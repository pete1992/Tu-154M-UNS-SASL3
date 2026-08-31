-- Overhead control sounds, cold-and-dark cap initialization, and cap interlocks

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    -- X-Plane
    {"eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", globalProperty},
    {"eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]", globalProperty},
    {"eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", globalProperty},

    -- Timing
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},

    -- Overhead switches
    {"var_left", "tu154/custom/switchers/ovhd/var_left", globalPropertyi},
    {"var_right", "tu154/custom/switchers/ovhd/var_right", globalPropertyi},
    {"auasp_on", "tu154/custom/switchers/ovhd/auasp_on", globalPropertyi},
    {"auasp_contr", "tu154/custom/switchers/ovhd/auasp_contr", globalPropertyi},
    {"eup_on", "tu154/custom/switchers/ovhd/eup_on", globalPropertyi},
    {"agr_on", "tu154/custom/switchers/ovhd/agr_on", globalPropertyi},
    {"bkk_contr", "tu154/custom/switchers/ovhd/bkk_contr", globalPropertyi},
    {"bkk_on", "tu154/custom/switchers/ovhd/bkk_on", globalPropertyi},
    {"sau_stu_on", "tu154/custom/switchers/ovhd/sau_stu_on", globalPropertyi},
    {"pkp_left_on", "tu154/custom/switchers/ovhd/pkp_left_on", globalPropertyi},
    {"pkp_right_on", "tu154/custom/switchers/ovhd/pkp_right_on", globalPropertyi},
    {"mgv_contr", "tu154/custom/switchers/ovhd/mgv_contr", globalPropertyi},
    {"tks_on_1", "tu154/custom/switchers/ovhd/tks_on_1", globalPropertyi},
    {"tks_on_2", "tu154/custom/switchers/ovhd/tks_on_2", globalPropertyi},
    {"tks_heat", "tu154/custom/switchers/ovhd/tks_heat", globalPropertyi},
    {"tks_corr_1", "tu154/custom/switchers/ovhd/tks_corr_1", globalPropertyi},
    {"tks_corr_2", "tu154/custom/switchers/ovhd/tks_corr_2", globalPropertyi},
    {"curs_pnp_mode_1", "tu154/custom/switchers/ovhd/curs_pnp_mode_1", globalPropertyi},
    {"curs_pnp_mode_2", "tu154/custom/switchers/ovhd/curs_pnp_mode_2", globalPropertyi},
    {"svs_on", "tu154/custom/switchers/ovhd/svs_on", globalPropertyi},
    {"svs_heat", "tu154/custom/switchers/ovhd/svs_heat", globalPropertyi},
    {"kln_on", "tu154/custom/switchers/ovhd/kln_on", globalPropertyi},
    {"tcas_on", "tu154/custom/switchers/ovhd/tcas_on", globalPropertyi},
    {"emerg_light_on", "tu154/custom/switchers/ovhd/emerg_light_on", globalPropertyi},
    {"curs_np_on_1", "tu154/custom/switchers/ovhd/curs_np_on_1", globalPropertyi},
    {"curs_np_on_2", "tu154/custom/switchers/ovhd/curs_np_on_2", globalPropertyi},
    {"tra_67_on", "tu154/custom/switchers/ovhd/tra_67_on", globalPropertyi},
    {"rsbn_on", "tu154/custom/switchers/ovhd/rsbn_on", globalPropertyi},
    {"rsbn_recon", "tu154/custom/switchers/ovhd/rsbn_recon", globalPropertyi},
    {"rv5_1_on", "tu154/custom/switchers/ovhd/rv5_1_on", globalPropertyi},
    {"rv5_2_on", "tu154/custom/switchers/ovhd/rv5_2_on", globalPropertyi},
    {"vhf_1_on", "tu154/custom/switchers/ovhd/vhf_1_on", globalPropertyi},
    {"vhf_2_on", "tu154/custom/switchers/ovhd/vhf_2_on", globalPropertyi},
    {"stabil_ga_main", "tu154/custom/switchers/ovhd/stabil_ga_main", globalPropertyi},
    {"stabil_ga_reserv", "tu154/custom/switchers/ovhd/stabil_ga_reserv", globalPropertyi},
    {"micron_1_on", "tu154/custom/switchers/ovhd/micron_1_on", globalPropertyi},
    {"micron_2_on", "tu154/custom/switchers/ovhd/micron_2_on", globalPropertyi},
    {"spu_on", "tu154/custom/switchers/ovhd/spu_on", globalPropertyi},
    {"sgs_on", "tu154/custom/switchers/ovhd/sgs_on", globalPropertyi},
    {"sd75_1_on", "tu154/custom/switchers/ovhd/sd75_1_on", globalPropertyi},
    {"sd75_2_on", "tu154/custom/switchers/ovhd/sd75_2_on", globalPropertyi},
    {"uvid_on", "tu154/custom/switchers/ovhd/uvid_on", globalPropertyi},
    {"vbe_1_on", "tu154/custom/switchers/ovhd/vbe_1_on", globalPropertyi},
    {"vbe_2_on", "tu154/custom/switchers/ovhd/vbe_2_on", globalPropertyi},
    {"mars_on", "tu154/custom/switchers/ovhd/mars_on", globalPropertyi},
    {"vent_1", "tu154/custom/switchers/ovhd/vent_1", globalPropertyi},
    {"vent_2", "tu154/custom/switchers/ovhd/vent_2", globalPropertyi},
    {"vent_3", "tu154/custom/switchers/ovhd/vent_3", globalPropertyi},
    {"arm406", "tu154/custom/switchers/ovhd/arm406", globalPropertyi},
    {"ushdb_mode_1", "tu154/custom/switchers/ovhd/ushdb_mode_1", globalPropertyi},
    {"ushdb_mode_2", "tu154/custom/switchers/ovhd/ushdb_mode_2", globalPropertyi},

    -- Overhead pushbuttons
    {"tks_signal_off", "tu154/custom/buttons/ovhd/tks_signal_off", globalPropertyi},
    {"svs_contr", "tu154/custom/buttons/ovhd/svs_contr", globalPropertyi},

    -- Protective caps
    {"bkk_contr_cap", "tu154/custom/switchers/ovhd/bkk_contr_cap", globalPropertyi},
    {"bkk_on_cap", "tu154/custom/switchers/ovhd/bkk_on_cap", globalPropertyi},
    {"sau_stu_cap", "tu154/custom/switchers/ovhd/sau_stu_cap", globalPropertyi},
    {"pkp_left_cap", "tu154/custom/switchers/ovhd/pkp_left_cap", globalPropertyi},
    {"pkp_right_cap", "tu154/custom/switchers/ovhd/pkp_right_cap", globalPropertyi},
    {"mgv_contr_cap", "tu154/custom/switchers/ovhd/mgv_contr_cap", globalPropertyi},
    {"emerg_light_cap", "tu154/custom/switchers/ovhd/emerg_light_cap", globalPropertyi},
})

