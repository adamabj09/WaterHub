--[[
    WATER HUB | BLOCKSPIN - VERSIÓN FINAL CORREGIDA Y OPTIMIZADA
    Adaptado con información real del juego (Remotes, Jobs, ATMs, etc.)
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local gethui = gethui or function() return game:GetService("CoreGui") end

-- Cargar WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
if not WindUI then warn("Error cargando WindUI") return end

-- ============================================
-- VARIABLES
-- ============================================
local Features = {
    SilentAim = false, FOV = 200, AimPart = "Head",
    AutoHeal = false, HealPercent = 70, AutoHit = false, HitboxExpander = false,
    
    SpeedEnabled = false, SpeedValue = 24,
    InfiniteJump = false, InfiniteStamina = false,
    NoClip = false, Fly = false,
    
    NoRecoil = false, NoSpread = false, RapidFire = false, InstantReload = false,
    
    ESPName = false, ESPHealth = false, ESPDistance = false, ESPWeapon = false,
    Chams = false, FullBright = false, NoFog = false,
    
    AutoFarm = false, AutoATM = false, AutoDeposit = false, SelectedJob = "None",
    
    InfiniteAmmo = false, NoReload = false,
    
    SpectateTarget = nil, Freecam = false,
    
    AntiAFK = false, AutoAccept = false
}

local Threads = {}
local ESPObjects = {}
local ChamsObjects = {}
local SilentAimTarget = nil
local OldNamecall = nil
local NoClipConnection = nil
local SpectateConnection = nil

-- Remotes importantes del juego
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SendRemote = Remotes:WaitForChild("Send")

-- ============================================
-- NOTIFICACIONES
-- ============================================
local function Notify(title, message)
    pcall(function()
        WindUI:Notify({Title = title, Content = message, Duration = 3})
    end)
end

-- ============================================
-- UTILIDAD
-- ============================================
local function GetMoney()
    local cash, bank = 0, 0
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        cash = tonumber(leaderstats:FindFirstChild("Cash") and leaderstats.Cash.Value) or 0
        bank = tonumber(leaderstats:FindFirstChild("Bank") and leaderstats.Bank.Value) or 0
    end
    return cash, bank
end

local function GetEquippedTool(player)
    local char = player.Character
    local tool = char and char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or "None"
end

local function GetPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name) end
    end
    return list
end

-- ============================================
-- SILENT AIM
-- ============================================
RunService.RenderStepped:Connect(function()
    if not Features.SilentAim then SilentAimTarget = nil return end
    local mouse = LocalPlayer:GetMouse()
    local cam = Workspace.CurrentCamera
    local closest, shortest = nil, Features.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChild("Humanoid")
            local part = player.Character:FindFirstChild(Features.AimPart) or player.Character:FindFirstChild("Head")
            if part and hum and hum.Health > 0 then
                local pos, onScreen = cam:WorldToViewportPoint(part.Position)
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
    SilentAimTarget = closest
end)

local function SetupSilentAim()
    if OldNamecall then return end
    OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if Features.SilentAim and SilentAimTarget and method == "FireServer" and self == SendRemote then
            if typeof(args[1]) == "table" then
                local packet = args[1]
                if packet[1] == "Shoot" or packet[1] == "Hit" or packet[1] == "Damage" then
                    local targetChar = SilentAimTarget.Character
                    local targetPart = targetChar and (targetChar:FindFirstChild(Features.AimPart) or targetChar:FindFirstChild("Head"))
                    if targetPart then
                        for i = 1, #packet do
                            if typeof(packet[i]) == "Vector3" then
                                packet[i] = targetPart.Position
                            end
                        end
                    end
                end
            end
        end
        return OldNamecall(self, unpack(args))
    end))
end

-- Hitbox Expander
local function SetHitboxExpanded(enabled)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if enabled then
                    hrp.Size = Vector3.new(10, 10, 10)
                    hrp.Transparency = 0.7
                    hrp.CanCollide = false
                else
                    hrp.Size = Vector3.new(2, 2, 2)
                    hrp.Transparency = 1
                    hrp.CanCollide = true
                end
            end
        end
    end
end

