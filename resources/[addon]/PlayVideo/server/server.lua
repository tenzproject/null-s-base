RegisterServerEvent('youtube:syncVideo')
AddEventHandler('youtube:syncVideo', function(videoId, mode)
    TriggerClientEvent('youtube:playVideo', -1, videoId, mode)
end)

RegisterServerEvent('youtube:stop')
AddEventHandler('youtube:stop', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getPermission("video") ~= true then return end
    TriggerClientEvent('youtube:playVideo', -1, nil, "stop")
end)

RegisterCommand("stopVideo", function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getPermission("video") ~= true then return end
    TriggerClientEvent('youtube:playVideo', -1, nil, "stop")
end)


RegisterCommand("playsmall", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer.getPermission("video") then return end
    
    if #args < 1 then
        TriggerEvent("chat:addMessage", {
            color = {255, 0, 0},
            args = {"Système", "Utilisation: /playsmall [url youtube]"}
        })
        return
    end
    TriggerServerEvent('youtube:syncVideo', args[1], 'small')
end)

RegisterCommand("playlarge", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer.getPermission("video") then return end
    if #args < 1 then
        TriggerEvent("chat:addMessage", {
            color = {255, 0, 0},
            args = {"Système", "Utilisation: /playlarge [url youtube]"}
        })
        return
    end
    TriggerServerEvent('youtube:syncVideo', args[1], 'large')
end)