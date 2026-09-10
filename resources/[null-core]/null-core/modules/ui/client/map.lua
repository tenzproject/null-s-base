mapConfig = {
    mapType = "square",
    vehicleOnly = false,
    anchor = "bottom-left",
    position = { x = 1, y = 95 }
}

local defaultAspectRatio = 1920/1080
local resolutionX, resolutionY = GetActiveScreenResolution()
local aspectRatio = resolutionX/resolutionY
local minimapOffset = 0
if aspectRatio > defaultAspectRatio then
    minimapOffset = ((defaultAspectRatio-aspectRatio)/3.6)-0.008
end

local mapSizes = {
    square = { w = 0.1638, h = 0.183, calibrationX = 0.01, calibrationY = -0.06, blipOffsetX = 0.005, blipOffsetY = 0.06 },
    -- Circle: 292px width / 1920 = 0.1521, 237px height / 1080 = 0.2194
    circle = { w = 0.1521, h = 0.2194, calibrationX = -0.005, calibrationY = -0.06, blipOffsetX = 0.02, blipOffsetY = 0.05 } 
}

local maskSizes = {
    square = { w = 0.128, h = 0.20 },
    circle = { w = 0.128, h = 0.20 }
}

-- État du streaming des masques de minimap (évite de re-stream à chaque appel).
local appliedMaskDict = nil

-- Stream la texture custom (square/circlemap) + refresh la bigmap, EN ARRIÈRE-PLAN.
-- Détaché du chemin synchrone pour ne JAMAIS bloquer l'appelant (DoEnterReveal).
local function streamMinimapMask(dict)
    if appliedMaskDict == dict then return end
    CreateThread(function()
        RequestStreamedTextureDict(dict, false)
        local deadline = GetGameTimer() + 5000
        while not HasStreamedTextureDictLoaded(dict) and GetGameTimer() < deadline do
            Wait(0)
        end
        if not HasStreamedTextureDictLoaded(dict) then
            -- Asset pack absent : on garde le masque natif GTA, pas de blocage.
            return
        end
        AddReplaceTexture("platform:/textures/graphics", "radarmasksm", dict, "radarmasksm")
        AddReplaceTexture("platform:/textures/graphics", "radarmask1g", dict, "radarmasksm")
        appliedMaskDict = dict
        -- Toggle bigmap pour forcer le refresh du masque appliqué.
        SetRadarBigmapEnabled(true, false)
        Wait(50)
        SetRadarBigmapEnabled(false, false)
    end)
end

-- Positionne la minimap. SYNCHRONE et INSTANTANÉ (aucun Wait), donc safe à
-- appeler depuis le chemin critique du spawn. Le streaming du masque custom
-- part en tâche de fond via streamMinimapMask.
function loadMapType(mapType)
    if not mapType or not mapSizes[mapType] then
        mapType = "square"
    end
    local pos = mapConfig.position
    local anchor = mapConfig.anchor or "bottom-left"

    local currentMapW = mapSizes[mapType].w or 0.1638
    local currentMapH = mapSizes[mapType].h or 0.183

    local currentMaskW = maskSizes[mapType].w
    local currentMaskH = maskSizes[mapType].h

    local targetX = pos.x / 100
    local targetY = pos.y / 100

    if string.find(anchor, "right") then
        targetX = targetX - currentMaskW
    elseif string.find(anchor, "center") or string.find(anchor, "middle") then
        targetX = targetX - (currentMaskW / 2)
    end

    if string.find(anchor, "bottom") then
        targetY = targetY - currentMaskH
    elseif string.find(anchor, "center") or string.find(anchor, "middle") then
        targetY = targetY - (currentMaskH / 2)
    end

    targetX = targetX + minimapOffset

    local safeZone = GetSafeZoneSize()
    local safeZoneOffsetW = (1.0 - safeZone) * 0.5
    local safeZoneOffsetH = (1.0 - safeZone) * 0.5

    local finalX = targetX - safeZoneOffsetW
    local finalY = targetY - safeZoneOffsetH

    finalX = finalX + mapSizes[mapType].calibrationX
    finalY = finalY + mapSizes[mapType].calibrationY

    -- Blip position: same base as mask + centering offset + manual calibration
    local blipBaseX = finalX + (currentMaskW - currentMapW) / 2 + mapSizes[mapType].blipOffsetX
    local blipBaseY = finalY + (currentMaskH - currentMapH) / 2 + mapSizes[mapType].blipOffsetY

    local alignH = "L"
    local alignV = "T"

    -- Positionnement immédiat (instantané, jamais bloquant).
    if mapType == "circle" then
        SetMinimapClipType(1)
        SetMinimapComponentPosition("minimap", alignH, alignV, blipBaseX, blipBaseY, currentMapW, currentMapH)
        SetMinimapComponentPosition("minimap_mask", alignH, alignV, finalX + 0.21, finalY, 0.065, 0.20)
        SetMinimapComponentPosition('minimap_blur', alignH, alignV, finalX, finalY + 0.015, 0.252, 0.338)
    else
        SetMinimapClipType(0)
        SetMinimapComponentPosition("minimap", alignH, alignV, blipBaseX, blipBaseY, currentMapW, currentMapH)
        SetMinimapComponentPosition("minimap_mask", alignH, alignV, finalX, finalY, currentMaskW, currentMaskH)
        SetMinimapComponentPosition('minimap_blur', alignH, alignV, finalX - 0.015, finalY + 0.02, 0.262, 0.300)
    end
    SetBlipAlpha(GetNorthRadarBlip(), 0)

    -- Masque custom en tâche de fond (no-op si déjà appliqué ou asset absent).
    streamMinimapMask((mapType == "circle") and "circlemap" or "squaremap")
