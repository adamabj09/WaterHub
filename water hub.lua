--[[
    WATER HUB | BLOCKSPIN - FINAL EDITION v3.0
    ✓ Círculo FOV visible y funcional
    ✓ Silent Aim con aim a la cabeza dentro del FOV
    ✓ Todas las tabs completas y funcionando
    ✓ Sin Fly/NoClip (anti-cheat del juego)
    ✓ Tema Verde/Azul profesional
    By: AdamABJ
--]]

if getgenv and getgenv().WaterHubLoaded then
    print("⚠️ Water Hub ya está cargado")
    return
end
if getgenv then getgenv().WaterHubLoaded = true end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")

local gethui = gethui or function() return CoreGui end

-- CARGAR WINDUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

if not WindUI then
    warn("Error cargando WindUI")
    return
end

-- NOTIFICACIONES
local function Notify(title, message)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = message,
            Duration = 3
        })
    end)
end

-- VARIABLES
local Features = {
    SilentAim = false,
    ShowFOV = false,
    FOV = 200,
    AimPart = "Head",
    AutoHeal = false,
    HealPercent = 70,
    AutoHit = false,
    ShootingDistance = 1500,
    
    SpeedEnabled = false,
    SpeedValue = 50,
    InfiniteJump = false,
    JumpMode = "Fly Jump",
    InfiniteStamina = false,
    
    Automatic = false,
    FireRate = 1000,
    NoRecoil = false,
    NoSpread = false,
    InstantReload = false,
    
    ESPName = false,
    ESPHealth = false,
    ESPDistance = false,
    ESPWeapon = false,
    Chams = false,
    FullBright = false,
    NoFog = false,
    
    AntiAFK = false,
}

local Threads = {}
local ESPObjects = {}
local ChamsObjects = {}
local SilentAimTarget = nil
local OldNamecall = nil
local InfiniteJumpConnection = nil
local FOVCircle = nil

-- FUNCIONES UTILIDAD
local function GetEquippedTool(player)
    local char = player.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or nil
end

local function GetMoney()
    local cash, bank = 0, 0
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local cashObj = leaderstats:FindFirstChild("Cash")
        local bankObj = leaderstats:FindFirstChild("Bank")
        if cashObj then cash = tonumber(cashObj.Value) or 0 end
        if bankObj then bank = tonumber(bankObj.Value) or 0 end
    end
    return cash, bank
end

-- FOV CIRCLE
local function CreateFOVCircle()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FOVCircle"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    screenGui.Parent = gethui()
    
    local circle = Instance.new("Frame")
    circle.Name = "Circle"
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = 0
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    circle.Size = UDim2.new(0, Features.FOV * 2, 0, Features.FOV * 2)
    circle.Visible = false
    circle.Parent = screenGui
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 255, 136)
    stroke.Thickness = 2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = circle
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle
    
    local bg = Instance.new("Frame")
    bg.Name = "BG"
    bg.BackgroundColor3 = Color3.fromRGB(0, 255, 136)
    bg.BackgroundTransparency = 0.9
    bg.BorderSizePixel = 0
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.Parent = circle
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(1, 0)
    bgCorner.Parent = bg
    
    local center = Instance.new("Frame")
    center.Name = "Center"
    center.BackgroundColor3 = Color3.fromRGB(0, 242, 254)
    center.BorderSizePixel = 0
    center.AnchorPoint = Vector2.new(0.5, 0.5)
    center.Position = UDim2.new(0.5, 0, 0.5, 0)
    center.Size = UDim2.new(0, 4, 0, 4)
    center.Parent = circle
    
    local centerCorner = Instance.new("UICorner")
    centerCorner.CornerRadius = UDim.new(1, 0)
    centerCorner.Parent = center
    
    FOVCircle = {Screen = screenGui, Circle = circle, Stroke = stroke}
    return FOVCircle
end

local function UpdateFOV()
    if not FOVCircle then CreateFOVCircle() end
    if FOVCircle then
        FOVCircle.Circle.Size = UDim2.new(0, Features.FOV * 2, 0, Features.FOV * 2)
        FOVCircle.Circle.Visible = Features.ShowFOV and Features.SilentAim
    end
end

