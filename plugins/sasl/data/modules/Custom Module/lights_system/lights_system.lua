-- lights_system.lua
-- Registers lighting commands, panels, light outputs and failures.

components = {
    light_commands {},
    light_panel {}, -- panel with sounds
    cockpit_lights {}, -- lights intensity logic
    ext_lights {}, -- external lights
    light_fails {}, -- failures for light system
}
