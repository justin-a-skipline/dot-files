---
name: embedded-screen
description: Talk to an embedded device over USB serial through one shared screen session that both a human and Claude drive at the same time. Output scrolls forward into scrollback and a log file, so no full-screen terminal and no daemon are needed. Use when the task is to send commands to a device on /dev/ttyUSB0 (or another serial port), read its output, or set up shared serial access. Replaces the embedded-serial / embedded-serial-daemon / embedded-cmd stack.
---

# Embedded serial over a shared screen session

`screen` opens the serial line directly. One detached session owns the port. A
human attaches to type and watch; Claude sends commands and reads the log. Both
drive the same session, so there is no second writer and no deadlock. Output
scrolls forward, so it lands in scrollback and in the log file — a full-screen
program (minicom) does not, which is why it broke vim scrollback.

The helper is `embedded-screen.sh` next to this file. Defaults: session
`embedded`, port `/dev/ttyUSB0`, baud `115200`, log `/tmp/embedded-serial.log`.
Override with `EMBEDDED_PORT`, `EMBEDDED_BAUD`, `EMBEDDED_LOG`, `EMBEDDED_PROMPT`.

## Claude: how to drive it

```bash
S=~/dot-files/claude/skills/embedded-screen/embedded-screen.sh

"$S" start                 # start the session if it is not already up
"$S" run 'ls -la /root'    # send, wait for the prompt, print the output
"$S" send 'reboot'         # send without waiting (fire-and-forget)
"$S" read                  # print the last 4000 bytes of the log
"$S" status
```

Prefer `run` for anything you need the output of. It waits for the shell prompt
to come back instead of sleeping a fixed time, so long commands (`grep -r`) do
not get cut off. If the device prompt is not `#`/`$`, set `EMBEDDED_PROMPT` to a
regex that matches the last line at rest, e.g. `EMBEDDED_PROMPT='hdvo-ng:.*[#$]'`.

`send` and `run` pass text to `screen ... stuff`, which interprets `\n`, `\t`,
octal `\NNN`, and `^x`. A literal backslash in a command must be doubled.

## Human: how to use it

Two aliases (in `.bashrc`):

- `embedded` — attach to the session, starting it first if needed. Detach with
  `Ctrl-A D`. Everything you type goes to the device. Scroll back with
  `Ctrl-A Esc`, then `q` to leave copy mode.
- `embedded-log` — `tail -f` the log in the current window. Use this in a vim
  terminal to keep vim scrollback, search, and yank on the device output.

You and Claude can both be active at once: you attached and typing, Claude
sending through the same session.

## Notes

- The log grows without bound. `"$S" start` truncates it. Delete it when large.
- No xmodem or file transfer — this is line-oriented console only. Keep minicom
  for a file transfer if you ever need one.
- `stop` / `Ctrl-A D` then `screen -S embedded -X quit` ends the session.