-- SILENT AIM
RunService.RenderStepped:Connect(function()
    UpdateFOV()
    
    if not Features.SilentAim then
        SilentAimTarget = nil
        return
    end
    
    local mouse = LocalPlayer:GetMouse()
    local cam = Workspace.CurrentCamera
    if not mouse or not cam then 
        SilentAimTarget = nil
        return 
    end
    
    local screenCenter = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local closest = nil
    local shortestDist = Features.FOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(Features.AimPart) or player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            
            if targetPart and humanoid and humanoid.Health > 0 and hrp then
                local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if localHRP then
                    local dist = (hrp.Position - localHRP.Position).Magnitude
                    if dist > Features.ShootingDistance then continue end
                end
                
                local pos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local distFromCenter = (screenPos - screenCenter).Magnitude
                    
                    if distFromCenter < shortestDist then
                        shortestDist = distFromCenter
                        closest = player
                    end
                end
            end
        end
    end
    
    SilentAimTarget = closest
    
    if FOVCircle and Features.ShowFOV then
        if closest then
            FOVCircle.Stroke.Color = Color3.fromRGB(255, 50, 50)
        else
            FOVCircle.Stroke.Color = Color3.fromRGB(0, 255, 136)
        end
    end
end)

local function SetupSilentAim()
    if OldNamecall then return end
    
    OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if Features.SilentAim and method == "FireServer" and SilentAimTarget then
            local name = self.Name:lower()
            if name:find("hit") or name:find("damage") or name:find("shoot") or name:find("fire") or name:find("bullet") then
                local targetChar = SilentAimTarget.Character
                if targetChar then
                    local targetPart = targetChar:FindFirstChild(Features.AimPart) or targetChar:FindFirstChild("Head")
                    if targetPart then
                        for i = 1, #args do
                            if typeof(args[i]) == "Vector3" then
                                args[i] = targetPart.Position
                            elseif typeof(args[i]) == "CFrame" then
                                args[i] = CFrame.new(targetPart.Position)
                            elseif typeof(args[i]) == "Instance" and args[i]:IsA("BasePart") then
                                args[i] = targetPart
                            elseif typeof(args[i]) == "Player" then
                                args[i] = SilentAimTarget
                            end
                        end
                    end
                end
            end
        end
        
        return OldNamecall(self, unpack(args))
    end)
end

-- AUTO HEAL/HIT
local function AutoHealLoop()
    while Features.AutoHeal do
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local healthPercent = (hum.Health / hum.MaxHealth) * 100
                    if healthPercent < Features.HealPercent then
                        hum.Health = hum.MaxHealth
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end

local function AutoHitLoop()
    while Features.AutoHit do
        pcall(function()
            if SilentAimTarget and SilentAimTarget.Character then
                local char = LocalPlayer.Character
                if char then
                    local tool = char:FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                end
            end
        end)
        task.wait(0.1)
    end
end

-- MOVEMENT
local function SpeedLoop()
    while Features.SpeedEnabled do
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = Features.SpeedValue end
            end
        end)
        task.wait(0.1)
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

local function SetupInfiniteJump()
    if InfiniteJumpConnection then
        pcall(function() InfiniteJumpConnection:Disconnect() end)
        InfiniteJumpConnection = nil
    end
    
    if Features.InfiniteJump then
        InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            pcall(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end
            end)
        end)
    end
end

local function InfiniteStaminaLoop()
    while Features.InfiniteStamina do
        pcall(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum:SetAttribute("Stamina", 100)
                    local staminaVal = char:FindFirstChild("Stamina")
                    if staminaVal then staminaVal.Value = 100 end
                end
            end
        end)
        task.wait(0.2)
    end
end

-- WEAPON MODS
local function ApplyWeaponMods()
    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        
        for _, obj in ipairs(char:GetDescendants()) do
            if obj:IsA("Tool") then
                if Features.NoRecoil then
                    local recoil = obj:FindFirstChild("Recoil") or obj:FindFirstChild("RecoilValue")
                    if recoil then recoil.Value = 0 end
                end
                if Features.NoSpread then
                    local spread = obj:FindFirstChild("Spread") or obj:FindFirstChild("SpreadValue")
                    if spread then spread.Value = 0 end
                end
                if Features.Automatic then
                    local auto = obj:FindFirstChild("Automatic")
                    if auto then auto.Value = true end
                end
                local fireRate = obj:FindFirstChild("FireRate") or obj:FindFirstChild("Cooldown")
                if fireRate then fireRate.Value = 60 / Features.FireRate end
            end
        end
    end)
