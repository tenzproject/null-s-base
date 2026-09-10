null.data.world.vehicles = {
    list = {},
    loaded = false,
}

function getValidModel(model)
    if type(model) == "number" then
        return math.floor(model)
    end
    
    local numericModel = tonumber(model)
    if numericModel ~= nil then
        return math.floor(numericModel)
    end
    
    if type(model) == "string" then
        local hashKey = GetHashKey(model)
        if hashKey ~= 0 then
            return hashKey
        else
            print("Invalid model string:", model)
        end
    else
        print("Invalid model type:", type(model))
    end

    return nil
end

local function createWorldVehicle(v, cb)
    local model = getValidModel(v.model)
    if model then -- Only proceed if the model is valid
        local pos = vector3(v.pos.x, v.pos.y, v.pos.z)

        Citizen.CreateThread(function()
            ESX.Game.SpawnLocalVehicle(model, pos, 0.0, function(entity)
                cb(entity)
            end)
        end)
    else
        cb(nil) -- Pass nil to the callback for invalid models
    end
end

function hexToRGB(hex)
    hex = hex:gsub("#", "") -- Supprime le caractère "#" s'il est présent

    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)

    return r, g, b
end

function stringToTable(str)
    local x, y, z = str:match("([^,]+),([^,]+),([^,]+)")
    return vector3(tonumber(x), tonumber(y), tonumber(z))
end

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    local loopWait = 2000
    null.fct.waitPlayerLoaded()

    while not null.data.world.vehicles.loaded do
        Wait(100)
    end

    while true do
        for k, v in pairs(null.data.world.vehicles.list) do
            if v and v.pos and v.entity ~= "in_spawning" then
                local distance = #(PlayerState.coords - vector3(v.pos.x, v.pos.y, v.pos.z))
                
                if distance > 200.0 then
                    if v.entity and DoesEntityExist(v.entity) then
                        DeleteEntity(v.entity)
                        v.entity = nil
                        v.target = nil
                    end
                else
                    if not v.entity or v.entity == 0 or (not DoesEntityExist(v.entity) and v.entity ~= "in_spawning") then
                        if DoesEntityExist(v.entity) then
                            DeleteEntity(v.entity)
                        end
                        v.entity = "in_spawning"
                        createWorldVehicle(v, function(entity)
                            if entity then 
                                v.entity = entity
                                SetVehicleOnGroundProperly(v.entity)
                                SetEntityCoords(v.entity, v.pos.x, v.pos.y, v.pos.z)
                                SetEntityRotation(v.entity, v.rotation.x, v.rotation.y, v.rotation.z)
                                SetEntityInvincible(v.entity, true) 
                                SetVehicleDoorsLocked(v.entity, 2)
                                SetVehicleExtraColours(v.entity, 0,0)
                                SetVehicleCustomPrimaryColour(v.entity, v.color[1], v.color[2], v.color[3])
                                SetVehicleCustomSecondaryColour(v.entity, v.color[1], v.color[2], v.color[3])
                                Citizen.SetTimeout(500, function()
                                    FreezeEntityPosition(v.entity, true)
                                end)
                            end
                        end)
                    end
                end
            end
        end
        Citizen.Wait(loopWait)
    end
end))

RegisterNetEvent('worldvehicle:client:load', function(vehicles)
    for k,v in pairs(vehicles) do
        --local newPos = stringToTable(v[3])
        local newPos = v[3]
        --local newRot = stringToTable(v[4])
        local newRot = v[4]
        local r, g, b = hexToRGB(v[2])

        null.data.world.vehicles.list[v[5]] = {
            model = v[1],
            color = {r, g, b},
            pos = newPos,
            rotation = newRot,
            id = v[5],
        }
    end

    Citizen.Wait(1000)

    null.data.world.vehicles.loaded = true
end)

RegisterNetEvent('worldvehicle:client:add', function(id, data)
    local r, g, b = hexToRGB(data[2])
    
    null.data.world.vehicles.list[id] = {
        model = data[1],
        color = {r, g, b},
        pos = data[3],
        rotation = data[4],
        id = id,
    }
end)

RegisterNetEvent('worldvehicle:client:remove', function(id)
    local vehicleTable = null.data.world.vehicles.list[id]
    if vehicleTable == nil then 
        return 
    end

    local entity = vehicleTable.entity

    null.data.world.vehicles.list[id] = nil

    if DoesEntityExist(entity) then 
        ESX.Game.DeleteVehicle(entity)
    end
end)

RegisterNetEvent('worldvehicle:client:changeColor', function(id, color)
    local vehicleTable = null.data.world.vehicles.list[id]

    if vehicleTable == nil then 
        return 
    end

    local r, g, b = hexToRGB(color)
    null.data.world.vehicles.list[id].color = {r, g, b}
    SetVehicleCustomPrimaryColour(vehicleTable.entity, r, g, b)
    SetVehicleCustomSecondaryColour(vehicleTable.entity, r, g, b)
    SetVehicleExtraColours(vehicleTable.entity, 0,0)
end)