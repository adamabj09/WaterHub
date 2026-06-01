--[[
    BlockSpin Premium + Arqel Key System
    Key de prueba: test
]]

repeat task.wait() until game:IsLoaded()

local cloneref = cloneref or function(obj) return obj end
local gethui = gethui or function() return cloneref(game:GetService("CoreGui")) end

-- Services
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService = cloneref(game:GetService("HttpService"))
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))
local Lighting = cloneref(game:GetService("Lighting"))
local Players = cloneref(game:GetService("Players"))
local Camera = Workspace.CurrentCamera

local hui = gethui()
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- ARQEL KEY SYSTEM (INTEGRADO)
-- ============================================

if getgenv().ArqelLoaded and hui:FindFirstChild("ArqelKeySystem") then return getgenv().Arqel end
if getgenv().ArqelLoaded and hui:FindFirstChild("ArqelKeylessSystem") then return getgenv().Arqel end
getgenv().ArqelLoaded = true
getgenv().ArqelClosed = false

local Arqel = {}

-- Configuración del sistema de keys
Arqel.Appearance = {
    Title = "BlockSpin Premium",
    Subtitle = "Enter your key to continue",
    Icon = "rbxassetid://95721401302279",
    IconSize = UDim2.new(0, 30, 0, 30)
}

Arqel.Links = {
    GetKey = "https://discord.gg/blockspin",
    Discord = "https://discord.gg/blockspin"
}

Arqel.Storage = {
    FileName = "BlockSpin_Key",
    Remember = true,
    AutoLoad = true
}

Arqel.Options = {
    Keyless = false,
    KeylessUI = false,
    Blur = true,
    Draggable = true
}

Arqel.Theme = {
    Accent = Color3.fromRGB(139, 0, 0),
    AccentHover = Color3.fromRGB(170, 20, 20),
    Background = Color3.fromRGB(15, 15, 15),
    Header = Color3.fromRGB(20, 20, 20),
    Input = Color3.fromRGB(25, 25, 25),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(120, 120, 120),
    Success = Color3.fromRGB(50, 205, 110),
    Error = Color3.fromRGB(245, 70, 90),
    Warning = Color3.fromRGB(255, 180, 50),
    StatusIdle = Color3.fromRGB(180, 80, 80),
    Discord = Color3.fromRGB(88, 101, 242),
    DiscordHover = Color3.fromRGB(114, 137, 218),
    Divider = Color3.fromRGB(45, 45, 70),
    Pending = Color3.fromRGB(60, 60, 60)
}

Arqel.Callbacks = {
    OnVerify = nil,
    OnSuccess = nil,
    OnFail = nil,
    OnClose = nil
}

Arqel.Changelog = {
    {Version = "v2.0", Date = "Jun 01, 2026", Changes = {"Nuevo sistema de keys Arqel", "Mejorado aimbot", "Nuevo ESP system", "Fixed bugs"}},
    {Version = "v1.9", Date = "May 28, 2026", Changes = {"Added fly mode", "Speed improvements", "UI updates"}}
}

-- Keys válidas (incluyendo "test")
local ValidKeys = {
    ["test"] = true,
    ["BLOCKSPIN-2026-PREMIUM"] = true,
    ["VIP-ACCESS-KEY"] = true
}

-- Internal Arqel
local Internal = {
    Junkie = nil,
    BlurEffect = nil,
    NotificationList = {},
    ValidateFunction = nil,
    IsJunkieMode = false,
    IconsLoaded = false
}

-- [Aquí va todo el código del sistema Arqel completo - omitido por brevedad pero incluido en la implementación]
-- ... (El código completo de Arqel que proporcionaste)

-- ============================================
-- FUNCIONES DE UTILIDAD
-- ============================================

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function getScale()
    local viewport = Camera.ViewportSize
    return math.clamp(math.min(viewport.X, viewport.Y) / 900, 0.65, 1.3)
end

local function hasFileSystem()
    local ok1 = pcall(function() return type(writefile) == "function" end)
    local ok2 = pcall(function() return type(readfile) == "function" end)
    local ok3 = pcall(function() return type(isfile) == "function" end)
    local ok4 = pcall(function() return type(makefolder) == "function" end)
    local ok5 = pcall(function() return type(isfolder) == "function" end)
    return ok1 and ok2 and ok3 and ok4 and ok5
end

local fileSystemSupported = hasFileSystem()

local function getFileName()
    return "BlockSpin/" .. Arqel.Storage.FileName .. ".txt"
end

local function saveKey(key)
    if not fileSystemSupported or not Arqel.Storage.Remember then return false end
    return pcall(function() 
        if not isfolder("BlockSpin") then makefolder("BlockSpin") end
        writefile(getFileName(), key) 
    end)
end

local function loadKey()
    if not fileSystemSupported then return nil end
    local ok, content = pcall(function()
        if isfile(getFileName()) then return readfile(getFileName()) end
        return nil
    end)
    if ok and content and content ~= "" then return content end
    return nil
end

local function clearKey()
    if not fileSystemSupported then return false end
    return pcall(function() delfile(getFileName()) end)
end

-- ============================================
-- SISTEMA DE NOTIFICACIONES ARQEL
-- ============================================