end

-- ESP
local ESPGui = nil

local function GetESPGui()
    if ESPGui and ESPGui.Parent then return ESPGui end
    local sg = Instance.new("ScreenGui")
    sg.Name = "ESP"
    sg.ResetOnSpawn = false
    sg.Parent = gethui()
    ESPGui = sg
    return sg
end

local function CreateESP(player)
    if ESPObjects[player] then return end
    
    local gui = GetESPGui()
    local esp = {}
    
    esp.Name = Instance.new("TextLabel")
    esp.Name.Size = UDim2.new(0, 200, 0, 20)
    esp.Name.BackgroundTransparency = 1
    esp.Name.TextColor3 = Color3.fromRGB(255, 255, 255)
    esp.Name.TextSize = 12
    esp.Name.Font = Enum.Font.GothamBold
    esp.Name.Parent = gui
    
    esp.HealthBg = Instance.new("Frame")
    esp.HealthBg.Size = UDim2.new(0, 100, 0, 6)
    esp.HealthBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    esp.HealthBg.BorderSizePixel = 0
    esp.HealthBg.Parent = gui
    
    esp.HealthBar = Instance.new("Frame")
    esp.HealthBar.Size = UDim2.new(1, 0, 1, 0)
    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    esp.HealthBar.BorderSizePixel = 0
    esp.HealthBar.Parent = esp.HealthBg
    
    esp.Distance = Instance.new("TextLabel")
    esp.Distance.Size = UDim2.new(0, 100, 0, 15)
    esp.Distance.BackgroundTransparency = 1
    esp.Distance.TextColor3 = Color3.fromRGB(0, 242, 254)
    esp.Distance.TextSize = 10
    esp.Distance.Font = Enum.Font.Gotham
    esp.Distance.Parent = gui
    
    esp.Weapon = Instance.new("TextLabel")
    esp.Weapon.Size = UDim2.new(0, 150, 0, 20)
    esp.Weapon.BackgroundTransparency = 1
    esp.Weapon.TextColor3 = Color3.fromRGB(0, 255, 150)
    esp.Weapon.TextSize = 10
    esp.Weapon.Font = Enum.Font.GothamBold
    esp.Weapon.Parent = gui
    
    esp.LastWeapon = nil
    ESPObjects[player] = esp
end

local function UpdateESP()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myPos then myPos = myPos.Position end
    
    for player, esp in pairs(ESPObjects) do
        pcall(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    if Features.ESPName then
                        esp.Name.Position = UDim2.new(0, pos.X - 100, 0, pos.Y - 50)
                        esp.Name.Text = player.Name
                        esp.Name.Visible = true
                    else
                        esp.Name.Visible = false
                    end
                    
                    if Features.ESPHealth then
                        local percent = hum.Health / hum.MaxHealth
                        esp.HealthBar.Size = UDim2.new(percent, 0, 1, 0)
                        esp.HealthBar.BackgroundColor3 = Color3.fromRGB(255 * (1-percent), 255 * percent, 100)
                        esp.HealthBg.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 30)
                        esp.HealthBg.Visible = true
                    else
                        esp.HealthBg.Visible = false
                    end
                    
                    if Features.ESPDistance and myPos then
                        local dist = (myPos - hrp.Position).Magnitude
                        esp.Distance.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 20)
                        esp.Distance.Text = math.floor(dist) .. "m"
                        esp.Distance.Visible = true
                    else
                        esp.Distance.Visible = false
                    end
                    
                    if Features.ESPWeapon then
                        local weapon = GetEquippedTool(player)
                        if weapon and weapon ~= esp.LastWeapon then
                            esp.LastWeapon = weapon
                            esp.Weapon.Text = "🔫 " .. weapon
                        end
                        if weapon then
                            esp.Weapon.Position = UDim2.new(0, pos.X - 75, 0, pos.Y - 10)
                            esp.Weapon.Visible = true
                        else
                            esp.Weapon.Visible = false
                        end
                    else
                        esp.Weapon.Visible = false
                    end
                else
                    esp.Name.Visible = false
                    esp.HealthBg.Visible = false
                    esp.Distance.Visible = false
                    esp.Weapon.Visible = false
                end
            else
                esp.Name.Visible = false
                esp.HealthBg.Visible = false
                esp.Distance.Visible = false
                esp.Weapon.Visible = false
            end
        end)
    end
