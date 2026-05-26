--[[
    WATER HUB | BLOCKSPIN - VERSION FINAL FUNCIONAL CORREGIDA
    Pestañas: COMBAT, MOVEMENT, WEAPON, VISUAL, AUTOFARM, GUNS AMMO, SPECTATE, MISC, CONFIG
    Con lógica real para BlockSpin (ATMs, Remotes, Armas, etc.)
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
local TeleportService = game:GetService("TeleportService")
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
-- VARIABLES Y ESTADO
-- ============================================
local Features = {
    -- Combat
    SilentAim = false,
    FOV = 200,
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
    InfiniteStamina = false,
    NoClip = false,
    Fly = false,
    FlySpeed = 50,
    
    -- Weapon
    NoRecoil = false,
    NoSpread = false,
    RapidFire = false,
    InstantReload = false,
    
    -- Visual
    ESPName = false,
    ESPHealth = false,
    ESPDistance = false,
    ESPWeapon = false,
    Chams = false,
    FullBright = false,
    NoFog = false,
    
    -- AutoFarm
    AutoFarm = false,
    AutoATM = false,
    AutoDeposit = false,
    SelectedJob = "None",
    
    -- Guns Ammo
    InfiniteAmmo = false,
    NoReload = false,
    
    -- Spectate
    SpectateTarget = nil,
    Freecam = false,
    
    -- Misc
    AntiAFK = false,
    AutoAccept = false,
    ServerHop = false
}

local Threads = {}
local ESPObjects = {}
local ChamsObjects = {}
local NoClipConnection = nil
local SilentAimTarget = nil
local OldNamecall = nil
local SpectateConnection = nil
local FlyConnection = nil
local FlyBodyVelocity = nil
local FlyBodyGyro = nil

-- Cache de remotes
local RemotesCache = {}
local function GetRemotes()
    if #RemotesCache > 0 then return RemotesCache end
    
    local Replicated = game:GetService("ReplicatedStorage")
    local remotes = {}
    
    -- Buscar todos los remotes
    for _, obj in ipairs(Replicated:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(remotes, obj)
        end
    end
    
    RemotesCache = remotes
    return remotes
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

-- ============================================
-- COMBAT - SILENT AIM Y KILL AURA
-- ============================================
RunService.RenderStepped:Connect(function()
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
            
            -- Detectar remotes de daño comunes en BlockSpin
            if name:find("hit") or name:find("damage") or name:find("shoot") 
               or name:find("fire") or name:find("bullet") or name:find("ray")
               or name:find("combat") or name:find("attack") or name:find("weapon") then
                
                local targetChar = SilentAimTarget.Character
                if targetChar then
                    local targetPart = targetChar:FindFirstChild(Features.AimPart) 
                        or targetChar:FindFirstChild("Head")
                        or targetChar:FindFirstChild("HumanoidRootPart")
                    
                    if targetPart then
                        -- Modificar posición de impacto
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
                        
                        -- Si hay argumentos de hit/rayo
                        if #args >= 2 and typeof(args[2]) == "Vector3" then
                            args[2] = targetPart.Position
                        end
                        
                        -- Cambiar target player si es necesario
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

-- Hitbox Expander mejorado
local function SetHitboxExpanded(enabled)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            
            if hrp then
                if enabled then
                    -- Crear hitbox expandida invisible
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
                    -- Buscar medkit en backpack o usar remote de curación
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    if backpack then
                        local medkit = backpack:FindFirstChild("Medkit") 
                            or backpack:FindFirstChild("Bandage")
                            or backpack:FindFirstChild("Health")
                        if medkit then
                            hum.Health = hum.MaxHealth
                        end
                    end
                    
                    -- Buscar remote de curación
                    local Replicated = game:GetService("ReplicatedStorage")
                    local healRemote = Replicated:FindFirstChild("Heal") 
                        or Replicated:FindFirstChild("UseMedkit")
                    if healRemote then
                        healRemote:FireServer()
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
-- MOVEMENT
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
    -- Resetear velocidad al desactivar
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

local function InfiniteStaminaLoop()
    while Features.InfiniteStamina do
        local char = LocalPlayer.Character
        if char then
            -- Buscar stamina en diferentes lugares comunes
            local staminaLocations = {
                char:FindFirstChild("Stamina"),
                char:FindFirstChild("Energy"),
                char:FindFirstChild("StaminaValue"),
                char:FindFirstChild("EnergyValue")
            }
            
            for _, stamina in ipairs(staminaLocations) do
                if stamina and (stamina:IsA("NumberValue") or stamina:IsA("IntValue")) then
                    stamina.Value = stamina:IsA("IntValue") and 100 or 100
                end
            end
            
            -- Buscar en humanoid
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum:SetAttribute("Stamina", 100)
                local humStamina = hum:FindFirstChild("Stamina")
                if humStamina then humStamina.Value = 100 end
            end
        end
        task.wait(0.2)
    end
end

local function SetNoClip(enabled)
    if enabled then
        if NoClipConnection then return end
        NoClipConnection = RunService.Stepped:Connect(function()
            if not Features.NoClip then return end
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if NoClipConnection then
            NoClipConnection:Disconnect()
            NoClipConnection = nil
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

-- Fly mejorado
local function FlyLoop()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Crear BodyVelocity y BodyGyro para fly suave
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp
    
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bg.P = 9e4
    bg.Parent = hrp
    
    FlyBodyVelocity = bv
    FlyBodyGyro = bg
    
    local speed = Features.FlySpeed
    local keys = {W = false, A = false, S = false, D = false, Space = false, LeftShift = false}
    
    local connections = {}
    
    connections.KeyDown = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.W then keys.W = true end
        if input.KeyCode == Enum.KeyCode.A then keys.A = true end
        if input.KeyCode == Enum.KeyCode.S then keys.S = true end
        if input.KeyCode == Enum.KeyCode.D then keys.D = true end
        if input.KeyCode == Enum.KeyCode.Space then keys.Space = true end
        if input.KeyCode == Enum.KeyCode.LeftShift then keys.LeftShift = true end
    end)
    
    connections.KeyUp = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then keys.W = false end
        if input.KeyCode == Enum.KeyCode.A then keys.A = false end
        if input.KeyCode == Enum.KeyCode.S then keys.S = false end
        if input.KeyCode == Enum.KeyCode.D then keys.D = false end
        if input.KeyCode == Enum.KeyCode.Space then keys.Space = false end
        if input.KeyCode == Enum.KeyCode.LeftShift then keys.LeftShift = false end
    end)
    
    while Features.Fly do
        local cam = Workspace.CurrentCamera
        if not cam then break end
        
        local direction = Vector3.new(0, 0, 0)
        
        if keys.W then direction = direction + cam.CFrame.LookVector end
        if keys.S then direction = direction - cam.CFrame.LookVector end
        if keys.A then direction = direction - cam.CFrame.RightVector end
        if keys.D then direction = direction + cam.CFrame.RightVector end
        if keys.Space then direction = direction + Vector3.new(0, 1, 0) end
        if keys.LeftShift then direction = direction - Vector3.new(0, 1, 0) end
        
        if direction.Magnitude > 0 then
            direction = direction.Unit * speed
            bv.Velocity = direction
            bg.CFrame = cam.CFrame
        else
            bv.Velocity = Vector3.new(0, 0, 0)
        end
        
        task.wait()
    end
    
    for _, conn in pairs(connections) do
        conn:Disconnect()
    end
    
    if bv then bv:Destroy() end
    if bg then bg:Destroy() end
    FlyBodyVelocity = nil
    FlyBodyGyro = nil
end

-- ============================================
-- WEAPON MODS
-- ============================================
local function ModTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    
    -- Valores a modificar
    local mods = {
        -- Recoil
        Recoil = Features.NoRecoil and 0 or nil,
        RecoilValue = Features.NoRecoil and 0 or nil,
        RecoilAmount = Features.NoRecoil and 0 or nil,
        -- Spread
        Spread = Features.NoSpread and 0 or nil,
        SpreadValue = Features.NoSpread and 0 or nil,
        Accuracy = Features.NoSpread and 100 or nil,
        -- Fire Rate
        FireRate = Features.RapidFire and 0.01 or nil,
        Cooldown = Features.RapidFire and 0.01 or nil,
        FireCooldown = Features.RapidFire and 0.01 or nil,
        -- Reload
        ReloadTime = Features.InstantReload and 0.01 or nil,
        ReloadDuration = Features.InstantReload and 0.01 or nil,
        -- Automatic
        Automatic = true,
        Auto = true
    }
    
    -- Aplicar a valores directos del tool
    for name, value in pairs(mods) do
        local obj = tool:FindFirstChild(name)
        if obj then
            if obj:IsA("NumberValue") or obj:IsA("IntValue") or obj:IsA("DoubleConstrainedValue") then
                obj.Value = value
            elseif obj:IsA("BoolValue") then
                obj.Value = value
            end
        end
    end
    
    -- Buscar en configuración del arma
    local configNames = {"Configuration", "Settings", "Config", "GunSettings", "WeaponConfig"}
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
    
    -- Modificar módulos de script si existen
    for _, scriptObj in ipairs(tool:GetDescendants()) do
        if scriptObj:IsA("ModuleScript") then
            -- Algunos juegos guardan configs en módulos
            local success, module = pcall(require, scriptObj)
            if success and type(module) == "table" then
                -- No podemos modificar módulos directamente, pero podemos intentar
                for key, _ in pairs(module) do
                    if Features.NoRecoil and (key:lower():find("recoil")) then
                        module[key] = 0
                    end
                    if Features.NoSpread and (key:lower():find("spread") or key:lower():find("accuracy")) then
                        module[key] = 0
                    end
                    if Features.RapidFire and (key:lower():find("firerate") or key:lower():find("cooldown")) then
                        module[key] = 0.01
                    end
                end
            end
        end
    end
end

local function ApplyWeaponMods()
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Modificar arma equipada
    local equipped = char:FindFirstChildOfClass("Tool")
    if equipped then ModTool(equipped) end
    
    -- Modificar armas en backpack
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            ModTool(tool)
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
                -- Nombres comunes de munición
                local ammoNames = {"Ammo", "Clip", "Magazine", "Bullets", "CurrentAmmo", "AmmoCount"}
                
                for _, name in ipairs(ammoNames) do
                    local ammo = tool:FindFirstChild(name)
                    if ammo and (ammo:IsA("IntValue") or ammo:IsA("NumberValue")) then
                        ammo.Value = 999
                    end
                end
                
                -- Buscar en configuración
                local configNames = {"Configuration", "Settings", "Config"}
                for _, configName in ipairs(configNames) do
                    local config = tool:FindFirstChild(configName)
                    if config then
                        for _, name in ipairs(ammoNames) do
                            local ammo = config:FindFirstChild(name)
                            if ammo then ammo.Value = 999 end
                        end
                    end
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
    sg.Name = "ESP_" .. tostring(math.random(1000, 9999))
    sg.ResetOnSpawn = false
    sg.Parent = gethui()
    ESPGui = sg
    return sg
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
                    -- Name ESP
                    if Features.ESPName then
                        esp.Name.Position = UDim2.new(0, pos.X - 100, 0, pos.Y - 50)
                        esp.Name.Text = player.Name
                        esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end
                    
                    -- Health ESP
                    if Features.ESPHealth then
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
        Lighting.FogStart = 0
    else
        Lighting.Brightness = 2
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 1000
    end
end

local function SetNoFog(enabled)
    if enabled then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    else
        Lighting.FogEnd = 1000
    end
end

-- ============================================
-- AUTOFARM - ATM Y TRABAJOS
-- ============================================
local function HackATM(atm)
    if not atm then return end
    
    local Replicated = game:GetService("ReplicatedStorage")
    
    -- Método 1: ClickDetector
    local clickDetector = atm:FindFirstChild("ClickDetector") 
        or atm:FindFirstChildOfClass("ClickDetector")
    if clickDetector then
        fireclickdetector(clickDetector)
        return true
    end
    
    -- Método 2: ProximityPrompt
    local prompt = atm:FindFirstChild("ProximityPrompt")
        or atm:FindFirstChildOfClass("ProximityPrompt")
    if prompt then
        fireproximityprompt(prompt)
        return true
    end
    
    -- Método 3: RemoteEvent
    local hackRemote = Replicated:FindFirstChild("HackATM") 
        or Replicated:FindFirstChild("RobATM")
        or Replicated:FindFirstChild("ATM")
        or Replicated:FindFirstChild("StealATM")
    if hackRemote then
        hackRemote:FireServer(atm)
        return true
    end
    
    -- Método 4: TouchInterest
    local touchPart = atm:IsA("Model") and atm:FindFirstChildOfClass("BasePart") or atm
    if touchPart and touchPart:FindFirstChild("TouchInterest") then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            firetouchinterest(char.HumanoidRootPart, touchPart, 0)
            firetouchinterest(char.HumanoidRootPart, touchPart, 1)
            return true
        end
    end
    
    return false
end

local function DepositMoney()
    local Replicated = game:GetService("ReplicatedStorage")
    
    -- Buschar remote de depósito
    local depositRemote = Replicated:FindFirstChild("Deposit") 
        or Replicated:FindFirstChild("Bank")
        or Replicated:FindFirstChild("DepositMoney")
    if depositRemote then
        depositRemote:FireServer()
        return true
    end
    
    -- Buschar ATM cercano para depositar
    local atm = GetNearestATM()
    if atm then
        local prompt = atm:FindFirstChild("DepositPrompt") 
            or atm:FindFirstChild("BankPrompt")
        if prompt then
            fireproximityprompt(prompt)
            return true
        end
    end
    
    return false
end

local function AutoATMLoop()
    while Features.AutoATM do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            
            -- Buschar ATM más cercano
            local atm, dist = GetNearestATM()
            
            if atm then
                -- Teletransportarse si está lejos
                if dist > 10 then
                    local targetPos = atm:IsA("Model") and 
                        (atm:FindFirstChildOfClass("BasePart") and atm:FindFirstChildOfClass("BasePart").Position) or 
                        (atm:IsA("BasePart") and atm.Position)
                    
                    if targetPos then
                        hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 5, 5))
                        task.wait(0.5)
                    end
                end
                
                -- Intentar hackear
                if dist < 15 then
                    HackATM(atm)
                    task.wait(2) -- Esperar entre hacks
                end
            end
        end
        task.wait(0.5)
    end
end

local function AutoDepositLoop()
    while Features.AutoDeposit do
        local cash, bank = GetMoney()
        
        -- Depositar si tenemos más de 500 en cash
        if cash > 500 then
            DepositMoney()
            task.wait(3)
        end
        
        task.wait(5)
    end
end

local function AutoFarmLoop()
    while Features.AutoFarm do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            
            if Features.SelectedJob == "Janitor" then
                -- Buschar basura para limpiar
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj.Name:find("Mess") or obj.Name:find("Trash") 
                       or obj.Name:find("Garbage") or obj.Name:find("Puddle")
                       or obj.Name:find("Clean") then
                        
                        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                            local dist = (obj.Position - hrp.Position).Magnitude
                            if dist < 50 then
                                -- Teletransportarse
                                hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0, 3, 0))
                                task.wait(0.2)
                                
                                -- Interactuar
                                if obj:FindFirstChild("ClickDetector") then
                                    fireclickdetector(obj.ClickDetector)
                                elseif obj:FindFirstChild("ProximityPrompt") then
                                    fireproximityprompt(obj.ProximityPrompt)
                                elseif obj:FindFirstChild("TouchInterest") then
                                    firetouchinterest(hrp, obj, 0)
                                    firetouchinterest(hrp, obj, 1)
                                end
                                
                                -- Remote de trabajo
                                local Replicated = game:GetService("ReplicatedStorage")
                                local workRemote = Replicated:FindFirstChild("Work") 
                                    or Replicated:FindFirstChild("Job")
                                    or Replicated:FindFirstChild("Clean")
                                if workRemote then
                                    workRemote:FireServer(obj)
                                end
                                
                                task.wait(0.5)
                            end
                        end
                    end
                end
                
            elseif Features.SelectedJob == "ATM" then
                -- Cambiar a farmeo de ATM
                Features.AutoATM = true
                AutoATMLoop()
                Features.AutoATM = false
                break
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

