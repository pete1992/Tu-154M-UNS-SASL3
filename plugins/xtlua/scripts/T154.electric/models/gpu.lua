--[[
Changelog
2026-10-04
- Extract the GPU electrical model from SASL sound rendering.
- Preserve start, stop, connection, ejection and overload behavior with restorable state.
]]

-- Pure GPU electrical model. SASL retains sound playback and camera attenuation.
-- The thresholds and update order match the original SASL implementation.
local bindings = {
    { "gpu_present", "tu154/custom/anim/gpu_present", "integer" },
    { "gpu_work_anim", "tu154/custom/anim/gpu_work", "float" },
    { "gpu_volt", "tu154/custom/elec/gpu_volt", "float" },
    { "gpu_amp", "tu154/custom/elec/gpu_amp", "float" },
    { "gpu_overload", "tu154/custom/elec/gpu_overload", "integer" },
    { "gpu_on", "tu154/custom/switchers/eng/gpu_on", "integer" },
    { "gpu_work_bus", "tu154/custom/elec/gpu_work", "integer" },
    { "DC_27_volt1", "tu154/custom/elec/bus27_volt_left", "float" },
    { "DC_27_volt2", "tu154/custom/elec/bus27_volt_right", "float" },
    { "GS", "sim/flightmodel/position/groundspeed", "float" },
    { "frame_time", "tu154/custom/time/frame_time", "float" },
    { "ismaster", "scp/api/ismaster", "float" },
}

local GPU_START_RATE = 0.25       -- 4 seconds from stopped to running
local GPU_STOP_RATE = 0.10        -- 10 seconds from running to stopped
local GPU_CONNECT_DELAY = 1.0
local GPU_EJECT_DELAY = 1.0
local GPU_EJECT_GS = 0.1
local GPU_OUTPUT_VOLTAGE = 115
local GPU_CONTROL_VOLTAGE = 13
local GPU_OVERLOAD_LIMIT = 900

local function create(io, saved)
    saved = saved or {}
    local STATE = {
        work_timer = saved.work_timer or 0,
        connect_timer = saved.connect_timer or 0,
        eject_timer = saved.eject_timer or 0,
    }

    local function updateElectricalState(dt)
        local present = io.get("gpu_present")
        local ground_speed = math.abs(io.get("GS"))

        if ground_speed > GPU_EJECT_GS then
            STATE.eject_timer = STATE.eject_timer + dt
        else
            STATE.eject_timer = 0
        end

        if STATE.eject_timer >= GPU_EJECT_DELAY then
            STATE.work_timer = 0
            STATE.connect_timer = 0

            io.set("gpu_work_anim", 0)
            io.set("gpu_present", 0)
            io.set("gpu_volt", 0)
            io.set("gpu_overload", 0)
            io.set("gpu_work_bus", 0)

            return
        end

        -- GPU spool-up / spool-down.
        if present == 1 then
            STATE.work_timer = STATE.work_timer + dt * GPU_START_RATE
        else
            STATE.work_timer = STATE.work_timer - dt * GPU_STOP_RATE
            io.set("gpu_overload", 0)
        end

        if STATE.work_timer >= 1 then
            STATE.work_timer = 1

            local dc_available =
                io.get("DC_27_volt1") > GPU_CONTROL_VOLTAGE
                or io.get("DC_27_volt2") > GPU_CONTROL_VOLTAGE

            if dc_available and io.get("gpu_overload") ~= 1 then
                io.set("gpu_volt", GPU_OUTPUT_VOLTAGE)
            else
                io.set("gpu_volt", 0)
            end
        elseif STATE.work_timer <= 0 then
            STATE.work_timer = 0
            io.set("gpu_volt", 0)
        elseif STATE.work_timer < 0.9 then
            -- Preserve the existing spool-down voltage behavior.
            io.set("gpu_volt", 0)
        end

        io.set("gpu_work_anim", STATE.work_timer)

        -- GPU bus connection.
        local gpu_switch = io.get("gpu_on")

        if gpu_switch == 1 then
            STATE.connect_timer = STATE.connect_timer + dt

            if STATE.connect_timer >= GPU_CONNECT_DELAY then
                STATE.connect_timer = GPU_CONNECT_DELAY

                if STATE.work_timer == 1 and io.get("gpu_overload") ~= 1 then
                    io.set("gpu_work_bus", 1)
                else
                    io.set("gpu_work_bus", 0)
                end
            else
                io.set("gpu_work_bus", 0)
            end
        else
            STATE.connect_timer = 0
            io.set("gpu_work_bus", 0)
        end

        -- GPU overload latch.
        if io.get("gpu_amp") > GPU_OVERLOAD_LIMIT then
            io.set("gpu_overload", 1)
        elseif gpu_switch == 0 then
            io.set("gpu_overload", 0)
        end
    end

    local function update()
        local dt = io.get("frame_time")
        if dt <= 0 then
            return
        end
        if io.get("ismaster") ~= 1 then
            updateElectricalState(dt)
        end
    end

    local function export()
        return {
            work_timer = STATE.work_timer,
            connect_timer = STATE.connect_timer,
            eject_timer = STATE.eject_timer,
        }
    end

    return { update = update, export = export }
end

return { bindings = bindings, outputs = { "gpu_work_anim", "gpu_present", "gpu_volt", "gpu_overload", "gpu_work_bus" }, create = create }
