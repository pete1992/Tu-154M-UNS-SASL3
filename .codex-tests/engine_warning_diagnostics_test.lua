-- Offline actual-module regression: diagnose warning sources without changing lamp logic.
-- No simulator connection, actual audio playback, or native DataRef writes.
local root = assert(arg[1], "Provide the aircraft directory")
local module_path = root .. "/plugins/sasl/data/modules/Custom Module/engines_system/engines_panel.lua"
local scenarios, assertions = 0, 0
local function eq(actual, expected, label)
    assert(actual == expected, label .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
    assertions = assertions + 1
end

local function controller()
    local values, bindings, messages = {}, {}, {}
    local env = setmetatable({}, {__index = _G})
    env.globalProperty = function(path) return path end
    env.globalPropertyi, env.globalPropertyf = env.globalProperty, env.globalProperty
    env.defineProperty = function(name, property) env[name] = property; bindings[name] = property end
    env.get = function(property) return values[assert(property, "nil DataRef read")] or 0 end
    env.set = function(property, value)
        assert(property:sub(1, 4) ~= "sim/", "Unexpected native write: " .. property)
        values[property] = value
    end
    env.bool2int = function(value) return value and 1 or 0 end
    local function capture(message)
        if tostring(message):find("[Engine warning]", 1, true) then messages[#messages + 1] = tostring(message) end
    end
    env.logInfo = capture
    env.sasl = {logInfo = capture, al = {
        loadSample = function(path) return path end,
        playSample = function() end,
    }}
    local chunk
    if setfenv then chunk = assert(loadfile(module_path)); setfenv(chunk, env)
    else chunk = assert(loadfile(module_path, "t", env)) end
    chunk()
    local r = {values = values, bindings = bindings, messages = messages}
    function r:set(name, value) values[assert(bindings[name], name)] = value end
    function r:get(name) return values[assert(bindings[name], name)] or 0 end
    function r:update(count) for _ = 1, count or 1 do env.update() end end
    function r:clear_logs() for i = #messages, 1, -1 do messages[i] = nil end end
    function r:engine_logs(engine)
        local result = {}
        for _, message in ipairs(messages) do
            if tonumber(message:match("engine=(%d+)")) == engine then result[#result + 1] = message end
        end
        return result
    end
    function r:causes(engine)
        local logs = self:engine_logs(engine)
        return logs[#logs] and logs[#logs]:match("causes=([^ ]+)")
    end
    function r:forward(expected, label)
        for i = 1, 3 do eq(self:get("fp_eng_fail_" .. i), expected[i], label .. " engine " .. i) end
    end
    r:set("frame_time", 0.1)
    r:set("bus27_volt_left", 28.5); r:set("bus27_volt_right", 28.5)
    r:set("fire_main_switch", 1); r:set("tank1_w", 5000)
    for i = 1, 3 do
        r:set("rpm_high_" .. i, 60); r:set("eng" .. i .. "_N1", 50)
        r:set("oil_p_" .. i, 50); r:set("vibra_" .. i, 20)
        r:set("eng_fuel_press_" .. i, 1); r:set("egt_" .. i, 600)
        r:set("oil_qty_" .. i, 15); r:set("gauges_on_" .. i, 1)
    end
    r:update(4); r.initial_log_count = #messages; r:clear_logs()
    return r
end

local function test(name, callback)
    callback(controller()); scenarios = scenarios + 1; print("PASS " .. name)
end

for _, rpm in ipairs({0, 40, 60, 75, 100}) do
    test("healthy RPM " .. rpm .. " never triggers forward warning", function(r)
        eq(r.initial_log_count, 0, "initial healthy state is silent")
        for i = 1, 3 do r:set("rpm_high_" .. i, rpm) end
        r:update(10); r:forward({0, 0, 0}, "healthy sensors")
        eq(#r.messages, 0, "RPM change alone does not change warning causes")
        for i = 1, 3 do
            eq(r:get("eng" .. i .. "_vna33"), rpm < 74 and 1 or 0, "normal VNA33 indication")
            eq(r:get("eng" .. i .. "_vna0"), rpm < 91 and 1 or 0, "normal VNA0 indication")
        end
        eq(r:get("eng1_bypass_valve"), rpm > 12 and rpm < 73 and 1 or 0, "engine1 normal bypass")
        eq(r:get("eng2_bypass_valve"), rpm > 13 and rpm < 78 and 1 or 0, "engine2 normal bypass")
        eq(r:get("eng3_bypass_valve"), rpm > 12.5 and rpm < 75 and 1 or 0, "engine3 normal bypass")
    end)
end

local faults = {
    {prefix = "oil_p_", value = 9, restore = 50, cause = "OIL_PRESSURE"},
    {prefix = "vibra_", value = 56, restore = 20, cause = "VIBRATION"},
    {prefix = "chip_detect", value = 1, restore = 0, cause = "CHIPS"},
    {prefix = "eng_fuel_press_", value = 0, restore = 1, cause = "FUEL_PRESSURE"},
    {prefix = "sim_engine_on_fire", value = 6, restore = 0, cause = "FIRE"},
    {prefix = "egt_", value = 711, restore = 600, cause = "EGT"},
}
for engine = 1, 3 do
    for _, fault in ipairs(faults) do
        test("engine " .. engine .. " isolated " .. fault.cause, function(r)
            r:set(fault.prefix .. engine, fault.value); r:update()
            local expected = {0, 0, 0}; expected[engine] = 1
            r:forward(expected, "isolated alarm source")
            eq(#r.messages, 1, "only changed engine logged")
            eq(r:causes(engine), fault.cause, "exact cause token")
            local message = r.messages[1]
            for _, field in ipairs({"rpm", "oil_psi", "fuel_pressure", "vibration", "chips", "fire", "egt_C", "reverse"}) do
                assert(message:match(field .. "=[^ ]+"), "Missing diagnostic field " .. field)
                assertions = assertions + 1
            end
            eq(tonumber(message:match("rpm=([%d%.]+)")), 60, "measured RPM included")
            r:update(100)
            eq(#r.messages, 1, "unchanged cause not logged every frame")
            r:set(fault.prefix .. engine, fault.restore); r:update()
            r:forward({0, 0, 0}, "source cleared")
            eq(r:causes(engine), "CLEAR", "clear transition logged")
            eq(#r.messages, 2, "one fault and one clear event")
        end)
    end
end

test("strict source thresholds are unchanged", function(r)
    local boundaries = {
        {"oil_p_1", 10, 9.999, 50},
        {"vibra_1", 55, 55.001, 20},
        {"egt_1", 710, 710.001, 600},
        {"chip_detect1", 0.9, 1, 0},
        {"eng_fuel_press_1", 0.001, 0, 1},
        {"sim_engine_on_fire1", 5, 6, 0},
    }
    for _, item in ipairs(boundaries) do
        r:set(item[1], item[2]); r:update()
        eq(r:get("fp_eng_fail_1"), 0, "boundary remains non-warning " .. item[1])
        r:set(item[1], item[3]); r:update()
        eq(r:get("fp_eng_fail_1"), 1, "just beyond boundary warns " .. item[1])
        r:set(item[1], item[4]); r:update()
    end
    r:set("sim_engine_on_fire1", 6); r:set("fire_main_switch", 0); r:update()
    eq(r:get("fp_eng_fail_1"), 0, "fire warning still follows existing main switch product")
end)

test("cause changes remain visible while aggregate warning stays ON", function(r)
    r:set("oil_p_1", 9); r:update()
    eq(r:causes(1), "OIL_PRESSURE", "first cause")
    r:set("vibra_1", 56); r:update()
    eq(r:causes(1), "OIL_PRESSURE,VIBRATION", "additional simultaneous cause")
    eq(r:get("fp_eng_fail_1"), 1, "aggregate lamp remains ON")
    r:set("oil_p_1", 50); r:update()
    eq(r:causes(1), "VIBRATION", "remaining cause")
    eq(#r.messages, 3, "cause list changes logged despite unchanged lamp")
    r:set("vibra_1", 60); r:set("rpm_high_1", 45); r:update(20)
    eq(#r.messages, 3, "values changing within same cause do not spam log")
    r:set("vibra_1", 20); r:update()
    eq(r:causes(1), "CLEAR", "last cause cleared")
end)

test("front lamp test, day-night and bus brightness remain unchanged", function(r)
    r:set("lamp_test_fwd", 1); r:update()
    r:forward({1, 1, 1}, "lamp test")
    eq(#r.messages, 0, "lamp test does not invent raw warning causes")
    r:set("day_night_set", 1); r:update()
    r:forward({1, 1, 1}, "lamp test overrides night dimming")
    r:set("lamp_test_fwd", 0); r:set("oil_p_1", 9); r:set("oil_p_2", 9); r:set("oil_p_3", 9); r:update()
    r:forward({0.75, 0.75, 0.75}, "normal night dimming")
    r:set("bus27_volt_left", 0); r:update()
    r:forward({0, 0.75, 0.75}, "left warning lamp follows left bus")
    r:set("bus27_volt_right", 0); r:update()
    r:forward({0, 0, 0}, "all lamps dark without buses")
    eq(#r.messages, 3, "brightness changes do not change raw cause logs")
end)

for _, spec in ipairs({{engine = 1, ref = "revers_flap_L"}, {engine = 3, ref = "revers_flap_R"}}) do
    test("engine " .. spec.engine .. " closing reverser condition preserved", function(r)
        r:set(spec.ref, 1); r:update()
        eq(r:get("fp_eng_fail_" .. spec.engine), 0, "deployment alone is not malfunction source")
        r:set(spec.ref, 0.94); r:update()
        eq(r:get("fp_eng_fail_" .. spec.engine), 1, "closing within original interval warns")
        eq(r:causes(spec.engine), "REVERSER", "closing reverser cause")
        r:update()
        eq(r:get("fp_eng_fail_" .. spec.engine), 0, "stationary reverser clears moving condition")
        eq(r:causes(spec.engine), "CLEAR", "stationary clears diagnostic")
        r:set(spec.ref, 1); r:update(); r:set(spec.ref, 0.95); r:update()
        eq(r:get("fp_eng_fail_" .. spec.engine), 0, "upper interval boundary excluded")
        r:set(spec.ref, 0.05); r:update()
        eq(r:get("fp_eng_fail_" .. spec.engine), 0, "lower interval boundary excluded")
        r:set(spec.ref, 0); r:update()
        eq(r:get("fp_eng_fail_" .. spec.engine), 0, "fully stowed is clear")
    end)
end

print("PASS engine warning diagnostics: " .. scenarios .. " scenarios, " .. assertions .. " assertions; simulated inputs, unchanged alarm rules")
