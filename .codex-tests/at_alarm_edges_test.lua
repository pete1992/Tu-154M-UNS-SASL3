-- Offline cabin sound regression: real component with mocked SASL audio.
local root = assert(arg[1], "Provide the aircraft directory")
local module_path = root .. "/plugins/sasl/data/modules/Custom Module/sounds/cabin_sounds.lua"
local AP_OFF = "Custom Sounds/short_speaker.wav"
local LONG = "Custom Sounds/long_speaker.wav"
local DR = {
    roll = "tu154/custom/absu/roll_main_mode",
    pitch = "tu154/custom/absu/pitch_main_mode",
    at = "tu154/custom/absu/stu_mode",
    fail = "tu154/custom/absu/absu_fail_signal",
    left = "tu154/custom/elec/bus27_volt_left",
    right = "tu154/custom/elec/bus27_volt_right",
    external = "sim/graphics/view/view_is_external",
    buzzer = "tu154/custom/switchers/eng/fuel_buzzer",
    speaker_fail = "tu154/custom/failures/speaker_alarm_fail",
    auasp = "tu154/custom/alarm/speaker_auasp",
    fuel = "tu154/custom/alarm/speaker_fuel",
}
local assertions, scenarios = 0, 0
local function eq(actual, expected, message)
    assert(actual == expected, message .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
    assertions = assertions + 1
end

local function controller(seed)
    local values = {
        [DR.left] = 28,
        [DR.right] = 28,
        [DR.buzzer] = 1,
        ["tu154/custom/time/frame_time"] = 0.016,
        ["sim/operation/sound/warning_volume_ratio"] = 1,
        ["tu154/custom/failures/failures_enabled"] = 1,
    }
    for key, value in pairs(seed or {}) do values[assert(DR[key])] = value end
    local playing, plays, bindings = {}, {}, {}
    local env = setmetatable({}, {__index = _G})
    env.globalProperty = function(path) return path end
    env.globalPropertyi = env.globalProperty
    env.globalPropertyf = env.globalProperty
    env.defineProperty = function(name, property) env[name] = property; bindings[name] = property end
    env.get = function(property) return values[assert(property, "nil property")] or 0 end
    env.set = function(property, value)
        assert(property:sub(1, 4) ~= "sim/", "Sound logic must not write native DataRefs")
        values[property] = value
    end
    env.bool2int = function(value) return value and 1 or 0 end
    env.sasl = {al = {
        loadSample = function(path) return path end,
        playSample = function(sample, looped)
            eq(type(looped), "boolean", "SASL 3 loop flag")
            plays[sample] = (plays[sample] or 0) + 1
            playing[sample] = true
        end,
        stopSample = function(sample) playing[sample] = false end,
        isSamplePlaying = function(sample) return playing[sample] == true end,
        setSampleGain = function() end,
        setSamplePitch = function() end,
    }}
    local chunk
    if setfenv then chunk = assert(loadfile(module_path)); setfenv(chunk, env)
    else chunk = assert(loadfile(module_path, "t", env)) end
    chunk()
    local result = {bindings = bindings}
    function result:set(key, value) values[assert(DR[key])] = value end
    function result:update(count) for _ = 1, count or 1 do env.update() end end
    function result:count(sample) return plays[sample or AP_OFF] or 0 end
    function result:finish_sound(sample) playing[sample or AP_OFF] = false end
    return result
end

local function test(name, callback, seed)
    callback(controller(seed))
    scenarios = scenarios + 1
    print("PASS " .. name)
end

test("AT preparation, engagement and TOGA transitions are silent", function(r)
    for _, mode in ipairs({0, 1, 2, 3, 4, 3}) do
        r:set("at", mode); r:update()
        eq(r:count(), 0, "AT engagement is not AP OFF")
    end
    r:update(120)
    eq(r:count(), 0, "steady AT remains silent")
end)

test("AT disconnect sounds once, then re-engagement is silent", function(r)
    r:set("at", 2); r:update()
    eq(r:count(), 1, "AT falling edge sounds")
    r:finish_sound(); r:update(120)
    eq(r:count(), 1, "disconnected state does not repeat")
    r:set("at", 3); r:update()
    eq(r:count(), 1, "AT rising edge remains silent")
    r:set("at", 0); r:update()
    eq(r:count(), 2, "AT power-off falling edge sounds")
end, {at = 3})

test("TOGA completion and AT total failure still sound", function(r)
    r:set("at", 2); r:update()
    eq(r:count(), 1, "TOGA finished to ready")
    r:set("at", 4); r:update()
    eq(r:count(), 1, "TOGA engagement silent")
    r:set("at", -1); r:update()
    eq(r:count(), 2, "AT failed from active")
end, {at = 4})

test("AP axis engagement and damper initialization are silent", function(r)
    for _, state in ipairs({{1, 0}, {2, 0}, {2, 1}, {2, 2}}) do
        r:set("roll", state[1]); r:set("pitch", state[2]); r:update()
        eq(r:count(), 0, "rising control levels remain silent")
    end
end)

test("independent AP and damper disconnects remain audible", function(r)
    for index, state in ipairs({{1, 2}, {1, 1}, {0, 1}, {0, 0}}) do
        r:set("roll", state[1]); r:set("pitch", state[2]); r:update()
        eq(r:count(), index, "falling axis control level sounds")
    end
end, {roll = 2, pitch = 2})

test("one axis disconnect cannot be masked by engagement of the other", function(r)
    r:set("roll", 1); r:set("pitch", 2); r:set("at", 3); r:update()
    eq(r:count(), 1, "real AP loss wins despite simultaneous AT engagement")
end, {roll = 2, pitch = 1, at = 2})

test("AT engagement does not suppress an independent ABSU failure", function(r)
    r:set("at", 3); r:set("fail", 1); r:update()
    eq(r:count(), 1, "genuine failure alarm remains")
    r:finish_sound(); r:update()
    eq(r:count(), 2, "failure alarm repeats when sample finishes")
end, {at = 2})

for _, gate in ipairs({"external", "buzzer", "speaker_fail", "power"}) do
    test("existing audible warning gate: " .. gate, function(r)
        if gate == "external" then r:set("external", 1)
        elseif gate == "buzzer" then r:set("buzzer", 0)
        elseif gate == "speaker_fail" then r:set("speaker_fail", 1)
        else r:set("left", 0); r:set("right", 0) end
        r:set("at", 2); r:update()
        eq(r:count(), 0, "gate suppresses sound as before")
        r:set("external", 0); r:set("buzzer", 1); r:set("speaker_fail", 0)
        r:set("left", 28); r:set("right", 28); r:update()
        eq(r:count(), 0, "no delayed stale disconnect alarm")
    end, {at = 3})
end

test("AP power loss still warns when one DC supply remains", function(r)
    r:set("left", 0); r:set("roll", 0); r:set("pitch", 0); r:update()
    eq(r:count(), 1, "remaining speaker power permits loss warning")
end, {roll = 2, pitch = 2})

test("AUASP warning priority is preserved during AT disconnect", function(r)
    r:set("at", 2); r:set("auasp", 1); r:update()
    eq(r:count(), 0, "AUASP retains priority")
    eq(r:count(LONG), 1, "AUASP continuous warning remains")
end, {at = 3})

test("DataRef schema has no standalone version binding", function(r)
    eq(r.bindings.xp_version, nil, "XP12 direct SASL audio API")
    eq(r.bindings.stu_mode, DR.at, "AT DataRef unchanged")
    eq(r.bindings.roll_main_mode, DR.roll, "AP roll DataRef unchanged")
    eq(r.bindings.pitch_main_mode, DR.pitch, "AP pitch DataRef unchanged")
end)

print(string.format("PASS: %d scenarios, %d assertions", scenarios, assertions))
