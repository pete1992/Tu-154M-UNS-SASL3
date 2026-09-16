<img width="2172" height="724" alt="tu154_uns_header" src="https://github.com/user-attachments/assets/de4cc515-8e23-458c-9fa4-3f7512c2da3d" />

<p align="center">
  <i>Still Soviet. Just slightly less broken.</i>
</p>

# Tu-154M UNS Community re-continuation Project  

Tu-154 UNS is a continued development and modernization project for the
Tupolev Tu-154M in X-Plane.

The project focuses on preserving the character and complexity of the original
aircraft while modernizing the underlying Lua code, improving SASL 3 compatibility,
correcting legacy system behaviour and refining the flight model using available
Tu-154M documentation and flight-test data.

**X-Plane 11 Final Release: 2.0.9**  
**X-Plane 12 Release: 3.0.0 — Coming Soon**

---

## About the Project

The Tu-154 is not a simple aircraft, and this project is intentionally not trying to turn it into one.

**Tu-154 UNS** is a continued development and modernization project for the Tupolev Tu-154M, focused on preserving the complexity, character and systems-oriented operation of the original aircraft while modernizing the underlying simulation platform.

The X-Plane 11 development line is complete with version **2.0.9**.  
Active development now continues for **X-Plane 12**, with version **3.0.0** representing the next major generation of the project.

The goal of Tu-154 UNS is to preserve the aircraft's systems-heavy nature while continuously improving:

- system accuracy and reliability
- flight-control behaviour
- aerodynamics and flight-model fidelity
- ABSU / AFCS behaviour
- navigation and avionics systems
- electrical and hydraulic systems
- fuel and engine simulation
- APU simulation
- anti-ice and environmental systems
- cockpit logic and indications
- lighting and visual effects
- failure simulation
- SASL 3 compatibility and modernization
- xTlua runtime, plugin and script infrastructure
- X-Plane 12 integration and native system compatibility
- code quality, maintainability and documentation

Development is not limited to aircraft Lua scripts. The project also includes changes to the underlying **xTlua plugin itself**, improving thread safety, plugin lifecycle handling, script reload behaviour, memory management, error handling and overall runtime reliability.

Where reliable documentation, measured behaviour or simulator data is available, it is preferred over assumptions. Existing behaviour is preserved unless there is a confirmed reason to change it.


---

## Requirements

- X-Plane 11
	or 
- X-Plane 12

- 64-bit operating system


The aircraft is final for **X-Plane 11** and is under current development for **X-Plane 12**.



---

## Installation

1. Download or clone the repository.
2. Copy the complete aircraft folder into:

X-Plane 12/Aircraft/
Example:

X-Plane 12/
└── Aircraft/
    └── Tu-154 UNS/
Start X-Plane 12.
Select the Tu-154M from the aircraft menu.
Allow the aircraft and SASL components to finish initialization before operating cockpit systems.

When updating an existing installation, replacing the complete aircraft folder is recommended unless otherwise stated in the release notes.

# The Road so far...   

## X-Plane 11

### 2.0.9 — Final X-Plane 11 Release

**Release 2.0.9 is the final release of Tu-154 UNS for X-Plane 11.**

It is also the first major cumulative update since the initial working SASL 3 based version and concludes the active development of the X-Plane 11 branch.

*This release contains extensive work on the aircraft systems, flight controls, aerodynamics, avionics, lighting, APU simulation and the underlying Lua codebase, which is essentially completely overhauled.*

Future development continues separately for X-Plane 12.

#### Core / SASL 3

- Continued migration and stabilization of legacy Tu-154 systems for SASL 3.
- Reworked numerous legacy SASL 2 components for reliable operation under SASL 3.
- Standardized DataRef/property initialization across the project using local `defineProps()` helpers.
- Fixed several Lua 5.1 compatibility and callback/upvalue limitations.
- Reduced unnecessary per-frame DataRef reads, allocations and repeated calculations.
- Improved component initialization order and startup reliability.
- Preserved SmartCopilot master/slave ownership throughout affected systems.
- Improved compatibility between X-Plane 11 and X-Plane 12 SASL sound handling.
- Replaced and cleaned up large amounts of legacy Russian code comments with consistent English documentation.
- Removed obsolete, duplicated or conflicting system logic where appropriate.

#### Flight Model & Aerodynamics

