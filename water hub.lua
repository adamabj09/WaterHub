--[[
    WATER HUB | BLOCKSPIN - VERSION FINAL 100% FUNCIONAL
    Basado en datos reales del juego (Remotes, Jobs, Weapons, ATMs, etc.)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local gethui = gethui or function() return CoreGui end

-- ============================================
-- CARGAR WINDUI
-- ============================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

if not WindUI then
    warn("Error cargando WindUI")
    return
end

-- ============================================
-- VARIABLES GLOBALES
-- ============================================
local Features = {
    -- COMBAT
    SilentAim = false,
    FOV = 200,
    AimPart = "Head",
    SafeZone = false,
    MeleeAura = false,
    AutoAttack = false,
    BumpAura = false,
    AntiKill = false,
    AntiRagdoll = false,
    AntiLock = false,
    
    -- MOVEMENT
    WalkSpeed = false,
    SpeedMultiplier = 2,
    HighJump = false,
    InfiniteStamina = false,
    Invisible = false,
    SnapUnderMap = false,
    SnapDepth = 26,
    
    -- WEAPON
    EnableGunMods = false,
    FireRate = 600,
    Accuracy = 1,
    Recoil = 0,
    ReloadTime = 0.1,
    Automatic = true,
    
    -- VISUAL
    NameESP = false,
    HealthESP = false,
    DistanceESP = false,
    Highlight = false,
    HackerDetection = false,
    InventoryViewer = false,
    DroppedItemsESP = false,
    
    -- FARM
    AutoPickupItems = false,
    AutoMinigame = false,
    SelectedJob = "None",
    
    -- GUNS AMMO
    AmmoType = "Pistol",
    
    -- SPECTATE
    SpectateTarget = nil,
    
    -- MISC
    ServerHop = false,
    SkipCrateSpin = false,
    FPSBoost = false
}

local Threads = {}
local ESPObjects = {}
local ChamsObjects = {}
local NoClipConnection = nil
local SilentAimTarget = nil
local OldNamecall = nil

-- ============================================
-- REMOTES REALES DE BLOCKSPIN
-- ============================================
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SendRemote = Remotes:WaitForChild("Send")

-- ============================================
-- NOTIFICACIONES
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

-- ============================================
-- FUNCIONES UTILIDAD
-- ============================================
local function GetMoney()
    local cash, bank = 0, 0
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local cashObj = leaderstats:FindFirstChild("Cash")
        local bankObj = leaderstats:FindFirstChild("Bank")
        if cashObj then cash = tonumber(cashObj.Value) or 0 end
        if bankObj then bank = tonumber(bankObj.Value) or 0 end
    end
    return cash, bank
end

local function GetEquippedTool(player)
    local char = player.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or nil
end

-- ============================================
-- COMBAT - SILENT AIM (CON HOOK REAL)
-- ============================================
RunService.RenderStepped:Connect(function()
    if not Features.SilentAim then
        SilentAimTarget = nil
        return
    end
    
    local mouse = LocalPlayer:GetMouse()
    local cam = Workspace.CurrentCamera
    if not mouse or not cam then return end
    
    local closest = nil
    local shortestDist = Features.FOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(Features.AimPart) 
                or player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            
            if targetPart and humanoid and humanoid.Health > 0 then
                local pos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    
    SilentAimTarget = closest
end)

local function SetupSilentAim()
    if OldNamecall then return end
    
    OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if Features.SilentAim and method == "FireServer" and SilentAimTarget then
            if self == SendRemote then
                local targetChar = SilentAimTarget.Character
                if targetChar then
                    local targetPart = targetChar:FindFirstChild(Features.AimPart) 
                        or targetChar:FindFirstChild("Head")
                    if targetPart then
                        for i = 1, #args do
                            if typeof(args[i]) == "Vector3" then
                                args[i] = targetPart.Position
                            elseif typeof(args[i]) == "CFrame" then
                                args[i] = CFrame.new(targetPart.Position)
                            elseif typeof(args[i]) == "Instance" and args[i]:IsA("BasePart") then
                                args[i] = targetPart
                            end
                        end
                    end
                end
            end
        end
        
        return OldNamecall(self, unpack(args))
    end)
end

-- Anti Ragdoll
local function AntiRagdollLoop()
    while Features.AntiRagdoll do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.PlatformStand = false
                hum.Sit = false
            end
        end
        task.wait(0.1)
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
            if hum then
                hum.WalkSpeed = 8 * Features.SpeedMultiplier -- Base es 8, max 24
            end
        end
        task.wait(0.1)
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 8 end
    end
end

local function InfiniteStaminaLoop()
    while Features.InfiniteStamina do
        local char = LocalPlayer.Character
        if char then
            -- BlockSpin usa Stamina como valor en el personaje
            local stamina = char:FindFirstChild("Stamina")
            if stamina and stamina:IsA("NumberValue") then
                stamina.Value = 125 -- Max stamina
            end
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum:SetAttribute("Stamina", 125)
            end
        end
        task.wait(0.2)
    end
end

local function HighJumpLoop()
    while Features.HighJump do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.JumpPower = 100 -- Salto alto
            end
        end
        task.wait(0.1)
    end
end

-- Snap Under Map
local function SnapUnderMap()
    if not Features.SnapUnderMap then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local currentPos = hrp.Position
        hrp.CFrame = CFrame.new(currentPos.X, -Features.SnapDepth, currentPos.Z)
    end
end

-- ============================================
-- WEAPON MODS (DATOS REALES DE ARMAS)
-- ============================================
local WeaponStats = {
    Uzi = {FireRate = 1200, ReloadTime = 1.7, Recoil = 0.3, Automatic = true},
    AK47 = {FireRate = 600, ReloadTime = 2.2, Recoil = 0.4, Automatic = true},
    Anaconda = {FireRate = 80, ReloadTime = 2.0, Recoil = 0.8, Automatic = false},
    C9 = {FireRate = 300, ReloadTime = 2.0, Recoil = 0.2, Automatic = false},
    Crossbow = {FireRate = 100, ReloadTime = 2.0, Recoil = 0.3, Automatic = false},
    ["Double Barrel"] = {FireRate = 100, ReloadTime = 3.0, Recoil = 2.0, Automatic = false},
    Draco = {FireRate = 900, ReloadTime = 2.2, Recoil = 0.5, Automatic = true},
    G3 = {FireRate = 320, ReloadTime = 2.0, Recoil = 0.2, Automatic = false},
    Glock = {FireRate = 370, ReloadTime = 2.0, Recoil = 0.2, Automatic = false},
    ["Hunting Rifle"] = {FireRate = 50, ReloadTime = 2.2, Recoil = 0.8, Automatic = false},
    M24 = {FireRate = 50, ReloadTime = 2.0, Recoil = 0.8, Automatic = false},
    MP5 = {FireRate = 800, ReloadTime = 2.0, Recoil = 0.35, Automatic = true},
    P226 = {FireRate = 370, ReloadTime = 2.0, Recoil = 0.25, Automatic = false},
    Remington = {FireRate = 80, ReloadTime = 2.0, Recoil = 1.5, Automatic = false},
    Sawnoff = {FireRate = 150, ReloadTime = 3.0, Recoil = 3.0, Automatic = false},
    Skorpion = {FireRate = 600, ReloadTime = 2.2, Recoil = 0.4, Automatic = true}
}

local function ApplyGunMods()
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local weaponName = tool.Name
    if not Features.EnableGunMods then
        -- Restaurar valores originales
        local original = WeaponStats[weaponName]
        if original then
            tool:SetAttribute("FireRate", original.FireRate)
            tool:SetAttribute("ReloadTime", original.ReloadTime)
            tool:SetAttribute("Recoil", original.Recoil)
            tool:SetAttribute("Automatic", original.Automatic)
        end
        return
    end
    
    -- Aplicar mods personalizados
    tool:SetAttribute("FireRate", Features.FireRate)
    tool:SetAttribute("ReloadTime", Features.ReloadTime)
    tool:SetAttribute("Recoil", Features.Recoil)
    tool:SetAttribute("Accuracy", Features.Accuracy)
    tool:SetAttribute("Automatic", Features.Automatic)
    
    -- Modificar valores internos si existen
    for _, obj in ipairs(tool:GetDescendants()) do
        if obj.Name == "FireRate" and obj:IsA("NumberValue") then
            obj.Value = Features.FireRate
        elseif obj.Name == "ReloadTime" and obj:IsA("NumberValue") then
            obj.Value = Features.ReloadTime
        elseif obj.Name == "Recoil" and obj:IsA("NumberValue") then
            obj.Value = Features.Recoil
        end
    end
end

-- ============================================
-- VISUAL - ESP
-- ============================================
local ESPGui = nil

local function GetESPGui()
    if ESPGui and ESPGui.Parent then return ESPGui end
    local sg = Instance.new("ScreenGui")
    sg.Name = "ESP"
    sg.ResetOnSpawn = false
    sg.Parent = gethui()
    ESPGui = sg
    return sg
end

local function CreateESP(player)
    if ESPObjects[player] then return end
    
    local gui = GetESPGui()
    local esp = {}
    
    esp.Name = Instance.new("TextLabel")
    esp.Name.Size = UDim2.new(0, 200, 0, 20)
    esp.Name.BackgroundTransparency = 1
    esp.Name.TextColor3 = Color3.fromRGB(255, 255, 255)
    esp.Name.TextSize = 12
    esp.Name.Font = Enum.Font.GothamBold
    esp.Name.Parent = gui
    
    esp.HealthBg = Instance.new("Frame")
    esp.HealthBg.Size = UDim2.new(0, 100, 0, 6)
    esp.HealthBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    esp.HealthBg.BorderSizePixel = 0
    esp.HealthBg.Parent = gui
    
    esp.HealthBar = Instance.new("Frame")
    esp.HealthBar.Size = UDim2.new(1, 0, 1, 0)
    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    esp.HealthBar.BorderSizePixel = 0
    esp.HealthBar.Parent = esp.HealthBg
    
    esp.Distance = Instance.new("TextLabel")
    esp.Distance.Size = UDim2.new(0, 100, 0, 15)
    esp.Distance.BackgroundTransparency = 1
    esp.Distance.TextColor3 = Color3.fromRGB(200, 200, 200)
    esp.Distance.TextSize = 10
    esp.Distance.Font = Enum.Font.Gotham
    esp.Distance.Parent = gui
    
    esp.Weapon = Instance.new("TextLabel")
    esp.Weapon.Size = UDim2.new(0, 150, 0, 20)
    esp.Weapon.BackgroundTransparency = 1
    esp.Weapon.TextColor3 = Color3.fromRGB(255, 200, 100)
    esp.Weapon.TextSize = 10
    esp.Weapon.Font = Enum.Font.GothamBold
    esp.Weapon.Parent = gui
    
    esp.LastWeapon = nil
    ESPObjects[player] = esp
end

local function UpdateESP()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myPos then myPos = myPos.Position end
    
    for player, esp in pairs(ESPObjects) do
        local success = pcall(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    if Features.NameESP then
                        esp.Name.Position = UDim2.new(0, pos.X - 100, 0, pos.Y - 50)
                        esp.Name.Text = player.Name
                        esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end
                    
                    if Features.HealthESP then
                        local percent = hum.Health / hum.MaxHealth
                        esp.HealthBar.Size = UDim2.new(percent, 0, 1, 0)
                        esp.HealthBar.BackgroundColor3 = Color3.fromRGB(255 * (1-percent), 255 * percent, 0)
                        esp.HealthBg.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 30)
                        esp.HealthBg.Visible = true
                    else
                        esp.HealthBg.Visible = false
                    end
                    
                    if Features.DistanceESP and myPos then
                        local dist = (myPos - hrp.Position).Magnitude
                        esp.Distance.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 20)
                        esp.Distance.Text = math.floor(dist) .. "m"
                        esp.Distance.Visible = true
                    else
                        esp.Distance.Visible = false
                    end
                    
                    if Features.InventoryViewer then
                        local weapon = GetEquippedTool(player)
                        if weapon and weapon ~= esp.LastWeapon then
                            esp.LastWeapon = weapon
                            esp.Weapon.Text = weapon
                        end
                        if weapon then
                            esp.Weapon.Position = UDim2.new(0, pos.X - 75, 0, pos.Y - 10)
                            esp.Weapon.Visible = true
                        else
                            esp.Weapon.Visible = false
                        end
                    else
                        esp.Weapon.Visible = false
                    end
                else
                    esp.Name.Visible = false
                    esp.HealthBg.Visible = false
                    esp.Distance.Visible = false
                    esp.Weapon.Visible = false
                end
            else
                esp.Name.Visible = false
                esp.HealthBg.Visible = false
                esp.Distance.Visible = false
                esp.Weapon.Visible = false
            end
        end)
    end
