--[[
    WATER HUB | BLOCKSPIN - VERSIÓN FINAL COMPLETA
    Pestañas: COMBAT, MOVEMENT, WEAPON, VISUAL, AUTOFARM, SPECTATE, MISC, CONFIG
    Con botón flotante, tecla F para abrir/cerrar, Invisible (Desync) y Snap Under Map (Z)
--]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

local gethui = gethui or function() return CoreGui end

-- ============================================
-- CARGAR WINDUI
-- ============================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
if not WindUI then
    warn("Error cargando WindUI")
    return
end

-- ============================================
-- NOTIFICACIONES
-- ============================================
local function Notify(title, message, duration)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = message,
            Duration = duration or 3
        })
    end)
end

-- ============================================
-- VARIABLES PRINCIPALES
-- ============================================
local Features = {
    -- COMBAT
    SilentAim = false,
    FOV = 200,
    AimPart = "Head",
    AutoHeal = false,
    HealPercent = 70,
    AutoHit = false,
    HitboxExpander = false,
    
    -- MOVEMENT
    SpeedEnabled = false,
    SpeedValue = 50,
    InfiniteJump = false,
    InfiniteStamina = false,
    NoClip = false,
    Fly = false,
    Invisible = false,
    EnableSnap = false,
    SnapDepth = 26,
    
    -- WEAPON
    NoRecoil = false,
    NoSpread = false,
    RapidFire = false,
    InstantReload = false,
    
    -- VISUAL
    ESPName = false,
    ESPHealth = false,
    ESPDistance = false,
    ESPWeapon = false,
    Chams = false,
    FullBright = false,
    NoFog = false,
    
    -- AUTOFARM
    AutoFarm = false,
    AutoATM = false,
    AutoDeposit = false,
    SelectedJob = "None",
    
    -- GUNS AMMO (aunque no tenga mucho sentido en BlockSpin)
    InfiniteAmmo = false,
    NoReload = false,
    
    -- SPECTATE
    SpectateTarget = nil,
    Freecam = false,
    
    -- MISC
    AntiAFK = false,
    AutoAccept = false,
    QTeleport = false,
}

local Threads = {}
local ESPObjects = {}
local ChamsObjects = {}
local NoClipConnection = nil
local SilentAimTarget = nil
local OldNamecall = nil
local SpectateConnection = nil
local DesyncBody = nil
local DesyncConnection = nil

-- ============================================
-- FUNCIONES DE UTILIDAD
-- ============================================
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

local function GetEquippedTool(player)
    local char = player.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or nil
end

local function GetPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name)
        end
    end
    return list
end

-- ============================================
--- COMBAT: SILENT AIM
-- ============================================
RunService.RenderStepped:Connect(function()
    if not Features.SilentAim then
        SilentAimTarget = nil
        return
    end
    
    local mouse = LocalPlayer:GetMouse()
    local cam = Workspace.CurrentCamera
    if not mouse or not cam then return end
    
    local closest = nil
    local shortestDist = Features.FOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(Features.AimPart) or player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if targetPart and humanoid and humanoid.Health > 0 then
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
end)

local function SetupSilentAim()
    if OldNamecall then return end
    OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        if Features.SilentAim and method == "FireServer" and SilentAimTarget then
            local name = self.Name:lower()
            if name:find("hit") or name:find("damage") or name:find("shoot") or name:find("fire") then
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
                            end
                        end
                        if #args > 0 and typeof(args[1]) == "Instance" and args[1]:IsA("Player") then
                            args[1] = SilentAimTarget
                        end
                    end
                end
            end
        end
        return OldNamecall(self, unpack(args))
    end)
end

-- Hitbox Expander
local function SetHitboxExpanded(enabled)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                hrp.Size = enabled and Vector3.new(10, 10, 10) or Vector3.new(2, 2, 1)
                hrp.Transparency = enabled and 0.7 or 1
                hrp.CanCollide = not enabled
            end
        end
    end
end

