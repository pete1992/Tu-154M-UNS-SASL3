-- current_counter.lua
--[[
Changelog
- Grouped all 77 Dataref bindings through defineProps().
- Preserved all original property names, constructors, and binding order.
- Corrected km5_2_cc to read tu154/custom/tks/km5_2_cc instead of the duplicated km5_1_cc path.
- Corrected the 115 V bus 1 load formula from nav1_pow_cc * rsbn_cc * 5 to nav1_pow_cc + rsbn_cc * 5.
- Added early SmartCopilot slave return so only the owning instance writes electrical bus currents.
- Cached repeatedly used load Datarefs once per frame.
- Kept all existing load multipliers unchanged.
- Kept APU starter current out of the normal 27 V bus totals because bus27_logic.lua handles starter load separately.
- Explicitly writes both emergency 115 V bus currents to 0 because this module has no separately modeled emergency-bus consumers.
- Does not clamp bus currents so rectifier/generator overload logic receives the real calculated demand.
- Replaced Russian comments with English comments while preserving legacy property identifiers.
]]

-- Electrical load counter for the Tu-154M.
-- Aggregates subsystem current demand onto the 27 V, 36 V, and 115 V buses.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- Bus current outputs
    { "bus27_amp_left", "tu154/custom/elec/bus27_amp_left", globalPropertyf },
    { "bus27_amp_right", "tu154/custom/elec/bus27_amp_right", globalPropertyf },
    { "bus36_amp_left", "tu154/custom/elec/bus36_amp_left", globalPropertyf },
    { "bus36_amp_right", "tu154/custom/elec/bus36_amp_right", globalPropertyf },
    { "bus36_amp_pts250_1", "tu154/custom/elec/bus36_amp_pts250_1", globalPropertyf },
    { "bus36_amp_pts250_2", "tu154/custom/elec/bus36_amp_pts250_2", globalPropertyf },
    { "bus115_1_amp", "tu154/custom/elec/bus115_1_amp", globalPropertyf },
    { "bus115_2_amp", "tu154/custom/elec/bus115_2_amp", globalPropertyf },
    { "bus115_3_amp", "tu154/custom/elec/bus115_3_amp", globalPropertyf },
    { "bus115_em_1_amp", "tu154/custom/elec/bus115_em_1_amp", globalPropertyf },
    { "bus115_em_2_amp", "tu154/custom/elec/bus115_em_2_amp", globalPropertyf },
    -- 27 V loads
    { "bat_amp_cc_1", "tu154/custom/elec/bat_cc_1", globalPropertyf },
    { "bat_amp_cc_2", "tu154/custom/elec/bat_cc_2", globalPropertyf },
    { "bat_amp_cc_3", "tu154/custom/elec/bat_cc_3", globalPropertyf },
    { "bat_amp_cc_4", "tu154/custom/elec/bat_cc_4", globalPropertyf },
    { "cockpit_light_cc_left", "tu154/custom/elec/cockpit_light_cc_left", globalPropertyf },
    { "cockpit_light_cc_right", "tu154/custom/elec/cockpit_light_cc_right", globalPropertyf },
    { "ext_light_cc_left", "tu154/custom/elec/ext_light_cc_left", globalPropertyf },
    { "ext_light_cc_right", "tu154/custom/elec/ext_light_cc_right", globalPropertyf },
    { "apu_start_cc", "tu154/custom/elec/apu_start_cc", globalPropertyf },
    { "fuel_pumps_27_cc", "tu154/custom/elec/fuel_pumps_27_cc", globalPropertyf },
    { "ai_27_L_cc", "tu154/custom/antiice/ai_27_L_cc", globalPropertyf },
    { "ai_27_R_cc", "tu154/custom/antiice/ai_27_R_cc", globalPropertyf },
    { "ctr_27_L_cc", "tu154/custom/control/ctr_27_L_cc", globalPropertyf },
    { "ctr_27_R_cc", "tu154/custom/control/ctr_27_R_cc", globalPropertyf },
    { "msrp_27_L_cc", "tu154/custom/msrp/msrp_27_L_cc", globalPropertyf },
    { "msrp_27_R_cc", "tu154/custom/msrp/msrp_27_R_cc", globalPropertyf },
    { "svs27_cc", "tu154/custom/svs/power_27cc", globalPropertyf },
    { "auasp_pow27_cc", "tu154/custom/elec/auasp_pow27_cc", globalPropertyf },
    { "rv__1", "tu154/custom/elec/rv5_left_cc", globalPropertyf },
    { "rv__2", "tu154/custom/elec/rv5_right_cc", globalPropertyf },
    { "taws_cc", "tu154/custom/taws/taws_cc", globalPropertyf },
    { "fire_sys_cc", "tu154/custom/fire/fire_sys_cc", globalPropertyf },
    { "vhf1_cc", "tu154/custom/radio/vhf1_cc", globalPropertyf },
    { "vhf2_cc", "tu154/custom/radio/vhf2_cc", globalPropertyf },
    { "km5_1_cc", "tu154/custom/tks/km5_1_cc", globalPropertyf },
    { "km5_2_cc", "tu154/custom/tks/km5_2_cc", globalPropertyf },
    { "ga_1_cc", "tu154/custom/tks/ga_1_cc", globalPropertyf },
    { "ga_2_cc", "tu154/custom/tks/ga_2_cc", globalPropertyf },
    { "ga_heat_cc", "tu154/custom/tks/ga_heat_cc", globalPropertyf },
    { "bgmk_1_cc", "tu154/custom/tks/bgmk_1_cc", globalPropertyf },
    { "bgmk_2_cc", "tu154/custom/tks/bgmk_2_cc", globalPropertyf },
    { "ush_cc", "tu154/custom/tks/ush_cc", globalPropertyf },
    { "agr_cc", "tu154/custom/ahz/agr_cc", globalPropertyf },
    { "ark15_L_cc", "tu154/custom/radio/ark15_L_cc", globalPropertyf },
    { "ark15_R_cc", "tu154/custom/radio/ark15_R_cc", globalPropertyf },
    -- 36 V loads
    { "diss_cc", "tu154/custom/nvu/diss_cc", globalPropertyf },
    { "radar_cc", "tu154/custom/radio/radar_cc", globalPropertyf },
    { "rsbn_cc", "tu154/custom/radio/rsbn_cc", globalPropertyf },
    { "ctr_36L_cc", "tu154/custom/control/ctr_36L_cc", globalPropertyf },
    { "ctr_36R_cc", "tu154/custom/control/ctr_36R_cc", globalPropertyf },
    { "svs36_cc", "tu154/custom/svs/power_36cc", globalPropertyf },
    { "absu_power_cc", "tu154/custom/absu_power_cc", globalPropertyf },
    { "pkp_left_power_cc", "tu154/custom/bkk/pkp_left_power_cc", globalPropertyf },
    { "pkp_right_power_cc", "tu154/custom/bkk/pkp_right_power_cc", globalPropertyf },
    { "mgv_ctr_power_cc", "tu154/custom/bkk/mgv_ctr_power_cc", globalPropertyf },
    { "absu_at_power_cc", "tu154/custom/absu_at_power_cc", globalPropertyf },
    -- 115 V loads
    { "nvu_cc", "tu154/custom/nvu/nvu_cc", globalPropertyf },
    { "nav1_pow_cc", "tu154/custom/radio/nav1_pow_cc", globalPropertyf },
    { "nav2_pow_cc", "tu154/custom/radio/nav2_pow_cc", globalPropertyf },
    { "vu1_amp", "tu154/custom/elec/vu1_amp", globalPropertyf },
    { "vu2_amp", "tu154/custom/elec/vu2_amp", globalPropertyf },
    { "vu3_amp", "tu154/custom/elec/vu_res_amp", globalPropertyf },
    { "cockpit_light_cc_115", "tu154/custom/elec/cockpit_light_cc_115", globalPropertyf },
    { "fuel_pumps_115_1_cc", "tu154/custom/elec/fuel_pumps_115_1_cc", globalPropertyf },
    { "fuel_pumps_115_3_cc", "tu154/custom/elec/fuel_pumps_115_3_cc", globalPropertyf },
    { "gs_pump_2_cc", "tu154/custom/hydro/gs_pump_2_cc", globalPropertyf },
    { "gs_pump_3_cc", "tu154/custom/hydro/gs_pump_3_cc", globalPropertyf },
    { "ai_115_1_cc", "tu154/custom/antiice/ai_115_1_cc", globalPropertyf },
    { "ai_115_2_cc", "tu154/custom/antiice/ai_115_2_cc", globalPropertyf },
    { "ai_115_3_cc", "tu154/custom/antiice/ai_115_3_cc", globalPropertyf },
    { "ctr_115_1_cc", "tu154/custom/control/ctr_115_1_cc", globalPropertyf },
    { "ctr_115_3_cc", "tu154/custom/control/ctr_115_3_cc", globalPropertyf },
    { "svs115_cc", "tu154/custom/svs/power_115cc", globalPropertyf },
    -- SmartCopilot
    { "auasp_pow115_cc", "tu154/custom/elec/auasp_pow115_cc", globalPropertyf },
    { "ismaster", "scp/api/ismaster", globalPropertyf },
    { "hascontrol_1", "scp/api/hascontrol_1", globalPropertyf },
})

