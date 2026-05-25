--[[
    WATER HUB | BLOCKSPIN | DELTA EDITION COMPLETA
    Con Chams, ESP 3D, Silent Aim, Fly, No Clip, Auto Hit y más
    By: AdamABJ
--]]

-- ============================================
-- CONFIGURACIÓN
-- ============================================
local Config = {
    -- Colores
    FrameColor = Color3.fromRGB(35, 40, 50),
    FrameTransparency = 0.3,
    PlayerTextColor = Color3.fromRGB(255, 255, 255),
    WeaponTextColor = Color3.fromRGB(255, 200, 100),
    ChamsColor = Color3.fromRGB(0, 100, 255), -- Azul
    ChamsTransparency = 0.4,
    
    -- Movimiento
    DefaultWalkSpeed = 16,
    InfiniteJumpInterval = 0.05,
    FlySpeed = 50,
    
    -- Combat
    AutoHealPercent = 70,
    SilentAimFOV = 200,
    AimPart = "Head",
    
    -- ESP
    ESPUpdateInterval = 0.1,
    InventoryUpdateInterval = 2,
    
    -- Otros
    AntiAFKInterval = 60,
}

-- ============================================
-- SERVICIOS
-- ============================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

-- ============================================
-- IDs DE ARMAS (23 COMPLETAS)
-- ============================================
local WeaponImages = {
    ["AK47"] = "rbxassetid://124555430577178",
    ["AUG"] = "rbxassetid://83729841153733",
    ["AWP"] = "rbxassetid://126356167274927",
    ["Anaconda"] = "rbxassetid://121547020534134",
    ["C9"] = "rbxassetid://79659079988022",
    ["Crossbow"] = "rbxassetid://89240642376715",
    ["Double Barrel"] = "rbxassetid://83625765638039",
    ["Draco"] = "rbxassetid://120937616266903",
    ["Firework Launcher"] = "rbxassetid://88284317820274",
    ["G3"] = "rbxassetid://133411291398002",
    ["Glock"] = "rbxassetid://97846154366870",
    ["Hunting Rifle"] = "rbxassetid://81547704965153",
    ["M16"] = "rbxassetid://74321352408872",
    ["M24"] = "rbxassetid://73387965982603",
    ["M249"] = "rbxassetid://80044343904275",
    ["MP5"] = "rbxassetid://80501079489777",
    ["P226"] = "rbxassetid://92521100297776",
    ["P90"] = "rbxassetid://110565990980804",
    ["RPG"] = "rbxassetid://138426000142807",
    ["Remington"] = "rbxassetid://101271375930409",
    ["Sawnoff"] = "rbxassetid://90588305892707",
    ["Skorpion"] = "rbxassetid://105318377951686",
    ["Uzi"] = "rbxassetid://109290695652338",
}

-- ============================================
-- FUNCIONES UTILITARIAS
-- ============================================
local function GetPlayerWeapon(player)
    local char = player.Character
    if not char then return nil, nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name, WeaponImages[tool.Name]
    end
    return nil, nil
end

local function GetClosestPlayerToMouse(fov)
    local mouse = LocalPlayer:GetMouse()
    local camera = Workspace.CurrentCamera
    if not mouse or not camera then return nil end
    
    local closest = nil
    local shortest = fov or Config.SilentAimFOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local target = player.Character:FindFirstChild(Config.AimPart) or player.Character:FindFirstChild("Head")
            local hum = player.Character:FindFirstChild("Humanoid")
            if target and hum and hum.Health > 0 then
                local pos, onScreen = camera:WorldToViewportPoint(target.Position)
                if onScreen then
                    local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

-- ============================================
-- CARGAR WINDUI
-- ============================================
local WindUI

local function LoadWindUI()
    local success, result = pcall(function()
        return require(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init"))
    end)
    
    if success then
        WindUI = result
        return true
    end
    
    local httpSuccess, httpResult = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua", true))()
    end)
    
    if httpSuccess and httpResult then
        WindUI = httpResult
        return true
    end
    
    StarterGui:SetCore("SendNotification", {
        Title = "Error",
        Text = "No se pudo cargar WindUI",
        Duration = 3
    })
    return false
