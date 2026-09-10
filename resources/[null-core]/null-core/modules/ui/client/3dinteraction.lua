local interactions3D = {}
local ShowedInteraction = {}
local displayEnabled = true
local InPauseMenu = false

local cooldowns = {}
local function actionCooldown(id, delay)
    local currentTime = GetGameTimer()
    if not cooldowns[id] or (currentTime - cooldowns[id]) >= delay then
        cooldowns[id] = currentTime
        return true
    end
    return false
end

function Display3DInteractions(show)
    displayEnabled = show

    if not show then
        for id, interaction in pairs(interactions3D) do
            SendNUIMessage({
                type = "UPDATE_3D_INTERACTION",
                id = id,
                show = false
            })
        end
    end
end

local function World3DToScreen2D(x, y, z)
    local onScreen, _x, _y = GetScreenCoordFromWorldCoord(x, y, z)
    
    if not onScreen then return false, 0, 0 end
    
    if _x < 0 or _x > 1 or _y < 0 or _y > 1 then
        return false, 0, 0
    end
    
    local screenX = _x * 1920
    local screenY = _y * 1080
    
    return true, screenX, screenY
end

ConfigAllKeys = {
    ["E"] = 51,
    ["F"] = 23,
    ["G"] = 47,
    ["H"] = 74,
    ["K"] = 311,
    ["Y"] = 246,
}

function Exist3DInteraction(id)
    if interactions3D[id] ~= nil then return true end
    return false
end

function Add3DInteraction(data, resourceName)
    if not data.id then return end
    if data.type == nil then data.type = "basic" end
    if data.maxDistance == nil then data.maxDistance = 5.0 end
    if data.maxDistance2 == nil then data.maxDistance2 = 2.0 end
    
    if interactions3D[data.id] ~= nil then
        Remove3DInteraction(data.id)
    end
    
    if type(data.coords) ~= 'vector3' then
        data.coords = vector3(data.coords.x, data.coords.y, data.coords.z)
    end

    local stockEvents = {}
    local events = {}
    local canInteraction = {}
    local canSee = {}
    local canSeeFirst = nil
    local everyTime = {}
    local rightFunction = {}

    if data.type == "multi" then
        for k, v in pairs(data.text.lines) do
            if v.id == nil then
                v.id = k
            end
            
            if v.rightAreFunction then
                rightFunction[v.id] = "null-core:3d:function:" .. data.id .. "-" .. v.id
                RegisterNetEvent(rightFunction[v.id])
                stockEvents[rightFunction[v.id]] = AddEventHandler(rightFunction[v.id], v.right)
            end
            
            if v.action ~= nil then
                events[v.id] = "null-core:3d:action:" .. data.id .. "-" .. v.id
                RegisterNetEvent(events[v.id])
                stockEvents[events[v.id]] = AddEventHandler(events[v.id], v.action)
            end
            
            if v.canInteract ~= nil then
                canInteraction[v.id] = "null-core:3d:canInteraction:" .. data.id .. "-" .. v.id
                RegisterNetEvent(canInteraction[v.id])
                stockEvents[canInteraction[v.id]] = AddEventHandler(canInteraction[v.id], v.canInteract)
            end
            
            if v.canSee ~= nil then
                canSee[v.id] = "null-core:3d:canSee:" .. data.id .. "-" .. v.id
                RegisterNetEvent(canSee[v.id])
                stockEvents[canSee[v.id]] = AddEventHandler(canSee[v.id], v.canSee)
            end
        end
    else
        if data.Action ~= nil then
            events = "null-core:3d:" .. data.id
            RegisterNetEvent(events)
            stockEvents[events] = AddEventHandler(events, data.Action)
        end
    end

    if data.canSee ~= nil then
        canSeeFirst = "null-core:3d:canSee:" .. data.id
        RegisterNetEvent(canSeeFirst)
        stockEvents[canSeeFirst] = AddEventHandler(canSeeFirst, data.canSee)
    end

    if data.everytime ~= nil then
        for k, v in pairs(data.everytime) do
            everyTime[k] = "null-core:3d:everytime:" .. data.id .. "-" .. k
            RegisterNetEvent(everyTime[k])
            stockEvents[everyTime[k]] = AddEventHandler(everyTime[k], v)
        end
    end
    
    if data.blip and type(data.blip) == 'table' then
        ESX.addBlips({
            name = ("%s-%s"):format(data.blip.name, data.id),
            label = data.blip.name,
            category = data.category,
            position = data.coords,
            sprite = data.blip.sprite,
            display = data.blip.display,
            scale = data.blip.scale ~= nil and data.blip.scale or 0.75,
            color = data.blip.color,
        })
    end

    interactions3D[data.id] = {
        coords = data.coords,
        text = data.text,
        type = data.type,
        bucket = data.bucket,
        rightFunction = rightFunction,
        canInteraction = canInteraction,
        stockEvents = stockEvents,
        resource = resourceName or GetCurrentResourceName(),
        canSee = canSee,
        canSeeFirst = canSeeFirst,
        events = events,
        everyTime = everyTime,
        maxDistance = data.maxDistance,
        maxDistance2 = data.maxDistance2,
        key = data.key,
        hidden = false
    }
