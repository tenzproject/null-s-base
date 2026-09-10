while not _G.NullInventoryUILoaded do
    Wait(0)
end

local PlayerInventoryClient = {}

function PlayerInventoryClient.GetItem(itemName)
    local playerData = ESX.GetPlayerData()
    if not playerData or not playerData.inventory then return nil end
    
    for _, item in pairs(playerData.inventory) do
        if item.name == itemName and item.count > 0 then
            return item
        end
    end
    
    return nil
end

function PlayerInventoryClient.HasItem(itemName, count)
    count = count or 1
    local item = PlayerInventoryClient.GetItem(itemName)
    return item and item.count >= count
end

function PlayerInventoryClient.GetInventory()
    local playerData = ESX.GetPlayerData()
    return playerData and playerData.inventory or {}
end

function PlayerInventoryClient.GetItemCount(itemName)
    local item = PlayerInventoryClient.GetItem(itemName)
    return item and item.count or 0
end

function PlayerInventoryClient.GetWeapon(weaponName)
    local playerData = ESX.GetPlayerData()
    if not playerData or not playerData.loadout then return nil end
    
    for _, weapon in pairs(playerData.loadout) do
        if weapon.name == weaponName then
            return weapon
        end
    end
    
    return nil
end

function PlayerInventoryClient.HasWeapon(weaponName)
    return PlayerInventoryClient.GetWeapon(weaponName) ~= nil
end

function PlayerInventoryClient.GetLoadout()
    local playerData = ESX.GetPlayerData()
    return playerData and playerData.loadout or {}
end

function PlayerInventoryClient.GetMoney(moneyType)
    moneyType = moneyType or "cash"
    return ESX.getAccountMoney(moneyType) or 0
end

function PlayerInventoryClient.HasMoney(amount, moneyType)
    return PlayerInventoryClient.GetMoney(moneyType) >= (tonumber(amount) or 0)
end

function PlayerInventoryClient.GetWeight()
    return ESX.GetCurrentWeight and ESX.GetCurrentWeight() or 0
end

function PlayerInventoryClient.GetMaxWeight()
    return ESX.GetMaxWeight and ESX.GetMaxWeight() or (Config.Inventory.MaxWeight or 24)
end

function PlayerInventoryClient.CanCarry(additionalWeight)
    return (PlayerInventoryClient.GetWeight() + additionalWeight) <= PlayerInventoryClient.GetMaxWeight()
end

function PlayerInventoryClient.GetFreeWeight()
    return PlayerInventoryClient.GetMaxWeight() - PlayerInventoryClient.GetWeight()
end

function PlayerInventoryClient.IsOpen()
    return NullInventory and NullInventory.isOpen or false
end

function PlayerInventoryClient.Open(secondInventory)
    if NullInventory then
        NullInventory.Open(secondInventory)
    end
end

function PlayerInventoryClient.Close()
    if NullInventory then
        NullInventory.Close()
    end
end

function PlayerInventoryClient.SetCanOpen(canOpen)
    if NullInventory then
        NullInventory.canOpen = canOpen
    end
end

function PlayerInventoryClient.CanOpen()
    return NullInventory and NullInventory.canOpen or false
end

function PlayerInventoryClient.GetEquippedAccessory(accessoryType)
    if NullInventory and NullInventory.equippedClothes then
        return NullInventory.equippedClothes[accessoryType]
    end
    return nil
end

function PlayerInventoryClient.HasEquippedAccessory(accessoryType)
    return PlayerInventoryClient.GetEquippedAccessory(accessoryType) ~= nil
end

function PlayerInventoryClient.GetAllEquippedAccessories()
    return NullInventory and NullInventory.equippedClothes or {}
end

exports("GetItem", PlayerInventoryClient.GetItem)
exports("HasItem", PlayerInventoryClient.HasItem)
exports("GetInventory", PlayerInventoryClient.GetInventory)
exports("GetItemCount", PlayerInventoryClient.GetItemCount)

exports("GetWeapon", PlayerInventoryClient.GetWeapon)
exports("HasWeapon", PlayerInventoryClient.HasWeapon)
exports("GetLoadout", PlayerInventoryClient.GetLoadout)

exports("GetMoney", PlayerInventoryClient.GetMoney)
exports("HasMoney", PlayerInventoryClient.HasMoney)

exports("GetWeight", PlayerInventoryClient.GetWeight)
exports("GetMaxWeight", PlayerInventoryClient.GetMaxWeight)
exports("CanCarry", PlayerInventoryClient.CanCarry)
exports("GetFreeWeight", PlayerInventoryClient.GetFreeWeight)

exports("IsInventoryOpen", PlayerInventoryClient.IsOpen)
exports("OpenInventory", PlayerInventoryClient.Open)
exports("CloseInventory", PlayerInventoryClient.Close)
exports("SetCanOpenInventory", PlayerInventoryClient.SetCanOpen)
exports("CanOpenInventory", PlayerInventoryClient.CanOpen)

exports("GetEquippedAccessory", PlayerInventoryClient.GetEquippedAccessory)
exports("HasEquippedAccessory", PlayerInventoryClient.HasEquippedAccessory)
exports("GetAllEquippedAccessories", PlayerInventoryClient.GetAllEquippedAccessories)

_G.PlayerInventoryClient = PlayerInventoryClient

null.InitPrint("Player Inventory Client Bridge loaded")

return PlayerInventoryClient
