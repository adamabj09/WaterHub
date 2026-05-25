--[[
    WATER HUB | BLOCKSPIN - VERSIÓN COMPLETA
    Basado en información extraída con Dex Explorer
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
local VirtualUser = game:GetService("VirtualUser")

-- ============================================
-- CARGAR WINDUI
-- ============================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
if not WindUI then
    StarterGui:SetCore("SendNotification", {Title = "Error", Text = "No se pudo cargar WindUI", Duration = 3})
    return
end

-- ============================================
-- REMOTES (ENCONTRADOS EN DEX)
-- ============================================
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local SendRemote = Remotes and Remotes:FindFirstChild("Send")
local GetRemote = Remotes and Remotes:FindFirstChild("Get")
local HitDetection = ReplicatedStorage:FindFirstChild("HitDetection")
local DamageClient = ReplicatedStorage:FindFirstChild("DamageClient")

-- ============================================
-- IDs DE ARMAS (EXTRAÍDOS CON DEX)
-- ============================================
local WeaponImages = {
    ["AK47"] = "rbxassetid://124555430577178",
    ["AUG"] = "rbxassetid://83729841153733",
    ["AWP"] = "rbxassetid://126356167274927",
    ["Anaconda"] = "rbxassetid://121547020534134",
    ["Bizon"] = "rbxassetid://0", -- Pendiente
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
-- MÓDULO DE STAMINA (ENCONTRADO EN DEX)
-- ============================================
local StaminaModule = ReplicatedStorage:FindFirstChild("Modules") and 
                      ReplicatedStorage.Modules:FindFirstChild("Game") and
                      ReplicatedStorage.Modules.Game:FindFirstChild("Skills") and
                      ReplicatedStorage.Modules.Game.Skills:FindFirstChild("stamina")

-- ============================================
-- CONSUMIBLES (ENCONTRADOS EN DEX)
-- ============================================
local Consumables = ReplicatedStorage:FindFirstChild("Items") and 
                    ReplicatedStorage.Items:FindFirstChild("consumable")

-- ============================================
-- FUNCIONES DE UTILIDAD
-- ============================================
local function FireSend(action, ...)
    if SendRemote then
        pcall(function() SendRemote:FireServer(action, ...) end)
    end
end

local function GetEquippedWeapon(player)
    local char = player.Character
    if not char then return nil, nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name, WeaponImages[tool.Name]
    end
    return nil, nil
end

local function ApplyWeaponMods()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    if _G.NoRecoil then
        tool:SetAttribute("recoil", 0)
    end
    if _G.NoSpread then
        tool:SetAttribute("accuracy", 1)
    end
    if _G.RapidFire then
        tool:SetAttribute("fire_rate", 0)
    end
end

local function SetInfiniteStamina(enabled)
    if enabled and StaminaModule then
        -- Modificar el módulo de stamina (requiere require)
        pcall(function()
            local stamina = require(StaminaModule)
            if stamina then
                -- Depende de la estructura del módulo
                for i, level in ipairs(stamina) do
                    if level.reward_info then
                        level.reward_info.stamina_capacity_increase = 1000
                        level.reward_info.stamina_regeneration_increase = 1000
                    end
                end
            end
        end)
    end
end

-- ============================================
-- VARIABLES GLOBALES
-- ============================================
_G = _G or {}
_G.SilentAim = false
_G.FOV = 200
_G.AimPart = "Head"
_G.AutoHeal = false
_G.HealPercent = 70
_G.AutoHit = false
_G.SpeedEnabled = false
_G.SpeedValue = 50
_G.InfiniteJump = false
_G.NoClip = false
_G.Fly = false
_G.NoRecoil = false
_G.NoSpread = false
_G.RapidFire = false
_G.NameESP = false
_G.HealthESP = false
_G.DistanceESP = false
_G.WeaponESP = false
_G.WeaponIconESP = false
_G.FullBright = false
_G.Magneto = false
_G.MagnetoRadius = 50
_G.AntiAFK = false
_G.InfiniteStamina = false
_G.AutoReload = false

local SilentTarget = nil
local ESPs = {}
local MagnetoItems = {}
local NoClipConn = nil
local FlyConnections = {}
local Threads = {}

-- ============================================
-- SILENT AIM
-- ============================================
local function UpdateSilentAim()
    if not _G.SilentAim then 
        SilentTarget = nil
        return 
    end
    
    local mouse = LocalPlayer:GetMouse()
    local cam = Workspace.CurrentCamera
    if not mouse or not cam then return end
    
    local closest = nil
    local shortest = _G.FOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local target = player.Character:FindFirstChild(_G.AimPart) or player.Character:FindFirstChild("Head")
            local hum = player.Character:FindFirstChild("Humanoid")
            if target and hum and hum.Health > 0 then
                local pos, onScreen = cam:WorldToViewportPoint(target.Position)
                if onScreen then
                    local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                    if dist < shortest then
                        shortest = dist
                        closest = player
                    end
                end
            end
        end
    end
    
    SilentTarget = closest
end

-- Hook para Silent Aim
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if _G.SilentAim and method == "FireServer" and SilentTarget then
        local name = self.Name:lower()
        if name:find("hit") or name:find("damage") or name:find("shoot") or name:find("fire") then
            if SilentTarget and SilentTarget.Character then
                local targetPart = SilentTarget.Character:FindFirstChild(_G.AimPart) or SilentTarget.Character:FindFirstChild("Head")
                if targetPart then
                    for i = 1, #args do
                        if typeof(args[i]) == "Vector3" then
                            args[i] = targetPart.Position
                        elseif typeof(args[i]) == "Instance" and args[i]:IsA("BasePart") then
                            args[i] = targetPart
                        elseif typeof(args[i]) == "Player" then
                            args[i] = SilentTarget
                        end
                    end
                end
            end
        end
    end
    
    return oldNamecall(self, unpack(args))
end)

-- ============================================
-- AUTO HEAL
-- ============================================
local function AutoHealLoop()
    while _G.AutoHeal do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum and (hum.Health / hum.MaxHealth) * 100 < _G.HealPercent then
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
    while _G.AutoHit do
        if SilentTarget then
            FireSend("Hit", SilentTarget, _G.AimPart)
        end
        task.wait(0.2)
    end
end

-- ============================================
-- MOVEMENT LOOPS
-- ============================================
local function SpeedLoop()
    while _G.SpeedEnabled do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = _G.SpeedValue end
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
    while _G.InfiniteJump do
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
    if _G.NoClip then
        if NoClipConn then return end
        NoClipConn = RunService.Stepped:Connect(function()
            if not _G.NoClip then return end
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

local function FlyLoop()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local speed = 50
    local keys = {W = false, A = false, S = false, D = false, Space = false, LeftShift = false}
    
    local function onInput(input, isDown)
        if input.KeyCode == Enum.KeyCode.W then keys.W = isDown end
        if input.KeyCode == Enum.KeyCode.A then keys.A = isDown end
        if input.KeyCode == Enum.KeyCode.S then keys.S = isDown end
        if input.KeyCode == Enum.KeyCode.D then keys.D = isDown end
        if input.KeyCode == Enum.KeyCode.Space then keys.Space = isDown end
        if input.KeyCode == Enum.KeyCode.LeftShift then keys.LeftShift = isDown end
    end
    
    FlyConnections.KeyDown = UserInputService.InputBegan:Connect(function(i) onInput(i, true) end)
    FlyConnections.KeyUp = UserInputService.InputEnded:Connect(function(i) onInput(i, false) end)
    
    while _G.Fly do
        local cam = Workspace.CurrentCamera
        local dir = Vector3.new(0, 0, 0)
        
        if keys.W then dir = dir + cam.CFrame.LookVector end
        if keys.S then dir = dir - cam.CFrame.LookVector end
        if keys.A then dir = dir - cam.CFrame.RightVector end
        if keys.D then dir = dir + cam.CFrame.RightVector end
        if keys.Space then dir = dir + Vector3.new(0, 1, 0) end
        if keys.LeftShift then dir = dir - Vector3.new(0, 1, 0) end
        
        if dir.Magnitude > 0 then
            hrp.Velocity = dir.Unit * speed
        else
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
        task.wait()
    end
    
    if FlyConnections.KeyDown then FlyConnections.KeyDown:Disconnect() end
    if FlyConnections.KeyUp then FlyConnections.KeyUp:Disconnect() end
    FlyConnections = {}
end

-- ============================================
-- INFINITE STAMINA
-- ============================================
local function InfiniteStaminaLoop()
    while _G.InfiniteStamina do
        local char = LocalPlayer.Character
        if char then
            local staminaVal = char:FindFirstChild("Stamina")
            if staminaVal and staminaVal:IsA("NumberValue") then
                staminaVal.Value = 100
            end
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum:SetAttribute("Stamina", 100)
            end
        end
        SetInfiniteStamina(true)
        task.wait(0.2)
    end
    SetInfiniteStamina(false)
end

-- ============================================
-- WEAPON MODS LOOP
-- ============================================
local function WeaponModsLoop()
    while _G.NoRecoil or _G.NoSpread or _G.RapidFire do
        ApplyWeaponMods()
        task.wait(0.5)
    end
end

-- ============================================
-- AUTO RELOAD
-- ============================================
local function AutoReloadLoop()
    while _G.AutoReload do
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local ammo = tool:GetAttribute("Ammo") or tool:GetAttribute("CurrentAmmo")
                if ammo and ammo <= 0 then
                    pcall(function() VirtualUser:ClickButton1(Vector2.new(0,0), Enum.UserInputType.Keyboard, Enum.KeyCode.R) end)
                end
            end
        end
        task.wait(0.5)
    end
end

-- ============================================
-- ESP DE JUGADORES
-- ============================================
local ESPGui = nil

local function GetESP()
    if ESPGui and ESPGui.Parent then return ESPGui end
    ESPGui = Instance.new("ScreenGui")
    ESPGui.Name = "WaterHubESP"
    ESPGui.ResetOnSpawn = false
    ESPGui.Parent = CoreGui
    return ESPGui
end

local function CreateESP(player)
    if ESPs[player] then return end
    
    local gui = GetESP()
    local esp = {}
    
    esp.Name = Instance.new("TextLabel", gui)
    esp.Name.Size = UDim2.new(0, 200, 0, 20)
    esp.Name.BackgroundTransparency = 1
    esp.Name.TextColor3 = Color3.fromRGB(255,255,255)
    esp.Name.TextSize = 12
    esp.Name.Font = Enum.Font.GothamBold
    
    esp.HealthBg = Instance.new("Frame", gui)
    esp.HealthBg.Size = UDim2.new(0, 100, 0, 6)
    esp.HealthBg.BackgroundColor3 = Color3.fromRGB(50,50,50)
    
    esp.HealthBar = Instance.new("Frame", esp.HealthBg)
    esp.HealthBar.Size = UDim2.new(1,0,1,0)
    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(0,255,0)
    
    esp.Distance = Instance.new("TextLabel", gui)
    esp.Distance.Size = UDim2.new(0, 100, 0, 15)
    esp.Distance.BackgroundTransparency = 1
    esp.Distance.TextColor3 = Color3.fromRGB(200,200,200)
    esp.Distance.TextSize = 10
    
    esp.Weapon = Instance.new("TextLabel", gui)
    esp.Weapon.Size = UDim2.new(0, 150, 0, 20)
    esp.Weapon.BackgroundTransparency = 1
    esp.Weapon.TextColor3 = Color3.fromRGB(255,200,100)
    esp.Weapon.TextSize = 10
    
    esp.WeaponIcon = Instance.new("ImageLabel", gui)
    esp.WeaponIcon.Size = UDim2.new(0, 20, 0, 20)
    esp.WeaponIcon.BackgroundTransparency = 1
    
    esp.LastWeapon = nil
    ESPs[player] = esp
end

local function UpdateESP()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myPos then myPos = myPos.Position end
    
    for player, esp in pairs(ESPs) do
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        
        if hrp and hum and hum.Health > 0 then
            local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
            
            if onScreen then
                local dist = myPos and (myPos - hrp.Position).Magnitude or 0
                local percent = hum.Health / hum.MaxHealth
                
                if _G.NameESP then
                    esp.Name.Position = UDim2.new(0, pos.X - 100, 0, pos.Y - 50)
                    esp.Name.Text = player.Name
                    esp.Name.Visible = true
                else esp.Name.Visible = false end
                
                if _G.HealthESP then
                    esp.HealthBar.Size = UDim2.new(percent, 0, 1, 0)
                    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(255 * (1-percent), 255 * percent, 0)
                    esp.HealthBg.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 30)
                    esp.HealthBg.Visible = true
                else esp.HealthBg.Visible = false end
                
                if _G.DistanceESP then
                    esp.Distance.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 20)
                    esp.Distance.Text = math.floor(dist) .. "m"
                    esp.Distance.Visible = true
                else esp.Distance.Visible = false end
                
                if _G.WeaponESP or _G.WeaponIconESP then
                    local weaponName, weaponIcon = GetEquippedWeapon(player)
                    if weaponName and weaponName ~= esp.LastWeapon then
                        esp.LastWeapon = weaponName
                        if _G.WeaponESP then
                            esp.Weapon.Text = "🔫 " .. weaponName
                        end
                        if _G.WeaponIconESP and weaponIcon then
                            esp.WeaponIcon.Image = weaponIcon
                        end
                    end
                    
                    if weaponName then
                        local yOff = 0
                        if _G.WeaponESP then
                            esp.Weapon.Position = UDim2.new(0, pos.X - 75, 0, pos.Y + 10)
                            esp.Weapon.Visible = true
                            yOff = 25
                        else
                            esp.Weapon.Visible = false
                        end
                        if _G.WeaponIconESP and weaponIcon then
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
-- FULL BRIGHT
-- ============================================
local function SetFullBright()
    if _G.FullBright then
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
-- MAGNETO
-- ============================================
local function MagnetoLoop()
    while _G.Magneto do
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
                        while MagnetoItems[part] and _G.Magneto and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
                            local dist = (part.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                            if dist < _G.MagnetoRadius then
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
    while _G.AntiAFK do
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        end)
        task.wait(60)
    end
end

-- ============================================
-- INICIALIZAR ESP
-- ============================================
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then CreateESP(p) end
end)