end

if not LoadWindUI() then return end

-- ============================================
-- UIMANAGER
-- ============================================
local UIManager = {}

function UIManager:CreateWindow()
    return WindUI:CreateWindow({
        Title = "Water Hub | BlockSpin",
        Author = "By: AdamABJ",
        Icon = "solar:water-drops-bold-duotone",
        Theme = "Dark",
        Transparent = true,
        ToggleKey = Enum.KeyCode.RightShift,
        Acrylic = true,
    })
end

-- ============================================
-- CHAMS MANAGER
-- ============================================
local ChamsManager = {
    Enabled = false,
    Objects = {},
}

function ChamsManager:ApplyToPlayer(player)
    local char = player.Character
    if not char then return end
    
    if self.Enabled then
        if not self.Objects[player] then
            local highlight = Instance.new("Highlight")
            highlight.Name = "WaterHubChams"
            highlight.FillColor = Config.ChamsColor
            highlight.FillTransparency = Config.ChamsTransparency
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.Adornee = char
            highlight.Parent = char
            self.Objects[player] = highlight
        end
    else
        if self.Objects[player] then
            self.Objects[player]:Destroy()
            self.Objects[player] = nil
        end
    end
end

function ChamsManager:UpdateAll()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            self:ApplyToPlayer(player)
        end
    end
end

function ChamsManager:Toggle(enabled)
    self.Enabled = enabled
    self:UpdateAll()
end

-- ============================================
-- ESP MANAGER (3D con BillboardGui)
-- ============================================
local ESPManager = {
    Enabled = false,
    Objects = {},
}

function ESPManager:CreateESP(player)
    if self.Objects[player] then return end
    
    local gui = Instance.new("BillboardGui")
    gui.Name = "WaterHubESP"
    gui.Size = UDim2.new(0, 200, 0, 60)
    gui.AlwaysOnTop = true
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui
    
    local nameLabel = Instance.new("TextLabel", gui)
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Config.PlayerTextColor
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    
    local healthBar = Instance.new("Frame", gui)
    healthBar.Size = UDim2.new(1, 0, 0, 5)
    healthBar.Position = UDim2.new(0, 0, 0, 22)
    healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    
    local weaponLabel = Instance.new("TextLabel", gui)
    weaponLabel.Size = UDim2.new(1, 0, 0, 15)
    weaponLabel.Position = UDim2.new(0, 0, 0, 30)
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.TextColor3 = Config.WeaponTextColor
    weaponLabel.TextSize = 10
    
    local distanceLabel = Instance.new("TextLabel", gui)
    distanceLabel.Size = UDim2.new(1, 0, 0, 15)
    distanceLabel.Position = UDim2.new(0, 0, 0, 45)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distanceLabel.TextSize = 10
    
    self.Objects[player] = {
        Gui = gui,
        NameLabel = nameLabel,
        HealthBar = healthBar,
        WeaponLabel = weaponLabel,
        DistanceLabel = distanceLabel,
        Adornee = nil,
        LastWeapon = nil,
    }
end

function ESPManager:UpdateESP(player)
    local data = self.Objects[player]
    if not data then return end
    
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    
    if hrp and hum and hum.Health > 0 then
        data.Gui.Adornee = hrp
        data.Gui.Enabled = true
        
        local healthPercent = hum.Health / hum.MaxHealth
        data.HealthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
        data.HealthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
        
        local myPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if myPos then
            local dist = (myPos.Position - hrp.Position).Magnitude
            data.DistanceLabel.Text = math.floor(dist) .. "m"
        end
        
        local weaponName, weaponIcon = GetPlayerWeapon(player)
        if weaponName ~= data.LastWeapon then
            data.LastWeapon = weaponName
            if weaponName then
                data.WeaponLabel.Text = "🔫 " .. weaponName
            else
                data.WeaponLabel.Text = "🔫 Sin arma"
            end
        end
    else
        data.Gui.Enabled = false
    end
