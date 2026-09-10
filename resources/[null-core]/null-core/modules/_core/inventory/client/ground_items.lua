
GroundItems = {
    items = {},
    nearbyItems = {},
    currentNearby = nil,
}

local GROUND_ITEM_PROP = `prop_cs_cardbox_01`
local INTERACTION_DISTANCE = 2.5
local REFRESH_INTERVAL = 1000

local function BuildGroundItemInteractionLines(groundItem)
    local lines = {}
    
    if groundItem.items and #groundItem.items > 0 then
        for _, item in ipairs(groundItem.items) do
            table.insert(lines, {
                left = item.label or item.name,
                right = "x" .. tostring(item.count),
            })
        end
    end
    
    if groundItem.weapons and #groundItem.weapons > 0 then
        for _, weapon in ipairs(groundItem.weapons) do
            table.insert(lines, {
                left = weapon.label or weapon.name,
                right = tostring(weapon.ammo or 0) .. " balles",
            })
        end
    end
    
    if groundItem.accessories and #groundItem.accessories > 0 then
        for _, acc in ipairs(groundItem.accessories) do
            table.insert(lines, {
                left = acc.label or acc.name,
                right = "x1",
            })
        end
    end
    
    if groundItem.cash and groundItem.cash > 0 then
        table.insert(lines, {
            left = "Argent propre",
            right = "$" .. tostring(groundItem.cash),
        })
    end
    
    if groundItem.dirtycash and groundItem.dirtycash > 0 then
        table.insert(lines, {
            left = "Argent sale",
            right = "$" .. tostring(groundItem.dirtycash),
        })
    end
    
    return lines
end

local function UpdateGroundItem3DInteraction(id, groundItem)
    local interactionId = "ground_item_" .. tostring(id)
    
    if Exist3DInteraction(interactionId) then
        Remove3DInteraction(interactionId)
    end
    
    local lines = BuildGroundItemInteractionLines(groundItem)
    if #lines == 0 then return end
    
    local coords = groundItem.coords
    if type(coords) ~= 'vector3' then
        coords = vector3(coords.x, coords.y, coords.z)
    end
    
    Add3DInteraction({
        id = interactionId,
        type = "multi",
        coords = coords + vector3(0, 0, -0.7),
        maxDistance = 5.0,
        maxDistance2 = 1.5,
        text = {
            title = "Carton            [ALT]",
            lines = lines,
        },
    })
end

local function RemoveGroundItem3DInteraction(id)
    local interactionId = "ground_item_" .. tostring(id)
    if Exist3DInteraction(interactionId) then
        Remove3DInteraction(interactionId)
    end
end

Citizen.CreateThread(function()
    while true do
        local sleep = REFRESH_INTERVAL
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        if NullInventory.isOpen then
            GroundItems.nearbyItems = {}
            GroundItems.currentNearby = nil
            
            for id, groundItem in pairs(GroundItems.items) do
                local distance = #(playerCoords - groundItem.coords)
                
                if distance <= INTERACTION_DISTANCE then
                    table.insert(GroundItems.nearbyItems, {
                        id = id,
                        distance = distance,
                        data = groundItem
                    })
                end
            end
            
            table.sort(GroundItems.nearbyItems, function(a, b)
                return a.distance < b.distance
            end)
            
            if #GroundItems.nearbyItems > 0 then
                GroundItems.currentNearby = GroundItems.nearbyItems[1].id
            end
        end
        
        Citizen.Wait(sleep)
    end
end)

RegisterNetEvent('null:groundItems:add')
AddEventHandler('null:groundItems:add', function(id, data)
    
    if GroundItems.items[id] then
        return
    end
    
    RequestModel(GROUND_ITEM_PROP)
    while not HasModelLoaded(GROUND_ITEM_PROP) do
        Citizen.Wait(10)
    end
    
    local prop = CreateObject(GROUND_ITEM_PROP, data.coords.x, data.coords.y, data.coords.z - 1.0, false, false, false)
    SetEntityAsMissionEntity(prop, true, true)
    PlaceObjectOnGroundProperly(prop)
    FreezeEntityPosition(prop, true)
    
    GroundItems.items[id] = {
        coords = data.coords,
        items = data.items,
        weapons = data.weapons,
        accessories = data.accessories or {},
        cash = data.cash or 0,
        dirtycash = data.dirtycash or 0,
        prop = prop,
    }
    
    UpdateGroundItem3DInteraction(id, GroundItems.items[id])
end)

