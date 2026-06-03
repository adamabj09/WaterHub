--// FARM v3.0 - Blockspin Superior Edition
--// By: adamABJ
--// Executor: Delta (Fixed)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local gethui = gethui or function() return CoreGui end

--// CARGAR WINDUI (Forma correcta)
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

if not WindUI then
    warn("Error cargando WindUI")
    return
end

--// CONFIGURACIÓN
local ConfigFile = "FARM_Config.json"

local FARM = {
    Version = "3.0.0",
    Config = {},
    State = {
        Active = false,
        CurrentJob = nil,
        StartTime = nil,
        TotalEarned = 0,
        IncomeRate = 0,
        IsFarming = false
    },
    Hooks = {},
    Jobs = {},
    Threads = {}
}

--// Default Config
FARM.Config = {
    -- Farm
    AutoFarm = false,
    PreferredJob = "shelf_stocker",
    SmartJobSwitch = true,
    AutoDeposit = false,
    
    -- Anti-Detection
    Humanize = true,
    MinDelay = 0.05,
    MaxDelay = 0.15,
    JitterAmount = 0.02,
    
    -- Safety
    AntiRagdoll = false,
    AntiDamage = false,
    AutoRespawn = false,
    HideName = false,
    
    -- Server
    AutoRejoin = false,
    TargetJobId = "",
    
    -- Stats
    TrackIncome = true,
    WebhookURL = "",
    
    -- UI
    ThemeColor = Color3.fromHex("#00F2FE")
}

--// Cargar Config
local function LoadConfig()
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
        end
    end
end

LoadConfig()

--// Guardar Config
function FARM:SaveConfig()
    if writefile then
        local success, encoded = pcall(function()
            return HttpService:JSONEncode(FARM.Config)
        end)
        if success then
            writefile(ConfigFile, encoded)
            return true
        end
    end
    return false
end

--// Reset Config
function FARM:ResetConfig()
    FARM.Config = {
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
    }
    FARM:SaveConfig()
end

--// Notificación
local function Notify(title, content)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = content,
            Duration = 3
        })
    end)
end

--// Game Modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Core = Modules:WaitForChild("Core")
local Game = Modules:WaitForChild("Game")

local Net = require(Core:WaitForChild("Net"))
local Char = require(Core:WaitForChild("Char"))
local Util = require(Core:WaitForChild("Util"))
local JobData = require(Game:WaitForChild("Jobs"):WaitForChild("JobData"))
local JobUtil = require(Game:WaitForChild("Jobs"):WaitForChild("JobUtil"))

--// Character References
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    HRP = char:WaitForChild("HumanoidRootPart")
end)

--// SECURE NETWORKING (Metamethod Hooking - Fixed for Delta)
function FARM:InitSecureNetworking()
    local mt = getrawmetatable(Net)
    if not mt then return end
    
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall
    
    mt.__namecall = function(self, ...)
        local method = getnamecallmethod()
        if method == "send" and self == Net and FARM.Config.Humanize then
            FARM:HumanDelay()
        end
        return oldNamecall(self, ...)
    end
    
    setreadonly(mt, true)
end

function FARM:HumanDelay()
    local delay = math.random() * (FARM.Config.MaxDelay - FARM.Config.MinDelay) + FARM.Config.MinDelay
    if FARM.Config.JitterAmount then
        delay = delay + (math.random() - 0.5) * FARM.Config.JitterAmount
    end
    task.wait(math.max(0, delay))
end