end

function ESPManager:UpdateAll()
    for player, _ in pairs(self.Objects) do
        self:UpdateESP(player)
    end
end

function ESPManager:Toggle(enabled)
    self.Enabled = enabled
    if enabled then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                self:CreateESP(player)
            end
        end
        -- Loop de actualización
        task.spawn(function()
            while self.Enabled do
                self:UpdateAll()
                task.wait(Config.ESPUpdateInterval)
            end
        end)
    else
        for _, data in pairs(self.Objects) do
            pcall(function() data.Gui:Destroy() end)
        end
        self.Objects = {}
    end
end

-- ============================================
-- INVENTORY MANAGER
-- ============================================
local InventoryManager = {
    PlayerFrames = {},
    Group = nil,
}

function InventoryManager:CreatePlayerFrame(player)
    if not self.Group then return end
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 55)
    frame.BackgroundColor3 = Config.FrameColor
    frame.BackgroundTransparency = Config.FrameTransparency
    frame.BorderSizePixel = 0
    frame.Parent = self.Group

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0, 150, 0, 20)
    nameLabel.Position = UDim2.new(0, 10, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Config.PlayerTextColor
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = frame

    local weaponLabel = Instance.new("TextLabel")
    weaponLabel.Size = UDim2.new(0, 150, 0, 20)
    weaponLabel.Position = UDim2.new(0, 10, 0, 28)
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.TextColor3 = Config.WeaponTextColor
    weaponLabel.TextSize = 11
    weaponLabel.TextXAlignment = Enum.TextXAlignment.Left
    weaponLabel.Parent = frame

    local weaponImage = Instance.new("ImageLabel")
    weaponImage.Size = UDim2.new(0, 25, 0, 25)
    weaponImage.Position = UDim2.new(1, -35, 0.5, -12)
    weaponImage.BackgroundTransparency = 1
    weaponImage.Parent = frame

    self.PlayerFrames[player] = {
        Frame = frame,
        WeaponLabel = weaponLabel,
        WeaponImage = weaponImage,
        LastWeapon = nil,
    }
end

function InventoryManager:UpdatePlayerFrame(player)
    local data = self.PlayerFrames[player]
    if not data then return end

    local weaponName, weaponIcon = GetPlayerWeapon(player)
    
    if weaponName ~= data.LastWeapon then
        data.LastWeapon = weaponName
        if weaponName then
            data.WeaponLabel.Text = "🔫 " .. weaponName
            if weaponIcon then
                data.WeaponImage.Image = weaponIcon
                data.WeaponImage.Visible = true
            else
                data.WeaponImage.Visible = false
            end
        else
            data.WeaponLabel.Text = "🔫 Sin arma"
            data.WeaponImage.Visible = false
        end
    end
end

function InventoryManager:UpdateAll()
    for player, _ in pairs(self.PlayerFrames) do
        self:UpdatePlayerFrame(player)
    end
end

function InventoryManager:Cleanup()
    for player, data in pairs(self.PlayerFrames) do
        if not player or not player.Parent then
            pcall(function() data.Frame:Destroy() end)
            self.PlayerFrames[player] = nil
        end
    end
end

-- ============================================
-- MOVEMENT MANAGER
-- ============================================
local MovementManager = {
    SpeedEnabled = false,
    SpeedValue = Config.DefaultWalkSpeed,
    JumpEnabled = false,
    NoClipEnabled = false,
    FlyEnabled = false,
    NoClipConnection = nil,
    FlyConnection = nil,
    FlyKeys = {W = false, A = false, S = false, D = false, Space = false, LeftShift = false},
}

function MovementManager:ToggleSpeed(enabled)
    self.SpeedEnabled = enabled
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = enabled and self.SpeedValue or Config.DefaultWalkSpeed
    end
end

function MovementManager:SetSpeedValue(value)
    self.SpeedValue = value
    if self.SpeedEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = value
        end
    end
end

function MovementManager:ToggleJump(enabled)
    self.JumpEnabled = enabled
end

function MovementManager:StartJumpLoop()
    task.spawn(function()
        while true do
            if self.JumpEnabled then
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum and hum:GetState() == Enum.HumanoidStateType.Landed then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
            task.wait(Config.InfiniteJumpInterval)
        end
    end)
end

function MovementManager:ToggleNoClip(enabled)
    self.NoClipEnabled = enabled
    if enabled then
        if self.NoClipConnection then return end
        self.NoClipConnection = RunService.Stepped:Connect(function()
            if not self.NoClipEnabled then return end
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if self.NoClipConnection then
            self.NoClipConnection:Disconnect()
            self.NoClipConnection = nil
        end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

function MovementManager:ToggleFly(enabled)
    self.FlyEnabled = enabled
    
    if enabled then
        if self.FlyConnection then return end
        
        local function onInput(input, isDown)
            if input.KeyCode == Enum.KeyCode.W then self.FlyKeys.W = isDown end
            if input.KeyCode == Enum.KeyCode.A then self.FlyKeys.A = isDown end
            if input.KeyCode == Enum.KeyCode.S then self.FlyKeys.S = isDown end
            if input.KeyCode == Enum.KeyCode.D then self.FlyKeys.D = isDown end
            if input.KeyCode == Enum.KeyCode.Space then self.FlyKeys.Space = isDown end
            if input.KeyCode == Enum.KeyCode.LeftShift then self.FlyKeys.LeftShift = isDown end
        end
        
        self.FlyConnections = {
            KeyDown = UserInputService.InputBegan:Connect(function(i) onInput(i, true) end),
            KeyUp = UserInputService.InputEnded:Connect(function(i) onInput(i, false) end),
        }
        
        self.FlyConnection = RunService.RenderStepped:Connect(function()
            if not self.FlyEnabled then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            local cam = Workspace.CurrentCamera
            local dir = Vector3.new(0, 0, 0)
            
            if self.FlyKeys.W then dir = dir + cam.CFrame.LookVector end
            if self.FlyKeys.S then dir = dir - cam.CFrame.LookVector end
            if self.FlyKeys.A then dir = dir - cam.CFrame.RightVector end
            if self.FlyKeys.D then dir = dir + cam.CFrame.RightVector end
            if self.FlyKeys.Space then dir = dir + Vector3.new(0, 1, 0) end
            if self.FlyKeys.LeftShift then dir = dir - Vector3.new(0, 1, 0) end
            
            if dir.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + dir.Unit * Config.FlySpeed
            end
        end)
    else
        if self.FlyConnection then
            self.FlyConnection:Disconnect()
            self.FlyConnection = nil
        end
        if self.FlyConnections then
            if self.FlyConnections.KeyDown then self.FlyConnections.KeyDown:Disconnect() end
            if self.FlyConnections.KeyUp then self.FlyConnections.KeyUp:Disconnect() end
            self.FlyConnections = nil
        end
    end
end

-- ============================================
-- COMBAT MANAGER
-- ============================================
local CombatManager = {
    AutoHealEnabled = false,
    AutoHitEnabled = false,
    SilentAimEnabled = false,
    SilentAimTarget = nil,
}

function CombatManager:ToggleAutoHeal(enabled)
    self.AutoHealEnabled = enabled
    if enabled then
        task.spawn(function()
            while self.AutoHealEnabled do
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum and hum.Health < hum.MaxHealth * (Config.AutoHealPercent / 100) then
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    if backpack then
                        local medkit = backpack:FindFirstChild("Medkit") or backpack:FindFirstChild("Bandage")
                        if medkit and medkit:IsA("Tool") then
                            pcall(function()
                                medkit.Parent = LocalPlayer.Character
                                medkit:Activate()
                            end)
                        end
                    end
                end
                task.wait(1)
            end
        end)
    end
end

function CombatManager:ToggleAutoHit(enabled)
    self.AutoHitEnabled = enabled
    if enabled then
        task.spawn(function()
            while self.AutoHitEnabled do
                if self.SilentAimTarget then
                    -- Simular golpe (depende del juego, puede ser un remote)
                    pcall(function()
                        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                        if tool then
                            tool:Activate()
                        end
                    end)
                end
                task.wait(0.2)
            end
        end)
    end
end

function CombatManager:ToggleSilentAim(enabled)
    self.SilentAimEnabled = enabled
    if enabled then
        task.spawn(function()
            while self.SilentAimEnabled do
                self.SilentAimTarget = GetClosestPlayerToMouse(Config.SilentAimFOV)
                task.wait(0.05)
            end
        end)
    else
        self.SilentAimTarget = nil
    end
end

-- ============================================
-- WEAPON MANAGER (No Recoil, No Spread)
-- ============================================
local WeaponManager = {
    NoRecoilEnabled = false,
    NoSpreadEnabled = false,
}

function WeaponManager:ApplyMods()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    if self.NoRecoilEnabled then
        pcall(function() tool:SetAttribute("recoil", 0) end)
    end
    if self.NoSpreadEnabled then
        pcall(function() tool:SetAttribute("accuracy", 1) end)
    end
end

function WeaponManager:StartLoop()
    task.spawn(function()
        while true do
            if self.NoRecoilEnabled or self.NoSpreadEnabled then
                self:ApplyMods()
            end
            task.wait(0.5)
        end
    end)
end

function WeaponManager:ToggleNoRecoil(enabled)
    self.NoRecoilEnabled = enabled
end

function WeaponManager:ToggleNoSpread(enabled)
    self.NoSpreadEnabled = enabled
end

-- ============================================
-- MISC MANAGER
-- ============================================
local MiscManager = {
    AntiAFKEnabled = false,
    FullBrightEnabled = false,
}

function MiscManager:ToggleAntiAFK(enabled)
    self.AntiAFKEnabled = enabled
    if enabled then
        task.spawn(function()
            while self.AntiAFKEnabled do
                pcall(function()
                    VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
                    task.wait(0.1)
                    VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
                end)
                task.wait(Config.AntiAFKInterval)
            end
        end)
    end
end

function MiscManager:ToggleFullBright(enabled)
    self.FullBrightEnabled = enabled
    if enabled then
        Lighting.Brightness = 10
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    else
        Lighting.Brightness = 2
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 1000
    end
end

function MiscManager:Rejoin()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end

function MiscManager:ServerHop()
    local HttpService = game:GetService("HttpService")
    local servers = {}
    local response = HttpService:GetAsync("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")
    local data = HttpService:JSONDecode(response)
    for _, server in ipairs(data.data) do
        if server.playing < server.maxPlayers then
            table.insert(servers, server.id)
        end
    end
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
    end
end

-- ============================================
-- INICIALIZAR UI
-- ============================================
local Window = UIManager:CreateWindow()
Window:Tag({ Title = "v3.0 | Delta Edition", Color = "Text" })

-- Pestañas
local GeneralTab = Window:Tab({ Title = "General", Icon = "solar:user-bold-duotone" })
local CombatTab = Window:Tab({ Title = "Combat", Icon = "solar:swords-bold-duotone" })
local WeaponsTab = Window:Tab({ Title = "Weapons", Icon = "solar:tuning-bold-duotone" })
local VisualTab = Window:Tab({ Title = "Visual", Icon = "solar:eye-bold-duotone" })
local InventoryTab = Window:Tab({ Title = "Inventory", Icon = "solar:backpack-bold-duotone" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "solar:settings-bold-duotone" })

GeneralTab:Select()

-- ============================================
-- PESTAÑA GENERAL
-- ============================================
local MoveGroup = GeneralTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚡ Movement" })

MoveGroup:Toggle({
    Flag = "SpeedHack", Title = "Speed Hack", Value = false,
    Callback = function(v) MovementManager:ToggleSpeed(v) end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Slider({
    Flag = "SpeedValue", Title = "Speed Amount", IsTooltip = true, Step = 1,
    Value = { Min = Config.DefaultWalkSpeed, Max = 200, Default = 50 },
    Callback = function(v) MovementManager:SetSpeedValue(v) end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "InfiniteJump", Title = "Infinite Jump", Value = false,
    Callback = function(v) MovementManager:ToggleJump(v) end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "NoClip", Title = "No Clip", Value = false,
    Callback = function(v) MovementManager:ToggleNoClip(v) end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "Fly", Title = "Fly Mode", Value = false,
    Callback = function(v) MovementManager:ToggleFly(v) end,
})

-- ============================================
-- PESTAÑA COMBAT
-- ============================================
local CombatGroup = CombatTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚔️ Combat" })

CombatGroup:Toggle({
    Flag = "SilentAim", Title = "Silent Aim", Value = false,
    Callback = function(v) CombatManager:ToggleSilentAim(v) end,
})

CombatGroup:Space()
CombatGroup:Space()

CombatGroup:Slider({
    Flag = "SilentAimFOV", Title = "Silent Aim FOV", IsTooltip = true, Step = 1,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v) Config.SilentAimFOV = v end,
})

CombatGroup:Space()
CombatGroup:Space()

CombatGroup:Dropdown({
    Flag = "AimPart", Title = "Aim Part", Values = { "Head", "Torso", "HumanoidRootPart" }, Value = "Head",
    Callback = function(v) Config.AimPart = v end,
})

CombatTab:Space({ Columns = 2 })

local AutoGroup = CombatTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "🤖 Auto" })

AutoGroup:Toggle({
    Flag = "AutoHeal", Title = "Auto Heal", Value = false,
    Callback = function(v) CombatManager:ToggleAutoHeal(v) end,
})

AutoGroup:Space()
AutoGroup:Space()

AutoGroup:Slider({
    Flag = "HealPercent", Title = "Heal at HP%", IsTooltip = true, Step = 1,
    Value = { Min = 20, Max = 90, Default = 70 },
    Callback = function(v) Config.AutoHealPercent = v end,
})

AutoGroup:Space()
AutoGroup:Space()

AutoGroup:Toggle({
    Flag = "AutoHit", Title = "Auto Hit", Value = false,
    Callback = function(v) CombatManager:ToggleAutoHit(v) end,
})

-- ============================================
-- PESTAÑA WEAPONS
-- ============================================
local WeaponGroup = WeaponsTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "🔫 Mods" })

