-- ============================================================================
-- CRIMENET - Admin & Test Commands
-- ============================================================================

-- Helper: resolve a CN-XXXXX id to an internal identifier
local function ResolveCNId(input)
    if not input then return nil end
    local upper = string.upper(input)
    -- If it looks like a CN-ID
    if string.sub(upper, 1, 3) == "CN-" then
        -- Check real profiles
        for id, p in pairs(CrimeNetCache.profiles) do
            if p.crimenet_id and string.upper(p.crimenet_id) == upper then
                return id
            end
        end
        -- Check fake profiles
        for fid, f in pairs(CrimeNetCache.fakeProfiles) do
            if f.crimenet_id and string.upper(f.crimenet_id) == upper then
                return fid
            end
        end
        return nil
    end
    -- Otherwise treat as raw identifier
    return input
end

-- ============================================================================
-- /cn_myid
-- Shows the player's CrimeNet ID
-- ============================================================================
RegisterCommand("cn_myid", function(src, args)
    if src <= 0 then print("[CrimeNet] Must be run in-game") return end
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local profile = CrimeNetCache.profiles[xPlayer.identifier]
    local cid = profile and profile.crimenet_id or "Non généré"
    TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Ton ID", cid, "CHAR_MULTIPLAYER")
end, false)

-- ============================================================================
-- /cn_fakeplayer <name> [gangname] [is_boss 0/1] [is_important 0/1] [admin_label]
-- Creates a fake player profile for testing the network
-- ============================================================================
RegisterCommand("cn_fakeplayer", function(src, args)
    if src > 0 then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer or (xPlayer.getGroup() ~= "fondateur") then
            TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Erreur", "Permissions insuffisantes", "CHAR_MULTIPLAYER")
            return
        end
    end

    local name = args[1]
    if not name then
        if src > 0 then
            TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Usage", "/cn_fakeplayer <name> [gang] [is_boss] [is_important] [label]", "CHAR_MULTIPLAYER")
        else
            print("[CrimeNet] Usage: cn_fakeplayer <name> [gang] [is_boss] [is_important] [label]")
        end
        return
    end

    local gangname = args[2] ~= "none" and args[2] or nil
    local is_boss = tonumber(args[3]) == 1
    local is_important = tonumber(args[4]) == 1
    local admin_label = args[5] or nil
    local fakeId = "fake:" .. string.lower(name) .. ":" .. math.random(1000, 9999)
    local cid = CrimeNet.GenerateId()

    MySQL.Async.execute([[
        INSERT INTO `crimenet_fake_profiles` (fake_id, name, gangname, is_boss, is_important, admin_label, description, crimenet_id)
        VALUES (@id, @name, @gang, @boss, @imp, @label, @desc, @cid)
    ]], {
        ['@id'] = fakeId,
        ['@name'] = name,
        ['@gang'] = gangname,
        ['@boss'] = is_boss and 1 or 0,
        ['@imp'] = is_important and 1 or 0,
        ['@label'] = admin_label,
        ['@desc'] = "Profil test: " .. name,
        ['@cid'] = cid,
    }, function()
        -- Update cache
        CrimeNetCache.fakeProfiles[fakeId] = {
            name = name,
            gangname = gangname,
            is_boss = is_boss,
            is_important = is_important,
            admin_label = admin_label,
            description = "Profil test: " .. name,
            avatar_url = nil,
            crimenet_id = cid,
        }

        local msg = "Fake créé: " .. name .. " (" .. cid .. ")"
        if gangname then msg = msg .. " | Gang: " .. gangname end
        if is_boss then msg = msg .. " | BOSS" end
        if is_important then msg = msg .. " | IMPORTANT" end

        if src > 0 then
            TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Admin", msg, "CHAR_MULTIPLAYER")
        end
        print("[CrimeNet] " .. msg)
    end)
end, false)

