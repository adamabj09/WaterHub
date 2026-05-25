--[[
    WATER HUB | BLOCKSPIN - VERSIÓN CON NUEVA UI
    Fixes: UI moderna, Silent Aim estable, ESP con imágenes, Infinita Estamina
--]]

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer
local Workspace = cloneref(game:GetService("Workspace"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))
local StarterGui = cloneref(game:GetService("StarterGui"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local UserInputService = cloneref(game:GetService("UserInputService"))

local gethui = gethui or function() return CoreGui end

-- Cache de cámara
local Camera = Workspace.CurrentCamera
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    Camera = Workspace.CurrentCamera
end)

-- ============================================
-- CARGAR WINDUI (NUEVA VERSIÓN)
-- ============================================
local WindUI
do
    local ok, result = pcall(function()
        return require("./src/Init")
    end)

    if ok then
        WindUI = result
    else
        if RunService:IsStudio() or not writefile then
            WindUI = require(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init"))
        else
            WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
        end
    end
end

-- ============================================
-- REMOTES DE BLOCKSPIN
-- ============================================
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local SendRemote = Remotes and Remotes:FindFirstChild("Send")
local EventRemote = ReplicatedStorage:FindFirstChild("Event")

-- ============================================
-- VARIABLES GLOBALES
-- ============================================
local silentAimActive = false
local fovRadius = 200
local aimPart = "Head"
local speedEnabled = false
local speedAmount = 50
local infiniteJump = false
local infiniteStamina = false -- NUEVO
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
-- IDS DE IMÁGENES CORREGIDOS (ASSETIDS VÁLIDOS)
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
-- SILENT AIM - CÁLCULO FUERA DEL HOOK (ANTI-CRASH)
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
-- SILENT AIM HOOK (SOLO LEE VARIABLE, NO CALCULA)
-- ============================================
local oldNamecall
local function SetupSilentAim()
    if oldNamecall then return end -- Ya está configurado
    
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if silentAimActive and method == "FireServer" and SilentAimTarget and SilentAimTarget.Character then
            -- Detectar remotes de daño de BlockSpin
            local remoteName = self.Name:lower()
            if self == SendRemote or remoteName:find("hit") or remoteName:find("damage") or remoteName:find("shoot") or remoteName:find("fire") then
                local targetPart = SilentAimTarget.Character:FindFirstChild(aimPart) or SilentAimTarget.Character:FindFirstChild("Head")
                if targetPart then
                    -- Modificar argumentos para apuntar al enemigo
                    for i, arg in ipairs(args) do
                        if typeof(arg) == "Vector3" then
                            args[i] = targetPart.Position
                        elseif typeof(arg) == "CFrame" then
                            args[i] = CFrame.new(targetPart.Position)
                        elseif typeof(arg) == "Instance" and arg:IsA("BasePart") then
                            args[i] = targetPart
                        end
                    end
                    -- Si el primer argumento es el jugador objetivo
                    if #args >= 1 and typeof(args[1]) == "Instance" and args[1]:IsA("Player") then
                        args[1] = SilentAimTarget
                    end
                end
            end
        end
        return oldNamecall(self, unpack(args))
    end)
end

-- ============================================
-- INFINITA ESTAMINA (NUEVO)
-- ============================================
local function InfiniteStaminaLoop()
    while infiniteStamina do
        local char = LocalPlayer.Character
        if char then
            -- BlockSpin usa valores de stamina en el humanoid o atributos
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                -- Método 1: Restaurar stamina si existe como atributo
                if char:GetAttribute("Stamina") then
                    char:SetAttribute("Stamina", 100)
                end
                -- Método 2: Valor en humanoid
                if hum:GetAttribute("Stamina") then
                    hum:SetAttribute("Stamina", 100)
                end
            end
            -- Método 3: Buscar objeto de stamina en el personaje
            local staminaObj = char:FindFirstChild("Stamina") or char:FindFirstChild("stamina")
            if staminaObj and staminaObj:IsA("NumberValue") then
                staminaObj.Value = 100
            end
        end
        task.wait(0.1)
    end
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
-- ESP CON IMÁGENES CORREGIDAS
-- ============================================
local function GetESPScreenGui()
    if ScreenGui and ScreenGui.Parent then return ScreenGui end
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
    
    -- Contenedor para ítem con imagen
    esp.ItemContainer = Instance.new("Frame")
    esp.ItemContainer.Name = "ItemContainer_" .. player.Name
    esp.ItemContainer.Size = UDim2.new(0, 150, 0, 24)
    esp.ItemContainer.BackgroundTransparency = 1
    esp.ItemContainer.Parent = espGui
    
    esp.ItemIcon = Instance.new("ImageLabel")
    esp.ItemIcon.Name = "ItemIcon"
    esp.ItemIcon.Size = UDim2.new(0, 20, 0, 20)
    esp.ItemIcon.Position = UDim2.new(0, 0, 0, 2)
    esp.ItemIcon.BackgroundTransparency = 1
    esp.ItemIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    esp.ItemIcon.Parent = esp.ItemContainer
    
    esp.Item = Instance.new("TextLabel")
    esp.Item.Name = "ItemText"
    esp.Item.Size = UDim2.new(0, 125, 0, 20)
    esp.Item.Position = UDim2.new(0, 22, 0, 2)
    esp.Item.BackgroundTransparency = 1
    esp.Item.TextColor3 = Color3.fromRGB(255, 200, 100)
    esp.Item.TextSize = 10
    esp.Item.Font = Enum.Font.GothamBold
    esp.Item.TextXAlignment = Enum.TextXAlignment.Left
    esp.Item.Parent = esp.ItemContainer
    
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
                        esp.ItemContainer.Position = UDim2.new(0, pos.X - 75, 0, pos.Y - 10)
                        esp.ItemContainer.Visible = true
                    else
                        esp.ItemContainer.Visible = false
                    end
                else
                    esp.Name.Visible = false
                    esp.HealthBg.Visible = false
                    esp.Distance.Visible = false
                    esp.ItemContainer.Visible = false
                end
            else
                esp.Name.Visible = false
                esp.HealthBg.Visible = false
                esp.Distance.Visible = false
                esp.ItemContainer.Visible = false
            end
        end)
    end