local COLD_DARK_CHECK_DELAY = 0.3
local ENGINE_STOPPED_N1 = 5
local CAP_CLOSED = 0
local CAP_OPEN = 1

local switcher_sound = sasl.al.loadSample("Custom Sounds/metal_switch.wav")
local cap_sound = sasl.al.loadSample("Custom Sounds/cap.wav")
local button_sound = sasl.al.loadSample("Custom Sounds/plastic_btn.wav")

local switch_properties = {
    var_left,
    var_right,
    auasp_on,
    auasp_contr,
    eup_on,
    agr_on,
    bkk_contr,
    bkk_on,
    sau_stu_on,
    pkp_left_on,
    pkp_right_on,
    mgv_contr,
    tks_on_1,
    tks_on_2,
    tks_heat,
    tks_corr_1,
    tks_corr_2,
    curs_pnp_mode_1,
    curs_pnp_mode_2,
    svs_on,
    svs_heat,
    kln_on,
    tcas_on,
    emerg_light_on,
    curs_np_on_1,
    curs_np_on_2,
    tra_67_on,
    rsbn_on,
    rsbn_recon,
    rv5_1_on,
    rv5_2_on,
    vhf_1_on,
    vhf_2_on,
    stabil_ga_main,
    stabil_ga_reserv,
    micron_1_on,
    micron_2_on,
    spu_on,
    sgs_on,
    sd75_1_on,
    sd75_2_on,
    uvid_on,
    vbe_1_on,
    vbe_2_on,
    mars_on,
    vent_1,
    vent_2,
    vent_3,
    arm406,
    ushdb_mode_1,
    ushdb_mode_2,
}

