-- FiveM Heli Cam by mraes
-- Version 1.3 2017-06-12

--CONFIG--
local fov_max = 150.0
local fov_min = 7.0 -- max zoom level (smaller fov is more zoom)
local zoomspeed = 10.0 -- camera zoom speed
local speed_lr = 8.0 -- speed by which the camera pans left-right 
local speed_ud = 8.0 -- speed by which the camera pans up-down
local toggle_helicam = 51 -- control id of the button by which to toggle the helicam mode. Default: INPUT_CONTEXT (E)
local toggle_rappel = 154 -- control id to rappel out of the heli. Default: INPUT_DUCK (X)
local toggle_spotlight = 183 -- control id to toggle the front spotlight Default: INPUT_PhoneCameraGrid (G)
local toggle_lock_on = 22 -- control id to lock onto a vehicle with the camera. Default is INPUT_SPRINT (spacebar)

local helicam = false
local polmav_hash = GetHashKey("pcj")
local fov = (fov_max+fov_min)*0.5
local vision_state = 0 -- 0 is normal, 1 is nightmode, 2 is thermal vision


--FUNCTIONS--

local function IsPlayerInPolmav()
	local lPed = GetPlayerPed(-1)
	local vehicle = GetVehiclePedIsIn(lPed)
	return IsVehicleModel(vehicle, polmav_hash)
end


local function ChangeVision()
	if vision_state == 0 then
		SetNightvision(true)
		vision_state = 1
	elseif vision_state == 1 then
		SetNightvision(false)
		SetSeethrough(true)
		vision_state = 2
	else
		SetSeethrough(false)
		vision_state = 0
	end
end


