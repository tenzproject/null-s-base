-- ============================================================================
-- TRASH SEARCH - Server Side
-- Per-prop cooldown, loot generation into temporary inventory cache
-- ============================================================================

while not _G.InventoryCacheLoaded do Wait(0) end

local propCooldowns = {} -- key = coordsHash, value = os.time()

local function CoordsHash(x, y, z)
    return string.format("%.1f_%.1f_%.1f", x, y, z)
end

local function GetTotalLootWeight()
    local total = 0
    for _, item in ipairs(Config.TrashSearch.Loot) do
        total = total + item.weight
    end
    return total
end

local function GetWeightedRandomLoot(totalWeight)
    local roll = math.random(1, totalWeight)
    local cumulative = 0
    for _, item in ipairs(Config.TrashSearch.Loot) do
        cumulative = cumulative + item.weight
        if roll <= cumulative then
            local qty = math.random(item.min or 1, item.max or 1)
            return item.name, item.label, qty
        end
    end
    local fb = Config.TrashSearch.Loot[1]
    return fb.name, fb.label, 1
end

local function GenerateLootItems()
    local findChance = Config.TrashSearch.FindChance or 65
    if math.random(1, 100) > findChance then
        return {}
    end

    local maxItems = Config.TrashSearch.MaxItemsPerSearch or 2
    local itemCount = math.random(1, maxItems)
    local totalWeight = GetTotalLootWeight()
    local items = {}

    for i = 1, itemCount do
        local itemName, itemLabel, qty = GetWeightedRandomLoot(totalWeight)
        local found = false
        for _, it in ipairs(items) do
            if it.name == itemName then
                it.count = it.count + qty
                found = true
                break
            end
        end
        if not found then
            local itemData = ESX.Items[itemName]
            table.insert(items, {
                name = itemName,
                label = itemLabel,
                count = qty,
                weight = itemData and itemData.weight or 0.10,
                metadata = {},
            })
        end
    end

    return items
end

-- Callback: check per-prop cooldown, generate loot, create temp cache, return inventory data
ESX.RegisterServerCallback('null:trashsearch:open', function(source, cb, propX, propY, propZ)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false, "Erreur joueur") end

    local hash = CoordsHash(propX, propY, propZ)
    local now = os.time()
    local cooldown = Config.TrashSearch.Cooldown or 30

    if propCooldowns[hash] and (now - propCooldowns[hash]) < cooldown then
        local remaining = cooldown - (now - propCooldowns[hash])
        return cb(false, "Cette poubelle a déjà été fouillée. Réessayez dans ~r~" .. remaining .. "s")
    end

    propCooldowns[hash] = now

    local lootItems = GenerateLootItems()

    -- Build inventory data for the temporary cache
    local storageName = "trash_" .. hash
    local cacheKey = "SOCIETY_" .. storageName
    local data = {
        cash = 0,
        dirtycash = 0,
        items = lootItems,
        loadout = {},
        clothes = {},
    }

    local maxWeight = 500
    InventoryCache.Set(cacheKey, data, maxWeight, nil)
    InventoryCache.AddPlayer(cacheKey, source)

    cb(true, data, storageName, cacheKey)
end)

-- Cleanup old prop cooldowns every 5 minutes
Citizen.CreateThread(function()
    while true do
        Wait(300000)
        local now = os.time()
        local cooldown = (Config.TrashSearch.Cooldown or 30) * 2
        for hash, t in pairs(propCooldowns) do
            if (now - t) > cooldown then
                propCooldowns[hash] = nil
            end
        end
    end
end)