-- ============================================================================
-- /cn_addcontact <target_server_id|"me"> <contact_identifier>
-- Adds a contact to a player (real or fake)
-- ============================================================================
RegisterCommand("cn_addcontact", function(src, args)
    if src > 0 then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer or (xPlayer.getGroup() ~= "fondateur") then
            TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Erreur", "Permissions insuffisantes", "CHAR_MULTIPLAYER")
            return
        end
    end

    local target = args[1]
    local contactInput = args[2]

    if not target or not contactInput then
        local usage = "/cn_addcontact <server_id|me> <identifier|CN-XXXXX>"
        if src > 0 then
            TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Usage", usage, "CHAR_MULTIPLAYER")
        else
            print("[CrimeNet] Usage: " .. usage)
        end
        return
    end

    -- Resolve target
    local targetIdentifier
    if target == "me" and src > 0 then
        local xPlayer = ESX.GetPlayerFromId(src)
        targetIdentifier = xPlayer.identifier
    else
        local targetId = tonumber(target)
        if targetId then
            local xTarget = ESX.GetPlayerFromId(targetId)
            if xTarget then
                targetIdentifier = xTarget.identifier
            end
        end
    end

    if not targetIdentifier then
        if src > 0 then
            TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Erreur", "Joueur introuvable", "CHAR_MULTIPLAYER")
        else
            print("[CrimeNet] Joueur introuvable")
        end
        return
    end

    local contactId = ResolveCNId(contactInput)
    if not contactId then
        local errMsg = "Identifiant/CN-ID introuvable: " .. contactInput
        if src > 0 then
            TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Erreur", errMsg, "CHAR_MULTIPLAYER")
        else
            print("[CrimeNet] " .. errMsg)
        end
        return
    end

    CrimeNet.AddContact(targetIdentifier, contactId, nil, function(success, err)
        local msg = success and ("Contact ajouté: " .. contactId) or ("Erreur: " .. (err or "unknown"))
        if src > 0 then
            TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Admin", msg, "CHAR_MULTIPLAYER")
        end
        print("[CrimeNet] " .. msg)
    end)
end, false)

-- ============================================================================
-- /cn_important <identifier> [label]
-- Marks a player (real or fake) as important in the network
-- ============================================================================
RegisterCommand("cn_important", function(src, args)
    if src > 0 then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer or (xPlayer.getGroup() ~= "fondateur") then
            TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Erreur", "Permissions insuffisantes", "CHAR_MULTIPLAYER")
            return
        end
    end

    local rawId = args[1]
    if not rawId then
        local usage = "/cn_important <identifier|CN-XXXXX> [label]"
        if src > 0 then
            TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Usage", usage, "CHAR_MULTIPLAYER")
        else
            print("[CrimeNet] Usage: " .. usage)
        end
        return
    end

    local identifier = ResolveCNId(rawId)
    if not identifier then
        local errMsg = "Identifiant/CN-ID introuvable: " .. rawId
        if src > 0 then TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Erreur", errMsg, "CHAR_MULTIPLAYER") end
        return
    end

    local label = args[2] or nil

    MySQL.Async.execute([[
        INSERT INTO `crimenet_network_nodes` (identifier, is_important, admin_label, set_by)
        VALUES (@id, 1, @label, @setby)
        ON DUPLICATE KEY UPDATE is_important = 1, admin_label = @label, set_by = @setby
    ]], {
        ['@id'] = identifier,
        ['@label'] = label,
        ['@setby'] = src > 0 and ESX.GetPlayerFromId(src).identifier or "console",
    }, function()
        CrimeNetCache.networkNodes[identifier] = { is_important = true, admin_label = label }

        -- If it's a fake profile, update that too
        if CrimeNetCache.fakeProfiles[identifier] then
            CrimeNetCache.fakeProfiles[identifier].is_important = true
            CrimeNetCache.fakeProfiles[identifier].admin_label = label
            MySQL.Async.execute("UPDATE `crimenet_fake_profiles` SET is_important = 1, admin_label = @label WHERE fake_id = @id", {
                ['@id'] = identifier, ['@label'] = label
            })
        end

        local msg = "Marqué important: " .. identifier .. (label and (" (" .. label .. ")") or "")
        if src > 0 then
            TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Admin", msg, "CHAR_MULTIPLAYER")
        end
        print("[CrimeNet] " .. msg)
    end)
end, false)

