RegisterServerEvent('Null:esx_skin:save')
AddEventHandler('Null:esx_skin:save', function(skin)
	local xPlayer = ESX.GetPlayerFromId(source)

	if not xPlayer then
		return
	end

	MySQL.Async.execute('UPDATE users SET skin = @skin WHERE identifier = @identifier', {
		['@skin'] = json.encode(skin),
		['@identifier'] = xPlayer.identifier
	})
end)
ESX.RegisterServerCallback('Null:esx_skin:getPlayerSkin', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if not xPlayer then
		cb(nil, nil)
		return
	end

	MySQL.Async.fetchAll('SELECT skin FROM users WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(users)
		local user, skin = users[1]

		local jobSkin = {
			skin_male = xPlayer.job.skin_male,
			skin_female = xPlayer.job.skin_female
		}

		if user.skin then
			skin = json.decode(user.skin)
		end

		cb(skin, jobSkin)
	end)
end)

ESX.AddGroupCommand('skin', 'superadmin', function(source, args, user)
	if args[1] == nil then
		TriggerClientEvent('Null:openSkinMenu', source)
	else
		TriggerClientEvent('Null:openSkinMenu', args[1])
	end
end, {help = _U('skin')})

AddEventHandler('Null:esx_skin:getPlayerSkinSv', function(identifier, cb)
	MySQL.Async.fetchAll('SELECT skin FROM users WHERE identifier = @identifier', {
		['@identifier'] = identifier
	}, function(users)
		local user, skin = users[1]

		if user.skin then
			skin = json.decode(user.skin)
		end

		cb(skin)
	end)
end)