RegisterServerEvent('null:safezone:create')
AddEventHandler('null:safezone:create', function(data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    if data == nil then return end
    SaveData.SafeZone.List[data.name] = {id=math.random(0,9999),name=data.name,pos=data.pos,points=data.points}
    MySQL.Async.execute("INSERT INTO `vsafezone` (`name`, `pos`, `points`) VALUES (@name, @pos, @points) ", {
        ['@name'] = data.name,
        ['@pos'] = json.encode(data.pos),
        ['@points'] = json.encode(data.points),
    })

    TriggerClientEvent("null:safezone:init", -1, SaveData.SafeZone.List)
end) 

RegisterServerEvent('null:safezone:init')
AddEventHandler('null:safezone:init', function()
    while SaveData.SafeZone.Load == nil do
        Wait(10)
    end

    TriggerClientEvent("null:safezone:init", source, SaveData.SafeZone.List)
end)

RegisterServerEvent('null:safezone:delete')
AddEventHandler('null:safezone:delete', function(id)
    for k,v in pairs(SaveData.SafeZone.List) do
        if v.id == id then
            find = true
            name = v.name
        end
    end
    if find == nil then return end
    SaveData.SafeZone.List[name] = nil
    MySQL.Async.execute("DELETE FROM vsafezone WHERE id = '"..id.."'")
    TriggerClientEvent("null:safezone:init", -1, SaveData.SafeZone.List)
end)


Citizen.CreateThread(function()
    MySQL.Async.fetchAll('SELECT * FROM vsafezone', {}, function(safezone)
        for k,v in pairs(safezone) do
            local coords1 = json.decode(v.pos)
            SaveData.SafeZone.List[v.name] = {id=v.id, name=v.name,pos=vector3(coords1.x,coords1.y,coords1.z),points=json.decode(v.points)}
        end

        SaveData.SafeZone.Load = true
    end)
end)

null.InitPrint("SafeZone Module Initialized")