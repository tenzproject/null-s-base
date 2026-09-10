-- ============================================================
--  Taxi — Client / Core
--  État global · Bridge NUI · Hook F6
-- ============================================================

TaxiClient = TaxiClient or {}

local CFG = Config.Taxi

TaxiClient.State = {
    profile        = nil,        -- profil reçu du serveur (rank, xp, todayRides...)
    inMission      = false,
    mission        = nil,        -- table mission active (CFG.Missions[key])
    missionKey     = nil,
    step           = "idle",     -- idle | toPickup | atPickup | inRide | atDestination
    stops          = {},         -- liste des destinations { pos, label }
    stopIndex      = 1,
    pickupCoords   = nil,
    pickupBlip     = nil,
    destBlip       = nil,
    pedEntity      = nil,
    pedDialogue    = nil,
    startTime      = 0,
    startCoords    = nil,
    distanceMeters = 0,
    moodPercent    = CFG.Economy.Mood.StartPercent,
    fareEstimate   = 0,
    lastVehicle    = nil,
}

-- ============================================================
-- Helpers
-- ============================================================
function TaxiClient.notify(msg)
    if ESX and ESX.ShowNotification then ESX.ShowNotification(msg) end
end

function TaxiClient.isOnDuty()
    return ESX and ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name == "taxi"
end

function TaxiClient.isInTaxi()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 then return nil end
    if GetPedInVehicleSeat(veh, -1) ~= ped then return nil end
    -- Vérifie que c'est bien un véhicule taxi configuré
    local model = GetEntityModel(veh)
    for _, v in ipairs(CFG.Vehicles) do
        if model == GetHashKey(v.model) then return veh, v end
    end
    return veh, nil
end

function TaxiClient.requestModel(name)
    local hash = type(name) == "number" and name or GetHashKey(name)
    if not IsModelInCdimage(hash) then return false end
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(50) end
    return HasModelLoaded(hash)
end

function TaxiClient.pickRandom(t) return t[math.random(1, #t)] end

function TaxiClient.dist2D(a, b)
    return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z))
end

-- ============================================================
-- Profile (refresh depuis le serveur)
-- ============================================================
function TaxiClient.RefreshProfile(cb)
    ESX.TriggerServerCallback('null:taxi:getProfile', function(profile)
        TaxiClient.State.profile = profile
        if cb then cb(profile) end
        TaxiClient.PushHUD()
    end)
end

-- ============================================================
-- Bridge NUI
-- ============================================================
function TaxiClient.PushHUD(extra)
    local s = TaxiClient.State
    SendNUIMessage({
        action = 'taxiHUD:update',
        data = {
            visible       = s.inMission,
            missionKey    = s.missionKey,
            missionLabel  = s.mission and s.mission.label or nil,
            step          = s.step,
            stopIndex     = s.stopIndex,
            stopCount     = #s.stops,
            stopLabel     = s.stops[s.stopIndex] and s.stops[s.stopIndex].label or nil,
            distanceMeters= math.floor(s.distanceMeters),
            moodPercent   = math.floor(s.moodPercent),
            fareEstimate  = math.floor(s.fareEstimate),
            elapsedSec    = s.startTime > 0 and (GetGameTimer() - s.startTime) / 1000 or 0,
            extra         = extra or nil,
        }
    })
end

function TaxiClient.OpenHUD()
    SendNUIMessage({ action = 'taxiHUD:open' })
    TaxiClient.PushHUD()
end

function TaxiClient.CloseHUD()
    SendNUIMessage({ action = 'taxiHUD:close' })
end

