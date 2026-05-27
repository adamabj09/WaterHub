--[[
    WATER HUB | BLOCKSPIN - VERSION FINAL COMPLETA
    Todas las funciones corregidas según especificaciones
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
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

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
-- CONFIGURACIÓN INICIAL
-- ============================================
local ConfigFile = "WaterHub_BlockSpin_v2.json"

local Features = {
    -- COMBAT (Todo OFF por defecto)
    SilentAim = false,
    ShowFOV = false,
    FOV = 150,
    AimPart = "Head",
    SafeZone = false,
    MeleeAura = false,
    AutoAttack = false,
    AntiKill = false,
    AntiKillHealth = 20,
    AntiRagdoll = false,
    AntiLock = false,
    
    -- MOVEMENT
    WalkSpeed = false,
    SpeedValue = 50,
    SuperJump = false,
    JumpPower = 100,
    InfiniteStamina = false,
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
    DroppedItemsESP = false,
    ESPColors = {
        Common = Color3.fromRGB(169, 169, 169),      -- Gris
        Rare = Color3.fromRGB(0, 112, 221),          -- Azul
        Epic = Color3.fromRGB(163, 53, 238),         -- Morado
        Legendary = Color3.fromRGB(255, 140, 0),     -- Naranja
        Mythic = Color3.fromRGB(255, 105, 180),      -- Rosa
        Money = Color3.fromRGB(0, 255, 0)             -- Verde
    },
    
    -- FARM
    AutoPickup = false,
    AutoATM = false,
    AutoDeposit = false,
    SelectedJob = "None",
    AutoFarmJob = false,
    
    -- GUNS AMMO
    AmmoType = "Pistol",
    
    -- UI
    ThemeColor = Color3.fromHex("#00F2FE")
}

-- Cargar configuración al inicio
local function LoadConfig()
    if isfile(ConfigFile) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigFile))
        end)
        if success and data then
            for key, value in pairs(data) do
                if Features[key] ~= nil then
                    Features[key] = value
                end
            end
        end
    end
end

LoadConfig() -- Cargar al inicio

-- ============================================
-- VARIABLES GLOBALES
-- ============================================
local Threads = {}
local ESPObjects = {}
local ItemESPObjects = {}
local ChamsObjects = {}
local SilentAimTarget = nil
local OldNamecall = nil
local FOVCircle = nil
local AntiKillConnection = nil

-- ============================================
-- REMOTES REALES
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
-- FOV CIRCLE (FIJO EN CENTRO DE PANTALLA)
-- ============================================
local function CreateFOVCircle()
    if FOVCircle then FOVCircle:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FOVCircle"
    screenGui.Parent = gethui()
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    
    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0) -- Centro fijo
    circle.Size = UDim2.new(0, Features.FOV * 2, 0, Features.FOV * 2)
    circle.BackgroundTransparency = 1
    circle.Parent = screenGui
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Features.ThemeColor
    stroke.Thickness = 2
    stroke.Parent = circle
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle
    
    -- Número del FOV en el centro
    local label = Instance.new("TextLabel")
    label.Name = "FOVLabel"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(Features.FOV)
    label.TextColor3 = Features.ThemeColor
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.Parent = circle
    
    FOVCircle = screenGui
    screenGui.Enabled = Features.ShowFOV and Features.SilentAim
end

local function UpdateFOVSize()
    if FOVCircle then
        local circle = FOVCircle:FindFirstChild("Circle")
        if circle then
            circle.Size = UDim2.new(0, Features.FOV * 2, 0, Features.FOV * 2)
            local label = circle:FindFirstChild("FOVLabel")
            if label then
                label.Text = tostring(Features.FOV)
            end
        end
    end
end

-- ============================================
-- SILENT AIM (APUNTA AUTOMÁTICO)
-- ============================================
local function GetClosestPlayerToCenter()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    
    local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
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
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local dist = (screenCenter - screenPos).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    
    return closest
