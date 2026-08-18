-- bkk.lua
-- BKK attitude comparison and roll warning logic.

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"bkk_on", "tu154/custom/switchers/ovhd/bkk_on", globalPropertyi},
    {"bkk_contr", "tu154/custom/switchers/ovhd/bkk_contr", globalPropertyi},
    {"roll_a", "tu154/custom/bkk/pkp_roll_left", globalPropertyf},
    {"roll_b", "tu154/custom/bkk/pkp_roll_right", globalPropertyf},
    {"roll_c", "tu154/custom/gyro/mgv_contr_roll", globalPropertyf},
    {"pitch_a", "tu154/custom/gyro/ahz_pitch_int_L", globalPropertyf},
    {"pitch_b", "tu154/custom/gyro/ahz_pitch_int_R", globalPropertyf},
    {"pitch_c", "tu154/custom/gyro/mgv_contr_pitch", globalPropertyf},
    {"bkk_fail", "tu154/custom/failures/bkk_fail", globalPropertyi},
    {"left_roll_big", "tu154/custom/bkk/left_roll_big", globalPropertyi},
    {"right_roll_big", "tu154/custom/bkk/right_roll_big", globalPropertyi},
    {"mgv_contr_fail", "tu154/custom/bkk/mgv_contr_fail", globalPropertyi},
    {"no_contr_ag", "tu154/custom/bkk/no_contr_ag", globalPropertyi},
    {"pkp_fail_left", "tu154/custom/bkk/pkp_fail_left", globalPropertyi},
    {"pkp_fail_right", "tu154/custom/bkk/pkp_fail_right", globalPropertyi},
    {"roll_left_high", "tu154/custom/lights/roll_left_high", globalPropertyf},
    {"roll_right_high", "tu154/custom/lights/roll_right_high", globalPropertyf},
    {"mgv_control_fail", "tu154/custom/lights/mgv_control_fail", globalPropertyf},
    {"no_ag_controll", "tu154/custom/lights/no_ag_controll", globalPropertyf},
    {"bkk_ok", "tu154/custom/lights/small/bkk_ok", globalPropertyf},
    {"mgv_flag", "tu154/custom/gyro/mgv_contr_flag", globalPropertyf},
    {"ias", "sim/cockpit2/gauges/indicators/airspeed_kts_pilot", globalPropertyf},
    {"radio_alt", "sim/cockpit2/gauges/indicators/radio_altimeter_height_ft_pilot", globalPropertyf},
    {"bkk_pitch", "tu154/custom/bkk/bkk_pitch", globalPropertyf},
    {"bkk_roll", "tu154/custom/bkk/bkk_roll", globalPropertyf},
    {"absu_landing_on", "tu154/custom/switchers/console/absu_landing_on", globalPropertyi},
    {"test_lamps", "tu154/custom/buttons/lamp_test_front", globalPropertyi},
    {"day_night_set", "tu154/custom/lights/day_night_set", globalPropertyf},
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},
})

local fail_a = false
local fail_b = false
local fail_c = false

local flag_ab = false
local flag_ac = false
local flag_bc = false

local roll_res = 0
local pitch_res = 0

-- true = flight mode, false = landing mode
local flight_mode = true


function update()
    local power =
        get(bkk_on) == 1
        and get(bus27_volt_left) > 13
        and get(bus27_volt_right) > 13
        and get(bkk_fail) == 0

    local a = get(roll_a)
    local b = get(roll_b)
    local c = get(roll_c)

    -- Compare all three attitude sources and latch mismatch flags.
    if power then
        if math.abs(a - b) > 7 then
            flag_ab = true
        end

        if math.abs(a - c) > 7 then
            flag_ac = true
        end

        if math.abs(b - c) > 7 then
            flag_bc = true
        end

        if not fail_a then
            fail_a = flag_ab and flag_ac
        end

        if not fail_b then
            fail_b = flag_ab and flag_bc
        end

        if not fail_c then
            fail_c = flag_ac and flag_bc
        end
    else
        fail_a = false
        fail_b = false
        fail_c = false

        flag_ab = false
        flag_ac = false
        flag_bc = false
    end

    -- Generate BKK output signals.
    local roll_left = 0
    local roll_right = 0
    local pkp_fail_l = 0
    local pkp_fail_r = 0
    local mgv_fail = 0
    local no_ag_control = 0
    local bkk_test_ok = 0

    local test = get(bkk_contr) ~= 0

    local spd = get(ias) * 1.852
    local alt = get(radio_alt) * 0.3048

    -- Switch between landing and flight roll limits.
    if spd <= 280
        or (alt <= 250 and get(absu_landing_on) == 1) then
        flight_mode = false
    elseif spd >= 340 then
        flight_mode = true
    end

    if power then
        roll_left =
            bool2int(
                test
                or (a < -33 and flight_mode)
                or (a < -15 and not flight_mode)
            )

        roll_right =
            bool2int(
                test
                or (a > 33 and flight_mode)
                or (a > 15 and not flight_mode)
            )

        pkp_fail_l = bool2int(fail_a or test)
        pkp_fail_r = bool2int(fail_b or test)
        mgv_fail = bool2int(fail_c or get(mgv_flag) == 1 or test)
        bkk_test_ok = bool2int(test)

        -- Reset latched comparison failures during the control test.
        if test then
            fail_a = false
            fail_b = false
            fail_c = false

            flag_ab = false
            flag_ac = false
            flag_bc = false
        end
    else
        roll_left = 0
        roll_right = 0
        bkk_test_ok = 0
        no_ag_control = 1
    end

    -- Calculate the resulting attitude from all valid sources.
    if pkp_fail_l + pkp_fail_r + mgv_fail < 3 then
        local valid_sources =
            (1 - pkp_fail_l)
            + (1 - pkp_fail_r)
            + (1 - mgv_fail)

        roll_res =
            (
                a * (1 - pkp_fail_l)
                + b * (1 - pkp_fail_r)
                + c * (1 - mgv_fail)
            )
            / valid_sources

        local ap = get(pitch_a)
        local bp = get(pitch_b)
        local cp = get(pitch_c)

        pitch_res =
            (
                ap * (1 - pkp_fail_l)
                + bp * (1 - pkp_fail_r)
                + cp * (1 - mgv_fail)
            )
            / valid_sources
    end

    set(bkk_pitch, pitch_res)
    set(bkk_roll, roll_res)

    -- Set BKK result flags.
    set(left_roll_big, roll_left)
    set(right_roll_big, roll_right)
    set(mgv_contr_fail, mgv_fail)
    set(no_contr_ag, no_ag_control)
    set(pkp_fail_left, pkp_fail_l)
    set(pkp_fail_right, pkp_fail_r)

    -- Calculate lamp brightness.
    local test_btn =
        get(test_lamps)
        * math.max((get(bus27_volt_right) - 10) / 18.5, 0)

    local day_night =
        1 - get(day_night_set) * 0.25

    local lamps_brt =
        math.max(
            (math.max(get(bus27_volt_left), get(bus27_volt_right)) - 10) / 18.5,
            0
        )
        * day_night

    set(
        roll_left_high,
        math.max(roll_left * lamps_brt, test_btn)
    )

    set(
        roll_right_high,
        math.max(roll_right * lamps_brt, test_btn)
    )

    set(
        mgv_control_fail,
        math.max(mgv_fail * lamps_brt, test_btn)
    )

    set(
        no_ag_controll,
        math.max(no_ag_control * lamps_brt, test_btn)
    )

    set(bkk_ok, bkk_test_ok)
end