end

-- Actualización de datos de ítems (cada 0.3s para rendimiento)
local function UpdateESPData()
    while true do
        if inventoryEspActive then
            for player, esp in pairs(ESPs) do
                pcall(function()
                    local itemName = GetEquippedItem(player)
                    if itemName ~= esp.LastItem then
                        esp.LastItem = itemName
                        if itemName then
                            esp.Item.Text = itemName
                            -- Buscar imagen del ítem
                            local imgId = ItemImages[itemName]
                            if imgId then
                                esp.ItemIcon.Image = imgId
                                esp.ItemIcon.Visible = true
                                esp.Item.Size = UDim2.new(0, 125, 0, 20)
                                esp.Item.Position = UDim2.new(0, 22, 0, 2)
                            else
                                esp.ItemIcon.Visible = false
                                esp.Item.Size = UDim2.new(0, 150, 0, 20)
                                esp.Item.Position = UDim2.new(0, 0, 0, 2)
                            end
                            esp.ItemContainer.Visible = true
                        else
                            esp.ItemContainer.Visible = false
                        end
                    end
                end)
            end
        end
        task.wait(0.3)
    end
end

-- ============================================
-- MAGNETO OPTIMIZADO
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
-- LOOPS CON CONTROL DE HILOS
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
-- VENTANA PRINCIPAL (NUEVA UI)
-- ============================================
local ThemeName = "Dark"

local Window = WindUI:CreateWindow({
    Title = "Water Hub | BlockSpin",
    Author = "By: AdamABJ",
    Icon = "solar:water-drop-bold-duotone",
    Theme = ThemeName,
    NewElements = true,
    Transparent = true,
    ToggleKey = Enum.KeyCode.F,
    Acrylic = true,
})

