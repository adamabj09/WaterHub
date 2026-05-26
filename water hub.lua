--[[
    WATER HUB | BLOCKSPIN - VERSION CORREGIDA
    Funciones REMOVIDAS: Fly, NoClip, Infinite Ammo/Stamina (anti-cheat)
    Funciones MEJORADAS: AutoFarm con movimiento suave, FOV Circle, ESP larga distancia
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
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
-- VARIABLES Y ESTADO
-- ============================================
local Features = {
    -- Combat
    SilentAim = false,
    FOV = 200,
    ShowFOVCircle = true,
    AimPart = "Head",
    AutoHeal = false,
    HealPercent = 70,
    AutoHit = false,
    HitboxExpander = false,
    KillAura = false,
    
    -- Movement
    SpeedEnabled = false,
    SpeedValue = 50,
    InfiniteJump = false,
    
    -- Weapon (solo mods visuales/cliente)
    NoRecoil = false,
    NoSpread = false,
    RapidFire = false,
    InstantReload = false,
    
    -- Visual
    ESPName = false,
    ESPHealth = false,
    ESPDistance = false,
    ESPWeapon = false,
    ESPMaxDistance = 2000, -- Distancia máxima para ESP
    Chams = false,
    FullBright = false,
    NoFog = false,
    
    -- AutoFarm
    AutoFarm = false,
    AutoATM = false,
    AutoDeposit = false,
    SelectedJob = "None",
    FarmSpeed = 50, -- Velocidad de movimiento al farmear (studs/segundo)
    
    -- Spectate
    SpectateTarget = nil,
    
    -- Misc
    AntiAFK = false,
}

local Threads = {}
local ESPObjects = {}
local ChamsObjects = {}
local SilentAimTarget = nil
local OldNamecall = nil
local SpectateConnection = nil
local FOVCircle = nil
local IsFarming = false

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
-- FOV CIRCLE VISUAL
-- ============================================
local function CreateFOVCircle()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FOVCircle"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = gethui()
    
    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    circle.Size = UDim2.new(0, Features.FOV * 2, 0, Features.FOV * 2)
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = 0
    circle.Parent = screenGui
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = circle
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle
    
    FOVCircle = circle
    screenGui.Enabled = Features.ShowFOVCircle and Features.SilentAim
    return screenGui
end

local function UpdateFOVCircle()
    if FOVCircle then
        FOVCircle.Size = UDim2.new(0, Features.FOV * 2, 0, Features.FOV * 2)
        FOVCircle.Parent.Parent.Enabled = Features.ShowFOVCircle and Features.SilentAim
    end
end

-- Crear círculo al inicio
CreateFOVCircle()

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
-- MOVIMIENTO SUAVE (Tween) - Para farmear sin teletransporte
-- ============================================
local function MoveToPosition(targetPos, speed)
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
    
    local hrp = char.HumanoidRootPart
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    local distance = (targetPos - hrp.Position).Magnitude
    if distance < 3 then return true end
    
    -- Calcular tiempo basado en velocidad
    local timeNeeded = distance / speed
    
    -- Crear tween
    local tweenInfo = TweenInfo.new(
        timeNeeded,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    
    local targetCFrame = CFrame.new(targetPos)
    local tween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
    
    tween:Play()
    
    -- Esperar a que termine o se cancele
    local completed = false
    tween.Completed:Connect(function() completed = true end)
    
    -- Esperar con timeout
    local startTime = tick()
    while not completed and tick() - startTime < timeNeeded + 2 do
        if not IsFarming then
            tween:Cancel()
            return false
        end
        task.wait(0.1)
    end
    
    return completed
end

-- ============================================
-- COMBAT - SILENT AIM CON FOV CIRCLE
-- ============================================
RunService.RenderStepped:Connect(function()
    -- Actualizar círculo FOV
    UpdateFOVCircle()
    
    if not Features.SilentAim and not Features.KillAura then
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
                or player.Character:FindFirstChild("HumanoidRootPart")
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
    
    -- Kill Aura
    if Features.KillAura and closest and closest.Character then
        local myChar = LocalPlayer.Character
        if myChar then
            local tool = myChar:FindFirstChildOfClass("Tool")
            if tool then
                local targetHRP = closest.Character:FindFirstChild("HumanoidRootPart")
                local myHRP = myChar:FindFirstChild("HumanoidRootPart")
                if targetHRP and myHRP then
                    local dist = (targetHRP.Position - myHRP.Position).Magnitude
                    if dist < 15 then
                        pcall(function() tool:Activate() end)
                    end
                end
            end
        end
    end
end)

local function SetupSilentAim()
    if OldNamecall then return end
    
    OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if Features.SilentAim and method == "FireServer" and SilentAimTarget then
            local name = self.Name:lower()
            
            if name:find("hit") or name:find("damage") or name:find("shoot") 
               or name:find("fire") or name:find("bullet") or name:find("ray")
               or name:find("combat") or name:find("attack") or name:find("weapon") then
                
                local targetChar = SilentAimTarget.Character
                if targetChar then
                    local targetPart = targetChar:FindFirstChild(Features.AimPart) 
                        or targetChar:FindFirstChild("Head")
                        or targetChar:FindFirstChild("HumanoidRootPart")
                    
                    if targetPart then
                        for i = 1, #args do
                            if typeof(args[i]) == "Vector3" then
                                args[i] = targetPart.Position
                            elseif typeof(args[i]) == "CFrame" then
                                args[i] = CFrame.new(targetPart.Position)
                            elseif typeof(args[i]) == "Instance" then
                                if args[i]:IsA("BasePart") then
                                    args[i] = targetPart
                                elseif args[i]:IsA("Player") then
                                    args[i] = SilentAimTarget
                                end
                            end
                        end
                        
                        if #args >= 2 and typeof(args[2]) == "Vector3" then
                            args[2] = targetPart.Position
                        end
                        
                        if #args >= 1 and typeof(args[1]) == "Instance" and args[1]:IsA("Player") then
                            args[1] = SilentAimTarget
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
                    local hitbox = hrp:FindFirstChild("ExpandedHitbox")
                    if not hitbox then
                        hitbox = Instance.new("Part")
                        hitbox.Name = "ExpandedHitbox"
                        hitbox.Size = Vector3.new(10, 10, 10)
                        hitbox.Transparency = 1
                        hitbox.CanCollide = false
                        hitbox.Anchored = false
                        hitbox.Parent = hrp
                        
                        local weld = Instance.new("Weld")
                        weld.Part0 = hrp
                        weld.Part1 = hitbox
                        weld.Parent = hrp
                    end
                else
                    local hitbox = hrp:FindFirstChild("ExpandedHitbox")
                    if hitbox then hitbox:Destroy() end
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
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    if backpack then
                        local medkit = backpack:FindFirstChild("Medkit") 
                            or backpack:FindFirstChild("Bandage")
                        if medkit then
                            hum.Health = hum.MaxHealth
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end

-- Auto Hit
local function AutoHitLoop()
    while Features.AutoHit do
        if SilentAimTarget and SilentAimTarget.Character then
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    pcall(function() tool:Activate() end)
                end
            end
        end
        task.wait(0.2)
    end
end

-- ============================================
-- MOVEMENT (Sin Fly ni NoClip - anti-cheat)
-- ============================================
local function SpeedLoop()
    while Features.SpeedEnabled do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = Features.SpeedValue
            end
        end
        task.wait(0.1)
    end
    
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

local function InfiniteJumpLoop()
    UserInputService.JumpRequest:Connect(function()
        if Features.InfiniteJump then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end)
end

-- ============================================
-- WEAPON MODS (Solo cliente, no infinite ammo)
-- ============================================
local function ModTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    local mods = {
        Recoil = Features.NoRecoil and 0 or nil,
        RecoilValue = Features.NoRecoil and 0 or nil,
        RecoilAmount = Features.NoRecoil and 0 or nil,
        Spread = Features.NoSpread and 0 or nil,
        SpreadValue = Features.NoSpread and 0 or nil,
        Accuracy = Features.NoSpread and 100 or nil,
        FireRate = Features.RapidFire and 0.01 or nil,
        Cooldown = Features.RapidFire and 0.01 or nil,
        FireCooldown = Features.RapidFire and 0.01 or nil,
        ReloadTime = Features.InstantReload and 0.01 or nil,
        ReloadDuration = Features.InstantReload and 0.01 or nil,
    }
    
    for name, value in pairs(mods) do
        local obj = tool:FindFirstChild(name)
        if obj then
            if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                obj.Value = value
            elseif obj:IsA("BoolValue") then
                obj.Value = value
            end
        end
    end
    
    local configNames = {"Configuration", "Settings", "Config", "GunSettings"}
    for _, configName in ipairs(configNames) do
        local config = tool:FindFirstChild(configName)
        if config then
            for name, value in pairs(mods) do
                local setting = config:FindFirstChild(name)
                if setting then
                    if setting:IsA("NumberValue") or setting:IsA("IntValue") then
                        setting.Value = value
                    elseif setting:IsA("BoolValue") then
                        setting.Value = value
                    end
                end
            end
        end
    end
end

local function ApplyWeaponMods()
    local char = LocalPlayer.Character
    if not char then return end
    
    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped then ModTool(equipped) end
    
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            ModTool(tool)
        end
    end
end

-- ============================================
-- ESP MEJORADO - Larga distancia
-- ============================================
local ESPGui = nil

local function GetESPGui()
    if ESPGui and ESPGui.Parent then return ESPGui end
    local sg = Instance.new("ScreenGui")
    sg.Name = "ESP_" .. tostring(math.random(1000, 9999))
    sg.ResetOnSpawn = false
    sg.Parent = gethui()
    ESPGui = sg
    return sg
end

-- Función para obtener posición del jugador incluso si character no está cargado
local function GetPlayerPosition(player)
    -- Intentar obtener del character
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        return player.Character.HumanoidRootPart.Position, true
    end
    
    -- Si no hay character, estimar basado en última posición conocida o no mostrar
    return nil, false
end

local function CreateESP(player)
    if ESPObjects[player] then return end
    
    local gui = GetESPGui()
    local esp = {}
    
    -- Name
    esp.Name = Instance.new("TextLabel")
    esp.Name.Size = UDim2.new(0, 200, 0, 20)
    esp.Name.BackgroundTransparency = 1
    esp.Name.TextColor3 = Color3.fromRGB(255, 255, 255)
    esp.Name.TextSize = 12
    esp.Name.Font = Enum.Font.GothamBold
    esp.Name.TextStrokeTransparency = 0.5
    esp.Name.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    esp.Name.Parent = gui
    
    -- Health Bar Background
    esp.HealthBg = Instance.new("Frame")
    esp.HealthBg.Size = UDim2.new(0, 100, 0, 6)
    esp.HealthBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    esp.HealthBg.BorderSizePixel = 0
    esp.HealthBg.Parent = gui
    
    -- Health Bar
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
    esp.Distance.TextStrokeTransparency = 0.5
    esp.Distance.Parent = gui
    
    -- Weapon
    esp.Weapon = Instance.new("TextLabel")
    esp.Weapon.Size = UDim2.new(0, 150, 0, 20)
    esp.Weapon.BackgroundTransparency = 1
    esp.Weapon.TextColor3 = Color3.fromRGB(255, 200, 100)
    esp.Weapon.TextSize = 10
    esp.Weapon.Font = Enum.Font.GothamBold
    esp.Weapon.TextStrokeTransparency = 0.5
    esp.Weapon.Parent = gui
    
    esp.LastPosition = nil
    esp.LastUpdate = 0
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
            -- Verificar distancia máxima
            if myPos then
                local playerPos, hasChar = GetPlayerPosition(player)
                if playerPos then
                    local dist = (myPos - playerPos).Magnitude
                    if dist > Features.ESPMaxDistance then
                        esp.Name.Visible = false
                        esp.HealthBg.Visible = false
                        esp.Distance.Visible = false
                        esp.Weapon.Visible = false
                        return
                    end
                end
            end
            
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            
            -- Si no hay character pero teníamos posición guardada, usarla
            if not hrp and esp.LastPosition then
                hrp = {Position = esp.LastPosition}
            end
            
            if hrp then
                -- Guardar última posición conocida
                if char and char:FindFirstChild("HumanoidRootPart") then
                    esp.LastPosition = hrp.Position
                end
                
                local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    -- Name ESP
                    if Features.ESPName then
                        esp.Name.Position = UDim2.new(0, pos.X - 100, 0, pos.Y - 50)
                        esp.Name.Text = player.Name .. (not char and " [NO LOADED]" or "")
                        esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end
                    
                    -- Health ESP (solo si hay humanoid)
                    if Features.ESPHealth and hum then
                        local percent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                        esp.HealthBar.Size = UDim2.new(percent, 0, 1, 0)
                        esp.HealthBar.BackgroundColor3 = Color3.fromRGB(255 * (1-percent), 255 * percent, 0)
                        esp.HealthBg.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 30)
                        esp.HealthBg.Visible = true
                    else
                        esp.HealthBg.Visible = false
                    end
                    
                    -- Distance ESP
                    if Features.ESPDistance and myPos then
                        local dist = (myPos - hrp.Position).Magnitude
                        esp.Distance.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 20)
                        esp.Distance.Text = math.floor(dist) .. " studs"
                        esp.Distance.Visible = true
                    else
                        esp.Distance.Visible = false
                    end
                    
                    -- Weapon ESP
                    if Features.ESPWeapon then
                        local weapon = GetEquippedTool(player)
                        if weapon then
                            esp.Weapon.Text = "🔫 " .. weapon
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

-- Chams
local function SetChams(enabled)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if enabled then
                if not ChamsObjects[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "Chams"
                    highlight.FillColor = player.Team == LocalPlayer.Team and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
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
-- AUTOFARM CON MOVIMIENTO SUAVE
-- ============================================
local function GetNearestATM()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    
    local hrp = char.HumanoidRootPart
    local nearest = nil
    local shortestDist = math.huge
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:find("ATM") or obj.Name:find("Atm") then
            local part = obj:IsA("Model") and obj:FindFirstChildOfClass("BasePart") or 
                        (obj:IsA("BasePart") and obj or nil)
            if part then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    nearest = obj
                end
            end
        end
    end
    
    return nearest, shortestDist
end

local function HackATM(atm)
    if not atm then return false end
    
    local clickDetector = atm:FindFirstChild("ClickDetector") 
        or atm:FindFirstChildOfClass("ClickDetector")
    if clickDetector then
        fireclickdetector(clickDetector)
        return true
    end
    
    local prompt = atm:FindFirstChild("ProximityPrompt")
        or atm:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt)
        return true
    end
    
    return false
end

local function DepositMoney()
    local Replicated = game:GetService("ReplicatedStorage")
    local depositRemote = Replicated:FindFirstChild("Deposit") 
        or Replicated:FindFirstChild("Bank")
    if depositRemote then
        depositRemote:FireServer()
        return true
    end
    return false
end

-- Auto ATM con movimiento suave
local function AutoATMLoop()
    IsFarming = true
    
    while Features.AutoATM and IsFarming do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local atm, dist = GetNearestATM()
            
            if atm and dist > 5 then
                -- Moverse suavemente hacia el ATM
                local targetPos = atm:IsA("Model") and 
                    (atm:FindFirstChildOfClass("BasePart") and atm:FindFirstChildOfClass("BasePart").Position) or 
                    (atm:IsA("BasePart") and atm.Position)
                
                if targetPos then
                    -- Posición frente al ATM
                    targetPos = targetPos + Vector3.new(0, 0, 3)
                    
                    Notify("Auto ATM", "Moviendo hacia ATM...")
                    local success = MoveToPosition(targetPos, Features.FarmSpeed)
                    
                    if success then
                        -- Intentar hackear
                        task.wait(0.5)
                        HackATM(atm)
                        Notify("Auto ATM", "Hackeando ATM...")
                        task.wait(3) -- Esperar animación
                    end
                end
            elseif atm and dist <= 5 then
                -- Ya estamos cerca, hackear
                HackATM(atm)
                task.wait(3)
            end
        end
        task.wait(1)
    end
    
    IsFarming = false
end

local function AutoDepositLoop()
    while Features.AutoDeposit do
        local cash, bank = GetMoney()
        
        if cash > 500 then
            DepositMoney()
            task.wait(3)
        end
        
        task.wait(5)
    end
end

-- Auto Farm Jobs con movimiento suave
local function AutoFarmLoop()
    IsFarming = true
    
    while Features.AutoFarm and IsFarming do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            
            if Features.SelectedJob == "Janitor" then
                -- Buschar basura cercana
                local nearestTrash = nil
                local shortestDist = math.huge
                
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj.Name:find("Mess") or obj.Name:find("Trash") 
                       or obj.Name:find("Garbage") or obj.Name:find("Puddle") then
                        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                            local dist = (obj.Position - hrp.Position).Magnitude
                            if dist < shortestDist and dist < 100 then
                                shortestDist = dist
                                nearestTrash = obj
                            end
                        end
                    end
                end
                
                if nearestTrash and shortestDist > 5 then
                    -- Moverse hacia la basura
                    Notify("Auto Farm", "Moviendo hacia objetivo...")
                    local success = MoveToPosition(nearestTrash.Position + Vector3.new(0, 3, 0), Features.FarmSpeed)
                    
                    if success then
                        task.wait(0.3)
                        -- Interactuar
                        if nearestTrash:FindFirstChild("ClickDetector") then
                            fireclickdetector(nearestTrash.ClickDetector)
                        elseif nearestTrash:FindFirstChild("ProximityPrompt") then
                            fireproximityprompt(nearestTrash.ProximityPrompt)
                        end
                        task.wait(1)
                    end
                elseif nearestTrash and shortestDist <= 5 then
                    -- Interactuar directamente
                    if nearestTrash:FindFirstChild("ClickDetector") then
                        fireclickdetector(nearestTrash.ClickDetector)
                    elseif nearestTrash:FindFirstChild("ProximityPrompt") then
                        fireproximityprompt(nearestTrash.ProximityPrompt)
                    end
                    task.wait(1)
                else
                    task.wait(2)
                end
                
            elseif Features.SelectedJob == "ATM" then
                Features.AutoATM = true
                AutoATMLoop()
                Features.AutoATM = false
                break
            end
        end
        task.wait(0.5)
    end
    
    IsFarming = false
end

-- ============================================
-- SPECTATE
-- ============================================
local function StartSpectate(targetPlayer)
    if SpectateConnection then
        SpectateConnection:Disconnect()
        SpectateConnection = nil
    end
    
    if not targetPlayer or not targetPlayer.Character then
        local myChar = LocalPlayer.Character
        if myChar then
            local hum = myChar:FindFirstChild("Humanoid")
            Workspace.CurrentCamera.CameraSubject = hum or myChar
        end
        return
    end
    
    SpectateConnection = RunService.RenderStepped:Connect(function()
        if targetPlayer and targetPlayer.Character then
            local hum = targetPlayer.Character:FindFirstChild("Humanoid")
            Workspace.CurrentCamera.CameraSubject = hum or targetPlayer.Character
        else
            local myChar = LocalPlayer.Character
            if myChar then
                local hum = myChar:FindFirstChild("Humanoid")
                Workspace.CurrentCamera.CameraSubject = hum or myChar
            end
        end
    end)
end

-- ============================================
-- MISC
-- ============================================
local function AntiAFKLoop()
    local VirtualUser = game:GetService("VirtualUser")
    while Features.AntiAFK do
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
        task.wait(60)
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

Notify("Water Hub", "Script cargado - Anti-cheat bypass activado")

-- ============================================
-- PESTAÑAS
-- ============================================

-- 1. COMBAT
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "sword" })

