-- ============================================================================
-- ILLEGAL TABLET - Server Side
-- XP/Level system, Missions generation, Data callbacks
-- ============================================================================

-- Flag : true quand les colonnes vgangs (xp/level/missions/...) existent.
-- Évite que le chargement (fetchAll plus bas) tourne avant la migration sur
-- une base de données neuve (colonnes encore absentes → requête en échec).
GangsSchemaReady = false

-- SQL Migration: add xp, level columns to vgangs if they don't exist
Citizen.CreateThread(function()
    Wait(2000)

    local pending = 9
    local function done()
        pending = pending - 1
        if pending <= 0 then
            GangsSchemaReady = true
        end
    end

    local function ensureColumn(columnName, definition)
        MySQL.Async.fetchScalar([[
            SELECT COUNT(*)
            FROM INFORMATION_SCHEMA.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'vgangs'
              AND COLUMN_NAME = @column
        ]], { ['@column'] = columnName }, function(count)
            if tonumber(count) == 0 then
                MySQL.Async.execute(("ALTER TABLE `vgangs` ADD COLUMN `%s` %s"):format(columnName, definition), {}, done)
            else
                done()
            end
        end)
    end

    ensureColumn('xp', 'INT NOT NULL DEFAULT 0')
    ensureColumn('level', 'INT NOT NULL DEFAULT 1')
    ensureColumn('missions', 'LONGTEXT DEFAULT NULL')
    ensureColumn('missions_reset_daily', 'VARCHAR(20) DEFAULT NULL')
    ensureColumn('missions_reset_weekly', 'VARCHAR(20) DEFAULT NULL')
    ensureColumn('total_territories_won', 'INT NOT NULL DEFAULT 0')
    ensureColumn('gangcolor', "VARCHAR(10) DEFAULT '#e74c3c'")
    ensureColumn('tier', 'INT NOT NULL DEFAULT 1')
    ensureColumn('posFabrication', 'LONGTEXT DEFAULT NULL')

    SetTimeout(5000, function()
        GangsSchemaReady = true
    end)

    -- Migrate craft material items
    if Config.IllegalGroups and Config.IllegalGroups.CraftMaterials then
        for _, mat in ipairs(Config.IllegalGroups.CraftMaterials) do
            MySQL.Async.execute("INSERT IGNORE INTO `items` (`name`, `label`, `weight`) VALUES (@name, @label, 0.10)", {
                ['@name'] = mat.name,
                ['@label'] = mat.label,
            })
        end
    end
end)

-- ============================================================================
-- XP / LEVEL HELPERS
-- ============================================================================

local function GetRequiredXP(level)
    if level >= Config.IllegalTablet.XP.MaxLevel then return 0 end
    return math.floor(Config.IllegalTablet.XP.BaseXP * (level ^ Config.IllegalTablet.XP.Exponent))
end

local function GetGangLevel(gangname)
    if SaveData.gangs[gangname] == nil then return 1 end
    return SaveData.gangs[gangname].level or 1
end

local function GetGangXP(gangname)
    if SaveData.gangs[gangname] == nil then return 0 end
    return SaveData.gangs[gangname].xp or 0
end

local function GetUnlocksForLevel(level)
    local unlocks = {}
    for _, unlock in ipairs(Config.IllegalTablet.LevelUnlocks) do
        if unlock.level <= level then
            unlocks[unlock.type] = unlock.value
        end
    end
    return unlocks
end

local function GetMaxMembers(level)
    local max = 10
    for _, unlock in ipairs(Config.IllegalTablet.LevelUnlocks) do
        if unlock.type == "max_members" and unlock.level <= level then
            max = unlock.value
        end
    end
    return max
end

local function GetMaxRanks(level)
    local max = 4
    for _, unlock in ipairs(Config.IllegalTablet.LevelUnlocks) do
        if unlock.type == "max_ranks" and unlock.level <= level then
            max = unlock.value
        end
    end
    return max
end

local function GetBlackmarketDiscount(level)
    local discount = 0
    for _, unlock in ipairs(Config.IllegalTablet.LevelUnlocks) do
        if unlock.type == "blackmarket_discount" and unlock.level <= level then
            discount = unlock.value
        end
    end
    return discount
end

local function HasWeaponSell(level)
    for _, unlock in ipairs(Config.IllegalTablet.LevelUnlocks) do
        if unlock.type == "weapon_sell" and unlock.level <= level then
            return true
        end
    end
    return false
end

local function HasWeaponCraft(level)
    for _, unlock in ipairs(Config.IllegalTablet.LevelUnlocks) do
        if unlock.type == "weapon_craft" and unlock.level <= level then
            return true
        end
    end
    return false
end

function AddGangXP(gangname, amount)
    if SaveData.gangs[gangname] == nil then return end
    if amount <= 0 then return end

    local currentXP = SaveData.gangs[gangname].xp or 0
    local currentLevel = SaveData.gangs[gangname].level or 1

    if currentLevel >= Config.IllegalTablet.XP.MaxLevel then return end

    currentXP = currentXP + amount
    local leveledUp = false

    while currentLevel < Config.IllegalTablet.XP.MaxLevel do
        local required = GetRequiredXP(currentLevel)
        if currentXP >= required then
            currentXP = currentXP - required
            currentLevel = currentLevel + 1
            leveledUp = true
        else
            break
        end
    end

    SaveData.gangs[gangname].xp = currentXP
    SaveData.gangs[gangname].level = currentLevel

    MySQL.Async.execute('UPDATE vgangs SET xp = @xp, level = @level WHERE gangname = @gangname', {
        ['@xp'] = currentXP,
        ['@level'] = currentLevel,
        ['@gangname'] = gangname,
    })

    if leveledUp then
        for _, v in pairs(SaveData.gangs[gangname].StatePly) do
            if v.id then
                TriggerClientEvent('null:tablet:levelUp', v.id, currentLevel)
            end
        end
    end

    TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
end

local function GetGangTier(gangname)
    if SaveData.gangs[gangname] == nil then return 1 end
    return SaveData.gangs[gangname].tier or 1
end

local function SetGangTier(gangname, tier)
    if SaveData.gangs[gangname] == nil then return end
    tier = math.max(1, math.min(4, tonumber(tier) or 1))
    SaveData.gangs[gangname].tier = tier
    MySQL.Async.execute('UPDATE vgangs SET tier = @tier WHERE gangname = @gangname', {
        ['@tier'] = tier,
        ['@gangname'] = gangname,
    })
    TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
end

-- Export for other modules
exports('AddGangXP', AddGangXP)
exports('GetGangLevel', GetGangLevel)
exports('GetGangTier', GetGangTier)
exports('SetGangTier', SetGangTier)
exports('GetMaxMembers', GetMaxMembers)
exports('GetMaxRanks', GetMaxRanks)
exports('GetBlackmarketDiscount', GetBlackmarketDiscount)
exports('HasWeaponSell', HasWeaponSell)
exports('HasWeaponCraft', HasWeaponCraft)

