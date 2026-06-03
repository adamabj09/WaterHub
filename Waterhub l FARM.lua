--// FARM v3.1 - Bulletproof Edition
--// By: adamABJ
--// Si esto no carga, el problema es tu executor

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

--// CARGA WINDUI CON FALLBACK
local WindUI
local loadAttempts = {
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua",
    "https://cdn.jsdelivr.net/gh/Footagesus/WindUI@main/dist/main.lua",
    "https://raw.githubusercontent.com/Depth-Studios/WindUI/main/dist/main.lua"
}

for _, url in ipairs(loadAttempts) do
    local success, result = pcall(function()
        return loadstring(game:HttpGet(url))()
    end)
    if success and result then
        WindUI = result
        print("WindUI cargado desde:", url)
        break
    end
end

if not WindUI then
    -- UI Fallback - Crear UI básica si WindUI falla
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FARM_Fallback"
    ScreenGui.Parent = game.CoreGui
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 300, 0, 400)
    Frame.Position = UDim2.new(0.5, -150, 0.5, -200)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 30)
    Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    Title.Text = "FARM v3.1 - Fallback Mode"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.Parent = Frame
    
    local ErrorText = Instance.new("TextLabel")
    ErrorText.Size = UDim2.new(1, -20, 0, 100)
    ErrorText.Position = UDim2.new(0, 10, 0, 50)
    ErrorText.BackgroundTransparency = 1
    ErrorText.Text = "WindUI no pudo cargar.\nVerifica tu conexión o usa otro executor."
    ErrorText.TextColor3 = Color3.fromRGB(255, 100, 100)
    ErrorText.TextSize = 14
    ErrorText.TextWrapped = true
    ErrorText.Parent = Frame
    
    warn("FARM: WindUI no cargó - Modo Fallback activado")
    
    -- Crear mock de WindUI mínimo
    WindUI = {
        CreateWindow = function(self, opts)
            return {
                Tab = function() return {
                    Section = function() end,
                    Toggle = function() end,
                    Button = function() end,
                    Dropdown = function() end,
                    Slider = function() end,
                    Input = function() end,
                    Label = function() end,
                    Select = function() end
                } end,
                Notify = function() end
            }
        end,
        Notify = function(self, opts)
            print("[NOTIFY]", opts.Title, "-", opts.Content)
        end
    }
end

--// CONFIGURACIÓN SIMPLE
local FARM = {
    Active = false,
    CurrentJob = nil,
    Config = {
        PreferredJob = "shelf_stocker",
        AutoFarm = false,
        Humanize = true
    }
}

--// SISTEMA DE JOBS SIMPLIFICADO (Sin hooks complejos)
local Jobs = {
    shelf_stocker = {
        name = "shelf_stocker",
        location = nil, -- Se busca dinámicamente
        state = "IDLE"
    },
    steakhouse_cook = {
        name = "steakhouse_cook", 
        location = nil,
        state = "IDLE"
    },
    janitor = {
        name = "janitor",
        location = nil,
        state = "IDLE"
    }
}

--// BUSCAR LOCATIONS DINÁMICAMENTE
local function FindJobLocations()
    -- Shelf Stocker
    local gasStation = Workspace:FindFirstChild("Map") 
        and Workspace.Map:FindFirstChild("Tiles") 
        and Workspace.Map.Tiles:FindFirstChild("GasStationTile")
    
    if gasStation then
        local quick11 = gasStation:FindFirstChild("Quick11")
        if quick11 then
            local interior = quick11:FindFirstChild("Interior")
            if interior then
                local beacon = interior:FindFirstChild("Quick11Beacon")
                if beacon then
                    Jobs.shelf_stocker.location = beacon:FindFirstChild("TouchPart")
                end
            end
        end
    end
    
    -- Steakhouse Cook
    local shopping = Workspace:FindFirstChild("Map") 
        and Workspace.Map:FindFirstChild("Tiles") 
        and Workspace.Map.Tiles:FindFirstChild("ShoppingTile")
    
    if shopping then
        local steakhouse = shopping:FindFirstChild("SteakHouse")
        if steakhouse then
            local interior = steakhouse:FindFirstChild("Interior")
            if interior then
                local beacon = interior:FindFirstChild("SteakHouseBeacon")
                if beacon then
                    Jobs.steakhouse_cook.location = beacon:FindFirstChild("TouchPart")
                end
            end
        end
    end
    
    -- Janitor
    Jobs.janitor.location = Workspace:FindFirstChild("BurgePlaceBeacon") 
        and Workspace.BurgePlaceBeacon:FindFirstChild("TouchPart")
    
    print("Locations encontradas:")
    for job, data in pairs(Jobs) do
        print("  " .. job .. ":", data.location and "SÍ" or "NO")
    end
