-- Offline regression of the real SASL anti-ice component. No simulator writes.
-- Usage: fengari .codex-tests/window_probe_heat_test.lua <aircraft-directory>
local root = assert(arg[1], "Provide the aircraft directory")
local path = root .. "/plugins/sasl/data/modules/Custom Module/antiice/antiice_logic.lua"
local scenarios, assertions = 0, 0

local function check(condition, message)
    assert(condition, message)
    assertions = assertions + 1
end

local function near(actual, expected, message)
    check(type(actual) == "number" and math.abs(actual - expected) < 1e-8,
        message .. ": " .. tostring(actual) .. " versus " .. tostring(expected))
end

local function controller()
    local values, writes, created = {}, {}, {}
    local e = setmetatable({}, {__index = _G})
    local function bind(name, kind, index)
        return {name = name, kind = kind, index = index,
            key = name .. (index and ("[" .. (index - 1) .. "]") or "")}
    end
    e.globalProperty = function(name) return bind(name, "auto") end
    e.globalPropertyi = function(name) return bind(name, "int") end
    e.globalPropertyf = function(name) return bind(name, "float") end
    e.globalPropertyiae = function(name, index)
        check(index >= 1 and index <= 4, "SASL integer-array accessor is one-based")
        return bind(name, "int-array", index)
    end
    e.globalPropertyfae = function(name, index)
        check(index >= 1 and index <= 4, "SASL float-array accessor is one-based")
        return bind(name, "float-array", index)
    end
    e.createGlobalPropertyf = function(name, default)
        check(name:find("tu154/custom/antiice/window_heat_time_", 1, true) == 1,
            "Only own defrost timing properties are created")
        created[name], values[name] = true, default
        return bind(name, "float")
    end
    e.defineProperty = function(name, property) e[name] = property end
    e.get = function(property) return values[assert(property).key] or 0 end
    e.set = function(property, value)
        assert(property.name:find("sim/flightmodel/failures/window_ice", 1, true) ~= 1,
            "Never clear, reset or inject native windshield ice")
        assert(property.name ~= "sim/flightmodel/failures/ice_delta", "Native ice rate is read-only")
        values[property.key] = value
        writes[property.key] = (writes[property.key] or 0) + 1
    end
    e.bool2int = function(value) return value and 1 or 0 end
    e.clamp = function(value, low, high) return math.max(low, math.min(high, value)) end
    e.math = setmetatable({random = function() return 0.5 end}, {__index = math})
    local chunk
    if setfenv then chunk = assert(loadfile(path)); setfenv(chunk, e)
    else chunk = assert(loadfile(path, "t", e)) end
    chunk()
    local r = {env = e, created = created}
    function r:set(name, value) values[assert(e[name], name).key] = value end
    function r:get(name) return e.get(assert(e[name], name)) end
    function r:writeCount(name) return writes[assert(e[name], name).key] or 0 end
    function r:step(dt, count)
        self:set("frame_time", dt or 0.1)
        for _ = 1, count or 1 do e.update() end
    end
    function r:power(left, right)
        self:set("bus27_volt_left", left and 27 or 0)
        self:set("bus27_volt_right", right and 27 or 0)
        self:set("bus115_1_volt", left and 115 or 0)
        self:set("bus115_2_volt", 115)
        self:set("bus115_3_volt", right and 115 or 0)
    end
    function r:windows(left, center, right)
        self:set("window_heat_1", left)
        self:set("window_heat_2", center)
        self:set("window_heat_3", right)
    end
    function r:expectWindows(left, center, right)
        near(self:get("native_heat_left"), left, "Pilot front heat")
        near(self:get("native_heat_center"), center, "Center front heat")
        near(self:get("native_heat_right"), right, "Copilot front heat")
        near(self:get("native_heat_unused"), 0, "Unused channel is always off")
    end
    function r:probes(left, right, standby)
        self:set("pitot_heat_1", left)
        self:set("pitot_heat_2", right)
        self:set("pitot_heat_3", standby)
    end
    function r:expectProbes(left, right, standby)
        local groups = {
            {left, "sim_pitot_heat_1", "AOA_heat_on", "static_heat_pilot", "TAT_heat_pilot"},
            {right, "sim_pitot_heat_2", "AOA_heat_on_copilot", "static_heat_copilot", "TAT_heat_copilot"},
            {standby, "sim_pitot_heat_3", "AOA_heat_on_standby", "static_heat_standby", "TAT_heat_standby"},
        }
        for _, group in ipairs(groups) do
            for i = 2, #group do near(self:get(group[i]), group[1], group[i]) end
        end
    end
    return r
