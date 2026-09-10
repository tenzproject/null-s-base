-- ============================================================================
-- CRIMENET - Server Main (Database, Profiles, Contacts, Callbacks)
-- ============================================================================

CrimeNetCache = {
    profiles = {},      -- [identifier] = { description, avatar_url }
    contacts = {},      -- [identifier] = { {contact_identifier, nickname, added_at}, ... }
    networkNodes = {},   -- [identifier] = { is_important, admin_label }
    gangBosses = {},     -- [gangname] = identifier (cached boss lookup)
    fakeProfiles = {},   -- [fake_id] = { name, gangname, is_boss, is_important, admin_label, description, avatar_url }
    gangInfo = {},       -- [identifier] = { gangname, gangLabel, is_boss } (persisted gang info for offline resolution)
}

-- ============================================================================
-- DATABASE INIT
-- ============================================================================
Citizen.CreateThread(function()
    Wait(2000)

    -- Player profiles (description + avatar)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `crimenet_profiles` (
            `identifier` VARCHAR(60) NOT NULL,
            `description` VARCHAR(250) DEFAULT '',
            `avatar_url` TEXT DEFAULT NULL,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    -- Player contacts (who you know)
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `crimenet_contacts` (
            `id` INT AUTO_INCREMENT,
            `owner` VARCHAR(60) NOT NULL,
            `contact` VARCHAR(60) NOT NULL,
            `nickname` VARCHAR(50) DEFAULT NULL,
            `added_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_contact` (`owner`, `contact`),
            INDEX `idx_owner` (`owner`),
            INDEX `idx_contact` (`contact`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    -- Direct messages
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `crimenet_messages` (
            `id` INT AUTO_INCREMENT,
            `from_id` VARCHAR(60) NOT NULL,
            `to_id` VARCHAR(60) NOT NULL,
            `content` VARCHAR(500) NOT NULL,
            `sent_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `read_at` DATETIME DEFAULT NULL,
            PRIMARY KEY (`id`),
            INDEX `idx_conversation` (`from_id`, `to_id`),
            INDEX `idx_to` (`to_id`, `sent_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    -- Group chats
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `crimenet_groups` (
            `id` INT AUTO_INCREMENT,
            `name` VARCHAR(60) NOT NULL,
            `creator` VARCHAR(60) NOT NULL,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    -- Group members
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `crimenet_group_members` (
            `group_id` INT NOT NULL,
            `identifier` VARCHAR(60) NOT NULL,
            `joined_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`group_id`, `identifier`),
            INDEX `idx_member` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    -- Group messages
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `crimenet_group_messages` (
            `id` INT AUTO_INCREMENT,
            `group_id` INT NOT NULL,
            `from_id` VARCHAR(60) NOT NULL,
            `content` VARCHAR(500) NOT NULL,
            `sent_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_group` (`group_id`, `sent_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    -- Add pseudonym column if not exists
    MySQL.Async.execute([[
        ALTER TABLE `crimenet_profiles` ADD COLUMN IF NOT EXISTS `pseudonym` VARCHAR(30) DEFAULT NULL AFTER `avatar_url`;
    ]], {})

    -- Add crimenet_id column if not exists
    MySQL.Async.execute([[
        ALTER TABLE `crimenet_profiles` ADD COLUMN IF NOT EXISTS `crimenet_id` VARCHAR(10) DEFAULT NULL AFTER `pseudonym`;
    ]], {})
    MySQL.Async.execute([[
        ALTER TABLE `crimenet_profiles` ADD UNIQUE INDEX IF NOT EXISTS `idx_crimenet_id` (`crimenet_id`);
    ]], {})

    -- Admin-marked important network nodes
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `crimenet_network_nodes` (
            `identifier` VARCHAR(60) NOT NULL,
            `is_important` TINYINT(1) NOT NULL DEFAULT 1,
            `admin_label` VARCHAR(60) DEFAULT NULL,
            `set_by` VARCHAR(60) DEFAULT NULL,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    -- Fake profiles for testing
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `crimenet_fake_profiles` (
            `fake_id` VARCHAR(60) NOT NULL,
            `name` VARCHAR(50) NOT NULL,
            `gangname` VARCHAR(50) DEFAULT NULL,
            `is_boss` TINYINT(1) NOT NULL DEFAULT 0,
            `is_important` TINYINT(1) NOT NULL DEFAULT 0,
            `admin_label` VARCHAR(60) DEFAULT NULL,
            `description` VARCHAR(250) DEFAULT '',
            `avatar_url` TEXT DEFAULT NULL,
            PRIMARY KEY (`fake_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    -- Add crimenet_id to fake profiles if not exists
    MySQL.Async.execute([[
        ALTER TABLE `crimenet_fake_profiles` ADD COLUMN IF NOT EXISTS `crimenet_id` VARCHAR(10) DEFAULT NULL AFTER `avatar_url`;
    ]], {})

    -- Marketplace listings
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `crimenet_marketplace` (
            `id` INT AUTO_INCREMENT,
            `seller` VARCHAR(60) NOT NULL,
            `category` VARCHAR(20) NOT NULL DEFAULT 'items',
            `title` VARCHAR(60) NOT NULL,
            `description` VARCHAR(300) DEFAULT '',
            `price` INT NOT NULL DEFAULT 0,
            `photos` TEXT DEFAULT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'active',
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_seller` (`seller`),
            INDEX `idx_status` (`status`),
            INDEX `idx_category` (`category`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    -- Contracts system
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `crimenet_contracts` (
            `id` INT AUTO_INCREMENT,
            `contract_id` VARCHAR(32) NOT NULL UNIQUE,
            `type` VARCHAR(10) NOT NULL DEFAULT 'solo',
            `label` VARCHAR(60) NOT NULL,
            `description` VARCHAR(200) DEFAULT '',
            `vehicle_model` VARCHAR(30) DEFAULT '',
            `vehicle_label` VARCHAR(30) DEFAULT '',
            `cargo_estimate` VARCHAR(30) DEFAULT '',
            `revenue` INT NOT NULL DEFAULT 0,
            `xp_reward` INT NOT NULL DEFAULT 0,
            `min_xp` INT NOT NULL DEFAULT 0,
            `difficulty` INT NOT NULL DEFAULT 1,
            `crew_min` INT DEFAULT NULL,
            `crew_max` INT DEFAULT NULL,
            `deadline` INT NOT NULL DEFAULT 30,
            `fixed_time` VARCHAR(10) DEFAULT NULL,
            `status` VARCHAR(20) NOT NULL DEFAULT 'available',
            `accepted_by` VARCHAR(60) DEFAULT NULL,
            `accepted_at` DATETIME DEFAULT NULL,
            `expires_at` DATETIME NOT NULL,
            `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            INDEX `idx_contract_id` (`contract_id`),
            INDEX `idx_status` (`status`),
            INDEX `idx_type` (`type`),
            INDEX `idx_min_xp` (`min_xp`),
            INDEX `idx_expires` (`expires_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    -- Player active contract tracking
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `crimenet_player_contracts` (
            `id` INT AUTO_INCREMENT,
            `identifier` VARCHAR(60) NOT NULL,
            `contract_id` VARCHAR(32) NOT NULL,
            `accepted_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
            `must_complete_by` DATETIME NOT NULL,
            `is_crew` TINYINT(1) DEFAULT 0,
            `crew_members` TEXT DEFAULT NULL,
            `status` VARCHAR(20) DEFAULT 'active',
            `completed_at` DATETIME DEFAULT NULL,
            `failed_at` DATETIME DEFAULT NULL,
            `fail_reason` VARCHAR(50) DEFAULT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `idx_player_active` (`identifier`, `status`),
            INDEX `idx_contract` (`contract_id`),
            INDEX `idx_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    -- Load caches
    Wait(1000)
    LoadNetworkNodes()
    LoadFakeProfiles()

    print("[CrimeNet] Database initialized")
end)

-- ============================================================================
-- CACHE LOADERS
-- ============================================================================
function LoadNetworkNodes()
    MySQL.Async.fetchAll("SELECT * FROM `crimenet_network_nodes`", {}, function(results)
        CrimeNetCache.networkNodes = {}
        for _, row in ipairs(results or {}) do
            CrimeNetCache.networkNodes[row.identifier] = {
                is_important = row.is_important == 1 or row.is_important == true,
                admin_label = row.admin_label,
            }
        end
    end)
end

function LoadFakeProfiles()
    MySQL.Async.fetchAll("SELECT * FROM `crimenet_fake_profiles`", {}, function(results)
        CrimeNetCache.fakeProfiles = {}
        for _, row in ipairs(results or {}) do
            local cid = row.crimenet_id
            if not cid then
                cid = CrimeNet.GenerateId()
                MySQL.Async.execute("UPDATE `crimenet_fake_profiles` SET crimenet_id = @cid WHERE fake_id = @id", {
                    ['@id'] = row.fake_id, ['@cid'] = cid
                })
            end
            CrimeNetCache.fakeProfiles[row.fake_id] = {
                name = row.name,
                gangname = row.gangname,
                is_boss = row.is_boss == 1 or row.is_boss == true,
                is_important = row.is_important == 1 or row.is_important == true,
                admin_label = row.admin_label,
                description = row.description or "",
                avatar_url = row.avatar_url,
                crimenet_id = cid,
            }
        end
    end)
end

-- ============================================================================
-- PROFANITY FILTER
-- ============================================================================
local BLOCKED_WORDS = {
    "pute", "putain", "salope", "connard", "connasse", "enculé", "enculer",
    "nique", "ntm", "fdp", "fils de pute", "pd", "tapette", "tarlouze",
    "bâtard", "batard", "merde", "bite", "couille", "branleur", "branleuse",
    "negro", "negre", "nègre", "bougnoule", "youpin", "feuj",
    "admin", "superadmin", "fondateur", "staff", "moderateur", "modérateur",
    "nigger", "nigga", "faggot", "retard",
    "hitler", "nazi", "isis", "daesh",
}

function CrimeNet.IsNameClean(name)
    if not name or #name < 2 or #name > 24 then return false, "LENGTH" end
    -- Only allow letters, numbers, spaces, hyphens, underscores
    if not string.match(name, "^[%w%s%-_àâäéèêëïîôùûüÿçœæÀÂÄÉÈÊËÏÎÔÙÛÜŸÇŒÆ]+$") then return false, "INVALID_CHARS" end
    local lower = string.lower(name)
    for _, word in ipairs(BLOCKED_WORDS) do
        if string.find(lower, word, 1, true) then return false, "PROFANITY" end
    end
    return true
end

-- ============================================================================
-- PROFILE HELPERS
-- ============================================================================
function CrimeNet.GetProfile(identifier, cb)
    if CrimeNetCache.profiles[identifier] then
        cb(CrimeNetCache.profiles[identifier])
        return
    end

    MySQL.Async.fetchAll("SELECT * FROM `crimenet_profiles` WHERE identifier = @id", {
        ['@id'] = identifier
    }, function(result)
        if result and result[1] then
            local p = { description = result[1].description or "", avatar_url = result[1].avatar_url, pseudonym = result[1].pseudonym, crimenet_id = result[1].crimenet_id }
            -- Auto-generate crimenet_id if missing
            if not p.crimenet_id then
                p.crimenet_id = CrimeNet.GenerateId()
                MySQL.Async.execute("UPDATE `crimenet_profiles` SET crimenet_id = @cid WHERE identifier = @id", {
                    ['@id'] = identifier, ['@cid'] = p.crimenet_id
                })
            end
            CrimeNetCache.profiles[identifier] = p
            cb(p)
        else
            local cid = CrimeNet.GenerateId()
            MySQL.Async.execute("INSERT IGNORE INTO `crimenet_profiles` (identifier, crimenet_id) VALUES (@id, @cid)", {
                ['@id'] = identifier, ['@cid'] = cid
            })
            local p = { description = "", avatar_url = nil, pseudonym = nil, crimenet_id = cid }
            CrimeNetCache.profiles[identifier] = p
            cb(p)
        end
    end)
end

-- Generate a unique CrimeNet ID like CN-XXXX
function CrimeNet.GenerateId()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = "CN-"
    for _ = 1, 5 do
        local idx = math.random(1, #chars)
        id = id .. string.sub(chars, idx, idx)
    end
    return id
end

function CrimeNet.UpdateProfile(identifier, fields)
    local sets = {}
    local params = { ['@id'] = identifier }

    if fields.description ~= nil then
        local desc = string.sub(fields.description, 1, CrimeNet.Config.Network.maxDescriptionLength)
        table.insert(sets, "description = @desc")
        params['@desc'] = desc
        if CrimeNetCache.profiles[identifier] then CrimeNetCache.profiles[identifier].description = desc end
    end
    if fields.avatar_url ~= nil then
        local url = fields.avatar_url
        -- If it's a table/object (from photo picker), extract the src field
        if type(url) == "table" then
            url = url.src or url.url or nil
        end
        if type(url) == "string" then
            table.insert(sets, "avatar_url = @avatar")
            params['@avatar'] = url
            if CrimeNetCache.profiles[identifier] then CrimeNetCache.profiles[identifier].avatar_url = url end
        end
    end
    if fields.pseudonym ~= nil then
        local name = string.sub(fields.pseudonym, 1, 24)
        table.insert(sets, "pseudonym = @pseudo")
        params['@pseudo'] = name
        if CrimeNetCache.profiles[identifier] then CrimeNetCache.profiles[identifier].pseudonym = name end
    end

    if #sets == 0 then return end

    MySQL.Async.execute("UPDATE `crimenet_profiles` SET " .. table.concat(sets, ", ") .. " WHERE identifier = @id", params)
end

-- ============================================================================
-- CONTACT HELPERS
-- ============================================================================
function CrimeNet.GetContacts(identifier, cb)
    MySQL.Async.fetchAll([[
        SELECT c.contact, c.nickname, c.added_at,
               COALESCE(p.description, '') as description,
               p.avatar_url
        FROM crimenet_contacts c
        LEFT JOIN crimenet_profiles p ON p.identifier = c.contact
        WHERE c.owner = @id
        ORDER BY c.added_at DESC
    ]], { ['@id'] = identifier }, function(results)
        local contacts = {}
        for _, row in ipairs(results or {}) do
            table.insert(contacts, {
                identifier = row.contact,
                nickname = row.nickname,
                added_at = row.added_at,
                description = row.description,
                avatar_url = row.avatar_url,
            })
        end
        cb(contacts)
    end)
end

function CrimeNet.AddContact(owner, contactId, nickname, cb)
    -- Check max contacts
    MySQL.Async.fetchScalar("SELECT COUNT(*) FROM `crimenet_contacts` WHERE owner = @id", {
        ['@id'] = owner
    }, function(count)
        if count >= CrimeNet.Config.Network.maxContacts then
            cb(false, "MAX_CONTACTS")
            return
        end

        -- Can't add yourself
        if owner == contactId then
            cb(false, "SELF_ADD")
            return
        end

        MySQL.Async.execute("INSERT IGNORE INTO `crimenet_contacts` (owner, contact, nickname) VALUES (@owner, @contact, @nick)", {
            ['@owner'] = owner,
            ['@contact'] = contactId,
            ['@nick'] = nickname,
        }, function(rowsChanged)
            if rowsChanged > 0 then
                -- Ensure profile exists for contact
                MySQL.Async.execute("INSERT IGNORE INTO `crimenet_profiles` (identifier) VALUES (@id)", {
                    ['@id'] = contactId
                })
                cb(true)
            else
                cb(false, "ALREADY_CONTACT")
            end
        end)
    end)
end

function CrimeNet.RemoveContact(owner, contactId, cb)
    MySQL.Async.execute("DELETE FROM `crimenet_contacts` WHERE owner = @owner AND contact = @contact", {
        ['@owner'] = owner,
        ['@contact'] = contactId,
    }, function(rowsChanged)
        cb(rowsChanged > 0)
    end)
end

function CrimeNet.ShareContact(owner, contactToShare, targetPlayer, cb)
    -- Check that owner has this contact
    MySQL.Async.fetchScalar("SELECT COUNT(*) FROM `crimenet_contacts` WHERE owner = @owner AND contact = @contact", {
        ['@owner'] = owner,
        ['@contact'] = contactToShare,
    }, function(count)
        if count == 0 then
            cb(false, "NOT_YOUR_CONTACT")
            return
        end
        -- Add contact to target player
        CrimeNet.AddContact(targetPlayer, contactToShare, nil, cb)
    end)
end

-- ============================================================================
-- MESSAGE HELPERS
-- ============================================================================
function CrimeNet.SendMessage(fromId, toId, content, cb)
    local msg = string.sub(content, 1, CrimeNet.Config.Network.maxMessageLength)

    MySQL.Async.insert("INSERT INTO `crimenet_messages` (from_id, to_id, content) VALUES (@from, @to, @content)", {
        ['@from'] = fromId,
        ['@to'] = toId,
        ['@content'] = msg,
    }, function(insertId)
        cb(insertId > 0, insertId)
    end)
end

function CrimeNet.GetConversation(identifier, otherIdentifier, page, cb)
    local limit = CrimeNet.Config.Network.messagesPerPage
    local offset = (page - 1) * limit

    MySQL.Async.fetchAll([[
        SELECT id, from_id, to_id, content, sent_at, read_at
        FROM crimenet_messages
        WHERE (from_id = @me AND to_id = @other) OR (from_id = @other AND to_id = @me)
        ORDER BY sent_at DESC
        LIMIT @limit OFFSET @offset
    ]], {
        ['@me'] = identifier,
        ['@other'] = otherIdentifier,
        ['@limit'] = limit,
        ['@offset'] = offset,
    }, function(results)
        -- Mark unread messages as read
        MySQL.Async.execute([[
            UPDATE crimenet_messages SET read_at = NOW()
            WHERE from_id = @other AND to_id = @me AND read_at IS NULL
        ]], { ['@me'] = identifier, ['@other'] = otherIdentifier })

        cb(results or {})
    end)
end

function CrimeNet.GetRecentConversations(identifier, cb)
    local limit = CrimeNet.Config.Network.recentConversations

    MySQL.Async.fetchAll([[
        SELECT m.*, 
               CASE WHEN m.from_id = @me THEN m.to_id ELSE m.from_id END as other_id
        FROM crimenet_messages m
        INNER JOIN (
            SELECT 
                CASE WHEN from_id = @me THEN to_id ELSE from_id END as partner,
                MAX(id) as max_id
            FROM crimenet_messages
            WHERE from_id = @me OR to_id = @me
            GROUP BY partner
            ORDER BY max_id DESC
            LIMIT @limit
        ) latest ON m.id = latest.max_id
        ORDER BY m.sent_at DESC
    ]], {
        ['@me'] = identifier,
        ['@limit'] = limit,
    }, function(results)
        -- Count unread per conversation
        MySQL.Async.fetchAll([[
            SELECT from_id, COUNT(*) as unread
            FROM crimenet_messages
            WHERE to_id = @me AND read_at IS NULL
            GROUP BY from_id
        ]], { ['@me'] = identifier }, function(unreadResults)
            local unreadMap = {}
            for _, r in ipairs(unreadResults or {}) do
                unreadMap[r.from_id] = r.unread
            end

            local conversations = {}
            for _, row in ipairs(results or {}) do
                table.insert(conversations, {
                    other_id = row.other_id,
                    last_message = row.content,
                    last_sent_at = row.sent_at,
                    is_mine = row.from_id == identifier,
                    unread = unreadMap[row.other_id] or 0,
                })
            end
            cb(conversations)
        end)
    end)
end

-- ============================================================================
-- GROUP CHAT HELPERS
-- ============================================================================
function CrimeNet.CreateGroup(creatorId, name, memberIds, cb)
    -- Check max groups
    MySQL.Async.fetchScalar("SELECT COUNT(*) FROM `crimenet_group_members` WHERE identifier = @id", {
        ['@id'] = creatorId
    }, function(count)
        if count >= CrimeNet.Config.Network.maxGroups then
            cb(false, "MAX_GROUPS")
            return
        end

        MySQL.Async.insert("INSERT INTO `crimenet_groups` (name, creator) VALUES (@name, @creator)", {
            ['@name'] = string.sub(name, 1, 60),
            ['@creator'] = creatorId,
        }, function(groupId)
            if groupId <= 0 then cb(false, "CREATE_FAILED") return end

            -- Add creator + members
            local allMembers = { creatorId }
            for _, mid in ipairs(memberIds or {}) do
                if mid ~= creatorId then
                    table.insert(allMembers, mid)
                end
            end

            -- Cap at max
            local max = CrimeNet.Config.Network.maxGroupMembers
            if #allMembers > max then
                for i = max + 1, #allMembers do allMembers[i] = nil end
            end

            for _, mid in ipairs(allMembers) do
                MySQL.Async.execute("INSERT IGNORE INTO `crimenet_group_members` (group_id, identifier) VALUES (@gid, @mid)", {
                    ['@gid'] = groupId, ['@mid'] = mid,
                })
            end

            cb(true, groupId)
        end)
    end)
end

function CrimeNet.GetGroups(identifier, cb)
    MySQL.Async.fetchAll([[
        SELECT g.id, g.name, g.creator, g.created_at,
               (SELECT COUNT(*) FROM crimenet_group_members WHERE group_id = g.id) as member_count
        FROM crimenet_groups g
        INNER JOIN crimenet_group_members gm ON gm.group_id = g.id
        WHERE gm.identifier = @id
        ORDER BY g.created_at DESC
    ]], { ['@id'] = identifier }, function(results)
        cb(results or {})
    end)
end

function CrimeNet.SendGroupMessage(groupId, fromId, content, cb)
    local msg = string.sub(content, 1, CrimeNet.Config.Network.maxMessageLength)

    -- Verify membership
    MySQL.Async.fetchScalar("SELECT COUNT(*) FROM `crimenet_group_members` WHERE group_id = @gid AND identifier = @id", {
        ['@gid'] = groupId, ['@id'] = fromId,
    }, function(count)
        if count == 0 then cb(false, "NOT_MEMBER") return end

        MySQL.Async.insert("INSERT INTO `crimenet_group_messages` (group_id, from_id, content) VALUES (@gid, @from, @content)", {
            ['@gid'] = groupId, ['@from'] = fromId, ['@content'] = msg,
        }, function(insertId)
            cb(insertId > 0, insertId)
        end)
    end)
end

function CrimeNet.GetGroupMessages(groupId, identifier, page, cb)
    local limit = CrimeNet.Config.Network.messagesPerPage
    local offset = (page - 1) * limit

    -- Verify membership
    MySQL.Async.fetchScalar("SELECT COUNT(*) FROM `crimenet_group_members` WHERE group_id = @gid AND identifier = @id", {
        ['@gid'] = groupId, ['@id'] = identifier,
    }, function(count)
        if count == 0 then cb({}) return end

        MySQL.Async.fetchAll([[
            SELECT id, from_id, content, sent_at
            FROM crimenet_group_messages
            WHERE group_id = @gid
            ORDER BY sent_at DESC
            LIMIT @limit OFFSET @offset
        ]], {
            ['@gid'] = groupId,
            ['@limit'] = limit,
            ['@offset'] = offset,
        }, function(results)
            cb(results or {})
        end)
    end)
end

function CrimeNet.GetGroupMembers(groupId, cb)
    MySQL.Async.fetchAll([[
        SELECT gm.identifier, gm.joined_at, COALESCE(p.description, '') as description, p.avatar_url
        FROM crimenet_group_members gm
        LEFT JOIN crimenet_profiles p ON p.identifier = gm.identifier
        WHERE gm.group_id = @gid
    ]], { ['@gid'] = groupId }, function(results)
        cb(results or {})
    end)
end

function CrimeNet.AddGroupMember(groupId, identifier, addedBy, cb)
    -- Check membership of adder
    MySQL.Async.fetchScalar("SELECT COUNT(*) FROM `crimenet_group_members` WHERE group_id = @gid AND identifier = @id", {
        ['@gid'] = groupId, ['@id'] = addedBy,
    }, function(count)
        if count == 0 then cb(false, "NOT_MEMBER") return end

        -- Check max members
        MySQL.Async.fetchScalar("SELECT COUNT(*) FROM `crimenet_group_members` WHERE group_id = @gid", {
            ['@gid'] = groupId,
        }, function(memberCount)
            if memberCount >= CrimeNet.Config.Network.maxGroupMembers then
                cb(false, "MAX_MEMBERS")
                return
            end

            MySQL.Async.execute("INSERT IGNORE INTO `crimenet_group_members` (group_id, identifier) VALUES (@gid, @mid)", {
                ['@gid'] = groupId, ['@mid'] = identifier,
            }, function(rowsChanged)
                cb(rowsChanged > 0)
            end)
        end)
    end)
end

function CrimeNet.LeaveGroup(groupId, identifier, cb)
    MySQL.Async.execute("DELETE FROM `crimenet_group_members` WHERE group_id = @gid AND identifier = @id", {
        ['@gid'] = groupId, ['@id'] = identifier,
    }, function(rowsChanged)
        cb(rowsChanged > 0)
    end)
end

-- ============================================================================
-- PLAYER INFO RESOLVER (real + fake players)
-- ============================================================================
function CrimeNet.ResolvePlayerInfo(identifier)
    -- Check if it's a fake profile
    if CrimeNetCache.fakeProfiles[identifier] then
        local fake = CrimeNetCache.fakeProfiles[identifier]
        return {
            identifier = identifier,
            name = fake.name,
            gangname = fake.gangname,
            is_boss = fake.is_boss,
            is_important = fake.is_important,
            admin_label = fake.admin_label,
            description = fake.description,
            avatar_url = fake.avatar_url,
            online = false,
            is_fake = true,
        }
    end

    -- Real player
    local info = {
        identifier = identifier,
        name = nil,
        gangname = nil,
        gangLabel = nil,
        is_boss = false,
        is_important = false,
        admin_label = nil,
        description = "",
        avatar_url = nil,
        online = false,
        is_fake = false,
    }

    -- Check if online
    local xPlayers = ESX.GetPlayers()
    for _, pid in ipairs(xPlayers) do
        local xP = ESX.GetPlayerFromId(pid)
        if xP and xP.identifier == identifier then
            info.online = true
            info.name = xP.getName()
            local job2 = xP.getJob2()
            if job2 and job2.name ~= "unemployed" and job2.name ~= "unemployed2" then
                info.gangname = job2.name
                info.gangLabel = job2.label
                -- Check if boss
                if job2.grade_name then
                    for _, bossName in ipairs(CrimeNet.Config.Graph.bossGradeNames) do
                        if string.lower(job2.grade_name) == bossName then
                            info.is_boss = true
                            break
                        end
                    end
                end
                if not info.is_boss and job2.grade and job2.grade >= CrimeNet.Config.Graph.bossMinGrade then
                    info.is_boss = true
                end
            end
            break
        end
    end

    -- If not online, try cached gang info
    if not info.online and CrimeNetCache.gangInfo and CrimeNetCache.gangInfo[identifier] then
        local cached = CrimeNetCache.gangInfo[identifier]
        info.gangname = cached.gangname
        info.gangLabel = cached.gangLabel
        info.is_boss = cached.is_boss
    end

    -- If not online, try to get name from DB
    if not info.name then
        -- We'll resolve this asynchronously in the network builder
        info.name = "Hors ligne"
    end

    -- Check admin-marked important
    if CrimeNetCache.networkNodes[identifier] then
        info.is_important = CrimeNetCache.networkNodes[identifier].is_important
        info.admin_label = CrimeNetCache.networkNodes[identifier].admin_label
    end

    -- Profile cache
    if CrimeNetCache.profiles[identifier] then
        info.description = CrimeNetCache.profiles[identifier].description or ""
        info.avatar_url = CrimeNetCache.profiles[identifier].avatar_url
    end

    return info
end

-- ============================================================================
-- GANG BOSS RESOLVER
-- ============================================================================
function CrimeNet.FindGangBoss(gangname, contactIdentifiers)
    -- First, check if any contact in this gang is a boss
    for _, cid in ipairs(contactIdentifiers) do
        local info = CrimeNet.ResolvePlayerInfo(cid)
        if info.gangname == gangname and info.is_boss then
            return cid
        end
    end
    return nil
end

-- ============================================================================
-- ASYNC PLAYER NAME RESOLVER (for offline players)
-- ============================================================================
function CrimeNet.ResolvePlayerNames(identifiers, cb)
    if #identifiers == 0 then cb({}) return end

    -- Build IN clause
    local placeholders = {}
    local params = {}
    for i, id in ipairs(identifiers) do
        local key = '@id' .. i
        table.insert(placeholders, key)
        params[key] = id
    end

    MySQL.Async.fetchAll(
        "SELECT identifier, CONCAT(firstname, ' ', lastname) as name FROM users WHERE identifier IN (" .. table.concat(placeholders, ",") .. ")",
        params,
        function(results)
            local map = {}
            for _, row in ipairs(results or {}) do
                map[row.identifier] = row.name
            end
            cb(map)
        end
    )
end

-- ============================================================================
-- ASYNC OFFLINE GANG INFO RESOLVER (queries users table for job2 data)
-- ============================================================================
function CrimeNet.ResolveOfflineGangInfo(identifiers, cb)
    if #identifiers == 0 then cb() return end

    -- Filter to only identifiers not already cached and not online
    local toResolve = {}
    local onlineSet = {}
    local xPlayers = ESX.GetPlayers()
    for _, pid in ipairs(xPlayers) do
        local xP = ESX.GetPlayerFromId(pid)
        if xP then onlineSet[xP.identifier] = true end
    end

    for _, id in ipairs(identifiers) do
        if not onlineSet[id] and not CrimeNetCache.gangInfo[id] and not CrimeNetCache.fakeProfiles[id] and not string.find(id, "^fake:") then
            table.insert(toResolve, id)
        end
    end

    if #toResolve == 0 then cb() return end

    local placeholders = {}
    local params = {}
    for i, id in ipairs(toResolve) do
        local key = '@id' .. i
        table.insert(placeholders, key)
        params[key] = id
    end

    MySQL.Async.fetchAll(
        "SELECT identifier, job2, job2_grade FROM users WHERE identifier IN (" .. table.concat(placeholders, ",") .. ")",
        params,
        function(results)
            for _, row in ipairs(results or {}) do
                local gangname = row.job2
                if gangname and gangname ~= "" and gangname ~= "unemployed" and gangname ~= "unemployed2" then
                    -- Resolve label from jobs table or use gangname
                    local gangLabel = gangname
                    local is_boss = false
                    local grade = tonumber(row.job2_grade) or 0

                    -- Check boss by grade
                    if grade >= CrimeNet.Config.Graph.bossMinGrade then
                        is_boss = true
                    end

                    CrimeNetCache.gangInfo[row.identifier] = {
                        gangname = gangname,
                        gangLabel = gangLabel,
                        is_boss = is_boss,
                    }
                end
            end

            -- Try to resolve gang labels
            local gangNames = {}
            local gangSet = {}
            for _, gi in pairs(CrimeNetCache.gangInfo) do
                if gi.gangname and not gangSet[gi.gangname] then
                    gangSet[gi.gangname] = true
                    table.insert(gangNames, gi.gangname)
                end
            end

            if #gangNames > 0 then
                local gPlaceholders = {}
                local gParams = {}
                for i, gn in ipairs(gangNames) do
                    local key = '@g' .. i
                    table.insert(gPlaceholders, key)
                    gParams[key] = gn
                end
                MySQL.Async.fetchAll(
                    "SELECT name, label FROM jobs WHERE name IN (" .. table.concat(gPlaceholders, ",") .. ")",
                    gParams,
                    function(jobResults)
                        local labelMap = {}
                        for _, jr in ipairs(jobResults or {}) do
                            labelMap[jr.name] = jr.label
                        end
                        -- Update cached gang labels
                        for _, gi in pairs(CrimeNetCache.gangInfo) do
                            if gi.gangname and labelMap[gi.gangname] then
                                gi.gangLabel = labelMap[gi.gangname]
                            end
                        end
                        cb()
                    end
                )
            else
                cb()
            end
        end
    )
end

-- ============================================================================
-- MAIN DATA CALLBACK (replaces old GoFast-only callback)
-- ============================================================================
ESX.RegisterServerCallback("CrimeNet:getData", function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb(nil) return end

    local identifier = xPlayer.identifier

    -- Ensure profile exists
    CrimeNet.GetProfile(identifier, function(profile)
        -- Get contacts
        CrimeNet.GetContacts(identifier, function(contacts)
            -- Get recent conversations
            CrimeNet.GetRecentConversations(identifier, function(conversations)
                -- Get groups
                CrimeNet.GetGroups(identifier, function(groups)
                    -- Resolve player names for contacts
                    local contactIds = {}
                    for _, c in ipairs(contacts) do
                        table.insert(contactIds, c.identifier)
                    end

                    -- Add fake profile contacts
                    for fakeId, _ in pairs(CrimeNetCache.fakeProfiles) do
                        -- Check if this fake is in the player's contacts
                        for _, c in ipairs(contacts) do
                            if c.identifier == fakeId then
                                break
                            end
                        end
                    end

                    CrimeNet.ResolvePlayerNames(contactIds, function(nameMap)
                        -- Resolve gang info for offline contacts from DB
                        CrimeNet.ResolveOfflineGangInfo(contactIds, function()
                        -- Build contact list with resolved info
                        local resolvedContacts = {}
                        for _, c in ipairs(contacts) do
                            local info = CrimeNet.ResolvePlayerInfo(c.identifier)
                            if not info.online and nameMap[c.identifier] then
                                info.name = nameMap[c.identifier]
                            end
                            -- Cache gang info from online players for future offline lookups
                            if info.online and info.gangname then
                                CrimeNetCache.gangInfo[c.identifier] = {
                                    gangname = info.gangname,
                                    gangLabel = info.gangLabel,
                                    is_boss = info.is_boss,
                                }
                            end
                            table.insert(resolvedContacts, {
                                identifier = c.identifier,
                                name = c.nickname or info.name or "Inconnu",
                                nickname = c.nickname,
                                realName = info.name,
                                gangname = info.gangname,
                                gangLabel = info.gangLabel,
                                is_boss = info.is_boss,
                                is_important = info.is_important,
                                admin_label = info.admin_label,
                                description = info.description or c.description,
                                avatar_url = info.avatar_url or c.avatar_url,
                                online = info.online,
                                is_fake = info.is_fake,
                                added_at = c.added_at,
                            })
                        end

                        -- Build conversation list with names
                        local resolvedConversations = {}
                        for _, conv in ipairs(conversations) do
                            local cInfo = CrimeNet.ResolvePlayerInfo(conv.other_id)
                            if not cInfo.online and nameMap[conv.other_id] then
                                cInfo.name = nameMap[conv.other_id]
                            end
                            -- Try to find nickname from contacts
                            local nick = nil
                            for _, c in ipairs(contacts) do
                                if c.identifier == conv.other_id and c.nickname then
                                    nick = c.nickname
                                    break
                                end
                            end
                            table.insert(resolvedConversations, {
                                other_id = conv.other_id,
                                name = nick or cInfo.name or "Inconnu",
                                avatar_url = cInfo.avatar_url,
                                online = cInfo.online,
                                last_message = conv.last_message,
                                last_sent_at = conv.last_sent_at,
                                is_mine = conv.is_mine,
                                unread = conv.unread,
                            })
                        end

                        -- Build network graph (fetch GoFast XP for NPC contact unlock status)
                        local function buildAndSend(goFastInfo)
                            local networkData = CrimeNet.BuildNetworkGraph(identifier, resolvedContacts, goFastInfo)

                            -- Fetch marketplace listings
                            CrimeNet.GetMarketListings(identifier, function(marketplace)
                                cb({
                                    profile = {
                                        identifier = identifier,
                                        name = profile.pseudonym or xPlayer.getName(),
                                        pseudonym = profile.pseudonym,
                                        crimenet_id = profile.crimenet_id,
                                        description = profile.description,
                                        avatar_url = profile.avatar_url,
                                    },
                                    contacts = resolvedContacts,
                                    conversations = resolvedConversations,
                                    groups = groups,
                                    network = networkData,
                                    marketplace = marketplace,
                                })
                            end)
                        end -- end buildAndSend

                        -- Fetch GoFast XP for NPC contact unlock status
                        local ok, _ = pcall(function()
                            exports["null-core"]:GoFast_GetReputation(identifier, function(rep)
                                buildAndSend(rep)
                            end)
                        end)
                        if not ok then
                            buildAndSend(nil)
                        end

                        end) -- end ResolveOfflineGangInfo
                    end) -- end ResolvePlayerNames
                end) -- end GetGroups
            end) -- end GetRecentConversations
        end) -- end GetContacts
    end) -- end GetProfile
end)

-- ============================================================================
-- CONTACT MANAGEMENT CALLBACKS
-- ============================================================================
ESX.RegisterServerCallback("CrimeNet:addContact", function(src, cb, contactIdentifier, nickname)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb(false, "NO_PLAYER") return end

    CrimeNet.AddContact(xPlayer.identifier, contactIdentifier, nickname, function(success, err)
        cb(success, err)
    end)
end)

ESX.RegisterServerCallback("CrimeNet:removeContact", function(src, cb, contactIdentifier)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb(false) return end

    CrimeNet.RemoveContact(xPlayer.identifier, contactIdentifier, function(success)
        cb(success)
    end)
end)

ESX.RegisterServerCallback("CrimeNet:shareContact", function(src, cb, contactToShare, targetServerId)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb(false) return end

    local targetPlayer = ESX.GetPlayerFromId(targetServerId)
    if not targetPlayer then cb(false, "TARGET_NOT_FOUND") return end

    CrimeNet.ShareContact(xPlayer.identifier, contactToShare, targetPlayer.identifier, function(success, err)
        if success then
            -- Notify target player
            TriggerClientEvent("CrimeNet:contactShared", targetServerId, {
                from = xPlayer.getName(),
                contact = contactToShare,
            })
        end
        cb(success, err)
    end)
end)

-- ============================================================================
-- MESSAGE CALLBACKS
-- ============================================================================
ESX.RegisterServerCallback("CrimeNet:sendMessage", function(src, cb, toIdentifier, content)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb(false) return end

    CrimeNet.SendMessage(xPlayer.identifier, toIdentifier, content, function(success, msgId)
        if success then
            -- Find target player if online and notify
            local xPlayers = ESX.GetPlayers()
            for _, pid in ipairs(xPlayers) do
                local xP = ESX.GetPlayerFromId(pid)
                if xP and xP.identifier == toIdentifier then
                    TriggerClientEvent("CrimeNet:newMessage", pid, {
                        id = msgId,
                        from_id = xPlayer.identifier,
                        from_name = xPlayer.getName(),
                        content = content,
                    })
                    break
                end
            end
        end
        cb(success, msgId)
    end)
end)

ESX.RegisterServerCallback("CrimeNet:getConversation", function(src, cb, otherIdentifier, page)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb({}) return end

    CrimeNet.GetConversation(xPlayer.identifier, otherIdentifier, page or 1, function(messages)
        cb(messages)
    end)
end)

-- ============================================================================
-- GROUP CALLBACKS
-- ============================================================================
ESX.RegisterServerCallback("CrimeNet:createGroup", function(src, cb, name, memberIdentifiers)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb(false) return end

    CrimeNet.CreateGroup(xPlayer.identifier, name, memberIdentifiers, function(success, groupIdOrErr)
        cb(success, groupIdOrErr)
    end)
end)

ESX.RegisterServerCallback("CrimeNet:sendGroupMessage", function(src, cb, groupId, content)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb(false) return end

    CrimeNet.SendGroupMessage(groupId, xPlayer.identifier, content, function(success, msgId)
        if success then
            -- Notify all group members who are online
            CrimeNet.GetGroupMembers(groupId, function(members)
                for _, member in ipairs(members) do
                    if member.identifier ~= xPlayer.identifier then
                        local xPlayers = ESX.GetPlayers()
                        for _, pid in ipairs(xPlayers) do
                            local xP = ESX.GetPlayerFromId(pid)
                            if xP and xP.identifier == member.identifier then
                                TriggerClientEvent("CrimeNet:newGroupMessage", pid, {
                                    group_id = groupId,
                                    id = msgId,
                                    from_id = xPlayer.identifier,
                                    from_name = xPlayer.getName(),
                                    content = content,
                                })
                                break
                            end
                        end
                    end
                end
            end)
        end
        cb(success, msgId)
    end)
end)

ESX.RegisterServerCallback("CrimeNet:getGroupMessages", function(src, cb, groupId, page)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb({}) return end

    CrimeNet.GetGroupMessages(groupId, xPlayer.identifier, page or 1, function(messages)
        cb(messages)
    end)
end)

ESX.RegisterServerCallback("CrimeNet:getGroupMembers", function(src, cb, groupId)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb({}) return end

    CrimeNet.GetGroupMembers(groupId, function(members)
        cb(members)
    end)
end)

ESX.RegisterServerCallback("CrimeNet:addGroupMember", function(src, cb, groupId, memberIdentifier)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb(false) return end

    CrimeNet.AddGroupMember(groupId, memberIdentifier, xPlayer.identifier, function(success, err)
        cb(success, err)
    end)
end)

ESX.RegisterServerCallback("CrimeNet:leaveGroup", function(src, cb, groupId)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb(false) return end

    CrimeNet.LeaveGroup(groupId, xPlayer.identifier, function(success)
        cb(success)
    end)
end)

-- ============================================================================
-- PROFILE UPDATE CALLBACK
-- ============================================================================
ESX.RegisterServerCallback("CrimeNet:updateProfile", function(src, cb, fields)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb(false) return end

    -- Validate pseudonym if provided
    if fields and fields.pseudonym then
        local clean, err = CrimeNet.IsNameClean(fields.pseudonym)
        if not clean then
            cb(false, err)
            return
        end
    end

    CrimeNet.UpdateProfile(xPlayer.identifier, fields or {})
    cb(true)
end)

-- ============================================================================
-- FIND PLAYER BY CRIMENET ID (for adding contacts)
-- ============================================================================
ESX.RegisterServerCallback("CrimeNet:findByCrimenetId", function(src, cb, crimenetId)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb(nil) return end

    local upperCid = string.upper(crimenetId or "")

    -- Check if it's own ID
    if CrimeNetCache.profiles[xPlayer.identifier] and CrimeNetCache.profiles[xPlayer.identifier].crimenet_id == upperCid then
        cb(nil, "SELF_ADD")
        return
    end

    -- Search in DB
    MySQL.Async.fetchAll("SELECT identifier, pseudonym FROM `crimenet_profiles` WHERE crimenet_id = @cid LIMIT 1", {
        ['@cid'] = upperCid
    }, function(result)
        if result and result[1] then
            local foundId = result[1].identifier
            -- Resolve name
            local info = CrimeNet.ResolvePlayerInfo(foundId)
            local name = info.name
            if name == "Hors ligne" then
                -- Try DB name
                MySQL.Async.fetchScalar("SELECT CONCAT(firstname, ' ', lastname) FROM users WHERE identifier = @id", {
                    ['@id'] = foundId
                }, function(dbName)
                    cb({
                        identifier = foundId,
                        name = result[1].pseudonym or dbName or "Inconnu",
                        crimenet_id = upperCid,
                        online = info.online,
                        is_fake = info.is_fake,
                    })
                end)
            else
                cb({
                    identifier = foundId,
                    name = result[1].pseudonym or name,
                    crimenet_id = upperCid,
                    online = info.online,
                    is_fake = info.is_fake,
                })
            end
        else
            -- Check fake profiles
            for fakeId, fake in pairs(CrimeNetCache.fakeProfiles) do
                if fake.crimenet_id and string.upper(fake.crimenet_id) == upperCid then
                    cb({
                        identifier = fakeId,
                        name = fake.name,
                        crimenet_id = upperCid,
                        online = false,
                        is_fake = true,
                    })
                    return
                end
            end
            cb(nil, "NOT_FOUND")
        end
    end)
end)

-- ============================================================================
-- CONTACT TRUST (migrated from old server.lua)
-- ============================================================================
RegisterServerEvent("Null:crimenet:incrementContactTrust")
AddEventHandler("Null:crimenet:incrementContactTrust", function(contactId, amount)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local identifier = xPlayer.identifier

    exports["null-core"]:GoFast_GetReputation(identifier, function(rep)
        if not rep then return end
        local trust = rep.contact_trust or {}
        trust[contactId] = (trust[contactId] or 0) + (amount or 1)

        for _, contact in ipairs(CrimeNet.Config.NPCContacts) do
            if contact.id == contactId and trust[contactId] > contact.maxTrust then
                trust[contactId] = contact.maxTrust
            end
        end

        MySQL.Async.execute("UPDATE `gofast_reputation` SET contact_trust = @ct WHERE identifier = @id", {
            ['@id'] = identifier,
            ['@ct'] = json.encode(trust),
        })
    end)
end)

-- ============================================================================
-- BLACKLIST APPEAL
-- ============================================================================
RegisterServerEvent("Null:crimenet:removeBlacklist")
AddEventHandler("Null:crimenet:removeBlacklist", function(targetIdentifier)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if not xPlayer.getGroup() or (xPlayer.getGroup() ~= "admin" and xPlayer.getGroup() ~= "superadmin") then
        return
    end

    MySQL.Async.execute("UPDATE `gofast_reputation` SET blacklisted = 0, blacklisted_at = NULL WHERE identifier = @id", {
        ['@id'] = targetIdentifier,
    })

    TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Admin", "Blacklist retirée pour " .. targetIdentifier, "CHAR_MULTIPLAYER")
end)

-- ============================================================================
-- MISSION COMPLETION → TRUST INCREMENT
-- ============================================================================
RegisterServerEvent("Null:gofast:complete")
AddEventHandler("Null:gofast:complete", function(engineHealth)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    exports["null-core"]:GoFast_GetReputation(xPlayer.identifier, function(rep)
        if not rep then return end
        for _, contact in ipairs(CrimeNet.Config.NPCContacts) do
            if rep.xp >= contact.unlockXP then
                local trust = rep.contact_trust or {}
                if (trust[contact.id] or 0) < contact.maxTrust then
                    TriggerEvent("Null:crimenet:incrementContactTrust", contact.id, 1)
                    break
                end
            end
        end
    end)
end)

-- ============================================================================
-- MARKETPLACE HELPERS
-- ============================================================================
local VALID_CATEGORIES = { vehicles = true, weapons = true, items = true, drugs = true }

function CrimeNet.GetMarketListings(identifier, cb)
    MySQL.Async.fetchAll([[
        SELECT m.*, p.pseudonym, p.avatar_url
        FROM `crimenet_marketplace` m
        LEFT JOIN `crimenet_profiles` p ON p.identifier = m.seller
        WHERE m.status IN ('active', 'sold')
        ORDER BY m.created_at DESC
        LIMIT 100
    ]], {}, function(results)
        local listings = {}
        for _, row in ipairs(results or {}) do
            local photos = {}
            if row.photos and row.photos ~= "" then
                photos = json.decode(row.photos) or {}
            end
            -- Resolve seller name
            local sellerName = row.pseudonym or "Anonyme"
            local xSeller = ESX.GetPlayerFromIdentifier(row.seller)
            if not row.pseudonym and xSeller then
                sellerName = xSeller.getName() or "Anonyme"
            end
            table.insert(listings, {
                id = row.id,
                seller_id = row.seller,
                seller_name = sellerName,
                seller_online = xSeller ~= nil,
                category = row.category,
                title = row.title,
                description = row.description or "",
                price = row.price,
                photos = photos,
                status = row.status,
                created_at = tostring(row.created_at),
                is_mine = row.seller == identifier,
            })
        end
        cb(listings)
    end)
end

ESX.RegisterServerCallback("CrimeNet:market:getListings", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end
    CrimeNet.GetMarketListings(xPlayer.identifier, cb)
end)

ESX.RegisterServerCallback("CrimeNet:market:create", function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false, "NO_PLAYER") end

    local category = data.category or "items"
    if not VALID_CATEGORIES[category] then return cb(false, "INVALID_CATEGORY") end

    local title = string.sub(data.title or "", 1, 60)
    if #title < 2 then return cb(false, "TITLE_TOO_SHORT") end

    local description = string.sub(data.description or "", 1, 300)
    local price = tonumber(data.price) or 0
    if price < 0 then price = 0 end

    local photos = data.photos or {}
    if category ~= "vehicles" then photos = {} end -- only vehicles get photos
    local photosJson = json.encode(photos)

    MySQL.Async.execute([[
        INSERT INTO `crimenet_marketplace` (seller, category, title, description, price, photos)
        VALUES (@seller, @cat, @title, @desc, @price, @photos)
    ]], {
        ['@seller'] = xPlayer.identifier,
        ['@cat'] = category,
        ['@title'] = title,
        ['@desc'] = description,
        ['@price'] = price,
        ['@photos'] = photosJson,
    }, function(rowsChanged)
        cb(rowsChanged > 0)
    end)
end)

ESX.RegisterServerCallback("CrimeNet:market:markSold", function(source, cb, listingId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end

    MySQL.Async.execute([[
        UPDATE `crimenet_marketplace` SET status = 'sold' WHERE id = @id AND seller = @seller
    ]], {
        ['@id'] = listingId,
        ['@seller'] = xPlayer.identifier,
    }, function(rowsChanged)
        cb(rowsChanged > 0)
    end)
end)

ESX.RegisterServerCallback("CrimeNet:market:delete", function(source, cb, listingId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end

    MySQL.Async.execute([[
        DELETE FROM `crimenet_marketplace` WHERE id = @id AND seller = @seller
    ]], {
        ['@id'] = listingId,
        ['@seller'] = xPlayer.identifier,
    }, function(rowsChanged)
        cb(rowsChanged > 0)
    end)
end)

-- ============================================================================
-- CONTRACT SYSTEM
-- ============================================================================

-- In-memory cache for available contracts
CrimeNetCache.contracts = {}
CrimeNetCache.lastContractRefresh = 0

function CrimeNet.GenerateContractId()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local id = "CTR-"
    for _ = 1, 8 do
        local idx = math.random(1, #chars)
        id = id .. string.sub(chars, idx, idx)
    end
    return id
end

function CrimeNet.GetPlayerXP(identifier, cb)
    local ok, _ = pcall(function()
        exports["null-core"]:GoFast_GetReputation(identifier, function(rep)
            cb(rep and rep.xp or 0)
        end)
    end)
    if not ok then
        cb(0)
    end
end

function CrimeNet.GenerateContracts()
    local cfg = CrimeNet.Config.Contracts
    local now = os.time()
    
    -- Count players online
    local onlinePlayers = #ESX.GetPlayers()
    
    -- Calculate how many contracts to generate
    local soloCount = math.min(
        cfg.baseCount.solo + math.floor(onlinePlayers * cfg.perPlayerCount.solo / 10),
        cfg.maxCount.solo
    )
    local crewCount = math.min(
        cfg.baseCount.crew + math.floor(onlinePlayers * cfg.perPlayerCount.crew / 10),
        cfg.maxCount.crew
    )
    
    -- Get templates
    local function getRandomContract(type, tierTemplates)
        if not tierTemplates or #tierTemplates == 0 then return nil end
        local tpl = tierTemplates[math.random(1, #tierTemplates)]
        
        -- Apply revenue variance
        local variance = (math.random() * 2 - 1) * (cfg.revenueVariance / 100)
        local revenue = math.floor(tpl.baseRevenue * (1 + variance))
        
        -- Calculate XP reward based on difficulty
        local xpReward = math.floor(tpl.difficulty * 15 * cfg.xpMultiplier)
        
        local contract = {
            contract_id = CrimeNet.GenerateContractId(),
            type = type,
            label = tpl.label,
            description = tpl.description or (type == "crew" and "Contrat en équipe. Requiert coordination." or "Contrat solo. Discrétion requise."),
            vehicle_model = tpl.vehicle,
            vehicle_label = tpl.vehicle,
            cargo_estimate = tpl.cargo,
            revenue = revenue,
            xp_reward = xpReward,
            min_xp = tierTemplates.minXP or 0,
            difficulty = tpl.difficulty,
            crew_min = tpl.crewMin,
            crew_max = tpl.crewMax,
            deadline = tpl.deadline,
            fixed_time = tpl.startTime or nil,
            status = 'available',
            expires_at = os.date("%Y-%m-%d %H:%M:%S", now + cfg.contractLifetime * 60)
        }
        return contract
    end
    
    local newContracts = {}
    
    -- Generate solo contracts across all tiers
    for tierIdx, tier in ipairs(cfg.Templates) do
        local tierCount = math.ceil(soloCount / #cfg.Templates)
        for i = 1, tierCount do
            if tier.solo and #tier.solo > 0 then
                local c = getRandomContract('solo', tier.solo)
                if c then
                    c.min_xp = tier.minXP
                    table.insert(newContracts, c)
                end
            end
        end
    end
    
    -- Generate crew contracts across all tiers
    for tierIdx, tier in ipairs(cfg.Templates) do
        local tierCount = math.ceil(crewCount / #cfg.Templates)
        for i = 1, tierCount do
            if tier.crew and #tier.crew > 0 then
                local c = getRandomContract('crew', tier.crew)
                if c then
                    c.min_xp = tier.minXP
                    c.crew_min = c.crew_min or 2
                    c.crew_max = c.crew_max or 4
                    table.insert(newContracts, c)
                end
            end
        end
    end
    
    -- Generate fixed-time contracts (limited number)
    for _, tier in ipairs(cfg.Templates) do
        if tier.fixedTime and #tier.fixedTime > 0 then
            for _, ft in ipairs(tier.fixedTime) do
                local variance = (math.random() * 2 - 1) * (cfg.revenueVariance / 100)
                local revenue = math.floor(ft.baseRevenue * (1 + variance))
                local xpReward = math.floor(ft.difficulty * 20 * cfg.xpMultiplier)
                
                table.insert(newContracts, {
                    contract_id = CrimeNet.GenerateContractId(),
                    type = ft.crewMin and 'crew' or 'solo',
                    label = ft.label,
                    description = "Contrat à heure fixe. Ne pas rater le départ !",
                    vehicle_model = ft.vehicle,
                    vehicle_label = ft.vehicle,
                    cargo_estimate = ft.cargo,
                    revenue = revenue,
                    xp_reward = xpReward,
                    min_xp = tier.minXP,
                    difficulty = ft.difficulty,
                    crew_min = ft.crewMin,
                    crew_max = ft.crewMax,
                    deadline = ft.deadline,
                    fixed_time = ft.startTime,
                    status = 'available',
                    expires_at = os.date("%Y-%m-%d %H:%M:%S", now + cfg.contractLifetime * 60)
                })
            end
        end
    end
    
    -- Store in DB
    MySQL.Async.execute("DELETE FROM `crimenet_contracts` WHERE status = 'available'", {}, function()
        for _, c in ipairs(newContracts) do
            MySQL.Async.execute([[
                INSERT INTO `crimenet_contracts` 
                (contract_id, type, label, description, vehicle_model, vehicle_label, cargo_estimate,
                 revenue, xp_reward, min_xp, difficulty, crew_min, crew_max, deadline, fixed_time, status, expires_at)
                VALUES (@cid, @type, @label, @desc, @vmodel, @vlabel, @cargo,
                        @revenue, @xp, @minxp, @diff, @crewmin, @crewmax, @deadline, @fixed, 'available', @expires)
            ]], {
                ['@cid'] = c.contract_id,
                ['@type'] = c.type,
                ['@label'] = c.label,
                ['@desc'] = c.description,
                ['@vmodel'] = c.vehicle_model,
                ['@vlabel'] = c.vehicle_label,
                ['@cargo'] = c.cargo_estimate,
                ['@revenue'] = c.revenue,
                ['@xp'] = c.xp_reward,
                ['@minxp'] = c.min_xp,
                ['@diff'] = c.difficulty,
                ['@crewmin'] = c.crew_min,
                ['@crewmax'] = c.crew_max,
                ['@deadline'] = c.deadline,
                ['@fixed'] = c.fixed_time,
                ['@expires'] = c.expires_at,
            })
        end
    end)
    
    CrimeNetCache.contracts = newContracts
    CrimeNetCache.lastContractRefresh = now
    print("[CrimeNet] Generated " .. #newContracts .. " new contracts")
end

function CrimeNet.RefreshContractsIfNeeded()
    local cfg = CrimeNet.Config.Contracts
    local now = os.time()
    if now - CrimeNetCache.lastContractRefresh > cfg.refreshInterval * 60 then
        CrimeNet.GenerateContracts()
    end
end

function CrimeNet.GetContractsForPlayer(identifier, cb)
    CrimeNet.RefreshContractsIfNeeded()
    
    CrimeNet.GetPlayerXP(identifier, function(xp)
        MySQL.Async.fetchAll([[
            SELECT * FROM `crimenet_contracts` 
            WHERE status = 'available' AND expires_at > NOW()
            ORDER BY min_xp ASC, revenue DESC
        ]], {}, function(results)
            local contracts = {}
            for _, row in ipairs(results or {}) do
                local isLocked = xp < row.min_xp
                table.insert(contracts, {
                    id = row.contract_id,
                    type = row.type,
                    label = row.label,
                    description = row.description,
                    vehicleModel = row.vehicle_model,
                    vehicleLabel = row.vehicle_label,
                    cargoEstimate = row.cargo_estimate,
                    revenue = row.revenue,
                    xpReward = row.xp_reward,
                    minXP = row.min_xp,
                    difficulty = row.difficulty,
                    crewMin = row.crew_min,
                    crewMax = row.crew_max,
                    deadline = row.deadline,
                    fixedTime = row.fixed_time,
                    status = isLocked and 'locked' or 'available',
                    xpCurrent = xp,
                })
            end
            cb(contracts)
        end)
    end)
end

function CrimeNet.GetPlayerActiveContract(identifier, cb)
    MySQL.Async.fetchAll([[
        SELECT pc.*, c.* 
        FROM `crimenet_player_contracts` pc
        INNER JOIN `crimenet_contracts` c ON c.contract_id = pc.contract_id
        WHERE pc.identifier = @id AND pc.status = 'active'
        LIMIT 1
    ]], { ['@id'] = identifier }, function(results)
        if results and results[1] then
            cb({
                contractId = results[1].contract_id,
                acceptedAt = results[1].accepted_at,
                mustCompleteBy = results[1].must_complete_by,
                isCrew = results[1].is_crew == 1,
                crewMembers = results[1].crew_members and json.decode(results[1].crew_members) or nil,
            })
        else
            cb(nil)
        end
    end)
end

function CrimeNet.AcceptContract(identifier, contractId, crewMembers, cb)
    local cfg = CrimeNet.Config.Contracts
    
    -- Check if player already has active contract
    MySQL.Async.fetchScalar([[
        SELECT COUNT(*) FROM `crimenet_player_contracts` 
        WHERE identifier = @id AND status = 'active'
    ]], { ['@id'] = identifier }, function(hasActive)
        if hasActive > 0 then
            cb(false, "ALREADY_ACTIVE_CONTRACT")
            return
        end
        
        -- Get contract details
        MySQL.Async.fetchAll([[
            SELECT * FROM `crimenet_contracts` WHERE contract_id = @cid AND status = 'available'
        ]], { ['@cid'] = contractId }, function(results)
            if not results or #results == 0 then
                cb(false, "CONTRACT_NOT_AVAILABLE")
                return
            end
            
            local contract = results[1]
            
            -- Check XP requirement
            CrimeNet.GetPlayerXP(identifier, function(xp)
                if xp < contract.min_xp then
                    cb(false, "INSUFFICIENT_XP")
                    return
                end
                
                -- Check crew requirements
                if contract.type == 'crew' then
                    local crewCount = crewMembers and #crewMembers or 0
                    local minCrew = contract.crew_min or 2
                    local maxCrew = contract.crew_max or 6
                    
                    if crewCount < minCrew then
                        cb(false, "INSUFFICIENT_CREW")
                        return
                    end
                    if crewCount > maxCrew then
                        cb(false, "TOO_MANY_CREW")
                        return
                    end
                end
                
                -- Calculate completion deadline
                local now = os.time()
                local mustCompleteBy
                
                if contract.fixed_time then
                    -- Parse fixed time (e.g., "22:00")
                    local hour, min = string.match(contract.fixed_time, "(%d+):(%d+)")
                    if hour and min then
                        local fixedTs = os.time({
                            year = os.date("*t", now).year,
                            month = os.date("*t", now).month,
                            day = os.date("*t", now).day,
                            hour = tonumber(hour),
                            min = tonumber(min),
                            sec = 0
                        })
                        -- If time already passed today, it's for tomorrow
                        if fixedTs < now then
                            fixedTs = fixedTs + 86400
                        end
                        mustCompleteBy = fixedTs + contract.deadline * 60
                    else
                        mustCompleteBy = now + contract.deadline * 60
                    end
                else
                    mustCompleteBy = now + contract.deadline * 60
                end
                
                -- Update contract status
                MySQL.Async.execute([[
                    UPDATE `crimenet_contracts` 
                    SET status = 'accepted', accepted_by = @id, accepted_at = NOW()
                    WHERE contract_id = @cid
                ]], { ['@cid'] = contractId, ['@id'] = identifier }, function()
                    -- Create player contract record
                    MySQL.Async.execute([[
                        INSERT INTO `crimenet_player_contracts`
                        (identifier, contract_id, must_complete_by, is_crew, crew_members)
                        VALUES (@id, @cid, @completeBy, @isCrew, @crew)
                    ]], {
                        ['@id'] = identifier,
                        ['@cid'] = contractId,
                        ['@completeBy'] = os.date("%Y-%m-%d %H:%M:%S", mustCompleteBy),
                        ['@isCrew'] = contract.type == 'crew' and 1 or 0,
                        ['@crew'] = crewMembers and json.encode(crewMembers) or nil,
                    }, function()
                        cb(true, {
                            contractId = contractId,
                            type = contract.type,
                            deadline = mustCompleteBy,
                            fixedTime = contract.fixed_time,
                        })
                    end)
                end)
            end)
        end)
    end)
end

function CrimeNet.FailContract(identifier, reason)
    local cfg = CrimeNet.Config.Contracts
    
    MySQL.Async.execute([[
        UPDATE `crimenet_player_contracts` 
        SET status = 'failed', failed_at = NOW(), fail_reason = @reason
        WHERE identifier = @id AND status = 'active'
    ]], { ['@id'] = identifier, ['@reason'] = reason }, function()
        -- Apply reputation penalty
        exports["null-core"]:GoFast_GetReputation(identifier, function(rep)
            if rep then
                local penalty = reason == "FIXED_TIME_MISSED" and cfg.fixedTimeMissPenalty or cfg.contractFailPenalty
                local newXP = math.max(0, (rep.xp or 0) - penalty)
                
                -- Update XP via GoFast system
                TriggerEvent("Null:goFast:setXP", identifier, newXP)
                
                -- Notify player
                local src = ESX.GetPlayerFromIdentifier(identifier)
                if src then
                    TriggerClientEvent("esx:showNotification", src.source, 
                        "~r~Contrat échoué : -" .. penalty .. " XP")
                end
            end
        end)
    end)
end

function CrimeNet.CompleteContract(identifier)
    MySQL.Async.execute([[
        UPDATE `crimenet_player_contracts` 
        SET status = 'completed', completed_at = NOW()
        WHERE identifier = @id AND status = 'active'
    ]], { ['@id'] = identifier })
end

-- Contract cleanup thread
CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        
        -- Expire old available contracts
        MySQL.Async.execute([[
            UPDATE `crimenet_contracts` 
            SET status = 'expired' 
            WHERE status = 'available' AND expires_at < NOW()
        ]], {})
        
        -- Find and fail expired player contracts
        MySQL.Async.fetchAll([[
            SELECT pc.identifier, c.fixed_time, c.label
            FROM `crimenet_player_contracts` pc
            INNER JOIN `crimenet_contracts` c ON c.contract_id = pc.contract_id
            WHERE pc.status = 'active' AND pc.must_complete_by < NOW()
        ]], {}, function(results)
            for _, row in ipairs(results or {}) do
                local reason = row.fixed_time and "FIXED_TIME_MISSED" or "DEADLINE_EXPIRED"
                CrimeNet.FailContract(row.identifier, reason)
            end
        end)
    end
end)

-- Server callbacks for contracts
ESX.RegisterServerCallback("CrimeNet:getContracts", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end
    CrimeNet.GetContractsForPlayer(xPlayer.identifier, cb)
end)

ESX.RegisterServerCallback("CrimeNet:getActiveContract", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end
    CrimeNet.GetPlayerActiveContract(xPlayer.identifier, cb)
end)

ESX.RegisterServerCallback("CrimeNet:acceptContract", function(source, cb, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false, "NO_PLAYER") end
    CrimeNet.AcceptContract(xPlayer.identifier, data.contractId, data.crewMembers, cb)
end)

-- Event handlers for GoFast mission integration
RegisterServerEvent("Null:crimenet:missionStarted")
AddEventHandler("Null:crimenet:missionStarted", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    -- Check if player has active contract
    CrimeNet.GetPlayerActiveContract(xPlayer.identifier, function(contract)
        if contract then
            -- Mark that mission is from contract
            TriggerClientEvent("crimenet:contractMission", src, {
                contractId = contract.contractId,
                mustCompleteBy = contract.mustCompleteBy,
                isCrew = contract.isCrew,
            })
        end
    end)
end)

RegisterServerEvent("Null:crimenet:missionCompleted")
AddEventHandler("Null:crimenet:missionCompleted", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    CrimeNet.CompleteContract(xPlayer.identifier)
end)

RegisterServerEvent("Null:crimenet:missionFailed")
AddEventHandler("Null:crimenet:missionFailed", function(reason)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    CrimeNet.FailContract(xPlayer.identifier, reason or "FAILED")
end)

-- Admin command to refresh contracts
RegisterCommand("refreshcontracts", function(source)
    if source > 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or not xPlayer.getGroup() or (xPlayer.getGroup() ~= "fondateur") then
            return
        end
    end
    CrimeNet.GenerateContracts()
    if source > 0 then
        TriggerClientEvent("esx:showNotification", source, "~g~Contrats rafraîchis")
    end
end, true)

print("[CrimeNet] Server main loaded")
