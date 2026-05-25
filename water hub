--[[
    WATER HUB | BLOCKSPIN - VERSIÓN FINAL ESTABLE
    Fixes: Silent Aim sin crash, Magneto optimizado, Control de hilos limpio
--]]

-- ============================================
-- SERVICIOS Y CONFIGURACIÓN INICIAL
-- ============================================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local gethui = gethui or function() return CoreGui end

-- Cache de cámara optimizado
local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)

print("🌀 Water Hub | BlockSpin - Iniciando...")

-- ============================================
-- CARGAR WINDUI
-- ============================================
local WindUI
local success, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if success and result then
    WindUI = result
else
    success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()
    end)
    if success and result then
        WindUI = result
    else
        warn("❌ Error cargando WindUI")
        return
    end
end

if not WindUI or not WindUI.CreateWindow then
    warn("❌ WindUI inválido")
    return
end

-- ============================================
-- REMOTES
-- ============================================
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local SendRemote = Remotes and Remotes:FindFirstChild("Send")
local EventRemote = ReplicatedStorage:FindFirstChild("Event")

-- ============================================
-- VARIABLES GLOBALES Y CONTROL DE HILOS
-- ============================================
local silentAimActive = false
local fovRadius = 200
local aimPart = "Head"
local speedEnabled = false
local speedAmount = 50
local infiniteJump = false
local noClipActive = false
local autoHealActive = false
local autoHealHP = 70
local autoHitActive = false
local noRecoilActive = false
local noSpreadActive = false
local magnetoActive = false
local magnetoRadius = 50
local magnetoSpeed = 60
local nameEspActive = false
local healthEspActive = false
local distanceEspActive = false
local inventoryEspActive = false

local threads = {}
local ESPs = {}
local MagnetoItems = {}
local ScreenGui = nil
local NoClipConnection = nil
local SilentAimTarget = nil

-- ============================================
-- IDS DE IMÁGENES
-- ============================================
local ItemImages = {
    ["Fists"] = "rbxassetid://116170302967943",
    ["Baseball Bat"] = "rbxassetid://70390201507839",
    ["Tactical Axe"] = "rbxassetid://128521472487967",
    ["Tactical Knife"] = "rbxassetid://138188463918911",
    ["Tactical Shovel"] = "rbxassetid://92343057781870",
    ["Crowbar"] = "rbxassetid://90424115101219",
    ["Switchblade"] = "rbxassetid://93060515735865",
    ["Granada"] = "rbxassetid://91702588622611",
    ["Molotov"] = "rbxassetid://109158861273815",
    ["FishingRodRegular"] = "rbxassetid://120270558984957",
    ["FishingRodPro"] = "rbxassetid://106570831786716",
    ["FishingRodUltimate"] = "rbxassetid://75257833138570",
    ["Mop"] = "rbxassetid://71489031926594",
    ["Bandage"] = "rbxassetid://135140124942347",
    ["First Aid Kit"] = "rbxassetid://128659636079830",
}

-- ============================================
-- FUNCIONES UTILITARIAS
-- ============================================
local function GetRealMoney()
    local cash, bank = 0, 0
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, stat in ipairs(leaderstats:GetChildren()) do
            local name = stat.Name:lower()
            if name:find("cash") or name:find("money") then
                cash = tonumber(stat.Value) or 0
            elseif name:find("bank") then
                bank = tonumber(stat.Value) or 0
            end
        end
    end
    return cash, bank
end

local function GetEquippedItem(player)
    local char = player.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or nil
end

