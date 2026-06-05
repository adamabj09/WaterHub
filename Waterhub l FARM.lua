--[[
    WATER HUB | BLOCKSPIN - VERSIÓN FINAL FUNCIONAL
    Silent Aim + ESP (Slots Circulares) + Movimiento + Armas
    Vídeo de fondo: 5608321996 (silenciado, ocupa toda la ventana)
    Detección de armas mejorada para BlockSpin
    Todo desactivado por defecto
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
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
-- CONFIGURACIÓN (TODO DESACTIVADO)
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

local function SaveConfig()
    local data = {}
    for k, v in pairs(Features) do data[k] = v end
    pcall(function()
        if writefile then writefile(ConfigFile, HttpService:JSONEncode(data)) end
    end)
end

local function Notify(title, msg)
    pcall(function() WindUI:Notify({Title = title, Content = msg, Duration = 2.5}) end)
end

-- ============================================
-- INVENTARIO (DATOS)
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

-- Detección mejorada para BlockSpin (busca en todo el personaje, incluso dentro de Backpack, etc.)
local function GetEquippedItem(character)
    -- 1. Buscar Tool clásico
    local tool = character:FindFirstChildOfClass("Tool")
    if tool and listaIconos[tool.Name] then
        return tool.Name
    end
    
    -- 2. Buscar en cualquier Model que contenga "Handle" y esté en la lista
    for _, child in ipairs(character:GetDescendants()) do
        if child:IsA("Model") and listaIconos[child.Name] then
            if child:FindFirstChild("Handle", true) then
                return child.Name
            end
        end
    end
    
    -- 3. Si aún no, buscar por nombre exacto en cualquier parte del personaje
    for itemName, _ in pairs(listaIconos) do
        if character:FindFirstChild(itemName, true) then
            return itemName
        end
    end
    
    return nil
end

-- ============================================
-- SILENT AIM
-- ============================================
local SilentAim = {SelectedPart = nil}

function SilentAim:GetClosestTarget()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local best = nil
    local bestDist = math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                local head = char:FindFirstChild("Head")
                if hum and hum.Health > 0 and head then
                    local pos, onScreen = cam:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < bestDist then
                            bestDist = dist
                            best = head
                        end
                    end
                end
            end
        end
    end
    return best
end

function SilentAim:IsValidTarget()
    if not Features.SilentAim then return false end
    local target = self:GetClosestTarget()
    if not target then return false end
    self.SelectedPart = target
    return true
end

local __index
__index = hookmetamethod(game, "__index", function(t, k)
    if t:IsA("Mouse") and (k == "Hit" or k == "Target") and SilentAim:IsValidTarget() then
        local part = SilentAim.SelectedPart
        if part then
            local predicted = part.CFrame + (part.Velocity * Features.Prediction)
            return (k == "Hit" and predicted or part)
        end
    end
    return __index(t, k)
end)

RunService:BindToRenderStep("WaterHub_AimLock", 0, function()
    if Features.AimLock and SilentAim:IsValidTarget() and UserInputService:IsKeyDown(Features.AimLockKeybind) then
        local part = SilentAim.SelectedPart
        if part then
            local cam = Workspace.CurrentCamera
            local predicted = part.CFrame + (part.Velocity * Features.Prediction)
            cam.CFrame = CFrame.lookAt(cam.CFrame.Position, predicted.Position)
        end
    end
end)

-- ============================================
-- ESP CON SLOTS CIRCULARES (CORREGIDO)
-- ============================================
local ESPObjects = {}

local function CreateESP(player, rootPart)
    if not rootPart or not rootPart.Parent then return end
    local character = rootPart.Parent
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "WaterHub_Inv"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 80, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.Adornee = rootPart
    billboard.Parent = gethui()
    billboard.Enabled = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0.2
    frame.Parent = billboard
    
    Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)
    
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 3
    stroke.Color = RAREZA_COLORES["gris"]
    stroke.Parent = frame
    
    local img = Instance.new("ImageLabel")
    img.Size = UDim2.new(0, 50, 0, 50)
    img.Position = UDim2.new(0.5, -25, 0.5, -25)
    img.BackgroundTransparency = 1
    img.Image = ""
    img.Parent = frame
    
    -- Dibujos ESP clásicos
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
    
    local conn
    conn = RunService.RenderStepped:Connect(function()
        local cam = Workspace.CurrentCamera
        if not cam or not rootPart.Parent then
            conn:Disconnect()
            Box:Remove()
            Name:Remove()
            Distance:Remove()
            billboard:Destroy()
            return
        end
        
        local rootPos, onScreen = cam:WorldToViewportPoint(rootPart.Position)
        local dist = (cam.CFrame.Position - rootPart.Position).Magnitude
        local hum = character:FindFirstChild("Humanoid")
        
        if onScreen and hum and hum.Health > 0 then
            local size = Vector2.new(2000 / rootPos.Z, 3000 / rootPos.Z)
            
            if Features.ESPBoxes then
                Box.Size = size
                Box.Position = Vector2.new(rootPos.X - size.X/2, rootPos.Y - size.Y/2)
                Box.Color = Features.ESPColor
                Box.Thickness = Features.ESPThickness
                Box.Visible = true
            else
                Box.Visible = false
            end
            
            if Features.ESPNames then
                Name.Position = Vector2.new(rootPos.X, rootPos.Y - size.Y/2 - 20)
                Name.Visible = true
            else
                Name.Visible = false
            end
            
            if Features.ESPDistance then
                Distance.Text = tostring(math.floor(dist)) .. "m"
                Distance.Position = Vector2.new(rootPos.X, rootPos.Y + size.Y/2 + 5)
                Distance.Visible = true
            else
                Distance.Visible = false
            end
            
            if Features.ESPInventory then
                local item = GetEquippedItem(character)
                if item and listaIconos[item] then
                    img.Image = listaIconos[item]
                    local rareza = DEFINICION_RAREZA[item] or "gris"
                    stroke.Color = RAREZA_COLORES[rareza]
                else
                    img.Image = ""
                    stroke.Color = RAREZA_COLORES["gris"]
                end
                billboard.Enabled = true
            else
                billboard.Enabled = false
            end
            
            if Features.ESPChams then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and not part:FindFirstChild("ESP_Highlight") then
                        local hl = Instance.new("Highlight")
                        hl.Name = "ESP_Highlight"
                        hl.FillColor = Features.ESPColor
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.Parent = part
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
    
    local function Cleanup()
        conn:Disconnect()
        Box:Remove()
        Name:Remove()
        Distance:Remove()
        billboard:Destroy()
        for _, part in ipairs(character:GetDescendants()) do
            local hl = part:FindFirstChild("ESP_Highlight")
            if hl then hl:Destroy() end
        end
    end
    
    rootPart.AncestryChanged:Connect(function(_, parent)
        if not parent then Cleanup() end
    end)
    
    table.insert(ESPObjects, {Player = player, Cleanup = Cleanup})
end

local function OnCharacterAdded(character)
    local player = Players:GetPlayerFromCharacter(character)
    if not player or player == LocalPlayer then return end
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    if rootPart then
        CreateESP(player, rootPart)
    else
        local conn
        conn = character.ChildAdded:Connect(function(child)
            if child.Name == "HumanoidRootPart" then
                conn:Disconnect()
                CreateESP(player, child)
            end
        end)
    end
end

local function OnPlayerAdded(player)
    if player == LocalPlayer then return end
    player.CharacterAdded:Connect(OnCharacterAdded)
    if player.Character then task.spawn(OnCharacterAdded, player.Character) end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
    OnPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
    for i, obj in ipairs(ESPObjects) do
        if obj.Player == player then
            pcall(obj.Cleanup)
            table.remove(ESPObjects, i)
            break
        end
    end
end)

-- ============================================
-- MOVIMIENTO
-- ============================================
local MovementCoroutines = {}

local function StartWalkSpeed()
    if MovementCoroutines.WalkSpeed then task.cancel(MovementCoroutines.WalkSpeed) end
    MovementCoroutines.WalkSpeed = task.spawn(function()
        while Features.WalkSpeed do
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = Features.SpeedValue end
            end
            task.wait(0.1)
        end
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end)
end

local function StartSuperJump()
    if MovementCoroutines.SuperJump then task.cancel(MovementCoroutines.SuperJump) end
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
            if hum then hum.JumpPower = 50 end
        end
    end)
