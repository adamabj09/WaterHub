-- ============================================
-- WATER HUB | MM2 - By: AdamABJ
-- ============================================

local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
if not WindUI then 
    warn("Error cargando WindUI") 
    return 
end

local Window = WindUI:CreateWindow({
    Title = "Water Hub | MM2",
    Author = "By: AdamABJ",
    Icon = "rbxassetid://10734950309",
    Theme = "Dark",
    Transparent = true,
    ToggleKey = Enum.KeyCode.RightShift,
})

-- Variables
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
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
local Movement = Window:Tab({Title = "Movement"})
local Render = Window:Tab({Title = "Render"})
local Teleport = Window:Tab({Title = "Teleport"})
local Murderer = Window:Tab({Title = "Murderer"})

-- MOVEMENT
Movement:Section({Title = "Movement"})

Movement:Slider({Title = "WalkSpeed", Min = 16, Max = 500, Default = 16, Callback = function(v) humanoid.WalkSpeed = v end})
Movement:Slider({Title = "JumpPower", Min = 50, Max = 500, Default = 50, Callback = function(v) humanoid.JumpPower = v end})
Movement:Slider({Title = "FOV", Min = 50, Max = 120, Default = 70, Callback = function(v) Workspace.CurrentCamera.FieldOfView = v end})

Movement:Button({Title = "Infinite Jump", Callback = function()
    UserInputService.JumpRequest:Connect(function() humanoid:ChangeState("Jumping") end)
    WindUI:Notify({Title = "Infinite Jump", Content = "Activado"})
end})

-- RENDER
Render:Section({Title = "ESP"})

Render:Toggle({Title = "Murderer ESP", Callback = function(v) print("Murderer ESP:", v) end})
Render:Toggle({Title = "Sheriff ESP", Callback = function(v) print("Sheriff ESP:", v) end})
Render:Toggle({Title = "Show Names", Callback = function(v)
    game.StarterPlayer.NameDisplayDistance = v and 100 or 0
end})

-- TELEPORT
Teleport:Section({Title = "Teleports"})

local tpName = ""
Teleport:Textbox({Title = "Player Name", PlaceholderText = "Nombre...", Callback = function(t) tpName = t end})
Teleport:Button({Title = "Teleport to Player", Callback = function()
    if tpName and Players:FindFirstChild(tpName) then
        root.CFrame = Players[tpName].Character.HumanoidRootPart.CFrame
    end
end})

Teleport:Button({Title = "Teleport to Lobby", Callback = function() root.CFrame = CFrame.new(-108.5, 145, 0.6) end})
Teleport:Button({Title = "Teleport to Map", Callback = function() print("TP Map") end})
Teleport:Button({Title = "Teleport to Murderer", Callback = function() print("TP Murderer") end})
Teleport:Button({Title = "Teleport to Sheriff", Callback = function() print("TP Sheriff") end})

-- MURDERER
Murderer:Button({Title = "Grab Gun", Callback = function()
    if Workspace:FindFirstChild("GunDrop") then
        local old = root.CFrame
        root.CFrame = Workspace.GunDrop.CFrame
        task.wait(0.3)
        root.CFrame = old
    end
end})

Murderer:Button({Title = "Kill All (Murderer)", Callback = function()
    WindUI:Notify({Title = "Kill All", Content = "En desarrollo..."})
end})

print("💧 Water Hub | MM2 cargado correctamente - By: AdamABJ")