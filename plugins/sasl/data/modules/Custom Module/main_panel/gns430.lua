-- gns430.lua
-- this is GNS supplement logicS
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
    -- Unused in this component (no child components consume these bindings).
    -- { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },

    -- { "show_gns", "tu154/custom/anim/show_gns", globalPropertyi },
    { "show_RXP", "tu154/custom/anim/RXP", globalPropertyi },
    { "overrideGPS", "sim/operation/override/override_gps", globalPropertyi },

-- source
    -- Keep the existing overhead-switch path: it now powers GNS/UNS, not KLN.
    { "gps_on", "tu154/custom/switchers/ovhd/kln_on", globalPropertyi },
-- The GNS and both UNS panels share the native GPS1 receiver.
    { "uns1_on", "tu154/custom/uns1_on", globalPropertyf },
    { "uns2_on", "tu154/custom/uns2_on", globalPropertyf },

    { "bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf }, --   27
    { "bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf }, --   27

    { "gps_course_degtm", "sim/cockpit/radios/gps_course_degtm", globalPropertyf }, -- DTK magnetic
    { "gps_hdef_dot", "sim/cockpit/radios/gps_hdef_dot", globalPropertyf }, -- Course dev in dots
    { "gps_fromto", "sim/cockpit/radios/gps_fromto", globalPropertyi },

-- results
    { "gps_power", "sim/cockpit2/radios/actuators/gps_power", globalPropertyi }, -- GPS power
    { "gns_lit", "tu154/custom/lights/gns430_lit", globalPropertyf }, -- GPS power

    { "GNS430_dtk", "tu154/custom/SC/GNS430_dtk", globalPropertyf }, --
    { "GNS430_dev", "tu154/custom/SC/GNS430_dev", globalPropertyf }, --
    { "GNS430_flag", "tu154/custom/SC/GNS430_flag", globalPropertyi }, --

-- animation
    { "LB_angle", "tu154/custom/rotary/GNS430/LB_angle", globalPropertyf }, -- LB_angle
    { "LS_angle", "tu154/custom/rotary/GNS430/LS_angle", globalPropertyf }, -- LS_angle
    { "RB_angle", "tu154/custom/rotary/GNS430/RB_angle", globalPropertyf }, -- RB_angle
    { "RS_angle", "tu154/custom/rotary/GNS430/RS_angle", globalPropertyf }, -- RS_angle

    { "kill_map_fms_line", "sim/graphics/misc/kill_map_fms_line", globalPropertyi }, --

-- Smart Copilot
    { "ismaster", "scp/api/ismaster", globalPropertyf }, -- Master. 0 = plugin not found, 1 = slave 2 = master
    -- Unused: this component only distinguishes the SmartCopilot master/slave.
    -- { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf },
})

local LB_left = sasl.findCommand("sim/GPS/g430n1_coarse_down")

function LB_left_hnd(phase)
	if 1 == phase then
		set(LB_angle, get(LB_angle) - 10)
	end
	return 0
end

sasl.registerCommandHandler(LB_left, 0, LB_left_hnd)

local LB_right = sasl.findCommand("sim/GPS/g430n1_coarse_up")

function LB_right_hnd(phase)
	if 1 == phase then
		set(LB_angle, get(LB_angle) + 10)
	end
	return 0
end

sasl.registerCommandHandler(LB_right, 0, LB_right_hnd)

local LS_left = sasl.findCommand("sim/GPS/g430n1_fine_down")

function LS_left_hnd(phase)
	if 1 == phase then
		set(LS_angle, get(LS_angle) - 10)
	end
	return 0
end

sasl.registerCommandHandler(LS_left, 0, LS_left_hnd)

local LS_right = sasl.findCommand("sim/GPS/g430n1_fine_up")

function LS_right_hnd(phase)
	if 1 == phase then
		set(LS_angle, get(LS_angle) + 10)
	end
	return 0
end

sasl.registerCommandHandler(LS_right, 0, LS_right_hnd)

