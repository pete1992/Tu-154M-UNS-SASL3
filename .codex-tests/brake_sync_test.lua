-- Offline regression of the real brake module; no X-Plane connection.
-- Usage: fengari brake_sync_test.lua <aircraft-directory>
local root = assert(arg[1], "Provide the aircraft directory")
local path = root .. "/plugins/sasl/data/modules/Custom Module/brake_system/brake_system.lua"
local assertions, scenarios = 0, 0
local function check(ok, message)
    assert(ok, message)
    assertions = assertions + 1
end
local function near(actual, expected, message)
    check(type(actual) == "number" and math.abs(actual - expected) < 1e-9,
        message .. ": " .. tostring(actual) .. " versus " .. tostring(expected))
end
local function controller()
    local values, writes = {}, {}
    local e = setmetatable({}, {__index = _G})
    e.globalProperty = function(name) return name end
    e.globalPropertyi, e.globalPropertyf = e.globalProperty, e.globalProperty
    e.defineProperty = function(name, property) e[name] = property end
    e.get = function(property) return values[assert(property)] or 0 end
    e.set = function(property, value)
        assert(not property:find("sim/joystick/", 1, true), "Do not overwrite raw input")
        values[property] = value
        writes[property] = (writes[property] or 0) + 1
    end
    e.sasl = {
        al = {loadSample = function(name) return name end, playSample = function() end},
        findCommand = function(name) return name end,
        registerCommandHandler = function() end,
    }
    e.bool2int = function(value) return value and 1 or 0 end
    e.interpolate = function(points, x)
        for i = 2, #points do
            local a, b = points[i - 1], points[i]
            if x <= b[1] then return a[2] + (b[2] - a[2]) * (x - a[1]) / (b[1] - a[1]) end
        end
        return points[#points][2]
    end
    local chunk
    if setfenv then chunk = assert(loadfile(path)); setfenv(chunk, e)
    else chunk = assert(loadfile(path, "t", e)) end
    chunk()
    local r = {env = e}
    function r:set(name, value) values[assert(e[name], name)] = value end
    function r:get(name) return e.get(assert(e[name], name)) end
    function r:inputs(left, right)
        values["sim/joystick/joy_mapped_axis_value[6]"] = left
        values["sim/joystick/joy_mapped_axis_value[7]"] = right
    end
    function r:step() e.update() end
    function r:expect(left, right)
        near(self:get("l_brake_add"), left, "Left service brake")
        near(self:get("r_brake_add"), right, "Right service brake")
    end
    function r:writeCount(name) return writes[assert(e[name])] or 0 end
    r:set("frame_time", 0.1)
    r:set("gs_press_1", 120)
    r:set("gs_press_4", 120)
    r:set("parking_brake", 0)
    r:step() -- Preserve the existing one-frame pedal reset on parking release.
    return r
end
local function test(name, run)
    run()
    scenarios = scenarios + 1
    print("PASS " .. name)
end

test("near-equal inputs use their mean, symmetrically", function()
    local r = controller()
    for _, pair in ipairs({{0.50, 0.56}, {0.56, 0.50}, {0.90, 0.99}, {0.99, 0.90}, {0.45, 0.45}}) do
        r:inputs(pair[1], pair[2]); r:step()
        local mean = (pair[1] + pair[2]) / 2
        r:expect(mean, mean)
    end
end)
test("strict ten-percentage-point boundary and larger differences", function()
    local r = controller()
    for _, pair in ipairs({{0.50, 0.60}, {0.60, 0.50}, {0.80, 0.90}, {0.20, 0.30},
        {0.800000011920929, 0.899999976158142}, {0.40, 0.70}, {1, 0}, {0, 1}}) do
        r:inputs(pair[1], pair[2]); r:step(); r:expect(pair[1], pair[2])
    end
    r:inputs(0.5, 0.5999); r:step(); r:expect(0.54995, 0.54995)
end)
test("releasing both brakes and existing low-input deadband", function()
    local r = controller()
    r:inputs(0.6, 0.65); r:step()
    r:inputs(0, 0); r:step(); r:expect(0, 0)
    r:inputs(0, 0.09); r:step(); r:expect(0, 0)
    r:inputs(0, 0.10); r:step(); r:expect(0, 0.10)
end)
test("synchronization compares input, not hydraulic output", function()
    local r = controller()
    r:set("gs_press_1", 60)
    r:inputs(0.4, 0.45); r:step(); r:expect(0.2125, 0.2125)
    r:inputs(0.4, 0.55); r:step(); r:expect(0.2, 0.275)
    r:set("gs_press_1", 0); r:step(); r:expect(0, 0)
end)
test("one-sided brake failures remain one-sided", function()
    local r = controller()
    r:set("ismaster", 1) -- Keep the existing failure manager from clearing injected failures.
    r:inputs(0.5, 0.56)
    r:set("rel_lbrakes", 6); r:step(); r:expect(0, 0.53)
    r:set("rel_lbrakes", 0); r:set("rel_rbrakes", 6); r:step(); r:expect(0.53, 0)
end)
test("shared and individual keyboard commands participate in demand", function()
    local r = controller()
    r:inputs(0.4, 0.45)
    for _ = 1, 3 do r.env.left_brk_cmd_hnd(1) end
    r:step(); r:expect(0.6, 0.45)
    r.env.left_brk_cmd_hnd(2)
    r:step(); r:expect(0.425, 0.425)
    for _ = 1, 4 do r.env.regular_brk_hnd(1) end
    r:step(); r:expect(0.8, 0.8)
    r.env.regular_brk_hnd(2)
    r:inputs(0, 0); r:step(); r:expect(0, 0)
end)
test("park, emergency brakes and chocks remain independent", function()
    local r = controller()
    r:inputs(0.4, 0.46); r:set("brake_emerg", 0.8); r:step()
    r:expect(0.43, 0.43)
    near(r:get("parkbrake"), 0.8, "Emergency demand")
    near(r:get("int_brakes_L"), 0.8, "Emergency left")
    near(r:get("int_brakes_R"), 0.8, "Emergency right")
    r:set("parking_brake", 1); r:step()
    near(r:get("parkbrake"), 1, "Parking demand")
    r:set("gear_blocks", 1); r:step()
    near(r:get("parkbrake"), 5, "Chocks unchanged")
end)
test("SmartCopilot control ownership is respected", function()
    local r = controller()
    r:inputs(0.4, 0.46)
    r:set("hascontrol_1", 1)
    local before = r:writeCount("l_brake_add")
    r:step()
    check(r:writeCount("l_brake_add") == before, "No local brake writes without control")
    r:set("hascontrol_1", 2); r:step(); r:expect(0.43, 0.43)
end)
test("normal and error shutdown release the brake override", function()
    for _, isError in ipairs({false, true}) do
        local r = controller()
        r.env.onModuleShutdown(isError)
        near(r:get("overr"), 0, "Override released")
    end
end)
print("PASS brake synchronization: " .. scenarios .. " scenarios, " .. assertions .. " assertions")
