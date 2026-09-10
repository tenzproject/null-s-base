while not _G.InventoryClothesLoaded do
    Wait(0)
end

local PlayerInventory = {}

function PlayerInventory.AddItem(playerId, itemName, count, metadata)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    count = tonumber(count) or 1
    if count <= 0 then return false end
    
    xPlayer.addInventoryItem(itemName, count, metadata)
    return true
end

function PlayerInventory.RemoveItem(playerId, itemName, count, itemId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    count = tonumber(count) or 1
    if count <= 0 then return false end
    
    local item = xPlayer.getInventoryItem(itemName, itemId)
    if not item or item.count < count then return false end
    
    xPlayer.removeInventoryItem(itemName, count, itemId)
    return true
end

function PlayerInventory.GetItem(playerId, itemName, itemId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return nil end
    
    return xPlayer.getInventoryItem(itemName, itemId)
end

function PlayerInventory.HasItem(playerId, itemName, count)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    count = tonumber(count) or 1
    local item = xPlayer.getInventoryItem(itemName)
    
    return item and item.count >= count
end

function PlayerInventory.GetInventory(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return {} end
    
    return xPlayer.getInventory()
end

function PlayerInventory.AddWeapon(playerId, weaponName, ammo, metadata, permanent, serialNumber, durability, components)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    if PlayerInventory.HasWeapon(playerId, weaponName) then
        return false
    end
    
    xPlayer.addWeapon(weaponName, ammo or 0, metadata, permanent or false, serialNumber, durability or 0.0, components or {})
    return true
end

function PlayerInventory.RemoveWeapon(playerId, weaponName)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    if not PlayerInventory.HasWeapon(playerId, weaponName) then
        return false
    end
    
    xPlayer.removeWeapon(weaponName)
    return true
end

function PlayerInventory.HasWeapon(playerId, weaponName)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    local loadout = xPlayer.getLoadout()
    for _, weapon in pairs(loadout) do
        if type(weapon) == "table" and weapon.name == weaponName then
            return true
        end
    end
    
    return false
end

function PlayerInventory.GetWeapon(playerId, weaponName)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return nil end
    
    local loadout = xPlayer.getLoadout()
    for _, weapon in pairs(loadout) do
        if type(weapon) == "table" and weapon.name == weaponName then
            return weapon
        end
    end
    
    return nil
end

function PlayerInventory.GetLoadout(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return {} end
    
    return xPlayer.getLoadout()
end

function PlayerInventory.AddMoney(playerId, amount, moneyType)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end
    
    moneyType = moneyType or "cash"
    xPlayer.addAccountMoney(moneyType, amount)
    return true
end

function PlayerInventory.RemoveMoney(playerId, amount, moneyType)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end
    
    moneyType = moneyType or "cash"
    local currentMoney = xPlayer.getAccount(moneyType).money
    
    if currentMoney < amount then return false end
    
    xPlayer.removeAccountMoney(moneyType, amount)
    return true
end

function PlayerInventory.GetMoney(playerId, moneyType)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return 0 end
    
    moneyType = moneyType or "cash"
    return xPlayer.getAccount(moneyType).money
end

function PlayerInventory.HasMoney(playerId, amount, moneyType)
    return PlayerInventory.GetMoney(playerId, moneyType) >= (tonumber(amount) or 0)
end

function PlayerInventory.GetWeight(playerId)
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
            weight = weight + ESX.GetWeaponWeigh(weapon.name)
        end
    end
    
    return weight
end

function PlayerInventory.GetMaxWeight(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return 0 end
    
    return xPlayer.getMaxWeight and xPlayer.getMaxWeight() or (Config.Inventory.MaxWeight or 24)
end

function PlayerInventory.CanCarry(playerId, additionalWeight)
    local currentWeight = PlayerInventory.GetWeight(playerId)
    local maxWeight = PlayerInventory.GetMaxWeight(playerId)
    
    return (currentWeight + additionalWeight) <= maxWeight
end

function PlayerInventory.TransferItem(fromPlayerId, toPlayerId, itemName, count)
    if not PlayerInventory.HasItem(fromPlayerId, itemName, count) then
        return false
    end
    
    local item = PlayerInventory.GetItem(fromPlayerId, itemName)
    local itemWeight = item and item.weight or 1
    
    if not PlayerInventory.CanCarry(toPlayerId, itemWeight * count) then
        return false
    end
    
    if PlayerInventory.RemoveItem(fromPlayerId, itemName, count) then
        return PlayerInventory.AddItem(toPlayerId, itemName, count, item and item.metadata)
    end
    
    return false
end

function PlayerInventory.TransferWeapon(fromPlayerId, toPlayerId, weaponName)
    if not PlayerInventory.HasWeapon(fromPlayerId, weaponName) then
        return false
    end
    
    if PlayerInventory.HasWeapon(toPlayerId, weaponName) then
        return false
    end
    
    local weapon = PlayerInventory.GetWeapon(fromPlayerId, weaponName)
    if not weapon then return false end
    
    if PlayerInventory.RemoveWeapon(fromPlayerId, weaponName) then
        return PlayerInventory.AddWeapon(
            toPlayerId,
            weaponName,
            0,
            weapon.metadata,
            weapon.permanent,
            weapon.serialnumber,
            weapon.durability,
            weapon.components
        )
    end
    
    return false
end

exports("AddItem", PlayerInventory.AddItem)
exports("RemoveItem", PlayerInventory.RemoveItem)
exports("GetItem", PlayerInventory.GetItem)
exports("HasItem", PlayerInventory.HasItem)
exports("GetInventory", PlayerInventory.GetInventory)

exports("AddWeapon", PlayerInventory.AddWeapon)
exports("RemoveWeapon", PlayerInventory.RemoveWeapon)
exports("HasWeapon", PlayerInventory.HasWeapon)
exports("GetWeapon", PlayerInventory.GetWeapon)
exports("GetLoadout", PlayerInventory.GetLoadout)

exports("AddMoney", PlayerInventory.AddMoney)
exports("RemoveMoney", PlayerInventory.RemoveMoney)
exports("GetMoney", PlayerInventory.GetMoney)
exports("HasMoney", PlayerInventory.HasMoney)

exports("GetWeight", PlayerInventory.GetWeight)
exports("GetMaxWeight", PlayerInventory.GetMaxWeight)
exports("CanCarry", PlayerInventory.CanCarry)

exports("TransferItem", PlayerInventory.TransferItem)
exports("TransferWeapon", PlayerInventory.TransferWeapon)

_G.PlayerInventory = PlayerInventory

--null.InitPrint("Player Inventory Bridge loaded")

return PlayerInventory
