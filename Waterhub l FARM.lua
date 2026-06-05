--[[
    WATER HUB | BLOCKSPIN - VERSIÓN FINAL CON INVENTARIO VISUAL
    Silent Aim + ESP con Slots Circulares + Movimiento + Armas
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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
    warn("[WATER HUB] Error: No se pudo cargar WindUI")
    return
end

-- ============================================
-- SISTEMA DE CONFIGURACIÓN
-- ============================================
local ConfigFile = "WaterHub_BlockSpin_v5.json"

local Features = {
    SilentAim = false,
    AimLock = false,
    Prediction = 0.165,
    AimLockKeybind = Enum.KeyCode.E,
    ESPBoxes = false,
    ESPNames = false,
    ESPDistance = false,
    ESPChams = false,
    ESPInventory = false,
    ESPColor = Color3.fromRGB(0, 150, 255),
    ESPThickness = 1,
    WalkSpeed = false,
    SpeedValue = 50,
    SuperJump = false,
    JumpPower = 100,
    InfiniteStamina = false,
    AntiKill = false,
    AntiKillHealth = 20,
    EnableGunMods = false,
    FireRate = 600,
    Recoil = 0,
    ReloadTime = 0.1,
    FPSBoost = false,
    ThemeColor = Color3.fromHex("#0096FF")
}

local function LoadConfig()
    if isfile and isfile(ConfigFile) then
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
LoadConfig()

local function SaveConfig(silent)
    local dataToSave = {}
    for key, _ in pairs(Features) do
        dataToSave[key] = Features[key]
    end
    pcall(function()
        if writefile then
            writefile(ConfigFile, HttpService:JSONEncode(dataToSave))
        end
    end)
end

local function Notify(title, message)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = message,
            Duration = 2.5
        })
    end)
end

-- ============================================
-- DATOS DE INVENTARIO (TUS IDs Y RAREZAS)
-- ============================================
local RAREZA_COLORES = {
    ["rojo"]    = Color3.fromRGB(255, 30, 30),
    ["naranja"] = Color3.fromRGB(255, 120, 0),
    ["morada"]  = Color3.fromRGB(160, 32, 240),
    ["azul"]    = Color3.fromRGB(30, 144, 255),
    ["verde"]   = Color3.fromRGB(50, 205, 50),
    ["gris"]    = Color3.fromRGB(100, 100, 100)
}

local DEFINICION_RAREZA = {
    ["Ak 47"] = "naranja", ["Anaconda"] = "rojo", ["C9"] = "verde", ["Double barril"] = "morada",
    ["Draco"] = "morada", ["Firework"] = "morada", ["G3"] = "verde", ["Glock"] = "azul",
    ["M16"] = "naranja", ["M241"] = "rojo", ["MP5"] = "naranja", ["P226"] = "azul",
    ["RPG"] = "naranja", ["Remington"] = "naranja", ["Sawnoff"] = "naranja", ["Skorpion"] = "morada",
    ["Uzi"] = "azul", ["Baseball Bat"] = "verde", ["Tactical Axe"] = "naranja", 
    ["Tactical Knife"] = "naranja", ["Tactical Shovel"] = "naranja", ["Crowbar"] = "azul", 
    ["Switchblade"] = "azul", ["Granada"] = "morada", ["Molotov"] = "morada", ["Mop"] = "gris", 
    ["First Aid Kit"] = "morada", ["Energy Shot"] = "morada", ["Bandage"] = "gris", 
    ["FishingRodRegular"] = "gris", ["FishingRodPro"] = "gris", ["FishingRodUltimate"] = "gris"
}

