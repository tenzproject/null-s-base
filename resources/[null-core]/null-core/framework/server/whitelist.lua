while SaveData == nil do Wait(1) end
while SaveData.cacheLoad == false do Wait(1) end
ESX.Whitelist = {}
ESX.Whitelist.reason = Config.whitelistMessage

ESX.Whitelist.GetStatus = function()
    return SaveData.json.whitelist["status"]
end

ESX.Whitelist.ChangeStatus = function(bool, cb)
    if bool and SaveData.json.whitelist["status"] == false then
        local asyncTasks = {}
        local xPlayers = ESX.GetPlayers()
        if #xPlayers > 0 then
            for i = 1, #xPlayers, 1 do
                table.insert(asyncTasks, function(cb2)
                    local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
                    if SaveData.json.whitelist["players"][xPlayer.identifier] == nil then
                        ESX.SavePlayer(xPlayer, cb2)
                        DropPlayer(xPlayer.source, "Vous avez été déconnecté de notre serveur.")
                    end
                end)
            end
            Async.parallelLimit(asyncTasks, 8, cb)
        end
        SaveData.json.whitelist["status"] = true
    elseif bool == false and SaveData.json.whitelist["status"] == true then
        SaveData.json.whitelist["status"] = false
        cb()
    end
end

ESX.Whitelist.ChangeReason = function(value)
    ESX.Whitelist.reason = value
end

ESX.Whitelist.AddPlayer = function(identifier, name, idunique)
    if SaveData.json.whitelist == nil then SaveData.json.whitelist = {} end
    if SaveData.json.whitelist["players"] == nil then SaveData.json.whitelist["players"] = {} end
    SaveData.json.whitelist["players"][identifier] = {name = name, idunique = idunique, status = true}
end

ESX.Whitelist.RemovePlayer = function(identifier)
    SaveData.json.whitelist["players"][identifier] = nil
end

ESX.Whitelist.GetPlayer = function(identifier)
    return SaveData.json.whitelist["players"][identifier]
end

ESX.Whitelist.GetPlayers = function()
    return SaveData.json.whitelist["players"]
end