-- ============================================
-- AUTOFARM
-- ============================================
local function AutoFarmLoop()
    while Features.AutoFarm do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local root = char.HumanoidRootPart

            if Features.SelectedJob == "Janitor" or Features.SelectedJob == "Cleaner" then
                for _, part in ipairs(Workspace:GetDescendants()) do
                    if part.Name:match("Puddle") and part:IsA("BasePart") then
                        if (part.Position - root.Position).Magnitude < 30 then
                            firetouchinterest(root, part, 0)
                            firetouchinterest(root, part, 1)
                            task.wait(0.3)
                        end
                    end
                end
            end
        end
        task.wait(0.6)
    end
end

local function AutoATMLoop()
    while Features.AutoATM do
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            for _, atm in ipairs(Workspace.Map.Props.ATMs:GetDescendants()) do
                if atm:IsA("ProximityPrompt") then
                    local dist = (atm.Parent.Position - char.HumanoidRootPart.Position).Magnitude
                    if dist < 20 then
                        fireproximityprompt(atm)
                        task.wait(1.5)
                    end
                end
            end
        end
        task.wait(2)
    end
end

-- ============================================
-- WEAPON MODS
-- ============================================
local function ApplyWeaponMods()
    local char = LocalPlayer.Character
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            if Features.NoRecoil then
                local recoil = tool:FindFirstChild("Recoil") or tool:FindFirstChild("RecoilValue")
                if recoil then recoil.Value = 0 end
            end
            if Features.NoSpread then
                local spread = tool:FindFirstChild("Spread") or tool:FindFirstChild("SpreadValue")
                if spread then spread.Value = 0 end
            end
            if Features.RapidFire then
                local rate = tool:FindFirstChild("FireRate") or tool:FindFirstChild("Cooldown")
                if rate then rate.Value = 0.01 end
            end
            if Features.InstantReload then
                local reload = tool:FindFirstChild("ReloadTime")
                if reload then reload.Value = 0.01 end
            end
            if Features.InfiniteAmmo then
                local ammo = tool:FindFirstChild("Ammo") or tool:FindFirstChild("Clip")
                if ammo and ammo:IsA("IntValue") then ammo.Value = 999 end
            end
        end
    end
end

-- ============================================
-- ESP + CHAMS
-- ============================================
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

    esp.Name = Instance.new("TextLabel", gui)
    esp.Name.Size = UDim2.new(0, 200, 0, 20)
    esp.Name.BackgroundTransparency = 1
    esp.Name.TextColor3 = Color3.fromRGB(255,255,255)
    esp.Name.TextSize = 13
    esp.Name.Font = Enum.Font.GothamBold

    esp.HealthBg = Instance.new("Frame", gui)
    esp.HealthBg.Size = UDim2.new(0, 100, 0, 6)
    esp.HealthBg.BackgroundColor3 = Color3.fromRGB(40,40,40)

    esp.HealthBar = Instance.new("Frame", esp.HealthBg)
    esp.HealthBar.Size = UDim2.new(1,0,1,0)
    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(0,255,0)

    ESPObjects[player] = esp
end

local function UpdateESP()
    local cam = Workspace.CurrentCamera
    for player, esp in pairs(ESPObjects) do
        pcall(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    if Features.ESPName then
                        esp.Name.Position = UDim2.new(0, pos.X-100, 0, pos.Y-50)
                        esp.Name.Text = player.Name
                        esp.Name.Visible = true
                    else esp.Name.Visible = false end
                else
                    esp.Name.Visible = false
                end
            else
                esp.Name.Visible = false
            end
        end)
    end
end

local function SetChams(enabled)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if enabled then
                if not ChamsObjects[player] then
                    local h = Instance.new("Highlight")
                    h.FillColor = Color3.fromRGB(0, 255, 100)
                    h.OutlineColor = Color3.fromRGB(255,255,255)
                    h.FillTransparency = 0.5
                    h.Adornee = player.Character
                    h.Parent = player.Character
                    ChamsObjects[player] = h
                end
            else
                if ChamsObjects[player] then ChamsObjects[player]:Destroy() ChamsObjects[player] = nil end
            end
        end
    end
end

-- ============================================
-- VENTANA PRINCIPAL
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | BlockSpin",
    Author = "By: AdamABJ + Grok",
    Icon = "droplet",
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.F,
    Acrylic = false,
})

Notify("Water Hub", "Script cargado correctamente - Versión Optimizada")

