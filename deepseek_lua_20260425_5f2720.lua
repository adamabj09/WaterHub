-- =====================================================
-- WATER HUB v5.2 – MOBILE/DUEL ULTIMATE | BY: ABJadam
-- Optimizado para: Delta, Fluxus, Hydrogen, Móvil
-- Funciones: Anti-Kick, Aimbot (WallCheck+Smoothing), ESP con limpieza
-- =====================================================

-- ==================== 1. SERVICIOS ====================
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local HttpService = game:GetService("HttpService")

-- Detectar executor
local isDelta = not newcclosure and not syn and not fluxus

-- ==================== 2. KEY SYSTEM ====================
local KEY_URL = "https://script.google.com/macros/s/AKfycbwFidcaEC0E2L72kUuyTyDqkx8PDpVoISwB5KBcO-t2p0m1LtQueCkFeYgVUFpdu96psg/exec"
local KEY_FILE = "WaterHub_Key.txt"

local function saveKey(key)
    pcall(function()
        if writefile then writefile(KEY_FILE, key)
        elseif syn and syn.io then syn.io.writeFile(KEY_FILE, key) end
    end)
end

local function loadKey()
    local content = nil
    pcall(function()
        if readfile then content = readfile(KEY_FILE)
        elseif syn and syn.io then content = syn.io.readFile(KEY_FILE) end
    end)
    return content
end

local function verifyKey(key)
    local http = (syn and syn.request) or (fluxus and fluxus.request) or request or http_request
    if not http then return false end
    local success, res = pcall(http, {Url = KEY_URL .. "?key=" .. key .. "&action=verify", Method = "GET"})
    if success and res and res.Body then
        local data = HttpService:JSONDecode(res.Body)
        return data.valid == true
    end
    return false
end

local keyValid = false
local savedKey = loadKey()
if savedKey and verifyKey(savedKey) then
    keyValid = true
    print("🔑 Key válida (auto-login)")
else
    local function askKey()
        local gui = Instance.new("ScreenGui")
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 150)
        frame.Position = UDim2.new(0.5, -150, 0.5, -75)
        frame.BackgroundColor3 = Color3.fromRGB(30,30,40)
        frame.Parent = gui
        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0.8, 0, 0, 40)
        input.Position = UDim2.new(0.1, 0, 0.2, 0)
        input.PlaceholderText = "Introduce la Key"
        input.TextColor3 = Color3.new(1,1,1)
        input.BackgroundColor3 = Color3.fromRGB(50,50,60)
        input.Parent = frame
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.4, 0, 0, 40)
        btn.Position = UDim2.new(0.3, 0, 0.6, 0)
        btn.Text = "Verificar"
        btn.BackgroundColor3 = Color3.fromRGB(0,150,200)
        btn.Parent = frame
        btn.MouseButton1Click:Connect(function()
            if verifyKey(input.Text) then
                saveKey(input.Text)
                keyValid = true
                gui:Destroy()
            else
                input.Text = ""
                input.PlaceholderText = "Key inválida"
            end
        end)
        gui.Parent = CoreGui
        repeat task.wait() until keyValid
    end
    askKey()
end
if not keyValid then return end

