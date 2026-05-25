--[[
    WATER HUB | BLOCKSPIN - VERSIÓN DELTA FINAL
    Librería WindUI Oficial
    By: AdamABJ
--]]

if getgenv and getgenv().WaterHubLoaded then
    print("⚠️ Water Hub ya está cargado")
    return
end
getgenv().WaterHubLoaded = true

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
-- CARGAR WINDUI OFICIAL
-- ============================================
local cloneref = (cloneref or clonereference or function(instance)
    return instance
end)

local ReplicatedStorageClone = cloneref(game:GetService("ReplicatedStorage"))
local RunServiceClone = cloneref(game:GetService("RunService"))

local WindUI

do
    local ok, result = pcall(function()
        return require("./src/Init")
    end)

    if ok then
        WindUI = result
    else
        if RunServiceClone:IsStudio() or not writefile then
            WindUI = require(ReplicatedStorageClone:WaitForChild("WindUI"):WaitForChild("Init"))
        else
            WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
        end
    end
end

if not WindUI then
    warn("❌ Error cargando WindUI")
    getgenv().WaterHubLoaded = false
    return
end

print("✅ WindUI Cargado Correctamente")

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
local Threads = {}
local ESPGui = nil

-- ============================================
-- CHAMS (SIN MEMORY LEAKS)
-- ============================================
local function CleanupChams(player)
    if ChamsObjects[player] then
        if ChamsObjects[player].highlight then
            pcall(function() ChamsObjects[player].highlight:Destroy() end)
        end
        if ChamsObjects[player].connection then
            pcall(function() ChamsObjects[player].connection:Disconnect() end)
        end
        ChamsObjects[player] = nil
    end
end

local function ApplyChams(player, enabled)
    if enabled then
        local char = player.Character
        if not char then return end
        
        CleanupChams(player)
        
        local highlight = Instance.new("Highlight")
        highlight.Name = "WaterHubChams"
        highlight.FillColor = Color3.fromRGB(0, 100, 255)
        highlight.FillTransparency = 0.4
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Adornee = char
        highlight.Parent = char
        
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
-- SILENT AIM (OPTIMIZADO)
-- ============================================
local function UpdateSilentAim()
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

-- Silent Aim Hook
local oldNamecall
pcall(function()
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
end)

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
-- SPEED (CORREGIDO)
-- ============================================
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
    ApplySpeed()
    while Settings.SpeedEnabled do
        task.wait(0.5)
        ApplySpeed()
    end
    
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

-- ============================================
-- INFINITE JUMP (CORREGIDO)
-- ============================================
local InfiniteJumpConnection = nil

local function SetupInfiniteJump()
    if InfiniteJumpConnection then
        pcall(function() InfiniteJumpConnection:Disconnect() end)
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
-- INFINITE STAMINA (CORREGIDO)
-- ============================================
local function InfiniteStaminaLoop()
    while Settings.InfiniteStamina do
        task.wait(0.1)
        
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                pcall(function() hum:SetAttribute("Stamina", 100) end)
                local staminaVal = char:FindFirstChild("Stamina")
                if staminaVal then
                    staminaVal.Value = 100
                end
            end
            
            local staminaPlayer = LocalPlayer:FindFirstChild("Stamina")
            if staminaPlayer then
                staminaPlayer.Value = 100
            end
        end
    end
end

-- ============================================
-- WEAPON MODS (CORREGIDO)
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
    if WeaponModsRunning then return end
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
local function GetESP()
    if ESPGui and ESPGui.Parent then return ESPGui end
    ESPGui = Instance.new("ScreenGui")
    ESPGui.Name = "WaterHubESP"
    ESPGui.ResetOnSpawn = false
    ESPGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    pcall(function() ESPGui.Parent = CoreGui end)
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
-- RESPAWN HANDLER
-- ============================================
LocalPlayer.CharacterAdded:Connect(function(char)
    if Settings.SpeedEnabled then
        task.wait(0.3)
        local hum = char:FindFirstChild("Humanoid")
        if hum then 
            hum.WalkSpeed = Settings.SpeedValue 
        end
    end
    
    if Settings.NoRecoil or Settings.NoSpread then
        task.wait(0.5)
        ApplyWeaponMods()
        UpdateWeaponMods()
    end
    
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
-- UI - WINDUI OFICIAL
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | BlockSpin",
    Author = "By: AdamABJ",
    Folder = "WaterHub_Final",
    Icon = "solar:water-drops-bold-duotone",
    Theme = "Dark",
    NewElements = true,
    Transparent = true,
    ToggleKey = Enum.KeyCode.F,
    Acrylic = true,
})

local Tag = Window:Tag({
    Title = "v2.1 | Delta Ready",
    Color = "Text",
})

-- ============================================
-- PESTAÑAS
-- ============================================
local CombatTab = Window:Tab({
    Title = "COMBAT",
    Icon = "solar:swords-bold-duotone",
})

local MovementTab = Window:Tab({
    Title = "MOVEMENT",
    Icon = "solar:user-bold-duotone",
})

