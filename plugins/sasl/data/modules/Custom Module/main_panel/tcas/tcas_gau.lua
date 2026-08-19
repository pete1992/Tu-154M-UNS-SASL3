-- tcas_gau.lua
-- TCAS/VSI gauge display and logic.

size = {482, 530}

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"bus27_volt", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus115_volt", "tu154/custom/elec/bus115_1_volt", globalPropertyf},
    {"var_on", "tu154/custom/switchers/ovhd/var_left", globalPropertyi},
    {"tcas_on", "tu154/custom/switchers/ovhd/tcas_on", globalPropertyi},
    {"vsi_brt", "tu154/custom/gauges/vsi/vsi_brt_left", globalPropertyf},
    {"vvi", "sim/cockpit2/gauges/indicators/vvi_fpm_pilot", globalPropertyf},
    {"vvi_int", "tu154/custom/gauges/vvi_left", globalPropertyf},
    {"mode_set", "tu154/custom/tcas/mode_set", globalPropertyi},
    {"tcas_range_set", "tu154/custom/tcas/range_set", globalPropertyi},
    {"level_mode", "tu154/custom/tcas/level_mode", globalPropertyi},
    {"fl_mode", "tu154/custom/tcas/fl_mode", globalPropertyi},
    {"flt_id", "tu154/custom/tcas/flt_id", globalPropertyi},
    {"ra_scale_set", "tu154/custom/tcas/ra_scale_set", globalPropertyi},
    {"vvi_fail", "sim/operation/failures/rel_ss_vvi", globalPropertyi},
    {"ismaster", "scp/api/ismaster", globalPropertyf},
    {"hascontrol_1", "scp/api/hascontrol_1", globalPropertyf},
})

-- Main VSI textures
local scale_img = sasl.gl.loadImage(
    "tcas_scale.png",
    14,
    47,
    482,
    482
)

local needle_img = sasl.gl.loadImage(
    "tcas_scale.png",
    2,
    0,
    346,
    38
)

-- TCAS range scales
local scale_15 = sasl.gl.loadImage(
    "tcas_marks.png",
    18,
    377,
    72,
    72
)

local scale_10 = sasl.gl.loadImage(
    "tcas_marks.png",
    123,
    343,
    102,
    102
)

local scale_5 = sasl.gl.loadImage(
    "tcas_marks.png",
    276,
    256,
    194,
    194
)

local scale_3 = sasl.gl.loadImage(
    "tcas_marks.png",
    18,
    48,
    268,
    174
)

-- TCAS mode indications
local mc_img = sasl.gl.loadImage(
    "tcas_marks.png",
    0,
    493,
    53,
    22
)

local stby_img = sasl.gl.loadImage(
    "tcas_marks.png",
    8,
    275,
    110,
    46
)

local ta_img = sasl.gl.loadImage(
    "tcas_marks.png",
    144,
    275,
    83,
    46
)

local test_img = sasl.gl.loadImage(
    "tcas_marks.png",
    64,
    493,
    78,
    22
)

-- Range labels
local range_15 = sasl.gl.loadImage(
    "tcas_marks.png",
    372,
    399,
    112,
    24
)

local range_10 = sasl.gl.loadImage(
    "tcas_marks.png",
    372,
    364,
    112,
    24
)

local range_5 = sasl.gl.loadImage(
    "tcas_marks.png",
    372,
    329,
    112,
    24
)

local range_3 = sasl.gl.loadImage(
    "tcas_marks.png",
    372,
    293,
    112,
    24
)

-- Relative altitude filter indications
local above_img = sasl.gl.loadImage(
    "tcas_marks.png",
    372,
    58,
    113,
    22
)

local below_img = sasl.gl.loadImage(
    "tcas_marks.png",
    371,
    25,
    115,
    22
)

-- Resolution advisory scales
local tcas_scale_climb = sasl.gl.loadImage(
    "tcas_scale_climb.png",
    14,
    47,
    482,
    482
)

local tcas_scale_climb_10 = sasl.gl.loadImage(
    "tcas_scale_climb_10.png",
    14,
    47,
    482,
    482
)

local tcas_scale_descend = sasl.gl.loadImage(
    "tcas_scale_descend.png",
    14,
    47,
    482,
    482
)