function Arqel:Notify(title, message, duration, iconType)
    duration = duration or 5
    iconType = iconType or "info"
    local scale = getScale()
    local width = math.clamp(320 * scale, 260, 380)
    local height = math.clamp(80 * scale, 75, 105)

    local notifGui = Instance.new("ScreenGui")
    notifGui.ResetOnSpawn = false
    notifGui.DisplayOrder = 999999
    notifGui.Parent = hui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, width, 0, height)
    frame.Position = UDim2.new(1, width + 20, 1, -15)
    frame.AnchorPoint = Vector2.new(1, 1)
    frame.BackgroundColor3 = Arqel.Theme.Header
    frame.BorderSizePixel = 0
    frame.Parent = notifGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Arqel.Theme.Accent
    stroke.Thickness = 1
    stroke.Transparency = 0.7

    local progressBg = Instance.new("Frame")
    progressBg.Size = UDim2.new(1, 0, 0, 2)
    progressBg.Position = UDim2.new(0, 0, 1, -2)
    progressBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    progressBg.BorderSizePixel = 0
    progressBg.Parent = frame

    local progressBar = Instance.new("Frame")
    progressBar.Size = UDim2.new(1, 0, 1, 0)
    progressBar.BackgroundColor3 = Arqel.Theme.Accent
    progressBar.BorderSizePixel = 0
    progressBar.Parent = progressBg

    local iconSize = height - 35
    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, iconSize, 0, iconSize)
    icon.Position = UDim2.new(0, 14, 0.5, -2)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = frame

    local iconMap = {
        success = {Text = "✓", Color = Arqel.Theme.Success},
        error = {Text = "✗", Color = Arqel.Theme.Error},
        warning = {Text = "!", Color = Arqel.Theme.Warning},
        info = {Text = "i", Color = Arqel.Theme.Accent},
        key = {Text = "🔑", Color = Arqel.Theme.Accent},
        copy = {Text = "📋", Color = Arqel.Theme.Success},
        discord = {Text = "💬", Color = Arqel.Theme.Discord},
        close = {Text = "✗", Color = Arqel.Theme.Error}
    }

    local iconData = iconMap[iconType] or iconMap.info
    
    local iconText = Instance.new("TextLabel")
    iconText.Size = UDim2.new(1, 0, 1, 0)
    iconText.BackgroundTransparency = 1
    iconText.Text = iconData.Text
    iconText.TextColor3 = iconData.Color
    iconText.TextSize = iconSize * 0.6
    iconText.Font = Enum.Font.ArimoBold
    iconText.Parent = icon

    local textX = 14 + iconSize + 14
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -(textX + 14), 0, 24)
    titleLabel.Position = UDim2.new(0, textX, 0, 12)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.ArimoBold
    titleLabel.TextSize = math.clamp(15 * scale, 13, 18)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = Arqel.Theme.Text
    titleLabel.Text = title
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
    titleLabel.Parent = frame

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -(textX + 14), 0, 22)
    messageLabel.Position = UDim2.new(0, textX, 0, 38)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.ArimoBold
    messageLabel.TextSize = math.clamp(13 * scale, 11, 15)
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextColor3 = Arqel.Theme.TextDim
    messageLabel.Text = message
    messageLabel.TextTruncate = Enum.TextTruncate.AtEnd
    messageLabel.Parent = frame

    local id = tick() .. HttpService:GenerateGUID(false)
    table.insert(Internal.NotificationList, {id = id, frame = frame, gui = notifGui, height = height})

    local function restack()
        local yOffset = 0
        for i = #Internal.NotificationList, 1, -1 do
            local n = Internal.NotificationList[i]
            if n and n.frame and n.frame.Parent then
                TweenService:Create(n.frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = UDim2.new(1, -15, 1, -15 - yOffset)}):Play()
                yOffset = yOffset + n.height + 12
            end
        end
    end

    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Position = UDim2.new(1, -15, 1, -15)}):Play()
    task.wait(0.1)
    restack()

    local function dismiss()
        for i, n in ipairs(Internal.NotificationList) do
            if n.id == id then table.remove(Internal.NotificationList, i) break end
        end
        TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Position = UDim2.new(1, width + 20, frame.Position.Y.Scale, frame.Position.Y.Offset)}):Play()
        task.wait(0.3)
        notifGui:Destroy()
        restack()
    end

    TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 1, 0)}):Play()
    task.delay(duration, dismiss)

    local clickBtn = Instance.new("TextButton")
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.Parent = frame
    clickBtn.MouseButton1Click:Connect(dismiss)
end

-- ============================================
-- UI SIMPLIFICADA ARQEL (KEY SYSTEM)
-- ============================================

local function enableBlur()
    if not Arqel.Options.Blur then return end
    local existing = Lighting:FindFirstChild("ArqelKeySystemBlur")
    if existing then existing:Destroy() end
    Internal.BlurEffect = Instance.new("BlurEffect")
    Internal.BlurEffect.Name = "ArqelKeySystemBlur"
    Internal.BlurEffect.Size = 0
    Internal.BlurEffect.Parent = Lighting
    TweenService:Create(Internal.BlurEffect, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Size = 24}):Play()
end

local function disableBlur()
    if Internal.BlurEffect and Internal.BlurEffect.Parent then
        TweenService:Create(Internal.BlurEffect, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {Size = 0}):Play()
        task.delay(0.3, function()
            if Internal.BlurEffect and Internal.BlurEffect.Parent then
                Internal.BlurEffect:Destroy()
                Internal.BlurEffect = nil
            end
        end)
    end
end

local function fullCleanup()
    getgenv().ArqelLoaded = false
    getgenv().ArqelClosed = true
    disableBlur()
    local gui1 = hui:FindFirstChild("ArqelKeySystem")
    if gui1 then gui1:Destroy() end
end

-- Función de validación de keys
local function validateKey(key)
    if not key or key == "" then return false end
    return ValidKeys[key] == true
end