local WeaponsTab = Window:Tab({
    Title = "WEAPON",
    Icon = "solar:tuning-bold-duotone",
})

local VisualTab = Window:Tab({
    Title = "VISUAL",
    Icon = "solar:eye-bold-duotone",
})

local MiscTab = Window:Tab({
    Title = "MISC",
    Icon = "solar:slider-minimalistic-horizontal-bold-duotone",
})

local ConfigTab = Window:Tab({
    Title = "CONFIG",
    Icon = "solar:settings-bold-duotone",
})

CombatTab:Select()

-- ============================================
-- COMBAT TAB
-- ============================================
CombatTab:Section({
    Title = "⚔️ Combat",
    Desc = "Sistemas de combate",
})

local CombatGroup = CombatTab:Group()

CombatGroup:Toggle({
    Title = "Silent Aim",
    Value = false,
    Callback = function(v) Settings.SilentAim = v end,
})

CombatGroup:Space({ Columns = 0.5 })

CombatGroup:Slider({
    Title = "FOV Radius",
    IsTooltip = true,
    Step = 1,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v) Settings.FOV = v end,
})

CombatGroup:Space({ Columns = 0.5 })

CombatGroup:Dropdown({
    Title = "Aim Part",
    Values = { "Head", "Torso", "HumanoidRootPart" },
    Value = "Head",
    Callback = function(v) Settings.AimPart = v end,
})

CombatTab:Space({ Columns = 2 })

CombatTab:Section({
    Title = "🤖 Auto",
    Desc = "Automatizaciones",
})

local AutoGroup = CombatTab:Group()

AutoGroup:Toggle({
    Title = "Auto Heal",
    Value = false,
    Callback = function(v)
        Settings.AutoHeal = v
        if v then Threads.AutoHeal = task.spawn(AutoHealLoop) end
    end,
})

AutoGroup:Space({ Columns = 0.5 })

AutoGroup:Slider({
    Title = "Heal at HP%",
    IsTooltip = true,
    Step = 1,
    Value = { Min = 20, Max = 90, Default = 70 },
    Callback = function(v) Settings.HealPercent = v end,
})

AutoGroup:Space({ Columns = 0.5 })

AutoGroup:Toggle({
    Title = "Auto Hit",
    Value = false,
    Callback = function(v)
        Settings.AutoHit = v
        if v then Threads.AutoHit = task.spawn(AutoHitLoop) end
    end,
})

-- ============================================
-- MOVEMENT TAB
-- ============================================
MovementTab:Section({
    Title = "⚡ Movement",
    Desc = "Sistemas de movimiento",
})

local MoveGroup = MovementTab:Group()

MoveGroup:Toggle({
    Title = "Speed Hack",
    Value = false,
    Callback = function(v)
        Settings.SpeedEnabled = v
        if v then 
            Threads.Speed = task.spawn(SpeedLoop) 
        else
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
        end
    end,
})

MoveGroup:Space({ Columns = 0.5 })

MoveGroup:Slider({
    Title = "Speed Amount",
    IsTooltip = true,
    Step = 1,
    Value = { Min = 16, Max = 250, Default = 50 },
    Callback = function(v)
        Settings.SpeedValue = v
        if Settings.SpeedEnabled then
            ApplySpeed()
        end
    end,
})

MoveGroup:Space({ Columns = 0.5 })

MoveGroup:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(v)
        Settings.InfiniteJump = v
        SetupInfiniteJump()
    end,
})

MoveGroup:Space({ Columns = 0.5 })

MoveGroup:Toggle({
    Title = "Infinite Stamina",
    Value = false,
    Callback = function(v)
        Settings.InfiniteStamina = v
        if v then Threads.Stamina = task.spawn(InfiniteStaminaLoop) end
    end,
})

-- ============================================
-- WEAPONS TAB
-- ============================================
WeaponsTab:Section({
    Title = "🔫 Weapon Mods",
    Desc = "Modificaciones",
})

local WeaponGroup = WeaponsTab:Group()

WeaponGroup:Toggle({
    Title = "No Recoil",
    Value = false,
    Callback = function(v)
        Settings.NoRecoil = v
        UpdateWeaponMods()
    end,
})

WeaponGroup:Space({ Columns = 0.5 })

WeaponGroup:Toggle({
    Title = "No Spread",
    Value = false,
    Callback = function(v)
        Settings.NoSpread = v
        UpdateWeaponMods()
    end,
})

-- ============================================
-- VISUAL TAB
-- ============================================
VisualTab:Section({
    Title = "👤 Chams",
    Desc = "Resaltar jugadores",
})

local ChamsGroup = VisualTab:Group()

ChamsGroup:Toggle({
    Title = "Enable Chams",
    Value = false,
    Callback = function(v)
        Settings.Chams = v
        UpdateAllChams()
    end,
})

VisualTab:Space({ Columns = 2 })

VisualTab:Section({
    Title = "👁️ ESP",
    Desc = "Información en pantalla",
})

local EspGroup = VisualTab:Group()

EspGroup:Toggle({
    Title = "Name ESP",
    Value = false,
    Callback = function(v) Settings.NameESP = v end,
})

