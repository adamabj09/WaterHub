--[[
    WATER HUB | Murder Mystery 2
    ESP | Teleports | Combat | Custom UI
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

-- ============================================
-- CARGAR WINDUI
-- ============================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

if not WindUI then
    warn("Error cargando WindUI")
    return
end

-- ============================================
-- VARIABLES Y CONFIGURACIÓN
-- ============================================
local Features = {
    -- ESP
    ESPBoxes = false,
    ESPNames = false,
    ESPDistance = false,
    ESPTracers = false,
    ESPHighlight = false,
    ESPColor = Color3.fromRGB(0, 150, 255),
    
    -- COMBAT
    SilentAim = false,
    KillAll = false,
    AutoGrabGun = false,
    
    -- MOVEMENT
    WalkSpeed = false,
    SpeedValue = 30,
    InfiniteJump = false,
    Noclip = false,
    
    -- TELEPORTS
    AutoTPGun = false,
    
    -- MISC
    Fullbright = false,
    AntiAFK = false
}

local ESPObjects = {}
local Roles = {
    Murderer = nil,
    Sheriff = nil,
    Innocent = {}
}

-- ============================================
-- FUNCIONES UTILIDAD
-- ============================================
local function Notify(title, message)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = message,
            Duration = 3
        })
    end)
end

local function GetRole(player)
    if not player.Character then return "Unknown" end
    if player.Character:FindFirstChild("Knife") then return "Murderer" end
    if player.Character:FindFirstChild("Gun") then return "Sheriff" end
    return "Innocent"
end

local function TeleportTo(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character:PivotTo(cf + Vector3.new(0, 3, 0))
    end
end

-- ============================================
-- SISTEMA ESP (MEJORADO)
-- ============================================
local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local esp = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        Highlight = nil
    }
    
    -- Box
    esp.Box.Thickness = 1
    esp.Box.Filled = false
    esp.Box.Visible = false
    
    -- Name
    esp.Name.Size = 13
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.Visible = false
    
    -- Distance
    esp.Distance.Size = 12
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.Visible = false
    
    -- Tracer
    esp.Tracer.Thickness = 1
    esp.Tracer.Visible = false
    
    ESPObjects[player] = esp
    
    -- Cleanup
    player.CharacterRemoving:Connect(function()
        if ESPObjects[player] then
            for _, obj in pairs(ESPObjects[player]) do
                if typeof(obj) == "table" and obj.Remove then
                    obj:Remove()
                elseif typeof(obj) == "Instance" then
                    obj:Destroy()
                end
            end
            ESPObjects[player] = nil
        end
    end)
end

local function UpdateESP()
    local camera = Workspace.CurrentCamera
    local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    myPos = myPos and myPos.Position or Vector3.new()
    
    for player, esp in pairs(ESPObjects) do
        local success = pcall(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local humanoid = char and char:FindFirstChild("Humanoid")
            
            if not hrp or not humanoid or humanoid.Health <= 0 then
                for _, obj in pairs(esp) do
                    if typeof(obj) == "table" then obj.Visible = false end
                end
                return
            end
            
            local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
            local distance = (myPos - hrp.Position).Magnitude
            
            if onScreen then
                local role = GetRole(player)
                local color = role == "Murderer" and Color3.fromRGB(255, 0, 0) or
                             role == "Sheriff" and Color3.fromRGB(0, 255, 0) or
                             Features.ESPColor
                
                -- Box
                if Features.ESPBoxes then
                    local size = math.clamp(2000 / pos.Z, 30, 150)
                    esp.Box.Size = Vector2.new(size, size * 1.5)
                    esp.Box.Position = Vector2.new(pos.X - size/2, pos.Y - size*0.75)
                    esp.Box.Color = color
                    esp.Box.Visible = true
                else
                    esp.Box.Visible = false
                end
                
                -- Name
                if Features.ESPNames then
                    esp.Name.Position = Vector2.new(pos.X, pos.Y - 40)
                    esp.Name.Text = player.Name .. " [" .. role .. "]"
                    esp.Name.Color = color
                    esp.Name.Visible = true
                else
                    esp.Name.Visible = false
                end
                
                -- Distance
                if Features.ESPDistance then
                    esp.Distance.Position = Vector2.new(pos.X, pos.Y + 20)
                    esp.Distance.Text = math.floor(distance) .. "m"
                    esp.Distance.Color = Color3.fromRGB(255, 255, 255)
                    esp.Distance.Visible = true
                else
                    esp.Distance.Visible = false
                end
                
                -- Tracer
                if Features.ESPTracers then
                    esp.Tracer.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
                    esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                    esp.Tracer.Color = color
                    esp.Tracer.Visible = true
                else
                    esp.Tracer.Visible = false
                end
                
                -- Highlight (Chams)
                if Features.ESPHighlight then
                    if not esp.Highlight or not esp.Highlight.Parent then
                        esp.Highlight = Instance.new("Highlight")
                        esp.Highlight.FillTransparency = 0.5
                        esp.Highlight.OutlineTransparency = 0
                        esp.Highlight.Parent = char
                    end
                    esp.Highlight.FillColor = color
                    esp.Highlight.OutlineColor = Color3.new(0, 0, 0)
                elseif esp.Highlight then
                    esp.Highlight:Destroy()
                    esp.Highlight = nil
                end
            else
                for _, obj in pairs(esp) do
                    if typeof(obj) == "table" then obj.Visible = false end
                end
            end
        end)
        
        if not success then
            for _, obj in pairs(esp) do
                if typeof(obj) == "table" then obj.Visible = false end
            end
        end
    end
