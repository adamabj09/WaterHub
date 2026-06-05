--[[
    WATER HUB | Murder Mystery 2 - ULTIMATE
    Features: ESP, Silent Aim, Kill All, Auto Farm, Teleports, X-Ray, NoClip, Speed, Hitbox Extender
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
local CoreGui = game:GetService("CoreGui")

-- ============================================
-- WINDUI
-- ============================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

if not WindUI then
    warn("Error cargando WindUI")
    return
end

-- ============================================
-- VARIABLES
-- ============================================
local Features = {
    -- ESP
    ESPHighlight = false,
    ESPGun = false,
    ESPCoins = false,
    
    -- COMBAT
    SilentAim = false,
    Prediction = 0.165,
    KillAll = false,
    HitboxExtender = false,
    HitboxSize = 10,
    HitboxAngle = 60,
    
    -- MOVEMENT
    WalkSpeed = false,
    SpeedValue = 30,
    NoClip = false,
    InfiniteJump = false,
    
    -- AUTO
    AutoFarm = false,
    AutoGrabGun = false,
    
    -- TELEPORT
    TPToMurderer = false,
    TPToSheriff = false,
    
    -- WORLD
    XRay = false,
    XRayTransparency = 0.5,
    
    -- MISC
    AntiAFK = false
}

-- Roles
local Roles = {
    Murderer = nil,
    Sheriff = nil,
    Hero = nil
}

local ESPObjects = {}
local NoClipConnection = nil

-- ============================================
-- FUNCIONES UTILIDAD
-- ============================================
local function Notify(title, message)
    pcall(function()
        WindUI:Notify({Title = title, Content = message, Duration = 3})
    end)
end

local function GetRole(player)
    if not player.Character then return "Unknown" end
    if player.Character:FindFirstChild("Knife") then return "Murderer" end
    if player.Character:FindFirstChild("Gun") then return "Sheriff" end
    if player.Character:FindFirstChild("Hero") then return "Hero" end
    return "Innocent"
end

local function TeleportTo(cf)
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character:PivotTo(cf + Vector3.new(0, 3, 0))
    end
end

-- ============================================
-- ESP SYSTEM (HIGHLIGHTS)
-- ============================================
local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local highlight = Instance.new("Highlight")
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    ESPObjects[player] = highlight
    
    local function update()
        local role = GetRole(player)
        if role == "Murderer" then
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(150, 0, 0)
        elseif role == "Sheriff" then
            highlight.FillColor = Color3.fromRGB(0, 100, 255)
            highlight.OutlineColor = Color3.fromRGB(0, 50, 150)
        elseif role == "Hero" then
            highlight.FillColor = Color3.fromRGB(255, 255, 0)
            highlight.OutlineColor = Color3.fromRGB(150, 150, 0)
        else
            highlight.FillColor = Color3.fromRGB(255, 255, 255)
            highlight.OutlineColor = Color3.fromRGB(100, 100, 100)
        end
    end
    
    local function onChar(char)
        if char then
            highlight.Parent = char
            update()
        end
    end
    
    player.CharacterAdded:Connect(onChar)
    if player.Character then
        onChar(player.Character)
    end
    
    -- Gun ESP
    local gunBillboard = nil
    if Features.ESPGun then
        local gun = Workspace:FindFirstChild("GunDrop")
        if gun then
            gunBillboard = Instance.new("BillboardGui")
            gunBillboard.Size = UDim2.new(0, 100, 0, 50)
            gunBillboard.AlwaysOnTop = true
            gunBillboard.StudsOffset = Vector3.new(0, 2, 0)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Text = "🔫 GUN"
            label.TextColor3 = Color3.fromRGB(255, 215, 0)
            label.TextSize = 20
            label.Font = Enum.Font.GothamBold
            label.Parent = gunBillboard
            
            gunBillboard.Adornee = gun
            gunBillboard.Parent = CoreGui
        end
    end
    
    -- Cleanup
    player.CharacterRemoving:Connect(function()
        highlight.Parent = nil
        if gunBillboard then gunBillboard:Destroy() end
    end)
end

-- ============================================
-- SILENT AIM (CON PREDICCIÓN)
-- ============================================
local Aiming = loadstring(game:HttpGet("https://raw.githubusercontent.com/RapperDeluxe/scripts/main/silent%20aim%20module"))()
Aiming.TeamCheck(false)

local DaHoodSettings = {
    SilentAim = false,
    Prediction = 0.165
}

function Aiming.Check()
    if not (Aiming.Enabled and Aiming.Selected and Aiming.SelectedPart) then return false end
    local char = Aiming.Character(Aiming.Selected)
    if not char then return false end
    local humanoid = char:FindFirstChild("Humanoid")
    return humanoid and humanoid.Health > 0
end

local __index
__index = hookmetamethod(game, "__index", function(t, k)
    if t:IsA("Mouse") and (k == "Hit" or k == "Target") and DaHoodSettings.SilentAim and Aiming.Check() then
        local part = Aiming.SelectedPart
        local prediction = part.Velocity * DaHoodSettings.Prediction
        local hit = part.CFrame + prediction
        return k == "Hit" and hit or part
    end
    return __index(t, k)
end)

-- ============================================
-- COMBAT FUNCTIONS
-- ============================================
local function KillAll()
    if GetRole(LocalPlayer) ~= "Murderer" then
        Notify("Error", "You are not the Murderer!")
        return
    end
    
    local knife = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Knife")
    if not knife then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local distance = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            
            if distance <= Features.HitboxSize then
                firetouchinterest(hrp, knife:FindFirstChild("Handle") or knife, 0)
                firetouchinterest(hrp, knife:FindFirstChild("Handle") or knife, 1)
            end
        end
    end
end

local function HitboxExtender()
    if not Features.HitboxExtender then return end
    if GetRole(LocalPlayer) ~= "Murderer" then return end
    
    local knife = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Knife")
    if not knife then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            local distance = (hrp.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            
            if distance <= Features.HitboxSize then
                firetouchinterest(hrp, knife:FindFirstChild("Handle") or knife, 0)
            end
        end
    end
end

local function AutoGrabGun()
    local gun = Workspace:FindFirstChild("GunDrop")
    if gun then
        TeleportTo(gun.CFrame)
        Notify("Gun", "Teleported to gun!")
    else
        Notify("Gun", "No gun dropped")
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

local function NoClipLoop()
    if Features.NoClip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end

UserInputService.JumpRequest:Connect(function()
    if Features.InfiniteJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ============================================
-- AUTO FARM
-- ============================================
local function AutoFarmLoop()
    while Features.AutoFarm do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local coinContainer = Workspace:FindFirstChild("CoinContainer", true)
            if coinContainer then
                for _, coin in ipairs(coinContainer:GetChildren()) do
                    if coin.Name == "Coin_Server" and Features.AutoFarm then
                        char.HumanoidRootPart.CFrame = CFrame.new(coin.Position - Vector3.new(0, 2.5, 0))
                        task.wait(0.3)
                    end
                end
            end
        end
        task.wait(0.1)
    end
end

-- ============================================
-- X-RAY (OBSERVATION)
-- ============================================
local function XRay(state)
    if state then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
                obj.Transparency = Features.XRayTransparency
            end
        end
    else
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
                obj.Transparency = 0
            end
        end
    end
end

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
    Title = "Water Hub | MM2 Ultimate",
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

ESPTab:Section({ Title = "Player ESP", Desc = "Role highlights" })

ESPTab:Toggle({
    Title = "Player Highlights",
    Value = false,
    Callback = function(v)
        Features.ESPHighlight = v
        for _, obj in pairs(ESPObjects) do
            if typeof(obj) == "Instance" then
                obj.Enabled = v
            end
        end
    end,
})

ESPTab:Toggle({
    Title = "Gun ESP",
    Value = false,
    Callback = function(v)
        Features.ESPGun = v
    end,
})

ESPTab:Toggle({
    Title = "Coin ESP",
    Value = false,
    Callback = function(v)
        Features.ESPCoins = v
    end,
})

-- 2. COMBAT TAB
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "crosshair" })

CombatTab:Section({ Title = "Silent Aim", Desc = "Auto targeting" })

CombatTab:Toggle({
    Title = "Silent Aim",
    Value = false,
    Callback = function(v)
        Features.SilentAim = v
        DaHoodSettings.SilentAim = v
    end,
})

CombatTab:Slider({
    Title = "Prediction",
    Step = 0.001,
    Value = { Min = 0, Max = 0.5, Default = 0.165 },
    Callback = function(v)
        Features.Prediction = v
        DaHoodSettings.Prediction = v
    end,
})

CombatTab:Section({ Title = "Murderer", Desc = "Kill features" })

CombatTab:Toggle({
    Title = "Kill All",
    Value = false,
    Callback = function(v)
        Features.KillAll = v
        if v then
            task.spawn(function()
                while Features.KillAll do
                    KillAll()
                    task.wait(0.1)
                end
            end)
        end
    end,
})

CombatTab:Toggle({
    Title = "Hitbox Extender",
    Value = false,
    Callback = function(v)
        Features.HitboxExtender = v
        if v then
            task.spawn(function()
                while Features.HitboxExtender do
                    HitboxExtender()
                    task.wait(0.05)
                end
            end)
        end
    end,
})

CombatTab:Slider({
    Title = "Hitbox Size",
    Step = 1,
    Value = { Min = 5, Max = 30, Default = 10 },
    Callback = function(v)
        Features.HitboxSize = v
    end,
})

CombatTab:Section({ Title = "Sheriff", Desc = "Gun utilities" })

CombatTab:Button({
    Title = "Auto Grab Gun",
    Callback = AutoGrabGun
})

-- 3. MOVEMENT TAB
local MoveTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })

MoveTab:Section({ Title = "Speed" })

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

MoveTab:Section({ Title = "Physics" })

MoveTab:Toggle({
    Title = "NoClip",
    Value = false,
    Callback = function(v)
        Features.NoClip = v
    end,
})

MoveTab:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(v)
        Features.InfiniteJump = v
    end,
})

-- 4. AUTO TAB
local AutoTab = Window:Tab({ Title = "AUTO", Icon = "zap" })

AutoTab:Section({ Title = "Farming", Desc = "Auto collect" })

AutoTab:Toggle({
    Title = "Auto Farm Coins",
    Value = false,
    Callback = function(v)
        Features.AutoFarm = v
        if v then task.spawn(AutoFarmLoop) end
    end,
})

AutoTab:Section({ Title = "Gun", Desc = "Auto pickup" })

AutoTab:Toggle({
    Title = "Auto Grab Gun",
    Value = false,
    Callback = function(v)
        Features.AutoGrabGun = v
        if v then
            task.spawn(function()
                while Features.AutoGrabGun do
                    local gun = Workspace:FindFirstChild("GunDrop")
                    if gun then
                        AutoGrabGun()
                        task.wait(1)
                    end
                    task.wait(0.5)
                end
            end)
        end
    end,
})

-- 5. TELEPORT TAB
local TPTab = Window:Tab({ Title = "TELEPORT", Icon = "map-pin" })