local listaIconos = {
    ["Baseball Bat"] = "rbxassetid://70390201507839", ["Tactical Axe"] = "rbxassetid://128521472487967",
    ["Tactical Knife"] = "rbxassetid://138188463918911", ["Tactical Shovel"] = "rbxassetid://92343057781870",
    ["Crowbar"] = "rbxassetid://90424115101219", ["Switchblade"] = "rbxassetid://93060515735865",
    ["Granada"] = "rbxassetid://91702588622611", ["Molotov"] = "rbxassetid://109158861273815",
    ["FishingRodRegular"] = "rbxassetid://120270558984957", ["FishingRodPro"] = "rbxassetid://106570831786716",
    ["FishingRodUltimate"] = "rbxassetid://75257833138570", ["Mop"] = "rbxassetid://71489031926594",
    ["Bandage"] = "rbxassetid://135140124942347", ["First Aid Kit"] = "rbxassetid://128659636079830",
    ["Energy Shot"] = "rbxassetid://82182210950828", ["Ak 47"] = "rbxassetid://124555430577178",
    ["Anaconda"] = "rbxassetid://132781174839844", ["C9"] = "rbxassetid://79659079988022",
    ["Double barril"] = "rbxassetid://83625765638039", ["Draco"] = "rbxassetid://120937616266903",
    ["Firework"] = "rbxassetid://88284317820274", ["G3"] = "rbxassetid://133411291398002",
    ["Glock"] = "rbxassetid://97846154366870", ["M16"] = "rbxassetid://74321352408872",
    ["M241"] = "rbxassetid://80044343904275", ["MP5"] = "rbxassetid://80501079489777",
    ["P226"] = "rbxassetid://92521100297776", ["RPG"] = "rbxassetid://138426000142807",
    ["Remington"] = "rbxassetid://101271375930409", ["Sawnoff"] = "rbxassetid://90588305892707",
    ["Skorpion"] = "rbxassetid://105318377951686", ["Uzi"] = "rbxassetid://109290695652338"
}

-- ============================================
-- FUNCIÓN PARA OBTENER ARMA EQUIPADA
-- ============================================
local function GetEquippedItem(character)
    -- Buscar herramienta estándar
    local tool = character:FindFirstChildOfClass("Tool")
    if tool and listaIconos[tool.Name] then
        return tool.Name
    end
    
    -- Buscar por nombre de objeto en el personaje
    for itemName, _ in pairs(listaIconos) do
        if character:FindFirstChild(itemName) then
            return itemName
        end
    end
    
    return nil
end

-- ============================================
-- SILENT AIM SYSTEM
-- ============================================
local SilentAim = {
    Enabled = false,
    Selected = nil,
    SelectedPart = nil
}

function SilentAim:GetClosestTarget()
    local closestTarget = nil
    local closestDistance = math.huge
    local camera = Workspace.CurrentCamera
    if not camera then return nil end
    
    local players = Players:GetPlayers()
    for _, player in ipairs(players) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                local head = character:FindFirstChild("Head")
                
                if humanoid and humanoid.Health > 0 and head then
                    local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
                    
                    if onScreen then
                        local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        
                        if distance < closestDistance then
                            closestDistance = distance
                            closestTarget = {
                                Player = player,
                                Character = character,
                                Head = head
                            }
                        end
                    end
                end
            end
        end
    end
    
    return closestTarget
end

function SilentAim:IsValidTarget()
    if not Features.SilentAim then return false end
    
    local target = self:GetClosestTarget()
    if not target then return false end
    
    local character = target.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    
    if not humanoid or humanoid.Health <= 0 then return false end
    
    self.Selected = target.Player
    self.SelectedPart = target.Head
    return true
end

-- Hook del Silent Aim
local __index
__index = hookmetamethod(game, "__index", function(t, k)
    if t:IsA("Mouse") and (k == "Hit" or k == "Target") and SilentAim:IsValidTarget() then
        local selectedPart = SilentAim.SelectedPart
        if selectedPart then
            local predictedPosition = selectedPart.CFrame + (selectedPart.Velocity * Features.Prediction)
            if k == "Hit" then
                return predictedPosition
            else
                return selectedPart
            end
        end
    end
    return __index(t, k)
end)

-- Aim Lock
RunService:BindToRenderStep("WaterHub_AimLock", 0, function()
    if Features.AimLock and SilentAim:IsValidTarget() then
        if UserInputService:IsKeyDown(Features.AimLockKeybind) then
            local selectedPart = SilentAim.SelectedPart
            if selectedPart then
                local camera = Workspace.CurrentCamera
                local predictedPosition = selectedPart.CFrame + (selectedPart.Velocity * Features.Prediction)
                camera.CFrame = CFrame.lookAt(camera.CFrame.Position, predictedPosition.Position)
            end
        end
    end
end)

-- ============================================
-- ESP SYSTEM CON SLOTS CIRCULARES (TU SISTEMA)
-- ============================================
local ESPObjects = {}