RegisterNetEvent('null:groundItems:remove')
AddEventHandler('null:groundItems:remove', function(id)
    if not GroundItems.items[id] then
        return
    end
    
    local groundItem = GroundItems.items[id]
    
    if DoesEntityExist(groundItem.prop) then
        DeleteEntity(groundItem.prop)
    end
    
    RemoveGroundItem3DInteraction(id)
    
    GroundItems.items[id] = nil
    
    if NullInventory.isOpen and NullInventory.currentChest and NullInventory.currentChest.data.type == "GROUND" then
        if NullInventory.currentChest.data.id == id then
            TriggerEvent("null:inventory:closeinv")
        end
    end
end)

RegisterNetEvent('null:groundItems:update')
AddEventHandler('null:groundItems:update', function(id, data)
    if not GroundItems.items[id] then
        return
    end
    
    GroundItems.items[id].items = data.items
    GroundItems.items[id].weapons = data.weapons
    GroundItems.items[id].accessories = data.accessories or GroundItems.items[id].accessories or {}
    GroundItems.items[id].cash = data.cash or 0
    GroundItems.items[id].dirtycash = data.dirtycash or 0
    
    UpdateGroundItem3DInteraction(id, GroundItems.items[id])
    
    if NullInventory.isOpen and NullInventory.currentChest and NullInventory.currentChest.data.type == "GROUND" then
        if NullInventory.currentChest.data.id == id then
            local weight = 0
            for _, item in pairs(data.items or {}) do
                weight = weight + ((item.weight or 1) * (item.count or 1))
            end
            for _, weapon in pairs(data.weapons or {}) do
                weight = weight + 5
            end
            
            local rightInventory = FormatInventoryForUI(data)
            TriggerEvent("esx:refreshRightInventory", rightInventory)
            TriggerEvent("inventory:right:changeWeight", weight)
        end
    end
end)

RegisterNetEvent('null:groundItems:sync')
AddEventHandler('null:groundItems:sync', function(items)
    for id, groundItem in pairs(GroundItems.items) do
        RemoveGroundItem3DInteraction(id)
        if DoesEntityExist(groundItem.prop) then
            DeleteEntity(groundItem.prop)
        end
    end
    
    GroundItems.items = {}
    
    for id, data in pairs(items) do
        TriggerEvent('null:groundItems:add', id, data)
    end
end)

function GetGroundItemIdFromEntity(entity)
    if not entity or not DoesEntityExist(entity) then
        return nil
    end
    
    for id, groundItem in pairs(GroundItems.items) do
        if groundItem.prop == entity then
            return id
        end
    end
    
    return nil
end

local PICKUP_DISTANCE = 1.5 

local function IsPlayerNearGroundItem(groundItemId)
    if not GroundItems.items[groundItemId] then
        return false
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local itemCoords = GroundItems.items[groundItemId].coords
    local distance = #(playerCoords - itemCoords)
    
    return distance <= PICKUP_DISTANCE
end

function PickupSingleItem(groundItemId, itemType, itemName, count, label)
    if not groundItemId or not GroundItems.items[groundItemId] then
        return
    end
    
    if not IsPlayerNearGroundItem(groundItemId) then
        ESX.ShowNotification("~r~Vous êtes trop loin du carton")
        return
    end
    
    TriggerServerEvent('null:groundItems:withdraw', groundItemId, itemType, itemName, count)
    
    if itemType == 'cash' or itemType == 'dirtycash' then
        ESX.ShowNotification(("~g~Vous avez récupéré ~s~$%d ~g~de %s"):format(count, label or itemName))
    else
        ESX.ShowNotification(("~g~Vous avez récupéré ~s~%dx %s"):format(count, label or itemName))
    end
    
    Wait(500)
    TriggerServerEvent('null:groundItems:checkAndDelete', groundItemId)
end

