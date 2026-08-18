-- msrp_panel.lua
-- MSRP panel controls, lamps and initialization logic.

local function defineProps(defs)
    for _, def in ipairs(defs) do
        defineProperty(def[1], def[3](def[2]))
    end
end

defineProps({
    {"msrp_mlp_main", "tu154/custom/lights/small/msrp_mlp_main", globalPropertyf},
    {"msrp_mlp_aux", "tu154/custom/lights/small/msrp_mlp_aux", globalPropertyf},
    {"msrp_up2", "tu154/custom/lights/small/msrp_up2", globalPropertyf},
    {"msrp_mars", "tu154/custom/lights/small/msrp_mars", globalPropertyf},
    {"lamp_test_msrp", "tu154/custom/buttons/lamp_test_msrp", globalPropertyi},
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
    {"msrp_night_day", "tu154/custom/switchers/eng/msrp_night_day", globalPropertyi},
    {"msrp_main_switch", "tu154/custom/switchers/eng/msrp_main_switch", globalPropertyi},
    {"mars_on", "tu154/custom/switchers/ovhd/mars_on", globalPropertyi},
    {"bus27_volt_left", "tu154/custom/elec/bus27_volt_left", globalPropertyf},
    {"bus27_volt_right", "tu154/custom/elec/bus27_volt_right", globalPropertyf},
    {"frame_time", "tu154/custom/time/frame_time", globalPropertyf},
    {"eng1_N1", "sim/flightmodel/engine/ENGN_N1_[0]", globalProperty},
    {"eng2_N1", "sim/flightmodel/engine/ENGN_N1_[1]", globalProperty},
    {"eng3_N1", "sim/flightmodel/engine/ENGN_N1_[2]", globalProperty},
    {"ismaster", "scp/api/ismaster", globalPropertyf},
})

local switcher_sound = sasl.al.loadSample("Custom Sounds/metal_switch.wav")
local button_sound = sasl.al.loadSample("Custom Sounds/plastic_btn.wav")
local rot_sound = sasl.al.loadSample("Custom Sounds/rot_click.wav")

local black_box_dir = moduleDirectory .. "/Custom Module/black_box"

local notLoaded = true
local start_timer = 0

local mlp_lit_1 = false
local mlp_lit_2 = false
local mlp_1_timer = 0
local mlp_2_timer = 0


local function wrapDigit(value)
    return value % 10
end


local function routeDigits(route)
    route = route % 1000

    return
        math.floor(route / 100),
        math.floor((route % 100) / 10),
        route % 10
end


local function sw_reset()
    if get(eng1_N1) < 5
        and get(eng2_N1) < 5
        and get(eng3_N1) < 5 then

        set(msrp_mlp_1, 0)
        set(msrp_mlp_2, 0)
        set(msrp_main_switch, 0)
    end
end


local function set_date()
    local system_date = os.date("*t")

    local date_ten = math.floor(system_date.day / 10)
    local date_one = system_date.day % 10

    local month_ten = math.floor(system_date.month / 10)
    local month_one = system_date.month % 10

    local short_year = system_date.year % 100
    local year_ten = math.floor(short_year / 10)
    local year_one = short_year % 10

    local flight_num =
        wrapDigit(get(msrp_route_hun)) * 100
        + wrapDigit(get(msrp_route_ten)) * 10
        + wrapDigit(get(msrp_route_one))

    local initial_flight_num = flight_num
    local route_hun
    local route_ten
    local route_one
    local free_route_found = false

    -- Search all possible three-digit route numbers once.
    for _ = 1, 1000 do
        route_hun, route_ten, route_one =
            routeDigits(flight_num)

        local panel_numbers =
            string.format(
                "%d%d_%d%d_%d%d_%d%d%d",
                date_ten,
                date_one,
                month_ten,
                month_one,
                year_ten,
                year_one,
                route_hun,
                route_ten,
                route_one
            )

        local filename =
            black_box_dir
            .. "/"
            .. panel_numbers
            .. ".bbox"

        local file = io.open(filename, "r")

        if file then
            file:close()
            flight_num = (flight_num + 1) % 1000
        else
            free_route_found = true
            break
        end
    end

    if not free_route_found then
        flight_num = initial_flight_num
        route_hun, route_ten, route_one =
            routeDigits(flight_num)

        print(
            "MSRP: no free route number found for current date; "
                .. "keeping route "
                .. string.format(
                    "%d%d%d",
                    route_hun,
                    route_ten,
                    route_one
                )
        )
    end

    set(msrp_date_ten, date_ten)
    set(msrp_date_one, date_one)
    set(msrp_month_ten, month_ten)
    set(msrp_month_one, month_one)
    set(msrp_year_ten, year_ten)
    set(msrp_year_one, year_one)
    set(msrp_route_hun, route_hun)
    set(msrp_route_ten, route_ten)
    set(msrp_route_one, route_one)