end

-- Hook para Silent Aim
local function SetupSilentAim()
    if OldNamecall then return end
    
    OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if Features.SilentAim and method == "FireServer" then
            if self == SendRemote then
                local target = GetClosestPlayerToCenter()
                if target and target.Character then
                    local targetPart = target.Character:FindFirstChild(Features.AimPart) 
                        or target.Character:FindFirstChild("Head")
                    
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

-- Loop de Aimbot
RunService.RenderStepped:Connect(function()
    if not Features.SilentAim then return end
    
    SilentAimTarget = GetClosestPlayerToCenter()
    
    if SilentAimTarget and SilentAimTarget.Character then
        local targetPart = SilentAimTarget.Character:FindFirstChild(Features.AimPart) 
            or SilentAimTarget.Character:FindFirstChild("Head")
        
        if targetPart then
            local cam = Workspace.CurrentCamera
            cam.CFrame = CFrame.new(cam.CFrame.Position, targetPart.Position)
        end
    end
end)

-- ============================================
-- ANTI KILL (SIN NOTIFICACIONES SPAM)
-- ============================================
local LastHealthNotified = 100

local function AntiKillFunction()
    if not Features.AntiKill then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if hum and hrp then
        local healthPercent = (hum.Health / hum.MaxHealth) * 100
        
        -- Solo notificar si cambió significativamente
        if math.abs(LastHealthNotified - healthPercent) > 10 then
            LastHealthNotified = healthPercent
        end
        
        if healthPercent <= Features.AntiKillHealth then
            -- Teletransportar debajo del mapa usando Tween (anti-detección)
            local targetPos = Vector3.new(hrp.Position.X, -Features.SnapDepth, hrp.Position.Z)
            
            local tween = TweenService:Create(hrp, TweenInfo.new(0.5), {CFrame = CFrame.new(targetPos)})
            tween:Play()
        end
    end
end

-- ============================================
-- MOVIMIENTO
-- ============================================
local function WalkSpeedLoop()
    while Features.WalkSpeed do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = Features.SpeedValue
            end
        end
        task.wait(0.1)
    end
    -- Reset
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

local function SuperJumpLoop()
    while Features.SuperJump do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.JumpPower = Features.JumpPower
                -- Auto-salto
                if hum.FloorMaterial ~= Enum.Material.Air then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
        task.wait(0.3)
    end
    -- Reset
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.JumpPower = 50 end
    end
end

local function InfiniteStaminaLoop()
    while Features.InfiniteStamina do
        local char = LocalPlayer.Character
        if char then
            local stamina = char:FindFirstChild("Stamina")
            if stamina and stamina:IsA("NumberValue") then
                stamina.Value = 125
            end
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum:SetAttribute("Stamina", 125)
            end
        end
        task.wait(0.2)
    end
end

-- ============================================
-- SNAP UNDER MAP (BOTÓN ON/OFF)
-- ============================================
local function ToggleSnapUnderMap()
    if not Features.SnapUnderMap then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local targetPos = Vector3.new(hrp.Position.X, -Features.SnapDepth, hrp.Position.Z)
    local tween = TweenService:Create(hrp, TweenInfo.new(0.5), {CFrame = CFrame.new(targetPos)})
    tween:Play()
    
    Notify("Snap", "Teleported under map")
end

-- ============================================
-- ESP DE ITEMS EN EL SUELO (CON RAREZA)
-- ============================================
local function GetItemRarity(itemName)
    itemName = itemName:lower()
    
    -- Míticos (rosa)
    if itemName:find("golden") or itemName:find("diamond") or itemName:find("legendary") then
        return "Mythic"
    end
    
    -- Legendarios (naranja)
    if itemName:find("rare") or itemName:find("epic") or itemName:find("special") then
        return "Legendary"
    end
    
    -- Épicos (morado)
    if itemName:find("uncommon") or itemName:find("good") then
        return "Epic"
    end
    
    -- Raros (azul)
    if itemName:find("box") or itemName:find("crate") then
        return "Rare"
    end
    
    -- Dinero (verde)
    if itemName:find("cash") or itemName:find("money") or itemName:find("$") then
        return "Money"
    end
    
    -- Común (gris)
    return "Common"
