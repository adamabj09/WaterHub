--[[
    WATER HUB | BLOCKSPIN - VERSION OPTIMIZADA
    Silent Aim + ESP Mejorados | Sin Farm
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
    warn("Error cargando WindUI")
    return
end

-- ============================================
-- CONFIGURACIÓN PRINCIPAL
-- ============================================
local ConfigFile = "WaterHub_BlockSpin_v4.json"

local Features = {
    -- SILENT AIM
    SilentAim = false,
    AimLock = false,
    Prediction = 0.165,
    AimLockKeybind = Enum.KeyCode.E,
    
    -- ESP
    ESPBoxes = false,
    ESPNames = false,
    ESPDistance = false,
    ESPChams = false,
    ESPInventory = false,
    ESPColor = Color3.fromRGB(0, 150, 255),
    ESPThickness = 1,
    
    -- MOVEMENT
    WalkSpeed = false,
    SpeedValue = 50,
    SuperJump = false,
    JumpPower = 100,
    InfiniteStamina = false,
    AntiKill = false,
    AntiKillHealth = 20,
    
    -- WEAPON
    EnableGunMods = false,
    FireRate = 600,
    Recoil = 0,
    ReloadTime = 0.1,
    
    -- MISC
    FPSBoost = false,
    ThemeColor = Color3.fromHex("#0096FF")
}

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
LoadConfig()

-- ============================================
-- NOTIFICACIONES Y GUARDADO
-- ============================================
local function Notify(title, message)
    pcall(function()
        WindUI:Notify({Title = title, Content = message, Duration = 2.5})
    end)
end

-- Añadido parámetro "silent" para que no salten notificaciones como locas con los sliders
local function SaveConfig(silent)
    local dataToSave = {
        SilentAim = Features.SilentAim,
        AimLock = Features.AimLock,
        Prediction = Features.Prediction,
        ESPBoxes = Features.ESPBoxes,
        ESPNames = Features.ESPNames,
        ESPDistance = Features.ESPDistance,
        ESPChams = Features.ESPChams,
        ESPInventory = Features.ESPInventory,
        WalkSpeed = Features.WalkSpeed,
        SpeedValue = Features.SpeedValue,
        SuperJump = Features.SuperJump,
        JumpPower = Features.JumpPower,
        InfiniteStamina = Features.InfiniteStamina,
        AntiKill = Features.AntiKill,
        EnableGunMods = Features.EnableGunMods,
        FireRate = Features.FireRate,
        Recoil = Features.Recoil,
        ThemeColor = Features.ThemeColor
    }
    pcall(function()
        writefile(ConfigFile, HttpService:JSONEncode(dataToSave))
        if not silent then
            Notify("Configuración", "Guardada correctamente.")
        end
    end)
end

-- ============================================
-- SILENT AIM + AIMLOCK (BLOCKSPIN SYSTEM)
-- ============================================
local Aiming = loadstring(game:HttpGet("https://raw.githubusercontent.com/RapperDeluxe/scripts/main/silent%20aim%20module"))()
Aiming.TeamCheck(false)

local CombatSettings = {
    SilentAim = Features.SilentAim,
    AimLock = Features.AimLock,
    Prediction = Features.Prediction,
    AimLockKeybind = Features.AimLockKeybind
}

function Aiming.Check()
    if not (Aiming.Enabled == true and Aiming.Selected ~= LocalPlayer and Aiming.SelectedPart ~= nil) then
        return false
    end
    
    local Character = Aiming.Character(Aiming.Selected)
    if not Character then return false end
    
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid or Humanoid.Health <= 0 then return false end
    
    return true
end

local __index
__index = hookmetamethod(game, "__index", function(t, k)
    if (t:IsA("Mouse") and (k == "Hit" or k == "Target") and Aiming.Check() and CombatSettings.SilentAim) then
        local SelectedPart = Aiming.SelectedPart
        local Hit = SelectedPart.CFrame + (SelectedPart.Velocity * CombatSettings.Prediction)
        return (k == "Hit" and Hit or SelectedPart)
    end
    return __index(t, k)
end)

RunService:BindToRenderStep("AimLock", 0, function()
    if (CombatSettings.AimLock and Aiming.Check() and UserInputService:IsKeyDown(CombatSettings.AimLockKeybind)) then
        local SelectedPart = Aiming.SelectedPart
        local Hit = SelectedPart.CFrame + (SelectedPart.Velocity * CombatSettings.Prediction)
        Workspace.CurrentCamera.CFrame = CFrame.lookAt(Workspace.CurrentCamera.CFrame.Position, Hit.Position)
    end
end)

-- ============================================
-- ESP SYSTEM + BLOCKSPIN INVENTORY SCANNER
-- ============================================
local ESPObjects = {}
local LowfiESP = {
    Boxes = Features.ESPBoxes,
    Names = Features.ESPNames,
    Distance = Features.ESPDistance,
    Cham = Features.ESPChams,
    Inventory = Features.ESPInventory,
    Color = Features.ESPColor,
    Thickness = Features.ESPThickness
}

local COLORES_RAREZA = {
    ["rojo"]    = Color3.fromRGB(255, 30, 30),
    ["naranja"] = Color3.fromRGB(255, 120, 0),
    ["morada"]  = Color3.fromRGB(160, 32, 240),
    ["azul"]    = Color3.fromRGB(30, 144, 255),
    ["verde"]   = Color3.fromRGB(50, 205, 50),
    ["gris"]    = Color3.fromRGB(180, 180, 180)
}

local datosObjetos = {
    ["Ak 47"] = {rareza = "naranja"}, ["Anaconda"] = {rareza = "rojo"}, ["C9"] = {rareza = "verde"},
    ["Double barril"] = {rareza = "morada"}, ["Draco"] = {rareza = "morada"}, ["Firework"] = {rareza = "morada"},
    ["G3"] = {rareza = "verde"}, ["Glock"] = {rareza = "azul"}, ["M16"] = {rareza = "naranja"},
    ["M241"] = {rareza = "rojo"}, ["MP5"] = {rareza = "naranja"}, ["P226"] = {rareza = "azul"},
    ["RPG"] = {rareza = "naranja"}, ["Remington"] = {rareza = "naranja"}, ["Sawnoff"] = {rareza = "naranja"},
    ["Skorpion"] = {rareza = "morada"}, ["Uzi"] = {rareza = "azul"}, ["Baseball Bat"] = {rareza = "verde"},
    ["Tactical Axe"] = {rareza = "naranja"}, ["Tactical Knife"] = {rareza = "naranja"}, ["Tactical Shovel"] = {rareza = "naranja"},
    ["Crowbar"] = {rareza = "azul"}, ["Switchblade"] = {rareza = "azul"}, ["Granada"] = {rareza = "morada"},
    ["Molotov"] = {rareza = "morada"}, ["Mop"] = {rareza = "gris"}, ["First Aid Kit"] = {rareza = "morada"},
    ["Energy Shot"] = {rareza = "morada"}, ["Bandage"] = {rareza = "gris"}, ["FishingRodRegular"] = {rareza = "gris"},
    ["FishingRodPro"] = {rareza = "gris"}, ["FishingRodUltimate"] = {rareza = "gris"}
}

local CurrentCamera = Workspace.CurrentCamera
local V2New = Vector2.new

local function NewDrawing(Object, Props)
    local New = Drawing.new(Object)
    for i, v in pairs(Props or {}) do New[i] = v end
    return New
end

local function CreateESP(P, User, Obj)
    if not Obj or not Obj.Parent then return end
    local Char = Obj.Parent
    local Head = Char:WaitForChild("Head", 5)
    if not Head then return end
    
    local bGui = Instance.new("BillboardGui")
    bGui.Name = "WaterHub_InvESP"
    bGui.AlwaysOnTop = true
    bGui.Size = UDim2.new(0, 200, 0, 50)
    bGui.StudsOffset = Vector3.new(0, 3.5, 0)
    bGui.Enabled = false
    bGui.Parent = gethui() or Head
    if bGui.Parent ~= Head then bGui.Adornee = Head end

    local iText = Instance.new("TextLabel")
    iText.Size = UDim2.new(1, 0, 1, 0)
    iText.BackgroundTransparency = 1
    iText.TextSize = 13
    iText.Font = Enum.Font.SourceSansBold
    iText.TextColor3 = Color3.fromRGB(255, 255, 255)
    iText.TextStrokeTransparency = 0
    iText.Text = "[Fists]"
    iText.Parent = bGui

    local Box = NewDrawing("Square", {Thickness = LowfiESP.Thickness, Color = LowfiESP.Color, Transparency = 1, Filled = false, Visible = false})
    local Name = NewDrawing("Text", {Text = User, Color = Color3.fromRGB(255, 255, 255), Transparency = 1, Outline = true, Center = true, Visible = false, Size = 13, Font = 2})
    local Distance = NewDrawing("Text", {Text = "0m", Color = Color3.fromRGB(200, 200, 200), Transparency = 1, Outline = true, Center = true, Visible = false, Size = 12, Font = 2})

    local Connection
    Connection = RunService.RenderStepped:Connect(function()
        if not Box or not bGui:IsDescendantOf(game) then 
            Connection:Disconnect()
            return 
        end
        
        local RootPos, RootVis = CurrentCamera:WorldToViewportPoint(Obj.Position)
        local GetDistance = (CurrentCamera.CFrame.p - Obj.Position).Magnitude
        local Humanoid = Char:FindFirstChild("Humanoid")
        
        if RootVis and Humanoid and Humanoid.Health > 0 then
            local Size = V2New(2000 / RootPos.Z, 3000 / RootPos.Z)
            
            if LowfiESP.Boxes then
                Box.Size = Size
                Box.Position = V2New(RootPos.X - Size.X / 2, RootPos.Y - Size.Y / 2)
                Box.Color = LowfiESP.Color
                Box.Thickness = LowfiESP.Thickness
                Box.Visible = true
            else Box.Visible = false end

            if LowfiESP.Names then
                Name.Position = V2New(RootPos.X, RootPos.Y - (Size.Y / 2) - 20)
                Name.Visible = true
            else Name.Visible = false end

            if LowfiESP.Distance then
                Distance.Text = tostring(math.floor(GetDistance)) .. "m"
                Distance.Position = V2New(RootPos.X, RootPos.Y + (Size.Y / 2) + 5)
                Distance.Visible = true
            else Distance.Visible = false end

            -- Escáner de inventario para BlockSpin (Lee Tools nativas y Modelos 3D pegados al jugador)
            if LowfiESP.Inventory then
                local objetoEquipado = nil
                
                -- Busca herramientas estándar
                local tool = Char:FindFirstChildOfClass("Tool")
                if tool then 
                    objetoEquipado = tool.Name 
                else
                    -- Si no hay tool, escanea los objetos pegados al personaje por si el juego usa accesorios/modelos como armas
                    for nombreEnLista, _ in pairs(datosObjetos) do
                        if Char:FindFirstChild(nombreEnLista) then
                            objetoEquipado = nombreEnLista
                            break
                        end
                    end
                end

                if objetoEquipado and datosObjetos[objetoEquipado] then
                    iText.Text = "[" .. objetoEquipado .. "]"
                    iText.TextColor3 = COLORES_RAREZA[datosObjetos[objetoEquipado].rareza] or COLORES_RAREZA["gris"]
                else
                    iText.Text = "[Ninguno]"
                    iText.TextColor3 = COLORES_RAREZA["gris"]
                end
                bGui.Enabled = true
            else
                bGui.Enabled = false
            end
            
            if LowfiESP.Cham then
                for _, part in ipairs(Char:GetDescendants()) do
                    if part:IsA("BasePart") and not part:FindFirstChild("ESP_Highlight") then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "ESP_Highlight"
                        highlight.FillColor = LowfiESP.Color
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.FillTransparency = 0.5
                        highlight.Parent = part
                    end
                end
            end
        else
            Box.Visible = false; Name.Visible = false; Distance.Visible = false; bGui.Enabled = false
        end
    end)

    local function Cleanup()
        Connection:Disconnect()
        Box:Remove(); Name:Remove(); Distance:Remove()
        bGui:Destroy()
        for _, part in ipairs(Char:GetDescendants()) do
            if part:FindFirstChild("ESP_Highlight") then part.ESP_Highlight:Destroy() end
        end
    end
    
    Obj.AncestryChanged:Connect(function(_, Parent) if Parent == nil then Cleanup() end end)
    table.insert(ESPObjects, {Player = P, Cleanup = Cleanup})
end

local function OnCharacterAdded(Char)
    local Plr = Players:GetPlayerFromCharacter(Char)
    if not Plr or Plr == LocalPlayer then return end
    
    if not Char:FindFirstChild("HumanoidRootPart") then
        local Env
        Env = Char.ChildAdded:Connect(function(Child)
            if Child.Name == "HumanoidRootPart" then
                Env:Disconnect()
                CreateESP(Plr, Plr.Name, Child)
            end
        end)
    else CreateESP(Plr, Plr.Name, Char.HumanoidRootPart) end
end

local function OnPlayerAdded(P)
    if P == LocalPlayer then return end
    P.CharacterAdded:Connect(OnCharacterAdded)
    if P.Character then task.spawn(OnCharacterAdded, P.Character) end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do OnPlayerAdded(p) end
Players.PlayerRemoving:Connect(function(p)
    for i, obj in ipairs(ESPObjects) do
        if obj.Player == p then
            pcall(obj.Cleanup)
            table.remove(ESPObjects, i)
            break
        end
    end
end)

-- ============================================
-- MOVIMIENTO
-- ============================================
local function WalkSpeedLoop()
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
end

local function SuperJumpLoop()
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
end

local function InfiniteStaminaLoop()
    while Features.InfiniteStamina do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum:SetAttribute("Stamina", 125) end
        end
        task.wait(0.2)
    end
end

-- ============================================
-- ANTI KILL
-- ============================================
local AntiKillConnection
local function AntiKillFunction()
    if not Features.AntiKill then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hum and hrp then
        local healthPercent = (hum.Health / hum.MaxHealth) * 100
        if healthPercent <= Features.AntiKillHealth then
            local targetPos = Vector3.new(hrp.Position.X, -26, hrp.Position.Z)
            TweenService:Create(hrp, TweenInfo.new(0.5), {CFrame = CFrame.new(targetPos)}):Play()
        end
    end
end

-- ============================================
-- GUN MODS
-- ============================================
local function ApplyGunMods()
    if not Features.EnableGunMods then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local config = tool:FindFirstChild("Configuration")
            if config then
                local fireRate = config:FindFirstChild("FireRate")
                if fireRate then fireRate.Value = Features.FireRate end
                local recoil = config:FindFirstChild("Recoil")
                if recoil then recoil.Value = Features.Recoil end
                local reload = config:FindFirstChild("ReloadTime")
                if reload then reload.Value = Features.ReloadTime end
            end
        end
    end
end

-- ============================================
-- SERVER HOP & FPS BOOST
-- ============================================
local function ServerHop()
    local PlaceID = game.PlaceId
    local url = "https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100"
    local success, result = pcall(function() return game:HttpGet(url) end)
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
    Notify("Error", "No se encontraron servidores")
end

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
-- UI (WINDUI)
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | BlockSpin",
    Author = "Optimized",
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

-- 1. COMBAT
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "crosshair" })
CombatTab:Section({ Title = "Silent Aim", Desc = "Asistencia de disparo silenciosa" })

