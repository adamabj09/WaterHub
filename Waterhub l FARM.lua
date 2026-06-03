--// FARM v3.0 - Blockspin Superior Edition
--// By: adamABJ
--// Executor: Delta
--// UI Library: WindUI

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local RunService = cloneref(game:GetService("RunService"))
local TeleportService = cloneref(game:GetService("TeleportService"))
local Players = cloneref(game:GetService("Players"))
local HttpService = cloneref(game:GetService("HttpService"))
local TweenService = cloneref(game:GetService("TweenService"))

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HRP = Character:WaitForChild("HumanoidRootPart")

--// WindUI Load
local WindUI
local ok, result = pcall(function()
	return require("./src/Init")
end)

if ok then
	WindUI = result
else
	if RunService:IsStudio() or not writefile then
		WindUI = require(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init"))
	else
		WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
	end
end

--// FARM Core System
local FARM = {
	Version = "3.0.0",
	Config = {},
	State = {
		Active = false,
		CurrentJob = nil,
		CurrentTool = nil,
		StartTime = nil,
		TotalEarned = 0,
		IncomeRate = 0,
		LastAction = tick()
	},
	Hooks = {},
	Jobs = {},
	Utils = {}
}

--// Default Config
FARM.Config = {
	-- Farm Settings
	AutoFarm = false,
	PreferredJob = "shelf_stocker", -- steakhouse_cook, janitor, shelf_stocker, atm_hacker
	SmartJobSwitch = true,
	AutoDeposit = true,
	
	-- Anti-Detection
	Humanize = true,
	MinDelay = 0.05,
	MaxDelay = 0.15,
	JitterAmount = 0.02,
	
	-- Safety
	AntiRagdoll = true,
	AntiDamage = true,
	AutoRespawn = true,
	HideName = true,
	
	-- Server
	AutoRejoin = true,
	TargetJobId = "",
	
	-- Stats
	TrackIncome = true,
	WebhookURL = ""
}

--// Load Config from file if exists
if readfile and isfile and isfile("FARM_Config.json") then
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile("FARM_Config.json"))
	end)
	if ok then
		for k, v in pairs(data) do
			FARM.Config[k] = v
		end
	end
end

--// Save Config function
function FARM:SaveConfig()
	if writefile then
		writefile("FARM_Config.json", HttpService:JSONEncode(FARM.Config))
		return true
	end
	return false
end

--// Reset Config
function FARM:ResetConfig()
	FARM.Config = {
		AutoFarm = false,
		PreferredJob = "shelf_stocker",
		SmartJobSwitch = true,
		AutoDeposit = true,
		Humanize = true,
		MinDelay = 0.05,
		MaxDelay = 0.15,
		JitterAmount = 0.02,
		AntiRagdoll = true,
		AntiDamage = true,
		AutoRespawn = true,
		HideName = true,
		AutoRejoin = true,
		TargetJobId = "",
		TrackIncome = true,
		WebhookURL = ""
	}
	FARM:SaveConfig()
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

--// Secure Networking with Metamethod Hooking
function FARM:InitSecureNetworking()
	local mt = getrawmetatable(Net)
	if mt then
		setreadonly(mt, false)
		local oldNamecall = mt.__namecall
		
		mt.__namecall = newcclosure(function(self, ...)
			local method = getnamecallmethod()
			if method == "send" and self == Net and FARM.Config.Humanize then
				FARM:HumanDelay()
			end
			return oldNamecall(self, ...)
		end)
		
		setreadonly(mt, true)
	end
end

function FARM:HumanDelay()
	local delay = math.random() * (FARM.Config.MaxDelay - FARM.Config.MinDelay) + FARM.Config.MinDelay
	if FARM.Config.JitterAmount then
		delay = delay + (math.random() - 0.5) * FARM.Config.JitterAmount
	end
	task.wait(math.max(0, delay))
end

--// Anti-Ragdoll & Safety
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
			mt.__newindex = newcclosure(function(t, k, v)
				if k == "Health" and v <= 0 then
					return
				end
				return oldNewIndex(t, k, v)
			end)
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

--// Job System
FARM.Jobs.Cook = {
	Name = "steakhouse_cook",
	State = "IDLE",
	CurrentGrill = nil,
	
	Start = function(self)
		if LocalPlayer:GetAttribute("Job") ~= self.Name then
			FARM:ApplyForJob(self.Name)
		end
		
		while FARM.State.Active and FARM.State.CurrentJob == self.Name do
			self:Tick()
			task.wait(0.1)
		end
	end,
	
	Tick = function(self)
		if self.State == "IDLE" then
			local grill = FARM:FindFreeGrill()
			if grill then
				self.CurrentGrill = grill
				self.State = "WALKING"
				FARM:WalkTo(grill.Position)
			end
		elseif self.State == "WALKING" then
			if FARM:IsAtPosition(self.CurrentGrill.Position, 5) then
				self.State = "COOKING"
			end
		elseif self.State == "COOKING" then
			Net.send("start_grilling_2", self.CurrentGrill)
			task.wait(math.random(8, 12))
			Net.send("finish_grilling_2", self.CurrentGrill, "Cooked")
			self.State = "IDLE"
		end
	end
}

