# Aircraft flight-preset validation

Target: the live I: X-Plane 12 Tu-154M installation. This is offline validation, not a simulator flight test.

## Implementation

`aircraft_init.lua` applies an explicit control preset on its first update and once after each SASL `onAirportLoaded` event. `main.lua` places it after DataRef creation and before the instrument, electrical, engine, fuel and start-system updates.

The allowlist contains 186 controls: 173 existing SASL controls and the 13 existing xTlua hot-start avionics settings. All SASL paths, accessor types and hot values are checked against the actual creator files. Cold values reproduce the existing cold-reset positions; `nil` deliberately preserves controls that did not have a cold reset.

Covered systems: electrical supplies and guarded emergency disconnects; fuel pumps, automatic feed and fire valves; start fuel admission; engine gauges/fire detection; flight-control boosters and ABSU preparation; autothrottle engine disconnect buttons; nosewheel guard; bleed/cabin regulation; navigation/instrument power; overhead power guards; window/probe heat; ice detection; MSRP; exterior lights/passenger signs; TCAS; engine/sensor covers and chocks; Kontur/UBS/UNS/WX/SRPBZ/SZT avionics.

Nine start-panel selectors, switches and buttons are reset to their creator default of zero for both presets. A button held in the previous flight cannot therefore start or stop a new APD sequence before native engine telemetry has settled.

The initializer does not start native engines, change mixture or ignition, engage the autopilot, rewrite navigation routes, clear failures, alter fuel/payload/hydraulic quantities, or override normal system power and failure gates. It does not poll the startup preference after applying a preset. Manual shutdown and switch movement remain possible immediately afterward. A SmartCopilot slave consumes the initialization request without writing; later acquisition of control does not unexpectedly apply an old request.

## Lifecycle and xTlua evidence

- Installed `plugins/sasl/data/init/initProcessing.lua` lines 205–208 document `onAirportLoaded(flightIndex)` as the user's new-airport/new-flight callback. The parameter is not documented as an AI aircraft index, so no `flightIndex == 0` filter is used.
- `T154.zmisc.aircraft_load()` already assigns the 13 hot avionics values. Their existing xTlua init constructors synchronously publish writable `number` DataRefs; weather handlers are empty and the remaining selected controls have no notifier side effects.
- The inspected simulator log loads xTlua at lines 638–645 before delayed SASL main-module construction at lines 856–864; xTlua relinks SASL inputs afterward at line 1078. All 13 paths appear among registered DataRefs at unload. Existing SASL UNS/WX bindings use the same `globalPropertyf` access pattern.

## Checks run

From the aircraft root:

```powershell
node .codex-tests/aircraft_init_test.js
```

Results: Lua 5.1 syntax passed; host ordering and all 13 xTlua startup values passed; 8,501 Lua mock assertions passed against the exact 186-control allowlist.

Scenarios include fresh hot start with initially zero engine telemetry, fresh cold start, arbitrary/nil airport indices, callback-before-first-update, multiple queued callbacks, same-aircraft hot/cold restart, manual switch changes after initialization, changed preferences without a new-flight event, and SmartCopilot slave/control transfer. Any write outside the control allowlist fails the test.

The JavaScript runner supplies read-only file access because the available Fengari CLI omits `io.open`. The Lua test also supports a native interpreter with normal file I/O.

## Remaining simulator checks

Fully reload the aircraft with engines running, then verify normal electrical power, fuel pressure, instrumentation, controls, avionics and cover removal. Repeat after a cold flight using the same aircraft without restarting X-Plane. Verify subsequent deliberate shutdown is not overridden. Native engine combustion, hydraulic buildup, high-altitude hot spawning, and real plugin event timing are not reproduced by these mocks.
