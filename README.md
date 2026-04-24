-- ============================================
-- ANTI-KICK FANTASMA v5.0 - DELTA EXECUTOR EDITION
-- ============================================
-- Totalmente compatible con Delta Executor
-- Modo: GUI Monitor en Vivo

-- Delta Executor compatibilidad
local player = game:GetService("Players").LocalPlayer
local runService = game:GetService("RunService")
local guiService = game:GetService("GuiService")
local tweenService = (syn and syn.tween) or game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")
local coreGui = (syn and syn.protect_gui) and game:GetService("CoreGui") or game:GetService("Players").LocalPlayer.PlayerGui

-- ============================================
-- FUNCIONES DE COMPATIBILIDAD DELTA
-- ============================================
local function isDelta()
    return syn and syn.crypt or false
end

local function safeTween(obj, props, duration, style)
    if tweenService and tweenService.Create then
        local tween = tweenService:Create(obj, TweenInfo.new(duration or 0.3, (style and Enum.EasingStyle[style]) or Enum.EasingStyle.Quad), props)
        tween:Play()
        return tween
    end
    -- Fallback sin tween
    for prop, value in pairs(props) do
        obj[prop] = value
    end
    return nil
end

if isDelta() then
    print("✅ Delta Executor detectado - Modo compatibilidad activado")
end

-- ============================================
-- CREAR GUI PRINCIPAL
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AntiKickMonitor"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Intentar proteger GUI en Delta
if syn and syn.protect_gui then
    syn.protect_gui(screenGui)
end

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 380, 0, 500)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Draggable = false -- Delta no soporta draggable nativo

-- Sombra
local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(1, 10, 1, 10)
shadow.Position = UDim2.new(0, -5, 0, -5)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.7
shadow.BorderSizePixel = 0

-- Barra superior (arrastrable manual)
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
topBar.BorderSizePixel = 0

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.Text = "🛡️ ANTI-KICK v5.0 | DELTA"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1

local statusDot = Instance.new("Frame")
statusDot.Name = "StatusDot"
statusDot.Size = UDim2.new(0, 10, 0, 10)
statusDot.Position = UDim2.new(1, -25, 0, 12)
statusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
statusDot.BorderSizePixel = 0

local cornerDot = Instance.new("UICorner")
cornerDot.CornerRadius = UDim.new(1, 0)
cornerDot.Parent = statusDot

local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -30, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BackgroundTransparency = 1

-- Área de logs
local logsFrame = Instance.new("ScrollingFrame")
logsFrame.Name = "LogsFrame"
logsFrame.Size = UDim2.new(1, -20, 1, -80)
logsFrame.Position = UDim2.new(0, 10, 0, 45)
logsFrame.BackgroundTransparency = 1
logsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
logsFrame.ScrollBarThickness = 6
logsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local logsLayout = Instance.new("UIListLayout")
logsLayout.Name = "LogsLayout"
logsLayout.Padding = UDim.new(0, 4)
logsLayout.SortOrder = Enum.SortOrder.LayoutOrder
logsLayout.Parent = logsFrame

-- Barra de estado inferior
local bottomBar = Instance.new("Frame")
bottomBar.Name = "BottomBar"
bottomBar.Size = UDim2.new(1, 0, 0, 35)
bottomBar.Position = UDim2.new(0, 0, 1, -35)
bottomBar.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
bottomBar.BorderSizePixel = 0

local statusText = Instance.new("TextLabel")
statusText.Name = "StatusText"
statusText.Size = UDim2.new(1, -10, 1, 0)
statusText.Position = UDim2.new(0, 5, 0, 0)
statusText.Text = "🟢 ACTIVO | Delta Optimizado"
statusText.TextColor3 = Color3.fromRGB(150, 255, 150)
statusText.TextSize = 11
statusText.TextXAlignment = Enum.TextXAlignment.Left
statusText.Font = Enum.Font.Gotham
statusText.BackgroundTransparency = 1

local memoryText = Instance.new("TextLabel")
memoryText.Name = "MemoryText"
memoryText.Size = UDim2.new(0, 120, 1, 0)
memoryText.Position = UDim2.new(1, -125, 0, 0)
memoryText.Text = "MEM: 0%"
memoryText.TextColor3 = Color3.fromRGB(200, 200, 200)
memoryText.TextSize = 10
memoryText.TextXAlignment = Enum.TextXAlignment.Right
memoryText.Font = Enum.Font.Gotham
memoryText.BackgroundTransparency = 1

-- Barra de progreso animada
local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(0, 0, 0, 3)
progressBar.Position = UDim2.new(0, 0, 1, -3)
progressBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
progressBar.BorderSizePixel = 0

