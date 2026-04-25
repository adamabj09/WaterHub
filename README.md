-- =====================================================
-- WATER HUB v5.1 – DELTA EDITION | BY: ABJadam
-- Compatible con Delta Executor (y otros)
-- Funciones: Key System, Auto Duel, Aimbot, ESP, etc.
-- Anti-Kick + Anti-Ban mejorado
-- =====================================================

-- ==================== 1. COMPATIBILIDAD DELTA ====================
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

-- Detectar executor y funciones disponibles
local hasSyn = syn and type(syn) == "table"
local hasFluxus = fluxus and type(fluxus) == "table"
local hasDelta = delta and type(delta) == "table" or (not hasSyn and not hasFluxus) -- Delta suele no tener variables globales

-- Funciones de archivo
local writeFileFunc, readFileFunc
if hasSyn and syn.io then
    writeFileFunc = syn.io.writeFile
    readFileFunc = syn.io.readFile
elseif hasFluxus and fluxus.io then
    writeFileFunc = fluxus.io.writeFile
    readFileFunc = fluxus.io.readFile
elseif hasDelta then
    -- Delta usa funciones globales writefile/readfile
    writeFileFunc = writefile
    readFileFunc = readfile
end

-- Funciones HTTP
local httpRequestFunc
if hasSyn and syn.request then
    httpRequestFunc = syn.request
elseif hasFluxus and fluxus.request then
    httpRequestFunc = fluxus.request
elseif hasDelta then
    httpRequestFunc = request or http_request
end

-- Funciones de metatabla (solo si existen)
local getRawMetatable = getrawmetatable
local setReadOnly = setreadonly
local newCClosure = newcclosure

-- ==================== 2. KEY SYSTEM (adaptado) ====================
local KEY_URL = "https://script.google.com/macros/s/AKfycbwFidcaEC0E2L72kUuyTyDqkx8PDpVoISwB5KBcO-t2p0m1LtQueCkFeYgVUFpdu96psg/exec"
local KEY_FILE = "WaterHub_Key.txt"

local function saveKey(key)
    if writeFileFunc then
        pcall(writeFileFunc, KEY_FILE, key)
    end
end

local function loadKey()
    if readFileFunc then
        local success, content = pcall(readFileFunc, KEY_FILE)
        if success then return content end
    end
    return nil
end

local function verifyKey(key)
    if not httpRequestFunc then return false end
    local url = KEY_URL .. "?key=" .. key .. "&action=verify"
    local response = pcall(httpRequestFunc, {Url = url, Method = "GET"})
    if response and response.Body then
        local data = HttpService:JSONDecode(response.Body)
        return data.valid == true
    end
    return false
end

-- Auto-login o pedir key
local keyValid = false
local saved = loadKey()
if saved and verifyKey(saved) then
    keyValid = true
    print("🔑 Key válida (auto-login)")
else
    -- Ventana para ingresar key
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
        local k = input.Text
        if verifyKey(k) then
            saveKey(k)
            keyValid = true
            gui:Destroy()
        else
            input.Text = ""
            input.PlaceholderText = "Key inválida, intenta de nuevo"
        end
    end)
    gui.Parent = CoreGui
    repeat task.wait() until keyValid
end
if not keyValid then return end

-- ==================== 3. ANTI-KICK MEJORADO (Delta compatible) ====================
local function SuperAntiCheat()
    pcall(function()
        LocalPlayer.Kick = function() end
        LocalPlayer.Destroy = function() end
    end)
    -- Si existen las funciones de metatabla, las usamos
    if getRawMetatable and setReadOnly and newCClosure then
        pcall(function()
            local mt = getRawMetatable(game)
            if mt then
                setReadOnly(mt, false)
                local oldNamecall = mt.__namecall
                mt.__namecall = newCClosure(function(self, ...)
                    local method = getnamecallmethod()
                    if method == "Kick" or method == "kick" or method == "Destroy" then
                        return nil
                    end
                    return oldNamecall(self, ...)
                end)
                setReadOnly(mt, true)
            end
        end)
    end
    -- Bloquear remotes maliciosos
    local blacklist = {"Kick","Ban","Report","BAC","AntiCheat"}
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
    -- Heartbeat
    RunService.Heartbeat:Connect(function()
        if LocalPlayer.Kick ~= function() then LocalPlayer.Kick = function() end end
    end)