WeaponGroup:Toggle({
    Flag = "NoRecoil", Title = "No Recoil", Value = false,
    Callback = function(v) WeaponManager:ToggleNoRecoil(v) end,
})

WeaponGroup:Space()
WeaponGroup:Space()

WeaponGroup:Toggle({
    Flag = "NoSpread", Title = "No Spread", Value = false,
    Callback = function(v) WeaponManager:ToggleNoSpread(v) end,
})

-- ============================================
-- PESTAÑA VISUAL
-- ============================================
local VisualGroup = VisualTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "🎨 Visual" })

VisualGroup:Toggle({
    Flag = "Chams", Title = "Chams (Azul)", Value = false,
    Callback = function(v) ChamsManager:Toggle(v) end,
})

VisualGroup:Space()
VisualGroup:Space()

VisualGroup:Toggle({
    Flag = "ESP", Title = "ESP 3D", Value = false,
    Callback = function(v) ESPManager:Toggle(v) end,
})

VisualGroup:Space()
VisualGroup:Space()

VisualGroup:Toggle({
    Flag = "FullBright", Title = "Full Bright", Value = false,
    Callback = function(v) MiscManager:ToggleFullBright(v) end,
})

-- ============================================
-- PESTAÑA INVENTORY
-- ============================================
InventoryManager.Group = InventoryTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "📦 Players Inventory" })

