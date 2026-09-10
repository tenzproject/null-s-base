-- ============================================================================
-- PAWN SHOP - Server Side
-- Player marketplace + NPC default items
-- ============================================================================

local Listings = {}    -- id -> listing data (player listings from DB)
local nextNpcId = -1   -- negative IDs for NPC items

-- ============================================================================
-- SQL Migration
-- ============================================================================
CreateThread(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `pawnshop_listings` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(60) NOT NULL,
            `seller_name` VARCHAR(60) NOT NULL DEFAULT 'Inconnu',
            `item_name` VARCHAR(100) NOT NULL,
            `item_label` VARCHAR(100) NOT NULL,
            `count` INT NOT NULL DEFAULT 1,
            `price_per_unit` INT NOT NULL DEFAULT 1,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `pawnshop_sales` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(60) NOT NULL,
            `amount` INT NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    Wait(500)
    LoadListingsFromDB()
end)

function LoadListingsFromDB()
    MySQL.Async.fetchAll("SELECT * FROM pawnshop_listings", {}, function(result)
        Listings = {}
        for _, row in ipairs(result) do
            Listings[row.id] = {
                id = row.id,
                identifier = row.identifier,
                sellerName = row.seller_name,
                itemName = row.item_name,
                itemLabel = row.item_label,
                count = row.count,
                pricePerUnit = row.price_per_unit,
                isNpc = false,
            }
        end
        null.DebugPrint("[PawnShop] Loaded " .. #result .. " listings from DB")
    end)
end

-- ============================================================================
-- Build NPC listings from config
-- ============================================================================
local function GetNpcListings()
    local npc = {}
    local id = -1
    for _, item in ipairs(Config.PawnShop.DefaultItems or {}) do
        table.insert(npc, {
            id = id,
            identifier = "npc",
            sellerName = "Boutique",
            itemName = item.name,
            itemLabel = item.label,
            count = item.stock, -- -1 = unlimited
            pricePerUnit = item.price,
            isNpc = true,
        })
        id = id - 1
    end
    return npc
end

-- ============================================================================
-- Build data payload for NUI
-- ============================================================================
local function BuildPawnShopData(playerId, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(nil) end

    local allListings = GetNpcListings()
    for _, listing in pairs(Listings) do table.insert(allListings, listing) end

    local myListings = {}
    for _, listing in pairs(Listings) do
        if listing.identifier == xPlayer.identifier then table.insert(myListings, listing) end
    end

    local playerInv = {}
    for _, item in pairs(xPlayer.getInventory()) do
        if item.count > 0 and not Config.PawnShop.BlackListItem[item.name] and not ESX.ContribItem(item.name) then
            table.insert(playerInv, { name = item.name, label = item.label or item.name, count = item.count })
        end
    end

    local cash = xPlayer.getAccount('cash').money
    local bank = xPlayer.getAccount('bank').money

    MySQL.Async.fetchAll("SELECT * FROM pawnshop_sales WHERE identifier = @id", {
        ["@id"] = xPlayer.identifier,
    }, function(salesResult)
        local pendingSales = {}
        local pendingTotal = 0
        for _, row in ipairs(salesResult or {}) do
            table.insert(pendingSales, { id = row.id, amount = row.amount })
            pendingTotal = pendingTotal + row.amount
        end
        cb({
            listings = allListings,
            myListings = myListings,
            playerInventory = playerInv,
            pendingSales = pendingSales,
            pendingSalesTotal = pendingTotal,
            money = { cash = cash, bank = bank },
            maxListings = Config.PawnShop.MaxListingsPerPlayer or 8,
            saleTax = Config.PawnShop.SaleTax or 5,
        })
    end)
end

local function RefreshClient(playerId)
    BuildPawnShopData(playerId, function(data)
        if data then TriggerClientEvent("null:pawnshop:update", playerId, data) end
    end)
end

-- ============================================================================
-- Callback: Open pawnshop UI
-- ============================================================================
ESX.RegisterServerCallback('null:pawnshop:getData', function(source, cb)
    BuildPawnShopData(source, function(data) cb(data) end)
end)

-- ============================================================================
-- NUI Callbacks (registered via client forwarding)
-- ============================================================================

-- Buy item (NPC or player listing)
RegisterNetEvent("null:pawnshop:buy")
AddEventHandler("null:pawnshop:buy", function(listingId, quantity, paymentType, isNpc)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    quantity = tonumber(quantity) or 1
    if quantity < 1 then return end

    local listing = nil
    if isNpc then
        -- Find NPC listing by id
        for _, npc in ipairs(GetNpcListings()) do
            if npc.id == listingId then
                listing = npc
                break
            end
        end
    else
        listing = Listings[listingId]
    end

    if not listing then
        TriggerClientEvent("null:pawnshop:buyResult", src, { success = false, message = "Annonce introuvable" })
        return
    end

    -- Check stock
    if not isNpc and listing.count < quantity then
        TriggerClientEvent("null:pawnshop:buyResult", src, { success = false, message = "Stock insuffisant" })
        return
    end

    -- Can't buy own listing
    if not isNpc and listing.identifier == xPlayer.identifier then
        TriggerClientEvent("null:pawnshop:buyResult", src, { success = false, message = "Vous ne pouvez pas acheter votre propre annonce" })
        return
    end

    local totalCost = listing.pricePerUnit * quantity

    -- Check money
    local account = paymentType == 'bank' and 'bank' or 'cash'
    if xPlayer.getAccount(account).money < totalCost then
        TriggerClientEvent("null:pawnshop:buyResult", src, { success = false, message = "Fonds insuffisants" })
        return
    end

    -- Check carry
    if not xPlayer.canCarryItem(listing.itemName, quantity) then
        TriggerClientEvent("null:pawnshop:buyResult", src, { success = false, message = "Inventaire plein" })
        return
    end

    -- Process purchase
    xPlayer.removeAccountMoney(account, totalCost, {title = 'Achat Marche', description = 'Achat au marche aux puces', category = 'purchase'})
    xPlayer.addInventoryItem(listing.itemName, quantity)

    if not isNpc then
        -- Credit seller (with tax deducted)
        local tax = Config.PawnShop.SaleTax or 5
        local sellerAmount = math.floor(totalCost * (100 - tax) / 100)

        local tPlayer = ESX.GetPlayerFromIdentifier(listing.identifier)
        if tPlayer then
            tPlayer.addAccountMoney('bank', sellerAmount, {title = 'Vente Marche', description = 'Vente au marche aux puces', category = 'salary'})
            tPlayer.showNotification("Vous avez vendu ~g~x" .. quantity .. " " .. listing.itemLabel .. "~s~ pour ~g~$" .. sellerAmount)
        else
            MySQL.Async.execute("INSERT INTO pawnshop_sales (identifier, amount) VALUES (@id, @amount)", {
                ["@id"] = listing.identifier,
                ["@amount"] = sellerAmount,
            })
        end

        -- Update stock
        listing.count = listing.count - quantity
        if listing.count <= 0 then
            Listings[listingId] = nil
            MySQL.Async.execute("DELETE FROM pawnshop_listings WHERE id = @id", { ["@id"] = listingId })
        else
            MySQL.Async.execute("UPDATE pawnshop_listings SET count = @count WHERE id = @id", {
                ["@id"] = listingId,
                ["@count"] = listing.count,
            })
        end
    end

    TriggerClientEvent("null:pawnshop:buyResult", src, { success = true, message = "Achat de x" .. quantity .. " " .. listing.itemLabel .. " effectue !" })
    RefreshClient(src)
end)

-- Sell item (create listing)
RegisterNetEvent("null:pawnshop:sell")
AddEventHandler("null:pawnshop:sell", function(itemName, itemLabel, count, pricePerUnit)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    count = tonumber(count) or 0
    pricePerUnit = tonumber(pricePerUnit) or 0
    if count < 1 or pricePerUnit < 1 then
        TriggerClientEvent("null:pawnshop:sellResult", src, { success = false, message = "Valeurs invalides" })
        return
    end

    -- Check blacklist
    if Config.PawnShop.BlackListItem[itemName] or ESX.ContribItem(itemName) then
        TriggerClientEvent("null:pawnshop:sellResult", src, { success = false, message = "Cet item ne peut pas etre vendu" })
        return
    end

    -- Check max listings
    local myCount = 0
    for _, l in pairs(Listings) do
        if l.identifier == xPlayer.identifier then myCount = myCount + 1 end
    end
    if myCount >= (Config.PawnShop.MaxListingsPerPlayer or 8) then
        TriggerClientEvent("null:pawnshop:sellResult", src, { success = false, message = "Nombre max d'annonces atteint" })
        return
    end

    -- Check inventory
    local invItem = xPlayer.getInventoryItem(itemName)
    if not invItem or invItem.count < count then
        TriggerClientEvent("null:pawnshop:sellResult", src, { success = false, message = "Vous n'avez pas assez de cet item" })
        return
    end

    -- Remove from inventory
    xPlayer.removeInventoryItem(itemName, count)

    -- Get player name
    local charName = xPlayer.getName() or "Inconnu"

    -- Insert into DB
    MySQL.Async.execute("INSERT INTO pawnshop_listings (identifier, seller_name, item_name, item_label, count, price_per_unit) VALUES (@id, @name, @itemName, @itemLabel, @count, @price)", {
        ["@id"] = xPlayer.identifier,
        ["@name"] = charName,
        ["@itemName"] = itemName,
        ["@itemLabel"] = itemLabel,
        ["@count"] = count,
        ["@price"] = pricePerUnit,
    }, function()
        -- Reload from DB to get auto-increment ID
        LoadListingsFromDB()
        Wait(200)
        TriggerClientEvent("null:pawnshop:sellResult", src, { success = true, message = "Annonce creee: x" .. count .. " " .. itemLabel })
        RefreshClient(src)
    end)
end)

-- Cancel listing
RegisterNetEvent("null:pawnshop:cancel")
AddEventHandler("null:pawnshop:cancel", function(listingId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local listing = Listings[listingId]
    if not listing or listing.identifier ~= xPlayer.identifier then
        TriggerClientEvent("null:pawnshop:cancelResult", src, { success = false, message = "Annonce introuvable" })
        return
    end

    -- Return items
    xPlayer.addInventoryItem(listing.itemName, listing.count)

    -- Remove from DB
    Listings[listingId] = nil
    MySQL.Async.execute("DELETE FROM pawnshop_listings WHERE id = @id", { ["@id"] = listingId })

    TriggerClientEvent("null:pawnshop:cancelResult", src, { success = true, message = "Annonce annulee, items rendus" })
    RefreshClient(src)
end)

-- Collect all pending sales
RegisterNetEvent("null:pawnshop:collectAll")
AddEventHandler("null:pawnshop:collectAll", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    MySQL.Async.fetchAll("SELECT * FROM pawnshop_sales WHERE identifier = @id", {
        ["@id"] = xPlayer.identifier,
    }, function(result)
        if not result or #result == 0 then
            TriggerClientEvent("null:pawnshop:collectResult", src, { success = false, message = "Aucun revenu en attente" })
            return
        end
        local total = 0
        for _, row in ipairs(result) do total = total + row.amount end
        xPlayer.addAccountMoney('bank', total, { title = 'Encaissement Marche', description = 'Gains de ventes au marche', category = 'salary' })
        MySQL.Async.execute("DELETE FROM pawnshop_sales WHERE identifier = @id", { ["@id"] = xPlayer.identifier })
        TriggerClientEvent("null:pawnshop:collectResult", src, { success = true, message = "Encaisse: $" .. total })
        RefreshClient(src)
    end)
end)

-- Notify player on login if they have pending sales
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    Wait(3000)
    MySQL.Async.fetchAll("SELECT SUM(amount) as total FROM pawnshop_sales WHERE identifier = @id", {
        ["@id"] = xPlayer.identifier,
    }, function(result)
        if result and result[1] and result[1].total and result[1].total > 0 then
            xPlayer.showNotification("Vous avez ~g~$" .. result[1].total .. "~s~ de ventes en attente au marche aux puces !")
        end
    end)
end)