-- Offline tests of the actual AT and throttle modules, including their handover.
-- Usage: fengari at_manual_disconnect_test.lua <aircraft-directory>
local root = assert(arg[1], "Provide aircraft directory")
local folder = root .. "/plugins/sasl/data/modules/Custom Module/"
local assertions, scenarios = 0, 0
local function check(value, message)
    assert(value, message)
    assertions = assertions + 1
end
local function near(actual, expected, tolerance, message)
    check(math.abs(actual - expected) <= tolerance,
        message .. ": " .. tostring(actual) .. " vs " .. tostring(expected))
end
local function fixture()
    local values, writes, commands, plays, playing = {}, {}, {}, {}, {}
    values["sim/version/xplane_internal_version"] = 120000
    for i = 0, 2 do values["tu154/custom/SC/engine/ENGN_thro_" .. i] = 0.4 end
    local function loadModule(path)
        local env = setmetatable({}, {__index = _G})
        local function accessor(path, index) return path .. (index and "#" .. index or "") end
        env.globalProperty = accessor
        env.globalPropertyi, env.globalPropertyf, env.globalPropertyfae = accessor, accessor, accessor
        env.defineProperty = function(name, property) env[name] = assert(property) end
        env.get = function(property) return values[assert(property, "Unknown read")] or 0 end
        env.set = function(property, value)
            assert(property, "Unknown write")
            check(type(value) == "number" and value == value and math.abs(value) < math.huge,
                "Finite output " .. property)
            writes[property] = (writes[property] or 0) + 1
            values[property] = value
        end
        env.bool2int = function(value) return value and 1 or 0 end
        env.clamp = function(value, low, high) return math.max(low, math.min(high, value)) end
        env.safeClamp = function(value, low, high, fallback)
            if type(value) ~= "number" or value ~= value then return fallback or 0 end
            return env.clamp(value, low, high)
        end
        env.line = function(x, x1, y1, x2, y2) return y1 + (x - x1) * (y2 - y1) / (x2 - x1) end
        env.fastInterpolate = function(points, value)
            for i = 2, #points do
                if value <= points[i][1] then
                    return env.line(value, points[i - 1][1], points[i - 1][2], points[i][1], points[i][2])
                end
            end
            return points[#points][2]
        end
        env.print = function() end
        env.sasl = {
            findCommand = function(name) return name end,
            registerCommandHandler = function(command, _, handler) commands[command] = handler end,
            al = {
                loadSample = function(path) return path end,
                playSample = function(sample, looped)
                    check(type(looped) == "boolean", "SASL 3 audio flag")
                    plays[sample] = (plays[sample] or 0) + 1; playing[sample] = true
                end,
                stopSample = function(sample) playing[sample] = false end,
                isSamplePlaying = function(sample) return playing[sample] == true end,
                setSampleGain = function() end,
                setSamplePitch = function() end,
            },
        }
        local chunk
        if setfenv then chunk = assert(loadfile(folder .. path)); setfenv(chunk, env)
        else chunk = assert(loadfile(folder .. path, "t", env)) end
        chunk()
        return env
    end
    local rud = loadModule("engines_system/rud_logic.lua")
    local at = loadModule("main_panel/absu/absu_at.lua")
    local r = {at = at, rud = rud, values = values, writes = writes, commands = commands, modes = {}, plays = plays}
    function r:set(name, value) values[assert(at[name] or rud[name], name)] = value end
    function r:get(name) return values[assert(at[name] or rud[name], name)] or 0 end
    function r:step(count, rudFirst)
        for _ = 1, count or 1 do
            if self.systems and self.systemsFirst then self.systems.after_physics() end
            if rudFirst then rud.update(); at.update() else at.update(); rud.update() end
            if self.systems and not self.systemsFirst then self.systems.after_physics() end
            if self.sounds then self.sounds.update() end
            self.modes[#self.modes + 1] = self:get("stu_mode")
        end
    end
    function r:engage()
        self:set("absu_stab_speed", 0); self:step(12)
        self:set("absu_stab_speed", 1); self:step()
        near(self:get("stu_mode"), 3, 0, "AT engages")
        self:set("absu_stab_speed", 0); self:step(2)
    end
    function r:move(engine, value) self:set("tro_comm_" .. engine, value) end
    function r:attachSystemsAndSound(systemsFirst)
        local bindings, systemWrites = {}, {}
        local env = setmetatable({}, {
            __index = function(_, key)
                if bindings[key] then return values[bindings[key]] or 0 end
                return _G[key]
            end,
            __newindex = function(target, key, value)
                if type(value) == "table" and value.__dataref then
                    bindings[key] = value.__dataref
                elseif bindings[key] then
                    values[bindings[key]] = value
                    systemWrites[bindings[key]] = (systemWrites[bindings[key]] or 0) + 1
                else rawset(target, key, value) end
            end,
        })
        env.getfenv = function() return env end
        env.find_dataref = function(path) return {__dataref = path} end
        env.create_command = function(path) return path end
        env.print = function() end
        values["sim/weapons/Prad"] = {[3] = 0}
        local path = root .. "/plugins/xtlua/init/scripts/T154.systems/T154.systems.lua"
        local chunk
        if setfenv then chunk = assert(loadfile(path)); setfenv(chunk, env)
        else chunk = assert(loadfile(path, "t", env)) end
        chunk()
        self.systems, self.systemsFirst, self.systemWrites = env, systemsFirst, systemWrites
        values["tu154/custom/switchers/eng/fuel_buzzer"] = 1
        values["sim/operation/sound/warning_volume_ratio"] = 1
        self.sounds = loadModule("sounds/cabin_sounds.lua")
    end
    r:set("frame_time", 0.02)
    r:set("ias_left", 300); r:set("ias_right", 300)
    r:set("bus27_volt_left", 27); r:set("bus27_volt_right", 27)
    r:set("bus36_volt_left", 36); r:set("bus115_1_volt", 115)
    r:set("absu_speed_prepare", 1)
    r:set("absu_speed_us_right_left", 1)
    r:set("outside_air_temp", 15); r:set("baro_press", 29.92)
    r:set("engine_egt_redline", 708)
    for i = 1, 3 do r:set("engine_egt_" .. i, 500) end
    r:step(70)
    near(r:get("stu_mode"), 2, 0, "AT ready after preparation")
    return r
end
local function test(name, run)
    run(); scenarios = scenarios + 1; print("PASS " .. name)
end

for engine = 1, 3 do
    test("single physical engine " .. engine .. " releases AT", function()
        local r = fixture(); r:engage(); r:move(engine, 0.46); r:step(6)
        near(r:get("stu_mode"), 2, 0, "one active lever sufficient")
        for i = 1, 3 do near(r:get("rud_" .. i .. "_spd"), 0, 0, "all AT servos released") end
    end)
end

test("common hardware axis releases AT", function()
    local r = fixture(); r:engage()
    for i = 1, 3 do r:move(i, 0.32) end
    r:step(6); near(r:get("stu_mode"), 2, 0, "common throttle movement")
end)

test("small noise and isolated spikes cannot release AT", function()
    local r = fixture(); r:engage()
    for i = 1, 100 do r:move(1, 0.4 + (i % 2 == 0 and 0.015 or -0.015)); r:step() end
    near(r:get("stu_mode"), 3, 0, "jitter ignored")
    r:move(1, 0.9); r:step(); r:move(1, 0.4); r:step(20)
    near(r:get("stu_mode"), 3, 0, "single spike ignored")
end)

test("slow cumulative travel and opposite lever motion are detected", function()
    local r = fixture(); r:engage()
    for i = 1, 12 do r:move(1, 0.4 + i * 0.005); r:step(2) end
    r:step(6); near(r:get("stu_mode"), 2, 0, "slow input is not differentiated frame by frame")
    r:engage(); r:move(1, 0.56); r:move(2, 0.3); r:step(6)
    near(r:get("stu_mode"), 2, 0, "opposite inputs cannot cancel as a sum")
end)

test("engagement baseline and deliberate reengagement do not jump", function()
    local r = fixture()
    for i = 1, 3 do r:move(i, 0.8) end
    r:step(5); r:engage(); r:step(30)
    near(r:get("stu_mode"), 3, 0, "preexisting hardware mismatch is not movement")
    r:move(2, 0.7); r:step(6); near(r:get("stu_mode"), 2, 0, "first release")
    r:engage(); r:step(20); near(r:get("stu_mode"), 3, 0, "new engagement captures new input")
    r:move(2, 0.63); r:step(6); near(r:get("stu_mode"), 2, 0, "later fresh movement releases")
end)

test("holding C gives exactly one transition and cannot reengage after pilot release", function()
    local r = fixture(); r:set("absu_stab_speed", 1); r:step(40)
    near(r:get("stu_mode"), 3, 0, "held engage is not a repeated toggle")
    r:move(1, 0.48); r:step(30)
    near(r:get("stu_mode"), 2, 0, "held button cannot undo manual disconnect")
    r:set("absu_stab_speed", 0); r:step(12); r:set("absu_stab_speed", 1); r:step()
    near(r:get("stu_mode"), 3, 0, "fresh press reengages")
    r:set("absu_stab_speed", 0); r:step(12); r:set("absu_stab_speed", 1); r:step()
    near(r:get("stu_mode"), 2, 0, "fresh press disengages")
end)

test("disabled lever does not disconnect other AT channels", function()
    local r = fixture(); r:set("absu_throt_off_1", 1); r:engage()
    r:move(1, 0.9); r:step(20); near(r:get("stu_mode"), 3, 0, "disconnected channel ignored")
    r:move(2, 0.48); r:step(6); near(r:get("stu_mode"), 2, 0, "remaining active channel releases")
end)

test("SCP slave cannot publish manual release or command release", function()
    local r = fixture(); r:engage(); r:set("ismaster", 1)
    local count = r.writes[r.at.stu_mode]
    r:move(1, 0.9); r:step(20)
    r.commands["sim/engines/throttle_up"](0)
    r.commands["sim/engines/throttle_down"](1)
    near(r:get("stu_mode"), 3, 0, "slave mode unchanged")
    near(r.writes[r.at.stu_mode], count, 0, "slave mode has no writes")
end)

test("authority and remote-throttle handover rebase before detecting new input", function()
    local r = fixture(); r:engage(); r:set("ismaster", 2); r:set("hascontrol_1", 1)
    r:move(1, 0.8); r:step(20)
    near(r:get("stu_mode"), 3, 0, "new remote owner baseline")
    r:move(1, 0.72); r:step(6); near(r:get("stu_mode"), 2, 0, "remote SC pilot can release")
    r:engage(); r:set("control_thro_other", 1); r:move(1, 0.3); r:step(20)
    near(r:get("stu_mode"), 3, 0, "other-throttle authority baseline")
    r:move(1, 0.23); r:step(6); near(r:get("stu_mode"), 2, 0, "new local owner can release")
end)

test("paused frames cannot qualify movement", function()
    local r = fixture(); r:engage(); r:set("sim_paused", 1); r:move(3, 0.5); r:step(30)
    near(r:get("stu_mode"), 3, 0, "paused detector does not advance")
    r:set("sim_paused", 0); r:step(6); near(r:get("stu_mode"), 2, 0, "resume qualifies deliberate input")
end)

test("invalid pilot samples cannot poison movement detector", function()
    local r = fixture(); r:engage(); r:move(1, 0/0); r:step(5); r:move(1, 0.4); r:step(10)
    near(r:get("stu_mode"), 3, 0, "valid recovery rebases without release")
    r:move(1, 0.48); r:step(6); near(r:get("stu_mode"), 2, 0, "detector recovers")
end)

test("manual intervention overrides TOGA", function()
    local r = fixture(); r:engage(); r:set("pitch_main_mode", 2); r:set("absu_landing_on", 1)
    r:set("pitch_sub_mode", 6); r:set("toga_command", 1)
    r:step(); near(r:get("stu_mode"), 4, 0, "TOGA enters")
    r:move(3, 0.32); r:step(6); near(r:get("stu_mode"), 2, 0, "TOGA releases to pilot")
    r:step(10); near(r:get("stu_mode"), 2, 0, "TOGA cannot reengage itself")
    for i = 1, 3 do near(r:get("rud_" .. i .. "_spd"), 0, 0, "TOGA sentinel suppressed after takeover") end
end)

test("power loss and dual failures still release AT", function()
    local r = fixture(); r:engage(); r:set("bus115_1_volt", 0); r:step()
    near(r:get("stu_mode"), 0, 0, "power-off preserved")
    r = fixture(); r:engage(); r:set("absu_at1_fail", 1); r:set("absu_at2_fail", 1); r:step()
    near(r:get("stu_mode"), -1, 0, "total AT failure preserved")
end)

test("keyboard throttle command releases on first press", function()
    local r = fixture(); r:engage(); r.commands["sim/engines/throttle_down"](0); r:step()
    near(r:get("stu_mode"), 2, 0, "command begin releases")
end)

for _, rudFirst in ipairs({false, true}) do
    test("real AT servo separation and stopped-input handover, rudFirst=" .. tostring(rudFirst), function()
        local r = fixture(); r:engage(); r:set("ias_yellow_left", 390)
        r:step(100, rudFirst)
        near(r:get("stu_mode"), 3, 0, "automatic movement never disconnects")
        check(math.abs(r:get("anim_rud1") - 0.4) > 0.1, "actual rud module moved virtual lever")
        for i = 1, 3 do
            near(r:get("tro_comm_" .. i), 0.4, 0, "servo never modifies SC pilot input")
            check(not r.writes[r.at["tro_comm_" .. i]], "no servo write to pilot command")
            r:move(i, 0.3)
        end
        r:step(8, rudFirst)
        near(r:get("stu_mode"), 2, 0, "pilot movement qualified")
        for i = 1, 3 do near(r:get("anim_rud" .. i), 0.3, 1e-10, "stopped physical input handed over") end
    end)
end

test("zero instantaneous servo speed cannot hand controls over while AT still engaged", function()
    local r = fixture(); r:engage(); r:move(1, 0.7)
    local before = r:get("anim_rud1")
    r:set("rud_1_spd", 0); r.rud.update()
    near(r:get("anim_rud1"), before, 1e-12, "AT still owns lever at zero PD rate")
end)

test("command disconnect before AT update gives pilot priority over stale servo rate", function()
    local r = fixture(); r:engage(); r:set("ias_yellow_left", 390); r:step(30)
    check(r:get("rud_1_spd") ~= 0, "servo rate exists before command callback")
    for i = 1, 3 do r:move(i, 0.2) end
    r.rud.update() -- Read the pilot movement while AT still owns the levers.
    r.commands["sim/engines/throttle_down"](0)
    r.rud.update() -- Deliberately precedes AT's clearing of its old servo rates.
    for i = 1, 3 do near(r:get("anim_rud" .. i), 0.2, 1e-10, "pending input beats stale servo") end
end)

test("existing XP12 proportional and derivative gains are retained", function()
    local r = fixture(); r:engage()
    local smoothed
    for index = 1, 100 do
        local name, value = debug.getupvalue(r.at.update, index)
        if name == "IAS_smth" then smoothed = value; break end
    end
    check(smoothed ~= nil, "actual controller IAS state found")
    r:set("frame_time", 0); r:set("ias_yellow_left", smoothed + 10); r:step()
    local value = r:get("rud_1_spd")
    check(value >= 10 * 0.008 * 1.2 * 0.98 - 1e-12 and value <= 10 * 0.008 * 1.2 * 1.02 + 1e-12,
        "XP12 K_P = 0.008 with original channel spread")
    r:set("frame_time", 0.02); r:set("ias_left", smoothed); r:set("ias_yellow_left", smoothed)
    r.at.IAS_last = smoothed - 0.02; r:step()
    value = r:get("rud_1_spd")
    check(value >= -0.05 * 1.2 * 1.02 - 1e-10 and value <= -0.05 * 1.2 * 0.98 + 1e-10,
        "XP12 K_D = -0.05 with original channel spread")
end)

for _, systemsFirst in ipairs({false, true}) do
    test("actual xTlua, SASL AT and sound preserve held-button engagement, systemsFirst=" .. tostring(systemsFirst), function()
        local r = fixture(); r:attachSystemsAndSound(systemsFirst)
        r:set("absu_stab_speed", 1); r:step(40)
        near(r:get("stu_mode"), 3, 0, "held C stays engaged across both plugins")
        near(r.plays["Custom Sounds/short_speaker.wav"] or 0, 0, 0, "actual engagement has no AP OFF")
        r:move(1, 0.48); r:step(40)
        near(r:get("stu_mode"), 2, 0, "held C cannot undo takeover across both plugins")
        near(r.plays["Custom Sounds/short_speaker.wav"] or 0, 1, 0, "manual disconnect still warns once")
        check(not r.systemWrites[r.at.stu_mode], "xTlua never competes for AT mode")
        r:engage(); r:step(20)
        near(r.plays["Custom Sounds/short_speaker.wav"] or 0, 1, 0, "reengage remains silent")
    end)
end

print("PASS AT manual disconnect: " .. scenarios .. " scenarios, " .. assertions .. " assertions; actual modules, mocked simulator")
