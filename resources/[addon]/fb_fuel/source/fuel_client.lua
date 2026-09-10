local isNearPump = false
local isFueling = false
local currentFuel = 0.0
local currentCost = 0.0
local currentCash = 1000
local fuelSynced = false
local inBlacklisted = false
local activeDuiStation = nil  

local function ManageFuelUsage(vehicle)
	if not DecorExistOn(vehicle, Config.Fuel.FuelDecor) then
		SetFuel(vehicle, math.random(200, 800) / 10)
	elseif not fuelSynced then
		SetFuel(vehicle, GetFuel(vehicle))

		fuelSynced = true
	end

	if IsVehicleEngineOn(vehicle) then
		SetFuel(vehicle, GetVehicleFuelLevel(vehicle) - Config.Fuel.FuelUsage[Round(GetVehicleCurrentRpm(vehicle), 1)] * (Config.Fuel.Classes[GetVehicleClass(vehicle)] or 1.0) / 10)
	end
end

Citizen.CreateThread(function()
	DecorRegister(Config.Fuel.FuelDecor, 1)

	for index = 1, #Config.Fuel.Blacklist do
		if type(Config.Fuel.Blacklist[index]) == 'string' then
			Config.Fuel.Blacklist[GetHashKey(Config.Fuel.Blacklist[index])] = true
		else
			Config.Fuel.Blacklist[Config.Fuel.Blacklist[index]] = true
		end
	end

	for index = #Config.Fuel.Blacklist, 1, -1 do
		table.remove(Config.Fuel.Blacklist, index)
	end

	while true do
		Citizen.Wait(1000)

		local ped = PlayerPedId()

		if IsPedInAnyVehicle(ped) then
			local vehicle = GetVehiclePedIsIn(ped)

			if Config.Fuel.Blacklist[GetEntityModel(vehicle)] then
				inBlacklisted = true
			else
				inBlacklisted = false
			end

			if not inBlacklisted and GetPedInVehicleSeat(vehicle, -1) == ped then
				ManageFuelUsage(vehicle)
			end
		else
			if fuelSynced then
				fuelSynced = false
			end

			if inBlacklisted then
				inBlacklisted = false
			end
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(250)

		local pumpObject, pumpDistance = FindNearestFuelPump()

		if pumpDistance < 2.5 then
			isNearPump = pumpObject

			local playerData = ESX.GetPlayerData()
			for i=1, #playerData.accounts, 1 do
				if playerData.accounts[i].name == 'money' then
					currentCash = playerData.accounts[i].money
					break
				end
			end
		else
			isNearPump = false

			Citizen.Wait(math.ceil(pumpDistance * 20))
		end
	end
end)

AddEventHandler('fuel:startFuelUpTick', function(pumpObject, ped, vehicle)
	currentFuel = GetVehicleFuelLevel(vehicle)

	while isFueling do
		Citizen.Wait(500)

		local oldFuel = DecorGetFloat(vehicle, Config.Fuel.FuelDecor)
		local fuelToAdd = math.random(10, 20) / 10.0
		local extraCost = fuelToAdd / 1.5 * Config.Fuel.CostMultiplier

		if not pumpObject then
			if GetAmmoInPedWeapon(ped, 883325847) - fuelToAdd * 100 >= 0 then
				currentFuel = oldFuel + fuelToAdd

				SetPedAmmo(ped, 883325847, math.floor(GetAmmoInPedWeapon(ped, 883325847) - fuelToAdd * 100))
			else
				isFueling = false
			end
		else
			currentFuel = oldFuel + fuelToAdd
		end

		if currentFuel > 100.0 then
			currentFuel = 100.0
			isFueling = false
		end

		currentCost = currentCost + extraCost

		if currentCash >= currentCost then
			SetFuel(vehicle, currentFuel)
			
			if activeDuiStation then
				TriggerEvent('UpdateFuelStation', currentCost, currentFuel)
			end
		else
			isFueling = false
		end
	end

	if pumpObject then
		TriggerServerEvent('fuel:pay', currentCost)  
	end

	currentCost = 0.0
end)

