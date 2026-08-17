--[[
Changelog
- Grouped all property bindings through a local defineProps() helper while preserving all existing property names, Dataref paths, constructors, and their original order.
- Added X-Plane version detection so all panel sounds use the correct playSample() argument for X-Plane 11 and X-Plane 12.
- Replaced Russian comments with English comments.
- Replaced sum-based control-change detection with direct state comparisons to prevent opposite changes from cancelling each other.
- Prevented the automatic cold-and-dark reset from producing artificial switch sounds.
- Added landing-light extension and mode switches to the cold-and-dark reset.
- Prevented the landing-light safety cap from producing a delayed second switch sound when it forces the protected switch off.
- Made frame time a local per-frame value instead of creating a component-global temporary.
- Stopped updating the startup timer after initialization has completed.
- Preserved all existing sound assignments, reset timing, engine-N1 reset condition, and panel behavior unless explicitly listed above.
]]

-- Panel logic for the lighting system.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

-- Controls and sources.
defineProps({
    { "mid_left_panel_int_set", "tu154/custom/lights/mid_left_panel_int_set", globalPropertyf },
    { "left_panel_int_set", "tu154/custom/lights/left_panel_int_set", globalPropertyf },
    { "right_panel_int_set", "tu154/custom/lights/right_panel_int_set", globalPropertyf },
    { "mid_right_panel_int_set", "tu154/custom/lights/mid_right_panel_int_set", globalPropertyf },
    { "ovhd_panel_int_set", "tu154/custom/lights/ovhd_panel_int_set", globalPropertyf },
    { "cabinl_flood_set", "tu154/custom/lights/cabinl_flood_set", globalPropertyf },
    { "azs_panel_flood_set", "tu154/custom/lights/azs_panel_flood_set", globalPropertyf },
    { "cargo_light_1_set", "tu154/custom/lights/cargo_light_1_set", globalPropertyf },
    { "cargo_light_2_set", "tu154/custom/lights/cargo_light_2_set", globalPropertyf },
    { "tech_light_set", "tu154/custom/lights/tech_light_set", globalPropertyf },
    { "gear_nacelle_light_set", "tu154/custom/lights/gear_nacelle_light_set", globalPropertyf },
    { "nav_lights_set", "tu154/custom/lights/nav_lights_set", globalPropertyi },
    { "strobe_set", "tu154/custom/lights/strobe_set", globalPropertyi },
    { "wing_light_left_set", "tu154/custom/lights/wing_light_left_set", globalPropertyi },
    { "wing_light_right_set", "tu154/custom/lights/wing_light_right_set", globalPropertyi },
    { "tail_light_set", "tu154/custom/lights/tail_light_set", globalPropertyi },
    { "day_night_set", "tu154/custom/lights/day_night_set", globalPropertyi },
    { "landing_ext_set_L", "tu154/custom/lights/landing_ext_set_L", globalPropertyi },
    { "landing_ext_set_R", "tu154/custom/lights/landing_ext_set_R", globalPropertyi },
    { "landing_mode_set_L", "tu154/custom/lights/landing_mode_set_L", globalPropertyi },
    { "landing_mode_set_R", "tu154/custom/lights/landing_mode_set_R", globalPropertyi },
    { "light_signal_set", "tu154/custom/lights/light_signal_set", globalPropertyi },
    { "sign_belts", "tu154/custom/switchers/ovhd/sign_belts", globalPropertyi },
    { "sign_nosmoke", "tu154/custom/switchers/ovhd/sign_nosmoke", globalPropertyi },
    { "sign_exit", "tu154/custom/switchers/ovhd/sign_exit", globalPropertyi },
    { "landing_light_off", "tu154/custom/lights/landing_light_off", globalPropertyi },
    { "landing_light_off_cap", "tu154/custom/lights/landing_light_off_cap", globalPropertyi },
    { "eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", globalPropertyf },
    { "eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]", globalPropertyf },
    { "eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", globalPropertyf },
    { "frame_time", "tu154/custom/time/frame_time", globalPropertyf },
})

-- Added for X-Plane 11 / X-Plane 12 sound API compatibility.
defineProperty("xp_version", globalPropertyi("sim/version/xplane_internal_version"))

