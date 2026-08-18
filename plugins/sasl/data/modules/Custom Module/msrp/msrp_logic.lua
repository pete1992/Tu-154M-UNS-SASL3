-- msrp_logic.lua
-- MSRP flight data recorder logic.

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},
    {"msrp_recording", "tu154/custom/msrp/msrp_recording", globalPropertyi},
    {"msrp_date_ten", "tu154/custom/switchers/eng/msrp_date_ten", globalPropertyi},
    {"msrp_date_one", "tu154/custom/switchers/eng/msrp_date_one", globalPropertyi},
    {"msrp_month_ten", "tu154/custom/switchers/eng/msrp_month_ten", globalPropertyi},
    {"msrp_month_one", "tu154/custom/switchers/eng/msrp_month_one", globalPropertyi},
    {"msrp_year_ten", "tu154/custom/switchers/eng/msrp_year_ten", globalPropertyi},
    {"msrp_year_one", "tu154/custom/switchers/eng/msrp_year_one", globalPropertyi},
    {"msrp_route_hun", "tu154/custom/switchers/eng/msrp_route_hun", globalPropertyi},
    {"msrp_route_ten", "tu154/custom/switchers/eng/msrp_route_ten", globalPropertyi},
    {"msrp_route_one", "tu154/custom/switchers/eng/msrp_route_one", globalPropertyi},
    {"msrp_mlp_1", "tu154/custom/switchers/eng/msrp_mlp_1", globalPropertyi},
    {"msrp_mlp_2", "tu154/custom/switchers/eng/msrp_mlp_2", globalPropertyi},
    {"msrp_main_switch", "tu154/custom/switchers/eng/msrp_main_switch", globalPropertyi},
    {"total_flight_time_sec", "sim/time/total_flight_time_sec", globalPropertyf},
    {"zulu_time_hours", "sim/cockpit2/clock_timer/zulu_time_hours", globalPropertyi},
    {"zulu_time_minutes", "sim/cockpit2/clock_timer/zulu_time_minutes", globalPropertyi},
    {"zulu_time_seconds", "sim/cockpit2/clock_timer/zulu_time_seconds", globalPropertyi},
    {"latitude", "sim/flightmodel/position/latitude", globalPropertyf},
    {"longitude", "sim/flightmodel/position/longitude", globalPropertyf},
    {"true_crs", "sim/flightmodel/position/true_psi", globalPropertyf},
    {"msl_alt", "sim/flightmodel/position/elevation", globalPropertyf},
    {"mgv_pitch", "tu154/custom/gyro/mgv_contr_pitch", globalPropertyf},
    {"mgv_roll", "tu154/custom/gyro/mgv_contr_roll", globalPropertyf},
    {"sideslip_degrees", "sim/cockpit2/gauges/indicators/sideslip_degrees", globalPropertyf},
    {"yoke_pitch", "tu154/custom/controlls/yoke_pitch", globalPropertyf},
    {"yoke_roll", "tu154/custom/controlls/yoke_roll", globalPropertyf},
    {"pedals_turn", "tu154/custom/controlls/pedals", globalPropertyf},
    {"int_pitch_trim", "tu154/custom/trimmers/int_pitch_trim", globalPropertyf},
    {"int_roll_trim", "tu154/custom/trimmers/int_roll_trim", globalPropertyf},
    {"int_yaw_trim", "tu154/custom/trimmers/int_yaw_trim", globalPropertyf},
    {"stab_ind", "tu154/custom/gauges/misc/stab_ind", globalPropertyf},
    {"flap_left_ind", "tu154/custom/gauges/misc/flap_left_ind", globalPropertyf},
    {"flap_right_ind", "tu154/custom/gauges/misc/flap_right_ind", globalPropertyf},
    {"slats", "sim/flightmodel2/controls/slat1_deploy_ratio", globalPropertyf},
    {"ail_L", "sim/flightmodel/controls/wing3l_ail1def", globalPropertyf},
    {"ail_R", "sim/flightmodel/controls/wing3r_ail1def", globalPropertyf},
    {"elevator_L", "sim/flightmodel/controls/hstab1_elv1def", globalPropertyf},
    {"elevator_R", "sim/flightmodel/controls/hstab2_elv1def", globalPropertyf},
    {"rudder", "sim/flightmodel/controls/vstab2_rud1def", globalPropertyf},
    {"spd_brk_inn_L", "sim/flightmodel/controls/wing1l_spo1def", globalPropertyf},
    {"spd_brk_inn_R", "sim/flightmodel/controls/wing1r_spo1def", globalPropertyf},
    {"spd_brk_mid_L", "sim/flightmodel/controls/wing2l_spo2def", globalPropertyf},
    {"spd_brk_mid_R", "sim/flightmodel/controls/wing2r_spo2def", globalPropertyf},
    {"roll_spoil_L", "sim/flightmodel/controls/wing2l_spo1def", globalPropertyf},
    {"roll_spoil_R", "sim/flightmodel/controls/wing2r_spo1def", globalPropertyf},
    {"msl_press", "sim/weather/barometer_sealevel_inhg", globalPropertyf},
    {"rv5_alt", "tu154/custom/misc/rv5_alt_left", globalPropertyf},
    {"vvi", "sim/cockpit2/gauges/indicators/vvi_fpm_pilot", globalPropertyf},
    {"aoa_ind", "tu154/custom/gauges/misc/aoa_ind", globalPropertyf},
    {"gforce_ind", "tu154/custom/gauges/misc/gforce_ind", globalPropertyf},
    {"ias", "sim/cockpit2/gauges/indicators/airspeed_kts_pilot", globalPropertyf},
    {"mach_svs", "tu154/custom/svs/machno", globalPropertyf},
    {"course_gpk", "tu154/custom/tks/course_gpk", globalPropertyf},
    {"course_gmk", "tu154/custom/tks/course_gmk", globalPropertyf},
    {"rpm_high_1", "tu154/custom/gauges/engine/rpm_high_1", globalPropertyf},
    {"rpm_high_2", "tu154/custom/gauges/engine/rpm_high_2", globalPropertyf},
    {"rpm_high_3", "tu154/custom/gauges/engine/rpm_high_3", globalPropertyf},
    {"ENGN_propmode_1", "sim/flightmodel/engine/ENGN_propmode[0]", globalProperty},
    {"ENGN_propmode_2", "sim/flightmodel/engine/ENGN_propmode[1]", globalProperty},
    {"ENGN_propmode_3", "sim/flightmodel/engine/ENGN_propmode[2]", globalProperty},
    {"fuel_flow_1", "tu154/custom/gauges/eng/fuel_flow_1", globalPropertyf},
    {"fuel_flow_2", "tu154/custom/gauges/eng/fuel_flow_2", globalPropertyf},
    {"fuel_flow_3", "tu154/custom/gauges/eng/fuel_flow_3", globalPropertyf},
    {"m_total", "sim/flightmodel/weight/m_total", globalPropertyf},
    {"m_fuel", "sim/flightmodel/weight/m_fuel_total", globalPropertyf},
    {"cg_pos_actual", "tu154/custom/misc/cg_pos_actual", globalPropertyf},
    {"deflection_mtr_3", "sim/flightmodel2/gear/tire_vertical_deflection_mtr[2]", globalProperty},
    {"roll_main_mode", "tu154/custom/absu/roll_main_mode", globalPropertyi},
    {"pitch_main_mode", "tu154/custom/absu/pitch_main_mode", globalPropertyi},
    {"stu_mode", "tu154/custom/absu/stu_mode", globalPropertyi},
    {"deploy_ratio_1", "sim/flightmodel2/gear/deploy_ratio[0]", globalProperty},
    {"deploy_ratio_2", "sim/flightmodel2/gear/deploy_ratio[1]", globalProperty},
    {"deploy_ratio_3", "sim/flightmodel2/gear/deploy_ratio[2]", globalProperty},
    {"outer_marker", "sim/cockpit/misc/outer_marker_lit", globalPropertyi},
    {"middle_marker", "sim/cockpit/misc/middle_marker_lit", globalPropertyi},
    {"inner_marker", "sim/cockpit/misc/inner_marker_lit", globalPropertyi},
    {"nav_cs_flag", "tu154/custom/radio/nav1_cs_flag", globalPropertyi},
    {"nav_gs_flag", "tu154/custom/radio/nav1_gs_flag", globalPropertyi},
    {"nav_cs", "tu154/custom/radio/nav1_cs", globalPropertyf},
    {"nav_gs", "tu154/custom/radio/nav1_gs", globalPropertyf},
    {"wind_direction_degt", "sim/weather/wind_direction_degt", globalPropertyf},
    {"wind_speed_kt", "sim/weather/wind_speed_kt", globalPropertyf},
    {"msrp_27_L_cc", "tu154/custom/msrp/msrp_27_L_cc", globalPropertyf},
    {"msrp_27_R_cc", "tu154/custom/msrp/msrp_27_R_cc", globalPropertyf},
    {"msrp_power", "tu154/custom/msrp/msrp_power", globalPropertyi},
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"ismaster", "scp/api/ismaster", globalPropertyf},
})

