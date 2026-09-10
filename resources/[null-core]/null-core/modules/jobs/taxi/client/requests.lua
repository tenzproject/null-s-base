-- ============================================================
--  Taxi — Client Requests Bridge
--  - Expose les NUI callbacks consommés par la tablette React
--  - Push la position du chauffeur quand il a une course assignée
--  - Pose le waypoint quand on accepte un client
-- ============================================================

-- État partagé entre requests.lua (accept/release) et ridemeter.lua
-- (détection entrée client + tick distance).
TaxiClient = TaxiClient or {}
TaxiClient.accepted = TaxiClient.accepted or nil   -- { id, coords, citizen, address }

local pingThread = false
local function ensurePingThread()
    if pingThread then return end
    pingThread = true
    CreateThread(function()
        while pingThread do
            Wait(3000)
            if TaxiClient.accepted then
                local c = GetEntityCoords(PlayerPedId())
                TriggerServerEvent('null:taxi:driverPing', { x = c.x, y = c.y, z = c.z })
            else
                pingThread = false
                return
            end
        end
    end)
end

-- ============================================================
-- NUI callbacks (utilisés par la tablette TaxiBoard)
-- ============================================================

RegisterNUICallback('taxi:listRequests', function(_, cb)
    ESX.TriggerServerCallback('null:taxi:listRequests', function(list)
        cb({ requests = list or {} })
    end)
end)

RegisterNUICallback('taxi:acceptRequest', function(data, cb)
    if not data or not data.id then return cb({ ok = false }) end
    ESX.TriggerServerCallback('null:taxi:acceptRequest', function(ok, payload)
        if ok and payload and payload.coords then
            TaxiClient.accepted = payload
            SetNewWaypoint(payload.coords.x + 0.0, payload.coords.y + 0.0)
            ensurePingThread()
            if ESX and ESX.ShowNotification then
                ESX.ShowNotification(("~y~Course acceptée~s~ : ~b~%s~s~"):format(payload.citizen or "Client"))
            end
        else
            if ESX and ESX.ShowNotification then
                ESX.ShowNotification("~r~Impossible d'accepter cette demande")
            end
        end
        cb({ ok = ok and true or false })
    end, data.id)
end)

-- ============================================================
-- Server -> Client events
-- ============================================================

-- Met à jour la liste affichée dans la tablette si elle est ouverte
RegisterNetEvent('null:taxi:queueUpdated', function(snap)
    SendNUIMessage({ action = 'taxiBoard:requests', data = snap or {} })
end)

-- Nouveau client en attente : notif rapide pour les chauffeurs
RegisterNetEvent('null:taxi:newRequest', function(req)
    if ESX and ESX.ShowNotification then
        local addr = (req and req.address ~= "" and req.address) or "Localisation inconnue"
        ESX.ShowNotification(("~y~[Taxi]~s~ Demande de %s — %s"):format(req.citizenName or "Client", addr))
    end
end)

-- Le citoyen a annulé : libère le chauffeur si concerné
RegisterNetEvent('null:taxi:requestCanceled', function(reqId)
    if TaxiClient.accepted and TaxiClient.accepted.id == reqId then
        TaxiClient.accepted = nil
        if ESX and ESX.ShowNotification then
            ESX.ShowNotification("~r~Le client a annulé sa demande")
        end
    end
end)

-- La course est terminée / libérée
RegisterNetEvent('null:taxi:requestEnded', function(reqId)
    if TaxiClient.accepted and TaxiClient.accepted.id == reqId then
        TaxiClient.accepted = nil
    end
end)
