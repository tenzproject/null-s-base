-- ============================================================================
-- IMAGE MAKER - Client Module
-- Green screen setup, camera, entity spawning, NUI callbacks
-- ============================================================================

local ImageMaker = {}
local isOpen = false
local isCapturing = false
local config = nil
local cam = nil
local currentEntity = nil
local basePos = nil
local clearTaskInterval = nil
local captureQueue = {}
local captureIndex = 0
local captureSettings = {}
local awaitingCapture = false
local customMode = false
local customSaveType = nil
local customCam = { dist = 5.0, angleH = 30.0, angleV = 10.0, fov = 40.0, target = nil, offsetZ = 0.0 }

-- ============================================================================
-- HELPERS
-- ============================================================================

local function Delay(ms)
    Citizen.Wait(ms)
end

local function setWeatherTime()
    exports['null-core']:stopTimeWhile(true)
    exports['null-core']:DisplayHud(false)
    SetRainLevel(0.0)
    SetWeatherTypePersist('EXTRASUNNY')
    SetWeatherTypeNow('EXTRASUNNY')
    SetWeatherTypeNowPersist('EXTRASUNNY')
    NetworkOverrideClockTime(18, 0, 0)
    NetworkOverrideClockMillisecondsPerGameMinute(1000000)
end

local function restoreWeather()
    exports['null-core']:stopTimeWhile(false)
    exports['null-core']:DisplayHud(true)
end

local function destroyCamera()
    RenderScriptCams(false, false, 0, true, false, 0)
    DestroyAllCams(true)
    if cam then
        DestroyCam(cam, true)
        cam = nil
    end
end

local function cleanupEntity()
    if currentEntity and DoesEntityExist(currentEntity) then
        DeleteEntity(currentEntity)
        currentEntity = nil
    end
end

local function stopClearTask()
    if clearTaskInterval then
        clearTaskInterval = false
    end
end

local function startClearTask()
    clearTaskInterval = true
    Citizen.CreateThread(function()
        while clearTaskInterval do
            if PlayerState.ped and DoesEntityExist(PlayerState.ped) then
                ClearPedTasksImmediately(PlayerState.ped)
            end
            Citizen.Wait(1)
        end
    end) 
end

local function resetPedComponents() 
    -- SetPedDefaultComponentVariation(PlayerState.ped)
    -- Delay(150) 
    -- SetPedComponentVariation(PlayerState.ped, 0, 0, 1, 0)
    -- SetPedComponentVariation(PlayerState.ped, 1, 0, 0, 0)
    -- SetPedComponentVariation(PlayerState.ped, 2, -1, 0, 0)
    -- SetPedComponentVariation(PlayerState.ped, 7, 0, 0, 0)
    -- SetPedComponentVariation(PlayerState.ped, 5, 0, 0, 0)
    -- SetPedComponentVariation(PlayerState.ped, 6, -1, 0, 0)
    -- SetPedComponentVariation(PlayerState.ped, 9, 0, 0, 0)
    -- SetPedComponentVariation(PlayerState.ped, 3, -1, 0, 0)
    -- SetPedComponentVariation(PlayerState.ped, 8, -1, 0, 0)
    -- SetPedComponentVariation(PlayerState.ped, 4, -1, 0, 0)
    -- SetPedComponentVariation(PlayerState.ped, 11, -1, 0, 0)
    -- SetPedHairColor(PlayerState.ped, 45, 15)
    -- -- Clear all props
    -- for _, cat in ipairs(config.clothingCategories or {}) do
    --     if cat.type == 'PROPS' then
    --         ClearPedProp(PlayerState.ped, cat.component)
    --     end
    -- end


	SetPedDefaultComponentVariation(PlayerState.ped)

	Delay(150)

	SetPedComponentVariation(PlayerState.ped, 0, 0, 1, 0)
	SetPedComponentVariation(PlayerState.ped, 1, 0, 0, 0)
	SetPedComponentVariation(PlayerState.ped, 2, -1, 0, 0)
	SetPedComponentVariation(PlayerState.ped, 7, 0, 0, 0)
	SetPedComponentVariation(PlayerState.ped, 5, 0, 0, 0)
	SetPedComponentVariation(PlayerState.ped, 6, -1, 0, 0)
	SetPedComponentVariation(PlayerState.ped, 9, 0, 0, 0)
	SetPedComponentVariation(PlayerState.ped, 3, -1, 0, 0)
	SetPedComponentVariation(PlayerState.ped, 8, -1, 0, 0)
	SetPedComponentVariation(PlayerState.ped, 4, -1, 0, 0)
	SetPedComponentVariation(PlayerState.ped, 11, -1, 0, 0)
	SetPedHairColor(PlayerState.ped, 45, 15)
	ClearAllPedProps()
end

local function setupCamera(fov, zPos, rotation)
    destroyCamera()

    local gs = config.greenScreen
    SetEntityCoordsNoOffset(PlayerState.ped, gs.position.x, gs.position.y, gs.position.z, false, false, false)
    SetEntityRotation(PlayerState.ped, rotation.x, rotation.y, rotation.z, 2, false)
    FreezeEntityPosition(PlayerState.ped, true)
    Delay(50)

    local coords = GetEntityCoords(PlayerState.ped)
    local fwd = GetEntityForwardVector(PlayerState.ped)
    local px, py, pz = coords.x, coords.y, coords.z
    local fx, fy, fz = fwd.x, fwd.y, fwd.z

    -- Camera in front of the ped, green screen behind
    local camPos = vector3(px + fx * 1.2, py + fy * 1.2, pz + fz + zPos)

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPos.x, camPos.y, camPos.z, 0.0, 0.0, 0.0, fov, true, 0)
    SetCamFov(cam, fov)
    PointCamAtCoord(cam, px, py, pz + zPos)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false, 0)
    Delay(50)
