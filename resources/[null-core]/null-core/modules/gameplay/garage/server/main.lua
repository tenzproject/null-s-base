local VehicleSort = {}

function CheckIfVehicleIsOwned(plate)
	for k,v in pairs(SaveData.json["owned_vehicles"]) do
		if v.plate == plate then
			return true
		end
	end
	return false
end

function CheckOwnerVehicle(plate, owner, jobs)
	for k,v in pairs(SaveData.json["owned_vehicles"]) do
		if v.plate == plate and (v.owner == owner or v.owner == jobs[1] or v.owner == jobs[2]) then
			return true
		end
	end
	return false
end

ESX.RegisterServerCallback('null:getOwnedCars', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local job = xPlayer.getJob().name
	local job2 = xPlayer.getJob2().name
	local ownedCars = {}
	local ownedCarsJobs = {}
	local OwnedCarsOrg = {} 

	for k,v in pairs(SaveData.json["owned_vehicles"]) do
		if type(v) ~= "table" then goto pass end
		if v.owner == xPlayer.identifier then
			table.insert(ownedCars, {boutique = v.boutique, owner = v.owner, garageid = v.garage, label = v.label, vehicle = v.vehicle, type = v.type, state = v.state, plate = v.plate})
		elseif v.owner == job then
			table.insert(ownedCarsJobs, {boutique = v.boutique, owner = v.owner, garageid = v.garage, label = v.label, vehicle = v.vehicle, type = v.type, state = v.state, plate = v.plate})
		elseif v.owner == job2 then
			table.insert(OwnedCarsOrg, {boutique = v.boutique, owner = v.owner, garageid = v.garage, label = v.label, vehicle = v.vehicle, type = v.type, state = v.state, plate = v.plate})
		end
		::pass::
	end

	TriggerClientEvent('null:UpdateTableVehicleSort', xPlayer.source, VehicleSort)
	cb(ownedCars, ownedCarsJobs, OwnedCarsOrg)
end)

RegisterNetEvent('null:renameVehicle', function(owner, vehicle, label)
	local source = source 
    local xPlayer = ESX.GetPlayerFromId(source)
	TriggerEvent("ratelimit", source, "null:renameVehicle") 

	if xPlayer.identifier == owner or xPlayer.job.name == owner or xPlayer.job2.name == owner then
		SaveData.json["owned_vehicles"][vehicle.plate].label = label
	else
		DropPlayer(source, 'Utilisation du trigger pour renommer les véhicules')
	end
end)

RegisterNetEvent('null:setstatevehicle', function(plate, state, Entity)
	local source = source 

	TriggerEvent("ratelimit", source, "null:setstatevehicle") 
	local xPlayer = ESX.GetPlayerFromId(source)
	if not state then
		if not VehicleSort[plate] then
			VehicleSort[plate] = {}
			VehicleSort[plate].Entity = Entity
			SaveData.json["owned_vehicles"][plate].state = false
			TriggerClientEvent('null:UpdateTableVehicleSort', xPlayer.source, VehicleSort)
		else
			--TriggerClientEvent('null:DeleteEntity', xPlayer.source, Entity)
		end
	else
		VehicleSort[plate] = nil
		SaveData.json["owned_vehicles"][plate].state = true
		TriggerClientEvent('null:UpdateTableVehicleSort', xPlayer.source, VehicleSort)
	end
end)

ESX.RegisterServerCallback('null:storevehicle', function(source, cb, vehicleProps, garageid, displayname)
	if vehicleProps == nil then return end
	local ownedCars = {}
	local vehplate = vehicleProps.plate:match('^%s*(.-)%s*$')
	local vehiclemodel = vehicleProps.model
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if CheckOwnerVehicle(vehplate, xPlayer.identifier, {xPlayer.job.name, xPlayer.job2.name}) then
		SaveData.json["owned_vehicles"][vehplate].vehicle = vehicleProps
		cb(true)
		return
	end
	cb(false)
end)

local MoneyRepairVehicle = 1500
ESX.RegisterServerCallback('null:storevehiclewithmoney', function(source, cb, vehicleProps)
	local ownedCars = {}
	local vehplate = vehicleProps.plate:match('^%s*(.-)%s*$')
	local vehiclemodel = vehicleProps.model
	local xPlayer = ESX.GetPlayerFromId(source)
	vehiclePlate = string.gsub(vehicleProps.plate, '%s+', '')
	if xPlayer.getAccount('cash').money >= MoneyRepairVehicle then
		if CheckOwnerVehicle(vehplate, xPlayer.identifier, {xPlayer.job.name, xPlayer.job2.name}) then
			SaveData.json["owned_vehicles"][vehplate].vehicle = vehicleProps
			xPlayer.removeAccountMoney('cash', MoneyRepairVehicle)
			cb(true)
			return
		else
			cb(false)
		end
	else
		xPlayer.showNotification('Vous n\'avez pas l\'argent néccéssaire')
		cb(false)
	end
end)

