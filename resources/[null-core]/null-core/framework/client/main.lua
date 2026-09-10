if not MACROS_INIT then return end

local isLoadoutLoaded, isPaused, disableUi, isPlayerSpawned, isDead, pickups = false, false, false, false, false, {}

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerLoaded = true
	ESX.PlayerData = xPlayer
	ESX.RebuildInventoryCache()
	ESX.RebuildLoadoutCache()
    RemoveMultiplayerBankCash()
    RemoveMultiplayerWalletCash()
	ReplaceHudColourWithRgba(116,tonumber(ESX.Config("r")),tonumber(ESX.Config("g")),tonumber(ESX.Config("b")),255)
	TriggerServerEvent('null:cache:requestVersion')
end)

RegisterNetEvent('null:cache:versionChanged')
AddEventHandler('null:cache:versionChanged', function(version)
	SendNUIMessage({ action = 'cacheVersion', version = version })
end)

RegisterNetEvent('esx:setMaxWeight')
AddEventHandler('esx:setMaxWeight', function(newMaxWeight)
	ESX.PlayerData.maxWeight = newMaxWeight
end)

RegisterNetEvent('esx:setStaffMode')
AddEventHandler('esx:setStaffMode', function(bool)
	ESX.PlayerData.staffmode = bool
end)

AddEventHandler('playerSpawned', function(spawn, isFirstSpawn)
	null.fct.waitPlayerLoaded()

	TriggerEvent('esx:restoreLoadout')

	if isFirstSpawn then
		TriggerServerEvent('esx:positionSaveReady')
	end

	TriggerServerEvent("null:esx:loadname", GetPlayerName(PlayerId()))

	isLoadoutLoaded, isPlayerSpawned, isDead = true, true, false
	SetCanAttackFriendly(PlayerPedId(), true, true)
	NetworkSetFriendlyFireOption(true)
end)

AddEventHandler('esx:onPlayerDeath', function() isDead = true end)
AddEventHandler('EMS:ReviveClientPlayer', function() isDead = false end)
AddEventHandler('Null:skinchanger:loadDefaultModel', function() isLoadoutLoaded = false end)
function ESX.getIsDead() return isDead end
exports("playerIsDead", ESX.getIsDead)

AddEventHandler('Null:skinchanger:modelLoaded', function()
	null.fct.waitPlayerLoaded()
	
	TriggerEvent('esx:restoreLoadout')
end)

AddEventHandler('esx:restoreLoadout', function()
	local playerPed = PlayerPedId()
	--local ammoTypes = {}

	RemoveAllPedWeapons(playerPed, true)

	for i = 1, #ESX.PlayerData.loadout, 1 do
		local weaponName = ESX.PlayerData.loadout[i].name
		local weaponHash = GetHashKey(weaponName)

		GiveWeaponToPed(playerPed, weaponHash, 250, false, false)
		--local ammoType = GetPedAmmoTypeFromWeapon(playerPed, weaponHash)

		for j = 1, #ESX.PlayerData.loadout[i].components, 1 do
			local weaponComponent = ESX.PlayerData.loadout[i].components[j]
			if weaponComponent ~= nil and weaponName ~= nil then
				local component = ESX.GetWeaponComponent(weaponName, weaponComponent)
				if component then
					GiveWeaponComponentToPed(playerPed, weaponHash, component.hash)
				end
			end
		end

		--if not ammoTypes[ammoType] then
		--	AddAmmoToPed(playerPed, weaponHash, ESX.PlayerData.loadout[i].ammo)
		--	ammoTypes[ammoType] = true
		--end
	end

	isLoadoutLoaded = true
end)

RegisterNetEvent('esx:editWeapon')
AddEventHandler('esx:editWeapon', function(weapon, data)
	local weaponData = ESX.PlayerData.loadoutByName[weapon]
	if weaponData then
		for k,v in pairs(data) do
			weaponData[k] = v
		end
	end
end)

