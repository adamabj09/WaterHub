--// FARM v3.0 - DIAGNOSTIC VERSION
--// By: adamABJ | Debug for Delta

print("=" .. string.rep("=", 50))
print("FARM DIAGNOSTIC - Starting...")
print("=" .. string.rep("=", 50))

--// Paso 1: Servicios básicos
print("[STEP 1] Loading services...")
local success, err = pcall(function()
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local CoreGui = game:GetService("CoreGui")
    print("[STEP 1] ✓ Services loaded")
end)
if not success then print("[STEP 1] ✗ FAILED: " .. tostring(err)) return end

--// Paso 2: WindUI
print("[STEP 2] Loading WindUI...")
local WindUI
local success, err = pcall(function()
    WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if not success or not WindUI then
    print("[STEP 2] ✗ FAILED: " .. tostring(err))
    print("[STEP 2] Trying alternative WindUI...")
    pcall(function()
        WindUI = loadstring(game:HttpGet("https://pastebin.com/raw/U0mKbjvJ"))()
    end)
    if not WindUI then
        print("[STEP 2] ✗ All WindUI sources failed")
        return
    end
end
print("[STEP 2] ✓ WindUI loaded")

--// Paso 3: Config
print("[STEP 3] Setting up config...")
local ConfigFile = "FARM_Config.json"
local FARM = {
    Version = "3.0.0",
    Config = {
        AutoFarm = false,
        PreferredJob = "shelf_stocker",
        SmartJobSwitch = true,
        AutoDeposit = false,
        Humanize = true,
        MinDelay = 0.05,
        MaxDelay = 0.15,
        JitterAmount = 0.02,
        AntiRagdoll = false,
        AntiDamage = false,
        AutoRespawn = false,
        HideName = false,
        AutoRejoin = false,
        TargetJobId = "",
        TrackIncome = true,
        WebhookURL = "",
        ThemeColor = Color3.fromHex("#00F2FE")
    },
    State = {
        Active = false,
        CurrentJob = nil,
        StartTime = nil,
        TotalEarned = 0,
        IncomeRate = 0,
        IsFarming = false
    },
    Jobs = {}
}

-- Cargar config guardada
if isfile and isfile(ConfigFile) then
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(ConfigFile))
    end)
    if success and data then
        for k, v in pairs(data) do
            if FARM.Config[k] ~= nil then
                FARM.Config[k] = v
            end
        end
        print("[STEP 3] ✓ Config loaded from file")
    end
else
    print("[STEP 3] ✓ Using default config")
end

--// Paso 4: Funciones de utilidad
print("[STEP 4] Creating utility functions...")

function FARM:SaveConfig()
    if writefile then
        local success, encoded = pcall(function()
            return HttpService:JSONEncode(FARM.Config)
        end)
        if success then
            writefile(ConfigFile, encoded)
        end
    end
end

local function Notify(title, content)
    pcall(function()
        WindUI:Notify({ Title = title, Content = content, Duration = 3 })
    end)
end

function FARM:HumanDelay()
    local delay = math.random() * (FARM.Config.MaxDelay - FARM.Config.MinDelay) + FARM.Config.MinDelay
    if FARM.Config.JitterAmount then
        delay = delay + (math.random() - 0.5) * FARM.Config.JitterAmount
    end
    task.wait(math.max(0, delay))
end

print("[STEP 4] ✓ Utility functions created")

--// Paso 5: Game Modules
print("[STEP 5] Loading game modules...")
local Net, Char, Util, JobData, JobUtil
local success, err = pcall(function()
    local Modules = ReplicatedStorage:WaitForChild("Modules")
    local Core = Modules:WaitForChild("Core")
    local Game = Modules:WaitForChild("Game")
    
    Net = require(Core:WaitForChild("Net"))
    print("[STEP 5] ✓ Net loaded")
    Char = require(Core:WaitForChild("Char"))
    print("[STEP 5] ✓ Char loaded")
    Util = require(Core:WaitForChild("Util"))
    print("[STEP 5] ✓ Util loaded")
    JobData = require(Game:WaitForChild("Jobs"):WaitForChild("JobData"))
    print("[STEP 5] ✓ JobData loaded")
    JobUtil = require(Game:WaitForChild("Jobs"):WaitForChild("JobUtil"))
    print("[STEP 5] ✓ JobUtil loaded")
end)
if not success then
    print("[STEP 5] ✗ FAILED: " .. tostring(err))
    print("[STEP 5] Trying without JobData/JobUtil...")
end

--// Paso 6: Character setup
print("[STEP 6] Setting up character...")
local Character, Humanoid, HRP

local function SetupCharacter()
    Character = LocalPlayer.Character
    if Character then
        Humanoid = Character:FindFirstChild("Humanoid")
        HRP = Character:FindFirstChild("HumanoidRootPart")
        if Humanoid and HRP then
            print("[STEP 6] ✓ Character ready")
            return true
        end
    end
    return false
