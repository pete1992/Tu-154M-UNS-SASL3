--[[
Changelog
2026-10-04
- Coordinate batteries, generators, currents, 36 V, 27 V, 115 V and GPU in source order.
- Preserve per-module timing, saved state, SmartCopilot gates and GPU command revisions.
]]

-- Ordered electrical model shared by the worker and its synchronous fallback.
-- This module only handles Lua numbers/tables; the adapters own simulator I/O.
local Core = {}
local source = debug.getinfo(1, "S").source
local module_dir = source:sub(1, 1) == "@" and source:sub(2):match("^(.*)[/\\]")
local model_names = { "battery", "generators", "currents", "bus36", "bus27", "bus115", "gpu" }
local models = {}
for _, name in ipairs(model_names) do
    -- XTLua's dofile resolves relative to its module, while SASL supplies an
    -- ordinary loadfile path. Use the physical path when one is available.
    if module_dir then
        models[name] = assert(loadfile(module_dir .. "/models/" .. name .. ".lua"))()
    else
        models[name] = dofile("models/" .. name .. ".lua")
    end
end

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end
Core.copy = copy

local function finite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end
Core.finite = finite

-- Match the aircraft's main.lua interpolation, including both endpoints.
local function interpolate(tbl, value)
    local lastActual, lastReference = 0, 0
    for i = 1, #tbl do
        local v = tbl[i]
        if value == v[1] then return v[2] end
        if value < v[1] then
            local d = v[1] - lastActual
            if d == 0 then return lastReference end
            return lastReference + (value - lastActual) / d * (v[2] - lastReference)
        end
        lastActual, lastReference = v[1], v[2]
    end
    return value - lastActual + lastReference
end

local function canonical(path, index)
    return index ~= nil and path .. "[" .. index .. "]" or path
end
Core.canonical = canonical

local instances = {}
for i = 1, 4 do
    local bindings = copy(models.battery.bindings)
    for _, row in ipairs(bindings) do
        local alias = row[1]
        if alias == "bat_on_bus" then row[2] = "tu154/custom/switchers/eng/bat" .. i .. "_on"
        elseif alias == "bat_fail" then row[2] = "tu154/custom/failures/bat_" .. i .. "_fail"
        elseif alias == "bat_kz" then row[2] = "tu154/custom/failures/bat_" .. i .. "_kz"
        elseif alias == "bus_volt" then
            row[2] = "tu154/custom/elec/bus27_volt_" .. (i % 2 == 0 and "right" or "left")
        elseif alias == "sim_bat_on" then row[4] = i - 1
        elseif row[2]:match("^tu154/custom/elec/bat_") then
            row[2] = row[2]:gsub("_1$", "_" .. i)
        end
    end
    instances[#instances + 1] = { name = "battery" .. i, model = models.battery, bindings = bindings }
end
for i = 2, #model_names do
    local name = model_names[i]
    instances[#instances + 1] = { name = name, model = models[name], bindings = models[name].bindings }
end

Core.bindings, Core.owned, Core.urgent = {}, {}, {}
local known = {}
for _, instance in ipairs(instances) do
    instance.aliases = {}
    for _, row in ipairs(instance.bindings) do
        local key = canonical(row[2], row[4])
        instance.aliases[row[1]] = key
        if not known[key] then
            local definition = { key = key, path = row[2], kind = row[3], index = row[4] }
            known[key] = definition
            Core.bindings[#Core.bindings + 1] = definition
        end
    end
    for _, alias in ipairs(instance.model.outputs) do
        Core.owned[assert(instance.aliases[alias], alias)] = true
    end
end

Core.role_key = "scp/api/ismaster"
Core.dt_key = "tu154/custom/time/frame_time"
Core.gpu_command = "tu154/custom/anim/gpu_present"
Core.gpu_revision_key = "__electric_gpu_command_revision"
-- Commands remain external inputs even when GPU ejection writes them once.
Core.external_outputs = { [Core.gpu_command] = true }
for _, definition in ipairs(Core.bindings) do
    local key = definition.key
    if not Core.owned[key] and (key:find("/switchers/", 1, true)
        or key:find("/failures/", 1, true)
        or key == Core.role_key or key == Core.gpu_command
        or key == "tu154/custom/elec/apu_start_seq") then
        Core.urgent[key] = true
    end
end
Core.urgent[Core.gpu_command] = true

function Core.new(initial, saved, random)
    assert(type(initial) == "table", "electrical inputs missing")
    local self = {
        values = {}, writes = {}, components = {},
        gpu_command_revision = saved and saved.gpu_command_revision
            or initial[Core.gpu_revision_key] or 0,
    }
    for _, definition in ipairs(Core.bindings) do
        local key = definition.key
        local value = saved and saved.values[key] or initial[key]
        assert(finite(value), "invalid electrical input: " .. key)
        self.values[key] = value
    end
    for _, instance in ipairs(instances) do
        local aliases = instance.aliases
        local io = {
            get = function(alias)
                return self.values[assert(aliases[alias], "unknown electrical binding: " .. tostring(alias))]
            end,
            set = function(alias, value)
                local key = assert(aliases[alias], "unknown electrical output: " .. tostring(alias))
                assert(Core.owned[key] and finite(value), "invalid electrical output: " .. key)
                self.values[key], self.writes[key] = value, value
            end,
            random = random or math.random,
            interpolate = interpolate,
        }
        self.components[#self.components + 1] = {
            name = instance.name,
            instance = instance.model.create(io, saved and saved.models[instance.name]),
        }
    end

    function self:step(inputs)
        assert(type(inputs) == "table", "electrical sample missing")
        local slave = inputs[Core.role_key] == 1
        local revision = inputs[Core.gpu_revision_key]
        if revision ~= nil then
            assert(finite(revision) and revision >= 0 and revision % 1 == 0,
                "invalid GPU command revision")
        end
        -- Ownership can change inside a replayed batch. Do not publish a
        -- preceding master's writes over the newly synchronized slave state.
        if slave then self.writes = {} end
        for _, definition in ipairs(Core.bindings) do
            local key = definition.key
            local value = inputs[key]
            assert(finite(value), "invalid electrical sample: " .. key)
            -- A queued frame must not overwrite newly calculated feedback with
            -- an older published bus value. Slave snapshots are authoritative.
            if key == Core.gpu_command and not slave then
                -- Repeated captured values are not new commands. In particular,
                -- an older 'present' sample must not undo a queued GPU ejection.
                if revision == nil or revision ~= self.gpu_command_revision then
                    self.values[key], self.writes[key] = value, nil
                end
            elseif slave or not Core.owned[key] then
                self.values[key] = value
            end
        end
        if revision ~= nil then self.gpu_command_revision = revision end
        for _, item in ipairs(self.components) do item.instance.update() end
    end

    function self:outputs()
        return copy(self.writes)
    end

    function self:export()
        local state = {
            values = copy(self.values), models = {},
            gpu_command_revision = self.gpu_command_revision,
        }
        for _, item in ipairs(self.components) do
            state.models[item.name] = item.instance.export()
        end
        return state
    end
    return self
end

return Core