end

local function setupVehicleCamera(vehicle, hash)
    destroyCamera()

    local minDim, maxDim = GetModelDimensions(hash)
    local modelSize = vector3(maxDim.x - minDim.x, maxDim.y - minDim.y, maxDim.z - minDim.z)

    -- FOV capped at 60 (matches old working code)
    local maxSize = math.max(modelSize.x, modelSize.y, modelSize.z)
    local fov = math.min(maxSize / 0.15 * 10, 60) + 0.0

    local vehCoords = GetEntityCoords(vehicle, false)
    local ox, oy, oz = vehCoords.x, vehCoords.y, vehCoords.z
    local center = vector3(
        ox + (minDim.x + maxDim.x) / 2,
        oy + (minDim.y + maxDim.y) / 2,
        oz + (minDim.z + maxDim.z) / 2
    )

    -- Distance and angle matching old working JS code (Math.cos(340) with 340 in radians)
    local dist = maxSize + 0.5
    local camPos = vector3(
        center.x + dist * math.cos(340),
        center.y + dist * math.sin(340),
        center.z + modelSize.z / 2
    )

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPos.x, camPos.y, camPos.z, 0.0, 0.0, 0.0, fov, true, 0)
    SetCamFov(cam, fov)
    PointCamAtCoord(cam, center.x, center.y, center.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false, 0)
end

local function setupObjectCamera(object, hash)
    destroyCamera()

    local minDim, maxDim = GetModelDimensions(hash)
    local modelSize = vector3(maxDim.x - minDim.x, maxDim.y - minDim.y, maxDim.z - minDim.z)
    local fov = math.min(math.max(modelSize.x, modelSize.z) / 0.15 * 10, 60) + 0.0

    local objCoords = GetEntityCoords(object, false)
    local objFwd = GetEntityForwardVector(object)
    local ox, oy, oz = objCoords.x, objCoords.y, objCoords.z
    local fx, fy, fz = objFwd.x, objFwd.y, objFwd.z
    local center = vector3(
        ox + (minDim.x + maxDim.x) / 2,
        oy + (minDim.y + maxDim.y) / 2,
        oz + (minDim.z + maxDim.z) / 2
    )

    local camPos = vector3(
        center.x + fx * 1.2 + math.max(modelSize.x, modelSize.z) / 2,
        center.y + fy * 1.2 + math.max(modelSize.x, modelSize.z) / 2,
        center.z + fz
    )

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPos.x, camPos.y, camPos.z, 0.0, 0.0, 0.0, fov, true, 0)
    SetCamFov(cam, fov)
    PointCamAtCoord(cam, center.x, center.y, center.z)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false, 0)
end

local function loadModel(hash)
    if not IsModelValid(hash) then return false end
    if not HasModelLoaded(hash) then
        RequestModel(hash)
        local timeout = 50
        while not HasModelLoaded(hash) and timeout > 0 do
            Delay(100)
            timeout = timeout - 1
        end
    end
    return HasModelLoaded(hash)
end

-- ============================================================================
-- CAPTURE FUNCTIONS
-- ============================================================================

local function captureClothingItem(gender, categoryId, componentType, componentId, drawableId, cameraInfo)
    resetPedComponents()
    Delay(150)

    if componentType == 'PROPS' then
        SetPedPreloadPropData(PlayerState.ped, componentId, drawableId, 0)
        local t = 50
        while not HasPedPreloadPropDataFinished(PlayerState.ped) and t > 0 do Delay(50); t = t - 1 end
        ClearPedProp(PlayerState.ped, componentId)
        SetPedPropIndex(PlayerState.ped, componentId, drawableId, 0, 0)
    else
        SetPedPreloadVariationData(PlayerState.ped, componentId, drawableId, 0)
        local t = 50
        while not HasPedPreloadVariationDataFinished(PlayerState.ped) and t > 0 do Delay(50); t = t - 1 end
        SetPedComponentVariation(PlayerState.ped, componentId, drawableId, 0, 0)
    end

    setupCamera(cameraInfo.fov + 0.0, cameraInfo.zPos, cameraInfo.rotation)
    Delay(captureSettings.delay or 300)

    local filename = gender .. "/" .. categoryId .. "/" .. tostring(drawableId)
    awaitingCapture = true
    TriggerServerEvent('null:imagemaker:capture', 'clothing', filename, true)

    local timeout = 100
    while awaitingCapture and timeout > 0 do
        Delay(100)
        timeout = timeout - 1
    end
end

