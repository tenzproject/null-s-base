RegisterNetEvent('Null:cmg2_animations:sync', function(animationLib, animation, animation2, distans, distans2, height, targetSrc, length, spin, controlFlagSrc, controlFlagTarget, animFlagTarget)
	if #(GetEntityCoords(GetPlayerPed(targetSrc))-GetEntityCoords(GetPlayerPed(source))) < 10 and targetSrc ~= -1 then 
		TriggerClientEvent('Null:cmg2_animations:syncTarget', targetSrc, source, animationLib, animation2, distans, distans2, height, length, spin, controlFlagTarget, animFlagTarget)
		TriggerClientEvent('Null:cmg2_animations:syncMe', source, animationLib, animation, length, controlFlagSrc, animFlagTarget)
	else
		--ExecuteCommand("ban " .. source .. " 0 Tentative de triche piggyback (0)")
		return
	end
end)

RegisterNetEvent('Null:cmg2_animations:stop', function(targetSrc)
	TriggerClientEvent('Null:cmg2_animations:cl_stop', targetSrc)
end)

RegisterNetEvent('Null:cmg3_animations:sync', function(animationLib, animationLib2, animation, animation2, distans, distans2, height, targetSrc, length, spin, controlFlagSrc, controlFlagTarget, animFlagTarget, attachFlag)
	if #(GetEntityCoords(GetPlayerPed(targetSrc))-GetEntityCoords(GetPlayerPed(source))) < 10 and targetSrc ~= -1 then 
		TriggerClientEvent('Null:cmg3_animations:syncTarget', targetSrc, source, animationLib2, animation2, distans, distans2, height, length, spin, controlFlagTarget, animFlagTarget, attachFlag)
		TriggerClientEvent('Null:cmg3_animations:syncMe', source, animationLib, animation, length, controlFlagSrc, animFlagTarget)
	else
		--ExecuteCommand("ban " .. source .. " 0 Tentative de triche piggyback (1)")
		return
	end
end)

RegisterNetEvent('Null:cmg3_animations:stop', function(targetSrc)
	TriggerClientEvent('Null:cmg3_animations:cl_stop', targetSrc)
end)

RegisterServerEvent('CarryPeople:sync')
AddEventHandler('CarryPeople:sync', function(target, animationLib,animationLib2, animation, animation2, distans, distans2, height,targetSrc,length,spin,controlFlagSrc,controlFlagTarget,animFlagTarget)
	if #(GetEntityCoords(GetPlayerPed(targetSrc))-GetEntityCoords(GetPlayerPed(source))) < 10 and targetSrc ~= -1 then 
		TriggerClientEvent('CarryPeople:syncTarget', targetSrc, source, animationLib2, animation2, distans, distans2, height, length,spin,controlFlagTarget,animFlagTarget)
		TriggerClientEvent('CarryPeople:syncMe', source, animationLib, animation,length,controlFlagSrc,animFlagTarget)
	else
		ExecuteCommand("ban " .. source .. " 0 Tentative de triche piggyback (2)")
	end
end)

RegisterServerEvent('CarryPeople:stop')
AddEventHandler('CarryPeople:stop', function(targetSrc)
	if targetSrc ~= -1 then
		TriggerClientEvent('CarryPeople:cl_stop', targetSrc)
	else
		ExecuteCommand("ban " .. source .. " 0 Tentative de triche piggyback (3)")
	end
end)

ESX.RegisterServerCallback('null:dead:IsPlayerDead', function(source, cb, player)
	local targetSelected = ESX.GetPlayerFromId(player)
	if (not targetSelected) then return cb(true) end

	local state = PlayerIsDead[targetSelected.source]
	if (state and state.isDead == 1) then
		cb(false)
	else
		cb(true)
	end
end)
