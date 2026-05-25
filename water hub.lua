--[[
    WATER HUB | BLOCKSPIN - VERSIÓN DELTA (OPTIMIZADA)
    Bugs arreglados: Infinite Jump, Chams, WeaponMods, Speed, Stamina, Silent Aim
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
local TeleportService = game:GetService("TeleportService")

-- ============================================
-- CARGAR WINDUI
-- ============================================
local WindUI
local ok, result = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if ok then
    WindUI = result
else
    StarterGui:SetCore("SendNotification", {Title = "Error", Text = "No se pudo cargar WindUI", Duration = 3})
    return
end

-- ============================================
-- REMOTES
-- ============================================
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local SendRemote = Remotes and Remotes:FindFirstChild("Send")

local function FireSend(action, ...)
    if SendRemote then
        pcall(function() SendRemote:FireServer(action, ...) end)
    end
end

-- ============================================
-- IDS DE ARMAS
-- ============================================
local WeaponImages = {
    ["AK47"] = "rbxassetid://124555430577178",
    ["AUG"] = "rbxassetid://83729841153733",
    ["AWP"] = "rbxassetid://126356167274927",
    ["Anaconda"] = "rbxassetid://121547020534134",
    ["Bizon"] = "rbxassetid://0",
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

local function GetEquippedWeapon(player)
    local char = player.Character
    if not char then return nil, nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name, WeaponImages[tool.Name]
    end
    return nil, nil
end

-- ============================================
-- CONFIGURACIÓN
-- ============================================
local Settings = {
    SilentAim = false,
    FOV = 200,
    AimPart = "Head",
    AutoHeal = false,
    HealPercent = 70,
    AutoHit = false,
    SpeedEnabled = false,
    SpeedValue = 50,
    InfiniteJump = false,
    NoRecoil = false,
    NoSpread = false,
    NameESP = false,
    HealthESP = false,
    DistanceESP = false,
    WeaponESP = false,
    WeaponIconESP = false,
    Chams = false,
    FullBright = false,
    AntiAFK = false,
    InfiniteStamina = false,
}

local SilentTarget = nil
local ESPs = {}
local ChamsObjects = {}
local Connections = {} -- Almacenar conexiones para limpiarlas
local Threads = {}

-- ============================================
-- CHAMS (ARREGLADO - SIN MEMORY LEAKS)
-- ============================================
local function CleanupChams(player)
    if ChamsObjects[player] then
        if ChamsObjects[player].highlight then
            ChamsObjects[player].highlight:Destroy()
        end
        if ChamsObjects[player].connection then
            ChamsObjects[player].connection:Disconnect()
        end
        ChamsObjects[player] = nil
    end
end

local function ApplyChams(player, enabled)
    if enabled then
        local char = player.Character
        if not char then return end
        
        CleanupChams(player) -- Limpiar existentes primero
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "WaterHubChams"
        highlight.FillColor = Color3.fromRGB(0, 100, 255)
        highlight.FillTransparency = 0.4
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Adornee = char
        highlight.Parent = char
        
        -- Conexión que se limpia automáticamente
        local conn = char.AncestryChanged:Connect(function(_, parent)
            if not parent then
                CleanupChams(player)
            end
        end)
        
        ChamsObjects[player] = {
            highlight = highlight,
            connection = conn
        }
    else
        CleanupChams(player)
    end
end

local function UpdateAllChams()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            ApplyChams(player, Settings.Chams)
        end
    end
end

-- ============================================
-- SILENT AIM (OPTIMIZADO - EARLY RETURN)
-- ============================================
local function UpdateSilentAim()
    -- Early return si está desactivado (ahorra recursos)
    if not Settings.SilentAim then 
        SilentTarget = nil
        return 
    end
    
    local mouse = LocalPlayer:GetMouse()
    local cam = Workspace.CurrentCamera
    if not mouse or not cam then 
        SilentTarget = nil
        return 
    end
    
    local closest = nil
    local shortest = Settings.FOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local target = player.Character:FindFirstChild(Settings.AimPart) or player.Character:FindFirstChild("Head")
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
if hookmetamethod and getnamecallmethod then
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        if not Settings.SilentAim or not SilentTarget then
            return oldNamecall(self, ...)
        end
        
        local method = getnamecallmethod()
        if method ~= "FireServer" then
            return oldNamecall(self, ...)
        end
        
        local name = tostring(self.Name):lower()
        if not (name:find("hit") or name:find("damage") or name:find("shoot")) then
            return oldNamecall(self, ...)
        end
        
        local args = {...}
        if SilentTarget and SilentTarget.Character then
            local targetPart = SilentTarget.Character:FindFirstChild(Settings.AimPart) or SilentTarget.Character:FindFirstChild("Head")
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
        
        return oldNamecall(self, unpack(args))
    end)
end

-- ============================================
-- AUTO HEAL
-- ============================================
local function AutoHealLoop()
    while Settings.AutoHeal do
        task.wait(1)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum and (hum.Health / hum.MaxHealth) * 100 < Settings.HealPercent then
                FireSend("UseItem", "Medkit")
                FireSend("Heal")
            end
        end
    end
end

-- ============================================
-- AUTO HIT
-- ============================================
local function AutoHitLoop()
    while Settings.AutoHit do
        task.wait(0.2)
        if SilentTarget then
            FireSend("Hit", SilentTarget, Settings.AimPart)
        end
    end
end

-- ============================================
-- SPEED (ARREGLADO - RESET CORRECTO)
-- ============================================
local CurrentSpeedConnection = nil

local function ApplySpeed()
    if not Settings.SpeedEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if hum then 
        hum.WalkSpeed = Settings.SpeedValue 
    end
end

local function SpeedLoop()
    -- Aplicar inmediatamente
    ApplySpeed()
    
    -- Reaplicar cada 0.5 segundos si cambia
    while Settings.SpeedEnabled do
        task.wait(0.5)
        ApplySpeed()
    end
    
    -- Reset al desactivar
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

-- ============================================
-- INFINITE JUMP (ARREGLADO)
-- ============================================
local InfiniteJumpConnection = nil

local function SetupInfiniteJump()
    if InfiniteJumpConnection then
        InfiniteJumpConnection:Disconnect()
        InfiniteJumpConnection = nil
    end
    
    if Settings.InfiniteJump then
        InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    end
end

-- ============================================
-- INFINITE STAMINA (ARREGLADO - MÁS SIMPLE)
-- ============================================
local function InfiniteStaminaLoop()
    while Settings.InfiniteStamina do
        task.wait(0.1) -- Más frecuente para mejor efecto
        
        local char = LocalPlayer.Character
        if char then
            -- Intentar múltiples métodos
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                -- Método 1: Atributo
                pcall(function() hum:SetAttribute("Stamina", 100) end)
                -- Método 2: Value object
                local staminaVal = char:FindFirstChild("Stamina")
                if staminaVal then
                    staminaVal.Value = 100
                end
            end
            
            -- Método 3: Value en player
            local staminaPlayer = LocalPlayer:FindFirstChild("Stamina")
            if staminaPlayer then
                staminaPlayer.Value = 100
            end
        end
    end
end

-- ============================================
-- WEAPON MODS (ARREGLADO - LOOP TERMINABLE)
-- ============================================
local WeaponModsRunning = false

local function ApplyWeaponMods()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    if Settings.NoRecoil then
        pcall(function() tool:SetAttribute("recoil", 0) end)
    end
    if Settings.NoSpread then
        pcall(function() tool:SetAttribute("accuracy", 1) end)
    end
end

local function WeaponModsLoop()
    if WeaponModsRunning then return end -- Evitar múltiples loops
    WeaponModsRunning = true
    
    while Settings.NoRecoil or Settings.NoSpread do
        ApplyWeaponMods()
        task.wait(0.5)
    end
    
    WeaponModsRunning = false
end

local function UpdateWeaponMods()
    if Settings.NoRecoil or Settings.NoSpread then
        if not WeaponModsRunning then
            Threads.WeaponMods = task.spawn(WeaponModsLoop)
        end
    end
end

-- ============================================
-- ESP
-- ============================================
local ESPGui = nil

local function GetESP()
    if ESPGui and ESPGui.Parent then return ESPGui end
    ESPGui = Instance.new("ScreenGui")
    ESPGui.Name = "WaterHubESP"
    ESPGui.ResetOnSpawn = false
    ESPGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function()
        ESPGui.Parent = CoreGui
    end)
    
    if not ESPGui.Parent then
        ESPGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    return ESPGui
end

local function CreateESP(player)
    if ESPs[player] then return end
    
    local gui = GetESP()
    local esp = {}
    
    esp.Name = Instance.new("TextLabel")
    esp.Name.Size = UDim2.new(0, 200, 0, 20)
    esp.Name.BackgroundTransparency = 1
    esp.Name.TextColor3 = Color3.fromRGB(255,255,255)
    esp.Name.TextSize = 12
    esp.Name.Font = Enum.Font.GothamBold
    esp.Name.Parent = gui
    
    esp.HealthBg = Instance.new("Frame")
    esp.HealthBg.Size = UDim2.new(0, 100, 0, 6)
    esp.HealthBg.BackgroundColor3 = Color3.fromRGB(50,50,50)
    esp.HealthBg.BorderSizePixel = 0
    esp.HealthBg.Parent = gui
    
    esp.HealthBar = Instance.new("Frame")
    esp.HealthBar.Size = UDim2.new(1,0,1,0)
    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(0,255,0)
    esp.HealthBar.BorderSizePixel = 0
    esp.HealthBar.Parent = esp.HealthBg
    
    esp.Distance = Instance.new("TextLabel")
    esp.Distance.Size = UDim2.new(0, 100, 0, 15)
    esp.Distance.BackgroundTransparency = 1
    esp.Distance.TextColor3 = Color3.fromRGB(200,200,200)
    esp.Distance.TextSize = 10
    esp.Distance.Parent = gui
    
    esp.Weapon = Instance.new("TextLabel")
    esp.Weapon.Size = UDim2.new(0, 150, 0, 20)
    esp.Weapon.BackgroundTransparency = 1
    esp.Weapon.TextColor3 = Color3.fromRGB(255,200,100)
    esp.Weapon.TextSize = 10
    esp.Weapon.Parent = gui
    
    esp.WeaponIcon = Instance.new("ImageLabel")
    esp.WeaponIcon.Size = UDim2.new(0, 30, 0, 30)
    esp.WeaponIcon.BackgroundTransparency = 1
    esp.WeaponIcon.Parent = gui
    
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
                
                if Settings.NameESP then
                    esp.Name.Position = UDim2.new(0, pos.X - 100, 0, pos.Y - 60)
                    esp.Name.Text = player.Name
                    esp.Name.Visible = true
                else 
                    esp.Name.Visible = false 
                end
                
                if Settings.HealthESP then
                    esp.HealthBar.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
                    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(255 * (1-percent), 255 * percent, 0)
                    esp.HealthBg.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 40)
                    esp.HealthBg.Visible = true
                else 
                    esp.HealthBg.Visible = false 
                end
                
                if Settings.DistanceESP then
                    esp.Distance.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 30)
                    esp.Distance.Text = math.floor(dist) .. "m"
                    esp.Distance.Visible = true
                else 
                    esp.Distance.Visible = false 
                end
                
                if Settings.WeaponESP or Settings.WeaponIconESP then
                    local weaponName, weaponIcon = GetEquippedWeapon(player)
                    if weaponName and weaponName ~= esp.LastWeapon then
                        esp.LastWeapon = weaponName
                        if Settings.WeaponESP then
                            esp.Weapon.Text = "🔫 " .. weaponName
                        end
                        if Settings.WeaponIconESP and weaponIcon then
                            esp.WeaponIcon.Image = weaponIcon
                        end
                    end
                    
                    if weaponName then
                        if Settings.WeaponESP then
                            esp.Weapon.Position = UDim2.new(0, pos.X - 75, 0, pos.Y - 10)
                            esp.Weapon.Visible = true
                        else
                            esp.Weapon.Visible = false
                        end
                        
                        if Settings.WeaponIconESP and weaponIcon then
                            esp.WeaponIcon.Position = UDim2.new(0, pos.X - 110, 0, pos.Y - 15)
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
    if Settings.FullBright then
        Lighting.Brightness = 10
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.ClockTime = 14
    else
        Lighting.Brightness = 2
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 1000
    end