CombatTab:Section({ Title = "Silent Aim", Desc = "Apuntado automatico con FOV" })

CombatTab:Toggle({
    Title = "Silent Aim",
    Value = false,
    Callback = function(v)
        Features.SilentAim = v
        if v then SetupSilentAim() end
        UpdateFOVCircle()
        Notify("Silent Aim", v and "Activado" or "Desactivado")
    end,
})

CombatTab:Toggle({
    Title = "Mostrar FOV",
    Value = true,
    Callback = function(v)
        Features.ShowFOVCircle = v
        UpdateFOVCircle()
    end,
})

CombatTab:Slider({
    Title = "FOV",
    Step = 10,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v) 
        Features.FOV = v
        UpdateFOVCircle()
    end,
})

CombatTab:Dropdown({
    Title = "Aim Part",
    Value = "Head",
    Values = { "Head", "HumanoidRootPart", "Torso" },
    Callback = function(v) Features.AimPart = v end,
})

CombatTab:Space({ Columns = 1 })

CombatTab:Section({ Title = "Combat", Desc = "Funciones de combate" })

CombatTab:Toggle({
    Title = "Kill Aura",
    Value = false,
    Callback = function(v)
        Features.KillAura = v
        Notify("Kill Aura", v and "Activado" or "Desactivado")
    end,
})

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