Players.PlayerRemoving:Connect(function(p)
    local esp = ESPs[p]
    if esp then
        pcall(function()
            esp.Name:Destroy()
            esp.HealthBg:Destroy()
            esp.Distance:Destroy()
            esp.Weapon:Destroy()
            esp.WeaponIcon:Destroy()
        end)
        ESPs[p] = nil
    end
end)

-- ============================================
-- RESPAWN HANDLER
-- ============================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if _G.SpeedEnabled then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = _G.SpeedValue end
    end
    if _G.NoRecoil or _G.NoSpread or _G.RapidFire then
        ApplyWeaponMods()
    end
    if _G.NoClip then
        NoClipLoop()
    end
end)

-- ============================================
-- ACTUALIZAR SILENT AIM
-- ============================================
RunService.RenderStepped:Connect(UpdateSilentAim)

-- ============================================
-- ACTUALIZAR ESP
-- ============================================
RunService.RenderStepped:Connect(UpdateESP)

-- ============================================
-- VENTANA PRINCIPAL (WINDUI)
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

Window:Tag({ Title = "v1.0 | Dex Edition", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })

-- ============================================
-- PESTAÑAS
-- ============================================
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "solar:swords-bold-duotone", Border = true })
local MovementTab = Window:Tab({ Title = "MOVEMENT", Icon = "solar:user-bold-duotone", Border = true })
local WeaponsTab = Window:Tab({ Title = "WEAPON", Icon = "solar:tuning-bold-duotone", Border = true })
local VisualTab = Window:Tab({ Title = "VISUAL", Icon = "solar:eye-bold-duotone", Border = true })
local MagnetoTab = Window:Tab({ Title = "MAGNETO", Icon = "solar:magnet-bold-duotone", Border = true })
local MiscTab = Window:Tab({ Title = "MISC", Icon = "solar:slider-minimalistic-horizontal-bold-duotone", Border = true })
local ConfigTab = Window:Tab({ Title = "CONFIG", Icon = "solar:settings-bold-duotone", Border = true })

