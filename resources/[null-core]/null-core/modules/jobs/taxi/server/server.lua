-- ============================================================
--  Taxi — Server
--  XP / Rangs · Paiement · Société · Anti-cheat distance
-- ============================================================

local CFG = Config.Taxi

-- En mémoire (réinitialisé au restart). Clé = identifier.
local Drivers = {}    -- { xp, rank, todayRides, todayEarnings, lastResetDay }
local Active  = {}    -- [src] = { mission = "standard", startTime, lastDistance }

-- ---- Helpers ---------------------------------------------------
local function today()
    return os.date("%Y-%m-%d")
end

local function notify(src, msg)
    TriggerClientEvent('esx:showNotification', src, msg)
end

local function getDriver(identifier)
    if not Drivers[identifier] then
        Drivers[identifier] = {
            xp = 0, rank = "novice",
            todayRides = 0, todayEarnings = 0,
            lastResetDay = today(),
        }
    end
    -- Reset journalier
    if Drivers[identifier].lastResetDay ~= today() then
        Drivers[identifier].todayRides    = 0
        Drivers[identifier].todayEarnings = 0
        Drivers[identifier].lastResetDay  = today()
    end
    return Drivers[identifier]
end

local function rankFromXp(xp)
    local current = CFG.Ranks[1]
    for _, r in ipairs(CFG.Ranks) do
        if xp >= r.minXp then current = r end
    end
    return current
end

local function rankIndex(key)
    for i, r in ipairs(CFG.Ranks) do
        if r.key == key then return i end
    end
    return 1
end

local function meetsRank(driver, requiredKey)
    if not requiredKey then return true end
    return rankIndex(driver.rank) >= rankIndex(requiredKey)
end

local function payToSociety(amount)
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_taxi', function(account)
        if account then account.addMoney(amount) end
    end)
end

-- ---- Callback : profil chauffeur ------------------------------
ESX.RegisterServerCallback('null:taxi:getProfile', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= "taxi" then return cb(nil) end
    local driver = getDriver(xPlayer.identifier)
    local rank   = rankFromXp(driver.xp)
    driver.rank  = rank.key

    local nextRank
    for _, r in ipairs(CFG.Ranks) do
        if r.minXp > driver.xp then nextRank = r; break end
    end

    cb({
        xp            = driver.xp,
        rank          = rank,
        nextRank      = nextRank,
        todayRides    = driver.todayRides,
        todayEarnings = driver.todayEarnings,
        dailyGoal     = CFG.Economy.DailyRideGoal,
        identifier    = xPlayer.identifier,
        playerName    = xPlayer.getName and xPlayer.getName() or "Chauffeur",
    })
end)

-- ---- Callback : démarrage de mission --------------------------
ESX.RegisterServerCallback('null:taxi:startMission', function(source, cb, missionKey)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= "taxi" then return cb(false, "no_job") end

    local mission = CFG.Missions[missionKey]
    if not mission then return cb(false, "no_mission") end

    local driver = getDriver(xPlayer.identifier)
    if not meetsRank(driver, mission.requireRank) then
        notify(source, "~r~Rang insuffisant pour cette mission")
        return cb(false, "no_rank")
    end

    if Active[source] then
        return cb(false, "already_active")
    end

    -- Priorité joueur : bloque les missions IA tant qu'une demande joueur
    -- n'a pas été prise par quelqu'un.
    local ok, pending = pcall(function() return exports["null-core"]:HasPendingTaxiRequest() end)
    if ok and pending then
        notify(source, "~r~Un joueur attend un taxi — prenez d'abord sa demande")
        return cb(false, "player_priority")
    end

    Active[source] = {
        mission   = missionKey,
        startTime = os.time(),
    }
    cb(true, mission)
end)

-- ---- Cancel mission --------------------------------------------
RegisterNetEvent('null:taxi:cancelMission', function()
    local src = source
    Active[src] = nil
end)

