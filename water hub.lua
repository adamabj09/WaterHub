--[[
    WATER HUB | BLOCKSPIN - VERSIÓN FINAL
    By: AdamABJ
    Con ESP de inventario (iconos reales de armas)
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

-- ============================================
-- CARGAR WINDUI
-- ============================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
if not WindUI then return end

-- ============================================
-- REMOTES REALES DE BLOCKSPIN
-- ============================================
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local SendRemote = Remotes and Remotes:FindFirstChild("Send")
local HitDetection = ReplicatedStorage:FindFirstChild("HitDetection")

local function FireSend(action, ...)
    if SendRemote then
        pcall(function() SendRemote:FireServer(action, ...) end)
    end
end

-- ============================================
-- IDs DE IMÁGENES DE ARMAS (PARA ESP)
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

local function GetWeaponImage(weaponName)
    return WeaponImages[weaponName] or "rbxassetid://0"
end

-- ============================================
-- VARIABLES GLOBALES
-- ============================================
local Features = {
    -- Combat
    SilentAim = false,
    FOV = 200,
    AimPart = "Head",
    AutoHeal = false,
    HealPercent = 70,
    AutoHit = false,
    
    -- Movement
    SpeedEnabled = false,
    SpeedValue = 50,
    InfiniteJump = false,
    NoClip = false,
    Fly = false,
    
    -- Weapons
    NoRecoil = false,
    NoSpread = false,
    RapidFire = false,
    
    -- ESP
    ESPName = false,
    ESPHealth = false,
    ESPDistance = false,
    ESPWeapon = false,
    ESPWeaponIcon = false,
    FullBright = false,
    
    -- Magneto
    Magneto = false,
    MagnetoRadius = 50,
    
    -- Misc
    AntiAFK = false,
}

local ESPs = {}
local SilentAimTarget = nil
local MagnetoItems = {}
local NoClipConnection = nil
local FlyConnection = nil
local Threads = {}

-- ============================================
-- FUNCIONES DE UTILIDAD
-- ============================================
local function GetEquippedWeapon(player)
    local char = player.Character
    if not char then return nil, nil end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name, GetWeaponImage(tool.Name)
    end
    
    return nil, nil
end

local function ApplyWeaponMods()
    local char = LocalPlayer.Character
    if not char then return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    if Features.NoRecoil then
        tool:SetAttribute("recoil", 0)
    end
    
    if Features.NoSpread then
        tool:SetAttribute("accuracy", 1)
    end
    
    if Features.RapidFire then
        tool:SetAttribute("fire_rate", 0)
    end
end

-- ============================================
-- ESP DE JUGADORES (CON ARMAS)
-- ============================================
local ESPGui = nil

local function GetESP()
    if ESPGui and ESPGui.Parent then return ESPGui end
    local sg = Instance.new("ScreenGui")
    sg.Name = "WaterHubESP"
    sg.ResetOnSpawn = false
    sg.Parent = CoreGui
    ESPGui = sg
    return sg
end

local function CreateESP(player)
    if ESPs[player] then return end
    
    local gui = GetESP()
    local esp = {}
    
    -- Nombre
    esp.Name = Instance.new("TextLabel")
    esp.Name.Size = UDim2.new(0, 200, 0, 20)
    esp.Name.BackgroundTransparency = 1
    esp.Name.TextColor3 = Color3.fromRGB(255, 255, 255)
    esp.Name.TextSize = 12
    esp.Name.Font = Enum.Font.GothamBold
    esp.Name.Parent = gui
    
    -- Barra de vida
    esp.HealthBg = Instance.new("Frame")
    esp.HealthBg.Size = UDim2.new(0, 100, 0, 6)
    esp.HealthBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    esp.HealthBg.BorderSizePixel = 0
    esp.HealthBg.Parent = gui
    
    esp.HealthBar = Instance.new("Frame")
    esp.HealthBar.Size = UDim2.new(1, 0, 1, 0)
    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    esp.HealthBar.BorderSizePixel = 0
    esp.HealthBar.Parent = esp.HealthBg
    
    -- Distancia
    esp.Distance = Instance.new("TextLabel")
    esp.Distance.Size = UDim2.new(0, 100, 0, 15)
    esp.Distance.BackgroundTransparency = 1
    esp.Distance.TextColor3 = Color3.fromRGB(200, 200, 200)
    esp.Distance.TextSize = 10
    esp.Distance.Font = Enum.Font.Gotham
    esp.Distance.Parent = gui
    
    -- Arma (texto)
    esp.Weapon = Instance.new("TextLabel")
    esp.Weapon.Size = UDim2.new(0, 150, 0, 20)
    esp.Weapon.BackgroundTransparency = 1
    esp.Weapon.TextColor3 = Color3.fromRGB(255, 200, 100)
    esp.Weapon.TextSize = 10
    esp.Weapon.Font = Enum.Font.GothamBold
    esp.Weapon.Parent = gui
    
    -- Icono del arma
    esp.WeaponIcon = Instance.new("ImageLabel")
    esp.WeaponIcon.Size = UDim2.new(0, 20, 0, 20)
    esp.WeaponIcon.BackgroundTransparency = 1
    esp.WeaponIcon.Parent = gui
    
    esp.LastWeapon = nil
    ESPs[player] = esp
end

local function UpdateESP()
    local camera = Workspace.CurrentCamera
    if not camera then return end
    
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myPos then myPos = myPos.Position end
    
    for player, esp in pairs(ESPs) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        if hrp and hum and hum.Health > 0 then
            local pos, onScreen = camera:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                local distance = myPos and (myPos - hrp.Position).Magnitude or 0
                local healthPercent = hum.Health / hum.MaxHealth
                
                -- Nombre
                if Features.ESPName then
                    esp.Name.Position = UDim2.new(0, pos.X - 100, 0, pos.Y - 50)
                    esp.Name.Text = player.Name
                    esp.Name.Visible = true
                else
                    esp.Name.Visible = false
                end
                
                -- Barra de vida
                if Features.ESPHealth then
                    esp.HealthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
                    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                    esp.HealthBg.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 30)
                    esp.HealthBg.Visible = true
                else
                    esp.HealthBg.Visible = false
                end
                
                -- Distancia
                if Features.ESPDistance then
                    esp.Distance.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 20)
                    esp.Distance.Text = math.floor(distance) .. "m"
                    esp.Distance.Visible = true
                else
                    esp.Distance.Visible = false
                end
                
                -- Arma equipada (con icono)
                if Features.ESPWeapon or Features.ESPWeaponIcon then
                    local weaponName, weaponIcon = GetEquippedWeapon(player)
                    
                    if weaponName and weaponName ~= esp.LastWeapon then
                        esp.LastWeapon = weaponName
                        if Features.ESPWeapon then
                            esp.Weapon.Text = "🔫 " .. weaponName
                        end
                        if Features.ESPWeaponIcon and weaponIcon then
                            esp.WeaponIcon.Image = weaponIcon
                        end
                    end
                    
                    if weaponName then
                        local yOffset = 0
                        
                        if Features.ESPWeapon then
                            esp.Weapon.Position = UDim2.new(0, pos.X - 75, 0, pos.Y + 10)
                            esp.Weapon.Visible = true
                            yOffset = 25
                        else
                            esp.Weapon.Visible = false
                        end
                        
                        if Features.ESPWeaponIcon and weaponIcon then
                            esp.WeaponIcon.Position = UDim2.new(0, pos.X - 95, 0, pos.Y + 10)
                            esp.WeaponIcon.Visible = true
                        else
                            esp.WeaponIcon.Visible = false
                        end
                    else
                        esp.Weapon.Visible = false
                        esp.WeaponIcon.Visible = false
                    end
                else
                    esp.Weapon.Visible = false
                    esp.WeaponIcon.Visible = false
                end
            else
                esp.Name.Visible = false
                esp.HealthBg.Visible = false
                esp.Distance.Visible = false
                esp.Weapon.Visible = false
                esp.WeaponIcon.Visible = false
            end
        else
            esp.Name.Visible = false
            esp.HealthBg.Visible = false
            esp.Distance.Visible = false
            esp.Weapon.Visible = false
            esp.WeaponIcon.Visible = false
        end
    end
