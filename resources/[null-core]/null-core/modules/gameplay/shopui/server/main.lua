-- ============================================================================
-- SHOP UI - Server Side
-- Handles transactions, money checks, item giving
-- ============================================================================

local Locales = {
    NoMoney = "Vous n'avez pas assez d'argent pour acheter %s.",
    CantCarry = "Vous ne pouvez pas porter le %s.",
    HasWeapon = "Vous possédez déjà un(e) %s.",
    PurchaseSuccess = "Article(s) acheté(s) avec succès pour $%s.",
}

local MAX_QUANTITY = 100

local catalog = nil

local function buildCatalog()
    catalog = {}
    local sources = {
        Config.AmmunationShop and Config.AmmunationShop.storeConfig,
        Config.LTD and Config.LTD.StoreConfig,
        Config.Supermarket247 and Config.Supermarket247.StoreConfig,
        Config.RobsLiquor and Config.RobsLiquor.StoreConfig,
    }
    for _, store in pairs(sources) do
        if store and store.Items then
            for _, it in ipairs(store.Items) do
                if it.name and tonumber(it.price) then
                    local key = it.name
                    if not catalog[key] or tonumber(it.price) < catalog[key].price then
                        catalog[key] = {
                            price = math.floor(tonumber(it.price)),
                            label = it.label or it.name,
                            isWeapon = it.name:sub(1, 7):upper() == "WEAPON_",
                        }
                    end
                end
            end
        end
    end
end

local function GetCatalogItem(name)
    if not catalog then buildCatalog() end
    return catalog[name]
end

local function GetPlayer(source)
    if not source or source == 0 then return nil end
    return ESX.GetPlayerFromId(source)
end

local function CanCarryItem(source, itemName, itemQuantity)
    local xPlayer = GetPlayer(source)
    if not xPlayer then return false end
    return xPlayer.canCarryItem(itemName, itemQuantity)
end

local function AddItem(source, itemName, itemQuantity)
    local xPlayer = GetPlayer(source)
    if not xPlayer then return false end
    return xPlayer.addInventoryItem(itemName, itemQuantity)
end

local function HasWeapon(source, weaponName)
    local xPlayer = GetPlayer(source)
    if not xPlayer then return false end
    return xPlayer.hasWeapon(weaponName)
end

local function AddWeapon(source, weaponName)
    local xPlayer = GetPlayer(source)
    if not xPlayer then return false end
    return xPlayer.addWeapon(weaponName, 120)
end

-- Process a cart transaction (buy multiple items)
ESX.RegisterServerCallback('null:shopui:processTransaction', function(source, cb, paymentType, cartArray)
    if not source or source == 0 then return cb(false, "Invalid source") end
    if not cartArray or #cartArray == 0 then return cb(false, "Empty cart") end

    local xPlayer = GetPlayer(source)
    if not xPlayer then return cb(false, "Player not found") end

    local accountType = paymentType == "bank" and "bank" or "cash"
    local totalCartPrice = 0
    local errors = {}

    for _, item in ipairs(cartArray) do
        local itemName = type(item) == "table" and tostring(item.name) or nil
        local entry = itemName and GetCatalogItem(itemName) or nil

        if not entry then
            goto continue
        end

        local label = entry.label
        local isWeapon = entry.isWeapon
        local quantity = isWeapon and 1 or math.floor(tonumber(item.quantity) or 0)
        if quantity < 1 then goto continue end
        if quantity > MAX_QUANTITY then quantity = MAX_QUANTITY end

        local totalItemPrice = entry.price * quantity

        local availableMoney = xPlayer.getAccount(accountType).money
        if availableMoney < totalItemPrice then
            table.insert(errors, Locales.NoMoney:format(label))
            goto continue
        end

        if isWeapon then
            if HasWeapon(source, itemName) then
                table.insert(errors, Locales.HasWeapon:format(label))
            else
                xPlayer.removeAccountMoney(accountType, totalItemPrice)
                AddWeapon(source, itemName)
                totalCartPrice = totalCartPrice + totalItemPrice
            end
        else
            if CanCarryItem(source, itemName, quantity) then
                xPlayer.removeAccountMoney(accountType, totalItemPrice)
                AddItem(source, itemName, quantity)
                totalCartPrice = totalCartPrice + totalItemPrice
            else
                table.insert(errors, Locales.CantCarry:format(label))
            end
        end

        ::continue::
    end

    -- Send error notifications
    for _, err in ipairs(errors) do
        xPlayer.showNotification(err, "error")
    end

    if totalCartPrice > 0 then
        xPlayer.showNotification(Locales.PurchaseSuccess:format(totalCartPrice), "success")

        local cash = xPlayer.getAccount("cash").money
        local bank = xPlayer.getAccount("bank").money
        cb(true, { cash = cash, bank = bank })
    else
        cb(false, "No items purchased")
    end
end)

-- Get player money for UI display
ESX.RegisterServerCallback('null:shopui:getMoney', function(source, cb)
    local xPlayer = GetPlayer(source)
    if not xPlayer then return cb({ cash = 0, bank = 0 }) end

    cb({
        cash = xPlayer.getAccount("cash").money,
        bank = xPlayer.getAccount("bank").money,
    })
end)

null.InitPrint("ShopUI Server Module loaded")
