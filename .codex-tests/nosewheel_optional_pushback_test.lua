-- Offline regression of the actual module; X-Plane/SASL access is mocked.
-- Usage: fengari nosewheel_optional_pushback_test.lua <aircraft-directory>
local root = assert(arg[1], "Provide the aircraft directory")
local path = root .. "/plugins/sasl/data/modules/Custom Module/controls/nosewheel.lua"
local assertions = 0
local function check(ok, message)
    assert(ok, message)
    assertions = assertions + 1
end
local function controller(available, connected)
    local e = setmetatable({}, {__index = _G})
    local r = {available = available, connected = connected, lookups = 0, reads = 0, frees = 0, writes = {}}
    local values, ref = {}, {}
    local function bind(name)
        check(name ~= "bp/connected", "BetterPushback must not be a mandatory property")
        return name
    end
    e.globalProperty, e.globalPropertyi, e.globalPropertyf = bind, bind, bind
    e.defineProperty = function(name, property) e[name] = property end
    e.get = function(property) return values[assert(property)] or 0 end
    e.set = function(property, value)
        values[assert(property)] = value
        r.writes[property] = (r.writes[property] or 0) + 1
    end
    e.TYPE_INT = 1
    e.sasl = {
        findDataRef = function(name, kind, silent)
            check(name == "bp/connected" and kind == e.TYPE_INT and silent == true, "silent optional lookup")
            r.lookups = r.lookups + 1
            if r.available then return ref, kind end
        end,
        getDataRef = function(handle)
            check(handle == ref, "read only a valid handle")
            r.reads = r.reads + 1
            return r.available and r.connected or 0
        end,
        freeDataRef = function(handle)
            check(handle == ref, "free only owned handle")
            r.frees = r.frees + 1
        end,
    }
    e.clamp = function(x, low, high) return math.max(low, math.min(high, x)) end
    e.bool2int = function(value) return value and 1 or 0 end
    e.interpolate = function(points, x)
        for i = 2, #points do
            local a, b = points[i - 1], points[i]
            if x <= b[1] then return a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1]) end
        end
        return points[#points][2]
    end
    e.findCommand = function(name) return name end
    e.registerCommandHandler = function(_, _, handler) r.toggle = handler end
    local chunk
    if setfenv then chunk = assert(loadfile(path)); setfenv(chunk, e)
    else chunk = assert(loadfile(path, "t", e)) end
    chunk()
    function r:set(name, value) values[assert(e[name], name)] = value end
    function r:get(name) return e.get(assert(e[name], name)) end
    function r:step(n) for _ = 1, n or 1 do e.update() end end
    function r:steerWrites() return self.writes[e.tire_steer_command_deg] or 0 end
    r.env = e
    r:set("frame_time", 0.1)
    r:set("nosewheel_turn_enable", 1)
    r:set("bus27_volt_left", 27)
    r:set("gs_press_2", 210)
    r:set("deflection_mtr_1", 0.2)
    r:set("joy_yaw", 1)
    return r
end

local absent = controller(false, 0)
absent:step(100)
check(absent:steerWrites() == 100 and absent:get("tire_steer_command_deg") > 0, "normal steering without plugin")
check(absent.reads == 0 and absent.lookups <= 11, "no nil reads or per-frame missing lookup")
absent.available, absent.connected = true, 1
absent:set("nosewheel_turn_enable", 0)
absent:step(12)
local count = absent:steerWrites()
absent:step(10)
check(absent:steerWrites() == count, "late plugin registration hands off steering")
absent.available = false
absent:step()
check(absent:steerWrites() == count + 1, "orphan handle returns to aircraft steering")
absent.available = true
absent:step()
check(absent:steerWrites() == count + 1, "re-registered provider regains handoff")

local off = controller(true, 0)
off:step(20)
check(off:steerWrites() == 20 and off.lookups == 1, "disconnected plugin retains steering and cached lookup")
local on = controller(true, 1)
on:step()
check(on:steerWrites() == 1, "powered NWS retains original precedence")
on:set("bus27_volt_left", 0)
on:step(10)
check(on:steerWrites() == 1, "unpowered NWS leaves tug command untouched")

local gated = controller(false, 0)
gated:set("ismaster", 1)
gated:step()
gated:set("ismaster", 0)
gated:set("frame_time", 0)
gated:step()
check(gated.lookups == 0 and gated:steerWrites() == 0, "slave and pause gates preserved")
check(gated.toggle(0) == 0 and gated:get("nosewheel_turn_enable") == 0, "toggle still works")
for _, errorShutdown in ipairs({false, true}) do
    local r = controller(true, 1)
    r:step()
    r.env.onModuleShutdown(errorShutdown)
    check(r:get("override_wheel_steer") == 0 and r.frees == 1, "normal/error shutdown releases ownership")
    r.env.onModuleShutdown(errorShutdown)
    check(r.frees == 1, "cleanup is idempotent")
end
gated.env.onModuleShutdown(true)
check(gated.frees == 0, "missing plugin needs no handle cleanup")
print("PASS nosewheel optional BetterPushback: " .. assertions .. " assertions")
