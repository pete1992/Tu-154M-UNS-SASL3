-- absu_indicator.lua
-- ABSU control-position indicators.

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
    -- Control inputs and nosewheel strut deflection
    { "absu_contr_pitch", "tu154/custom/absu/contr_pitch", globalPropertyf },
    { "absu_contr_roll", "tu154/custom/absu/contr_roll", globalPropertyf },
    { "absu_contr_yaw", "tu154/custom/absu/contr_yaw", globalPropertyf },
    { "int_pitch_trim", "tu154/custom/trimmers/int_pitch_trim", globalPropertyf },
    -- SASL array indices are 1-based: element 1 is native gear[0].
    { "gear1_deflect", "sim/flightmodel2/gear/tire_vertical_deflection_mtr", globalPropertyfae, 1 },

    -- Indicator outputs
    { "rudder_pos_ind", "tu154/custom/gauges/misc/rudder_pos_ind", globalPropertyf },
    { "aileron_pos_ind", "tu154/custom/gauges/misc/aileron_pos_ind", globalPropertyf },
    { "elevator_pos_ind", "tu154/custom/gauges/misc/elevator_pos_ind", globalPropertyf },
})

function update()
	set(rudder_pos_ind, get(absu_contr_yaw) / 0.4)
	set(aileron_pos_ind, get(absu_contr_roll) / 0.4)
	set(elevator_pos_ind, get(absu_contr_pitch) / 0.4)
	if get(gear1_deflect) > 0.01 and get(int_pitch_trim) < -0.5 then set(elevator_pos_ind, -get(absu_contr_pitch) / 0.4) end
end