--// ANTI-RAGDOLL & SAFETY
function FARM:InitSafety()
    if FARM.Config.AntiRagdoll then
        local success, Ragdoll = pcall(function()
            return require(Game:WaitForChild("Ragdoll"))
        end)
        if success and Ragdoll and Ragdoll.EnableRagdoll then
            Ragdoll.EnableRagdoll = function() return nil end
        end
    end
    
    if FARM.Config.AntiDamage then
        local mt = getrawmetatable(Humanoid)
        if mt then
            setreadonly(mt, false)
            local oldNewIndex = mt.__newindex
            mt.__newindex = function(t, k, v)
                if k == "Health" and v <= 0 then
                    return
                end
                return oldNewIndex(t, k, v)
            end
            setreadonly(mt, true)
        end
    end
    
    if FARM.Config.AutoRespawn then
        Humanoid.Died:Connect(function()
            task.wait(2)
            local spawnLocation = LocalPlayer:FindFirstChild("SpawnCFrame")
            if spawnLocation and HRP then
                HRP.CFrame = spawnLocation.Value
            end
        end)
    end
end

--// JOB SYSTEM - COOK
FARM.Jobs.Cook = {
    Name = "steakhouse_cook",
    State = "IDLE",
    CurrentGrill = nil,
    
    Start = function(self)
        if LocalPlayer:GetAttribute("Job") ~= self.Name then
            FARM:ApplyForJob(self.Name)
        end
        
        FARM.State.IsFarming = true
        
        while FARM.State.Active and FARM.State.CurrentJob == self.Name and FARM.State.IsFarming do
            self:Tick()
            task.wait(0.1)
        end
    end,
    
    Stop = function(self)
        FARM.State.IsFarming = false
        self.State = "IDLE"
    end,
    
    Tick = function(self)
        if self.State == "IDLE" then
            local grill = FARM:FindFreeGrill()
            if grill then
                self.CurrentGrill = grill
                self.State = "WALKING"
                FARM:TweenToPosition(grill.Position)
            else
                task.wait(1)
            end
            
        elseif self.State == "WALKING" then
            if FARM:IsAtPosition(self.CurrentGrill.Position, 5) then
                self.State = "COOKING"
            else
                task.wait(0.1)
            end
            
        elseif self.State == "COOKING" then
            Net.send("start_grilling_2", self.CurrentGrill)
            
            local cookTime = math.random(8, 12)
            task.wait(cookTime)
            
            if FARM.State.IsFarming then
                Net.send("finish_grilling_2", self.CurrentGrill, "Cooked")
                self.State = "IDLE"
            end
        end
    end
}

--// JOB SYSTEM - STOCKER (La joya - Hermanos no tiene esto)
FARM.Jobs.Stocker = {
    Name = "shelf_stocker",
    State = "IDLE",
    HasBox = false,
    CurrentShelf = nil,
    
    Start = function(self)
        if LocalPlayer:GetAttribute("Job") ~= self.Name then
            FARM:ApplyForJob(self.Name)
        end
        
        FARM.State.IsFarming = true
        
        while FARM.State.Active and FARM.State.CurrentJob == self.Name and FARM.State.IsFarming do
            self:Tick()
            task.wait(0.1)
        end
    end,
    
    Stop = function(self)
        FARM.State.IsFarming = false
        self.State = "IDLE"
    end,
    
    Tick = function(self)
        if self.State == "IDLE" then
            if not self.HasBox then
                local box = FARM:FindAvailableBox()
                if box then
                    FARM:TweenToPosition(box.Position)
                    task.wait(FARM:CalculateTweenTime(box.Position))
                    FARM:FirePrompt(box:FindFirstChild("ProximityPrompt"))
                    self.HasBox = true
                else
                    task.wait(1)
                end
            else
                local shelf = FARM:FindEmptyShelf()
                if shelf then
                    self.CurrentShelf = shelf
                    self.State = "WALKING_TO_SHELF"
                    FARM:TweenToPosition(shelf.Position)
                else
                    task.wait(1)
                end
            end
            
        elseif self.State == "WALKING_TO_SHELF" then
            if FARM:IsAtPosition(self.CurrentShelf.Position, 3) then
                self.State = "STOCKING"
            else
                task.wait(0.1)
            end
            
        elseif self.State == "STOCKING" then
            local success = Net.get("player_started_stocking_shelf", self.CurrentShelf)
            if success then
                local stockTime = 10 / FARM:GetSkillMultiplier("speed")
                task.wait(stockTime)
                
                if FARM.State.IsFarming then
                    Net.get("player_stocked_shelf", self.CurrentShelf)
                    self.HasBox = false
                    self.State = "IDLE"
                end
            else
                self.State = "IDLE"
            end
        end
    end
}

