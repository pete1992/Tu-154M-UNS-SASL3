-- Shared systems time step. Use simulator timing even while parked; aircraft
-- pitch moment is not a clock and must not freeze engine/APU startup logic.
local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    { "sim_frame_period", "sim/operation/misc/frame_rate_period", globalPropertyf },
    { "sim_paused", "sim/time/paused", globalPropertyi },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
})

function update()
    local passed = get(sim_frame_period)
    if get(sim_paused) ~= 0 or passed ~= passed or passed < 0 or passed == math.huge then
        passed = 0
    end
    -- Preserve the existing systems integration limit during long frame stalls.
    set(frame_time, math.min(passed, 0.1))
end