end

if not SetupCharacter() then
    print("[STEP 6] Waiting for character...")
    LocalPlayer.CharacterAdded:Wait()
    task.wait(1)
    SetupCharacter()
end

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
    print("[STEP 6] Character respawned")
end)

--// Paso 7: Job functions básicas (versión simplificada)
print("[STEP 7] Creating job functions...")

function FARM:TweenToPosition(position)
    if not HRP then return end
    local tween = TweenService:Create(HRP, TweenInfo.new(1, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(position)
    })
    tween:Play()
end

function FARM:IsAtPosition(position, tolerance)
    if not HRP then return false end
    return (HRP.Position - position).Magnitude <= (tolerance or 3)
end

function FARM:FirePrompt(prompt)
    if prompt and prompt:IsA("ProximityPrompt") then
        fireproximityprompt(prompt)
    end
end

--// Funciones de búsqueda simplificadas
function FARM:FindFreeGrill()
    for _, grill in pairs(Workspace:GetDescendants()) do
        if grill.Name == "SteakGrill" then
            local userId = grill:GetAttribute("user_id_assigned")
            if not userId or userId == 0 then
                return grill
            end
        end
    end
    return nil
end

function FARM:FindAvailableBox()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "PickUpBox" then
            local prompt = obj:FindFirstChild("ProximityPrompt")
            if prompt and prompt.Enabled then
                return obj
            end
        end
    end
    return nil
end

function FARM:FindEmptyShelf()
    for _, shelf in pairs(Workspace:GetDescendants()) do
        if shelf.Name == "Shelf" then
            if not shelf:GetAttribute("player_assigned") then
                return shelf
            end
        end
    end
    return nil
end