function update()
    -- SmartCopilot slave receives synchronized current values.
    if get(ismaster) == 1 then
        return
    end

    --------------------------------------------------------------------------
    -- Cache repeatedly used loads
    --------------------------------------------------------------------------
    local bat_cc_1 = get(bat_amp_cc_1)
    local bat_cc_2 = get(bat_amp_cc_2)
    local bat_cc_3 = get(bat_amp_cc_3)
    local bat_cc_4 = get(bat_amp_cc_4)

    local fuel27 = get(fuel_pumps_27_cc)

    local km5_1 = get(km5_1_cc)
    local km5_2 = get(km5_2_cc)

    local ga_1 = get(ga_1_cc)
    local ga_2 = get(ga_2_cc)
    local bgmk_1 = get(bgmk_1_cc)
    local bgmk_2 = get(bgmk_2_cc)

    local agr = get(agr_cc)
    local ark15_L = get(ark15_L_cc)
    local ark15_R = get(ark15_R_cc)

    local nvu = get(nvu_cc)
    local diss = get(diss_cc)
    local radar = get(radar_cc)
    local rsbn = get(rsbn_cc)

    local absu_power = get(absu_power_cc)
    local absu_at_power = get(absu_at_power_cc)

    local nav1 = get(nav1_pow_cc)
    local nav2 = get(nav2_pow_cc)

    local rv1 = get(rv__1)
    local rv2 = get(rv__2)

    local vu1 = get(vu1_amp)
    local vu2 = get(vu2_amp)
    local vu3 = get(vu3_amp)

    local cockpit115 = get(cockpit_light_cc_115)
    local svs115 = get(svs115_cc)

    --------------------------------------------------------------------------
    -- 27 V buses
    --------------------------------------------------------------------------
    local bus27_L =
        bat_cc_1
        + bat_cc_3
        + get(cockpit_light_cc_left)
        + get(ext_light_cc_left)
        + fuel27 * 0.5
        + get(ai_27_L_cc)
        + get(ctr_27_L_cc)
        + get(msrp_27_L_cc)

    bus27_L =
        bus27_L
        + get(svs27_cc)
        + rv1
        + get(taws_cc)
        + get(vhf1_cc)
        + km5_1 * 2
        + ga_1 * 0.5
        + ga_2 * 0.5
        + get(ga_heat_cc)
        + bgmk_1
        + agr

    bus27_L =
        bus27_L
        + nvu * 10
        + ark15_L
        + diss
        + rsbn * 5

    local bus27_R =
        bat_cc_2
        + bat_cc_4
        + get(cockpit_light_cc_right)
        + get(ext_light_cc_right)
        + fuel27 * 0.5
        + get(ai_27_R_cc)
        + get(ctr_27_R_cc)
        + get(msrp_27_R_cc)

    bus27_R =
        bus27_R
        + get(auasp_pow27_cc)
        + rv2
        + get(fire_sys_cc)
        + get(vhf2_cc)
        + km5_2 * 2
        + bgmk_2
        + get(ush_cc)
        + ark15_R
        + radar * 3

    set(bus27_amp_left, bus27_L)
    set(bus27_amp_right, bus27_R)

    --------------------------------------------------------------------------
    -- 36 V buses
    --------------------------------------------------------------------------
    local bus36_L =
        get(ctr_36L_cc)
        + get(svs36_cc)
        + absu_power * 3
        + get(pkp_left_power_cc)
        + absu_at_power
        + nvu * 7
        + ark15_L
        + diss

    local bus36_R =
        get(ctr_36R_cc)
        + absu_power * 3
        + get(pkp_right_power_cc)
        + km5_2 * 3
        + ga_2 * 2
        + bgmk_2
        + ark15_R
        + nav2

    local bus36_pts_1 =
        absu_power * 3
        + get(mgv_ctr_power_cc)
        + agr
        + radar

    local bus36_pts_2 =
        km5_1 * 3
        + ga_1 * 2
        + bgmk_1
        + nav1

    set(bus36_amp_left, bus36_L)
    set(bus36_amp_right, bus36_R)
    set(bus36_amp_pts250_1, bus36_pts_1)
    set(bus36_amp_pts250_2, bus36_pts_2)

    --------------------------------------------------------------------------
    -- 115 V buses
    --------------------------------------------------------------------------
    local bus115_1 =
        vu1 * 0.25
        + vu3 * 0.125
        + cockpit115 * 0.5
        + get(fuel_pumps_115_1_cc)
        + get(gs_pump_2_cc)
        + get(ai_115_1_cc)
        + get(ctr_115_1_cc)

    bus115_1 =
        bus115_1
        + svs115
        + rv1
        + get(taws_cc) * 0.2
        + absu_at_power
        + nvu
        + diss * 3
        + nav1
        + rsbn * 5

    local bus115_2 =
        get(ai_115_2_cc)

    local bus115_3 =
        vu2 * 0.25
        + vu3 * 0.125
        + cockpit115 * 0.5
        + get(fuel_pumps_115_3_cc)
        + get(gs_pump_3_cc)
        + get(ai_115_3_cc)
        + get(ctr_115_3_cc)

    bus115_3 =
        bus115_3
        + get(auasp_pow115_cc)
        + rv2
        + absu_power
        + nav2
        + radar * 3

    set(bus115_1_amp, bus115_1)
    set(bus115_2_amp, bus115_2)
    set(bus115_3_amp, bus115_3)

    -- No dedicated emergency-bus consumers are modeled in this module.
    set(bus115_em_1_amp, 0)
    set(bus115_em_2_amp, 0)
end
