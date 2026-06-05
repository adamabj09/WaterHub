-- MM2 WindUI Optimizado - Sin FOV, Notificaciones Controladas, Funciones Reparadas
-- Compatible con: Synapse X, KRNL, Fluxus, Electron, Script-Ware

-- ============ SERVICIOS Y VARIABLES ============
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ============ VARIABLES DE ESTADO ============
local ESP = {
    Enabled = false,
    Murderer = false,
    Sheriff = false,
    Innocent = false,
    Highlights = {}
}

local Combat = {
    SilentAim = false,
    AutoAttack = false,
    TargetMurderer = false,
    HitboxExtender = false,
    HitboxSize = 10
}

local Movement = {
    Speed = false,
    SpeedValue = 50,
    Noclip = false,
    InfiniteJump = false,
    JumpPower = 50
}

local Visuals = {
    XRay = false,
    Fullbright = false,
    RemoveFog = false
}

local AutoFarm = {
    Enabled = false,
    CollectCoins = false,
    AutoShoot = false
}

-- ============ SISTEMA DE NOTIFICACIONES CON THROTTLING ============
local NotificationSystem = {
    LastNotification = {},
    Cooldown = 3, -- segundos entre notificaciones del mismo tipo
    Queue = {},
    Processing = false
}

local function CanNotify(notificationType)
    local lastTime = NotificationSystem.LastNotification[notificationType] or 0
    local currentTime = tick()
    if currentTime - lastTime >= NotificationSystem.Cooldown then
        NotificationSystem.LastNotification[notificationType] = currentTime
        return true
    end
    return false
end

local function SendNotification(title, message, duration, notificationType)
    notificationType = notificationType or "general"
    duration = duration or 3
    
    if not CanNotify(notificationType) then return end
    
    -- Usar el sistema de notificaciones de WindUI si está disponible
    if WindUI and WindUI.Notify then
        WindUI.Notify({
            Title = title,
            Content = message,
            Duration = duration
        })
    else
        -- Fallback a Roblox notifications
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = duration
        })
    end
end

-- ============ CARGAR WINDUI ============
local WindUIPath = "https://raw.githubusercontent.com/FoxyFletch/WindUI/main/dist/main.lua"
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet(WindUIPath))()
end)

if not success then
    -- Intentar URL alternativo
    success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/BloodBorneNeko/WindUI/main/dist/main.lua"))()
    end)
end

if not success then
    error("No se pudo cargar WindUI")
end

-- ============ FUNCIONES UTILITARIAS ============
local function GetRole(player)
    if not player or not player.Character then return "Unknown" end
    
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    -- Verificar en el personaje
    for _, item in pairs(character:GetDescendants()) do
        if item.Name == "Knife" or item.Name:lower():find("knife") then
            return "Murderer"
        elseif item.Name == "Gun" or item.Name:lower():find("gun") then
            return "Sheriff"
        end
    end
    
    -- Verificar en mochila
    if backpack then
        for _, item in pairs(backpack:GetDescendants()) do
            if item.Name == "Knife" or item.Name:lower():find("knife") then
                return "Murderer"
            elseif item.Name == "Gun" or item.Name:lower():find("gun") then
                return "Sheriff"
            end
        end
    end
    
    return "Innocent"
end

local function GetPlayerByRole(role)
    for _, player in pairs(Players:GetPlayers()) do
        if GetRole(player) == role then
            return player
        end
    end
    return nil
end

local function GetMurderer()
    return GetPlayerByRole("Murderer")
end

local function GetSheriff()
    return GetPlayerByRole("Sheriff")
end

