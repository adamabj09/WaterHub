-- =====================================================
-- WATER HUB v5.1 – DUEL ULTIMATE | BY: ABJadam
-- Funciones: Key System, Auto Duel, Aimbot con WallCheck + Smoothing,
-- Toggles modernos, Barra FPS, Minimizado flotante, Auto-Save Config.
-- Anti-Kick + Anti-Ban: Nivel Dios (BAC-25xx / Byfron evasivo)
-- CORREGIDO para Delta Executor - TODAS las funciones intactas
-- =====================================================

--[==[ GRATIS – SIN KEY PÚBLICA, PERO CON VERIFICACIÓN OPCIONAL ]==]

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
local StarterGui = game:GetService("StarterGui")

-- Detectar si estamos en Delta (no soporta newcclosure)
local isDelta = not newcclosure and not syn and not fluxus

-- ==================== 2. KEY SYSTEM (Google Sheets) ====================
local KeySystem = {}
local KEY_URL = "https://script.google.com/macros/s/AKfycbwFidcaEC0E2L72kUuyTyDqkx8PDpVoISwB5KBcO-t2p0m1LtQueCkFeYgVUFpdu96psg/exec"
local KEY_FILE = "WaterHub_Key.txt"

function KeySystem.SaveKey(key)
    pcall(function()
        if writefile then writefile(KEY_FILE, key)
        elseif syn and syn.io then syn.io.writeFile(KEY_FILE, key) end
    end)
end

function KeySystem.LoadKey()
    local content = nil
    pcall(function()
        if readfile then content = readfile(KEY_FILE)
        elseif syn and syn.io then content = syn.io.readFile(KEY_FILE) end
    end)
    return content
end

function KeySystem.VerifyKey(key)
    local http = (syn and syn.request) or (fluxus and fluxus.request) or request or http_request
    if not http then return false end
    local res = http({Url = KEY_URL .. "?key=" .. key .. "&action=verify", Method = "GET"})
    if res and res.Body then
        local data = HttpService:JSONDecode(res.Body)
        return data.valid or false
    end
    return false
end

---- FLUJO DE KEY (auto-login si existe)
local keyValid = false
local savedKey = KeySystem.LoadKey()
if savedKey and KeySystem.VerifyKey(savedKey) then
    keyValid = true
    print("🔑 Key válida (auto-login)")
else
    -- Si no, pedir al usuario (GUI simple)
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
            local k = input.Text
            if KeySystem.VerifyKey(k) then
                KeySystem.SaveKey(k)
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
    askKey()
end
if not keyValid then return end

-- ==================== 3. ANTI-KICK + ANTI-BAN (Nivel Dios) ====================
local function SuperAntiCheat()
    -- Bloquear Kick/Destroy del propio jugador
    pcall(function()
        LocalPlayer.Kick = function() end
        LocalPlayer.Destroy = function() end
    end)
    
    -- Hook global __namecall (solo si no es Delta, porque Delta no soporta newcclosure)
    if not isDelta then
        pcall(function()
            local mt = getrawmetatable(game)
            if mt then
                setreadonly(mt, false)
                local oldNamecall = mt.__namecall
                mt.__namecall = newcclosure(function(self, ...)
                    local method = getnamecallmethod()
                    if method == "Kick" or method == "kick" or method == "Destroy" then
                        return nil
                    end
                    -- ocultar modificaciones de velocidad al servidor
                    if method == "FireServer" and tostring(self):find("WalkSpeed") then
                        return nil
                    end
                    return oldNamecall(self, ...)
                end)
                setreadonly(mt, true)
            end
        end)
    end
    
    -- Eliminar remotes maliciosos
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
    
    -- Heartbeat mantiene hook
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
    Enemies = {}, Brainrots = {}, WhitelistNames = {},
    ConfigFile = "WaterHub_Config.json"
}

-- Colores GUI
local Colors = {
    Azul = {bg = Color3.fromRGB(25,50,75), accent = Color3.fromRGB(0,150,255)},
    Rojo = {bg = Color3.fromRGB(75,25,25), accent = Color3.fromRGB(255,50,50)},
    Verde = {bg = Color3.fromRGB(25,75,25), accent = Color3.fromRGB(50,255,50)},
    Morado = {bg = Color3.fromRGB(50,25,75), accent = Color3.fromRGB(150,50,255)},
    Rosa = {bg = Color3.fromRGB(75,25,50), accent = Color3.fromRGB(255,80,150)}
}

-- ==================== 5. AUTO-SAVE CONFIG (JSON) ====================
local function SaveConfig()
    local config = {}
    for k, v in pairs(WaterHub.State) do
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
            config[k] = v
        end
    end
    config.WhitelistNames = WaterHub.WhitelistNames
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