local function captureVehicle(model)
    local gs = config.greenScreen
    local hash = GetHashKey(model)
    if not loadModel(hash) then return false end

    ClearAreaOfVehicles(gs.vehiclePosition.x, gs.vehiclePosition.y, gs.vehiclePosition.z, 10.0, false, false, false, false, false)
    Delay(200)

    local vehicle = CreateVehicle(hash, gs.vehiclePosition.x, gs.vehiclePosition.y, gs.vehiclePosition.z, 0.0, true, true)
    if vehicle == 0 then
        SetModelAsNoLongerNeeded(hash)
        return false
    end
    
    currentEntity = vehicle
    SetEntityRotation(vehicle, gs.vehicleRotation.x, gs.vehicleRotation.y, gs.vehicleRotation.z, 0, false)
    FreezeEntityPosition(vehicle, true)
    SetVehicleModKit(vehicle, 0)
    SetVehicleWindowTint(vehicle, 1)
    SetVehicleColours(vehicle, 12, 12)
    SetVehicleExtraColours(vehicle, 12, 0)
    
    -- SetVehicleEnveffScale(vehicle, 0.0)

    -- Wait for vehicle to be fully visible/rendered
    local timeout = 50
    while not IsEntityVisible(vehicle) and timeout > 0 do
        Delay(100)
        timeout = timeout - 1
    end
    Delay(300)

    setupVehicleCamera(vehicle, hash)
    Delay(math.max(captureSettings.delay or 500, 800))

    awaitingCapture = true
    TriggerServerEvent('null:imagemaker:capture', 'vehicle', model, true)

    local timeout = 100
    while awaitingCapture and timeout > 0 do
        Delay(100)
        timeout = timeout - 1
    end

    DeleteEntity(vehicle)
    currentEntity = nil
    SetModelAsNoLongerNeeded(hash)
    return true
end

local function captureWeapon(weaponName)
    local gs = config.greenScreen
    local weaponHash = GetHashKey(weaponName)
    if not IsWeaponValid(weaponHash) then return false end

    local modelHash = GetWeapontypeModel(weaponHash)
    if not loadModel(modelHash) then return false end

    SetEntityCoords(PlayerState.ped, gs.hiddenSpot.x, gs.hiddenSpot.y, gs.hiddenSpot.z, false, false, false)
    Delay(50)

    local obj = CreateObjectNoOffset(modelHash, gs.position.x, gs.position.y, gs.position.z, false, true, true)
    if obj == 0 then
        SetModelAsNoLongerNeeded(modelHash)
        return false
    end

    currentEntity = obj
    SetEntityRotation(obj, gs.rotation.x, gs.rotation.y, gs.rotation.z, 0, false)
    FreezeEntityPosition(obj, true)
    Delay(50)

    setupObjectCamera(obj, modelHash)
    Delay(captureSettings.delay or 500)

    awaitingCapture = true

    local objCoords = GetEntityCoords(obj, false)
    local lightPos = vector3(objCoords.x, objCoords.y, objCoords.z + 1.0)

    Citizen.CreateThread(function()
        while awaitingCapture and DoesEntityExist(obj) do
            DrawSpotLight(lightPos.x, lightPos.y, lightPos.z, 0.0, 0.0, -1.0, 255, 255, 255, 15.0, 5.0, 1.0, 15.0, 1.0)
            Citizen.Wait(0)
        end
    end)

    TriggerServerEvent('null:imagemaker:capture', 'weapon', weaponName, true)

    local timeout = 100
    while awaitingCapture and timeout > 0 do
        Delay(100)
        timeout = timeout - 1
    end

    DeleteEntity(obj)
    currentEntity = nil
    SetModelAsNoLongerNeeded(modelHash)
    return true
end

local function capturePed(pedModel)
    local gs = config.greenScreen
    local hash = GetHashKey(pedModel)
    if not loadModel(hash) then return false end

    local pedEntity = CreatePed(4, hash, gs.position.x, gs.position.y, gs.position.z, gs.rotation.z, false, true)
    if pedEntity == 0 then
        SetModelAsNoLongerNeeded(hash)
        return false
    end

    currentEntity = pedEntity
    FreezeEntityPosition(pedEntity, true)
    Delay(100)

    -- Camera for ped - full body (center at ~0.85m for full height coverage)
    destroyCamera()
    local pedCoords = GetEntityCoords(pedEntity)
    local pedFwd = GetEntityForwardVector(pedEntity)
    local px, py, pz = pedCoords.x, pedCoords.y, pedCoords.z
    local fx, fy = pedFwd.x, pedFwd.y
    local camPos = vector3(px + fx * 2.5, py + fy * 2.5, pz + 0.85)

    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPos.x, camPos.y, camPos.z, 0.0, 0.0, 0.0, 45.0, true, 0)
    SetCamFov(cam, 45.0)
    PointCamAtCoord(cam, px, py, pz + 0.85)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false, 0)
    Delay(captureSettings.delay or 500)

    -- Move player out of frame
    SetEntityCoords(PlayerState.ped, gs.hiddenSpot.x, gs.hiddenSpot.y, gs.hiddenSpot.z, false, false, false)
    Delay(100)

    awaitingCapture = true
    TriggerServerEvent('null:imagemaker:capture', 'ped', pedModel, true)

    local timeout = 100
    while awaitingCapture and timeout > 0 do
        Delay(100)
        timeout = timeout - 1
    end

    DeleteEntity(pedEntity)
    currentEntity = nil
    SetModelAsNoLongerNeeded(hash)
    return true
end

local function captureProp(propModel)
    local gs = config.greenScreen
    local hash = GetHashKey(propModel)
    if not loadModel(hash) then return false end

    SetEntityCoords(PlayerState.ped, gs.hiddenSpot.x, gs.hiddenSpot.y, gs.hiddenSpot.z, false, false, false)
    Delay(50)

    local obj = CreateObjectNoOffset(hash, gs.position.x, gs.position.y, gs.position.z, false, true, true)
    if obj == 0 then
        SetModelAsNoLongerNeeded(hash)
        return false
    end

    currentEntity = obj
    SetEntityRotation(obj, gs.rotation.x, gs.rotation.y, gs.rotation.z, 0, false)
    FreezeEntityPosition(obj, true)
    Delay(50)

    setupObjectCamera(obj, hash)
    Delay(captureSettings.delay or 500)

    awaitingCapture = true
    TriggerServerEvent('null:imagemaker:capture', 'prop', propModel, true)

    local timeout = 100
    while awaitingCapture and timeout > 0 do
        Delay(100)
        timeout = timeout - 1
    end

    DeleteEntity(obj)
    currentEntity = nil
    SetModelAsNoLongerNeeded(hash)
    return true
