# Engine-generator idle availability regression

Target: live `I:/X-Plane 12/Aircraft/Laminar Research/Tu-154M-UNS-SASL3`.

## Confirmed source defect

`generators_logic.lua` required native low-spool `ENGN_N1_ > 25` independently for
all three generators. At or below 25, it reset the existing connection delay on
every frame and wrote the native generator switch OFF, even when X-Plane could
still generate sufficient voltage. There was no availability hysteresis.

The engine-gauge source maps native N2/N1 through separate altitude-dependent
tables. A cockpit RPM reading therefore is not the raw speed used by that old
cutoff. The current ACF has `_n2_power_curve = 3.5`; historical idle RPM readings
were not used as a current calibration. The supplied `Data.txt` has no native
engine RPM or electrical output columns. No simulator was started for this fix.

## Native input and ACF verification

The installed `I:/X-Plane 12/Resources/plugins/DataRefs.txt` declares:

- `sim/cockpit2/electrical/generator_volts`: read-only `float[8]`, potential voltage
  the generator can produce even before its external circuit is connected.
- `sim/aircraft/electrical/acf_nom_gen_volt`: read-only scalar nominal voltage.
- `sim/flightmodel/engine/ENGN_N2_`: native core rotation, `float[16]`.
- `sim/cockpit/electrical/generator_on`: writable `int[8]`, unchanged output path.

The current ACF defines three generators (indices 0, 1, 2), each rated 160 A,
one native bus, a native nominal generator voltage of 24.5 V, and a generator
design-RPM ratio of 0.25. The custom system has a separate 115 V model.

Availability therefore compares native potential voltage **as a ratio of native
nominal voltage**, never against the custom 110/115/122 V output values. It acquires
at 90% nominal and holds at 85%. This numerical hysteresis is a simulator-interface
stability margin, not a claim about a real Tu-154 regulator's calibrated limits.

Native N2 must also be positive and finite. Missing/invalid/zero supply voltage,
nominal voltage or core rotation cannot energize a generator. No burning-fuel flag,
throttle request, displayed RPM or guessed replacement idle-RPM threshold is used.

The installed SASL `initProperties.lua` confirms that array element accessors take
one-based indices. `floatElement(0..2)` / `intElement(0..2)` map them to SASL 1..3 in
the single declarative `defineProps` block. The owned file's XP11 accessor branch
was removed because this aircraft targets XP12 only.

## Preserved behavior

- Existing custom `122 - amps / 500` voltage/load curve and >110 V work indication.
- Existing 27 V excitation-bus condition and two-second connection delay.
- Normal OFF/ON/TEST transitions and immediate emergency cutoff.
- Native failures, overload delay/latching/reset, and SmartCopilot ownership.
- APU generator threshold, timing, load curve, failure and switch behavior.
- No ACF, engine tuning, throttle, fuel, geometry, or saved-state edits by this patch.

Non-finite elapsed time is also ignored rather than corrupting the connection and
overload timers. No read-only native input is written by the controller.

## Offline checks and remaining simulator test

`generator_idle_test.lua` loads the actual SASL file with indexed read/write-aware
property mocks. It checks running-state load, stopped/spooling/idle inputs,
independent engines, voltage hysteresis and nominal-voltage scaling, spindown,
DC excitation, normal/emergency/TEST switches, native failures, load droop,
overload trip/reset, APU behavior, non-finite inputs, time/ownership guards, and
SASL array indexing: **16 scenarios, 407 assertions passed**. Lua 5.1 syntax and
the scoped whitespace check passed too.

The mocked idle RPM values are test inputs, not newly measured simulator values.
The tests do not prove that X-Plane's current engine/electrical model supplies the
expected potential voltage at ground idle.

After a full aircraft reload, verify all three generators during running-aircraft
initialization, stable ground idle, idle with normal electrical loads, acceleration
and return to idle, then shut down each engine and test OFF/TEST/emergency cutoff.
If a generator disconnects, record native `ENGN_N1_`, `ENGN_N2_`, `generator_volts`,
`acf_nom_gen_volt`, failure flags and the custom DC/AC voltages and current. Do not
hide an actual native undervoltage or generator failure by forcing the work flag.
