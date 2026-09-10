while not _G.InventoryCacheLoaded do
    Wait(0)
end

local Storage = {}

local DEFAULT_INVENTORY = {
    cash = 0,
    dirtycash = 0,
    items = {},
    loadout = {},
    clothes = {},
}

local function GetCacheKey(invType, id)
    return ("%s_%s"):format(invType, tostring(id))
end

local function EnrichItems(items)
    local enriched = {}
    for k, v in pairs(items) do
        local itemData = ESX.Items[v.name]
        enriched[k] = {
            name = v.name,
            count = v.count or 1,
            weight = itemData and itemData.weight or 1,
            label = ESX.GetItemLabel(v.name) or v.label or v.name,
            unique = itemData and itemData.unique or v.unique or false,
            metadata = v.metadata or {},
            extra = v.extra,
        }
    end
    return enriched
end

local function EnrichLoadout(loadout)
    local enriched = {}
    for k, v in pairs(loadout) do
        enriched[k] = {
            name = v.name,
            label = ESX.GetWeaponLabel(v.name) or v.label or v.name,
            metadata = v.metadata or {},
            permanent = v.permanent or false,
            serialnumber = v.serialnumber,
            durability = Config.AmmunationShop.repairSysteme and v.durability or 0,
            components = v.components or {},
        }
    end
    return enriched
end

function Storage.Open(playerId, id, invType, maxWeight, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, "Joueur introuvable") end

    if PlayerIsDead and PlayerIsDead[playerId] and PlayerIsDead[playerId].isDead == 1 then
        return cb(false, "Vous ne pouvez pas faire ça")
    end

    local cacheKey = GetCacheKey(invType, id)

    local cached = InventoryCache.Get(cacheKey)
    if cached then
        if InventoryCache.HasPlayers(cacheKey) then
            -- return cb(false, "Ce coffre est déjà ouvert par quelqu'un")
        end

        if maxWeight and maxWeight > 0 then
            cached.maxWeight = maxWeight
        end

        InventoryCache.AddPlayer(cacheKey, playerId)
        return cb(true, cached.data, cacheKey, cached.weight, cached.maxWeight)
    end

    if invType == "VEHICLE" or invType == "VEHICLE_GLOVE_BOX" then
        Storage.LoadVehicle(id, function(success, data, dbId)
            if success then
                local mw = maxWeight or Config.Inventory.DefaultWeights[invType] or Config.Inventory.DefaultWeights.VEHICLE or 100
                local cache = InventoryCache.Set(cacheKey, data, mw, dbId)
                InventoryCache.AddPlayer(cacheKey, playerId)
                cb(true, data, cacheKey, cache.weight, mw)
            else
                cb(false, data)
            end
        end, xPlayer.identifier)
    elseif invType == "PROPERTY" then
        -- Property inventories load from SaveData.PropertiesList
        Storage.LoadProperty(cacheKey, function(success, data, propName)
            if success then
                local mw = maxWeight or data.maxWeight or Config.Inventory.DefaultWeights.PROPERTY or 100
                local cache = InventoryCache.Set(cacheKey, data, mw, propName)
                InventoryCache.AddPlayer(cacheKey, playerId)
                cb(true, data, cacheKey, cache.weight, mw)
            else
                cb(false, data)
            end
        end)
    else
        Storage.LoadStorage(id, function(success, data, dbId)
            if success then
                local mw = maxWeight or Config.Inventory.DefaultWeights[invType] or 1000
                local cache = InventoryCache.Set(cacheKey, data, mw, dbId)
                InventoryCache.AddPlayer(cacheKey, playerId)
                cb(true, data, cacheKey, cache.weight, mw)
            else
                cb(false, data)
            end
        end)
    end
end

function Storage.Close(playerId, cacheKey)
    InventoryCache.RemovePlayer(cacheKey, playerId)
    
    if not InventoryCache.HasPlayers(cacheKey) then
        -- Trash inventories have no DB backing, just discard
        if cacheKey:find("trash_") then
            InventoryCache.Remove(cacheKey)
            return
        end
        Storage.SaveFromCache(cacheKey)
        if cacheKey:find("^VEHICLE_") or cacheKey:find("^VEHICLE_GLOVE_BOX_") then
            InventoryCache.Remove(cacheKey)
        end
    end
end

