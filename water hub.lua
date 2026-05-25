--[[
    WATER HUB | BLOCKSPIN - VERSIÓN DELTA
    Optimizado para Delta Executor
    By: AdamABJ (Editado para Delta)
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
-- VERIFICACIÓN DE DELTA / COMPATIBILIDAD
-- ============================================
local function getexecutorname()
    return (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) or "Unknown"
end

print("Ejecutor detectado:", getexecutorname())

-- ============================================
-- CARGAR WINDUI (CON MANEJO DE ERRORES PARA DELTA)
-- ============================================
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)

if not success or not WindUI then
    warn("Error cargando WindUI:", WindUI)
    -- Intentar alternativa para Delta
    success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua", true))()
    end)
    
    if not success then
        StarterGui:SetCore("SendNotification", {
            Title = "Error", 
            Text = "No se pudo cargar WindUI. Reintenta.", 
            Duration = 5
        })
        return
    end
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
        local args = {...}
        local success, err = pcall(function()
            SendRemote:FireServer(action, unpack(args))
        end)
        if not success then
            warn("Error en FireSend:", err)
        end
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
    
    if Settings.NoRecoil then
        pcall(function() tool:SetAttribute("recoil", 0) end)
    end
    if Settings.NoSpread then
        pcall(function() tool:SetAttribute("accuracy", 1) end)
    end
    if Settings.RapidFire then
        pcall(function() tool:SetAttribute("fire_rate", 0) end)
    end
end

local function SetInfiniteStamina(enabled)
    if enabled and StaminaModule then
        pcall(function()
            local stamina = require(StaminaModule)
            if stamina and type(stamina) == "table" then
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
-- TABLA DE CONFIGURACIÓN (MEJOR QUE _G)
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
    NoClip = false,
    Fly = false,
    NoRecoil = false,
    NoSpread = false,
    RapidFire = false,
    NameESP = false,
    HealthESP = false,
    DistanceESP = false,
    WeaponESP = false,
    WeaponIconESP = false,
    FullBright = false,
    Magneto = false,
    MagnetoRadius = 50,
    AntiAFK = false,
    InfiniteStamina = false,
    AutoReload = false
}

local SilentTarget = nil
local ESPs = {}
local MagnetoItems = {}
local NoClipConn = nil
local FlyConnections = {}
local Threads = {}
local oldNamecall = nil

-- ============================================
-- SILENT AIM (COMPATIBLE CON DELTA)
-- ============================================
local function UpdateSilentAim()
    if not Settings.SilentAim then 
        SilentTarget = nil
        return 
    end
    
    local mouse = LocalPlayer:GetMouse()
    local cam = Workspace.CurrentCamera
    if not mouse or not cam then return end
    
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

-- Hook para Silent Aim (VERSIÓN DELTA COMPATIBLE)
if hookmetamethod and getnamecallmethod then
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if Settings.SilentAim and method == "FireServer" and SilentTarget then
            local name = tostring(self.Name):lower()
            if name:find("hit") or name:find("damage") or name:find("shoot") or name:find("fire") or name:find("bullet") then
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
            end
        end
        
        return oldNamecall(self, unpack(args))
    end)
else
    warn("Tu ejecutor no soporta hookmetamethod - Silent Aim podría no funcionar correctamente")
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
-- MOVEMENT LOOPS
-- ============================================
local function SpeedLoop()
    while Settings.SpeedEnabled do
        task.wait(0.1)
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then 
                hum.WalkSpeed = Settings.SpeedValue 
            end
        end
    end
    
    -- Reset al desactivar
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then 
            hum.WalkSpeed = 16 
        end
    end
end

