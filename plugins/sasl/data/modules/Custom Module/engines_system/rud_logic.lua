-- rud_logic.lua

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Engine 1 throttle input synchronized through SmartCopilot
    { "tro_comm_1", "tu154/custom/SC/engine/ENGN_thro_0", globalPropertyf },
    -- Engine 2 throttle input synchronized through SmartCopilot
    { "tro_comm_2", "tu154/custom/SC/engine/ENGN_thro_1", globalPropertyf },
    -- Engine 3 throttle input synchronized through SmartCopilot
    { "tro_comm_3", "tu154/custom/SC/engine/ENGN_thro_2", globalPropertyf },
    -- Engine 1 effective throttle position
    { "sim_rud_1", "sim/flightmodel/engine/ENGN_thro_use[0]", globalProperty },
    -- Engine 2 effective throttle position
    { "sim_rud_2", "sim/flightmodel/engine/ENGN_thro_use[1]", globalProperty },
    -- Engine 3 effective throttle position
    { "sim_rud_3", "sim/flightmodel/engine/ENGN_thro_use[2]", globalProperty },
    -- Left engine thrust-reverser deployment ratio
    { "revers_flap_L", "sim/flightmodel2/engines/thrust_reverser_deploy_ratio[0]", globalProperty },
    -- Right engine thrust-reverser deployment ratio
    { "revers_flap_R", "sim/flightmodel2/engines/thrust_reverser_deploy_ratio[2]", globalProperty },
    -- Left engine propeller mode used for reverser control
    { "eng_modL", "sim/flightmodel/engine/ENGN_propmode[0]", globalProperty },
    -- Right engine propeller mode used for reverser control
   { "eng_modR", "sim/flightmodel/engine/ENGN_propmode[2]", globalProperty },
    -- Engine 1 cockpit throttle animation
    { "anim_rud1", "tu154/custom/controlls/throttle_1", globalPropertyf },
    -- Engine 2 cockpit throttle animation
    { "anim_rud2", "tu154/custom/controlls/throttle_2", globalPropertyf },
    -- Engine 3 cockpit throttle animation
    { "anim_rud3", "tu154/custom/controlls/throttle_3", globalPropertyf },
    -- Engine 1 internal throttle animation
    { "anim_rud1_ENG", "tu154/custom/controlls/throttle_1_ENG", globalPropertyf },
    -- Engine 2 internal throttle animation
    { "anim_rud2_ENG", "tu154/custom/controlls/throttle_2_ENG", globalPropertyf },
    -- Engine 3 internal throttle animation
    { "anim_rud3_ENG", "tu154/custom/controlls/throttle_3_ENG", globalPropertyf },
    -- Left reverser-lever animation
    { "revers_L", "tu154/custom/controlls/revers_L", globalPropertyf },
    -- Right reverser-lever animation
    { "revers_R", "tu154/custom/controlls/revers_R", globalPropertyf },
    -- Throttle-lock position
    { "throttle_lock", "tu154/custom/controlls/throttle_lock", globalPropertyf },
    -- Aircraft elevation above mean sea level
    { "msl_alt", "sim/flightmodel/position/elevation", globalPropertyf },
    -- Sea-level barometric pressure
    { "baro_press", "sim/weather/barometer_sealevel_inhg", globalPropertyf },
    -- Outside air temperature
    { "outside_air_temp", "sim/cockpit2/temperature/outside_air_temp_degc", globalPropertyf },
    -- Engine 1 ABSU throttle movement command
    { "rud_1_spd", "tu154/custom/absu/rud_1_spd", globalPropertyf },
    -- Engine 2 ABSU throttle movement command
    { "rud_2_spd", "tu154/custom/absu/rud_2_spd", globalPropertyf },
    -- Engine 3 ABSU throttle movement command
    { "rud_3_spd", "tu154/custom/absu/rud_3_spd", globalPropertyf },
    -- Engine 1 throttle-control failure
    { "comsta0", "sim/operation/failures/rel_comsta0", globalPropertyi },
    -- Engine 2 throttle-control failure
    { "comsta1", "sim/operation/failures/rel_comsta1", globalPropertyi },
    -- Engine 3 throttle-control failure
    { "comsta2", "sim/operation/failures/rel_comsta2", globalPropertyi },
    -- Local reverser failure
    { "rev_fail", "sim/operation/failures/rel_revloc1", globalPropertyi },
    -- Reverser system failure
    { "rev_fail_2", "sim/operation/failures/rel_revers1", globalPropertyi },
    -- Project frame duration
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
    -- X-Plane throttle override
    { "override", "sim/operation/override/override_throttles", globalPropertyi },
    -- Maximum aircraft throttle setting
    { "acf_tmax", "sim/aircraft/engine/acf_tmax", globalPropertyf },
    -- Combined X-Plane throttle ratio
    { "throttle_ratio_all", "sim/cockpit2/engine/actuators/throttle_ratio_all", globalPropertyf },
})

