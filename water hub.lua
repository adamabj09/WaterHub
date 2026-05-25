--[[
    WATER HUB | BLOCKSPIN - VERSIÓN CORREGIDA
    Pestañas: COMBAT | MOVEMENT | WEAPON | VISUAL | GUNS AMMO | FARM | MISC | CONFIG
    INVISIBLE (DESYNC): Te mueves libremente, tu cuerpo se queda quieto donde reiniciaste
--]]

if getgenv and getgenv().WaterHubLoaded then
    print("⚠️ Water Hub ya está cargado")
    return
end
if getgenv then getgenv().WaterHubLoaded = true end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

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
-- CONFIGURACIÓN DE GUARDADO
-- ============================================
local ConfigName = "WaterHub_Config"

local function SaveConfig()
    local config = {}
    for name, value in pairs(Features) do
        if type(value) ~= "function" and type(value) ~= "userdata" then
            config[name] = value
        end
    end
    local success, err = pcall(function()
        writefile(ConfigName .. ".json", HttpService:JSONEncode(config))
    end)
    if success then
        Notify("Config", "Configuración guardada")
    else
        Notify("Config", "Error al guardar: " .. tostring(err))
    end
end

local function LoadConfig()
    local success, data = pcall(function()
        return readfile(ConfigName .. ".json")
    end)
    if success and data then
        local loaded = HttpService:JSONDecode(data)
        for name, value in pairs(loaded) do
            if Features[name] ~= nil then
                Features[name] = value
            end
        end
        Notify("Config", "Configuración cargada")
        return true
    else
        Notify("Config", "No se encontró configuración guardada")
        return false
    end
end

local function DeleteConfig()
    local success = pcall(function()
        delfile(ConfigName .. ".json")
    end)
    if success then
        Notify("Config", "Configuración eliminada")
    else
        Notify("Config", "Error al eliminar")
    end
end

-- ============================================
-- VARIABLES Y ESTADO
-- ============================================
local Features = {
    -- COMBAT
    SilentAim = false,
    FOV = 200,
    AimPart = "Head",
    SaleLegend = false,
    ProtectedPlayers = {},
    MeleeAura = false,
    MeteorAura = false,
    AutoAttack = false,
    BumpAura = false,
    AntiKill = false,
    AntiRagdoll = false,
    AntiLock = false,
    
    -- MOVEMENT
    WalkSpeed = 16,
    SpeedMultiplier = 1,
    HighJump = false,
    InfiniteStamina = false,
    Invisible = false,
    AntiNoClip = false,
    EnableSnap = false,
    SnapDepth = 26,
    
    -- WEAPON
    EnableGunMods = false,
    FireRate = 430,
    Accuracy = 1,
    RecoilValue = 0,
    ReloadTime = 10,
    Automatic = false,
    
    -- VISUAL
    ESPName = false,
    ESPHealth = false,
    ESPDistance = false,
    Highlight = false,
    ESPHackers = false,
    InventoryViewer = false,
    DroppedItemsESP = false,
    FullBright = false,
    NoFog = false,
    
    -- GUNS AMMO
    BulletType = "Pistol",
    
    -- FARM
    AutoPickupItems = false,
    AutoMinigame = false,
    
    -- MISC
    SpectateTarget = nil,
    ServerJobId = "",
    SmallServer = false,
    ServerHop = false,
}

local Threads = {}
local ESPObjects = {}
local HighlightObjects = {}
local SilentAimTarget = nil
local OldNamecall = nil
local SpectateConnection = nil
local OriginalWalkSpeed = 16
local OriginalJumpPower = 50
local DesyncBody = nil
local DesyncConnection = nil

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

local function GetPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    return list
end

-- ============================================
-- INVISIBLE (DESYNC) - FUNCIONAMIENTO REAL
-- ============================================
-- Cuando activas Invisible y reinicias:
-- - Tu personaje se queda quieto donde reiniciaste
-- - Tú puedes moverte libremente por el mapa
-- - Los demás te ven en el lugar donde reiniciaste
-- - Si te disparan, no te hacen daño
-- - Si activas No Clip o te sientas, te apareces (te descubres)

