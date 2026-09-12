-- Offline audio lifecycle regression; no simulator connection or actual sound playback.
local root = assert(arg[1], "Provide the aircraft directory")
local module_path = root .. "/plugins/sasl/data/modules/Custom Module/main_panel/taws/taws_sound.lua"
local aircraft_path = "I:/X-Plane 12/Aircraft/Laminar Research/Tu-154M-UNS-SASL3"
local warning_sample = aircraft_path .. "/sounds/alert/wshr.wav"
local native_warning = "sim/cockpit2/annunciators/windshear_warning_systems"
local external_view = "sim/graphics/view/view_is_external"
local windshear_switch = "tu154/custom/wx2000_windshear"
local ready = "tu154/custom/kontur/weather_ready"
local system_power = "tu154/custom/kontur/weather_sys"
local bus = "tu154/custom/elec/bus36_volt_left"
local english = "tu154/custom/taws/taws_english"
local eng_phrase = "tu154/custom/sounds/taws_eng_phrase"
local rus_phrase = "tu154/custom/sounds/taws_rus_phrase"
local assertions, scenarios = 0, 0
local function eq(actual, expected, message)
    assert(actual == expected, message .. ": " .. tostring(actual) .. " ~= " .. tostring(expected))
    assertions = assertions + 1
end

