 local RunService = game:GetService("RunService")
local cloneref = (cloneref or clonereference or function(instance) return instance end)
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local HttpService = cloneref(game:GetService("HttpService"))

local WindUI

-- [1] CARGADOR DE LA LIBRERÍA (WINDUI)
do
	local ok, result = pcall(function()
		return require("./src/Init")
	end)

	if ok then
		WindUI = result
	else
		if cloneref(game:GetService("RunService")):IsStudio() then
			WindUI = require(cloneref(ReplicatedStorage:WaitForChild("WindUI"):WaitForChild("Init")))
		else
			WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
		end
	end
end

-- [2] CONFIGURACIÓN DE LA VENTANA PRINCIPAL (WATER HUB)
local Window = WindUI:CreateWindow({
	Title = "Water Hub | Blox Spin",
	Author = "By: AdamABJ", -- Tu firma oficial en la esquina superior
	Folder = "WaterHub_AdamABJ", -- Carpeta donde se guardarán tus archivos JSON de config
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
		Color = ColorSequence.new(
			Color3.fromHex("#00F2FE"),
			Color3.fromHex("#4FACFE")
		),
	},
	Topbar = {
		Height = 44,
		ButtonsType = "Mac", -- Estilo premium Apple (Botones de colores)
	},
})

-- Etiqueta de versión pequeña estilo Github
Window:Tag({
	Title = "v" .. WindUI.Version,
	Icon = "github",
	Color = Color3.fromHex("#1c1c1c"),
	Border = true,
})

-- [3] CREACIÓN DE LAS PESTAÑAS PRINCIPALES (TABS)
local GeneralTab = Window:Tab({ Title = "General", Icon = "solar:user-bold-duotone", Border = true })
local CombatTab = Window:Tab({ Title = "Combat", Icon = "solar:swords-bold-duotone", Border = true })
local WeaponModTab = Window:Tab({ Title = "Weapon Mod", Icon = "solar:tuning-bold-duotone", Border = true })
local CosmeticTab = Window:Tab({ Title = "Cosmetic", Icon = "solar:shirt-bold-duotone", Border = true })
local EspTab = Window:Tab({ Title = "Esp", Icon = "solar:eye-bold-duotone", Border = true })
local VehicleTab = Window:Tab({ Title = "Vehicle", Icon = "solar:bus-bold-duotone", Border = true })
local ShopTab = Window:Tab({ Title = "Shop", Icon = "solar:cart-large-4-bold-duotone", Border = true })
local MiscTab = Window:Tab({ Title = "Misc", Icon = "solar:slider-minimalistic-horizontal-bold-duotone", Border = true })
local ServerTab = Window:Tab({ Title = "Server", Icon = "solar:server-square-bold-duotone", Border = true })
local ConfigTab = Window:Tab({ Title = "Config", Icon = "solar:folder-with-files-bold-duotone", Border = true })

-- ====================================================================
-- PESTAÑA: GENERAL
-- ====================================================================
do
	local GeneralSection = GeneralTab:Section({ Title = "Player Options", Box = true, BoxBorder = true, Opened = true })
	local GeneralGroup = GeneralTab:Group()

	GeneralGroup:Toggle({
		Flag = "Invisible", Title = "Invisible", Value = false,
		Callback = function(v) print("Invisible:", v) end
	})
	GeneralGroup:Space()
	GeneralGroup:Toggle({
		Flag = "EnableJump", Title = "Enable Jump", Value = false,
		Callback = function(v) print("Enable Jump:", v) end
	})
	GeneralGroup:Space()
	GeneralGroup:Dropdown({
		Flag = "JumpMode", Title = "Jump Mode", Values = { "Fly Jump", "Normal Jump", "Infinite Jump" }, Value = "Fly Jump",
		Callback = function(v) print("Jump Mode:", v) end
	})
	GeneralGroup:Space()
	GeneralGroup:Toggle({
		Flag = "InfinityStamina", Title = "Infinity Stamina", Value = false,
		Callback = function(v) print("Infinity Stamina:", v) end
	})
	GeneralGroup:Space()
	GeneralGroup:Toggle({
		Flag = "SpeedHack", Title = "Speed Hack", Value = false,
		Callback = function(v) print("Speed Hack:", v) end
	})
	GeneralGroup:Space()
	GeneralGroup:Toggle({
		Flag = "HideName", Title = "Hide Name", Value = false,
		Callback = function(v) print("Hide Name:", v) end
	})
	GeneralGroup:Space()
	GeneralGroup:Toggle({
		Flag = "PickupItems", Title = "Pickup Items", Value = false,
		Callback = function(v) print("Pickup Items:", v) end
	})
end