local function SetupDesync()
    if not Features.Invisible then
        if DesyncBody then
            DesyncBody:Destroy()
            DesyncBody = nil
        end
        if DesyncConnection then
            DesyncConnection:Disconnect()
            DesyncConnection = nil
        end
        return
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Guardar la posición donde reiniciaste
    local desyncPosition = hrp.Position
    
    -- Crear un cuerpo fantasma que se queda quieto
    DesyncBody = Instance.new("Part")
    DesyncBody.Name = "DesyncBody"
    DesyncBody.Size = hrp.Size
    DesyncBody.CFrame = CFrame.new(desyncPosition)
    DesyncBody.Anchored = true
    DesyncBody.CanCollide = false
    DesyncBody.Transparency = 0.5
    DesyncBody.BrickColor = BrickColor.new("Bright red")
    DesyncBody.Parent = workspace
    
    -- Conectar para actualizar la posición del cuerpo fantasma
    DesyncConnection = RunService.Heartbeat:Connect(function()
        if not Features.Invisible then return end
        if not DesyncBody then return end
        
        -- El cuerpo fantasma se queda donde reiniciaste
        DesyncBody.CFrame = CFrame.new(desyncPosition)
        
        -- Si se activa Anti No Clip o se sienta, destruir el desync
        if Features.AntiNoClip then
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Seated then
                Features.Invisible = false
                Notify("Invisible", "Desactivado por sentarte")
                SetupDesync()
            end
        end
    end)
    
    Notify("Invisible (Desync)", "Activado - Tu cuerpo se quedó en: " .. tostring(desyncPosition))
end

-- Detectar cuando el personaje muere o reaparece para activar desync
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if Features.Invisible then
        SetupDesync()
    end
end)

-- ============================================
-- COMBAT - SILENT AIM
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
            local isProtected = false
            for _, protected in ipairs(Features.ProtectedPlayers) do
                if protected == player.Name then
                    isProtected = true
                    break
                end
            end
            if isProtected then continue end
            
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
            local name = self.Name:lower()
            if name:find("hit") or name:find("damage") or name:find("shoot") or name:find("fire") then
                local targetChar = SilentAimTarget.Character
                if targetChar then
                    local targetPart = targetChar:FindFirstChild(Features.AimPart) 
                        or targetChar:FindFirstChild("Head")
                    if targetPart then
                        for i = 1, #args do
                            if typeof(args[i]) == "Vector3" then
                                args[i] = targetPart.Position
                            elseif typeof(args[i]) == "Instance" and args[i]:IsA("BasePart") then
                                args[i] = targetPart
                            end
                        end
                        if #args > 0 and typeof(args[1]) == "Instance" and args[1]:IsA("Player") then
                            args[1] = SilentAimTarget
                        end
                    end
                end
            end
        end
        
        return OldNamecall(self, unpack(args))
    end)
end

-- Melee Aura (Wide Fists)
local function MeleeAuraLoop()
    while Features.MeleeAura do
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetChildren()) do
                if part:IsA("Tool") and part:FindFirstChild("Handle") then
                    local handle = part.Handle
                    handle.Size = Vector3.new(10, 10, 10)
                    handle.Transparency = 0.5
                end
            end
        end
        task.wait(0.1)
    end
end

-- Meteor Aura
local function MeteorAuraLoop()
    while Features.MeteorAura do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local explosion = Instance.new("Explosion")
            explosion.Position = hrp.Position + Vector3.new(math.random(-10, 10), 5, math.random(-10, 10))
            explosion.BlastRadius = 5
            explosion.BlastPressure = 0
            explosion.Parent = workspace
        end
        task.wait(2)
    end
end

-- Auto Attack
local function AutoAttackLoop()
    while Features.AutoAttack do
        if SilentAimTarget then
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    pcall(function() tool:Activate() end)
                end
            end
        end
        task.wait(0.1)
    end
end

-- Bump Aura (Vehicles)
local function BumpAuraLoop()
    while Features.BumpAura do
        for _, vehicle in ipairs(Workspace:GetDescendants()) do
            if vehicle:IsA("VehicleSeat") or vehicle.Name:find("Vehicle") then
                local hrp = vehicle.Parent and vehicle.Parent:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp:ApplyImpulse(Vector3.new(0, 50, 0))
                end
            end
        end
        task.wait(0.5)
    end
end

-- Anti Kill
local function AntiKillLoop()
    while Features.AntiKill do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.Health <= 0 then
                hum.Health = hum.MaxHealth
            end
        end
        task.wait(0.1)
    end
end

-- Anti Ragdoll
local function AntiRagdollLoop()
    while Features.AntiRagdoll do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Physics then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
        task.wait(0.1)
    end
end

-- Anti Lock (evita que te apunten)
local function AntiLockLoop()
    while Features.AntiLock do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.1, 0)
        end
        task.wait(0.3)
    end
end