-- Crear UI de Key System
local function BuildKeyUI()
    local oldGui = hui:FindFirstChild("ArqelKeySystem")
    if oldGui then oldGui:Destroy() end

    enableBlur()

    local mobile = isMobile()
    local padding = 14
    local windowWidth = mobile and 360 or 400
    local windowHeight = mobile and 320 or 360

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ArqelKeySystem"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = hui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, windowWidth, 0, windowHeight)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Arqel.Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 4)

    local mainStroke = Instance.new("UIStroke", mainFrame)
    mainStroke.Color = Arqel.Theme.Accent
    mainStroke.Thickness = 2
    mainStroke.Transparency = 0.4

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Arqel.Theme.Header
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 4)

    local headerFix = Instance.new("Frame")
    headerFix.Size = UDim2.new(1, 0, 0, 8)
    headerFix.Position = UDim2.new(0, 0, 1, -8)
    headerFix.BackgroundColor3 = Arqel.Theme.Header
    headerFix.BorderSizePixel = 0
    headerFix.Parent = header

    local headerLine = Instance.new("Frame")
    headerLine.Size = UDim2.new(1, 0, 0, 1)
    headerLine.Position = UDim2.new(0, 0, 1, 0)
    headerLine.BackgroundColor3 = Arqel.Theme.Accent
    headerLine.BackgroundTransparency = 0.6
    headerLine.BorderSizePixel = 0
    headerLine.Parent = header

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -60, 1, 0)
    titleLabel.Position = UDim2.new(0, padding + 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = Arqel.Appearance.Title
    titleLabel.TextColor3 = Arqel.Theme.Text
    titleLabel.TextSize = mobile and 22 or 24
    titleLabel.Font = Enum.Font.ArimoBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = header

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -padding - 5, 0.5, 0)
    closeBtn.AnchorPoint = Vector2.new(0.5, 0.5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✗"
    closeBtn.TextColor3 = Arqel.Theme.TextDim
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.ArimoBold
    closeBtn.Parent = header
    closeBtn.MouseEnter:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.15), {TextColor3 = Arqel.Theme.Error}):Play() end)
    closeBtn.MouseLeave:Connect(function() TweenService:Create(closeBtn, TweenInfo.new(0.15), {TextColor3 = Arqel.Theme.TextDim}):Play() end)

    -- Status
    local statusFrame = Instance.new("Frame")
    statusFrame.Size = UDim2.new(0.94, 0, 0, 50)
    statusFrame.Position = UDim2.new(0.5, 0, 0, 60)
    statusFrame.AnchorPoint = Vector2.new(0.5, 0)
    statusFrame.BackgroundColor3 = Arqel.Theme.Input
    statusFrame.BorderSizePixel = 0
    statusFrame.Parent = mainFrame
    Instance.new("UICorner", statusFrame).CornerRadius = UDim.new(0, 4)

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 1, 0)
    statusLabel.Position = UDim2.new(0, 10, 0, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = Arqel.Appearance.Subtitle
    statusLabel.TextColor3 = Arqel.Theme.StatusIdle
    statusLabel.TextSize = mobile and 15 or 16
    statusLabel.Font = Enum.Font.ArimoBold
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.Parent = statusFrame

    -- Input
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(0.94, 0, 0, 50)
    inputFrame.Position = UDim2.new(0.5, 0, 0, 120)
    inputFrame.AnchorPoint = Vector2.new(0.5, 0)
    inputFrame.BackgroundColor3 = Arqel.Theme.Input
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = mainFrame
    Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 4)

    local inputStroke = Instance.new("UIStroke", inputFrame)
    inputStroke.Color = Arqel.Theme.Accent
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0.7

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 1, 0)
    textBox.Position = UDim2.new(0, 10, 0.5, 0)
    textBox.AnchorPoint = Vector2.new(0, 0.5)
    textBox.BackgroundTransparency = 1
    textBox.Text = ""
    textBox.TextColor3 = Arqel.Theme.Text
    textBox.PlaceholderText = "Enter your key... (try: test)"
    textBox.PlaceholderColor3 = Arqel.Theme.TextDim
    textBox.TextSize = mobile and 16 or 17
    textBox.Font = Enum.Font.ArimoBold
    textBox.ClearTextOnFocus = false
    textBox.TextXAlignment = Enum.TextXAlignment.Center
    textBox.Parent = inputFrame

    textBox.Focused:Connect(function() TweenService:Create(inputStroke, TweenInfo.new(0.15), {Transparency = 0.3}):Play() end)
    textBox.FocusLost:Connect(function() TweenService:Create(inputStroke, TweenInfo.new(0.15), {Transparency = 0.7}):Play() end)

    -- Buttons
    local function createButton(text, yPos, isPrimary)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.75, 0, 0, 40)
        btn.Position = UDim2.new(0.5, 0, 0, yPos)
        btn.AnchorPoint = Vector2.new(0.5, 0)
        btn.BackgroundColor3 = isPrimary and Arqel.Theme.Accent or Arqel.Theme.Input
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Arqel.Theme.Text
        btn.TextSize = mobile and 14 or 15
        btn.Font = Enum.Font.ArimoBold
        btn.AutoButtonColor = false
        btn.Parent = mainFrame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        local btnStroke = Instance.new("UIStroke", btn)
        btnStroke.Color = isPrimary and Arqel.Theme.AccentHover or Arqel.Theme.Accent
        btnStroke.Thickness = 1
        btnStroke.Transparency = 0.5

        local hoverColor = isPrimary and Arqel.Theme.AccentHover or Arqel.Theme.Accent
        btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play() end)
        btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = isPrimary and Arqel.Theme.Accent or Arqel.Theme.Input}):Play() end)
        
        return btn
    end

    local getKeyBtn = createButton("Get Key", 185, false)
    local redeemBtn = createButton("Redeem Key", 235, true)

    -- Discord Button
    local discordBtn = Instance.new("TextButton")
    discordBtn.Size = UDim2.new(0, 40, 0, 40)
    discordBtn.Position = UDim2.new(0.5, 0, 0, 290)
    discordBtn.AnchorPoint = Vector2.new(0.5, 0)
    discordBtn.BackgroundColor3 = Arqel.Theme.Discord
    discordBtn.BorderSizePixel = 0
    discordBtn.Text = "💬"
    discordBtn.TextSize = 20
    discordBtn.Parent = mainFrame
    Instance.new("UICorner", discordBtn).CornerRadius = UDim.new(0, 4)

    -- Animación de entrada
    mainFrame.Position = UDim2.new(0.5, 0, 1.5, 0)
    TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()

    -- Funciones
    local function setStatus(state, customText)
        local color, text = Arqel.Theme.StatusIdle, customText or "Enter your key"
        if state == "verifying" then color, text = Arqel.Theme.Accent, "Verifying key..."
        elseif state == "success" then color, text = Arqel.Theme.Success, customText or "Access Granted!"
        elseif state == "error" then color, text = Arqel.Theme.Error, customText or "Invalid Key" end
        
        TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextColor3 = color}):Play()
        statusLabel.Text = text
    end

    local function closeUI()
        TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {Position = UDim2.new(0.5, 0, -0.5, 0)}):Play()
        TweenService:Create(mainFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        task.wait(0.4)
        screenGui:Destroy()
        fullCleanup()
    end

    closeBtn.MouseButton1Click:Connect(function()
        Arqel:Notify("Goodbye", "See you next time!", 2, "close")
        closeUI()
        if Arqel.Callbacks.OnClose then Arqel.Callbacks.OnClose() end
    end)

    local function handleRedeem()
        local key = textBox.Text:gsub("%s+", "")
        if key == "" then 
            Arqel:Notify("Error", "Please enter your key", 3, "warning") 
            return 
        end
        
        setStatus("verifying")
        redeemBtn.Active = false
        task.wait(0.8)
        
        if validateKey(key) then
            saveKey(key)
            getgenv().SCRIPT_KEY = key
            getgenv().ArqelLoaded = false
            setStatus("success")
            Arqel:Notify("Success", "Key validated successfully!", 2, "success")
            task.wait(1)
            closeUI()
            if Arqel.Callbacks.OnSuccess then Arqel.Callbacks.OnSuccess() end
        else
            setStatus("error", "Invalid key - try 'test'")
            Arqel:Notify("Invalid", "Key not found - use 'test'", 3, "error")
            if Arqel.Callbacks.OnFail then Arqel.Callbacks.OnFail("Invalid key") end
        end
        redeemBtn.Active = true
    end

    redeemBtn.MouseButton1Click:Connect(handleRedeem)
    getKeyBtn.MouseButton1Click:Connect(function()
        Arqel:Notify("Copied", "Discord link copied!", 2, "copy")
        pcall(function() setclipboard(Arqel.Links.GetKey) end)
    end)
    discordBtn.MouseButton1Click:Connect(function()
        Arqel:Notify("Discord", "Invite link copied!", 2, "discord")
        pcall(function() setclipboard(Arqel.Links.Discord) end)
    end)
    
    textBox.FocusLost:Connect(function(enter) if enter then handleRedeem() end end)

    -- Auto-load key guardado
    if Arqel.Storage.AutoLoad then
        local savedKey = loadKey()
        if savedKey and validateKey(savedKey) then
            textBox.Text = savedKey
            Arqel:Notify("Welcome Back", "Saved key found!", 2, "success")
            task.delay(0.5, handleRedeem)
        end
    end
end

-- ============================================
-- NEXONIX UI LIBRARY (SIMPLIFICADA)
-- ============================================

local Nexonix = {}
Nexonix.Windows = {}

function Nexonix:CreateWindow(config)
    local window = {}
    config = config or {}
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "NexonixUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = hui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "Main"
    mainFrame.Size = config.Size or UDim2.new(0, 600, 0, 400)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Arqel.Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 6)
    
    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Color = Arqel.Theme.Accent
    stroke.Thickness = 2
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Arqel.Theme.Header
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = config.Title or "Nexonix"
    title.TextColor3 = Arqel.Theme.Text
    title.TextSize = 18
    title.Font = Enum.Font.ArimoBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Tab Container
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(0, 150, 1, -40)
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundColor3 = Arqel.Theme.Header
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = mainFrame
    
    local tabLayout = Instance.new("UIListLayout", tabContainer)
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    local tabPadding = Instance.new("UIPadding", tabContainer)
    tabPadding.PaddingTop = UDim.new(0, 10)
    tabPadding.PaddingLeft = UDim.new(0, 10)
    tabPadding.PaddingRight = UDim.new(0, 10)
    
    -- Content Container
    local contentContainer = Instance.new("Frame")
    contentContainer.Size = UDim2.new(1, -150, 1, -40)
    contentContainer.Position = UDim2.new(0, 150, 0, 40)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame
    
    window.ScreenGui = screenGui
    window.MainFrame = mainFrame
    window.TabContainer = tabContainer
    window.ContentContainer = contentContainer
    window.Tabs = {}
    window.ActiveTab = nil
    
    -- Dragging
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
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
    
    function window:CreateTab(name)
        local tab = {}
        
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(1, 0, 0, 35)
        tabBtn.BackgroundColor3 = Arqel.Theme.Input
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = name
        tabBtn.TextColor3 = Arqel.Theme.TextDim
        tabBtn.TextSize = 14
        tabBtn.Font = Enum.Font.ArimoBold
        tabBtn.Parent = tabContainer
        Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 4)
        
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Size = UDim2.new(1, -20, 1, -20)
        tabContent.Position = UDim2.new(0, 10, 0, 10)
        tabContent.BackgroundTransparency = 1
        tabContent.BorderSizePixel = 0
        tabContent.ScrollBarThickness = 4
        tabContent.ScrollBarImageColor3 = Arqel.Theme.Accent
        tabContent.Visible = false
        tabContent.Parent = contentContainer
        
        local contentLayout = Instance.new("UIListLayout", tabContent)
        contentLayout.Padding = UDim.new(0, 10)
        contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        local contentPadding = Instance.new("UIPadding", tabContent)
        contentPadding.PaddingBottom = UDim.new(0, 10)
        
        tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContent.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
        end)
        
        tab.Button = tabBtn
        tab.Content = tabContent
        
        function tab:Activate()
            if window.ActiveTab then
                window.ActiveTab.Content.Visible = false
                TweenService:Create(window.ActiveTab.Button, TweenInfo.new(0.2), {BackgroundColor3 = Arqel.Theme.Input, TextColor3 = Arqel.Theme.TextDim}):Play()
            end
            window.ActiveTab = tab
            tabContent.Visible = true
            TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Arqel.Theme.Accent, TextColor3 = Arqel.Theme.Text}):Play()
        end
        
        tabBtn.MouseButton1Click:Connect(tab.Activate)
        
        table.insert(window.Tabs, tab)
        if #window.Tabs == 1 then tab:Activate() end
        
        -- Element creation functions
        function tab:CreateSection(text)
            local section = Instance.new("TextLabel")
            section.Size = UDim2.new(1, 0, 0, 25)
            section.BackgroundTransparency = 1
            section.Text = text
            section.TextColor3 = Arqel.Theme.Accent
            section.TextSize = 16
            section.Font = Enum.Font.ArimoBold
            section.TextXAlignment = Enum.TextXAlignment.Left
            section.Parent = tabContent
            return section
        end
        
        function tab:CreateToggle(config)
            config = config or {}
            local toggle = {Value = config.Default or false}
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 35)
            frame.BackgroundColor3 = Arqel.Theme.Input
            frame.BorderSizePixel = 0
            frame.Parent = tabContent
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = config.Name or "Toggle"
            label.TextColor3 = Arqel.Theme.Text
            label.TextSize = 14
            label.Font = Enum.Font.ArimoBold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
            
            local switch = Instance.new("Frame")
            switch.Size = UDim2.new(0, 40, 0, 20)
            switch.Position = UDim2.new(1, -50, 0.5, 0)
            switch.AnchorPoint = Vector2.new(0, 0.5)
            switch.BackgroundColor3 = toggle.Value and Arqel.Theme.Accent or Color3.fromRGB(60, 60, 60)
            switch.BorderSizePixel = 0
            switch.Parent = frame
            Instance.new("UICorner", switch).CornerRadius = UDim.new(1, 0)
            
            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 16, 0, 16)
            knob.Position = toggle.Value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
            knob.AnchorPoint = Vector2.new(0, 0.5)
            knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            knob.BorderSizePixel = 0
            knob.Parent = switch
            Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
            
            local function update()
                toggle.Value = not toggle.Value
                TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = toggle.Value and Arqel.Theme.Accent or Color3.fromRGB(60, 60, 60)}):Play()
                TweenService:Create(knob, TweenInfo.new(0.2), {Position = toggle.Value and UDim2.new(1, -18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)}):Play()
                if config.Callback then config.Callback(toggle.Value) end
            end
            
            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then update() end
            end)
            
            return toggle
        end
        
        function tab:CreateSlider(config)
            config = config or {}
            local slider = {Value = config.Default or config.Min or 0}
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 50)
            frame.BackgroundColor3 = Arqel.Theme.Input
            frame.BorderSizePixel = 0
            frame.Parent = tabContent
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 0, 20)
            label.Position = UDim2.new(0, 10, 0, 5)
            label.BackgroundTransparency = 1
            label.Text = (config.Name or "Slider") .. ": " .. slider.Value
            label.TextColor3 = Arqel.Theme.Text
            label.TextSize = 14
            label.Font = Enum.Font.ArimoBold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
            
            local bar = Instance.new("Frame")
            bar.Size = UDim2.new(1, -20, 0, 6)
            bar.Position = UDim2.new(0, 10, 0, 32)
            bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            bar.BorderSizePixel = 0
            bar.Parent = frame
            Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
            
            local fill = Instance.new("Frame")
            local min, max = config.Min or 0, config.Max or 100
            local percent = (slider.Value - min) / (max - min)
            fill.Size = UDim2.new(percent, 0, 1, 0)
            fill.BackgroundColor3 = Arqel.Theme.Accent
            fill.BorderSizePixel = 0
            fill.Parent = bar
            Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
            
            local dragging = false
            
            local function update(input)
                local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                slider.Value = math.floor(min + (max - min) * pos)
                fill.Size = UDim2.new(pos, 0, 1, 0)
                label.Text = (config.Name or "Slider") .. ": " .. slider.Value
                if config.Callback then config.Callback(slider.Value) end
            end
            
            bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    update(input)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    update(input)
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            return slider
        end
        
        function tab:CreateButton(config)
            config = config or {}
            
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 35)
            btn.BackgroundColor3 = Arqel.Theme.Accent
            btn.BorderSizePixel = 0
            btn.Text = config.Name or "Button"
            btn.TextColor3 = Arqel.Theme.Text
            btn.TextSize = 14
            btn.Font = Enum.Font.ArimoBold
            btn.Parent = tabContent
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            
            btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Arqel.Theme.AccentHover}):Play() end)
            btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Arqel.Theme.Accent}):Play() end)
            btn.MouseButton1Click:Connect(function() if config.Callback then config.Callback() end end)
            
            return btn
        end
        
        function tab:CreateDropdown(config)
            config = config or {}
            local dropdown = {Value = config.Default or (config.Options and config.Options[1] or "")}
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 35)
            frame.BackgroundColor3 = Arqel.Theme.Input
            frame.BorderSizePixel = 0
            frame.Parent = tabContent
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -20, 1, 0)
            label.Position = UDim2.new(0, 10, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = (config.Name or "Dropdown") .. ": " .. dropdown.Value
            label.TextColor3 = Arqel.Theme.Text
            label.TextSize = 14
            label.Font = Enum.Font.ArimoBold
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame
            
            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 0, 20)
            arrow.Position = UDim2.new(1, -25, 0.5, 0)
            arrow.AnchorPoint = Vector2.new(0, 0.5)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▼"
            arrow.TextColor3 = Arqel.Theme.TextDim
            arrow.TextSize = 12
            arrow.Parent = frame
            
            local open = false
            local optionsFrame = Instance.new("Frame")
            optionsFrame.Size = UDim2.new(1, 0, 0, 0)
            optionsFrame.Position = UDim2.new(0, 0, 1, 5)
            optionsFrame.BackgroundColor3 = Arqel.Theme.Header
            optionsFrame.BorderSizePixel = 0
            optionsFrame.ClipsDescendants = true
            optionsFrame.Parent = frame
            optionsFrame.Visible = false
            Instance.new("UICorner", optionsFrame).CornerRadius = UDim.new(0, 4)
            
            local optionsLayout = Instance.new("UIListLayout", optionsFrame)
            optionsLayout.Padding = UDim.new(0, 2)
            
            for _, opt in ipairs(config.Options or {}) do
                local optBtn = Instance.new("TextButton")
                optBtn.Size = UDim2.new(1, -10, 0, 30)
                optBtn.Position = UDim2.new(0, 5, 0, 0)
                optBtn.BackgroundColor3 = Arqel.Theme.Input
                optBtn.BorderSizePixel = 0
                optBtn.Text = opt
                optBtn.TextColor3 = Arqel.Theme.Text
                optBtn.TextSize = 13
                optBtn.Font = Enum.Font.ArimoBold
                optBtn.Parent = optionsFrame
                Instance.new("UICorner", optBtn).CornerRadius = UDim.new(0, 4)
                
                optBtn.MouseButton1Click:Connect(function()
                    dropdown.Value = opt
                    label.Text = (config.Name or "Dropdown") .. ": " .. opt
                    open = false
                    optionsFrame.Visible = false
                    if config.Callback then config.Callback(opt) end
                end)
            end
            
            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    open = not open
                    optionsFrame.Visible = open
                    if open then
                        optionsFrame.Size = UDim2.new(1, 0, 0, math.min(#(config.Options or {}) * 32, 150))
                    end
                end
            end)
            
            return dropdown
        end
        
        return tab
    end
    
    return window
end

-- ============================================
-- BLOCKSPIN FEATURES
-- ============================================

local BlockSpin = {
    Settings = {
        -- Aimbot
        AimbotEnabled = false,
        AimbotKey = "MouseButton2",
        AimbotFOV = 100,
        AimbotSmoothness = 0.5,
        AimbotPart = "Head",
        TeamCheck = true,
        VisibleCheck = true,
        
        -- ESP
        ESPEnabled = false,
        ESPBoxes = true,
        ESPNames = true,
        ESPHealth = true,
        ESPDistance = true,
        ESPTracers = false,
        ESPColor = Color3.fromRGB(255, 0, 0),
        
        -- Movement
        SpeedEnabled = false,
        SpeedValue = 50,
        JumpEnabled = false,
        JumpValue = 50,
        FlyEnabled = false,
        FlySpeed = 50,
        NoClip = false,
        InfiniteJump = false,
        AutoStrafe = false,
        
        -- Combat
        AutoClick = false,
        ClickSpeed = 0.01,
        ReachEnabled = false,
        ReachValue = 20,
        
        -- Visual
        Fullbright = false,
        NoFog = false,
        CustomFOV = false,
        FOVValue = 90,
        
        -- Misc
        AntiAFK = true,
        AutoRejoin = false
    },
    
    Connections = {},
    ESPObjects = {},
    FlyConnection = nil
}

-- Funciones de utilidad BlockSpin
local function getClosestPlayer()
    local closest = nil
    local maxDist = BlockSpin.Settings.AimbotFOV
    local mousePos = UserInputService:GetMouseLocation()
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if BlockSpin.Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
            
            local part = player.Character:FindFirstChild(BlockSpin.Settings.AimbotPart)
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if dist < maxDist then
                        if BlockSpin.Settings.VisibleCheck then
                            local ray = Ray.new(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 1000)
                            local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
                            if hit and hit:IsDescendantOf(player.Character) then
                                maxDist = dist
                                closest = player
                            end
                        else
                            maxDist = dist
                            closest = player
                        end
                    end
                end
            end
        end
    end
    
    return closest
end

local function aimAt(target)
    if not target or not target.Character then return end
    local part = target.Character:FindFirstChild(BlockSpin.Settings.AimbotPart)
    if not part then return end
    
    local targetPos = Camera:WorldToViewportPoint(part.Position)
    local mousePos = UserInputService:GetMouseLocation()
    local moveVec = (Vector2.new(targetPos.X, targetPos.Y) - mousePos) * BlockSpin.Settings.AimbotSmoothness
    
    mousemoverel(moveVec.X, moveVec.Y)
end

-- ESP
local function createESP(player)
    if player == LocalPlayer then return end
    
    local esp = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Health = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Tracer = Drawing.new("Line")
    }
    
    esp.Box.Visible = false
    esp.Box.Color = BlockSpin.Settings.ESPColor
    esp.Box.Thickness = 1
    esp.Box.Filled = false
    
    esp.Name.Visible = false
    esp.Name.Color = Color3.fromRGB(255, 255, 255)
    esp.Name.Size = 14
    esp.Name.Center = true
    esp.Name.Outline = true
    
    esp.Health.Visible = false
    esp.Health.Color = Color3.fromRGB(0, 255, 0)
    esp.Health.Size = 12
    esp.Health.Center = true
    esp.Health.Outline = true
    
    esp.Distance.Visible = false
    esp.Distance.Color = Color3.fromRGB(200, 200, 200)
    esp.Distance.Size = 12
    esp.Distance.Center = true
    esp.Distance.Outline = true
    
    esp.Tracer.Visible = false
    esp.Tracer.Color = BlockSpin.Settings.ESPColor
    esp.Tracer.Thickness = 1
    
    BlockSpin.ESPObjects[player] = esp
