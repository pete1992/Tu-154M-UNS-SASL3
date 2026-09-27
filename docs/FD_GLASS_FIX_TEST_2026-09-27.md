# FD warning and hydraulic instrument glass

## Scope

Live installation: `I:/X-Plane 12/Aircraft/Laminar Research/Tu-154M-UNS-SASL3`.
Only the FD warning recovery logic and three misplaced hydraulic gauge glass
meshes were changed. Existing USVP work and unrelated ACF edits were preserved.

## FD cause and fix

`man_roll_lamp` and `man_pitch_lamp` retain earlier disconnect warnings until
acknowledged. In `absu_controls.lua`, both stored lamps also invalidated each
other's FD axis, even when LOC and GS had been successfully recaptured.

Removed only those two cross-axis lamp dependencies. Current calculator,
receiver, TKS and STU-test checks are unchanged. Warning-lamp acknowledgement,
autopilot control laws, receiver selection and HSI LD logic are unchanged.
No valid guidance at startup is still indicated as unavailable; this patch does
not permanently hide a genuine invalid/failure flag.

## Offline regression

Run from the aircraft root with LuaJIT:

```text
luajit tests/absu_fd_flags_test.lua
```

312 assertions passed using the actual mode/controller scripts with mocked
native APIs: NAV1/NAV2, 20/60/120 FPS, six-second signal loss and reacquisition,
current failures, STU test, FD off, shared-cockpit slave and new-flight reset.
Reintroducing the old dependencies in memory makes the recapture test fail.
Lua syntax and the controller whitespace diff check passed; CRLF preserved.

## X-Plane runtime checks

Test source: EDDV 27R ILS, 108.90 MHz. APP/GS/STAB were operated through their
normal button input DataRefs. Radio frequency changes produced the loss and
reacquisition; FD output flags were not forced during this regression test.

| State | LOC/GS submodes | Stored roll/pitch warnings | FD roll/pitch flags |
| --- | --- | --- | --- |
| Original runtime, initial valid capture | 6 / 5 | 0 / 0 | 0 / 0 |
| Original runtime, valid recapture after loss | 6 / 5 | 1 / 1 | **1 / 1 (bug)** |
| Reloaded fixed runtime, valid recapture | 6 / 5 | 1 / 1 | **0 / 0** |

At fixed recapture, both AP main modes were 2, both selected NAV1 validity
flags were 0, and left/right PKP pitch warning outputs were 0. The pilot PKP
warning flag was visibly retracted. Original loss correctly displayed warnings.
An earlier paused display-only 0/1 injection also confirmed that the existing
OBJ flag animation itself works; that injection and shared-cockpit test state
were restored before the receiver regression.

The post-fix regression used a temporary position-update override to keep the
test point stationary while the native receiver and SASL logic ran. This is a
live indication/capture test, not a complete flown ILS or autoland validation.
The override was released and the aircraft returned to its original ground
coordinates after testing.

## Glass cause and fix

Three meshes in `objects/cockpit_glass.obj` were offset from their instrument
frames along z. Changed only 14 vertex z coordinates per gauge:

- HYD1: +0.009 m (vertices 1382-1395, zero-based).
- HYD2: +0.006 m (vertices 281-294).
- HYD3: +0.003 m (vertices 267-280).
- Emergency brake glass already aligned and was left untouched.

17,859 structural/comparison assertions passed: 3,093 vertices, 10,200 valid
indices, only the intended 42 z fields changed; all remaining bytes, normals,
UVs and material directives unchanged. Glass edges match the frame openings
within rounding tolerance. LF preserved, including two inherited trailing
spaces in the touched vertex lines.

Live oblique and close views confirmed no glass rectangles protrude beside
the hydraulic gauges. Other instrument glass and ACF attachments were not moved.
