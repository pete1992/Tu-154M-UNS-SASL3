-- dataref_creator_4.lua
-- Creates integration bridges, worker mailboxes, and additional aircraft DataRefs.

createGlobalPropertyf("scp/api/ismaster", 0)
createGlobalPropertyf("scp/api/hascontrol_1", 0)
createGlobalPropertyf("tu154/custom/eng/apu_fuel_last", 0)
-- RXP owns its external DataRefs. Publish only our checked, optional bridge;
-- creating RXP placeholders here would make a missing plugin look installed.
createGlobalPropertyi("tu154/custom/gps/rxp_available", 0)
createGlobalPropertyf("tu154/custom/gps/rxp_course", 0)
createGlobalPropertyf("tu154/custom/gps/rxp_deviation", 0)
createGlobalPropertyi("tu154/custom/gps/rxp_flag", 0)
createGlobalPropertyf("tu154/custom/xap/An24_gauges/mrp_cc", 0)
createGlobalPropertyi("tu154/custom/failures/apu_pta6_fail", 0) -- PTA-6A tachometer converter failure
createGlobalPropertyf("tu154/custom/anim/tiller_pos", 0)
createGlobalPropertyi("tu154/custom/hydro/nosewheel_turn_power", 0)
createGlobalPropertyi("tu154/custom/lights/white_light_tail", 0)

local ELECTRIC_WORKER_MAILBOX_SIZE = 8192
local ELECTRIC_WORKER_EMPTY = string.rep(" ", ELECTRIC_WORKER_MAILBOX_SIZE)

createGlobalPropertys("tu154/custom/elec/worker_request", ELECTRIC_WORKER_EMPTY, false, true, false)

createGlobalPropertys("tu154/custom/elec/worker_response", ELECTRIC_WORKER_EMPTY, false, true, false)

-- KATET source selection, radio-approach interlock and distance indication.
-- Keep these states separate from the repurposed legacy SP-50 DataRefs.
local katetControls = {
    { "mode", 0 }, -- 0 = ILS/CAT III, 1 = KATET/CAT II, 2 = SP-50/CAT I simulation profiles.
    { "nav_mode", 0 }, -- 0 = Enroute, 1 = Landing
    { "night_day", 1 }, -- 0 = Night, 1 = Day
    { "dme_rsbn", 1 }, -- 0 = DME, 1 = RSBN
}

for _, control in ipairs(katetControls) do
    createGlobalPropertyi("tu154/custom/katet/" .. control[1], control[2])
end

-- KATET approach preparation is independent of the pilot's HSI LD switch.
createGlobalPropertyi("tu154/custom/absu/approach_enabled", 0)
createGlobalPropertyi("tu154/custom/absu/approach_category", 3) -- Selected simulation profile, not autoland certification.

-- Unlike the held mechanical RSBN range, digital readouts need live validity.
createGlobalPropertyi("tu154/custom/rsbn/distance_valid", 0)

-- PPN-13 controls and animations. The source aircraft uses the same names
-- without the project-wide /custom namespace.
local ppnButtonNames = {
    "ack",
    "flt",
    "lookup",
    "poweroff",
    "snp",
    "t1",
    "t2",
    "t3",
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
    "servo_pitch_lt",
    "servo_roll_lt",
    "servo_yaw_lt",
    "bdg_pitch_lt",
    "bdg_roll_lt",
    "bdg_yaw_lt",
    "cws1_lt",
    "cws2_lt",
    "bns_p_lt",
    "bap_p_lt",
    "bap_r_lt",
    "vkv_lt",
    "vu_lt",
    "ute_lt",
    "stu_p_lt",
    "stu_r_lt",
    "at_lt",
    "bsn_lt",
    "mgv_p_stu_lt",
    "mgv_r_stu_lt",
    "mgv_p_sau_lt",
    "mgv_r_sau_lt",
    "ks_lt",
    "bns_r_lt",
    "ch1_lt",
    "ch2_lt",
    "ch3_lt",
    "ch4_lt",
    "absu_ready_lt",
}

