function createvehicle(model, pos, rotation, color)
    table.insert(SaveData.World.Vehicles, {
        [1] = model,
        [2] = color,
        [3] = pos,
        [4] = rotation,
        [5] = idfinal + 1
    })
    MySQL.Async.execute("INSERT INTO `vfictifveh` (`model`, `color`, `pos`, `rotation`) VALUES (@model, @color, @pos, @rotation) ", {
        ['@model'] = model,
        ['@color'] = color,
        ['@pos'] = json.encode(pos),
        ['@rotation'] = json.encode(rotation)
    })
end

Citizen.CreateThread(function()
    MySQL.Async.fetchAll('SELECT * FROM vfictifveh', {}, function(result)
        idfinal = 0
        for k,v in pairs(result) do
            v.pos = json.decode(v.pos)
            v.rotation = json.decode(v.rotation)
            table.insert(SaveData.World.Vehicles, {
                [1] = v.model,
                [2] = v.color,
                [3] = vector3(v.pos.x,v.pos.y,v.pos.z),
                [4] = vector3(v.rotation.x,v.rotation.y,v.rotation.z),
                [5] = v.id,
            })
            if v.id > idfinal then
                idfinal = v.id
            end
        end
    end)
end)

RegisterNetEvent('worldvehicle:server:changeColor', function(id, newcolor)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    for k,v in pairs(SaveData.World.Vehicles) do
        if k == id then
            SaveData.World.Vehicles[k][2] = newcolor
        end
    end
    TriggerClientEvent("worldvehicle:client:changeColor", -1, id, newcolor)
    MySQL.Async.execute('UPDATE vfictifveh SET color = @color WHERE id = @id', {
        ['@id'] = id,
        ['@color'] = newcolor
    })
end)

RegisterNetEvent('worldvehicle:server:add', function(model, pos, rotation, color)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    local id = nil
    local data = nil
    createvehicle(model, pos, rotation, color)
    
    for k,v in pairs(SaveData.World.Vehicles) do
        if v[1] == model then
            if #(v[3] - pos) < 10 then
                id = k
                data = v
            end 
        end
    end
    if id == nil or data == nil then return end
    TriggerClientEvent("worldvehicle:client:add", -1, id, data)
end)

RegisterNetEvent('worldvehicle:server:remove', function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    for k,v in pairs(SaveData.World.Vehicles) do
        if v[5] == id then
            table.remove(SaveData.World.Vehicles, k)
            MySQL.Async.execute('DELETE FROM vfictifveh WHERE id = @id', {
                ['@id'] = v[5]
            }, function()
            end)
        end
    end
    TriggerClientEvent("worldvehicle:client:remove", -1, id)
end)

AddEventHandler('esx:playerLoaded', function(eventSrc, xPlayer)
    TriggerClientEvent("worldvehicle:client:load", xPlayer.source,SaveData.World.Vehicles)
end)