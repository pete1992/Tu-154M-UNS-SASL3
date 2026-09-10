-- Offline receiver regression tests; does not connect to X-Plane.
local root = assert(arg[1], "Provide the aircraft directory")
local radio_dir = root .. "/plugins/sasl/data/modules/Custom Module/main_panel/radio/"
local receiver_chunk = assert(loadfile(radio_dir .. "course_mp.lua"))
assert(loadfile(radio_dir .. "radio.lua"))

local function load_with_env(path, env)
    local chunk
    if setfenv then
        chunk = assert(loadfile(path))
        setfenv(chunk, env)
    else
        chunk = assert(loadfile(path, "t", env))
    end
    chunk()
end

local radio_env = setmetatable({
    globalPropertyf = function(path) return path end,
    globalPropertyi = function(path) return path end,
}, {__index = function(_, key)
    if _G[key] ~= nil then return _G[key] end
    return function(properties) return {kind = key, properties = properties} end
end})
load_with_env(radio_dir .. "radio.lua", radio_env)
local nav2_overrides
for _, component in ipairs(radio_env.components) do
    if component.kind == "course_mp" and component.properties.frequency then
        nav2_overrides = component.properties
    end
end
assert(nav2_overrides, "NAV2 component binding missing")

local function receiver(number)
    local values = {}
    local env = {}
    if number == 2 then
        for name, property in pairs(nav2_overrides) do env[name] = property end
    end
    setmetatable(env, {__index = _G})
    local function noop() end
    env.sasl = {
        al = {loadSample = noop, playSample = noop, setSampleGain = noop},
        gl = {loadFont = noop, setFontGlyphSpacingFactor = noop, drawText = noop},
    }
    env.globalPropertyf = function(path) return path end
    env.globalPropertyi = env.globalPropertyf
    env.defineProperty = function(name, property)
        if env[name] == nil then env[name] = property end
    end
    env.get = function(property) return values[property] or 0 end
    env.set = function(property, value) values[property] = value end
    env.bool2int = function(value) return value and 1 or 0 end
    -- Force the old random no-signal pulse on every frame.
    env.math = setmetatable({random = function(a) return a or 1 end}, {__index = math})
    load_with_env(radio_dir .. "course_mp.lua", env)
    local r = {env = env, values = values}
    function r:set(name, value) values[assert(env[name], name)] = value end
    function r:get(name) return values[assert(env[name], name)] end
    function r:step() env.update() end
    r:set("frequency", 11030)
    r:set("frame_time", 0.02)
    r:set("curs_np_on", 1)
    r:set("bus36_volt", 36)
    r:set("bus115_volt", 115)
    r:set("bus27_volt_left", 27)
    r:set("bus27_volt_right", 27)
    r:set("cs_signal", 1)
    r:set("gs_flag", 1)
    r:set("cr_flag", 0)
    r:set("v_plank", 1.25)
    r:set("h_plank", -0.625)
    r:set("obs", 180)
    return r
end

local assertions = 0
local function equals(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    assertions = assertions + 1
end

for number = 1, 2 do
    local prefix = "NAV" .. number .. " "
    local r = receiver(number)
    r:step()
    equals(r:get("nav_cs_flag"), 0, prefix .. "LOC valid without TO/FROM")
    equals(r:get("nav_gs_flag"), 0, prefix .. "GS valid")
    equals(r:get("nav_cs"), 0.5, prefix .. "LOC normalized")
    equals(r:get("nav_gs"), -0.25, prefix .. "GS normalized")

    r:set("cr_flag", 1)
    r:set("cs_signal", 0)
    r:set("gs_flag", 0)
    for _ = 1, 1000 do
        r:step()
        assert(r:get("nav_cs_flag") == 1 and r:get("nav_gs_flag") == 1,
            prefix .. "no random valid guidance while reception is absent")
        assert(r:get("nav_cs") == 0 and r:get("nav_gs") == 0,
            prefix .. "no random deviation while reception is absent")
    end
    equals(r:get("nav_cs_flag"), 1, prefix .. "stale TO/FROM does not validate LOC")
    equals(r:get("nav_gs_flag"), 1, prefix .. "GS loss immediately flagged")

    r:set("cs_signal", 1)
    r:step()
    equals(r:get("nav_cs_flag"), 0, prefix .. "VOR course reception")
    equals(r:get("nav_gs_flag"), 1, prefix .. "VOR does not invent GS")
    r:set("gs_flag", 1)
    r:step()
    equals(r:get("nav_gs_flag"), 0, prefix .. "GS reception recovers")

    for _, fault in ipairs({
        {"curs_np_on", 0, 1},
        {"bus36_volt", 29, 36},
        {"bus115_volt", 109, 115},
        {"nav_fail", 1, 0},
    }) do
        r:set(fault[1], fault[2])
        r:step()
        equals(r:get("nav_cs_flag"), 1, prefix .. fault[1] .. " invalidates LOC")
        equals(r:get("nav_gs_flag"), 1, prefix .. fault[1] .. " invalidates GS")
        equals(r:get("nav_cs"), 0, prefix .. fault[1] .. " clears LOC")
        equals(r:get("nav_gs"), 0, prefix .. fault[1] .. " clears GS")
        r:set(fault[1], fault[3])
    end

    r:set("v_plank", 0 / 0)
    r:set("h_plank", math.huge)
    r:step()
    equals(r:get("nav_cs_flag"), 1, prefix .. "NaN rejected")
    equals(r:get("nav_gs_flag"), 1, prefix .. "infinity rejected")
    equals(r:get("nav_cs"), 0, prefix .. "NaN never published")
    equals(r:get("nav_gs"), 0, prefix .. "infinity never published")
    r:set("v_plank", 1.25)
    r:set("h_plank", -0.625)

    for button = 1, 3 do
        r:set("nav_but_" .. button, 1)
        r:step()
        equals(r:get("nav_cs"), button - 2, prefix .. "LOC panel test " .. button)
        equals(r:get("nav_gs"), button - 2, prefix .. "GS panel test " .. button)
        r:set("nav_but_" .. button, 0)
    end

    r:set("ismaster", 1)
    r:set("nav_cs", 0.123)
    r:set("nav_gs", 0.456)
    r:set("nav_cs_flag", 7)
    r:set("nav_gs_flag", 8)
    r:step()
    equals(r:get("nav_cs"), 0.123, prefix .. "SmartCopilot slave preserves LOC")
    equals(r:get("nav_gs"), 0.456, prefix .. "SmartCopilot slave preserves GS")
    equals(r:get("nav_cs_flag"), 7, prefix .. "slave preserves LOC flag")
    equals(r:get("nav_gs_flag"), 8, prefix .. "slave preserves GS flag")
end

local r = receiver(2)
r.values["sim/cockpit2/radios/indicators/nav1_display_horizontal"] = 0
r.values["sim/cockpit/radios/nav1_CDI"] = 0
r:step()
equals(r:get("nav_cs_flag"), 0, "NAV2 uses NAV2 horizontal source")
equals(r:get("nav_gs_flag"), 0, "NAV2 uses NAV2 GS source")
r:set("cs_signal", 0)
r:set("gs_flag", 0)
r.values["sim/cockpit2/radios/indicators/nav1_display_horizontal"] = 1
r.values["sim/cockpit/radios/nav1_CDI"] = 1
r:step()
equals(r:get("nav_cs_flag"), 1, "NAV1 cannot validate NAV2 LOC")
equals(r:get("nav_gs_flag"), 1, "NAV1 cannot validate NAV2 GS")
print("PASS: " .. assertions .. " receiver assertions plus 2000 no-signal frames; both radio modules parsed")