end

-- ============================================================================
-- UTILS / TATTOOS CAPTURE HELPERS
-- ============================================================================

-- Cadrage caméra par type d'utils (hair/beard/eyebrows/lipstick/chesthair).
-- Pour les tatouages, le cadrage est dérivé de la zone (cf. UTILS_ZONE_FRAMING).
local UTILS_TYPE_FRAMING = {
    hair      = { fov = 28.0, zPos = 0.68, rotZ = 300 },
    eyebrows  = { fov = 22.0, zPos = 0.65, rotZ = 300 },
    beard     = { fov = 22.0, zPos = 0.62, rotZ = 300 },
    lipstick  = { fov = 18.0, zPos = 0.60, rotZ = 300 },
    makeup    = { fov = 22.0, zPos = 0.65, rotZ = 300 },
    blush     = { fov = 22.0, zPos = 0.64, rotZ = 300 },
    chesthair = { fov = 45.0, zPos = 0.30, rotZ = 300 },
}

-- Cadrage caméra par zone du corps (utilisé pour les tatouages).
-- rotZ tourne le ped pour montrer la zone : ~300 = face, ~120 = dos,
-- 60 = côté droit (R), 240 = côté gauche (L).
local UTILS_ZONE_FRAMING = {
    hair    = { fov = 28.0, zPos = 0.68,  rotZ = 300 },
    neck    = { fov = 30.0, zPos = 0.55,  rotZ = 300 },
    chest   = { fov = 45.0, zPos = 0.30,  rotZ = 300 },
    stomach = { fov = 45.0, zPos = 0.10,  rotZ = 300 },
    back    = { fov = 45.0, zPos = 0.30,  rotZ = 120 },
    larm    = { fov = 35.0, zPos = 0.30,  rotZ = 240 },
    rarm    = { fov = 35.0, zPos = 0.30,  rotZ = 60  },
    lleg    = { fov = 50.0, zPos = -0.40, rotZ = 240 },
    rleg    = { fov = 50.0, zPos = -0.40, rotZ = 60  },
    torso   = { fov = 55.0, zPos = 0.10,  rotZ = 300 },
}

-- Initialise les head blend data du freemode ped, sinon les head overlays
-- (sourcils/barbe/rouge à lèvres/pilosité) ne s'affichent pas.
local function initFreemodePedHead()
    if PlayerState.ped and DoesEntityExist(PlayerState.ped) then
        SetPedHeadBlendData(PlayerState.ped, 0, 0, 0, 0, 0, 0, 0.0, 0.0, 0.0, false)
        Delay(50)
    end
end

-- Met le ped torse-nu (et jambes si stripLegs) pour capturer pilosité /
-- tatouages corps. Valeurs nudes diffèrent légèrement entre M/F.
local function stripPedBody(gender, stripLegs)
    local p = PlayerState.ped
    SetPedComponentVariation(p, 8,  15, 0, 0)            -- undershirt: aucun
    SetPedComponentVariation(p, 11, 15, 0, 0)            -- top: torse nu
    SetPedComponentVariation(p, 3,  15, 0, 0)            -- bras nus
    SetPedComponentVariation(p, 9,  0,  0, 0)            -- pas de gilet
    SetPedComponentVariation(p, 10, 0,  0, 0)            -- pas de décals
    if stripLegs then
        local legsDrawable = (gender == 'female') and 15 or 21
        SetPedComponentVariation(p, 4, legsDrawable, 0, 0)
    end
end

