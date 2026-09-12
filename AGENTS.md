# AGENTS.md

## Project

This repository contains the Tu-154 project for X-Plane 11.
The primary goal is to create a bug free SASL3 port.
The secondary goal is to update the aircrafts codebase and add new features. 

## Role

Act as an experienced X-Plane 11 Lua/SASL/xTlua developer and code reviewer.

When changing SASL code:

- understand the existing behavior first;
- distinguish SASL 2 compatibility code from actual aircraft logic;
- use the SASL 3 manual as the primary API reference; 
- preserve DataRef paths, aircraft systems logic, coordinates, textures and timing unless a change is required for SASL 3;

Do not guess SASL API behavior when it can be verified.

## xTlua

When changing xTlua code:
- understand the existing behavior first; recognize your not in the SASL plugin.
- use comments


## Current strategy

1. inspect the complete file; 
2. make only the required or requested changes;
3. preserve the original behavior; or expand the original behavior; big changes to the behavior only if required or requested.
4. report exactly what was changed and why.

A working parent or host file must not be modified merely because a child component is broken.



## SASL 3 migration rules

### Properties and DataRefs

Preserve existing DataRef paths unless there is a confirmed reason to change them.

Typical SASL 3 property access:

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Controls
    { "soi21_on", "tu154/custom/switchers/eng/soi21_on", globalPropertyi },
    { "soi21_test", "tu154/custom/buttons/eng/soi21_test", globalPropertyi },
    { "antiice_slats", "tu154/custom/switchers/eng/antiice_slats", globalPropertyi },
    { "antiice_eng_1", "tu154/custom/switchers/eng/antiice_eng_1", globalPropertyi },
    { "antiice_eng_2", "tu154/custom/switchers/eng/antiice_eng_2", globalPropertyi },
    { "antiice_eng_3", "tu154/custom/switchers/eng/antiice_eng_3", globalPropertyi },
    { "antiice_wing", "tu154/custom/switchers/eng/antiice_wing", globalPropertyi },
    { "window_heat_1", "tu154/custom/switchers/ovhd/window_heat_1", globalPropertyi },
    { "window_heat_2", "tu154/custom/switchers/ovhd/window_heat_2", globalPropertyi },
    { "window_heat_3", "tu154/custom/switchers/ovhd/window_heat_3", globalPropertyi },
    { "pitot_heat_1", "tu154/custom/switchers/ovhd/pitot_heat_1", globalPropertyi },
    { "pitot_heat_2", "tu154/custom/switchers/ovhd/pitot_heat_2", globalPropertyi },
    { "pitot_heat_3", "tu154/custom/switchers/ovhd/pitot_heat_3", globalPropertyi },
})

For indexed/array DataRefs, do not blindly preserve SASL 2 typed-array access patterns.

Example:

```lua
	defineProperty("gear0", globalProperty("sim/flightmodel2/gear/tire_vertical_deflection_mtr[0]"))
```

Use the SASL 3 manual and the actual DataRef type to determine the correct accessor.

Do not globally replace all `globalPropertyf` or `globalPropertyi`.

### Component lifecycle

If a component defines its own `update()` and owns child `components`, ensure child updates are still dispatched when required:

```lua
function update()
    -- local logic
    updateAll(components)
end
```

If a component defines its own `draw()` and owns child `components`, ensure child drawing is dispatched when required:

```lua
function draw()
    drawAll(components)
end
```

Do not add `drawAll(components)` or `updateAll(components)` to a file that does not actually own a top-level `components` table.

Context windows manage their own child components.

## Mouse handling

Do not perform blanket conversions between:

- `onMouseDown`
- `onMouseUp`
- `onMouseHold`
- legacy SASL 2 click handlers

Determine the intended behavior of each control.

### Momentary pushbutton

Typical pattern:

```lua
onMouseDown = function()
    set(button, 1)
    return true
end,

onMouseUp = function()
    set(button, 0)
    return true
end,
```

### Toggle / one-step action