end


local msrp_date_ten_last = get(msrp_date_ten)
local msrp_date_one_last = get(msrp_date_one)
local msrp_month_ten_last = get(msrp_month_ten)
local msrp_month_one_last = get(msrp_month_one)
local msrp_year_ten_last = get(msrp_year_ten)
local msrp_year_one_last = get(msrp_year_one)
local msrp_route_hun_last = get(msrp_route_hun)
local msrp_route_ten_last = get(msrp_route_ten)
local msrp_route_one_last = get(msrp_route_one)

local msrp_mlp_1_last = get(msrp_mlp_1)
local msrp_mlp_2_last = get(msrp_mlp_2)
local msrp_night_day_last = get(msrp_night_day)
local msrp_main_switch_last = get(msrp_main_switch)
local mars_on_last = get(mars_on)
local lamp_test_msrp_last = get(lamp_test_msrp)


local function syncControlHistory()
    msrp_date_ten_last = get(msrp_date_ten)
    msrp_date_one_last = get(msrp_date_one)
    msrp_month_ten_last = get(msrp_month_ten)
    msrp_month_one_last = get(msrp_month_one)
    msrp_year_ten_last = get(msrp_year_ten)
    msrp_year_one_last = get(msrp_year_one)
    msrp_route_hun_last = get(msrp_route_hun)
    msrp_route_ten_last = get(msrp_route_ten)
    msrp_route_one_last = get(msrp_route_one)

    msrp_mlp_1_last = get(msrp_mlp_1)
    msrp_mlp_2_last = get(msrp_mlp_2)
    msrp_night_day_last = get(msrp_night_day)
    msrp_main_switch_last = get(msrp_main_switch)
    mars_on_last = get(mars_on)
    lamp_test_msrp_last = get(lamp_test_msrp)
end


local function check_controls(MASTER)
    local lamp_test_msrp_sw = get(lamp_test_msrp)

    if lamp_test_msrp_sw ~= lamp_test_msrp_last then
        sasl.al.playSample(button_sound, false)
    end

    local msrp_date_ten_sw = get(msrp_date_ten)
    local msrp_date_one_sw = get(msrp_date_one)
    local msrp_month_ten_sw = get(msrp_month_ten)
    local msrp_month_one_sw = get(msrp_month_one)
    local msrp_year_ten_sw = get(msrp_year_ten)
    local msrp_year_one_sw = get(msrp_year_one)
    local msrp_route_hun_sw = get(msrp_route_hun)
    local msrp_route_ten_sw = get(msrp_route_ten)
    local msrp_route_one_sw = get(msrp_route_one)

    -- Normalize rotary digits only on the authoritative side.
    if MASTER then
        msrp_date_ten_sw = wrapDigit(msrp_date_ten_sw)
        msrp_date_one_sw = wrapDigit(msrp_date_one_sw)
        msrp_month_ten_sw = wrapDigit(msrp_month_ten_sw)
        msrp_month_one_sw = wrapDigit(msrp_month_one_sw)
        msrp_year_ten_sw = wrapDigit(msrp_year_ten_sw)
        msrp_year_one_sw = wrapDigit(msrp_year_one_sw)
        msrp_route_hun_sw = wrapDigit(msrp_route_hun_sw)
        msrp_route_ten_sw = wrapDigit(msrp_route_ten_sw)
        msrp_route_one_sw = wrapDigit(msrp_route_one_sw)

        set(msrp_date_ten, msrp_date_ten_sw)
        set(msrp_date_one, msrp_date_one_sw)
        set(msrp_month_ten, msrp_month_ten_sw)
        set(msrp_month_one, msrp_month_one_sw)
        set(msrp_year_ten, msrp_year_ten_sw)
        set(msrp_year_one, msrp_year_one_sw)
        set(msrp_route_hun, msrp_route_hun_sw)
        set(msrp_route_ten, msrp_route_ten_sw)
        set(msrp_route_one, msrp_route_one_sw)
    end

    local rotary_changed =
        msrp_date_ten_sw ~= msrp_date_ten_last
        or msrp_date_one_sw ~= msrp_date_one_last
        or msrp_month_ten_sw ~= msrp_month_ten_last
        or msrp_month_one_sw ~= msrp_month_one_last
        or msrp_year_ten_sw ~= msrp_year_ten_last
        or msrp_year_one_sw ~= msrp_year_one_last
        or msrp_route_hun_sw ~= msrp_route_hun_last
        or msrp_route_ten_sw ~= msrp_route_ten_last
        or msrp_route_one_sw ~= msrp_route_one_last

    if rotary_changed then
        sasl.al.playSample(rot_sound, false)
    end

    local msrp_mlp_1_sw = get(msrp_mlp_1)
    local msrp_mlp_2_sw = get(msrp_mlp_2)
    local msrp_night_day_sw = get(msrp_night_day)
    local msrp_main_switch_sw = get(msrp_main_switch)
    local mars_on_sw = get(mars_on)

    local switch_changed =
        msrp_mlp_1_sw ~= msrp_mlp_1_last
        or msrp_mlp_2_sw ~= msrp_mlp_2_last
        or msrp_night_day_sw ~= msrp_night_day_last
        or msrp_main_switch_sw ~= msrp_main_switch_last
        or mars_on_sw ~= mars_on_last

    if switch_changed then
        sasl.al.playSample(switcher_sound, false)
    end

    msrp_date_ten_last = msrp_date_ten_sw
    msrp_date_one_last = msrp_date_one_sw
    msrp_month_ten_last = msrp_month_ten_sw
    msrp_month_one_last = msrp_month_one_sw
    msrp_year_ten_last = msrp_year_ten_sw
    msrp_year_one_last = msrp_year_one_sw
    msrp_route_hun_last = msrp_route_hun_sw
    msrp_route_ten_last = msrp_route_ten_sw
    msrp_route_one_last = msrp_route_one_sw

    msrp_mlp_1_last = msrp_mlp_1_sw
    msrp_mlp_2_last = msrp_mlp_2_sw
    msrp_night_day_last = msrp_night_day_sw
    msrp_main_switch_last = msrp_main_switch_sw
    mars_on_last = mars_on_sw
    lamp_test_msrp_last = lamp_test_msrp_sw
