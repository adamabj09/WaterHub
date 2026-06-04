--[[
    WATER HUB | BLOCKSPIN - VERSION OPTIMIZADA
    Silent Aim + ESP Mejorados | Sin Farm
]]

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")

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
-- CONFIGURACIÓN
-- ============================================
local ConfigFile = "WaterHub_BlockSpin_v3.json"

local Features = {
    -- SILENT AIM (NUEVO SISTEMA)
    SilentAim = false,
    AimLock = false,
    Prediction = 0.165,
    AimLockKeybind = Enum.KeyCode.E,
    
    -- ESP (NUEVO SISTEMA LOWFI)
    ESPBoxes = false,
    ESPNames = false,
    ESPDistance = false,
    ESPChams = false,
    ESPColor = Color3.fromRGB(0, 150, 255),
    ESPThickness = 1,
    
    -- MOVEMENT
    WalkSpeed = false,
    SpeedValue = 50,
    SuperJump = false,
    JumpPower = 100,
    InfiniteStamina = false,
    AntiKill = false,
    AntiKillHealth = 20,
    
    -- WEAPON
    EnableGunMods = false,
    FireRate = 600,
    Recoil = 0,
    ReloadTime = 0.1,
    
    -- MISC
    FPSBoost = false,
    ThemeColor = Color3.fromHex("#0096FF")
}

-- Cargar config
local function LoadConfig()
    if isfile(ConfigFile) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(ConfigFile))
        end)
        if success and data then
            for key, value in pairs(data) do
                if Features[key] ~= nil then
                    Features[key] = value
                end
            end
        end
    end
end
LoadConfig()

-- ============================================
-- NOTIFICACIONES
-- ============================================
local function Notify(title, message)
    pcall(function()
        WindUI:Notify({Title = title, Content = message, Duration = 3})
    end)
end

-- ============================================
-- SILENT AIM + AIMLOCK (SISTEMA DA HOOD)
-- ============================================
local Aiming = loadstring(game:HttpGet("https://raw.githubusercontent.com/RapperDeluxe/scripts/main/silent%20aim%20module"))()
Aiming.TeamCheck(false)

local DaHoodSettings = {
    SilentAim = false,
    AimLock = false,
    Prediction = 0.165,
    AimLockKeybind = Enum.KeyCode.E
}

-- Overwrite para verificar estado del jugador
function Aiming.Check()
    if not (Aiming.Enabled == true and Aiming.Selected ~= LocalPlayer and Aiming.SelectedPart ~= nil) then
        return false
    end
    
    local Character = Aiming.Character(Aiming.Selected)
    if not Character then return false end
    
    local Humanoid = Character:FindFirstChild("Humanoid")
    if not Humanoid or Humanoid.Health <= 0 then return false end
    
    return true
end

-- Hook del Silent Aim
local __index
__index = hookmetamethod(game, "__index", function(t, k)
    if (t:IsA("Mouse") and (k == "Hit" or k == "Target") and Aiming.Check() and DaHoodSettings.SilentAim) then
        local SelectedPart = Aiming.SelectedPart
        local Hit = SelectedPart.CFrame + (SelectedPart.Velocity * DaHoodSettings.Prediction)
        return (k == "Hit" and Hit or SelectedPart)
    end
    return __index(t, k)
end)

-- AimLock loop
RunService:BindToRenderStep("AimLock", 0, function()
    if (DaHoodSettings.AimLock and Aiming.Check() and UserInputService:IsKeyDown(DaHoodSettings.AimLockKeybind)) then
        local SelectedPart = Aiming.SelectedPart
        local Hit = SelectedPart.CFrame + (SelectedPart.Velocity * DaHoodSettings.Prediction)
        Workspace.CurrentCamera.CFrame = CFrame.lookAt(Workspace.CurrentCamera.CFrame.Position, Hit.Position)
    end
end)

-- ============================================
-- ESP SYSTEM (LOWFI STYLE)
-- ============================================
local ESPObjects = {}
local LowfiESP = {
    Boxes = false,
    Names = false,
    Distance = false,
    Cham = false,
    Color = Color3.fromRGB(0, 150, 255),
    Thickness = 1
}

local CurrentCamera = Workspace.CurrentCamera
local V2New = Vector2.new
local V3New = Vector3.new

local function NewDrawing(Object, Props)
    local New = Drawing.new(Object)
    for i, v in pairs(Props or {}) do
        New[i] = v
    end
    return New
end

