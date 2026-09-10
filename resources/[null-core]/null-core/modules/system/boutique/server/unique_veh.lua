
Citizen.CreateThread(function()
    if SaveData.json["boutique"] == nil then
        while SaveData.json["boutique"] == nil do 
            Wait(100)
        end
    end
    
    if SaveData.json["boutique"]["unique_veh"] == nil then
        SaveData.json["boutique"]["unique_veh"] = {}
    end
    
    function GetUniqueVehi(idunique)
        local returnTable = {}
        for k,v in pairs(SaveData.json["boutique"]["unique_veh"]) do 
            if (v.stock == nil or (v.stock > 0)) and (v.idunique == nil or idunique == v.idunique) then
                returnTable[k] = v
            end 
        end
        return returnTable
    end
    
    RegisterNetEvent("null:boutique:staff:UniqueVeh", function(id, data)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getGroup() == "user" then return end
        if id then
            if data == nil then
                SaveData.json["boutique"]["unique_veh"][id] = nil
            else
                if data.model then
                    SaveData.json["boutique"]["unique_veh"][id].model = data.model
                end
                if data.label then
                    SaveData.json["boutique"]["unique_veh"][id].label = data.label
                end
                if data.price then
                    SaveData.json["boutique"]["unique_veh"][id].price = data.price
                end
                if data.stock then
                    SaveData.json["boutique"]["unique_veh"][id].stock = data.stock
                end
                if data.idunique then
                    SaveData.json["boutique"]["unique_veh"][id].idunique = data.idunique
                end
            end
        else
            local id = #SaveData.json["boutique"]["unique_veh"] + 1
            SaveData.json["boutique"]["unique_veh"][id] = {
                id = id,
                model = data.model,
                label = data.label,
                price = data.price,
                stock = data.stock or 1,
                initStock = data.stock or 1,
                idunique = data.idunique or nil,
                createBy = xPlayer.getName(),
                createAt = os.time(),
            }
        end
        TriggerClientEvent("null:boutique:recevieUniqueVeh", xPlayer.source, GetUniqueVehi(xPlayer.getIdunique()))
    end)
    
    
    
    RegisterNetEvent("null:boutique:boughtUniqueVeh", function(veh)
        local xPlayer = ESX.GetPlayerFromId(source)
        local uniqueVehs = GetUniqueVehi(xPlayer.getIdunique())
        local selectVeh = nil
        for k,v in pairs(uniqueVehs) do 
            if v.id == veh then
                selectVeh = v
            end
        end
        if selectVeh == nil then return null.DebugPrint("SelectVeh Unique don't find.") end
        exports["null-ui"]:OnProcessCheckout(xPlayer.source, selectVeh.price, string.format("Achat de : %s", selectVeh.label), function()
            local newStock = SaveData.json["boutique"]["unique_veh"][selectVeh.id].stock - 1
            SaveData.json["boutique"]["unique_veh"][selectVeh.id].stock = newStock
            if newStock <= 0 then
                SaveData.json["boutique"]["unique_veh"][selectVeh.id] = nil
            end
    
            local newplate = nil
            local oldCacheData = Cache.Get("owned_vehicles")
            local PlateExist = true
            while PlateExist do
                newplate = null.fct.format.randomPlateText()
                if oldCacheData[string.upper(newplate)] == nil then
                    PlateExist = false
                end
                Wait(100)
            end
    
            oldCacheData[string.upper(newplate)] = {
                owner = xPlayer.identifier,
                plate = string.upper(newplate),
                model = selectVeh.model,
                label = selectVeh.label,
                vehicle = { model = GetHashKey(selectVeh.model), plate = newplate },
                coffre = {},
                type = "car",
                state = true,
                boutique = true,
                garage = true,
            }
            Cache.Edit("owned_vehicles", oldCacheData)
            TriggerClientEvent("null:boutique:recevieUniqueVeh", xPlayer.source, GetUniqueVehi(xPlayer.getIdunique()))
            xPlayer.showNotification("Vous avez acheter : ~b~" .. selectVeh.label .. "~s~ sur la boutique !")
        end, function()
            xPlayer.showNotification("Vous ne posséder pas les points nécessaires")
            return
        end)
    end)
end)