- Major rework of the Tu-154M wing and wing-tip airfoil characteristics.
- Reworked lift, drag and pitching-moment behaviour across the usable angle-of-attack range.
- Improved clean-flight aerodynamic behaviour.
- Reworked stall progression to reduce excessive prolonged mushing.
- Stall onset is now significantly sharper and less artificially stable.
- Wing and wing-tip stall behaviour has been tuned to allow a more realistic asymmetric loss of lift.
- Reworked high-angle-of-attack behaviour and post-stall characteristics.
- Improved pitch behaviour during flap extension and retraction.
- Rebalanced flap lift, drag and pitching-moment effects.
- Improved interaction between flap configuration and stabilizer position.
- Reworked Mach-dependent pitch response.
- Removed duplicated aerodynamic corrections which could result in multiple systems modifying the same flight-model behaviour.
- Extensive tuning performed using recorded flight-cycle data and Tu-154M flight-manual performance data.

#### Flight Controls

- Completely reviewed and cleaned up the primary flight-control logic.
- Corrected hydraulic booster behaviour.
- Removed the fictional manual primary-control fallback when hydraulic boosters are unavailable.
- Primary controls now correctly depend on powered hydraulic booster channels.
- Hydraulic authority is properly limited to the valid range.
- Improved actuator behaviour at low or unstable frame rates.
- Added frame-rate-independent filtering for pitch, roll and yaw pilot inputs.
- Added a small remapped control-axis deadzone to eliminate hardware/yoke jitter.
- Added gentle aileron-to-rudder coupling for users flying without rudder pedals.
- Manual rudder, rudder trim and ABSU yaw commands remain fully additive.
- Corrected force-loader electrical consumption and state handling.
- Mach-dependent control-force simulation now affects pilot input instead of incorrectly reducing the final elevator command.
- Mechanical trim and ABSU commands retain full booster authority.
- Elevator travel is now independent of horizontal stabilizer incidence.
- Full elevator travel remains available at every stabilizer position:
  - approximately 25° nose-up;
  - approximately 20° nose-down relative travel.
- Improved low-speed elevator authority.
- Preserved existing spoiler, reverse-thrust and ABSU integration.

#### Stabilizer / Trim

- Reworked stabilizer and elevator interaction.
- Corrected the behaviour of the automatic stabilizer schedule.
- Improved transitions between takeoff, climb, approach and landing configurations.
- Stabilizer movement no longer artificially consumes available elevator travel.
- Improved pitch response while the stabilizer returns toward the enroute position.
- Reduced excessive pitch changes during flap/stabilizer transitions.
- Preserved the Tu-154M CG-dependent stabilizer schedule.

#### APU

- Major cleanup and stabilization of the APU simulation.
- Reworked APU heating and cooling behaviour.
- Reduced excessive APU heat accumulation.
- Improved EGT, internal APU temperature and oil-temperature dynamics.
- Improved starter and bleed-air behaviour.
- Restored the legacy APU random-failure system for SASL 3.
- Restored APU runtime-based failures.
- Added the previously missing APU runtime DataRef handling.
- Added a dedicated PTA-6A tachometer-converter failure.
- Preserved hot-start, high-EGT, oil-temperature and residual-fuel failure logic.
- Failure generation now correctly respects SmartCopilot ownership.
- Disabling global failures reliably clears all APU failure states.

#### Electrical & Lighting

- Reworked several external-light calculations.
- Landing-light brightness now follows the actual physical deployment position.
- Landing lights no longer instantly illuminate at full intensity while extending.
- Corrected landing-light electrical bus scaling.
- Limited voltage coefficients to the valid range so overvoltage cannot artificially increase brightness or deployment speed.
- Corrected nosewheel taxi-light visibility.
- Taxi lights are now enabled only when the nose gear is almost fully deployed.
- Hidden taxi lights no longer consume simulated electrical current.
- Corrected flight-signal-light electrical load calculations.
- Reworked white navigation-light flash timing.
- White wing flashes now operate simultaneously with a short high-intensity pulse.
- Improved beacon timing.
- Preserved individual landing-light failures and electrical supply dependencies.
- Preserved Virtual Airline landing-light compatibility behaviour.

#### Cockpit / Cold & Dark