function Storage.LoadVehicle(plate, cb, ownerIdentifier)
    MySQL.Async.fetchAll('SELECT coffre, owner FROM vtrunk WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        if result[1] then
            local data = json.decode(result[1].coffre) or table.clone(DEFAULT_INVENTORY)
            data.items = EnrichItems(data.items or {})
            data.loadout = EnrichLoadout(data.loadout or {})
            data.clothes = data.clothes or {}
            cb(true, data, plate)
        else
            MySQL.Async.execute('INSERT INTO vtrunk (plate, owner) VALUES (@plate, @owner)', {
                ['@plate'] = plate,
                ['@owner'] = ownerIdentifier or ''
            }, function()
                cb(true, table.clone(DEFAULT_INVENTORY), plate)
            end)
        end
    end)
end

function Storage.LoadStorage(name, cb)
    MySQL.Async.fetchAll('SELECT coffre, id FROM vstorage WHERE name = @name', {
        ['@name'] = name
    }, function(result)
        if result[1] then
            local data = json.decode(result[1].coffre) or table.clone(DEFAULT_INVENTORY)
            data.items = EnrichItems(data.items or {})
            data.loadout = EnrichLoadout(data.loadout or {})
            data.clothes = data.clothes or {}
            cb(true, data, result[1].id)
        else
            MySQL.Async.execute('INSERT INTO vstorage (name) VALUES (@name)', {
                ['@name'] = name
            }, function()
                MySQL.Async.fetchAll('SELECT id FROM vstorage WHERE name = @name', {
                    ['@name'] = name
                }, function(result2)
                    cb(true, table.clone(DEFAULT_INVENTORY), result2[1] and result2[1].id or nil)
                end)
            end)
        end
    end)
end

function Storage.LoadProperty(cacheKey, cb)
    -- Extract property name from cacheKey (format: "PROPERTY_proprieties_name" or "PROPERTY_name")
    local propName = cacheKey:match("^PROPERTY_proprieties_(.+)$") or cacheKey:match("^PROPERTY_(.+)$")
    if not propName then
        return cb(false, "Invalid property cache key")
    end

    -- Wait for properties to be loaded
    local attempts = 0
    while not SaveData or not SaveData.PropertiesList do
        Wait(100)
        attempts = attempts + 1
        if attempts > 50 then
            return cb(false, "Properties not loaded")
        end
    end

    local propData = SaveData.PropertiesList[propName]
    if not propData then
        return cb(false, "Property not found: " .. propName)
    end

    -- Convert property data to inventory format
    local data = {
        cash = propData.data and propData.data.accounts and propData.data.accounts.cash or 0,
        dirtycash = propData.data and propData.data.accounts and propData.data.accounts.dirtycash or 0,
        items = {},
        loadout = {},
        clothes = {},
        maxWeight = propData.poids,
    }

    -- Convert items from property format to inventory format
    if propData.data and propData.data.item then
        for k, v in pairs(propData.data.item) do
            table.insert(data.items, {
                name = v.name,
                count = v.count,
                label = v.label or ESX.GetItemLabel(v.name),
                weight = ESX.Items[v.name] and ESX.Items[v.name].weight or 1,
            })
        end
    end

    -- Convert weapons from property format to inventory format
    if propData.data and propData.data.weapons then
        for k, v in pairs(propData.data.weapons) do
            table.insert(data.loadout, {
                name = v.name,
                label = v.label or ESX.GetWeaponLabel(v.name),
                metadata = {},
                ammo = v.ammo,
            })
        end
    end

    cb(true, data, propName)
end

