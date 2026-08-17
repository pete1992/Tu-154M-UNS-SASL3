-- absu_commands.lua

-- absu_commands.lua
-- Refactored: DataRefs moved to bulk defineProps format.
-- All comments in English per project rules.

-----------------------------------------------------------------------
-- Bulk DataRef definitions
-----------------------------------------------------------------------
local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
{"absu_zk", "tu154/custom/buttons/console/absu_zk", globalPropertyi},
{"absu_reset", "tu154/custom/buttons/console/absu_reset", globalPropertyi},
{"absu_nvu", "tu154/custom/buttons/console/absu_nvu", globalPropertyi},
{"absu_app", "tu154/custom/buttons/console/absu_app", globalPropertyi},
{"absu_gs", "tu154/custom/buttons/console/absu_gs", globalPropertyi},
{"absu_stab_m", "tu154/custom/buttons/console/absu_stab_m",                globalPropertyi},
{"absu_stab_v", "tu154/custom/buttons/console/absu_stab_v",                globalPropertyi},
{"absu_stab_h", "tu154/custom/buttons/console/absu_stab_h",                globalPropertyi},
{"absu_stab", "tu154/custom/buttons/console/absu_stab",                  globalPropertyi},
{"absu_stab_speed", "tu154/custom/buttons/console/absu_stab_speed",            globalPropertyi},
{"absu_speed_change", "tu154/custom/switchers/console/absu_speed_change", globalPropertyi},
{"absu_turn_handle", "tu154/custom/switchers/console/absu_turn_handle",         globalPropertyi},
{"absu_pitch_wheel_dir", "tu154/custom/switchers/console/absu_pitch_wheel_dir",     globalPropertyi},
{"pkp_course_L", "tu154/custom/gauges/compas/pkp_helper_course_L",          globalPropertyf},
{"pkp_course_R", "tu154/custom/gauges/compas/pkp_helper_course_R",          globalPropertyf},
})

-----------------------------------------------------------------------
-- Helpers
-----------------------------------------------------------------------
local function clamp(x, lo, hi)
    if x < lo then return lo end
    if x > hi then return hi end
    return x
end

local function wrap360(v)
    -- Keep heading in [0, 360)
    v = v % 360
    if v < 0 then v = v + 360 end
    return v
end

-----------------------------------------------------------------------
-- Commands
-----------------------------------------------------------------------
local AP_stab          = findCommand("sim/autopilot/fdir_on")
local AP_AT            = findCommand("sim/autopilot/autothrottle_toggle")
local AP_ZK            = findCommand("sim/autopilot/heading")
local AP_wing_level    = findCommand("sim/autopilot/wing_leveler")
local AP_turn_left     = findCommand("sim/autopilot/override_left")
local AP_turn_right    = findCommand("sim/autopilot/override_right")
local AP_NVU           = findCommand("sim/autopilot/NAV")
local AP_stab_V        = findCommand("sim/autopilot/airspeed_sync")
local AP_stab_M        = findCommand("sim/autopilot/level_change")
local AP_stab_H        = findCommand("sim/autopilot/altitude_hold")
local AP_GS            = findCommand("sim/autopilot/glide_slope")
local AP_APP           = findCommand("sim/autopilot/approach")
local AP_down          = findCommand("sim/autopilot/nose_down")
local AP_up            = findCommand("sim/autopilot/nose_up")
local AP_spd_up        = findCommand("sim/autopilot/airspeed_up")
local AP_spd_down      = findCommand("sim/autopilot/airspeed_down")
local PNP_head_left_L  = findCommand("sim/autopilot/heading_down")
local PNP_head_right_L = findCommand("sim/autopilot/heading_up")
local PNP_head_left_R  = findCommand("sim/autopilot/heading_copilot_down")
local PNP_head_right_R = findCommand("sim/autopilot/heading_copilot_up")

-----------------------------------------------------------------------
-- Handlers
-----------------------------------------------------------------------
-- Momentary: press (phase==1) sets 1, release sets 0
local function AP_stab_hnd(phase)
    if phase == 1 then set(absu_stab, 1) else set(absu_stab, 0) end
    return 0
end
registerCommandHandler(AP_stab, 0, AP_stab_hnd)

local function AP_AT_hnd(phase)
    if phase == 1 then set(absu_stab_speed, 1) else set(absu_stab_speed, 0) end
    return 0
end
registerCommandHandler(AP_AT, 0, AP_AT_hnd)

local function AP_ZK_hnd(phase)
    if phase == 1 then set(absu_zk, 1) else set(absu_zk, 0) end
    return 0
end
registerCommandHandler(AP_ZK, 0, AP_ZK_hnd)

