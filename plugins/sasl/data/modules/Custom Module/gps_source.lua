-- Automatic local GPS-provider selection. A partial/missing RXP installation
-- uses the native GNS430; external RXP DataRefs must never be created by us.
local function defineProps(defs)
    for _, def in ipairs(defs) do
        local prop
        if def[4] ~= nil then
            prop = def[3](def[2], def[4])
        else
            prop = def[3](def[2])
        end
        defineProperty(def[1], prop)
    end
end

defineProps({
    { "show_gns", "tu154/custom/anim/show_gns", globalPropertyi },
    { "show_RXP", "tu154/custom/anim/RXP", globalPropertyi },
    { "rxp_available", "tu154/custom/gps/rxp_available", globalPropertyi },
    { "rxp_course", "tu154/custom/gps/rxp_course", globalPropertyf },
    { "rxp_deviation", "tu154/custom/gps/rxp_deviation", globalPropertyf },
    { "rxp_flag", "tu154/custom/gps/rxp_flag", globalPropertyi },
})

-- Probe every required external property silently before any read. Resolving
-- them again also detects late plugin startup and removed/changed DataRefs.
local rxp_datarefs = {
    "RXP/radios/indicators/gps_course_degtm",
    "RXP/radios/indicators/gps_cross_track_nm",
    "RXP/radios/indicators/hsi_flag_from_to_pilot",
}

local function finite(value)
    return type(value) == "number" and value == value
        and value > -math.huge and value < math.huge
end

local function update_source()
    local refs = {}
    local available = true
    for i, path in ipairs(rxp_datarefs) do
        local ref, kind = sasl.findDataRef(path, TYPE_UNKNOWN, true)
        if ref and (kind == TYPE_FLOAT or kind == TYPE_DOUBLE or kind == TYPE_INT) then
            refs[i] = ref
        else
            available = false
        end
    end

    local course, deviation, flag = 0, 0, 0
    if available then
        local raw_course = sasl.getDataRef(refs[1])
        local raw_deviation = sasl.getDataRef(refs[2])
        local raw_flag = sasl.getDataRef(refs[3])
        -- No valid fix is not the same as no plugin. Retain RXP selection,
        -- but keep invalid/non-finite navigation values out of the indicators.
        if finite(raw_course) and finite(raw_deviation)
            and (raw_flag == 1 or raw_flag == 2) then
            course, deviation, flag = raw_course, raw_deviation, raw_flag
        end
    end
    set(rxp_course, course)
    set(rxp_deviation, deviation)
    set(rxp_flag, flag)
    set(rxp_available, bool2int(available))

    -- One owner for installation selection: neither a saved preference nor
    -- the Ground panel may force an unavailable plugin (or the removed KLN).
    if get(show_gns) ~= 1 then set(show_gns, 1) end
    local selected_rxp = bool2int(available)
    if get(show_RXP) ~= selected_rxp then set(show_RXP, selected_rxp) end
end

-- Components are constructed before their first update, so initialize the
-- read-only UI and bridge now as well as on subsequent simulator frames.
update_source()

function update()
    update_source()
end