local function captureUtilsItem(item, utilsInfo)
    local gender    = item.gender
    local utilsType = item.utilsType

    -- Reset ped + init head blend (indispensable pour les head overlays)
    resetPedComponents()
    Delay(150)
    initFreemodePedHead()

    local framing
    local filenameBase

    if utilsType == 'tattoos' then
        -- Cas spécial : applique le tatouage via AddPedDecorationFromHashes
        local zone = item.zone or 'torso'
        -- Strip torse pour toutes les zones sauf jambes/cheveux
        if zone ~= 'lleg' and zone ~= 'rleg' and zone ~= 'hair' then
            stripPedBody(gender, false)
        elseif zone == 'lleg' or zone == 'rleg' then
            stripPedBody(gender, true)
        end
        Delay(80)

        ClearPedDecorations(PlayerState.ped)
        if item.collection and item.nameHash then
            AddPedDecorationFromHashes(
                PlayerState.ped,
                GetHashKey(item.collection),
                GetHashKey(item.nameHash)
            )
        end
        Delay(150)

        framing      = UTILS_ZONE_FRAMING[zone] or UTILS_ZONE_FRAMING.torso
        filenameBase = gender .. '/tattoos/' .. tostring(item.nameHash)

    elseif utilsType == 'hair' then
        SetPedComponentVariation(PlayerState.ped, utilsInfo.componentId, item.variationId, 0, 0)
        Delay(50)
        SetPedHairColor(PlayerState.ped, 0, 0)
        framing      = UTILS_TYPE_FRAMING.hair
        filenameBase = gender .. '/' .. utilsType .. '/' .. tostring(item.variationId)

    elseif utilsType == 'eyebrows' or utilsType == 'beard' or utilsType == 'lipstick'
        or utilsType == 'makeup' or utilsType == 'blush' then
        SetPedHeadOverlay(PlayerState.ped, utilsInfo.componentId, item.variationId, 1.0)
        Delay(50)
        SetPedHeadOverlayColor(PlayerState.ped, utilsInfo.componentId, utilsInfo.colorId or 1, 0, 0)
        framing      = UTILS_TYPE_FRAMING[utilsType]
        filenameBase = gender .. '/' .. utilsType .. '/' .. tostring(item.variationId)

    elseif utilsType == 'chesthair' then
        -- Pilosité torse : strip top puis applique l'overlay 10
        stripPedBody(gender, false)
        Delay(80)
        SetPedHeadOverlay(PlayerState.ped, utilsInfo.componentId, item.variationId, 1.0)
        Delay(50)
        SetPedHeadOverlayColor(PlayerState.ped, utilsInfo.componentId, utilsInfo.colorId or 1, 0, 0)
        framing      = UTILS_TYPE_FRAMING.chesthair
        filenameBase = gender .. '/' .. utilsType .. '/' .. tostring(item.variationId)

    else
        return
    end

    setupCamera(framing.fov, framing.zPos, { x = 0, y = 0, z = framing.rotZ })
    Delay(captureSettings.delay or 500)

    awaitingCapture = true
    TriggerServerEvent('null:imagemaker:capture', 'utils', filenameBase, true)

    local timeout = 100
    while awaitingCapture and timeout > 0 do
        Delay(100)
        timeout = timeout - 1
    end
end

-- ============================================================================
-- CAPTURE RESULT HANDLER
-- ============================================================================

RegisterNetEvent('null:imagemaker:captureResult', function(success, filename, captureType)
    awaitingCapture = false
    SendNUIMessage({
        action = 'imagemaker:captureProgress',
        success = success,
        filename = filename,
        captureType = captureType,
        current = captureIndex,
        total = #captureQueue,
    })
end)

-- ============================================================================
-- BATCH CAPTURE ORCHESTRATOR
-- ============================================================================

local function runBatchCapture()
    if not config then return end
    isCapturing = true

    basePos = GetEntityCoords(PlayerState.ped, false)
    setWeatherTime()
    DisableIdleCamera(true)
    Delay(200)

    local gs = config.greenScreen

    for i, item in ipairs(captureQueue) do
        if not isCapturing then break end
        captureIndex = i

        SendNUIMessage({
            action = 'imagemaker:captureProgress',
            current = i,
            total = #captureQueue,
            itemLabel = item.label or item.id,
            capturing = true,
        })

        if item.type == 'clothing' then
            -- Set up ped model for clothing
            local modelHash = item.gender == 'female' and GetHashKey('mp_f_freemode_01') or GetHashKey('mp_m_freemode_01')
            if loadModel(modelHash) then
                SetPlayerModel(PlayerId(), modelHash)
                Delay(200)
                SetEntityRotation(PlayerState.ped, gs.rotation.x, gs.rotation.y, gs.rotation.z, 0, false)
                SetEntityCoordsNoOffset(PlayerState.ped, gs.position.x, gs.position.y, gs.position.z, false, false, false)
                FreezeEntityPosition(PlayerState.ped, true)
                SetPlayerControl(PlayerId(), false)

                local camSettings = nil
                if item.componentType == 'PROPS' then
                    camSettings = config.cameraSettings.PROPS[item.componentId]
                else
                    camSettings = config.cameraSettings.CLOTHING[item.componentId]
                end

                if camSettings then
                    captureClothingItem(item.gender, item.categoryId, item.componentType, item.componentId, item.drawableId, camSettings)
                end
                SetPlayerControl(PlayerId(), true)
                FreezeEntityPosition(PlayerState.ped, false)
                SetModelAsNoLongerNeeded(modelHash)
            end

        elseif item.type == 'vehicle' then
            SetEntityCoords(PlayerState.ped, gs.hiddenSpot.x, gs.hiddenSpot.y, gs.hiddenSpot.z, false, false, false)
            SetPlayerControl(PlayerId(), false)
            captureVehicle(item.model)
            SetPlayerControl(PlayerId(), true)

        elseif item.type == 'weapon' then
            SetPlayerControl(PlayerId(), false)
            captureWeapon(item.weaponName)
            SetPlayerControl(PlayerId(), true)

        elseif item.type == 'ped' then
            SetPlayerControl(PlayerId(), false)
            capturePed(item.model)
            SetPlayerControl(PlayerId(), true)

        elseif item.type == 'prop' then
            SetPlayerControl(PlayerId(), false)
            captureProp(item.model)
            SetPlayerControl(PlayerId(), true)

        elseif item.type == 'utils' then
            -- Set up ped model for utils
            local modelHash = item.gender == 'female' and GetHashKey('mp_f_freemode_01') or GetHashKey('mp_m_freemode_01')
            if loadModel(modelHash) then
                SetPlayerModel(PlayerId(), modelHash)
                Delay(200)
                SetEntityRotation(PlayerState.ped, gs.rotation.x, gs.rotation.y, gs.rotation.z, 0, false)
                SetEntityCoordsNoOffset(PlayerState.ped, gs.position.x, gs.position.y, gs.position.z, false, false, false)
                FreezeEntityPosition(PlayerState.ped, true)
                SetPlayerControl(PlayerId(), false)

                -- Find utils category info
                local utilsInfo = nil
                for _, cat in ipairs(config.utilsCategories or {}) do
                    if cat.id == item.utilsType then
                        utilsInfo = cat
                        break
                    end
                end

                if utilsInfo or item.utilsType == 'tattoos' then
                    captureUtilsItem(item, utilsInfo)
                end

                SetPlayerControl(PlayerId(), true)
                FreezeEntityPosition(PlayerState.ped, false)
                SetModelAsNoLongerNeeded(modelHash)
            end
        end
    end

    -- Cleanup
    cleanupEntity()
    destroyCamera()
    stopClearTask()

    -- Restore player
    if basePos then
        local bx, by, bz = basePos.x, basePos.y, basePos.z
		ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
			TriggerEvent('Null:skinchanger:loadSkin', skin)
		end)
        Delay(200)
        local _, ground = GetGroundZFor_3dCoord(bx, by, bz, 0, false)
        SetEntityCoords(PlayerState.ped, bx, by, ground or bz, false, false, false)
    end

    restoreWeather()
    SetPlayerControl(PlayerId(), true)
    FreezeEntityPosition(PlayerState.ped, false)
    DisableIdleCamera(false)
    isCapturing = false

    TriggerServerEvent('null:imagemaker:restart:cache')

    Delay(5000)

    SendNUIMessage({
        action = 'imagemaker:captureComplete',
    })
