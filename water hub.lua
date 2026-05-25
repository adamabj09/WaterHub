--[[
    WATER HUB | BLOCKSPIN - VERSIÓN AUTO-ADAPTABLE
    Características:
    - Aimbot con línea visual a la cabeza
    - Auto-detección de armas, eventos y estructuras del juego
    - Sin NoClip, Fly ni AutoFarm (eliminados)
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
-- AUTO-ADAPTACIÓN: DETECCIÓN DEL JUEGO
-- ============================================
local GameData = {
    Name = game.PlaceId or "Unknown",
    RemotesPath = nil,
    DamageEvent = nil,
    HealEvent = nil,
    WeaponNames = {},
    JobParts = {},
    ATMParts = {},
    MoneyStats = {},
}

-- Detectar automáticamente la estructura del juego
local function AutoDetectGame()
    -- Detectar RemoteEvents
    local function findRemotes(folder)
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                local name = child.Name:lower()
                if name:find("damage") or name:find("hit") or name:find("attack") then
                    GameData.DamageEvent = child
                elseif name:find("heal") or name:find("health") then
                    GameData.HealEvent = child
                end
            elseif child:IsA("Folder") or child:IsA("Model") then
                findRemotes(child)
            end
        end
    end
    
    -- Buscar en ReplicatedStorage
    findRemotes(ReplicatedStorage)
    
    -- Detectar estadísticas de dinero
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            local name = stat.Name:lower()
            if name:find("cash") or name:find("money") or name:find("coin") then
                GameData.MoneyStats.cash = stat
            elseif name:find("bank") then
                GameData.MoneyStats.bank = stat
            end
        end
    end
    
    -- Detectar partes de trabajos
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            local name = part.Name:lower()
            if name:find("puddle") or name:find("mess") or name:find("dirt") then
                table.insert(GameData.JobParts, part)
            elseif name:find("atm") or name:find("bank") then
                table.insert(GameData.ATMParts, part)
            end
        end
    end
    
    Notify("Auto-Detect", "Juego detectado: " .. game.PlaceId)
end

-- ============================================
-- ARMAS DETECTADAS AUTOMÁTICAMENTE
-- ============================================
local Weapons = {}

local function DetectWeapons()
    -- Buscar armas en el jugador y su mochila
    local function scanForWeapons(container)
        for _, obj in ipairs(container:GetChildren()) do
            if obj:IsA("Tool") then
                local weaponData = {
                    name = obj.Name,
                    tool = obj,
                    damage = 10,
                    cooldown = 0.5,
                    range = 10
                }
                
                -- Intentar obtener daño del arma
                local damageVal = obj:FindFirstChild("Damage") or obj:FindFirstChild("DamageValue")
                if damageVal then
                    weaponData.damage = tonumber(damageVal.Value) or 10
                end
                
                -- Intentar obtener cooldown
                local cdVal = obj:FindFirstChild("Cooldown") or obj:FindFirstChild("FireRate")
                if cdVal then
                    weaponData.cooldown = tonumber(cdVal.Value) or 0.5
                end
                
                -- Intentar obtener rango
                local rangeVal = obj:FindFirstChild("Range") or obj:FindFirstChild("Reach")
                if rangeVal then
                    weaponData.range = tonumber(rangeVal.Value) or 10
                end
                
                -- Evitar duplicados
                local found = false
                for _, w in ipairs(Weapons) do
                    if w.name == weaponData.name then
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(Weapons, weaponData)
                end
            end
        end
    end
    
    scanForWeapons(LocalPlayer.Backpack)
    local char = LocalPlayer.Character
    if char then
        scanForWeapons(char)
    end
    
    if #Weapons == 0 then
        -- Armas por defecto si no se detectan
        Weapons = {
            { name = "Sword", damage = 15, cooldown = 0.8, range = 4 },
            { name = "Bow", damage = 10, cooldown = 1.2, range = 30 },
            { name = "Staff", damage = 25, cooldown = 2.5, range = 15 }
        }
    end
end

-- ============================================
-- VARIABLES Y ESTADO
-- ============================================
local Features = {
    -- Combat (Aimbot)
    AimbotEnabled = false,
    AimbotFOV = 200,
    AimbotPart = "Head",
    AimbotVisible = true,
    AimbotLine = true,
    AimbotLineColor = Color3.fromRGB(0, 255, 100),
    AutoHeal = false,
    HealPercent = 70,
    AutoHit = false,
    HitboxExpander = false,
    InfiniteStamina = false,
    -- Weapon
    NoRecoil = false,
    NoSpread = false,
    RapidFire = false,
    InstantReload = false,
    InfiniteAmmo = false,
    -- Visual
    ESPName = false,
    ESPHealth = false,
    ESPDistance = false,
    ESPWeapon = false,
    ESPBox = false,
    ESPSkeleton = false,
    Chams = false,
    FullBright = false,
    NoFog = false,
    -- Auto
    AutoATM = false,
    AutoDeposit = false,
    SelectedJob = "None",
    -- Spectate
    SpectateTarget = nil,
    -- Misc
    AntiAFK = false,
    AutoAccept = false,
    -- Damage System
    DamageMultiplier = 1,
    ShowDamageNumbers = false,
}

local Threads = {}
local ESPObjects = {}
local ChamsObjects = {}
local AimbotTarget = nil
local OldNamecall = nil
local SpectateConnection = nil
local InfiniteJumpConnection = nil
local AimbotLines = {}  -- Para las líneas de aimbot

-- ============================================
-- FUNCIONES UTILIDAD
-- ============================================
local function GetMoney()
    local cash, bank = 0, 0
    if GameData.MoneyStats.cash then
        cash = tonumber(GameData.MoneyStats.cash.Value) or 0
    end
    if GameData.MoneyStats.bank then
        bank = tonumber(GameData.MoneyStats.bank.Value) or 0
    end
    return cash, bank
end

local function GetEquippedTool(player)
    local char = player.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or nil
end

local function GetCurrentWeapon()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return nil, nil end
    
    for _, w in ipairs(Weapons) do
        if tool.Name == w.name or tool.Name:lower():find(w.name:lower()) then
            return w, tool
        end
    end
    return nil, tool
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
-- AIMBOT CON LÍNEA VISUAL
-- ============================================
local function CreateAimbotLine(target)
    if not Features.AimbotLine then return end
    
    -- Eliminar línea anterior
    if AimbotLines.line then
        AimbotLines.line:Destroy()
        AimbotLines.line = nil
    end
    
    if not target or not target.Character then return end
    
    local targetPart = target.Character:FindFirstChild(Features.AimbotPart) or target.Character:FindFirstChild("Head")
    if not targetPart then return end
    
    local line = Instance.new("LineHandleAdornment")
    line.Name = "AimbotLine"
    line.Color3 = Features.AimbotLineColor
    line.Thickness = 2
    line.AlwaysOnTop = true
    line.ZIndex = 0
    line.Parent = targetPart
    
    AimbotLines.line = line
    AimbotLines.target = target
end

local function UpdateAimbotLine()
    if not Features.AimbotLine then
        if AimbotLines.line then
            AimbotLines.line:Destroy()
            AimbotLines.line = nil
        end
        return
    end
    
    if not AimbotLines.line or not AimbotLines.target or not AimbotLines.target.Character then
        if AimbotLines.line then
            AimbotLines.line:Destroy()
            AimbotLines.line = nil
        end
        return
    end
    
    local myChar = LocalPlayer.Character
    local targetChar = AimbotLines.target.Character
    
    if myChar and myChar:FindFirstChild("HumanoidRootPart") and targetChar:FindFirstChild(Features.AimbotPart) then
        local startPos = myChar.HumanoidRootPart.Position
        local endPos = targetChar[Features.AimbotPart].Position
        AimbotLines.line.PointA = startPos
        AimbotLines.line.PointB = endPos
        AimbotLines.line.Visible = true
    else
        AimbotLines.line.Visible = false
    end
end

-- Aimbot - Selecciona objetivo
RunService.RenderStepped:Connect(function()
    if not Features.AimbotEnabled then
        if AimbotLines.line then
            AimbotLines.line:Destroy()
            AimbotLines.line = nil
        end
        AimbotTarget = nil
        return
    end
    
    local mouse = LocalPlayer:GetMouse()
    local cam = Workspace.CurrentCamera
    if not mouse or not cam then return end
    
    local closest = nil
    local shortestDist = Features.AimbotFOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(Features.AimbotPart) 
                or player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            
            if targetPart and humanoid and humanoid.Health > 0 then
                local pos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                if onScreen or not Features.AimbotVisible then
                    local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    
    AimbotTarget = closest
    CreateAimbotLine(AimbotTarget)
end)

-- Actualizar línea continuamente
RunService.RenderStepped:Connect(UpdateAimbotLine)

-- Silent Aim con hook
local function SetupSilentAim()
    if OldNamecall then return end
    
    OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if Features.AimbotEnabled and method == "FireServer" and AimbotTarget then
            local name = self.Name:lower()
            if name:find("hit") or name:find("damage") or name:find("shoot") or name:find("fire") or name:find("attack") then
                local targetChar = AimbotTarget.Character
                if targetChar then
                    local targetPart = targetChar:FindFirstChild(Features.AimbotPart) 
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
                        if #args > 0 and typeof(args[1]) == "Instance" and args[1]:IsA("Player") then
                            args[1] = AimbotTarget
                        end
                    end
                end
            end
        end
        
        return OldNamecall(self, unpack(args))
    end)
end

-- Hitbox Expander
local function SetHitboxExpanded(enabled)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if enabled then
                    hrp.Size = Vector3.new(10, 10, 10)
                    hrp.Transparency = 0.7
                    hrp.CanCollide = false
                else
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                end
            end
        end
    end
end

-- Auto Heal
local function AutoHealLoop()
    while Features.AutoHeal do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                local healthPercent = (hum.Health / hum.MaxHealth) * 100
                if healthPercent < Features.HealPercent then
                    if GameData.HealEvent then
                        GameData.HealEvent:FireServer()
                    end
                    hum.Health = hum.MaxHealth
                    Notify("Auto Heal", "Curado al " .. Features.HealPercent .. "%")
                end
            end
        end
        task.wait(0.5)
    end
end

-- Auto Hit
local function AutoHitLoop()
    while Features.AutoHit do
        if AimbotTarget then
            local char = LocalPlayer.Character
            if char then
                local weapon, tool = GetCurrentWeapon()
                local targetChar = AimbotTarget.Character
                
                if tool then
                    pcall(function() tool:Activate() end)
                end
                
                if weapon and weapon.cooldown then
                    task.wait(weapon.cooldown)
                else
                    task.wait(0.2)
                end
            end
        end
        task.wait(0.1)
    end
end

-- Infinite Stamina
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

-- ============================================
-- WEAPON MODS
-- ============================================
local function ApplyWeaponMods()
    local char = LocalPlayer.Character
    if not char then return end
    
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("Tool") then
            if Features.NoRecoil then
                local recoil = obj:FindFirstChild("Recoil") or obj:FindFirstChild("RecoilValue")
                if recoil then recoil.Value = 0 end
            end
            if Features.NoSpread then
                local spread = obj:FindFirstChild("Spread") or obj:FindFirstChild("SpreadValue")
                if spread then spread.Value = 0 end
            end
            if Features.RapidFire then
                local fireRate = obj:FindFirstChild("FireRate") or obj:FindFirstChild("Cooldown")
                if fireRate then fireRate.Value = 0.01 end
            end
            if Features.InstantReload then
                local reload = obj:FindFirstChild("ReloadTime")
                if reload then reload.Value = 0.01 end
            end
        end
    end
end

-- Infinite Ammo
local function InfiniteAmmoLoop()
    while Features.InfiniteAmmo do
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("Clip") or tool:FindFirstChild("Magazine")
                if ammo and ammo:IsA("IntValue") then
                    ammo.Value = 999
                end
            end
        end
        task.wait(0.1)
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
    
    esp.Box = Instance.new("Frame")
    esp.Box.Size = UDim2.new(0, 50, 0, 100)
    esp.Box.BackgroundTransparency = 0.5
    esp.Box.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    esp.Box.BorderSizePixel = 1
    esp.Box.BorderColor3 = Color3.fromRGB(0, 242, 254)
    esp.Box.Parent = gui
    
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
                    local size = 50 / (pos.Z / 10)
                    size = math.clamp(size, 20, 100)
                    
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
                    
                    if Features.ESPBox then
                        esp.Box.Size = UDim2.new(0, size, 0, size * 2)
                        esp.Box.Position = UDim2.new(0, pos.X - size/2, 0, pos.Y - size)
                        esp.Box.Visible = true
                    else
                        esp.Box.Visible = false
                    end
                else
                    esp.Name.Visible = false
                    esp.HealthBg.Visible = false
                    esp.Distance.Visible = false
                    esp.Weapon.Visible = false
                    esp.Box.Visible = false
                end
            else
                esp.Name.Visible = false
                esp.HealthBg.Visible = false
                esp.Distance.Visible = false
                esp.Weapon.Visible = false
                esp.Box.Visible = false
            end
        end)
    end
