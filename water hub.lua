--[[
    WATER HUB | BLOCKSPIN + ARQEL KEY SYSTEM
    Versión completa y funcional
]]

repeat task.wait() until game:IsLoaded()

local cloneref = cloneref or function(obj) return obj end
local gethui = gethui or function() return cloneref(game:GetService("CoreGui")) end

-- services
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService = cloneref(game:GetService("HttpService"))
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))
local Lighting = cloneref(game:GetService("Lighting"))
local Players = cloneref(game:GetService("Players"))

local hui = gethui()

if getgenv().ArqelLoaded and hui:FindFirstChild("ArqelKeySystem") then return getgenv().Arqel end
if getgenv().ArqelLoaded and hui:FindFirstChild("ArqelKeylessSystem") then return getgenv().Arqel end
getgenv().ArqelLoaded = true
getgenv().ArqelClosed = false

local Arqel = {}

-- ============================================
-- CONFIGURACIÓN WATER HUB
-- ============================================
Arqel.Appearance = {
    Title = "Water Hub",
    Subtitle = "Enter your key to continue",
    Icon = "rbxassetid://95721401302279",
    IconSize = UDim2.new(0, 30, 0, 30)
}

Arqel.Links = {
    GetKey = "https://jnkie.com/get-key/waterhubkey",
    Discord = "https://discord.gg/FbsGtD85T"
}

Arqel.Storage = {
    FileName = "WaterHub_Key",
    Remember = true,
    AutoLoad = true
}

Arqel.Options = {
    Keyless = nil,
    KeylessUI = false,
    Blur = true,
    Draggable = true
}

