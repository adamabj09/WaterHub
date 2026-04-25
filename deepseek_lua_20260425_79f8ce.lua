-- =====================================================
-- WATER HUB v5.3 – GUI PROFESSIONAL | BY: ABJadam
-- Diseño elegante | Animación de lluvia | Delta Compatible
-- KEY DESACTIVADA (modo demo) - Presiona "Verificar" para abrir
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
local Lighting = game:GetService("Lighting")

-- ==================== 2. KEY SYSTEM (DESACTIVADA - MODO DEMO) ====================
local keyValid = true  -- DESACTIVADA: Siempre válida para ver la GUI
local KEY_URL = "https://script.google.com/macros/s/AKfycbyfxTS6LpCaDvEMrSyJRrRb32bXjNlDW3yaWWZZocqIYmG6ztz0uRKcpqx1ieP0uLXaog/exec"

-- Las funciones de key existen pero no bloquean
local function saveKey(key) pcall(function() if writefile then writefile("WaterHub_Key.txt", key) end end) end
local function loadKey() local c = nil pcall(function() if readfile then c = readfile("WaterHub_Key.txt") end end) return c end
local function verifyKey(key) return true end  -- SIEMPRE VÁLIDA

print("🔓 Modo demo - Key desactivada para pruebas")

-- ==================== 3. ANTI-KICK (Delta compatible) ====================
local function SuperAntiCheat()
    pcall(function() LocalPlayer.Kick = function() end end)
    
    local blacklist = {"Kick","Ban","Report","BAC","AntiCheat","Admin","Log"}
    local function scan(obj)
        if not obj then return end
        pcall(function()
            for _, v in pairs(obj:GetChildren()) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    for _, bad in pairs(blacklist) do
                        if v.Name:find(bad) then
                            pcall(function() v.FireServer = function() end v.OnClientEvent = function() end end)
                        end
                    end
                end
                scan(v)
            end
        end)
    end
    scan(ReplicatedStorage)
    scan(game:GetService("ReplicatedFirst"))
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
        SpeedValue = 16, JumpValue = 50, FlySpeed = 50,
        MenuColor = "Azul"
    },
    Enemies = {}, ActiveHighlights = {},
    ConfigFile = "WaterHub_Config.json"
}

local Colors = {
    Azul = {bg = Color3.fromRGB(20,30,45), accent = Color3.fromRGB(0,180,255), glow = Color3.fromRGB(0,100,200)},
    Rojo = {bg = Color3.fromRGB(45,20,20), accent = Color3.fromRGB(255,60,60), glow = Color3.fromRGB(200,0,0)},
    Verde = {bg = Color3.fromRGB(20,45,20), accent = Color3.fromRGB(60,255,60), glow = Color3.fromRGB(0,200,0)},
    Morado = {bg = Color3.fromRGB(35,20,55), accent = Color3.fromRGB(180,60,255), glow = Color3.fromRGB(120,0,200)},
    Rosa = {bg = Color3.fromRGB(55,20,45), accent = Color3.fromRGB(255,80,160), glow = Color3.fromRGB(200,0,120)}
}

-- ==================== 5. EFECTO LLUVIA ====================
local rainDrops = {}
local function createRainEffect(parentFrame)
    for i = 1, 60 do
        local drop = Instance.new("Frame")
        drop.Size = UDim2.new(0, 2, 0, 12)
        drop.Position = UDim2.new(math.random() * 1, 0, math.random() * 1, 0)
        drop.BackgroundColor3 = Color3.fromRGB(150, 200, 255)
        drop.BackgroundTransparency = math.random(30, 70) / 100
        drop.BorderSizePixel = 0
        drop.Parent = parentFrame
        
        local dropCorner = Instance.new("UICorner")
        dropCorner.CornerRadius = UDim.new(0, 2)
        dropCorner.Parent = drop
        
        table.insert(rainDrops, drop)
        
        task.spawn(function()
            while drop and drop.Parent do
                local startY = drop.Position.Y.Offset
                for y = startY, parentFrame.AbsoluteSize.Y + 20, 3 do
                    if not drop or not drop.Parent then break end
                    drop.Position = UDim2.new(drop.Position.X.Scale, drop.Position.X.Offset, 0, y)
                    task.wait(0.016)
                end
                drop.Position = UDim2.new(math.random() * 1, 0, 0, -20)
                task.wait(math.random(10, 40) / 100)
            end
        end)
    end
