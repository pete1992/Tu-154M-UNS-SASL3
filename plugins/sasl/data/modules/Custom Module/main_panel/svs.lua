-- svs.lua
-- SVS air data system logic.

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
    -- Simulator air data
    { "mach_sim", "sim/flightmodel/misc/machno", globalPropertyf },
    { "msl_alt", "sim/flightmodel/position/elevation", globalPropertyf }, -- Meters MSL
    { "msl_press", "sim/weather/barometer_sealevel_inhg", globalPropertyf }, -- Sea-level pressure in inHg
    -- { "airspeed", "sim/flightmodel/position/indicated_airspeed", globalPropertyf }, -- Unused: TAS uses true_airspeed directly.
    { "true_airspeed", "sim/flightmodel/position/true_airspeed", globalPropertyf }, -- Meters per second

    -- Controls
    { "svs_contr", "tu154/custom/buttons/ovhd/svs_contr", globalPropertyi },
    { "svs_on", "tu154/custom/switchers/ovhd/svs_on", globalPropertyi },
    { "svs_heat", "tu154/custom/switchers/ovhd/svs_heat", globalPropertyi },

    -- Failures
    { "rel_pitot", "sim/operation/failures/rel_pitot", globalPropertyi },
    { "rel_pitot2", "sim/operation/failures/rel_pitot2", globalPropertyi },
    { "static_fail_L", "sim/operation/failures/rel_static", globalPropertyi },
    { "static_fail_R", "sim/operation/failures/rel_static2", globalPropertyi },
    { "svs_fail", "sim/operation/failures/rel_adc_comp", globalPropertyi },

    -- Indications
    { "mach_svs", "tu154/custom/svs/machno", globalPropertyf },
    { "alt_svs", "tu154/custom/svs/altitude", globalPropertyf }, -- Altitude at standard pressure
    { "tas_svs", "tu154/custom/svs/true_airspeed", globalPropertyf },

    -- Electrical power and current consumption
    { "bus27_volt", "tu154/custom/elec/bus27_volt_left", globalPropertyf },
    { "bus36_volt", "tu154/custom/elec/bus36_volt_left", globalPropertyf },
    { "bus115_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "svs27_cc", "tu154/custom/svs/power_27cc", globalPropertyf },
    { "svs36_cc", "tu154/custom/svs/power_36cc", globalPropertyf },
    { "svs115_cc", "tu154/custom/svs/power_115cc", globalPropertyf },
    -- { "sensors_caps", "tu154/custom/anim/sensors_caps", globalPropertyi }, -- Unused: the old caps check is commented out.

    -- SmartCopilot authority
    { "ismaster", "scp/api/ismaster", globalPropertyf }, -- 0 = absent, 1 = slave, 2 = master
    -- { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf }, -- Unused: output authority uses ismaster only.
})

--[[

local alt_kus_tbl = {{ -50000000, 0.5},    -- bugs workaround
				  { 0, 1 },    -- on standard pressure zero level
          		  {  2000, 1.0288 },
				  {  4000, 1.0571 },
				  {  6000, 1.0879 },
				  {  8000, 1.1205 },
				  {  10000, 1.1549 },
				  {  12000, 1.1901 },
				  {  14000, 1.2223 },
				  {  16000, 1.2558 },  
          		  {  18000, 1.2924 },   
          		  {  20000, 1.3341 },
				  {  22000, 1.3708 },
				  {  24000, 1.4154 },
				  {  26000, 1.4558 },
				  {  28000, 1.5005 },
				  {  30000, 1.5500 },
				  {  32000, 1.6039 },
				  {  34000, 1.6597 },
				  {  36000, 1.7164 },
				  {  38000, 1.7920 },
				  {  40000, 1.8762 },
				  {  42000, 1.9653 },
          		  {  10000000, 10 }}   -- linear above
				  
--]]

local mach = 0
local tas = 0
local altitude = 0

function update()
	
	-- power
	local power = get(svs_on) == 1 and get(bus27_volt) > 13 and get(bus36_volt) > 30 and get(bus115_volt) > 110 and get(svs_fail) == 0
	
	local test = power and get(svs_contr) == 1
	
	local heat = power and get(svs_heat) == 1
	
	--local blocked = get(sensors_caps) == 1
	
	-- current consumption
	local cc_27 = bool2int(power) * 10 + bool2int(test) * 4 + bool2int(heat) * 17
	local cc_other = bool2int(power)
	
	set(svs27_cc, cc_27)
	set(svs36_cc, cc_other * 1.5)
	set(svs115_cc, cc_other * 3.5)
	
	-- mach number
	local pitot_fail = (get(rel_pitot) == 6 and get(rel_pitot2) == 6)
	if not pitot_fail and power then mach = get(mach_sim) end
	
	if test then mach = 0.8 end -- svs control check

	-- altitude
	local alt_QNE = get(msl_alt) * 3.28083 + (29.92 - get(msl_press)) * 1000  -- calculate altitude in feet above standart pressure
	local static_fail = (get(static_fail_L) == 6 and get(static_fail_R) == 6)
	
	if power and not static_fail then altitude = alt_QNE * 0.3048 end
	
	if test then altitude = 12000 end
	
	-- TAS
	-- local alt_tas_coef = interpolate(alt_kus_tbl, alt_QNE)	
	
	if power and not pitot_fail then tas = get(true_airspeed) * 3.6 end --get(airspeed) * alt_tas_coef * 1.852 end
	
	if tas < 180 then tas = 0 end
		
	if test then tas = 900 end

local MASTER = get(ismaster) ~= 1	
	
if MASTER then	
	
	-- results
	set(mach_svs, mach)
	set(alt_svs, altitude)	
	set(tas_svs, tas)

end

end

