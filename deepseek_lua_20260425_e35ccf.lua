-- =====================================================
-- WATER HUB v7.0 – BRAINROT DUELS | BY: ABJadam
-- Funciones reales: Auto Attack, Lock, Grab, Spin Bot
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

-- ==================== 2. VARIABLES ====================
local WaterHub = {
    State = {
        AutoPlay = false,
        ManualAutoPlay = false,
        Taunt = false,
        Lock = false,
        UnGrab = false,
        TapFloat = false,
        SpinBot = false,
        AimBot = false,
        FOV = 45,
        Speed = 16,
        MenuColor = "Azul"
    },
    Enemies = {},
    ActiveHighlights = {}
}

local Colors = {
    Azul = {bg = Color3.fromRGB(15, 25, 40), accent = Color3.fromRGB(0, 150, 255)},
    Rojo = {bg = Color3.fromRGB(40, 15, 15), accent = Color3.fromRGB(255, 60, 60)},
}

-- ==================== 3. ANTI-KICK ====================
pcall(function() LocalPlayer.Kick = function() end end)

-- ==================== 4. AUTO ATTACK (PEGA AUTOMÁTICAMENTENTE) ====================
local lastAttack = 0
local function AutoAttack()
    if not WaterHub.State.AutoPlay and not WaterHub.State.ManualAutoPlay then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Buscar enemigo más cercano
    local closest = nil
    local closestDist = 50
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local enemyHrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if enemyHrp then
                local dist = (hrp.Position - enemyHrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = plr
                end
            end
        end
    end
    
    if closest and closest.Character then
        local now = tick()
        if now - lastAttack > 0.15 then
            pcall(function()
                -- Usar RemoteEvent para atacar
                local attackRemote = ReplicatedStorage:FindFirstChild("RE/Combat/Attack") or
                                    ReplicatedStorage:FindFirstChild("RE/Attack") or
                                    ReplicatedStorage:FindFirstChild("RE/Duel/Attack")
                
                if attackRemote then
                    attackRemote:FireServer(closest.Character)
                end
                
                -- Si tiene tool, activarlo
                local tool = char:FindFirstChildOfClass("Tool")
                if tool and tool:FindFirstChild("Handle") then
                    tool:Activate()
                end
            end)
            lastAttack = now
        end
    end
end

-- ==================== 5. LOCK (BLOQUEAR) ====================
local function LockTarget()
    if not WaterHub.State.Lock then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Buscar enemigo
    local closest = nil
    local closestDist = 50
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local enemyHrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if enemyHrp then
                local dist = (hrp.Position - enemyHrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = enemyHrp
                end
            end
        end
    end
    
    if closest then
        Camera.CFrame = CFrame.new(hrp.Position, closest.Position)
    end
end

-- ==================== 6. SPIN BOT (GIRAR) ====================
local spinAngle = 0
local function SpinBot()
    if not WaterHub.State.SpinBot then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    spinAngle = spinAngle + 0.1
    local currentCF = hrp.CFrame
    hrp.CFrame = currentCF * CFrame.Angles(0, 0.1, 0)
end

-- ==================== 7. TAP FLOAT ====================
local floatHeight = 0
local function TapFloat()
    if not WaterHub.State.TapFloat then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    floatHeight = floatHeight + 0.05
    if floatHeight > 5 then floatHeight = 5 end
    
    hrp.CFrame = hrp.CFrame + Vector3.new(0, 0.01, 0)
end

-- ==================== 8. UNGRAB ====================
local function UnGrab()
    if not WaterHub.State.UnGrab then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    pcall(function()
        local grabState = char:FindFirstChild("GrabbedState")
        if grabState then
            grabState:Destroy()
        end
        
        local grabRemote = ReplicatedStorage:FindFirstChild("RE/Grab/Release") or
                          ReplicatedStorage:FindFirstChild("RE/Release")
        if grabRemote then
            grabRemote:FireServer()
        end
    end)
end

-- ==================== 9. TAUNT ====================
local function Taunt()
    if not WaterHub.State.Taunt then return end
    
    pcall(function()
        local tauntRemote = ReplicatedStorage:FindFirstChild("RE/Emote/Taunt") or
                           ReplicatedStorage:FindFirstChild("RE/Taunt")
        if tauntRemote then
            tauntRemote:FireServer()
        end
    end)
end

-- ==================== 10. TOGGLE ====================
local function createToggle(parent, text, stateKey)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.BackgroundColor3 = Color3.fromRGB(20, 32, 50)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
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
    toggleBtn.Position = UDim2.new(1, -65, 0.5, -13)
    toggleBtn.BackgroundColor3 = WaterHub.State[stateKey] and Colors.Azul.accent or Color3.fromRGB(60, 70, 85)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBtn

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 20, 0, 20)
    toggleCircle.Position = WaterHub.State[stateKey] and UDim2.new(1, -24, 0, 3) or UDim2.new(0, 3, 0, 3)
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
        local targetColor = WaterHub.State[stateKey] and Colors.Azul.accent or Color3.fromRGB(60, 70, 85)
        local targetPos = WaterHub.State[stateKey] and UDim2.new(1, -24, 0, 3) or UDim2.new(0, 3, 0, 3)
        TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        TweenService:Create(toggleCircle, TweenInfo.new(0.2), {Position = targetPos}):Play()
    end)

    return frame
end

