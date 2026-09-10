-- Offline wiring regression: native NAV -> CourseMP -> ABSU modes -> actuators.
-- This exercises real modules with shared mocked DataRefs, not flight dynamics.
local root = assert(arg[1], "Provide the aircraft directory")
local panel = root .. "/plugins/sasl/data/modules/Custom Module/main_panel/"
local checks, checked_frames, scenarios = 0, 0, 0

local function equal(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end
local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end
local function load_module(path, env)
    local chunk
    if setfenv then chunk = assert(loadfile(path)); setfenv(chunk, env)
    else chunk = assert(loadfile(path, "t", env)) end
    chunk()
end

local function simulation()
    local values, handlers = {}, {}
    local function environment(overrides)
        local env = {}
        for name, property in pairs(overrides or {}) do env[name] = property end
        setmetatable(env, {__index = _G})
        local function noop() return 0 end
        env.sasl = {
            al = {loadSample = noop, playSample = noop, setSampleGain = noop},
            gl = {loadFont = noop, setFontGlyphSpacingFactor = noop, drawText = noop},
            findCommand = function(name) return name end,
            registerCommandHandler = function(name, _, fn) handlers[name] = fn end,
        }
        env.SASL_COMMAND_BEGIN, env.SASL_COMMAND_CONTINUE = 0, 1
        env.globalPropertyf = function(path) return path end
        env.globalPropertyi, env.globalProperty = env.globalPropertyf, env.globalPropertyf
        env.defineProperty = function(name, property)
            if rawget(env, name) == nil then env[name] = property end
        end
        env.get = function(property) return values[assert(property, "nil property read")] or 0 end
        env.set = function(property, value) values[assert(property, "nil property write")] = value end
        env.bool2int = function(value) return value and 1 or 0 end
        env.sign = function(value) return value > 0 and 1 or value < 0 and -1 or 0 end
        env.clamp = function(value, low, high) return math.max(low, math.min(high, value)) end
        env.safeClamp = function(value, low, high, fallback)
            if type(value) ~= "number" or value ~= value then return fallback or 0 end
            return env.clamp(value, low, high)
        end
        env.line = function(value, x1, y1, x2, y2)
            return y1 + (value - x1) * (y2 - y1) / (x2 - x1)
        end
        env.fastInterpolate = function(points, value)
            if value <= points[1][1] then return points[1][2] end
            for i = 2, #points do
                if value <= points[i][1] then
                    return env.line(value, points[i-1][1], points[i-1][2], points[i][1], points[i][2])
                end
            end
            return points[#points][2]
        end
        -- Fixtures only use these two real ILS channels; VOR is explicitly false.
        env.isILS = function(frequency) return frequency == 11030 or frequency == 11050 end
        env.math = setmetatable({random = function(a) return a or 1 end}, {__index = math})
        return env
    end

    local host = environment()
    setmetatable(host, {__index = function(_, key)
        if _G[key] ~= nil then return _G[key] end
        return function(properties) return {kind = key, properties = properties} end
    end})
    load_module(panel .. "radio/radio.lua", host)
    local nav2_overrides
    for _, component in ipairs(host.components) do
        if component.kind == "course_mp" and component.properties.frequency then
            nav2_overrides = component.properties
        end
    end
    assert(nav2_overrides, "NAV2 actual component bindings missing")

    local nav1, nav2, mode, controls = environment(), environment(nav2_overrides), environment(), environment()
    load_module(panel .. "radio/course_mp.lua", nav1)
    load_module(panel .. "radio/course_mp.lua", nav2)
    load_module(panel .. "absu/absu_mode.lua", mode)
    load_module(panel .. "absu/absu_controls.lua", controls)

    local r = {nav = {nav1, nav2}, mode = mode, controls = controls}
    function r:set(env, name, value) values[assert(rawget(env, name), name)] = value end
    function r:get(env, name) return env.get(assert(rawget(env, name), name)) end
    function r:step(frames)
        for _ = 1, frames or 1 do
            nav1.update(); nav2.update(); mode.update(); controls.update()
            for _, name in ipairs({"absu_contr_roll", "absu_contr_pitch", "absu_contr_yaw"}) do
                local value = self:get(controls, name)
                assert(finite(value) and math.abs(value) <= 0.40000001, name .. " finite bounded actuator")
            end
            checked_frames = checked_frames + 1
        end
    end
    function r:press(name)
        self:set(mode, name, 1); self:step(); self:set(mode, name, 0); self:step()
    end
    function r:modes(roll, pitch, lateral, vertical, label)
        equal(self:get(mode, "roll_main_mode"), roll, label .. " roll AP")
        equal(self:get(mode, "pitch_main_mode"), pitch, label .. " pitch AP")
        equal(self:get(mode, "roll_sub_mode"), lateral, label .. " LOC")
        equal(self:get(mode, "pitch_sub_mode"), vertical, label .. " GS")
    end
    function r:capture()
        self:step(20); self:press("absu_app"); self:press("absu_gs")
        self:modes(2, 2, 6, 5, "native signal captured through full chain")
    end

    for _, name in ipairs({"bus27_volt_left", "bus27_volt_right"}) do r:set(mode, name, 27) end
    for _, name in ipairs({"bus115_1_volt", "bus115_3_volt"}) do r:set(mode, name, 115) end
    for _, name in ipairs({"bus36_volt_left", "bus36_volt_right", "bus36_volt_pts250_1", "bus36_volt_pts250_2"}) do
        r:set(mode, name, 36)
    end
    for _, axis in ipairs({"ail", "elev", "rud"}) do
        for i = 1, 3 do r:set(mode, "hydro_ra56_" .. axis .. "_" .. i, 1) end
    end
    for i = 1, 3 do r:set(mode, "gs_press_" .. i, 200) end
    for _, name in ipairs({"sau_stu_on", "absu_roll_ch_on", "absu_pitch_ch_on", "absu_landing_on", "absu_needles_on", "svs_on"}) do
        r:set(mode, name, 1)
    end
    for _, env in ipairs(r.nav) do
        r:set(env, "curs_np_on", 1)
        r:set(env, "frequency", 11030)
        r:set(env, "cs_signal", 1)
        r:set(env, "gs_flag", 1)
        r:set(env, "cr_flag", 0)
        r:set(env, "v_plank", 0.25)
        r:set(env, "h_plank", 0.10)
        r:set(env, "obs", 180)
    end
    r:set(mode, "frame_time", 0.02)
    r:set(mode, "rv5_alt", 500)
    r:set(controls, "mach_svs", 0.24)
    r:set(controls, "ias", 165)
    r:set(controls, "alt_svs", 500)
    r:set(controls, "bkk_pitch", 3)
    r:set(controls, "course_gpk", 180)
    r:set(controls, "pkp_obs_1", 180)
    r:set(controls, "pkp_obs_2", 180)
    r:step(20); r:press("absu_stab")
    r:modes(2, 2, 1, 1, "powered stabilization")
    return r
end

local function test(name, fn)
    fn(simulation()); scenarios = scenarios + 1; print("PASS " .. name)
end

test("native NAV1 chain remains captured", function(r)
    equal(r:get(r.nav[1], "nav_pow_cc"), 1, "receiver publishes actual power")
    equal(r:get(r.nav[1], "nav_cs_flag"), 0, "native LOC publishes valid custom signal")
    equal(r:get(r.nav[1], "nav_gs_flag"), 0, "native GS publishes valid custom signal")
    r:capture(); r:step(3000)
    r:modes(2, 2, 6, 5, "one minute captured with finite controls")
end)

test("brief native loss never switches source or drops AP", function(r)
    r:capture(); r:step(250)
    for _ = 1, 10 do
        r:set(r.nav[1], "cs_signal", 0); r:set(r.nav[1], "gs_flag", 0)
        r:set(r.nav[1], "v_plank", 0/0); r:set(r.nav[1], "h_plank", math.huge)
        r:step(20)
        equal(r:get(r.nav[1], "nav_cs_flag"), 1, "real LOC loss stays visible")
        equal(r:get(r.nav[1], "nav_gs_flag"), 1, "real GS loss stays visible")
        equal(r:get(r.nav[1], "nav_cs"), 0, "invalid LOC not fabricated")
        equal(r:get(r.nav[1], "nav_gs"), 0, "invalid GS not fabricated")
        equal(r:get(r.mode, "absu_use_second_nav"), 0, "no NAV2 source switch during grace")
        r:modes(2, 2, 6, 5, "0.4 second native gap")
        r:set(r.nav[1], "cs_signal", 1); r:set(r.nav[1], "gs_flag", 1)
        r:set(r.nav[1], "v_plank", -0.25); r:set(r.nav[1], "h_plank", -0.1)
        r:step(30)
        r:modes(2, 2, 6, 5, "native recovery remains captured")
    end
    equal(r:get(r.mode, "absu_fail_signal"), 0, "no false disconnection alarm")
end)

test("native NAV2 approach ignores broken NAV1", function(r)
    r:set(r.nav[1], "nav_fail", 1)
    r:capture(); r:step(500)
    equal(r:get(r.nav[1], "nav_cs_flag"), 1, "NAV1 truly invalid")
    equal(r:get(r.nav[2], "nav_cs_flag"), 0, "NAV2 truly valid")
    equal(r:get(r.mode, "absu_use_second_nav"), 1, "NAV2 selected")
    r:modes(2, 2, 6, 5, "broken primary does not disengage secondary")
    r:set(r.nav[1], "nav_fail", 0); r:step(100)
    equal(r:get(r.mode, "absu_use_second_nav"), 1, "primary recovery does not switch captured source")
    r:modes(2, 2, 6, 5, "NAV2 remains captured")
end)

test("native GS loss disengages once and never silently recaptures", function(r)
    r:set(r.mode, "flap_inn_L", 45); r:set(r.mode, "flap_inn_R", 45)
    r:set(r.nav[1], "h_plank", 0)
    r:step(20); r:press("absu_app")
    r:modes(2, 2, 6, 5, "automatic GS capture from native centered beam")
    r:set(r.nav[1], "gs_flag", 0)
    local previous, exits = 5, 0
    for _ = 1, 150 do
        r:step()
        local current = r:get(r.mode, "pitch_sub_mode")
        if previous == 5 and current ~= 5 then exits = exits + 1 end
        previous = current
    end
    equal(exits, 1, "one GS disengagement")
    r:modes(2, 1, 6, 1, "sustained native GS loss releases pitch only")
    r:set(r.nav[1], "gs_flag", 1); r:step(500)
    equal(r:get(r.nav[1], "nav_gs_flag"), 0, "native GS recovered")
    r:modes(2, 1, 6, 1, "recovered centered GS does not recapture automatically")
end)

print("PASS " .. scenarios .. " integration scenarios, " .. checks .. " assertions, " .. checked_frames .. " frames with 3 bounded finite actuators")
