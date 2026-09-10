-- ================================================================
-- Null REALTORS — Agence Immobilière (Boss + Employés)
-- ================================================================
-- Étape 2 : Génération auto + achat société + callbacks de base
-- Repose sur le module gameplay/properties existant pour les
-- intérieurs / coffre / sonnette / entrée. Toute maison achetée
-- par la société est enregistrée dans `properties_list` avec
-- owner = Config.Realtors.SocietyName, ce qui réutilise tout le
-- pipeline existant (entry, coffre, etc.)
-- ================================================================

local CFG          = Config.Realtors
local LISTINGS     = {}      -- [listingId] = { ... } biens à vendre actuellement sur le marché
local LAST_REFRESH = 0

-- ----------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------
local function now() return os.time() end

local function getDate()
    local d = os.date('*t')
    return string.format("%02d/%02d/%04d - %02d:%02d", d.day, d.month, d.year, d.hour, d.min)
end

local function genListingId()
    return string.format("LST-%d-%d", now(), math.random(1000, 9999))
end

local function genPropertyName()
    return string.format("realtor_%d_%d", now(), math.random(100000, 999999))
end

local function getSocietyMoney()
    local society = SocietyCache and SocietyCache[CFG.SocietyName]
    if not society then return 0 end
    return society.data.accounts.cash or 0
end

local function debitSociety(amount, label, detail)
    local society = SocietyCache and SocietyCache[CFG.SocietyName]
    if not society then return false end
    if (society.data.accounts.cash or 0) < amount then return false end
    society.data.accounts.cash = society.data.accounts.cash - amount
    SocietySaved[CFG.SocietyName] = SocietyCache[CFG.SocietyName]
    if addHistorySociety then
        addHistorySociety(CFG.SocietyName, label or "Dépense agence", detail or "", -amount)
    end
    return true
end

local function creditSociety(amount, label, detail)
    local society = SocietyCache and SocietyCache[CFG.SocietyName]
    if not society then return false end
    society.data.accounts.cash = (society.data.accounts.cash or 0) + amount
    SocietySaved[CFG.SocietyName] = SocietyCache[CFG.SocietyName]
    if addHistorySociety then
        addHistorySociety(CFG.SocietyName, label or "Recette agence", detail or "", amount)
    end
    return true
end

-- ----------------------------------------------------------------
-- DB init
-- ----------------------------------------------------------------
local ensureConstructionSchema  -- forward declaration (defined in construction section)