function TaxiClient.OpenBoard()
    if not TaxiClient.isOnDuty() then
        TaxiClient.notify("~r~Vous n'êtes pas en service taxi")
        return
    end
    TaxiClient.RefreshProfile(function(profile)
        -- Résolution de la brand (même logique que les shops)
        local brand = CFG.Brand
        if CFG.Brands then
            if CFG.DefaultBrand and CFG.Brands[CFG.DefaultBrand] then
                brand = CFG.Brands[CFG.DefaultBrand]
            else
                for _, b in pairs(CFG.Brands) do brand = b; break end
            end
        end

        SendNUIMessage({
            action = 'taxiBoard:open',
            data = {
                profile  = profile,
                missions = TaxiClient.GetMissionsForUI(),
                ranks    = CFG.Ranks,
                brand    = brand,
            }
        })
        SetNuiFocus(true, true)
    end)
end

function TaxiClient.CloseBoard()
    SendNUIMessage({ action = 'taxiBoard:close' })
    SetNuiFocus(false, false)
end

function TaxiClient.GetMissionsForUI()
    local list = {}
    local rankIdx = 1
    if TaxiClient.State.profile and TaxiClient.State.profile.rank then
        for i, r in ipairs(CFG.Ranks) do
            if r.key == TaxiClient.State.profile.rank.key then rankIdx = i end
        end
    end
    local function rankPos(key)
        if not key then return 1 end
        for i, r in ipairs(CFG.Ranks) do if r.key == key then return i end end
        return 1
    end
    for key, m in pairs(CFG.Missions) do
        list[#list + 1] = {
            key         = key,
            label       = m.label,
            description = m.description,
            icon        = m.icon,
            stops       = m.stops,
            requireRank = m.requireRank,
            unlocked    = (rankIdx >= rankPos(m.requireRank)),
        }
    end
    table.sort(list, function(a, b)
        if a.unlocked ~= b.unlocked then return a.unlocked end
        return (a.label or "") < (b.label or "")
    end)
    return list
end

-- ============================================================
-- NUI Callbacks
-- ============================================================
RegisterNUICallback('taxi:close', function(_, cb)
    TaxiClient.CloseBoard()
    cb('ok')
end)

RegisterNUICallback('taxi:startMission', function(data, cb)
    TaxiClient.CloseBoard()
    if data and data.key and TaxiClient.StartMission then
        TaxiClient.StartMission(data.key)
    end
    cb('ok')
end)

RegisterNUICallback('taxi:cancelMission', function(_, cb)
    if TaxiClient.CancelMission then TaxiClient.CancelMission() end
    cb('ok')
end)

-- ============================================================
-- Hook F6 — global menu jobs appelle OpenMenuTaxi()
-- ============================================================
function OpenMenuTaxi()
    OpenTaxiServiceMenu()
end

-- Compat ascendante : la fonction StartTaxiMission est appelée
-- depuis quelques anciens points (RageUI). On la mappe au nouveau flow.
function StartTaxiMission()
    if TaxiClient.State.inMission then
        if TaxiClient.CancelMission then TaxiClient.CancelMission() end
    else
        if TaxiClient.StartMission then TaxiClient.StartMission("standard") end
    end
end

-- ============================================================
-- Listeners
-- ============================================================
RegisterNetEvent('esx:setJob', function(job)
    if job and job.name == "taxi" then
        TaxiClient.RefreshProfile()
    else
        TaxiClient.CloseHUD()
        if TaxiClient.State.inMission and TaxiClient.CancelMission then
            TaxiClient.CancelMission()
        end
    end
end)

AddEventHandler('esx:onPlayerSpawn', function()
    if TaxiClient.isOnDuty() then TaxiClient.RefreshProfile() end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and TaxiClient.State.inMission and TaxiClient.CancelMission then
        TaxiClient.CancelMission()
    end
end)

local serviceMenuOpen = false
local serviceMenu = RageUI.CreateMenu("Service Taxi", "Annonces & Facturation")
serviceMenu.Display.Header = true
serviceMenu.Closed = function() serviceMenuOpen = false end

local serviceStatus = false

