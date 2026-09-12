# XP12 engine warning regression - 2026-09-12

Target: the live I: X-Plane 12 installation, Tu-154M-UNS-SASL3, X-Plane 12.4.3.

## Reproduction and cause

The unmodified warning rules identified EGT as the source, with normal oil pressure,
fuel pressure, vibration, chip and fire inputs. A ground-run step from idle to a
0.85 pilot throttle request produced 862.0 C indicated EGT at 48.55 raw custom RPM
and 721.9 C at 68.61 RPM. All three raw and smoothed malfunction outputs were 1.
Steady intermediate settings did not reproduce the warning.

The existing SASL throttle override writes ENGN_thro_use directly. Laminar documents
that this bypasses the simulator's native overtemperature protection:
https://developer.x-plane.com/article/fadec-controlled-engines/

## Change

rud_logic.lua now schedules XP12 acceleration separately for each engine using
native Celsius EGT and its positive rate of change. The controller preserves the
existing idle demand, lever animation, steady throttle mapping and warning limits.
It uses the aircraft EGT redline minus 25 C of numerical headroom, a two-second
prediction horizon, and bounded throttle correction. These are simulator-control
parameters, not a claim to reproduce a specific real engine regulator.

No ACF parameters, EGT readings, RPM tables or alarm thresholds were changed.
The XP11 path remains unchanged. Opened SASL bindings were converted to defineProps
according to the project's standing convention.

## Live checks

Pilot requests were supplied through the local Web API throttle_ratio_all at 5 Hz.
The existing aircraft throttle controller and native engine simulation remained
active. Snapshots were sampled at approximately 1 Hz; values below are sampled
maxima. The warning logger also records cause transitions between snapshots.

| Check | Sampled EGT peak | Malfunction warning |
| --- | ---: | --- |
| Initial patched idle to 0.85 request, 30 samples | 677.4 C | None |
| Final module reload, idle to full request, 30 samples | 678.1 C | None |
| Full to 0.55 request, 15 samples | 580.3 C | None |
| Intermediate to full request, 20 samples | 670.9 C | None |

Full-request effective throttle reached 0.9798, matching the existing mapping;
raw custom RPM reached approximately 91.5 during the recorded run and continued
settling. Groundspeed remained near zero during the acceleration tests with the
parking brake set. The final reload briefly reported the existing fuel-pressure
startup transition, which cleared normally before acceleration testing.

A separate controlled test held engine 2 native EGT at 800 C for six seconds using
the temporary simulator temperature override. Indicated EGT reached 786.5 C and
raw/smoothed malfunction outputs were exactly [0, 1, 0]. Only engine 2 throttle was
limited. The previous override value (0) was restored in a finally block.

## Offline checks and limits

- engine_warning_diagnostics_test.lua: 28 scenarios, 483 assertions.
- engine_acceleration_test.lua: 18 scenarios, 27,112 assertions against the actual
  module/helper, including XP11 behavior, independent engines, predictive response,
  idle/deceleration, pause/resume, long frames, frame rates and slave ownership.
- These mocks do not simulate engine thermodynamics; the ground runs above provide
  the thermal evidence.
- No airborne go-around, full cold-start sequence, extreme-weather envelope or
  complete native N1/N2 engine recalibration was performed in this regression.
- The existing high-power aircraft reload behavior is not changed by this fix.