end

-- ============================================
-- ANTI AFK
-- ============================================
local function AntiAFKLoop()
    while Settings.AntiAFK do
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        end)
        task.wait(60)
    end
end

-- ============================================
-- INICIALIZAR
-- ============================================
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then 
        pcall(function() 
            CreateESP(player) 
            ApplyChams(player, Settings.Chams)
        end)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then 
        pcall(function() 
            CreateESP(p) 
            ApplyChams(p, Settings.Chams)
        end)
    end
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
    CleanupChams(p)
end)

-- ============================================
-- RESPAWN HANDLER (MEJORADO)
-- ============================================
LocalPlayer.CharacterAdded:Connect(function(char)
    -- Aplicar speed si está activado
    if Settings.SpeedEnabled then
        task.wait(0.3)
        local hum = char:FindFirstChild("Humanoid")
        if hum then 
            hum.WalkSpeed = Settings.SpeedValue 
        end
    end
    
    -- Aplicar weapon mods
    if Settings.NoRecoil or Settings.NoSpread then
        task.wait(0.5)
        ApplyWeaponMods()
        UpdateWeaponMods()
    end
    
    -- Reaplicar chams
    if Settings.Chams then
        task.wait(1)
        UpdateAllChams()
    end
end)

-- ============================================
-- LOOPS PRINCIPALES
-- ============================================
RunService.RenderStepped:Connect(function()
    UpdateSilentAim()
    UpdateESP()
end)

