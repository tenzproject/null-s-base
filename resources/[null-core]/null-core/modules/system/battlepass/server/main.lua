-- ============================================================================
-- BATTLE PASS SERVER MODULE
-- ============================================================================

local BattlePass = {}
local PlayerBPCache = {} -- [identifier] = { level, xp, claimed_free, claimed_premium, season_id }

-- ============================================================================
-- SQL MIGRATION
-- ============================================================================
local function RunMigration()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `vbattlepass_progress` (
            `identifier` VARCHAR(60) NOT NULL,
            `season_id` VARCHAR(60) NOT NULL DEFAULT 'season_1',
            `level` INT NOT NULL DEFAULT 1,
            `xp` INT NOT NULL DEFAULT 0,
            `claimed_free` TEXT DEFAULT NULL,
            `claimed_premium` TEXT DEFAULT NULL,
            `last_xp_tick` BIGINT DEFAULT 0,
            PRIMARY KEY (`identifier`, `season_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `vbattlepass_seasons` (
            `season_id` VARCHAR(60) NOT NULL PRIMARY KEY,
            `name` VARCHAR(120) NOT NULL,
            `start_date` BIGINT NOT NULL,
            `end_date` BIGINT NOT NULL,
            `active` TINYINT(1) NOT NULL DEFAULT 1
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})
end

Citizen.CreateThread(function()
    Wait(2000)
    RunMigration()
    Wait(1000)
    BattlePass.EnsureCurrentSeason()
end)

-- ============================================================================
-- SEASON MANAGEMENT
-- ============================================================================
function BattlePass.EnsureCurrentSeason()
    local season = Config.BattlePass.CurrentSeason
    if not season then return end

    MySQL.Async.fetchAll("SELECT * FROM vbattlepass_seasons WHERE season_id = @id", {
        ['@id'] = season.id
    }, function(result)
        if not result or not result[1] then
            local startDate = os.time()
            local endDate = startDate + (Config.BattlePass.SeasonDurationDays * 86400)
            MySQL.Async.execute([[
                INSERT INTO vbattlepass_seasons (season_id, name, start_date, end_date, active)
                VALUES (@id, @name, @start, @endDate, 1)
            ]], {
                ['@id'] = season.id,
                ['@name'] = season.name,
                ['@start'] = startDate,
                ['@endDate'] = endDate,
            })
            print(('[BattlePass] Season "%s" created. Ends in %d days.'):format(season.name, Config.BattlePass.SeasonDurationDays))
        else
            local row = result[1]
            if row.active == 1 and tonumber(row.end_date) <= os.time() then
                MySQL.Async.execute("UPDATE vbattlepass_seasons SET active = 0 WHERE season_id = @id", {
                    ['@id'] = season.id
                })
                print(('[BattlePass] Season "%s" has expired.'):format(row.name))
            end
        end
    end)
end

function BattlePass.GetSeasonInfo(cb)
    local season = Config.BattlePass.CurrentSeason
    if not season then cb(nil) return end

    MySQL.Async.fetchAll("SELECT * FROM vbattlepass_seasons WHERE season_id = @id", {
        ['@id'] = season.id
    }, function(result)
        if result and result[1] then
            local row = result[1]
            cb({
                id = row.season_id,
                name = row.name,
                startDate = tonumber(row.start_date),
                endDate = tonumber(row.end_date),
                active = row.active == 1,
                timeLeft = math.max(0, tonumber(row.end_date) - os.time()),
            })
        else
            cb(nil)
        end
    end)
end

-- ============================================================================
-- XP & LEVEL CALCULATIONS
-- ============================================================================
function BattlePass.GetRequiredXP(level)
    local cfg = Config.BattlePass.XP
    return cfg.BaseXP + (level - 1) * cfg.XPPerLevel
end

function BattlePass.GetTotalXPForLevel(level)
    local total = 0
    for i = 1, level - 1 do
        total = total + BattlePass.GetRequiredXP(i)
    end
    return total
end

-- ============================================================================
-- PLAYER DATA LOADING
-- ============================================================================
function BattlePass.LoadPlayerData(identifier, cb)
    local seasonId = Config.BattlePass.CurrentSeason.id
    MySQL.Async.fetchAll("SELECT * FROM vbattlepass_progress WHERE identifier = @id AND season_id = @season", {
        ['@id'] = identifier,
        ['@season'] = seasonId,
    }, function(result)
        local data
        if result and result[1] then
            local row = result[1]
            data = {
                level = tonumber(row.level) or 1,
                xp = tonumber(row.xp) or 0,
                claimed_free = row.claimed_free and json.decode(row.claimed_free) or {},
                claimed_premium = row.claimed_premium and json.decode(row.claimed_premium) or {},
                last_xp_tick = tonumber(row.last_xp_tick) or 0,
            }
        else
            data = {
                level = 1,
                xp = 0,
                claimed_free = {},
                claimed_premium = {},
                last_xp_tick = os.time(),
            }
            MySQL.Async.execute([[
                INSERT INTO vbattlepass_progress (identifier, season_id, level, xp, claimed_free, claimed_premium, last_xp_tick)
                VALUES (@id, @season, 1, 0, '[]', '[]', @tick)
            ]], {
                ['@id'] = identifier,
                ['@season'] = seasonId,
                ['@tick'] = os.time(),
            })
        end
        PlayerBPCache[identifier] = data
        if cb then cb(data) end
    end)
end

function BattlePass.SavePlayerData(identifier)
    local data = PlayerBPCache[identifier]
    if not data then return end
    local seasonId = Config.BattlePass.CurrentSeason.id
    MySQL.Async.execute([[
        UPDATE vbattlepass_progress
        SET level = @level, xp = @xp, claimed_free = @cf, claimed_premium = @cp, last_xp_tick = @tick
        WHERE identifier = @id AND season_id = @season
    ]], {
        ['@level'] = data.level,
        ['@xp'] = data.xp,
        ['@cf'] = json.encode(data.claimed_free),
        ['@cp'] = json.encode(data.claimed_premium),
        ['@tick'] = data.last_xp_tick,
        ['@id'] = identifier,
        ['@season'] = seasonId,
    })
end

-- ============================================================================
-- ADD XP & LEVEL UP
-- ============================================================================
function BattlePass.AddXP(identifier, amount)
    local data = PlayerBPCache[identifier]
    if not data then return end
    if data.level >= Config.BattlePass.MaxLevel then return end

    data.xp = data.xp + amount

    -- Check for level ups
    local leveled = false
    while data.level < Config.BattlePass.MaxLevel do
        local required = BattlePass.GetRequiredXP(data.level)
        if data.xp >= required then
            data.xp = data.xp - required
            data.level = data.level + 1
            leveled = true
        else
            break
        end
    end

    -- Cap XP at max level
    if data.level >= Config.BattlePass.MaxLevel then
        data.xp = 0
    end

    PlayerBPCache[identifier] = data
    BattlePass.SavePlayerData(identifier)

    return leveled
end

-- ============================================================================
-- PLAYTIME XP TICK (runs every N minutes for each online player)
-- ============================================================================
Citizen.CreateThread(function()
    Wait(10000) -- Wait for server to initialize
    while true do
        local tickMinutes = Config.BattlePass.XP.PlaytimeTickMinutes
        Wait(tickMinutes * 60 * 1000) -- Wait N minutes

        if not Config.BattlePass.Enabled then goto continue end

        local players = ESX.GetPlayers()
        for _, playerId in ipairs(players) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            if xPlayer and xPlayer.identifier then
                local data = PlayerBPCache[xPlayer.identifier]
                if data then
                    local xpAmount = Config.BattlePass.XP.PlaytimeXPPerMinute * tickMinutes
                    local leveled = BattlePass.AddXP(xPlayer.identifier, xpAmount)

                    -- Notify client of XP gain
                    TriggerClientEvent('null:battlepass:xpGain', playerId, xpAmount, data.level, data.xp, BattlePass.GetRequiredXP(data.level))

                    if leveled then
                        TriggerClientEvent('null:battlepass:levelUp', playerId, data.level)
                    end
                end
            end
        end

        ::continue::
    end
end)

-- ============================================================================
-- CLAIM REWARD
-- ============================================================================
function BattlePass.ClaimReward(identifier, source, level, track)
    local data = PlayerBPCache[identifier]
    if not data then return false, "Données introuvables" end

    -- Check level reached
    if data.level < level then
        return false, "Niveau insuffisant"
    end

    -- Check track
    local claimedList
    if track == "free" then
        claimedList = data.claimed_free
    elseif track == "premium" then
        -- Check if player has premium access
        local isVip, vipType = GetVIP(identifier)
        local hasPremium = isVip and Config.VIP.Tiers[vipType] and Config.VIP.Tiers[vipType].advantages.battlePassIncluded
        if not hasPremium then
            return false, "Passe Premium requis"
        end
        claimedList = data.claimed_premium
    else
        return false, "Track invalide"
    end

    -- Check not already claimed
    for _, cl in ipairs(claimedList) do
        if cl == level then
            return false, "Déjà réclamé"
        end
    end

    -- Find reward in config
    local reward = nil
    for _, r in ipairs(Config.BattlePass.CurrentSeason.Rewards) do
        if r.level == level then
            reward = r[track]
            break
        end
    end

    if not reward then
        return false, "Aucune récompense à ce niveau"
    end

    -- Give reward
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return false, "Joueur introuvable" end

    local success, msg = BattlePass.GiveReward(xPlayer, reward)
    if not success then
        return false, msg or "Erreur lors de la distribution"
    end

    -- Mark as claimed
    table.insert(claimedList, level)
    BattlePass.SavePlayerData(identifier)

    return true, reward.label
end

function BattlePass.GiveReward(xPlayer, reward)
    if reward.type == "money" then
        xPlayer.addAccountMoney('bank', reward.amount)
    elseif reward.type == "coins" then
        -- Add coins via tebex wallet
        local identifiers = GetPlayerIdentifiers(xPlayer.source)
        local fivemId = nil
        for _, v in pairs(identifiers) do
            local before, after = v:match("([^:]+):([^:]+)")
            if before == "fivem" then fivemId = after break end
        end
        if fivemId then
            LiteMySQL:Insert('tebex_players_wallet', {
                identifiers = fivemId,
                idunique = xPlayer.getIdunique(),
                transaction = 'Récompense Passe de Combat: ' .. reward.label,
                price = 0,
                currency = 'Points',
                points = reward.amount,
            })
        end
    elseif reward.type == "item" then
        xPlayer.addInventoryItem(reward.name, reward.amount or 1)
    elseif reward.type == "weapon" then
        xPlayer.addWeapon(reward.name, reward.ammo or 250, nil, reward.permanent or false, 0)
    elseif reward.type == "vehicle" then
        -- Add vehicle to owned_vehicles
        local characters = { "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z" }
        local plate = ""
        math.randomseed(GetGameTimer() + xPlayer.source)
        for i = 1, 3 do plate = plate .. characters[math.random(1, #characters)] end
        plate = plate .. math.random(1000, 9999)

        local oldCacheData = exports["null-core"]:GetCacheData("owned_vehicles")
        oldCacheData[string.upper(plate)] = {
            owner = xPlayer.identifier,
            plate = string.upper(plate),
            model = reward.model,
            label = reward.model,
            vehicle = { model = GetHashKey(reward.model), plate = plate },
            coffre = {},
            type = "car",
            state = true,
            boutique = true,
            garage = true,
        }
        exports["null-core"]:EditCacheData("owned_vehicles", oldCacheData)
    elseif reward.type == "crate" then
        xPlayer.addInventoryItem(reward.name, reward.amount or 1)
    else
        return false, "Type de récompense inconnu"
    end

    xPlayer.showNotification(("~g~Passe de Combat~s~\nVous avez reçu : %s"):format(reward.label))
    return true
end

-- ============================================================================
-- PLAYER LOAD / UNLOAD
-- ============================================================================
AddEventHandler('esx:playerLoaded', function(source, xPlayer)
    if not Config.BattlePass.Enabled then return end
    BattlePass.LoadPlayerData(xPlayer.identifier)
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer and xPlayer.identifier and PlayerBPCache[xPlayer.identifier] then
        BattlePass.SavePlayerData(xPlayer.identifier)
        PlayerBPCache[xPlayer.identifier] = nil
    end
end)

-- ============================================================================
-- SERVER CALLBACKS
-- ============================================================================
ESX.RegisterServerCallback('null:battlepass:getData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    if not Config.BattlePass.Enabled then cb(nil) return end

    local identifier = xPlayer.identifier
    local data = PlayerBPCache[identifier]

    if not data then
        BattlePass.LoadPlayerData(identifier, function(loaded)
            BattlePass.GetSeasonInfo(function(seasonInfo)
                local isVip, vipType = GetVIP(identifier)
                local hasPremium = isVip and Config.VIP.Tiers[vipType] and Config.VIP.Tiers[vipType].advantages.battlePassIncluded or false
                cb({
                    level = loaded.level,
                    xp = loaded.xp,
                    requiredXP = BattlePass.GetRequiredXP(loaded.level),
                    maxLevel = Config.BattlePass.MaxLevel,
                    claimedFree = loaded.claimed_free,
                    claimedPremium = loaded.claimed_premium,
                    hasPremium = hasPremium,
                    season = seasonInfo,
                    rewards = BattlePass.FormatRewardsForNUI(),
                })
            end)
        end)
        return
    end

    BattlePass.GetSeasonInfo(function(seasonInfo)
        local isVip, vipType = GetVIP(identifier)
        local hasPremium = isVip and Config.VIP.Tiers[vipType] and Config.VIP.Tiers[vipType].advantages.battlePassIncluded or false
        cb({
            level = data.level,
            xp = data.xp,
            requiredXP = BattlePass.GetRequiredXP(data.level),
            maxLevel = Config.BattlePass.MaxLevel,
            claimedFree = data.claimed_free,
            claimedPremium = data.claimed_premium,
            hasPremium = hasPremium,
            season = seasonInfo,
            rewards = BattlePass.FormatRewardsForNUI(),
        })
    end)
end)

function BattlePass.FormatRewardsForNUI()
    local rewards = {}
    for _, r in ipairs(Config.BattlePass.CurrentSeason.Rewards) do
        local free = r.free
        local premium = r.premium

        if free and free.type == "money" and free.name == nil then
            free = table.clone and table.clone(free) or json.decode(json.encode(free))
            free.name = "cash"
        elseif free and free.type == "coins" and free.name == nil then
            free = table.clone and table.clone(free) or json.decode(json.encode(free))
            free.name = "fidelcoins"
        end

        if premium and premium.type == "money" and premium.name == nil then
            premium = table.clone and table.clone(premium) or json.decode(json.encode(premium))
            premium.name = "cash"
        elseif premium and premium.type == "coins" and premium.name == nil then
            premium = table.clone and table.clone(premium) or json.decode(json.encode(premium))
            premium.name = "fidelcoins"
        end

        table.insert(rewards, {
            level = r.level,
            free = free,
            premium = premium,
        })
    end
    return rewards
end

ESX.RegisterServerCallback('null:battlepass:claimReward', function(source, cb, level, track)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false, "Joueur introuvable") return end

    local success, msg = BattlePass.ClaimReward(xPlayer.identifier, source, level, track)

    if success then
        local data = PlayerBPCache[xPlayer.identifier]
        cb(true, msg, {
            claimedFree = data.claimed_free,
            claimedPremium = data.claimed_premium,
        })
    else
        cb(false, msg)
    end
end)

-- ============================================================================
-- BUY LEVEL WITH COINS
-- ============================================================================
local BP_LEVEL_COST = 150

local function BP_GetFivemId(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, v in pairs(identifiers) do
        local before, after = v:match("([^:]+):([^:]+)")
        if before == "fivem" then return after end
    end
    return nil
end

local function BP_GetPlayerCoins(fivemId, cb)
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

local function BP_DeductCoins(fivemId, xPlayer, amount, transaction, cb)
    BP_GetPlayerCoins(fivemId, function(current)
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
        BP_GetPlayerCoins(fivemId, function(newCoins)
            cb(true, newCoins)
        end)
    end)
end

ESX.RegisterServerCallback('null:battlepass:buyLevel', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false, "Joueur introuvable") return end

    local identifier = xPlayer.identifier
    local data = PlayerBPCache[identifier]
    if not data then cb(false, "Données non chargées") return end

    if data.level >= Config.BattlePass.MaxLevel then
        cb(false, "Vous êtes déjà au niveau maximum")
        return
    end

    local fivemId = BP_GetFivemId(source)
    if not fivemId then cb(false, "Identifiant introuvable") return end

    BP_DeductCoins(fivemId, xPlayer, BP_LEVEL_COST, string.format("Passe de Combat: Achat niveau %d", data.level + 1), function(success, newCoins)
        if not success then
            cb(false, "Coins insuffisants (il faut " .. BP_LEVEL_COST .. " coins)")
            return
        end

        -- Level up the player
        data.level = data.level + 1
        data.xp = 0
        PlayerBPCache[identifier] = data
        BattlePass.SavePlayerData(identifier)

        xPlayer.showNotification(("~g~Passe de Combat~s~\nNiveau %d acheté !"):format(data.level))

        cb(true, "Niveau " .. data.level .. " débloqué !", {
            level = data.level,
            xp = data.xp,
            requiredXP = BattlePass.GetRequiredXP(data.level),
            coins = newCoins,
        })
    end)
end)

-- ============================================================================
-- VIP ADVANTAGES HELPERS (server exports)
-- ============================================================================
function GetVIPAdvantage(identifier, key)
    local isVip, vipType = GetVIP(identifier)
    if not isVip or not vipType then
        return Config.VIP.Defaults[key]
    end
    local tier = Config.VIP.Tiers[vipType]
    if tier and tier.advantages and tier.advantages[key] ~= nil then
        return tier.advantages[key]
    end
    return Config.VIP.Defaults[key]
end

function GetVIPSellBoost(identifier)
    return GetVIPAdvantage(identifier, "sellBoostPct") or 0
end

function GetVIPFarmSellBoost(identifier)
    return GetVIPAdvantage(identifier, "farmSellBoostPct") or 0
end

function GetVIPFarmHarvestBoost(identifier)
    return GetVIPAdvantage(identifier, "farmHarvestBoostPct") or 0
end

function GetVIPActivitySellBoost(identifier)
    return GetVIPAdvantage(identifier, "activitySellBoostPct") or 0
end

function GetVIPRepairTime(identifier)
    return GetVIPAdvantage(identifier, "repairTimeMinutes") or Config.VIP.Defaults.repairTimeMinutes
end

function GetVIPDeathTimer(identifier)
    return GetVIPAdvantage(identifier, "deathTimerMinutes") or Config.VIP.Defaults.deathTimerMinutes
end

function GetVIPMaxWeight(identifier)
    return GetVIPAdvantage(identifier, "maxWeight") or Config.VIP.Defaults.maxWeight
end

exports('GetVIPAdvantage', GetVIPAdvantage)
exports('GetVIPSellBoost', GetVIPSellBoost)
exports('GetVIPFarmSellBoost', GetVIPFarmSellBoost)
exports('GetVIPFarmHarvestBoost', GetVIPFarmHarvestBoost)
exports('GetVIPActivitySellBoost', GetVIPActivitySellBoost)
exports('GetVIPRepairTime', GetVIPRepairTime)
exports('GetVIPDeathTimer', GetVIPDeathTimer)
exports('GetVIPMaxWeight', GetVIPMaxWeight)

-- ============================================================================
-- VIP DATA CALLBACK (for NUI)
-- ============================================================================
ESX.RegisterServerCallback('null:vip:getFullData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    local isVip, vipType, timeData = GetVIP(xPlayer.identifier)

    cb({
        isVip = isVip,
        type = vipType,
        time = timeData,
        tiers = {}, -- Config is already available client-side
        advantages = Config.VIP.AdvantagesList,
    })
end)

-- VIP Death Timer callback (used by OnDeath client)
ESX.RegisterServerCallback('null:vip:getDeathTimer', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(10) return end
    local timer = GetVIPDeathTimer(xPlayer.identifier)
    cb(timer)
end)

-- Admin command: add battle pass XP
RegisterCommand('addBPXP', function(source, args)
    if source ~= 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.getGroup() ~= 'fondateur' then return end
    end

    local targetId = tonumber(args[1])
    local amount = tonumber(args[2]) or 100

    if not targetId then
        print('[BattlePass] Usage: addBPXP <id> [amount]')
        return
    end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then print('[BattlePass] Joueur non trouvé') return end

    local leveled = BattlePass.AddXP(target.identifier, amount)
    local data = PlayerBPCache[target.identifier]
    if data then
        TriggerClientEvent('null:battlepass:xpGain', targetId, amount, data.level, data.xp, BattlePass.GetRequiredXP(data.level))
        if leveled then
            TriggerClientEvent('null:battlepass:levelUp', targetId, data.level)
        end
    end
    print(('[BattlePass] +%d XP to %s (Level %d)'):format(amount, target.getName(), data and data.level or 0))
end, false)

-- Admin command: set battle pass level
RegisterCommand('setBPLevel', function(source, args)
    if source ~= 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.getGroup() ~= 'fondateur' then return end
    end

    local targetId = tonumber(args[1])
    local level = tonumber(args[2]) or 1

    if not targetId then
        print('[BattlePass] Usage: setBPLevel <id> <level>')
        return
    end

    local target = ESX.GetPlayerFromId(targetId)
    if not target then print('[BattlePass] Joueur non trouvé') return end

    local data = PlayerBPCache[target.identifier]
    if data then
        data.level = math.min(level, Config.BattlePass.MaxLevel)
        data.xp = 0
        BattlePass.SavePlayerData(target.identifier)
        TriggerClientEvent('null:battlepass:levelUp', targetId, data.level)
        print(('[BattlePass] Set %s to level %d'):format(target.getName(), data.level))
    end
end, false)

null.InitPrint('^2Battle Pass module loaded^7')
