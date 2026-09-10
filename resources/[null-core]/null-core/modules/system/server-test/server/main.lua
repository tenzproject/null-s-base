--[[
    Server Load Testing Module v3 - Simulation Réaliste
    
    Simule le coût RÉEL d'un joueur sur le serveur:
    - Objets joueurs en mémoire Lua (même structure que CreatePlayer)
    - Cache inventaire (InventoryCache pattern)
    - Cache jobs (ESX.Cache.Jobs pattern)
    - Charge staff/admin (getLightAllPlayers, refreshOnePlayer, getPlayerInventory)
    - Requêtes MySQL périodiques (save 5min, position sync 1min)
    - json.encode/decode (le vrai bottleneck CPU)
    - ServerCallbacks simulés
    - Threads par joueur (position, activité, inventaire)
    
    Estimation coût réel par joueur:
    ~20 requêtes MySQL/min, ~50 json.encode/decode/min, ~2KB RAM objet joueur,
    + overhead staff: getLightAllPlayers O(n) * nb_staff
    
    Commandes RCON:
    servertest [joueurs]       - Démarrer (max 500)
    servertest_stop            - Arrêter + rapport
    servertest_status          - Stats en cours
    
    SÉCURITÉ: Tables MySQL isolées (server_test_*), aucune donnée réelle touchée.
    Requiert: devmode = true
--]]

-- ============================================================================
-- CONFIG
-- ============================================================================

local ServerTest = {
    active = false,
    config = {
        -- Estimation requêtes MySQL par joueur par minute
        queriesPerPlayerPerMinute = 20,
        -- Pondération des types de requêtes
        queryWeights = {
            select_user = 30,
            select_storage = 20,
            select_clothes = 10,
            update_user = 25,
            update_storage = 15,
        },
        -- Intervalle monitoring (ms)
        monitorInterval = 5000,
        -- Ratio staff: 1 staff pour N joueurs (minimum 7 staff)
        staffRatio = 10,
        staffMinimum = 7,
        staffMaximum = 20,
        -- % de joueurs avec un coffre ouvert en simultané
        openStoragePercent = 30,
        -- Nombre d'items moyen par inventaire joueur
        avgItemsPerPlayer = 15,
        -- Nombre d'armes moyen par joueur
        avgWeaponsPerPlayer = 3,
        -- Intervalle de save DB simulé (ms) - réel = 5min
        dbSaveInterval = 300000,
        -- Intervalle position sync simulé (ms) - réel = 60s
        positionSyncInterval = 60000,
        -- Intervalle admin refresh simulé par staff (ms)
        adminRefreshInterval = 2000,
        -- Intervalle activité joueur (inventaire, argent, etc.) (ms)
        playerActivityInterval = 3000,
        -- Tables de test
        tables = {
            users = "server_test_users",
            storage = "server_test_storage",
            clothes = "server_test_clothes",
        },
    },
    stats = {
        startTime = 0,
        ramBeforeMB = 0,
        ramCurrentMB = 0,
        ramPeakMB = 0,
        queriesTotal = 0,
        queriesFailed = 0,
        avgQueryTime = 0,
        jsonEncodes = 0,
        jsonDecodes = 0,
        adminRefreshes = 0,
        inventoryOps = 0,
        simulatedPlayers = 0,
        simulatedStaff = 0,
    },
    threads = {},
    queryTimes = {},
    -- Données simulées en mémoire
    fakePlayers = {},           -- Objets joueurs (même footprint que ESX.Players)
    fakePlayersByIdUnique = {}, -- Index O(1) comme ESX.PlayersByIdUnique
    fakePlayersByIdentifier = {}, -- Index O(1) comme ESX.PlayersByIdentifier
    fakeJobCache = {},          -- Cache jobs comme ESX.Cache.Jobs
    fakeInventoryCache = {},    -- Cache coffres comme InventoryCache
    fakeStaffList = {},         -- Liste staff
    testData = { users = {}, storage = {} },
}

-- ============================================================================
-- UTILS
-- ============================================================================

local function GetMemoryUsage()
    return collectgarbage("count") / 1024
end

local function GenerateIdentifier()
    local hex = "0123456789abcdef"
    local id = "license:"
    for i = 1, 40 do
        local idx = math.random(1, 16)
        id = id .. hex:sub(idx, idx)
    end
    return id
end

local function GenerateSteamId()
    return "steam:" .. string.format("%015x", math.random(1, 0x7FFFFFFF))
end

local JOBS = {"unemployed", "police", "ambulance", "mechanic", "realestateagent", "burgershot", "cardealer", "taxi", "farmer"}
local JOBS2 = {"unemployed2", "bloods", "crips", "vagos", "ballas", "lostmc"}
local ITEM_NAMES = {"water", "bread", "bandage", "phone", "lockpick", "weed_pooch", "cocaine_bag", "burger", "medkit", "armor", "radio", "binoculars", "fishing_rod", "bait", "rope", "duct_tape", "drill", "gold_bar", "diamond", "watch"}
local WEAPON_NAMES = {"WEAPON_PISTOL", "WEAPON_SMG", "WEAPON_CARBINERIFLE", "WEAPON_PUMPSHOTGUN", "WEAPON_MICROSMG", "WEAPON_KNIFE", "WEAPON_BAT", "WEAPON_STUNGUN"}
local PERMISSION_GROUPS = {"user", "user", "user", "user", "user", "user", "user", "user", "helper", "mod", "supermod", "admin", "superadmin", "fondateur"}
local ACCOUNT_NAMES = {"cash", "bank", "dirtycash"}

-- ============================================================================
-- FAKE PLAYER OBJECT CREATION (même footprint que CreatePlayer)
-- ============================================================================

