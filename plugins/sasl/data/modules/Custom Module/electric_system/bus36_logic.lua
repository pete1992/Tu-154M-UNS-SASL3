-- 36V Bus Logic for Tu-154M X-Plane 11
-- All comments in English, code refactored for clarity and robustness

-- System overview:
-- There are 4 main 36V buses:
--  Bus 1: Powered from TR1 (primary), can be switched to TR2
--  Bus 2: Powered from TR2 (primary), can be switched to TR1
--  Bus 3: Powered from PTS250_1 (connected to 27V right bus)
--  Bus 4: Powered from PTS250_2 (connected to 27V left bus)

local function defineProps(defs)
    for _, d in ipairs(defs) do
        _G[d[1]] = d[3](d[2])
    end
end

defineProps({
    -- Panel controls
    {"bus36_tr_left_to_right", "tu154/custom/switchers/eng/bus36_tr_left_to_right", globalPropertyi}, -- Left bus TR switch: 0 = auto, 1 = manual
    {"bus36_tr_right_to_left", "tu154/custom/switchers/eng/bus36_tr_right_to_left", globalPropertyi}, -- Right bus TR switch: 0 = auto, 1 = manual
    {"pts250_on", "tu154/custom/switchers/eng/pts250_on", globalPropertyi}, -- PTS250 switch
    {"pts250_mode", "tu154/custom/switchers/eng/pts250_mode", globalPropertyi}, -- PTS250 mode: 0 = auto, 1 = manual
    {"agr_on", "tu154/custom/switchers/ovhd/agr_on", globalPropertyi}, -- AGR switch
    -- Transformer and PTS status
    {"bus36_tr1_work", "tu154/custom/elec/bus36_tr1_work", globalPropertyi},
    {"bus36_tr2_work", "tu154/custom/elec/bus36_tr2_work", globalPropertyi},
    {"bus36_pts1_work", "tu154/custom/elec/bus36_pts1_work", globalPropertyi},
    {"bus36_pts2_work", "tu154/custom/elec/bus36_pts2_work", globalPropertyi},
    -- Bus sources (TR or cross-fed)
    {"bus36_src_L", "tu154/custom/elec/bus36_src_L", globalPropertyi}, -- 0 = TR1, 1 = TR2
    {"bus36_src_R", "tu154/custom/elec/bus36_src_R", globalPropertyi}, -- 0 = TR2, 1 = TR1
    -- Main voltages/currents
    {"bus115_1_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf},
    {"bus115_3_volt", "tu154/custom/elec/bus115_3_volt", globalPropertyf},
    {"bus115_1_amp", "tu154/custom/elec/bus115_1_amp", globalPropertyf},
    {"bus115_3_amp", "tu154/custom/elec/bus115_3_amp", globalPropertyf},
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},
    {"bus27_amp_left", "tu154/custom/elec/bus27_amp_left", globalPropertyf},
    {"bus27_amp_right", "tu154/custom/elec/bus27_amp_right", globalPropertyf},
    -- 36V outputs
    {"bus36_volt_left", "tu154/custom/elec/bus36_volt_left", globalPropertyf},
    {"bus36_volt_right", "tu154/custom/elec/bus36_volt_right", globalPropertyf},
    {"bus36_volt_pts250_1", "tu154/custom/elec/bus36_volt_pts250_1", globalPropertyf},
    {"bus36_volt_pts250_2", "tu154/custom/elec/bus36_volt_pts250_2", globalPropertyf},
    {"bus36_amp_left", "tu154/custom/elec/bus36_amp_left", globalPropertyf},
    {"bus36_amp_right", "tu154/custom/elec/bus36_amp_right", globalPropertyf},
    {"bus36_amp_pts250_1", "tu154/custom/elec/bus36_amp_pts250_1", globalPropertyf},
    {"bus36_amp_pts250_2", "tu154/custom/elec/bus36_amp_pts250_2", globalPropertyf},
    -- Failures
    {"tr1_fail", "tu154/custom/failures/tr1_fail", globalPropertyi},
    {"tr2_fail", "tu154/custom/failures/tr2_fail", globalPropertyi},
    {"pts250_1_fail", "tu154/custom/failures/pts250_1_fail", globalPropertyi},
    {"pts250_2_fail", "tu154/custom/failures/pts250_2_fail", globalPropertyi},
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
})