-- Smart Copilot
-- Master. 0 = plugin not found, 1 = slave 2 = master
defineProperty("ismaster", globalPropertyf("scp/api/ismaster"))
-- Have control. 0 = plugin not found, 1 = no control 2 = has control
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1"))

-- local function clamp(x, lo, hi)
    -- if x ~= x then return lo end
    -- if x < lo then return lo end
    -- if x > hi then return hi end
    -- return x
-- end

-- local function safeClamp(value, min_val, max_val, default)
    -- if type(value) ~= "number" or value ~= value then
        -- return default or 0
    -- end

    -- return clamp(value, min_val, max_val)
-- end

-- local function fastInterpolate(table, x)
    -- if #table < 2 then return 0 end
    -- local low, high = 1, #table
    -- while low < high do
        -- local mid = math.floor((low + high) / 2)
        -- if table[mid][1] <= x then
            -- low = mid + 1
        -- else
            -- high = mid
        -- end
    -- end
    -- local i = math.max(1, low - 1)
    -- if i >= #table then return table[#table][2] end
    -- if i < 1 then return table[1][2] end
    -- local x1, y1 = table[i][1], table[i][2]
    -- local x2, y2 = table[i + 1][1], table[i + 1][2]
    -- if x2 == x1 then return y1 end
    -- return y1 + (y2 - y1) * (x - x1) / (x2 - x1)
-- end

set(override, 1) 

set(sim_rud_1, 0.25)
set(sim_rud_2, 0.25)
set(sim_rud_3, 0.25)

local forward_table = {{ -10000, 0.00 }, 
                  {  0.0, 0.02 },	
				  {  0.5, 0.38 },	
				  {  0.6, 0.55}, 
				  {  0.65, 0.637 }, 
                  {  0.7, 0.805}, 
           	      {  0.8, 0.886 }, 
				  {  1.0, 0.975 },	
				  {  1.1, 1.0 },	
				  {  1.2, 1.2 },	
          	      {  100000, 1.3 }} 
local reverse_table = {{ -10000, 0.04 }, 
                  {  0.0, 0.18 },	
				  {  0.5, 0.18 },	
				  {  0.6, 0.8}, 
           	      {  1.0, 0.8 }, 
          	      {  100000, 0.8 }} 
local rud_T_tbl = {{ -10000, 10 }, 
                  {  -60, 10 },	
				   {  0, 1}, 
				  {  40, 0.4}, 
				  {  60, 0.3}, 
          	      {  100000, 0.1 }} 
				  
local thro_1_pos = 0
local thro_2_pos = 0
local thro_3_pos = 0
local thro_1_pos_ENG = 0
local thro_3_pos_ENG = 0
local rev_L_pos = 0
local rev_R_pos = 0
local initial_throttle_1 = safeClamp(get(tro_comm_1), 0, 1, 0)
local initial_throttle_2 = safeClamp(get(tro_comm_2), 0, 1, 0)
local initial_throttle_3 = safeClamp(get(tro_comm_3), 0, 1, 0)

