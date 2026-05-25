--[[
    WATER HUB | BLOCKSPIN - VERSIÓN DELTA SIMPLIFICADA
    Solo funciones que SÍ funcionan en Delta
    By: AdamABJ
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

-- ============================================
-- CARGAR WINDUI (FALLBACK MANUAL SI FALLA)
-- ============================================
local WindUI
pcall(function()
    WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if not WindUI then
    -- GUI manual simple si WindUI falla
    local gui = Instance.new("ScreenGui")
    gui.Name = "WaterHub"
    gui.Parent = CoreGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 400)
    frame.Position = UDim2.new(0.5, -150, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.Parent = gui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    title.Text = "WATER HUB (MODO SIMPLE)"
    title.TextColor3 = Color3.fromRGB(255,255,255)
    title.Parent = frame
    
    local text = Instance.new("TextLabel")
    text.Size = UDim2.new(1, -20, 1, -40)
    text.Position = UDim2.new(0, 10, 0, 35)
    text.BackgroundTransparency = 1
    text.Text = "WindUI no cargó\nUsando modo simple\n\nSpeed: H\nJump: J\nNoClip: N\nFly: F"
    text.TextColor3 = Color3.fromRGB(200,200,200)
    text.TextSize = 14
    text.Parent = frame
    
    WindUI = {Notify = function() end} -- dummy
end

-- ============================================
-- REMOTES
-- ============================================
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local SendRemote = Remotes and Remotes:FindFirstChild("Send")

-- ============================================
-- IDs DE ARMAS (23)
-- ============================================
local WeaponImages = {
    ["AK47"] = "rbxassetid://124555430577178",
    ["AUG"] = "rbxassetid://83729841153733",
    ["AWP"] = "rbxassetid://126356167274927",
    ["Anaconda"] = "rbxassetid://121547020534134",
    ["C9"] = "rbxassetid://79659079988022",
    ["Crossbow"] = "rbxassetid://89240642376715",
    ["Double Barrel"] = "rbxassetid://83625765638039",
    ["Draco"] = "rbxassetid://120937616266903",
    ["Firework Launcher"] = "rbxassetid://88284317820274",
    ["G3"] = "rbxassetid://133411291398002",
    ["Glock"] = "rbxassetid://97846154366870",
    ["Hunting Rifle"] = "rbxassetid://81547704965153",
    ["M16"] = "rbxassetid://74321352408872",
    ["M24"] = "rbxassetid://73387965982603",
    ["M249"] = "rbxassetid://80044343904275",
    ["MP5"] = "rbxassetid://80501079489777",
    ["P226"] = "rbxassetid://92521100297776",
    ["P90"] = "rbxassetid://110565990980804",
    ["RPG"] = "rbxassetid://138426000142807",
    ["Remington"] = "rbxassetid://101271375930409",
    ["Sawnoff"] = "rbxassetid://90588305892707",
    ["Skorpion"] = "rbxassetid://105318377951686",
    ["Uzi"] = "rbxassetid://109290695652338",
}

-- ============================================
-- CONFIGURACIÓN
-- ============================================
local Settings = {
    Speed = false,
    SpeedValue = 50,
    Jump = false,
    NoClip = false,
    Fly = false,
    Chams = false,
}

local ESPs = {}
local ChamsObj = {}
local NoClipConn = nil
local Flying = false
local FlySpeed = 50
local FlyConnection = nil

-- ============================================
-- CHAMS (AZUL)
-- ============================================
local function ApplyChams(player, enabled)
    local char = player.Character
    if not char then return end
    if enabled then
        if not ChamsObj[player] then
            local h = Instance.new("Highlight")
            h.FillColor = Color3.fromRGB(0, 100, 255)
            h.FillTransparency = 0.5
            h.Adornee = char
            h.Parent = char
            ChamsObj[player] = h
        end
    else
        if ChamsObj[player] then
            ChamsObj[player]:Destroy()
            ChamsObj[player] = nil
        end
    end
end

-- ============================================
-- ESP
-- ============================================
local function CreateESP(player)
    if ESPs[player] then return end
    
    local gui = Instance.new("BillboardGui")
    gui.Name = "WaterHubESP"
    gui.Size = UDim2.new(0, 200, 0, 50)
    gui.AlwaysOnTop = true
    gui.ResetOnSpawn = false
    gui.Parent = CoreGui
    
    local nameLabel = Instance.new("TextLabel", gui)
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.fromRGB(255,255,255)
    nameLabel.TextSize = 12
    
    local healthBar = Instance.new("Frame", gui)
    healthBar.Size = UDim2.new(1, 0, 0, 5)
    healthBar.Position = UDim2.new(0, 0, 0, 22)
    healthBar.BackgroundColor3 = Color3.fromRGB(0,255,0)
    
    local weaponLabel = Instance.new("TextLabel", gui)
    weaponLabel.Size = UDim2.new(1, 0, 0, 15)
    weaponLabel.Position = UDim2.new(0, 0, 0, 30)
    weaponLabel.BackgroundTransparency = 1
    weaponLabel.TextColor3 = Color3.fromRGB(255,200,100)
    weaponLabel.TextSize = 10
    
    ESPs[player] = {gui, nameLabel, healthBar, weaponLabel, nil}
end

local function UpdateESP()
    for player, data in pairs(ESPs) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        if hrp and hum and hum.Health > 0 then
            data[1].Adornee = hrp
            data[1].Enabled = true
            
            local percent = hum.Health / hum.MaxHealth
            data[3].Size = UDim2.new(percent, 0, 1, 0)
            data[3].BackgroundColor3 = Color3.fromRGB(255*(1-percent), 255*percent, 0)
            
            -- Obtener arma equipada
            local tool = char:FindFirstChildOfClass("Tool")
            if tool and tool.Name ~= data[5] then
                data[5] = tool.Name
                local icon = WeaponImages[tool.Name]
                if icon then
                    data[4].Text = "🔫 " .. tool.Name
                else
                    data[4].Text = "🔫 " .. tool.Name
                end
            end
        else
            data[1].Enabled = false
        end
    end
end

-- ============================================
-- MOVEMENT
-- ============================================
local function SpeedLoop()
    while Settings.Speed do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = Settings.SpeedValue end
        end
        task.wait(0.1)
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

local function JumpLoop()
    local conn
    conn = UserInputService.JumpRequest:Connect(function()
        if Settings.Jump then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum and hum:GetState() == Enum.HumanoidStateType.Landed then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end)
    while Settings.Jump do task.wait(0.5) end
    conn:Disconnect()
end

local function NoClipLoop()
    if Settings.NoClip then
        if NoClipConn then return end
        NoClipConn = RunService.Stepped:Connect(function()
            if not Settings.NoClip then return end
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if NoClipConn then
            NoClipConn:Disconnect()
            NoClipConn = nil
        end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

local function FlyUpdate()
    if not Flying then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local move = Vector3.new(0,0,0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0,0,-1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0,0,1) end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1,0,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1,0,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move + Vector3.new(0,-1,0) end
    
    if move.Magnitude > 0 then
        local cam = Workspace.CurrentCamera
        local cf = cam.CFrame
        local direction = cf:VectorToWorldSpace(move).Unit
        hrp.CFrame = hrp.CFrame + direction * FlySpeed
    end
end

-- ============================================
-- AUTO HEAL (SIMPLE)
-- ============================================
local function AutoHealLoop()
    while Settings.AutoHeal do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.Health < hum.MaxHealth * 0.7 then
                -- Buscar medkit en el inventario
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    local medkit = backpack:FindFirstChild("Medkit") or backpack:FindFirstChild("Bandage")
                    if medkit and medkit:IsA("Tool") then
                        medkit.Parent = char
                        medkit:Activate()
                    end
                end
            end
        end
        task.wait(1)
    end
end

-- ============================================
-- CONFIGURAR GUI WINDUI (SI ESTÁ DISPONIBLE)
-- ============================================
if WindUI and WindUI.CreateWindow then
    local Window = WindUI:CreateWindow({
        Title = "Water Hub | BlockSpin",
        Author = "By: AdamABJ",
        Folder = "WaterHub_Delta",
        Icon = "solar:water-drops-bold-duotone",
        Theme = "Dark",
        NewElements = true,
        Transparent = true,
        ToggleKey = Enum.KeyCode.RightShift,
        Acrylic = true,
    })
    
    local MovementTab = Window:Tab({ Title = "MOVEMENT", Icon = "solar:user-bold-duotone" })
    local VisualTab = Window:Tab({ Title = "VISUAL", Icon = "solar:eye-bold-duotone" })
    
    local MoveGroup = MovementTab:Group({ Title = "⚡ Movement" })
    MoveGroup:Toggle({ Title = "Speed Hack", Value = false, Callback = function(v) Settings.Speed = v; if v then task.spawn(SpeedLoop) end end })
    MoveGroup:Slider({ Title = "Speed", Value = {Min=16, Max=250, Default=50}, Callback = function(v) Settings.SpeedValue = v end })
    MoveGroup:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(v) Settings.Jump = v; if v then task.spawn(JumpLoop) end end })
    MoveGroup:Toggle({ Title = "No Clip", Value = false, Callback = function(v) Settings.NoClip = v; NoClipLoop() end })
    MoveGroup:Toggle({ Title = "Fly", Value = false, Callback = function(v) 
        Flying = v
        if v and not FlyConnection then
            FlyConnection = RunService.RenderStepped:Connect(FlyUpdate)
        elseif not v and FlyConnection then
            FlyConnection:Disconnect()
            FlyConnection = nil
        end
    end end)
    
    local VisualGroup = VisualTab:Group({ Title = "🎨 Visual" })
    VisualGroup:Toggle({ Title = "Chams (Azul)", Value = false, Callback = function(v)
        Settings.Chams = v
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then ApplyChams(p, v) end
        end
    end })
    VisualGroup:Toggle({ Title = "ESP", Value = false, Callback = function(v)
        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer then CreateESP(p) end
            end
            RunService.RenderStepped:Connect(UpdateESP)
        else
            for _, data in pairs(ESPs) do pcall(function() data[1]:Destroy() end) end
            ESPs = {}
        end
    end })
    
    local CreditsTab = Window:Tab({ Title = "CREDITS", Icon = "solar:star-bold-duotone" })
    CreditsTab:Button({ Title = "Water Hub Created By AdamABJ", Callback = function() end })
end

-- ============================================
-- INICIALIZAR
-- ============================================
StarterGui:SetCore("SendNotification", {Title = "Water Hub", Text = "✅ Cargado para Delta", Duration = 3})

print("=" .. string.rep("=", 40))
print("WATER HUB - DELTA EDITION")
print("Velocidad: H")
print("Jump infinito: J")
print("NoClip: N")
print("Fly: F")
print("=" .. string.rep("=", 40))

-- Controles con teclas para cuando no hay GUI visible
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.H then
        Settings.Speed = not Settings.Speed
        if Settings.Speed then task.spawn(SpeedLoop) end
        StarterGui:SetCore("SendNotification", {Title = "Water Hub", Text = "Speed: " .. (Settings.Speed and "ON" or "OFF"), Duration = 1})
    elseif input.KeyCode == Enum.KeyCode.J then
        Settings.Jump = not Settings.Jump
        if Settings.Jump then task.spawn(JumpLoop) end
        StarterGui:SetCore("SendNotification", {Title = "Water Hub", Text = "Infinite Jump: " .. (Settings.Jump and "ON" or "OFF"), Duration = 1})
    elseif input.KeyCode == Enum.KeyCode.N then
        Settings.NoClip = not Settings.NoClip
        NoClipLoop()
        StarterGui:SetCore("SendNotification", {Title = "Water Hub", Text = "No Clip: " .. (Settings.NoClip and "ON" or "OFF"), Duration = 1})
    elseif input.KeyCode == Enum.KeyCode.F then
        Flying = not Flying
        if Flying and not FlyConnection then
            FlyConnection = RunService.RenderStepped:Connect(FlyUpdate)
        elseif not Flying and FlyConnection then
            FlyConnection:Disconnect()
            FlyConnection = nil
        end
        StarterGui:SetCore("SendNotification", {Title = "Water Hub", Text = "Fly: " .. (Flying and "ON" or "OFF"), Duration = 1})
    end
end)

-- Detectar nuevos jugadores para ESP y Chams
Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then
        if Settings.Chams then ApplyChams(p, true) end
        if ESPs[p] then CreateESP(p) end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if ChamsObj[p] then ChamsObj[p]:Destroy() end
    if ESPs[p] then ESPs[p][1]:Destroy() end
end)

-- Aplicar Chams a jugadores existentes si la opción está activa
task.wait(1)
if Settings.Chams then
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then ApplyChams(p, true) end
    end
end
