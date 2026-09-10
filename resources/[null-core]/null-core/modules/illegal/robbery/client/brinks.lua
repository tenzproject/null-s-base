local AlreadySpawn = false
local PedModel = GetHashKey("csb_mweather")
local GroupBrinks = CreateGroup()
local BrinksDrive = false
local theBrinks = nil

function InitPedBrinks(ped, driver, codriver)
	SetBlockingOfNonTemporaryEvents(ped, false)
	SetPedSeeingRange(ped, 0)
	SetPedFleeAttributes(ped, 0, 0)
	SetPedArmour(ped, 200)
	DisablePedPainAudio(storePed, true)
	TaskStartScenarioInPlace(storePed, 'WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT', 0, 0)
	SetPedSuffersCriticalHits(ped, false)
	SetPedMaxHealth(ped, 200)
	SetPedDiesWhenInjured(ped, true)
	SetPedCanRagdoll(ped, false)
	SetPedAsEnemy(ped, true)
	SetPedCanBeDraggedOut(ped, true)
	SetPedCanBeKnockedOffVehicle(ped, true)
	SetPedStayInVehicleWhenJacked(ped, true)
	
	if driver or codriver then
		if driver then
			SetPedAsGroupLeader(ped, GroupBrinks)
		else
			SetPedAsGroupMember(ped, GroupBrinks)
		end
		GiveWeaponToPed(ped, "WEAPON_PISTOL_MK2", 500, false, false)
		GiveWeaponToPed(ped, "WEAPON_CARBINERIFLE_MK2", 500, false, false)
		SetCurrentPedWeapon(ped, "WEAPON_PISTOL_MK2", false)
		SetPedAmmo(ped, "WEAPON_PISTOL_MK2", 500)
	else
		SetPedAsGroupMember(ped, GroupBrinks)
		GiveWeaponToPed(ped, "WEAPON_PISTOL_MK2", 500, false, false)
		GiveWeaponToPed(ped, "WEAPON_CARBINERIFLE_MK2", 500, false, false)
		SetCurrentPedWeapon(ped, "WEAPON_CARBINERIFLE_MK2", false)
		SetPedAmmo(ped, "WEAPON_CARBINERIFLE_MK2", 500)
	end
	SetPedNeverLeavesGroup(ped, true)
end

RegisterNetEvent('null:braquage:brinks:PoliceNotify')
AddEventHandler('null:braquage:brinks:PoliceNotify', function()
	local player = ESX.GetPlayerData()
	if null.data.jobs.polices.list[ESX.PlayerData.job.name] ~= nil then
        ESX.ShowNotification("~r~Information : Un camion brinks a faire une demande d'aide !")
    end
end)

RegisterNetEvent('null:braquage:brinks:removeblips')
AddEventHandler('null:braquage:brinks:removeblips', function()
	local player = ESX.GetPlayerData()
    if null.data.jobs.polices.list[ESX.PlayerData.job.name] ~= nil then
		ESX.removeBlip("brinks_location")
    end
	theBrinks = nil
	BrinksDrive = false
	AlreadySpawn = false
end)

RegisterNetEvent('null:braquage:brinks:openvehicle')
AddEventHandler('null:braquage:brinks:openvehicle', function()
	if theBrinks ~= nil then
		SetVehicleDoorsLocked(theBrinks, 0)
		SetVehicleDoorCanBreak(theBrinks, -1, true)
		SetVehicleDoorCanBreak(theBrinks, 0, true)
	end
end)

RegisterNetEvent('null:braquage:brinks:initFin')
AddEventHandler('null:braquage:brinks:initFin', function()
	null.data.markers.register("waitingbrinks", {
		Position = vec3(725.490112, -752.409119, 25.559225),
		Public = true,
		Job = nil,
		Job2 = nil,
		Action = function()
			if PlayerStateisInVehicle then
				if IsVehicleModel(PlayerStatevehicle, "stockade") then
					DeleteEntity(PlayerStatevehicle)
					TriggerServerEvent("null:brinks:finish")
					null.data.markers.unregister("waitingbrinks")
				else
					ESX.ShowNotification("C'est pas un Brinks ca !")
				end
			else
				ESX.ShowNotification("Tu n'es pas dans un véhicule")
			end
		end
	})
	local model = "cs_lestercrest"
	ESX.Streaming.RequestModel(GetHashKey(model))
	local storePed = CreatePed(4, GetHashKey(model), 727.00476074219, -752.26354980469, 24.628215789795, 93.125053405762, false, false)
	SetBlockingOfNonTemporaryEvents(storePed, false)
	FreezeEntityPosition(storePed, true)
	DisablePedPainAudio(storePed, true)
	SetPedSeeingRange(storePed, 0)
	SetPedFleeAttributes(storePed, 0, 0)
	SetPedArmour(storePed, 200)
	SetPedSuffersCriticalHits(storePed, false)
	SetPedMaxHealth(storePed, 200)
	SetPedDiesWhenInjured(storePed, true)
	SetEntityInvincible(storePed, true)
	TaskStartScenarioInPlace(storePed, 'WORLD_HUMAN_STAND_IMPATIENT_UPRIGHT', 0, 0)
	SetModelAsNoLongerNeeded(GetHashKey(model))
end)

