#!/bin/bash
#
# Compile the RTT bridge program
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RTT_SRC="${SCRIPT_DIR}/SEGGER_RTT_V816"

echo "Compiling RTT bridge..."

gcc -o "${SCRIPT_DIR}/rtt_bridge" \
    "${SCRIPT_DIR}/rtt_bridge.c" \
    "${RTT_SRC}/RTT/SEGGER_RTT.c" \
    -I "${RTT_SRC}/RTT" \
    -I "${RTT_SRC}/Config" \
    -O2 \
    -Wall \
    -Wextra

echo "✓ Compiled: ${SCRIPT_DIR}/rtt_bridge"
echo ""
echo "Usage:"
echo "  ${SCRIPT_DIR}/rtt_bridge | nc -l 12345"
