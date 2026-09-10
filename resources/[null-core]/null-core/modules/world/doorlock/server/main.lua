-- ============================================================================
-- Null Doorlock — Serveur
-- Source de vérité des portes : état, permissions, persistance DB, broadcast.
-- ============================================================================

local Doors = {}          -- [id] = doorData (état autoritaire)
local DoorsLoaded = false
local autolockTimers = {} -- [id] = true si un thread d'auto-lock tourne déjà

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function decodeJson(str, fallback)
    if not str or str == '' then return fallback end
    local ok, res = pcall(json.decode, str)
    if ok and res ~= nil then return res end
    return fallback
end

-- Payload "public" (tous les clients) : juste ce qu'il faut pour rendre la porte.
local function buildClientDoor(door)
    return {
        id       = door.id,
        label    = door.label,
        locked   = door.locked,
        doors    = door.doors,
        lockpick = door.lockpick,
        hasCode  = door.code ~= nil and door.code ~= '',
    }
end

local function buildClientPayload()
    local out = {}
    for id, door in pairs(Doors) do
        out[id] = buildClientDoor(door)
    end
    return out
end

-- Payload "éditeur" (admins only) : tous les détails de config pour le menu.
local function buildEditorDoor(door)
    return {
        id        = door.id,
        label     = door.label,
        locked    = door.locked,
        doors     = door.doors,
        groups    = door.groups or {},
        items     = door.items or {},
        code      = door.code,
        adminRank = door.adminRank,
        lockpick  = door.lockpick,
        autolock  = door.autolock,
    }
end

