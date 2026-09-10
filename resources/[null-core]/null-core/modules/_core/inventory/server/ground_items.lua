-- Ground Items System - Server Side
-- Gère les items au sol côté serveur

GroundItems = {
    items = {},
    nextId = 1,
}

-- Créer un item au sol
function CreateGroundItem(coords, items, weapons, cash, dirtycash, accessories)
    local id = "ground_" .. GroundItems.nextId
    GroundItems.nextId = GroundItems.nextId + 1
    
    GroundItems.items[id] = {
        coords = coords,
        items = items or {},
        weapons = weapons or {},
        accessories = accessories or {},
        cash = cash or 0,
        dirtycash = dirtycash or 0,
        createdAt = os.time(),
    }
        
    -- Sync à tous les joueurs
    TriggerClientEvent('null:groundItems:add', -1, id, GroundItems.items[id])
        
    return id
end

-- Supprimer un item au sol
function DeleteGroundItem(id)
    if not GroundItems.items[id] then
        return false
    end
    
    GroundItems.items[id] = nil
    
    -- Sync à tous les joueurs
    TriggerClientEvent('null:groundItems:remove', -1, id)
    
    return true
end

-- Ajouter un item dans un carton au sol
function AddItemToGroundItem(id, itemType, itemName, count, metadata)
    if not GroundItems.items[id] then
        return false
    end
    
    local groundItem = GroundItems.items[id]
    
    if itemType == "item" then
        local found = false
        for i, item in ipairs(groundItem.items) do
            if item.name == itemName and not item.unique then
                groundItem.items[i].count = groundItem.items[i].count + count
                found = true
                break
            end
        end
        
        if not found then
            table.insert(groundItem.items, {
                name = itemName,
                count = count,
                label = ESX.Items[itemName].label,
                weight = ESX.Items[itemName].weight,
                metadata = metadata or {},
                unique = metadata and metadata.unique or false,
            })
        end
    elseif itemType == "weapon" then
        table.insert(groundItem.weapons, {
            name = itemName,
            label = ESX.GetWeaponLabel(itemName),
            ammo = count,
            metadata = metadata or {},
        })
    elseif itemType == "cash" then
        groundItem.cash = groundItem.cash + count
    elseif itemType == "dirtycash" then
        groundItem.dirtycash = groundItem.dirtycash + count
    end
    
    -- Sync à tous les joueurs
    TriggerClientEvent('null:groundItems:update', -1, id, groundItem)
    
    return true
end

-- Retirer un item d'un carton au sol
function RemoveItemFromGroundItem(id, itemType, itemName, count)
    if not GroundItems.items[id] then
        return false
    end
    
    local groundItem = GroundItems.items[id]
    
    if itemType == "item" then
        for i, item in ipairs(groundItem.items) do
            if item.name == itemName then
                if item.count <= count then
                    table.remove(groundItem.items, i)
                else
                    groundItem.items[i].count = groundItem.items[i].count - count
                end
                break
            end
        end
    elseif itemType == "weapon" then
        for i, weapon in ipairs(groundItem.weapons) do
            if weapon.name == itemName then
                table.remove(groundItem.weapons, i)
                break
            end
        end
    elseif itemType == "accessory" then
        for i, accessory in ipairs(groundItem.accessories) do
            if accessory.name == itemName then
                table.remove(groundItem.accessories, i)
                break
            end
        end
    elseif itemType == "cash" then
        groundItem.cash = math.max(0, groundItem.cash - count)
    elseif itemType == "dirtycash" then
        groundItem.dirtycash = math.max(0, groundItem.dirtycash - count)
    end
    
    -- Vérifier si le carton est vide
    if #groundItem.items == 0 and #groundItem.weapons == 0 and #groundItem.accessories == 0 and groundItem.cash == 0 and groundItem.dirtycash == 0 then
        DeleteGroundItem(id)
        return true
    end
    
    -- Sync à tous les joueurs
    TriggerClientEvent('null:groundItems:update', -1, id, groundItem)
    
    return true
end

-- Callback pour récupérer les données d'un item au sol
ESX.RegisterServerCallback('null:groundItems:getData', function(source, cb, id)
    if not GroundItems.items[id] then
        cb(nil)
        return
    end
    
    cb({
        items = GroundItems.items[id].items,
        loadout = GroundItems.items[id].weapons,
        accessories = GroundItems.items[id].accessories,
        cash = GroundItems.items[id].cash,
        dirtycash = GroundItems.items[id].dirtycash,
        type = "GROUND",
        id = id,
        maxWeight = -1,
    })
end)