-- ====================================================================
-- PESTAÑA: COMBAT
-- ====================================================================
do
	-- Sección Combat:
	local CombatSec = CombatTab:Section({ Title = "Combat:", Box = true, BoxBorder = true, Opened = true })
	local CombatGroup = CombatTab:Group()

	CombatGroup:Toggle({
		Flag = "SilentAim", Title = "Silent Aim", Value = false,
		Callback = function(v) print("Silent Aim:", v) end
	})
	CombatGroup:Space()
	CombatGroup:Toggle({
		Flag = "ShowFOV", Title = "Show FOV", Value = false,
		Callback = function(v) print("Show FOV:", v) end
	})
	CombatGroup:Space()
	CombatGroup:Slider({
		Flag = "FOV", Title = "FOV:", IsTooltip = true, Step = 1, Value = { Min = 0, Max = 500, Default = 200 },
		Callback = function(v) print("FOV:", v) end
	})
	CombatGroup:Space()
	CombatGroup:Slider({
		Flag = "ShootingDistance", Title = "Shooting Distance", IsTooltip = true, Step = 1, Value = { Min = 0, Max = 3000, Default = 1500 },
		Callback = function(v) print("Shooting Distance:", v) end
	})
	CombatGroup:Space()
	CombatGroup:Dropdown({
		Flag = "AimPart", Title = "Aim Part", Values = { "Head", "HumanoidRootPart", "Torso" }, Value = "Head",
		Callback = function(v) print("Aim Part:", v) end
	})
	CombatGroup:Space()
	CombatGroup:Dropdown({
		Flag = "IgnorePlayer", Title = "Ignore player", Values = { "--", "Friends", "Team" }, Value = "--",
		Callback = function(v) print("Ignore player:", v) end
	})

	CombatTab:Space({ Columns = 2 })

	-- Sección Auto
	local AutoSec = CombatTab:Section({ Title = "Auto", Box = true, BoxBorder = true, Opened = true })
	local AutoGroup = CombatTab:Group()

	AutoGroup:Toggle({
		Flag = "AutoHeal", Title = "Auto Heal", Value = false,
		Callback = function(v) print("Auto Heal:", v) end
	})
	AutoGroup:Space()
	AutoGroup:Slider({
		Flag = "HealHP", Title = "Heal HP %", IsTooltip = true, Step = 1, Value = { Min = 0, Max = 100, Default = 70 },
		Callback = function(v) print("Heal HP %:", v) end
	})
	AutoGroup:Space()
	AutoGroup:Toggle({
		Flag = "AutoHit", Title = "Auto Hit", Value = false,
		Callback = function(v) print("Auto Hit:", v) end
	})

	CombatTab:Space({ Columns = 2 })

	-- Sección Anti
	local AntiSec = CombatTab:Section({ Title = "Anti", Box = true, BoxBorder = true, Opened = true })
	local AntiGroup = CombatTab:Group()

	AntiGroup:Toggle({
		Flag = "AntiAim", Title = "Anti Aim", Desc = "only works when you run", Value = false,
		Callback = function(v) print("Anti Aim:", v) end
	})
	AntiGroup:Space()
	AntiGroup:Toggle({
		Flag = "AntiKill", Title = "Anti-Kill", Value = false,
		Callback = function(v) print("Anti-Kill:", v) end
	})
	AntiGroup:Space()
	AntiGroup:Toggle({
		Flag = "AntiRagdoll", Title = "Anti Ragdoll", Value = false,
		Callback = function(v) print("Anti Ragdoll:", v) end
	})
end

-- ====================================================================
-- PESTAÑA: WEAPON MOD
-- ====================================================================
do
	local GunSec = WeaponModTab:Section({ Title = "Gun:", Box = true, BoxBorder = true, Opened = true })
	local GunGroup = WeaponModTab:Group()

	GunGroup:Toggle({
		Flag = "Automatic", Title = "Automatic", Value = false,
		Callback = function(v) print("Automatic:", v) end
	})
	GunGroup:Space()
	GunGroup:Slider({
		Flag = "FireRate", Title = "Fire Rate", IsTooltip = true, Step = 1, Value = { Min = 0, Max = 2000, Default = 1000 },
		Callback = function(v) print("Fire Rate:", v) end
	})
	GunGroup:Space()
	GunGroup:Toggle({
		Flag = "NoRecoil", Title = "No Recoil", Value = false,
		Callback = function(v) print("No Recoil:", v) end
	})
end

-- ====================================================================
-- PESTAÑA: COSMETIC
-- ====================================================================
do
	local CosmeticSec = CosmeticTab:Section({ Title = "Skins & Visuals", Box = true, BoxBorder = true, Opened = true })
	CosmeticSec:Paragraph({
		Title = "Próximamente",
		Desc = "Modifica los aspectos visuales aquí.",
		Image = "solar:info-circle-bold-duotone"
	})
end

