#!/usr/bin/env python3
"""Estimate active engagement time from Claude Code session logs.

Reads the timestamped events in ~/.claude/projects/*/*.jsonl, groups them by
git branch (the task), and reports "active" hours per ISO week. Active time is
the sum of gaps between consecutive events in a session, with any gap longer
than the idle cap treated as "stepped away" so juggling several tasks does not
inflate the total.

The logs are the source of truth and are never modified, so this is safe to run
as many times a week as you like -- every run recomputes from scratch.

  weekly_hours.py                 current week, every task
  weekly_hours.py --task grinder  one task, first touch to now (run on completion)
  weekly_hours.py --week 2026-06-08   a specific week (any date in it)
  weekly_hours.py --since 2026-06-01 --until 2026-06-15   custom window
  weekly_hours.py --all-time      every week on record

Add --commits to also print the git commits that land in each bucket's window;
the /weekly-log skill uses that to write the "what I did" narrative.
"""

import argparse
import glob
import json
import os
import subprocess
from collections import defaultdict
from datetime import datetime, timedelta

PROJECTS_DIR = os.path.expanduser("~/.claude/projects")

# Two caps, applied by what was happening at the *start* of a gap:
#   IDLE_CAP  after Claude gave a final text answer (ball is in your court)
#   WORK_CAP  while a tool is running or Claude is mid-task (you asked, it works)
# This is the "15 minutes after the prompt returned to me" rule: a long build or
# test counts as work, but the session left open overnight does not.
IDLE_CAP = timedelta(minutes=15)
WORK_CAP = timedelta(minutes=30)
TAIL_PAD = timedelta(minutes=2)    # credit for reading the final response


def parse_ts(s):
    """Parse an ISO-8601 timestamp (with trailing Z) to an aware datetime."""
    try:
        return datetime.fromisoformat(s.replace("Z", "+00:00"))
    except (ValueError, AttributeError):
        return None


def week_start(dt):
    """Monday 00:00 (local) of the week containing dt."""
    local = dt.astimezone()
    monday = local - timedelta(days=local.weekday())
    return monday.replace(hour=0, minute=0, second=0, microsecond=0)


def is_yield_point(o):
    """True if this event is Claude handing control back to the user.

    That is an assistant message with no tool_use block: a final text answer.
    The gap that follows it is idle time (you reading / off doing other duties),
    so it gets the short cap. Every other event (a tool call, a tool result, a
    user prompt) means work is in flight, so the gap after it gets the work cap.
    """
    if o.get("type") != "assistant":
        return False
    content = (o.get("message") or {}).get("content")
    if isinstance(content, list):
        return not any(isinstance(b, dict) and b.get("type") == "tool_use"
                       for b in content)
    return True


def load_events():
    """Yield (timestamp, is_yield, branch, cwd, path) for every activity event."""
    for path in glob.glob(os.path.join(PROJECTS_DIR, "*", "*.jsonl")):
        with open(path, errors="ignore") as fh:
            for line in fh:
                try:
                    o = json.loads(line)
                except json.JSONDecodeError:
                    continue
                ts = parse_ts(o.get("timestamp"))
                branch = o.get("gitBranch")
                cwd = o.get("cwd") or ""
                # Only user/assistant events mark real activity; skip injected
                # meta/system lines so they cannot stretch a gap.
                if not ts or not branch or o.get("type") not in ("user", "assistant"):
                    continue
                if o.get("isMeta"):
                    continue
                yield ts, is_yield_point(o), branch, cwd, path


def active_intervals(events, idle_cap=IDLE_CAP, work_cap=WORK_CAP):
    """Split sorted (timestamp, is_yield) events into active intervals.

    The cap for a gap depends on what was happening when it started: the short
    idle_cap after Claude yielded a final answer, the longer work_cap while a
    tool is running. A gap within its cap extends the current interval; a gap
    past it closes the interval (crediting the cap as a tail) and starts a new
    one. So a long build counts, an overnight-idle session does not.
    """
    if not events:
        return []
    intervals = []
    start = events[0][0]
    prev_t, prev_yield = events[0]
    for t, yielded in events[1:]:
        cap = idle_cap if prev_yield else work_cap
        if t - prev_t > cap:
            intervals.append((start, prev_t + cap))
            start = t
        prev_t, prev_yield = t, yielded
    intervals.append((start, prev_t + TAIL_PAD))
    return intervals


