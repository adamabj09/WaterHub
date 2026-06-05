-- ============================================
-- CARGAR WINDUI
-- ============================================
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

if not WindUI then
    warn("Error cargando WindUI")
    return
end

-- ============================================
-- CREAR VENTANA PRINCIPAL
-- ============================================
local Window = WindUI:CreateWindow({
    Title = "Water Hub | MM2",
    Author = "By: AdamABJ",
    Theme = "Dark",
    ToggleKey = Enum.KeyCode.RightShift,
    Size = UDim2.new(0, 550, 0, 400)
})

-- ============================================
-- VARIABLES
-- ============================================
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local cam = game:GetService("Workspace").CurrentCamera
local Mouse = player:GetMouse()

-- Variables de vuelo
local flying = false
local speedfly = 1
local CONTROL = {F = 0, B = 0, L = 0, R = 0}
local lCONTROL = {F = 0, B = 0, L = 0, R = 0}
local SPEED = 0

-- Actualizar character al morir
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
end)

-- ============================================
-- PESTAÑAS (usando el método correcto de WindUI)
-- ============================================
local MovementTab = Window:AddTab("Movement")
local RenderTab = Window:AddTab("Render")
local MurdererTab = Window:AddTab("Murderer")
local TeleportTab = Window:AddTab("Teleport")

-- ============================================
-- MOVEMENT TAB
-- ============================================
local SpeedSection = MovementTab:AddSection("Speed")

SpeedSection:AddSlider({
    Name = "Walk Speed",
    Min = 0,
    Max = 500,
    Default = 16,
    Callback = function(Value)
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = Value
        end
    end
})

local JumpSection = MovementTab:AddSection("Jump")

JumpSection:AddSlider({
    Name = "Jump Power",
    Min = 0,
    Max = 500,
    Default = 50,
    Callback = function(Value)
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.JumpPower = Value
        end
    end
})

local FOVSection = MovementTab:AddSection("Camera")

FOVSection:AddSlider({
    Name = "Field of View",
    Min = 50,
    Max = 120,
    Default = 70,
    Callback = function(Value)
        cam.FieldOfView = Value
    end
})

local FlySection = MovementTab:AddSection("Fly")

FlySection:AddToggle({
    Name = "Fly",
    Default = false,
    Callback = function(Value)
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

            spawn(function()
                repeat task.wait()
                    if character:FindFirstChild("Humanoid") then
                        character.Humanoid.PlatformStand = true
                    end
                    if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 then
                        SPEED = 50
                    elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0) and SPEED ~= 0 then
                        SPEED = 0
                    end
                    if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 then
                        BV.velocity = ((cam.CFrame.LookVector * (CONTROL.F + CONTROL.B)) + ((cam.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B) * 0.2, 0).p) - cam.CFrame.p)) * SPEED
                        lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
                    elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and SPEED ~= 0 then
                        BV.velocity = ((cam.CFrame.LookVector * (lCONTROL.F + lCONTROL.B)) + ((cam.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B) * 0.2, 0).p) - cam.CFrame.p)) * SPEED
                    else
                        BV.velocity = Vector3.new(0, 0.1, 0)
                    end
                    BG.cframe = cam.CFrame
                until not flying
                CONTROL = {F = 0, B = 0, L = 0, R = 0}
                lCONTROL = {F = 0, B = 0, L = 0, R = 0}
                SPEED = 0
                BG:Destroy()
                BV:Destroy()
                if character:FindFirstChild("Humanoid") then
                    character.Humanoid.PlatformStand = false
                end
            end)

            local keyDownConn
            local keyUpConn
            keyDownConn = Mouse.KeyDown:Connect(function(KEY)
                if KEY:lower() == 'w' then CONTROL.F = speedfly
                elseif KEY:lower() == 's' then CONTROL.B = -speedfly
                elseif KEY:lower() == 'a' then CONTROL.L = -speedfly
                elseif KEY:lower() == 'd' then CONTROL.R = speedfly
                end
            end)
            keyUpConn = Mouse.KeyUp:Connect(function(KEY)
                if KEY:lower() == 'w' then CONTROL.F = 0
                elseif KEY:lower() == 's' then CONTROL.B = 0
                elseif KEY:lower() == 'a' then CONTROL.L = 0
                elseif KEY:lower() == 'd' then CONTROL.R = 0
                end
            end)

            while flying do task.wait() end
            keyDownConn:Disconnect()
            keyUpConn:Disconnect()
        else
            flying = false
        end
    end
})

local OtherSection = MovementTab:AddSection("Other")

OtherSection:AddButton({
    Name = "Infinite Jump",
    Callback = function()
        local JumpConn
        JumpConn = UIS.JumpRequest:Connect(function()
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid:ChangeState("Jumping")
            end
        end)
        WindUI:Notification("Infinite Jump Activated", "Hold space to jump infinitely", 3)
    end
})

OtherSection:AddToggle({
    Name = "NoClip",
    Default = false,
    Callback = function(Value)
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = not Value
                end
            end
        end
    end
})

OtherSection:AddButton({
    Name = "Grab Gun",
    Callback = function()
        if character and character:FindFirstChild("HumanoidRootPart") then
            local root = character.HumanoidRootPart
            local pos = root.CFrame
            if workspace:FindFirstChild("GunDrop") then
                root.CFrame = workspace.GunDrop.CFrame
                task.wait(0.25)
                root.CFrame = pos
                WindUI:Notification("Success", "Teleported to gun drop", 3)
            else
                WindUI:Notification("Sheriff Not Dead", "Wait until the sheriff dies and drops the gun", 5)
            end
        end
    end
})

