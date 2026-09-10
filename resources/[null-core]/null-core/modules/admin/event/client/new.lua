local event = {}
local moneyProps = {}
local moneyPropsNbr = 0
local on = false
local entredInZone = false
local entredInZone2 = false
local blip 
RegisterNetEvent('null:Eventstart', function(data)
    if not data or not data.position then return end
    local canAction = ActionCooldown("eventFourgonStart", 15000)
    if not canAction then return end
    ESX.addBlips({
        name = 'event_brinks',
        label = 'Fourgon Blindé',
        category = nil,
        position = vector3(data.position.x,data.position.y,data.position.z),
        sprite = 67,
        display = 4,
        scale = 0.75,
        color = 75
    })
    ESX.Game.SpawnVehicle('stockade', data.position, 90.0, function(vehicle)
        if vehicle == nil then return end
        event[data.position] = {
            entity = vehicle,
            on = true,
            interval = 2000,
            time = 300,
            drawNotification = function(msg, coords)
                --ESX.ShowFloatingHelpNotification(msg, coords)
                ESX.ShowHelpNotification(msg)
            end
        }
        Wait(2000)
        SetVehicleUndriveable(vehicle, true)
        FreezeEntityPosition(vehicle, 1)
        SetVehicleEngineOn(vehicle, false, false, false)
        SetVehicleDoorsLocked(vehicle, 2)

        Citizen.CreateThread(function()
            while event[data.position].on do
                Wait(event[data.position].interval)
                event[data.position].interval = 1000

                local playerCoords = GetEntityCoords(PlayerPedId())
                local dist = #(playerCoords-data.position)

                event[data.position].time = event[data.position].time - 1

                if dist < 25 then
                    entredInZone = true

                    vehicleHealth = GetEntityHealth(vehicle)
                    finalHealth = vehicleHealth/10
    
                    event[data.position].interval = 1000
    
                    ShowInfo(
                        "Informations Van",  
                        {
                            {left = "Temps", right = (event[data.position].time..' secondes'), color = "rgb(255, 255, 255)"},
                            {left = "Vie du véhicule", right = (finalHealth..'%'), color = "rgb(255, 255, 255)"},
                        }
                    )

                    if vehicleHealth/10 <= 0 then
                        SetVehicleAlarm(vehicle, 1)
                        for i = 1,9 do
                            SetVehicleDoorOpen(vehicle, i, 0, 1)
                        end
                        TriggerServerEvent('null:Eventbroke', data)
                        event[data.position].on = false
                        HideInfo()
                        entredInZone = false
                        break
                    end
    
                    if event[data.position].time <= 0 then
                        TriggerServerEvent('null:server:Eventstop', data.position, data.id)
                        entredInZone = false
                        event[data.position].on = false
                        break
                    end
                else
                    if entredInZone then
                        entredInZone = false
                        HideInfo()
                    end
                end
                
                if not event[data.position].on then
                    entredInZone = false
                    break
                end
            end
            HideInfo()
        end)
    end)
end)

RegisterNetEvent('null:Eventbroke', function(data)
    TriggerServerEvent('null:EventsecondBroke', data)
end)

RegisterNetEvent('null:EventsecondBroke', function(data)
    local nbrProps = 0
    moneyProps = {}
    for k,v in pairs(data.reward) do
        ESX.Game.SpawnObject('ex_prop_crate_money_sc', vector3(v.pos.x, v.pos.y, v.pos.z-0.98), function(obj)
            FreezeEntityPosition(obj, true)
            moneyPropsNbr = moneyPropsNbr + 1
            moneyProps[k] = {
                id = data.id,
                obj = obj,
                coords = GetEntityCoords(obj)
            }
            nbrProps = nbrProps + 1
        end)
    end

    on = true

    Citizen.CreateThread(function()
        local interval = 2000
        while on do
            Wait(interval)
            for k,v in pairs(moneyProps) do
                local playerCoords = GetEntityCoords(PlayerPedId())
                objCoords = v.coords
                dist = #(playerCoords-vector3(objCoords.x, objCoords.y, objCoords.z))
                
                if dist <= 30 then
                    if dist <= 3.5 then
                        interval = 1
                        DrawInstructionBarNotification(objCoords.x, objCoords.y, objCoords.z, '[E~s~] pour ramasser les ~y~lingôt')
                        if IsControlJustReleased(0, 38) and v.recup == nil then
                            v.recup = true
                            TriggerServerEvent('null:server:Eventtake', v.obj, k, data.id)
                        end
                    end
                else
                    interval = 2000
                end
            end

            if not on then
                break
            end
        end
    end)
    Citizen.CreateThread(function()
        local interval2 = 2000
        while on do
            Wait(interval2)
            if data == nil then return end
            if data.position == nil then return end
            interval2 = 2000
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dst = #(playerCoords-data.position)
            if dst < 25 then
                entredInZone2 = true
                interval2 = 1
                ESX.ShowHelpNotification('Récuperer les palettes d\'Argents !')
                ShowInfo(
                    "Informations Van",  
                    {
                        {left = "Temps", right = (event[data.position].time..' secondes'), color = "rgb(255, 255, 255)"},
                        {left = "Nombre de palettes", right = (moneyPropsNbr.."/"..nbrProps), color = "rgb(255, 255, 255)"},
                    }
                )
    
                if moneyPropsNbr <= 0 then
                    TriggerServerEvent('null:server:Eventstop', data.position, data.id)
                    on = false
                    entredInZone2 = false
                    break
                end
            else
                if entredInZone2 then
                    entredInZone2 = false
                    HideInfo()
                end
            end


            if not on then
                break
            end
        end 
        HideInfo()
    end)
end)

RegisterNetEvent('null:client:Eventtake', function(obj, index)
    for k,v in pairs(moneyProps) do
        if k == index then
            DeleteObject(v.obj)
            DeleteObject(obj)
            moneyProps[k] = nil
            moneyPropsNbr = moneyPropsNbr - 1
            break
        end
    end
    if #props <= 0 then
        on = false
    end
end)

RegisterNetEvent('null:client:Eventstop', function(position)
    HideInfo()
    ESX.removeBlip("event_brinks")
    on = false
    if event[position] ~= nil then
        if event[position].entity ~= nil then
            DeleteEntity(event[position].entity)
        end
        event[position] = nil
    end
end)