end

RegisterCommand("devcalibration_square", function(source, args)
    mapSizes.square.calibrationX = tonumber(args[1])
    mapSizes.square.calibrationY = tonumber(args[2])
    print("[MAP] Calibration updated: X=" .. mapSizes.square.calibrationX .. " Y=" .. mapSizes.square.calibrationY)
    loadMapType(mapConfig.mapType)
end)

RegisterCommand("devcalibration_circle", function(source, args)
    mapSizes.circle.calibrationX = tonumber(args[1])
    mapSizes.circle.calibrationY = tonumber(args[2])
    print("[MAP] Calibration updated: X=" .. mapSizes.circle.calibrationX .. " Y=" .. mapSizes.circle.calibrationY)
    loadMapType(mapConfig.mapType)
end)

RegisterCommand("devblipoffset_square", function(source, args)
    mapSizes.square.blipOffsetX = tonumber(args[1]) or 0.0
    mapSizes.square.blipOffsetY = tonumber(args[2]) or 0.0
    print("[MAP] Blip offset updated (square): X=" .. mapSizes.square.blipOffsetX .. " Y=" .. mapSizes.square.blipOffsetY)
    loadMapType(mapConfig.mapType)
end)

RegisterCommand("devblipoffset_circle", function(source, args)
    mapSizes.circle.blipOffsetX = tonumber(args[1]) or 0.0
    mapSizes.circle.blipOffsetY = tonumber(args[2]) or 0.0
    print("[MAP] Blip offset updated (circle): X=" .. mapSizes.circle.blipOffsetX .. " Y=" .. mapSizes.circle.blipOffsetY)
    loadMapType(mapConfig.mapType)
end)

RegisterNetEvent('null-hud:updateMapConfig')
AddEventHandler('null-hud:updateMapConfig', function(config)
    if config then
        mapConfig.mapType = config.mapType or "square"
        mapConfig.vehicleOnly = config.vehicleOnly or false
        
        if config.anchor then
            mapConfig.anchor = config.anchor
        end
        if config.position then
            mapConfig.position = config.position
        end

        loadMapType(mapConfig.mapType)
        
    end
end)

CreateThread(function()
    local mapChanged = false
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(ped, false)
        if mapConfig.vehicleOnly then
            mapChanged = true
            DisplayRadar(inVehicle)
        elseif mapChanged then
            mapChanged = false
            DisplayRadar(true)
        end
    end
end)

exports('getMapConfig', function()
    return mapConfig
end)

CreateThread(function()
    Wait(3000)
    loadMapType(mapConfig.mapType or "square")
    Wait(3000)
    loadMapType(mapConfig.mapType or "square")
    Wait(10000)
    loadMapType(mapConfig.mapType or "square")
end)
