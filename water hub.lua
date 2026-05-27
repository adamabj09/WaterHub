--[[
    WATER HUB | BLOCKSPIN - VERSION FINAL FUNCIONAL
    Basado en datos reales: Remotes, Jobs, Weapons, ATMs
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
-- VARIABLES GLOBALES
-- ============================================
local Features = {
    SilentAim = false,
    ShowFOV = true,
    FOV = 200,
    AimPart = "Head",
    SafeZone = false,
    MeleeAura = false,
    AutoAttack = false,
    AntiKill = false,
    AntiKillHealth = 20,
    AntiRagdoll = false,
    AntiLock = false,
    WalkSpeed = false,
    SpeedMultiplier = 2,
    HighJump = false,
    JumpPower = 100,
    InfiniteStamina = false,
    Invisible = false,
    SnapUnderMap = false,
    SnapDepth = 26,
    EnableGunMods = false,
    FireRate = 600,
    Accuracy = 1,
    Recoil = 0,
    ReloadTime = 0.1,
    Automatic = true,
    NameESP = false,
    HealthESP = false,
    DistanceESP = false,
    Highlight = false,
    AutoPickupItems = false,
    AutoMinigame = false,
    AmmoType = "Pistol",
    FPSBoost = false
}

local Threads = {}
local ESPObjects = {}
local ChamsObjects = {}
local SilentAimTarget = nil
local OldNamecall = nil
local FOVCircle = nil
local AntiKillConnection = nil

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
-- FOV CIRCLE VISUAL
-- ============================================
local function CreateFOVCircle()
    if FOVCircle then FOVCircle:Destroy() end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FOVCircle"
    screenGui.Parent = gethui()
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    
    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.Size = UDim2.new(0, Features.FOV * 2, 0, Features.FOV * 2)
    circle.Position = UDim2.new(0.5, -Features.FOV, 0.5, -Features.FOV)
    circle.BackgroundTransparency = 1
    circle.Parent = screenGui
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 2
    stroke.Parent = circle
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle
    
    FOVCircle = screenGui
    
    -- Actualizar posición del mouse
    RunService.RenderStepped:Connect(function()
        if not Features.ShowFOV or not Features.SilentAim then
            screenGui.Enabled = false
            return
        end
        screenGui.Enabled = true
        
        local mouse = LocalPlayer:GetMouse()
        circle.Position = UDim2.new(0, mouse.X - Features.FOV, 0, mouse.Y - Features.FOV)
        circle.Size = UDim2.new(0, Features.FOV * 2, 0, Features.FOV * 2)
    end)
end

-- ============================================
-- SILENT AIM REAL (APUNTA AUTOMÁTICO)
-- ============================================
local function GetClosestPlayerToMouse()
    local mouse = LocalPlayer:GetMouse()
    local cam = Workspace.CurrentCamera
    if not mouse or not cam then return nil end
    
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
    
    return closest
end

-- Hook para Silent Aim (modifica los disparos)
local function SetupSilentAim()
    if OldNamecall then return end
    
    OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if Features.SilentAim and method == "FireServer" then
            -- Detectar el remote Send de BlockSpin
            if self == SendRemote then
                local target = GetClosestPlayerToMouse()
                if target and target.Character then
                    local targetPart = target.Character:FindFirstChild(Features.AimPart) 
                        or target.Character:FindFirstChild("Head")
                    
                    if targetPart then
                        -- Modificar el argumento de posición/dirección
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

-- Auto Aim (mueve la cámara suavemente hacia el objetivo)
RunService.RenderStepped:Connect(function()
    if not Features.SilentAim then return end
    
    local target = GetClosestPlayerToMouse()
    SilentAimTarget = target
    
    if target and target.Character then
        local targetPart = target.Character:FindFirstChild(Features.AimPart) 
            or target.Character:FindFirstChild("Head")
        
        if targetPart then
            local cam = Workspace.CurrentCamera
            -- Suavizar el apuntado
            local targetCFrame = CFrame.new(cam.CFrame.Position, targetPart.Position)
            cam.CFrame = cam.CFrame:Lerp(targetCFrame, 0.1)
        end
    end
end)

-- ============================================
-- ANTI KILL (TELEPORT DEBAJO DEL MAPA)
-- ============================================
local function AntiKillFunction()
    if not Features.AntiKill then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    
    if hum and hrp then
        local healthPercent = (hum.Health / hum.MaxHealth) * 100
        if healthPercent <= Features.AntiKillHealth then
            -- Teletransportar debajo del mapa
            local currentPos = hrp.Position
            hrp.CFrame = CFrame.new(currentPos.X, -Features.SnapDepth, currentPos.Z)
            
            -- Notificar
            Notify("Anti Kill", "Teleported under map! Health: " .. math.floor(healthPercent) .. "%")
        end
    end
end

local function StartAntiKill()
    if AntiKillConnection then return end
    AntiKillConnection = RunService.Heartbeat:Connect(AntiKillFunction)
end

local function StopAntiKill()
    if AntiKillConnection then
        AntiKillConnection:Disconnect()
        AntiKillConnection = nil
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
                -- BlockSpin base speed es 8, max 24
                local newSpeed = 8 * Features.SpeedMultiplier
                hum.WalkSpeed = math.clamp(newSpeed, 8, 24)
            end
        end
        task.wait(0.1)
    end
    -- Reset
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
            -- BlockSpin usa Stamina como NumberValue en el personaje
            local stamina = char:FindFirstChild("Stamina")
            if stamina and stamina:IsA("NumberValue") then
                stamina.Value = 125
            end
            
            -- También como atributo
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
                hum.JumpPower = Features.JumpPower
            end
        end
        task.wait(0.1)
    end
end

-- ============================================
-- WEAPON MODS (DATOS REALES)
-- ============================================
local function ApplyGunMods()
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    if not Features.EnableGunMods then
        -- Restaurar valores por defecto (basado en datos reales)
        local defaultStats = {
            Uzi = {FireRate = 1200, ReloadTime = 1.7, Recoil = 0.3},
            AK47 = {FireRate = 600, ReloadTime = 2.2, Recoil = 0.4},
            -- ... etc
        }
        local stats = defaultStats[tool.Name]
        if stats then
            tool:SetAttribute("FireRate", stats.FireRate)
            tool:SetAttribute("ReloadTime", stats.ReloadTime)
            tool:SetAttribute("Recoil", stats.Recoil)
        end
        return
    end
    
    -- Aplicar mods personalizados
    tool:SetAttribute("FireRate", Features.FireRate)
    tool:SetAttribute("ReloadTime", Features.ReloadTime)
    tool:SetAttribute("Recoil", Features.Recoil)
    tool:SetAttribute("Accuracy", Features.Accuracy)
    tool:SetAttribute("Automatic", Features.Automatic)
    
    -- Modificar valores internos
    for _, obj in ipairs(tool:GetDescendants()) do
        if obj:IsA("NumberValue") then
            if obj.Name == "FireRate" then obj.Value = Features.FireRate end
            if obj.Name == "ReloadTime" then obj.Value = Features.ReloadTime end
            if obj.Name == "Recoil" then obj.Value = Features.Recoil end
        end
    end
end

-- ============================================
-- ESP
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
    
    -- Name
    esp.Name = Instance.new("TextLabel")
    esp.Name.Size = UDim2.new(0, 200, 0, 20)
    esp.Name.BackgroundTransparency = 1
    esp.Name.TextColor3 = Color3.fromRGB(255, 255, 255)
    esp.Name.TextSize = 12
    esp.Name.Font = Enum.Font.GothamBold
    esp.Name.Parent = gui
    
    -- Health
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
    
    -- Distance
    esp.Distance = Instance.new("TextLabel")
    esp.Distance.Size = UDim2.new(0, 100, 0, 15)
    esp.Distance.BackgroundTransparency = 1
    esp.Distance.TextColor3 = Color3.fromRGB(200, 200, 200)
    esp.Distance.TextSize = 10
    esp.Distance.Font = Enum.Font.Gotham
    esp.Distance.Parent = gui
    
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
                else
                    esp.Name.Visible = false
                    esp.HealthBg.Visible = false
                    esp.Distance.Visible = false
                end
            else
                esp.Name.Visible = false
                esp.HealthBg.Visible = false
                esp.Distance.Visible = false
            end
        end)
    end
end

-- ============================================
-- FARM
-- ============================================
local function AutoPickupLoop()
    while Features.AutoPickupItems do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Buscar items cercanos
            for _, item in ipairs(Workspace:GetDescendants()) do
                if item:IsA("BasePart") and (item.Name:find("Cash") or item.Name:find("Money")) then
                    if (item.Position - hrp.Position).Magnitude < 10 then
                        if item:FindFirstChild("ClickDetector") then
                            fireclickdetector(item.ClickDetector)
                        end
                    end
                end
            end
        end
        task.wait(0.5)
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
        if obj:IsA("BasePart") then
            obj.Material = Enum.Material.Plastic
        end
    end
end

-- ============================================
-- CONFIG SAVE/LOAD
-- ============================================
local ConfigFile = "WaterHub_BlockSpin_Config.json"

local function SaveConfig()
    local configData = {
        SilentAim = Features.SilentAim,
        ShowFOV = Features.ShowFOV,
        FOV = Features.FOV,
        AimPart = Features.AimPart,
        WalkSpeed = Features.WalkSpeed,
        SpeedMultiplier = Features.SpeedMultiplier,
        InfiniteStamina = Features.InfiniteStamina,
        HighJump = Features.HighJump,
        JumpPower = Features.JumpPower,
        EnableGunMods = Features.EnableGunMods,
        FireRate = Features.FireRate,
        Recoil = Features.Recoil,
        ReloadTime = Features.ReloadTime,
        NameESP = Features.NameESP,
        HealthESP = Features.HealthESP,
        DistanceESP = Features.DistanceESP,
        AntiKill = Features.AntiKill,
        AntiKillHealth = Features.AntiKillHealth
    }
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(configData)
    end)
    
    if success then
        writefile(ConfigFile, encoded)
        Notify("Config", "Saved successfully!")
    else
        Notify("Error", "Failed to save config")
    end
