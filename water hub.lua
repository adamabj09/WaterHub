--[[
    WATER HUB | BLOCKSPIN - VERSIÓN OPTIMIZADA
    Basado en la lógica de Sp3arParvus
    Solo opciones que funcionan en BlockSpin
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
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")

-- ============================================
-- CARGAR UI (Fluent)
-- ============================================
local UI = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = UI:CreateWindow({
    Title = "Water Hub | BlockSpin",
    SubTitle = "Optimized Version",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 450),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.End,
})

-- ============================================
-- NOTIFICACIONES
-- ============================================
local function Notify(title, message, duration)
    UI:Notify({
        Title = title,
        Content = message,
        Duration = duration or 3
    })
end

-- ============================================
-- VARIABLES
-- ============================================
local Features = {
    -- COMBAT
    SilentAim = false,
    FOV = 200,
    AimPart = "Head",
    TeamCheck = false,
    Smoothing = 20,
    VisibilityCheck = true,
    HitboxExpander = false,
    AutoHeal = false,
    AutoHit = false,
    
    -- MOVEMENT
    WalkSpeed = 16,
    HighJump = false,
    InfiniteStamina = false,
    Invisible = false,
    EnableSnap = false,
    SnapDepth = 26,
    
    -- VISUAL
    ESPName = false,
    ESPHealth = false,
    ESPDistance = false,
    Chams = false,
    FullBright = false,
    
    -- FARM
    AutoPickup = false,
    AutoATM = false,
    
    -- MISC
    AntiAFK = false,
    QTeleport = false,
}

local Threads = {}
local ESPObjects = {}
local ChamsObjects = {}
local SilentAimTarget = nil
local OldNamecall = nil
local DesyncBody = nil
local DesyncConnection = nil
local OriginalJumpPower = 50
local OriginalWalkSpeed = 16

-- Cache para jugadores
local PlayersCache = {}
local function UpdatePlayersCache()
    PlayersCache = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(PlayersCache, player)
        end
    end
end

local function GetPlayersCache()
    return PlayersCache
end

UpdatePlayersCache()

-- ============================================
-- FUNCIONES UTILIDAD
-- ============================================
local function GetCharacter(player)
    if not player then return nil, nil end
    local char = player.Character
    if not char or not char.Parent then return nil, nil end
    local root = char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart
    if not root then return nil, nil end
    return char, root
end

local function GetHealth(player)
    local char = player.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            return hum.Health, hum.MaxHealth
        end
    end
    return 0, 100
end

local function InEnemyTeam(player)
    if not Features.TeamCheck then return true end
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team ~= player.Team
    end
    return true
end

-- ============================================
-- SILENT AIM (CORAZÓN DEL AIMBOT)
-- ============================================
local Camera = Workspace.CurrentCamera

local function GetClosestPlayer()
    if not Features.SilentAim then return nil end
    
    local mouse = LocalPlayer:GetMouse()
    if not mouse then return nil end
    
    local closest = nil
    local shortestDist = Features.FOV
    local cameraPos = Camera.CFrame.Position
    
    for _, player in ipairs(GetPlayersCache()) do
        if player ~= LocalPlayer and InEnemyTeam(player) then
            local char, root = GetCharacter(player)
            if not char or not root then continue end
            
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.Health <= 0 then continue end
            
            local targetPart = char:FindFirstChild(Features.AimPart) or char:FindFirstChild("Head")
            if not targetPart then continue end
            
            -- Visibility check
            if Features.VisibilityCheck then
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                local ray = Workspace:Raycast(cameraPos, (targetPart.Position - cameraPos), raycastParams)
                if ray and ray.Instance and not ray.Instance:IsDescendantOf(char) then
                    continue
                end
            end
            
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                local dx = screenPos.X - mouse.X
                local dy = screenPos.Y - mouse.Y
                local dist = math.sqrt(dx * dx + dy * dy)
                
                if dist < shortestDist then
                    shortestDist = dist
                    closest = player
                end
            end
        end
    end
    
    return closest
end

-- Hook para Silent Aim
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
                    local targetPart = targetChar:FindFirstChild(Features.AimPart) 
                        or targetChar:FindFirstChild("Head")
                    if targetPart then
                        for i = 1, #args do
                            if typeof(args[i]) == "Vector3" then
                                args[i] = targetPart.Position
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
local function SetHitboxExpander(enabled)
    for _, player in ipairs(GetPlayersCache()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if enabled then
                    hrp.Size = Vector3.new(10, 10, 10)
                    hrp.Transparency = 0.7
                    hrp.CanCollide = false
                else
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                end
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
            if hum and hum.Health < hum.MaxHealth then
                -- Buscar medkit en la mochila
                local backpack = LocalPlayer:FindFirstChild("Backpack")
                if backpack then
                    local medkit = backpack:FindFirstChild("Medkit") or backpack:FindFirstChild("Bandage")
                    if medkit then
                        hum.Health = hum.MaxHealth
                        Notify("Auto Heal", "Curado!")
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
local function ApplyMovement()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    
    hum.WalkSpeed = Features.WalkSpeed
    
    if Features.HighJump then
        hum.JumpPower = 100
    else
        hum.JumpPower = 50
    end
end

local function MovementLoop()
    while true do
        ApplyMovement()
        task.wait(0.1)
    end
end

local function InfiniteStaminaLoop()
    while Features.InfiniteStamina do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                pcall(function() hum:SetAttribute("Stamina", 100) end)
                local staminaVal = char:FindFirstChild("Stamina")
                if staminaVal then staminaVal.Value = 100 end
            end
        end
        task.wait(0.2)
    end
end

-- Invisible (Desync)
local function SetupDesync()
    if not Features.Invisible then
        if DesyncBody then
            DesyncBody:Destroy()
            DesyncBody = nil
        end
        if DesyncConnection then
            DesyncConnection:Disconnect()
            DesyncConnection = nil
        end
        return
    end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local desyncPosition = hrp.Position
    
    DesyncBody = Instance.new("Part")
    DesyncBody.Name = "DesyncBody"
    DesyncBody.Size = Vector3.new(4, 4, 1)
    DesyncBody.CFrame = CFrame.new(desyncPosition)
    DesyncBody.Anchored = true
    DesyncBody.CanCollide = false
    DesyncBody.Transparency = 0.5
    DesyncBody.BrickColor = BrickColor.new("Bright red")
    DesyncBody.Parent = workspace
    
    DesyncConnection = RunService.Heartbeat:Connect(function()
        if not Features.Invisible then return end
        if DesyncBody then
            DesyncBody.CFrame = CFrame.new(desyncPosition)
        end
    end)
    
    Notify("Invisible (Desync)", "Activado - Reinicia para efecto completo")
end

-- Snap Under Map
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

-- ============================================
-- VISUAL - ESP
-- ============================================
local ESPGui = nil

local function GetESPGui()
    if ESPGui and ESPGui.Parent then return ESPGui end
    local sg = Instance.new("ScreenGui")
    sg.Name = "WaterHub_ESP"
    sg.ResetOnSpawn = false
    sg.Parent = game:GetService("CoreGui")
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
                else
                    esp.Name.Visible = false
                    esp.HealthBg.Visible = false
                    esp.Distance.Visible = false
                end
            else
                esp.Name.Visible = false
                esp.HealthBg.Visible = false
                esp.Distance.Visible = false
            end
        end)
    end
end

-- Chams
local function SetChams(enabled)
    for _, player in ipairs(GetPlayersCache()) do
        if player ~= LocalPlayer and player.Character then
            if enabled then
                if not ChamsObjects[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "WaterHub_Chams"
                    highlight.FillColor = Color3.fromRGB(0, 255, 100)
                    highlight.OutlineColor = Color3.fromRGB(0, 242, 254)
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

-- Full Bright
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

-- ============================================
-- FARM
-- ============================================
local function AutoPickupLoop()
    while Features.AutoPickup do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name == "CashDrawer" or obj.Name == "CashPart") then
                    local dist = (obj.Position - hrp.Position).Magnitude
                    if dist < 15 then
                        firetouchinterest(hrp, obj, 0)
                        firetouchinterest(hrp, obj, 1)
                    end
                end
            end
        end
        task.wait(0.3)
    end
end

local function AutoATMLoop()
    while Features.AutoATM do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj.Name == "ATM" and obj:FindFirstChild("ClickDetector") then
                    local dist = (obj.Position - hrp.Position).Magnitude
                    if dist < 10 then
                        fireclickdetector(obj.ClickDetector)
                        Notify("Auto ATM", "Usando ATM...")
                        task.wait(2)
                    end
                end
            end
        end
        task.wait(1)
    end
end

-- ============================================
-- MISC
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
-- UI - PESTAÑA COMBAT
-- ============================================
local CombatTab = Window:AddTab({ Title = "COMBAT", Icon = "sword" })

CombatTab:AddSection("Aimbot")

CombatTab:AddToggle("SilentAim", {
    Title = "Silent Aim",
    Default = false,
    Callback = function(v)
        Features.SilentAim = v
        if v then SetupSilentAim() end
        Notify("Silent Aim", v and "Activado" or "Desactivado")
    end
})

CombatTab:AddSlider("FOV", {
    Title = "FOV Size",
    Default = 200,
    Min = 50,
    Max = 500,
    Rounding = 1,
    Callback = function(v)
        Features.FOV = v
    end
})

CombatTab:AddDropdown("AimPart", {
    Title = "Aim Part",
    Values = { "Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso" },
    Default = "Head",
    Callback = function(v)
        Features.AimPart = v
    end
})

CombatTab:AddToggle("TeamCheck", {
    Title = "Ignore Teammates",
    Default = false,
    Callback = function(v)
        Features.TeamCheck = v
    end
})

CombatTab:AddSlider("Smoothing", {
    Title = "Smoothing",
    Default = 20,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(v)
        Features.Smoothing = v
    end
})

CombatTab:AddToggle("VisibilityCheck", {
    Title = "Visibility Check",
    Default = true,
    Callback = function(v)
        Features.VisibilityCheck = v
    end
})

CombatTab:AddToggle("HitboxExpander", {
    Title = "Hitbox Expander",
    Default = false,
    Callback = function(v)
        Features.HitboxExpander = v
        SetHitboxExpander(v)
    end
})

CombatTab:AddSection("Auto")

CombatTab:AddToggle("AutoHeal", {
    Title = "Auto Heal",
    Default = false,
    Callback = function(v)
        Features.AutoHeal = v
        if v then Threads.AutoHeal = task.spawn(AutoHealLoop) end
    end
})

CombatTab:AddToggle("AutoHit", {
    Title = "Auto Hit",
    Default = false,
    Callback = function(v)
        Features.AutoHit = v
        if v then Threads.AutoHit = task.spawn(AutoHitLoop) end
    end
})

-- ============================================
-- UI - PESTAÑA MOVEMENT
-- ============================================
local MovementTab = Window:AddTab({ Title = "MOVEMENT", Icon = "running" })

MovementTab:AddSection("Movement")

MovementTab:AddSlider("WalkSpeed", {
    Title = "Walk Speed",
    Default = 16,
    Min = 16,
    Max = 200,
    Rounding = 1,
    Callback = function(v)
        Features.WalkSpeed = v
        ApplyMovement()
    end
})

MovementTab:AddToggle("HighJump", {
    Title = "High Jump",
    Default = false,
    Callback = function(v)
        Features.HighJump = v
        ApplyMovement()
    end
})

MovementTab:AddToggle("InfiniteStamina", {
    Title = "Infinite Stamina",
    Default = false,
    Callback = function(v)
        Features.InfiniteStamina = v
        if v then Threads.Stamina = task.spawn(InfiniteStaminaLoop) end
    end
})

MovementTab:AddSection("Desync")

MovementTab:AddToggle("Invisible", {
    Title = "Invisible (Desync)",
    Default = false,
    Callback = function(v)
        Features.Invisible = v
        SetupDesync()
        Notify("Invisible (Desync)", v and "Activado - Reinicia para efecto completo" or "Desactivado")
    end
})

MovementTab:AddSection("Snap Under Map")

MovementTab:AddToggle("EnableSnap", {
    Title = "Enable Snap",
    Default = false,
    Callback = function(v)
        Features.EnableSnap = v
    end
})

MovementTab:AddSlider("SnapDepth", {
    Title = "Snap Depth",
    Default = 26,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Callback = function(v)
        Features.SnapDepth = v
    end
})

MovementTab:AddLabel("Hold Z to snap under map")

-- ============================================
-- UI - PESTAÑA VISUAL
-- ============================================
local VisualTab = Window:AddTab({ Title = "VISUAL", Icon = "eye" })

VisualTab:AddSection("ESP")

VisualTab:AddToggle("ESPName", {
    Title = "Name ESP",
    Default = false,
    Callback = function(v)
        Features.ESPName = v
    end
})

VisualTab:AddToggle("ESPHealth", {
    Title = "Health ESP",
    Default = false,
    Callback = function(v)
        Features.ESPHealth = v
    end
})

VisualTab:AddToggle("ESPDistance", {
    Title = "Distance ESP",
    Default = false,
    Callback = function(v)
        Features.ESPDistance = v
    end
})

VisualTab:AddSection("Chams")

VisualTab:AddToggle("Chams", {
    Title = "Chams (Verde/Azul)",
    Default = false,
    Callback = function(v)
        Features.Chams = v
        SetChams(v)
    end
})

VisualTab:AddSection("World")

VisualTab:AddToggle("FullBright", {
    Title = "Full Bright",
    Default = false,
    Callback = function(v)
        Features.FullBright = v
        SetFullBright(v)
    end
})

-- ============================================
-- UI - PESTAÑA FARM
-- ============================================
local FarmTab = Window:AddTab({ Title = "FARM", Icon = "robot" })

FarmTab:AddSection("Auto Farm")

FarmTab:AddToggle("AutoPickup", {
    Title = "Auto Pickup Items (CashDrawer)",
    Default = false,
    Callback = function(v)
        Features.AutoPickup = v
        if v then Threads.AutoPickup = task.spawn(AutoPickupLoop) end
    end
})

FarmTab:AddToggle("AutoATM", {
    Title = "Auto ATM",
    Default = false,
    Callback = function(v)
        Features.AutoATM = v
        if v then Threads.AutoATM = task.spawn(AutoATMLoop) end
    end
})

-- ============================================
-- UI - PESTAÑA MISC
-- ============================================
local MiscTab = Window:AddTab({ Title = "MISC", Icon = "settings" })

MiscTab:AddSection("General")

MiscTab:AddToggle("AntiAFK", {
    Title = "Anti AFK",
    Default = false,
    Callback = function(v)
        Features.AntiAFK = v
        if v then Threads.AntiAFK = task.spawn(AntiAFKLoop) end
    end
})

MiscTab:AddToggle("QTeleport", {
    Title = "Q-Teleport (Press Q to teleport to mouse)",
    Default = false,
    Callback = function(v)
        Features.QTeleport = v
    end
})

MiscTab:AddSection("Server")

MiscTab:AddButton({
    Title = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

MiscTab:AddButton({
    Title = "Destroy UI",
    Callback = function()
        for k, _ in pairs(Threads) do Threads[k] = nil end
        SetChams(false)
        SetHitboxExpander(false)
        SetFullBright(false)
        if DesyncBody then DesyncBody:Destroy() end
        if DesyncConnection then DesyncConnection:Disconnect() end
        Window:Destroy()
        if getgenv then getgenv().WaterHubLoaded = false end
        Notify("Water Hub", "UI Destruida")
    end
})

-- ============================================
-- INICIALIZACIÓN
-- ============================================
task.spawn(MovementLoop)

UpdatePlayersCache()

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    UpdatePlayersCache()
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    UpdatePlayersCache()
    if ESPObjects[player] then
        pcall(function()
            if ESPObjects[player].Name then ESPObjects[player].Name:Destroy() end
            if ESPObjects[player].HealthBg then ESPObjects[player].HealthBg:Destroy() end
            if ESPObjects[player].Distance then ESPObjects[player].Distance:Destroy() end
        end)
        ESPObjects[player] = nil
    end
    if ChamsObjects[player] then
        ChamsObjects[player]:Destroy()
        ChamsObjects[player] = nil
    end
end)

RunService.RenderStepped:Connect(UpdateESP)

-- Actualizar Silent Aim target cada frame
RunService.RenderStepped:Connect(function()
    SilentAimTarget = GetClosestPlayer()
end)

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    ApplyMovement()
    if Features.Invisible then
        SetupDesync()
    end
    if Features.HitboxExpander then
        SetHitboxExpander(true)
    end
end)

-- Actualizar caché de jugadores periódicamente
task.spawn(function()
    while true do
        task.wait(5)
        UpdatePlayersCache()
    end
end)

CombatTab:Select()
Notify("Water Hub", "Script cargado - Optimizado para BlockSpin")

print("✅ Water Hub | BlockSpin - Versión Optimizada cargada")