local function CreateESP(P, User, Obj)
    if not Obj then return end
    
    local Box = NewDrawing("Square", {
        Thickness = LowfiESP.Thickness,
        Color = LowfiESP.Color,
        Transparency = 1,
        Filled = false,
        Visible = false
    })

    local Name = NewDrawing("Text", {
        Text = User,
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 1,
        Outline = true,
        Center = true,
        Visible = false,
        Size = 13,
        Font = 2
    })

    local Distance = NewDrawing("Text", {
        Text = "0m",
        Color = Color3.fromRGB(200, 200, 200),
        Transparency = 1,
        Outline = true,
        Center = true,
        Visible = false,
        Size = 12,
        Font = 2
    })

    local Connection
    Connection = RunService.RenderStepped:Connect(function()
        if not Box or not Name or not Distance then 
            Connection:Disconnect()
            return 
        end
        
        local RootPos, RootVis = CurrentCamera:WorldToViewportPoint(Obj.Position)
        local GetDistance = (CurrentCamera.CFrame.p - Obj.Position).Magnitude
        
        local Char = P.Character
        local Humanoid = Char and Char:FindFirstChild("Humanoid")
        
        if RootVis and Humanoid and Humanoid.Health > 0 then
            -- Box
            if LowfiESP.Boxes then
                local Size = V2New(2000 / RootPos.Z, 3000 / RootPos.Z)
                Box.Size = Size
                Box.Position = V2New(RootPos.X - Size.X / 2, RootPos.Y - Size.Y / 2)
                Box.Color = LowfiESP.Color
                Box.Thickness = LowfiESP.Thickness
                Box.Visible = true
            else
                Box.Visible = false
            end

            -- Name
            if LowfiESP.Names then
                Name.Position = V2New(Box.Position.X + (Box.Size.X / 2), Box.Position.Y - 20)
                Name.Color = Color3.fromRGB(255, 255, 255)
                Name.Visible = true
            else
                Name.Visible = false
            end

            -- Distance
            if LowfiESP.Distance then
                Distance.Text = tostring(math.floor(GetDistance)) .. "m"
                Distance.Position = V2New(Box.Position.X + (Box.Size.X / 2), Box.Position.Y + Box.Size.Y + 5)
                Distance.Color = Color3.fromRGB(200, 200, 200)
                Distance.Visible = true
            else
                Distance.Visible = false
            end
            
            -- Chams (Highlight)
            if LowfiESP.Cham and Char then
                for _, part in ipairs(Char:GetDescendants()) do
                    if part:IsA("BasePart") and not part:FindFirstChild("ESP_Highlight") then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "ESP_Highlight"
                        highlight.FillColor = LowfiESP.Color
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.FillTransparency = 0.5
                        highlight.OutlineTransparency = 0
                        highlight.Parent = part
                    end
                end
            end
        else
            Box.Visible = false
            Name.Visible = false
            Distance.Visible = false
        end
    end)

    -- Cleanup
    local function Cleanup()
        Connection:Disconnect()
        Box:Remove()
        Name:Remove()
        Distance:Remove()
        if P.Character then
            for _, part in ipairs(P.Character:GetDescendants()) do
                if part:FindFirstChild("ESP_Highlight") then
                    part.ESP_Highlight:Destroy()
                end
            end
        end
    end
    
    Obj.AncestryChanged:Connect(function(_, Parent)
        if Parent == nil then Cleanup() end
    end)
    
    table.insert(ESPObjects, {Player = P, Cleanup = Cleanup})
end

local function OnCharacterAdded(Char)
    local Plr = Players:GetPlayerFromCharacter(Char)
    if not Plr or Plr == LocalPlayer then return end
    
    if not Char:FindFirstChild("HumanoidRootPart") then
        local Env
        Env = Char.ChildAdded:Connect(function(Child)
            if Child.Name == "HumanoidRootPart" then
                Env:Disconnect()
                CreateESP(Plr, Plr.Name, Child)
            end
        end)
    else
        CreateESP(Plr, Plr.Name, Char.HumanoidRootPart)
    end
end

local function OnPlayerAdded(P)
    if P == LocalPlayer then return end
    P.CharacterAdded:Connect(OnCharacterAdded)
    if P.Character then
        task.spawn(OnCharacterAdded, P.Character)
    end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
for _, p in ipairs(Players:GetPlayers()) do
    OnPlayerAdded(p)
end

Players.PlayerRemoving:Connect(function(p)
    for i, obj in ipairs(ESPObjects) do
        if obj.Player == p then
            pcall(obj.Cleanup)
            table.remove(ESPObjects, i)
            break
        end
    end
end)

-- ============================================
-- MOVIMIENTO
-- ============================================
local function WalkSpeedLoop()
    while Features.WalkSpeed do
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

local function SuperJumpLoop()
    while Features.SuperJump do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.JumpPower = Features.JumpPower
                if hum.FloorMaterial ~= Enum.Material.Air then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
        task.wait(0.3)
    end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.JumpPower = 50 end
    end
end

