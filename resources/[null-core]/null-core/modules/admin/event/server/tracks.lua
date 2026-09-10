local TrackType = {
    ["timer"] = {},
    ["players"] = {},
}
 
-- Si type == timer, récompenser tout les 1 du mois
-- Si type == players, récompenser les top 1,2,3 de la course, donc minPlayers de minimum 3

while SaveData.json["tracks"] == nil do Wait(10) end
 
for k,v in pairs(SaveData.json["tracks"]) do
    if v.classements == nil then SaveData.json["tracks"][k].classements = {} end
    SaveData.json["tracks"][k].lobby = {}
    if v.mise == nil then SaveData.json["tracks"][k].mise = 10000 end
    if v.maxTime == nil then SaveData.json["tracks"][k].maxTime = 300000 end
    if v.reward == nil then SaveData.json["tracks"][k].reward = false end
    if v.type == nil then SaveData.json["tracks"][k].type = "timer" end
end

--[[
lobby = {
    id = 1,
    players = {},
    instance = 685_1,
    start = false,
}
]]


RegisterNetEvent("null:staff:createtracks", function(data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer == nil then return end
    if xPlayer.getGroup() == "user" then return end
    if data.type == nil then data.type = "timer" end
    local value = {
        id = #SaveData.json["tracks"] + 1,
        name = data.name,
        type = data.type,
        label = data.label,
        maxTime = data.maxTime,
        zone = data.zone,
        spawn = data.spawn,
        checkpoint = data.checkpoint,
        finish = data.finisPos,
        onlyFirstPerson = data.firstperson,
        pedPosition = data.pedpos,
        speedRestabilisater = data.speedRestabilisater,
        giveDrift = data.drift,
        maxPlayers = data.maxPlayers,
        minPlayers = data.minPlayers,
        enableCollision = data.collision,
        players = {},
        mise = data.mise,
        rewards = data.rewards,
        vehicules = data.vehicules,
        maxDamage = data.maxDamage,
        reward = false,
        lobby = {},
    }

    SaveData.json["tracks"][#SaveData.json["tracks"]+1] = value
    TriggerClientEvent("null:track:load", -1, SaveData.json["tracks"])
end)

ESX.RegisterServerCallback("null:track:getClassement", function(source, cb)
    local Classements = {}
    for k,v in pairs(SaveData.json["tracks"]) do
        Classements[v.id] = v.classements
    end
    cb(Classements)
end)

ESX.RegisterServerCallback("null:track:getClassementFromTrack", function(source, cb, id)
    cb(SaveData.json["tracks"][id].classements)
end)

RegisterNetEvent("null:track:request", function()
    TriggerClientEvent("null:track:load", source, SaveData.json["tracks"])
end)

RegisterNetEvent("null:track:startrace", function(id)

    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["tracks"][id] == nil then return end


    if SaveData.json["tracks"][id].type == "players" then
        if xPlayer.getAccount("bank").money < SaveData.json["tracks"][id].mise then return end
        local lobbyid = #SaveData.json["tracks"][id].lobby+1
        SaveData.json["tracks"][id].lobby[lobbyid] = {
            id = lobbyid,
            trackid = id,
            instance = tonumber("665"..math.random(0,999)),
            nbrPlayers = 1,
            playerInTrack = 1,
            players = {
                [xPlayer.getIdunique()] = {
                    owner = true,
                    finish = false,
                    name = xPlayer.getName(),
                    idunique = xPlayer.getIdunique(),
                    source = xPlayer.source,
                    checkpoints = {},
                }
            },
            start = false,
        }
        Config.Instance[SaveData.json["tracks"][id].lobby[lobbyid].instance] = "Lobby Race - "..SaveData.json["tracks"][id].label
        
        TriggerClientEvent("null:track:lobby:load", -1, id, lobbyid, SaveData.json["tracks"][id].lobby[lobbyid])
    else
        TriggerClientEvent("null:track:lobby:setintrack", xPlayer.source)
        StartRace("timer", id, nil, xPlayer.source)
    end
end)

RegisterNetEvent("null:track:kick", function(id, idlobby, idunique)
    local xPlayer = ESX.GetPlayerFromId(source)
    local owner = false
    for k,v in pairs(SaveData.json["tracks"][id].lobby[idlobby].players) do
        if v.idunique == xPlayer.getIdunique() then
            owner = v.owner
            break
        end
    end
    if not owner then return end
    SaveData.json["tracks"][id].lobby[idlobby].nbrPlayers = SaveData.json["tracks"][id].lobby[idlobby].nbrPlayers - 1
    SaveData.json["tracks"][id].lobby[idlobby].playerInTrack = SaveData.json["tracks"][id].lobby[idlobby].playerInTrack - 1
    SaveData.json["tracks"][id].lobby[idlobby].players[idunique] = nil
    TriggerClientEvent("null:track:lobby:load", -1, id, idlobby, SaveData.json["tracks"][id].lobby[idlobby])
end)

RegisterNetEvent("null:track:players:leave", function(id, idlobby)
    local xPlayer = ESX.GetPlayerFromId(source)
    SaveData.json["tracks"][id].lobby[idlobby].players[xPlayer.getIdunique()] = nil
    SaveData.json["tracks"][id].lobby[idlobby].nbrPlayers = SaveData.json["tracks"][id].lobby[idlobby].nbrPlayers - 1
    SaveData.json["tracks"][id].lobby[idlobby].playerInTrack = SaveData.json["tracks"][id].lobby[idlobby].playerInTrack - 1

    TriggerClientEvent("null:track:lobby:load", -1, id, idlobby, SaveData.json["tracks"][id].lobby[idlobby])
end)

RegisterNetEvent("null:track:players:race:leave", function(id, idlobby)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent("null:annonce", source, "COURSE", "Vous avez était exclu.", 6000)
    --ESX.ChatMessage(xPlayer.source, "Vous avez était exclu de la course. Cause: exit zone", "Race Systeme", {255, 0, 0})
    SaveData.json["tracks"][id].lobby[idlobby].players[xPlayer.getIdunique()] = nil
    SaveData.json["tracks"][id].lobby[idlobby].nbrPlayers = SaveData.json["tracks"][id].lobby[idlobby].nbrPlayers - 1
    SaveData.json["tracks"][id].lobby[idlobby].playerInTrack = SaveData.json["tracks"][id].lobby[idlobby].playerInTrack - 1
    TriggerClientEvent("null:track:lobby:leave", xPlayer.source)
    SetEntityCoords(GetPlayerPed(xPlayer.source), vector3(SaveData.json["tracks"][id].pedPosition.pos.x, SaveData.json["tracks"][id].pedPosition.pos.y, SaveData.json["tracks"][id].pedPosition.pos.z))
    for k,v in pairs(SaveData.json["tracks"][id].lobby[idlobby].players) do
        ESX.ChatMessage(v.source, "Le joueur "..v.name.." a quitter la course. Cause: exit zone", "Race Systeme", {255, 0, 0})
    end
    TriggerClientEvent("null:track:lobby:load", -1, id, idlobby, SaveData.json["tracks"][id].lobby[idlobby])
end)

RegisterNetEvent("null:staff:track:delete", function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    if SaveData.json["tracks"][id] == nil then return end

    SaveData.json["tracks"][id] = nil
    TriggerClientEvent("null:track:load", -1, SaveData.json["tracks"])
end)

RegisterNetEvent("null:track:solo:leave", function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerClientEvent("null:annonce", source, "COURSE", "Vous avez était exclu.", 6000)
    TriggerClientEvent("null:track:lobby:leave", xPlayer.source)
    SetEntityCoords(GetPlayerPed(xPlayer.source), vector3(SaveData.json["tracks"][id].pedPosition.pos.x, SaveData.json["tracks"][id].pedPosition.pos.y, SaveData.json["tracks"][id].pedPosition.pos.z))
end)


RegisterNetEvent("null:track:players:race:pastcheckpawn", function(id, idlobby, checkpoint)
    local xPlayer = ESX.GetPlayerFromId(source)
    local idunique = xPlayer.getIdunique()
    if SaveData.json["tracks"][id].checkpoint[checkpoint] == nil then return end
    if SaveData.json["tracks"][id].lobby[idlobby] == nil then return end
    if SaveData.json["tracks"][id].lobby[idlobby].players[idunique] == nil then return end
    if SaveData.json["tracks"][id].lobby[idlobby].players[idunique].checkpoints == nil then SaveData.json["tracks"][id].lobby[idlobby].players[idunique].checkpoints = {} end
    if SaveData.json["tracks"][id].lobby[idlobby].players[idunique].checkpoints[checkpoint] ~= nil then return end

    if checkpoint ~= 1 then
        if SaveData.json["tracks"][id].lobby[idlobby].players[idunique].checkpoints[checkpoint-1] == nil then 
            return 
        end
        SaveData.json["tracks"][id].lobby[idlobby].players[idunique].checkpoints[checkpoint] = true
    else
        SaveData.json["tracks"][id].lobby[idlobby].players[idunique].checkpoints[1] = true
    end

    TriggerClientEvent("null:track:lobby:load", -1, id, idlobby, SaveData.json["tracks"][id].lobby[idlobby])
end)

RegisterNetEvent("null:track:players:race:finish", function(id, idlobby)
    local xPlayer = ESX.GetPlayerFromId(source)
    local idunique = xPlayer.getIdunique()
    local pos = SaveData.json["tracks"][id].finish.pos
    if #(xPlayer.getCoords() - vector3(pos.x,pos.y,pos.z)) > 15 then return end
    if SaveData.json["tracks"][id].lobby[idlobby] == nil or SaveData.json["tracks"][id].lobby[idlobby].finish then return end
    if not SaveData.json["tracks"][id].lobby[idlobby].position then SaveData.json["tracks"][id].lobby[idlobby].position = {} end
    if SaveData.json["tracks"][id].lobby[idlobby].players[idunique].checkpoints[#SaveData.json["tracks"][id].lobby[idlobby].players[idunique].checkpoints] == nil or #SaveData.json["tracks"][id].lobby[idlobby].players[idunique].checkpoints ~= #SaveData.json["tracks"][id].checkpoint then 
        return 
    end
    if SaveData.json["tracks"][id].lobby[idlobby].players[idunique].finish then return end
    local nbr = 1
    for k,v in pairs(SaveData.json["tracks"][id].lobby[idlobby].position) do nbr = nbr + 1 end
    if nbr == SaveData.json["tracks"][id].lobby[idlobby].nbrPlayers then 
        SaveData.json["tracks"][id].lobby[idlobby].finish = true
        SaveData.json["tracks"][id].lobby[idlobby].players[idunique].finish = true
        SaveData.json["tracks"][id].lobby[idlobby].players[idunique].position = #SaveData.json["tracks"][id].lobby[idlobby].position+1
        SaveData.json["tracks"][id].lobby[idlobby].position[#SaveData.json["tracks"][id].lobby[idlobby].position+1] = idunique
        local Top1Label = ""
        local Top2Label = ""
        local Top3Label = ""
        for k,v in pairs(SaveData.json["tracks"][id].lobby[idlobby].players) do
            local xTarget = ESX.GetPlayerFromId(v.source)
            if v.position == 1 then
                Top1Label = "Top 1: "..v.name.." ("..v.idunique..")"
                local moneyvalue = math.floor(SaveData.json["tracks"][id].mise*0.6)*SaveData.json["tracks"][id].lobby[idlobby].nbrPlayers
                ESX.ChatMessage(v.source, "Vous avez reçu "..moneyvalue.."$", "Race Systeme", {255, 255, 0})
                if xTarget then
                    xTarget.addAccountMoney('bank', moneyvalue, {title = 'Gains Course', description = '1ère place', category = 'salary'})
                end
            elseif v.position == 2 then
                Top2Label = ", Top 2: "..v.name.." ("..v.idunique..")"
                local moneyvalue = math.floor(SaveData.json["tracks"][id].mise*0.3)*SaveData.json["tracks"][id].lobby[idlobby].nbrPlayers
                ESX.ChatMessage(v.source, "Vous avez reçu "..moneyvalue.."$", "Race Systeme", {255, 255, 0})
                if xTarget then
                    xTarget.addAccountMoney('bank', moneyvalue, {title = 'Gains Course', description = '2ème place', category = 'salary'})
                end
            elseif v.position == 3 then
                Top3Label = ", Top 3: "..v.name.." ("..v.idunique..")"
                local moneyvalue = math.floor(SaveData.json["tracks"][id].mise*0.1)*SaveData.json["tracks"][id].lobby[idlobby].nbrPlayers
                ESX.ChatMessage(v.source, "Vous avez reçu "..moneyvalue.."$", "Race Systeme", {255, 255, 0})
                if xTarget then
                    xTarget.addAccountMoney('bank', moneyvalue, {title = 'Gains Course', description = '3ème place', category = 'salary'})
                end
            end
        end
        local FinishLabel = Top1Label..Top2Label..Top3Label
        for k,v in pairs(SaveData.json["tracks"][id].lobby[idlobby].players) do
            TriggerClientEvent("null:track:lobby:leave", v.source)
            SetEntityCoords(GetPlayerPed(xPlayer.source), vector3(SaveData.json["tracks"][id].pedPosition.pos.x, SaveData.json["tracks"][id].pedPosition.pos.y, SaveData.json["tracks"][id].pedPosition.pos.z))
            SetInInstance(v.source, 0, "Course")
            ESX.ChatMessage(v.source, "La course est terminer.", "Race Systeme", {255, 255, 0})
            TriggerClientEvent("null:annonce", v.source, "La Course est terminer", FinishLabel, 7000)
            SaveData.json["tracks"][id].lobby[idlobby] = nil
        end
    else
        SaveData.json["tracks"][id].lobby[idlobby].players[idunique].finish = true
        SaveData.json["tracks"][id].lobby[idlobby].players[idunique].position = #SaveData.json["tracks"][id].lobby[idlobby].position+1
        SaveData.json["tracks"][id].lobby[idlobby].position[#SaveData.json["tracks"][id].lobby[idlobby].position+1] = idunique
        TriggerClientEvent("null:track:ply:finish", SaveData.json["tracks"][id].lobby[idlobby].players[idunique].source)
        SetEntityCoords(GetPlayerPed(xPlayer.source), vector3(SaveData.json["tracks"][id].pedPosition.pos.x, SaveData.json["tracks"][id].pedPosition.pos.y, SaveData.json["tracks"][id].pedPosition.pos.z))
        SetInInstance(SaveData.json["tracks"][id].lobby[idlobby].players[idunique].source, 0, "Course")
        for k,v in pairs(SaveData.json["tracks"][id].lobby[idlobby].players) do
            print(v.source, k)
            ESX.ChatMessage(v.source, "Le joueur "..SaveData.json["tracks"][id].lobby[idlobby].players[idunique].name.." est arriver en "..SaveData.json["tracks"][id].lobby[idlobby].players[idunique].position.." position !", "Race Systeme", {255, 255, 0})
        end
    end
    
    TriggerClientEvent("null:track:lobby:load", -1, id, idlobby, SaveData.json["tracks"][id].lobby[idlobby])
end)

RegisterNetEvent("null:track:solo:finish", function(id, timetostart, timetofinish)
    timetostart = timetostart/1000
    timetofinish = timetofinish/1000
    local FinalTimer = (timetostart-timetofinish)
	local mins = string.format("%02.f", math.floor(FinalTimer / 60))
	local secs = string.format("%02.f", math.floor(FinalTimer - mins * 60))
	local Timer = string.format("%s:%s", mins, secs)

    local xPlayer = ESX.GetPlayerFromId(source)
    local idunique = xPlayer.getIdunique()
    
    local pos = SaveData.json["tracks"][id].finish.pos
    if #(xPlayer.getCoords() - vector3(pos.x,pos.y,pos.z)) > 10.0 then return end
    TriggerClientEvent("null:track:lobby:leave", xPlayer.source)
    SetEntityCoords(GetPlayerPed(xPlayer.source), vector3(SaveData.json["tracks"][id].pedPosition.pos.x, SaveData.json["tracks"][id].pedPosition.pos.y, SaveData.json["tracks"][id].pedPosition.pos.z))
    SetInInstance(xPlayer.source, 0)
    ESX.ChatMessage(xPlayer.source, "La course est terminer.", "Race Systeme", {255, 255, 0})
    ESX.ChatMessage(xPlayer.source, "Vous avez fini en "..Timer.." Minutes", "Race Systeme", {255, 255, 0})
    
    local best = true
    for k,v in pairs(SaveData.json["tracks"][id].classements) do

        if v.idunique == idunique then
            if (v.timer > FinalTimer) then
                SaveData.json["tracks"][id].classements[k] = nil
            else
                best = false
            end
        end
    end


    if best then
        table.insert(SaveData.json["tracks"][id].classements, {
            timer = FinalTimer,
            timer2 = Timer,
            date = os.date('%Y-%m-%d %H:%M:%S'),
            idunique = idunique,
            name = xPlayer.getName(),
        })
    end
end)   

RegisterNetEvent("null:track:players:closelobby", function(id, idlobby)
    local xPlayer = ESX.GetPlayerFromId(source)
    local owner = false
    for k,v in pairs(SaveData.json["tracks"][id].lobby[idlobby].players) do
        if v.idunique == xPlayer.getIdunique() then
            owner = v.owner
            break
        end
    end
    if not owner then return end
    for k,v in pairs(SaveData.json["tracks"][id].lobby[idlobby].players) do
        TriggerClientEvent("null:track:lobby:leave", v.source)
    end
    SaveData.json["tracks"][id].lobby[idlobby] = nil
    TriggerClientEvent("null:track:lobby:load", -1, id, idlobby, SaveData.json["tracks"][id].lobby[idlobby])
end)

RegisterNetEvent("null:staff:track:closelobby", function(id, idlobby)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    for k,v in pairs(SaveData.json["tracks"][id].lobby[idlobby].players) do
        TriggerClientEvent("null:track:lobby:leave", v.source)
    end
    SaveData.json["tracks"][id].lobby[idlobby] = nil
    TriggerClientEvent("null:track:lobby:load", -1, id, idlobby, SaveData.json["tracks"][id].lobby[idlobby])
end)

RegisterNetEvent("null:track:players:join", function(id, idlobby)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.getAccount("bank").money < SaveData.json["tracks"][id].mise then return end

    SaveData.json["tracks"][id].lobby[idlobby].players[xPlayer.getIdunique()] = {
        owner = false,
        finish = false,
        name = xPlayer.getName(),
        idunique = xPlayer.getIdunique(),
        source = xPlayer.source,
    }
    SaveData.json["tracks"][id].lobby[idlobby].nbrPlayers = SaveData.json["tracks"][id].lobby[idlobby].nbrPlayers + 1
    SaveData.json["tracks"][id].lobby[idlobby].playerInTrack = SaveData.json["tracks"][id].lobby[idlobby].playerInTrack + 1
    TriggerClientEvent("null:track:lobby:load", -1, id, idlobby, SaveData.json["tracks"][id].lobby[idlobby])
end)

RegisterCommand("insertbot", function(source, args)
    local idunique = math.random(999,100000)
    args[1] = tonumber(args[1])
    args[2] = tonumber(args[2])
    SaveData.json["tracks"][args[1]].lobby[args[2]].players[idunique] = {
        owner = false,
        name = "Bot",
        idunique = idunique,
        source = 1000,
    }
    print(idunique, "bot")
    SaveData.json["tracks"][args[1]].lobby[args[2]].nbrPlayers = SaveData.json["tracks"][args[1]].lobby[args[2]].nbrPlayers + 1
    SaveData.json["tracks"][args[1]].lobby[args[2]].playerInTrack = SaveData.json["tracks"][args[1]].lobby[args[2]].playerInTrack + 1
    TriggerClientEvent("null:track:lobby:load", -1, args[1], args[2], SaveData.json["tracks"][args[1]].lobby[args[2]])
end)
 
RegisterCommand("botfinish", function(source, args)
    id = tonumber(args[1])
    idlobby = tonumber(args[2])
    idunique = tonumber(args[3])


    if SaveData.json["tracks"][id].lobby[idlobby].finish then return end
    if not SaveData.json["tracks"][id].lobby[idlobby].position then SaveData.json["tracks"][id].lobby[idlobby].position = {} end
    local nbr = 1
    for k,v in pairs(SaveData.json["tracks"][id].lobby[idlobby].position) do nbr = nbr + 1 end

    if nbr == SaveData.json["tracks"][id].lobby[idlobby].nbrPlayers then 
        SaveData.json["tracks"][id].lobby[idlobby].finish = true
        SaveData.json["tracks"][id].lobby[idlobby].playerInTrack = SaveData.json["tracks"][id].lobby[idlobby].playerInTrack - 1
        SaveData.json["tracks"][id].lobby[idlobby].players[idunique].position = #SaveData.json["tracks"][id].lobby[idlobby].position+1
        SaveData.json["tracks"][id].lobby[idlobby].position[#SaveData.json["tracks"][id].lobby[idlobby].position+1] = idunique
    
        for k,v in pairs(SaveData.json["tracks"][id].lobby[idlobby].players) do
            TriggerClientEvent("null:track:lobby:leave", v.source)
            SetEntityCoords(GetPlayerPed(100), vector3(SaveData.json["tracks"][id].pedPosition.pos.x, SaveData.json["tracks"][id].pedPosition.pos.y, SaveData.json["tracks"][id].pedPosition.pos.z))
            SetInInstance(v.source, 0)
            ESX.ChatMessage(v.source, "Le joueur "..SaveData.json["tracks"][id].lobby[idlobby].players[idunique].name.." est arriver en "..SaveData.json["tracks"][id].lobby[idlobby].players[idunique].position.." position !", "Race Systeme", {255, 255, 0})
            ESX.ChatMessage(v.source, "La course est terminer.", "Race Systeme", {255, 255, 0})

            SaveData.json["tracks"][id].lobby[idlobby] = nil            
        end
    else
        SaveData.json["tracks"][id].lobby[idlobby].players[idunique].position = #SaveData.json["tracks"][id].lobby[idlobby].position+1
        SaveData.json["tracks"][id].lobby[idlobby].position[#SaveData.json["tracks"][id].lobby[idlobby].position+1] = idunique
        SaveData.json["tracks"][id].lobby[idlobby].playerInTrack = SaveData.json["tracks"][id].lobby[idlobby].playerInTrack - 1
        TriggerClientEvent("null:track:ply:finish", SaveData.json["tracks"][id].lobby[idlobby].players[idunique].source)
        SetEntityCoords(GetPlayerPed(100), vector3(SaveData.json["tracks"][id].pedPosition.pos.x, SaveData.json["tracks"][id].pedPosition.pos.y, SaveData.json["tracks"][id].pedPosition.pos.z))
        SetInInstance(SaveData.json["tracks"][id].lobby[idlobby].players[idunique].source, 0)
        for k,v in pairs(SaveData.json["tracks"][id].lobby[idlobby].players) do
            ESX.ChatMessage(v.source, "Le joueur "..SaveData.json["tracks"][id].lobby[idlobby].players[idunique].name.." est arriver en "..SaveData.json["tracks"][id].lobby[idlobby].players[idunique].position.." position !", "Race Systeme", {255, 255, 0})
        end
    end
    
    TriggerClientEvent("null:track:lobby:load", -1, id, idlobby, SaveData.json["tracks"][id].lobby[idlobby])

end)

RegisterNetEvent("null:track:players:start", function(id, idlobby)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["tracks"][id].type == "players" then
        local owner = false
        for k,v in pairs(SaveData.json["tracks"][id].lobby[idlobby].players) do
            local xTarget = ESX.GetPlayerFromId(v.source)
            TriggerClientEvent("null:track:lobby:setintrack", v.source)
            if xTarget then
                xTarget.removeAccountMoney('bank', SaveData.json["tracks"][id].mise, {title = 'Mise Course', description = 'Inscription course', category = 'purchase'})
            end
            if v.idunique == xPlayer.getIdunique() then
                owner = v.owner
            end
        end
        if not owner then return end
        if SaveData.json["tracks"][id].lobby[idlobby].start then return end
        SaveData.json["tracks"][id].lobby[idlobby].start = true
        StartRace("players", id, idlobby)
        TriggerClientEvent("null:track:lobby:load", -1, id, idlobby, SaveData.json["tracks"][id].lobby[idlobby])
    end
end)

function StartRace(type, id, lobbyid, src)
    Citizen.CreateThread(function()
        if type == "players" then
            local Track = SaveData.json["tracks"][id]
            local Lobby = Track.lobby[lobbyid]
            local owner = nil
            local vehicules = nil
            if Config.Event.Track.VehiculePacks[Track.vehicules] ~= nil then
                vehicules = Config.Event.Track.VehiculePacks[Track.vehicules][math.random(1, #Config.Event.Track.VehiculePacks[Track.vehicules])]
            else
                vehicules = Track.vehicules
            end
            for k,v in pairs(Lobby.players) do
                if v.owner == true then owner = {idunique = v.idunique,source = v.source,name = v.name} end
                SetInInstance(v.source, Lobby.instance)
                TriggerClientEvent("null:track:lobby:start", v.source, id, lobbyid, Track.zone, Track.giveDrift)
            end
            Wait(1500)
            for k,v in pairs(Track.spawn) do   
                local index = 0
                for k2,v2 in pairs(Lobby.players) do
                    index = index + 1
                    if index == k then
                        TriggerClientEvent('esx:spawnVehicleLocal_client', v2.source, vehicules, vector3(v.pos.x, v.pos.y, v.pos.z), v.heading)
                    end
                end
            end
            Wait(7000)
            for k,v in pairs(Lobby.players) do
                TriggerClientEvent('null:race:start', v.source)
            end
            Citizen.CreateThread(function()
                while true do
                    if SaveData.json["tracks"][id].lobby[lobbyid] == nil or SaveData.json["tracks"][id].lobby[lobbyid].nbrPlayers <= 0 or SaveData.json["tracks"][id].lobby[lobbyid].playerInTrack <= 0 then
                        break
                    end
                    Wait(5000)
                end
                SaveData.json["tracks"][id].lobby[lobbyid] = nil
                TriggerClientEvent("null:track:lobby:load", -1, id, lobbyid, nil)
            end)
        else
            local Track = SaveData.json["tracks"][id]
            local vehicules = nil
            if Config.Event.Track.VehiculePacks[Track.vehicules] ~= nil then
                vehicules = Config.Event.Track.VehiculePacks[Track.vehicules][math.random(1, #Config.Event.Track.VehiculePacks[Track.vehicules])]
            else
                vehicules = Track.vehicules
            end
            TriggerClientEvent("null:track:solo:start", src, id, Track.zone, Track.giveDrift)
            local instance = tonumber("665"..math.random(0,999))
            SetInInstance(src, instance)
            Wait(1500)
            local pos = nil
            local head = nil
            for k,v in pairs(Track.spawn) do
                pos = v.pos
                head = v.heading
            end
            TriggerClientEvent('esx:spawnVehicleLocal_client', src, vehicules, vector3(pos.x, pos.y, pos.z), Track.spawn[1].heading)
            Wait(7000)
            TriggerClientEvent('null:race:start', src)

        end
    end)
end


Citizen.CreateThread(function()
    local DayOfMount = tonumber(os.date("%d"))
    local Mount = tonumber(os.date("%m"))

    if DayOfMount == 1 then
        print("[^1Track^7] Recompenses du mois pour les courses en cours.")
        for k,v in pairs(SaveData.json["tracks"]) do
            if v.reward == false or v.reward ~= Mount then
                v.reward = Mount
                local Classement = v.classements
                table.sort(Classement, function(a, b)
                    return a.timer < b.timer
                end)
                if Classement[1] then
                    local idunique = Classement[1].idunique
                    local xPlayer = ESX.GetPlayerFromId(ReturnPlayerId(idunique).source)
                    if xPlayer then
                        
                    else

                    end
                end
            end
        end
    end
end)