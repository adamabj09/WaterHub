-- ===================================================== 
-- WATER HUB v5.2 – DELTA COMPATIBLE | BY: ABJadam 
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

-- Detectar executor (CORREGIDO PARA DELTA)
local isDelta = not syn and not fluxus and not _G.ExploitName
local isFluxus = fluxus ~= nil
local isSynapse = syn ~= nil

-- ==================== 2. KEY SYSTEM ====================
local KEY_URL = "https://script.google.com/macros/s/AKfycbyfxTS6LpCaDvEMrSyJRrRb32bXjNlDW3yaWWZZocqIYmG6ztz0uRKcpqx1ieP0uLXaog/exec"
local KEY_FILE = "WaterHub_Key.txt"

local function saveKey(key)
    pcall(function()
        if writefile then
            writefile(KEY_FILE, key)
        end
    end)
end

local function loadKey()
    local content = nil
    pcall(function()
        if readfile then
            content = readfile(KEY_FILE)
        end
    end)
    return content
end

local function verifyKey(key)
    local http = request or http_request
    if not http then 
        print("❌ No HTTP disponible")
        return false 
    end
    
    local success, res = pcall(function()
        return http({
            Url = KEY_URL .. "?key=" .. key .. "&action=verify",
            Method = "GET"
        })
    end)
    
    if success and res and res.Body then
        local decoded = pcall(function()
            return HttpService:JSONDecode(res.Body)
        end)
        if decoded then
            local data = decoded
            return data.valid == true
        end
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
        gui.ResetOnSpawn = false
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
        btn.TextColor3 = Color3.fromRGB(255,255,255)
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
        repeat task.wait() until keyValid or not gui.Parent
    end
    askKey()
end

if not keyValid then return end

-- ==================== 3. ANTI-KICK (DELTA COMPATIBLE) ====================
local function SuperAntiCheat()
    pcall(function()
        LocalPlayer.Kick = function() end
    end)
    
    -- NO usar getrawmetatable en Delta
    if not isDelta then
        pcall(function()
            if _G.setreadonly then
                _G.setreadonly(getrawmetatable(game), false)
            end
        end)
    end
    
    local blacklist = {"Kick","Ban","Report","BAC","AntiCheat","Admin","Log"}
    local function scan(obj)
        if not obj then return end
        pcall(function()
            for _, v in pairs(obj:GetChildren()) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    for _, bad in pairs(blacklist) do
                        if v.Name:find(bad) then
                            pcall(function()
                                v.FireServer = function() end
                                v.OnClientEvent = function() end
                            end)
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
        AutoDuel = false,
        AutoPlay = false,
        AutoWin = false,
        AutoFarmWins = false,
        Aimbot = false,
        SilentAim = false,
        Triggerbot = false,
        ESPPlayers = false,
        ESPBrainrot = false,
        Godmode = false,
        AntiRagdoll = false,
        AntiStun = false,
        AntiSlow = false,
        SpeedHack = false,
        JumpHack = false,
        Fly = false,
        RemoveAnimation = false,
        NoAnimationAttack = false,
        FastAttack = false,
        InfiniteRange = false,
        AutoCollect = false,
        AutoLeave = false,
        AutoQueue = false,
        AntiDetectionDelay = true,
        Visuals = false,
        SpeedValue = 16,
        JumpValue = 50,
        FlySpeed = 50,
        MenuColor = "Azul",
        CurrentStatus = "Esperando...",
    },
    Stats = { Kills = 0, Wins = 0, Damage = 0 },
    Enemies = {},
    Brainrots = {},
    ConfigFile = "WaterHub_Config.json",
    ActiveHighlights = {}
}

local Colors = {
    Azul = {bg = Color3.fromRGB(25,50,75), accent = Color3.fromRGB(0,150,255)},
    Rojo = {bg = Color3.fromRGB(75,25,25), accent = Color3.fromRGB(255,50,50)},
    Verde = {bg = Color3.fromRGB(25,75,25), accent = Color3.fromRGB(50,255,50)},
    Morado = {bg = Color3.fromRGB(50,25,75), accent = Color3.fromRGB(150,50,255)},
    Rosa = {bg = Color3.fromRGB(75,25,50), accent = Color3.fromRGB(255,80,150)}
}

-- ==================== 5. CONFIG ====================
local function SaveConfig()
    local config = {}
    for k, v in pairs(WaterHub.State) do
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
            config[k] = v
        end
    end
    
    pcall(function()
        if writefile then
            local json = HttpService:JSONEncode(config)
            writefile(WaterHub.ConfigFile, json)
        end
    end)
end

local function LoadConfig()
    pcall(function()
        if readfile then
            local content = readfile(WaterHub.ConfigFile)
            if content then
                local config = HttpService:JSONDecode(content)
                for k, v in pairs(config) do
                    if WaterHub.State[k] ~= nil then
                        WaterHub.State[k] = v
                    end
                end
            end
        end
    end)
end

-- ==================== 6. LIMPIEZA ESP ====================
local function ClearESP()
    for _, highlight in pairs(WaterHub.ActiveHighlights) do
        pcall(function() highlight:Destroy() end)
    end
    WaterHub.ActiveHighlights = {}
end

-- ==================== 7. AIMBOT ====================
local AimbotHandler = {}

function AimbotHandler.GetClosestEnemy()
    local closest, closestDist = nil, math.huge
    for _, enemy in pairs(WaterHub.Enemies) do
        if enemy and enemy.Character and enemy.Character:FindFirstChild("HumanoidRootPart") then
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
    if not enemy or not enemy.Character or not enemy.Character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    local origin = Camera.CFrame.Position
    local target = enemy.Character.HumanoidRootPart.Position
    local params = RaycastParams.new()
    
    if LocalPlayer.Character then
        params.FilterDescendantsInstances = {LocalPlayer.Character}
    end
    params.FilterType = Enum.RaycastFilterType.Blacklist
    
    local ray = Workspace:Raycast(origin, (target - origin).Unit * 500, params)
    if ray and ray.Instance and ray.Instance:IsDescendantOf(enemy.Character) then
        return true
    end
    return false
end

function AimbotHandler.SmoothAim(targetCFrame)
    local step = 0.15
    Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, step)
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

-- ==================== 8. GUI ====================
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

-- Top Bar
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 45)
topBar.BackgroundColor3 = Colors[WaterHub.State.MenuColor].accent
topBar.BackgroundTransparency = 0.3
topBar.Parent = mainFrame

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

-- Scroll
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

-- Close Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(1, -10, 0, 40)
closeBtn.Position = UDim2.new(0, 5, 1, -48)
closeBtn.Text = "❌ CERRAR"
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

-- ==================== 9. MAIN LOOP ====================
RunService.RenderStepped:Connect(function()
    -- Actualizar enemigos
    WaterHub.Enemies = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(WaterHub.Enemies, plr)
        end
    end
    
    -- Aimbot
    if WaterHub.State.Aimbot then
        AimbotHandler.HandleAimbot()
    end
    
    -- ESP Players
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
end)

-- Speed/Jump Hack
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    if WaterHub.State.SpeedHack then
        hum.WalkSpeed = WaterHub.State.SpeedValue
    end
    
    if WaterHub.State.JumpHack then
        hum.JumpPower = WaterHub.State.JumpValue
    end
end)

-- ==================== 10. CLEANUP ====================
LoadConfig()
print("✅ WATER HUB v5.2 – DELTA COMPATIBLE")
print("🚀 Script iniciado correctamente")
