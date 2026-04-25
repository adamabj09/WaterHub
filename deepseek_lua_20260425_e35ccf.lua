-- =====================================================
-- WATER HUB v6.0 – CHILLI HUB STYLE | BY: ABJadam
-- GUI Profesional con Aimbot real y Minimización Zoom
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
        Aimbot = false,
        AimbotSmooth = 0.25,
        Triggerbot = false,
        ESPPlayers = false,
        Godmode = false,
        AntiRagdoll = false,
        SpeedHack = false,
        JumpHack = false,
        InfiniteStamina = false,
        AutoCollect = false,
        SpeedValue = 50,
        JumpValue = 100,
        MenuColor = "Azul"
    },
    Enemies = {},
    ActiveHighlights = {},
    MinimizeAnim = false
}

local Colors = {
    Azul = {bg = Color3.fromRGB(15, 25, 40), accent = Color3.fromRGB(0, 150, 255), glow = Color3.fromRGB(0, 200, 255)},
    Rojo = {bg = Color3.fromRGB(40, 15, 15), accent = Color3.fromRGB(255, 60, 60), glow = Color3.fromRGB(255, 100, 100)},
}

-- ==================== 3. ANTI-KICK ====================
local function SuperAntiCheat()
    pcall(function() LocalPlayer.Kick = function() end end)
    local blacklist = {"Kick","Ban","Report","BAC","AntiCheat"}
    local function scan(obj)
        if not obj then return end
        pcall(function()
            for _, v in pairs(obj:GetChildren()) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    for _, bad in pairs(blacklist) do
                        if v.Name:find(bad) then
                            pcall(function() v.FireServer = function() end; v.OnClientEvent = function() end end)
                        end
                    end
                end
                scan(v)
            end
        end)
    end
    scan(ReplicatedStorage)
end
SuperAntiCheat()

-- ==================== 4. AIMBOT REAL (PEGA DIRECTO) ====================
local AimbotHandler = {}
local aimbotTarget = nil
local lastShot = 0

function AimbotHandler.GetClosestEnemy()
    local closest, closestDist = nil, 100
    for _, enemy in pairs(WaterHub.Enemies) do
        if enemy and enemy.Character then
            local hrp = enemy.Character:FindFirstChild("HumanoidRootPart")
            local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp and myHrp then
                local dist = (hrp.Position - myHrp.Position).Magnitude
                if dist < closestDist and enemy.Character:FindFirstChild("Humanoid") and enemy.Character:FindFirstChild("Humanoid").Health > 0 then
                    closestDist = dist
                    closest = enemy
                end
            end
        end
    end
    return closest
end

function AimbotHandler.HandleAimbot()
    if not WaterHub.State.Aimbot then 
        aimbotTarget = nil
        return 
    end
    
    aimbotTarget = AimbotHandler.GetClosestEnemy()
    if aimbotTarget and aimbotTarget.Character then
        local hrp = aimbotTarget.Character:FindFirstChild("HumanoidRootPart")
        local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and myHrp then
            -- Apuntar directamente a la cabeza
            local headPos = aimbotTarget.Character:FindFirstChild("Head")
            local targetPos = headPos and (headPos.Position + Vector3.new(0, 0.5, 0)) or hrp.Position
            
            local newCF = CFrame.lookAt(Camera.CFrame.Position, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(newCF, WaterHub.State.AimbotSmooth)
            
            -- Auto disparar
            if WaterHub.State.Triggerbot then
                local now = tick()
                if now - lastShot > 0.1 then
                    pcall(function()
                        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                        if tool then
                            tool:Activate()
                            lastShot = now
                        end
                    end)
                end
            end
        end
    end
end

-- ==================== 5. FUNCIONES ====================
local function ApplySpeedHack()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    if WaterHub.State.SpeedHack then
        hum.WalkSpeed = WaterHub.State.SpeedValue
    else
        hum.WalkSpeed = 16
    end
end

local function ApplyJumpHack()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    if WaterHub.State.JumpHack then
        hum.JumpPower = WaterHub.State.JumpValue
    else
        hum.JumpPower = 50
    end
end

local function ApplyGodmode()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    if WaterHub.State.Godmode then
        hum.MaxHealth = math.huge
        hum.Health = math.huge
    end
end

local function ApplyAntiRagdoll()
    if not WaterHub.State.AntiRagdoll then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum.Sit = false
    end
end

local function ApplyAutoCollect()
    if not WaterHub.State.AutoCollect then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    for _, item in pairs(Workspace:GetDescendants()) do
        if item.Name:find("Brainrot") or item.Name:find("Brain") then
            if (item.Position - hrp.Position).Magnitude < 50 then
                pcall(function() hrp.CFrame = CFrame.new(item.Position + Vector3.new(0, 3, 0)) end)
            end
        end
    end
end

-- ==================== 6. TOGGLE ====================
local function createToggle(parent, text, stateKey, onChanged)
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
        if onChanged then onChanged(WaterHub.State[stateKey]) end
    end)

    return frame
