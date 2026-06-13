-- WindUI Integration & Farm Script
-- Author: GLM 4.7 Flash Heretic

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- WindUI Loader
local WindUI
if RunService:IsStudio() then
	WindUI = require(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init"))
else
	local success, result = pcall(function()
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
	end)
	WindUI = success and result or nil
end

if not WindUI then
	warn("Failed to load WindUI")
	return
end

-- Job Data & Utils
local JobData = require(ReplicatedStorage.Modules.Game.Jobs.JobData)
local JobUtil = require(ReplicatedStorage.Modules.Game.Jobs.JobUtil)
local JobApp = require(ReplicatedStorage.Modules.Game.Jobs.JobApplication)

-- UI Initialization
local Main = WindUI:CreateWindow("Farming & Tools", 800, 450)

-- Tab: FARM
local FarmTab = Main:AddTab("FARM", "🚜")

-- --- SWIPER SECTION ---
local SwiperGroup = FarmTab:AddGroup("Swiper:")

local SwiperAfk = SwiperGroup:AddToggle("Afk Checker", false, "If your character stays idle for more than 5 minutes, it will automatically rejoin.")
local SwiperVehicle = SwiperGroup:AddDropdown("Vehicle Type", {"Bike", "Car", "Truck"})
local SwiperTool = SwiperGroup:AddDropdown("HackTools", {"Smart Select", "HackToolBasic", "HackToolPro", "HackToolUltimate", "HackToolQuantum"})
local SwiperQty = SwiperGroup:AddSlider("HackTools Quantity", 5, 1, 100)

-- --- FISHING SECTION ---
local FishingGroup = FarmTab:AddGroup("Fishing:")

local FishingAfk = FishingGroup:AddToggle("Afk Checker", false, "If your character stays idle for more than 5 minutes, it will automatically rejoin.")
local FishingVehicle = FishingGroup:AddDropdown("Vehicle Type", {"Bike", "Car"})
local FishingRod = FishingGroup:AddDropdown("Rod", {"Smart Select", "FishingRodRegular", "FishingRodPro", "FishingRodAdvanced", "FishingRodUltimate"})
local FishingBait = FishingGroup:AddDropdown("Bait", {"Smart Select", "WormtecRegular", "WormtecPro", "WormtecUltimate", "PrawntecRegular", "PrawntecPro"})
local FishingBaitQty = FishingGroup:AddSlider("Bait Quantity", 10, 1, 50)
local FishingAmount = FishingGroup:AddSlider("Fish Amount", 10, 1, 100)

-- Tab: GENERAL
local GeneralTab = Main:AddTab("General", "👤")

local GeneralHideName = GeneralTab:AddToggle("Hide Name", false, "Just hide only client side.")
local GeneralAntiKill = GeneralTab:AddToggle("Anti Kill", false, "Prevent kill when you has been downed.")
local GeneralAntiRagdoll = GeneralTab:AddToggle("Anti Ragdoll", false, "Anti stunned when you got hit or bumped by car.")
local GeneralAutoRespawn = GeneralTab:AddToggle("Auto Respawn", false, "Automatic respawn when you death.")

-- Tab: SERVER
local ServerTab = Main:AddTab("Server", "🖥️")

local ServerInfoBox = ServerTab:AddBox("Server Information:")
ServerInfoBox:AddLabel("PlaceId", tostring(game.PlaceId))
ServerInfoBox:AddLabel("Players", tostring(Players:GetPlayers() | #Players:GetPlayers()))
ServerInfoBox:AddLabel("Ping", tostring(game:GetService("NetworkService"):GetServerPing()))

local JobIdInput = ServerTab:AddInput("JobId", "Enter JobId here...")
local CopyJobIdBtn = ServerTab:AddButton("Copy JobId", "Click to copy this server's JobId")
local TeleportBtn = ServerTab:AddButton("Teleport", "Teleport to target jobid.")
local RejoinBtn = ServerTab:AddButton("Rejoin", "Rejoin in same server.")

-- Tab: CONFIG
local ConfigTab = Main:AddTab("Config", "⚙️")

local SaveConfigBtn = ConfigTab:AddButton("Save Config", "Save current config.")
local ResetConfigBtn = ConfigTab:AddButton("Reset Config", "Wipe all config.")
local WipeWorkspaceBtn = ConfigTab:AddButton("Wipe Workspace", "Delete all file in workspace.")

-- --- LOGIC & REMOTES ---

-- Remote Hook
local NetModule = require(ReplicatedStorage.Modules.Core.Net)

-- Swiper Logic
SwiperVehicle.OnSelected:Connect(function(selected)
	-- Logic to select vehicle
	warn("Vehicle selected:", selected)
end)

SwiperTool.OnSelected:Connect(function(selected)
	warn("HackTool selected:", selected)
end)

-- Fishing Logic
FishingRod.OnSelected:Connect(function(selected)
	warn("Rod selected:", selected)
end)

FishingBait.OnSelected:Connect(function(selected)
	warn("Bait selected:", selected)
end)

-- General Logic
GeneralAntiKill.OnToggled:Connect(function(isOn)
	-- Logic for Anti Kill
	if isOn then
		warn("Anti Kill Enabled")
	else
		warn("Anti Kill Disabled")
	end
end)

GeneralAntiRagdoll.OnToggled:Connect(function(isOn)
	-- Logic for Anti Ragdoll
	if isOn then
		warn("Anti Ragdoll Enabled")
	else
		warn("Anti Ragdoll Disabled")
	end
end)

-- Server Logic
CopyJobIdBtn.OnClick:Connect(function()
	local jobId = game:GetService("TeleportService"):GetJobId()
	clipboard.set(jobId)
	warn("JobId Copied!")
end)

TeleportBtn.OnClick:Connect(function()
	local targetJobId = JobIdInput.Text
	if targetJobId and targetJobId ~= "" then
		-- Teleport logic using TeleportService
		local success, err = pcall(function()
			game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, targetJobId, LocalPlayer)
		end)
		if not success then
			warn("Teleport failed:", err)
		end
	else
		warn("Please enter a valid JobId")
	end
end)