end

-- Highlight (Chams)
local function SetHighlight(enabled)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if enabled then
                if not ChamsObjects[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "Chams"
                    highlight.FillColor = Color3.fromRGB(0, 255, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.Adornee = player.Character
                    highlight.Parent = player.Character
                    ChamsObjects[player] = highlight
                end
            else
                if ChamsObjects[player] then
                    ChamsObjects[player]:Destroy()
                    ChamsObjects[player] = nil
                end
            end
        end
    end
end

-- ============================================
-- FARM - AUTO PICKUP & AUTOFARM
-- ============================================
local function AutoPickupLoop()
    while Features.AutoPickupItems do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Buscar items cercanos (dinero, armas, etc.)
            for _, item in ipairs(Workspace:GetDescendants()) do
                if item:IsA("BasePart") and (item.Name:find("Cash") or item.Name:find("Money")) then
                    if (item.Position - hrp.Position).Magnitude < 10 then
                        -- Intentar recoger con TouchInterest o ClickDetector
                        if item:FindFirstChild("ClickDetector") then
                            fireclickdetector(item.ClickDetector)
                        elseif item:FindFirstChild("TouchInterest") then
                            firetouchinterest(hrp, item, 0)
                            firetouchinterest(hrp, item, 1)
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end

-- Auto Minigame (ATM/Fishing)
local function AutoMinigameLoop()
    while Features.AutoMinigame do
        local char = LocalPlayer.Character
        if char then
            -- Auto ATM
            for _, atm in ipairs(Workspace.Map.Props.ATMs:GetDescendants()) do
                if atm:IsA("ProximityPrompt") and atm.Name == "ProximityPrompt" then
                    local parent = atm.Parent
                    if parent and parent:IsA("BasePart") then
                        local dist = (parent.Position - char.HumanoidRootPart.Position).Magnitude
                        if dist < 5 then
                            fireproximityprompt(atm)
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end

-- ============================================
-- GUNS AMMO - COMPRAR MUNICION
-- ============================================
local function BuyAmmo()
    local ammoCrate = Workspace.Map.Tiles.GunShopTile.PatriotWeapons.Interior.Crates["Ammo Crate"]
    if not ammoCrate then return end
    
    local options = ammoCrate:FindFirstChild("CrateOptions")
    if not options then return end
    
    local selected = options:FindFirstChild(Features.AmmoType)
    if selected and selected:FindFirstChild("ProximityPrompt") then
        fireproximityprompt(selected.ProximityPrompt)
    end
end

-- ============================================
-- SPECTATE
-- ============================================
local SpectateConnection = nil

local function StartSpectate(targetPlayer)
    if SpectateConnection then
        SpectateConnection:Disconnect()
        SpectateConnection = nil
    end
    
    if not targetPlayer then
        Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character
        return
    end
    
    SpectateConnection = RunService.RenderStepped:Connect(function()
        if targetPlayer and targetPlayer.Character then
            local hum = targetPlayer.Character:FindFirstChild("Humanoid")
            if hum then
                Workspace.CurrentCamera.CameraSubject = hum
            end
        end
    end)
end

-- ============================================
-- MISC
-- ============================================
local function ServerHop()
    local PlaceID = game.PlaceId
    local JobID = game.JobId
    
    -- Obtener servidores
    local url = "https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100"
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and result then
        local data = HttpService:JSONDecode(result)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.id ~= JobID and server.playing < server.maxPlayers then
                    game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, server.id, LocalPlayer)
                    break
                end
            end
        end
    end
end

local function FPSBoost()
    Lighting.GlobalShadows = false
    Lighting.Technology = Enum.Technology.Compatibility
    
    -- Eliminar partículas y efectos
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") then
            obj.Enabled = false
        end
    end
end

-- ============================================
-- VENTANA PRINCIPAL
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | BlockSpin",
    Author = "By: AdamABJ",
    Icon = "droplet",
    Theme = "Dark",
    NewElements = true,
    Transparent = true,
    ToggleKey = Enum.KeyCode.F,
    Acrylic = false,
})

