-- ============================================================
--  Taxi — Missions
--  5 types : standard · vip · tour · express · medical
--  Scènes ped, dialogues, suivi humeur, suivi distance.
-- ============================================================

local CFG = Config.Taxi

-- ============================================================
-- Sélection des points & ped
-- ============================================================
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