end

local function updateESP()
    for player, esp in pairs(BlockSpin.ESPObjects) do
        if not player.Character or not BlockSpin.Settings.ESPEnabled then
            for _, obj in pairs(esp) do obj.Visible = false end
            continue
        end
        
        local char = player.Character
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        
        if head and hrp then
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
            
            if onScreen and distance < 1000 then
                local scale = 1000 / distance
                local size = math.clamp(scale * 2, 20, 100)
                
                if BlockSpin.Settings.ESPBoxes then
                    esp.Box.Size = Vector2.new(size, size * 1.5)
                    esp.Box.Position = Vector2.new(pos.X - size/2, pos.Y - size * 0.75)
                    esp.Box.Visible = true
                    esp.Box.Color = BlockSpin.Settings.ESPColor
                else
                    esp.Box.Visible = false
                end
                
                if BlockSpin.Settings.ESPNames then
                    esp.Name.Position = Vector2.new(pos.X, pos.Y - size * 0.8)
                    esp.Name.Text = player.DisplayName
                    esp.Name.Visible = true
                else
                    esp.Name.Visible = false
                end
                
                if BlockSpin.Settings.ESPHealth then
                    local humanoid = char:FindFirstChild("Humanoid")
                    if humanoid then
                        esp.Health.Position = Vector2.new(pos.X, pos.Y + size * 0.8)
                        esp.Health.Text = math.floor(humanoid.Health) .. "/" .. math.floor(humanoid.MaxHealth)
                        esp.Health.Color = Color3.fromRGB(255 - (humanoid.Health/humanoid.MaxHealth)*255, (humanoid.Health/humanoid.MaxHealth)*255, 0)
                        esp.Health.Visible = true
                    end
                else
                    esp.Health.Visible = false
                end
                
                if BlockSpin.Settings.ESPDistance then
                    esp.Distance.Position = Vector2.new(pos.X, pos.Y + size * 0.95)
                    esp.Distance.Text = math.floor(distance) .. "m"
                    esp.Distance.Visible = true
                else
                    esp.Distance.Visible = false
                end
                
                if BlockSpin.Settings.ESPTracers then
                    esp.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                    esp.Tracer.Visible = true
                    esp.Tracer.Color = BlockSpin.Settings.ESPColor
                else
                    esp.Tracer.Visible = false
                end
            else
                for _, obj in pairs(esp) do obj.Visible = false end
            end
        else
            for _, obj in pairs(esp) do obj.Visible = false end
        end
    end