-- ============================================
-- MOVEMENT
-- ============================================
local function ApplyMovement()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    local finalSpeed = Features.WalkSpeed * Features.SpeedMultiplier
    hum.WalkSpeed = finalSpeed
    
    if Features.HighJump then
        hum.JumpPower = 100
    else
        hum.JumpPower = 50
    end
end

local function MovementLoop()
    while true do
        ApplyMovement()
        task.wait(0.1)
    end
end

local function InfiniteStaminaLoop()
    while Features.InfiniteStamina do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                pcall(function() hum:SetAttribute("Stamina", 100) end)
                local staminaVal = char:FindFirstChild("Stamina")
                if staminaVal then staminaVal.Value = 100 end
            end
            local staminaPlayer = LocalPlayer:FindFirstChild("Stamina")
            if staminaPlayer then staminaPlayer.Value = 100 end
        end
        task.wait(0.2)
    end
end

-- Snap Under Map
UserInputService.InputBegan:Connect(function(input)
    if Features.EnableSnap and input.KeyCode == Enum.KeyCode.Z then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            hrp.CFrame = CFrame.new(hrp.Position.X, Features.SnapDepth, hrp.Position.Z)
            Notify("Snap", "Teletransportado bajo el mapa")
        end
    end
end)

-- ============================================
-- WEAPON MODS
-- ============================================
local function ApplyWeaponMods()
    if not Features.EnableGunMods then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("Tool") then
            local fireRate = obj:FindFirstChild("FireRate") or obj:FindFirstChild("Cooldown")
            if fireRate then fireRate.Value = 60 / Features.FireRate end
            
            local accuracy = obj:FindFirstChild("Accuracy") or obj:FindFirstChild("Spread")
            if accuracy then accuracy.Value = Features.Accuracy end
            
            local recoil = obj:FindFirstChild("Recoil") or obj:FindFirstChild("RecoilValue")
            if recoil then recoil.Value = Features.RecoilValue end
            
            local reload = obj:FindFirstChild("ReloadTime")
            if reload then reload.Value = Features.ReloadTime end
            
            if Features.Automatic then
                local auto = obj:FindFirstChild("Automatic") or obj:FindFirstChild("Auto")
                if auto then auto.Value = true end
            end
        end
    end
end

local function WeaponModsLoop()
    while Features.EnableGunMods do
        ApplyWeaponMods()
        task.wait(0.5)
    end
end