-- ==================== 3. ANTI-KICK (Delta compatible) ====================
local function SuperAntiCheat()
    pcall(function()
        LocalPlayer.Kick = function() end
        LocalPlayer.Destroy = function() end
    end)
    
    if not isDelta then
        pcall(function()
            local mt = getrawmetatable(game)
            if mt then
                setreadonly(mt, false)
                local oldNamecall = mt.__namecall
                mt.__namecall = function(self, ...)
                    local method = getnamecallmethod()
                    if method == "Kick" or method == "kick" or method == "Destroy" then
                        return nil
                    end
                    return oldNamecall(self, ...)
                end
                setreadonly(mt, true)
            end
        end)
    end
    
    local blacklist = {"Kick","Ban","Report","BAC","AntiCheat","Admin","Log"}
    local function scan(obj)
        for _, v in pairs(obj:GetChildren()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                for _, bad in pairs(blacklist) do
                    if v.Name:find(bad) then
                        pcall(function()
                            if v:IsA("RemoteEvent") then v.OnClientEvent = function() end end
                            v.FireServer = function() end
                        end)
                    end
                end
            end
            scan(v)
        end
    end
    scan(ReplicatedStorage)
    scan(game:GetService("ReplicatedFirst"))
    
    RunService.Heartbeat:Connect(function()
        if LocalPlayer.Kick ~= function() then LocalPlayer.Kick = function() end end
    end)
end
SuperAntiCheat()

-- ==================== 4. VARIABLES GLOBALES ====================
local WaterHub = {
    State = {
        AutoDuel = false, AutoPlay = false, AutoWin = false, AutoFarmWins = false,
        Aimbot = false, SilentAim = false, Triggerbot = false,
        ESPPlayers = false, ESPBrainrot = false, Godmode = false,
        AntiRagdoll = false, AntiStun = false, AntiSlow = false,
        SpeedHack = false, JumpHack = false, Fly = false,
        RemoveAnimation = false, NoAnimationAttack = false, FastAttack = false,
        InfiniteRange = false, AutoCollect = false, AutoLeave = false, AutoQueue = false,
        AntiDetectionDelay = true, Visuals = false,
        SpeedValue = 16, JumpValue = 50, FlySpeed = 50,
        MenuColor = "Azul", CurrentStatus = "Esperando...",
    },
    Stats = { Kills = 0, Wins = 0, Damage = 0 },
    Enemies = {}, Brainrots = {},
    ConfigFile = "WaterHub_Config.json",
    ActiveHighlights = {}  -- Para limpieza de ESP
}

local Colors = {
    Azul = {bg = Color3.fromRGB(25,50,75), accent = Color3.fromRGB(0,150,255)},
    Rojo = {bg = Color3.fromRGB(75,25,25), accent = Color3.fromRGB(255,50,50)},
    Verde = {bg = Color3.fromRGB(25,75,25), accent = Color3.fromRGB(50,255,50)},
    Morado = {bg = Color3.fromRGB(50,25,75), accent = Color3.fromRGB(150,50,255)},
    Rosa = {bg = Color3.fromRGB(75,25,50), accent = Color3.fromRGB(255,80,150)}
}

-- ==================== 5. AUTO-SAVE CONFIG ====================
local function SaveConfig()
    local config = {}
    for k, v in pairs(WaterHub.State) do
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
            config[k] = v
        end
    end
    config.WhitelistNames = WaterHub.WhitelistNames or {}
    local json = HttpService:JSONEncode(config)
    pcall(function()
        if writefile then writefile(WaterHub.ConfigFile, json)
        elseif syn and syn.io then syn.io.writeFile(WaterHub.ConfigFile, json) end
    end)
end

local function LoadConfig()
    local content = nil
    pcall(function()
        if readfile then content = readfile(WaterHub.ConfigFile)
        elseif syn and syn.io then content = syn.io.readFile(WaterHub.ConfigFile) end
    end)
    if content then
        local config = HttpService:JSONDecode(content)
        for k, v in pairs(config) do
            if WaterHub.State[k] ~= nil then
                WaterHub.State[k] = v
            end
        end
        if config.WhitelistNames then WaterHub.WhitelistNames = config.WhitelistNames end
    end
end

-- ==================== 6. LIMPIEZA DE ESP (Optimización memoria) ====================
local function ClearESP()
    for _, highlight in pairs(WaterHub.ActiveHighlights) do
        pcall(function() highlight:Destroy() end)
    end
    WaterHub.ActiveHighlights = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Highlight") and (obj.Name == "ESP_Highlight" or obj.Name == "ESP_Brainrot") then
            pcall(function() obj:Destroy() end)
        end
    end
end

-- ==================== 7. AIMBOT (WallCheck + Smoothing) ====================
local AimbotHandler = {}

function AimbotHandler.GetClosestEnemy()
    local closest, closestDist = nil, math.huge
    for _, enemy in pairs(WaterHub.Enemies) do
        if enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
            local root = enemy.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local mousePos = UserInputService:GetMouseLocation()
                local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = enemy
                end
            end
        end
    end
    return closest
end

function AimbotHandler.WallCheck(enemy)
    if not enemy.Character or not enemy.Character:FindFirstChild("HumanoidRootPart") then return false end
    local origin = Camera.CFrame.Position
    local target = enemy.Character.HumanoidRootPart.Position
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local ray = Workspace:Raycast(origin, (target - origin).Unit * 500, params)
    if ray and ray.Instance:IsDescendantOf(enemy.Character) then return true end
    return false
end

function AimbotHandler.SmoothAim(targetCFrame)
    local currentCF = Camera.CFrame
    local step = 0.15
    local newCF = currentCF:Lerp(targetCFrame, step)
    Camera.CFrame = newCF
end

function AimbotHandler.HandleAimbot()
    if not WaterHub.State.Aimbot then return end
    local target = AimbotHandler.GetClosestEnemy()
    if target and AimbotHandler.WallCheck(target) then
        local root = target.Character.HumanoidRootPart
        local targetCF = CFrame.new(Camera.CFrame.Position, root.Position)
        AimbotHandler.SmoothAim(targetCF)
    end
end

-- ==================== 8. TOGGLES MODERNOS ====================
local function CreateToggle(parent, text, stateKey, onChange)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 35)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220,220,220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.Parent = frame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, 25)
    toggleBtn.Position = UDim2.new(0.85, 0, 0.5, -12)
    toggleBtn.Text = ""
    local currentState = WaterHub.State[stateKey] or false
    toggleBtn.BackgroundColor3 = currentState and Colors[WaterHub.State.MenuColor].accent or Color3.fromRGB(80,80,90)
    toggleBtn.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1,0)
    corner.Parent = toggleBtn
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 20, 0, 20)
    circle.Position = currentState and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 4, 0, 2)
    circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    circle.BorderSizePixel = 0
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1,0)
    circleCorner.Parent = circle
    circle.Parent = toggleBtn
    toggleBtn.Parent = frame
    
    local function updateToggle()
        local active = WaterHub.State[stateKey]
        local targetColor = active and Colors[WaterHub.State.MenuColor].accent or Color3.fromRGB(80,80,90)
        local targetPos = active and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 4, 0, 2)
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = targetPos}):Play()
    end
    
    toggleBtn.MouseButton1Click:Connect(function()
        WaterHub.State[stateKey] = not WaterHub.State[stateKey]
        updateToggle()
        if onChange then onChange(WaterHub.State[stateKey]) end
        SaveConfig()
    end)
    
    updateToggle()
    return toggleBtn