function PickupGroundItem(groundItemId)
    if not groundItemId or not GroundItems.items[groundItemId] then
        return
    end
    
    if not IsPlayerNearGroundItem(groundItemId) then
        ESX.ShowNotification("~r~Vous êtes trop loin du carton")
        return
    end
    
    local groundItem = GroundItems.items[groundItemId]
    
    ESX.TriggerServerCallback('null:groundItems:getData', function(data)
        if not data then
            ESX.ShowNotification("~r~Erreur: Impossible de récupérer les items")
            return
        end
        
        local itemsPickedUp = {}
        
        if data.items and #data.items > 0 then
            for _, item in ipairs(data.items) do
                TriggerServerEvent('null:groundItems:withdraw', groundItemId, 'item', item.name, item.count)
                table.insert(itemsPickedUp, ("%dx %s"):format(item.count, item.label or item.name))
            end
        end
        
        if data.loadout and #data.loadout > 0 then
            for _, weapon in ipairs(data.loadout) do
                TriggerServerEvent('null:groundItems:withdraw', groundItemId, 'weapon', weapon.name, 1)
                table.insert(itemsPickedUp, weapon.label or weapon.name)
            end
        end
        
        if data.accessories and #data.accessories > 0 then
            for _, accessory in ipairs(data.accessories) do
                TriggerServerEvent('null:groundItems:withdraw', groundItemId, 'accessory', accessory.name, 1)
                table.insert(itemsPickedUp, accessory.label or accessory.name)
            end
        end
        
        if data.cash and data.cash > 0 then
            TriggerServerEvent('null:groundItems:withdraw', groundItemId, 'cash', 'cash', data.cash)
            table.insert(itemsPickedUp, ("$%d argent propre"):format(data.cash))
        end
        
        if data.dirtycash and data.dirtycash > 0 then
            TriggerServerEvent('null:groundItems:withdraw', groundItemId, 'dirtycash', 'dirtycash', data.dirtycash)
            table.insert(itemsPickedUp, ("$%d argent sale"):format(data.dirtycash))
        end
        
        if #itemsPickedUp > 0 then
            ESX.ShowNotification(("~g~Vous avez récupéré: ~s~%s"):format(table.concat(itemsPickedUp, ", ")))
            
            Wait(500)
            TriggerServerEvent('null:groundItems:checkAndDelete', groundItemId)
        else
            ESX.ShowNotification("~o~Le carton est vide")
        end
    end, groundItemId)
end

function GetGroundItemSubmenuActions(groundItemId)
    if not groundItemId or not GroundItems.items[groundItemId] then
        return {}
    end
    
    local groundItem = GroundItems.items[groundItemId]
    local submenuActions = {}
    
    table.insert(submenuActions, {
        "Tout ramasser",
        function()
            PickupGroundItem(groundItemId)
        end
    })
    
    if groundItem.items and #groundItem.items > 0 then
        for _, item in ipairs(groundItem.items) do
            table.insert(submenuActions, {
                ("%s (x%d)"):format(item.label or item.name, item.count),
                function()
                    PickupSingleItem(groundItemId, 'item', item.name, item.count, item.label)
                end
            })
        end
    end
    
    if groundItem.weapons and #groundItem.weapons > 0 then
        for _, weapon in ipairs(groundItem.weapons) do
            table.insert(submenuActions, {
                ("%s (%d balles)"):format(weapon.label or weapon.name, weapon.ammo or 0),
                function()
                    PickupSingleItem(groundItemId, 'weapon', weapon.name, 1, weapon.label)
                end
            })
        end
    end
    
    
    if groundItem.cash and groundItem.cash > 0 then
        table.insert(submenuActions, {
            ("Argent propre ($%d)"):format(groundItem.cash),
            function()
                PickupSingleItem(groundItemId, 'cash', 'cash', groundItem.cash, 'Argent propre')
            end
        })
    end
    
    if groundItem.dirtycash and groundItem.dirtycash > 0 then
        table.insert(submenuActions, {
            ("Argent sale ($%d)"):format(groundItem.dirtycash),
            function()
                PickupSingleItem(groundItemId, 'dirtycash', 'dirtycash', groundItem.dirtycash, 'Argent sale')
            end
        })
    end
    
    return submenuActions
end

exports('GetGroundItemIdFromEntity', GetGroundItemIdFromEntity)
exports('PickupGroundItem', PickupGroundItem)
exports('PickupSingleItem', PickupSingleItem)
exports('GetGroundItemSubmenuActions', GetGroundItemSubmenuActions)
