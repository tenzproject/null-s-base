AddEventHandler('esx:playerLoaded', function(source)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    TriggerClientEvent("null:ascensueur:recevie", source, SaveData.json["ascenceurs"])
end)

RegisterNetEvent('null:initAscenseur')
AddEventHandler('null:initAscenseur', function()
    local source = source
	local xPlayer = ESX.GetPlayerFromId(source)

    TriggerClientEvent("null:ascenseur:recevie", source, SaveData.json["ascenceurs"])
end)

RegisterNetEvent('null:ascenseur:create')
AddEventHandler('null:ascenseur:create', function(name,data, pos)
    local xPlayer = ESX.GetPlayerFromId(source)
    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        local FinalData = {}
        for k,v in pairs(data) do
            FinalData[k] = {position=v.pos, label=v.label,heading=v.heading}
        end
        table.insert(SaveData.json["ascenceurs"], {
            pos = pos,
            name = name,
            data = FinalData,
        })
        --[[SaveData.json["ascenceurs"][name] = {
            pos = pos,
            name = name,
            data = FinalData,
        }]]
        TriggerClientEvent("null:ascenseur:recevie", -1, SaveData.json["ascenceurs"])
    else
        ExecuteCommand("ban " .. source .. " Tentative de triche creation mécano (0)")
    end
end)

RegisterNetEvent('null:ascenseur:remove')
AddEventHandler('null:ascenseur:remove', function(name)
    local xPlayer = ESX.GetPlayerFromId(source)

    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        for k,v in pairs(SaveData.json["ascenceurs"]) do
            if v.name == name then 
                NullLemlrdev = v
                SaveData.json["ascenceurs"][k] = nil
                break
            end
        end
        if NullLemlrdev ~= nil then
            TriggerClientEvent("null:ascenseur:recevie", -1, SaveData.json["ascenceurs"])
        end
    else
        ExecuteCommand("ban " .. source .. " Tentative de triche creation mécano (0)")
    end
end)