-- ============================================
-- COMBAT TAB
-- ============================================
local CombatGroup = CombatTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚔️ Combat" })

CombatGroup:Toggle({
    Flag = "SilentAim", Title = "Silent Aim", Value = false,
    Callback = function(v) _G.SilentAim = v end,
})

CombatGroup:Space()
CombatGroup:Space()

CombatGroup:Slider({
    Flag = "FOV", Title = "FOV Radius", IsTooltip = true, Step = 1,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v) _G.FOV = v end,
})

CombatGroup:Space()
CombatGroup:Space()

CombatGroup:Dropdown({
    Flag = "AimPart", Title = "Aim Part", Values = { "Head", "Torso", "HumanoidRootPart" }, Value = "Head",
    Callback = function(v) _G.AimPart = v end,
})

CombatTab:Space({ Columns = 2 })

local AutoGroup = CombatTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "🤖 Auto" })

AutoGroup:Toggle({
    Flag = "AutoHeal", Title = "Auto Heal", Value = false,
    Callback = function(v)
        _G.AutoHeal = v
        if v then Threads.AutoHeal = task.spawn(AutoHealLoop) else Threads.AutoHeal = nil end
    end,
})

AutoGroup:Space()
AutoGroup:Space()

AutoGroup:Slider({
    Flag = "HealHP", Title = "Heal at HP%", IsTooltip = true, Step = 1,
    Value = { Min = 20, Max = 90, Default = 70 },
    Callback = function(v) _G.HealPercent = v end,
})