local function InfiniteJumpLoop()
    local UserInputService = game:GetService("UserInputService")
    local jumping = false
    
    local connection = UserInputService.JumpRequest:Connect(function()
        if Settings.InfiniteJump then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end)
    
    table.insert(Threads, connection)
    
    -- Mantener el loop activo mientras esté habilitado
    while Settings.InfiniteJump do
        task.wait(1)
    end
    
    connection:Disconnect()
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
    
    FlyConnections.KeyDown = UserInputService.InputBegan:Connect(function(i, g) 
        if not g then onInput(i, true) end
    end)
    
    FlyConnections.KeyUp = UserInputService.InputEnded:Connect(function(i) 
        onInput(i, false) 
    end)
    
    local bv = Instance.new("BodyVelocity")
    bv.Name = "FlyVelocity"
    bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp
    
    while Settings.Fly do
        local cam = Workspace.CurrentCamera
        local dir = Vector3.new(0, 0, 0)
        
        if keys.W then dir = dir + cam.CFrame.LookVector end
        if keys.S then dir = dir - cam.CFrame.LookVector end
        if keys.A then dir = dir - cam.CFrame.RightVector end
        if keys.D then dir = dir + cam.CFrame.RightVector end
        if keys.Space then dir = dir + Vector3.new(0, 1, 0) end
        if keys.LeftShift then dir = dir - Vector3.new(0, 1, 0) end
        
        if dir.Magnitude > 0 then
            bv.Velocity = dir.Unit * speed
        else
            bv.Velocity = Vector3.new(0, 0, 0)
        end
        task.wait()
    end
    
    -- Cleanup
    if FlyConnections.KeyDown then FlyConnections.KeyDown:Disconnect() end
    if FlyConnections.KeyUp then FlyConnections.KeyUp:Disconnect() end
    FlyConnections = {}
    
    if hrp:FindFirstChild("FlyVelocity") then
        hrp.FlyVelocity:Destroy()
    end
end

-- ============================================
-- INFINITE STAMINA
-- ============================================
local function InfiniteStaminaLoop()
    while Settings.InfiniteStamina do
        task.wait(0.2)
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
    end
    SetInfiniteStamina(false)
end

-- ============================================
-- WEAPON MODS LOOP
-- ============================================
local function WeaponModsLoop()
    while Settings.NoRecoil or Settings.NoSpread or Settings.RapidFire do
        task.wait(0.5)
        ApplyWeaponMods()
    end
end

-- ============================================
-- AUTO RELOAD
-- ============================================
local function AutoReloadLoop()
    while Settings.AutoReload do
        task.wait(0.5)
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local ammo = tool:GetAttribute("Ammo") or tool:GetAttribute("CurrentAmmo")
                if ammo and ammo <= 0 then
                    pcall(function() 
                        VirtualUser:ClickButton1(Vector2.new(0,0), Enum.UserInputType.Keyboard, Enum.KeyCode.R) 
                    end)
                end
            end
        end
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
    ESPGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Protección para Delta
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
    esp.WeaponIcon.Size = UDim2.new(0, 20, 0, 20)
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
                    esp.Name.Position = UDim2.new(0, pos.X - 100, 0, pos.Y - 50)
                    esp.Name.Text = player.Name
                    esp.Name.Visible = true
                else 
                    esp.Name.Visible = false 
                end
                
                if Settings.HealthESP then
                    esp.HealthBar.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
                    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(255 * (1-percent), 255 * percent, 0)
                    esp.HealthBg.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 30)
                    esp.HealthBg.Visible = true
                else 
                    esp.HealthBg.Visible = false 
                end
                
                if Settings.DistanceESP then
                    esp.Distance.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 20)
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
                        local yOff = 0
                        if Settings.WeaponESP then
                            esp.Weapon.Position = UDim2.new(0, pos.X - 75, 0, pos.Y + 10)
                            esp.Weapon.Visible = true
                            yOff = 25
                        else
                            esp.Weapon.Visible = false
                        end
                        
                        if Settings.WeaponIconESP and weaponIcon then
                            esp.WeaponIcon.Position = UDim2.new(0, pos.X - 95, 0, pos.Y + 10 + yOff)
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
-- MAGNETO
-- ============================================
local function MagnetoLoop()
    while Settings.Magneto do
        task.wait(0.5)
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
                        while MagnetoItems[part] and Settings.Magneto and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") do
                            local success, dist = pcall(function()
                                return (part.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                            end)
                            
                            if success and dist < Settings.MagnetoRadius then
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
    end
    MagnetoItems = {}
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
-- INICIALIZAR ESP
-- ============================================
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then 
        pcall(function() CreateESP(player) end)
    end
end

Players.PlayerAdded:Connect(function(p)
    if p ~= LocalPlayer then 
        pcall(function() CreateESP(p) end)
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
end)

-- ============================================
-- RESPAWN HANDLER
-- ============================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if Settings.SpeedEnabled then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = Settings.SpeedValue end
    end
    if Settings.NoRecoil or Settings.NoSpread or Settings.RapidFire then
        ApplyWeaponMods()
    end
    if Settings.NoClip then
        NoClipLoop()
    end
    if Settings.Fly then
        -- Reiniciar fly si estaba activo
        task.wait(0.5)
        if Settings.Fly then
            Threads.Fly = task.spawn(FlyLoop)
        end
    end
end)

