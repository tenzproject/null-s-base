-- ============================================================================
-- GOFAST V2 - Client Module
-- ============================================================================

local GF = {}
GF.active = false
GF.missionData = nil
GF.vehicle = nil
GF.blipDelivery = nil
GF.blipPickup = nil
GF.pickupPed = nil
GF.deliveryPed = nil
GF.InAnim = false
GF.lastDriveByTime = 0

-- ============================================================================
-- HELPERS
-- ============================================================================
local function dist(a, b)
    return #(a - b)
end

local function loadModel(model)
    local hash = type(model) == "string" and GetHashKey(model) or model
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    return hash
end

-- ============================================================================
-- BLIP MANAGEMENT
-- ============================================================================
function GF.CreateBlip(coords, sprite, color, label, route)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipScale(blip, 0.85)
    SetBlipColour(blip, color)
    SetBlipAlpha(blip, 200)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
    if route then SetBlipRoute(blip, true) end
    PulseBlip(blip)
    return blip
end

function GF.RemoveBlips()
    if GF.blipDelivery then RemoveBlip(GF.blipDelivery) GF.blipDelivery = nil end
    if GF.blipPickup then RemoveBlip(GF.blipPickup) GF.blipPickup = nil end
end

-- ============================================================================
-- ANIMATION HELPER
-- ============================================================================
function GF.PlayGiveTakeAnim(playerPed, targetPed)
    GF.InAnim = true
    local playerCoords = GetEntityCoords(playerPed)
    local pedCoords = GetEntityCoords(targetPed)
    local pedWasFrozen = IsEntityPositionFrozen(targetPed)
    if pedWasFrozen then
        FreezeEntityPosition(targetPed, false)
    end

    TaskTurnPedToFaceCoord(playerPed, pedCoords.x, pedCoords.y, pedCoords.z, 1000)
    TaskTurnPedToFaceCoord(targetPed, playerCoords.x, playerCoords.y, playerCoords.z, 1000)

    Wait(1000)

    if pedWasFrozen then
        FreezeEntityPosition(targetPed, true)
    end

    local dict, anim = "mp_common", "givetake1_a"
    ESX.Streaming.RequestAnimDict(dict)
    TaskPlayAnim(playerPed, dict, anim, -1.0, -1.0, 3000, 0, 0, true, true, true)
    TaskPlayAnim(targetPed, dict, anim, -1.0, -1.0, 3000, 0, 0, true, true, true)
    Wait(3000)
    GF.InAnim = false
end

-- ============================================================================
-- MISSION START (called after server responds with mission data)
-- ============================================================================
RegisterNetEvent("Null:gofast:missionResponse")
AddEventHandler("Null:gofast:missionResponse", function(data)
    if data.error then
        if data.error == "BLACKLISTED" then
            ESX.ShowNotification("~r~[CrimeNet] Tu es blacklisté du réseau.")
        elseif data.error == "COOLDOWN" then
            local mins = math.ceil((data.remaining or 0) / 60)
            ESX.ShowNotification("~r~[CrimeNet] Cooldown actif : " .. mins .. " min restantes.")
        elseif data.error == "ALREADY_ACTIVE" then
            ESX.ShowNotification("~r~[CrimeNet] Tu as déjà une mission en cours.")
        elseif data.error == "NO_GANG" then
            ESX.ShowNotification("~r~[CrimeNet] Pas de groupe illégal pour le mode crew.")
        elseif data.error == "NOT_ENOUGH_CREW" then
            ESX.ShowNotification("~r~[CrimeNet] Membres en ligne insuffisants : " .. (data.online or 0) .. "/" .. (data.required or 0))
        end
        return
    end

    if data.success and data.mission then
        GF.missionData = data.mission
        GF.active = true
        GF.StartPickupPhase()
    end
end)

