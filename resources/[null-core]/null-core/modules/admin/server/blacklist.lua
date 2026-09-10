local blockedPlayers = {}

local function BlockPlayerWeapons(playerId, time)
    blockedPlayers[playerId] = true
    TriggerClientEvent('blacklistgun:toggleBlock', playerId, true)
    if Config.NotifAlert == "chat" then
        TriggerClientEvent('chat:addMessage', playerId, { args = { '[STAFF]', 'Vous venez de vous faire restreindre vos armes' }})
    elseif Config.NotifAlert == "notif" then
        TriggerClientEvent('esx:showNotification', playerId, "Vous venez de vous faire restreindre vos armes")
    end

    if time and time > 0 then
        Citizen.SetTimeout(time * 60000, function()
            if blockedPlayers[playerId] then
                blockedPlayers[playerId] = nil
                TriggerClientEvent('blacklistgun:toggleBlock', playerId, false)
            end
        end)
    end
end

local function UnblockPlayerWeapons(playerId)
    if blockedPlayers[playerId] then
        blockedPlayers[playerId] = nil
        TriggerClientEvent('blacklistgun:toggleBlock', playerId, false)
        if Config.NotifAlert == "chat" then
            TriggerClientEvent('chat:addMessage', playerId, { args = { '[STAFF]', 'Votre restriction vient de se terminé' }})
        elseif Config.NotifAlert == "notif" then
            TriggerClientEvent('esx:showNotification', playerId, "Votre restriction vient de se terminé")
        end
    end
end

RegisterCommand("blweapon", function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if Config.GroupeHighPerm[xPlayer.getGroup()] then
        local targetId = tonumber(args[1])
        local time = tonumber(args[2])

        if targetId and GetPlayerPing(targetId) > 0 then
            BlockPlayerWeapons(targetId, time)
            TriggerClientEvent('chat:addMessage', source, { args = { '[SYSTEM]', 'Le joueur ' .. targetId .. ' a maintenant ses armes restreinte pendant ' .. (time or 'indefinite') .. ' minutes.' }})
        else
            TriggerClientEvent('chat:addMessage', source, { args = { '[SYSTEM]', 'ID Du joueur invalide.' }})
        end
    else
        TriggerClientEvent('chat:addMessage', source, { args = { '[SYSTEM]', 'Vous ne possèdez pas les permissions suffisante pour utilisez cette commande.' }})
    end
end, false)

RegisterCommand("unblweapon", function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        local targetId = tonumber(args[1])

        if targetId and GetPlayerPing(targetId) > 0 then
            UnblockPlayerWeapons(targetId)
            TriggerClientEvent('chat:addMessage', source, { args = { '[SYSTEM]', 'Le joueur ' .. targetId .. ' est maintenant plus restricter.' }})
        else
            TriggerClientEvent('chat:addMessage', source, { args = { '[SYSTEM]', 'ID Du joueur invalide.' }})
        end
    else
        TriggerClientEvent('chat:addMessage', source, { args = { '[SYSTEM]', 'Vous ne possèdez pas les permissions suffisante pour utilisez cette commande.' }})
    end
end, false)