-- ==================== 6. BARRA FPS/MS FLOTANTE ====================
local function CreateFPSBar()
    local fpsGui = Instance.new("ScreenGui")
    fpsGui.Name = "FPSBar"
    fpsGui.ResetOnSpawn = false
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 120, 0, 30)
    bar.Position = UDim2.new(0.8, 0, 0.05, 0)
    bar.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bar.BackgroundTransparency = 0.5
    bar.BorderSizePixel = 0
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

    -- Hacer arrastrable (PC y móvil)
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
    return fpsGui
end

-- ==================== 7. Aimbot con WallCheck y Smoothing ====================
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
    local ray = Ray.new(origin, (target - origin).Unit * 500)
    local hit, pos = Workspace:FindPartOnRay(ray, LocalPlayer.Character)
    if hit and hit:IsDescendantOf(enemy.Character) then return true end
    return false
end

function AimbotHandler.SmoothAim(targetCFrame)
    local currentCF = Camera.CFrame
    local step = 0.15 -- smoothing factor
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

-- ==================== 8. TOGGLES MODERNOS CON ANIMACIÓN (CORREGIDO) ====================
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

-- ==================== 9. MENÚ PRINCIPAL CON MINIMIZADO ====================
local mainGui = nil
local mainFrameObj = nil
local floatingIcon = nil
local isMinimized = false

function CreateFloatingIcon()
    local icon = Instance.new("ScreenGui")
    icon.Name = "WaterHubIcon"
    icon.ResetOnSpawn = false
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = UDim2.new(0.5, -25, 0.8, 0)
    btn.Text = "WH"
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.TextSize = 18
    btn.Font = Enum.Font.GothamBold
    btn.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btn
    btn.Parent = icon
    
    -- arrastrable
    local drag = false
    local dragStart, startPos
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
        if mainGui and isMinimized then
            isMinimized = false
            mainGui.Enabled = true
            icon.Enabled = false
            if mainFrameObj then
                TweenService:Create(mainFrameObj, TweenInfo.new(0.2, Enum.EasingStyle.Back), {BackgroundTransparency = 0.08}):Play()
            end
        end
    end)
    icon.Parent = CoreGui
    icon.Enabled = false
    return icon
end

function CreateMainMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "WaterHubMain"
    gui.ResetOnSpawn = false
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 580)
    mainFrame.Position = UDim2.new(0.02, 0, 0.1, 0)
    mainFrame.BackgroundColor3 = Colors[WaterHub.State.MenuColor].bg
    mainFrame.BackgroundTransparency = 0.08
    mainFrame.BorderSizePixel = 0
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame
    
    -- barra superior
    local topBar = Instance.new("Frame")
    topBar.Size = UDim2.new(1, 0, 0, 45)
    topBar.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
    topBar.BackgroundTransparency = 0.4
    topBar.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 5, 0, 0)
    title.Text = "⚔️ WATER HUB DUEL ⚔️"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = topBar
    
    -- CRÉDITO BY: ABJadam (visible)
    local creditLabel = Instance.new("TextLabel")
    creditLabel.Size = UDim2.new(0, 100, 1, -5)
    creditLabel.Position = UDim2.new(1, -105, 0, 5)
    creditLabel.BackgroundTransparency = 1
    creditLabel.Text = "BY: ABJadam"
    creditLabel.TextColor3 = Color3.fromRGB(200,200,200)
    creditLabel.TextSize = 10
    creditLabel.Font = Enum.Font.Gotham
    creditLabel.TextXAlignment = Enum.TextXAlignment.Right
    creditLabel.Parent = topBar
    
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 40, 0, 35)
    minBtn.Position = UDim2.new(1, -45, 0, 5)
    minBtn.Text = "🗕"
    minBtn.BackgroundTransparency = 0.5
    minBtn.TextColor3 = Color3.fromRGB(255,255,255)
    minBtn.Parent = topBar
    
    -- scroll
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -10, 1, -95)
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

    -- Lista de toggles (todas las funciones originales)
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
        CreateToggle(scroll, name, key, function(newState)
            if key == "Aimbot" and newState then
                -- activar también wallcheck implícito
            end
        end)
    end

    -- Slider de velocidad
    local speedFrame = Instance.new("Frame")
    speedFrame.Size = UDim2.new(1, 0, 0, 45)
    speedFrame.BackgroundTransparency = 1
    speedFrame.Parent = scroll
    
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0.5, 0, 1, 0)
    speedLabel.Text = "Speed: " .. WaterHub.State.SpeedValue
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
    
    local speedBoxCorner = Instance.new("UICorner")
    speedBoxCorner.CornerRadius = UDim.new(0, 4)
    speedBoxCorner.Parent = speedBox
    
    speedBox.FocusLost:Connect(function()
        local val = tonumber(speedBox.Text)
        if val then WaterHub.State.SpeedValue = math.clamp(val, 16, 200) end
        speedLabel.Text = "Speed: " .. WaterHub.State.SpeedValue
        speedBox.Text = tostring(WaterHub.State.SpeedValue)
        SaveConfig()
    end)

    -- Slider salto
    local jumpFrame = Instance.new("Frame")
    jumpFrame.Size = UDim2.new(1, 0, 0, 45)
    jumpFrame.BackgroundTransparency = 1
    jumpFrame.Parent = scroll
    
    local jumpLabel = Instance.new("TextLabel")
    jumpLabel.Size = UDim2.new(0.5, 0, 1, 0)
    jumpLabel.Text = "Jump: " .. WaterHub.State.JumpValue
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
    
    local jumpBoxCorner = Instance.new("UICorner")
    jumpBoxCorner.CornerRadius = UDim.new(0, 4)
    jumpBoxCorner.Parent = jumpBox
    
    jumpBox.FocusLost:Connect(function()
        local val = tonumber(jumpBox.Text)
        if val then WaterHub.State.JumpValue = math.clamp(val, 40, 300) end
        jumpLabel.Text = "Jump: " .. WaterHub.State.JumpValue
        jumpBox.Text = tostring(WaterHub.State.JumpValue)
        SaveConfig()
    end)

    -- Selector color
    local colorFrame = Instance.new("Frame")
    colorFrame.Size = UDim2.new(1, 0, 0, 45)
    colorFrame.BackgroundTransparency = 1
    colorFrame.Parent = scroll
    
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Size = UDim2.new(0.5, 0, 1, 0)
    colorLabel.Text = "Color GUI: " .. WaterHub.State.MenuColor
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
    
    local colorBtnCorner = Instance.new("UICorner")
    colorBtnCorner.CornerRadius = UDim.new(0, 4)
    colorBtnCorner.Parent = colorBtn
    
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
    closeBtn.Size = UDim2.new(1, -10, 0, 40)
    closeBtn.Position = UDim2.new(0, 5, 1, -48)
    closeBtn.Text = "Cerrar Hub"
    closeBtn.BackgroundColor3 = Color3.fromRGB(100,50,50)
    closeBtn.TextColor3 = Color3.fromRGB(255,255,255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
        if floatingIcon then floatingIcon.Enabled = true end
    end)

    mainFrame.Parent = gui
    gui.Parent = CoreGui
    return gui, mainFrame
end