EspGroup:Space({ Columns = 0.5 })

EspGroup:Toggle({
    Title = "Health ESP",
    Value = false,
    Callback = function(v) Settings.HealthESP = v end,
})

EspGroup:Space({ Columns = 0.5 })

EspGroup:Toggle({
    Title = "Distance ESP",
    Value = false,
    Callback = function(v) Settings.DistanceESP = v end,
})

EspGroup:Space({ Columns = 0.5 })

EspGroup:Toggle({
    Title = "Weapon ESP",
    Value = false,
    Callback = function(v) Settings.WeaponESP = v end,
})

EspGroup:Space({ Columns = 0.5 })

EspGroup:Toggle({
    Title = "Weapon Icon ESP",
    Value = false,
    Callback = function(v) Settings.WeaponIconESP = v end,
})

VisualTab:Space({ Columns = 2 })

VisualTab:Section({
    Title = "🌍 World",
    Desc = "Efectos globales",
})

local WorldGroup = VisualTab:Group()

WorldGroup:Toggle({
    Title = "Full Bright",
    Value = false,
    Callback = function(v)
        Settings.FullBright = v
        SetFullBright()
    end,
})

-- ============================================
-- MISC TAB
-- ============================================
MiscTab:Section({
    Title = "⚙️ Miscellaneous",
    Desc = "Otras opciones",
})

local MiscGroup = MiscTab:Group()

MiscGroup:Toggle({
    Title = "Anti AFK",
    Value = false,
    Callback = function(v)
        Settings.AntiAFK = v
        if v then Threads.AntiAFK = task.spawn(AntiAFKLoop) end
    end,
})

-- ============================================
-- CONFIG TAB
-- ============================================
ConfigTab:Section({
    Title = "⚙️ Server",
    Desc = "Servidor",
})

local ServerGroup = ConfigTab:Group()

ServerGroup:Button({
    Title = "Rejoin Server",
    Icon = "solar:refresh-bold-duotone",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

ServerGroup:Space({ Columns = 0.5 })

ServerGroup:Button({
    Title = "Copy Game ID",
    Icon = "solar:copy-bold",
    Callback = function()
        setclipboard(tostring(game.PlaceId))
        WindUI:Notify({
            Title = "Copiado",
            Content = "Game ID copiado al portapapeles",
            Icon = "solar:copy-bold",
            Duration = 2,
        })
    end,
})

ConfigTab:Space({ Columns = 2 })

ConfigTab:Section({
    Title = "💀 Danger Zone",
    Desc = "Opciones peligrosas",
})

local DangerGroup = ConfigTab:Group()

DangerGroup:Button({
    Title = "Destroy UI",
    Icon = "solar:logout-3-bold",
    Size = "Small",
    Color = Color3.fromRGB(255, 70, 70),
    Callback = function()
        -- Parar threads
        for name, thread in pairs(Threads) do
            if type(thread) == "thread" then
                pcall(function() task.cancel(thread) end)
            end
        end
        
        -- Parar infinite jump
        if InfiniteJumpConnection then
            pcall(function() InfiniteJumpConnection:Disconnect() end)
        end
        
        -- Limpiar chams
        for player, data in pairs(ChamsObjects) do
            CleanupChams(player)
        end
        
        -- Reset
        Settings = {}
        SetFullBright()
        
        -- Destruir ESP
        for _, esp in pairs(ESPs) do
            pcall(function()
                esp.Name:Destroy()
                esp.HealthBg:Destroy()
                esp.Distance:Destroy()
                esp.Weapon:Destroy()
                esp.WeaponIcon:Destroy()
            end)
        end
        
        -- Destruir UI
        pcall(function() Window:Destroy() end)
        if ESPGui then
            pcall(function() ESPGui:Destroy() end)
        end
        
        getgenv().WaterHubLoaded = false
        
        print("✅ Water Hub Destruido Correctamente")
    end,
})

ConfigTab:Space({ Columns = 2 })

ConfigTab:Section({
    Title = "📝 About",
    Desc = "Acerca de",
})

local AboutGroup = ConfigTab:Group()

AboutGroup:Button({
    Title = "Water Hub v2.1",
    Icon = "solar:star-bold-duotone",
    Size = "Small",
    Color = Color3.fromHex("#EF4F1D"),
    Callback = function() end,
})

AboutGroup:Space({ Columns = 0.5 })

AboutGroup:Button({
    Title = "By: AdamABJ",
    Icon = "solar:check-circle-bold",
    Size = "Small",
    Color = Color3.fromHex("#00F2FE"),
    Callback = function() end,
})

-- ============================================
-- NOTIFICACIONES
-- ============================================
pcall(function()
    WindUI:Notify({
        Title = "Water Hub",
        Content = "✅ v2.1 Cargado Exitosamente",
        Icon = "solar:water-drops-bold-duotone",
        Duration = 3,
    })
end)

print("✅ Water Hub v2.1 Cargado Completamente")
print("🎮 Todas las funciones activas y operacionales")
print("📍 Presiona F para abrir/cerrar la UI")
