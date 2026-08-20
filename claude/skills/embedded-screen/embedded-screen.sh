#!/bin/bash
# Shared serial console over a detached screen session.
# Both a human (attach) and an automated caller (send/read) drive one port.
# screen talks to the serial line directly, so output scrolls forward and
# lands in scrollback and the log file. No minicom, no daemon, no FIFO.

SESSION="${EMBEDDED_SESSION:-embedded}"
PORT="${EMBEDDED_PORT:-/dev/ttyUSB0}"
BAUD="${EMBEDDED_BAUD:-115200}"
LOG="${EMBEDDED_LOG:-/tmp/embedded-serial.log}"
PROMPT="${EMBEDDED_PROMPT:-[#$] *$}"   # matches when the shell prompt returns

is_running() {
    screen -ls "$SESSION" 2>/dev/null | grep -q "\.${SESSION}[[:space:]]"
}

start() {
    if is_running; then
        echo "Already running: $SESSION"
        return 0
    fi
    if [ ! -e "$PORT" ]; then
        echo "Error: $PORT not found. Is the device connected?"
        return 1
    fi
    : > "$LOG"
    screen -dmS "$SESSION" "$PORT" "$BAUD"
    sleep 0.3
    # screen 4.09 needs logging turned on explicitly; the -L flag is not enough.
    screen -S "$SESSION" -X logfile "$LOG"
    screen -S "$SESSION" -X logfile flush 1
    screen -S "$SESSION" -X log on
    echo "Started $SESSION on $PORT at $BAUD, logging to $LOG"
}

stop() {
    screen -S "$SESSION" -X quit 2>/dev/null && echo "Stopped $SESSION" \
        || echo "Not running: $SESSION"
}

status() {
    if is_running; then
        echo "Running: $SESSION on $PORT ($BAUD), log $LOG"
    else
        echo "Not running: $SESSION"
    fi
}

attach() {
    is_running || start || return 1
    exec screen -r "$SESSION"
}

# send TEXT... : type the text and press Enter. Backslashes must be doubled,
# because screen's stuff interprets \n, \t, \NNN, and ^x.
send() {
    is_running || { echo "Error: $SESSION not running. Run: $0 start"; return 1; }
    screen -S "$SESSION" -X stuff "$*$(printf '\r')"
}

# read : print the tail of the log (device output plus what was typed).
read_log() {
    tail -c "${1:-4000}" "$LOG" 2>/dev/null
}

# run TEXT... : send the command, then wait for the prompt to return, then
# print everything the command produced. Replaces the old sleep-and-hope.
run() {
    is_running || { echo "Error: $SESSION not running. Run: $0 start"; return 1; }
    local before
    before=$(stat -c%s "$LOG" 2>/dev/null || echo 0)
    send "$@"
    local i
    for i in $(seq 1 100); do   # up to ~20 s
        sleep 0.2
        if tail -n 1 "$LOG" 2>/dev/null | grep -qE "$PROMPT"; then
            break
        fi
    done
    tail -c +"$((before + 1))" "$LOG" 2>/dev/null
}

cmd="${1:-status}"
shift 2>/dev/null
case "$cmd" in
    start)   start ;;
    stop)    stop ;;
    status)  status ;;
    attach)  attach ;;
    send)    send "$@" ;;
    read)    read_log "$@" ;;
    run)     run "$@" ;;
    *)
        echo "Usage: $0 {start|stop|status|attach|send TEXT|read [BYTES]|run TEXT}"
        exit 1
        ;;
esac