local black_box_dir = moduleDirectory .. "/Custom Module/black_box"
local filename = black_box_dir .. "/default_file.bbox"
local panel_numbers = "0"
local initialized_filename = nil
local save_timer = 0

local HEADER_NAMES = {
    "Sim time",
    "Time stamp",
    "Latitude",
    "Longtitude",
    "TrueCRS",
    "MSL alt",
    "Pitch",
    "Roll",
    "Slip",
    "Yoke pitch",
    "Yoke roll",
    "Yoke yaw",
    "Trim pitch",
    "Trim roll",
    "Trim yaw",
    "Stab pos",
    "Flaps L",
    "Flaps R",
    "Slats",
    "Aileron L",
    "Aileron R",
    "Elevator L",
    "Elevator R",
    "Rudder",
    "Spoiler OUT L",
    "Spoiler MID L",
    "Spoiler INN L",
    "Spoiler OUT R",
    "Spoiler MID R",
    "Spoiler INN R",
    "Baro alt",
    "Radio alt",
    "Vertical spd",
    "AoA",
    "G-load",
    "Airspeed",
    "Mach No",
    "Mag CRS",
    "TKS CRS",
    "ILS CRS",
    "ILS GS",
    "CRS Flag",
    "GS Flag",
    "Wind dir",
    "Wind speed",
    "ENG 1 RPM",
    "ENG 2 RPM",
    "ENG 3 RPM",
    "ENG 1 FF",
    "ENG 2 FF",
    "ENG 3 FF",
    "Total weight",
    "Total CG",
    "Total fuel",
    "On Ground",
    "Gear Down",
    "ABSU Roll mode",
    "ABSU Pitch mode",
    "ABSU AT mode",
    "Marker",
}
local HEADER_UNITS = {
    "sec",
    "HH:MM:SS",
    "deg",
    "deg",
    "deg",
    "m",
    "deg",
    "deg",
    "deg",
    "ratio",
    "ratio",
    "ratio",
    "ratio",
    "ratio",
    "ratio",
    "deg",
    "deg",
    "deg",
    "deg",
    "deg",
    "deg",
    "deg",
    "deg",
    "deg",
    "ratio",
    "ratio",
    "ratio",
    "ratio",
    "ratio",
    "ratio",
    "m",
    "m",
    "m/s",
    "deg",
    "g",
    "km/h",
    "M",
    "deg",
    "deg",
    "dot",
    "dot",
    "bool",
    "bool",
    "deg",
    "km/h",
    "%",
    "%",
    "%",
    "kg/h",
    "kg/h",
    "kg/h",
    "kg",
    "%MAC",
    "kg",
    "bool",
    "bool",
    "mode",
    "mode",
    "mode",
    "mode",
}
local HEADER_LIMITS = {
    "0/0",
    "0/0",
    "0/0",
    "0/0",
    "0/0",
    "0/0",
    "-10/20",
    "-30/30",
    "-20/20",
    "-1/1",
    "-1/1",
    "-1/1",
    "-1/1",
    "-1/1",
    "-1/1",
    "0/-5.5",
    "0/45",
    "0/45",
    "0/22",
    "-20/20",
    "-20/20",
    "-20/25",
    "-20/25",
    "-25/25",
    "0/1",
    "0/1",
    "0/1",
    "0/1",
    "0/1",
    "0/1",
    "0/0",
    "0/900",
    "-30/30",
    "-5/12",
    "-0.5/2.5",
    "-100/600",
    "-0.2/0.86",
    "0/0",
    "0/0",
    "-1/1",
    "-1/1",
    "0/0",
    "0/0",
    "0/0",
    "0/0",
    "40/96",
    "40/96",
    "40/96",
    "400/5300",
    "400/5300",
    "400/5300",
    "54000/100000",
    "18/32",
    "2500/40000",
    "0/0",
    "0/0",
    "0/0",
    "0/0",
    "0/0",
    "0/0",
}
local HEADER_GROUPS = {
    "time",
    "time",
    "coordinates",
    "coordinates",
    "course",
    "MSL",
    "orientation",
    "orientation",
    "orientation",
    "yoke",
    "yoke",
    "yoke",
    "trim",
    "trim",
    "trim",
    "stab",
    "wing mech",
    "wing mech",
    "wing mech",
    "controls",
    "controls",
    "controls",
    "controls",
    "controls",
    "spoilers",
    "spoilers",
    "spoilers",
    "spoilers",
    "spoilers",
    "spoilers",
    "altitude",
    "altitude",
    "vertical speed",
    "aoa",
    "G-load",
    "airspeed",
    "mach",
    "course",
    "course",
    "ILS",
    "ILS",
    "ILS",
    "ILS",
    "course",
    "wind speed",
    "engine RPM",
    "engine RPM",
    "engine RPM",
    "fuel flow",
    "fuel flow",
    "fuel flow",
    "mass",
    "CG",
    "mass",
    "event",
    "event",
    "event",
    "event",
    "event",
    "event",
}