-- ---- Finalisation : paiement + XP ------------------------------
ESX.RegisterServerCallback('null:taxi:finishMission', function(source, cb, payload)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= "taxi" then return cb(false) end

    local active = Active[source]
    if not active then return cb(false) end
    Active[source] = nil

    local mission = CFG.Missions[active.mission]
    if not mission then return cb(false) end

    -- Anti-abuse : valeurs bornées côté server
    local distanceMeters = math.max(0, math.min(50000, tonumber(payload.distanceMeters) or 0))
    local moodPercent    = math.max(0, math.min(100, tonumber(payload.moodPercent) or 0))
    local elapsedSec     = math.max(1, math.min(7200, tonumber(payload.elapsedSec) or 1))

    -- Calcul fare
    local baseFare = CFG.Economy.BaseFare
    local distFare = (distanceMeters / 1000.0) * CFG.Economy.PerKilometer
    local fare     = baseFare + distFare

    -- Multiplicateur mission
    local missMul = CFG.Economy.MissionMultiplier[active.mission] or 1.0
    fare = fare * missMul

    -- Multiplicateur rang
    local driver  = getDriver(xPlayer.identifier)
    local rank    = rankFromXp(driver.xp)
    fare = fare * (rank.payMul or 1.0)

    -- Bonus express si terminé sous le seuil
    if mission.timeBonus and mission.timeBonusUnder and elapsedSec <= mission.timeBonusUnder then
        fare = fare * 1.30
    end

    -- Pourboire (selon humeur)
    local moodFactor = moodPercent / 100.0
    local tip        = fare * CFG.Economy.TipMultiplier * moodFactor * (mission.tipBase or 1.0)
    if mission.moodCritical and moodPercent < 50 then
        tip = 0
    end

    fare = math.floor(fare)
    tip  = math.floor(tip)
    local total = fare + tip

    -- Paiement joueur + société
    xPlayer.addAccountMoney('bank', total, {
        title = 'Course Taxi',
        description = mission.label or "Course",
        category = 'salary',
    })
    payToSociety(math.floor(total * (CFG.Economy.SocietyShare or 1.0)))

    -- XP / Rang
    local xpGain = (CFG.XpReward[active.mission] or 1)
    if moodPercent >= 80 then xpGain = xpGain + 1 end
    driver.xp            = driver.xp + xpGain
    driver.todayRides    = driver.todayRides + 1
    driver.todayEarnings = driver.todayEarnings + total

    local newRank = rankFromXp(driver.xp)
    local rankUp  = (newRank.key ~= driver.rank)
    driver.rank   = newRank.key

    -- Bonus journalier
    local dailyBonus = 0
    if driver.todayRides == CFG.Economy.DailyRideGoal then
        dailyBonus = CFG.Economy.DailyBonus or 0
        if dailyBonus > 0 then
            xPlayer.addAccountMoney('bank', dailyBonus, {
                title = 'Bonus Journalier Taxi',
                description = 'Objectif de courses atteint',
                category = 'salary',
            })
            driver.todayEarnings = driver.todayEarnings + dailyBonus
        end
    end

    cb(true, {
        fare         = fare,
        tip          = tip,
        total        = total,
        xpGain       = xpGain,
        rankUp       = rankUp,
        rank         = newRank,
        dailyBonus   = dailyBonus,
        todayRides   = driver.todayRides,
    })
end)

--RegisterServerEvent('Ouvre:taxi')
--AddEventHandler('Ouvre:taxi', function()
   -- local xPlayer = ESX.GetPlayerFromId(source)
   -- if not xPlayer or xPlayer.job.name ~= "taxi" then return end
   -- local logo  = SocietyList and SocietyList["taxi"] and SocietyList["taxi"].logo ~= "" and SocietyList["taxi"].logo or nil
  --  local color = SocietyList and SocietyList["taxi"] and SocietyList["taxi"].brandColor or nil
  --  TriggerClientEvent('null:notificationAdvanced', -1,
  --      'Le service de taxi est désormais ~g~Disponible~s~ !', 'Taxi', 'Annonce', color, logo)
--end)

--RegisterServerEvent('Ferme:taxi')
--AddEventHandler('Ferme:taxi', function()
  --  local xPlayer = ESX.GetPlayerFromId(source)
   -- if not xPlayer or xPlayer.job.name ~= "taxi" then return end
   -- local logo  = SocietyList and SocietyList["taxi"] and SocietyList["taxi"].logo ~= "" and SocietyList["taxi"].logo or nil
   -- local color = SocietyList and SocietyList["taxi"] and SocietyList["taxi"].brandColor or nil
   -- TriggerClientEvent('null:notificationAdvanced', -1,
   --     'Le service de taxi est désormais ~r~Indisponible~s~ !', 'Taxi', 'Annonce', color, logo)
--end)

-- ---- Compatibilité ancienne (taxi:FinishMission) --------------
RegisterNetEvent("taxi:FinishMission")
AddEventHandler("taxi:FinishMission", function(distanceBonus)
    -- Conservé pour ne pas casser les anciens scripts qui l'appellent.
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= "taxi" then return end
    if (tonumber(distanceBonus) or 0) > 30000 then return end
    local bonus = math.floor((tonumber(distanceBonus) or 0) * (CFG.Economy.PerKilometer / 1000.0))
    local gain  = math.random(800, 1500) + bonus
    xPlayer.addAccountMoney('bank', gain, {
        title = 'Course Taxi (legacy)', description = 'Course terminée', category = 'salary'
    })
    payToSociety(gain)
    notify(source, ("Course terminée — ~g~+%d$"):format(gain))
end)

-- ---- Cleanup ---------------------------------------------------
AddEventHandler('playerDropped', function()
    Active[source] = nil
end)

-- ---- Export pour autres modules --------------------------------
exports("GetTaxiDriver", function(identifier)
    return Drivers[identifier]
end)