local function CreateESP(player, rootPart)
    if not rootPart or not rootPart.Parent then return end
    
    local character = rootPart.Parent
    
    -- ============================================
    -- BILLBOARD GUI CON SLOT CIRCULAR (TU DISEÑO)
    -- ============================================
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "WaterHub_InvESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 80, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.Adornee = rootPart
    
    -- Slot circular (Frame redondo)
    local slotFrame = Instance.new("Frame")
    slotFrame.Name = "SlotCircular"
    slotFrame.Size = UDim2.new(1, 0, 1, 0)
    slotFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    slotFrame.BackgroundTransparency = 0.2
    slotFrame.Parent = billboard
    
    -- Esquina redonda para hacerlo circular
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = slotFrame
    
    -- Borde de color dinámico
    local stroke = Instance.new("UIStroke")
    stroke.Name = "RarityStroke"
    stroke.Thickness = 3
    stroke.Color = RAREZA_COLORES["gris"]
    stroke.Parent = slotFrame
    
    -- Imagen del arma
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "ItemImage"
    imageLabel.Size = UDim2.new(0, 50, 0, 50)
    imageLabel.Position = UDim2.new(0.5, -25, 0.5, -25)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = ""
    imageLabel.Parent = slotFrame
    
    -- ============================================
    -- DRAWINGS PARA BOX, NAME Y DISTANCE
    -- ============================================
    local Box = Drawing.new("Square")
    Box.Thickness = Features.ESPThickness
    Box.Color = Features.ESPColor
    Box.Transparency = 1
    Box.Filled = false
    Box.Visible = false
    
    local Name = Drawing.new("Text")
    Name.Text = player.Name
    Name.Color = Color3.fromRGB(255, 255, 255)
    Name.Transparency = 1
    Name.Outline = true
    Name.Center = true
    Name.Visible = false
    Name.Size = 13
    Name.Font = 2
    
    local Distance = Drawing.new("Text")
    Distance.Text = "0m"
    Distance.Color = Color3.fromRGB(200, 200, 200)
    Distance.Transparency = 1
    Distance.Outline = true
    Distance.Center = true
    Distance.Visible = false
    Distance.Size = 12
    Distance.Font = 2
    
    -- ============================================
    -- ACTUALIZACIÓN EN TIEMPO REAL
    -- ============================================
    local updateConnection
    updateConnection = RunService.RenderStepped:Connect(function()
        local camera = Workspace.CurrentCamera
        if not camera or not rootPart.Parent then
            updateConnection:Disconnect()
            Box:Remove()
            Name:Remove()
            Distance:Remove()
            billboard:Destroy()
            return
        end
        
        local rootPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
        local distance = (camera.CFrame.Position - rootPart.Position).Magnitude
        local humanoid = character:FindFirstChild("Humanoid")
        
        if onScreen and humanoid and humanoid.Health > 0 then
            local size = Vector2.new(2000 / rootPos.Z, 3000 / rootPos.Z)
            
            -- Actualizar Box ESP
            if Features.ESPBoxes then
                Box.Size = size
                Box.Position = Vector2.new(rootPos.X - size.X/2, rootPos.Y - size.Y/2)
                Box.Color = Features.ESPColor
                Box.Thickness = Features.ESPThickness
                Box.Visible = true
            else
                Box.Visible = false
            end
            
            -- Actualizar Name ESP
            if Features.ESPNames then
                Name.Position = Vector2.new(rootPos.X, rootPos.Y - (size.Y/2) - 20)
                Name.Visible = true
            else
                Name.Visible = false
            end
            
            -- Actualizar Distance ESP
            if Features.ESPDistance then
                Distance.Text = tostring(math.floor(distance)) .. "m"
                Distance.Position = Vector2.new(rootPos.X, rootPos.Y + (size.Y/2) + 5)
                Distance.Visible = true
            else
                Distance.Visible = false
            end
            
            -- ============================================
            -- ACTUALIZAR SLOT CIRCULAR CON INVENTARIO
            -- ============================================
            if Features.ESPInventory then
                local equippedItem = GetEquippedItem(character)
                
                if equippedItem and listaIconos[equippedItem] then
                    -- Actualizar imagen
                    imageLabel.Image = listaIconos[equippedItem]
                    
                    -- Actualizar color del borde según rareza
                    local rareza = DEFINICION_RAREZA[equippedItem] or "gris"
                    stroke.Color = RAREZA_COLORES[rareza]
                else
                    -- Sin arma: slot vacío
                    imageLabel.Image = ""
                    stroke.Color = RAREZA_COLORES["gris"]
                end
                
                billboard.Enabled = true
            else
                billboard.Enabled = false
            end
            
            -- Chams
            if Features.ESPChams then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and not part:FindFirstChild("ESP_Highlight") then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "ESP_Highlight"
                        highlight.FillColor = Features.ESPColor
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.FillTransparency = 0.5
                        highlight.Parent = part
                    end
                end
            end
        else
            Box.Visible = false
            Name.Visible = false
            Distance.Visible = false
            billboard.Enabled = false
        end
    end)
    
    -- ============================================
    -- LIMPIEZA
    -- ============================================
    local function Cleanup()
        updateConnection:Disconnect()
        Box:Remove()
        Name:Remove()
        Distance:Remove()
        billboard:Destroy()
        
        -- Limpiar highlights
        for _, part in ipairs(character:GetDescendants()) do
            local highlight = part:FindFirstChild("ESP_Highlight")
            if highlight then
                highlight:Destroy()
            end
        end
    end
    
    rootPart.AncestryChanged:Connect(function(_, parent)
        if not parent then
            Cleanup()
        end
    end)
    
    table.insert(ESPObjects, {
        Player = player,
        Cleanup = Cleanup
    })
