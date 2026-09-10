ESX.RegisterUsableItem('parachute', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	local playerPed = GetPlayerPed(-1)
    if not xPlayer.hasWeapon("GADGET_PARACHUTE") then 
        local tinit, model = 0, nil
        if GetVIP(xPlayer.identifer) then
            --tinit = 10
            --model = "pil_p_para_pilot_sp_s"
        end
        TriggerClientEvent("null:setInParachute", source, tinit, model)

        xPlayer.removeInventoryItem("parachute", 1)

        TriggerClientEvent('esx:showNotification', source, 'Parachute équiper')
    end
end)