local function Initialize(scaleform, text, text2)
    local scaleform = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(0)
    end
    PushScaleformMovieFunction(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
	PushScaleformMovieFunctionParameterString(text)
    PushScaleformMovieFunctionParameterString(text2)
    PopScaleformMovieFunctionVoid()
    return scaleform
end

null.fct.draw.AddLongString = function(txt)
    local maxLen = 100
    for i = 0, string.len(txt), maxLen do
        local sub = string.sub(txt, i, math.min(i + maxLen, string.len(txt)))
        AddTextComponentString(sub)
    end
end

null.fct.draw.Text = function(intFont, stirngText, floatScale, intPosX, intPosY, color, boolShadow, intAlign, addWarp)
	SetTextFont(intFont)
	SetTextScale(floatScale, floatScale)
	if boolShadow then
		SetTextDropShadow(0, 0, 0, 0, 0)
		SetTextEdge(0, 0, 0, 0, 0)
	end
	SetTextColour(color[1], color[2], color[3], 255)
	if intAlign == 0 then
		SetTextCentre(true)
	else
		SetTextJustification(intAlign or 1)
		if intAlign == 2 then
			SetTextWrap(.0, addWarp or intPosX)
		end
	end
	SetTextEntry("STRING")
	AddTextComponentString(stirngText)
	DrawText(intPosX, intPosY)
end	

null.fct.draw.Text2 = function(text, scale, posX, posY, color)
	SetTextFont(0)
	SetTextScale(scale, scale)
    SetTextDropShadow(0, 0, 0, 0, 0)
	SetTextColour(color[1], color[2], color[3], 255)
	BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(posX, posY)
end

null.fct.draw.CenteredAnnouncement = function(text, Subtitle, timer)
    Citizen.CreateThread(function()
        local startTime = GetGameTimer()
        while GetGameTimer() - startTime < timer do
            scaleform = Initialize("mp_big_message_freemode", text, Subtitle)
            DrawScaleformMovieFullscreen(scaleform, 0, 0, 0, 255, 0)
            Citizen.Wait(0) 
        end
    end)
end