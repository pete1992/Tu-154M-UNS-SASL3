-- Offline SASL mock: real arm406.lua, no X-Plane connection or audio playback.
local root = assert(arg[1], "Provide the aircraft directory")
local filename = root .. "/plugins/sasl/data/modules/Custom Module/main_panel/arm406.lua"
local prefix = "tu154/custom/arm406/"
local paths = {
    enable = "tu154/custom/switchers/ovhd/arm406",
    test = "tu154/custom/buttons/console/pdu406_control",
    mute = "tu154/custom/buttons/console/pdu406_sound_off",
    left = "tu154/custom/elec/bus27_volt_left",
    right = "tu154/custom/elec/bus27_volt_right",
    dt = "tu154/custom/time/frame_time",
    paused = "sim/time/paused",
    outside = "sim/graphics/view/view_is_external",
    sound = "sim/operation/sound/sound_on",
    volume = "sim/operation/sound/warning_volume_ratio",
}
local assertions, scenarios = 0, 0
local function eq(a, b, message)
    assert(a == b, (message or "value") .. ": " .. tostring(a) .. " ~= " .. tostring(b))
    assertions = assertions + 1
end

local function controller(missing_audio)
    local values, created, commands, playing, gains, plays = {}, {}, {}, {}, {}, {}
    for _, path in pairs(paths) do values[path] = 0 end
    values[paths.volume], values[paths.sound] = 1, 1
    values["tu154/custom/lights/button/dejur_contr"] = 0
    values["tu154/custom/lights/button/sound_off"] = 0
    local env = setmetatable({}, {__index = _G})
    env.globalPropertyi = function(path)
        assert(values[path] ~= nil, "Unresolved binding: " .. path)
        return path
    end
    env.globalPropertyf = env.globalPropertyi
    env.createGlobalPropertyi = function(path, default)
        assert(values[path] == nil and path:sub(1, #prefix) == prefix, "Duplicate/out-of-scope DataRef")
        values[path], created[path] = default, true
        return path
    end
    env.createGlobalPropertyf = env.createGlobalPropertyi
    env.defineProperty = function(name, prop) env[name] = prop end
    env.get = function(prop) return assert(values[prop], "Unknown property: " .. tostring(prop)) end
    env.set = function(prop, value)
        assert(values[prop] ~= nil, "Unknown write: " .. tostring(prop))
        assert(prop:sub(1, 4) ~= "sim/", "Must not write native radios or aircraft state")
        values[prop] = value
    end
    local sample = "Custom Sounds/arm406_monitor.wav"
    env.sasl = {
        createCommand = function(name, description)
            assert(not commands[name] and type(description) == "string")
            commands[name] = {}; return name
        end,
        registerCommandHandler = function(name, before, handler) commands[name].handler = handler end,
        al = {
            loadSample = function(path) if not missing_audio then return path end end,
            setSampleGain = function(path, gain)
                assert(path and gain >= 0 and gain <= 600); gains[path] = gain
            end,
            isSamplePlaying = function(path) assert(path); return playing[path] == true end,
            playSample = function(path, loop)
                assert(path); playing[path] = true; plays[path] = (plays[path] or 0) + 1
                eq(loop, path == sample, "Only the monitor loops")
            end,
            stopSample = function(path) assert(path); playing[path] = false end,
        },
    }
    local chunk
    if setfenv then chunk = assert(loadfile(filename)); setfenv(chunk, env)
    else chunk = assert(loadfile(filename, "t", env)) end
    chunk()
    local r = {values = values, playing = playing, plays = plays, gains = gains, sample = sample}
    local function resolve(key) return paths[key] or prefix .. key end
    function r:set(key, value) values[resolve(key)] = value end
    function r:get(key) return values[resolve(key)] end
    function r:step(dt, count)
        self:set("dt", dt or 0.25)
        for _ = 1, count or 1 do env.update() end
    end
    function r:power(left, right)
        self:set("enable", 1); self:set("left", left or 27); self:set("right", right or 0); self:step()
    end
    function r:press(key, steps)
        self:set(key, 1); self:step(0.25, steps or 1); self:set(key, 0); self:step(0)
    end
    function r:activate() self:press("manual_button", 8) end
    function r:command(name, phase) eq(commands["tu154/arm406/" .. name].handler(phase), 0, "Command consumed") end
    function r:shutdown() env.onModuleShutdown() end
    function r:silent() return not playing[sample] end
    return r
end
local function test(name, fn, missing_audio)
    fn(controller(missing_audio)); scenarios = scenarios + 1; print("PASS " .. name)
end

test("cold and dark never tests or transmits automatically", function(r)
    r:step(0.25, 200); eq(r:get("mode"), 0); eq(r:get("tx_1215"), 0); eq(r:get("test_active"), 0)
    r:power(); r:step(0.25, 200); eq(r:get("mode"), 1); eq(r:get("emergency_latched"), 0); eq(r:silent(), true)
end)
for _, pair in ipairs({{0, 0, 0}, {7, 7, 0}, {13, 13, 0}, {27, 0, 1}, {0, 27, 1}}) do
    test("independent buses " .. pair[1] .. "/" .. pair[2], function(r)
        r:power(pair[1], pair[2]); eq(r:get("mode"), pair[3]); eq(r:get("arm_lit"), pair[3])
    end)
end
test("ten-second self-test never sets any distress transmission flag", function(r)
    r:power(); r:set("test", 1)
    local fault, emergency, tone = false, false, false
    for i = 1, 40 do
        r:step(0.25)
        eq(r:get("tx_1215"), 0); eq(r:get("tx_406"), 0); eq(r:get("emergency_latched"), 0)
        fault = fault or r:get("fault_lit") > 0
        emergency = emergency or r:get("emergency_lit") > 0
        tone = tone or not r:silent()
    end
    eq(fault, true); eq(emergency, true); eq(tone, true)
    eq(r:get("test_active"), 0); eq(r:get("test_passed"), 1); eq(r:get("mode"), 1)
    r:step(0.25, 100); eq(r:get("test_active"), 0, "Held TEST does not restart")
    r:set("test", 0); r:step(); r:press("test"); eq(r:get("test_active"), 1)
end)
test("brief and repeated short presses cannot trigger emergency", function(r)
    r:power(); for _ = 1, 8 do r:press("manual_button", 7) end
    eq(r:get("emergency_latched"), 0); eq(r:get("tx_1215"), 0)
end)
test("deliberate hold latches; TEST and SOUND OFF never stop the beacon", function(r)
    r:power(); r:activate(); eq(r:get("mode"), 3); eq(r:get("tx_1215"), 1); eq(r:silent(), false)
    local plays = r.plays[r.sample]; r:step(0.25, 100); eq(r.plays[r.sample], plays, "Loop not restarted per frame")
    r:press("test"); eq(r:get("test_active"), 0); eq(r:get("tx_1215"), 1)
    r:press("mute"); eq(r:silent(), true); eq(r:get("muted"), 1); eq(r:get("tx_1215"), 1)
    r:set("mute", 1); r:step(0.25, 100); eq(r:get("muted"), 1)
    r:set("enable", 0); r:step(); eq(r:get("emergency_latched"), 0); eq(r:get("mode"), 0); eq(r:get("tx_1215"), 0)
    r:set("enable", 1); r:step(); eq(r:get("mode"), 1); eq(r:get("tx_1215"), 0); eq(r:get("muted"), 0)
end)
test("backup supply preserves an activated beacon across bus loss", function(r)
    r:power(); r:activate(); r:set("left", 0); r:step(0.25, 100)
    eq(r:get("tx_1215"), 1); eq(r:get("emergency_latched"), 1); eq(r:get("mode"), 3)
    r:press("mute"); eq(r:silent(), true); eq(r:get("tx_1215"), 1)
    r:set("enable", 0); r:step(); eq(r:get("tx_1215"), 0); eq(r:get("emergency_latched"), 0)
end)
test("holding an input across power restoration cannot activate", function(r)
    r:set("manual_button", 1); r:step(); r:power(); r:step(0.25, 100); eq(r:get("emergency_latched"), 0)
    r:set("manual_button", 0); r:step(); r:activate(); eq(r:get("emergency_latched"), 1)
    r:set("manual_button", 1); r:set("enable", 0); r:step(); r:set("enable", 1); r:step(0.25, 100)
    eq(r:get("emergency_latched"), 0)
end)
test("bus loss cancels a test without leaving lamps or audio stuck", function(r)
    r:power(); r:press("test", 16); eq(r:silent(), false)
    r:set("left", 0); r:step(); eq(r:silent(), true); eq(r:get("test_active"), 0); eq(r:get("fault_lit"), 0)
    r:power(); eq(r:get("test_active"), 0)
end)
for _, key in ipairs({"unit_failed", "battery_failed"}) do
    test(key .. " causes a failed test and a visible fault", function(r)
        r:power(); r:set(key, 1); r:press("test", 40)
        eq(r:get("test_passed"), 0); eq(r:get("mode"), 4); eq(r:get("fault_lit"), 1)
        r:set(key, 0); r:press("test", 40); eq(r:get("test_passed"), 1); eq(r:get("fault_lit"), 0)
    end)
end
test("unserviceable supply/transmitter stop TX but do not silently clear activation", function(r)
    r:power(); r:activate(); r:set("unit_failed", 1); r:step()
    eq(r:get("emergency_latched"), 1); eq(r:get("tx_1215"), 0); eq(r:silent(), true)
    r:set("unit_failed", 0); r:set("left", 0); r:set("battery_failed", 1); r:step()
    eq(r:get("tx_1215"), 0); eq(r:get("emergency_latched"), 1)
    r:set("right", 27); r:step(); eq(r:get("tx_1215"), 1)
end)
test("406 burst simulation is separate from continuous 121.5 state", function(r)
    r:power(); r:activate(); local burst, gap = false, false
    for _ = 1, 204 do
        r:step(); eq(r:get("tx_1215"), 1)
        burst = burst or r:get("tx_406") == 1; gap = gap or r:get("tx_406") == 0
    end
    eq(burst, true); eq(gap, true)
end)
test("pause and invalid deltas cannot complete the guarded hold", function(r)
    r:power(); r:set("manual_button", 1)
    for _, dt in ipairs({0, -1, 0/0, math.huge}) do r:step(dt, 10); eq(r:get("emergency_latched"), 0) end
    r:set("paused", 1); r:step(1, 10); eq(r:get("emergency_latched"), 0)
    r:set("paused", 0); r:step(200); eq(r:get("emergency_latched"), 0, "One stall cannot trigger")
end)
test("pressing during pause requires release and a new activation press", function(r)
    r:power(); r:set("paused", 1); r:set("manual_button", 1); r:step(1)
    r:set("paused", 0); r:step(0.25, 40); eq(r:get("emergency_latched"), 0)
end)
for _, gate in ipairs({"paused", "outside", "sound", "volume"}) do
    test("local audio obeys " .. gate .. " without resetting transmitter", function(r)
        r:power(); r:activate(); eq(r:silent(), false)
        r:set(gate, (gate == "paused" or gate == "outside") and 1 or 0); r:step()
        eq(r:silent(), true); eq(r:get("tx_1215"), 1)
        r:set(gate, (gate == "paused" or gate == "outside") and 0 or 1); r:step()
        eq(r:silent(), false)
    end)
end
test("optional commands control the same cockpit properties", function(r)
    r:power(); r:command("test", 0); r:step(); eq(r:get("test_active"), 1); r:command("test", 2)
    r:command("activate", 0); r:step(0.25, 8); r:command("activate", 2); r:step(0)
    eq(r:get("tx_1215"), 1); eq(r:get("test_active"), 0)
    r:command("sound_off", 0); r:step(); r:command("sound_off", 2); eq(r:silent(), true)
end)
test("missing audio cannot break controls or transmission state", function(r)
    r:power(); r:press("test", 40); eq(r:get("test_passed"), 1); r:activate(); eq(r:get("tx_1215"), 1)
    r:press("mute"); r:shutdown(); eq(r:get("tx_1215"), 0)
end, true)
test("shutdown stops sound and clears owned outputs", function(r)
    r:power(); r:activate(); r:shutdown(); eq(r:silent(), true)
    for _, key in ipairs({"mode", "emergency_latched", "manual_button", "tx_1215", "tx_406", "arm_lit", "emergency_lit", "fault_lit"}) do
        eq(r:get(key), 0, key)
    end
end)
print("PASS ARM-406: " .. scenarios .. " scenarios, " .. assertions .. " assertions; SASL/audio mocked")