local joy_pos_last_1 = initial_throttle_1
local joy_pos_last_2 = initial_throttle_2
local joy_pos_last_3 = initial_throttle_3
local virtual_rud_1 = 0.02
local virtual_rud_2 = 0.02
local virtual_rud_3 = 0.02
local virtual_rud_1_act = 0.02
local virtual_rud_2_act = 0.02
local virtual_rud_3_act = 0.02
local joy_rud_pos_1 = initial_throttle_1
local joy_rud_pos_2 = initial_throttle_2
local joy_rud_pos_3 = initial_throttle_3

-- Keep small hardware-axis noise from moving the virtual throttle levers.
local THROTTLE_DEADZONE = 0.02

-- Keep all three throttle axes linked while their total spread remains small.
-- Hysteresis prevents repeated linking and unlinking near the 20% threshold.
local THROTTLE_UNLINK_THRESHOLD = 0.25
local THROTTLE_RELINK_THRESHOLD = 0.15

local throttle_input_state = {
    linked = true,

    filtered_1 = initial_throttle_1,
    filtered_2 = initial_throttle_2,
    filtered_3 = initial_throttle_3,

    linked_position = 0,
}

throttle_input_state.linked_position =
    (
        throttle_input_state.filtered_1
        + throttle_input_state.filtered_2
        + throttle_input_state.filtered_3
    ) / 3

local function apply_throttle_deadzone(raw_value, previous_value)
    local value =
        safeClamp(
            raw_value,
            0,
            1,
            previous_value
        )

    if math.abs(value - previous_value) >= THROTTLE_DEADZONE then
        return value
    end

    return previous_value
end

local function process_throttle_inputs(raw_1, raw_2, raw_3)
    throttle_input_state.filtered_1 =
        apply_throttle_deadzone(
            raw_1,
            throttle_input_state.filtered_1
        )

    throttle_input_state.filtered_2 =
        apply_throttle_deadzone(
            raw_2,
            throttle_input_state.filtered_2
        )

    throttle_input_state.filtered_3 =
        apply_throttle_deadzone(
            raw_3,
            throttle_input_state.filtered_3
        )

    local highest =
        math.max(
            throttle_input_state.filtered_1,
            throttle_input_state.filtered_2,
            throttle_input_state.filtered_3
        )

    local lowest =
        math.min(
            throttle_input_state.filtered_1,
            throttle_input_state.filtered_2,
            throttle_input_state.filtered_3
        )

    local spread = highest - lowest

    if throttle_input_state.linked then
        if spread > THROTTLE_UNLINK_THRESHOLD then
            throttle_input_state.linked = false
        end
    elseif spread < THROTTLE_RELINK_THRESHOLD then
        throttle_input_state.linked = true
    end

    if throttle_input_state.linked then
        local average =
            (
                throttle_input_state.filtered_1
                + throttle_input_state.filtered_2
                + throttle_input_state.filtered_3
            ) / 3

        -- Apply the same deadzone to the common linked position.
        throttle_input_state.linked_position =
            apply_throttle_deadzone(
                average,
                throttle_input_state.linked_position
            )

        return
            throttle_input_state.linked_position,
            throttle_input_state.linked_position,
            throttle_input_state.linked_position
    end

    -- Keep the linked position synchronized for a smooth future relink.
    throttle_input_state.linked_position =
        (
            throttle_input_state.filtered_1
            + throttle_input_state.filtered_2
            + throttle_input_state.filtered_3
        ) / 3

    return
        throttle_input_state.filtered_1,
        throttle_input_state.filtered_2,
        throttle_input_state.filtered_3
end

rev_comm = sasl.findCommand("sim/engines/thrust_reverse_toggle")
function rev_comm_hnd(phase)
	if 0 == phase then 
		set(throttle_ratio_all, 0)
	end
	return 0
