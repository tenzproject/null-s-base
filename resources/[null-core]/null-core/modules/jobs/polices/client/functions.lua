RegisterNetEvent('null:police:blips')
AddEventHandler('null:police:blips', function(id, name, pos,sprite, color, tag)
    if null.data.jobs.polices.list[ESX.PlayerData.job.name] ~= nil then
        if tag == nil then tag = 'default' end
        ESX.addBlips({
            name = tag..':police-blip_'..id,
            label = name,
            category = nil,
            position = vector3(pos.x,pos.y,pos.z),
            sprite = sprite,
            display = 4,
            scale = 0.75,
            color = color
        })
    end
end)

RegisterNetEvent('null:police:removeblips')
AddEventHandler('null:police:removeblips', function(id)
    if null.data.jobs.polices.list[ESX.PlayerData.job.name] then
        ESX.removeBlip('police-blip_'..id)
    end
end)

RegisterNetEvent('null:police:removeallblips')
AddEventHandler('null:police:removeallblips', function()
    if null.data.jobs.polices.list[ESX.PlayerData.job.name] then
        local listBlips = ESX.getBasicBlips()
        for k,v in pairs(listBlips) do
            if string.find(k, "police-blip") then
                ESX.removeBlip(k)
            end
        end
    end
end)

RegisterNetEvent('null:police:removeallblipswithtag')
AddEventHandler('null:police:removeallblipswithtag', function(tag)
    if null.data.jobs.polices.list[ESX.PlayerData.job.name] then
        local listBlips = ESX.getBasicBlips()
        for k,v in pairs(listBlips) do
            if string.find(k, "police-blip") and string.find(k, tag) then
                ESX.removeBlip(k)
            end
        end
    end
end)

RegisterNetEvent('null:police:notif')
AddEventHandler('null:police:notif', function(msg, onlyinservice)
    if null.data.jobs.polices.list[ESX.PlayerData.job.name] then
        if onlyinservice then
            if ServicePoliceCheck then 
                ESX.ShowNotification(msg)
            end
        else
            ESX.ShowNotification(msg)
        end
    end
end)


RegisterNetEvent('null:police:addchoicenotif')
AddEventHandler('null:police:addchoicenotif', function(id, name, pos,sprite, color, tag,msg)
    if null.data.jobs.polices.list[ESX.PlayerData.job.name] then
        if tag == nil then tag = 'default' end
        ESX.ShowAccept(msg, function(result)
            if result then
                ESX.addBlips({
                    name = tag..':police-blip_'..id,
                    label = name,
                    category = nil,
                    position = vector3(pos.x,pos.y,pos.z),
                    sprite = sprite,
                    display = 4,
                    scale = 0.75,
                    color = color
                })
                SetNewWaypoint(pos.x,pos.y)
                ESX.ShowNotification("Un point sur votre GPS a était placé.")
                Citizen.CreateThread(function()
                    ESX.removeBlip(tag..':police-blip_'..id)
                end)
            end
        end)    
    end
end)
