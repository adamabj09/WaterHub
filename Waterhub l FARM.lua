-- ============================================
-- CARGAR VENYX UI
-- ============================================
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Thunderblade737/VenyxUI/main/source.lua"))()

if not Library then
    warn("Error cargando Venyx UI")
    return
end

-- ============================================
-- CREAR VENTANA PRINCIPAL
-- ============================================
local Window = Library:CreateWindow("Water Hub | MM2", Enum.KeyCode.RightShift)
Window:SetSize(UDim2.new(0, 550, 0, 400))

-- ============================================
-- VARIABLES GLOBALES
-- ============================================
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local cam = workspace.CurrentCamera
local Mouse = player:GetMouse()

-- Variables de vuelo
local flying = false
local speedfly = 1
local CONTROL = {F = 0, B = 0, L = 0, R = 0}
local lCONTROL = {F = 0, B = 0, L = 0, R = 0}
local SPEED = 0
local flyConnections = {}

-- Actualizar character al morir
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
end)

-- ============================================
-- FUNCIÓN PARA ACTUALIZAR DROPDOWN DE JUGADORES
-- ============================================
local function UpdatePlayerList(dropdown)
    if not dropdown then return end
    local playerList = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            table.insert(playerList, plr.Name)
        end
    end
    dropdown:Clear()
    dropdown:Add(playerList)
end

-- ============================================
-- PESTAÑAS
-- ============================================
local MovementTab = Window:CreateTab("Movement")
local RenderTab = Window:CreateTab("Render")
local MurdererTab = Window:CreateTab("Murderer")
local TeleportTab = Window:CreateTab("Teleport")

-- ============================================
-- MOVEMENT TAB
-- ============================================
local SpeedSection = MovementTab:CreateSection("Speed")

SpeedSection:CreateSlider("Walk Speed", 0, 500, 16, true, function(Value)
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = Value
    end
end)

local JumpSection = MovementTab:CreateSection("Jump")

JumpSection:CreateSlider("Jump Power", 0, 500, 50, true, function(Value)
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.JumpPower = Value
    end
end)

local FOVSection = MovementTab:CreateSection("Camera")

FOVSection:CreateSlider("Field of View", 50, 120, 70, true, function(Value)
    cam.FieldOfView = Value
end)

local FlySection = MovementTab:CreateSection("Fly")

local flyToggle = false
FlySection:CreateToggle("Fly", false, function(Value)
    flyToggle = Value
    
    if Value then
        flying = true
        local T = character:WaitForChild("HumanoidRootPart")
        local BG = Instance.new("BodyGyro", T)
        local BV = Instance.new("BodyVelocity", T)
        BG.P = 9e4
        BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        BG.cframe = T.CFrame
        BV.velocity = Vector3.new(0, 0.1, 0)
        BV.maxForce = Vector3.new(9e9, 9e9, 9e9)

        local flyThread = game:GetService("RunService").Heartbeat:Connect(function()
            if not flying then return end
            
            if character:FindFirstChild("Humanoid") then
                character.Humanoid.PlatformStand = true
            end
            
            if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 then
                SPEED = 50
            elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0) and SPEED ~= 0 then
                SPEED = 0
            end
            
            if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 then
                BV.velocity = ((cam.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((cam.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B) * 0.2, 0).Position) - cam.CFrame.Position)) * SPEED
                lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
            elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and SPEED ~= 0 then
                BV.velocity = ((cam.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) + ((cam.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B) * 0.2, 0).Position) - cam.CFrame.Position)) * SPEED
            else
                BV.velocity = Vector3.new(0, 0.1, 0)
            end
            BG.cframe = cam.CFrame
        end)

        local keyDownConn = Mouse.KeyDown:Connect(function(KEY)
            local k = KEY:lower()
            if k == 'w' then CONTROL.F = speedfly
            elseif k == 's' then CONTROL.B = -speedfly
            elseif k == 'a' then CONTROL.L = -speedfly
            elseif k == 'd' then CONTROL.R = speedfly
            end
        end)
        
        local keyUpConn = Mouse.KeyUp:Connect(function(KEY)
            local k = KEY:lower()
            if k == 'w' then CONTROL.F = 0
            elseif k == 's' then CONTROL.B = 0
            elseif k == 'a' then CONTROL.L = 0
            elseif k == 'd' then CONTROL.R = 0
            end
        end)

        flyConnections = {flyThread, keyDownConn, keyUpConn, BG, BV}
        
        while flying and flyToggle do
            task.wait()
        end
        
        -- Limpiar al desactivar
        for _, conn in pairs(flyConnections) do
            if conn:IsA("RBXScriptConnection") then
                conn:Disconnect()
            elseif conn:IsA("BasePart") then
                conn:Destroy()
            end
        end
        flyConnections = {}
        CONTROL = {F = 0, B = 0, L = 0, R = 0}
        lCONTROL = {F = 0, B = 0, L = 0, R = 0}
        SPEED = 0
        if character:FindFirstChild("Humanoid") then
            character.Humanoid.PlatformStand = false
        end
    else
        flying = false
    end