-- ============================================
-- SILENT AIM - CÁLCULO SEGURO FUERA DEL HOOK
-- ============================================
RunService.RenderStepped:Connect(function()
    if not silentAimActive then 
        SilentAimTarget = nil 
        return 
    end
    
    local mouse = LocalPlayer:GetMouse()
    if not mouse or not Camera then return end
    
    local closest = nil
    local shortestDist = fovRadius
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local target = char and (char:FindFirstChild(aimPart) or char:FindFirstChild("Head"))
            local hum = char and char:FindFirstChild("Humanoid")
            
            if target and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(target.Position)
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

-- ============================================
-- SILENT AIM HOOK (SOLO LEE LA VARIABLE)
-- ============================================
local oldNamecall
local function SetupSilentAim()
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if silentAimActive and method == "FireServer" and SilentAimTarget and SilentAimTarget.Character then
            if self == SendRemote or self.Name:lower():find("hit") or self.Name:lower():find("damage") or self.Name:lower():find("shoot") then
                local targetPart = SilentAimTarget.Character:FindFirstChild(aimPart) or SilentAimTarget.Character:FindFirstChild("Head")
                if targetPart then
                    for i, arg in ipairs(args) do
                        if typeof(arg) == "Vector3" then
                            args[i] = targetPart.Position
                        elseif typeof(arg) == "CFrame" then
                            args[i] = CFrame.new(targetPart.Position)
                        elseif typeof(arg) == "Instance" and arg:IsA("BasePart") then
                            args[i] = targetPart
                        end
                    end
                    if #args == 1 and typeof(args[1]) == "Instance" then
                        args[1] = SilentAimTarget
                    end
                end
            end
        end
        return oldNamecall(self, unpack(args))
    end)
end

-- ============================================
-- NOCLIP ESTABLE
-- ============================================
local function SetNoClip(enabled)
    if enabled then
        if NoClipConnection then return end
        NoClipConnection = RunService.Stepped:Connect(function()
            if not noClipActive then return end
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

-- ============================================
-- ESP OPTIMIZADO
-- ============================================
local function GetESPScreenGui()
    if ScreenGui then return ScreenGui end
    local success, gui = pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "WaterHub_ESP_" .. tostring(math.random(1000, 9999))
        sg.ResetOnSpawn = false
        sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
        sg.Parent = gethui()
        return sg
    end)
    if success then
        ScreenGui = gui
        return gui
    end
    return nil
end

local function CreateESP(player)
    if ESPs[player] then return end
    local espGui = GetESPScreenGui()
    if not espGui then return end
    
    local esp = {}
    
    local function CreateLabel(name, size, color)
        local label = Instance.new("TextLabel")
        label.Name = name .. "_" .. player.Name
        label.Size = size or UDim2.new(0, 100, 0, 20)
        label.BackgroundTransparency = 1
        label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        label.TextSize = 12
        label.Font = Enum.Font.GothamBold
        label.Parent = espGui
        return label
    end
    
    esp.Name = CreateLabel("Name", UDim2.new(0, 200, 0, 20), Color3.fromRGB(255, 255, 255))
    esp.Name.Text = player.Name
    
    esp.HealthBg = Instance.new("Frame")
    esp.HealthBg.Name = "HealthBg_" .. player.Name
    esp.HealthBg.Size = UDim2.new(0, 100, 0, 6)
    esp.HealthBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    esp.HealthBg.BorderSizePixel = 0
    esp.HealthBg.Parent = espGui
    
    esp.HealthBar = Instance.new("Frame")
    esp.HealthBar.Name = "HealthBar_" .. player.Name
    esp.HealthBar.Size = UDim2.new(1, 0, 1, 0)
    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    esp.HealthBar.BorderSizePixel = 0
    esp.HealthBar.Parent = esp.HealthBg
    
    esp.Distance = CreateLabel("Distance", UDim2.new(0, 100, 0, 15), Color3.fromRGB(200, 200, 200))
    esp.Distance.TextSize = 10
    
    esp.Item = CreateLabel("Item", UDim2.new(0, 150, 0, 20), Color3.fromRGB(255, 200, 100))
    esp.Item.TextSize = 10
    
    esp.ItemIcon = Instance.new("ImageLabel")
    esp.ItemIcon.Name = "ItemIcon_" .. player.Name
    esp.ItemIcon.Size = UDim2.new(0, 20, 0, 20)
    esp.ItemIcon.BackgroundTransparency = 1
    esp.ItemIcon.Parent = espGui
    
    esp.LastItem = nil
    ESPs[player] = esp
end