end


local function lamps(passed)
    local main_sw = get(msrp_main_switch)

    local test_btn =
        get(lamp_test_msrp)
        * math.max(
            (get(bus27_volt_right) - 10) / 18.5,
            0
        )
        * main_sw

    local day_night =
        0.75 + get(msrp_night_day) * 0.25

    local lamps_brt =
        math.max(
            (
                math.max(
                    get(bus27_volt_left),
                    get(bus27_volt_right)
                )
                - 10
            )
            / 18.5,
            0
        )
        * day_night
        * main_sw

    local mlp_1_brt = 0
    local mlp_2_brt = 0

    if main_sw == 1 then
        if get(msrp_mlp_1) == 1 then
            mlp_1_timer = mlp_1_timer + passed

            if mlp_1_timer > 7.1 then
                mlp_lit_1 = not mlp_lit_1
                mlp_1_timer = 0
            end
        else
            mlp_1_timer = 0
            mlp_lit_1 = false
        end

        mlp_1_brt = bool2int(mlp_lit_1)

        if get(msrp_mlp_2) == 1 then
            mlp_2_timer = mlp_2_timer + passed

            if mlp_2_timer > 6.9 then
                mlp_lit_2 = not mlp_lit_2
                mlp_2_timer = 0
            end
        else
            mlp_2_timer = 0
            mlp_lit_2 = false
        end

        mlp_2_brt = bool2int(mlp_lit_2)
    else
        mlp_1_brt = 0
        mlp_2_brt = 0
        mlp_1_timer = 0
        mlp_2_timer = 0
    end

    set(
        msrp_mlp_main,
        math.max(
            mlp_1_brt * lamps_brt,
            test_btn
        )
    )

    set(
        msrp_mlp_aux,
        math.max(
            mlp_2_brt * lamps_brt,
            test_btn
        )
    )

    -- Preserve the original UP-2 lamp behavior.
    set(
        msrp_up2,
        math.max(
            lamps_brt,
            test_btn
        )
    )

    set(
        msrp_mars,
        math.max(
            get(mars_on) * lamps_brt,
            test_btn
        )
    )
end


function update()
    local passed = get(frame_time)
    local MASTER = get(ismaster) ~= 1

    start_timer = start_timer + passed

    if notLoaded and start_timer > 0.3 then
        if MASTER then
            set_date()
            sw_reset()
        end

        syncControlHistory()
        notLoaded = false
    end

    check_controls(MASTER)
    lamps(passed)
end
