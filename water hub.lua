--[[
    WATER HUB | BLOCKSPIN | DELTA EDITION
    Adaptado para Delta Executor
    By: AdamABJ
--]]

-- ============================================
-- CONFIGURACIÓN
-- ============================================
local Config = {
    FrameColor = Color3.fromRGB(35, 40, 50),
    FrameTransparency = 0.3,
    PlayerTextColor = Color3.fromRGB(255, 255, 255),
    WeaponTextColor = Color3.fromRGB(255, 200, 100),
    DefaultWalkSpeed = 16,
    InfiniteJumpInterval = 0.05,
    InventoryUpdateInterval = 2,
}

-- ============================================
-- SERVICIOS
-- ============================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

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
-- FUNCIÓN PARA OBTENER ARMA
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

-- ============================================
-- CARGAR WINDUI (ADAPTADO PARA DELTA)
-- ============================================
local WindUI

local function LoadWindUI()
    -- Intento 1: Cargar desde ReplicatedStorage
    local success, result = pcall(function()
        return require(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init"))
    end)
    
    if success then
        WindUI = result
        return true
    end
    
    -- Intento 2: Cargar desde GitHub (con bypass para Delta)
    local httpSuccess, httpResult = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua", true))()
    end)
    
    if httpSuccess and httpResult then
        WindUI = httpResult
        return true
    end
    
    -- Si todo falla, notificar error
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
-- INVENTORY MANAGER
-- ============================================
local InventoryManager = {
    PlayerFrames = {},
    Group = nil,
}

function InventoryManager:CreatePlayerFrame(player)
    -- Asegurar que el grupo existe
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
        NameLabel = nameLabel,
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

function InventoryManager:UpdateAllPlayers()
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

-- ============================================
-- COMBAT MANAGER
-- ============================================
local CombatManager = {
    AutoHealEnabled = false,
}

function CombatManager:ToggleAutoHeal(enabled)
    self.AutoHealEnabled = enabled
    if enabled then
        task.spawn(function()
            while self.AutoHealEnabled do
                local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum and hum.Health < hum.MaxHealth * 0.7 then
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

-- ============================================
-- INICIALIZAR UI
-- ============================================
local Window = UIManager:CreateWindow()
Window:Tag({ Title = "v2.0 | Delta Edition", Color = "Text" })

-- Pestañas
local GeneralTab = Window:Tab({ Title = "General", Icon = "solar:user-bold-duotone" })
local CombatTab = Window:Tab({ Title = "Combat", Icon = "solar:swords-bold-duotone" })
local InventoryTab = Window:Tab({ Title = "Inventory", Icon = "solar:backpack-bold-duotone" })
local SettingsTab = Window:Tab({ Title = "Settings", Icon = "solar:settings-bold-duotone" })

GeneralTab:Select()

-- ============================================
-- PESTAÑA GENERAL
-- ============================================
local GeneralSection = GeneralTab:Section({ Title = "Movement", Box = true, BoxBorder = true, Opened = true })
local MoveGroup = GeneralTab:Group()

MoveGroup:Toggle({
    Flag = "SpeedHack",
    Title = "Speed Hack",
    Value = false,
    Callback = function(v) MovementManager:ToggleSpeed(v) end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Slider({
    Flag = "SpeedValue",
    Title = "Speed Amount",
    IsTooltip = true,
    Step = 1,
    Value = { Min = Config.DefaultWalkSpeed, Max = 200, Default = 50 },
    Callback = function(v) MovementManager:SetSpeedValue(v) end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "InfiniteJump",
    Title = "Infinite Jump",
    Value = false,
    Callback = function(v) MovementManager:ToggleJump(v) end,
})

-- ============================================
-- PESTAÑA COMBAT
-- ============================================
local CombatSection = CombatTab:Section({ Title = "Auto Options", Box = true, BoxBorder = true, Opened = true })
local CombatGroup = CombatTab:Group()

CombatGroup:Toggle({
    Flag = "AutoHeal",
    Title = "Auto Heal",
    Value = false,
    Callback = function(v) CombatManager:ToggleAutoHeal(v) end,
})

-- ============================================
-- PESTAÑA INVENTORY
-- ============================================
local InventorySection = InventoryTab:Section({ Title = "Players Inventory", Box = true, BoxBorder = true, Opened = true })
InventoryManager.Group = InventoryTab:Group()

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
        
        -- Detectar nuevos jugadores
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and not InventoryManager.PlayerFrames[player] then
                InventoryManager:CreatePlayerFrame(player)
            end
        end
        
        task.wait(Config.InventoryUpdateInterval)
    end
end)

-- Cuando un jugador sale
Players.PlayerRemoving:Connect(function(player)
    if InventoryManager.PlayerFrames[player] then
        pcall(function() InventoryManager.PlayerFrames[player].Frame:Destroy() end)
        InventoryManager.PlayerFrames[player] = nil
    end
end)

-- ============================================
-- PESTAÑA SETTINGS
-- ============================================
local SettingsSection = SettingsTab:Section({ Title = "UI Settings", Box = true, BoxBorder = true, Opened = true })
local SettingsGroup = SettingsTab:Group()

SettingsGroup:Toggle({
    Flag = "Transparent",
    Title = "Window Transparency",
    Value = true,
    Callback = function(v) Window:ToggleTransparency(v) end,
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
        Content = "Delta Edition cargada con éxito!",
        Icon = "solar:water-drops-bold-duotone",
        Duration = 3,
    })
end)

StarterGui:SetCore("SendNotification", {
    Title = "Water Hub",
    Text = "✅ Delta Edition lista!",
    Duration = 3,
})

print("✅ Water Hub | BlockSpin - Delta Edition cargada")
print("🔫 Inventory Manager activado")
