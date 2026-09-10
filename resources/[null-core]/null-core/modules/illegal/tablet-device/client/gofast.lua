-- ============================================================================
-- ILLEGAL TABLET DEVICE - Solo GoFast (client)
-- ============================================================================

local SGF = {}
SGF.active = false
SGF.mission = nil
SGF.vehicle = nil
SGF.pickupPed = nil
SGF.blipPickup = nil
SGF.blipDelivery = nil
SGF.phase = nil  -- 'pickup' | 'delivery'
SGF.inAnim = false

local function dist(a, b) return #(a - b) end

local function loadModel(model)
    local hash = type(model) == 'string' and GetHashKey(model) or model
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 5000 do Wait(10) t = t + 10 end
    return hash
end

local function makeBlip(coords, sprite, color, label, route)
    local b = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(b, sprite)
    SetBlipScale(b, 0.9)
    SetBlipColour(b, color)
    SetBlipAlpha(b, 220)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label)
    EndTextCommandSetBlipName(b)
    if route then SetBlipRoute(b, true) end
    PulseBlip(b)
    return b
end

local function removeBlips()
    if SGF.blipPickup then RemoveBlip(SGF.blipPickup) SGF.blipPickup = nil end
    if SGF.blipDelivery then RemoveBlip(SGF.blipDelivery) SGF.blipDelivery = nil end
end

local function playGiveAnim(targetPed)
    SGF.inAnim = true
    local p = PlayerPedId()
    TaskTurnPedToFaceEntity(p, targetPed, 1000)
    TaskTurnPedToFaceEntity(targetPed, p, 1000)
    Wait(800)
    local dict = 'mp_common'
    ESX.Streaming.RequestAnimDict(dict)
    TaskPlayAnim(p, dict, 'givetake1_a', -1.0, -1.0, 2500, 0, 0, true, true, true)
    TaskPlayAnim(targetPed, dict, 'givetake1_a', -1.0, -1.0, 2500, 0, 0, true, true, true)
    Wait(2500)
    SGF.inAnim = false
end

local function cleanup()
    removeBlips()
    if SGF.pickupPed and DoesEntityExist(SGF.pickupPed) then DeleteEntity(SGF.pickupPed) end
    if SGF.vehicle and DoesEntityExist(SGF.vehicle) then ESX.Game.DeleteVehicle(SGF.vehicle) end
    SGF.pickupPed = nil
    SGF.vehicle = nil
    SGF.mission = nil
    SGF.active = false
    SGF.phase = nil
end

