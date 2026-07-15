---
name: review-branch
description: Produce a thorough, commit-by-commit PR review of a branch as a single markdown file — full diffs (git -W) with heavily dispersed inline commentary and a per-commit summary. Use when the user says things like "review this branch", "review the branch going back to <commit/origin/main>", or "PR review from HEAD back to X". Hunts for both correctness bugs and code smells / architectural issues in one pass, ranked by severity.
---

# Review Branch

Generate a detailed, reviewer-grade walkthrough of a branch, commit by commit, written to a single markdown file.

## Determine the range

**Always confirm how far back before reviewing.** The review covers `<base>..HEAD`.
- If the user named a commit/ref/tag ("back to abc123", "since v2.1"), treat that as the proposed base but still show them the resolved range and commit list to confirm.
- If they didn't name a base, **ask** how far back to go. Offer sensible options — `origin/main`, the merge-base with `origin/main` (true fork point), or a specific commit — with `git log --oneline` context so they can see the commits. Do not silently pick a default.
- Only start reviewing once the range is confirmed.

## What to look for

One pass, both concerns, ranked together by severity — there's no separate "bug mode" vs. "smell mode":
- **Correctness bugs.** The specific input/state that produces a wrong result, crash, leak, race, or off-by-one. These are usually the most severe findings, so they usually rank first.
- **Code smells and architecture.** Over-engineering, duplication (especially copy-paste between files), misplaced responsibilities, API-misuse-by-design, and anything with a simpler alternative. Apply the house philosophy in the global CLAUDE.md: simplest thing that works, deletions over additions, APIs usable without knowing their internals. When the author is new to the codebase, watch hardest for new code that reinvents something already available — search for a pre-existing helper before accepting a hand-rolled one.

Don't let one concern crowd out the other: a branch can have both a real bug and a real design problem, and the report should surface both. Let severity — not category — drive the ranking. The skepticism dial is the "don't invent problems" rule below: report a smell only when you can name a concrete cost, so a tight bugfix branch doesn't get buried in speculative architecture notes while a large feature still gets a hard look at its design.

## How to review

Work through commits **oldest to newest** so the report tells the same story the author intended:

```
git log --reverse --format='%H %s' <base>..HEAD
```

For each commit, read the **full diff with function context**:

```
git show -W <commit>
```

The `-W` (`--function-context`) flag is the whole point — it shows the entire enclosing function for each hunk, not just the changed lines, so you can judge changes in context.

**Always run the Doxygen / function-header check** on every changed or added function. The house standard (non-negotiable, no "tiny helper" exception):
- Doc comments live on the **definition in the `.c` file**, not on the header declaration. Headers carry bare declarations only. (Exceptions: C++ member functions or inline functions defined in a header.)
- Format is Doxygen: `@brief`, then a `@param` for **every** parameter, then `@return` when the function returns non-void.
- Flag: functions touched in the diff that lack a doc comment, are missing a `@param`/`@return` tag that applies, or have the comment on the declaration instead of the definition. A short brief is fine; missing tags are not.

**Critical rules:**
- **A problem in one commit may be fixed in a later one.** Before you finalize any bug you spotted in commit N, check whether a later commit in the range already addresses it. If it does, say so rather than reporting a false positive — note it was a transient issue resolved in commit M.
- **When something is curious or you're unsure, open the actual code** (not just the diff) to see whether it makes sense. Trace callers, check the header, look at how neighboring code does the same thing. Don't speculate when you can verify.
- **Don't invent problems.** If a commit is clean, say it's clean. Resist "this could bite later if…" framing unless you can name a concrete, near-term scenario.

## Output format

Write everything to a single markdown file: `pr-review-<branch-slug>.md` in the repo root (tell the user the path; this file is a working artifact, not meant to be committed). If it already exists, overwrite it.

Structure, in order:

