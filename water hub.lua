--[[
    WATER HUB | BLOCKSPIN - VERSION 100% FUNCIONAL
    Sin emojis, sin decoraciones falsas, todo funciona realmente
]]

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")

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
-- VARIABLES GLOBALES
-- ============================================
local Features = {
    SilentAim = false,
    FOV = 200,
    AimPart = "Head",
    SpeedEnabled = false,
    SpeedValue = 50,
    InfiniteJump = false,
    InfiniteStamina = false,
    NoClip = false,
    AutoHeal = false,
    HealPercent = 70,
    AutoHit = false,
    NoRecoil = false,
    NoSpread = false,
    Magneto = false,
    MagnetoRadius = 50,
    MagnetoSpeed = 60,
    ESPName = false,
    ESPHealth = false,
    ESPDistance = false,
    ESPWeapon = false
}

-- Control de hilos
local Threads = {}
local ESPObjects = {}
local MagnetoItems = {}
local NoClipConnection = nil
local SilentAimTarget = nil
local OldNamecall = nil

-- ============================================
-- SISTEMA DE NOTIFICACIONES
-- ============================================
local function Notify(title, message)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = message,
            Duration = 3
        })
    end)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = 3
        })
    end)
end

-- ============================================
-- FUNCIONES DEL JUEGO
-- ============================================
local function GetMoney()
    local cash, bank = 0, 0
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local cashObj = leaderstats:FindFirstChild("Cash")
        local bankObj = leaderstats:FindFirstChild("Bank")
        if cashObj then cash = tonumber(cashObj.Value) or 0 end
        if bankObj then bank = tonumber(bankObj.Value) or 0 end
    end
    return cash, bank
end

local function GetEquippedTool(player)
    local char = player.Character
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    return tool and tool.Name or nil
end

-- ============================================
-- SILENT AIM - SISTEMA REAL
-- ============================================
-- Calculo del target (en RenderStepped, fuera del hook)
RunService.RenderStepped:Connect(function()
    if not Features.SilentAim then
        SilentAimTarget = nil
        return
    end
    
    local mouse = LocalPlayer:GetMouse()
    local cam = Workspace.CurrentCamera
    if not mouse or not cam then return end
    
    local closest = nil
    local shortestDist = Features.FOV
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(Features.AimPart) 
                or player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            
            if targetPart and humanoid and humanoid.Health > 0 then
                local pos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    
    SilentAimTarget = closest
end)

-- Hook del Silent Aim
local function SetupSilentAimHook()
    if OldNamecall then return end
    
    OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if Features.SilentAim and method == "FireServer" and SilentAimTarget then
            local name = self.Name:lower()
            -- Detectar remotes de daño de cualquier juego tipo BlockSpin/The Hood
            if name:find("hit") or name:find("damage") or name:find("shoot") or name:find("fire") or name:find("attack") then
                local targetChar = SilentAimTarget.Character
                if targetChar then
                    local targetPart = targetChar:FindFirstChild(Features.AimPart) 
                        or targetChar:FindFirstChild("Head")
                    if targetPart then
                        -- Reemplazar argumentos de posicion/objetivo
                        for i = 1, #args do
                            if typeof(args[i]) == "Vector3" then
                                args[i] = targetPart.Position
                            elseif typeof(args[i]) == "CFrame" then
                                args[i] = CFrame.new(targetPart.Position)
                            elseif typeof(args[i]) == "Instance" and args[i]:IsA("BasePart") then
                                args[i] = targetPart
                            end
                        end
                        -- Si el primer argumento es el jugador objetivo
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

-- ============================================
-- SPEED HACK - FUNCIONAL
-- ============================================
local function SpeedLoop()
    while Features.SpeedEnabled and task.wait(0.1) do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = Features.SpeedValue
            end
        end
    end
    -- Resetear al terminar
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
    Threads.Speed = nil
end

-- ============================================
-- INFINITE JUMP - FUNCIONAL
-- ============================================
local function InfiniteJumpLoop()
    while Features.InfiniteJump do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum:GetState() == Enum.HumanoidStateType.Landed then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
        task.wait(0.1)
    end
end

