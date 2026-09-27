-- xtlua_usvp_test.lua
-- Offline ownership/regression tests using the installed classic-main bootstrap.
-- Native DataRefs, timer scheduling and SASL terrain probes are mocked here.
-- Run with LuaJIT from the aircraft root, or pass the aircraft root as argument 1.

local root = (arg[1] or "."):gsub("\\", "/"):gsub("/$", "")
local sasl = root .. "/plugins/sasl/data/modules/Custom Module/"
local source = root .. "/plugins/xtlua/init/scripts/T154.usvp/T154.usvp.lua"
local checks = 0

local function check(condition, message)
    checks = checks + 1
    assert(condition, message)
end

local function equal(actual, expected, message)
    check(actual == expected, message .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local function near(actual, expected, message)
    check(type(actual) == "number" and math.abs(actual - expected) <= 1e-9,
        message .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local function read(path)
    local file = assert(io.open(path, "rb"))
    local contents = file:read("*a")
    file:close()
    return contents
end

local function run_file(path, env)
    local chunk = assert(loadfile(path))
    setfenv(chunk, env)
    return chunk()
end

local definitions = {
    { "tas_svs", "tu154/custom/svs/true_airspeed", 0 },
    { "diss_groundspeed", "tu154/custom/nvu/diss_groundspeed", 0 },
    { "diss_cc", "tu154/custom/nvu/diss_cc", 0 },
    { "diss_mode", "tu154/custom/nvu/diss_mode", 0 },
    { "speed_mid_flag", "tu154/custom/gauges/speed/speed_mid_flag", 0 },
    { "speed_mid_needle", "tu154/custom/gauges/speed/speed_mid_needle", 0 },
    { "sim_frame_period", "sim/operation/misc/frame_rate_period", 1 / 60 },
    { "sim_paused", "sim/time/paused", 0 },
}

local function runtime(missing)
    local rt = { refs = {}, timers = {}, writes = 0 }
    for index, def in ipairs(definitions) do
        rt.refs[def[2]] = {
            path = def[2], value = def[3], type = (missing == index or missing == "all") and "none" or "number",
        }
    end
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.XLuaFindDataRef = function(path) return assert(rt.refs[path], "Unexpected USVP binding: " .. path) end
    env.XLuaGetDataRefType = function(handle) return handle.type end
    env.XLuaGetNumber = function(handle)
        check(handle.type == "number", "Do not read an unresolved USVP DataRef")
        return handle.value
    end
    env.XLuaSetNumber = function(handle, value)
        check(handle.type == "number", "Do not write an unresolved USVP DataRef")
        equal(handle.path, definitions[6][2], "USVP only owns the needle output")
        handle.value = value
        rt.writes = rt.writes + 1
    end
    env.XLuaCreateTimer = function(callback)
        local timer = { callback = callback }
        rt.timers[#rt.timers + 1] = timer
        return timer
    end
    env.XLuaRunTimer = function(timer, delay, interval) timer.delay, timer.interval = delay, interval end
    run_file(root .. "/plugins/xtlua/init/init.lua", env)
    env.run_module_in_namespace(assert(loadfile(source)))
    rt.bootstrap, rt.module = env, env.n
    equal(rt.writes, 0, "Loading USVP does not write SASL-owned DataRefs before readiness")
    equal(#rt.timers, 1, "One USVP timer is registered")
    check(rt.module.after_physics == nil and rt.module.after_replay == nil,
        "No duplicate USVP integration through physics/replay callbacks")
    for _, def in ipairs(definitions) do
        check(rawget(env, def[1]) == nil, "USVP binding does not leak into bootstrap globals: " .. def[1])
        check(rawget(rt.module, "functions")[def[1]] ~= nil, "USVP binding is a transparent module property: " .. def[1])
    end
    function rt:set(name, value)
        for _, def in ipairs(definitions) do
            if def[1] == name then self.refs[def[2]].value = value; return end
        end
        error("Unknown USVP binding: " .. name)
    end
    function rt:get(name)
        for _, def in ipairs(definitions) do if def[1] == name then return self.refs[def[2]].value end end
        error("Unknown USVP binding: " .. name)
    end
    function rt:tick()
        local timer = self.timers[1]
        equal(timer.delay, 0, "USVP timer starts immediately")
        equal(timer.interval, 0, "USVP uses one classic-main callback per frame")
        timer.callback()
    end
    return rt
end

local function sasl_component(path, values, writes)
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.globalPropertyf = function(name) if values[name] == nil then values[name] = 0 end; return name end
    env.globalPropertyi = env.globalPropertyf
    env.defineProperty = function(name, property) env[name] = property end
    env.get = function(property) return assert(values[property], "Missing SASL mock property: " .. property) end
    env.set = function(property, value)
        values[property] = value
        if writes then writes[property] = (writes[property] or 0) + 1 end
    end
    env.bool2int = function(value) return value and 1 or 0 end
    env.PROBE_HIT_TERRAIN = 0
    env.sasl = { probeTerrain = function(x, y, z) return 0, x, y, z, 0, 1, 0, 0, 0, 0, 0 end }
    run_file(path, env)
    return env
end

local function uncommented(text)
    return text:gsub("%-%-%[%[.-%]%]", ""):gsub("%-%-[^\r\n]*", "")
end

-- Cutover and single-writer contracts are checked in addition to numeric tests.
do
    local host = uncommented(read(sasl .. "main_panel/main_panel.lua"))
    check(not host:match("%f[%a]usvp%s*{"), "SASL must not instantiate the former USVP writer")
    local systems = uncommented(read(root .. "/plugins/xtlua/init/scripts/T154.systems/T154.systems.lua"))
    check(not systems:find("speed_mid_needle", 1, true), "T154.systems no longer binds/writes the USVP needle")
    check(not systems:find("tu154/custom/nvu/diss_", 1, true), "DISS publication belongs to its producer, not T154.systems")
    local usvp = read(source)
    check(usvp:match("^%-%- T154%.usvp%.lua"), "USVP script name is on line 1")
end

for missing = 1, #definitions do
    local rt = runtime(missing)
    for _ = 1, 3 do rt:tick() end
    equal(rt.writes, 0, "Unresolved USVP input/output blocks publication")
    rt.refs[definitions[missing][2]].type = "number"
    rt:tick()
    equal(rt.writes, 1, "USVP recovers when its late DataRef resolves")
    rt.refs[definitions[missing][2]].type = "none"
    rt:tick()
    equal(rt.writes, 1, "USVP stops writing when a resolved DataRef disappears")
end

do
    local rt = runtime("all")
    rt:tick()
    for index, def in ipairs(definitions) do
        rt.refs[def[2]].type = "number"
        rt:tick()
        if index < #definitions then equal(rt.writes, 0, "All USVP handles must be resolved together") end
    end
    equal(rt.writes, 1, "USVP begins once the complete binding set resolves")
end

-- Execute the former SASL USVP and time component rather than retype their filter.
local function pair()
    local rt = runtime()
    local values = { ["tu154/custom/time/frame_time"] = 0 }
    for _, def in ipairs(definitions) do values[def[2]] = def[3] end
    local timing = sasl_component(sasl .. "time_logic.lua", values)
    local former = sasl_component(sasl .. "main_panel/usvp.lua", values)
    local function step(dt, tas, gs, selector, power, mode, paused, replay)
        local input = {
            sim_frame_period = dt, tas_svs = tas, diss_groundspeed = gs, speed_mid_flag = selector,
            diss_cc = power, diss_mode = mode, sim_paused = paused or 0,
        }
        for _, def in ipairs(definitions) do
            if input[def[1]] ~= nil then rt:set(def[1], input[def[1]]); values[def[2]] = input[def[1]] end
        end
        rt.bootstrap.setup_callback_var("SIM_PERIOD", 999)
        rt.bootstrap.setup_callback_var("IN_REPLAY", replay or 0)
        timing.update(); former.update(); rt:tick()
        local expected = values[definitions[6][2]]
        if selector == 1 and power > 0 and mode == 0 then expected = 0 end
        near(rt:get("speed_mid_needle"), expected, "USVP preserves filter state and applies one final warm-up gate")
        return rt:get("speed_mid_needle")
    end
    return rt, step
end

for _, fps in ipairs({ 10, 20, 30, 60, 120 }) do
    local rt, step = pair()
    for frame = 1, fps * 6 do
        local phase = math.floor((frame - 1) / fps)
        local selector = phase < 2 and 0 or 1
        local power = phase == 4 and 0 or 1
        local mode = phase == 2 and 0 or (phase == 3 and 3 or 2)
        step(1 / fps, 450 + phase * 100, phase == 3 and 709.9992 or 950 + phase * 40,
            selector, power, mode, 0, phase == 5 and 1 or 0)
    end
    check(rt:get("speed_mid_needle") > 360, "USVP must preserve unwrapped speed above 1000 km/h")
end

do
    local rt, step = pair()
    step(0.1, 500, 800, 0, 1, 0)
    local held = step(0.1, 500, 800, 0, 1, 0)
    check(held > 0, "DISS warm-up must not suppress TAS display")
    for _, dt in ipairs({ 0, -1, 0 / 0, math.huge, -math.huge }) do
        near(step(dt, 900, 1000, 0, 1, 2), held, "Invalid duration cannot move the needle")
    end
    near(step(0.1, 900, 1000, 0, 1, 2, 1), held, "Pause holds USVP state")
    near(step(0.1, 900, 1000, 0, 1, 2, 1, 1), held, "Paused replay holds USVP state")
    check(step(0.1, 900, 1000, 0, 1, 2, 0, 1) > held, "Playing replay updates USVP")
    step(0.5, 900, 1000, 0, 1, 2)
    step(9, 900, 1000, 0, 1, 2)
    near(step(0.1, 900, 1000, 1, 1, 0), 0, "Powered DISS warm-up hides GS needle")
    for _ = 1, 20 do step(0.1, 900, 1000, 1, 1, 0) end
    check(step(0.1, 900, 1000, 1, 1, 2) > 359.9, "Warm-up retains hidden filter state for release")
    check(step(0.1, 900, 1000, 1, 0, 0) > 0, "Unpowered DISS is not mistaken for warm-up")
    held = rt:get("speed_mid_needle")
    rt.bootstrap.do_callout("flight_start")
    near(step(0, 900, 1000, 1, 0, 0), held, "Flight callback does not reset USVP state")
    for _, selector in ipairs({ -1, 0, 2, 1.01 }) do
        check(step(0.1, 900, 1000, selector, 1, 0) > 0, "Only exact selector value 1 chooses/gates groundspeed")
    end
end

do
    local rt = runtime()
    rt:set("sim_frame_period", 0.1)
    rt:set("tas_svs", 500); rt:tick()
    local held, writes = rt:get("speed_mid_needle"), rt.writes
    for _, invalid in ipairs({ 0 / 0, math.huge, -math.huge }) do
        rt:set("tas_svs", invalid); rt:tick()
        equal(rt.writes, writes, "Invalid selected TAS is not published")
        near(rt:get("speed_mid_needle"), held, "Invalid selected TAS cannot poison filter state")
    end
    rt:set("tas_svs", 500); rt:tick()
    check(rt:get("speed_mid_needle") > held, "Valid TAS recovers after invalid input")
    held, writes = rt:get("speed_mid_needle"), rt.writes
    rt:set("speed_mid_flag", 1)
    for _, invalid in ipairs({ 0 / 0, math.huge, -math.huge }) do
        rt:set("diss_groundspeed", invalid); rt:tick()
        equal(rt.writes, writes, "Invalid selected GS is not published")
        near(rt:get("speed_mid_needle"), held, "Invalid selected GS cannot poison filter state")
    end
    rt:set("diss_groundspeed", 800); rt:tick()
    check(rt:get("speed_mid_needle") > held, "Valid GS recovers after invalid input")
end

local diss_prefix = "tu154/custom/nvu/"
local diss_outputs = { "diss_groundspeed", "diss_slip_angle", "diss_wind_spd", "diss_wind_course", "diss_mode" }
local diss_time = "sim/time/total_running_time_sec"
local diss_switch = "tu154/custom/switchers/ovhd/diss_on"
local nvu_switch = "tu154/custom/switchers/ovhd/nvu_calc_set"

local function diss_runtime(authority)
    local values = {
        ["scp/api/ismaster"] = authority or 0,
        ["tu154/custom/time/frame_time"] = 0.02,
        [diss_time] = 1000,
        [diss_switch] = 1,
        [nvu_switch] = -1,
        ["tu154/custom/elec/bus27_volt_left"] = 28.5,
        ["tu154/custom/elec/bus36_volt_left"] = 36,
        ["tu154/custom/elec/bus115_1_volt"] = 115,
        ["tu154/custom/svs/true_airspeed"] = 720,
        [diss_prefix .. "diss_groundspeed"] = 450,
        [diss_prefix .. "diss_slip_angle"] = 8,
        [diss_prefix .. "diss_wind_spd"] = 34,
        [diss_prefix .. "diss_wind_course"] = 21,
        [diss_prefix .. "diss_mode"] = 2,
    }
    local writes = {}
    local env = sasl_component(sasl .. "main_panel/diss/diss_logic.lua", values, writes)
    local rt = { values = values, writes = writes, env = env }
    function rt:tick(time) if time then values[diss_time] = time end; env.update() end
    function rt:get(name) return values[diss_prefix .. name] end
    return rt
end

-- The actual DISS producer owns both calculation and the 180-second publication hold.
do
    local rt = diss_runtime()
    rt:tick(1000)
    equal(rt:get("diss_cc"), 1, "DISS power/current is published while warming")
    local held = { diss_groundspeed = 450, diss_slip_angle = 8, diss_wind_spd = 34, diss_wind_course = 21 }
    for _, t in ipairs({ 1000.01, 1001, 1050, 1179, 1179.999 }) do
        rt:tick(t)
        equal(rt:get("diss_mode"), 0, "DISS stays unavailable before 180 seconds")
        for name, value in pairs(held) do near(rt:get(name), value, "DISS preserves initial warm-up snapshot: " .. name) end
    end
    rt:tick(1180)
    equal(rt:get("diss_mode"), 3, "Warm-up release publishes actual default mode, not forced auto mode")
    near(rt:get("diss_groundspeed"), 709.9992, "DISS default groundspeed remains unchanged")
    near(rt:get("diss_slip_angle"), 0, "DISS default drift remains unchanged")
    rt:tick(1500)
    equal(rt:get("diss_mode"), 3, "DISS does not restart warm-up while continuously powered")
    rt.values[diss_switch] = 0; rt:tick(1501)
    equal(rt:get("diss_cc"), 0, "DISS power-off resets current")
    equal(rt:get("diss_mode"), 0, "DISS power-off clears mode")
    near(rt:get("diss_groundspeed"), 0, "DISS power-off clears groundspeed as before")
    rt.values[diss_switch] = 1; rt:tick(1600)
    rt:tick(1779.999)
    equal(rt:get("diss_mode"), 0, "Repowered DISS needs a fresh 180-second warm-up")
    near(rt:get("diss_groundspeed"), 0, "Repowered DISS holds its new zero-speed snapshot")
    rt:tick(1780)
    equal(rt:get("diss_mode"), 3, "Repowered DISS releases after 180 seconds")
end

do
    local rt = diss_runtime()
    rt.values[nvu_switch] = 0
    rt.values[diss_prefix .. "diss_wind_spd"] = 0
    rt.values[diss_prefix .. "diss_wind_course"] = 0
    rt:tick(1000); rt:tick(1180)
    equal(rt:get("diss_mode"), 2, "Manual mode survives warm-up release")
    near(rt:get("diss_groundspeed"), 720, "Manual wind-free GS equals TAS")
    near(rt:get("diss_slip_angle"), 0, "Manual wind-free drift is zero")
end

do
    local rt = diss_runtime()
    rt.values[nvu_switch] = 1
    rt.values["sim/flightmodel/position/groundspeed"] = 200
    rt:tick(1000)
    for frame = 1, 110 do rt:tick(1000 + frame * 0.02) end
    equal(rt:get("diss_mode"), 0, "Auto latch cannot bypass warm-up")
    rt:tick(1180)
    equal(rt:get("diss_mode"), 1, "Valid automatic DISS releases in auto mode")
    near(rt:get("diss_groundspeed"), 720, "Automatic DISS measured GS is preserved")
end

do
    local rt = diss_runtime(1)
    for _, t in ipairs({ 1000, 1001, 1179, 1180, 2000 }) do rt:tick(t) end
    rt.values[diss_switch] = 0; rt:tick(2001)
    rt.values[diss_switch] = 1; rt:tick(2002)
    for _, name in ipairs(diss_outputs) do
        equal(rt.writes[diss_prefix .. name] or 0, 0, "Slave never clobbers synchronized DISS output: " .. name)
    end
    near(rt:get("diss_groundspeed"), 450, "Slave synchronized groundspeed is preserved")
    near(rt:get("diss_mode"), 2, "Slave synchronized mode is preserved")
end

-- Private warm-up state follows local power on both peers; publication stays master-only.
do
    local rt = diss_runtime(1)
    rt:tick(1000); rt:tick(1179.999); rt:tick(1180)
    for _, name in ipairs(diss_outputs) do
        equal(rt.writes[diss_prefix .. name] or 0, 0, "Slave warm-up tracking never writes: " .. name)
    end
    rt.values["scp/api/ismaster"] = 2
    rt:tick(1180.01)
    equal(rt:get("diss_mode"), 3, "Slave-to-master handover does not restart completed local warm-up")
    near(rt:get("diss_groundspeed"), 709.9992, "New master immediately publishes available default GS")
end

do
    local rt = diss_runtime(2)
    rt:tick(1000); rt:tick(1180)
    equal(rt:get("diss_mode"), 3, "Initial master warm-up completes")
    rt.values["scp/api/ismaster"] = 1
    local before = {}
    for _, name in ipairs(diss_outputs) do before[name] = rt.writes[diss_prefix .. name] or 0 end
    rt.values[diss_switch] = 0; rt:tick(1200)
    -- Emulate the remote master's synchronized measurements after its power cycle.
    rt.values[diss_prefix .. "diss_groundspeed"] = 123
    rt.values[diss_prefix .. "diss_slip_angle"] = 4
    rt.values[diss_prefix .. "diss_wind_spd"] = 5
    rt.values[diss_prefix .. "diss_wind_course"] = 6
    rt.values[diss_prefix .. "diss_mode"] = 0
    rt.values[diss_switch] = 1; rt:tick(1250); rt:tick(1300)
    for _, name in ipairs(diss_outputs) do
        equal(rt.writes[diss_prefix .. name] or 0, before[name], "Power cycle while slave remains read-only: " .. name)
    end
    rt.values["scp/api/ismaster"] = 2; rt:tick(1300.01)
    equal(rt:get("diss_mode"), 0, "Master-to-slave power cycle clears previous completed warm-up")
    near(rt:get("diss_groundspeed"), 123, "Handover retains the repower snapshot, not stale ready GS")
    rt:tick(1429.999)
    equal(rt:get("diss_mode"), 0, "New master waits for only the remaining local warm-up duration")
    rt:tick(1430)
    equal(rt:get("diss_mode"), 3, "Repowered peer becomes ready at its original power-up plus180 seconds")
    near(rt:get("diss_groundspeed"), 709.9992, "Repowered handover restores normal default GS")
end

print(string.format("PASS: %d offline assertions; actual classic-main bootstrap, original USVP baseline and DISS producer", checks))
print("Native scheduling, real SmartCopilot peers and visual X-Plane behavior are not proven by these mocks.")
