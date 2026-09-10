ESX.Cache = {}
ESX.Cache.Jobs = {
    ambulance = {},
    police = {}, 
    gouvernement = {}, 
}

function AddJobToCache(name)
    ESX.Cache.Jobs[name] = {}
end

Citizen.CreateThread(function()
    while SaveData.cacheLoad ~= true do Wait(10) end
    for k,v in pairs(SaveData.json["entreprises"]["Ambulance"]) do 
        AddJobToCache(k)
    end
    for k,v in pairs(SaveData.json["entreprises"]["Police"]) do 
        AddJobToCache(k)
    end
    for k,v in pairs(SaveData.json["entreprises"]["Mécano"]) do 
        AddJobToCache(k)
    end
    for k,v in pairs(SaveData.json["entreprises"]["Farm"]) do 
        AddJobToCache(k)
    end
    for k,v in pairs(SaveData.json["entreprises"]["Restaurant"]) do 
        AddJobToCache(k)
    end
    for k,v in pairs(SaveData.json["entreprises"]["Bar"]) do 
        AddJobToCache(k)
    end
end)

RegisterServerEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(source, xPlayer)
    if ESX.Cache.Jobs[xPlayer.job.name] then 
        if not ESX.Cache.Jobs[xPlayer.job.name][xPlayer.source] then 
            ESX.Cache.Jobs[xPlayer.job.name][xPlayer.source] = xPlayer.source
        end
    end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(PlayerSrc, job, lastjob)
    if ESX.Cache.Jobs[lastjob.name] then 
        ESX.Cache.Jobs[lastjob.name][PlayerSrc] = nil 
    end
    if ESX.Cache.Jobs[job.name] then 
        ESX.Cache.Jobs[job.name][PlayerSrc] = PlayerSrc
    end
end)

AddEventHandler('playerDropped', function (reason)
    local xPlayer = ESX.GetPlayerFromId(source)
    if (xPlayer) then
        if ESX.Cache.Jobs[xPlayer.job.name] then 
            if ESX.Cache.Jobs[xPlayer.job.name][xPlayer.source] then 
                ESX.Cache.Jobs[xPlayer.job.name][xPlayer.source] = nil
            end
        end
    end
end)

function ESX.GetJobsPlayers(jobname) 
    if ESX.Cache.Jobs[jobname] then 
        return ESX.Cache.Jobs[jobname]
    end
end

function ESX.GetJobsTypePlayers(jobtype) 
    local AllPlayers = {}
    local typeLab = nil
    if jobtype == "ambulance" then
        typeLab = "Ambulance"
    elseif jobtype == "bars" then
        typeLab = "Bar"
    elseif jobtype == "restaurant" then
        typeLab = "Restaurant"
    elseif jobtype == "farm" then
        typeLab = "Farm"
    elseif jobtype == "mecano" then
        typeLab = "Mécano"
    end
    if typeLab then
        for k,v in pairs(SaveData.json.entreprises[typeLab]) do 
            if ESX.Cache.Jobs[k] then
                for k2, v2 in pairs(ESX.Cache.Jobs[k]) do 
                    AllPlayers[k2] = v2
                end
            end
        end
    end
    return AllPlayers
end