end

-- ============================================
-- SILENT AIM
-- ============================================
local function SilentAimLoop()
    while Features.SilentAim do
        local mouse = LocalPlayer:GetMouse()
        local cam = Workspace.CurrentCamera
        if mouse and cam then
            local closest = nil
            local shortestDist = Features.FOV
            
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local targetPart = player.Character:FindFirstChild(Features.AimPart) or player.Character:FindFirstChild("Head")
                    local hum = player.Character:FindFirstChild("Humanoid")
                    
                    if targetPart and hum and hum.Health > 0 then
                        local pos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                            if dist < shortestDist then
                                shortestDist = dist
                                closest = player
                            end
                        end
                    end
                end
            end
            
            SilentAimTarget = closest
        end
        task.wait(0.05)
    end
end

-- ============================================
-- AUTO HEAL
-- ============================================
local function AutoHealLoop()
    while Features.AutoHeal do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum and (hum.Health / hum.MaxHealth) * 100 < Features.HealPercent then
                FireSend("UseItem", "Medkit")
                FireSend("Heal")
            end
        end
        task.wait(1)
    end
end

-- ============================================
-- AUTO HIT
-- ============================================
local function AutoHitLoop()
    while Features.AutoHit do
        if SilentAimTarget then
            FireSend("Hit", SilentAimTarget, Features.AimPart)
        end
        task.wait(0.2)
    end