RegisterNetEvent('esx:editDurability')
AddEventHandler('esx:editDurability', function(weapon, newvalue)
	local weaponData = ESX.PlayerData.loadoutByName[weapon]
	if weaponData then
		weaponData.durability = newvalue
	end
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
	if account.name == 'cash' then
        StatSetInt(`MP0_WALLET_BALANCE`, account.money)
    end
    if account.name == 'bank' then
        StatSetInt(`BANK_BALANCE`, account.money)
    end
    RemoveMultiplayerBankCash()
    RemoveMultiplayerWalletCash()
	local AccountsAmountDifference = {cash = 0, bank = 0, dirtycash = 0}
	for i = 1, #ESX.PlayerData.accounts, 1 do
		if ESX.PlayerData.accounts[i].name == account.name then
			AccountsAmountDifference[account.name] = account.money - ESX.PlayerData.accounts[i].money
			ESX.PlayerData.accounts[i] = account
			break
		end
	end

	for k,v in pairs(AccountsAmountDifference) do
		if v ~= 0 then
			if v > 0 then
				ESX.UI.ShowInventoryItemNotification(true, "$ ("..ESX.GetAccountLabel(k)..")", v, k)
			else
				ESX.UI.ShowInventoryItemNotification(false, "$ ("..ESX.GetAccountLabel(k)..")", -v, k)
			end
		end	
	end

	ESX.UI.HUD.UpdateElement('account_' .. account.name, {
		money = ESX.Math.GroupDigits(account.money)
	})
end)

RegisterNetEvent('esx:addInventoryItem')
AddEventHandler('esx:addInventoryItem', function(item)
	ESX.UI.ShowInventoryItemNotification(true, item.label, item.count, item.name)
	table.insert(ESX.PlayerData.inventory, item)
	ESX.PlayerData.inventoryByName[item.name] = item
end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(item, identifier)
	for i = 1, #ESX.PlayerData.inventory, 1 do
		if ESX.PlayerData.inventory[i].name == item.name and (not identifier or (item.unique and ESX.PlayerData.inventory[i].extra.identifier and ESX.PlayerData.inventory[i].extra.identifier == identifier)) then
			ESX.UI.ShowInventoryItemNotification(false, item.label, item.count, item.name)
			table.remove(ESX.PlayerData.inventory, i)
			ESX.PlayerData.inventoryByName[item.name] = nil
			break
		end
	end
end)

RegisterNetEvent('esx:updateItemCount')
AddEventHandler('esx:updateItemCount', function(add, itemName, count)
	local item = ESX.PlayerData.inventoryByName[itemName]
	if item then
		ESX.UI.ShowInventoryItemNotification(add, item.label, add and (count - item.count) or (item.count - count), item.name)
		item.count = count
	end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    TriggerServerEvent("vFrame:setjob", job.name, ESX.PlayerData.job.name)
	ESX.PlayerData.job = job

	ESX.UI.HUD.UpdateElement('job', {
		job_label = job.label,
		grade_label = job.grade_label
	})
end)

RegisterNetEvent('esx:setJob2')
AddEventHandler('esx:setJob2', function(job2)
    TriggerServerEvent("vFrame:setjob2", job2.name, ESX.PlayerData.job2.name)
	ESX.PlayerData.job2 = job2

	ESX.UI.HUD.UpdateElement('job2', {
		job2_label = job2.label,
		grade2_label = job2.grade_label
	})
end)

RegisterNetEvent('esx:setGroup')
AddEventHandler('esx:setGroup', function(group, lastGroup)
	ESX.PlayerData.group = group
    TriggerServerEvent("null:staff:requestGroupVerif")
end)

RegisterNetEvent('esx:addWeapon')
AddEventHandler('esx:addWeapon', function(weaponName, weaponAmmo, weaponMetadata, serialNumber, permanent, durability)
	if ESX.PlayerData.loadoutByName[weaponName] then return end
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	local weaponLabel = ESX.GetWeaponLabel(weaponName)
	ESX.UI.ShowInventoryItemNotification(true, weaponLabel, 1, weaponName)
	local weaponData = {
		name = weaponName,
		ammo = weaponAmmo,
		label = weaponLabel,
		components = {},
		metadata = weaponMetadata,
		permanent = permanent,
		serialnumber = serialNumber,
		durability = Config.AmmunationShop.repairSysteme and durability or 0
	}
	table.insert(ESX.PlayerData.loadout, weaponData)
	ESX.PlayerData.loadoutByName[weaponName] = weaponData
	GiveWeaponToPed(playerPed, weaponHash, weaponAmmo, false, false)
end)

RegisterNetEvent('esx:editWeaponMetadata')
AddEventHandler('esx:editWeaponMetadata', function(weaponName, weaponMetadata)
	local weapon = ESX.PlayerData.loadoutByName[weaponName]
	if weapon then
		weapon.metadata = weaponMetadata
	end
end)

