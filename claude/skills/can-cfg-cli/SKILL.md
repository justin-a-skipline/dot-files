---
name: can-cfg-cli
description: >-
  Build can-cfg (Truck Designer) and drive it from the command line in the
  Skip-Line monorepo: regenerating a truck's system.h with --generate, reading
  the analyzer output, and diffing a generated system against the deployed or
  hand-written MANUAL version with the meld scripts. Use whenever the task
  involves testing a TD codegen change, comparing a generated system.h to a
  _MANUAL.h, comparing two trucks, or working out why a feature JSON edit is
  not taking effect. Covers the flags --help does not list, the exit-code
  and analyzer gotchas that make a successful run look like a failure, and the
  house idiom for emitting an output object so merged and no-pin devices work.
---

# Driving can-cfg from the command line

can-cfg is the Truck Designer GUI, but it takes a batch mode that loads a
`.truck` file, runs the system analyzer, and writes `system.h`. That is the
loop for testing any codegen change in `projects/can-cfg/sysgen/`.

Everything below runs from `projects/can-cfg`.

## Build

```bash
./scripts/command_line_dev_build -q       # -q suppresses everything but errors
./scripts/command_line_dev_build -q -t    # also build and run the unit tests
```

Output is `build/can-cfg`.

Use this script rather than calling `make` yourself. It does `touch can-cfg.qrc`
on every run, so a changed `features/*.json` or `lib/*.json` is always
re-bundled by rcc. **Do not hand-delete `build/qrc_*` to force a rebuild** — the
script already handles it, and deleting the linked binary just costs a full
relink.

`-t` builds and runs the `xmltovariant` and `xmlconfignormalizer` tests. A
failing test aborts the build, so `-t` is the single gate for "does this branch
pass?".

A `/bin/sh: line 1: test: too many arguments` line in the output is the
gdb-index step in the `.pro` file misfiring. It is harmless and unrelated to
your change.

## Regenerate a truck's system.h

```bash
./build/can-cfg --generate <path-to-.truck> --svntestonly --saveto <output-dir>
```

The full set of arguments, which is more than `--help` prints:

| flag | meaning |
|---|---|
| `--generate <file>` | Load the `.truck` and write `system.h`. Needs a direct path to the file, not the folder. Implies SVN off. |
| `--saveto <dir>` | Where the generated files go. **The directory must already exist** — create it first or nothing is written. |
| `--ioconfig` | Also write `IOConfig.xml`, for the main HDVO. Only does anything with `--generate`. |
| `--svntestonly` | Run SVN operations in test mode. Always pass this. |
| `--testtd` | TD testing mode. |
| `--help`, `-h` | Usage. |

Always write to a scratch directory rather than over
`~/skiprepo/production/systems/<NAME>/system.h`, so you can diff the two.

## Regenerate a truck's IOConfig.xml

Add `--ioconfig`. The file goes in the same `--saveto` folder as `system.h`:

```bash
./build/can-cfg --generate "$TRUCK" --svntestonly --saveto "$OUT" --ioconfig
```

The GUI writes one file per HDVO variant, into
`td_variants/<logging|non_logging>/factorydefaults/`, so diff against the
variant matching the unit you generated for.

### Which unit the file is built from

The logging unit — the DL-18 — whenever the truck has one, both here and in the
HDVO tab (`TruckConfig::mainCVOIndex()`). That is the rule, without exception:
the logging unit is always the one that gets updated. A truck whose non-logging
unit holds better data is a broken truck file, not a case to accommodate.

It matters because the `<AnalogInputs>` and `<ThermoInputs>` sections only
include channels the controlling unit has **checked** — `checkedIONodes` on the
`Cvo`, which is per-unit and can drift apart.

`SC12_A18801` is a truck with exactly that damage, worth knowing as a symptom to
recognize: its DL-18 lists eight entries that all point at a `CANLG-IN4` box
that was deleted, and none for the `CANLG-TC8` still on the truck, so its
generated file loses all four thermocouple inputs. Its first unit, `CVO-3`, has
the live keys. Fix the truck file; don't change which unit controls.

Nothing self-heals a list like that — `setAnalogInputDefaults()` skips any unit
whose stored list is non-empty, and dead keys count as non-empty.

### Differences from the deployed file are normal

Catalog long/short names get revised, so a current TD legitimately emits
`Yellow Tank Temperature` where the deployed file says
`Yellow Material Temperature`. Judge the diff by whether whole
elements/sections appear or vanish, not by text churn inside them.

can-cfg is a Qt4 GUI app, so it needs a display. `DISPLAY` is normally already
set; `xvfb-run` is **not** installed, and Qt4 has no `-platform offscreen`.

### Reading the result

Two things routinely look like failures and are not:

**Exit code 1 is normal during development.** `checkGitRepoConditions` in
`analysis/systemanalyzer.cpp` treats an out-of-sync or dirty monorepo as a fatal
analyzer error, and `mainwindow.cpp` propagates any fatal error as
`qApp->exit(1)` *after* writing the file. So a clean truck on a working branch
still exits 1. Check the `Errors:` block on stderr to tell git-sync noise from a
real truck-config problem:

```
Errors:
	Local monorepo is not in sync with upstream branch      <- ignore
Warnings:
	Differences in the IOConfig.xml detected
	Local monorepo is not the main branch
```