end
SuperAntiCheat()

-- ==================== 4. CONFIGURACIÓN Y ESTADO ====================
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
    Enemies = {}, WhitelistNames = {},
    ConfigFile = "WaterHub_Config.json"
}

local Colors = {
    Azul = {bg = Color3.fromRGB(25,50,75), accent = Color3.fromRGB(0,150,255)},
    Rojo = {bg = Color3.fromRGB(75,25,25), accent = Color3.fromRGB(255,50,50)},
    Verde = {bg = Color3.fromRGB(25,75,25), accent = Color3.fromRGB(50,255,50)},
    Morado = {bg = Color3.fromRGB(50,25,75), accent = Color3.fromRGB(150,50,255)},
    Rosa = {bg = Color3.fromRGB(75,25,50), accent = Color3.fromRGB(255,80,150)}
}

-- Guardar/ cargar configuración
local function SaveConfig()
    local config = {}
    for k, v in pairs(WaterHub.State) do
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
            config[k] = v
        end
    end
    config.WhitelistNames = WaterHub.WhitelistNames
    local json = HttpService:JSONEncode(config)
    if writeFileFunc then
        pcall(writeFileFunc, WaterHub.ConfigFile, json)
    end
end

local function LoadConfig()
    if readFileFunc then
        local success, content = pcall(readFileFunc, WaterHub.ConfigFile)
        if success and content then
            local config = HttpService:JSONDecode(content)
            for k, v in pairs(config) do
                if WaterHub.State[k] ~= nil then
                    WaterHub.State[k] = v
                end
            end
            if config.WhitelistNames then WaterHub.WhitelistNames = config.WhitelistNames end
        end
    end
end

-- ==================== 5. BARRA FPS ====================
local function CreateFPSBar()
    local fpsGui = Instance.new("ScreenGui")
    fpsGui.Name = "FPSBar"
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 120, 0, 30)
    bar.Position = UDim2.new(0.8, 0, 0.05, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bar.BackgroundTransparency = 0.5
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1,0); corner.Parent = bar
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1,0,1,0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Text = "FPS: -- | MS: --"
    label.Parent = bar
    bar.Parent = fpsGui
    fpsGui.Parent = CoreGui
    local lastTime = os.clock()
    local frames = 0
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = os.clock()
        if now - lastTime >= 0.2 then
            local fps = frames / (now - lastTime)
            local ms = (1 / fps) * 1000
            label.Text = string.format("FPS: %.1f | MS: %.1f", fps, ms)
            frames = 0
            lastTime = now
        end
    end)
    -- arrastrable
    local dragging = false
    local dragStart, startPos
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = bar.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            bar.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ==================== 6. AIMBOT (con WallCheck y Smoothing) ====================
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
    local direction = (target - origin).Unit * 500
    local ray = Ray.new(origin, direction)
    local hit, pos = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
    if hit and hit:IsDescendantOf(enemy.Character) then return true end
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

