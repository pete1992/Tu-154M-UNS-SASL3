-- Offline tests of the actual SASL exterior-animation component.
-- Usage: fengari .codex-tests/wipers_states_test.lua <aircraft-directory>
local root = assert(arg[1], "Provide the aircraft directory")
local path = root .. "/plugins/sasl/data/modules/Custom Module/animation/ext_anim.lua"
local assertions, scenarios = 0, 0

local function check(condition, message)
    assert(condition, message)
    assertions = assertions + 1
end

local function near(actual, expected, message)
    check(type(actual) == "number" and math.abs(actual - expected) < 1e-8,
        message .. ": " .. tostring(actual) .. " versus " .. tostring(expected))
end

local function angle(phase)
    return (math.cos(math.pi * phase * 2 - math.pi) + 1) * 31
end

local function controller()
    local values = {["sim/version/xplane_internal_version"] = 120400}
    local e = setmetatable({}, {__index = _G})
    e.globalProperty = function(name) return name end
    e.globalPropertyi, e.globalPropertyf = e.globalProperty, e.globalProperty
    e.defineProperty = function(name, property) e[name] = property end
    e.get = function(property) return values[assert(property)] or 0 end
    e.set = function(property, value) values[assert(property)] = value end
    e.clamp = function(x, low, high) return math.max(low, math.min(high, x)) end
    e.bool2int = function(value) return value and 1 or 0 end
    e.sasl = {al = {loadSample = function(name) return name end, playSample = function() end}}
    local chunk
    if setfenv then chunk = assert(loadfile(path)); setfenv(chunk, e)
    else chunk = assert(loadfile(path, "t", e)) end
    chunk()
    local r = {env = e}
    function r:set(name, value) values[assert(e[name], name)] = value end
    function r:get(name) return e.get(assert(e[name], name)) end
    function r:step(dt, count)
        self:set("frame_time", dt)
        for _ = 1, count or 1 do e.update() end
    end
    function r:power(left, right)
        self:set("bus27_volt_left", left and 27 or 0)
        self:set("bus115_1_volt", left and 115 or 0)
        self:set("bus27_volt_right", right and 27 or 0)
        self:set("bus115_3_volt", right and 115 or 0)
    end
    function r:expect(left, right)
        near(self:get("wiper_angle_left"), left, "Left blade")
        near(self:get("wiper_angle_right"), right, "Right blade")
    end
    return r
end

local function test(name, run)
    run()
    scenarios = scenarios + 1
    print("PASS " .. name)
end

test("cold-and-dark and OFF stay fully parked", function()
    local r = controller()
    r:set("wiper_left", -1); r:set("wiper_right", 1)
    r:step(1 / 30, 90); r:expect(0, 0)
    r:power(true, true)
    r:set("wiper_left", 0); r:set("wiper_right", 0)
    r:step(1 / 30, 90); r:expect(0, 0)
end)

test("left and right retain separate slow and fast speeds", function()
    local r = controller()
    r:power(true, true)
    r:set("wiper_left", -1); r:set("wiper_right", 1)
    r:step(1 / 60, 10)
    r:expect(angle(0.25), angle(0.5))
    r:step(1 / 60, 10)
    r:expect(angle(0.5), angle(0))
end)

test("full sweep is bounded at normal and low frame rates", function()
    for _, dt in ipairs({1 / 120, 1 / 60, 1 / 30, 0.1, 0.2, 1.07}) do
        local r = controller()
        r:power(true, true)
        r:set("wiper_left", -1); r:set("wiper_right", 1)
        for _ = 1, 30 do
            r:step(dt)
            for _, side in ipairs({"left", "right"}) do
                local current = r:get("wiper_angle_" .. side)
                check(current >= 0 and current <= 62, side .. " angle stays inside 0..62")
            end
        end
    end
end)

