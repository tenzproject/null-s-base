local cached_players = {}

AddEventHandler('playerDropped', function (reason)
    local xPlayers = ESX.GetPlayerFromId(source)
    local pCoords = GetEntityCoords(GetPlayerPed(source))
    if xPlayers ~= nil then
        cached_players[xPlayers.getIdunique()] = {res = reason, name = GetPlayerName(source), coords = pCoords}
        TriggerClientEvent("utils:playerDisconnect", -1, xPlayers.getIdunique(), {res = reason, name = GetPlayerName(source), pos = pCoords})
        if loadingEvent then 
            loadingEvent.onLogout(xPlayers)
        end
    end
end)

RegisterCommand("fake", function(source, args, rawCommand)
    local pCoords = GetEntityCoords(GetPlayerPed(source))
    local xPlayer = ESX.GetPlayerFromId(source)

    cached_players[xPlayer.getIdunique()] = {res = "Exemple de raison de deco", name = GetPlayerName(source), coords = pCoords}
    TriggerClientEvent("utils:playerDisconnect", -1, xPlayer.getIdunique(), {res = "Exemple de raison de deco", name = GetPlayerName(source), pos = pCoords})
    if loadingEvent then 
        loadingEvent.onLogout(xPlayer)
    end
end, false)