-- ==================== 7. TOGGLES MODERNOS ====================
local function CreateToggle(parent, text, stateVar, onChange)
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
    toggleBtn.BackgroundColor3 = stateVar and Colors[WaterHub.State.MenuColor].accent or Color3.fromRGB(80,80,90)
    toggleBtn.BorderSizePixel = 0
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(1,0); corner.Parent = toggleBtn
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 20, 0, 20)
    circle.Position = stateVar and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 4, 0, 2)
    circle.BackgroundColor3 = Color3.fromRGB(255,255,255)
    circle.BorderSizePixel = 0
    local circleCorner = Instance.new("UICorner"); circleCorner.CornerRadius = UDim.new(1,0); circleCorner.Parent = circle
    circle.Parent = toggleBtn
    toggleBtn.Parent = frame
    local function updateToggle(active)
        local targetColor = active and Colors[WaterHub.State.MenuColor].accent or Color3.fromRGB(80,80,90)
        local targetPos = active and UDim2.new(1, -24, 0, 2) or UDim2.new(0, 4, 0, 2)
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {Position = targetPos}):Play()
    end
    toggleBtn.MouseButton1Click:Connect(function()
        local newState = not stateVar
        stateVar = newState
        updateToggle(newState)
        if onChange then onChange(newState) end
    end)
    updateToggle(stateVar)
    return function() return stateVar end
end

-- ==================== 8. MENÚ PRINCIPAL + CRÉDITO VISIBLE ====================
local mainGui, floatingIcon, isMinimized

local function CreateFloatingIcon()
    local icon = Instance.new("ScreenGui")
    icon.Name = "WaterHubIcon"
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = UDim2.new(0.5, -25, 0.8, 0)
    btn.Text = "WH"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextSize = 18
    btn.Font = Enum.Font.GothamBold
    btn.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = btn
    btn.Parent = icon
    local drag, dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            drag = true
            dragStart = input.Position
            startPos = btn.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
    btn.MouseButton1Click:Connect(function()
        if mainGui and not isMinimized then
            isMinimized = false
            mainGui.Enabled = true
            icon.Enabled = false
            TweenService:Create(mainGui.MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {BackgroundTransparency = 0.08}):Play()
        end
    end)
    icon.Parent = CoreGui
    icon.Enabled = false
    return icon
end

function CreateMainMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "WaterHubMain"
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 580) -- altura extra para crédito
    mainFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = Colors[WaterHub.State.MenuColor].bg
    mainFrame.BackgroundTransparency = 0.08
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = mainFrame
    -- Barra superior
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 40)
    topBar.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
    topBar.BackgroundTransparency = 0.4
    topBar.Parent = mainFrame
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Text = "⚔️ WATER HUB DUEL ⚔️"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.BackgroundTransparency = 1
    title.Parent = topBar
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 40, 0, 30)
    minBtn.Position = UDim2.new(1, -45, 0, 5)
    minBtn.Text = "🗕"
    minBtn.BackgroundTransparency = 0.5
    minBtn.TextColor3 = Color3.fromRGB(255,255,255)
    minBtn.Parent = topBar
    -- Crédito visible (BY: ABJadam)
    local creditLabel = Instance.new("TextLabel")
    creditLabel.Size = UDim2.new(1, 0, 0, 20)
    creditLabel.Position = UDim2.new(0, 0, 1, -20)
    creditLabel.BackgroundTransparency = 1
    creditLabel.Text = "BY: ABJadam"
    creditLabel.TextColor3 = Color3.fromRGB(200,200,200)
    creditLabel.TextSize = 11
    creditLabel.Font = Enum.Font.Gotham
    creditLabel.TextXAlignment = Enum.TextXAlignment.Right
    creditLabel.Parent = mainFrame
    -- Scroll
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, -90)
    scroll.Position = UDim2.new(0, 5, 0, 45)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 4
    scroll.Parent = mainFrame
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
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
        local state = WaterHub.State[key] or false
        CreateToggle(scroll, name, state, function(newState)
            WaterHub.State[key] = newState
            SaveConfig()
        end)
    end

    -- Slider velocidad
    local speedFrame = Instance.new("Frame")
    speedFrame.Size = UDim2.new(1, 0, 0, 40)
    speedFrame.BackgroundTransparency = 1
    speedFrame.Parent = scroll
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0.5, 0, 1, 0)
    speedLabel.Text = "Speed: " .. WaterHub.State.SpeedValue
    speedLabel.TextColor3 = Color3.fromRGB(255,255,255)
    speedLabel.BackgroundTransparency = 1
    speedLabel.Parent = speedFrame
    local speedBox = Instance.new("TextBox")
    speedBox.Size = UDim2.new(0.4, 0, 0.6, 0)
    speedBox.Position = UDim2.new(0.55, 0, 0.2, 0)
    speedBox.Text = tostring(WaterHub.State.SpeedValue)
    speedBox.BackgroundColor3 = Color3.fromRGB(40,45,55)
    speedBox.TextColor3 = Color3.fromRGB(255,255,255)
    speedBox.Parent = speedFrame
    speedBox.FocusLost:Connect(function()
        local val = tonumber(speedBox.Text)
        if val then WaterHub.State.SpeedValue = math.clamp(val, 16, 200) end
        speedLabel.Text = "Speed: " .. WaterHub.State.SpeedValue
        speedBox.Text = tostring(WaterHub.State.SpeedValue)
        SaveConfig()
    end)

    -- Slider salto
    local jumpFrame = Instance.new("Frame")
    jumpFrame.Size = UDim2.new(1, 0, 0, 40)
    jumpFrame.BackgroundTransparency = 1
    jumpFrame.Parent = scroll
    local jumpLabel = Instance.new("TextLabel")
    jumpLabel.Size = UDim2.new(0.5, 0, 1, 0)
    jumpLabel.Text = "Jump: " .. WaterHub.State.JumpValue
    jumpLabel.TextColor3 = Color3.fromRGB(255,255,255)
    jumpLabel.BackgroundTransparency = 1
    jumpLabel.Parent = jumpFrame
    local jumpBox = Instance.new("TextBox")
    jumpBox.Size = UDim2.new(0.4, 0, 0.6, 0)
    jumpBox.Position = UDim2.new(0.55, 0, 0.2, 0)
    jumpBox.Text = tostring(WaterHub.State.JumpValue)
    jumpBox.BackgroundColor3 = Color3.fromRGB(40,45,55)
    jumpBox.TextColor3 = Color3.fromRGB(255,255,255)
    jumpBox.Parent = jumpFrame
    jumpBox.FocusLost:Connect(function()
        local val = tonumber(jumpBox.Text)
        if val then WaterHub.State.JumpValue = math.clamp(val, 40, 300) end
        jumpLabel.Text = "Jump: " .. WaterHub.State.JumpValue
        jumpBox.Text = tostring(WaterHub.State.JumpValue)
        SaveConfig()
    end)

    -- Selector color
    local colorFrame = Instance.new("Frame")
    colorFrame.Size = UDim2.new(1, 0, 0, 40)
    colorFrame.BackgroundTransparency = 1
    colorFrame.Parent = scroll
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Size = UDim2.new(0.5, 0, 1, 0)
    colorLabel.Text = "Color GUI: " .. WaterHub.State.MenuColor
    colorLabel.TextColor3 = Color3.fromRGB(255,255,255)
    colorLabel.Parent = colorFrame
    local colorBtn = Instance.new("TextButton")
    colorBtn.Size = UDim2.new(0.3, 0, 0.6, 0)
    colorBtn.Position = UDim2.new(0.65, 0, 0.2, 0)
    colorBtn.Text = "Cambiar"
    colorBtn.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
    colorBtn.TextColor3 = Color3.fromRGB(255,255,255)
    colorBtn.Parent = colorFrame
    colorBtn.MouseButton1Click:Connect(function()
        local order = {"Azul","Rojo","Verde","Morado","Rosa"}
        local idx = 1
        for i, c in ipairs(order) do if c == WaterHub.State.MenuColor then idx = i % #order + 1 break end end
        WaterHub.State.MenuColor = order[idx]
        colorLabel.Text = "Color GUI: " .. WaterHub.State.MenuColor
        colorBtn.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
        mainFrame.BackgroundColor3 = Colors[WaterHub.State.MenuColor].bg
        topBar.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
        SaveConfig()
    end)

    -- Botón cerrar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(1, 0, 0, 40)
    closeBtn.Position = UDim2.new(0, 0, 1, -45)
    closeBtn.Text = "Cerrar Hub"
    closeBtn.BackgroundColor3 = Color3.fromRGB(100,50,50)
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.Parent = mainFrame
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
        if floatingIcon then floatingIcon.Enabled = true end
    end)

    mainFrame.Parent = gui
    gui.Parent = CoreGui
    return gui, mainFrame