-- Auto Heal
local function AutoHealLoop()
    while Features.AutoHeal do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                local healthPercent = (hum.Health / hum.MaxHealth) * 100
                if healthPercent < Features.HealPercent then
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    if backpack then
                        local medkit = backpack:FindFirstChild("Medkit") or backpack:FindFirstChild("Bandage")
                        if medkit then
                            hum.Health = hum.MaxHealth
                            Notify("Auto Heal", "Curado al " .. Features.HealPercent .. "%")
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end

-- Auto Hit
local function AutoHitLoop()
    while Features.AutoHit do
        if SilentAimTarget then
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    pcall(function() tool:Activate() end)
                end
            end
        end
        task.wait(0.2)
    end
end

-- ============================================
-- MOVEMENT
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

local function InfiniteStaminaLoop()
    while Features.InfiniteStamina do
        local char = LocalPlayer.Character
        if char then
            local staminaVal = char:FindFirstChild("Stamina")
            if staminaVal and staminaVal:IsA("NumberValue") then staminaVal.Value = 100 end
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                local humStamina = hum:FindFirstChild("Stamina")
                if humStamina then humStamina.Value = 100 end
                hum:SetAttribute("Stamina", 100)
            end
        end
        task.wait(0.2)
    end
end

local function SetNoClip(enabled)
    if enabled then
        if NoClipConnection then return end
        NoClipConnection = RunService.Stepped:Connect(function()
            if not Features.NoClip then return end
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
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
                if part:IsA("BasePart") then part.CanCollide = true end
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
    local connections = {}
    connections.KeyDown = UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then keys.W = true end
        if input.KeyCode == Enum.KeyCode.A then keys.A = true end
        if input.KeyCode == Enum.KeyCode.S then keys.S = true end
        if input.KeyCode == Enum.KeyCode.D then keys.D = true end
        if input.KeyCode == Enum.KeyCode.Space then keys.Space = true end
        if input.KeyCode == Enum.KeyCode.LeftShift then keys.LeftShift = true end
    end)
    connections.KeyUp = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.W then keys.W = false end
        if input.KeyCode == Enum.KeyCode.A then keys.A = false end
        if input.KeyCode == Enum.KeyCode.S then keys.S = false end
        if input.KeyCode == Enum.KeyCode.D then keys.D = false end
        if input.KeyCode == Enum.KeyCode.Space then keys.Space = false end
        if input.KeyCode == Enum.KeyCode.LeftShift then keys.LeftShift = false end
    end)
    while Features.Fly do
        local cam = Workspace.CurrentCamera
        local direction = Vector3.new(0,0,0)
        if keys.W then direction = direction + cam.CFrame.LookVector end
        if keys.S then direction = direction - cam.CFrame.LookVector end
        if keys.A then direction = direction - cam.CFrame.RightVector end
        if keys.D then direction = direction + cam.CFrame.RightVector end
        if keys.Space then direction = direction + Vector3.new(0,1,0) end
        if keys.LeftShift then direction = direction - Vector3.new(0,1,0) end
        if direction.Magnitude > 0 then
            direction = direction.Unit * speed
            hrp.Velocity = direction
        else
            hrp.Velocity = Vector3.new(0,0,0)
        end
        task.wait()
    end
    for _, conn in pairs(connections) do conn:Disconnect() end
end

-- INVISIBLE (DESYNC)
local function SetupDesync()
    if not Features.Invisible then
        if DesyncBody then DesyncBody:Destroy() end
        if DesyncConnection then DesyncConnection:Disconnect() end
        return
    end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local pos = hrp.Position
    DesyncBody = Instance.new("Part")
    DesyncBody.Name = "DesyncBody"
    DesyncBody.Size = Vector3.new(4,4,1)
    DesyncBody.CFrame = CFrame.new(pos)
    DesyncBody.Anchored = true
    DesyncBody.CanCollide = false
    DesyncBody.Transparency = 0.5
    DesyncBody.BrickColor = BrickColor.new("Bright red")
    DesyncBody.Parent = workspace
    DesyncConnection = RunService.Heartbeat:Connect(function()
        if Features.Invisible and DesyncBody then
            DesyncBody.CFrame = CFrame.new(pos)
        end
    end)
    Notify("Invisible (Desync)", "Activado - Reinicia para efecto completo")
