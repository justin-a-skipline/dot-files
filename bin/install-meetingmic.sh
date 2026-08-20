#!/usr/bin/env bash
# install-meetingmic.sh — install a "MeetingMic" input device that mixes all
# system audio with your microphone, so a browser or Notion can select it as
# the meeting mic and capture both sides of the call.
#
# Works on PipeWire (PulseAudio compatibility) and on plain PulseAudio.
# Installs a control command at ~/.local/bin/meetingmic and two systemd user
# services:
#   meetingmic.service        loads the device at login
#   meetingmic-watch.service  rebuilds it when you switch output or mic
#
#   ./install-meetingmic.sh            # install and start
#   ./install-meetingmic.sh uninstall  # remove everything
#
# After install, pick "MeetingMic" in the browser microphone dropdown.

set -euo pipefail

BIN_DIR="$HOME/.local/bin"
UNIT_DIR="$HOME/.config/systemd/user"
CTL="$BIN_DIR/meetingmic"
UNIT="$UNIT_DIR/meetingmic.service"
WATCH_UNIT="$UNIT_DIR/meetingmic-watch.service"

need() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Error: '$1' not found. Install it first." >&2
        exit 1
    }
}

uninstall() {
    echo "Stopping and removing MeetingMic..."
    systemctl --user disable --now meetingmic-watch.service 2>/dev/null || true
    systemctl --user disable --now meetingmic.service 2>/dev/null || true
    [ -x "$CTL" ] && "$CTL" down 2>/dev/null || true
    rm -f "$UNIT" "$WATCH_UNIT" "$CTL"
    systemctl --user daemon-reload 2>/dev/null || true
    echo "Removed."
}

if [ "${1:-}" = "uninstall" ]; then
    uninstall
    exit 0
fi

need pactl
need systemctl

mkdir -p "$BIN_DIR" "$UNIT_DIR"

# --- control command -------------------------------------------------------
cat > "$CTL" <<'CTL_EOF'
#!/usr/bin/env bash
# meetingmic — a virtual microphone that mixes all system audio with your mic.
# Select "MeetingMic" as the input in your browser or meeting app.
set -uo pipefail

STATE="${XDG_RUNTIME_DIR:-/tmp}/meetingmic.modules"
BASE="${XDG_RUNTIME_DIR:-/tmp}/meetingmic.base"   # the sink+mic it was built on

loaded() { pactl list short sources 2>/dev/null | grep -q "[[:space:]]MeetingMic[[:space:]]"; }

load() {
    local id
    id=$(pactl load-module "$@") || return 1
    echo "$id" >> "$STATE"
}

up() {
    if loaded; then
        echo "MeetingMic already up."
        return 0
    fi
    local i
    for i in $(seq 1 50); do
        pactl info >/dev/null 2>&1 && break
        sleep 0.2
    done
    pactl info >/dev/null 2>&1 || { echo "Audio server not responding." >&2; exit 1; }

    local sink mic
    sink=$(pactl get-default-sink)
    mic=$(pactl get-default-source)
    if [ "$mic" = "MeetingMic" ]; then
        echo "Default source is MeetingMic; cannot build on itself. Set a real mic as default first." >&2
        exit 1
    fi

    : > "$STATE"
    load module-null-sink sink_name=Meeting \
        sink_properties=device.description=Meeting
    load module-remap-source master=Meeting.monitor \
        source_name=MeetingMic source_properties=device.description=MeetingMic
    load module-loopback source="${sink}.monitor" sink=Meeting \
        latency_msec=20 source_dont_move=true sink_dont_move=true
    load module-loopback source="$mic" sink=Meeting \
        latency_msec=20 source_dont_move=true sink_dont_move=true

    printf '%s\n%s\n' "$sink" "$mic" > "$BASE"
    echo "MeetingMic is up (output: $sink, mic: $mic)."
}

down() {
    if [ -s "$STATE" ]; then
        tac "$STATE" | while read -r id; do
            pactl unload-module "$id" 2>/dev/null || true
        done
        rm -f "$STATE"
    fi
    pactl list short modules 2>/dev/null \
        | awk '/sink_name=Meeting|source_name=MeetingMic|sink=Meeting/{print $1}' \
        | while read -r id; do pactl unload-module "$id" 2>/dev/null || true; done
    rm -f "$BASE"
    echo "MeetingMic is down."
}

status() {
    if loaded; then
        echo "MeetingMic is UP."
        [ -s "$BASE" ] && echo "  built on: $(tr '\n' ' ' < "$BASE")"
        pactl list short sources | grep -iE "meeting" || true
    else
        echo "MeetingMic is down."
    fi
}

reload() { down; up; }

# watch: rebuild MeetingMic whenever the default output or mic changes.
watch() {
    local prev="" cur
    while true; do
        cur="$(pactl get-default-sink 2>/dev/null)|$(pactl get-default-source 2>/dev/null)"
        # Skip if the audio server is not answering, or the default mic is
        # MeetingMic itself (nothing real to build on).
        case "$cur" in
            "|"|*"|MeetingMic") sleep 2; continue ;;
        esac
        if [ "$cur" != "$prev" ]; then
            # Compare against what MeetingMic was actually built on, not just
            # the last poll, so a rebuild only happens on a real change.
            local want built
            want="$(printf '%s' "$cur" | tr '|' '\n')"
            built="$(cat "$BASE" 2>/dev/null)"
            if [ "$want" != "$built" ]; then
                reload >/dev/null 2>&1 || true
            fi
            prev="$cur"
        fi
        sleep 2
    done
}

case "${1:-status}" in
    up)     up ;;
    down)   down ;;
    status) status ;;
    reload) reload ;;
    watch)  watch ;;
    *) echo "usage: meetingmic {up|down|status|reload|watch}"; exit 1 ;;
esac
CTL_EOF
chmod +x "$CTL"

# --- systemd user services -------------------------------------------------
cat > "$UNIT" <<UNIT_EOF
[Unit]
Description=MeetingMic virtual microphone (system audio + mic)
After=pipewire-pulse.service pulseaudio.service
Wants=pipewire-pulse.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=$CTL up
ExecStop=$CTL down

[Install]
WantedBy=default.target
UNIT_EOF

cat > "$WATCH_UNIT" <<UNIT_EOF
[Unit]
Description=MeetingMic auto-follow (rebuild on output/mic change)
After=meetingmic.service
Requires=meetingmic.service

[Service]
Type=simple
ExecStart=$CTL watch
Restart=on-failure
RestartSec=2

[Install]
WantedBy=default.target
UNIT_EOF

systemctl --user daemon-reload
systemctl --user enable --now meetingmic.service
systemctl --user enable --now meetingmic-watch.service

echo
echo "Installed."
echo "  control:  $CTL {up|down|status|reload}"
echo "  service:  meetingmic.service        (starts at login)"
echo "  service:  meetingmic-watch.service  (rebuilds on output/mic switch)"
echo
echo "Pick 'MeetingMic' as the microphone in your browser or meeting app."