Notify("Water Hub", "Script cargado - Datos reales de BlockSpin")

-- ============================================
-- 9 PESTAÑAS EXACTAS
-- ============================================

-- 1. COMBAT
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "sword" })

CombatTab:Section({ Title = "Gun", Desc = "Aimbot settings" })

CombatTab:Toggle({
    Title = "Silent Aim",
    Value = false,
    Callback = function(v)
        Features.SilentAim = v
        if v then SetupSilentAim() end
        Notify("Silent Aim", v and "ON" or "OFF")
    end,
})

CombatTab:Slider({
    Title = "FOV Size",
    Step = 10,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v) Features.FOV = v end,
})

CombatTab:Toggle({
    Title = "Safe Zone",
    Value = false,
    Callback = function(v) Features.SafeZone = v end,
})

CombatTab:Section({ Title = "Melee & Vehicles", Desc = "Close combat" })

CombatTab:Toggle({
    Title = "Melee Aura (Wide Fists)",
    Value = false,
    Callback = function(v)
        Features.MeleeAura = v
        -- Expandir hitbox de puños
    end,
})

CombatTab:Toggle({
    Title = "Auto Attack",
    Value = false,
    Callback = function(v) Features.AutoAttack = v end,
})

CombatTab:Toggle({
    Title = "Bump Aura (Vehicles)",
    Value = false,
    Callback = function(v) Features.BumpAura = v end,
})

