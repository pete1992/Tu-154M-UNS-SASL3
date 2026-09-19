-- hydro_logic_old_old.lua
-- this is hydraulic logic

-- controls
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
    { "accum_fill", "tu154/custom/buttons/hydro/accum_fill", globalPropertyi }, --

    { "connect2to1", "tu154/custom/switchers/hydro/connect2to1", globalPropertyi }, --  2   1
    { "pump_2", "tu154/custom/switchers/hydro/pump_2", globalPropertyi }, --  2   1
    { "pump_3", "tu154/custom/switchers/hydro/pump_3", globalPropertyi }, --  2   1

    -- sources
    { "rpm_high_1", "tu154/custom/gauges/engine/rpm_high_1", globalPropertyf }, --     №1
    { "rpm_high_2", "tu154/custom/gauges/engine/rpm_high_2", globalPropertyf }, --     №2
    { "rpm_high_3", "tu154/custom/gauges/engine/rpm_high_3", globalPropertyf }, --     №3

    { "bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf },
    { "bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf },

    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf }, --   27
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf }, --   27

    -- results
    { "gs_press_1", "tu154/custom/hydro/gs_press_1", globalPropertyf }, --   1
    { "gs_press_2", "tu154/custom/hydro/gs_press_2", globalPropertyf }, --   2
    { "gs_press_3", "tu154/custom/hydro/gs_press_3", globalPropertyf }, --   3
    { "gs_press_4", "tu154/custom/hydro/gs_press_4", globalPropertyf }, --   4

    { "gs_qty_1", "tu154/custom/hydro/gs_qty_1", globalPropertyf }, --
    { "gs_qty_2", "tu154/custom/hydro/gs_qty_2", globalPropertyf }, --
    { "gs_qty_3", "tu154/custom/hydro/gs_qty_3", globalPropertyf }, --
    { "gs_qty_12_show", "tu154/custom/hydro/gs_qty_12_show", globalPropertyf }, --
    { "gs_qty_3_show", "tu154/custom/hydro/gs_qty_3_show", globalPropertyf }, --

    -- failures
    { "hs_leak_1", "tu154/custom/failures/hydro_leak_1", globalPropertyi }, -- leak
    { "hs_leak_2", "tu154/custom/failures/hydro_leak_2", globalPropertyi }, -- leak
    { "hs_leak_3", "tu154/custom/failures/hydro_leak_3", globalPropertyi }, -- leak
    { "hs_leak_4", "tu154/custom/failures/hydro_leak_4", globalPropertyi }, -- leak

    { "hydro_pump_fail_11", "tu154/custom/failures/hydro_pump_fail_11", globalPropertyi },
    { "hydro_pump_fail_12", "tu154/custom/failures/hydro_pump_fail_12", globalPropertyi },
    { "hydro_pump_fail_2", "tu154/custom/failures/hydro_pump_fail_2", globalPropertyi },
    { "hydro_pump_fail_3", "tu154/custom/failures/hydro_pump_fail_3", globalPropertyi },

    { "hydro_elec_fail_2", "tu154/custom/failures/hydro_elec_fail_2", globalPropertyi },
    { "hydro_elec_fail_3", "tu154/custom/failures/hydro_elec_fail_3", globalPropertyi },

    -- time
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf }, -- flight time

    -- currents
    { "gs_pump_2_cc", "tu154/custom/hydro/gs_pump_2_cc", globalPropertyf }, --
    { "gs_pump_3_cc", "tu154/custom/hydro/gs_pump_3_cc", globalPropertyf }, --

    -- Smart Copilot
    { "ismaster", "scp/api/ismaster", globalPropertyf }, -- Master. 0 = plugin not found, 1 = slave 2 = master
    -- { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf }, -- Have control. 0 = plugin not found, 1 = no control 2 = has control
})

local engine_pumps_t = { 
{  -10000, 42},
{  0, 42},    
{  140, 40 },    
{  190, 35 },    
{  210, 0 },
{  1000, 0 }}  

local electric_pumps_t = { 
{  -10000, 42},
{  0, 17},    
{  140, 15 },    
{  190, 14 },    
{  210, 0 },
{  1000, 0 }} 

function update()
	local passed = get(frame_time)

local MASTER = get(ismaster) ~= 1	
	
	print("work")