end

-- ==================== 7. SLIDER ====================
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

-- ==================== 8. GUI PRINCIPAL ====================
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

-- Borde glow
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

local titleIcon = Instance.new("TextLabel")
titleIcon.Size = UDim2.new(0, 50, 0, 50)
titleIcon.Position = UDim2.new(0, 15, 0, 10)
titleIcon.Text = "💧"
titleIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
titleIcon.TextSize = 40
titleIcon.BackgroundTransparency = 1
titleIcon.Font = Enum.Font.GothamBold
titleIcon.Parent = topBar

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0.5, 0, 1, 0)
title.Position = UDim2.new(0, 70, 0, 0)
title.Text = "WATER HUB"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.BackgroundTransparency = 1
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 60, 0, 25)
versionLabel.Position = UDim2.new(1, -65, 0, 10)
versionLabel.Text = "v6.0"
versionLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
versionLabel.TextSize = 12
versionLabel.Font = Enum.Font.Gotham
versionLabel.BackgroundTransparency = 1
versionLabel.Parent = topBar

-- MINIMIZE BUTTON
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 40, 0, 40)
minBtn.Position = UDim2.new(1, -45, 0, 15)
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.TextSize = 28
minBtn.Font = Enum.Font.GothamBold
minBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
minBtn.BorderSizePixel = 0
minBtn.Parent = topBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 10)
minCorner.Parent = minBtn

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
local function createCategory(parent, title, icon)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 35)
    label.BackgroundColor3 = Colors.Azul.accent
    label.BackgroundTransparency = 0.7
    label.Text = icon .. " " .. title
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.BorderSizePixel = 0
    label.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = label
end

-- COMBATE
createCategory(scroll, "COMBATE", "⚔️")
createToggle(scroll, "Aimbot", "Aimbot")
createSlider(scroll, "Precisión Aimbot", "AimbotSmooth", 0.05, 1)
createToggle(scroll, "Triggerbot", "Triggerbot")
createToggle(scroll, "ESP Players", "ESPPlayers")

-- MOVIMIENTO
createCategory(scroll, "MOVIMIENTO", "🏃")
createToggle(scroll, "Speed Hack", "SpeedHack")
createSlider(scroll, "Velocidad", "SpeedValue", 16, 150)
createToggle(scroll, "Jump Hack", "JumpHack")
createSlider(scroll, "Salto", "JumpValue", 50, 200)

-- PROTECCIÓN
createCategory(scroll, "PROTECCIÓN", "🛡️")
createToggle(scroll, "Godmode", "Godmode")
createToggle(scroll, "Anti-Ragdoll", "AntiRagdoll")

-- FARM
createCategory(scroll, "FARM", "🤖")
createToggle(scroll, "Auto Collect", "AutoCollect")

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

-- ==================== 9. MINIMIZE CON ZOOM ====================
local minimized = false
local floatingIcon = nil

