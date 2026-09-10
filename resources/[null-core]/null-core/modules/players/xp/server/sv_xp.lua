--[[AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    MySQL.Async.fetchAll('SELECT * FROM users WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    }, function(result)
        TriggerClientEvent('XNL_NET:XNL_SetInitialXPLevels', xPlayer.source, tonumber(result[1].xp), true, true)
    end)
end)
 
-- AC here for later
RegisterNetEvent("XNL_SAVE:3ktWUdgNkuyy6v7WLR7KBX")
AddEventHandler("XNL_SAVE:3ktWUdgNkuyy6v7WLR7KBX", function (xpBase, nbRxP)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    MySQL.Async.execute("UPDATE users SET xp = @xp WHERE identifier = @identifier", {["@identifier"] = xPlayer.identifier, ['xp'] = nbRxP})
end)

RegisterServerEvent("XNL_NET:AddPlayerXP")
AddEventHandler("XNL_NET:AddPlayerXP", function(xp)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    TriggerClientEvent("XNL_NET:AddPlayerXP", src, xp)
    MySQL.Async.execute("UPDATE users SET xp = xp + @xp WHERE identifier = @identifier", {["@xp"] = xp, ["@identifier"] = xPlayer.identifier}, function() end)
end)]]