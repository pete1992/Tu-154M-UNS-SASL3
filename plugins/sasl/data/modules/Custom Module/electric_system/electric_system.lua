--[[
Changelog
2026-10-04
- Dispatch electrical computation through the ordered worker adapter.
- Keep GPU sounds, failures and cockpit instruments in SASL.
]]

-- Electric computation is owned by one ordered worker model.
-- SASL publishes its results and retains local sounds, failures and instruments.
components = {
    electric_worker {},
    gpu_logic {},
    electric_fails {},
    electric_panel {},
}