-- 2. MOVEMENT (Sin Fly ni NoClip)
local MovementTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })

MovementTab:Section({ Title = "Speed", Desc = "Velocidad de movimiento" })

MovementTab:Toggle({
    Title = "Speed Hack",
    Value = false,
    Callback = function(v)
        Features.SpeedEnabled = v
        if v then Threads.Speed = task.spawn(SpeedLoop) end
    end,
})

MovementTab:Slider({
    Title = "Speed",
    Step = 5,
    Value = { Min = 16, Max = 200, Default = 50 },
    Callback = function(v) Features.SpeedValue = v end,
})

MovementTab:Space({ Columns = 1 })

MovementTab:Section({ Title = "Extras", Desc = "Otras funciones" })

MovementTab:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(v)
        Features.InfiniteJump = v
        if v then Threads.Jump = task.spawn(InfiniteJumpLoop) end
    end,
})

-- 3. WEAPON
local WeaponTab = Window:Tab({ Title = "WEAPON", Icon = "crosshair" })

WeaponTab:Section({ Title = "Gun Mods", Desc = "Modificaciones de armas (Client-side)" })

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

-- 4. VISUAL
local VisualTab = Window:Tab({ Title = "VISUAL", Icon = "eye" })

VisualTab:Section({ Title = "ESP", Desc = "Ver jugadores a larga distancia" })

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

