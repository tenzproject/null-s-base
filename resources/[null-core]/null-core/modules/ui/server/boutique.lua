local BoutiqueServer = {}

-- Base URL for boutique images (from null-ui resource)
local IMG_BASE = "nui://null-cache/images/boutique/"

CreateThread(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `tebex_Null_fidelite` (
            `license` VARCHAR(64) NOT NULL,
            `havebuy` INT NOT NULL DEFAULT 0,
            `totalbuy` INT NOT NULL DEFAULT 0,
            PRIMARY KEY (`license`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})
end)

-- ============================================================================
-- HELPERS - FiveM identifier & coins from tebex_players_wallet
-- ============================================================================

local function GetFivemId(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, v in pairs(identifiers) do
        local before, after = v:match("([^:]+):([^:]+)")
        if before == "fivem" then
            return after
        end
    end
    return nil
end

local function GetPlayerCoins(fivemId, cb)
    MySQL.Async.fetchAll("SELECT SUM(points) as total FROM tebex_players_wallet WHERE identifiers = @id", {
        ['@id'] = fivemId
    }, function(result)
        local coins = 0
        if result and result[1] and result[1].total then
            coins = tonumber(result[1].total) or 0
        end
        cb(coins)
    end)
end

local function GetPlayerHistory(fivemId, cb)
    MySQL.Async.fetchAll("SELECT * FROM tebex_players_wallet WHERE identifiers = @id ORDER BY id DESC LIMIT 50", {
        ['@id'] = fivemId
    }, function(result)
        local history = {}
        if result then
            for _, row in ipairs(result) do
                table.insert(history, {
                    id = tostring(row.id),
                    label = row.transaction or "Transaction",
                    price = math.abs(tonumber(row.points) or 0),
                    date = row.date or "",
                    category = row.currency or "Points",
                    isCredit = (tonumber(row.points) or 0) > 0,
                })
            end
        end
        cb(history)
    end)
end

local function DeductCoins(fivemId, xPlayer, amount, transaction, cb)
    GetPlayerCoins(fivemId, function(current)
        if current < amount then
            cb(false, current)
            return
        end
        LiteMySQL:Insert('tebex_players_wallet', {
            identifiers = fivemId,
            idunique = xPlayer.getIdunique(),
            transaction = transaction,
            price = 0,
            currency = 'Points',
            points = -amount,
        })
        GetPlayerCoins(fivemId, function(newCoins)
            cb(true, newCoins)
        end)
    end)
end

local function GetPlayerFidelity(fivemId, cb)
    MySQL.Async.fetchAll("SELECT * FROM tebex_Null_fidelite WHERE license = @license", {
        ['@license'] = fivemId
    }, function(result)
        local havebuy = 0
        local totalbuy = 0
        if result and result[1] then
            havebuy = tonumber(result[1].havebuy) or 0
            totalbuy = tonumber(result[1].totalbuy) or 0
        end
        cb(havebuy, totalbuy)
    end)
end

local function HasAlreadyPurchased(fivemId, label, cb)
    MySQL.Async.fetchAll("SELECT * FROM tebex_players_wallet WHERE (`transaction` LIKE @transaction AND `identifiers` = @identifiers)", {
        ['@identifiers'] = fivemId,
        ['@transaction'] = "%" .. label .. "%"
    }, function(result)
        cb(result and result[1] ~= nil)
    end)
end

-- ============================================================================
-- DAILY SHOP - Seed-based generation (date + player identifier)
-- ============================================================================

local function seededRandom(seed)
    seed = (seed * 1103515245 + 12345) % 2147483648
    return seed, (seed % 10000) / 10000
end

function BoutiqueServer.GenerateDailyShop(playerIdentifier)
    local today = os.date("%Y%m%d")
    local seedStr = today .. (playerIdentifier or "default")
    local seed = 0
    for i = 1, #seedStr do
        seed = seed + string.byte(seedStr, i) * (i * 31)
    end

    local dailyItems = {}
    local usedIndices = { vehicles = {}, weapons = {} }
    local targetRarities = { "common", "rare", "epic", "epic", "legendary", "ultimate" }

    for i = #targetRarities, 2, -1 do
        seed, _ = seededRandom(seed)
        local j = (seed % i) + 1
        targetRarities[i], targetRarities[j] = targetRarities[j], targetRarities[i]
    end

    for i = 1, 6 do
        local targetRarity = targetRarities[i]
        local rand
        seed, rand = seededRandom(seed)

        local isVehicle = rand < 0.6
        local pool = isVehicle and Config.Boutique.DailyShopPool.vehicles or Config.Boutique.DailyShopPool.weapons
        local poolType = isVehicle and "vehicles" or "weapons"

        local candidates = {}
        for idx, item in ipairs(pool) do
            if item.rarity == targetRarity and not usedIndices[poolType][idx] then
                table.insert(candidates, { item = item, idx = idx })
            end
        end

        if #candidates == 0 then
            for idx, item in ipairs(pool) do
                if not usedIndices[poolType][idx] then
                    table.insert(candidates, { item = item, idx = idx })
                end
            end
        end

        if #candidates == 0 then
            pool = isVehicle and Config.Boutique.DailyShopPool.weapons or Config.Boutique.DailyShopPool.vehicles
            poolType = isVehicle and "weapons" or "vehicles"
            for idx, item in ipairs(pool) do
                if not usedIndices[poolType][idx] then
                    table.insert(candidates, { item = item, idx = idx })
                end
            end
        end

        if #candidates > 0 then
            seed, rand = seededRandom(seed)
            local chosen = candidates[(seed % #candidates) + 1]
            usedIndices[poolType][chosen.idx] = true

            seed, rand = seededRandom(seed)
            local discounts = { 0, 0, 0, 10, 15, 20 }
            local discount = discounts[(seed % #discounts) + 1]
            local originalPrice = chosen.item.basePrice
            local finalPrice = math.floor(originalPrice * (1 - discount / 100))
            local finalImage = ""

            if chosen.item.model then
                finalImage = "nui://null-cache/images/vehicles/" .. (chosen.item.model or "") .. ".webp"
            else
                finalImage = "nui://null-cache/images/weapons/" .. chosen.item.name .. ".webp"
            end

            table.insert(dailyItems, {
                id = "daily_" .. i,
                label = chosen.item.label,
                description = chosen.item.description,
                price = finalPrice,
                originalPrice = discount > 0 and originalPrice or nil,
                discount = discount > 0 and discount or nil,
                type = chosen.item.model and "vehicle" or "weapon",
                model = chosen.item.model,
                name = chosen.item.name,
                image = finalImage,
                rarity = chosen.item.rarity,
                stats = chosen.item.stats,
            })
        end
    end

    return dailyItems
end

-- ============================================================================
-- NIGHT MARKET SYSTEM
-- ============================================================================

-- Load persisted NightMarket state from cache (survives restarts)
local NightMarket = Cache.Get("nightmarket") or {
    active = false,
    cards = {},
    expiresAt = 0,
    startedBy = nil,
}

local function SaveNightMarketCache()
    Cache.Set("nightmarket", {
        active = NightMarket.active,
        cards = NightMarket.cards,
        expiresAt = NightMarket.expiresAt,
        startedBy = NightMarket.startedBy,
    })
end

local NIGHTMARKET_DURATION = 7 * 24 * 60 * 60 -- 1 week in seconds
local NIGHTMARKET_CARD_COUNT = 5
local NIGHTMARKET_DISCOUNTS = {
    common = { min = 30, max = 50 },
    rare = { min = 25, max = 45 },
    epic = { min = 20, max = 40 },
    legendary = { min = 15, max = 35 },
    ultimate = { min = 10, max = 30 },
}

function BoutiqueServer.StartNightMarket(staffName)
    if NightMarket.active and os.time() < NightMarket.expiresAt then
        return false, "Un NightMarket est déjà en cours !"
    end

    -- Build combined pool
    local allItems = {}
    for _, item in ipairs(Config.Boutique.DailyShopPool.vehicles) do
        table.insert(allItems, { item = item, type = "vehicle" })
    end
    for _, item in ipairs(Config.Boutique.DailyShopPool.weapons) do
        table.insert(allItems, { item = item, type = "weapon" })
    end

    -- Shuffle
    for i = #allItems, 2, -1 do
        local j = math.random(1, i)
        allItems[i], allItems[j] = allItems[j], allItems[i]
    end

    -- Pick target rarities: 1 ultimate/legendary, 2 epic/rare, 2 random
    local targetRarities = {}
    local highRarities = {}
    local midRarities = {}
    local lowRarities = {}
    for idx, entry in ipairs(allItems) do
        local r = entry.item.rarity
        if r == "ultimate" or r == "legendary" then
            table.insert(highRarities, idx)
        elseif r == "epic" or r == "rare" then
            table.insert(midRarities, idx) 
        else
            table.insert(lowRarities, idx)
        end
    end

    local cards = {}
    local usedIdx = {}

    -- Pick 1 high rarity
    local function pickFrom(pool)
        for _, idx in ipairs(pool) do
            if not usedIdx[idx] then
                usedIdx[idx] = true
                return allItems[idx]
            end
        end
        return nil
    end

    local function pickAny()
        for idx, entry in ipairs(allItems) do
            if not usedIdx[idx] then
                usedIdx[idx] = true
                return entry
            end
        end
        return nil
    end

    -- 1 high, 2 mid, 2 any
    local picks = {}
    picks[1] = pickFrom(highRarities)
    picks[2] = pickFrom(midRarities)
    picks[3] = pickFrom(midRarities)
    picks[4] = pickAny()
    picks[5] = pickAny()

    -- Shuffle the picks order
    for i = #picks, 2, -1 do
        local j = math.random(1, i)
        picks[i], picks[j] = picks[j], picks[i]
    end

    local sessionId = tostring(os.time())

    for i = 1, NIGHTMARKET_CARD_COUNT do
        local entry = picks[i]
        if entry then
            local rarity = entry.item.rarity
            local discountRange = NIGHTMARKET_DISCOUNTS[rarity] or { min = 20, max = 40 }
            local discount = math.random(discountRange.min, discountRange.max)
            local originalPrice = entry.item.basePrice
            local finalPrice = math.floor(originalPrice * (1 - discount / 100))

            local cardImage = ""
            if entry.type == "vehicle" and entry.item.model then
                cardImage = "nui://null-cache/images/vehicles/" .. entry.item.model .. ".webp"
            elseif entry.type == "weapon" and entry.item.name then
                cardImage = "nui://null-cache/images/weapons/" .. entry.item.name .. ".webp"
            end

            table.insert(cards, {
                id = "nm_" .. sessionId .. "_" .. i,
                label = entry.item.label,
                description = entry.item.description,
                price = finalPrice,
                originalPrice = originalPrice,
                discount = discount,
                type = entry.type,
                model = entry.item.model,
                name = entry.item.name,
                image = cardImage,
                rarity = rarity,
            })
        end
    end

    NightMarket.active = true
    NightMarket.cards = cards
    NightMarket.expiresAt = os.time() + NIGHTMARKET_DURATION
    NightMarket.startedBy = staffName or "Staff"

    SaveNightMarketCache()

    -- Notify all online players
    TriggerClientEvent('null:nightmarket:started', -1)

    return true, "NightMarket lancé avec succès ! Durée : 7 jours."
end

function BoutiqueServer.StopNightMarket()
    NightMarket.active = false
    NightMarket.cards = {}
    NightMarket.expiresAt = 0
    NightMarket.startedBy = nil
    SaveNightMarketCache()
    TriggerClientEvent('null:nightmarket:stopped', -1)
end

function BoutiqueServer.IsNightMarketActive()
    if NightMarket.active and os.time() >= NightMarket.expiresAt then
        BoutiqueServer.StopNightMarket()
    end
    return NightMarket.active
end

function BoutiqueServer.GetNightMarketData()
    if not BoutiqueServer.IsNightMarketActive() then
        return nil
    end
    return {
        cards = NightMarket.cards,
        expiresAt = NightMarket.expiresAt,
        startedBy = NightMarket.startedBy,
    }
end

-- Server event: staff starts a NightMarket
RegisterServerEvent('null:nightmarket:start')
AddEventHandler('null:nightmarket:start', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    if not xPlayer.getPermission("GESTION_BOUTIQUE") then return end

    local staffName = GetPlayerName(source) or "Staff"
    local success, msg = BoutiqueServer.StartNightMarket(staffName)

    TriggerClientEvent('esx:showNotification', source, success and ("~g~" .. msg) or ("~r~" .. msg))
end)

-- Server event: staff stops a NightMarket
RegisterServerEvent('null:nightmarket:stop')
AddEventHandler('null:nightmarket:stop', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    if not xPlayer.getPermission("GESTION_BOUTIQUE") then return end
    BoutiqueServer.StopNightMarket()
    TriggerClientEvent('esx:showNotification', source, "~g~NightMarket arrêté.")
end)

-- Server callback: check if NightMarket is active
ESX.RegisterServerCallback('null:nightmarket:isActive', function(source, cb)
    cb(BoutiqueServer.IsNightMarketActive())
end)

-- Server callback: get NightMarket data for NUI
ESX.RegisterServerCallback('null:nightmarket:getData', function(source, cb)
    local data = BoutiqueServer.GetNightMarketData()
    if not data then
        cb({ active = false })
        return
    end
    cb({
        active = true,
        cards = data.cards,
        expiresAt = data.expiresAt,
        timeLeft = math.max(0, NightMarket.expiresAt - os.time()),
    })
end)

-- Server callback: purchase a NightMarket card
ESX.RegisterServerCallback('null:nightmarket:purchase', function(source, cb, cardId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({ success = false, message = "Joueur introuvable" }) return end

    if not BoutiqueServer.IsNightMarketActive() then
        cb({ success = false, message = "Le NightMarket n'est plus actif" })
        return
    end

    local fivemId = GetFivemId(source)
    if not fivemId then cb({ success = false, message = "Identifiant introuvable" }) return end

    -- Find the card
    local card = nil
    for _, c in ipairs(NightMarket.cards) do
        if c.id == cardId then
            card = c
            break
        end
    end

    if not card then
        cb({ success = false, message = "Carte introuvable" })
        return
    end

    -- Check if already purchased
    HasAlreadyPurchased(fivemId, "NightMarket: " .. card.label, function(alreadyBought)
        if alreadyBought then
            cb({ success = false, message = "Tu as déjà acheté cet item !" })
            return
        end

        DeductCoins(fivemId, xPlayer, card.price, "NightMarket: " .. card.label, function(success, newCoins)
            if not success then
                cb({ success = false, message = "Coins insuffisants" })
                return
            end

            -- Give the item
            if card.type == "vehicle" and card.model then
                xPlayer.addAccountMoney('bank', 0)
                MySQL.Async.execute("INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)", {
                    ['@owner'] = xPlayer.identifier,
                    ['@plate'] = "NM" .. math.random(10000, 99999),
                    ['@vehicle'] = json.encode({ model = GetHashKey(card.model) }),
                })
            elseif card.type == "weapon" and card.name then
                xPlayer.addWeapon(card.name, 250)
            end

            cb({
                success = true,
                message = card.label .. " acheté avec succès !",
                coins = newCoins,
            })
        end)
    end)
end)

-- ============================================================================
-- FORMAT CONFIG ITEMS for NUI (with correct image paths)
-- ============================================================================

function BoutiqueServer.FormatItems(category)
    local items = {}
    local categoryAliases = {
        vehicle = "vehicles",
        weapon = "weapons",
        pack = "packs",
        boost = "boosts",
        crate = "crates",
    }
    category = categoryAliases[category] or category

    if category == "vehicles" and Config.Boutique.Vehicles then
        for i, v in ipairs(Config.Boutique.Vehicles) do
            table.insert(items, {
                id = "vehicle_" .. i,
                label = v.label,
                description = v.description,
                price = v.price,
                model = v.model,
                stats = v.stats,
                size = v.size,
                cells = v.cells,
                category = "vehicle",
                image = "nui://null-cache/images/vehicles/" .. (v.model or "") .. ".webp",
            })
        end
    elseif category == "weapons" and Config.Boutique.Weapons then
        for i, w in ipairs(Config.Boutique.Weapons) do
            local weaponImg = nil
            if w.name then
                weaponImg = "nui://null-cache/images/weapons/" .. w.name .. ".webp"
            end
            table.insert(items, {
                id = "weapon_" .. i,
                label = w.label,
                description = w.description,
                price = w.price,
                name = w.name,
                stats = w.stats,
                size = w.size,
                cells = w.cells,
                category = "weapon",
                image = weaponImg,
            })
        end
    elseif category == "packs" and Config.Boutique.Packs then
        local packImages = {
            ["entreprise"] = IMG_BASE .. "packs/entreprise.png",
            ["gang"] = IMG_BASE .. "packs/gang.png",
            ["veh-unique"] = IMG_BASE .. "packs/veh-unique.png",
        }
        local sorted = {}
        for key, pack in pairs(Config.Boutique.Packs) do
            pack._key = key
            table.insert(sorted, pack)
        end
        table.sort(sorted, function(a, b) return (a.index or 0) < (b.index or 0) end)
        for i, p in ipairs(sorted) do
            table.insert(items, {
                id = "pack_" .. p._key,
                label = p.label,
                description = p.description,
                price = p.price,
                info = p.info,
                info2 = p.info2,
                category = "pack",
                image = packImages[p._key],
            })
        end
    elseif category == "boosts" and Config.Boutique.Boosts then
        for i, b in pairs(Config.Boutique.Boosts) do
            table.insert(items, {
                id = "boost_" .. i,
                label = b.label,
                price = b.price,
                time = b.time,
                activeBoost = b.activeBoost,
                category = "boost",
                image = IMG_BASE .. "categories/boosts.webp",
            })
        end
    elseif category == "crates" and Config.Boutique.Crates and Config.Boutique.Crates.List then
        local sorted = {}
        for key, crate in pairs(Config.Boutique.Crates.List) do
            crate._key = key
            table.insert(sorted, crate)
        end
        table.sort(sorted, function(a, b) return (a.position or 0) < (b.position or 0) end)
        for _, c in ipairs(sorted) do
            table.insert(items, {
                id = "crate_" .. c._key,
                label = c.label,
                price = c.price > 0 and c.price or 0,
                buyable = c.buyable ~= false and c.price > 0,
                five = c.five,
                teen = c.teen,
                inside = c.Inside,
                category = "crate",
                preview = c.preview,
                image = IMG_BASE .. "crates/" .. (c._key or "") .. ".webp",
            })
        end
    end

    return items
end

-- ============================================================================
-- SERVER CALLBACKS
-- ============================================================================

ESX.RegisterServerCallback('null:boutique:getData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({}) return end

    local function sendBoutiqueData(coins, history, fidelity, fidelityTotal, dailySeed)
        local dailyItems = BoutiqueServer.GenerateDailyShop(dailySeed or tostring(source))
        local vehicles = BoutiqueServer.FormatItems("vehicles")
        local weapons = BoutiqueServer.FormatItems("weapons")
        local packs = BoutiqueServer.FormatItems("packs")
        local boosts = BoutiqueServer.FormatItems("boosts")
        local crates = BoutiqueServer.FormatItems("crates")

        local boutiqueLink = null.getConvarKey("boutiqueLink") or ""
        local nightMarketData = BoutiqueServer.GetNightMarketData()

        cb({
            userInfo = {
                coins = coins or 0,
                history = history or {},
                fidelity = fidelity or 0,
                fidelityTotal = fidelityTotal or 0,
            },
            items = {
                vehicles = vehicles,
                weapons = weapons,
                packs = packs,
                boosts = boosts,
                crates = crates,
            },
            dailyItems = dailyItems,
            boutiqueLink = boutiqueLink,
            nightMarket = nightMarketData and {
                active = true,
                cards = nightMarketData.cards,
                timeLeft = math.max(0, NightMarket.expiresAt - os.time()),
            } or { active = false },
        })
    end

    local fivemId = GetFivemId(source)
    if not fivemId then
        sendBoutiqueData(0, {}, 0, 0, xPlayer.identifier or tostring(source))
        return
    end

    GetPlayerCoins(fivemId, function(coins)
        GetPlayerHistory(fivemId, function(history)
            GetPlayerFidelity(fivemId, function(havebuy, totalbuy)
                sendBoutiqueData(coins, history, havebuy, totalbuy, fivemId)
            end)
        end)
    end)
end)

ESX.RegisterServerCallback('null:boutique:getItems', function(source, cb, category)
    local items = BoutiqueServer.FormatItems(category)
    cb(items)
end)

ESX.RegisterServerCallback('null:boutique:purchase', function(source, cb, itemId, category, quantity, price)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({ success = false, message = "Joueur introuvable" }) return end

    local fivemId = GetFivemId(source)
    if not fivemId then cb({ success = false, message = "Identifiant FiveM introuvable" }) return end

    local totalPrice = price * (quantity or 1)
    local itemLabel = itemId

    if category == "vehicle" then
        -- Find vehicle in config
        for _, v in ipairs(Config.Boutique.Vehicles or {}) do
            if "vehicle_" .. _ == itemId or v.model == itemId then
                itemLabel = v.label
                totalPrice = v.price
                break
            end
        end

        -- Check if already purchased
        HasAlreadyPurchased(fivemId, itemLabel, function(alreadyOwned)
            if alreadyOwned then
                cb({ success = false, message = "Vous avez déjà ce véhicule" })
                return
            end

            DeductCoins(fivemId, xPlayer, totalPrice, string.format("Achat de : %s", itemLabel), function(success, newCoins)
                if not success then
                    cb({ success = false, message = "Coins insuffisants" })
                    return
                end

                -- Find vehicle model
                local vehicleModel = nil
                for _, v in ipairs(Config.Boutique.Vehicles or {}) do
                    if "vehicle_" .. _ == itemId or v.model == itemId then
                        vehicleModel = v.model
                        break
                    end
                end

                -- Add vehicle to owned_vehicles via cache (same as old boutique)
                if vehicleModel then
                    local characters = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }
                    local function CreateRandomPlateText()
                        local plate = ""
                        math.randomseed(GetGameTimer())
                        for i = 1, 4 do
                            plate = plate .. characters[math.random(1, #characters)]
                        end
                        for i = 1, 3 do
                            plate = plate .. math.random(1, 9)
                        end
                        return plate
                    end

                    local oldCacheData = exports["null-core"]:GetCacheData("owned_vehicles")
                    local newplate = nil
                    local PlateExist = true
                    while PlateExist do
                        newplate = CreateRandomPlateText()
                        if oldCacheData[string.upper(newplate)] == nil then
                            PlateExist = false
                        end
                        Wait(100)
                    end

                    oldCacheData[string.upper(newplate)] = {
                        owner = xPlayer.identifier,
                        plate = string.upper(newplate),
                        model = vehicleModel,
                        label = vehicleModel,
                        vehicle = { model = GetHashKey(vehicleModel), plate = newplate },
                        coffre = {},
                        type = "car",
                        state = true,
                        boutique = true,
                        garage = true,
                    }
                    exports["null-core"]:EditCacheData("owned_vehicles", oldCacheData)
                end

                xPlayer.showNotification("Vous avez acheté : " .. itemLabel .. " sur la boutique !")

                cb({
                    success = true,
                    message = "Achat effectué avec succès !",
                    coins = newCoins,
                    vehicleModel = vehicleModel,
                })
            end)
        end)

    elseif category == "weapon" then
        local weaponData = nil
        for _, w in ipairs(Config.Boutique.Weapons or {}) do
            if "weapon_" .. _ == itemId or w.name == itemId then
                weaponData = w
                itemLabel = w.label
                totalPrice = w.price
                break
            end
        end

        if not weaponData then
            cb({ success = false, message = "Arme introuvable" })
            return
        end

        HasAlreadyPurchased(fivemId, itemLabel, function(alreadyOwned)
            if alreadyOwned then
                cb({ success = false, message = "Vous avez déjà cette arme" })
                return
            end

            DeductCoins(fivemId, xPlayer, totalPrice, string.format("Achat de : %s", itemLabel), function(success, newCoins)
                if not success then
                    cb({ success = false, message = "Coins insuffisants" })
                    return
                end

                xPlayer.addWeapon(weaponData.name, 250, nil, true, 0)
                xPlayer.showNotification("Vous avez acheté : " .. weaponData.label .. " sur la boutique !")

                cb({
                    success = true,
                    message = "Achat effectué avec succès !",
                    coins = newCoins,
                })
            end)
        end)

    elseif category == "pack" then
        local packKey = itemId:gsub("pack_", "")
        local packData = Config.Boutique.Packs and Config.Boutique.Packs[packKey]

        if not packData then
            cb({ success = false, message = "Pack introuvable" })
            return
        end

        itemLabel = packData.label
        totalPrice = packData.price

        -- Use the old boutique's pack purchase logic via server event
        TriggerEvent('null:server:BuyPack', packKey)

        -- For now, return success - the event handles the actual logic
        GetPlayerCoins(fivemId, function(newCoins)
            cb({
                success = true,
                message = "Demande d'achat envoyée",
                coins = newCoins,
            })
        end)

    elseif category == "boost" then
        local boostData = nil
        for k, b in pairs(Config.Boutique.Boosts or {}) do
            if "boost_" .. k == itemId then
                boostData = b
                itemLabel = b.label
                totalPrice = b.price
                break
            end
        end

        if not boostData then
            cb({ success = false, message = "Boost introuvable" })
            return
        end

        DeductCoins(fivemId, xPlayer, totalPrice, string.format("Achat de : %s", itemLabel), function(success, newCoins)
            if not success then
                cb({ success = false, message = "Coins insuffisants" })
                return
            end

            xPlayer.showNotification("Vous avez acheté : " .. itemLabel .. " sur la boutique !")

            cb({
                success = true,
                message = "Achat effectué avec succès !",
                coins = newCoins,
            })
        end)

    else
        -- Daily shop or other
        DeductCoins(fivemId, xPlayer, totalPrice, string.format("Achat boutique : %s", itemLabel), function(success, newCoins)
            if not success then
                cb({ success = false, message = "Coins insuffisants" })
                return
            end

            cb({
                success = true,
                message = "Achat effectué avec succès !",
                coins = newCoins,
            })
        end)
    end
end)

ESX.RegisterServerCallback('null:boutique:openCrate', function(source, cb, crateId, quantity)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({ reward = nil }) return end

    local fivemId = GetFivemId(source)
    if not fivemId then cb({ reward = nil, message = "Identifiant FiveM introuvable" }) return end

    local crateKey = crateId:gsub("crate_", "")
    local crate = Config.Boutique.Crates and Config.Boutique.Crates.List and Config.Boutique.Crates.List[crateKey]

    if not crate then
        cb({ reward = nil, message = "Caisse introuvable" })
        return
    end

    local totalPrice = 0
    if quantity == 5 and crate.five then
        totalPrice = crate.five
    elseif quantity == 10 and crate.teen then
        totalPrice = crate.teen
    else
        totalPrice = crate.price * (quantity or 1)
    end

    if crate.buyable == false or crate.price <= 0 then
        cb({ reward = nil, message = "Cette caisse ne peut pas être achetée" })
        return
    end

    DeductCoins(fivemId, xPlayer, totalPrice, string.format("Ouverture caisse : %s (x%d)", crate.label, quantity or 1), function(success, newCoins)
        if not success then
            cb({ reward = nil, message = "Coins insuffisants" })
            return
        end

        -- Roll for reward using rarity chances
        local chances = Config.Boutique.Crates.Chances or { Ultime = 5, Legendary = 15, Rare = 30 }
        local roll = math.random(1, 100)
        local targetRarity

        if roll <= (chances.Ultime or 5) then
            targetRarity = 4
        elseif roll <= (chances.Ultime or 5) + (chances.Legendary or 15) then
            targetRarity = 3
        elseif roll <= (chances.Ultime or 5) + (chances.Legendary or 15) + (chances.Rare or 30) then
            targetRarity = 2
        else
            targetRarity = 1
        end

        local candidates = {}
        for _, item in ipairs(crate.Inside or {}) do
            if item.rarity == targetRarity then
                table.insert(candidates, item)
            end
        end

        if #candidates == 0 then
            candidates = crate.Inside or {}
        end

        if #candidates == 0 then
            cb({ reward = nil, message = "Erreur: caisse vide" })
            return
        end

        local reward = candidates[math.random(1, #candidates)]

        -- Give reward
        if reward.typeLot == "vehicle" or reward.typeLot == "helico" then
            -- Vehicle will be spawned client-side
        elseif reward.typeLot == "weapon" then
            xPlayer.addWeapon(reward.model, 250)
        elseif reward.typeLot == "money" then
            xPlayer.addMoney(reward.amount or 0)
        elseif reward.typeLot == "Coins" then
            LiteMySQL:Insert('tebex_players_wallet', {
                identifiers = fivemId,
                idunique = xPlayer.getIdunique(),
                transaction = "Gain caisse : " .. (reward.label or "Coins"),
                price = 0,
                currency = 'Points',
                points = reward.amount or 0,
            })
            newCoins = newCoins + (reward.amount or 0)
        elseif reward.typeLot == "item" then
            xPlayer.addInventoryItem(reward.model, reward.amount or 1)
        end

        null.DebugPrint(string.format("Boutique Crate: %s opened %s and got %s (rarity %d)",
            xPlayer.getName(), crateKey, reward.label, reward.rarity))

        cb({
            reward = reward,
            coins = newCoins,
        })
    end)
end)

-- History callback
ESX.RegisterServerCallback('null:boutique:getHistory', function(source, cb)
    local fivemId = GetFivemId(source)
    if not fivemId then cb({}) return end

    GetPlayerHistory(fivemId, function(history)
        cb(history)
    end)
end)

-- Coins callback (used by weapon customization standalone menu)
ESX.RegisterServerCallback('null:boutique:getCoins', function(source, cb)
    local fivemId = GetFivemId(source)
    if not fivemId then cb(0) return end
    GetPlayerCoins(fivemId, function(coins)
        cb(coins)
    end)
end)

-- ============================================================================
-- WEAPON CUSTOMIZATION
-- ============================================================================

local WEAPON_COMPONENT_PRICE = 250 -- Default price per component

-- Get weapon custom data from null-ui resource
local function GetWeaponCustomData()
    local ok, data = pcall(function()
        return exports["null-ui"]:GetWeaponCustomPrice()
    end)
    if ok and data then return data end
    return nil
end

-- Find component data for a weapon
local function FindWeaponComponents(weaponName)
    local customData = GetWeaponCustomData()
    if not customData then return {} end

    for _, weapon in pairs(customData) do
        if weapon.name and weapon.name:upper() == weaponName:upper() then
            return weapon.components or {}
        end
    end
    return {}
end

ESX.RegisterServerCallback('null:boutique:getPlayerWeapons', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({}) return end

    local loadout = xPlayer.getLoadout()
    local weapons = {}

    for _, weapon in ipairs(loadout) do
        local weaponName = weapon.name
        local components = FindWeaponComponents(weaponName)
        local weaponComponents = {}

        for _, comp in ipairs(components) do
            if comp.hash and comp.hash ~= "" then
                local installed = false
                -- Check if component is installed by comparing both name and hash
                if weapon.components then
                    for _, installedComp in ipairs(weapon.components) do
                        -- installedComp can be a name (e.g. "clip_extended") or a hash string (e.g. "COMPONENT_GRAU_CLIP_02")
                        if string.lower(installedComp) == string.lower(comp.name) then
                            installed = true
                            break
                        end
                        if string.upper(installedComp) == string.upper(comp.hash) then
                            installed = true
                            break
                        end
                    end
                end

                table.insert(weaponComponents, {
                    name = comp.name or "",
                    label = comp.label or comp.name or "",
                    hash = comp.hash,
                    price = comp.point or WEAPON_COMPONENT_PRICE,
                    installed = installed,
                })
            end
        end

        -- Get weapon label
        local weaponLabel = weaponName
        local customData = GetWeaponCustomData()
        if customData then
            for _, w in pairs(customData) do
                if w.name and w.name:upper() == weaponName:upper() then
                    weaponLabel = w.label or weaponName
                    break
                end
            end
        end

        table.insert(weapons, {
            name = weaponName,
            label = weaponLabel,
            components = weaponComponents,
        })
    end

    cb(weapons)
end)

ESX.RegisterServerCallback('null:boutique:buyWeaponComponent', function(source, cb, weaponName, componentHash, price)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb({ success = false, message = "Joueur introuvable" }) return end

    local fivemId = GetFivemId(source)
    if not fivemId then cb({ success = false, message = "Identifiant introuvable" }) return end

    -- Validate component exists in WEAPON_CUSTOM_PRICE
    local components = FindWeaponComponents(weaponName)
    local validComponent = nil
    for _, comp in ipairs(components) do
        if comp.hash == componentHash then
            validComponent = comp
            break
        end
    end

    if not validComponent then
        cb({ success = false, message = "Composant invalide" })
        return
    end

    local componentPrice = validComponent.point or WEAPON_COMPONENT_PRICE

    DeductCoins(fivemId, xPlayer, componentPrice, string.format("Custom arme: %s - %s", weaponName, validComponent.label or componentHash), function(success, newCoins)
        if not success then
            cb({ success = false, message = "Coins insuffisants" })
            return
        end

        -- Directly insert component into loadout (bypass ESX.GetWeaponComponent which fails for duplicate names)
        weaponName = string.upper(weaponName)
        local loadoutNum, weapon = xPlayer.getWeapon(weaponName)
        if weapon then
            -- Store the component name in loadout (ESX standard)
            table.insert(weapon.components, string.lower(validComponent.name))
            -- Trigger client event to apply visually using the hash
            xPlayer.triggerEvent('esx:addWeaponComponent', weaponName, string.lower(validComponent.name))
        end

        cb({
            success = true,
            message = "Composant installé !",
            coins = newCoins,
        })
    end)
end)

-- ============================================================================
-- VIP PURCHASE FROM BOUTIQUE
-- ============================================================================

-- Helper: get VIP tier level (Basic=1, Premium=2)
local VIP_HIERARCHY = { ["Basic"] = 1, ["Premium"] = 2 }

-- Server callback to get VIP purchase info (price, restrictions) for NUI
ESX.RegisterServerCallback('null:boutique:getVipPurchaseInfo', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    local isVip, vipType, timeData = GetVIP(xPlayer.identifier)

    local result = {}
    for tierName, tier in pairs(Config.VIP.Tiers) do
        local info = {
            price = tier.price,
            blocked = false,
            blockedReason = nil,
            upgradeDiscount = 0,
        }

        if isVip and vipType then
            local currentLevel = VIP_HIERARCHY[vipType] or 0
            local targetLevel = VIP_HIERARCHY[tierName] or 0

            -- Block buying same tier (already active)
            if tierName == vipType then
                info.blocked = true
                info.blockedReason = "already_active"
            -- Block buying a lower tier (e.g. Basic when Premium is active)
            elseif targetLevel < currentLevel then
                info.blocked = true
                info.blockedReason = "downgrade"
            -- Upgrade: calculate discount based on remaining days of current VIP
            elseif targetLevel > currentLevel and timeData then
                local remainingDays = (timeData.remaining or 0) / 60 / 24
                if remainingDays > 0 then
                    local currentTier = Config.VIP.Tiers[vipType]
                    if currentTier then
                        local dailyRate = currentTier.price / (currentTier.durationDays or 31)
                        local discount = math.floor(dailyRate * remainingDays)
                        info.upgradeDiscount = discount
                        info.price = math.max(0, tier.price - discount)
                    end
                end
            end
        end

        result[tierName] = info
    end

    cb(result)
end)

RegisterNetEvent('null:boutique:buyVip', function(tierName)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local fivemId = GetFivemId(source)
    if not fivemId then
        xPlayer.showNotification("~r~Erreur: Identifiant FiveM introuvable")
        return
    end

    local tier = Config.VIP and Config.VIP.Tiers and Config.VIP.Tiers[tierName]
    if not tier then
        xPlayer.showNotification("~r~Erreur: Tier VIP introuvable")
        return
    end

    local identifier = xPlayer.identifier
    local isVip, vipType, timeData = GetVIP(identifier)

    -- Block: can't buy a lower or equal tier
    if isVip and vipType then
        local currentLevel = VIP_HIERARCHY[vipType] or 0
        local targetLevel = VIP_HIERARCHY[tierName] or 0

        if targetLevel <= currentLevel then
            local msg = tierName == vipType and "Vous avez déjà ce VIP actif" or "Vous avez un VIP supérieur actif"
            xPlayer.showNotification("~r~" .. msg)
            TriggerClientEvent('null:boutique:nuiCallback', source, { action = 'boutique:purchaseResult', success = false, message = msg })
            return
        end
    end

    -- Calculate price (with upgrade discount if applicable)
    local price = tier.price
    local days = tier.durationDays or 31

    if isVip and vipType and timeData then
        local currentTier = Config.VIP.Tiers[vipType]
        if currentTier then
            local remainingDays = (timeData.remaining or 0) / 60 / 24
            if remainingDays > 0 then
                local dailyRate = currentTier.price / (currentTier.durationDays or 31)
                local discount = math.floor(dailyRate * remainingDays)
                price = math.max(0, tier.price - discount)
            end
        end
    end

    DeductCoins(fivemId, xPlayer, price, string.format("Achat VIP %s (%d jours)", tierName, days), function(success, newCoins)
        if not success then
            xPlayer.showNotification("~r~Coins insuffisants pour acheter le VIP")
            TriggerClientEvent('null:boutique:nuiCallback', source, { action = 'boutique:purchaseResult', success = false, message = "Coins insuffisants" })
            return
        end

        -- Set VIP with FIXED expiration (not stacking days)
        local newExpiration = os.time() + (days * 86400)

        MySQL.Async.fetchAll("SELECT * FROM vips WHERE identifier = @identifier", {
            ['@identifier'] = identifier
        }, function(result)
            if result[1] then
                MySQL.Async.execute('UPDATE vips SET expiration = @expiration, type = @type, vip = 1 WHERE identifier = @identifier', {
                    ['@identifier'] = identifier,
                    ['@expiration'] = newExpiration,
                    ['@type'] = tierName
                })
            else
                MySQL.Async.execute('INSERT INTO vips (identifier, vip, expiration, type) VALUES (@identifier, 1, @expiration, @type)', {
                    ['@identifier'] = identifier,
                    ['@expiration'] = newExpiration,
                    ['@type'] = tierName
                })
            end

            -- Update VipCache directly
            local CalculateTimeRemaining = function(exp)
                local rem = ((exp - os.time()) / 60)
                return {
                    days = math.floor(rem / 60 / 24),
                    hours = math.floor((rem / 60) % 24),
                    minutes = math.ceil(rem % 60),
                    remaining = rem
                }
            end

            local timeCalc = CalculateTimeRemaining(newExpiration)
            -- VipCache is in vip/server/main.lua, update it
            if VipCache then
                VipCache[identifier] = {
                    isVip = true,
                    type = tierName,
                    time = timeCalc,
                    expiration = newExpiration
                }
            end

            SyncVipToClient(source, identifier)

            xPlayer.showNotification(("~g~VIP %s~s~ activé pour %d jours !"):format(tier.label, days))

            TriggerClientEvent('null:boutique:nuiCallback', source, {
                action = 'boutique:purchaseResult',
                success = true,
                message = tier.label .. " activé !",
                coins = newCoins,
            })
        end)
    end)
end)