end)

local OtherSection = MovementTab:CreateSection("Other")

local infiniteJumpActive = false
local infiniteJumpConn = nil

OtherSection:CreateButton("Infinite Jump", function()
    if infiniteJumpActive then
        if infiniteJumpConn then
            infiniteJumpConn:Disconnect()
            infiniteJumpConn = nil
        end
        infiniteJumpActive = false
        Library:Notification("Infinite Jump Deactivated", "Turned off", 3)
    else
        infiniteJumpActive = true
        infiniteJumpConn = UIS.JumpRequest:Connect(function()
            if character and character:FindFirstChild("Humanoid") and infiniteJumpActive then
                character.Humanoid:ChangeState("Jumping")
            end
        end)
        Library:Notification("Infinite Jump Activated", "Hold space to jump infinitely", 3)
    end
end)

local noclipActive = false
OtherSection:CreateToggle("NoClip", false, function(Value)
    noclipActive = Value
    if character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not Value
            end
        end
    end
end)

OtherSection:CreateButton("Grab Gun", function()
    if character and character:FindFirstChild("HumanoidRootPart") then
        local root = character.HumanoidRootPart
        local pos = root.CFrame
        if workspace:FindFirstChild("GunDrop") then
            root.CFrame = workspace.GunDrop.CFrame
            task.wait(0.25)
            root.CFrame = pos
            Library:Notification("Success", "Teleported to gun drop", 3)
        else
            Library:Notification("Sheriff Not Dead", "Wait until the sheriff dies and drops the gun", 5)
        end
    end
end)

-- ============================================
-- RENDER TAB
-- ============================================
local ESPSection = RenderTab:CreateSection("ESP")

local murdererESPActive = false
local sheriffESPActive = false

local function UpdateESP()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character then
            local backpack = v.Character:FindFirstChild("Backpack") or v:FindFirstChild("Backpack")
            local esp = v.Character:FindFirstChild("ESP")
            
            if murdererESPActive and backpack and backpack:FindFirstChild("Knife") then
                if not esp then
                    esp = Instance.new("Highlight")
                    esp.Name = "ESP"
                    esp.Parent = v.Character
                end
                esp.FillColor = Color3.fromRGB(255, 0, 0)
                esp.OutlineColor = Color3.fromRGB(255, 255, 255)
                esp.FillTransparency = 0.3
                esp.OutlineTransparency = 0
                esp.Enabled = true
            elseif sheriffESPActive and backpack and backpack:FindFirstChild("Gun") then
                if not esp then
                    esp = Instance.new("Highlight")
                    esp.Name = "ESP"
                    esp.Parent = v.Character
                end
                esp.FillColor = Color3.fromRGB(0, 0, 255)
                esp.OutlineColor = Color3.fromRGB(255, 255, 255)
                esp.FillTransparency = 0.3
                esp.OutlineTransparency = 0
                esp.Enabled = true
            elseif esp then
                esp.Enabled = false
            end
        end
    end