local function ensureSchema()
    MySQL.execute([[
        CREATE TABLE IF NOT EXISTS `realtor_sales` (
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `property_name` VARCHAR(64) NOT NULL,
            `property_label` VARCHAR(128) NOT NULL,
            `interior` VARCHAR(32) NOT NULL,
            `neighborhood` VARCHAR(64) NOT NULL,
            `mode` ENUM('sell','rent') NOT NULL,
            `seller_identifier` VARCHAR(64) NOT NULL,
            `seller_name` VARCHAR(128) NOT NULL,
            `buyer_identifier` VARCHAR(64) NOT NULL,
            `buyer_name` VARCHAR(128) NOT NULL,
            `price` INT(11) NOT NULL DEFAULT 0,
            `days` INT(11) NOT NULL DEFAULT 0,
            `created_at` VARCHAR(32) NOT NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_property` (`property_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.execute([[
        CREATE TABLE IF NOT EXISTS `realtor_active_rentals` (
            `property_name` VARCHAR(64) NOT NULL,
            `tenant_identifier` VARCHAR(64) NOT NULL,
            `tenant_name` VARCHAR(128) NOT NULL,
            `daily_price` INT(11) NOT NULL,
            `started_at` INT(11) NOT NULL,
            `expires_at` INT(11) NOT NULL,
            PRIMARY KEY (`property_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

-- ----------------------------------------------------------------
-- Génération d'un listing depuis un point du pool
-- ----------------------------------------------------------------
local function isSpawnAlreadyOwned(spawnKey)
    -- Si une property_list existe déjà avec ce spawnKey en "originSpawn", c'est qu'elle est possédée
    if not SaveData or not SaveData.PropertiesList then return false end
    for _, p in pairs(SaveData.PropertiesList) do
        if p.originSpawn == spawnKey then return true end
    end
    return false
end

local function isSpawnAlreadyListed(spawnKey)
    for _, l in pairs(LISTINGS) do
        if l.spawnKey == spawnKey then return true end
    end
    return false
end

local function buildListing(spawn)
    local interior = CFG.InteriorTypes[spawn.interior]
    local hood     = CFG.Neighborhoods[spawn.neighborhood] or { label = spawn.neighborhood, priceMul = 1.0 }
    local jitter   = (math.random() * (CFG.Generation.PriceJitter[2] - CFG.Generation.PriceJitter[1]))
                     + CFG.Generation.PriceJitter[1]
    local price    = math.floor(interior.basePrice * hood.priceMul * jitter)
    local rent     = math.floor((interior.baseRent or 0) * hood.priceMul * jitter)

    return {
        id           = genListingId(),
        spawnKey     = spawn.key,
        door         = { x = spawn.door.x, y = spawn.door.y, z = spawn.door.z, w = spawn.door.w },
        interior     = spawn.interior,
        interiorLabel= interior.label,
        photos       = interior.photos or 1,
        warehouse    = interior.warehouse or false,
        neighborhood = spawn.neighborhood,
        neighborhoodLabel = hood.label,
        price        = price,
        suggestedSale = math.floor(price * CFG.PublicSaleMargin),
        suggestedRent = rent,
        generatedAt  = now(),
    }
end

local function regenerateListings(force)
    -- Retire d'abord les listings qui correspondent à des spawns désormais possédés
    for id, l in pairs(LISTINGS) do
        if isSpawnAlreadyOwned(l.spawnKey) then LISTINGS[id] = nil end
    end

    -- Si on a déjà assez de listings et qu'on ne force pas, on ne fait rien
    local count = 0
    for _ in pairs(LISTINGS) do count = count + 1 end
    if not force and count >= CFG.Generation.MinListings then return end

    -- Si on force, on vide le marché actuel
    if force then LISTINGS = {} end

    -- Construit la liste des spawns disponibles
    local available = {}
    for _, sp in ipairs(CFG.SpawnPool) do
        if not isSpawnAlreadyOwned(sp.key) and not isSpawnAlreadyListed(sp.key) then
            available[#available + 1] = sp
        end
    end

    -- Mélange (Fisher-Yates)
    for i = #available, 2, -1 do
        local j = math.random(i)
        available[i], available[j] = available[j], available[i]
    end

    local target = CFG.Generation.MaxListings - count
    for i = 1, math.min(target, #available) do
        local listing = buildListing(available[i])
        LISTINGS[listing.id] = listing
    end

    LAST_REFRESH = now()
    -- null.InitPrint(("^2[REALTOR] %d listings générés (total = %d)^0"):format(target, count + target))
end

-- ----------------------------------------------------------------
-- Conversion listing → properties_list (achat société)
-- ----------------------------------------------------------------
local function spawnPositionToPropertyPositions(spawnDoor, interiorKey)
    local interior = Config.Properties.List[interiorKey]
    return {
        ["EXIT"]   = vector3(spawnDoor.x, spawnDoor.y, spawnDoor.z),
        ["ENTER"]  = interior.positions.inside,
        ["COFFRE"] = interior.positions.cam_coords,
    }
end

local function createPropertyForSociety(listing, buyerName)
    local interior  = Config.Properties.List[listing.interior]
    local maxWeight = (interior and interior.MaxWeight) or 250
    local name      = genPropertyName()
    local label     = string.format("%s • %s", listing.interiorLabel, listing.neighborhoodLabel)
    local positions = spawnPositionToPropertyPositions(listing.door, listing.interior)

    local data = {
        ["weapons"] = {},
        ["item"]    = {},
        ["accounts"] = { cash = 0, dirtycash = 0 },
    }
    local parms = { GradesAlloweds = {}, PeopleAlloweds = {} }

    SaveData.PropertiesList[name] = {
        id          = math.random(111111, 999999),
        name        = name,
        label       = label,
        poids       = maxWeight,
        price       = listing.price,
        isBuy       = true,                       -- propriété "active" (possédée)
        positions   = positions,
        owner       = CFG.SocietyName,            -- société agence
        immeuble    = "0",
        data        = data,
        parms       = parms,
        bucketID    = tonumber("21"..tostring(math.random(1111, 9999))),
        -- ---------- champs propres au module realtor ----------
        originSpawn = listing.spawnKey,
        interior    = listing.interior,
        neighborhood= listing.neighborhood,
        listingMode = "sell",                     -- sell | rent
        salePrice   = listing.suggestedSale,
        rentPrice   = listing.suggestedRent,
        boughtAt    = now(),
        boughtFor   = listing.price,
        boughtBy    = buyerName,
    }

    local info = { name = name, label = label, poids = maxWeight }
    MySQL.Async.execute(
        'INSERT INTO properties_list (id, name, info, price, coords, immeuble, owner, isBuy, data, parms) '..
        'VALUES (@id, @name, @info, @price, @coords, @immeuble, @owner, @isBuy, @data, @parms)',
        {
            ["@id"]       = SaveData.PropertiesList[name].id,
            ["@name"]     = name,
            ["@info"]     = json.encode(info),
            ["@price"]    = listing.price,
            ["@coords"]   = json.encode(positions),
            ["@immeuble"] = "0",
            ["@owner"]    = CFG.SocietyName,
            ["@isBuy"]    = 1,
            ["@data"]     = json.encode(data),
            ["@parms"]    = json.encode(parms),
        }
    )

    -- Pousse le state aux clients pour blip / markers
    TriggerClientEvent("null:properties:UpdatePropertiesList", -1, SaveData.PropertiesList)
    TriggerClientEvent("h:propertySyncProperties", -1)

    return name
end

-- ----------------------------------------------------------------
-- Boot
-- ----------------------------------------------------------------
CreateThread(function()
    while not SaveData or not SaveData.PropertiesList do Wait(200) end
    while not SocietyCache or not SocietyCache[CFG.SocietyName] do
        TriggerEvent('esx_society:registerSociety', CFG.SocietyName, "Agence Immobilière",
            CFG.SocietyName, CFG.SocietyName, CFG.SocietyName, { type = 'private' })
        Wait(200)
    end

    ensureSchema()
    ensureConstructionSchema()
    Wait(2000)
    regenerateListings(true)

    -- null.InitPrint("^2[REALTOR] Module agence chargé.^0")

    while true do
        Wait(CFG.Generation.RefreshInterval)
        regenerateListings(true)
    end
end)

-- ----------------------------------------------------------------
-- Helpers vues
-- ----------------------------------------------------------------
local function listingToPayload(l) return l end

local function getOwnedProperties()
    local out = {}
    if not SaveData or not SaveData.PropertiesList then return out end
    for _, p in pairs(SaveData.PropertiesList) do
        if p.owner == CFG.SocietyName then
            out[#out + 1] = {
                name           = p.name,
                label          = p.label,
                price          = p.price,
                positions      = p.positions,
                interior       = p.interior,
                interiorLabel  = (CFG.InteriorTypes[p.interior] and CFG.InteriorTypes[p.interior].label) or p.interior,
                neighborhood   = p.neighborhood,
                neighborhoodLabel = (CFG.Neighborhoods[p.neighborhood] and CFG.Neighborhoods[p.neighborhood].label) or p.neighborhood,
                listingMode    = p.listingMode or "sell",
                salePrice      = p.salePrice or p.price,
                rentPrice      = p.rentPrice or 0,
                boughtAt       = p.boughtAt,
                boughtFor      = p.boughtFor,
                originSpawn    = p.originSpawn,
                photos         = (CFG.InteriorTypes[p.interior] and CFG.InteriorTypes[p.interior].photos) or 1,
                warehouse      = (CFG.InteriorTypes[p.interior] and CFG.InteriorTypes[p.interior].warehouse) or false,
            }
        end
    end
    return out
end

local function getActiveRentals()
    local rows = MySQL.query.await('SELECT * FROM realtor_active_rentals', {}) or {}
    local out  = {}
    for _, r in ipairs(rows) do out[r.property_name] = r end
    return out
end

-- ----------------------------------------------------------------
-- Callbacks
-- ----------------------------------------------------------------
-- ----------------------------------------------------------------
-- DEBUG : sources autorisées à ouvrir la tablette sans le job
-- ----------------------------------------------------------------
_G.RealtorDebugSources = _G.RealtorDebugSources or {}  -- [src] = 'boss' | 'employee'
local DebugSources = _G.RealtorDebugSources

local function isAuthorized(xPlayer, src)
    return xPlayer and (xPlayer.job.name == CFG.JobName or DebugSources[src] ~= nil)
 end
local function isBossAuthorized(xPlayer, src)
    if DebugSources[src] == 'boss' then return true end
    return xPlayer and xPlayer.job.name == CFG.JobName and xPlayer.job.grade >= CFG.BossGrade
end

AddEventHandler('playerDropped', function()
    DebugSources[source] = nil
end)

ESX.RegisterServerCallback('realtor:grantDebug', function(source, cb, mode)
    if mode ~= 'boss' and mode ~= 'employee' then cb(false) return end
    DebugSources[source] = mode
    print(('[REALTOR] Debug grant : src=%s mode=%s'):format(source, mode))
    cb(true)
end)

ESX.RegisterServerCallback("realtor:getDashboard", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not isAuthorized(xPlayer, source) then cb(nil) return end

    local owned   = getOwnedProperties()
    local rentals = getActiveRentals()
    -- enrichit owned avec rental info
    for _, p in ipairs(owned) do
        local r = rentals[p.name]
        if r then
            p.rental = {
                tenantName = r.tenant_name,
                expiresAt  = r.expires_at,
                dailyPrice = r.daily_price,
                startedAt  = r.started_at,
            }
        end
    end

    local listings = {}
    for _, l in pairs(LISTINGS) do listings[#listings + 1] = listingToPayload(l) end

    local history = MySQL.query.await(
        'SELECT * FROM realtor_sales ORDER BY id DESC LIMIT 100', {}) or {}

    local debugMode = DebugSources[source]
    -- constructions en cours (employé voit tout, pour son suivi)
    local constructions = {}
    if SaveData and SaveData.PropertiesList then
        local cRows = MySQL.query.await('SELECT * FROM realtor_constructions WHERE notified = 0') or {}
        for _, r in ipairs(cRows) do
            local p = SaveData.PropertiesList[r.property_name]
            constructions[#constructions + 1] = {
                name       = r.property_name,
                label      = p and p.label or r.property_name,
                interior   = r.interior,
                finishesAt = r.finishes_at,
                ownerName  = (ESX.GetPlayerFromId((function()
                    for _, pid in ipairs(ESX.GetPlayers()) do
                        local px = ESX.GetPlayerFromId(pid)
                        if px and px.identifier == r.owner_identifier then return pid end
                    end
                end)()) or { getName = function() return r.owner_identifier end }).getName(),
            }
        end
    end

    cb({
        mode          = debugMode or ((xPlayer.job.grade >= CFG.BossGrade) and "boss" or "employee"),
        societyMoney  = getSocietyMoney(),
        listings      = listings,
        owned         = owned,
        history       = history,
        constructions = constructions,
        neighborhoods = CFG.Neighborhoods,
        interiors     = CFG.InteriorTypes,
        config        = {
            buyMargin       = CFG.BuyMargin,
            publicSaleMargin = CFG.PublicSaleMargin,
            minRentalDays   = CFG.MinRentalDays,
            maxRentalDays   = CFG.MaxRentalDays,
            construction    = CFG.Construction,
        },
        nextRefreshAt = LAST_REFRESH + math.floor(CFG.Generation.RefreshInterval / 1000),
        playerName    = xPlayer.getName(),
    })
end)

-- ----------------------------------------------------------------
-- BOSS : achat d'un listing
-- ----------------------------------------------------------------
RegisterNetEvent("realtor:buyListing", function(listingId)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if not isBossAuthorized(xPlayer, _src) then return end

    local listing = LISTINGS[listingId]
    if not listing then
        TriggerClientEvent('esx:showNotification', _src, "~r~Bien introuvable ou déjà vendu")
        return
    end

    local cost = math.floor(listing.price * CFG.BuyMargin)
    if not debitSociety(cost,
        "Achat immobilier",
        ("Bien: %s\nQuartier: %s\nAcheté par: %s\nMontant: %s$"):format(
            listing.interiorLabel, listing.neighborhoodLabel, xPlayer.getName(), ESX.Math.GroupDigits(cost)))
    then
        TriggerClientEvent('esx:showNotification', _src, "~r~Fonds insuffisants dans la société")
        return
    end

    local propName = createPropertyForSociety(listing, xPlayer.getName())
    LISTINGS[listingId] = nil

    TriggerClientEvent('esx:showNotification', _src,
        ("~g~Bien acquis pour %s$ (%s)"):format(ESX.Math.GroupDigits(cost), listing.neighborhoodLabel))

    -- Notifie les autres clients du job pour refresh dashboard
    for _, pid in ipairs(ESX.GetPlayers()) do
        local p = ESX.GetPlayerFromId(pid)
        if p and p.job and p.job.name == CFG.JobName then
            TriggerClientEvent("realtor:dashboardDirty", pid)
        end
    end
end)

-- ----------------------------------------------------------------
-- BOSS : config d'un bien possédé (mode + prix)
-- ----------------------------------------------------------------
RegisterNetEvent("realtor:updatePropertySettings", function(propName, settings)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if not isBossAuthorized(xPlayer, _src) then return end

    local p = SaveData.PropertiesList[propName]
    if not p or p.owner ~= CFG.SocietyName then
        TriggerClientEvent('esx:showNotification', _src, "~r~Bien introuvable")
        return
    end

    if settings.mode == "sell" or settings.mode == "rent" then
        p.listingMode = settings.mode
    end
    if type(settings.salePrice) == "number" and settings.salePrice > 0 then
        p.salePrice = math.floor(settings.salePrice)
    end
    if type(settings.rentPrice) == "number" and settings.rentPrice >= 0 then
        p.rentPrice = math.floor(settings.rentPrice)
    end

    -- Persist via le mécanisme existant : le module properties sauvegarde via parms/data
    -- mais nos champs (listingMode, salePrice, rentPrice) sont uniquement en mémoire.
    -- On les stocke dans p.parms.realtor pour les rendre persistants.
    p.parms = p.parms or { GradesAlloweds = {}, PeopleAlloweds = {} }
    p.parms.realtor = {
        listingMode = p.listingMode,
        salePrice   = p.salePrice,
        rentPrice   = p.rentPrice,
        originSpawn = p.originSpawn,
        interior    = p.interior,
        neighborhood= p.neighborhood,
        boughtAt    = p.boughtAt,
        boughtFor   = p.boughtFor,
        boughtBy    = p.boughtBy,
    }
    if SavePropreties then
        SavePropreties(p.name, p.data, p.parms)
    end

    TriggerClientEvent('esx:showNotification', _src, "~g~Paramètres mis à jour")

    for _, pid in ipairs(ESX.GetPlayers()) do
        local px = ESX.GetPlayerFromId(pid)
        if px and px.job and px.job.name == CFG.JobName then
            TriggerClientEvent("realtor:dashboardDirty", pid)
        end
    end
end)

-- ----------------------------------------------------------------
-- Re-hydrate les méta realtor depuis parms.realtor au boot
-- ----------------------------------------------------------------
CreateThread(function()
    while not SaveData or not SaveData.PropertiesList do Wait(200) end
    Wait(3000)
    for _, p in pairs(SaveData.PropertiesList) do
        if p.owner == CFG.SocietyName and p.parms and p.parms.realtor then
            local r = p.parms.realtor
            p.listingMode  = p.listingMode  or r.listingMode  or "sell"
            p.salePrice    = p.salePrice    or r.salePrice    or p.price
            p.rentPrice    = p.rentPrice    or r.rentPrice    or 0
            p.originSpawn  = p.originSpawn  or r.originSpawn
            p.interior     = p.interior     or r.interior
            p.neighborhood = p.neighborhood or r.neighborhood
            p.boughtAt     = p.boughtAt     or r.boughtAt
            p.boughtFor    = p.boughtFor    or r.boughtFor
            p.boughtBy     = p.boughtBy     or r.boughtBy
        end
    end
end)

-- ================================================================
-- ÉTAPE 5 : Vente / Location aux citoyens
-- ================================================================

local SaleBillingWaiting = {}  -- [billId] = 'pending' | true | false

local function persistRealtorMeta(p)
    if not p then return end
    p.parms = p.parms or { GradesAlloweds = {}, PeopleAlloweds = {} }
    p.parms.realtor = {
        listingMode = p.listingMode,
        salePrice   = p.salePrice,
        rentPrice   = p.rentPrice,
        originSpawn = p.originSpawn,
        interior    = p.interior,
        neighborhood= p.neighborhood,
        boughtAt    = p.boughtAt,
        boughtFor   = p.boughtFor,
        boughtBy    = p.boughtBy,
    }
    if SavePropreties then
        SavePropreties(p.name, p.data, p.parms)
    end
end

local function broadcastDirty()
    for _, pid in ipairs(ESX.GetPlayers()) do
        local p = ESX.GetPlayerFromId(pid)
        if p and p.job and p.job.name == CFG.JobName then
            TriggerClientEvent("realtor:dashboardDirty", pid)
        end
    end
end

local function requestBillingFromBuyer(targetId, amount, label)
    local billId = math.random(0, 99999999)
    SaleBillingWaiting[billId] = 'pending'
    TriggerClientEvent("realtor:billingDemande", targetId, billId, amount, label)

    local waited = 0
    while SaleBillingWaiting[billId] == 'pending' and waited < 30 do
        Wait(1000); waited = waited + 1
        if not ESX.GetPlayerFromId(targetId) then
            SaleBillingWaiting[billId] = nil
            return false, 'disconnected'
        end
    end
    if SaleBillingWaiting[billId] == 'pending' then
        SaleBillingWaiting[billId] = nil
        return false, 'timeout'
    end
    local accepted = SaleBillingWaiting[billId]
    SaleBillingWaiting[billId] = nil
    if not accepted then return false, 'refused' end
    return true, 'ok'
end

local function chargeBuyer(xTarget, amount)
    local cash = xTarget.getAccount('cash').money
    local bank = xTarget.getAccount('bank').money
    if cash + bank < amount then return false end
    if cash >= amount then
        xTarget.removeAccountMoney('cash', amount)
    else
        if cash > 0 then xTarget.removeAccountMoney('cash', cash) end
        xTarget.removeAccountMoney('bank', amount - cash)
    end
    return true
end

RegisterNetEvent("realtor:billingReponse", function(billId, accepted)
    if SaleBillingWaiting[billId] == 'pending' then
        SaleBillingWaiting[billId] = accepted and true or false
    end
end)

-- ----------------------------------------------------------------
-- VENTE à un joueur
-- ----------------------------------------------------------------
ESX.RegisterServerCallback("realtor:sellToPlayer", function(source, cb, propName, targetId)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget or not isAuthorized(xPlayer, _src) then cb(false, 'error') return end

    local p = SaveData.PropertiesList[propName]
    if not p or p.owner ~= CFG.SocietyName then cb(false, 'unavailable') return end
    if p.listingMode ~= "sell" then cb(false, 'wrongmode') return end

    -- proximité du seller à la porte (anti-abus)
    local sellerPed = GetPlayerPed(_src)
    local sCoords   = GetEntityCoords(sellerPed)
    local door      = vector3(p.positions.EXIT.x, p.positions.EXIT.y, p.positions.EXIT.z)
    if #(sCoords - door) > 25.0 then cb(false, 'farfromdoor') return end

    local price = p.salePrice or p.price
    local cashB = xTarget.getAccount('cash').money
    local bankB = xTarget.getAccount('bank').money
    if cashB + bankB < price then cb(false, 'nomoney') return end

    -- billing
    local ok, reason = requestBillingFromBuyer(targetId, price,
        ("Achat %s — %s"):format(
            (CFG.InteriorTypes[p.interior] and CFG.InteriorTypes[p.interior].label) or p.interior,
            (CFG.Neighborhoods[p.neighborhood] and CFG.Neighborhoods[p.neighborhood].label) or p.neighborhood))
    if not ok then cb(false, reason) return end

    if not chargeBuyer(xTarget, price) then cb(false, 'nomoney') return end

    -- transfert de propriété définitif
    p.owner       = xTarget.identifier
    p.listingMode = nil
    p.parms       = p.parms or { GradesAlloweds = {}, PeopleAlloweds = {} }
    p.parms.realtor = nil  -- plus géré par l'agence

    MySQL.Async.execute('UPDATE properties_list SET owner=@owner, isBuy=1, parms=@parms WHERE name=@name', {
        ["@owner"] = xTarget.identifier,
        ["@parms"] = json.encode(p.parms),
        ["@name"]  = p.name,
    })

    -- crédit société (full montant ; tu peux réintroduire une TVA si besoin)
    creditSociety(price, "Vente immobilière",
        ("Bien: %s\nQuartier: %s\nVendeur: %s\nAcheteur: %s\nMontant: %s$"):format(
            p.label, p.neighborhood or '?', xPlayer.getName(), xTarget.getName(),
            ESX.Math.GroupDigits(price)))

    MySQL.insert(
        'INSERT INTO realtor_sales (property_name, property_label, interior, neighborhood, mode, '..
        'seller_identifier, seller_name, buyer_identifier, buyer_name, price, days, created_at) '..
        'VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',
        { p.name, p.label, p.interior or '?', p.neighborhood or '?', 'sell',
          xPlayer.identifier, xPlayer.getName(), xTarget.identifier, xTarget.getName(),
          price, 0, getDate() }
    )

    TriggerClientEvent("null:properties:UpdatePropertiesList", -1, SaveData.PropertiesList)
    TriggerClientEvent("h:propertySyncProperties", -1)
    TriggerClientEvent("null:properties:UpdatePropertiesBuyed", -1, p.name, true, xTarget.identifier)

    TriggerClientEvent('esx:showNotification', _src,
        ("~g~Bien vendu à %s (%s$)"):format(xTarget.getName(), ESX.Math.GroupDigits(price)))
    TriggerClientEvent('esx:showNotification', targetId,
        ("~g~Vous êtes désormais propriétaire de %s"):format(p.label))

    broadcastDirty()
    cb(true, 'ok')
end)

-- ----------------------------------------------------------------
-- LOCATION à un joueur (paiement upfront pour la durée)
-- ----------------------------------------------------------------
ESX.RegisterServerCallback("realtor:rentToPlayer", function(source, cb, propName, targetId, days)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xTarget = ESX.GetPlayerFromId(targetId)
    if not xTarget or not isAuthorized(xPlayer, _src) then cb(false, 'error') return end

    days = tonumber(days) or 0
    if days < CFG.MinRentalDays or days > CFG.MaxRentalDays then cb(false, 'baddays') return end

    local p = SaveData.PropertiesList[propName]
    if not p or p.owner ~= CFG.SocietyName then cb(false, 'unavailable') return end
    if p.listingMode ~= "rent" then cb(false, 'wrongmode') return end
    if (CFG.InteriorTypes[p.interior] and CFG.InteriorTypes[p.interior].warehouse) then cb(false, 'warehousenorent') return end

    -- proximité seller
    local sCoords = GetEntityCoords(GetPlayerPed(_src))
    local door    = vector3(p.positions.EXIT.x, p.positions.EXIT.y, p.positions.EXIT.z)
    if #(sCoords - door) > 25.0 then cb(false, 'farfromdoor') return end

    -- locataire déjà actif ?
    local existing = MySQL.query.await('SELECT 1 FROM realtor_active_rentals WHERE property_name = ?', { p.name })
    if existing and #existing > 0 then cb(false, 'alreadyrented') return end

    local daily = p.rentPrice or 0
    if daily <= 0 then cb(false, 'badrent') return end
    local total = daily * days

    local cashB = xTarget.getAccount('cash').money
    local bankB = xTarget.getAccount('bank').money
    if cashB + bankB < total then cb(false, 'nomoney') return end

    local ok, reason = requestBillingFromBuyer(targetId, total,
        ("Location %s jours — %s"):format(days,
            (CFG.InteriorTypes[p.interior] and CFG.InteriorTypes[p.interior].label) or p.interior))
    if not ok then cb(false, reason) return end

    if not chargeBuyer(xTarget, total) then cb(false, 'nomoney') return end

    -- enregistrement bail
    local startedAt = now()
    local expiresAt = startedAt + (days * 86400)

    MySQL.execute(
        'INSERT INTO realtor_active_rentals (property_name, tenant_identifier, tenant_name, daily_price, started_at, expires_at) '..
        'VALUES (?,?,?,?,?,?)',
        { p.name, xTarget.identifier, xTarget.getName(), daily, startedAt, expiresAt }
    )

    -- transfère ownership au locataire (réutilise pipeline properties pour entrée/coffre)
    p.owner = xTarget.identifier
    MySQL.Async.execute('UPDATE properties_list SET owner=@owner WHERE name=@name', {
        ["@owner"] = xTarget.identifier, ["@name"] = p.name,
    })

    creditSociety(total, "Location immobilière",
        ("Bien: %s\nLocataire: %s\nDurée: %d jours\nMontant: %s$"):format(
            p.label, xTarget.getName(), days, ESX.Math.GroupDigits(total)))

    MySQL.insert(
        'INSERT INTO realtor_sales (property_name, property_label, interior, neighborhood, mode, '..
        'seller_identifier, seller_name, buyer_identifier, buyer_name, price, days, created_at) '..
        'VALUES (?,?,?,?,?,?,?,?,?,?,?,?)',
        { p.name, p.label, p.interior or '?', p.neighborhood or '?', 'rent',
          xPlayer.identifier, xPlayer.getName(), xTarget.identifier, xTarget.getName(),
          total, days, getDate() }
    )

    TriggerClientEvent("null:properties:UpdatePropertiesList", -1, SaveData.PropertiesList)
    TriggerClientEvent("h:propertySyncProperties", -1)
    TriggerClientEvent("null:properties:UpdatePropertiesBuyed", -1, p.name, true, xTarget.identifier)

    TriggerClientEvent('esx:showNotification', _src,
        ("~g~Bien loué à %s pour %d jours (%s$)"):format(xTarget.getName(), days, ESX.Math.GroupDigits(total)))
    TriggerClientEvent('esx:showNotification', targetId,
        ("~g~Vous êtes locataire de %s jusqu'au %s"):format(p.label, os.date('%d/%m/%Y', expiresAt)))

    broadcastDirty()
    cb(true, 'ok')
end)

-- ----------------------------------------------------------------
-- Thread d'expiration des baux
-- ----------------------------------------------------------------
local function evictTenant(propName)
    local p = SaveData.PropertiesList[propName]
    if not p then return end

    -- Re-attribue à la société
    p.owner       = CFG.SocietyName
    p.listingMode = p.listingMode or "rent"
    -- Vide le coffre + paramètres d'accès au précédent locataire
    p.parms = { GradesAlloweds = {}, PeopleAlloweds = {} }
    -- Clear chest data to prevent next tenant from accessing previous tenant's items
    p.data = {
        ["weapons"] = {},
        ["item"] = {},
        ["accounts"] = { cash = 0, dirtycash = 0 },
    }
    persistRealtorMeta(p)

    MySQL.Async.execute('UPDATE properties_list SET owner=@owner, parms=@parms, data=@data WHERE name=@name', {
        ["@owner"] = CFG.SocietyName,
        ["@parms"] = json.encode(p.parms),
        ["@data"]  = json.encode(p.data),
        ["@name"]  = p.name,
    })

    TriggerClientEvent("null:properties:UpdatePropertiesList", -1, SaveData.PropertiesList)
    TriggerClientEvent("h:propertySyncProperties", -1)
    TriggerClientEvent("null:properties:UpdatePropertiesBuyed", -1, p.name, true, CFG.SocietyName)

    null.InitPrint(("^3[REALTOR] Bail expiré : %s repris par l'agence^0"):format(p.name))
end

CreateThread(function()
    while not SaveData or not SaveData.PropertiesList do Wait(500) end
    Wait(15000)
    while true do
        local nowTs = now()
        local rows = MySQL.query.await(
            'SELECT property_name, tenant_identifier FROM realtor_active_rentals WHERE expires_at <= ?', { nowTs }) or {}
        for _, r in ipairs(rows) do
            evictTenant(r.property_name)
            -- Notifie le locataire s'il est en ligne
            for _, pid in ipairs(ESX.GetPlayers()) do
                local px = ESX.GetPlayerFromId(pid)
                if px and px.identifier == r.tenant_identifier then
                    TriggerClientEvent('esx:showNotification', pid,
                        "~r~Votre bail immobilier a expiré, vous avez été expulsé.")
                    -- force la sortie si à l'intérieur
                    TriggerClientEvent("null:properties:forceExitProperty", pid)
                    break
                end
            end
            MySQL.execute('DELETE FROM realtor_active_rentals WHERE property_name = ?', { r.property_name })
        end
        if #rows > 0 then broadcastDirty() end
        Wait(60000)  -- check toutes les minutes
    end
end)

-- ----------------------------------------------------------------
-- Coffre société : dépôt / retrait depuis la tablette boss
-- ----------------------------------------------------------------
ESX.RegisterServerCallback("realtor:deposit", function(source, cb, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not isAuthorized(xPlayer, source) then return cb(false, 'unauth') end
    amount = tonumber(amount) or 0
    if amount <= 0 then return cb(false, 'badamount') end
    if xPlayer.getAccount('cash').money < amount then return cb(false, 'nomoney') end

    xPlayer.removeAccountMoney('cash', amount)
    creditSociety(amount, "Dépôt agence",
        ("Auteur: %s (%s)"):format(xPlayer.getName(), xPlayer.getIdunique()))

    MySQL.Async.execute("UPDATE society SET data = @data WHERE name = @name", {
        ["@name"] = CFG.SocietyName,
        ["@data"] = json.encode(SocietyCache[CFG.SocietyName].data),
    })

    if null and null.logs and null.logs.send then
        null.logs.send("Logs",
            ("[REALTOR] %s a déposé %d$ au coffre agence"):format(xPlayer.getName(), amount),
            "society", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    end

    broadcastDirty()
    cb(true)
end)

ESX.RegisterServerCallback("realtor:withdraw", function(source, cb, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not isBossAuthorized(xPlayer, source) then return cb(false, 'unauth') end
    amount = tonumber(amount) or 0
    if amount <= 0 then return cb(false, 'badamount') end
    if getSocietyMoney() < amount then return cb(false, 'societynomoney') end

    if not debitSociety(amount, "Retrait agence",
        ("Auteur: %s (%s)"):format(xPlayer.getName(), xPlayer.getIdunique())) then
        return cb(false, 'error')
    end

    -- Application des taxes sur le retrait (mêmes règles que society tablet)
    local newamount = amount
    if RemoveTaxesOfAmount then
        newamount = RemoveTaxesOfAmount("retrait", amount, true,
            (SocietyList and SocietyList[CFG.SocietyName] and SocietyList[CFG.SocietyName].label) or CFG.SocietyName,
            CFG.SocietyName) or amount
    end
    xPlayer.addAccountMoney('cash', newamount)

    MySQL.Async.execute("UPDATE society SET data = @data WHERE name = @name", {
        ["@name"] = CFG.SocietyName,
        ["@data"] = json.encode(SocietyCache[CFG.SocietyName].data),
    })

    if null and null.logs and null.logs.send then
        null.logs.send("Logs",
            ("[REALTOR] %s a retiré %d$ du coffre agence"):format(xPlayer.getName(), amount),
            "society", { idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName() })
    end

    broadcastDirty()
    cb(true)
end)

-- ================================================================
-- CONSTRUCTION
-- ================================================================

local CCFG = CFG.Construction  -- shortcut

-- Pending reconnect notifs for owners of just-finished constructions
-- [identifier] = { label, finishedAt }
local pendingConstructionNotifs = {}

ensureConstructionSchema = function()
    MySQL.execute([[
        CREATE TABLE IF NOT EXISTS `realtor_constructions` (
            `property_name`  VARCHAR(64)  NOT NULL,
            `owner_identifier` VARCHAR(64) NOT NULL,
            `interior`       VARCHAR(32)  NOT NULL,
            `finishes_at`    INT(11)      NOT NULL,
            `notified`       TINYINT(1)   NOT NULL DEFAULT 0,
            PRIMARY KEY (`property_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

local function isUnderConstruction(propName)
    if not propName then return false end
    local p = SaveData.PropertiesList[propName]
    return p and p.underConstruction == true
end

local function getConstructionInfo(propName)
    local row = MySQL.query.await(
        'SELECT * FROM realtor_constructions WHERE property_name = ?', { propName })
    return row and row[1] or nil
end

local function getConstructionsForPlayer(identifier)
    local out = {}
    if not SaveData or not SaveData.PropertiesList then return out end
    for _, p in pairs(SaveData.PropertiesList) do
        if p.underConstruction and p.owner == identifier then
            local info = MySQL.query.await(
                'SELECT * FROM realtor_constructions WHERE property_name = ?', { p.name })
            local row = info and info[1]
            out[#out + 1] = {
                name       = p.name,
                label      = p.label,
                interior   = p.interior,
                finishesAt = row and row.finishes_at or 0,
                positions  = p.positions,
            }
        end
    end
    return out
end

-- ----------------------------------------------------------------
-- realtor:construct callback
-- ----------------------------------------------------------------
ESX.RegisterServerCallback("realtor:construct", function(source, cb, payload)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if not isAuthorized(xPlayer, _src) then return cb(false, 'not_employee') end

    if not CCFG or not CCFG.Enabled then return cb(false, 'disabled') end

    local interiorType = payload and payload.interiorType
    if not interiorType or not CFG.InteriorTypes[interiorType] then
        return cb(false, 'unknown_type')
    end

    local targetId = payload and payload.targetId
    local xTarget  = ESX.GetPlayerFromId(targetId)
    if not xTarget then return cb(false, 'no_target') end

    local price = (CCFG.Prices and CCFG.Prices[interiorType]) or 300000
    local cashT = xTarget.getAccount('cash').money
    local bankT = xTarget.getAccount('bank').money
    if cashT + bankT < price then return cb(false, 'nomoney') end

    -- Billing request to target
    local ok, reason = requestBillingFromBuyer(targetId, price,
        ("Construction %s — À votre position\nMontant : %s$"):format(
            CFG.InteriorTypes[interiorType].label or interiorType,
            ESX.Math.GroupDigits(price)))
    if not ok then return cb(false, reason) end

    if not chargeBuyer(xTarget, price) then return cb(false, 'nomoney') end

    -- Commission société
    if CCFG.CommissionPct and CCFG.CommissionPct > 0 then
        local commission = math.floor(price * CCFG.CommissionPct)
        creditSociety(commission, "Commission construction",
            ("Employé: %s\nClient: %s\nType: %s\nMontant: %s$"):format(
                xPlayer.getName(), xTarget.getName(), interiorType, ESX.Math.GroupDigits(commission)))
    end

    -- Crée la propriété verrouillée (underConstruction)
    local interior = Config.Properties.List[interiorType]
    local x = tonumber(payload.x) or 0
    local y = tonumber(payload.y) or 0
    local z = tonumber(payload.z) or 0
    local positions = {
        ["EXIT"]   = vector3(x, y, z),
        ["ENTER"]  = (interior and interior.positions and interior.positions.inside) or vector3(x, y, z + 1),
        ["COFFRE"] = (interior and interior.positions and interior.positions.cam_coords) or vector3(x, y, z + 1),
    }

    local name      = "construct_" .. genPropertyName()
    local intCFG    = CFG.InteriorTypes[interiorType]
    local nbhKey    = "unknown"
    local label     = string.format("Chantier • %s", intCFG and intCFG.label or interiorType)
    local maxWeight = (interior and interior.MaxWeight) or 250
    local data  = { ["weapons"] = {}, ["item"] = {}, ["accounts"] = { cash = 0, dirtycash = 0 } }
    local parms = { GradesAlloweds = {}, PeopleAlloweds = {
        { identifier = xTarget.identifier, name = xTarget.getName(), perms = { enter = true, deposit = true, withdraw = true } }
    } }
    local buildTime = CCFG.BuildTime or 86400
    local finishesAt = now() + buildTime

    SaveData.PropertiesList[name] = {
        id               = math.random(111111, 999999),
        name             = name,
        label            = label,
        poids            = maxWeight,
        price            = price,
        isBuy            = false,         -- verrouillé jusqu'à fin de construction
        positions        = positions,
        owner            = xTarget.identifier,
        immeuble         = "0",
        data             = data,
        parms            = parms,
        bucketID         = tonumber("21"..tostring(math.random(1111, 9999))),
        interior         = interiorType,
        neighborhood     = nbhKey,
        underConstruction = true,
        finishesAt       = finishesAt,
        builtBy          = xPlayer.getName(),
        builtAt          = now(),
    }

    MySQL.Async.execute(
        'INSERT INTO properties_list (id, name, info, price, coords, immeuble, owner, isBuy, data, parms) '..
        'VALUES (@id, @name, @info, @price, @coords, @immeuble, @owner, @isBuy, @data, @parms)',
        {
            ["@id"]       = SaveData.PropertiesList[name].id,
            ["@name"]     = name,
            ["@info"]     = json.encode({ name = name, label = label, poids = maxWeight }),
            ["@price"]    = price,
            ["@coords"]   = json.encode(positions),
            ["@immeuble"] = "0",
            ["@owner"]    = xTarget.identifier,
            ["@isBuy"]    = 0,
            ["@data"]     = json.encode(data),
            ["@parms"]    = json.encode(parms),
        }
    )

    MySQL.execute(
        'INSERT INTO realtor_constructions (property_name, owner_identifier, interior, finishes_at) VALUES (?,?,?,?)',
        { name, xTarget.identifier, interiorType, finishesAt }
    )

    TriggerClientEvent("null:properties:UpdatePropertiesList", -1, SaveData.PropertiesList)
    TriggerClientEvent("h:propertySyncProperties", -1)

    TriggerClientEvent('esx:showNotification', _src,
        ("~g~Construction lancée pour %s (%s$) — prête dans 24h"):format(
            xTarget.getName(), ESX.Math.GroupDigits(price)))
    TriggerClientEvent('esx:showNotification', targetId,
        ("~g~Votre %s est en construction ! Elle sera prête dans 24h."):format(intCFG and intCFG.label or interiorType))

    broadcastDirty()
    cb(true, 'ok')
end)

-- ----------------------------------------------------------------
-- Thread finition construction
-- ----------------------------------------------------------------
CreateThread(function()
    while not SaveData or not SaveData.PropertiesList do Wait(500) end
    -- Rehydrate underConstruction flag from DB on boot
    Wait(5000)
    local rows = MySQL.query.await('SELECT * FROM realtor_constructions WHERE notified = 0') or {}
    for _, r in ipairs(rows) do
        local p = SaveData.PropertiesList[r.property_name]
        if p then
            p.underConstruction = true
            p.finishesAt = r.finishes_at
        end
    end

    while true do
        Wait(30000)
        local nowTs = now()
        local done = MySQL.query.await(
            'SELECT * FROM realtor_constructions WHERE finishes_at <= ? AND notified = 0', { nowTs }) or {}
        for _, r in ipairs(done) do
            local p = SaveData.PropertiesList[r.property_name]
            if p then
                -- Déverrouille la propriété
                p.underConstruction = nil
                p.finishesAt = nil
                p.isBuy = true
                MySQL.Async.execute('UPDATE properties_list SET isBuy=1 WHERE name=?', { r.property_name })
                TriggerClientEvent("null:properties:UpdatePropertiesList", -1, SaveData.PropertiesList)
                TriggerClientEvent("h:propertySyncProperties", -1)
                TriggerClientEvent("null:properties:UpdatePropertiesBuyed", -1, r.property_name, true, r.owner_identifier)
            end
            MySQL.execute('UPDATE realtor_constructions SET notified=1 WHERE property_name=?', { r.property_name })

            -- Notifie le propriétaire si en ligne, sinon queue
            local notified = false
            for _, pid in ipairs(ESX.GetPlayers()) do
                local px = ESX.GetPlayerFromId(pid)
                if px and px.identifier == r.owner_identifier then
                    TriggerClientEvent('esx:showAdvancedNotification', pid,
                        "~g~CONSTRUCTION TERMINÉE", "Votre propriété",
                        "Votre bien ~y~" .. (p and p.label or r.property_name) .. "~s~ est prêt ! Vous pouvez y entrer.",
                        "CHAR_BLOCKED")
                    notified = true
                    break
                end
            end
            if not notified then
                if not pendingConstructionNotifs[r.owner_identifier] then
                    pendingConstructionNotifs[r.owner_identifier] = {}
                end
                table.insert(pendingConstructionNotifs[r.owner_identifier], {
                    label = p and p.label or r.property_name,
                    time  = os.date("%H:%M"),
                })
            end
        end
        if #done > 0 then broadcastDirty() end
    end
end)

-- ----------------------------------------------------------------
-- Notif construction terminée à la reconnexion
-- ----------------------------------------------------------------
AddEventHandler("esx:playerLoaded", function(playerId, xPlayer)
    local id = xPlayer and xPlayer.identifier
    if not id then return end
    local notifs = pendingConstructionNotifs[id]
    if not notifs or #notifs == 0 then return end
    SetTimeout(6000, function()
        for _, n in ipairs(notifs) do
            TriggerClientEvent('esx:showAdvancedNotification', playerId,
                "~g~CONSTRUCTION TERMINÉE", "Votre propriété",
                "Votre bien ~y~" .. n.label .. "~s~ est prêt depuis ~b~" .. n.time .. "~s~ !",
                "CHAR_BLOCKED")
        end
        pendingConstructionNotifs[id] = nil
    end)
end)

-- ----------------------------------------------------------------
-- Expose helpers internes (pour étape 5)
-- ----------------------------------------------------------------
_G.RealtorInternal = {
    LISTINGS         = LISTINGS,
    getOwnedProperties = getOwnedProperties,
    getActiveRentals = getActiveRentals,
    debitSociety     = debitSociety,
    creditSociety    = creditSociety,
    getSocietyMoney  = getSocietyMoney,
    getDate          = getDate,
    cfg              = CFG,
}