end

local function CreateItemESP(item)
    if ItemESPObjects[item] then return end
    
    local rarity = GetItemRarity(item.Name)
    local color = Features.ESPColors[rarity] or Features.ESPColors.Common
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ItemESP_" .. item.Name
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.Parent = gethui()
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = color
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.Text = item.Name
    label.Parent = billboard
    
    -- Símbolo de dinero
    if rarity == "Money" then
        label.Text = "$ " .. item.Name
    end
    
    billboard.Adornee = item
    ItemESPObjects[item] = billboard
end

local function UpdateItemsESP()
    if not Features.DroppedItemsESP then return end
    
    for _, item in ipairs(Workspace:GetDescendants()) do
        if item:IsA("BasePart") and (item.Name:find("Cash") or item.Name:find("Money") or item.Name:find("Box") or item:GetAttribute("Item")) then
            if not ItemESPObjects[item] then
                CreateItemESP(item)
            end
        end
    end
end

-- ============================================
-- ESP DE JUGADORES
-- ============================================
local function CreatePlayerESP(player)
    if ESPObjects[player] then return end
    
    local esp = {}
    
    -- Name
    esp.Name = Instance.new("TextLabel")
    esp.Name.Size = UDim2.new(0, 200, 0, 20)
    esp.Name.BackgroundTransparency = 1
    esp.Name.TextColor3 = Features.ThemeColor
    esp.Name.TextSize = 12
    esp.Name.Font = Enum.Font.GothamBold
    esp.Name.Parent = gethui()
    
    -- Health Bar
    esp.HealthBg = Instance.new("Frame")
    esp.HealthBg.Size = UDim2.new(0, 100, 0, 6)
    esp.HealthBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    esp.HealthBg.BorderSizePixel = 0
    esp.HealthBg.Parent = gethui()
    
    esp.HealthBar = Instance.new("Frame")
    esp.HealthBar.Size = UDim2.new(1, 0, 1, 0)
    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    esp.HealthBar.BorderSizePixel = 0
    esp.HealthBar.Parent = esp.HealthBg
    
    -- Distance
    esp.Distance = Instance.new("TextLabel")
    esp.Distance.Size = UDim2.new(0, 100, 0, 15)
    esp.Distance.BackgroundTransparency = 1
    esp.Distance.TextColor3 = Color3.fromRGB(200, 200, 200)
    esp.Distance.TextSize = 10
    esp.Distance.Font = Enum.Font.Gotham
    esp.Distance.Parent = gethui()
    
    -- Weapon
    esp.Weapon = Instance.new("TextLabel")
    esp.Weapon.Size = UDim2.new(0, 150, 0, 20)
    esp.Weapon.BackgroundTransparency = 1
    esp.Weapon.TextColor3 = Color3.fromRGB(255, 200, 100)
    esp.Weapon.TextSize = 10
    esp.Weapon.Font = Enum.Font.GothamBold
    esp.Weapon.Parent = gethui()
    
    ESPObjects[player] = esp
end

local function UpdatePlayerESP()
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

