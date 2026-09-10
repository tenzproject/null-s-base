Citizen.CreateThread(function()
    Wait(2500)
    TriggerServerEvent("null:world:getServerInfo")
end)

RegisterNetEvent("null:world:serverInfo", function(data)
    null.data.server.days = data.day
    null.data.server.mounts = data.mount
    null.data.server.years = data.years
    null.data.server.maxplayers = data.maxplayers
end)