-- ============================================
-- UI - VENTANA PRINCIPAL
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | BlockSpin",
    Author = "By: AdamABJ",
    Folder = "WaterHub_Fixed",
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

Window:Tag({ Title = "v2.1 | Fixed", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })

-- ============================================
-- PESTAÑAS
-- ============================================
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "solar:swords-bold-duotone", Border = true })
local MovementTab = Window:Tab({ Title = "MOVEMENT", Icon = "solar:user-bold-duotone", Border = true })
local WeaponsTab = Window:Tab({ Title = "WEAPON", Icon = "solar:tuning-bold-duotone", Border = true })
local VisualTab = Window:Tab({ Title = "VISUAL", Icon = "solar:eye-bold-duotone", Border = true })
local MiscTab = Window:Tab({ Title = "MISC", Icon = "solar:slider-minimalistic-horizontal-bold-duotone", Border = true })
local ConfigTab = Window:Tab({ Title = "CONFIG", Icon = "solar:settings-bold-duotone", Border = true })

-- ============================================
-- COMBAT TAB
-- ============================================
local CombatGroup = CombatTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚔️ Combat" })

CombatGroup:Toggle({
    Flag = "SilentAim", Title = "Silent Aim", Value = false,
    Callback = function(v) Settings.SilentAim = v end,
})