-- ============================================
-- ACTUALIZAR SILENT AIM Y ESP
-- ============================================
RunService.RenderStepped:Connect(function()
    UpdateSilentAim()
    UpdateESP()
end)

-- ============================================
-- VENTANA PRINCIPAL (WINDUI)
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | BlockSpin",
    Author = "By: AdamABJ | Delta Edition",
    Folder = "WaterHub_Delta",
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

Window:Tag({ Title = "v1.0 | Delta Edition", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })

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
        if v then 
            Threads.AutoHeal = task.spawn(AutoHealLoop) 
        end
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
        if v then 
            Threads.AutoHit = task.spawn(AutoHitLoop) 
        end
    end,
})

AutoGroup:Space()
AutoGroup:Space()

AutoGroup:Toggle({
    Flag = "AutoReload", Title = "Auto Reload", Value = false,
    Callback = function(v)
        Settings.AutoReload = v
        if v then 
            Threads.AutoReload = task.spawn(AutoReloadLoop) 
        end
    end,
})

-- ============================================
-- MOVEMENT TAB
-- ============================================
local MoveGroup = MovementTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚡ Movement" })

MoveGroup:Toggle({
    Flag = "SpeedHack", Title = "Speed Hack", Value = false,
    Callback = function(v)
        Settings.SpeedEnabled = v
        if v then 
            Threads.Speed = task.spawn(SpeedLoop) 
        else
            -- Reset speed
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
        Settings.InfiniteJump = v
        if v then 
            Threads.Jump = task.spawn(InfiniteJumpLoop) 
        end
    end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "InfiniteStamina", Title = "Infinite Stamina", Value = false,
    Callback = function(v)
        Settings.InfiniteStamina = v
        if v then 
            Threads.Stamina = task.spawn(InfiniteStaminaLoop) 
        end
    end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "NoClip", Title = "No Clip", Value = false,
    Callback = function(v)
        Settings.NoClip = v
        NoClipLoop()
    end,
})

MoveGroup:Space()
MoveGroup:Space()

MoveGroup:Toggle({
    Flag = "Fly", Title = "Fly Mode", Value = false,
    Callback = function(v)
        Settings.Fly = v
        if v then
            Threads.Fly = task.spawn(FlyLoop)
        else
            -- Limpiar fly
            if FlyConnections.KeyDown then FlyConnections.KeyDown:Disconnect() end
            if FlyConnections.KeyUp then FlyConnections.KeyUp:Disconnect() end
            FlyConnections = {}
            local char = LocalPlayer.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp and hrp:FindFirstChild("FlyVelocity") then
                    hrp.FlyVelocity:Destroy()
                end
            end
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
        Settings.NoRecoil = v
        if v and not Threads.WeaponMods then
            Threads.WeaponMods = task.spawn(WeaponModsLoop)
        elseif not v and not (Settings.NoSpread or Settings.RapidFire) then
            Threads.WeaponMods = nil
        end
    end,
})

WeaponGroup:Space()
WeaponGroup:Space()