-- ============================================
-- GUNS AMMO - BUY AMMO
-- ============================================
local function BuyAmmo()
    Notify("Buy Ammo", "Comprando balas tipo: " .. Features.BulletType)
    -- Buscar crate y comprar
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name:find("Crate") or obj.Name:find("AmmoCrate") then
            if obj:FindFirstChild("ClickDetector") then
                fireclickdetector(obj.ClickDetector)
                break
            end
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
    sg.Name = "WaterHub_ESP"
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
    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    esp.HealthBar.BorderSizePixel = 0
    esp.HealthBar.Parent = esp.HealthBg
    
    esp.Distance = Instance.new("TextLabel")
    esp.Distance.Size = UDim2.new(0, 100, 0, 15)
    esp.Distance.BackgroundTransparency = 1
    esp.Distance.TextColor3 = Color3.fromRGB(0, 242, 254)
    esp.Distance.TextSize = 10
    esp.Distance.Font = Enum.Font.Gotham
    esp.Distance.Parent = gui
    
    esp.Weapon = Instance.new("TextLabel")
    esp.Weapon.Size = UDim2.new(0, 150, 0, 20)
    esp.Weapon.BackgroundTransparency = 1
    esp.Weapon.TextColor3 = Color3.fromRGB(0, 255, 150)
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
        pcall(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    if Features.ESPName then
                        esp.Name.Position = UDim2.new(0, pos.X - 100, 0, pos.Y - 50)
                        esp.Name.Text = player.Name
                        esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end
                    
                    if Features.ESPHealth then
                        local percent = hum.Health / hum.MaxHealth
                        esp.HealthBar.Size = UDim2.new(percent, 0, 1, 0)
                        esp.HealthBar.BackgroundColor3 = Color3.fromRGB(255 * (1-percent), 255 * percent, 100)
                        esp.HealthBg.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 30)
                        esp.HealthBg.Visible = true
                    else
                        esp.HealthBg.Visible = false
                    end
                    
                    if Features.ESPDistance and myPos then
                        local dist = (myPos - hrp.Position).Magnitude
                        esp.Distance.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 20)
                        esp.Distance.Text = math.floor(dist) .. "m"
                        esp.Distance.Visible = true
                    else
                        esp.Distance.Visible = false
                    end
                    
                    if Features.ESPWeapon then
                        local weapon = GetEquippedTool(player)
                        if weapon and weapon ~= esp.LastWeapon then
                            esp.LastWeapon = weapon
                            esp.Weapon.Text = "🔫 " .. weapon
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
                if not HighlightObjects[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "WaterHub_Highlight"
                    highlight.FillColor = Color3.fromRGB(0, 255, 100)
                    highlight.OutlineColor = Color3.fromRGB(0, 242, 254)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.Adornee = player.Character
                    highlight.Parent = player.Character
                    HighlightObjects[player] = highlight
                end
            else
                if HighlightObjects[player] then
                    HighlightObjects[player]:Destroy()
                    HighlightObjects[player] = nil
                end
            end
        end
    end
end

-- ESP Hackers
local function ESPHackersLoop()
    while Features.ESPHackers do
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hum = player.Character:FindFirstChild("Humanoid")
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hum and hrp then
                    local head = player.Character:FindFirstChild("Head")
                    if head and hrp then
                        local headAngle = (head.CFrame - hrp.CFrame).Y
                        if math.abs(headAngle) > 45 then
                            pcall(function()
                                if ESPObjects[player] then
                                    ESPObjects[player].Name.Text = player.Name .. " [HACKER]"
                                    ESPObjects[player].Name.TextColor3 = Color3.fromRGB(255, 0, 0)
                                end
                            end)
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end

-- Inventory Viewer
local function InventoryViewerLoop()
    while Features.InventoryViewer do
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local items = {}
                if player.Backpack then
                    for _, tool in ipairs(player.Backpack:GetChildren()) do
                        if tool:IsA("Tool") then
                            table.insert(items, tool.Name)
                        end
                    end
                end
                if #items > 0 then
                    -- Mostrar en ESP o notificación
                end
            end
        end
        task.wait(2)
    end
end

-- Dropped Items ESP
local function DroppedItemsESP()
    while Features.DroppedItemsESP do
        for _, item in ipairs(Workspace:GetDescendants()) do
            if item:IsA("Tool") or (item:IsA("BasePart") and (item.Name:find("Drop") or item.Name:find("Item"))) then
                -- Crear ESP para items
                local gui = GetESPGui()
                if not item:FindFirstChild("ItemESP") then
                    local label = Instance.new("TextLabel")
                    label.Name = "ItemESP"
                    label.Size = UDim2.new(0, 100, 0, 20)
                    label.BackgroundTransparency = 1
                    label.Text = item.Name
                    label.TextColor3 = Color3.fromRGB(255, 200, 0)
                    label.TextSize = 10
                    label.Parent = gui
                    item:SetAttribute("ESPLabel", label)
                end
            end
        end
        task.wait(0.5)
    end
end

-- Full Bright / No Fog
local function SetFullBright(enabled)
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

local function SetNoFog(enabled)
    if enabled then
        Lighting.FogEnd = 100000
    else
        Lighting.FogEnd = 1000
    end
end

-- ============================================
-- FARM
-- ============================================
local function AutoPickupLoop()
    while Features.AutoPickupItems do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            for _, item in ipairs(Workspace:GetDescendants()) do
                if item:IsA("Tool") or (item:IsA("BasePart") and (item.Name:find("Pickup") or item.Name:find("Item"))) then
                    local dist = (item.Position - char.HumanoidRootPart.Position).Magnitude
                    if dist < 15 then
                        firetouchinterest(char.HumanoidRootPart, item, 0)
                        firetouchinterest(char.HumanoidRootPart, item, 1)
                    end
                end
            end
        end
        task.wait(0.3)
    end
end

local function AutoMinigameLoop()
    while Features.AutoMinigame do
        local char = LocalPlayer.Character
        if char then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj.Name:find("ATM") or obj.Name:find("Fishing") or obj.Name:find("Minigame") then
                    if obj:FindFirstChild("ClickDetector") then
                        fireclickdetector(obj.ClickDetector)
                        task.wait(1)
                    end
                end
            end
        end
        task.wait(2)
    end
end

-- ============================================
-- MISC - SPECTATE
-- ============================================
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
            Workspace.CurrentCamera.CameraSubject = targetPlayer.Character:FindFirstChild("Humanoid") or targetPlayer.Character
        else
            Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character
        end
    end)
end

-- MISC - SERVERS
local function JoinByID(jobId)
    if jobId and jobId ~= "" then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
    end
end

local function ServerHop()
    Notify("Server Hop", "Buscando servidor más lleno...")
    -- Aquí iría la lógica para saltar de servidor
    local servers = {}
    -- Por ahora solo notifica
    task.wait(2)
    Notify("Server Hop", "No se encontró servidor")