-- ============================================
-- FARM - TRABAJOS ESPECÍFICOS
-- ============================================
local JobLocations = {
    Janitor = Workspace:FindFirstChild("BurgePlaceBeacon") and Workspace.BurgePlaceBeacon:FindFirstChild("TouchPart"),
    ShelfStocker = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Tiles") and Workspace.Map.Tiles:FindFirstChild("GasStationTile") and Workspace.Map.Tiles.GasStationTile:FindFirstChild("Quick11") and Workspace.Map.Tiles.GasStationTile.Quick11:FindFirstChild("Interior") and Workspace.Map.Tiles.GasStationTile.Quick11.Interior:FindFirstChild("Quick11Beacon") and Workspace.Map.Tiles.GasStationTile.Quick11.Interior.Quick11Beacon:FindFirstChild("TouchPart"),
    SteakhouseCook = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Tiles") and Workspace.Map.Tiles:FindFirstChild("ShoppingTile") and Workspace.Map.Tiles.ShoppingTile:FindFirstChild("SteakHouse") and Workspace.Map.Tiles.ShoppingTile.SteakHouse:FindFirstChild("Interior") and Workspace.Map.Tiles.ShoppingTile.SteakHouse.Interior:FindFirstChild("SteakHouseBeacon") and Workspace.Map.Tiles.ShoppingTile.SteakHouse.Interior.SteakHouseBeacon:FindFirstChild("TouchPart")
}