function OpenTaxiServiceMenu()
    if serviceMenuOpen then
        serviceMenuOpen = false
        RageUI.Visible(serviceMenu, false)
        return
    end

    serviceMenuOpen = true
    RageUI.Visible(serviceMenu, true)

    Citizen.CreateThread(function()
        while serviceMenuOpen do
            RageUI.IsVisible(serviceMenu, function()
                RageUI.Checkbox("Prendre mon service", "Vous rend disponible pour les appels taxi des joueurs.", serviceStatus, {}, {
                    onChecked = function()
                        serviceStatus = true
                        TriggerServerEvent("null:taxi:setService", true)
                        if ESX and ESX.ShowNotification then
                            ESX.ShowNotification("~g~Service taxi pris~s~ — vous recevrez les appels clients")
                        end
                    end,
                    onUnChecked = function()
                        serviceStatus = false
                        TriggerServerEvent("null:taxi:setService", false)
                        if ESX and ESX.ShowNotification then
                            ESX.ShowNotification("~o~Service taxi quitté")
                        end
                    end,
                })

                RageUI.Line()

                if serviceStatus == true then

                    RageUI.Checkbox("Status de l'entreprise", "Affiche le statut de l'entreprise.", entreprisestatus, {}, {
                    onChecked = function()
                        entreprisestatus = true 
                        TriggerServerEvent("vsociety:updateSocietyStatus", "taxi", true)
                    end,
                    onUnChecked = function()
                        entreprisestatus = false
                        TriggerServerEvent("vsociety:updateSocietyStatus", "taxi", false)
                    end,
                })

                RageUI.Button("Montrer mon badge", nil, {}, true, {
                    onSelected = function()
                        if ShowJobBadge then ShowJobBadge(ESX.PlayerData.job.name) end
                    end,
                })

                RageUI.Button("Facturer un client proche", "Envoie une facture au joueur le plus proche.", {}, true, {
                    onSelected = function()
                        local closest, dist = ESX.Game.GetClosestPlayer()
                        if closest ~= -1 and dist <= 3.0 then
                            local amount = null.fct.input("Montant de la facture")
                            if amount and tonumber(amount) and tonumber(amount) > 0 then
                                TriggerServerEvent("Core:AddBilling", GetPlayerServerId(closest), tonumber(amount), ESX.PlayerData.job.name)
                                ESX.ShowNotification("~g~Facture envoyée")
                            end
                        else
                            ESX.ShowNotification("~r~Aucun joueur à proximité")
                        end
                    end,
                })

                RageUI.Button("Ouvrir le tableau de bord", "Affiche les missions disponibles.", { RightLabel = "→" }, true, {
                    onSelected = function()
                        RageUI.CloseAll()
                        TaxiClient.OpenBoard()
                    end,
                })
            end

            end)
            Wait(0)
        end
    end)
end

