-- Offline SASL property mock: probe TEST indications and probe failure ownership.
-- Run from the aircraft directory with Lua 5.1 or the available Fengari CLI.
local base = "plugins/sasl/data/modules/Custom Module/antiice/"
local checks = 0

local function equal(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function component(file)
    local values, writes, definitions = {}, {}, {}
    local env = setmetatable({}, { __index = _G })
    env.math = setmetatable({}, { __index = math })
    env.random_value = 0.5
    env.math.random = function(minimum)
        if minimum then return 15 end
        return env.random_value
    end
    env.globalProperty = function(path) return path end
    env.globalPropertyi = env.globalProperty
    env.globalPropertyf = env.globalProperty
    env.defineProperty = function(name, property)
        assert(definitions[name] == nil, "Duplicate binding " .. name)
        definitions[name] = property
        env[name] = property
        values[property] = 0
    end
    env.get = function(property)
        assert(property ~= nil, "Missing property passed to get")
        assert(values[property] ~= nil, "Unbound property " .. property)
        return values[property]
    end
    env.set = function(property, value)
        assert(property ~= nil and values[property] ~= nil, "Unbound property passed to set")
        values[property] = value
        writes[property] = (writes[property] or 0) + 1
    end
    env.bool2int = function(value) return value and 1 or 0 end
    -- Preserve the original RPM-based test setup behind the shared start-mode guard.
    env.isColdAndDarkStart = function() return true end
    env.sasl = { al = {
        loadSample = function(path) return path end,
        playSample = function() end,
    } }
    local chunk
    if setfenv then
        chunk = assert(loadfile(base .. file))
        setfenv(chunk, env)
    else
        chunk = assert(loadfile(base .. file, "t", env))
    end
    chunk()
    function env.input(name, value)
        assert(definitions[name], "Missing input " .. name)
        values[definitions[name]] = value
    end
    function env.value(name) return values[assert(definitions[name])] end
    function env.tick(dt)
        env.input("frame_time", dt or 1)
        env.update()
    end
    env.writes = writes
    return env
end

local function panel()
    local p = component("antiice_panel.lua")
    p.input("eng1_N1", 30) -- Do not enter the unchanged cold-and-dark reset.
    p.input("bus27_volt_left", 28.5)
    p.input("bus27_volt_right", 28.5)
    for i = 1, 3 do p.input("pitot_heat_" .. i, -1) end
    return p
end

do
    local p = panel()
    p.tick()
    for i = 1, 3 do equal(p.value("heat_ok_" .. i), 1, "Healthy TEST lamp " .. i) end
    p.input("bus27_volt_left", 0)
    p.tick()
    equal(p.value("heat_ok_1"), 0, "Right bus cannot energize PPD 1 test")
    equal(p.value("heat_ok_2"), 1, "PPD 2 uses right bus")
    equal(p.value("heat_ok_3"), 1, "PPD 3 uses right bus")
    p.input("bus27_volt_left", 28.5)
    p.input("bus27_volt_right", 0)
    p.tick()
    equal(p.value("heat_ok_1"), 1, "PPD 1 uses left bus")
    equal(p.value("heat_ok_2"), 0, "Left bus cannot energize PPD 2 test")
    equal(p.value("heat_ok_3"), 0, "Left bus cannot energize PPD 3 test")
    for _, voltage in ipairs({ 0, 10, 12.99, 13 }) do
        p.input("bus27_volt_left", voltage)
        p.input("bus27_volt_right", voltage)
        p.tick()
        for i = 1, 3 do equal(p.value("heat_ok_" .. i), 0, "Probe voltage threshold " .. i) end
    end
    p.input("bus27_volt_left", 27)
    p.input("bus27_volt_right", 20)
    p.tick()
    equal(p.value("heat_ok_1"), 17 / 18.5, "PPD 1 own-bus dimming")
    equal(p.value("heat_ok_2"), 10 / 18.5, "PPD 2 own-bus dimming")
    equal(p.value("heat_ok_3"), 10 / 18.5, "PPD 3 own-bus dimming")
end

do
    local p = panel()
    for _, position in ipairs({ 0, 1 }) do
        for i = 1, 3 do p.input("pitot_heat_" .. i, position) end
        p.tick()
        for i = 1, 3 do equal(p.value("heat_ok_" .. i), 0, "Only TEST lights the diagnostic lamp") end
    end
    for i = 1, 3 do p.input("pitot_heat_" .. i, -1) end
    p.input("rel_ice_pitot_heat1", 6)
    p.input("rel_ice_pitot_heat2", 6)
    p.input("rel_ice_pitot_heat_stby", 6)
    p.tick()
    for i = 1, 3 do equal(p.value("heat_ok_" .. i), 0, "Native failed probe cannot test healthy") end
    p.input("rel_ice_pitot_heat_stby", 0)
    for _, failure in ipairs({ 1, 6 }) do
        p.input("ppd_3_heat_fail", failure)
        p.tick()
        equal(p.value("heat_ok_3"), 0, "Custom PPD 3 failure, including legacy 6")
    end
    p.input("ppd_3_heat_fail", 0)
    p.tick()
    equal(p.value("heat_ok_3"), 1, "Repaired PPD 3 can test healthy")
    for enum = 1, 5 do
        p.input("rel_ice_pitot_heat1", enum)
        p.tick()
        equal(p.value("heat_ok_1"), 1, "Scheduled failure is not an already failed heater")
    end
end

local function failures()
    local f = component("antiice_fails.lua")
    f.input("failures_enabled", 1)
    f.input("bus27_volt_left", 28.5)
    f.input("bus27_volt_right", 28.5)
    f.input("deflection_mtr_2", 0.05)
    f.input("deflection_mtr_3", 0.05)
    for i = 1, 3 do f.input("pitot_heat_" .. i, 1) end
    return f
end

local function healthy_probes(f, label)
    equal(f.value("rel_ice_pitot_heat1"), 0, label .. " PPD 1")
    equal(f.value("rel_ice_pitot_heat2"), 0, label .. " PPD 2")
    equal(f.value("ppd_3_heat_fail"), 0, label .. " PPD 3")
end

do
    local f = failures()
    f.input("rel_ice_pitot_heat1", 6)
    f.input("rel_ice_pitot_heat2", 6)
    f.input("ppd_3_heat_fail", 1)
    f.input("rel_ice_pitot_heat_stby", 6)
    f.tick(20)
    equal(f.value("rel_ice_pitot_heat1"), 6, "Native PPD 1 failure stays latched")
    equal(f.value("rel_ice_pitot_heat2"), 6, "Native PPD 2 failure stays latched")
    equal(f.value("ppd_3_heat_fail"), 1, "Custom PPD 3 failure stays latched")
    equal(f.value("rel_ice_pitot_heat_stby"), 6, "External standby failure stays latched")
    equal(f.writes[f.rel_ice_pitot_heat_stby], nil, "Native standby failure is not owned here")
    for enum = 1, 5 do
        f.input("rel_ice_pitot_heat1", enum)
        f.input("rel_ice_pitot_heat2", enum)
        f.tick(20)
        equal(f.value("rel_ice_pitot_heat1"), enum, "Preserve scheduled PPD 1 failure")
        equal(f.value("rel_ice_pitot_heat2"), enum, "Preserve scheduled PPD 2 failure")
    end
    f.input("ppd_3_heat_fail", 6)
    f.tick(20)
    equal(f.value("ppd_3_heat_fail"), 6, "Do not turn legacy custom failure into a repair")
end

-- 0.001 is above the ordinary failure probability but below heat-soak failure
-- probability at difficulty 1. This isolates the existing 20-minute threshold.
for _, position in ipairs({ -1, 0 }) do
    local f = failures()
    f.random_value = 0.001
    for i = 1, 3 do f.input("pitot_heat_" .. i, position) end
    for _ = 1, 100 do f.tick(20) end
    healthy_probes(f, "OFF/TEST never accumulates heat exposure")
end

do
    local f = failures()
    f.random_value = 0.001
    f.input("deflection_mtr_2", 0)
    f.input("deflection_mtr_3", 0)
    for _ = 1, 100 do f.tick(20) end
    healthy_probes(f, "Normal airborne probe use does not cause heat-soak failure")
end

for _, voltage in ipairs({ 0, 13 }) do
    local f = failures()
    f.random_value = 0.001
    f.input("bus27_volt_left", voltage)
    f.input("bus27_volt_right", voltage)
    for _ = 1, 100 do f.tick(20) end
    healthy_probes(f, "Unpowered probes do not overheat")
end

do
    local f = failures()
    f.random_value = 0.001
    for _ = 1, 60 do f.tick(20) end
    healthy_probes(f, "No heat-soak failure before 20 minutes")
    f.tick(20)
    equal(f.value("rel_ice_pitot_heat1"), 6, "Ground heat soak can fail PPD 1")
    equal(f.value("rel_ice_pitot_heat2"), 6, "Ground heat soak can fail PPD 2")
    equal(f.value("ppd_3_heat_fail"), 1, "Ground heat soak writes custom boolean 1, not native 6")
    f.random_value = 0.5
    f.tick(20)
    equal(f.value("rel_ice_pitot_heat1"), 6, "Failed ground-heated probe stays failed")
    equal(f.value("ppd_3_heat_fail"), 1, "Failed PPD 3 stays failed")
end

for _, reset in ipairs({ "off", "test", "airborne", "power" }) do
    local f = failures()
    for _ = 1, 61 do f.tick(20) end -- Exposure exists, but no failure was drawn.
    if reset == "off" or reset == "test" then
        for i = 1, 3 do f.input("pitot_heat_" .. i, reset == "off" and 0 or -1) end
    elseif reset == "airborne" then
        f.input("deflection_mtr_2", 0)
        f.input("deflection_mtr_3", 0)
    else
        f.input("bus27_volt_left", 0)
        f.input("bus27_volt_right", 0)
    end
    f.random_value = 0.001
    f.tick(20)
    healthy_probes(f, "Reset exposure before same-frame failure check: " .. reset)
end

do
    local f = failures()
    f.random_value = 0.001
    f.input("bus27_volt_left", 0)
    f.input("rel_ice_pitot_heat_stby", 6)
    for _ = 1, 61 do f.tick(20) end
    equal(f.value("rel_ice_pitot_heat1"), 0, "PPD 1 cannot heat through the opposite bus")
    equal(f.value("rel_ice_pitot_heat2"), 6, "Powered PPD 2 can accumulate ground heat")
    equal(f.value("ppd_3_heat_fail"), 0, "Already failed standby circuit cannot heat-soak")
end

do
    local f = failures()
    f.input("ismaster", 1)
    f.random_value = 0
    f.tick(1300)
    healthy_probes(f, "SmartCopilot slave does not generate failures")
    equal(next(f.writes), nil, "SmartCopilot slave writes no failure DataRefs")
    f.input("ismaster", 0)
    f.input("rel_ice_pitot_heat1", 6)
    f.input("rel_ice_pitot_heat2", 6)
    f.input("ppd_3_heat_fail", 1)
    f.input("rel_ice_pitot_heat_stby", 6)
    f.input("failures_enabled", 0)
    f.tick()
    healthy_probes(f, "Existing failures-disabled reset behavior is retained")
    equal(f.value("rel_ice_pitot_heat_stby"), 6, "Do not add standby native reset ownership")
end

print("PASS: " .. checks .. " probe panel/failure assertions (offline mocks; no simulator run)")