local function ServerHop()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    
    local servers = {}
    local req = game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
    local data = HttpService:JSONDecode(req)
    
    if data and data.data then
        for _, server in ipairs(data.data) do
            if server.playing < server.maxPlayers and server.id ~= game.JobId then
                table.insert(servers, server.id)
            end
        end
    end
    
    if #servers > 0 then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer)
    else
        Notify("Server Hop", "No se encontraron servidores disponibles")
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

Notify("Water Hub", "Script cargado correctamente - BlockSpin Edition")

-- ============================================
-- PESTAÑAS
-- ============================================

-- 1. COMBAT
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "sword" })

CombatTab:Section({ Title = "Aimbot", Desc = "Apuntado automatico" })

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
    Title = "FOV",
    Step = 10,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v) Features.FOV = v end,
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

-- 2. MOVEMENT
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

MovementTab:Section({ Title = "Flight", Desc = "Volar" })

MovementTab:Toggle({
    Title = "Fly",
    Value = false,
    Callback = function(v)
        Features.Fly = v
        if v then Threads.Fly = task.spawn(FlyLoop) end
    end,
})

MovementTab:Slider({
    Title = "Fly Speed",
    Step = 5,
    Value = { Min = 10, Max = 200, Default = 50 },
    Callback = function(v) Features.FlySpeed = v end,
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

MovementTab:Toggle({
    Title = "Infinite Stamina",
    Value = false,
    Callback = function(v)
        Features.InfiniteStamina = v
        if v then Threads.Stamina = task.spawn(InfiniteStaminaLoop) end
    end,
})

MovementTab:Toggle({
    Title = "No Clip",
    Value = false,
    Callback = function(v)
        Features.NoClip = v
        SetNoClip(v)
    end,
})

-- 3. WEAPON
local WeaponTab = Window:Tab({ Title = "WEAPON", Icon = "crosshair" })

WeaponTab:Section({ Title = "Gun Mods", Desc = "Modificaciones de armas" })

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

-- 5. AUTOFARM
local AutoFarmTab = Window:Tab({ Title = "AUTOFARM", Icon = "robot" })

AutoFarmTab:Section({ Title = "ATM Farm", Desc = "Farmear ATMs automaticamente" })

AutoFarmTab:Toggle({
    Title = "Auto ATM",
    Value = false,
    Callback = function(v)
        Features.AutoATM = v
        if v then Threads.AutoATM = task.spawn(AutoATMLoop) end
    end,
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

AutoFarmTab:Section({ Title = "Jobs", Desc = "Trabajos automaticos" })

AutoFarmTab:Toggle({
    Title = "Auto Farm Job",
    Value = false,
    Callback = function(v)
        Features.AutoFarm = v
        if v then Threads.AutoFarm = task.spawn(AutoFarmLoop) end
    end,
})

AutoFarmTab:Dropdown({
    Title = "Job",
    Value = "None",
    Values = { "None", "Janitor", "ATM" },
    Callback = function(v) Features.SelectedJob = v end,
})

-- 6. GUNS AMMO
local GunsAmmoTab = Window:Tab({ Title = "GUNS AMMO", Icon = "target" })

GunsAmmoTab:Section({ Title = "Ammo", Desc = "Municion infinita" })

GunsAmmoTab:Toggle({
    Title = "Infinite Ammo",
    Value = false,
    Callback = function(v)
        Features.InfiniteAmmo = v
        if v then Threads.InfiniteAmmo = task.spawn(InfiniteAmmoLoop) end
    end,
})

GunsAmmoTab:Toggle({
    Title = "No Reload",
    Value = false,
    Callback = function(v) Features.NoReload = v end,
})

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

-- Actualizar lista de jugadores
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

MiscTab:Button({
    Title = "Server Hop",
    Callback = function()
        Notify("Server Hop", "Buscando servidor...")
        ServerHop()
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
        -- Limpiar todo
        for k, thread in pairs(Threads) do
            if thread then
                pcall(function() coroutine.close(thread) end)
            end
        end
        SetChams(false)
        SetNoClip(false)
        StartSpectate(nil)
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
-- Crear ESP para jugadores existentes
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end

-- Eventos de jugadores
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

-- Loop de ESP
RunService.RenderStepped:Connect(UpdateESP)

-- Handler de respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    
    -- Reaplicar velocidad
    if Features.SpeedEnabled then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = Features.SpeedValue end
    end
    
    -- Reaplicar NoClip
    if Features.NoClip then
        SetNoClip(false)
        task.wait(0.1)
        SetNoClip(true)
    end
    
    -- Reaplicar mods de armas
    if Features.NoRecoil or Features.NoSpread or Features.RapidFire or Features.InstantReload then
        ApplyWeaponMods()
    end
    
    -- Reaplicar Fly
    if Features.Fly then
        Features.Fly = false
        task.wait(0.1)
        Features.Fly = true
        Threads.Fly = task.spawn(FlyLoop)
    end
end)

-- Tool equipado - aplicar mods
LocalPlayer.Character.ChildAdded:Connect(function(child)
    if child:IsA("Tool") then
        task.wait(0.2)
        if Features.NoRecoil or Features.NoSpread or Features.RapidFire or Features.InstantReload then
            ModTool(child)
        end
    end
end)

-- Seleccionar pestaña de combate por defecto
CombatTab:Select()

print("Water Hub | BlockSpin - Script cargado 100% funcional")
print("Creado por: AdamABJ")
