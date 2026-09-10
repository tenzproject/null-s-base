-- ============================================================
--  Taxi — Client Ride Meter
--  - Côté chauffeur : détecte l'entrée du client dans le véhicule
--    puis envoie beginRide + rideTick au serveur (distance réelle).
--  - Côté citoyen  : reçoit rideStarted/rideUpdate/rideEnded et
--    pousse la HUD NUI (taxiRide:*).
-- ============================================================

local CFG = Config.Taxi
local METER_CFG = (CFG and CFG.Economy and CFG.Economy.RideMeter) or {
    UpdateMs = 500,
}

TaxiClient = TaxiClient or {}
TaxiClient.ride = TaxiClient.ride or {
    active     = false,   -- course en cours (chauffeur OU passager)
    asDriver   = false,   -- rôle courant
    meters     = 0,       -- distance cumulée (chauffeur uniquement)
    price      = 0,
    lastCoords = nil,
}

-- ------------------------------------------------------------
-- HUD bridge — passe par null-taxi-app (phone iframe)
-- Les messages sont routés via TriggerEvent local pour que
-- null-taxi-app/client.lua les intercepte et les envoie
-- dans son propre NUI (l'iframe lb-phone), jamais en fullscreen.
-- ------------------------------------------------------------
local function openHud(role, payload)
    TriggerEvent('null:taxi:rideHUDMsg', 'taxiRide:start', {
        role       = role,
        citizen    = payload and payload.citizen,
        driverName = payload and payload.driverName,
    })
end

local function updateHud(meters, price)
    TriggerEvent('null:taxi:rideHUDMsg', 'taxiRide:update', {
        meters = math.floor(meters or 0),
        price  = math.floor(price or 0),
    })
end

local function closeHud(summary)
    TriggerEvent('null:taxi:rideHUDMsg', 'taxiRide:end', summary or {})
end

-- ============================================================
-- DRIVER SIDE
-- ============================================================

local function plateOfVehicle(veh)
    return veh and veh ~= 0 and GetVehicleNumberPlateText(veh) or nil
end

-- Surveille : quand TaxiClient.accepted est set ET que le chauffeur est
-- dans un véhicule, on attend qu'un autre joueur (le client) entre, et
-- on démarre la course.
CreateThread(function()
    while true do
        Wait(1000)
        local ride = TaxiClient.ride
        local acc  = TaxiClient.accepted

        if acc and not ride.active then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh and veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                -- Y a-t-il un passager non chauffeur ?
                local passengerSeat = nil
                for seat = 0, 3 do
                    local p = GetPedInVehicleSeat(veh, seat)
                    if p and p ~= 0 and p ~= ped and IsPedAPlayer(p) then
                        passengerSeat = seat
                        break
                    end
                end
                if passengerSeat then
                    ride.active   = true
                    ride.asDriver = true
                    ride.meters   = 0
                    ride.price    = 0
                    ride.lastCoords = GetEntityCoords(ped)
                    TriggerServerEvent('null:taxi:beginRide')
                end
            end
        end
    end
end)

-- Tick distance (chauffeur seulement)
CreateThread(function()
    while true do
        local ride = TaxiClient.ride
        if ride.active and ride.asDriver then
            local ped = PlayerPedId()
            local cur = GetEntityCoords(ped)
            if ride.lastCoords then
                local d = #(cur - ride.lastCoords)
                if d > 0.5 and d < 100.0 then  -- filtre téléports
                    ride.meters = ride.meters + d
                end
            end
            ride.lastCoords = cur

            -- Condition de fin : plus personne d'autre dans le véhicule
            local veh = GetVehiclePedIsIn(ped, false)
            local anyPassenger = false
            if veh and veh ~= 0 then
                for seat = 0, 3 do
                    local p = GetPedInVehicleSeat(veh, seat)
                    if p and p ~= 0 and p ~= ped and IsPedAPlayer(p) then
                        anyPassenger = true; break
                    end
                end
            end
            if not anyPassenger then
                -- Le client est descendu → fin de course
                ESX.TriggerServerCallback('null:taxi:endRide', function(ok, result)
                    if ok and result then
                        closeHud({ price = result.price or 0, paid = result.paid or 0 })
                    end
                end)
                ride.active = false
                ride.asDriver = false
                ride.meters = 0
                ride.lastCoords = nil
                TaxiClient.accepted = nil
            else
                TriggerServerEvent('null:taxi:rideTick', math.floor(ride.meters))
            end
        end
        Wait(METER_CFG.UpdateMs or 500)
    end
end)

-- ============================================================
-- EVENTS (driver + passenger)
-- ============================================================

RegisterNetEvent('null:taxi:rideStarted', function(payload)
    payload = payload or {}
    local ride = TaxiClient.ride
    if not ride.asDriver then
        -- Passager : on s'accroche à la HUD
        ride.active   = true
        ride.asDriver = false
        ride.meters   = 0
        ride.price    = 0
        openHud('passenger', { driverName = payload.driverName })
    else
        openHud('driver', { citizen = payload.citizen })
    end
end)

RegisterNetEvent('null:taxi:rideUpdate', function(payload)
    payload = payload or {}
    updateHud(payload.meters or 0, payload.price or 0)
end)

RegisterNetEvent('null:taxi:rideEnded', function(payload)
    payload = payload or {}
    closeHud({ price = payload.price or 0, paid = payload.paid or 0 })
    local ride = TaxiClient.ride
    ride.active    = false
    ride.asDriver  = false
    ride.meters    = 0
    ride.lastCoords = nil
end)
