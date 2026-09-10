null.fct.draw.HideHUDThisFrame = LPH_NO_VIRTUALIZE(function()
	HideHelpTextThisFrame()
	HideHudComponentThisFrame(19) -- weapon wheel
	HideHudComponentThisFrame(1) -- Wanted Stars
	HideHudComponentThisFrame(2) -- Weapon icon
	HideHudComponentThisFrame(3) -- Cash
	HideHudComponentThisFrame(4) -- MP CASH
	HideHudComponentThisFrame(13) -- Cash Change
	HideHudComponentThisFrame(11) -- Floating Help Text
	HideHudComponentThisFrame(12) -- more floating help text
	HideHudComponentThisFrame(15) -- Subtitle Text
	HideHudComponentThisFrame(18) -- Game Stream
end)

null.fct.draw.DrawInstructionalButtons = LPH_NO_VIRTUALIZE(function(buttons)
	local scaleform = RequestScaleformMovie("instructional_buttons")
	while not HasScaleformMovieLoaded(scaleform) do
		Citizen.Wait(0)
	end

    DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 0, 0)

	PushScaleformMovieFunction(scaleform, "CLEAR_ALL")
	PopScaleformMovieFunctionVoid()

	PushScaleformMovieFunction(scaleform, "SET_CLEAR_SPACE")
	PushScaleformMovieFunctionParameterInt(200)
	PopScaleformMovieFunctionVoid()

	local i = 0
	for _, button in pairs(buttons) do
		PushScaleformMovieFunction(scaleform, "SET_DATA_SLOT")
		PushScaleformMovieFunctionParameterInt(i)
		PushScaleformMovieMethodParameterButtonName(GetControlInstructionalButton(2, button.key, true))
		BeginTextCommandScaleformString("STRING")
		AddTextComponentScaleform(button.label)
		EndTextCommandScaleformString()
		PopScaleformMovieFunctionVoid()
		i = i + 1
	end

	PushScaleformMovieFunction(scaleform, "DRAW_INSTRUCTIONAL_BUTTONS")
	PopScaleformMovieFunctionVoid()

	PushScaleformMovieFunction(scaleform, "SET_BACKGROUND_COLOUR")
	PushScaleformMovieFunctionParameterInt(0)
	PushScaleformMovieFunctionParameterInt(0)
	PushScaleformMovieFunctionParameterInt(0)
	PushScaleformMovieFunctionParameterInt(70)
	PopScaleformMovieFunctionVoid()

	return scaleform
end)

null.fct.draw.DrawRetroSprite = LPH_NO_VIRTUALIZE(function(textureDict, textureName, nums, node)
    if textureName == 'rightnode' then
        if selectedNode[selected][1] == node then
            textureName = textureName .. "_roll"
        end
    elseif textureName == 'leftnode' and selected == node then
        textureName = textureName .. "_roll"
    end
    DrawSprite(textureDict, textureName, nums[1], nums[2], nums[3], nums[4], nums[5], 999, 999, 999, 1.0)
end)

null.fct.draw.Text3D = LPH_NO_VIRTUALIZE(function(coords, text, size, a, font, dropShadow)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local camCoords      = GetGameplayCamCoords()
    local dist           = GetDistanceBetweenCoords(camCoords, coords.x, coords.y, coords.z, true)
    local size           = size

    if size == nil then
        size = 1
    end

    local scale = (size / dist) * 2
    local fov   = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    local opacity = a or 255
    local font = font or 4

    if onScreen then
        --SetTextColour(255, 30, 30, opacity)
        --SetTextDropshadow(5, 0, 0, 0, 0)
        SetTextCentre(1)
        SetTextEntry('STRING')

        SetTextProportional(0) -- Might not be needed. Play around with it I guess
        SetTextFont(4) -- Font for the text we are drawing
        SetTextOutline()
        SetTextScale(0.4,0.4)
        SetTextColour(255,255,255, 255)

        AddTextComponentString(text)
        DrawText(x, y)
    end
end)

null.fct.draw.Text3DBar = LPH_NO_VIRTUALIZE(function(x, y, z, text)
	SetTextScale(0.35, 0.35)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 215)
	SetTextEntry("STRING")
	SetTextCentre(true)
	AddTextComponentString(text)
	SetDrawOrigin(x,y,z, 0)
	DrawText(0.0, 0.0)
	local factor = (string.len(text)) / 370
	DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
	ClearDrawOrigin()
end)

-- @TODO: move to 3D text file
local draw_data = {}

local addDraw = LPH_NO_VIRTUALIZE(function(data)
    table.insert(draw_data, data)
end)

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        local near_drawer  = false
        local ped       = GetPlayerPed(-1)
        local pedCoords = GetEntityCoords(ped)

        for k,v in pairs(draw_data) do
            local dst = GetDistanceBetweenCoords(pedCoords, v.pos, true)

            if dst <= v.dst then
                near_drawer = true
                null.fct.draw.Text3D(v.pos, v.text, v.size)
            end
        end

        if near_drawer then
            Wait(1)
        else
            Wait(1000)
        end
    end
end))

Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    addDraw({
        pos = vector3(-1100.717, -2847.521, 16.8864),

        text = " Bienvenue sur "..ESX.Config("serverColor")..ESX.Config("serverName").."~s~ ! ",
        size = 3.5,

        dst = 4.0,
    })
    addDraw({
        pos = vector3(-1100.717, -2847.521, 16.6864),

        text = "Envie de rejoindre une "..ESX.Config("serverColor").."entreprise ~s~?",
        size = 3.5,

        dst = 4.0,
    })
    addDraw({
        pos = vector3(-1100.717, -2847.521, 16.4864),

        text = "Direction notre discord > "..ESX.Config("serverColor").."discord.gg/mercuryrp",
        size = 3.5,

        dst = 4.0,
    })
    addDraw({
        pos = vector3(-1100.717, -2847.521, 16.2864),

        text = "IMPORTANT",
        size = 3.5,

        dst = 4.0,
    })
    addDraw({
        pos = vector3(-1100.717, -2847.521, 16.0864),

        text = "Modifiez vos touches dans les options",
        size = 3.5,

        dst = 4.0,
    })
    addDraw({
        pos = vector3(-1100.717, -2847.521, 15.8864),

        text = "ECHAP > Parametres > Configuration > Configurer vos touches > "..ESX.Config("serverName"),
        size = 3.5,

        dst = 4.0,
    })
    addDraw({
        pos = vector3(-1100.717, -2847.521, 15.6864),

        text = ESX.Config("serverColor").."Vous pouvez sortir de l'airport pour louez un véhicule",
        size = 0.5,

        dst = 3.0,
    })
end)