local function GenerateInventory(count)
    local inv = {}
    local usedItems = {}
    for i = 1, count do
        local name
        repeat
            name = ITEM_NAMES[math.random(1, #ITEM_NAMES)]
        until not usedItems[name]
        usedItems[name] = true
        inv[i] = {
            name = name,
            count = math.random(1, 50),
            label = "Item " .. name,
            weight = math.random(1, 10) * 0.25,
            canRemove = true,
            metadata = { quality = math.random(50, 100), source = "test" },
            unique = false,
            extra = nil,
        }
    end
    return inv
end

local function GenerateLoadout(count)
    local loadout = {}
    local usedWeapons = {}
    for i = 1, math.min(count, #WEAPON_NAMES) do
        local name
        repeat
            name = WEAPON_NAMES[math.random(1, #WEAPON_NAMES)]
        until not usedWeapons[name]
        usedWeapons[name] = true
        loadout[i] = {
            name = name,
            label = "Weapon " .. name,
            ammo = math.random(0, 250),
            metadata = {},
            permanent = false,
            serialnumber = "SN" .. math.random(100000, 999999),
            durability = math.random(50, 100),
            components = {},
        }
    end
    return loadout
end

local function GenerateAccounts()
    return {
        { name = "cash", money = math.random(0, 50000) },
        { name = "bank", money = math.random(1000, 500000) },
        { name = "dirtycash", money = math.random(0, 100000) },
    }
end

local function GenerateClothesEquiped()
    return {
        torso_1 = math.random(0, 300), torso_2 = math.random(0, 10),
        legs_1 = math.random(0, 100), legs_2 = math.random(0, 10),
        shoes_1 = math.random(0, 80), shoes_2 = math.random(0, 10),
        tshirt_1 = math.random(0, 150), tshirt_2 = math.random(0, 10),
        bags_1 = 0, bags_2 = 0,
        arms = math.random(0, 200), arms_2 = math.random(0, 10),
        helmet_1 = -1, helmet_2 = 0,
        glasses_1 = -1, glasses_2 = 0,
        mask_1 = 0, mask_2 = 0,
    }
end

local function CreateFakePlayer(fakeSource, index)
    local self = {}
    local identifier = GenerateIdentifier()
    local idunique = 900000 + index

    -- Mêmes champs que CreatePlayer dans player.lua
    self.source = fakeSource
    self.identifier = identifier
    self.idunique = idunique
    self.discord = "discord:" .. math.random(100000000, 999999999)
    self.fivem = "fivem:" .. math.random(100000, 999999)
    self.name = "TestPlayer_" .. index
    self.firstname = "Prénom" .. math.random(1, 500)
    self.lastname = "Nom" .. math.random(1, 500)
    self.dateofbirth = string.format("%02d/%02d/%04d", math.random(1, 28), math.random(1, 12), math.random(1980, 2005))
    self.sex = math.random(0, 1)
    self.permission_group = PERMISSION_GROUPS[math.random(1, #PERMISSION_GROUPS)]
    self.permission_level = self.permission_group == "user" and 0 or math.random(1, 10)
    self.accounts = GenerateAccounts()
    
    local jobName = JOBS[math.random(1, #JOBS)]
    self.job = {
        id = math.random(1, 50),
        name = jobName,
        label = "Job " .. jobName,
        grade = math.random(0, 5),
        grade_name = "grade_" .. math.random(0, 5),
        grade_label = "Grade " .. math.random(0, 5),
        grade_salary = math.random(100, 5000),
        skin_male = {},
        skin_female = {},
    }
    
    local job2Name = JOBS2[math.random(1, #JOBS2)]
    self.job2 = {
        id = math.random(51, 100),
        name = job2Name,
        label = "Job2 " .. job2Name,
        grade = math.random(0, 3),
        grade_name = "grade2_" .. math.random(0, 3),
        grade_label = "Grade2 " .. math.random(0, 3),
        grade_salary = 0,
        skin_male = {},
        skin_female = {},
    }
    
    self.inventory = GenerateInventory(ServerTest.config.avgItemsPerPlayer)
    self.loadout = GenerateLoadout(ServerTest.config.avgWeaponsPerPlayer)
    self.clothes_equiped = GenerateClothesEquiped()
    self.lastPosition = { x = math.random(-2000, 2000) + 0.0, y = math.random(-2000, 2000) + 0.0, z = math.random(0, 500) + 0.0 }
    self.maxWeight = 120
    self.ata = 0
    self.playtime = math.random(0, 1000000)
    self.afk_time = 0
    self.afk_point = 0.0
    self.streamer = false
    self.smells = { weed = math.random(0, 100), alcohol = math.random(0, 50) }
    self.inJail = false
    self.staffmode = self.permission_group ~= "user"
    self.gamertag = false
    self.vip = nil
    self.instance = 0
    self.freeze = false
    self.enter = true
    self.positionSaveReady = true
    self.suit = nil
    self.coords = { x = self.lastPosition.x, y = self.lastPosition.y, z = self.lastPosition.z, heading = math.random(0, 359) + 0.0 }

    -- Dirty flags + JSON cache (même pattern que player.lua optimisé)
    local _dirty = { accounts = true, inventory = true, loadout = true, clothes = true, smells = true, position = true }
    local _jsonCache = {}

    local function markDirty(field)
        _dirty[field] = true
    end

    -- Cache O(1) comptes (même pattern que player.lua)
    local accountsCache = {}
    for i, acc in ipairs(self.accounts) do
        accountsCache[acc.name] = acc
    end
    self.cash = accountsCache["cash"].money
    self.bank = accountsCache["bank"].money
    self.black = accountsCache["dirtycash"].money

    -- Closures (même overhead mémoire que le vrai CreatePlayer)
    self.triggerEvent = function() end
    self.chatMessage = function() end
    self.kick = function() end
    self.set = function(key, value) self[key] = value end
    self.get = function(key) return self[key] end
    self.isStreamer = function() return self.streamer end
    self.getIdentifier = function() return self.identifier end
    self.getIdunique = function() return self.idunique end
    self.getName = function() return self.name end
    self.getGroup = function() return self.permission_group end
    self.getLevel = function() return self.permission_level end
    self.getPlayTime = function() return self.playtime end
    self.getJob = function() return self.job end
    self.getJob2 = function() return self.job2 end
    self.getCoords = function() return self.coords end
    self.getLastPosition = function() return self.lastPosition end
    self.setLastPosition = function(c) self.lastPosition = c; markDirty('position') end
    self.getClothes = function() return self.clothes_equiped end
    self.getSmells = function() return self.smells end
    self.getAfk = function() return { afk_time = self.afk_time, afk_point = self.afk_point } end
    self.getAccount = function(name) return accountsCache[name] end
    self.getMoney = function() return accountsCache["cash"] end
    self.getAccounts = function(minimal)
        if minimal then
            local m = {}
            for i = 1, #self.accounts do
                m[i] = { name = self.accounts[i].name, money = self.accounts[i].money }
            end
            return m
        end
        return self.accounts
    end
    self.getInventory = function(minimal)
        if minimal then
            local m = {}
            for i = 1, #self.inventory do
                m[i] = { name = self.inventory[i].name, count = self.inventory[i].count, metadata = self.inventory[i].metadata, unique = self.inventory[i].unique }
            end
            return m
        end
        return self.inventory
    end
    self.getLoadout = function() return self.loadout end
    self.setPlayTime = function(v) self.playtime = v end
    self.updateCoords = function(c) self.coords = c end
    self.getSuit = function() return self.suit end
    self.getJail = function() return self.inJail end
    self.setAfk = function() end
    self.setName = function(n) self.name = n end
    self.setGroup = function() end
    self.setLevel = function() end
    self.setAccountMoney = function(name, money) 
        if accountsCache[name] then accountsCache[name].money = money end
        markDirty('accounts')
    end
    self.addAccountMoney = function(name, money)
        if accountsCache[name] then accountsCache[name].money = accountsCache[name].money + money end
        markDirty('accounts')
    end
    self.removeAccountMoney = function(name, money)
        if accountsCache[name] then accountsCache[name].money = math.max(0, accountsCache[name].money - money) end
        markDirty('accounts')
    end
    self.syncInventory = function() markDirty('inventory') end
    self.setMaxWeight = function(w) self.maxWeight = w end
    self.showNotification = function() end
    self.markDirty = markDirty

    -- getJsonCache: ne ré-encode que si dirty (même logique que player.lua)
    self.getJsonCache = function(field)
        if _dirty[field] then
            if field == 'accounts' then
                _jsonCache.accounts = json.encode(self.getAccounts(true))
            elseif field == 'inventory' then
                _jsonCache.inventory = json.encode(self.getInventory(true))
            elseif field == 'loadout' then
                local loadout = self.getLoadout()
                local minimalLoadout = {}
                for k, v in ipairs(loadout) do
                    minimalLoadout[k] = {
                        name = v.name,
                        ammo = v.ammo,
                        components = v.components,
                        serialnumber = v.serialnumber,
                        permanent = v.permanent,
                        durability = v.durability,
                        metadata = v.metadata,
                    }
                end
                _jsonCache.loadout = json.encode(minimalLoadout)
            elseif field == 'clothes' then
                _jsonCache.clothes = json.encode(self.clothes_equiped)
            elseif field == 'smells' then
                _jsonCache.smells = json.encode(self.smells)
            elseif field == 'position' then
                _jsonCache.position = json.encode(self.lastPosition)
            end
            _dirty[field] = false
            ServerTest.stats.jsonEncodes = ServerTest.stats.jsonEncodes + 1
            return _jsonCache[field]
        end
        -- Cache hit: pas de ré-encodage
        ServerTest.stats.cacheHits = (ServerTest.stats.cacheHits or 0) + 1
        return _jsonCache[field]
    end

    return self, identifier, idunique
end

-- ============================================================================
-- STAFF / ADMIN SIMULATION (le plus coûteux sur un serveur peuplé)
-- ============================================================================

local heavyFields = { inventory = true, loadout = true, clothes_equiped = true }

local function getLightPlayerData(xPlayerData)
    if xPlayerData == nil then return nil end
    local light = {}
    for k, v in pairs(xPlayerData) do
        if type(v) ~= "function" and not heavyFields[k] then
            light[k] = v
        end
    end
    return light
end

local function getLightAllPlayers(playersByIdUnique)
    local result = {}
    for idunique, data in pairs(playersByIdUnique) do
        result[idunique] = getLightPlayerData(data)
    end
    return result
end

-- ============================================================================
-- INVENTORY CACHE SIMULATION
-- ============================================================================

local function CreateFakeInventoryCache(storageName, playerSource)
    local data = {
        cash = math.random(0, 10000),
        dirtycash = math.random(0, 50000),
        items = GenerateInventory(math.random(5, 20)),
        loadout = GenerateLoadout(math.random(0, 3)),
        clothes = {},
    }
    
    -- Calcul poids (même logique que InventoryCache.CalculateWeight)
    local weight = 0
    for _, item in pairs(data.items) do
        weight = weight + ((item.weight or 1) * (item.count or 1))
    end
    
    return {
        data = data,
        weight = weight,
        maxWeight = 1000,
        openedBy = { [playerSource] = true },
        lastAccess = os.time(),
        dirty = false,
        dbId = math.random(1, 99999),
    }
end

-- ============================================================================
-- MYSQL TEST TABLES (isolées)
-- ============================================================================

local function SetupTestTables(callback)
    local t = ServerTest.config.tables
    
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `]] .. t.users .. [[` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(255) NOT NULL,
            `name` VARCHAR(50) DEFAULT NULL,
            `firstname` VARCHAR(50) DEFAULT NULL,
            `lastname` VARCHAR(50) DEFAULT NULL,
            `position` LONGTEXT DEFAULT NULL,
            `skin` LONGTEXT DEFAULT NULL,
            `accounts` LONGTEXT DEFAULT NULL,
            `inventory` LONGTEXT DEFAULT NULL,
            `loadout` LONGTEXT DEFAULT NULL,
            `clothes` LONGTEXT DEFAULT NULL,
            `job` VARCHAR(50) DEFAULT 'unemployed',
            `job_grade` INT DEFAULT 0,
            `job2` VARCHAR(50) DEFAULT 'unemployed2',
            `job2_grade` INT DEFAULT 0,
            `status` LONGTEXT DEFAULT NULL,
            `playtime` INT DEFAULT 0,
            `metadata` MEDIUMTEXT DEFAULT NULL,
            `smells` LONGTEXT DEFAULT NULL,
            `permission_group` VARCHAR(50) DEFAULT 'user',
            `permission_level` INT DEFAULT 0,
            INDEX `idx_identifier` (`identifier`),
            INDEX `idx_job` (`job`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function()
        MySQL.Async.execute([[
            CREATE TABLE IF NOT EXISTS `]] .. t.storage .. [[` (
                `id` INT AUTO_INCREMENT PRIMARY KEY,
                `name` VARCHAR(100) NOT NULL,
                `coffre` LONGTEXT DEFAULT NULL,
                UNIQUE KEY `name` (`name`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]], {}, function()
            MySQL.Async.execute([[
                CREATE TABLE IF NOT EXISTS `]] .. t.clothes .. [[` (
                    `id` INT AUTO_INCREMENT PRIMARY KEY,
                    `type` VARCHAR(60) NOT NULL,
                    `identifier` VARCHAR(255) DEFAULT NULL,
                    `name` LONGTEXT DEFAULT NULL,
                    `label` VARCHAR(255) DEFAULT NULL,
                    `data` LONGTEXT DEFAULT NULL,
                    INDEX `idx_identifier` (`identifier`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
            ]], {}, function()
                callback(true)
            end)
        end)
    end)
end

local function CleanupTestTables()
    local t = ServerTest.config.tables
    MySQL.Async.execute("DROP TABLE IF EXISTS `" .. t.users .. "`", {}, function() end)
    MySQL.Async.execute("DROP TABLE IF EXISTS `" .. t.storage .. "`", {}, function() end)
    MySQL.Async.execute("DROP TABLE IF EXISTS `" .. t.clothes .. "`", {}, function() end)
end

-- ============================================================================
-- SEED TEST DATA
-- ============================================================================

local function SeedTestData(playerCount, callback)
    ServerTest.testData.users = {}
    ServerTest.testData.storage = {}
    
    local t = ServerTest.config.tables
    local pending = playerCount + 10
    local done = 0
    
    local function checkDone()
        done = done + 1
        if done >= pending then callback(true) end
    end
    
    -- Insérer joueurs dans la table test
    for i = 1, playerCount do
        local player = ServerTest.fakePlayers[i]
        if not player then checkDone() goto continue end
        
        table.insert(ServerTest.testData.users, player.identifier)
        
        -- Utilise getJsonCache (même pattern que ESX.SavePlayer optimisé)
        MySQL.Async.execute(
            "INSERT INTO `" .. t.users .. "` (identifier, name, firstname, lastname, position, accounts, inventory, loadout, clothes, job, job_grade, job2, job2_grade, playtime, smells, permission_group, permission_level) VALUES (@id, @name, @fn, @ln, @pos, @acc, @inv, @lo, @cl, @job, @jg, @j2, @j2g, @pt, @sm, @pg, @pl)",
            {
                ['@id'] = player.identifier,
                ['@name'] = player.name,
                ['@fn'] = player.firstname,
                ['@ln'] = player.lastname,
                ['@pos'] = player.getJsonCache('position'),
                ['@acc'] = player.getJsonCache('accounts'),
                ['@inv'] = player.getJsonCache('inventory'),
                ['@lo'] = player.getJsonCache('loadout'),
                ['@cl'] = player.getJsonCache('clothes'),
                ['@job'] = player.job.name,
                ['@jg'] = player.job.grade,
                ['@j2'] = player.job2.name,
                ['@j2g'] = player.job2.grade,
                ['@pt'] = player.playtime,
                ['@sm'] = player.getJsonCache('smells'),
                ['@pg'] = player.permission_group,
                ['@pl'] = player.permission_level,
            }, function() checkDone() end
        )
        ::continue::
    end
    
    -- Créer coffres test
    for i = 1, 10 do
        local storageName = "test_coffre_" .. i
        table.insert(ServerTest.testData.storage, storageName)
        
        local coffreData = {
            cash = math.random(0, 10000),
            dirtycash = math.random(0, 50000),
            items = {},
            loadout = {},
            clothes = {},
        }
        for j = 1, math.random(5, 15) do
            table.insert(coffreData.items, {
                name = ITEM_NAMES[math.random(1, #ITEM_NAMES)],
                count = math.random(1, 100),
            })
        end
        
        local coffreJson = json.encode(coffreData)
        ServerTest.stats.jsonEncodes = ServerTest.stats.jsonEncodes + 1
        
        MySQL.Async.execute(
            "INSERT INTO `" .. t.storage .. "` (name, coffre) VALUES (@name, @coffre) ON DUPLICATE KEY UPDATE coffre = @coffre",
            { ['@name'] = storageName, ['@coffre'] = coffreJson },
            function() checkDone() end
        )
    end
end

-- ============================================================================
-- SIMULATION QUERIES (sur tables test)
-- ============================================================================

local function ExecuteTestQuery(queryType, callback)
    local t = ServerTest.config.tables
    local startTime = GetGameTimer()
    local query, params, isSelect
    
    if queryType == "select_user" then
        isSelect = true
        local id = ServerTest.testData.users[math.random(1, math.max(1, #ServerTest.testData.users))] or "none"
        local queries = {
            "SELECT * FROM `" .. t.users .. "` WHERE identifier = @id",
            "SELECT position, accounts, inventory FROM `" .. t.users .. "` WHERE identifier = @id",
            "SELECT job, job_grade, job2, job2_grade FROM `" .. t.users .. "` WHERE identifier = @id",
            "SELECT accounts, inventory, loadout, clothes FROM `" .. t.users .. "` WHERE identifier = @id",
            "SELECT COUNT(*) as c FROM `" .. t.users .. "` WHERE job = @job",
        }
        query = queries[math.random(1, #queries)]
        params = { ['@id'] = id, ['@job'] = JOBS[math.random(1, #JOBS)] }
        
    elseif queryType == "select_storage" then
        isSelect = true
        local name = ServerTest.testData.storage[math.random(1, math.max(1, #ServerTest.testData.storage))] or "test_coffre_1"
        query = "SELECT coffre FROM `" .. t.storage .. "` WHERE name = @name"
        params = { ['@name'] = name }
        
    elseif queryType == "select_clothes" then
        isSelect = true
        local id = ServerTest.testData.users[math.random(1, math.max(1, #ServerTest.testData.users))] or "none"
        query = "SELECT * FROM `" .. t.clothes .. "` WHERE identifier = @id"
        params = { ['@id'] = id }
        
    elseif queryType == "update_user" then
        isSelect = false
        local player = ServerTest.fakePlayers[math.random(1, math.max(1, #ServerTest.fakePlayers))]
        if player then
            -- Utilise getJsonCache (même pattern que ESX.SavePlayer optimisé)
            query = "UPDATE `" .. t.users .. "` SET accounts = @acc, inventory = @inv, loadout = @lo, clothes = @cl, position = @pos, smells = @sm, job = @job, job_grade = @jg, playtime = @pt WHERE identifier = @id"
            params = {
                ['@id'] = player.identifier,
                ['@acc'] = player.getJsonCache('accounts'),
                ['@inv'] = player.getJsonCache('inventory'),
                ['@lo'] = player.getJsonCache('loadout'),
                ['@cl'] = player.getJsonCache('clothes'),
                ['@pos'] = player.getJsonCache('position'),
                ['@sm'] = player.getJsonCache('smells'),
                ['@job'] = player.job.name,
                ['@jg'] = player.job.grade,
                ['@pt'] = player.playtime,
            }
        else
            callback(true, 0)
            return
        end
        
    elseif queryType == "update_storage" then
        isSelect = false
        local name = ServerTest.testData.storage[math.random(1, math.max(1, #ServerTest.testData.storage))] or "test_coffre_1"
        local coffreData = {
            cash = math.random(0, 10000),
            dirtycash = math.random(0, 50000),
            items = GenerateInventory(math.random(3, 12)),
            loadout = {},
            clothes = {},
        }
        local coffreJson = json.encode(coffreData)
        ServerTest.stats.jsonEncodes = ServerTest.stats.jsonEncodes + 1
        query = "UPDATE `" .. t.storage .. "` SET coffre = @coffre WHERE name = @name"
        params = { ['@name'] = name, ['@coffre'] = coffreJson }
    else
        callback(true, 0)
        return
    end
    
    if isSelect then
        MySQL.Async.fetchAll(query, params, function(result)
            local execTime = GetGameTimer() - startTime
            -- Simuler json.decode sur le résultat (comme LoadStorage / LoadUser)
            if result and #result > 0 then
                for _, row in ipairs(result) do
                    for col, val in pairs(row) do
                        if type(val) == "string" and (val:sub(1,1) == "{" or val:sub(1,1) == "[") then
                            pcall(json.decode, val)
                            ServerTest.stats.jsonDecodes = ServerTest.stats.jsonDecodes + 1
                        end
                    end
                end
            end
            callback(result ~= nil, execTime)
        end)
    else
        MySQL.Async.execute(query, params, function(rowsChanged)
            local execTime = GetGameTimer() - startTime
            callback(rowsChanged ~= nil, execTime)
        end)
    end
end

local function GetWeightedQueryType()
    local rand = math.random(1, 100)
    local cumulative = 0
    for queryType, weight in pairs(ServerTest.config.queryWeights) do
        cumulative = cumulative + weight
        if rand <= cumulative then
            return queryType
        end
    end
    return "select_user"
end

-- ============================================================================
-- SIMULATION: ACTIVITE JOUEUR (json.encode/decode, cache ops)
-- ============================================================================

local function SimulatePlayerActivity()
    if not ServerTest.active then return end
    local playerCount = #ServerTest.fakePlayers
    if playerCount == 0 then return end
    
    local player = ServerTest.fakePlayers[math.random(1, playerCount)]
    if not player then return end
    
    local action = math.random(1, 10)
    
    if action <= 3 then
        -- Modification argent (trigger admin refresh en réel)
        local accName = ACCOUNT_NAMES[math.random(1, #ACCOUNT_NAMES)]
        local acc = player.getAccount(accName)
        if acc then
            acc.money = math.max(0, acc.money + math.random(-500, 1000))
            player.markDirty('accounts')
        end
        ServerTest.stats.inventoryOps = ServerTest.stats.inventoryOps + 1
        
    elseif action <= 5 then
        -- Modification inventaire
        local inv = player.getInventory()
        if #inv > 0 then
            local idx = math.random(1, #inv)
            inv[idx].count = math.max(0, inv[idx].count + math.random(-5, 10))
            player.markDirty('inventory')
        end
        ServerTest.stats.inventoryOps = ServerTest.stats.inventoryOps + 1
        
    elseif action <= 7 then
        -- Utilise getJsonCache (comme null:inventory:update optimisé)
        player.getJsonCache('inventory')
        player.getJsonCache('accounts')
        
    elseif action <= 9 then
        -- Ouvrir/fermer un coffre cache
        local storageKey = "SOCIETY_test_coffre_" .. math.random(1, 10)
        if ServerTest.fakeInventoryCache[storageKey] then
            -- Sauvegarder (json.encode comme Storage.SaveFromCache)
            local cached = ServerTest.fakeInventoryCache[storageKey]
            if cached and cached.data then
                local saveData = {
                    cash = cached.data.cash or 0,
                    dirtycash = cached.data.dirtycash or 0,
                    items = {},
                    loadout = {},
                    clothes = {},
                }
                for _, item in pairs(cached.data.items or {}) do
                    table.insert(saveData.items, { name = item.name, count = item.count, metadata = item.metadata })
                end
                json.encode(saveData)
                ServerTest.stats.jsonEncodes = ServerTest.stats.jsonEncodes + 1
            end
            ServerTest.fakeInventoryCache[storageKey] = nil
        else
            -- Ouvrir (json.decode comme Storage.LoadStorage)
            ServerTest.fakeInventoryCache[storageKey] = CreateFakeInventoryCache(storageKey, player.source)
            ServerTest.stats.jsonDecodes = ServerTest.stats.jsonDecodes + 1
        end
        ServerTest.stats.inventoryOps = ServerTest.stats.inventoryOps + 1
        
    else
        -- Position update
        player.lastPosition = {
            x = player.lastPosition.x + math.random(-10, 10),
            y = player.lastPosition.y + math.random(-10, 10),
            z = player.lastPosition.z + math.random(-2, 2),
        }
        player.coords = {
            x = player.lastPosition.x,
            y = player.lastPosition.y,
            z = player.lastPosition.z,
            heading = math.random(0, 359) + 0.0,
        }
    end
end

-- ============================================================================
-- SIMULATION: STAFF OVERHEAD
-- ============================================================================

local function SimulateStaffRefresh()
    if not ServerTest.active then return end
    
    local staffCount = #ServerTest.fakeStaffList
    if staffCount == 0 then return end
    
    -- Chaque staff fait un getLightAllPlayers (O(n) sur tous les joueurs)
    local allLight = getLightAllPlayers(ServerTest.fakePlayersByIdUnique)
    ServerTest.stats.adminRefreshes = ServerTest.stats.adminRefreshes + 1
    
    -- En réalité ça fait un TriggerClientEvent avec toutes ces données à chaque staff
    -- On simule le coût mémoire de la sérialisation
    -- msgpack encode est similaire à json.encode en termes de CPU
end

local function SimulateStaffPlayerRefresh()
    if not ServerTest.active then return end
    
    local playerCount = #ServerTest.fakePlayers
    if playerCount == 0 then return end
    
    -- refreshOnePlayer: getLightPlayerData pour UN joueur, envoyé à tous les staff
    local player = ServerTest.fakePlayers[math.random(1, playerCount)]
    if player then
        local lightData = getLightPlayerData(player)
        ServerTest.stats.adminRefreshes = ServerTest.stats.adminRefreshes + 1
    end
end

local function SimulateStaffInventoryLookup()
    if not ServerTest.active then return end
    
    local playerCount = #ServerTest.fakePlayers
    if playerCount == 0 then return end
    
    -- Un staff regarde l'inventaire d'un joueur (ServerCallback getPlayerInventory)
    local player = ServerTest.fakePlayers[math.random(1, playerCount)]
    if player then
        local inv = player.getInventory()
        local loadout = player.getLoadout()
        -- Sérialisation pour envoi au client staff
        json.encode(inv)
        json.encode(loadout)
        ServerTest.stats.jsonEncodes = ServerTest.stats.jsonEncodes + 2
        ServerTest.stats.adminRefreshes = ServerTest.stats.adminRefreshes + 1
    end
end

-- ============================================================================
-- SIMULATION: DB SAVE PERIODIQUE (comme ESX.SavePlayers)
-- ============================================================================

local function SimulatePeriodicSave()
    if not ServerTest.active then return end
    
    local playerCount = #ServerTest.fakePlayers
    if playerCount == 0 then return end
    
    -- Sauvegardes étalées par lots (même pattern que ESX.StartDBSync optimisé)
    local BATCH_SIZE = 10
    local totalBatches = math.ceil(playerCount / BATCH_SIZE)
    local SAVE_INTERVAL = ServerTest.config.dbSaveInterval
    local delayBetweenBatches = math.max(500, math.floor(SAVE_INTERVAL / (totalBatches + 1)))
    
    print(string.format("[^3ServerTest^7] Sauvegarde étalée: %d joueurs en %d lots (délai %dms entre lots)", playerCount, totalBatches, delayBetweenBatches))
    
    local t = ServerTest.config.tables
    for batchIndex = 1, totalBatches do
        SetTimeout(delayBetweenBatches * (batchIndex - 1), function()
            if not ServerTest.active then return end
            local startIdx = (batchIndex - 1) * BATCH_SIZE + 1
            local endIdx = math.min(batchIndex * BATCH_SIZE, playerCount)
            
            for i = startIdx, endIdx do
                local player = ServerTest.fakePlayers[i]
                if not player then goto continue end
                
                -- Utilise getJsonCache (seuls les champs dirty sont ré-encodés)
                MySQL.Async.execute(
                    "UPDATE `" .. t.users .. "` SET accounts = @acc, inventory = @inv, loadout = @lo, clothes = @cl, position = @pos, smells = @sm, job = @job, job_grade = @jg, playtime = playtime + 300 WHERE identifier = @id",
                    {
                        ['@id'] = player.identifier,
                        ['@acc'] = player.getJsonCache('accounts'),
                        ['@inv'] = player.getJsonCache('inventory'),
                        ['@lo'] = player.getJsonCache('loadout'),
                        ['@cl'] = player.getJsonCache('clothes'),
                        ['@pos'] = player.getJsonCache('position'),
                        ['@sm'] = player.getJsonCache('smells'),
                        ['@job'] = player.job.name,
                        ['@jg'] = player.job.grade,
                    }, function(rows)
                        ServerTest.stats.queriesTotal = ServerTest.stats.queriesTotal + 1
                    end
                )
                ::continue::
            end
        end)
    end
end

-- ============================================================================
-- TEST CONTROL
-- ============================================================================

function ServerTest.Start(playerCount)
    if ServerTest.active then
        print("[^1ServerTest^7] Un test est déjà en cours. Utilisez servertest_stop d'abord.")
        return false
    end
    
    if not devmode then
        print("[^1ServerTest^7] Requiert devmode = true")
        return false
    end
    
    playerCount = math.min(tonumber(playerCount) or 10, 500)
    -- Ratio staff réaliste: base 5 + 1 par tranche de 50 joueurs, plafonné à 20
    -- Petits serveurs: 5-7 staff | Moyens: 8-12 | Gros: 13-20
    local staffCount = math.min(
        ServerTest.config.staffMaximum or 20,
        math.max(
            ServerTest.config.staffMinimum or 7,
            5 + math.floor(playerCount / 50)
        )
    )
    
    print("[^3ServerTest^7] ================================================")
    print(string.format("[^3ServerTest^7] Préparation: %d joueurs + %d staff simulés", playerCount, staffCount))
    print("[^3ServerTest^7] ================================================")
    
    -- Phase 1: Nettoyage + Création tables
    print("[^3ServerTest^7] [1/4] Nettoyage tables précédentes...")
    CleanupTestTables()
    Wait(500)
    
    print("[^3ServerTest^7] [2/4] Création tables test isolées...")
    SetupTestTables(function(success)
        if not success then
            print("[^1ServerTest^7] Échec création tables")
            return
        end
        
        -- Phase 2: Créer les objets joueurs en mémoire
        print("[^3ServerTest^7] [3/4] Création objets joueurs en mémoire...")
        collectgarbage("collect")
        Wait(100)
        local ramBefore = GetMemoryUsage()
        
        -- Créer les fake players
        ServerTest.fakePlayers = {}
        ServerTest.fakePlayersByIdUnique = {}
        ServerTest.fakePlayersByIdentifier = {}
        ServerTest.fakeJobCache = {}
        ServerTest.fakeInventoryCache = {}
        ServerTest.fakeStaffList = {}
        
        for i = 1, playerCount do
            local fakeSource = 9000 + i
            local player, identifier, idunique = CreateFakePlayer(fakeSource, i)
            
            ServerTest.fakePlayers[i] = player
            ServerTest.fakePlayersByIdUnique[idunique] = player
            ServerTest.fakePlayersByIdentifier[identifier] = player
            
            -- Job cache
            if not ServerTest.fakeJobCache[player.job.name] then
                ServerTest.fakeJobCache[player.job.name] = {}
            end
            ServerTest.fakeJobCache[player.job.name][fakeSource] = fakeSource
        end
        
        -- Créer les staff (parmi les joueurs)
        local staffAssigned = 0
        for i = 1, playerCount do
            if staffAssigned >= staffCount then break end
            local player = ServerTest.fakePlayers[i]
            if player.permission_group ~= "user" then
                table.insert(ServerTest.fakeStaffList, {
                    group = player.permission_group,
                    source = player.source,
                    idunique = player.idunique,
                    name = player.name,
                    staffmode = true,
                })
                staffAssigned = staffAssigned + 1
            end
        end
        -- Compléter si pas assez de staff naturels
        while staffAssigned < staffCount do
            local player = ServerTest.fakePlayers[staffAssigned + 1]
            if player then
                player.permission_group = "mod"
                player.staffmode = true
                table.insert(ServerTest.fakeStaffList, {
                    group = "mod",
                    source = player.source,
                    idunique = player.idunique,
                    name = player.name,
                    staffmode = true,
                })
            end
            staffAssigned = staffAssigned + 1
        end
        
        -- Créer des caches inventaire (% joueurs avec coffre ouvert)
        local openCount = math.ceil(playerCount * ServerTest.config.openStoragePercent / 100)
        for i = 1, math.min(openCount, 10) do
            local key = "SOCIETY_test_coffre_" .. i
            local playerSrc = ServerTest.fakePlayers[math.random(1, playerCount)].source
            ServerTest.fakeInventoryCache[key] = CreateFakeInventoryCache(key, playerSrc)
        end
        
        collectgarbage("collect")
        Wait(100)
        local ramAfterObjects = GetMemoryUsage()
        local ramPerPlayer = (ramAfterObjects - ramBefore) / playerCount
        
        print(string.format("[^3ServerTest^7] Mémoire objets joueurs: %.2f MB (%.3f MB/joueur)", ramAfterObjects - ramBefore, ramPerPlayer))
        print(string.format("[^3ServerTest^7] Staff: %d | Coffres ouverts: %d | Job caches: %d", 
            #ServerTest.fakeStaffList, openCount, ESX.Table and ESX.Table.SizeOf and 0 or 0))
        
        -- Phase 3: Seed MySQL
        print("[^3ServerTest^7] [4/4] Insertion données test MySQL...")
        SeedTestData(playerCount, function()
            -- Phase 4: Démarrer la simulation
            ServerTest.active = true
            ServerTest.stats = {
                startTime = GetGameTimer(),
                ramBeforeMB = ramBefore,
                ramCurrentMB = ramAfterObjects,
                ramPeakMB = ramAfterObjects,
                ramObjectsMB = ramAfterObjects - ramBefore,
                ramPerPlayerMB = ramPerPlayer,
                queriesTotal = 0,
                queriesFailed = 0,
                avgQueryTime = 0,
                jsonEncodes = 0,
                jsonDecodes = 0,
                cacheHits = 0,
                adminRefreshes = 0,
                inventoryOps = 0,
                simulatedPlayers = playerCount,
                simulatedStaff = #ServerTest.fakeStaffList,
            }
            ServerTest.queryTimes = {}
            
            local queriesPerSecond = (playerCount * ServerTest.config.queriesPerPlayerPerMinute) / 60
            local msBetweenQueries = math.max(1, math.floor(1000 / queriesPerSecond))
            
            print("[^2ServerTest^7] ================================================")
            print(string.format("[^2ServerTest^7] TEST DÉMARRÉ: %d joueurs | %d staff", playerCount, #ServerTest.fakeStaffList))
            print(string.format("[^2ServerTest^7] RAM: %.2f MB | Requêtes: ~%.1f/sec", ramAfterObjects, queriesPerSecond))
            print("[^2ServerTest^7] Tables: " .. ServerTest.config.tables.users .. ", " .. ServerTest.config.tables.storage)
            print("[^2ServerTest^7] ================================================")
            
            -- THREAD 1: Requêtes MySQL continues
            ServerTest.threads.queryGenerator = Citizen.CreateThread(function()
                while ServerTest.active do
                    local queryType = GetWeightedQueryType()
                    ExecuteTestQuery(queryType, function(success, execTime)
                        if not ServerTest.active then return end
                        if success then
                            ServerTest.stats.queriesTotal = ServerTest.stats.queriesTotal + 1
                            table.insert(ServerTest.queryTimes, execTime)
                        else
                            ServerTest.stats.queriesFailed = ServerTest.stats.queriesFailed + 1
                        end
                        if #ServerTest.queryTimes > 200 then
                            table.remove(ServerTest.queryTimes, 1)
                        end
                    end)
                    Wait(msBetweenQueries)
                end
            end)
            
            -- THREAD 2: Activité joueurs (inventaire, argent, coffres)
            ServerTest.threads.playerActivity = Citizen.CreateThread(function()
                while ServerTest.active do
                    SimulatePlayerActivity()
                    Wait(ServerTest.config.playerActivityInterval)
                end
            end)
            
            -- THREAD 3: Staff refresh (getLightAllPlayers)
            ServerTest.threads.staffFullRefresh = Citizen.CreateThread(function()
                while ServerTest.active do
                    -- Chaque staff fait un full refresh régulièrement
                    for _, staff in ipairs(ServerTest.fakeStaffList) do
                        if not ServerTest.active then break end
                        SimulateStaffRefresh()
                        Wait(100)
                    end
                    Wait(ServerTest.config.adminRefreshInterval)
                end
            end)
            
            -- THREAD 4: Staff single player refresh (déclenché par changements joueurs)
            ServerTest.threads.staffPlayerRefresh = Citizen.CreateThread(function()
                while ServerTest.active do
                    -- ~10 refreshes de joueurs individuels par seconde (money/inv changes)
                    SimulateStaffPlayerRefresh()
                    Wait(100)
                end
            end)
            
            -- THREAD 5: Staff inventory lookups
            ServerTest.threads.staffInvLookup = Citizen.CreateThread(function()
                while ServerTest.active do
                    -- Un staff regarde l'inventaire d'un joueur toutes les 5-10s
                    SimulateStaffInventoryLookup()
                    Wait(math.random(5000, 10000))
                end
            end)
            
            -- THREAD 6: Sauvegarde périodique (comme ESX.SavePlayers toutes les 5 min)
            ServerTest.threads.periodicSave = Citizen.CreateThread(function()
                while ServerTest.active do
                    Wait(ServerTest.config.dbSaveInterval)
                    if ServerTest.active then
                        SimulatePeriodicSave()
                    end
                end
            end)
            
            -- THREAD 7: Position sync (comme ESX.SyncPosition toutes les 60s)
            ServerTest.threads.positionSync = Citizen.CreateThread(function()
                while ServerTest.active do
                    Wait(ServerTest.config.positionSyncInterval)
                    if not ServerTest.active then break end
                    for i = 1, #ServerTest.fakePlayers do
                        local player = ServerTest.fakePlayers[i]
                        if player then
                            player.lastPosition = {
                                x = player.lastPosition.x + math.random(-5, 5),
                                y = player.lastPosition.y + math.random(-5, 5),
                                z = player.lastPosition.z,
                            }
                            player.markDirty('position')
                        end
                    end
                end
            end)
            
            -- THREAD 8: Monitoring
            ServerTest.threads.monitor = Citizen.CreateThread(function()
                while ServerTest.active do
                    local currentRam = GetMemoryUsage()
                    ServerTest.stats.ramCurrentMB = currentRam
                    if currentRam > ServerTest.stats.ramPeakMB then
                        ServerTest.stats.ramPeakMB = currentRam
                    end
                    
                    if #ServerTest.queryTimes > 0 then
                        local total = 0
                        for _, t in ipairs(ServerTest.queryTimes) do total = total + t end
                        ServerTest.stats.avgQueryTime = total / #ServerTest.queryTimes
                    end
                    
                    local duration = (GetGameTimer() - ServerTest.stats.startTime) / 1000
                    local qps = duration > 0 and (ServerTest.stats.queriesTotal / duration) or 0
                    local ramDelta = currentRam - ServerTest.stats.ramBeforeMB
                    
                    print(string.format(
                        "[^3ServerTest^7] RAM: %.1f MB (+%.1f) | Q: %d (%.1f/s, avg %.1fms) | JSON: %d enc / %d dec / %d cache hits | Staff: %d ref | InvOps: %d",
                        currentRam, ramDelta, ServerTest.stats.queriesTotal, qps, ServerTest.stats.avgQueryTime,
                        ServerTest.stats.jsonEncodes, ServerTest.stats.jsonDecodes, ServerTest.stats.cacheHits or 0,
                        ServerTest.stats.adminRefreshes, ServerTest.stats.inventoryOps
                    ))
                    
                    Wait(ServerTest.config.monitorInterval)
                end
            end)
        end)
    end)
    
    return true
end

function ServerTest.Stop()
    if not ServerTest.active then
        print("[^1ServerTest^7] Aucun test en cours")
        return false
    end
    
    ServerTest.active = false
    
    for name, _ in pairs(ServerTest.threads) do
        ServerTest.threads[name] = nil
    end
    
    Wait(500)
    collectgarbage("collect")
    Wait(500)
    local ramAfter = GetMemoryUsage()
    
    local duration = (GetGameTimer() - ServerTest.stats.startTime) / 1000
    local ramDelta = ramAfter - ServerTest.stats.ramBeforeMB
    local qps = duration > 0 and (ServerTest.stats.queriesTotal / duration) or 0
    
    print("")
    print("[^2ServerTest^7] ======================================================")
    print("[^2ServerTest^7]              RÉSULTATS DU TEST DE CHARGE              ")
    print("[^2ServerTest^7] ======================================================")
    print("")
    print(string.format("  ^3Joueurs simulés:^7        %d", ServerTest.stats.simulatedPlayers))
    print(string.format("  ^3Staff simulés:^7          %d (ratio 1:%d, min %d)", ServerTest.stats.simulatedStaff, ServerTest.config.staffRatio, ServerTest.config.staffMinimum))
    print(string.format("  ^3Durée:^7                  %.1f secondes", duration))
    print("")
    print("  ^5--- Mémoire ---^7")
    print(string.format("  RAM avant test:           %.2f MB", ServerTest.stats.ramBeforeMB))
    print(string.format("  RAM objets joueurs:       %.2f MB (%.3f MB/joueur)", ServerTest.stats.ramObjectsMB or 0, ServerTest.stats.ramPerPlayerMB or 0))
    print(string.format("  RAM peak:                 %.2f MB", ServerTest.stats.ramPeakMB))
    print(string.format("  RAM après cleanup:        %.2f MB", ramAfter))
    print(string.format("  Delta RAM total:          %+.2f MB", ramDelta))
    print("")
    print("  ^5--- MySQL ---^7")
    print(string.format("  Requêtes totales:         %d", ServerTest.stats.queriesTotal))
    print(string.format("  Requêtes échouées:        %d", ServerTest.stats.queriesFailed))
    print(string.format("  Requêtes/sec:             %.1f", qps))
    print(string.format("  Temps moyen requête:      %.2f ms", ServerTest.stats.avgQueryTime))
    print("")
    print("  ^5--- CPU (json/cache) ---^7")
    print(string.format("  json.encode:              %d appels (%.1f/sec)", ServerTest.stats.jsonEncodes, ServerTest.stats.jsonEncodes / math.max(1, duration)))
    print(string.format("  json.decode:              %d appels (%.1f/sec)", ServerTest.stats.jsonDecodes, ServerTest.stats.jsonDecodes / math.max(1, duration)))
    print(string.format("  Cache hits:               %d (%.1f%% hit rate)", ServerTest.stats.cacheHits or 0, (ServerTest.stats.cacheHits or 0) / math.max(1, ServerTest.stats.cacheHits + ServerTest.stats.jsonEncodes) * 100))
    print(string.format("  Admin refreshes:          %d (%.1f/sec)", ServerTest.stats.adminRefreshes, ServerTest.stats.adminRefreshes / math.max(1, duration)))
    print(string.format("  Opérations inventaire:    %d", ServerTest.stats.inventoryOps))
    print("")
    print("  ^5Optimisations simulées:^7")
    print("  - Dirty flags + JSON cache (player.lua)")
    print("  - Sauvegardes étalées par lots (ESX.StartDBSync)")
    print("  - Loadout minimal sans label")
    print("")
    print("[^2ServerTest^7] ======================================================")
    print("")
    
    -- Nettoyage mémoire
    print("[^3ServerTest^7] Nettoyage mémoire + tables MySQL...")
    ServerTest.fakePlayers = {}
    ServerTest.fakePlayersByIdUnique = {}
    ServerTest.fakePlayersByIdentifier = {}
    ServerTest.fakeJobCache = {}
    ServerTest.fakeInventoryCache = {}
    ServerTest.fakeStaffList = {}
    ServerTest.testData = { users = {}, storage = {} }
    
    collectgarbage("collect")
    CleanupTestTables()
    
    Wait(300)
    local ramFinal = GetMemoryUsage()
    print(string.format("[^3ServerTest^7] RAM finale après cleanup: %.2f MB (libéré: %.2f MB)", ramFinal, ServerTest.stats.ramPeakMB - ramFinal))
    
    return true
end

-- ============================================================================
-- COMMANDS
-- ============================================================================

RegisterCommand("servertest", function(source, args, rawCommand)
    if not devmode then
        print("[^1ServerTest^7] Cette commande requiert devmode = true")
        return
    end
    
    local playerCount = tonumber(args[1])
    
    if not playerCount or playerCount < 1 then
        print("[^3ServerTest^7] ─────────────────────────────────────────")
        print("[^3ServerTest^7] Usage: servertest [nombre_de_joueurs]")
        print("[^3ServerTest^7] Exemple: servertest 50  (simule 50 joueurs)")
        print("[^3ServerTest^7] Max: 500 joueurs")
        print("[^3ServerTest^7]")
        print("[^3ServerTest^7] Ce qui est simulé par joueur:")
        print("[^3ServerTest^7]   - Objet joueur complet en RAM (inventaire, armes, comptes, job...)")
        print("[^3ServerTest^7]   - Cache jobs, cache coffres ouverts")
        print("[^3ServerTest^7]   - Requêtes MySQL (~20/min/joueur)")
        print("[^3ServerTest^7]   - Dirty flags + JSON cache (seuls les champs modifiés sont ré-encodés)")
        print("[^3ServerTest^7]   - Sauvegardes étalées par lots (évite les pics CPU)")
        print("[^3ServerTest^7]   - Loadout minimal sans label (reconstruit côté client)")
        print("[^3ServerTest^7]   - Overhead staff/admin (1 staff pour 10 joueurs, min 7)")
        print("[^3ServerTest^7]   - Sauvegarde DB périodique (comme ESX.SavePlayers)")
        print("[^3ServerTest^7]   - Position sync, activité inventaire")
        print("[^3ServerTest^7]")
        print("[^3ServerTest^7] Commandes: servertest_stop | servertest_status")
        print("[^3ServerTest^7] ─────────────────────────────────────────")
        return
    end
    
    ServerTest.Start(playerCount)
end, true)

RegisterCommand("servertest_stop", function(source, args, rawCommand)
    if not devmode then
        print("[^1ServerTest^7] Cette commande requiert devmode = true")
        return
    end
    ServerTest.Stop()
end, true)

RegisterCommand("servertest_status", function(source, args, rawCommand)
    if not devmode then
        print("[^1ServerTest^7] Cette commande requiert devmode = true")
        return
    end
    
    if not ServerTest.active then
        print("[^3ServerTest^7] Aucun test en cours")
        return
    end
    
    local duration = (GetGameTimer() - ServerTest.stats.startTime) / 1000
    local qps = duration > 0 and (ServerTest.stats.queriesTotal / duration) or 0
    local ramDelta = ServerTest.stats.ramCurrentMB - ServerTest.stats.ramBeforeMB
    
    print("")
    print("[^3ServerTest^7] ========== STATUS ==========")
    print(string.format("  Actif depuis: %.1f sec", duration))
    print(string.format("  Joueurs: %d | Staff: %d", ServerTest.stats.simulatedPlayers, ServerTest.stats.simulatedStaff))
    print(string.format("  RAM: %.1f MB (+%.1f) | Peak: %.1f MB", ServerTest.stats.ramCurrentMB, ramDelta, ServerTest.stats.ramPeakMB))
    print(string.format("  RAM/joueur (objets): %.3f MB", ServerTest.stats.ramPerPlayerMB or 0))
    print(string.format("  MySQL: %d requêtes (%.1f/s) | avg %.1fms | %d échouées", ServerTest.stats.queriesTotal, qps, ServerTest.stats.avgQueryTime, ServerTest.stats.queriesFailed))
    print(string.format("  JSON: %d encode | %d decode | %d cache hits", ServerTest.stats.jsonEncodes, ServerTest.stats.jsonDecodes, ServerTest.stats.cacheHits or 0))
    print(string.format("  Admin: %d refreshes | InvOps: %d", ServerTest.stats.adminRefreshes, ServerTest.stats.inventoryOps))
    print("[^3ServerTest^7] ============================")
    print("")
end, true)

-- ============================================================================
-- CLEANUP
-- ============================================================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if ServerTest.active then
        ServerTest.active = false
        ServerTest.fakePlayers = {}
        ServerTest.fakePlayersByIdUnique = {}
        ServerTest.fakePlayersByIdentifier = {}
        ServerTest.fakeJobCache = {}
        ServerTest.fakeInventoryCache = {}
        ServerTest.fakeStaffList = {}
        CleanupTestTables()
    end
end)