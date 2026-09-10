--[[ Environment ]]--
-- Time Sync --
local RateLimitNotif = false
SafeZoneLoad = false
null.data.system.safezone = {
	load = false,
	list = {},
}
local zones = nil
local disabledSafeZonesKeys = {
	{group = 2, key = 37, message = 'Vous ne pouvez pas sortir d\'arme en SafeZone'},
	{group = 0, key = 24, message = 'Vous ne pouvez pas faire ceci en SafeZone'},
	{group = 0, key = 69, message = 'Vous ne pouvez pas faire ceci en SafeZone'},
	{group = 0, key = 92, message = 'Vous ne pouvez pas faire ceci en SafeZone'},
	{group = 0, key = 106, message = 'Vous ne pouvez pas faire ceci en SafeZone'},
	{group = 0, key = 168, message = 'Vous ne pouvez pas faire ceci en SafeZone'},
	{group = 0, key = 160, message = 'Vous ne pouvez pas faire ceci en SafeZone'},
	{group = 0, key = 160, message = 'Vous ne pouvez pas faire ceci en SafeZone'},

}

Citizen.CreateThread(function()
    Wait(2000)
    TriggerServerEvent('null:safezone:init')
end)


RegisterNetEvent('null:safezone:init')
AddEventHandler('null:safezone:init', function(Table)
	if null.data.system.safezone.list ~= nil then
		null.data.system.safezone.list = nil
	end
	if zones ~= nil then
		for k,v in pairs(zones) do
			v:destroy()
		end
	end
	zones = {}
	null.data.system.safezone.list = Table
	null.data.system.safezone.load = true

	for k,v in pairs(null.data.system.safezone.list) do
		local polyzone = PolyZone:Create(v.points, {
            name = ("safezone_%s"):format(v.id),
            data = {
                id = v.id,
                name = v.name,
                pos = v.position,
            }
        })
        table.insert(zones, polyzone)

		polyzone:onPlayerInOut(function(isPointInside, point)
			if isPointInside then
				PlayerState.safeZoneName = v.name
				PlayerState.isInSafeZone = true
			elseif not isPointInside and PlayerState.safeZoneName == v.name then
				PlayerState.isInSafeZone = false
			end
		end)
	end
end)

local notifIn, notifOut = false, false
local closestZone = 1

local function setSafeZoneUi(state)
	local ok, err = pcall(function()
		TriggerEvent("null-ui:setSafeZone", state)
	end)

	if not ok then
		null.DebugPrint(("Safezone UI event failed: %s"):format(tostring(err)))
	end
end



Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
	while not NetworkIsPlayerActive(PlayerId()) do
		Citizen.Wait(0)
	end

	while null.data.system.safezone.load == false do
		Wait(10)
	end

	while true do
		local plyPed = PlayerPedId()
		local src = source
		if PlayerState.isInSafeZone then
			Wait(0)
		else
			Wait(3000)
		end

		if PlayerState.isInSafeZone then
			local weapon = GetSelectedPedWeapon(PlayerPedId())
			if null.data.jobs.polices.list[ESX.PlayerData.job.name] ~= nil then 
			else
				SetCurrentPedWeapon(plyPed, `WEAPON_UNARMED`, true)
				null.DebugPrint("Safezone, set unarmed")
			end
			if not notifIn then
				--NetworkSetFriendlyFireOption(false)
				while not DisplayHud do Wait(100) end
				setSafeZoneUi(true)
				null.DebugPrint("Entered safezone: " .. (PlayerState.safeZoneName or "unknown"))
				--ESX.ShowNotification("Vous êtes en SafeZone","Protection")

				notifIn = true
				notifOut = false
			end
		else
			if not notifOut then
				--NetworkSetFriendlyFireOption(true)
				while not DisplayHud do Wait(100) end
				setSafeZoneUi(false)
				null.DebugPrint("Exited safezone: " .. (PlayerState.safeZoneName or "unknown"))
				--ESX.ShowNotification("Vous n\'êtes plus en SafeZone","Protection")

				notifOut = true
				notifIn = false
			end
		end

		if notifIn then

			--DisablePlayerFiring(player, true)

			for i = 1, #disabledSafeZonesKeys, 1 do
				DisableControlAction(disabledSafeZonesKeys[i].group, disabledSafeZonesKeys[i].key, true)

				if IsDisabledControlJustPressed(disabledSafeZonesKeys[i].group, disabledSafeZonesKeys[i].key) then
					SetCurrentPedWeapon(player, `WEAPON_UNARMED`, true)
					null.DebugPrint("Safezone, set unarmed")

					if disabledSafeZonesKeys[i].message then
						if not RateLimitNotif then 
							if  null.data.jobs.polices.list[ESX.PlayerData.job.name] ~= nil then 
							else
								ESX.ShowNotification(disabledSafeZonesKeys[i].message,"warning")
							end
							RateLimitNotif = true
							Citizen.SetTimeout(3000, function()
								RateLimitNotif = false
							end)
						end
					end
				end
			end
		end
	end
end))

--[[CreateThread(function()
	while true do
		Wait(1500)
		local PlayerPed = PlayerPedId()
		local players = GetActivePlayers()

		for i = 1, #players, 1 do
			local otherPed = GetPlayerPed(players[i])

			if IsPedInAnyVehicle(otherPed, false) then
				local otherVeh = GetVehiclePedIsUsing(otherPed)
				if not IsThisModelABoat(GetEntityModel(otherVeh)) then
					SetEntityNoCollisionEntity(PlayerPed, otherVeh, true)
					SetEntityNoCollisionEntity(otherVeh, PlayerPed, true)
				end
			end
		end
	end
end)]]

function GetSafeZone()
	return notifIn
end

exports("GetSafeZone", GetSafeZone)
