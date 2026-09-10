-- Offline ABSU state-machine regression tests; no simulator connection.
local root = assert(arg[1], "Provide the aircraft directory")
local path = root .. "/plugins/sasl/data/modules/Custom Module/main_panel/absu/absu_mode.lua"
local assertions, scenarios = 0, 0
local function eq(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    assertions = assertions + 1
end
local function controller()
    local env, values, handlers = {}, {}, {}
    setmetatable(env, {__index = _G})
    env.globalPropertyi = function(p) return p end
    env.globalPropertyf = env.globalPropertyi
    env.defineProperty = function(name, p) env[name] = p end
    env.get = function(p) return values[p] or 0 end
    env.set = function(p, v) values[p] = v end
    env.bool2int = function(v) return v and 1 or 0 end
    -- Test fixture frequencies: 110.30/110.50 are ILS, 113.00 is VOR.
    env.isILS = function(f) return f == 11030 or f == 11050 end
    env.SASL_COMMAND_BEGIN, env.SASL_COMMAND_CONTINUE = 0, 1
    env.sasl = {findCommand = function(n) return n end,
        registerCommandHandler = function(n, _, fn) handlers[n] = fn end}
    local chunk
    if setfenv then chunk = assert(loadfile(path)); setfenv(chunk, env)
    else chunk = assert(loadfile(path, "t", env)) end
    chunk()
    local r = {env = env, handlers = handlers}
    function r:set(name, v) values[assert(env[name], name)] = v end
    function r:get(name) return env.get(assert(env[name], name)) end
    function r:step(n) for _ = 1, n or 1 do env.update() end end
    function r:press(name) self:set(name, 1); self:step(); self:set(name, 0); self:step() end
    function r:modes(roll, pitch, lateral, vertical, label)
        eq(self:get("roll_main_mode"), roll, label .. " roll AP")
        eq(self:get("pitch_main_mode"), pitch, label .. " pitch AP")
        eq(self:get("roll_sub_mode"), lateral, label .. " lateral")
        eq(self:get("pitch_sub_mode"), vertical, label .. " vertical")
    end
    function r:capture()
        self:step(20); self:press("absu_app"); self:press("absu_gs")
        self:modes(2, 2, 6, 5, "capture")
    end
    for _, n in ipairs({"bus27_volt_left", "bus27_volt_right"}) do r:set(n, 27) end
    for _, n in ipairs({"bus115_1_volt", "bus115_3_volt"}) do r:set(n, 115) end
    for _, n in ipairs({"bus36_volt_left", "bus36_volt_right", "bus36_volt_pts250_1", "bus36_volt_pts250_2"}) do r:set(n, 36) end
    for _, axis in ipairs({"ail", "elev", "rud"}) do
        for i = 1, 3 do r:set("hydro_ra56_" .. axis .. "_" .. i, 1) end
    end
    for i = 1, 3 do r:set("gs_press_" .. i, 200) end
    for _, n in ipairs({"sau_stu_on", "absu_roll_ch_on", "absu_pitch_ch_on", "absu_landing_on", "nav_power_1", "nav_power_2", "svs_on"}) do r:set(n, 1) end
    r:set("freq_1", 11030); r:set("freq_2", 11030)
    r:set("nav_gs_1", 0.3); r:set("nav_gs_2", 0.3)
    r:set("frame_time", 0.02); r:set("rv5_alt", 500)
    r:step(20); r:press("absu_stab")
    r:modes(2, 2, 1, 1, "initial stabilization")
    return r
end
local function test(name, fn)
    fn(controller()); scenarios = scenarios + 1; print("PASS " .. name)
end

test("stable NAV1 approach", function(r)
    r:capture(); r:step(3000); r:modes(2, 2, 6, 5, "60 seconds stable")
end)
test("NAV2 fallback does not use NAV1 resets", function(r)
    r:set("nav_cs_flag_1", 1); r:set("nav_gs_flag_1", 1); r:capture()
    eq(r:get("absu_use_second_nav"), 1, "NAV2 selected")
    r:set("nav_cs_flag_1", 0); r:set("nav_gs_flag_1", 0); r:step(100)
    eq(r:get("absu_use_second_nav"), 1, "NAV2 remains selected after NAV1 recovers")
    r:set("nav_power_1", 0); r:set("nav_fail_1", 1); r:step(100)
    r:modes(2, 2, 6, 5, "unselected receiver failure")
end)
test("brief signal gaps retain captured source and AP", function(r)
    r:capture()
    for _ = 1, 20 do
        r:set("nav_cs_flag_1", 1); r:set("nav_gs_flag_1", 1); r:step(20)
        r:modes(2, 2, 6, 5, "0.4 second gap")
        eq(r:get("absu_use_second_nav"), 0, "no transient NAV2 switch")
        r:set("nav_cs_flag_1", 0); r:set("nav_gs_flag_1", 0); r:step(20)
    end
    eq(r:get("absu_fail_signal"), 0, "no false disconnect alarm")
end)
test("sustained loss cannot recapture from held buttons", function(r)
    r:set("absu_app", 1); r:set("absu_gs", 1); r:step(20)
    r:modes(2, 2, 6, 5, "held buttons captured")
    r:set("nav_cs_flag_1", 1); r:set("nav_gs_flag_1", 1); r:step(60)
    r:modes(1, 1, 1, 1, "sustained loss releases both")
    r:set("nav_cs_flag_1", 0); r:set("nav_gs_flag_1", 0); r:step(100)
    r:modes(1, 1, 1, 1, "signal return does not recapture")
    r:set("absu_app", 0); r:set("absu_gs", 0); r:step()
    r:press("absu_stab"); r:capture()
end)
test("acquisition requires stable reception", function(r)
    r:set("nav_cs_flag_1", 1); r:set("nav_cs_flag_2", 1)
    r:set("nav_gs_flag_1", 1); r:set("nav_gs_flag_2", 1)
    r:press("absu_app"); r:press("absu_gs")
    r:modes(2, 2, 10, 10, "armed without reception")
    r:set("nav_cs_flag_1", 0); r:set("nav_gs_flag_1", 0); r:step(5)
    r:modes(2, 2, 10, 10, "short false-valid pulse not captured")
    r:set("nav_cs_flag_1", 1); r:set("nav_gs_flag_1", 1); r:step()
    r:set("nav_cs_flag_1", 0); r:set("nav_gs_flag_1", 0); r:step(20)
    r:modes(2, 2, 6, 5, "stable reception captured")
end)
for _, source in ipairs({1, 2}) do
    test("NAV" .. source .. " automatic GS once per approach", function(r)
        if source == 2 then r:set("nav_cs_flag_1", 1); r:set("nav_gs_flag_1", 1) end
        r:set("flap_inn_L", 45); r:set("flap_inn_R", 45)
        r:set("nav_gs_" .. source, 0); r:step(20); r:press("absu_app")
        r:modes(2, 2, 6, 5, "auto GS uses selected receiver")
        r:set("nav_gs_flag_" .. source, 1); r:step(60)
        r:modes(2, 1, 6, 1, "GS sustained loss")
        r:set("nav_gs_flag_" .. source, 0); r:step(100)
        r:modes(2, 1, 6, 1, "auto GS cannot silently recapture")
    end)
end
for _, setting in ipairs({{"nav_power_1", 0}, {"nav_fail_1", 1}, {"freq_1", 11050}, {"freq_1", 11300}}) do
    test("immediate disconnect on " .. setting[1] .. "=" .. setting[2], function(r)
        r:capture(); r:set(setting[1], setting[2]); r:step()
        r:modes(1, 1, 1, 1, "hardware loss or retune")
    end)
end
test("landing preparation off clears capture and arming", function(r)
    r:capture(); r:set("absu_landing_on", 0); r:step()
    r:modes(1, 1, 1, 1, "landing off")
    r:set("absu_landing_on", 1); r:set("nav_cs_flag_1", 1); r:set("nav_cs_flag_2", 1)
    r:set("nav_gs_flag_1", 1); r:set("nav_gs_flag_2", 1)
    r:press("absu_app"); r:press("absu_gs")
    r:modes(1, 1, 10, 10, "armed flight director")
    r:set("absu_landing_on", 0); r:step()
    r:modes(1, 1, 1, 1, "armed selection cancelled")
end)
test("reset and pitch wheel remain effective", function(r)
    r:capture(); r:set("flap_inn_L", 45); r:set("flap_inn_R", 45); r:set("nav_gs_1", 0)
    r:press("absu_reset"); r:step(100); r:modes(2, 2, 1, 1, "reset")
    r:capture(); r:set("absu_pitch_wheel", 1); r:step(100)
    r:modes(2, 2, 6, 1, "pitch wheel exits GS without recapture")
end)
test("manual input and disconnect command remain immediate", function(r)
    r:capture(); r:set("joy_roll", 0.21); r:set("joy_pitch", -0.21); r:step()
    r:modes(1, 1, 6, 5, "manual control retains directors")
    r:set("joy_roll", 0); r:set("joy_pitch", 0); r:press("absu_stab")
    r.handlers["sim/autopilot/fdir_toggle"](0); r:step()
    r:modes(1, 1, 6, 5, "disconnect command")
end)
test("ABSU power and hydraulic loss remain immediate", function(r)
    r:capture(); r:set("bus27_volt_left", 0); r:step(); r:modes(0, 0, 0, 0, "power loss")
end)
test("hydraulic loss remains immediate", function(r)
    r:capture(); r:set("gs_press_1", 0); r:set("gs_press_2", 0); r:step()
    r:modes(0, 0, 0, 0, "hydraulic loss")
end)
test("damper faults remain immediate", function(r)
    r:capture(); r:set("absu_damp_roll_fail", 1); r:set("absu_damp_pitch_fail", 1); r:step()
    eq(r:get("roll_main_mode"), 0, "roll damper failure")
    eq(r:get("pitch_main_mode"), 0, "pitch damper failure")
end)
test("TOGA still exits the approach", function(r)
    r:capture(); r.handlers["sim/autopilot/take_off_go_around"](0); r:step()
    r:modes(2, 2, 1, 6, "TOGA")
end)
test("SmartCopilot slave does not publish custom modes", function(r)
    r:capture(); r:set("ismaster", 1); r:set("nav_power_1", 0); r:step(100)
    r:modes(2, 2, 6, 5, "slave")
end)
test("wheel cancellation wins on GS acquisition frame", function(r)
    r:set("nav_gs_flag_1", 1); r:press("absu_gs")
    r:set("frame_time", 0.1); r:set("nav_gs_flag_1", 0); r:step(2)
    eq(r:get("pitch_sub_mode"), 10, "not acquired yet")
    r:set("absu_pitch_wheel", 1); r:step(20)
    eq(r:get("pitch_sub_mode"), 1, "wheel cancelled capture")
end)
test("turn handle cancellation wins on LOC acquisition frame", function(r)
    r:set("nav_cs_flag_1", 1); r:set("nav_cs_flag_2", 1); r:press("absu_app")
    r:set("frame_time", 0.1); r:set("nav_cs_flag_1", 0); r:step(2)
    eq(r:get("roll_sub_mode"), 10, "not acquired yet")
    r:set("absu_turn_handle", 2); r:step()
    eq(r:get("roll_sub_mode"), 1, "turn handle cancelled capture")
end)
test("NAV1 chatter cannot starve stable armed NAV2", function(r)
    r:set("nav_cs_flag_1", 1); r:set("nav_cs_flag_2", 1); r:press("absu_app")
    r:set("nav_cs_flag_2", 0); r:step()
    for i = 1, 30 do r:set("nav_cs_flag_1", i % 2); r:step() end
    eq(r:get("absu_use_second_nav"), 1, "stable NAV2 acquisition source")
    eq(r:get("roll_sub_mode"), 6, "NAV2 captured despite NAV1 chatter")
end)
test("non-approach VOR selection is preserved", function(r)
    r:set("absu_landing_on", 0); r:set("absu_nav_on", 1); r:set("freq_1", 11300)
    r:press("absu_az1"); r:step(20)
    eq(r:get("absu_use_second_nav"), 0, "valid VOR1 is not replaced by ILS2")
    eq(r:get("roll_sub_mode"), 4, "VOR1 mode preserved")
end)
test("module reload preserves captured NAV2", function(r)
    r:set("nav_cs_flag_1", 1); r:set("nav_gs_flag_1", 1); r:capture()
    local chunk
    if setfenv then chunk = assert(loadfile(path)); setfenv(chunk, r.env)
    else chunk = assert(loadfile(path, "t", r.env)) end
    chunk(); r:step()
    r:modes(2, 2, 6, 5, "reload initializes selected frequency")
    eq(r:get("absu_use_second_nav"), 1, "NAV2 preserved on reload")
end)
test("invalid frame time cannot trigger false signal-loss reset", function(r)
    r:capture(); r:set("nav_cs_flag_1", 1); r:set("nav_gs_flag_1", 1)
    for _, dt in ipairs({0, -1, 0/0, math.huge}) do r:set("frame_time", dt); r:step(20) end
    r:modes(2, 2, 6, 5, "invalid elapsed time")
end)
print("PASS " .. scenarios .. " mode scenarios, " .. assertions .. " assertions")