local function TweenToPosition(targetPos, duration)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local tween = TweenService:Create(hrp, TweenInfo.new(duration or 2, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
    tween:Play()
    return tween
end

local function AutoFarmJanitor()
    -- Buscar charcos cercanos y limpiarlos
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:find("Puddle") and obj:IsA("BasePart") then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local dist = (obj.Position - char.HumanoidRootPart.Position).Magnitude
                if dist < 50 then
                    TweenToPosition(obj.Position + Vector3.new(0, 0, 3), 2)
                    task.wait(2.5)
                    -- Limpiar (usar mopa)
                    local tool = char:FindFirstChild("Mop")
                    if tool then
                        tool:Activate()
                    end
                end
            end
        end
    end
end

local function AutoFarmShelfStocker()
    -- Buscar cajas y estantes
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:find("Box") and obj:IsA("BasePart") then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local dist = (obj.Position - char.HumanoidRootPart.Position).Magnitude
                if dist < 50 then
                    TweenToPosition(obj.Position + Vector3.new(0, 0, 3), 2)
                    task.wait(2.5)
                end
            end
        end
    end
end

local function AutoFarmSteakhouse()
    -- Ir a la parrilla
    local grill = Workspace:FindFirstChild("GrillArea") or Workspace:FindFirstChild("Grill")
    if grill then
        TweenToPosition(grill.Position + Vector3.new(0, 0, 5), 3)
    end
end

local function AutoFarmLoop()
    while Features.AutoFarmJob do
        if Features.SelectedJob == "Janitor" then
            AutoFarmJanitor()
        elseif Features.SelectedJob == "ShelfStocker" then
            AutoFarmShelfStocker()
        elseif Features.SelectedJob == "SteakhouseCook" then
            AutoFarmSteakhouse()
        end
        task.wait(5)
    end
end

-- ============================================
-- AUTO PICKUP Y AUTO ATM
-- ============================================
local function AutoPickupLoop()
    while Features.AutoPickup do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Pickup items
            for _, item in ipairs(Workspace:GetDescendants()) do
                if item:IsA("BasePart") and (item.Name:find("Cash") or item.Name:find("Money") or item:GetAttribute("Item")) then
                    if (item.Position - hrp.Position).Magnitude < 15 then
                        TweenToPosition(item.Position, 0.5)
                        if item:FindFirstChild("ClickDetector") then
                            fireclickdetector(item.ClickDetector)
                        end
                    end
                end
            end
            
            -- Auto ATM
            if Features.AutoATM then
                for _, atm in ipairs(Workspace.Map.Props.ATMs:GetDescendants()) do
                    if atm:IsA("ProximityPrompt") then
                        local parent = atm.Parent
                        if parent and parent:IsA("BasePart") then
                            if (parent.Position - hrp.Position).Magnitude < 10 then
                                fireproximityprompt(atm)
                            end
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end

-- ============================================
-- GUNS AMMO
-- ============================================
local function BuyAmmo()
    local ammoCrate = Workspace:FindFirstChild("Map") 
        and Workspace.Map:FindFirstChild("Tiles") 
        and Workspace.Map.Tiles:FindFirstChild("GunShopTile") 
        and Workspace.Map.Tiles.GunShopTile:FindFirstChild("PatriotWeapons") 
        and Workspace.Map.Tiles.GunShopTile.PatriotWeapons:FindFirstChild("Interior") 
        and Workspace.Map.Tiles.GunShopTile.PatriotWeapons.Interior:FindFirstChild("Crates") 
        and Workspace.Map.Tiles.GunShopTile.PatriotWeapons.Interior.Crates:FindFirstChild("Ammo Crate")
    
    if not ammoCrate then
        Notify("Error", "Ammo Crate not found")
        return
    end
    
    local options = ammoCrate:FindFirstChild("CrateOptions")
    if not options then return end
    
    local selected = options:FindFirstChild(Features.AmmoType)
    if selected and selected:FindFirstChild("ProximityPrompt") then
        -- Moverse al crate primero
        local touchPart = ammoCrate:FindFirstChild("TESTBEACON") and ammoCrate.TESTBEACON:FindFirstChild("TouchPart")
        if touchPart then
            TweenToPosition(touchPart.Position, 2)
            task.wait(2.5)
        end
        
        fireproximityprompt(selected.ProximityPrompt)
        Notify("Ammo", "Buying " .. Features.AmmoType .. " ammo...")
    end
end

-- ============================================
-- SERVER HOP
-- ============================================
local function ServerHop()
    local PlaceID = game.PlaceId
    local url = "https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100"
    
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and result then
        local data = HttpService:JSONDecode(result)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(PlaceID, server.id, LocalPlayer)
                    return
                end
            end
        end
    end
    Notify("Error", "No servers found")
end

-- ============================================
-- FPS BOOST
-- ============================================
local function FPSBoost()
    Lighting.GlobalShadows = false
    Lighting.Technology = Enum.Technology.Compatibility
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") then
            obj.Enabled = false
        end
    end
end

-- ============================================
-- GUARDAR CONFIGURACIÓN
-- ============================================
local function SaveConfig()
    local dataToSave = {
        SilentAim = Features.SilentAim,
        ShowFOV = Features.ShowFOV,
        FOV = Features.FOV,
        AimPart = Features.AimPart,
        WalkSpeed = Features.WalkSpeed,
        SpeedValue = Features.SpeedValue,
        SuperJump = Features.SuperJump,
        JumpPower = Features.JumpPower,
        InfiniteStamina = Features.InfiniteStamina,
        SnapUnderMap = Features.SnapUnderMap,
        SnapDepth = Features.SnapDepth,
        EnableGunMods = Features.EnableGunMods,
        FireRate = Features.FireRate,
        Recoil = Features.Recoil,
        ReloadTime = Features.ReloadTime,
        NameESP = Features.NameESP,
        HealthESP = Features.HealthESP,
        DistanceESP = Features.DistanceESP,
        DroppedItemsESP = Features.DroppedItemsESP,
        AutoPickup = Features.AutoPickup,
        AutoATM = Features.AutoATM,
        ThemeColor = Features.ThemeColor
    }
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(dataToSave)
    end)
    
    if success then
        writefile(ConfigFile, encoded)
        Notify("Config", "Saved!")
    end
end

-- ============================================
-- VENTANA PRINCIPAL CON COLOR PERSONALIZABLE
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
    OpenButton = {
        Title = "Open",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
        Color = ColorSequence.new(Features.ThemeColor, Features.ThemeColor),
    },
})

-- ============================================
-- PESTAÑAS
-- ============================================

-- 1. COMBAT
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "sword" })

CombatTab:Section({ Title = "Aimbot", Desc = "Auto targeting" })

CombatTab:Toggle({
    Title = "Silent Aim",
    Value = Features.SilentAim,
    Callback = function(v)
        Features.SilentAim = v
        if v then SetupSilentAim() end
        SaveConfig()
    end,
})

