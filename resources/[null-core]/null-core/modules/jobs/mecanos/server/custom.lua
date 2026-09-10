local Vehicles

local VehiclesInShop = {}



RegisterServerEvent('fpwn_customs:refreshOwnedVehicle')
AddEventHandler('fpwn_customs:refreshOwnedVehicle', function(vehicleProps, playerSrc)
	if playerSrc == "byClient" then playerSrc = source end
	local xPlayer = ESX.GetPlayerFromId(playerSrc)
	if xPlayer == nil then return end
	
	if SaveData.json["owned_vehicles"][string.upper(vehicleProps.plate)] then
		SaveData.json["owned_vehicles"][string.upper(vehicleProps.plate)].vehicle = vehicleProps
	else
		print("Attempted to update a null owned vehicle")
	end
end)

function addHistoryCustomToMecano()

end

ESX.RegisterServerCallback("Core:GetSocietyHistorique", function(source, cb, society)
    MySQL.Async.fetchAll('SELECT * FROM `vhistoriquesociety` WHERE `society` = @society', {
        ['@society'] = society
    }, function(result)
        if result[1] then
            cb(result)
        else
            cb({})
        end
    end)
end)

ESX.RegisterServerCallback('fpwn_customs:getVehiclesPrices', function(source, cb)
	if not Vehicles then
		MySQL.Async.fetchAll('SELECT * FROM vehicles', {}, function(result)
			local vehicles = {}

			for i=1, #result, 1 do
				table.insert(vehicles, {
					model = result[i].model,
					price = result[i].price
				})
			end

			Vehicles = vehicles
			cb(Vehicles)
		end)
	else
		cb(Vehicles)
	end
end)

RegisterServerEvent('fpwn_customs:checkVehicle')
AddEventHandler('fpwn_customs:checkVehicle', function(plate)
	local xPlayer = ESX.GetPlayerFromId(source)
	--print("plate: " .. plate)
	for k, v in pairs(VehiclesInShop) do 
		--print("k: " .. k)
		--print("v['plate']: " .. v['plate'])
		if v.plate == plate and _source ~= k then
			--print("found it")
			TriggerClientEvent('fpwn_customs:resetVehicle', source, v)
			VehiclesInShop[xPlayer.identifier] = nil
			break
		end
	end
end)

RegisterServerEvent('fpwn_customs:saveVehicle')
AddEventHandler('fpwn_customs:saveVehicle', function(oldVehProps)
	local xPlayer = ESX.GetPlayerFromId(source)
	--print("oldVehProps['plate']: " .. oldVehProps['plate'])
	if oldVehProps then
		VehiclesInShop[xPlayer.identifier] = oldVehProps
		--print("VehiclesInShop[_source][plate]: " .. VehiclesInShop[_source]['plate'])
	end
end)

function calcFinalPrice(shopCart, shopProfit, shopReduction)
	local shopProfitValue = 0
	local totalCartValue = 0

	for k, v in pairs(shopCart) do
		--print("k: " .. k)
		--print("v['price']: " .. v['price'])
		totalCartValue = totalCartValue + v['price']
	end
	shopCosts = 100 - shopProfit
	shopReductionValue = totalCartValue * (shopReduction / 100)
	totalWithReduction = totalCartValue - shopReductionValue
	shopProfitValue = totalWithReduction * (shopProfit / 100)
	shopCostValue = totalWithReduction * (shopCosts / 100)
	
	return shopCostValue, totalWithReduction
end

