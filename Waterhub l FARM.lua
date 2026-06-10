loadstring([[
local L = loadstring(game:HttpGet("https://raw.githubusercontent.com/x2zu/OPEN-SOURCE-UI-ROBLOX/refs/heads/main/X2ZU%20UI%20ROBLOX%20OPEN%20SOURCE/DummyUi-leak-by-x2zu/fetching-main/Tools/Framework.luau"))()
task.wait(0.4)

-- Servicios y Variables Globales
local P = game.Players.LocalPlayer
local RS = game:GetService("RunService")
local WS = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")

-- Configuración de la Ventana Principal
local W = L:Window({
    Title = "MONA HUB",
    Desc = "x2zu on top",
    Icon = 105059922903197,
    Theme = "Dark",
    Config = {
        Keybind = Enum.KeyCode.LeftControl,
        Size = UDim2.new(0, 500, 0, 400)
    },
    CloseUIButton = {
        Enabled = true,
        Text = "x2zu"
    }
})

-- ============================================
-- PESTAÑA: PLAYER (Jugador)
-- ============================================
local PT = W:Tab({ Title = "Player", Icon = "star" })
PT:Section({ Title = "Player Controls" })

local ws, jb, wsD, jbD = 16, 0, 16, 0

-- Control de Velocidad (WalkSpeed)
PT:Slider({
    Title = "Walk Speed",
    Min = 16,
    Max = 200,
    Default = ws,
    Callback = function(v)
        if P.Character and P.Character:FindFirstChild("Humanoid") then
            P.Character.Humanoid.WalkSpeed = v
        end
    end
})

-- Control de Salto (Jump Boost)
PT:Slider({
    Title = "Jump Boost",
    Min = 0,
    Max = 200,
    Default = jb,
    Callback = function(v)
        jb = v
    end
})

-- Lógica del Jump Boost (BodyVelocity)
UIS.JumpRequest:Connect(function()
    if jb > 0 and P.Character and P.Character:FindFirstChild("HumanoidRootPart") then
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, jb, 0)
        bv.MaxForce = Vector3.new(0, math.huge, 0)
        bv.P = 10000
        bv.Parent = P.Character.HumanoidRootPart
        game.Debris:AddItem(bv, 0.3)
    end
end)

-- Botón de Reinicio de Valores
PT:Button({
    Title = "รีเซ็ตค่า", -- Botón de reinicio
    Callback = function()
        if P.Character and P.Character:FindFirstChild("Humanoid") then
            P.Character.Humanoid.WalkSpeed = wsD
        end
        jb = jbD
        W:Notify({
            Title = "รีเซ็ตสำเร็จ!",
            Desc = "กลับไปค่าเริ่มต้น",
            Time = 3
        })
    end
})

-- ============================================
-- PESTAÑA: ESP (Visuales y Optimización)
-- ============================================
local ESP_TAB = W:Tab({ Title = "ESP", Icon = "eye" })
ESP_TAB:Section({ Title = "ESP Controls" })

local BoostFPS, ShowNames, ShowItems = true, true, true

ESP_TAB:Toggle({
    Title = "Boost FPS",
    Value = false,
    Callback = function(v)
        BoostFPS = v
    end
})

ESP_TAB:Toggle({
    Title = "ESP ชื่อผู้เล่น", -- Mostrar nombres
    Value = true,
    Callback = function(v)
        ShowNames = v
    end
})

ESP_TAB:Toggle({
    Title = "ดูของผู้เล่น", -- Ver ítems
    Value = true,
    Callback = function(v)
        ShowItems = v
    end
})

-- Diccionario de traducción de ítems
local ItemNameMapping = {
    ["1001"] = "Spin Fruit",
    ["1002"] = "Sword",
    ["1003"] = "Shield"
}

-- Función para dibujar el ESP (BillboardGui)
local function CreateESP(p, text, color, name, offset)
    local b = Instance.new("BillboardGui")
    b.Name = name
    b.Adornee = p
    b.Size = UDim2.new(0, 150, 0, 35)
    b.AlwaysOnTop = true
    b.Value = offset or Vector3.new(0, 2, 0)
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.TextColor3 = color
    l.TextScaled = true
    l.Font = Enum.Font.SourceSansBold
    l.Text = text
    l.Parent = b
    
    b.Parent = p
    return b
end

-- Función para leer los inventarios
local function GetInventory(plr)
    if plr == P then 
        return "ตัวเรา" 
    end
    
    local txt = ""
    local pd = WS:FindFirstChild("PlayerData")
    
    if pd and pd:FindFirstChild(plr.Name) then
        local inv = pd[plr.Name]:FindFirstChild("Inventory")
        if inv then
            for _, i in pairs(inv:GetChildren()) do
                txt = txt .. (ItemNameMapping[i.Name] or i.Name) .. ", "
            end
        end
    else
        -- Lectura alternativa por Backpack estándar
        for _, i in pairs(plr.Backpack:GetChildren()) do
            if i:IsA("Tool") then
                txt = txt .. i.Name .. ", "
            end
        end
        if plr.Character then
            for _, i in pairs(plr.Character:GetChildren()) do
                if i:IsA("Tool") then
                    txt = txt .. i.Name .. ", "
                end
            end
        end
    end
    
    if txt ~= "" then
        txt = txt:sub(1, -3)
    else
        txt = "ไม่มีของ"
    end
    return txt
end

-- Función para reducir gráficos (Boost FPS)
local function ApplyBoostFPS()
    for _, o in pairs(WS:GetDescendants()) do
        if o:IsA("BasePart") and o.Parent ~= P.Character then
            o.Material = Enum.Material.Plastic
            o.Color = Color3.fromRGB(50, 50, 50)
            o.CastShadow = false
        end
    end
end

-- Bucles de Renderizado para ESP y FPS
RS.Heartbeat:Connect(function()
    if BoostFPS then 
        ApplyBoostFPS() 
    end
end)

RS.RenderStepped:Connect(function()
    for _, plr in pairs(game.Players:GetPlayers()) do
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local HRP = plr.Character.HumanoidRootPart
            
            -- Lógica para pintar nombres
            if ShowNames and plr ~= P then
                if not HRP:FindFirstChild("ESP_Name") then
                    CreateESP(HRP, plr.Name, Color3.new(1, 0, 0), "ESP_Name", Vector3.new(0, 2, 0))
                else
                    HRP.ESP_Name.TextLabel.Text = plr.Name
                end
            elseif HRP:FindFirstChild("ESP_Name") then
                HRP.ESP_Name:Destroy()
            end
            
            -- Lógica para pintar ítems de inventario
            if ShowItems and plr ~= P then
                local inv = GetInventory(plr)
                if not HRP:FindFirstChild("ESP_Items") then
                    CreateESP(HRP, inv, Color3.new(0, 1, 0), "ESP_Items", Vector3.new(0, -2, 0))
                else
                    HRP.ESP_Items.TextLabel.Text = inv
                end
            elseif HRP:FindFirstChild("ESP_Items") then
                HRP.ESP_Items:Destroy()
            end
        end
    end
end)

-- ============================================
-- PESTAÑA: PVP (Combate)
-- ============================================
local PV = W:Tab({ Title = "PVP", Icon = "sword" })
PV:Section({ Title = "Combat Features" })

PV:Toggle({
    Title = "Silent Aim",
    Value = false,
    Callback = function(en)
        if en then
            getgenv().khen = {
                ['Silent'] = {
                    Normal = { Enabled = true, HitPart = "Head", Prediction = 0.1657724, AirPrediction = 0.149 },
                    FOV = { FOVSize = 250, ShowFOV = true },
                    Resolver = { Enabled = true }
                }
            }
            loadstring(game:HttpGet("https://raw.githubusercontent.com/khenn791/script-khen/refs/heads/main/SilentAim", true))()
        else
            if getgenv().khen and getgenv().khen.Silent then
                getgenv().khen.Silent.Normal.Enabled = false
            end
        end
    end
})

-- ============================================
-- PESTAÑA: SERVER (Gestión de Servidores)
-- ============================================
local ST = W:Tab({ Title = "Server", Icon = "server" })
ST:Section({ Title = "Server Features" })

-- Cambiar de servidor de forma automática (Server Hop)
ST:Button({
    Title = "เปลี่ยนเซิร์ฟ", -- Cambiar servidor
    Callback = function()
        local PID = game.PlaceId
        local c = ""
        local fs
        
        repeat
            local ok, res = pcall(function()
                return HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PID .. "/servers/Public?sortOrder=Asc&limit=100" .. (c ~= "" and "&cursor=" .. c or "")))
            end)
            
            if ok and res and res.data then
                for _, s in pairs(res.data) do
                    if s.playing < s.maxPlayers and s.id ~= game.JobId then
                        fs = s.id
                        break
                    end
                end
                c = res.nextPageCursor or ""
            else
                break
            end
        until fs or c == ""
        
        if fs then
            TS:TeleportToPlaceInstance(PID, fs, P)
        else
            W:Notify({
                Title = "ไม่พบ Server",
                Desc = "ไม่มี Server ว่าง",
                Time = 4
            })
        end
    end
})

-- Mostrar información del servidor actual
ST:Button({
    Title = "Server Info",
    Callback = function()
        W:Notify({
            Title = "Server Info",
            Desc = "PlaceId:" .. game.PlaceId .. "\nJobId:" .. game.JobId,
            Time = 4
        })
    end
})

-- ============================================
-- PESTAÑA: UI (Configuración de Interfaz)
-- ============================================
local UT = W:Tab({ Title = "UI", Icon = "desktop" })
UT:Section({ Title = "UI Controls" })

UT:Toggle({
    Title = "UI Toggle",
    Value = true,
    Callback = function(v)
        W.Enabled = v
    end
})

UT:Toggle({
    Title = "Lock UI",
    Value = false,
    Callback = function(v)
        W.Draggable = not v
    end
})

-- Notificación de Carga Completa
W:Notify({
    Title = "MONA HUB v1.2",
    Desc = "Loaded!",
    Time = 4
})
]])()
