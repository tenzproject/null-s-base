-- ============================================================================
-- CRIMENET - Server (app data bridge to gofast module)
-- ============================================================================

-- The heavy lifting is done by the gofast module in null-core.
-- This server file handles CrimeNet-specific server callbacks and events
-- that the lb-phone app needs but don't belong in the core module.

-- ============================================================================
-- CONTACT MESSAGE SYSTEM
-- ============================================================================
-- Contacts send scripted messages based on trust level.
-- Trust increases when missions are completed successfully.

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

        -- Cap trust at contact's maxTrust from config
        for _, contact in ipairs(Config.GoFast.Contacts) do
            if contact.id == contactId and trust[contactId] > contact.maxTrust then
                trust[contactId] = contact.maxTrust
            end
        end

        -- Save via core module
        MySQL.Async.execute("UPDATE `gofast_reputation` SET contact_trust = @ct WHERE identifier = @id", {
            ['@id'] = identifier,
            ['@ct'] = json.encode(trust),
        })
    end)
end)

-- ============================================================================
-- BLACKLIST APPEAL (admin only, or future in-app mechanic)
-- ============================================================================
RegisterServerEvent("Null:crimenet:removeBlacklist")
AddEventHandler("Null:crimenet:removeBlacklist", function(targetIdentifier)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- Only allow staff
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
-- Listen for gofast completion to auto-increment contact trust
RegisterServerEvent("Null:gofast:complete")
AddEventHandler("Null:gofast:complete", function(engineHealth)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- Pick a random unlocked contact to increase trust
    exports["null-core"]:GoFast_GetReputation(xPlayer.identifier, function(rep)
        if not rep then return end
        for _, contact in ipairs(Config.GoFast.Contacts) do
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

print("[CrimeNet] Serveur chargé")