end

-- ============================================
-- MOVEMENT LOOPS
-- ============================================
local function SpeedLoop()
    while Features.SpeedEnabled do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = Features.SpeedValue end
        end
        task.wait(0.1)
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

local function InfiniteJumpLoop()
    while Features.InfiniteJump do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Landed then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
        task.wait(0.1)
    end
end

local function NoClipLoop()
    if Features.NoClip then
        if NoClipConnection then return end
        NoClipConnection = RunService.Stepped:Connect(function()
            if not Features.NoClip then return end
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if NoClipConnection then
            NoClipConnection:Disconnect()
            NoClipConnection = nil
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

local function FlyLoop()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local speed = 50
    local keys = {W = false, A = false, S = false, D = false, Space = false, LeftShift = false}
    
    local keyDown = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then keys.W = true end
        if input.KeyCode == Enum.KeyCode.A then keys.A = true end
        if input.KeyCode == Enum.KeyCode.S then keys.S = true end
        if input.KeyCode == Enum.KeyCode.D then keys.D = true end
        if input.KeyCode == Enum.KeyCode.Space then keys.Space = true end
        if input.KeyCode == Enum.KeyCode.LeftShift then keys.LeftShift = true end
    end)
    
    local keyUp = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then keys.W = false end
        if input.KeyCode == Enum.KeyCode.A then keys.A = false end
        if input.KeyCode == Enum.KeyCode.S then keys.S = false end
        if input.KeyCode == Enum.KeyCode.D then keys.D = false end
        if input.KeyCode == Enum.KeyCode.Space then keys.Space = false end
        if input.KeyCode == Enum.KeyCode.LeftShift then keys.LeftShift = false end
    end)
    
    while Features.Fly do
        local cam = Workspace.CurrentCamera
        local direction = Vector3.new(0, 0, 0)
        
        if keys.W then direction = direction + cam.CFrame.LookVector end
        if keys.S then direction = direction - cam.CFrame.LookVector end
        if keys.A then direction = direction - cam.CFrame.RightVector end
        if keys.D then direction = direction + cam.CFrame.RightVector end
        if keys.Space then direction = direction + Vector3.new(0, 1, 0) end
        if keys.LeftShift then direction = direction - Vector3.new(0, 1, 0) end
        
        if direction.Magnitude > 0 then
            direction = direction.Unit * speed
            hrp.Velocity = direction
        else
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
        
        task.wait()
    end
    
    keyDown:Disconnect()
    keyUp:Disconnect()
