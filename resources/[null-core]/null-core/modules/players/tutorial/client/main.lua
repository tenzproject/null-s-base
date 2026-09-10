-- ============================================================================
-- TUTORIAL SYSTEM - Client Side (v3)
-- New flow: Categories visible → Path choice → BMX → Driveschool → PED vehicle
-- → Clothing (F to continue) → Job Center → Complete
-- Uses Objectives system for in-game step guidance
-- ============================================================================

local tutorialActive = false
local tutorialStep = 'welcome'
local tutorialPath = nil
local playerFrozen = false
local vehiclePickupPed = nil
local bmxVehicle = nil
local licenseJustCompleted = false
local driveschoolClosed = false
local jobCenterCoords = nil -- Resolved by server at start
local objectivesStarted = false

-- Forward declarations
local goToStep
local openTutorialNUI
local updateObjective

-- ============================================================================
-- NUI COMMUNICATION
-- ============================================================================

openTutorialNUI = function(data)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'tutorial:open',
        data = data or {}
    })
end

local function closeTutorialNUI()
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'tutorial:close'
    })
end

-- ============================================================================
-- OBJECTIVES SYSTEM INTEGRATION
-- ============================================================================

local TUTORIAL_OBJECTIVES = {
    goto_driveschool = { stepId = "goto_driveschool", title = "Direction l'auto-école", description = "Utilisez votre BMX (TAB → utiliser) et suivez le GPS" },
    waiting_driveschool = { stepId = "waiting_driveschool", title = "Passez votre permis", description = "Arrêtez-vous et ouvrez la tablette" },
    driveschool_active = { stepId = "driveschool_active", title = "Examen en cours", description = "Suivez les instructions de l'examinateur" },
    license_done = { stepId = "license_done", title = "Permis obtenu !", description = "Ouvrez la tablette pour continuer" },
    goto_vehicle_pickup = { stepId = "goto_vehicle_pickup", title = "Récupérez votre véhicule", description = "Suivez le GPS et appuyez sur E près du mécanicien" },
    vehicle_received = { stepId = "vehicle_received", title = "Véhicule récupéré !", description = "Ouvrez la tablette pour continuer" },
    goto_clothing = { stepId = "goto_clothing", title = "Magasin de vêtements", description = "Suivez le GPS et arrêtez-vous à proximité" },
    waiting_clothing = { stepId = "waiting_clothing", title = "Personnalisez votre tenue", description = "Entrez dans le magasin via la tablette" },
    clothing_active = { stepId = "clothing_active", title = "Faites vos achats", description = "Appuyez sur F quand vous avez terminé" },
    clothing_done = { stepId = "clothing_done", title = "Tenue choisie !", description = "Ouvrez la tablette pour continuer" },
    goto_jobcenter = { stepId = "goto_jobcenter", title = "Pôle emploi", description = "Suivez le GPS et arrêtez-vous à proximité" },
    arrived_jobcenter = { stepId = "arrived_jobcenter", title = "Pôle emploi", description = "Découvrez les métiers disponibles" },
}

local function buildObjectiveSteps()
    local steps = {}
    local order = {
        "goto_driveschool", "waiting_driveschool", "driveschool_active", "license_done",
        "goto_vehicle_pickup", "vehicle_received",
        "goto_clothing", "waiting_clothing", "clothing_active", "clothing_done",
        "goto_jobcenter", "arrived_jobcenter",
    }
    for _, key in ipairs(order) do
        local obj = TUTORIAL_OBJECTIVES[key]
        table.insert(steps, { id = obj.stepId, title = obj.title, description = obj.description })
    end
    return steps
end

local function startTutorialObjectives()
    if objectivesStarted then return end
    objectivesStarted = true
    StartObjectives("tutorial", "Tutoriel", buildObjectiveSteps(), {
        color = "#44a5ff",
        startStep = 0,
        skipCommand = "skiptutorial",
    })
end

updateObjective = function(step)
    if not objectivesStarted then return end
    local obj = TUTORIAL_OBJECTIVES[step]
    if obj then
        SetObjectiveStep(obj.stepId)
    end
