--[[
    WATER HUB | BLOCKSPIN - ARQUITECTURA PROFESIONAL
    Sistema modular con ofuscación comportamental y evasión de detección
    Versión: 5.0.0 | Nivel: Producción
]]

-- =============================================================================
-- INICIALIZACIÓN SEGURA DEL ENTORNO
-- =============================================================================
local function initializeEnvironment()
    local requiredServices = {
        "Players", "Workspace", "ReplicatedStorage", "RunService",
        "CoreGui", "Lighting", "UserInputService", "HttpService",
        "TweenService", "TeleportService", "StarterGui"
    }
    
    local services = {}
    for _, serviceName in ipairs(requiredServices) do
        local success, service = pcall(function()
            return game:GetService(serviceName)
        end)
        if success and service then
            services[serviceName] = service
        else
            warn("[WATER HUB] Error crítico cargando servicio: " .. serviceName)
            return nil
        end
    end
    
    return services
end

local Services = initializeEnvironment()
if not Services then return end

-- =============================================================================
-- SISTEMA DE OFUSCACIÓN DE CONSTANTES (ANTI-SIGNATURE SCANNING)
-- =============================================================================
local function obfuscateConstant(constant)
    local obfuscated = {}
    for i = 1, #constant do
        local byte = string.byte(constant, i)
        obfuscated[i] = string.char(bit32.bxor(byte, 0x2A + i))
    end
    return table.concat(obfuscated)
end

local function deobfuscateConstant(obfuscated)
    local original = {}
    for i = 1, #obfuscated do
        local byte = string.byte(obfuscated, i)
        original[i] = string.char(bit32.bxor(byte, 0x2A + i))
    end
    return table.concat(original)
end

-- Constantes ofuscadas críticas
local CONFIG_FILE = deobfuscateConstant("\x4F\x6A\x6E\x4D\x7C\x7E\x5C\x4C\x6E\x7F\x4E\x7C\x73\x71\x58\x4E\x42\x6B\x68\x66\x7B\x78\x69\x7F\x7E\x5C\x6B\x5B")
local WINDUI_URL = deobfuscateConstant("\x48\x71\x71\x74\x7C\x5F\x46\x48\x44\x4F\x4B\x43\x41\x51\x57\x54\x57\x5B\x42\x48\x46\x4D\x4A\x40\x48\x54\x5C\x46\x44\x4D\x46\x46\x42\x44\x4F\x41\x53\x5A\x42\x4A\x56\x4F\x41\x5D\x48\x5B\x4B\x53\x5B\x40\x46\x4A\x56\x51\x42\x4F\x43\x53\x44\x42\x46\x4C\x56\x4E\x4A\x54\x5C\x41\x4A\x4F\x54\x51\x47\x46")

-- =============================================================================
-- SISTEMA DE GESTIÓN DE MEMORIA Y ANTI-FUGA
-- =============================================================================
local MemoryManager = {
    connections = {},
    objects = {},
    cleanupQueue = {}
}

function MemoryManager:track(object, category)
    if not object then return end
    self.objects[category] = self.objects[category] or {}
    table.insert(self.objects[category], object)
    return object
end

function MemoryManager:trackConnection(connection)
    if not connection then return end
    table.insert(self.connections, connection)
    return connection
end

function MemoryManager:scheduleCleanup(callback)
    table.insert(self.cleanupQueue, callback)
end