end

-- ==================== 6. GUI PRINCIPAL (ELEGANTE) ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaterHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Fondo con blur
local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 0.5
background.Parent = screenGui

-- Frame principal (glassmorphism)
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 380, 0, 600)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -300)
mainFrame.BackgroundColor3 = Colors[WaterHub.State.MenuColor].bg
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Efecto glass (blur interno)
local glassOverlay = Instance.new("Frame")
glassOverlay.Size = UDim2.new(1, 0, 1, 0)
glassOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
glassOverlay.BackgroundTransparency = 0.03
glassOverlay.Parent = mainFrame

-- Borde glow
local glowBorder = Instance.new("Frame")
glowBorder.Size = UDim2.new(1, 4, 1, 4)
glowBorder.Position = UDim2.new(0, -2, 0, -2)
glowBorder.BackgroundColor3 = Colors[WaterHub.State.MenuColor].glow
glowBorder.BackgroundTransparency = 0.7
glowBorder.BorderSizePixel = 0
glowBorder.Parent = mainFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local glowCorner = Instance.new("UICorner")
glowCorner.CornerRadius = UDim.new(0, 18)
glowCorner.Parent = glowBorder

-- Efecto lluvia dentro de la GUI
createRainEffect(mainFrame)

-- Top Bar (gradiente visual)
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 60)
topBar.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
topBar.BackgroundTransparency = 0.2
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 16)
topCorner.Parent = topBar

-- Título con ícono
local titleIcon = Instance.new("TextLabel")
titleIcon.Size = UDim2.new(0, 40, 1, 0)
titleIcon.Position = UDim2.new(0, 15, 0, 0)
titleIcon.Text = "💧"
titleIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
titleIcon.TextSize = 28
titleIcon.BackgroundTransparency = 1
titleIcon.Font = Enum.Font.GothamBold
titleIcon.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.6, 0, 1, 0)
title.Position = UDim2.new(0, 60, 0, 0)
title.Text = "WATER HUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 20
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

-- Subtítulo
local subTitle = Instance.new("TextLabel")
subTitle.Size = UDim2.new(0.6, 0, 0, 20)
subTitle.Position = UDim2.new(0, 60, 0, 30)
subTitle.Text = "BY: ABJadam"
subTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
subTitle.TextSize = 11
subTitle.Font = Enum.Font.Gotham
subTitle.BackgroundTransparency = 1
subTitle.TextXAlignment = Enum.TextXAlignment.Left
subTitle.TextTransparency = 0.3
subTitle.Parent = topBar

-- Versión
local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 60, 0, 20)
versionLabel.Position = UDim2.new(1, -70, 0, 40)
versionLabel.Text = "v5.3"
versionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
versionLabel.TextSize = 10
versionLabel.Font = Enum.Font.Gotham
versionLabel.BackgroundTransparency = 1
versionLabel.TextTransparency = 0.5
versionLabel.Parent = topBar

-- Botón minimizar (estilizado)
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 35, 0, 35)
minBtn.Position = UDim2.new(1, -45, 0, 12)
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.TextSize = 24
minBtn.Font = Enum.Font.GothamBold
minBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
minBtn.BackgroundTransparency = 0.2
minBtn.BorderSizePixel = 0
minBtn.Parent = topBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 8)
minCorner.Parent = minBtn

-- ScrollFrame para contenido
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -85)
scroll.Position = UDim2.new(0, 10, 0, 70)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scroll.Parent = mainFrame

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0, 8)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Parent = scroll

-- ==================== 7. SECCIÓN DE CATEGORÍAS ====================
local function createCategory(parent, titleText, icon)
    local categoryFrame = Instance.new("Frame")
    categoryFrame.Size = UDim2.new(1, 0, 0, 35)
    categoryFrame.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
    categoryFrame.BackgroundTransparency = 0.85
    categoryFrame.BorderSizePixel = 0
    categoryFrame.Parent = parent
    
    local catCorner = Instance.new("UICorner")
    catCorner.CornerRadius = UDim.new(0, 8)
    catCorner.Parent = categoryFrame
    
    local catIcon = Instance.new("TextLabel")
    catIcon.Size = UDim2.new(0, 30, 1, 0)
    catIcon.Text = icon
    catIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    catIcon.TextSize = 16
    catIcon.BackgroundTransparency = 1
    catIcon.Parent = categoryFrame
    
    local catLabel = Instance.new("TextLabel")
    catLabel.Size = UDim2.new(1, -35, 1, 0)
    catLabel.Position = UDim2.new(0, 35, 0, 0)
    catLabel.Text = titleText
    catLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    catLabel.TextSize = 13
    catLabel.Font = Enum.Font.GothamBold
    catLabel.BackgroundTransparency = 1
    catLabel.TextXAlignment = Enum.TextXAlignment.Left
    catLabel.Parent = categoryFrame
    
    return categoryFrame
