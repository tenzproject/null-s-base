ShopEMS = {
    {name = "bandage", label = "Bandage", price = 50},
    {name = "medikit", label = "Kit de soin", price = 75}
}

RegisterNetEvent("Null:UseItemsEMS")
AddEventHandler("Null:UseItemsEMS", function(itemname, number, timetowait)
    if timetowait == nil then timetowait = 5000 end
    local lib, anim = 'anim@heists@narcotics@funding@gang_idle', 'gang_chatting_idle01' -- TODO better animations
    local playerPed = PlayerPedId()
    ESX.Streaming.RequestAnimDict(lib, function()
        TaskPlayAnim(playerPed, lib, anim, 8.0, -8.0, -1, 0, 0, false, false, false)
        FreezeEntityPosition(PlayerPedId(), true)
        ShowProgressBar(timetowait,"Appliquage des soins")
        Wait(timetowait) 
        SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) + number)  

        FreezeEntityPosition(PlayerPedId(), false)
        
        ClearPedTasksImmediately(PlayerPedId())
    end)
end)