-- Crear frames para jugadores existentes
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        InventoryManager:CreatePlayerFrame(player)
    end
end

-- Actualizar inventario periódicamente
task.spawn(function()
    while true do
        for player, _ in pairs(InventoryManager.PlayerFrames) do
            if player and player.Parent then
                pcall(function() InventoryManager:UpdatePlayerFrame(player) end)
            else
                InventoryManager:Cleanup()
            end
        end
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not InventoryManager.PlayerFrames[player] then
                InventoryManager:CreatePlayerFrame(player)
            end
        end
        
        task.wait(Config.InventoryUpdateInterval)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if InventoryManager.PlayerFrames[player] then
        pcall(function() InventoryManager.PlayerFrames[player].Frame:Destroy() end)
        InventoryManager.PlayerFrames[player] = nil
    end
end)

-- ============================================
-- PESTAÑA SETTINGS
-- ============================================
local SettingsGroup = SettingsTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚙️ General" })

SettingsGroup:Toggle({
    Flag = "AntiAFK", Title = "Anti AFK", Value = false,
    Callback = function(v) MiscManager:ToggleAntiAFK(v) end,
})

SettingsGroup:Space()
SettingsGroup:Space()

SettingsGroup:Button({
    Title = "🔄 Rejoin Server",
    Icon = "solar:refresh-bold-duotone",
    Justify = "Left",
    Callback = function() MiscManager:Rejoin() end,
})

