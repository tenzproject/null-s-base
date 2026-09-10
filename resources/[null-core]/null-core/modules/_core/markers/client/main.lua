null.data.markers = {
    list = Config.Markers,
    loaded = false,
}

null.data.markers.register = function(id, data)
    if not null.data.markers.list[id] then 
        null.data.markers.list[id] = data
    end
end

null.data.markers.unregister = function(id)
    null.data.markers.list[id] = nil
end

null.data.markers.isRegister = function(id)
    if null.data.markers.list[id] then
        return true 
    else
        return false
    end
end

null.data.markers.editLabel = function(id, value)
    if null.data.markers.list[id] then 
        null.data.markers.list[id].Label = value
    end
end

null.data.markers.editAction = function(id, value)
    if null.data.markers.list[id] then 
        null.data.markers.list[id].Action = value
    end
end

null.data.markers.setVisible = function(id, bool)
    if null.data.markers.list[id] then 
        null.data.markers.list[id].hide = not bool
    end
end

exports("MarkerRegister", null.data.markers.register)
exports("MarkerUnregister", null.data.markers.unregister)
exports("MarkerIsRegister", null.data.markers.isRegister)
exports("MarkerEditLabel", null.data.markers.editLabel)
exports("MarkerEditAction", null.data.markers.editAction)
exports("MarkerSetVisible", null.data.markers.setVisible)
exports("isMarkerLoad", function ()
    return null.data.markers.loaded
end)

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    null.fct.waitPlayerLoaded()
    for _,marker in pairs(null.data.markers.list) do
        if marker.Blip then
            ESX.addBlips({
                name = _,
                label = marker.Blip.Name,
                category = nil,
                position = marker.Position,
                sprite = marker.Blip.Sprite,
                display = marker.Blip.Display,
                scale = marker.Blip.Scale,
                color = marker.Blip.Color,
                type = marker.Blip.Type,
            })
        end
	end
    while true do
        local isProche = false
        for k,v in pairs(null.data.markers.list) do
            if (v.Public or ESX.PlayerData.job ~= nil and ESX.PlayerData.job.name == v.Job or ESX.PlayerData.job2.name == v.Job2) and (v.hide == nil or v.hide == false) then
                local dist = Vdist2(GetEntityCoords(PlayerPedId(), false), v.Position)
                if (dist < 2.0) then
                    isProche = true
                    --null.fct.draw.Text3DBar(v.Position.x, v.Position.y,v.Position.z, v.Label or "Appuyez sur [~y~E~s~] pour intéragir~s~.")
                    ESX.ShowHelpNotification(v.Label or "Appuyez sur [~y~E~s~] pour intéragir~s~.")
                end
                if dist < 20.0 then
                    isProche = true
                    if v.Marker == nil or v.Marker == true then
                        DrawMarker(25, v.Position.x, v.Position.y, v.Position.z-0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 255, false, false, 2, false, false, false, false)
                    end
                end
                if dist < 1.5 then
                    if IsControlJustPressed(1,51) then
                        v.Action(v.Position)
                    end
                end
            end
        end
        
		if isProche then
			Wait(0)
		else
			Wait(750)
		end
	end
end))

null.data.markers.loaded = true