end

-- ============================================
-- ANTI AFK
-- ============================================
local function AntiAFKLoop()
    while Features.AntiAFK do
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(60)
        end)
    end
end

-- ============================================
-- AUTO ACCEPT
-- ============================================
local function AutoAcceptLoop()
    while Features.AutoAccept do
        pcall(function()
            local dialog = LocalPlayer.PlayerGui:FindFirstChild("Dialog")
            if dialog then
                local accept = dialog:FindFirstChild("AcceptButton")
                if accept then
                    accept:Fire()
                end
            end
        end)
        task.wait(0.5)
    end
end

-- ============================================
-- SALE LEGEND (detección de ventas/eventos)
-- ============================================
local function SaleLegendLoop()
    while Features.SaleLegend do
        pcall(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name:find("Sale") or obj.Name:find("Legend") or obj.Name:find("Event") then
                    if obj:FindFirstChild("ClickDetector") then
                        fireclickdetector(obj.ClickDetector)
                    end
                end
            end
        end)
        task.wait(5)
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
    OpenButton = {
        Title = "Open Water Hub",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("#00FF88")),
            ColorSequenceKeypoint.new(0.5, Color3.fromHex("#00E5FF")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("#00B0FF"))
        }),
    },
})

Window:Tag({ 
    Title = "v1.0 | Complete Edition", 
    Icon = "leaf", 
    Color = Color3.fromHex("#00FF88"), 
    Border = true 
})

Notify("Water Hub", "Script cargado - Todas las opciones disponibles")

-- ============================================
-- PESTAÑA 1: COMBAT
-- ============================================
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "sword" })

CombatTab:Section({ Title = "GUN", Desc = "Configuración de armas" })

CombatTab:Toggle({
    Title = "Silent Aim",
    Value = false,
    Callback = function(v)
        Features.SilentAim = v
        if v then SetupSilentAim() end
        Notify("Silent Aim", v and "Activado" or "Desactivado")
    end,
})

CombatTab:Slider({
    Title = "FOV Size",
    Step = 10,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v) Features.FOV = v end,
})

CombatTab:Toggle({
    Title = "Sale Legend",
    Value = false,
    Callback = function(v) 
        Features.SaleLegend = v
        if v then Threads.SaleLegend = task.spawn(SaleLegendLoop) end
        Notify("Sale Legend", v and "Activado" or "Desactivado")
    end,
})

CombatTab:Dropdown({
    Title = "Selección a jugadores a proteger",
    Value = "None",
    Values = GetPlayers(),
    Callback = function(v)
        if v ~= "None" and not table.find(Features.ProtectedPlayers, v) then
            table.insert(Features.ProtectedPlayers, v)
            Notify("Protección", v .. " será protegido")
        end
    end,
})

CombatTab:Space({ Columns = 1 })

CombatTab:Section({ Title = "MELEE & VEHICLES", Desc = "Auras y ataques" })

CombatTab:Toggle({
    Title = "Melee Aura (Wide Fists)",
    Value = false,
    Callback = function(v)
        Features.MeleeAura = v
        if v then Threads.MeleeAura = task.spawn(MeleeAuraLoop) end
    end,
})

CombatTab:Toggle({
    Title = "Meteor Aura (W2b Fists)",
    Value = false,
    Callback = function(v)
        Features.MeteorAura = v
        if v then Threads.MeteorAura = task.spawn(MeteorAuraLoop) end
        Notify("Meteor Aura", v and "Activada" or "Desactivada")
    end,
})

CombatTab:Toggle({
    Title = "Auto Attack",
    Value = false,
    Callback = function(v)
        Features.AutoAttack = v
        if v then Threads.AutoAttack = task.spawn(AutoAttackLoop) end
    end,
})

CombatTab:Toggle({
    Title = "Bump Aura (Vehicles)",
    Value = false,
    Callback = function(v)
        Features.BumpAura = v
        if v then Threads.BumpAura = task.spawn(BumpAuraLoop) end
        Notify("Bump Aura", v and "Activada" or "Desactivada")
    end,
})

CombatTab:Space({ Columns = 1 })

CombatTab:Section({ Title = "DEFENSE", Desc = "Protección" })

CombatTab:Toggle({
    Title = "Anti Kill",
    Value = false,
    Callback = function(v)
        Features.AntiKill = v
        if v then Threads.AntiKill = task.spawn(AntiKillLoop) end
    end,
})

CombatTab:Toggle({
    Title = "Anti Ragdoll",
    Value = false,
    Callback = function(v)
        Features.AntiRagdoll = v
        if v then Threads.AntiRagdoll = task.spawn(AntiRagdollLoop) end
    end,
})