end

-- ============================================
-- MANEJO DE JUGADORES
-- ============================================
local function OnCharacterAdded(character)
    local player = Players:GetPlayerFromCharacter(character)
    if not player or player == LocalPlayer then return end
    
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if rootPart then
        CreateESP(player, rootPart)
    else
        local connection
        connection = character.ChildAdded:Connect(function(child)
            if child.Name == "HumanoidRootPart" then
                connection:Disconnect()
                CreateESP(player, child)
            end
        end)
    end
end

local function OnPlayerAdded(player)
    if player == LocalPlayer then return end
    
    player.CharacterAdded:Connect(OnCharacterAdded)
    
    if player.Character then
        task.spawn(OnCharacterAdded, player.Character)
    end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    OnPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
    for i, espObj in ipairs(ESPObjects) do
        if espObj.Player == player then
            pcall(espObj.Cleanup)
            table.remove(ESPObjects, i)
            break
        end
    end
end)

-- ============================================
-- SISTEMA DE MOVIMIENTO
-- ============================================
local MovementCoroutines = {}

local function StartWalkSpeed()
    if MovementCoroutines.WalkSpeed then
        task.cancel(MovementCoroutines.WalkSpeed)
    end
    
    MovementCoroutines.WalkSpeed = task.spawn(function()
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
        
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = 16
            end
        end
    end)
end

local function StartSuperJump()
    if MovementCoroutines.SuperJump then
        task.cancel(MovementCoroutines.SuperJump)
    end
    
    MovementCoroutines.SuperJump = task.spawn(function()
        while Features.SuperJump do
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum.JumpPower = Features.JumpPower
                    if hum.FloorMaterial ~= Enum.Material.Air then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end
            task.wait(0.3)
        end
        
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.JumpPower = 50
            end
        end
    end)
end

local function StartInfiniteStamina()
    if MovementCoroutines.Stamina then
        task.cancel(MovementCoroutines.Stamina)
    end
    
    MovementCoroutines.Stamina = task.spawn(function()
        while Features.InfiniteStamina do
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    pcall(function()
                        hum:SetAttribute("Stamina", 125)
                    end)
                end
            end
            task.wait(0.2)
        end
    end)
end

-- Anti Kill
local AntiKillConnection

local function StartAntiKill()
    if AntiKillConnection then
        AntiKillConnection:Disconnect()
    end
    
    AntiKillConnection = RunService.Heartbeat:Connect(function()
        if not Features.AntiKill then return end
        
        local char = LocalPlayer.Character
        if not char then return end
        
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if hum and hrp then
            local healthPercent = (hum.Health / hum.MaxHealth) * 100
            if healthPercent <= Features.AntiKillHealth then
                local targetPos = Vector3.new(hrp.Position.X, -50, hrp.Position.Z)
                TweenService:Create(hrp, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    CFrame = CFrame.new(targetPos)
                }):Play()
            end
        end
    end)
