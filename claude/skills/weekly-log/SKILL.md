---
name: weekly-log
description: Produce a time log from Claude Code session activity — active hours per task per week, with a short "what I did" narrative drawn from git commits. Use when the user wants hours for a card/task they just finished, a weekly roundup for time capture, or activity over a date range. Triggers on "how many hours", "time log", "hours on <card>", "what did I do this week".
---

# Weekly time log

Turns Claude Code's session logs into a defensible time log. The logs stamp
every event with a timestamp and the git branch, so activity is reconstructed
after the fact — the user does not track hours by hand.

Two facts drive everything here:

- **The number is a floor, not total labor. Report it that way.** It measures
  time actively interacting with Claude. Work done between prompts or away from
  the session — coding in the IDE, testing on hardware, reviewing a diff,
  meetings — is invisible (it shows as one capped gap, or no events at all). For
  someone who does most work through Claude it is near-total; for someone who
  also codes and tests independently it is a lower bound. Never present it as
  "hours worked"; present it as "hands-on-Claude time, add hands-off work."
- **Active hours are an estimate.** The script sums the gaps between events, but
  the cap on a gap depends on what was happening: time while a tool runs or
  Claude is mid-task counts in full (you asked for it, up to a 30 min sanity
  cap per gap), while idle time after Claude hands back a final answer is capped
  at 15 min (you have other duties). Report it as *active engagement time*.
  - The weekly headline is the **union** of all tasks' time — overlaps counted
    once — because the user runs several projects in parallel and summing per
    task would double-count. Each task row still shows its own hours (what you
    log on that card); the two differ by however much parallel work happened,
    which the output states outright.
- **Commit attribution is fuzzy; you fix it with judgment.** History here is
  linear (rebased), so git cannot say which branch a commit came from. The
  script matches commits to a task purely by author-date landing inside an
  active session on that branch. When the user worked two branches in one
  sitting, commits from the *other* branch leak in. **Filter them out by
  reading the commit text against the branch name** before you narrate.

## Steps

1. **Pick the query from what the user asked:**
   - A finished card / "hours on X" → `--task <substring>` (first touch to now).
   - "this week" / no timeframe → no args (current week).
   - A named past week → `--week YYYY-MM-DD` (any date in it).
   - A range → `--since YYYY-MM-DD --until YYYY-MM-DD`.
   - Everything on record → `--all-time`.

2. **Run the script for hours**, from any work repo:
   ```
   python3 ~/.claude/skills/weekly-log/weekly_hours.py [query flags]
   ```

3. **Run it again with `--commits`** to get the candidate commit list per bucket.

4. **Narrate each bucket.** For every (week, task) row, write 1–2 plain
   sentences of what got done, drawn from the commits — but first drop any
   commit whose subject clearly belongs to a different task than the branch
   name. The commit messages are already factual; theme and condense them, do
   not invent. If a bucket has hours but no surviving commits (abandoned branch,
   or committed outside a session), say so plainly rather than guessing.

5. **Present** the weekly view: task, active hours, and the one-line narrative.
   Keep it tight enough to transcribe into a card's hours field.

## Notes

- Scans every project under `~/.claude/projects` — this is a work-only account,
  so all of it is work. Narrow to one task with `--task` when needed.
- Stateless — recomputes from the logs each run, so running it several times a
  week for different cards never double-counts. Each run is just a query.
- `--idle-cap N` / `--work-cap N` tune the two thresholds (minutes) if the
  defaults (15 idle, 30 in-flight) feel wrong.
- Long hands-off testing that never touches Claude (flash a truck, drive it for
  an hour) leaves no log events, so no model can see it — add that time by hand.
