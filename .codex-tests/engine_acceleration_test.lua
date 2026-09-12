-- Offline regression for the actual rud_logic module and its acceleration helper.
-- No X-Plane connection: native reads/writes and command registration are mocked.
-- Usage: fengari engine_acceleration_test.lua <aircraft-directory>
local root = assert(arg[1], "Provide the aircraft directory")
local path = root .. "/plugins/sasl/data/modules/Custom Module/engines_system/rud_logic.lua"
local scenarios, assertions = 0, 0
local function check(condition, message)
    assert(condition, message); assertions = assertions + 1
end
local function near(actual, expected, tolerance, message)
    check(type(actual) == "number" and math.abs(actual - expected) <= tolerance,
        message .. ": " .. tostring(actual) .. " versus " .. tostring(expected))
end
local function upvalue(fn, wanted)
    for i = 1, 100 do
        local name, value = debug.getupvalue(fn, i)
        if not name then break end
        if name == wanted then return value end
    end
    error("Missing production upvalue " .. wanted)
end

local function controller(version, input)
    local env = setmetatable({}, {__index = _G})
    local values, properties, bindings, writes = {}, {}, {}, {}
    values["sim/version/xplane_internal_version"] = version or 12000
    for i = 0, 2 do values["tu154/custom/SC/engine/ENGN_thro_" .. i] = input or 0 end
    local function accessor(kind)
        return function(property, index)
            local key = property .. (index and ("#" .. index) or "")
            properties[key] = {path = property, kind = kind, index = index}
            return key
        end
    end
    env.globalProperty = accessor("generic")
    env.globalPropertyf, env.globalPropertyi = accessor("float"), accessor("int")
    env.globalPropertyfae = accessor("float-array-element")
    env.defineProperty = function(name, property)
        env[name] = property; bindings[name] = properties[property]
    end
    env.get = function(property)
        return values[assert(property, "Undefined property read")] or 0
    end
    env.set = function(property, value)
        assert(property, "Undefined property write")
        check(type(value) == "number" and value == value and math.abs(value) < math.huge,
            "Non-finite production write " .. property)
        check(not property:find("EGT", 1, true), "Temperature/redline must remain read only")
        writes[property] = (writes[property] or 0) + 1; values[property] = value
    end
    env.sasl = {
        findCommand = function(command) return command end,
        registerCommandHandler = function() end,
    }
    env.print = function() end
    env.safeClamp = function(value, low, high, default)
        if type(value) ~= "number" or value ~= value then return default or 0 end
        return math.max(low, math.min(high, value))
    end
    env.line = function(x, x1, y1, x2, y2)
        return y1 + (x - x1) * (y2 - y1) / (x2 - x1)
    end
    env.fastInterpolate = function(points, x)
        for i = 2, #points do
            if x <= points[i][1] then
                return env.line(x, points[i - 1][1], points[i - 1][2], points[i][1], points[i][2])
            end
        end
        return points[#points][2]
    end
    local chunk
    if setfenv then chunk = assert(loadfile(path)); setfenv(chunk, env)
    else chunk = assert(loadfile(path, "t", env)) end
    chunk()
    local r = {env = env, bindings = bindings, writes = writes, values = values}
    r.limit = upvalue(env.update, "limitAcceleration")
    r.state = upvalue(r.limit, "acceleration_state")
    function r:set(name, value) values[assert(env[name], name)] = value end
    function r:get(name) return env.get(assert(env[name], name)) end
    function r:step(count) for _ = 1, count or 1 do env.update() end end
    function r:run(engine, demand, temperature, dt, idle, redline, actual)
        return self.limit(engine, demand, idle or 0.1915, temperature, redline or 708, dt or 0.1, actual)
    end
    r:set("frame_time", 0.1); r:set("baro_press", 29.92); r:set("outside_air_temp", 15)
    if (version or 12000) >= 12000 then
        r:set("engine_egt_redline", 708)
        for i = 1, 3 do r:set("engine_egt_" .. i, 500) end
    end
    return r
end

local function test(name, run)
    run(); scenarios = scenarios + 1; print("PASS " .. name)
end

test("XP12 typed native temperature bindings are separate and read only", function()
    local r = controller()
    near(r.bindings.xp_version.kind == "int" and 1 or 0, 1, 0, "version accessor")
    for i = 1, 3 do
        local b = r.bindings["engine_egt_" .. i]
        check(b.path == "sim/flightmodel2/engines/EGT_deg_cel", "native Celsius path")
        check(b.kind == "float-array-element" and b.index == i, "one-based engine array element")
    end
    check(r.bindings.engine_egt_redline.path == "sim/aircraft/limits/red_hi_EGT", "aircraft redline path")
    check(r.bindings.engine_egt_redline.kind == "float", "redline float accessor")
    r:step(5)
end)

test("XP11 never binds or applies native temperature schedule", function()
    local r = controller(11000, 0.8)
    check(not r.bindings.engine_egt_1 and not r.bindings.engine_egt_redline, "no XP12-only bindings")
    local target = 0.175 + 0.825 * 0.886
    local expected = 0.02
    for _ = 1, 100 do
        expected = expected + (target - expected) * (1 - math.exp(-0.775 * 0.1))
        r:step()
        for i = 1, 3 do near(r:get("sim_rud_" .. i), expected, 1e-12, "unchanged XP11 forward response") end
    end
    for i = 1, 3 do check(r.state[i].output == nil, "XP11 limiter state untouched") end
end)

test("normal EGT reaches requested power without permanent cap", function()
    local r = controller()
    local previous = 0.1915
    for _ = 1, 80 do
        local value = r:run(1, 0.975, 500)
        check(value >= previous and value <= 0.975, "monotonic bounded acceleration")
        check(value - previous <= 0.035 + 1e-12, "maximum 0.35 ratio/s rise")
        previous = value
    end
    near(previous, 0.975, 1e-12, "requested power eventually reached")
    near(r:run(1, 0.975, 500), 0.975, 1e-12, "steady demand retained")
end)

test("all three helper states are independent", function()
    local r = controller()
    for _ = 1, 40 do
        r:run(1, 0.8, 500); r:run(2, 0.8, 750); r:run(3, 0.6, 500)
    end
    near(r.state[1].output, 0.8, 1e-12, "healthy engine 1")
    near(r.state[2].output, 0.1915, 1e-12, "hot engine 2 held at idle floor")
    near(r.state[3].output, 0.6, 1e-12, "healthy engine 3 independent demand")
end)

test("full module keeps independent EGT despite linked cockpit levers", function()
    local r = controller(12000, 0.8)
    r:set("engine_egt_2", 750); r:step(150)
    check(r:get("sim_rud_1") > 0.9 and r:get("sim_rud_3") > 0.9, "healthy engines attain power")
    near(r:get("sim_rud_2"), 0.1915, 1e-12, "hot engine alone limited")
    for i = 1, 3 do near(r:get("anim_rud" .. i), 0.8, 1e-12, "cockpit lever not moved by limiter") end
end)

test("positive EGT trend holds or reduces output before current temperature reaches margin", function()
    local r = controller()
    for _ = 1, 30 do r:run(1, 0.7, 600) end
    local previous = r.state[1].output
    local value = r:run(1, 0.9, 640)
    check(640 < 708 - 25, "current temperature is below control margin")
    check(r.state[1].rate > 0, "rising temperature tracked")
    check(value < previous, "prediction anticipates hot transient")
end)

test("steady overshoot correction is bounded and never crosses idle", function()
    local r = controller()
    for _ = 1, 30 do r:run(1, 0.8, 500) end
    local previous = r.state[1].output
    for _ = 1, 100 do
        local value = r:run(1, 0.8, 733)
        check(value <= previous and previous - value <= 0.05 + 1e-12, "correction at most 0.5 ratio/s")
        check(value >= 0.1915, "idle floor respected")
        previous = value
    end
    near(previous, 0.1915, 1e-12, "sustained excessive temperature reaches idle floor")
end)

test("lower demand and idle take precedence over acceleration", function()
    local r = controller()
    for _ = 1, 30 do r:run(1, 0.8, 500) end
    near(r:run(1, 0.35, 500), 0.35, 1e-12, "lower demand passes immediately")
    near(r:run(1, 0.1915, 800), 0.1915, 1e-12, "idle demand passes despite high EGT")
    near(r:run(1, 0.02, 900), 0.02, 1e-12, "below-idle failure/start demand is not raised")
    near(r.state[1].rate, 0, 1e-12, "idle clears rate history")
end)

test("negative EGT rate does not predict an artificial temperature increase", function()
    local r = controller()
    r:run(1, 0.8, 650)
    local previous = r.state[1].output
    local value = r:run(1, 0.8, 500)
    check(r.state[1].rate < 0, "cooling rate remains negative")
    near(value - previous, 0.035, 1e-12, "cooling allows full acceleration rate")
end)

test("exact margin holds power and lower redline changes scheduling", function()
    local r = controller()
    local value = r:run(1, 0.9, 683)
    near(value, 0.1915, 1e-12, "zero headroom at 708 minus 25")
    check(r:run(2, 0.9, 600, 0.1, 0.1915, 850) > 0.1915, "higher configured redline allows rise")
    near(r:run(3, 0.9, 600, 0.1, 0.1915, 620), 0.1915, 1e-12, "lower configured redline holds")
end)

test("zero and negative frame durations do not advance output", function()
    local r = controller()
    for _ = 1, 15 do r:run(1, 0.8, 500) end
    local previous = r.state[1].output
    near(r:run(1, 0.9, 500, 0), previous, 1e-12, "zero time does not accelerate")
    near(r:run(1, 0.9, 500, -1), previous, 1e-12, "negative time does not accelerate")
    near(r:run(1, 0.25, 500, 0), 0.25, 1e-12, "zero-time lower demand returned safely")
    near(r.state[1].output, 0.25, 1e-12, "lower demand persists across pause")
    near(r:run(1, 0.9, 500), 0.285, 1e-12, "resume has no old-output rebound")
end)

test("paused frames preserve the last timed EGT sample", function()
    local r = controller()
    for _ = 1, 30 do r:run(1, 0.7, 600) end
    local previous = r.state[1].output
    near(r:run(1, 0.9, 640, 0), previous, 1e-12, "pause holds output")
    near(r.state[1].temperature, 600, 1e-12, "untimed sample not consumed")
    check(r:run(1, 0.9, 640) < previous, "resume detects preserved temperature rise")
end)

test("helper seeds from actual output without exceeding current demand", function()
    local r = controller()
    near(r:run(1, 0.8, 500, 0.1, 0.1915, 708, 0.65), 0.685, 1e-12,
        "existing actual output is used instead of idle seed")
    near(r:run(2, 0.4, 500, 0.1, 0.1915, 708, 0.9), 0.4, 1e-12,
        "startup reduction overrides higher actual output")
    near(r:run(3, 0.8, 500, 0, 0.1915, 708, 0.6), 0.6, 1e-12,
        "paused initialization preserves actual output")
end)

test("full module normal-EGT lever reduction retains the XP11 deceleration response", function()
    local current, baseline = controller(12000, 0.8), controller(11000, 0.8)
    current:step(150); baseline:step(150)
    for i = 1, 3 do current:set("tro_comm_" .. i, 0); baseline:set("tro_comm_" .. i, 0) end
    for _ = 1, 150 do
        current:step(); baseline:step()
        for i = 1, 3 do
            near(current:get("sim_rud_" .. i), baseline:get("sim_rud_" .. i), 1e-12,
                "unmodified normal deceleration engine " .. i)
        end
    end
    near(current:get("sim_rud_1"), 0.1915, 1e-6, "idle eventually reached")
end)

test("full module slave does not publish throttle or advance limiter state", function()
    local r = controller(12000, 0.8)
    r:set("ismaster", 1)
    local original = {}
    for i = 1, 3 do original[i] = r:get("sim_rud_" .. i) end
    r:step(20)
    for i = 1, 3 do
        near(r:get("sim_rud_" .. i), original[i], 0, "slave leaves synchronized throttle alone")
        check(r.state[i].output == nil, "slave does not run acceleration model")
    end
end)

test("long frames bound rise and correction per update", function()
    local r = controller()
    near(r:run(1, 0.9, 500, 10), 0.1915 + 0.035, 1e-12, "ten-second frame rise capped at 0.1 seconds")
    for _ = 1, 30 do r:run(2, 0.8, 500) end
    local previous = r.state[2].output
    local value = r:run(2, 0.8, 900, 10)
    check(previous - value <= 0.05 + 1e-12, "long-frame correction capped")
    check(value >= 0.1915 and value <= 0.8, "long frame remains bounded")
end)

test("normal schedule is frame-rate independent", function()
    local results = {}
    for _, fps in ipairs({30, 60, 120}) do
        local r = controller()
        for _ = 1, fps do r:run(1, 0.9, 500, 1 / fps) end
        results[#results + 1] = r.state[1].output
    end
    near(results[1], results[2], 1e-12, "30 versus 60 FPS")
    near(results[2], results[3], 1e-12, "60 versus 120 FPS")
    near(results[1], 0.1915 + 0.35, 1e-12, "one second rate")
end)

test("full module releases throttle override on unload", function()
    local r = controller()
    near(r:get("override"), 1, 0, "override enabled at module start")
    r.env.onModuleDone()
    near(r:get("override"), 0, 0, "override released at module shutdown")
end)

print("PASS engine acceleration: " .. scenarios .. " scenarios, " .. assertions .. " assertions; mocked actual module, no engine thermal simulation")