local function truncate2(value)
    if value > 0 then
        return math.floor(value * 100) * 0.01
    elseif value < 0 then
        return math.ceil(value * 100) * 0.01
    end

    return 0
end

local function truncate1(value)
    if value > 0 then
        return math.floor(value * 10) * 0.1
    elseif value < 0 then
        return math.ceil(value * 10) * 0.1
    end

    return 0
end

local function floor2(value)
    return math.floor(value * 100) * 0.01
end

local function writeHeaderLine(file, prefix, values)
    file:write(prefix, "\t", table.concat(values, "\t"), "\t\n")
end

local function createFileName()
    panel_numbers =
        get(msrp_date_ten)
        .. get(msrp_date_one)
        .. "_"
        .. get(msrp_month_ten)
        .. get(msrp_month_one)
        .. "_"
        .. get(msrp_year_ten)
        .. get(msrp_year_one)
        .. "_"
        .. get(msrp_route_hun)
        .. get(msrp_route_ten)
        .. get(msrp_route_one)

    filename = black_box_dir .. "/" .. panel_numbers .. ".bbox"
end

local function ensureFile()
    if initialized_filename == filename then
        return true
    end

    local existing = io.open(filename, "r")

    if existing then
        existing:close()
        initialized_filename = filename
        return true
    end

    local file = io.open(filename, "w")

    if not file then
        print(
            "MSRP: cannot create file "
                .. filename
                .. ". Check the black_box directory and its permissions."
        )
        return false
    end

    file:write("0\t", panel_numbers, "\n")
    writeHeaderLine(file, "1", HEADER_NAMES)
    writeHeaderLine(file, "2", HEADER_UNITS)
    writeHeaderLine(file, "3", HEADER_LIMITS)
    writeHeaderLine(file, "4", HEADER_GROUPS)
    file:close()

    initialized_filename = filename
    return true
