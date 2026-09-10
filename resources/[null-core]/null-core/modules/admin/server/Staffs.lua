function InitAllStaffs()
    SaveData.Admin.Staffs.Load = false
    MySQL.Async.fetchAll("SELECT * FROM staff", {}, function(result)
        for k,v in pairs(result) do
            SaveData.Admin.Staffs.List[v.idunique] = v
        end
        SaveData.Admin.Staffs.Load = true
    end)
end

Citizen.CreateThread(function()
    InitAllStaffs()
end)