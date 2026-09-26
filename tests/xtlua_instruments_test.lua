-- xtlua_instruments_test.lua
-- Offline regression tests: real installed Lua bootstraps, mocked native APIs.
-- Run from the aircraft root with LuaJIT, or pass that root as the first argument.
-- This does not exercise the native scheduler, SDK, SmartCopilot or cockpit draw.

local root = (arg[1] or "."):gsub("\\", "/"):gsub("/$", "")
local sasl = root .. "/plugins/sasl/data/modules/Custom Module/"
local clock_source = root .. "/plugins/xtlua/scripts/T154.clock24/T154.clock24.lua"
local thermo_source = root .. "/plugins/xtlua/init/scripts/T154.termo/T154.termo.lua"
local checks = 0

local function check(condition, message)
    checks = checks + 1
    assert(condition, message)
end

local function equal(actual, expected, message)
    check(actual == expected, message .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local function near(actual, expected, message)
    check(type(actual) == "number" and math.abs(actual - expected) <= 1e-10,
        message .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local function read(path)
    local file = assert(io.open(path, "rb"))
    local text = file:read("*a")
    file:close()
    return text
end

local function run_file(path, env)
    local chunk = assert(loadfile(path))
    setfenv(chunk, env)
    return chunk()
end

local function copy_math(random, randomseed)
    local result = {}
    for key, value in pairs(math) do result[key] = value end
    result.random = random
    result.randomseed = randomseed or function() end
    return result
end

local clock_refs = {
    { "utc_time", "sim/time/zulu_time_sec", 0 },
    { "clock_24_hours", "tu154/custom/gauges/clock_24_hours", 0 },
    { "clock_24_mins", "tu154/custom/gauges/clock_24_mins", 0 },
    { "clock_24_red", "tu154/custom/gauges/clock_24_red", 0 },
}
local thermo_refs = {
    { "thermo", "sim/cockpit2/temperature/outside_air_temp_degc", 15 },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", 27 },
    { "sim_frame_period", "sim/operation/misc/frame_rate_period", 1 / 60 },
    { "sim_paused", "sim/time/paused", 0 },
    { "thermo_outside", "tu154/custom/gauges/misc/thermo_outside", 0 },
}

local function runtime(kind, definitions, missing)
    local rt = { refs = {}, writes = {}, write_count = 0, random_count = 0, seed_count = 0, timers = {} }
    for index, def in ipairs(definitions) do
        rt.refs[def[2]] = {
            path = def[2], value = def[3], type = (missing == "all" or missing == index) and "none" or "number",
        }
    end
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.math = copy_math(function(limit)
        equal(limit, 360, "Red-hand random range")
        equal(rt.seed_count, 1, "Clock RNG is seeded before its first draw")
        rt.random_count = rt.random_count + 1
        return 137
    end, function(seed)
        equal(seed, 123456789, "Clock seed uses wall-clock time as original SASL host did")
        rt.seed_count = rt.seed_count + 1
    end)
    env.os = setmetatable({ time = function() return 123456789 end }, { __index = os })
    -- The actual worker bootstrap configures JIT limits; avoid changing this test process.
    env.jit = { opt = { start = function() end } }
    local prefix = kind == "worker" and "XTLua" or "XLua"
    env[prefix .. "FindDataRef"] = function(path)
        return assert(rt.refs[path], "Unexpected DataRef: " .. path)
    end
    env[prefix .. "GetDataRefType"] = function(handle) return handle.type end
    env[prefix .. "GetNumber"] = function(handle)
        check(handle.type == "number", "Never read unresolved native number: " .. handle.path)
        return handle.value
    end
    env[prefix .. "SetNumber"] = function(handle, value)
        check(handle.type == "number", "Never write unresolved native number: " .. handle.path)
        handle.value = value
        rt.write_count = rt.write_count + 1
        rt.writes[handle.path] = (rt.writes[handle.path] or 0) + 1
    end
    env[prefix .. "CreateTimer"] = function(callback)
        local timer = { callback = callback }
        rt.timers[#rt.timers + 1] = timer
        return timer
    end
    env[prefix .. "RunTimer"] = function(timer, delay, interval)
        timer.delay, timer.interval = delay, interval
    end
    local bootstrap = kind == "worker" and "/plugins/xtlua/init.lua" or "/plugins/xtlua/init/init.lua"
    run_file(root .. bootstrap, env)
    env.run_module_in_namespace(assert(loadfile(kind == "worker" and clock_source or thermo_source)))
    rt.bootstrap, rt.module = env, env.n
    equal(rt.seed_count, kind == "worker" and 1 or 0, "Only clock seeds once at module load")
    for _, def in ipairs(definitions) do
        check(rawget(env, def[1]) == nil, "Binding must not leak into bootstrap _G: " .. def[1])
        check(rawget(rt.module, "functions")[def[1]] ~= nil, "Binding must be a namespace property: " .. def[1])
    end
    equal(rt.write_count, 0, "Module load must not write DataRefs")
    function rt:set(name, value)
        for _, def in ipairs(definitions) do
            if def[1] == name then self.refs[def[2]].value = value; return end
        end
        error("Unknown binding " .. name)
    end
    function rt:get(name)
        for _, def in ipairs(definitions) do
            if def[1] == name then return self.refs[def[2]].value end
        end
        error("Unknown binding " .. name)
    end
    function rt:tick()
        if kind == "worker" then
            self.bootstrap.do_callout("after_physics")
        else
            -- Native source separately verifies one callback per main pre-frame,
            -- including pause/replay. Here we test its registered callback only.
            for _, timer in ipairs(self.timers) do
                check(timer.delay == 0 and timer.interval == 0, "Thermo uses one zero-interval main timer")
                timer.callback()
            end
        end
    end
    return rt
end

local function original_component(path, shared)
    local env = setmetatable({}, { __index = _G })
    env.math = copy_math(function(limit) equal(limit, 360, "Original red-hand random range"); return 137 end)
    env.globalPropertyf = function(name) return name end
    env.globalPropertyi = env.globalPropertyf
    env.defineProperty = function(name, property) env[name] = property end
    env.get = function(property) return assert(shared[property], "Missing SASL input " .. property) end
    env.set = function(property, value) shared[property] = value end
    run_file(path, env)
    return env
end

-- Preserve exact recovery copies and disable the two former SASL writers.
for _, name in ipairs({ "clock24.lua", "termo.lua" }) do
    equal(read(sasl .. "main_panel/" .. name), read(sasl .. "main_panel/" .. name .. ".bak"), name .. " backup is byte-identical")
end
local host = read(sasl .. "main_panel/main_panel.lua")
for _, name in ipairs({ "clock24", "termo" }) do
    local active = false
    for line in host:gmatch("[^\r\n]+") do
        if line:match("^%s*" .. name .. "%s*{") then active = true end
    end
    check(not active, name .. " former SASL writer is not instantiated")
    check(host:match("%-%-%s*" .. name .. "%s*{") ~= nil, name .. " cutover is explicitly reversible")
end

-- Every required DataRef must resolve before any output or random initialization.
for _, definition in ipairs({ { "worker", clock_refs }, { "main", thermo_refs } }) do
    local kind, refs = definition[1], definition[2]
    for missing = 1, #refs do
        local rt = runtime(kind, refs, missing)
        for _ = 1, 3 do rt:tick() end
        equal(rt.write_count, 0, kind .. " unresolved input/output blocks all writes")
        equal(rt.random_count, 0, kind .. " unresolved input/output does not consume random initialization")
        rt.refs[refs[missing][2]].type = "number"
        rt:tick()
        equal(rt.write_count, kind == "worker" and 3 or 1, kind .. " recovers after late DataRef registration")
        if kind == "worker" then equal(rt.random_count, 1, "Late clock initialization runs exactly once") end
    end
    local rt = runtime(kind, refs, "all")
    rt:tick()
    for index, def in ipairs(refs) do
        rt.refs[def[2]].type = "number"
        rt:tick()
        if index < #refs then equal(rt.write_count, 0, kind .. " waits for all DataRefs") end
    end
    equal(rt.write_count, kind == "worker" and 3 or 1, kind .. " starts only when all DataRefs exist")
    local before = rt.write_count
    rt.refs[refs[#refs][2]].type = "none"
    rt:tick()
    equal(rt.write_count, before, kind .. " stops writing if a DataRef becomes unavailable")
end

-- Original clock parity, UTC scrubbing, invalid input and synchronized red hand.
do
    local rt = runtime("worker", clock_refs)
    local values = {}
    for _, def in ipairs(clock_refs) do values[def[2]] = def[3] end
    local old = original_component(sasl .. "main_panel/clock24.lua.bak", values)
    for _, utc in ipairs({ 0, 1, 3599, 3600, 43200, 86399, 0, 70000, 123.456, 86400, -1 }) do
        rt:set("utc_time", utc)
        values[clock_refs[1][2]] = utc
        rt:tick(); old.update()
        near(rt:get("clock_24_mins"), values[clock_refs[3][2]], "Minute-hand formula parity")
        near(rt:get("clock_24_hours"), values[clock_refs[2][2]], "Hour-hand formula parity")
    end
    equal(rt.random_count, 1, "Clock random initialization is one-shot")
    equal(rt.writes[clock_refs[4][2]], 1, "Red hand is written only once")
    rt:set("clock_24_red", 307)
    rt.bootstrap.do_callout("flight_start")
    rt.bootstrap.setup_callback_var("SIM_PERIOD", 999)
    rt:set("utc_time", 12345)
    rt:tick(); rt:tick()
    equal(rt:get("clock_24_red"), 307, "External/SmartCopilot red hand survives callbacks and new flight")
    equal(rt.random_count, 1, "Flight start does not reinitialize red hand")
    equal(rt.seed_count, 1, "Flight start does not reseed the clock RNG")
    local count = rt.write_count
    for _, invalid in ipairs({ 0 / 0, math.huge, -math.huge }) do rt:set("utc_time", invalid); rt:tick() end
    equal(rt.write_count, count, "Invalid UTC cannot poison outputs")
    local late = runtime("worker", clock_refs)
    late:set("utc_time", 0 / 0); late:tick()
    equal(late.random_count, 0, "Invalid initial UTC does not consume initialization")
    late:set("utc_time", 0); late:tick()
    equal(late.random_count, 1, "Clock starts after valid UTC arrives")
end

-- Execute both original SASL files as the baseline rather than retyping equations.
local function thermo_pair()
    local rt = runtime("main", thermo_refs)
    equal(#rt.timers, 1, "Exactly one thermo timer is registered")
    check(rt.module.after_physics == nil, "No duplicate physics integration callback")
    check(rt.module.after_replay == nil, "No duplicate replay integration callback")
    local values = { ["tu154/custom/time/frame_time"] = 0.1 }
    for _, def in ipairs(thermo_refs) do values[def[2]] = def[3] end
    local time = original_component(sasl .. "time_logic.lua", values)
    local old = original_component(sasl .. "main_panel/termo.lua.bak", values)
    local function step(dt, temperature, voltage, paused, replay)
        rt:set("sim_frame_period", dt); values[thermo_refs[3][2]] = dt
        rt:set("thermo", temperature); values[thermo_refs[1][2]] = temperature
        rt:set("bus27_volt_right", voltage); values[thermo_refs[2][2]] = voltage
        rt:set("sim_paused", paused or 0); values[thermo_refs[4][2]] = paused or 0
        rt.bootstrap.setup_callback_var("SIM_PERIOD", 987)
        rt.bootstrap.setup_callback_var("IN_REPLAY", replay or 0)
        time.update(); old.update(); rt:tick()
        near(rt:get("thermo_outside"), values[thermo_refs[5][2]], "Thermo matches original SASL integration")
        return rt:get("thermo_outside")
    end
    return rt, step
end

for _, fps in ipairs({ 20, 30, 60, 120 }) do
    local rt, step = thermo_pair()
    for frame = 1, fps * 4 do
        local temperature = frame <= fps and 15 or (frame <= 2 * fps and 170 or -90)
        local voltage = frame <= 3 * fps and 27 or 0
        step(1 / fps, temperature, voltage, 0, frame > fps and 1 or 0)
    end
    equal(rt.random_count, 0, "Thermo does not use random state")
end

do
    local rt, step = thermo_pair()
    near(step(0.1, 15, 13), -55, "Exactly 13 V remains unpowered")
    near(step(0.1, 15, 12.99), -55, "Below 13 V remains unpowered")
    near(step(0.1, 15, 13.01), -20, "Above 13 V powers thermometer")
    step(0.1, 115, 27); step(0.1, 116, 27); step(0.1, -55, 27); step(0.1, -56, 27)
    step(0.5, 20, 27); step(9, 20, 27)
    local held = rt:get("thermo_outside")
    for _, dt in ipairs({ 0, -0.2, 0 / 0, math.huge, -math.huge }) do
        near(step(dt, 100, 27), held, "Invalid/zero frame duration holds state")
    end
    near(step(0.1, 100, 27, 1, 0), held, "Paused flight holds state")
    near(step(0.1, 100, 27, 1, 1), held, "Paused replay holds state")
    check(step(0.1, 100, 27, 0, 1) > held, "Unpaused replay still updates via timer")
    held = rt:get("thermo_outside")
    rt.bootstrap.do_callout("flight_start")
    near(step(0, 20, 27), held, "New flight does not reset original persistent needle state")
    local before = rt.write_count
    rt:set("thermo", 0 / 0); rt:tick()
    equal(rt.write_count, before, "Invalid OAT is rejected without poisoning state")
    near(rt:get("thermo_outside"), held, "Needle holds on invalid OAT")
    step(0.1, 10, 27)
end

print(string.format("PASS: %d offline assertions; installed bootstraps + mocked native APIs + original SASL baselines", checks))
print("Native scheduling, cross-plugin load order and visual cockpit behavior still require X-Plane testing.")
