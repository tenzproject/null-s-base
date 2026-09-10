CameraUtils = {}

CustomCamCoords = nil

function CameraUtils.GenerateUUID()
  local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return string.gsub(template, '[xy]', function (c)
      local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
      return string.format('%x', v)
  end)
end

function CameraUtils.RequestCamera(name, camera, onclose)
    StartWhileCamera(onclose)
    if Config.Cameras.HideRadar then
        DisplayRadar(false)
    end

    if NullInventory.isOpen == true then
        TriggerEvent("null:inventory:closeinv")
    end

        null.DisplayHud(false)

    if type(camera) == "vector4" or type(camera) == "vector3" or type(camera) == "vector" then
        CustomCamCoords = camera
        camNumber = 0
        if inCam then
            inCam = false
            PlaySoundFrontend(-1, "HACKING_SUCCESS", false)
            Wait(250)
            ClearPedTasks(PlayerPedId())
        else
            PlaySoundFrontend(-1, "HACKING_SUCCESS", false)
            CameraUtils.UseCamera(name, camNumber)
        end
    else
        CustomCamCoords = nil
        camNumber = tonumber(camera)
        if inCam then
            inCam = false
            PlaySoundFrontend(-1, "HACKING_SUCCESS", false)
            Wait(250)
            ClearPedTasks(PlayerPedId())
        else
            if camNumber > 0 and camNumber < #Config.Cameras.Cameras + 1 then
                PlaySoundFrontend(-1, "HACKING_SUCCESS", false)
                CameraUtils.UseCamera(name, camNumber)
            end
        end
    end
end

function CameraUtils.ChangeCamera(name, camera)
    changedCamera = true
    RenderScriptCams(false, false, 0, 1, 0)
    DestroyCam(cctvCam, false)
    camNumber = tonumber(camera)
    CameraUtils.UseCamera(name, camera)
end

function CameraUtils.UseCamera(locationName, cameraUsed)
    camFov = 110.0
    local location = nil
    if cameraUsed ~= 0 then
        for k, v in pairs(Config.Cameras.Cameras) do
            if locationName == v.name and cameraUsed == v.camera then
                location = v.location
                currentCamIndex = k
            end
        end
    else
        location = CustomCamCoords
        currentCamIndex = 0
    end
    if location == nil then
        location = CustomCamCoords
        currentCamIndex = 0
    end

    if not inCam then
        cameraScaleform = RequestScaleformMovie("TRAFFIC_CAM") -- Traffic Cam UI Header
        while not HasScaleformMovieLoaded(cameraScaleform) do
            Citizen.Wait(0)
        end
        PushScaleformMovieFunction(cameraScaleform, "PLAY_CAM_MOVIE")
        PopScaleformMovieFunctionVoid()
        scaleformState = "LOADED_SCALEFORM"
    end
    
    cctvCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cctvCam, location.x, location.y, location.z + 1.2)
    SetCamRot(cctvCam, -15.0,0.0, location.w)
    SetCamFov(cctvCam, camFov)
    RenderScriptCams(true, false, 0, 1, 0)
    SetFocusArea(location.x, location.y, location.z, 0.0, 0.0, 0.0)
    inCam = true
    if not changedCamera then
        Wait(3000) -- Wait until scaleform has loaded fully and you can use the camera
        scaleformState = "CAMERA_READY"
    end
end

function CameraUtils.CloseCamera()
    DestroyCam(cctvCam, false)
    RenderScriptCams(false, false, 0, 1, 0)
    ClearFocus()
    ClearTimecycleModifier()
    SetScaleformMovieAsNoLongerNeeded(cameraScaleform)
    SetScaleformMovieAsNoLongerNeeded(controlsScaleform)
    SetNightvision(false)
    SetSeethrough(false)
    cctvCam = 0
    cameraScaleform = nil
    controlsScaleform = nil
    currentCamIndex = 0
    inCam = false
    scaleformState = "UNLOADED"
    TriggerServerEvent("null:labo:setincamera", false, PlayerState.Illegals.inLabo)
    changedCamera = false
    null.DisplayHud(true)
end

function CameraUtils.GetCamAmountByName(buildingName)
    local cameraCount = 0
    for k, v in pairs(Config.Cameras.Cameras) do
        if v.name == buildingName then
            cameraCount = cameraCount + 1
        end
    end
    return cameraCount
end

function CameraUtils.CreateInstructions(passedScaleform, buttonsMessages)
    local tempScaleform = RequestScaleformMovie(passedScaleform)
    while not HasScaleformMovieLoaded(tempScaleform) do
        Citizen.Wait(0)
    end
    PushScaleformMovieFunction(tempScaleform, "CLEAR_ALL")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(tempScaleform, "SET_CLEAR_SPACE")
    PushScaleformMovieFunctionParameterInt(200)
    PopScaleformMovieFunctionVoid()

    local buttonCount = 0
    for k, v in pairs(buttonsMessages) do
        PushScaleformMovieFunction(tempScaleform, "SET_DATA_SLOT")
        PushScaleformMovieFunctionParameterInt(buttonCount)
        Button(GetControlInstructionalButton(2, v.button, true))
        ButtonMessage(v.name)
        PopScaleformMovieFunctionVoid()
        buttonCount = buttonCount + 1
    end

    PushScaleformMovieFunction(tempScaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
    PopScaleformMovieFunctionVoid()

    PushScaleformMovieFunction(tempScaleform, "SET_BACKGROUND_COLOUR")
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(0)
    PushScaleformMovieFunctionParameterInt(70)
    PopScaleformMovieFunctionVoid()

    return tempScaleform
end

function ButtonMessage(text)
    BeginTextCommandScaleformString("STRING")
    AddTextComponentScaleform(text)
    EndTextCommandScaleformString()
end

function Button(ControlButton)
    N_0xe83a3e3557a56640(ControlButton)
end

CameraUtils.ToggleHUD = function(toggledHud)
    if toggledHud then
        -- toggle it here
    else
        -- turn it off here
    end
end

CameraUtils.Notification = function(msg, flash, saveToBrief, hudColorIndex)
	local notify = GetCurrentResourceName()..':notification'
	AddTextEntry(notify, msg)
	BeginTextCommandThefeedPost(notify)
	if hudColorIndex then ThefeedNextPostBackgroundColor(hudColorIndex) end
	EndTextCommandThefeedPostTicker(flash or false, saveToBrief or true)

	msg, hudColorIndex, flash, saveToBrief, notify = nil, nil, nil, nil, nil
end