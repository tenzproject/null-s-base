while not _G.InventoryStorageLoaded do
    Wait(0)
end

local Transfers = {}

local ERROR = {
    NO_PLAYER = "Joueur introuvable",
    NO_CACHE = "Coffre introuvable",
    NO_ITEM = "Vous n'avez pas cet objet",
    NO_WEAPON = "Vous n'avez pas cette arme",
    NO_MONEY = "Vous n'avez pas cette somme",
    NO_SPACE = "Plus de place dans le coffre",
    CHEST_NO_ITEM = "Cet objet n'est plus dans le coffre",
    CHEST_NO_WEAPON = "Cette arme n'est plus dans le coffre",
    CHEST_NO_MONEY = "Il n'y a pas cette somme dans le coffre",
    WEAPON_PERMANENT = "Cette arme est permanente",
    WEAPON_POLICE = "Cette arme appartient aux forces de l'ordre",
    ALREADY_HAS_WEAPON = "Vous avez déjà cette arme",
    INVALID_COUNT = "Quantité invalide",
}

local function GetCache(cacheKey)
    return InventoryCache.Get(cacheKey)
end

local function HasSpace(cached, itemWeight, count)
    if cached.maxWeight == -1 then return true end
    local newWeight = cached.weight + (itemWeight * count)
    return newWeight <= cached.maxWeight
end

local function SendError(playerId, message)
    TriggerClientEvent("inventory:sendMessage", playerId, "~r~" .. message)
end

local function SendSuccess(playerId, message)
    TriggerClientEvent("inventory:sendMessage", playerId, "~g~" .. message)
end

function Transfers.DepositMoney(playerId, cacheKey, amount, moneyType, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, ERROR.NO_PLAYER) end
    
    local cached = GetCache(cacheKey)
    if not cached then return cb(false, ERROR.NO_CACHE) end
    
    amount = tonumber(amount) or 0
    if amount <= 0 then return cb(false, ERROR.INVALID_COUNT) end
    
    local playerMoney = xPlayer.getAccount(moneyType).money
    if playerMoney < amount then return cb(false, ERROR.NO_MONEY) end
    
    xPlayer.removeAccountMoney(moneyType, amount)
    cached.data[moneyType] = (cached.data[moneyType] or 0) + amount
    InventoryCache.MarkDirty(cacheKey)
    
    cb(true)
end

function Transfers.WithdrawMoney(playerId, cacheKey, amount, moneyType, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, ERROR.NO_PLAYER) end
    
    local cached = GetCache(cacheKey)
    if not cached then return cb(false, ERROR.NO_CACHE) end
    
    amount = tonumber(amount) or 0
    if amount <= 0 then return cb(false, ERROR.INVALID_COUNT) end
    
    local chestMoney = cached.data[moneyType] or 0
    if chestMoney < amount then return cb(false, ERROR.CHEST_NO_MONEY) end
    
    cached.data[moneyType] = chestMoney - amount
    xPlayer.addAccountMoney(moneyType, amount)
    InventoryCache.MarkDirty(cacheKey)
    
    cb(true)
end