local function InfiniteStaminaLoop()
    while Features.InfiniteStamina do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum:SetAttribute("Stamina", 125) end
        end
        task.wait(0.2)
    end
end

-- ============================================
-- ANTI KILL
-- ============================================
local AntiKillConnection
local function AntiKillFunction()
    if not Features.AntiKill then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hum and hrp then
        local healthPercent = (hum.Health / hum.MaxHealth) * 100
        if healthPercent <= Features.AntiKillHealth then
            local targetPos = Vector3.new(hrp.Position.X, -26, hrp.Position.Z)
            TweenService:Create(hrp, TweenInfo.new(0.5), {CFrame = CFrame.new(targetPos)}):Play()
        end
    end
end

-- ============================================
-- GUN MODS
-- ============================================
local function ApplyGunMods()
    if not Features.EnableGunMods then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local config = tool:FindFirstChild("Configuration")
            if config then
                local fireRate = config:FindFirstChild("FireRate")
                if fireRate then fireRate.Value = Features.FireRate end
                local recoil = config:FindFirstChild("Recoil")
                if recoil then recoil.Value = Features.Recoil end
                local reload = config:FindFirstChild("ReloadTime")
                if reload then reload.Value = Features.ReloadTime end
            end
        end
    end
end

-- ============================================
-- SERVER HOP
-- ============================================
local function ServerHop()
    local PlaceID = game.PlaceId
    local url = "https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100"
    local success, result = pcall(function() return game:HttpGet(url) end)
    if success and result then
        local data = HttpService:JSONDecode(result)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(PlaceID, server.id, LocalPlayer)
                    return
                end
            end
        end
    end
    Notify("Error", "No servers found")
end

-- ============================================
-- FPS BOOST
-- ============================================
local function FPSBoost()
    Lighting.GlobalShadows = false
    Lighting.Technology = Enum.Technology.Compatibility
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") then
            obj.Enabled = false
        end
    end
end

-- ============================================
-- GUARDAR CONFIG
-- ============================================
local function SaveConfig()
    local dataToSave = {
        SilentAim = Features.SilentAim,
        AimLock = Features.AimLock,
        Prediction = Features.Prediction,
        ESPBoxes = Features.ESPBoxes,
        ESPNames = Features.ESPNames,
        ESPDistance = Features.ESPDistance,
        ESPChams = Features.ESPChams,
        WalkSpeed = Features.WalkSpeed,
        SpeedValue = Features.SpeedValue,
        SuperJump = Features.SuperJump,
        JumpPower = Features.JumpPower,
        InfiniteStamina = Features.InfiniteStamina,
        AntiKill = Features.AntiKill,
        EnableGunMods = Features.EnableGunMods,
        FireRate = Features.FireRate,
        Recoil = Features.Recoil,
        ThemeColor = Features.ThemeColor
    }
    pcall(function()
        writefile(ConfigFile, HttpService:JSONEncode(dataToSave))
        Notify("Config", "Saved!")
    end)
end

-- ============================================
-- UI (WINDUI)
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | BlockSpin",
    Author = "Optimized",
    Icon = "droplet",
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.F,
    OpenButton = {
        Title = "Open",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 2,
        Enabled = true,
        Draggable = true,
        Color = ColorSequence.new(Features.ThemeColor, Features.ThemeColor),
    },
})

-- 1. COMBAT (SILENT AIM + AIMLOCK)
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "crosshair" })

CombatTab:Section({ Title = "Silent Aim", Desc = "Prediction based targeting" })

CombatTab:Toggle({
    Title = "Silent Aim",
    Value = Features.SilentAim,
    Callback = function(v)
        Features.SilentAim = v
        DaHoodSettings.SilentAim = v
        SaveConfig()
    end,
})

CombatTab:Toggle({
    Title = "Aim Lock (Hold E)",
    Value = Features.AimLock,
    Callback = function(v)
        Features.AimLock = v
        DaHoodSettings.AimLock = v
        SaveConfig()
    end,
})

CombatTab:Slider({
    Title = "Prediction",
    Step = 0.001,
    Value = { Min = 0, Max = 0.5, Default = Features.Prediction },
    Callback = function(v)
        Features.Prediction = v
        DaHoodSettings.Prediction = v
        SaveConfig()
    end,
})

CombatTab:Section({ Title = "Defense", Desc = "Auto protection" })

CombatTab:Toggle({
    Title = "Anti Kill",
    Value = Features.AntiKill,
    Callback = function(v)
        Features.AntiKill = v
        if v then
            AntiKillConnection = RunService.Heartbeat:Connect(AntiKillFunction)
        elseif AntiKillConnection then
            AntiKillConnection:Disconnect()
        end
        SaveConfig()
    end,
})

