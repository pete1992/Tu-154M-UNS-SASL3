# Engine-running flight start and idle generator regression

Target: `I:/X-Plane 12/Aircraft/Laminar Research/Tu-154M-UNS-SASL3`, XP12 branch. No ACF, stall, geometry, saved-state or simulator configuration edits were made for this repair. No simulator was launched, and nothing was committed or pushed.

## Causes and changes

- Many one-shot cold initializers only inspected RPM. Initial zero telemetry could shut down fuel/electrical/instrument controls despite the selected engines-running preset. A shared startup-selection guard now protects 23 initializers, including the ground-cover and attitude-instrument setup. The hydraulic cold check also now tests engine 3 instead of engine 2 twice.
- The aircraft lacked a coordinated same-aircraft flight-preset lifecycle. `aircraft_init.lua` runs before dependent systems and applies an explicit, creator-verified control preset once at first update or the next user-airport/new-flight event. It does not continuously reopen switches, clear failures, force native engines, engage AP, change routes or synthesize bus/hydraulic outputs.
- The APD started with an already-expired timestamp. It now distinguishes initial no-combustion from an engine that has actually run; failed starts and established-engine shutdown cleanup remain effective. New-flight callbacks release owned starter commands and clear stale sequence state.
- Local fuel valves/pressure are initialized for the new flight rather than inherited from a previous cold flight. Hot priming is bounded to four simulation seconds while pump controls are requested, covering existing generator/pump startup delays. It expires if actual supply fails, is not refreshed continuously, and does not defeat manual mixture/fire-valve cutoffs or deliberate pump shutdown.
- Engine generators previously disconnected whenever native N1 was at or below 25%, without hysteresis. Availability now uses native available generator voltage relative to the configured nominal voltage, 90% pickup/85% hold, and a finite positive N2 rotational guard. Custom output/load behavior, DC requirements, contactor delay, OFF/TEST/emergency isolation, faults, overload and APU behavior remain intact.

The native voltage signal is documented as available before connection, corroborated by [Laminar's XP12.0.8 electrical changes](https://www.x-plane.com/kb/x-plane-12-08-release-notes/). This avoids depending on remapped cockpit RPM, but actual native voltage at the aircraft's current idle has not been measured in this session.

Opened legacy SASL binding blocks were migrated to the requested `defineProps` format. Binding inventories and complete executable-logic comparisons cover the mechanical changes. Existing dirty anti-ice work was preserved.

## Offline verification

- `engine_flight_start_test.lua`: actual aircraft initializer + fuel + APD components, 16 scenarios / 2,180 assertions. Includes initial zero telemetry, idle beyond 56 seconds, cold-to-hot reuse, deliberate shutdown, normal/failed/dry starts, pause/power loss, covers, shared-cockpit slave, high-altitude priming and finite priming expiry.
- `generator_idle_test.lua`: 16 scenarios / 407 assertions, including availability, hysteresis, DC loss, engine shutdown, individual failures, emergency switches and overload/APU behavior.
- `aircraft_init_test.js`: exact preset allowlist, creator types/defaults, xTlua startup values, lifecycle and host ordering. See `aircraft_init_validation.md` for final counts.
- `cold_start_guards_test.js`: 251 checks across 23 Lua files, including 138 executed startup predicates and full-file logic comparisons.
- Fuel-pump and battery schema tests prove equivalent executable logic and unchanged binding inventories.
- Existing heater panel/failure regression: 103 assertions.
- Lua 5.1 parsing passed for all 37 changed/new production Lua files, including pre-existing unrelated changes. Scoped whitespace checks passed.

## Required simulator confirmation

1. Fully reload the aircraft with **Start with engines running** selected. Confirm normal power, fuel pressure, instruments, controls, avionics and removed covers; the APD must not start a new sequence.
2. Keep all three engines at ground idle for at least two minutes, then vary idle/throttle. Watch each generator's work/voltage, native N2, native available generator voltage and native nominal voltage. There must be no unwarranted generator chatter; a genuine native undervoltage must still be detected.
3. Start cold, wait more than 56 seconds, then start a new engines-running flight using the same loaded aircraft. Repeat a normal manual engine start and deliberate shutdown.
4. Confirm one-engine failure/isolation and an aloft hot spawn. The mocks cannot prove real combustion, native electrical availability, hydraulic buildup or plugin callback ordering.