function Transfers.DepositItem(playerId, cacheKey, itemName, count, itemExtra, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, ERROR.NO_PLAYER) end
    
    local cached = GetCache(cacheKey)
    if not cached then 
        return cb(false, ERROR.NO_CACHE)
    end
    
    count = tonumber(count) or 0
    if count <= 0 then return cb(false, ERROR.INVALID_COUNT) end
    
    -- Special handling for accessories - they don't use ESX.Items system
    if itemName == "item_accessory" then
        -- Find accessory in player inventory by matching extra.identifier
        local playerItem = nil
        local itemIndex = nil
        local clotheId = itemExtra and itemExtra.identifier
        
        for i = 1, #xPlayer.inventory do
            local invItem = xPlayer.inventory[i]
            if invItem.name == itemName then
                if clotheId and invItem.extra and invItem.extra.identifier == clotheId then
                    playerItem = invItem
                    itemIndex = i
                    break
                elseif not clotheId then
                    playerItem = invItem
                    itemIndex = i
                    break
                end
            end
        end
        
        if not playerItem then
            return cb(false, ERROR.NO_ITEM)
        end
        
        -- Check if it's a bag
        local isBag = playerItem.metadata and playerItem.metadata.type2 == "bag"
        
        if isBag and _G.InventoryBackpacks then
            -- For bags, we don't transfer the item itself, we just mark it as "stored"
            -- The bag's inventory stays in vbackpacks but we add a reference in the storage
            local bagClotheId = playerItem.metadata.clotheId or playerItem.extra and playerItem.extra.identifier
            
            if not bagClotheId then
                return cb(false, "Sac invalide (pas d'ID)")
            end
            
            -- Calculate bag weight (contents weight / divisor)
            _G.InventoryBackpacks.GetBagInventoryWeight(xPlayer.identifier, bagClotheId, function(bagWeight)
                local itemWeight = bagWeight
                
                if not HasSpace(cached, itemWeight, 1) then
                    return cb(false, ERROR.NO_SPACE)
                end
                
                -- Add bag reference to storage
                table.insert(cached.data.items, {
                    name = itemName,
                    count = 1,
                    weight = itemWeight,
                    label = playerItem.label or "Sac à dos",
                    metadata = playerItem.metadata or {},
                    extra = playerItem.extra,
                    unique = true,
                })
                
                -- Remove bag accessory from player
                xPlayer.removeInventoryItem(itemName, 1, clotheId)
                
                InventoryCache.UpdateWeight(cacheKey)
                InventoryCache.MarkDirty(cacheKey)
                
                cb(true)
            end)
            return
        else
            -- Regular accessory (not a bag)
            local itemWeight = 1
            if not HasSpace(cached, itemWeight, 1) then
                return cb(false, ERROR.NO_SPACE)
            end
            
            table.insert(cached.data.items, {
                name = itemName,
                count = 1,
                weight = itemWeight,
                label = playerItem.label or "Accessoire",
                metadata = playerItem.metadata or {},
                extra = playerItem.extra,
                unique = true,
            })
            
            xPlayer.removeInventoryItem(itemName, 1, clotheId)
            
            InventoryCache.UpdateWeight(cacheKey)
            InventoryCache.MarkDirty(cacheKey)
            
            cb(true)
            return
        end
    end
    
    -- Normal item handling (non-accessories)
    local itemId = itemExtra and itemExtra.identifier or nil
    local playerItem, itemIndex = xPlayer.getInventoryItem(itemName, itemId)
    
    if not playerItem or not playerItem.name then
        return cb(false, ERROR.NO_ITEM)
    end
    
    if playerItem.count < count and not playerItem.unique then
        return cb(false, ERROR.NO_ITEM)
    end
    
    local itemWeight = ESX.Items[itemName] and ESX.Items[itemName].weight or 1
    if not HasSpace(cached, itemWeight, count) then
        return cb(false, ERROR.NO_SPACE)
    end
    
    local found = false
    if not playerItem.unique then
        for k, v in pairs(cached.data.items) do
            if v.name == itemName then
                cached.data.items[k].count = v.count + count
                found = true
                break
            end
        end
    end
    
    if not found then
        table.insert(cached.data.items, {
            name = itemName,
            count = count,
            weight = itemWeight,
            label = ESX.GetItemLabel(itemName),
            metadata = playerItem.metadata or {},
            extra = playerItem.extra,
            unique = playerItem.unique,
        })
    end
    
    if playerItem.unique then
        xPlayer.removeInventoryItem(itemName, count, itemId)
    else
        xPlayer.removeInventoryItem(itemName, count)
    end
    
    InventoryCache.UpdateWeight(cacheKey)
    InventoryCache.MarkDirty(cacheKey)
    
    cb(true)
end

