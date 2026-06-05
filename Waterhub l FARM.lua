-- ============================================
-- CARGAR WINDUI
-- ============================================
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if not success or not WindUI then
    warn("Error cargando WindUI. Revisa la URL o tu conexión.")
    return
end

-- ============================================
-- CREAR VENTANA PRINCIPAL
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | MM2",
    Author = "By: AdamABJ",
    Icon = "rbxassetid://120258375748753",
    Theme = "Dark",
    Transparent = true,
    ToggleKey = Enum.KeyCode.RightShift,
    Position = "Center",
    Size = UDim2.new(0, 550, 0, 400),
    Draggable = true,
    Resizable = false
})

-- ============================================
-- VARIABLES
-- ============================================
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local cam = game:GetService("Workspace").Camera
local Mouse = player:GetMouse()

-- Variables de vuelo
local flying = false
local speedfly = 1
local CONTROL = {F = 0, B = 0, L = 0, R = 0}
local lCONTROL = {F = 0, B = 0, L = 0, R = 0}
local SPEED = 0

-- Actualizar character al morir
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
end)

-- ============================================
-- PESTAÑAS Y SECCIONES
-- ============================================
local function crearSeccionMovimiento(Window)
    local MovementTab = Window:NewTab("Movement")
    local SpeedSection = MovementTab:NewSection("Speed")

    SpeedSection:NewSlider({
        Name = "Walk Speed",
        Min = 0,
        Max = 500,
        Default = 16,
        Step = 2,
        Callback = function(Value)
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.WalkSpeed = Value
            end
        end
    })
    -- Otros elementos se pueden añadir siguiendo la lógica del script.
end

local function crearSeccionRender(Window)
    local RenderTab = Window:NewTab("Render")
    local ESPSection = RenderTab:NewSection("ESP")
    ESPSection:NewToggle({
        Name = "Murderer ESP",
        Default = false,
        Callback = function(Value)
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= player and v.Character then
                    local backpack = v.Character:FindFirstChild("Backpack")
                    if backpack and backpack:FindFirstChild("Knife") then
                        local ESP = v.Character:FindFirstChild("ESP") or Instance.new("Highlight")
                        ESP.Name = "ESP"
                        ESP.Parent = v.Character
                        ESP.FillColor = Color3.fromRGB(255, 0, 0)
                        ESP.OutlineColor = Color3.fromRGB(255, 255, 255)
                        ESP.FillTransparency = 0.3
                        ESP.OutlineTransparency = 0
                        ESP.Enabled = Value
                    end
                end
            end
        end
    })
    -- Puedes completar esta función con más características de renderizado.
end

-- ============================================
-- CREAR TODAS LAS SECCIONES
-- ============================================
crearSeccionMovimiento(Window)
crearSeccionRender(Window)

-- ============================================
-- NOTIFICACIÓN DE CARGA
-- ============================================
WindUI:Notification("Water Hub", "MM2 script loaded successfully!", 5)