end

ESPSection:CreateToggle("Murderer ESP", false, function(Value)
    murdererESPActive = Value
    UpdateESP()
end)

ESPSection:CreateToggle("Sheriff ESP", false, function(Value)
    sheriffESPActive = Value
    UpdateESP()
end)

-- Actualizar ESP periódicamente
task.spawn(function()
    while task.wait(0.5) do
        if murdererESPActive or sheriffESPActive then
            UpdateESP()
        end
    end
end)

local NamesSection = RenderTab:CreateSection("Names")

NamesSection:CreateToggle("Show Names", false, function(Value)
    game.StarterPlayer.NameDisplayDistance = Value and 100 or 0
end)

-- ============================================
-- MURDERER TAB
-- ============================================
local MurderSection = MurdererTab:CreateSection("Murderer")

MurderSection:CreateButton("Kill All", function()
    local backpack = player:FindFirstChild("Backpack") or (character and character:FindFirstChild("Backpack"))
    if backpack and backpack:FindFirstChild("Knife") then
        for _, Victim in pairs(Players:GetPlayers()) do
            if Victim ~= player and Victim.Character and Victim.Character:FindFirstChild("HumanoidRootPart") then
                repeat
                    task.wait()
                    if character and character:FindFirstChild("HumanoidRootPart") and Victim.Character and Victim.Character:FindFirstChild("HumanoidRootPart") then
                        character.HumanoidRootPart.CFrame = Victim.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)
                    end
                until not Victim.Character or not Victim.Character:FindFirstChild("Humanoid") or Victim.Character.Humanoid.Health == 0
            end
        end
        Library:Notification("Done", "Killed all players", 3)
    else
        Library:Notification("Not Murderer", "You need to be the murderer to use this", 5)
    end
end)

-- ============================================
-- TELEPORT TAB
-- ============================================
local TeleportSection = TeleportTab:CreateSection("Teleports")

TeleportSection:CreateButton("Teleport to Lobby", function()
    if character and character:FindFirstChild("HumanoidRootPart") then
        character.HumanoidRootPart.CFrame = CFrame.new(-108.5, 145, 0.6)
    end
end)

TeleportSection:CreateButton("Teleport to Map", function()
    if character and character:FindFirstChild("HumanoidRootPart") then
        for _, v in pairs(workspace:GetChildren()) do
            if v:FindFirstChild("Spawns") then
                character.HumanoidRootPart.CFrame = v.Spawns.Spawn.CFrame
                break
            end
        end
    end
end)

TeleportSection:CreateButton("Teleport to Murderer", function()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character then
            local backpack = v:FindFirstChild("Backpack") or v.Character:FindFirstChild("Backpack")
            if backpack and backpack:FindFirstChild("Knife") and v.Character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
                break
            end
        end
    end
end)

TeleportSection:CreateButton("Teleport to Sheriff", function()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= player and v.Character then
            local backpack = v:FindFirstChild("Backpack") or v.Character:FindFirstChild("Backpack")
            if backpack and backpack:FindFirstChild("Gun") and v.Character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
                break
            end
        end
    end
end)

local TPPlayerSection = TeleportTab:CreateSection("Player Teleport")

local playerDropdown = TPPlayerSection:CreateDropdown("Select Player", {}, function(Value)
    if Value then
        local target = Players:FindFirstChild(Value)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
        end
    end
end)

-- Actualizar lista de jugadores cada 3 segundos
task.spawn(function()
    while task.wait(3) do
        local playerList = {}
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player then
                table.insert(playerList, plr.Name)
            end
        end
        playerDropdown:Clear()
        playerDropdown:Add(playerList)
    end
end)

-- ============================================
-- NOTIFICACIÓN DE CARGA
-- ============================================
Library:Notification("Water Hub", "MM2 script loaded successfully!", 5)