end

local function StartInfiniteStamina()
    if MovementCoroutines.Stamina then task.cancel(MovementCoroutines.Stamina) end
    MovementCoroutines.Stamina = task.spawn(function()
        while Features.InfiniteStamina do
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then pcall(function() hum:SetAttribute("Stamina", 125) end) end
            end
            task.wait(0.2)
        end
    end)
end

local AntiKillConnection

local function StartAntiKill()
    if AntiKillConnection then AntiKillConnection:Disconnect() end
    AntiKillConnection = RunService.Heartbeat:Connect(function()
        if not Features.AntiKill then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hum and hrp then
            if (hum.Health / hum.MaxHealth) * 100 <= Features.AntiKillHealth then
                TweenService:Create(hrp, TweenInfo.new(0.3), {
                    CFrame = CFrame.new(Vector3.new(hrp.Position.X, -50, hrp.Position.Z))
                }):Play()
            end
        end
    end)
end

local function StopAntiKill()
    if AntiKillConnection then AntiKillConnection:Disconnect(); AntiKillConnection = nil end
end

-- ============================================
-- ARMAS
-- ============================================
local function ApplyGunMods()
    if not Features.EnableGunMods then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local cfg = tool:FindFirstChild("Configuration")
            if cfg then
                pcall(function()
                    local fr = cfg:FindFirstChild("FireRate")
                    if fr then fr.Value = Features.FireRate end
                    local rec = cfg:FindFirstChild("Recoil")
                    if rec then rec.Value = Features.Recoil end
                    local rel = cfg:FindFirstChild("ReloadTime")
                    if rel then rel.Value = Features.ReloadTime end
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
    local success, result = pcall(function() return game:HttpGet(url) end)
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
    Notify("Error", "No se encontraron servidores")
end

local function FPSBoost()
    Lighting.GlobalShadows = false
    Lighting.Technology = Enum.Technology.Compatibility
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") then
            pcall(function() obj.Enabled = false end)
        end
    end
end

-- ============================================
-- INTERFAZ WINDUI + VÍDEO DE FONDO CORREGIDO
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

-- Insertar vídeo de fondo silencioso que ocupe toda la ventana
task.spawn(function()
    task.wait(0.5)
    local mainFrame = nil
    local gui = gethui()
    -- Buscar el Frame que contiene el título y el ScrollingFrame de las pestañas
    for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("Frame") and obj:FindFirstChild("Water Hub | BlockSpin") then
            -- A veces el título es un TextLabel hijo directo de ese Frame
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("ScrollingFrame") or (child:IsA("Frame") and #child:GetChildren() > 0) then
                    mainFrame = obj
                    break
                end
            end
        end
        if mainFrame then break end
    end
    
    if not mainFrame then
        warn("[WATER HUB] No se encontró el frame principal para el vídeo")
        return
    end
    
    -- Hacer el fondo transparente para que se vea el vídeo
    mainFrame.BackgroundTransparency = 1
    
    local videoFrame = Instance.new("VideoFrame")
    videoFrame.Size = UDim2.new(1, 0, 1, 0)
    videoFrame.Position = UDim2.new(0, 0, 0, 0)
    videoFrame.BackgroundTransparency = 1
    videoFrame.Video = "rbxassetid://5608321996"
    videoFrame.Looped = true
    videoFrame.Playing = true
    videoFrame.Volume = 0
    videoFrame.ZIndex = 1
    videoFrame.Parent = mainFrame
    
    -- Subir ZIndex de los demás elementos
    for _, child in ipairs(mainFrame:GetChildren()) do
        if child ~= videoFrame and child:IsA("GuiObject") then
            child.ZIndex = math.max(child.ZIndex, 2)
        end
    end
    print("[WATER HUB] Vídeo de fondo colocado correctamente")
end)

-- ============================================
-- PESTAÑAS
-- ============================================
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "crosshair" })
CombatTab:Section({ Title = "Silent Aim" })
CombatTab:Toggle({Title = "Silent Aim", Value = Features.SilentAim, Callback = function(v) Features.SilentAim = v; SaveConfig() end})
CombatTab:Toggle({Title = "Aim Lock (Hold E)", Value = Features.AimLock, Callback = function(v) Features.AimLock = v; SaveConfig() end})
CombatTab:Slider({Title = "Prediction", Step = 0.001, Value = {Min=0,Max=0.5,Default=Features.Prediction}, Callback = function(v) Features.Prediction = v; SaveConfig() end})
CombatTab:Section({ Title = "Defensa" })
CombatTab:Toggle({Title = "Anti Kill", Value = Features.AntiKill, Callback = function(v) Features.AntiKill = v; if v then StartAntiKill() else StopAntiKill() end; SaveConfig() end})
CombatTab:Slider({Title = "Anti Kill Health %", Step = 5, Value = {Min=5,Max=50,Default=Features.AntiKillHealth}, Callback = function(v) Features.AntiKillHealth = v; SaveConfig() end})