ESX.RegisterServerCallback('null:storeVehicleFourriere', function(source, cb, vehicleProps)
	local ownedCars = {}
	local vehplate = vehicleProps.plate:match('^%s*(.-)%s*$')
	local vehiclemodel = vehicleProps.model
	local xPlayer = ESX.GetPlayerFromId(source)
	local priceFourriere = 1500
	if xPlayer.getAccount('bank').money >= priceFourriere then
		if CheckOwnerVehicle(vehplate, xPlayer.identifier, {xPlayer.job.name, xPlayer.job2.name}) then
			SaveData.json["owned_vehicles"][vehplate].vehicle = vehicleProps
			xPlayer.removeAccountMoney('cash', MoneyRepairVehicle)
			cb(true)
			return
		else
			cb(false)
		end
	else
		xPlayer.showNotification('Vous n\'avez pas l\'argent nécéssaire (Banque)')
		cb(false)
	end	
end)

local Garage = {}

RegisterNetEvent('null:createGarage', function(table)
	local source = source 
	TriggerEvent("ratelimit", source, "null:createGarage") 
	local xPlayer = ESX.GetPlayerFromId(source)

	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        MySQL.update("INSERT INTO `garage` (`name`, `pos`, `SpawnPoint`, `DeletePoint`, `type`, `blip`) VALUES (@name, @pos, @SpawnPoint, @DeletePoint, @type, @blip) ", {
            ['@name'] = table.name,
            ['@pos'] = json.encode(table.position),
			['@SpawnPoint'] = json.encode(table.spawnPoints),
			['@DeletePoint'] = json.encode(table.deletePoint),
			['@type'] = table.type,
			['@blip'] = table.blip == true and 1 or 0
        })
		Garage[table.name] = {}
		Garage[table.name].id = 58
		Garage[table.name].name = table.name
		Garage[table.name].position = table.position
		Garage[table.name].SpawnPoint = table.spawnPoints
		Garage[table.name].DeletePoint = table.deletePoint
		Garage[table.name].blip = table.blip
		Garage[table.name].type = table.type
		TriggerClientEvent('null:refreshGarage', -1, Garage)
		xPlayer.showNotification('Le garage à été crée avec succès')
	end
end)

RegisterNetEvent('null:deleteGarage', function(name)
	local source = source 
	TriggerEvent("ratelimit", source, "null:createGarage") 
	local xPlayer = ESX.GetPlayerFromId(source)

	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        Garage[name] = nil
		MySQL.Async.execute('DELETE FROM garage WHERE `name` = @name', {
			['@name'] = name
		})
		TriggerClientEvent('null:refreshGarage', -1, Garage)
		xPlayer.showNotification('Le garage à été supprimer avec succès')
	end
end)

Citizen.CreateThread(function()
	LoadGarage()
end)

function LoadGarage()
    MySQL.query('SELECT * FROM garage', {}, function(ElGarage)
        for i=1, #ElGarage, 1 do
			local Pos = json.decode(ElGarage[i].pos)
			local PosSpawn = json.decode(ElGarage[i].SpawnPoint)
			local PosDelete = json.decode(ElGarage[i].DeletePoint)
			Garage[ElGarage[i].name] = {}
			Garage[ElGarage[i].name].id = tonumber(ElGarage[i].id)
			Garage[ElGarage[i].name].name = ElGarage[i].name
			Garage[ElGarage[i].name].position = Pos
			Garage[ElGarage[i].name].SpawnPoint = PosSpawn
			Garage[ElGarage[i].name].DeletePoint = PosDelete
			Garage[ElGarage[i].name].blip = ElGarage[i].blip
			Garage[ElGarage[i].name].type = ElGarage[i].type
        end
		TriggerEvent("null:core:recevieload:GarageCount", #ElGarage)
		--Wait(10000)
		--print('[^4LOAD^0] [^4'..#ElGarage..'^0] Garages ont été load avec succès')
    end)
end

RegisterNetEvent('null:InitGarage', function()
	local source = source 
	TriggerEvent("ratelimit", source, "null:InitGarage") 
	TriggerClientEvent('null:refreshGarage', source, Garage)
end)

RegisterNetEvent('Null:AttribuerVehicule', function(type, vehicle)
	local source = source
	TriggerEvent("ratelimit", source, "Null:AttribuerVehicule") 
	local xPlayer = ESX.GetPlayerFromId(source)
	if type == 'job' then
		if xPlayer.job.name ~= 'unemployed' then
			if vehicle.owner == xPlayer.identifier then
				SaveData.json["owned_vehicles"][vehicle.plate].owner = xPlayer.job.name
				xPlayer.showNotification('Le véhicule à été attribué a l\'entreprise : '..xPlayer.job.label)
			end
		else
			xPlayer.showNotification('Vous n\'avez pas d\'entreprise pour faire çela')
		end
	elseif type == 'job2' then
		if vehicle.owner == xPlayer.identifier then
			if xPlayer.job2.name ~= 'unemployed2' then
				if vehicle.owner == xPlayer.identifier then
					SaveData.json["owned_vehicles"][vehicle.plate].owner = xPlayer.job2.name
					xPlayer.showNotification('Le véhicule à été attribué a l\'entreprise : '..xPlayer.job2.label)
				end
			else
				xPlayer.showNotification('Vous n\'avez pas d\'entreprise pour faire çela : ')
			end
		end
	end
end)

RegisterCommand('creategarage', function(source,args) 
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		TriggerClientEvent('null:creategarage', source)
	end
end)