-- Event pour déposer un item dans un carton au sol
RegisterNetEvent('null:groundItems:deposit')
AddEventHandler('null:groundItems:deposit', function(id, itemType, itemName, count, metadata)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    if not GroundItems.items[id] then
        return
    end
    
    -- Vérifier que le joueur a l'item
    if itemType == "item" then
        local item = xPlayer.getInventoryItem(itemName)
        if not item or item.count < count then
            return
        end
        
        xPlayer.removeInventoryItem(itemName, count)
        AddItemToGroundItem(id, "item", itemName, count, metadata)
        
    elseif itemType == "weapon" then
        if not xPlayer.hasWeapon(itemName) then
            return
        end
        
        local weaponNum, weapon = xPlayer.getWeapon(itemName)
        xPlayer.removeWeapon(itemName)
        AddItemToGroundItem(id, "weapon", itemName, weapon.ammo, weapon.metadata)
        
    elseif itemType == "cash" then
        local account = xPlayer.getAccount("cash")
        if not account or account.money < count then
            return
        end
        
        xPlayer.removeAccountMoney("cash", count)
        AddItemToGroundItem(id, "cash", nil, count)
        
    elseif itemType == "dirtycash" then
        local account = xPlayer.getAccount("dirtycash")
        if not account or account.money < count then
            return
        end
        
        xPlayer.removeAccountMoney("dirtycash", count)
        AddItemToGroundItem(id, "dirtycash", nil, count)
    end
end)

