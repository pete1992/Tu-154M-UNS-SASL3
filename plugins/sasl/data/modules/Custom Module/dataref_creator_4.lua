createGlobalPropertyi("tu154/custom/switchers/ovhd/stabil_ga_reserve", 1  )
createGlobalPropertyf("scp/api/ismaster", 0 )
createGlobalPropertyf("scp/api/hascontrol_1", 0 )
createGlobalPropertyi("tu154/custom/xap/KLN90/WPT", 0 )
createGlobalPropertyi("tu154/custom/xap/KLN90/MSG", 0 )
createGlobalPropertyi("tu154/custom/xap/KLN90/visible", 0)
createGlobalPropertyf("tu154/custom/eng/apu_fuel_last", 0)
createGlobalPropertyf("RXP/radios/indicators/gps_course_degtm", 0)
createGlobalPropertyf("RXP/radios/indicators/gps_cross_track_nm", 0)
createGlobalPropertyf("RXP/radios/indicators/hsi_flag_from_to_pilot", 0)
createGlobalPropertyf("tu154/custom/xap/An24_gauges/mrp_cc", 0)
createGlobalPropertyi("tu154/custom/tcas/vvi_left_new",0)
createGlobalPropertyi("tu154/custom/failures/apu_pta6_fail", 0) -- PTA-6A tachometer converter failure
createGlobalPropertyf("tu154/custom/anim/tiller_pos", 0)
createGlobalPropertyi("tu154/custom/hydro/nosewheel_turn_power", 0)

-- PPN-13 controls and animations. The source aircraft uses the same names
-- without the project-wide /custom namespace.
local ppnButtonNames = {
    "ack", "flt", "lookup", "poweroff", "snp", "t1", "t2", "t3",
}

for _, name in ipairs(ppnButtonNames) do
    createGlobalPropertyi("tu154/custom/manipulators/buttons/absu/ppn13_" .. name, 0)
    createGlobalPropertyf("tu154/custom/manipulators/buttons/absu/ppn13_" .. name .. "_anim", 0)
end

createGlobalPropertyi("tu154/custom/manipulators/buttons/absu/ppn13_test_absu", 0)
createGlobalPropertyi("tu154/custom/manipulators/buttons/absu/ppn13_test_svk", 0)
createGlobalPropertyi("tu154/custom/manipulators/buttons/absu/ppn13_lid", 0)
createGlobalPropertyf("tu154/custom/manipulators/switches/absu/ppn13_test_absu_anim", 0)
createGlobalPropertyf("tu154/custom/manipulators/switches/absu/ppn13_test_svk_anim", 0)
createGlobalPropertyf("tu154/custom/manipulators/caps/ppn13_lid", 0)

-- PPN-13 annunciators.
local ppnLightNames = {
    "servo_pitch_lt", "servo_roll_lt", "servo_yaw_lt",
    "bdg_pitch_lt", "bdg_roll_lt", "bdg_yaw_lt",
    "cws1_lt", "cws2_lt", "bns_p_lt", "bap_p_lt", "bap_r_lt", "vkv_lt",
    "vu_lt", "ute_lt", "stu_p_lt", "stu_r_lt", "at_lt", "bsn_lt",
    "mgv_p_stu_lt", "mgv_r_stu_lt", "mgv_p_sau_lt", "mgv_r_sau_lt",
    "ks_lt", "bns_r_lt", "ch1_lt", "ch2_lt", "ch3_lt", "ch4_lt",
    "absu_ready_lt",
}

for _, name in ipairs(ppnLightNames) do
    createGlobalPropertyf("tu154/custom/systems/absu/ppn13/" .. name, 0)
end

-- Six-channel test buses are part of the XP12 PPN-13 interface. The current
-- source logic does not drive them yet, but retaining them keeps the port's
-- dataref contract complete for future channel-test logic.
local ppnTestNames = {
    "servo_pitch", "servo_roll", "servo_yaw",
    "bdg_pitch", "bdg_roll", "bdg_yaw",
    "cws1", "cws2", "bns_p", "bap_p", "bap_r", "vkv",
    "vu", "ute", "stu_p", "stu_r", "at", "bsn",
    "mgv_p_stu", "mgv_r_stu", "mgv_p_sau", "mgv_r_sau", "ks", "bns_r",
}

for _, name in ipairs(ppnTestNames) do
    createGlobalPropertyia(
        "tu154/custom/systems/absu/ppn13/" .. name .. "_test_signal",
        {0, 0, 0, 0, 0, 0}
    )
end

-- Pitch servo light (main pitch servo channel active)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/servo_pitch_lt", 0)
-- -- Roll servo light (main roll servo channel active)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/servo_roll_lt", 0)
-- -- Yaw servo light (main yaw servo channel active)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/servo_yaw_lt", 0)