end

local function StopAntiKill()
    if AntiKillConnection then
        AntiKillConnection:Disconnect()
        AntiKillConnection = nil
    end
end

-- ============================================
-- SISTEMA DE ARMAS
-- ============================================
local function ApplyGunMods()
    if not Features.EnableGunMods then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local config = tool:FindFirstChild("Configuration")
            if config then
                pcall(function()
                    local fireRate = config:FindFirstChild("FireRate")
                    if fireRate then fireRate.Value = Features.FireRate end
                    
                    local recoil = config:FindFirstChild("Recoil")
                    if recoil then recoil.Value = Features.Recoil end
                    
                    local reload = config:FindFirstChild("ReloadTime")
                    if reload then reload.Value = Features.ReloadTime end
                end)
            end
        end
    end
end

-- ============================================
-- UTILIDADES
-- ============================================
local function ServerHop()
    local placeId = game.PlaceId
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
    
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and result then
        local data = HttpService:JSONDecode(result)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(placeId, server.id, LocalPlayer)
                    return
                end
            end
        end
    end
    
    Notify("Error", "No se encontraron servidores disponibles")
end

local function FPSBoost()
    Lighting.GlobalShadows = false
    Lighting.Technology = Enum.Technology.Compatibility
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") then
            pcall(function()
                obj.Enabled = false
            end)
        end
    end
end

-- ============================================
-- INTERFAZ DE USUARIO (WINDUI)
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | BlockSpin",
    Author = "Professional",
    Icon = "droplet",
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.F,
    OpenButton = {
        Title = "Open",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        Color = ColorSequence.new(Features.ThemeColor, Features.ThemeColor),
    },
})

-- Pestaña COMBAT
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "crosshair" })
CombatTab:Section({ Title = "Silent Aim", Desc = "Asistencia de disparo silenciosa" })

CombatTab:Toggle({
    Title = "Silent Aim",
    Value = Features.SilentAim,
    Callback = function(v)
        Features.SilentAim = v
        SaveConfig(true)
    end,
})

CombatTab:Toggle({
    Title = "Aim Lock (Hold E)",
    Value = Features.AimLock,
    Callback = function(v)
        Features.AimLock = v
        SaveConfig(true)
    end,
})

CombatTab:Slider({
    Title = "Prediction",
    Step = 0.001,
    Value = { Min = 0, Max = 0.5, Default = Features.Prediction },
    Callback = function(v)
        Features.Prediction = v
        SaveConfig(true)
    end,
})

CombatTab:Section({ Title = "Defensa", Desc = "Protección del jugador" })

CombatTab:Toggle({
    Title = "Anti Kill",
    Value = Features.AntiKill,
    Callback = function(v)
        Features.AntiKill = v
        if v then
            StartAntiKill()
        else
            StopAntiKill()
        end
        SaveConfig(true)
    end,
})

CombatTab:Slider({
    Title = "Anti Kill Health %",
    Step = 5,
    Value = { Min = 5, Max = 50, Default = Features.AntiKillHealth },
    Callback = function(v)
        Features.AntiKillHealth = v
        SaveConfig(true)
    end,
})

-- Pestaña ESP
local ESPTab = Window:Tab({ Title = "ESP", Icon = "eye" })
ESPTab:Section({ Title = "Player ESP", Desc = "Visualización con slots de inventario" })

ESPTab:Toggle({
    Title = "Cajas (Boxes)",
    Value = Features.ESPBoxes,
    Callback = function(v)
        Features.ESPBoxes = v
        SaveConfig(true)
    end,
})

ESPTab:Toggle({
    Title = "Nombres",
    Value = Features.ESPNames,
    Callback = function(v)
        Features.ESPNames = v
        SaveConfig(true)
    end,
})

ESPTab:Toggle({
    Title = "Distancia",
    Value = Features.ESPDistance,
    Callback = function(v)
        Features.ESPDistance = v
        SaveConfig(true)
    end,
})

ESPTab:Toggle({
    Title = "Resaltado (Chams)",
    Value = Features.ESPChams,
    Callback = function(v)
        Features.ESPChams = v
        SaveConfig(true)
    end,
})