end

-- CHAMS
local function SetChams(enabled)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if enabled then
                if not ChamsObjects[player] then
                    pcall(function()
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "Chams"
                        highlight.FillColor = Color3.fromRGB(0, 255, 100)
                        highlight.OutlineColor = Color3.fromRGB(0, 242, 254)
                        highlight.FillTransparency = 0.5
                        highlight.OutlineTransparency = 0
                        highlight.Adornee = player.Character
                        highlight.Parent = player.Character
                        ChamsObjects[player] = highlight
                    end)
                end
            else
                if ChamsObjects[player] then
                    pcall(function() ChamsObjects[player]:Destroy() end)
                    ChamsObjects[player] = nil
                end
            end
        end
    end
end

-- LIGHTING
local function SetFullBright(enabled)
    if enabled then
        Lighting.Brightness = 10
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    else
        Lighting.Brightness = 2
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 1000
    end
end

local function SetNoFog(enabled)
    if enabled then
        Lighting.FogEnd = 100000
    else
        Lighting.FogEnd = 1000
    end
end

-- ANTI AFK
local function AntiAFKLoop()
    while Features.AntiAFK do
        pcall(function()
            local vu = game:GetService("VirtualUser")
            vu:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        end)
        task.wait(60)
    end
end

-- WINDOW
local Window = WindUI:CreateWindow({
    Title = "Water Hub | BlockSpin",
    Author = "By: AdamABJ",
    Icon = "droplet",
    Theme = "Dark",
    NewElements = true,
    Transparent = true,
    ToggleKey = Enum.KeyCode.F,
    Acrylic = false,
    OpenButton = {
        Title = "Open Water Hub",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("#00FF88")),
            ColorSequenceKeypoint.new(0.5, Color3.fromHex("#00E5FF")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("#00B0FF"))
        }),
    },
})

Window:Tag({ 
    Title = "v3.0 | FOV Edition", 
    Icon = "target", 
    Color = Color3.fromHex("#00FF88"), 
    Border = true 
})

Notify("Water Hub", "✓ Script cargado correctamente")

-- TABS

-- COMBAT TAB
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "target" })

CombatTab:Section({ Title = "Aimbot", Desc = "Silent Aim con FOV" })

CombatTab:Toggle({
    Title = "Silent Aim",
    Value = false,
    Callback = function(v)
        Features.SilentAim = v
        if v then SetupSilentAim() end
        UpdateFOV()
        Notify("Silent Aim", v and "✓ ON" or "✗ OFF")
    end,
})

CombatTab:Toggle({
    Title = "Show FOV Circle",
    Value = false,
    Callback = function(v)
        Features.ShowFOV = v
        UpdateFOV()
    end,
})

CombatTab:Slider({
    Title = "FOV Size",
    Step = 10,
    Value = { Min = 50, Max = 400, Default = 200 },
    Callback = function(v) Features.FOV = v UpdateFOV() end,
})

CombatTab:Slider({
    Title = "Shooting Distance",
    Step = 100,
    Value = { Min = 100, Max = 3000, Default = 1500 },
    Callback = function(v) Features.ShootingDistance = v end,
})

CombatTab:Dropdown({
    Title = "Aim Part",
    Value = "Head",
    Values = { "Head", "HumanoidRootPart", "Torso" },
    Callback = function(v) Features.AimPart = v end,
})

CombatTab:Space({ Columns = 1 })

CombatTab:Section({ Title = "Auto Combat", Desc = "Automatización" })

CombatTab:Toggle({
    Title = "Auto Heal",
    Value = false,
    Callback = function(v)
        Features.AutoHeal = v
        if v then Threads.AutoHeal = task.spawn(AutoHealLoop) end
        Notify("Auto Heal", v and "✓ ON" or "✗ OFF")
    end,
})