end
sasl.registerCommandHandler(rev_comm, 0, rev_comm_hnd)
function update()
	local passed = get(frame_time)
	local stop_lever = get(throttle_lock) 
	local rev_L = get(eng_modL) == 3
	local rev_R = get(eng_modR) == 3
	local T_coef = fastInterpolate(rud_T_tbl, get(outside_air_temp))
	local T_coef_1 = T_coef
	if rev_L then T_coef_1 = T_coef_1 / 1.5 end
	local T_coef_3 = T_coef
	if rev_R then T_coef_3 = T_coef_3 / 1.5 end
	local joy_rud_MAX_1 = 1
	local joy_rud_MIN_1 = 0.175 
	local joy_rud_MAX_2 = 1
	local joy_rud_MIN_2 = 0.175
	local joy_rud_MAX_3 = 1
	local joy_rud_MIN_3 = 0.175
	local alt = get(msl_alt) * 3.28083 
	local alt_baro = alt * 0.3048 + (29.92 - get(baro_press)) * 1000 * 0.3048 
	local height_coef = line(alt_baro, 0, 1, 11000, 0.975) 
	local stall_1 = get(comsta0) == 6
	if stall_1 then 
		joy_rud_MAX_1 = 0.05 
		joy_rud_MIN_1 = 0
	end
	local stall_2 = get(comsta1) == 6
	if stall_2 then 
		joy_rud_MAX_2 = 0.05 
		joy_rud_MIN_2 = 0
	end
	local stall_3 = get(comsta2) == 6
	if stall_3 then 
		joy_rud_MAX_3 = 0.05 
		joy_rud_MIN_3 = 0 
	end	
	local rud_spd_1 = get(rud_1_spd)
	local rud_spd_2 = get(rud_2_spd)
	local rud_spd_3 = get(rud_3_spd)
	local joy_pos_1, joy_pos_2, joy_pos_3 =
		process_throttle_inputs(
			get(tro_comm_1),
			get(tro_comm_2),
			get(tro_comm_3)
		)
	if rud_spd_1 ~= 0 then
		joy_rud_pos_1 = joy_rud_pos_1 + rud_spd_1 * passed
	elseif math.abs(joy_pos_1 - joy_pos_last_1) > 0.001 then
		joy_rud_pos_1 = joy_pos_1
	end
	if rud_spd_2 ~= 0 then
		joy_rud_pos_2 = joy_rud_pos_2 + rud_spd_2 * passed
	elseif math.abs(joy_pos_2 - joy_pos_last_2) > 0.001 then
		joy_rud_pos_2 = joy_pos_2
	end
	if rud_spd_3 ~= 0 then
		joy_rud_pos_3 = joy_rud_pos_3 + rud_spd_3 * passed
	elseif math.abs(joy_pos_3 - joy_pos_last_3) > 0.001 then
		joy_rud_pos_3 = joy_pos_3
	end
	if math.abs(joy_pos_last_1 - joy_pos_1) > 0.001 then joy_pos_last_1 = joy_pos_1 end
	if math.abs(joy_pos_last_2 - joy_pos_2) > 0.001 then joy_pos_last_2 = joy_pos_2 end
	if math.abs(joy_pos_last_3 - joy_pos_3) > 0.001 then joy_pos_last_3 = joy_pos_3 end
	if joy_rud_pos_1 > 1 then joy_rud_pos_1 = 1
	elseif joy_rud_pos_1 < 0 then joy_rud_pos_1 = 0 end
	if joy_rud_pos_2 > 1 then joy_rud_pos_2 = 1
	elseif joy_rud_pos_2 < 0 then joy_rud_pos_2 = 0 end
	if joy_rud_pos_3 > 1 then joy_rud_pos_3 = 1
	elseif joy_rud_pos_3 < 0 then joy_rud_pos_3 = 0 end
	if stop_lever < 0.2 then
		if rev_L then
			thro_1_pos = 0
			thro_1_pos_ENG = -fastInterpolate(reverse_table, joy_rud_pos_1) * 0.4
			rev_L_pos = -thro_1_pos_ENG * 2.5
			virtual_rud_1 = joy_rud_MIN_1 + (joy_rud_MAX_1 - joy_rud_MIN_1) * fastInterpolate(reverse_table, joy_rud_pos_1)
		else
			thro_1_pos = joy_rud_pos_1
			thro_1_pos_ENG = joy_rud_pos_1
			rev_L_pos = 0
			virtual_rud_1 = joy_rud_MIN_1 + (joy_rud_MAX_1 - joy_rud_MIN_1) * fastInterpolate(forward_table, joy_rud_pos_1)
		end
		if rev_L or rev_R then 
			thro_2_pos = 0
			virtual_rud_2 = joy_rud_MIN_2 + (joy_rud_MAX_2 - joy_rud_MIN_2) * fastInterpolate(forward_table, joy_rud_MIN_2)
		else
			thro_2_pos = joy_rud_pos_2
			virtual_rud_2 = joy_rud_MIN_2 + (joy_rud_MAX_2 - joy_rud_MIN_2) * fastInterpolate(forward_table, joy_rud_pos_2)
		end
		if rev_R then
			thro_3_pos = 0
			thro_3_pos_ENG = -fastInterpolate(reverse_table, joy_rud_pos_3) * 0.4
			rev_R_pos = -thro_3_pos_ENG * 2.5
			virtual_rud_3 = joy_rud_MIN_3 + (joy_rud_MAX_3 - joy_rud_MIN_3) * fastInterpolate(reverse_table, joy_rud_pos_3)
		else
			thro_3_pos = joy_rud_pos_3
			thro_3_pos_ENG = joy_rud_pos_3
			rev_R_pos = 0
			virtual_rud_3 = joy_rud_MIN_3 + (joy_rud_MAX_3 - joy_rud_MIN_3) * fastInterpolate(forward_table, joy_rud_pos_3)
		end
	end
	if virtual_rud_1_act < virtual_rud_1 then 
		virtual_rud_1_act = virtual_rud_1_act - (virtual_rud_1_act - virtual_rud_1) * passed * T_coef_1
	else 
		virtual_rud_1_act = virtual_rud_1_act - (virtual_rud_1_act - virtual_rud_1) * passed
	end
	if virtual_rud_2_act < virtual_rud_2 then 
		virtual_rud_2_act = virtual_rud_2_act - (virtual_rud_2_act - virtual_rud_2) * passed * T_coef
	else 
		virtual_rud_2_act = virtual_rud_2_act - (virtual_rud_2_act - virtual_rud_2) * passed
	end
	if virtual_rud_3_act < virtual_rud_3 then 
		virtual_rud_3_act = virtual_rud_3_act - (virtual_rud_3_act - virtual_rud_3) * passed * T_coef_3
	else 
		virtual_rud_3_act = virtual_rud_3_act - (virtual_rud_3_act - virtual_rud_3) * passed
	end
	local thro_high_1 = line(virtual_rud_1_act, 0, 0.525, 1, 1.07)
	local thro_high_2 = line(virtual_rud_2_act, 0, 0.525, 1, 1.07)
	local thro_high_3 = line(virtual_rud_3_act, 0, 0.525, 1, 1.07)
	local thro_1 = line(alt_baro, 0, virtual_rud_1_act, 11000, thro_high_1)
	local thro_2 = line(alt_baro, 0, virtual_rud_2_act, 11000, thro_high_2)
	local thro_3 = line(alt_baro, 0, virtual_rud_3_act, 11000, thro_high_3)
local MASTER = get(ismaster) ~= 1	
if MASTER then	
	set(anim_rud1, thro_1_pos)
	set(anim_rud2, thro_2_pos)
	set(anim_rud3, thro_3_pos)
	set(anim_rud1_ENG, thro_1_pos_ENG)
	set(anim_rud2_ENG, thro_2_pos)
	set(anim_rud3_ENG, thro_3_pos_ENG)
	set(throttle_lock, stop_lever)
	set(revers_L, rev_L_pos)
	set(revers_R, rev_R_pos)
	set(sim_rud_1, thro_1)
	set(sim_rud_2, thro_2)
	set(sim_rud_3, thro_3)
end
	set(rev_fail, 6) 
	set(rev_fail_2, 6)
	set(acf_tmax, 108288 * height_coef)
end

function onModuleDone()
	set(override, 0)
	print("throttles released")
end