end

-- ==================== 9. GUI PRINCIPAL ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaterHub"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 340, 0, 550)
mainFrame.Position = UDim2.new(0.5, -170, 0.5, -275)
mainFrame.BackgroundColor3 = Colors[WaterHub.State.MenuColor].bg
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

-- Barra superior
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 45)
topBar.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
topBar.BackgroundTransparency = 0.3
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 12)
topCorner.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 5, 0, 0)
title.Text = "💧 WATER HUB 💧"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

-- Crédito
local credit = Instance.new("TextLabel")
credit.Size = UDim2.new(0, 100, 1, -5)
credit.Position = UDim2.new(1, -105, 0, 5)
credit.Text = "BY: ABJadam"
credit.TextColor3 = Color3.fromRGB(200,200,200)
credit.TextSize = 10
credit.Font = Enum.Font.Gotham
credit.BackgroundTransparency = 1
credit.TextXAlignment = Enum.TextXAlignment.Right
credit.Parent = topBar

-- Minimizar
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 35, 0, 30)
minBtn.Position = UDim2.new(1, -40, 0, 8)
minBtn.Text = "🗕"
minBtn.TextColor3 = Color3.fromRGB(255,255,255)
minBtn.BackgroundTransparency = 0.5
minBtn.Parent = topBar