CombatTab:Toggle({
    Title = "Silent Aim",
    Value = Features.SilentAim,
    Callback = function(v)
        Features.SilentAim = v
        CombatSettings.SilentAim = v
        SaveConfig(true)
    end,
})

CombatTab:Toggle({
    Title = "Aim Lock (Hold E)",
    Value = Features.AimLock,
    Callback = function(v)
        Features.AimLock = v
        CombatSettings.AimLock = v
        SaveConfig(true)
    end,
})

CombatTab:Slider({
    Title = "Prediction",
    Step = 0.001,
    Value = { Min = 0, Max = 0.5, Default = Features.Prediction },
    Callback = function(v)
        Features.Prediction = v
        CombatSettings.Prediction = v
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
            AntiKillConnection = RunService.Heartbeat:Connect(AntiKillFunction)
        elseif AntiKillConnection then
            AntiKillConnection:Disconnect()
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

-- 2. ESP
local ESPTab = Window:Tab({ Title = "ESP", Icon = "eye" })
ESPTab:Section({ Title = "Player ESP", Desc = "Indicadores visuales y de inventario" })

ESPTab:Toggle({
    Title = "Cajas (Boxes)",
    Value = Features.ESPBoxes,
    Callback = function(v)
        Features.ESPBoxes = v
        LowfiESP.Boxes = v
        SaveConfig(true)
    end,
})

ESPTab:Toggle({
    Title = "Nombres",
    Value = Features.ESPNames,
    Callback = function(v)
        Features.ESPNames = v
        LowfiESP.Names = v
        SaveConfig(true)
    end,
})

ESPTab:Toggle({
    Title = "Distancia",
    Value = Features.ESPDistance,
    Callback = function(v)
        Features.ESPDistance = v
        LowfiESP.Distance = v
        SaveConfig(true)
    end,
})

ESPTab:Toggle({
    Title = "Resaltado (Chams)",
    Value = Features.ESPChams,
    Callback = function(v)
        Features.ESPChams = v
        LowfiESP.Cham = v
        SaveConfig(true)
    end,
})

ESPTab:Toggle({
    Title = "Inventario Equipado",
    Value = Features.ESPInventory,
    Callback = function(v)
        Features.ESPInventory = v
        LowfiESP.Inventory = v
        SaveConfig(true)
    end,
})

ESPTab:Slider({
    Title = "Grosor del ESP",
    Step = 0.5,
    Value = { Min = 0.5, Max = 3, Default = Features.ESPThickness },
    Callback = function(v)
        Features.ESPThickness = v
        LowfiESP.Thickness = v
        SaveConfig(true)
    end,
})

-- 3. MOVEMENT
local MoveTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })
MoveTab:Section({ Title = "Movimiento" })

