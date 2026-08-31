-- T154.tcas2000.lua

-- Create writable custom datarefs owned by this xTLua script.
function deferred_dataref(name, type, notifier)
    print("Deffered dataref: " .. name)
    local dref = XLuaCreateDataRef(name, type, "yes", notifier)
    return wrap_dref_any(dref, type)
end

-- Simulator and aircraft inputs.
simDR_sqwk = find_dataref("sim/cockpit2/radios/actuators/transponder_code")
simDR_fid = find_dataref("sim/cockpit2/radios/actuators/flight_id")
simDR_xpdr_reply = find_dataref("sim/cockpit/radios/transponder_light")
simDR_tcas_disp_mod = find_dataref("tu154/custom/tcas/screen_mode")
simDR_tcas_sw_mod = find_dataref("tu154/custom/switchers/tcas/tcas_mode")
simDR_tcas_mode = find_dataref("tu154/custom/tcas/mode_set")
simDR_but_sound = find_dataref("tu154/custom/buttons/srpbz/but_down")
simDR_vsi_brtleft = find_dataref("tu154/custom/gauges/vsi/vsi_brt_left")
simDR_vsi_brtright = find_dataref("tu154/custom/gauges/vsi/vsi_brt_right")
simDR_ping_pong = find_dataref("sim/graphics/animation/ping_pong_2")
simDR_sc_master = find_dataref("scp/api/ismaster")

-- Display, selector, and animation outputs. Keep the aircraft's existing
-- tu154/custom namespace so the current OBJ and panel references remain valid.
lit_atc = deferred_dataref("tu154/custom/tcas2000/lit_atc", "number")
lit_fid = deferred_dataref("tu154/custom/tcas2000/lit_fid", "number")
lit_xpndr = deferred_dataref("tu154/custom/tcas2000/lit_xpndr", "number")
mode = deferred_dataref("tu154/custom/tcas2000/mode", "number")
tcas_lit = deferred_dataref("tu154/custom/tcas2000/lit", "number")
l1 = deferred_dataref("tu154/custom/tcas2000/l1", "number")
l2 = deferred_dataref("tu154/custom/tcas2000/l2", "number")
r1 = deferred_dataref("tu154/custom/tcas2000/r1", "number")
r2 = deferred_dataref("tu154/custom/tcas2000/r2", "number")
line = deferred_dataref("tu154/custom/tcas2000/line", "string")
line_sc = deferred_dataref("tu154/custom/tcas2000/line_sc", "string")
atcfid = deferred_dataref("tu154/custom/tcas2000/atcfid", "number")

local FID_LENGTH = 7
local FID_CHARACTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789"

local squawk_digits = {0, 0, 0, 0}
local squawk_editing = false
local squawk_cursor = 0

local fid_indices = {27, 27, 27, 27, 27, 27, 27}
local fid_cursor = 0

-- SmartCopilot reports 1 on the slave, 2 on the master, and 0 when the
-- plugin is not present. Only master/standalone may change aircraft state.
local function has_write_authority()
    return simDR_sc_master ~= 1
end

local function clamp(value, minimum, maximum)
    if value < minimum then
        return minimum
    elseif value > maximum then
        return maximum
    end
    return value
end

local function rounded(value)
    return math.floor((tonumber(value) or 0) + 0.5)
end

local function rotate_knob(value, step)
    value = rounded(value) + step * 36
    while value < 0 do
        value = value + 360
    end
    while value >= 360 do
        value = value - 360
    end
    return value
end

local function controls_available()
    return simDR_tcas_disp_mod >= 0 and simDR_tcas_disp_mod < 5
end

local function pulse_button_sound(value)
    if has_write_authority() then
        simDR_but_sound = value
    end
end