- Reworked cold-and-dark initialization for multiple cockpit systems.
- Existing or manually selected switch positions are no longer unnecessarily overwritten.
- Protective caps now correctly enforce their associated switch position.
- Programmatic cold-and-dark initialization no longer generates artificial cockpit sounds.
- Landing-light extension and mode switches are correctly included in cold-and-dark handling.
- Improved switch, cap and pushbutton sound-change detection.
- Opposing switch changes can no longer cancel each other and suppress sounds.
- Improved initialization of several overhead-panel controls.
- Corrected water-system startup state when the aircraft is not loaded cold and dark.

#### ABSU / AFCS

- Continued cleanup and stabilization of the ABSU implementation.
- Improved interaction between ABSU commands, mechanical trim and hydraulic flight controls.
- ABSU commands are no longer incorrectly weakened by the pilot Mach-response curve.
- Corrected several ABSU DataRef and property handling issues.
- Improved ABSU annunciator logic.
- ABSU READY indication now illuminates correctly when the required systems are healthy.
- Preserved existing roll, pitch, yaw, approach and stabilization modes.

#### Navigation / Displays

- Continued modernization of the Captain and First Officer navigation displays.
- Improved separation of the two display units.
- NAV and TAWS operation can now be selected independently between both displays.
- Weather-radar display is available independently on both units.
- Corrected several display and drawing compatibility issues introduced during the SASL 3 migration.
- Improved handling of legacy navigation components within the SASL 3 environment.

#### Load & Fuel Planning Panel

- Reworked internal state handling to remain safely within Lua 5.1 limits.
- Fixed route-change detection for main and alternate flight calculations.
- Fuel calculations now update correctly when either distance or flight level changes.
- Opposing simultaneous value changes can no longer accidentally suppress recalculation.
- Reduced repeated table allocations and calculations.
- Reused fuel-interpolation data instead of recreating it every frame.
- Optimized CG calculation handling.
- Removed redundant CG writes during fast loading.
- Corrected the 0% payload preset so both cargo compartments are also emptied.
- Preserved the original Tu-154 payload, CG, fuel-distribution and tank-limit logic.

#### General Fixes & Cleanup

- Fixed numerous missing or incorrectly scoped DataRef properties.
- Corrected several SASL 2 → SASL 3 API incompatibilities.
- Fixed various sound playback API issues.
- Fixed several drawing-function argument and parameter errors.
- Fixed nil-function and component initialization errors found during migration.
- Reduced unnecessary writes to unchanged DataRefs.
- Improved code readability and internal documentation.
- Preserved original aircraft behaviour wherever no correction was required.

---

**2.0.9 marks the end of active X-Plane 11 development.**

The X-Plane 11 version will remain available as the final stable release of that branch, while future Tu-154 UNS development continues on X-Plane 12.

## X-Plane 12

### X-Plane 12 Migration

- Added a dedicated X-Plane 12 aircraft configuration and converted airfoils.
- Updated aircraft systems for native X-Plane 12 DataRefs and behavior.
- Corrected X-Plane version detection throughout the aircraft systems.
- Removed or replaced legacy X-Plane 11 compatibility paths where required.
- Updated cockpit and aircraft object materials for X-Plane 12 rendering.
- Added X-Plane 12 specific aircraft icons, preferences and supporting assets.

### Flight Model & Aerodynamics

- Converted all three D-30KU-154 engines to X-Plane's two-spool jet model.
- Corrected the takeoff and high-cruise specific fuel consumption assignments.
- Recalibrated the native maximum thrust limit for all three engines.
- Revised aircraft geometry in the X-Plane 12 ACF where required.
- Reworked flap pitching-moment behavior for X-Plane 12.
- Preserved the established flap CL/CD characteristics while adding a stronger
  speed-dependent nose-down pitching moment at higher flap operating speeds.
- Updated the asymmetric stall supplement to version 4.4.0.
- Stall development is now driven primarily by sustained AoA and actual elevator
  position instead of raw joystick/aggression gates.
- Stall separation remains active with trim-held elevator even with a neutral joystick.
- Added sustained low-AoA recovery logic and controlled re-entry during recovery.
- Added roll-induced local AoA effects across the virtual wing elements.
- Reworked stall/spin damping to retain high-rate damping without over-stabilizing
  the separated-flow regime.

### Engines

- Added X-Plane 12 specific N1/N2 and EGT handling.
- Added independent per-engine EGT-aware acceleration protection.
- Engine acceleration now anticipates excessive EGT instead of applying one
  common throttle restriction to all engines.
- Pilot throttle lever position remains independent from the internal
  engine-protection output.