local ESPTab = Window:Tab({ Title = "ESP", Icon = "eye" })
ESPTab:Section({ Title = "Player ESP" })
ESPTab:Toggle({Title = "Cajas (Boxes)", Value = Features.ESPBoxes, Callback = function(v) Features.ESPBoxes = v; SaveConfig() end})
ESPTab:Toggle({Title = "Nombres", Value = Features.ESPNames, Callback = function(v) Features.ESPNames = v; SaveConfig() end})
ESPTab:Toggle({Title = "Distancia", Value = Features.ESPDistance, Callback = function(v) Features.ESPDistance = v; SaveConfig() end})
ESPTab:Toggle({Title = "Resaltado (Chams)", Value = Features.ESPChams, Callback = function(v) Features.ESPChams = v; SaveConfig() end})
ESPTab:Toggle({Title = "Inventario Equipado", Value = Features.ESPInventory, Callback = function(v) Features.ESPInventory = v; SaveConfig() end})
ESPTab:Slider({Title = "Grosor del ESP", Step = 0.5, Value = {Min=0.5,Max=3,Default=Features.ESPThickness}, Callback = function(v) Features.ESPThickness = v; SaveConfig() end})

local MoveTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })
MoveTab:Section({ Title = "Velocidad" })
MoveTab:Toggle({Title = "Walk Speed", Value = Features.WalkSpeed, Callback = function(v) Features.WalkSpeed = v; if v then StartWalkSpeed() end; SaveConfig() end})
MoveTab:Slider({Title = "Velocidad", Step = 5, Value = {Min=16,Max=200,Default=Features.SpeedValue}, Callback = function(v) Features.SpeedValue = v; SaveConfig() end})
MoveTab:Section({ Title = "Saltos y Stamina" })
MoveTab:Toggle({Title = "Super Jump", Value = Features.SuperJump, Callback = function(v) Features.SuperJump = v; if v then StartSuperJump() end; SaveConfig() end})
MoveTab:Slider({Title = "Fuerza de Salto", Step = 10, Value = {Min=50,Max=200,Default=Features.JumpPower}, Callback = function(v) Features.JumpPower = v; SaveConfig() end})
MoveTab:Toggle({Title = "Estamina Infinita", Value = Features.InfiniteStamina, Callback = function(v) Features.InfiniteStamina = v; if v then StartInfiniteStamina() end; SaveConfig() end})

