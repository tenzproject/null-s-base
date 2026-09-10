local PlayerInKO = false
Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while PlayerState == nil do Wait(10) end
    local wait = 15
    local count = 60

    while true do
        SetPedConfigFlag(PlayerState.ped, 35, false)
        SetPedConfigFlag(PlayerState.ped, 149, true)
        SetPedConfigFlag(PlayerState.ped, 438, true)

        if IsPedInMeleeCombat(PlayerState.ped) then
            if GetEntityHealth(PlayerState.ped) < 115 then
                ESX.ShowNotification("Tu viens de te faire assomé ! Patiente un peu.")
                wait = 15
                PlayerInKO = true
                SetEntityHealth(PlayerState.ped, 116)
            end
        end

        if PlayerInKO then
            SetPlayerInvincible(PlayerState.playerId, true)
            DisablePlayerFiring(PlayerState.playerId, true)
            SetPedToRagdoll(PlayerState.ped, 1000, 1000, 0, 0, 0, 0)
            ResetPedRagdollTimer(PlayerState.ped)
                
            if wait >= 0 then
                count = count - 1

                if count == 0 then
                    count = 60
                    wait = wait - 1
                    SetEntityHealth(PlayerState.ped, GetEntityHealth(PlayerState.ped) + 4)
                end
            else
                SetPlayerInvincible(PlayerState.playerId, false)
                PlayerInKO = false
            end
        end

        if IsPedInMeleeCombat(PlayerState.ped) or PlayerInKO then 
            Wait(0)
        else
            Wait(750)
        end
        
    end
end))