end

-- SNAP UNDER MAP (Z)
UserInputService.InputBegan:Connect(function(input)
    if Features.EnableSnap and input.KeyCode == Enum.KeyCode.Z then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = CFrame.new(
                char.HumanoidRootPart.Position.X,
                Features.SnapDepth,
                char.HumanoidRootPart.Position.Z
            )
            Notify("Snap", "Teletransportado bajo el mapa")
        end
    end
end)

-- Q-Teleport
UserInputService.InputBegan:Connect(function(input)
    if Features.QTeleport and input.KeyCode == Enum.KeyCode.Q then
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local mouse = LocalPlayer:GetMouse()
        if root and mouse and mouse.Hit then
            root.CFrame = CFrame.new(mouse.Hit.X, mouse.Hit.Y + 1, mouse.Hit.Z)
            Notify("Q-Teleport", "Teletransportado al cursor")
        end
    end
end)

-- ============================================
-- WEAPON MODS
-- ============================================
local function ApplyWeaponMods()
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
            if Features.RapidFire then
                local fireRate = obj:FindFirstChild("FireRate") or obj:FindFirstChild("Cooldown")
                if fireRate then fireRate.Value = 0.01 end
            end
            if Features.InstantReload then
                local reload = obj:FindFirstChild("ReloadTime")
                if reload then reload.Value = 0.01 end
            end
            if Features.InfiniteAmmo then
                local ammo = obj:FindFirstChild("Ammo") or obj:FindFirstChild("Clip")
                if ammo and ammo:IsA("IntValue") then ammo.Value = 999 end
            end
        end
    end
end

-- ============================================
-- VISUAL: ESP
-- ============================================
local ESPGui = nil
local function GetESPGui()
    if ESPGui and ESPGui.Parent then return ESPGui end
    local sg = Instance.new("ScreenGui")
    sg.Name = "WaterHub_ESP"
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
    esp.Name.Size = UDim2.new(0,200,0,20)
    esp.Name.BackgroundTransparency = 1
    esp.Name.TextColor3 = Color3.fromRGB(255,255,255)
    esp.Name.TextSize = 12
    esp.Name.Font = Enum.Font.GothamBold
    esp.Name.Parent = gui
    esp.HealthBg = Instance.new("Frame")
    esp.HealthBg.Size = UDim2.new(0,100,0,6)
    esp.HealthBg.BackgroundColor3 = Color3.fromRGB(50,50,50)
    esp.HealthBg.BorderSizePixel = 0
    esp.HealthBg.Parent = gui
    esp.HealthBar = Instance.new("Frame")
    esp.HealthBar.Size = UDim2.new(1,0,1,0)
    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(0,255,0)
    esp.HealthBar.BorderSizePixel = 0
    esp.HealthBar.Parent = esp.HealthBg
    esp.Distance = Instance.new("TextLabel")
    esp.Distance.Size = UDim2.new(0,100,0,15)
    esp.Distance.BackgroundTransparency = 1
    esp.Distance.TextColor3 = Color3.fromRGB(200,200,200)
    esp.Distance.TextSize = 10
    esp.Distance.Font = Enum.Font.Gotham
    esp.Distance.Parent = gui
    esp.Weapon = Instance.new("TextLabel")
    esp.Weapon.Size = UDim2.new(0,150,0,20)
    esp.Weapon.BackgroundTransparency = 1
    esp.Weapon.TextColor3 = Color3.fromRGB(255,200,100)
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
                    else esp.Name.Visible = false end
                    if Features.ESPHealth then
                        local percent = hum.Health / hum.MaxHealth
                        esp.HealthBar.Size = UDim2.new(percent, 0, 1, 0)
                        esp.HealthBar.BackgroundColor3 = Color3.fromRGB(255*(1-percent), 255*percent, 0)
                        esp.HealthBg.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 30)
                        esp.HealthBg.Visible = true
                    else esp.HealthBg.Visible = false end
                    if Features.ESPDistance and myPos then
                        local dist = (myPos - hrp.Position).Magnitude
                        esp.Distance.Position = UDim2.new(0, pos.X - 50, 0, pos.Y - 20)
                        esp.Distance.Text = math.floor(dist) .. "m"
                        esp.Distance.Visible = true
                    else esp.Distance.Visible = false end
                    if Features.ESPWeapon then
                        local weapon = GetEquippedTool(player)
                        if weapon and weapon ~= esp.LastWeapon then
                            esp.LastWeapon = weapon
                            esp.Weapon.Text = weapon
                        end
                        esp.Weapon.Visible = weapon and true or false
                        if weapon then esp.Weapon.Position = UDim2.new(0, pos.X - 75, 0, pos.Y - 10) end
                    else esp.Weapon.Visible = false end
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

