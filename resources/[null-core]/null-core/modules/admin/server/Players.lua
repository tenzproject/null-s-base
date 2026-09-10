

function InitAllUsers() 
    SaveData.Players.Offline.Load = false
    SaveData.Players.Offline.Number = 0
    MySQL.Async.fetchAll("SELECT idunique, name, permission_group, identifier, firstname, lastname, accounts, streamer FROM users", {}, function(result)
        for k,v in pairs(result) do
            SaveData.Players.Offline.List[v.idunique] = v
            SaveData.Players.Offline.Number = SaveData.Players.Offline.Number + 1
        end
        SaveData.Players.Offline.Load = true
    end)
end

Citizen.CreateThread(function()
    InitAllUsers()
end)