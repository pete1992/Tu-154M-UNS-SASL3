--[[
Changelog
- Preserved the existing refactored Dataref layout and all 115 defineProps() entries.
- Replaced the _G-based property assignment with SASL defineProperty() registration.
- Corrected gpu_work_bus, inv115_fail, and buses_connected to globalPropertyi to match their integer Datarefs.
- Preserved bus27_source_left and bus27_source_right as globalPropertyi.
- Added XP11/XP12-compatible one-shot sound playback.
- Fixed the lamp-test voltage calculation and clamped panel-lamp brightness to 0..1.
- Fixed double voltage scaling of the emergency 115 V inverter lamp during lamp test.
- Replaced sum-based switch/cap sound detection with direct per-control state comparison.
- Consolidated gauge needle dynamics into one helper.
- Made gauge needle position integration frame-rate independent while matching the previous behavior at a 60 FPS reference rate.
- Reduced repeated Dataref reads in lamp and gauge logic.
- Preserved selector mappings, switching delays, gauge scales, cold-and-dark reset, avionics power logic, generator warning voltage threshold, and PTS/VU lamp meanings.
- Kept GEN_OVERLOAD_AMP and NEEDLE_ACCEL_LIMIT as reserved legacy tuning constants.
]]

-- Electric panel logic for Tu-154M.
-- SASL 2.6.1 / X-Plane 11 with X-Plane 12 compatibility where required.