local function SetChams(enabled)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if enabled then
                if not ChamsObjects[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "WaterHub_Chams"
                    highlight.FillColor = Color3.fromRGB(0,255,0)
                    highlight.OutlineColor = Color3.fromRGB(255,255,255)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                    highlight.Adornee = player.Character
                    highlight.Parent = player.Character
                    ChamsObjects[player] = highlight
                end
            else
                if ChamsObjects[player] then
                    ChamsObjects[player]:Destroy()
                    ChamsObjects[player] = nil
                end
            end
        end
    end
end

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
    Lighting.FogEnd = enabled and 100000 or 1000
end

-- ============================================
-- AUTOFARM
-- ============================================
local function AutoFarmLoop()
    while Features.AutoFarm do
        local char = LocalPlayer.Character
        if char then
            if Features.SelectedJob == "Cleaner" then
                for _, part in ipairs(Workspace:GetDescendants()) do
                    if part.Name:find("Puddle") or part.Name:find("Mess") then
                        if char:FindFirstChild("HumanoidRootPart") and (part.Position - char.HumanoidRootPart.Position).Magnitude < 50 then
                            firetouchinterest(char.HumanoidRootPart, part, 0)
                            firetouchinterest(char.HumanoidRootPart, part, 1)
                        end
                    end
                end
            elseif Features.SelectedJob == "Pizza" then
                for _, part in ipairs(Workspace:GetDescendants()) do
                    if part.Name:find("Pizza") or part.Name:find("Box") then
                        if char:FindFirstChild("HumanoidRootPart") and (part.Position - char.HumanoidRootPart.Position).Magnitude < 10 then
                            firetouchinterest(char.HumanoidRootPart, part, 0)
                            firetouchinterest(char.HumanoidRootPart, part, 1)
                        end
                    end
                end
            elseif Features.SelectedJob == "Delivery" then
                for _, npc in ipairs(Workspace:GetDescendants()) do
                    if npc:FindFirstChild("ClickDetector") then
                        if char:FindFirstChild("HumanoidRootPart") and (npc.Position - char.HumanoidRootPart.Position).Magnitude < 10 then
                            fireclickdetector(npc.ClickDetector)
                        end
                    end
                end
            end
        end
        task.wait(0.5)
    end
end

local function AutoATMLoop()
    while Features.AutoATM do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            for _, atm in ipairs(Workspace:GetDescendants()) do
                if atm.Name:find("ATM") and atm:FindFirstChild("ClickDetector") then
                    local dist = (atm.Position - char.HumanoidRootPart.Position).Magnitude
                    if dist < 10 then
                        fireclickdetector(atm.ClickDetector)
                        Notify("Auto ATM", "Usando ATM...")
                        task.wait(2)
                    end
                end
            end
        end
        task.wait(1)
    end
end

local function AutoDepositLoop()
    while Features.AutoDeposit do
        local cash, _ = GetMoney()
        if cash > 1000 then
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                for _, atm in ipairs(Workspace:GetDescendants()) do
                    if atm.Name:find("ATM") and atm:FindFirstChild("ClickDetector") then
                        local dist = (atm.Position - char.HumanoidRootPart.Position).Magnitude
                        if dist < 10 then
                            fireclickdetector(atm.ClickDetector)
                            Notify("Auto Deposit", "Depositando dinero...")
                            task.wait(3)
                        end
                    end
                end
            end
        end
        task.wait(5)
    end
end

local function InfiniteAmmoLoop()
    while Features.InfiniteAmmo do
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("Clip")
                if ammo and ammo:IsA("IntValue") then ammo.Value = 999 end
            end
        end
        task.wait(0.1)
    end
end

-- ============================================
-- SPECTATE
-- ============================================
local function StartSpectate(targetPlayer)
    if SpectateConnection then SpectateConnection:Disconnect() end
    if not targetPlayer then
        Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character
        return
    end
    SpectateConnection = RunService.RenderStepped:Connect(function()
        if targetPlayer and targetPlayer.Character then
            Workspace.CurrentCamera.CameraSubject = targetPlayer.Character:FindFirstChild("Humanoid") or targetPlayer.Character
        else
            Workspace.CurrentCamera.CameraSubject = LocalPlayer.Character
        end
    end)
end

-- ============================================
-- MISC: ANTIAFK
-- ============================================
local function AntiAFKLoop()
    while Features.AntiAFK do
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(60)
        end)
    end