-- ====================================================================
-- PESTAÑA: ESP
-- ====================================================================
do
	-- Sección Principal ESP
	local EspSec1 = EspTab:Section({ Title = "Visuals:", Box = true, BoxBorder = true, Opened = true })
	local EspGroup1 = EspTab:Group()

	EspGroup1:Toggle({
		Flag = "NameESP", Title = "Name ESP", Value = false,
		Callback = function(v) print("Name ESP:", v) end
	})
	EspGroup1:Space()
	EspGroup1:Toggle({
		Flag = "HealthESP", Title = "Health ESP", Value = false,
		Callback = function(v) print("Health ESP:", v) end
	})
	EspGroup1:Space()
	EspGroup1:Toggle({
		Flag = "HackerESP", Title = "Hacker ESP [Anti Aim]", Value = false,
		Callback = function(v) print("Hacker ESP:", v) end
	})

	EspTab:Space({ Columns = 2 })

	-- Sección Item
	local ItemSec = EspTab:Section({ Title = "Item", Box = true, BoxBorder = true, Opened = true })
	local EspGroup2 = EspTab:Group()

	EspGroup2:Toggle({
		Flag = "WeaponEsp", Title = "Weapon Esp", Value = false,
		Callback = function(v) print("Weapon Esp:", v) end
	})
	EspGroup2:Space()
	EspGroup2:Toggle({
		Flag = "ItemESP", Title = "Item ESP", Value = false,
		Callback = function(v) print("Item ESP:", v) end
	})
	EspGroup2:Space()
	EspGroup2:Dropdown({
		Flag = "SelectRarity", Title = "Select Rarity", Values = { "Uncommon", "Common", "Rare", "Epic", "Legendary" }, Value = "Uncommon",
		Callback = function(v) print("Selected Rarity:", v) end
	})
end

-- ====================================================================
-- PESTAÑA: VEHICLE
-- ====================================================================
do
	local VehicleSec = VehicleTab:Section({ Title = "Vehicle Mods", Box = true, BoxBorder = true, Opened = true })
	VehicleSec:Paragraph({
		Title = "Opciones de Vehículos",
		Desc = "Configuraciones destinadas al control y velocidad de transportes.",
		Image = "solar:info-circle-bold-duotone"
	})
end

-- ====================================================================
-- PESTAÑA: SHOP
-- ====================================================================
do
	-- Sección ATM (Visualizadores de dinero con iconos dedicados)
	local AtmSec = ShopTab:Section({ Title = "ATM", Box = true, BoxBorder = true, Opened = true })
	
	AtmSec:Button({
		Title = "Cash: $79",
		Icon = "solar:wallet-money-bold-duotone",
		Callback = function() end -- Actúa puramente como indicador visual estético
	})
	
	ShopTab:Space()
	
	AtmSec:Button({
		Title = "Bank: $44,055",
		Icon = "solar:bank-bold-duotone",
		Color = Color3.fromHex("#83889E"),
		Callback = function() end
	})

	ShopTab:Space({ Columns = 2 })

	-- Sección Remote Purchase
	local RemoteSec = ShopTab:Section({ Title = "Remote Purchase", Box = true, BoxBorder = true, Opened = true })
	local ShopGroup = ShopTab:Group()

	ShopGroup:Dropdown({
		Flag = "AmmoType", Title = "Ammo", Values = { "Pistol", "Rifle", "Shotgun", "SMG" }, Value = "Pistol",
		Callback = function(v) print("Selected Ammo Type:", v) end
	})
	ShopGroup:Space()
	ShopGroup:Button({
		Title = "Buy Ammo", Icon = "solar:cursor-bold", Justify = "Left",
		Callback = function() print("Comprando munición...") end
	})
	ShopGroup:Space()
	ShopGroup:Dropdown({
		Flag = "WeaponType", Title = "Weapon", Values = { "Basic", "Advanced", "Special" }, Value = "Basic",
		Callback = function(v) print("Selected Weapon Type:", v) end
	})
	ShopGroup:Space()
	ShopGroup:Button({
		Title = "Buy Weapon", Icon = "solar:cursor-bold", Justify = "Left",
		Callback = function() print("Comprando arma...") end
	})
end

-- ====================================================================
-- PESTAÑA: MISC
-- ====================================================================
do
	local MiscSec = MiscTab:Section({ Title = "Misc", Box = true, BoxBorder = true, Opened = true })
	local MiscGroup = MiscTab:Group()

	MiscGroup:Toggle({
		Flag = "Freecam", Title = "Freecam", Value = false,
		Callback = function(v) print("Freecam:", v) end
	})
	MiscGroup:Space()
	MiscGroup:Toggle({
		Flag = "Snap", Title = "snap", Value = false,
		Callback = function(v) print("Snap:", v) end
	})
	MiscGroup:Space()
	MiscGroup:Slider({
		Flag = "Depth", Title = "Depth", IsTooltip = true, Step = 1, Value = { Min = 0, Max = 50, Default = 8 },
		Callback = function(v) print("Depth:", v) end
	})