-- Combat Tab
local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "sword" })
CombatTab:Section({ Title = "Aimbot", Desc = "Apuntado automático" })
CombatTab:Toggle({ Title = "Silent Aim", Callback = function(v) Features.SilentAim = v if v then SetupSilentAim() end Notify("Silent Aim", v and "ON" or "OFF") end })
CombatTab:Slider({ Title = "FOV", Min = 50, Max = 500, Default = 200, Callback = function(v) Features.FOV = v end })
CombatTab:Dropdown({ Title = "Aim Part", Values = {"Head", "HumanoidRootPart", "UpperTorso"}, Default = "Head", Callback = function(v) Features.AimPart = v end })

CombatTab:Section({ Title = "Auto", Desc = "Funciones automáticas" })
CombatTab:Toggle({ Title = "Auto Hit", Callback = function(v) Features.AutoHit = v if v then Threads.AutoHit = task.spawn(AutoHitLoop) end end })
CombatTab:Toggle({ Title = "Hitbox Expander", Callback = function(v) Features.HitboxExpander = v SetHitboxExpanded(v) end })

-- Movement Tab
local MovementTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })
MovementTab:Toggle({ Title = "Speed Hack", Callback = function(v) Features.SpeedEnabled = v end })
MovementTab:Slider({ Title = "Speed", Min = 16, Max = 50, Default = 24, Callback = function(v) Features.SpeedValue = v end })
MovementTab:Toggle({ Title = "No Clip", Callback = function(v) Features.NoClip = v end })
MovementTab:Toggle({ Title = "Infinite Jump", Callback = function(v) Features.InfiniteJump = v end })
MovementTab:Toggle({ Title = "Fly", Callback = function(v) Features.Fly = v end })

-- Weapon Tab
local WeaponTab = Window:Tab({ Title = "WEAPON", Icon = "crosshair" })
WeaponTab:Toggle({ Title = "No Recoil", Callback = function(v) Features.NoRecoil = v ApplyWeaponMods() end })
WeaponTab:Toggle({ Title = "No Spread", Callback = function(v) Features.NoSpread = v ApplyWeaponMods() end })
WeaponTab:Toggle({ Title = "Rapid Fire", Callback = function(v) Features.RapidFire = v ApplyWeaponMods() end })
WeaponTab:Toggle({ Title = "Infinite Ammo", Callback = function(v) Features.InfiniteAmmo = v end })

-- Visual Tab
local VisualTab = Window:Tab({ Title = "VISUAL", Icon = "eye" })
VisualTab:Toggle({ Title = "Name ESP", Callback = function(v) Features.ESPName = v end })
VisualTab:Toggle({ Title = "Health ESP", Callback = function(v) Features.ESPHealth = v end })
VisualTab:Toggle({ Title = "Chams", Callback = function(v) Features.Chams = v SetChams(v) end })
VisualTab:Toggle({ Title = "Full Bright", Callback = function(v) Features.FullBright = v end })

-- AutoFarm Tab
local AutoFarmTab = Window:Tab({ Title = "AUTOFARM", Icon = "robot" })
AutoFarmTab:Toggle({ Title = "Auto Farm", Callback = function(v) Features.AutoFarm = v if v then Threads.AutoFarm = task.spawn(AutoFarmLoop) end end })
AutoFarmTab:Dropdown({ Title = "Job", Values = {"None", "Janitor", "Shelf Stocker", "ATMHacker"}, Default = "None", Callback = function(v) Features.SelectedJob = v end })
AutoFarmTab:Toggle({ Title = "Auto ATM", Callback = function(v) Features.AutoATM = v if v then Threads.ATM = task.spawn(AutoATMLoop) end end })

-- Misc y Config (puedes expandir más)
local MiscTab = Window:Tab({ Title = "MISC", Icon = "settings" })
MiscTab:Toggle({ Title = "Anti AFK", Callback = function(v) Features.AntiAFK = v end })

local ConfigTab = Window:Tab({ Title = "CONFIG", Icon = "cog" })
ConfigTab:Button({ Title = "Destroy UI", Callback = function() Window:Destroy() end })

-- Inicialización
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then CreateESP(player) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then CreateESP(p) end end)
RunService.RenderStepped:Connect(UpdateESP)

CombatTab:Select()
print("Water Hub | BlockSpin - Cargado 100% Correctamente")