end

-- ============================================
-- COMBAT FUNCTIONS
-- ============================================
local function KillAll()
    if GetRole(LocalPlayer) ~= "Murderer" then
        Notify("Error", "You are not the Murderer!")
        return
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local knife = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Knife")
            if knife then
                TeleportTo(player.Character.HumanoidRootPart.CFrame)
                task.wait(0.1)
            end
        end
    end
end

local function AutoGrabGun()
    local gun = Workspace:FindFirstChild("GunDrop")
    if gun then
        TeleportTo(gun.CFrame)
        Notify("Success", "Teleported to gun!")
    else
        Notify("Error", "Gun not dropped yet")
    end
end

-- ============================================
-- MOVEMENT
-- ============================================
local function WalkSpeedLoop()
    while Features.WalkSpeed do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = Features.SpeedValue end
        end
        task.wait(0.1)
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

local function NoclipLoop()
    if Features.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Features.InfiniteJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ============================================
-- TELEPORTS
-- ============================================
local function GetPlayerByTool(toolName)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild(toolName) then
            return player
        end
    end
    return nil
end

local function TPToMurderer()
    local murderer = GetPlayerByTool("Knife")
    if murderer and murderer.Character then
        TeleportTo(murderer.Character.HumanoidRootPart.CFrame)
        Notify("Teleport", "Teleported to Murderer!")
    else
        Notify("Error", "Murderer not found")
    end
end

local function TPToSheriff()
    local sheriff = GetPlayerByTool("Gun")
    if sheriff and sheriff.Character then
        TeleportTo(sheriff.Character.HumanoidRootPart.CFrame)
        Notify("Teleport", "Teleported to Sheriff!")
    else
        Notify("Error", "Sheriff not found")
    end
end

-- ============================================
-- MISC
-- ============================================
local function Fullbright(state)
    if state then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.FogEnd = 100000
    else
        Lighting.Ambient = Color3.new(0.5, 0.5, 0.5)
        Lighting.Brightness = 1
        Lighting.FogEnd = 1000
    end
end

local function AntiAFK()
    LocalPlayer.Idled:Connect(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
    end)
end

-- ============================================
-- UI (WINDUI)
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | MM2",
    Author = "By: AdamABJ",
    Icon = "skull",
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.F,
    OpenButton = {
        Title = "Open",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        Color = ColorSequence.new(Color3.fromRGB(0, 150, 255), Color3.fromRGB(0, 150, 255)),
    },
})

-- 1. ESP TAB
local ESPTab = Window:Tab({ Title = "ESP", Icon = "eye" })

ESPTab:Section({ Title = "Player ESP", Desc = "Visual indicators" })

ESPTab:Toggle({
    Title = "Boxes",
    Value = false,
    Callback = function(v)
        Features.ESPBoxes = v
    end,
})

ESPTab:Toggle({
    Title = "Names",
    Value = false,
    Callback = function(v)
        Features.ESPNames = v
    end,
})

ESPTab:Toggle({
    Title = "Distance",
    Value = false,
    Callback = function(v)
        Features.ESPDistance = v
    end,
})

ESPTab:Toggle({
    Title = "Tracers",
    Value = false,
    Callback = function(v)
        Features.ESPTracers = v
    end,
})

ESPTab:Toggle({
    Title = "Highlight (Chams)",
    Value = false,
    Callback = function(v)
        Features.ESPHighlight = v
    end,
})

ESPTab:Section({ Title = "Colors", Desc = "ESP Appearance" })

ESPTab:Button({
    Title = "Set Color (Blue)",
    Callback = function()
        Features.ESPColor = Color3.fromRGB(0, 150, 255)
        Notify("ESP", "Color set to Blue")
    end,
})