local function UpdateESPPositions()
    if not Camera then return end
    local myChar = LocalPlayer.Character
    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    for player, esp in pairs(ESPs) do
        local success = pcall(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local distance = myHrp and (myHrp.Position - hrp.Position).Magnitude or 0
                    local healthPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    
                    if nameEspActive then
                        esp.Name.Position = UDim2.new(0, pos.X - 100, 0, pos.Y - 50)
                        esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end
                    
                    if healthEspActive then
                        esp.HealthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
                        esp.HealthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                        esp.HealthBg.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 30)
                        esp.HealthBg.Visible = true
                    else
                        esp.HealthBg.Visible = false
                    end
                    
                    if distanceEspActive then
                        esp.Distance.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 20)
                        esp.Distance.Text = math.floor(distance) .. "m"
                        esp.Distance.Visible = true
                    else
                        esp.Distance.Visible = false
                    end
                    
                    if inventoryEspActive then
                        esp.Item.Position = UDim2.new(0, pos.X - 75, 0, pos.Y - 10)
                        if esp.ItemIcon.Visible then
                            esp.ItemIcon.Position = UDim2.new(0, pos.X - 95, 0, pos.Y - 10)
                        end
                    else
                        esp.Item.Visible = false
                        esp.ItemIcon.Visible = false
                    end
                else
                    esp.Name.Visible = false
                    esp.HealthBg.Visible = false
                    esp.Distance.Visible = false
                    esp.Item.Visible = false
                    esp.ItemIcon.Visible = false
                end
            else
                esp.Name.Visible = false
                esp.HealthBg.Visible = false
                esp.Distance.Visible = false
                esp.Item.Visible = false
                esp.ItemIcon.Visible = false
            end
        end)
    end
end

local function UpdateESPData()
    while true do
        if inventoryEspActive then
            for player, esp in pairs(ESPs) do
                pcall(function()
                    local itemName = GetEquippedItem(player)
                    if itemName ~= esp.LastItem then
                        esp.LastItem = itemName
                        if itemName then
                            esp.Item.Text = "🔫 " .. itemName
                            local imgId = ItemImages[itemName]
                            if imgId then
                                esp.ItemIcon.Image = imgId
                                esp.ItemIcon.Visible = true
                            else
                                esp.ItemIcon.Visible = false
                            end
                            esp.Item.Visible = true
                        else
                            esp.Item.Visible = false
                            esp.ItemIcon.Visible = false
                        end
                    end
                end)
            end
        end
        task.wait(0.3)
    end
end

-- ============================================
-- MAGNETO OPTIMIZADO (EVENTOS + ESCANEO ÚNICO)
-- ============================================
local function ScanMapForItems()
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            local name = part.Name
            if name:find("Cash") or name:find("Money") or name:find("Ammo") or part:GetAttribute("Item") then
                if part.Parent and not part.Parent:FindFirstChild("Humanoid") then
                    MagnetoItems[part] = true
                end
            end
        end
    end
end

Workspace.DescendantAdded:Connect(function(part)
    if part:IsA("BasePart") then
        task.wait(0.1)
        if part and part.Parent then
            local name = part.Name
            if name:find("Cash") or name:find("Money") or name:find("Ammo") or part:GetAttribute("Item") then
                if not part.Parent:FindFirstChild("Humanoid") then
                    MagnetoItems[part] = true
                end
            end
        end
    end
end)

local function MagnetoLoop()
    ScanMapForItems()
    while magnetoActive do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            for part, _ in pairs(MagnetoItems) do
                if part and part.Parent and part:IsA("BasePart") then
                    local dist = (part.Position - hrp.Position).Magnitude
                    if dist < magnetoRadius then
                        local dir = (hrp.Position - part.Position).Unit
                        part.Velocity = dir * magnetoSpeed
                        part.AssemblyLinearVelocity = dir * magnetoSpeed
                    end
                elseif not part or not part.Parent then
                    MagnetoItems[part] = nil
                end
            end
        end
        task.wait(0.1)
    end
end

-- ============================================
-- LOOPS CON CONTROL DE HILOS LIMPIO
-- ============================================
local function StartSpeedLoop()
    if threads.Speed then return end
    threads.Speed = task.spawn(function()
        while speedEnabled do
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = speedAmount
            end
            task.wait(0.1)
        end
        threads.Speed = nil
    end)
