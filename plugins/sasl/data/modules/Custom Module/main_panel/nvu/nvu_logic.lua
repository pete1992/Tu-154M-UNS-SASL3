-- nvu_logic.lua
-- Compatibility outputs still required outside the retired NVU system.
-- FMS panels enter the flight plan; ABSU flies it through the existing GPS bridge.
-- No coordinate calculation, NVU-set selection or extra source routing belongs here.

local function defineProps(defs)
    for _, def in ipairs(defs) do
        local prop
        if def[4] ~= nil then
            prop = def[3](def[2], def[4])
        else
            prop = def[3](def[2])
        end
        defineProperty(def[1], prop)
    end
end

defineProps({
    { "gps_power", "sim/cockpit2/radios/actuators/gps_power", globalPropertyi },
    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf },
    { "nvu_on_lit", "tu154/custom/lights/small/nvu_on", globalPropertyf },
    { "nvu_cc", "tu154/custom/nvu/nvu_cc", globalPropertyf },
})

function update()
    -- The before-taxi checklist still reads this legacy "navigation on" signal.
    -- Report GPS power, not route validity: a powered GPS need not have a leg yet.
    local brightness = math.max((math.max(get(bus27_volt_left), get(bus27_volt_right)) - 10) / 18.5, 0)
    set(nvu_on_lit, get(gps_power) > 0 and brightness or 0)

    -- current_counter still includes this load. The removed NVU draws no current.
    set(nvu_cc, 0)
end