end

local function test(name, run)
    run()
    scenarios = scenarios + 1
    print("PASS " .. name)
end

test("native thermal channel indices are explicit and one-based in SASL", function()
    local r = controller()
    for name, index in pairs({native_heat_left = 1, native_heat_right = 2,
        native_heat_center = 3, native_heat_unused = 4}) do
        local binding = r.env[name]
        check(binding.name == "sim/cockpit2/ice/ice_window_heat_on_window"
            and binding.kind == "int-array" and binding.index == index, name .. " exact channel")
    end
    for name, index in pairs({native_ice_left = 1, native_ice_right = 2, native_ice_center = 3}) do
        local binding = r.env[name]
        check(binding.name == "sim/flightmodel/failures/window_ice_per_window"
            and binding.kind == "float-array" and binding.index == index, name .. " exact sensor")
    end
    for i = 1, 3 do near(r:get("window_heat_time_" .. i), 1 / 0.015, "Initial defrost time") end
end)

test("cold-and-dark overrides stale native heat switches", function()
    local r = controller()
    r:windows(1, 1, 1); r:probes(1, 1, 1)
    r:set("native_heat_unused", 1)
    r:step()
    r:expectWindows(0, 0, 0); r:expectProbes(0, 0, 0)
    for _, name in ipairs({"ai_115_1_cc", "ai_115_3_cc", "ai_27_L_cc", "ai_27_R_cc"}) do
        near(r:get(name), 0, "Cold-and-dark load " .. name)
    end
end)

test("each window switch drives its own front pane", function()
    local r = controller(); r:power(true, true)
    r:windows(1, 0, 0); r:step(); r:expectWindows(1, 0, 0)
    r:windows(0, 1, 0); r:step(); r:expectWindows(0, 1, 0)
    r:windows(0, 0, 1); r:step(); r:expectWindows(0, 0, 1)
    r:windows(0, 0, 0); r:step(); r:expectWindows(0, 0, 0)
end)

test("normal and strong heat preserve defrost rates and AC loads", function()
    local r = controller(); r:power(true, true)
    r:windows(-1, -1, -1); r:step(); r:expectWindows(1, 1, 1)
    for i = 1, 3 do near(r:get("window_heat_time_" .. i), 1 / 0.015, "Normal defrost time") end
    near(r:get("ai_115_1_cc"), 3.75, "Normal pilot AC load")
    near(r:get("ai_115_3_cc"), 7.5, "Normal center/copilot AC load")
    r:windows(1, 1, 1); r:step(); r:expectWindows(1, 1, 1)
    for i = 1, 3 do near(r:get("window_heat_time_" .. i), 50, "Strong defrost time") end
    near(r:get("ai_115_1_cc"), 5, "Strong pilot AC load")
    near(r:get("ai_115_3_cc"), 10, "Strong center/copilot AC load")
    r:windows(2, 2, 2); r:step(); r:expectWindows(0, 0, 0)
end)