function Storage.SaveFromCache(cacheKey)
    local cached = InventoryCache.Get(cacheKey)
    if not cached or not cached.dirty then return end

    local invType, id = cacheKey:match("^([^_]+)_(.+)$")
    if not invType or not id then
        print("[ERROR] Invalid cacheKey format: " .. tostring(cacheKey))
        return
    end

    -- Handle PROPERTY type separately - save to SaveData.PropertiesList
    if invType == "PROPERTY" then
        local propName = id:match("^proprieties_(.+)$") or id
        if SaveData and SaveData.PropertiesList and SaveData.PropertiesList[propName] then
            local prop = SaveData.PropertiesList[propName]
            -- Convert inventory format back to property format
            prop.data = prop.data or {}
            prop.data.accounts = prop.data.accounts or {}
            prop.data.accounts.cash = cached.data.cash or 0
            prop.data.accounts.dirtycash = cached.data.dirtycash or 0

            -- Convert items
            prop.data.item = {}
            for _, item in pairs(cached.data.items or {}) do
                prop.data.item[item.name] = {
                    name = item.name,
                    count = item.count,
                    label = item.label or ESX.GetItemLabel(item.name),
                }
            end

            -- Convert weapons back to property format (keyed by random id)
            prop.data.weapons = {}
            local weaponIdx = 1
            for _, weapon in pairs(cached.data.loadout or {}) do
                local randomId = math.random(0, 999999)
                prop.data.weapons[randomId] = {
                    name = weapon.name,
                    label = weapon.label or ESX.GetWeaponLabel(weapon.name),
                    ammo = weapon.ammo or 0,
                }
            end

            -- Mark for saving to database
            if PropertiesSaved then
                PropertiesSaved[propName] = prop
            end
        end
        InventoryCache.ClearDirty(cacheKey)
        return
    end

    local saveData = {
        cash = cached.data.cash or 0,
        dirtycash = cached.data.dirtycash or 0,
        items = {},
        loadout = {},
        clothes = cached.data.clothes or {},
    }

    for _, item in pairs(cached.data.items or {}) do
        table.insert(saveData.items, {
            name = item.name,
            count = item.count,
            metadata = item.metadata,
            extra = item.extra,
            unique = item.unique,
        })
    end

    for _, weapon in pairs(cached.data.loadout or {}) do
        table.insert(saveData.loadout, {
            name = weapon.name,
            metadata = weapon.metadata,
            permanent = weapon.permanent,
            serialnumber = weapon.serialnumber,
            durability = Config.AmmunationShop.repairSysteme and weapon.durability or 0,
            components = weapon.components,
        })
    end

    local jsonData = json.encode(saveData)

    if invType == "VEHICLE" or invType == "VEHICLE_GLOVE_BOX" then
        MySQL.Async.execute('UPDATE vtrunk SET coffre = @coffre WHERE plate = @plate', {
            ['@coffre'] = jsonData,
            ['@plate'] = id
        }, function(affectedRows)
            --null.DebugPrint("[Inventory] VEHICLE save affected rows: " .. tostring(affectedRows))
        end)
    else
        MySQL.Async.execute('UPDATE vstorage SET coffre = @coffre WHERE name = @name', {
            ['@coffre'] = jsonData,
            ['@name'] = id
        }, function(affectedRows)
            --null.DebugPrint("[Inventory] STORAGE save affected rows: " .. tostring(affectedRows))
        end)
    end

    InventoryCache.ClearDirty(cacheKey)
    --null.DebugPrint("[Inventory] Saved cache: " .. cacheKey)
end

AddEventHandler("null:inventory:saveCache", function(cacheKey)
    Storage.SaveFromCache(cacheKey)
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    for key, cached in pairs(InventoryCache) do
        if type(cached) == "table" and cached.dirty then
            Storage.SaveFromCache(key)
        end
    end
end)

local EMPTY_COFFRE = json.encode({ cash = 0, dirtycash = 0, items = {}, loadout = {}, clothes = {} })

function CreateStorage(storagename) 
    MySQL.Async.fetchAll('SELECT coffre, id FROM vstorage WHERE name = @name', {
        ['@name'] = storagename
    }, function (result)
        if result[1] == nil then
            MySQL.Async.execute("INSERT INTO `vstorage` (`name`, `coffre`) VALUES (@name, @coffre)", {
                ['@name'] = storagename,
                ['@coffre'] = EMPTY_COFFRE,
            })
        elseif not result[1].coffre or result[1].coffre == '' then
            -- Fix existing rows with NULL/empty coffre
            MySQL.Async.execute("UPDATE `vstorage` SET `coffre` = @coffre WHERE `name` = @name", {
                ['@name'] = storagename,
                ['@coffre'] = EMPTY_COFFRE,
            })
        end
    end)
end