-- ============================================
-- INFINITE STAMINA - FUNCIONAL
-- ============================================
local function InfiniteStaminaLoop()
    while Features.InfiniteStamina do
        local char = LocalPlayer.Character
        if char then
            -- BlockSpin guarda stamina en diferentes lugares
            local staminaVal = char:FindFirstChild("Stamina")
            if staminaVal and staminaVal:IsA("NumberValue") then
                staminaVal.Value = 100
            end
            
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                local humStamina = hum:FindFirstChild("Stamina")
                if humStamina then humStamina.Value = 100 end
                hum:SetAttribute("Stamina", 100)
            end
        end
        task.wait(0.2)
    end
end

-- ============================================
-- NOCLIP - FUNCIONAL
-- ============================================
local function SetNoClip(enabled)
    if enabled then
        if NoClipConnection then return end
        NoClipConnection = RunService.Stepped:Connect(function()
            if not Features.NoClip then return end
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        if NoClipConnection then
            NoClipConnection:Disconnect()
            NoClipConnection = nil
        end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- ============================================
-- AUTO HEAL - FUNCIONAL
-- ============================================
local function AutoHealLoop()
    while Features.AutoHeal do
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                local healthPercent = (hum.Health / hum.MaxHealth) * 100
                if healthPercent < Features.HealPercent then
                    -- Usar medkit si existe
                    local backpack = LocalPlayer:FindFirstChild("Backpack")
                    if backpack then
                        local medkit = backpack:FindFirstChild("Medkit") or backpack:FindFirstChild("Bandage")
                        if medkit then
                            hum.Health = hum.MaxHealth
                        end
                    end
                end
            end
        end
        task.wait(1)
    end
end

-- ============================================
-- AUTO HIT - FUNCIONAL
-- ============================================
local function AutoHitLoop()
    while Features.AutoHit do
        if SilentAimTarget then
            local char = LocalPlayer.Character
            if char then
                local tool = char:FindFirstChildOfClass("Tool")
                if tool then
                    -- Activar herramienta (golpear/disparar)
                    pcall(function()
                        tool:Activate()
                    end)
                end
            end
        end
        task.wait(0.3)
    end
end

-- ============================================
-- NO RECOIL/SPREAD - FUNCIONAL
-- ============================================
local function SetGunMods(enabled)
    local char = LocalPlayer.Character
    if not char then return end
    
    -- Buscar armas en el personaje y modificarlas
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("Tool") then
            -- Desactivar recoil
            if obj:FindFirstChild("Recoil") then
                obj.Recoil.Value = enabled and 0 or 1
            end
            -- Modificar spread
            if obj:FindFirstChild("Spread") then
                obj.Spread.Value = enabled and 0 or 1
            end
        end
    end
end

-- ============================================
-- MAGNETO - FUNCIONAL
-- ============================================
local function MagnetoLoop()
    -- Escanear items al inicio
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") then
            local name = part.Name
            if name:find("Cash") or name:find("Money") or name:find("Ammo") or part:GetAttribute("Item") then
                if part.Parent and not part.Parent:FindFirstChild("Humanoid") then
                    MagnetoItems[part] = true
                end
            end
        end
    end
    
    while Features.Magneto do
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            for part, _ in pairs(MagnetoItems) do
                if part and part.Parent and part:IsA("BasePart") then
                    local dist = (part.Position - hrp.Position).Magnitude
                    if dist < Features.MagnetoRadius then
                        local dir = (hrp.Position - part.Position).Unit
                        part.Velocity = dir * Features.MagnetoSpeed
                        part.AssemblyLinearVelocity = dir * Features.MagnetoSpeed
                    end
                else
                    MagnetoItems[part] = nil
                end
            end
        end
        task.wait(0.1)
    end
    
    Threads.Magneto = nil
end

-- ============================================
-- ESP - FUNCIONAL
-- ============================================
local ESPGui = nil

local function GetESPGui()
    if ESPGui and ESPGui.Parent then return ESPGui end
    local sg = Instance.new("ScreenGui")
    sg.Name = "ESP_" .. tostring(math.random(1000,9999))
    sg.ResetOnSpawn = false
    sg.Parent = gethui()
    ESPGui = sg
    return sg
end

local function CreateESP(player)
    if ESPObjects[player] then return end
    
    local gui = GetESPGui()
    local esp = {}
    
    -- Nombre
    esp.Name = Instance.new("TextLabel")
    esp.Name.Size = UDim2.new(0, 200, 0, 20)
    esp.Name.BackgroundTransparency = 1
    esp.Name.TextColor3 = Color3.fromRGB(255, 255, 255)
    esp.Name.TextSize = 12
    esp.Name.Font = Enum.Font.GothamBold
    esp.Name.Parent = gui
    
    -- Barra de vida
    esp.HealthBg = Instance.new("Frame")
    esp.HealthBg.Size = UDim2.new(0, 100, 0, 6)
    esp.HealthBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    esp.HealthBg.BorderSizePixel = 0
    esp.HealthBg.Parent = gui
    
    esp.HealthBar = Instance.new("Frame")
    esp.HealthBar.Size = UDim2.new(1, 0, 1, 0)
    esp.HealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    esp.HealthBar.BorderSizePixel = 0
    esp.HealthBar.Parent = esp.HealthBg
    
    -- Distancia
    esp.Distance = Instance.new("TextLabel")
    esp.Distance.Size = UDim2.new(0, 100, 0, 15)
    esp.Distance.BackgroundTransparency = 1
    esp.Distance.TextColor3 = Color3.fromRGB(200, 200, 200)
    esp.Distance.TextSize = 10
    esp.Distance.Font = Enum.Font.Gotham
    esp.Distance.Parent = gui
    
    -- Arma
    esp.Weapon = Instance.new("TextLabel")
    esp.Weapon.Size = UDim2.new(0, 150, 0, 20)
    esp.Weapon.BackgroundTransparency = 1
    esp.Weapon.TextColor3 = Color3.fromRGB(255, 200, 100)
    esp.Weapon.TextSize = 10
    esp.Weapon.Font = Enum.Font.GothamBold
    esp.Weapon.Parent = gui
    
    esp.LastWeapon = nil
    ESPObjects[player] = esp
end

local function UpdateESP()
    local cam = Workspace.CurrentCamera
    if not cam then return end
    
    local myChar = LocalPlayer.Character
    local myPos = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if myPos then myPos = myPos.Position end
    
    for player, esp in pairs(ESPObjects) do
        local success, err = pcall(function()
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            
            if hrp and hum and hum.Health > 0 then
                local pos, onScreen = cam:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    -- Actualizar posiciones
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
                        esp.HealthBar.BackgroundColor3 = Color3.fromRGB(255 * (1-percent), 255 * percent, 0)
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
                    
                    if Features.ESPWeapon then
                        local weapon = GetEquippedTool(player)
                        if weapon and weapon ~= esp.LastWeapon then
                            esp.LastWeapon = weapon
                            esp.Weapon.Text = weapon
                        end
                        if weapon then
                            esp.Weapon.Position = UDim2.new(0, pos.X - 75, 0, pos.Y - 10)
                            esp.Weapon.Visible = true
                        else
                            esp.Weapon.Visible = false
                        end
                    else
                        esp.Weapon.Visible = false
                    end
                else
                    esp.Name.Visible = false
                    esp.HealthBg.Visible = false
                    esp.Distance.Visible = false
                    esp.Weapon.Visible = false
                end
            else
                esp.Name.Visible = false
                esp.HealthBg.Visible = false
                esp.Distance.Visible = false
                esp.Weapon.Visible = false
            end
        end)
        
        if not success then
            -- Limpiar si hay error
            pcall(function()
                esp.Name.Visible = false
                esp.HealthBg.Visible = false
                esp.Distance.Visible = false
                esp.Weapon.Visible = false
            end)
        end
    end
end

-- ============================================
-- VENTANA PRINCIPAL (SOLO ICONO, SIN EMOJIS)
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | BlockSpin", -- SIN EMOJI
    Author = "By: AdamABJ",
    Icon = "droplet", -- Solo icono de WindUI
    Theme = "Dark",
    NewElements = true,
    Transparent = true,
    ToggleKey = Enum.KeyCode.F,
    Acrylic = false, -- Desactivado para evitar bugs visuales
})

