null.getConvarKey = function(key, ...)
    local status, value = pcall(GetConvar, key, "")
    if status then
        if value and value ~= "" then
            return string.format(value, ...)
        else
            return nil
        end
    else
        return nil
    end
end

null.setLoaderName = function(name)
    null.loader.resources[name] = {
        name = name
    }
end 

null.quickHash = function(str)
    local hash = 0
    for i = 1, #str do
        hash = (hash * 31 + str:byte(i)) % 2^32
    end
    return hash
end

local printCache = {}

null.DebugPrint = function(...)
    local args = {...}
    local formatArgs = args
    for k,v in pairs(formatArgs) do 
        if type(v) == "table" then
            formatArgs[k] = json.encode(v)
        elseif type(v) == "boolean" then
            formatArgs[k] = v and "true" or "false"
        elseif type(v) == "number" then
            formatArgs[k] = tostring(v)
        end
    end
    local hash = null.quickHash(table.concat(formatArgs, " "))

    if printCache[hash] ~= nil and (GetGameTimer() - printCache[hash] < 5000) then
        return
    elseif printCache[hash] ~= nil then
        table.insert(args, "(timeout 5000ms)")
    end
    
    printCache[hash] = GetGameTimer()

end

null.InitPrint = function(msg)
end

DisplayHud = false
local LastRequest = nil

--[[
exemple :
1.
null.DisplayHud(true, 999)

2.
null.DisplayHud("always-display", true)
null.DisplayHud("additional-display", false)
null.DisplayHud("3dinteractions", false)
]]

--[[
priority : 

Options Affichage (Activer/Désactiver l'HUD) : 54

Creator : 978

Default : 1
]]

null.DisplayHud = function(first, second, third)
    if type(first) == "boolean" then
        -- Priority handling:
        --  - second = priorité du caller (défaut 1 si non fourni)
        --  - LastRequest = priorité du dernier verrou actif
        -- Un appel SANS priorité explicite est traité comme priorité 1, et ne peut
        -- donc PAS écraser un verrou plus élevé (ex: DisplayHud(true, 999)).
        local callerPriority = tonumber(second) or 1
        if LastRequest == nil then LastRequest = 1 end
        if callerPriority < LastRequest then
            return
        end
        LastRequest = callerPriority

        DisplayHud = first
        for k,v in pairs(Config.Hud) do
            if v ~= true then goto continue end
            if GetResourceState(k) ~= "started" then goto continue end

            if Config.HudExports[k] then
                local success, error = pcall(function()
                    Config.HudExports[k](first)
                end)
                if devmode and not success then
                    print("Error in " .. k .. ": " .. error)
                end
            end

            ::continue::
        end
    
        pcall(function()
            exports["null-core"]:setChatCanOpen(first)
        end)

        if Config.HudExports["More"] ~= nil and type(Config.HudExports["More"]) == "function" then
            Config.HudExports["More"](first)
        end
    elseif type(first) == "string" then
        if Config.HudConfig[first] then
            for k,v in pairs(Config.HudConfig[first]) do
                if v.enabled == true and GetResourceState(k) == "started" then
                    v.functions(second)
                end
            end
        end
    end
end

exports("DisplayHud", null.DisplayHud)
exports("isDisplayHud", function() return DisplayHud end)

local ActiveFrontEnd = false
null.ActiveFrontend = function(bool)
    ActiveFrontEnd = bool
    if bool then
        ActivateFrontendMenu(GetHashKey("FE_MENU_VERSION_EMPTY"), false, -1)
    else
        SetFrontendActive(false)
    end
end
exports("ActiveFrontend", null.ActiveFrontend)
exports("isActiveFrontEnd", function() return ActiveFrontEnd end)