CombatTab:Slider({
    Title = "Anti Kill Health %",
    Step = 5,
    Value = { Min = 5, Max = 50, Default = Features.AntiKillHealth },
    Callback = function(v)
        Features.AntiKillHealth = v
        SaveConfig()
    end,
})

-- 2. ESP (NUEVO SISTEMA)
local ESPTab = Window:Tab({ Title = "ESP", Icon = "eye" })

ESPTab:Section({ Title = "Player ESP", Desc = "Visual indicators" })

ESPTab:Toggle({
    Title = "Boxes",
    Value = Features.ESPBoxes,
    Callback = function(v)
        Features.ESPBoxes = v
        LowfiESP.Boxes = v
        SaveConfig()
    end,
})

ESPTab:Toggle({
    Title = "Names",
    Value = Features.ESPNames,
    Callback = function(v)
        Features.ESPNames = v
        LowfiESP.Names = v
        SaveConfig()
    end,
})

ESPTab:Toggle({
    Title = "Distance",
    Value = Features.ESPDistance,
    Callback = function(v)
        Features.ESPDistance = v
        LowfiESP.Distance = v
        SaveConfig()
    end,
})

ESPTab:Toggle({
    Title = "Chams (Highlight)",
    Value = Features.ESPChams,
    Callback = function(v)
        Features.ESPChams = v
        LowfiESP.Cham = v
        SaveConfig()
    end,
})

ESPTab:Slider({
    Title = "ESP Thickness",
    Step = 0.5,
    Value = { Min = 0.5, Max = 3, Default = Features.ESPThickness },
    Callback = function(v)
        Features.ESPThickness = v
        LowfiESP.Thickness = v
        SaveConfig()
    end,
})

-- 3. MOVEMENT
local MoveTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })

MoveTab:Section({ Title = "Speed" })

MoveTab:Toggle({
    Title = "Walk Speed",
    Value = Features.WalkSpeed,
    Callback = function(v)
        Features.WalkSpeed = v
        if v then task.spawn(WalkSpeedLoop) end
        SaveConfig()
    end,
})

MoveTab:Slider({
    Title = "Speed Value",
    Step = 5,
    Value = { Min = 16, Max = 200, Default = Features.SpeedValue },
    Callback = function(v)
        Features.SpeedValue = v
        SaveConfig()
    end,
})

MoveTab:Section({ Title = "Jump" })

MoveTab:Toggle({
    Title = "Super Jump",
    Value = Features.SuperJump,
    Callback = function(v)
        Features.SuperJump = v
        if v then task.spawn(SuperJumpLoop) end
        SaveConfig()
    end,
})

MoveTab:Slider({
    Title = "Jump Power",
    Step = 10,
    Value = { Min = 50, Max = 200, Default = Features.JumpPower },
    Callback = function(v)
        Features.JumpPower = v
        SaveConfig()
    end,
})

MoveTab:Toggle({
    Title = "Infinite Stamina",
    Value = Features.InfiniteStamina,
    Callback = function(v)
        Features.InfiniteStamina = v
        if v then task.spawn(InfiniteStaminaLoop) end
        SaveConfig()
    end,
})

-- 4. WEAPON
local WeaponTab = Window:Tab({ Title = "WEAPON", Icon = "target" })

WeaponTab:Section({ Title = "Gun Mods" })

WeaponTab:Toggle({
    Title = "Enable Gun Mods",
    Value = Features.EnableGunMods,
    Callback = function(v)
        Features.EnableGunMods = v
        ApplyGunMods()
        SaveConfig()
    end,
})

WeaponTab:Slider({
    Title = "Fire Rate",
    Step = 50,
    Value = { Min = 50, Max = 2000, Default = Features.FireRate },
    Callback = function(v)
        Features.FireRate = v
        ApplyGunMods()
        SaveConfig()
    end,
})

WeaponTab:Slider({
    Title = "Recoil",
    Step = 0.1,
    Value = { Min = 0, Max = 3, Default = Features.Recoil },
    Callback = function(v)
        Features.Recoil = v
        ApplyGunMods()
        SaveConfig()
    end,
})

-- 5. MISC
local MiscTab = Window:Tab({ Title = "MISC", Icon = "settings" })

MiscTab:Button({
    Title = "Server Hop",
    Callback = ServerHop
})

MiscTab:Toggle({
    Title = "FPS Boost",
    Value = Features.FPSBoost,
    Callback = function(v)
        Features.FPSBoost = v
        if v then FPSBoost() end
        SaveConfig()
    end,
})

MiscTab:Button({
    Title = "Save Config",
    Callback = SaveConfig
})

-- Seleccionar primera pestaña
CombatTab:Select()

print("Water Hub | BlockSpin - Loaded Successfully")
print("Silent Aim + ESP System Ready")
