# AGENTS.md

## Project

This repository contains the Tu-154 project for X-Plane 11.

The current development task is the migration of an existing SASL 2 project to SASL 3 while preserving the original aircraft behavior as closely as possible.

The goal is not to redesign the aircraft or modernize working logic. The goal is a clean, stable SASL 3 port.

## Role

Act as an experienced X-Plane 11 Lua/SASL developer and code reviewer.

When changing code:

- understand the existing behavior first;
- distinguish SASL 2 compatibility code from actual aircraft logic;
- use the SASL 3 manual as the primary API reference;
- preserve DataRef paths, aircraft systems logic, coordinates, textures and timing unless a change is required for SASL 3;
- prefer small, reviewable changes over broad automated rewrites.

Do not guess SASL API behavior when it can be verified.

## Current migration strategy

Work file by file.

Do not perform repository-wide conversions unless explicitly requested.

For each file:

1. inspect the complete file;
2. identify actual SASL 2 -> SASL 3 incompatibilities;
3. separate API migration issues from aircraft/system logic;
4. make only the required changes;
5. preserve the original behavior;
6. check Lua syntax after editing;
7. report exactly what was changed and why.

A working parent or host file must not be modified merely because a child component is broken.

## Important current state

The 2D panel main/menu host is already working.

Do not modify `panels_2d.lua` unless explicitly requested.

If an individual popup opens correctly but its contents are broken, investigate the corresponding child panel first, for example:

- `absu_panel_2d.lua`
- `load_panel.lua`
- `overhead_2d.lua`
- `nvu_panel_2d.lua`
- `checklist_panel_2d.lua`
- `ground_panel.lua`
- `UPhone.lua`
- `camera.lua`
- `palette_2d.lua`
- `failures_2d.lua`

Do not fix the main panel/menu system as a side effect of debugging one of these files.

## SASL 3 migration rules

### Properties and DataRefs

Preserve existing DataRef paths unless there is a confirmed reason to change them.

Typical SASL 3 property access:

```lua
defineProperty("name", globalProperty("path"))
defineProperty("name", globalPropertyf("path"))
defineProperty("name", globalPropertyi("path"))
```

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

- run a Lua syntax check when possible;
- search for accidentally introduced legacy SASL calls;
- verify all referenced component names still exist;
- verify all `components = { ... }` blocks are balanced;
- verify mouse handlers return `true` where expected;
- verify `set()` is only used on writable properties;
- verify no automated replacement changed system semantics.

If syntax validation is not possible, state that clearly.

Do not claim runtime correctness solely because a file parses.

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

## Primary objective

A successful change is the smallest change that makes the current file work correctly under SASL 3 without changing the Tu-154's intended behavior.
