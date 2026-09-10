ESX.Blips = {
    basicBlip = {},
    jobsBlip = {},
    myJobBlip = {},
    categoryBlip = {},
}

function ESX.getBasicBlips()
    return ESX.Blips.basicBlip
end

function ESX.addBlips(blipsData)
    if ESX.Blips.basicBlip[blipsData.name] then
        RemoveBlip(ESX.Blips.basicBlip[blipsData.name])
    end

    AddTextEntry('ESXMYBLIP', blipsData.label)

    if blipsData.entity then
        ESX.Blips.basicBlip[blipsData.name] = AddBlipForEntity(blipsData.entity)
    else
        ESX.Blips.basicBlip[blipsData.name] = AddBlipForCoord(blipsData.position)
    end

    local blip = ESX.Blips.basicBlip[blipsData.name]
    
    SetBlipSprite(blip, blipsData.sprite)

    SetBlipScale(blip, blipsData.scale)
    
    SetBlipColour(blip, blipsData.color)
    SetBlipDisplay(blip, blipsData.display)
    if blipsData.disableShortRange == nil then
        SetBlipAsShortRange(blip, true)
    end

    BeginTextCommandSetBlipName('ESXMYBLIP')
    EndTextCommandSetBlipName(blip)

    if blipsData.category then 
        SetBlipCategory(blip, blipsData.category)
    end

    if blipsData.type then
        if ESX.Blips.categoryBlip[blipsData.type] == nil then
            ESX.Blips.categoryBlip[blipsData.type] = {}
        end

        table.insert(ESX.Blips.categoryBlip[blipsData.type], blipsData)
    end
end

function ESX.addJobBlip(blipData)
    null.fct.waitPlayerLoaded()

    AddTextEntry('ESXMYBLIP2', ('[METIER] %s'):format(blipData.label))

    if not ESX.Blips.jobsBlip[blipData.jobName] then
        ESX.Blips.jobsBlip[blipData.jobName] = {}
    end

    ESX.Blips.jobsBlip[blipData.jobName][blipData.name] = blipData

    if ESX.PlayerData.job.name == blipData.jobName or ESX.PlayerData.job2.name == blipData.jobName then 
        if ESX.Blips.myJobBlip[blipData.name] then
            RemoveBlip(ESX.Blips.myJobBlip[blipData.name])
        end
        ESX.Blips.myJobBlip[blipData.name] = AddBlipForCoord(blipData.position)

        SetBlipSprite(ESX.Blips.myJobBlip[blipData.name], blipData.sprite)
        SetBlipDisplay(ESX.Blips.myJobBlip[blipData.name], blipData.display)
        SetBlipScale(ESX.Blips.myJobBlip[blipData.name], blipData.scale)
        SetBlipColour(ESX.Blips.myJobBlip[blipData.name], blipData.color)
        if blipData.category then 
            SetBlipCategory(ESX.Blips.myJobBlip[blipData.name], blipData.category)
        end
        SetBlipAsShortRange(ESX.Blips.myJobBlip[blipData.name], true)
    
        BeginTextCommandSetBlipName("ESXMYBLIP2")
        EndTextCommandSetBlipName(ESX.Blips.myJobBlip[blipData.name])
    end
end

function ESX.removeBlip(blipName)
    if ESX.Blips.basicBlip[blipName] then
        RemoveBlip(ESX.Blips.basicBlip[blipName])
    end

    if ESX.Blips.myJobBlip[blipName] then
        RemoveBlip(ESX.Blips.myJobBlip[blipName])
    end
end

function ESX.getBlip(blipsName)
    return ESX.Blips.basicBlip[blipsName]
end

function ESX.updateBlipCoords (name, pos)
    local blip = ESX.Blips.basicBlip[name]
    if not blip then return end

    SetBlipCoords(blip, pos.x, pos.y, pos.z)
end

function ESX.addAllBlipsFromCategory(categoryName)
    if ESX.Blips.categoryBlip[categoryName] == nil then return end

    for i = 1, #ESX.Blips.categoryBlip[categoryName] do 
        ESX.addBlips(ESX.Blips.categoryBlip[categoryName][i])
    end
end

function ESX.removeAllBlipsFromCategory(categoryName)
    if ESX.Blips.categoryBlip[categoryName] == nil then return end

    for i = 1, #ESX.Blips.categoryBlip[categoryName] do 
        RemoveBlip(ESX.Blips.basicBlip[ESX.Blips.categoryBlip[categoryName][i].name])
    end
end

RegisterNetEvent('null:blip:updateBlip', function(newJob, lastJob)
    if (ESX.Blips.jobsBlip[lastJob]) then
        for k,v in pairs(ESX.Blips.jobsBlip[lastJob]) do 
            for i,p in pairs(ESX.Blips.myJobBlip) do 
                if i == k then
                    RemoveBlip(ESX.Blips.myJobBlip[k])
                end
            end
        end
    end

    if not ESX.Blips.jobsBlip[newJob] then 
        ESX.Blips.jobsBlip[newJob] = {}
    end

    for k,v in pairs(ESX.Blips.jobsBlip[newJob]) do
        local blipData =  ESX.Blips.jobsBlip[newJob][k]

        AddTextEntry('ESXMYBLIP2', ('[METIER] %s'):format(blipData.label))

        ESX.Blips.myJobBlip[blipData.name] = AddBlipForCoord(blipData.position)

        SetBlipSprite(ESX.Blips.myJobBlip[blipData.name], blipData.sprite)
        SetBlipDisplay(ESX.Blips.myJobBlip[blipData.name], blipData.display)
        SetBlipScale(ESX.Blips.myJobBlip[blipData.name], blipData.scale)
        SetBlipColour(ESX.Blips.myJobBlip[blipData.name], blipData.color)
        if blipData.category then
            SetBlipCategory(ESX.Blips.myJobBlip[blipData.name], blipData.category)
        end
        SetBlipAsShortRange(ESX.Blips.myJobBlip[blipData.name], true)
    
        BeginTextCommandSetBlipName("ESXMYBLIP2")
        EndTextCommandSetBlipName(ESX.Blips.myJobBlip[blipData.name])
    end
end)