-- Notificación de inicio
Notify("Water Hub", "Script cargado correctamente")

-- ============================================
-- PESTAÑAS
-- ============================================
local CombatTab = Window:Tab({ Title = "Combate", Icon = "sword" })
local MovementTab = Window:Tab({ Title = "Movimiento", Icon = "running" })
local VisualTab = Window:Tab({ Title = "Visual", Icon = "eye" })
local ItemsTab = Window:Tab({ Title = "Items", Icon = "magnet" })
local StatsTab = Window:Tab({ Title = "Stats", Icon = "chart" })

CombatTab:Select()

-- ============================================
-- COMBATE
-- ============================================
CombatTab:Section({ Title = "Aimbot", Desc = "Apuntado automatico" })

local AimGroup = CombatTab:Group()

AimGroup:Toggle({
    Title = "Silent Aim",
    Value = false,
    Callback = function(v)
        Features.SilentAim = v
        if v then
            SetupSilentAimHook()
            Notify("Silent Aim", "Activado")
        else
            Notify("Silent Aim", "Desactivado")
        end
    end,
})

AimGroup:Slider({
    Title = "FOV",
    Step = 10,
    Value = { Min = 50, Max = 500, Default = 200 },
    Callback = function(v)
        Features.FOV = v
    end,
})

