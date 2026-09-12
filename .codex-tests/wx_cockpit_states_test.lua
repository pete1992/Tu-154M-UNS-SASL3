-- Offline full-module WX regression; native setter side effects are stress mocks.
-- This test does not connect to X-Plane or simulate radar returns/flight dynamics.
local root = assert(arg[1], "Provide the aircraft directory")
local path = root .. "/plugins/xtlua/init/scripts/T154.kontur/T154.kontur.lua"
local assertions, scenarios = 0, 0
local function eq(actual, expected, description)
    assert(actual == expected, description .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
    assertions = assertions + 1
end
local native = "sim/cockpit2/EFIS/EFIS_weather_"
local mode_paths = {native .. "mode", native .. "mode_copilot"}
local pws_path = native .. "pws"

local function controller()
    local bindings, refs, values, globals, commands, writes = {}, {}, {}, {}, {}, {}
    local initializing = true
    local env = setmetatable({}, {
        __index = function(_, name)
            if bindings[name] then return values[bindings[name]] end
            if globals[name] ~= nil then return globals[name] end
            return _G[name]
        end,
        __newindex = function(_, name, value)
            if type(value) == "table" and value.dataref_handle then
                -- deferred_dataref temporarily stores the handle in global dref.
                if name == "dref" then globals[name] = value; return end
                bindings[name] = value.path
                if values[value.path] == nil then values[value.path] = value.kind == "string" and "" or 0 end
                return
            end
            local dataref = bindings[name]
            if not dataref then globals[name] = value; return end
            if not initializing and dataref:sub(1, 4) == "sim/" then
                writes[#writes + 1] = {path = dataref, value = value, pws_before = values[pws_path]}
            end
            values[dataref] = value
            if not initializing and (dataref == mode_paths[1] or dataref == mode_paths[2]) then
                -- Deliberately hostile reset fixture, not a claim about exact native defaults.
                local side = dataref == mode_paths[2] and "_copilot" or ""
                values[native .. "auto_tilt" .. side] = 1
                values[native .. "multiscan" .. side] = 1
                values[native .. "tilt" .. side] = 0
                values[native .. "gcs" .. side] = 1
                values[native .. "stab" .. side] = 0
                values[native .. "gain" .. side] = 1
                values[pws_path] = 0
            end
        end,
    })
    env.print = function() end
    env.find_dataref = function(name) return {dataref_handle = true, path = name, kind = "number"} end
    env.XLuaCreateDataRef = function(name, kind, writable, notifier)
        refs[name] = {kind = kind, writable = writable, notifier = notifier}
        return {dataref_handle = true, path = name, kind = kind}
    end
    env.wrap_dref_any = function(handle) return handle end
    env.create_command = function(name, _, handler) commands[name] = handler; return name end
    local chunk
    if setfenv then chunk = assert(loadfile(path)); setfenv(chunk, env)
    else chunk = assert(loadfile(path, "t", env)) end
    chunk(); initializing = false
    local r = {env = env, refs = refs, values = values, writes = writes}
    function r:set(name, value) values[assert(bindings[name], name)] = value end
    function r:get(name) return values[assert(bindings[name], name)] end
    function r:step(count) for _ = 1, count or 1 do env.after_physics() end end
    function r:command(name) assert(commands[name], name)(0, 0); self:step() end
    function r:clear_writes() for i = #writes, 1, -1 do writes[i] = nil end end
    function r:write_count(dataref)
        local count = 0
        for _, write in ipairs(writes) do if write.path == dataref then count = count + 1 end end
        return count
    end
    function r:settings(mode, pws, physical, label)
        eq(self:get("simDR_weather_mode_xp"), mode, label .. " pilot mode")
        eq(self:get("simDR_weather_mode_xp_fo"), mode, label .. " copilot mode")
        eq(self:get("simDR_weather_pws"), pws, label .. " PWS")
        for _, suffix in ipairs({"", "_fo"}) do
            eq(self:get("simDR_weather_gcs" .. suffix), mode == 4 and 0 or 1, label .. " GCS" .. suffix)
            eq(self:get("simDR_weather_tilt" .. suffix), -7.5, label .. " tilt" .. suffix)
            eq(self:get("simDR_weather_auto_tilt" .. suffix), 0, label .. " auto tilt" .. suffix)
            eq(self:get("simDR_weather_multiscan" .. suffix), 0, label .. " multiscan" .. suffix)
            eq(self:get("simDR_weather_stab" .. suffix), 1, label .. " stabilization" .. suffix)
        end
    end
    r:set("simDR_passed", 0.05); r:set("simDR_36v", 36)
    r:set("simDR_bus27left", 27); r:set("simDR_bus27right", 27)
    r:set("kontur_pow_l", 1); r:set("kontur_pow_r", 1)
    r:set("ubs_pow_l", 1); r:set("ubs_pow_r", 1)
    r:set("simDR_gps_power", 1); r:set("simDR_gps_fromto", 1)
    r:set("simDR_tcas_mode", 4)
    env.aircraft_load(); r:set("wx2000_tilt", -7.5); r:clear_writes()
    return r
end
local function test(name, callback)
    callback(controller()); scenarios = scenarios + 1; print("PASS " .. name)
end

test("writable physical controls and defaults", function(r)
    for _, name in ipairs({"tu154/custom/kontur/weather_mode", "tu154/custom/wx2000_windshear"}) do
        local ref = assert(r.refs[name], "Missing cockpit DataRef " .. name)
        eq(ref.kind, "number", "numeric cockpit state")
        eq(ref.writable, "yes", "writable cockpit state")
        eq(type(ref.notifier), "function", "write notifier")
    end
    eq(r:get("weather_mode"), 1, "WX default")
    eq(r:get("wx2000_windshear"), 0, "windshear OFF default")
end)

for _, powered in ipairs({0, 1}) do
    for physical = 0, 3 do
        for windshear = 0, 1 do
            test("power " .. powered .. " detent " .. physical .. " PWS switch " .. windshear, function(r)
                r:set("weather_sys", powered); r:set("weather_mode", physical)
                r:set("wx2000_windshear", windshear); r:step(401)
                eq(r:get("weather_mode"), physical, "detent retained")
                eq(r:get("wx2000_windshear"), windshear, "switch retained")
                eq(r:get("weather_ready"), powered, "20 second readiness including TEST")
                r:settings(powered == 1 and physical + 1 or 0, powered * windshear, physical, "settled")
                r:clear_writes(); r:step(100)
                eq(r:write_count(mode_paths[1]), 0, "no stationary pilot mode restart")
                eq(r:write_count(mode_paths[2]), 0, "no stationary copilot mode restart")
            end)
        end
    end
end

test("native radar and PWS wait for complete warmup", function(r)
    r:set("weather_sys", 1); r:set("weather_mode", 2); r:set("wx2000_windshear", 1)
    r:step(99); eq(r:get("kontur_wx_test_l"), 0, "before 5 seconds")
    r:step(2); eq(r:get("kontur_wx_test_l"), 1, "after 5 seconds")
    r:step(140); eq(r:get("kontur_wx_test_l"), 2, "after 12 seconds")
    r:step(158)
    eq(r:get("weather_ready"), 0, "19.95 seconds not ready")
    eq(r:get("simDR_weather_mode_xp"), 0, "no native scan during warmup")
    eq(r:get("simDR_weather_pws"), 0, "PWS blocked during warmup")
    r:step(2); eq(r:get("kontur_wx_test_l"), -1, "20 seconds complete")
    r:settings(3, 1, 2, "WX/TURB release")
end)

test("detent changes restore cockpit settings after native side effects", function(r)
    r:set("weather_sys", 1); r:set("wx2000_windshear", 1); r:step(401)
    for _, physical in ipairs({3, 2, 0, 1, 3, 0}) do
        r:set("weather_mode", physical); r:clear_writes(); r:step()
        r:settings(physical + 1, 1, physical, "detent change")
        eq(r:write_count(mode_paths[1]), 1, "one pilot mode write")
        eq(r:write_count(mode_paths[2]), 1, "one copilot mode write")
        r:clear_writes(); r:step(30)
        eq(r:write_count(mode_paths[1]), 0, "pilot sweep preserved")
        eq(r:write_count(mode_paths[2]), 0, "copilot sweep preserved")
    end
end)

test("PWS suppressed before shutdown and fresh warmup on power recovery", function(r)
    r:set("weather_sys", 1); r:set("weather_mode", 3); r:set("wx2000_windshear", 1); r:step(401)
    r:set("wx2000_windshear", 0); r:step()
    eq(r:get("simDR_weather_pws"), 0, "physical OFF clears PWS")
    r:set("wx2000_windshear", 1); r:step()
    eq(r:get("simDR_weather_pws"), 1, "AUTO restores PWS")
    r:set("weather_sys", 0); r:clear_writes(); r:step()
    local off_writes = 0
    for _, write in ipairs(r.writes) do
        if (write.path == mode_paths[1] or write.path == mode_paths[2]) and write.value == 0 then
            eq(write.pws_before, 0, "PWS zero before native OFF")
            off_writes = off_writes + 1
        end
    end
    eq(off_writes, 2, "both modes switched OFF")
    eq(r:get("weather_ready"), 0, "SYS off invalidates readiness")
    r:settings(0, 0, 3, "OFF")
    r:set("weather_sys", 1); r:step(399)
    eq(r:get("weather_ready"), 0, "restart needs fresh 20 seconds")
    eq(r:get("simDR_weather_pws"), 0, "restart cannot emit early")
    r:step(2); r:settings(4, 1, 3, "MAP and AUTO recovery")
    r:set("simDR_36v", 0); r:step()
    eq(r:get("simDR_weather_pws"), 0, "bus loss clears PWS")
    eq(r:get("simDR_weather_mode_xp"), 0, "bus loss clears radar")
end)

test("aircraft reload suppresses inherited PWS before native OFF", function(r)
    r:set("simDR_weather_mode_xp", 4); r:set("simDR_weather_mode_xp_fo", 3)
    r:set("simDR_weather_pws", 1); r:clear_writes(); r.env.aircraft_load()
    local count = 0
    for _, write in ipairs(r.writes) do
        if (write.path == mode_paths[1] or write.path == mode_paths[2]) and write.value == 0 then
            eq(write.pws_before, 0, "reload PWS suppressed before native mode OFF"); count = count + 1
        end
    end
    eq(count, 2, "reload switches both native modes OFF")
    eq(r:get("simDR_weather_pws"), 0, "reload PWS remains OFF")
end)

test("NAV TCAS and WX selection survive all physical radar modes", function(r)
    r:set("weather_sys", 1); r:set("wx2000_windshear", 1); r:step(480)
    for _, side in ipairs({"l", "r"}) do
        r:command("kontur/nav_btn_" .. side)
        r:command("kontur/rls_btn_" .. side)
        r:command("kontur/tcas_btn_" .. side)
    end
    for physical = 0, 3 do
        r:set("weather_mode", physical); r:step()
        for _, side in ipairs({"l", "r"}) do
            eq(r:get("kontur_mode_" .. side), 5, "NAV+WX mode retained")
            eq(r:get("kontur_nav_" .. side), 1, "NAV retained")
            eq(r:get("kontur_tcas_" .. side), 2, "TCAS overlay retained")
        end
        eq(r:get("simDR_fms_line"), 0, "route line remains visible")
    end
    r:command("kontur/tcas_btn_l")
    eq(r:get("kontur_tcas_l"), 0, "left TCAS off")
    eq(r:get("kontur_tcas_r"), 2, "right TCAS unaffected")
    eq(r:get("kontur_nav_l"), 1, "left NAV retained")
    r:command("kontur/rls_btn_l")
    eq(r:get("kontur_mode_l"), 3, "left WX independently deselected")
    eq(r:get("kontur_mode_r"), 5, "right NAV+WX retained")
    eq(r:get("simDR_weather_pws"), 1, "PWS independent of display keys")
end)

test("display standby is preserved across TEST selection", function(r)
    r:set("weather_sys", 1); r:set("wx2000_windshear", 1); r:step(480)
    r:command("kontur/rls_btn_l"); r:command("kontur/btn3_btn_l")
    eq(r:get("kontur_wx_l"), 2, "left screen standby")
    r:set("weather_mode", 0); r:step(); r:set("weather_mode", 1); r:step()
    eq(r:get("kontur_wx_l"), 2, "TEST does not reset display standby")
    eq(r:get("simDR_efis_1_wxr"), 0, "standby overlay remains hidden")
    eq(r:get("simDR_weather_pws"), 1, "ready AUTO independent of screen standby")
    r:command("kontur/rls_btn_l"); r:command("kontur/rls_btn_l")
    eq(r:get("kontur_wx_l"), 3, "explicit WX reselection restores scan")
end)

test("gain and tilt survive mode changes", function(r)
    r:set("weather_sys", 1); r:step(401)
    for _, control in ipairs({"kontur_rru_l", "kontur_rru_r", "wx2000_gain"}) do
        r:set(control, 0); r:step()
        eq(r:get("simDR_weather_gain"), 0, "gain reaches zero: " .. control)
        r:set(control, 0.6); r:step()
        eq(r:get("simDR_weather_gain"), 1.2, "last moved gain pilot")
        eq(r:get("simDR_weather_gain_fo"), 1.2, "last moved gain copilot")
        r:set("weather_mode", 3); r:step()
        eq(r:get("simDR_weather_gain"), 1.2, "gain reapplied after mode setter")
        r:set("weather_mode", 1); r:step()
    end
    for _, tilt in ipairs({-15, 0, 15}) do
        r:set("wx2000_tilt", tilt); r:step()
        eq(r:get("simDR_weather_tilt"), tilt, "pilot physical tilt")
        eq(r:get("simDR_weather_tilt_fo"), tilt, "copilot physical tilt")
    end
end)

test("TEST image ignores attitude faults but respects screen standby", function(r)
    r:set("weather_sys", 1); r:set("wx2000_windshear", 1); r:step(480)
    r:command("kontur/rls_btn_l"); r:command("kontur/rls_btn_r")
    for _, fault in ipairs({"simDRnostab_l", "simDRnostab_r", "ubs_pow_l", "ubs_pow_r"}) do
        r:set(fault, fault:sub(1, 3) == "ubs" and 0 or 1)
        for physical = 0, 3 do
            r:set("weather_mode", physical); r:step()
            local side = fault:sub(-1) == "l" and "1" or "2"
            eq(r:get("simDR_efis_" .. side .. "_wxr"), physical == 0 and 1 or 0,
                "TEST alone bypasses stabilization fault " .. fault)
        end
        r:set(fault, fault:sub(1, 3) == "ubs" and 1 or 0)
    end
    r:set("weather_mode", 0); r:set("ubs_pow_l", 0); r:set("ubs_pow_r", 0)
    r:command("kontur/btn3_btn_l"); r:command("kontur/btn3_btn_r")
    eq(r:get("simDR_efis_1_wxr"), 0, "TEST hidden in left standby")
    eq(r:get("simDR_efis_2_wxr"), 0, "TEST hidden in right standby")
end)

test("invalid physical detents and power inputs cannot emit", function(r)
    r:set("weather_sys", 1); r:set("wx2000_windshear", 1); r:step(401)
    for _, value in ipairs({-1, 4, 1.5, 0/0, math.huge}) do
        r:set("weather_mode", value); r:step()
        eq(r:get("simDR_weather_mode_xp"), 0, "invalid detent inhibits radar")
        eq(r:get("simDR_weather_mode_xp_fo"), 0, "invalid detent inhibits copilot radar")
        eq(r:get("simDR_weather_pws"), 0, "invalid detent inhibits PWS")
    end
    r:set("weather_mode", 1)
    for _, name in ipairs({"weather_sys", "simDR_36v"}) do
        for _, value in ipairs({0/0, math.huge}) do
            r:set(name, value); r:step()
            eq(r:get("simDR_weather_mode_xp"), 0, "nonfinite power inhibits radar")
            eq(r:get("simDR_weather_pws"), 0, "nonfinite power inhibits PWS")
        end
        r:set(name, name == "weather_sys" and 1 or 36)
    end
end)
print("PASS WX logic: " .. scenarios .. " scenarios, " .. assertions .. " assertions; no live radar claim")