VisualTab:Slider({
    Title = "Max ESP Distance",
    Step = 100,
    Value = { Min = 500, Max = 5000, Default = 2000 },
    Callback = function(v) Features.ESPMaxDistance = v end,
})

VisualTab:Space({ Columns = 1 })

VisualTab:Section({ Title = "Chams", Desc = "Resaltar jugadores" })

VisualTab:Toggle({
    Title = "Chams",
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

-- 5. AUTOFARM (Con movimiento suave)
local AutoFarmTab = Window:Tab({ Title = "AUTOFARM", Icon = "robot" })

AutoFarmTab:Section({ Title = "ATM Farm", Desc = "Farmear ATMs (movimiento suave)" })

AutoFarmTab:Toggle({
    Title = "Auto ATM",
    Value = false,
    Callback = function(v)
        Features.AutoATM = v
        if v then 
            Threads.AutoATM = task.spawn(AutoATMLoop)
        else
            IsFarming = false
        end
    end,
})

AutoFarmTab:Slider({
    Title = "Farm Speed",
    Step = 10,
    Value = { Min = 20, Max = 100, Default = 50 },
    Callback = function(v) Features.FarmSpeed = v end,
})

AutoFarmTab:Toggle({
    Title = "Auto Deposit",
    Value = false,
    Callback = function(v)
        Features.AutoDeposit = v
        if v then Threads.AutoDeposit = task.spawn(AutoDepositLoop) end
    end,
})

AutoFarmTab:Space({ Columns = 1 })

AutoFarmTab:Section({ Title = "Jobs", Desc = "Trabajos automaticos (movimiento suave)" })

AutoFarmTab:Toggle({
    Title = "Auto Farm Job",
    Value = false,
    Callback = function(v)
        Features.AutoFarm = v
        if v then 
            Threads.AutoFarm = task.spawn(AutoFarmLoop)
        else
            IsFarming = false
        end
    end,
})

AutoFarmTab:Dropdown({
    Title = "Job",
    Value = "None",
    Values = { "None", "Janitor", "ATM" },
    Callback = function(v) Features.SelectedJob = v end,
})

-- 6. GUNS AMMO (SIN infinite ammo - no funciona)
local GunsAmmoTab = Window:Tab({ Title = "GUNS AMMO", Icon = "target" })

GunsAmmoTab:Section({ Title = "Nota", Desc = "Infinite ammo no funciona en BlockSpin (server-side)" })

GunsAmmoTab:Label({ Title = "El servidor valida la municion" })
GunsAmmoTab:Label({ Title = "Usa Rapid Fire en Weapon en su lugar" })

-- 7. SPECTATE
local SpectateTab = Window:Tab({ Title = "SPECTATE", Icon = "video" })

SpectateTab:Section({ Title = "Spectate", Desc = "Ver otros jugadores" })

local PlayerList = SpectateTab:Dropdown({
    Title = "Select Player",
    Value = "None",
    Values = GetPlayers(),
    Callback = function(v)
        local target = Players:FindFirstChild(v)
        Features.SpectateTarget = target
        if target then
            StartSpectate(target)
            Notify("Spectate", "Observando a " .. v)
        else
            StartSpectate(nil)
        end
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
        Notify("Spectate", "Modo espectador desactivado")
    end,
})

-- 8. MISC
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

-- 9. CONFIG
local ConfigTab = Window:Tab({ Title = "CONFIG", Icon = "cog" })

ConfigTab:Section({ Title = "Account", Desc = "Tu informacion" })

local CashLabel = ConfigTab:Label({ Title = "Cash: Loading..." })
local BankLabel = ConfigTab:Label({ Title = "Bank: Loading..." })

task.spawn(function()
    while true do
        local cash, bank = GetMoney()
        pcall(function()
            CashLabel:Set("Cash: $" .. cash)
            BankLabel:Set("Bank: $" .. bank)
        end)
        task.wait(1)
    end
end)

ConfigTab:Space({ Columns = 1 })

ConfigTab:Section({ Title = "Script", Desc = "Control del script" })

ConfigTab:Button({
    Title = "Destroy UI",
    Callback = function()
        IsFarming = false
        for k, thread in pairs(Threads) do
            if thread then
                pcall(function() coroutine.close(thread) end)
            end
        end
        SetChams(false)
        StartSpectate(nil)
        if FOVCircle then FOVCircle.Parent:Destroy() end
        if ESPGui then ESPGui:Destroy() end
        Window:Destroy()
    end,
})

ConfigTab:Button({
    Title = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

-- ============================================
-- INICIALIZACION
-- ============================================
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end

Players.PlayerAdded:Connect(function(p) 
    if p ~= LocalPlayer then CreateESP(p) end 
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
    if ChamsObjects[p] then
        ChamsObjects[p]:Destroy()
        ChamsObjects[p] = nil
    end
end)

RunService.RenderStepped:Connect(UpdateESP)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    
    if Features.SpeedEnabled then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = Features.SpeedValue end
    end
    
    if Features.NoRecoil or Features.NoSpread or Features.RapidFire or Features.InstantReload then
        ApplyWeaponMods()
    end
end)

LocalPlayer.Character.ChildAdded:Connect(function(child)
    if child:IsA("Tool") then
        task.wait(0.2)
        if Features.NoRecoil or Features.NoSpread or Features.RapidFire or Features.InstantReload then
            ModTool(child)
        end
    end
end)

CombatTab:Select()

print("Water Hub | BlockSpin - Version Anti-Cheat Bypass cargada")
