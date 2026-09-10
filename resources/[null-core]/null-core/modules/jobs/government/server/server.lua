

TriggerEvent('esx_society:registerSociety', 'gouvernement', 'Gouvernement', 'society_gouvernement', 'society_gouvernement', 'society_gouvernement', {type = 'public'})

RegisterServerEvent('gouv:handcuff')
AddEventHandler('gouv:handcuff', function(target)
  TriggerClientEvent('gouv:handcuff', target)
end)

RegisterServerEvent('gouv:drag')
AddEventHandler('gouv:drag', function(target)
  local _source = source
  TriggerClientEvent('gouv:drag', target, _source)
end)

RegisterServerEvent('gouv:putInVehicle')
AddEventHandler('gouv:putInVehicle', function(target)
  TriggerClientEvent('gouv:putInVehicle', target)
end)

RegisterServerEvent('gouv:OutVehicle')
AddEventHandler('gouv:OutVehicle', function(target)
    TriggerClientEvent('gouv:OutVehicle', target)
end)

local lastCreatedCall = {}
RegisterNetEvent("null:sendcall", function()
	local xPlayer = ESX.GetPlayerFromId(source)
	if lastCreatedCall[source] ~= nil then 
		if os.time() - lastCreatedCall < 60*5 then
			return xPlayer.showNotification("Vous devez attendre 5 Minute entre chaque appel.")
		end
	end
	local playersInJob = ESX.GetJobsPlayers("gouvernement")
	for k,v in pairs(playersInJob) do
		TriggerClientEvent("esx:showNotification", k, "Un nouvel appel a été fait à l'accueil du gouvernement.")
	end
end)

local lastCreatedAsk = {}
RegisterNetEvent("gouv:sendentreprise", function(LastName, FirstName, tel, Subject, Desc)
	local xPlayer = ESX.GetPlayerFromId(source)
	if lastCreatedAsk[source] ~= nil then 
		if os.time() - lastCreatedAsk < 60*5 then
			return xPlayer.showNotification("Vous devez attendre 5 Minute entre chaque demande.")
		end
	end
	xPlayer.showNotification("Votre demande à bien été pris en compte")
	--ESX.Logs("Nouvel demande de création d'entreprise.", "Nom Prenom: "..LastName.." "..FirstName.."\nNumero de téléphone: "..tel.."\nSujet de l'entreprise: "..Subject.."\nDéscription de l'entreprise: "..Desc, Config.Gouvernement.Accueil.AskCreateSociety)
end)

--[[RegisterNetEvent('gouv:confiscatePlayerItem')
AddEventHandler('gouv:confiscatePlayerItem', function(target, itemType, itemName, amount)
    local _source = source
    local sourceXPlayer = ESX.GetPlayerFromId(_source)
    local targetXPlayer = ESX.GetPlayerFromId(target)

	if xPlayer.job.name == 'gouvernement' then
		if itemType == 'item_standard' then
			local targetItem = targetXPlayer.getInventoryItem(itemName)
			local sourceItem = sourceXPlayer.getInventoryItem(itemName)
			
				targetXPlayer.removeInventoryItem(itemName, amount)
				sourceXPlayer.addInventoryItem(itemName, amount)
				TriggerClientEvent("esx:showNotification", source, "Vous avez volé ~r~"..amount..' '..sourceItem.label.."~s~.")
				TriggerClientEvent("esx:showNotification", target, "Il t'a été volé ~r~"..amount..' '..sourceItem.label.."~s~.")
			else
				--TriggerClientEvent("esx:showNotification", source, "~r~quantité invalide")
			end
			
		if itemType == 'item_account' then
			targetXPlayer.removeAccountMoney(itemName, amount)
			sourceXPlayer.addAccountMoney   (itemName, amount)
			
			TriggerClientEvent("esx:showNotification", source, "Vous avez volé ~r~"..amount.."€ ~s~Argent sale~s~.")
			TriggerClientEvent("esx:showNotification", target, "Il t'a été volé ~r~"..amount.."€ ~s~Argent sale~s~.")
			
		elseif itemType == 'item_weapon' then
			if amount == nil then amount = 0 end
			targetXPlayer.removeWeapon(itemName, amount)
			sourceXPlayer.addWeapon   (itemName, amount)

			TriggerClientEvent("esx:showNotification", source, "Vous avez volé ~r~"..ESX.GetWeaponLabel(itemName).."~s~ avec ~r~"..amount.."~s~ munitions.")
			TriggerClientEvent("esx:showNotification", target, "Il t'a été volé ~r~"..ESX.GetWeaponLabel(itemName).."~s~ avec ~r~"..amount.."~s~ munitions.")
		end
	end
end)]]


ESX.RegisterServerCallback('gouv:getOtherPlayerData', function(source, cb, target, notify)
    local xPlayer = ESX.GetPlayerFromId(target)

    TriggerClientEvent("esx:showNotification", target, "~r~Tu es fouillé...")

    if xPlayer then
        local data = {
            name = xPlayer.getName(),
            job = xPlayer.job.label,
            grade = xPlayer.job.grade_label,
            inventory = xPlayer.getInventory(),
            accounts = xPlayer.getAccounts(),
            weapons = xPlayer.getLoadout()
        }

        cb(data)
    end
end)