end

-- ============================================
-- MAGNETO
-- ============================================
local function MagnetoLoop()
    while Features.Magneto do
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not MagnetoItems[part] then
                local isItem = part:GetAttribute("Item") or 
                              part.Name:find("Cash") or 
                              part.Name:find("Money") or
                              part.Name:find("Ammo") or
                              part:FindFirstChild("DroppedItem")
                
                if isItem and part.Parent and not part.Parent:FindFirstChild("Humanoid") then
                    MagnetoItems[part] = true
                    task.spawn(function()
                        while MagnetoItems[part] and Features.Magneto and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
                            local dist = (part.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                            if dist < Features.MagnetoRadius then
                                local dir = (LocalPlayer.Character.HumanoidRootPart.Position - part.Position).Unit
                                part.Velocity = dir * 60
                                part.AssemblyLinearVelocity = dir * 60
                            end
                            task.wait(0.1)
                        end
                    end)
                end
            end
        end
        task.wait(0.5)
    end
    MagnetoItems = {}
end

-- ============================================
-- ANTI AFK
-- ============================================
local function AntiAFKLoop()
    while Features.AntiAFK do
        local vu = game:GetService("VirtualUser")
        pcall(function()
            vu:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            vu:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        end)
        task.wait(60)
    end
end

-- ============================================
-- FULL BRIGHT
-- ============================================
local function SetFullBright()
    if Features.FullBright then
        Lighting.Brightness = 10
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    else
        Lighting.Brightness = 2
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 1000
    end
end

-- ============================================
-- WINDUI VENTANA PRINCIPAL
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | BlockSpin",
    Author = "By: AdamABJ",
    Folder = "WaterHub_AdamABJ",
    Icon = "solar:water-drops-bold-duotone",
    NewElements = true,
    HideSearchBar = false,
    OpenButton = {
        Title = "Open Water Hub",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.5,
        Color = ColorSequence.new(Color3.fromHex("#00F2FE"), Color3.fromHex("#4FACFE")),
    },
    Topbar = { Height = 44, ButtonsType = "Mac" },
})

Window:Tag({ Title = "v1.0 | By AdamABJ", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })

-- ============================================
-- PESTAÑAS
-- ============================================
local CombatTab = Window:Tab({ Title = "Combat", Icon = "solar:swords-bold-duotone", Border = true })
local MovementTab = Window:Tab({ Title = "Movement", Icon = "solar:user-bold-duotone", Border = true })
local WeaponsTab = Window:Tab({ Title = "Weapons", Icon = "solar:tuning-bold-duotone", Border = true })
local VisualTab = Window:Tab({ Title = "Visual", Icon = "solar:eye-bold-duotone", Border = true })
local MagnetoTab = Window:Tab({ Title = "Magneto", Icon = "solar:magnet-bold-duotone", Border = true })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "solar:slider-minimalistic-horizontal-bold-duotone", Border = true })

-- ============================================
-- COMBAT TAB
-- ============================================
local CombatGroup = CombatTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚔️ Combat" })

CombatGroup:Toggle({
    Flag = "SilentAim", Title = "Silent Aim", Value = false,
    Callback = function(v)
        Features.SilentAim = v
        if v then Threads.SilentAim = task.spawn(SilentAimLoop) else Threads.SilentAim = nil end
    end,
})

CombatGroup:Space()
CombatGroup:Space()

CombatGroup:Slider({
    Flag = "FOV", Title = "FOV Radius", IsTooltip = true, Step = 1,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v) Features.FOV = v end,
})

CombatGroup:Space()
CombatGroup:Space()