end

function Remove3DInteraction(id)
    if interactions3D[id] then
        if interactions3D[id].stockEvents then
            for eventName, handler in pairs(interactions3D[id].stockEvents) do
                RemoveEventHandler(handler)
            end
        end
        
        SendNUIMessage({
            type = "REMOVE_3D_INTERACTION",
            id = id
        })
        
        ShowedInteraction[id] = nil
        interactions3D[id] = nil
    end
end

function ClearAll3DInteractions()
    SendNUIMessage({
        type = "CLEAR_3D_INTERACTIONS"
    })
    interactions3D = {}
end

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        if displayEnabled then
            for id, interaction in pairs(interactions3D) do
                if (interaction.bucket == nil or interaction.bucket == PlayerState.bucket) and not InPauseMenu then
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    local distance = #(playerCoords - interaction.coords)
                    
                    if distance <= interaction.maxDistance then
                        if not ShowedInteraction[id] then
                            ShowedInteraction[id] = interaction
                        end
                    else 
                        if ShowedInteraction[id] then
                            ShowedInteraction[id] = nil
                            SendNUIMessage({
                                type = "UPDATE_3D_INTERACTION",
                                id = id,
                                show = false
                            })
                        end
                    end
                else
                    if ShowedInteraction[id] then
                        ShowedInteraction[id] = nil
                        SendNUIMessage({
                            type = "UPDATE_3D_INTERACTION",
                            id = id,
                            show = false
                        })
                    end
                end
            end
        end
        Wait(1500)
    end
