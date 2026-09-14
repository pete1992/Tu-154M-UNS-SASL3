# ILS / autothrottle bug fixes

Target: live Tu-154M X-Plane 12 installation, branch `xp12`.

## Changes

- `absu_mode.lua`: clearing the captain's landing preparation now clears a
  latched LD indication. Explicit NAV/VOR selections retain priority, and the
  copilot's separate selector remains independent. Manual AP disconnect alone
  does not cancel valid ILS flight-director guidance.
- `T154.systems.lua`: removed the competing held-button STU mode writer. SASL
  remains responsible for readiness, engagement, manual release and TOGA.
- `absu_at.lua`: C-button toggles are rising-edge triggered. Deliberate pilot
  movement of any active throttle by 5% of its full range, maintained for 0.10 s,
  releases AT. The existing synchronized pilot input is separate from AT servo
  output; single/common axes and remote throttle ownership use the same route.
- `rud_logic.lua`: preserve pending pilot input while AT owns the lever, then
  hand control back even if the pilot has already stopped moving the lever.
- `cabin_sounds.lua`: only falling AP-control edges sound AP OFF. AT engagement
  is silent; actual AT release and genuine independent AP failures still warn.
- Existing XP12 AT PD gains remain `0.008` / `-0.05`; unrelated aircraft tuning,
  failures, power gates, warning priorities and shared-cockpit ownership remain.

## Offline checks

The tests load actual Lua components with mocked simulator properties. They are
not an aircraft reload, hardware throttle test or flight-dynamics validation.

- `ils_modes_test.lua`: 31 scenarios / 468 assertions, including a reproduced
  pre-fix LD failure, landing/reset/source selection, NAV2, capture, receiver
  loss, manual AP override, TOGA and power/failure gates.
- `ils_receivers_test.lua`: 82 assertions plus 2,000 no-signal frames.
- `ils_controls_test.lua`: 13 guidance scenarios.
- `ils_integration_test.lua`: 4 scenarios / 192 assertions / 5,292 frames.
- `at_alarm_edges_test.lua`: 14 scenarios / 94 assertions.
- `at_manual_disconnect_test.lua`: 23 scenarios / 73,279 assertions, actual AT,
  throttle actuator, xTlua systems and cabin-sound integration. Covers both
  update orders, input filtering, ownership, held controls, genuine failures,
  XP12 gains and manual takeovers.
- Existing start/idle, heater, wiper and glass regression suites were rerun.
- Lua 5.1 parsing and scoped Git whitespace checks were run.

The old ILS tests waited only 1.2 or 3 seconds for sustained receiver loss. Their
fixtures now wait beyond the existing five-second grace period; production
receiver-loss timing was not changed. Mechanical-conversion/mesh audits use the
explicit pre-change Git baseline so committing does not invalidate the checks.

## Simulator confirmation still required

1. Capture LOC/GS, switch landing preparation OFF and check that APP/GS and the
   captain's LD indication clear; reselect an approach and NAV/VOR afterwards.
2. Engage AT with both a short and held C press: no AP OFF sound or mode cycling.
3. Move one active physical throttle deliberately: AT must release once, sound
   its normal disconnect warning and give manual thrust control back. Repeat
   with a common axis, in TOGA, and with a throttle-up/down command.
4. Leave the hardware untouched while AT moves the virtual levers; no false
   disconnect should occur. Verify genuine AP/AT failures remain audible.