def intervals_active_time(intervals):
    return sum((end - start for start, end in intervals), timedelta())


def union_time(intervals):
    """Wall-clock time covered by intervals, overlaps counted once.

    Per-task hours can be summed to see how much attention each card got, but
    summing them across tasks double-counts time when several sessions ran in
    parallel. The union is the honest "how long were you actually engaged" total.
    """
    if not intervals:
        return timedelta()
    ordered = sorted(intervals)
    total = timedelta()
    cur_start, cur_end = ordered[0]
    for start, end in ordered[1:]:
        if start <= cur_end:
            cur_end = max(cur_end, end)
        else:
            total += cur_end - cur_start
            cur_start, cur_end = start, end
    return total + (cur_end - cur_start)


def build_buckets(events, idle_cap=IDLE_CAP, work_cap=WORK_CAP):
    """Aggregate events into {(week_start, branch): {...}} buckets.

    Active intervals are computed per (session, branch) so cross-session and
    cross-task gaps never count. Events are keyed to a week by their own
    timestamp. Active hours are derived from a bucket's intervals on demand, so
    they are never stored and cannot drift out of sync.
    """
    # Group events per (session-file, branch) to compute intervals,
    # while remembering which week each event belongs to.
    per_stream = defaultdict(list)   # (path, branch) -> [(ts, is_yield, cwd), ...]
    for ts, is_yield, branch, cwd, path in events:
        per_stream[(path, branch)].append((ts, is_yield, cwd))

    buckets = defaultdict(lambda: {"cwds": set(), "first": None, "last": None,
                                   "streams": 0, "intervals": []})
    for (path, branch), items in per_stream.items():
        items.sort(key=lambda x: x[0])
        # Split the stream at week boundaries so a session spanning midnight
        # Sunday is credited to the right weeks.
        by_week = defaultdict(list)
        for ts, is_yield, cwd in items:
            by_week[week_start(ts)].append((ts, is_yield, cwd))
        for wk, wk_items in by_week.items():
            events_wk = [(t, y) for t, y, _ in wk_items]
            b = buckets[(wk, branch)]
            b["intervals"].extend(active_intervals(events_wk, idle_cap, work_cap))
            b["streams"] += 1
            for _, _, cwd in wk_items:
                b["cwds"].add(cwd)
            times = [t for t, _ in events_wk]
            lo, hi = times[0], times[-1]
            b["first"] = lo if b["first"] is None else min(b["first"], lo)
            b["last"] = hi if b["last"] is None else max(b["last"], hi)
    return buckets


def repo_root(cwd):
    """Nearest git toplevel for a cwd, or None if it is gone / not a repo."""
    if not cwd or not os.path.isdir(cwd):
        return None
    try:
        out = subprocess.run(["git", "-C", cwd, "rev-parse", "--show-toplevel"],
                             capture_output=True, text=True, timeout=5)
        return out.stdout.strip() or None
    except (subprocess.SubprocessError, OSError):
        return None


def commits_in_intervals(root, intervals):
    """Commit subjects *authored* inside any active interval, in the repo at root.

    Two things matter here:

    * Filter on author date, not committer date. git's --since/--until use
      committer date, which a rebase rewrites to the rebase time. Author date
      survives a rebase and is what lines up with the session log, so we emit
      the author unix timestamp (%at) and filter it ourselves.
    * Match against the contiguous active intervals, not the outer span. With a
      linear (rebased) history git cannot tell us which branch a commit came
      from, so time is our only signal -- and a commit authored *while you were
      in a session on this branch* is far better attributed than one that
      merely falls between your first and last touch of the week.
    """
    if not root or not intervals:
        return []
    windows = [(s.timestamp(), e.timestamp()) for s, e in intervals]
    try:
        out = subprocess.run(
            ["git", "-C", root, "log", "--no-merges", "--all",
             "--pretty=format:%at\t%h %s"],
            capture_output=True, text=True, timeout=15)
    except (subprocess.SubprocessError, OSError):
        return []
    commits = []
    for line in out.stdout.splitlines():
        if "\t" not in line:
            continue
        at, rest = line.split("\t", 1)
        try:
            when = float(at)
        except ValueError:
            continue
        if any(lo <= when <= hi for lo, hi in windows):
            commits.append(rest)
    return commits