end

-- Chams
local function SetChams(enabled)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if enabled then
                if not ChamsObjects[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "WaterHub_Chams"
                    highlight.FillColor = Color3.fromRGB(0, 255, 100)
                    highlight.OutlineColor = Color3.fromRGB(0, 242, 254)
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
-- AUTO ATM
-- ============================================
local function AutoATMLoop()
    while Features.AutoATM do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            for _, atm in ipairs(GameData.ATMParts) do
                if atm and atm:FindFirstChild("ClickDetector") then
                    local dist = (atm.Position - char.HumanoidRootPart.Position).Magnitude
                    if dist < 10 then
                        fireclickdetector(atm.ClickDetector)
                        Notify("Auto ATM", "Usando ATM...")
                        task.wait(2)
                    end
                end
            end
        end
        task.wait(1)
    end
end

-- ============================================
-- SPECTATE
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

-- ============================================
-- MISC
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
    Title = "v4.0 | Aimbot Visual | Auto-Adaptable", 
    Icon = "leaf", 
    Color = Color3.fromHex("#00FF88"), 
    Border = true 
})

Notify("Water Hub", "Script cargado - Auto-adaptable")

-- ============================================
-- PESTAÑA 1: AIMBOT
-- ============================================
local AimbotTab = Window:Tab({ Title = "AIMBOT", Icon = "crosshair" })