RegisterNetEvent('esx:addWeaponComponent')
AddEventHandler('esx:addWeaponComponent', function(weaponName, weaponComponent)
	for i = 1, #ESX.PlayerData.loadout, 1 do
		if ESX.PlayerData.loadout[i].name == weaponName then
			local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

			if component then
				local found = false

				for j = 1, #ESX.PlayerData.loadout[i].components, 1 do
					if ESX.PlayerData.loadout[i].components[j] == weaponComponent then
						found = true
						break
					end
				end

				if not found then
					local playerPed = PlayerPedId()
					local weaponHash = GetHashKey(weaponName)

					ESX.UI.ShowInventoryItemNotification(true, component.label, false)
					table.insert(ESX.PlayerData.loadout[i].components, weaponComponent)
					GiveWeaponComponentToPed(playerPed, weaponHash, component.hash)
				end
			end
		end
	end
end)

RegisterNetEvent('esx:setWeaponAmmo')
AddEventHandler('esx:setWeaponAmmo', function(weaponName, weaponAmmo)
	local weapon = ESX.PlayerData.loadoutByName[weaponName]
	if weapon then
		weapon.ammo = weaponAmmo
		SetPedAmmo(PlayerPedId(), GetHashKey(weaponName), weaponAmmo)
	end
end)

RegisterNetEvent('esx:removeWeapon')
AddEventHandler('esx:removeWeapon', function(weaponName, ammo)
	if not ESX.PlayerData.loadoutByName[weaponName] then return end
	local playerPed = PlayerPedId()
	local weaponHash = GetHashKey(weaponName)
	local weaponLabel = ESX.GetWeaponLabel(weaponName)
	ESX.UI.ShowInventoryItemNotification(false, weaponLabel, 1, weaponName)
	for i = 1, #ESX.PlayerData.loadout, 1 do
		if ESX.PlayerData.loadout[i].name == weaponName then
			table.remove(ESX.PlayerData.loadout, i)
			break
		end
	end
	ESX.PlayerData.loadoutByName[weaponName] = nil
	RemoveWeaponFromPed(playerPed, weaponHash)
end)

RegisterNetEvent('esx:removeWeaponComponent')
AddEventHandler('esx:removeWeaponComponent', function(weaponName, weaponComponent)
	for i = 1, #ESX.PlayerData.loadout, 1 do
		if ESX.PlayerData.loadout[i].name == weaponName then
			local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

			if component then
				for j = 1, #ESX.PlayerData.loadout[i].components, 1 do
					if ESX.PlayerData.loadout[i].components[j] == weaponComponent then
						local playerPed = PlayerPedId()
						local weaponHash = GetHashKey(weaponName)

						ESX.UI.ShowInventoryItemNotification(false, component.label, false)
						table.remove(ESX.PlayerData.loadout[i].components, j)
						RemoveWeaponComponentFromPed(playerPed, weaponHash, component.hash)
						break
					end
				end
			end
		end
	end
end)

-- Commands
RegisterNetEvent('esx:teleport')
AddEventHandler('esx:teleport', function(coords)
	ESX.Game.Teleport(PlayerPedId(), coords)
end)

RegisterNetEvent('esx:head')
AddEventHandler('esx:head', function(heading)
	SetEntityHeading(PlayerPedId(), heading)
end)

RegisterNetEvent('esx:freeze')
AddEventHandler('esx:freeze', function(bool)
	FreezeEntityPosition(PlayerPedId(), bool)
end)

RegisterNetEvent('esx:spawnVehicleLocal_client')
AddEventHandler('esx:spawnVehicleLocal_client', function(model, pCoords, pHeading)
	model = (type(model) == 'number' and model or GetHashKey(model))
	if IsModelInCdimage(model) then
		ESX.Game.Teleport(PlayerPedId(), pCoords)
		Wait(100)
		ESX.Game.SpawnVehicle(model, pCoords, pHeading, function(vehicle) 
			TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
		end)
	else
		TriggerEvent('chat:addMessage', { args = { '^1SYSTEM', 'Modèle de véhicules invalide' } })
	end
end)

RegisterNetEvent('esx:createPickup')
AddEventHandler('esx:createPickup', function(pickupId, label, coords, type, name, components)
	local pickupObject

	ESX.Game.SpawnLocalObject('prop_cs_package_01', coords, function(obj)
		pickupObject = obj
	end)

	while not pickupObject do
		Citizen.Wait(100)
	end

	SetEntityAsMissionEntity(pickupObject, false, false)
	PlaceObjectOnGroundProperly(pickupObject)
	FreezeEntityPosition(pickupObject, true)

	pickups[pickupId] = {
		id = pickupId,
		obj = pickupObject,
		label = label,
		inRange = false,
		coords = coords
	}
end)