local function buildEditorPayload()
    local out = {}
    for _, door in pairs(Doors) do
        out[#out + 1] = buildEditorDoor(door)
    end
    table.sort(out, function(a, b) return (a.id or 0) < (b.id or 0) end)
    return out
end

-- Vérifie si un xPlayer a le droit de (dé)verrouiller une porte donnée.
local function canPlayerAccess(xPlayer, door)
    if not door then return false end

    local hasGroupRule = door.groups and next(door.groups) ~= nil
    local hasItemRule  = door.items and #door.items > 0
    local hasAdminRule = door.adminRank and door.adminRank ~= ''
    local hasCodeRule  = door.code and door.code ~= ''

    -- Aucune restriction => porte publique.
    if not hasGroupRule and not hasItemRule and not hasAdminRule then
        return true
    end

    if not xPlayer then return false end

    -- Rank admin : le joueur passe si son grade >= grade du rang requis.
    if hasAdminRule then
        local pgroup = xPlayer.getGroup and xPlayer.getGroup() or nil
        if pgroup then
            local gradeTable  = Config and Config.GroupeGrade or nil
            local playerGrade = (gradeTable and gradeTable[pgroup] and gradeTable[pgroup].grade) or 0
            local needGrade   = (gradeTable and gradeTable[door.adminRank] and gradeTable[door.adminRank].grade) or 999
            if pgroup == door.adminRank or playerGrade >= needGrade then return true end
        end
    end

    -- Jobs (principal + secondaire).
    if hasGroupRule then
        local jobs = {}
        if xPlayer.getJob then jobs[#jobs + 1] = xPlayer.getJob() end
        if xPlayer.getJob2 then jobs[#jobs + 1] = xPlayer.getJob2() end
        for _, job in ipairs(jobs) do
            if job and job.name then
                local requiredGrade = door.groups[job.name]
                if requiredGrade ~= nil and (job.grade or 0) >= requiredGrade then
                    return true
                end
            end
        end
        local pgroup = xPlayer.getGroup and xPlayer.getGroup() or nil
        if pgroup and door.groups[pgroup] ~= nil then return true end
    end

    -- Items (clés).
    if hasItemRule and xPlayer.getInventoryItem then
        for _, itemName in ipairs(door.items) do
            local item = xPlayer.getInventoryItem(itemName)
            if item and (item.count or 0) > 0 then return true end
        end
    end

    return false
end

local function notify(src, msg)
    TriggerClientEvent('null:notification', src, msg)
end

local function isEditor(xPlayer)
    if not xPlayer then return false end
    local group = xPlayer.getGroup and xPlayer.getGroup() or nil
    if not group then return false end

    -- Groupes explicitement autorisés (ex: dev, fondateur).
    if DoorlockConfig.EditorExtraGroups and DoorlockConfig.EditorExtraGroups[group] then
        return true
    end

    -- Vérification par grade (système null).
    local gradeTable = Config and Config.GroupeGrade or nil
    local info = gradeTable and gradeTable[group] or nil
    local grade = info and info.grade or 0
    return grade >= (DoorlockConfig.EditorMinGrade or 8)
end

-- ---------------------------------------------------------------------------
-- Chargement DB
-- ---------------------------------------------------------------------------

local function loadDoors()
    local result = MySQL.query.await('SELECT * FROM `Null_doorlock`') or {}
    Doors = {}
    for _, row in ipairs(result) do
        Doors[row.id] = {
            id        = row.id,
            label     = row.label,
            locked    = row.locked == 1,
            doors     = decodeJson(row.doors, {}),
            groups    = decodeJson(row.groups, {}),
            items     = decodeJson(row.items, {}),
            code      = row.code,
            adminRank = row.admin_rank,
            lockpick  = row.lockpick == 1,
            autolock  = row.autolock,
        }
    end
    DoorsLoaded = true
    null.DebugPrint(('[Doorlock] %d porte(s) chargée(s) depuis la DB'):format(#result))
    TriggerClientEvent('Null_doorlock:syncAll', -1, buildClientPayload())
end

CreateThread(function()
    while not MySQL do Wait(50) end
    MySQL.ready(function()
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS `Null_doorlock` (
                `id` INT(11) NOT NULL AUTO_INCREMENT,
                `label` VARCHAR(64) DEFAULT NULL,
                `locked` TINYINT(1) NOT NULL DEFAULT 1,
                `doors` LONGTEXT NOT NULL,
                `groups` LONGTEXT DEFAULT NULL,
                `items` LONGTEXT DEFAULT NULL,
                `code` VARCHAR(32) DEFAULT NULL,
                `admin_rank` VARCHAR(32) DEFAULT NULL,
                `lockpick` TINYINT(1) NOT NULL DEFAULT 1,
                `autolock` INT(11) DEFAULT NULL,
                PRIMARY KEY (`id`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]])
        -- Migration douce si la table existait déjà sans les colonnes code/admin_rank.
        local function ensureDoorlockColumn(columnName, definition)
            local count = MySQL.scalar.await([[
                SELECT COUNT(*)
                FROM INFORMATION_SCHEMA.COLUMNS
                WHERE TABLE_SCHEMA = DATABASE()
                  AND TABLE_NAME = 'Null_doorlock'
                  AND COLUMN_NAME = ?
            ]], { columnName })
            if tonumber(count) == 0 then
                MySQL.query.await(("ALTER TABLE `Null_doorlock` ADD COLUMN `%s` %s"):format(columnName, definition))
            end
        end
        ensureDoorlockColumn('code', 'VARCHAR(32) DEFAULT NULL')
        ensureDoorlockColumn('admin_rank', 'VARCHAR(32) DEFAULT NULL')
        loadDoors()
    end)
end)

-- ---------------------------------------------------------------------------
-- Sync
-- ---------------------------------------------------------------------------

RegisterNetEvent('Null_doorlock:requestSync', function()
    local src = source
    if not DoorsLoaded then return end
    TriggerClientEvent('Null_doorlock:syncAll', src, buildClientPayload())
end)

-- Le menu éditeur demande la liste détaillée (admins only).
ESX.RegisterServerCallback('Null_doorlock:getEditorList', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not isEditor(xPlayer) then return cb(false) end
    cb(buildEditorPayload())
end)

-- ---------------------------------------------------------------------------
-- Auto-lock
-- ---------------------------------------------------------------------------

local function scheduleAutolock(door)
    if not door.autolock or door.autolock <= 0 then return end
    if autolockTimers[door.id] then return end
    autolockTimers[door.id] = true
    SetTimeout(door.autolock * 1000, function()
        autolockTimers[door.id] = nil
        local d = Doors[door.id]
        if d and not d.locked then
            d.locked = true
            MySQL.update('UPDATE `Null_doorlock` SET `locked` = 1 WHERE `id` = @id', { ['@id'] = d.id })
            TriggerClientEvent('Null_doorlock:setState', -1, d.id, true, true)
        end
    end)
end

-- ---------------------------------------------------------------------------
-- (Dé)verrouillage
-- ---------------------------------------------------------------------------

local function applyToggle(door)
    door.locked = not door.locked
    MySQL.update('UPDATE `Null_doorlock` SET `locked` = @locked WHERE `id` = @id', {
        ['@locked'] = door.locked and 1 or 0,
        ['@id']     = door.id,
    })
    TriggerClientEvent('Null_doorlock:setState', -1, door.id, door.locked, false)
    if not door.locked then scheduleAutolock(door) end
end

RegisterNetEvent('Null_doorlock:toggle', function(doorId, viaLockpick)
    local src = source
    local door = Doors[doorId]
    if not door then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if viaLockpick then
        if not door.lockpick or not door.locked then return end
    else
        if not canPlayerAccess(xPlayer, door) then
            notify(src, DoorlockConfig.Text.noAccess)
            return
        end
    end

    applyToggle(door)
end)

-- Déverrouillage par code (validé serveur).
RegisterNetEvent('Null_doorlock:tryCode', function(doorId, code)
    local src = source
    local door = Doors[doorId]
    if not door or not door.code or door.code == '' then return end
    if tostring(code) == tostring(door.code) then
        if door.locked then applyToggle(door) end
        notify(src, '~g~Code correct.')
    else
        notify(src, '~r~Code incorrect.')
    end
end)

ESX.RegisterServerCallback('Null_doorlock:canAccess', function(source, cb, doorId)
    local door = Doors[doorId]
    if not door then return cb(false) end
    local xPlayer = ESX.GetPlayerFromId(source)
    cb(canPlayerAccess(xPlayer, door))
end)

RegisterNetEvent('Null_doorlock:lockpickResult', function(doorId, success)
    local src = source
    local door = Doors[doorId]
    if not door or not door.lockpick then return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if not success and DoorlockConfig.Lockpick.breakOnFail and DoorlockConfig.LockpickItem then
        xPlayer.removeInventoryItem(DoorlockConfig.LockpickItem, 1)
        notify(src, "Votre crochet s'est cassé.")
    end
end)

-- ============================================================================
-- ÉDITEUR — création / édition / suppression (admin only)
-- ============================================================================

ESX.RegisterServerCallback('Null_doorlock:create', function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not isEditor(xPlayer) then return cb(false, 'Accès refusé') end
    if not data or not data.doors or #data.doors == 0 then return cb(false, 'Aucune porte ciblée') end

    local insertId = MySQL.insert.await(
        'INSERT INTO `Null_doorlock` (`label`, `locked`, `doors`, `groups`, `items`, `code`, `admin_rank`, `lockpick`, `autolock`) VALUES (@label, @locked, @doors, @groups, @items, @code, @admin_rank, @lockpick, @autolock)',
        {
            ['@label']      = data.label or 'Porte',
            ['@locked']     = (data.locked ~= false) and 1 or 0,
            ['@doors']      = json.encode(data.doors),
            ['@groups']     = json.encode(data.groups or {}),
            ['@items']      = json.encode(data.items or {}),
            ['@code']       = (data.code ~= '' and data.code) or nil,
            ['@admin_rank'] = (data.adminRank ~= '' and data.adminRank) or nil,
            ['@lockpick']   = (data.lockpick ~= false) and 1 or 0,
            ['@autolock']   = data.autolock,
        }
    )

    if not insertId then return cb(false, 'Erreur DB') end

    Doors[insertId] = {
        id        = insertId,
        label     = data.label or 'Porte',
        locked    = data.locked ~= false,
        doors     = data.doors,
        groups    = data.groups or {},
        items     = data.items or {},
        code      = (data.code ~= '' and data.code) or nil,
        adminRank = (data.adminRank ~= '' and data.adminRank) or nil,
        lockpick  = data.lockpick ~= false,
        autolock  = data.autolock,
    }

    TriggerClientEvent('Null_doorlock:addOne', -1, buildClientDoor(Doors[insertId]))
    cb(true, insertId)
end)

ESX.RegisterServerCallback('Null_doorlock:update', function(source, cb, doorId, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not isEditor(xPlayer) then return cb(false, 'Accès refusé') end
    local door = Doors[doorId]
    if not door then return cb(false, 'Porte introuvable') end

    door.label     = data.label or door.label
    door.groups    = data.groups or door.groups
    door.items     = data.items or door.items
    door.code      = (data.code ~= '' and data.code) or nil
    door.adminRank = (data.adminRank ~= '' and data.adminRank) or nil
    door.lockpick  = (data.lockpick ~= nil) and data.lockpick or door.lockpick
    door.autolock  = data.autolock

    MySQL.update('UPDATE `Null_doorlock` SET `label`=@label, `groups`=@groups, `items`=@items, `code`=@code, `admin_rank`=@admin_rank, `lockpick`=@lockpick, `autolock`=@autolock WHERE `id`=@id', {
        ['@label']      = door.label,
        ['@groups']     = json.encode(door.groups),
        ['@items']      = json.encode(door.items),
        ['@code']       = door.code,
        ['@admin_rank'] = door.adminRank,
        ['@lockpick']   = door.lockpick and 1 or 0,
        ['@autolock']   = door.autolock,
        ['@id']         = door.id,
    })

    TriggerClientEvent('Null_doorlock:addOne', -1, buildClientDoor(door))
    cb(true)
end)

ESX.RegisterServerCallback('Null_doorlock:delete', function(source, cb, doorId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not isEditor(xPlayer) then return cb(false, 'Accès refusé') end
    if not Doors[doorId] then return cb(false, 'Porte introuvable') end
    MySQL.update('DELETE FROM `Null_doorlock` WHERE `id` = @id', { ['@id'] = doorId })
    Doors[doorId] = nil
    TriggerClientEvent('Null_doorlock:removeOne', -1, doorId)
    cb(true)
end)

exports('GetDoor', function(id) return Doors[id] end)
exports('GetDoors', function() return Doors end)
