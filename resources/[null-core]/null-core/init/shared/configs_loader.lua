--[[
    Null Core - Configs Loader
    Ce fichier est chargé par les ressources externes pour avoir accès aux configs
    Il récupère les globals depuis null-core via exports
]]

local resourceName = GetCurrentResourceName()
local resourceName2 = GetInvokingResource()
if resourceName == "null-core" then
    -- Dans null-core : créer les exports pour partager les globals
    exports("GetConfig", function()
        return Config
    end)
    
    exports("GetNull", function()
        if null == nil then
            while null == nil do
                Wait(100)
            end
        end
        return null
    end)
    
    exports("GetESX", function()
        if ESX == nil then
            while ESX == nil do
                Wait(100)
            end
        end
        return ESX
    end)

    -- Exports NullUI/RageUI (client uniquement)
    if not IsDuplicityVersion() then
        exports("GetNullUI", function()
            return NullUI
        end)
        
        exports("GetRageUI", function()
            return RageUI or NullUI
        end)
        
        -- Alias pour compatibilité
        exports("GetRMenu", function()
            return RMenu
        end)
    end
    
    if null and null.InitPrint then
        null.InitPrint("^2Configs loader initialized")
    end
else
    while true do 
        local success, error = pcall(function()
            Config = exports["null-core"]:GetConfig()
            null = exports["null-core"]:GetNull()
            ESX = exports["null-core"]:GetESX()
        end)
        if success then
            break
        end
        Wait(100)
    end
    
    if IsDuplicityVersion() then 
        if string.find(resourceName, "null-") then
            local isAllowed = false
            while null == nil or null.auth == nil do
                Wait(100)
            end

            if null.auth.resources == nil then
                isAllowed = true
            else
                for _, allowedResource in ipairs(null.auth.resources) do
                    if allowedResource == resourceName then
                        isAllowed = true
                        break
                    end
                end
            end
            
            if not isAllowed then
                print("^1[Null Auth] Ressource non autorisée: " .. resourceName)
                print("^1[Null Auth] Arrêt de la ressource...")
                BaseStopResource(resourceName, "Ressource non autorisée")
                null = nil
                Config = nil
                return
            end
        end
    end
    
    if not IsDuplicityVersion() then
        local rageUIExport = exports["null-core"]:GetRageUI()
        if rageUIExport then
            RageUI = rageUIExport
        end
        
        local rmenuExport = exports["null-core"]:GetRMenu()
        if rmenuExport then
            RMenu = rmenuExport
        end
    end

    if null.setLoaderName then 
        null.setLoaderName(resourceName)
    end

    --null.InitPrint("^2Configs chargées depuis null-core", resourceName)
end