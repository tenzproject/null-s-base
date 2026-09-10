
local previewProp = nil
local function deletePreviewProp()
    if not DoesEntityExist(previewProp) then return end
    DeleteEntity(previewProp)
    previewProp = nil
end

null.fct.game.SelectProps = LPH_NO_VIRTUALIZE(function(props)
    if props == nil then return end

    isAddingDoorlock = true
    local doorCount = 1
    local lastEntity = 0

    local theEntity = nil
    local FinalSelect = nil
    while true do
        DisablePlayerFiring(PlayerState.ped, true)

        local hit, entity, coords = lib.raycast.cam(1|16)

        if hit then
            DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 255, 42, 24, 100, false, false, 0, true, false, false, false)
        end

        if hit and entity > 0 and GetEntityType(entity) == 3 then
            if lastEntity ~= entity then
                SetEntityDrawOutline(entity, true)
                SetEntityDrawOutline(lastEntity, false)
            end

            lastEntity = entity
            if IsControlPressed(0,38) then
                local breaked = false
                for k,v in pairs(props) do
                    print(GetEntityModel(entity), v, GetHashKey(v))
                    if GetEntityModel(entity) == GetHashKey(v) or tostring(GetEntityModel(entity)) == tostring(v) then
                        theEntity = entity
                        FinalSelect = v
                        breaked = true
                        break
                    end
                end
                if breaked then break end
            end
        end
        Wait(0)
    end

    SetEntityDrawOutline(lastEntity, false)
    local data = {
        finalSelect = FinalSelect,
        entity = theEntity,
        hash = GetHashKey(theEntity),
        model = GetEntityModel(theEntity),
        pos = GetEntityCoords(theEntity),
        heading = GetEntityHeading(theEntity),
        rotation = GetEntityRotation(theEntity),
    }
    return data
end)

null.fct.game.placeProps = LPH_NO_VIRTUALIZE(function(hash, cbFinish, cbCancel)
    Citizen.CreateThread(function()
        local coords, forward = GetEntityCoords(PlayerPedId()), GetEntityForwardVector(PlayerPedId())
        local objectCoords = (coords + forward * 3.0)

        ESX.Streaming.RequestModel(hash)
        previewProp = CreateObjectNoOffset(hash, objectCoords.x, objectCoords.y, objectCoords.z, false, false, false)
        SetModelAsNoLongerNeeded(hash)

        SetEntityCollision(previewProp, false, false)
        SetCanClimbOnEntity(previewProp, false)
        FreezeEntityPosition(previewProp, true)

        local relativeCoords = vector3(0.0, 0.0, 0.0)

        useGizmo(previewProp)

        local placeEntityProperlyOnTheGround = true
        local inPreviewMode = true

        while inPreviewMode do
            HideHudComponentThisFrame(19)
            HideHudComponentThisFrame(20)

            DrawScaleformMovieFullscreen(previewInstructions, 255, 255, 255, 255, 0)

            coords, forward = GetEntityCoords(PlayerPedId()), GetEntityForwardVector(PlayerPedId())

            local newObjectCoords = GetEntityCoords(previewProp)

            SetEntityCoords(previewProp, newObjectCoords.x, newObjectCoords.y, newObjectCoords.z)
            
            if IsControlJustPressed(0, 215) then -- Enter
                inPreviewMode = false


                objectCoords = GetEntityCoords(previewProp)
                objectRotation = GetEntityRotation(previewProp)
                
                -- finish
                cbFinish(objectCoords, objectRotation)

                deletePreviewProp()
            end

            if IsControlJustPressed(0, 177) then -- BACKSPACE : Cancel
                cbCancel()
                inPreviewMode = false
                return
            end

            SetEntityRotation(previewProp, objectRotation)
            Citizen.Wait(0)
        end
    end)
end)