local function CheckInputRotation(cam, zoomvalue)
	local rightAxisX = GetDisabledControlNormal(0, 220)
	local rightAxisY = GetDisabledControlNormal(0, 221)
	local rotation = GetCamRot(cam, 2)
	if rightAxisX ~= 0.0 or rightAxisY ~= 0.0 then
		new_z = rotation.z + rightAxisX*-1.0*(speed_ud)*(zoomvalue+0.1)
		new_x = math.max(math.min(20.0, rotation.x + rightAxisY*-1.0*(speed_lr)*(zoomvalue+0.1)), -89.5) -- Clamping at top (cant see top of heli) and at bottom (doesn't glitch out in -90deg)
		SetCamRot(cam, new_x, 0.0, new_z, 2)
	end
end

local function HandleZoom(cam)
	local lPed = GetPlayerPed(-1)
	if not ( IsPedSittingInAnyVehicle( lPed ) ) then

		if IsControlJustPressed(0,32) then -- Scrollup
			fov = math.max(fov - zoomspeed, fov_min)
		end
		if IsControlJustPressed(0,8) then
			fov = math.min(fov + zoomspeed, fov_max) -- ScrollDown		
		end
		local current_fov = GetCamFov(cam)
		if math.abs(fov-current_fov) < 0.1 then -- the difference is too small, just set the value directly to avoid unneeded updates to FOV of order 10^-5
			fov = current_fov
		end
		SetCamFov(cam, current_fov + (fov - current_fov)*0.05) -- Smoothing of camera zoom
	else
		if IsControlJustPressed(0,241) then -- Scrollup
			fov = math.max(fov - zoomspeed, fov_min)
		end
		if IsControlJustPressed(0,242) then
			fov = math.min(fov + zoomspeed, fov_max) -- ScrollDown		
		end
		local current_fov = GetCamFov(cam)
		if math.abs(fov-current_fov) < 0.1 then -- the difference is too small, just set the value directly to avoid unneeded updates to FOV of order 10^-5
			fov = current_fov
		end
		SetCamFov(cam, current_fov + (fov - current_fov)*0.05) -- Smoothing of camera zoom
	end
end

local function GetVehicleInView(cam)
	local coords = GetCamCoord(cam)
	local forward_vector = RotAnglesToVec(GetCamRot(cam, 2))
	--DrawLine(coords, coords+(forward_vector*100.0), 255,0,0,255) -- debug line to show LOS of cam
	local rayhandle = CastRayPointToPoint(coords, coords+(forward_vector*200.0), 10, GetVehiclePedIsIn(GetPlayerPed(-1)), 0)
	local _, _, _, _, entityHit = GetRaycastResult(rayhandle)
	if entityHit>0 and IsEntityAVehicle(entityHit) then
		return entityHit
	else
		return nil
	end
end

local function RotAnglesToVec(rot) -- input vector3
	local z = math.rad(rot.z)
	local x = math.rad(rot.x)
	local num = math.abs(math.cos(x))
	return vector3(-math.sin(z)*num, math.cos(z)*num, math.sin(x))
end




--THREADS--

local threadstarter = false
function StartThreadsJumelle()
	if threadstarter then return end
	threadstarter = true
	Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
		while true do
			local lPed = PlayerState.ped
			local heli = PlayerState.vehicle
			
			if helicam then
	
				if NullInventory.isOpen == true then
					TriggerEvent("null:inventory:closeinv")
				end
	
				if not ( IsPedSittingInAnyVehicle( lPed ) ) then
	
							Citizen.CreateThread(function()
	
								TaskStartScenarioInPlace(lPed, "WORLD_HUMAN_BINOCULARS", 0, 1)
								PlayAmbientSpeech1(lPed, "GENERIC_CURSE_MED", "SPEECH_PARAMS_FORCE")
	
							end)
	
						else
						end	
	
						Wait(2000)
	
						SetTimecycleModifier("heliGunCam")
	
				SetTimecycleModifierStrength(0.3)
	
				local scaleform = RequestScaleformMovie("HELI_CAM")
	
				while not HasScaleformMovieLoaded(scaleform) do
	
					Citizen.Wait(10)
	
				end
	
				local lPed = PlayerState.ped
				local heli = PlayerState.vehicle
				local cam = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
	
				AttachCamToEntity(cam, lPed, 0.0,0.0,1.0, true)
				SetCamRot(cam, 0.0,0.0,GetEntityHeading(lPed))
				SetCamFov(cam, fov)
				RenderScriptCams(true, false, 0, 1, 0)
				PushScaleformMovieFunction(scaleform, "SET_CAM_LOGO")
				PushScaleformMovieFunctionParameterInt(0) -- 0 for nothing, 1 for LSPD logo
				PopScaleformMovieFunctionVoid()
	
				local locked_on_vehicle = nil
	
				while helicam and not IsEntityDead(lPed) and (PlayerState.vehicle == heli) and true do
	
					if IsControlJustPressed(0, 177) then -- Toggle Helicam
	
						PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
						ClearPedTasks(lPed)
						helicam = false
	
					end
	
					if locked_on_vehicle then
						
					else
						local zoomvalue = (1.0/(fov_max-fov_min))*(fov-fov_min)
	
						CheckInputRotation(cam, zoomvalue)
	
						local vehicle_detected = GetVehicleInView(cam)
	
					end
	
					HandleZoom(cam)
					DisplayRadar(false)
					null.DisplayHud(false)
					null.fct.draw.HideHUDThisFrame()
	
					DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
					Citizen.Wait(0)
				end
	
				null.DisplayHud(true)
				DisplayRadar(true)
	
				helicam = false
	
				ClearTimecycleModifier()
	
				fov = (fov_max+fov_min)*0.5
	
				RenderScriptCams(false, false, 0, 1, 0)
	
				SetScaleformMovieAsNoLongerNeeded(scaleform)
	
				DestroyCam(cam, false)
				SetNightvision(false)
				SetSeethrough(false)
				Citizen.Wait(0)
			else
				Citizen.Wait(500)
			end
		end
	end))
end
--EVENTS--

RegisterNetEvent('jumelles:Active') --Just added the event to activate the binoculars
AddEventHandler('jumelles:Active', function()
	
	helicam = not helicam
	StartThreadsJumelle()
end)