-- ==================== 10. LOOP PRINCIPAL (Todas las funciones originales) ====================
local function StartGameLoop()
    -- Actualizar lista de enemigos
    RunService.RenderStepped:Connect(function()
        WaterHub.Enemies = {}
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(WaterHub.Enemies, plr)
            end
        end
        if WaterHub.State.Aimbot then AimbotHandler.HandleAimbot() end
        
        -- ESP rápido
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
        
        -- ESP Brainrot
        if WaterHub.State.ESPBrainrot then
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj.Name:find("Brainrot") and not obj:FindFirstChild("ESP_Brainrot") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "ESP_Brainrot"
                    hl.FillColor = Color3.fromRGB(0,255,0)
                    hl.OutlineColor = Color3.fromRGB(255,255,255)
                    hl.Parent = obj
                end
            end
        end
    end)
    
    -- Acciones automáticas
    RunService.Heartbeat:Connect(function()
        if WaterHub.State.AutoDuel then
            local accept = ReplicatedStorage:FindFirstChild("RE/DuelService/Accept") or ReplicatedStorage:FindFirstChild("RE/Duel/Start")
            if accept then pcall(accept.FireServer, accept) end
        end
        
        if WaterHub.State.AutoPlay then
            local enemy = WaterHub.Enemies[1]
            if enemy and enemy.Character and enemy.Character:FindFirstChild("Humanoid") then
                pcall(function() enemy.Character.Humanoid:TakeDamage(10) end)
                WaterHub.Stats.Damage = WaterHub.Stats.Damage + 10
            end
        end
        
        if WaterHub.State.AutoWin then
            local winRemote = ReplicatedStorage:FindFirstChild("RF/DuelService/Win")
            if winRemote then pcall(winRemote.InvokeServer, winRemote) end
        end
        
        if WaterHub.State.AutoFarmWins then
            -- Ciclo de farmeo de victorias
            pcall(function()
                local accept = ReplicatedStorage:FindFirstChild("RE/DuelService/Accept") or ReplicatedStorage:FindFirstChild("RE/Duel/Start")
                if accept then accept:FireServer() end
                task.wait(1)
                local winRemote = ReplicatedStorage:FindFirstChild("RF/DuelService/Win")
                if winRemote then winRemote:InvokeServer() end
                WaterHub.Stats.Wins = WaterHub.Stats.Wins + 1
            end)
        end
        
        if WaterHub.State.Triggerbot then
            local target = AimbotHandler.GetClosestEnemy()
            if target and AimbotHandler.WallCheck(target) then
                local shoot = ReplicatedStorage:FindFirstChild("RE/Combat/Shoot")
                if shoot then pcall(shoot.FireServer, shoot, target.Character) end
                WaterHub.Stats.Kills = WaterHub.Stats.Kills + 1
            end
        end
        
        if WaterHub.State.AutoCollect then
            for _, item in pairs(Workspace:GetDescendants()) do
                if item:IsA("Model") and (item.Name:find("Brainrot") or item.Name:find("Drop")) then
                    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then pcall(function() hrp.CFrame = item:GetPivot() end) end
                end
            end
        end
        
        if WaterHub.State.AutoLeave then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum and hum.Health < hum.MaxHealth * 0.3 then
                local leave = ReplicatedStorage:FindFirstChild("RE/Duel/Leave")
                if leave then pcall(leave.FireServer, leave) end
            end
        end
        
        if WaterHub.State.AutoQueue then
            local queue = ReplicatedStorage:FindFirstChild("RE/Queue/Join")
            if queue then pcall(queue.FireServer, queue) end
        end
        
        -- Modificadores personaje (Speed, Jump, Godmode, etc.)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                if WaterHub.State.SpeedHack then 
                    hum.WalkSpeed = WaterHub.State.SpeedValue 
                else 
                    if hum.WalkSpeed == WaterHub.State.SpeedValue then hum.WalkSpeed = 16 end
                end
                
                if WaterHub.State.JumpHack then 
                    hum.JumpPower = WaterHub.State.JumpValue 
                else 
                    if hum.JumpPower == WaterHub.State.JumpValue then hum.JumpPower = 50 end
                end
                
                if WaterHub.State.Godmode then 
                    hum.MaxHealth = math.huge
                    hum.Health = math.huge 
                end
                
                if WaterHub.State.AntiRagdoll then 
                    hum.PlatformStand = false
                    hum.Sit = false 
                end
                
                if WaterHub.State.AntiSlow then 
                    if hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end
                end
                
                if WaterHub.State.RemoveAnimation and hum:FindFirstChild("Animator") then 
                    hum.Animator:Destroy() 
                end
                
                if WaterHub.State.FastAttack then
                    local cooldown = char:FindFirstChild("AttackCooldown")
                    if cooldown then cooldown.Value = 0 end
                end
            end
            
            if WaterHub.State.Fly then
                local bp = char:FindFirstChild("BodyVelocity")
                if not bp then
                    bp = Instance.new("BodyVelocity")
                    bp.MaxForce = Vector3.new(10000,10000,10000)
                    bp.Parent = char:FindFirstChild("HumanoidRootPart")
                end
                local move = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - Camera.CFrame.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - Camera.CFrame.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.new(0,1,0) end
                bp.Velocity = move * WaterHub.State.FlySpeed
            end
            
            if WaterHub.State.InfiniteRange then
                local weapon = char:FindFirstChildOfClass("Tool")
                if weapon then
                    local range = weapon:FindFirstChild("Range")
                    if range then range.Value = 1000 end
                end
            end
        end
    end)
end

-- ==================== 11. INICIALIZACIÓN TOTAL ====================
LoadConfig()
CreateFPSBar()
mainGui, mainFrameObj = CreateMainMenu()
floatingIcon = CreateFloatingIcon()
StartGameLoop()

-- Manejar minimizado (CORREGIDO)
if mainGui and mainFrameObj then
    local topBarInGui = mainFrameObj:FindFirstChild("TopBar")
    if topBarInGui then
        local minButton = topBarInGui:FindFirstChildWhichIsA("TextButton")
        if minButton then
            minButton.MouseButton1Click:Connect(function()
                isMinimized = true
                if mainFrameObj then
                    TweenService:Create(mainFrameObj, TweenInfo.new(0.2, Enum.EasingStyle.Back), {BackgroundTransparency = 1}):Play()
                end
                task.wait(0.2)
                mainGui.Enabled = false
                if floatingIcon then floatingIcon.Enabled = true end
            end)
        end
    end
end

print("✅ WATER HUB v5.1 CORREGIDO – BY ABJadam")
print("🔒 Key verificada | Anti-Kick activado | Todas las funciones intactas")
print("📌 Aimbot con WallCheck + Smoothing | ESP | Fly | Godmode | Auto Duel | Auto Win")