def fmt_hours(td):
    return f"{td.total_seconds() / 3600:.1f}h"


def main():
    ap = argparse.ArgumentParser(description="Active hours from Claude logs.")
    ap.add_argument("--task", help="only this branch/task (substring match)")
    ap.add_argument("--week", help="any date (YYYY-MM-DD) in the target week")
    ap.add_argument("--since", help="window start (YYYY-MM-DD)")
    ap.add_argument("--until", help="window end (YYYY-MM-DD)")
    ap.add_argument("--all-time", action="store_true", help="every week")
    ap.add_argument("--commits", action="store_true",
                    help="list git commits per bucket (for the narrative)")
    ap.add_argument("--idle-cap", type=int, default=15,
                    help="minutes of idle-after-answer that still counts (default 15)")
    ap.add_argument("--work-cap", type=int, default=30,
                    help="minutes a single in-flight tool run can count (default 30)")
    args = ap.parse_args()

    idle_cap = timedelta(minutes=args.idle_cap)
    work_cap = timedelta(minutes=args.work_cap)

    buckets = build_buckets(load_events(), idle_cap, work_cap)

    # Decide the week window.
    now = datetime.now().astimezone()
    if args.all_time or args.task or args.since or args.until:
        lo_week = hi_week = None  # no week gate; other filters apply below
    elif args.week:
        d = datetime.fromisoformat(args.week).astimezone()
        lo_week = hi_week = week_start(d)
    else:
        lo_week = hi_week = week_start(now)

    since = datetime.fromisoformat(args.since).astimezone() if args.since else None
    until = (datetime.fromisoformat(args.until).astimezone() + timedelta(days=1)
             if args.until else None)

    # since/until gate whole buckets by their first/last touch, not per event.
    # A bucket that straddles the window edge is kept in full -- fine for
    # week-grained reporting, and not worth re-bucketing by day to tighten.
    rows = []
    for (wk, branch), b in buckets.items():
        if lo_week and not (lo_week <= wk <= hi_week):
            continue
        if args.task and args.task.lower() not in branch.lower():
            continue
        if since and b["last"] < since:
            continue
        if until and b["first"] > until:
            continue
        rows.append((wk, branch, b))

    if not rows:
        print("No activity found for that query.")
        return

    # Group rows by week, biggest task first within each week.
    by_week = defaultdict(list)
    for wk, branch, b in rows:
        by_week[wk].append((branch, b))

    for wk in sorted(by_week):
        week_rows = sorted(
            by_week[wk],
            key=lambda r: -intervals_active_time(r[1]["intervals"]).total_seconds())
        engaged = union_time([iv for _, b in week_rows for iv in b["intervals"]])
        print(f"WEEK OF {wk.date()}   —   {fmt_hours(engaged)} engaged")

        summed = timedelta()
        for branch, b in week_rows:
            active = intervals_active_time(b["intervals"])
            summed += active
            print(f"  {branch[:36]:38}{fmt_hours(active):>8}"
                  f"   ({b['streams']} sessions)")
            if args.commits:
                root = None
                for cwd in b["cwds"]:
                    root = repo_root(cwd)
                    if root:
                        break
                for c in commits_in_intervals(root, b["intervals"]):
                    print(f"      {c}")

        overlap = summed - engaged
        if overlap > timedelta(minutes=30):
            print(f"  {'':38}{'-' * 8}")
            print(f"  per-task hours sum to {fmt_hours(summed)}; "
                  f"{fmt_hours(overlap)} was parallel/overlapping work")
        print()


if __name__ == "__main__":
    main()