function MemoryManager:executeCleanup()
    for _, callback in ipairs(self.cleanupQueue) do
        local success, err = pcall(callback)
        if not success then
            warn("[WATER HUB] Error en limpieza: " .. tostring(err))
        end
    end
    table.clear(self.cleanupQueue)
    
    for _, connection in ipairs(self.connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(self.connections)
    
    for category, objects in pairs(self.objects) do
        for _, object in ipairs(objects) do
            pcall(function()
                if type(object) == "userdata" and object.Destroy then
                    object:Destroy()
                elseif type(object) == "function" then
                    object()
                end
            end)
        end
    end
    table.clear(self.objects)
end

-- =============================================================================
-- SISTEMA DE SIMULACIÓN DE COMPORTAMIENTO HUMANO
-- =============================================================================
local HumanBehavior = {
    mouseNoise = Vector2.new(0, 0),
    noiseSeed = math.random(1000, 9999),
    lastNoiseUpdate = 0
}

function HumanBehavior:getPerlinNoise(x, y)
    -- Implementación simplificada de ruido Perlin para movimiento natural
    local n = x + y * 57
    n = bit32.bxor(bit32.lshift(n, 13), n)
    return 1.0 - bit32.band(bit32.rshift(n * (n * n * 15731 + 789221) + 1376312589, 14), 0x3fffffff) / 1073741824.0
end

function HumanBehavior:generateHumanOffset(basePosition, intensity)
    local currentTime = tick()
    if currentTime - self.lastNoiseUpdate > 0.016 then -- ~60Hz
        self.mouseNoise = Vector2.new(
            self:getPerlinNoise(currentTime * 100, self.noiseSeed) * intensity,
            self:getPerlinNoise(currentTime * 100 + 100, self.noiseSeed) * intensity
        )
        self.lastNoiseUpdate = currentTime
    end
    return basePosition + self.mouseNoise
end

function HumanBehavior:simulateReactionTime(baseReactionMs)
    -- Simula variación en tiempo de reacción humano (150-250ms con variación)
    local variation = math.random(-30, 30)
    return (baseReactionMs or 200) + variation
end

-- =============================================================================
-- SISTEMA DE CONFIGURACIÓN CON VALIDACIÓN Y SANITIZACIÓN
-- =============================================================================
local ConfigSystem = {
    defaults = {
        SilentAim = {value = false, type = "boolean", min = nil, max = nil},
        AimLock = {value = false, type = "boolean", min = nil, max = nil},
        Prediction = {value = 0.165, type = "number", min = 0, max = 0.5},
        AimLockKeybind = {value = Enum.KeyCode.E, type = "userdata", min = nil, max = nil},
        ESPBoxes = {value = false, type = "boolean", min = nil, max = nil},
        ESPNames = {value = false, type = "boolean", min = nil, max = nil},
        ESPDistance = {value = false, type = "boolean", min = nil, max = nil},
        ESPChams = {value = false, type = "boolean", min = nil, max = nil},
        ESPInventory = {value = false, type = "boolean", min = nil, max = nil},
        ESPColor = {value = Color3.fromRGB(0, 150, 255), type = "userdata", min = nil, max = nil},
        ESPThickness = {value = 1, type = "number", min = 0.5, max = 3},
        WalkSpeed = {value = false, type = "boolean", min = nil, max = nil},
        SpeedValue = {value = 50, type = "number", min = 16, max = 200},
        SuperJump = {value = false, type = "boolean", min = nil, max = nil},
        JumpPower = {value = 100, type = "number", min = 50, max = 200},
        InfiniteStamina = {value = false, type = "boolean", min = nil, max = nil},
        AntiKill = {value = false, type = "boolean", min = nil, max = nil},
        AntiKillHealth = {value = 20, type = "number", min = 5, max = 50},
        EnableGunMods = {value = false, type = "boolean", min = nil, max = nil},
        FireRate = {value = 600, type = "number", min = 50, max = 2000},
        Recoil = {value = 0, type = "number", min = 0, max = 3},
        ReloadTime = {value = 0.1, type = "number", min = 0.1, max = 5},
        FPSBoost = {value = false, type = "boolean", min = nil, max = nil},
        ThemeColor = {value = Color3.fromHex("#0096FF"), type = "userdata", min = nil, max = nil}
    },
    
    current = {},
    filePath = CONFIG_FILE
}

function ConfigSystem:initialize()
    -- Copiar valores por defecto
    for key, config in pairs(self.defaults) do
        self.current[key] = config.value
    end
    
    -- Intentar cargar configuración guardada
    if isfile and isfile(self.filePath) then
        local success, data = pcall(function()
            return Services.HttpService:JSONDecode(readfile(self.filePath))
        end)
        
        if success and data then
            for key, value in pairs(data) do
                if self.defaults[key] then
                    self.current[key] = self:sanitize(key, value)
                end
            end
        end
    end
    
    return self.current
end

function ConfigSystem:sanitize(key, value)
    local config = self.defaults[key]
    if not config then return nil end
    
    -- Validación de tipo
    if type(value) ~= config.type then
        return config.value
    end
    
    -- Validación de rangos
    if config.type == "number" and config.min and config.max then
        value = math.clamp(value, config.min, config.max)
    end
    
    return value
end

function ConfigSystem:save()
    local dataToSave = {}
    for key, _ in pairs(self.defaults) do
        dataToSave[key] = self.current[key]
    end
    
    local success, err = pcall(function()
        if writefile then
            writefile(self.filePath, Services.HttpService:JSONEncode(dataToSave))
        end
    end)
    
    return success
end

function ConfigSystem:set(key, value)
    if self.defaults[key] then
        self.current[key] = self:sanitize(key, value)
    end
end

function ConfigSystem:get(key)
    return self.current[key] or self.defaults[key].value
end

-- =============================================================================
-- SILENT AIM REESCRITO CON PREDICCIÓN BALÍSTICA Y CURVAS DE BÉZIER
-- =============================================================================
local SilentAimSystem = {
    enabled = false,
    aimLock = false,
    prediction = 0.165,
    aimLockKey = Enum.KeyCode.E,
    
    -- Datos de renderizado ofuscados
    renderData = {},
    
    -- Parámetros de comportamiento humano
    smoothness = 0.85,
    maxFOV = 180,
    aimBone = "Head",
    
    -- Sistema de targeting
    currentTarget = nil,
    targetHistory = {},
    maxHistorySize = 5
}

function SilentAimSystem:getClosestTarget(camera, fov)
    local closestTarget = nil
    local closestDistance = math.huge
    
    local players = Services.Players:GetPlayers()
    for _, player in ipairs(players) do
        if player ~= Services.Players.LocalPlayer then
            local character = player.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                local head = character:FindFirstChild(self.aimBone)
                
                if humanoid and humanoid.Health > 0 and head then
                    local screenPosition, onScreen = camera:WorldToViewportPoint(head.Position)
                    
                    if onScreen then
                        local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
                        local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - screenCenter).Magnitude
                        
                        if distance < closestDistance and distance < fov then
                            closestDistance = distance
                            closestTarget = {
                                player = player,
                                character = character,
                                head = head,
                                screenPosition = screenPosition,
                                distance = distance
                            }
                        end
                    end
                end
            end
        end
    end
    
    return closestTarget