local function digits_from_squawk(value)
    value = clamp(rounded(value), 0, 7777)

    local d1 = math.floor(value / 1000)
    value = value - d1 * 1000
    local d2 = math.floor(value / 100)
    value = value - d2 * 100
    local d3 = math.floor(value / 10)
    local d4 = value - d3 * 10

    -- The transponder code is octal even though the dataref is represented
    -- as a normal integer containing four decimal-looking digits.
    return {
        clamp(d1, 0, 7),
        clamp(d2, 0, 7),
        clamp(d3, 0, 7),
        clamp(d4, 0, 7),
    }
end

local function squawk_from_digits(digits)
    return digits[1] * 1000 + digits[2] * 100 + digits[3] * 10 + digits[4]
end

local function squawk_text(digits, cursor)
    local result = {}
    local cursor_visible = math.abs(simDR_ping_pong) > 0.5

    for index = 1, 4 do
        if cursor == index and not cursor_visible then
            result[index] = " "
        else
            result[index] = tostring(digits[index])
        end
    end

    return table.concat(result)
end

local function begin_squawk_edit()
    if not squawk_editing then
        squawk_digits = digits_from_squawk(simDR_sqwk)
        squawk_editing = true
    end
end

local function adjust_squawk_digit(index, step)
    if not has_write_authority() then
        return
    end

    begin_squawk_edit()
    squawk_digits[index] = (squawk_digits[index] + step) % 8
    squawk_cursor = index
end

local function commit_squawk()
    if squawk_editing and has_write_authority() then
        simDR_sqwk = squawk_from_digits(squawk_digits)
    end

    squawk_editing = false
    squawk_cursor = 0
end

local function fid_character_index(character)
    local index = string.find(FID_CHARACTERS, string.upper(character or " "), 1, true)
    return index or 27
end

local function load_fid_buffer()
    -- xTLua exposes XP11's byte[8] Flight ID dataref as a Lua string.
    -- XTLuaGetString already stops at the terminating byte, but cut an
    -- embedded NUL as well so this remains safe with every XP11 build.
    local text = tostring(simDR_fid or "")
    local terminator = string.find(text, string.char(0), 1, true)
    if terminator then
        text = string.sub(text, 1, terminator - 1)
    end
    text = string.upper(string.sub(text, 1, FID_LENGTH))

    for index = 1, FID_LENGTH do
        local character = string.sub(text, index, index)
        if character == "" then
            character = " "
        end

        fid_indices[index] = fid_character_index(character)
    end
end

local function fid_buffer_text(cursor)
    local result = {}
    local cursor_visible = math.abs(simDR_ping_pong) > 0.5

    for index = 1, FID_LENGTH do
        local character = string.sub(FID_CHARACTERS, fid_indices[index], fid_indices[index])

        if cursor == index and not cursor_visible then
            result[index] = " "
        elseif cursor == index and character == " " then
            -- Keep the edit cursor visible even when the stored Flight ID is
            -- empty; otherwise ENT appears to have no effect on the display.
            result[index] = "("
        else
            result[index] = character
        end
    end

    -- The target panel has eight character cells; XP11's own Flight ID uses
    -- seven characters plus its terminating byte.
    return table.concat(result) .. " "
end

local function fid_buffer_is_empty()
    for index = 1, FID_LENGTH do
        if string.sub(FID_CHARACTERS, fid_indices[index], fid_indices[index]) ~= " " then
            return false
        end
    end

    return true
end

local function write_fid_buffer()
    if not has_write_authority() then
        return
    end

    local text = fid_buffer_text(0)
    text = string.sub(text, 1, FID_LENGTH)

    -- Always pass all seven useful bytes so a shorter new ID also overwrites
    -- remnants of a longer old one. XP11 keeps byte eight as the terminator.
    simDR_fid = text
end

local function adjust_fid_character(step)
    if not has_write_authority() then
        return
    end

    -- A turn on the FID page must be useful immediately after MODE. The
    -- donor required a separate push before its rotary became active; this
    -- target replaces that push with ENT, but also accepts a direct turn by
    -- selecting the first character automatically.
    if fid_cursor < 1 then
        load_fid_buffer()
        fid_cursor = 1
    end

    local character_count = string.len(FID_CHARACTERS)
    fid_indices[fid_cursor] = ((fid_indices[fid_cursor] - 1 + step) % character_count) + 1