test("window electrical isolation and strict bus thresholds", function()
    for _, bus in ipairs({"bus27_volt_left", "bus115_1_volt", "bus27_volt_right", "bus115_3_volt"}) do
        local r = controller(); r:power(true, true); r:windows(1, 1, 1)
        r:set(bus, bus:find("bus27", 1, true) and 13 or 110)
        r:step()
        local left_bus = bus == "bus27_volt_left" or bus == "bus115_1_volt"
        if left_bus then r:expectWindows(0, 1, 1) else r:expectWindows(1, 0, 0) end
        near(r:get("ai_115_1_cc"), left_bus and 0 or 5, "Left failed circuit load")
        near(r:get("ai_115_3_cc"), left_bus and 10 or 0, "Right failed circuit load")
    end
    local r = controller(); r:power(true, true); r:windows(1, 1, 1)
    r:set("bus115_2_volt", 0); r:step(); r:expectWindows(1, 1, 1)
end)

test("custom and native window failures remain pane-local", function()
    local failures = {
        {"window_heat_fail_1", 1, 0, 1, 1}, {"window_heat_fail_2", 1, 1, 0, 1},
        {"window_heat_fail_3", 1, 1, 1, 0}, {"native_window_fail_left", 6, 0, 1, 1},
        {"native_window_fail_center", 6, 1, 0, 1}, {"native_window_fail_right", 6, 1, 1, 0},
    }
    for _, failure in ipairs(failures) do
        local r = controller(); r:power(true, true); r:windows(1, 1, 1)
        r:set(failure[1], failure[2]); r:step()
        r:expectWindows(failure[3], failure[4], failure[5])
        r:set(failure[1], 0); r:step(); r:expectWindows(1, 1, 1)
    end
    local r = controller(); r:power(true, true); r:windows(1, 1, 1)
    r:set("native_window_fail_left", 3); r:step(); r:expectWindows(1, 1, 1)
end)

test("native ice mirrors are read-only and keep L/C/R display order", function()
    local r = controller(); r:power(true, true); r:windows(1, 1, 1)
    r:set("window_ice", 0.91)
    r:set("native_ice_left", 0.11); r:set("native_ice_right", 0.22)
    r:set("native_ice_center", 0.33); r:set("native_ice_unheated", 0.44)
    r:step(1, 10)
    for name, expected in pairs({window_ice = 0.91, window_ice_1 = 0.11,
        window_ice_2 = 0.33, window_ice_3 = 0.22, window_ice_4 = 0.44}) do
        near(r:get(name), expected, name .. " is mirrored without native reset")
    end
    r:set("native_ice_left", -0.1); r:set("native_ice_right", 1.2)
    r:step(); near(r:get("window_ice_1"), 0, "Display lower bound")
    near(r:get("window_ice_3"), 1, "Display upper bound")
    near(r:get("native_ice_right"), 1.2, "Native ratio remains untouched")
end)

test("all three probe switches independently protect four sensor types", function()
    local r = controller(); r:power(true, true)
    r:probes(1, 0, 0); r:step(); r:expectProbes(1, 0, 0)
    near(r:get("ai_27_L_cc"), 10, "Pilot DC load"); near(r:get("ai_27_R_cc"), 0, "Right DC off")
    r:probes(0, 1, 0); r:step(); r:expectProbes(0, 1, 0)
    r:probes(0, 0, 1); r:step(); r:expectProbes(0, 0, 1)
    r:probes(1, 1, 1); r:step(); r:expectProbes(1, 1, 1)
    near(r:get("ai_27_L_cc"), 10, "Pilot load unchanged")
    near(r:get("ai_27_R_cc"), 14, "Copilot plus standby load")
end)

test("diagnostic test and OFF do not energize probe heaters", function()
    local r = controller(); r:power(true, true)
    for _, mode in ipairs({-1, 0, 2}) do
        r:probes(mode, mode, mode); r:step(); r:expectProbes(0, 0, 0)
        near(r:get("ai_27_L_cc"), 0, "No pilot heater load")
        near(r:get("ai_27_R_cc"), 0, "No right heater load")
    end
end)

test("probe buses are independent and do not require AC", function()
    local r = controller(); r:power(false, true); r:probes(1, 1, 1)
    r:step(); r:expectProbes(0, 1, 1)
    r:power(true, false); r:step(); r:expectProbes(1, 0, 0)
    r:power(true, true)
    for i = 1, 3 do r:set("bus115_" .. i .. "_volt", 0) end
    r:step(); r:expectProbes(1, 1, 1)
end)