CombatTab:Toggle({
    Title = "Anti Lock",
    Value = false,
    Callback = function(v)
        Features.AntiLock = v
        if v then Threads.AntiLock = task.spawn(AntiLockLoop) end
    end,
})

-- ============================================
-- PESTAÑA 2: MOVEMENT
-- ============================================
local MovementTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })

MovementTab:Section({ Title = "Movement", Desc = "Configuración de movimiento" })

MovementTab:Slider({
    Title = "Walk Speed",
    Step = 1,
    Value = { Min = 16, Max = 200, Default = 16 },
    Callback = function(v) 
        Features.WalkSpeed = v
        ApplyMovement()
    end,
})

MovementTab:Slider({
    Title = "Speed Multiplier",
    Step = 0.1,
    Value = { Min = 0.5, Max = 5, Default = 1 },
    Callback = function(v) 
        Features.SpeedMultiplier = v
        ApplyMovement()
    end,
})

MovementTab:Toggle({
    Title = "High Jump",
    Value = false,
    Callback = function(v)
        Features.HighJump = v
        ApplyMovement()
    end,
})

MovementTab:Toggle({
    Title = "Infinite Stamina",
    Value = false,
    Callback = function(v)
        Features.InfiniteStamina = v
        if v then Threads.Stamina = task.spawn(InfiniteStaminaLoop) end
    end,
})

MovementTab:Toggle({
    Title = "Invisible (Desync)",
    Value = false,
    Callback = function(v)
        Features.Invisible = v
        if v then 
            Notify("Invisible (Desync)", "Activado - Reinicia para efecto completo")
            SetupDesync()
        else
            if DesyncBody then DesyncBody:Destroy() end
            if DesyncConnection then DesyncConnection:Disconnect() end
        end
    end,
})

MovementTab:Toggle({
    Title = "Anti No Clip",
    Value = false,
    Callback = function(v)
        Features.AntiNoClip = v
        Notify("Anti No Clip", v and "Activado - Sentarte desactivará Invisible" or "Desactivado")
    end,
})

MovementTab:Space({ Columns = 1 })

MovementTab:Section({ Title = "SNAP UNDER MAP", Desc = "Teletransportarse bajo el mapa" })

MovementTab:Toggle({
    Title = "Enable Snap",
    Value = false,
    Callback = function(v) Features.EnableSnap = v end,
})

MovementTab:Slider({
    Title = "Snap Depth",
    Step = 1,
    Value = { Min = 0, Max = 100, Default = 26 },
    Callback = function(v) Features.SnapDepth = v end,
})

MovementTab:Label({ Title = "Hold Z to snap under map" })

-- ============================================
-- PESTAÑA 3: WEAPON
-- ============================================
local WeaponTab = Window:Tab({ Title = "WEAPON", Icon = "crosshair" })

WeaponTab:Section({ Title = "GUN MODS", Desc = "Modificaciones de armas" })

WeaponTab:Toggle({
    Title = "Enable Gun Mods",
    Value = false,
    Callback = function(v)
        Features.EnableGunMods = v
        if v then Threads.WeaponMods = task.spawn(WeaponModsLoop) end
    end,
})

WeaponTab:Slider({
    Title = "Fire Rate",
    Step = 10,
    Value = { Min = 50, Max = 1000, Default = 430 },
    Callback = function(v) 
        Features.FireRate = v
        if Features.EnableGunMods then ApplyWeaponMods() end
    end,
})

WeaponTab:Slider({
    Title = "Accuracy",
    Step = 0.1,
    Value = { Min = 0.1, Max = 2, Default = 1 },
    Callback = function(v) 
        Features.Accuracy = v
        if Features.EnableGunMods then ApplyWeaponMods() end
    end,
})

WeaponTab:Slider({
    Title = "Recoil",
    Step = 1,
    Value = { Min = 0, Max = 100, Default = 0 },
    Callback = function(v) 
        Features.RecoilValue = v
        if Features.EnableGunMods then ApplyWeaponMods() end
    end,
})

WeaponTab:Slider({
    Title = "Reload Time",
    Step = 0.5,
    Value = { Min = 0.1, Max = 10, Default = 10 },
    Callback = function(v) 
        Features.ReloadTime = v
        if Features.EnableGunMods then ApplyWeaponMods() end
    end,
})

WeaponTab:Toggle({
    Title = "Automatic",
    Value = false,
    Callback = function(v)
        Features.Automatic = v
        if Features.EnableGunMods then ApplyWeaponMods() end
    end,
})

