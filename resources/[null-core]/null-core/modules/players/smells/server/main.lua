local inSmellZone = {}
local ThreadZoneStarted = false
ESX.RegisterServerCallback("null:smells:getPlayer", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(target)
    if not xTarget or not xPlayer then return end

    local smells = xTarget.getSmells()
    if smells == nil then smells = {} end
    cb(smells)
end)

RegisterNetEvent("null:smells:updateSmell", function(data, data2)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    local deo = xPlayer.getSmell("deo")
    local actual = xPlayer.getSmell(data2) or {value = 0}
    if deo and deo.value > 0 then
        if actual.value < deo.value then
            actual.hidden = true
        else
            actual.hidden = false
        end
    end
    if (actual.value + data) > 100 then 
        actual.value = 100
        xPlayer.setSmell(data2, actual)
    else
        actual.value = (actual.value + data)
        xPlayer.setSmell(data2, actual)
    end
end)

RegisterNetEvent("null:smells:setInSmellZone", function(name)
    local xPlayer = ESX.GetPlayerFromId(source)
    inSmellZone[xPlayer.source] = {time = os.time(), type = name}
    CreateSmellZoneThread()
end)


function CreateSmellZoneThread()
    if ThreadZoneStarted then return end
    ThreadZoneStarted = true
    Citizen.CreateThread(function()
        while true do
            local nbr = 0
            for k,v in pairs(inSmellZone) do
                if (os.time() - v.time) > 15 then
                    inSmellZone[k] = nil
                else
                    nbr += 1
                end
            end 
            if nbr == 0 then break end
            Wait(10*1000)
        end
    end)
end

Citizen.CreateThread(function()
    while true do
        local final = {}
        for k,v in pairs(ESX.Players) do
            local smells = v.getSmells()
            if smells ~= nil then
                for name,data in pairs(smells) do
                    if Config.smells.allSmells[name] == nil then 
                        goto continue 
                    end
                    if inSmellZone[v.source] and inSmellZone[v.source].type == name then 
                        goto continue 
                    end
                    data.value = data.value - (Config.smells.allSmells[name].removePerMinute)
                    if Config.smells.allSmells[name].canHide and data.hidden then
                        if smells["deo"] == nil then
                            data.hidden = false
                        elseif smells["deo"].value <= 0 then
                            data.hidden = false
                        elseif smells["deo"].value < data.value then
                            data.hidden = false
                        end
                    elseif Config.smells.allSmells[name].canHide then
                        if smells["deo"] ~= nil and smells["deo"].value >= 0 and smells["deo"].value > data.value then
                            data.hidden = true
                        end
                    end
                    v.setSmell(name, data)
                    if data.value <= 0 then 
                        v.setSmell(name, nil)
                    end
                    ::continue::
                end
            end 
        end

        
        Wait(60 * 1000)
    end
end)