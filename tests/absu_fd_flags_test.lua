-- absu_fd_flags_test.lua
-- Offline regression test of the real SASL mode and controller components.
-- Native APIs/DataRefs are mocked; this is not an in-simulator flight test.
-- Run with LuaJIT from the aircraft root, or pass the root as argument 1.

local root = (arg[1] or "."):gsub("\\", "/"):gsub("/$", "")
local base = root .. "/plugins/sasl/data/modules/Custom Module/main_panel/absu/"
local checks = 0

local function equal(actual, expected, label)
    checks = checks + 1
    assert(actual == expected, label .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
end

local function runtime(fps, receiver)
    local rt = { values = {}, fps = fps, receiver = receiver }
    local function environment()
        local env = setmetatable({}, { __index = _G })
        env.globalPropertyf = function(path) return path end
        env.globalPropertyi = env.globalPropertyf
        env.globalProperty = env.globalPropertyf
        env.defineProperty = function(name, path)
            env[name] = path
            if rt.values[path] == nil then rt.values[path] = 0 end
        end
        env.get = function(path) return assert(rt.values[path], "Unbound mock DataRef: " .. tostring(path)) end
        env.set = function(path, value)
            assert(rt.values[path] ~= nil, "Unbound output: " .. tostring(path))
            rt.values[path] = value
        end
        env.bool2int = function(value) return value and 1 or 0 end
        env.clamp = function(value, low, high) return math.max(low, math.min(high, value)) end
        env.safeClamp = function(value, low, high, fallback)
            if type(value) ~= "number" or value ~= value then return fallback end
            return env.clamp(value, low, high)
        end
        env.sign = function(value) return value < 0 and -1 or value > 0 and 1 or 0 end
        env.line = function(value, x1, y1, x2, y2)
            return y1 + (value - x1) / (x2 - x1) * (y2 - y1)
        end
        env.fastInterpolate = function(points, value)
            for i = 2, #points do
                if value <= points[i][1] then
                    return env.line(value, points[i - 1][1], points[i - 1][2], points[i][1], points[i][2])
                end
            end
            return points[#points][2]
        end
        -- Only the two explicit test frequencies are used; RF reception is mocked.
        env.isILS = function(frequency) return frequency == 11030 end
        env.sasl = { findCommand = function(name) return name end, registerCommandHandler = function() end }
        env.SASL_COMMAND_BEGIN, env.SASL_COMMAND_CONTINUE = 0, 1
        return env
    end

    rt.mode, rt.controls = environment(), environment()
    for _, component in ipairs({ { rt.mode, "absu_mode.lua" }, { rt.controls, "absu_controls.lua" } }) do
        local chunk = assert(loadfile(base .. component[2]))
        setfenv(chunk, component[1])
        chunk()
    end
    function rt:put(name, value)
        self.values[assert(self.mode[name] or self.controls[name], name)] = value
    end
    function rt:get(name)
        return self.values[assert(self.mode[name] or self.controls[name], name)]
    end
    function rt:tick(frames)
        for _ = 1, frames or 1 do self.mode.update(); self.controls.update() end
    end
    function rt:flags(roll, pitch, label)
        equal(self:get("absu_roll_flag"), roll, label .. " roll")
        equal(self:get("absu_pitch_flag"), pitch, label .. " pitch")
    end
    function rt:engage()
        -- Exercise the actual input edges and capture rules; never set modes,
        -- warning lamps or FD outputs directly in the end-to-end regression.
        self:put("absu_app", 1)
        self:put("absu_gs", 1)
        self:put("absu_stab", 1)
        self:tick()
        self:put("absu_app", 0)
        self:put("absu_gs", 0)
        self:put("absu_stab", 0)
        self:tick(self.fps)
        equal(self:get("roll_main_mode"), 2, "Roll AP engaged")
        equal(self:get("pitch_main_mode"), 2, "Pitch AP engaged")
        equal(self:get("roll_sub_mode"), 6, "LOC captured")
        equal(self:get("pitch_sub_mode"), 5, "GS captured")
        equal(self:get("absu_use_second_nav"), self.receiver - 1, "Selected ILS receiver")
    end

    local inputs = {
        frame_time = 1 / fps, katet_nav_mode = 1, katet_mode = 0, sau_stu_on = 1,
        absu_pitch_ch_on = 1, absu_roll_ch_on = 1, absu_needles_on = 1,
        freq_1 = 11300, freq_2 = 11300,
        nav_cs_flag_1 = 1, nav_gs_flag_1 = 1, nav_cs_flag_2 = 1, nav_gs_flag_2 = 1,
        nav_power_1 = 1, nav_power_2 = 1, rv5_alt = 500, ias = 150,
        mach_svs = 0.25, alt_svs = 1000,
        gs_press_1 = 210, gs_press_2 = 210, gs_press_3 = 210,
        bus27_volt_left = 27, bus27_volt_right = 27, bus115_3_volt = 115,
        bus36_volt_left = 36, bus36_volt_right = 36, bus36_volt_pts250_1 = 36,
    }
    for _, axis in ipairs({ "rud", "ail", "elev" }) do
        for number = 1, 3 do inputs["hydro_ra56_" .. axis .. "_" .. number] = 1 end
    end
    inputs["freq_" .. receiver] = 11030
    inputs["nav_cs_flag_" .. receiver] = 0
    inputs["nav_gs_flag_" .. receiver] = 0
    for name, value in pairs(inputs) do rt:put(name, value) end
    rt:tick(fps)
    return rt
end

local function recovered_approach(fps, receiver)
    local rt = runtime(fps, receiver)
    rt:flags(1, 1, "No guidance immediately after loading")
    rt:engage()
    rt:flags(0, 0, "First valid approach")
    equal(rt:get("man_roll_lamp"), 0, "No initial roll warning")
    equal(rt:get("man_pitch_lamp"), 0, "No initial pitch warning")

    rt:put("nav_cs_flag_" .. receiver, 1)
    rt:put("nav_gs_flag_" .. receiver, 1)
    rt:tick(6 * fps)
    equal(rt:get("roll_main_mode"), 1, "LOC loss releases roll AP")
    equal(rt:get("pitch_main_mode"), 1, "GS loss releases pitch AP")
    equal(rt:get("man_roll_lamp"), 1, "LOC loss latches roll warning")
    equal(rt:get("man_pitch_lamp"), 1, "GS loss latches pitch warning")
    rt:flags(1, 1, "Both signals lost")

    rt:put("nav_cs_flag_" .. receiver, 0)
    rt:put("nav_gs_flag_" .. receiver, 0)
    rt:tick(fps)
    rt:engage()
    equal(rt:get("man_roll_lamp"), 1, "Roll warning retains acknowledgement semantics")
    equal(rt:get("man_pitch_lamp"), 1, "Pitch warning retains acknowledgement semantics")
    rt:flags(0, 0, "Valid recapture despite two retained warnings")
    equal(rt:get("absu_roll_ind"), 0, "Valid roll guidance is not parked")
    equal(rt:get("absu_pitch_ind"), 0, "Valid pitch guidance is not parked")
    rt:tick(10 * fps)
    rt:flags(0, 0, "Recaptured flags remain clear")
    return rt
end

for _, fps in ipairs({ 20, 60, 120 }) do
    for receiver = 1, 2 do recovered_approach(fps, receiver) end
end

for receiver = 1, 2 do
    local rt = recovered_approach(60, receiver)
    -- Isolate the controller's current-fault checks from mode cancellation here.
    -- The retained lamp states arise from real mode-layer signal loss above.
    local cases = {
        { "Roll calculator failure", { absu_calc_roll_fail = 1 }, 1, 0 },
        { "Pitch calculator failure", { absu_calc_pitch_fail = 1 }, 0, 1 },
        { "Selected LOC failure", { ["nav_cs_flag_" .. receiver] = 1 }, 1, 0 },
        { "Selected GS failure", { ["nav_gs_flag_" .. receiver] = 1 }, 0, 1 },
        { "Both TKS failed", { tks_fail_left = 1, tks_fail_right = 1 }, 1, 0 },
        { "STU test", { absu_speed_test_2 = 1 }, 1, 1 },
        { "FD explicitly off", { absu_needles_on = 0 }, 1, 1 },
    }
    for _, case in ipairs(cases) do
        local old = {}
        for name, value in pairs(case[2]) do old[name] = rt:get(name); rt:put(name, value) end
        rt.controls.update()
        rt:flags(case[3], case[4], case[1])
        for name, value in pairs(old) do rt:put(name, value) end
        rt.controls.update()
        rt:flags(0, 0, case[1] .. " cleared")
    end

    -- Shared-cockpit slaves must not overwrite the synchronized FD outputs.
    local roll, pitch = rt:get("absu_roll_flag"), rt:get("absu_pitch_flag")
    rt:put("ismaster", 1)
    rt:put("absu_speed_test_2", 1)
    rt.controls.update()
    rt:flags(roll, pitch, "Slave does not publish test flags")
    rt:put("ismaster", 0)
    rt.controls.update()
    rt:flags(1, 1, "Master publishes test flags")
    rt:put("absu_speed_test_2", 0)

    rt.mode.onAirportLoaded()
    rt.controls.onAirportLoaded()
    rt:tick()
    rt:flags(1, 1, "New flight has no old guidance")
    equal(rt:get("man_roll_lamp"), 0, "New flight resets roll warning")
    equal(rt:get("man_pitch_lamp"), 0, "New flight resets pitch warning")
end

print("PASS: " .. checks .. " offline ABSU FD assertions (real mode/controller, mocked native API)")