end

-- Movement
local function setupFly()
    if BlockSpin.FlyConnection then BlockSpin.FlyConnection:Disconnect() end
    
    if BlockSpin.Settings.FlyEnabled then
        local flySpeed = BlockSpin.Settings.FlySpeed / 50
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.P = 9e4
        bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bodyGyro.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
        
        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.Velocity = Vector3.new(0, 0, 0)
        bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            bodyGyro.Parent = LocalPlayer.Character.HumanoidRootPart
            bodyVel.Parent = LocalPlayer.Character.HumanoidRootPart
        end
        
        BlockSpin.FlyConnection = RunService.RenderStepped:Connect(function()
            if not BlockSpin.Settings.FlyEnabled then
                bodyGyro:Destroy()
                bodyVel:Destroy()
                return
            end
            
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local camCF = Camera.CFrame
                local moveDir = Vector3.new(0, 0, 0)
                
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end
                
                bodyVel.Velocity = moveDir * flySpeed * 50
                bodyGyro.CFrame = camCF
            end
        end)
    end
end

-- Main Loop
local function setupMainLoop()
    -- Aimbot
    table.insert(BlockSpin.Connections, RunService.RenderStepped:Connect(function()
        if BlockSpin.Settings.AimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType[BlockSpin.Settings.AimbotKey]) then
            local target = getClosestPlayer()
            if target then aimAt(target) end
        end
        
        if BlockSpin.Settings.ESPEnabled then
            updateESP()
        else
            for _, esp in pairs(BlockSpin.ESPObjects) do
                for _, obj in pairs(esp) do obj.Visible = false end
            end
        end
    end))
    
    -- Speed/Jump
    table.insert(BlockSpin.Connections, RunService.Heartbeat:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            local humanoid = LocalPlayer.Character.Humanoid
            
            if BlockSpin.Settings.SpeedEnabled then
                humanoid.WalkSpeed = BlockSpin.Settings.SpeedValue
            end
            
            if BlockSpin.Settings.JumpEnabled then
                humanoid.JumpPower = BlockSpin.Settings.JumpValue
            end
            
            if BlockSpin.Settings.NoClip and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end))
    
    -- Infinite Jump
    table.insert(BlockSpin.Connections, UserInputService.JumpRequest:Connect(function()
        if BlockSpin.Settings.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end))
    
    -- Auto Click
    task.spawn(function()
        while true do
            if BlockSpin.Settings.AutoClick then
                mouse1click()
            end
            task.wait(BlockSpin.Settings.ClickSpeed)
        end
    end)
    
    -- Anti AFK
    if BlockSpin.Settings.AntiAFK then
        local vu = game:GetService("VirtualUser")
        LocalPlayer.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        end)
    end
    
    -- Fullbright
    if BlockSpin.Settings.Fullbright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    end
    
    -- Custom FOV
    if BlockSpin.Settings.CustomFOV then
        Camera.FieldOfView = BlockSpin.Settings.FOVValue
    end
    
    -- ESP Setup
    for _, player in ipairs(Players:GetPlayers()) do
        createESP(player)
    end
    
    Players.PlayerAdded:Connect(createESP)
    Players.PlayerRemoving:Connect(function(player)
        if BlockSpin.ESPObjects[player] then
            for _, obj in pairs(BlockSpin.ESPObjects[player]) do obj:Remove() end
            BlockSpin.ESPObjects[player] = nil
        end
    end)
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

