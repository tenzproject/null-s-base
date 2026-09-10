-- COMMAND HANDLER --
local lastCommands = {}
AddEventHandler('chatMessage', function(source, author, message)
	if message == nil or message == "" then return end
	
	if (message):find(Config.CommandPrefix) ~= 1 then
		return
	end

	local commandArgs = ESX.StringSplit(((message):sub((Config.CommandPrefix):len() + 1)), ' ')
	local commandName = (table.remove(commandArgs, 1)):lower()
	local command = ESX.Commands[commandName]

	if command then
		CancelEvent()
		if lastCommands[source] == nil then
			lastCommands[source] = {}
		else
			if lastCommands[source][commandName] ~= nil and (os.time() - lastCommands[source][commandName]) < 1 then
				return
			else
				lastCommands[source][commandName] = nil
			end
		end
		local xPlayer = ESX.GetPlayerFromId(source)
		if command.group ~= nil then
			--if ESX.Groups[xPlayer.getGroup()]:canTarget(ESX.Groups[command.group]) then
			if ESX.GroupeHavePermission(ESX.Groups[xPlayer.getGroup()], ESX.Groups[command.group]) then
				if (command.arguments > -1) and (command.arguments ~= #commandArgs) then
					TriggerEvent("esx:incorrectAmountOfArguments", source, command.arguments, #commandArgs)
				else
					lastCommands[source][commandName] = os.time()
					command.callback(source, commandArgs, xPlayer)
				end
			else
				ESX.ChatMessage(source, 'Permissions Insuffisantes !')
			end
		else
			if (command.arguments > -1) and (command.arguments ~= #commandArgs) then
				TriggerEvent("esx:incorrectAmountOfArguments", source, command.arguments, #commandArgs)
			else
				lastCommands[source][commandName] = os.time()
				command.callback(source, commandArgs, xPlayer)
			end
		end
	end
end)

function ESX.AddCommand(command, callback, suggestion, arguments)
	ESX.Commands[command] = {}
	ESX.Commands[command].group = nil
	ESX.Commands[command].callback = callback
	ESX.Commands[command].arguments = arguments or -1

	if type(suggestion) == 'table' then
		if type(suggestion.params) ~= 'table' then
			suggestion.params = {}
		end

		if type(suggestion.help) ~= 'string' then
			suggestion.help = ''
		end

		table.insert(ESX.CommandsSuggestions, {name = ('%s%s'):format(Config.CommandPrefix, command), help = suggestion.help, params = suggestion.params})
	end
end

function ESX.AddGroupCommand(command, group, callback, suggestion, arguments)
	ESX.Commands[command] = {}
	ESX.Commands[command].group = group
	ESX.Commands[command].callback = callback
	ESX.Commands[command].arguments = arguments or -1

	if type(suggestion) == 'table' then
		if type(suggestion.params) ~= 'table' then
			suggestion.params = {}
		end

		if type(suggestion.help) ~= 'string' then
			suggestion.help = ''
		end

		table.insert(ESX.CommandsSuggestions, {name = ('%s%s'):format(Config.CommandPrefix, command), help = suggestion.help, params = suggestion.params})
	end
end

function ESX.RegisterCommand(command, group, callback, suggestion, arguments)
	ESX.Commands[command] = {}
	ESX.Commands[command].group = group
	ESX.Commands[command].callback = callback
	ESX.Commands[command].arguments = arguments or -1

	if type(suggestion) == 'table' then
		if type(suggestion.params) ~= 'table' then
			suggestion.params = {}
		end

		if type(suggestion.help) ~= 'string' then
			suggestion.help = ''
		end

		table.insert(ESX.CommandsSuggestions, {name = ('%s%s'):format(Config.CommandPrefix, command), help = suggestion.help, params = suggestion.params})
	end
end


ESX.AddGroupCommand('pos', 'admin', function(source, args, user)
	local x, y, z = tonumber(args[1]), tonumber(args[2]), tonumber(args[3])
	
	if x and y and z then
		TriggerClientEvent('esx:teleport', source, vector3(x, y, z))
	else
		ESX.ChatMessage(source, "Invalid coordinates!")
	end
end, {help = "Teleport to coordinates", params = {
	{name = "x", help = "X coords"},
	{name = "y", help = "Y coords"},
	{name = "z", help = "Z coords"}
}})

ESX.AddGroupCommand('setjob', 'superadmin', function(source, args, user)
	if tonumber(args[1]) and args[2] and tonumber(args[3]) then
		--local xPlayer = ESX.GetPlayerFromId(args[1])
		local xPlayer = ESX.GetPlayerFromIdUnique(args[1])
		local xPlayer2 = ESX.GetPlayerFromId(source)

		if xPlayer then
			if ESX.DoesJobExist(args[2], args[3]) then
				xPlayer.setJob(args[2], args[3])
				null.logs.job("setjob", xPlayer, args[2], args[3], xPlayer2)
			else
				ESX.ChatMessage(source, 'Le job ou grade existe pas')
			end
		else
			ESX.ChatMessage(source, 'Le joueur est déconecter')
		end
	else
		ESX.ChatMessage(source, 'Commande invalide')
	end
end, {help = _U('setjob'), params = {
	{name = "Id Unique", help = _U('id_param')},
	{name = "job", help = _U('setjob_param2')},
	{name = "grade_id", help = _U('setjob_param3')}
}})

ESX.AddGroupCommand('setjob2', 'superadmin', function(source, args, user)
	if tonumber(args[1]) and args[2] and tonumber(args[3]) then
		--local xPlayer = ESX.GetPlayerFromId(args[1])
		local xPlayer = ESX.GetPlayerFromIdUnique(args[1])
		local xPlayer2 = ESX.GetPlayerFromId(source)

		if xPlayer then
			if ESX.DoesJobExist(args[2], args[3]) then
				xPlayer.setJob2(args[2], args[3])
				null.logs.job("setjob2", xPlayer, args[2], args[3], xPlayer2)
			else
				ESX.ChatMessage(source, 'Le job ou grade existe pas')
			end
		else
			ESX.ChatMessage(source, 'Le joueur est déconecter.')
		end
	else
		ESX.ChatMessage(source, 'Commande Invalide')
	end
end, {help = _U('setjob'), params = {
	{name = "Id Unique", help = _U('id_param')},
	{name = "job2", help = _U('setjob_param2')},
	{name = "grade_id", help = _U('setjob_param3')}
}})


ESX.AddGroupCommand('giveitem', 'helper', function(source, args, user)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getPermission("give_item") ~= true then return end
	local xTarget = ESX.GetPlayerFromIdUnique(args[1])

	if xTarget then
		local item = args[2]
		local count = tonumber(args[3])

		if count then
			if ESX.Items[item] then
				if not xPlayer.getPermission("give_item_boutique") then
					if ESX.ContribItem(item) then
						return
					end
				end
				xTarget.addInventoryItem(item, count)
				null.logs.item("give", xPlayer, ESX.GetItemLabel(item), count, xTarget)
			else
				xTarget.showNotification(_U('invalid_item'))
			end
		else
			xTarget.showNotification(_U('invalid_amount'))
		end
	else
		ESX.ChatMessage(source, 'Le joueur est déconecter.')
	end
end, {help = _U('giveitem'), params = {
	{name = "Id Unique", help = _U('id_param')},
	{name = "item", help = _U('item')},
	{name = "amount", help = _U('amount')}
}})

ESX.AddGroupCommand('giveweapon', 'helper', function(source, args, user)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getPermission("give_weapon") ~= true then return end
	local xTarget = ESX.GetPlayerFromIdUnique(args[1])
	

	if xTarget then
		local weaponName = args[2] or 'unknown'

		if ESX.GetWeapon(weaponName) then
			if xTarget.hasWeapon(weaponName) then
				ESX.ChatMessage(source, 'Le joueur a déjà cette arme sur lui.')
			else
				if not xPlayer.getPermission("give_weapon_boutique") then
					if ESX.ContribWeapon(weaponName) then
						return
					end
				end
				xTarget.addWeapon(weaponName, tonumber(args[3]))
				
				null.logs.weapon("give", xPlayer, ESX.GetWeaponLabel(weaponName), xTarget)
			end
		else
			ESX.ChatMessage(source, 'Le nom de l\'arme est invalide.')
		end
	else
		ESX.ChatMessage(source, 'Le joueur est déconecter.')
	end
end, {help = _U('giveweapon'), params = {
	{name = "ID Unique", help = _U('id_param')},
	{name = "weaponName", help = _U('weapon')},
	{name = "ammo", help = _U('amountammo')}
}})

--[[ESX.AddGroupCommand('giveweaponcomponent', 'fondateur', function(source, args, user)
	local xPlayer2 = ESX.GetPlayerFromId(source)
	local xPlayer = ESX.GetPlayerFromIdUnique(args[1])

	if xPlayer then
		local weaponName = args[2] or 'unknown'

		if ESX.GetWeapon(weaponName) then
			if xPlayer.hasWeapon(weaponName) then
				local component = ESX.GetWeaponComponent(weaponName, args[3] or 'unknown')

				if component then
					if xPlayer.hasWeaponComponent(weaponName, args[3]) then
						ESX.ChatMessage(source, 'Le joueur a déjà cet accessoire sur lui.')
					else
						xPlayer.addWeaponComponent(weaponName, args[3])
						null.logs.adminCommand("giveweaponcomponent", xPlayer2, xPlayer, args[3].." sur "..weaponName)
					end
				else
					ESX.ChatMessage(source, 'Invalid weapon component.')
				end
			else
				ESX.ChatMessage(source, 'Le joueur ne possède pas cette arme')
			end
		else
			ESX.ChatMessage(source, 'Arme inexistante')
		end
	else
		ESX.ChatMessage(source, 'Le joueur est déconecter.')
	end
end, {help = 'Give weapon component', params = {
	{name = 'Id Unique', help = _U('id_param')},
	{name = 'weaponName', help = _U('weapon')},
	{name = 'componentName', help = 'weapon component'}
}})]]

RegisterCommand("clear", function(source)
	if (source == 0) then
		TriggerClientEvent('chat:clear', -1)
	else
		local playerSelected = ESX.GetPlayerFromId(source)
		if (not playerSelected) then return end

		if (playerSelected.getGroup() == "fondateur" or playerSelected.getGroup() == "responsable") then
			TriggerClientEvent("chat:clear", -1)
			null.logs.adminCommand("clear", playerSelected)
		else
			return ESX.ChatMessage(source, "~r~Vous n'avez pas la permission d'utiliser la commande.")
		end
	end
end)

RegisterCommand("clearchat", function(source)
	if (source == 0) then
		TriggerClientEvent('chat:clear', -1)
	else
		local playerSelected = ESX.GetPlayerFromId(source)
		if (not playerSelected) then return end

		if (playerSelected.getGroup() == "fondateur" or playerSelected.getGroup() == "responsable") then
			TriggerClientEvent("chat:clear", -1)
			null.logs.adminCommand("clear", playerSelected)
		else
			return ESX.ChatMessage(source, "~r~Vous n'avez pas la permission d'utiliser la commande.")
		end
	end
end)


ESX.AddGroupCommand('clearinventory', 'fondateur', function(source, args, user)
	local xPlayer = nil
	local xPlayer2 = ESX.GetPlayerFromId(source)
	if args[1] then
		--local xPlayer = ESX.GetPlayerFromId(args[1])
		local xPlayer = ESX.GetPlayerFromIdUnique(args[1])
		--xPlayer = ESX.GetPlayerFromId(args[1])
	else
		xPlayer = ESX.GetPlayerFromId(source)
	end

	if xPlayer then
		for i = 1, #xPlayer.inventory, 1 do
			if xPlayer.inventory[i].count > 0 then
				xPlayer.setInventoryItem(xPlayer.inventory[i].name, 0)
			end
		end
		null.logs.adminCommand("clearinventory", xPlayer2, xPlayer)
	else
		ESX.ChatMessage(source, 'Le joueur est déconecter')
	end
end, {help = _U('command_clearinventory'), params = {
	{name = "Id Unique", help = _U('command_playerid_param')}
}})

ESX.AddGroupCommand('clearloadout', 'fondateur', function(source, args, user)

	local xPlayer = nil
	local xPlayer2 = ESX.GetPlayerFromId(source)
	if args[1] then
		local xPlayer = ESX.GetPlayerFromIdUnique(args[1])
		--xPlayer = ESX.GetPlayerFromId(args[1])
	else
		xPlayer = ESX.GetPlayerFromId(source)
	end

	if xPlayer then
		for i = #xPlayer.loadout, 1, -1 do
			xPlayer.removeWeapon(xPlayer.loadout[i].name)
		end
		null.logs.adminCommand("clearloadout", xPlayer2, xPlayer)
	else
		ESX.ChatMessage(source, 'Le joueur est déconecter')
	end
end, {help = _U('command_clearloadout'), params = {
	{name = "Id Unique", help = _U('command_playerid_param')}
}})

local listwhitelist = {
    {model = "sanchez"},
    {model = "panto"},
    {model = "sultan"},
    {model = "sanchez2"},
    {model = "blista"},
    {model = "cliffhanger"},
}

ESX.AddGroupCommand('car', 'helper', function(source, args, user)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() == 'helper' or xPlayer.getGroup() == 'mod' or xPlayer.getGroup() == 'admin' then 
		if args[1] then
			for k, v in pairs(listwhitelist) do
				if args[1] == v.model then
					if args[2] then
						local xTarget = ESX.GetPlayerFromIdUnique(args[2])
						TriggerClientEvent('esx:spawnVehicleLocal_client', xTarget.source, args[1], GetEntityCoords(GetPlayerPed(xTarget.source)))
						null.logs.vehicle("spawn", xPlayer, args[1])
					else
						TriggerClientEvent('esx:spawnVehicleLocal_client', source, args[1], GetEntityCoords(GetPlayerPed(source)))
						null.logs.vehicle("spawn", xPlayer, args[1])
					end
				end
			end
		else
			ESX.ChatMessage(source, 'Mauvaise formulation')
		end
	else
		if args[1] then
			if args[2] then
				xTarget = ESX.GetPlayerFromIdUnique(args[2])
				TriggerClientEvent('esx:spawnVehicleLocal_client', source, args[1], GetEntityCoords(GetPlayerPed(xTarget.id)))
			else
				TriggerClientEvent('esx:spawnVehicleLocal_client', source, args[1], GetEntityCoords(GetPlayerPed(source)))
			end
			null.logs.vehicle("spawn", xPlayer, args[1])
		else
			ESX.ChatMessage(source, 'Mauvaise formulation')
		end
	end
end, {help = _U('spawn_car'), params = {
    {name = "car", help = _U('spawn_car_param')},
	{name = "id", help = _U('spawn_car_param2')}
}})

ESX.AddGroupCommand('dv', 'helper', function(source, args, user)
	local xPlayer = ESX.GetPlayerFromId(source)
	if args[1] == nil then args[1] = 1 end
	TriggerClientEvent('esx:deleteVehicle', source, args[1])
	null.logs.vehicle("delete", xPlayer, "radius: "..args[1])
end, {help = _U('delete_vehicle'), params = {
	{name = 'radius', help = 'Optional, delete every vehicle within the specified radius'}
}})


ESX.AddGroupCommand('extras', 'admin', function(source, args, user)
	TriggerClientEvent("null:client:openExtrasMenu", source)
end, {help = "Ouvrir le menu Extras Véhicule"})


ESX.AddGroupCommand('adminprops', 'superadmin', function(source, args, user)
    TriggerClientEvent("props:client:useProp", source, true)
end)