end

local function AutoHealLoop()
    if threads.AutoHeal then return end
    threads.AutoHeal = task.spawn(function()
        while autoHealActive do
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum and (hum.Health / hum.MaxHealth) * 100 < autoHealHP then
                if EventRemote then
                    pcall(function() EventRemote:FireServer("Heal", "Medkit") end)
                end
            end
            task.wait(1)
        end
        threads.AutoHeal = nil
    end)
end

local function AutoHitLoop()
    if threads.AutoHit then return end
    threads.AutoHit = task.spawn(function()
        while autoHitActive do
            if SilentAimTarget and SendRemote then
                pcall(function() SendRemote:FireServer("Hit", SilentAimTarget) end)
            end
            task.wait(0.3)
        end
        threads.AutoHit = nil
    end)
end

-- ============================================
-- VENTANA PRINCIPAL
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | BlockSpin",
    Author = "By: AdamABJ",
    Folder = "WaterHub_AdamABJ",
    Icon = "droplet",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Abrir Water Hub",
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
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
})

-- ============================================
-- PESTAÑAS
-- ============================================
local GeneralTab = Window:Tab({ Title = "General", Icon = "user", Border = true })
local CombatTab = Window:Tab({ Title = "Combate", Icon = "sword", Border = true })
local WeaponsTab = Window:Tab({ Title = "Armas", Icon = "settings", Border = true })
local EspTab = Window:Tab({ Title = "ESP", Icon = "eye", Border = true })
local MagnetoTab = Window:Tab({ Title = "Magneto", Icon = "magnet", Border = true })

-- ============================================
-- PESTAÑA: GENERAL
-- ============================================
local GeneralGroup = GeneralTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "Movimiento" })

GeneralGroup:Toggle({
    Flag = "SpeedHack",
    Title = "Speed Hack",
    Value = false,
    Callback = function(v)
        speedEnabled = v
        if v then
            StartSpeedLoop()
        else
            threads.Speed = nil -- LIMPIAR HILO
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end,
})

GeneralGroup:Slider({
    Flag = "SpeedValue",
    Title = "Velocidad",
    Step = 1,
    Value = { Min = 16, Max = 250, Default = 50 },
    Callback = function(v)
        speedAmount = v
    end,
})

GeneralGroup:Toggle({
    Flag = "InfiniteJump",
    Title = "Salto Infinito",
    Value = false,
    Callback = function(v)
        infiniteJump = v
        if v then
            task.spawn(function()
                while infiniteJump do
                    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
                    if hum and hum:GetState() == Enum.HumanoidStateType.Landed then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                    task.wait(0.1)
                end
            end)
        end
    end,
})

GeneralGroup:Toggle({
    Flag = "NoClip",
    Title = "No Clip",
    Value = false,
    Callback = function(v)
        noClipActive = v
        SetNoClip(v)
    end,
})

-- ============================================
-- PESTAÑA: COMBATE
-- ============================================
local CombatGroup = CombatTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "Aimbot" })

CombatGroup:Toggle({
    Flag = "SilentAim",
    Title = "Silent Aim (Hook Real)",
    Value = false,
    Callback = function(v)
        silentAimActive = v
        if v and not oldNamecall then
            SetupSilentAim()
        end
    end,
})

CombatGroup:Slider({
    Flag = "FOV",
    Title = "Radio FOV",
    Step = 1,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v)
        fovRadius = v
    end,
})

CombatGroup:Dropdown({
    Flag = "AimPart",
    Title = "Parte Objetivo",
    Values = { "Head", "HumanoidRootPart", "Torso" },
    Value = "Head",
    Callback = function(v)
        aimPart = v
    end,
})

local AutoGroup = CombatTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "Automático" })

AutoGroup:Toggle({
    Flag = "AutoHeal",
    Title = "Curación Automática",
    Value = false,
    Callback = function(v)
        autoHealActive = v
        if v then AutoHealLoop() else threads.AutoHeal = nil end
    end,
})

AutoGroup:Slider({
    Flag = "HealHP",
    Title = "Curar al % de vida",
    Step = 1,
    Value = { Min = 20, Max = 90, Default = 70 },
    Callback = function(v)
        autoHealHP = v
    end,
})

