-- Shared systems time step. Use simulator timing even while parked; aircraft
-- pitch moment is not a clock and must not freeze engine/APU startup logic.
defineProperty("sim_frame_period", globalPropertyf("sim/operation/misc/frame_rate_period"))
defineProperty("sim_paused", globalPropertyi("sim/time/paused"))
defineProperty("frame_time", globalPropertyf("tu154/custom/time/frame_time"))

function update()
    local passed = get(sim_frame_period)
    if get(sim_paused) ~= 0 or passed ~= passed or passed < 0 or passed == math.huge then
        passed = 0
    end
    -- Preserve the existing systems integration limit during long frame stalls.
    set(frame_time, math.min(passed, 0.1))
end