end

local function updateTutorialNUI(step, data)
    SendNUIMessage({
        action = 'tutorial:updateStep',
        data = {
            step = step,
            path = tutorialPath,
            extra = data or {}
        }
    })
end

-- ============================================================================
-- PLAYER CONTROL
-- ============================================================================

local function freezePlayer(freeze)
    playerFrozen = freeze
    FreezeEntityPosition(PlayerPedId(), freeze)
    if freeze then
        SetPlayerControl(PlayerId(), false, 0)
    else
        SetPlayerControl(PlayerId(), true, 0)
    end
end

-- ============================================================================
-- BMX MANAGEMENT
-- ============================================================================

local function deleteBmx()
    if bmxVehicle and DoesEntityExist(bmxVehicle) then
        DeleteEntity(bmxVehicle)
    end
    bmxVehicle = nil
end

-- ============================================================================
-- VEHICLE PICKUP PED
-- ============================================================================

local function deleteVehiclePickupPed()
    if vehiclePickupPed and DoesEntityExist(vehiclePickupPed) then
        DeleteEntity(vehiclePickupPed)
    end
    vehiclePickupPed = nil
    
    if Exist3DInteraction('tutorial_vehicle_pickup') then
        Remove3DInteraction('tutorial_vehicle_pickup')
    end
end

local function spawnVehiclePickupPed()
    deleteVehiclePickupPed()
    local cfg = Config.Tutorial.vehiclePickup
    local pedCoords = cfg.pedCoords
    local hash = GetHashKey(cfg.pedModel)
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 50 do Wait(100) t = t + 1 end
    if not HasModelLoaded(hash) then return end
    
    vehiclePickupPed = CreatePed(4, hash, pedCoords.x, pedCoords.y, pedCoords.z - 1.0, pedCoords.w or 0.0, false, true)
    SetEntityInvincible(vehiclePickupPed, true)
    SetBlockingOfNonTemporaryEvents(vehiclePickupPed, true)
    FreezeEntityPosition(vehiclePickupPed, true)
    TaskStartScenarioInPlace(vehiclePickupPed, cfg.pedScenario, 0, true)
    SetModelAsNoLongerNeeded(hash)
    
    Add3DInteraction({
        id = 'tutorial_vehicle_pickup',
        coords = vector3(pedCoords.x, pedCoords.y, pedCoords.z),
        maxDistance = cfg.interactionDistance,
        maxDistance2 = 2.5,
        text = cfg.interactionText,
        key = cfg.interactionKey,
        Action = function()
            TriggerEvent('null:tutorial:pickupVehicle')
        end,
    })
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

local function cleanupAll()
    closeTutorialNUI()
    freezePlayer(false)
    deleteBmx()
    deleteVehiclePickupPed()
    DisableTutorialEventHooks()
    tutorialActive = false
    objectivesStarted = false
    DisplayRadar(true)
    null.DisplayHud(true)
    
    -- Stop objectives tracker if active
    if HasActiveObjectives and HasActiveObjectives() then
        CompleteObjectives(1500)
    end
end

-- ============================================================================
-- STEP MANAGEMENT
-- ============================================================================

goToStep = function(step, extraData)
    tutorialStep = step
    TriggerServerEvent('null:tutorial:updateStep', step, tutorialPath)
    updateTutorialNUI(step, extraData)
    updateObjective(step)
end

-- ============================================================================
-- NUI CALLBACKS
-- ============================================================================

-- Player chose to skip the tutorial
RegisterNUICallback('tutorial:skip', function(data, cb)
    cleanupAll()
    TriggerServerEvent('null:tutorial:skip')
    cb('ok')
end)

-- Player chose to skip via objectives skipCommand
RegisterNetEvent('null:tutorial:skipFromObjectives', function()
    if tutorialActive then
        cleanupAll()
        TriggerServerEvent('null:tutorial:skip')
    end
end)

-- Player clicked "Start Tutorial" from welcome screen (all categories visible)
RegisterNUICallback('tutorial:startTutorial', function(data, cb)
    goToStep('categories')
    cb('ok')
end)