end))

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        if displayEnabled then
            for id, interaction in pairs(ShowedInteraction) do
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - interaction.coords)
                local onScreen, screenX, screenY = World3DToScreen2D(
                    interaction.coords.x,
                    interaction.coords.y,
                    interaction.coords.z
                )
                
                if onScreen then
                    if interaction.canSeeFirst then
                        local can = actionCooldown(interaction.canSeeFirst, 2000)
                        if can then
                            TriggerEvent(interaction.canSeeFirst, function(result, reason)
                                if not result then
                                    if reason then
                                        interaction.hidden = false
                                        interaction.disabled = true
                                        interaction.disabledReason = reason
                                    else
                                        interaction.hidden = true
                                        interaction.disabled = false
                                        interaction.disabledReason = nil
                                    end
                                else
                                    interaction.hidden = false
                                    interaction.disabled = false
                                    interaction.disabledReason = nil
                                end
                            end)
                        end
                    end
                    
                    if interaction.everyTime then
                        for k, v in pairs(interaction.everyTime) do
                            local can = actionCooldown(v, k)
                            if can then
                                TriggerEvent(v)
                            end
                        end
                    end
                    
                    if interaction.type == "basic" then
                        SendNUIMessage({
                            type = "UPDATE_3D_INTERACTION",
                            id = id,
                            screenX = screenX,
                            screenY = screenY,
                            distance = distance,
                            maxDistance = interaction.maxDistance2,
                            text = interaction.text,
                            key = interaction.key,
                            show = not interaction.hidden,
                            disabled = interaction.disabled,
                            disabledReason = interaction.disabledReason
                        })
                        
                        if interaction.events and interaction.key and not interaction.disabled then
                            if IsControlJustReleased(0, ConfigAllKeys[interaction.key]) and distance <= interaction.maxDistance2 then
                                TriggerEvent(interaction.events)
                            end
                        end
                    elseif interaction.type == "multi" then
                        local tempsText = interaction.text
                        
                        if type(interaction.text) == "table" then
                            for k, v in pairs(tempsText.lines) do
                                if v.rightAreFunction then
                                    if interaction.rightFunction[v.id] then
                                        local can = actionCooldown(interaction.rightFunction[v.id], 2000)
                                        if can then
                                            TriggerEvent(interaction.rightFunction[v.id], function(result)
                                                v.right = result
                                            end)
                                        end
                                    end
                                end
                                
                                if v.canSee and interaction.canSee and interaction.canSee[v.id] then
                                    local can = actionCooldown(interaction.canSee[v.id], 2000)
                                    if can then
                                        TriggerEvent(interaction.canSee[v.id], function(result, reason)
                                            if result == false then
                                                if reason then
                                                    tempsText.lines[k].hidden = false
                                                    tempsText.lines[k].disabled = true
                                                    tempsText.lines[k].disabledReason = reason
                                                else
                                                    tempsText.lines[k].hidden = true
                                                    tempsText.lines[k].disabled = false
                                                    tempsText.lines[k].disabledReason = nil
                                                end
                                            else
                                                tempsText.lines[k].hidden = false
                                                tempsText.lines[k].disabled = false
                                                tempsText.lines[k].disabledReason = nil
                                            end
                                        end)
                                    end
                                else
                                    tempsText.lines[k].hidden = false
                                    tempsText.lines[k].disabled = false
                                    tempsText.lines[k].disabledReason = nil
                                end
                            end

                            tempsText = json.encode(null.fct.format.clearTableFunction(tempsText))
                        end
                        
                        SendNUIMessage({
                            type = "UPDATE_3D_INTERACTION",
                            id = id,
                            screenX = screenX,
                            screenY = screenY,
                            distance = distance,
                            maxDistance = interaction.maxDistance2,
                            text = tempsText,
                            key = interaction.key,
                            show = not interaction.hidden
                        })
                        
                        if type(interaction.text) == "table" and interaction.text.lines ~= nil then
                            for k, v in pairs(interaction.text.lines) do
                                if v.key and IsControlJustReleased(0, ConfigAllKeys[v.key]) and v.hidden ~= true and v.disabled ~= true and distance <= interaction.maxDistance2 and interaction.events[v.id] ~= nil then
                                    if interaction.canInteraction ~= nil and interaction.canInteraction[v.id] ~= nil then
                                        TriggerEvent(interaction.canInteraction[v.id], function(result)
                                            if result then
                                                TriggerEvent(interaction.events[v.id])
                                            end
                                        end)
                                    else
                                        TriggerEvent(interaction.events[v.id])
                                    end
                                end
                            end
                        end
                    end
                else
                    if ShowedInteraction[id] then
                        if distance < interaction.maxDistance then
                            ShowedInteraction[id] = nil
                        end
                        SendNUIMessage({
                            type = "UPDATE_3D_INTERACTION",
                            id = id,
                            show = false
                        })
                    end
                end
            end
        end
        Wait(0)
    end
end))

exports('Add3DInteraction', Add3DInteraction)
exports('Remove3DInteraction', Remove3DInteraction)
exports('ClearAll3DInteractions', ClearAll3DInteractions)
exports('Exist3DInteraction', Exist3DInteraction)
exports('Display3DInteractions', Display3DInteractions)

function Refresh3DInteraction(id)
    if interactions3D[id] and ShowedInteraction[id] then
        SendNUIMessage({
            type = "UPDATE_3D_INTERACTION",
            id = id,
            show = false
        })
        ShowedInteraction[id] = nil
    end
end
exports('Refresh3DInteraction', Refresh3DInteraction)
