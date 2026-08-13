---
name: pr-description
description: Write the text of a pull-request description — the title and body — in strict ASD-STE100 Simplified Technical English and Orwell's writing rules. The text states the facts about the final product: what the merged code does, grouped by area, not the commit-by-commit history or the review/fix process. Use when the user asks to write, draft, or reword a PR description or PR title. This skill is the writing only; it does not push or open the PR.
---

# PR description

Write the title and body of a pull request. This is writing only — no git, no gh, no pushing.

## What the text says

State the facts about the **final product** — what the merged code does once it lands. The reader
wants the end state, not the road there.

Include:
- **What it does.** The feature or fix, in the product's own terms. Group by area, not by commit.
- **How to reach it or how it behaves** when that is not obvious (a new menu, a toggle, a
  data-driven hook).
- **Where external artifacts live** — files the branch depends on that are NOT in this repo
  (templates, config, assets in SVN or a home folder). Name the path.

Leave out:
- The commit-by-commit story. The commits are already in the PR; do not restate them.
- The review, the fixes, the bugs found and fixed on the branch, the rewrite history. The reader
  reads the final diff; process noise buries the facts.
- Test-run bookkeeping and build counts, unless the user asks for a testing section.

Ask the user before adding a "Testing", "Risk", or "Rollout" section — default to product facts only.

## Writing rules — strict

Every word of the body and the title follows ASD-STE100 Simplified Technical English AND Orwell's
six rules. These two sets mostly say the same thing; obey both.

**ASD-STE100:**
- Active voice. Name the actor. "The analyzer reads the file", not "The file is read".
- Present tense. Say what the product does, not what it will do or would do.
- One word, one meaning. Pick the plain word and reuse it. A synonym reads as a second thing.
- No metaphors, idioms, or figures of speech. No "under the hood", "plumbing", "wiring",
  "seamless", "leverage", "magic". Say the mechanism.
- One idea per sentence. Keep sentences short — about 20 words.
- Cut every filler: "basically", "essentially", "simply", "just", "actually", "note that",
  "in order to", "at this point".
- Verbs, not noun piles. "Configures the pump", not "performs pump configuration".
- Say the thing first. No windup.

**Orwell's six rules:**
1. Never use a metaphor, simile, or figure of speech you are used to seeing in print.
2. Never use a long word where a short one will do.
3. If you can cut a word, cut it.
4. Never use the passive where you can use the active.
5. Never use a foreign phrase, a scientific word, or a jargon word if an everyday word will do.
6. Break any of these rules sooner than say anything outright barbarous.

**Domain-term exception to rule 5 and the jargon rule:** keep the real names of real things — CAN,
HDVO, propulsion widget, hydrostatic drive, td_variants. These are the product's vocabulary, not
jargon. Drop only invented shorthand.

**Self-edit pass — required.** After a first draft, read it once and cut. For each sentence: is it
active, present, one idea, and free of filler? Can any word come out? If yes, cut it, then reread.

Before → after:
- "This PR basically overhauls the permissions plumbing so the widget can be leveraged seamlessly
  under the hood." → "The analyzer reads the deployed permissions file and warns when the
  propulsion widget is missing."
- "Provisioning of the boxes will be performed upon toggling of the feature option." → "Provisioning
  runs when the user toggles the feature option."

## Title

A short noun phrase that names the product or change. Same rules: active, plain, no filler, no
metaphor. Not a sentence, not a commit subject with a type prefix.
- Good: "Hydrostatic Drive: Truck Designer feature with in-app switchbox templates"
- Weak: "Add support for enabling the new hydrostatic drive functionality"

## Never

Do NOT append a `Claude-Session:` trailer, a `Co-Authored-By: Claude` line, a "Generated with
Claude Code" line, or any other tool attribution to the body or title. The description is the
change, nothing else.
