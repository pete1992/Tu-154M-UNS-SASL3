-- pnp.lua
-- PNP navigation indicator logic.

defineProperty("gauge_num", 0)

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"absu_zpu_sel", "tu154/custom/switchers/console/absu_zpu_sel", globalPropertyi},
    {"course_ga", "tu154/custom/tks/course_ga_1", globalPropertyf},
    {"course_bgmk", "tu154/custom/tks/course_bgmk_1", globalPropertyf},
    {"diss_slip_angle", "tu154/custom/nvu/diss_slip_angle", globalPropertyf},
    {"nav_cs_1", "tu154/custom/radio/nav1_cs", globalPropertyf},
    {"nav_gs_1", "tu154/custom/radio/nav1_gs", globalPropertyf},
    {"nav_cs_flag_1", "tu154/custom/radio/nav1_cs_flag", globalPropertyi},
    {"nav_gs_flag_1", "tu154/custom/radio/nav1_gs_flag", globalPropertyi},
    {"nav_cs_2", "tu154/custom/radio/nav2_cs", globalPropertyf},
    {"nav_gs_2", "tu154/custom/radio/nav2_gs", globalPropertyf},
    {"nav_cs_flag_2", "tu154/custom/radio/nav2_cs_flag", globalPropertyi},
    {"nav_gs_flag_2", "tu154/custom/radio/nav2_gs_flag", globalPropertyi},
    {"obs", "tu154/custom/gauges/compas/pkp_obs_set_L", globalPropertyf},
    {"obs_side", "tu154/custom/gauges/compas/pkp_obs_set_R", globalPropertyf},
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"gyro_fail", "tu154/custom/tks/fail_left", globalPropertyi},
    {"absu_use_second_nav", "tu154/custom/absu_use_second_nav", globalPropertyi},
    {"nvu_res_course", "tu154/custom/nvu/nvu_res_course", globalPropertyf},
    {"nvu_res_z", "tu154/custom/nvu/nvu_res_z", globalPropertyf},
    {"kln_course", "tu154/custom/kln90/kln_course", globalPropertyf},
    {"kln_dev", "tu154/custom/kln90/kln_dev", globalPropertyf},
    {"kln_flag", "tu154/custom/kln90/kln_flag", globalPropertyi},
    {"show_gns", "tu154/custom/anim/show_gns", globalPropertyi},
    {"show_RXP", "tu154/custom/anim/RXP", globalPropertyi},
    {"GNS430_dtk", "tu154/custom/SC/GNS430_dtk", globalPropertyf},
    {"GNS430_dev", "tu154/custom/SC/GNS430_dev", globalPropertyf},
    {"GNS430_flag", "tu154/custom/SC/GNS430_flag", globalPropertyi},
    {"gps_power", "sim/cockpit2/radios/actuators/gps_power", globalPropertyi},
    {"RXP_course", "RXP/radios/indicators/gps_course_degtm", globalPropertyf},
    {"RXP_dev", "RXP/radios/indicators/gps_cross_track_nm", globalPropertyf},
    {"RXP_flag", "RXP/radios/indicators/hsi_flag_from_to_pilot", globalPropertyf},
    {"pnp_mode", "tu154/custom/switchers/ovhd/curs_pnp_mode_1", globalPropertyi},
    {"pkp_obs_knob", "tu154/custom/gauges/compas/pkp_obs_knob_L", globalPropertyf},
    {"absu_pnp_mode", "tu154/custom/absu/absu_pnp_mode_1", globalPropertyi},
    {"absu_pnp_mode_2", "tu154/custom/absu/absu_pnp_mode_2", globalPropertyi},
    {"nav_select", "tu154/custom/switchers/nav_select", globalPropertyi},
    {"bus27_volt", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus36_volt", "tu154/custom/elec/bus36_volt_pts250_2", globalPropertyf},
    {"fail_ga", "sim/operation/failures/rel_ss_dgy", globalPropertyf},
    {"tks_on", "tu154/custom/switchers/ovhd/tks_on_1", globalPropertyi},
    {"pkp_gyro_course", "tu154/custom/gauges/compas/pkp_gyro_course_L", globalPropertyf},
    {"pkp_obs", "tu154/custom/gauges/compas/pkp_obs_L", globalPropertyf},
    {"pkp_helper_course", "tu154/custom/gauges/compas/pkp_helper_course_L", globalPropertyf},
    {"pkp_slip_angle", "tu154/custom/gauges/compas/pkp_slip_angle_L", globalPropertyf},
    {"pkp_course_plank", "tu154/custom/gauges/compas/pkp_course_plank_L", globalPropertyf},
    {"pkp_gs_plank", "tu154/custom/gauges/compas/pkp_gs_plank_L", globalPropertyf},
    {"pkp_gs_flag", "tu154/custom/gauges/compas/pkp_gs_flag_L", globalPropertyi},
    {"pkp_course_flag", "tu154/custom/gauges/compas/pkp_course_flag_L", globalPropertyi},
    {"pkp_main_flag", "tu154/custom/gauges/compas/pkp_main_flag_L", globalPropertyi},
    {"pkp_obs_flag", "tu154/custom/gauges/compas/pkp_obs_flag_L", globalPropertyi},
    {"pkp_obs_one", "tu154/custom/gauges/compas/pkp_obs_one_L", globalPropertyf},
    {"pkp_obs_ten", "tu154/custom/gauges/compas/pkp_obs_ten_L", globalPropertyf},
    {"pkp_obs_hundr", "tu154/custom/gauges/compas/pkp_obs_hundr_L", globalPropertyf},
    {"pnp_sp_lamp", "tu154/custom/lights/small/pnp_sp_left", globalPropertyf},
    {"pnp_vor_lamp", "tu154/custom/lights/small/pnp_vor_left", globalPropertyf},
    {"pnp_nv_lamp", "tu154/custom/lights/small/pnp_nv_left", globalPropertyf},
    {"ismaster", "scp/api/ismaster", globalPropertyf},
})

