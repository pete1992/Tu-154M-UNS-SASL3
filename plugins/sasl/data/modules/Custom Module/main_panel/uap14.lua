-- uap14.lua
-- AOA and G-force indicator logic.

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"ias", "sim/cockpit2/gauges/indicators/airspeed_kts_pilot", globalPropertyf},
    {"mach", "sim/flightmodel/misc/machno", globalPropertyf},
    {"gforce", "sim/flightmodel2/misc/gforce_normal", globalPropertyf},
    {"alpha", "sim/flightmodel2/misc/AoA_angle_degrees", globalPropertyf},
    {"alpha_fail", "sim/operation/failures/rel_AOA", globalPropertyi},
    {"flap_inn_L", "sim/flightmodel/controls/wing1l_fla1def", globalPropertyf},
    {"slats", "sim/flightmodel2/controls/slat1_deploy_ratio", globalPropertyf},
    {"rel_pitot", "sim/operation/failures/rel_pitot", globalPropertyi},
    {"lamp_test", "tu154/custom/buttons/lamp_test_front", globalPropertyi},
    {"auasp_on", "tu154/custom/switchers/ovhd/auasp_on", globalPropertyi},
    {"auasp_contr", "tu154/custom/switchers/ovhd/auasp_contr", globalPropertyi},
    {"gforce_reset", "tu154/custom/buttons/misc/gforce_reset", globalPropertyi},
    {"day_night_set", "tu154/custom/lights/day_night_set", globalPropertyf},
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},
    {"bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf},
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"auasp_pow27_cc", "tu154/custom/elec/auasp_pow27_cc", globalPropertyf},
    {"auasp_pow115_cc", "tu154/custom/elec/auasp_pow115_cc", globalPropertyf},
    {"uap_fail", "sim/operation/failures/rel_AOA", globalPropertyi},
    {"warn_fail", "sim/operation/failures/rel_stall_warn", globalPropertyi},
    {"aoa_ind", "tu154/custom/gauges/misc/aoa_ind", globalPropertyf},
    {"aoa_sector", "tu154/custom/gauges/misc/aoa_sector", globalPropertyf},
    {"gforce_ind", "tu154/custom/gauges/misc/gforce_ind", globalPropertyf},
    {"gforce_max", "tu154/custom/gauges/misc/gforce_max", globalPropertyf},
    {"gforce_min", "tu154/custom/gauges/misc/gforce_min", globalPropertyf},
    {"auasp_lamp", "tu154/custom/lights/auasp_lamp", globalPropertyf},
    {"alpha_high", "tu154/custom/lights/alpha_high", globalPropertyf},
    {"g_force_high", "tu154/custom/lights/g_force_high", globalPropertyf},
    {"alpha_critical", "tu154/custom/auasp/alpha_critical", globalPropertyi},
    {"gforce_critical", "tu154/custom/auasp/gforce_critical", globalPropertyi},
    {"speaker_auasp", "tu154/custom/alarm/speaker_auasp", globalPropertyi},
    {"ismaster", "scp/api/ismaster", globalPropertyf},
})

local sector_ang = 12
local aoa_ang_act = 0
local aoa_ang_need = 0
local lamp_lit = false
local lamp_counter = 0
local mach_act = 0

local gf_act = 0
local gf_max = 0
local gf_min = 0

function update()
    local MASTER = get(ismaster) ~= 1

    local power = bool2int(
        get(bus27_volt_right) > 13
        and get(bus115_3_volt) > 110
        and get(auasp_on) == 1
        and get(uap_fail) < 6
    )

    local passed = get(frame_time)
    local mode_sw = get(auasp_contr)

    set(auasp_pow27_cc, power * 10)
    set(auasp_pow115_cc, power * 3)

    -- Critical AOA sector logic.
    local sector_ang_need = 12
    local flaps = get(flap_inn_L)
    local slat = get(slats)

    if get(rel_pitot) < 6 then
        mach_act = get(mach)
    end

    if mode_sw == 1 then
        sector_ang_need = 10
    elseif slat > 0.9 and flaps < 25 then
        sector_ang_need = 14
    elseif flaps >= 25 then
        sector_ang_need = 12
    else
        if mach_act <= 0.42 then
            sector_ang_need = 12
        else
            sector_ang_need = (0.42 - mach_act) * 6 / 0.48 + 12
        end
    end

    if sector_ang > sector_ang_need + 0.01 then
        sector_ang = sector_ang - passed * power * 0.4
    elseif sector_ang < sector_ang_need - 0.01 then
        sector_ang = sector_ang + passed * power * 0.4
    end

    set(aoa_sector, sector_ang)

    -- AOA indicator.
    if mode_sw == 1 and get(alpha_fail) < 6 then
        aoa_ang_need = 10
    elseif mode_sw == -1 then
        aoa_ang_need = 0
    elseif get(ias) > 50 and get(alpha_fail) < 6 then
        aoa_ang_need = get(alpha) + 3
    end

    aoa_ang_act = aoa_ang_act + (aoa_ang_need - aoa_ang_act) * passed * power * 3

    if aoa_ang_act > 15 then
        aoa_ang_act = 15
    elseif aoa_ang_act < 0 then
        aoa_ang_act = 0
    end

    set(aoa_ind, aoa_ang_act)

    -- G-force indicator.
    local gf_need

    if mode_sw == 1 then
        gf_need = 2.0
    else
        gf_need = get(gforce)
    end

    gf_act = gf_act + (gf_need - gf_act) * passed * 2 * power

    if gf_act > 3 then
        gf_act = 3
    elseif gf_act < -1 then
        gf_act = -1
    end

    set(gforce_ind, gf_act)

    -- Maximum and minimum needles.
    local button = get(gforce_reset)

    if gf_max < gf_act then
        gf_max = gf_act
    elseif gf_max > gf_act + 0.01 then
        gf_max = gf_max - passed * button * 2
    end

    if gf_min > gf_act then
        gf_min = gf_act
    elseif gf_min < gf_act - 0.01 then
        gf_min = gf_min + passed * button * 2
    end

    if MASTER then
        set(gforce_max, gf_max)
        set(gforce_min, gf_min)
    end

    -- Warning signals and lamp logic.
    local aoa_crit = bool2int(aoa_ang_act >= sector_ang - 0.5) * power
    local gf_crit = bool2int(gf_act >= 1.8 or gf_act <= -0.8) * power

    if aoa_crit + gf_crit > 0 then
        lamp_counter = lamp_counter + passed

        if lamp_counter > 0.3 then
            lamp_counter = 0
            lamp_lit = not lamp_lit
        end
    else
        lamp_lit = false
    end

    set(alpha_critical, aoa_crit)
    set(gforce_critical, gf_crit)
    set(auasp_lamp, bool2int(lamp_lit))
    set(speaker_auasp, math.max(aoa_crit, gf_crit) * bool2int(get(warn_fail) < 6))

    -- Lamp brightness.
    local test_btn = get(lamp_test) * math.max((get(bus27_volt_right) - 10) / 18.5, 0)
    local day_night = 1 - get(day_night_set) * 0.25
    local lamps_brt = math.max(
        (math.max(get(bus27_volt_left), get(bus27_volt_right)) - 10) / 18.5,
        0
    ) * day_night

    set(alpha_high, math.max(aoa_crit * lamps_brt, test_btn))
    set(g_force_high, math.max(gf_crit * lamps_brt, test_btn))
end
