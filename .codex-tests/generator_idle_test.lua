-- Offline regression for the actual SASL engine/APU generator controller.
-- This mocks inputs only; it is not a simulator electrical/engine runtime test.
local root = arg[1] or "."
local file = root .. "/plugins/sasl/data/modules/Custom Module/electric_system/generators_logic.lua"
local assertions, scenarios = 0, 0

local function eq(actual, expected, label)
    assertions = assertions + 1
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function near(actual, expected, label)
    assertions = assertions + 1
    assert(math.abs(actual - expected) < 0.000001, label .. ": expected " .. expected .. ", got " .. actual)
end

local function controller(initial_running)
    local values, definitions, writes = {}, {}, {}
    local env = setmetatable({}, { __index = _G })
    local readonly = {
        ["sim/cockpit2/electrical/generator_volts"] = true,
        ["sim/aircraft/electrical/acf_nom_gen_volt"] = true,
    }
    local function scalar(path) return {path = path, key = path} end
    local function element(path, index)
        assert(index >= 1 and index <= 3, "Native engine indices must use SASL elements 1..3")
        return {path = path, index = index, key = path .. "[" .. (index - 1) .. "]"}
    end
    env.globalPropertyi = scalar
    env.globalPropertyf = scalar
    env.globalPropertyiae = element
    env.globalPropertyfae = element
    env.defineProperty = function(name, prop)
        assert(not definitions[name], "Duplicate binding: " .. name)
        definitions[name] = prop
        env[name] = prop
        values[prop.key] = 0
        if initial_running then
            if name:match("^gen_%d_on$") then values[prop.key] = 1 end
            if name:match("^eng%d_N2$") then values[prop.key] = 70 end
            if name:match("^sim_gen%d_volt$") then values[prop.key] = 24.5 end
            if name == "DC_27_volt1" or name == "DC_27_volt2" then values[prop.key] = 28 end
        end
        if name == "sim_gen_nominal_volt" then values[prop.key] = 24.5 end
    end
    env.get = function(prop)
        assert(prop and values[prop.key] ~= nil, "Unbound property read")
        return values[prop.key]
    end
    env.set = function(prop, value)
        assert(prop and values[prop.key] ~= nil, "Unbound property write")
        assert(not readonly[prop.path], "Write to read-only native property: " .. prop.path)
        assert(type(value) == "number" and value == value and math.abs(value) < math.huge, "Non-finite output")
        values[prop.key] = value
        writes[#writes + 1] = {prop.key, value}
    end
    local chunk
    if setfenv then
        chunk = assert(loadfile(file))
        setfenv(chunk, env)
    else
        chunk = assert(loadfile(file, "t", env))
    end
    chunk()
    local r = {definitions = definitions, writes = writes}
    function r:set(name, value) values[assert(definitions[name], name).key] = value end
    function r:get(name) return values[assert(definitions[name], name).key] end
    function r:tick(dt) self:set("frame_time", dt or 0.1); env.update() end
    function r:run(seconds, step)
        step = step or 0.1
        for _ = 1, math.floor(seconds / step + 0.001) do self:tick(step) end
    end
    function r:engine(i, rpm, potential)
        self:set("eng" .. i .. "_N2", rpm)
        self:set("sim_gen" .. i .. "_volt", potential)
    end
    function r:all_ready()
        self:set("DC_27_volt1", 28)
        self:set("DC_27_volt2", 28)
        for i = 1, 3 do self:engine(i, 70, 24.5); self:set("gen_" .. i .. "_on", 1) end
    end
    function r:online(i, expected, label)
        eq(self:get("gen" .. i .. "_work"), expected, label .. " custom work")
        eq(self:get("sim_gen" .. i .. "_on"), expected, label .. " native switch")
        if expected == 0 then near(self:get("gen" .. i .. "_volt_bus"), 0, label .. " voltage") end
    end
    return r
end

local function test(name, body)
    body()
    scenarios = scenarios + 1
    print("PASS " .. name)
end

test("running-aircraft initialization", function()
    local r = controller(true)
    r:tick()
    for i = 1, 3 do r:online(i, 1, "Running engine " .. i) end
end)

test("stopped and starter-only engines cannot supply", function()
    local r = controller()
    r:all_ready()
    for _, rpm in ipairs({0, 5, 20, 26, 100}) do
        for i = 1, 3 do r:engine(i, rpm, 0) end
        r:run(4)
        for i = 1, 3 do r:online(i, 0, "Unpowered shaft " .. rpm) end
    end
    for i = 1, 3 do r:engine(i, 0, 24.5) end
    r:run(4)
    for i = 1, 3 do r:online(i, 0, "Stale voltage with stopped core") end
end)

test("idle supply follows native available voltage, not legacy fan RPM", function()
    local r = controller()
    r:all_ready()
    for _, rpm in ipairs({37, 38, 60, 73.78}) do
        for i = 1, 3 do r:engine(i, rpm, 24.5) end
        r:run(3)
        for i = 1, 3 do r:online(i, 1, "Native idle-capable supply at core RPM " .. rpm) end
    end
end)

test("connection delay and independent engines", function()
    local r = controller()
    r:all_ready()
    r:engine(2, 0, 0)
    r:tick(0.1)
    r:run(1.9)
    for i = 1, 3 do r:online(i, 0, "Connection delay") end
    r:run(0.3)
    r:online(1, 1, "Engine 1")
    r:online(2, 0, "Engine 2 stopped")
    r:online(3, 1, "Engine 3")
    r:engine(2, 70, 24.5)
    r:run(1.9)
    r:online(2, 0, "Independent engine 2 delay")
    r:run(0.3)
    r:online(2, 1, "Engine 2 connected")
end)

test("voltage hysteresis prevents idle contactor chatter", function()
    local r = controller(true)
    r:tick()
    for n = 1, 40 do
        r:engine(1, 38, 24.5 * (n % 2 == 0 and 0.87 or 0.91))
        r:tick()
        r:online(1, 1, "Inside hysteresis band")
    end
    r:engine(1, 38, 24.5 * 0.84)
    r:tick()
    r:online(1, 0, "Undervoltage disconnect")
    r:engine(1, 38, 24.5 * 0.87)
    r:run(4)
    r:online(1, 0, "Band does not reconnect")
    r:engine(1, 38, 24.5 * 0.91)
    r:run(1.9)
    r:online(1, 0, "Recovery preserves delay")
    r:run(0.3)
    r:online(1, 1, "Recovered supply")
end)

test("native nominal voltage is normalized independently of custom 115V", function()
    for _, nominal in ipairs({24.5, 28, 115}) do
        local r = controller()
        r:all_ready()
        r:set("sim_gen_nominal_volt", nominal)
        r:engine(1, 38, nominal * 0.899)
        r:run(3)
        r:online(1, 0, "Below connection ratio")
        r:engine(1, 38, nominal * 0.90)
        r:run(3)
        r:online(1, 1, "Exact connection ratio")
        near(r:get("gen1_volt_bus"), 122, "Custom unloaded voltage is not native voltage")
        r:engine(1, 38, nominal * 0.85)
        r:tick()
        r:online(1, 1, "Exact hold ratio")
        r:engine(1, 38, nominal * 0.849)
        r:tick()
        r:online(1, 0, "Below hold ratio")
    end
end)

test("spindown removes supply and resets delay", function()
    local r = controller(true)
    r:tick()
    r:engine(1, 20, 18)
    r:tick()
    r:online(1, 0, "Low rotation voltage")
    r:engine(1, 0, 0)
    r:run(3)
    r:online(1, 0, "Stopped after spindown")
    r:engine(1, 70, 24.5)
    r:run(1.9)
    r:online(1, 0, "Spindown reset connection timer")
    r:run(0.3)
    r:online(1, 1, "Restored engine")
end)

test("DC excitation uses either existing bus and fails at threshold", function()
    local r = controller(true)
    r:tick()
    r:set("DC_27_volt1", 0)
    r:tick()
    r:online(1, 1, "Right bus excitation")
    r:set("DC_27_volt2", 13)
    r:tick()
    for i = 1, 3 do r:online(i, 0, "Both DC buses unavailable") end
    r:set("DC_27_volt1", 28)
    r:run(3)
    for i = 1, 3 do r:online(i, 1, "Left bus excitation restored") end
end)

test("OFF and emergency cutoff remain authoritative", function()
    for i = 1, 3 do
        local r = controller(true)
        r:tick()
        r:set("emerg_gen_on_" .. i, 1)
        r:tick()
        r:online(i, 0, "Emergency cutoff " .. i)
        eq(r:get("gen_" .. i .. "_on"), 1, "Emergency retains normal switch")
        r:set("emerg_gen_on_" .. i, 0)
        r:run(1.9)
        r:online(i, 0, "Emergency release delay")
        r:run(0.3)
        r:online(i, 1, "Emergency release connected")
        r:set("gen_" .. i .. "_on", 0)
        r:run(3)
        r:online(i, 0, "Normal OFF")
    end
end)

test("TEST produces unloaded voltage but never feeds bus", function()
    local r = controller(true)
    r:tick()
    r:set("gen_1_on", -1)
    r:tick()
    r:run(3)
    near(r:get("gen1_volt_bus"), 122, "TEST available voltage")
    eq(r:get("gen1_work"), 0, "TEST custom contactor open")
    eq(r:get("sim_gen1_on"), 0, "TEST native contactor open")
    r:set("emerg_gen_on_1", 1)
    r:tick()
    r:online(1, 0, "Emergency overrides TEST")
end)

test("native failures remain authoritative and independent", function()
    for i = 1, 3 do
        local r = controller(true)
        r:tick()
        r:set("sim_gen" .. i .. "_fail", 6)
        r:tick()
        r:online(i, 0, "Failed generator " .. i)
        eq(r:get("sim_gen" .. i .. "_fail"), 6, "Failure not erased")
        r:online(i % 3 + 1, 1, "Other generator remains connected")
        r:set("sim_gen" .. i .. "_fail", 2)
        r:tick()
        r:online(i, 1, "Scheduled failure is not failed now")
        eq(r:get("sim_gen" .. i .. "_fail"), 2, "Scheduled failure not erased")
    end
end)

test("load droop and delayed overload trip/reset preserved", function()
    local r = controller(true)
    r:tick()
    r:set("gen1_amp_bus", 500)
    r:run(20)
    near(r:get("gen1_volt_bus"), 121, "Original 500A droop")
    eq(r:get("gen1_overload"), 0, "500A boundary does not trip")
    r:set("gen1_amp_bus", 501)
    r:run(14)
    r:online(1, 1, "Brief overcurrent allowed")
    r:run(2)
    r:tick()
    eq(r:get("gen1_overload"), 1, "Sustained overcurrent latched")
    r:online(1, 0, "Overload removes supply")
    r:set("gen1_amp_bus", 0)
    r:run(2)
    r:online(1, 0, "Overload stays latched")
    r:set("gen_1_on", 0)
    r:tick()
    eq(r:get("gen1_overload"), 0, "OFF resets overload")
    r:set("gen_1_on", 1)
    r:run(3)
    r:online(1, 1, "Reset reconnects after delay")
end)

test("APU threshold, delay, failure and switch unchanged", function()
    local r = controller()
    r:set("DC_27_volt1", 28)
    r:set("apu_gen_on", 1)
    r:set("eng4_N1", 92)
    r:run(4)
    eq(r:get("gen4_work"), 0, "APU at threshold remains disconnected")
    r:set("eng4_N1", 95)
    r:run(1.9)
    eq(r:get("gen4_work"), 0, "APU connection delay")
    r:run(0.3)
    eq(r:get("gen4_work"), 1, "APU connected")
    r:set("apu_gen_fail", 1)
    r:tick()
    eq(r:get("gen4_work"), 0, "APU failure")
    r:set("apu_gen_fail", 0)
    r:set("apu_gen_on", 0)
    r:tick()
    near(r:get("gen4_volt_bus"), 0, "APU OFF voltage")
end)

test("non-finite speed/voltage/nominal cannot create supply", function()
    for _, field in ipairs({"eng1_N2", "sim_gen1_volt", "sim_gen_nominal_volt"}) do
        for _, value in ipairs({0, -1, 0 / 0, math.huge, -math.huge}) do
            local r = controller(true)
            r:tick()
            r:set(field, value)
            r:tick()
            r:online(1, 0, "Invalid availability input " .. field)
        end
    end
end)

test("paused/invalid timing and SmartCopilot slave do not write", function()
    local r = controller(true)
    r:tick()
    for _, dt in ipairs({0, -1, 0 / 0, math.huge}) do
        local before = #r.writes
        r:tick(dt)
        eq(#r.writes, before, "Invalid/no elapsed time has no writes")
    end
    r:set("ismaster", 1)
    local before = #r.writes
    r:tick()
    eq(#r.writes, before, "Slave does not own generator writes")
end)

test("SASL indexed bindings match native arrays", function()
    local r = controller()
    for i = 1, 3 do
        eq(r.definitions["eng" .. i .. "_N2"].path, "sim/flightmodel/engine/ENGN_N2_", "Core RPM array path")
        eq(r.definitions["eng" .. i .. "_N2"].index, i, "Core RPM SASL index")
        eq(r.definitions["sim_gen" .. i .. "_volt"].index, i, "Generator voltage SASL index")
        eq(r.definitions["sim_gen" .. i .. "_on"].index, i, "Native contactor SASL index")
    end
end)

print(string.format("PASS: %d scenarios, %d assertions", scenarios, assertions))