CombatTab:Toggle({
    Title = "Show FOV Circle",
    Value = Features.ShowFOV,
    Callback = function(v)
        Features.ShowFOV = v
        if v then CreateFOVCircle() elseif FOVCircle then FOVCircle:Destroy() end
        SaveConfig()
    end,
})

CombatTab:Slider({
    Title = "FOV Size",
    Step = 10,
    Value = { Min = 50, Max = 500, Default = Features.FOV },
    Callback = function(v)
        Features.FOV = v
        UpdateFOVSize()
        SaveConfig()
    end,
})

CombatTab:Dropdown({
    Title = "Aim Part",
    Value = Features.AimPart,
    Values = {"Head", "Torso", "HumanoidRootPart"},
    Callback = function(v)
        Features.AimPart = v
        SaveConfig()
    end,
})

CombatTab:Section({ Title = "Defense", Desc = "Protection" })

CombatTab:Toggle({
    Title = "Anti Kill",
    Value = Features.AntiKill,
    Callback = function(v)
        Features.AntiKill = v
        if v then
            AntiKillConnection = RunService.Heartbeat:Connect(AntiKillFunction)
        else
            if AntiKillConnection then AntiKillConnection:Disconnect() end
        end
        SaveConfig()
    end,
})

CombatTab:Slider({
    Title = "Anti Kill Health %",
    Step = 5,
    Value = { Min = 5, Max = 50, Default = Features.AntiKillHealth },
    Callback = function(v)
        Features.AntiKillHealth = v
        SaveConfig()
    end,
})

-- 2. MOVEMENT
local MovementTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })

MovementTab:Section({ Title = "Speed", Desc = "Walk speed modifier" })

MovementTab:Toggle({
    Title = "Walk Speed",
    Value = Features.WalkSpeed,
    Callback = function(v)
        Features.WalkSpeed = v
        if v then Threads.Speed = task.spawn(WalkSpeedLoop) else Threads.Speed = nil end
        SaveConfig()
    end,
})

MovementTab:Slider({
    Title = "Speed Value",
    Step = 5,
    Value = { Min = 16, Max = 200, Default = Features.SpeedValue },
    Callback = function(v)
        Features.SpeedValue = v
        SaveConfig()
    end,
})

MovementTab:Section({ Title = "Jump & Stamina", Desc = "Movement extras" })

MovementTab:Toggle({
    Title = "Super Jump",
    Value = Features.SuperJump,
    Callback = function(v)
        Features.SuperJump = v
        if v then Threads.Jump = task.spawn(SuperJumpLoop) else Threads.Jump = nil end
        SaveConfig()
    end,
})

MovementTab:Slider({
    Title = "Jump Power",
    Step = 10,
    Value = { Min = 50, Max = 200, Default = Features.JumpPower },
    Callback = function(v)
        Features.JumpPower = v
        SaveConfig()
    end,
})

MovementTab:Toggle({
    Title = "Infinite Stamina",
    Value = Features.InfiniteStamina,
    Callback = function(v)
        Features.InfiniteStamina = v
        if v then Threads.Stamina = task.spawn(InfiniteStaminaLoop) else Threads.Stamina = nil end
        SaveConfig()
    end,
})

MovementTab:Section({ Title = "Snap", Desc = "Teleport under map" })

MovementTab:Toggle({
    Title = "Snap Under Map",
    Value = Features.SnapUnderMap,
    Callback = function(v)
        Features.SnapUnderMap = v
        if v then ToggleSnapUnderMap() end
        SaveConfig()
    end,
})

MovementTab:Slider({
    Title = "Snap Depth",
    Step = 5,
    Value = { Min = 10, Max = 100, Default = Features.SnapDepth },
    Callback = function(v)
        Features.SnapDepth = v
        SaveConfig()
    end,
})

-- 3. WEAPON
local WeaponTab = Window:Tab({ Title = "WEAPON", Icon = "crosshair" })