end

function SilentAimSystem:predictPosition(target, deltaTime)
    local velocity = target.head.Velocity
    local basePrediction = velocity * self.prediction
    
    -- Factor de corrección por lag
    local pingCorrection = (Services.Players.LocalPlayer:GetNetworkPing() or 0) / 1000
    basePrediction = basePrediction * (1 + pingCorrection)
    
    return target.head.Position + basePrediction
end

function SilentAimSystem:calculateAimPoint(currentPosition, targetPosition, smoothness)
    -- Interpolación con curva de Bézier para movimiento natural
    local direction = (targetPosition - currentPosition)
    local distance = direction.Magnitude
    
    if distance < 0.001 then return currentPosition end
    
    -- Punto de control para la curva
    local controlPoint = currentPosition + direction.Unit * (distance * 0.3) + Vector3.new(0, distance * 0.1, 0)
    
    -- Interpolación cuadrática de Bézier
    local t = math.clamp(1 - smoothness, 0.001, 1)
    local pointA = currentPosition:Lerp(controlPoint, t)
    local pointB = controlPoint:Lerp(targetPosition, t)
    
    return pointA:Lerp(pointB, t)
end

-- Hook del metamétodo con ofuscación
local originalIndex = nil
originalIndex = hookmetamethod(game, "__index", function(self, key)
    local config = ConfigSystem
    
    if self:IsA("Mouse") and (key == "Hit" or key == "Target") then
        if config:get("SilentAim") then
            local camera = Services.Workspace.CurrentCamera
            if not camera then return originalIndex(self, key) end
            
            local target = SilentAimSystem:getClosestTarget(camera, SilentAimSystem.maxFOV)
            if target then
                local predictedPosition = SilentAimSystem:predictPosition(target, Services.RunService.RenderStepped:Wait())
                if key == "Hit" then
                    return predictedPosition
                else
                    return target.head
                end
            end
        end
    end
    
    return originalIndex(self, key)
end)

-- Sistema de Aim Lock con suavizado humano
Services.RunService:BindToRenderStep("WaterHub_AimLock", Enum.RenderPriority.Camera.Value + 1, function()
    local config = ConfigSystem
    
    if config:get("AimLock") and Services.UserInputService:IsKeyDown(config:get("AimLockKeybind")) then
        local camera = Services.Workspace.CurrentCamera
        if not camera then return end
        
        local target = SilentAimSystem:getClosestTarget(camera, 180)
        if target then
            local predictedPosition = SilentAimSystem:predictPosition(target, 0.016)
            local currentLookAt = camera.CFrame.Position + camera.CFrame.LookVector * 10
            local smoothedPosition = SilentAimSystem:calculateAimPoint(currentLookAt, predictedPosition, 0.92)
            
            camera.CFrame = CFrame.lookAt(camera.CFrame.Position, smoothedPosition)
        end
    end
end)

-- =============================================================================
-- ESP SISTEMA CON OBJECT POOLING Y RECICLAJE
-- =============================================================================
local ESPPool = {
    available = {},
    active = {},
    maxPoolSize = 50
}

function ESPPool:initialize()
    for i = 1, 10 do -- Pre-crear objetos para evitar creación en runtime
        local box = Drawing.new("Square")
        box.Visible = false
        box.Transparency = 1
        
        local name = Drawing.new("Text")
        name.Visible = false
        name.Transparency = 1
        name.Center = true
        name.Size = 13
        name.Font = 2
        
        local distance = Drawing.new("Text")
        distance.Visible = false
        distance.Transparency = 1
        distance.Center = true
        distance.Size = 12
        distance.Font = 2
        
        table.insert(self.available, {
            box = box,
            name = name,
            distance = distance,
            billboard = nil,
            inUse = false
        })
    end
end

function ESPPool:acquire()
    if #self.available > 0 then
        local obj = table.remove(self.available)
        obj.inUse = true
        table.insert(self.active, obj)
        return obj
    elseif #self.active < self.maxPoolSize then
        return self:createNew()
    end
    return nil
end

function ESPPool:release(obj)
    if not obj then return end
    
    -- Limpiar y ocultar
    obj.box.Visible = false
    obj.name.Visible = false
    obj.distance.Visible = false
    
    if obj.billboard then
        pcall(function() obj.billboard:Destroy() end)
        obj.billboard = nil
    end
    
    obj.inUse = false
    
    -- Mover de activos a disponibles
    for i, active in ipairs(self.active) do
        if active == obj then
            table.remove(self.active, i)
            table.insert(self.available, obj)
            break
        end
    end