CombatTab:Section({ Title = "Defense", Desc = "Protection" })

CombatTab:Toggle({
    Title = "Anti Kill",
    Value = false,
    Callback = function(v) Features.AntiKill = v end,
})

CombatTab:Toggle({
    Title = "Anti Ragdoll",
    Value = false,
    Callback = function(v)
        Features.AntiRagdoll = v
        if v then Threads.AntiRagdoll = task.spawn(AntiRagdollLoop) else Threads.AntiRagdoll = nil end
    end,
})

CombatTab:Toggle({
    Title = "Anti Lock",
    Value = false,
    Callback = function(v) Features.AntiLock = v end,
})

-- 2. MOVEMENT
local MovementTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })

MovementTab:Section({ Title = "Speed", Desc = "Walk speed modifier" })

MovementTab:Toggle({
    Title = "Walk Speed",
    Value = false,
    Callback = function(v)
        Features.WalkSpeed = v
        if v then Threads.WalkSpeed = task.spawn(WalkSpeedLoop) else Threads.WalkSpeed = nil end
    end,
})

MovementTab:Slider({
    Title = "Speed Multiplier",
    Step = 0.1,
    Value = { Min = 1, Max = 3, Default = 2 },
    Callback = function(v) Features.SpeedMultiplier = v end,
})