function AddItemToStorage(storagename, name, number)
    local p = promise.new()
    local cacheKey = FindStorageCacheKey(storagename)
    
    local cached = InventoryCache.Get(cacheKey)
    if cached then
        local inventory = cached.data
        
        if not inventory.items then
            inventory.items = {}
        end
        
        local alreadyIn = nil
        for k,v in pairs(inventory.items) do
            if v.name == name then
                alreadyIn = {v,k}
            end
        end
        
        if alreadyIn == nil then
            local itemWeight = 1
            if ESX.Items[name] ~= nil then
                itemWeight = ESX.Items[name].weight
            end
            table.insert(inventory.items, {name=name, weight=itemWeight, count=number,label=ESX.GetItemLabel(name)})
        else
            inventory.items[alreadyIn[2]].count = inventory.items[alreadyIn[2]].count + number
        end
        
        InventoryCache.MarkDirty(cacheKey)
        --null.DebugPrint("[CACHE] Added Item "..name.." ("..number.."x) to cached storage: "..storagename)
        p:resolve(true)
    else
        MySQL.Async.fetchAll('SELECT coffre, id FROM vstorage WHERE name = @name', {
            ['@name'] = storagename
        }, function (result)
            if result[1] then
                local inventory = json.decode(result[1].coffre)
                
                if not inventory or type(inventory) ~= "table" then
                    -- Auto-repair NULL/corrupted coffre
                    inventory = { cash = 0, dirtycash = 0, items = {}, loadout = {}, clothes = {} }
                end
                
                if not inventory.items then
                    inventory.items = {}
                end
                
                local alreadyIn = nil
                for k,v in pairs(inventory.items) do
                    if v.name == name then
                        alreadyIn = {v,k}
                    end
                end
                if alreadyIn == nil then
                    local itemWeight = 1
                    if ESX.Items[name] ~= nil then
                        itemWeight = ESX.Items[name].weight
                    end
                    table.insert(inventory.items, {name=name, weight=itemWeight, count=number,label=ESX.GetItemLabel(name)})
                else
                    inventory.items[alreadyIn[2]].count = inventory.items[alreadyIn[2]].count + number
                end
                MySQL.Async.execute("UPDATE `vstorage` SET `coffre` = '"..json.encode(inventory).."' WHERE `name` = '"..storagename.."'", {}, function()
                    --null.DebugPrint("[SQL] Added Item "..name.." ("..number.."x) to storage : "..storagename)
                    p:resolve(true)
                end)
            else
                null.DebugPrint("[SQL] Storage not found: "..storagename)
                p:resolve(false)
            end
        end)
    end
    
    return Citizen.Await(p)
end

function RemoveItemToStorage(storagename, name, number)
    local cacheKey = FindStorageCacheKey(storagename)
    
    local cached = InventoryCache.Get(cacheKey)
    if cached then
        local inventory = cached.data
        
        if not inventory or type(inventory) ~= "table" or not inventory.items then
            print("[ERROR] Storage data corrupted for: " .. storagename)
            return
        end
        
        local alreadyIn = nil
        for k,v in pairs(inventory.items) do
            if v.name == name then
                alreadyIn = {v,k}
            end
        end
        
        if alreadyIn ~= nil then
            if inventory.items[alreadyIn[2]].count - number > 0 then
                inventory.items[alreadyIn[2]].count = inventory.items[alreadyIn[2]].count - number
            else
                inventory.items[alreadyIn[2]] = nil
            end
        else
            return false
        end
        
        InventoryCache.MarkDirty(cacheKey)
        --null.DebugPrint("[CACHE] Removed Item "..name.." ("..number.."x) from cached storage: "..storagename)
    else
        MySQL.Async.fetchAll('SELECT coffre, id FROM vstorage WHERE name = @name', {
            ['@name'] = storagename
        }, function (result)
            if result[1] then
                local inventory = json.decode(result[1].coffre)
                
                if not inventory or type(inventory) ~= "table" or not inventory.items then
                    print("[ERROR] Storage data corrupted for: " .. storagename)
                    return
                end
                
                local alreadyIn = nil
                for k,v in pairs(inventory.items) do
                    if v.name == name then
                        alreadyIn = {v,k}
                    end
                end
                if alreadyIn ~= nil then
                    if inventory.items[alreadyIn[2]].count - number > 0 then
                        inventory.items[alreadyIn[2]].count = inventory.items[alreadyIn[2]].count - number
                    else
                        inventory.items[alreadyIn[2]] = nil
                    end
                else
                    return false
                end
                MySQL.Async.execute("UPDATE `vstorage` SET `coffre` = '"..json.encode(inventory).."' WHERE `name` = '"..storagename.."'", {}, function()  end)
            end
        end)
    end
end