local tcas_scale_descend_10 = sasl.gl.loadImage(
    "tcas_scale_descend_10.png",
    14,
    47,
    482,
    482
)

local tcas_scale_maintain_lvl = sasl.gl.loadImage(
    "tcas_scale_maintain_lvl.png",
    14,
    47,
    482,
    482
)

local tcas_scale_not_climb = sasl.gl.loadImage(
    "tcas_scale_not_climb.png",
    14,
    47,
    482,
    482
)

local tcas_scale_not_climb_2 = sasl.gl.loadImage(
    "tcas_scale_not_climb_2.png",
    14,
    47,
    482,
    482
)

local tcas_scale_not_descend = sasl.gl.loadImage(
    "tcas_scale_not_descend.png",
    14,
    47,
    482,
    482
)

local tcas_scale_not_descend_2 = sasl.gl.loadImage(
    "tcas_scale_not_descend_2.png",
    14,
    47,
    482,
    482
)

local vvi_tbl = {
    {-30, -170},
    {-20, -145},
    {-10, -110},
    {-5, -60},
    {0, 0},
    {5, 60},
    {10, 110},
    {20, 145},
    {30, 170},
}

local vvi_ang_act = 0

local mode_show = 3
local range_show = 0

local tcas_power = false
local vvi_power = false

local level = 0
local fl_text_draw = ""

local ra_mode = 0
local power_cntr = 0
local brightness = 0

function update()
    local passed = get(frame_time)

    local power_27 =
        get(bus27_volt) > 13
        and get(vvi_fail) ~= 6

    if get(var_on) == 1 then
        power_cntr = power_cntr + passed
    else
        power_cntr = 0
    end

    if power_cntr > 10 then
        power_cntr = 10
    end

    vvi_power =
        power_27
        and power_cntr > 3

    -- VSI brightness
    brightness =
        (get(vsi_brt) ^ 0.8)
        * bool2int(vvi_power)

    tcas_power =
        get(bus115_volt) > 110
        and get(tcas_on) == 1
        and vvi_power

    if get(ismaster) ~= 1 then
        set(vvi_int, get(vvi))
    end

    -- Convert vertical speed from ft/min to m/s.
    local vvi_ms = get(vvi_int) * 0.00508

    if vvi_ms >= 30 then
        vvi_ang_act = 170
    elseif vvi_ms <= -30 then
        vvi_ang_act = -170
    else
        vvi_ang_act = interpolate(
            vvi_tbl,
            vvi_ms
        )
    end

    level = get(level_mode)
    ra_mode = get(ra_scale_set)
    range_show = get(tcas_range_set)
    mode_show = get(mode_set)

    -- SASL 3 requires manual child update dispatch when update() is overridden.
    if components then
        updateAll(components)
    end
end

