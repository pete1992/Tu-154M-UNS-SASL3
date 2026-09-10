-- Offline ABSU guidance regression tests; no simulator connection.
local root = assert(arg[1], "Provide the aircraft directory")
local path = root .. "/plugins/sasl/data/modules/Custom Module/main_panel/absu/absu_controls.lua"
local scenarios = 0

local function controller()
    local env, values = {}, {}
    setmetatable(env, {__index = _G})
    env.defineProperty = function(name, property) env[name] = property end
    env.globalPropertyf = function(property) return property end
    env.globalPropertyi, env.globalProperty = env.globalPropertyf, env.globalPropertyf
    env.get = function(property)
        assert(property, "Undefined property")
        return values[property] or 0
    end
    env.set = function(property, value)
        assert(property, "Undefined write")
        assert(type(value) == "number" and value == value and math.abs(value) < math.huge,
            "Invalid write: " .. property)
        values[property] = value
    end
    -- Match the shared main.lua/functions.lua helpers, including infinity clamping.
    env.clamp = function(value, low, high)
        if value ~= value then return low end
        if value < low then return low end
        if value > high then return high end
        return value
    end
    env.safeClamp = function(value, low, high, default)
        if type(value) ~= "number" or value ~= value then return default or 0 end
        return env.clamp(value, low, high)
    end
    env.sign = function(value) return value > 0 and 1 or (value < 0 and -1 or 0) end
    env.bool2int = function(value) return value and 1 or 0 end
    env.line = function(x, x1, y1, x2, y2)
        return y1 + (x - x1) * (y2 - y1) / (x2 - x1)
    end
    env.fastInterpolate = function(points, value)
        for i = 2, #points do
            if value <= points[i][1] then
                return env.line(value, points[i - 1][1], points[i - 1][2], points[i][1], points[i][2])
            end
        end
        return points[#points][2]
    end
    -- Test frequencies: 110.30 and 109.50 are ILS; 113.00 is VOR.
    env.isILS = function(frequency) return frequency == 11030 or frequency == 10950 end
    values["tu154/custom/bkk/bkk_pitch"] = 2
    values["tu154/custom/svs/machno"] = 0.28
    values["sim/cockpit2/gauges/indicators/airspeed_kts_pilot"] = 150
    values["tu154/custom/svs/altitude"] = 1000

    local chunk
    if setfenv then
        chunk = assert(loadfile(path)); setfenv(chunk, env)
    else
        chunk = assert(loadfile(path, "t", env))
    end
    chunk()
    local state
    for i = 1, 100 do
        local name, value = debug.getupvalue(env.update, i)
        if not name then break end
        if name == "S" then state = value end
    end
    assert(state, "Controller state missing")
    local r = {env = env, state = state}
    function r:set(name, value) values[assert(env[name], name)] = value end
    function r:get(name) return env.get(assert(env[name], name)) end
    function r:step(count) for _ = 1, count or 1 do env.update() end end

    r:set("frame_time", 1 / 60)
    r:set("roll_main_mode", 2); r:set("pitch_main_mode", 2)
    r:set("roll_sub_mode", 6); r:set("pitch_sub_mode", 5)
    r:set("freq_1", 11030); r:set("freq_2", 11030)
    r:set("nav_cs_1", 0.2); r:set("nav_cs_2", 0.2)
    r:set("absu_landing_on", 1); r:set("absu_needles_on", 1); r:set("absu_nav_on", 1)
    r:set("rv5_alt", 1000)
    for i = 1, 3 do
        r:set("gs_press_" .. i, 100)
        for _, axis in ipairs({"elev", "ail", "rud"}) do
            r:set("hydro_ra56_" .. axis .. "_" .. i, 1)
        end
    end
    return r
end

local function near(actual, expected, tolerance)
    assert(math.abs(actual - expected) <= tolerance,
        tostring(actual) .. " versus " .. tostring(expected))
end
local function test(name, run)
    run(controller())
    scenarios = scenarios + 1
    print("PASS " .. name)
end

test("script syntax and full mocked update", function(r)
    r:step()
end)

test("constant LOC has usable command authority", function(r)
    r:step(600)
    assert(r.state.ILS_roll_need > 7 and r:get("absu_contr_roll") > 0.3)
end)

test("LOC command invariant across 30 60 120 FPS", function()
    local targets = {}
    for _, fps in ipairs({30, 60, 120}) do
        local r = controller()
        r:set("frame_time", 1 / fps); r:step(fps * 8)
        targets[#targets + 1] = r.state.ILS_roll_need
    end
    near(targets[1], targets[2], 0.01)
    near(targets[2], targets[3], 0.01)
end)

test("GS capture preserves established LOC authority", function(r)
    r:set("pitch_sub_mode", 4); r:step(600)
    local target = r.state.ILS_roll_need
    r:set("pitch_sub_mode", 5); r:step()
    near(r.state.ILS_roll_need, target, 0.01)
end)

test("LOC dropout holds target and reacquires without derivative kick", function(r)
    r:step(300)
    local target = r.state.ILS_roll_need
    r:set("nav_cs_flag_1", 1); r:set("nav_cs_1", 0); r:step(30)
    near(r.state.ILS_roll_need, target, 1e-9)
    r:set("nav_cs_flag_1", 0); r:set("nav_cs_1", 0.2); r:step()
    near(r.state.ILS_spd_last, 0, 1e-9)
end)

test("GS dropout holds pitch and resets slope on recovery", function(r)
    r:set("nav_gs_1", 0.2); r:step(240)
    local target = r.state.GS_pitch_need
    r:set("nav_gs_flag_1", 1); r:set("nav_gs_1", 0); r:step(30)
    near(r.state.GS_pitch_need, target, 1e-9)
    r:set("nav_gs_flag_1", 0); r:set("nav_gs_1", 0.2); r:step()
    near(r.state.GS_smth, r.state.GS_last, 1e-9)
    assert(math.abs(r.state.GS_pitch_need - target) < 0.1)
end)

test("NAV2 uses healthy NAV2 with NAV1 failed", function(r)
    r:set("absu_use_second_nav", 1); r:set("freq_1", 11300)
    r:set("nav_cs_flag_1", 1); r:set("nav_gs_flag_1", 1); r:set("man_roll_lamp", 1)
    r:step(300)
    assert(r.state.loc_guidance_valid and r.state.gs_guidance_valid)
    assert(r:get("absu_roll_flag") == 0)
end)

test("selected NAV2 failure never borrows NAV1 guidance", function(r)
    r:set("absu_use_second_nav", 1); r:step(300)
    r:set("nav_cs_flag_2", 1); r:set("nav_gs_flag_2", 1); r:step()
    assert(not r.state.loc_guidance_valid and not r.state.gs_guidance_valid)
    near(r:get("absu_roll_ind"), 0, 1e-9)
    near(r:get("absu_pitch_ind"), 0, 1e-9)
end)

test("frequency change clears stale guidance derivative", function(r)
    r:step(300)
    r:set("freq_1", 10950); r:set("nav_cs_1", -0.2); r:step()
    near(r.state.ILS_spd_last, 0, 1e-9)
    assert(r.state.ILS_roll_need < 0)
end)

test("mode exit drops held approach targets", function(r)
    r:step(300)
    r:set("roll_sub_mode", 1); r:set("pitch_sub_mode", 1); r:step()
    near(r.state.ILS_roll_need, r.state.roll_now, 1e-9)
    near(r.state.GS_pitch_need, r.state.pitch_now, 1e-9)
    assert(not r.state.loc_guidance_valid and not r.state.gs_guidance_valid)
end)

test("frame hitch leaves hydraulic outputs bounded", function(r)
    r:step(300)
    r:set("frame_time", 2); r:set("nav_cs_1", -1.2); r:set("nav_gs_1", 1); r:step()
    assert(math.abs(r:get("absu_contr_roll")) <= 0.4 and math.abs(r:get("absu_contr_pitch")) <= 0.4)
    near(r.state.passed, 0.1, 1e-9)
end)

test("invalid clock input does not create invalid outputs", function(r)
    r:set("frame_time", 0 / 0); r:step(); near(r.state.passed, 0, 1e-9)
    r:set("frame_time", -1); r:step(); near(r.state.passed, 0, 1e-9)
    r:set("frame_time", math.huge); r:step(); near(r.state.passed, 0.1, 1e-9)
end)

test("controller never rewrites AP modes", function(r)
    r:step(300)
    r:set("nav_cs_flag_1", 1); r:set("nav_gs_flag_1", 1); r:step(180)
    assert(r:get("roll_main_mode") == 2 and r:get("pitch_main_mode") == 2)
    assert(r:get("roll_sub_mode") == 6 and r:get("pitch_sub_mode") == 5)
end)

print(scenarios .. " control scenarios passed")