defineProperty("xp_version", globalPropertyi("sim/version/xplane_internal_version"))
local XP11 = get(xp_version) > 120000

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Panel controls
    {"gpu_on", "tu154/custom/switchers/eng/gpu_on", globalPropertyi}, -- GPU switch
    {"apu_gen_on", "tu154/custom/switchers/eng/apu_gen_on", globalPropertyi}, -- APU generator switch
    {"bus115_volt_sel", "tu154/custom/switchers/eng/bus115_volt_sel", globalPropertyi}, -- 115V voltmeter source selector
    {"bus115_volt_phase_sel", "tu154/custom/switchers/eng/bus115_volt_phase_sel", globalPropertyi}, -- 115V voltmeter phase selector
    {"bus115_amp_sel", "tu154/custom/switchers/eng/bus115_amp_sel", globalPropertyi}, -- 115V ammeter source selector
    {"bus115_amp_phase_sel", "tu154/custom/switchers/eng/bus115_amp_phase_sel", globalPropertyi}, -- 115V ammeter phase selector
    {"gen_1_on", "tu154/custom/switchers/eng/gen_1_on", globalPropertyi}, -- Generator 1 switch
    {"gen_2_on", "tu154/custom/switchers/eng/gen_2_on", globalPropertyi}, -- Generator 2 switch
    {"gen_3_on", "tu154/custom/switchers/eng/gen_3_on", globalPropertyi}, -- Generator 3 switch
    {"emerg_inv115", "tu154/custom/switchers/eng/emerg_inv115", globalPropertyi}, -- Emergency inverter 115V
    {"emerg_inv115_cap", "tu154/custom/switchers/eng/emerg_inv115_cap", globalPropertyi}, -- Emergency inverter 115V cap
    {"bus36_volt_sel", "tu154/custom/switchers/eng/bus36_volt_sel", globalPropertyi}, -- 36V voltmeter source selector
    {"pts250_sel", "tu154/custom/switchers/eng/pts250_sel", globalPropertyi}, -- PTS250 selector
    {"bus36_tr_left_to_right", "tu154/custom/switchers/eng/bus36_tr_left_to_right", globalPropertyi}, -- 36V TR left to right
    {"bus36_tr_right_to_left", "tu154/custom/switchers/eng/bus36_tr_right_to_left", globalPropertyi}, -- 36V TR right to left
    {"pts250_on", "tu154/custom/switchers/eng/pts250_on", globalPropertyi}, -- PTS250 switch
    {"pts250_mode", "tu154/custom/switchers/eng/pts250_mode", globalPropertyi}, -- PTS250 mode
    {"pts250_on_cap", "tu154/custom/switchers/eng/pts250_on_cap", globalPropertyi}, -- PTS250 switch cap
    {"pts250_mode_cap", "tu154/custom/switchers/eng/pts250_mode_cap", globalPropertyi}, -- PTS250 mode cap
    {"bus27_volt_sel", "tu154/custom/switchers/eng/bus27_volt_sel", globalPropertyi}, -- 27V voltmeter selector
    {"bus27_amp1_sel", "tu154/custom/switchers/eng/bus27_amp1_sel", globalPropertyi}, -- 27V ammeter 1 selector
    {"bus27_amp2_sel", "tu154/custom/switchers/eng/bus27_amp2_sel", globalPropertyi}, -- 27V ammeter 2 selector
    {"bus27_connect", "tu154/custom/switchers/eng/bus27_connect", globalPropertyi}, -- 27V bus connection
    {"bus27_connect_cap", "tu154/custom/switchers/eng/bus27_connect_cap", globalPropertyi}, -- 27V bus connection cap
    {"bus27_vu1", "tu154/custom/switchers/eng/bus27_vu1", globalPropertyi}, -- 27V VU1 switch
    {"bus27_vu2", "tu154/custom/switchers/eng/bus27_vu2", globalPropertyi}, -- 27V VU2 switch
    {"bat1_on", "tu154/custom/switchers/eng/bat1_on", globalPropertyi}, -- Battery 1 switch
    {"bat2_on", "tu154/custom/switchers/eng/bat2_on", globalPropertyi}, -- Battery 2 switch
    {"bat3_on", "tu154/custom/switchers/eng/bat3_on", globalPropertyi}, -- Battery 3 switch
    {"bat4_on", "tu154/custom/switchers/eng/bat4_on", globalPropertyi}, -- Battery 4 switch

    -- Gauges
    {"bus115_freq", "tu154/custom/gauges/eng/bus115_freq", globalPropertyf}, -- 115V frequency gauge
    {"bus115_volt", "tu154/custom/gauges/eng/bus115_volt", globalPropertyf}, -- 115V voltmeter
    {"bus115_amp", "tu154/custom/gauges/eng/bus115_amp", globalPropertyf}, -- 115V ammeter
    {"bus36_volt", "tu154/custom/gauges/eng/bus36_volt", globalPropertyf}, -- 36V voltmeter
    {"bus27_volt", "tu154/custom/gauges/eng/bus27_volt", globalPropertyf}, -- 27V voltmeter
    {"bus27_amp1", "tu154/custom/gauges/eng/bus27_amp1", globalPropertyf}, -- 27V ammeter 1
    {"bus27_amp2", "tu154/custom/gauges/eng/bus27_amp2", globalPropertyf}, -- 27V ammeter 2

    -- Timing and sources
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf}, -- Simulation frame time
    {"sim_run_time", "sim/time/total_running_time_sec", globalPropertyf}, -- Total simulation run time

    -- Battery and generator sources
    {"bat_volt_1", "tu154/custom/elec/bat_volt_1", globalPropertyf}, -- Battery 1 voltage
    {"bat_volt_2", "tu154/custom/elec/bat_volt_2", globalPropertyf}, -- Battery 2 voltage
    {"bat_volt_3", "tu154/custom/elec/bat_volt_3", globalPropertyf}, -- Battery 3 voltage
    {"bat_volt_4", "tu154/custom/elec/bat_volt_4", globalPropertyf}, -- Battery 4 voltage
    {"bat_amp_1", "tu154/custom/elec/bat_amp_1", globalPropertyf}, -- Battery 1 current
    {"bat_amp_2", "tu154/custom/elec/bat_amp_2", globalPropertyf}, -- Battery 2 current
    {"bat_amp_3", "tu154/custom/elec/bat_amp_3", globalPropertyf}, -- Battery 3 current
    {"bat_amp_4", "tu154/custom/elec/bat_amp_4", globalPropertyf}, -- Battery 4 current
    {"bat_amp_cc_1", "tu154/custom/elec/bat_cc_1", globalPropertyf}, -- Battery 1 charge current
    {"bat_amp_cc_2", "tu154/custom/elec/bat_cc_2", globalPropertyf}, -- Battery 2 charge current
    {"bat_amp_cc_3", "tu154/custom/elec/bat_cc_3", globalPropertyf}, -- Battery 3 charge current
    {"bat_amp_cc_4", "tu154/custom/elec/bat_cc_4", globalPropertyf}, -- Battery 4 charge current
    {"vu1_amp", "tu154/custom/elec/vu1_amp", globalPropertyf}, -- VU1 current
    {"vu2_amp", "tu154/custom/elec/vu2_amp", globalPropertyf}, -- VU2 current
    {"vu_res_amp", "tu154/custom/elec/vu_res_amp", globalPropertyf}, -- VU reserve current
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf}, -- 27V bus left voltage
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf}, -- 27V bus right voltage

    -- Bus 36V
    {"bus36_volt_left", "tu154/custom/elec/bus36_volt_left", globalPropertyf}, -- 36V bus left voltage
    {"bus36_volt_right", "tu154/custom/elec/bus36_volt_right", globalPropertyf}, -- 36V bus right voltage
    {"bus36_volt_pts250_1", "tu154/custom/elec/bus36_volt_pts250_1", globalPropertyf}, -- 36V PTS250 #1 voltage
    {"bus36_volt_pts250_2", "tu154/custom/elec/bus36_volt_pts250_2", globalPropertyf}, -- 36V PTS250 #2 voltage

    -- Bus 115/200V and generator currents
    {"gen1_volt", "tu154/custom/elec/gen1_volt", globalPropertyf}, -- Generator 1 voltage
    {"gen2_volt", "tu154/custom/elec/gen2_volt", globalPropertyf}, -- Generator 2 voltage
    {"gen3_volt", "tu154/custom/elec/gen3_volt", globalPropertyf}, -- Generator 3 voltage
    {"gen4_volt", "tu154/custom/elec/gen4_volt", globalPropertyf}, -- Generator 4 voltage
    {"gpu_volt", "tu154/custom/elec/gpu_volt", globalPropertyf}, -- GPU voltage
    {"bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf}, -- 115V bus phase 1
    {"bus115_2_volt", "tu154/custom/elec/bus115_2_volt", globalPropertyf}, -- 115V bus phase 2
    {"bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf}, -- 115V bus phase 3
    {"bus115_em_1_volt", "tu154/custom/elec/bus115_em_1_volt", globalPropertyf}, -- Emergency 115V bus 1
    {"bus115_em_2_volt", "tu154/custom/elec/bus115_em_2_volt", globalPropertyf}, -- Emergency 115V bus 2
    {"gen1_amp", "tu154/custom/elec/gen1_amp", globalPropertyf}, -- Generator 1 current
    {"gen2_amp", "tu154/custom/elec/gen2_amp", globalPropertyf}, -- Generator 2 current
    {"gen3_amp", "tu154/custom/elec/gen3_amp", globalPropertyf}, -- Generator 3 current
    {"gen4_amp", "tu154/custom/elec/gen4_amp", globalPropertyf}, -- Generator 4 current
    {"gpu_amp", "tu154/custom/elec/gpu_amp", globalPropertyf}, -- GPU current

    -- Lamps
    {"lamp_apu_gen_on", "tu154/custom/lights/small/apu_gen_on", globalPropertyf}, -- GPU/RAP connected lamp
    {"bus_npk_1", "tu154/custom/lights/small/bus_npk_1", globalPropertyf}, -- NPK bus 1 lamp
    {"bus_npk_2", "tu154/custom/lights/small/bus_npk_2", globalPropertyf}, -- NPK bus 2 lamp
    {"emerg_inv_115", "tu154/custom/lights/small/emerg_inv_115", globalPropertyf}, -- Emergency inverter 115V lamp
    {"gen_fail_1", "tu154/custom/lights/small/gen_fail_1", globalPropertyf}, -- Generator 1 fail lamp
    {"gen_fail_2", "tu154/custom/lights/small/gen_fail_2", globalPropertyf}, -- Generator 2 fail lamp
    {"gen_fail_3", "tu154/custom/lights/small/gen_fail_3", globalPropertyf}, -- Generator 3 fail lamp
    {"bus_connected", "tu154/custom/lights/small/bus_connected", globalPropertyf}, -- Buses connected lamp
    {"left_bus_use_bat", "tu154/custom/lights/small/left_bus_use_bat", globalPropertyf}, -- Left bus on battery lamp
    {"right_bus_use_bat", "tu154/custom/lights/small/right_bus_use_bat", globalPropertyf}, -- Right bus on battery lamp
    {"turn_off_bat_1", "tu154/custom/lights/small/turn_off_bat_1", globalPropertyf}, -- Turn off battery 1 lamp
    {"turn_off_bat_2", "tu154/custom/lights/small/turn_off_bat_2", globalPropertyf}, -- Turn off battery 2 lamp
    {"turn_off_bat_3", "tu154/custom/lights/small/turn_off_bat_3", globalPropertyf}, -- Turn off battery 3 lamp
    {"turn_off_bat_4", "tu154/custom/lights/small/turn_off_bat_4", globalPropertyf}, -- Turn off battery 4 lamp
    {"vu_on_1", "tu154/custom/lights/small/vu_on_1", globalPropertyf}, -- VU1 on lamp
    {"vu_on_2", "tu154/custom/lights/small/vu_on_2", globalPropertyf}, -- VU2 on lamp
    {"left_bus_on_tr2", "tu154/custom/lights/small/left_bus_on_tr2", globalPropertyf}, -- Left bus on TR2 lamp
    {"right_bus_on_tr1", "tu154/custom/lights/small/right_bus_on_tr1", globalPropertyf}, -- Right bus on TR1 lamp
    {"pts250_n1", "tu154/custom/lights/small/pts250_n1", globalPropertyf}, -- PTS250 N1 lamp
    {"pts250_n2", "tu154/custom/lights/small/pts250_n2", globalPropertyf}, -- PTS250 N2 lamp

    -- Lamp sources and states
    {"test_lamps", "tu154/custom/buttons/lamp_test_apu", globalPropertyi}, -- Lamp test button
    {"gpu_work_bus", "tu154/custom/elec/gpu_work", globalPropertyi}, -- GPU working status
    {"inv115_fail", "tu154/custom/failures/inv115_fail", globalPropertyi}, -- Inverter 115V fail status
    {"buses_connected", "tu154/custom/elec/bus_connected", globalPropertyi}, -- Buses connected status
    {"bus27_source_left", "tu154/custom/elec/bus27_source_left", globalPropertyi}, -- 27V left bus source
    {"bus27_source_right", "tu154/custom/elec/bus27_source_right", globalPropertyi}, -- 27V right bus source
    {"vu_res_to_L", "tu154/custom/elec/vu_res_to_L", globalPropertyi}, -- Reserve VU to left bus
    {"vu_res_to_R", "tu154/custom/elec/vu_res_to_R", globalPropertyi}, -- Reserve VU to right bus
    {"bus36_src_L", "tu154/custom/elec/bus36_src_L", globalPropertyi}, -- 36V source left
    {"bus36_src_R", "tu154/custom/elec/bus36_src_R", globalPropertyi}, -- 36V source right
    {"bus36_pts1_work", "tu154/custom/elec/bus36_pts1_work", globalPropertyi}, -- PTS250 1 work lamp
    {"bus36_pts2_work", "tu154/custom/elec/bus36_pts2_work", globalPropertyi}, -- PTS250 2 work lamp
    {"bat_therm_1", "tu154/custom/elec/bat_therm_1", globalPropertyf}, -- Battery 1 temperature
    {"bat_therm_2", "tu154/custom/elec/bat_therm_2", globalPropertyf}, -- Battery 2 temperature
    {"bat_therm_3", "tu154/custom/elec/bat_therm_3", globalPropertyf}, -- Battery 3 temperature
    {"bat_therm_4", "tu154/custom/elec/bat_therm_4", globalPropertyf}, -- Battery 4 temperature

    -- Engines
    {"eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", XP11 and globalPropertyf or globalProperty }, -- Engine 1 N1
    {"eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]",XP11 and globalPropertyf or globalProperty }, -- Engine 2 N1
    {"eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", XP11 and globalPropertyf or globalProperty }, -- Engine 3 N1
    {"sim_avionics", "sim/cockpit2/switches/avionics_power_on", globalPropertyi}, -- Sim avionics switch
})

