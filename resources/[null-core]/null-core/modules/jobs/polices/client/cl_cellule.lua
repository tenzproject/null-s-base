local JAIL_MESSAGE = nil
RegisterNetEvent("Null:setTimerPrison")
AddEventHandler("Null:setTimerPrison", function(timer, code, cellulepos)
    ESX.ShowNotification("Vous êtes en prison pendant ~p~"..timer.." secondes~s~ vous serez remis dehors automatiquement si vous ne vous déconnectez pas")
    while true do
        if timer > 1 then
            local distance = math.floor(Distance3d(PlayerState.coords, cellulepos))
            if distance >= 3 then 
                SetEntityCoords(PlayerState.ped, cellulepos) 
            end
            if PlayerState.weapon ~= `WEAPON_UNARMED` then 
                SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
                null.DebugPrint("police prison, set unarmed")
            end
            timer = timer - 1
            time = TimerBar(timer)
            ShowInfo(
                "Information Prison",  
                {
                    {left = "Mis par", right = "Police", color = "rgb(0, 0, 255)"},
                    {left = "Temps restant", right = ("%s heures"):format(time[1]..':'..time[2]..':'..time[3]), color = "rgb(255, 255, 255)"},
                }
            )
            TriggerServerEvent("Null:updatetimerprison", timer, code)
        else
            break
        end
        Wait(1000)
    end
    HideInfo()
end)

RegisterNetEvent("Null:gooutjail")
AddEventHandler("Null:gooutjail", function(timer, code)
    HideInfo()
end)