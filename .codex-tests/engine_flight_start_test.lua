-- Real start/fuel components with mocked SASL properties and starter commands.
-- These regressions do not simulate X-Plane combustion or an actual flight.
local root = arg[1] or "."
local assertions, scenarios = 0, 0
local function eq(actual, expected, label)
    assertions = assertions + 1
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function rig(hot)
    local values, writes, commands = {}, {}, {}
    local function loadComponent(relative)
        local env = setmetatable({}, {__index = _G})
        local function property(path) if values[path] == nil then values[path] = 0 end return path end
        env.globalProperty, env.globalPropertyf, env.globalPropertyi = property, property, property
        env.defineProperty = function(name, prop) env[name] = prop end
        env.get = function(prop) assert(prop and values[prop] ~= nil, "Unbound read"); return values[prop] end
        env.set = function(prop, value)
            assert(prop and values[prop] ~= nil, "Unbound write")
            assert(value == value and math.abs(value) < math.huge, "Invalid output")
            values[prop] = value
            writes[#writes + 1] = prop
        end
        env.clamp = function(v, lo, hi) return math.max(lo, math.min(hi, v)) end
        env.bool2int = function(v) return v and 1 or 0 end
        env.fastInterpolate = function(t, v)
            for i = 2, #t do
                if v <= t[i][1] then
                    return t[i-1][2] + (t[i][2]-t[i-1][2]) * (v-t[i-1][1]) / (t[i][1]-t[i-1][1])
                end
            end
            return t[#t][2]
        end
        env.sasl = {
            findCommand = function(path) commands[path] = {begin_count=0, end_count=0, held=false}; return path end,
            commandBegin = function(path)
                local c = commands[path]; assert(not c.held, "Double commandBegin"); c.held = true; c.begin_count = c.begin_count + 1
            end,
            commandEnd = function(path)
                local c = commands[path]; assert(c.held, "Unowned commandEnd"); c.held = false; c.end_count = c.end_count + 1
            end,
            al = {loadSample = function(path) return path end, playSample = function() end},
        }
        local path = root .. "/plugins/sasl/data/modules/Custom Module/" .. relative
        local chunk
        if setfenv then chunk = assert(loadfile(path)); setfenv(chunk, env)
        else chunk = assert(loadfile(path, "t", env)) end
        chunk()
        return env
    end
    local fuel = loadComponent("fuel_system/fuel_engines.lua")
    local start = loadComponent("start_system/start_logic.lua")
    local initializer = loadComponent("aircraft_init.lua")
    local r = {values=values, writes=writes, commands=commands, start=start, fuel=fuel}
    function r:set(name, value) values[assert(start[name] or fuel[name], name)] = value end
    function r:get(name) return values[assert(start[name] or fuel[name], name)] end
    function r:engine(i, n2, burning)
        self:set("eng_rpm" .. i, n2); self:set("eng_work" .. i, burning)
    end
    function r:preset(running)
        -- aircraft_init applies custom controls; X-Plane applies native engine
        -- mixture/ignition. Neither operation is performed continuously here.
        self:set("startup_running", running and 1 or 0)
        self:set("bus27_volt_left", running and 28 or 0)
        self:set("bus27_volt_right", running and 28 or 0)
        for i = 1, 4 do
            self:set("tank1_" .. i, running and 1 or 0)
            self:set("pump_tank1_" .. i .. "_on", running and 1 or 0)
        end
        for i = 1, 3 do
            self:set("fire_valve_" .. i, running and 1 or 0)
            self:set("fuel_in_" .. i, running and 1 or 0)
            self:set("eng_mix_" .. i, running and 1 or 0)
            self:set("sim_ignition" .. i, running and 3 or 0)
            self:set("sim_igniter" .. i, running and 1 or 0)
        end
    end
    function r:tick()
        self:set("frame_time", 0.1)
        initializer.update()
        fuel.update() -- Production component ordering: fuel before starter.
        start.update()
    end
    function r:run(seconds) for _ = 1, math.floor(seconds*10+0.5) do self:tick() end end
    function r:newFlight(running)
        self:preset(running)
        initializer.onAirportLoaded(3)
        fuel.onAirportLoaded(3) -- flightIndex is not an AI aircraft index.
        start.onAirportLoaded(3)
    end
    function r:groundStart(mode)
        self:tick() -- Finish the initial cold preset before simulated pilot actions.
        self:set("engine_caps", 0)
        self:set("fire_valve_1", 1); self:set("eng_mix_1", 1)
        self:set("bus27_volt_left", 28); self:set("bus27_volt_right", 28)
        for i = 1, 4 do self:set("tank1_" .. i, 1) end
        self:set("auto_tanks_turn", 1); self:set("fuel_flow_mode", 1)
        self:set("starter_switch", 1); self:set("starter_eng_select", 1)
        self:set("starter_mode", mode); self:set("starter_pressure", 4.5)
        self:set("starter_start", 1); self:tick(); self:set("starter_start", 0)
        self:run(2)
    end
    r:set("starter_rpm", 0.26)
    r:preset(hot)
    return r
end
local function test(name, body) body(); scenarios=scenarios+1; print("PASS " .. name) end

test("hot load survives initially zero native RPM and combustion", function()
    local r = rig(true)
    r:run(1)
    for i=1,3 do
        eq(r:get("fuel_in_"..i), 1, "Hot fuel admission")
        eq(r:get("sim_ignition"..i), 3, "Native ignition preserved")
        eq(r:get("engine_"..i.."_fuel"), 0, "No artificial fuel cut")
        r:engine(i, 38, 1)
    end
    r:run(90)
    for i=1,3 do
        eq(r:get("fuel_in_"..i), 1, "Idle beyond old timeout")
        eq(r:get("apd_working_"..i), 0, "No synthetic starter sequence")
        eq(r.commands["sim/starters/engage_starter_"..i].begin_count, 0, "No starter command")
    end
end)
test("cold flight remains cold", function()
    local r=rig(false); r:run(70)
    for i=1,3 do
        eq(r:get("fuel_in_"..i),0,"Cold admission")
        eq(r:get("engine_"..i.."_fuel"),6,"Cold native cutoff")
        eq(r:get("fire_vlv_open_"..i),0,"Cold valve")
    end
end)
test("same-aircraft cold to hot flight resets closed local valves", function()
    local r=rig(false); r:run(70); r:newFlight(true); r:tick()
    for i=1,3 do
        eq(r:get("fire_vlv_open_"..i),1,"Hot valve at first update")
        eq(r:get("engine_"..i.."_fuel"),0,"Hot fuel immediately available")
        eq(r:get("fuel_in_"..i),1,"Old APD age ignored")
    end
end)
test("deliberate fire valve and mixture shutdown stay effective", function()
    local r=rig(true); r:run(1)
    r:set("fire_valve_1",0); r:set("eng_mix_2",0); r:run(10)
    eq(r:get("engine_1_fuel"),6,"Closed fire valve cuts fuel")
    eq(r:get("engine_2_fuel"),6,"Closed mixture cuts fuel")
    eq(r:get("engine_3_fuel"),0,"Other engine unaffected")
    eq(r:get("fire_vlv_open_1"),0,"Preset not reapplied each frame")
    eq(r:get("eng_mix_2"),0,"No forced mixture reopening")
end)
test("normal APD completion at XP12 low idle retains fuel", function()
    local r=rig(false); r:groundStart(1); r:engine(1,22,0); r:tick()
    eq(r:get("fuel_in_1"),1,"APD admits fuel")
    eq(r:get("sim_ignition1"),1,"APD ignition")
    r:engine(1,38,1); r:run(3); r:run(65)
    eq(r:get("apd_working_1"),0,"APD complete")
    eq(r:get("fuel_in_1"),1,"Running engine fuel retained")
    eq(r.commands["sim/starters/engage_starter_1"].held,false,"Starter released")
end)
test("failed active start still times out", function()
    local r=rig(false); r:groundStart(1); r:engine(1,30,0); r:run(60)
    eq(r:get("fuel_in_1"),0,"Failed start cutoff")
    eq(r:get("sim_ignition1"),0,"Failed start ignition off")
    eq(r:get("apd_working_1"),0,"Failed APD stopped")
    eq(r.commands["sim/starters/engage_starter_1"].held,false,"Failed starter released")
end)
test("dry crank never admits fuel", function()
    local r=rig(false); r:groundStart(0); r:engine(1,25,0); r:run(10)
    eq(r:get("fuel_in_1"),0,"Dry crank fuel")
    eq(r:get("sim_ignition1"),0,"Dry crank ignition")
end)
test("power loss abort remains active", function()
    local r=rig(false); r:groundStart(1); r:engine(1,25,0); r:tick()
    r:set("bus27_volt_left",0); r:tick()
    eq(r:get("fuel_in_1"),0,"Power loss cutoff")
    eq(r.commands["sim/starters/engage_starter_1"].held,false,"Power loss releases command")
end)
test("pause does not consume APD timeout", function()
    local r=rig(false); r:groundStart(1); r:engine(1,25,0); r:tick()
    r:set("sim_paused",1); r:run(70)
    eq(r:get("apd_working_1"),1,"Paused APD remains active")
    r:set("sim_paused",0); r:run(60)
    eq(r:get("apd_working_1"),0,"Unpaused failed APD times out")
end)
test("engine covers still block engines", function()
    local r=rig(true); r:tick(); r:engine(1,38,1); r:set("engine_caps",1); r:tick()
    eq(r:get("fuel_in_1"),0,"Cover safety preserved")
end)
test("new flight releases previous APD command without native engine writes", function()
    local r=rig(false); r:groundStart(1)
    eq(r.commands["sim/starters/engage_starter_1"].held,true,"APD initially held")
    r:newFlight(true); r:tick()
    eq(r.commands["sim/starters/engage_starter_1"].held,false,"Flight reset releases command")
    eq(r:get("sim_ignition1"),3,"New native hot ignition retained")
    eq(r:get("fuel_in_1"),1,"New flight fuel retained")
end)
test("SCP slave writes no native engine or fuel properties", function()
    local r=rig(true); r:set("ismaster",1); r:newFlight(true)
    local before=#r.writes; r:run(70)
    for i=before+1,#r.writes do eq(r.writes[i]:sub(1,4)=="sim/",false,"No slave native write") end
end)
test("fuel starvation protections remain effective", function()
    local r=rig(true); r:tick(); r:set("elevation",10000)
    for i=1,4 do r:set("tank1_"..i,0); r:set("pump_tank1_"..i.."_on",0) end
    r:tick()
    for i=1,3 do eq(r:get("engine_"..i.."_fuel"),6,"Unpressurized high-altitude cutoff") end
end)
test("established stopped engine retains delayed fuel and ignition cleanup", function()
    local r=rig(true); r:engine(1,38,1); r:run(70)
    r:set("eng_mix_1",0); r:engine(1,20,0); r:tick()
    eq(r:get("engine_1_fuel"),6,"Mixture cutoff remains immediate")
    eq(r:get("fuel_in_1"),0,"Established engine shutdown clears fuel latch")
    eq(r:get("sim_ignition1"),0,"Established engine shutdown clears ignition")
    eq(r:get("sim_igniter1"),0,"Established engine shutdown clears igniter")
end)
test("hot preset aloft bridges generator and boost pump initialization once", function()
    local r=rig(false); r:run(70); r:newFlight(true); r:set("elevation",10000)
    for i=1,4 do r:set("tank1_"..i,0) end
    r:run(3.2)
    for i=1,3 do eq(r:get("engine_"..i.."_fuel"),0,"Primed hot fuel while contactors settle") end
    for i=1,4 do r:set("tank1_"..i,1) end
    r:run(5)
    for i=1,3 do eq(r:get("engine_"..i.."_fuel"),0,"Actual pumps take over without another pressure delay") end
    for i=1,4 do r:set("tank1_"..i,0) end
    r:tick()
    for i=1,3 do eq(r:get("engine_"..i.."_fuel"),6,"No repeated priming during subsequent failure") end
end)
test("hot priming expires if the actual supply never becomes available", function()
    local r=rig(true); r:set("elevation",10000)
    for i=1,4 do r:set("tank1_"..i,0) end
    r:run(5)
    for i=1,3 do eq(r:get("engine_"..i.."_fuel"),6,"Permanent supply failure not masked") end
end)
print(string.format("PASS %d scenarios, %d assertions", scenarios, assertions))