end

-- ==================== 8. TOGGLE MODERNO ====================
local function createModernToggle(parent, text, stateKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.Parent = frame
    
    local toggleBtn = Instance.new("Frame")
    toggleBtn.Size = UDim2.new(0, 50, 0, 26)
    toggleBtn.Position = UDim2.new(1, -60, 0.5, -13)
    toggleBtn.BackgroundColor3 = WaterHub.State[stateKey] and Colors[WaterHub.State.MenuColor].accent or Color3.fromRGB(60, 65, 75)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBtn
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 20, 0, 20)
    toggleCircle.Position = WaterHub.State[stateKey] and UDim2.new(1, -24, 0, 3) or UDim2.new(0, 4, 0, 3)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Parent = toggleBtn
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = toggleBtn
    
    button.MouseButton1Click:Connect(function()
        WaterHub.State[stateKey] = not WaterHub.State[stateKey]
        local targetColor = WaterHub.State[stateKey] and Colors[WaterHub.State.MenuColor].accent or Color3.fromRGB(60, 65, 75)
        local targetPos = WaterHub.State[stateKey] and UDim2.new(1, -24, 0, 3) or UDim2.new(0, 4, 0, 3)
        TweenService:Create(toggleBtn, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(toggleCircle, TweenInfo.new(0.15), {Position = targetPos}):Play()
    end)
    
    return frame
end

-- ==================== 9. SLIDER MODERNO ====================
local function createModernSlider(parent, text, stateKey, minVal, maxVal, unit)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
    frame.BackgroundTransparency = 0.5
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 0, 25)
    label.Position = UDim2.new(0, 15, 0, 5)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.Parent = frame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.3, 0, 0, 25)
    valueLabel.Position = UDim2.new(0.7, 0, 0, 5)
    valueLabel.Text = tostring(WaterHub.State[stateKey]) .. unit
    valueLabel.TextColor3 = Colors[WaterHub.State.MenuColor].accent
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.Parent = frame
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(0.9, 0, 0, 4)
    sliderBg.Position = UDim2.new(0.05, 0, 0, 38)
    sliderBg.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame
    
    local sliderBgCorner = Instance.new("UICorner")
    sliderBgCorner.CornerRadius = UDim.new(0, 2)
    sliderBgCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    local percent = (WaterHub.State[stateKey] - minVal) / (maxVal - minVal)
    sliderFill.Size = UDim2.new(percent, 0, 1, 0)
    sliderFill.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(0, 2)
    sliderFillCorner.Parent = sliderFill
    
    local dragDetect = Instance.new("TextButton")
    dragDetect.Size = UDim2.new(0.9, 0, 0, 20)
    dragDetect.Position = UDim2.new(0.05, 0, 0, 30)
    dragDetect.BackgroundTransparency = 1
    dragDetect.Text = ""
    dragDetect.Parent = frame
    
    local dragging = false
    dragDetect.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = input.Position.X
            local sliderPos = sliderBg.AbsolutePosition.X
            local sliderWidth = sliderBg.AbsoluteSize.X
            local newPercent = math.clamp((mousePos - sliderPos) / sliderWidth, 0, 1)
            local newValue = math.floor(minVal + (newPercent * (maxVal - minVal)))
            WaterHub.State[stateKey] = newValue
            sliderFill.Size = UDim2.new(newPercent, 0, 1, 0)
            valueLabel.Text = tostring(newValue) .. unit
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return frame
end

-- ==================== 10. CONSTRUIR GUI COMPLETA ====================
-- Categoría: COMBATE
createCategory(scroll, "⚔️ COMBATE", "⚔️")
local combatOptions = {"Auto Duel","Auto Play","Auto Win","Auto Farm Wins","Aimbot","Silent Aim","Triggerbot","Godmode"}
for _, opt in ipairs(combatOptions) do
    local key = opt:gsub(" ",""):gsub("%-","")
    createModernToggle(scroll, opt, key)