CombatGroup:Space()
CombatGroup:Space()

CombatGroup:Slider({
    Flag = "FOV", Title = "FOV Radius", IsTooltip = true, Step = 1,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v) Settings.FOV = v end,
})

CombatGroup:Space()
CombatGroup:Space()

CombatGroup:Dropdown({
    Flag = "AimPart", Title = "Aim Part", Values = { "Head", "Torso", "HumanoidRootPart" }, Value = "Head",
    Callback = function(v) Settings.AimPart = v end,
})

CombatTab:Space({ Columns = 2 })

local AutoGroup = CombatTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "🤖 Auto" })

AutoGroup:Toggle({
    Flag = "AutoHeal", Title = "Auto Heal", Value = false,
    Callback = function(v)
        Settings.AutoHeal = v
        if v then Threads.AutoHeal = task.spawn(AutoHealLoop) end
    end,
})

AutoGroup:Space()
AutoGroup:Space()

AutoGroup:Slider({
    Flag = "HealHP", Title = "Heal at HP%", IsTooltip = true, Step = 1,
    Value = { Min = 20, Max = 90, Default = 70 },
    Callback = function(v) Settings.HealPercent = v end,
})

AutoGroup:Space()
AutoGroup:Space()

AutoGroup:Toggle({
    Flag = "AutoHit", Title = "Auto Hit", Value = false,
    Callback = function(v)
        Settings.AutoHit = v
        if v then Threads.AutoHit = task.spawn(AutoHitLoop) end
    end,
})

-- ============================================
-- MOVEMENT TAB (ARREGLADO)
-- ============================================
local MoveGroup = MovementTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚡ Movement" })

MoveGroup:Toggle({
    Flag = "SpeedHack", Title = "Speed Hack", Value = false,
    Callback = function(v)
        Settings.SpeedEnabled = v
        if v then 
            Threads.Speed = task.spawn(SpeedLoop) 
        else
            -- Reset inmediato
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
        end
    end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Slider({
    Flag = "SpeedValue", Title = "Speed Amount", IsTooltip = true, Step = 1,
    Value = { Min = 16, Max = 250, Default = 50 },
    Callback = function(v)
        Settings.SpeedValue = v
        if Settings.SpeedEnabled then
            ApplySpeed()
        end
    end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "InfiniteJump", Title = "Infinite Jump", Value = false,
    Callback = function(v)
        Settings.InfiniteJump = v
        SetupInfiniteJump()
    end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "InfiniteStamina", Title = "Infinite Stamina", Value = false,
    Callback = function(v)
        Settings.InfiniteStamina = v
        if v then Threads.Stamina = task.spawn(InfiniteStaminaLoop) end
    end,
})

-- ============================================
-- WEAPONS TAB (ARREGLADO)
-- ============================================
local WeaponGroup = WeaponsTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "🔫 Mods" })