local function controller(missing_sample)
    local values, loads, plays, stops, playing, bindings = {}, {}, {}, {}, {}, {}
    local env = setmetatable({}, {__index = _G})
    env.globalPropertyi = function(path) return path end
    env.globalPropertyf = env.globalPropertyi
    env.defineProperty = function(name, property) env[name] = property; bindings[name] = property end
    env.get = function(property) return values[assert(property, "nil property")] or 0 end
    env.set = function(property, value)
        assert(property:sub(1, 4) ~= "sim/", "Sound code must not write native DataRefs: " .. property)
        values[property] = value
    end
    env.sasl = {
        getAircraftPath = function() return aircraft_path end,
        al = {
            loadSample = function(path)
                loads[#loads + 1] = path
                if missing_sample and path == warning_sample then return nil end
                return path
            end,
            playSample = function(sample, loop)
                assert(sample ~= nil, "nil sample played")
                plays[#plays + 1] = {sample = sample, loop = loop}
                playing[sample] = true
            end,
            stopSample = function(sample)
                assert(sample ~= nil, "nil sample stopped")
                stops[#stops + 1] = sample
                playing[sample] = false
            end,
            isSamplePlaying = function(sample)
                assert(sample ~= nil, "nil sample queried")
                return playing[sample] == true
            end,
        },
    }
    local chunk
    if setfenv then chunk = assert(loadfile(module_path)); setfenv(chunk, env)
    else chunk = assert(loadfile(module_path, "t", env)) end
    chunk()
    local r = {values = values, loads = loads, plays = plays, stops = stops, playing = playing, bindings = bindings}
    function r:set(path, value) values[path] = value end
    function r:get(path) return values[path] or 0 end
    function r:update(count) for _ = 1, count or 1 do env.update() end end
    function r:count_loads(path)
        local count = 0
        for _, sample in ipairs(loads) do if sample == path then count = count + 1 end end
        return count
    end
    function r:count_plays(path)
        local count = 0
        for _, item in ipairs(plays) do if item.sample == path then count = count + 1 end end
        return count
    end
    function r:count_stops(path)
        local count = 0
        for _, sample in ipairs(stops) do if sample == path then count = count + 1 end end
        return count
    end
    function r:is_warning_playing() return playing[warning_sample] == true end
    r:set(windshear_switch, 1); r:set(ready, 1); r:set(system_power, 1); r:set(bus, 36)
    r:set(external_view, 0); r:set(english, 1)
    return r
end

local function test(name, callback, missing_sample)
    callback(controller(missing_sample)); scenarios = scenarios + 1; print("PASS " .. name)
end

test("exact aircraft WAV is loaded lazily once, AUTO alone is silent", function(r)
    eq(r:count_loads(warning_sample), 0, "not loaded at module initialization")
    r:update()
    eq(r:count_loads(warning_sample), 1, "loaded at first update using aircraft path")
    r:update(100)
    eq(r:count_loads(warning_sample), 1, "sample loaded only once")
    eq(r:count_plays(warning_sample), 0, "AUTO without real warning is silent")
    eq(r:is_warning_playing(), false, "AUTO is not a test alarm")
    for _, path in ipairs(r.loads) do
        if path:find("wshr.wav", 1, true) then eq(path, warning_sample, "exact WAV path") end
    end
end)

for warning = 0, 5 do
    test("native warning enum " .. warning, function(r)
        r:set(native_warning, warning); r:update()
        local audible = warning >= 2
        eq(r:is_warning_playing(), audible, "enum playback policy")
        eq(r:count_plays(warning_sample), audible and 1 or 0, "one guarded play")
        if audible then
            eq(r.plays[#r.plays].loop, true, "warning sample loops while warning active")
            r:update(120)
            eq(r:count_plays(warning_sample), 1, "active warning is not restarted each frame")
        end
    end)
end

for _, warning in ipairs({-1, 6, 2.5, 0/0, math.huge}) do
    test("invalid warning enum is silent", function(r)
        r:set(native_warning, warning); r:update(3)
        eq(r:is_warning_playing(), false, "invalid enum silent")
        eq(r:count_plays(warning_sample), 0, "invalid enum never plays")
    end)
end

for warning = 2, 4 do
    for _, gate in ipairs({windshear_switch, ready, system_power, bus}) do
        test("predictive enum " .. warning .. " gated by " .. gate, function(r)
            r:set(native_warning, warning); r:update()
            eq(r:is_warning_playing(), true, "active predictive warning")
            r:set(gate, 0); r:update()
            eq(r:is_warning_playing(), false, "gate removal stops predictive warning")
            eq(r:count_stops(warning_sample), 1, "active sound stopped once")
            r:update(20)
            eq(r:count_stops(warning_sample), 1, "silent sound not repeatedly stopped")
            r:set(gate, gate == bus and 36 or 1); r:update()
            eq(r:is_warning_playing(), true, "restored gate resumes actual predictive warning")
            eq(r:count_plays(warning_sample), 2, "one guarded restart after gate restoration")
        end)
    end
end

test("reactive enum 5 remains audible with WX and predictive system OFF", function(r)
    r:set(windshear_switch, 0); r:set(ready, 0); r:set(system_power, 0); r:set(bus, 0)
    r:set(native_warning, 5); r:update()
    eq(r:is_warning_playing(), true, "reactive warning independent of WX/PWS controls")
    r:update(60)
    eq(r:count_plays(warning_sample), 1, "reactive loop not restarted")
    r:set(native_warning, 4); r:update()
    eq(r:is_warning_playing(), false, "predictive warning respects OFF state after reactive")
end)

test("clear warning and external camera stop playback; cockpit reentry resumes", function(r)
    r:set(native_warning, 3); r:update()
    r:set(native_warning, 0); r:update()
    eq(r:is_warning_playing(), false, "warning clear stops loop")
    eq(r:count_stops(warning_sample), 1, "one stop on clear")
    r:set(native_warning, 5); r:update()
    r:set(external_view, 1); r:update()
    eq(r:is_warning_playing(), false, "external view stops reactive warning")
    r:update(40)
    eq(r:count_plays(warning_sample), 2, "external view never restarts warning")
    r:set(external_view, 0); r:update()
    eq(r:is_warning_playing(), true, "cockpit reentry resumes active warning")
    eq(r:count_plays(warning_sample), 3, "one restart on cockpit reentry")
    r:set(native_warning, 1); r:update()
    eq(r:is_warning_playing(), false, "advisory stops preceding warning loop")
end)

test("an unexpectedly stopped sample is restarted while real warning persists", function(r)
    r:set(native_warning, 2); r:update()
    r.playing[warning_sample] = false
    r:update()
    eq(r:count_plays(warning_sample), 2, "isSamplePlaying guard repairs stopped playback")
    eq(r:is_warning_playing(), true, "actual alert resumes")
end)

test("missing warning WAV is safe and not reloaded every frame", function(r)
    r:set(native_warning, 3); r:update(100)
    r:set(external_view, 1); r:update(); r:set(native_warning, 0); r:update()
    eq(r:count_loads(warning_sample), 1, "missing sample attempted once")
    eq(r:count_plays(warning_sample), 0, "nil sample never played")
    eq(r:count_stops(warning_sample), 0, "nil sample never stopped")
    r:set(external_view, 0); r:set(eng_phrase, 14); r:update()
    eq(r:count_plays("Custom Sounds/taws/eng/pull_up.wav"), 1, "missing new WAV does not break existing TAWS")
end, true)

test("existing English and alternate TAWS selection and phrase resets preserved", function(r)
    for _, item in ipairs({
        {1, eng_phrase, 1, "Custom Sounds/taws/eng/alt_50.wav"},
        {1, eng_phrase, 14, "Custom Sounds/taws/eng/pull_up.wav"},
        {0, rus_phrase, 3, "Custom Sounds/taws/rus/20ft.wav"},
        {0, rus_phrase, 11, "Custom Sounds/taws/rus/altitude_alert.wav"},
        {0, rus_phrase, 12, "Custom Sounds/taws/eng/dont_sink.wav"},
        {0, rus_phrase, 25, "Custom Sounds/taws/rus/2500ft.wav"},
    }) do
        r:set(english, item[1]); r:set(item[2], item[3]); r:update()
        eq(r.plays[#r.plays].sample, item[4], "original TAWS phrase mapping")
        eq(r.plays[#r.plays].loop, false, "TAWS phrase remains one shot")
        eq(r:get(item[2]), 0, "selected TAWS phrase resets")
    end
    r:set(english, 1); r:set(eng_phrase, 2); r:set(external_view, 1)
    local previous = #r.plays
    r:update()
    eq(#r.plays, previous, "external view suppresses new TAWS phrase")
    eq(r:get(eng_phrase), 2, "external-view TAWS phrase retains original pending behavior")
    r:set(external_view, 0); r:set(native_warning, 5); r:update()
    eq(r:is_warning_playing(), true, "reactive warning plays with existing TAWS behavior")
    eq(r:get(eng_phrase), 0, "TAWS pending phrase resets on cockpit reentry")
    eq(r:count_plays("Custom Sounds/taws/eng/alt_200.wav"), 1, "pending TAWS phrase still played")
end)

print("PASS windshear sound: " .. scenarios .. " scenarios, " .. assertions .. " assertions; audio calls mocked, no native DataRef writes")
