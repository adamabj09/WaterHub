-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Cargar Arqel (Key System)
local Arqel = loadstring(game:HttpGet("https://raw.githubusercontent.com/Cobruhehe/expert-octo-doodle/main/Arqel.lua"))()

-- Configurar Arqel
Arqel.Appearance.Title = "Premium Hub"
Arqel.Appearance.Subtitle = "Enter your key to continue"
Arqel.Appearance.Icon = "rbxassetid://95721401302279"

-- Links
Arqel.Links.GetKey = "https://discord.gg/tukey"
Arqel.Links.Discord = "https://discord.gg/tudiscord"

-- Opciones
Arqel.Options.Keyless = false
Arqel.Options.Blur = true
Arqel.Options.Draggable = true

-- Tema personalizado
Arqel.Theme.Accent = Color3.fromRGB(139, 0, 0)
Arqel.Theme.AccentHover = Color3.fromRGB(170, 20, 20)
Arqel.Theme.Background = Color3.fromRGB(15, 15, 15)
Arqel.Theme.Header = Color3.fromRGB(20, 20, 20)
Arqel.Theme.Text = Color3.fromRGB(255, 255, 255)

-- Función de validación personalizada (key = "test")
Arqel.Callbacks.OnVerify = function(key)
    -- Key de prueba: "test"
    if key == "test" then
        return {
            valid = true,
            message = "Access granted"
        }
    else
        return {
            valid = false,
            error = "KEY_INVALID",
            message = "Invalid key. Use 'test' to access."
        }
    end
end

-- Callback cuando la key es válida
Arqel.Callbacks.OnSuccess = function()
    Arqel:Notify("Welcome", "Key validated! Loading menu...", 2, "success")
    task.wait(0.5)
    loadNexonixMenu()
end

Arqel.Callbacks.OnFail = function(errorMsg)
    Arqel:Notify("Error", errorMsg, 3, "error")
end

