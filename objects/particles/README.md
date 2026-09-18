# Tu-154M particle integration

`tu154.acf` attaches `particles.obj` once, with the same model origin and visibility
flags as `engines.obj`. Its supplied APU emitter position is retained. The PSS
already directs the exhaust aft (heading 179-181 degrees), so the OBJ must not
apply a second 180-degree rotation.

The active system is `apu_effects.pss`, extracted from the supplied library:

- Slot 0: `sim/flightmodel2/position/true_airspeed` (m/s).
- Slot 1: `tu154/custom/eng/apu_n1` (percent), used for rate and opacity.
- Slot 2: `tu154/custom/eng/apu_egt` (degrees C), used for rate and size.
- A stopped or cold APU emits no particles. A hot APU fades with spool-down.
- Existing particles expire within 1.5 seconds after emission stops.
- No writes to the APU simulation or electrical system are required.

`aircraft_particles.pss` is retained unchanged as the supplied source library;
it is not loaded at runtime. It contains B2-only DataRefs and unrelated default
effects. Loading only the extracted effect avoids those unresolved dependencies
without altering the stock engine, tire, fire or contrail effects.

Ground-deicing emitter placements are commented out in `particles.obj`, as
requested. The first donor emitter is named `de_ice`, not `de_ice1`. Do not enable
either placement until the service controls and DataRefs have been implemented.

Validation in X-Plane remains required after a full aircraft reload: inspect the
APU outlet and exhaust direction from outside, check cold cranking, normal running
and shutdown, and confirm that no ground-deicing spray appears.