local function createFloatingIcon()
    local iconGui = Instance.new("ScreenGui")
    iconGui.Name = "FloatingIcon"
    iconGui.ResetOnSpawn = false
    iconGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local iconBtn = Instance.new("TextButton")
    iconBtn.Name = "IconBtn"
    iconBtn.Size = UDim2.new(0, 70, 0, 70)
    iconBtn.Position = UDim2.new(0.5, -35, 0.5, -35)
    iconBtn.Text = "WH"
    iconBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconBtn.TextSize = 32
    iconBtn.Font = Enum.Font.GothamBold
    iconBtn.BackgroundColor3 = Colors.Azul.accent
    iconBtn.BorderSizePixel = 0
    iconBtn.Parent = iconGui

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 18)
    iconCorner.Parent = iconBtn

    local iconStroke = Instance.new("UIStroke")
    iconStroke.Color = Color3.fromRGB(0, 200, 255)
    iconStroke.Thickness = 2
    iconStroke.Transparency = 0.3
    iconStroke.Parent = iconBtn

    local dragIcon = false
    local dragStartIcon, startPosIcon

    iconBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragIcon = true
            dragStartIcon = input.Position
            startPosIcon = iconBtn.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragIcon and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStartIcon
            iconBtn.Position = UDim2.new(startPosIcon.X.Scale, startPosIcon.X.Offset + delta.X, startPosIcon.Y.Scale, startPosIcon.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragIcon = false
        end
    end)

    iconBtn.MouseButton1Click:Connect(function()
        if minimized then
            minimized = false
            
            -- ZOOM OUT (abrir)
            TweenService:Create(iconBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 0, 0, 0)
            }):Play()
            
            task.wait(0.15)
            iconGui.Enabled = false
            screenGui.Enabled = true
            
            -- ZOOM IN (abrir GUI)
            mainFrame.Size = UDim2.new(0, 50, 0, 50)
            mainFrame.Position = UDim2.new(0.5, -25, 0.5, -25)
            TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 380, 0, 600),
                Position = UDim2.new(0.5, -190, 0.5, -300)
            }):Play()
        end
    end)

    iconGui.Parent = CoreGui
    iconGui.Enabled = false
    return iconGui
end

minBtn.MouseButton1Click:Connect(function()
    if not minimized then
        minimized = true
        
        -- ZOOM OUT (cerrar GUI)
        TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 50, 0, 50),
            Position = UDim2.new(0.5, -25, 0.5, -25)
        }):Play()
        
        task.wait(0.2)
        screenGui.Enabled = false
        
        if not floatingIcon then
            floatingIcon = createFloatingIcon()
        end
        floatingIcon.Enabled = true
        
        -- ZOOM IN (icono aparece)
        local iconBtn = floatingIcon:FindFirstChild("IconBtn")
        if iconBtn then
            iconBtn.Size = UDim2.new(0, 0, 0, 0)
            TweenService:Create(iconBtn, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 70, 0, 70)
            }):Play()
        end
    end
end)

-- ==================== 10. DRAG ====================
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

-- ==================== 11. LOOPS ====================
RunService.RenderStepped:Connect(function()
    WaterHub.Enemies = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(WaterHub.Enemies, plr)
        end
    end

    AimbotHandler.HandleAimbot()

    if WaterHub.State.ESPPlayers then
        for _, enemy in pairs(WaterHub.Enemies) do
            if enemy.Character and not enemy.Character:FindFirstChild("ESP_Highlight") then
                local hl = Instance.new("Highlight")
                hl.Name = "ESP_Highlight"
                hl.FillColor = Color3.fromRGB(255, 50, 50)
                hl.OutlineColor = Color3.fromRGB(255, 255, 100)
                hl.FillTransparency = 0.3
                hl.Parent = enemy.Character
                table.insert(WaterHub.ActiveHighlights, hl)
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    ApplySpeedHack()
    ApplyJumpHack()
    ApplyGodmode()
    ApplyAntiRagdoll()
    ApplyAutoCollect()
end)

-- ==================== 12. INIT ====================
screenGui.Parent = CoreGui

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("💧 WATER HUB v6.0 - CHILLI HUB STYLE")
print("✅ GUI PROFESIONAL CON ZOOM")
print("✅ AIMBOT QUE PEGA DIRECTO")
print("✅ MINIMIZACIÓN CON ANIMACIÓN")
print("👑 BY: ABJadam")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
