local cloudOpacity = 0.10 -- (default: 0.01)
local muteSound = true -- (default: true)

local function ToggleSound(state)
	if state then
		StartAudioScene("MP_LEADERBOARD_SCENE");
	else
		StopAudioScene("MP_LEADERBOARD_SCENE");
	end
end

local function InitialSetup()
	SetManualShutdownLoadingScreenNui(true)
	ToggleSound(muteSound)
	if not IsPlayerSwitchInProgress() then
		SwitchOutPlayer(PlayerPedId(), 0, 1)
	end
end

local function ClearScreen()
	SetCloudHatOpacity(cloudOpacity)
	HideHudAndRadarThisFrame()
	SetDrawOrigin(0.0, 0.0, 0.0, 0)
end


null.fct.utils.SkyCam = LPH_NO_VIRTUALIZE(function(time)
    if time == nil then time = 5000 end
	InitialSetup()
	
	while GetPlayerSwitchState() ~= 5 do
		Citizen.Wait(0)
		ClearScreen()
	end
	ShutdownLoadingScreen()
	ClearScreen()
	Citizen.Wait(0)

	ShutdownLoadingScreenNui()
	
	ClearScreen()
	Citizen.Wait(0)
	ClearScreen()
	--DoScreenFadeIn(500)
	while not IsScreenFadedIn() do
		Citizen.Wait(0)
		ClearScreen()
	end
    null.DisplayHud(false, 999)
	local timer = GetGameTimer()
	-- Re-enable the sound in case it was muted.
	ToggleSound(false)
	while true do
		ClearScreen()
		Citizen.Wait(0) 
			
		if GetGameTimer() - timer > time then
			-- Switch to the player.
			SwitchInPlayer(PlayerPedId())
			ClearScreen()
			RequestModel(Modelveh)

			while GetPlayerSwitchState() ~= 12 do
				Citizen.Wait(0)
				ClearScreen()
			end
			null.DisplayHud(true, 999)
			break
		end
	end
	ClearDrawOrigin()
    null.DisplayHud(true, 999)
end)

null.fct.utils.SkyTransportCoords = LPH_NO_VIRTUALIZE(function(time, coords)
	if coords == nil then return end
    if time == nil then time = 5000 end
	InitialSetup()
	
	while GetPlayerSwitchState() ~= 5 do
		Citizen.Wait(0)
		ClearScreen()
	end
	ShutdownLoadingScreen()
	ClearScreen()
	Citizen.Wait(0)
	SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
	ShutdownLoadingScreenNui()
	
	ClearScreen()
	Citizen.Wait(0)
	ClearScreen()
	--DoScreenFadeIn(500)
	while not IsScreenFadedIn() do
		Citizen.Wait(0)
		ClearScreen()
	end
    null.DisplayHud(false, 999)
	local timer = GetGameTimer()
	-- Re-enable the sound in case it was muted.
	ToggleSound(false)
	while true do
		ClearScreen()
		Citizen.Wait(0) 
			
		if GetGameTimer() - timer > time then
			-- Switch to the player.
			SwitchInPlayer(PlayerPedId())
			ClearScreen()
			RequestModel(Modelveh)

			while GetPlayerSwitchState() ~= 12 do
				Citizen.Wait(0)
				ClearScreen()
			end
			null.DisplayHud(true, 999)
			break
		end
	end
	ClearDrawOrigin()
	null.DisplayHud(true, 999)
end)

null.fct.utils.SkyTransportWipe = LPH_NO_VIRTUALIZE(function(time)
    if time == nil then time = 5000 end
	InitialSetup()
	
	while GetPlayerSwitchState() ~= 5 do
		Citizen.Wait(0)
		ClearScreen()
	end
	ShutdownLoadingScreen()
	ClearScreen()
	Citizen.Wait(0)

	ShutdownLoadingScreenNui()
	
	ClearScreen()
	Citizen.Wait(0)
	ClearScreen()
	--DoScreenFadeIn(500)
	while not IsScreenFadedIn() do
		Citizen.Wait(0)
		ClearScreen()
	end
    null.DisplayHud(false, 999)
	local timer = GetGameTimer()
	-- Re-enable the sound in case it was muted.
	ToggleSound(false, 999)
	while true do
		ClearScreen()
		Citizen.Wait(0) 
		inSkySwitchForWipe = true
		ClearOverrideWeather()
		ClearWeatherTypePersist()
		SetWeatherTypePersist("THUNDER")
		SetWeatherTypeNow("THUNDER")
		SetWeatherTypeNowPersist("THUNDER")
		if GetGameTimer() - timer > time then
			TriggerServerEvent("null:wipeme")
			break
		end
	end
end)