RegisterNetEvent('null:braquage:brinks:PoliceBlip')
AddEventHandler('null:braquage:brinks:PoliceBlip', function(targetCoords)
	local player = ESX.GetPlayerData()
	if null.data.jobs.polices.list[player.job.name] ~= nil then
        ESX.removeBlip("brinks_location")
		ESX.addBlips({
			name = 'brinks_location',
			label = 'Fourgon Blindé',
			category = nil,
			position = vector3(targetCoords.x, targetCoords.y, targetCoords.z),
			sprite = 161,
			display = 4,
			scale = 2.0,
			color = 1
		})
    end
end)

RegisterNetEvent('null:braquage:brinks:spawn', function()
    if AlreadySpawn then return end
	AlreadySpawn = true

	ESX.Game.SpawnVehicle("stockade", vec3(934.05261230469, -3.533684015274, 78.763984680176), 144.2540435791, function(vehicle)
		BrinksDrive = true
		SetVehicleNumberPlateText(vehicle, 'BRINKS') 
		SetVehicleBodyHealth(vehicle, 1000)
		ESX.Streaming.RequestModel(PedModel)
		local conductorPed = CreatePed(4, PedModel, 934.65124511719, -5.3943238258362, 78.763984680176, 302.48529052734, false, false)
		InitPedBrinks(PedModel, true)
		local coconductorPed = CreatePed(4, PedModel, 934.65124511719, -5.3943238258362, 78.763984680176, 302.48529052734, false, false)
		InitPedBrinks(coconductorPed, false, true)
		local protect1Ped = CreatePed(4, PedModel, 934.65124511719, -5.3943238258362, 78.763984680176, 302.48529052734, false, false)
		InitPedBrinks(protect1Ped)
		local protect2Ped = CreatePed(4, PedModel, 934.65124511719, -5.3943238258362, 78.763984680176, 302.48529052734, false, false)
		InitPedBrinks(protect2Ped)
		SetModelAsNoLongerNeeded(PedModel)
		TaskWarpPedIntoVehicle(conductorPed, vehicle, -1) 
		TaskWarpPedIntoVehicle(coconductorPed, vehicle, 0) 
		TaskWarpPedIntoVehicle(protect1Ped, vehicle, 1) 
		TaskWarpPedIntoVehicle(protect2Ped, vehicle, 2) 
		TaskVehicleDriveToCoordLongrange(conductorPed, vehicle, 2904.177734,4389.688477, 51.00, 50.00, 0, 20)
		Wait(1000)
		SetVehicleDoorsLocked(vehicle, 2)
		SetVehicleFuelLevel(vehicle,  100)
		SetEntityInvincible(vehicle, true)
		SetVehicleCanDeformWheels(vehicle, false)
		SetVehicleCanLeakOil(vehicle, false)
		SetVehicleCanLeakPetrol(vehicle, false)
		SetVehicleCanEngineOperateOnFire(vehicle, false)
		SetVehicleDoorCanBreak(vehicle, -1, false)
		SetVehicleDoorCanBreak(vehicle, 0, false)
		SetVehicleHighGear(vehicle, 5)
		SetVehicleCurrentRpm(vehicle, 300)
		SetVehicleBrake(vehicle, false)
		theBrinks = vehicle
		

		Citizen.CreateThread(function ()
			while true do
				Wait(10000)
				local speed = GetEntitySpeed(vehicle)*3.6
				if speed > 5 then
					BrinksDrive = true
				else
					BrinksDrive = false
				end
				if not BrinksDrive then break end
			end
			--TriggerServerEvent("null:brinks:everypedisdead")
		end)
		Citizen.CreateThread(function ()
			while true do
				local healt1 = GetEntityHealth(conductorPed)
				local healt2 = GetEntityHealth(coconductorPed)
				local healt3 = GetEntityHealth(protect1Ped)
				local healt4 = GetEntityHealth(protect2Ped)
				local total = healt1 + healt2 + healt3 + healt4
				if total <= 200 then
					TriggerServerEvent("null:brinks:everypedisdead")
				else
					local nbrAlive = 0
					if healt1 > 0 then
						nbrAlive = nbrAlive + 1
					end
					if healt2 > 0 then
						nbrAlive = nbrAlive + 1
					end
					if healt3 > 0 then
						nbrAlive = nbrAlive + 1
					end
					if healt4 > 0 then
						nbrAlive = nbrAlive + 1
					end
					TriggerServerEvent("null:brinks:updatepedalive", nbrAlive)
				end
				Wait(10000)
			end
		end)
		Citizen.CreateThread(function ()
			while BrinksDrive do
				TriggerServerEvent("null:brinks:receviecoords", GetEntityCoords(vehicle))
				Wait(5000)
			end
		end)
	end)
end)