end

local function writeFile()
    local file = io.open(filename, "a")

    if not file then
        initialized_filename = nil
        print("MSRP: cannot append to file " .. filename)
        return false
    end

    local zulu =
        string.format(
            "%02d:%02d:%02d",
            get(zulu_time_hours),
            get(zulu_time_minutes),
            get(zulu_time_seconds)
        )

    local baro_alt =
        get(msl_alt)
        + (29.92 - get(msl_press)) * 1000 * 0.3048

    baro_alt = truncate1(baro_alt)

    local gear =
        bool2int(
            get(deploy_ratio_1) > 0.99
            and get(deploy_ratio_2) > 0.99
            and get(deploy_ratio_3) > 0.99
        )

    local marker = 0

    if get(inner_marker) == 1 then
        marker = 1
    elseif get(middle_marker) == 1 then
        marker = 2
    elseif get(outer_marker) == 1 then
        marker = 3
    end

    local row = {
        math.floor(get(total_flight_time_sec) * 100) * 0.01,
        zulu,
        math.floor(get(latitude) * 1000000) * 0.000001,
        math.floor(get(longitude) * 1000000) * 0.000001,
        floor2(get(true_crs)),
        floor2(get(msl_alt)),
        truncate2(get(mgv_pitch)),
        truncate2(get(mgv_roll)),
        truncate2(get(sideslip_degrees)),
        truncate2(get(yoke_pitch)),
        truncate2(get(yoke_roll)),
        truncate2(get(pedals_turn)),
        truncate2(get(int_pitch_trim)),
        truncate2(get(int_roll_trim)),
        truncate2(get(int_yaw_trim)),
        floor2(get(stab_ind)),
        floor2(get(flap_left_ind)),
        floor2(get(flap_right_ind)),
        math.floor(get(slats) * 100) * 0.22,
        truncate2(get(ail_L)),
        truncate2(get(ail_R)),
        truncate2(-get(elevator_L)),
        truncate2(-get(elevator_R)),
        truncate2(get(rudder)),
        math.floor(get(roll_spoil_L) * 100 / 20) * 0.01,
        math.floor(get(spd_brk_mid_L) * 100 / 45) * 0.01,
        math.floor(get(spd_brk_inn_L) * 100 / 50) * 0.01,
        math.floor(get(roll_spoil_R) * 100 / 20) * 0.01,
        math.floor(get(spd_brk_mid_R) * 100 / 45) * 0.01,
        math.floor(get(spd_brk_inn_R) * 100 / 50) * 0.01,
        baro_alt,
        math.floor(get(rv5_alt) * 10) * 0.1,
        math.floor(get(vvi) * 0.00508 * 100) * 0.01,
        floor2(get(aoa_ind)),
        floor2(get(gforce_ind)),
        math.floor(get(ias) * 1.852 * 10) * 0.1,
        math.floor(get(mach_svs) * 10000) * 0.0001,
        floor2(get(course_gmk)),
        floor2(get(course_gpk)),
        math.floor(get(nav_cs) * 100 * 2.5) * 0.01,
        math.floor(get(nav_gs) * 100 * 2.5) * 0.01,
        get(nav_cs_flag),
        get(nav_gs_flag),
        floor2(get(wind_direction_degt)),
        math.floor(get(wind_speed_kt) * 1.852 * 100) * 0.01,
        floor2(get(rpm_high_1))
            * (1 - 2 * bool2int(get(ENGN_propmode_1) == 3)),
        floor2(get(rpm_high_2))
            * (1 - 2 * bool2int(get(ENGN_propmode_2) == 3)),
        floor2(get(rpm_high_3))
            * (1 - 2 * bool2int(get(ENGN_propmode_3) == 3)),
        floor2(get(fuel_flow_1)),
        floor2(get(fuel_flow_2)),
        floor2(get(fuel_flow_3)),
        math.floor(get(m_total)),
        floor2(get(cg_pos_actual)),
        math.floor(get(m_fuel)),
        bool2int(get(deflection_mtr_3) > 0.01),
        gear,
        get(roll_main_mode),
        get(pitch_main_mode),
        get(stu_mode),
        marker,
    }

    for i = 1, #row do
        row[i] = tostring(row[i])
    end

    file:write("9\t", table.concat(row, "\t"), "\t\n")
    file:close()
    return true
end

createFileName()

function update()
    local MASTER = get(ismaster) ~= 1

    if not MASTER then
        return
    end

    local passed = get(frame_time)
    local airspeed = get(ias) * 1.852
    local power27_L = get(bus27_volt_left) > 13
    local power27_R = get(bus27_volt_right) > 13
    local power =
        (power27_L or power27_R)
        and get(msrp_main_switch) == 1

    save_timer = save_timer + passed

    if save_timer >= 1 then
        save_timer = save_timer - 1

        local should_record =
            airspeed > 80
            and (
                get(msrp_mlp_1) == 1
                or get(msrp_mlp_2) == 1
            )
            and power

        if should_record then
            local write_ok =
                ensureFile()
                and writeFile()

            set(msrp_recording, bool2int(write_ok))
        else
            createFileName()
            set(msrp_recording, 0)
        end
    end

    if power then
        if power27_R then
            set(msrp_27_L_cc, 0)
            set(msrp_27_R_cc, 5)
        elseif power27_L then
            set(msrp_27_L_cc, 5)
            set(msrp_27_R_cc, 0)
        end
    else
        set(msrp_27_L_cc, 0)
        set(msrp_27_R_cc, 0)
    end

    set(msrp_power, bool2int(power))
end