-- Función principal del menú Nexonix
function loadNexonixMenu()
    -- Cargar Nexonix
    local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/sametexe001/sametlibs/refs/heads/main/nexonix/Library.lua"))()
    
    local KeybindList = Library:KeybindList({Name = "Keybind List"})
    
    local Window = Library:Window({Logo = "rbxassetid://77749228793011"}) do 
        local TabOne = Window:Page({Icon = "rbxassetid://129245697782918"})
        local TabTwo = Window:Page({Icon = "rbxassetid://129245697782918"})
        local TabThree = Window:Page({Icon = "rbxassetid://129245697782918"})
        local TabFour = Window:Page({Icon = "rbxassetid://129245697782918"})

        -- Tab One: Aimbot & Weapon
        do
            local AimbotSection = TabOne:Section({Name = "aimbot", Side = 1})
            local WeaponSection = TabOne:Section({Name = "weapon", Side = 2})
            TabOne:Section({Name = "weapon extras", Side = 2})
            TabOne:Section({Name = "weapon config", Side = 2})
            TabOne:Section({Name = "weapon mods", Side = 2})
            TabOne:Section({Name = "weapon stats", Side = 2})

            -- Aimbot Elements
            AimbotSection:Toggle({
                Name = "aimbot",
                Flag = "aimbot",
                Default = false,
                Tooltip = "Enable aimbot assistance",
                Callback = function(Value)
                    print("Aimbot:", Value)
                    -- Aquí va tu lógica de aimbot
                end
            })

            AimbotSection:Button({
                Name = "Reset Settings",
                Tooltip = "Reset all aimbot settings to default",
                Callback = function()
                    print("Settings reset")
                end
            })

            AimbotSection:Slider({
                Name = "Smoothness",
                Tooltip = "Aimbot smoothness level",
                Flag = "smoothness",
                Min = 1,
                Max = 100,
                Default = 50,
                Suffix = "%",
                Decimals = 1,
                Callback = function(Value)
                    print("Smoothness:", Value)
                end
            })

            AimbotSection:Slider({
                Name = "FOV",
                Tooltip = "Field of view for aimbot",
                Flag = "fov",
                Min = 10,
                Max = 500,
                Default = 100,
                Suffix = " px",
                Decimals = 0,
                Callback = function(Value)
                    print("FOV:", Value)
                end
            })

            AimbotSection:Dropdown({
                Name = "Target Part",
                Flag = "targetpart",
                Default = "Head",
                Items = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
                Callback = function(Value)
                    print("Target:", Value)
                end
            })

            AimbotSection:Dropdown({
                Name = "Aim Mode",
                Flag = "aimmode",
                Default = "Silent",
                Items = {"Silent", "Normal", "Smooth", "Flick"},
                Callback = function(Value)
                    print("Mode:", Value)
                end
            })

            AimbotSection:Label({Name = "FOV Color"}):Colorpicker({
                Flag = "fovcolor",
                Default = Color3.fromRGB(255, 0, 0),
                Callback = function(Value)
                    print("FOV Color:", Value)
                end
            })

            AimbotSection:Label({Name = "Aimbot Key"}):Keybind({
                Name = "Aimbot Key",
                Flag = "aimkey",
                Default = Enum.KeyCode.Q,
                Mode = "Toggle",
                Callback = function(Value)
                    print("Aim Key:", Value)
                end
            })

            AimbotSection:Textbox({
                Name = "Custom Target",
                Placeholder = "Enter username...",
                Flag = "customtarget",
                Numeric = false,
                Finished = true,
                Callback = function(Value)
                    print("Target:", Value)
                end
            })

            -- Weapon Elements
            local Toggle = WeaponSection:Toggle({
                Name = "No Recoil",
                Flag = "norecoil",
                Default = false,
                Tooltip = "Remove weapon recoil",
                Callback = function(Value)
                    print("No Recoil:", Value)
                end
            })

            local ToggleSettings = Toggle:Settings(200)

            ToggleSettings:Toggle({
                Name = "No Spread",
                Flag = "nospread",
                Default = false,
                Callback = function(Value)
                    print("No Spread:", Value)
                end
            })

            ToggleSettings:Toggle({
                Name = "Instant Reload",
                Flag = "instantreload",
                Default = false,
                Callback = function(Value)
                    print("Instant Reload:", Value)
                end
            })

            ToggleSettings:Button({
                Name = "Apply Changes",
                Callback = function()
                    print("Weapon settings applied")
                end
            })

            ToggleSettings:Slider({
                Name = "Damage Multiplier",
                Flag = "damagemult",
                Min = 1,
                Max = 10,
                Default = 1,
                Suffix = "x",
                Decimals = 0.1,
                Callback = function(Value)
                    print("Damage:", Value)
                end
            })

            ToggleSettings:Slider({
                Name = "Fire Rate",
                Flag = "firerate",
                Min = 0.1,
                Max = 5,
                Default = 1,
                Suffix = "x",
                Decimals = 0.1,
                Callback = function(Value)
                    print("Fire Rate:", Value)
                end
            })

            ToggleSettings:Dropdown({
                Name = "Hitbox Expander",
                Flag = "hitbox",
                Default = "Disabled",
                Items = {"Disabled", "Small", "Medium", "Large", "Huge"},
                Callback = function(Value)
                    print("Hitbox:", Value)
                end
            })

            ToggleSettings:Label({Name = "Tracer Color"}):Colorpicker({
                Flag = "tracercolor",
                Default = Color3.fromRGB(0, 255, 0),
                Callback = function(Value)
                    print("Tracer Color:", Value)
                end
            })

            Toggle:Keybind({
                Name = "Weapon Key",
                Flag = "weaponkey",
                Default = Enum.KeyCode.F,
                Mode = "Toggle",
                Callback = function(Value)
                    print("Weapon Key:", Value)
                end
            })

            WeaponSection:RangeSlider({
                Name = "Damage Range",
                Flag = "damagerange",
                Default = {10, 100},
                Gap = 10,
                Min = 1,
                Max = 200,
                Decimals = 1,
                Callback = function(value)
                    local min = value[1]
                    local max = value[2]
                    print("Damage Range:", min, "-", max)
                end
            })

            WeaponSection:Button({
                Name = "Unlock All Weapons",
                Tooltip = "Unlock all weapons in inventory",
                Callback = function()
                    print("Weapons unlocked")
                end
            })

            WeaponSection:Button({
                Name = "Max Ammo",
                Callback = function()
                    print("Max ammo set")
                end
            })
        end

        -- Tab Two: Visuals
        do
            local VisualsSection = TabTwo:Section({Name = "esp", Side = 1})
            local WorldSection = TabTwo:Section({Name = "world", Side = 2})

            VisualsSection:Toggle({
                Name = "ESP",
                Flag = "esp",
                Default = false,
                Tooltip = "Show player ESP",
                Callback = function(Value)
                    print("ESP:", Value)
                end
            })

            VisualsSection:Toggle({
                Name = "Box ESP",
                Flag = "boxesp",
                Default = false,
                Callback = function(Value)
                    print("Box ESP:", Value)
                end
            })

            VisualsSection:Toggle({
                Name = "Name ESP",
                Flag = "nameesp",
                Default = false,
                Callback = function(Value)
                    print("Name ESP:", Value)
                end
            })

            VisualsSection:Toggle({
                Name = "Health ESP",
                Flag = "healthesp",
                Default = false,
                Callback = function(Value)
                    print("Health ESP:", Value)
                end
            })

            VisualsSection:Colorpicker({
                Name = "ESP Color",
                Flag = "espcolor",
                Default = Color3.fromRGB(255, 255, 255),
                Callback = function(Value)
                    print("ESP Color:", Value)
                end
            })

            WorldSection:Toggle({
                Name = "Full Bright",
                Flag = "fullbright",
                Default = false,
                Callback = function(Value)
                    print("Full Bright:", Value)
                end
            })

            WorldSection:Slider({
                Name = "Time of Day",
                Flag = "timeofday",
                Min = 0,
                Max = 24,
                Default = 12,
                Suffix = "h",
                Callback = function(Value)
                    print("Time:", Value)
                end
            })
        end

        -- Tab Three: Movement
        do
            local MovementSection = TabThree:Section({Name = "movement", Side = 1})
            local FlySection = TabThree:Section({Name = "fly", Side = 2})

            MovementSection:Toggle({
                Name = "Speed Hack",
                Flag = "speedhack",
                Default = false,
                Callback = function(Value)
                    print("Speed:", Value)
                end
            })

            MovementSection:Slider({
                Name = "Speed",
                Flag = "speed",
                Min = 16,
                Max = 200,
                Default = 50,
                Suffix = " studs",
                Callback = function(Value)
                    print("Speed Value:", Value)
                end
            })

            MovementSection:Toggle({
                Name = "Infinite Jump",
                Flag = "infjump",
                Default = false,
                Callback = function(Value)
                    print("Inf Jump:", Value)
                end
            })

            FlySection:Toggle({
                Name = "Fly",
                Flag = "fly",
                Default = false,
                Callback = function(Value)
                    print("Fly:", Value)
                end
            })

            FlySection:Slider({
                Name = "Fly Speed",
                Flag = "flyspeed",
                Min = 1,
                Max = 100,
                Default = 50,
                Callback = function(Value)
                    print("Fly Speed:", Value)
                end
            })
        end

        -- Tab Four: Misc
        do
            local MiscSection = TabFour:Section({Name = "misc", Side = 1})
            local ConfigSection = TabFour:Section({Name = "config", Side = 2})

            MiscSection:Button({
                Name = "Anti-AFK",
                Callback = function()
                    print("Anti-AFK enabled")
                end
            })

            MiscSection:Toggle({
                Name = "Auto Farm",
                Flag = "autofarm",
                Default = false,
                Callback = function(Value)
                    print("Auto Farm:", Value)
                end
            })

            ConfigSection:Button({
                Name = "Save Config",
                Callback = function()
                    print("Config saved")
                    Library:Notification("Config Saved", "Your settings have been saved!", 3, Color3.fromRGB(0, 255, 0))
                end
            })

            ConfigSection:Button({
                Name = "Load Config",
                Callback = function()
                    print("Config loaded")
                    Library:Notification("Config Loaded", "Settings restored!", 3, Color3.fromRGB(0, 255, 0))
                end
            })
        end
    end

    -- Watermark
    local Watermark = Window:Watermark({
        Name = "Premium Hub | v1.0", 
        Logo = "rbxassetid://77749228793011"
    }) 
    
    Watermark:AddItem("rbxassetid://79077177539456", LocalPlayer.Name)
    
    local FrameTimer = tick()
    local FPS = 60
    local FrameCount = 0

    local FPSText, FPSTextHolder = Watermark:AddItem("rbxassetid://81108100527616", "FPS: " .. FPS)

    Library:Connect(RunService.RenderStepped, function()
        FrameCount += 1
        if tick() - FrameTimer >= 1 then
            FPS = FrameCount
            FrameCount = 0
            FrameTimer = tick()
        end
        FPSText.Instance.Text = "FPS: " .. FPS
    end)

    -- Notificación de bienvenida
    Library:Notification("Welcome", "Premium Hub loaded successfully!", 5, Color3.fromRGB(0, 255, 0))
end

-- Iniciar Arqel
Arqel:Launch()
