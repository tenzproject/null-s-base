RegisterNetEvent('Null:props:place', function(name, label, id, coords, heading, isForStaff)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    if not xPlayer then return end
    if isForStaff and xPlayer.getGroup() ~= "user" then 
        MySQL.Async.execute('INSERT INTO world_props (name, label, owner, position, heading, iid) VALUES (@name, @label, @owner, @position, @heading, @iid)', {
            ['@name'] = name,
            ['@label'] = label,
            ['@owner'] = json.encode({UniqueID = 0, Name = "AdminProps:"..xPlayer.name, day = os.date("*t").day, hours = os.date("*t").hour, min = os.date("*t").min, month = os.date("*t").month, years = os.date("*t").year, firstName = "Staff", lastName = ""}),
            ['@position'] = json.encode(coords),
            ['@heading'] = json.encode(heading),
            ['@iid'] = id
        }, function()
            MySQL.Async.fetchAll('SELECT * FROM world_props WHERE iid = @iid', {
                ['@iid'] = id
            }, function(result)
                for k,v in pairs(result) do
                    SaveData.World.Props[v.id] ={
                        propsName = v.name,
                        propsId = v.id,
                        position = json.decode(v.position),
                        instance = v.instance,
                        heading = json.decode(v.heading),
                        owner = json.decode(v.owner),
                        label = v.label
                    }
                    TriggerClientEvent('null:world:propsaddTable', -1, v.id,  SaveData.World.Props[v.id])
                end
            end)
        end)
    else
        local instance = null.fct.instance.Get(xPlayer.source)
        if instance then
            instance = instance.number
        else
            return
        end
        if instance ~= 0 then
            if instance == 75576 or instance == 9201 or instance == 666 then
                return
            else
                xPlayer.removeInventoryItem("mobilier", 1)
                MySQL.Async.execute('INSERT INTO world_props (name, label, owner, position, instance, heading, iid) VALUES (@name, @label, @owner, @position, @instance, @heading, @iid)', {
                    ['@name'] = name,
                    ['@label'] = label,
                    ['@owner'] = json.encode({UniqueID = xPlayer.idunique, Name = xPlayer.name, day = os.date("*t").day, hours = os.date("*t").hour, min = os.date("*t").min, month = os.date("*t").month, years = os.date("*t").year, firstName = xPlayer.firstname, lastName = xPlayer.lastname}),
                    ['@position'] = json.encode(coords),
                    ['@instance'] = instance,
                    ['@heading'] = json.encode(heading),
                    ['@iid'] = id
                }, function()
                    MySQL.Async.fetchAll('SELECT * FROM world_props WHERE iid = @iid', {
                        ['@iid'] = id
                    }, function(result)
                        for k,v in pairs(result) do
                            SaveData.World.Props[v.id] ={
                                propsName = v.name,
                                propsId = v.id,
                                position = json.decode(v.position),
                                instance = v.instance,
                                heading = json.decode(v.heading),
                                owner = json.decode(v.owner),
                                label = v.label
                            }
                            TriggerClientEvent('null:world:propsaddTable', -1, v.id,  SaveData.World.Props[v.id])
                        end
                    end)
                end)
            end
        else
            xPlayer.removeInventoryItem("mobilier", 1)
            MySQL.Async.execute('INSERT INTO world_props (name, label, owner, position, heading, iid) VALUES (@name, @label, @owner, @position, @heading, @iid)', {
                ['@name'] = name,
                ['@label'] = label,
                ['@owner'] = json.encode({UniqueID = xPlayer.idunique, Name = xPlayer.name, day = os.date("*t").day, hours = os.date("*t").hour, min = os.date("*t").min, month = os.date("*t").month, years = os.date("*t").year, firstName = xPlayer.firstname, lastName = xPlayer.lastname}),
                ['@position'] = json.encode(coords),
                ['@heading'] = json.encode(heading),
                ['@iid'] = id
            }, function()
                MySQL.Async.fetchAll('SELECT * FROM world_props WHERE iid = @iid', {
                    ['@iid'] = id
                }, function(result)
                    for k,v in pairs(result) do
                        SaveData.World.Props[v.id] = {
                            propsName = v.name,
                            propsId = v.id,
                            position = json.decode(v.position),
                            instance = v.instance,
                            heading = json.decode(v.heading),
                            owner = json.decode(v.owner),
                            label = v.label
                        }
                        TriggerClientEvent('null:world:propsaddTable', -1, v.id,  SaveData.World.Props[v.id])
                    end
                end)
            end)
        end
    end
end)

RegisterNetEvent('null:world:propsserver:loadProps', function()
    local source = source

    MySQL.Async.fetchAll('SELECT * FROM world_props', {}, function(result)
        for k,v in pairs(result) do
            SaveData.World.Props[v.id] ={
                propsName = v.name,
                propsId = v.id,
                position = json.decode(v.position),
                instance = v.instance,
                heading = json.decode(v.heading),
                owner = json.decode(v.owner),
                label = v.label
            }
            TriggerClientEvent('null:world:propsaddTable', source, v.id,  SaveData.World.Props[v.id])
        end
    end)
end)

RegisterNetEvent('null:world:propsserver:delete', function(data)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)

    MySQL.Async.execute('DELETE FROM world_props WHERE id = @id', {
        ['@id'] = data.propsId
    }, function()
        xPlayer.addInventoryItem("mobilier", 1)
        TriggerClientEvent('null:world:propsremoveTable', -1, data.propsId)
        SaveData.World.Props[data.propsId] = nil
    end)
end)

RegisterNetEvent('null:props:server:changeOwner', function(data, newidu)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "usert" then return end
    player = ReturnPlayerId(newidu) or {id = 0}
    xTarget = ESX.GetPlayerFromId(player.id)

    if SaveData.World.Props[data.propsId] ~= nil then
        if xTarget == nil then
            SaveData.World.Props[data.propsId].owner.Name = "Inconnu"
        else
            SaveData.World.Props[data.propsId].owner.Name = xTarget.getName()
        end
        SaveData.World.Props[data.propsId].owner.UniqueID = newidu

        MySQL.Async.execute('UPDATE world_props SET owner = @owner WHERE id = @id', {
            ['@id'] = data.propsId,
            ['@owner'] = json.encode(SaveData.World.Props[data.propsId].owner),
        })
    end

    TriggerClientEvent('null:world:propsaddTable', source, data.propsId,  SaveData.World.Props[data.propsId])
end)


ESX.RegisterUsableItem('mobilier', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	local playerPed = GetPlayerPed(source)

    TriggerClientEvent("props:client:useProp", source)
end)