-- ============================================================================
-- /cn_unimportant <identifier>
-- Removes important status from a player
-- ============================================================================
RegisterCommand("cn_unimportant", function(src, args)
    if src > 0 then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer or (xPlayer.getGroup() ~= "fondateur") then
            return
        end
    end

    local rawId = args[1]
    if not rawId then return end
    local identifier = ResolveCNId(rawId)
    if not identifier then return end

    MySQL.Async.execute("DELETE FROM `crimenet_network_nodes` WHERE identifier = @id", {
        ['@id'] = identifier
    })
    CrimeNetCache.networkNodes[identifier] = nil

    if CrimeNetCache.fakeProfiles[identifier] then
        CrimeNetCache.fakeProfiles[identifier].is_important = false
        CrimeNetCache.fakeProfiles[identifier].admin_label = nil
        MySQL.Async.execute("UPDATE `crimenet_fake_profiles` SET is_important = 0, admin_label = NULL WHERE fake_id = @id", {
            ['@id'] = identifier
        })
    end

    local msg = "Important retiré: " .. identifier
    if src > 0 then
        TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Admin", msg, "CHAR_MULTIPLAYER")
    end
    print("[CrimeNet] " .. msg)
end, false)

-- ============================================================================
-- /cn_listfakes
-- Lists all fake profiles
-- ============================================================================
RegisterCommand("cn_listfakes", function(src, args)
    if src > 0 then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer or (xPlayer.getGroup() ~= "fondateur") then
            return
        end
    end

    print("[CrimeNet] === FAKE PROFILES ===")
    for fakeId, fake in pairs(CrimeNetCache.fakeProfiles) do
        local line = (fake.crimenet_id or "NO-ID") .. " | " .. fakeId .. " | " .. fake.name
        if fake.gangname then line = line .. " | Gang: " .. fake.gangname end
        if fake.is_boss then line = line .. " | BOSS" end
        if fake.is_important then line = line .. " | IMPORTANT" end
        print("  " .. line)
    end
    print("[CrimeNet] === END ===")

    if src > 0 then
        TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Admin", "Liste affichée dans la console serveur", "CHAR_MULTIPLAYER")
    end
end, false)

-- ============================================================================
-- /cn_delfake <fake_id>
-- Deletes a fake profile and all its contacts
-- ============================================================================
RegisterCommand("cn_delfake", function(src, args)
    if src > 0 then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer or (xPlayer.getGroup() ~= "fondateur") then
            return
        end
    end

    local rawId = args[1]
    if not rawId then return end
    local fakeId = ResolveCNId(rawId)
    if not fakeId then fakeId = rawId end

    MySQL.Async.execute("DELETE FROM `crimenet_fake_profiles` WHERE fake_id = @id", { ['@id'] = fakeId })
    MySQL.Async.execute("DELETE FROM `crimenet_contacts` WHERE owner = @id OR contact = @id", { ['@id'] = fakeId })
    MySQL.Async.execute("DELETE FROM `crimenet_network_nodes` WHERE identifier = @id", { ['@id'] = fakeId })

    CrimeNetCache.fakeProfiles[fakeId] = nil
    CrimeNetCache.networkNodes[fakeId] = nil

    local msg = "Fake supprimé: " .. fakeId
    if src > 0 then
        TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Admin", msg, "CHAR_MULTIPLAYER")
    end
    print("[CrimeNet] " .. msg)
end, false)

