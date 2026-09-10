local loaded = false
local inVehicle = false
local hunger, thirst, oxygen = 100, 100, 100
local seatbelt = false
local cs, fs = 0.0, 0.0

CreateThread(function()
    Wait(2000)
    loaded = true
    SendNUIMessage({
        type = 'mic',
        range = 1
    })
end)
 
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local vhc = IsPedInAnyVehicle(ped, false)
        local health = GetEntityHealth(ped) - 100
        local armor = GetPedArmour(ped)
        local p = PlayerId()
        local sleep = 500

        if loaded then
            if not IsPauseMenuActive() then
                if vhc then
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    inVehicle = true
                    
                    if GetPedInVehicleSeat(vehicle, -1) == ped then
                        sleep = 100
                        local model = GetEntityModel(vehicle)
                        local door = false
                        local lights = false
                        local engine = GetIsVehicleEngineRunning(vehicle)
                        local fuel = GetVehicleFuelLevel(vehicle)
                        local speed = math.floor(GetEntitySpeed(vehicle) * 3.6)
                        local damage = GetVehicleEngineHealth(vehicle)
                        local rpm = GetVehicleCurrentRpm(vehicle)
                        local gear = GetVehicleCurrentGear(vehicle)
                        local handbrake = GetVehicleHandbrake(vehicle)
                        local _, lightson, highbeams = GetVehicleLightsState(vehicle)

                        -- Check doors
                        for i = 0, 5 do
                            if GetVehicleDoorAngleRatio(vehicle, i) ~= 0 then
                                door = true
                                break
                            end
                        end

                        SendNUIMessage({
                            type = "carStatus",
                            engine = engine,
                            door = door,
                            light = lightson,
                            fuel = fuel,
                            speed = speed,
                            ehealt = damage,
                            rpm = rpm,
                            gear = gear,
                            hbreake = handbrake,
                            belt = seatbelt,
                        })

                        SendNUIMessage({
                            type = "inCar"
                        })
                    else
                        sleep = 500
                    end
                else
                    sleep = 500
                    inVehicle = false
                    seatbelt = false
                    
                    SendNUIMessage({
                        type = "outCar"
                    })
                end

                -- Oxygen calculation
                if not IsEntityInWater(ped) then
                    oxygen = 100 - GetPlayerSprintStaminaRemaining(p)
                else
                    oxygen = GetPlayerUnderwaterTimeRemaining(p) * 10
                end

                SendNUIMessage({
                    type = "playerStatus",
                    heal = health,
                    armour = armor,
                    hunger = hunger,
                    thirst = thirst,
                    stamina = GetPlayerSprintStaminaRemaining(p),
                    oxygen = oxygen,
                    weather = IsEntityInWater(ped)
                })

                SendNUIMessage({
                    type = "show"
                })
            else
                SendNUIMessage({
                    type = "pause"
                })
            end
        end
        Wait(sleep)
    end
end)

-- Microphone status
CreateThread(function()
    while true do
        local p = PlayerId()
        SendNUIMessage({
            type = 'mic',
            state = NetworkIsPlayerTalking(p)
        })
        Wait(250)
    end
end)

-- Seatbelt physics
CreateThread(function()
    while true do
        Wait(0)
        if loaded and inVehicle then
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            fs = cs
            cs = GetEntitySpeed(vehicle)
            local mfwd = GetEntitySpeedVector(vehicle, true).y > 1.0
            local vhfr = (fs - cs) / GetFrameTime() > 981
            
            if not seatbelt then
                if mfwd and fs * 3.6 > 80 and vhfr then
                    SetPedToRagdoll(PlayerPedId(), 1000, 1000, 0, 0, 0, 0)
                end
            end
        end
    end
end)

-- Seatbelt command
RegisterKeyMapping('belt', 'Mettre la Ceinture', 'keyboard', 'B')
RegisterCommand('belt', function()
    if not IsPauseMenuActive() and inVehicle then
        seatbelt = not seatbelt
        LocalPlayer.state:set('Null_seatbelt', seatbelt, false)
        if seatbelt then
            TriggerEvent('InteractSound_CL:PlayOnOne', 'seatbelt', 0.7)
        else
            TriggerEvent('InteractSound_CL:PlayOnOne', 'seatbeltoff', 0.7)
        end
    end
end)

-- Reset seatbelt state when exiting vehicle (mirrors existing behaviour in main loop)
CreateThread(function()
    local lastInVehicle = false
    while true do
        Wait(500)
        if lastInVehicle and not inVehicle then
            LocalPlayer.state:set('Null_seatbelt', false, false)
        end
        lastInVehicle = inVehicle
    end
end) 

exports('HideHud', HideHud)
function HideHud(bool)
    SendNUIMessage({
        action = 'hud-hide',
        data = {state = bool}
    })
end

-- Status updates from esx_newui
RegisterNetEvent('esx_newui:updateBasics', function(status)
    for k, v in pairs(status) do
        if v.name == "hunger" then
            hunger = v.percent
        elseif v.name == "thirst" then
            thirst = v.percent
        end
    end
end)

-- Salty Chat support
RegisterNetEvent('SaltyChat_TalkStateChanged', function(status)
    SendNUIMessage({
        type = 'mic',
        state = status
    })
end)

-- pma-voice support
RegisterNetEvent('pma-voice:setTalkingMode', function(mode)
    SendNUIMessage({
        type = 'mic',
        range = mode
    })
end)
  