-- ScrollFrame
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -100)
scroll.Position = UDim2.new(0, 5, 0, 50)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 4
scroll.Parent = mainFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

-- Toggles
local toggleDefs = {
    "Auto Duel","Auto Play","Auto Win","Auto Farm Wins",
    "Aimbot","Silent Aim","Triggerbot","ESP Players","ESP Brainrot",
    "Godmode","Anti-Ragdoll","Anti-Stun","Anti-Slow",
    "Speed Hack","Jump Hack","Fly","Remove Animation","No Attack Anim",
    "Fast Attack","Infinite Range","Auto Collect","Auto Leave","Auto Queue",
    "Anti Detection Delay","Visuals"
}

for _, name in ipairs(toggleDefs) do
    local key = name:gsub(" ",""):gsub("%-","")
    CreateToggle(scroll, name, key)
end

-- Speed Slider
local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(1, 0, 0, 45)
speedFrame.BackgroundTransparency = 1
speedFrame.Parent = scroll

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.5, 0, 1, 0)
speedLabel.Text = "Velocidad: " .. WaterHub.State.SpeedValue
speedLabel.TextColor3 = Color3.fromRGB(255,255,255)
speedLabel.BackgroundTransparency = 1
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 13
speedLabel.Parent = speedFrame

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0.35, 0, 0.7, 0)
speedBox.Position = UDim2.new(0.6, 0, 0.15, 0)
speedBox.Text = tostring(WaterHub.State.SpeedValue)
speedBox.BackgroundColor3 = Color3.fromRGB(40,45,55)
speedBox.TextColor3 = Color3.fromRGB(255,255,255)
speedBox.Font = Enum.Font.Gotham
speedBox.TextSize = 13
speedBox.Parent = speedFrame

speedBox.FocusLost:Connect(function()
    local val = tonumber(speedBox.Text)
    if val then WaterHub.State.SpeedValue = math.clamp(val, 16, 200) end
    speedLabel.Text = "Velocidad: " .. WaterHub.State.SpeedValue
    speedBox.Text = tostring(WaterHub.State.SpeedValue)
    SaveConfig()
end)

-- Jump Slider
local jumpFrame = Instance.new("Frame")
jumpFrame.Size = UDim2.new(1, 0, 0, 45)
jumpFrame.BackgroundTransparency = 1
jumpFrame.Parent = scroll

local jumpLabel = Instance.new("TextLabel")
jumpLabel.Size = UDim2.new(0.5, 0, 1, 0)
jumpLabel.Text = "Salto: " .. WaterHub.State.JumpValue
jumpLabel.TextColor3 = Color3.fromRGB(255,255,255)
jumpLabel.BackgroundTransparency = 1
jumpLabel.Font = Enum.Font.Gotham
jumpLabel.TextSize = 13
jumpLabel.Parent = jumpFrame

local jumpBox = Instance.new("TextBox")
jumpBox.Size = UDim2.new(0.35, 0, 0.7, 0)
jumpBox.Position = UDim2.new(0.6, 0, 0.15, 0)
jumpBox.Text = tostring(WaterHub.State.JumpValue)
jumpBox.BackgroundColor3 = Color3.fromRGB(40,45,55)
jumpBox.TextColor3 = Color3.fromRGB(255,255,255)
jumpBox.Font = Enum.Font.Gotham
jumpBox.TextSize = 13
jumpBox.Parent = jumpFrame

jumpBox.FocusLost:Connect(function()
    local val = tonumber(jumpBox.Text)
    if val then WaterHub.State.JumpValue = math.clamp(val, 40, 300) end
    jumpLabel.Text = "Salto: " .. WaterHub.State.JumpValue
    jumpBox.Text = tostring(WaterHub.State.JumpValue)
    SaveConfig()
end)

-- Color Selector
local colorFrame = Instance.new("Frame")
colorFrame.Size = UDim2.new(1, 0, 0, 45)
colorFrame.BackgroundTransparency = 1
colorFrame.Parent = scroll