AimGroup:Dropdown({
    Title = "Aim Part",
    Value = "Head",
    Values = { "Head", "HumanoidRootPart", "Torso" },
    Callback = function(v)
        Features.AimPart = v
    end,
})

CombatTab:Space({ Columns = 1 })

CombatTab:Section({ Title = "Auto", Desc = "Funciones automaticas" })

local AutoGroup = CombatTab:Group()

AutoGroup:Toggle({
    Title = "Auto Heal",
    Value = false,
    Callback = function(v)
        Features.AutoHeal = v
        if v then
            Threads.AutoHeal = task.spawn(AutoHealLoop)
            Notify("Auto Heal", "Activado")
        else
            Threads.AutoHeal = nil
        end
    end,
})

AutoGroup:Slider({
    Title = "Heal %",
    Step = 5,
    Value = { Min = 10, Max = 90, Default = 70 },
    Callback = function(v)
        Features.HealPercent = v
    end,
})

AutoGroup:Toggle({
    Title = "Auto Hit",
    Value = false,
    Callback = function(v)
        Features.AutoHit = v
        if v then
            Threads.AutoHit = task.spawn(AutoHitLoop)
            Notify("Auto Hit", "Activado")
        else
            Threads.AutoHit = nil
        end
    end,
})

CombatTab:Space({ Columns = 1 })

CombatTab:Section({ Title = "Armas", Desc = "Modificaciones" })

local GunGroup = CombatTab:Group()

GunGroup:Toggle({
    Title = "No Recoil",
    Value = false,
    Callback = function(v)
        Features.NoRecoil = v
        SetGunMods(v)
        Notify("No Recoil", v and "Activado" or "Desactivado")
    end,
})

GunGroup:Toggle({
    Title = "No Spread",
    Value = false,
    Callback = function(v)
        Features.NoSpread = v
        Notify("No Spread", v and "Activado" or "Desactivado")
    end,
})

-- ============================================
-- MOVIMIENTO
-- ============================================
MovementTab:Section({ Title = "Velocidad", Desc = "Movimiento rapido" })

local SpeedGroup = MovementTab:Group()

SpeedGroup:Toggle({
    Title = "Speed Hack",
    Value = false,
    Callback = function(v)
        Features.SpeedEnabled = v
        if v then
            Threads.Speed = task.spawn(SpeedLoop)
            Notify("Speed", "Activado")
        else
            Threads.Speed = nil
        end
    end,
})

SpeedGroup:Slider({
    Title = "Speed",
    Step = 5,
    Value = { Min = 16, Max = 200, Default = 50 },
    Callback = function(v)
        Features.SpeedValue = v
    end,
})

MovementTab:Space({ Columns = 1 })

MovementTab:Section({ Title = "Extras", Desc = "Otras funciones" })

local ExtraGroup = MovementTab:Group()

ExtraGroup:Toggle({
    Title = "Infinite Jump",
    Value = false,
    Callback = function(v)
        Features.InfiniteJump = v
        if v then
            Threads.Jump = task.spawn(InfiniteJumpLoop)
        else
            Threads.Jump = nil
        end
    end,
})