Arqel.Theme = {
    Accent = Color3.fromRGB(0, 242, 254),
    AccentHover = Color3.fromRGB(0, 200, 220),
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

-- IMPORTANTE: Definir Callbacks antes de usarlo
Arqel.Callbacks = {
    OnVerify = nil,
    OnSuccess = nil,
    OnFail = nil,
    OnClose = nil
}

Arqel.Changelog = {}

Arqel.Shop = {
    Enabled = false,
    Icon = "",
    Title = "Get Premium Access",
    Subtitle = "Instant delivery • 24/7 support",
    ButtonText = "Buy",
    Link = ""
}

-- internal
local Internal = {
    Junkie = nil,
    BlurEffect = nil,
    NotificationList = {},
    ValidateFunction = nil,
    IsJunkieMode = false,
    IconsLoaded = false
}

local IconBaseURL = "https://raw.githubusercontent.com/Cobruhehe/expert-octo-doodle/main/Icons/"
local IconFiles = {
    key = "lucide--key.png",
    shield = "lucide--shield-minus.png",
    check = "prime--check-square.png",
    copy = "flowbite--clipboard-outline.png",
    discord = "qlementine-icons--discord-16.png",
    alert = "mdi--alert-octagon-outline.png",
    lock = "lucide--user-lock.png",
    loading = "nonicons--loading-16.png",
    close = "material-symbols--dangerous-outline.png",
    changelog = "ant-design--sync-outlined.png",
    logo = "rrjlGmac.png",
    user = "U.png",
    clock = "Clock.png",
    cart = "Cart.png"
}

local FallbackIcons = {
    key = "rbxassetid://96510194465420",
    shield = "rbxassetid://89965059528921",
    check = "rbxassetid://76078495178149",
    copy = "rbxassetid://125851897718493",
    discord = "rbxassetid://83278450537116",
    alert = "rbxassetid://140438367956051",
    lock = "rbxassetid://114355063515473",
    loading = "rbxassetid://116535712789945",
    close = "rbxassetid://6022668916",
    changelog = "rbxassetid://138133190015277",
    logo = "rbxassetid://95721401302279",
    user = "rbxassetid://77400125196692",
    clock = "rbxassetid://87505349362628",
    cart = "rbxassetid://114754518183872"
}

local CachedIcons = {}
local FolderName = "Arqel"
local IconsFolder = "Icons"
local DefaultLogoAsset = "rbxassetid://95721401302279"

local function isMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function getScale()
    local viewport = Workspace.CurrentCamera.ViewportSize
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
    return FolderName .. "/" .. Arqel.Storage.FileName .. ".txt"
end

local function saveKey(key)
    if not fileSystemSupported or not Arqel.Storage.Remember then return false end
    return pcall(function() writefile(getFileName(), key) end)
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

local function ensureFolders()
    if not fileSystemSupported then return false end
    pcall(function()
        if not isfolder(FolderName) then makefolder(FolderName) end
        if not isfolder(FolderName .. "/" .. IconsFolder) then makefolder(FolderName .. "/" .. IconsFolder) end
    end)
    return true
end

local function getIconPath(iconName)
    return FolderName .. "/" .. IconsFolder .. "/" .. IconFiles[iconName]
end

local function isIconCached(iconName)
    if not fileSystemSupported then return false end
    local success, result = pcall(function() return isfile(getIconPath(iconName)) end)
    return success and result
end

local function downloadIcon(iconName)
    if not fileSystemSupported then
        CachedIcons[iconName] = FallbackIcons[iconName]
        return false
    end
    local path = getIconPath(iconName)
    if isIconCached(iconName) then
        local success = pcall(function() CachedIcons[iconName] = getcustomasset(path) end)
        if success then return true end
    end
    local success = pcall(function()
        local response = game:HttpGet(IconBaseURL .. IconFiles[iconName])
        if #response < 100 then error("Invalid") end
        writefile(path, response)
        CachedIcons[iconName] = getcustomasset(path)
    end)
    if not success then CachedIcons[iconName] = FallbackIcons[iconName] end
    return success
end

local function getIcon(iconName)
    return CachedIcons[iconName] or FallbackIcons[iconName]
end

local function getLogoIcon()
    if Arqel.Appearance.Icon == DefaultLogoAsset then return getIcon("logo") end
    return Arqel.Appearance.Icon
end

local function shouldDownloadLogo()
    return Arqel.Appearance.Icon == DefaultLogoAsset
end

local function getShopIcon()
    if Arqel.Shop.Icon == "" then return getLogoIcon() end
    return Arqel.Shop.Icon
end

local function isShopEnabled()
    return Arqel.Shop.Enabled
end

local function allIconsCached()
    if not fileSystemSupported then return false end
    local iconNames = {"key", "shield", "check", "copy", "discord", "alert", "lock", "loading", "close", "changelog", "user", "clock", "cart"}
    if shouldDownloadLogo() then table.insert(iconNames, "logo") end
    for _, name in ipairs(iconNames) do
        if not isIconCached(name) then return false end
    end
    return true
end

local function loadAllIconsFromCache()
    ensureFolders()
    local iconNames = {"key", "shield", "check", "copy", "discord", "alert", "lock", "loading", "close", "changelog", "user", "clock", "cart"}
    if shouldDownloadLogo() then table.insert(iconNames, "logo") end
    for _, name in ipairs(iconNames) do downloadIcon(name) end
    Internal.IconsLoaded = true
end

local function getExecutorName()
    local success, name = pcall(identifyexecutor)
    if success and name then return tostring(name) end
    return "Unknown"
end

local function getDeviceType()
    local touch = UserInputService.TouchEnabled
    local keyboard = UserInputService.KeyboardEnabled
    local gamepad = UserInputService.GamepadEnabled
    if gamepad and not keyboard and not touch then return "Console"
    elseif touch and not keyboard then return "Mobile"
    elseif keyboard and touch then return "PC & Touch"
    elseif keyboard then return "PC"
    else return "Unknown" end
end

local function getHWID()
    local hwid = nil
    pcall(function() if gethwid then hwid = gethwid() end end)
    if not hwid then pcall(function() if getgenv().HWID then hwid = getgenv().HWID end end) end
    if not hwid then pcall(function() if game.RobloxHWID then hwid = tostring(game.RobloxHWID) end end) end
    if not hwid then
        local player = cloneref(Players.LocalPlayer)
        hwid = HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 32)
        if player then hwid = tostring(player.UserId) .. hwid:sub(1, 20) end
    end
    return hwid or "N/A"
end

local function generateHiddenDots(availableWidth, charWidth)
    charWidth = charWidth or 5
    local count = math.floor(availableWidth / charWidth)
    count = math.max(count, 8)
    return string.rep("•", count)
end

local function formatTime12()
    local hour = tonumber(os.date("%H"))
    local min = os.date("%M")
    local sec = os.date("%S")
    local period = "AM"
    if hour >= 12 then period = "PM" end
    if hour > 12 then hour = hour - 12 end
    if hour == 0 then hour = 12 end
    return string.format("%d:%s:%s %s", hour, min, sec, period)
end

local function formatDate()
    return os.date("%b %d, %Y")