FARM.Jobs.Stocker = {
	Name = "shelf_stocker",
	State = "IDLE",
	HasBox = false,
	CurrentShelf = nil,
	
	Start = function(self)
		if LocalPlayer:GetAttribute("Job") ~= self.Name then
			FARM:ApplyForJob(self.Name)
		end
		
		while FARM.State.Active and FARM.State.CurrentJob == self.Name do
			self:Tick()
			task.wait(0.1)
		end
	end,
	
	Tick = function(self)
		if self.State == "IDLE" then
			if not self.HasBox then
				local box = FARM:FindAvailableBox()
				if box then
					FARM:WalkTo(box.Position)
					FARM:FirePrompt(box:FindFirstChild("ProximityPrompt"))
					self.HasBox = true
				end
			else
				local shelf = FARM:FindEmptyShelf()
				if shelf then
					self.CurrentShelf = shelf
					self.State = "WALKING_TO_SHELF"
					FARM:WalkTo(shelf.Position)
				end
			end
		elseif self.State == "WALKING_TO_SHELF" then
			if FARM:IsAtPosition(self.CurrentShelf.Position, 3) then
				self.State = "STOCKING"
			end
		elseif self.State == "STOCKING" then
			local success = Net.get("player_started_stocking_shelf", self.CurrentShelf)
			if success then
				task.wait(10 / FARM:GetSkillMultiplier("speed"))
				Net.get("player_stocked_shelf", self.CurrentShelf)
				self.HasBox = false
				self.State = "IDLE"
			end
		end
	end
}

FARM.Jobs.Janitor = {
	Name = "janitor",
	State = "IDLE",
	CurrentPuddle = nil,
	
	Start = function(self)
		if LocalPlayer:GetAttribute("Job") ~= self.Name then
			FARM:ApplyForJob(self.Name)
		end
		FARM:EquipTool("Mop")
		
		while FARM.State.Active and FARM.State.CurrentJob == self.Name do
			self:Tick()
			task.wait(0.1)
		end
	end,
	
	Tick = function(self)
		if self.State == "IDLE" then
			local puddle = FARM:FindNearestPuddle()
			if puddle then
				self.CurrentPuddle = puddle
				self.State = "WALKING"
				FARM:WalkTo(puddle.Position)
			end
		elseif self.State == "WALKING" then
			if FARM:IsAtPosition(self.CurrentPuddle.Position, 5) then
				self.State = "CLEANING"
			end
		elseif self.State == "CLEANING" then
			Net.send("start_cleaning_puddle", self.CurrentPuddle)
			local mopLength = FARM:GetMopLength(self.CurrentPuddle)
			task.wait(mopLength)
			if FARM:IsAtPosition(self.CurrentPuddle.Position, 5) then
				-- Auto-completes server-side
			else
				Net.send("player_moved_from_puddle", self.CurrentPuddle)
			end
			self.State = "IDLE"
		end
	end
}

--// Utility Functions
function FARM:ApplyForJob(jobName)
	local locations = {
		["steakhouse_cook"] = workspace.Map.Tiles.ShoppingTile.SteakHouse.Interior.SteakHouseBeacon.TouchPart,
		["shelf_stocker"] = workspace.Map.Tiles.GasStationTile.Quick11.Interior.Quick11Beacon.TouchPart,
		["janitor"] = workspace.BurgePlaceBeacon.TouchPart,
		["atm_hacker"] = workspace.Map.Props.ATMs.ATM
	}
	
	local beacon = locations[jobName]
	if beacon then
		self:WalkTo(beacon.Position)
		task.wait(0.5)
		Net.send("apply_for_job", beacon)
		task.wait(1)
	end
end

function FARM:WalkTo(position)
	local distance = (HRP.Position - position).Magnitude
	local duration = distance / 16
	TweenService:Create(HRP, TweenInfo.new(duration), {CFrame = CFrame.new(position)}):Play()
	task.wait(duration)
end

function FARM:IsAtPosition(position, tolerance)
	return (HRP.Position - position).Magnitude <= (tolerance or 3)
end

function FARM:FirePrompt(prompt)
	if prompt and prompt:IsA("ProximityPrompt") then
		fireproximityprompt(prompt)
	end
end

function FARM:FindFreeGrill()
	for _, grill in pairs(workspace:GetDescendants()) do
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
	for _, obj in pairs(workspace:GetDescendants()) do
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
	for _, shelf in pairs(workspace:GetDescendants()) do
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
	for _, obj in pairs(workspace:GetDescendants()) do
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
		if tool then
			Humanoid:EquipTool(tool)
		end
	end
end

function FARM:GetBestJob()
	local rates = {
		["shelf_stocker"] = 150,
		["steakhouse_cook"] = 120,
		["janitor"] = 100,
		["atm_hacker"] = 80
	}
	return FARM.Config.PreferredJob
end

--// Income Tracker
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

--// Server Functions
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

--// Initialize
FARM:InitSecureNetworking()
FARM:InitSafety()
FARM:InitIncomeTracker()