AimbotTab:Section({ Title = "Aimbot Config", Desc = "Configuración del apuntado" })

AimbotTab:Toggle({
    Title = "Enable Aimbot",
    Value = false,
    Callback = function(v)
        Features.AimbotEnabled = v
        if v then SetupSilentAim() end
        Notify("Aimbot", v and "Activado" or "Desactivado")
    end,
})

AimbotTab:Slider({
    Title = "FOV",
    Step = 10,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v) Features.AimbotFOV = v end,
})

AimbotTab:Dropdown({
    Title = "Aim Part",
    Value = "Head",
    Values = { "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso" },
    Callback = function(v) Features.AimbotPart = v end,
})

AimbotTab:Toggle({
    Title = "Visible Check",
    Value = true,
    Callback = function(v) Features.AimbotVisible = v end,
})

AimbotTab:Space({ Columns = 1 })

AimbotTab:Section({ Title = "Visual Line", Desc = "Línea que apunta a la cabeza" })

AimbotTab:Toggle({
    Title = "Show Aimbot Line",
    Value = true,
    Callback = function(v)
        Features.AimbotLine = v
        if not v and AimbotLines.line then
            AimbotLines.line:Destroy()
            AimbotLines.line = nil
        end
    end,
})

AimbotTab:ColorPicker({
    Title = "Line Color",
    Value = Color3.fromRGB(0, 255, 100),
    Callback = function(v)
        Features.AimbotLineColor = v
        if AimbotLines.line then
            AimbotLines.line.Color3 = v
        end
    end,
})

