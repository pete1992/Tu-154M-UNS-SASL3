# Wiper controller validation (2026-09-14)

Target: the live `I:/X-Plane 12/Aircraft/Laminar Research/Tu-154M-UNS-SASL3` aircraft.

## Confirmed controller defect and repair

`animation/ext_anim.lua` used an OFF parking dead zone (`phase > 0.1`)
and wrapped the phase before detecting park. This could leave a blade several
degrees off its stop or repeatedly overshoot park at low frame rates.

Each motor now finishes its current cycle and stops at exactly zero when OFF
and powered. Loss of either the respective DC or AC supply freezes that blade;
restoring power resumes movement or completes parking. Pause, negative time,
NaN and infinite time steps cannot corrupt the wiper phase.

Unchanged: left/right switch DataRefs, left/right angle DataRefs, physical sweep
of 0..62 degrees, slow 1.5 and fast 3 cycles per second, separate DC/AC power
requirements, cockpit manipulator/mesh geometry and all non-wiper animations.
`animation/animation.lua` only has its two existing bindings converted to the
requested `defineProps` schema; component order is unchanged.
The obsolete XP11-only sound branch/version binding in `ext_anim.lua` is removed
per the XP12-only project instructions; the existing XP12 sound call is unchanged.

## Offline evidence

`wipers_states_test.lua` loads the real component with mocked SASL properties.
Result: **11 scenarios, 677 assertions passed**. Coverage includes exact parking
from nine phases at five frame rates, partial-cycle power loss, both independent
power supplies, speed transitions, cold-and-dark, invalid time steps, angle
bounds and selected unchanged non-wiper outputs.

Lua 5.1 syntax parsing passed for the two edited components and the test script.
The scoped Git whitespace check passed. `ext_anim.lua` retains CRLF; the host
retains LF. The legacy `rain_mask.lua` was inspected but not modified in this
controller repair: it also produces shared rain data for existing systems.

## Native rain integration boundary

X-Plane's `sim/flightmodel2/misc/wiper_angle_deg` array is read-only, and all
native wiper ranges in this ACF are zero. The existing aircraft-owned angle
DataRefs should therefore continue to drive both the mesh and the native
`WIPER_param` effect; no native angle writes or ACF changes are needed.

The pre-existing `glass_ext_xp12.obj` referenced `tu154ce/anim/...`, but was not
loaded by the active ACF. Correcting that unused file alone would not fix the
live aircraft. Active glass/mask integration is checked separately by the glass
regression test, not by this controller mock.

Primary references:

- [Laminar Research: windshield rain effects](https://developer.x-plane.com/article/windshield-rain-effects/)
- [Laminar Research: windshield ice and rain protection DataRefs](https://developer.x-plane.com/article/windshield-ice-and-rain-protection-datarefs/)
- Installed `I:/X-Plane 12/Resources/plugins/DataRefs.txt`, wiper control/angle entries.

## Required in-simulator checks

Reload the aircraft, establish 27 V and 115 V supplies and select each wiper
independently: slow, fast and OFF. Verify blade travel and exact final parking,
then interrupt each motor's supply during a sweep and restore it. In rain,
verify the native cleared region follows the visible blade on the correct side
without clearing the opposite window or leaving a legacy opaque layer.

No X-Plane session was launched and no runtime/visual pass is claimed.
