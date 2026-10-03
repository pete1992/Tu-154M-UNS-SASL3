--[[
Changelog
2026-10-04
- Port consumer-current aggregation to the ordered numeric worker model.
- Use binding keys without exceeding LuaJIT closure upvalue limits.
]]

-- currents.lua
-- Electrical consumer current aggregation.
-- Numeric I/O is provided by the caller; this module has no simulator API access.

local bindings = {
    { "bus27_amp_left", "tu154/custom/elec/bus27_amp_left", "float" },
    { "bus27_amp_right", "tu154/custom/elec/bus27_amp_right", "float" },
    { "bus36_amp_left", "tu154/custom/elec/bus36_amp_left", "float" },
    { "bus36_amp_right", "tu154/custom/elec/bus36_amp_right", "float" },
    { "bus36_amp_pts250_1", "tu154/custom/elec/bus36_amp_pts250_1", "float" },
    { "bus36_amp_pts250_2", "tu154/custom/elec/bus36_amp_pts250_2", "float" },
    { "bus115_1_amp", "tu154/custom/elec/bus115_1_amp", "float" },
    { "bus115_2_amp", "tu154/custom/elec/bus115_2_amp", "float" },
    { "bus115_3_amp", "tu154/custom/elec/bus115_3_amp", "float" },
    { "bus115_em_1_amp", "tu154/custom/elec/bus115_em_1_amp", "float" },
    { "bus115_em_2_amp", "tu154/custom/elec/bus115_em_2_amp", "float" },
    { "bat_amp_cc_1", "tu154/custom/elec/bat_cc_1", "float" },
    { "bat_amp_cc_2", "tu154/custom/elec/bat_cc_2", "float" },
    { "bat_amp_cc_3", "tu154/custom/elec/bat_cc_3", "float" },
    { "bat_amp_cc_4", "tu154/custom/elec/bat_cc_4", "float" },
    { "cockpit_light_cc_left", "tu154/custom/elec/cockpit_light_cc_left", "float" },
    { "cockpit_light_cc_right", "tu154/custom/elec/cockpit_light_cc_right", "float" },
    { "ext_light_cc_left", "tu154/custom/elec/ext_light_cc_left", "float" },
    { "ext_light_cc_right", "tu154/custom/elec/ext_light_cc_right", "float" },
    { "fuel_pumps_27_cc", "tu154/custom/elec/fuel_pumps_27_cc", "float" },
    { "ai_27_L_cc", "tu154/custom/antiice/ai_27_L_cc", "float" },
    { "ai_27_R_cc", "tu154/custom/antiice/ai_27_R_cc", "float" },
    { "ctr_27_L_cc", "tu154/custom/control/ctr_27_L_cc", "float" },
    { "ctr_27_R_cc", "tu154/custom/control/ctr_27_R_cc", "float" },
    { "msrp_27_L_cc", "tu154/custom/msrp/msrp_27_L_cc", "float" },
    { "msrp_27_R_cc", "tu154/custom/msrp/msrp_27_R_cc", "float" },
    { "svs27_cc", "tu154/custom/svs/power_27cc", "float" },
    { "auasp_pow27_cc", "tu154/custom/elec/auasp_pow27_cc", "float" },
    { "rv__1", "tu154/custom/elec/rv5_left_cc", "float" },
    { "rv__2", "tu154/custom/elec/rv5_right_cc", "float" },
    { "taws_cc", "tu154/custom/taws/taws_cc", "float" },
    { "fire_sys_cc", "tu154/custom/fire/fire_sys_cc", "float" },
    { "vhf1_cc", "tu154/custom/radio/vhf1_cc", "float" },
    { "vhf2_cc", "tu154/custom/radio/vhf2_cc", "float" },
    { "km5_1_cc", "tu154/custom/tks/km5_1_cc", "float" },
    { "km5_2_cc", "tu154/custom/tks/km5_2_cc", "float" },
    { "ga_1_cc", "tu154/custom/tks/ga_1_cc", "float" },
    { "ga_2_cc", "tu154/custom/tks/ga_2_cc", "float" },
    { "ga_heat_cc", "tu154/custom/tks/ga_heat_cc", "float" },
    { "bgmk_1_cc", "tu154/custom/tks/bgmk_1_cc", "float" },
    { "bgmk_2_cc", "tu154/custom/tks/bgmk_2_cc", "float" },
    { "ush_cc", "tu154/custom/tks/ush_cc", "float" },
    { "agr_cc", "tu154/custom/ahz/agr_cc", "float" },
    { "ark15_L_cc", "tu154/custom/radio/ark15_L_cc", "float" },
    { "ark15_R_cc", "tu154/custom/radio/ark15_R_cc", "float" },
    { "diss_cc", "tu154/custom/nvu/diss_cc", "float" },
    { "radar_cc", "tu154/custom/radio/radar_cc", "float" },
    { "rsbn_cc", "tu154/custom/radio/rsbn_cc", "float" },
    { "ctr_36L_cc", "tu154/custom/control/ctr_36L_cc", "float" },
    { "ctr_36R_cc", "tu154/custom/control/ctr_36R_cc", "float" },
    { "svs36_cc", "tu154/custom/svs/power_36cc", "float" },
    { "absu_power_cc", "tu154/custom/absu_power_cc", "float" },
    { "pkp_left_power_cc", "tu154/custom/bkk/pkp_left_power_cc", "float" },
    { "pkp_right_power_cc", "tu154/custom/bkk/pkp_right_power_cc", "float" },
    { "mgv_ctr_power_cc", "tu154/custom/bkk/mgv_ctr_power_cc", "float" },
    { "absu_at_power_cc", "tu154/custom/absu_at_power_cc", "float" },
    { "nvu_cc", "tu154/custom/nvu/nvu_cc", "float" },
    { "nav1_pow_cc", "tu154/custom/radio/nav1_pow_cc", "float" },
    { "nav2_pow_cc", "tu154/custom/radio/nav2_pow_cc", "float" },
    { "vu1_amp", "tu154/custom/elec/vu1_amp", "float" },
    { "vu2_amp", "tu154/custom/elec/vu2_amp", "float" },
    { "vu3_amp", "tu154/custom/elec/vu_res_amp", "float" },
    { "cockpit_light_cc_115", "tu154/custom/elec/cockpit_light_cc_115", "float" },
    { "fuel_pumps_115_1_cc", "tu154/custom/elec/fuel_pumps_115_1_cc", "float" },
    { "fuel_pumps_115_3_cc", "tu154/custom/elec/fuel_pumps_115_3_cc", "float" },
    { "gs_pump_2_cc", "tu154/custom/hydro/gs_pump_2_cc", "float" },
    { "gs_pump_3_cc", "tu154/custom/hydro/gs_pump_3_cc", "float" },
    { "ai_115_1_cc", "tu154/custom/antiice/ai_115_1_cc", "float" },
    { "ai_115_2_cc", "tu154/custom/antiice/ai_115_2_cc", "float" },
    { "ai_115_3_cc", "tu154/custom/antiice/ai_115_3_cc", "float" },
    { "ctr_115_1_cc", "tu154/custom/control/ctr_115_1_cc", "float" },
    { "ctr_115_3_cc", "tu154/custom/control/ctr_115_3_cc", "float" },
    { "svs115_cc", "tu154/custom/svs/power_115cc", "float" },
    { "auasp_pow115_cc", "tu154/custom/elec/auasp_pow115_cc", "float" },
    { "ismaster", "scp/api/ismaster", "float" },
}

