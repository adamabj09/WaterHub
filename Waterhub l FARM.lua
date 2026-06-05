-- ============================================
-- WATER HUB | MM2 - By: AdamABJ
-- ============================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
if not WindUI then 
    warn("Error cargando WindUI") 
    return 
end

local Window = WindUI:CreateWindow({
    Title = "💧 Water Hub | MM2",
    Author = "By: AdamABJ",
    Icon = "rbxassetid://10734950309",
    Theme = "Dark",
    Transparent = true,
    ToggleKey = Enum.KeyCode.RightShift,
})

-- ============================================
-- VARIABLES GLOBALES
-- ============================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local root = character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(new)
    character = new
    humanoid = new:WaitForChild("Humanoid")
    root = new:WaitForChild("HumanoidRootPart")
end)

-- ============================================
-- TABS
-- ============================================
local Movement = Window:Tab({Title = "🚀 Movement", Icon = "rbxassetid://6031224621"})
local Render = Window:Tab({Title = "🎨 Render", Icon = "rbxassetid://6023426922"})
local Teleport = Window:Tab({Title = "📍 Teleport", Icon = "rbxassetid://6031075931"})
local Murderer = Window:Tab({Title = "🔪 Murderer", Icon = "rbxassetid://6031154874"})

-- ============================================
-- MOVEMENT TAB
-- ============================================
Movement:Section({Title = "⚡ Speed & Movement"})

Movement:Slider({
    Title = "👟 WalkSpeed",
    Min = 16,
    Max = 500,
    Default = 16,
    Callback = function(v)
        humanoid.WalkSpeed = v
    end
})

Movement:Slider({
    Title = "🎯 JumpPower",
    Min = 50,
    Max = 500,
    Default = 50,
    Callback = function(v)
        humanoid.JumpPower = v
    end
})

Movement:Slider({
    Title = "🎥 Field of View (FOV)",
    Min = 50,
    Max = 120,
    Default = 70,
    Callback = function(v)
        Workspace.CurrentCamera.FieldOfView = v
    end
})

Movement:Button({
    Title = "🔄 Infinite Jump",
    Callback = function()
        UserInputService.JumpRequest:Connect(function()
            humanoid:ChangeState("Jumping")
        end)
        WindUI:Notify({Title = "Infinite Jump", Content = "Activado.", Duration = 3})
    end
})

-- ============================================
-- RENDER TAB
-- ============================================
Render:Section({Title = "🕵 ESP & Highlights"})

Render:Toggle({
    Title = "🩸 Murderer ESP",
    Callback = function(v)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local backpack = player.Character:FindFirstChild("Backpack")
                if backpack and backpack:FindFirstChild("Knife") then
                    if v then
                        local esp = Instance.new("Highlight")
                        esp.Parent = player.Character
                        esp.FillColor = Color3.fromRGB(255, 0, 0)
                        esp.OutlineColor = Color3.fromRGB(255, 255, 255)
                        esp.Name = "MurdererHighlight"
                    else
                        local existingEsp = player.Character:FindFirstChild("MurdererHighlight")
                        if existingEsp then
                            existingEsp:Destroy()
                        end
                    end
                end
            end
        end
    end
})

Render:Toggle({
    Title = "🔵 Sheriff ESP",
    Callback = function(v)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local backpack = player.Character:FindFirstChild("Backpack")
                if backpack and backpack:FindFirstChild("Gun") then
                    if v then
                        local esp = Instance.new("Highlight")
                        esp.Parent = player.Character
                        esp.FillColor = Color3.fromRGB(0, 0, 255)
                        esp.OutlineColor = Color3.fromRGB(255, 255, 255)
                        esp.Name = "SheriffHighlight"
                    else
                        local existingEsp = player.Character:FindFirstChild("SheriffHighlight")
                        if existingEsp then
                            existingEsp:Destroy()
                        end
                    end
                end
            end
        end
    end
})

Render:Toggle({
    Title = "📛 Show Player Names",
    Callback = function(v)
        game.StarterPlayer.NameDisplayDistance = v and 100 or 0
    end
})

-- ============================================
-- TELEPORT TAB
-- ============================================
Teleport:Section({Title = "🚪 Quick Teleports"})

Teleport:Button({
    Title = "🏢 Teleport to Lobby",
    Callback = function()
        root.CFrame = CFrame.new(-108.5, 145, 0.6)
    end
})

Teleport:Button({
    Title = "🗺 Teleport to Map",
    Callback = function()
        for _, child in ipairs(Workspace:GetChildren()) do
            if child:FindFirstChild("Spawns") then
                root.CFrame = child.Spawns.Spawn.CFrame
                break
            end
        end
    end
})

-- ============================================
-- MURDERER TAB
-- ============================================
Murderer:Section({Title = "🔪 Murderer Abilities"})

Murderer:Button({
    Title = "🔫 Grab Gun",
    Callback = function()
        if Workspace:FindFirstChild("GunDrop") then
            local initialPosition = root.CFrame
            root.CFrame = Workspace.GunDrop.CFrame
            task.wait(0.3)
            root.CFrame = initialPosition
        end
    end
})

Murderer:Button({
    Title = "💥 Kill All",
    Callback = function()
        WindUI:Notify({Title = "Kill All", Content = "Función en desarrollo.", Duration = 3})
    end
})

-- ============================================
-- NOTIFICACIÓN DE CARGA
-- ============================================
WindUI:Notify({
    Title = "Water Hub",
    Content = "Script cargado correctamente. ¡Disfruta!",
    Duration = 5
})

print("💧 Water Hub | MM2 cargado correctamente - By: AdamABJ")