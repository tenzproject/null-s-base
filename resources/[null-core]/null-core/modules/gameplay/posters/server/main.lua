if SaveData.json["posters"] == nil then SaveData.json["posters"] = {} end
Citizen.CreateThread(function()
    ESX.RegisterUsableItem('poster', function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if Config.Posters.onlyForAdmin then 
            if not xPlayer.getPermission("video") then return end
        end
        TriggerClientEvent("posters:placeImage", source)
    end)
end)

RegisterNetEvent("posters:addNewImage", function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if Config.Posters.onlyForAdmin then 
        if not xPlayer.getPermission("video") then return end
    end

    if data.renderDist == nil then
        if xPlayer.getInventoryItem("poster") == nil or xPlayer.getInventoryItem("poster").count <= 0 then return end
        xPlayer.removeInventoryItem("poster", 1)
    end
    SaveData.json["posters"][#SaveData.json["posters"]+1] = data
    TriggerClientEvent("posters:sendAddedImage", -1, data)
end)

ESX.RegisterServerCallback("posters:getImages", function(source, cb)
    cb(SaveData.json["posters"])
end)

RegisterNetEvent("posters:deleteImage", function(id, isOwner)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if Config.Posters.onlyForAdmin then 
        if not xPlayer.getPermission("video") then return end
    end
    for k,v in pairs(SaveData.json["posters"]) do
        if v.id == id then
            table.remove(SaveData.json["posters"], k)
            TriggerClientEvent("posters:deleteClientImage", -1, id)
            break
        end
    end
    if isOwner then
        local xPlayer = ESX.GetPlayerFromId(_source)
        xPlayer.addInventoryItem("poster", 1)
    end
end)

RegisterCommand("removeposter", function(source, args, raw)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer.getPermission("video") then return end
    TriggerClientEvent("posters:removePoster", source)
end)

RegisterCommand("adminposter", function(source, args, raw)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getPermission("video") then
        TriggerClientEvent("posters:placeImage", source, true)
    end
end)
