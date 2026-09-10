GF = {
    isLoad = true,
    ZoneGf = {},
    CountFFA = 0,
    LastPos = {},
    Spawn = Config.GunFightZone.spawn,
}

Citizen.CreateThread(function()
    for k,v in pairs(SaveData.json["zonegf"]) do
        v.Players = {}
        v.nbrPlayers = 0
        for k2,v2 in pairs(v.spawnPoint) do
            v.spawnPoint[k2] = vector3(v2.x, v2.y, v2.z)
        end
        v.position = vector3(v.position.x, v.position.y, v.position.z)
    end
end)

RegisterServerEvent('null:zonegf:getallzone')
AddEventHandler('null:zonegf:getallzone', function()
    while not GF.isLoad do Wait(100) end
    TriggerClientEvent("null:zonegf:initzonegf", source, SaveData.json["zonegf"])
end)


RegisterServerEvent('null:zonegf:create')
AddEventHandler('null:zonegf:create', function(data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    local finalSpawnPoint = {}
    for k,v in pairs(data.spawnpos) do
        table.insert(finalSpawnPoint, vector3(v.x, v.y, v.z))
    end
    SaveData.json["zonegf"][#SaveData.json["zonegf"]+1] = {
        id = #SaveData.json["zonegf"]+1,
        nbrPlayers = 0,
        isOpen = true,
        lastPos = {},
        Players = {},
        maxPlayers = data.maxplayer,
        position = data.pos,
        label = data.name,
        allStats = {},
        spawnPoint = finalSpawnPoint,
    }
    TriggerClientEvent("null:zonegf:initzonegf", -1, SaveData.json["zonegf"])
end)

RegisterServerEvent('null:zonegf:delete')
AddEventHandler('null:zonegf:delete', function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    SaveData.json["zonegf"][id] = nil
    TriggerClientEvent("null:zonegf:initzonegf", -1, SaveData.json["zonegf"])
end)

RegisterServerEvent('null:zonegf:close')
AddEventHandler('null:zonegf:close', function(id, bool)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    if SaveData.json["zonegf"][id] ~= nil then SaveData.json["zonegf"][id].isOpen = bool end
    TriggerClientEvent("null:zonegf:editOpen", -1, id, bool)
end)

ESX.RegisterServerCallback('null:zonegf:join', function(source, cb, zoneid, type)
    if SaveData.json["zonegf"][zoneid] ~= nil then
        if type == "Join" then
            if SaveData.json["zonegf"][zoneid].nbrPlayers == SaveData.json["zonegf"][zoneid].maxPlayers then 
                return 
            end
            if SaveData.json["zonegf"][zoneid].isOpen == false then return end
            null.fct.instance.Set(source, 75576, "Zone GunFight")
            SaveData.json["zonegf"][zoneid].nbrPlayers = SaveData.json["zonegf"][zoneid].nbrPlayers + 1
            SaveData.json["zonegf"][zoneid].Players[source] = true
            if not SaveData.json["zonegf"][zoneid].lastPos[source] then
                SaveData.json["zonegf"][zoneid].lastPos[source] = GetEntityCoords(GetPlayerPed(source))
            end
            TriggerClientEvent('null:gunfight:newStat', -1, 'p', SaveData.json["zonegf"][zoneid].nbrPlayers, zoneid)
            SetEntityCoords(GetPlayerPed(source), SaveData.json["zonegf"][zoneid].spawnPoint[math.random(1, #SaveData.json["zonegf"][zoneid].spawnPoint)])
            cb(SaveData.json["zonegf"][zoneid].nbrPlayers)
        elseif type == "Leave" then
            null.fct.instance.Set(source, 0)
            SaveData.json["zonegf"][zoneid].nbrPlayers = SaveData.json["zonegf"][zoneid].nbrPlayers - 1
            SaveData.json["zonegf"][zoneid].lastPos[source] = nil
            SaveData.json["zonegf"][zoneid].Players[source] = nil
            TriggerClientEvent('null:gunfight:newStat', -1, 'p', SaveData.json["zonegf"][zoneid].nbrPlayers, zoneid)
            SetEntityCoords(GetPlayerPed(source), Config.GunFightZone.quit)
            cb(SaveData.json["zonegf"][zoneid].nbrPlayers)
        end
    else
        null.fct.instance.Set(source, 0)
        return
    end
end)

-- 2 


local Anti2FoisNullGF = {}
RegisterServerEvent('null:gunfight:newStat')
AddEventHandler('null:gunfight:newStat', function(...)
    local Args = {...}
    local CoolDown = {}
    if not Args then return end

    if Anti2FoisNullGF[source] ~= nil then
        if os.time() - Anti2FoisNullGF[source] < 3 then 
            return 
        else
            Anti2FoisNullGF[source] = nil
        end
    end

    Anti2FoisNullGF[source] = os.time()

    if Args[1] and Args[2] then
        local xDeath = ESX.GetPlayerFromId(Args[2])
        local xKiller = ESX.GetPlayerFromId(Args[1])
        TriggerClientEvent("null:zonegf:refreshStats", xDeath.source, "death")
        TriggerClientEvent("null:zonegf:refreshStats", xKiller.source, "kill")

        MySQL.Async.fetchAll('SELECT * FROM gunfight_stats WHERE identifier = @identifier', {
            ['@identifier'] = xDeath.identifier
        }, function(result)
            if result[1] then
                MySQL.Async.execute('UPDATE gunfight_stats SET kills = @kills, deaths = @deaths, ratio = @ratio WHERE identifier = @identifier', {
                    ['@identifier'] = xDeath.identifier,
                    ['@kills'] = result[1].kills,
                    ['@deaths'] = result[1].deaths + 1,
                    ['@ratio'] = Round(result[1].kills / (result[1].deaths + 1), 1)
                })
            else
                MySQL.Async.execute('INSERT INTO gunfight_stats (identifier, kills, deaths, ratio, name) VALUES (@identifier, @kills, @deaths, @ratio, @name)', {
                    ['@identifier'] = xDeath.identifier,
                    ['@kills'] = 0,
                    ['@deaths'] = 1,
                    ['@ratio'] = 0,
                    ['@name'] = GetPlayerName(xDeath.source)
                })
            end
        end)

        MySQL.Async.fetchAll('SELECT * FROM gunfight_stats WHERE identifier = @identifier', {
            ['@identifier'] = xKiller.identifier
        }, function(result)
            if result[1] then
                MySQL.Async.execute('UPDATE gunfight_stats SET kills = @kills, deaths = @deaths, ratio = @ratio WHERE identifier = @identifier', {
                    ['@identifier'] = xKiller.identifier,
                    ['@kills'] = result[1].kills + 1,
                    ['@deaths'] = result[1].deaths,
                    ['@ratio'] = Round(result[1].kills + 1 / result[1].deaths, 1)
                })
            else
                MySQL.Async.execute('INSERT INTO gunfight_stats (identifier, kills, deaths, ratio, name) VALUES (@identifier, @kills, @deaths, @ratio, @name)', {
                    ['@identifier'] = xKiller.identifier,
                    ['@kills'] = 1,
                    ['@deaths'] = 0,
                    ['@ratio'] = 0,
                    ['@name'] = GetPlayerName(xKiller.source)
                })
            end
        end)
    else
        local xDeath = ESX.GetPlayerFromId(Args[1])
        TriggerClientEvent("null:zonegf:refreshStats", xDeath.source, "death")
        Wait(100)

        MySQL.Async.fetchAll('SELECT * FROM gunfight_stats WHERE identifier = @identifier', {
            ['@identifier'] = xDeath.identifier
        }, function(result)
            if result[1] then
                MySQL.Async.execute('UPDATE gunfight_stats SET kills = @kills, deaths = @deaths, ratio = @ratio WHERE identifier = @identifier', {
                    ['@identifier'] = xDeath.identifier,
                    ['@kills'] = result[1].kills,
                    ['@deaths'] = result[1].deaths + 1,
                    ['@ratio'] = Round(result[1].kills / (result[1].deaths + 1), 1)
                })
            else
                MySQL.Async.execute('INSERT INTO gunfight_stats (identifier, kills, deaths, ratio, name) VALUES (@identifier, @kills, @deaths, @ratio, @name)', {
                    ['@identifier'] = xDeath.identifier,
                    ['@kills'] = 1,
                    ['@deaths'] = 0,
                    ['@ratio'] = 0,
                    ['@name'] = GetPlayerName(xDeath.source)
                })
            end
        end)
    end
end)

RegisterServerEvent('null:gunfight:admin:resetleader')
AddEventHandler('null:gunfight:admin:resetleader', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if Config.GroupeHighPerm[xPlayer.getGroup()] == nil then return end
    xPlayer.showNotification("✅ Zone Gunfight Reset avec succés")
    MySQL.Async.execute('DELETE FROM gunfight_stats', {})
end)

RegisterServerEvent('null:gunfight:admin:kickzonegf')
AddEventHandler('null:gunfight:admin:kickzonegf', function(type, zoneid)
    local xPlayer = ESX.GetPlayerFromId(source)
    if Config.GroupeHighPerm[xPlayer.getGroup()] == nil then return end
    if type == "all" then
        xPlayer.showNotification("✅ Tous les joueurs ont était exclu de la zone Gunfight")
        for k,v in pairs(SaveData.json["zonegf"]) do
            for i,x in pairs(v.Players) do
                TriggerClientEvent("null:zonegf:leave", i)
            end
        end
    elseif type == "zone" and SaveData.json["zonegf"][zoneid] ~= nil then
        xPlayer.showNotification("✅ Tous les joueurs ont était exclu de la zone "..SaveData.json["zonegf"][zoneid].label)
        for i,x in pairs(SaveData.json["zonegf"][zoneid].Players) do
            TriggerClientEvent("null:zonegf:leave", i)
        end
    end
end)


ESX.RegisterServerCallback('null:gunfight:getAll', function(source, cb, ...)
    local Args = {...}
    if not Args then return end
    if Args[1] == 'myStats' then
        local xPlayer = ESX.GetPlayerFromId(source)
        MySQL.Async.fetchAll('SELECT * FROM gunfight_stats WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            if result[1] then
                json.encode(result[1])
                cb(result[1])
            else
                cb(nil)
            end
        end)
    elseif Args[1] == 'allStats' then
        MySQL.Async.fetchAll('SELECT * FROM gunfight_stats ORDER BY ratio DESC', {}, function(result)
            if result then
                leaderboard = {}
                for _, player in pairs(result) do
                    table.insert(leaderboard, player)
                end
                table.sort(leaderboard, compareKD)
                cb(leaderboard)
            else
                cb(nil)
            end
        end)
    else
        return
    end
end)