Use a single event, normally `onMouseDown`, unless the original behavior explicitly requires repetition:

```lua
onMouseDown = function()
    set(toggle, 1 - get(toggle))
    return true
end,
```

### Repeating action

Use `onMouseHold` only when repeated execution while the button is held is intentionally required.

Never convert every `onMouseDown` to `onMouseHold`.

A toggle implemented with `onMouseHold` can flip many times during one click and is usually wrong.

## Interactive components

Use SASL 3 compatible interactive components.

Do not revert working SASL 3 `interactive { ... }` components to legacy components merely to resemble the SASL 2 source.

Preserve:

- hitbox coordinates;
- visibility rules;
- switch direction;
- min/max limits;
- button state behavior.

## Context windows

Use SASL 3 `contextWindow` semantics.

Typical configuration:

```lua
my_window = contextWindow {
    position = {50, 50, 500, 500},
    visible = false,

    noDecore = true,
    noBackground = true,

    proportional = true,
    saveState = true,

    name = "my_window",

    components = {
        my_component {
            position = {0, 0, 500, 500},
        },
    },
}
```

Use ContextWindow methods for runtime state:

```lua
my_window:setIsVisible(true)
my_window:setPosition(x, y, w, h)
```

Do not reintroduce deprecated SASL 2 window parameters such as:

- `resizeProportional`
- `savePosition`

Do not modify already working context-window host code unless the task specifically concerns it.

## Textures

Preserve texture filenames, crop rectangles, panel coordinates and sprite geometry unless there is a confirmed SASL 3 incompatibility.

Be aware that texture crop coordinate conventions may differ between old code and SASL 3 APIs.

Do not alter texture coordinates merely because they look unusual.

If a texture currently renders correctly, treat its coordinates as validated.

## Helper components

Use the helper component intended for the specific job.

Example:

`rectangle_ctr_fuel` is the intended helper for dynamic fuel/cargo fill rectangles in the load panel.

Do not replace it with `rectangle_ctr` unless explicitly requested or proven necessary.

Before modifying a helper component, first check whether another dedicated helper already exists.

## Aircraft logic

Do not change aircraft behavior while performing API migration unless the user explicitly asks for a systems/aerodynamics change.

This includes:

- ABSU logic;
- NVU logic;
- engine logic;
- electrical logic;
- fuel logic;
- payload calculations;
- CG calculations;
- animation behavior;
- autopilot behavior;
- failures;
- SmartCopilot synchronization.

A SASL migration fix should not silently become a systems rewrite.

## Code style

Lua comments written or changed by the agent should be in English.

Preserve the general style of the existing file unless cleanup materially improves readability.

Prefer clear, explicit code over clever rewrites when reviewing aircraft-system logic.

Avoid unrelated formatting churn.

Do not rename DataRefs, properties, files, textures or component names without a concrete reason.

## Validation

After modifying a Lua file:

- search for accidentally introduced legacy SASL calls;
- verify all referenced component names still exist;
- verify all `components = { ... }` blocks are balanced;
- verify mouse handlers return `true` where expected;
- verify `set()` is only used on writable properties;
- verify no automated replacement changed system semantics.



## Review output

When presenting a corrected file, briefly state:

- what was broken;
- what was changed;
- what was deliberately left unchanged;
- whether syntax validation passed;
- any dependency that still needs inspection.

Do not produce a long generic SASL explanation unless requested.

## Safety rules for automated conversions

Never run broad replacements without reviewing their semantic effect.

Especially dangerous transformations include:

```text
onMouseDown -> onMouseHold
globalPropertyf -> globalProperty
subpanel -> contextWindow
clickable -> interactive
```

Some of these transformations may be valid in specific places, but none are universally safe.
Every conversion must be validated against the component's actual behavior.

## Source priority

When there is a conflict, use this order:

1. current user instruction;
2. known working behavior in the current project;
3. SASL 3 manual/API documentation;
4. original SASL 2 implementation;
5. inference.

Do not overwrite known-working project behavior based only on a generic migration pattern.