local button_properties = {
    tks_signal_off,
    svs_contr,
}

-- A closed cap mechanically forces the protected switch to the listed value.
-- The emergency-light cap is intentionally not opened during cold-and-dark setup.
local guarded_switches = {
    {cap = bkk_contr_cap, switch = bkk_contr, forced_value = 0, open_on_cold_dark = true},
    {cap = bkk_on_cap, switch = bkk_on, forced_value = 1, open_on_cold_dark = true},
    {cap = sau_stu_cap, switch = sau_stu_on, forced_value = 1, open_on_cold_dark = true},
    {cap = pkp_left_cap, switch = pkp_left_on, forced_value = 1, open_on_cold_dark = true},
    {cap = pkp_right_cap, switch = pkp_right_on, forced_value = 1, open_on_cold_dark = true},
    {cap = mgv_contr_cap, switch = mgv_contr, forced_value = 1, open_on_cold_dark = true},
    {cap = emerg_light_cap, switch = emerg_light_on, forced_value = 0, open_on_cold_dark = false},
}

local cap_properties = {}
for index = 1, #guarded_switches do
    cap_properties[index] = guarded_switches[index].cap
end

local function read_property_states(properties)
    local states = {}

    for index = 1, #properties do
        states[index] = get(properties[index])
    end

    return states
end

local function synchronize_property_states(properties, states)
    for index = 1, #properties do
        states[index] = get(properties[index])
    end
end

local function update_property_sound(properties, states, sample)
    local changed = false

    for index = 1, #properties do
        local current_value = get(properties[index])

        if current_value ~= states[index] then
            changed = true
        end

        states[index] = current_value
    end

    if changed then
        sasl.al.playSample(sample, false)
    end
end

local switch_states = read_property_states(switch_properties)
local cap_states = read_property_states(cap_properties)
local button_states = read_property_states(button_properties)

local cold_dark_check_pending = true
local cold_dark_elapsed = 0

local function initialize_cold_dark_caps()
    local engine_1_n1 = get(eng1_N1)
    local engine_2_n1 = get(eng2_N1)
    local engine_3_n1 = get(eng3_N1)

    if engine_1_n1 < ENGINE_STOPPED_N1
        and engine_2_n1 < ENGINE_STOPPED_N1
        and engine_3_n1 < ENGINE_STOPPED_N1
    then
        -- Preserve every loaded or manually selected switch position.
        for index = 1, #guarded_switches do
            local rule = guarded_switches[index]

            if rule.open_on_cold_dark and get(rule.cap) ~= CAP_OPEN then
                set(rule.cap, CAP_OPEN)
            end
        end

        -- Programmatic cap positioning must not create a cockpit-input sound.
        synchronize_property_states(cap_properties, cap_states)
    end

    cold_dark_check_pending = false
end

local function update_cold_dark_check()
    if not cold_dark_check_pending then
        return
    end

    cold_dark_elapsed = cold_dark_elapsed + get(frame_time)

    if cold_dark_elapsed > COLD_DARK_CHECK_DELAY then
        initialize_cold_dark_caps()
    end
end

local function update_switch_sounds()
    update_property_sound(switch_properties, switch_states, switcher_sound)
end

local function update_guard_caps()
    update_property_sound(cap_properties, cap_states, cap_sound)

    for index = 1, #guarded_switches do
        local rule = guarded_switches[index]

        if cap_states[index] == CAP_CLOSED and get(rule.switch) ~= rule.forced_value then
            set(rule.switch, rule.forced_value)
        end
    end
end

local function update_button_sounds()
    update_property_sound(button_properties, button_states, button_sound)
end

function update()
    update_cold_dark_check()
    update_switch_sounds()
    update_guard_caps()
    update_button_sounds()
end
