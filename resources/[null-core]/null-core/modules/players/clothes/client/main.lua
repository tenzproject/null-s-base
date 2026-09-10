Citizen.CreateThread(function()
    Wait(4000)
    TriggerServerEvent("RecieveVetement")
end)

RegisterNetEvent("Null:recieveclientsidevetement", function(Info)
    PlayerState.Clothes = Info
end)