--// JOB SYSTEM - JANITOR
FARM.Jobs.Janitor = {
    Name = "janitor",
    State = "IDLE",
    CurrentPuddle = nil,
    
    Start = function(self)
        if LocalPlayer:GetAttribute("Job") ~= self.Name then
            FARM:ApplyForJob(self.Name)
        end
        
        FARM:EquipTool("Mop")
        FARM.State.IsFarming = true
        
        while FARM.State.Active and FARM.State.CurrentJob == self.Name and FARM.State.IsFarming do
            self:Tick()
            task.wait(0.1)
        end
    end,
    
    Stop = function(self)
        FARM.State.IsFarming = false
        self.State = "IDLE"
    end,
    
    Tick = function(self)
        if self.State == "IDLE" then
            local puddle = FARM:FindNearestPuddle()
            if puddle then
                self.CurrentPuddle = puddle
                self.State = "WALKING"
                FARM:TweenToPosition(puddle.Position)
            else
                task.wait(1)
            end
            
        elseif self.State == "WALKING" then
            if FARM:IsAtPosition(self.CurrentPuddle.Position, 5) then
                self.State = "CLEANING"
            else
                task.wait(0.1)
            end
            
        elseif self.State == "CLEANING" then
            Net.send("start_cleaning_puddle", self.CurrentPuddle)
            
            local mopLength = FARM:GetMopLength(self.CurrentPuddle)
            task.wait(mopLength)
            
            if FARM.State.IsFarming then
                if not FARM:IsAtPosition(self.CurrentPuddle.Position, 5) then
                    Net.send("player_moved_from_puddle", self.CurrentPuddle)
                end
                self.State = "IDLE"
            end
        end
    end
}

--// UTILITY FUNCTIONS
function FARM:CalculateTweenTime(targetPos)
    if not HRP then return 2 end
    local distance = (HRP.Position - targetPos).Magnitude
    return distance / 16
end