test("native PPD failures and both standby failure inputs disable their group", function()
    local failures = {
        {"rel_ice_pitot_heat1", 6, 0, 1, 1}, {"rel_ice_pitot_heat2", 6, 1, 0, 1},
        {"rel_ice_pitot_heat3", 6, 1, 1, 0}, {"ppd_3_heat_fail", 1, 1, 1, 0},
    }
    for _, failure in ipairs(failures) do
        local r = controller(); r:power(true, true); r:probes(1, 1, 1)
        r:set(failure[1], failure[2]); r:step()
        r:expectProbes(failure[3], failure[4], failure[5])
        near(r:get("ai_27_L_cc"), 10 * failure[3], "Failed pilot heater load")
        near(r:get("ai_27_R_cc"), 7 * (failure[4] + failure[5]), "Failed right heater load")
        r:set(failure[1], 0); r:step(); r:expectProbes(1, 1, 1)
    end
end)

test("icing source is native ice_delta and retains the old rate multiplier", function()
    local r = controller(); r:power(true, true); r:set("soi21_on", 1)
    r:set("native_ice_rate", 0.001)
    r:step(1)
    near(r:get("frm_ice"), 0.002, "Wing/slat rate with deterministic random factor")
    near(r:get("frm_ice2"), 0.002, "Right wing/slat rate")
    near(r:get("ice_detected"), 1, "Accretion detected at zero window ice")
    r:set("native_ice_left", 1); r:set("native_ice_unheated", 1)
    r:step(1)
    near(r:get("frm_ice"), 0.004, "Accretion still detected at full window ice")
    r:set("native_ice_rate", -0.001); r:step(1)
    near(r:get("frm_ice"), 0.002, "Native removal rate decreases custom wing ice")
    r:set("native_ice_rate", 0); r:step(1, 9)
    near(r:get("ice_detected"), 0, "Residual window ice does not retrigger SOI")
    near(r:get("frm_ice"), 0.002, "No derivative from heated native window ratios")
end)

test("window heating cannot alter icing sensor source", function()
    local r = controller(); r:power(true, true); r:set("soi21_on", 1)
    r:set("native_ice_left", 0.9); r:set("window_ice", 0.9)
    r:windows(1, 1, 1); r:step(1)
    near(r:get("ice_detected"), 0, "Static native window ratio is not accretion")
    near(r:get("frm_ice"), 0, "No fabricated wing ice from 0.5 reset")
    r:set("native_ice_left", 0.1); r:set("window_ice", 0.1); r:step(1)
    near(r:get("ice_detected"), 0, "Heated pane removal is not the global ice sensor")
end)

test("SOI diagnostic timing and detector power/failure gates are retained", function()
    local r = controller(); r:power(true, true); r:set("soi21_on", 1)
    r:set("soi21_test", 1); r:step(0.1)
    near(r:get("ice_detected"), 1, "SOI test requests detection")
    near(r:get("ice_detect_ok"), 0, "SOI test acknowledgement is delayed")
    r:set("soi21_test", 0); r:step(1, 31)
    near(r:get("ice_detect_ok"), 1, "SOI healthy after 31 seconds")
    r:step(1, 24); near(r:get("ice_detect_ok"), 0, "SOI acknowledgement ends at 55 seconds")
    r:set("native_ice_rate", 0.001); r:set("rio_fail", 1)
    r:step(1, 9); near(r:get("ice_detected"), 0, "Failed sensor cannot detect accretion")
    r:set("rio_fail", 0); r:power(true, false); r:step()
    near(r:get("ice_detected"), 0, "Both detector DC buses required")
end)

