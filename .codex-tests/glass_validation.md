# XP12 windshield and passenger glazing validation

## Loaded sources and material correction

The original active ACF loaded `drops_window.obj`, `snow_window.obj`, `glass.obj`
and `cockpit_glass.obj`. The pre-existing `glass_ext_xp12.obj` and its thermal/wiper
bindings were not loaded. Merely fixing their obsolete DataRefs would do nothing.

Passenger glazing is the `glass.obj` range `TRIS 648 768` and the three passenger
door ranges at indices 1968, 2016 and 2064. These remain drawn, with every original
position, normal, index and UV unchanged. The base `glass2.png` is entirely alpha 0.
The removed `glass_LIT.png` is instead a visibly dark frost texture: example pixels
are RGB 19/21/21 with alpha 210, not a clear passenger-glass material. No window
texture image was modified. The original flat normal map and dielectric specular
setting are retained.

This is a source-level correction of the legacy coating paths, not visual proof
that the LIT file alone caused the reported symptom. In particular, the passenger
range used `no_LIT`, so its exact day/night contribution cannot be established
without the renderer. The two also-active legacy rain/snow overlays covered the
passenger windows and used light-level-driven opacity. They are no longer attached
to the ACF; native effects now occupy their two attachment slots. The passenger
windows therefore no longer receive those legacy dark rain/snow/frost passes.

No livery supplies `glass2.png`, `glass_LIT.png`, the thermal map, or a rain mask.
The Orenair livery's `glass.png` is not referenced by the loaded glazing now.
`cockpit_glass.obj` remains unchanged. Its triangle centers do not project within
2 cm of the new windshield; the nearest projected surface is about 14.5 cm away,
so the structural check finds no second coplanar front-glass pass there.

## Native front glazing

`glass_front_rain.obj` and `glass_front_reflector.obj` each contain 56 triangles,
copied numerically from the original M's respective outward and inward front panes.
The old front draw calls alone are disabled in `glass.obj` to avoid duplicates.
The root ACF change binds them as Outside Rain Glass (8194) and Inside Reflector
(8195), matching the installed Laminar C172 pair. Attachment offsets and all other
ACF properties remain unchanged.

Only UV coordinates are transferred from the donor B2's existing front-window
mask layout. Outward front-pane Y/Z positions match within 10 micrometres; the B2
has a different window width, which is deliberately not copied. Inside vertices
retain their original positions/normals and use the corresponding outside UVs.
There is no UV inset or rescaling. Existing mask files are reused unchanged.

The RGB thermal channels represent left/right/center and read the native
failure-aware `ice_window_heat_running[0/1/2]` with the aircraft's independent
defrost-time DataRefs. Alpha is not enabled as a fourth heater. Wiper red/green
channels follow the custom left/right blade angles over the existing 0..62-degree
range. `TRIS_break` separates the three rain islands.

## Offline checks

Run `node .codex-tests/glass_native_test.js` from the aircraft directory.

- Original mesh/UV preservation and passenger draw calls verified.
- Native inward/outward normals, winding, indices, textures and ACF bindings verified.
- No stale B2/CE DataRefs, metalness or dark LIT material in the native pair.
- 48,216 thermal samples including edges: left 96.97%, right 99.99%, center 100%.
  The left source mask includes a narrow unheated border, retained to avoid moving
  the wiper UVs. This does not justify claiming that every seal pixel is heated.
- Area-weighted wiper coverage: left 42.60%, right 44.24% of each 0.30762 m2 pane.
  Donor comparison is 42.60%/44.20% with the same atlas. Equal samples per triangle
  misleadingly give about 8.3%, because most triangles are tiny seal/corner pieces.
- The existing wiper image contains 8/35 sampled low-level pixels in the opposite
  channel (maximum values 5/11). These are preserved paint/antialias remnants,
  not an opposite-side swept gradient; no raster alteration was performed.
- Original OBJ line endings retained; whitespace diff check passes.

## Remaining simulator checks

Reload the aircraft. Check passenger windows from cabin/exterior in dry weather,
rain and at night; confirm no dark coating and that glazing/reflections remain.
Check front-pane rain and freezing conditions, independent heaters and failures,
both wiper speeds and park, and especially the blade-to-cleared-area alignment.
The offline comparison validates mapping consistency, not the live rain renderer.
Cockpit side/roof windows are not part of this three-front-pane native rain pair.

## Primary references

- https://developer.x-plane.com/article/windshield-rain-effects/
- https://developer.x-plane.com/article/windshield-ice-effects/
- Installed XP12 `Resources/plugins/DataRefs.txt` (native running-status array).
- Installed C172 ACF `glass_out.obj` / `glass_inn_reflector.obj` attachment flags.