AutoGroup:Space()
AutoGroup:Space()

AutoGroup:Toggle({
    Flag = "AutoHit", Title = "Auto Hit", Value = false,
    Callback = function(v)
        _G.AutoHit = v
        if v then Threads.AutoHit = task.spawn(AutoHitLoop) else Threads.AutoHit = nil end
    end,
})

AutoGroup:Space()
AutoGroup:Space()

AutoGroup:Toggle({
    Flag = "AutoReload", Title = "Auto Reload", Value = false,
    Callback = function(v)
        _G.AutoReload = v
        if v then Threads.AutoReload = task.spawn(AutoReloadLoop) else Threads.AutoReload = nil end
    end,
})

-- ============================================
-- MOVEMENT TAB
-- ============================================
local MoveGroup = MovementTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚡ Movement" })

MoveGroup:Toggle({
    Flag = "SpeedHack", Title = "Speed Hack", Value = false,
    Callback = function(v)
        _G.SpeedEnabled = v
        if v then Threads.Speed = task.spawn(SpeedLoop) else Threads.Speed = nil end
    end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Slider({
    Flag = "SpeedValue", Title = "Speed Amount", IsTooltip = true, Step = 1,
    Value = { Min = 16, Max = 250, Default = 50 },
    Callback = function(v)
        _G.SpeedValue = v
        if _G.SpeedEnabled then
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
        _G.InfiniteJump = v
        if v then Threads.Jump = task.spawn(InfiniteJumpLoop) else Threads.Jump = nil end
    end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "InfiniteStamina", Title = "Infinite Stamina", Value = false,
    Callback = function(v)
        _G.InfiniteStamina = v
        if v then Threads.Stamina = task.spawn(InfiniteStaminaLoop) else Threads.Stamina = nil end
    end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "NoClip", Title = "No Clip", Value = false,
    Callback = function(v)
        _G.NoClip = v
        NoClipLoop()
    end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "Fly", Title = "Fly Mode", Value = false,
    Callback = function(v)
        _G.Fly = v
        if v then
            FlyConnections = {}
            Threads.Fly = task.spawn(FlyLoop)
        else
            Threads.Fly = nil
        end
    end,
})

-- ============================================
-- WEAPONS TAB
-- ============================================
local WeaponGroup = WeaponsTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "🔫 Mods" })