function AddWeaponToStorage(storagename, name, description)
    local cacheKey = FindStorageCacheKey(storagename)
    
    local cached = cacheKey and InventoryCache.Get(cacheKey)
    if cached then
        local inventory = cached.data
        if not inventory.loadout then
            inventory.loadout = {}
        end
        if description ~= nil then
            table.insert(inventory.loadout, {name=name, metadata = {description=description}})
        else
            table.insert(inventory.loadout, {name=name})
        end
        InventoryCache.MarkDirty(cacheKey)
        --null.DebugPrint("[CACHE] Added weapon "..name.." to cached storage: "..storagename)
    else
        MySQL.Async.fetchAll("SELECT coffre, id FROM vstorage WHERE name = @name", {
            ['@name'] = storagename
        }, function(result)
            if result[1] then
                local inventory = json.decode(result[1].coffre)
                if not inventory or type(inventory) ~= "table" then
                    -- Auto-repair NULL/corrupted coffre
                    inventory = { cash = 0, dirtycash = 0, items = {}, loadout = {}, clothes = {} }
                end
                if not inventory.loadout then
                    inventory.loadout = {}
                end
                if description ~= nil then
                    table.insert(inventory.loadout, {name=name, metadata = {description=description}})
                else
                    table.insert(inventory.loadout, {name=name})
                end
                description = description or "Nil"
                MySQL.Async.execute("UPDATE `vstorage` SET `coffre` = '"..json.encode(inventory).."' WHERE `name` = '"..storagename.."'", {}, function()  end)
                --null.DebugPrint("[SQL] Added weapon "..name.." (Description: "..description..") to storage : "..storagename)
            end
        end)
    end
end

function RemoveWeaponToStorage(storagename, name)
    local cacheKey = FindStorageCacheKey(storagename)
    
    local cached = cacheKey and InventoryCache.Get(cacheKey)
    if cached then
        local inventory = cached.data
        if not inventory or type(inventory) ~= "table" or not inventory.loadout then
            print("[ERROR] Storage data corrupted for: " .. storagename)
            return
        end
        local alreadyIn = {}
        for k,v in pairs(inventory.loadout) do
            if v.name == name then
                alreadyIn = {v,k}
            end
        end
        if alreadyIn[2] ~= nil then
            inventory.loadout[alreadyIn[2]] = nil
        else
            return false
        end
        InventoryCache.MarkDirty(cacheKey)
        --null.DebugPrint("[CACHE] Removed weapon "..name.." from cached storage: "..storagename)
    else
        MySQL.Async.fetchAll('SELECT coffre, id FROM vstorage WHERE name = @name', {
            ['@name'] = storagename
        }, function (result)
            if result[1] then
                local inventory = json.decode(result[1].coffre)
                if not inventory or type(inventory) ~= "table" or not inventory.loadout then
                    print("[ERROR] Storage data corrupted for: " .. storagename)
                    return
                end
                local alreadyIn = {}
                for k,v in pairs(inventory.loadout) do
                    if v.name == name then
                        alreadyIn = {v,k}
                    end
                end
                if alreadyIn[2] ~= nil then
                    inventory.loadout[alreadyIn[2]] = nil
                else
                    return false
                end
                MySQL.Async.execute("UPDATE `vstorage` SET `coffre` = '"..json.encode(inventory).."' WHERE `name` = '"..storagename.."'", {}, function()  end)
            end
        end)
    end
end

function GetItemCountFromStorage(storagename, itemname, cb)
    local cacheKey = FindStorageCacheKey(storagename)
    
    local cached = InventoryCache.Get(cacheKey)
    if cached then
        local inventory = cached.data
        local count = 0
        
        if inventory.items then
            for k,v in pairs(inventory.items) do
                if v.name == itemname then
                    count = v.count or 0
                    break
                end
            end
        end
        
        if cb then
            cb(count)
        end
        return count
    else
        MySQL.Async.fetchAll('SELECT coffre, id FROM vstorage WHERE name = @name', {
            ['@name'] = storagename
        }, function (result) 
            if result[1] then
                local inventory = json.decode(result[1].coffre) or {items = {}}
                local count = 0
                if inventory.items and type(inventory.items) == "table" then
                    for k,v in pairs(inventory.items) do
                        if v.name == itemname then
                            count = v.count or 0
                            break
                        end
                    end
                end
                if cb then
                    cb(count)
                end
                return count
            else
                if cb then
                    cb(0)
                end
                return 0
            end
        end)
    end
end

exports("Storage_Open", Storage.Open)
exports("Storage_Close", Storage.Close)
exports("Storage_Save", Storage.SaveFromCache)

_G.InventoryStorage = Storage
_G.InventoryStorageLoaded = true

return Storage