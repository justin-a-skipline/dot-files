#!/usr/bin/env bash
# Inject a slash command into Claude Code's own input box.
#
# Needs a process that owns claude's pty master. claude-pty.py exposes one through
# the FIFO in $CLAUDE_PTY_FIFO; screen exposes one through `stuff`. Writing to the
# pty slave (/dev/pts/N) only paints output and cannot inject input.
set -euo pipefail

readonly COOLDOWN_SECONDS=60
readonly STAMP="$HOME/.claude/.self-input-last"

# Whitelist, not free text. A stray /compact is survivable; a self-injected
# arbitrary prompt is an unattended runaway loop.
is_allowed() {
    case "$1" in
        /compact | /clear) return 0 ;;
        *) return 1 ;;
    esac
}

die() {
    echo "send-self: $1" >&2
    exit 1
}

transport() {
    if [[ -n ${CLAUDE_PTY_FIFO:-} && -p ${CLAUDE_PTY_FIFO:-} ]]; then
        echo fifo
    elif [[ -n ${STY:-} ]]; then
        echo screen
    else
        echo none
    fi
}

check_environment() {
    case "$(transport)" in
        fifo) ;;
        screen)
            command -v screen >/dev/null || die "screen not installed"
            screen -S "$STY" -Q select . >/dev/null 2>&1 ||
                die "screen session $STY is not reachable"
            ;;
        *) die "no pty owner — launch claude via start_claude (claude-pty.py) or screen" ;;
    esac
}

describe() {
    case "$(transport)" in
        fifo) echo "pty relay ($CLAUDE_PTY_FIFO)" ;;
        screen) echo "screen session $STY" ;;
    esac
}

seconds_since_last_send() {
    [[ -f $STAMP ]] || { echo "$COOLDOWN_SECONDS"; return; }
    echo $(( $(date +%s) - $(stat -c %Y "$STAMP") ))
}

send_fifo() {
    # Literal CR, and a timeout so a dead relay fails instead of blocking forever.
    printf '%s\r' "$1" | timeout 5 dd of="$CLAUDE_PTY_FIFO" status=none ||
        die "write to $CLAUDE_PTY_FIFO failed — is claude-pty.py still running?"
}

send_screen() {
    # screen exports WINDOW to the process it launches, so target that window explicitly
    # rather than whatever window the user happens to be looking at.
    local target=(-S "$STY")
    local window="${CLAUDE_SCREEN_WINDOW:-${WINDOW:-}}"
    [[ -n $window ]] && target+=(-p "$window")
    screen "${target[@]}" -X stuff "$1$(printf '\r')"
}

if [[ ${1:-} == --check ]]; then
    check_environment
    echo "ready: $(describe), $(seconds_since_last_send)s since last send"
    exit 0
fi

command="${1:-}"
[[ -n $command ]] || die "usage: send-self.sh </compact|/clear> | --check"
is_allowed "$command" || die "'$command' is not whitelisted (allowed: /compact, /clear)"

check_environment

elapsed=$(seconds_since_last_send)
if (( elapsed < COOLDOWN_SECONDS )); then
    die "cooldown: last send was ${elapsed}s ago, need ${COOLDOWN_SECONDS}s"
fi

case "$(transport)" in
    fifo) send_fifo "$command" ;;
    screen) send_screen "$command" ;;
esac

touch "$STAMP"
echo "sent $command to $(describe)"