end

-- ============================================
-- VENTANA PRINCIPAL (WINDUI)
-- ============================================
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
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 136)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 229, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 176, 255))
        }),
    },
})

Window:Tag({ Title = "Water Hub v3.0", Icon = "droplet", Color = Color3.fromRGB(0, 255, 136), Border = true })
Notify("Water Hub", "Script cargado - Presiona F para abrir/cerrar")

-- ============================================
-- CREAR PESTAÑAS (TODAS)
-- ============================================
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "sword" })
CombatTab:Section({ Title = "Aimbot", Desc = "Apuntado automático" })
CombatTab:Toggle({ Title = "Silent Aim", Value = false, Callback = function(v) Features.SilentAim = v; if v then SetupSilentAim() end; Notify("Silent Aim", v and "ON" or "OFF") end })
CombatTab:Slider({ Title = "FOV", Step = 10, Value = { Min = 50, Max = 500, Default = 200 }, Callback = function(v) Features.FOV = v end })
CombatTab:Dropdown({ Title = "Aim Part", Value = "Head", Values = { "Head", "HumanoidRootPart", "Torso" }, Callback = function(v) Features.AimPart = v end })
CombatTab:Space({ Columns = 1 })
CombatTab:Section({ Title = "Auto", Desc = "Funciones automáticas" })
CombatTab:Toggle({ Title = "Auto Heal", Value = false, Callback = function(v) Features.AutoHeal = v; if v then Threads.AutoHeal = task.spawn(AutoHealLoop) end end })
CombatTab:Slider({ Title = "Heal %", Step = 5, Value = { Min = 10, Max = 90, Default = 70 }, Callback = function(v) Features.HealPercent = v end })
CombatTab:Toggle({ Title = "Auto Hit", Value = false, Callback = function(v) Features.AutoHit = v; if v then Threads.AutoHit = task.spawn(AutoHitLoop) end end })
CombatTab:Toggle({ Title = "Hitbox Expander", Value = false, Callback = function(v) Features.HitboxExpander = v; SetHitboxExpanded(v) end })

local MovementTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })
MovementTab:Section({ Title = "Speed", Desc = "Velocidad de movimiento" })
MovementTab:Toggle({ Title = "Speed Hack", Value = false, Callback = function(v) Features.SpeedEnabled = v; if v then Threads.Speed = task.spawn(SpeedLoop) end end })
MovementTab:Slider({ Title = "Speed", Step = 5, Value = { Min = 16, Max = 200, Default = 50 }, Callback = function(v) Features.SpeedValue = v end })
MovementTab:Space({ Columns = 1 })
MovementTab:Section({ Title = "Extras", Desc = "Otras funciones" })
MovementTab:Toggle({ Title = "Infinite Jump", Value = false, Callback = function(v) Features.InfiniteJump = v; if v then Threads.Jump = task.spawn(InfiniteJumpLoop) end end })
MovementTab:Toggle({ Title = "Infinite Stamina", Value = false, Callback = function(v) Features.InfiniteStamina = v; if v then Threads.Stamina = task.spawn(InfiniteStaminaLoop) end end })
MovementTab:Toggle({ Title = "No Clip", Value = false, Callback = function(v) Features.NoClip = v; SetNoClip(v) end })
MovementTab:Toggle({ Title = "Fly", Value = false, Callback = function(v) Features.Fly = v; if v then Threads.Fly = task.spawn(FlyLoop) end end })
MovementTab:Space({ Columns = 1 })
MovementTab:Section({ Title = "Desync", Desc = "Invisible (Desync)" })
MovementTab:Toggle({ Title = "Invisible (Desync)", Value = false, Callback = function(v) Features.Invisible = v; SetupDesync(); Notify("Invisible (Desync)", v and "Activado - Reinicia" or "Desactivado") end })
MovementTab:Space({ Columns = 1 })
MovementTab:Section({ Title = "Snap Under Map", Desc = "Teletransportarse bajo el mapa (Hold Z)" })
MovementTab:Toggle({ Title = "Enable Snap", Value = false, Callback = function(v) Features.EnableSnap = v end })
MovementTab:Slider({ Title = "Snap Depth", Step = 1, Value = { Min = 0, Max = 100, Default = 26 }, Callback = function(v) Features.SnapDepth = v end })
MovementTab:Label({ Title = "📌 Presiona Z para teletransportarte bajo el mapa" })

local WeaponTab = Window:Tab({ Title = "WEAPON", Icon = "crosshair" })
WeaponTab:Section({ Title = "Mods", Desc = "Modificaciones de armas" })
WeaponTab:Toggle({ Title = "No Recoil", Value = false, Callback = function(v) Features.NoRecoil = v; ApplyWeaponMods() end })
WeaponTab:Toggle({ Title = "No Spread", Value = false, Callback = function(v) Features.NoSpread = v; ApplyWeaponMods() end })
WeaponTab:Toggle({ Title = "Rapid Fire", Value = false, Callback = function(v) Features.RapidFire = v; ApplyWeaponMods() end })
WeaponTab:Toggle({ Title = "Instant Reload", Value = false, Callback = function(v) Features.InstantReload = v; ApplyWeaponMods() end })
WeaponTab:Space({ Columns = 1 })
WeaponTab:Section({ Title = "Ammo", Desc = "Munición infinita" })
WeaponTab:Toggle({ Title = "Infinite Ammo", Value = false, Callback = function(v) Features.InfiniteAmmo = v; if v then Threads.InfiniteAmmo = task.spawn(InfiniteAmmoLoop) end end })
WeaponTab:Toggle({ Title = "No Reload", Value = false, Callback = function(v) Features.NoReload = v end })

local VisualTab = Window:Tab({ Title = "VISUAL", Icon = "eye" })
VisualTab:Section({ Title = "ESP", Desc = "Ver jugadores" })
VisualTab:Toggle({ Title = "Name ESP", Value = false, Callback = function(v) Features.ESPName = v end })
VisualTab:Toggle({ Title = "Health ESP", Value = false, Callback = function(v) Features.ESPHealth = v end })
VisualTab:Toggle({ Title = "Distance ESP", Value = false, Callback = function(v) Features.ESPDistance = v end })
VisualTab:Toggle({ Title = "Weapon ESP", Value = false, Callback = function(v) Features.ESPWeapon = v end })
VisualTab:Space({ Columns = 1 })
VisualTab:Section({ Title = "Chams", Desc = "Resaltar jugadores" })
VisualTab:Toggle({ Title = "Chams", Value = false, Callback = function(v) Features.Chams = v; SetChams(v) end })
VisualTab:Space({ Columns = 1 })
VisualTab:Section({ Title = "World", Desc = "Modificar mundo" })
VisualTab:Toggle({ Title = "Full Bright", Value = false, Callback = function(v) Features.FullBright = v; SetFullBright(v) end })
VisualTab:Toggle({ Title = "No Fog", Value = false, Callback = function(v) Features.NoFog = v; SetNoFog(v) end })

