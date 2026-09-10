RegisterServerEvent('Null:esx_billing:sendBill')
AddEventHandler('Null:esx_billing:sendBill', function(target, sharedAccountName, label, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xTarget = ESX.GetPlayerFromId(target)
	amount = ESX.Math.Round(amount)

	if amount < 0 or amount > 25000000 then
		print(('esx_billing: %s attempted to send a negative bill!'):format(xPlayer.identifier))
	else
		if xTarget ~= nil then
			if target == source or xPlayer.job.name ~= 'unemployed' and #(GetEntityCoords(GetPlayerPed(source))-GetEntityCoords(GetPlayerPed(target))) < 15 then 
				MySQL.Async.execute('INSERT INTO billing (identifier,date, sender, target_type, target, label, amount) VALUES (@identifier,@date, @sender, @target_type, @target, @label, @amount)', {
					['@identifier'] = xTarget.identifier,
					['@sender'] = xPlayer.identifier,
					['@target_type'] = 'society',
					['@target'] = xPlayer.job.name,
					['@label'] = label,
					['@date'] = os.date('%Y-%m-%d %H:%M:%S'),
					['@amount'] = amount
				}, function(rowsChanged)
					TriggerClientEvent('esx:showNotification', target, 'vous avez reçu une facture')
					TriggerClientEvent('Null:esx_billing:newBill', target)
					sendToDiscord('LOGS', '[FACTURE] ' ..xPlayer.getName().. ' viens de donner une facture à l\'ID : ' ..target.. ' montant : ' ..amount.. '', 3145658)

				end)
			end
		end
	end
end)

function SendBill(sender, recevier, target, amount, label)
	local xTarget = ESX.GetPlayerFromId(target)
	amount = ESX.Math.Round(amount)

	if amount < 0 then
		print(('esx_billing: %s attempted to send a negative bill!'):format(xPlayer.identifier))
	else
		if xTarget ~= nil then
			MySQL.Async.execute('INSERT INTO billing (identifier,date, sender, target_type, target, label, amount) VALUES (@identifier,@date, @sender, @target_type, @target, @label, @amount)', {
				['@identifier'] = xTarget.identifier,
				['@sender'] = sender,
				['@target_type'] = 'society',
				['@target'] = recevier,
				['@label'] = label,
				['@date'] = os.date('%Y-%m-%d %H:%M:%S'),
				['@amount'] = amount
			}, function(rowsChanged)
				TriggerClientEvent('esx:showNotification', target, 'vous avez reçu une facture')
				TriggerClientEvent('Null:esx_billing:newBill', target)
			end)
		end
	end
end

ESX.RegisterServerCallback('Null:esx_billing:getBills', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM billing WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		local bills = {}

		for i = 1, #result, 1 do
			table.insert(bills, {
				id = result[i].id,
				identifier = result[i].identifier,
				sender = result[i].sender,
				targetType = result[i].target_type,
				target = result[i].target,
				label = result[i].label,
				amount = result[i].amount
			})
		end

		cb(bills)
	end)
end)

ESX.RegisterServerCallback('Null:esx_billing:getTargetBills', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)

	MySQL.Async.fetchAll('SELECT * FROM billing WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		local bills = {}

		for i = 1, #result, 1 do
			table.insert(bills, {
				id = result[i].id,
				identifier = result[i].identifier,
				sender = result[i].sender,
				targetType = result[i].target_type,
				target = result[i].target,
				label = result[i].label,
				amount = result[i].amount
			})
		end

		cb(bills)
	end)
end)