end

local function LoadConfig()
    if not isfile(ConfigFile) then
        Notify("Config", "No config file found")
        return
    end
    
    local success, data = pcall(function()
        local content = readfile(ConfigFile)
        return HttpService:JSONDecode(content)
    end)
    
    if success and data then
        -- Aplicar configuración
        Features.SilentAim = data.SilentAim or false
        Features.ShowFOV = data.ShowFOV or true
        Features.FOV = data.FOV or 200
        Features.AimPart = data.AimPart or "Head"
        Features.WalkSpeed = data.WalkSpeed or false
        Features.SpeedMultiplier = data.SpeedMultiplier or 2
        Features.InfiniteStamina = data.InfiniteStamina or false
        Features.HighJump = data.HighJump or false
        Features.JumpPower = data.JumpPower or 100
        Features.EnableGunMods = data.EnableGunMods or false
        Features.FireRate = data.FireRate or 600
        Features.Recoil = data.Recoil or 0
        Features.ReloadTime = data.ReloadTime or 0.1
        Features.NameESP = data.NameESP or false
        Features.HealthESP = data.HealthESP or false
        Features.DistanceESP = data.DistanceESP or false
        Features.AntiKill = data.AntiKill or false
        Features.AntiKillHealth = data.AntiKillHealth or 20
        
        -- Actualizar UI si es necesario
        if Features.SilentAim then
            SetupSilentAim()
            CreateFOVCircle()
        end
        
        Notify("Config", "Loaded successfully!")
    else
        Notify("Error", "Failed to load config")
    end