-- ============================================================================
-- MISSIONS SYSTEM
-- ============================================================================

local function GetTodayKey()
    return os.date("%Y-%m-%d")
end

local function GetWeekKey()
    return os.date("%Y-W") .. os.date("%W")
end

local function ShuffleTable(t, seed)
    math.randomseed(seed)
    local n = #t
    for i = n, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

local function GenerateMissionsForGang(gangname)
    local gang = SaveData.gangs[gangname]
    if gang == nil then return end

    local todayKey = GetTodayKey()
    local weekKey = GetWeekKey()
    local missions = gang.missions or {}
    local changed = false

    -- Reset daily missions if needed
    if gang.missions_reset_daily ~= todayKey then
        local dailyPool = {}
        for _, m in ipairs(Config.IllegalTablet.Missions.Daily) do
            dailyPool[#dailyPool + 1] = m
        end
        -- Seed based on gangname + date for consistent per-gang randomness
        local seed = 0
        for i = 1, #gangname do
            seed = seed + string.byte(gangname, i)
        end
        seed = seed * tonumber(os.date("%Y%m%d"))
        ShuffleTable(dailyPool, seed)

        missions.daily = {}
        for i = 1, math.min(Config.IllegalTablet.Missions.DailyCount, #dailyPool) do
            missions.daily[i] = {
                id = dailyPool[i].id,
                progress = 0,
                objective = dailyPool[i].objective,
                completed = false,
                claimed = false,
                acceptedBy = nil,
            }
        end
        gang.missions_reset_daily = todayKey
        changed = true
    end

    -- Reset weekly missions if needed
    if gang.missions_reset_weekly ~= weekKey then
        local weeklyPool = {}
        for _, m in ipairs(Config.IllegalTablet.Missions.Weekly) do
            weeklyPool[#weeklyPool + 1] = m
        end
        local seed = 0
        for i = 1, #gangname do
            seed = seed + string.byte(gangname, i)
        end
        seed = seed * tonumber(os.date("%Y") .. os.date("%W"))
        ShuffleTable(weeklyPool, seed)

        missions.weekly = {}
        for i = 1, math.min(Config.IllegalTablet.Missions.WeeklyCount, #weeklyPool) do
            missions.weekly[i] = {
                id = weeklyPool[i].id,
                progress = 0,
                objective = weeklyPool[i].objective,
                completed = false,
                claimed = false,
                acceptedBy = nil,
            }
        end
        gang.missions_reset_weekly = weekKey
        changed = true
    end

    gang.missions = missions

    if changed then
        SaveGangMissions(gangname)
    end

    return missions
end

function SaveGangMissions(gangname)
    local gang = SaveData.gangs[gangname]
    if gang == nil then return end
    MySQL.Async.execute('UPDATE vgangs SET missions = @missions, missions_reset_daily = @daily, missions_reset_weekly = @weekly WHERE gangname = @gangname', {
        ['@missions'] = json.encode(gang.missions or {}),
        ['@daily'] = gang.missions_reset_daily,
        ['@weekly'] = gang.missions_reset_weekly,
        ['@gangname'] = gangname,
    })
end

-- ============================================================================
-- DIRTY MONEY TRACKING
-- ============================================================================

function TrackDirtyMoney(gangname, amount)
    if gangname == nil or gangname == "unemployed" then return end
    if amount == nil or amount <= 0 then return end

    if SaveData.json["groupes-dirty-money"] == nil then
        SaveData.json["groupes-dirty-money"] = {}
    end
    if SaveData.json["groupes-dirty-money"][gangname] == nil then
        SaveData.json["groupes-dirty-money"][gangname] = {
            total = 0,
            daily = {},
            weekly = {},
            monthly = {},
        }
    end

    local data = SaveData.json["groupes-dirty-money"][gangname]
    local todayKey = os.date("%Y-%m-%d")
    local weekKey = os.date("%Y-W") .. os.date("%W")
    local monthKey = os.date("%Y-%m")

    data.total = (data.total or 0) + amount
    data.daily[todayKey] = (data.daily[todayKey] or 0) + amount
    data.weekly[weekKey] = (data.weekly[weekKey] or 0) + amount
    data.monthly[monthKey] = (data.monthly[monthKey] or 0) + amount

    -- Cleanup old entries (keep last 7 days, 4 weeks, 3 months)
    local keepDays = 7
    local keepWeeks = 4
    local keepMonths = 3
    local now = os.time()

    for k, _ in pairs(data.daily) do
        local y, m, d = k:match("(%d+)-(%d+)-(%d+)")
        if y then
            local t = os.time({year=tonumber(y), month=tonumber(m), day=tonumber(d)})
            if os.difftime(now, t) > keepDays * 86400 then
                data.daily[k] = nil
            end
        end
    end
    for k, _ in pairs(data.weekly) do
        local y, w = k:match("(%d+)-W(%d+)")
        if y and w then
            local currentWeek = tonumber(os.date("%W"))
            local currentYear = tonumber(os.date("%Y"))
            local ky, kw = tonumber(y), tonumber(w)
            if currentYear > ky or (currentYear == ky and currentWeek - kw > keepWeeks) then
                data.weekly[k] = nil
            end
        end
    end
    for k, _ in pairs(data.monthly) do
        local y, m = k:match("(%d+)-(%d+)")
        if y then
            local currentMonth = tonumber(os.date("%m"))
            local currentYear = tonumber(os.date("%Y"))
            local ky, km = tonumber(y), tonumber(m)
            local monthsDiff = (currentYear - ky) * 12 + (currentMonth - km)
            if monthsDiff > keepMonths then
                data.monthly[k] = nil
            end
        end
    end
end

function GetDirtyMoneyStats(gangname)
    if SaveData.json["groupes-dirty-money"] == nil then
        SaveData.json["groupes-dirty-money"] = {}
    end
    if SaveData.json["groupes-dirty-money"][gangname] == nil then
        return { today = 0, week = 0, month = 0, total = 0 }
    end

    local data = SaveData.json["groupes-dirty-money"][gangname]
    local todayKey = os.date("%Y-%m-%d")
    local weekKey = os.date("%Y-W") .. os.date("%W")
    local monthKey = os.date("%Y-%m")

    return {
        today = data.daily[todayKey] or 0,
        week = data.weekly[weekKey] or 0,
        month = data.monthly[monthKey] or 0,
        total = data.total or 0,
    }
end

exports('GetDirtyMoneyStats', GetDirtyMoneyStats)

-- Progress a mission for a gang
function ProgressGangMission(gangname, missionId, amount)
    if SaveData.gangs[gangname] == nil then return end

    -- Auto-track dirty money when relevant missions progress
    if missionId == "daily_dirty_money" then
        TrackDirtyMoney(gangname, amount)
    end

    local missions = SaveData.gangs[gangname].missions
    if missions == nil then return end

    local function progressInList(list)
        if list == nil then return false end
        for _, m in ipairs(list) do
            if m.id == missionId and not m.completed and m.acceptedBy ~= nil then
                m.progress = math.min(m.progress + amount, m.objective)
                if m.progress >= m.objective then
                    m.completed = true
                end
                return true
            end
        end
        return false
    end

    local progressed = progressInList(missions.daily) or progressInList(missions.weekly)
    if progressed then
        SaveGangMissions(gangname)
    end
end

exports('ProgressGangMission', ProgressGangMission)

-- ============================================================================
-- LOAD GANG XP/LEVEL/MISSIONS FROM DB (hook into existing gang load)
-- ============================================================================

Citizen.CreateThread(function()
    -- Wait for gangs to be loaded first
    while not IllegalGroupsLoaded do
        Wait(100)
    end
    -- ET attendre la fin de la migration de schéma (DB neuve) sinon le SELECT
    -- référence des colonnes encore inexistantes.
    local deadline = GetGameTimer() + 15000
    while not GangsSchemaReady and GetGameTimer() < deadline do
        Wait(100)
    end
    Wait(500)

    MySQL.Async.fetchAll('SELECT gangname, xp, level, missions, missions_reset_daily, missions_reset_weekly, total_territories_won, gangcolor, tier FROM vgangs', {}, function(results)
        if not results then return end
        for _, row in ipairs(results) do
            if SaveData.gangs[row.gangname] then
                SaveData.gangs[row.gangname].xp = row.xp or 0
                SaveData.gangs[row.gangname].level = row.level or 1
                SaveData.gangs[row.gangname].total_territories_won = row.total_territories_won or 0
                SaveData.gangs[row.gangname].gangcolor = row.gangcolor or '#e74c3c'
                SaveData.gangs[row.gangname].tier = row.tier or 1
                SaveData.gangs[row.gangname].missions_reset_daily = row.missions_reset_daily
                SaveData.gangs[row.gangname].missions_reset_weekly = row.missions_reset_weekly

                if row.missions and row.missions ~= "" then
                    SaveData.gangs[row.gangname].missions = json.decode(row.missions)
                else
                    SaveData.gangs[row.gangname].missions = {}
                end

                -- Generate/refresh missions
                GenerateMissionsForGang(row.gangname)
            end
        end
        TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
    end)
end)

-- ============================================================================
-- BLACKMARKET DATA BUILDER
-- ============================================================================

function BuildBlackmarketData(gangname, gangLevel)
    local gang = SaveData.gangs[gangname]
    if not gang then return nil end

    -- Check if gang has weapon sell access (KitArme + level unlock)
    local canSell = (gang.KitArme == 1 or gang.KitArme == true) and HasWeaponSell(gangLevel)
    if not canSell then return { unlocked = false } end

    local discount = GetBlackmarketDiscount(gangLevel)

    local weapons = {}
    if Config.IllegalGroups and Config.IllegalGroups.Sell and Config.IllegalGroups.Sell.Weapons then
        for weaponName, data in pairs(Config.IllegalGroups.Sell.Weapons) do
            local basePrice = data.price or 0
            local finalPrice = math.floor(basePrice * (1 - discount / 100))
            weapons[#weapons + 1] = {
                id = weaponName,
                name = data.name or weaponName,
                label = data.label or weaponName,
                basePrice = basePrice,
                price = finalPrice,
            }
        end
    end
    table.sort(weapons, function(a, b) return a.price < b.price end)

    local items = {}
    if Config.IllegalGroups and Config.IllegalGroups.Sell and Config.IllegalGroups.Sell.Items then
        for itemName, data in pairs(Config.IllegalGroups.Sell.Items) do
            local basePrice = data.price or 0
            local finalPrice = math.floor(basePrice * (1 - discount / 100))
            items[#items + 1] = {
                id = itemName,
                name = data.name or itemName,
                label = data.label or itemName,
                basePrice = basePrice,
                price = finalPrice,
            }
        end
    end
    table.sort(items, function(a, b) return a.price < b.price end)

    return {
        unlocked = true,
        discount = discount,
        weapons = weapons,
        items = items,
    }
end

-- ============================================================================
-- TABLET DATA CALLBACK
-- ============================================================================

ESX.RegisterServerCallback('null:tablet:getData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local gangname = xPlayer.getJob2().name

    -- Unemployed2 players get the createGroup mode
    if gangname == "unemployed2" or gangname == "unemployed" then
        if Config.IllegalTablet.GroupCreation and Config.IllegalTablet.GroupCreation.enabled then
            cb({
                mode = "createGroup",
                gangTiers = Config.IllegalTablet.GangTiers,
                groupCreation = Config.IllegalTablet.GroupCreation,
            })
        else
            cb(nil)
        end
        return
    end

    if SaveData.gangs[gangname] == nil then
        cb(nil)
        return
    end

    local gang = SaveData.gangs[gangname]
    GenerateMissionsForGang(gangname)

    -- Build missions data with full info from config
    local missionsData = { daily = {}, weekly = {} }
    local missionConfigMap = {}
    for _, m in ipairs(Config.IllegalTablet.Missions.Daily) do
        missionConfigMap[m.id] = m
    end
    for _, m in ipairs(Config.IllegalTablet.Missions.Weekly) do
        missionConfigMap[m.id] = m
    end

    if gang.missions and gang.missions.daily then
        for _, m in ipairs(gang.missions.daily) do
            local cfg = missionConfigMap[m.id]
            if cfg then
                missionsData.daily[#missionsData.daily + 1] = {
                    id = m.id,
                    label = cfg.label,
                    description = cfg.description,
                    category = cfg.category,
                    xp = cfg.xp,
                    objective = m.objective,
                    progress = m.progress,
                    completed = m.completed,
                    claimed = m.claimed,
                    acceptedBy = m.acceptedBy,
                }
            end
        end
    end
    if gang.missions and gang.missions.weekly then
        for _, m in ipairs(gang.missions.weekly) do
            local cfg = missionConfigMap[m.id]
            if cfg then
                missionsData.weekly[#missionsData.weekly + 1] = {
                    id = m.id,
                    label = cfg.label,
                    description = cfg.description,
                    category = cfg.category,
                    xp = cfg.xp,
                    objective = m.objective,
                    progress = m.progress,
                    completed = m.completed,
                    claimed = m.claimed,
                    acceptedBy = m.acceptedBy,
                }
            end
        end
    end

    -- Build members list
    local members = {}
    local memberCount = 0
    for idunique, ply in pairs(gang.PlyList) do
        local isOnline = false
        for _, sp in pairs(gang.StatePly) do
            if sp.name and ply.idunique == idunique then
                isOnline = true
                break
            end
        end
        local gradeLabel = "Inconnu"
        if gang.GradeList and gang.GradeList[tostring(ply.job2_grade)] then
            gradeLabel = gang.GradeList[tostring(ply.job2_grade)].label
        end
        members[#members + 1] = {
            idunique = ply.idunique,
            firstname = ply.firstname,
            lastname = ply.lastname,
            grade = ply.job2_grade,
            gradeLabel = gradeLabel,
            online = isOnline,
        }
        memberCount = memberCount + 1
    end

    -- Build grades list
    local grades = {}
    for k, v in pairs(gang.GradeList) do
        grades[#grades + 1] = {
            grade = tonumber(k),
            name = v.name,
            label = v.label,
        }
    end
    table.sort(grades, function(a, b) return a.grade > b.grade end)

    -- Build permissions
    local permissions = {
        perms_coffre = gang.perms_coffre or {},
        perms_recruter = gang.perms_recruter or {},
        perms_promouvoir = gang.perms_promouvoir or {},
        perms_gestionmembre = gang.perms_gestionmembre or {},
        perms_vente = gang.perms_vente or {},
        perms_fabrication = gang.perms_fabrication or {},
    }

    -- Level unlocks info
    local currentLevel = gang.level or 1
    local currentXP = gang.xp or 0
    local requiredXP = GetRequiredXP(currentLevel)
    local unlocks = GetUnlocksForLevel(currentLevel)

    -- Next unlocks
    local nextUnlocks = {}
    for _, unlock in ipairs(Config.IllegalTablet.LevelUnlocks) do
        if unlock.level > currentLevel then
            nextUnlocks[#nextUnlocks + 1] = {
                level = unlock.level,
                type = unlock.type,
                value = unlock.value,
                description = unlock.description,
            }
        end
    end

    -- Territories data
    local territoriesData = SaveData.json["territories"] or {}
    local ownedTerritories = 0
    for _, t in pairs(territoriesData) do
        if t.owner == gangname then
            ownedTerritories = ownedTerritories + 1
        end
    end

    -- Ranking data: build leaderboard
    local ranking = {}
    for gname, gdata in pairs(SaveData.gangs) do
        ranking[#ranking + 1] = {
            name = gname,
            label = gdata.label or gname,
            level = gdata.level or 1,
            xp = gdata.xp or 0,
            tier = gdata.tier or 1,
            totalTerritoriesWon = gdata.total_territories_won or 0,
            memberCount = 0,
        }
        for _ in pairs(gdata.PlyList) do
            ranking[#ranking].memberCount = ranking[#ranking].memberCount + 1
        end
    end
    table.sort(ranking, function(a, b)
        if a.level ~= b.level then return a.level > b.level end
        return a.xp > b.xp
    end)

    -- Player info
    local playerGrade = xPlayer.getJob2().grade
    local playerGradeName = xPlayer.getJob2().grade_name
    local isBoss = playerGradeName == "boss"

    cb({
        gangname = gangname,
        ganglabel = gang.label or gangname,
        gangcolor = gang.gangcolor or '#e74c3c',
        tier = gang.tier or 1,
        gangTiers = Config.IllegalTablet.GangTiers,
        level = currentLevel,
        xp = currentXP,
        requiredXP = requiredXP,
        maxLevel = Config.IllegalTablet.XP.MaxLevel,
        memberCount = memberCount,
        maxMembers = GetMaxMembers(currentLevel),
        maxRanks = GetMaxRanks(currentLevel),
        blackmarketDiscount = GetBlackmarketDiscount(currentLevel),
        hasWeaponSell = HasWeaponSell(currentLevel),
        hasWeaponCraft = HasWeaponCraft(currentLevel),
        members = members,
        grades = grades,
        permissions = permissions,
        missions = missionsData,
        ranking = ranking,
        territories = territoriesData,
        ownedTerritories = ownedTerritories,
        totalTerritoriesWon = gang.total_territories_won or 0,
        nextUnlocks = nextUnlocks,
        unlocks = unlocks,
        playerGrade = playerGrade,
        playerGradeName = playerGradeName,
        isBoss = isBoss,
        kitArme = gang.KitArme,
        fabArme = gang.FabArme,
        groupStats = getGroupeStat(gangname),
        dirtyMoney = GetDirtyMoneyStats(gangname),
        blackmarket = BuildBlackmarketData(gangname, currentLevel),
    })
end)

-- ============================================================================
-- TABLET ACTIONS
-- ============================================================================

-- Change gang color
RegisterNetEvent('null:tablet:changeColor')
AddEventHandler('null:tablet:changeColor', function(color)
    local xPlayer = ESX.GetPlayerFromId(source)
    local gangname = xPlayer.getJob2().name
    if xPlayer.getJob2().grade_name ~= "boss" then return end
    if SaveData.gangs[gangname] == nil then return end

    -- Validate hex color format
    if type(color) ~= "string" or not color:match("^#%x%x%x%x%x%x$") then return end

    SaveData.gangs[gangname].gangcolor = color
    MySQL.Async.execute('UPDATE vgangs SET gangcolor = @color WHERE gangname = @gangname', {
        ['@color'] = color,
        ['@gangname'] = gangname,
    })
end)

-- BlackMarket: Buy weapon via tablet
RegisterNetEvent('null:tablet:buyWeapon')
AddEventHandler('null:tablet:buyWeapon', function(weaponId, quantity)
    local xPlayer = ESX.GetPlayerFromId(source)
    local gangname = xPlayer.getJob2().name
    if SaveData.gangs[gangname] == nil then return end
    local gang = SaveData.gangs[gangname]

    -- Permission check: perms_vente
    if not gang.perms_vente or not gang.perms_vente[tostring(xPlayer.getJob2().grade)] then return end

    -- Access check: KitArme + level
    local gangLevel = gang.level or 1
    if not ((gang.KitArme == 1 or gang.KitArme == true) and HasWeaponSell(gangLevel)) then return end

    -- Validate weapon
    if not Config.IllegalGroups or not Config.IllegalGroups.Sell or not Config.IllegalGroups.Sell.Weapons then return end
    local weaponData = Config.IllegalGroups.Sell.Weapons[weaponId]
    if weaponData == nil then return end

    quantity = math.max(1, math.min(10, tonumber(quantity) or 1))
    local discount = GetBlackmarketDiscount(gangLevel)
    local finalPrice = math.floor(weaponData.price * (1 - discount / 100)) * quantity

    if xPlayer.getAccount('dirtycash').money >= finalPrice then
        xPlayer.removeAccountMoney('dirtycash', finalPrice)
        Citizen.CreateThread(function()
            for i = 1, quantity do
                TriggerClientEvent("inventory:sendMessage", xPlayer.source, "~p~[BlackMarket]~s~ (~y~+" .. i .. "~s~) " .. (weaponData.label or weaponId))
                AddWeaponToStorage(gangname, weaponId)
                Wait(2500)
            end
        end)
    else
        xPlayer.showNotification("~r~Vous n'avez pas assez d'argent sale.")
    end
end)

-- BlackMarket: Buy item via tablet
RegisterNetEvent('null:tablet:buyItem')
AddEventHandler('null:tablet:buyItem', function(itemId, quantity)
    local xPlayer = ESX.GetPlayerFromId(source)
    local gangname = xPlayer.getJob2().name
    if SaveData.gangs[gangname] == nil then return end
    local gang = SaveData.gangs[gangname]

    -- Permission check: perms_vente
    if not gang.perms_vente or not gang.perms_vente[tostring(xPlayer.getJob2().grade)] then return end

    -- Access check: KitArme + level
    local gangLevel = gang.level or 1
    if not ((gang.KitArme == 1 or gang.KitArme == true) and HasWeaponSell(gangLevel)) then return end

    -- Validate item
    if not Config.IllegalGroups or not Config.IllegalGroups.Sell or not Config.IllegalGroups.Sell.Items then return end
    local itemData = Config.IllegalGroups.Sell.Items[itemId]
    if itemData == nil then return end

    quantity = math.max(1, math.min(10, tonumber(quantity) or 1))
    local discount = GetBlackmarketDiscount(gangLevel)
    local finalPrice = math.floor(itemData.price * (1 - discount / 100)) * quantity

    if xPlayer.getAccount('dirtycash').money >= finalPrice then
        xPlayer.removeAccountMoney('dirtycash', finalPrice)
        Citizen.CreateThread(function()
            for i = 1, quantity do
                TriggerClientEvent("inventory:sendMessage", xPlayer.source, "~p~[BlackMarket]~s~ " .. (itemData.label or itemId))
                AddItemToStorage(gangname, itemId, 1)
                Wait(4000)
            end
        end)
    else
        xPlayer.showNotification("~r~Vous n'avez pas assez d'argent sale.")
    end
end)

-- ============================================================================
-- GROUP NAME / LABEL VALIDATION HELPERS
-- ============================================================================

local function ContainsForbiddenWord(str, cfg)
    local lower = string.lower(str)
    if cfg.forbiddenWords then
        for _, word in ipairs(cfg.forbiddenWords) do
            if lower:find(string.lower(word), 1, true) then
                return word
            end
        end
    end
    return nil
end

local function IsReservedName(name, cfg)
    local lower = string.lower(name)
    if cfg.reservedNames then
        for _, reserved in ipairs(cfg.reservedNames) do
            if lower == string.lower(reserved) then
                return true
            end
        end
    end
    return false
end

function ValidateGroupName(groupName, cfg, cb)
    if type(groupName) ~= "string" then return cb("Nom invalide") end
    if #groupName < cfg.minNameLength or #groupName > cfg.maxNameLength then
        return cb("Le nom doit contenir entre " .. cfg.minNameLength .. " et " .. cfg.maxNameLength .. " caractères")
    end
    if not groupName:match("^[a-z0-9_]+$") then
        return cb("Le nom ne doit contenir que des lettres minuscules, chiffres et underscores")
    end
    if IsReservedName(groupName, cfg) then
        return cb("Ce nom est réservé et ne peut pas être utilisé")
    end
    local forbidden = ContainsForbiddenWord(groupName, cfg)
    if forbidden then return cb("Le nom contient un mot interdit") end
    if SaveData.gangs[groupName] then return cb("Ce nom de groupe existe déjà") end
    if ESX.Jobs and ESX.Jobs[groupName] then return cb("Ce nom est déservé par un métier existant") end
    MySQL.Async.fetchAll('SELECT 1 FROM jobs WHERE name = @name LIMIT 1', { ['@name'] = groupName }, function(result)
        cb(result and result[1] and "Ce nom est déjà utilisé par un job existant" or nil)
    end)
end

function ValidateGroupLabel(groupLabel, groupName, cfg, cb)
    if type(groupLabel) ~= "string" then return cb("Label invalide") end
    if #groupLabel < cfg.minLabelLength or #groupLabel > cfg.maxLabelLength then
        return cb("Le label doit contenir entre " .. cfg.minLabelLength .. " et " .. cfg.maxLabelLength .. " caractères")
    end
    local forbidden = ContainsForbiddenWord(groupLabel, cfg)
    if forbidden then return cb("Le label contient un mot interdit") end
    for _, gdata in pairs(SaveData.gangs) do
        if gdata.label and string.lower(gdata.label) == string.lower(groupLabel) then
            return cb("Un groupe avec ce nom affiché existe déjà")
        end
    end
    MySQL.Async.fetchAll('SELECT 1 FROM jobs WHERE LOWER(label) = LOWER(@label) LIMIT 1', { ['@label'] = groupLabel }, function(result)
        cb(result and result[1] and "Ce nom affiché est déjà utilisé par un métier existant" or nil)
    end)
end

ESX.RegisterServerCallback('null:tablet:validateGroup', function(source, cb, groupName, groupLabel)
    local cfg = Config.IllegalTablet.GroupCreation
    if not cfg then return cb({ nameError = nil, labelError = nil }) end

    local doNameCheck = groupName and #groupName > 0
    local doLabelCheck = groupLabel and #groupLabel > 0

    local function finish(nameErr, labelErr)
        cb({ nameError = nameErr, labelError = labelErr })
    end

    if doNameCheck then
        ValidateGroupName(groupName, cfg, function(nameErr)
            if doLabelCheck then
                ValidateGroupLabel(groupLabel, groupName, cfg, function(labelErr)
                    finish(nameErr, labelErr)
                end)
            else
                finish(nameErr, nil)
            end
        end)
    elseif doLabelCheck then
        ValidateGroupLabel(groupLabel, groupName or "", cfg, function(labelErr)
            finish(nil, labelErr)
        end)
    else
        finish(nil, nil)
    end
end)

RegisterNetEvent('null:tablet:createGroup')
AddEventHandler('null:tablet:createGroup', function(groupName, groupLabel)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local job2name = xPlayer.getJob2().name
    if job2name ~= "unemployed2" and job2name ~= "unemployed" then
        TriggerClientEvent('esx:showNotification', src, "❌ Vous appartenez déjà à un groupe")
        return
    end

    if not Config.IllegalTablet.GroupCreation or not Config.IllegalTablet.GroupCreation.enabled then
        TriggerClientEvent('esx:showNotification', src, "❌ La création de groupe est désactivée")
        return
    end

    local cfg = Config.IllegalTablet.GroupCreation

    -- Validate name + label using shared helper
    local nameErr = ValidateGroupName(groupName, cfg)
    if nameErr then
        TriggerClientEvent('esx:showNotification', src, "❌ " .. nameErr)
        return
    end

    local labelErr = ValidateGroupLabel(groupLabel, groupName, cfg)
    if labelErr then
        TriggerClientEvent('esx:showNotification', src, "❌ " .. labelErr)
        return
    end

    -- Check dirty money balance
    local price = cfg.price or 0
    if price > 0 then
        local account = xPlayer.getAccount('dirtycash')
        if not account or account.money < price then
            TriggerClientEvent('esx:showNotification', src, "❌ Vous n'avez pas assez d'argent sale ($" .. price .. ")")
            return
        end
        xPlayer.removeAccountMoney('dirtycash', price)
    end

    -- Create the gang (tier 1 = Petite frappe by default)
    CreateStorage(groupName)
    MySQL.Async.execute("INSERT INTO `vgangs` (`gangname`,`ganglabel`, `posCoffre`, `KitArme`, `FabArme`, `zone`, `tier`) VALUES (@gangname,@ganglabel, @posCoffre, @KitArme, @FabArme, @zone, @tier)", {
        ['@gangname'] = groupName,
        ['@ganglabel'] = groupLabel,
        ['@posCoffre'] = '{}',
        ['@KitArme'] = 0,
        ['@FabArme'] = 0,
        ['@zone'] = '[]',
        ['@tier'] = 1,
    })

    -- Create job entry
    MySQL.Async.execute("INSERT INTO `jobs` (`name`, `label`, `whitelisted`, `illegal`) VALUES (@name, @label, @whitelisted, @illegal)", {
        ['@name'] = groupName,
        ['@label'] = groupLabel,
        ['@whitelisted'] = 1,
        ['@illegal'] = 1,
    })

    -- Create default grades: recrue(0), membre(1), gerant(2), boss(3)
    local defaultGrades = {
        { grade = 0, name = "recrue", label = "Recrue" },
        { grade = 1, name = "membre", label = "Membre" },
        { grade = 2, name = "gerant", label = "Gérant" },
        { grade = 3, name = "boss", label = "Boss" },
    }
    for _, g in ipairs(defaultGrades) do
        MySQL.Async.execute("INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES (@job_name, @grade, @name, @label, @salary, @skin_male, @skin_female)", {
            ['@job_name'] = groupName,
            ['@grade'] = g.grade,
            ['@name'] = g.name,
            ['@label'] = g.label,
            ['@salary'] = 0,
            ['@skin_male'] = "{}",
            ['@skin_female'] = "{}",
        })
    end

    -- Create society entries
    MySQL.Async.execute("INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES (@name, @label, @shared)", {
        ['@name'] = 'society_' .. groupName,
        ['@label'] = groupLabel,
        ['@shared'] = 1,
    })
    MySQL.Async.execute("INSERT INTO `addon_inventory` (`name`, `label`, `shared`) VALUES (@name, @label, @shared)", {
        ['@name'] = 'society_' .. groupName,
        ['@label'] = groupLabel,
        ['@shared'] = 1,
    })
    MySQL.Async.execute("INSERT IGNORE INTO `society` (`name`, `label`, `legal`) VALUES (@name, @label, @legal)", {
        ['@name'] = groupName,
        ['@label'] = groupLabel,
        ['@legal'] = 0,
    })

    Wait(500)
    ExecuteCommand("refreshGlobalsInformations")
    Wait(100)

    -- Initialize SaveData
    SaveData.gangs[groupName] = {
        name = groupName,
        label = groupLabel,
        posCoffre = {},
        Point = 0,
        zone = {},
        KitArme = 0,
        FabArme = 0,
        GradeList = {},
        State = false,
        StatePly = {},
        PlyList = {},
        xp = 0,
        level = 1,
        tier = 1,
        total_territories_won = 0,
        gangcolor = '#e74c3c',
        missions = {},
        perms_coffre = { ["0"] = false, ["1"] = false, ["2"] = false, ["3"] = true },
        perms_recruter = { ["0"] = false, ["1"] = false, ["2"] = false, ["3"] = true },
        perms_promouvoir = { ["0"] = false, ["1"] = false, ["2"] = false, ["3"] = true },
        perms_gestionmembre = { ["0"] = false, ["1"] = false, ["2"] = false, ["3"] = true },
        perms_vente = { ["0"] = false, ["1"] = false, ["2"] = false, ["3"] = true },
        perms_fabrication = { ["0"] = false, ["1"] = false, ["2"] = false, ["3"] = true },
    }

    -- Refresh grade list
    if ESX.Jobs[groupName] then
        SaveData.gangs[groupName].GradeList = ESX.Jobs[groupName].grades
    end

    ExecuteCommand("refreshGlobalsInformations")
    Wait(200)

    -- Refresh grade list again after ESX refresh
    if ESX.Jobs[groupName] and ESX.Jobs[groupName].grades then
        SaveData.gangs[groupName].GradeList = ESX.Jobs[groupName].grades
    end

    -- Set the player as boss of the new gang
    xPlayer.setJob2(groupName, 3)

    -- Add player to PlyList
    local idunique = xPlayer.getIdunique()
    SaveData.gangs[groupName].PlyList[idunique] = {
        name = xPlayer.getName(),
        firstname = xPlayer.get("firstName") or "",
        lastname = xPlayer.get("lastName") or "",
        idunique = idunique,
        job2 = groupName,
        job2_grade = 3,
    }

    -- Generate initial missions
    GenerateMissionsForGang(groupName)

    TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
    TriggerClientEvent('esx:showNotification', src, "✅ Groupe '" .. groupLabel .. "' créé avec succès ! Vous êtes le Boss.")

    -- Close and reopen the tablet with the new gang data
    TriggerClientEvent('null:tablet:groupCreated', src)
end)

-- Accept a mission
RegisterNetEvent('null:tablet:acceptMission')
AddEventHandler('null:tablet:acceptMission', function(missionId, missionType)
    local xPlayer = ESX.GetPlayerFromId(source)
    local gangname = xPlayer.getJob2().name
    if SaveData.gangs[gangname] == nil then return end

    local missions = SaveData.gangs[gangname].missions
    if missions == nil then return end

    local list = missions[missionType]
    if list == nil then return end

    for _, m in ipairs(list) do
        if m.id == missionId then
            if m.acceptedBy ~= nil then
                xPlayer.showNotification("❌ Cette mission a déjà été acceptée")
                return
            end
            m.acceptedBy = xPlayer.getIdunique()
            SaveGangMissions(gangname)
            return
        end
    end
end)

-- Claim mission reward (XP)
RegisterNetEvent('null:tablet:claimMission')
AddEventHandler('null:tablet:claimMission', function(missionId, missionType)
    local xPlayer = ESX.GetPlayerFromId(source)
    local gangname = xPlayer.getJob2().name
    if SaveData.gangs[gangname] == nil then return end

    local missions = SaveData.gangs[gangname].missions
    if missions == nil then return end

    local list = missions[missionType]
    if list == nil then return end

    local missionConfigMap = {}
    for _, m in ipairs(Config.IllegalTablet.Missions.Daily) do
        missionConfigMap[m.id] = m
    end
    for _, m in ipairs(Config.IllegalTablet.Missions.Weekly) do
        missionConfigMap[m.id] = m
    end

    for _, m in ipairs(list) do
        if m.id == missionId and m.completed and not m.claimed then
            m.claimed = true
            local cfg = missionConfigMap[m.id]
            if cfg then
                AddGangXP(gangname, cfg.xp)
            end
            SaveGangMissions(gangname)
            return
        end
    end
end)

-- Add grade (from tablet)
RegisterNetEvent('null:tablet:addGrade')
AddEventHandler('null:tablet:addGrade', function(label)
    local xPlayer = ESX.GetPlayerFromId(source)
    local gangname = xPlayer.getJob2().name
    if xPlayer.getJob2().grade_name ~= "boss" then return end
    if SaveData.gangs[gangname] == nil then return end

    local currentLevel = SaveData.gangs[gangname].level or 1
    local maxRanks = GetMaxRanks(currentLevel)

    local gradeCount = 0
    for _ in pairs(SaveData.gangs[gangname].GradeList) do
        gradeCount = gradeCount + 1
    end

    if gradeCount >= maxRanks then
        xPlayer.showNotification("❌ Nombre maximum de rangs atteint (Niveau "..currentLevel..")")
        return
    end

    local pos = math.random(111,999)
    local name = "playergrade_"..tostring(pos)

    MySQL.Async.execute("INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`) VALUES (@job_name, @grade, @name, @label) ", {
        ['@job_name'] = gangname,
        ['@grade'] = pos,
        ['@name'] = name,
        ['@label'] = label
    })
    Wait(500)
    ExecuteCommand("refreshGlobalsInformations")
    Wait(500)
    SaveData.gangs[gangname].GradeList[tostring(pos)] = {name=name,label=label}
    OthersLogsDetails("Logs Groupe Illégal","Le joueur "..xPlayer.getName().." ("..xPlayer.getIdunique()..") a ajouter un grade : "..label.." ("..name..") ("..gangname..")","gestion-illegal-group", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})
    TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
end)

-- Remove grade (from tablet)
RegisterNetEvent('null:tablet:removeGrade')
AddEventHandler('null:tablet:removeGrade', function(gradeName, gradePos)
    local xPlayer = ESX.GetPlayerFromId(source)
    local gangname = xPlayer.getJob2().name
    if xPlayer.getJob2().grade_name ~= "boss" then return end

    if gradeName == "boss" then
        xPlayer.showNotification("❌ Impossible de supprimer le grade Boss")
        return
    end

    MySQL.update('DELETE FROM job_grades WHERE name = @name AND job_name = @job_name', {
        ['@name'] = gradeName,
        ['@job_name'] = gangname
    }, function()
        Wait(500)
        ExecuteCommand("refreshGlobalsInformations")
        Wait(500)
        SaveData.gangs[gangname].GradeList[tostring(gradePos)] = nil
        TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
    end)
end)

-- Change permissions (from tablet)
RegisterNetEvent('null:tablet:changePerms')
AddEventHandler('null:tablet:changePerms', function(permType, gradeKey, value)
    local xPlayer = ESX.GetPlayerFromId(source)
    local gangname = xPlayer.getJob2().name
    if xPlayer.getJob2().grade_name ~= "boss" then return end
    if SaveData.gangs[gangname] == nil then return end

    local validPerms = {
        "perms_coffre", "perms_recruter", "perms_promouvoir",
        "perms_gestionmembre", "perms_vente", "perms_fabrication"
    }
    local isValid = false
    for _, p in ipairs(validPerms) do
        if p == permType then isValid = true break end
    end
    if not isValid then return end

    if SaveData.gangs[gangname][permType] == nil then
        SaveData.gangs[gangname][permType] = {}
    end
    SaveData.gangs[gangname][permType][gradeKey] = value

    MySQL.Async.execute("UPDATE `vgangs` SET `"..permType.."` = '"..json.encode(SaveData.gangs[gangname][permType]).."' WHERE `gangname` = '"..gangname.."'", {})
end)

-- Change member grade (from tablet)
RegisterNetEvent('null:tablet:changeMemberGrade')
AddEventHandler('null:tablet:changeMemberGrade', function(targetIdunique, newGrade)
    local xPlayer = ESX.GetPlayerFromId(source)
    local gangname = xPlayer.getJob2().name
    if SaveData.gangs[gangname] == nil then return end

    -- Check permission
    local playerGrade = tostring(xPlayer.getJob2().grade)
    if not (xPlayer.getJob2().grade_name == "boss" or (SaveData.gangs[gangname].perms_gestionmembre and SaveData.gangs[gangname].perms_gestionmembre[playerGrade])) then
        return
    end

    local gradeInfo = SaveData.gangs[gangname].GradeList[tostring(newGrade)]
    if gradeInfo == nil then return end
    if gradeInfo.name == "boss" then return end

    local player = exports["null-core"]:getPlayerWithUniqueID(targetIdunique) or {id = 0}
    local xTarget = ESX.GetPlayerFromId(player.id)

    if xTarget ~= nil then
        xTarget.setJob2(gangname, newGrade)
    else
        MySQL.Async.execute("UPDATE `users` SET `job2_grade` = '"..newGrade.."' WHERE `idunique` = '"..targetIdunique.."'", {})
    end

    if SaveData.gangs[gangname].PlyList[targetIdunique] then
        SaveData.gangs[gangname].PlyList[targetIdunique].job2_grade = newGrade
    end

    OthersLogsDetails("Logs Groupe Illégal","Le joueur "..xPlayer.getName().." ("..xPlayer.getIdunique()..") a modifier le grade de "..targetIdunique.." en "..newGrade.." ("..gangname..")","gestion-illegal-group", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = targetIdunique})
    TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
end)

-- Kick member (from tablet)
RegisterNetEvent('null:tablet:kickMember')
AddEventHandler('null:tablet:kickMember', function(targetIdunique)
    local xPlayer = ESX.GetPlayerFromId(source)
    local gangname = xPlayer.getJob2().name
    if SaveData.gangs[gangname] == nil then return end

    local playerGrade = tostring(xPlayer.getJob2().grade)
    if not (xPlayer.getJob2().grade_name == "boss" or (SaveData.gangs[gangname].perms_gestionmembre and SaveData.gangs[gangname].perms_gestionmembre[playerGrade])) then
        return
    end

    -- Can't kick boss
    local targetPly = SaveData.gangs[gangname].PlyList[targetIdunique]
    if targetPly == nil then return end
    local targetGradeInfo = SaveData.gangs[gangname].GradeList[tostring(targetPly.job2_grade)]
    if targetGradeInfo and targetGradeInfo.name == "boss" then return end

    local player = exports["null-core"]:getPlayerWithUniqueID(targetIdunique) or {id = 0}
    local xTarget = ESX.GetPlayerFromId(player.id)

    if xTarget ~= nil then
        xTarget.setJob2("unemployed", 0)
    else
        MySQL.Async.execute("UPDATE `users` SET `job2` = 'unemployed' WHERE `idunique` = '"..targetIdunique.."'", {})
        MySQL.Async.execute("UPDATE `users` SET `job2_grade` = '0' WHERE `idunique` = '"..targetIdunique.."'", {})
    end

    SaveData.gangs[gangname].PlyList[targetIdunique] = nil
    TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)

    OthersLogsDetails("Logs Groupe Illégal","Le joueur "..xPlayer.getName().." ("..xPlayer.getIdunique()..") a exclu "..targetIdunique.." de son groupe illégal ("..gangname..")","gestion-illegal-group", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = targetIdunique})
end)

-- Increment total_territories_won (called from territories module)
function IncrementGangTerritoriesWon(gangname)
    if SaveData.gangs[gangname] == nil then return end
    SaveData.gangs[gangname].total_territories_won = (SaveData.gangs[gangname].total_territories_won or 0) + 1
    MySQL.Async.execute('UPDATE vgangs SET total_territories_won = @total WHERE gangname = @gangname', {
        ['@total'] = SaveData.gangs[gangname].total_territories_won,
        ['@gangname'] = gangname,
    })
end

exports('IncrementGangTerritoriesWon', IncrementGangTerritoriesWon)

-- ============================================================================
-- PERIODIC MISSION CHECKS (state-based missions)
-- ============================================================================

Citizen.CreateThread(function()
    while not IllegalGroupsLoaded do Wait(100) end
    Wait(30000)
    while true do
        for gangname, gang in pairs(SaveData.gangs) do
            -- weekly_territory_hold: count territories owned simultaneously
            local ownedTerritories = 0
            if SaveData.json["territories"] then
                for _, t in pairs(SaveData.json["territories"]) do
                    if t.owner == gangname then
                        ownedTerritories = ownedTerritories + 1
                    end
                end
            end
            if ownedTerritories > 0 then
                ProgressGangMission(gangname, "weekly_territory_hold", ownedTerritories)
            end

            -- weekly_members_online: count members online simultaneously
            local onlineCount = 0
            if gang.StatePly then
                for _, sp in pairs(gang.StatePly) do
                    if sp.id then
                        onlineCount = onlineCount + 1
                    end
                end
            end
            if onlineCount > 0 then
                ProgressGangMission(gangname, "weekly_members_online", onlineCount)
            end
        end
        Wait(5 * 60 * 1000)
    end
end)

-- ============================================================================
-- STAFF MANAGEMENT CALLBACKS
-- ============================================================================

ESX.RegisterServerCallback('null:staff:getGangTabletData', function(source, cb, gangname)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer.getPermission("GESTION_BUILDER") then cb(nil) return end
    if SaveData.gangs[gangname] == nil then cb(nil) return end

    local gang = SaveData.gangs[gangname]
    local stats = getGroupeStat(gangname)

    cb({
        gangname = gangname,
        label = gang.label or gangname,
        level = gang.level or 1,
        xp = gang.xp or 0,
        requiredXP = GetRequiredXP(gang.level or 1),
        maxLevel = Config.IllegalTablet.XP.MaxLevel,
        totalTerritoriesWon = gang.total_territories_won or 0,
        gangcolor = gang.gangcolor or '#e74c3c',
        groupStats = stats,
        missions = gang.missions or {},
    })
end)

RegisterServerEvent('null:staff:setGangLevel')
AddEventHandler('null:staff:setGangLevel', function(gangname, newLevel)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer.getPermission("GESTION_BUILDER") then return end
    if SaveData.gangs[gangname] == nil then return end

    newLevel = math.max(1, math.min(newLevel, Config.IllegalTablet.XP.MaxLevel))
    SaveData.gangs[gangname].level = newLevel
    SaveData.gangs[gangname].xp = 0

    MySQL.Async.execute('UPDATE vgangs SET xp = 0, level = @level WHERE gangname = @gangname', {
        ['@level'] = newLevel,
        ['@gangname'] = gangname,
    })

    TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
    ESX.ShowNotification(source, "Niveau du groupe "..gangname.." défini à "..newLevel)
end)

RegisterServerEvent('null:staff:addGangXP')
AddEventHandler('null:staff:addGangXP', function(gangname, amount)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer.getPermission("GESTION_BUILDER") then return end
    if SaveData.gangs[gangname] == nil then return end

    amount = tonumber(amount) or 0
    if amount <= 0 then return end

    AddGangXP(gangname, amount)
    ESX.ShowNotification(source, "+"..amount.." XP ajouté au groupe "..gangname)
end)

RegisterServerEvent('null:staff:resetGangMissions')
AddEventHandler('null:staff:resetGangMissions', function(gangname)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer.getPermission("GESTION_BUILDER") then return end
    if SaveData.gangs[gangname] == nil then return end

    SaveData.gangs[gangname].missions = {}
    SaveData.gangs[gangname].missions_reset_daily = nil
    SaveData.gangs[gangname].missions_reset_weekly = nil

    GenerateMissionsForGang(gangname)
    SaveGangMissions(gangname)

    ESX.ShowNotification(source, "Missions du groupe "..gangname.." réinitialisées")
end)

RegisterServerEvent('null:staff:setGangStat')
AddEventHandler('null:staff:setGangStat', function(gangname, statKey, value)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer.getPermission("GESTION_BUILDER") then return end

    local validStats = { ["criminalité"] = true, ["confiance"] = true, ["honneur"] = true, ["morale"] = true }
    if not validStats[statKey] then return end

    value = math.max(0, math.min(100, tonumber(value) or 0))

    local stats = getGroupeStat(gangname)
    stats[statKey] = value

    ESX.ShowNotification(source, "Stat '"..statKey.."' du groupe "..gangname.." définie à "..value)
end)

RegisterServerEvent('null:staff:resetGangXP')
AddEventHandler('null:staff:resetGangXP', function(gangname)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer.getPermission("GESTION_BUILDER") then return end
    if SaveData.gangs[gangname] == nil then return end

    SaveData.gangs[gangname].level = 1
    SaveData.gangs[gangname].xp = 0

    MySQL.Async.execute('UPDATE vgangs SET xp = 0, level = 1 WHERE gangname = @gangname', {
        ['@gangname'] = gangname,
    })

    TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
    ESX.ShowNotification(source, "XP et niveau du groupe "..gangname.." réinitialisés")
end)