end

-- ====================================================================
-- PESTAÑA: SERVER
-- ====================================================================
do
	local ServerSec = ServerTab:Section({ Title = "Join Server", Box = true, BoxBorder = true, Opened = true })
	local ServerGroup = ServerTab:Group()

	ServerGroup:Input({
		Flag = "ServerID", Title = "Server ID", Placeholder = "Paste Job ID here...", Type = "Input", Icon = "solar:pen-bold-duotone",
		Callback = function(v) print("Server ID ingresado:", v) end
	})
	ServerGroup:Space()
	ServerGroup:Button({
		Title = "Join Server", Icon = "solar:cursor-bold", Justify = "Left",
		Callback = function() print("Uniéndose al Server ID...") end
	})
	ServerGroup:Space()
	ServerGroup:Button({
		Title = "Rejoin", Icon = "solar:cursor-bold", Justify = "Left",
		Callback = function() 
			game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
		end
	})
	ServerGroup:Space()
	ServerGroup:Button({
		Title = "Server Hop", Icon = "solar:cursor-bold", Justify = "Left",
		Callback = function() print("Buscando un nuevo servidor público...") end
	})
	ServerGroup:Space()
	ServerGroup:Button({
		Title = "Random server", Icon = "solar:cursor-bold", Justify = "Left",
		Callback = function() print("Cambiando a servidor aleatorio...") end
	})
end

-- ====================================================================
-- PESTAÑA: CONFIG (GESTOR DE ARCHIVOS + AJUSTES ORIGINALES)
-- ====================================================================
do
	-- Sección Settings:
	local SettingsSec = ConfigTab:Section({ Title = "Settings:", Box = true, BoxBorder = true, Opened = true })
	local SettingsGroup = ConfigTab:Group()

	SettingsGroup:Toggle({
		Flag = "ShowPing", Title = "Show Ping", Value = false,
		Callback = function(v) print("Show Ping:", v) end
	})
	SettingsGroup:Space()
	SettingsGroup:Button({
		Title = "Bring Car", Icon = "solar:cursor-bold", Justify = "Left",
		Callback = function() print("Trayendo vehículo...") end
	})
	SettingsGroup:Space()
	SettingsGroup:Button({
		Title = "Boost FPS", Icon = "solar:cursor-bold", Justify = "Left",
		Callback = function() print("Maximizando rendimiento FPS...") end
	})
	SettingsGroup:Space()
	SettingsGroup:Button({
		Title = "Claim All Quests", Icon = "solar:cursor-bold", Justify = "Left",
		Callback = function() print("Reclamando todas las misiones...") end
	})

	ConfigTab:Space({ Columns = 2 })

	-- LÓGICA DE GUARDADO/CARGA DEL SCRIPT ORIGINAL (Solo ejecutores reales)
	if not RunService:IsStudio() and writefile and printidentity() then
		local ConfigManager = Window.ConfigManager
		local ConfigName = "default"

		local SaveSec = ConfigTab:Section({ Title = "Save / Load Hub Config", Box = true, BoxBorder = true, Opened = true })

		local ConfigNameInput = SaveSec:Input({
			Title = "File Name", Icon = "file-cog",
			Callback = function(value) ConfigName = value end
		})

		SaveSec:Space()

		local AllConfigs = ConfigManager:AllConfigs()
		local DefaultValue = table.find(AllConfigs, ConfigName) and ConfigName or nil

		local AllConfigsDropdown = SaveSec:Dropdown({
			Title = "Saved Files", Desc = "Select an existing config", Values = AllConfigs, Value = DefaultValue,
			Callback = function(value)
				ConfigName = value
				ConfigNameInput:Set(value)
			end
		})

		SaveSec:Space()

		SaveSec:Button({
			Title = "Save Config", Color = Color3.fromHex("#30FF6A"), Justify = "Center",
			Callback = function()
				Window.CurrentConfig = ConfigManager:Config(ConfigName)
				if Window.CurrentConfig:Save() then
					WindUI:Notify({ Title = "Water Hub", Content = "Config '" .. ConfigName .. "' guardada.", Icon = "check" })
				end
				AllConfigsDropdown:Refresh(ConfigManager:AllConfigs())
			end
		})

		SaveSec:Space()

		SaveSec:Button({
			Title = "Load Config", Color = Color3.fromHex("#4FACFE"), Justify = "Center",
			Callback = function()
				Window.CurrentConfig = ConfigManager:CreateConfig(ConfigName)
				if Window.CurrentConfig:Load() then
					WindUI:Notify({ Title = "Water Hub", Content = "Config '" .. ConfigName .. "' cargada.", Icon = "refresh-cw" })
				end
			end
		})
	end
end
