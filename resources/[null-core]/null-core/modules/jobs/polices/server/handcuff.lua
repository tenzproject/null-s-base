

AddEventHandler('esx:playerLoaded', function(source, xPlayer)
	xPlayer.set('cuffState', {isCuffed = false, cuffMethod = nil})
end)

RegisterServerEvent('null:handcuff:handcuff')
AddEventHandler('null:handcuff:handcuff', function(target, wannacuff, method)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xPlayerTarget = ESX.GetPlayerFromId(target)
	local targetCuff = xPlayerTarget.get('cuffState')
	if targetCuff == nil then
		targetCuff = {isCuffed = false, cuffMethod = nil}
		xPlayerTarget.set('cuffState', targetCuff)
	end
	local dist = #(xPlayer.getCoords(true) - xPlayerTarget.getCoords(true))

	if target == -1 then
		ExecuteCommand("ban " .. source .. " 0 Tentative de triche handcuff (0)")
	else
		if dist < 30 then
			if wannacuff then
				if not targetCuff.isCuffed then
					if method == 'policecuff' then
						TriggerClientEvent('null:handcuff:arresting', xPlayer.source)
						TriggerClientEvent('null:handcuff:thecuff', target, true, xPlayer.source)
						xPlayerTarget.set('cuffState', {isCuffed = true, cuffMethod = method})
					elseif method == 'basiccuff' then
						TriggerClientEvent('null:handcuff:arresting', xPlayer.source)
						TriggerClientEvent('null:handcuff:thecuff', target, true, xPlayer.source)
						xPlayerTarget.set('cuffState', {isCuffed = true, cuffMethod = method})
					end
				end
			elseif not wannacuff then
				if targetCuff.isCuffed then
					if (method == targetCuff.cuffMethod) or (method == 'all') then
						TriggerClientEvent('null:handcuff:unarresting', xPlayer.source)
						TriggerClientEvent('null:handcuff:thecuff', target, false)
						xPlayerTarget.set('cuffState', {isCuffed = false, cuffMethod = nil})
					else
						TriggerClientEvent('esx:showNotification', xPlayer.source, 'Vous ne pouvez démenottez cette personne')
					end
				else
					TriggerClientEvent('esx:showNotification', xPlayer.source, 'Vous ne pouvez démenottez cette personne')
				end
			end
		else
			ExecuteCommand("ban " .. source .. " 0 Tentative de triche handcuff (1)")
		end
	end
end)

ESX.RegisterUsableItem('basic_cuff', function(source)
	TriggerClientEvent('null:handcuff:cbClosestPlayerID', source, true, 'basiccuff')
end)

ESX.RegisterUsableItem('basic_key', function(source)
	TriggerClientEvent('null:handcuff:cbClosestPlayerID', source, false, 'basiccuff')
end)

ESX.RegisterUsableItem('police_cuff', function(source)
	TriggerClientEvent('null:handcuff:cbClosestPlayerID', source, true, 'policecuff')
end)

ESX.RegisterUsableItem('police_key', function(source)
	TriggerClientEvent('null:handcuff:cbClosestPlayerID', source, false, 'policecuff')
end)

ESX.RegisterUsableItem('lockpick', function(source)
	TriggerClientEvent('null:handcuff:cbClosestPlayerID', source, false, 'all')
end)

-- Unhandcuff
ESX.AddGroupCommand('demenotter', "admin", function(source, args, user)
	local xPlayer

	if args[1] then
		xPlayer = ESX.GetPlayerFromId(args[1])
	else
		xPlayer = ESX.GetPlayerFromId(source)
	end

	if xPlayer then
		xPlayer.triggerEvent('null:handcuff:thecuff', false)
		xPlayer.set('cuffState', {isCuffed = false, cuffMethod = nil})
	else
		ESX.ChatMessage(source, 'Player not online.')
	end
end, {help = "Se démenotter en urgence", params = { {name = "userid", help = "The ID of the player"}, {name = "reason", help = "The reason as to why you kick this player"} }})