test("OFF reaches exact park from every part of the sweep", function()
    for _, phase in ipairs({0.01, 0.05, 0.09, 0.1, 0.25, 0.5, 0.6, 0.9, 0.99}) do
        for _, dt in ipairs({1 / 60, 0.07, 0.2, 0.6, 2}) do
            local r = controller()
            r:power(true, true)
            r:set("wiper_left", 1); r:set("wiper_right", 1)
            r:step(phase / 3)
            r:expect(angle(phase), angle(phase))
            r:set("wiper_left", 0); r:set("wiper_right", 0)
            r:step(dt, math.ceil(1 / dt) + 1)
            r:expect(0, 0)
            r:step(dt, 3); r:expect(0, 0)
        end
    end
end)

test("switching OFF finishes the current cycle instead of teleporting", function()
    local r = controller()
    r:power(true, true)
    r:set("wiper_left", 1); r:set("wiper_right", 1)
    r:step(0.1)
    r:set("wiper_left", 0); r:set("wiper_right", 0)
    r:step(0.1); r:expect(angle(0.4), angle(0.4))
    r:step(0.61); r:expect(0, 0)
end)

test("power loss freezes each motor independently and restoration resumes", function()
    local r = controller()
    r:power(true, true)
    r:set("wiper_left", -1); r:set("wiper_right", -1)
    r:step(0.1)
    r:power(false, true)
    r:step(0.1); r:expect(angle(0.15), angle(0.3))
    r:power(true, false)
    r:step(0.1); r:expect(angle(0.3), angle(0.3))
end)

test("OFF cannot auto-park with no motor power", function()
    local r = controller()
    r:power(true, true)
    r:set("wiper_left", 1); r:set("wiper_right", 1)
    r:step(0.1)
    r:power(false, false)
    r:set("wiper_left", 0); r:set("wiper_right", 0)
    r:step(1, 3); r:expect(angle(0.3), angle(0.3))
    r:power(true, true)
    r:step(1); r:expect(0, 0)
end)

test("each motor requires its own DC and AC supplies", function()
    for _, bus in ipairs({"bus27_volt_left", "bus115_1_volt", "bus27_volt_right", "bus115_3_volt"}) do
        local r = controller()
        r:power(true, true)
        r:set("wiper_left", 1); r:set("wiper_right", 1)
        r:set(bus, 0)
        r:step(0.1)
        if bus == "bus27_volt_left" or bus == "bus115_1_volt" then
            r:expect(0, angle(0.3))
        else
            r:expect(angle(0.3), 0)
        end
    end
end)

test("speed changes preserve phase instead of jumping to park", function()
    local r = controller()
    r:power(true, true)
    r:set("wiper_left", -1); r:set("wiper_right", 1)
    r:step(0.1)
    r:set("wiper_left", 1); r:set("wiper_right", -1)
    r:step(0.1); r:expect(angle(0.45), angle(0.45))
end)

test("pause and invalid time steps do not corrupt motor phase", function()
    local r = controller()
    r:power(true, true)
    r:set("wiper_left", -1); r:set("wiper_right", 1)
    r:step(0.1)
    for _, dt in ipairs({0, -1, math.huge, -math.huge, 0 / 0}) do
        r:step(dt); r:expect(angle(0.15), angle(0.3))
    end
    r:step(0.1); r:expect(angle(0.3), angle(0.6))
end)

test("wiper processing leaves unrelated surface outputs intact", function()
    local r = controller()
    r:power(true, true)
    r:set("wiper_left", 1); r:set("wiper_right", -1)
    r:set("revers_L", 0.2); r:set("revers_R", 0.8)
    r:set("elevator_L", -40); r:set("elevator_R", 40)
    r:set("brake_emerg", 0.7)
    r:step(0.1)
    near(r:get("reverse_mid"), 0.5, "Reverser average unchanged")
    near(r:get("elev_anim_L"), -25, "Left elevator limit unchanged")
    near(r:get("elev_anim_R"), 20, "Right elevator limit unchanged")
    near(r:get("brake_emerg_L"), 0.7, "Left emergency lever unchanged")
    near(r:get("brake_emerg_R"), 0.7, "Right emergency lever unchanged")
end)

print("PASS wiper control: " .. scenarios .. " scenarios, " .. assertions .. " assertions")