if MASTER then	
	
	-- calculate oil amount
	local hs1_qty = get(gs_qty_1) -- overall quantity of oil
	local hs2_qty = get(gs_qty_2) -- overall quantity of oil
	local hs3_qty = get(gs_qty_3) -- overall quantity of oil

	-- set connection between barrel's parts for HS1 and HS2
	local bak1_1 = hs1_qty - 30
	local bak1_2 = hs2_qty - 30
	local bak3 = hs3_qty - 21
	
	if bak1_1 > 12 or bak1_2 > 12 then
		bak1_1 = bak1_1 + (bak1_2 - bak1_1) * passed * 5
		bak1_2 = bak1_2 + (bak1_1 - bak1_2) * passed * 5
	end
	
	-- check leak
	local leak_1 = get(hs_leak_1) == 1
	local leak_2 = get(hs_leak_2) == 1
	local leak_3 = get(hs_leak_3) == 1
	local leak_4 = get(hs_leak_4) == 1
	
	-- check power
	local power27L = get(bus27_volt_left) > 13
	local power27R = get(bus27_volt_right) > 13
	
	local power115_1 = get(bus115_1_volt) > 110
	local power115_3 = get(bus115_3_volt) > 110
	
	-- calculate pressures
	local press_1 = get(gs_press_1)
	local press_2 = get(gs_press_2)
	local press_3 = get(gs_press_3)
	local press_4 = get(gs_press_4)
	
	-- gain pressure from engine pumps
	local RPM_1 = get(rpm_high_1)
	local RPM_2 = get(rpm_high_2)
	local RPM_3 = get(rpm_high_3)
	local eng_pump_1_1 = math.min (1, RPM_1 * 0.02) * (1 - get(hydro_pump_fail_11))
	local eng_pump_1_2 = math.min (1, RPM_2 * 0.02) * (1 - get(hydro_pump_fail_12))
	local eng_pump_2 = math.min (1, RPM_2 * 0.02) * (1 - get(hydro_pump_fail_2))
	local eng_pump_3 = math.min (1, RPM_3 * 0.02) * (1 - get(hydro_pump_fail_3))
	
	if hs1_qty > 30 then press_1 = press_1 + (eng_pump_1_1 + eng_pump_1_2) * interpolate(engine_pumps_t, press_1) * passed end
	if hs2_qty > 30 then press_2 = press_2 + eng_pump_2 * interpolate(engine_pumps_t, press_2) * passed end
	if hs3_qty > 21 then press_3 = press_3 + eng_pump_3 * interpolate(engine_pumps_t, press_3) * passed end
	
	-- charge the accumulator for emergency brakes
	if get(accum_fill) == 1 and press_4 < press_1 and power27L then
		press_1 = press_1 - math.min(math.abs(press_4 - press_1), 20) * 2 * passed
		press_4 = press_4 + math.min(math.abs(press_1 - press_4), 20) * 2 * passed
		leak_1 = leak_4
	end
	
	-- connect HS 1 and HS2
	if get(connect2to1) == 1 and power27L and press_2 > press_1 then
		press_1 = press_1 + math.min(math.abs(press_2 - press_1), 20) * 2 * passed
		press_2 = press_2 - math.min(math.abs(press_1 - press_2), 20) * 2 * passed
		leak_2 = leak_1
	end
	
	-- gain pressure from electrical pumps
	local elec_pump_2 = bool2int(power115_1 and power27L and get(pump_2) == 1) * (1 - get(hydro_elec_fail_2))
	local elec_pump_3 = bool2int(power115_3 and power27R and get(pump_3) == 1) * (1 - get(hydro_elec_fail_3))
	
	if hs2_qty > 28 then press_2 = press_2 + elec_pump_2 * interpolate(electric_pumps_t, press_2) * passed end
	if hs3_qty > 21 then press_3 = press_3 + elec_pump_3 * interpolate(electric_pumps_t, press_3) * passed end
	
	local pump2_current = elec_pump_2 * (32 + interpolate(electric_pumps_t, press_2) * 0.15)
	local pump3_current = elec_pump_3 * (32 + interpolate(electric_pumps_t, press_3) * 0.15)
	
	-- internal pressure leak
	if press_1 > 0 then press_1 = press_1 - passed * 0.03 * press_1 * 0.005	end
	if press_2 > 0 then press_2 = press_2 - passed * 0.025 * press_2 * 0.005 end
	if press_3 > 0 then press_3 = press_3 - passed * 0.005 * press_3 * 0.005 end
	if press_4 > 0 then press_4 = press_4 - passed * 0.003 * press_4 * 0.005 end
	
	-- external leak
	if leak_1 and press_1 > 0 then press_1 = press_1 - passed * (press_1 + 20) * 0.01 end
	if leak_2 and press_2 > 0 then press_2 = press_2 - passed * (press_2 + 20) * 0.01 end
	if leak_3 and press_3 > 0 then press_3 = press_3 - passed * (press_3 + 20) * 0.01 end
	if leak_4 and press_4 > 0 then press_4 = press_4 - passed * (press_4 + 20) * 0.01 end
	
	-- leak oil from systems
	if leak_1 and bak1_1 > 0 then bak1_1 = bak1_1 - passed * (press_1 + 20) * 0.0005 end
	if leak_2 and bak1_2 > 0 then bak1_2 = bak1_2 - passed * (press_2 + 20) * 0.0005 end
	if leak_3 and bak3 > 0 then bak3 = bak3 - passed * (press_3 + 20) * 0.0005 end
	
	-- limit qty
	if bak1_1 < 0 then bak1_1 = 0 end
	if bak1_2 < 0 then bak1_2 = 0 end
	if bak3 < 0 then bak3 = 0 end
	
	-- oil quantity in barrels
	local oil_qty_12 = bak1_1 * 2 - press_1 * 0.019 - press_2 * 0.019 - press_4 * 0.019
	local oil_qty_3 = bak3 - press_3 * 0.019
	
	--print(get(gs_qty_1))
	
	-- set results
	set(gs_press_1, press_1)
	set(gs_press_2, press_2)
	set(gs_press_3, press_3)
	set(gs_press_4, press_4)
	
	set(gs_pump_2_cc, pump2_current)
	set(gs_pump_3_cc, pump3_current)
	
	set(gs_qty_12_show, oil_qty_12)
	set(gs_qty_3_show, oil_qty_3 + 24)
	
	set(gs_qty_1, bak1_1 + 30)
	set(gs_qty_2, bak1_2 + 30)
	set(gs_qty_3, bak3 + 24)

end
	
end