ESPTab:Toggle({
    Title = "Inventario Equipado",
    Value = Features.ESPInventory,
    Callback = function(v)
        Features.ESPInventory = v
        SaveConfig(true)
    end,
})

ESPTab:Slider({
    Title = "Grosor del ESP",
    Step = 0.5,
    Value = { Min = 0.5, Max = 3, Default = Features.ESPThickness },
    Callback = function(v)
        Features.ESPThickness = v
        SaveConfig(true)
    end,
})

-- Pestaña MOVEMENT
local MoveTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })
MoveTab:Section({ Title = "Velocidad" })

MoveTab:Toggle({
    Title = "Walk Speed",
    Value = Features.WalkSpeed,
    Callback = function(v)
        Features.WalkSpeed = v
        if v then
            StartWalkSpeed()
        end
        SaveConfig(true)
    end,
})

MoveTab:Slider({
    Title = "Velocidad",
    Step = 5,
    Value = { Min = 16, Max = 200, Default = Features.SpeedValue },
    Callback = function(v)
        Features.SpeedValue = v
        SaveConfig(true)
    end,
})

MoveTab:Section({ Title = "Saltos y Stamina" })

MoveTab:Toggle({
    Title = "Super Jump",
    Value = Features.SuperJump,
    Callback = function(v)
        Features.SuperJump = v
        if v then
            StartSuperJump()
        end
        SaveConfig(true)
    end,
})

MoveTab:Slider({
    Title = "Fuerza de Salto",
    Step = 10,
    Value = { Min = 50, Max = 200, Default = Features.JumpPower },
    Callback = function(v)
        Features.JumpPower = v
        SaveConfig(true)
    end,
})

MoveTab:Toggle({
    Title = "Estamina Infinita",
    Value = Features.InfiniteStamina,
    Callback = function(v)
        Features.InfiniteStamina = v
        if v then
            StartInfiniteStamina()
        end
        SaveConfig(true)
    end,
})

-- Pestaña WEAPON
local WeaponTab = Window:Tab({ Title = "WEAPON", Icon = "target" })
WeaponTab:Section({ Title = "Modificadores de Armas" })

WeaponTab:Toggle({
    Title = "Activar Gun Mods",
    Value = Features.EnableGunMods,
    Callback = function(v)
        Features.EnableGunMods = v
        if v then
            ApplyGunMods()
        end
        SaveConfig(true)
    end,
})

WeaponTab:Slider({
    Title = "Cadencia (Fire Rate)",
    Step = 50,
    Value = { Min = 50, Max = 2000, Default = Features.FireRate },
    Callback = function(v)
        Features.FireRate = v
        if Features.EnableGunMods then
            ApplyGunMods()
        end
        SaveConfig(true)
    end,
})

WeaponTab:Slider({
    Title = "Retroceso (Recoil)",
    Step = 0.1,
    Value = { Min = 0, Max = 3, Default = Features.Recoil },
    Callback = function(v)
        Features.Recoil = v
        if Features.EnableGunMods then
            ApplyGunMods()
        end
        SaveConfig(true)
    end,
})

WeaponTab:Slider({
    Title = "Tiempo de Recarga",
    Step = 0.1,
    Value = { Min = 0.1, Max = 5, Default = Features.ReloadTime },
    Callback = function(v)
        Features.ReloadTime = v
        if Features.EnableGunMods then
            ApplyGunMods()
        end
        SaveConfig(true)
    end,
})

-- Pestaña MISC
local MiscTab = Window:Tab({ Title = "MISC", Icon = "settings" })

MiscTab:Button({
    Title = "Cambiar de Servidor",
    Callback = ServerHop
})

MiscTab:Toggle({
    Title = "Optimizar FPS",
    Value = Features.FPSBoost,
    Callback = function(v)
        Features.FPSBoost = v
        if v then
            FPSBoost()
        end
        SaveConfig(true)
    end,
})

MiscTab:Button({
    Title = "Guardar Configuración",
    Callback = function()
        SaveConfig(false)
        Notify("Configuración", "Guardada correctamente")
    end
})

-- Seleccionar primera pestaña
CombatTab:Select()

print("[WATER HUB] Cargado exitosamente")
print("[WATER HUB] Slots circulares con imágenes - ACTIVO")