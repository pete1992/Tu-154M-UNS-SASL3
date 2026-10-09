-- electric_system.lua
-- Registers the electrical worker adapter, GPU sounds, failures and cockpit panel.

-- Electric computation is owned by one ordered worker model.
-- SASL publishes its results and retains local sounds, failures and instruments.
components = {
    electric_worker {},
    gpu_logic {},
    electric_fails {},
    electric_panel {},
}
