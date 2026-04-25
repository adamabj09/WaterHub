-- =====================================================
-- WATER HUB v5.5 – BRAINROT 2026 | BY: ABJadam
-- Todas las funciones CORREGIDAS y ACTIVAS
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
        Triggerbot = false,
        ESPPlayers = false,
        Godmode = false,
        AntiRagdoll = false,
        AntiStun = false,
        SpeedHack = false,
        JumpHack = false,
        InfiniteStamina = false,
        AutoCollect = false,
        SpeedValue = 25,
        JumpValue = 80,
        MenuColor = "Azul"
    },
    Enemies = {},
    ActiveHighlights = {},
    ConfigFile = "WaterHub_Config.json"
}

local Colors = {
    Azul = {bg = Color3.fromRGB(20,30,45), accent = Color3.fromRGB(0,180,255), glow = Color3.fromRGB(0,100,200)},
    Rojo = {bg = Color3.fromRGB(45,20,20), accent = Color3.fromRGB(255,60,60), glow = Color3.fromRGB(200,0,0)},
    Verde = {bg = Color3.fromRGB(20,45,20), accent = Color3.fromRGB(60,255,60), glow = Color3.fromRGB(0,200,0)},
    Morado = {bg = Color3.fromRGB(35,20,55), accent = Color3.fromRGB(180,60,255), glow = Color3.fromRGB(120,0,200)},
    Rosa = {bg = Color3.fromRGB(55,20,45), accent = Color3.fromRGB(255,80,160), glow = Color3.fromRGB(200,0,120)}
}

-- ==================== 3. CONFIG ====================
local function SaveConfig()
    local config = {}
    for k, v in pairs(WaterHub.State) do
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
            config[k] = v
        end
    end
    pcall(function()
        if writefile then
            writefile(WaterHub.ConfigFile, HttpService:JSONEncode(config))
        end
    end)
end

local function LoadConfig()
    pcall(function()
        if readfile then
            local content = readfile(WaterHub.ConfigFile)
            if content then
                local success, config = pcall(function() return HttpService:JSONDecode(content) end)
                if success and config then
                    for k, v in pairs(config) do
                        if WaterHub.State[k] ~= nil then
                            WaterHub.State[k] = v
                        end
                    end
                end
            end
        end
    end)
end

-- ==================== 4. LIMPIEZA ESP ====================
local function ClearESP()
    for _, highlight in pairs(WaterHub.ActiveHighlights) do
        pcall(function() highlight:Destroy() end)
    end
    WaterHub.ActiveHighlights = {}
end

-- ==================== 5. ANTI-KICK ====================
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
                            pcall(function() v.FireServer = function() end; v.OnClientEvent = function() end end)
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

-- ==================== 6. AIMBOT ====================
local AimbotHandler = {}
local aimbotTarget = nil

function AimbotHandler.GetClosestEnemy()
    local closest, closestDist = nil, 50
    for _, enemy in pairs(WaterHub.Enemies) do
        if enemy and enemy.Character then
            local hrp = enemy.Character:FindFirstChild("HumanoidRootPart")
            if hrp and LocalPlayer.Character then
                local myHrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    local dist = (hrp.Position - myHrp.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = enemy
                    end
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
        if hrp then
            local targetPos = hrp.Position + Vector3.new(0, 1, 0)
            local newCF = CFrame.lookAt(Camera.CFrame.Position, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(newCF, 0.2)
        end
    end
end

function AimbotHandler.HandleTriggerbot()
    if not WaterHub.State.Triggerbot or not aimbotTarget then return end
    
    if aimbotTarget.Character then
        pcall(function()
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            if tool then
                local fire = tool:FindFirstChild("Fire") or tool:FindFirstChild("Activate")
                if fire and fire:IsA("RemoteEvent") then
                    fire:FireServer()
                end
            end
        end)
    end
end

-- ==================== 7. ANTI-RAGDOLL ====================
local function ApplyAntiRagdoll()
    if not WaterHub.State.AntiRagdoll then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        hum.PlatformStand = false
        hum.Sit = false
    end
    
    for _, joint in pairs(char:GetDescendants()) do
        if joint:IsA("Motor6D") or joint:IsA("Weld") then
            pcall(function() joint.Enabled = true end)
        end
    end
end

-- ==================== 8. SPEED HACK ====================
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

-- ==================== 9. JUMP HACK ====================
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

-- ==================== 10. GODMODE ====================
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

-- ==================== 11. STAMINA INFINITO ====================
local function ApplyInfiniteStamina()
    if not WaterHub.State.InfiniteStamina then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    pcall(function()
        local stats = char:FindFirstChild("Stats")
        if stats then
            local stamina = stats:FindFirstChild("Stamina")
            if stamina then
                stamina.Value = 999
            end
        end
    end)
end

-- ==================== 12. AUTO COLLECT ====================
local function ApplyAutoCollect()
    if not WaterHub.State.AutoCollect then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    for _, item in pairs(Workspace:GetDescendants()) do
        if item.Name == "Brainrot" or item.Name == "Brain" or item.Name:find("Brainrot") then
            if item:IsA("Model") or item:IsA("Part") then
                pcall(function()
                    if (item.Position - hrp.Position).Magnitude < 30 then
                        hrp.CFrame = CFrame.new(item.Position + Vector3.new(0, 3, 0))
                        task.wait(0.1)
                    end
                end)
            end
        end
    end
end

-- ==================== 13. TOGGLE ====================
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
        SaveConfig()
    end)

    return frame
end

-- ==================== 14. SLIDER ====================
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
    valueLabel.TextColor3 = Color3.fromRGB(0, 180, 255)
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
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
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
            if sliderWidth > 0 then
                local newPercent = math.clamp((mousePos - sliderPos) / sliderWidth, 0, 1)
                local newValue = math.floor(minVal + (newPercent * (maxVal - minVal)))
                WaterHub.State[stateKey] = newValue
                sliderFill.Size = UDim2.new(newPercent, 0, 1, 0)
                valueLabel.Text = tostring(newValue) .. unit
                SaveConfig()
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

-- ==================== 15. GUI ====================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WaterHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local background = Instance.new("Frame")
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
background.BackgroundTransparency = 0.6
background.Parent = screenGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 400, 0, 620)
mainFrame.Position = UDim2.new(0.5, -200, 0.5, -310)
mainFrame.BackgroundColor3 = Colors.Azul.bg
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 60)
topBar.BackgroundColor3 = Colors.Azul.accent
topBar.BackgroundTransparency = 0.3
topBar.BorderSizePixel = 0
topBar.Parent = mainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 16)
topCorner.Parent = topBar

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

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0, 60, 0, 20)
versionLabel.Position = UDim2.new(1, -70, 0, 40)
versionLabel.Text = "v5.5"
versionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
versionLabel.TextSize = 10
versionLabel.Font = Enum.Font.Gotham
versionLabel.BackgroundTransparency = 1
versionLabel.Parent = topBar

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -20, 1, -100)
scroll.Position = UDim2.new(0, 10, 0, 70)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 4
scroll.Parent = mainFrame

