-- flap_aero_temp.lua
-- Tu-154M flap aerodynamics with a bounded XP12 pitch-moment test correction.
--[[ Changelog
v4.2.7-XP12-test1
  Preserve the v4.2.6 CL/CD values and low-speed Cm schedules.
  In XP12, blend to a stronger nose-down Cm schedule from 150 to 200 KEAS.
  Above 200 KEAS, hold Cm at -0.5000 / -0.5660 from the first detent onward.
  This removes the weaker Cm command at 28/25 degrees in the faster regime.
  Preserve all original outputs in XP11 and with fully retracted flaps.
  Use actual flap deflections and absolute, stateless coefficient writes.
  Keep this implementation identical to flap_aero_temp.lua so either existing
  component works, and loading both does not compound the correction.

Calibration: Cycle Dump(20260911-190417), XP12 build 124311.
The 150/200 KEAS limits and fast Cm targets are an empirical test calibration,
not a measured Tu-154 aerodynamic law or a flight-validated final setting.
No elevator, stabilizer, airfoil, lift, drag, or plugin-force override is added.
--]]

-- local defineProps Function
local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"cl", "sim/aircraft/controls/acf_flap_cl", globalPropertyf},
    {"cd", "sim/aircraft/controls/acf_flap_cd", globalPropertyf},
    {"cm", "sim/aircraft/controls/acf_flap_cm", globalPropertyf},
    {"cl2", "sim/aircraft/controls/acf_flap2_cl", globalPropertyf},
    {"cd2", "sim/aircraft/controls/acf_flap2_cd", globalPropertyf},
    {"cm2", "sim/aircraft/controls/acf_flap2_cm", globalPropertyf},
    {"flap_inn_L", "sim/flightmodel/controls/wing1l_fla1def", globalPropertyf},
    {"flap_inn_R", "sim/flightmodel/controls/wing1r_fla1def", globalPropertyf},
    {"flap_mid_L", "sim/flightmodel/controls/wing2l_fla2def", globalPropertyf},
    {"flap_mid_R", "sim/flightmodel/controls/wing2r_fla2def", globalPropertyf},
    {"equivalent_airspeed", "sim/flightmodel/position/equivalent_airspeed", globalPropertyf},
    {"xplane_version", "sim/version/xplane_internal_version", globalPropertyi}
})

local FLAP1_CL = 1.029
local FLAP1_CD = 0.064
local FLAP2_CL = 1.165
local FLAP2_CD = 0.068

local XP12_CORRECTION_ENABLED = true
local CORRECTION_START_KEAS = 150.0
local CORRECTION_FULL_KEAS = 200.0

-- Preserve the original schedules below 150 KEAS and in XP11.
local flap1_cm_tbl = {
    {-10, -0.4480},
    {0,   -0.4480},
    {15,  -0.4480},
    {28,  -0.3490},
    {36,  -0.4102},
    {45,  -0.3762},
    {100, -0.3762}
}

local flap2_cm_tbl = {
    {-10, -0.5071},
    {0,   -0.5071},
    {13,  -0.5071},
    {25,  -0.3950},
    {32,  -0.4642},
    {40,  -0.4257},
    {100, -0.4257}
}

-- Equal clean endpoints give exactly zero correction with flaps retracted.
-- X-Plane applies its native deflection scaling to these coefficients; do not
-- multiply the outputs by flap fraction a second time.
local flap1_cm_fast_tbl = {
    {-10, -0.4480},
    {0,   -0.4480},
    {15,  -0.5000},
    {28,  -0.5000},
    {36,  -0.5000},
    {45,  -0.5000},
    {100, -0.5000}
}

local flap2_cm_fast_tbl = {
    {-10, -0.5071},
    {0,   -0.5071},
    {13,  -0.5660},
    {25,  -0.5660},
    {32,  -0.5660},
    {40,  -0.5660},
    {100, -0.5660}
}

local function sample(tbl, value)
    if value <= tbl[1][1] then
        return tbl[1][2]
    end
    for i = 2, #tbl do
        if value <= tbl[i][1] then
            local a = tbl[i - 1]
            local b = tbl[i]
            local fraction = (value - a[1]) / (b[1] - a[1])
            return a[2] + fraction * (b[2] - a[2])
        end
    end
    return tbl[#tbl][2]
end

local function speedBlend()
    if not XP12_CORRECTION_ENABLED or get(xplane_version) < 120000 then
        return 0.0
    end

    -- KEAS is a native X-Plane value in knots, not TAS or metres per second.
    -- Invalid or unavailable numerical samples select the original schedule.
    local speed = get(equivalent_airspeed)
    if type(speed) ~= "number" or speed ~= speed
        or speed == math.huge or speed == -math.huge then
        return 0.0
    end
    if speed <= CORRECTION_START_KEAS then
        return 0.0
    end
    if speed >= CORRECTION_FULL_KEAS then
        return 1.0
    end

    local x = (speed - CORRECTION_START_KEAS)
        / (CORRECTION_FULL_KEAS - CORRECTION_START_KEAS)
    return x * x * (3.0 - 2.0 * x)
end

local function momentCoefficient(base, fast, angle, blend)
    local original = sample(base, angle)
    if blend == 0.0 then
        return original
    end
    return original + blend * (sample(fast, angle) - original)
end

function update()
    local flap_inn = 0.5 * (get(flap_inn_L) + get(flap_inn_R))
    local flap_mid = 0.5 * (get(flap_mid_L) + get(flap_mid_R))
    local blend = speedBlend()

    set(cl, FLAP1_CL)
    set(cd, FLAP1_CD)
    set(cm, momentCoefficient(flap1_cm_tbl, flap1_cm_fast_tbl, flap_inn, blend))

    set(cl2, FLAP2_CL)
    set(cd2, FLAP2_CD)
    set(cm2, momentCoefficient(flap2_cm_tbl, flap2_cm_fast_tbl, flap_mid, blend))
end