end

-- Categoría: MOVIMIENTO
createCategory(scroll, "🏃 MOVIMIENTO", "🏃")
local moveOptions = {"Speed Hack","Jump Hack","Fly","Remove Animation","No Attack Anim","Fast Attack","Infinite Range"}
for _, opt in ipairs(moveOptions) do
    local key = opt:gsub(" ",""):gsub("%-","")
    createModernToggle(scroll, opt, key)
end

-- Sliders de velocidad y salto
createModernSlider(scroll, "Velocidad", "SpeedValue", 16, 200, "")
createModernSlider(scroll, "Salto", "JumpValue", 40, 300, "")

-- Categoría: ESP
createCategory(scroll, "👁️ ESP", "👁️")
local espOptions = {"ESP Players","ESP Brainrot","Visuals"}
for _, opt in ipairs(espOptions) do
    local key = opt:gsub(" ",""):gsub("%-","")
    createModernToggle(scroll, opt, key)
end

-- Categoría: AUTOMATIZACIÓN
createCategory(scroll, "🤖 AUTOMATIZACIÓN", "🤖")
local autoOptions = {"Auto Collect","Auto Leave","Auto Queue"}
for _, opt in ipairs(autoOptions) do
    local key = opt:gsub(" ",""):gsub("%-","")
    createModernToggle(scroll, opt, key)
end

-- Categoría: PROTECCIÓN
createCategory(scroll, "🛡️ PROTECCIÓN", "🛡️")
local protectOptions = {"Anti-Ragdoll","Anti-Stun","Anti-Slow","Anti Detection Delay"}
for _, opt in ipairs(protectOptions) do
    local key = opt:gsub(" ",""):gsub("%-","")
    createModernToggle(scroll, opt, key)
end

-- Selector de color
local colorFrame = Instance.new("Frame")
colorFrame.Size = UDim2.new(1, 0, 0, 50)
colorFrame.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
colorFrame.BackgroundTransparency = 0.5
colorFrame.Parent = scroll

local colorCorner = Instance.new("UICorner")
colorCorner.CornerRadius = UDim.new(0, 8)
colorCorner.Parent = colorFrame

local colorLabel = Instance.new("TextLabel")
colorLabel.Size = UDim2.new(0.4, 0, 1, 0)
colorLabel.Position = UDim2.new(0, 15, 0, 0)
colorLabel.Text = "🎨 Tema de color"
colorLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
colorLabel.TextXAlignment = Enum.TextXAlignment.Left
colorLabel.BackgroundTransparency = 1
colorLabel.Font = Enum.Font.Gotham
colorLabel.TextSize = 13
colorLabel.Parent = colorFrame

local colorPicker = Instance.new("TextButton")
colorPicker.Size = UDim2.new(0.35, 0, 0.6, 0)
colorPicker.Position = UDim2.new(0.6, 0, 0.2, 0)
colorPicker.Text = string.sub(WaterHub.State.MenuColor, 1, 1) .. string.sub(WaterHub.State.MenuColor, 2)
colorPicker.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
colorPicker.TextColor3 = Color3.fromRGB(255, 255, 255)
colorPicker.Font = Enum.Font.GothamBold
colorPicker.TextSize = 13
colorPicker.Parent = colorFrame

local colorPickerCorner = Instance.new("UICorner")
colorPickerCorner.CornerRadius = UDim.new(0, 6)
colorPickerCorner.Parent = colorPicker

colorPicker.MouseButton1Click:Connect(function()
    local order = {"Azul","Rojo","Verde","Morado","Rosa"}
    local idx = 1
    for i, c in ipairs(order) do if c == WaterHub.State.MenuColor then idx = i % #order + 1 break end end
    WaterHub.State.MenuColor = order[idx]
    colorPicker.Text = string.sub(WaterHub.State.MenuColor, 1, 1) .. string.sub(WaterHub.State.MenuColor, 2)
    colorPicker.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
    mainFrame.BackgroundColor3 = Colors[WaterHub.State.MenuColor].bg
    topBar.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
    glowBorder.BackgroundColor3 = Colors[WaterHub.State.MenuColor].glow
    
    for _, btn in pairs(scroll:GetDescendants()) do
        if btn:IsA("Frame") and btn.BackgroundColor3 == Colors[order[idx-1] or "Azul"].accent then
            TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent}):Play()
        end
    end
