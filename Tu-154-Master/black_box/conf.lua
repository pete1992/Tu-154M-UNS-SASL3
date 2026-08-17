function love.conf(t)
    t.title = "Black Box Decoder"        -- window title
    t.author = "Felis Leopard"        -- app author
    t.window.icon = "images/icon.png" -- window icon

    t.console = false           -- show console
    
    t.window.width = 1280                -- The window width (number)
    t.window.height = 800               -- The window height (number)
    t.window.vsync = 0
    
    t.window.resizable = false          -- Let the window be user-resizable (boolean)
    t.window.minwidth = 1280             -- Minimum window width if the window is resizable (number)
    t.window.minheight = 800            -- Minimum window height if the window is resizable (number)
    
    t.modules.joystick = false   -- joystick 
    t.modules.audio = false      -- audio
    t.modules.keyboard = true   -- keyboard
    t.modules.event = true      -- events
    t.modules.image = true      -- images
    t.modules.graphics = true   -- graphics
    t.modules.timer = true      -- timer
    t.modules.mouse = true      -- mouse
    t.modules.sound = false      -- sound
    t.modules.physics = false    -- physics
end