-- -- BDG pitch light (backup pitch channel active –  = )
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bdg_pitch_lt", 0)
-- -- BDG roll light (backup roll channel active)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bdg_roll_lt", 0)
-- -- BDG yaw light (backup yaw channel active)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bdg_yaw_lt", 0)

-- -- CWS1 light (Control Wheel Steering 1 mode engaged – manual override mode)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/cws1_lt", 0)
-- -- CWS2 light (Control Wheel Steering 2 mode engaged – alternate override)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/cws2_lt", 0)

-- -- BNS pitch light ( = Main vertical pitch stabilization channel)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bns_p_lt", 0)
-- -- BAP pitch light ( = automatic pitch hold mode engaged)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bap_p_lt", 0)
-- -- BAP roll light ( = automatic roll hold mode engaged)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bap_r_lt", 0)

-- -- VKV light ( = lateral guidance mode from navigation source active)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/vkv_lt", 0)
-- -- VU light ( = vertical guidance mode active)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/vu_lt", 0)
-- -- UTE light ( = approach mode active)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/ute_lt", 0)

-- -- STU pitch light ( = pitch stabilizer engaged)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/stu_p_lt", 0)
-- -- STU roll light ( = roll stabilizer engaged)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/stu_r_lt", 0)

-- -- AT light ( = automatic throttle engaged)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/at_lt", 0)
-- -- BSN light ( = final approach pitch mode – likely flare/landing logic)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bsn_lt", 0)

-- -- MGV pitch STU light ( = electric trim pitch in STU mode active)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/mgv_p_stu_lt", 0)
-- -- MGV roll STU light (electric trim roll in STU mode active)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/mgv_r_stu_lt", 0)
-- -- MGV pitch SAU light (electric trim pitch in SAU mode active)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/mgv_p_sau_lt", 0)
-- -- MGV roll SAU light (electric trim roll in SAU mode active)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/mgv_r_sau_lt", 0)

-- -- KS light ( = course stabilization mode active)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/ks_lt", 0)
-- -- BNS roll light ( roll stabilization channel active)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bns_r_lt", 0)

-- -- Test signal for pitch servo
-- createGlobalPropertyi("tu154/custom/systems/absu/ppn13/servo_pitch_test_signal", 0)
-- -- Test signal for roll servo
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/servo_roll_test_signal", 0)
-- -- Test signal for yaw servo
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/servo_yaw_test_signal", 0)

-- -- Test signal for backup pitch channel (BDG)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bdg_pitch_test_signal", 0)
-- -- Test signal for backup roll channel (BDG)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bdg_roll_test_signal", 0)
-- -- Test signal for backup yaw channel (BDG)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bdg_yaw_test_signal", 0)

-- -- Test signal for CWS1 mode (manual override 1)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/cws1_test_signal", 0)
-- -- Test signal for CWS2 mode (manual override 2)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/cws2_test_signal", 0)

-- -- Test signal for main pitch stabilization channel (BNS)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bns_p_test_signal", 0)
-- -- Test signal for automatic pitch hold (BAP)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bap_p_test_signal", 0)
-- -- Test signal for automatic roll hold (BAP)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bap_r_test_signal", 0)

-- -- Test signal for lateral navigation guidance (VKV)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/vkv_test_signal", 0)
-- -- Test signal for vertical navigation guidance (VU)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/vu_test_signal", 0)
-- -- Test signal for approach mode (UTE)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/ute_test_signal", 0)

-- -- Test signal for pitch stabilization (STU)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/stu_p_test_signal", 0)
-- -- Test signal for roll stabilization (STU)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/stu_r_test_signal", 0)

-- -- Test signal for auto throttle mode (AT)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/at_test_signal", 0)
-- -- Test signal for landing logic / flare mode (BSN)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bsn_test_signal", 0)

-- -- Test signal for pitch trim in STU mode
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/mgv_p_stu_test_signal", 0)
-- -- Test signal for roll trim in STU mode
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/mgv_r_stu_test_signal", 0)

-- -- Test signal for pitch trim in SAU mode
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/mgv_p_sau_test_signal", 0)
-- -- Test signal for roll trim in SAU mode
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/mgv_r_sau_test_signal", 0)
-- -- Test signal for course stabilization mode (KS)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/ks_test_signal", 0)
-- -- Test signal for roll channel of BNS
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/bns_r_test_signal", 0)
-- -- ABSU channel 1 indicator light
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/ch1_lt", 0)
-- -- ABSU channel 2 indicator light
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/ch2_lt", 0)
-- -- ABSU channel 3 indicator light
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/ch3_lt", 0)
-- -- ABSU channel 4 indicator light
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/ch4_lt", 0)
-- -- ABSU ready light (system operational)
-- createGlobalPropertyf("tu154/custom/systems/absu/ppn13/absu_ready_lt", 0)