-- Player chose a path (legal/illegal)
RegisterNUICallback('tutorial:choosePath', function(data, cb)
    tutorialPath = data.path
    TriggerServerEvent('null:tutorial:updateStep', tutorialStep, tutorialPath)
    goToStep('path_chosen')
    cb('ok')
end)

-- Player continues after choosing path → BMX given, go to driveschool
RegisterNUICallback('tutorial:continueToDriveschool', function(data, cb)
    -- Give BMX item to player
    TriggerServerEvent('null:tutorial:giveBmx')
    
    -- Set waypoint to driveschool
    local ds = Config.Tutorial.driveschool
    SetNewWaypoint(ds.coords.x, ds.coords.y)
    
    -- Start objectives tracker
    startTutorialObjectives()
    
    goToStep('goto_driveschool')
    closeTutorialNUI()
    cb('ok')
end)

-- Player continues after license → go to vehicle pickup PED
RegisterNUICallback('tutorial:continueAfterLicense', function(data, cb)
    local vp = Config.Tutorial.vehiclePickup
    SetNewWaypoint(vp.pedCoords.x, vp.pedCoords.y)
    spawnVehiclePickupPed()
    goToStep('goto_vehicle_pickup')
    closeTutorialNUI()
    cb('ok')
end)

-- Player continues after vehicle → go to clothing store
RegisterNUICallback('tutorial:continueAfterVehicle', function(data, cb)
    local cs = Config.Tutorial.clothingStore
    SetNewWaypoint(cs.coords.x, cs.coords.y)
    goToStep('goto_clothing')
    closeTutorialNUI()
    cb('ok')
end)

-- Player continues to job center
RegisterNUICallback('tutorial:continueToJobCenter', function(data, cb)
    local coords = jobCenterCoords or Config.Tutorial.jobCenter.coords
    if coords then
        SetNewWaypoint(coords.x, coords.y)
    end
    goToStep('goto_jobcenter')
    closeTutorialNUI()
    cb('ok')
end)

-- Player enters clothing shop (waiting_clothing → clothing_active)
RegisterNUICallback('tutorial:enterClothingShop', function(data, cb)
    goToStep('clothing_active')
    closeTutorialNUI()
    cb('ok')
end)

-- Player advances to next step from NUI
RegisterNUICallback('tutorial:nextStep', function(data, cb)
    local nextStep = data.nextStep
    if nextStep then
        goToStep(nextStep, data.extra)
    end
    cb('ok')
end)

-- Close tablet to go do something (driveschool, clothing, jobcenter)
RegisterNUICallback('tutorial:releaseControls', function(data, cb)
    closeTutorialNUI()
    cb('ok')
end)

-- Tutorial complete
RegisterNUICallback('tutorial:complete', function(data, cb)
    cleanupAll()
    TriggerServerEvent('null:tutorial:complete')
    cb('ok')
end)

-- Close NUI (for intermediate closes)
RegisterNUICallback('tutorial:close', function(data, cb)
    closeTutorialNUI()
    cb('ok')
end)

-- ============================================================================
-- EVENT DETECTION SYSTEM
-- ============================================================================

RegisterNetEvent('null:tutorial:eventDetected', function(eventType)
    if not tutorialActive then return end
    
    if eventType == 'driveschool_opened' and tutorialStep == 'waiting_driveschool' then
        goToStep('driveschool_active')
        closeTutorialNUI()
        
    elseif eventType == 'license_completed' and (tutorialStep == 'driveschool_active' or tutorialStep == 'waiting_driveschool') then
        licenseJustCompleted = true
        if driveschoolClosed then
            licenseJustCompleted = false
            driveschoolClosed = false
            Citizen.CreateThread(function()
                Wait(500)
                goToStep('license_done')
                openTutorialNUI({ step = 'license_done', path = tutorialPath })
            end)
        end
        
    elseif eventType == 'driveschool_closed' then
        driveschoolClosed = true
        if licenseJustCompleted then
            licenseJustCompleted = false
            driveschoolClosed = false
            Citizen.CreateThread(function()
                Wait(500)
                goToStep('license_done')
                openTutorialNUI({ step = 'license_done', path = tutorialPath })
            end)
        end
    end
end)

