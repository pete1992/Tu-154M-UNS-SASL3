# Windshield, probe heat, wipers and passenger glazing

Date: 2026-09-14. Target: live I:/ X-Plane 12 aircraft, branch xp12.

## Implemented control paths

- `antiice_logic.lua` no longer switches the native windshield heater OFF every
  frame or resets visible native window ice to 0.5 as a makeshift ice sensor.
  SOI/legacy wing accumulation now reads the native `ice_delta` rate, retaining
  the existing factor of two. This sensor substitution still needs an icing
  flight check; unchanged gates alone do not prove identical wing accretion.
- Window switches retain OFF (0), normal (-1) and strong (1). Their established
  0.015/0.02 rates become native thermal-source defrost times of 66.67/50 seconds
  for a fully frozen pane without ongoing accretion. Native XP12 controls the
  actual weather-dependent ice effect; it is not instant clearing.
- Electrical mapping stays left pane = left 27 V + AC bus 1; center/right panes
  = right 27 V + AC bus 3. DC must exceed 13 V and AC 110 V. Custom and native
  heater failures disable the corresponding circuit; custom AC loads retain
  their previous rates and master-only update ownership.
- Native channels are 0=left, 1=right, 2=center; channel 3 is unused/OFF. The
  center source therefore uses XP12's generic third-window failure slot named
  `rel_ice_window_heat_l_side`. SASL element access is one-based and the helper
  converts explicitly from the zero-based OBJ channel index.
- Three local defrost-time DataRefs are created in the SASL binding table:
  `tu154/custom/antiice/window_heat_time_1/2/3` (left/center/right). OBJ thermal
  sources use the read-only, failure-aware native `ice_window_heat_running[]`.
- All three PPD switches now operate native pilot/copilot/standby Pitot heaters,
  with associated AoA, static and TAT protection. This is the model's probe-group
  implementation, not a claim of exact real-aircraft wiring. PPD 1 uses the left
  DC bus, PPD 2/3 the right. Existing DC loads remain 10/7/7 A. Standby honors
  both its custom failure and XP12 standby failure. TEST (-1) is diagnostic only.
- Probe TEST lamps require their own live bus and healthy heater. Random probe
  failure checks no longer repair a latched failure after an unsuccessful draw.
  Overheat exposure requires a healthy powered HEAT circuit on the ground; OFF,
  TEST, flight or power loss resets exposure. Existing unrelated failure behavior
  and the existing failures-disabled resets are retained.
- Wipers retain separate supplies, slow/fast speeds and 0..62-degree mesh travel.
  OFF now completes the cycle and parks at exactly zero without a dead zone.
  The native wiper effect reads the same custom angles as the physical blades.

## Active glass integration

- ACF slots 27/28 replace the old `drops_window.obj` / `snow_window.obj` overlays
  with `glass_front_rain.obj` (flags 8194) and `glass_front_reflector.obj` (8195).
  These outside/inside rain-glass flags were checked against the installed
  Laminar C172. Attachment offsets and all other ACF fields are unchanged.
- The new front-pane pair retains this M model's exact XYZ, normals and triangle
  winding. Only UVs are mapped to already-present `windshield_thermal_out.png`
  and `wiper_out.png` assets using matching donor Y/Z vertices. No donor aircraft
  width/geometry, textures, FMOD or other systems were copied.
- `glass.obj` retains passenger-window meshes, door-window animation, original
  UVs, transparent albedo and reflections. Its dark legacy `glass_LIT.png`
  coating is disconnected. Duplicate front-pane drawing is disabled only where
  the new native pair takes over. Passenger windows are not electrically heated.
- No raster assets are edited. The existing narrow thermal-mask edge is retained
  rather than shifting the UVs and altering the wiper-mask alignment.

## Offline verification

- `window_probe_heat_test.lua`: 18 scenarios / 874 assertions passed.
- `heater_panel_failures_test.lua`: 103 assertions passed.
- `wipers_states_test.lua`: 11 scenarios / 677 assertions passed.
- `glass_native_test.js`: mesh/index preservation, transparent passenger albedo,
  active ACF bindings, independent heat/wiper channels and control-mask sampling.
- Lua 5.1 syntax checked for all edited SASL components and new Lua tests.
- Native bindings checked against installed `Resources/plugins/DataRefs.txt`;
  writes in the heating controller target writable properties, not native
  read-only status or wiper-angle arrays.
- Existing user ACF changes are preserved. SHA-256 of normalized ACF content
  excluding only slot 27/28 filenames and flags, before and after:
  `98bc298f9be1d752c92e271554dd159399b64acd03bb598f591fe0d4cc30fd94`.

New/read SASL declarations follow the requested `defineProps` pattern. No xTlua
files were changed. Legacy `rain_mask.lua`/misc derived values remain available
to existing consumers even though the old opaque OBJ overlays are detached.

## Simulator checks still required

No simulator was launched; static checks and mocked Lua tests are not a rendered
or in-flight acceptance test. Fully reload the aircraft to load the changed ACF
and OBJ files, then check:

1. Passenger-window view from inside the cabin in daylight and darkness, with
   cabin lights both OFF/ON. Confirm the reported black coating is gone while
   glass/reflections and passenger-door window positions remain correct.
2. Rain: each wiper independently in slow/fast/OFF; check swept region follows
   the visible blade, stops at park, and does not clear the opposite pane.
3. Icing: left/center/right window heater switches independently; compare normal
   and strong modes, power interruption and individual failures. Inspect edges
   for an excessive unheated strip or a duplicate reflection layer.
4. All three PPD TEST lamps with each DC supply and failure state, then HEAT in
   icing conditions. Verify pilot/copilot/standby instruments remain responsive.
5. SOI indication and wing/slat icing over time after switching windshield heat,
   plus cold-and-dark and engines-running initialization.

## Primary API references

- [Laminar: windshield ice effects](https://developer.x-plane.com/article/windshield-ice-effects/)
- [Laminar: windshield rain effects](https://developer.x-plane.com/article/windshield-rain-effects/)
- Installed SASL `data/init/initProperties.lua`: indexed property accessors.
- Installed X-Plane `Resources/plugins/DataRefs.txt`: types and write permissions.