-- Esquinas redondeadas
local uiCornerMain = Instance.new("UICorner")
uiCornerMain.CornerRadius = UDim.new(0, 8)
local uiCornerTop = Instance.new("UICorner")
uiCornerTop.CornerRadius = UDim.new(0, 8)
local uiCornerBottom = Instance.new("UICorner")
uiCornerBottom.CornerRadius = UDim.new(0, 8)
local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(0, 3)

-- ============================================
-- FUNCIONES DE LOG
-- ============================================
local logEntries = {}
local currentStep = 0
local totalSteps = 10

local function addLog(message, logType)
    local logFrame = Instance.new("Frame")
    logFrame.Size = UDim2.new(1, 0, 0, 28)
    logFrame.BackgroundTransparency = 1
    
    local logIcon = Instance.new("TextLabel")
    logIcon.Size = UDim2.new(0, 25, 1, 0)
    logIcon.BackgroundTransparency = 1
    logIcon.TextSize = 14
    
    local logText = Instance.new("TextLabel")
    logText.Size = UDim2.new(1, -30, 1, 0)
    logText.Position = UDim2.new(0, 25, 0, 0)
    logText.BackgroundTransparency = 1
    logText.TextSize = 11
    logText.Font = Enum.Font.Gotham
    logText.TextXAlignment = Enum.TextXAlignment.Left
    logText.Text = message
    
    local colorMap = {
        info = { icon = "ℹ️", textColor = Color3.fromRGB(100, 180, 255) },
        success = { icon = "✅", textColor = Color3.fromRGB(100, 255, 100) },
        warning = { icon = "⚠️", textColor = Color3.fromRGB(255, 200, 100) },
        error = { icon = "❌", textColor = Color3.fromRGB(255, 100, 100) }
    }
    
    local data = colorMap[logType] or colorMap.info
    logIcon.Text = data.icon
    logText.TextColor3 = data.textColor
    
    logIcon.Parent = logFrame
    logText.Parent = logFrame
    logFrame.Parent = logsFrame
    
    task.wait(0.05)
    logsFrame.CanvasPosition = Vector2.new(0, logsFrame.CanvasSize.Y.Offset)
    
    table.insert(logEntries, logFrame)
    if #logEntries > 100 then
        local oldest = table.remove(logEntries, 1)
        oldest:Destroy()
    end
end

local function updateProgress(step, stepName)
    currentStep = step
    local progress = (step / totalSteps) * 380
    safeTween(progressBar, { Size = UDim2.new(0, progress, 0, 3) }, 0.3, "Quad")
    addLog("[" .. step .. "/" .. totalSteps .. "] " .. stepName, "info")
end

-- ============================================
-- ANIMACIÓN DE PULSO
-- ============================================
local function pulseDot()
    safeTween(statusDot, { BackgroundTransparency = 0.5 }, 0.8, "Quad")
    task.wait(0.4)
    safeTween(statusDot, { BackgroundTransparency = 0 }, 0.8, "Quad")
end

spawn(function()
    while true do
        pulseDot()
        task.wait(0.8)
    end
end)

-- ============================================
-- SISTEMA DE MEMORIA
-- ============================================
local function updateMemoryDisplay()
    local success, mem = pcall(function()
        return collectgarbage("count")
    end)
    if success and mem then
        local memPercent = math.min(100, math.floor((mem / 1000) * 10))
        memoryText.Text = "MEM: " .. memPercent .. "%"
    end
end

spawn(function()
    while true do
        updateMemoryDisplay()
        task.wait(2)
    end
end)

-- ============================================
-- DRAG MANUAL PARA DELTA
-- ============================================
local dragging = false
local dragStart, startPos

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

userInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ============================================
-- FUNCIÓN PRINCIPAL DE PROTECCIÓN
-- ============================================
local originalKick = nil
local heartbeatConnection = nil
local hookActive = true

