# ARM-406 manual emergency beacon

Implemented in the live XP12 Tu-154M installation. Donor B2 files remain unchanged;
FMOD and PA3 are not used. The ten-second B2 test concept is adapted into a new
SASL component because this aircraft already owns the PDU controls/lamps in SASL
and SASL provides the local audio path. No xTlua DataRefs were changed.

## Cockpit operation

- Overhead ARM-406 ON and either 27 V bus above 13 V: panel ready, green ARM strip.
- Hold the ARM/EMERGENCY face for two simulated seconds: latch manual distress.
  A short click does not activate. No crash or hard-landing trigger exists.
- Left PDU button, ORDER/CONTR: ten-second lamp/monitor self-test. Never transmits.
- Right PDU button, SOUND OFF: mute the local monitor, not the beacon.
- Overhead ARM-406 OFF: clear distress/test/mute. ON returns to standby.
- Bus loss does not clear a manually activated beacon. A simplified serviceable
  internal battery sustains it; battery ageing/discharge time is not modeled.

The original M illuminated texture has no usable bright ARM/EMERGENCY lettering.
Existing lamp-atlas cells therefore provide thin green/emergency status strips
beside the unchanged text and an amber fault-window overlay. No PNG, UV of an
existing triangle, ACF entry or unrelated cockpit manipulator was modified.

## Simulation interface

All new properties use `tu154/custom/arm406/`. `manual_button` is a writable
momentary input. `unit_failed` and `battery_failed` accept 0/1 for fault injection.
Derived outputs: `mode` (0 off, 1 ready, 2 test, 3 distress, 4 fault),
`emergency_latched`, `test_active`, `test_passed` (last test result), `muted`,
`tx_1215`, `tx_406`, `aural_active`, and the three annunciator brightness values.

TX is simulator state only: continuous 121.5 indication and a deterministic
0.5-second/50-second 406 burst indication. No encoded RF message, satellite
uplink, distress-network integration or real transmission is implemented.
COM tuning, transponder, NAV, TCAS and PA3 remain untouched. The new WAV is a
synthetic local PDU monitor, not a recording from a real certified ARM-406.

Optional commands: `tu154/arm406/activate` (hold), `tu154/arm406/test`,
`tu154/arm406/sound_off`. SmartCopilot forwards the new momentary input alongside
the two existing PDU buttons; late-join state transfer is not implemented here.

## Verification

- Lua 5.1 syntax parsing of the component, host and state test.
- `arm406_states_test.lua`: real component under a SASL/audio mock; power gates,
  self-test, deliberate activation, mute, reset, battery fallback, fault inputs,
  burst state, paused/invalid time, view/audio gates, commands and shutdown.
- `arm406_geometry_test.js`: full OBJ structure and previous mesh preservation,
  triangle coverage, +Y winding, measured hitboxes, DataRefs and host registration.
- `arm406_monitor_asset.js`: deterministic mono PCM WAV generation/check.

These are offline checks, not a simulator/runtime pass. Remaining cockpit test:
reload the aircraft, inspect the PDU status strips/fault window from both seats,
check each click area and press animation, run the complete test, manually
activate, mute, interrupt bus power, then reset with the overhead switch.
Check the monitor volume and SASL log. Shared-cockpit behavior remains untested.
