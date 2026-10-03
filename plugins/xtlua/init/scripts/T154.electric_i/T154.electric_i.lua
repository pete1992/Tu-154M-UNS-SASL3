--[[
Changelog
2026-10-04
- Create and initialize the two owned, fixed-capacity electrical string mailboxes.
]]

-- Own the electric mailbox storage on X-Plane's main thread.
local Packet = dofile("../../../scripts/T154.electric/packet.lua")
local module_env = getfenv(1)
local deferred_datarefs = {
    { "electric_worker_request", Packet.REQUEST_PATH, "string" },
    { "electric_worker_response", Packet.RESPONSE_PATH, "string" },
}

local function create_datarefs(definitions)
    for _, def in ipairs(definitions) do
        local handle = XLuaCreateDataRef(def[2], def[3], "yes", nil)
        module_env[def[1]] = wrap_dref_any(handle, def[3])
        module_env[def[1]] = Packet.empty()
    end
end

create_datarefs(deferred_datarefs)