- Improved engine-start logic for X-Plane 12.
- Balanced starter command begin/end handling.
- Starter commands are reliably released on abort, authority loss and module shutdown.
- Engine start timers now use simulation time and no longer expire while paused.
- Restored electrical, cover, dry-crank and starter-button interlocks.
- Successful XP12 starts require sustained combustion above the configured
  starter completion threshold.
- Improved engines-running flight initialization.
- Corrected generator availability and behavior at ground idle.
- Improved cold-and-dark / engines-running system initialization.

### ABSU / Autothrottle

- Reworked LOC and glideslope guidance for X-Plane 12.
- Added actual NAV receiver signal-validity checks.
- NAV1 and NAV2 are now treated as independent approach receivers.
- The selected failed receiver can no longer silently borrow guidance from
  the other receiver.
- Improved LOC/GS signal-loss and reacquisition handling.
- Prevented derivative kicks after frequency or signal changes.
- Improved frame-rate independence of approach guidance.
- Bounded ABSU outputs during long frame stalls.
- Increased available ILS roll-command authority.
- Corrected landing-mode indication reset when landing preparation is deselected.
- Improved manual autothrottle disconnect and throttle handover behavior.
- Pilot throttle movement is preserved while the autothrottle servo owns the levers
  and is applied correctly after servo release.
- Improved autothrottle disconnect warning behavior.

### Navigation / KONTUR / Weather Radar

- Migrated KONTUR weather radar control to X-Plane 12 cockpit2 EFIS controls.
- Added native X-Plane 12 weather radar mode and gain control.
- Added independent left and right weather-overlay control.
- NAV and WX layers can now be displayed simultaneously.
- TCAS can be overlaid on NAV and NAV/WX without hiding the route.
- Added functional WX2000 TILT control.
- Added TEST, WX, WX/TURB and MAP radar mode selection.
- Added windshear radar control and indication support.
- Updated KONTUR cockpit manipulators and display geometry.
- Reworked KONTUR DataRef registration into declarative binding tables while
  preserving existing global names and notifier behavior.
- Updated GNS/UNS integration around the shared native GPS1 receiver.

### ARM-406 Emergency Beacon

- Added a functional ARM-406 / PDU-406 emergency beacon simulation.
- Added manual emergency activation through the cockpit ARM/EMERGENCY control.
- Emergency activation requires a deliberate two-second hold.
- Added ten-second PDU control/lamp test.
- Added local emergency-beacon monitor audio.
- Added SOUND OFF control for the local monitor.
- Emergency activation remains latched after aircraft electrical power loss.
- Added simplified internal battery behavior for an activated beacon.
- Added dedicated cockpit manipulators and annunciator logic.
- Added SmartCopilot synchronization for the manual activation control.
- No automatic crash or hard-landing activation is simulated.

### Brakes & Ground Handling

- Improved left/right brake pedal synchronization.
- Small pedal differences are treated as a common braking demand while deliberate
  differential braking remains independent.
- Preserved independent left/right brake failures.
- Preserved parking brake, emergency brake and wheel-chock behavior.
- Brake control now respects SmartCopilot ownership.
- X-Plane brake override is reliably released during normal or error shutdown.
- BetterPushback integration is now optional.
- Added silent BetterPushback detection and delayed-load retry.

### Anti-Ice / Windows / Wipers

- Reworked windshield heating for X-Plane 12 native icing behavior.
- Removed the legacy behavior that repeatedly reset native windshield ice.
- Existing OFF / normal / strong windshield heater switch positions are preserved.
- Updated icing-rate input for the existing SOI/wing icing logic.
- Reworked probe-heating and heater-failure handling.
- Added X-Plane 12 native front-window rain and reflection geometry.
- Added dedicated rain and reflector objects for the front cockpit glazing.
- Removed legacy opaque rain-overlay dependence from the active windshield rendering.
- Reworked windshield wiper behavior for native XP12 rain effects.
- Preserved independent wiper speeds and park behavior.
- Updated passenger glazing and reflection materials for X-Plane 12.

### Electrical / Pneumatic / Other Systems

- Added the required X-Plane 12 pneumatic bridge for APU-assisted engine starts.
- Improved generator logic and native generator availability checks.
- Improved battery and electrical system compatibility with X-Plane 12.
- Improved hydraulic and fuel-system initialization.
- Added additional TAWS protection against invalid/non-finite terrain probe data.
- Updated several cold-and-dark reset conditions for reliable engines-running starts.
- Improved shared system timing and bounded long-frame integration steps.