-- ============================================
-- PESTAÑA 2: COMBAT
-- ============================================
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "sword" })

CombatTab:Section({ Title = "Auto", Desc = "Funciones automáticas" })

CombatTab:Toggle({
    Title = "Auto Heal",
    Value = false,
    Callback = function(v)
        Features.AutoHeal = v
        if v then Threads.AutoHeal = task.spawn(AutoHealLoop) end
    end,
})

CombatTab:Slider({
    Title = "Heal %",
    Step = 5,
    Value = { Min = 10, Max = 90, Default = 70 },
    Callback = function(v) Features.HealPercent = v end,
})

CombatTab:Toggle({
    Title = "Auto Hit",
    Value = false,
    Callback = function(v)
        Features.AutoHit = v
        if v then Threads.AutoHit = task.spawn(AutoHitLoop) end
    end,
})

CombatTab:Toggle({
    Title = "Hitbox Expander",
    Value = false,
    Callback = function(v)
        Features.HitboxExpander = v
        SetHitboxExpanded(v)
    end,
})

CombatTab:Toggle({
    Title = "Infinite Stamina",
    Value = false,
    Callback = function(v)
        Features.InfiniteStamina = v
        if v then Threads.Stamina = task.spawn(InfiniteStaminaLoop) end
    end,
})

-- ============================================
-- PESTAÑA 3: WEAPON MODS
-- ============================================
local WeaponTab = Window:Tab({ Title = "WEAPON MODS", Icon = "target" })

WeaponTab:Section({ Title = "Mods", Desc = "Modificaciones de armas" })

WeaponTab:Toggle({
    Title = "No Recoil",
    Value = false,
    Callback = function(v)
        Features.NoRecoil = v
        ApplyWeaponMods()
    end,
})

WeaponTab:Toggle({
    Title = "No Spread",
    Value = false,
    Callback = function(v)
        Features.NoSpread = v
        ApplyWeaponMods()
    end,
})

WeaponTab:Toggle({
    Title = "Rapid Fire",
    Value = false,
    Callback = function(v)
        Features.RapidFire = v
        ApplyWeaponMods()
    end,
})