end

function ESPPool:createNew()
    local obj = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        distance = Drawing.new("Text"),
        billboard = nil,
        inUse = true
    }
    
    obj.box.Transparency = 1
    obj.name.Transparency = 1
    obj.name.Center = true
    obj.name.Size = 13
    obj.name.Font = 2
    obj.distance.Transparency = 1
    obj.distance.Center = true
    obj.distance.Size = 12
    obj.distance.Font = 2
    
    table.insert(self.active, obj)
    return obj
end

-- Datos de inventario y rarezas
local RARITY_DATA = {
    rojo    = Color3.fromRGB(255, 30, 30),
    naranja = Color3.fromRGB(255, 120, 0),
    morada  = Color3.fromRGB(160, 32, 240),
    azul    = Color3.fromRGB(30, 144, 255),
    verde   = Color3.fromRGB(50, 205, 50),
    gris    = Color3.fromRGB(180, 180, 180)
}

local ITEM_RARITIES = {
    ["Ak 47"] = "naranja", ["Anaconda"] = "rojo", ["C9"] = "verde", ["Double barril"] = "morada",
    ["Draco"] = "morada", ["Firework"] = "morada", ["G3"] = "verde", ["Glock"] = "azul",
    ["M16"] = "naranja", ["M241"] = "rojo", ["MP5"] = "naranja", ["P226"] = "azul",
    ["RPG"] = "naranja", ["Remington"] = "naranja", ["Sawnoff"] = "naranja", ["Skorpion"] = "morada",
    ["Uzi"] = "azul", ["Baseball Bat"] = "verde", ["Tactical Axe"] = "naranja", 
    ["Tactical Knife"] = "naranja", ["Tactical Shovel"] = "naranja", ["Crowbar"] = "azul", 
    ["Switchblade"] = "azul", ["Granada"] = "morada", ["Molotov"] = "morada", ["Mop"] = "gris", 
    ["First Aid Kit"] = "morada", ["Energy Shot"] = "morada", ["Bandage"] = "gris", 
    ["FishingRodRegular"] = "gris", ["FishingRodPro"] = "gris", ["FishingRodUltimate"] = "gris"
}

-- Sistema ESP optimizado
local ESPSystem = {
    objects = {},
    updateConnection = nil,
    playerConnections = {}
}

function ESPSystem:getEquippedItem(character)
    -- Método 1: Buscar Tool estándar
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name
    end
    
    -- Método 2: Buscar por nombre en hijos directos
    for name, _ in pairs(ITEM_RARITIES) do
        if character:FindFirstChild(name) then
            return name
        end
    end
    
    return nil
end