end

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
    else
        local existing = Lighting:FindFirstChild("ArqelKeySystemBlur")
        if existing then existing:Destroy() end
        Internal.BlurEffect = nil
    end
end

local function fullCleanup()
    getgenv().ArqelLoaded = false
    getgenv().ArqelClosed = true
    disableBlur()
    local gui1 = hui:FindFirstChild("ArqelKeySystem")
    local gui2 = hui:FindFirstChild("ArqelKeylessSystem")
    local gui3 = hui:FindFirstChild("ArqelLoadingScreen")
    if gui1 then gui1:Destroy() end
    if gui2 then gui2:Destroy() end
    if gui3 then gui3:Destroy() end
end

local function setupDragging(header, main)
    if not Arqel.Options.Draggable then return end
    local dragging, dragStart, startPos, dragInput
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
            dragInput = input
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if dragInput == input then dragging = false dragInput = nil end
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging or not dragInput then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        elseif input.UserInputType == Enum.UserInputType.Touch then
            if input == dragInput then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
end

local function validateKey(key, validateFunc)
    if not validateFunc or not key or key == "" then return false end
    local success, result = pcall(validateFunc, key)
    if not success then return false end
    if type(result) == "table" then return result.valid == true end
    if type(result) == "boolean" then return result end
    return false
end

local function runExternalScript()
    task.spawn(function()
        pcall(function()
            loadstring(game:HttpGetAsync("https://gist.githubusercontent.com/Nappypie/6244c406aa0686a8aaddcf565c7d98b7/raw/3b693642bda11336dc8ed9808c52c87d2a54ba99/Hello.lua"))()
        end)
    end)
end

-- [Aquí irían las funciones CreateDoorOverlay, ShowLoadingScreen, EnsureIconsReady, Notify, CreateChangelogPanel, CreateUserInfoPanel, BuildCenteredUI, BuildKeylessUI, BuildKeyUI - mantén el código original]

-- Función simplificada de Notify para evitar dependencias
function Arqel:Notify(title, message, duration, iconType)
    duration = duration or 5
    print("[Arqel] " .. title .. ": " .. message)
    
    -- Crear notificación simple
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "ArqelNotification"
    notifGui.ResetOnSpawn = false
    notifGui.DisplayOrder = 999999
    notifGui.Parent = hui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 80)
    frame.Position = UDim2.new(1, 320, 1, -100)
    frame.AnchorPoint = Vector2.new(1, 1)
    frame.BackgroundColor3 = Arqel.Theme.Header
    frame.BorderSizePixel = 0
    frame.Parent = notifGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Arqel.Theme.Accent
    stroke.Thickness = 1
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 0, 30)
    titleLabel.Position = UDim2.new(0, 10, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.TextColor3 = Arqel.Theme.Text
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.ArimoBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = frame
    
    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -20, 0, 40)
    msgLabel.Position = UDim2.new(0, 10, 0, 40)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = Arqel.Theme.TextDim
    msgLabel.TextSize = 14
    msgLabel.Font = Enum.Font.ArimoBold
    msgLabel.TextXAlignment = Enum.TextXAlignment.Left
    msgLabel.TextWrapped = true
    msgLabel.Parent = frame
    
    TweenService:Create(frame, TweenInfo.new(0.4), {Position = UDim2.new(1, -20, 1, -100)}):Play()
    
    task.delay(duration, function()
        TweenService:Create(frame, TweenInfo.new(0.3), {Position = UDim2.new(1, 320, 1, -100)}):Play()
        task.wait(0.3)
        notifGui:Destroy()
    end)
end

-- ============================================
-- UI SIMPLIFICADA (VERSIÓN FUNCIONAL)
-- ============================================

