-- ============================================================
--  Taxi — Server Requests Queue
--  Système de demandes "appel taxi" (depuis l'app téléphone)
--  - Citoyen demande -> file d'attente -> notif chauffeurs en service
--  - Chauffeur accepte depuis la tablette -> assigne, notif citoyen
--  - Citoyen voit la progression du taxi (position du chauffeur)
-- ============================================================

local CFG = Config.Taxi

local Requests = {}            -- [id] = { id, citizenSrc, citizenIdf, citizenName, coords, address, note, createdAt, takenBy, ride = { active, startedAt, meters, price } }
local AssignedByCitizen = {}   -- [citizenSrc]   = requestId
local AssignedByDriver  = {}   -- [driverSrc]    = requestId
local OnService         = {}   -- [driverSrc]    = true  (chauffeur ayant pris son service via le menu RageUI)

local nextId = 0
local function genId()
    nextId = nextId + 1
    return ("req_%d_%d"):format(os.time(), nextId)
end

-- ms epoch (clients sont en JS, on s'aligne)
local function nowMs()
    return math.floor((os.time()) * 1000 + (GetGameTimer() % 1000))
end

local function hasTaxiJob(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    return xPlayer and xPlayer.job and xPlayer.job.name == "taxi"
end

-- "En service" = job taxi + bouton ON dans le menu RageUI.
local function isOnServiceTaxi(src)
    return hasTaxiJob(src) and OnService[src] == true
end

local function listOnServiceTaxis()
    local out = {}
    for _, src in ipairs(GetPlayers()) do
        local s = tonumber(src)
        if s and isOnServiceTaxi(s) then out[#out + 1] = s end
    end
    return out
end

-- ============================================================
-- PRIORITÉ : Y a-t-il une demande joueur non encore acceptée ?
-- Les missions IA (tablette / board) sont bloquées tant que oui.
-- ============================================================
local function hasPendingPlayerRequest()
    for _, req in pairs(Requests) do
        if not req.takenBy then return true end
    end
    return false
end
exports("HasPendingTaxiRequest", hasPendingPlayerRequest)

local function requestSnapshot(req)
    return {
        id           = req.id,
        citizenName  = req.citizenName,
        citizenId    = req.citizenIdf,
        coords       = { x = req.coords.x, y = req.coords.y, z = req.coords.z },
        address      = req.address,
        note         = req.note,
        createdAt    = req.createdAt,
    }
end

local function listPendingSnapshots()
    local out = {}
    for _, req in pairs(Requests) do
        if not req.takenBy then out[#out + 1] = requestSnapshot(req) end
    end
    table.sort(out, function(a, b) return a.createdAt < b.createdAt end)
    return out
end

local function broadcastQueueToTaxis()
    local snap = listPendingSnapshots()
    for _, src in ipairs(listOnServiceTaxis()) do
        TriggerClientEvent('null:taxi:queueUpdated', src, snap)
    end
end

-- ============================================================
-- Citizen API
-- ============================================================

ESX.RegisterServerCallback('null:taxi:requestRide', function(source, cb, payload)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false, "no_player") end

    -- Une seule demande active par citoyen
    if AssignedByCitizen[source] then
        return cb(false, "already_pending")
    end

    payload = payload or {}
    local coords = payload.coords or {}
    if type(coords.x) ~= "number" or type(coords.y) ~= "number" then
        return cb(false, "no_coords")
    end

    local id = genId()
    local req = {
        id           = id,
        citizenSrc   = source,
        citizenIdf   = xPlayer.identifier,
        citizenName  = (xPlayer.getName and xPlayer.getName()) or ("Citoyen #" .. source),
        coords       = { x = coords.x + 0.0, y = coords.y + 0.0, z = (coords.z or 0.0) + 0.0 },
        address      = tostring(payload.address or ""),
        note         = tostring(payload.note or ""),
        createdAt    = nowMs(),
        takenBy      = nil,
    }
    Requests[id] = req
    AssignedByCitizen[source] = id

    -- Notifier les chauffeurs en service
    for _, driverSrc in ipairs(listOnServiceTaxis()) do
        TriggerClientEvent('null:taxi:newRequest', driverSrc, requestSnapshot(req))
    end
    broadcastQueueToTaxis()

    cb(true, id)
end)

ESX.RegisterServerCallback('null:taxi:cancelMyRequest', function(source, cb)
    local id = AssignedByCitizen[source]
    if not id or not Requests[id] then return cb(false) end
    local req = Requests[id]

    -- Si déjà pris -> avertir chauffeur
    if req.takenBy then
        AssignedByDriver[req.takenBy] = nil
        TriggerClientEvent('null:taxi:requestCanceled', req.takenBy, id)
    end

    Requests[id] = nil
    AssignedByCitizen[source] = nil
    broadcastQueueToTaxis()
    cb(true)
end)

ESX.RegisterServerCallback('null:taxi:getMyRequest', function(source, cb)
    local id = AssignedByCitizen[source]
    if not id or not Requests[id] then return cb(nil) end
    local req = Requests[id]
    local driverName, driverSrc, driverCoords
    if req.takenBy then
        driverSrc = req.takenBy
        local drv = ESX.GetPlayerFromId(req.takenBy)
        if drv and drv.getName then driverName = drv.getName() end
        local ped = drv and GetPlayerPed(req.takenBy)
        if ped and ped ~= 0 then
            local c = GetEntityCoords(ped)
            driverCoords = { x = c.x, y = c.y, z = c.z }
        end
    end
    cb({
        request = requestSnapshot(req),
        accepted = req.takenBy ~= nil,
        driverSrc = driverSrc,
        driverName = driverName,
        driverCoords = driverCoords,
    })
end)

ESX.RegisterServerCallback('null:taxi:listDrivers', function(source, cb)
    -- Liste publique : nb de taxis en service + busy/idle
    local drivers = {}
    for _, src in ipairs(listOnServiceTaxis()) do
        local xP = ESX.GetPlayerFromId(src)
        drivers[#drivers + 1] = {
            id     = src,
            name   = (xP and xP.getName and xP.getName()) or ("Chauffeur #" .. src),
            busy   = AssignedByDriver[src] ~= nil,
        }
    end
    cb({
        drivers = drivers,
        total   = #drivers,
    })
end)

-- ============================================================
-- Driver API
-- ============================================================

ESX.RegisterServerCallback('null:taxi:listRequests', function(source, cb)
    if not isOnServiceTaxi(source) then return cb({}) end
    cb(listPendingSnapshots())
end)

ESX.RegisterServerCallback('null:taxi:acceptRequest', function(source, cb, reqId)
    if not isOnServiceTaxi(source) then return cb(false, "no_job") end
    local req = Requests[reqId]
    if not req or req.takenBy then return cb(false, "gone") end
    if AssignedByDriver[source] then return cb(false, "already_busy") end

    req.takenBy = source
    AssignedByDriver[source] = reqId

    -- Notifier le citoyen
    local drv = ESX.GetPlayerFromId(source)
    local driverName = (drv and drv.getName and drv.getName()) or ("Chauffeur #" .. source)
    req.driverNameCached = driverName
    TriggerClientEvent('null:taxi:requestAccepted', req.citizenSrc, {
        id          = req.id,
        driverSrc   = source,
        driverName  = driverName,
    })

    -- Renvoyer les coords au chauffeur pour pose du GPS
    cb(true, {
        id      = req.id,
        coords  = req.coords,
        citizen = req.citizenName,
        address = req.address,
    })

    broadcastQueueToTaxis()
end)

-- Le chauffeur est arrivé / annule sa prise en charge
ESX.RegisterServerCallback('null:taxi:releaseRequest', function(source, cb)
    local id = AssignedByDriver[source]
    if not id or not Requests[id] then return cb(false) end
    local req = Requests[id]

    -- Notifier le citoyen
    TriggerClientEvent('null:taxi:requestEnded', req.citizenSrc, id)

    Requests[id] = nil
    AssignedByCitizen[req.citizenSrc] = nil
    AssignedByDriver[source] = nil
    broadcastQueueToTaxis()
    cb(true)
end)

-- Le chauffeur ping sa position (pour que le citoyen voie sa progression)
RegisterNetEvent('null:taxi:driverPing', function(coords)
    local src = source
    local id  = AssignedByDriver[src]
    if not id or not Requests[id] then return end
    local req = Requests[id]
    if type(coords) ~= "table" then return end
    TriggerClientEvent('null:taxi:driverPos', req.citizenSrc, {
        x = tonumber(coords.x) or 0.0,
        y = tonumber(coords.y) or 0.0,
        z = tonumber(coords.z) or 0.0,
    })
end)

-- ============================================================
-- Toggle "en service" (relié au menu RageUI du chauffeur)
-- ============================================================
RegisterNetEvent('null:taxi:setService', function(onOff)
    local src = source
    if not hasTaxiJob(src) then return end
    if onOff then OnService[src] = true else OnService[src] = nil end

    -- Si le chauffeur quitte son service alors qu'il avait une course
    -- acceptée en cours, on libère la demande citoyenne.
    if not onOff then
        local dReq = AssignedByDriver[src]
        if dReq and Requests[dReq] then
            local req = Requests[dReq]
            TriggerClientEvent('null:taxi:requestEnded', req.citizenSrc, dReq)
            Requests[dReq] = nil
            AssignedByCitizen[req.citizenSrc] = nil
            AssignedByDriver[src] = nil
            broadcastQueueToTaxis()
        end
    end
end)

-- ============================================================
-- RIDE METER — compteur de course en direct
--  beginRide  : le chauffeur signale que le client est monté
--  rideTick   : update périodique de la distance totale (en m)
--  endRide    : clôture, paiement, XP, notif client
-- ============================================================
local RideCfg = (CFG and CFG.Economy and CFG.Economy.RideMeter) or {
    BaseFare = 10, PerMeter = 0.012, MinFare = 15, DriverXp = 2, SocietyShare = 1.0,
}

local function computePrice(meters)
    local price = (RideCfg.BaseFare or 10) + (meters or 0) * (RideCfg.PerMeter or 0.012)
    local min   = RideCfg.MinFare or 0
    if price < min then price = min end
    return math.floor(price + 0.5)
end

local function payToSocietyTaxi(amount)
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_taxi', function(account)
        if account then account.addMoney(amount) end
    end)
end

RegisterNetEvent('null:taxi:beginRide', function()
    local src = source
    local id  = AssignedByDriver[src]
    if not id or not Requests[id] then return end
    local req = Requests[id]
    req.ride = {
        active    = true,
        startedAt = nowMs(),
        meters    = 0,
        price     = computePrice(0),
    }
    TriggerClientEvent('null:taxi:rideStarted', src,           { id = id, citizen = req.citizenName })
    TriggerClientEvent('null:taxi:rideStarted', req.citizenSrc, { id = id, driverName = req.driverNameCached })
    -- Premier tick pour poser le HUD
    TriggerClientEvent('null:taxi:rideUpdate', src,             { meters = 0, price = req.ride.price })
    TriggerClientEvent('null:taxi:rideUpdate', req.citizenSrc,  { meters = 0, price = req.ride.price })
end)

RegisterNetEvent('null:taxi:rideTick', function(meters)
    local src = source
    local id  = AssignedByDriver[src]
    if not id or not Requests[id] then return end
    local req = Requests[id]
    if not req.ride or not req.ride.active then return end

    meters = tonumber(meters) or 0
    if meters < 0 then meters = 0 end
    if meters > 200000 then meters = 200000 end  -- safety clamp
    req.ride.meters = meters
    req.ride.price  = computePrice(meters)

    TriggerClientEvent('null:taxi:rideUpdate', src,             { meters = meters, price = req.ride.price })
    TriggerClientEvent('null:taxi:rideUpdate', req.citizenSrc,  { meters = meters, price = req.ride.price })
end)

ESX.RegisterServerCallback('null:taxi:endRide', function(source, cb)
    local src = source
    local id  = AssignedByDriver[src]
    if not id or not Requests[id] then return cb(false) end
    local req = Requests[id]
    if not req.ride or not req.ride.active then
        -- Pas de ride actif : on libère juste (cas "release")
        TriggerClientEvent('null:taxi:requestEnded', req.citizenSrc, id)
        Requests[id] = nil
        AssignedByCitizen[req.citizenSrc] = nil
        AssignedByDriver[src] = nil
        broadcastQueueToTaxis()
        return cb(true, { price = 0 })
    end

    req.ride.active = false
    local price = req.ride.price or computePrice(req.ride.meters or 0)

    -- Paiement citoyen (bank)
    local cit = ESX.GetPlayerFromId(req.citizenSrc)
    local paid = 0
    if cit then
        local bank = cit.getAccount and cit.getAccount('bank') and cit.getAccount('bank').money or 0
        local debit = math.min(bank, price)
        if debit > 0 then
            cit.removeAccountMoney('bank', debit, {
                title = 'Course Taxi', description = ('Trajet (%d m)'):format(req.ride.meters or 0), category = 'service',
            })
            paid = debit
        end
    end

    -- Paiement chauffeur + société
    local drv = ESX.GetPlayerFromId(src)
    if drv and paid > 0 then
        drv.addAccountMoney('bank', paid, {
            title = 'Course Taxi', description = ('Client %s'):format(req.citizenName or "?"), category = 'salary',
        })
        payToSocietyTaxi(math.floor(paid * (RideCfg.SocietyShare or 1.0)))
    end

    -- Notifs HUD "end"
    TriggerClientEvent('null:taxi:rideEnded', src,             { price = price, paid = paid })
    TriggerClientEvent('null:taxi:rideEnded', req.citizenSrc,  { price = price, paid = paid })

    -- Cleanup
    TriggerClientEvent('null:taxi:requestEnded', req.citizenSrc, id)
    Requests[id] = nil
    AssignedByCitizen[req.citizenSrc] = nil
    AssignedByDriver[src] = nil
    broadcastQueueToTaxis()

    cb(true, { price = price, paid = paid })
end)

-- ============================================================
-- Cleanup
-- ============================================================
AddEventHandler('playerDropped', function()
    local src = source
    OnService[src] = nil

    -- Citoyen part : supprime sa demande
    local cReq = AssignedByCitizen[src]
    if cReq and Requests[cReq] then
        local req = Requests[cReq]
        if req.takenBy then
            AssignedByDriver[req.takenBy] = nil
            TriggerClientEvent('null:taxi:requestCanceled', req.takenBy, cReq)
        end
        Requests[cReq] = nil
        AssignedByCitizen[src] = nil
        broadcastQueueToTaxis()
    end

    -- Chauffeur part : libère la demande qu'il avait prise
    local dReq = AssignedByDriver[src]
    if dReq and Requests[dReq] then
        local req = Requests[dReq]
        TriggerClientEvent('null:taxi:requestEnded', req.citizenSrc, dReq)
        Requests[dReq] = nil
        AssignedByCitizen[req.citizenSrc] = nil
        AssignedByDriver[src] = nil
        broadcastQueueToTaxis()
    end
end)