local main_scale_act = math.random(-180, 180)

-- Initialize the shared course only from the local/master side.
if get(ismaster) ~= 1 then
    set(pkp_gyro_course, main_scale_act)
else
    main_scale_act = get(pkp_gyro_course)
end

local slip_ang_act = 0
local v_plank_act = 0
local h_plank_act = 0
local obs_actual = 0
local obs_knob_last = 0
local obs_now = get(obs)
local obs_course = get(obs)

function update()
    local MASTER = get(ismaster) ~= 1
    local passed = get(frame_time)

    local power =
        get(bus27_volt) > 13
        and get(bus36_volt) > 30
        and get(tks_on) == 1
        and get(fail_ga) < 6

    local mode = get(absu_pnp_mode)
    local mode_2 = get(absu_pnp_mode_2)
    local nav_sel = get(nav_select)

    -- Read the synchronized/current course before applying local movement.
    main_scale_act = get(pkp_gyro_course)

    if power then
        -- Main compass course.
        local course = get(course_ga)

        if get(pnp_mode) == 0 then
            course = get(course_bgmk)
        end

        local cur_delta = main_scale_act - course

        if cur_delta > 180 then
            cur_delta = cur_delta - 360
        elseif cur_delta < -180 then
            cur_delta = cur_delta + 360
        end

        if cur_delta > 1 then
            main_scale_act = main_scale_act - passed * 30
        elseif cur_delta < -1 then
            main_scale_act = main_scale_act + passed * 30
        else
            main_scale_act = main_scale_act - cur_delta * passed * 20
        end

        -- Slip angle.
        local slip = get(diss_slip_angle)

        slip_ang_act =
            slip_ang_act
            + (slip - slip_ang_act) * passed * 10

        if slip_ang_act > 30 then
            slip_ang_act = 30
        elseif slip_ang_act < -30 then
            slip_ang_act = -30
        end
    end

    -- Limit compass course.
    if main_scale_act > 180 then
        main_scale_act = main_scale_act - 360
    elseif main_scale_act < -180 then
        main_scale_act = main_scale_act + 360
    end

    if MASTER then
        set(pkp_gyro_course, main_scale_act)
    end

    -- Limit displayed slip angle.
    if slip_ang_act > 20 then
        slip_ang_act = 20
    elseif slip_ang_act < -20 then
        slip_ang_act = -20
    end

    set(pkp_slip_angle, slip_ang_act)

    -- TKS flag logic.
    if not power or get(gyro_fail) == 1 then
        set(pkp_main_flag, 1)
    else
        set(pkp_main_flag, 0)
    end

    local course_flag = get(nav_cs_flag_1)
    local gs_flag = get(nav_gs_flag_1)
    local course_pl = get(nav_cs_1)
    local glidesl_pl = -get(nav_gs_1)

    if mode == 2 and power then
        -- AZ-1 mode.
        course_pl = get(nav_cs_1)
        glidesl_pl = 0

        if course_pl > 1.3 then
            course_pl = 1.3
        elseif course_pl < -1.3 then
            course_pl = -1.3
        end

        obs_course = get(obs)
        set(pkp_obs_flag, 0)

        if ((get(gauge_num) == 0 and get(absu_zpu_sel) == 1)
            or (get(gauge_num) == 1 and get(absu_zpu_sel) == 0))
            and mode_2 > 1 then

            obs_course = get(obs_side)
            set(pkp_obs_flag, 1)
        end

        course_flag = get(nav_cs_flag_1)
        gs_flag = 1

    elseif mode == 3 and power then
        -- AZ-2 mode.
        course_pl = get(nav_cs_2)
        glidesl_pl = 0

        if course_pl > 1.3 then
            course_pl = 1.3
        elseif course_pl < -1.3 then
            course_pl = -1.3
        end

        obs_course = get(obs)
        set(pkp_obs_flag, 0)

        if ((get(gauge_num) == 0 and get(absu_zpu_sel) == 1)
            or (get(gauge_num) == 1 and get(absu_zpu_sel) == 0))
            and mode_2 > 1 then

            obs_course = get(obs_side)
            set(pkp_obs_flag, 1)
        end

        course_flag = get(nav_cs_flag_2)
        gs_flag = 1

    elseif mode == 4 and power then
        -- APP mode.
        course_pl = get(nav_cs_1)
        glidesl_pl = -get(nav_gs_1)

        if get(absu_use_second_nav) == 1 then
            course_pl = get(nav_cs_2)
            glidesl_pl = -get(nav_gs_2)
        end

        if course_pl > 1.3 then
            course_pl = 1.3
        elseif course_pl < -1.3 then
            course_pl = -1.3
        end

        obs_course = get(obs)
        set(pkp_obs_flag, 0)

        if ((get(gauge_num) == 0 and get(absu_zpu_sel) == 1)
            or (get(gauge_num) == 1 and get(absu_zpu_sel) == 0))
            and mode_2 > 1 then

            obs_course = get(obs_side)
            set(pkp_obs_flag, 1)
        end

        course_flag = math.min(get(nav_cs_flag_1), get(nav_cs_flag_2))
        gs_flag = math.min(get(nav_gs_flag_1), get(nav_gs_flag_2))

    elseif power and mode == 1 and nav_sel == 0 then
        -- NVU mode.
        obs_course = get(nvu_res_course)
        course_pl = -get(nvu_res_z) * 0.1
        glidesl_pl = 0

        gs_flag = 1
        course_flag = 0

        set(pkp_obs_flag, 1)

    elseif power and mode == 1 and nav_sel == 1 then
        -- KLN/GNS/RXP mode.
        obs_course = get(kln_course)
        course_pl = get(kln_dev) * 0.1852
        glidesl_pl = 0

        gs_flag = 1
        course_flag = bool2int(get(kln_flag) == 0)

        if get(show_gns) == 1 and get(show_RXP) == 0 then
            -- GNS.
            obs_course = get(GNS430_dtk)
            course_pl = get(GNS430_dev) * 0.1852 * 2.1
            glidesl_pl = 0

            gs_flag = 1
            course_flag = get(GNS430_flag)

        elseif get(show_gns) == 1 and get(show_RXP) == 1 then
            -- RXP.
            obs_course = get(RXP_course)
            course_pl = get(RXP_dev) * 1.852 * 0.5
            glidesl_pl = 0

            gs_flag = 1
            course_flag = bool2int(get(RXP_flag) == 0)
        end

        set(pkp_obs_flag, 1)

    elseif power then
        obs_course = get(obs)
        course_pl = 0
        glidesl_pl = 0

        gs_flag = 1
        course_flag = 1

        set(pkp_obs_flag, 1)

    else
        course_pl = 0
        glidesl_pl = 0

        gs_flag = 1
        course_flag = 1

        set(pkp_obs_flag, 1)
    end

    -- Smooth course and glideslope planks.
    v_plank_act =
        v_plank_act
        + (course_pl - v_plank_act) * passed * 5

    h_plank_act =
        h_plank_act
        + (glidesl_pl - h_plank_act) * passed * 5

    if v_plank_act > 1.1 then
        v_plank_act = 1.1
    elseif v_plank_act < -1.1 then
        v_plank_act = -1.1
    end

    if h_plank_act > 1.1 then
        h_plank_act = 1.1
    elseif h_plank_act < -1.1 then
        h_plank_act = -1.1
    end

    set(pkp_course_plank, v_plank_act)
    set(pkp_gs_plank, h_plank_act)
    set(pkp_gs_flag, gs_flag)
    set(pkp_course_flag, course_flag)

    -- Smooth OBS course.
    if power then
        local obs_delta = obs_actual - obs_course

        if obs_delta > 180 then
            obs_delta = obs_delta - 360
        elseif obs_delta < -180 then
            obs_delta = obs_delta + 360
        end

        if obs_delta > 2 then
            obs_actual = obs_actual - passed * 30
        elseif obs_delta < -2 then
            obs_actual = obs_actual + passed * 30
        else
            obs_actual = obs_actual - obs_delta * passed * 15
        end
    end

    while obs_actual > 360 do
        obs_actual = obs_actual - 360
    end

    while obs_actual < 0 do
        obs_actual = obs_actual + 360
    end

    set(pkp_obs, obs_actual)

    -- Apply OBS knob movement.
    local obs_knob_now = get(pkp_obs_knob)

    while obs_knob_now > 360 do
        obs_knob_now = obs_knob_now - 360
    end

    while obs_knob_now < 0 do
        obs_knob_now = obs_knob_now + 360
    end

    if MASTER then
        set(pkp_obs_knob, obs_knob_now)
    end

    local knob_diff = obs_knob_now - obs_knob_last
    obs_knob_last = obs_knob_now
    obs_now = get(obs)

    if math.abs(knob_diff) < 50 then
        obs_now = obs_now + knob_diff
    end

    while obs_now > 360 do
        obs_now = obs_now - 360
    end

    while obs_now < 0 do
        obs_now = obs_now + 360
    end

    if MASTER then
        set(obs, math.floor(obs_now + 0.4))
    end

    -- OBS number drums.
    local obs_1 = obs_now % 10
    local obs_10 =
        math.floor((obs_now % 100) * 0.1)
        + math.max(obs_1 - 9, 0)

    local obs_100 =
        math.floor((obs_now % 1000) * 0.01)
        + math.max(obs_10 - 9, 0)

    set(pkp_obs_hundr, obs_100)
    set(pkp_obs_ten, obs_10)
    set(pkp_obs_one, obs_1)

    -- Limit helper course.
    local ZK_crs = get(pkp_helper_course)

    while ZK_crs > 360 do
        ZK_crs = ZK_crs - 360
    end

    while ZK_crs < 0 do
        ZK_crs = ZK_crs + 360
    end

    set(pkp_helper_course, ZK_crs)

    -- Mode lamps.
    if power then
        set(pnp_sp_lamp, bool2int(mode == 4))
        set(pnp_vor_lamp, bool2int(mode == 2 or mode == 3))
        set(pnp_nv_lamp, bool2int(mode == 1))
    else
        set(pnp_sp_lamp, 0)
        set(pnp_vor_lamp, 0)
        set(pnp_nv_lamp, 0)
    end
end
