IsRagdollPut = false

RegisterCommand('+ragdoll', function()
    if PlayerState.isInVehicle then return end
    IsRagdollPut = not IsRagdollPut
    while IsRagdollPut do
        Wait(0)
        local plyPed = PlayerPedId()
        local entityAlpha = GetEntityAlpha(PlayerPedId())
        if entityAlpha < 100 then
            Citizen.Wait(0)
        else
            if IsRagdollPut and IsControlJustReleased(1, 22) or IsRagdollPut and IsControlJustReleased(1, 51) then
                IsRagdollPut = not IsRagdollPut
                break
            end
            if IsRagdollPut then
                SetPedRagdollForceFall(plyPed)
                ResetPedRagdollTimer(PlayerPedId())
                SetPedToRagdoll(PlayerPedId(), 1000, 1000, 3, 0, 0, 0)
                ResetPedRagdollTimer(PlayerPedId())
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ ou ~INPUT_JUMP~ pour ~g~vous relever~s~.")
            end
        end    
    end
end, false)
RegisterKeyMapping('+ragdoll', 'S\'endormir / se réveiller', 'keyboard', 'j')