WeaponTab:Toggle({
    Title = "Instant Reload",
    Value = false,
    Callback = function(v)
        Features.InstantReload = v
        ApplyWeaponMods()
    end,
})

WeaponTab:Space({ Columns = 1 })

WeaponTab:Section({ Title = "Ammo", Desc = "Munición infinita" })

WeaponTab:Toggle({
    Title = "Infinite Ammo",
    Value = false,
    Callback = function(v)
        Features.InfiniteAmmo = v
        if v then Threads.InfiniteAmmo = task.spawn(InfiniteAmmoLoop) end
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
    Title = "Weapon ESP",
    Value = false,
    Callback = function(v) Features.ESPWeapon = v end,
})

VisualTab:Toggle({
    Title = "Box ESP",
    Value = false,
    Callback = function(v) Features.ESPBox = v end,
})

VisualTab:Space({ Columns = 1 })

VisualTab:Section({ Title = "Chams", Desc = "Resaltar jugadores" })

VisualTab:Toggle({
    Title = "Chams (Verde/Azul)",
    Value = false,
    Callback = function(v)
        Features.Chams = v
        SetChams(v)
    end,
})

VisualTab:Space({ Columns = 1 })

VisualTab:Section({ Title = "World", Desc = "Modificar mundo" })

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
-- PESTAÑA 5: AUTO
-- ============================================
local AutoTab = Window:Tab({ Title = "AUTO", Icon = "robot" })

AutoTab:Section({ Title = "ATM", Desc = "Robar y depositar" })

AutoTab:Toggle({
    Title = "Auto ATM",
    Value = false,
    Callback = function(v)
        Features.AutoATM = v
        if v then Threads.AutoATM = task.spawn(AutoATMLoop) end
    end,
})

AutoTab:Toggle({
    Title = "Auto Deposit",
    Value = false,
    Callback = function(v) Features.AutoDeposit = v end,
})

-- ============================================
-- PESTAÑA 6: SPECTATE
-- ============================================
local SpectateTab = Window:Tab({ Title = "SPECTATE", Icon = "video" })

SpectateTab:Section({ Title = "Spectate", Desc = "Ver otros jugadores" })

local PlayerList = SpectateTab:Dropdown({
    Title = "Select Player",
    Value = "None",
    Values = GetPlayers(),
    Callback = function(v)
        local target = Players:FindFirstChild(v)
        Features.SpectateTarget = target
        StartSpectate(target)
    end,
})

task.spawn(function()
    while true do
        task.wait(5)
        pcall(function()
            PlayerList:SetValues(GetPlayers())
        end)
    end
end)

SpectateTab:Button({
    Title = "Stop Spectate",
    Callback = function()
        StartSpectate(nil)
        Features.SpectateTarget = nil
        Notify("Spectate", "Detenido")
    end,
})

-- ============================================
-- PESTAÑA 7: MISC
-- ============================================
local MiscTab = Window:Tab({ Title = "MISC", Icon = "settings" })

MiscTab:Section({ Title = "General", Desc = "Funciones varias" })

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
    Callback = function(v) Features.AutoAccept = v end,
})

-- ============================================
-- PESTAÑA 8: CONFIG
-- ============================================
local ConfigTab = Window:Tab({ Title = "CONFIG", Icon = "cog" })

ConfigTab:Section({ Title = "Account", Desc = "Tu información" })

local CashLabel = ConfigTab:Label({ Title = "Cash: Loading..." })
local BankLabel = ConfigTab:Label({ Title = "Bank: Loading..." })

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
        SetChams(false)
        StartSpectate(nil)
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
-- INICIALIZACIÓN AUTO-ADAPTABLE
-- ============================================
AutoDetectGame()
DetectWeapons()

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
            ESPObjects[p].Box:Destroy()
        end)
        ESPObjects[p] = nil
    end
    if ChamsObjects[p] then
        ChamsObjects[p]:Destroy()
        ChamsObjects[p] = nil
    end
end)

RunService.RenderStepped:Connect(UpdateESP)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if Features.NoRecoil or Features.NoSpread or Features.RapidFire then
        ApplyWeaponMods()
    end
    -- Re-detectar armas al cambiar de personaje
    DetectWeapons()
end)

-- Actualizar lista de jugadores periódicamente
task.spawn(function()
    while true do
        task.wait(10)
        pcall(function()
            if PlayerList then
                PlayerList:SetValues(GetPlayers())
            end
        end)
    end
end)

AimbotTab:Select()
print("✅ Water Hub | BlockSpin - Versión Auto-Adaptable con Aimbot Visual")