--[[
    PropInteract — Server
    Validates interactions, bridges item giving/removal to ESX inventory.
    
    Events:
        null:propInteract:validate   — Server-side validation of an action
        null:propInteract:giveItem   — Give item to player after scene action
        null:propInteract:removeItem — Remove item from player inventory
        null:propInteract:complete   — Scene completed, process results
]]

-- ============================================================
-- ITEM MANAGEMENT
-- ============================================================

RegisterNetEvent('null:propInteract:giveItem')
AddEventHandler('null:propInteract:giveItem', function(itemName, count, metadata)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    count = count or 1
    
    if xPlayer.canCarryItem(itemName, count) then
        xPlayer.addInventoryItem(itemName, count, metadata)
        TriggerClientEvent('null:propInteract:itemResult', source, {
            success = true,
            item = itemName,
            count = count,
        })
    else
        TriggerClientEvent('null:propInteract:itemResult', source, {
            success = false,
            item = itemName,
            reason = "inventory_full",
        })
    end
end)

RegisterNetEvent('null:propInteract:removeItem')
AddEventHandler('null:propInteract:removeItem', function(itemName, count)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    count = count or 1
    local item = xPlayer.getInventoryItem(itemName)
    
    if item and item.count >= count then
        xPlayer.removeInventoryItem(itemName, count)
        TriggerClientEvent('null:propInteract:itemResult', source, {
            success = true,
            item = itemName,
            count = -count,
        })
    else
        TriggerClientEvent('null:propInteract:itemResult', source, {
            success = false,
            item = itemName,
            reason = "not_enough",
        })
    end
end)

-- ============================================================
-- SCENE COMPLETION
-- ============================================================

RegisterNetEvent('null:propInteract:complete')
AddEventHandler('null:propInteract:complete', function(sceneId, results)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    -- Process results (give items)
    if results and type(results) == "table" then
        for _, result in ipairs(results) do
            if result.item and result.count and result.count > 0 then
                if xPlayer.canCarryItem(result.item, result.count) then
                    xPlayer.addInventoryItem(result.item, result.count, result.metadata)
                end
            end
        end
    end
end)

-- ============================================================
-- VALIDATION
-- ============================================================

RegisterNetEvent('null:propInteract:validate')
AddEventHandler('null:propInteract:validate', function(sceneId, actionId, data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    -- Basic validation — extend per scene type
    -- Check required items in inventory
    if data and data.requiredItems then
        for _, req in ipairs(data.requiredItems) do
            local item = xPlayer.getInventoryItem(req.name)
            if not item or item.count < (req.count or 1) then
                TriggerClientEvent('null:propInteract:validateResult', source, {
                    valid = false,
                    reason = "missing_item",
                    item = req.name,
                })
                return
            end
        end
    end
    
    TriggerClientEvent('null:propInteract:validateResult', source, {
        valid = true,
        sceneId = sceneId,
        actionId = actionId,
    })
end)

-- ============================================================
-- EXPORTS
-- ============================================================

-- Server-side: trigger a prop scene on a specific client
exports('OpenPlayerPropScene', function(playerId, config)
    TriggerClientEvent('null:propInteract:open', playerId, config)
end)

exports('ClosePlayerPropScene', function(playerId)
    TriggerClientEvent('null:propInteract:close', playerId)
end)