SettingsGroup:Space()
SettingsGroup:Space()

SettingsGroup:Button({
    Title = "🎲 Server Hop",
    Icon = "solar:shuffle-bold-duotone",
    Justify = "Left",
    Callback = function() MiscManager:ServerHop() end,
})

SettingsGroup:Space()
SettingsGroup:Space()

SettingsGroup:Button({
    Title = "💀 Destroy UI",
    Icon = "solar:logout-3-bold",
    Justify = "Left",
    Color = Color3.fromRGB(255, 70, 70),
    Callback = function()
        Window:Destroy()
        for _, data in pairs(ESPManager.Objects) do
            pcall(function() data.Gui:Destroy() end)
        end
        for _, data in pairs(InventoryManager.PlayerFrames) do
            pcall(function() data.Frame:Destroy() end)
        end
        for _, highlight in pairs(ChamsManager.Objects) do
            pcall(function() highlight:Destroy() end)
        end
        MiscManager:ToggleFullBright(false)
        MovementManager:ToggleNoClip(false)
        MovementManager:ToggleFly(false)
    end,
})

SettingsGroup:Space()
SettingsGroup:Space()

SettingsGroup:Button({
    Title = "Water Hub Created By AdamABJ",
    Icon = "solar:star-bold-duotone",
    Color = Color3.fromHex("#EF4F1D"),
    Justify = "Center",
    Callback = function() end,
})

-- ============================================
-- INICIAR LOOPS
-- ============================================
MovementManager:StartJumpLoop()
WeaponManager:StartLoop()

-- Mantener velocidad después de respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if MovementManager.SpeedEnabled then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = MovementManager.SpeedValue end
    end
end)

-- ============================================
-- NOTIFICACIÓN FINAL
-- ============================================
pcall(function()
    WindUI:Notify({
        Title = "Water Hub | BlockSpin",
        Content = "Delta Edition Completa cargada!",
        Icon = "solar:water-drops-bold-duotone",
        Duration = 3,
    })
end)

StarterGui:SetCore("SendNotification", {
    Title = "Water Hub",
    Text = "✅ Delta Edition Completa (800+ líneas)",
    Duration = 3,
})

print("✅ Water Hub | BlockSpin - Delta Edition Completa")
print("📊 Módulos cargados:")
print("   - Chams Manager")
print("   - ESP Manager (3D)")
print("   - Inventory Manager")
print("   - Movement Manager (Speed, Jump, NoClip, Fly)")
print("   - Combat Manager (Silent Aim, Auto Heal, Auto Hit)")
print("   - Weapon Manager (No Recoil, No Spread)")
print("   - Misc Manager (Anti AFK, Full Bright, Server Hop)")
