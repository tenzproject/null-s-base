local piggyBackInProgress = false

RegisterCommand('porter', function(source, args)
	local canAction = ActionCooldown("porter", 3000)
	if not canAction then return end
	local plyPed = PlayerPedId()
	if not PlayerIsDead then
		if not piggyBackInProgress then
			piggyBackInProgress = true
			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	
			if closestDistance ~= -1 and closestDistance <= 3 then
				local target = GetPlayerServerId(closestPlayer)
					
				local targetPed = GetPlayerPed(closestPlayer)
				if not ESX.isHandsUp(targetPed) then
					return ESX.ShowNotification('🙌 Le joueur cible ne leve pas les mains')
				end
				local lib = 'anim@arena@celeb@flat@paired@no_props@'
				local anim1 = 'piggyback_c_player_a'
				local anim2 = 'piggyback_c_player_b'
				local distans = -0.07
				local distans2 = 0.0
				local height = 0.45
				local length = 100000
				local spin = 0.0
				local controlFlagMe = 49
				local controlFlagTarget = 33
				local animFlagTarget = 1
	
				TriggerServerEvent('Null:cmg2_animations:sync', lib, anim1, anim2, distans, distans2, height, target, length, spin, controlFlagMe, controlFlagTarget, animFlagTarget)
			else
				ESX.TriggerServerCallback("null:piggyback:checkOfflineIsNear", function(result) 
					if not result then
						ESX.ShowNotification('⚠️  Il n\'y personne a proximiter.')
					end
				end, PlayerState.coords)
			end
		else
			piggyBackInProgress = false
			ClearPedSecondaryTask(plyPed)
			DetachEntity(plyPed, true, false)
			local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
	
			if closestDistance ~= -1 and closestDistance <= 3 then
				local target = GetPlayerServerId(closestPlayer)
				TriggerServerEvent('Null:cmg2_animations:stop', target)
			end
		end
	end
end, false)


RegisterNetEvent('Null:cmg2_animations:syncTarget', function(targetId, animationLib, animation2, distans, distans2, height, length, spin, controlFlag)
	local target = GetPlayerFromServerId(targetId)

	if target == PlayerId() or target < 1 then
		return
	end

	local plyPed = PlayerPedId()
	local targetPed = GetPlayerPed(target)

	piggyBackInProgress = true
	RequestAnimDict(animationLib)

	while not HasAnimDictLoaded(animationLib) do
		Citizen.Wait(10)
	end

	spin = spin or 180.0

	AttachEntityToEntity(plyPed, targetPed, 0, distans2, distans, height, 0.5, 0.5, spin, false, false, false, false, 2, false)

	if controlFlag == nil then
		controlFlag = 0
	end

	TaskPlayAnim(plyPed, animationLib, animation2, 8.0, -8.0, length, controlFlag, 0, false, false, false)
end)

RegisterNetEvent('Null:cmg2_animations:syncMe', function(animationLib, animation, length, controlFlag, animFlag)
	local plyPed = PlayerPedId()
	RequestAnimDict(animationLib)

	while not HasAnimDictLoaded(animationLib) do
		Citizen.Wait(10)
	end

	Citizen.Wait(500)

	if controlFlag == nil then
		controlFlag = 0
	end

	TaskPlayAnim(plyPed, animationLib, animation, 8.0, -8.0, length, controlFlag, 0, false, false, false)
	Citizen.Wait(length)
end)

RegisterNetEvent('Null:cmg2_animations:cl_stop', function()
	local plyPed = PlayerPedId()
	piggyBackInProgress = false
	ClearPedSecondaryTask(plyPed)
	DetachEntity(plyPed, true, false)
end)

Citizen.CreateThread(function()
	while true do
		if piggyBackInProgress then
			Citizen.Wait(10)
		else
			Wait(1500)
		end

		if piggyBackInProgress then
			DisableControlAction(0, 21, true) -- INPUT_SPRINT
			DisableControlAction(0, 22, true) -- INPUT_JUMP
			DisableControlAction(0, 24, true) -- INPUT_ATTACK
			DisableControlAction(0, 44, true) -- INPUT_COVER
			DisableControlAction(0, 45, true) -- INPUT_RELOAD
			DisableControlAction(0, 140, true) -- INPUT_MELEE_ATTACK_LIGHT
			DisableControlAction(0, 141, true) -- INPUT_MELEE_ATTACK_HEAVY
			DisableControlAction(0, 142, true) -- INPUT_MELEE_ATTACK_ALTERNATE
			DisableControlAction(0, 143, true) -- INPUT_MELEE_BLOCK
			DisableControlAction(0, 144, true) -- PARACHUTE DEPLOY
			DisableControlAction(0, 145, true) -- PARACHUTE DETACH
			DisableControlAction(0, 243, true) -- INPUT_ENTER_CHEAT_CODE
			DisableControlAction(0, 257, true) -- INPUT_ATTACK2
			DisableControlAction(0, 263, true) -- INPUT_MELEE_ATTACK1
			DisableControlAction(0, 264, true) -- INPUT_MELEE_ATTACK2
			DisableControlAction(0, 73, true) -- INPUT_X
		end
	end
end)