CombatGroup:Dropdown({
    Flag = "AimPart", Title = "Aim Part", Values = { "Head", "Torso", "HumanoidRootPart" }, Value = "Head",
    Callback = function(v) Features.AimPart = v end,
})

CombatTab:Space({ Columns = 2 })

local AutoGroup = CombatTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "🤖 Auto" })

AutoGroup:Toggle({
    Flag = "AutoHeal", Title = "Auto Heal", Value = false,
    Callback = function(v)
        Features.AutoHeal = v
        if v then Threads.AutoHeal = task.spawn(AutoHealLoop) else Threads.AutoHeal = nil end
    end,
})

AutoGroup:Space()
AutoGroup:Space()

AutoGroup:Slider({
    Flag = "HealHP", Title = "Heal at HP%", IsTooltip = true, Step = 1,
    Value = { Min = 20, Max = 90, Default = 70 },
    Callback = function(v) Features.HealPercent = v end,
})

AutoGroup:Space()
AutoGroup:Space()

AutoGroup:Toggle({
    Flag = "AutoHit", Title = "Auto Hit", Value = false,
    Callback = function(v)
        Features.AutoHit = v
        if v then Threads.AutoHit = task.spawn(AutoHitLoop) else Threads.AutoHit = nil end
    end,
})

-- ============================================
-- MOVEMENT TAB
-- ============================================
local MoveGroup = MovementTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚡ Movement" })

MoveGroup:Toggle({
    Flag = "SpeedHack", Title = "Speed Hack", Value = false,
    Callback = function(v)
        Features.SpeedEnabled = v
        if v then Threads.Speed = task.spawn(SpeedLoop) else Threads.Speed = nil end
    end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Slider({
    Flag = "SpeedValue", Title = "Speed Amount", IsTooltip = true, Step = 1,
    Value = { Min = 16, Max = 250, Default = 50 },
    Callback = function(v)
        Features.SpeedValue = v
        if Features.SpeedEnabled then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "InfiniteJump", Title = "Infinite Jump", Value = false,
    Callback = function(v)
        Features.InfiniteJump = v
        if v then Threads.Jump = task.spawn(InfiniteJumpLoop) else Threads.Jump = nil end
    end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "NoClip", Title = "No Clip", Value = false,
    Callback = function(v)
        Features.NoClip = v
        NoClipLoop()
    end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "Fly", Title = "Fly Mode", Value = false,
    Callback = function(v)
        Features.Fly = v
        if v then Threads.Fly = task.spawn(FlyLoop) else Threads.Fly = nil end
    end,
})

-- ============================================
-- WEAPONS TAB
-- ============================================
local WeaponGroup = WeaponsTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "🔫 Mods" })

WeaponGroup:Toggle({
    Flag = "NoRecoil", Title = "No Recoil", Value = false,
    Callback = function(v)
        Features.NoRecoil = v
        ApplyWeaponMods()
    end,
})

WeaponGroup:Space()
WeaponGroup:Space()

WeaponGroup:Toggle({
    Flag = "NoSpread", Title = "No Spread", Value = false,
    Callback = function(v)
        Features.NoSpread = v
        ApplyWeaponMods()
    end,
})

WeaponGroup:Space()
WeaponGroup:Space()

WeaponGroup:Toggle({
    Flag = "RapidFire", Title = "Rapid Fire", Value = false,
    Callback = function(v)
        Features.RapidFire = v
        ApplyWeaponMods()
    end,
})

-- ============================================
-- VISUAL TAB
-- ============================================
local EspGroup = VisualTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "👁️ ESP" })

EspGroup:Toggle({
    Flag = "NameESP", Title = "Name ESP", Value = false,
    Callback = function(v) Features.ESPName = v end,
})

EspGroup:Space()
EspGroup:Space()

EspGroup:Toggle({
    Flag = "HealthESP", Title = "Health ESP", Value = false,
    Callback = function(v) Features.ESPHealth = v end,
})

EspGroup:Space()
EspGroup:Space()