local function IsAlive(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function GetHumanoidRootPart(player)
    if not player or not player.Character then return nil end
    return player.Character:FindFirstChild("HumanoidRootPart")
end

-- ============ SISTEMA ESP CON HIGHLIGHTS ============
local function CreateESP(player)
    if not player or not player.Character then return end
    if ESP.Highlights[player] then return end
    
    local character = player.Character
    local highlight = Instance.new("Highlight")
    
    local role = GetRole(player)
    local fillColor, outlineColor
    
    if role == "Murderer" then
        fillColor = Color3.fromRGB(255, 0, 0)
        outlineColor = Color3.fromRGB(150, 0, 0)
    elseif role == "Sheriff" then
        fillColor = Color3.fromRGB(0, 100, 255)
        outlineColor = Color3.fromRGB(0, 50, 150)
    else
        fillColor = Color3.fromRGB(0, 255, 0)
        outlineColor = Color3.fromRGB(0, 150, 0)
    end
    
    highlight.FillColor = fillColor
    highlight.OutlineColor = outlineColor
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = character
    
    ESP.Highlights[player] = {
        Highlight = highlight,
        Role = role,
        Player = player
    }
end

local function RemoveESP(player)
    if ESP.Highlights[player] then
        if ESP.Highlights[player].Highlight then
            ESP.Highlights[player].Highlight:Destroy()
        end
        ESP.Highlights[player] = nil
    end
end

local function ClearESP()
    for player, data in pairs(ESP.Highlights) do
        if data.Highlight then
            data.Highlight:Destroy()
        end
    end
    ESP.Highlights = {}
end

local function UpdateESP()
    if not ESP.Enabled then
        ClearESP()
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) then
            local role = GetRole(player)
            local shouldShow = false
            
            if role == "Murderer" and ESP.Murderer then
                shouldShow = true
            elseif role == "Sheriff" and ESP.Sheriff then
                shouldShow = true
            elseif role == "Innocent" and ESP.Innocent then
                shouldShow = true
            end
            
            if shouldShow then
                if not ESP.Highlights[player] or ESP.Highlights[player].Role ~= role then
                    RemoveESP(player)
                    CreateESP(player)
                end
            else
                RemoveESP(player)
            end
        else
            RemoveESP(player)
        end
    end
end

-- ============ COMBAT SYSTEM ============
local function GetClosestPlayer(maxDistance)
    maxDistance = maxDistance or 100
    local closest = nil
    local shortestDistance = maxDistance
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) then
            local targetPart = GetHumanoidRootPart(player)
            local localPart = GetHumanoidRootPart(LocalPlayer)
            
            if targetPart and localPart then
                local distance = (targetPart.Position - localPart.Position).Magnitude
                if distance < shortestDistance then
                    -- Verificar si es murderer cuando TargetMurderer está activado
                    if Combat.TargetMurderer then
                        if GetRole(player) == "Murderer" then
                            closest = player
                            shortestDistance = distance
                        end
                    else
                        closest = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    
    return closest
end

local function SilentAim()
    if not Combat.SilentAim then return end
    if not IsAlive(LocalPlayer) then return end
    
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local target = GetClosestPlayer(150)
    if not target or not IsAlive(target) then return end
    
    local targetPart = target.Character:FindFirstChild("Head") or target.Character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end
    
    -- Simular aim silencioso
    local args = {
        [1] = targetPart.Position,
        [2] = targetPart
    }
    
    -- Intentar disparar
    pcall(function()
        if tool:FindFirstChild("Shoot") then
            tool.Shoot:FireServer(unpack(args))
        elseif tool:FindFirstChild("Fire") then
            tool.Fire:FireServer(unpack(args))
        end
    end)
end

local function AutoAttack()
    if not Combat.AutoAttack then return end
    if not IsAlive(LocalPlayer) then return end
    
    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local target = GetClosestPlayer(Combat.HitboxSize)
    if not target then return end
    
    -- Auto ataque con cooldown
    pcall(function()
        if tool:FindFirstChild("Attack") then
            tool.Attack:FireServer()
        elseif tool:FindFirstChild("Stab") then
            tool.Stab:FireServer()
        elseif tool:FindFirstChild("Slash") then
            tool.Slash:FireServer()
        end
    end)
end

-- ============ HITBOX EXTENDER ============
local function UpdateHitboxes()
    if not Combat.HitboxExtender then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and IsAlive(player) then
            local hrp = GetHumanoidRootPart(player)
            if hrp then
                hrp.Size = Vector3.new(Combat.HitboxSize, Combat.HitboxSize, Combat.HitboxSize)
                hrp.Transparency = 0.9
                hrp.CanCollide = false
            end
        end
    end
end

local function ResetHitboxes()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
            end
        end
    end
end

-- ============ MOVEMENT ============
local function SetupMovement()
    -- Speed
    local function UpdateSpeed()
        if not IsAlive(LocalPlayer) then return end
        local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            if Movement.Speed then
                humanoid.WalkSpeed = Movement.SpeedValue
            else
                humanoid.WalkSpeed = 16
            end
        end
    end
    
    -- Noclip
    local function UpdateNoclip()
        if not IsAlive(LocalPlayer) then return end
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not Movement.Noclip
            end
        end
    end
    
    -- Infinite Jump
    local infiniteJumpConnection
    if Movement.InfiniteJump then
        infiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            if IsAlive(LocalPlayer) then
                local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    elseif infiniteJumpConnection then
        infiniteJumpConnection:Disconnect()
    end
    
    RunService.RenderStepped:Connect(function()
        UpdateSpeed()
        UpdateNoclip()
    end)
end