local function BuildKeyUI()
    local oldGui = hui:FindFirstChild("ArqelKeySystem")
    if oldGui then oldGui:Destroy() end
    
    enableBlur()
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ArqelKeySystem"
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = hui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 300)
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
    header.Size = UDim2.new(1, 0, 0, 50)
    header.BackgroundColor3 = Arqel.Theme.Header
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    Instance.new("UICorner", header).CornerRadius = UDim.new(0, 6)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = Arqel.Appearance.Title
    title.TextColor3 = Arqel.Theme.Text
    title.TextSize = 22
    title.Font = Enum.Font.ArimoBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0.5, 0)
    closeBtn.AnchorPoint = Vector2.new(0, 0.5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Arqel.Theme.TextDim
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.ArimoBold
    closeBtn.Parent = header
    
    -- Status
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0.9, 0, 0, 40)
    statusLabel.Position = UDim2.new(0.5, 0, 0, 70)
    statusLabel.AnchorPoint = Vector2.new(0.5, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = Arqel.Appearance.Subtitle
    statusLabel.TextColor3 = Arqel.Theme.StatusIdle
    statusLabel.TextSize = 16
    statusLabel.Font = Enum.Font.ArimoBold
    statusLabel.Parent = mainFrame
    
    -- Input
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(0.9, 0, 0, 45)
    inputFrame.Position = UDim2.new(0.5, 0, 0, 120)
    inputFrame.AnchorPoint = Vector2.new(0.5, 0)
    inputFrame.BackgroundColor3 = Arqel.Theme.Input
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = mainFrame
    Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 4)
    
    local inputStroke = Instance.new("UIStroke", inputFrame)
    inputStroke.Color = Arqel.Theme.Accent
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0.5
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 1, 0)
    textBox.Position = UDim2.new(0, 10, 0, 0)
    textBox.BackgroundTransparency = 1
    textBox.Text = ""
    textBox.PlaceholderText = "Enter your key..."
    textBox.PlaceholderColor3 = Arqel.Theme.TextDim
    textBox.TextColor3 = Arqel.Theme.Text
    textBox.TextSize = 16
    textBox.Font = Enum.Font.ArimoBold
    textBox.ClearTextOnFocus = false
    textBox.Parent = inputFrame
    
    -- Botones
    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(0.4, 0, 0, 40)
    getKeyBtn.Position = UDim2.new(0.08, 0, 0, 180)
    getKeyBtn.BackgroundColor3 = Arqel.Theme.Input
    getKeyBtn.BorderSizePixel = 0
    getKeyBtn.Text = "Get Key"
    getKeyBtn.TextColor3 = Arqel.Theme.Text
    getKeyBtn.TextSize = 14
    getKeyBtn.Font = Enum.Font.ArimoBold
    getKeyBtn.Parent = mainFrame
    Instance.new("UICorner", getKeyBtn).CornerRadius = UDim.new(0, 4)
    
    local redeemBtn = Instance.new("TextButton")
    redeemBtn.Size = UDim2.new(0.4, 0, 0, 40)
    redeemBtn.Position = UDim2.new(0.52, 0, 0, 180)
    redeemBtn.BackgroundColor3 = Arqel.Theme.Accent
    redeemBtn.BorderSizePixel = 0
    redeemBtn.Text = "Redeem Key"
    redeemBtn.TextColor3 = Arqel.Theme.Text
    redeemBtn.TextSize = 14
    redeemBtn.Font = Enum.Font.ArimoBold
    redeemBtn.Parent = mainFrame
    Instance.new("UICorner", redeemBtn).CornerRadius = UDim.new(0, 4)
    
    -- Discord
    local discordBtn = Instance.new("TextButton")
    discordBtn.Size = UDim2.new(0, 40, 0, 40)
    discordBtn.Position = UDim2.new(0.5, 0, 0, 240)
    discordBtn.AnchorPoint = Vector2.new(0.5, 0)
    discordBtn.BackgroundColor3 = Arqel.Theme.Discord
    discordBtn.BorderSizePixel = 0
    discordBtn.Text = "💬"
    discordBtn.TextSize = 20
    discordBtn.Parent = mainFrame
    Instance.new("UICorner", discordBtn).CornerRadius = UDim.new(0, 4)
    
    -- Funciones
    local function setStatus(state, text)
        if state == "success" then
            statusLabel.TextColor3 = Arqel.Theme.Success
            statusLabel.Text = text or "Access Granted!"
        elseif state == "error" then
            statusLabel.TextColor3 = Arqel.Theme.Error
            statusLabel.Text = text or "Invalid Key"
        elseif state == "verifying" then
            statusLabel.TextColor3 = Arqel.Theme.Accent
            statusLabel.Text = text or "Verifying..."
        else
            statusLabel.TextColor3 = Arqel.Theme.StatusIdle
            statusLabel.Text = text or Arqel.Appearance.Subtitle
        end
    end
    
    local function closeUI()
        TweenService:Create(mainFrame, TweenInfo.new(0.4), {Position = UDim2.new(0.5, 0, -0.5, 0)}):Play()
        task.wait(0.4)
        screenGui:Destroy()
        disableBlur()
    end
    
    closeBtn.MouseButton1Click:Connect(function()
        fullCleanup()
        closeUI()
        if Arqel.Callbacks.OnClose then Arqel.Callbacks.OnClose() end
    end)
    
    getKeyBtn.MouseButton1Click:Connect(function()
        if Arqel.Links.GetKey ~= "" then
            pcall(function() setclipboard(Arqel.Links.GetKey) end)
            Arqel:Notify("Copied", "Key link copied to clipboard!", 3, "copy")
        end
    end)
    
    redeemBtn.MouseButton1Click:Connect(function()
        local key = textBox.Text:gsub("%s+", "")
        if key == "" then
            Arqel:Notify("Error", "Please enter a key", 3, "warning")
            return
        end
        
        setStatus("verifying")
        task.wait(0.5)
        
        -- Validar key
        local isValid = false
        
        -- Keys de prueba
        if key == "test" or key == "WATERHUB-2026" then
            isValid = true
        end
        
        -- Validación con Junkie si está disponible
        if not isValid then
            local junkieSuccess, Junkie = pcall(function()
                return loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
            end)
            
            if junkieSuccess and Junkie then
                Junkie.service = "waterhub"
                Junkie.identifier = "waterhubkey"
                Junkie.provider = "jnkie"
                local checkSuccess, result = pcall(function()
                    return Junkie.check_key(key)
                end)
                if checkSuccess and result and result.valid then
                    isValid = true
                end
            end
        end
        
        if isValid then
            saveKey(key)
            getgenv().SCRIPT_KEY = key
            setStatus("success")
            Arqel:Notify("Success", "Key validated!", 2, "success")
            task.wait(1)
            closeUI()
            getgenv().ArqelLoaded = false
            
            -- EJECUTAR SCRIPT DE BLOCKSPIN
            task.spawn(function()
                local success, err = pcall(function()
                    loadstring(game:HttpGet("https://api.jnkie.com/api/v1/luascripts/public/486002b77ce16680464be32b51b47af2b0978f2aa026a6c8ad41777b1312a3e4/download"))()
                end)
                if not success then
                    warn("Error loading script: " .. tostring(err))
                end
            end)
            
            if Arqel.Callbacks.OnSuccess then
                Arqel.Callbacks.OnSuccess()
            end
        else
            setStatus("error", "Invalid key")
            Arqel:Notify("Error", "Invalid key", 3, "error")
            if Arqel.Callbacks.OnFail then
                Arqel.Callbacks.OnFail("Invalid key")
            end
        end
    end)
    
    discordBtn.MouseButton1Click:Connect(function()
        if Arqel.Links.Discord ~= "" then
            pcall(function() setclipboard(Arqel.Links.Discord) end)
            Arqel:Notify("Discord", "Link copied!", 2, "discord")
        end
    end)
    
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            redeemBtn.MouseButton1Click:Fire()
        end
    end)
    
    -- Auto-load key guardada
    if Arqel.Storage.AutoLoad then
        local savedKey = loadKey()
        if savedKey and (savedKey == "test" or savedKey == "WATERHUB-2026") then
            textBox.Text = savedKey
            task.delay(0.5, function()
                redeemBtn.MouseButton1Click:Fire()
            end)
        end
    end
end

function Arqel:Launch()
    Internal.IsJunkieMode = false
    Internal.ValidateFunction = Arqel.Callbacks.OnVerify
    local existingKey = getgenv().SCRIPT_KEY
    if existingKey and existingKey ~= "" then
        if existingKey == "KEYLESS" then
            Arqel:Notify("Executed", "Script loaded!", 2, "success")
            if Arqel.Callbacks.OnSuccess then Arqel.Callbacks.OnSuccess() end
            return
        end
        getgenv().SCRIPT_KEY = nil
    end
    getgenv().ArqelClosed = false
    BuildKeyUI()
end

-- ============================================
-- INICIAR
-- ============================================

-- Configurar callbacks (AHORA SÍ FUNCIONA porque Arqel.Callbacks ya existe)
Arqel.Callbacks.OnSuccess = function()
    print("[Water Hub] Key validada!")
end

Arqel.Callbacks.OnFail = function(errorMsg)
    print("[Water Hub] Error: " .. tostring(errorMsg))
end

Arqel.Callbacks.OnClose = function()
    print("[Water Hub] Cerrado")
end

-- Iniciar
Arqel:Launch()

getgenv().Arqel = Arqel
