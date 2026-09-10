local lastExitedVeh = nil
local GarageActuelData = {}
--[[Citizen.CreateThread(function()
    while true do
        local sleep = 300
        local pCoords = GetEntityCoords(PlayerPedId())

        for k,v in pairs(cfg_garage_entreprise) do
            --if ESX.PlayerData.job.name == v.job then
                local distance = #(v.pos - pCoords)
                if distance < 30 then
                    --DrawMarker(v.Marker.type, v.pos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, v.Marker.x, v.Marker.y, v.Marker.z, v.Marker.r, v.Marker.g, v.Marker.b, v.Marker.a, false, false, 2, true, nil, nil, false)
                    DrawMarker(25, v.pos.x, v.pos.y, v.pos.z-0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 255, false, false, 2, false, false, false, false)
                    sleep = 0
                end

                if distance < 2.0 then
                    sleep = 0
                    null.fct.draw.Text3DBar(v.pos.x, v.pos.y, v.pos.z, "Appuyez sur [~y~E~s~] pour ouvrir le garage~s~.")
                    --ESX.ShowHelpNotification("Appuie sur ~INPUT_PICKUP~ pour ouvrir le garage")
                    if IsControlJustReleased(1, 38) then
                        GarageActuelData = v
                        openMenuGarageEZZZZZ()
                    end
                end
            --end
        end
        Wait(sleep) 
    end
end)]]

function openJobGarage(jobname, data)
    local menu = RageUI.CreateMenu("", "Que souhaitez-vous faire ?")

    RageUI.Visible(menu, not RageUI.Visible(menu))
    while menu do
        Citizen.Wait(0)
        FreezeEntityPosition(PlayerPedId(), true)
        RageUI.IsVisible(menu, function()
            for k,v in pairs(data) do
                RageUI.Button(v.name, nil, {RightLabel = ""}, true, {
                    onSelected = function()
                        local found, coords, heading = CheckSpawnData(v.spawn)
                        if found then 
                            ESX.Game.SpawnVehicle(k, coords, heading, function(vehicle)
                                lastExitedVeh = vehicle
                                for i = 0,14 do
                                   SetVehicleExtra(vehicle, i, 0)
                                end
                                if v.props then
                                    ESX.Game.SetVehicleProperties(vehicle, v.props)
                                end
                                TriggerServerEvent('Null:garage:addTempKey', GetVehicleNumberPlateText(vehicle))
                            end)
                        end
                        RageUI.CloseAll()
                    end
                })
            end
        end, function()
        end)

        if not RageUI.Visible(menu) then
            FreezeEntityPosition(PlayerPedId(), false)
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

function CheckSpawnData(data)
    if not data then
        return false, vector3(0, 0, 0), 0.0
    end

    -- Si c'est un vector4 direct (ex: vector4(x, y, z, heading))
    if type(data) == 'vector4' then
        local pos = vector3(data.x, data.y, data.z)
        local heading = data.w
        if ESX.Game.IsSpawnPointClear(pos, 2.0) then
            return true, pos, heading
        end
        return false, pos, heading
    end

    -- Si c'est une table de points {pos, heading}
    if type(data) ~= 'table' or #data == 0 then
        return false, vector3(0, 0, 0), 0.0
    end

    local found = false
    local essai = 0
    local pos = vector3(10.0, 10.10, 10.10)
    local heading = 0.0
    while not found do
        Wait(100)
        local r = math.random(1, #data)
        local _pos = data[r]
        if ESX.Game.IsSpawnPointClear(_pos.pos, 2.0) then
            pos = _pos.pos
            heading = _pos.heading
            found = true
        end
        essai = essai + 1
        if essai > #data * 2 then
            break
        end
    end
    return found, pos, heading
end

Citizen.CreateThread(function()
    while not null.data.markers.loaded do
        Wait(100)
    end
    for k,v in pairs(Config.Garage.JobsGarages) do 
        null.data.markers.register("jobgarage_"..k.."_spawn", {
            Position = v.coords,
            Public = false,
            Job = k,
            Blip = {
                Name = v.name,
                Sprite = 357,
                Display = 4,
                Scale = 0.6,
                Color = 10
            },
            Action = function()
                openJobGarage(k, v.garage)
            end
        })

        null.data.markers.register("jobgarage_"..k.."_delete", {
            Position = v.delete, 
            Public = false,
            Job = k,
            Action = function()
                if PlayerState.isInVehicle and PlayerState.vehicleSeat == -1 then
                    for k,v in pairs(v.garage) do
                        if GetEntityModel(PlayerState.vehicle) == GetHashKey(k) then
                            ESX.Game.DeleteVehicle(PlayerState.vehicle)
                            break 
                        end
                    end
                end
            end
        })
    end
end)