MoveTab:Toggle({
    Title = "Walk Speed",
    Value = Features.WalkSpeed,
    Callback = function(v)
        Features.WalkSpeed = v
        if v then task.spawn(WalkSpeedLoop) end
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
        if v then task.spawn(SuperJumpLoop) end
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
        if v then task.spawn(InfiniteStaminaLoop) end
        SaveConfig(true)
    end,
})

-- 4. WEAPON
local WeaponTab = Window:Tab({ Title = "WEAPON", Icon = "target" })
WeaponTab:Section({ Title = "Modificadores de Armas" })

WeaponTab:Toggle({
    Title = "Activar Gun Mods",
    Value = Features.EnableGunMods,
    Callback = function(v)
        Features.EnableGunMods = v
        ApplyGunMods()
        SaveConfig(true)
    end,
})

WeaponTab:Slider({
    Title = "Cadencia (Fire Rate)",
    Step = 50,
    Value = { Min = 50, Max = 2000, Default = Features.FireRate },
    Callback = function(v)
        Features.FireRate = v
        ApplyGunMods()
        SaveConfig(true)
    end,
})

WeaponTab:Slider({
    Title = "Retroceso (Recoil)",
    Step = 0.1,
    Value = { Min = 0, Max = 3, Default = Features.Recoil },
    Callback = function(v)
        Features.Recoil = v
        ApplyGunMods()
        SaveConfig(true)
    end,
})

-- 5. MISC
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
        if v then FPSBoost() end
        SaveConfig(true)
    end,
})

MiscTab:Button({
    Title = "Guardar Configuración Manual",
    Callback = function()
        SaveConfig(false) -- Aquí el 'false' hace que SÍ muestre la notificación
    end
})

-- Seleccionar primera pestaña
CombatTab:Select()

print("Water Hub | BlockSpin - Cargado con éxito")