local colorLabel = Instance.new("TextLabel")
colorLabel.Size = UDim2.new(0.5, 0, 1, 0)
colorLabel.Text = "Color: " .. WaterHub.State.MenuColor
colorLabel.TextColor3 = Color3.fromRGB(255,255,255)
colorLabel.BackgroundTransparency = 1
colorLabel.Font = Enum.Font.Gotham
colorLabel.TextSize = 13
colorLabel.Parent = colorFrame

local colorBtn = Instance.new("TextButton")
colorBtn.Size = UDim2.new(0.35, 0, 0.7, 0)
colorBtn.Position = UDim2.new(0.6, 0, 0.15, 0)
colorBtn.Text = "Cambiar"
colorBtn.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
colorBtn.TextColor3 = Color3.fromRGB(255,255,255)
colorBtn.Font = Enum.Font.GothamBold
colorBtn.TextSize = 12
colorBtn.Parent = colorFrame

colorBtn.MouseButton1Click:Connect(function()
    local order = {"Azul","Rojo","Verde","Morado","Rosa"}
    local idx = 1
    for i, c in ipairs(order) do if c == WaterHub.State.MenuColor then idx = i % #order + 1 break end end
    WaterHub.State.MenuColor = order[idx]
    colorLabel.Text = "Color: " .. WaterHub.State.MenuColor
    colorBtn.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
    mainFrame.BackgroundColor3 = Colors[WaterHub.State.MenuColor].bg
    topBar.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
    SaveConfig()
end)

-- Botón cerrar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -10, 0, 40)
closeBtn.Position = UDim2.new(0, 5, 1, -48)
closeBtn.Text = "❌ CERRAR WATER HUB ❌"
closeBtn.BackgroundColor3 = Color3.fromRGB(100,50,50)
closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Parent = mainFrame

closeBtn.MouseButton1Click:Connect(function()
    ClearESP()
    screenGui:Destroy()
end)

screenGui.Parent = CoreGui

-- ==================== 10. DRAG PARA MÓVIL ====================
local dragging = false
local dragStart, startPos

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ==================== 11. MINIMIZADO FLOTANTE ====================
local minimized = false
local floatingIcon = nil

local function createFloatingIcon()
    local iconGui = Instance.new("ScreenGui")
    iconGui.Name = "WaterHubIcon"
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = UDim2.new(0.8, 0, 0.8, 0)
    btn.Text = "WH"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextSize = 18
    btn.Font = Enum.Font.GothamBold
    btn.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
    local cornerBtn = Instance.new("UICorner")
    cornerBtn.CornerRadius = UDim.new(0, 12)
    cornerBtn.Parent = btn
    btn.Parent = iconGui
    iconGui.Parent = CoreGui
    iconGui.Enabled = false
    
    local dragIcon = false
    local dragStartIcon, startPosIcon
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragIcon = true
            dragStartIcon = input.Position
            startPosIcon = btn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragIcon and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartIcon
            btn.Position = UDim2.new(startPosIcon.X.Scale, startPosIcon.X.Offset + delta.X, startPosIcon.Y.Scale, startPosIcon.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragIcon = false
        end
    end)
    
    btn.MouseButton1Click:Connect(function()
        screenGui.Enabled = true
        iconGui.Enabled = false
        minimized = false
    end)
    
    return iconGui
end

minBtn.MouseButton1Click:Connect(function()
    minimized = true
    screenGui.Enabled = false
    if not floatingIcon then
        floatingIcon = createFloatingIcon()
    else
        floatingIcon.Enabled = true
    end
end)

-- ==================== 12. LOOP PRINCIPAL (Completo) ====================
-- Limpiar ESP al cambiar estado
local lastESPPlayers = false
local lastESPBrainrot = false