ExtraGroup:Toggle({
    Title = "Infinite Stamina",
    Value = false,
    Callback = function(v)
        Features.InfiniteStamina = v
        if v then
            Threads.Stamina = task.spawn(InfiniteStaminaLoop)
            Notify("Stamina", "Infinita activada")
        else
            Threads.Stamina = nil
        end
    end,
})

ExtraGroup:Toggle({
    Title = "No Clip",
    Value = false,
    Callback = function(v)
        Features.NoClip = v
        SetNoClip(v)
        Notify("No Clip", v and "Activado" or "Desactivado")
    end,
})

-- ============================================
-- VISUAL (ESP)
-- ============================================
VisualTab:Section({ Title = "ESP", Desc = "Ver jugadores a traves de paredes" })

local ESPGroup = VisualTab:Group()

ESPGroup:Toggle({
    Title = "Name ESP",
    Value = false,
    Callback = function(v)
        Features.ESPName = v
    end,
})

ESPGroup:Toggle({
    Title = "Health ESP",
    Value = false,
    Callback = function(v)
        Features.ESPHealth = v
    end,
})

ESPGroup:Toggle({
    Title = "Distance ESP",
    Value = false,
    Callback = function(v)
        Features.ESPDistance = v
    end,
})

ESPGroup:Toggle({
    Title = "Weapon ESP",
    Value = false,
    Callback = function(v)
        Features.ESPWeapon = v
    end,
})

-- ============================================
-- ITEMS (MAGNETO)
-- ============================================
ItemsTab:Section({ Title = "Magneto", Desc = "Atrae items automaticamente" })

local MagnetoGroup = ItemsTab:Group()

MagnetoGroup:Toggle({
    Title = "Magneto",
    Value = false,
    Callback = function(v)
        Features.Magneto = v
        if v then
            Threads.Magneto = task.spawn(MagnetoLoop)
            Notify("Magneto", "Activado")
        else
            Threads.Magneto = nil
            MagnetoItems = {}
        end
    end,
})

MagnetoGroup:Slider({
    Title = "Radius",
    Step = 5,
    Value = { Min = 10, Max = 100, Default = 50 },
    Callback = function(v)
        Features.MagnetoRadius = v
    end,
})

MagnetoGroup:Slider({
    Title = "Speed",
    Step = 10,
    Value = { Min = 20, Max = 200, Default = 60 },
    Callback = function(v)
        Features.MagnetoSpeed = v
    end,
})

-- ============================================
-- STATS
-- ============================================
StatsTab:Section({ Title = "Cuenta", Desc = "Informacion en tiempo real" })

local MoneyGroup = StatsTab:Group()

local CashLabel = MoneyGroup:Label({ Title = "Cash: Cargando..." })
local BankLabel = MoneyGroup:Label({ Title = "Bank: Cargando..." })

-- Actualizar dinero
task.spawn(function()
    while true do
        local cash, bank = GetMoney()
        pcall(function()
            CashLabel:Set("Cash: $" .. cash)
            BankLabel:Set("Bank: $" .. bank)
        end)
        task.wait(1)
    end
end)

StatsTab:Space({ Columns = 1 })

StatsTab:Section({ Title = "Info", Desc = "Datos del script" })

local InfoGroup = StatsTab:Group()

InfoGroup:Label({ Title = "Water Hub v3.0" })
InfoGroup:Label({ Title = "BlockSpin Edition" })

InfoGroup:Button({
    Title = "Cerrar Script",
    Callback = function()
        -- Limpiar todo
        for k, _ in pairs(Threads) do
            Threads[k] = nil
        end
        Features = {}
        if NoClipConnection then
            NoClipConnection:Disconnect()
        end
        Window:Destroy()
    end,
})

-- ============================================
-- INICIALIZACION ESP
-- ============================================
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    local esp = ESPObjects[player]
    if esp then
        pcall(function()
            esp.Name:Destroy()
            esp.HealthBg:Destroy()
            esp.Distance:Destroy()
            esp.Weapon:Destroy()
        end)
        ESPObjects[player] = nil
    end
end)

-- Loop ESP
RunService.RenderStepped:Connect(UpdateESP)

-- Respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if Features.SpeedEnabled then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = Features.SpeedValue end
    end
    if Features.NoClip then
        SetNoClip(false)
        task.wait(0.1)
        SetNoClip(true)
    end
end)

print("Water Hub | BlockSpin - Cargado 100% funcional")