function FARM:FindNearestPuddle()
    local nearest, minDist = nil, math.huge
    if not HRP then return nil end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:match("Puddle") and not obj:GetAttribute("mopped") then
            local dist = (obj.Position - HRP.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = obj
            end
        end
    end
    return nearest
end

print("[STEP 7] ✓ Job functions created")

--// Paso 8: Inicializar seguridad (versión simplificada sin hooks)
print("[STEP 8] Setting up safety...")
if FARM.Config.AutoRespawn and Humanoid then
    Humanoid.Died:Connect(function()
        task.wait(2)
        local spawnLocation = LocalPlayer:FindFirstChild("SpawnCFrame")
        if spawnLocation and HRP then
            HRP.CFrame = spawnLocation.Value
        end
    end)
    print("[STEP 8] ✓ AutoRespawn enabled")
end

--// COMENTADO: Hooks que pueden fallar en Delta
--[[
if FARM.Config.AntiDamage and Humanoid then
    pcall(function()
        local mt = getrawmetatable(Humanoid)
        if mt then
            setreadonly(mt, false)
            local oldNewIndex = mt.__newindex
            mt.__newindex = function(t, k, v)
                if k == "Health" and v <= 0 then return end
                return oldNewIndex(t, k, v)
            end
            setreadonly(mt, true)
        end
    end)
end
]]

print("[STEP 8] ✓ Safety setup complete")

--// Paso 9: Crear UI
print("[STEP 9] Creating UI...")
local Window

local success, err = pcall(function()
    Window = WindUI:CreateWindow({
        Title = "FARM v" .. FARM.Version,
        Author = "By: adamABJ",
        Icon = "solar:bolt-bold",
        Theme = "Dark",
        NewElements = true,
        Transparent = true,
        ToggleKey = Enum.KeyCode.RightShift,
        Acrylic = false,
        OpenButton = {
            Title = "Open",
            CornerRadius = UDim.new(1, 0),
            StrokeThickness = 2,
            Enabled = true,
            Draggable = true,
            OnlyMobile = false,
            Scale = 0.5,
            Color = ColorSequence.new(FARM.Config.ThemeColor, FARM.Config.ThemeColor),
        },
    })
end)

if not success or not Window then
    print("[STEP 9] ✗ FAILED to create Window: " .. tostring(err))
    print("[STEP 9] Trying simpler Window...")
    pcall(function()
        Window = WindUI:CreateWindow({
            Title = "FARM",
            Theme = "Dark",
            ToggleKey = Enum.KeyCode.RightShift,
        })
    end)
    if not Window then
        print("[STEP 9] ✗ Cannot create Window")
        return
    end
end
print("[STEP 9] ✓ Window created")

--// Crear Tabs
local TabFarm = Window:Tab({ Title = "Farming", Icon = "solar:case-round-bold" })
local TabGeneral = Window:Tab({ Title = "General", Icon = "solar:user-bold" })
local TabServer = Window:Tab({ Title = "Server", Icon = "solar:server-bold" })
local TabConfig = Window:Tab({ Title = "Config", Icon = "solar:settings-bold" })

TabFarm:Select()
print("[STEP 9] ✓ Tabs created")

--// Paso 10: Agregar botones
print("[STEP 10] Adding UI elements...")

TabFarm:Section({ Title = "Auto Farm", Desc = "Automatic job farming" })

TabFarm:Toggle({
    Title = "Enable Auto Farm",
    Value = false,
    Callback = function(v)
        FARM.Config.AutoFarm = v
        FARM.State.Active = v
        print("[FARM] AutoFarm: " .. tostring(v))
        
        if v then
            -- Intentar iniciar farm simple
            Notify("FARM", "Farm started!")
        else
            Notify("FARM", "Farm stopped!")
        end
        FARM:SaveConfig()
    end,
})

TabFarm:Dropdown({
    Title = "Select Job",
    Value = FARM.Config.PreferredJob,
    Values = { "shelf_stocker", "steakhouse_cook", "janitor" },
    Callback = function(v)
        FARM.Config.PreferredJob = v
        print("[FARM] Job selected: " .. v)
        FARM:SaveConfig()
    end
})

TabFarm:Button({
    Title = "Test: Find Grill",
    Callback = function()
        local grill = FARM:FindFreeGrill()
        if grill then
            print("[TEST] ✓ Grill found: " .. grill:GetFullName())
            Notify("Test", "Grill found!")
        else
            print("[TEST] ✗ No grill found")
            Notify("Test", "No grill available")
        end
    end
})

TabFarm:Button({
    Title = "Test: Find Box",
    Callback = function()
        local box = FARM:FindAvailableBox()
        if box then
            print("[TEST] ✓ Box found: " .. box:GetFullName())
            Notify("Test", "Box found!")
        else
            print("[TEST] ✗ No box found")
            Notify("Test", "No box available")
        end
    end
})

TabFarm:Button({
    Title = "Test: Find Shelf",
    Callback = function()
        local shelf = FARM:FindEmptyShelf()
        if shelf then
            print("[TEST] ✓ Shelf found: " .. shelf:GetFullName())
            Notify("Test", "Shelf found!")
        else
            print("[TEST] ✗ No shelf found")
            Notify("Test", "No empty shelf")
        end
    end
})

TabFarm:Button({
    Title = "Test: Find Puddle",
    Callback = function()
        local puddle = FARM:FindNearestPuddle()
        if puddle then
            print("[TEST] ✓ Puddle found: " .. puddle:GetFullName())
            Notify("Test", "Puddle found!")
        else
            print("[TEST] ✗ No puddle found")
            Notify("Test", "No puddle found")
        end
    end
})

TabGeneral:Section({ Title = "Diagnostics" })

TabGeneral:Button({
    Title = "Check HRP",
    Callback = function()
        if HRP then
            print("[DIAG] ✓ HRP exists at: " .. tostring(HRP.Position))
            Notify("Diag", "HRP OK: " .. math.floor(HRP.Position.X) .. ", " .. math.floor(HRP.Position.Y))
        else
            print("[DIAG] ✗ No HRP")
            Notify("Diag", "No HRP found!")
        end
    end
})

TabGeneral:Button({
    Title = "Check Net",
    Callback = function()
        if Net then
            print("[DIAG] ✓ Net module loaded")
            Notify("Diag", "Net module OK")
        else
            print("[DIAG] ✗ Net module not loaded")
            Notify("Diag", "Net module missing")
        end
    end
})

TabGeneral:Button({
    Title = "Print All Info",
    Callback = function()
        print("\n=== FARM DIAGNOSTIC ===")
        print("Version: " .. FARM.Version)
        print("PlaceId: " .. game.PlaceId)
        print("JobId: " .. game.JobId)
        print("Players: " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers)
        print("Character: " .. tostring(Character))
        print("Humanoid: " .. tostring(Humanoid))
        print("HRP: " .. tostring(HRP))
        print("Net: " .. tostring(Net))
        print("JobData: " .. tostring(JobData))
        print("JobUtil: " .. tostring(JobUtil))
        print("Config.AutoFarm: " .. tostring(FARM.Config.AutoFarm))
        print("=======================\n")
        Notify("Diag", "Check console output")
    end
})

TabConfig:Section({ Title = "Configuration" })

TabConfig:Button({
    Title = "Save Config",
    Callback = function()
        FARM:SaveConfig()
        Notify("Config", "Saved!")
    end
})

print("[STEP 10] ✓ UI elements added")

--// Final
print("\n" .. string.rep("=", 50))
print("FARM DIAGNOSTIC LOADED SUCCESSFULLY")
print("Version: " .. FARM.Version)
print("Use the DIAGNOSTICS buttons to test functions")
print(string.rep("=", 50) .. "\n")

getgenv().FARM = FARM

Notify("FARM Diagnostic", "Loaded! Use test buttons to find issues")