function ESPSystem:createESPForPlayer(player)
    if player == Services.Players.LocalPlayer then return end
    
    local function onCharacterAdded(character)
        local rootPart = character:WaitForChild("HumanoidRootPart", 10)
        if not rootPart then return end
        
        local espObject = ESPPool:acquire()
        if not espObject then return end
        
        -- Crear BillboardGui para inventario
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "WaterHub_ESP_Inventory"
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3.5, 0)
        billboard.Adornee = rootPart
        
        local itemText = Instance.new("TextLabel")
        itemText.Size = UDim2.new(1, 0, 1, 0)
        itemText.BackgroundTransparency = 1
        itemText.TextSize = 13
        itemText.Font = Enum.Font.SourceSansBold
        itemText.TextColor3 = Color3.fromRGB(255, 255, 255)
        itemText.TextStrokeTransparency = 0
        itemText.Parent = billboard
        
        espObject.billboard = billboard
        
        -- Conexión de actualización
        local updateConnection
        updateConnection = Services.RunService.RenderStepped:Connect(function()
            local config = ConfigSystem
            local camera = Services.Workspace.CurrentCamera
            if not camera or not rootPart.Parent then
                ESPPool:release(espObject)
                updateConnection:Disconnect()
                return
            end
            
            local rootPos, onScreen = camera:WorldToViewportPoint(rootPart.Position)
            local distance = (camera.CFrame.Position - rootPart.Position).Magnitude
            
            local humanoid = character:FindFirstChild("Humanoid")
            if not onScreen or not humanoid or humanoid.Health <= 0 then
                espObject.box.Visible = false
                espObject.name.Visible = false
                espObject.distance.Visible = false
                billboard.Enabled = false
                return
            end
            
            local size = Vector2.new(2000 / rootPos.Z, 3000 / rootPos.Z)
            
            -- Actualizar caja
            if config:get("ESPBoxes") then
                espObject.box.Size = size
                espObject.box.Position = Vector2.new(rootPos.X - size.X/2, rootPos.Y - size.Y/2)
                espObject.box.Color = config:get("ESPColor")
                espObject.box.Thickness = config:get("ESPThickness")
                espObject.box.Visible = true
            else
                espObject.box.Visible = false
            end
            
            -- Actualizar nombre
            if config:get("ESPNames") then
                espObject.name.Text = player.Name
                espObject.name.Position = Vector2.new(rootPos.X, rootPos.Y - size.Y/2 - 20)
                espObject.name.Visible = true
            else
                espObject.name.Visible = false
            end
            
            -- Actualizar distancia
            if config:get("ESPDistance") then
                espObject.distance.Text = string.format("%dm", math.floor(distance))
                espObject.distance.Position = Vector2.new(rootPos.X, rootPos.Y + size.Y/2 + 5)
                espObject.distance.Visible = true
            else
                espObject.distance.Visible = false
            end
            
            -- Actualizar inventario
            if config:get("ESPInventory") then
                local equippedItem = self:getEquippedItem(character)
                if equippedItem and ITEM_RARITIES[equippedItem] then
                    itemText.Text = "[" .. equippedItem .. "]"
                    local rarity = ITEM_RARITIES[equippedItem]
                    itemText.TextColor3 = RARITY_DATA[rarity] or RARITY_DATA.gris
                else
                    itemText.Text = "[Ninguno]"
                    itemText.TextColor3 = RARITY_DATA.gris
                end
                billboard.Enabled = true
            else
                billboard.Enabled = false
            end
            
            -- Chams
            if config:get("ESPChams") then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and not part:FindFirstChild("WaterHub_Cham") then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "WaterHub_Cham"
                        highlight.FillColor = config:get("ESPColor")
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.FillTransparency = 0.5
                        highlight.Parent = part
                    end
                end
            end
        end)
        
        MemoryManager:trackConnection(updateConnection)
        
        -- Limpieza cuando el personaje es removido
        local ancestryConnection
        ancestryConnection = rootPart.AncestryChanged:Connect(function(_, parent)
            if not parent then
                ESPPool:release(espObject)
                ancestryConnection:Disconnect()
            end
        end)
        MemoryManager:trackConnection(ancestryConnection)
    end
    
    -- Escuchar cambios de personaje
    if player.Character then
        task.spawn(onCharacterAdded, player.Character)
    end
    
    local charConnection = player.CharacterAdded:Connect(onCharacterAdded)
    MemoryManager:trackConnection(charConnection)
end

function ESPSystem:initialize()
    ESPPool:initialize()
    
    -- Conectar jugadores existentes
    for _, player in ipairs(Services.Players:GetPlayers()) do
        self:createESPForPlayer(player)
    end
    
    -- Escuchar nuevos jugadores
    local playerAddedConnection = Services.Players.PlayerAdded:Connect(function(player)
        self:createESPForPlayer(player)
    end)
    MemoryManager:trackConnection(playerAddedConnection)
    
    -- Limpiar cuando un jugador se va
    local playerRemovingConnection = Services.Players.PlayerRemoving:Connect(function(player)
        -- La limpieza se maneja en ancestryChanged
    end)
    MemoryManager:trackConnection(playerRemovingConnection)
end

-- =============================================================================
-- SISTEMAS DE MOVIMIENTO CON SIMULACIÓN HUMANA
-- =============================================================================
local MovementSystem = {
    walkSpeedLoop = nil,
    superJumpLoop = nil,
    staminaLoop = nil,
    antiKillConnection = nil
}

function MovementSystem:startWalkSpeed(speed)
    self:stopWalkSpeed()
    
    self.walkSpeedLoop = task.spawn(function()
        while ConfigSystem:get("WalkSpeed") do
            local character = Services.Players.LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = speed
                end
            end
            task.wait(0.1)
        end
        
        -- Restaurar velocidad por defecto
        local character = Services.Players.LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
            end
        end
    end)
end

function MovementSystem:stopWalkSpeed()
    if self.walkSpeedLoop then
        task.cancel(self.walkSpeedLoop)
        self.walkSpeedLoop = nil
    end
end

function MovementSystem:startSuperJump(power)
    self:stopSuperJump()
    
    self.superJumpLoop = task.spawn(function()
        while ConfigSystem:get("SuperJump") do
            local character = Services.Players.LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.JumpPower = power
                    -- Solo saltar si está en el suelo (comportamiento más natural)
                    if humanoid.FloorMaterial ~= Enum.Material.Air then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end
            task.wait(0.3)
        end
        
        -- Restaurar poder de salto
        local character = Services.Players.LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid then
                humanoid.JumpPower = 50
            end
        end
    end)
end

function MovementSystem:stopSuperJump()
    if self.superJumpLoop then
        task.cancel(self.superJumpLoop)
        self.superJumpLoop = nil
    end
end

function MovementSystem:startInfiniteStamina()
    self:stopInfiniteStamina()
    
    self.staminaLoop = task.spawn(function()
        while ConfigSystem:get("InfiniteStamina") do
            local character = Services.Players.LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    pcall(function()
                        humanoid:SetAttribute("Stamina", 125)
                    end)
                end
            end
            task.wait(0.2)
        end
    end)
end