EspGroup:Toggle({
    Flag = "DistanceESP", Title = "Distance ESP", Value = false,
    Callback = function(v) Features.ESPDistance = v end,
})

EspGroup:Space()
EspGroup:Space()

EspGroup:Toggle({
    Flag = "WeaponESP", Title = "Weapon Name ESP", Value = false,
    Callback = function(v) Features.ESPWeapon = v end,
})

EspGroup:Space()
EspGroup:Space()

EspGroup:Toggle({
    Flag = "WeaponIconESP", Title = "Weapon Icon ESP", Value = false,
    Callback = function(v) Features.ESPWeaponIcon = v end,
})

VisualTab:Space({ Columns = 2 })

local WorldGroup = VisualTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "🌍 World" })

WorldGroup:Toggle({
    Flag = "FullBright", Title = "Full Bright", Value = false,
    Callback = function(v)
        Features.FullBright = v
        SetFullBright()
    end,
})

-- ============================================
-- MAGNETO TAB
-- ============================================
local MagnetoGroup = MagnetoTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "🧲 Magneto" })

MagnetoGroup:Toggle({
    Flag = "Magneto", Title = "Magneto (Attract Items)", Value = false,
    Callback = function(v)
        Features.Magneto = v
        if v then Threads.Magneto = task.spawn(MagnetoLoop) else Threads.Magneto = nil end
    end,
})

MagnetoGroup:Space()
MagnetoGroup:Space()

MagnetoGroup:Slider({
    Flag = "MagnetoRadius", Title = "Magneto Radius", IsTooltip = true, Step = 1,
    Value = { Min = 10, Max = 100, Default = 50 },
    Callback = function(v) Features.MagnetoRadius = v end,
})

-- ============================================
-- MISC TAB
-- ============================================
local MiscGroup = MiscTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚙️ Misc" })

MiscGroup:Toggle({
    Flag = "AntiAFK", Title = "Anti AFK", Value = false,
    Callback = function(v)
        Features.AntiAFK = v
        if v then Threads.AntiAFK = task.spawn(AntiAFKLoop) else Threads.AntiAFK = nil end
    end,
})

MiscGroup:Space()
MiscGroup:Space()

MiscGroup:Button({
    Title = "🔄 Rejoin Server",
    Icon = "solar:refresh-bold-duotone",
    Justify = "Left",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

-- ============================================
-- CRÉDITOS
-- ============================================
local CreditsGroup = MiscTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "📝 Credits" })

CreditsGroup:Button({
    Title = "Water Hub Created By AdamABJ",
    Icon = "solar:star-bold-duotone",
    Color = Color3.fromHex("#EF4F1D"),
    Justify = "Center",
    Callback = function() end,
})

-- ============================================
-- INICIALIZAR ESP
-- ============================================
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then CreateESP(player) end
end)

Players.PlayerRemoving:Connect(function(player)
    local esp = ESPs[player]
    if esp then
        pcall(function()
            esp.Name:Destroy()
            esp.HealthBg:Destroy()
            esp.Distance:Destroy()
            esp.Weapon:Destroy()
            esp.WeaponIcon:Destroy()
        end)
        ESPs[player] = nil
    end
end)

RunService.RenderStepped:Connect(UpdateESP)

-- ============================================
-- RESPAWN HANDLER
-- ============================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if Features.SpeedEnabled then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = Features.SpeedValue end
    end
    if Features.NoRecoil or Features.NoSpread or Features.RapidFire then
        ApplyWeaponMods()
    end
    if Features.NoClip then
        NoClipLoop()
    end
end)

-- ============================================
-- NOTIFICACIÓN
-- ============================================
WindUI:Notify({
    Title = "Water Hub | BlockSpin",
    Content = "¡Cargado con éxito! By: AdamABJ",
    Icon = "solar:water-drops-bold-duotone",
    Duration = 3,
})

print("✅ Water Hub | BlockSpin - Cargado correctamente")
print("🔫 24 armas con IDs cargadas para ESP de inventario")