-- ============================================
-- PESTAÑAS
-- ============================================
local CombatTab = Window:Tab({
    Title = "Combate",
    Icon = "solar:sword-bold-duotone",
})

local MovementTab = Window:Tab({
    Title = "Movimiento",
    Icon = "solar:running-bold-duotone",
})

local VisualTab = Window:Tab({
    Title = "Visual",
    Icon = "solar:eye-bold-duotone",
})

local ItemsTab = Window:Tab({
    Title = "Items",
    Icon = "solar:magnet-bold-duotone",
})

local SettingsTab = Window:Tab({
    Title = "Config",
    Icon = "solar:settings-bold-duotone",
})

CombatTab:Select()

-- ============================================
-- PESTAÑA COMBATE
-- ============================================
CombatTab:Section({
    Title = "Aimbot",
    Desc = "Configuración de apuntado automático",
})

local SilentAimGroup = CombatTab:Group()

SilentAimGroup:Toggle({
    Title = "Silent Aim",
    Value = false,
    Callback = function(v)
        silentAimActive = v
        if v and not oldNamecall then
            SetupSilentAim()
        end
    end,
})

SilentAimGroup:Slider({
    Title = "Radio FOV",
    Step = 1,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v)
        fovRadius = v
    end,
})

SilentAimGroup:Dropdown({
    Title = "Parte Objetivo",
    Value = "Head",
    Values = { "Head", "HumanoidRootPart", "Torso" },
    Callback = function(v)
        aimPart = v
    end,
})

CombatTab:Space({ Columns = 1 })

CombatTab:Section({
    Title = "Automático",
    Desc = "Funciones automáticas de combate",
})

local AutoGroup = CombatTab:Group()

AutoGroup:Toggle({
    Title = "Auto Heal",
    Value = false,
    Callback = function(v)
        autoHealActive = v
        if v then AutoHealLoop() else threads.AutoHeal = nil end
    end,
})

AutoGroup:Slider({
    Title = "% Vida para curar",
    Step = 1,
    Value = { Min = 10, Max = 90, Default = 70 },
    Callback = function(v)
        autoHealHP = v
    end,
})

AutoGroup:Toggle({
    Title = "Auto Hit",
    Value = false,
    Callback = function(v)
        autoHitActive = v
        if v then AutoHitLoop() else threads.AutoHit = nil end
    end,
})

CombatTab:Space({ Columns = 1 })

CombatTab:Section({
    Title = "Armas",
    Desc = "Modificaciones de armas",
})

local WeaponGroup = CombatTab:Group()

WeaponGroup:Toggle({
    Title = "No Recoil",
    Value = false,
    Callback = function(v)
        noRecoilActive = v
        LocalPlayer:SetAttribute("NoRecoil", v)
    end,
})

WeaponGroup:Toggle({
    Title = "No Spread",
    Value = false,
    Callback = function(v)
        noSpreadActive = v
        LocalPlayer:SetAttribute("NoSpread", v)
    end,
})

-- ============================================
-- PESTAÑA MOVIMIENTO
-- ============================================
MovementTab:Section({
    Title = "Velocidad",
    Desc = "Control de movimiento del personaje",
})

local SpeedGroup = MovementTab:Group()

SpeedGroup:Toggle({
    Title = "Speed Hack",
    Value = false,
    Callback = function(v)
        speedEnabled = v
        if v then
            StartSpeedLoop()
        else
            threads.Speed = nil
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end,
})

SpeedGroup:Slider({
    Title = "Velocidad",
    Step = 1,
    Value = { Min = 16, Max = 250, Default = 50 },
    Callback = function(v)
        speedAmount = v
    end,
})

MovementTab:Space({ Columns = 1 })

MovementTab:Section({
    Title = "Movimiento Avanzado",
    Desc = "Funciones adicionales de movimiento",
})

local AdvancedMoveGroup = MovementTab:Group()