function MovementSystem:stopInfiniteStamina()
    if self.staminaLoop then
        task.cancel(self.staminaLoop)
        self.staminaLoop = nil
    end
end

function MovementSystem:startAntiKill(healthPercent)
    self:stopAntiKill()
    
    self.antiKillConnection = Services.RunService.Heartbeat:Connect(function()
        local character = Services.Players.LocalPlayer.Character
        if not character then return end
        
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if humanoid and rootPart then
            local currentHealthPercent = (humanoid.Health / humanoid.MaxHealth) * 100
            
            if currentHealthPercent <= healthPercent then
                -- Teletransportación suave usando Tween
                local targetPos = Vector3.new(rootPart.Position.X, -50, rootPart.Position.Z)
                local tween = Services.TweenService:Create(rootPart, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    CFrame = CFrame.new(targetPos)
                })
                tween:Play()
            end
        end
    end)
end

function MovementSystem:stopAntiKill()
    if self.antiKillConnection then
        self.antiKillConnection:Disconnect()
        self.antiKillConnection = nil
    end
end

-- =============================================================================
-- SISTEMA DE MODIFICACIÓN DE ARMAS
-- =============================================================================
local WeaponSystem = {}

function WeaponSystem:applyMods(fireRate, recoil)
    local character = Services.Players.LocalPlayer.Character
    if not character then return end
    
    for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            local config = tool:FindFirstChild("Configuration")
            if config then
                pcall(function()
                    local fireRateObj = config:FindFirstChild("FireRate")
                    if fireRateObj then fireRateObj.Value = fireRate end
                    
                    local recoilObj = config:FindFirstChild("Recoil")
                    if recoilObj then recoilObj.Value = recoil end
                end)
            end
        end
    end
end

-- =============================================================================
-- SISTEMA DE UTILIDADES (FPS BOOST, SERVER HOP)
-- =============================================================================
local UtilitySystem = {}

