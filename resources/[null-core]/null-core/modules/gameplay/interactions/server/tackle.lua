RegisterServerEvent('esx:tackle:tryTackle')
AddEventHandler('esx:tackle:tryTackle', function(target)
    if target ~= -1 and #(GetEntityCoords(GetPlayerPed(source))-GetEntityCoords(GetPlayerPed(target))) < 10 then 
        TriggerClientEvent('esx:tackle:getTackled', target, source)
        TriggerClientEvent('esx:tackle:playTackle', source)
    end
end)