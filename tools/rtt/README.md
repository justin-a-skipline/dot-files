# rtt_bridge - Bidirectional RTT to Network Bridge

A bidirectional bridge for testing embedded systems using J-Link RTT instead of UART.

## License

**rtt_bridge.c and compile script:** MIT License - See file headers

**SEGGER RTT SDK:** SEGGER license (see `SEGGER_RTT_V816/LICENSE.md`)
- Redistribution permitted with copyright notice
- Used for J-Link RTT communication
- Download: https://www.segger.com/downloads/j-link/

## Requirements

- J-Link debug probe
- GCC compiler
- Connected MCU with RTT enabled firmware

## Quick Start

```bash
# Compile
./compile_rtt_bridge.sh

# Use
./rtt_bridge | nc -l 12345
```

## Architecture

```
MCU (RTT) ↔ rtt_bridge ↔ netcat ↔ Network
```

## Files

- `rtt_bridge.c` - Main bridge program (MIT License)
- `compile_rtt_bridge.sh` - Build script
- `SEGGER_RTT_V816/` - SEGGER RTT SDK (SEGGER License)

## SEGGER RTT Attribution

This tool uses SEGGER Real-Time Transfer (RTT) software.
RTT is copyright © SEGGER Microcontroller GmbH. See `SEGGER_RTT_V816/LICENSE.md` for details.

## Links

- J-Link: https://www.segger.com/j-link
- RTT Info: https://www.segger.com/products/debug-probes/j-link/technology/about-real-time-transfer