local outputs = {
    "bus27_amp_left",
    "bus27_amp_right",
    "bus36_amp_left",
    "bus36_amp_right",
    "bus36_amp_pts250_1",
    "bus36_amp_pts250_2",
    "bus115_1_amp",
    "bus115_2_amp",
    "bus115_3_amp",
    "bus115_em_1_amp",
    "bus115_em_2_amp",
}

local function create(io, saved)
    local get = io.get
    local set = io.set

    -- Literal aliases keep this large consumer list below LuaJIT's upvalue limit.
    local function update()
        -- SmartCopilot slave receives synchronized current values.
        if get("ismaster") == 1 then
            return
        end

        --------------------------------------------------------------------------
        -- Cache repeatedly used loads
        --------------------------------------------------------------------------
        local bat_cc_1 = get("bat_amp_cc_1")
        local bat_cc_2 = get("bat_amp_cc_2")
        local bat_cc_3 = get("bat_amp_cc_3")
        local bat_cc_4 = get("bat_amp_cc_4")

        local fuel27 = get("fuel_pumps_27_cc")

        local km5_1 = get("km5_1_cc")
        local km5_2 = get("km5_2_cc")

        local ga_1 = get("ga_1_cc")
        local ga_2 = get("ga_2_cc")
        local bgmk_1 = get("bgmk_1_cc")
        local bgmk_2 = get("bgmk_2_cc")

        local agr = get("agr_cc")
        local ark15_L = get("ark15_L_cc")
        local ark15_R = get("ark15_R_cc")

        local nvu = get("nvu_cc")
        local diss = get("diss_cc")
        local radar = get("radar_cc")
        local rsbn = get("rsbn_cc")

        local absu_power = get("absu_power_cc")
        local absu_at_power = get("absu_at_power_cc")

        local nav1 = get("nav1_pow_cc")
        local nav2 = get("nav2_pow_cc")

        local rv1 = get("rv__1")
        local rv2 = get("rv__2")

        local vu1 = get("vu1_amp")
        local vu2 = get("vu2_amp")
        local vu3 = get("vu3_amp")

        local cockpit115 = get("cockpit_light_cc_115")
        local svs115 = get("svs115_cc")

        --------------------------------------------------------------------------
        -- 27 V buses
        --------------------------------------------------------------------------
        local bus27_L =
            bat_cc_1
            + bat_cc_3
            + get("cockpit_light_cc_left")
            + get("ext_light_cc_left")
            + fuel27 * 0.5
            + get("ai_27_L_cc")
            + get("ctr_27_L_cc")
            + get("msrp_27_L_cc")

        bus27_L =
            bus27_L
            + get("svs27_cc")
            + rv1
            + get("taws_cc")
            + get("vhf1_cc")
            + km5_1 * 2
            + ga_1 * 0.5
            + ga_2 * 0.5
            + get("ga_heat_cc")
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
            + get("cockpit_light_cc_right")
            + get("ext_light_cc_right")
            + fuel27 * 0.5
            + get("ai_27_R_cc")
            + get("ctr_27_R_cc")
            + get("msrp_27_R_cc")

        bus27_R =
            bus27_R
            + get("auasp_pow27_cc")
            + rv2
            + get("fire_sys_cc")
            + get("vhf2_cc")
            + km5_2 * 2
            + bgmk_2
            + get("ush_cc")
            + ark15_R
            + radar * 3

        set("bus27_amp_left", bus27_L)
        set("bus27_amp_right", bus27_R)

        --------------------------------------------------------------------------
        -- 36 V buses
        --------------------------------------------------------------------------
        local bus36_L =
            get("ctr_36L_cc")
            + get("svs36_cc")
            + absu_power * 3
            + get("pkp_left_power_cc")
            + absu_at_power
            + nvu * 7
            + ark15_L
            + diss

        local bus36_R =
            get("ctr_36R_cc")
            + absu_power * 3
            + get("pkp_right_power_cc")
            + km5_2 * 3
            + ga_2 * 2
            + bgmk_2
            + ark15_R
            + nav2

        local bus36_pts_1 =
            absu_power * 3
            + get("mgv_ctr_power_cc")
            + agr
            + radar

        local bus36_pts_2 =
            km5_1 * 3
            + ga_1 * 2
            + bgmk_1
            + nav1

        set("bus36_amp_left", bus36_L)
        set("bus36_amp_right", bus36_R)
        set("bus36_amp_pts250_1", bus36_pts_1)
        set("bus36_amp_pts250_2", bus36_pts_2)

        --------------------------------------------------------------------------
        -- 115 V buses
        --------------------------------------------------------------------------
        local bus115_1 =
            vu1 * 0.25
            + vu3 * 0.125
            + cockpit115 * 0.5
            + get("fuel_pumps_115_1_cc")
            + get("gs_pump_2_cc")
            + get("ai_115_1_cc")
            + get("ctr_115_1_cc")

        bus115_1 =
            bus115_1
            + svs115
            + rv1
            + get("taws_cc") * 0.2
            + absu_at_power
            + nvu
            + diss * 3
            + nav1
            + rsbn * 5

        local bus115_2 =
            get("ai_115_2_cc")

        local bus115_3 =
            vu2 * 0.25
            + vu3 * 0.125
            + cockpit115 * 0.5
            + get("fuel_pumps_115_3_cc")
            + get("gs_pump_3_cc")
            + get("ai_115_3_cc")
            + get("ctr_115_3_cc")

        bus115_3 =
            bus115_3
            + get("auasp_pow115_cc")
            + rv2
            + absu_power
            + nav2
            + radar * 3

        set("bus115_1_amp", bus115_1)
        set("bus115_2_amp", bus115_2)
        set("bus115_3_amp", bus115_3)

        -- No dedicated emergency-bus consumers are modeled in this module.
        set("bus115_em_1_amp", 0)
        set("bus115_em_2_amp", 0)
    end

    return {
        update = update,
        export = function()
            return {}
        end,
    }
end

return { bindings = bindings, outputs = outputs, create = create }
