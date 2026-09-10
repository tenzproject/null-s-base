-- ============================================================================
-- KEVLAR SYSTEM — Server
-- Item stays in inventory when equipped (like accessories/bags)
-- ============================================================================

local equippedKevlar = {} -- [serverId] = { itemName, uniqueId, extraIdentifier, durability, maxDurability, maxArmor, identifier }

-- SQL migration: create kevlar tracking table
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `vkevlars` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(60) NOT NULL,
            `item_name` VARCHAR(50) NOT NULL,
            `unique_id` VARCHAR(100) NOT NULL,
            `durability` FLOAT NOT NULL DEFAULT 100,
            `equipped` TINYINT(1) NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `uk_unique_id` (`unique_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})
end)

-- ============================================================================
-- HELPERS
-- ============================================================================

local function GetKevlarUniqueId(item)
    if item.metadata and item.metadata.uniqueId then
        return item.metadata.uniqueId
    end
    if item.extra and item.extra.identifier then
        return tostring(item.name) .. "-" .. tostring(item.extra.identifier)
    end
    return nil
end

local function GetKevlarExtraId(item)
    return item.extra and item.extra.identifier or nil
end

local function SaveKevlarDurability(uniqueId, durability)
    if not uniqueId then return end
    MySQL.Async.execute(
        'UPDATE `vkevlars` SET `durability` = @durability WHERE `unique_id` = @uniqueId',
        { ['@durability'] = durability, ['@uniqueId'] = uniqueId }
    )
end

local function EnsureKevlarRecord(identifier, itemName, uniqueId, durability)
    if not uniqueId then return end
    MySQL.Async.execute([[
        INSERT INTO `vkevlars` (`identifier`, `item_name`, `unique_id`, `durability`)
        VALUES (@identifier, @itemName, @uniqueId, @durability)
        ON DUPLICATE KEY UPDATE `durability` = VALUES(`durability`)
    ]], {
        ['@identifier'] = identifier,
        ['@itemName'] = itemName,
        ['@uniqueId'] = uniqueId,
        ['@durability'] = durability,
    })
end

-- Find a specific kevlar item in player inventory by extra.identifier
local function FindKevlarInInventory(xPlayer, itemName, extraIdentifier)
    for i, item in ipairs(xPlayer.inventory) do
        if item.name == itemName and item.count > 0 then
            if extraIdentifier then
                if item.extra and tostring(item.extra.identifier) == tostring(extraIdentifier) then
                    return item, i
                end
            else
                return item, i
            end
        end
    end
    return nil, nil
end

-- Update durability directly on the inventory item (in-place)
local function UpdateItemDurability(xPlayer, itemName, extraIdentifier, newDurability)
    local item = FindKevlarInInventory(xPlayer, itemName, extraIdentifier)
    if item and item.metadata then
        item.metadata.durability = newDurability
    end
end

-- ============================================================================
-- EQUIP KEVLAR — Item stays in inventory
-- ============================================================================

RegisterNetEvent("null:kevlar:equip", function(itemName, itemExtra)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local kevlarConfig = Config.Kevlar.GetKevlarConfig(itemName)
    if not kevlarConfig then return end

    -- Already wearing kevlar?
    if equippedKevlar[src] then
        TriggerClientEvent("inventory:sendMessage", src, "~r~Vous portez déjà un gilet")
        return
    end

    -- Find the item in player inventory
    local extraId = itemExtra and itemExtra.identifier or nil
    local foundItem = FindKevlarInInventory(xPlayer, itemName, extraId)
    if not foundItem then return end

    local uniqueId = GetKevlarUniqueId(foundItem)
    if not uniqueId then return end
    local itemExtraId = GetKevlarExtraId(foundItem)

    -- Get durability from metadata
    local durability = foundItem.metadata and foundItem.metadata.durability
    if not durability or durability <= 0 then
        durability = kevlarConfig.maxDurability
    end

    -- Calculate armor from durability ratio
    local armorValue = math.floor((durability / kevlarConfig.maxDurability) * kevlarConfig.maxArmor)
    if armorValue <= 0 then
        TriggerClientEvent("inventory:sendMessage", src, "~r~Ce gilet est détruit")
        return
    end

    -- Track equipped (item stays in inventory)
    equippedKevlar[src] = {
        itemName = itemName,
        uniqueId = uniqueId,
        extraIdentifier = itemExtraId,
        durability = durability,
        maxDurability = kevlarConfig.maxDurability,
        maxArmor = kevlarConfig.maxArmor,
        identifier = xPlayer.identifier,
    }

    -- Save to DB
    EnsureKevlarRecord(xPlayer.identifier, itemName, uniqueId, durability)
    MySQL.Async.execute('UPDATE `vkevlars` SET `equipped` = 1 WHERE `unique_id` = @uniqueId', { ['@uniqueId'] = uniqueId })

    -- Apply armor + visual on client (send extraIdentifier so UI knows which item)
    TriggerClientEvent("null:kevlar:equipped", src, {
        itemName = itemName,
        extraIdentifier = itemExtraId,
        durability = durability,
        maxDurability = kevlarConfig.maxDurability,
        maxArmor = kevlarConfig.maxArmor,
        armorValue = armorValue,
        bproof = kevlarConfig.bproof,
    })

    TriggerClientEvent("null:inventory:update", src)
end)

-- ============================================================================
-- UNEQUIP KEVLAR — Item already in inventory, just remove armor
-- ============================================================================

RegisterNetEvent("null:kevlar:unequip", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local equipped = equippedKevlar[src]
    if not equipped then
        TriggerClientEvent("inventory:sendMessage", src, "~r~Vous ne portez pas de gilet")
        return
    end

    -- Update durability on the item in inventory
    UpdateItemDurability(xPlayer, equipped.itemName, equipped.extraIdentifier, equipped.durability)

    -- Update DB
    SaveKevlarDurability(equipped.uniqueId, equipped.durability)
    MySQL.Async.execute('UPDATE `vkevlars` SET `equipped` = 0 WHERE `unique_id` = @uniqueId', { ['@uniqueId'] = equipped.uniqueId })

    equippedKevlar[src] = nil

    -- Remove armor + visual on client
    TriggerClientEvent("null:kevlar:unequipped", src)
    TriggerClientEvent("null:inventory:update", src)
end)

-- ============================================================================
-- DAMAGE SYNC — Client reports armor loss, update item metadata in-place
-- ============================================================================

RegisterNetEvent("null:kevlar:damageTick", function(newArmor)
    local src = source
    local equipped = equippedKevlar[src]
    if not equipped then return end

    local kevlarConfig = Config.Kevlar.GetKevlarConfig(equipped.itemName)
    if not kevlarConfig then return end

    -- Calculate new durability from armor value
    local ratio = newArmor / kevlarConfig.maxArmor
    local newDurability = math.max(0, math.floor(ratio * kevlarConfig.maxDurability))

    -- Only update if durability decreased
    if newDurability < equipped.durability then
        equipped.durability = newDurability
        SaveKevlarDurability(equipped.uniqueId, newDurability)

        -- Update item metadata in inventory in-place
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            UpdateItemDurability(xPlayer, equipped.itemName, equipped.extraIdentifier, newDurability)
        end

        -- If destroyed, remove item from inventory
        if newDurability <= 0 then
            if xPlayer then
                xPlayer.removeInventoryItem(equipped.itemName, 1, equipped.extraIdentifier)
            end
            MySQL.Async.execute('DELETE FROM `vkevlars` WHERE `unique_id` = @uniqueId', { ['@uniqueId'] = equipped.uniqueId })
            equippedKevlar[src] = nil
            TriggerClientEvent("null:kevlar:destroyed", src)
            TriggerClientEvent("inventory:sendMessage", src, "~r~Votre gilet est détruit")
            TriggerClientEvent("null:inventory:update", src)
        end
    end
end)

-- ============================================================================
-- GET EQUIPPED STATE — For inventory display
-- ============================================================================

ESX.RegisterServerCallback("null:kevlar:getEquipped", function(source, cb)
    local equipped = equippedKevlar[source]
    if equipped then
        cb({
            itemName = equipped.itemName,
            extraIdentifier = equipped.extraIdentifier,
            durability = equipped.durability,
            maxDurability = equipped.maxDurability,
            maxArmor = equipped.maxArmor,
        })
    else
        cb(nil)
    end
end)

-- ============================================================================
-- PLAYER LOAD — Restore equipped kevlar on connect
-- ============================================================================

AddEventHandler("esx:playerLoaded", function(playerId, xPlayer)
    MySQL.Async.fetchAll(
        'SELECT * FROM `vkevlars` WHERE `identifier` = @identifier AND `equipped` = 1 LIMIT 1',
        { ['@identifier'] = xPlayer.identifier },
        function(result)
            if result and #result > 0 then
                local row = result[1]
                local kevlarConfig = Config.Kevlar.GetKevlarConfig(row.item_name)
                if kevlarConfig and row.durability > 0 then
                    local armorValue = math.floor((row.durability / kevlarConfig.maxDurability) * kevlarConfig.maxArmor)

                    -- Find the item in inventory to get its extra.identifier
                    local foundItem = nil
                    for _, item in ipairs(xPlayer.inventory) do
                        if item.name == row.item_name and item.metadata and item.metadata.uniqueId == row.unique_id then
                            foundItem = item
                            break
                        end
                    end

                    local extraId = foundItem and GetKevlarExtraId(foundItem) or nil

                    equippedKevlar[playerId] = {
                        itemName = row.item_name,
                        uniqueId = row.unique_id,
                        extraIdentifier = extraId,
                        durability = row.durability,
                        maxDurability = kevlarConfig.maxDurability,
                        maxArmor = kevlarConfig.maxArmor,
                        identifier = xPlayer.identifier,
                    }

                    -- Update item durability to match DB
                    if foundItem and foundItem.metadata then
                        foundItem.metadata.durability = row.durability
                    end

                    -- Delay so client is ready
                    SetTimeout(5000, function()
                        if equippedKevlar[playerId] then
                            TriggerClientEvent("null:kevlar:equipped", playerId, {
                                itemName = row.item_name,
                                extraIdentifier = extraId,
                                durability = row.durability,
                                maxDurability = kevlarConfig.maxDurability,
                                maxArmor = kevlarConfig.maxArmor,
                                armorValue = armorValue,
                                bproof = kevlarConfig.bproof,
                            })
                        end
                    end)
                else
                    -- Broken kevlar, clean up
                    MySQL.Async.execute('DELETE FROM `vkevlars` WHERE `id` = @id', { ['@id'] = row.id })
                end
            end
        end
    )
end)

-- ============================================================================
-- CLEANUP — Player dropped: save durability
-- ============================================================================

AddEventHandler("esx:playerDropped", function(playerId)
    if equippedKevlar[playerId] then
        local equipped = equippedKevlar[playerId]
        SaveKevlarDurability(equipped.uniqueId, equipped.durability)
        equippedKevlar[playerId] = nil
    end
end)

AddEventHandler("playerDropped", function()
    local src = source
    if equippedKevlar[src] then
        local equipped = equippedKevlar[src]
        SaveKevlarDurability(equipped.uniqueId, equipped.durability)
        equippedKevlar[src] = nil
    end
end)