ESPTab:Button({
    Title = "Set Color (Red)",
    Callback = function()
        Features.ESPColor = Color3.fromRGB(255, 50, 50)
        Notify("ESP", "Color set to Red")
    end,
})

ESPTab:Button({
    Title = "Set Color (Green)",
    Callback = function()
        Features.ESPColor = Color3.fromRGB(50, 255, 50)
        Notify("ESP", "Color set to Green")
    end,
})

-- 2. COMBAT TAB
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "sword" })

CombatTab:Section({ Title = "Murderer", Desc = "Kill all players" })

CombatTab:Button({
    Title = "Kill All (Murderer Only)",
    Callback = function()
        KillAll()
    end,
})

CombatTab:Section({ Title = "Sheriff", Desc = "Gun utilities" })

CombatTab:Button({
    Title = "Auto Grab Gun",
    Callback = function()
        AutoGrabGun()
    end,
})

CombatTab:Toggle({
    Title = "Silent Aim",
    Value = false,
    Callback = function(v)
        Features.SilentAim = v
        Notify("Combat", "Silent Aim " .. (v and "Enabled" or "Disabled"))
    end,
})

-- 3. TELEPORTS TAB
local TPTab = Window:Tab({ Title = "TELEPORTS", Icon = "map-pin" })

TPTab:Section({ Title = "Players", Desc = "Teleport to roles" })

TPTab:Button({
    Title = "Teleport to Murderer",
    Callback = TPToMurderer,
})

TPTab:Button({
    Title = "Teleport to Sheriff",
    Callback = TPToSheriff,
})

TPTab:Section({ Title = "Items", Desc = "Teleport to items" })

TPTab:Button({
    Title = "Teleport to Gun",
    Callback = AutoGrabGun,
})

TPTab:Section({ Title = "Locations", Desc = "Map locations" })

TPTab:Button({
    Title = "Teleport to Lobby",
    Callback = function()
        local lobby = Workspace:FindFirstChild("Spawn") or Workspace:FindFirstChild("Lobby")
        if lobby then
            TeleportTo(lobby.CFrame)
        end
    end,
})

-- 4. MOVEMENT TAB
local MoveTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })

MoveTab:Section({ Title = "Speed", Desc = "Walk speed modifier" })

MoveTab:Toggle({
    Title = "Walk Speed",
    Value = false,
    Callback = function(v)
        Features.WalkSpeed = v
        if v then task.spawn(WalkSpeedLoop) end
    end,
})

MoveTab:Slider({
    Title = "Speed Value",
    Step = 5,
    Value = { Min = 16, Max = 100, Default = 30 },
    Callback = function(v)
        Features.SpeedValue = v
    end,
})

MoveTab:Section({ Title = "Physics", Desc = "Movement exploits" })

MoveTab:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(v)
        Features.InfiniteJump = v
    end,
})

MoveTab:Toggle({
    Title = "Noclip",
    Value = false,
    Callback = function(v)
        Features.Noclip = v
    end,
})

-- 5. MISC TAB
local MiscTab = Window:Tab({ Title = "MISC", Icon = "settings" })

MiscTab:Section({ Title = "Visual", Desc = "Visual modifications" })

MiscTab:Toggle({
    Title = "Fullbright",
    Value = false,
    Callback = function(v)
        Features.Fullbright = v
        Fullbright(v)
    end,
})

MiscTab:Section({ Title = "Utility", Desc = "Useful features" })

MiscTab:Button({
    Title = "Anti-AFK",
    Callback = function()
        AntiAFK()
        Notify("Misc", "Anti-AFK Enabled")
    end,
})

MiscTab:Button({
    Title = "Server Hop",
    Callback = function()
        local PlaceID = game.PlaceId
        local HttpService = game:GetService("HttpService")
        local TeleportService = game:GetService("TeleportService")
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100"))
        for _, server in ipairs(servers.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(PlaceID, server.id)
                return
            end
        end
    end,
})

-- ============================================
-- INICIALIZACIÓN
-- ============================================
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end)

-- Update ESP Loop
RunService.RenderStepped:Connect(function()
    UpdateESP()
    NoclipLoop()
end)

-- Auto-detect roles
task.spawn(function()
    while true do
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local role = GetRole(player)
                if role == "Murderer" then
                    Roles.Murderer = player
                elseif role == "Sheriff" then
                    Roles.Sheriff = player
                end
            end
        end
        task.wait(1)
    end
end)

-- Gun drop notifier
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "GunDrop" then
        Notify("Gun Dropped!", "The gun has spawned!")
    end
end)

ESPTab:Select()

print("Water Hub | MM2 Loaded Successfully")
print("Features: ESP, Teleports, Combat, Movement")