-- Smartcopilot
defineProperty("ismaster", globalPropertyf("scp/api/ismaster")) -- Master. 0 = plugin not found, 1 = slave 2 = master
defineProperty("hascontrol_1", globalPropertyf("scp/api/hascontrol_1")) -- Have control. 0 = plugin not found, 1 = no control 2 = has control

function update()
    -- Only execute on master instance
    if get(frame_time) > 0 and get(ismaster) ~= 1 then

        -- --- TRANSFORMER BUS LOGIC ---

        -- Read switches
        local tr1_sw = get(bus36_tr_left_to_right)
        local tr2_sw = get(bus36_tr_right_to_left)
        -- Compute transformer voltages (simulate TR failure by 0)
        local tr1_volt = (get(bus115_1_volt) / 3.27) * (1 - get(tr1_fail))
        local tr2_volt = (get(bus115_3_volt) / 3.27) * (1 - get(tr2_fail))
        -- Bus sources: 0 = normal, 1 = crossfeed
        local bus_source_L = 0
        local bus_source_R = 0
        -- Bus left logic (TR1 preferred)
        local bus_L_volt = 0
        if tr1_sw == 0 and tr1_volt > 30 then
            bus_L_volt = tr1_volt
            bus_source_L = 0
        else
            bus_L_volt = tr2_volt
            bus_source_L = 1
        end

        -- Bus right logic (TR2 preferred)
        local bus_R_volt = 0
        if tr2_sw == 0 and tr2_volt > 30 then
            bus_R_volt = tr2_volt
            bus_source_R = 0
        else
            bus_R_volt = tr1_volt
            bus_source_R = 1
        end
        set(bus36_volt_left, bus_L_volt)
        set(bus36_volt_right, bus_R_volt)
        set(bus36_src_L, bus_source_L)
        set(bus36_src_R, bus_source_R)
        set(bus36_tr1_work, tr1_volt > 0 and 1 or 0)
        set(bus36_tr2_work, tr2_volt > 0 and 1 or 0)

        -- --- PTS250 BUSES LOGIC ---

        local bus27_L = get(bus27_volt_left)
        local bus27_R = get(bus27_volt_right)

        -- PTS250_1 powers 36V Bus 3 (if right 27V is present and system enabled)
        local pts_1_volt = 0
        if bus27_R > 13 and (get(pts250_on) == 1 or get(agr_on) == 1) and get(pts250_1_fail) == 0 then
            pts_1_volt = 36
            set(bus36_pts1_work, 1)
        else
            set(bus36_pts1_work, 0)
        end
        -- PTS250_2 powers 36V Bus 4 (manual or if main 36V falls)
        local pts_2_volt = 0
        if (bus_L_volt < 30 or get(pts250_mode) == 1) and bus27_L > 13 and get(pts250_2_fail) == 0 then
            pts_2_volt = 36
            set(bus36_pts2_work, 1)
        else
            set(bus36_pts2_work, 0)
        end

        -- --- 36V BUS OUTPUT ASSIGNMENTS ---

        -- Bus 1 logic: prefer PTS250_1 if available, else right bus
        local bus_1_volt = 0
        if pts_1_volt > 0 then
            bus_1_volt = 36
            set(bus27_amp_right, get(bus27_amp_right) + get(bus36_amp_pts250_1) * 1.4) -- reflect current draw on 27V right
        else
            bus_1_volt = bus_R_volt
            set(bus36_amp_right, get(bus36_amp_right) + get(bus36_amp_pts250_1) * 1.05)
        end
        -- Bus 2 logic: prefer left main bus, else PTS250_2
        local bus_2_volt = 0
        if bus_L_volt > 30 then
            bus_2_volt = bus_L_volt
            set(bus36_amp_left, get(bus36_amp_left) + get(bus36_amp_pts250_2) * 1.05)
        else
            bus_2_volt = pts_2_volt
            set(bus27_amp_left, get(bus27_amp_left) + get(bus36_amp_pts250_2) * 1.4)
        end
        set(bus36_volt_pts250_1, bus_1_volt)
        set(bus36_volt_pts250_2, bus_2_volt)
        -- Reflect current draw on main buses (simulate transformer loading)
        set(bus115_1_amp, get(bus115_1_amp) + (get(bus36_amp_left) / 3.25) * (1 - bus_source_L) + (get(bus36_amp_right) / 3.25) * bus_source_R)
        set(bus115_3_amp, get(bus115_3_amp) + (get(bus36_amp_left) / 3.25) * (bus_source_L) + (get(bus36_amp_right) / 3.25) * (1 - bus_source_R))
    end
end

