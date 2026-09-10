
local holdingHostageInProgress, beingHeldHostage, holdingHostage = false, false
local takeHostageAnimNamePlaying, takeHostageAnimDictPlaying, takeHostageControlFlagPlaying = '', '', 0

local hostageAllowedWeapons = {
	`WEAPON_PISTOL`,
	`WEAPON_PISTOL_MK2`,
	`WEAPON_COMBATPISTOL`,
	`WEAPON_PISTOL50`,
	`WEAPON_SNSPISTOL`,
	`WEAPON_SNSPISTOL_MK2`,
	`WEAPON_HEAVYPISTOL`,
	`WEAPON_VINTAGEPISTOL`,
	`WEAPON_REVOLVER`,
	`WEAPON_REVOLVER_MK2`,
	`WEAPON_DOUBLEACTION`,
	`WEAPON_APPISTOL`,
	`WEAPON_NAVYREVOLVER`,
	`WEAPON_GADGETPISTOL`,
	`WEAPON_GLOCK`
}

function releaseHostage()
	local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

	if closestDistance ~= -1 and closestDistance <= 3 then
		local target = GetPlayerServerId(closestPlayer)

		local lib = 'reaction@shove'
		local anim1 = 'shove_var_a'
		local lib2 = 'reaction@shove'
		local anim2 = 'shoved_back'
		local distans = 0.11
		local distans2 = -0.24
		local height = 0.0
		local spin = 0.0
		local length = 100000
		local controlFlagMe = 120
		local controlFlagTarget = 0
		local animFlagTarget = 1
		local attachFlag = false

		TriggerServerEvent('Null:cmg3_animations:sync', lib, lib2, anim1, anim2, distans, distans2, height, target, length, spin, controlFlagMe, controlFlagTarget, animFlagTarget, attachFlag)
	end
end

function killHostage()
	local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

	if closestDistance ~= -1 and closestDistance <= 3 then
		local target = GetPlayerServerId(closestPlayer)

		local lib = 'anim@gangops@hostage@'
		local anim1 = 'perp_fail'
		local lib2 = 'anim@gangops@hostage@'
		local anim2 = 'victim_fail'
		local distans = 0.11
		local distans2 = -0.24
		local height = 0.0
		local spin = 0.0
		local length = 0.2
		local controlFlagMe = 168
		local controlFlagTarget = 0
		local animFlagTarget = 1
		local attachFlag = false

		TriggerServerEvent('Null:cmg3_animations:sync', lib, lib2, anim1, anim2, distans, distans2, height, target, length, spin, controlFlagMe, controlFlagTarget, animFlagTarget, attachFlag)
	end
end

RegisterCommand('otage', function()
		if not GetSafeZone() then
			if not PlayerIsDead then
				local plyPed = PlayerPedId()
				local currentWeapon = GetSelectedPedWeapon(plyPed)
				local canTakeHostage, foundWeapon = false, false
		
				ClearPedSecondaryTask(plyPed)
				DetachEntity(plyPed, true, false)
		
				for i = 1, #hostageAllowedWeapons do
					if currentWeapon == hostageAllowedWeapons[i] then
						canTakeHostage = true
						foundWeapon = hostageAllowedWeapons[i]
					end
				end
		
				if not foundWeapon then
					for i = 1, #hostageAllowedWeapons do
						if HasPedGotWeapon(plyPed, hostageAllowedWeapons[i], false) then
							if GetAmmoInPedWeapon(plyPed, hostageAllowedWeapons[i]) > 0 then
								canTakeHostage = true
								foundWeapon = hostageAllowedWeapons[i]
								break
							end
						end
					end
				end
		
				if canTakeHostage then
					if not holdingHostageInProgress then
						local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		
						if closestDistance ~= -1 and closestDistance <= 3 then
							local target = GetPlayerServerId(closestPlayer)

							ESX.TriggerServerCallback("null:dead:IsPlayerDead", function(result)
								if (result) then
									if IsPlayerDead(closestPlayer) then
										ESX.ShowNotification('Vous ne pouvez porter ce joueur !')
									else
										local lib = 'anim@gangops@hostage@'
										local anim1 = 'perp_idle'
										local lib2 = 'anim@gangops@hostage@'
										local anim2 = 'victim_idle'
										local distans = 0.11
										local distans2 = -0.24
										local height = 0.0
										local spin = 0.0
										local length = 100000
										local controlFlagMe = 49
										local controlFlagTarget = 49
										local animFlagTarget = 50
										local attachFlag = true
				
										SetCurrentPedWeapon(plyPed, foundWeapon, true)
										holdingHostageInProgress = true
										holdingHostage = true
										TriggerServerEvent('Null:cmg3_animations:sync', lib, lib2, anim1, anim2, distans, distans2, height, target, length, spin, controlFlagMe, controlFlagTarget, animFlagTarget, attachFlag)
									end
								else
									ESX.ShowNotification('Vous ne pouvez pas faire ça.')
									return
								end
							end, target)
						else
							ESX.ShowNotification('Aucun joueur à proximité !')
						end
					end
				else
					ESX.ShowNotification('Vous avez besoin d\'un pistolet de combat ou un pistolet pour prendre un otage !')
				end
			end
		else
			ESX.ShowNotification('Vous ne pouvez pas utilisez cette commande en Zone Safe')
		end
end)