WeaponGroup:Toggle({
    Flag = "NoRecoil", Title = "No Recoil", Value = false,
    Callback = function(v)
        _G.NoRecoil = v
        if v and not Threads.WeaponMods then
            Threads.WeaponMods = task.spawn(WeaponModsLoop)
        elseif not v and not (_G.NoSpread or _G.RapidFire) then
            Threads.WeaponMods = nil
        end
    end,
})

WeaponGroup:Space()
WeaponGroup:Space()

WeaponGroup:Toggle({
    Flag = "NoSpread", Title = "No Spread", Value = false,
    Callback = function(v)
        _G.NoSpread = v
        if v and not Threads.WeaponMods then
            Threads.WeaponMods = task.spawn(WeaponModsLoop)
        elseif not v and not (_G.NoRecoil or _G.RapidFire) then
            Threads.WeaponMods = nil
        end
    end,
})

WeaponGroup:Space()
WeaponGroup:Space()

WeaponGroup:Toggle({
    Flag = "RapidFire", Title = "Rapid Fire", Value = false,
    Callback = function(v)
        _G.RapidFire = v
        if v and not Threads.WeaponMods then
            Threads.WeaponMods = task.spawn(WeaponModsLoop)
        elseif not v and not (_G.NoRecoil or _G.NoSpread) then
            Threads.WeaponMods = nil
        end
    end,
})

-- ============================================
-- VISUAL TAB
-- ============================================
local EspGroup = VisualTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "👁️ ESP" })

EspGroup:Toggle({
    Flag = "NameESP", Title = "Name ESP", Value = false,
    Callback = function(v) _G.NameESP = v end,
})

EspGroup:Space()
EspGroup:Space()

EspGroup:Toggle({
    Flag = "HealthESP", Title = "Health ESP", Value = false,
    Callback = function(v) _G.HealthESP = v end,
})

EspGroup:Space()
EspGroup:Space()

EspGroup:Toggle({
    Flag = "DistanceESP", Title = "Distance ESP", Value = false,
    Callback = function(v) _G.DistanceESP = v end,
})

