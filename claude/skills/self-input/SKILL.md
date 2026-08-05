---
name: self-input
description: Trigger /compact or /clear on yourself, without asking the user to type it, by injecting keystrokes into Claude Code's own input box. Use when context is filling up mid-task and stopping to ask for a compact would break the flow, or when the user asks whether you can drive your own client. Requires claude to be running under claude-pty.py or inside a screen session.
---

# Self-input (drive your own client)

Injection needs a process that owns the pty master Claude Code's TUI reads from.
Writing to the pty slave (`/dev/pts/N`) paints output but is not an input channel, and
`TIOCSTI` is disabled by default on kernels 6.2+.

Two owners work, and `send-self.sh` picks whichever is present:

- **`claude-pty.py`** (`~/dot-files/bin/`, what `start_claude` uses) publishes a FIFO at
  `$CLAUDE_PTY_FIFO`; anything written there lands in the input box. It relays bytes
  without parsing them, so truecolor survives — screen 4.x mangles 24-bit SGR.
- **`screen`** via `screen -X stuff`, for sessions started under screen directly.

## Use it

```bash
~/.claude/skills/self-input/send-self.sh --check     # can I inject right now?
~/.claude/skills/self-input/send-self.sh /compact
```

`--check` reports the transport and cooldown state without sending anything. Run it first
if you are unsure the session has a pty owner.

## Rules

- **Send it as the last action of your turn.** Injected text lands in the input box while
  the turn is still running and submits when the turn ends. Sending it early means the
  command fires at an unpredictable point relative to the rest of your work.
- **Say what you did.** Tell the user you triggered the compact. A context reset they did
  not ask for and cannot see coming is disorienting.
- **Only `/compact` and `/clear` are whitelisted.** The script rejects everything else.
  Do not work around it by writing to `$CLAUDE_PTY_FIFO` or calling `screen -X stuff`
  directly — the whitelist is the thing that keeps a bad turn from injecting its own next
  prompt and looping unattended.
- **60 second cooldown**, tracked in `~/.claude/.self-input-last`. A cooldown failure is
  the guard working, not a bug to retry past.
- Never send `/clear` with unsaved working state. Write a handoff note to the scratchpad
  first — `/clear` drops everything, `/compact` summarizes.

## Setup

`start_claude` (in `~/dot-files/.bashrc`) already launches through the relay, which
exports `CLAUDE_PTY_FIFO`. Nothing else is needed.

Under screen instead, `STY` must be set. If claude sits in a window other than the
session's current one, set `CLAUDE_SCREEN_WINDOW` to that window number.

## When not to use it

Auto-compact (`autoCompact` in `~/.claude.json`, or `/config`) already handles the
threshold case. Reach for this only when you want the reset at a point you choose — a
natural task boundary, right after writing a handoff file — rather than wherever the
context limit happens to land.