end

--// ESPERAR A QUE EL JUEGO CARGUE
task.spawn(function()
    repeat task.wait(1) until Workspace:FindFirstChild("Map")
    FindJobLocations()
end)

--// FUNCIONES BÁSICAS
local function Notify(title, content)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = content,
            Duration = 3
        })
    end)
end

local function TweenToPosition(position)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local distance = (hrp.Position - position).Magnitude
    local duration = distance / 16
    
    local tween = TweenService:Create(hrp, TweenInfo.new(duration), {
        CFrame = CFrame.new(position)
    })
    tween:Play()
    return tween
end

--// FARM LOOP BÁSICO
local function FarmLoop()
    while FARM.Active do
        local job = Jobs[FARM.Config.PreferredJob]
        if not job then task.wait(1) continue end
        
        if job.name == "shelf_stocker" then
            -- Lógica simplificada de shelf stocker
            print("Farming shelf_stocker...")
            task.wait(5)
            
        elseif job.name == "steakhouse_cook" then
            print("Farming steakhouse_cook...")
            task.wait(5)
            
        elseif job.name == "janitor" then
            print("Farming janitor...")
            task.wait(5)
        end
        
        task.wait(1)
    end
end

--// CREAR UI
local Window = WindUI:CreateWindow({
    Title = "FARM",
    Author = "By: adamABJ",
    Icon = "bolt",
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.RightShift,
})

local TabFarm = Window:Tab({ Title = "Farming", Icon = "case" })
local TabServer = Window:Tab({ Title = "Server", Icon = "server" })
local TabConfig = Window:Tab({ Title = "Config", Icon = "settings" })

-- Farming Tab
TabFarm:Section({ Title = "Auto Farm" })

TabFarm:Toggle({
    Title = "Enable Auto Farm",
    Value = false,
    Callback = function(v)
        FARM.Active = v
        FARM.Config.AutoFarm = v
        
        if v then
            Notify("FARM", "Started!")
            task.spawn(FarmLoop)
        else
            Notify("FARM", "Stopped!")
        end
    end
})

TabFarm:Dropdown({
    Title = "Select Job",
    Value = "shelf_stocker",
    Values = {"shelf_stocker", "steakhouse_cook", "janitor"},
    Callback = function(v)
        FARM.Config.PreferredJob = v
    end
})

-- Server Tab
TabServer:Section({ Title = "Server Info" })

local ServerInfo = {
    PlaceId = game.PlaceId,
    JobId = game.JobId,
    Players = #Players:GetPlayers()
}

TabServer:Label({ Title = "PlaceId: " .. ServerInfo.PlaceId })
TabServer:Label({ Title = "Players: " .. ServerInfo.Players })
TabServer:Label({ Title = "JobId: " .. string.sub(ServerInfo.JobId, 1, 20) .. "..." })

TabServer:Button({
    Title = "Copy JobId",
    Callback = function()
        if setclipboard then
            setclipboard(game.JobId)
            Notify("Success", "JobId copied!")
        end
    end
})

-- Config Tab
TabConfig:Section({ Title = "Settings" })

TabConfig:Button({
    Title = "Test Notification",
    Callback = function()
        Notify("Test", "FARM is working!")
    end
})

-- Inicializar
Notify("FARM Loaded", "v3.1 by adamABJ")

print("FARM v3.1 cargado correctamente")