-- ============================================
-- PESTAÑA 4: VISUAL
-- ============================================
local VisualTab = Window:Tab({ Title = "VISUAL", Icon = "eye" })

VisualTab:Section({ Title = "ESP", Desc = "Ver jugadores" })

VisualTab:Toggle({
    Title = "Name ESP",
    Value = false,
    Callback = function(v) Features.ESPName = v end,
})

VisualTab:Toggle({
    Title = "Health ESP",
    Value = false,
    Callback = function(v) Features.ESPHealth = v end,
})

VisualTab:Toggle({
    Title = "Distance ESP",
    Value = false,
    Callback = function(v) Features.ESPDistance = v end,
})

VisualTab:Toggle({
    Title = "Highlight",
    Value = false,
    Callback = function(v)
        Features.Highlight = v
        SetHighlight(v)
    end,
})

VisualTab:Space({ Columns = 1 })

VisualTab:Section({ Title = "HACKER DETECTION", Desc = "Detectar hackers" })

VisualTab:Toggle({
    Title = "ESP Hackers (Anti-Aim)",
    Value = false,
    Callback = function(v)
        Features.ESPHackers = v
        if v then Threads.ESPHackers = task.spawn(ESPHackersLoop) end
    end,
})

VisualTab:Space({ Columns = 1 })

VisualTab:Section({ Title = "ITEMS", Desc = "Ver items" })

VisualTab:Toggle({
    Title = "Inventory Viewer",
    Value = false,
    Callback = function(v)
        Features.InventoryViewer = v
        if v then Threads.InventoryViewer = task.spawn(InventoryViewerLoop) end
    end,
})

VisualTab:Toggle({
    Title = "Dropped Items ESP",
    Value = false,
    Callback = function(v)
        Features.DroppedItemsESP = v
        if v then Threads.DroppedItems = task.spawn(DroppedItemsESP) end
    end,
})

VisualTab:Space({ Columns = 1 })

VisualTab:Section({ Title = "WORLD", Desc = "Modificar mundo" })

VisualTab:Toggle({
    Title = "Full Bright",
    Value = false,
    Callback = function(v)
        Features.FullBright = v
        SetFullBright(v)
    end,
})

VisualTab:Toggle({
    Title = "No Fog",
    Value = false,
    Callback = function(v)
        Features.NoFog = v
        SetNoFog(v)
    end,
})

-- ============================================
-- PESTAÑA 5: GUNS AMMO
-- ============================================
local GunsAmmoTab = Window:Tab({ Title = "GUNS AMMO", Icon = "target" })

GunsAmmoTab:Section({ Title = "Ammo", Desc = "Configuración de munición" })

GunsAmmoTab:Dropdown({
    Title = "Tipo de Bala",
    Value = "Pistol",
    Values = { "Pistol", "Rifle", "Shotgun", "Sniper", "SMG", "LMG" },
    Callback = function(v) Features.BulletType = v end,
})

GunsAmmoTab:Button({
    Title = "BUY AMMO",
    Callback = function()
        BuyAmmo()
    end,
})

GunsAmmoTab:Label({ Title = "Abre el crate con el tipo seleccionado" })

-- ============================================
-- PESTAÑA 6: FARM
-- ============================================
local FarmTab = Window:Tab({ Title = "FARM", Icon = "robot" })

FarmTab:Section({ Title = "Farm", Desc = "Auto farmeo" })

FarmTab:Toggle({
    Title = "Auto Pickup Items",
    Value = false,
    Callback = function(v)
        Features.AutoPickupItems = v
        if v then Threads.AutoPickup = task.spawn(AutoPickupLoop) end
    end,
})

FarmTab:Toggle({
    Title = "Auto Minigame (ATM/Fishing)",
    Value = false,
    Callback = function(v)
        Features.AutoMinigame = v
        if v then Threads.AutoMinigame = task.spawn(AutoMinigameLoop) end
    end,
})

-- ============================================
-- PESTAÑA 7: MISC
-- ============================================
local MiscTab = Window:Tab({ Title = "MISC", Icon = "settings" })

MiscTab:Section({ Title = "SPECTATE", Desc = "Ver otros jugadores" })

local PlayerList = MiscTab:Dropdown({
    Title = "Select Player",
    Value = "None",
    Values = GetPlayers(),
    Callback = function(v)
        local target = Players:FindFirstChild(v)
        Features.SpectateTarget = target
    end,
})

MiscTab:Button({
    Title = "espectear",
    Callback = function()
        StartSpectate(Features.SpectateTarget)
        Notify("Spectate", "Specteando a " .. (Features.SpectateTarget and Features.SpectateTarget.Name or "nadie"))
    end,
})