function Transfers.WithdrawItem(playerId, cacheKey, itemName, count, itemExtra, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, ERROR.NO_PLAYER) end
    
    local cached = GetCache(cacheKey)
    if not cached then return cb(false, ERROR.NO_CACHE) end
    
    count = tonumber(count) or 0
    if count <= 0 then return cb(false, ERROR.INVALID_COUNT) end
    
    local foundIndex = nil
    local foundItem = nil
    
    for k, v in pairs(cached.data.items) do
        if v.name == itemName then
            if itemExtra and itemExtra.identifier and v.extra and v.extra.identifier then
                if v.extra.identifier == itemExtra.identifier then
                    foundIndex = k
                    foundItem = v
                    break
                end
            else
                foundIndex = k
                foundItem = v
                break
            end
        end
    end
    
    if not foundItem then
        return cb(false, ERROR.CHEST_NO_ITEM)
    end
    
    if foundItem.count < count and not foundItem.unique then
        return cb(false, ERROR.CHEST_NO_ITEM)
    end
    
    -- Special handling for bags
    local isBag = itemName == "item_accessory" and foundItem.metadata and foundItem.metadata.type2 == "bag"
    
    if isBag and _G.InventoryBackpacks then
        local clotheId = foundItem.metadata.clotheId or foundItem.extra and foundItem.extra.identifier
        
        if clotheId and _G.InventoryBackpacks then
            -- Verify bag still exists in vbackpacks
            _G.InventoryBackpacks.BelongsToPlayer(xPlayer.identifier, clotheId, function(exists)
                if not exists then
                    -- Bag doesn't exist anymore, just remove from storage
                    table.remove(cached.data.items, foundIndex)
                    InventoryCache.UpdateWeight(cacheKey)
                    InventoryCache.MarkDirty(cacheKey)
                    return cb(false, "Ce sac n'existe plus")
                end
                
                -- Remove bag from storage
                table.remove(cached.data.items, foundIndex)
                
                -- Give bag accessory to player
                xPlayer.addInventoryItem(itemName, 1, foundItem.metadata)
                
                InventoryCache.UpdateWeight(cacheKey)
                InventoryCache.MarkDirty(cacheKey)
                
                cb(true)
            end)
            return
        end
    end
    
    -- Normal item handling
    if foundItem.count == count or foundItem.unique then
        table.remove(cached.data.items, foundIndex)
    else
        cached.data.items[foundIndex].count = foundItem.count - count
    end
    
    xPlayer.addInventoryItem(itemName, count, foundItem.metadata)
    
    InventoryCache.UpdateWeight(cacheKey)
    InventoryCache.MarkDirty(cacheKey)
    
    cb(true)
end

function Transfers.DepositWeapon(playerId, cacheKey, weaponName, metadata, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, ERROR.NO_PLAYER) end
    
    local cached = GetCache(cacheKey)
    if not cached then return cb(false, ERROR.NO_CACHE) end
    
    local playerLoadout = xPlayer.getLoadout()
    local foundWeapon = nil
    
    for _, weapon in pairs(playerLoadout) do
        if type(weapon) == "table" and weapon.name == weaponName then
            if weapon.permanent then
                return cb(false, ERROR.WEAPON_PERMANENT)
            end
            if weapon.metadata and (weapon.metadata.police or weapon.metadata.gouvernement) then
                return cb(false, ERROR.WEAPON_POLICE)
            end
            foundWeapon = weapon
            break
        end
    end
    
    if not foundWeapon then
        return cb(false, ERROR.NO_WEAPON)
    end
    
    local weaponWeight = ESX.GetWeaponWeight(weaponName) or Config.WeaponDefaultWeight
    if not HasSpace(cached, weaponWeight, 1) then
        return cb(false, ERROR.NO_SPACE)
    end
    
    table.insert(cached.data.loadout, {
        name = weaponName,
        label = ESX.GetWeaponLabel(weaponName),
        metadata = metadata or foundWeapon.metadata or {},
        permanent = foundWeapon.permanent or false,
        serialnumber = foundWeapon.serialnumber,
        durability = Config.AmmunationShop.repairSysteme and foundWeapon.durability or 0,
        components = foundWeapon.components or {},
    })
    
    xPlayer.removeWeapon(weaponName)
    
    InventoryCache.UpdateWeight(cacheKey)
    InventoryCache.MarkDirty(cacheKey)
    
    cb(true)