RegisterNetEvent('esx:createMissingPickups')
AddEventHandler('esx:createMissingPickups', function(missingPickups)
	for pickupId, pickup in pairs(missingPickups) do
		local pickupObject = nil

		ESX.Game.SpawnLocalObject('prop_cs_package_01', pickup.coords, function(obj)
			pickupObject = obj
		end)

		while pickupObject == nil do
			Citizen.Wait(100)
		end

		SetEntityAsMissionEntity(pickupObject, false, false)
		PlaceObjectOnGroundProperly(pickupObject)
		FreezeEntityPosition(pickupObject, true)

		pickups[pickupId] = {
			id = pickupId,
			obj = pickupObject,
			label = pickup.label,
			inRange = false,
			coords = pickup.coords
		}
	end
end)

RegisterNetEvent('esx:removePickup')
AddEventHandler('esx:removePickup', function(id)
	ESX.Game.DeleteObject(pickups[id].obj)
	pickups[id] = nil
end)

RegisterNetEvent('esx:deleteVehicle')
AddEventHandler('esx:deleteVehicle', function(radius)
	local NewVehicleList = {}
	local playerPed = PlayerPedId()
	if radius and tonumber(radius) then
		radius = tonumber(radius) + 0.01
		local vehicles = ESX.Game.GetVehiclesInArea(GetEntityCoords(playerPed, false), radius)
		for k,v in pairs(vehicles) do 
			table.insert(NewVehicleList, NetworkGetNetworkIdFromEntity(v))
		end
		TriggerServerEvent('zgeg:DeleteVehicle', NewVehicleList, true)
	else
		local vehicle, attempt = ESX.Game.GetVehicleInDirection(), 0
		if IsPedInAnyVehicle(playerPed, true) then
			vehicle = GetVehiclePedIsIn(playerPed, false)
		end
		TriggerServerEvent('zgeg:DeleteVehicle', vehicle, false)
	end
end)

AddEventHandler('Null:showHud', function(value)
	disableUi = value
end)


-- Pickups
--Citizen.CreateThread(function()
--	while true do
--		Wait(0)
--		local playerPed = PlayerPedId()
--		local plyCoords = GetEntityCoords(playerPed, false)
--		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
--
--		for k, v in pairs(pickups) do
--			local distance = #(plyCoords - v.coords)
--
--			if distance < 5 then
--				local label = v.label
--
--				if distance < 1 then
--					if IsControlJustReleased(0, 38) then
--						if IsPedOnFoot(playerPed) then
--							if (closestDistance == -1 or closestDistance > 3) then
--								local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
--								ESX.Streaming.RequestAnimDict(dict)
--								TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
--								Citizen.Wait(1000)
--
--								TriggerServerEvent('esx:onPickup', v.id)
--								PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
--							else
--								ESX.ShowNotification('Vous ne devez pas être entouré de joueurs pour effectuer cette action !')
--							end
--						else
--							ESX.ShowNotification('Vous devez être à pied pour effectuer cette action !')
--						end
--					end
--
--					label = ('%s\n%s'):format(label, _U('threw_pickup_prompt'))
--				end
--
--				ESX.Game.Utils.DrawText3D(vector3(v.coords.x, v.coords.y, v.coords.z + 0.25), label, 1.2, 0)
--			else
--				Wait(750)
--			end
--		end
--	end
--end)

-- Last position
Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
	while true do
		Citizen.Wait(15000)
		local playerPed = PlayerPedId()

		if ESX.PlayerLoaded and isPlayerSpawned then
			if not IsEntityDead(playerPed) then
				ESX.PlayerData.lastPosition = GetEntityCoords(playerPed, false)
			end
		end

		if IsEntityDead(playerPed) and isPlayerSpawned then
			isPlayerSpawned = false
		end
	end
end))

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
	while true do
		Citizen.Wait(5*60*1000)
		TriggerServerEvent("null:esx:updateplaytime")
	end
end))

-- Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
-- 	null.fct.waitPlayerLoaded()

-- 	local playerPed = PlayerPedId()
	
-- 	if playerPed and playerPed ~= -1 then
-- 		while GetResourceState('spawnmanager') ~= 'started' do
-- 			Citizen.Wait(100)
-- 		end
-- 		TriggerEvent('spawnmanager:spawnPlayer', {model = `mp_m_freemode_01`, coords = ESX.PlayerData.lastPosition, heading = 0.0})
-- 		return
-- 	end
-- end))

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
	while true do
		Citizen.Wait(100)

		if NetworkIsSessionStarted() then
			TriggerServerEvent('esx:firstJoinProper')
			return
		end
	end
end))