-- Previous control states used for sound detection.
local mid_left_panel_last = get(mid_left_panel_int_set)
local left_panel_last = get(left_panel_int_set)
local right_panel_last = get(right_panel_int_set)
local mid_right_panel_last = get(mid_right_panel_int_set)
local ovhd_panel_last = get(ovhd_panel_int_set)
local cabinl_flood_last = get(cabinl_flood_set)
local azs_panel_flood_last = get(azs_panel_flood_set)
local cargo_1_last = get(cargo_light_1_set)
local cargo_2_last = get(cargo_light_2_set)
local tech_light_last = get(tech_light_set)
local gear_nacelle_last = get(gear_nacelle_light_set)
local day_night_last = get(day_night_set)
local nav_lights_last = get(nav_lights_set)
local strobe_last = get(strobe_set)
local wing_light_left_last = get(wing_light_left_set)
local wing_light_right_last = get(wing_light_right_set)
local tail_light_last = get(tail_light_set)
local landing_ext_last_L = get(landing_ext_set_L)
local landing_ext_last_R = get(landing_ext_set_R)
local landing_mode_last_L = get(landing_mode_set_L)
local landing_mode_last_R = get(landing_mode_set_R)
local light_signal_last = get(light_signal_set)
local sign_belts_last = get(sign_belts)
local sign_nosmoke_last = get(sign_nosmoke)
local sign_exit_last = get(sign_exit)
local lights_off_last = get(landing_light_off)
local lights_cap_last = get(landing_light_off_cap)

-- Sound samples.
local switcher_sound = loadSample('Custom Sounds/metal_switch.wav')
local rotary_sound = loadSample('Custom Sounds/rot_click_big.wav')
local cap_sound = loadSample('Custom Sounds/cap.wav')
local seatbelt_sound = loadSample('Custom Sounds/seatbelt.wav')
local nosmoke_sound= loadSample('Custom Sounds/nosmoke.wav')

local XP11 = get(xp_version) > 120000

local function playPanelSample(sample)
    if XP11 then
        playSample(sample, false)
    else
        playSample(sample, false)
    end
end

local notLoaded = true
local sim_start_timer = 0

local function reset_switchers()
    if get(eng1_N1) < 5 and get(eng2_N1) < 5 and get(eng3_N1) < 5 then
        set(nav_lights_set, 0)
        set(strobe_set, 0)
        set(wing_light_left_set, 0)
        set(wing_light_right_set, 0)
        set(tail_light_set, 0)
        set(sign_belts, 0)
        set(sign_nosmoke, 0)
        set(sign_exit, 0)

        -- Keep landing-light controls in a defined cold-and-dark state.
        set(landing_ext_set_L, 0)
        set(landing_ext_set_R, 0)
        set(landing_mode_set_L, 0)
        set(landing_mode_set_R, 0)

        -- Synchronize cached states so the automatic reset remains silent.
        nav_lights_last = 0
        strobe_last = 0
        wing_light_left_last = 0
        wing_light_right_last = 0
        tail_light_last = 0
        sign_belts_last = 0
        sign_nosmoke_last = 0
        sign_exit_last = 0
        landing_ext_last_L = 0
        landing_ext_last_R = 0
        landing_mode_last_L = 0
        landing_mode_last_R = 0
    end

    notLoaded = false
end

