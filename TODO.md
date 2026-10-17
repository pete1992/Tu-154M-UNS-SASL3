# TODO - Tu-154M: deferred B2 concepts

Source comparison: local Tu-154B2-CE-master v1.41-dev, 2026-10-17.
The user selected comparison points 1-7 for implementation. The following ideas remain open and are not implemented by that selection.

## Operating state per airframe (comparison point 8)
- [ ] Optional persistent wear, oil quantities, operating hours and failures per registration/livery.
- [ ] Reuse the M declarative save format and SmartCopilot write ownership; retain current per-livery T154_config.dat settings.
- [ ] Define default-livery fallback, migration of the current shared saved_state.ini and safe livery switching.
Reference: B2 Custom Module/save_state.lua (livery-dependent path); M save_state.lua (shared state).

## Additional improvements
- [ ] TAWS side-profile warning/pull-up boundaries: feed the display from the existing M warning calculation; avoid B2's duplicated nested terrain probes.
- [ ] Fuel temperature: vary thermal response with actual M tank masses and a suitable flight-temperature source; retain current safe gauge dynamics and validate heat-transfer constants.
- [ ] Ground deicing: treatment vehicle/UI, fluid selection, treatment duration, snow and remaining protection indication. Implement coherent native XP12 wing/tail effects, abort rules and M geometry. B2's partial physics and displayed protection times are not validated M values.
- [ ] Cabin/outside walkaround via stairs: adapt collision boundaries, seats, doors, stairs and camera/VR behavior to M geometry.
- [ ] EFB fork-angle calculator from departure/destination ICAO, plus destination elevation: robust navigation-data parsing, unavailable-airport handling and validated formulas. Do not copy the inactive B2 weather request.

## Larger system projects
- [ ] RA-56: three independently moving hydraulic servo channels per axis, disagreement detection, isolation and locking. Preserve M ABSU control laws/limits and existing PPN-13/failure interfaces; validate mechanical data and flight behavior.
- [ ] SVS: coherent pressure/temperature sensor states, warmup, covers, heating and icing. Establish M sensor allocation, heater power, time constants and interactions with native icing before implementation.
- [ ] SARD: explicit regulators and outflow valves for individual failure scenarios. Establish actual M hardware/volume/limits first; compare against existing native X-Plane pressure physics, handle override ownership and timestep integration.

## Optional historical equipment
- [ ] PA-3/NVU chart and flight-plan editor only as a consciously selected historical equipment option; retain UNS/GTN/GPS guidance in the current M configuration.
- [ ] KLN90B only as optional equipment, with cockpit/UI/integration scope defined separately.
- [ ] Optional moving seat frames: M currently animates its armrests, not seat translation. A sliding-seat feature needs separate geometry, controls and motion DataRefs before adding its movement sound.

## Comparison decisions: no blanket port
- Kontur/weather/TCAS, ABSU integrators, PPN-13, 8.33-kHz radios, EFB basic calculators, wear persistence and per-livery configuration already exist in M.
- Keep the M xTlua electrical worker architecture and existing causal-failure policy.
- Do not port NK-8 engine limits, RT-12 behavior, fuel/SFC or temperature coefficients into D-30 engines without M evidence.
- B2 camera_shake and slow_load components are inactive; reassess any future feature independently.
- B2 FMOD currently covers a limited set of controls; it is not evidence of a complete engine-audio replacement.
- Do not carry over B2 brake channel cross-wiring, side-dependent temperature mistakes, AP-altitude writes from map rendering or per-frame debug error logging.

## Simulator acceptance for selected points 1-7
- [ ] APU weak-battery startup, electrical/pneumatic load steps and engine-start demand.
- [ ] GS2 steering demand, towing isolation, pump pressure/current transients and emergency gear regression.
- [ ] Independent left/right braking energy and temperature, cooling with/without electrical power, wear/failures and shutdown.
- [ ] RSBN audible identification through SPU, station changes and signal/power loss.
- [ ] Hardware commands on press/hold/release and each relevant control position/cover/power state.
- [ ] Cabin heating/cooling with doors/windows open/closed, occupancy and cockpit-door exchange.
- [ ] Touchdown, wipers, door/armrests: sound balance, source placement, views, pause and reload/shutdown.