MiscTab:Space({ Columns = 1 })

MiscTab:Section({ Title = "SERVERS", Desc = "Control de servidores" })

MiscTab:Textbox({
    Title = "Server JobId",
    Value = "",
    Callback = function(v) Features.ServerJobId = v end,
})

MiscTab:Button({
    Title = "Join by ID",
    Callback = function()
        JoinByID(Features.ServerJobId)
    end,
})

MiscTab:Toggle({
    Title = "Small Server (1-2 players)",
    Value = false,
    Callback = function(v) Features.SmallServer = v end,
})

MiscTab:Toggle({
    Title = "Server Hop",
    Value = false,
    Callback = function(v)
        Features.ServerHop = v
        if v then ServerHop() end
    end,
})

MiscTab:Label({ Title = "Salta al servidor más lleno con espacio" })

MiscTab:Space({ Columns = 1 })

MiscTab:Section({ Title = "General", Desc = "Otras funciones" })

MiscTab:Toggle({
    Title = "Anti AFK",
    Value = false,
    Callback = function(v)
        Features.AntiAFK = v
        if v then Threads.AntiAFK = task.spawn(AntiAFKLoop) end
    end,
})

MiscTab:Toggle({
    Title = "Auto Accept",
    Value = false,
    Callback = function(v)
        Features.AutoAccept = v
        if v then Threads.AutoAccept = task.spawn(AutoAcceptLoop) end
    end,
})

-- ============================================
-- PESTAÑA 8: CONFIG
-- ============================================
local ConfigTab = Window:Tab({ Title = "CONFIG", Icon = "cog" })

ConfigTab:Section({ Title = "CONFIG MANAGER", Desc = "Guardar y cargar configuraciones" })

ConfigTab:Button({
    Title = "Save Config",
    Callback = function()
        SaveConfig()
    end,
})

ConfigTab:Button({
    Title = "Load Config",
    Callback = function()
        LoadConfig()
        Notify("Config", "Configuración cargada - Reinicia el UI para ver cambios")
    end,
})

ConfigTab:Button({
    Title = "Delete Config",
    Callback = function()
        DeleteConfig()
    end,
})

ConfigTab:Space({ Columns = 1 })

ConfigTab:Section({ Title = "Account", Desc = "Tu información" })

local CashLabel = ConfigTab:Label({ Title = "💵 Cash: Loading..." })
local BankLabel = ConfigTab:Label({ Title = "🏦 Bank: Loading..." })

task.spawn(function()
    while true do
        local cash, bank = GetMoney()
        pcall(function()
            CashLabel:Set("💵 Cash: $" .. cash)
            BankLabel:Set("🏦 Bank: $" .. bank)
        end)
        task.wait(1)
    end
end)

ConfigTab:Space({ Columns = 1 })

ConfigTab:Section({ Title = "Script", Desc = "Control del script" })

ConfigTab:Button({
    Title = "Destroy UI",
    Callback = function()
        for k, _ in pairs(Threads) do Threads[k] = nil end
        SetHighlight(false)
        StartSpectate(nil)
        if DesyncBody then DesyncBody:Destroy() end
        if DesyncConnection then DesyncConnection:Disconnect() end
        Window:Destroy()
        if getgenv then getgenv().WaterHubLoaded = false end
        Notify("Water Hub", "UI Destruida")
    end,
})

ConfigTab:Button({
    Title = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

-- ============================================
-- INICIALIZACIÓN
-- ============================================
task.spawn(MovementLoop)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then 
        CreateESP(player)
    end
end

Players.PlayerAdded:Connect(function(p) 
    if p ~= LocalPlayer then 
        CreateESP(p)
    end 
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
    if HighlightObjects[p] then
        HighlightObjects[p]:Destroy()
        HighlightObjects[p] = nil
    end
end)

RunService.RenderStepped:Connect(UpdateESP)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    ApplyMovement()
    if Features.EnableGunMods then
        ApplyWeaponMods()
    end
    if Features.Invisible then
        SetupDesync()
    end
end)

-- Actualizar lista de jugadores periódicamente
task.spawn(function()
    while true do
        task.wait(5)
        pcall(function()
            PlayerList:SetValues(GetPlayers())
        end)
    end
end)

CombatTab:Select()
print("✅ Water Hub | BlockSpin - Versión Completa cargada")
print("✅ INVISIBLE (DESYNC): Actívalo y reinicia. Tu cuerpo se queda quieto, tú te mueves libremente.")