Framework = ESX

if Config.Computer.Framework == "qbcore" then -- standardization of framework functions
    Framework.RegisterServerCallback = Framework.Functions.CreateCallback
    Framework.GetPlayerFromId = Framework.Functions.GetPlayer
    Framework.RegisterUsableItem = Framework.Functions.CreateUseableItem
    Framework.GetPlayers = Framework.Functions.GetPlayers
end


math.randomseed(os.time())

if Config.Computer.UseItem and Config.Computer.UseItem ~= "" then
    Framework.RegisterUsableItem(Config.Computer.UseItem, function(src, item)
        TriggerClientEvent("null:laptop:open", src)
    end)
end

Framework.RegisterServerCallback("ccmp:startComputer", function(_, cb, location)
    cb(RegisterNewIP(location))
end)

RegisterNetEvent("ccmp:stopComputer", function(location, laptop)
    local ip = GetIPFromLocation(location)

    if ip then
        if not laptop then
            SetIPState(ip, false)
        else
            RemoveIP(ip)
        end
    end
end)

RegisterNetEvent("cuchi_computer:getIdentifier", function()
    local _source = source
    local identifier = Config.Computer.Functions.GetIdentifier(_source, Framework.GetPlayerFromId(_source))
    TriggerClientEvent("cuchi_computer:getIdentifier", _source, identifier)
end)

Framework.RegisterServerCallback("ccmp:ipTracer", function(_, cb, ip)
    cb(GetLocationFromIP(ip) or "DISCONNECTED")
end)

Framework.RegisterServerCallback("ccmp:netscan", function(_, cb)
    cb(GetAllIPAddresses())
end)

if Config.Computer.DataHeists.Enabled then
    local heistDelays = Config.Computer.DataHeists.TypeOfDelay == "each" and {} or 0
    local breachPaths = {}

    Framework.RegisterServerCallback("ccmp:dataHeist", function(id, cb, heistCoords)
        local range = Config.Computer.DataHeists.Areas[heistCoords]
        if range then
            local ped = GetPlayerPed(id)
            local coords = GetEntityCoords(ped)
            local distance = #(coords - heistCoords)
            if distance <= range then -- security check
                local delay = (Config.Computer.DataHeists.TypeOfDelay == "each" and (heistDelays[heistCoords] or 0) or heistDelays)
                local delta = os.time() - delay
                if delta >= Config.Computer.DataHeists.Delay * 60 * 1000 then
                    if Config.Computer.DataHeists.TypeOfDelay == "each" then
                        heistDelays[heistCoords] = os.time()
                    else
                        heistDelays = os.time()
                    end

                    local gps = vector2(coords.x, coords.y)
                    local players = Framework.GetPlayers()

                    for i = 1, #players, 1 do
                        local player = Framework.GetPlayerFromId(players[i])

                        if player then
                            for j = 1, #Config.Computer.DataHeists.JobsToCall, 1 do
                                local jobName = ""
                                if Config.Computer.Framework == "esx" then
                                    jobName = player.job.name
                                end

                                if jobName == Config.Computer.DataHeists.JobsToCall[j] then
                                    TriggerClientEvent("ccmp:dataHeistCall", players[i], gps)
                                    break
                                end
                            end
                        end
                    end

                    local netPath = "//".."breach-temp"..math.random(0, 100000).."/breached/data/dump-"..math.random(0, 100000)
                    breachPaths[netPath] = heistCoords

                    cb(netPath)
                else
                    cb("delay")
                end
            end
        end
    end)

    Framework.RegisterServerCallback("ccmp:dataHeistClaim", function(id, cb, heistCoords, netPath)
        local range = Config.Computer.DataHeists.Areas[heistCoords]
        if range then
            local ped = GetPlayerPed(id)
            local coords = GetEntityCoords(ped)
            local distance = #(coords - heistCoords)
            if distance <= range then -- security check
                if breachPaths[netPath] and breachPaths[netPath] == heistCoords then
                    breachPaths[netPath] = nil
                    local player = Framework.GetPlayerFromId(id)
                    local reward = math.random(Config.Computer.DataHeists.Reward[1], Config.Computer.DataHeists.Reward[2])

                    player.addMoney(reward)


                    cb(true, reward)
                else
                    cb(false)
                end
            end
        end
    end)
end
