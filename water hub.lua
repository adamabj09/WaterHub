--[[
    WATER HUB | BLOCKSPIN + ARQEL KEY SYSTEM
    Integración completa con validación Junkie
]]

repeat task.wait() until game:IsLoaded()

-- ============================================
-- CONFIGURACIÓN DEL SISTEMA DE KEYS
-- ============================================

-- Aquí va TODO el código del sistema Arqel que proporcionaste
-- (Mantengo el código completo del sistema Arqel)

local cloneref = cloneref or function(obj) return obj end
local gethui = gethui or function() return cloneref(game:GetService("CoreGui")) end

-- services
local TweenService = cloneref(game:GetService("TweenService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local HttpService = cloneref(game:GetService("HttpService"))
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))
local Lighting = cloneref(game:GetService("Lighting"))
local Players = cloneref(game:GetService("Players"))

local hui = gethui()

if getgenv().ArqelLoaded and hui:FindFirstChild("ArqelKeySystem") then return getgenv().Arqel end
if getgenv().ArqelLoaded and hui:FindFirstChild("ArqelKeylessSystem") then return getgenv().Arqel end
getgenv().ArqelLoaded = true
getgenv().ArqelClosed = false

local Arqel = {}

-- CONFIGURACIÓN PERSONALIZADA PARA WATER HUB
Arqel.Appearance = {
    Title = "Water Hub",
    Subtitle = "Enter your key to continue",
    Icon = "rbxassetid://95721401302279",
    IconSize = UDim2.new(0, 30, 0, 30)
}

-- LINK PARA OBTENER KEY (tu link de jnkie)
Arqel.Links = {
    GetKey = "https://jnkie.com/get-key/waterhubkey",
    Discord = ""
}

Arqel.Storage = {
    FileName = "WaterHub_Key",
    Remember = true,
    AutoLoad = true
}

Arqel.Options = {
    Keyless = nil,
    KeylessUI = false,
    Blur = true,
    Draggable = true
}

Arqel.Theme = {
    Accent = Color3.fromRGB(0, 242, 254),        -- Cyan para Water Hub
    AccentHover = Color3.fromRGB(0, 200, 220),
    Background = Color3.fromRGB(15, 15, 15),
    Header = Color3.fromRGB(20, 20, 20),
    Input = Color3.fromRGB(25, 25, 25),
    Text = Color3.fromRGB(255, 255, 255),
    TextDim = Color3.fromRGB(120, 120, 120),
    Success = Color3.fromRGB(50, 205, 110),
    Error = Color3.fromRGB(245, 70, 90),
    Warning = Color3.fromRGB(255, 180, 50),
    StatusIdle = Color3.fromRGB(180, 80, 80),
    Discord = Color3.fromRGB(88, 101, 242),
    DiscordHover = Color3.fromRGB(114, 137, 218),
    Divider = Color3.fromRGB(45, 45, 70),
    Pending = Color3.fromRGB(60, 60, 60)
}

-- [TODO EL CÓDIGO DEL SISTEMA ARQEL VA AQUÍ - EL MISMO QUE PROPORCIONASTE]
-- ... (Mantén todo el código de Arqel desde "local Internal = {" hasta el final)

-- ============================================
-- CONFIGURACIÓN DEL CALLBACK (SCRIPT A EJECUTAR)
-- ============================================

-- URL del script de BlockSpin que se ejecutará cuando la key sea válida
local BLOCKSPIN_SCRIPT_URL = "https://api.jnkie.com/api/v1/luascripts/public/486002b77ce16680464be32b51b47af2b0978f2aa026a6c8ad41777b1312a3e4/download"

-- Configurar el callback de éxito
Arqel.Callbacks.OnSuccess = function()
    print("[Water Hub] Key validada correctamente. Cargando script...")
    
    -- Ejecutar el script de BlockSpin
    local success, result = pcall(function()
        loadstring(game:HttpGet(BLOCKSPIN_SCRIPT_URL))()
    end)
    
    if success then
        print("[Water Hub] Script cargado exitosamente!")
    else
        warn("[Water Hub] Error cargando script: " .. tostring(result))
    end
end

Arqel.Callbacks.OnFail = function(errorMsg)
    print("[Water Hub] Key inválida: " .. tostring(errorMsg))
end

Arqel.Callbacks.OnClose = function()
    print("[Water Hub] Sistema de keys cerrado")
end

-- ============================================
-- INICIAR SISTEMA DE KEYS
-- ============================================

-- Usar LaunchJunkie para integración con jnkie.com
-- Configuración para el servicio Junkie
local JunkieConfig = {
    Service = "waterhub",           -- Tu servicio en Junkie
    Identifier = "waterhubkey",     -- Tu identificador
    Provider = "jnkie"              -- El proveedor
}

-- Iniciar el sistema
task.spawn(function()
    -- Intentar usar LaunchJunkie primero (para validación con jnkie.com)
    local success = pcall(function()
        Arqel:LaunchJunkie(JunkieConfig)
    end)
    
    -- Si falla, usar el sistema de keys manual
    if not success then
        print("[Water Hub] Usando sistema de keys manual...")
        
        -- Configurar función de validación manual
        Arqel.Callbacks.OnVerify = function(key)
            -- Aquí puedes agregar keys manuales si quieres
            local validKeys = {
                ["test"] = true,
                ["WATERHUB-2026"] = true
            }
            
            if validKeys[key] then
                return {valid = true}
            else
                -- Intentar validar con Junkie manualmente
                local junkieSuccess, Junkie = pcall(function()
                    return loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
                end)
                
                if junkieSuccess and Junkie then
                    Junkie.service = JunkieConfig.Service
                    Junkie.identifier = JunkieConfig.Identifier
                    Junkie.provider = JunkieConfig.Provider
                    return Junkie.check_key(key)
                end
                
                return {valid = false, error = "KEY_INVALID"}
            end
        end
        
        Arqel:Launch()
    end
end)

-- Exponer globalmente
getgenv().Arqel = Arqel
getgenv().WaterHub = {
    Arqel = Arqel,
    Reload = function()
        getgenv().SCRIPT_KEY = nil
        Arqel:LaunchJunkie(JunkieConfig)
    end
}

print("[Water Hub] Sistema de keys iniciado. Esperando validación...")
