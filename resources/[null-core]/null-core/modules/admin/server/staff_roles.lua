local StaffRolesLoaded = false

local function normalizePermission(permission)
    if permission == nil then return nil end
    return string.lower(tostring(permission))
end

local function encodePermissions(permissions)
    return json.encode(permissions or {})
end

local function decodePermissions(value)
    if type(value) == "table" then return value end
    if type(value) ~= "string" or value == "" then return {} end

    local ok, decoded = pcall(json.decode, value)
    if ok and type(decoded) == "table" then
        return decoded
    end

    return {}
end

local function getRankConfig(roleName)
    for _, rank in pairs(Config.Admin.RankList or {}) do
        if type(rank) == "table" and rank.rank == roleName then
            return rank
        end
    end
end

local function getDefaultRolePermissions(roleName)
    local permissions = {}
    local gradeData = Config.GroupeGrade and Config.GroupeGrade[roleName]
    local grade = gradeData and tonumber(gradeData.grade)

    if not grade then return permissions end

    for permission, minimumGrade in pairs(Config.Admin.PermissionsGrade or {}) do
        if grade >= tonumber(minimumGrade) then
            permissions[normalizePermission(permission)] = true
        end
    end

    return permissions
end

local function ensureTables()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `staff_roles` (
            `name` VARCHAR(50) NOT NULL,
            `label` VARCHAR(80) NOT NULL,
            `grade` INT NOT NULL DEFAULT 0,
            `inherits` VARCHAR(50) NOT NULL DEFAULT 'user',
            `menu_color` VARCHAR(12) NOT NULL DEFAULT '~s~',
            `gamertag_color` INT NOT NULL DEFAULT 6,
            `gamertag_label` VARCHAR(32) NOT NULL DEFAULT '',
            `can_assign` TINYINT(1) NOT NULL DEFAULT 1,
            `high_perm` TINYINT(1) NOT NULL DEFAULT 0,
            `always_colored` TINYINT(1) NOT NULL DEFAULT 0,
            `star` TINYINT(1) NOT NULL DEFAULT 0,
            `permissions` LONGTEXT NOT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end

local function seedDefaultRoles()
    local countResult = MySQL.query.await("SELECT COUNT(*) AS count FROM `staff_roles`", {}) or {}
    local count = countResult[1] and tonumber(countResult[1].count) or 0

    if count > 0 then return end

    for groupName, gradeData in pairs(Config.GroupeGrade or {}) do
        if groupName ~= Config.DefaultGroup then
            local rank = getRankConfig(groupName) or {}
            local inherits = "user"

            for _, group in ipairs(Config.Groupes or {}) do
                if group.name == groupName then
                    inherits = group.before ~= "" and group.before or "user"
                    break
                end
            end

            MySQL.query.await([[
                INSERT INTO `staff_roles`
                    (`name`, `label`, `grade`, `inherits`, `menu_color`, `gamertag_color`, `gamertag_label`, `can_assign`, `high_perm`, `always_colored`, `star`, `permissions`)
                VALUES
                    (@name, @label, @grade, @inherits, @menu_color, @gamertag_color, @gamertag_label, @can_assign, @high_perm, @always_colored, @star, @permissions)
            ]], {
                ["@name"] = groupName,
                ["@label"] = rank.label or groupName,
                ["@grade"] = tonumber(gradeData.grade) or 0,
                ["@inherits"] = inherits,
                ["@menu_color"] = rank.menuColor or "~s~",
                ["@gamertag_color"] = tonumber(rank.gamertag_color) or 6,
                ["@gamertag_label"] = (Config.Admin.RankListGamerTag and Config.Admin.RankListGamerTag[groupName]) or "",
                ["@can_assign"] = rank.can == false and 0 or 1,
                ["@high_perm"] = (Config.GroupeHighPerm and Config.GroupeHighPerm[groupName]) and 1 or 0,
                ["@always_colored"] = rank.alwayscolored and 1 or 0,
                ["@star"] = rank.star and 1 or 0,
                ["@permissions"] = encodePermissions(getDefaultRolePermissions(groupName))
            })
        end
    end
end

local function sortRoles(a, b)
    if a.grade == b.grade then return a.name < b.name end
    return a.grade < b.grade
end

local function applyRoles(rows)
    local groupList = {
        { name = Config.DefaultGroup, before = "" }
    }
    local groupGrades = {
        [Config.DefaultGroup] = { grade = 0 }
    }
    local highPerms = {}
    local rolePermissions = {}
    local rankList = {}
    local rankLabels = {
        [Config.DefaultGroup] = Config.DefaultGroup
    }
    local rankGamertags = {
        [Config.DefaultGroup] = ""
    }

    table.sort(rows, sortRoles)

    for _, role in ipairs(rows) do
        local roleName = tostring(role.name)
        local permissions = decodePermissions(role.permissions)
        local normalizedPermissions = {}

        for permission, enabled in pairs(permissions) do
            if enabled then
                local normalized = normalizePermission(permission)
                if normalized then normalizedPermissions[normalized] = true end
            end
        end

        groupList[#groupList + 1] = {
            name = roleName,
            before = role.inherits ~= "" and role.inherits or Config.DefaultGroup
        }

        groupGrades[roleName] = {
            grade = tonumber(role.grade) or 0
        }

        rolePermissions[roleName] = normalizedPermissions

        if tonumber(role.high_perm) == 1 then
            highPerms[roleName] = true
        end

        rankList[#rankList + 1] = {
            rank = roleName,
            label = role.label or roleName,
            menuColor = role.menu_color or "~s~",
            can = tonumber(role.can_assign) == 1,
            gamertag_color = tonumber(role.gamertag_color) or 6,
            alwayscolored = tonumber(role.always_colored) == 1,
            star = tonumber(role.star) == 1
        }

        rankLabels[roleName] = role.label or roleName
        rankGamertags[roleName] = role.gamertag_label or ""
    end

    Config.Groupes = groupList
    Config.GroupeGrade = groupGrades
    Config.GroupeHighPerm = highPerms
    Config.Admin.RolePermissions = rolePermissions
    Config.Admin.RankList = rankList
    Config.Admin.RankListLabel = rankLabels
    Config.Admin.RankListGamerTag = rankGamertags

    if ESX and ESX.Groups then
        ESX.Groups = {}
        for _, group in ipairs(Config.Groupes) do
            ESX.AddGroup(group.name, group.before)
        end
    end
end

local function fetchRoles()
    return MySQL.query.await("SELECT * FROM `staff_roles` ORDER BY `grade` ASC, `name` ASC", {}) or {}
end

function ReloadStaffRoles()
    ensureTables()
    seedDefaultRoles()
    local rows = fetchRoles()
    applyRoles(rows)
    StaffRolesLoaded = true
    TriggerClientEvent("null:staffroles:sync", -1, GetStaffRolesPayload())
end

function GetStaffRolesPayload()
    return {
        roles = Config.Admin.RankList or {},
        grades = Config.GroupeGrade or {},
        highPerm = Config.GroupeHighPerm or {},
        rolePermissions = Config.Admin.RolePermissions or {},
        permissionDefaults = Config.Admin.PermissionsGrade or {},
        rankLabels = Config.Admin.RankListLabel or {},
        rankGamertags = Config.Admin.RankListGamerTag or {}
    }
end

local function isFounder(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    return xPlayer and xPlayer.getGroup and xPlayer.getGroup() == "fondateur"
end

local function sanitizeRoleName(value)
    local roleName = tostring(value or ""):lower():gsub("%s+", "")
    if roleName:match("^[%w_%-]+$") then
        return roleName
    end
end

local function refreshOnlinePlayers()
    for _, playerId in ipairs(ESX.GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            TriggerClientEvent("null:staffroles:sync", playerId, GetStaffRolesPayload())
            TriggerClientEvent("null:staff:recevieRequestGroup", playerId, {xPlayer.getGroup() ~= "user", xPlayer.getGroup()})
        end
    end
end

AddEventHandler("esx:playerLoaded", function(source)
    if StaffRolesLoaded then
        TriggerClientEvent("null:staffroles:sync", source, GetStaffRolesPayload())
    end
end)

AddEventHandler("null:staff:requestGroupVerif", function(target)
    local playerId = target or source
    if playerId and StaffRolesLoaded then
        TriggerClientEvent("null:staffroles:sync", playerId, GetStaffRolesPayload())
    end
end)

ESX.RegisterServerCallback("null:staffroles:get", function(source, cb)
    if not StaffRolesLoaded then ReloadStaffRoles() end
    cb(GetStaffRolesPayload())
end)

RegisterNetEvent("null:staffroles:create", function(data)
    local src = source
    if not isFounder(src) then return end
    data = data or {}

    local roleName = sanitizeRoleName(data.name)
    if not roleName or roleName == "user" then
        return TriggerClientEvent("esx:showNotification", src, "~r~Nom de rôle invalide")
    end

    if Config.GroupeGrade[roleName] then
        return TriggerClientEvent("esx:showNotification", src, "~r~Ce rôle existe déjà")
    end

    MySQL.Async.execute([[
        INSERT INTO `staff_roles`
            (`name`, `label`, `grade`, `inherits`, `menu_color`, `gamertag_color`, `gamertag_label`, `can_assign`, `high_perm`, `always_colored`, `star`, `permissions`)
        VALUES
            (@name, @label, @grade, @inherits, @menu_color, @gamertag_color, @gamertag_label, @can_assign, @high_perm, @always_colored, @star, @permissions)
    ]], {
        ["@name"] = roleName,
        ["@label"] = tostring(data.label or roleName),
        ["@grade"] = tonumber(data.grade) or 1,
        ["@inherits"] = tostring(data.inherits or "user"),
        ["@menu_color"] = tostring(data.menuColor or "~s~"),
        ["@gamertag_color"] = tonumber(data.gamertagColor) or 6,
        ["@gamertag_label"] = tostring(data.gamertagLabel or ""),
        ["@can_assign"] = data.canAssign == false and 0 or 1,
        ["@high_perm"] = data.highPerm and 1 or 0,
        ["@always_colored"] = data.alwaysColored and 1 or 0,
        ["@star"] = data.star and 1 or 0,
        ["@permissions"] = encodePermissions(data.permissions or {})
    }, function()
        ReloadStaffRoles()
        refreshOnlinePlayers()
        TriggerClientEvent("esx:showNotification", src, "~g~Rôle staff créé")
    end)
end)

RegisterNetEvent("null:staffroles:update", function(roleName, data)
    local src = source
    if not isFounder(src) then return end
    data = data or {}

    roleName = sanitizeRoleName(roleName)
    if not roleName or roleName == "user" then return end

    MySQL.Async.execute([[
        UPDATE `staff_roles`
        SET `label` = @label,
            `grade` = @grade,
            `inherits` = @inherits,
            `menu_color` = @menu_color,
            `gamertag_color` = @gamertag_color,
            `gamertag_label` = @gamertag_label,
            `can_assign` = @can_assign,
            `high_perm` = @high_perm,
            `always_colored` = @always_colored,
            `star` = @star,
            `permissions` = @permissions
        WHERE `name` = @name
    ]], {
        ["@name"] = roleName,
        ["@label"] = tostring(data.label or roleName),
        ["@grade"] = tonumber(data.grade) or 1,
        ["@inherits"] = tostring(data.inherits or "user"),
        ["@menu_color"] = tostring(data.menuColor or "~s~"),
        ["@gamertag_color"] = tonumber(data.gamertagColor) or 6,
        ["@gamertag_label"] = tostring(data.gamertagLabel or ""),
        ["@can_assign"] = data.canAssign == false and 0 or 1,
        ["@high_perm"] = data.highPerm and 1 or 0,
        ["@always_colored"] = data.alwaysColored and 1 or 0,
        ["@star"] = data.star and 1 or 0,
        ["@permissions"] = encodePermissions(data.permissions or {})
    }, function()
        ReloadStaffRoles()
        refreshOnlinePlayers()
        TriggerClientEvent("esx:showNotification", src, "~g~Rôle staff modifié")
    end)
end)

RegisterNetEvent("null:staffroles:delete", function(roleName)
    local src = source
    if not isFounder(src) then return end

    roleName = sanitizeRoleName(roleName)
    if not roleName or roleName == "user" or roleName == "fondateur" then
        return TriggerClientEvent("esx:showNotification", src, "~r~Ce rôle ne peut pas être supprimé")
    end

    MySQL.Async.execute("DELETE FROM `staff_roles` WHERE `name` = @name", {
        ["@name"] = roleName
    }, function()
        MySQL.Async.execute("UPDATE `users` SET `permission_group` = 'user' WHERE `permission_group` = @name", {
            ["@name"] = roleName
        })
        MySQL.Async.execute("DELETE FROM `staff` WHERE `permission_group` = @name", {
            ["@name"] = roleName
        })

        for _, playerId in ipairs(ESX.GetPlayers()) do
            local xPlayer = ESX.GetPlayerFromId(playerId)
            if xPlayer and xPlayer.getGroup() == roleName then
                xPlayer.setGroup("user")
            end
        end

        ReloadStaffRoles()
        refreshOnlinePlayers()
        ExecuteCommand("server staffs refresh")
        TriggerClientEvent("esx:showNotification", src, "~g~Rôle staff supprimé")
    end)
end)

Citizen.CreateThread(function()
    Wait(500)
    ReloadStaffRoles()
end)
