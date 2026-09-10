local focusActive = false

null.fct.utils.StartFocusMode = LPH_NO_VIRTUALIZE(function()
    if focusActive then return end 
    focusActive = true

    local playerPed = PlayerPedId()
    Citizen.CreateThread(function()
        while focusActive do
            Citizen.Wait(1000) 
            local playerCoords = GetEntityCoords(playerPed)  

            local vehicles = ESX.Game.GetVehiclesInArea(playerCoords, 50.0)
            local peds = ESX.Game.GetPedsInArea(playerCoords, 50.0)

            local targets = {}
            for _, veh in ipairs(vehicles) do table.insert(targets, veh) end
            for _, ped in ipairs(peds) do table.insert(targets, ped) end

            if #targets > 0 then
                local target = targets[math.random(#targets)]
                
                SetCinematicModeActive(true)
                
                local targetCoords = GetEntityCoords(target)
                SetFocusEntity(target)
                
                local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
                SetCamActive(cam, true)
                RenderScriptCams(true, true, 500, true, true)
                
                local offsetX = math.random(-5, 5) * 1.0
                local offsetY = math.random(-5, 5) * 1.0
                SetCamCoord(cam, targetCoords.x + offsetX, targetCoords.y + offsetY, targetCoords.z + 2.0)
                PointCamAtEntity(cam, target, 0.0, 0.0, 0.0, true)
            end
        end
    end)
end)

null.fct.utils.StopFocusMode = LPH_NO_VIRTUALIZE(function()
    if not focusActive then return end
    focusActive = false

    local playerPed = PlayerPedId()
    Wait(1000)
    FreezeEntityPosition(playerPed, false) 
    ClearFocus()
    SetCinematicModeActive(false)
    
    RenderScriptCams(false, true, 500, true, true)
    DestroyCam(GetRenderingCam(), true)
end)

exports("StopFocusMode", StopFocusMode)
exports("StartFocusMode", StartFocusMode)