-- Event pour retirer un item d'un carton au sol
RegisterNetEvent('null:groundItems:withdraw')
AddEventHandler('null:groundItems:withdraw', function(id, itemType, itemName, count)
    local _source = source  -- capture before any async call
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end
    
    if not GroundItems.items[id] then
        return
    end
    
    local groundItem = GroundItems.items[id]
    
    if itemType == "item" then
        local found = false
        local itemData = nil
        
        for i, item in ipairs(groundItem.items) do
            if item.name == itemName then
                if item.count >= count then
                    found = true
                    itemData = item
                end
                break
            end
        end
        
        if not found then
            return
        end
        
        if not xPlayer.canCarryItem(itemName, count) then
            xPlayer.showAdvancedNotification("Informations", "Inventaire", "Vous ne pouvez pas porter plus d'items", 'CHAR_REDSIDE', 0, 7)
            return
        end
        
        xPlayer.addInventoryItem(itemName, count, itemData.metadata)
        RemoveItemFromGroundItem(id, "item", itemName, count)
        
    elseif itemType == "weapon" then
        local found = false
        local weaponData = nil
        
        for i, weapon in ipairs(groundItem.weapons) do
            if weapon.name == itemName then
                found = true
                weaponData = weapon
                break
            end
        end
        
        if not found then
            return
        end
        
        if xPlayer.hasWeapon(itemName) then
            xPlayer.showAdvancedNotification("Informations", "Armes", "Vous avez déjà cette arme", 'CHAR_REDSIDE', 0, 7)
            return
        end
        
        xPlayer.addWeapon(itemName, weaponData.ammo, weaponData.metadata)
        RemoveItemFromGroundItem(id, "weapon", itemName, 1)
        
    elseif itemType == "cash" then
        if groundItem.cash < count then
            return
        end
        
        xPlayer.addAccountMoney("cash", count)
        RemoveItemFromGroundItem(id, "cash", nil, count)
        
    elseif itemType == "dirtycash" then
        if groundItem.dirtycash < count then
            return
        end
        
        xPlayer.addAccountMoney("dirtycash", count)
        RemoveItemFromGroundItem(id, "dirtycash", nil, count)
        
    elseif itemType == "accessory" then
        print("[PICKUP ACCESSORY] === PICKUP DEMANDE ===")
        print("[PICKUP ACCESSORY] groundItem id:", id, "itemName:", tostring(itemName))
        print("[PICKUP ACCESSORY] accessories dans le carton:", #groundItem.accessories)
        for i, acc in ipairs(groundItem.accessories) do
            print("[PICKUP ACCESSORY]   [", i, "] name=", tostring(acc.name), "type=", tostring(acc.type), "label=", tostring(acc.label))
        end

        local found = false
        local accessoryData = nil
        
        for i, accessory in ipairs(groundItem.accessories) do
            if tostring(accessory.name) == tostring(itemName) then
                found = true
                accessoryData = accessory
                break
            end
        end
        
        if not found then
            print("[PICKUP ACCESSORY] ERREUR: accessory '" .. tostring(itemName) .. "' introuvable dans groundItem.accessories")
            return
        end
        
        print("[PICKUP ACCESSORY] Trouvé: type=", tostring(accessoryData.type), "label=", tostring(accessoryData.label))
        print("[PICKUP ACCESSORY] skin type:", type(accessoryData.skin), "skin value:", type(accessoryData.skin) == "table" and json.encode(accessoryData.skin) or tostring(accessoryData.skin))

        -- Ajouter l'accessoire au joueur via vclothes (pas ESX inventory)
        local identifier = xPlayer.identifier
        local accType = accessoryData.type or "unknown"
        local accLabel = accessoryData.label or accType
        local accSkin = accessoryData.skin or {}
        
        if type(accSkin) == "string" then
            print("[PICKUP ACCESSORY] skin est une string, décodage JSON...")
            accSkin = json.decode(accSkin) or {}
        end
        if type(accSkin) ~= "table" then accSkin = {} end

        print("[PICKUP ACCESSORY] INSERT vclothes: identifier=", identifier, "type=", accType, "name=", accLabel, "data keys:", json.encode(accSkin))
        
        MySQL.Async.insert('INSERT INTO vclothes (identifier, type, name, label, data) VALUES (@identifier, @type, @name, @label, @data)', {
            ['@identifier'] = identifier,
            ['@type'] = accType,
            ['@name'] = accLabel,
            ['@label'] = accLabel,
            ['@data'] = json.encode(accSkin)
        }, function(insertId)
            print("[PICKUP ACCESSORY] INSERT résultat: insertId=", tostring(insertId))
            if insertId and insertId > 0 then
                if _G.InventoryClothes and _G.InventoryClothes.ClearCache then
                    _G.InventoryClothes.ClearCache(identifier)
                    print("[PICKUP ACCESSORY] Cache clothes effacé")
                end
                RemoveItemFromGroundItem(id, "accessory", itemName, 1)
                TriggerClientEvent("null:inventory:clearClothesCache", _source)
                TriggerClientEvent("null:inventory:update", _source)
                print("[PICKUP ACCESSORY] Succès, inventaire mis à jour pour source:", _source)
                xPlayer.showAdvancedNotification("Informations", "Vêtements", ("Vous avez récupéré %s"):format(accLabel), 'CHAR_REDSIDE', 0, 7)
            else
                print("[PICKUP ACCESSORY] ERREUR: INSERT vclothes échoué, insertId=", tostring(insertId))
            end
        end)
    end
end)

-- Vérifier si un carton est vide et le supprimer
RegisterNetEvent('null:groundItems:checkAndDelete')
AddEventHandler('null:groundItems:checkAndDelete', function(id)
    if not GroundItems.items[id] then
        return
    end
    
    local groundItem = GroundItems.items[id]
    
    -- Vérifier si le carton est vide
    local isEmpty = true
    
    if groundItem.items and #groundItem.items > 0 then
        isEmpty = false
    end
    
    if groundItem.weapons and #groundItem.weapons > 0 then
        isEmpty = false
    end
    
    if groundItem.accessories and #groundItem.accessories > 0 then
        isEmpty = false
    end
    
    if groundItem.cash and groundItem.cash > 0 then
        isEmpty = false
    end
    
    if groundItem.dirtycash and groundItem.dirtycash > 0 then
        isEmpty = false
    end
    
    -- Si vide, supprimer
    if isEmpty then
        DeleteGroundItem(id)
    end
end)

-- Sync les items au sol à un joueur qui se connecte
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    TriggerClientEvent('null:groundItems:sync', playerId, GroundItems.items)
end)

-- Nettoyer les vieux items au sol (toutes les 5 minutes)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5 * 60 * 1000) -- 5 minutes
        
        local now = os.time()
        local toDelete = {}
        
        for id, groundItem in pairs(GroundItems.items) do
            -- Supprimer les items de plus de 30 minutes
            if (now - groundItem.createdAt) > (30 * 60) then
                table.insert(toDelete, id)
            end
        end
        
        for _, id in ipairs(toDelete) do
            DeleteGroundItem(id)
        end
        
        if #toDelete > 0 then
            print(("[Ground Items] Nettoyage: %d cartons supprimés"):format(#toDelete))
        end
    end
end)