RegisterServerEvent('fpwn_customs:finishPurchase')
AddEventHandler('fpwn_customs:finishPurchase', function(society, newVehProps, shopCart, playerId, shopProfit, shopReduction, autoInvoice, staff)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xTarget = ESX.GetPlayerFromId(playerId)
	if staff and xPlayer.getGroup() ~= "user" then
		xTarget = ESX.GetPlayerFromId(source)
		
		TriggerClientEvent('esx:showNotification', source, "L'achat a était effectuer")
		TriggerClientEvent('fpwn_customs:canBill', source, totalWithReduction, playerId)
		
		newVehProps['extras'] = { [1] = 12, [2] = '12' }
		TriggerEvent('fpwn_customs:refreshOwnedVehicle', newVehProps, source)
		isFinished = true

		if VehiclesInShop[xPlayer.identifier] then VehiclesInShop[xPlayer.identifier] = nil end
	else
		local societyFinal = "society_"..xPlayer.getJob().name
		local isFinished = false
	
		local shopCostValue, totalWithReduction = calcFinalPrice(shopCart, shopProfit, shopReduction)
		if shopCostValue <= 0 or totalWithReduction <= 0 then
			TriggerClientEvent('fpwn_customs:cantBill', source)
			TriggerClientEvent('fpwn_customs:resetVehicle', source, VehiclesInShop[xPlayer.identifier])
			VehiclesInShop[xPlayer.identifier] = nil
			return
		end
	
		local societyAccount = {}
	
		--TriggerEvent('Null:esx_addonaccount:getSharedAccount', societyFinal, function(account)
		--	societyAccount = account
		--end)
	
		--if shopCostValue <= societyAccount.money then
			if autoInvoice then
				local playerMoney = xPlayer.getAccount('bank')
				if playerMoney.money >= totalWithReduction and autoInvoice then
					TriggerClientEvent('esx:showNotification', source, "L'achat a était effectuer")
					TriggerClientEvent('fpwn_customs:canBill', source, totalWithReduction, playerId)
					--TriggerEvent("Core:AddBilling", source, tonumber(totalWithReduction), xPlayer.getJob().name)
					--societyAccount.addMoney(totalWithReduction - shopCostValue)
					xPlayer.removeAccountMoney('bank', totalWithReduction, {title = 'Customisation Véhicule', description = 'Tuning mécano (auto-facture)', category = 'purchase'})
	
					newVehProps['extras'] = { [1] = 12, [2] = '12' }
					TriggerEvent('fpwn_customs:refreshOwnedVehicle', newVehProps, source)
					isFinished = true
					exports["null-core"]:SendLogs("Logs","Le joueur : "..xPlayer.getName().." (T"..source.." U"..xPlayer.getIdunique()..")\n A custom le véhicule : "..newVehProps.model.." (Plaque : "..newVehProps.plate..")\nPour le joueur : "..xPlayer.getName().." (T"..source.." U"..xPlayer.getIdunique()..")\n Pour un total de : "..totalWithReduction.."$ (Avec Auto Facture) \n\nEntreprise : **"..xPlayer.getJob().label.."**","mecano", {idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName()})
					exports["null-core"]:SendLogs("Logs Mécano","Le joueur "..xPlayer.getName().." ("..xPlayer.getIdunique()..") a custom le véhicule : "..newVehProps.model.." (Plaque : "..newVehProps.plate..") pour le joueur : "..xPlayer.getName().." ("..xPlayer.getIdunique()..") Total : "..totalWithReduction.."$ (Avec Auto Facture) ("..xPlayer.getJob().label..")","mecano", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = xPlayer.getIdunique(), name_cible = xPlayer.getName()})
				end
			else
				local targetMoney = xTarget.getAccount('bank')
				if targetMoney.money >= totalWithReduction and not autoInvoice then
					TriggerClientEvent('esx:showNotification', source, "L'achat a était effectuer")
					--TriggerEvent("Core:AddBilling", playerId, tonumber(totalWithReduction), xPlayer.getJob().name)
					--societyAccount.addMoney(totalWithReduction - shopCostValue)
					xTarget.removeAccountMoney('bank', totalWithReduction, {title = 'Customisation Véhicule', description = 'Tuning mécano', category = 'purchase'})
					TriggerEvent('fpwn_customs:refreshOwnedVehicle', newVehProps, source)
					isFinished = true
					exports["null-core"]:SendLogs("Logs Mécano","Le joueur "..xPlayer.getName().." ("..xPlayer.getIdunique()..") a custom le véhicule : "..newVehProps.model.." (Plaque : "..newVehProps.plate..") pour le joueur : "..xTarget.getName().." ("..xTarget.getIdunique()..") Total : "..totalWithReduction.."$ ("..xPlayer.getJob().label..")","mecano", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = xTarget.getIdunique(), name_cible = xTarget.getName()})
				else
					TriggerClientEvent('esx:showNotification', source, 'La personne n\'a pas assez d\'argent (Banque)')
					isFinished = false
				end
			end
		--else
		--	TriggerClientEvent('esx:showNotification', source, 'Pas assez d\'argent dans la société', _U('not_enough_money'))
		--	isFinished = false
		--end
	
		if not isFinished then
			TriggerClientEvent('fpwn_customs:cantBill', source)
			TriggerClientEvent('fpwn_customs:resetVehicle', source, VehiclesInShop[xPlayer.identifier])
		end
	
		if VehiclesInShop[xPlayer.identifier] then VehiclesInShop[xPlayer.identifier] = nil end
	end
end)


RegisterServerEvent('fpwn_customs:resetvh')
AddEventHandler('fpwn_customs:resetvh', function()
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerClientEvent('fpwn_customs:resetVehicle', source, VehiclesInShop[xPlayer.identifier])

	if VehiclesInShop[xPlayer.identifier] then VehiclesInShop[xPlayer.identifier] = nil end
end)