-- ============================================================================
-- VEHICLE PICKUP EVENT (called from Add3DInteraction Action)
-- ============================================================================

RegisterNetEvent('null:tutorial:pickupVehicle', function()
    if not tutorialActive or tutorialStep ~= 'goto_vehicle_pickup' then return end
    
    local cfg = Config.Tutorial.vehiclePickup
    local spawnPositions = cfg.spawnPositions
    local spawnPos = spawnPositions[math.random(#spawnPositions)]
    
    -- Generate a custom plate like admin menu
    local function generatePlate()
        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        local nums = "0123456789"
        local plate = ""
        for i = 1, 4 do plate = plate .. chars:sub(math.random(#chars), math.random(#chars)):sub(1,1) end
        for i = 1, 4 do plate = plate .. nums:sub(math.random(#nums), math.random(#nums)):sub(1,1) end
        return plate
    end
    
    ESX.Game.SpawnVehicle(cfg.vehicleModel, vector3(spawnPos.x, spawnPos.y, spawnPos.z), spawnPos.w, function(vehicle)
        if not DoesEntityExist(vehicle) then
            ESX.ShowNotification('~r~Erreur lors du spawn du véhicule')
            return
        end
        
        -- Set custom plate before getting props (like admin giveGarageVeh)
        local customPlate = generatePlate()
        SetVehicleNumberPlateText(vehicle, customPlate)
        
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
        vehicleProps.plate = customPlate
        
        -- Enregistrer le véhicule dans le garage du joueur (comme admin giveGarage)
        TriggerServerEvent('null:tutorial:giveGarageVehicle', vehicleProps, cfg.vehicleModel)
        
        -- Donner les clés au joueur
        TriggerEvent('null:vehicle:addKeys', customPlate)
        
        -- Supprimer le PED et l'interaction
        deleteVehiclePickupPed()
        
        -- Supprimer le BMX s'il existe encore
        deleteBmx()
        
        -- Passer à l'étape suivante
        goToStep('vehicle_received')
        openTutorialNUI({ step = 'vehicle_received', path = tutorialPath })
    end)
end)

-- ============================================================================
-- PROXIMITY MONITORING
-- ============================================================================

Citizen.CreateThread(function()
    while true do
        Wait(500)
        if not tutorialActive then goto continue end
        
        local ped = PlayerPedId()
        local pCoords = GetEntityCoords(ped)
        
        -- Arrive near driveschool + vehicle stopped → open tablet
        if tutorialStep == 'goto_driveschool' then
            local ds = Config.Tutorial.driveschool
            if #(pCoords - ds.coords) < ds.arrivalRadius then
                local veh = GetVehiclePedIsIn(ped, false)
                if veh == 0 or GetEntitySpeed(veh) < 1.0 then
                    goToStep('waiting_driveschool')
                    openTutorialNUI({ step = 'waiting_driveschool', path = tutorialPath })
                end
            end
        end
        
        -- Arrive near clothing store + vehicle stopped → open tablet
        if tutorialStep == 'goto_clothing' then
            local cs = Config.Tutorial.clothingStore
            if #(pCoords - cs.coords) < cs.arrivalRadius then
                -- Vérifier que le véhicule est arrêté
                local veh = GetVehiclePedIsIn(ped, false)
                if veh == 0 or GetEntitySpeed(veh) < 1.0 then
                    goToStep('waiting_clothing')
                    openTutorialNUI({ step = 'waiting_clothing', path = tutorialPath })
                end
            end
        end
        
        -- Arrive near job center + vehicle stopped → open tablet
        if tutorialStep == 'goto_jobcenter' then
            local jc = Config.Tutorial.jobCenter
            local jcCoords = jobCenterCoords or jc.coords
            if jcCoords and #(pCoords - jcCoords) < jc.arrivalRadius then
                -- Vérifier que le véhicule est arrêté
                local veh = GetVehiclePedIsIn(ped, false)
                if veh == 0 or GetEntitySpeed(veh) < 1.0 then
                    goToStep('arrived_jobcenter')
                    openTutorialNUI({ step = 'arrived_jobcenter', path = tutorialPath })
                end
            end
        end
        
        ::continue::
    end
end)

-- ============================================================================
-- CLOTHING SHOP MANUAL CONTINUATION (F key)
-- ============================================================================

Citizen.CreateThread(function()
    while true do
        Wait(0)
        if tutorialActive and tutorialStep == 'clothing_active' then
            local cfg = Config.Tutorial.clothingStore
            ESX.ShowHelpNotification(Config.Tutorial.messages.clothingContinue)
            if IsControlJustReleased(0, cfg.continueKey) then
                goToStep('clothing_done')
                openTutorialNUI({ step = 'clothing_done', path = tutorialPath })
                Wait(1000)
            end
        else
            Wait(500)
        end
    end
end)

-- ============================================================================
-- TUTORIAL START/END EVENTS
-- ============================================================================

RegisterNetEvent('null:tutorial:started', function(data)
    tutorialActive = true
    tutorialStep = 'welcome'
    tutorialPath = nil
    licenseJustCompleted = false
    driveschoolClosed = false
    objectivesStarted = false
    
    -- Store resolved job center coords from server
    jobCenterCoords = data.jobCenterCoords

    -- Enable event detection hooks
    EnableTutorialEventHooks()

    -- Player stays where they are (no TP) — tutorial starts after character creation

    Wait(500)

    -- Open NUI with all config data
    local cfg = Config.Tutorial
    openTutorialNUI({
        step = 'welcome',
        config = {
            discordLink = cfg.discordLink,
            jobs = cfg.jobCenter.jobs,
        }
    })
end)

RegisterNetEvent('null:tutorial:ended', function()
    cleanupAll()
end)

-- ============================================================================
-- BMX SPAWN (when player uses the BMX item)
-- ============================================================================

RegisterNetEvent('null:tutorial:spawnBmx', function()
    deleteBmx()
    
    local cfg = Config.Tutorial.bmx
    local ped = PlayerPedId()
    local pCoords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local offset = cfg.spawnOffset
    
    -- Spawn devant le joueur
    local forward = GetEntityForwardVector(ped)
    local spawnCoords = pCoords + forward * offset.y + vector3(offset.x, 0.0, offset.z)
    
    local hash = GetHashKey(cfg.model)
    RequestModel(hash)
    local t = 0
    while not HasModelLoaded(hash) and t < 50 do Wait(100) t = t + 1 end
    if not HasModelLoaded(hash) then return end
    
    bmxVehicle = CreateVehicle(hash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, false)
    SetVehicleOnGroundProperly(bmxVehicle)
    SetModelAsNoLongerNeeded(hash)
end)

-- ============================================================================
-- TRIGGER AFTER CHARACTER CREATION
-- ============================================================================

RegisterNetEvent('esx:charCreator:finish', function()
    if not Config.Tutorial or not Config.Tutorial.enabled then return end

    -- Small delay to let character creation close properly
    Citizen.SetTimeout(2000, function()
        ESX.TriggerServerCallback('null:tutorial:needsTutorial', function(needsTutorial)
            if needsTutorial then
                TriggerServerEvent('null:tutorial:start')
            end
        end)
    end)
end)

-- Also check on loading screen (for players who reconnect mid-tutorial)
RegisterNetEvent('null:tutorial:check', function()
    if not Config.Tutorial or not Config.Tutorial.enabled then return end

    ESX.TriggerServerCallback('null:tutorial:needsTutorial', function(needsTutorial)
        if needsTutorial then
            Wait(1000)
            TriggerServerEvent('null:tutorial:start')
        end
    end)
end)

-- ============================================================================
-- DEBUG COMMAND
-- ============================================================================

RegisterCommand('tutorial', function()
    if tutorialActive then
        cleanupAll()
        TriggerServerEvent('null:tutorial:skip')
    else
        TriggerServerEvent('null:tutorial:start')
    end
end, false)

null.InitPrint('Tutorial system (client) loaded')