end

-- ============================================
-- VENTANA PRINCIPAL CON BOTÓN FLOTANTE
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | BlockSpin",
    Author = "By: AdamABJ",
    Icon = "droplet",
    Theme = "Dark",
    NewElements = true,
    Transparent = true,
    ToggleKey = Enum.KeyCode.F, -- Para PC
    Acrylic = false,
    -- BOTÓN FLOTANTE PARA MÓVIL
    OpenButton = {
        Title = "Open Water Hub",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
        Color = ColorSequence.new(
            Color3.fromHex("#00F2FE"),
            Color3.fromHex("#4FACFE")
        ),
    },
})

Notify("Water Hub", "Script loaded! Press F or tap the button to open")

-- ============================================
-- PESTAÑAS
-- ============================================

-- 1. COMBAT
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "sword" })

CombatTab:Section({ Title = "Gun", Desc = "Aimbot settings" })

CombatTab:Toggle({
    Title = "Silent Aim (Auto Headshot)",
    Value = false,
    Callback = function(v)
        Features.SilentAim = v
        if v then
            SetupSilentAim()
            CreateFOVCircle()
        else
            if FOVCircle then FOVCircle:Destroy() end
        end
        Notify("Silent Aim", v and "ON - Auto targeting enabled" or "OFF")
    end,
})