RegisterNetEvent('Null:cmg3_animations:syncTarget', function(target, animationLib, animation2, distans, distans2, height, length, spin, controlFlag, animFlagTarget, attach)
	local plyPed = PlayerPedId()
	local targetPed = GetPlayerPed(GetPlayerFromServerId(target))

	if holdingHostageInProgress then
		holdingHostageInProgress = false
	else
		holdingHostageInProgress = true
	end

	beingHeldHostage = true
	RequestAnimDict(animationLib)

	while not HasAnimDictLoaded(animationLib) do
		Citizen.Wait(10)
	end

	if spin == nil then
		spin = 180.0
	end

	if attach then
		AttachEntityToEntity(plyPed, targetPed, 0, distans2, distans, height, 0.5, 0.5, spin, false, false, false, false, 2, false)
	end
	
	if controlFlag == nil then
		controlFlag = 0
	end

	if animation2 == 'victim_fail' then
		SetEntityHealth(plyPed, 0)
		DetachEntity(plyPed, true, false)
		TaskPlayAnim(plyPed, animationLib, animation2, 8.0, -8.0, length, controlFlag, 0, false, false, false)
		beingHeldHostage = false
		holdingHostageInProgress = false
	elseif animation2 == 'shoved_back' then
		holdingHostageInProgress = false
		DetachEntity(plyPed, true, false)
		TaskPlayAnim(plyPed, animationLib, animation2, 8.0, -8.0, length, controlFlag, 0, false, false, false)
		beingHeldHostage = false
	else
		TaskPlayAnim(plyPed, animationLib, animation2, 8.0, -8.0, length, controlFlag, 0, false, false, false)
	end

	takeHostageAnimNamePlaying = animation2
	takeHostageAnimDictPlaying = animationLib
	takeHostageControlFlagPlaying = controlFlag
end)

RegisterNetEvent('Null:cmg3_animations:syncMe', function(animationLib, animation, length, controlFlag, animFlag)
	local plyPed = PlayerPedId()

	ClearPedSecondaryTask(plyPed)
	RequestAnimDict(animationLib)

	while not HasAnimDictLoaded(animationLib) do
		Citizen.Wait(10)
	end

	if controlFlag == nil then
		controlFlag = 0
	end

	TaskPlayAnim(playerPed, animationLib, animation, 8.0, -8.0, length, controlFlag, 0, false, false, false)

	takeHostageAnimNamePlaying = animation
	takeHostageAnimDictPlaying = animationLib
	takeHostageControlFlagPlaying = controlFlag

	if animation == 'perp_fail' then
		SetPedShootsAtCoord(plyPed, 0.0, 0.0, 0.0, 0)
		holdingHostageInProgress = false
	elseif animation == 'shove_var_a' then
		Citizen.Wait(900)
		ClearPedSecondaryTask(plyPed)
		holdingHostageInProgress = false
	end
end)