components = {

    -- 15 NM scale
    textureLit {
        position = {205, 165, 72, 72},
        image = scale_15,
        visible = function()
            return
                mode_show > 2
                and range_show == 3
                and tcas_power
        end,
    },

    -- 10 NM scale
    textureLit {
        position = {191, 151, 102, 102},
        image = scale_10,
        visible = function()
            return
                (
                    mode_show > 2
                    and range_show == 2
                )
                or (
                    mode_show == -1
                )
                and tcas_power
        end,
    },

    -- 5 NM scale
    textureLit {
        position = {144, 105, 194, 194},
        image = scale_5,
        visible = function()
            return
                mode_show > 2
                and range_show == 1
                and tcas_power
        end,
    },

    -- 3 NM scale
    textureLit {
        position = {106, 182, 268, 174},
        image = scale_3,
        visible = function()
            return
                mode_show > 2
                and range_show == 0
                and tcas_power
        end,
    },

    -- Meter-per-second indication
    textureLit {
        position = {213, 320, 53, 22},
        image = mc_img,
        visible = function()
            return
                mode_show <= 2
                and mode_show ~= -1
        end,
    },

    -- Main VSI scale
    textureLit {
        position = {0, 60, 482, 482},
        image = scale_img,
    },

    -- RA climb scale
    textureLit {
        position = {0, 38, 482, 482},
        image = tcas_scale_climb,
        visible = function()
            return
                ra_mode == 1
                and tcas_power
        end,
    },

    -- RA climb 10 scale
    textureLit {
        position = {0, 60, 482, 482},
        image = tcas_scale_climb_10,
        visible = function()
            return
                ra_mode == 2
                and tcas_power
        end,
    },

    -- RA descend scale
    textureLit {
        position = {0, 60, 482, 482},
        image = tcas_scale_descend,
        visible = function()
            return
                ra_mode == 3
                and tcas_power
        end,
    },

    -- RA descend 10 scale
    textureLit {
        position = {0, 60, 482, 482},
        image = tcas_scale_descend_10,
        visible = function()
            return
                ra_mode == 4
                and tcas_power
        end,
    },

    -- RA maintain level scale
    textureLit {
        position = {0, 60, 482, 482},
        image = tcas_scale_maintain_lvl,
        visible = function()
            return
                ra_mode == 5
                and tcas_power
        end,
    },

    -- RA do not climb scale
    textureLit {
        position = {0, 60, 482, 482},
        image = tcas_scale_not_climb,
        visible = function()
            return
                ra_mode == 6
                and tcas_power
        end,
    },

    -- RA do not climb extended scale
    textureLit {
        position = {0, 60, 482, 482},
        image = tcas_scale_not_climb_2,
        visible = function()
            return
                ra_mode == 7
                and tcas_power
        end,
    },

    -- RA do not descend scale
    textureLit {
        position = {0, 60, 482, 482},
        image = tcas_scale_not_descend,
        visible = function()
            return
                ra_mode == 8
                and tcas_power
        end,
    },

    -- RA do not descend extended / test scale
    textureLit {
        position = {0, 60, 482, 482},
        image = tcas_scale_not_descend_2,
        visible = function()
            return
                (
                    ra_mode == 9
                    or mode_show == -1
                )
                and tcas_power
        end,
    },

    -- 15 NM range indication
    textureLit {
        position = {350, 450, 112, 24},
        image = range_15,
        visible = function()
            return
                mode_show > 2
                and range_show == 3
                and tcas_power
        end,
    },

    -- 10 NM range indication
    textureLit {
        position = {350, 450, 112, 24},
        image = range_10,
        visible = function()
            return
                mode_show > 2
                and range_show == 2
                and tcas_power
        end,
    },

    -- 5 NM range indication
    textureLit {
        position = {350, 450, 112, 24},
        image = range_5,
        visible = function()
            return
                mode_show > 2
                and range_show == 1
                and tcas_power
        end,
    },

    -- 3 NM range indication
    textureLit {
        position = {350, 450, 112, 24},
        image = range_3,
        visible = function()
            return
                mode_show > 2
                and range_show == 0
                and tcas_power
        end,
    },

    -- Standby indication
    textureLit {
        position = {40, 40, 110, 46},
        image = stby_img,
        visible = function()
            return
                mode_show >= 0
                and mode_show <= 2
                and tcas_power
        end,
    },

    -- TA-only indication
    textureLit {
        position = {50, 40, 83, 46},
        image = ta_img,
        visible = function()
            return
                mode_show == 3
                and tcas_power
        end,
    },

    -- Test indication
    textureLit {
        position = {50, 40, 78, 22},
        image = test_img,
        visible = function()
            return
                mode_show == -1
                and tcas_power
        end,
    },

    -- Above indication
    textureLit {
        position = {30, 485, 115, 22},
        image = above_img,
        visible = function()
            return
                (
                    level == 1
                    or mode_show == -1
                )
                and tcas_power
        end,
    },

    -- Below indication
    textureLit {
        position = {30, 485, 115, 22},
        image = below_img,
        visible = function()
            return
                level == -1
                and tcas_power
        end,
    },

    -- Flight-level text
    fl_text {
        position = {30, 485, 160, 40},
        text = function()
            return fl_text_draw
        end,
    },

    -- VSI needle
    needleLit {
        position = {68, 97, 346, 346},
        image = needle_img,
        angle = function()
            return vvi_ang_act
        end,
        visible = function()
            return true
        end,
    },

    -- Brightness mask
    rectangle_ctr {
        R = 0,
        G = 0,
        B = 0,
        A = function()
            return 1 - brightness
        end,
        position_x = 0,
        position_y = 0,
        width = size[1],
        height = size[2],
    },
}