-- ============================================================================
-- /cn_testsetup
-- Quick setup: creates a large realistic criminal network with gangs,
-- cartels, and specialized contacts (launderers, arms dealers, etc.)
-- ============================================================================
RegisterCommand("cn_testsetup", function(src, args)
    if src <= 0 then print("[CrimeNet] This command must be run in-game") return end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer or (xPlayer.getGroup() ~= "fondateur") then
        TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Erreur", "Permissions insuffisantes", "CHAR_MULTIPLAYER")
        return
    end

    local myId = xPlayer.identifier

    -- Large criminal ecosystem with gangs, cartels, and specialists
    local fakes = {

        { name = "Lil' Loco",    gang = "vagos",    boss = true,  imp = true,  label = "OG" },
        { name = "Big Haze",     gang = "vagos",    boss = false, imp = false, label = "Shotcaller" },
        { name = "Vago Raton",   gang = "vagos",    boss = false, imp = false, label = "Soldat" },
        { name = "Shadow",       gang = nil,         boss = false, imp = true,  label = "Informateur" },
        -- { name = "Ghost Runner", gang = nil,         boss = false, imp = false, label = nil },
        { name = "Broker",       gang = nil,         boss = false, imp = true,  label = "Courtier" },
        { name = "M. Madrazo",   gang = "madrazo",  boss = true,  imp = true,  label = "Don du Cartel" },
        { name = "El Coronel",   gang = "madrazo",  boss = false, imp = true,  label = "Lieutenant" },
        { name = "Sicario Delta",gang = "madrazo",  boss = false, imp = false, label = "Enforcer" },
        -- { name = "La Madrina",   gang = "madrazo",  boss = false, imp = false, label = "Comptable" },
        { name = "El Coyote",    gang = "madrazo",  boss = false, imp = false, label = "Trafficker" },

        -- -- ═══════════════════════════════════════════════════════════
        -- -- MADRAZO CARTEL (Mexican Cartel - Major cocaine supplier)
        -- -- ═══════════════════════════════════════════════════════════
        -- { name = "M. Madrazo",      gang = "madrazo",  boss = true,  imp = true,  label = "Don du Cartel" },
        -- { name = "El Coronel",      gang = "madrazo",  boss = false, imp = true,  label = "Lieutenant" },
        -- { name = "Sicario Delta",   gang = "madrazo",  boss = false, imp = false, label = "Enforcer" },
        -- { name = "La Madrina",      gang = "madrazo",  boss = false, imp = false, label = "Comptable" },
        -- { name = "El Coyote",       gang = "madrazo",  boss = false, imp = false, label = "Trafficker" },


        -- -- ═══════════════════════════════════════════════════════════
        -- -- VAGOS (Latino street gang - territory control)
        -- -- ═══════════════════════════════════════════════════════════
        -- { name = "Lil' Loco",       gang = "vagos",    boss = true,  imp = true,  label = "OG" },
        -- { name = "Big Haze",        gang = "vagos",    boss = false, imp = false, label = "Shotcaller" },
        -- { name = "Vago Raton",      gang = "vagos",    boss = false, imp = false, label = "Soldat" },
        -- { name = "Cypress",         gang = "vagos",    boss = false, imp = false, label = "Soldat" },


        -- -- ═══════════════════════════════════════════════════════════
        -- -- ARMENIAN MAFIA (International fraud, car theft)
        -- -- ═══════════════════════════════════════════════════════════
        -- { name = "Simeon Y",        gang = "armenian", boss = true,  imp = true,  label = "Boss" },
        -- { name = "Karen D",         gang = "armenian", boss = false, imp = false, label = "Accountant" },
        -- { name = "Repo Man",        gang = "armenian", boss = false, imp = false, label = "Collector" },

        -- -- ═══════════════════════════════════════════════════════════
        -- -- SPECIALIZED INDEPENDENT CONTACTS (No gang affiliation)
        -- -- ═══════════════════════════════════════════════════════════
        
        -- -- Money Launderers
        -- { name = "Lester Crest",    gang = nil, boss = false, imp = true,  label = "Blanchisseur" },
        -- { name = "Swiss Connect",   gang = nil, boss = false, imp = false, label = "Blanchisseur" },

        -- -- Weapons Dealers - Small Arms
        -- { name = "G. Lester",       gang = nil, boss = false, imp = true,  label = "Armes Légères" },
        -- { name = "AK Connection",   gang = nil, boss = false, imp = false, label = "Armes Légères" },

        -- -- Weapons Dealers - Heavy/Explosives
        -- { name = "The Gunner",      gang = nil, boss = false, imp = true,  label = "Armes Lourdes" },

        -- -- Hackers & Tech
        -- -- { name = "Phantom Phreak",  gang = nil, boss = false, imp = false, label = "Hacker" },
        -- { name = "4Chan",           gang = nil, boss = false, imp = false, label = "Hacker" },

        -- -- Forgers & Documents
        -- { name = "The Forger",      gang = nil, boss = false, imp = true,  label = "Faussaire" },

        -- -- Getaway Drivers & Transport
        -- { name = "Wheelman",        gang = nil, boss = false, imp = true,  label = "Chauffeur" },
        -- { name = "Chopper Pilot",   gang = nil, boss = false, imp = false, label = "Pilote" },

        -- -- Informants & Snitches
        -- { name = "Deep Throat",     gang = nil, boss = false, imp = true,  label = "Informateur" },

        -- -- Enforcers/Hitmen
        -- { name = "The Cleaner",     gang = nil, boss = false, imp = true,  label = "Tueur à gages" },

        -- -- Smugglers & Traffickers
        -- { name = "Captain Jack",    gang = nil, boss = false, imp = true,  label = "Contrebandier" },

        -- -- Muscle/Security
        -- { name = "Tiny",            gang = nil, boss = false, imp = false, label = "Muscle" },
        -- { name = "Brutus",          gang = nil, boss = false, imp = false, label = "Muscle" },

        -- -- Jewelers/Heist Specialists
        -- { name = "The Jeweler",     gang = nil, boss = false, imp = true,  label = "Joaillier" },
        -- { name = "Vault Tech",      gang = nil, boss = false, imp = false, label = "Spécialiste" },
        -- { name = "Thermite Guy",    gang = nil, boss = false, imp = false, label = "Spécialiste" },
    }

    local createdIds = {}
    local pending = #fakes

    for _, f in ipairs(fakes) do
        local fakeId = "fake:" .. string.lower(f.name:gsub(" ", "_")) .. ":" .. math.random(1000, 9999)
        local fakeCid = CrimeNet.GenerateId()

        MySQL.Async.execute([[
            INSERT INTO `crimenet_fake_profiles` (fake_id, name, gangname, is_boss, is_important, admin_label, description, crimenet_id)
            VALUES (@id, @name, @gang, @boss, @imp, @label, @desc, @cid)
        ]], {
            ['@id'] = fakeId,
            ['@name'] = f.name,
            ['@gang'] = f.gang,
            ['@boss'] = f.boss and 1 or 0,
            ['@imp'] = f.imp and 1 or 0,
            ['@label'] = f.label,
            ['@desc'] = "Contact du réseau: " .. f.name,
            ['@cid'] = fakeCid,
        }, function()
            CrimeNetCache.fakeProfiles[fakeId] = {
                name = f.name,
                gangname = f.gang,
                is_boss = f.boss,
                is_important = f.imp,
                admin_label = f.label,
                description = "Contact du réseau: " .. f.name,
                avatar_url = nil,
                crimenet_id = fakeCid,
            }

            if f.imp then
                CrimeNetCache.networkNodes[fakeId] = { is_important = true, admin_label = f.label }
                MySQL.Async.execute([[
                    INSERT IGNORE INTO `crimenet_network_nodes` (identifier, is_important, admin_label, set_by)
                    VALUES (@id, 1, @label, @setby)
                ]], { ['@id'] = fakeId, ['@label'] = f.label, ['@setby'] = myId })
            end

            table.insert(createdIds, fakeId)

            pending = pending - 1
            if pending <= 0 then
                -- Add all fakes as contacts
                for _, cid in ipairs(createdIds) do
                    CrimeNet.AddContact(myId, cid, nil, function() end)
                end

                TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Admin",
                    #createdIds .. " contacts criminels créés", "CHAR_MULTIPLAYER")
                print("[CrimeNet] Test setup complete: " .. #createdIds .. " fake profiles created for " .. myId)
                print("[CrimeNet] Gangs: Madrazo Cartel, The Lost MC, Vagos, Families, Ballas, Triads, Armenian Mafia")
                print("[CrimeNet] Specialists: Launderers, Arms dealers, Drug dealers, Hackers, Drivers, Hitmen, Smugglers, Medics")
            end
        end)
    end
end, false)

-- ============================================================================
-- /cn_cleartest
-- Removes all fake profiles and their contacts
-- ============================================================================
RegisterCommand("cn_cleartest", function(src, args)
    if src > 0 then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer or (xPlayer.getGroup() ~= "fondateur") then
            return
        end
    end

    MySQL.Async.execute("DELETE FROM `crimenet_fake_profiles`", {})
    MySQL.Async.execute("DELETE FROM `crimenet_contacts` WHERE owner LIKE 'fake:%' OR contact LIKE 'fake:%'", {})
    MySQL.Async.execute("DELETE FROM `crimenet_network_nodes` WHERE identifier LIKE 'fake:%'", {})

    CrimeNetCache.fakeProfiles = {}
    -- Clean network nodes cache of fake entries
    for id, _ in pairs(CrimeNetCache.networkNodes) do
        if string.sub(id, 1, 5) == "fake:" then
            CrimeNetCache.networkNodes[id] = nil
        end
    end

    local msg = "Tous les faux profils supprimés"
    if src > 0 then
        TriggerClientEvent("esx:showAdvancedNotification", src, "CRIMENET", "Admin", msg, "CHAR_MULTIPLAYER")
    end
    print("[CrimeNet] " .. msg)
end, false)

print("[CrimeNet] Commands loaded")
