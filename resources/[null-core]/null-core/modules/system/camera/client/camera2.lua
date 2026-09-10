local selectedLocation = nil
local selectedCamera = nil
AddedLocations = {}
scaleformState = "UNLOADED"
changedCamera = false


RegisterNetEvent('null:camera:menu')
AddEventHandler('null:camera:menu', function()
    MenuCamera()
	TriggerEvent("null:inventory:closeinv")
end)

local CameraListeFreeWay = {
	[1] = true,
	[2] = true,
	[3] = true,
	[4] = true,
	[5] = true,
	[6] = true,
}


function MenuCamera()
	local vente = RageUI.CreateMenu("", "Listes des caméras")
	RageUI.Visible(vente, not RageUI.Visible(vente))

	while vente do
		Citizen.Wait(0)
			RageUI.IsVisible(vente, function()
				for k,v in pairs(CameraListeFreeWay) do
					RageUI.Button('Caméra Los Santos FreeWay N'..k, nil, {}, true, {
						onSelected = function() 
							RageUI.CloseAll()
							CameraUtils.RequestCamera("Los Santos FreeWay", k, MenuCamera)
						end
					})
				end
			end)
		if not RageUI.Visible(vente) and not RageUI.Visible(braquagelist) then
			vente = RMenu:DeleteType('vente', true)
		end
	end
end


currentCamIndex = 0
switchingCam = false
inCam = false
cctvCam = 0
cameraScaleform = nil
controlsScaleform = nil
camFov = 110.0
local drawnControls = false


local startWhileCamera = false
function StartWhileCamera(onclose)
	if startWhileCamera then return end
	startWhileCamera = true
	Citizen.CreateThread(function ()
		while true do
			Wait(0)
	
			if inCam then
				if IsDisabledControlJustPressed(0, 194) then -- Backspace
					CameraUtils.CloseCamera()
					AddedLocations = {}
					if Config.Cameras.HideRadar then
						DisplayRadar(true)
					end
	
					if Config.Cameras.HideHUD then
						CameraUtils.ToggleHUD(true)
					end
					if onclose then
						onclose()
					end
				end
	
				if (currentCamIndex > 0 and not CustomCamCoords) or CustomCamCoords then
					if CustomCamCoords or Config.Cameras.Cameras[currentCamIndex].canRotate then
						local rotation = GetCamRot(cctvCam, 2)
	
						if IsDisabledControlPressed(1, 174) then -- Arrow Left (Rotate Left)
							SetCamRot(cctvCam, rotation.x, 0.0, rotation.z + 0.3, 2)
						--end
						end
	
						if IsDisabledControlPressed(1, 175) then -- Arrow Right (Rotate Right)
							SetCamRot(cctvCam, rotation.x, 0.0, rotation.z - 0.3, 2)
						end
	
						if IsDisabledControlPressed(1, 172) then -- Arrow Up (Up)
							if rotation.x <= 0.0 then
								SetCamRot(cctvCam, rotation.x + 0.3, 0.0, rotation.z, 2)
							end
						end
	
						if IsDisabledControlPressed(1, 173) then -- Arrow Down (Down)
							if rotation.x <= 50.0 and rotation.x >= -88.0 then
								SetCamRot(cctvCam, rotation.x - 0.3, 0.0, rotation.z, 2)
							end
						end
					end
	
					if IsDisabledControlJustPressed(0, 241) then -- Zoom In
						if camFov > -1.0 then
							camFov = camFov - 3.0
							SetCamFov(cctvCam, camFov)
						end
					end
					
					if IsDisabledControlJustPressed(0, 242) then -- Zoom Out
						if camFov < 110.0 then
							camFov = camFov + 3.0
							SetCamFov(cctvCam, camFov)
						end
					end
				end
			end
	
			-- Handle Camera Scaleform and Timecycle
			if inCam then
				local location = 0
				if CustomCamCoords then
					location = CustomCamCoords
					SetTimecycleModifier(Config.Cameras.TimecycleTypes["highquality"])
				else
					location = Config.Cameras.Cameras[currentCamIndex].location
					SetTimecycleModifier(Config.Cameras.TimecycleTypes[Config.Cameras.Cameras[currentCamIndex].cameraType])
				end
				SetTimecycleModifierStrength(1.0)
				PushScaleformMovieFunction(cameraScaleform, "SET_ALT_FOV_HEADING")
				-- PushScaleformMovieFunctionParameterFloat(GetEntityCoords(location.w).z)
				PushScaleformMovieFunctionParameterFloat(location.w)
				PushScaleformMovieFunctionParameterFloat(1.0)
				PushScaleformMovieFunctionParameterFloat(GetCamRot(cctvCam, 2).z)
				PopScaleformMovieFunctionVoid()
				DrawScaleformMovieFullscreen(cameraScaleform, 255, 255, 255, 255)
				DisableAllControlActions(0)
			end
	
			-- Handle Controls Scaleform
			if inCam and scaleformState == "CAMERA_READY" then
				local buttonsMessage = {
					{name = "Fermer", button = 194},
					{name = "Rétrécir", button = 242},
					{name = "Agrandir", button = 241},
					{name = "Bas", button = 173},
					{name = "Haut", button = 172},
					{name = "Droite", button = 175},
					{name = "Gauche", button = 174}
				}
				controlsScaleform = CameraUtils.CreateInstructions("instructional_buttons", buttonsMessage)
				DrawScaleformMovieFullscreen(controlsScaleform, 255, 255, 255, 255, 0)
			end
		end
	end)
end