-- ============ VISUALS ============
local function UpdateVisuals()
    -- Fullbright
    if Visuals.Fullbright then
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        Lighting.Brightness = 1
        Lighting.GlobalShadows = true
        Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    end
    
    -- Remove Fog
    if Visuals.RemoveFog then
        Lighting.FogStart = 0
        Lighting.FogEnd = 100000
        Lighting.FogColor = Color3.fromRGB(255, 255, 255)
    end
end

-- X-Ray
local function UpdateXRay()
    for _, part in pairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not part:IsDescendantOf(LocalPlayer.Character) then
            if Visuals.XRay then
                if part.Transparency < 1 then
                    part:SetAttribute("OriginalTransparency", part.Transparency)
                    part.Transparency = 0.8
                end
            else
                local original = part:GetAttribute("OriginalTransparency")
                if original then
                    part.Transparency = original
                    part:SetAttribute("OriginalTransparency", nil)
                end
            end
        end
    end
end

-- ============ AUTO FARM ============
local function GetCoins()
    local coins = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("coin") and obj:IsA("BasePart") then
            table.insert(coins, obj)
        end
    end
    return coins
end

local function CollectCoins()
    if not AutoFarm.CollectCoins then return end
    if not IsAlive(LocalPlayer) then return end
    
    local coins = GetCoins()
    local hrp = GetHumanoidRootPart(LocalPlayer)
    if not hrp then return end
    
    for _, coin in pairs(coins) do
        if coin and coin.Parent then
            local distance = (coin.Position - hrp.Position).Magnitude
            if distance < 50 then
                firetouchinterest(hrp, coin, 0)
                firetouchinterest(hrp, coin, 1)
            end
        end
    end
end

-- ============ TELEPORTS ============
local TeleportLocations = {
    ["Lobby"] = CFrame.new(0, 100, 0),
    ["Map Center"] = CFrame.new(0, 50, 0),
    ["Gun Drop"] = CFrame.new(0, 50, 50),
    ["Safe Spot"] = CFrame.new(0, 200, 0)
}

local function TeleportTo(cframe)
    local hrp = GetHumanoidRootPart(LocalPlayer)
    if hrp then
        hrp.CFrame = cframe
        SendNotification("Teleport", "Teletransportado exitosamente", 2, "teleport")
    end
end

-- ============ CREAR UI ============
local Window = WindUI:CreateWindow({
    Title = "MM2 Premium",
    Icon = "rbxassetid://7733965386",
    Author = "Optimized",
    Folder = "MM2Script",
    Size = UDim2.fromOffset(580, 420),
    Transparent = true,
    Theme = "Dark"
})

-- TABS
local PlayerTab = Window:CreateTab({
    Title = "Player",
    Icon = "user"
})

local VisualsTab = Window:CreateTab({
    Title = "Visuals",
    Icon = "eye"
})

local CombatTab = Window:CreateTab({
    Title = "Combat",
    Icon = "sword"
})

local TeleportTab = Window:CreateTab({
    Title = "Teleports",
    Icon = "map-pin"
})

local MiscTab = Window:CreateTab({
    Title = "Misc",
    Icon = "settings"
})

-- ============ PLAYER TAB ============
PlayerTab:CreateSection("Movement")

PlayerTab:CreateToggle({
    Name = "Speed",
    CurrentValue = false,
    Callback = function(value)
        Movement.Speed = value
        SendNotification("Speed", value and "Activado" or "Desactivado", 2, "speed")
    end
})

PlayerTab:CreateSlider({
    Name = "Speed Value",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(value)
        Movement.SpeedValue = value
    end
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(value)
        Movement.Noclip = value
        SendNotification("Noclip", value and "Activado" or "Desactivado", 2, "noclip")
    end
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(value)
        Movement.InfiniteJump = value
        SendNotification("Infinite Jump", value and "Activado" or "Desactivado", 2, "jump")
    end
})

-- ============ VISUALS TAB ============
VisualsTab:CreateSection("ESP")

VisualsTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Callback = function(value)
        ESP.Enabled = value
        if not value then ClearESP() end
        SendNotification("ESP", value and "Activado" or "Desactivado", 2, "esp")
    end
})

VisualsTab:CreateToggle({
    Name = "Show Murderer",
    CurrentValue = true,
    Callback = function(value)
        ESP.Murderer = value
    end
})

VisualsTab:CreateToggle({
    Name = "Show Sheriff",
    CurrentValue = true,
    Callback = function(value)
        ESP.Sheriff = value
    end
})

VisualsTab:CreateToggle({
    Name = "Show Innocent",
    CurrentValue = false,
    Callback = function(value)
        ESP.Innocent = value
    end
})