end

-- ============================================================================
-- NUI CALLBACKS
-- ============================================================================

RegisterNUICallback('imagemaker:close', function(_, cb)
    if isCapturing then
        isCapturing = false
        Delay(500)
    end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'imagemaker:close' })
    cb('ok')
end)

RegisterNUICallback('imagemaker:getConfig', function(_, cb)
    if not config then
        ESX.TriggerServerCallback('null:imagemaker:getConfig', function(cfg)
            config = cfg
            cb(config)
        end)
    else
        cb(config)
    end
end)

RegisterNUICallback('imagemaker:scanImages', function(_, cb)
    TriggerServerEvent('null:imagemaker:scanImages')
    cb('ok')
end)

RegisterNetEvent('null:imagemaker:scanResult', function(data)
    SendNUIMessage({
        action = 'imagemaker:scanResult',
        data = data,
    })
end)

RegisterNUICallback('imagemaker:scanGameData', function(data, cb)
    -- Scan clothing variations for a given gender
    local gender = data.gender or 'male'
    local modelHash = gender == 'female' and GetHashKey('mp_f_freemode_01') or GetHashKey('mp_m_freemode_01')

    if not loadModel(modelHash) then
        cb({ error = 'Failed to load model' })
        return
    end

    -- Create a temporary ped to count variations
    local tempPed = CreatePed(4, modelHash, 0.0, 0.0, 0.0, 0.0, false, false)
    Delay(200)

    local clothingData = {}
    for _, cat in ipairs(config.clothingCategories or {}) do
        local count = 0
        if cat.type == 'PROPS' then
            count = GetNumberOfPedPropDrawableVariations(tempPed, cat.component)
        else
            count = GetNumberOfPedDrawableVariations(tempPed, cat.component)
        end
        clothingData[cat.id] = count
    end

    -- Scan utils variations
    local utilsData = {}
    local tattoosForGender = (config.tattoosList and config.tattoosList[gender]) or {}
    for _, cat in ipairs(config.utilsCategories or {}) do
        local count = 0
        if cat.id == 'hair' then
            count = GetNumberOfPedDrawableVariations(tempPed, cat.componentId)
        elseif cat.id == 'tattoos' then
            count = #tattoosForGender
        else
            -- For overlays (eyebrows, beard, chesthair, lipstick)
            count = GetNumHeadOverlayValues(cat.componentId)
        end
        utilsData[cat.id] = count
    end

    DeleteEntity(tempPed)
    SetModelAsNoLongerNeeded(modelHash)

    -- Scan vehicles
    local vehicles = GetAllVehicleModels()

    cb({
        clothing = clothingData,
        utils = utilsData,
        tattoosList = tattoosForGender, -- liste { collection, nameHash, zone } pour ce genre
        vehicleCount = #vehicles,
        vehicles = vehicles,
    })
end)