RegisterNetEvent('Null:cmg3_animations:cl_stop', function()
	local plyPed = PlayerPedId()

	holdingHostageInProgress = false
	beingHeldHostage = false
	holdingHostage = false

	ClearPedSecondaryTask(plyPed)
	DetachEntity(plyPed, true, false)
end)

Citizen.CreateThread(function()
	while true do
		if (holdingHostage or beingHeldHostage) and takeHostageAnimDictPlaying ~= '' and takeHostageAnimNamePlaying ~= '' then
			Citizen.Wait(0)
		else
			Wait(1500)
		end

		if (holdingHostage or beingHeldHostage) and takeHostageAnimDictPlaying ~= '' and takeHostageAnimNamePlaying ~= '' then
			while not IsEntityPlayingAnim(PlayerPedId(), takeHostageAnimDictPlaying, takeHostageAnimNamePlaying, 3) do
				TaskPlayAnim(PlayerPedId(), takeHostageAnimDictPlaying, takeHostageAnimNamePlaying, 8.0, -8.0, 100000, takeHostageControlFlagPlaying, 0, false, false, false)
				Citizen.Wait(0)
			end
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		if holdingHostage or beingHeldHostage then
			Wait(0)
		else
			Wait(1500)
		end

		if holdingHostage then
			local plyPed = PlayerPedId()
			local plyCoords = GetEntityCoords(plyPed)

			if IsEntityDead(plyPed) then
				holdingHostage = false
				holdingHostageInProgress = false

				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

				if closestDistance ~= -1 and closestDistance <= 3 then
					local target = GetPlayerServerId(closestPlayer)
					TriggerServerEvent('Null:cmg3_animations:stop', target)
				end

				Citizen.Wait(100)
				releaseHostage()
			end

			DisableControlAction(0, 24, true) -- disable attack
			DisableControlAction(0, 25, true) -- disable aim
			DisableControlAction(0, 47, true) -- disable weapon
			DisableControlAction(0, 58, true) -- disable weapon
			DisablePlayerFiring(plyPed, true)

			ESX.Game.Utils.DrawText3D(plyCoords, 'Appuyer sur [G] pour relâcher, [H] pour tuer', 0.5)

			if IsDisabledControlJustPressed(0, 47) then
				holdingHostage = false
				holdingHostageInProgress = false

				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

				if closestDistance ~= -1 and closestDistance <= 3 then
					local target = GetPlayerServerId(closestPlayer)
					TriggerServerEvent('Null:cmg3_animations:stop', target)
				end

				Citizen.Wait(100)
				releaseHostage()
			elseif IsDisabledControlJustPressed(0, 74) then
				holdingHostage = false
				holdingHostageInProgress = false

				local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

				if closestDistance ~= -1 and closestDistance <= 3 then
					local target = GetPlayerServerId(closestPlayer)
					TriggerServerEvent('Null:cmg3_animations:stop', target)
				end

				killHostage()
			end
		end

		if beingHeldHostage then
			DisableControlAction(0, 21, true) -- disable sprint
			DisableControlAction(0, 24, true) -- disable attack
			DisableControlAction(0, 25, true) -- disable aim
			DisableControlAction(0, 47, true) -- disable weapon
			DisableControlAction(0, 58, true) -- disable weapon
			DisableControlAction(0, 263, true) -- disable melee
			DisableControlAction(0, 264, true) -- disable melee
			DisableControlAction(0, 257, true) -- disable melee
			DisableControlAction(0, 140, true) -- disable melee
			DisableControlAction(0, 141, true) -- disable melee
			DisableControlAction(0, 142, true) -- disable melee
			DisableControlAction(0, 143, true) -- disable melee
			DisableControlAction(0, 75, true) -- disable exit vehicle
			DisableControlAction(27, 75, true) -- disable exit vehicle
			DisableControlAction(0, 22, true) -- disable jump
			DisableControlAction(0, 32, true) -- disable move up
			DisableControlAction(0, 268, true)
			DisableControlAction(0, 33, true) -- disable move down
			DisableControlAction(0, 269, true)
			DisableControlAction(0, 34, true) -- disable move left
			DisableControlAction(0, 270, true)
			DisableControlAction(0, 35, true) -- disable move right
			DisableControlAction(0, 271, true)
		end
	end
end)