AddEventHandler('fuel:refuelFromPump', function(pumpObject, ped, vehicle)
    TaskTurnPedToFaceEntity(ped, vehicle, 1000)
    Citizen.Wait(1000)
    SetCurrentPedWeapon(ped, -1569615261, true)
    LoadAnimDict("timetable@gardener@filling_can")
    TaskPlayAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 2.0, 8.0, -1, 50, 0, 0, 0, 0)

    TriggerEvent('fuel:startFuelUpTick', pumpObject, ped, vehicle)

    Citizen.Wait(200)
	TriggerEvent('Start3DFuelStation', pumpObject, currentCost or 0, currentFuel or 0)
 
    CreateThread(function()
        while isFueling do
            TriggerEvent('UpdateFuelStation', currentCost or 0, currentFuel or 0, pumpObject)
            Citizen.Wait(350)
        end
    end)

    while isFueling do
        for _, controlIndex in pairs(Config.Fuel.DisableKeys) do
            DisableControlAction(0, controlIndex)
        end

        local vehicleCoords = GetEntityCoords(vehicle)

        if pumpObject then
            ESX.ShowHelpNotification(Config.Fuel.Strings.CancelFuelingPump)
        end

        if not IsEntityPlayingAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 3) then
            TaskPlayAnim(ped, "timetable@gardener@filling_can", "gar_ig_5_filling_can", 2.0, 8.0, -1, 50, 0, 0, 0, 0)
        end

        if IsControlJustReleased(0, 38) or DoesEntityExist(GetPedInVehicleSeat(vehicle, -1)) or (isNearPump and GetEntityHealth(pumpObject) <= 0) then
            isFueling = false
			break 	
        end

        Citizen.Wait(0)
    end
 
	ClearPedTasks(ped)
	RemoveAnimDict("timetable@gardener@filling_can")
	TriggerEvent('StopFuelStation')
	isFueling = false  
end)

Citizen.CreateThread(function()
	while true do
		local ped = PlayerPedId()

		if not isFueling and ((isNearPump and GetEntityHealth(isNearPump) > 0) or (GetSelectedPedWeapon(ped) == 883325847 and not isNearPump)) then
			if IsPedInAnyVehicle(ped) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped), -1) == ped then
				local pumpCoords = GetEntityCoords(isNearPump)

				DrawText3Ds(pumpCoords.x, pumpCoords.y, pumpCoords.z + 1.2, Config.Fuel.Strings.ExitVehicle)
			else
				local vehicle = GetPlayersLastVehicle()
				local vehicleCoords = GetEntityCoords(vehicle)

				if DoesEntityExist(vehicle) and GetDistanceBetweenCoords(GetEntityCoords(ped), vehicleCoords) < 2.5 then
					if not DoesEntityExist(GetPedInVehicleSeat(vehicle, -1)) then
						local stringCoords = GetEntityCoords(isNearPump)
						local canFuel = true

						if GetSelectedPedWeapon(ped) == 883325847 then
							stringCoords = vehicleCoords

							if GetAmmoInPedWeapon(ped, 883325847) < 100 then
								canFuel = false
							end
						end

						if GetVehicleFuelLevel(vehicle) < 95 and canFuel then
							if currentCash > 0 then
								ESX.ShowHelpNotification("Presse ~INPUT_PICKUP~ pour remplir le véhicule")

								if IsControlJustReleased(0, 38) then
									isFueling = true

									TriggerEvent('fuel:refuelFromPump', isNearPump, ped, vehicle)
									LoadAnimDict("timetable@gardener@filling_can")
								end
							else
								ESX.ShowNotification(Config.Fuel.Strings.NotEnoughCash)
							end
						elseif not canFuel then
							DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, Config.Fuel.Strings.JerryCanEmpty)
						else
							DrawText3Ds(stringCoords.x, stringCoords.y, stringCoords.z + 1.2, 'Réservoir plein')
						end
					end 
				end
			end
		else
			Citizen.Wait(250)
		end

		Citizen.Wait(0)
	end
end)

 
Citizen.CreateThread(function()
	for _, gasStationCoords in pairs(Config.Fuel.GasStations) do
		CreateBlip(gasStationCoords)
	end
end) 

exports('getVehFuel', function(veh)
	local fuel = tostring(math.ceil(GetVehicleFuelLevel(veh)))
	return fuel
end)