end

function Transfers.WithdrawWeapon(playerId, cacheKey, weaponName, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, ERROR.NO_PLAYER) end
    
    local cached = GetCache(cacheKey)
    if not cached then return cb(false, ERROR.NO_CACHE) end
    
    local playerLoadout = xPlayer.getLoadout()
    for _, weapon in pairs(playerLoadout) do
        if type(weapon) == "table" and weapon.name == weaponName then
            return cb(false, ERROR.ALREADY_HAS_WEAPON)
        end
    end
    
    local foundIndex = nil
    local foundWeapon = nil
    
    for k, weapon in pairs(cached.data.loadout) do
        if weapon.name == weaponName then
            foundIndex = k
            foundWeapon = weapon
            break
        end
    end
    
    if not foundWeapon then
        return cb(false, ERROR.CHEST_NO_WEAPON)
    end
    
    table.remove(cached.data.loadout, foundIndex)
    
    xPlayer.addWeapon(
        weaponName,
        0,
        foundWeapon.metadata,
        foundWeapon.permanent or false,
        foundWeapon.serialnumber,
        foundWeapon.durability or 0.0,
        foundWeapon.components or {}
    )
    
    InventoryCache.UpdateWeight(cacheKey)
    InventoryCache.MarkDirty(cacheKey)
    
    cb(true)
end

ESX.RegisterServerCallback('null:inventory:open', function(source, cb, id, invType, maxWeight)
    InventoryStorage.Open(source, id, invType, maxWeight, function(success, data, cacheKey, weight, mw)
        if success then
            cb({
                success = true,
                data = data,
                cacheKey = cacheKey,
                weight = weight,
                maxWeight = mw,
            })
        else
            cb({ success = false, error = data })
        end
    end)
end)

RegisterNetEvent("null:inventory:close", function(cacheKey)
    local playerId = source
    InventoryStorage.Close(playerId, cacheKey)
end)

ESX.RegisterServerCallback('null:inventory:depositMoney', function(source, cb, cacheKey, amount, moneyType)
    Transfers.DepositMoney(source, cacheKey, amount, moneyType, function(success, error)
        if not success then SendError(source, error) end
        cb(success)
    end)
end)

ESX.RegisterServerCallback('null:inventory:withdrawMoney', function(source, cb, cacheKey, amount, moneyType)
    Transfers.WithdrawMoney(source, cacheKey, amount, moneyType, function(success, error)
        if not success then SendError(source, error) end
        cb(success)
    end)
end)

ESX.RegisterServerCallback('null:inventory:depositItem', function(source, cb, cacheKey, itemName, count, extra)
    Transfers.DepositItem(source, cacheKey, itemName, count, extra, function(success, error)
        if not success then SendError(source, error) end
        cb(success)
    end)
end)

ESX.RegisterServerCallback('null:inventory:withdrawItem', function(source, cb, cacheKey, itemName, count, extra)
    Transfers.WithdrawItem(source, cacheKey, itemName, count, extra, function(success, error)
        if not success then SendError(source, error) end
        cb(success)
    end)
end)

ESX.RegisterServerCallback('null:inventory:depositWeapon', function(source, cb, cacheKey, weaponName, metadata)
    Transfers.DepositWeapon(source, cacheKey, weaponName, metadata, function(success, error)
        if not success then SendError(source, error) end
        cb(success)
    end)
end)

ESX.RegisterServerCallback('null:inventory:withdrawWeapon', function(source, cb, cacheKey, weaponName)
    Transfers.WithdrawWeapon(source, cacheKey, weaponName, function(success, error)
        if not success then SendError(source, error) end
        cb(success)
    end)
end)

_G.InventoryTransfers = Transfers
_G.InventoryTransfersLoaded = true

return Transfers