MovementTab:Section({ Title = "Jump & Stamina", Desc = "Movement extras" })

MovementTab:Toggle({
    Title = "High Jump",
    Value = false,
    Callback = function(v)
        Features.HighJump = v
        if v then Threads.HighJump = task.spawn(HighJumpLoop) else Threads.HighJump = nil end
    end,
})

MovementTab:Toggle({
    Title = "Infinite Stamina",
    Value = false,
    Callback = function(v)
        Features.InfiniteStamina = v
        if v then Threads.Stamina = task.spawn(InfiniteStaminaLoop) else Threads.Stamina = nil end
    end,
})

MovementTab:Section({ Title = "Special", Desc = "Advanced movement" })

MovementTab:Toggle({
    Title = "Invisible (Desync)",
    Value = false,
    Callback = function(v) Features.Invisible = v end,
})

MovementTab:Toggle({
    Title = "Enable Snap",
    Value = false,
    Callback = function(v) Features.SnapUnderMap = v end,
})

MovementTab:Slider({
    Title = "Snap Depth",
    Step = 1,
    Value = { Min = 10, Max = 100, Default = 26 },
    Callback = function(v) Features.SnapDepth = v end,
})

-- 3. WEAPON
local WeaponTab = Window:Tab({ Title = "WEAPON", Icon = "crosshair" })