local function clampValue(value, min_value, max_value)
    if value < min_value then
        return min_value
    elseif value > max_value then
        return max_value
    end
    return value
end

local function interpolate(tbl, x)
    if x <= tbl[1][1] then
        return tbl[1][2]
    end

    for i = 1, #tbl - 1 do
        local x0 = tbl[i][1]
        local y0 = tbl[i][2]
        local x1 = tbl[i + 1][1]
        local y1 = tbl[i + 1][2]

        if x <= x1 then
            local t = (x - x0) / (x1 - x0)
            return y0 + (y1 - y0) * t
        end
    end

    return tbl[#tbl][2]
end

local function sign(x)
    if x > 0 then
        return 1
    elseif x < 0 then
        return -1
    end
    return 0
end

local function playPanelSample(sample)
    if XP11 then
        sasl.al.playSample(sample, false)
    else
        sasl.al.playSample(sample, false)
    end
end

-- Generator warning thresholds.
local GEN_OVERLOAD_AMP = 200 -- Reserved for generator-overload indication logic.
local GEN_MIN_VOLT = 111

-- Gauge dynamics.
-- The old code added velocity directly to needle position once per frame.
-- Multiplying position integration by dt * 60 preserves the old response at
-- 60 FPS while removing the strong frame-rate dependency at other frame rates.
local NEEDLE_ACCEL = 50
local NEEDLE_FRICTION = 200
local NEEDLE_SPEED_LIMIT = 20
local NEEDLE_ACCEL_LIMIT = 5 -- Reserved legacy tuning constant.
local NEEDLE_REFERENCE_FPS = 60

local function updateNeedle(state, target, dt)
    if dt <= 0 then
        state.velocity = 0
        return state.actual
    end

    local acceleration = (target - state.actual) * NEEDLE_ACCEL
    state.velocity = state.velocity + acceleration * dt

    state.velocity = state.velocity
        - sign(state.velocity)
        * math.min(
            NEEDLE_FRICTION * dt,
            math.abs(state.velocity) * 0.5
        )

    state.velocity = clampValue(
        state.velocity,
        -NEEDLE_SPEED_LIMIT,
        NEEDLE_SPEED_LIMIT
    )

    state.actual = state.actual
        + state.velocity * dt * NEEDLE_REFERENCE_FPS

    return state.actual
end

-- Sounds.
local SAMPLES = {
    rotary = sasl.al.loadSample("Custom Sounds/plastic_switch.wav"),
    switcher = sasl.al.loadSample("Custom Sounds/metal_switch.wav"),
    cap = sasl.al.loadSample("Custom Sounds/cap.wav"),
}

-- Gauge conversion tables.
local VOLT115_TABLE = {
    { -5000, -120 },
    { 0, -120 },
    { 50, -95 },
    { 100, 0 },
    { 120, 20 },
    { 150, 120 },
    { 1000, 120 },
}

local AMP115_TABLE = {
    { -5000, -120 },
    { 0, -120 },
    { 40, -100 },
    { 50, -90 },
    { 100, -20 },
    { 110, 0 },
    { 145, 97 },
    { 150, 120 },
    { 1000, 120 },
}

local VOLT36_TABLE = {
    { -5000, -120 },
    { 0, -120 },
    { 15, -90 },
    { 30, -10 },
    { 40, 60 },
    { 45, 120 },
    { 1000, 120 },
}

local VOLT27_TABLE = {
    { -5000, -120 },
    { 0, -120 },
    { 30, 120 },
    { 1000, 120 },
}

local AMP27_TABLE = {
    { -5000, -120 },
    { -40, -120 },
    { 0, -99 },
    { 400, 120 },
    { 1000, 120 },
}

local VOLT115_SOURCES = {
    [0] = gen1_volt,
    [1] = gen2_volt,
    [2] = gen3_volt,
    [3] = gen4_volt,
    [4] = gpu_volt,
    [5] = bus115_em_1_volt,
    [6] = bus115_em_2_volt,
    [7] = bus115_1_volt,
    [8] = bus115_2_volt,
    [9] = bus115_3_volt,
}

local AMP115_SOURCES = {
    [0] = gpu_amp,
    [1] = gen1_amp,
    [2] = gen2_amp,
    [3] = gen3_amp,
    [4] = gen4_amp,
}

local GAUGE = {
    volt115 = {
        actual = -120,
        velocity = 0,
        timer = 0,
        selector_last = get(bus115_volt_sel),
        phase_last = get(bus115_volt_phase_sel),
    },
    freq115 = {
        actual = -120,
        velocity = 0,
        timer = 0,
    },
    amp115 = {
        actual = -120,
        velocity = 0,
        timer = 0,
        selector_last = get(bus115_amp_sel),
        phase_last = get(bus115_amp_phase_sel),
    },
    volt36 = {
        actual = -120,
        velocity = 0,
        timer = 0,
        selector_last = get(bus36_volt_sel),
    },
    volt27 = {
        actual = -120,
        velocity = 0,
        timer = 0,
        selector_last = get(bus27_volt_sel),
    },
    amp27_1 = {
        actual = -99,
        velocity = 0,
        timer = 0,
        selector_last = get(bus27_amp1_sel),
    },
    amp27_2 = {
        actual = -99,
        velocity = 0,
        timer = 0,
        selector_last = get(bus27_amp2_sel),
    },
}

local function selectedPropertyValue(sources, selector)
    local property = sources[selector]
    if property then
        return get(property)
    end
    return 0
end

local function updateVoltmeter115(dt)
    local state = GAUGE.volt115
    local freq_state = GAUGE.freq115

    local selector = get(bus115_volt_sel)
    local phase_selector = get(bus115_volt_phase_sel)

    state.timer = state.timer + dt

    if selector ~= state.selector_last
        or phase_selector ~= state.phase_last then
        state.timer = 0
        freq_state.timer = 0
        playPanelSample(SAMPLES.rotary)
    end

    state.selector_last = selector
    state.phase_last = phase_selector

    local target = -120

    if state.timer >= 0.05 then
        target = interpolate(
            VOLT115_TABLE,
            selectedPropertyValue(VOLT115_SOURCES, selector)
        )
    end

    set(bus115_volt, updateNeedle(state, target, dt))

    local freq_target = -120
    if target > 0 and freq_state.timer > 0.2 then
        freq_target = 0
    end

    freq_state.timer = freq_state.timer + dt
    set(bus115_freq, updateNeedle(freq_state, freq_target, dt))
end

local function updateAmmeter115(dt)
    local state = GAUGE.amp115
    local selector = get(bus115_amp_sel)
    local phase_selector = get(bus115_amp_phase_sel)

    if selector ~= state.selector_last
        or phase_selector ~= state.phase_last then
        state.timer = 0
        playPanelSample(SAMPLES.rotary)
    end

    state.selector_last = selector
    state.phase_last = phase_selector
    state.timer = state.timer + dt

    local target = -120

    if state.timer >= 0.05 then
        target = interpolate(
            AMP115_TABLE,
            selectedPropertyValue(AMP115_SOURCES, selector)
        )
    end

    set(bus115_amp, updateNeedle(state, target, dt))
end

local function updateVoltmeter36(dt)
    local state = GAUGE.volt36
    local selector = get(bus36_volt_sel)

    state.timer = state.timer + dt

    if selector ~= state.selector_last then
        state.timer = 0
        playPanelSample(SAMPLES.rotary)
    end

    state.selector_last = selector

    local target = -120

    if state.timer >= 0.05 then
        local voltage

        if selector < 3 then
            voltage = get(bus36_volt_left)
        elseif selector < 6 then
            voltage = get(bus36_volt_right)
        elseif get(pts250_sel) == 0 then
            voltage = get(bus36_volt_pts250_1)
        else
            voltage = get(bus36_volt_pts250_2)
        end

        target = interpolate(VOLT36_TABLE, voltage)
    end

    set(bus36_volt, updateNeedle(state, target, dt))
end

local function get27VoltSelectorValue(selector)
    if selector == 0 then
        return get(bat_volt_1)
    elseif selector == 1 then
        return get(bat_volt_3)
    elseif selector == 2 then
        return get(bus27_volt_left)
    elseif selector == 3 then
        return get(bus27_volt_right)
    elseif selector == 4 then
        return get(bat_volt_2)
    elseif selector == 5 then
        return get(bat_volt_4)
    end

    return 0
end

local function get27AmpSelectorValue(selector, right_side)
    if not right_side then
        if selector == 0 then
            return get(bat_amp_1) - get(bat_amp_cc_1)
        elseif selector == 1 then
            return get(bat_amp_3) - get(bat_amp_cc_3)
        elseif selector == 2 then
            return get(vu1_amp)
        elseif selector == 3 then
            return get(vu_res_amp)
        end
    else
        if selector == 0 then
            return get(bat_amp_2) - get(bat_amp_cc_2)
        elseif selector == 1 then
            return get(bat_amp_4) - get(bat_amp_cc_4)
        elseif selector == 2 then
            return get(vu2_amp)
        elseif selector == 3 then
            return get(vu_res_amp)
        end
    end

    return 0
end

local function updateBus27Gauges(dt)
    local volt_state = GAUGE.volt27
    local amp1_state = GAUGE.amp27_1
    local amp2_state = GAUGE.amp27_2

    local volt_selector = get(bus27_volt_sel)
    local amp1_selector = get(bus27_amp1_sel)
    local amp2_selector = get(bus27_amp2_sel)

    volt_state.timer = volt_state.timer + dt
    amp1_state.timer = amp1_state.timer + dt
    amp2_state.timer = amp2_state.timer + dt

    if volt_selector ~= volt_state.selector_last then
        volt_state.timer = 0
        playPanelSample(SAMPLES.rotary)
    end

    if amp1_selector ~= amp1_state.selector_last then
        amp1_state.timer = 0
        playPanelSample(SAMPLES.rotary)
    end

    if amp2_selector ~= amp2_state.selector_last then
        amp2_state.timer = 0
        playPanelSample(SAMPLES.rotary)
    end

    volt_state.selector_last = volt_selector
    amp1_state.selector_last = amp1_selector
    amp2_state.selector_last = amp2_selector

    local volt_target = -120
    if volt_state.timer >= 0.05 then
        volt_target = interpolate(
            VOLT27_TABLE,
            get27VoltSelectorValue(volt_selector)
        )
    end

    local amp1_target = -99
    if amp1_state.timer >= 0.05 then
        amp1_target = interpolate(
            AMP27_TABLE,
            get27AmpSelectorValue(amp1_selector, false)
        )
    end

    local amp2_target = -99
    if amp2_state.timer >= 0.05 then
        amp2_target = interpolate(
            AMP27_TABLE,
            get27AmpSelectorValue(amp2_selector, true)
        )
    end

    set(bus27_volt, updateNeedle(volt_state, volt_target, dt))
    set(bus27_amp1, updateNeedle(amp1_state, amp1_target, dt))
    set(bus27_amp2, updateNeedle(amp2_state, amp2_target, dt))
end

-- Switch sound tracking.
local SWITCHES = {
    { gpu_on, get(gpu_on) },
    { apu_gen_on, get(apu_gen_on) },
    { gen_1_on, get(gen_1_on) },
    { gen_2_on, get(gen_2_on) },
    { gen_3_on, get(gen_3_on) },
    { pts250_sel, get(pts250_sel) },
    { bus36_tr_left_to_right, get(bus36_tr_left_to_right) },
    { bus36_tr_right_to_left, get(bus36_tr_right_to_left) },
    { pts250_on, get(pts250_on) },
    { pts250_mode, get(pts250_mode) },
    { bus27_vu1, get(bus27_vu1) },
    { bus27_vu2, get(bus27_vu2) },
    { bat1_on, get(bat1_on) },
    { bat2_on, get(bat2_on) },
    { bat3_on, get(bat3_on) },
    { bat4_on, get(bat4_on) },
    { emerg_inv115, get(emerg_inv115) },
    { bus27_connect, get(bus27_connect) },
}

local CAPS = {
    { emerg_inv115_cap, emerg_inv115, get(emerg_inv115_cap) },
    { pts250_on_cap, pts250_on, get(pts250_on_cap) },
    { pts250_mode_cap, pts250_mode, get(pts250_mode_cap) },
    { bus27_connect_cap, bus27_connect, get(bus27_connect_cap) },
}

local function switchesCheck()
    local changed = false

    for _, item in ipairs(SWITCHES) do
        local current = get(item[1])

        if current ~= item[2] then
            changed = true
            item[2] = current
        end
    end

    if changed then
        playPanelSample(SAMPLES.switcher)
    end
end

local function capsCheck()
    local changed = false

    for _, item in ipairs(CAPS) do
        local cap_value = get(item[1])

        if cap_value ~= item[3] then
            changed = true
            item[3] = cap_value
        end

        if cap_value == 0 then
            set(item[2], 0)
        end
    end

    if changed then
        playPanelSample(SAMPLES.cap)
    end
end

local not_loaded = true

local function resetSwitchers()
    if get(eng1_N1) < 5
        and get(eng2_N1) < 5
        and get(eng3_N1) < 5 then

        set(gen_1_on, 0)
        set(gen_2_on, 0)
        set(gen_3_on, 0)

        set(bus27_vu1, 0)
        set(bus27_vu2, 0)

        set(bat1_on, 0)
        set(bat2_on, 0)
        set(bat3_on, 0)
        set(bat4_on, 0)
    end

    not_loaded = false
end

local function updateLamps()
    local bus27_left = get(bus27_volt_left)
    local bus27_right = get(bus27_volt_right)

    local lamp_power = clampValue(
        (math.max(bus27_left, bus27_right) - 10) / 18.5,
        0,
        1
    )

    local test_brightness = get(test_lamps) * lamp_power

    local bus115_1 = get(bus115_1_volt)
    local bus115_3 = get(bus115_3_volt)

    local gen1_voltage = get(gen1_volt)
    local gen2_voltage = get(gen2_volt)
    local gen3_voltage = get(gen3_volt)

    local bat1_switch = get(bat1_on)
    local bat2_switch = get(bat2_on)
    local bat3_switch = get(bat3_on)
    local bat4_switch = get(bat4_on)

    local left_source = get(bus27_source_left)
    local right_source = get(bus27_source_right)

    local gpu_lamp_brt = math.max(
        get(gpu_work_bus) * lamp_power,
        test_brightness
    )

    local npk_condition = 0
    if bus115_1 < GEN_MIN_VOLT and bus115_3 < GEN_MIN_VOLT then
        npk_condition = 1
    end
    local npk_brt = math.max(
        npk_condition * lamp_power,
        test_brightness
    )

    local emerg115_brt = math.max(
        get(emerg_inv115)
            * (1 - get(inv115_fail))
            * lamp_power,
        test_brightness
    )

    local gen_1_brt = math.max(
        (gen1_voltage < GEN_MIN_VOLT and 1 or 0) * lamp_power,
        test_brightness
    )
    local gen_2_brt = math.max(
        (gen2_voltage < GEN_MIN_VOLT and 1 or 0) * lamp_power,
        test_brightness
    )
    local gen_3_brt = math.max(
        (gen3_voltage < GEN_MIN_VOLT and 1 or 0) * lamp_power,
        test_brightness
    )

    local bus_con_brt = math.max(
        get(buses_connected) * lamp_power,
        test_brightness
    )

    local left_bat_condition = 0
    if left_source > 2 then
        left_bat_condition = math.max(bat1_switch, bat3_switch)
    end
    local left_bat_brt = math.max(
        left_bat_condition * lamp_power,
        test_brightness
    )

    local right_bat_condition = 0
    if right_source > 2 then
        right_bat_condition = math.max(bat2_switch, bat4_switch)
    end
    local right_bat_brt = math.max(
        right_bat_condition * lamp_power,
        test_brightness
    )

    local bat_1_brt = math.max(
        (get(bat_therm_1) > 100 and 1 or 0) * lamp_power,
        test_brightness
    )
    local bat_2_brt = math.max(
        (get(bat_therm_2) > 100 and 1 or 0) * lamp_power,
        test_brightness
    )
    local bat_3_brt = math.max(
        (get(bat_therm_3) > 100 and 1 or 0) * lamp_power,
        test_brightness
    )
    local bat_4_brt = math.max(
        (get(bat_therm_4) > 100 and 1 or 0) * lamp_power,
        test_brightness
    )

    local left_vu_brt = math.max(
        get(vu_res_to_L) * lamp_power,
        test_brightness
    )
    local right_vu_brt = math.max(
        get(vu_res_to_R) * lamp_power,
        test_brightness
    )

    local left_tr2_brt = math.max(
        get(bus36_src_L) * lamp_power,
        test_brightness
    )
    local right_tr1_brt = math.max(
        get(bus36_src_R) * lamp_power,
        test_brightness
    )

    -- PTS250 N1 means "PTS250 #1 not working".
    local pts_1_brt = math.max(
        (1 - get(bus36_pts1_work)) * lamp_power,
        test_brightness
    )

    -- PTS250 N2 means "PTS250 #2 on bus".
    local pts_2_brt = math.max(
        get(bus36_pts2_work) * lamp_power,
        test_brightness
    )

    set(lamp_apu_gen_on, gpu_lamp_brt)
    set(bus_npk_1, npk_brt)
    set(bus_npk_2, npk_brt)
    set(emerg_inv_115, emerg115_brt)

    set(gen_fail_1, gen_1_brt)
    set(gen_fail_2, gen_2_brt)
    set(gen_fail_3, gen_3_brt)

    set(bus_connected, bus_con_brt)
    set(left_bus_use_bat, left_bat_brt)
    set(right_bus_use_bat, right_bat_brt)

    set(turn_off_bat_1, bat_1_brt)
    set(turn_off_bat_2, bat_2_brt)
    set(turn_off_bat_3, bat_3_brt)
    set(turn_off_bat_4, bat_4_brt)

    set(vu_on_1, left_vu_brt)
    set(vu_on_2, right_vu_brt)

    set(left_bus_on_tr2, left_tr2_brt)
    set(right_bus_on_tr1, right_tr1_brt)

    set(pts250_n1, pts_1_brt)
    set(pts250_n2, pts_2_brt)
end

local sim_start_timer = 0

function update()
    local dt = get(frame_time)
    sim_start_timer = sim_start_timer + dt

    if sim_start_timer > 0.3 then
        if not_loaded then
            resetSwitchers()
        end

        switchesCheck()
        capsCheck()
    end

    updateVoltmeter115(dt)
    updateAmmeter115(dt)
    updateVoltmeter36(dt)
    updateBus27Gauges(dt)
    updateLamps()

    if get(bus27_volt_left) > 13
        or get(bus27_volt_right) > 13 then
        set(sim_avionics, 1)
    else
        set(sim_avionics, 0)
    end
end