-- ============================================
-- RENDER TAB
-- ============================================
local ESPSection = RenderTab:AddSection("ESP")

ESPSection:AddToggle({
    Name = "Murderer ESP",
    Default = false,
    Callback = function(Value)
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= player and v.Character then
                local backpack = v.Character:FindFirstChild("Backpack") or v:FindFirstChild("Backpack")
                if backpack and backpack:FindFirstChild("Knife") then
                    local ESP = v.Character:FindFirstChild("ESP") or v:FindFirstChild("ESP")
                    if not ESP and Value then
                        ESP = Instance.new("Highlight")
                        ESP.Name = "ESP"
                        ESP.Parent = v.Character
                        ESP.FillColor = Color3.fromRGB(255, 0, 0)
                        ESP.OutlineColor = Color3.fromRGB(255, 255, 255)
                        ESP.FillTransparency = 0.3
                        ESP.OutlineTransparency = 0
                    end
                    if ESP then
                        ESP.Enabled = Value
                    end
                end
            end
        end
    end
})

ESPSection:AddToggle({
    Name = "Sheriff ESP",
    Default = false,
    Callback = function(Value)
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= player and v.Character then
                local backpack = v.Character:FindFirstChild("Backpack") or v:FindFirstChild("Backpack")
                if backpack and backpack:FindFirstChild("Gun") then
                    local ESP = v.Character:FindFirstChild("ESP") or v:FindFirstChild("ESP")
                    if not ESP and Value then
                        ESP = Instance.new("Highlight")
                        ESP.Name = "ESP"
                        ESP.Parent = v.Character
                        ESP.FillColor = Color3.fromRGB(0, 0, 255)
                        ESP.OutlineColor = Color3.fromRGB(255, 255, 255)
                        ESP.FillTransparency = 0.3
                        ESP.OutlineTransparency = 0
                    end
                    if ESP then
                        ESP.Enabled = Value
                    end
                end
            end
        end
    end
})

local NamesSection = RenderTab:AddSection("Names")

NamesSection:AddToggle({
    Name = "Show Names",
    Default = false,
    Callback = function(Value)
        game.StarterPlayer.NameDisplayDistance = Value and 100 or 0
    end
})

-- ============================================
-- MURDERER TAB
-- ============================================
local MurderSection = MurdererTab:AddSection("Murderer")

MurderSection:AddButton({
    Name = "Kill All",
    Callback = function()
        local backpack = player:FindFirstChild("Backpack") or (character and character:FindFirstChild("Backpack"))
        if backpack and backpack:FindFirstChild("Knife") then
            for _, Victim in pairs(Players:GetPlayers()) do
                if Victim ~= player and Victim.Character and Victim.Character:FindFirstChild("HumanoidRootPart") then
                    repeat task.wait()
                        if character and character:FindFirstChild("HumanoidRootPart") and Victim.Character and Victim.Character:FindFirstChild("HumanoidRootPart") then
                            character.HumanoidRootPart.CFrame = Victim.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)
                        end
                    until not Victim.Character or not Victim.Character:FindFirstChild("Humanoid") or Victim.Character.Humanoid.Health == 0
                end
            end
            WindUI:Notification("Done", "Killed all players", 3)
        else
            WindUI:Notification("Not Murderer", "You need to be the murderer to use this", 5)
        end
    end
})

-- ============================================
-- TELEPORT TAB
-- ============================================
local TeleportSection = TeleportTab:AddSection("Teleports")

TeleportSection:AddButton({
    Name = "Teleport to Lobby",
    Callback = function()
        if character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = CFrame.new(-108.5, 145, 0.6)
        end
    end
})

TeleportSection:AddButton({
    Name = "Teleport to Map",
    Callback = function()
        if character and character:FindFirstChild("HumanoidRootPart") then
            for _, v in pairs(workspace:GetChildren()) do
                if v:FindFirstChild("Spawns") then
                    character.HumanoidRootPart.CFrame = v.Spawns.Spawn.CFrame
                    break
                end
            end
        end
    end
})

TeleportSection:AddButton({
    Name = "Teleport to Murderer",
    Callback = function()
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= player and v.Character then
                local backpack = v:FindFirstChild("Backpack") or v.Character:FindFirstChild("Backpack")
                if backpack and backpack:FindFirstChild("Knife") and v.Character:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
                    break
                end
            end
        end
    end
})

TeleportSection:AddButton({
    Name = "Teleport to Sheriff",
    Callback = function()
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= player and v.Character then
                local backpack = v:FindFirstChild("Backpack") or v.Character:FindFirstChild("Backpack")
                if backpack and backpack:FindFirstChild("Gun") and v.Character:FindFirstChild("HumanoidRootPart") then
                    character.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame
                    break
                end
            end
        end
    end
})

local TPPlayerSection = TeleportTab:AddSection("Player Teleport")

local selectedPlayer
local dropdown = TPPlayerSection:AddDropdown({
    Name = "Select Player",
    Options = {},
    Callback = function(Value)
        selectedPlayer = Value
        if selectedPlayer then
            local target = Players:FindFirstChild(selectedPlayer)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
            end
        end
    end
})

-- Actualizar lista de jugadores
task.spawn(function()
    while task.wait(3) do
        local playerList = {}
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= player then
                table.insert(playerList, plr.Name)
            end
        end
        dropdown:SetOptions(playerList)
    end
end})

-- ============================================
-- NOTIFICACIÓN DE CARGA
-- ============================================
WindUI:Notification("Water Hub", "MM2 script loaded successfully!", 5)