function FARM:TweenToPosition(position)
    if not HRP then return end
    local distance = (HRP.Position - position).Magnitude
    local duration = distance / 16
    
    local tween = TweenService:Create(HRP, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
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

function FARM:ApplyForJob(jobName)
    local locations = {
        ["steakhouse_cook"] = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Tiles") and Workspace.Map.Tiles:FindFirstChild("ShoppingTile") and Workspace.Map.Tiles.ShoppingTile:FindFirstChild("SteakHouse") and Workspace.Map.Tiles.ShoppingTile.SteakHouse:FindFirstChild("Interior") and Workspace.Map.Tiles.ShoppingTile.SteakHouse.Interior:FindFirstChild("SteakHouseBeacon") and Workspace.Map.Tiles.ShoppingTile.SteakHouse.Interior.SteakHouseBeacon:FindFirstChild("TouchPart"),
        ["shelf_stocker"] = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Tiles") and Workspace.Map.Tiles:FindFirstChild("GasStationTile") and Workspace.Map.Tiles.GasStationTile:FindFirstChild("Quick11") and Workspace.Map.Tiles.GasStationTile.Quick11:FindFirstChild("Interior") and Workspace.Map.Tiles.GasStationTile.Quick11.Interior:FindFirstChild("Quick11Beacon") and Workspace.Map.Tiles.GasStationTile.Quick11.Interior.Quick11Beacon:FindFirstChild("TouchPart"),
        ["janitor"] = Workspace:FindFirstChild("BurgePlaceBeacon") and Workspace.BurgePlaceBeacon:FindFirstChild("TouchPart")
    }
    
    local beacon = locations[jobName]
    if beacon then
        self:TweenToPosition(beacon.Position)
        task.wait(self:CalculateTweenTime(beacon.Position) + 0.5)
        Net.send("apply_for_job", beacon)
        task.wait(1)
    end
end

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
            local playerAssigned = shelf:GetAttribute("player_assigned")
            if not playerAssigned then
                return shelf
            end
        end
    end
    return nil
end

function FARM:FindNearestPuddle()
    local nearest, minDist = nil, math.huge
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:match("Puddle") and not obj:GetAttribute("mopped") then
            if HRP then
                local dist = (obj.Position - HRP.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

function FARM:GetSkillMultiplier(skillType)
    return 1
end

function FARM:GetMopLength(puddle)
    local spillTypes = JobData.job_info.janitor.spill_types
    for typeName, data in pairs(spillTypes) do
        if puddle.Name:match(typeName) then
            return data.mop_length
        end
    end
    return 5
end

function FARM:EquipTool(toolName)
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        local tool = backpack:FindFirstChild(toolName)
        if tool and Humanoid then
            Humanoid:EquipTool(tool)
        end
    end
end

function FARM:GetBestJob()
    return FARM.Config.PreferredJob
end

--// INCOME TRACKER
function FARM:InitIncomeTracker()
    if not FARM.Config.TrackIncome then return end
    
    FARM.State.StartTime = tick()
    FARM.State.StartMoney = LocalPlayer:GetAttribute("HandCash") or 0
    
    LocalPlayer:GetAttributeChangedSignal("HandCash"):Connect(function()
        local current = LocalPlayer:GetAttribute("HandCash") or 0
        FARM.State.TotalEarned = current - FARM.State.StartMoney
        local elapsed = (tick() - FARM.State.StartTime) / 3600
        FARM.State.IncomeRate = FARM.State.TotalEarned / math.max(elapsed, 0.001)
    end)
end

--// SERVER FUNCTIONS
function FARM:GetServerInfo()
    return {
        PlaceId = game.PlaceId,
        Players = #Players:GetPlayers(),
        MaxPlayers = Players.MaxPlayers,
        Ping = math.floor(LocalPlayer:GetNetworkPing() * 1000),
        JobId = game.JobId
    }
end

function FARM:CopyJobId()
    if setclipboard then
        setclipboard(game.JobId)
        return true
    end
    return false
end

function FARM:TeleportToJobId(jobId)
    if jobId and jobId ~= "" then
        TeleportService:TeleportToPlaceInstance(game.PlaceId, jobId, LocalPlayer)
    end
end

function FARM:RejoinSameServer()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end

function FARM:ServerHop()
    local PlaceID = game.PlaceId
    local url = "https://games.roblox.com/v1/games/" .. PlaceID .. "/servers/Public?sortOrder=Asc&limit=100"
    
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and result then
        local data = HttpService:JSONDecode(result)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    TeleportService:TeleportToPlaceInstance(PlaceID, server.id, LocalPlayer)
                    return true
                end
            end
        end
    end
    return false
end

--// INITIALIZE
FARM:InitSecureNetworking()
FARM:InitSafety()
FARM:InitIncomeTracker()

--// WINDUI WINDOW
local Window = WindUI:CreateWindow({
    Title = "FARM",
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

--// TABS
local TabFarm = Window:Tab({ Title = "Farming", Icon = "solar:case-round-bold" })
local TabGeneral = Window:Tab({ Title = "General", Icon = "solar:user-bold" })
local TabServer = Window:Tab({ Title = "Server", Icon = "solar:server-bold" })
local TabConfig = Window:Tab({ Title = "Config", Icon = "solar:settings-bold" })

TabFarm:Select()

--// FARMING TAB
TabFarm:Section({ Title = "Auto Farm", Desc = "Automatic job farming" })

TabFarm:Toggle({
    Title = "Enable Auto Farm",
    Value = FARM.Config.AutoFarm,
    Callback = function(v)
        FARM.Config.AutoFarm = v
        FARM.State.Active = v
        
        if v then
            local job = FARM.Config.SmartJobSwitch and FARM:GetBestJob() or FARM.Config.PreferredJob
            FARM.State.CurrentJob = job
            
            if job == "steakhouse_cook" then
                FARM.Jobs.Cook:Start()
            elseif job == "shelf_stocker" then
                FARM.Jobs.Stocker:Start()
            elseif job == "janitor" then
                FARM.Jobs.Janitor:Start()
            end
            
            Notify("FARM", "Started farming: " .. job)
        else
            FARM.State.Active = false
            FARM.State.IsFarming = false
            if FARM.Jobs.Cook then FARM.Jobs.Cook:Stop() end
            if FARM.Jobs.Stocker then FARM.Jobs.Stocker:Stop() end
            if FARM.Jobs.Janitor then FARM.Jobs.Janitor:Stop() end
            Notify("FARM", "Stopped farming")
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
        FARM:SaveConfig()
    end
})

TabFarm:Toggle({
    Title = "Smart Job Switch",
    Value = FARM.Config.SmartJobSwitch,
    Callback = function(v)
        FARM.Config.SmartJobSwitch = v
        FARM:SaveConfig()
    end
})

TabFarm:Toggle({
    Title = "Auto Deposit",
    Value = FARM.Config.AutoDeposit,
    Callback = function(v)
        FARM.Config.AutoDeposit = v
        FARM:SaveConfig()
    end
})

TabFarm:Section({ Title = "Anti-Detection", Desc = "Human behavior simulation" })

TabFarm:Toggle({
    Title = "Humanize Actions",
    Value = FARM.Config.Humanize,
    Callback = function(v)
        FARM.Config.Humanize = v
        FARM:SaveConfig()
    end
})

TabFarm:Slider({
    Title = "Min Delay",
    Step = 0.01,
    Value = { Min = 0, Max = 1, Default = FARM.Config.MinDelay },
    Callback = function(v)
        FARM.Config.MinDelay = v
        FARM:SaveConfig()
    end
})

TabFarm:Slider({
    Title = "Max Delay",
    Step = 0.01,
    Value = { Min = 0, Max = 1, Default = FARM.Config.MaxDelay },
    Callback = function(v)
        FARM.Config.MaxDelay = v
        FARM:SaveConfig()
    end
})

--// GENERAL TAB
TabGeneral:Section({ Title = "Safety Features", Desc = "Protection settings" })

TabGeneral:Toggle({
    Title = "Anti Ragdoll",
    Value = FARM.Config.AntiRagdoll,
    Callback = function(v)
        FARM.Config.AntiRagdoll = v
        Notify("FARM", "Restart script to apply Anti-Ragdoll")
        FARM:SaveConfig()
    end
})

TabGeneral:Toggle({
    Title = "Anti Damage",
    Value = FARM.Config.AntiDamage,
    Callback = function(v)
        FARM.Config.AntiDamage = v
        Notify("FARM", "Restart script to apply Anti-Damage")
        FARM:SaveConfig()
    end
})

TabGeneral:Toggle({
    Title = "Auto Respawn",
    Value = FARM.Config.AutoRespawn,
    Callback = function(v)
        FARM.Config.AutoRespawn = v
        FARM:SaveConfig()
    end
})

TabGeneral:Toggle({
    Title = "Hide Name",
    Value = FARM.Config.HideName,
    Callback = function(v)
        FARM.Config.HideName = v
        if v then
            local head = Character:FindFirstChild("Head")
            if head then
                local nametag = head:FindFirstChild("Nametag")
                if nametag then nametag:Destroy() end
            end
        end
        FARM:SaveConfig()
    end
})

TabGeneral:Section({ Title = "Statistics", Desc = "Farming stats" })

local StatsLabel = TabGeneral:Label({ Title = "Income: $0/hr | Total: $0" })

task.spawn(function()
    while task.wait(1) do
        local rate = math.floor(FARM.State.IncomeRate or 0)
        local total = math.floor(FARM.State.TotalEarned or 0)
        StatsLabel:SetTitle(string.format("Income: $%d/hr | Total: $%d", rate, total))
    end
end)

--// SERVER TAB
TabServer:Section({ Title = "Server Information", Desc = "Current server details" })

local ServerInfo = FARM:GetServerInfo()
local InfoLabel = TabServer:Label({ 
    Title = string.format("PlaceId: %d\nPlayers: %d/%d\nPing: %dms\nJobId: %s...", 
        ServerInfo.PlaceId, ServerInfo.Players, ServerInfo.MaxPlayers, 
        ServerInfo.Ping, string.sub(ServerInfo.JobId, 1, 20)) 
})

-- Actualizar info cada 5 segundos
task.spawn(function()
    while task.wait(5) do
        local info = FARM:GetServerInfo()
        InfoLabel:SetTitle(string.format("PlaceId: %d\nPlayers: %d/%d\nPing: %dms\nJobId: %s...", 
            info.PlaceId, info.Players, info.MaxPlayers, info.Ping, string.sub(info.JobId, 1, 20)))
    end
end)

TabServer:Input({
    Title = "Target JobId",
    Placeholder = "Enter JobId to teleport...",
    Default = FARM.Config.TargetJobId,
    Callback = function(v)
        FARM.Config.TargetJobId = v
        FARM:SaveConfig()
    end
})

TabServer:Button({
    Title = "Copy JobId",
    Desc = "Copy current server's JobId to clipboard",
    Callback = function()
        if FARM:CopyJobId() then
            Notify("Success", "JobId copied to clipboard!")
        else
            Notify("Error", "Clipboard not available")
        end
    end
})

TabServer:Button({
    Title = "Teleport to JobId",
    Desc = "Teleport to target server",
    Callback = function()
        if FARM.Config.TargetJobId ~= "" then
            FARM:TeleportToJobId(FARM.Config.TargetJobId)
        else
            Notify("Error", "Enter a JobId first")
        end
    end
})

TabServer:Button({
    Title = "Rejoin Same Server",
    Callback = function()
        FARM:RejoinSameServer()
    end
})

TabServer:Button({
    Title = "Server Hop",
    Callback = function()
        Notify("Server Hop", "Finding new server...")
        if FARM:ServerHop() then
            Notify("Success", "Joining new server...")
        else
            Notify("Error", "No servers found")
        end
    end
})

--// CONFIG TAB
TabConfig:Section({ Title = "Configuration", Desc = "Save and manage settings" })

TabConfig:Button({
    Title = "Save Config",
    Desc = "Save current configuration to file",
    Callback = function()
        if FARM:SaveConfig() then
            Notify("Success", "Configuration saved!")
        else
            Notify("Error", "Could not save config")
        end
    end
})

TabConfig:Button({
    Title = "Reset Config",
    Desc = "Reset all settings to default",
    Callback = function()
        FARM:ResetConfig()
        Notify("Success", "Configuration reset to default!")
    end
})

TabConfig:Button({
    Title = "Wipe Workspace",
    Desc = "Delete all FARM files",
    Callback = function()
        if delfile and isfile then
            if isfile(ConfigFile) then
                delfile(ConfigFile)
            end
        end
        Notify("Success", "Workspace wiped!")
    end
})

--// Welcome Notification
Notify("FARM Loaded", "v" .. FARM.Version .. " by adamABJ | Ready to dominate Blockspin")

--// Auto-start si estaba activo
if FARM.Config.AutoFarm then
    task.wait(2)
    FARM.State.Active = true
    local job = FARM.Config.PreferredJob
    FARM.State.CurrentJob = job
    
    if job == "steakhouse_cook" then
        FARM.Jobs.Cook:Start()
    elseif job == "shelf_stocker" then
        FARM.Jobs.Stocker:Start()
    elseif job == "janitor" then
        FARM.Jobs.Janitor:Start()
    end
end

getgenv().FARM = FARM

print("FARM v" .. FARM.Version .. " by adamABJ - Loaded Successfully (Delta Fixed)")