ESX.RegisterServerCallback('Null:esx_billing:payBill', function(source, cb, id)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM billing WHERE id = @id', {
		['@id'] = id
	}, function(result)
		if not result[1] then 
			cb()
			return 
		end
		local sender = result[1].sender
		local targetType = result[1].target_type
		local target = result[1].target
		local amount = result[1].amount
		local xTarget = ESX.GetPlayerFromIdentifier(sender)

		if targetType == 'player' then
			if xTarget ~= nil then
				if xPlayer.getAccount('bank').money >= amount then
					MySQL.Async.execute('DELETE from billing WHERE id = @id', {
						['@id'] = id
					}, function(rowsChanged)
						xPlayer.removeAccountMoney('bank', amount, {title = 'Paiement Facture', description = 'Facture payée à un joueur', category = 'fine'})
						xTarget.addAccountMoney('bank', amount, {title = 'Paiement Reçu', description = 'Facture payée par un joueur', category = 'salary'})
						TriggerClientEvent('esx:showNotification', source, 'vous avez payé une facture de '..ESX.Math.GroupDigits(amount))
						if xTarget ~= nil then TriggerClientEvent('esx:showNotification', xTarget.source, 'Vous avez reçu un paiement de '..ESX.Math.GroupDigits(amount)) end
						cb()
					end)
				elseif xPlayer.getAccount('cash').money >= amount then
					MySQL.Async.execute('DELETE from billing WHERE id = @id', {
						['@id'] = id
					}, function(rowsChanged)
						xPlayer.removeAccountMoney('cash', amount)
						xTarget.addAccountMoney('cash', amount)
						TriggerClientEvent('esx:showNotification', source, 'vous avez payé une facture de '..ESX.Math.GroupDigits(amount))
						if xTarget ~= nil then TriggerClientEvent('esx:showNotification', xTarget.source, 'Vous avez reçu un paiement de '..ESX.Math.GroupDigits(amount)) end
						cb()
					end)
				else
					TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas assez d\'argent')
					if xTarget ~= nil then TriggerClientEvent('esx:showNotification', xTarget.source, 'Le joueur n\'as pas assez d\'argent') end
					cb()
				end
			else
				TriggerClientEvent('esx:showNotification', source, _U('player_not_online'))
				cb()
			end
		else
            if xPlayer.getAccount('bank').money >= amount then
                MySQL.Async.execute('DELETE from billing WHERE id = @id', {
                    ['@id'] = id
                }, function(rowsChanged)
                    xPlayer.removeAccountMoney('bank', amount, {title = 'Paiement Facture', description = 'Facture payée à une entreprise', category = 'fine'})
                    SocietyCache[target].data["accounts"].cash = math.floor(SocietyCache[target].data["accounts"].cash+amount)
					SocietySaved[target] = SocietyCache[target]
                    TriggerClientEvent('esx:showNotification', source, 'vous avez payé une facture de '..ESX.Math.GroupDigits(amount))
                    if xTarget ~= nil then TriggerClientEvent('esx:showNotification', xTarget.source, 'Vous avez reçu un paiement de '..ESX.Math.GroupDigits(amount)) end
                    cb()
                end)
            elseif xPlayer.getAccount('cash').money >= amount then 
                MySQL.Async.execute('DELETE from billing WHERE id = @id', {
                    ['@id'] = id
                }, function(rowsChanged)
                    xPlayer.removeAccountMoney('cash', amount)
					if SocietyCache[target] then 
						SocietyCache[target].data["accounts"].cash = math.floor(SocietyCache[target].data["accounts"].cash+amount)
						SocietySaved[target] = SocietyCache[target]
					end
                    TriggerClientEvent('esx:showNotification', source, 'vous avez ~g~payé~s~ une facture de '..ESX.Math.GroupDigits(amount))
                    if xTarget ~= nil then TriggerClientEvent('esx:showNotification', xTarget.source, 'Vous avez reçu un paiement de '..ESX.Math.GroupDigits(amount)) end
                    cb()
                end)
            else
                TriggerClientEvent('esx:showNotification', source, 'Vous n\'avez pas assez d\'argent')
                if xTarget ~= nil then TriggerClientEvent('esx:showNotification', xTarget.source, 'Le joueur n\'as pas assez d\'argent') end
                cb()
            end
		end
	end)
end)

function sendToDiscord (name,message,color)
	date_local1 = os.date('%H:%M:%S', os.time())
	local date_local = date_local1
	local DiscordWebHook = "https://discord.com/api/webhooks/1147186659717296230/FnnGDBBngtg0PUJxDDxnjYjIK2js4rWQMFg08x3wUrgron8afFNxk2GwzyO7DFDRTDvx"
	-- Modify here your discordWebHook username = name, content = message,embeds = embeds

	local embeds = {
		{
			["title"]=message,
			["type"]="rich",
			["color"] =color,
			["footer"]=  {
				["text"]= "Heure: " ..date_local.. "",
			},
		}
	}

	if message == nil or message == '' then return FALSE end
	PerformHttpRequest(DiscordWebHook, function(err, text, headers) end, 'POST', json.encode({ username = name,embeds = embeds}), { ['Content-Type'] = 'application/json' })
end 