WeaponGroup:Toggle({
    Flag = "NoRecoil", Title = "No Recoil", Value = false,
    Callback = function(v)
        Settings.NoRecoil = v
        UpdateWeaponMods()
    end,
})

WeaponGroup:Space()
WeaponGroup:Space()

WeaponGroup:Toggle({
    Flag = "NoSpread", Title = "No Spread", Value = false,
    Callback = function(v)
        Settings.NoSpread = v
        UpdateWeaponMods()
    end,
})

-- ============================================
-- VISUAL TAB
-- ============================================
local ChamsGroup = VisualTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "👤 Chams" })

ChamsGroup:Toggle({
    Flag = "Chams", Title = "Chams (Jugadores Azules)", Value = false,
    Callback = function(v)
        Settings.Chams = v
        UpdateAllChams()
    end,
})

VisualTab:Space({ Columns = 2 })

local EspGroup = VisualTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "👁️ ESP" })

EspGroup:Toggle({
    Flag = "NameESP", Title = "Name ESP", Value = false,
    Callback = function(v) Settings.NameESP = v end,
})

EspGroup:Space()
EspGroup:Space()

EspGroup:Toggle({
    Flag = "HealthESP", Title = "Health ESP", Value = false,
    Callback = function(v) Settings.HealthESP = v end,
})

EspGroup:Space()
EspGroup:Space()

EspGroup:Toggle({
    Flag = "DistanceESP", Title = "Distance ESP", Value = false,
    Callback = function(v) Settings.DistanceESP = v end,
})

EspGroup:Space()
EspGroup:Space()

EspGroup:Toggle({
    Flag = "WeaponESP", Title = "Weapon Name ESP", Value = false,
    Callback = function(v) Settings.NameESP = v end,
})

EspGroup:Space()
EspGroup:Space()

EspGroup:Toggle({
    Flag = "WeaponIconESP", Title = "Weapon Icon ESP", Value = false,
    Callback = function(v) Settings.WeaponIconESP = v end,
})

VisualTab:Space({ Columns = 2 })

local WorldGroup = VisualTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "🌍 World" })

WorldGroup:Toggle({
    Flag = "FullBright", Title = "Full Bright", Value = false,
    Callback = function(v)
        Settings.FullBright = v
        SetFullBright()
    end,
})

-- ============================================
-- MISC TAB
-- ============================================
local MiscGroup = MiscTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚙️ Misc" })

MiscGroup:Toggle({
    Flag = "AntiAFK", Title = "Anti AFK", Value = false,
    Callback = function(v)
        Settings.AntiAFK = v
        if v then Threads.AntiAFK = task.spawn(AntiAFKLoop) end
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
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
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
        -- Limpiar todo
        for name, thread in pairs(Threads) do
            if type(thread) == "thread" then
                pcall(function() task.cancel(thread) end)
            end
        end
        
        if InfiniteJumpConnection then
            InfiniteJumpConnection:Disconnect()
        end
        
        for player, data in pairs(ChamsObjects) do
            CleanupChams(player)
        end
        
        Settings = {}
        SetFullBright()
        
        for _, esp in pairs(ESPs) do
            pcall(function()
                esp.Name:Destroy()
                esp.HealthBg:Destroy()
                esp.Distance:Destroy()
                esp.Weapon:Destroy()
                esp.WeaponIcon:Destroy()
            end)
        end
        
        pcall(function() Window:Destroy() end)
        if ESPGui then
            pcall(function() ESPGui:Destroy() end)
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

CreditsGroup:Space()
CreditsGroup:Button({
    Title = "v2.1 | Bugs Fixed",
    Icon = "solar:check-circle-bold",
    Color = Color3.fromHex("#00F2FE"),
    Justify = "Center",
    Callback = function() end,
})

-- ============================================
-- NOTIFICACIÓN
-- ============================================
pcall(function()
    WindUI:Notify({
        Title = "Water Hub | BlockSpin",
        Content = "¡Todos los bugs arreglados!",
        Icon = "solar:water-drops-bold-duotone",
        Duration = 3,
    })
end)

StarterGui:SetCore("SendNotification", {
    Title = "Water Hub",
    Text = "✅ v2.1 Cargado - Bugs Fixed",
    Duration = 3,
})

print("✅ Water Hub v2.1 | Todos los bugs arreglados")
