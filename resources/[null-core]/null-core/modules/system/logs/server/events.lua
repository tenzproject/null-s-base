--[[
    Null Logs System - Events
    Gestion des événements de logs (connexion, déconnexion, mort, etc.)
]]
    
-- Namespace
null.logs = null.logs or {}

-- Couleurs Discord
local Colors = {
    green = 5763719,    -- Connexion
    red = 15548997,     -- Déconnexion, mort
    orange = 16744192,  -- Warning
    blue = 3447003,     -- Info
    purple = 10181046,  -- Special
    grey = 9807270      -- Neutral
}

--[[
    Event: Connexion joueur
]]
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    if not xPlayer then return end
    
    local ids = null.fct.getIdentifiers(xPlayer.source)
    local ip = GetPlayerEndpoint(xPlayer.source)
    local ping = GetPlayerPing(xPlayer.source)
    
    null.logs.send(
        "Connexion",
        ("**%s** s'est connecté au serveur\n\n**Ping:** %sms"):format(xPlayer.getName(), ping),
        "connexion",
        {
            idunique = xPlayer.getIdunique(),
            name = xPlayer.getName(),
            ip = ip,
            discord = ids.discord,
            license = ids.license,
            color = Colors.green
        }
    )
end)

--[[
    Event: Déconnexion joueur
]]
AddEventHandler('playerDropped', function(reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local ids = null.fct.getIdentifiers(source)
    local playerName = GetPlayerName(source) or xPlayer.getName()
    
    -- Traduire la raison
    local reasonText = reason
    if reason == "Exiting" then
        reasonText = "Déconnexion volontaire"
    elseif reason == "Timed out" then
        reasonText = "Timeout"
    end
    
    null.logs.send(
        "Déconnexion",
        ("**%s** s'est déconnecté\n\n**Raison:** %s"):format(playerName, reasonText),
        "deconnexion",
        {
            idunique = xPlayer.getIdunique(),
            name = playerName,
            discord = ids.discord,
            license = ids.license,
            color = Colors.red
        }
    )
end)

--[[
    Event: Mort d'un joueur
]]
RegisterNetEvent('playerDied')
AddEventHandler('playerDied', function(deathType, playerId, killerId, deathReason, weapon)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local weaponText = weapon and ("`" .. weapon .. "`") or "Inconnu"
    
    if deathType == 1 then
        -- Suicide ou mort naturelle
        null.logs.send(
            "Mort",
            ("**%s** est mort\n\n**Cause:** %s"):format(xPlayer.getName(), weaponText),
            "mort",
            {
                idunique = xPlayer.getIdunique(),
                name = xPlayer.getName(),
                color = Colors.grey
            }
        )
    elseif deathType == 2 then
        -- Tué par un autre joueur
        local xKiller = ESX.GetPlayerFromId(killerId)
        if not xKiller then return end

        -- Incrémente les compteurs staff (kills/deaths) pour les gamertags
        if NullIncrementKillStat then
            NullIncrementKillStat(xKiller.getIdunique(), xPlayer.getIdunique())
        end
        
        -- Log pour la victime
        null.logs.send(
            "Mort",
            ("**%s** a été tué par **%s**\n\n**Arme:** %s\n**Raison:** %s"):format(
                xPlayer.getName(),
                xKiller.getName(),
                weaponText,
                deathReason or "N/A"
            ),
            "mort",
            {
                idunique = xPlayer.getIdunique(),
                name = xPlayer.getName(),
                idunique_cible = xKiller.getIdunique(),
                name_cible = xKiller.getName(),
                color = Colors.red
            }
        )
        
        -- Log pour le tueur
        null.logs.send(
            "Meurtre",
            ("**%s** a tué **%s**\n\n**Arme:** %s"):format(
                xKiller.getName(),
                xPlayer.getName(),
                weaponText
            ),
            "kill",
            {
                idunique = xKiller.getIdunique(),
                name = xKiller.getName(),
                idunique_cible = xPlayer.getIdunique(),
                name_cible = xPlayer.getName(),
                color = Colors.orange
            }
        )
    else
        -- Mort par autre chose
        null.logs.send(
            "Mort",
            ("**%s** est mort\n\n**Cause:** %s"):format(xPlayer.getName(), weaponText),
            "mort",
            {
                idunique = xPlayer.getIdunique(),
                name = xPlayer.getName(),
                color = Colors.grey
            }
        )
    end
end)

--[[
    Event: Ban
]]
RegisterNetEvent('null:logs:ban')
AddEventHandler('null:logs:ban', function(targetName, targetId, reason, duration, staffName)
    null.logs.send(
        "Ban",
        ("**%s** a été banni par **%s**\n\n**Raison:** %s\n**Durée:** %s"):format(
            targetName,
            staffName or "Système",
            reason or "Non spécifiée",
            duration or "Permanent"
        ),
        "ban",
        {
            name = targetName,
            idunique = targetId,
            color = Colors.red
        }
    )
end)

--[[
    Event: Unban
]]
RegisterNetEvent('null:logs:unban')
AddEventHandler('null:logs:unban', function(targetName, targetId, staffName)
    null.logs.send(
        "Unban",
        ("**%s** a été débanni par **%s**"):format(targetName, staffName or "Système"),
        "unban",
        {
            name = targetName,
            idunique = targetId,
            color = Colors.green
        }
    )
end)

--[[
    Event: Kick
]]
RegisterNetEvent('null:logs:kick')
AddEventHandler('null:logs:kick', function(targetName, targetId, reason, staffName)
    null.logs.send(
        "Kick",
        ("**%s** a été kick par **%s**\n\n**Raison:** %s"):format(
            targetName,
            staffName or "Système",
            reason or "Non spécifiée"
        ),
        "kick",
        {
            name = targetName,
            idunique = targetId,
            color = Colors.orange
        }
    )
end)

--[[
    Event: Warn
]]
RegisterNetEvent('null:logs:warn')
AddEventHandler('null:logs:warn', function(targetName, targetId, reason, staffName)
    null.logs.send(
        "Warn",
        ("**%s** a reçu un avertissement de **%s**\n\n**Raison:** %s"):format(
            targetName,
            staffName or "Système",
            reason or "Non spécifiée"
        ),
        "warn",
        {
            name = targetName,
            idunique = targetId,
            color = Colors.orange
        }
    )
end)