local AutoFarmTab = Window:Tab({ Title = "AUTOFARM", Icon = "robot" })
AutoFarmTab:Section({ Title = "Farm", Desc = "Farmear automáticamente" })
AutoFarmTab:Toggle({ Title = "Auto Farm Job", Value = false, Callback = function(v) Features.AutoFarm = v; if v then Threads.AutoFarm = task.spawn(AutoFarmLoop) end end })
AutoFarmTab:Dropdown({ Title = "Job", Value = "None", Values = { "None", "Cleaner", "Pizza", "Delivery" }, Callback = function(v) Features.SelectedJob = v end })
AutoFarmTab:Space({ Columns = 1 })
AutoFarmTab:Section({ Title = "ATM", Desc = "Robar y depositar" })
AutoFarmTab:Toggle({ Title = "Auto ATM", Value = false, Callback = function(v) Features.AutoATM = v; if v then Threads.AutoATM = task.spawn(AutoATMLoop) end end })
AutoFarmTab:Toggle({ Title = "Auto Deposit", Value = false, Callback = function(v) Features.AutoDeposit = v; if v then Threads.AutoDeposit = task.spawn(AutoDepositLoop) end end })

local SpectateTab = Window:Tab({ Title = "SPECTATE", Icon = "video" })
SpectateTab:Section({ Title = "Spectate", Desc = "Ver otros jugadores" })
local PlayerList = SpectateTab:Dropdown({ Title = "Select Player", Value = "None", Values = GetPlayers(), Callback = function(v) local target = Players:FindFirstChild(v); Features.SpectateTarget = target; StartSpectate(target) end })
task.spawn(function() while true do task.wait(5); pcall(function() PlayerList:SetValues(GetPlayers()) end) end end)
SpectateTab:Button({ Title = "Stop Spectate", Callback = function() StartSpectate(nil); Features.SpectateTarget = nil end })

local MiscTab = Window:Tab({ Title = "MISC", Icon = "settings" })
MiscTab:Section({ Title = "General", Desc = "Funciones varias" })
MiscTab:Toggle({ Title = "Anti AFK", Value = false, Callback = function(v) Features.AntiAFK = v; if v then Threads.AntiAFK = task.spawn(AntiAFKLoop) end end })
MiscTab:Toggle({ Title = "Auto Accept", Value = false, Callback = function(v) Features.AutoAccept = v end })
MiscTab:Toggle({ Title = "Q-Teleport", Value = false, Callback = function(v) Features.QTeleport = v end })

local ConfigTab = Window:Tab({ Title = "CONFIG", Icon = "cog" })
ConfigTab:Section({ Title = "Account", Desc = "Tu información" })
local CashLabel = ConfigTab:Label({ Title = "Cash: Loading..." })
local BankLabel = ConfigTab:Label({ Title = "Bank: Loading..." })
task.spawn(function() while true do local cash, bank = GetMoney(); pcall(function() CashLabel:Set("💰 Cash: $" .. cash); BankLabel:Set("🏦 Bank: $" .. bank) end); task.wait(1) end end)
ConfigTab:Space({ Columns = 1 })
ConfigTab:Section({ Title = "Script", Desc = "Control del script" })
ConfigTab:Button({ Title = "Destroy UI", Callback = function()
    for k, _ in pairs(Threads) do Threads[k] = nil end
    SetChams(false); SetNoClip(false); StartSpectate(nil)
    if DesyncBody then DesyncBody:Destroy() end
    if DesyncConnection then DesyncConnection:Disconnect() end
    Window:Destroy()
end })
ConfigTab:Button({ Title = "Rejoin Server", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end })

-- Seleccionar primera pestaña
CombatTab:Select()

-- ============================================
-- INICIALIZACIÓN DE OBJETOS Y EVENTOS
-- ============================================
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end

Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then CreateESP(p) end end)
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
        ChamsObjects[p]:Destroy()
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
    if Features.NoClip then
        SetNoClip(false)
        task.wait(0.1)
        SetNoClip(true)
    end
    if Features.NoRecoil or Features.NoSpread or Features.RapidFire then
        ApplyWeaponMods()
    end
    if Features.Invisible then SetupDesync() end
    if Features.HitboxExpander then SetHitboxExpanded(true) end
end)

print("✅ Water Hub | BlockSpin - Versión final cargada correctamente")
Notify("Water Hub", "Todas las funciones están listas")
