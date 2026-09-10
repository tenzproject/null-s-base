-- ================================================================
-- Null Taxi — lb-phone custom app (client)
-- ----------------------------------------------------------------
-- - Enregistre l'app dans lb-phone
-- - Bridge UI ↔ null-core (demande de taxi, status, position)
-- ================================================================

local IDENTIFIER = "Null_taxi"
local RES        = GetCurrentResourceName()

while GetResourceState("lb-phone") ~= "started" do
    Wait(500)
end

local function addApp()
    local ok, err = exports["lb-phone"]:AddCustomApp({
        identifier  = IDENTIFIER,
        name        = "Null Taxi",
        description = "Appelle un taxi en quelques secondes. Suivi de la course en direct.",
        developer   = "Null",
        size        = 14000,
        defaultApp  = false,
        price       = 0,
        ui          = RES .. "/ui/index.html",
        icon        = "https://cfx-nui-" .. RES .. "/ui/assets/icon.svg",
        images = {
            "https://cfx-nui-" .. RES .. "/ui/assets/icon.svg",
        },
        fixBlur     = true,
    })
    if not ok then
        print("^1[null-TAXI] AddCustomApp a échoué : " .. tostring(err) .. "^0")
    else
        print("^2[null-TAXI] App enregistrée dans lb-phone^0")
    end
end

addApp()
AddEventHandler("onResourceStart", function(resource)
    if resource == "lb-phone" then addApp() end
end)

-- ----------------------------------------------------------------
-- État local pour pousser les events vers l'UI embarquée
-- ----------------------------------------------------------------
local lastDriverCoords = nil   -- { x, y }
local hasActiveRequest = false

local function pushUI(action, data)
    SendNUIMessage({ action = action, data = data })
end

-- ----------------------------------------------------------------
-- NUI bridges
-- ----------------------------------------------------------------
RegisterNUICallback("listDrivers", function(_, cb)
    if not ESX or not ESX.TriggerServerCallback then
        cb({ ok = false, drivers = {}, total = 0 })
        return
    end
    ESX.TriggerServerCallback("null:taxi:listDrivers", function(res)
        if not res then return cb({ ok = false, drivers = {}, total = 0 }) end
        cb({ ok = true, drivers = res.drivers or {}, total = res.total or 0 })
    end)
end)

RegisterNUICallback("getMyRequest", function(_, cb)
    if not ESX or not ESX.TriggerServerCallback then return cb({ ok = false }) end
    ESX.TriggerServerCallback("null:taxi:getMyRequest", function(state)
        if not state then
            hasActiveRequest = false
            return cb({ ok = true, active = false })
        end
        hasActiveRequest = true
        cb({
            ok          = true,
            active      = true,
            request     = state.request,
            accepted    = state.accepted,
            driverName  = state.driverName,
            driverCoords= state.driverCoords or lastDriverCoords,
        })
    end)
end)

RegisterNUICallback("requestRide", function(data, cb)
    if not ESX or not ESX.TriggerServerCallback then return cb({ ok = false }) end

    local ped = PlayerPedId()
    local c   = GetEntityCoords(ped)
    local streetHash = GetStreetNameAtCoord(c.x, c.y, c.z)
    local streetName = streetHash and GetStreetNameFromHashKey(streetHash) or ""

    local payload = {
        coords  = { x = c.x, y = c.y, z = c.z },
        address = streetName,
        note    = (data and data.note) or "",
    }

    ESX.TriggerServerCallback("null:taxi:requestRide", function(ok, idOrErr)
        if ok then
            hasActiveRequest = true
            cb({ ok = true, id = idOrErr })
        else
            cb({ ok = false, error = idOrErr })
        end
    end, payload)
end)

RegisterNUICallback("cancelRequest", function(_, cb)
    if not ESX or not ESX.TriggerServerCallback then return cb({ ok = false }) end
    ESX.TriggerServerCallback("null:taxi:cancelMyRequest", function(ok)
        if ok then
            hasActiveRequest = false
            lastDriverCoords = nil
        end
        cb({ ok = ok and true or false })
    end)
end)

RegisterNUICallback("setWaypointHere", function(_, cb)
    -- Pose un waypoint sur soi-même (utile pour l'UI)
    local ped = PlayerPedId()
    local c   = GetEntityCoords(ped)
    SetNewWaypoint(c.x + 0.0, c.y + 0.0)
    cb({ ok = true })
end)

RegisterNUICallback("close", function(_, cb)
    cb("ok")
end)

-- ----------------------------------------------------------------
-- Ride HUD : reçu de ridemeter.lua (null-core) via event local
-- On le relaie dans la NUI du téléphone uniquement (pushUI).
-- ----------------------------------------------------------------
AddEventHandler('null:taxi:rideHUDMsg', function(action, data)
    pushUI(action, data or {})
end)

-- ----------------------------------------------------------------
-- Server -> client : pousse les events vers l'UI embarquée
-- ----------------------------------------------------------------
RegisterNetEvent("null:taxi:requestAccepted", function(payload)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(("~g~Un taxi a accepté votre course~s~%s")
            :format(payload and payload.driverName and (" — " .. payload.driverName) or ""))
    end
    pushUI("taxi:accepted", payload)

    -- Ouvre automatiquement l'app dans le téléphone (le joueur reçoit
    -- une "tablette" en plus, intégrée dans le tel, avec le bouton annuler).
    pcall(function()
        if exports["lb-phone"] and exports["lb-phone"].OpenApp then
            exports["lb-phone"]:OpenApp("Null Taxi")
        end
    end)
end)

RegisterNetEvent("null:taxi:driverPos", function(coords)
    if type(coords) ~= "table" then return end
    lastDriverCoords = { x = coords.x, y = coords.y }
    pushUI("taxi:driverPos", lastDriverCoords)
end)

RegisterNetEvent("null:taxi:requestEnded", function()
    hasActiveRequest = false
    lastDriverCoords = nil
    pushUI("taxi:ended", {})
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification("~b~Course taxi terminée")
    end
end)
