-- animation.lua
-- Registers external animations and windshield precipitation masks.

local function defineProps(defs)
    for _, d in ipairs(defs) do
        defineProperty(d[1], d[3](d[2]))
    end
end

defineProps({
    -- SmartCopilot
    { "ismaster", "scp/api/ismaster", globalPropertyf },
})

components = {
    ext_anim {},
    rain_mask {},
}