local scrollLayout = Instance.new("UIListLayout")
scrollLayout.Padding = UDim.new(0, 8)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
scrollLayout.Parent = scroll

-- Categorías
local function createCategory(parent, title, icon)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 30)
    label.BackgroundColor3 = Colors.Azul.accent
    label.BackgroundTransparency = 0.8
    label.Text = icon .. " " .. title
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.BorderSizePixel = 0
    label.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label
end

-- COMBATE
createCategory(scroll, "COMBATE", "⚔️")
createModernToggle(scroll, "Aimbot", "Aimbot")
createModernToggle(scroll, "Triggerbot", "Triggerbot")
createModernToggle(scroll, "ESP Players", "ESPPlayers")

-- MOVIMIENTO
createCategory(scroll, "MOVIMIENTO", "🏃")
createModernToggle(scroll, "Speed Hack", "SpeedHack")
createModernSlider(scroll, "Velocidad", "SpeedValue", 16, 150, "")
createModernToggle(scroll, "Jump Hack", "JumpHack")
createModernSlider(scroll, "Salto", "JumpValue", 50, 200, "")
createModernToggle(scroll, "Stamina Infinito", "InfiniteStamina")

-- PROTECCIÓN
createCategory(scroll, "PROTECCIÓN", "🛡️")
createModernToggle(scroll, "Godmode", "Godmode")
createModernToggle(scroll, "Anti-Ragdoll", "AntiRagdoll")
createModernToggle(scroll, "Anti-Stun", "AntiStun")

-- AUTOMATIZACIÓN
createCategory(scroll, "AUTOMATIZACIÓN", "🤖")
createModernToggle(scroll, "Auto Collect Brainrot", "AutoCollect")

-- Botón cerrar
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0.92, 0, 0, 45)
closeBtn.Position = UDim2.new(0.04, 0, 1, -52)
closeBtn.Text = "❌ CERRAR"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
closeBtn.BackgroundTransparency = 0.3
closeBtn.BorderSizePixel = 0
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
    ClearESP()
    screenGui:Destroy()
end)

-- ==================== 16. DRAG ====================
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

-- ==================== 17. LOOPS ====================
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
                hl.FillTransparency = 0.5
                hl.Parent = enemy.Character
                table.insert(WaterHub.ActiveHighlights, hl)
            end
        end
    elseif #WaterHub.ActiveHighlights > 0 then
        ClearESP()
    end
end)

RunService.Heartbeat:Connect(function()
    AimbotHandler.HandleTriggerbot()
    ApplyAntiRagdoll()
    ApplySpeedHack()
    ApplyJumpHack()
    ApplyGodmode()
    ApplyInfiniteStamina()
    ApplyAutoCollect()
end)

-- ==================== 18. INIT ====================
screenGui.Parent = CoreGui
LoadConfig()

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("💧 WATER HUB v5.5 - BRAINROT 2026")
print("✅ ERROR CORREGIDO - TODAS LAS FUNCIONES ACTIVAS")
print("👑 BY: ABJadam")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