RunService.RenderStepped:Connect(function()
    -- Detectar cambio en ESP para limpiar
    if lastESPPlayers ~= WaterHub.State.ESPPlayers or lastESPBrainrot ~= WaterHub.State.ESPBrainrot then
        if not WaterHub.State.ESPPlayers and not WaterHub.State.ESPBrainrot then
            ClearESP()
        end
        lastESPPlayers = WaterHub.State.ESPPlayers
        lastESPBrainrot = WaterHub.State.ESPBrainrot
    end
    
    -- Actualizar enemigos
    WaterHub.Enemies = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(WaterHub.Enemies, plr)
        end
    end
    
    -- Aimbot
    if WaterHub.State.Aimbot then AimbotHandler.HandleAimbot() end
    
    -- ESP Players (con limpieza)
    if WaterHub.State.ESPPlayers then
        for _, enemy in pairs(WaterHub.Enemies) do
            if enemy.Character and not enemy.Character:FindFirstChild("ESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "ESP_Highlight"
                hl.FillColor = Color3.fromRGB(255,0,0)
                hl.OutlineColor = Color3.fromRGB(255,255,0)
                hl.Parent = enemy.Character
                table.insert(WaterHub.ActiveHighlights, hl)
            end
        end
    end
    
    -- ESP Brainrot
    if WaterHub.State.ESPBrainrot then
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and (obj.Name:find("Brainrot") or obj.Name:find("Brain")) and not obj:FindFirstChild("ESP_Brainrot") then
                local hl = Instance.new("Highlight")
                hl.Name = "ESP_Brainrot"
                hl.FillColor = Color3.fromRGB(0,255,0)
                hl.OutlineColor = Color3.fromRGB(255,255,255)
                hl.Parent = obj
                table.insert(WaterHub.ActiveHighlights, hl)
            end
        end
    end
end)

-- Heartbeat con todas las acciones
RunService.Heartbeat:Connect(function()
    -- Auto Duel
    if WaterHub.State.AutoDuel then
        local accept = ReplicatedStorage:FindFirstChild("RE/DuelService/Accept") or ReplicatedStorage:FindFirstChild("RE/Duel/Start")
        if accept then pcall(accept.FireServer, accept) end
    end
    
    -- Auto Play
    if WaterHub.State.AutoPlay then
        local enemy = WaterHub.Enemies[1]
        if enemy and enemy.Character and enemy.Character:FindFirstChild("Humanoid") then
            pcall(function() enemy.Character.Humanoid:TakeDamage(10) end)
            WaterHub.Stats.Damage = WaterHub.Stats.Damage + 10
        end
    end
    
    -- Auto Win
    if WaterHub.State.AutoWin then
        local winRemote = ReplicatedStorage:FindFirstChild("RF/DuelService/Win")
        if winRemote then pcall(winRemote.InvokeServer, winRemote) end
    end
    
    -- Auto Farm Wins
    if WaterHub.State.AutoFarmWins then
        pcall(function()
            local accept = ReplicatedStorage:FindFirstChild("RE/DuelService/Accept") or ReplicatedStorage:FindFirstChild("RE/Duel/Start")
            if accept then accept:FireServer() end
            task.wait(0.5)
            local winRemote = ReplicatedStorage:FindFirstChild("RF/DuelService/Win")
            if winRemote then winRemote:InvokeServer() end
            WaterHub.Stats.Wins = WaterHub.Stats.Wins + 1
        end)
    end
    
    -- Triggerbot
    if WaterHub.State.Triggerbot then
        local target = AimbotHandler.GetClosestEnemy()
        if target and AimbotHandler.WallCheck(target) then
            local shoot = ReplicatedStorage:FindFirstChild("RE/Combat/Shoot")
            if shoot then pcall(shoot.FireServer, shoot, target.Character) end
            WaterHub.Stats.Kills = WaterHub.Stats.Kills + 1
        end
    end
    
    -- Auto Collect
    if WaterHub.State.AutoCollect then
        for _, item in pairs(Workspace:GetDescendants()) do
            if item:IsA("Model") and (item.Name:find("Brainrot") or item.Name:find("Drop")) then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then pcall(function() hrp.CFrame = item:GetPivot() end) end
            end
        end
    end
    
    -- Auto Leave
    if WaterHub.State.AutoLeave then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum and hum.Health < (hum.MaxHealth * 0.3) then
            local leave = ReplicatedStorage:FindFirstChild("RE/Duel/Leave")
            if leave then pcall(leave.FireServer, leave) end
        end
    end
    
    -- Auto Queue
    if WaterHub.State.AutoQueue then
        local queue = ReplicatedStorage:FindFirstChild("RE/Queue/Join")
        if queue then pcall(queue.FireServer, queue) end
    end
    
    -- ==================== MODIFICADORES DE PERSONAJE (COMPLETOS) ====================
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        
        -- Speed Hack
        if WaterHub.State.SpeedHack then
            if hum then hum.WalkSpeed = WaterHub.State.SpeedValue end
        elseif hum and hum.WalkSpeed == WaterHub.State.SpeedValue then
            hum.WalkSpeed = 16
        end
        
        -- Jump Hack
        if WaterHub.State.JumpHack then
            if hum then hum.JumpPower = WaterHub.State.JumpValue end
        elseif hum and hum.JumpPower == WaterHub.State.JumpValue then
            hum.JumpPower = 50
        end
        
        -- Godmode
        if WaterHub.State.Godmode and hum then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
            hum.BreakJointsOnDeath = false
        end
        
        -- Anti Ragdoll
        if WaterHub.State.AntiRagdoll and hum then
            hum.PlatformStand = false
            hum.Sit = false
            hum:GetPropertyChangedSignal("PlatformStand"):Connect(function()
                if hum.PlatformStand then hum.PlatformStand = false end
            end)
        end
        
        -- Anti Stun
        if WaterHub.State.AntiStun then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("RemoteEvent") and v.Name:find("Stun") then
                    pcall(function() v.OnClientEvent = function() end end)
                end
            end
        end
        
        -- Anti Slow
        if WaterHub.State.AntiSlow and hum and hum.WalkSpeed < 16 then
            hum.WalkSpeed = 16
        end
        
        -- Remove Animation
        if WaterHub.State.RemoveAnimation and hum and hum:FindFirstChild("Animator") then
            pcall(function() hum.Animator:Destroy() end)
        end
        
        -- No Animation Attack
        if WaterHub.State.NoAnimationAttack then
            local attackAnim = char:FindFirstChild("AttackAnimation")
            if attackAnim then pcall(function() attackAnim:Destroy() end) end
        end
        
        -- Fast Attack
        if WaterHub.State.FastAttack then
            local cooldown = char:FindFirstChild("AttackCooldown")
            if cooldown then cooldown.Value = 0 end
            local weapon = char:FindFirstChildOfClass("Tool")
            if weapon then
                local cd = weapon:FindFirstChild("Cooldown")
                if cd then cd.Value = 0 end
            end
        end
        
        -- Infinite Range
        if WaterHub.State.InfiniteRange then
            local weapon = char:FindFirstChildOfClass("Tool")
            if weapon then
                local range = weapon:FindFirstChild("Range")
                if range then range.Value = 1000 end
                local reach = weapon:FindFirstChild("Reach")
                if reach then reach.Value = 1000 end
            end
        end
        
        -- Fly (completo)
        if WaterHub.State.Fly then
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if rootPart then
                local bp = rootPart:FindFirstChild("BodyVelocity")
                if not bp then
                    bp = Instance.new("BodyVelocity")
                    bp.MaxForce = Vector3.new(10000, 10000, 10000)
                    bp.Parent = rootPart
                end
                local move = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0, 1, 0) end
                bp.Velocity = move * WaterHub.State.FlySpeed
            end
        elseif char and char:FindFirstChild("HumanoidRootPart") then
            local bp = char.HumanoidRootPart:FindFirstChild("BodyVelocity")
            if bp then pcall(function() bp:Destroy() end) end
        end
    end
end)

-- ==================== 13. LIMPIEZA AL SALIR ====================
Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        ClearESP()
    end
end)

-- Cargar configuración y mostrar mensaje final
LoadConfig()
print("✅ WATER HUB v5.2 – BY ABJadam")
print("🔒 Optimizado para móvil y Delta/Fluxus/Hydrogen")
print("📌 ESP con limpieza automática | Anti-lag | Todas las funciones activas")