RegisterServerEvent('Null:gouv:annonce')
AddEventHandler('Null:gouv:annonce', function(type)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local xPlayers	= ESX.GetPlayers()
	local msg = ""
	if type == "ouvre" then
		msg = "Le Gouvernement est désormais ~g~Disponible~s~ !"
	elseif type == "ferme" then
		msg = "Le Gouvernement est désormais ~r~Indisponible~s~ !"
	elseif type == "recrutement" then
		msg = "Recrutement en cours, rendez-vous au ~b~Gouvernement~s~ !"
	end
	if xPlayer.job.name == 'gouvernement' then
		for i=1, #xPlayers, 1 do
			local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
			TriggerClientEvent('esx:showNotification', xPlayers[i], msg)
		end
	end
end)

ESX.RegisterServerCallback('gouv:playerinventory', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local items   = xPlayer.inventory
	local all_items = {}
	
	for k,v in pairs(items) do
		if v.count > 0 then
			table.insert(all_items, {label = v.label, item = v.name,nb = v.count})
		end
	end

	cb(all_items)
end)


ESX.RegisterServerCallback('gouv:getStockItems', function(source, cb)
	local all_items = {}
	if xPlayer.job.name == 'gouvernement' then
		TriggerEvent('esx_addoninventory:getSharedInventory', 'society_gouvernement', function(inventory)
			for k,v in pairs(inventory.items) do
				if v.count > 0 then
					table.insert(all_items, {label = v.label,item = v.name, nb = v.count})
				end
			end

		end)
		cb(all_items)
	end
end)

RegisterServerEvent('gouv:putStockItems')
AddEventHandler('gouv:putStockItems', function(itemName, count)
	local xPlayer = ESX.GetPlayerFromId(source)
	local item_in_inventory = xPlayer.getInventoryItem(itemName).count

	if xPlayer.job.name == 'gouvernement' then
		TriggerEvent('esx_addoninventory:getSharedInventory', 'society_gouvernement', function(inventory)
			if item_in_inventory >= count and count > 0 then
				xPlayer.removeInventoryItem(itemName, count)
				inventory.addItem(itemName, count)
				TriggerClientEvent('esx:showNotification', xPlayer.source, "- ~g~Dépot\n~s~- ~g~Item ~s~: "..itemName.."\n~s~- ~o~Quantitée ~s~: "..count.."")
			else
				TriggerClientEvent('esx:showNotification', xPlayer.source, "~r~Vous n'en avez pas assez sur vous")
			end
		end)
	end
end)

RegisterServerEvent('gouv:takeStockItems')
AddEventHandler('gouv:takeStockItems', function(itemName, count)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer.job.name == 'gouvernement' then
		TriggerEvent('esx_addoninventory:getSharedInventory', 'society_gouvernement', function(inventory)
				xPlayer.addInventoryItem(itemName, count)
				inventory.removeItem(itemName, count)
				TriggerClientEvent('esx:showNotification', xPlayer.source, "- ~r~Retrait\n~s~- ~g~Item ~s~: "..itemName.."\n~s~- ~o~Quantitée ~s~: "..count.."")
		end)
	end
end)

RegisterServerEvent('gouv:depositMoney')
AddEventHandler('gouv:depositMoney', function(society, amount)

	local xPlayer = ESX.GetPlayerFromId(source)
	local money = xPlayer.getMoney()
	local src = source
  
	if xPlayer.job.name == 'gouvernement' then
		TriggerEvent('esx_addonaccount:getSharedAccount', society, function(account)
		if money >= tonumber(amount) then
			xPlayer.removeAccountMoney('cash', amount)
			account.addMoney(amount)
			TriggerClientEvent("esx:showNotification", src, "- ~o~Déposé \n~s~- ~g~Somme : "..amount.."$")
		else
			TriggerClientEvent("esx:showNotification", src, "- ~r~Erreur \n~s~- ~g~Pas assez d'argent")
		end
		end)
	end
end)


RegisterNetEvent('Null:gouv:vestaiaire:déposer')
AddEventHandler('Null:gouv:vestaiaire:déposer', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.job.name == 'gouvernement' then
		for k,v in pairs(Config.Gouvernement.Services.weapons) do
			xPlayer.removeWeapon(v.name)
		end
		TriggerClientEvent('esx:showNotification', source, "Vous avez posé tous vos armes")
	end
end)

RegisterNetEvent('Null:gouv:vestaiaire:equipement')
AddEventHandler('Null:gouv:vestaiaire:equipement', function(item,price)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.job.name == 'gouvernement' then
		for k,v in pairs(Config.Gouvernement.Services.weapons) do
			xPlayer.addWeapon(v.name, 1, {
				gouvernement = true,
			}, false, true)
		end
	end
end)