WeaponGroup:Toggle({
    Flag = "NoSpread", Title = "No Spread", Value = false,
    Callback = function(v)
        Settings.NoSpread = v
        if v and not Threads.WeaponMods then
            Threads.WeaponMods = task.spawn(WeaponModsLoop)
        elseif not v and not (Settings.NoRecoil or Settings.RapidFire) then
            Threads.WeaponMods = nil
        end
    end,
})

WeaponGroup:Space()
WeaponGroup:Space()

WeaponGroup:Toggle({
    Flag = "RapidFire", Title = "Rapid Fire", Value = false,
    Callback = function(v)
        Settings.RapidFire = v
        if v and not Threads.WeaponMods then
            Threads.WeaponMods = task.spawn(WeaponModsLoop)
        elseif not v and not (Settings.NoRecoil or Settings.NoSpread) then
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
    Callback = function(v) Settings.WeaponESP = v end,
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
-- MAGNETO TAB
-- ============================================
local MagnetoGroup = MagnetoTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "🧲 Magneto" })

MagnetoGroup:Toggle({
    Flag = "Magneto", Title = "Magneto (Attract Items)", Value = false,
    Callback = function(v)
        Settings.Magneto = v
        if v then 
            Threads.Magneto = task.spawn(MagnetoLoop) 
        end
    end,
})

MagnetoGroup:Space()
MagnetoGroup:Space()

MagnetoGroup:Slider({
    Flag = "MagnetoRadius", Title = "Magneto Radius", IsTooltip = true, Step = 1,
    Value = { Min = 10, Max = 100, Default = 50 },
    Callback = function(v) Settings.MagnetoRadius = v end,
})

-- ============================================
-- MISC TAB
-- ============================================
local MiscGroup = MiscTab:Group({ Box = true, BoxBorder = true, Opened = true, Title = "⚙️ Misc" })

MiscGroup:Toggle({
    Flag = "AntiAFK", Title = "Anti AFK", Value = false,
    Callback = function(v)
        Settings.AntiAFK = v
        if v then 
            Threads.AntiAFK = task.spawn(AntiAFKLoop) 
        end
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
        -- Detener todos los threads
        for name, thread in pairs(Threads) do
            if type(thread) == "thread" then
                pcall(function() task.cancel(thread) end)
            elseif typeof(thread) == "RBXScriptConnection" then
                pcall(function() thread:Disconnect() end)
            end
        end
        
        -- Limpiar conexiones
        if NoClipConn then
            pcall(function() NoClipConn:Disconnect() end)
        end
        
        for _, conn in pairs(FlyConnections) do
            pcall(function() conn:Disconnect() end)
        end
        
        -- Resetear valores
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
    Title = "Optimizado para Delta Executor",
    Icon = "solar:check-circle-bold",
    Color = Color3.fromHex("#00F2FE"),
    Justify = "Center",
    Callback = function() end,
})

-- ============================================
-- NOTIFICACIÓN DE CARGA
-- ============================================
pcall(function()
    WindUI:Notify({
        Title = "Water Hub | BlockSpin",
        Content = "¡Cargado con éxito en Delta! By: AdamABJ",
        Icon = "solar:water-drops-bold-duotone",
        Duration = 3,
    })
end)

StarterGui:SetCore("SendNotification", {
    Title = "Water Hub",
    Text = "✅ Delta Edition cargado correctamente",
    Duration = 3,
})

print("=" .. string.rep("=", 50))
print("WATER HUB | BLOCKSPIN - VERSIÓN DELTA")
print("By: AdamABJ")
print("=" .. string.rep("=", 50))
print("🔧 Compatibilidad: Delta Executor")
print("📊 Información cargada desde Dex Explorer:")
print("   - Remotes encontrados:", SendRemote and "Send ✓" or "Send ✗")
print("   - Armas con IDs:", #WeaponImages)
print("   - Módulo de stamina:", StaminaModule and "✓" or "✗")
print("=" .. string.rep("=", 50))