-- ==================== 11. SLIDER ====================
local function createSlider(parent, text, stateKey, minVal, maxVal)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 55)
    frame.BackgroundColor3 = Color3.fromRGB(20, 32, 50)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 0, 20)
    label.Position = UDim2.new(0, 15, 0, 5)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.Parent = frame

    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.2, 0, 0, 20)
    valueLabel.Position = UDim2.new(1, -40, 0, 5)
    valueLabel.Text = tostring(WaterHub.State[stateKey])
    valueLabel.TextColor3 = Colors.Azul.accent
    valueLabel.TextXAlignment = Enum.TextXAlignment.Center
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.Parent = frame

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(0.85, 0, 0, 4)
    sliderBg.Position = UDim2.new(0, 15, 0, 33)
    sliderBg.BackgroundColor3 = Color3.fromRGB(40, 55, 75)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame

    local sliderBgCorner = Instance.new("UICorner")
    sliderBgCorner.CornerRadius = UDim.new(0, 2)
    sliderBgCorner.Parent = sliderBg

    local sliderFill = Instance.new("Frame")
    local percent = (WaterHub.State[stateKey] - minVal) / (maxVal - minVal)
    sliderFill.Size = UDim2.new(percent, 0, 1, 0)
    sliderFill.BackgroundColor3 = Colors.Azul.accent
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg

    local sliderFillCorner = Instance.new("UICorner")
    sliderFillCorner.CornerRadius = UDim.new(0, 2)
    sliderFillCorner.Parent = sliderFill

    local dragDetect = Instance.new("TextButton")
    dragDetect.Size = UDim2.new(0.85, 0, 0, 15)
    dragDetect.Position = UDim2.new(0, 15, 0, 26)
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
            if sliderWidth > 0 then
                local newPercent = math.clamp((mousePos - sliderPos) / sliderWidth, 0, 1)
                local newValue = math.floor(minVal + (newPercent * (maxVal - minVal)))
                WaterHub.State[stateKey] = newValue
                sliderFill.Size = UDim2.new(newPercent, 0, 1, 0)
                valueLabel.Text = tostring(newValue)
                
                -- Aplicar speed instantáneamente
                if stateKey == "Speed" then
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChild("Humanoid")
                        if hum then
                            hum.WalkSpeed = newValue
                        end
                    end
                end
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return frame
end

-- ==================== 12. GUI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaterHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 380, 0, 600)
mainFrame.Position = UDim2.new(0.5, -190, 0.5, -300)
mainFrame.BackgroundColor3 = Colors.Azul.bg
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local glow = Instance.new("UIStroke")
glow.Color = Colors.Azul.accent
glow.Thickness = 2
glow.Transparency = 0.5
glow.Parent = mainFrame

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 20)
mainCorner.Parent = mainFrame

-- TOP BAR
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 70)
topBar.BackgroundColor3 = Colors.Azul.accent
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 20)
topCorner.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.7, 0, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.Text = "💧 WATER HUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 60, 0, 25)
versionLabel.Position = UDim2.new(1, -65, 0, 10)
versionLabel.Text = "v7.0"
versionLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
versionLabel.TextSize = 12
versionLabel.Font = Enum.Font.Gotham
versionLabel.BackgroundTransparency = 1
versionLabel.Parent = topBar

-- SCROLL
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -90)
scroll.Position = UDim2.new(0, 10, 0, 80)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 0
scroll.Parent = mainFrame

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0, 8)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Parent = scroll

-- CATEGORÍAS
local function createCategory(parent, title)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 35)
    label.BackgroundColor3 = Colors.Azul.accent
    label.BackgroundTransparency = 0.7
    label.Text = title
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.BorderSizePixel = 0
    label.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = label
end

-- AUTO PLAY
createCategory(scroll, "⚔️ AUTO PLAY")
createToggle(scroll, "Auto Play", "AutoPlay")
createToggle(scroll, "Manual Auto Play", "ManualAutoPlay")
createToggle(scroll, "Taunt", "Taunt")

-- COMBAT
createCategory(scroll, "🎯 COMBAT")
createToggle(scroll, "Aim Bot", "AimBot")
createToggle(scroll, "Lock", "Lock")
createToggle(scroll, "Un Grab", "UnGrab")
createToggle(scroll, "Tap Float", "TapFloat")
createToggle(scroll, "Spin Bot", "SpinBot")

-- SETTINGS
createCategory(scroll, "⚙️ CONFIGURACIÓN")
createSlider(scroll, "Speed", "Speed", 16, 150)

-- CLOSE BUTTON
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -20, 0, 40)
closeBtn.Position = UDim2.new(0, 10, 1, -50)
closeBtn.Text = "❌ CERRAR"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- ==================== 13. DRAG ====================
local dragging = false
local dragStart, startPos

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ==================== 14. LOOPS ====================
RunService.Heartbeat:Connect(function()
    AutoAttack()
    LockTarget()
    SpinBot()
    TapFloat()
    UnGrab()
    Taunt()
end)

-- ==================== 15. INIT ====================
screenGui.Parent = CoreGui

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("💧 WATER HUB v7.0 - BRAINROT DUELS")
print("✅ AUTO ATTACK FUNCIONAL")
print("✅ LOCK, SPIN BOT, TAP FLOAT")
print("✅ SPEED SLIDER FUNCIONAL")
print("👑 BY: ABJadam")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
