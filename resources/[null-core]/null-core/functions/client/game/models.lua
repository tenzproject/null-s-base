null.fct.game.RequestAndWaitModel = LPH_NO_VIRTUALIZE(function(modelName)
    if modelName and IsModelInCdimage(modelName) and not HasModelLoaded(modelName) then
        RequestModel(modelName)
        while not HasModelLoaded(modelName) do Citizen.Wait(100) end
    end
end)

null.fct.game.handlePreviewEventEntity = LPH_NO_VIRTUALIZE(function(model, entity_type)
    local entity = nil
    
    if entity_type == 'vehicle' then
        ESX.Game.SpawnLocalVehicle(model, PlayerState.coords, 50.0, function(vehicle)
            entity = vehicle
            SetEntityCollision(entity, false)
        end)
    elseif entity_type == 'object' then 
        ESX.Game.SpawnLocalObject(model, PlayerState.coords, function(result)
            entity = result
            SetEntityCollision(entity, false)
        end)
    end

    while not DoesEntityExist(entity) do
        Wait(10)
    end

    return entity
end)