CombatTab:Slider({
    Title = "Heal %",
    Step = 5,
    Value = { Min = 10, Max = 90, Default = 70 },
    Callback = function(v) Features.HealPercent = v end,
})

CombatTab:Toggle({
    Title = "Auto Hit",
    Value = false,
    Callback = function(v)
        Features.AutoHit = v
        if v then Threads.AutoHit = task.spawn(AutoHitLoop) end
        Notify("Auto Hit", v and "✓ ON" or "✗ OFF")
    end,
})

-- MOVEMENT TAB
local MovementTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })

MovementTab:Section({ Title = "Speed", Desc = "Velocidad" })

MovementTab:Toggle({
    Title = "Speed Hack",
    Value = false,
    Callback = function(v)
        Features.SpeedEnabled = v
        if v then Threads.Speed = task.spawn(SpeedLoop) end
        Notify("Speed", v and "✓ ON" or "✗ OFF")
    end,
})

MovementTab:Slider({
    Title = "Speed Value",
    Step = 5,
    Value = { Min = 16, Max = 200, Default = 50 },
    Callback = function(v) Features.SpeedValue = v end,
})

MovementTab:Space({ Columns = 1 })

MovementTab:Section({ Title = "Jump & Stamina", Desc = "Salto y energía" })

MovementTab:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(v)
        Features.InfiniteJump = v
        SetupInfiniteJump()
        Notify("Infinite Jump", v and "✓ ON" or "✗ OFF")
    end,
})

MovementTab:Dropdown({
    Title = "Jump Mode",
    Value = "Fly Jump",
    Values = { "Fly Jump", "Normal" },
    Callback = function(v) Features.JumpMode = v end,
})

MovementTab:Toggle({
    Title = "Infinite Stamina",
    Value = false,
    Callback = function(v)
        Features.InfiniteStamina = v
        if v then Threads.Stamina = task.spawn(InfiniteStaminaLoop) end
        Notify("Infinite Stamina", v and "✓ ON" or "✗ OFF")
    end,
})

-- WEAPON TAB
local WeaponTab = Window:Tab({ Title = "WEAPON", Icon = "crosshair" })

WeaponTab:Section({ Title = "Weapon Mods", Desc = "Modificaciones" })

WeaponTab:Toggle({
    Title = "No Recoil",
    Value = false,
    Callback = function(v)
        Features.NoRecoil = v
        ApplyWeaponMods()
        Notify("No Recoil", v and "✓ ON" or "✗ OFF")
    end,
})

WeaponTab:Toggle({
    Title = "No Spread",
    Value = false,
    Callback = function(v)
        Features.NoSpread = v
        ApplyWeaponMods()
        Notify("No Spread", v and "✓ ON" or "✗ OFF")
    end,
})

WeaponTab:Toggle({
    Title = "Automatic",
    Value = false,
    Callback = function(v)
        Features.Automatic = v
        ApplyWeaponMods()
        Notify("Automatic", v and "✓ ON" or "✗ OFF")
    end,
})

WeaponTab:Slider({
    Title = "Fire Rate (RPM)",
    Step = 50,
    Value = { Min = 100, Max = 3000, Default = 1000 },
    Callback = function(v) Features.FireRate = v ApplyWeaponMods() end,
})

-- VISUAL TAB
local VisualTab = Window:Tab({ Title = "VISUAL", Icon = "eye" })

VisualTab:Section({ Title = "ESP", Desc = "Ver jugadores" })

VisualTab:Toggle({
    Title = "Name ESP",
    Value = false,
    Callback = function(v)
        Features.ESPName = v
        Notify("Name ESP", v and "✓ ON" or "✗ OFF")
    end,
})

VisualTab:Toggle({
    Title = "Health ESP",
    Value = false,
    Callback = function(v)
        Features.ESPHealth = v
        Notify("Health ESP", v and "✓ ON" or "✗ OFF")
    end,
})

VisualTab:Toggle({
    Title = "Distance ESP",
    Value = false,
    Callback = function(v)
        Features.ESPDistance = v
        Notify("Distance ESP", v and "✓ ON" or "✗ OFF")
    end,
})