AdvancedMoveGroup:Toggle({
    Title = "Infinite Jump",
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

AdvancedMoveGroup:Toggle({
    Title = "Infinita Estamina",
    Value = false,
    Callback = function(v)
        infiniteStamina = v
        if v then
            if threads.Stamina then return end
            threads.Stamina = task.spawn(InfiniteStaminaLoop)
        else
            threads.Stamina = nil
        end
    end,
})

AdvancedMoveGroup:Toggle({
    Title = "No Clip",
    Value = false,
    Callback = function(v)
        noClipActive = v
        SetNoClip(v)
    end,
})

-- ============================================
-- PESTAÑA VISUAL (ESP)
-- ============================================
VisualTab:Section({
    Title = "ESP",
    Desc = "Visualización de jugadores",
})

local EspGroup = VisualTab:Group()

EspGroup:Toggle({
    Title = "Nombre ESP",
    Value = false,
    Callback = function(v)
        nameEspActive = v
    end,
})

EspGroup:Toggle({
    Title = "Vida ESP",
    Value = false,
    Callback = function(v)
        healthEspActive = v
    end,
})

EspGroup:Toggle({
    Title = "Distancia ESP",
    Value = false,
    Callback = function(v)
        distanceEspActive = v
    end,
})

EspGroup:Toggle({
    Title = "Arma ESP (con imagen)",
    Value = false,
    Callback = function(v)
        inventoryEspActive = v
    end,
})

-- ============================================
-- PESTAÑA ITEMS (MAGNETO)
-- ============================================
ItemsTab:Section({
    Title = "Magneto",
    Desc = "Atracción automática de items",
})

local MagnetoGroup = ItemsTab:Group()

MagnetoGroup:Toggle({
    Title = "Magneto Activado",
    Value = false,
    Callback = function(v)
        magnetoActive = v
        if v then
            if threads.Magneto then return end
            threads.Magneto = task.spawn(MagnetoLoop)
        else
            magnetoActive = false
            threads.Magneto = nil
            MagnetoItems = {}
        end
    end,
})

MagnetoGroup:Slider({
    Title = "Radio",
    Step = 1,
    Value = { Min = 10, Max = 100, Default = 50 },
    Callback = function(v)
        magnetoRadius = v
    end,
})

MagnetoGroup:Slider({
    Title = "Velocidad",
    Step = 1,
    Value = { Min = 20, Max = 150, Default = 60 },
    Callback = function(v)
        magnetoSpeed = v
    end,
})

-- ============================================
-- PESTAÑA CONFIG
-- ============================================
SettingsTab:Section({
    Title = "Información",
    Desc = "Datos de la cuenta",
})

local InfoGroup = SettingsTab:Group()

local cashLabel = InfoGroup:Label({
    Title = "💵 Cash: Cargando...",
})

local bankLabel = InfoGroup:Label({
    Title = "🏦 Bank: Cargando...",
})

task.spawn(function()
    while true do
        local success, cash, bank = pcall(GetRealMoney)
        if success then
            pcall(function()
                cashLabel:Set("💵 Cash: $" .. tostring(cash))
                bankLabel:Set("🏦 Bank: $" .. tostring(bank))
            end)
        end
        task.wait(1)
    end
end)

SettingsTab:Space({ Columns = 1 })

SettingsTab:Section({
    Title = "UI",
    Desc = "Configuración de interfaz",
})

local UiGroup = SettingsTab:Group()

UiGroup:Button({
    Title = "Destruir UI",
    Callback = function()
        Window:Destroy()
    end,
})

-- ============================================
-- INICIALIZACIÓN
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
            if esp.ItemContainer then esp.ItemContainer:Destroy() end
        end)
        ESPs[player] = nil
    end
end)

-- Conexiones ESP
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

-- Notificación de carga
pcall(function()
    WindUI:Notify({
        Title = "Water Hub",
        Content = "Script cargado correctamente",
        Duration = 3,
    })
end)

print("✅ Water Hub | BlockSpin - Cargado correctamente")