local function pickPickupCoords()
    return CFG.SpawnPoints[math.random(1, #CFG.SpawnPoints)]
end

local function pickDestinationCoords(exclude)
    for _ = 1, 12 do
        local pos = CFG.SpawnPoints[math.random(1, #CFG.SpawnPoints)]
        if not exclude or #(pos - exclude) > 200.0 then return pos end
    end
    return CFG.SpawnPoints[math.random(1, #CFG.SpawnPoints)]
end

local function pickPed(category)
    local list = CFG.Peds[category] or CFG.Peds.standard
    return list[math.random(1, #list)]
end

local function pickDialogue(key)
    local list = CFG.Dialogues[key]
    if not list or #list == 0 then return nil end
    return list[math.random(1, #list)]
end

-- ============================================================
-- Marker / Blip helpers
-- ============================================================
local function setBlip(pos, sprite, color, label)
    local blip = AddBlipForCoord(pos.x, pos.y, pos.z)
    SetBlipSprite(blip, sprite or 1)
    SetBlipColour(blip, color or 5)
    SetBlipScale(blip, 1.1)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, color or 5)
    if label then
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(label)
        EndTextCommandSetBlipName(blip)
    end
    return blip
end

local function clearBlip(blip)
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
end

-- ============================================================
-- Création du ped client
-- ============================================================
local function spawnClientPed(coords, modelName)
    if not TaxiClient.requestModel(modelName) then return nil end
    local hash = GetHashKey(modelName)
    local ped  = CreatePed(1, hash, coords.x, coords.y, coords.z, 0.0, false, true)
    SetModelAsNoLongerNeeded(hash)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskStartScenarioInPlace(ped, "WORLD_HUMAN_STAND_IMPATIENT", 0, true)
    return ped
end

local function makePedEnter(ped, vehicle)
    ClearPedTasksImmediately(ped)
    TaskEnterVehicle(ped, vehicle, 12000, 2, 2.0, 1, 0)
end

local function makePedLeave(ped)
    TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 0)
    Citizen.SetTimeout(4500, function()
        if DoesEntityExist(ped) then TaskWanderStandard(ped, 99999999.0, 10) end
    end)
end

-- ============================================================
-- Tracking d'humeur (mood) pendant la course
-- ============================================================
local function startMoodTracker()
    local s = TaxiClient.State
    local M = CFG.Economy.Mood
    s.moodPercent = M.StartPercent

    Citizen.CreateThread(function()
        local lastSpeed   = 0.0
        local lastBody    = nil
        local lastEngine  = nil
        while s.inMission and s.step == "inRide" do
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh and veh ~= 0 then
                local speedMs   = GetEntitySpeed(veh)
                local speedKmh  = speedMs * 3.6
                local bodyHp    = GetVehicleBodyHealth(veh)
                local engineHp  = GetVehicleEngineHealth(veh)

                -- Détection collision via baisse soudaine de santé carrosserie/moteur
                if lastBody and lastEngine then
                    local bodyDrop   = lastBody - bodyHp
                    local engineDrop = lastEngine - engineHp
                    if bodyDrop > 25 or engineDrop > 25 then
                        s.moodPercent = math.max(M.MinPercent, s.moodPercent - M.CrashPenalty)
                    end
                end
                lastBody, lastEngine = bodyHp, engineHp

                -- Freinage brusque (décélération > 8 m/s sur 1 s)
                if (lastSpeed - speedMs) > 8.0 then
                    s.moodPercent = math.max(M.MinPercent, s.moodPercent - M.HardBrakePenalty)
                end

                -- Excès de vitesse
                if speedKmh > M.SpeedLimit then
                    s.moodPercent = math.max(M.MinPercent, s.moodPercent - M.OverspeedPenalty)
                end

                -- Hors route prolongé
                local c = GetEntityCoords(veh)
                if not IsPointOnRoad(c.x, c.y, c.z, veh) then
                    s.moodPercent = math.max(M.MinPercent, s.moodPercent - M.OffroadPenalty)
                end

                -- Bonus de conduite douce
                if speedKmh > 5 and speedKmh < M.SpeedLimit then
                    s.moodPercent = math.min(M.MaxPercent, s.moodPercent + M.SmoothBonus * 0.2)
                end

                lastSpeed = speedMs
            end
            Wait(1000)
        end
    end)
end

-- ============================================================
-- Tracking de distance pendant la course
-- ============================================================
local function startDistanceTracker()
    local s = TaxiClient.State
    s.distanceMeters = 0
    s.startCoords = GetEntityCoords(PlayerPedId())

    Citizen.CreateThread(function()
        local last = s.startCoords
        while s.inMission and s.step == "inRide" do
            local now = GetEntityCoords(PlayerPedId())
            local d = #(now - last)
            if d > 0.5 then -- ignore le bruit
                s.distanceMeters = s.distanceMeters + d
                s.fareEstimate   = CFG.Economy.BaseFare
                                 + (s.distanceMeters / 1000.0) * CFG.Economy.PerKilometer
                last = now
            end
            TaxiClient.PushHUD()
            Wait(1500)
        end
    end)
end

-- ============================================================
-- Gestion de fin de mission
-- ============================================================
local function clearMissionState(keepBlips)
    local s = TaxiClient.State
    if not keepBlips then
        clearBlip(s.pickupBlip); s.pickupBlip = nil
        clearBlip(s.destBlip);   s.destBlip   = nil
    end
    if s.pedEntity and DoesEntityExist(s.pedEntity) then
        SetEntityAsNoLongerNeeded(s.pedEntity)
    end
    s.inMission   = false
    s.mission     = nil
    s.missionKey  = nil
    s.step        = "idle"
    s.stops       = {}
    s.stopIndex   = 1
    s.pedEntity   = nil
    s.pickupCoords= nil
    s.startTime   = 0
    s.distanceMeters = 0
    s.fareEstimate   = 0
    TaxiClient.CloseHUD()
end

function TaxiClient.CancelMission()
    if not TaxiClient.State.inMission then return end
    TriggerServerEvent('null:taxi:cancelMission')
    TaxiClient.notify("~r~Course annulée")
    clearMissionState(false)
end

-- ============================================================
-- Boucle d'attente "approche"
-- ============================================================
local function waitForApproach(getCoords, label, threshold)
    threshold = threshold or 8.0
    local s = TaxiClient.State
    while s.inMission do
        local pCoords = GetEntityCoords(PlayerPedId())
        local target  = getCoords()
        local d = #(pCoords - target)
        if d <= threshold then return true end
        if (GetGameTimer() % 5000) < 50 and label then
            TaxiClient.notify("~b~"..label)
        end
        Wait(700)
    end
    return false
end

-- ============================================================
-- Construction des arrêts selon le type
-- ============================================================
local function buildStops(missionKey, pickup)
    local stops = {}
    local mission = CFG.Missions[missionKey]

    if missionKey == "tour" then
        -- 3 spots touristiques aléatoires + retour vers un quartier
        local pool = {}
        for _, p in ipairs(CFG.TourPoints) do pool[#pool + 1] = p end
        for _ = 1, math.min(3, #pool) do
            local idx = math.random(1, #pool)
            stops[#stops + 1] = { pos = pool[idx].pos, label = pool[idx].label }
            table.remove(pool, idx)
        end
    elseif missionKey == "medical" and mission.destinationPreset then
        stops[1] = { pos = mission.destinationPreset, label = "Hôpital Pillbox Hill" }
    else
        stops[1] = { pos = pickDestinationCoords(pickup), label = "Destination" }
    end

    return stops
end

-- ============================================================
-- Démarrage générique d'une mission
-- ============================================================
function TaxiClient.StartMission(missionKey)
    if TaxiClient.State.inMission then
        TaxiClient.notify("~r~Une course est déjà en cours")
        return
    end
    if not TaxiClient.isOnDuty() then
        TaxiClient.notify("~r~Vous n'êtes pas en service taxi")
        return
    end

    -- Validation côté serveur (rang, etc.)
    ESX.TriggerServerCallback('null:taxi:startMission', function(ok, missionData)
        if not ok then return end

        local s = TaxiClient.State
        local mission = CFG.Missions[missionKey]
        s.inMission   = true
        s.mission     = mission
        s.missionKey  = missionKey
        s.step        = "toPickup"
        s.startTime   = GetGameTimer()
        s.moodPercent = CFG.Economy.Mood.StartPercent
        s.distanceMeters = 0

        -- Choix du pickup, du ped, des stops
        s.pickupCoords = pickPickupCoords()
        s.stops        = buildStops(missionKey, s.pickupCoords)
        s.stopIndex    = 1

        local category = (CFG.Peds[missionKey] and missionKey) or "standard"
        local pedModel = pickPed(category)

        -- Blip pickup
        s.pickupBlip = setBlip(s.pickupCoords, 280, 5, "Client à récupérer")
        TaxiClient.OpenHUD()
        PlaySoundFrontend(-1, "Menu_Accept", "Phone_SoundSet_Default", 1)
        TaxiClient.notify(("~b~Nouvelle course~s~ — ~y~%s"):format(mission.label or ""))

        Citizen.CreateThread(function()
            -- 1) Approche du pickup
            local reached = waitForApproach(function() return s.pickupCoords end, "Rendez-vous au point GPS", 35.0)
            if not reached or not s.inMission then return end

            -- 2) Spawn du ped client
            s.step      = "atPickup"
            s.pedEntity = spawnClientPed(s.pickupCoords, pedModel)
            clearBlip(s.pickupBlip); s.pickupBlip = nil
            TaxiClient.PushHUD()

            if not s.pedEntity then
                TaxiClient.notify("~r~Le client est introuvable, course annulée")
                TriggerServerEvent('null:taxi:cancelMission')
                clearMissionState(false)
                return
            end

            -- Approche fine + dialogue
            reached = waitForApproach(function() return GetEntityCoords(s.pedEntity) end, "Rapprochez-vous du client", 8.0)
            if not reached or not s.inMission then return end

            -- Dialogue selon type
            local pickupKey = "onPickup"
            if missionKey == "vip"     then pickupKey = "vipPickup"
            elseif missionKey == "express" then pickupKey = "expressPickup"
            elseif missionKey == "medical" then pickupKey = "medicalPickup" end
            local dialogue = pickDialogue(pickupKey) or pickDialogue("onPickup")
            if dialogue then
                ESX.Game.Utils.DrawText3D(GetEntityCoords(s.pedEntity) + vector3(0, 0, 1.0), dialogue, 0.45, 4)
            end

            -- 3) Faire monter le ped
            local veh = GetVehiclePedIsIn(PlayerPedId(), false)
            if veh and veh ~= 0 then
                makePedEnter(s.pedEntity, veh)
            end

            local enterTimeout = GetGameTimer() + 15000
            while s.inMission and not IsPedInAnyVehicle(s.pedEntity, false) and GetGameTimer() < enterTimeout do
                Wait(300)
            end

            if not IsPedInAnyVehicle(s.pedEntity, false) then
                TaxiClient.notify("~r~Le client a renoncé")
                TriggerServerEvent('null:taxi:cancelMission')
                clearMissionState(false)
                return
            end

            -- 4) En course
            s.step = "inRide"
            s.startTime = GetGameTimer()
            startMoodTracker()
            startDistanceTracker()

            -- Blip premier arrêt
            local current = s.stops[s.stopIndex]
            s.destBlip = setBlip(current.pos, 1, 2, current.label or "Destination")
            TaxiClient.PushHUD()

            -- Boucle des arrêts
            while s.inMission and s.stopIndex <= #s.stops do
                current = s.stops[s.stopIndex]
                clearBlip(s.destBlip)
                s.destBlip = setBlip(current.pos, 1, 2, current.label or "Destination")
                TaxiClient.PushHUD()

                -- Attente arrivée
                local arrived = false
                while s.inMission and not arrived do
                    local pCoords = GetEntityCoords(PlayerPedId())
                    if #(pCoords - current.pos) < 12.0 then arrived = true end
                    -- Vérification : ped est-il toujours dans le taxi ?
                    if not IsPedInAnyVehicle(s.pedEntity, false) then
                        TaxiClient.notify("~r~Le client est sorti du véhicule prématurément !")
                        s.moodPercent = math.max(0, s.moodPercent - 30)
                        arrived = true
                    end
                    Wait(700)
                end

                if not s.inMission then return end

                -- Si plusieurs stops (tour), petit arrêt à chaque spot
                if #s.stops > 1 and s.stopIndex < #s.stops then
                    -- Attente que le véhicule s'arrête
                    local stopCheck = GetGameTimer() + 10000
                    while s.inMission and GetGameTimer() < stopCheck do
                        local v = GetVehiclePedIsIn(PlayerPedId(), false)
                        if v ~= 0 and GetEntitySpeed(v) * 3.6 < 5 then
                            TaxiClient.notify("~b~Pause au "..(current.label or "spot")..".")
                            Wait(3500)
                            break
                        end
                        Wait(500)
                    end
                end

                s.stopIndex = s.stopIndex + 1
                TaxiClient.PushHUD()
            end

            if not s.inMission then return end

            -- 5) Attendre que le véhicule soit à l'arrêt
            s.step = "atDestination"
            TaxiClient.PushHUD()
            local stopWait = GetGameTimer() + 15000
            while s.inMission and GetGameTimer() < stopWait do
                local v = GetVehiclePedIsIn(PlayerPedId(), false)
                if v ~= 0 and GetEntitySpeed(v) * 3.6 < 3 then break end
                Wait(400)
            end

            -- 6) Le client descend
            if DoesEntityExist(s.pedEntity) then makePedLeave(s.pedEntity) end

            -- Dialogue de fin
            local farewellKey = "onDropoff"
            if s.moodPercent >= 75 then farewellKey = "moodHighEnd"
            elseif s.moodPercent < 35 then farewellKey = "moodLowEnd" end
            local farewell = pickDialogue(farewellKey)
            if farewell and DoesEntityExist(s.pedEntity) then
                ESX.Game.Utils.DrawText3D(GetEntityCoords(s.pedEntity) + vector3(0, 0, 1.0), farewell, 0.45, 4)
            end

            -- 7) Paiement + XP
            local elapsed = (GetGameTimer() - s.startTime) / 1000
            ESX.TriggerServerCallback('null:taxi:finishMission', function(ok, result)
                if ok and result then
                    PlaySoundFrontend(-1, "Mission_Pass_Notify", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 1)
                    local msg = ("~g~+%d$~s~ (course %d$ + pourboire ~y~%d$~s~)\nXP: ~b~+%d~s~"):format(
                        result.total or 0, result.fare or 0, result.tip or 0, result.xpGain or 0
                    )
                    if result.dailyBonus and result.dailyBonus > 0 then
                        msg = msg .. ("\n~o~Bonus journalier : +%d$"):format(result.dailyBonus)
                    end
                    if result.rankUp then
                        msg = msg .. ("\n~p~⬆ Promotion : %s"):format(result.rank.label or "")
                        PlaySoundFrontend(-1, "RANK_UP", "HUD_AWARDS", 1)
                    end
                    TaxiClient.notify(msg)
                    SendNUIMessage({
                        action = 'taxiHUD:summary',
                        data = {
                            total = result.total, fare = result.fare, tip = result.tip,
                            xpGain = result.xpGain, rankUp = result.rankUp,
                            rank = result.rank, dailyBonus = result.dailyBonus,
                            todayRides = result.todayRides, mood = math.floor(s.moodPercent),
                        }
                    })
                end
                Wait(4500)
                clearMissionState(false)
                TaxiClient.RefreshProfile()
            end, {
                distanceMeters = s.distanceMeters,
                moodPercent    = s.moodPercent,
                elapsedSec     = elapsed,
            })
        end)
    end, missionKey)
end

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

local menuGarageOpen = false
local menuGarage = RageUI.CreateMenu("Garage Taxi", "Choisissez votre véhicule")
menuGarage.Display.Header = true
menuGarage.Closed = function() menuGarageOpen = false end

local menuRangerOpen = false
local menuRanger = RageUI.CreateMenu("Ranger Taxi", "Restitution du véhicule")
menuRanger.Display.Header = true
menuRanger.Closed = function() menuRangerOpen = false end

-- ============================================================
-- Helpers
-- ============================================================
local function rankIndex(key)
    for i, r in ipairs(CFG.Ranks) do if r.key == key then return i end end
    return 1
end

local function currentRankIdx()
    if TaxiClient and TaxiClient.State and TaxiClient.State.profile and TaxiClient.State.profile.rank then
        return rankIndex(TaxiClient.State.profile.rank.key)
    end
    return 1
end

local function spawnTaxiVehicle(modelName)
    local hash = GetHashKey(modelName)
    if not IsModelInCdimage(hash) then
        ESX.ShowNotification("~r~Modèle inconnu : "..modelName)
        return
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do Wait(50) end
    if not HasModelLoaded(hash) then
        ESX.ShowNotification("~r~Impossible de charger le modèle")
        return
    end
    local s = CFG.Positions.Spawn
    local veh = CreateVehicle(hash, s.x, s.y, s.z, s.w or 0.0, true, true)
    SetVehicleNumberPlateText(veh, "TAXI"..math.random(100, 999))
    SetVehicleEngineOn(veh, true, true, false)
    SetEntityAsMissionEntity(veh, true, true)
    SetModelAsNoLongerNeeded(hash)
    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    ESX.ShowNotification("~g~Véhicule prêt — bonne course !")
end

-- ============================================================
-- Menu garage (sortir un véhicule)
-- ============================================================
function OpenGarageTaxi()
    if menuGarageOpen then
        menuGarageOpen = false
        RageUI.Visible(menuGarage, false)
        return
    end

    -- Refresh profile pour avoir le rang à jour
    if TaxiClient and TaxiClient.RefreshProfile then TaxiClient.RefreshProfile() end

    menuGarageOpen = true
    RageUI.Visible(menuGarage, true)

    Citizen.CreateThread(function()
        while menuGarageOpen do
            RageUI.IsVisible(menuGarage, function()
                local myRank = currentRankIdx()
                RageUI.Separator(("Rang actuel : ~b~%s"):format(
                    TaxiClient.State.profile and TaxiClient.State.profile.rank
                    and TaxiClient.State.profile.rank.label or "Apprenti"
                ))

                for _, v in ipairs(CFG.Vehicles) do
                    local req = rankIndex(v.rankReq or "novice")
                    local unlocked = myRank >= req
                    local right = unlocked and "Disponible" or ("Rang requis : "..(CFG.Ranks[req].label or ""))
                    RageUI.Button(v.label, nil, { RightLabel = right }, unlocked, {
                        onSelected = function()
                            if not unlocked then return end
                            RageUI.CloseAll()
                            spawnTaxiVehicle(v.model)
                        end,
                    })
                end
            end)
            Wait(0)
        end
    end)
end

-- ============================================================
-- Menu ranger
-- ============================================================
function OpenRangerTaxi()
    if menuRangerOpen then
        menuRangerOpen = false
        RageUI.Visible(menuRanger, false)
        return
    end

    menuRangerOpen = true
    RageUI.Visible(menuRanger, true)

    Citizen.CreateThread(function()
        while menuRangerOpen do
            RageUI.IsVisible(menuRanger, function()
                RageUI.Button("Ranger mon véhicule", "Le véhicule actuel sera supprimé.", { RightLabel = "" }, true, {
                    onSelected = function()
                        local ped = PlayerPedId()
                        if IsPedSittingInAnyVehicle(ped) then
                            local veh = GetVehiclePedIsIn(ped, false)
                            if GetPedInVehicleSeat(veh, -1) == ped then
                                ESX.ShowNotification("~g~Véhicule rangé au garage")
                                ESX.Game.DeleteVehicle(veh)
                            else
                                ESX.ShowNotification("~r~Vous devez être au volant")
                            end
                        else
                            local veh = ESX.Game.GetVehicleInDirection()
                            if DoesEntityExist(veh) then
                                ESX.ShowNotification("~g~Véhicule rangé au garage")
                                ESX.Game.DeleteVehicle(veh)
                            else
                                ESX.ShowNotification("~r~Aucun véhicule à proximité")
                            end
                        end
                        RageUI.CloseAll()
                    end,
                })
            end)
            Wait(0)
        end
    end)
end

-- ============================================================
-- Markers
-- ============================================================
Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    null.data.markers.register("taxi_garage", {
        Position = CFG.Positions.Garage,
        Public   = false,
        Job      = "taxi",
        Action   = function() OpenGarageTaxi() end,
    })
    null.data.markers.register("taxi_ranger", {
        Position = CFG.Positions.Ranger,
        Public   = false,
        Job      = "taxi",
        Action   = function() OpenRangerTaxi() end,
    })
end)