AutoGroup:Toggle({
    Flag = "AutoHit",
    Title = "Golpe Automático",
    Value = false,
    Callback = function(v)
        autoHitActive = v
        if v then AutoHitLoop() else threads.AutoHit = nil end
    end,
})

-- ============================================
-- PESTAÑA: ARMAS
-- ============================================
local WeaponGroup = WeaponsTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "Modificaciones" })

WeaponGroup:Toggle({
    Flag = "NoRecoil",
    Title = "Sin Retroceso",
    Value = false,
    Callback = function(v)
        noRecoilActive = v
        LocalPlayer:SetAttribute("NoRecoil", v)
    end,
})

WeaponGroup:Toggle({
    Flag = "NoSpread",
    Title = "Sin Dispersión",
    Value = false,
    Callback = function(v)
        noSpreadActive = v
        LocalPlayer:SetAttribute("NoSpread", v)
    end,
})

-- ============================================
-- PESTAÑA: ESP
-- ============================================
local EspGroup = EspTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "Visualización" })

EspGroup:Toggle({
    Flag = "NameESP",
    Title = "Nombre ESP",
    Value = false,
    Callback = function(v)
        nameEspActive = v
    end,
})

EspGroup:Toggle({
    Flag = "HealthESP",
    Title = "Vida ESP",
    Value = false,
    Callback = function(v)
        healthEspActive = v
    end,
})

EspGroup:Toggle({
    Flag = "DistanceESP",
    Title = "Distancia ESP",
    Value = false,
    Callback = function(v)
        distanceEspActive = v
    end,
})

EspGroup:Toggle({
    Flag = "InventoryESP",
    Title = "Inventario ESP (Arma)",
    Value = false,
    Callback = function(v)
        inventoryEspActive = v
    end,
})

-- ============================================
-- PESTAÑA: MAGNETO
-- ============================================
local MagnetoGroup = MagnetoTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "Atracción de Items" })

MagnetoGroup:Toggle({
    Flag = "Magneto",
    Title = "Magneto Activado",
    Value = false,
    Callback = function(v)
        magnetoActive = v
        if v then
            if threads.Magneto then return end
            threads.Magneto = task.spawn(MagnetoLoop)
        else
            magnetoActive = false
            threads.Magneto = nil -- LIMPIAR HILO
            MagnetoItems = {}
        end
    end,
})

MagnetoGroup:Slider({
    Flag = "MagnetoRadius",
    Title = "Radio de Atracción",
    Step = 1,
    Value = { Min = 10, Max = 100, Default = 50 },
    Callback = function(v)
        magnetoRadius = v
    end,
})

MagnetoGroup:Slider({
    Flag = "MagnetoSpeed",
    Title = "Velocidad de Atracción",
    Step = 1,
    Value = { Min = 20, Max = 150, Default = 60 },
    Callback = function(v)
        magnetoSpeed = v
    end,
})

-- ============================================
-- INICIALIZACIÓN ESP
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

Players.PlayerRemoving:Connect(function(player)
    local esp = ESPs[player]
    if esp then
        pcall(function()
            if esp.Name then esp.Name:Destroy() end
            if esp.HealthBg then esp.HealthBg:Destroy() end
            if esp.Distance then esp.Distance:Destroy() end
            if esp.Item then esp.Item:Destroy() end
            if esp.ItemIcon then esp.ItemIcon:Destroy() end
        end)
        ESPs[player] = nil
    end
end)

-- Conexiones optimizadas
RunService.RenderStepped:Connect(UpdateESPPositions)
task.spawn(UpdateESPData)

-- Respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if speedEnabled then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = speedAmount end
    end
    if noClipActive then
        SetNoClip(false)
        task.wait(0.1)
        SetNoClip(true)
    end
end)

-- Notificación
pcall(function()
    WindUI:Notify({
        Title = "Water Hub",
        Content = "Script cargado correctamente - Versión Estable",
        Icon = "droplet",
        Duration = 3,
    })
end)

print("✅ Water Hub cargado - Versión Final Estable para Delta")