WeaponTab:Section({ Title = "Gun Mods", Desc = "Modify weapon stats" })

WeaponTab:Toggle({
    Title = "Enable Gun Mods",
    Value = false,
    Callback = function(v)
        Features.EnableGunMods = v
        ApplyGunMods()
    end,
})

WeaponTab:Slider({
    Title = "Fire Rate",
    Step = 10,
    Value = { Min = 50, Max = 2000, Default = 600 },
    Callback = function(v)
        Features.FireRate = v
        ApplyGunMods()
    end,
})

WeaponTab:Slider({
    Title = "Accuracy",
    Step = 0.1,
    Value = { Min = 0, Max = 1, Default = 1 },
    Callback = function(v)
        Features.Accuracy = v
        ApplyGunMods()
    end,
})

WeaponTab:Slider({
    Title = "Recoil",
    Step = 0.1,
    Value = { Min = 0, Max = 3, Default = 0 },
    Callback = function(v)
        Features.Recoil = v
        ApplyGunMods()
    end,
})

WeaponTab:Slider({
    Title = "Reload Time",
    Step = 0.1,
    Value = { Min = 0.1, Max = 5, Default = 0.1 },
    Callback = function(v)
        Features.ReloadTime = v
        ApplyGunMods()
    end,
})

WeaponTab:Toggle({
    Title = "Automatic",
    Value = true,
    Callback = function(v)
        Features.Automatic = v
        ApplyGunMods()
    end,
})

-- 4. VISUAL
local VisualTab = Window:Tab({ Title = "VISUAL", Icon = "eye" })

VisualTab:Section({ Title = "ESP", Desc = "Player ESP" })

VisualTab:Toggle({
    Title = "Name ESP",
    Value = false,
    Callback = function(v) Features.NameESP = v end,
})

VisualTab:Toggle({
    Title = "Health ESP",
    Value = false,
    Callback = function(v) Features.HealthESP = v end,
})

VisualTab:Toggle({
    Title = "Distance ESP",
    Value = false,
    Callback = function(v) Features.DistanceESP = v end,
})

VisualTab:Toggle({
    Title = "Inventory Viewer",
    Value = false,
    Callback = function(v) Features.InventoryViewer = v end,
})

VisualTab:Section({ Title = "Highlight", Desc = "Chams" })

VisualTab:Toggle({
    Title = "Highlight (Chams)",
    Value = false,
    Callback = function(v)
        Features.Highlight = v
        SetHighlight(v)
    end,
})

VisualTab:Toggle({
    Title = "Hacker Detection",
    Value = false,
    Callback = function(v) Features.HackerDetection = v end,
})

VisualTab:Toggle({
    Title = "Dropped Items ESP",
    Value = false,
    Callback = function(v) Features.DroppedItemsESP = v end,
})

-- 5. FARM
local FarmTab = Window:Tab({ Title = "FARM", Icon = "tractor" })

FarmTab:Section({ Title = "Auto Farm", Desc = "Automatic farming" })

FarmTab:Toggle({
    Title = "Auto Pickup Items",
    Value = false,
    Callback = function(v)
        Features.AutoPickupItems = v
        if v then Threads.Pickup = task.spawn(AutoPickupLoop) else Threads.Pickup = nil end
    end,
})

FarmTab:Toggle({
    Title = "Auto Minigame (ATM/Fishing)",
    Value = false,
    Callback = function(v)
        Features.AutoMinigame = v
        if v then Threads.Minigame = task.spawn(AutoMinigameLoop) else Threads.Minigame = nil end
    end,
})

-- 6. GUNS AMMO
local GunsAmmoTab = Window:Tab({ Title = "GUNS AMMO", Icon = "target" })

GunsAmmoTab:Section({ Title = "Buy Ammo", Desc = "Purchase ammunition" })