end

local function mode_text(value)
    value = rounded(value)

    if value <= 0 then
        return " ST."
    elseif value == 1 then
        return " ON "
    elseif value == 2 then
        return " ALT"
    elseif value == 3 then
        return " TA "
    end

    return " RA "
end

local function set_knob_animation(knob_name, step)
    if knob_name == "l1" then
        l1 = rotate_knob(l1, step)
    elseif knob_name == "l2" then
        l2 = rotate_knob(l2, step)
    elseif knob_name == "r1" then
        r1 = rotate_knob(r1, step)
    else
        r2 = rotate_knob(r2, step)
    end
end

local function handle_knob(knob_name, squawk_index, step)
    if not has_write_authority() then
        return
    end

    set_knob_animation(knob_name, step)

    if atcfid == 0 then
        adjust_squawk_digit(squawk_index, -step)
    elseif atcfid == 1 then
        -- CAS67 used only its right small knob. The target has four existing
        -- digit rotaries; on the FID page all of them change the selected
        -- character, while ENT advances to the next position and commits.
        adjust_fid_character(-step)
    end
end

function tcas2000_l1_up_CMDhandler(phase, duration)
    if phase == 0 then
        handle_knob("l1", 1, -1)
    end
end

function tcas2000_l1_dn_CMDhandler(phase, duration)
    if phase == 0 then
        handle_knob("l1", 1, 1)
    end
end

function tcas2000_l2_up_CMDhandler(phase, duration)
    if phase == 0 then
        handle_knob("l2", 2, -1)
    end
end

function tcas2000_l2_dn_CMDhandler(phase, duration)
    if phase == 0 then
        handle_knob("l2", 2, 1)
    end
end

function tcas2000_r1_up_CMDhandler(phase, duration)
    if phase == 0 then
        handle_knob("r1", 3, -1)
    end
end

function tcas2000_r1_dn_CMDhandler(phase, duration)
    if phase == 0 then
        handle_knob("r1", 3, 1)
    end
end

function tcas2000_r2_up_CMDhandler(phase, duration)
    if phase == 0 then
        handle_knob("r2", 4, -1)
    end
end

function tcas2000_r2_dn_CMDhandler(phase, duration)
    if phase == 0 then
        handle_knob("r2", 4, 1)
    end
end

function tcas2000_mode_CMDhandler(phase, duration)
    if phase == 0 then
        if has_write_authority() and controls_available() then
            squawk_editing = false
            squawk_cursor = 0
            fid_cursor = 0

            if atcfid == 0 then
                atcfid = 1
                load_fid_buffer()
            else
                atcfid = 0
            end
        end

        pulse_button_sound(1)
    elseif phase == 2 then
        pulse_button_sound(0)
    end
end

function tcas2000_ent_CMDhandler(phase, duration)
    if phase == 0 then
        if has_write_authority() and controls_available() then
            if atcfid == 0 then
                commit_squawk()
            elseif fid_cursor == 0 then
                load_fid_buffer()
                fid_cursor = 1
            elseif fid_cursor < FID_LENGTH then
                fid_cursor = fid_cursor + 1
            else
                write_fid_buffer()
                fid_cursor = 0
            end
        end

        pulse_button_sound(1)
    elseif phase == 2 then
        pulse_button_sound(0)
    end
end

