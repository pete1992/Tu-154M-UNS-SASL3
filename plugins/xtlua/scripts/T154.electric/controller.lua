--[[
Changelog
2026-10-04
- Queue frame samples and replay unacknowledged work locally when required.
- Keep timing fallbacks silent while retaining diagnostics and genuine error reports.
]]

-- One outstanding worker batch; all unacknowledged samples remain replayable.
-- The worker has no aircraft side effects, so a cancelled batch can be safely
-- recomputed from the last acknowledged state on the simulator thread.
return function(Core, Packet)
    local Controller = {}

    local function same_shape(reference, candidate)
        if type(reference) ~= type(candidate) then return false end
        if type(reference) == "number" then return Core.finite(candidate) end
        if type(reference) ~= "table" then return true end
        for key, value in pairs(reference) do
            if not same_shape(value, candidate[key]) then return false end
        end
        for key in pairs(candidate) do
            if reference[key] == nil then return false end
        end
        return true
    end

    function Controller.new(options)
        local initial = assert(options.initial)
        local self = {
            state = Core.new(initial, nil, options.random):export(),
            session = assert(options.session),
            transport = assert(options.transport),
            report = options.report or function() end,
            pending = {}, frame = 0, request = 0, completed = 0,
            batches = 0, fallbacks = 0, mode = 0, last_batch_steps = 0,
            previous = Core.copy(initial), retry_time = 0, clock = 0,
            gpu_revision = 0,
        }

        local function finish(outputs)
            if outputs[Core.gpu_command] ~= nil then
                -- The adapter publishes this action immediately after tick().
                -- Its next echo is not a new external connect/disconnect input.
                self.previous[Core.gpu_command] = outputs[Core.gpu_command]
            end
            return outputs
        end

        local function local_replay()
            local first = self.pending[1]
            if not first then return {} end
            local core = Core.new(first.inputs, self.state)
            for _, sample in ipairs(self.pending) do core:step(sample.inputs) end
            self.state = core:export()
            self.completed = self.pending[#self.pending].id
            self.pending, self.inflight = {}, nil
            self.mode = 0
            return finish(core:outputs())
        end

        local function fallback(reason)
            self.fallbacks = self.fallbacks + 1
            self.retry_time = self.clock + 1
            if reason and reason ~= self.last_error then
                self.last_error = reason
                self.report(reason)
            end
            return local_replay()
        end

        local function validate_response(response, job)
            assert(response.version == Packet.VERSION, "electric response version")
            assert(response.first == job.first and response.last == job.last,
                "electric response sample range")
            assert(same_shape(self.state, response.state), "electric response state shape")
            assert(type(response.outputs) == "table", "electric response outputs missing")
            for key, value in pairs(response.outputs) do
                assert(Core.owned[key] and Core.finite(value)
                    and response.state.values[key] == value, "electric response output: " .. tostring(key))
            end
        end

        function self:tick(inputs, enabled)
            for _, definition in ipairs(Core.bindings) do
                assert(Core.finite(inputs[definition.key]), "invalid input: " .. definition.key)
            end
            self.frame = self.frame + 1
            local dt = inputs[Core.dt_key]
            self.clock = self.clock + math.max(0, dt)
            local urgent = false
            for key in pairs(Core.urgent) do
                if inputs[key] ~= self.previous[key] then urgent = true; break end
            end
            if inputs[Core.gpu_command] ~= self.previous[Core.gpu_command] then
                self.gpu_revision = self.gpu_revision + 1
            end
            self.previous = Core.copy(inputs)
            local snapshot = Core.copy(inputs)
            snapshot[Core.gpu_revision_key] = self.gpu_revision
            self.pending[#self.pending + 1] = { id = self.frame, inputs = snapshot }

            -- A switch, failure, ownership transition or pause is handled at
            -- this exact SASL update, without applying an older worker reply.
            if not enabled or urgent or dt <= 0 or inputs[Core.role_key] == 1 then
                return local_replay()
            end
            local ready_ok, ready = pcall(self.transport.ready)
            if not ready_ok or not ready or self.clock < self.retry_time then
                return local_replay()
            end

            local published = {}
            if self.inflight then
                local ok, packet = pcall(self.transport.read)
                if not ok then return fallback("Electric mailbox read failed: " .. tostring(packet)) end
                if packet ~= self.last_response and packet ~= "" and packet ~= Packet.empty() then
                    self.last_response = packet
                    local decoded, response = pcall(Packet.unpack, packet)
                    if not decoded then return fallback("Invalid electric response: " .. tostring(response)) end
                    if response.session == self.session and response.id == self.inflight.id then
                        local valid, reason = pcall(validate_response, response, self.inflight)
                        if not valid then return fallback(tostring(reason)) end
                        local count = self.inflight.last - self.inflight.first + 1
                        self.state, published = response.state, response.outputs
                        self.completed = self.inflight.last
                        self.last_batch_steps = count
                        for _ = 1, count do table.remove(self.pending, 1) end
                        self.inflight = nil
                        self.batches = self.batches + 1
                        self.last_error = nil
                        self.mode = 2
                    end
                    -- Replies to cancelled jobs or previous sessions have no
                    -- authority over the current model or public DataRefs.
                end
            end

            local waiting_time = 0
            for _, sample in ipairs(self.pending) do
                waiting_time = waiting_time + math.max(0, sample.inputs[Core.dt_key])
            end
            if #self.pending >= Packet.MAX_FRAMES or waiting_time > 0.25 then
                -- A delayed worker is an expected scheduling condition. Retain the
                -- fallback counter and replay every sample without an error log.
                local outputs = fallback()
                for key, value in pairs(outputs) do published[key] = value end
                return finish(published)
            end

            if not self.inflight and #self.pending > 0 then
                self.request = self.request + 1
                local job = {
                    version = Packet.VERSION, session = self.session, id = self.request,
                    first = self.pending[1].id, last = self.pending[#self.pending].id,
                    state = self.state, frames = self.pending,
                }
                local ok, packet = pcall(Packet.pack, job)
                if not ok then
                    local outputs = fallback("Electric request could not be packed: " .. tostring(packet))
                    for key, value in pairs(outputs) do published[key] = value end
                    return finish(published)
                end
                local sent, reason = pcall(self.transport.write, packet)
                if not sent then
                    local outputs = fallback("Electric mailbox write failed: " .. tostring(reason))
                    for key, value in pairs(outputs) do published[key] = value end
                    return finish(published)
                end
                self.inflight = { id = job.id, first = job.first, last = job.last }
                if self.mode ~= 2 then self.mode = 1 end
            end
            return finish(published)
        end
        return self
    end
    return Controller
end