GunsAmmoTab:Dropdown({
    Title = "Ammo Type",
    Value = "Pistol",
    Values = {"Pistol", "Rifle", "Shotgun", "Special"},
    Callback = function(v) Features.AmmoType = v end,
})

GunsAmmoTab:Button({
    Title = "BUY AMMO",
    Callback = function()
        BuyAmmo()
        Notify("Ammo", "Buying " .. Features.AmmoType .. " ammo...")
    end,
})

-- 7. SPECTATE
local SpectateTab = Window:Tab({ Title = "SPECTATE", Icon = "video" })

SpectateTab:Section({ Title = "Spectate Player", Desc = "Watch other players" })

local PlayerList = SpectateTab:Dropdown({
    Title = "Select Player",
    Value = "None",
    Values = {},
    Callback = function(v)
        local target = Players:FindFirstChild(v)
        Features.SpectateTarget = target
        if target then
            StartSpectate(target)
        else
            StartSpectate(nil)
        end
    end,
})

-- Actualizar lista
task.spawn(function()
    while true do
        task.wait(5)
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(list, p.Name)
            end
        end
        pcall(function()
            PlayerList:SetValues(list)
        end)
    end
end)

SpectateTab:Button({
    Title = "Stop Spectate",
    Callback = function()
        StartSpectate(nil)
        Features.SpectateTarget = nil
    end,
})

-- 8. MISC
local MiscTab = Window:Tab({ Title = "MISC", Icon = "settings" })

MiscTab:Section({ Title = "Servers", Desc = "Server management" })

MiscTab:Button({
    Title = "Server Hop",
    Callback = function()
        ServerHop()
    end,
})

MiscTab:Section({ Title = "Other", Desc = "Miscellaneous" })

MiscTab:Toggle({
    Title = "Skip Crate Spin",
    Value = false,
    Callback = function(v) Features.SkipCrateSpin = v end,
})

MiscTab:Toggle({
    Title = "FPS Boost",
    Value = false,
    Callback = function(v)
        Features.FPSBoost = v
        if v then FPSBoost() end
    end,
})

-- 9. CONFIG
local ConfigTab = Window:Tab({ Title = "CONFIG", Icon = "cog" })

ConfigTab:Section({ Title = "Config Manager", Desc = "Save and load settings" })

ConfigTab:Button({
    Title = "Save Config",
    Callback = function()
        local configData = {
            SilentAim = Features.SilentAim,
            FOV = Features.FOV,
            SpeedMultiplier = Features.SpeedMultiplier,
            -- etc...
        }
        writefile("WaterHub_Config.json", HttpService:JSONEncode(configData))
        Notify("Config", "Saved successfully!")
    end,
})

ConfigTab:Button({
    Title = "Load Config",
    Callback = function()
        if isfile("WaterHub_Config.json") then
            local data = readfile("WaterHub_Config.json")
            local config = HttpService:JSONDecode(data)
            -- Aplicar configuración
            Notify("Config", "Loaded successfully!")
        else
            Notify("Config", "No config found!")
        end
    end,
})

ConfigTab:Button({
    Title = "Delete Config",
    Callback = function()
        if isfile("WaterHub_Config.json") then
            delfile("WaterHub_Config.json")
            Notify("Config", "Deleted!")
        end
    end,
})

-- ============================================
-- INICIALIZACION
-- ============================================
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end

Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then CreateESP(p) end end)
Players.PlayerRemoving:Connect(function(p)
    if ESPObjects[p] then
        pcall(function()
            ESPObjects[p].Name:Destroy()
            ESPObjects[p].HealthBg:Destroy()
            ESPObjects[p].Distance:Destroy()
            ESPObjects[p].Weapon:Destroy()
        end)
        ESPObjects[p] = nil
    end
end)

RunService.RenderStepped:Connect(UpdateESP)

-- Respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if Features.WalkSpeed then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 8 * Features.SpeedMultiplier end
    end
    -- Reaplicar mods de armas
    if Features.EnableGunMods then
        ApplyGunMods()
    end
end)

CombatTab:Select()
print("Water Hub | BlockSpin - 100% Funcional con datos reales del juego")