**The header is written even when analysis fails.** That is deliberate — it is
the dev path for porting changes into a MANUAL truck. Don't reintroduce an early
return before `genSystemHeader()` in
`MainWindow::on_actionGenerate_System_Header_For_This_Truck_triggered`.

Because exit is 1, `cmd && next` silently swallows the next step. Use `;`:

```bash
./build/can-cfg --generate "$TRUCK" --svntestonly --saveto "$OUT" >/dev/null 2>&1
diff "$REF/system.h" "$OUT/system.h"
```

A real crash is a different animal — check for `Segmentation fault` or an exit
of 139, and get a backtrace with:

```bash
gdb -q --batch -ex run -ex bt --args ./build/can-cfg --generate "$TRUCK" --svntestonly --saveto "$OUT"
```

## Comparing systems

Two scripts wrap meld. Both are also copied into `build/` by the `.pro`.

```bash
./scripts/meld_system_files_for_system.bash <system-name-or-path>
```

For one system, compares TD-generated against deployed: `td_variants/...` vs
`variants/...` for `permissions/permissions.json`,
`factorydefaults/IOConfig.xml`, `factorydefaults/DefaultUIConfig.xml` and
`loggingconfig.json`, then `system.h` against `<NAME>_MANUAL.h`. It picks the
highest-priority variant folder automatically (`logging` over `non_logging`,
`cellular_hdvo` over `logging`).

```bash
./scripts/meld_two_systems.bash <system_dir_a> <system_dir_b>
```

Compares two different trucks' deployed config files against each other, plus
their MANUAL headers when both are manual systems. Takes system **directories**,
not names.

Both open meld windows in the background, so they need a display and are no use
in a headless run. For scripted comparison, diff the files directly.

## Emitting an output object: let the machinery pick the type

When a feature's codegen needs to emit an output for a device, **do not write the
class name or the `_Init` call by hand**. Put what is special about the output
onto the `DeviceTreeNode` and let the generic helpers resolve it:

```cpp
// StandardSystemHeader::generateMMAThreeWayValvesText()
node->setOnCondition(predName);                     // sets _condition and _isConditionalOn
if (!node->connection())
{
    node->setForceDummy(ConditionallyOnDummyOutput);   // merged: wired through a parent, no pin
}

// define pass
text += getOutputDeclaration(node);

// init pass -- getOutputInitialization() falls back to _lastMappingName, so set it first
_lastMappingName = getDeviceMappingName(node);
text += getOutputInitialization(node, QString("\t"));
```

`getOutputClassName()` resolves the class from the node's own state — H-bridge,
clone, inverted, conditional-on/off, D0 listener, dummy, conditionally-on dummy.
`getOutputDeclaration()` and `getOutputInitialization()` then dispatch on it, and
the conditional branches read the predicate back off `node->condition()`. The
carriage up/down code in the same file is the reference example.

Hand-rolling this breaks two things that are easy to miss:

- **Merges.** A merge refers to its children by `getOutputName(child)`. Name the
  object yourself and the merge emits a reference to a symbol nothing declares —
  the header does not compile, and the only clue is one dangling identifier.
- **No-pin outputs.** A merged device has `isConnected() == true` but
  `connection() == NULL`, so reaching for `connection()->staxIndex()` is a
  segfault. There is no valid channel to substitute: `0` is a real output, and
  `ConditionallyOnDummyOutput_Init` registers with `OutputMapping_Add(map, out, -1)`
  where `-1` is the actual "not a physical output" sentinel. Set `forceDummy` and
  let the helper emit the no-pin flavour instead.

`node->setObjectName()` overrides the derived name, but only for text generated
*after* it is set, so a merge emitted in an earlier section still sees the derived
name. Prefer the derived name over an override you have to sequence correctly.

## Where things live

- Dev trucks: `~/skiprepo/production/systems/<NAME>/<NAME>.truck`
- Deployed generated header: `~/skiprepo/production/systems/<NAME>/system.h`
- Hand-written reference: `projects/skipper/systems/<NAME>_MANUAL.h`

When checking a generated header against a MANUAL one, **compare structure, not
symbol names**. Generated symbols come from the device names on the wiring sheet
(`clFlowMeter1Input`) while hand-written ones are whatever the author typed
(`flowMeter1`). Different spelling of the same object is expected; a different
init order, channel number, or missing object is not.

## Testing a codegen change end to end

The .truck file is JSON, so the fastest way to test a config permutation is to
copy a real truck to a scratch dir and edit the JSON, rather than clicking
through the GUI. Feature options live under the feature's `options` map:

```json
"MMA" :    {
 "name" : "MMA",
 "options" :     {
  "Pump Boost Override from HDVO" : true
 }
},
```

Wiring-sheet connections are a channel-number-to-device-name map on each box, so
unwiring a device means blanking its entry:

```json
"27" : "E/L #2 3-Way Valve"   ->   "27" : ""
```

Then generate each permutation into its own output directory and compare. Always
include the **unchanged** case and diff it against a pre-change generation — a
codegen change that alters output for trucks that should be unaffected is the
most common way to break other systems:

```bash
for t in baseline optionon optionoff; do
    rm -rf "$OUT/$t" && mkdir -p "$OUT/$t"
    ./build/can-cfg --generate "$SCRATCH/$t/Truck.truck" --svntestonly --saveto "$OUT/$t" >/dev/null 2>&1
done
diff "$OUT/baseline/system.h" "$REF/system.h" && echo "unchanged trucks unaffected"
```