RegisterNUICallback('imagemaker:startCapture', function(data, cb)
    if isCapturing then
        cb({ error = 'Already capturing' })
        return
    end

    captureQueue = data.queue or {}
    captureSettings = data.settings or {}
    captureIndex = 0

    if #captureQueue == 0 then
        cb({ error = 'Empty queue' })
        return
    end

    cb({ started = true, total = #captureQueue })

    Citizen.CreateThread(function()
        runBatchCapture()
    end)
end)

RegisterNUICallback('imagemaker:stopCapture', function(_, cb)
    isCapturing = false
    cb('ok')
end)

RegisterNUICallback('imagemaker:deleteImage', function(data, cb)
    TriggerServerEvent('null:imagemaker:deleteImage', data.type, data.filename)
    cb('ok')
end)

RegisterNetEvent('null:imagemaker:deleteResult', function(success, filename, deleteType)
    SendNUIMessage({
        action = 'imagemaker:deleteResult',
        success = success,
        filename = filename,
        deleteType = deleteType,
    })
end)

-- ============================================================================
-- CUSTOM CAPTURE MODE
-- ============================================================================

local function updateCustomCamera()
    if not cam or not customCam.target then return end
    local rad = math.rad
    local cx = customCam.target.x + customCam.dist * math.cos(rad(customCam.angleV)) * math.cos(rad(customCam.angleH))
    local cy = customCam.target.y + customCam.dist * math.cos(rad(customCam.angleV)) * math.sin(rad(customCam.angleH))
    local cz = customCam.target.z + customCam.dist * math.sin(rad(customCam.angleV)) + customCam.offsetZ
    SetCamCoord(cam, cx, cy, cz)
    SetCamFov(cam, customCam.fov + 0.0)
    PointCamAtCoord(cam, customCam.target.x, customCam.target.y, customCam.target.z + customCam.offsetZ)
end

RegisterNUICallback('imagemaker:customSpawn', function(data, cb)
    if not config then cb({ error = 'No config' }) return end
    local gs = config.greenScreen
    local entityType = data.entityType -- 'vehicle', 'weapon', 'ped', 'prop', 'clothing'
    local model = data.model or ''

    -- Cleanup previous
    cleanupEntity()
    destroyCamera()
    customMode = true

    setWeatherTime()
    DisableIdleCamera(true)
    basePos = basePos or GetEntityCoords(PlayerState.ped)

    if entityType == 'vehicle' then
        local hash = GetHashKey(model)
        if not loadModel(hash) then cb({ error = 'Model failed' }) return end

        SetEntityCoords(PlayerState.ped, gs.hiddenSpot.x, gs.hiddenSpot.y, gs.hiddenSpot.z, false, false, false)

        ClearAreaOfVehicles(gs.vehiclePosition.x, gs.vehiclePosition.y, gs.vehiclePosition.z, 10.0, false, false, false, false, false)
        Delay(200)
        local veh = CreateVehicle(hash, gs.vehiclePosition.x, gs.vehiclePosition.y, gs.vehiclePosition.z, 0.0, true, true)
        if veh == 0 then cb({ error = 'Spawn failed' }) return end
        currentEntity = veh
        SetEntityRotation(veh, gs.vehicleRotation.x, gs.vehicleRotation.y, gs.vehicleRotation.z, 0, false)
        FreezeEntityPosition(veh, true)
        SetVehicleWindowTint(veh, 1)

        Delay(300)

        local minDim, maxDim = GetModelDimensions(hash)
        local modelSize = vector3(maxDim.x - minDim.x, maxDim.y - minDim.y, maxDim.z - minDim.z)
        local ox, oy, oz = GetEntityCoords(veh).x, GetEntityCoords(veh).y, GetEntityCoords(veh).z
        customCam.target = vector3(ox + (minDim.x + maxDim.x) / 2, oy + (minDim.y + maxDim.y) / 2, oz + (minDim.z + maxDim.z) / 2)
        customCam.dist = math.max(modelSize.x, modelSize.y, modelSize.z) + 3
        customCam.fov = 50.0
        customCam.angleH = 30.0
        customCam.angleV = 15.0
        customCam.offsetZ = 0.0
        SetModelAsNoLongerNeeded(hash)

    elseif entityType == 'weapon' or entityType == 'prop' then
        local hash
        if entityType == 'weapon' then
            local weaponHash = GetHashKey(model)
            hash = GetWeapontypeModel(weaponHash)
        else
            hash = GetHashKey(model)
        end
        if not loadModel(hash) then cb({ error = 'Model failed' }) return end

        SetEntityCoords(PlayerState.ped, gs.hiddenSpot.x, gs.hiddenSpot.y, gs.hiddenSpot.z, false, false, false)
        Delay(50)
        local obj = CreateObjectNoOffset(hash, gs.position.x, gs.position.y, gs.position.z, false, true, true)
        if obj == 0 then cb({ error = 'Spawn failed' }) return end
        currentEntity = obj
        SetEntityRotation(obj, gs.rotation.x, gs.rotation.y, gs.rotation.z, 0, false)
        FreezeEntityPosition(obj, true)
        Delay(50)

        local minDim, maxDim = GetModelDimensions(hash)
        local modelSize = vector3(maxDim.x - minDim.x, maxDim.y - minDim.y, maxDim.z - minDim.z)
        local ox, oy, oz = GetEntityCoords(obj).x, GetEntityCoords(obj).y, GetEntityCoords(obj).z
        customCam.target = vector3(ox + (minDim.x + maxDim.x) / 2, oy + (minDim.y + maxDim.y) / 2, oz + (minDim.z + maxDim.z) / 2)
        customCam.dist = math.max(modelSize.x, modelSize.y, modelSize.z) + 1.5
        customCam.fov = 40.0
        customCam.angleH = 30.0
        customCam.angleV = 5.0
        customCam.offsetZ = 0.0
        SetModelAsNoLongerNeeded(hash)

    elseif entityType == 'ped' then
        local hash = GetHashKey(model)
        if not loadModel(hash) then cb({ error = 'Model failed' }) return end

        SetEntityCoords(PlayerState.ped, gs.hiddenSpot.x, gs.hiddenSpot.y, gs.hiddenSpot.z, false, false, false)
        Delay(50)
        local pedEntity = CreatePed(4, hash, gs.position.x, gs.position.y, gs.position.z, gs.rotation.z, false, false)
        if pedEntity == 0 then cb({ error = 'Spawn failed' }) return end
        currentEntity = pedEntity
        FreezeEntityPosition(pedEntity, true)
        Delay(100)

        local coords = GetEntityCoords(pedEntity)
        customCam.target = vector3(coords.x, coords.y, coords.z + 0.85)
        customCam.dist = 2.5
        customCam.fov = 45.0
        customCam.angleH = 30.0
        customCam.angleV = 5.0
        customCam.offsetZ = 0.0
        SetModelAsNoLongerNeeded(hash)

    elseif entityType == 'clothing' then
        local gender = data.gender or 'male'
        local componentType = data.componentType or 'CLOTHING'
        local componentId = data.componentId or 11
        local drawableId = data.drawableId or 0

        local modelHash = gender == 'female' and GetHashKey('mp_f_freemode_01') or GetHashKey('mp_m_freemode_01')
        if not loadModel(modelHash) then cb({ error = 'Model failed' }) return end

        SetPlayerModel(PlayerId(), modelHash)
        Delay(200)
        SetEntityRotation(PlayerState.ped, gs.rotation.x, gs.rotation.y, gs.rotation.z, 0, false)
        SetEntityCoordsNoOffset(PlayerState.ped, gs.position.x, gs.position.y, gs.position.z, false, false, false)
        FreezeEntityPosition(PlayerState.ped, true)
        startClearTask()
        Delay(100)
        resetPedComponents()
        Delay(100)

        if componentType == 'PROPS' then
            SetPedPropIndex(PlayerState.ped, componentId, drawableId, 0, true)
        else
            SetPedComponentVariation(PlayerState.ped, componentId, drawableId, 0, 0)
        end
        Delay(100)

        local coords = GetEntityCoords(PlayerState.ped)
        customCam.target = vector3(coords.x, coords.y, coords.z + 0.5)
        customCam.dist = 1.8
        customCam.fov = 45.0
        customCam.angleH = 210.0
        customCam.angleV = 5.0
        customCam.offsetZ = 0.0
        customSaveType = 'clothing'
    end

    -- Create orbital camera
    destroyCamera()
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, customCam.fov, true, 0)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false, 0)
    updateCustomCamera()

    cb({ ok = true, dist = customCam.dist, angleH = customCam.angleH, angleV = customCam.angleV, fov = customCam.fov, offsetZ = customCam.offsetZ })
end)
 
