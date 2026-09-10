-- ============================================================================
-- GOFAST V2 - Server Module
-- Reputation-based illegal transport system
-- ============================================================================

local GoFast = {}
GoFast.activeMissions = {}       -- [identifier] = mission data
GoFast.cooldowns = {}            -- [identifier] = os.time() of last completion
GoFast.crewCooldowns = {}       -- [gangname] = os.time()
GoFast.payLocks = {}             -- [identifier] = true (prevent double pay)

-- ============================================================================
-- SQL MIGRATION
-- ============================================================================
local function ensureGofastColumn(columnName, definition)
    MySQL.Async.fetchScalar([[
        SELECT COUNT(*)
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'gofast_reputation'
          AND COLUMN_NAME = @column
    ]], { ['@column'] = columnName }, function(count)
        if tonumber(count) == 0 then
            MySQL.Async.execute(("ALTER TABLE `gofast_reputation` ADD COLUMN `%s` %s"):format(columnName, definition), {})
        end
    end)
end

MySQL.Async.execute([[
    CREATE TABLE IF NOT EXISTS `gofast_reputation` (
        `identifier` VARCHAR(255) NOT NULL PRIMARY KEY,
        `xp` INT NOT NULL DEFAULT 0,
        `total_missions` INT NOT NULL DEFAULT 0,
        `total_failed` INT NOT NULL DEFAULT 0,
        `blacklisted` TINYINT(1) NOT NULL DEFAULT 0,
        `blacklisted_at` DATETIME DEFAULT NULL,
        `contact_trust` LONGTEXT DEFAULT NULL,
        `last_mission` DATETIME DEFAULT NULL,
        `stolen_cargo_value` INT NOT NULL DEFAULT 0,
        `was_crew_betrayal` TINYINT(1) NOT NULL DEFAULT 0
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
]], {}, function()
    ensureGofastColumn('stolen_cargo_value', 'INT NOT NULL DEFAULT 0')
    ensureGofastColumn('was_crew_betrayal', 'TINYINT(1) NOT NULL DEFAULT 0')
end)

-- ============================================================================
-- REPUTATION HELPERS
-- ============================================================================
function GoFast.GetReputation(identifier, cb)
    MySQL.Async.fetchAll("SELECT * FROM `gofast_reputation` WHERE identifier = @id", {
        ['@id'] = identifier
    }, function(result)
        if result and result[1] then
            local data = result[1]
            data.contact_trust = data.contact_trust and json.decode(data.contact_trust) or {}
            cb(data)
        else
            MySQL.Async.execute("INSERT INTO `gofast_reputation` (identifier) VALUES (@id)", {
                ['@id'] = identifier
            })
            cb({ identifier = identifier, xp = 0, total_missions = 0, total_failed = 0, blacklisted = 0, contact_trust = {}, stolen_cargo_value = 0, was_crew_betrayal = 0 })
        end
    end)
end

function GoFast.AddXP(identifier, amount)
    MySQL.Async.execute("UPDATE `gofast_reputation` SET xp = GREATEST(0, xp + @xp) WHERE identifier = @id", {
        ['@id'] = identifier, ['@xp'] = amount
    })
end

function GoFast.IncrementMissions(identifier)
    MySQL.Async.execute("UPDATE `gofast_reputation` SET total_missions = total_missions + 1, last_mission = NOW() WHERE identifier = @id", {
        ['@id'] = identifier
    })
end

function GoFast.IncrementFailed(identifier)
    MySQL.Async.execute("UPDATE `gofast_reputation` SET total_failed = total_failed + 1 WHERE identifier = @id", {
        ['@id'] = identifier
    })
end

function GoFast.SetBlacklisted(identifier, state, cargoValue, wasCrew)
    if state then
        MySQL.Async.execute("UPDATE `gofast_reputation` SET blacklisted = 1, blacklisted_at = NOW(), xp = 0, stolen_cargo_value = @cv, was_crew_betrayal = @wc WHERE identifier = @id", {
            ['@id'] = identifier,
            ['@cv'] = cargoValue or 0,
            ['@wc'] = wasCrew and 1 or 0,
        })
    else
        MySQL.Async.execute("UPDATE `gofast_reputation` SET blacklisted = 0, blacklisted_at = NULL, stolen_cargo_value = 0, was_crew_betrayal = 0 WHERE identifier = @id", {
            ['@id'] = identifier
        })
    end
end

function GoFast.SaveContactTrust(identifier, trustTable)
    MySQL.Async.execute("UPDATE `gofast_reputation` SET contact_trust = @ct WHERE identifier = @id", {
        ['@id'] = identifier, ['@ct'] = json.encode(trustTable)
    })
end

-- ============================================================================
-- TIER RESOLUTION
-- ============================================================================
function GoFast.GetTierForXP(xp)
    for i = #Config.GoFast.Tiers, 1, -1 do
        local tier = Config.GoFast.Tiers[i]
        if xp >= tier.minXP then
            return tier, i
        end
    end
    return Config.GoFast.Tiers[1], 1
end

function GoFast.GetCrewTier(gangname)
    local level = 1
    if gangname and gangname ~= "unemployed" and gangname ~= "unemployed2" then
        local ok, result = pcall(function() return exports["null-core"]:GetGangLevel(gangname) end)
        if ok and result then level = result end
    end
    for i = #Config.GoFast.CrewTiers, 1, -1 do
        local tier = Config.GoFast.CrewTiers[i]
        if level >= tier.minLevel then
            return tier, i
        end
    end
    return Config.GoFast.CrewTiers[1], 1
end

-- ============================================================================
-- MISSION GENERATION
-- ============================================================================
function GoFast.GenerateMission(tier, isCrew)
    local pickupPool = Config.GoFast.PickupPoints
    local deliveryPool = Config.GoFast.DeliveryPoints

    local pickup = pickupPool[math.random(1, #pickupPool)]
    local delivery = deliveryPool[math.random(1, #deliveryPool)]

    -- Avoid same zone for pickup and delivery
    local attempts = 0
    while delivery.zone == pickup.zone and attempts < 10 do
        delivery = deliveryPool[math.random(1, #deliveryPool)]
        attempts = attempts + 1
    end

    -- Select vehicle from tier pool
    local vehicleModel = tier.vehicles[math.random(1, #tier.vehicles)]

    -- Generate cargo manifest
    local cargo = {}
    for _, cargoDef in ipairs(tier.cargo) do
        local qty = math.random(cargoDef.min, cargoDef.max)
        if qty > 0 then
            table.insert(cargo, {
                item = cargoDef.item,
                label = cargoDef.label,
                amount = qty,
            })
        end
    end

    return {
        id = "GF_" .. os.time() .. "_" .. math.random(1000, 9999),
        pickup = pickup,
        delivery = delivery,
        vehicle = vehicleModel,
        cargo = cargo,
        difficulty = tier.difficulty,
        payMultiplier = tier.payMultiplier,
        tierName = tier.name,
        isCrew = isCrew or false,
        startTime = nil,
        state = "pending", -- pending, active, delivering, completed, failed, betrayed
    }
end

-- ============================================================================
-- CALCULATE PAYMENT
-- ============================================================================
function GoFast.CalculatePayment(mission, engineHealth, elapsedSeconds)
    local totalPay = 0
    local cfg = Config.GoFast.Pay

    for _, item in ipairs(mission.cargo) do
        local basePrice = cfg.basePricePerItem[item.item] or 100
        totalPay = totalPay + (basePrice * item.amount)
    end

    -- Apply tier multiplier
    totalPay = math.floor(totalPay * mission.payMultiplier)

    -- Vehicle condition bonus
    if cfg.vehicleConditionBonus and engineHealth then
        local conditionMult = math.max(0.5, engineHealth / 1000.0)
        totalPay = math.floor(totalPay * conditionMult)
    end

    -- Speed bonus
    if elapsedSeconds and elapsedSeconds < cfg.speedBonus.threshold then
        totalPay = math.floor(totalPay * cfg.speedBonus.multiplier)
    end

    return totalPay
end

-- ============================================================================
-- CARGO VALUE CALCULATION
-- ============================================================================
function GoFast.CalculateCargoValue(cargo)
    if not cargo then return 0 end
    local total = 0
    local prices = Config.GoFast.Pay.basePricePerItem or {}
    if cargo.items then
        for _, item in ipairs(cargo.items) do
            local price = prices[item.name] or prices[item.item] or 0
            local count = item.count or item.amount or 1
            total = total + (price * count)
        end
    elseif type(cargo) == "table" then
        for _, item in ipairs(cargo) do
            local itemName = item.item or item.name
            local price = prices[itemName] or 0
            local count = item.count or item.amount or 1
            total = total + (price * count)
        end
    end
    return total
end

-- ============================================================================
-- POLICE ALERT (with optional pursuit scaling)
-- ============================================================================
function GoFast.AlertPolice(mission)
    if not Config.GoFast.PoliceAlert.enabled then return end

    Citizen.SetTimeout(Config.GoFast.PoliceAlert.delay * 1000, function()
        local xPlayers = ESX.GetPlayers()
        for i = 1, #xPlayers do
            local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
            if xPlayer and SaveData.json["entreprises"] and SaveData.json["entreprises"]["Police"] then
                if SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil then
                    TriggerClientEvent('esx:showAdvancedNotification', xPlayers[i],
                        "INDICATEUR", "Informations",
                        Config.GoFast.PoliceAlert.message,
                        "CHAR_MULTIPLAYER"
                    )
                end
            end
        end
    end)
end

-- ============================================================================
-- GANG PROGRESSION
-- ============================================================================
function GoFast.ProgressGang(xPlayer, payment)
    local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed"
    if gangname == "unemployed" or gangname == "unemployed2" then return end

    local cfg = Config.GoFast.Pay
    for _, missionId in ipairs(cfg.gangMissions) do
        pcall(function() exports["null-core"]:ProgressGangMission(gangname, missionId, 1) end)
    end
    pcall(function() exports["null-core"]:ProgressGangMission(gangname, "daily_dirty_money", payment) end)
    pcall(function() exports["null-core"]:ProgressGangMission(gangname, "weekly_dirty_money_mass", payment) end)
    pcall(function() exports["null-core"]:AddGangXP(gangname, cfg.gangXP) end)
end

-- ============================================================================
-- TRUNK CARGO MANAGEMENT
-- ============================================================================
function GoFast.BuildTrunkItems(cargo)
    local items = {}
    for _, item in ipairs(cargo) do
        local itemWeight = 1
        if ESX.Items[item.item] ~= nil then
            itemWeight = ESX.Items[item.item].weight
        end
        table.insert(items, {
            name = item.item,
            count = item.amount,
            weight = itemWeight,
            label = ESX.GetItemLabel(item.item) or item.label or item.item,
        })
    end
    return items
end

function GoFast.PopulateTrunk(plate, cargo)
    local items = GoFast.BuildTrunkItems(cargo)
    local saveData = { cash = 0, dirtycash = 0, items = items, loadout = {}, clothes = {} }

    -- Check if trunk is already cached (someone has it open)
    local cacheKey = FindStorageCacheKey(plate)
    if cacheKey then
        local cached = InventoryCache.Get(cacheKey)
        if cached then
            cached.data.items = items
            InventoryCache.MarkDirty(cacheKey)
            return
        end
    end

    -- Not cached — write directly to DB
    local jsonData = json.encode(saveData)
    MySQL.Async.fetchAll('SELECT plate FROM vtrunk WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        if result and result[1] then
            MySQL.Async.execute('UPDATE vtrunk SET coffre = @coffre WHERE plate = @plate', {
                ['@coffre'] = jsonData,
                ['@plate'] = plate,
            })
        else
            MySQL.Async.execute('INSERT INTO vtrunk (plate, coffre, owner) VALUES (@plate, @coffre, @owner)', {
                ['@plate'] = plate,
                ['@coffre'] = jsonData,
                ['@owner'] = '',
            })
        end
    end)
end

function GoFast.VerifyCargo(plate, expectedCargo, cb)
    local function checkItems(trunkItems)
        if not trunkItems then
            cb(false, 0)
            return
        end
        local totalExpected = 0
        local totalFound = 0
        for _, expected in ipairs(expectedCargo) do
            totalExpected = totalExpected + expected.amount
            for _, trunkItem in pairs(trunkItems) do
                if trunkItem.name == expected.item then
                    totalFound = totalFound + math.min(trunkItem.count, expected.amount)
                    break
                end
            end
        end
        local ratio = totalExpected > 0 and (totalFound / totalExpected) or 0
        cb(ratio >= 0.95, ratio)
    end

    -- Check cache first
    local cacheKey = FindStorageCacheKey(plate)
    if cacheKey then
        local cached = InventoryCache.Get(cacheKey)
        if cached and cached.data then
            checkItems(cached.data.items)
            return
        end
    end

    -- Fallback to DB
    MySQL.Async.fetchAll('SELECT coffre FROM vtrunk WHERE plate = @plate', {
        ['@plate'] = plate
    }, function(result)
        if not result or not result[1] or not result[1].coffre then
            cb(false, 0)
            return
        end
        local trunkData = json.decode(result[1].coffre)
        checkItems(trunkData and trunkData.items)
    end)
end

function GoFast.CleanTrunk(plate)
    local emptyInventory = { cash = 0, dirtycash = 0, items = {}, loadout = {}, clothes = {} }

    -- Check cache first
    local cacheKey = FindStorageCacheKey(plate)
    if cacheKey then
        local cached = InventoryCache.Get(cacheKey)
        if cached then
            cached.data.items = {}
            cached.data.loadout = {}
            InventoryCache.MarkDirty(cacheKey)
            return
        end
    end

    -- Fallback to DB
    local emptyData = json.encode(emptyInventory)
    MySQL.Async.execute('UPDATE vtrunk SET coffre = @coffre WHERE plate = @plate', {
        ['@coffre'] = emptyData,
        ['@plate'] = plate,
    })
end

-- ============================================================================
-- SERVER EVENTS
-- ============================================================================

-- Request mission data (called from CrimeNet app)
RegisterServerEvent("Null:gofast:requestMission")
AddEventHandler("Null:gofast:requestMission", function(missionType)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.identifier

    GoFast.GetReputation(identifier, function(rep)
        -- Check blacklist
        if rep.blacklisted == 1 then
            TriggerClientEvent("Null:gofast:missionResponse", src, { error = "BLACKLISTED" })
            return
        end

        -- Check cooldown
        local now = os.time()
        if GoFast.cooldowns[identifier] and now - GoFast.cooldowns[identifier] < Config.GoFast.Reputation.soloCooldown then
            local remaining = Config.GoFast.Reputation.soloCooldown - (now - GoFast.cooldowns[identifier])
            TriggerClientEvent("Null:gofast:missionResponse", src, { error = "COOLDOWN", remaining = remaining })
            return
        end

        -- Check if already in a mission
        if GoFast.activeMissions[identifier] then
            TriggerClientEvent("Null:gofast:missionResponse", src, { error = "ALREADY_ACTIVE" })
            return
        end

        local tier, tierIndex
        local isCrew = missionType == "crew"

        if isCrew then
            local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed"
            if gangname == "unemployed" or gangname == "unemployed2" then
                TriggerClientEvent("Null:gofast:missionResponse", src, { error = "NO_GANG" })
                return
            end

            -- Check crew cooldown
            if GoFast.crewCooldowns[gangname] and now - GoFast.crewCooldowns[gangname] < Config.GoFast.Reputation.crewCooldown then
                local remaining = Config.GoFast.Reputation.crewCooldown - (now - GoFast.crewCooldowns[gangname])
                TriggerClientEvent("Null:gofast:missionResponse", src, { error = "COOLDOWN", remaining = remaining })
                return
            end

            -- Check minimum crew members online
            local onlineCount = 0
            local xPlayers = ESX.GetPlayers()
            for i = 1, #xPlayers do
                local p = ESX.GetPlayerFromId(xPlayers[i])
                if p and p.getJob2() and p.getJob2().name == gangname then
                    onlineCount = onlineCount + 1
                end
            end
            if onlineCount < Config.GoFast.Reputation.crewMinPlayers then
                TriggerClientEvent("Null:gofast:missionResponse", src, {
                    error = "NOT_ENOUGH_CREW",
                    required = Config.GoFast.Reputation.crewMinPlayers,
                    online = onlineCount,
                })
                return
            end

            tier, tierIndex = GoFast.GetCrewTier(gangname)
        else
            tier, tierIndex = GoFast.GetTierForXP(rep.xp)
        end

        -- Generate mission
        local mission = GoFast.GenerateMission(tier, isCrew)
        mission.identifier = identifier
        mission.source = src
        mission.state = "pending"

        GoFast.activeMissions[identifier] = mission

        -- Generate unique plate for this mission vehicle
        -- Pad to 8 chars with spaces (GTA pads plates to 8 chars, GetVehicleNumberPlateText returns padded)
        local rawPlate = "GF" .. tostring(math.random(1000, 9999))
        local missionPlate = string.format("%-8s", rawPlate)
        mission.plate = missionPlate

        -- Pre-populate trunk with cargo
        GoFast.PopulateTrunk(missionPlate, mission.cargo)

        TriggerClientEvent("Null:gofast:missionResponse", src, {
            success = true,
            mission = {
                id = mission.id,
                plate = missionPlate,
                pickup = { coords = mission.pickup.coords, label = mission.pickup.label },
                delivery = { coords = mission.delivery.coords, label = mission.delivery.label },
                vehicle = mission.vehicle,
                cargo = mission.cargo,
                difficulty = mission.difficulty,
                tierName = mission.tierName,
                isCrew = mission.isCrew,
            },
        })
    end)
end)

-- Player picked up the vehicle and started driving
RegisterServerEvent("Null:gofast:start")
AddEventHandler("Null:gofast:start", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local mission = GoFast.activeMissions[identifier]
    if not mission then return end

    if mission.state ~= "pending" then return end

    mission.state = "active"
    mission.startTime = os.time()
    mission.source = src

    -- Start betrayal timeout
    Citizen.SetTimeout(Config.GoFast.Betrayal.deliveryTimeout * 1000, function()
        local m = GoFast.activeMissions[identifier]
        if m and m.id == mission.id and m.state == "active" then
            -- Mission timed out = betrayal
            GoFast.HandleBetrayal(identifier, src)
        end
    end)

    -- Alert police
    GoFast.AlertPolice()
end)

-- Player delivered the vehicle - server verifies cargo then rewards
RegisterServerEvent("Null:gofast:complete")
AddEventHandler("Null:gofast:complete", function(engineHealth, plate)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local mission = GoFast.activeMissions[identifier]
    if not mission then return end

    if mission.state ~= "active" then return end

    -- Prevent double pay
    if GoFast.payLocks[identifier] then return end
    GoFast.payLocks[identifier] = true

    local missionPlate = mission.plate or plate

    -- Verify cargo in trunk
    GoFast.VerifyCargo(missionPlate, mission.cargo, function(cargoComplete, ratio)
        mission.state = "completed"
        local elapsed = os.time() - (mission.startTime or os.time())

        if not cargoComplete then
            -- Cargo missing - NPC will attack, reduced/no payment
            GoFast.AddXP(identifier, -Config.GoFast.Reputation.xpLostOnFail)
            GoFast.IncrementFailed(identifier)
            GoFast.cooldowns[identifier] = os.time()
            GoFast.activeMissions[identifier] = nil
            GoFast.CleanTrunk(missionPlate)

            Citizen.SetTimeout(15000, function()
                GoFast.payLocks[identifier] = nil
            end)

            TriggerClientEvent("Null:gofast:result", src, {
                success = false,
                cargoMissing = true,
                cargoRatio = ratio,
                xpLost = Config.GoFast.Reputation.xpLostOnFail,
            })

            -- Refresh profile data for CrimeNet app
            GoFast.SendProfileRefresh(src)
            return
        end

        local payment = GoFast.CalculatePayment(mission, engineHealth, elapsed)

        -- Give reward as dirty cash
        xPlayer.addAccountMoney("dirtycash", payment)

        -- Update reputation
        local xpGain = Config.GoFast.Reputation.xpPerMission + math.floor(mission.difficulty / 2)
        GoFast.AddXP(identifier, xpGain)
        GoFast.IncrementMissions(identifier)

        -- Set cooldown
        GoFast.cooldowns[identifier] = os.time()
        if mission.isCrew then
            local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or nil
            if gangname then GoFast.crewCooldowns[gangname] = os.time() end
        end

        -- Gang progression
        GoFast.ProgressGang(xPlayer, payment)

        -- Clean trunk data
        GoFast.CleanTrunk(missionPlate)

        -- Cleanup
        GoFast.activeMissions[identifier] = nil
        Citizen.SetTimeout(15000, function()
            GoFast.payLocks[identifier] = nil
        end)

        -- Send result to client
        TriggerClientEvent("Null:gofast:result", src, {
            success = true,
            payment = payment,
            xpGain = xpGain,
            engineHealth = engineHealth,
            elapsed = elapsed,
            speedBonus = elapsed < Config.GoFast.Pay.speedBonus.threshold,
        })

        -- Refresh profile data for CrimeNet app
        GoFast.SendProfileRefresh(src)
    end)
end)

-- Player failed / abandoned the mission
RegisterServerEvent("Null:gofast:fail")
AddEventHandler("Null:gofast:fail", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local mission = GoFast.activeMissions[identifier]
    if not mission then return end

    mission.state = "failed"
    GoFast.AddXP(identifier, -Config.GoFast.Reputation.xpLostOnFail)
    GoFast.IncrementFailed(identifier)

    -- Clean trunk if plate exists
    if mission.plate then
        GoFast.CleanTrunk(mission.plate)
    end

    GoFast.activeMissions[identifier] = nil
    GoFast.cooldowns[identifier] = os.time()

    TriggerClientEvent("Null:gofast:result", src, {
        success = false,
        xpLost = Config.GoFast.Reputation.xpLostOnFail,
    })

    -- Refresh profile data for CrimeNet app
    GoFast.SendProfileRefresh(src)
end)

-- Player failed / abandoned the mission
RegisterServerEvent("null:gofast:pickupkey")
AddEventHandler("null:gofast:pickupkey", function(plate)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local mission = GoFast.activeMissions[identifier]
    if not mission then return end

    local idunique = xPlayer.getIdunique()
    if TempsKey[idunique] == nil then
        TempsKey[idunique] = {}
    end
    -- Store with trimmed+uppercased plate (matches Core:requestPlayerCars lookup)
    local cleanPlate = string.upper(plate:match('^%s*(.-)%s*$'))
    TempsKey[idunique][cleanPlate] = "gofast"
    xPlayer.showNotification("Vous avez obtenu les clés de la voiture~s~")
end)

-- Delivery ped recovers remaining cargo after killing player (cargo missing scenario)
RegisterServerEvent("null:gofast:deliveryped:takecargo")
AddEventHandler("null:gofast:deliveryped:takecargo", function(plate)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local mission = GoFast.activeMissions[identifier]
    if not mission then return end

    -- Use provided plate or fall back to mission plate
    local trunkPlate = plate or mission.plate
    if not trunkPlate then return end

    -- Clean the trunk (remove all remaining cargo from vehicle)
    GoFast.CleanTrunk(trunkPlate)

    -- Check if player has stolen cargo items in inventory
    local hasStolenCargo = false
    local stolenItems = {}
    
    if mission.cargo and mission.cargo.items then
        for _, cargoItem in ipairs(mission.cargo.items) do
            local itemName = cargoItem.name
            local invItem = xPlayer.getInventoryItem(itemName)
            if invItem and invItem.count > 0 then
                hasStolenCargo = true
                table.insert(stolenItems, { name = itemName, count = invItem.count })
            end
        end
    end

    if hasStolenCargo then
        -- Player has stolen cargo - remove all of it
        for _, item in ipairs(stolenItems) do
            xPlayer.removeInventoryItem(item.name, item.count)
            null.DebugPrint("[GoFast] Removed stolen cargo from player: " .. item.name .. " x" .. item.count)
        end
        xPlayer.showNotification("~r~L'acheteur t'a pris la marchandise que tu avais volée !")
    else
        -- Player stashed the cargo somewhere else - WIPE + KICK
        null.DebugPrint("[GoFast] Player " .. identifier .. " stashed cargo - triggering wipe")
        
        -- Schedule wipe and kick (same as ambush)
        Citizen.SetTimeout(5000, function()
            if GetPlayerName(src) then
                WipeTable(xPlayer.identifier)
                ExecuteCommand("kick " .. src .. " [CrimeNet] Marchandise dissimulée. Wipe administratif.")
            end
        end)
        
        xPlayer.showNotification("~r~TU AS CACHÉ LA MARCHANDISE. PRÉPARE-TOI À PAYER.")
    end
end)

-- ============================================================================
-- CREW MEMBER LISTING (for CrimeNet member selection modal)
-- ============================================================================
ESX.RegisterServerCallback("Null:gofast:getCrewMembers", function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb({}) return end

    local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed2"
    if gangname == "unemployed" or gangname == "unemployed2" then cb({}) return end

    local members = {}
    local xPlayers = ESX.GetPlayers()
    for i = 1, #xPlayers do
        local p = ESX.GetPlayerFromId(xPlayers[i])
        if p and p.getJob2() and p.getJob2().name == gangname and xPlayers[i] ~= src then
            table.insert(members, {
                serverId = xPlayers[i],
                name = p.getName(),
                identifier = p.identifier,
                grade = p.getJob2().grade_name or "membre",
            })
        end
    end
    cb(members)
end)

-- ============================================================================
-- CREW MISSION WITH SELECTED MEMBERS
-- ============================================================================
RegisterServerEvent("Null:gofast:requestCrewMission")
AddEventHandler("Null:gofast:requestCrewMission", function(selectedMemberIds)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.identifier

    GoFast.GetReputation(identifier, function(rep)
        if rep.blacklisted == 1 then
            TriggerClientEvent("Null:gofast:missionResponse", src, { error = "BLACKLISTED" })
            return
        end

        local now = os.time()

        if GoFast.cooldowns[identifier] and now - GoFast.cooldowns[identifier] < Config.GoFast.Reputation.soloCooldown then
            local remaining = Config.GoFast.Reputation.soloCooldown - (now - GoFast.cooldowns[identifier])
            TriggerClientEvent("Null:gofast:missionResponse", src, { error = "COOLDOWN", remaining = remaining })
            return
        end

        if GoFast.activeMissions[identifier] then
            TriggerClientEvent("Null:gofast:missionResponse", src, { error = "ALREADY_ACTIVE" })
            return
        end

        local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed2"
        if gangname == "unemployed" or gangname == "unemployed2" then
            TriggerClientEvent("Null:gofast:missionResponse", src, { error = "NO_GANG" })
            return
        end

        if GoFast.crewCooldowns[gangname] and now - GoFast.crewCooldowns[gangname] < Config.GoFast.Reputation.crewCooldown then
            local remaining = Config.GoFast.Reputation.crewCooldown - (now - GoFast.crewCooldowns[gangname])
            TriggerClientEvent("Null:gofast:missionResponse", src, { error = "COOLDOWN", remaining = remaining })
            return
        end

        if not selectedMemberIds or type(selectedMemberIds) ~= "table" then
            TriggerClientEvent("Null:gofast:missionResponse", src, { error = "NOT_ENOUGH_CREW", required = Config.GoFast.Reputation.crewMinPlayers, online = 1 })
            return
        end

        local totalCrew = #selectedMemberIds + 1
        if totalCrew < Config.GoFast.Reputation.crewMinPlayers then
            TriggerClientEvent("Null:gofast:missionResponse", src, {
                error = "NOT_ENOUGH_CREW",
                required = Config.GoFast.Reputation.crewMinPlayers,
                online = totalCrew,
            })
            return
        end

        -- Validate each member is online and in same gang
        local validMembers = {}
        for _, memberId in ipairs(selectedMemberIds) do
            local p = ESX.GetPlayerFromId(memberId)
            if p and p.getJob2() and p.getJob2().name == gangname then
                table.insert(validMembers, {
                    serverId = memberId,
                    name = p.getName(),
                    identifier = p.identifier,
                    grade = p.getJob2().grade_name or "membre",
                })
            end
        end

        if (#validMembers + 1) < Config.GoFast.Reputation.crewMinPlayers then
            TriggerClientEvent("Null:gofast:missionResponse", src, {
                error = "NOT_ENOUGH_CREW",
                required = Config.GoFast.Reputation.crewMinPlayers,
                online = #validMembers + 1,
            })
            return
        end

        local tier, tierIndex = GoFast.GetCrewTier(gangname)

        local mission = GoFast.GenerateMission(tier, true)
        mission.identifier = identifier
        mission.source = src
        mission.state = "pending"
        mission.leader = { serverId = src, identifier = identifier, name = xPlayer.getName() }
        mission.crewMembers = validMembers
        mission.gangname = gangname

        GoFast.activeMissions[identifier] = mission

        local rawPlate = "GF" .. tostring(math.random(1000, 9999))
        local missionPlate = string.format("%-8s", rawPlate)
        mission.plate = missionPlate

        GoFast.PopulateTrunk(missionPlate, mission.cargo)

        local missionPayload = {
            id = mission.id,
            plate = missionPlate,
            pickup = { coords = mission.pickup.coords, label = mission.pickup.label },
            delivery = { coords = mission.delivery.coords, label = mission.delivery.label },
            vehicle = mission.vehicle,
            cargo = mission.cargo,
            difficulty = mission.difficulty,
            tierName = mission.tierName,
            isCrew = true,
            crewLeader = src,
        }

        TriggerClientEvent("Null:gofast:missionResponse", src, {
            success = true,
            mission = missionPayload,
        })

        -- Notify crew members
        for _, member in ipairs(validMembers) do
            TriggerClientEvent("Null:gofast:crewMissionNotify", member.serverId, {
                leader = xPlayer.getName(),
                mission = missionPayload,
            })
        end
    end)
end)

-- ============================================================================
-- BETRAYAL SYSTEM (updated: blacklists all crew members on crew missions)
-- ============================================================================
function GoFast.HandleBetrayal(identifier, src)
    local mission = GoFast.activeMissions[identifier]
    if mission then
        mission.state = "betrayed"
    end
    GoFast.activeMissions[identifier] = nil

    -- Calculate stolen cargo value for drive-by scaling
    local cargoValue = mission and GoFast.CalculateCargoValue(mission.cargo) or 0
    local isCrew = mission and mission.isCrew or false

    -- Blacklist + XP wipe (leader)
    GoFast.SetBlacklisted(identifier, true, cargoValue, isCrew)
    GoFast.AddXP(identifier, -Config.GoFast.Reputation.xpLostOnBetray)

    -- Notify leader
    if src and GetPlayerName(src) then
        TriggerClientEvent("Null:gofast:betrayed", src)
    end

    -- Blacklist all crew members if this was a crew mission
    if mission and mission.crewMembers then
        for _, member in ipairs(mission.crewMembers) do
            GoFast.SetBlacklisted(member.identifier, true, cargoValue, true)
            GoFast.AddXP(member.identifier, -Config.GoFast.Reputation.xpLostOnBetray)
            if member.serverId and GetPlayerName(member.serverId) then
                TriggerClientEvent("Null:gofast:betrayed", member.serverId)
            end
            null.DebugPrint("[GoFast] Crew member " .. member.identifier .. " blacklisté (trahison crew)")
        end
    end

    -- Trigger dynamic pursuit proportional to stolen cargo value
    -- if mission and src and GetPlayerName(src) then
    --     GoFast.TriggerPursuit(src, mission)
    -- end

    null.DebugPrint("[GoFast] Joueur " .. identifier .. " blacklisté pour trahison")
end

-- Ambush trigger (called from CrimeNet app when blacklisted player tries to start a mission)
RegisterServerEvent("Null:gofast:triggerAmbush")
AddEventHandler("Null:gofast:triggerAmbush", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    GoFast.GetReputation(xPlayer.identifier, function(rep)
        if rep.blacklisted == 1 then
            -- Pick a random pickup point for the ambush location
            local ambushPoint = Config.GoFast.PickupPoints[math.random(1, #Config.GoFast.PickupPoints)]
            TriggerClientEvent("Null:gofast:ambush", src, {
                coords = ambushPoint.coords,
                pedCount = Config.GoFast.Betrayal.ambushPedCount,
                peds = Config.GoFast.Betrayal.hostilePeds,
                weapons = Config.GoFast.Betrayal.hostileWeapons,
            })

            -- Schedule wipe after ambush
            Citizen.SetTimeout(30000, function()
                if GetPlayerName(src) then
                    WipeTable(xPlayer.identifier)
                    ExecuteCommand("kick " .. src .. " [CrimeNet] Trahison fatale.")
                end
            end)
        end
    end)
end)

-- Drive-by check (called periodically from client when in danger zone)
-- Now scales with stolen cargo value stored in DB
RegisterServerEvent("Null:gofast:dangerZoneCheck")
AddEventHandler("Null:gofast:dangerZoneCheck", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    GoFast.GetReputation(xPlayer.identifier, function(rep)
        if rep.blacklisted == 1 or rep.blacklisted == true then
            local stolenValue = rep.stolen_cargo_value or 0
            local wasCrew = rep.was_crew_betrayal == 1

            -- Resolve drive-by tier from stolen cargo value
            local tier = GoFast.GetDriveByTier(stolenValue)

            -- Fallback to default config if no tiers configured
            local chance = tier and tier.driveByChance or Config.GoFast.Betrayal.driveByChance
            local nbrRandom = math.random()
            null.DebugPrint("[GoFast] Drive-by check — cargo: $" .. stolenValue .. " — chance: " .. chance .. " — roll: " .. nbrRandom)

            if nbrRandom < chance then
                if tier then
                    -- Scaled drive-by: use tier-specific params
                    local vehicleCount = tier.vehicleCount
                    if wasCrew and Config.GoFast.Betrayal.crewDriveByMultiplier then
                        vehicleCount = math.ceil(vehicleCount * Config.GoFast.Betrayal.crewDriveByMultiplier)
                    end

                    TriggerClientEvent("Null:gofast:driveBy", src, {
                        vehicleCount = vehicleCount,
                        pedsPerVehicle = tier.pedsPerVehicle,
                        vehicles = tier.vehicles,
                        peds = tier.peds,
                        weapons = tier.weapons,
                        tierLabel = tier.label,
                        cargoValue = stolenValue,
                    })
                else
                    -- Legacy fallback: original static drive-by
                    local veh = Config.GoFast.Betrayal.driveByVehicles[math.random(1, #Config.GoFast.Betrayal.driveByVehicles)]
                    TriggerClientEvent("Null:gofast:driveBy", src, {
                        vehicleCount = 2,
                        pedsPerVehicle = 3,
                        vehicles = { veh },
                        peds = Config.GoFast.Betrayal.hostilePeds,
                        weapons = Config.GoFast.Betrayal.hostileWeapons,
                    })
                end
            end
        end
    end)
end)

-- ============================================================================
-- SERVER CALLBACKS (for CrimeNet app data)
-- ============================================================================
ESX.RegisterServerCallback("Null:gofast:getProfileData", function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb(nil) return end

    local identifier = xPlayer.identifier
    local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed2"
    local isIllegal = gangname ~= "unemployed" and gangname ~= "unemployed2"

    GoFast.GetReputation(identifier, function(rep)
        local tier, tierIndex = GoFast.GetTierForXP(rep.xp)
        local crewTier, crewTierIndex = nil, 0
        if isIllegal then
            crewTier, crewTierIndex = GoFast.GetCrewTier(gangname)
        end

        -- Resolve unlocked contacts
        local contacts = {}
        for _, contact in ipairs(Config.GoFast.Contacts) do
            local unlocked = rep.xp >= contact.unlockXP
            local trust = rep.contact_trust[contact.id] or 0
            table.insert(contacts, {
                id = contact.id,
                name = unlocked and contact.name or contact.alias,
                avatar = contact.avatar,
                description = unlocked and contact.description or "???",
                unlocked = unlocked,
                trust = trust,
                maxTrust = contact.maxTrust,
                messages = unlocked and contact.messages or nil,
            })
        end

        -- Check cooldown
        local now = os.time()
        local soloCooldownRemaining = 0
        if GoFast.cooldowns[identifier] then
            soloCooldownRemaining = math.max(0, Config.GoFast.Reputation.soloCooldown - (now - GoFast.cooldowns[identifier]))
        end
        local crewCooldownRemaining = 0
        if isIllegal and GoFast.crewCooldowns[gangname] then
            crewCooldownRemaining = math.max(0, Config.GoFast.Reputation.crewCooldown - (now - GoFast.crewCooldowns[gangname]))
        end

        -- Active mission?
        local activeMission = nil
        if GoFast.activeMissions[identifier] then
            local m = GoFast.activeMissions[identifier]
            activeMission = {
                id = m.id,
                state = m.state,
                tierName = m.tierName,
                isCrew = m.isCrew,
                startTime = m.startTime,
            }
        end

        cb({
            isIllegal = isIllegal,
            gangname = gangname,
            xp = rep.xp,
            tier = { name = tier.name, label = tier.label, index = tierIndex, description = tier.description },
            crewTier = crewTier and { name = crewTier.name, label = crewTier.label, index = crewTierIndex } or nil,
            totalMissions = rep.total_missions,
            totalFailed = rep.total_failed,
            blacklisted = rep.blacklisted == 1,
            contacts = contacts,
            soloCooldown = soloCooldownRemaining,
            crewCooldown = crewCooldownRemaining,
            activeMission = activeMission,
            tiers = Config.GoFast.Tiers,
            crewMinPlayers = Config.GoFast.Reputation.crewMinPlayers,
        })
    end)
end)

-- ============================================================================
-- CLEANUP
-- ============================================================================
AddEventHandler('playerDropped', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local mission = GoFast.activeMissions[identifier]
    if mission and (mission.state == "active" or mission.state == "pending") then
        mission.state = "failed"
        GoFast.AddXP(identifier, -Config.GoFast.Reputation.xpLostOnFail)
        GoFast.IncrementFailed(identifier)
        GoFast.activeMissions[identifier] = nil
    end
end)

-- ============================================================================
-- EXPORTS (for CrimeNet app resource)
-- ============================================================================
exports("GoFast_IsBlacklisted", function(identifier, cb)
    GoFast.GetReputation(identifier, function(rep)
        cb(rep.blacklisted == 1)
    end)
end)

exports("GoFast_GetReputation", function(identifier, cb)
    GoFast.GetReputation(identifier, cb)
end)

exports("GoFast_GetTierForXP", function(xp)
    return GoFast.GetTierForXP(xp)
end)

-- ============================================================================
-- PROFILE REFRESH (for CrimeNet app instant update)
-- ============================================================================
function GoFast.SendProfileRefresh(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed2"
    local isIllegal = gangname ~= "unemployed" and gangname ~= "unemployed2"

    GoFast.GetReputation(identifier, function(rep)
        local tier, tierIndex = GoFast.GetTierForXP(rep.xp)
        local crewTier, crewTierIndex = nil, 0
        if isIllegal then
            crewTier, crewTierIndex = GoFast.GetCrewTier(gangname)
        end

        local contacts = {}
        for _, contact in ipairs(Config.GoFast.Contacts) do
            local unlocked = rep.xp >= contact.unlockXP
            local trust = rep.contact_trust[contact.id] or 0
            table.insert(contacts, {
                id = contact.id,
                name = unlocked and contact.name or contact.alias,
                avatar = contact.avatar,
                description = unlocked and contact.description or "???",
                unlocked = unlocked,
                trust = trust,
                maxTrust = contact.maxTrust,
                messages = unlocked and contact.messages or nil,
            })
        end

        local now = os.time()
        local soloCooldownRemaining = 0
        if GoFast.cooldowns[identifier] then
            soloCooldownRemaining = math.max(0, Config.GoFast.Reputation.soloCooldown - (now - GoFast.cooldowns[identifier]))
        end
        local crewCooldownRemaining = 0
        if isIllegal and GoFast.crewCooldowns[gangname] then
            crewCooldownRemaining = math.max(0, Config.GoFast.Reputation.crewCooldown - (now - GoFast.crewCooldowns[gangname]))
        end

        local activeMission = nil
        if GoFast.activeMissions[identifier] then
            local m = GoFast.activeMissions[identifier]
            activeMission = {
                id = m.id,
                state = m.state,
                tierName = m.tierName,
                isCrew = m.isCrew,
                startTime = m.startTime,
            }
        end

        TriggerClientEvent("Null:gofast:profileRefresh", src, {
            isIllegal = isIllegal,
            gangname = gangname,
            xp = rep.xp,
            tier = { name = tier.name, label = tier.label, index = tierIndex, description = tier.description },
            crewTier = crewTier and { name = crewTier.name, label = crewTier.label, index = crewTierIndex } or nil,
            totalMissions = rep.total_missions,
            totalFailed = rep.total_failed,
            blacklisted = rep.blacklisted == 1,
            contacts = contacts,
            soloCooldown = soloCooldownRemaining,
            crewCooldown = crewCooldownRemaining,
            activeMission = activeMission,
            tiers = Config.GoFast.Tiers,
            crewMinPlayers = Config.GoFast.Reputation.crewMinPlayers,
        })
    end)
end

null.DebugPrint("[GoFast V2] Module serveur chargé")