EspGroup:Space()
EspGroup:Space()

EspGroup:Toggle({
    Flag = "WeaponESP", Title = "Weapon Name ESP", Value = false,
    Callback = function(v) _G.WeaponESP = v end,
})

EspGroup:Space()
EspGroup:Space()

EspGroup:Toggle({
    Flag = "WeaponIconESP", Title = "Weapon Icon ESP", Value = false,
    Callback = function(v) _G.WeaponIconESP = v end,
})

VisualTab:Space({ Columns = 2 })

local WorldGroup = VisualTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "🌍 World" })

WorldGroup:Toggle({
    Flag = "FullBright", Title = "Full Bright", Value = false,
    Callback = function(v)
        _G.FullBright = v
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
        _G.Magneto = v
        if v then Threads.Magneto = task.spawn(MagnetoLoop) else Threads.Magneto = nil end
    end,
})

MagnetoGroup:Space()
MagnetoGroup:Space()

MagnetoGroup:Slider({
    Flag = "MagnetoRadius", Title = "Magneto Radius", IsTooltip = true, Step = 1,
    Value = { Min = 10, Max = 100, Default = 50 },
    Callback = function(v) _G.MagnetoRadius = v end,
})

-- ============================================
-- MISC TAB
-- ============================================
local MiscGroup = MiscTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚙️ Misc" })

MiscGroup:Toggle({
    Flag = "AntiAFK", Title = "Anti AFK", Value = false,
    Callback = function(v)
        _G.AntiAFK = v
        if v then Threads.AntiAFK = task.spawn(AntiAFKLoop) else Threads.AntiAFK = nil end
    end,
})

-- ============================================
-- CONFIG TAB
-- ============================================
local ConfigGroup = ConfigTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚙️ Config" })

ConfigGroup:Button({
    Title = "🔄 Rejoin Server",
    Icon = "solar:refresh-bold-duotone",
    Justify = "Left",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

ConfigGroup:Space()
ConfigGroup:Space()

ConfigGroup:Button({
    Title = "💀 Destroy UI",
    Icon = "solar:logout-3-bold",
    Justify = "Left",
    Color = Color3.fromRGB(255, 70, 70),
    Callback = function()
        for _, thread in pairs(Threads) do
            pcall(function() task.cancel(thread) end)
        end
        NoClipLoop()
        SetFullBright()
        _G = {}
        Window:Destroy()
        for _, esp in pairs(ESPs) do
            pcall(function()
                esp.Name:Destroy()
                esp.HealthBg:Destroy()
                esp.Distance:Destroy()
                esp.Weapon:Destroy()
                esp.WeaponIcon:Destroy()
            end)
        end
        StarterGui:SetCore("SendNotification", {Title = "Water Hub", Text = "UI Destruida", Duration = 2})
    end,
})

-- ============================================
-- CRÉDITOS
-- ============================================
local CreditsGroup = ConfigTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "📝 Credits" })

CreditsGroup:Button({
    Title = "Water Hub Created By AdamABJ",
    Icon = "solar:star-bold-duotone",
    Color = Color3.fromHex("#EF4F1D"),
    Justify = "Center",
    Callback = function() end,
})

-- ============================================
-- NOTIFICACIÓN DE CARGA
-- ============================================
WindUI:Notify({
    Title = "Water Hub | BlockSpin",
    Content = "¡Cargado con éxito! By: AdamABJ",
    Icon = "solar:water-drops-bold-duotone",
    Duration = 3,
})

StarterGui:SetCore("SendNotification", {
    Title = "Water Hub",
    Text = "✅ Script cargado - Basado en Dex Explorer",
    Duration = 3,
})

print("=" .. string.rep("=", 50))
print("WATER HUB | BLOCKSPIN - VERSIÓN COMPLETA")
print("By: AdamABJ")
print("=" .. string.rep("=", 50))
print("📊 Información cargada desde Dex Explorer:")
print("   - Remotes encontrados:", SendRemote and "Send ✓" or "Send ✗")
print("   - Armas con IDs:", #WeaponImages)
print("   - Módulo de stamina:", StaminaModule and "✓" or "✗")
print("   - Consumibles:", Consumables and "✓" or "✗")
print("=" .. string.rep("=", 50))
print("🔫 ESP de inventario con", #WeaponImages, "iconos de armas")
print("🎯 Silent Aim, Auto Heal y Auto Hit funcionando")
print("💪 Infinite Stamina usando el módulo original")
print("=" .. string.rep("=", 50))
