local nightvision = true

RegisterNetEvent('null:nightvision:put')
AddEventHandler('null:nightvision:put', function()
    if not nightvision then
        SetNightvision(false)
        TriggerEvent('Null:skinchanger:change', 'helmet_1', -1)
        
        nightvision = true
    else
        SetNightvision(true)
        TriggerEvent('Null:skinchanger:change', 'helmet_1', 118)
        nightvision = false
    end
end)