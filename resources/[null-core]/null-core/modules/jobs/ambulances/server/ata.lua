Ata = {}
AtaType = {}

ESX.RegisterServerCallback("null:getAta",function(source,cb)
    cb(Ata)
end)

ESX.RegisterServerCallback("null:getIfPlayerhaveAta",function(source,cb, idunique)
    if Ata[idunique] ~= nil then
        cb(Ata[idunique])
    else
        cb(false)
    end
end)

AddEventHandler('esx:playerDropped', function(eventSrc, xPlayer)
    local idunique = xPlayer.getIdunique()
    if Ata[idunique] ~= nil then
        if Ata[idunique] <= 0 then Ata[idunique] = nil end
    end
end)


AddEventHandler('esx:playerLoaded', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    local idunique = xPlayer.getIdunique()
    if xPlayer == nil then return end
    if Ata[idunique] ~= nil then
        Wait(1000)
        if Ata[idunique] <= 0 then Ata[idunique] = nil return end
        TriggerClientEvent("ata:client:update", source, { time = Ata[idunique], type = AtaType[idunique] or 0 })
    end
end)





RegisterNetEvent("ata:server:recevieatatime", function(time, bool)
    local xPlayer = ESX.GetPlayerFromId(source)
    Ata[xPlayer.getIdunique()] = time
end)

RegisterNetEvent("ata:server:updateCaneByExtended", function(player, time)
    if player == nil then
        player = source
    end
    TriggerClientEvent("ata:client:update", player, { time = time, type = 0 })
end)


RegisterNetEvent("ata:server:updateNoCane", function(player, time)
    local oPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["entreprises"][oPlayer.getJob().name] == nil then
        return 
    end
    
    if player == nil then
        player = source
    end
    local xPlayer = ESX.GetPlayerFromId(player)
    if xPlayer == nil then return end
    --xPlayer.setAta(time)
    Ata[xPlayer.getIdunique()] = time
    AtaType[xPlayer.getIdunique()] = 1
    TriggerClientEvent("ata:client:update", player, { time = time, type = 1 })
end)

RegisterNetEvent("ata:server:setMeAta", function(time, type)
    local xPlayer = ESX.GetPlayerFromId(source)
    if Ata[xPlayer.getIdunique()] == nil then 
        Ata[xPlayer.getIdunique()] = time
        AtaType[xPlayer.getIdunique()] = type or 1
        TriggerClientEvent("ata:client:update", player, { time = time, type = type or 1 })
    end
end)

RegisterNetEvent("ata:server:staff:updateNoCane", function(player, time)
    local oPlayer = ESX.GetPlayerFromId(source)
    if oPlayer.getGroup() == "user" then
        return
    end
    
    if player == nil then
        player = source
    end
    local xPlayer = ESX.GetPlayerFromId(player)
    if xPlayer == nil then return end
    if time == 0 then 
        if Ata[xPlayer.getIdunique()] ~= nil then 
            Ata[xPlayer.getIdunique()] = nil 
            AtaType[xPlayer.getIdunique()] = nil
            TriggerClientEvent("ata:client:update", player, { time = 0, type = 0 })
        end
        return
    end
    --xPlayer.setAta(time)
    Ata[xPlayer.getIdunique()] = time
    AtaType[xPlayer.getIdunique()] = 0
    TriggerClientEvent("ata:client:update", player, { time = time, type = 0 })
end)

RegisterNetEvent("ata:server:staff:updateNoCaneOffline", function(idunique, time)
    local oPlayer = ESX.GetPlayerFromId(source)
    if oPlayer.getGroup() == "user" then
        return
    end

    if time == 0 then 
        if Ata[idunique] ~= nil then 
            Ata[idunique] = nil 
        end
        return
    end
    --xPlayer.setAta(time)
    Ata[idunique] = time
    AtaType[idunique] = 0
end)

RegisterNetEvent("ata:server:updateAta", function(player, seconds)
    if player == nil then
        player = source
    end
    local time = math.floor(seconds / 60)
    local xPlayer = ESX.GetPlayerFromId(player)
    if xPlayer == nil then return end
    --xPlayer.setAta2(time)
    Ata[xPlayer.getIdunique()] = time
    TriggerClientEvent("ata:client:update", player, { time = time, type = AtaType[idunique] or 0 })
    if time <= 0 then
        Ata[xPlayer.getIdunique()] = nil
        AtaType[xPlayer.getIdunique()] = nil
        TriggerClientEvent("ata:client:update", player, { time = 0, type = 0 })
    end
end)