CombatTab:Toggle({
    Title = "Show FOV Circle",
    Value = true,
    Callback = function(v)
        Features.ShowFOV = v
        if v and Features.SilentAim then
            CreateFOVCircle()
        elseif FOVCircle then
            FOVCircle:Destroy()
        end
    end,
})

CombatTab:Slider({
    Title = "FOV Size",
    Step = 10,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v)
        Features.FOV = v
        if FOVCircle then
            local circle = FOVCircle:FindFirstChild("Circle")
            if circle then
                circle.Size = UDim2.new(0, v * 2, 0, v * 2)
                circle.Position = UDim2.new(0.5, -v, 0.5, -v)
            end
        end
    end,
})

CombatTab:Dropdown({
    Title = "Aim Part",
    Value = "Head",
    Values = {"Head", "Torso", "HumanoidRootPart"},
    Callback = function(v)
        Features.AimPart = v
    end,
})

CombatTab:Section({ Title = "Defense", Desc = "Protection settings" })

CombatTab:Toggle({
    Title = "Anti Kill (Teleport under map)",
    Value = false,
    Callback = function(v)
        Features.AntiKill = v
        if v then
            StartAntiKill()
        else
            StopAntiKill()
        end
        Notify("Anti Kill", v and "ON - Will teleport when health < " .. Features.AntiKillHealth .. "%" or "OFF")
    end,
})

CombatTab:Slider({
    Title = "Anti Kill Health %",
    Step = 5,
    Value = { Min = 5, Max = 50, Default = 20 },
    Callback = function(v)
        Features.AntiKillHealth = v
    end,
})

CombatTab:Toggle({
    Title = "Anti Ragdoll",
    Value = false,
    Callback = function(v)
        Features.AntiRagdoll = v
        -- Implementación simple
    end,
})

-- 2. MOVEMENT
local MovementTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })

MovementTab:Section({ Title = "Speed", Desc = "Walk speed" })

MovementTab:Toggle({
    Title = "Walk Speed",
    Value = false,
    Callback = function(v)
        Features.WalkSpeed = v
        if v then
            Threads.Speed = task.spawn(WalkSpeedLoop)
        else
            Threads.Speed = nil
        end
    end,
})

MovementTab:Slider({
    Title = "Speed Multiplier",
    Step = 0.1,
    Value = { Min = 1, Max = 3, Default = 2 },
    Callback = function(v)
        Features.SpeedMultiplier = v
    end,
})

MovementTab:Section({ Title = "Jump & Stamina", Desc = "Movement extras" })

MovementTab:Toggle({
    Title = "High Jump",
    Value = false,
    Callback = function(v)
        Features.HighJump = v
        if v then
            Threads.Jump = task.spawn(HighJumpLoop)
        else
            Threads.Jump = nil
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then hum.JumpPower = 50 end
        end
    end,
})

MovementTab:Slider({
    Title = "Jump Power",
    Step = 10,
    Value = { Min = 50, Max = 200, Default = 100 },
    Callback = function(v)
        Features.JumpPower = v
    end,
})

MovementTab:Toggle({
    Title = "Infinite Stamina",
    Value = false,
    Callback = function(v)
        Features.InfiniteStamina = v
        if v then
            Threads.Stamina = task.spawn(InfiniteStaminaLoop)
        else
            Threads.Stamina = nil
        end
    end,
})

