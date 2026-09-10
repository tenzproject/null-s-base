while not Config.Inventory do
    Wait(0)
end

local InventoryCache = {}

-- InventoryCache[type_id] = {
--     data = { items = {}, loadout = {}, cash = 0, dirtycash = 0, clothes = {} },
--     weight = 0,
--     maxWeight = 100,
--     openedBy = { [playerId] = true },
--     lastAccess = os.time(),
--     dirty = false,  -- true si modifié depuis dernière sauvegarde
--     dbId = nil,     -- ID en base de données
-- }

local CACHE_TIMEOUT = Config.Inventory.CacheTimeout or 300
local SAVE_INTERVAL = Config.Inventory.SaveInterval or 30

local function GetCacheKey(invType, id)
    return ("%s_%s"):format(invType, tostring(id))
end

function InventoryCache.Get(key)
    local cached = InventoryCache[key]
    if cached then
        cached.lastAccess = os.time()
        return cached
    end
    return nil
end

function InventoryCache.Set(key, data, maxWeight, dbId)
    local weight = InventoryCache.CalculateWeight(data)
    
    InventoryCache[key] = {
        data = data,
        weight = weight,
        maxWeight = maxWeight or -1,
        openedBy = {},
        lastAccess = os.time(),
        dirty = false,
        dbId = dbId,
    }
    
    return InventoryCache[key]
end

function InventoryCache.AddPlayer(key, playerId)
    local cached = InventoryCache[key]
    if cached then
        cached.openedBy[playerId] = true
        cached.lastAccess = os.time()
    end
end

function InventoryCache.RemovePlayer(key, playerId)
    local cached = InventoryCache[key]
    if cached then
        cached.openedBy[playerId] = nil
    end
end

function InventoryCache.HasPlayers(key)
    local cached = InventoryCache[key]
    if cached then
        for _ in pairs(cached.openedBy) do
            return true
        end
    end
    return false
end

function InventoryCache.MarkDirty(key)
    local cached = InventoryCache[key]
    if cached then
        cached.dirty = true
    end
end

function InventoryCache.CalculateWeight(data)
    local weight = 0
    
    if data.items then
        for _, item in pairs(data.items) do
            local itemWeight = item.weight or 1
            if ESX.Items[item.name] then
                itemWeight = ESX.Items[item.name].weight or 1
            end
            weight = weight + (itemWeight * (item.count or 1))
        end
    end
    
    if data.loadout then
        for _, weapon in pairs(data.loadout) do
            if not ESX.ContribWeapon(weapon.name) and not weapon.permanent then
                weight = weight + (ESX.GetWeaponWeight(weapon.name) or Config.WeaponDefaultWeight)
            end
        end
    end
    
    return weight
end

function InventoryCache.UpdateWeight(key)
    local cached = InventoryCache[key]
    if cached then
        cached.weight = InventoryCache.CalculateWeight(cached.data)
    end
end

function InventoryCache.Remove(key)
    InventoryCache[key] = nil
end

function InventoryCache.GetDirtyKeys()
    local keys = {}
    for key, cached in pairs(InventoryCache) do
        if type(cached) == "table" and cached.dirty then
            table.insert(keys, key)
        end
    end
    return keys
end

function InventoryCache.ClearDirty(key)
    local cached = InventoryCache[key]
    if cached then
        cached.dirty = false
    end
end

CreateThread(LPH_JIT(function()
    while true do
        Wait(60000)
        
        local now = os.time()
        local toRemove = {}
        
        for key, cached in pairs(InventoryCache) do
            if type(cached) == "table" then
                if not InventoryCache.HasPlayers(key) and (now - cached.lastAccess) > CACHE_TIMEOUT then
                    if cached.dirty then
                        TriggerEvent("null:inventory:saveCache", key)
                    end
                    table.insert(toRemove, key)
                end
            end
        end
        
        for _, key in ipairs(toRemove) do
            InventoryCache.Remove(key)
            null.DebugPrint("[Inventory Cache] Removed expired cache: " .. key)
        end
    end
end))

CreateThread(LPH_JIT(function()
    while true do
        Wait(SAVE_INTERVAL * 1000)
        
        local dirtyKeys = InventoryCache.GetDirtyKeys()
        for _, key in ipairs(dirtyKeys) do
            TriggerEvent("null:inventory:saveCache", key)
        end
    end
end))

function FindStorageCacheKey(storagename)
    for key, cached in pairs(InventoryCache) do
        if type(cached) == "table" then
            local _, id = key:match("^([^_]+)_(.+)$")
            if id == storagename then
                return key
            end
        end
    end
    return nil
end

_G.FindStorageCacheKey = FindStorageCacheKey
_G.InventoryCache = InventoryCache
_G.InventoryCacheLoaded = true

return InventoryCache
