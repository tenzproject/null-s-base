local convarCache = {}

null.getConvarKey = function(key, ...)
    if convarCache[key] then
        return string.format(convarCache[key], ...)
    end
    local status, value = pcall(GetConvar, key, "")
    if status then
        if value and value ~= "" then
            convarCache[key] = string.format(value, ...)
            return convarCache[key]
        else
            return nil
        end
    else
        return nil
    end
end

null.setLoaderName = function(name)
    null.loader.resources[name] = {
        name = name,
        path = GetResourcePath(name),
        status = GetResourceState(name),
    }
end 

-- remove all function on a table (and sub value etc) 
null.cleanTable = function(table)
    local newTable = {}
    for k,v in pairs(table) do
        if type(v) == "function" then
            newTable[k] = nil
        elseif type(v) == "table" then
            newTable[k] = null.cleanTable(v)
        else
            newTable[k] = v
        end
    end
    return newTable
end

null.DebugPrint = function(...)
    local args = {...}
end

null.InitPrint = function(msg)
end

null.stopServer = function(after)
    Citizen.CreateThread(function()
        ESX.SavePlayers()
    end)

    Citizen.CreateThread(function()
        SaveAllSociety()
    end)

    Citizen.CreateThread(function()
        if disableCacheSave == false then 
            SaveData.functions.SaveAllCacheData()
        end
        for k,v in pairs(SaveData.json["illegals"]["laboratorys"]) do 
            if v.propsDry ~= nil then
                for k2,v2 in pairs(v.propsDry) do
                    DeleteEntity(v2)
                    v.propsDry[k2] = nil
                end
            end
            if v.cameraProps then 
                DeleteEntity(v.cameraProps)
                v.cameraProps = nil
            end
        end
    end)

    Citizen.CreateThread(function()
        for k,v in pairs(WorldProps.data.propsSpawned) do
            if v.entity ~= nil then
                DeleteEntity(v.entity)
            end
        end
    end)

    Citizen.CreateThread(function()
        for k,v in pairs(ChestLoad) do
            if v.entity ~= nil and v.entity ~= "in_spawning" then
                DeleteEntity(v.entity)
            end
        end
    end)

    Citizen.CreateThread(function()
        for k,v in pairs(SaveData.Illegal.WeedPlants) do 
            DeleteEntity(v.entity)
        end
    end)

    Citizen.CreateThread(function()
        for k,v in pairs(Config.Drugs.objSpawn) do
            DeleteObject(v)
            Config.Drugs.objSpawn[k] = nil
        end
    end)

    if after then
        after()
    end
end