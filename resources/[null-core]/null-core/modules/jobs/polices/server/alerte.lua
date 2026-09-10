 RegisterServerEvent('null:police:alert:firelisten')
AddEventHandler('null:police:alert:firelisten', function(gx, gy, gz)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local xPlayers = ESX.GetPlayers()

    for k,v in pairs(xPlayers) do
        local thePlayer = ESX.GetPlayerFromId(v)
        if thePlayer.getGroup() ~= "user" then
            TriggerClientEvent('null:staff:recevieAppelTir',v, {x = gx,y = gy, z = gz})
        end
        if SaveData.json["entreprises"]["Police"][thePlayer.job.name] ~= nil then
            TriggerClientEvent('null:police:listen:fire:blips', v, gx, gy, gz)
        end
    end
end)

RegisterServerEvent('null:police:alert:take')
AddEventHandler('null:police:alert:take', function(gx, gy, gz)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local name = xPlayer.getName(source)
    local xPlayers = ESX.GetPlayers()

    for i = 1, #xPlayers, 1 do
        local thePlayer = ESX.GetPlayerFromId(xPlayers[i])
        if SaveData.json["entreprises"]["Police"][thePlayer.job.name] ~= nil then
            TriggerClientEvent('vPriseAppel', xPlayers[i], name)
        end
    end
end)