-- ============================================================================
-- PICKUP PHASE (realistic)
-- ============================================================================
function GF.StartPickupPhase()
    local mission = GF.missionData
    if not mission then return end

    local pickup = mission.pickup
    GF.blipPickup = GF.CreateBlip(pickup.coords, 478, 5, "GoFast - Pickup", true)

    ESX.ShowAdvancedNotification("CRIMENET", "~r~MISSION", "Rendez-vous au point de pickup : " .. pickup.label, "CHAR_MULTIPLAYER")

    -- Pre-spawn the mission vehicle (locked, with cargo already in trunk via server)
    local vehHash = loadModel(mission.vehicle)
    local vehCoords = pickup.coords
    local veh = CreateVehicle(vehHash, vehCoords.x, vehCoords.y, vehCoords.z, vehCoords.w, true, true)
    SetVehicleNumberPlateText(veh, mission.plate)
    SetVehicleDoorsLocked(veh, 2) -- Locked
    SetVehicleEnginePowerMultiplier(veh, 30.0)
    FreezeEntityPosition(veh, true)
    SetModelAsNoLongerNeeded(vehHash)
    GF.vehicle = veh

    -- Spawn contact NPC near the vehicle
    local pedModel = Config.GoFast.PedModels[math.random(1, #Config.GoFast.PedModels)]
    local hash = loadModel(pedModel)
    local pedX = vehCoords.x + 2.0 * math.cos(math.rad(vehCoords.w + 90))
    local pedY = vehCoords.y + 2.0 * math.sin(math.rad(vehCoords.w + 90))
    GF.pickupPed = CreatePed(4, hash, pedX, pedY, vehCoords.z - 1.0, vehCoords.w + 180.0, false, true)
    SetBlockingOfNonTemporaryEvents(GF.pickupPed, true)
    FreezeEntityPosition(GF.pickupPed, true)
    SetEntityInvincible(GF.pickupPed, true)
    SetModelAsNoLongerNeeded(hash)

    -- Wait for player to approach NPC and interact
    Citizen.CreateThread(function()
        local keysGiven = false
        while GF.active and GF.missionData and not keysGiven do
            local sleep = 500
            local playerCoords = GetEntityCoords(PlayerPedId())
            local d = dist(playerCoords, vector3(pedX, pedY, vehCoords.z))
            if d < 20.0 then
                sleep = 5
                if d < 2.5 and not GF.InAnim then
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour récupérer les clés")
                    if IsControlJustPressed(0, 51) then
                        keysGiven = true
                        GF.PickupKeyExchange()
                    end
                end
            end
            Wait(sleep)
        end
    end)
end

-- ============================================================================
-- PICKUP KEY EXCHANGE (animation + give temp keys)
-- ============================================================================
function GF.PickupKeyExchange()
    local mission = GF.missionData
    if not mission then return end

    local playerPed = PlayerPedId()

    -- Play key exchange animation
    GF.PlayGiveTakeAnim(playerPed, GF.pickupPed)

    -- Give temporary keys via the vehicle key system
    TriggerServerEvent('null:gofast:pickupkey', mission.plate)

    ESX.ShowNotification("~g~Vous avez reçu les clés du véhicule.")
    PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 1)

    -- Unlock vehicle and unfreeze it
    if GF.vehicle and DoesEntityExist(GF.vehicle) then
        SetVehicleDoorsLocked(GF.vehicle, 1) -- Unlocked
        FreezeEntityPosition(GF.vehicle, false)
    end

    -- Remove pickup blip
    if GF.blipPickup then RemoveBlip(GF.blipPickup) GF.blipPickup = nil end

    -- Remove pickup NPC (walks away then despawns)
    if GF.pickupPed and DoesEntityExist(GF.pickupPed) then
        FreezeEntityPosition(GF.pickupPed, false)
        SetEntityInvincible(GF.pickupPed, false)
        TaskWanderStandard(GF.pickupPed, 10.0, 10)
        local ped = GF.pickupPed
        GF.pickupPed = nil
        Citizen.SetTimeout(15000, function()
            if DoesEntityExist(ped) then DeleteEntity(ped) end
        end)
    end

    -- Set delivery blip
    local delivery = mission.delivery
    GF.blipDelivery = GF.CreateBlip(delivery.coords, 162, 1, "GoFast - Livraison", true)

    ESX.ShowNotification("~r~GOFAST\n~w~Livre le véhicule au point de livraison !\nLa marchandise est dans le coffre.\nPosition indiquée sur ton GPS.")

    -- Tell server mission is active
    TriggerServerEvent("Null:gofast:start")

    -- Monitor delivery
    GF.MonitorDelivery()
end

-- ============================================================================
-- DELIVERY MONITORING
-- ============================================================================
function GF.MonitorDelivery()
    local mission = GF.missionData
    if not mission then return end

    -- Spawn delivery NPC at delivery point
    local delivery = mission.delivery
    local pedModel = Config.GoFast.PedModels[math.random(1, #Config.GoFast.PedModels)]
    local hash = loadModel(pedModel)
    GF.deliveryPed = CreatePed(4, hash, delivery.coords.x, delivery.coords.y, delivery.coords.z - 1.0, delivery.coords.w, false, true)
    SetBlockingOfNonTemporaryEvents(GF.deliveryPed, true)
    FreezeEntityPosition(GF.deliveryPed, true)
    SetEntityInvincible(GF.deliveryPed, true)
    SetModelAsNoLongerNeeded(hash)

    Citizen.CreateThread(function()
        while GF.active and GF.vehicle do
            local sleep = 500
            local playerCoords = GetEntityCoords(PlayerPedId())
            local d = dist(playerCoords, vector3(delivery.coords.x, delivery.coords.y, delivery.coords.z))

            if d < 30.0 then
                sleep = 5
                -- Player must exit vehicle first
                local inVehicle = IsPedSittingInAnyVehicle(PlayerPedId())
                if d < 5.0 and not inVehicle and not GF.InAnim then
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour remettre les clés")
                    if IsControlJustPressed(0, 51) then
                        GF.DeliverySequence()
                        return
                    end
                elseif d < 5.0 and inVehicle then
                    ESX.ShowHelpNotification("~r~Sortez du véhicule pour effectuer la livraison")
                end
            end

            -- Check if vehicle is destroyed
            if GF.vehicle and DoesEntityExist(GF.vehicle) and IsEntityDead(GF.vehicle) then
                GF.FailMission()
                return
            end

            Wait(sleep)
        end
    end)
end

-- ============================================================================
-- DELIVERY SEQUENCE (realistic: key exchange, cargo check, reward or shoot)
-- ============================================================================
function GF.DeliverySequence()
    if not GF.active or not GF.vehicle or not GF.deliveryPed then return end

    local mission = GF.missionData
    if not mission then return end

    local playerPed = PlayerPedId()
    local deliveryPed = GF.deliveryPed
    local vehicle = GF.vehicle

    -- Step 1: Key exchange animation (player gives keys to NPC)
    ESX.ShowAdvancedNotification("GOFAST", "~y~LIVRAISON", "Remise des clés en cours...", "CHAR_MULTIPLAYER")
    GF.PlayGiveTakeAnim(playerPed, deliveryPed)

    -- Step 2: NPC walks to vehicle to check cargo
    ESX.ShowAdvancedNotification("GOFAST", "~y~VÉRIFICATION", "L'acheteur vérifie la marchandise...", "CHAR_MULTIPLAYER")
    FreezeEntityPosition(deliveryPed, false)

    local vehCoords = GetEntityCoords(vehicle)
    -- NPC walks to the rear of the vehicle (trunk)
    local vehHeading = GetEntityHeading(vehicle)
    local trunkX = vehCoords.x - 3.0 * math.cos(math.rad(vehHeading))
    local trunkY = vehCoords.y - 3.0 * math.sin(math.rad(vehHeading))
    TaskGoStraightToCoord(deliveryPed, trunkX, trunkY, vehCoords.z, 1.0, 5000, vehHeading + 180.0, 0.5)
    Wait(4000)

    -- Get engine health before we process anything
    local engineHealth = GetVehicleEngineHealth(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)

    -- Step 3: Server verifies cargo and sends result
    TriggerServerEvent("Null:gofast:complete", engineHealth, plate)

    -- Wait for server result
    GF.awaitingResult = true
    local resultData = nil
    local handlerRef = AddEventHandler("Null:gofast:result", function(data)
        resultData = data
        GF.awaitingResult = false
    end)

    -- Wait up to 10 seconds for server response
    local waitTime = 0
    while GF.awaitingResult and waitTime < 10000 do
        Wait(100)
        waitTime = waitTime + 100
    end
    RemoveEventHandler(handlerRef)

    if not resultData then
        -- Timeout - just cleanup
        ESX.ShowAdvancedNotification("GOFAST", "~r~ERREUR", "Connexion perdue.", "CHAR_MULTIPLAYER")
        GF.CleanupDelivery()
        return
    end

    if resultData.success then
        -- Step 4a: Cargo complete - NPC gives money animation
        ESX.ShowAdvancedNotification("GOFAST", "~g~CARGO VÉRIFIÉ", "Marchandise complète. Paiement en cours...", "CHAR_MULTIPLAYER")
        Wait(1000)

        -- NPC walks back to player for money exchange
        local playerPos = GetEntityCoords(playerPed)
        TaskGoStraightToCoord(deliveryPed, playerPos.x, playerPos.y, playerPos.z, 1.0, 4000, 0.0, 0.5)
        Wait(3000)

        -- Money exchange animation
        GF.PlayGiveTakeAnim(deliveryPed, playerPed)

        PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 1)

        local msg = "Récompense : ~g~" .. resultData.payment .. "$~w~\nXP : +" .. resultData.xpGain
        if resultData.speedBonus then
            msg = msg .. "\n~y~BONUS RAPIDITÉ !"
        end
        ESX.ShowAdvancedNotification("CRIMENET", "~g~MISSION TERMINÉE", msg, "CHAR_MULTIPLAYER")

        GF.CleanupDelivery()
    else
        -- Step 4b: Cargo missing - NPC attacks
        if resultData.cargoMissing then
            ESX.ShowAdvancedNotification("GOFAST", "~r~CARGO INCOMPLET", "La marchandise est incomplète ! L'acheteur est furieux !", "CHAR_MULTIPLAYER")
            PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", 1)
            Wait(1500)

            -- NPC becomes hostile
            SetEntityInvincible(deliveryPed, false)
            FreezeEntityPosition(deliveryPed, false)
            SetBlockingOfNonTemporaryEvents(deliveryPed, false)

            -- Give weapon and attack player
            local hostileWeapons = Config.GoFast.Betrayal.hostileWeapons
            local weapon = hostileWeapons[math.random(1, #hostileWeapons)]
            GiveWeaponToPed(deliveryPed, weapon, 999, false, true)
            SetPedCombatAttributes(deliveryPed, 46, true)
            SetPedFleeAttributes(deliveryPed, 0, false)
            TaskCombatPed(deliveryPed, playerPed, 0, 16)

            -- Store ref so it gets cleaned after timeout
            local hostilePed = deliveryPed
            GF.deliveryPed = nil

            Citizen.CreateThread(function()
                local playerPed = PlayerPedId()
                local deathPos = nil
                local checkedDeath = false
                
                while DoesEntityExist(hostilePed) do
                    -- Check if player is dead (health <= 0 or IsEntityDead)
                    if not checkedDeath and (GetEntityHealth(playerPed) <= 0 or IsEntityDead(playerPed) or PlayerIsDead) then
                        deathPos = GetEntityCoords(playerPed)
                        checkedDeath = true
                        
                        -- Clear ped's combat task and make them walk to player's death position
                        ClearPedTasks(hostilePed)
                        TaskGoStraightToCoord(hostilePed, deathPos.x, deathPos.y, deathPos.z, 1.0, 10000, 0.0, 0.5)
                    end
                    
                    -- If player died and we're close enough, trigger cargo recovery
                    if deathPos then
                        local pedCoords = GetEntityCoords(hostilePed)
                        local distance = #(pedCoords - deathPos)
                        if distance <= 2.0 then
                            -- Send vehicle plate to server so it can remove remaining cargo
                            local vehicle = GF.vehicle
                            local plate = nil
                            if DoesEntityExist(vehicle) then
                                plate = GetVehicleNumberPlateText(vehicle)
                            end
                            TriggerServerEvent("null:gofast:deliveryped:takecargo", plate)
                            break
                        end
                    end
                    
                    Wait(500)
                end
            end)

            ESX.ShowAdvancedNotification("CRIMENET", "~r~MISSION ÉCHOUÉE", "XP perdue : -" .. (resultData.xpLost or 0), "CHAR_MULTIPLAYER")

            -- Cleanup hostile NPC after 60 seconds
            Citizen.SetTimeout(60000, function()
                if DoesEntityExist(hostilePed) then DeleteEntity(hostilePed) end
            end)

            GF.CleanupDelivery(true) -- skip deleting deliveryPed (now hostile)
        else
            ESX.ShowAdvancedNotification("CRIMENET", "~r~MISSION ÉCHOUÉE", "XP perdue : -" .. (resultData.xpLost or 0), "CHAR_MULTIPLAYER")
            GF.CleanupDelivery()
        end
    end
end

-- ============================================================================
-- DELIVERY CLEANUP
-- ============================================================================
function GF.CleanupDelivery(keepDeliveryPed)
    GF.RemoveBlips()

    -- Delete mission vehicle
    if GF.vehicle and DoesEntityExist(GF.vehicle) then
        ESX.Game.DeleteVehicle(GF.vehicle)
    end

    -- Delete delivery NPC (unless hostile)
    if not keepDeliveryPed and GF.deliveryPed and DoesEntityExist(GF.deliveryPed) then
        DeleteEntity(GF.deliveryPed)
    end
    GF.deliveryPed = nil

    -- Spawn return vehicle
    local delivery = GF.missionData and GF.missionData.delivery
    if delivery then
        local returnHash = loadModel("issi2")
        local retVeh = CreateVehicle(returnHash, delivery.coords.x + 3.0, delivery.coords.y, delivery.coords.z, delivery.coords.w + 180.0, true, true)
        SetVehicleNumberPlateText(retVeh, "RETOUR")
        TaskWarpPedIntoVehicle(PlayerPedId(), retVeh, -1)
        SetModelAsNoLongerNeeded(returnHash)
    end

    GF.Cleanup()
end

function GF.FailMission()
    if not GF.active then return end

    TriggerServerEvent("Null:gofast:fail")
    ESX.ShowAdvancedNotification("GOFAST", "~r~ÉCHEC", "La mission a échoué.", "CHAR_MULTIPLAYER")
    PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", 1)
    GF.Cleanup()
end

function GF.Cleanup()
    GF.RemoveBlips()
    if GF.pickupPed and DoesEntityExist(GF.pickupPed) then
        DeleteEntity(GF.pickupPed)
    end
    if GF.deliveryPed and DoesEntityExist(GF.deliveryPed) then
        DeleteEntity(GF.deliveryPed)
    end
    GF.pickupPed = nil
    GF.deliveryPed = nil
    GF.vehicle = nil
    GF.missionData = nil
    GF.active = false
    GF.InAnim = false
end

-- ============================================================================
-- MISSION RESULT (from server) - handled inline in DeliverySequence
-- Only fires for non-delivery results (fail, betrayal, etc.)
-- ============================================================================
RegisterNetEvent("Null:gofast:result")
AddEventHandler("Null:gofast:result", function(data)
    -- If awaiting result in DeliverySequence, it handles the notification
    if GF.awaitingResult then return end

    if data.success then
        local msg = "Récompense : ~g~" .. data.payment .. "$~w~\nXP : +" .. data.xpGain
        if data.speedBonus then
            msg = msg .. "\n~y~BONUS RAPIDITÉ !"
        end
        ESX.ShowAdvancedNotification("CRIMENET", "~g~MISSION TERMINÉE", msg, "CHAR_MULTIPLAYER")
    else
        ESX.ShowAdvancedNotification("CRIMENET", "~r~MISSION ÉCHOUÉE", "XP perdue : -" .. (data.xpLost or 0), "CHAR_MULTIPLAYER")
    end
end)

-- ============================================================================
-- BETRAYAL - BLACKLIST NOTIFICATION
-- ============================================================================
RegisterNetEvent("Null:gofast:betrayed")
AddEventHandler("Null:gofast:betrayed", function()
    GF.Cleanup()
    ESX.ShowAdvancedNotification("CRIMENET", "~r~TRAHISON DÉTECTÉE", "Tu as été blacklisté du réseau.\nLe cartel te cherche.", "CHAR_MULTIPLAYER")
    PlaySoundFrontend(-1, "CHECKPOINT_MISSED", "HUD_MINI_GAME_SOUNDSET", 1)
end)

-- ============================================================================
-- AMBUSH (blacklisted player lured to a point)
-- ============================================================================
RegisterNetEvent("Null:gofast:ambush")
AddEventHandler("Null:gofast:ambush", function(data)
    if not data or not data.coords then return end

    local coords = data.coords
    local peds = data.peds or {}
    local weapons = data.weapons or {}
    local count = data.pedCount or 4

    local spawnedPeds = {}
    for i = 1, count do
        local model = peds[math.random(1, #peds)]
        local hash = loadModel(model)
        local offset = vector3(math.random(-5, 5), math.random(-5, 5), 0)
        local ped = CreatePed(4, hash, coords.x + offset.x, coords.y + offset.y, coords.z - 1.0, math.random(0, 360) + 0.0, true, true)
        local weapon = weapons[math.random(1, #weapons)]
        GiveWeaponToPed(ped, weapon, 999, false, true)
        SetPedCombatAttributes(ped, 46, true)
        SetPedFleeAttributes(ped, 0, false)
        TaskCombatPed(ped, PlayerPedId(), 0, 16)
        SetModelAsNoLongerNeeded(hash)
        table.insert(spawnedPeds, ped)
    end

    -- Cleanup after 120 seconds
    Citizen.SetTimeout(120000, function()
        for _, p in ipairs(spawnedPeds) do
            if DoesEntityExist(p) then DeleteEntity(p) end
        end
    end)
end)

-- ============================================================================
-- DRIVE-BY (random hostile vehicle when blacklisted in danger zone)
-- Now scales dynamically: vehicleCount, pedsPerVehicle, vehicles[], peds[], weapons[] from server
-- ============================================================================
RegisterNetEvent("Null:gofast:driveBy")
AddEventHandler("Null:gofast:driveBy", function(data) 
    if not data then return end

    local playerCoords = GetEntityCoords(PlayerPedId())
    local peds = data.peds or {}
    local weapons = data.weapons or {}
    local vehicles = data.vehicles or { data.vehicle or "baller2" }
    local vehicleCount = data.vehicleCount or 2
    local pedsPerVehicle = data.pedsPerVehicle or math.random(2, 4)
    local spawnedVehicles = {}
    local spawnedPeds = {}
    local spawnedBlips = {}

    null.DebugPrint("[GoFast] Drive-by: " .. vehicleCount .. " véhicules, " .. pedsPerVehicle .. " PNJ/véh — tier: " .. (data.tierLabel or "legacy"))

    for v = 1, vehicleCount do
        local angle = math.rad(math.random(0, 360))
        local spawnDist = math.random(60, 100)
        local spawnPos = playerCoords + vector3(math.cos(angle) * spawnDist, math.sin(angle) * spawnDist, 0)

        local vehModel = vehicles[math.random(1, #vehicles)]
        local vehHash = loadModel(vehModel)
        local veh = CreateVehicle(vehHash, spawnPos.x, spawnPos.y, spawnPos.z + 1.0, math.random(0, 360) + 0.0, true, true)
        SetModelAsNoLongerNeeded(vehHash)
        table.insert(spawnedVehicles, veh)

        -- Add blip on vehicle
        local blip = AddBlipForEntity(veh)
        SetBlipSprite(blip, 225) -- skull icon
        SetBlipColour(blip, 1) -- red
        SetBlipScale(blip, 1.0)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("~r~Drive-By")
        EndTextCommandSetBlipName(blip)
        table.insert(spawnedBlips, blip)

        for seatIndex = -1, pedsPerVehicle - 2 do
            -- -1 = driver, 0 = front passenger, 1+ = rear
            local pedModel = peds[math.random(1, #peds)]
            local pedHash = loadModel(pedModel)
            local ped = CreatePedInsideVehicle(veh, 4, pedHash, seatIndex, true, true)
            SetModelAsNoLongerNeeded(pedHash)
            table.insert(spawnedPeds, ped)

            -- Set relationship group so they don't attack each other (all hate player, not each other)
            SetPedRelationshipGroupHash(ped, GetHashKey("HATES_PLAYER"))

            -- Give weapon to all peds
            local weapon = weapons[math.random(1, #weapons)]
            GiveWeaponToPed(ped, weapon, 999, false, true)
            SetPedCombatAttributes(ped, 46, true)
            SetPedCombatAttributes(ped, 1, true) -- Aggressive
            SetPedCombatAbility(ped, 100)
            SetPedCombatMovement(ped, 2) -- Offensive
            SetPedCombatRange(ped, 2) -- Far range preferred
            SetPedArmour(ped, pedsPerVehicle >= 4 and 100 or 50)

            if seatIndex == -1 then
                -- Driver chases player
                TaskVehicleChase(ped, PlayerPedId())
                SetTaskVehicleChaseBehaviorFlag(ped, 32, true)
                SetDriveTaskCruiseSpeed(ped, 30.0 + (vehicleCount * 2.0))
            else
                -- Passengers shoot at player
                TaskCombatPed(ped, PlayerPedId(), 0, 16)
            end
        end
    end
    
    -- Cleanup after 3 minutes
    Citizen.SetTimeout(180000, function()
        for _, blip in ipairs(spawnedBlips) do
            if DoesBlipExist(blip) then RemoveBlip(blip) end
        end
        for _, p in ipairs(spawnedPeds) do
            if DoesEntityExist(p) then DeleteEntity(p) end
        end
        for _, v in ipairs(spawnedVehicles) do
            if DoesEntityExist(v) then DeleteEntity(v) end
        end
        null.DebugPrint("[GoFast] Despawned drive-by (" .. vehicleCount .. " vehicles, " .. #spawnedPeds .. " peds)")
    end)
end)

-- ============================================================================
-- DANGER ZONE MONITOR (for blacklisted players)
-- ============================================================================
Citizen.CreateThread(function()
    while true do
        Wait(60000)
        local dangerCfg = Config.GoFast.Betrayal
        if dangerCfg and dangerCfg.dangerZone then
            local pedCoords = GetEntityCoords(PlayerPedId())
            local center = dangerCfg.dangerZone.center
            local radius = dangerCfg.dangerZone.radius
            if dist(pedCoords, center) < radius then
                local now = GetGameTimer() / 1000
                if now - GF.lastDriveByTime > (dangerCfg.driveByCooldown or 300) then
                    TriggerServerEvent("Null:gofast:dangerZoneCheck")
                    GF.lastDriveByTime = now
                end
            end
        end
    end
end)