end)

-- Botón cerrar elegante
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.92, 0, 0, 45)
closeBtn.Position = UDim2.new(0.04, 0, 1, -52)
closeBtn.Text = "❌ CERRAR WATER HUB"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
closeBtn.BackgroundTransparency = 0.3
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    ClearESP()
    screenGui:Destroy()
end)

-- ==================== 11. DRAG PARA MÓVIL ====================
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

-- ==================== 12. MINIMIZADO ====================
local minimized = false
local floatingIcon = nil

local function createFloatingIcon()
    local iconGui = Instance.new("ScreenGui")
    iconGui.Name = "WaterHubIcon"
    iconGui.ResetOnSpawn = false
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 55, 0, 55)
    btn.Position = UDim2.new(0.85, 0, 0.85, 0)
    btn.Text = "💧"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 28
    btn.Font = Enum.Font.GothamBold
    btn.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
    btn.BackgroundTransparency = 0.15
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 14)
    btnCorner.Parent = btn
    
    local btnGlow = Instance.new("Frame")
    btnGlow.Size = UDim2.new(1, 6, 1, 6)
    btnGlow.Position = UDim2.new(0, -3, 0, -3)
    btnGlow.BackgroundColor3 = Colors[WaterHub.State.MenuColor].glow
    btnGlow.BackgroundTransparency = 0.6
    btnGlow.BorderSizePixel = 0
    btnGlow.Parent = btn
    
    local btnGlowCorner = Instance.new("UICorner")
    btnGlowCorner.CornerRadius = UDim.new(0, 17)
    btnGlowCorner.Parent = btnGlow
    
    btn.Parent = iconGui
    
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
    
    iconGui.Parent = CoreGui
    iconGui.Enabled = false
    return iconGui
end

minBtn.MouseButton1Click:Connect(function()
    minimized = true
    TweenService:Create(mainFrame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    TweenService:Create(topBar, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
    task.wait(0.2)
    screenGui.Enabled = false
    if not floatingIcon then
        floatingIcon = createFloatingIcon()
    else
        floatingIcon.Enabled = true
    end
end)

-- ==================== 13. LOOP PRINCIPAL ====================
RunService.RenderStepped:Connect(function()
    WaterHub.Enemies = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(WaterHub.Enemies, plr)
        end
    end
    
    -- ESP Players
    if WaterHub.State.ESPPlayers then
        for _, enemy in pairs(WaterHub.Enemies) do
            if enemy.Character and not enemy.Character:FindFirstChild("ESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "ESP_Highlight"
                hl.FillColor = Color3.fromRGB(255, 50, 50)
                hl.OutlineColor = Color3.fromRGB(255, 255, 100)
                hl.FillTransparency = 0.5
                hl.Parent = enemy.Character
                table.insert(WaterHub.ActiveHighlights, hl)
            end
        end
    elseif #WaterHub.ActiveHighlights > 0 then
        ClearESP()
    end
end)

-- Speed/Jump
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            if WaterHub.State.SpeedHack then hum.WalkSpeed = WaterHub.State.SpeedValue end
            if WaterHub.State.JumpHack then hum.JumpPower = WaterHub.State.JumpValue end
            if WaterHub.State.Godmode then hum.MaxHealth = math.huge; hum.Health = math.huge end
        end
    end
end)

-- ==================== 14. LIMPIEZA ====================
local function ClearESP()
    for _, highlight in pairs(WaterHub.ActiveHighlights) do
        pcall(function() highlight:Destroy() end)
    end
    WaterHub.ActiveHighlights = {}
end

Players.PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then ClearESP() end
end)

-- ==================== 15. INICIALIZAR ====================
screenGui.Parent = CoreGui

-- Animación de entrada
mainFrame.BackgroundTransparency = 1
TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.15}):Play()
TweenService:Create(topBar, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.2}):Play()

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("💧 WATER HUB v5.3 - GUI PROFESSIONAL")
print("👑 Creado por: ABJadam")
print("🎨 Diseño premium | Efecto lluvia | Glassmorphism")
print("🔓 Modo demo - Key desactivada")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")