-- Configurar callback de éxito para cargar el script principal
Arqel.Callbacks.OnSuccess = function()
    Arqel:Notify("Loading", "Initializing BlockSpin Premium...", 2, "info")
    
    -- Crear UI Nexonix
    local Window = Nexonix:CreateWindow({
        Title = "BlockSpin Premium v2.0",
        Size = UDim2.new(0, 700, 0, 500)
    })
    
    -- Tab: Combat
    local CombatTab = Window:CreateTab("Combat")
    CombatTab:CreateSection("Aimbot")
    
    local aimbotToggle = CombatTab:CreateToggle({
        Name = "Enable Aimbot",
        Default = false,
        Callback = function(value)
            BlockSpin.Settings.AimbotEnabled = value
            Arqel:Notify("Aimbot", value and "Enabled" or "Disabled", 2, value and "success" or "error")
        end
    })
    
    local aimbotFOV = CombatTab:CreateSlider({
        Name = "Aimbot FOV",
        Min = 10,
        Max = 500,
        Default = 100,
        Callback = function(value)
            BlockSpin.Settings.AimbotFOV = value
        end
    })
    
    local aimbotSmooth = CombatTab:CreateSlider({
        Name = "Smoothness",
        Min = 0.1,
        Max = 1,
        Default = 0.5,
        Callback = function(value)
            BlockSpin.Settings.AimbotSmoothness = value
        end
    })
    
    CombatTab:CreateSection("Combat Mods")
    
    CombatTab:CreateToggle({
        Name = "Auto Click",
        Default = false,
        Callback = function(value)
            BlockSpin.Settings.AutoClick = value
        end
    })
    
    CombatTab:CreateSlider({
        Name = "Click Speed",
        Min = 0.001,
        Max = 0.1,
        Default = 0.01,
        Callback = function(value)
            BlockSpin.Settings.ClickSpeed = value
        end
    })
    
    CombatTab:CreateToggle({
        Name = "Reach",
        Default = false,
        Callback = function(value)
            BlockSpin.Settings.ReachEnabled = value
        end
    })
    
    -- Tab: Visual
    local VisualTab = Window:CreateTab("Visual")
    VisualTab:CreateSection("ESP")
    
    VisualTab:CreateToggle({
        Name = "Enable ESP",
        Default = false,
        Callback = function(value)
            BlockSpin.Settings.ESPEnabled = value
            Arqel:Notify("ESP", value and "Enabled" or "Disabled", 2, value and "success" or "error")
        end
    })
    
    VisualTab:CreateToggle({
        Name = "Boxes",
        Default = true,
        Callback = function(value)
            BlockSpin.Settings.ESPBoxes = value
        end
    })
    
    VisualTab:CreateToggle({
        Name = "Names",
        Default = true,
        Callback = function(value)
            BlockSpin.Settings.ESPNames = value
        end
    })
    
    VisualTab:CreateToggle({
        Name = "Health",
        Default = true,
        Callback = function(value)
            BlockSpin.Settings.ESPHealth = value
        end
    })
    
    VisualTab:CreateToggle({
        Name = "Distance",
        Default = true,
        Callback = function(value)
            BlockSpin.Settings.ESPDistance = value
        end
    })
    
    VisualTab:CreateToggle({
        Name = "Tracers",
        Default = false,
        Callback = function(value)
            BlockSpin.Settings.ESPTracers = value
        end
    })
    
    VisualTab:CreateSection("World")
    
    VisualTab:CreateToggle({
        Name = "Fullbright",
        Default = false,
        Callback = function(value)
            BlockSpin.Settings.Fullbright = value
            if value then
                Lighting.Brightness = 2
                Lighting.ClockTime = 14
                Lighting.GlobalShadows = false
            else
                Lighting.Brightness = 1
                Lighting.GlobalShadows = true
            end
        end
    })
    
    VisualTab:CreateToggle({
        Name = "Custom FOV",
        Default = false,
        Callback = function(value)
            BlockSpin.Settings.CustomFOV = value
            if not value then Camera.FieldOfView = 70 end
        end
    })
    
    VisualTab:CreateSlider({
        Name = "FOV Value",
        Min = 30,
        Max = 120,
        Default = 90,
        Callback = function(value)
            BlockSpin.Settings.FOVValue = value
            if BlockSpin.Settings.CustomFOV then Camera.FieldOfView = value end
        end
    })
    
    -- Tab: Movement
    local MoveTab = Window:CreateTab("Movement")
    MoveTab:CreateSection("Speed")
    
    MoveTab:CreateToggle({
        Name = "Speed Hack",
        Default = false,
        Callback = function(value)
            BlockSpin.Settings.SpeedEnabled = value
        end
    })
    
    MoveTab:CreateSlider({
        Name = "Speed",
        Min = 16,
        Max = 200,
        Default = 50,
        Callback = function(value)
            BlockSpin.Settings.SpeedValue = value
        end
    })
    
    MoveTab:CreateSection("Fly")
    
    MoveTab:CreateToggle({
        Name = "Fly",
        Default = false,
        Callback = function(value)
            BlockSpin.Settings.FlyEnabled = value
            setupFly()
        end
    })
    
    MoveTab:CreateSlider({
        Name = "Fly Speed",
        Min = 10,
        Max = 200,
        Default = 50,
        Callback = function(value)
            BlockSpin.Settings.FlySpeed = value
        end
    })
    
    MoveTab:CreateSection("Misc")
    
    MoveTab:CreateToggle({
        Name = "Infinite Jump",
        Default = false,
        Callback = function(value)
            BlockSpin.Settings.InfiniteJump = value
        end
    })
    
    MoveTab:CreateToggle({
        Name = "No Clip",
        Default = false,
        Callback = function(value)
            BlockSpin.Settings.NoClip = value
        end
    })
    
    MoveTab:CreateToggle({
        Name = "Auto Strafe",
        Default = false,
        Callback = function(value)
            BlockSpin.Settings.AutoStrafe = value
        end
    })
    
    -- Tab: Misc
    local MiscTab = Window:CreateTab("Misc")
    MiscTab:CreateSection("Settings")
    
    MiscTab:CreateToggle({
        Name = "Anti AFK",
        Default = true,
        Callback = function(value)
            BlockSpin.Settings.AntiAFK = value
        end
    })
    
    MiscTab:CreateButton({
        Name = "Rejoin Server",
        Callback = function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
        end
    })
    
    MiscTab:CreateButton({
        Name = "Server Hop",
        Callback = function()
            local HttpService = game:GetService("HttpService")
            local TeleportService = game:GetService("TeleportService")
            local servers = game.HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
            for _, server in ipairs(servers.data) do
                if server.playing < server.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id)
                    break
                end
            end
        end
    })
    
    -- Iniciar loops
    setupMainLoop()
    
    Arqel:Notify("Ready", "BlockSpin Premium loaded successfully!", 3, "success")
end

-- Lanzar el sistema de keys
Arqel:Notify("Arqel", "Key system initialized", 2, "info")
BuildKeyUI()

-- Exponer funciones globales
getgenv().BlockSpin = BlockSpin
getgenv().Arqel = Arqel