local WeaponTab = Window:Tab({ Title = "WEAPON", Icon = "target" })
WeaponTab:Section({ Title = "Modificadores" })
WeaponTab:Toggle({Title = "Activar Gun Mods", Value = Features.EnableGunMods, Callback = function(v) Features.EnableGunMods = v; if v then ApplyGunMods() end; SaveConfig() end})
WeaponTab:Slider({Title = "Cadencia", Step = 50, Value = {Min=50,Max=2000,Default=Features.FireRate}, Callback = function(v) Features.FireRate = v; ApplyGunMods(); SaveConfig() end})
WeaponTab:Slider({Title = "Retroceso", Step = 0.1, Value = {Min=0,Max=3,Default=Features.Recoil}, Callback = function(v) Features.Recoil = v; ApplyGunMods(); SaveConfig() end})
WeaponTab:Slider({Title = "Tiempo de Recarga", Step = 0.1, Value = {Min=0.1,Max=5,Default=Features.ReloadTime}, Callback = function(v) Features.ReloadTime = v; ApplyGunMods(); SaveConfig() end})

local MiscTab = Window:Tab({ Title = "MISC", Icon = "settings" })
MiscTab:Button({Title = "Cambiar de Servidor", Callback = ServerHop})
MiscTab:Toggle({Title = "Optimizar FPS", Value = Features.FPSBoost, Callback = function(v) Features.FPSBoost = v; if v then FPSBoost() end; SaveConfig() end})
MiscTab:Button({Title = "Guardar Configuración", Callback = function() SaveConfig(); Notify("Configuración", "Guardada") end})

CombatTab:Select()

print("[WATER HUB] Cargado correctamente - Vídeo cubre toda la ventana - ESP de armas mejorado")