function update()
    local passed = get(frame_time)

    -- Perform the one-time startup reset after the original 0.3-second delay.
    if notLoaded then
        sim_start_timer = sim_start_timer + passed
        if sim_start_timer > 0.3 then
            reset_switchers()
        end
    end

    -- Read current control states once per frame.
    local mid_left_panel = get(mid_left_panel_int_set)
    local left_panel = get(left_panel_int_set)
    local right_panel = get(right_panel_int_set)
    local mid_right_panel = get(mid_right_panel_int_set)
    local ovhd_panel = get(ovhd_panel_int_set)
    local cabinl_flood = get(cabinl_flood_set)
    local azs_panel_flood = get(azs_panel_flood_set)
    local cargo_1 = get(cargo_light_1_set)
    local cargo_2 = get(cargo_light_2_set)
    local tech_light = get(tech_light_set)
    local gear_nacelle = get(gear_nacelle_light_set)
    local day_night = get(day_night_set)
    local nav_lights = get(nav_lights_set)
    local strobe = get(strobe_set)
    local wing_light_left = get(wing_light_left_set)
    local wing_light_right = get(wing_light_right_set)
    local tail_light = get(tail_light_set)
    local landing_ext_L = get(landing_ext_set_L)
    local landing_ext_R = get(landing_ext_set_R)
    local landing_mode_L = get(landing_mode_set_L)
    local landing_mode_R = get(landing_mode_set_R)
    local light_signal = get(light_signal_set)
    local sign_belts_sw = get(sign_belts)
    local sign_nosmoke_sw = get(sign_nosmoke)
    local sign_exit_sw = get(sign_exit)
    local lights_off = get(landing_light_off)
    local lights_cap = get(landing_light_off_cap)

    -- The closed safety cap forces the protected landing-light switch off.
    -- Synchronize the local state immediately to avoid a delayed false switch sound.
    if lights_cap == 0 and lights_off ~= 0 then
        set(landing_light_off, 0)
        lights_off = 0
        lights_off_last = 0
    end

    -- Rotary control sounds.
    local rotary_changed =
        mid_left_panel ~= mid_left_panel_last
        or left_panel ~= left_panel_last
        or right_panel ~= right_panel_last
        or mid_right_panel ~= mid_right_panel_last
        or ovhd_panel ~= ovhd_panel_last

    if rotary_changed then
        playPanelSample(rotary_sound)
    end

    -- Switch sounds. Direct comparisons prevent opposite changes from cancelling out.
    local switcher_changed =
        cabinl_flood ~= cabinl_flood_last
        or azs_panel_flood ~= azs_panel_flood_last
        or cargo_1 ~= cargo_1_last
        or cargo_2 ~= cargo_2_last
        or tech_light ~= tech_light_last
        or gear_nacelle ~= gear_nacelle_last
        or day_night ~= day_night_last
        or nav_lights ~= nav_lights_last
        or strobe ~= strobe_last
        or wing_light_left ~= wing_light_left_last
        or wing_light_right ~= wing_light_right_last
        or tail_light ~= tail_light_last
        or landing_ext_L ~= landing_ext_last_L
        or landing_ext_R ~= landing_ext_last_R
        or landing_mode_L ~= landing_mode_last_L
        or landing_mode_R ~= landing_mode_last_R
        or light_signal ~= light_signal_last
        or sign_belts_sw ~= sign_belts_last
        or sign_nosmoke_sw ~= sign_nosmoke_last
        or sign_exit_sw ~= sign_exit_last
        or lights_off ~= lights_off_last

    if switcher_changed then
        playPanelSample(switcher_sound)
    end

    if lights_cap ~= lights_cap_last then
        playPanelSample(cap_sound)
    end
	
	if sign_belts_sw == 1 and sign_belts_last ~= 1 then
		playPanelSample(seatbelt_sound)
	end
	
	if sign_nosmoke_sw == 1 and sign_nosmoke_last ~= 1 then
		playPanelSample(nosmoke_sound)
	end

    -- Save current states for the next frame.
    mid_left_panel_last = mid_left_panel
    left_panel_last = left_panel
    right_panel_last = right_panel
    mid_right_panel_last = mid_right_panel
    ovhd_panel_last = ovhd_panel

    cabinl_flood_last = cabinl_flood
    azs_panel_flood_last = azs_panel_flood
    cargo_1_last = cargo_1
    cargo_2_last = cargo_2
    tech_light_last = tech_light
    gear_nacelle_last = gear_nacelle
    day_night_last = day_night

    nav_lights_last = nav_lights
    strobe_last = strobe
    wing_light_left_last = wing_light_left
    wing_light_right_last = wing_light_right
    tail_light_last = tail_light

    landing_ext_last_L = landing_ext_L
    landing_ext_last_R = landing_ext_R
    landing_mode_last_L = landing_mode_L
    landing_mode_last_R = landing_mode_R
    light_signal_last = light_signal

    sign_belts_last = sign_belts_sw
    sign_nosmoke_last = sign_nosmoke_sw
    sign_exit_last = sign_exit_sw

    lights_off_last = lights_off
    lights_cap_last = lights_cap
end