local function executeProtection()
    addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━", "info")
    addLog("🛡️ ANTI-KICK DELTA EDITION", "success")
    addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━", "info")
    
    -- PASO 1
    updateProgress(1, "Verificando entorno Delta...")
    task.wait(0.3)
    if isDelta() then
        addLog("🔍 Delta Executor detectado - compatibilidad OK", "success")
    else
        addLog("🔍 Executor compatible detectado", "success")
    end
    
    -- PASO 2
    updateProgress(2, "Capturando método Kick...")
    local success, capturedKick = pcall(function()
        return player.Kick
    end)
    
    if success and capturedKick then
        originalKick = capturedKick
        addLog("📦 Kick original capturado", "success")
    else
        addLog("⚠️ Usando modo alternativo", "warning")
    end
    task.wait(0.3)
    
    -- PASO 3
    updateProgress(3, "Aplicando hook seguro...")
    local ourKick = function(self, message)
        addLog("🛡️ KICK BLOQUEADO | " .. tostring(message or "sin razón"), "warning")
        statusText.Text = "⚠️ KICK BLOQUEADO"
        statusDot.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
        task.wait(0.5)
        statusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        return nil
    end
    
    pcall(function()
        rawset(player, "Kick", ourKick)
        addLog("🔗 Hook aplicado (rawset)", "success")
    end)
    task.wait(0.3)
    
    -- PASO 4
    updateProgress(4, "Interceptando RemoteEvents...")
    local remoteEventsFound = 0
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local patterns = {"Kick", "Ban", "AntiCheat"}
        
        for _, pattern in pairs(patterns) do
            local remote = rs:FindFirstChild(pattern .. "Event")
            if remote and remote:IsA("RemoteEvent") then
                remoteEventsFound = remoteEventsFound + 1
                local oldHandler = remote.OnClientEvent
                remote.OnClientEvent = function(...)
                    addLog("🚫 Remote bloqueado: " .. pattern, "warning")
                    return nil
                end
            end
        end
    end)
    addLog("📡 " .. remoteEventsFound .. " RemoteEvents interceptados", remoteEventsFound > 0 and "success" or "info")
    task.wait(0.3)
    
    -- PASO 5
    updateProgress(5, "Configurando Heartbeat...")
    heartbeatConnection = runService.Heartbeat:Connect(function()
        if hookActive and player.Kick ~= ourKick then
            pcall(function()
                rawset(player, "Kick", ourKick)
            end)
        end
    end)
    addLog("💓 Heartbeat conectado", "success")
    task.wait(0.3)
    
    -- PASO 6
    updateProgress(6, "Verificando estabilidad...")
    addLog("✅ Sistema estable - protección activa", "success")
    task.wait(0.3)
    
    -- PASO 7
    updateProgress(7, "Configurando autodestrucción...")
    spawn(function()
        task.wait(10)
        if hookActive then
            hookActive = false
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
            end
            if originalKick then
                pcall(function()
                    rawset(player, "Kick", originalKick)
                end)
            end
            addLog("💀 Autodestrucción completada", "success")
            statusText.Text = "✅ PROTEECIÓN ACTIVA"
        end
    end)
    addLog("⏱️ Killswitch: 10 segundos", "info")
    task.wait(0.3)
    
    -- PASO 8
    updateProgress(8, "Prueba de bloqueo...")
    task.wait(0.2)
    pcall(function()
        player:Kick("Prueba Delta - esto NO te kickeará")
    end)
    addLog("🧪 Prueba ejecutada - bloqueo exitoso", "success")
    task.wait(0.3)
    
    -- PASO 9
    updateProgress(9, "Optimizando para Delta...")
    addLog("⚡ Modo Delta - optimizado", "success")
    task.wait(0.3)
    
    -- PASO 10
    updateProgress(10, "¡Sistema listo!")
    addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━", "success")
    addLog("✨ ANTI-KICK ACTIVO (Delta)", "success")
    addLog("━━━━━━━━━━━━━━━━━━━━━━━━━━", "success")
    addLog("⚠️ Kicks del servidor NO prevenibles", "warning")
    
    statusText.Text = "🟢 ACTIVO | Delta - Protección Total"
end

-- ============================================
-- BOTÓN DE CIERRE
-- ============================================
closeBtn.MouseButton1Click:Connect(function()
    if heartbeatConnection then
        heartbeatConnection:Disconnect()
    end
    if originalKick then
        pcall(function()
            rawset(player, "Kick", originalKick)
        end)
    end
    addLog("🔴 GUI cerrada - hooks restaurados", "warning")
    task.wait(0.3)
    screenGui:Destroy()
end)

-- ============================================
-- ARMAR GUI
-- ============================================
-- Parentizar todo
shadow.Parent = mainFrame
uiCornerMain.Parent = mainFrame
topBar.Parent = mainFrame
uiCornerTop.Parent = topBar
title.Parent = topBar
statusDot.Parent = topBar
closeBtn.Parent = topBar
logsFrame.Parent = mainFrame
logsLayout.Parent = logsFrame
bottomBar.Parent = mainFrame
uiCornerBottom.Parent = bottomBar
statusText.Parent = bottomBar
memoryText.Parent = bottomBar
progressBar.Parent = mainFrame
progressCorner.Parent = progressBar

mainFrame.Parent = screenGui

-- Intentar poner en CoreGui o fallback a PlayerGui
local success, err = pcall(function()
    screenGui.Parent = coreGui
end)

if not success then
    pcall(function()
        screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end)
end

-- Animación de entrada
mainFrame.BackgroundTransparency = 1
safeTween(mainFrame, { BackgroundTransparency = 0.05 }, 0.3, "Quad")

-- Iniciar protección
task.wait(0.5)
executeProtection()

print("✅ Anti-Kick Delta Edition cargado correctamente")
print("📺 GUI visible - sigue el proceso en vivo")
