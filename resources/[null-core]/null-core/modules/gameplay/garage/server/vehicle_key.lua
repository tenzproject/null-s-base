TempsKey = {}

ESX.RegisterServerCallback('esx_vehiclelock:mykey', function(source, cb, plate)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.query('SELECT * FROM open_car WHERE owner = @owner AND plate = @plate', {
		['@owner'] = xPlayer.identifier,
		['@plate'] = plate
	}, function(result)
		local found = false

		if result[1] then
			found = true
		end

		cb(found)
	end)
end)

RegisterNetEvent('Null:changevehicleowner', function(target, vehicle)
	local source = source 

	TriggerEvent("ratelimit", source, "Null:changevehicleowner") 
	if target == -1 then
		DropPlayer(source,'Désynchronisation avec le serveur ou détection de Cheat')
		return
	end
	local xPlayer = ESX.GetPlayerFromId(source)
	local xPlayerTarget = ESX.GetPlayerFromId(target)
	if SaveData.json["owned_vehicles"][string.upper(vehicle.plate)] and SaveData.json["owned_vehicles"][string.upper(vehicle.plate)].owner == xPlayer.identifier then
		if not SaveData.json["owned_vehicles"][string.upper(vehicle.plate)].boutique then
			SaveData.json["owned_vehicles"][string.upper(vehicle.plate)].owner = xPlayerTarget.identifier
			xPlayer.showNotification("Vous avez donner les clés du véhicule ("..ESX.Config("serverColor")..vehicle.plate.."~s~)")
			xPlayerTarget.showNotification("Vous avez reçu les clés du véhicule ("..ESX.Config("serverColor")..vehicle.plate.."~s~)")
		end
	else
		xPlayer.showNotification('Le véhicule ne vous appartient pas')
	end 
end)


RegisterNetEvent('Null:garage:addTempKey', function(plate)
	local xPlayer = ESX.GetPlayerFromId(source)
	local idunique = xPlayer.getIdunique()
	--if TempsKey[idunique] ~= nil and TempsKey[idunique][plate] ~= nil then
	--	return
	--end
	if TempsKey[idunique] == nil then
		TempsKey[idunique] = {}
	end
	TempsKey[idunique][plate] = os.time()
	xPlayer.showNotification("Vous avez obtenu les clés de la voiture pour ~b~"..Config.Garage.Time.." Minutes~s~")
end)


ESX.RegisterServerCallback('Core:requestPlayerCars', function(source, cb, plate)
	if plate == nil then
		return cb(false)
	end
	local xPlayer = ESX.GetPlayerFromId(source)
	local job = xPlayer.job.name 
	local idunique = xPlayer.getIdunique()
	local vehplate = plate:match('^%s*(.-)%s*$')

	if SaveData.json["owned_vehicles"][string.upper(vehplate)] then
		if SaveData.json["owned_vehicles"][string.upper(vehplate)].owner == xPlayer.identifier or SaveData.json["owned_vehicles"][string.upper(vehplate)].owner == xPlayer.job.name or SaveData.json["owned_vehicles"][string.upper(vehplate)].owner == xPlayer.job2.name then
			cb(true)
		end
	else
		if TempsKey[idunique] ~= nil and TempsKey[idunique][string.upper(vehplate)] ~= nil then
			if type(TempsKey[idunique][string.upper(vehplate)]) == "string" then
				if TempsKey[idunique][string.upper(vehplate)] == "gofast" then
					cb(true)
				else
					cb(false)
				end
			else
				if (SaveData.json["entreprises"]["Police"][job] ~= nil or SaveData.json["entreprises"]["Ambulance"][job] ~= nil) 
					or (os.time() - TempsKey[idunique][string.upper(vehplate)] > (Config.Garage.Time * 60)) then 
					TempsKey[idunique][string.upper(vehplate)] = nil
					cb(false)
				else
					cb(true)
				end
			end
		else
			cb(false)
		end
	end
end)