VisualsTab:CreateSection("World")

VisualsTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(value)
        Visuals.Fullbright = value
        UpdateVisuals()
        SendNotification("Fullbright", value and "Activado" or "Desactivado", 2, "visual")
    end
})

VisualsTab:CreateToggle({
    Name = "X-Ray",
    CurrentValue = false,
    Callback = function(value)
        Visuals.XRay = value
        UpdateXRay()
        SendNotification("X-Ray", value and "Activado" or "Desactivado", 2, "visual")
    end
})

VisualsTab:CreateToggle({
    Name = "Remove Fog",
    CurrentValue = false,
    Callback = function(value)
        Visuals.RemoveFog = value
        UpdateVisuals()
    end
})

-- ============ COMBAT TAB ============
CombatTab:CreateSection("Aim")

CombatTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Callback = function(value)
        Combat.SilentAim = value
        SendNotification("Silent Aim", value and "Activado" or "Desactivado", 2, "combat")
    end
})

CombatTab:CreateToggle({
    Name = "Auto Attack",
    CurrentValue = false,
    Callback = function(value)
        Combat.AutoAttack = value
        SendNotification("Auto Attack", value and "Activado" or "Desactivado", 2, "combat")
    end
})

CombatTab:CreateToggle({
    Name = "Target Murderer Only",
    CurrentValue = false,
    Callback = function(value)
        Combat.TargetMurderer = value
    end
})

CombatTab:CreateSection("Hitbox")

CombatTab:CreateToggle({
    Name = "Hitbox Extender",
    CurrentValue = false,
    Callback = function(value)
        Combat.HitboxExtender = value
        if not value then ResetHitboxes() end
        SendNotification("Hitbox", value and "Activado" or "Desactivado", 2, "combat")
    end
})

CombatTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {2, 50},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(value)
        Combat.HitboxSize = value
    end
})

-- ============ TELEPORT TAB ============
TeleportTab:CreateSection("Locations")

for name, cframe in pairs(TeleportLocations) do
    TeleportTab:CreateButton({
        Name = "Teleport to " .. name,
        Callback = function()
            TeleportTo(cframe)
        end
    })
end

TeleportTab:CreateSection("Players")

TeleportTab:CreateButton({
    Name = "Teleport to Murderer",
    Callback = function()
        local murderer = GetMurderer()
        if murderer and IsAlive(murderer) then
            local hrp = GetHumanoidRootPart(murderer)
            if hrp then
                TeleportTo(hrp.CFrame + Vector3.new(0, 5, 0))
            end
        else
            SendNotification("Error", "No se encontró asesino", 2, "error")
        end
    end
})

TeleportTab:CreateButton({
    Name = "Teleport to Sheriff",
    Callback = function()
        local sheriff = GetSheriff()
        if sheriff and IsAlive(sheriff) then
            local hrp = GetHumanoidRootPart(sheriff)
            if hrp then
                TeleportTo(hrp.CFrame + Vector3.new(0, 5, 0))
            end
        else
            SendNotification("Error", "No se encontró sheriff", 2, "error")
        end
    end
})

-- ============ MISC TAB ============
MiscTab:CreateSection("Auto Farm")

MiscTab:CreateToggle({
    Name = "Auto Collect Coins",
    CurrentValue = false,
    Callback = function(value)
        AutoFarm.CollectCoins = value
        SendNotification("Auto Farm", value and "Activado" or "Desactivado", 2, "farm")
    end
})

MiscTab:CreateSection("Info")

MiscTab:CreateButton({
    Name = "Check Roles",
    Callback = function()
        local murderer = GetMurderer()
        local sheriff = GetSheriff()
        
        local msg = ""
        if murderer then
            msg = msg .. "Murderer: " .. murderer.Name .. "\n"
        else
            msg = msg .. "Murderer: No encontrado\n"
        end
        
        if sheriff then
            msg = msg .. "Sheriff: " .. sheriff.Name
        else
            msg = msg .. "Sheriff: No encontrado"
        end
        
        SendNotification("Roles Actuales", msg, 5, "info")
    end
})

MiscTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Window:Destroy()
    end
})

-- ============ LOOPS PRINCIPALES ============
SetupMovement()

RunService.RenderStepped:Connect(function()
    -- ESP
    UpdateESP()
    
    -- Combat
    SilentAim()
    AutoAttack()
    UpdateHitboxes()
    
    -- Farm
    CollectCoins()
end)

-- Limpiar al cerrar
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "MM2Premium" then
        ClearESP()
        ResetHitboxes()
    end
end)

-- Notificación inicial
SendNotification("MM2 Script", "Script cargado correctamente", 3, "init")