WeaponTab:Section({ Title = "Gun Mods", Desc = "Modify weapon stats" })

WeaponTab:Toggle({
    Title = "Enable Gun Mods",
    Value = Features.EnableGunMods,
    Callback = function(v)
        Features.EnableGunMods = v
        ApplyGunMods()
        SaveConfig()
    end,
})

WeaponTab:Slider({
    Title = "Fire Rate",
    Step = 50,
    Value = { Min = 50, Max = 2000, Default = Features.FireRate },
    Callback = function(v)
        Features.FireRate = v
        ApplyGunMods()
        SaveConfig()
    end,
})

WeaponTab:Slider({
    Title = "Recoil",
    Step = 0.1,
    Value = { Min = 0, Max = 3, Default = Features.Recoil },
    Callback = function(v)
        Features.Recoil = v
        ApplyGunMods()
        SaveConfig()
    end,
})

WeaponTab:Slider({
    Title = "Reload Time",
    Step = 0.1,
    Value = { Min = 0.1, Max = 5, Default = Features.ReloadTime },
    Callback = function(v)
        Features.ReloadTime = v
        ApplyGunMods()
        SaveConfig()
    end,
})

-- 4. VISUAL
local VisualTab = Window:Tab({ Title = "VISUAL", Icon = "eye" })

VisualTab:Section({ Title = "Player ESP", Desc = "See players through walls" })

VisualTab:Toggle({
    Title = "Name ESP",
    Value = Features.NameESP,
    Callback = function(v)
        Features.NameESP = v
        SaveConfig()
    end,
})

VisualTab:Toggle({
    Title = "Health ESP",
    Value = Features.HealthESP,
    Callback = function(v)
        Features.HealthESP = v
        SaveConfig()
    end,
})

VisualTab:Toggle({
    Title = "Distance ESP",
    Value = Features.DistanceESP,
    Callback = function(v)
        Features.DistanceESP = v
        SaveConfig()
    end,
})

VisualTab:Section({ Title = "Items ESP", Desc = "See items on ground" })

VisualTab:Toggle({
    Title = "Dropped Items ESP",
    Value = Features.DroppedItemsESP,
    Callback = function(v)
        Features.DroppedItemsESP = v
        SaveConfig()
    end,
})

-- 5. FARM
local FarmTab = Window:Tab({ Title = "FARM", Icon = "tractor" })

FarmTab:Section({ Title = "Auto Farm", Desc = "Automatic farming" })

FarmTab:Toggle({
    Title = "Auto Pickup Items",
    Value = Features.AutoPickup,
    Callback = function(v)
        Features.AutoPickup = v
        if v then Threads.Pickup = task.spawn(AutoPickupLoop) else Threads.Pickup = nil end
        SaveConfig()
    end,
})

FarmTab:Toggle({
    Title = "Auto ATM",
    Value = Features.AutoATM,
    Callback = function(v)
        Features.AutoATM = v
        SaveConfig()
    end,
})

FarmTab:Section({ Title = "Jobs", Desc = "Select job to farm" })

FarmTab:Dropdown({
    Title = "Select Job",
    Value = Features.SelectedJob,
    Values = {"None", "Janitor", "ShelfStocker", "SteakhouseCook"},
    Callback = function(v)
        Features.SelectedJob = v
        SaveConfig()
    end,
})

FarmTab:Toggle({
    Title = "Auto Farm Job",
    Value = Features.AutoFarmJob,
    Callback = function(v)
        Features.AutoFarmJob = v
        if v then Threads.Farm = task.spawn(AutoFarmLoop) else Threads.Farm = nil end
        SaveConfig()
    end,
})

-- 6. GUNS AMMO
local GunsAmmoTab = Window:Tab({ Title = "GUNS AMMO", Icon = "target" })

GunsAmmoTab:Section({ Title = "Buy Ammo", Desc = "Purchase ammunition" })

