while not _G.InventoryClothesLoaded do
    Wait(0)
end

--null.InitPrint("Inventory Server modules loaded")

function GetPlayerInventoryForUI(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return nil end
    
    local inventory = {
        items = {},
        weapons = {},
        accessories = {},
        cash = xPlayer.getAccount("cash").money,
        dirtycash = xPlayer.getAccount("dirtycash").money,
    }
    
    for _, item in pairs(xPlayer.getInventory()) do
        if item.count > 0 then
            local canMove = not Config.Inventory.LockedItems[item.name]
            local itemData = {
                type = "item",
                name = item.name,
                label = item.label,
                count = item.count,
                weight = item.weight or 1,
                canMove = canMove,
                metadata = item.metadata,
                extra = item.extra,
                unique = item.unique,
            }
            table.insert(inventory.items, itemData)
        end
    end
    
    for _, weapon in pairs(xPlayer.getLoadout()) do
        local canMove = not Config.Inventory.LockedWeapons[weapon.name] and not weapon.permanent
        local weaponData = {
            type = "weapon",
            name = weapon.name,
            label = weapon.label,
            count = 1,
            canMove = canMove,
            metadata = weapon.metadata,
            permanent = weapon.permanent,
            durability = Config.AmmunationShop.repairSysteme and weapon.durability or 0,
            serialnumber = weapon.serialnumber,
        }
        table.insert(inventory.weapons, weaponData)
    end
    
    return inventory
end

function GetPlayerWeight(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return 0 end
    
    local weight = 0
    
    for _, item in pairs(xPlayer.getInventory()) do
        if item.count > 0 then
            weight = weight + ((item.weight or 1) * item.count)
        end
    end
    
    for _, weapon in pairs(xPlayer.getLoadout()) do
        if not ESX.ContribWeapon(weapon.name) and not weapon.permanent then
            weight = weight + (ESX.GetWeaponWeight(weapon.name) or Config.WeaponDefaultWeight)
        end
    end
    
    return weight
end

ESX.RegisterServerCallback('null:getCoffre', function(source, cb, chestName, chestType, clientMaxWeight)
    local invType
    
    if chestType == "trunk" then
        invType = "VEHICLE"
    elseif chestType == "glovebox" then
        invType = "VEHICLE_GLOVE_BOX"
    elseif chestType == "storage" then
        invType = "SOCIETY"
    elseif chestType ~= nil and string.match(chestType, "%u") then
        invType = chestType
    else
        invType = "SOCIETY"
    end
    
    local maxWeight = clientMaxWeight
    
    InventoryStorage.Open(source, chestName, invType, maxWeight, function(success, data, cacheKey, weight, mw)
        if success then
            data.savename = chestName
            data.cacheKey = cacheKey
            cb(data, chestName, weight)
        else
            TriggerClientEvent("inventory:sendMessage", source, "~r~" .. (data or "Erreur"))
            cb(nil)
        end
    end)
end)

ESX.RegisterServerCallback('null:getCoffre2', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil and Config.GroupeHighPerm[xPlayer.getGroup()] == true then
        MySQL.Async.fetchAll('SELECT coffre, id FROM vstorage WHERE name = @name', {
			['@name'] = "itemlist"
		}, function (result)
			if result[1] then
                local coffre = {
                    items = {},
                    clothes = {},
                    maxWeight = -1,
                    dirtycash = 9999999999,
                    cash = 9999999999,
                    loadout = {},
                }
                local coffre2 = {
                    items = {},
                    clothes = {},
                    maxWeight = -1,
                    dirtycash = 9999999999,
                    cash = 9999999999,
                    loadout = {},
                }
                
                table.insert(coffre.clothes, {type="top", name="top", id=1,label="Vetement Haut", data={
                    ["torso_1"] = 15, ["torso_2"] = 0
                }})
                table.insert(coffre.clothes, {type="shoes", name="shoes", id=1, label="Vetement Chaussure", data={
                    ["shoes_1"] = 15, ["shoes_2"] = 0
                }})
                table.insert(coffre.clothes, {type="pants", name="pants", id=1, label="Vetement Bas", data={
                    ["pants_1"] = 15, ["pants_2"] = 0
                }})
                table.insert(coffre2.clothes, {type="top", name="top", id=1, label="Vetement Haut", data={
                    ["torso_1"] = 15, ["torso_2"] = 0
                }})
                table.insert(coffre2.clothes, {type="shoes", name="shoes", id=1, label="Vetement Chaussure", data={
                    ["shoes_1"] = 15, ["shoes_2"] = 0
                }})
                table.insert(coffre2.clothes, {type="pants", name="pants", id=1, label="Vetement Bas", data={
                    ["pants_1"] = 15, ["pants_2"] = 0
                }})

                for k,v in pairs(ESX.GetWeaponList()) do
                    table.insert(coffre.loadout, {name=v.name, label=v.label})
                    table.insert(coffre2.loadout, {name=v.name})
                end

                for k,v in pairs(ESX.GetItemList()) do
                    table.insert(coffre.items, {name=k, weight=v.weight or 1, count=999999,label=v.label})
                    table.insert(coffre2.items, {name=k, weight=v.weight or 1, count=999999})
                end

                MySQL.Async.execute("UPDATE `vstorage` SET `coffre` = '"..json.encode(coffre2).."' WHERE `name` = 'itemlist'", {}, function()  end)

				cb(coffre, tonumber(result[1].id))
			end
		end) 
    end
end)

ESX.RegisterServerCallback("null:fouiller", function(source, cb, player)
    local tPlayer = ESX.GetPlayerFromId(player)
    if tPlayer then 
        local inventoryplayer = {
            id = player,
            identifier = player,
            weight = 0,
            maxWeight = 1000,
            items = {},
            loadout = {},
            cash = tPlayer.getAccount("cash").money,
            dirtycash = tPlayer.getAccount("cash").money
        }

        for k,v in pairs(tPlayer.getInventory()) do
            table.insert(inventoryplayer.items, {name=v.name, label=ESX.GetItemLabel(v.name), count=v.count})
        end

        for k,v in pairs(tPlayer.getLoadout()) do
            table.insert(inventoryplayer.loadout, {name=v.name, label=ESX.GetWeaponLabel(v.name),metadata=v.metadata})
        end
        cb(inventoryplayer)
    end
    cb(false)
end)

ESX.RegisterServerCallback('null:getCoffreForRefresh', function(source, cb, id, invType)
    local cacheKey = ("%s_%s"):format(invType, id)
    local cached = InventoryCache.Get(cacheKey)
    
    if cached then
        cb(cached.data, id)
    else
        cb({})
    end
end)

RegisterNetEvent("null:closeCoffre", function(name)
    local playerId = source
    
    local vehicleKey = "VEHICLE_" .. name
    local societyKey = "SOCIETY_" .. name
    
    InventoryStorage.Close(playerId, vehicleKey)
    InventoryStorage.Close(playerId, societyKey)
end)

ESX.RegisterServerCallback('null:inv:transfertCashToStorage', function(source, cb, id, count, moneyType, invType)
    local cacheKey = ("%s_%s"):format(invType, id)
    InventoryTransfers.DepositMoney(source, cacheKey, count, moneyType, function(success)
        cb(success)
    end)
end)

ESX.RegisterServerCallback('null:inv:transfertStorageToCash', function(source, cb, id, count, moneyType, invType)
    local cacheKey = ("%s_%s"):format(invType, id)
    InventoryTransfers.WithdrawMoney(source, cacheKey, count, moneyType, function(success)
        cb(success)
    end)
end)

ESX.RegisterServerCallback('null:inv:transfertItemToStorage', function(source, cb, id, name, count, invType, maxWeight, extra)
    local cacheKey = ("%s_%s"):format(invType, id)
    InventoryTransfers.DepositItem(source, cacheKey, name, count, extra, function(success)
        cb(success)
    end)
end)

ESX.RegisterServerCallback('null:inv:transfertStorageToItem', function(source, cb, id, name, count, invType, extra)
    local cacheKey = ("%s_%s"):format(invType, id)
    InventoryTransfers.WithdrawItem(source, cacheKey, name, count, extra, function(success)
        cb(success)
    end)
end)

ESX.RegisterServerCallback('null:inv:transfertWeaponToStorage', function(source, cb, id, name, invType, metadata, maxWeight)
    local cacheKey = ("%s_%s"):format(invType, id)
    InventoryTransfers.DepositWeapon(source, cacheKey, name, metadata, function(success)
        cb(success)
    end)
end)

ESX.RegisterServerCallback('null:inv:transferStorageToWeapon', function(source, cb, id, name, invType, metadata)
    local cacheKey = ("%s_%s"):format(invType, id)
    InventoryTransfers.WithdrawWeapon(source, cacheKey, name, function(success)
        cb(success)
    end)
end)

ESX.RegisterServerCallback('null:inv:getClothe', function(source, cb)
    InventoryClothes.Load(source, cb)
end)

ESX.RegisterServerCallback('null:inv:getClotheSkin', function(source, cb, clotheId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or not clotheId then return cb(nil) end
    MySQL.Async.fetchAll('SELECT data FROM vclothes WHERE id = @id AND identifier = @identifier', {
        ['@id'] = clotheId,
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        if result and result[1] and result[1].data then
            local raw = result[1].data
            local parsed = type(raw) == "string" and json.decode(raw) or raw
            cb(parsed)
        else
            cb(nil)
        end
    end)
end)

RegisterNetEvent("ZgegFramework:equipedClothes", function(clothes)
    InventoryClothes.SaveEquipped(source, clothes)
end)

RegisterNetEvent("ZgegFramework:clothes:rename", function(name, id)
    local playerId = source
    
    print("[INVENTORY DEBUG] ZgegFramework:clothes:rename triggered")
    print("[INVENTORY DEBUG] Player ID:", playerId, "Clothe ID:", id, "New Name:", name)
    
    InventoryClothes.Rename(playerId, id, name, function(success)
        if success then
            print("[INVENTORY SUCCESS] Clothe renamed successfully in database")
            
            -- Invalidate clothes cache and trigger client update
            TriggerClientEvent("inventory:clotheRenamed", playerId, id, name)
            TriggerClientEvent("inventory:sendMessage", playerId, "~g~Vêtement renommé: " .. name)
        else
            print("[INVENTORY ERROR] Failed to rename clothe")
        end
    end)
end)

RegisterNetEvent("ZgegFramework:clothes:transfere", function(id, target)
    InventoryClothes.Transfer(source, id, target, function() end)
end)

RegisterNetEvent("esx:clothes:delete", function(clotheId)
    InventoryClothes.Remove(source, clotheId, function() end)
end)

-- Rename Item Event
RegisterNetEvent("inventory:renameItem", function(itemData, newName)
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    
    print("[INVENTORY DEBUG] inventory:renameItem triggered")
    print("[INVENTORY DEBUG] Player ID:", playerId)
    print("[INVENTORY DEBUG] Item Data:", json.encode(itemData))
    print("[INVENTORY DEBUG] New Name:", newName)
    
    if not xPlayer then
        print("[INVENTORY ERROR] xPlayer not found for ID:", playerId)
        return
    end
    
    if not itemData or not itemData.name then
        print("[INVENTORY ERROR] Invalid itemData:", json.encode(itemData))
        return
    end
    
    if not newName or newName == "" then
        print("[INVENTORY ERROR] Invalid newName:", newName)
        return
    end
    
    local item, itemIndex = xPlayer.getInventoryItem(itemData.name)
    if not item or not itemIndex or item.count <= 0 then
        print("[INVENTORY ERROR] Item not found in inventory:", itemData.name)
        return
    end
    
    print("[INVENTORY DEBUG] Current item:", json.encode(item))
    print("[INVENTORY DEBUG] Item index:", itemIndex)
    
    -- Modify metadata directly in the player's inventory
    if not xPlayer.inventory[itemIndex].metadata then
        xPlayer.inventory[itemIndex].metadata = {}
    end
    xPlayer.inventory[itemIndex].metadata.title = newName
    
    print("[INVENTORY DEBUG] Metadata updated directly:", json.encode(xPlayer.inventory[itemIndex].metadata))
    print("[INVENTORY SUCCESS] Item renamed successfully (in-place)")
    
    -- Send updated metadata directly to client
    TriggerClientEvent("inventory:itemRenamed", playerId, itemData.name, itemIndex, newName)
    
    -- Notify client
    TriggerClientEvent("inventory:sendMessage", playerId, "~g~Item renommé: " .. newName)
end)

-- Rename Weapon Event
RegisterNetEvent("inventory:renameWeapon", function(weaponName, newName)
    local playerId = source
    local xPlayer = ESX.GetPlayerFromId(playerId)
    
    print("[INVENTORY DEBUG] inventory:renameWeapon triggered")
    print("[INVENTORY DEBUG] Player ID:", playerId)
    print("[INVENTORY DEBUG] Weapon Name:", weaponName)
    print("[INVENTORY DEBUG] New Name:", newName)
    
    if not xPlayer then
        print("[INVENTORY ERROR] xPlayer not found for ID:", playerId)
        return
    end
    
    if not weaponName or weaponName == "" then
        print("[INVENTORY ERROR] Invalid weaponName:", weaponName)
        return
    end
    
    if not newName or newName == "" then
        print("[INVENTORY ERROR] Invalid newName:", newName)
        return
    end
    
    -- Find weapon in loadout and get its index
    local weaponIndex = nil
    
    for i, w in pairs(xPlayer.loadout) do
        if type(w) == "table" and w.name == weaponName then
            weaponIndex = i
            break
        end
    end
    
    if not weaponIndex then
        print("[INVENTORY ERROR] Weapon not found in loadout:", weaponName)
        return
    end
    
    print("[INVENTORY DEBUG] Weapon found at index:", weaponIndex)
    print("[INVENTORY DEBUG] Current weapon:", json.encode(xPlayer.loadout[weaponIndex]))
    
    -- Modify metadata directly in the player's loadout
    if not xPlayer.loadout[weaponIndex].metadata then
        xPlayer.loadout[weaponIndex].metadata = {}
    end
    xPlayer.loadout[weaponIndex].metadata.title = newName
    
    print("[INVENTORY DEBUG] Metadata updated directly:", json.encode(xPlayer.loadout[weaponIndex].metadata))
    print("[INVENTORY SUCCESS] Weapon renamed successfully (in-place)")
    
    -- Send updated metadata directly to client
    TriggerClientEvent("inventory:weaponRenamed", playerId, weaponName, weaponIndex, newName)
    
    -- Notify client
    TriggerClientEvent("inventory:sendMessage", playerId, "~g~Arme renommée: " .. newName)
end)

-- ============================================================================
-- ALL ITEMS — Founder-only: get full item/weapon list
-- ============================================================================

local function HasInventoryAdminPermission(xPlayer, permission)
    if not xPlayer or not permission then return false end

    local group = xPlayer.getGroup and xPlayer.getGroup() or xPlayer.group
    if not group or group == "user" then return false end

    if Config.Admin and Config.Admin.RolePermissions and Config.Admin.RolePermissions[group] then
        return Config.Admin.RolePermissions[group][string.lower(permission)] == true
    end

    if Config.GroupeHighPerm and Config.GroupeHighPerm[group] == true then
        return true
    end

    if not Config.Admin or not Config.Admin.PermissionsGrade then return false end
    if not Config.GroupeGrade or not Config.GroupeGrade[group] then return false end

    local requiredGrade = nil
    for permName, grade in pairs(Config.Admin.PermissionsGrade) do
        if string.lower(permName) == string.lower(permission) then
            requiredGrade = grade
            break
        end
    end

    return requiredGrade ~= nil and Config.GroupeGrade[group].grade >= requiredGrade
end

ESX.RegisterServerCallback('newInventory:getAllItems', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ success = false, reason = "player_not_found", items = {} }) end

    if not HasInventoryAdminPermission(xPlayer, "liste_items_armes") then
        return cb({ success = false, reason = "missing_permission", items = {} })
    end

    local items = {}

    local itemList = ESX.GetItemList and ESX.GetItemList() or ESX.Items or {}
    for name, v in pairs(itemList or {}) do
        table.insert(items, {
            type = 'item',
            name = name,
            label = v.label or name,
            count = 999999,
            weight = v.weight or 1,
        })
    end

    local weaponList = ESX.GetWeaponList and ESX.GetWeaponList() or ESX.Weapons or {}
    for _, v in pairs(weaponList or {}) do
        table.insert(items, {
            type = 'weapon',
            name = v.name,
            label = v.label or v.name,
            count = 1,
            weight = ESX.GetWeaponWeight(v.name) or Config.WeaponDefaultWeight or 2,
        })
    end

    -- Money accounts
    table.insert(items, { type = 'account', name = 'cash',      label = 'Argent propre',  count = 999999999 })
    table.insert(items, { type = 'account', name = 'dirtycash', label = 'Argent sale',    count = 999999999 })

    table.sort(items, function(a, b) return (a.label or '') < (b.label or '') end)

    cb({ success = true, items = items })
end)

-- Take an item/weapon/money from the all-items infinite list
ESX.RegisterServerCallback('newInventory:allItemsTake', function(source, cb, itemName, itemType, count)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end
    if not (Config.GroupeHighPerm[xPlayer.getGroup()] == true) then return cb(false) end

    count = tonumber(count) or 1

    if itemType == 'account' then
        xPlayer.addAccountMoney(itemName, count)
        cb(true)
    elseif itemType == 'weapon' then
        xPlayer.addWeapon(itemName, 999)
        cb(true)
    else
        xPlayer.addInventoryItem(itemName, count)
        cb(true)
    end
end)

-- Deposit (destroy) an item into the all-items void
ESX.RegisterServerCallback('newInventory:allItemsDeposit', function(source, cb, itemName, itemType, count)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end
    if not (Config.GroupeHighPerm[xPlayer.getGroup()] == true) then return cb(false) end

    count = tonumber(count) or 1

    if itemType == 'account' then
        xPlayer.removeAccountMoney(itemName, count)
        cb(true)
    elseif itemType == 'weapon' then
        xPlayer.removeWeapon(itemName)
        cb(true)
    else
        xPlayer.removeInventoryItem(itemName, count)
        cb(true)
    end
end)

exports("GetPlayerInventoryForUI", GetPlayerInventoryForUI)
exports("GetPlayerWeight", GetPlayerWeight)

--null.InitPrint("Inventory Core Module loaded")