local function startPickup()
    local m = SGF.mission
    SGF.phase = 'pickup'
    SGF.blipPickup = makeBlip(m.pickup, 478, 5, 'Go-Fast — Pickup', true)
    ESX.ShowAdvancedNotification('CRIMENET', '~r~Go-Fast', 'Rends-toi au point de pickup.', 'CHAR_MULTIPLAYER')

    -- Spawn vehicle
    local vhash = loadModel(m.vehicle)
    local v = CreateVehicle(vhash, m.pickup.x, m.pickup.y, m.pickup.z, m.pickup.w, true, true)
    SetVehicleNumberPlateText(v, m.plate)
    SetVehicleDoorsLocked(v, 2)
    FreezeEntityPosition(v, true)
    SetModelAsNoLongerNeeded(vhash)
    SGF.vehicle = v

    -- Spawn contact ped
    local phash = loadModel(m.pedModel)
    local px = m.pickup.x + 2.0 * math.cos(math.rad(m.pickup.w + 90))
    local py = m.pickup.y + 2.0 * math.sin(math.rad(m.pickup.w + 90))
    local ped = CreatePed(4, phash, px, py, m.pickup.z - 1.0, m.pickup.w + 180.0, false, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetModelAsNoLongerNeeded(phash)
    SGF.pickupPed = ped

    CreateThread(function()
        while SGF.active and SGF.phase == 'pickup' do
            local sleep = 500
            local pc = GetEntityCoords(PlayerPedId())
            local d = dist(pc, vector3(px, py, m.pickup.z))
            if d < 15.0 then
                sleep = 5
                if d < 2.5 and not SGF.inAnim then
                    ESX.ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour récupérer les clés')
                    if IsControlJustPressed(0, 51) then
                        playGiveAnim(ped)
                        startDelivery()
                        return
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

function startDelivery()
    local m = SGF.mission
    SGF.phase = 'delivery'
    if SGF.vehicle and DoesEntityExist(SGF.vehicle) then
        SetVehicleDoorsLocked(SGF.vehicle, 1)
        FreezeEntityPosition(SGF.vehicle, false)
    end
    if SGF.blipPickup then RemoveBlip(SGF.blipPickup) SGF.blipPickup = nil end
    if SGF.pickupPed and DoesEntityExist(SGF.pickupPed) then
        FreezeEntityPosition(SGF.pickupPed, false)
        TaskWanderStandard(SGF.pickupPed, 10.0, 10)
        local ped = SGF.pickupPed
        SGF.pickupPed = nil
        SetTimeout(15000, function() if DoesEntityExist(ped) then DeleteEntity(ped) end end)
    end

    SGF.blipDelivery = makeBlip(m.delivery, 162, 1, 'Go-Fast — Livraison', true)
    ESX.ShowAdvancedNotification('CRIMENET', '~y~Livraison', 'Livre le véhicule au point indiqué.', 'CHAR_MULTIPLAYER')

    CreateThread(function()
        while SGF.active and SGF.phase == 'delivery' do
            local sleep = 500
            local pc = GetEntityCoords(PlayerPedId())
            local d = dist(pc, vector3(m.delivery.x, m.delivery.y, m.delivery.z))
            if SGF.vehicle and DoesEntityExist(SGF.vehicle) and IsEntityDead(SGF.vehicle) then
                TriggerServerEvent('null:illegalDevice:gofast:fail', 'VEHICLE_DESTROYED')
                cleanup()
                return
            end
            if d < 25.0 then
                sleep = 5
                local inVeh = IsPedSittingInAnyVehicle(PlayerPedId())
                if d < 6.0 and not inVeh then
                    ESX.ShowHelpNotification('Appuyez sur ~INPUT_CONTEXT~ pour livrer le véhicule')
                    if IsControlJustPressed(0, 51) then
                        TriggerServerEvent('null:illegalDevice:gofast:complete')
                        local delivery = m.delivery
                        cleanup()
                        SetTimeout(800, function()
                            local rh = loadModel(Config.IllegalDevice.GoFast.ReturnVehicle)
                            local retVeh = CreateVehicle(rh, delivery.x + 3.0, delivery.y, delivery.z, delivery.w + 180.0, true, true)
                            SetVehicleNumberPlateText(retVeh, 'RETOUR')
                            TaskWarpPedIntoVehicle(PlayerPedId(), retVeh, -1)
                            SetModelAsNoLongerNeeded(rh)
                        end)
                        return
                    end
                elseif d < 6.0 and inVeh then
                    ESX.ShowHelpNotification('~r~Sortez du véhicule pour livrer')
                end
            end
            Wait(sleep)
        end
    end)
end

RegisterNetEvent('null:illegalDevice:gofast:response')
AddEventHandler('null:illegalDevice:gofast:response', function(data)
    if data.error then
        if data.error == 'COOLDOWN' then
            local m = math.ceil((data.remaining or 0) / 60)
            ESX.ShowNotification('~r~[CrimeNet] Cooldown actif : ' .. m .. ' min restantes.')
        elseif data.error == 'ALREADY_ACTIVE' then
            ESX.ShowNotification('~r~[CrimeNet] Tu as déjà une mission en cours.')
        elseif data.error == 'INVALID' then
            ESX.ShowNotification('~r~[CrimeNet] Difficulté invalide.')
        else
            ESX.ShowNotification('~r~[CrimeNet] Erreur : ' .. tostring(data.error))
        end
        return
    end
    if data.success and data.mission then
        SGF.mission = data.mission
        SGF.active = true
        startPickup()
    end
end)

RegisterNetEvent('null:illegalDevice:gofast:result')
AddEventHandler('null:illegalDevice:gofast:result', function(data)
    if data.success then
        ESX.ShowAdvancedNotification('CRIMENET', '~g~Mission terminée', 'Paiement : ~g~$' .. data.payment, 'CHAR_MULTIPLAYER')
        PlaySoundFrontend(-1, 'Event_Start_Text', 'GTAO_FM_Events_Soundset', 1)
    else
        ESX.ShowAdvancedNotification('CRIMENET', '~r~Mission échouée', tostring(data.reason or ''), 'CHAR_MULTIPLAYER')
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then cleanup() end
end)