-- Wing leveler: zero the turn handle on press
local function AP_wing_level_hnd(phase)
    if phase == 1 then set(absu_turn_handle, 0) end
    return 0
end
registerCommandHandler(AP_wing_level, 0, AP_wing_level_hnd)

-- Turn handle step left/right: one step on initial press (phase==0)
local function AP_turn_left_hnd(phase)
    if phase == 0 then
        local a = get(absu_turn_handle) - 5
        set(absu_turn_handle, clamp(a, -50, 50))
    end
    return 0
end
registerCommandHandler(AP_turn_left, 0, AP_turn_left_hnd)

local function AP_turn_right_hnd(phase)
    if phase == 0 then
        local a = get(absu_turn_handle) + 5
        set(absu_turn_handle, clamp(a, -50, 50))
    end
    return 0
end
registerCommandHandler(AP_turn_right, 0, AP_turn_right_hnd)

local function AP_NVU_hnd(phase)
    if phase == 1 then set(absu_nvu, 1) else set(absu_nvu, 0) end
    return 0
end
registerCommandHandler(AP_NVU, 0, AP_NVU_hnd)

local function AP_stab_V_hnd(phase)
    if phase == 1 then set(absu_stab_v, 1) else set(absu_stab_v, 0) end
    return 0
end
registerCommandHandler(AP_stab_V, 0, AP_stab_V_hnd)

local function AP_stab_M_hnd(phase)
    if phase == 1 then set(absu_stab_m, 1) else set(absu_stab_m, 0) end
    return 0
end
registerCommandHandler(AP_stab_M, 0, AP_stab_M_hnd)

-- NOTE: this handler was duplicated in the original file; keep only one.
local function AP_stab_H_hnd(phase)
    if phase == 1 then set(absu_stab_h, 1) else set(absu_stab_h, 0) end
    return 0
end
registerCommandHandler(AP_stab_H, 0, AP_stab_H_hnd)

local function AP_GS_hnd(phase)
    if phase == 1 then set(absu_gs, 1) else set(absu_gs, 0) end
    return 0
end
registerCommandHandler(AP_GS, 0, AP_GS_hnd)

local function AP_APP_hnd(phase)
    if phase == 1 then set(absu_app, 1) else set(absu_app, 0) end
    return 0
end
registerCommandHandler(AP_APP, 0, AP_APP_hnd)

-- Pitch wheel direction: -1, 0, +1 based on press
local function AP_down_hnd(phase)
    if phase == 1 then set(absu_pitch_wheel_dir, -1) else set(absu_pitch_wheel_dir, 0) end
    return 0
end
registerCommandHandler(AP_down, 0, AP_down_hnd)

local function AP_up_hnd(phase)
    if phase == 1 then set(absu_pitch_wheel_dir, 1) else set(absu_pitch_wheel_dir, 0) end
    return 0
end
registerCommandHandler(AP_up, 0, AP_up_hnd)

-- Speed change: -1, 0, +1 based on press
local function AP_spd_up_hnd(phase)
    if phase == 1 then set(absu_speed_change, 1) else set(absu_speed_change, 0) end
    return 0
end
registerCommandHandler(AP_spd_up, 0, AP_spd_up_hnd)

local function AP_spd_down_hnd(phase)
    if phase == 1 then set(absu_speed_change, -1) else set(absu_speed_change, 0) end
    return 0
end
registerCommandHandler(AP_spd_down, 0, AP_spd_down_hnd)

-- PNP left pilot heading - step and wrap
local function PNP_head_left_L_hnd(phase)
    if phase == 1 then
        local v = get(pkp_course_L) - 1
        set(pkp_course_L, wrap360(v))
    end
    return 0
end
registerCommandHandler(PNP_head_left_L, 0, PNP_head_left_L_hnd)

-- PNP right pilot heading - step and wrap
local function PNP_head_right_L_hnd(phase)
    if phase == 1 then
        local v = get(pkp_course_L) + 1
        set(pkp_course_L, wrap360(v))
    end
    return 0
end
registerCommandHandler(PNP_head_right_L, 0, PNP_head_right_L_hnd)

-- PNP left copilot heading - step and wrap
local function PNP_head_left_R_hnd(phase)
    if phase == 1 then
        local v = get(pkp_course_R) - 1
        set(pkp_course_R, wrap360(v))
    end
    return 0
end
registerCommandHandler(PNP_head_left_R, 0, PNP_head_left_R_hnd)

-- PNP right copilot heading - step and wrap
local function PNP_head_right_R_hnd(phase)
    if phase == 1 then
        local v = get(pkp_course_R) + 1
        set(pkp_course_R, wrap360(v))
    end
    return 0
end
registerCommandHandler(PNP_head_right_R, 0, PNP_head_right_R_hnd)