test("pause and invalid frame time freeze accumulated state without corrupting it", function()
    for _, dt in ipairs({0, -1, math.huge, -math.huge, 0 / 0}) do
        local r = controller(); r:power(true, true); r:set("native_ice_rate", 0.001)
        r:step(1)
        local before = r:get("frm_ice")
        r:step(dt)
        near(r:get("frm_ice"), before, "Invalid/pause time cannot change airframe ice")
        near(r:get("wing_heat_t"), 0, "Invalid time cannot corrupt duct temperature")
    end
    local r = controller(); r:power(true, true); r:windows(1, 1, 1); r:probes(1, 1, 1)
    r:set("native_ice_rate", 0.001); r:set("sim_paused", 1); r:step(10)
    near(r:get("frm_ice"), 0, "Simulator pause freezes accretion")
    r:expectWindows(1, 1, 1); r:expectProbes(1, 1, 1)
end)

test("non-finite native ice rate cannot poison custom icing", function()
    for _, rate in ipairs({math.huge, -math.huge, 0 / 0}) do
        local r = controller(); r:power(true, true); r:set("soi21_on", 1)
        r:set("native_ice_rate", rate); r:step(1)
        near(r:get("frm_ice"), 0, "Non-finite native source rejected")
        near(r:get("ice_detected"), 0, "Non-finite source does not indicate icing")
        r:set("native_ice_rate", 0.001); r:step(1)
        near(r:get("frm_ice"), 0.002, "Recovery after invalid native source")
    end
end)

test("SmartCopilot slave applies local native switches but preserves shared mirrors", function()
    local r = controller(); r:power(true, true); r:windows(1, -1, 1); r:probes(1, 1, 1)
    r:set("ismaster", 1); r:set("native_ice_rate", 0.001)
    local shared = {"window_ice_1", "window_ice_2", "window_ice_3", "window_ice_4",
        "ice_detected", "ice_detect_ok", "frm_ice", "frm_ice2", "ai_115_1_cc", "ai_115_3_cc"}
    for _, name in ipairs(shared) do r:set(name, 0.123) end
    r:step(1)
    r:expectWindows(1, 1, 1); r:expectProbes(1, 1, 1)
    for _, name in ipairs(shared) do
        near(r:writeCount(name), 0, "No slave write to " .. name)
        near(r:get(name), 0.123, "Preserved shared state " .. name)
    end
    r:set("ismaster", 0); r:step()
    check(r:writeCount("window_ice_1") == 1, "Master ownership resumes normally")
end)

test("engine inlet and wing/slat operating gates remain intact", function()
    local r = controller(); r:power(true, true)
    for i = 1, 3 do r:set("antiice_eng_" .. i, 1); r:set("rpm_high_" .. i, 70) end
    r:set("antiice_wing", 1); r:set("antiice_slats", 1)
    r:step(0.1)
    for i = 1, 3 do near(r:get("inlet_heat_" .. i), 1, "Engine inlet " .. i) end
    near(r:get("wings_heat_on"), 1, "Native wing heater")
    near(r:get("wing_heating"), 1, "Custom wing heater")
    near(r:get("slat_heating"), 1, "Airborne slat heater")
    near(r:get("ai_115_2_cc"), 70, "Slat AC load unchanged")
    near(r:get("wing_heat_t"), 3, "Wing duct heating unchanged")
    near(r:get("stab_heat_t"), 3, "Stabilizer duct heating unchanged")
    r:set("rel_ice_inlet_heat2", 6); r:set("rpm_high_1", 50); r:set("bus27_volt_right", 0)
    r:set("deflection_mtr_2", 0.1); r:step(0)
    for i = 1, 3 do near(r:get("inlet_heat_" .. i), 0, "RPM/failure/DC engine gate " .. i) end
    near(r:get("eng_heat_open_1"), 1, "Engine valve can open below heating RPM")
    near(r:get("slat_heating"), 0, "Ground slat interlock unchanged")
    r:set("rel_ice_surf_heat", 6); r:step(0)
    near(r:get("wing_heating"), 0, "Wing failure interlock unchanged")
end)

print("PASS window/probe heat: " .. scenarios .. " scenarios, " .. assertions .. " assertions")