l_1_up = create_command("tcas2000/l1_up", "TCAS2000 L1 u", tcas2000_l1_up_CMDhandler)
l_1_dn = create_command("tcas2000/l1_dn", "TCAS2000 L1 d", tcas2000_l1_dn_CMDhandler)
l_2_up = create_command("tcas2000/l2_up", "TCAS2000 L2 u", tcas2000_l2_up_CMDhandler)
l_2_dn = create_command("tcas2000/l2_dn", "TCAS2000 L2 d", tcas2000_l2_dn_CMDhandler)
r_1_up = create_command("tcas2000/r1_up", "TCAS2000 R1 u", tcas2000_r1_up_CMDhandler)
r_1_dn = create_command("tcas2000/r1_dn", "TCAS2000 R1 d", tcas2000_r1_dn_CMDhandler)
r_2_up = create_command("tcas2000/r2_up", "TCAS2000 R2 u", tcas2000_r2_up_CMDhandler)
r_2_dn = create_command("tcas2000/r2_dn", "TCAS2000 R2 d", tcas2000_r2_dn_CMDhandler)
mode_com = create_command("tcas2000/mode", "TCAS2000 ATC/FID", tcas2000_mode_CMDhandler)
ent_com = create_command("tcas2000/ent", "TCAS2000 ENT", tcas2000_ent_CMDhandler)

local function update_normal_display()
    lit_xpndr = 0

    if atcfid == 1 then
        if fid_cursor == 0 then
            load_fid_buffer()
        end

        if fid_cursor == 0 and fid_buffer_is_empty() then
            -- MODE must show a recognizable FID page even when XP11's Flight
            -- ID is still empty. ENT then starts the visible edit cursor.
            line = " FID    "
        else
            line = fid_buffer_text(fid_cursor)
        end
        lit_atc = 0
        lit_fid = 1
    else
        if squawk_editing then
            line = "SQ " .. squawk_text(squawk_digits, squawk_cursor) .. " "
        else
            local current_digits = digits_from_squawk(simDR_sqwk)
            line = squawk_text(current_digits, 0) .. mode_text(simDR_tcas_mode)
        end

        lit_atc = 1
        lit_fid = 0

        -- The legacy output name is lit_xpndr, but the panel annunciator is
        -- the RPLY lamp. It is available only on the ATC page.
        if simDR_xpdr_reply > 0 and rounded(simDR_tcas_mode) > 0 then
            lit_xpndr = 1
        end
    end
end

function tcas()
    -- Preserve the target aircraft's existing display visibility behavior;
    -- no CAS67 bus, power-switch, startup, or failure logic is introduced.
    if simDR_tcas_disp_mod == 100 then
        tcas_lit = 0
    else
        tcas_lit = 1
    end

    if has_write_authority() then
        -- Explicitly retained at the user's request. The TCAS/VSI rate itself
        -- remains direct and unsmoothed in the existing gauge code.
        simDR_vsi_brtleft = 1
        simDR_vsi_brtright = 1

        -- The SASL TCAS logic remains the owner of mode_set and screen_mode.
        -- This script only passes the physical selector position to it.
        simDR_tcas_sw_mod = clamp(rounded(mode), 0, 4)
    end

    if simDR_tcas_disp_mod < 100 then
        update_normal_display()

        -- Keep the target aircraft's pre-existing special screen states. They
        -- are not replaced with the donor's power, self-test, or failure logic.
        if simDR_tcas_disp_mod == -10 then
            line = " IDENT  "
            lit_atc = 1
            lit_fid = 1
            lit_xpndr = 0
        elseif simDR_tcas_disp_mod == -1 then
            line = " ERROR  "
            lit_atc = 0
            lit_fid = 0
            lit_xpndr = 0
        elseif simDR_tcas_disp_mod == 5 then
            line = "%%%%%%%%"
            lit_atc = 1
            lit_fid = 1
            lit_xpndr = 1
        end
    end

    -- SmartCopilot synchronizes this derived string separately. The slave
    -- renders the master's pending Squawk/FID edit without writing aircraft
    -- state itself.
    if has_write_authority() then
        line_sc = line
    elseif string.len(line_sc) > 0 then
        line = line_sc
    end
end

function after_physics()
    tcas()
end