TPTab:Section({ Title = "Players", Desc = "Teleport to roles" })

TPTab:Button({
    Title = "Teleport to Murderer",
    Callback = TPToMurderer
})

TPTab:Button({
    Title = "Teleport to Sheriff",
    Callback = TPToSheriff
})

TPTab:Section({ Title = "Items", Desc = "Teleport to items" })

TPTab:Button({
    Title = "Teleport to Gun",
    Callback = AutoGrabGun
})

-- 6. WORLD TAB
local WorldTab = Window:Tab({ Title = "WORLD", Icon = "eye" })

WorldTab:Section({ Title = "X-Ray", Desc = "See through walls" })

WorldTab:Toggle({
    Title = "X-Ray",
    Value = false,
    Callback = function(v)
        Features.XRay = v
        XRay(v)
    end,
})

WorldTab:Slider({
    Title = "Transparency",
    Step = 0.1,
    Value = { Min = 0, Max = 1, Default = 0.5 },
    Callback = function(v)
        Features.XRayTransparency = v
        if Features.XRay then XRay(true) end
    end,
})

-- 7. MISC TAB
local MiscTab = Window:Tab({ Title = "MISC", Icon = "settings" })

MiscTab:Button({
    Title = "Anti-AFK",
    Callback = function()
        AntiAFK()
        Notify("Misc", "Anti-AFK Enabled")
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

-- Update loops
RunService.RenderStepped:Connect(function()
    NoClipLoop()
end)

-- Role detection
ReplicatedStorage.Fade.OnClientEvent:Connect(function(data)
    for _, player in ipairs(Players:GetPlayers()) do
        local info = data[player.Name]
        if info then
            local role = typeof(info) == "table" and info.Role or "Unknown"
            if role == "Murderer" then Roles.Murderer = player end
            if role == "Sheriff" then Roles.Sheriff = player end
            if role == "Hero" then Roles.Hero = player end
        end
    end
end)

-- Gun drop notifier
Workspace.ChildAdded:Connect(function(child)
    if child.Name == "GunDrop" then
        Notify("Gun Dropped!", "The gun has spawned!")
    end
end)

CombatTab:Select()

print("Water Hub | MM2 Ultimate - Loaded Successfully")
print("Features: ESP, Silent Aim, Kill All, Auto Farm, X-Ray, NoClip, Speed")