RegisterNUICallback('imagemaker:customAdjust', function(data, cb)
    if data.dist then customCam.dist = tonumber(data.dist) or customCam.dist end
    if data.angleH then customCam.angleH = tonumber(data.angleH) or customCam.angleH end
    if data.angleV then customCam.angleV = tonumber(data.angleV) or customCam.angleV end
    if data.fov then customCam.fov = tonumber(data.fov) or customCam.fov end
    if data.offsetZ then customCam.offsetZ = tonumber(data.offsetZ) or customCam.offsetZ end
    if data.entityRotZ then
        if customSaveType == 'clothing' and PlayerState.ped and DoesEntityExist(PlayerState.ped) then
            local rot = GetEntityRotation(PlayerState.ped, 2)
            SetEntityRotation(PlayerState.ped, rot.x, rot.y, tonumber(data.entityRotZ) or rot.z, 2, false)
        elseif currentEntity and DoesEntityExist(currentEntity) then
            local rot = GetEntityRotation(currentEntity, 2)
            SetEntityRotation(currentEntity, rot.x, rot.y, tonumber(data.entityRotZ) or rot.z, 2, false)
        end
    end
    updateCustomCamera()
    cb('ok')
end)

RegisterNUICallback('imagemaker:customCapture', function(data, cb)
    if not customMode then cb({ error = 'Not in custom mode' }) return end
    local saveName = data.saveName or ('custom_' .. os.time())
    local saveType = data.saveType or 'prop'

    awaitingCapture = true
    TriggerServerEvent('null:imagemaker:capture', saveType, saveName, true)

    local timeout = 100
    while awaitingCapture and timeout > 0 do
        Delay(100)
        timeout = timeout - 1
    end

    cb({ ok = true })
end)

RegisterNUICallback('imagemaker:customClear', function(_, cb)
    customMode = false
    customSaveType = nil
    cleanupEntity()
    destroyCamera()
    stopClearTask()
    restoreWeather()

    if basePos then
        local bx, by, bz = basePos.x, basePos.y, basePos.z
        ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
            TriggerEvent('Null:skinchanger:loadSkin', skin)
        end)
        Delay(200)
        local _, ground = GetGroundZFor_3dCoord(bx, by, bz, 0, false)
        SetEntityCoords(PlayerState.ped, bx, by, ground or bz, false, false, false)
    end

    SetPlayerControl(PlayerId(), true)
    FreezeEntityPosition(PlayerState.ped, false)
    DisableIdleCamera(false)
    cb('ok')
end)

-- ============================================================================
-- OPEN / CLOSE
-- ============================================================================

function ImageMaker.Open()
    if isOpen then return end
    isOpen = true
    SendNUIMessage({ action = 'imagemaker:open' })
    SetNuiFocus(true, true)
end

function ImageMaker.Close()
    if not isOpen then return end
    if isCapturing then
        isCapturing = false
    end
    isOpen = false
    SendNUIMessage({ action = 'imagemaker:close' })
    SetNuiFocus(false, false)
end

RegisterCommand('imagemaker', function()
    if isOpen then
        ImageMaker.Close()
    else
        ImageMaker.Open()
    end
end, false)

exports('OpenImageMaker', ImageMaker.Open)
exports('CloseImageMaker', ImageMaker.Close)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resName)
    if GetCurrentResourceName() ~= resName then return end
    cleanupEntity()
    destroyCamera()
    stopClearTask()
    restoreWeather()
    if PlayerState.ped then
        SetPlayerControl(PlayerId(), true)
        FreezeEntityPosition(PlayerState.ped, false)
    end
end)