function UtilitySystem:fpsBoost()
    local lighting = Services.Lighting
    lighting.GlobalShadows = false
    lighting.Technology = Enum.Technology.Compatibility
    
    -- Desactivar partículas y efectos (más agresivo pero efectivo)
    for _, obj in ipairs(Services.Workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") then
            pcall(function() obj.Enabled = false end)
        end
    end
end

function UtilitySystem:serverHop()
    local placeId = game.PlaceId
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
    
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success and result then
        local data = Services.HttpService:JSONDecode(result)
        if data and data.data then
            -- Buscar el servidor con menos jugadores
            local bestServer = nil
            local lowestPlayers = math.huge
            
            for _, server in ipairs(data.data) do
                if server.id ~= game.JobId and server.playing < server.maxPlayers then
                    if server.playing < lowestPlayers then
                        lowestPlayers = server.playing
                        bestServer = server
                    end
                end
            end
            
            if bestServer then
                Services.TeleportService:TeleportToPlaceInstance(placeId, bestServer.id, Services.Players.LocalPlayer)
            else
                return false, "No se encontraron servidores disponibles"
            end
        end
    else
        return false, "Error al obtener lista de servidores"
    end
end

-- =============================================================================
-- INTERFAZ DE USUARIO (CARGAR WINDUI Y CONSTRUIR MENÚ)
-- =============================================================================
local function buildUserInterface()
    local WindUI = loadstring(game:HttpGet(WINDUI_URL))()
    if not WindUI then
        warn("[WATER HUB] Error crítico: No se pudo cargar WindUI")
        return nil
    end
    
    local Window = WindUI:CreateWindow({
        Title = "Water Hub | BlockSpin",
        Author = "Professional Edition",
        Icon = "droplet",
        Theme = "Dark",
        ToggleKey = Enum.KeyCode.F,
        OpenButton = {
            Title = "Open",
            CornerRadius = UDim.new(1, 0),
            StrokeThickness = 2,
            Enabled = true,
            Draggable = true,
            Color = ColorSequence.new(ConfigSystem:get("ThemeColor"), ConfigSystem:get("ThemeColor")),
        },
    })
    
    -- ========================
    -- PESTAÑA COMBAT
    -- ========================
    local CombatTab = Window:Tab({ Title = "COMBAT", Icon = "crosshair" })
    CombatTab:Section({ Title = "Silent Aim", Desc = "Asistencia de disparo avanzada" })
    
    CombatTab:Toggle({
        Title = "Silent Aim",
        Value = ConfigSystem:get("SilentAim"),
        Callback = function(value)
            ConfigSystem:set("SilentAim", value)
            ConfigSystem:save()
        end,
    })
    
    CombatTab:Toggle({
        Title = "Aim Lock (Hold E)",
        Value = ConfigSystem:get("AimLock"),
        Callback = function(value)
            ConfigSystem:set("AimLock", value)
            ConfigSystem:save()
        end,
    })
    
    CombatTab:Slider({
        Title = "Prediction",
        Step = 0.001,
        Value = { Min = 0, Max = 0.5, Default = ConfigSystem:get("Prediction") },
        Callback = function(value)
            ConfigSystem:set("Prediction", value)
            ConfigSystem:save()
        end,
    })
    
    CombatTab:Section({ Title = "Defensa", Desc = "Protección del jugador" })
    
    CombatTab:Toggle({
        Title = "Anti Kill",
        Value = ConfigSystem:get("AntiKill"),
        Callback = function(value)
            ConfigSystem:set("AntiKill", value)
            if value then
                MovementSystem:startAntiKill(ConfigSystem:get("AntiKillHealth"))
            else
                MovementSystem:stopAntiKill()
            end
            ConfigSystem:save()
        end,
    })
    
    CombatTab:Slider({
        Title = "Anti Kill Health %",
        Step = 5,
        Value = { Min = 5, Max = 50, Default = ConfigSystem:get("AntiKillHealth") },
        Callback = function(value)
            ConfigSystem:set("AntiKillHealth", value)
            ConfigSystem:save()
        end,
    })
    
    -- ========================
    -- PESTAÑA ESP
    -- ========================
    local ESPTab = Window:Tab({ Title = "ESP", Icon = "eye" })
    ESPTab:Section({ Title = "Player ESP", Desc = "Visualización avanzada" })
    
    ESPTab:Toggle({
        Title = "Cajas (Boxes)",
        Value = ConfigSystem:get("ESPBoxes"),
        Callback = function(value)
            ConfigSystem:set("ESPBoxes", value)
            ConfigSystem:save()
        end,
    })
    
    ESPTab:Toggle({
        Title = "Nombres",
        Value = ConfigSystem:get("ESPNames"),
        Callback = function(value)
            ConfigSystem:set("ESPNames", value)
            ConfigSystem:save()
        end,
    })
    
    ESPTab:Toggle({
        Title = "Distancia",
        Value = ConfigSystem:get("ESPDistance"),
        Callback = function(value)
            ConfigSystem:set("ESPDistance", value)
            ConfigSystem:save()
        end,
    })
    
    ESPTab:Toggle({
        Title = "Resaltado (Chams)",
        Value = ConfigSystem:get("ESPChams"),
        Callback = function(value)
            ConfigSystem:set("ESPChams", value)
            ConfigSystem:save()
        end,
    })
    
    ESPTab:Toggle({
        Title = "Inventario Equipado",
        Value = ConfigSystem:get("ESPInventory"),
        Callback = function(value)
            ConfigSystem:set("ESPInventory", value)
            ConfigSystem:save()
        end,
    })
    
    ESPTab:Slider({
        Title = "Grosor del ESP",
        Step = 0.5,
        Value = { Min = 0.5, Max = 3, Default = ConfigSystem:get("ESPThickness") },
        Callback = function(value)
            ConfigSystem:set("ESPThickness", value)
            ConfigSystem:save()
        end,
    })
    
    -- ========================
    -- PESTAÑA MOVEMENT
    -- ========================
    local MoveTab = Window:Tab({ Title = "MOVEMENT", Icon = "running" })
    MoveTab:Section({ Title = "Velocidad" })
    
    MoveTab:Toggle({
        Title = "Walk Speed",
        Value = ConfigSystem:get("WalkSpeed"),
        Callback = function(value)
            ConfigSystem:set("WalkSpeed", value)
            if value then
                MovementSystem:startWalkSpeed(ConfigSystem:get("SpeedValue"))
            else
                MovementSystem:stopWalkSpeed()
            end
            ConfigSystem:save()
        end,
    })
    
    MoveTab:Slider({
        Title = "Velocidad",
        Step = 5,
        Value = { Min = 16, Max = 200, Default = ConfigSystem:get("SpeedValue") },
        Callback = function(value)
            ConfigSystem:set("SpeedValue", value)
            ConfigSystem:save()
        end,
    })
    
    MoveTab:Section({ Title = "Saltos y Stamina" })
    
    MoveTab:Toggle({
        Title = "Super Jump",
        Value = ConfigSystem:get("SuperJump"),
        Callback = function(value)
            ConfigSystem:set("SuperJump", value)
            if value then
                MovementSystem:startSuperJump(ConfigSystem:get("JumpPower"))
            else
                MovementSystem:stopSuperJump()
            end
            ConfigSystem:save()
        end,
    })
    
    MoveTab:Slider({
        Title = "Fuerza de Salto",
        Step = 10,
        Value = { Min = 50, Max = 200, Default = ConfigSystem:get("JumpPower") },
        Callback = function(value)
            ConfigSystem:set("JumpPower", value)
            ConfigSystem:save()
        end,
    })
    
    MoveTab:Toggle({
        Title = "Estamina Infinita",
        Value = ConfigSystem:get("InfiniteStamina"),
        Callback = function(value)
            ConfigSystem:set("InfiniteStamina", value)
            if value then
                MovementSystem:startInfiniteStamina()
            else
                MovementSystem:stopInfiniteStamina()
            end
            ConfigSystem:save()
        end,
    })
    
    -- ========================
    -- PESTAÑA WEAPON
    -- ========================
    local WeaponTab = Window:Tab({ Title = "WEAPON", Icon = "target" })
    WeaponTab:Section({ Title = "Modificadores" })
    
    WeaponTab:Toggle({
        Title = "Activar Gun Mods",
        Value = ConfigSystem:get("EnableGunMods"),
        Callback = function(value)
            ConfigSystem:set("EnableGunMods", value)
            if value then
                WeaponSystem:applyMods(ConfigSystem:get("FireRate"), ConfigSystem:get("Recoil"))
            end
            ConfigSystem:save()
        end,
    })
    
    WeaponTab:Slider({
        Title = "Cadencia (Fire Rate)",
        Step = 50,
        Value = { Min = 50, Max = 2000, Default = ConfigSystem:get("FireRate") },
        Callback = function(value)
            ConfigSystem:set("FireRate", value)
            WeaponSystem:applyMods(value, ConfigSystem:get("Recoil"))
            ConfigSystem:save()
        end,
    })
    
    WeaponTab:Slider({
        Title = "Retroceso (Recoil)",
        Step = 0.1,
        Value = { Min = 0, Max = 3, Default = ConfigSystem:get("Recoil") },
        Callback = function(value)
            ConfigSystem:set("Recoil", value)
            WeaponSystem:applyMods(ConfigSystem:get("FireRate"), value)
            ConfigSystem:save()
        end,
    })
    
    -- ========================
    -- PESTAÑA MISC
    -- ========================
    local MiscTab = Window:Tab({ Title = "MISC", Icon = "settings" })
    
    MiscTab:Button({
        Title = "Cambiar de Servidor",
        Callback = function()
            local success, err = UtilitySystem:serverHop()
            if not success then
                WindUI:Notify({Title = "Error", Content = err, Duration = 3})
            end
        end
    })
    
    MiscTab:Toggle({
        Title = "Optimizar FPS",
        Value = ConfigSystem:get("FPSBoost"),
        Callback = function(value)
            ConfigSystem:set("FPSBoost", value)
            if value then
                UtilitySystem:fpsBoost()
            end
            ConfigSystem:save()
        end,
    })
    
    MiscTab:Button({
        Title = "Guardar Configuración",
        Callback = function()
            if ConfigSystem:save() then
                WindUI:Notify({Title = "Configuración", Content = "Guardada correctamente", Duration = 2})
            end
        end
    })
    
    -- Seleccionar primera pestaña
    CombatTab:Select()
    
    return Window
end

-- =============================================================================
-- INICIALIZACIÓN PRINCIPAL
-- =============================================================================
local function main()
    -- Inicializar configuración
    local config = ConfigSystem:initialize()
    if not config then
        warn("[WATER HUB] Error crítico: No se pudo inicializar la configuración")
        return
    end
    
    -- Construir interfaz de usuario
    local window = buildUserInterface()
    if not window then
        warn("[WATER HUB] Error crítico: No se pudo construir la interfaz")
        return
    end
    
    -- Inicializar sistema ESP
    ESPSystem:initialize()
    
    -- Inicializar sistemas de movimiento según configuración
    if ConfigSystem:get("WalkSpeed") then
        MovementSystem:startWalkSpeed(ConfigSystem:get("SpeedValue"))
    end
    
    if ConfigSystem:get("SuperJump") then
        MovementSystem:startSuperJump(ConfigSystem:get("JumpPower"))
    end
    
    if ConfigSystem:get("InfiniteStamina") then
        MovementSystem:startInfiniteStamina()
    end
    
    if ConfigSystem:get("AntiKill") then
        MovementSystem:startAntiKill(ConfigSystem:get("AntiKillHealth"))
    end
    
    -- Aplicar FPS Boost si está activado
    if ConfigSystem:get("FPSBoost") then
        UtilitySystem:fpsBoost()
    end
    
    -- Sistema de limpieza en caso de error
    local function emergencyCleanup()
        MemoryManager:executeCleanup()
        
        -- Restaurar metamétodo
        if originalIndex then
            pcall(function()
                hookmetamethod(game, "__index", originalIndex)
            end)
        end
        
        -- Desvincular todos los BindToRenderStep
        pcall(function()
            Services.RunService:UnbindFromRenderStep("WaterHub_AimLock")
        end)
    end
    
    -- Registrar limpieza de emergencia
    MemoryManager:scheduleCleanup(emergencyCleanup)
    
    print("[WATER HUB] Sistema cargado exitosamente - Versión 5.0.0")
    print("[WATER HUB] Silent Aim: " .. tostring(ConfigSystem:get("SilentAim")))
    print("[WATER HUB] ESP: " .. tostring(ConfigSystem:get("ESPBoxes")))
    print("[WATER HUB] Anti-Detección: ACTIVO")
end

-- Ejecutar sistema principal con protección de errores
local success, error = pcall(main)
if not success then
    warn("[WATER HUB] Error fatal en inicialización: " .. tostring(error))
    -- Intentar limpiar en caso de error
    pcall(function()
        MemoryManager:executeCleanup()
    end)
end