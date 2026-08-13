---
name: asana-card
description: Create an Asana card (task) from a rough list of issues or a feature request, written in the house Background / Task Specific / Definition of Done structure. Researches each item in the codebase first, drafts the card body as nested bullet points, waits for the user to approve it, then creates it on the target board and section assigned to the user. Use when the user says "make an Asana card", "add a card to the sprint board", "track this in Asana", or hands over a walkthrough note to turn into a card.
---

# Asana card

Turn a rough note or issue list into one Asana card in the house format. Research the codebase first, draft the body, show it, then create.

## Defaults

- **Workspace:** spec-rite.io — gid `938599507103867`
- **Board:** SKL 2026 Active Sprints — gid `1212638896757734`
- **Section:** To Do — gid `1212638896757735`
- **Assignee:** `me`

The user names a different board, column, or assignee sometimes. When they do, resolve it: `search_objects` (resource_type project) for the board, then `get_project` with `include_sections: true` for the section gid. Otherwise use the defaults above and do not ask.

## Research first — required

The card must point at real code, not restate the symptom. For each item on the list, do a short investigation before writing:

- Find the file and class that owns the behavior, the cause, the data source, and the fix location. Get `file:line` references — for your own understanding.
- Fan out one read-only Explore agent per item when there are several — they run in parallel and you only keep the conclusions.

Then distill. Research deep, but the card is not the research. See "What goes in Task Specific" below — the card keeps the salient trap and one class/function anchor, not the `file:line` trace. Do not overclaim — when the research is not certain, write "likely" and say what to confirm.

## Escalate the research — required

Do not throw the deep research away after trimming the card. The full findings are worth more than the card, and reading the research next to the card often surfaces new considerations the card should carry. So:

- Write the full research to a file — one section per item, with the `file:line` detail the card leaves out. Put it in the scratchpad (or a path the user names).
- Send it to the user with `SendUserFile` so they can save it if they want.
- Point out in the message anything that reading the research surfaced — a reframed item, a new risk, an item that turned out not to be a bug. This is the point of escalating, not a formality.

Do this before or with the card draft, not after the card is created.

## The three headers

Every card uses these three, in this order. Each header is a **bold** line on its own — not a sized heading. The board does not use `<h1>`/`<h2>` for these; it bolds the word and leaves a blank line above and below (none above the first). In `html_notes` that is `<strong>Background</strong>` then a literal newline (`\n`) then the list. Asana notes allow no `<br>` or `<p>`, but a literal `\n` in the `html_notes` string renders as a line break — put one around each header for the blank line.

- **Background** — what the items are and the context. One block per item.
- **Task Specific** — the salient details, not a code trace. See the next section.
- **Definition of Done** — the checklist that says the card is finished. One line per item, testable.

## What goes in Task Specific

This is a grooming-session note, not a code review. The board's filled-out cards put here the one or two things a less-experienced engineer would miss — the trap, not the causal chain. Match that.

Put in:
- **The salient trap** — the gotcha that is invisible until it bites. The bootloader-vs-main-program address conflict. The counter that looks right but sums the wrong thing. The "modal" flag that does nothing because the widget is not a window. Flag it plainly ("Heads-up:", "Do not remove…").
- **One anchor** — a single class or function name that says where to start (`bindCycleLength`, the tab-bar stylesheet clamp). A function or class name is fine when it is needed. Not a list of five, and not line numbers.
- **Scope and sequencing** — what is in and out of scope, what must happen first, rough effort in commits or days when known.
- **Open questions** — the honest "still needs investigation" and "not sure", with a parenthetical answer added later when it is resolved.

Leave out:
- `file:line` chains and the step-by-step enforcement path. This is the exact thing that makes a card overwhelming and hard to read.
- Restated Background.
- Every file the change touches. Name the entry point, not the whole call graph.

## Formatting — nested bullets

The user wants bullet points, not prose paragraphs. Under each header:

- One top-level bullet per item on the list.
- The details for that item are sub-bullets indented one level under it.
- Keep each item's information together — all of item 1 in its bullet group, then item 2, and so on. Do not mix items.

Example shape for one item under Background:

```
- Stripe and cycle upper bounds
    - The main screen lets the operator edit Stripe length and Cycle.
    - Neither field clamps to a maximum, so the operator can enter an out-of-range value.
```

Nested bullets are not optional. Nobody wants to read prose in a card, and a single factual claim in its own bullet is easy to edit later when the team reviews it together. Do not collapse an item's facts into a paragraph.

## Formatting — no inline monospace

Inline monospace (single-backtick `code`) renders badly in Asana and wraps hard to read. Do not use it.

- Inline class, function, or object names: use **bold**, not backticks. `Truck::pumpUsageGallons()` becomes **Truck::pumpUsageGallons()**.
- A real multi-line snippet — a JSON payload, a small code block: use a fenced code block (`<pre>` in `html_notes`). Monospace earns its place there.
- Do not use bold for ordinary emphasis in a card, so bold reads as "this is an identifier".

## Writing style

All card text follows ASD-STE100 Simplified Technical English (see global CLAUDE.md): active voice, present tense, one idea per sentence, no filler, no metaphors. Keep the real domain terms (UDL, NG-MST, CAN, Stripe, Cycle). Direct and plain — the same voice as a short note to a teammate.

## Create the card

Draft the body in chat first, then wait for approval, then create the card directly. Do NOT use `create_task_preview_v4` — its confirmation widget does not render in the Claude Code command line. Review happens in the chat draft, not a widget.

1. Draft the full body and show it to the user in chat. Show the whole card — title, all three headers, every bullet.
2. Wait for the user to approve it. Do NOT call `create_tasks` until the user says to make the card. When they ask for a change, edit the draft, show it again, and wait again. Approval of an earlier version is not approval of the current one.
3. Create with `create_tasks` (a direct, non-widget create). Pass one task with:
   - `name` — a short noun-phrase title.
   - `html_notes` — the body. Each header is `<strong>` on its own, not `<h2>`, with a literal `\n` around it for the blank line. Use nested `<ul><li>` for the bullets; a sub-bullet is a `<ul>` inside its parent `<li>`. Bold identifiers with `<strong>`; never a code element for inline names. Allowed tags are a fixed list — `<br>` and `<p>` are NOT allowed, so do not use them; use a literal `\n` for a line break. The XML must be well-formed and wrapped in one `<body>` root. (Plain `notes` has no formatting — use `html_notes`.)
   - `project_id` — the board gid.
   - `section_id` — the section gid (To Do by default).
   - `assignee` — `me` (or the named user).
Ask about card splitting during the draft, before approval: when the note holds several unrelated issues, ask the user once whether they want one card that lists them all or one card per issue. Default to one card that lists them when they said "a card" (singular).

## Title

A short noun phrase that names the work. Not a sentence. Examples: "NG-MST main screen fixes", "UDL life totals screen". When one card covers several issues, name the group ("NG-MST Graco review follow-ups"), not the first item.