end

-- ==================== 9. LOOP PRINCIPAL ====================
local function StartGameLoop()
    RunService.RenderStepped:Connect(function()
        WaterHub.Enemies = {}
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(WaterHub.Enemies, plr)
            end
        end
        if WaterHub.State.Aimbot then AimbotHandler.HandleAimbot() end
        if WaterHub.State.ESPPlayers then
            for _, enemy in pairs(WaterHub.Enemies) do
                if enemy.Character and not enemy.Character:FindFirstChild("ESP_Highlight") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ESP_Highlight"
                    hl.FillColor = Color3.fromRGB(255,0,0)
                    hl.OutlineColor = Color3.fromRGB(255,255,0)
                    hl.Parent = enemy.Character
                end
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        -- Auto Duel
        if WaterHub.State.AutoDuel then
            local accept = ReplicatedStorage:FindFirstChild("RE/DuelService/Accept") or ReplicatedStorage:FindFirstChild("RE/Duel/Start")
            if accept then pcall(accept.FireServer, accept) end
        end
        -- Auto Play (daño básico)
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
            if hum and hum.Health < hum.MaxHealth * 0.3 then
                local leave = ReplicatedStorage:FindFirstChild("RE/Duel/Leave")
                if leave then pcall(leave.FireServer, leave) end
            end
        end
        -- Auto Queue
        if WaterHub.State.AutoQueue then
            local queue = ReplicatedStorage:FindFirstChild("RE/Queue/Join")
            if queue then pcall(queue.FireServer, queue) end
        end
        -- Modificadores personaje
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                if WaterHub.State.SpeedHack then hum.WalkSpeed = WaterHub.State.SpeedValue else hum.WalkSpeed = 16 end
                if WaterHub.State.JumpHack then hum.JumpPower = WaterHub.State.JumpValue else hum.JumpPower = 50 end
                if WaterHub.State.Godmode then hum.MaxHealth = math.huge; hum.Health = math.huge end
                if WaterHub.State.AntiRagdoll then hum.PlatformStand = false; hum.Sit = false end
                if WaterHub.State.AntiSlow then hum.WalkSpeed = WaterHub.State.SpeedValue end
                if WaterHub.State.RemoveAnimation and hum:FindFirstChild("Animator") then hum.Animator:Destroy() end
            end
            if WaterHub.State.Fly then
                local bp = char:FindFirstChild("BodyVelocity") or Instance.new("BodyVelocity")
                bp.MaxForce = Vector3.new(10000,10000,10000)
                bp.Parent = char:FindFirstChild("HumanoidRootPart")
                local move = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
                bp.Velocity = move * WaterHub.State.FlySpeed
            end
        end
    end)
end

-- ==================== 10. INICIALIZAR ====================
LoadConfig()
CreateFPSBar()
mainGui, _ = CreateMainMenu()
floatingIcon = CreateFloatingIcon()
StartGameLoop()

-- Minimizar
local minButton = mainGui:FindFirstChild("MainFrame") and mainGui.MainFrame:FindFirstChild("TopBar") and mainGui.MainFrame.TopBar:FindFirstChildWhichIsA("TextButton")
if minButton then
    minButton.MouseButton1Click:Connect(function()
        isMinimized = true
        TweenService:Create(mainGui.MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back), {BackgroundTransparency = 1}):Play()
        task.wait(0.2)
        mainGui.Enabled = false
        floatingIcon.Enabled = true
    end)
end

print("✅ WATER HUB v5.1 DELTA EDITION – BY ABJadam")
print("🔒 Anti-Kick activado | GUI con crédito visible")