### SASL / xTlua / Code

- Updated SASL from 3.22.5 to 3.23.0.
- Updated bundled SASL binaries for Windows, Linux and macOS.
- Updated SASL widget resources and configuration.
- Continued migration of SASL DataRefs to the project `defineProps()` structure.
- Updated xTlua integration for X-Plane 12 systems.
- Added extensive offline regression tests for:
  - ABSU / ILS guidance
  - NAV receiver isolation
  - engine acceleration protection
  - engine-start behavior
  - generator idle behavior
  - autothrottle disconnect behavior
  - braking
  - BetterPushback integration
  - KONTUR / weather radar
  - ARM-406
  - anti-ice and windshield heating
  - wipers and XP12 glazing
  - aircraft initialization
- Added static ACF validation and regression checks.

### Visual / Cockpit

- Added X-Plane 12 compatible cockpit glass and rain-effect objects.
- Updated cockpit normal maps and materials.
- Updated KONTUR and weather-radar controls and manipulators.
- Added ARM-406 cockpit interaction surfaces and annunciators.
- Updated project branding and repository header.

## XP12 Beta

### Navigation / SP-50 / KATET

- Added the SP-50/KATET navigation control system.
- Added dedicated KATET DataRefs for:
	- ILS / KATET / SP-50 source selection
	- Enroute / Landing mode
	- Day / Night indication mode
	- DME / RSBN distance selection
	- Added animated and clickable cockpit controls for all KATET selectors.
	- Separated the new KATET control states from the legacy SP-50 DataRefs.
	- Integrated KATET source selection with the ABSU navigation and landing logic.
	- Source changes now correctly cancel stale LOC/GS captures and reset radio-approach acquisition state.
	- Prevented automatic capture of a newly selected navigation source; NAV/VOR/APP must be selected deliberately.
	- Added automatic HSI source switching to the selected landing receiver during radio approaches.
	- Added protection against stale Landing mode indications on the PNP instruments.
	- KATET mode now feeds GPS1 lateral guidance to the PNP/ABSU navigation system.
	- GPS/KATET guidance is lateral-only; no artificial glideslope is generated.
	- ILS and SP-50 landing modes use the actual powered NAV receiver and genuine LOC/GS validity.
	- Reworked SP-50/KATET COURSE and GLIDE annunciator logic to follow actual source validity.
	- Added Day/Night brightness control for KATET signal annunciators.
	- Lamp test now illuminates all KATET COURSE/GLIDE indicators.

### DME / RSBN

- Added selectable DME/RSBN distance indication.
- Added explicit RSBN distance-valid state for digital displays.
- RSBN digital indication now updates only while a valid RSBN range is available.
- Preserved the existing mechanical RSBN behavior of retaining the last valid distance after signal loss.
- DME receiver failures no longer suppress the display when RSBN is selected.
- Corrected DME electrical power validation.
- Preserved independent NAV receiver and NM/km selection for both DME indicators.

### Engine Instruments

- Recalibrated the XP12 N1/N2 tachometer conversion tables.
- Updated both ground-level and high-altitude spool-speed calibration.
- Corrected the relationship between X-Plane 12 engine spool values and the Tu-154M cockpit RPM indications while preserving the existing cockpit indication scale.

### Engine Warning System

- Removed normal thrust-reverser transit from the ENGINE FAIL warning sources.
- Low oil-pressure and fuel-pressure failures are now evaluated only once the engine reaches the stabilized running range.
- Pressure monitoring now starts at N2 >= 60%.
- Prevented false ENGINE FAIL warnings during normal engine shutdown and spool-down.
- Dedicated reverser and pressure annunciators remain independent and unchanged.

### Cockpit

- Added fixed invisible manipulators for the four KATET/SP-50 controls.
- Updated cockpit animations for the new three-position source selector.
- Added Enroute/Landing, Day/Night and RSBN/DME switch animations.
- Corrected animation transforms for switches whose meshes already contain a baked rotation.
- Updated the Russian front-panel day, night/LIT and normal-map textures.

### Code / Maintenance

- Converted the GNS430 supplement DataRef declarations to the common `defineProps()` structure.
- Consolidated engine/throttle DataRef declarations without changing the existing throttle-linking behavior.
- Preserved the existing XP12 engine and throttle modifications while applying the new calibration and warning-system fixes.
