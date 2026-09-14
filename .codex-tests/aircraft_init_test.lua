-- Offline tests for the aircraft flight preset. No simulator or files are modified.
local root = arg[1] or "."
local module_path = root .. "/plugins/sasl/data/modules/Custom Module/aircraft_init.lua"
local assertions = 0
local function check(condition, message)
    assertions = assertions + 1
    assert(condition, message)
end
local function readFile(path)
    if readTestFile then return readTestFile(path) end
    local file = assert(io.open(path, "rb"))
    local source = file:read("*a")
    file:close()
    return source
end
local source = readFile(module_path)
local expected_rows = {}
local expected_by_path = {}
-- Independent, explicit allowlist: path | accessor type | cold/keep | hot.
-- Keeping this fixture separate makes an added production write fail the test.
local expected_text = [[
tu154/custom/switchers/eng/gen_1_on|i|0|1
tu154/custom/switchers/eng/gen_2_on|i|0|1
tu154/custom/switchers/eng/gen_3_on|i|0|1
tu154/custom/switchers/eng/bus27_vu1|i|0|1
tu154/custom/switchers/eng/bus27_vu2|i|0|1
tu154/custom/switchers/eng/bat1_on|i|0|1
tu154/custom/switchers/eng/bat2_on|i|0|1
tu154/custom/switchers/eng/bat3_on|i|0|1
tu154/custom/switchers/eng/bat4_on|i|0|1
tu154/custom/switchers/eng/gpu_on|i|0|0
tu154/custom/switchers/eng/apu_gen_on|i|0|0
tu154/custom/switchers/eng/emerg_inv115|i|0|0
tu154/custom/switchers/eng/emerg_inv115_cap|i|0|0
tu154/custom/switchers/eng/bus36_tr_left_to_right|i|0|0
tu154/custom/switchers/eng/bus36_tr_right_to_left|i|0|0
tu154/custom/switchers/eng/pts250_on|i|0|0
tu154/custom/switchers/eng/pts250_mode|i|0|0
tu154/custom/switchers/eng/pts250_on_cap|i|0|0
tu154/custom/switchers/eng/pts250_mode_cap|i|0|0
tu154/custom/switchers/eng/bus27_connect|i|0|0
tu154/custom/switchers/eng/bus27_connect_cap|i|0|0
tu154/custom/switchers/eng/emerg_gen_on_1|i|0|0
tu154/custom/switchers/eng/emerg_gen_on_2|i|0|0
tu154/custom/switchers/eng/emerg_gen_on_3|i|0|0
tu154/custom/switchers/eng/emerg_gen_on_1_cap|i|0|0
tu154/custom/switchers/eng/emerg_gen_on_2_cap|i|0|0
tu154/custom/switchers/eng/emerg_gen_on_3_cap|i|0|0
tu154/custom/switchers/fuel/pump_tank2_left|i|0|1
tu154/custom/switchers/fuel/pump_tank2_right|i|0|1
tu154/custom/switchers/fuel/pump_tank3_left|i|0|1
tu154/custom/switchers/fuel/pump_tank3_right|i|0|1
tu154/custom/switchers/fuel/pump_tank4|i|0|1
tu154/custom/switchers/fuel/pump_tank1_1|i|0|1
tu154/custom/switchers/fuel/pump_tank1_2|i|0|1
tu154/custom/switchers/fuel/pump_tank1_3|i|0|1
tu154/custom/switchers/fuel/pump_tank1_4|i|0|1
tu154/custom/switchers/fuel/fuel_level|i|0|1
tu154/custom/switchers/fuel/fuel_flow_mode|i|0|1
tu154/custom/switchers/fuel/fuel_flow_on|i|0|1
tu154/custom/switchers/fuel/fuel_meter_on|i|0|1
tu154/custom/switchers/fuel/fuel_meter_mech_on|i|0|1
tu154/custom/switchers/fuel/fire_valve_1|i|0|1
tu154/custom/switchers/fuel/fire_valve_2|i|0|1
tu154/custom/switchers/fuel/fire_valve_3|i|0|1
tu154/custom/switchers/fuel/fuel_trans|i|0|0
tu154/custom/switchers/fuel/fuel_trans_cap|i|0|0
tu154/custom/switchers/fuel/fuel_porc|i|0|0
tu154/custom/switchers/fuel/fuel_porc_cap|i|0|0
tu154/custom/switchers/fuel/fuel_flow_on_cap|i|0|0
tu154/custom/switchers/fuel/fire_valve_1_cap|i|0|0
tu154/custom/switchers/fuel/fire_valve_2_cap|i|0|0
tu154/custom/switchers/fuel/fire_valve_3_cap|i|0|0
tu154/custom/start/fuel_in_1|i|0|1
tu154/custom/start/fuel_in_2|i|0|1
tu154/custom/start/fuel_in_3|i|0|1
tu154/custom/switchers/eng/starter_cap|i|0|0
tu154/custom/switchers/eng/starter_switch|i|0|0
tu154/custom/switchers/eng/starter_eng_select|i|0|0
tu154/custom/switchers/eng/starter_mode|i|0|0
tu154/custom/buttons/eng/starter_start|i|0|0
tu154/custom/buttons/eng/starter_stop|i|0|0
tu154/custom/buttons/eng/flight_start_1|i|0|0
tu154/custom/buttons/eng/flight_start_2|i|0|0
tu154/custom/buttons/eng/flight_start_3|i|0|0
tu154/custom/switchers/eng/gauges_on_1|i|0|1
tu154/custom/switchers/eng/gauges_on_2|i|0|1
tu154/custom/switchers/eng/gauges_on_3|i|0|1
tu154/custom/switchers/eng/fire_main_switch|i|0|1
tu154/custom/switchers/eng/gauges_on_1_cap|i|1|0
tu154/custom/switchers/eng/gauges_on_2_cap|i|1|0
tu154/custom/switchers/eng/gauges_on_3_cap|i|1|0
tu154/custom/switchers/eng/fire_buzzer|i|keep|1
tu154/custom/switchers/eng/fire_buzzer_cap|i|keep|0
tu154/custom/switchers/console/buster_on_1|i|0|1
tu154/custom/switchers/console/buster_on_2|i|0|1
tu154/custom/switchers/console/buster_on_3|i|0|1
tu154/custom/switchers/console/absu_needles_on|i|0|1
tu154/custom/switchers/console/absu_nav_on|i|0|1
tu154/custom/switchers/console/absu_speed_prepare|i|0|1
tu154/custom/switchers/console/absu_roll_ch_on|i|0|1
tu154/custom/switchers/console/absu_pitch_ch_on|i|0|1
tu154/custom/switchers/console/nvu_power_on|i|0|1
tu154/custom/switchers/console/busters_cap|i|1|0
tu154/custom/switchers/console/absu_speed_prepare_cap|i|keep|0
tu154/custom/buttons/console/absu_throt_off_1|i|1|0
tu154/custom/buttons/console/absu_throt_off_2|i|1|0
tu154/custom/buttons/console/absu_throt_off_3|i|1|0
tu154/custom/switchers/nosewheel_turn_enable|i|keep|1
tu154/custom/switchers/nosewheel_turn_sel|i|1|0
tu154/custom/switchers/nosewheel_turn_cap|i|1|0
tu154/custom/switchers/airbleed/cockpit_mode_set|i|0|1
tu154/custom/switchers/airbleed/cabin1_mode_set|i|0|1
tu154/custom/switchers/airbleed/cabin2_mode_set|i|0|1
tu154/custom/switchers/airbleed/left_sys_mode_set|i|0|1
tu154/custom/switchers/airbleed/right_sys_mode_set|i|0|1
tu154/custom/switchers/airbleed/psvp_left_on|i|0|1
tu154/custom/switchers/airbleed/psvp_right_on|i|0|1
tu154/custom/switchers/airbleed/eng_valve_1|i|0|1
tu154/custom/switchers/airbleed/eng_valve_2|i|0|1
tu154/custom/switchers/airbleed/eng_valve_3|i|0|1
tu154/custom/switchers/airbleed/psvp_left_on_cap|i|keep|0
tu154/custom/switchers/airbleed/psvp_right_on_cap|i|keep|0
tu154/custom/switchers/ovhd/diss_on|i|0|1
tu154/custom/switchers/ovhd/diss_mode|i|0|1
tu154/custom/switchers/ovhd/nvu_calc_set|i|0|1
tu154/custom/switchers/ovhd/ark_1_mode|i|0|1
tu154/custom/switchers/ovhd/ark_2_mode|i|0|1
tu154/custom/switchers/ovhd/var_left|i|keep|1
tu154/custom/switchers/ovhd/var_right|i|keep|1
tu154/custom/switchers/ovhd/auasp_on|i|keep|1
tu154/custom/switchers/ovhd/eup_on|i|keep|1
tu154/custom/switchers/ovhd/agr_on|i|keep|1
tu154/custom/switchers/ovhd/tks_on_1|i|keep|1
tu154/custom/switchers/ovhd/tks_on_2|i|keep|1
tu154/custom/switchers/ovhd/svs_on|i|keep|1
tu154/custom/switchers/ovhd/svs_heat|i|keep|1
tu154/custom/switchers/ovhd/kln_on|i|keep|1
tu154/custom/switchers/ovhd/tcas_on|i|keep|1
tu154/custom/switchers/ovhd/vbe_1_on|i|keep|1
tu154/custom/switchers/ovhd/vbe_2_on|i|keep|1
tu154/custom/switchers/ovhd/curs_np_on_1|i|keep|1
tu154/custom/switchers/ovhd/curs_np_on_2|i|keep|1
tu154/custom/switchers/ovhd/tra_67_on|i|keep|1
tu154/custom/switchers/ovhd/rsbn_on|i|keep|1
tu154/custom/switchers/ovhd/rv5_1_on|i|keep|1
tu154/custom/switchers/ovhd/rv5_2_on|i|keep|1
tu154/custom/switchers/ovhd/vhf_1_on|i|keep|1
tu154/custom/switchers/ovhd/vhf_2_on|i|keep|1
tu154/custom/switchers/ovhd/uvid_on|i|keep|1
tu154/custom/switchers/ovhd/mars_on|i|keep|1
tu154/custom/switchers/ovhd/bkk_contr_cap|i|1|0
tu154/custom/switchers/ovhd/bkk_on_cap|i|1|0
tu154/custom/switchers/ovhd/sau_stu_cap|i|1|0
tu154/custom/switchers/ovhd/pkp_left_cap|i|1|0
tu154/custom/switchers/ovhd/pkp_right_cap|i|1|0
tu154/custom/switchers/ovhd/mgv_contr_cap|i|1|0
tu154/custom/switchers/ovhd/bkk_contr|i|keep|0
tu154/custom/switchers/ovhd/bkk_on|i|keep|1
tu154/custom/switchers/ovhd/sau_stu_on|i|keep|1
tu154/custom/switchers/ovhd/pkp_left_on|i|keep|1
tu154/custom/switchers/ovhd/pkp_right_on|i|keep|1
tu154/custom/switchers/ovhd/mgv_contr|i|keep|1
tu154/custom/switchers/ovhd/window_heat_1|i|0|-1
tu154/custom/switchers/ovhd/window_heat_2|i|0|-1
tu154/custom/switchers/ovhd/window_heat_3|i|0|-1
tu154/custom/switchers/ovhd/pitot_heat_1|i|0|1
tu154/custom/switchers/ovhd/pitot_heat_2|i|0|1
tu154/custom/switchers/ovhd/pitot_heat_3|i|0|1
tu154/custom/switchers/eng/soi21_on|i|0|1
tu154/custom/switchers/eng/antiice_slats|i|0|0
tu154/custom/switchers/eng/antiice_eng_1|i|0|0
tu154/custom/switchers/eng/antiice_eng_2|i|0|0
tu154/custom/switchers/eng/antiice_eng_3|i|0|0
tu154/custom/switchers/eng/antiice_wing|i|0|0
tu154/custom/switchers/eng/msrp_mlp_1|i|0|1
tu154/custom/switchers/eng/msrp_mlp_2|i|0|1
tu154/custom/switchers/eng/msrp_main_switch|i|0|1
tu154/custom/lights/nav_lights_set|i|0|1
tu154/custom/lights/strobe_set|i|0|1
tu154/custom/lights/tail_light_set|i|0|1
tu154/custom/lights/wing_light_left_set|i|0|0
tu154/custom/lights/wing_light_right_set|i|0|0
tu154/custom/lights/landing_ext_set_L|i|0|0
tu154/custom/lights/landing_ext_set_R|i|0|0
tu154/custom/lights/landing_mode_set_L|i|0|0
tu154/custom/lights/landing_mode_set_R|i|0|0
tu154/custom/switchers/ovhd/sign_belts|i|0|1
tu154/custom/switchers/ovhd/sign_nosmoke|i|0|1
tu154/custom/switchers/ovhd/sign_exit|i|0|0
tu154/custom/switchers/tcas/tcas_mode|i|0|4
tu154/custom/anim/gear_blocks|i|1|0
tu154/custom/anim/sensors_caps|i|1|0
tu154/custom/anim/engine_caps|i|1|0
tu154/custom/uns1_on|f|keep|1
tu154/custom/uns2_on|f|keep|1
tu154/custom/kontur/weather_sys|f|keep|1
tu154/custom/kontur/left_power|f|keep|1
tu154/custom/kontur/right_power|f|keep|1
tu154/custom/ubs/left_power|f|keep|1
tu154/custom/ubs/right_power|f|keep|1
tu154/custom/tcas2000/mode|f|keep|4
tu154/custom/kontur/weather_mode|f|keep|1
tu154/custom/kontur/srpbz|f|keep|1
tu154/custom/switchers/eng/szt_1|f|keep|1
tu154/custom/switchers/eng/szt_2|f|keep|1
tu154/custom/switchers/eng/szt_3|f|keep|1
]]
for line in expected_text:gmatch("[^\r\n]+") do
    local path, kind, cold, hot = line:match("^([^|]+)|([^|]+)|([^|]+)|([^|]+)$")
    check(path ~= nil, "Malformed preset fixture: " .. line)
    check(expected_by_path[path] == nil, "Duplicate expected path: " .. path)
    local row = {path = path, kind = kind, cold = tonumber(cold), hot = tonumber(hot)}
    expected_rows[#expected_rows + 1] = row
    expected_by_path[path] = row
end
check(#expected_rows == 186, "The reviewed preset allowlist changed")

local creator_defaults = {}
for i = 1, 4 do
    local creator = readFile(root .. "/plugins/sasl/data/modules/Custom Module/dataref_creator_" .. i .. ".lua")
    for line in creator:gmatch("[^\r\n]+") do
        local kind, path, value = line:match('^createGlobalProperty([if])%("([^"]+)",%s*([%d%.%-]+)')
        if path then
            creator_defaults[path] = {kind = kind, value = tonumber(value)}
        end
    end
end
local xtlua_hot = {
    ["tu154/custom/uns1_on"] = 1,
    ["tu154/custom/uns2_on"] = 1,
    ["tu154/custom/kontur/weather_sys"] = 1,
    ["tu154/custom/kontur/left_power"] = 1,
    ["tu154/custom/kontur/right_power"] = 1,
    ["tu154/custom/ubs/left_power"] = 1,
    ["tu154/custom/ubs/right_power"] = 1,
    ["tu154/custom/tcas2000/mode"] = 4,
    ["tu154/custom/kontur/weather_mode"] = 1,
    ["tu154/custom/kontur/srpbz"] = 1,
    ["tu154/custom/switchers/eng/szt_1"] = 1,
    ["tu154/custom/switchers/eng/szt_2"] = 1,
    ["tu154/custom/switchers/eng/szt_3"] = 1,
}
local creator_checks = 0
for _, row in ipairs(expected_rows) do
    local creator = creator_defaults[row.path]
    if creator then
        check(creator.kind == row.kind, "Wrong accessor type: " .. row.path)
        check(creator.value == row.hot, "Hot value differs from creator: " .. row.path)
        creator_checks = creator_checks + 1
    else
        check(row.kind == "f" and xtlua_hot[row.path] == row.hot,
            "Unreviewed xTlua preset: " .. row.path)
    end
end
check(creator_checks == 173, "SASL creator coverage changed")
check(not source:find("createGlobalProperty", 1, true), "Initializer must not create/recreate existing DataRefs")

local PREF = "sim/operation/prefs/startup_running"
local MASTER = "scp/api/ismaster"
local forbidden = {
    ["sim/flightmodel/weight/m_fuel[0]"] = 1234,
    ["sim/cockpit2/engine/actuators/mixture_ratio[0]"] = 0,
    ["sim/flightmodel/engine/ENGN_N1_[0]"] = 0,
    ["sim/flightmodel/engine/ENGN_N2_[0]"] = 0,
    ["sim/flightmodel2/engines/engine_is_burning_fuel[0]"] = 0,
    ["sim/operation/failures/rel_engfai0"] = 6,
    ["sim/operation/failures/rel_genera0"] = 6,
    ["tu154/custom/failures/eng_fuel_pmp_fail_1"] = 1,
    ["tu154/custom/hydro/gs_press_1"] = 42,
    ["tu154/custom/hydro/gs_qty_1"] = 43,
    ["tu154/custom/payload/cargo_1"] = 987,
    ["tu154/custom/absu/roll_main_mode"] = 0,
    ["tu154/custom/absu/pitch_main_mode"] = 0,
    ["sim/cockpit/autopilot/autopilot_state"] = 0,
    ["tu154/custom/kontur/latitude"] = "keep route",
    ["tu154/custom/tcas2000/squawk"] = 4321,
}
local function newController(pref, master)
    local state, writes, reads, bindings = {}, {}, {}, {}
    for _, row in ipairs(expected_rows) do
        state[row.path] = 7
    end
    for path, value in pairs(forbidden) do
        state[path] = value
    end
    state[PREF], state[MASTER] = pref, master
    local env = setmetatable({}, {__index = _G})
    local function accessor(kind)
        return function(path)
            check(path == PREF or path == MASTER or expected_by_path[path],
                "Unexpected binding: " .. path)
            if expected_by_path[path] then
                check(expected_by_path[path].kind == kind, "Wrong binding type: " .. path)
            end
            return path
        end
    end
    env.globalPropertyi = accessor("i")
    env.globalPropertyf = accessor("f")
    env.defineProperty = function(name, property)
        check(bindings[name] == nil, "Duplicate property name: " .. name)
        bindings[name] = property
        env[name] = property
    end
    env.get = function(property)
        check(state[property] ~= nil, "Read of undefined property: " .. tostring(property))
        reads[property] = (reads[property] or 0) + 1
        return state[property]
    end
    env.set = function(property, value)
        check(expected_by_path[property] ~= nil, "Write outside control allowlist: " .. tostring(property))
        check(type(value) == "number", "A preset write must be numeric")
        writes[#writes + 1] = {path = property, value = value}
        state[property] = value
    end
    env.print = function() end
    local chunk
    if setfenv then
        chunk = assert(loadstring(source, "@" .. module_path))
        setfenv(chunk, env)
    else
        chunk = assert(load(source, "@" .. module_path, "t", env))
    end
    chunk()
    local count = 0
    for _ in pairs(bindings) do count = count + 1 end
    check(count == #expected_rows + 2, "Binding allowlist is incomplete")
    check(#writes == 0, "File load must not perform preset writes")
    return {env = env, state = state, writes = writes, reads = reads}
end
local function assertPreset(c, hot, baseline)
    local expected_count = 0
    for _, row in ipairs(expected_rows) do
        local value = row.cold
        if hot then value = row.hot end
        if value ~= nil then expected_count = expected_count + 1
        else value = baseline or 7 end
        check(c.state[row.path] == value, "Wrong " .. (hot and "hot" or "cold") .. " value: " .. row.path)
    end
    for path, value in pairs(forbidden) do
        check(c.state[path] == value, "Non-control state changed: " .. path)
    end
    return expected_count
end
local function assertBatch(c, from, hot)
    local seen, expected_count = {}, 0
    for _, row in ipairs(expected_rows) do
        if hot or row.cold ~= nil then expected_count = expected_count + 1 end
    end
    check(#c.writes - from == expected_count, "Preset write count differs from allowlist")
    for i = from + 1, #c.writes do
        local write = c.writes[i]
        check(not seen[write.path], "Duplicate preset write: " .. write.path)
        seen[write.path] = true
        local row = expected_by_path[write.path]
        local value = row.cold
        if hot then value = row.hot end
        check(write.value == value, "Unexpected preset value: " .. write.path)
    end
end

-- Fresh hot load remains hot even before X-Plane publishes any engine RPM.
local hot = newController(1, 0)
hot.env.update()
assertPreset(hot, true)
assertBatch(hot, 0, true)
check(hot.reads[PREF] == 1, "Read startup preference once at initial apply")
local hot_writes = #hot.writes
hot.state[PREF] = 0
for _, row in ipairs(expected_rows) do hot.state[row.path] = 9 end
for _ = 1, 240 do hot.env.update() end
check(#hot.writes == hot_writes, "Must not force controls after initialization")
check(hot.reads[PREF] == 1, "Must not poll startup preference continuously")
for _, row in ipairs(expected_rows) do
    check(hot.state[row.path] == 9, "Manual shutdown/control movement was overwritten")
end

-- Fresh cold load uses only existing explicit cold resets.
local cold = newController(0, 2)
cold.env.update()
assertPreset(cold, false)
assertBatch(cold, 0, false)
local cold_writes = #cold.writes
cold.state[PREF] = 1
for _ = 1, 60 do cold.env.update() end
check(#cold.writes == cold_writes, "Preference change without new flight must not initialize")

-- An arbitrary flightIndex is still the documented USER-aircraft event.
cold.env.onAirportLoaded(17)
check(#cold.writes == cold_writes, "Airport callback should queue, not write mid-callback")
cold.state[PREF] = 0
cold.env.update()
assertPreset(cold, true)
assertBatch(cold, cold_writes, true)

-- Multiple callbacks before the next update coalesce to the latest snapshot.
for _, row in ipairs(expected_rows) do cold.state[row.path] = 7 end
local previous_writes = #cold.writes
cold.state[PREF] = 1
cold.env.onAirportLoaded(23)
cold.state[PREF] = 0
cold.env.onAirportLoaded()
cold.env.update()
assertPreset(cold, false)
assertBatch(cold, previous_writes, false)
previous_writes = #cold.writes
cold.env.update()
check(#cold.writes == previous_writes, "Queued cold preset must be one-shot")

-- Callback before the initial update must not cause two applications.
local early = newController(0, 0)
early.state[PREF] = 1
early.env.onAirportLoaded(0)
early.env.update()
assertPreset(early, true)
assertBatch(early, 0, true)
local early_writes = #early.writes
early.env.update()
check(#early.writes == early_writes, "Initial/event requests must coalesce")

-- Slave consumes requests without applying them, including late role changes.
local slave = newController(1, 1)
slave.env.update()
check(#slave.writes == 0, "SmartCopilot slave must not apply a preset")
slave.state[MASTER] = 2
slave.env.update()
check(#slave.writes == 0, "Acquiring control must not unexpectedly reset controls")
slave.env.onAirportLoaded(81)
slave.env.update()
assertPreset(slave, true)
assertBatch(slave, 0, true)
local slave_writes = #slave.writes
slave.state[MASTER] = 1
slave.env.onAirportLoaded()
slave.env.update()
check(#slave.writes == slave_writes, "Slave airport restart must not write")
slave.state[MASTER] = 2
slave.env.update()
check(#slave.writes == slave_writes, "Consumed slave event must stay consumed")

print("aircraft_init_test: PASS (" .. assertions .. " assertions; 186 reviewed control refs)")
