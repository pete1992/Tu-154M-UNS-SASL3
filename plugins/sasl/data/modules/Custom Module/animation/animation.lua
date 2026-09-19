-- animation.lua
-- Animation Datarefs declaration here
-- SASL

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- SmartCopilot
    {"ismaster", "scp/api/ismaster", globalPropertyf},
    -- {"hascontrol_1", "scp/api/hascontrol_1", globalPropertyf},
})

components = {
	ext_anim {},
	rain_mask {},
}