VisualTab:Toggle({
    Title = "Weapon ESP",
    Value = false,
    Callback = function(v)
        Features.ESPWeapon = v
        Notify("Weapon ESP", v and "✓ ON" or "✗ OFF")
    end,
})

VisualTab:Space({ Columns = 1 })

VisualTab:Section({ Title = "Chams", Desc = "Resaltar" })

VisualTab:Toggle({
    Title = "Chams",
    Value = false,
    Callback = function(v)
        Features.Chams = v
        SetChams(v)
        Notify("Chams", v and "✓ ON" or "✗ OFF")
    end,
})

VisualTab:Space({ Columns = 1 })

VisualTab:Section({ Title = "World", Desc = "Mundo" })

VisualTab:Toggle({
    Title = "Full Bright",
    Value = false,
    Callback = function(v)
        Features.FullBright = v
        SetFullBright(v)
        Notify("Full Bright", v and "✓ ON" or "✗ OFF")
    end,
})

VisualTab:Toggle({
    Title = "No Fog",
    Value = false,
    Callback = function(v)
        Features.NoFog = v
        SetNoFog(v)
        Notify("No Fog", v and "✓ ON" or "✗ OFF")
    end,
})

-- MISC TAB
local MiscTab = Window:Tab({ Title = "MISC", Icon = "settings" })

MiscTab:Section({ Title = "General", Desc = "Funciones" })

MiscTab:Toggle({
    Title = "Anti AFK",
    Value = false,
    Callback = function(v)
        Features.AntiAFK = v
        if v then Threads.AntiAFK = task.spawn(AntiAFKLoop) end
        Notify("Anti AFK", v and "✓ ON" or "✗ OFF")
    end,
})

MiscTab:Space({ Columns = 1 })

MiscTab:Section({ Title = "Account Info", Desc = "Tu cuenta" })

local CashLabel = MiscTab:Label({ Title = "💵 Cash: Loading..." })
local BankLabel = MiscTab:Label({ Title = "🏦 Bank: Loading..." })

task.spawn(function()
    while true do
        local cash, bank = GetMoney()
        pcall(function()
            CashLabel:Set("💵 Cash: $" .. cash)
            BankLabel:Set("🏦 Bank: $" .. bank)
        end)
        task.wait(2)
    end
end)

MiscTab:Space({ Columns = 1 })

MiscTab:Section({ Title = "Script", Desc = "Control" })

MiscTab:Button({
    Title = "Destroy UI",
    Callback = function()
        Features.SilentAim = false
        Features.ShowFOV = false
        Features.SpeedEnabled = false
        Features.AutoHeal = false
        Features.AutoHit = false
        Features.InfiniteJump = false
        Features.InfiniteStamina = false
        Features.Chams = false
        Features.FullBright = false
        Features.NoFog = false
        Features.AntiAFK = false
        
        SetChams(false)
        SetNoFog(false)
        SetFullBright(false)
        
        if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect() end
        if FOVCircle then FOVCircle.Screen:Destroy() end
        if ESPGui then ESPGui:Destroy() end
        
        Window:Destroy()
        if getgenv then getgenv().WaterHubLoaded = false end
        Notify("Water Hub", "✓ Destruido")
    end,
})

MiscTab:Button({
    Title = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

-- INICIALIZACIÓN
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end

Players.PlayerAdded:Connect(function(p) 
    task.wait(0.2)
    if p ~= LocalPlayer then CreateESP(p) end 
end)

Players.PlayerRemoving:Connect(function(p)
    if ESPObjects[p] then
        pcall(function()
            ESPObjects[p].Name:Destroy()
            ESPObjects[p].HealthBg:Destroy()
            ESPObjects[p].Distance:Destroy()
            ESPObjects[p].Weapon:Destroy()
        end)
        ESPObjects[p] = nil
    end
    if ChamsObjects[p] then
        pcall(function() ChamsObjects[p]:Destroy() end)
        ChamsObjects[p] = nil
    end
end)

RunService.RenderStepped:Connect(UpdateESP)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if Features.SpeedEnabled then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = Features.SpeedValue end
    end
    if Features.NoRecoil or Features.NoSpread or Features.Automatic then
        ApplyWeaponMods()
    end
end)

CombatTab:Select()
print("✅ Water Hub v3.0 - FUNCIONAL")