GunsAmmoTab:Dropdown({
    Title = "Ammo Type",
    Value = Features.AmmoType,
    Values = {"Pistol", "Rifle", "Shotgun", "Special"},
    Callback = function(v)
        Features.AmmoType = v
        SaveConfig()
    end,
})

GunsAmmoTab:Button({
    Title = "BUY AMMO",
    Callback = function()
        BuyAmmo()
    end,
})

-- 7. SPECTATE
local SpectateTab = Window:Tab({ Title = "SPECTATE", Icon = "video" })

SpectateTab:Section({ Title = "Spectate Player", Desc = "Watch other players" })

local PlayerDropdown = SpectateTab:Dropdown({
    Title = "Select Player",
    Value = "None",
    Values = {},
    Callback = function(v)
        local target = Players:FindFirstChild(v)
        if target and target.Character then
            local hum = target.Character:FindFirstChild("Humanoid")
            if hum then
                Workspace.CurrentCamera.CameraSubject = hum
            end
        end
    end,
})

-- Actualizar lista
task.spawn(function()
    while true do
        task.wait(3)
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                table.insert(list, p.Name)
            end
        end
        pcall(function()
            PlayerDropdown:SetValues(list)
        end)
    end
end)

SpectateTab:Button({
    Title = "Stop Spectate",
    Callback = function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum then
            Workspace.CurrentCamera.CameraSubject = hum
        end
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

MiscTab:Section({ Title = "Performance", Desc = "FPS boost" })

MiscTab:Toggle({
    Title = "FPS Boost",
    Value = Features.FPSBoost,
    Callback = function(v)
        Features.FPSBoost = v
        if v then FPSBoost() end
        SaveConfig()
    end,
})

-- 9. CONFIG
local ConfigTab = Window:Tab({ Title = "CONFIG", Icon = "cog" })

ConfigTab:Section({ Title = "Settings", Desc = "Save your configuration" })

ConfigTab:Button({
    Title = "Save Config",
    Callback = function()
        SaveConfig()
    end,
})

ConfigTab:Button({
    Title = "Delete Config",
    Callback = function()
        if isfile(ConfigFile) then
            delfile(ConfigFile)
            Notify("Config", "Deleted!")
        end
    end,
})

ConfigTab:Section({ Title = "Theme", Desc = "Customize colors" })

-- Color Picker simple
ConfigTab:Button({
    Title = "Set Theme Color (Cyan)",
    Callback = function()
        Features.ThemeColor = Color3.fromRGB(0, 242, 254)
        SaveConfig()
        Notify("Theme", "Color changed! Restart script to apply.")
    end,
})

ConfigTab:Button({
    Title = "Set Theme Color (Red)",
    Callback = function()
        Features.ThemeColor = Color3.fromRGB(255, 0, 0)
        SaveConfig()
        Notify("Theme", "Color changed! Restart script to apply.")
    end,
})

ConfigTab:Button({
    Title = "Set Theme Color (Green)",
    Callback = function()
        Features.ThemeColor = Color3.fromRGB(0, 255, 0)
        SaveConfig()
        Notify("Theme", "Color changed! Restart script to apply.")
    end,
})

-- ============================================
-- INICIALIZACIÓN
-- ============================================
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreatePlayerESP(player) end
end

Players.PlayerAdded:Connect(function(p) 
    if p ~= LocalPlayer then CreatePlayerESP(p) end 
end)

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

-- Update loops
RunService.RenderStepped:Connect(function()
    UpdatePlayerESP()
    UpdateItemsESP()
end)

-- Auto-load features
if Features.SilentAim and Features.ShowFOV then CreateFOVCircle() end
if Features.SilentAim then SetupSilentAim() end
if Features.AntiKill then AntiKillConnection = RunService.Heartbeat:Connect(AntiKillFunction) end

CombatTab:Select()

print("Water Hub | BlockSpin - Loaded Successfully")
print("All features are OFF by default. Activate manually.")