local RB_left = sasl.findCommand("sim/GPS/g430n1_chapter_dn")

function RB_left_hnd(phase)
	if 1 == phase then
		set(RB_angle, get(RB_angle) - 10)
	end
	return 0
end

sasl.registerCommandHandler(RB_left, 0, RB_left_hnd)

local RB_right = sasl.findCommand("sim/GPS/g430n1_chapter_up")

function RB_right_hnd(phase)
	if 1 == phase then
		set(RB_angle, get(RB_angle) + 10)
	end
	return 0
end

sasl.registerCommandHandler(RB_right, 0, RB_right_hnd)

local RS_left = sasl.findCommand("sim/GPS/g430n1_page_dn")

function RS_left_hnd(phase)
	if 1 == phase then
		set(RS_angle, get(RS_angle) - 10)
	end
	return 0
end

sasl.registerCommandHandler(RS_left, 0, RS_left_hnd)

local RS_right = sasl.findCommand("sim/GPS/g430n1_page_up")

function RS_right_hnd(phase)
	if 1 == phase then
		set(RS_angle, get(RS_angle) + 10)
	end
	return 0
end

sasl.registerCommandHandler(RS_right, 0, RS_right_hnd)

--[[
sim/GPS/g430n1_popup			Popup 2D panel

sim/GPS/g430n1_coarse_down		LB left
sim/GPS/g430n1_coarse_up		LB right
sim/GPS/g430n1_fine_down 		LS left
sim/GPS/g430n1_fine_up			LS right
sim/GPS/g430n1_nav_com_tog		LS push

sim/GPS/g430n1_chapter_dn		RB left
sim/GPS/g430n1_chapter_up		RB right
sim/GPS/g430n1_page_dn			RS left
sim/GPS/g430n1_page_up			RS right
sim/GPS/g430n1_cursor			RS push

sim/GPS/g430n1_com_ff			Com up-dn
sim/GPS/g430n1_nav_ff			Nav up-dn

sim/GPS/g430n1_cdi				CDI button
sim/GPS/g430n1_obs				OBS button
sim/GPS/g430n1_msg				MSG button
sim/GPS/g430n1_fpl				FPL button
sim/GPS/g430n1_proc				PROC button

sim/GPS/g430n1_zoom_out			RNG down
sim/GPS/g430n1_zoom_in			RNG up

sim/GPS/g430n1_direct			Dir button
sim/GPS/g430n1_menu				MENU button
sim/GPS/g430n1_clr				CLR button
sim/GPS/g430n1_ent				ENT button

--]]

local native_gps_last = false

function update()

	-- Own GPS1 power here so the GNS and UNS updates cannot switch it against each other.
	local left_power = get(bus27_volt_left) > 13
	local right_power = get(bus27_volt_right) > 13
	local gps_requested = (get(gps_on) > 0 and (left_power or right_power))
		or (get(uns1_on) > 0 and left_power)
		or (get(uns2_on) > 0 and right_power)
	set(gps_power, bool2int(gps_requested))
	set(gns_lit, get(gps_power) * 0.7)
	
	local native_gps_selected = get(show_RXP) == 0
	if native_gps_selected and not native_gps_last then
		-- Release a former provider's override on native fallback, but do not
		-- overwrite GPS ownership while the optional RXP provider is selected.
		set(overrideGPS, 0)
	end
	native_gps_last = native_gps_selected
	
	--print(get(gps_hdef_dot))
	if get(ismaster) ~= 1 then
		set(GNS430_dtk, get(gps_course_degtm))
		set(GNS430_dev, get(gps_hdef_dot))
		set(GNS430_flag, bool2int(get(gps_fromto) == 0 or get(gps_power) == 0))
		if get(GNS430_flag) == 1 then set(GNS430_dev, 0) end
	end
	
	-- Kontur owns route visibility for NAV versus WX/TCAS/TAWS modes.

end

function onModuleDone()
	
	set(gps_power, 1)
	set(kill_map_fms_line, 0)
	print("GPS reset")

end
