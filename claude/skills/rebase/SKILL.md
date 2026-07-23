---
name: rebase
description: How to rewrite git history in this environment, where interactive `git rebase -i` is blocked. Covers squashing/folding a fix into an earlier commit (fixup/autosquash), dropping a commit or a commit+revert pair, rewording/reordering/editing a specific commit, and rebuilding history from scratch — all driven non-interactively. Use whenever the user asks to squash, fold, fixup, reorder, reword, drop, split, or "clean up" commits, or to rebase a branch.
---

# Rebase (non-interactive)

The harness blocks the interactive `-i` flag when a human would drive it. You can still do
every interactive-rebase operation by driving it with **no-op editors**, or by using
non-`-i` rebase forms. This is not a workaround hack — it's the normal way to script rebase.

## The two editor env vars (this is the whole trick)

- `GIT_SEQUENCE_EDITOR` edits the **todo list** (the `pick`/`fixup`/`squash`/`reword` lines).
- `GIT_EDITOR` edits **commit messages** and other prompts (reword, squash-message merge).
- Setting either to `true` makes it a no-op that accepts what git generated, unchanged.

Prefix rebase commands with **both** set to `true` to run fully non-interactively:

```
GIT_SEQUENCE_EDITOR=true GIT_EDITOR=true git rebase -i --autosquash <base>
```

Env note: `git --version` here is 2.34.1. Plain `git rebase --autosquash` *without* `-i`
only autosquashes on git ≥ 2.38, so on this box you must use `-i` + the no-op editors.
The `-i` is fine — it's non-interactive because the editors never open.

## Golden rules (do these every time)

1. **Back up first:** `git branch backup-<short-desc>`. Costs nothing.
2. **Only rewrite unpushed history** (or history you've confirmed is safe to force-push).
3. **Verify after:** if the rewrite should only reorder/squash and NOT change the final tree,
   `git diff backup-<...> HEAD` must be **empty** (exit 0). Empty proves you touched no source
   — no rebuild needed. Non-empty means you changed content; rebuild/retest before trusting it.
4. Delete the backup branch once verified.

## Recipe 1 — Fold a fix into an earlier commit (most common)

Make the fix, then a fixup commit targeting the commit it belongs to, then autosquash:

```
git add <files>
git commit --fixup=<target-hash>        # message becomes "fixup! <target subject>"
GIT_SEQUENCE_EDITOR=true GIT_EDITOR=true git rebase -i --autosquash <target-hash>^
```

`--autosquash` moves each `fixup!` right after its target and pre-marks it `fixup` in the todo;
the no-op sequence editor accepts that todo as-is. Use `--squash=<hash>` instead of `--fixup`
if you also want the fixup's message folded into the target's (then `GIT_EDITOR` supplies the
combined message — set it to `true` to keep the default combined text).

Multiple fixups at once: create one `--fixup=<hash>` commit per target, then a single
`--autosquash` rebase from below the earliest target sorts them all.

## Recipe 2 — Drop a commit, or a commit+revert pair (no content edits)

`git rebase --onto` needs no `-i` at all, so it's always allowed. It replays everything
*after* `<last-to-drop>` onto `<new-base>`:

```
git rebase --onto <keep-this>  <last-commit-to-drop>
# drop a single commit X:      git rebase --onto X^ X
# drop an adjacent pair A..B:  git rebase --onto A^ B     (A is older, B newer; drops A and B)
```

Ideal for removing a no-op commit and its later revert. Verify with the empty-`git diff` check.

## Recipe 3 — Reword / reorder / edit a specific commit

Script the todo edit with a `GIT_SEQUENCE_EDITOR` that rewrites the generated todo file
(passed as `$1`), instead of a human editor. Example: mark one commit `edit` to amend it:

```
GIT_SEQUENCE_EDITOR='sed -i "s/^pick <hash>/edit <hash>/"' GIT_EDITOR=true \
    git rebase -i <hash>^
# rebase now stops at <hash>:
git commit --amend -m "New subject" --no-edit-author   # or edit files, git add, then amend
GIT_SEQUENCE_EDITOR=true GIT_EDITOR=true git rebase --continue
```

To **reorder**, have the sequence editor reorder the `pick` lines (e.g. a small python/awk
one-liner writing `$1`). To **reword only**, set the line to `reword` and supply the new
message via `GIT_EDITOR` (e.g. `GIT_EDITOR='printf "New msg\n" >'` writes the message file).

## Recipe 4 — Rebuild from scratch (when history is tangled or a file moved)

Sometimes a clean reset beats surgical fixups — e.g. a file was relocated across commits, or
you want to re-split the work. Reset soft to the base and re-commit in the intended order:

```
git branch backup-rebuild
git reset --soft <base>                 # keeps all changes staged, moves HEAD back
# ...restage/split and re-commit in clean order...
git checkout <orig-hash> -- <file>      # pull a specific file's blob from a prior commit if needed
```

## During any rebase: conflicts and control

Always prefix with the no-op editors and tail the output:

```
GIT_EDITOR=true GIT_SEQUENCE_EDITOR=true git rebase --continue 2>&1 | tail -8
GIT_EDITOR=true GIT_SEQUENCE_EDITOR=true git rebase --skip
git rebase --abort                      # bail out; returns to pre-rebase state
GIT_SEQUENCE_EDITOR='<script>' git rebase --edit-todo   # fix the todo mid-rebase
```

If `--continue` reports nothing staged after you resolved by removing all changes, `--skip`
that commit. When in doubt, `--abort` and start over from the backup.
