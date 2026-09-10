local ShowBadgeInProgress = false
local hash = `p_ld_id_card_002`
local badgePosition = {0.13, 0.03, -0.04, 80.0, 350.0, 180.0}

--[[function ShowJobBadge(job)
    TriggerServerEvent("Null:jsfour-idcard:open", GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), "job")
end]]

function ShowJobBadge(jobName)
    if ShowBadgeInProgress then return end
    ShowBadgeInProgress = true
    Citizen.CreateThread(function()
        local playerPed = PlayerPedId()
        local animDict = 'paper_1_rcm_alt1-9'
        local anim = 'player_one_dual-9'
        ESX.Streaming.RequestAnimDict(animDict)
        TaskPlayAnim(playerPed, animDict, anim, 1.0, -1.0, -1, 51, 0, false, false, false)

        ESX.Streaming.RequestModel(hash)
        local prop = CreateObject(hash, GetEntityCoords(playerPed), true, true, true)
        SetEntityAsNoLongerNeeded(prop)
        local boneIndex = GetPedBoneIndex(playerPed, 0xDEAD)

        local xPos, yPos, zPos, xRot, yRot, zRot = table.unpack(badgePosition)
        AttachEntityToEntity(prop, playerPed, boneIndex, xPos, yPos, zPos, xRot, yRot, zRot, true, true, false, true, 1, true)

        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
        if closestDistance ~= -1 and closestDistance <= 3.0 then
            TriggerServerEvent('Null:jsfour-idcard:open', GetPlayerServerId(PlayerId()), GetPlayerServerId(closestPlayer), 'job')
        end
        
        TriggerServerEvent("Null:jsfour-idcard:open", GetPlayerServerId(PlayerId()), GetPlayerServerId(PlayerId()), 'job')
        Wait(5000)
        ESX.Game.DeleteEntity(prop)
        ClearPedTasks(playerPed)
        ShowBadgeInProgress = false
    end)
end

exports('ShowJobBadge', function()
    local job = ESX.GetPlayerData().job.name
    if job == 'unemployed' then return end

    ShowJobBadge(job)
end)

RegisterCommand("f6", function()
    if not PlayerIsDead and ESX.PlayerData.job ~= nil then 
    
        for k,v in pairs(null.data.jobs.mecanos.list) do
            if ESX.PlayerData.job.name == v.name then
                openMecano()
            end
        end
        for k,v in pairs(null.data.jobs.bars.list) do
            if ESX.PlayerData.job.name == v.name then
                openBarBuilder()
            end
        end
        for k,v in pairs(null.data.jobs.polices.list) do
            if ESX.PlayerData.job.name == v.name then
                if ServicePoliceCheck then
                    PoliceJobs.openPolice()
                else
                    ESX.ShowNotification('Vous n\'êtes pas en service')
                end
            end
        end
        for k,v in pairs(null.data.jobs.restaurants.list) do
            if ESX.PlayerData.job.name == v.name then
                RestaurantJobs.OpenRestaurantMenu(ESX.PlayerData.job.name)
            end
        end
        for k,v in pairs(null.data.jobs.ambulances.list) do
            if ESX.PlayerData.job.name == v.name then
                if IsInServiceEMS then
                    AmbulanceJobs.OpenAmbulanceMenu(v.name)
                else
                    ESX.ShowNotification('Vous n\'êtes pas en service')
                end
            end
        end

        if ESX.PlayerData.job.name == 'gouvernement' then
            OpenMenuGouv()
        elseif ESX.PlayerData.job.name == 'realestateagent' then
            openTabletRelator()
        elseif ESX.PlayerData.job.name == 'carshop' then
             OpenDealerJobTablet('carshop')
        elseif ESX.PlayerData.job.name == 'bikeshop' then
             OpenDealerJobTablet('bikeshop')
        elseif ESX.PlayerData.job.name == 'boatshop' then
             OpenDealerJobTablet('boatshop')
        elseif ESX.PlayerData.job.name == 'taxi' then
            OpenTaxiServiceMenu()
        elseif ESX.PlayerData.job.name == 'journalist' then
            OpenMenuJournaliste()
        end
    end
end, false)


RegisterKeyMapping('f6', 'Menu Entreprise', 'keyboard', 'F6')