for _, name in ipairs(ppnLightNames) do
    createGlobalPropertyf("tu154/custom/systems/absu/ppn13/" .. name, 0)
end

-- Six-channel test buses are part of the XP12 PPN-13 interface. The current
-- source logic does not drive them yet, but retaining them keeps the port's
-- dataref contract complete for future channel-test logic.
local ppnTestNames = {
    "servo_pitch",
    "servo_roll",
    "servo_yaw",
    "bdg_pitch",
    "bdg_roll",
    "bdg_yaw",
    "cws1",
    "cws2",
    "bns_p",
    "bap_p",
    "bap_r",
    "vkv",
    "vu",
    "ute",
    "stu_p",
    "stu_r",
    "at",
    "bsn",
    "mgv_p_stu",
    "mgv_r_stu",
    "mgv_p_sau",
    "mgv_r_sau",
    "ks",
    "bns_r",
}

for _, name in ipairs(ppnTestNames) do
    -- "tu154/custom/systems/absu/ppn13/" .. name .. "_test_signal",
    -- {0, 0, 0, 0, 0, 0}
end

-- Pitch servo light (main pitch servo channel active)
-- -- Roll servo light (main roll servo channel active)
-- -- Yaw servo light (main yaw servo channel active)

-- Backup pitch-channel annunciator.
-- -- BDG roll light (backup roll channel active)
-- -- BDG yaw light (backup yaw channel active)

-- CWS1 annunciator for Control Wheel Steering mode 1.
-- CWS2 annunciator for Control Wheel Steering mode 2.

-- -- BNS pitch light ( = Main vertical pitch stabilization channel)
-- -- BAP pitch light ( = automatic pitch hold mode engaged)
-- -- BAP roll light ( = automatic roll hold mode engaged)

-- -- VKV light ( = lateral guidance mode from navigation source active)
-- -- VU light ( = vertical guidance mode active)
-- -- UTE light ( = approach mode active)

-- -- STU pitch light ( = pitch stabilizer engaged)
-- -- STU roll light ( = roll stabilizer engaged)

-- -- AT light ( = automatic throttle engaged)
-- BSN mode annunciator.

-- -- MGV pitch STU light ( = electric trim pitch in STU mode active)
-- -- MGV roll STU light (electric trim roll in STU mode active)
-- -- MGV pitch SAU light (electric trim pitch in SAU mode active)
-- -- MGV roll SAU light (electric trim roll in SAU mode active)

-- -- KS light ( = course stabilization mode active)
-- -- BNS roll light ( roll stabilization channel active)

-- -- Test signal for pitch servo
-- -- Test signal for roll servo
-- -- Test signal for yaw servo

-- -- Test signal for backup pitch channel (BDG)
-- -- Test signal for backup roll channel (BDG)
-- -- Test signal for backup yaw channel (BDG)

-- -- Test signal for CWS1 mode (manual override 1)
-- -- Test signal for CWS2 mode (manual override 2)

-- -- Test signal for main pitch stabilization channel (BNS)
-- -- Test signal for automatic pitch hold (BAP)
-- -- Test signal for automatic roll hold (BAP)

-- -- Test signal for lateral navigation guidance (VKV)
-- -- Test signal for vertical navigation guidance (VU)
-- -- Test signal for approach mode (UTE)

-- -- Test signal for pitch stabilization (STU)
-- -- Test signal for roll stabilization (STU)

-- -- Test signal for auto throttle mode (AT)
-- -- Test signal for landing logic / flare mode (BSN)

-- -- Test signal for pitch trim in STU mode
-- -- Test signal for roll trim in STU mode

-- -- Test signal for pitch trim in SAU mode
-- -- Test signal for roll trim in SAU mode
-- -- Test signal for course stabilization mode (KS)
-- -- Test signal for roll channel of BNS
-- -- ABSU channel 1 indicator light
-- -- ABSU channel 2 indicator light
-- -- ABSU channel 3 indicator light
-- -- ABSU channel 4 indicator light
-- -- ABSU ready light (system operational)
