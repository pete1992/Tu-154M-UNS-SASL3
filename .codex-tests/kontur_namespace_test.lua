-- Run the installed xTlua Lua glue, with only the native X-Plane API mocked.
-- This checks real property registration/reads/writes, not a live simulator.
local root = assert(arg[1], "Provide the aircraft directory")
local controller_path = root .. "/plugins/xtlua/init/scripts/T154.kontur/T154.kontur.lua"
local assertions = 0
local function check(condition, message)
    assert(condition, message)
    assertions = assertions + 1
end

-- Fengari is Lua 5.3; emulate the Lua 5.1 environment calls used by the actual loader.
-- Under Lua 5.1/LuaJIT these shims are not used.
local function environment_index(fn)
    for index = 1, math.huge do
        local name = debug.getupvalue(fn, index)
        if name == nil then return nil end
        if name == "_ENV" then return index end
    end
end
local set_environment = setfenv or function(fn, env)
    local index = assert(environment_index(fn), "Chunk has no environment")
    debug.upvaluejoin(fn, index, function() return env end, 1)
    return fn
end
local get_environment = getfenv or function(fn)
    if type(fn) == "number" then fn = debug.getinfo(fn + 1, "f").func end
    local index = assert(environment_index(fn), "Function has no environment")
    local _, env = debug.getupvalue(fn, index)
    return env
end
local function load_in(path, env)
    if setfenv then return set_environment(assert(loadfile(path)), env) end
    return assert(loadfile(path, "t", env))
end

local function run(glue_path)
    local native, registrations, commands = {}, {}, {}
    local host = setmetatable({}, {__index = _G})
    host._G = host
    host.debug = {traceback = debug.traceback}
    host.print = function() end
    host.getfenv, host.setfenv = get_environment, set_environment
    host.XLuaGetCode = function() return nil end -- Optional stack-trace helper only.
    host.XLuaFindDataRef = function(name)
        if not native[name] then native[name] = {kind = "number", value = 0} end
        return name
    end
    host.XLuaCreateDataRef = function(name, kind, writable, notifier)
        check(not native[name], "Duplicate creation: " .. name)
        native[name] = {kind = kind, value = kind == "string" and "" or 0}
        registrations[name] = {writable = writable, notifier = notifier}
        return name
    end
    host.XLuaGetDataRefType = function(handle) return native[handle].kind end
    host.XLuaGetNumber = function(handle) return native[handle].value end
    host.XLuaSetNumber = function(handle, value)
        check(type(value) == "number", "Non-numeric native write: " .. handle)
        native[handle].value = value
    end
    host.XLuaGetString = function(handle) return native[handle].value end
    host.XLuaSetString = function(handle, value)
        check(type(value) == "string", "Non-string native write: " .. handle)
        native[handle].value = value
    end
    host.XLuaCreateCommand = function(name) return name end
    host.XlLuaReplaceCommand = function(name, handler) commands[name] = handler end

    load_in(root .. "/" .. glue_path, host)()
    host.run_module_in_namespace(load_in(controller_path, host))
    local ns = host.n
    check(ns ~= host, "Controller must use a separate module namespace")
    check(ns._G == host, "Real loader must retain the parent _G, not alias the module")
    local count = 0
    for name, property in pairs(ns.functions) do
        count = count + 1
        check(type(property.__get) == "function", "Missing property getter: " .. name)
        check(type(property.__set) == "function", "Missing property setter: " .. name)
        check(rawget(host, name) == nil, "DataRef wrapper escaped to parent _G: " .. name)
    end
    check(count == 170, "Expected 170 registered properties, got " .. count)
    check(ns.weather_mode == 1, "WX initial selector value")
    check(native["tu154/custom/kontur/weather_mode"].value == 1, "Selector initialization reaches native storage")
    check(type(ns.deferred_dataref) == "function", "Creation helper remains a script global")
    check(ns.dref ~= nil, "Creation handle remains a script global")
    for _, name in ipairs({"weather_mode", "weather_sys", "wx2000_tilt", "wx2000_windshear"}) do
        local path = ns.functions[name].dref
        check(registrations[path].writable == "yes", "Writable cockpit DataRef: " .. name)
        check(type(registrations[path].notifier) == "function", "Cockpit notifier: " .. name)
    end

    ns.aircraft_load()
    ns.simDR_passed = 0.05
    ns.simDR_bus27left, ns.simDR_bus27right, ns.simDR_36v = 27, 27, 36
    ns.kontur_pow_l, ns.kontur_pow_r, ns.ubs_pow_l, ns.ubs_pow_r = 1, 1, 1, 1
    ns.simDR_gps_power, ns.simDR_gps_fromto, ns.simDR_tcas_mode = 1, 1, 4
    native["tu154/custom/wx2000_tilt"].value = -7.5
    check(ns.wx2000_tilt == -7.5, "External cockpit writes remain readable")
    ns.weather_sys, ns.wx2000_windshear = 1, 1
    for _ = 1, 500 do ns.after_physics() end
    check(ns.kontur_on_l == 1 and ns.kontur_on_r == 1, "Both displays complete startup")
    check(ns.weather_ready == 1, "Radar completes warmup")
    check(ns.simDR_weather_tilt == -7.5 and ns.simDR_weather_tilt_fo == -7.5, "Tilt reaches both native displays")
    check(ns.simDR_weather_pws == 1, "Windshear AUTO reaches native radar")
    ns.weather_mode = 3
    ns.after_physics()
    check(ns.simDR_weather_mode_xp == 4 and ns.simDR_weather_mode_xp_fo == 4, "MAP reaches both native modes")
    commands["kontur/nav_btn_l"](0, 0)
    ns.after_physics()
    commands["kontur/tcas_btn_l"](0, 0)
    ns.after_physics()
    check(ns.kontur_nav_l == 1 and ns.kontur_tcas_l == 2, "TCAS preserves NAV")
    check(ns.simDR_fms_line == 0, "Native NAV route remains visible")
    check(type(ns.lat_string) == "string", "Coordinate string stays a property value")
    check(ns.lat_string == native["tu154/custom/kontur/latitude"].value, "String output reaches native storage")
    ns.weather_sys = 0
    ns.after_physics()
    check(ns.weather_ready == 0 and ns.simDR_weather_pws == 0, "Radar shutdown clears readiness/PWS")
    print("PASS installed loader: " .. glue_path .. "; 170 properties and controller lifecycle")
end

run("plugins/xtlua/init/init.lua")
print("PASS Kontur namespace regression: " .. assertions .. " checks; no live simulator claim")