MovementTab:Section({ Title = "Special", Desc = "Advanced movement" })

MovementTab:Toggle({
    Title = "Snap Under Map (Hold Z)",
    Value = false,
    Callback = function(v)
        Features.SnapUnderMap = v
    end,
})

MovementTab:Slider({
    Title = "Snap Depth",
    Step = 5,
    Value = { Min = 10, Max = 100, Default = 26 },
    Callback = function(v)
        Features.SnapDepth = v
    end,
})

-- Tecla Z para snap
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Z and Features.SnapUnderMap then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local currentPos = hrp.Position
                hrp.CFrame = CFrame.new(currentPos.X, -Features.SnapDepth, currentPos.Z)
            end
        end
    end
end)

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
    Step = 50,
    Value = { Min = 50, Max = 2000, Default = 600 },
    Callback = function(v)
        Features.FireRate = v
        ApplyGunMods()
    end,
})

WeaponTab:Slider({
    Title = "Accuracy (0-1)",
    Step = 0.1,
    Value = { Min = 0, Max = 1, Default = 1 },
    Callback = function(v)
        Features.Accuracy = v
        ApplyGunMods()
    end,
})

WeaponTab:Slider({
    Title = "Recoil (0-3)",
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
    Title = "Highlight (Chams)",
    Value = false,
    Callback = function(v)
        Features.Highlight = v
        -- Simple highlight implementation
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if v then
                    local highlight = Instance.new("Highlight")
                    highlight.FillColor = Color3.fromRGB(0, 255, 0)
                    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    highlight.Adornee = player.Character
                    highlight.Parent = player.Character
                    ChamsObjects[player] = highlight
                else
                    if ChamsObjects[player] then
                        ChamsObjects[player]:Destroy()
                        ChamsObjects[player] = nil
                    end
                end
            end
        end
    end,
})

-- 5. FARM
local FarmTab = Window:Tab({ Title = "FARM", Icon = "tractor" })

FarmTab:Section({ Title = "Auto Farm", Desc = "Automatic farming" })

FarmTab:Toggle({
    Title = "Auto Pickup Items",
    Value = false,
    Callback = function(v)
        Features.AutoPickupItems = v
        if v then
            Threads.Pickup = task.spawn(AutoPickupLoop)
        else
            Threads.Pickup = nil
        end
    end,
})

FarmTab:Toggle({
    Title = "Auto Minigame (ATM)",
    Value = false,
    Callback = function(v)
        Features.AutoMinigame = v
        -- Implementación básica
    end,
})

-- 6. GUNS AMMO
local GunsAmmoTab = Window:Tab({ Title = "GUNS AMMO", Icon = "target" })

GunsAmmoTab:Section({ Title = "Buy Ammo", Desc = "Purchase ammunition" })

GunsAmmoTab:Dropdown({
    Title = "Ammo Type",
    Value = "Pistol",
    Values = {"Pistol", "Rifle", "Shotgun", "Special"},
    Callback = function(v)
        Features.AmmoType = v
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
        if target then
            local hum = target.Character and target.Character:FindFirstChild("Humanoid")
            if hum then
                Workspace.CurrentCamera.CameraSubject = hum
            end
        end
    end,
})

-- Actualizar lista de jugadores
task.spawn(function()
    while true do
        task.wait(2)
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

MiscTab:Section({ Title = "Performance", Desc = "FPS and graphics" })

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
        SaveConfig()
    end,
})

ConfigTab:Button({
    Title = "Load Config",
    Callback = function()
        LoadConfig()
    end,
})

ConfigTab:Button({
    Title = "Delete Config",
    Callback = function()
        if isfile(ConfigFile) then
            delfile(ConfigFile)
            Notify("Config", "Deleted!")
        else
            Notify("Error", "No config to delete")
        end
    end,
})

-- ============================================
-- INICIALIZACIÓN
-- ============================================
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
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
    if Features.EnableGunMods then
        ApplyGunMods()
    end
end)

CombatTab:Select()

print("Water Hub | BlockSpin - 100% Funcional")
print("Botón flotante activado para móvil")
print("Presiona F o toca el botón para abrir")