1. **Header** — branch name, range (`<base>..HEAD`), commit count, and date.
2. **One section per commit** (oldest first). For each:
   - A heading with the short hash and subject line.
   - The **relevant diff hunks** in fenced ```` ```diff ```` blocks, with your commentary **heavily dispersed throughout** — break the diff where you have something to say and drop the comment inline, right next to the lines it's about. Don't dump the whole diff then comment at the end; interleave. Trim genuinely uninteresting hunks (whitespace, mechanical renames) but note that you trimmed them.
   - A short **commit summary**: what it does, whether it's correct, and any findings.
3. **Findings — this is the part the user actually reads, so make it carry its own weight.** A single ranked list ordered by severity — bugs and smells interleaved, most severe first, categorized per finding (e.g. a short "correctness" / "architecture" / "nit" tag) but not segregated into separate mode-based sections. The commit walkthrough above is the record; this section is where the reader decides what to do. Each finding must be **self-contained** — the reader should be able to understand it, judge whether it's real, and act on it *without scrolling back to the commit sections or opening the code themselves*. They'll go look when they choose to, not because your writeup forced them to.

   For each finding, write a few short paragraphs in the user's voice (prose, not a filled-in form — don't literally print these as labeled fields), covering:
   - **What and where**, with `file:line` — then **quote the actual offending code inline** in a tight ```` ```diff ```` / ```` ```cpp ```` block. Don't make them go find it. If two spots interact (a caller and a callee, a flag set here and read there), show both.
   - **Why it's a problem, concretely.** For a bug, give the specific input/state that triggers it and what actually breaks — the failure scenario, traced through — not just "this is wrong." For a smell, name the real maintenance or misuse-by-design cost in plain terms.
   - **What you verified vs. what's still open.** If you traced callers, checked the header, or confirmed a neighbor does the same thing differently, say what you found so they can trust it. If the finding hinges on a fact you couldn't pin down, state exactly what you checked and the single question that remains — so they know the one thing to confirm, and don't have to re-derive the whole thing.
   - **The fix** — concrete and specific enough to hand off or apply, with the shape of the corrected code when that clarifies it. If there's a simpler alternative to the whole approach, lead with that.
   - **A severity/effort read** — merge-blocker vs. should-fix vs. nit, and roughly how big the fix is.

   Err toward more context, not less. A finding that reads "file:line — X is wrong, do Y" has failed the point of this section. Depth scales with severity: a merge-blocking bug earns a full walkthrough; a nit can be a sentence or two.

   **Verify every finding against the working tree before you write it — grep or read the current file, don't reason from the diff.** The Findings section describes the branch *as it will merge* (final-tree state at `HEAD`), so every finding must still be true of the current code. A defect an earlier commit introduced and a later commit in the range then fixed is **transient**: it belongs in the commit walkthrough (noted as resolved in commit M), never in Findings. This is the same "a problem in one commit may be fixed in a later one" rule from above, applied one more time at the moment you write the finding — it's the last gate. If you catch yourself describing duplication, a bug, or a smell that a later commit already cleaned up, that's a walkthrough note, not a finding. When in doubt, run the grep and cite what `HEAD` actually contains.

4. **Verdict** — a one-paragraph honest take on the branch as a whole: is it close, and what must happen before it merges.

**Every code and diff block — everywhere in the report — must name the function (or class member / method) it lives in**, so the reader can jump straight to it. `git show -W` already shows the enclosing function, so you have it. Put the function name in the prose right before the block, or as a comment on the block's first line (e.g. `// FactorySettingsScreen::initCalNumberChange()`). A bare `file:line` is not enough on its own — pair it with the function name. If a snippet spans two functions, label both.

Write commentary in the user's voice per the global CLAUDE.md: direct, conversational, opinionated but open — "I think X would be simpler because Y", not a formal rubric. Prioritize simplicity and flag unnecessary complexity as high priority.

## After writing

Report the file path and give a 2-3 sentence spoken summary of the headline findings so the user knows what they're walking into before they open the file.

**Do not apply fixes unless the user asks.** The review's job is to report.

## Applying fixes (only when asked)

If the user asks you to fix the findings:
- **One fix per commit.** Each finding gets its own logically-scoped commit, in an order that tells a story — mirrors the user's commit-granularity preference (small, single-purpose commits, optimized for the reviewer).
- **Doxygen updates may be grouped.** Function-header / Doxygen-comment fixes can go into a single commit together (e.g. "Bring touched functions up to house doc-comment standard") rather than one commit per comment.
- **Verify before each commit.** Build with `./scripts/command_line_dev_build --quiet` (and tests if applicable) before committing — no unverified commits. If the branch is somehow on `main`, branch first.
- Fix the root cause, not the symptom; don't mask a repeating signal with a debounce/timer.