--// WindUI Window
local Window = WindUI:CreateWindow({
	Title = "FARM",
	Author = "By: adamABJ",
	Icon = "solar:bolt-bold",
	Theme = "Dark",
	NewElements = true,
	Transparent = true,
	ToggleKey = FARM.Config.ToggleKey or Enum.KeyCode.RightShift,
	Acrylic = true
})

--// Tabs
local TabFarm = Window:Tab({ Title = "Farming", Icon = "solar:case-round-bold" })
local TabGeneral = Window:Tab({ Title = "General", Icon = "solar:user-bold" })
local TabServer = Window:Tab({ Title = "Server", Icon = "solar:server-bold" })
local TabConfig = Window:Tab({ Title = "Config", Icon = "solar:settings-bold" })

TabFarm:Select()

--// FARMING TAB
TabFarm:Section({ Title = "Auto Farm", Desc = "Configure farming settings" })

TabFarm:Toggle({
	Title = "Enable Auto Farm",
	Value = FARM.Config.AutoFarm,
	Callback = function(v)
		FARM.Config.AutoFarm = v
		FARM.State.Active = v
		if v then
			local job = FARM.Config.SmartJobSwitch and FARM:GetBestJob() or FARM.Config.PreferredJob
			FARM.State.CurrentJob = job
			if FARM.Jobs[job:gsub("steakhouse_", ""):gsub("shelf_", ""):gsub("atm_", "")] then
				task.spawn(function()
					FARM.Jobs[job:gsub("steakhouse_", ""):gsub("shelf_", ""):gsub("atm_", "")]:Start()
				end)
			end
		else
			FARM.State.CurrentJob = nil
		end
	end
})

TabFarm:Dropdown({
	Title = "Select Job",
	Value = FARM.Config.PreferredJob,
	Values = { "steakhouse_cook", "shelf_stocker", "janitor", "atm_hacker" },
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
	Value = { Min = 0, Max = 1, Default = FARM.Config.MinDelay },
	Step = 0.01,
	Callback = function(v)
		FARM.Config.MinDelay = v
		FARM:SaveConfig()
	end
})

TabFarm:Slider({
	Title = "Max Delay",
	Value = { Min = 0, Max = 1, Default = FARM.Config.MaxDelay },
	Step = 0.01,
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
		FARM:SaveConfig()
	end
})

TabGeneral:Toggle({
	Title = "Anti Damage",
	Value = FARM.Config.AntiDamage,
	Callback = function(v)
		FARM.Config.AntiDamage = v
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

TabGeneral:Section({ Title = "Stats", Desc = "Farming statistics" })

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
local InfoText = TabServer:Label({ 
	Title = string.format("PlaceId: %d\nPlayers: %d/%d\nPing: %d ms\nJobId: %s...", 
		ServerInfo.PlaceId, ServerInfo.Players, ServerInfo.MaxPlayers, ServerInfo.Ping, 
		string.sub(ServerInfo.JobId, 1, 20)) 
})

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
			WindUI:Notify({ Title = "Success", Content = "JobId copied!" })
		else
			WindUI:Notify({ Title = "Error", Content = "Clipboard not available" })
		end
	end
})

TabServer:Button({
	Title = "Teleport",
	Desc = "Teleport to target JobId",
	Callback = function()
		if FARM.Config.TargetJobId ~= "" then
			FARM:TeleportToJobId(FARM.Config.TargetJobId)
		else
			WindUI:Notify({ Title = "Error", Content = "Enter a JobId first" })
		end
	end
})

TabServer:Button({
	Title = "Rejoin",
	Desc = "Rejoin same server",
	Callback = function()
		FARM:RejoinSameServer()
	end
})

--// CONFIG TAB
TabConfig:Section({ Title = "Configuration", Desc = "Save and manage settings" })

TabConfig:Button({
	Title = "Save Config",
	Desc = "Save current configuration",
	Callback = function()
		if FARM:SaveConfig() then
			WindUI:Notify({ Title = "Success", Content = "Configuration saved!" })
		else
			WindUI:Notify({ Title = "Error", Content = "Could not save config" })
		end
	end
})

TabConfig:Button({
	Title = "Reset Config",
	Desc = "Reset all settings to default",
	Callback = function()
		FARM:ResetConfig()
		WindUI:Notify({ Title = "Success", Content = "Configuration reset!" })
	end
})

TabConfig:Button({
	Title = "Wipe Workspace",
	Desc = "Delete all files in workspace folder",
	Callback = function()
		if delfolder and isfolder and isfolder("FARM") then
			delfolder("FARM")
		end
		if delfile then
			for _, file in pairs({"FARM_Config.json"}) do
				if isfile and isfile(file) then
					delfile(file)
				end
			end
		end
		WindUI:Notify({ Title = "Success", Content = "Workspace wiped!" })
	end
})

--// Welcome Notification
WindUI:Notify({
	Title = "FARM Loaded",
	Content = "v" .. FARM.Version .. " by adamABJ | Ready to dominate",
	Duration = 5
})

getgenv().FARM = FARM
