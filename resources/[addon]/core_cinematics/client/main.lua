


local uiOpen             = false                  
local isRecording        = false                  
local isFreecamMode      = false                  
local editorCam          = nil                    

local keyframes          = {}                     
local currentFrame       = 0                      
local playbackSec        = 0.0                    
local totalFrames        = Config.DefaultFPS * 30 

local previewCams        = {}                     
local previewCamIdx      = 1                      
local activeLayer        = 0                      

local interpSettings     = {                      
    mode    = Config.DefaultInterpolationMode or "eased",
    tension = 0.0,
    spring  = 0.0,
}

local vehicleRecordings  = {}    
local pedRecordings      = {}    
local vehicleSpawns      = {}    
local pedSpawns          = {}    
local vehicleSpawnReady  = {}    
local pedSpawnReady      = {}    
local vehicleFrameIdx    = {}    

local overlayLayers      = {}    
local maxOverlayLayers   = 10    
local soloRecording      = nil   
local soloLayerActive    = false 

local playbackActive     = false 
local previewActive      = false 
local motionBlurOn       = false 

local trimStart          = 0.0   
local trimEnd            = nil   
local trimIn             = 0.0   

local playerSavedPos     = nil   
local playerSavedHead    = nil   

local cameraProp         = nil   
local cameraPropTimer    = 0     

local sceneFollowing     = {}    

local pedFrameIdx        = {}    
local pedJumpState       = {}    
local pedClimbState      = {}    
local pedRagdollState    = {}    
local pedInVehicle       = {}    
local pedLeavingVeh      = {}    
local pedWalkCooldown    = {}    
local pedWalking         = {}    

local isPlaying          = false 
local timeScale          = 1.0   
local savedPlayerPos     = nil   
local savedPlayerHeading = nil   
local inBucket           = false 

local driftSmokeTrack    = {}    
local soloRecordingLayer = nil   

local showPath           = false 
local cameraPropRecs     = {}    

local function syncPlayerSavedAlias()
    if playerSavedPos and not savedPlayerPos then savedPlayerPos = playerSavedPos end
    if playerSavedHead and not savedPlayerHeading then savedPlayerHeading = playerSavedHead end
end

local textObjects         = {} 
local textClips           = {} 

local worldSettings       = {  
    time            = 12.0,
    freezeTime      = false,
    weather         = "CLEAR",
    weatherOverride = true,
    rainEnabled     = false,
    rainLevel       = 0.0,
    windSpeed       = 0.0,
    cityLights      = false,
}

local sceneEntities       = {} 
local sceneRelGroups      = {} 
local sceneGroupRelMatrix = { neutral = 3, friendly = 1, hostile = 5 }
local sceneCombatActive   = false

local focusCam            = nil   
local hiDofActive         = false 

local fontUrlMap          = {}    
for _, font in ipairs(Config.Fonts or {}) do
    if font.url then
        fontUrlMap[font.family] = font.url
    end
end

local function lerpAngle(from, to, t)
    local delta = (to - from) % 360.0
    if delta > 180.0 then delta = delta - 360.0 end
    return from + delta * t
end

local function lerpTime(from, to, t)
    local delta = (to - from) % 24.0
    if delta > 12.0 then delta = delta - 24.0 end
    return (from + delta * t) % 24.0
end

local function normalizeFov(fov)
    fov = fov or Config.DefaultFov
    return fov + 0.001
end

local function easingToCurveType(easing)
    local map = { easein = 1, easeout = 2, ease = 3 }
    return map[easing] or 0
end

local function easeIn(t) return t * t * t end

local function easeOut(t)
    local inv = 1 - t
    return 1 - inv * inv * inv
end

local function easeInOut(t) return t * t * (3 - 2 * t) end

local function lerpVal(a, b, t) return a + (b - a) * t end

local function lerpVec3(a, b, t)
    return vector3(lerpVal(a.x, b.x, t), lerpVal(a.y, b.y, t), lerpVal(a.z, b.z, t))
end

local function lerpRot(a, b, t)
    return vector3(lerpAngle(a.x, b.x, t), lerpAngle(a.y, b.y, t), lerpAngle(a.z, b.z, t))
end

local function applyGameTime(hours)
    local h = math.floor(hours)
    local m = math.floor((hours - h) * 60)
    NetworkOverrideClockTime(h, m, 0)
end

local function captureVehicleProps(vehicle)
    local p1, p2          = GetVehicleColours(vehicle)
    local cr1, cg1, cb1   = GetVehicleCustomPrimaryColour(vehicle)
    local cr2, cg2, cb2   = GetVehicleCustomSecondaryColour(vehicle)
    local pearl, wheelCol = GetVehicleExtraColours(vehicle)
    local nr, ng, nb      = GetVehicleNeonLightsColour(vehicle)

    local props           = {
        colorP1    = p1,
        colorP2    = p2,
        isCustomP1 = GetIsVehiclePrimaryColourCustom(vehicle),
        customP1   = { cr1, cg1, cb1 },
        isCustomP2 = GetIsVehicleSecondaryColourCustom(vehicle),
        customP2   = { cr2, cg2, cb2 },
        pearl      = pearl,
        wheelColor = wheelCol,
        livery     = GetVehicleLivery(vehicle),
        wheelType  = GetVehicleWheelType(vehicle),
        windowTint = GetVehicleWindowTint(vehicle),
        neonColor  = { nr, ng, nb },
        neon       = {},
        mods       = {},
        extras     = {},
    }

    for i = 0, 3 do
        props.neon[i + 1] = IsVehicleNeonLightEnabled(vehicle, i)
    end
    for i = 0, 49 do
        local mod = GetVehicleMod(vehicle, i)
        if mod ~= -1 then
            props.mods[i] = { mod, GetVehicleModVariation(vehicle, i) }
        end
    end
    for i = 0, 14 do
        if DoesExtraExist(vehicle, i) then
            props.extras[i] = IsVehicleExtraTurnedOn(vehicle, i)
        end
    end

    return props
end

local function applyVehicleProps(vehicle, props)
    if not props then return end

    SetVehicleModKit(vehicle, 0)
    SetVehicleColours(vehicle, props.colorP1, props.colorP2)

    if props.isCustomP1 then
        SetVehicleCustomPrimaryColour(vehicle, props.customP1[1], props.customP1[2], props.customP1[3])
    end
    if props.isCustomP2 then
        SetVehicleCustomSecondaryColour(vehicle, props.customP2[1], props.customP2[2], props.customP2[3])
    end

    SetVehicleExtraColours(vehicle, props.pearl, props.wheelColor)
    SetVehicleLivery(vehicle, props.livery)
    SetVehicleWheelType(vehicle, props.wheelType)
    SetVehicleWindowTint(vehicle, props.windowTint)

    for i = 0, 49 do
        if props.mods[i] then
            SetVehicleMod(vehicle, i, props.mods[i][1], props.mods[i][2])
        end
    end
    for i = 0, 14 do
        if props.extras[i] ~= nil then
            SetVehicleExtra(vehicle, i, props.extras[i] and 0 or 1)
        end
    end
    for i = 0, 3 do
        SetVehicleNeonLightEnabled(vehicle, i, props.neon[i + 1])
    end
    SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
end

local function isPedFreemodeModel(ped)
    local model = GetEntityModel(ped)
    return model == 1885233650 or model == -1667301416
end

local function capturePedAppearance(ped)
    local data = {
        freemode   = isPedFreemodeModel(ped),
        components = {},
        props      = {},
    }

    pcall(function()
        for slot = 0, 11 do
            data.components[#data.components + 1] = {
                slot     = slot,
                drawable = GetPedDrawableVariation(ped, slot),
                texture  = GetPedTextureVariation(ped, slot),
                palette  = GetPedPaletteVariation(ped, slot),
            }
        end
    end)

    pcall(function()
        for slot = 0, 7 do
            data.props[#data.props + 1] = {
                slot     = slot,
                drawable = GetPedPropIndex(ped, slot),
                texture  = GetPedPropTextureIndex(ped, slot),
            }
        end
    end)

    if not data.freemode then return data end

    pcall(function()
        local s1, s2, s3, sk1, sk2, sk3, sm, skm, tm =
            Citizen.InvokeNative(
                2830157900151113168, ped,
                Citizen.PointerValueIntInitialized(0),
                Citizen.PointerValueIntInitialized(0),
                Citizen.PointerValueIntInitialized(0),
                Citizen.PointerValueIntInitialized(0),
                Citizen.PointerValueIntInitialized(0),
                Citizen.PointerValueIntInitialized(0),
                Citizen.PointerValueFloatInitialized(0),
                Citizen.PointerValueFloatInitialized(0),
                Citizen.PointerValueFloatInitialized(0)
            )
        data.headBlend = {
            shapeFirst  = s1,
            shapeSecond = s2,
            shapeThird  = s3,
            skinFirst   = sk1,
            skinSecond  = sk2,
            skinThird   = sk3,
            shapeMix    = sm or 0.0,
            skinMix     = skm or 0.0,
            thirdMix    = tm or 0.0,
        }
    end)

    data.overlays = {}
    pcall(function()
        for slot = 0, 12 do
            local _, val, ctype, c1, c2, opacity = GetPedHeadOverlayData(ped, slot)
            data.overlays[#data.overlays + 1] = {
                slot = slot,
                value = val,
                colourType = ctype,
                colour1 = c1,
                colour2 = c2,
                opacity = opacity,
            }
        end
    end)

    data.faceFeatures = {}
    pcall(function()
        for slot = 0, 19 do
            data.faceFeatures[#data.faceFeatures + 1] = {
                slot = slot, value = GetPedFaceFeature(ped, slot),
            }
        end
    end)

    pcall(function()
        data.hairColor          = GetPedHairColor(ped)
        data.hairHighlightColor = GetPedHairHighlightColor(ped)
    end)
    pcall(function()
        if GetPedEyeColor then
            data.eyeColor = GetPedEyeColor(ped)
        end
    end)

    return data
end

local function applyPedAppearance(ped, appearance)
    if not appearance then return end

    if isPedFreemodeModel(ped) and appearance.headBlend then
        local b = appearance.headBlend
        pcall(SetPedHeadBlendData, ped,
            b.shapeFirst or 0, b.shapeSecond or 0, b.shapeThird or 0,
            b.skinFirst or 0, b.skinSecond or 0, b.skinThird or 0,
            (b.shapeMix or 0) + 0.0,
            (b.skinMix or 0) + 0.0,
            (b.thirdMix or 0) + 0.0,
            false)
    end

    if appearance.components then
        for _, comp in ipairs(appearance.components) do
            pcall(SetPedComponentVariation, ped, comp.slot,
                comp.drawable or 0, comp.texture or 0, comp.palette or 0)
        end
    end

    if appearance.props then
        for _, prop in ipairs(appearance.props) do
            if prop.drawable and prop.drawable ~= -1 then
                pcall(SetPedPropIndex, ped, prop.slot, prop.drawable, prop.texture or 0, true)
            else
                pcall(ClearPedProp, ped, prop.slot)
            end
        end
    end
end

local function findPedSeat(vehicle, ped)
    if GetPedInVehicleSeat(vehicle, -1) == ped then return -1 end
    local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
    for seat = 0, maxSeats - 1 do
        if GetPedInVehicleSeat(vehicle, seat) == ped then
            return seat
        end
    end
    return -1
end

fv = normalizeFov

local spawnSingleVehicle, spawnSinglePed, spawnOverlayVehicle
local previewVehicleAtFrame, previewPedAtFrame, previewOverlayAtFrame
local stopPlayback, cleanupOverlaySpawns, sendOverlayLayersToJS
local drawKeyframePath, updateCameraProp, beginSoloRecording
local interpolateKeyframes, interpolateKeyframesSpline

function stopPlayback()
    isPlaying = false
    for _, ds in pairs(driftSmokeTrack) do
        if DriftSmoke and DriftSmoke.stopPlayback then DriftSmoke.stopPlayback(ds) end
    end
    driftSmokeTrack = {}

    if editorCam and DoesCamExist(editorCam) then
        StopCamShaking(editorCam, true)
        SetCamUseShallowDofMode(editorCam, false)
        SetCamActive(editorCam, true)
        RenderScriptCams(true, false, 0, true, true)
    end
    timeScale = 1.0
    SetTimeScale(1.0)
    SendNUIMessage({ type = "fxClear" })
    DisplayHud(true); DisplayRadar(true)
    ClearTimecycleModifier()
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "playbackStopped", frame = currentFrame })

    if savedPlayerPos then
        local p = PlayerPedId()
        SetEntityCoordsNoOffset(p, savedPlayerPos.x, savedPlayerPos.y, savedPlayerPos.z, false, false, false)
        SetEntityHeading(p, savedPlayerHeading or 0.0)
        SetEntityLocallyInvisible(p, false)
        SetEntityCollision(p, true, true)
        SetEntityInvincible(p, false)
        savedPlayerPos = nil; savedPlayerHeading = nil
    end
    
    if savedPlayerVehicle and DoesEntityExist(savedPlayerVehicle) then
        SetEntityCollision(savedPlayerVehicle, true, true)
        SetEntityInvincible(savedPlayerVehicle, false)
        SetEntityLocallyInvisible(savedPlayerVehicle, false)
        savedPlayerVehicle = nil
    end
    
    previewVehicleAtFrame(currentFrame)
    previewPedAtFrame(currentFrame)
    previewOverlayAtFrame(currentFrame)
end

function previewVehicleAtFrame(frame)
    if isPlaying then return end
    local sec = frame / (Config.DefaultFPS or 30)
    for i, rec in ipairs(vehicleRecordings) do
        local frames = rec.frames
        if #frames >= 2 then
            local inSec = trimStart + (frames[1].t or 0)
            local outSec = trimEnd or (trimStart + rec.duration)
            if sec >= inSec and sec <= outSec then
                local t = sec - trimStart + trimIn
                if not (vehicleSpawns[i] and DoesEntityExist(vehicleSpawns[i])) then
                    spawnSingleVehicle(i)
                else
                    local fi = 1
                    for k = 1, #frames - 1 do
                        if frames[k].t <= t then fi = k else break end
                    end
                    local f0  = frames[fi]; local f1 = frames[math.min(fi + 1, #frames)]
                    local df  = f1.t - f0.t
                    local a   = df > 0.001 and math.max(0, math.min(1, (t - f0.t) / df)) or 0
                    local px  = f0.px + (f1.px - f0.px) * a
                    local py  = f0.py + (f1.py - f0.py) * a
                    local pz  = f0.pz + (f1.pz - f0.pz) * a + (rec.suspensionDelta or 0)
                    local rx  = lerpAngle(f0.rx, f1.rx, a); local ry = lerpAngle(f0.ry, f1.ry, a); local rz = lerpAngle(
                        f0.rz, f1.rz, a)
                    local veh = vehicleSpawns[i]
                    FreezeEntityPosition(veh, true)
                    SetEntityCoordsNoOffset(veh, px, py, pz, false, false, false)
                    SetEntityRotation(veh, rx, ry, rz, 2, true)
                end
            else
                if vehicleSpawns[i] and DoesEntityExist(vehicleSpawns[i]) then
                    DeleteEntity(vehicleSpawns[i]); vehicleSpawns[i] = nil; vehicleSpawnReady[i] = false
                end
            end
        end
    end
end

function previewPedAtFrame(frame)
    if isPlaying then return end
    local sec = frame / (Config.DefaultFPS or 30)
    for i, rec in ipairs(pedRecordings) do
        local frames = rec.frames
        if #frames >= 2 then
            local inSec = trimStart + (frames[1].t or 0)
            local outSec = trimEnd or (trimStart + rec.duration)
            if sec >= inSec and sec <= outSec then
                local t = sec - trimStart + trimIn
                if not (pedSpawns[i] and DoesEntityExist(pedSpawns[i])) then
                    spawnSinglePed(i)
                else
                    local fi = 1
                    for k = 1, #frames - 1 do
                        if frames[k].t <= t then fi = k else break end
                    end
                    local f0  = frames[fi]; local f1 = frames[math.min(fi + 1, #frames)]
                    local df  = f1.t - f0.t
                    local a   = df > 0.001 and math.max(0, math.min(1, (t - f0.t) / df)) or 0
                    local px  = f0.px + (f1.px - f0.px) * a
                    local py  = f0.py + (f1.py - f0.py) * a
                    local pz  = f0.pz + (f1.pz - f0.pz) * a
                    local rz  = lerpAngle(f0.rz, f1.inVehicle and f0.rz or f1.rz, a)
                    local ped = pedSpawns[i]
                    FreezeEntityPosition(ped, true)
                    SetEntityCoordsNoOffset(ped, px, py, pz, false, false, false)
                    SetEntityHeading(ped, rz)
                end
            else
                if pedSpawns[i] and DoesEntityExist(pedSpawns[i]) then
                    DeleteEntity(pedSpawns[i]); pedSpawns[i] = nil; pedSpawnReady[i] = false
                end
            end
        end
    end
end

function previewOverlayAtFrame(frame)
    if isPlaying then return end
    local sec = frame / (Config.DefaultFPS or 30)
    for i, layer in ipairs(overlayLayers) do
        local rec = layer.vehicleRec
        local frames = rec and rec.frames
        if frames and #frames >= 2 then
            local endSec = layer.endSec or (layer.startSec + rec.duration - (layer.trimInSec or 0))
            if sec >= layer.startSec and sec <= endSec then
                local t = sec - layer.startSec + (layer.trimInSec or 0)
                if not (layer.vehicleSpawn and DoesEntityExist(layer.vehicleSpawn)) then
                    spawnOverlayVehicle(i)
                else
                    local fi = 1
                    for k = 1, #frames - 1 do if frames[k].t <= t then fi = k else break end end
                    local f0 = frames[fi]; local f1 = frames[math.min(fi + 1, #frames)]
                    local df = f1.t - f0.t; local a = df > 0.001 and math.max(0, math.min(1, (t - f0.t) / df)) or 0
                    local px = f0.px + (f1.px - f0.px) * a; local py = f0.py + (f1.py - f0.py) * a
                    local pz = f0.pz + (f1.pz - f0.pz) * a + (rec.suspensionDelta or 0)
                    local rx = lerpAngle(f0.rx, f1.rx, a); local ry = lerpAngle(f0.ry, f1.ry, a); local rz = lerpAngle(
                        f0.rz, f1.rz, a)
                    FreezeEntityPosition(layer.vehicleSpawn, true)
                    SetEntityCoordsNoOffset(layer.vehicleSpawn, px, py, pz, false, false, false)
                    SetEntityRotation(layer.vehicleSpawn, rx, ry, rz, 2, true)
                end
            else
                if layer.vehicleSpawn and DoesEntityExist(layer.vehicleSpawn) then
                    DeleteEntity(layer.vehicleSpawn); layer.vehicleSpawn = nil; layer.vehicleSpawning = false
                end
            end
        end
    end
end

function drawKeyframePath()
    if #keyframes < 2 then return end
    local distSq = (Config.PathDrawDistance or 150.0) ^ 2
    local pp = GetEntityCoords(PlayerPedId())
    for i = 1, #keyframes - 1 do
        local a = keyframes[i]; local b = keyframes[i + 1]
        local av = vector3(a.pos.x, a.pos.y, a.pos.z)
        local bv = vector3(b.pos.x, b.pos.y, b.pos.z)
        if #(av - pp) ^ 2 <= distSq or #(bv - pp) ^ 2 <= distSq then
            DrawLine(av.x, av.y, av.z, bv.x, bv.y, bv.z, 220, 50, 50, 200)
        end
    end
    for _, kf in ipairs(keyframes) do
        local v = vector3(kf.pos.x, kf.pos.y, kf.pos.z)
        if #(v - pp) ^ 2 <= distSq then
            DrawMarker(28, v.x, v.y, v.z, 0, 0, 0, 0, 0, 0, 0.15, 0.15, 0.15, 245, 200, 60, 200, false, true, 2, false,
                nil, nil, false)
        end
    end
end

function updateCameraProp()
    if not editorCam or not DoesCamExist(editorCam) then return end
    local p = GetCamCoord(editorCam)
    local r = GetCamRot(editorCam, 2)
    for _, rec in pairs(cameraPropRecs) do
        if rec.prop and DoesEntityExist(rec.prop) then
            SetEntityCoordsNoOffset(rec.prop, p.x, p.y, p.z, false, false, false)
            SetEntityRotation(rec.prop, r.x, r.y, r.z, 2, true)
        end
    end
end

function sendOverlayLayersToJS()
    local list = {}
    for i, layer in ipairs(overlayLayers) do
        list[i] = {
            id           = i,
            vehicleModel = layer.vehicleRec and layer.vehicleRec.vehicleModel or nil,
            startSec     = layer.startSec,
            endSec       = layer.endSec,
            trimInSec    = layer.trimInSec,
        }
    end
    SendNUIMessage({ type = "overlayLayersUpdate", layers = list })
end

function cleanupOverlaySpawns()
    for _, layer in ipairs(overlayLayers) do
        if layer.vehicleSpawn and DoesEntityExist(layer.vehicleSpawn) then
            DeleteEntity(layer.vehicleSpawn)
            layer.vehicleSpawn = nil; layer.vehicleSpawning = false
        end
    end
end

local savedPlayerVehicle = nil 

function spawnSingleVehicle(idx)
    if vehicleSpawns[idx] and DoesEntityExist(vehicleSpawns[idx]) then return end
    local rec = vehicleRecordings[idx]
    if not rec or not rec.frames or #rec.frames < 1 then return end
    vehicleSpawnReady[idx] = false
    CreateThread(function()
        local mh = rec.vehicleModel
        RequestModel(mh); local t = 0
        while not HasModelLoaded(mh) and t < 100 do
            Wait(50); t = t + 1
        end
        if not HasModelLoaded(mh) then return end
        local f0 = rec.frames[1]
        local veh = CreateVehicle(mh, f0.px, f0.py, f0.pz + 0.5, f0.rz or 0, false, false)
        SetEntityVisible(veh, true, false); SetEntityAlpha(veh, 255, false)
        SetEntityInvincible(veh, true); SetEntityCollision(veh, false, false)
        FreezeEntityPosition(veh, true)
        applyVehicleProps(veh, rec.props)
        vehicleSpawns[idx] = veh; vehicleSpawnReady[idx] = true
        vehicleFrameIdx[idx] = vehicleFrameIdx[idx] or 1
        SetModelAsNoLongerNeeded(mh)
    end)
end

function spawnSinglePed(idx)
    if pedSpawns[idx] and DoesEntityExist(pedSpawns[idx]) then return end
    local rec = pedRecordings[idx]
    if not rec or not rec.frames or #rec.frames < 1 then return end
    pedSpawnReady[idx] = false
    CreateThread(function()
        local mh = rec.pedModel
        RequestModel(mh); local t = 0
        while not HasModelLoaded(mh) and t < 100 do
            Wait(50); t = t + 1
        end
        if not HasModelLoaded(mh) then return end
        local f0 = rec.frames[1]
        local ped = CreatePed(4, mh, f0.px, f0.py, f0.pz, f0.rz or 0, false, false)
        SetEntityVisible(ped, true, false); SetEntityInvincible(ped, true)
        SetEntityCollision(ped, false, false); FreezeEntityPosition(ped, true)
        SetPedCanRagdoll(ped, false); SetPedFleeAttributes(ped, 0, false)
        applyPedAppearance(ped, rec.appearance)
        pedSpawns[idx] = ped; pedSpawnReady[idx] = true
        pedFrameIdx[idx] = pedFrameIdx[idx] or 1
        SetModelAsNoLongerNeeded(mh)
    end)
end

function spawnOverlayVehicle(idx)
    local layer = overlayLayers[idx]
    if not layer or layer.vehicleSpawning then return end
    if layer.vehicleSpawn and DoesEntityExist(layer.vehicleSpawn) then return end
    local rec = layer.vehicleRec
    if not rec or not rec.frames or #rec.frames < 1 then return end
    layer.vehicleSpawning = true
    CreateThread(function()
        local mh = rec.vehicleModel
        RequestModel(mh); local t = 0
        while not HasModelLoaded(mh) and t < 100 do
            Wait(50); t = t + 1
        end
        if not HasModelLoaded(mh) then
            layer.vehicleSpawning = false; return
        end
        local f0 = rec.frames[1]
        local veh = CreateVehicle(mh, f0.px, f0.py, f0.pz + 0.5, f0.rz or 0, false, false)
        SetEntityVisible(veh, true, false); SetEntityInvincible(veh, true)
        SetEntityCollision(veh, false, false); FreezeEntityPosition(veh, true)
        applyVehicleProps(veh, rec.props)
        layer.vehicleSpawn = veh; layer.vehicleSpawning = false
        layer.vehicleFrameIdx = layer.vehicleFrameIdx or 1
        SetModelAsNoLongerNeeded(mh)
    end)
end

function beginSoloRecording()
    if isRecording then return end
    soloRecordingLayer = {
        vehicleRec = nil,
        startSec = 0,
        endSec = nil,
        trimInSec = 0,
        vehicleSpawn = nil,
        vehicleSpawning = false,
        vehicleFrameIdx = 1
    }
    isRecording = true
    local startMs = GetGameTimer()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not (veh and veh ~= 0 and DoesEntityExist(veh)) then
        SendNUIMessage({ type = "toast", msg = _L("lua.errors.not_in_vehicle"), level = "error" })
        isRecording = false; soloRecordingLayer = nil; return
    end
    local frames = {}
    CreateThread(function()
        while isRecording do
            local t = (GetGameTimer() - startMs) / 1000.0
            local pos = GetEntityCoords(veh)
            local rot = GetEntityRotation(veh, 2)
            local vel = GetEntityVelocity(veh)
            frames[#frames + 1] = {
                t = t,
                px = pos.x,
                py = pos.y,
                pz = pos.z,
                rx = rot.x,
                ry = rot.y,
                rz = rot.z,
                vx = vel.x,
                vy = vel.y,
                vz = vel.z,
                steer = GetVehicleSteeringAngle(veh),
                rpm = GetVehicleCurrentRpm(veh),
                handbrake = GetVehicleHandbrake(veh),
            }
            Wait(0)
        end
        if #frames < 2 then
            soloRecordingLayer = nil; return
        end
        local rec = {
            vehicleModel    = GetEntityModel(veh),
            plate           = GetVehicleNumberPlateText(veh),
            props           = captureVehicleProps(veh),
            frames          = frames,
            duration        = frames[#frames].t,
            suspensionDelta = 0.0,
        }
        soloRecordingLayer.vehicleRec = rec
        table.insert(overlayLayers, soloRecordingLayer)
        soloRecordingLayer = nil
        sendOverlayLayersToJS()
        openUI()
    end)
    SendNUIMessage({ type = "soloRecordingStarted" })
end

local function startVehicleRecording(recordVehicles, recordPeds)
    if recordVehicles == nil then recordVehicles = true end
    if recordPeds == nil then recordPeds = true end

    if isRecording then
        print(_L("lua.notify.already_recording"))
        return
    end

    isRecording              = true
    vehicleRecordings        = {}
    pedRecordings            = {}

    local vehicleHandleToIdx = {}
    local pedHandleToIdx     = {}

    CreateThread(function()
        local startMs   = GetGameTimer()
        local playerPed = PlayerPedId()

        while isRecording do
            local elapsed   = (GetGameTimer() - startMs) / 1000.0
            playerPed       = PlayerPedId()
            local playerPos = GetEntityCoords(playerPed)
            local radius    = Config.RecordRadius

            if recordVehicles then
                for _, veh in ipairs(GetGamePool("CVehicle")) do
                    if DoesEntityExist(veh) and not IsEntityDead(veh) then
                        local dist = #(GetEntityCoords(veh) - playerPos)
                        if dist <= radius then
                            if not vehicleHandleToIdx[veh] then
                                local idx = #vehicleRecordings + 1
                                vehicleRecordings[idx] = {
                                    vehicleModel = GetEntityModel(veh),
                                    plate        = GetVehicleNumberPlateText(veh),
                                    props        = captureVehicleProps(veh),
                                    duration     = 0.0,
                                    frames       = {},
                                }
                                vehicleHandleToIdx[veh] = idx
                            end

                            local idx                                                         = vehicleHandleToIdx[veh]
                            local pos                                                         = GetEntityCoords(veh)
                            local rot                                                         = GetEntityRotation(veh, 2)
                            local vel                                                         = GetEntityVelocity(veh)

                            vehicleRecordings[idx].frames[#vehicleRecordings[idx].frames + 1] = {
                                t         = elapsed,
                                px        = pos.x,
                                py        = pos.y,
                                pz        = pos.z,
                                rx        = rot.x,
                                ry        = rot.y,
                                rz        = rot.z,
                                vx        = vel.x,
                                vy        = vel.y,
                                vz        = vel.z,
                                steer     = GetVehicleSteeringAngle(veh),
                                rpm       = GetVehicleCurrentRpm(veh),
                                horn      = IsHornActive(veh),
                                handbrake = GetVehicleHandbrake(veh),
                            }
                            vehicleRecordings[idx].duration                                   = elapsed
                        end
                    end
                end
            end

            if recordPeds then
                local pool = GetGamePool("CPed")
                
                local hasPlayer = false
                for _, p in ipairs(pool) do
                    if p == playerPed then
                        hasPlayer = true; break
                    end
                end
                if not hasPlayer then
                    pool[#pool + 1] = playerPed
                end

                for _, ped in ipairs(pool) do
                    if IsPedHuman(ped) and not IsEntityDead(ped) then
                        local dist = #(GetEntityCoords(ped) - playerPos)
                        if dist <= radius then
                            if not pedHandleToIdx[ped] then
                                local idx = #pedRecordings + 1
                                local ok, appearance = pcall(capturePedAppearance, ped)
                                pedRecordings[idx] = {
                                    pedModel   = GetEntityModel(ped),
                                    isPlayer   = (ped == playerPed),
                                    appearance = (ok and appearance) or nil,
                                    duration   = 0.0,
                                    frames     = {},
                                }
                                pedHandleToIdx[ped] = idx
                            end

                            local idx   = pedHandleToIdx[ped]
                            local frame = nil

                            if IsPedInAnyVehicle(ped, false) then
                                local veh = GetVehiclePedIsIn(ped, false)
                                local vehIdx = vehicleHandleToIdx[veh]
                                if vehIdx then
                                    frame = {
                                        t         = elapsed,
                                        inVehicle = true,
                                        vehRecIdx = vehIdx,
                                        seat      = findPedSeat(veh, ped),
                                    }
                                end
                            else
                                local pos      = GetEntityCoords(ped)
                                local vel      = GetEntityVelocity(ped)
                                local isAiming = false
                                if ped == playerPed then
                                    isAiming = IsPlayerFreeAiming(PlayerId())
                                end
                                if not isAiming then
                                    isAiming = IsPedAimingFromCover(ped)
                                end

                                frame = {
                                    t          = elapsed,
                                    inVehicle  = false,
                                    px         = pos.x,
                                    py         = pos.y,
                                    pz         = pos.z,
                                    rz         = GetEntityHeading(ped),
                                    vx         = vel.x,
                                    vy         = vel.y,
                                    vz         = vel.z,
                                    moveBlend  = GetPedDesiredMoveBlendRatio(ped),
                                    weapon     = GetSelectedPedWeapon(ped),
                                    isAiming   = isAiming,
                                    isShooting = IsPedShooting(ped),
                                    isJumping  = IsPedJumping(ped),
                                    isVaulting = IsPedVaulting(ped),
                                    isClimbing = IsPedClimbing(ped),
                                    isRagdoll  = IsPedRagdoll(ped),
                                }
                            end

                            if frame then
                                pedRecordings[idx].frames[#pedRecordings[idx].frames + 1] = frame
                                pedRecordings[idx].duration = elapsed
                            end
                        end
                    end
                end
            end

            local halfNow  = math.floor(elapsed * 2)
            local halfPrev = math.floor((elapsed - 0.033) * 2)
            if halfNow > halfPrev then
                SendNUIMessage({ type = "recordingTick", elapsed = elapsed })
            end

            Wait(33)
        end
    end)

    local stopKey = Config.RecordingStopKey or 177
    CreateThread(function()
        while isRecording do
            DisableControlAction(0, stopKey, true)
            if IsControlJustPressed(0, stopKey) or IsDisabledControlJustPressed(0, stopKey) then
                stopVehicleRecording()
                return
            end
            Wait(0)
        end
    end)

    local targets = ""
    if recordVehicles then targets = targets .. (_L("lua.notify.target_vehicles") or "") end
    if recordVehicles and recordPeds then targets = targets .. " + " end
    if recordPeds then targets = targets .. (_L("lua.notify.target_peds") or "") end
    print(_L("lua.notify.recording_started", { targets = targets, radius = Config.RecordRadius }))
end

local function stopVehicleRecording()
    if not isRecording then
        print(_L("lua.notify.not_recording"))
        return
    end

    isRecording = false
    SendNUIMessage({ type = "recordingStopped" })

    for i = #vehicleRecordings, 1, -1 do
        if #vehicleRecordings[i].frames < 2 then
            table.remove(vehicleRecordings, i)
        end
    end
    for i = #pedRecordings, 1, -1 do
        if #pedRecordings[i].frames < 2 then
            table.remove(pedRecordings, i)
        end
    end

    if #vehicleRecordings == 0 and #pedRecordings == 0 then
        vehicleRecordings = {}
        pedRecordings     = {}
        print(_L("lua.notify.recording_empty"))
        return
    end

    local maxDuration = 0.0
    for _, rec in ipairs(vehicleRecordings) do
        if rec.duration > maxDuration then maxDuration = rec.duration end
    end
    for _, rec in ipairs(pedRecordings) do
        if rec.duration > maxDuration then maxDuration = rec.duration end
    end

    print(_L("lua.notify.recording_saved", {
        vehicles = #vehicleRecordings,
        peds     = #pedRecordings,
        duration = string.format("%.1f", maxDuration),
    }))

    trimStart = 0.0
    trimEnd   = nil
    trimIn    = 0.0

    spawnVehicleRecording()
    initPedRecording()

    CreateThread(function()
        Wait(150)
        previewVehicleAtFrame(currentFrame or 0)
        previewPedAtFrame(currentFrame or 0)
    end)

    SendNUIMessage({ type = "recordingFinished" })
end

local function waitForModel(modelHash, maxTries)
    local n = 0
    while not HasModelLoaded(modelHash) and n < (maxTries or 100) do
        Wait(50); n = n + 1
    end
    return HasModelLoaded(modelHash)
end

local function spawnReplayVehicle(rec, idx)
    if vehicleSpawnReady[idx] then return end
    vehicleSpawnReady[idx] = true
    local model = rec.vehicleModel
    RequestModel(model)
    CreateThread(function()
        if not waitForModel(model) or not vehicleSpawnReady[idx] then
            vehicleSpawnReady[idx] = false
            SetModelAsNoLongerNeeded(model)
            return
        end
        local f0  = rec.frames[1]
        local veh = CreateVehicle(model, f0.px, f0.py, f0.pz, f0.rz, false, false)
        SetEntityRotation(veh, f0.rx, f0.ry, f0.rz, 2, true)
        SetEntityInvincible(veh, true)
        FreezeEntityPosition(veh, true)
        SetVehicleEngineOn(veh, true, true, false)
        SetVehicleLights(veh, 2)
        if rec.plate and rec.plate ~= "" then SetVehicleNumberPlateText(veh, rec.plate) end
        if rec.props then applyVehicleProps(veh, rec.props) end
        SetEntityMotionBlur(veh, motionBlurOn)
        SetModelAsNoLongerNeeded(model)
        vehicleSpawns[idx]     = veh
        vehicleSpawnReady[idx] = false
    end)
end

local function spawnVehicleRecording()
    local fps, maxDur = Config.DefaultFPS, 0.0
    for i, r in ipairs(vehicleRecordings) do
        vehicleFrameIdx[i] = 1
        spawnReplayVehicle(r, i)
        if r.duration > maxDur then maxDur = r.duration end
    end
    for _, r in ipairs(pedRecordings) do
        if r.duration > maxDur then maxDur = r.duration end
    end
    local entities = {}
    for i, r in ipairs(vehicleRecordings) do
        local name = GetDisplayNameFromVehicleModel(r.vehicleModel)
        if name == "CARNOTFOUND" then name = tostring(r.vehicleModel) end
        entities[#entities + 1] = { type = "vehicle", idx = i, model = name:lower(), isPlayer = false }
    end
    for i, r in ipairs(pedRecordings) do
        entities[#entities + 1] = { type = "ped", idx = i, model = tostring(r.pedModel), isPlayer = r.isPlayer or false }
    end
    SendNUIMessage({
        type        = "vehicleRecordingLoaded",
        duration    = maxDur,
        totalFrames = math.floor(maxDur * fps),
        count       = #vehicleRecordings,
        pedCount    = #pedRecordings,
        startFrame  = math.floor(trimStart * fps),
        endFrame    = trimEnd and math.floor(trimEnd * fps) or nil,
        trimInFrame = math.floor(trimIn * fps),
        entities    = entities,
    })
end

local function previewVehicleAtFrame(frame)
    if #vehicleRecordings == 0 then return end
    local sec = frame / Config.DefaultFPS
    for idx, rec in ipairs(vehicleRecordings) do
        local veh = vehicleSpawns[idx]
        if not veh or not DoesEntityExist(veh) then goto cont end
        local endSec = trimEnd or (trimStart + rec.duration - trimIn)
        local cursor = sec - trimStart + trimIn
        if sec < trimStart or sec > endSec or cursor < rec.frames[1].t or cursor > rec.duration then
            FreezeEntityPosition(veh, true); goto cont
        end
        local fi = vehicleFrameIdx[idx] or 1
        while fi < #rec.frames - 1 and rec.frames[fi + 1].t <= cursor do fi = fi + 1 end
        vehicleFrameIdx[idx] = fi
        local f0             = rec.frames[fi]
        local f1             = rec.frames[math.min(fi + 1, #rec.frames)]
        local dt             = f1.t - f0.t
        local t              = dt > 0.001 and math.max(0.0, math.min(1.0, (cursor - f0.t) / dt)) or 0.0
        local px             = f0.px + (f1.px - f0.px) * t
        local py             = f0.py + (f1.py - f0.py) * t
        local pz             = f0.pz + (f1.pz - f0.pz) * t + (rec.suspensionDelta or 0.0)
        local vx             = f0.vx + (f1.vx - f0.vx) * t
        local vy             = f0.vy + (f1.vy - f0.vy) * t
        local vz             = f0.vz + (f1.vz - f0.vz) * t
        local rx             = lerpAngle(f0.rx, f1.rx, t)
        local ry             = lerpAngle(f0.ry, f1.ry, t)
        local rz             = lerpAngle(f0.rz, f1.rz, t)
        local st             = f0.steer + (f1.steer - f0.steer) * t
        local rpm            = f0.rpm and (f0.rpm + ((f1.rpm or f0.rpm) - f0.rpm) * t) or nil
        if IsEntityOnScreen(veh) then
            FreezeEntityPosition(veh, false)
            local correction = (vector3(px, py, pz) - GetEntityCoords(veh)) * 15.0
            SetEntityRotation(veh, rx, ry, rz, 2, true)
            SetVehicleSteeringAngle(veh, st)
            if rpm then SetVehicleCurrentRpm(veh, rpm) end
            if f0.handbrake ~= nil then SetVehicleHandbrake(veh, f0.handbrake == true) end
            SetEntityVelocity(veh, vector3(vx, vy, vz) + correction)
        else
            FreezeEntityPosition(veh, true)
            SetEntityCoordsNoOffset(veh, px, py, pz, false, false, false)
            SetEntityRotation(veh, rx, ry, rz, 2, true)
        end
        ::cont::
    end
end

local function spawnSinglePed(idx)
    if pedSpawnReady[idx] then return end
    pedSpawnReady[idx] = true
    local rec          = pedRecordings[idx]
    local model        = rec.pedModel
    RequestModel(model)
    CreateThread(function()
        if not waitForModel(model) then
            pedSpawnReady[idx] = false
            SetModelAsNoLongerNeeded(model)
            return
        end
        local f0  = rec.frames[1]
        local ped = CreatePed(4, model, f0.px or 0, f0.py or 0, f0.pz or 0, f0.rz or 0.0, false, false)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        if rec.appearance then applyPedAppearance(ped, rec.appearance) end
        SetModelAsNoLongerNeeded(model)
        pedSpawns[idx]     = ped
        pedSpawnReady[idx] = false
    end)
end

local function initPedRecording()
    for i = 1, #pedRecordings do
        pedSpawnReady[i] = false
        spawnSinglePed(i)
    end
end

local function previewPedAtFrame(frame)
    if #pedRecordings == 0 then return end
    local sec = frame / Config.DefaultFPS
    for idx, rec in ipairs(pedRecordings) do
        local ped = pedSpawns[idx]
        if not ped or not DoesEntityExist(ped) then goto cont end
        local endSec = trimEnd or (trimStart + rec.duration - trimIn)
        local cursor = sec - trimStart + trimIn
        if sec < trimStart or sec > endSec then
            FreezeEntityPosition(ped, true); goto cont
        end
        local f0, f1
        for fi = 1, #rec.frames - 1 do
            if rec.frames[fi].t <= cursor and rec.frames[fi + 1].t >= cursor then
                f0 = rec.frames[fi]; f1 = rec.frames[fi + 1]; break
            end
        end
        if not f0 then goto cont end
        local dt = f1.t - f0.t
        local t  = dt > 0.001 and math.max(0.0, math.min(1.0, (cursor - f0.t) / dt)) or 0.0
        if f0.inVehicle then
            local veh = vehicleSpawns[f0.vehRecIdx]
            if veh and DoesEntityExist(veh) then
                local seat = f0.seat or -1
                if GetPedInVehicleSeat(veh, seat) ~= ped then TaskWarpPedIntoVehicle(ped, veh, seat) end
            end
            goto cont
        end
        local px = f0.px + (f1.px - f0.px) * t
        local py = f0.py + (f1.py - f0.py) * t
        local pz = f0.pz + (f1.pz - f0.pz) * t
        FreezeEntityPosition(ped, false)
        SetEntityCoordsNoOffset(ped, px, py, pz, false, false, false)
        SetEntityHeading(ped, lerpAngle(f0.rz, f1.rz, t))
        if f0.weapon and f0.weapon ~= 0 then SetCurrentPedWeapon(ped, f0.weapon, true) end
        if f0.moveBlend then SetPedDesiredMoveBlendRatio(ped, f0.moveBlend) end
        ::cont::
    end
end

local function lerpEffects(a, b, t)
    a              = a or {}; b = b or {}
    local ad       = a.dof or {}; local bd = b.dof or {}
    local as       = a.shake or {}; local bs = b.shake or {}
    local af       = a.filter or {}; local bf = b.filter or {}
    local afade    = a.fade or {}; local bfade = b.fade or {}
    local fadeType = (afade.type and afade.type ~= "none") and afade.type or (bfade.type or "none")
    local filtId   = (af.id and af.id ~= "none") and af.id or (bf.id or "none")
    return {
        shake      = { type = as.type or "none", amplitude = lerpVal(as.amplitude or 0, bs.amplitude or 0, t) },
        dof        = {
            enabled  = ad.enabled or bd.enabled or false,
            near     = lerpVal(ad.near or 3.0, bd.near or 3.0, t),
            far      = lerpVal(ad.far or 50, bd.far or 50, t),
            fNumber  = lerpVal(ad.fNumber or 1.2, bd.fNumber or 1.2, t),
            strength = lerpVal(ad.strength or 1.0, bd.strength or 1.0, t),
        },
        motionBlur = lerpVal(a.motionBlur or 0, b.motionBlur or 0, t),
        timeScale  = lerpVal(a.timeScale or 1.0, b.timeScale or 1.0, t),
        filter     = { id = filtId, strength = lerpVal(af.strength or 1.0, bf.strength or 1.0, t) },
        fade       = { type = fadeType, amount = lerpVal(afade.amount or 0, bfade.amount or 0, t) },
        letterbox  = lerpVal(a.letterbox or 0, b.letterbox or 0, t),
        vignette   = lerpVal(a.vignette or 0, b.vignette or 0, t),
        grain      = lerpVal(a.grain or 0, b.grain or 0, t),
    }
end

local function interpolateKeyframes(frame)
    local kfs = keyframes
    if #kfs == 0 then return nil end
    if #kfs == 1 then
        local kf = kfs[1]
        return {
            pos = vector3(kf.pos.x, kf.pos.y, kf.pos.z),
            rot = vector3(kf.rot.x, kf.rot.y, kf.rot.z),
            fov = kf.fov,
            effects = kf.effects or {},
            time = (kf.time and kf.time.enabled and kf.time.value) or nil
        }
    end
    if frame >= kfs[#kfs].frame then return nil end
    if frame < kfs[1].frame then
        local kf = kfs[1]
        return {
            pos = vector3(kf.pos.x, kf.pos.y, kf.pos.z),
            rot = vector3(kf.rot.x, kf.rot.y, kf.rot.z),
            fov = kf.fov,
            effects = kf.effects or {},
            time = (kf.time and kf.time.enabled and kf.time.value) or nil
        }
    end
    local kfA, kfB
    for i = 1, #kfs - 1 do
        if frame >= kfs[i].frame and frame < kfs[i + 1].frame then
            kfA = kfs[i]; kfB = kfs[i + 1]; break
        end
    end
    if not kfA then return nil end
    local span   = kfB.frame - kfA.frame
    local t      = span > 0 and math.max(0, math.min(1, (frame - kfA.frame) / span)) or 0
    local easing = kfA.easing
    if easing == "cut" then
        return {
            pos = vector3(kfA.pos.x, kfA.pos.y, kfA.pos.z),
            rot = vector3(kfA.rot.x, kfA.rot.y, kfA.rot.z),
            fov = kfA.fov,
            effects = kfA.effects or {},
            time = (kfA.time and kfA.time.enabled and kfA.time.value) or nil,
            timeScale = (kfA.effects and kfA.effects.timeScale) or 1.0
        }
    elseif easing == "ease" then
        t = easeInOut(t)
    elseif easing == "easein" then
        t = easeIn(t)
    elseif easing == "easeout" then
        t = easeOut(t)
    end
    local timeA = (kfA.time and kfA.time.enabled and kfA.time.value) or nil
    local timeB = (kfB.time and kfB.time.enabled and kfB.time.value) or nil
    local interpTime = nil
    if timeA and timeB then
        interpTime = lerpTime(timeA, timeB, t)
    elseif timeA then
        interpTime = lerpTime(timeA, worldSettings.time, t)
    elseif timeB then
        interpTime = lerpTime(worldSettings.time, timeB, t)
    end
    return {
        pos     = lerpVec3(vector3(kfA.pos.x, kfA.pos.y, kfA.pos.z), vector3(kfB.pos.x, kfB.pos.y, kfB.pos.z), t),
        rot     = lerpRot(vector3(kfA.rot.x, kfA.rot.y, kfA.rot.z), vector3(kfB.rot.x, kfB.rot.y, kfB.rot.z), t),
        fov     = lerpVal(kfA.fov, kfB.fov, t),
        effects = lerpEffects(kfA.effects, kfB.effects, t),
        time    = interpTime,
    }
end

local function catmullRom(p0, p1, p2, p3, t)
    return 0.5 *
        ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t)
end

local function interpolateKeyframesSpline(frame)
    local kfs = keyframes
    if #kfs < 2 then return interpolateKeyframes(frame) end
    if frame >= kfs[#kfs].frame then return nil end
    if frame < kfs[1].frame then
        local kf = kfs[1]
        return {
            pos = vector3(kf.pos.x, kf.pos.y, kf.pos.z),
            rot = vector3(kf.rot.x, kf.rot.y, kf.rot.z),
            fov = kf.fov,
            effects =
                kf.effects or {}
        }
    end
    local iA = 1
    for i = 1, #kfs - 1 do
        if frame >= kfs[i].frame and frame < kfs[i + 1].frame then
            iA = i; break
        end
    end
    local iB   = iA + 1
    local span = kfs[iB].frame - kfs[iA].frame
    local t    = span > 0 and math.max(0, math.min(1, (frame - kfs[iA].frame) / span)) or 0
    local p0   = kfs[math.max(iA - 1, 1)]; local p1 = kfs[iA]; local p2 = kfs[iB]; local p3 = kfs
        [math.min(iB + 1, #kfs)]
    local function splineVec(a, b, c, d)
        return vector3(catmullRom(a.pos.x, b.pos.x, c.pos.x, d.pos.x, t), catmullRom(a.pos.y, b.pos.y, c.pos.y, d.pos.y,
            t), catmullRom(a.pos.z, b.pos.z, c.pos.z, d.pos.z, t))
    end
    local timeA = (p1.time and p1.time.enabled and p1.time.value) or nil
    local timeB = (p2.time and p2.time.enabled and p2.time.value) or nil
    local interpTime = nil
    if timeA and timeB then
        interpTime = lerpTime(timeA, timeB, t)
    elseif timeA then
        interpTime = lerpTime(timeA, worldSettings.time, t)
    elseif timeB then
        interpTime = lerpTime(worldSettings.time, timeB, t)
    end
    return {
        pos     = splineVec(p0, p1, p2, p3),
        rot     = lerpRot(vector3(p1.rot.x, p1.rot.y, p1.rot.z), vector3(p2.rot.x, p2.rot.y, p2.rot.z), t),
        fov     = lerpVal(p1.fov, p2.fov, t),
        effects = lerpEffects(p1.effects, p2.effects, t),
        time    = interpTime,
    }
end

local activeShakeType = nil
local activeFilterId  = nil

local function applyEffects(fx)
    fx = fx or {}
    local ts = fx.timeScale or 1.0
    if ts ~= 1.0 then SetTimeScale(ts) end
    local shake = fx.shake or {}
    if shake.type and shake.type ~= "none" and (shake.amplitude or 0) > 0 then
        if shake.type ~= activeShakeType then
            if activeShakeType then StopCamShaking(editorCam, true) end
            StartCamShaking(editorCam, shake.type, shake.amplitude)
            activeShakeType = shake.type
        else
            SetCamShakeAmplitude(editorCam, shake.amplitude)
        end
    elseif activeShakeType then
        StopCamShaking(editorCam, true); activeShakeType = nil
    end
    local dof = fx.dof or {}
    if dof.enabled then
        SetUseHiDof(); hiDofActive = true
        SetCamNearDof(editorCam, dof.near or 3.0)
        SetCamFarDof(editorCam, dof.far or 50.0)
        SetCamDofFnumber(editorCam, dof.fNumber or 1.2)
        SetCamDofStrength(editorCam, dof.strength or 1.0)
    else
        hiDofActive = false
    end
    local filter = fx.filter or {}
    local fid = filter.id or "none"
    if fid ~= "none" then
        if fid ~= activeFilterId then
            if activeFilterId then AnimpostfxStop(activeFilterId) end
            AnimpostfxPlay(fid, 0, true); activeFilterId = fid
        end
    elseif activeFilterId then
        AnimpostfxStop(activeFilterId); activeFilterId = nil
        SendNUIMessage({ type = "fxClear" })
    end
    SendNUIMessage({
        type      = "effectsUpdate",
        fade      = fx.fade or { type = "none", amount = 0 },
        letterbox = fx.letterbox or 0,
        vignette  = fx.vignette or 0,
        grain     = fx.grain or 0,
    })
end

local function sendCoordsUpdate()
    if not (editorCam and DoesCamExist(editorCam)) then return end
    local pos = GetCamCoord(editorCam)
    local rot = GetCamRot(editorCam, 2)
    SendNUIMessage({
        type = "coordsUpdate",
        pos = { x = pos.x, y = pos.y, z = pos.z },
        rot = { x = rot.x, y = rot.y, z = rot.z },
        fov = GetCamFov(editorCam)
    })
end

local function applyKeyframeState(state)
    if not state or not (editorCam and DoesCamExist(editorCam)) then return end
    SetCamCoord(editorCam, state.pos.x, state.pos.y, state.pos.z)
    SetCamRot(editorCam, state.rot.x, state.rot.y, state.rot.z, 2)
    SetCamFov(editorCam, normalizeFov(state.fov))
    applyEffects(state.effects or {})
    if state.time then
        applyGameTime(state.time)
    elseif worldSettings.freezeTime then
        applyGameTime(worldSettings.time)
    end
    sendCoordsUpdate()
end

local function jumpToFrame(frame)
    currentFrame = frame
    if not (editorCam and DoesCamExist(editorCam)) then return end
    local state = (interpSettings.mode == "spline" and interpolateKeyframesSpline(frame)) or interpolateKeyframes(frame)
    applyKeyframeState(state)
    if (#vehicleRecordings > 0 or #pedRecordings > 0) and state then
        SetEntityCoordsNoOffset(PlayerPedId(), state.pos.x, state.pos.y, state.pos.z, false, false, false)
    end
    previewVehicleAtFrame(frame)
    previewPedAtFrame(frame)
    previewOverlayAtFrame(frame)
end

local function stopPlayback(frame)
    playbackActive = false
    jumpToFrame(frame or currentFrame)
end

local inBucket           = false
local pathSharingEnabled = true
local cameraPropHandle   = nil
local cameraPropSyncMs   = 0
local tutorialAdder      = nil
local activeShakeType    = nil
local activeFilterId     = nil

local function detectWeatherConflicts()
    local patterns, conflicts = Config.WeatherConflictPatterns or {}, {}
    for i = 0, GetNumResources() - 1 do
        local res = GetResourceByFindIndex(i)
        if res and GetResourceState(res) == "started" then
            local lower = res:lower()
            for _, pat in ipairs(patterns) do
                if lower:find(pat) then
                    conflicts[#conflicts + 1] = res; break
                end
            end
        end
    end
    return conflicts
end

local function spawnCameraProp(pos)
    local model = GetHashKey("prop_pap_camera_01")
    RequestModel(model)
    CreateThread(function()
        local t = 0
        while not HasModelLoaded(model) and t < 100 do
            Wait(50); t = t + 1
        end
        if not HasModelLoaded(model) then return end
        if cameraPropHandle and DoesEntityExist(cameraPropHandle) then DeleteEntity(cameraPropHandle) end
        cameraPropHandle = CreateObject(model, pos.x, pos.y, pos.z, false, false, false)
        FreezeEntityPosition(cameraPropHandle, true)
        SetEntityInvincible(cameraPropHandle, true)
        SetEntityCollision(cameraPropHandle, false, false)
        SetModelAsNoLongerNeeded(model)
    end)
end

local function updateCameraProp()
    if not (editorCam and DoesCamExist(editorCam)) then return end
    if not (cameraPropHandle and DoesEntityExist(cameraPropHandle)) then return end
    local pos   = GetCamCoord(editorCam)
    local rot   = GetCamRot(editorCam, 2)
    local yaw   = math.rad(rot.z + 180.0)
    local pitch = math.rad(-rot.x)
    local fwd   = vector3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
    local rgt   = vector3(math.cos(yaw), math.sin(yaw), 0.0)
    local up    = vector3(math.sin(yaw) * math.sin(pitch), -math.cos(yaw) * math.sin(pitch), math.cos(pitch))
    SetEntityMatrix(cameraPropHandle, fwd, rgt, up, pos)
    if pathSharingEnabled then
        local now = GetGameTimer()
        if now - cameraPropSyncMs > 100 then
            cameraPropSyncMs = now
            TriggerServerEvent("core_cinematics:syncCameraPropPos", {
                fx = fwd.x,
                fy = fwd.y,
                fz = fwd.z,
                rx = rgt.x,
                ry = rgt.y,
                rz = rgt.z,
                ux = up.x,
                uy = up.y,
                uz = up.z,
                px = pos.x,
                py = pos.y,
                pz = pos.z,
            })
        end
    end
end

local function drawKeyframePath()
    if not uiOpen then return end
    if #keyframes < 2 then return end
    local distSq = (Config.PathDrawDistance or 150.0) ^ 2
    local origin = GetEntityCoords(PlayerPedId())
    for i = 1, #keyframes - 1 do
        local a, b = keyframes[i], keyframes[i + 1]
        if a.pos and b.pos then
            local da = (a.pos.x - origin.x) ^ 2 + (a.pos.y - origin.y) ^ 2 + (a.pos.z - origin.z) ^ 2
            local db = (b.pos.x - origin.x) ^ 2 + (b.pos.y - origin.y) ^ 2 + (b.pos.z - origin.z) ^ 2
            if da <= distSq or db <= distSq then
                DrawLine(a.pos.x, a.pos.y, a.pos.z, b.pos.x, b.pos.y, b.pos.z, 220, 50, 50, 200)
            end
        end
    end
    for _, kf in ipairs(keyframes) do
        if kf.pos then
            local d = (kf.pos.x - origin.x) ^ 2 + (kf.pos.y - origin.y) ^ 2 + (kf.pos.z - origin.z) ^ 2
            if d <= distSq then
                DrawMarker(28, kf.pos.x, kf.pos.y, kf.pos.z, 0, 0, 0, 0, 0, 0, 0.15, 0.15, 0.15, 245, 200, 60, 200, false,
                    true, 2, false, nil, nil, false)
            end
        end
    end
end

local function syncCameraPathToServer()
    if not pathSharingEnabled then return end
    local path = {}
    for _, kf in ipairs(keyframes) do
        if kf.pos then path[#path + 1] = { x = kf.pos.x, y = kf.pos.y, z = kf.pos.z } end
    end
    TriggerServerEvent("core_cinematics:syncCameraPath", path)
end

local function previewOverlayAtFrame(frame)
    if #overlayLayers == 0 then return end
    local fps = Config.DefaultFPS
    for i, layer in ipairs(overlayLayers) do
        local rec  = layer.vehicleRec
        local veh  = layer.vehicleSpawn
        local sec  = frame / fps
        local endS = layer.endSec or (layer.startSec + (rec and rec.duration or 0) - (layer.trimInSec or 0))
        if sec < layer.startSec or sec > endS then
            if veh and DoesEntityExist(veh) then
                DeleteEntity(veh); layer.vehicleSpawn = nil
            end
        else
            if not veh or not DoesEntityExist(veh) then
                spawnOverlayVehicle(i)
            else
                local cursor = (sec - layer.startSec) + (layer.trimInSec or 0)
                local frames = rec and rec.frames or {}
                local n      = #frames
                if n >= 2 then
                    local fi = layer.vehicleFrameIdx or 1
                    while fi < n - 1 and frames[fi + 1].t <= cursor do fi = fi + 1 end
                    layer.vehicleFrameIdx = fi
                    local f0, f1          = frames[fi], frames[math.min(fi + 1, n)]
                    local dt              = f1.t - f0.t
                    local t               = dt > 0.001 and math.max(0, math.min(1, (cursor - f0.t) / dt)) or 0
                    local px              = f0.px + (f1.px - f0.px) * t
                    local py              = f0.py + (f1.py - f0.py) * t
                    local pz              = f0.pz + (f1.pz - f0.pz) * t
                    FreezeEntityPosition(veh, false)
                    SetEntityCoordsNoOffset(veh, px, py, pz, false, false, false)
                    SetEntityRotation(veh, lerpAngle(f0.rx, f1.rx, t), lerpAngle(f0.ry, f1.ry, t),
                        lerpAngle(f0.rz, f1.rz, t), 2, true)
                    SetVehicleSteeringAngle(veh, f0.steer + (f1.steer - f0.steer) * t)
                    SetEntityVelocity(veh, 0, 0, 0)
                    FreezeEntityPosition(veh, true)
                end
            end
        end
    end
end

function spawnOverlayVehicle(idx)
    local layer = overlayLayers[idx]
    if not layer or layer.vehicleSpawning then return end
    if layer.vehicleSpawn and DoesEntityExist(layer.vehicleSpawn) then DeleteEntity(layer.vehicleSpawn) end
    local rec = layer.vehicleRec; local model = rec.vehicleModel
    layer.vehicleSpawning = true
    RequestModel(model)
    CreateThread(function()
        local t = 0
        while not HasModelLoaded(model) and t < 100 do
            Wait(50); t = t + 1
        end
        if not layer.vehicleSpawning then
            SetModelAsNoLongerNeeded(model); return
        end
        local f0 = rec.frames[1]
        local veh = CreateVehicle(model, f0.px, f0.py, f0.pz, f0.rz, false, false)
        SetEntityRotation(veh, f0.rx or 0, f0.ry or 0, f0.rz or 0, 2, true)
        SetEntityInvincible(veh, true); FreezeEntityPosition(veh, true)
        SetVehicleEngineOn(veh, true, true, false); SetVehicleLights(veh, 2)
        if rec.plate and rec.plate ~= "" then SetVehicleNumberPlateText(veh, rec.plate) end
        if rec.props then applyVehicleProps(veh, rec.props) end
        SetEntityMotionBlur(veh, motionBlurOn)
        SetModelAsNoLongerNeeded(model)
        layer.vehicleSpawn = veh; layer.vehicleSpawning = false; layer.vehicleFrameIdx = 1
    end)
end

function cleanupOverlaySpawns()
    for _, layer in ipairs(overlayLayers) do
        if layer.vehicleSpawn and DoesEntityExist(layer.vehicleSpawn) then DeleteEntity(layer.vehicleSpawn) end
        layer.vehicleSpawn = nil; layer.vehicleSpawning = false; layer.vehicleFrameIdx = 1
    end
end

function sendOverlayLayersToJS()
    local fps, list = Config.DefaultFPS, {}
    for _, layer in ipairs(overlayLayers) do
        local rec = layer.vehicleRec
        local name = GetDisplayNameFromVehicleModel(rec.vehicleModel)
        if name == "CARNOTFOUND" then name = tostring(rec.vehicleModel) end
        list[#list + 1] = {
            id = layer.id,
            name = layer.name,
            model = name:lower(),
            duration = rec.duration,
            totalFrames = math.floor(rec.duration * fps),
            startFrame = math.floor((layer.startSec or 0) * fps),
            endFrame = layer.endSec and math.floor(layer.endSec * fps) or nil,
            trimInFrame = math.floor((layer.trimInSec or 0) * fps),
        }
    end
    SendNUIMessage({ type = "overlayLayersLoaded", layers = list })
end

local function openUI()
    if uiOpen then return end
    uiOpen = true
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    playerSavedPos = { x = pos.x, y = pos.y, z = pos.z }
    playerSavedHead = GetEntityHeading(ped)
    local camPos = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local camFov = GetGameplayCamFov()
    editorCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(editorCam, camPos.x, camPos.y, camPos.z)
    SetCamRot(editorCam, camRot.x, camRot.y, camRot.z, 2)
    SetCamFov(editorCam, normalizeFov(camFov))
    RenderScriptCams(true, false, 0, true, true)
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "show",
        fps = Config.DefaultFPS,
        shakes = Config.ShakeTypes,
        filters = Config.ColorFilters,
        fonts = Config.Fonts,
        fovMin = Config.FovMin,
        fovMax = Config.FovMax,
        defaultFov = Config.DefaultFov,
        totalFrames = totalFrames,
        predefinedAnims = Config.PredefinedAnimations or {},
        commonWeapons = Config.CommonWeapons or {},
        tutorialDefault = Config.DisableTutorialByDefault ~= true,
        weatherConflicts = detectWeatherConflicts(),
        autosaveInterval = Config.AutosaveInterval or 30000,
        defaultInterp = Config.DefaultInterpolationMode or "eased",
        defaultEasing = Config.DefaultKeyframeEasing or "ease",
        locale = GetLocaleData and GetLocaleData() or {},
    })
    sendCoordsUpdate()
    local hasRec = #vehicleRecordings > 0 or #pedRecordings > 0 or #overlayLayers > 0
    if hasRec and not inBucket then
        TriggerServerEvent("core_cinematics:enterBucket"); inBucket = true
        TriggerServerEvent("core_cinematics:clearCameraPath")
    end
    if not inBucket then spawnCameraProp(camPos) end
    spawnVehicleRecording(); initPedRecording()
    if #overlayLayers > 0 then
        sendOverlayLayersToJS()
        for i = 1, #overlayLayers do spawnOverlayVehicle(i) end
    end
    syncCameraPathToServer()
end

local function closeUI()
    if not uiOpen then return end
    uiOpen = false; isFreecamMode = false
    for _, cam in ipairs(previewCams) do
        if cam and DoesCamExist(cam) then DestroyCam(cam, false) end
    end
    previewCams = {}; previewCamIdx = 1
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "hide" })
    SetTimeScale(1.0); ClearOverrideWeather(); SetRainLevel(0.0)
    hiDofActive = false
    if playerSavedPos then
        local ped = PlayerPedId()
        SetEntityCoordsNoOffset(ped, playerSavedPos.x, playerSavedPos.y, playerSavedPos.z, false, false, false)
        SetEntityHeading(ped, playerSavedHead or 0.0)
        playerSavedPos = nil; playerSavedHead = nil
    end
    RenderScriptCams(false, false, 0, true, true)
    if editorCam and DoesCamExist(editorCam) then
        DestroyCam(editorCam, false); editorCam = nil
    end
    if inBucket then
        TriggerServerEvent("core_cinematics:leaveBucket"); inBucket = false
        local ped = PlayerPedId()
        SetEntityVisible(ped, true, false); ResetEntityAlpha(ped)
        SetEntityCollision(ped, true, true); SetEntityLocallyInvisible(ped, false)
        SetLocalPlayerVisibleLocally(true)
    end
    for _, veh in pairs(vehicleSpawns) do if DoesEntityExist(veh) then DeleteEntity(veh) end end
    vehicleSpawns = {}; vehicleSpawnReady = {}; vehicleFrameIdx = {}
    for _, p in pairs(pedSpawns) do if DoesEntityExist(p) then DeleteEntity(p) end end
    pedSpawns = {}; pedSpawnReady = {}
    cleanupOverlaySpawns()
    if cameraPropHandle and DoesEntityExist(cameraPropHandle) then
        DeleteEntity(cameraPropHandle); cameraPropHandle = nil
    end
    if activeShakeType then
        StopCamShaking(nil, true); activeShakeType = nil
    end
    if activeFilterId then
        AnimpostfxStop(activeFilterId); activeFilterId = nil
    end
end

CreateThread(function()
    while true do
        Wait(0)
        if uiOpen then
            if worldSettings.freezeTime then applyGameTime(worldSettings.time) end
            if worldSettings.weatherOverride then SetOverrideWeather(worldSettings.weather) end
            SetRainLevel(worldSettings.rainEnabled and (worldSettings.rainLevel or 0) or 0)
            SetWindSpeed(worldSettings.windSpeed or 0)
            SetArtificialLightsState(worldSettings.cityLights or false)
            drawKeyframePath()
            updateCameraProp()
        end
    end
end)

RegisterNetEvent("core_cinematics:permOk")
RegisterNetEvent("core_cinematics:permDenied")
RegisterNetEvent("core_cinematics:cameraPathUpdated")
RegisterNetEvent("core_cinematics:cameraPathCleared")
RegisterNetEvent("core_cinematics:cameraPropMoved")

AddEventHandler("core_cinematics:permOk", function() openUI() end)
AddEventHandler("core_cinematics:permDenied", function() end)

AddEventHandler("core_cinematics:cameraPathUpdated", function(sid, path)
    if sid == GetPlayerServerId(PlayerId()) then return end
    if not otherPlayerPaths[sid] then otherPlayerPaths[sid] = {} end
    otherPlayerPaths[sid].path = path or {}
end)

AddEventHandler("core_cinematics:cameraPathCleared", function(sid)
    if sid == GetPlayerServerId(PlayerId()) then return end
    local e = otherPlayerPaths[sid]
    if e then
        if e.prop and DoesEntityExist(e.prop) then DeleteEntity(e.prop) end
        otherPlayerPaths[sid] = nil
    end
end)

AddEventHandler("core_cinematics:cameraPropMoved", function(sid, mx)
    if sid == GetPlayerServerId(PlayerId()) then return end
    if not otherPlayerPaths[sid] then otherPlayerPaths[sid] = {} end
    local e = otherPlayerPaths[sid]
    if not (e.prop and DoesEntityExist(e.prop)) then
        local model = GetHashKey("prop_pap_camera_01")
        RequestModel(model)
        CreateThread(function()
            local t = 0
            while not HasModelLoaded(model) and t < 100 do
                Wait(50); t = t + 1
            end
            local obj = CreateObject(model, mx.px, mx.py, mx.pz, false, false, false)
            FreezeEntityPosition(obj, true); SetEntityInvincible(obj, true); SetEntityCollision(obj, false, false)
            SetModelAsNoLongerNeeded(model); e.prop = obj
        end)
    end
    e.matrix = mx
end)

RegisterCommand("cinematics", function(_, args)
    local sub = args[1]
    if sub == "record" then
        startVehicleRecording()
    elseif sub == "stop" then
        stopVehicleRecording()
    elseif sub == "clear" then
        isRecording = false; vehicleRecordings = {}; pedRecordings = {}
        print(_L("lua.notify.recordings_cleared"))
    elseif sub == "preview" then
        if #keyframes < 2 then
            print(_L("lua.notify.preview_no_prop_or_keyframes")); return
        end
        if previewActive then
            previewActive = false; print(_L("lua.notify.preview_stopped")); return
        end
        previewActive = true
        print(_L("lua.notify.preview_started"))
        CreateThread(function()
            local fps = Config.DefaultFPS
            local startMs = GetGameTimer()
            local maxSec = keyframes[#keyframes].frame / fps
            while previewActive do
                Wait(0)
                local elapsed = (GetGameTimer() - startMs) / 1000.0
                if elapsed > maxSec then
                    previewActive = false; print(_L("lua.notify.preview_finished")); break
                end
                local state = (interpSettings.mode == "spline" and interpolateKeyframesSpline(elapsed * fps))
                    or interpolateKeyframes(elapsed * fps)
                if state and cameraPropHandle and DoesEntityExist(cameraPropHandle) then
                    local yaw = math.rad(state.rot.z + 180.0); local pitch = math.rad(-state.rot.x)
                    local fwd = vector3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch),
                        math.sin(pitch))
                    local rgt = vector3(math.cos(yaw), math.sin(yaw), 0.0)
                    local up = vector3(math.sin(yaw) * math.sin(pitch), -math.cos(yaw) * math.sin(pitch), math.cos(pitch))
                    SetEntityMatrix(cameraPropHandle, fwd, rgt, up, state.pos)
                end
            end
        end)
    else
        if uiOpen then closeUI() else TriggerServerEvent("core_cinematics:checkPerm") end
    end
end, false)

local function startPlayback(fromFrame, toFrame)
    if playbackActive then return end
    playbackActive = true
    currentFrame   = fromFrame or 0
    local fps      = Config.DefaultFPS
    local maxFrame = toFrame or totalFrames

    SetNuiFocus(false, false)
    HideHudAndRadarThisFrame()
    DisplayHud(false)
    DisplayRadar(false)
    TriggerServerEvent("core_cinematics:clearCameraPath")

    CreateThread(function()
        local startMs  = GetGameTimer()
        local startSec = currentFrame / fps

        while playbackActive do
            Wait(0)

            local elapsed = (GetGameTimer() - startMs) / 1000.0 + startSec
            local frame   = math.floor(elapsed * fps)

            if frame >= maxFrame then
                playbackActive = false
                currentFrame   = maxFrame
                DisplayHud(true); DisplayRadar(true)
                SetNuiFocus(true, true)
                SendNUIMessage({ type = "playbackFinished", frame = currentFrame })
                break
            end

            currentFrame = frame

            local state = (interpSettings.mode == "spline"
                    and interpolateKeyframesSpline(frame))
                or interpolateKeyframes(frame)

            if state and editorCam and DoesCamExist(editorCam) then
                SetCamCoord(editorCam, state.pos.x, state.pos.y, state.pos.z)
                SetCamRot(editorCam, state.rot.x, state.rot.y, state.rot.z, 2)
                SetCamFov(editorCam, normalizeFov(state.fov))
                applyEffects(state.effects or {})
                if state.time then
                    applyGameTime(state.time)
                elseif worldSettings.freezeTime then
                    applyGameTime(worldSettings.time)
                end
            end

            previewVehicleAtFrame(frame)
            previewPedAtFrame(frame)
            previewOverlayAtFrame(frame)

            local nowMs = math.floor(elapsed * 2)
            local preMs = math.floor((elapsed - 0.033) * 2)
            if nowMs > preMs then
                SendNUIMessage({ type = "playbackTick", frame = frame })
            end
        end
    end)
end

local function spawnSingleVehicle(layerIdx)
    local layer = overlayLayers[layerIdx]
    if not layer or layer.vehicleSpawning then return end
    spawnOverlayVehicle(layerIdx)
end

local soloRecActive   = false
local soloRecLayerIdx = nil

local function beginSoloRecording(layerIdx)
    if soloRecActive then return end
    local layer = overlayLayers[layerIdx]
    if not layer then return end

    soloRecActive    = true
    soloRecLayerIdx  = layerIdx

    local rec        = { vehicleModel = 0, plate = "", props = nil, frames = {}, duration = 0.0 }
    layer.vehicleRec = rec
    SendNUIMessage({ type = "recordingStarted", layerIdx = layerIdx })

    local stopKey = Config.RecordingStopKey or 177

    CreateThread(function()
        local startMs = GetGameTimer()
        while soloRecActive and soloRecLayerIdx == layerIdx do
            Wait(33)
            local elapsed = (GetGameTimer() - startMs) / 1000.0
            if not soloRecActive then break end

            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then
                if rec.vehicleModel == 0 then
                    rec.vehicleModel = GetEntityModel(veh)
                    rec.plate        = GetVehicleNumberPlateText(veh)
                    rec.props        = captureVehicleProps(veh)
                end
                local pos = GetEntityCoords(veh)
                local rot = GetEntityRotation(veh, 2)
                local vel = GetEntityVelocity(veh)
                table.insert(rec.frames, {
                    t     = elapsed,
                    px    = pos.x,
                    py    = pos.y,
                    pz    = pos.z,
                    rx    = rot.x,
                    ry    = rot.y,
                    rz    = rot.z,
                    vx    = vel.x,
                    vy    = vel.y,
                    vz    = vel.z,
                    steer = GetVehicleSteeringAngle(veh),
                    rpm   = GetVehicleCurrentRpm(veh),
                    horn  = IsHornActive(veh),
                })
                rec.duration = elapsed

                local nowH   = math.floor(elapsed * 2)
                local prevH  = math.floor((elapsed - 0.033) * 2)
                if nowH > prevH then SendNUIMessage({ type = "recordingTick", elapsed = elapsed }) end
            end
        end
    end)

    CreateThread(function()
        while soloRecActive and soloRecLayerIdx == layerIdx do
            DisableControlAction(0, stopKey, true)
            if IsControlJustPressed(0, stopKey) or IsDisabledControlJustPressed(0, stopKey) then
                stopSoloRecording()
                return
            end
            Wait(0)
        end
    end)
end

function stopSoloRecording()
    if not soloRecActive then return end
    soloRecActive = false
    local idx = soloRecLayerIdx
    soloRecLayerIdx = nil

    SendNUIMessage({ type = "recordingStopped" })

    if not idx then return end
    local layer = overlayLayers[idx]
    if not layer then return end

    local rec = layer.vehicleRec
    if not rec or #rec.frames < 2 then
        table.remove(overlayLayers, idx)
        return
    end

    sendOverlayLayersToJS()
    spawnOverlayVehicle(idx)
end

RegisterNetEvent("core_cinematics:projectList")
RegisterNetEvent("core_cinematics:projectLoaded")
RegisterNetEvent("core_cinematics:projectLoadError")
RegisterNetEvent("core_cinematics:projectSaved")
RegisterNetEvent("core_cinematics:projectDeleted")
RegisterNetEvent("core_cinematics:loadRecording")

AddEventHandler("core_cinematics:projectList", function(list)
    SendNUIMessage({ type = "projectList", projects = list })
end)

AddEventHandler("core_cinematics:projectLoaded", function(raw)
    
    for _, veh in pairs(vehicleSpawns) do if DoesEntityExist(veh) then DeleteEntity(veh) end end
    for _, ped in pairs(pedSpawns) do if DoesEntityExist(ped) then DeleteEntity(ped) end end
    vehicleSpawns = {}; vehicleSpawnReady = {}; vehicleFrameIdx = {}
    pedSpawns = {}; pedSpawnReady = {}
    cleanupOverlaySpawns()
    overlayLayers = {}

    local ok, data = pcall(json.decode, raw)
    if ok and data then
        vehicleRecordings = {}; pedRecordings = {}
        trimStart         = data.vehicleRecStartSec or 0.0
        trimEnd           = data.vehicleRecEndSec
        trimIn            = data.vehicleRecTrimInSec or 0.0

        if data.hasRecording then
            SendNUIMessage({ type = "recLoading" })
            if uiOpen and not inBucket then
                TriggerServerEvent("core_cinematics:enterBucket"); inBucket = true
                TriggerServerEvent("core_cinematics:clearCameraPath")
            end
        elseif inBucket then
            TriggerServerEvent("core_cinematics:leaveBucket"); inBucket = false
        end

        data.vehicleRecordings   = nil
        data.pedRecordings       = nil
        data.vehicleRecStartSec  = nil
        data.vehicleRecEndSec    = nil
        data.vehicleRecTrimInSec = nil
        raw                      = json.encode(data) or raw
    end

    SendNUIMessage({ type = "projectLoaded", data = raw })
end)

AddEventHandler("core_cinematics:projectLoadError", function(msg)
    SendNUIMessage({ type = "projectLoadError", msg = msg })
end)

AddEventHandler("core_cinematics:projectSaved", function(slug)
    SendNUIMessage({ type = "projectSaved", slug = slug })
end)

AddEventHandler("core_cinematics:projectDeleted", function(slug)
    SendNUIMessage({ type = "projectDeleted", slug = slug })
end)

AddEventHandler("core_cinematics:loadRecording", function(raw)
    SendNUIMessage({ type = "recLoaded" })
    if type(raw) ~= "string" or #raw == 0 then return end
    local ok, data = pcall(json.decode, raw)
    if not ok or not data then return end

    if data.vehicleRecordings and #data.vehicleRecordings > 0 then vehicleRecordings = data.vehicleRecordings end
    if data.pedRecordings and #data.pedRecordings > 0 then pedRecordings = data.pedRecordings end

    if data.overlayLayers and #data.overlayLayers > 0 then
        overlayLayers = {}
        for i, layer in ipairs(data.overlayLayers) do
            overlayLayers[i] = {
                id              = layer.id,
                name            = layer.name,
                vehicleRec      = layer.vehicleRec,
                startSec        = layer.startSec or 0.0,
                endSec          = layer.endSec,
                trimInSec       = layer.trimInSec or 0.0,
                vehicleSpawn    = nil,
                vehicleSpawning = false,
                vehicleFrameIdx = 1,
            }
        end
    end

    local hasRec = #vehicleRecordings > 0 or #pedRecordings > 0 or #overlayLayers > 0
    if hasRec and uiOpen and not inBucket then
        TriggerServerEvent("core_cinematics:enterBucket"); inBucket = true
        TriggerServerEvent("core_cinematics:clearCameraPath")
    end

    if #vehicleRecordings > 0 then spawnVehicleRecording() end
    if #pedRecordings > 0 then initPedRecording() end
    if #overlayLayers > 0 then
        sendOverlayLayersToJS()
        for i = 1, #overlayLayers do spawnOverlayVehicle(i) end
    end
end)

RegisterNUICallback("close", function(_, cb)
    closeUI(); cb("ok")
end)

RegisterNUICallback("listProjects", function(_, cb)
    TriggerServerEvent("core_cinematics:listProjects"); cb("ok")
end)

RegisterNUICallback("loadProject", function(data, cb)
    TriggerServerEvent("core_cinematics:loadProject", data.slug); cb("ok")
end)

RegisterNUICallback("saveProject", function(data, cb)
    TriggerServerEvent("core_cinematics:saveProject", data); cb("ok")
end)

RegisterNUICallback("saveProjectMetadata", function(data, cb)
    data.vehicleRecStartSec  = trimStart
    data.vehicleRecEndSec    = trimEnd
    data.vehicleRecTrimInSec = trimIn
    data.hasRecording        = #vehicleRecordings > 0

    local timings            = {}
    for i, layer in ipairs(overlayLayers) do
        timings[i] = {
            id = layer.id,
            name = layer.name,
            startSec = layer.startSec or 0.0,
            endSec = layer.endSec,
            trimInSec =
                layer.trimInSec or 0.0
        }
    end
    data.overlayLayerTimings = timings
    TriggerServerEvent("core_cinematics:saveProject", data)
    cb("ok")
end)

RegisterNUICallback("saveProjectWithRecordings", function(data, cb)
    data.vehicleRecStartSec  = trimStart
    data.vehicleRecEndSec    = trimEnd
    data.vehicleRecTrimInSec = trimIn
    TriggerServerEvent("core_cinematics:saveProject", data)
    if #vehicleRecordings > 0 or #pedRecordings > 0 or #overlayLayers > 0 then
        local function serializeOverlay()
            local t = {}
            for i, layer in ipairs(overlayLayers) do
                t[i] = {
                    id = layer.id,
                    name = layer.name,
                    vehicleRec = layer.vehicleRec,
                    startSec = layer.startSec,
                    endSec =
                        layer.endSec,
                    trimInSec = layer.trimInSec
                }
            end
            return t
        end
        local payload = json.encode({
            vehicleRecordings = vehicleRecordings,
            pedRecordings = pedRecordings,
            overlayLayers =
                serializeOverlay()
        })
        TriggerLatentServerEvent("core_cinematics:saveRecording", 500000, data.slug, payload)
    end
    cb("ok")
end)

RegisterNUICallback("deleteProject", function(data, cb)
    TriggerServerEvent("core_cinematics:deleteProject", data.slug); cb("ok")
end)

RegisterNUICallback("startPositionMode", function(_, cb)
    isFreecamMode = true
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "positionModeOn" })
    cb("ok")
end)

RegisterNUICallback("exitPositionMode", function(_, cb)
    isFreecamMode = false
    SetNuiFocus(true, true)
    SendNUIMessage({ type = "positionCancelled" })
    sendCoordsUpdate()
    cb("ok")
end)

RegisterNUICallback("startPlayback", function(data, cb)
    startPlayback(data.fromFrame or 0, data.totalFrames or totalFrames)
    cb("ok")
end)

RegisterNUICallback("stopPlayback", function(_, cb)
    stopPlayback(); cb("ok")
end)

RegisterNUICallback("jumpToFrame", function(data, cb)
    jumpToFrame(data.frame or 0); cb("ok")
end)

RegisterNUICallback("setPathSharing", function(data, cb)
    pathSharingEnabled = data.enabled == true
    if pathSharingEnabled then
        syncCameraPathToServer()
    else
        TriggerServerEvent("core_cinematics:clearCameraPath")
    end
    cb("ok")
end)

RegisterNUICallback("setKeyframes", function(data, cb)
    keyframes   = data.keyframes or {}
    totalFrames = data.totalFrames or totalFrames
    syncCameraPathToServer()
    cb("ok")
end)

RegisterNUICallback("setInterpSettings", function(data, cb)
    interpSettings.mode    = data.mode or "native"
    interpSettings.tension = tonumber(data.tension) or 0.0
    interpSettings.spring  = tonumber(data.spring) or 0.0
    cb("ok")
end)

RegisterNUICallback("setWorldSettings", function(data, cb)
    worldSettings.time            = tonumber(data.time) or worldSettings.time
    worldSettings.freezeTime      = data.freezeTime == true
    worldSettings.weather         = data.weather or worldSettings.weather
    worldSettings.weatherOverride = data.weatherOverride ~= false
    worldSettings.rainEnabled     = data.rainEnabled == true
    worldSettings.rainLevel       = tonumber(data.rainLevel) or 0.0
    worldSettings.windSpeed       = tonumber(data.windSpeed) or worldSettings.windSpeed
    worldSettings.cityLights      = data.cityLights == true
    if worldSettings.weatherOverride then
        SetOverrideWeather(worldSettings.weather)
    else
        ClearOverrideWeather()
    end
    SetRainLevel(worldSettings.rainEnabled and worldSettings.rainLevel or 0.0)
    SetWindSpeed(worldSettings.windSpeed)
    SetArtificialLightsState(worldSettings.cityLights)
    applyGameTime(worldSettings.time)
    cb("ok")
end)

RegisterNUICallback("previewKeyframe", function(data, cb)
    local kf = data.keyframe
    if not kf then
        cb("ok"); return
    end
    if not (editorCam and DoesCamExist(editorCam)) then
        local cp = GetGameplayCamCoord(); local cr = GetGameplayCamRot(2); local cf = GetGameplayCamFov()
        editorCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(editorCam, cp.x, cp.y, cp.z)
        SetCamRot(editorCam, cr.x, cr.y, cr.z, 2)
        SetCamFov(editorCam, normalizeFov(cf))
        RenderScriptCams(true, false, 0, true, true)
    end
    SetCamActive(editorCam, true)
    SetCamCoord(editorCam, kf.pos.x, kf.pos.y, kf.pos.z)
    SetCamRot(editorCam, kf.rot.x, kf.rot.y, kf.rot.z, 2)
    SetCamFov(editorCam, normalizeFov(kf.fov))
    applyEffects(kf.effects or {})
    sendCoordsUpdate()
    cb("ok")
end)

RegisterNUICallback("setMotionBlur", function(data, cb)
    motionBlurOn = data.enabled == true
    for _, veh in pairs(vehicleSpawns) do SetEntityMotionBlur(veh, motionBlurOn) end
    for _, ped in pairs(pedSpawns) do SetEntityMotionBlur(ped, motionBlurOn) end
    for _, layer in ipairs(overlayLayers) do
        if layer.vehicleSpawn and DoesEntityExist(layer.vehicleSpawn) then
            SetEntityMotionBlur(layer.vehicleSpawn,
                motionBlurOn)
        end
    end
    cb("ok")
end)

RegisterNUICallback("setVehicleTrimRange", function(data, cb)
    trimStart = tonumber(data.startSec) or trimStart
    trimEnd   = tonumber(data.endSec) or trimEnd
    trimIn    = tonumber(data.trimInSec) or trimIn
    cb("ok")
end)

RegisterNUICallback("setOverlayLayerTiming", function(data, cb)
    local layer = overlayLayers[data.layerIdx]
    if layer then
        layer.startSec  = tonumber(data.startSec) or layer.startSec
        layer.endSec    = tonumber(data.endSec)
        layer.trimInSec = tonumber(data.trimInSec) or layer.trimInSec
    end
    cb("ok")
end)

RegisterNUICallback("addOverlayLayer", function(data, cb)
    local id                          = data.id or tostring(#overlayLayers + 1)
    local name                        = data.name or ("Layer " .. (#overlayLayers + 1))
    local newLayer                    = { id = id, name = name, vehicleRec = { vehicleModel = 0, frames = {}, duration = 0 }, startSec = 0.0, endSec = nil, trimInSec = 0.0, vehicleSpawn = nil, vehicleSpawning = false, vehicleFrameIdx = 1 }
    overlayLayers[#overlayLayers + 1] = newLayer
    sendOverlayLayersToJS()
    cb("ok")
end)

RegisterNUICallback("removeOverlayLayer", function(data, cb)
    local idx = data.layerIdx
    if idx and overlayLayers[idx] then
        local layer = overlayLayers[idx]
        if layer.vehicleSpawn and DoesEntityExist(layer.vehicleSpawn) then DeleteEntity(layer.vehicleSpawn) end
        table.remove(overlayLayers, idx)
        sendOverlayLayersToJS()
    end
    cb("ok")
end)

RegisterNUICallback("beginSoloRecording", function(data, cb)
    beginSoloRecording(data.layerIdx)
    cb("ok")
end)

RegisterNUICallback("stopSoloRecording", function(_, cb)
    stopSoloRecording(); cb("ok")
end)

RegisterNUICallback("tutorialSpawnAdder", function(_, cb)
    CreateThread(function()
        local model = -1216765807
        RequestModel(model)
        local t = 0
        while not HasModelLoaded(model) and t < 250 do
            Wait(20); t = t + 1
        end
        if not HasModelLoaded(model) then
            cb("fail"); return
        end
        local ped  = PlayerPedId()
        local pos  = GetEntityCoords(ped)
        local head = GetEntityHeading(ped)
        if tutorialAdder and DoesEntityExist(tutorialAdder) then DeleteEntity(tutorialAdder) end
        tutorialAdder = CreateVehicle(model, pos.x, pos.y, pos.z, head, true, false)
        SetEntityAsMissionEntity(tutorialAdder, true, true)
        SetVehicleOnGroundProperly(tutorialAdder)
        TaskWarpPedIntoVehicle(ped, tutorialAdder, -1)
        SetModelAsNoLongerNeeded(model)
        Wait(300)
        cb("ok")
    end)
end)

RegisterNUICallback("tutorialDespawnAdder", function(_, cb)
    if tutorialAdder and DoesEntityExist(tutorialAdder) then
        local pos = GetEntityCoords(tutorialAdder)
        SendNUIMessage({ type = "tutorialAdderPos", pos = { x = pos.x, y = pos.y, z = pos.z } })
        DeleteEntity(tutorialAdder)
    end
    tutorialAdder = nil
    cb("ok")
end)

RegisterNUICallback("tutorialReopenUI", function(_, cb)
    if not uiOpen then openUI() end
    cb("ok")
end)

RegisterNUICallback("tutorialCarPosAtFrame", function(data, cb)
    local frame = tonumber(data.frame) or 0
    local rec   = vehicleRecordings[1]
    if not rec or #rec.frames == 0 then
        cb({ ok = false }); return
    end

    local fps    = Config.DefaultFPS or 30
    local cursor = frame / fps - trimStart + trimIn
    if cursor < 0 then cursor = 0 end

    local frames = rec.frames
    local last   = frames[#frames]
    if cursor > last.t then
        cb({ ok = true, x = last.px, y = last.py, z = last.pz }); return
    end

    for i = 1, #frames - 1 do
        local f0, f1 = frames[i], frames[i + 1]
        if cursor >= f0.t and cursor <= f1.t then
            local dt = f1.t - f0.t
            local t  = dt > 0 and math.max(0, math.min(1, (cursor - f0.t) / dt)) or 0
            cb({
                ok = true,
                x = f0.px + (f1.px - f0.px) * t,
                y = f0.py + (f1.py - f0.py) * t,
                z = f0.pz +
                    (f1.pz - f0.pz) * t
            })
            return
        end
    end
    local f0 = frames[1]
    cb({ ok = true, x = f0.px, y = f0.py, z = f0.pz })
end)

local sceneEntities  = {} 
local sceneFollowing = {} 
local textObjects    = {} 
local textDefs       = {} 
local textClips      = {} 
local fontUrls       = Config.Fonts or {}

local function deleteSceneEntity(entityId)
    local e = sceneEntities[entityId]
    if not e then return end
    e.followGen = (e.followGen or 0) + 1
    sceneFollowing[entityId] = nil
    if e.driverPed and DoesEntityExist(e.driverPed) then DeleteEntity(e.driverPed) end
    if e.entityHandle and DoesEntityExist(e.entityHandle) then DeleteEntity(e.entityHandle) end
    sceneEntities[entityId] = nil
end

RegisterNUICallback("spawnScenePed", function(data, cb)
    local id    = data.entityId
    local model = GetHashKey(data.model)
    local pos   = data.pos or { x = 0, y = 0, z = 0 }

    RequestModel(model)
    CreateThread(function()
        local t = 0
        while not HasModelLoaded(model) and t < 100 do
            Wait(50); t = t + 1
        end
        if not HasModelLoaded(model) then
            SendNUIMessage({
                type = "sceneSpawnError",
                id = id,
                msg = _L("lua.errors.model_not_found",
                    { model = data.model })
            })
            return
        end
        local ped = CreatePed(4, model, pos.x, pos.y, pos.z, data.heading or 0.0, false, false)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetModelAsNoLongerNeeded(model)
        sceneEntities[id] = { type = "ped", entityHandle = ped, followGen = 0 }
        local finalPos = GetEntityCoords(ped)
        SendNUIMessage({ type = "sceneEntitySpawned", id = id, pos = { x = finalPos.x, y = finalPos.y, z = finalPos.z } })
        cb("ok")
    end)
end)

RegisterNUICallback("spawnSceneVehicle", function(data, cb)
    local id    = data.entityId
    local model = GetHashKey(data.model)
    local pos   = data.pos or { x = 0, y = 0, z = 0 }

    RequestModel(model)
    CreateThread(function()
        local t = 0
        while not HasModelLoaded(model) and t < 100 do
            Wait(50); t = t + 1
        end
        if not HasModelLoaded(model) then
            SendNUIMessage({
                type = "sceneSpawnError",
                id = id,
                msg = _L("lua.errors.model_not_found",
                    { model = data.model })
            })
            cb("ok"); return
        end
        local gz, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 5.0, false)
        local spawnZ = gz and (groundZ + 0.5) or pos.z
        local veh = CreateVehicle(model, pos.x, pos.y, spawnZ, data.heading or 0.0, false, false)
        SetEntityInvincible(veh, true)
        FreezeEntityPosition(veh, true)
        SetVehicleOnGroundProperly(veh)
        SetModelAsNoLongerNeeded(model)
        sceneEntities[id] = { type = "vehicle", entityHandle = veh, followGen = 0, followDist = 10.0, followSpeed = 25.0, driveStyle = 786603 }
        local finalPos = GetEntityCoords(veh)
        SendNUIMessage({ type = "sceneEntitySpawned", id = id, pos = { x = finalPos.x, y = finalPos.y, z = finalPos.z } })
        cb("ok")
    end)
end)

RegisterNUICallback("spawnSceneProp", function(data, cb)
    local id    = data.entityId
    local model = GetHashKey(data.model)
    local pos   = data.pos or { x = 0, y = 0, z = 0 }

    RequestModel(model)
    CreateThread(function()
        local t = 0
        while not HasModelLoaded(model) and t < 100 do
            Wait(50); t = t + 1
        end
        if not HasModelLoaded(model) then
            SendNUIMessage({
                type = "sceneSpawnError",
                id = id,
                msg = _L("lua.errors.model_not_found",
                    { model = data.model })
            })
            cb("ok"); return
        end
        local obj = CreateObject(model, pos.x, pos.y, pos.z, false, false, false)
        FreezeEntityPosition(obj, true)
        SetEntityInvincible(obj, true)
        PlaceObjectOnGroundProperly(obj)
        SetModelAsNoLongerNeeded(model)
        sceneEntities[id] = { type = "prop", entityHandle = obj, followGen = 0 }
        local finalPos = GetEntityCoords(obj)
        SendNUIMessage({ type = "sceneEntitySpawned", id = id, pos = { x = finalPos.x, y = finalPos.y, z = finalPos.z } })
        cb("ok")
    end)
end)

RegisterNUICallback("deleteSceneEntity", function(data, cb)
    deleteSceneEntity(data.entityId); cb("ok")
end)

RegisterNUICallback("scenePlayAnim", function(data, cb)
    local e = sceneEntities[data.entityId]
    if not e or not (e.entityHandle and DoesEntityExist(e.entityHandle)) then
        cb("ok"); return
    end

    local dict, name, loop = data.dict, data.name, data.loop
    RequestAnimDict(dict)
    CreateThread(function()
        local t = 0
        while not HasAnimDictLoaded(dict) and t < 100 do
            Wait(50); t = t + 1
        end
        if not HasAnimDictLoaded(dict) then
            SendNUIMessage({ type = "sceneSpawnError", msg = _L("lua.errors.anim_dict_not_found", { dict = dict }) })
            return
        end
        FreezeEntityPosition(e.entityHandle, false)
        local flags = loop and 1 or 0
        TaskPlayAnim(e.entityHandle, dict, name, 8.0, -8.0, -1, flags, 0, false, false, false)
    end)
    cb("ok")
end)

RegisterNUICallback("sceneGiveWeapon", function(data, cb)
    local e = sceneEntities[data.entityId]
    if not e or e.type ~= "ped" or not (e.entityHandle and DoesEntityExist(e.entityHandle)) then
        cb("ok"); return
    end
    local hash = data.weaponHash
    GiveWeaponToPed(e.entityHandle, hash, 999, false, true)
    SetCurrentPedWeapon(e.entityHandle, hash, true)
    cb("ok")
end)

RegisterNUICallback("sceneSetFollow", function(data, cb)
    local id = data.entityId
    local e  = sceneEntities[id]
    if not e or not (e.entityHandle and DoesEntityExist(e.entityHandle)) then
        cb("ok"); return
    end

    e.followDist  = data.dist or e.followDist or 5.0
    e.followSpeed = data.speed or e.followSpeed or 1.0

    if data.follow then
        FreezeEntityPosition(e.entityHandle, false)
        SetBlockingOfNonTemporaryEvents(e.entityHandle, false)
        SetPedFleeAttributes(e.entityHandle, 0, false)
        SetPedCombatAttributes(e.entityHandle, 46, true)
        SetPedKeepTask(e.entityHandle, true)
        if sceneFollowing[id] then
            cb("ok"); return
        end
        sceneFollowing[id] = true
        CreateThread(function()
            local lastSpeed = nil
            while sceneFollowing[id] do
                if not (e.entityHandle and DoesEntityExist(e.entityHandle)) then break end
                local speed = e.followSpeed or 1.0
                local dist  = e.followDist or 5.0
                if lastSpeed ~= speed then
                    ClearPedTasks(e.entityHandle)
                    TaskGoToEntity(e.entityHandle, PlayerPedId(), -1, dist, speed, 1073741824, 0)
                    lastSpeed = speed
                end
                Wait(1000)
            end
        end)
    else
        sceneFollowing[id] = nil
        ClearPedTasksImmediately(e.entityHandle)
        FreezeEntityPosition(e.entityHandle, true)
        SetBlockingOfNonTemporaryEvents(e.entityHandle, true)
    end
    cb("ok")
end)

RegisterNUICallback("sceneUpdatePedFollowSettings", function(data, cb)
    local e = sceneEntities[data.entityId]
    if e then
        e.followDist  = data.dist or e.followDist
        e.followSpeed = data.speed or e.followSpeed
    end
    cb("ok")
end)

RegisterNUICallback("sceneSetVehicleFollow", function(data, cb)
    local id = data.entityId
    local e  = sceneEntities[id]
    if not e or e.type ~= "vehicle" or not (e.entityHandle and DoesEntityExist(e.entityHandle)) then
        cb("ok"); return
    end

    e.followSpeed = data.speed or e.followSpeed or 25.0
    e.followDist  = data.dist or e.followDist or 10.0
    e.driveStyle  = data.driveStyle or e.driveStyle or 786603
    e.followGen   = (e.followGen or 0) + 1

    local gen     = e.followGen
    if e.driverPed and DoesEntityExist(e.driverPed) then
        DeleteEntity(e.driverPed); e.driverPed = nil
    end

    if data.follow then
        sceneFollowing[id] = true
        FreezeEntityPosition(e.entityHandle, false)
        SetVehicleDoorsLocked(e.entityHandle, 0)
        SetVehicleEngineOn(e.entityHandle, true, true, false)

        local driverModel = GetHashKey("s_m_y_cop_01")
        RequestModel(driverModel)
        CreateThread(function()
            local t = 0
            while not HasModelLoaded(driverModel) and t < 100 do
                Wait(50); t = t + 1
            end
            if e.followGen ~= gen or not DoesEntityExist(e.entityHandle) then
                SetModelAsNoLongerNeeded(driverModel); return
            end

            local driver = CreatePedInsideVehicle(e.entityHandle, 4, driverModel, -1, false, false)
            if not driver or driver == 0 then
                Wait(500)
                if e.followGen ~= gen then
                    SetModelAsNoLongerNeeded(driverModel); return
                end
                driver = CreatePedInsideVehicle(e.entityHandle, 4, driverModel, -1, false, false)
            end
            SetModelAsNoLongerNeeded(driverModel)
            if not driver or driver == 0 then return end
            if e.followGen ~= gen then
                DeleteEntity(driver); return
            end

            SetEntityInvincible(driver, true)
            SetEntityVisible(driver, false, false)
            SetBlockingOfNonTemporaryEvents(driver, true)
            SetPedKeepTask(driver, true)
            e.driverPed = driver

            Wait(200)
            local lastSpeed, lastStyle = nil, nil
            while sceneFollowing[id] and e.followGen == gen do
                if not (DoesEntityExist(e.entityHandle) and DoesEntityExist(driver)) then break end
                local speed = e.followSpeed or 25.0
                local style = e.driveStyle or 786603
                if lastSpeed ~= speed or lastStyle ~= style then
                    ClearPedTasks(driver)
                    SetDriverAbility(driver, 1.0)
                    SetDriverAggressiveness(driver, 1.0)
                    TaskVehicleChase(driver, PlayerPedId())
                    SetTaskVehicleChaseBehaviorFlag(driver, 1, true)
                    SetTaskVehicleChaseIdealPursuitDistance(driver, e.followDist or 10.0)
                    ModifyVehicleTopSpeed(e.entityHandle, speed / 25.0)
                    lastSpeed = speed; lastStyle = style
                end
                Wait(1000)
            end
            if e.followGen ~= gen and DoesEntityExist(driver) then DeleteEntity(driver) end
            if e.driverPed == driver then e.driverPed = nil end
        end)
    else
        sceneFollowing[id] = nil
        if DoesEntityExist(e.entityHandle) then
            FreezeEntityPosition(e.entityHandle, true)
            SetVehicleDoorsLocked(e.entityHandle, 2)
        end
    end
    cb("ok")
end)

RegisterNUICallback("sceneUpdateVehicleFollowSettings", function(data, cb)
    local e = sceneEntities[data.entityId]
    if e then
        e.followSpeed = data.speed or e.followSpeed
        e.followDist  = data.dist or e.followDist
        e.driveStyle  = data.driveStyle or e.driveStyle
    end
    cb("ok")
end)

local function createTextObject(def)
    local id     = def.id
    local text   = def.text or "Text"
    local size   = def.size or 4.0
    local charW  = math.max(0.5, (#text * 0.22 + 1.5) * size)
    local charH  = charW * 0.125

    local url    = "https://cfx-nui-core_cinematics/html/textdui/text.html"
    local dui    = CreateDui(url, 2048, 256)
    local handle = GetDuiHandle(dui)
    local txd    = "cc_text_txd_" .. id
    local txn    = "cc_text_txn_" .. id
    local rtxd   = CreateRuntimeTxd(txd)
    CreateRuntimeTextureFromDuiHandle(rtxd, txn, handle)

    textObjects[id] = {
        dui         = dui,
        txdName     = txd,
        txnName     = txn,
        worldWidth  = charW,
        worldHeight = charH,
        visible     = false,
    }

    Citizen.CreateThread(function()
        local t = 0
        while not IsDuiAvailable(dui) and t < 100 do
            Citizen.Wait(100); t = t + 1
        end
        Citizen.Wait(300)
        if not textObjects[id] or textObjects[id].dui ~= dui then return end
        SendDuiMessage(dui, json.encode({
            action       = "init",
            text         = def.text or "",
            font         = def.font or "Arial",
            fontUrl      = fontUrls[def.font] or "",
            color        = def.color or "#ffffff",
            shadow       = def.shadow or false,
            glow         = def.glow or false,
            outline      = def.outline or false,
            outlineColor = def.outlineColor or "#000000",
            outlineWidth = def.outlineWidth or 2,
        }))
    end)
end

local function destroyAllTextObjects()
    for _, obj in pairs(textObjects) do
        if obj.dui then DestroyDui(obj.dui) end
    end
    textObjects = {}
end

local function drawTextObjectAtPos(txdName, txnName, coords, worldW, worldH)
    local head   = math.rad(coords.heading or 0.0)
    local fwd    = vector3(-math.cos(head), math.sin(head), 0.0)
    local center = vector3(coords.x, coords.y, coords.z)
    local half   = worldW * 0.5
    local halfH  = worldH

    local tl     = center + fwd * (-half) + vector3(0, 0, halfH)
    local tr     = center + fwd * (half) + vector3(0, 0, halfH)
    local bl     = center + fwd * (-half)
    local br     = center + fwd * (half)

    DrawSpritePoly(br.x, br.y, br.z, tr.x, tr.y, tr.z, tl.x, tl.y, tl.z, 255, 255, 255, 255, txdName, txnName, 1, 1, 1, 1,
        0, 1, 0, 0, 1, 0)
    DrawSpritePoly(tl.x, tl.y, tl.z, bl.x, bl.y, bl.z, br.x, br.y, br.z, 255, 255, 255, 255, txdName, txnName, 0, 0, 1, 0,
        1, 1, 0, 1)
end

local function processTextClipsAtFrame(frame)
    for _, clip in ipairs(textClips) do
        local obj = textObjects[clip.textId]
        local def = textDefs[clip.textId]
        if obj and def then
            if frame >= clip.startFrame and frame <= clip.endFrame then
                obj.visible  = true
                local totalF = math.max(1, clip.endFrame - clip.startFrame)
                local relF   = frame - clip.startFrame
                SendDuiMessage(obj.dui, json.encode({
                    action           = "processText",
                    text             = def.text or "",
                    font             = def.font or "Arial",
                    fontUrl          = fontUrls[def.font] or "",
                    color            = def.color or "#ffffff",
                    shadow           = def.shadow or false,
                    glow             = def.glow or false,
                    outline          = def.outline or false,
                    outlineColor     = def.outlineColor or "#000000",
                    outlineWidth     = def.outlineWidth or 2,
                    colorShift       = def.colorShift or false,
                    colorShiftColors = def.colorShiftColors or "",
                    colorShiftSpeed  = def.colorShiftSpeed or 60,
                    animation        = def.animation or "fadeSlide",
                    relFrame         = relF,
                    totalFrames      = totalF,
                    animIn           = def.animIn or 15,
                    animOut          = def.animOut or 15,
                }))
            elseif obj.visible then
                obj.visible = false
                SendDuiMessage(obj.dui, json.encode({ action = "hide" }))
            end
        end
    end
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if not uiOpen then
            Citizen.Wait(200)
        else
            for id, obj in pairs(textObjects) do
                if obj.visible then
                    local def = textDefs[id]
                    if def and def.coords then
                        drawTextObjectAtPos(obj.txdName, obj.txnName, def.coords, obj.worldWidth, obj.worldHeight)
                    end
                end
            end
            if not isFreecamMode then
                processTextClipsAtFrame(currentFrame)
            end
        end
    end
end)

RegisterNUICallback("addTextObject", function(data, cb)
    textDefs[data.id] = data
    createTextObject(data)
    cb("ok")
end)

RegisterNUICallback("updateTextObject", function(data, cb)
    textDefs[data.id] = data
    local obj = textObjects[data.id]
    if obj and obj.dui then
        SendDuiMessage(obj.dui, json.encode({
            action = "init",
            text = data.text or "",
            font = data.font or "Arial",
            fontUrl = fontUrls[data.font] or "",
            color = data.color or "#ffffff",
            shadow = data.shadow or false,
            glow = data.glow or false,
            outline = data.outline or false,
            outlineColor = data.outlineColor or "#000000",
            outlineWidth = data.outlineWidth or 2,
        }))
    end
    cb("ok")
end)

RegisterNUICallback("removeTextObject", function(data, cb)
    local obj = textObjects[data.id]
    if obj and obj.dui then DestroyDui(obj.dui) end
    textObjects[data.id] = nil
    textDefs[data.id]    = nil
    cb("ok")
end)

RegisterNUICallback("setTextClips", function(data, cb)
    textClips = data.clips or {}
    cb("ok")
end)

RegisterNUICallback("setTextCoords", function(data, cb)
    if textDefs[data.id] then textDefs[data.id].coords = data.coords end
    cb("ok")
end)

local FREECAM_SPEED_BASE  = 5.0
local FREECAM_SPEED_FAST  = 20.0
local FREECAM_SPEED_SLOW  = 1.0
local FREECAM_LOOK_SCALAR = 0.15

local function getFreecamMoveDelta(dt)
    local speed = FREECAM_SPEED_BASE
    if IsControlPressed(0, 21) then speed = FREECAM_SPEED_FAST end 
    if IsControlPressed(0, 36) then speed = FREECAM_SPEED_SLOW end 

    local dx, dy, dz = 0, 0, 0
    if IsControlPressed(0, 30) then dx = dx - 1 end 
    if IsControlPressed(0, 31) then dx = dx + 1 end 
    if IsControlPressed(0, 32) then dy = dy + 1 end 
    if IsControlPressed(0, 33) then dy = dy - 1 end 
    if IsControlPressed(0, 44) then dz = dz + 1 end 
    if IsControlPressed(0, 38) then dz = dz - 1 end 

    return dx * speed * dt, dy * speed * dt, dz * speed * dt
end

CreateThread(function()
    while true do
        Wait(0)
        if not (uiOpen and isFreecamMode) then goto skip end
        if not (editorCam and DoesCamExist(editorCam)) then goto skip end

        local dt       = 0.016667
        local rot      = GetCamRot(editorCam, 2)
        local pos      = GetCamCoord(editorCam)
        local yaw      = math.rad(rot.z)
        local pitch    = math.rad(rot.x)

        local mx       = GetDisabledControlNormal(0, 1) * 5.0
        local my       = GetDisabledControlNormal(0, 2) * 5.0
        local newYaw   = rot.z - mx * FREECAM_LOOK_SCALAR * 360.0
        local newPitch = math.max(-89.0, math.min(89.0, rot.x - my * FREECAM_LOOK_SCALAR * 360.0))
        SetCamRot(editorCam, newPitch, 0.0, newYaw, 2)

        local dx, dForward, dz = getFreecamMoveDelta(dt)

        local fwd              = vector3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch),
            math.sin(pitch))
        local rgt              = vector3(math.cos(yaw), math.sin(yaw), 0.0)
        local newPos           = pos + fwd * dForward + rgt * dx + vector3(0, 0, dz)

        SetCamCoord(editorCam, newPos.x, newPos.y, newPos.z)
        SetEntityCoordsNoOffset(PlayerPedId(), newPos.x, newPos.y, newPos.z, false, false, false)

        DisableAllControlActions(0)
        EnableControlAction(0, 1, true)  
        EnableControlAction(0, 2, true)  
        EnableControlAction(0, 21, true) 
        EnableControlAction(0, 36, true) 
        EnableControlAction(0, 30, true); EnableControlAction(0, 31, true)
        EnableControlAction(0, 32, true); EnableControlAction(0, 33, true)
        EnableControlAction(0, 44, true); EnableControlAction(0, 38, true)

        sendCoordsUpdate()

        ::skip::
    end
end)

AddEventHandler("onResourceStop", function(res)
    if res ~= GetCurrentResourceName() then return end
    if uiOpen then closeUI() end
    destroyAllTextObjects()
    for id in pairs(sceneEntities) do deleteSceneEntity(id) end
    if cameraPropHandle and DoesEntityExist(cameraPropHandle) then DeleteEntity(cameraPropHandle) end
    if activeShakeType then StopCamShaking(nil, true) end
    if activeFilterId then AnimpostfxStop(activeFilterId) end
    SetTimeScale(1.0); ClearOverrideWeather(); SetRainLevel(0.0)
    DisplayHud(true); DisplayRadar(true)
    SetNuiFocus(false, false)
    RenderScriptCams(false, false, 0, true, true)
end)

local sceneRelGroups    = {}
local sceneCombatActive = false
local SCENE_REL         = { neutral = 3, friendly = 1, hostile = 5 }

local function hexToRgb(hex)
    if not hex or #hex < 7 then return 0, 0, 0 end
    return tonumber(hex:sub(2, 3), 16) or 0,
        tonumber(hex:sub(4, 5), 16) or 0,
        tonumber(hex:sub(6, 7), 16) or 0
end

local function applySceneEntitySettings(def, handle)
    if def.type == "ped" then
        if def.weapon then
            GiveWeaponToPed(handle, def.weapon, 999, false, true)
            SetCurrentPedWeapon(handle, def.weapon, true)
        end
        if def.anim and def.anim.dict and def.anim.name then
            RequestAnimDict(def.anim.dict)
            local t = 0
            while not HasAnimDictLoaded(def.anim.dict) and t < 50 do
                Wait(50); t = t + 1
            end
            if HasAnimDictLoaded(def.anim.dict) then
                FreezeEntityPosition(handle, false)
                TaskPlayAnim(handle, def.anim.dict, def.anim.name, 8.0, -8.0, -1, def.anim.loop and 1 or 0, 0, false,
                    false, false)
            end
        end
        if def.combatAbility then SetPedCombatAbility(handle, def.combatAbility) end
        if def.combatMovement then SetPedCombatMovement(handle, def.combatMovement) end
        if def.combatRange then SetPedCombatRange(handle, def.combatRange) end
        if def.accuracy then SetPedAccuracy(handle, def.accuracy) end
        SetPedCombatAttributes(handle, 46, true)
        SetPedCombatAttributes(handle, 5, true)
        SetPedCombatAttributes(handle, 0, true)
        if def.health then
            SetEntityMaxHealth(handle, def.health); SetEntityHealth(handle, def.health)
        end
        if def.armor then SetPedArmour(handle, def.armor) end
        if def.invincible == false then SetEntityInvincible(handle, false) end
        if def.ragdoll == false then SetPedCanRagdoll(handle, false) end
    elseif def.type == "vehicle" then
        if def.engine then SetVehicleEngineOn(handle, true, true, false) end
        local lm = def.lightMode
        if lm then
            if lm ~= 0 then SetVehicleEngineOn(handle, true, true, false) end
            SetVehicleInteriorlight(handle, false)
            if lm == 0 then
                SetVehicleLights(handle, 1); SetVehicleFullbeam(handle, false)
            elseif lm == 1 then
                SetVehicleLights(handle, 2); SetVehicleFullbeam(handle, false)
            elseif lm == 2 then
                SetVehicleLights(handle, 2); SetVehicleFullbeam(handle, true)
            elseif lm == 3 then
                SetVehicleLights(handle, 1); SetVehicleInteriorlight(handle, true)
            end
        end
        if def.siren then SetVehicleSiren(handle, true) end
        if def.doors then
            for i, open in ipairs(def.doors) do
                if open then SetVehicleDoorOpen(handle, i - 1, false, false) end
            end
        end
        if def.windows then
            for i, smash in ipairs(def.windows) do
                if smash then SmashVehicleWindow(handle, i - 1) end
            end
        end
        if def.indicators then
            if def.indicators.left then SetVehicleIndicatorLights(handle, 1, true) end
            if def.indicators.right then SetVehicleIndicatorLights(handle, 0, true) end
        end
        if def.color1 then
            local r, g, b = hexToRgb(def.color1); SetVehicleCustomPrimaryColour(handle, r, g, b)
        end
        if def.color2 then
            local r, g, b = hexToRgb(def.color2); SetVehicleCustomSecondaryColour(handle, r, g, b)
        end
        if def.dirtLevel then SetVehicleDirtLevel(handle, def.dirtLevel + 0.0) end
        if def.plateText and def.plateText ~= "" then SetVehicleNumberPlateText(handle, def.plateText) end
        if def.neon then
            for i = 0, 3 do SetVehicleNeonLightEnabled(handle, i, true) end
            if def.neonColor then
                local r, g, b = hexToRgb(def.neonColor); SetVehicleNeonLightsColour(handle, r, g, b)
            end
        end
    elseif def.type == "prop" then
        if def.frozen == false then FreezeEntityPosition(handle, false) end
        if def.visible == false then SetEntityVisible(handle, false, false) end
        if def.onFire then StartEntityFire(handle) end
    end
end

RegisterNUICallback("scenePropSetting", function(data, cb)
    local e = sceneEntities[data.entityId]
    if not e or not (e.entityHandle and DoesEntityExist(e.entityHandle)) then
        cb("ok"); return
    end
    local key, val = data.key, data.value
    if key == "frozen" then
        FreezeEntityPosition(e.entityHandle, val)
    elseif key == "visible" then
        SetEntityVisible(e.entityHandle, val, false)
    elseif key == "onFire" then
        if val then StartEntityFire(e.entityHandle) else StopEntityFire(e.entityHandle) end
    end
    cb("ok")
end)

RegisterNUICallback("sceneVehEngine", function(data, cb)
    local e = sceneEntities[data.entityId]
    if e and e.entityHandle then SetVehicleEngineOn(e.entityHandle, data.on, true, false) end
    cb("ok")
end)

RegisterNUICallback("sceneVehSiren", function(data, cb)
    local e = sceneEntities[data.entityId]
    if e and e.entityHandle then SetVehicleSiren(e.entityHandle, data.on) end
    cb("ok")
end)

RegisterNUICallback("sceneVehLights", function(data, cb)
    local e = sceneEntities[data.entityId]
    if not e or not e.entityHandle then
        cb("ok"); return
    end
    local h, m = e.entityHandle, data.mode
    SetVehicleInteriorlight(h, false)
    if m ~= 0 then SetVehicleEngineOn(h, true, true, false) end
    if m == 0 then
        SetVehicleLights(h, 1); SetVehicleFullbeam(h, false)
    elseif m == 1 then
        SetVehicleLights(h, 2); SetVehicleFullbeam(h, false)
    elseif m == 2 then
        SetVehicleLights(h, 2); SetVehicleFullbeam(h, true)
    elseif m == 3 then
        SetVehicleLights(h, 1); SetVehicleInteriorlight(h, true)
    end
    cb("ok")
end)

RegisterNUICallback("sceneVehDoor", function(data, cb)
    local e = sceneEntities[data.entityId]
    if not e or not e.entityHandle then
        cb("ok"); return
    end
    if data.open then
        SetVehicleDoorOpen(e.entityHandle, data.door, false, false)
    else
        SetVehicleDoorShut(e.entityHandle, data.door, false)
    end
    cb("ok")
end)

RegisterNUICallback("sceneVehWindow", function(data, cb)
    local e = sceneEntities[data.entityId]
    if e and e.entityHandle then SmashVehicleWindow(e.entityHandle, data.window) end
    cb("ok")
end)

RegisterNUICallback("sceneVehIndicator", function(data, cb)
    local e = sceneEntities[data.entityId]
    if e and e.entityHandle then
        SetVehicleIndicatorLights(e.entityHandle, 1, data.left or false)
        SetVehicleIndicatorLights(e.entityHandle, 0, data.right or false)
    end
    cb("ok")
end)

RegisterNUICallback("sceneVehColor", function(data, cb)
    local e = sceneEntities[data.entityId]
    if e and e.entityHandle then
        SetVehicleCustomPrimaryColour(e.entityHandle, data.r1, data.g1, data.b1)
        SetVehicleCustomSecondaryColour(e.entityHandle, data.r2, data.g2, data.b2)
    end
    cb("ok")
end)

RegisterNUICallback("sceneVehDirt", function(data, cb)
    local e = sceneEntities[data.entityId]
    if e and e.entityHandle then SetVehicleDirtLevel(e.entityHandle, (data.level or 0) + 0.0) end
    cb("ok")
end)

RegisterNUICallback("sceneVehPlate", function(data, cb)
    local e = sceneEntities[data.entityId]
    if e and e.entityHandle then SetVehicleNumberPlateText(e.entityHandle, data.text or "") end
    cb("ok")
end)

RegisterNUICallback("sceneVehNeon", function(data, cb)
    local e = sceneEntities[data.entityId]
    if e and e.entityHandle then
        for i = 0, 3 do SetVehicleNeonLightEnabled(e.entityHandle, i, data.on) end
    end
    cb("ok")
end)

RegisterNUICallback("sceneVehNeonColor", function(data, cb)
    local e = sceneEntities[data.entityId]
    if e and e.entityHandle then SetVehicleNeonLightsColour(e.entityHandle, data.r, data.g, data.b) end
    cb("ok")
end)

RegisterNUICallback("scenePedCombat", function(data, cb)
    local e = sceneEntities[data.entityId]
    if not e or e.type ~= "ped" or not (e.entityHandle and DoesEntityExist(e.entityHandle)) then
        cb("ok"); return
    end
    local h = e.entityHandle
    if data.weapon then
        GiveWeaponToPed(h, data.weapon, 999, false, true); SetCurrentPedWeapon(h, data.weapon, true)
    end
    if data.health then
        SetEntityMaxHealth(h, data.health); SetEntityHealth(h, data.health)
    end
    if data.armor then SetPedArmour(h, data.armor) end
    if data.combatAbility then SetPedCombatAbility(h, data.combatAbility) end
    if data.combatMovement then SetPedCombatMovement(h, data.combatMovement) end
    if data.combatRange then SetPedCombatRange(h, data.combatRange) end
    if data.accuracy then SetPedAccuracy(h, data.accuracy) end
    cb("ok")
end)

local function enforceSceneCombat()
    sceneCombatActive = true
    local peds = {}
    for _, e in pairs(sceneEntities) do
        if e.type == "ped" and e.entityHandle and DoesEntityExist(e.entityHandle) and not IsEntityDead(e.entityHandle) then
            local h = e.entityHandle
            FreezeEntityPosition(h, false); SetBlockingOfNonTemporaryEvents(h, false)
            SetPedFleeAttributes(h, 0, false); SetPedCanRagdoll(h, true)
            SetPedCombatAttributes(h, 46, true); SetPedCombatAttributes(h, 5, true)
            SetPedCombatAttributes(h, 0, true); SetPedCombatAttributes(h, 1, true)
            if e.group and e.group ~= "" and sceneRelGroups[e.group] then
                SetPedRelationshipGroupHash(h, sceneRelGroups[e.group])
            end
            if e.weapon then
                GiveWeaponToPed(h, e.weapon, 999, false, true); SetCurrentPedWeapon(h, e.weapon, true)
            end
            ClearPedTasks(h)
            peds[#peds + 1] = e
        end
    end
    Wait(0)
    for _, e in ipairs(peds) do
        if DoesEntityExist(e.entityHandle) and not IsEntityDead(e.entityHandle) then
            local target = nil
            local myHash = e.group and sceneRelGroups[e.group]
            if myHash then
                for _, other in pairs(sceneEntities) do
                    if other ~= e and other.type == "ped" and other.entityHandle and
                        DoesEntityExist(other.entityHandle) and not IsEntityDead(other.entityHandle) and
                        other.group and other.group ~= e.group and sceneRelGroups[other.group] then
                        if GetRelationshipBetweenGroups(myHash, sceneRelGroups[other.group]) == 5 then
                            target = other.entityHandle; break
                        end
                    end
                end
                local dirHash = sceneRelGroups.Director or 1862763509
                if not target and GetRelationshipBetweenGroups(myHash, dirHash) == 5 then
                    target = PlayerPedId()
                end
            end
            if target then
                TaskCombatPed(e.entityHandle, target, 0, 16)
                SetPedKeepTask(e.entityHandle, true)
            end
        end
    end
end

local function pauseSceneCombat()
    sceneCombatActive = false
    for _, e in pairs(sceneEntities) do
        if e.type == "ped" and e.entityHandle and DoesEntityExist(e.entityHandle) then
            local h = e.entityHandle
            if IsEntityDead(h) then ResurrectPed(h) end
            SetPedKeepTask(h, false)
            SetPedRelationshipGroupHash(h, 1862763509)
            ClearPedTasksImmediately(h)
            SetBlockingOfNonTemporaryEvents(h, true)
            FreezeEntityPosition(h, true)
            if e.pos then
                SetEntityCoordsNoOffset(h, e.pos.x, e.pos.y, e.pos.z, false, false, false)
                SetEntityHeading(h, e.heading or 0.0)
            end
        end
    end
end

RegisterNUICallback("sceneSetRelGroups", function(data, cb)
    local groups = data.groups or {}
    local matrix = data.matrix or {}

    sceneRelGroups.Director = 1862763509
    for _, g in ipairs(groups) do
        if g.name ~= "Director" and not sceneRelGroups[g.name] then
            local tag = "SCENE_" .. g.name:upper():gsub("%s+", "_")
            local _, hash = AddRelationshipGroup(tag)
            sceneRelGroups[g.name] = hash
        end
    end

    for _, a in ipairs(groups) do
        for _, b in ipairs(groups) do
            if a.name ~= b.name and sceneRelGroups[a.name] and sceneRelGroups[b.name] then
                SetRelationshipBetweenGroups(SCENE_REL.neutral, sceneRelGroups[a.name], sceneRelGroups[b.name])
            end
        end
    end

    for key, rel in pairs(matrix) do
        local a, b = key:match("^(.+)->(.+)$")
        if a and b and sceneRelGroups[a] and sceneRelGroups[b] then
            SetRelationshipBetweenGroups(SCENE_REL[rel] or SCENE_REL.neutral, sceneRelGroups[a], sceneRelGroups[b])
        end
    end

    if sceneCombatActive then enforceSceneCombat() end
    cb("ok")
end)

RegisterNUICallback("sceneToggleCombat", function(_, cb)
    if sceneCombatActive then pauseSceneCombat() else enforceSceneCombat() end
    SendNUIMessage({ type = "sceneCombatState", active = sceneCombatActive })
    cb("ok")
end)

RegisterNUICallback("sceneResetPositions", function(_, cb)
    CreateThread(function()
        pauseSceneCombat()
        for _, e in pairs(sceneEntities) do
            local h = e.entityHandle
            if h and DoesEntityExist(h) and e.pos then
                if e.type == "ped" then
                    if IsEntityDead(h) then ResurrectPed(h) end
                    ClearPedTasksImmediately(h); FreezeEntityPosition(h, true)
                elseif e.type == "vehicle" then
                    SetVehicleEngineOn(h, false, true, true)
                    SetVehicleFullbeam(h, false); SetVehicleLights(h, 1)
                    SetVehicleInteriorlight(h, false); SetVehicleSiren(h, false)
                    for i = 0, 3 do SetVehicleNeonLightEnabled(h, i, false) end
                    SetVehicleIndicatorLights(h, 0, false); SetVehicleIndicatorLights(h, 1, false)
                    FreezeEntityPosition(h, true)
                end
                SetEntityCoordsNoOffset(h, e.pos.x, e.pos.y, e.pos.z, false, false, false)
                SetEntityHeading(h, e.heading or 0.0)
                applySceneEntitySettings(e, h)
            end
        end
        SendNUIMessage({ type = "sceneCombatState", active = false })
    end)
    cb("ok")
end)

RegisterNUICallback("sceneEntitySetting", function(data, cb)
    local e = sceneEntities[data.entityId]
    if not e or not (e.entityHandle and DoesEntityExist(e.entityHandle)) then
        cb("ok"); return
    end
    e.group   = data.group or e.group
    e.weapon  = data.weapon or e.weapon
    e.heading = data.heading or e.heading
    if data.pos then e.pos = data.pos end
    applySceneEntitySettings(e, e.entityHandle)
    cb("ok")
end)

RegisterNUICallback("sceneEntityMove", function(data, cb)
    local e = sceneEntities[data.entityId]
    if not e or not (e.entityHandle and DoesEntityExist(e.entityHandle)) then
        cb("ok"); return
    end
    if data.pos then
        e.pos = data.pos
        SetEntityCoordsNoOffset(e.entityHandle, data.pos.x, data.pos.y, data.pos.z, false, false, false)
    end
    if data.heading ~= nil then
        e.heading = data.heading
        SetEntityHeading(e.entityHandle, data.heading)
    end
    cb("ok")
end)

RegisterNUICallback("getSceneEntities", function(_, cb)
    local list = {}
    for id, e in pairs(sceneEntities) do
        local pos, head
        if e.entityHandle and DoesEntityExist(e.entityHandle) then
            local p = GetEntityCoords(e.entityHandle)
            pos     = { x = p.x, y = p.y, z = p.z }
            head    = GetEntityHeading(e.entityHandle)
        end
        list[#list + 1] = { id = id, type = e.type, pos = pos, heading = head, group = e.group, weapon = e.weapon }
    end
    cb(list)
end)

local focusCam        = nil
local placementActive = nil

RegisterNUICallback("scenePedHealth", function(data, cb)
    local e = sceneEntities[data.entityId]
    if not e or e.type ~= "ped" or not (e.entityHandle and DoesEntityExist(e.entityHandle)) then
        cb("ok"); return
    end
    local h = e.entityHandle
    if IsEntityDead(h) then
        ResurrectPed(h); ClearPedTasksImmediately(h)
        local p = GetEntityCoords(h)
        SetEntityCoords(h, p.x, p.y, p.z, false, false, false, false)
    end
    local hp = data.health or 200
    SetEntityMaxHealth(h, hp); SetEntityHealth(h, hp)
    SetPedArmour(h, data.armor or 0)
    SetEntityInvincible(h, data.invincible == true)
    SetPedCanRagdoll(h, data.canRagdoll ~= false)
    SetPedCanRagdollFromPlayerImpact(h, data.canRagdoll ~= false)
    if data.flee then
        SetPedFleeAttributes(h, 0, false); SetBlockingOfNonTemporaryEvents(h, false)
    else
        SetPedFleeAttributes(h, 0, true)
    end
    cb("ok")
end)

RegisterNUICallback("scenePedScenario", function(data, cb)
    local e = sceneEntities[data.entityId]
    if not e or not (e.entityHandle and DoesEntityExist(e.entityHandle)) then
        cb("ok"); return
    end
    ClearPedTasks(e.entityHandle)
    FreezeEntityPosition(e.entityHandle, false)
    TaskStartScenarioInPlace(e.entityHandle, data.scenario, 0, true)
    cb("ok")
end)

RegisterNUICallback("scenePedStopScenario", function(data, cb)
    local e = sceneEntities[data.entityId]
    if e and e.entityHandle then ClearPedTasks(e.entityHandle) end
    cb("ok")
end)

RegisterNUICallback("scenePedAssignGroup", function(data, cb)
    local e = sceneEntities[data.entityId]
    if not e or e.type ~= "ped" or not (e.entityHandle and DoesEntityExist(e.entityHandle)) then
        cb("ok"); return
    end
    local h, grp = e.entityHandle, data.group or ""
    e.group = grp
    SetPedCombatAbility(h, data.ability or 1)
    SetPedCombatMovement(h, data.movement or 2)
    SetPedCombatRange(h, data.range or 1)
    SetPedAccuracy(h, data.accuracy or 50)
    SetPedCombatAttributes(h, 46, true)
    SetPedCombatAttributes(h, 5, true)
    SetPedCombatAttributes(h, 0, true)
    if grp ~= "" and sceneRelGroups[grp] then
        local myHash = sceneRelGroups[grp]
        SetPedRelationshipGroupHash(h, myHash)
        FreezeEntityPosition(h, false)
        SetBlockingOfNonTemporaryEvents(h, false)
        SetPedKeepTask(h, true); SetPedCanRagdoll(h, true)
        local target = nil
        local dirHash = sceneRelGroups.Director or 1862763509
        if GetRelationshipBetweenGroups(myHash, dirHash) == 5 then
            target = PlayerPedId()
        else
            for _, other in pairs(sceneEntities) do
                if other ~= e and other.type == "ped" and other.entityHandle and
                    DoesEntityExist(other.entityHandle) and other.group and
                    other.group ~= grp and sceneRelGroups[other.group] then
                    if GetRelationshipBetweenGroups(myHash, sceneRelGroups[other.group]) == 5 then
                        target = other.entityHandle; break
                    end
                end
            end
        end
        if target then
            ClearPedTasks(h); Wait(0); TaskCombatPed(h, target, 0, 16)
        end
    end
    cb("ok")
end)

RegisterNUICallback("sceneRestoreAll", function(data, cb)
    cb("ok")
    local entities  = data.entities or {}
    local relGroups = data.relGroups or {}
    local relMatrix = data.relMatrix or {}
    CreateThread(function()
        for _, def in ipairs(entities) do
            local model = GetHashKey(def.model)
            RequestModel(model)
            local t = 0
            while not HasModelLoaded(model) and t < 100 do
                Wait(50); t = t + 1
            end
            if HasModelLoaded(model) then
                local pos     = def.pos or { x = 0, y = 0, z = 0 }
                local heading = def.heading or 0.0
                local handle  = nil
                if def.type == "ped" then
                    handle = CreatePed(4, model, pos.x, pos.y, pos.z, heading, false, false)
                    SetEntityInvincible(handle, true); SetBlockingOfNonTemporaryEvents(handle, true)
                    FreezeEntityPosition(handle, true)
                    SetEntityCoordsNoOffset(handle, pos.x, pos.y, pos.z, false, false, false)
                elseif def.type == "vehicle" then
                    handle = CreateVehicle(model, pos.x, pos.y, pos.z, heading, false, false)
                    SetEntityInvincible(handle, true); FreezeEntityPosition(handle, true)
                    SetEntityCoordsNoOffset(handle, pos.x, pos.y, pos.z, false, false, false)
                elseif def.type == "prop" then
                    handle = CreateObject(model, pos.x, pos.y, pos.z, false, false, false)
                    FreezeEntityPosition(handle, true); SetEntityInvincible(handle, true)
                    PlaceObjectOnGroundProperly(handle)
                end
                SetModelAsNoLongerNeeded(model)
                if handle then
                    sceneEntities[def.id] = {
                        id = def.id,
                        type = def.type,
                        model = def.model,
                        entityHandle = handle,
                        pos =
                            pos,
                        heading = heading,
                        group = def.group,
                        weapon = def.weapon,
                        followGen = 0
                    }
                    applySceneEntitySettings(def, handle)
                end
            end
        end
        sceneRelGroups.Director = 1862763509
        for _, g in ipairs(relGroups) do
            if g.name ~= "Director" and not sceneRelGroups[g.name] then
                local tag = "SCENE_" .. g.name:upper():gsub("%s+", "_")
                local _, hash = AddRelationshipGroup(tag)
                sceneRelGroups[g.name] = hash
            end
        end
        for key, rel in pairs(relMatrix) do
            local a, b = key:match("^(.+)->(.+)$")
            if a and b and sceneRelGroups[a] and sceneRelGroups[b] then
                SetRelationshipBetweenGroups(SCENE_REL[rel] or SCENE_REL.neutral, sceneRelGroups[a], sceneRelGroups[b])
            end
        end
        pauseSceneCombat()
        SendNUIMessage({ type = "sceneCombatState", active = false })
    end)
end)

RegisterNUICallback("deleteRecording", function(_, cb)
    for _, veh in pairs(vehicleSpawns) do if DoesEntityExist(veh) then DeleteEntity(veh) end end
    vehicleSpawns = {}; vehicleSpawnReady = {}; vehicleFrameIdx = {}
    for _, ped in pairs(pedSpawns) do if DoesEntityExist(ped) then DeleteEntity(ped) end end
    pedSpawns = {}; pedSpawnReady = {}
    cleanupOverlaySpawns()
    vehicleRecordings = {}; pedRecordings = {}; overlayLayers = {}
    trimStart = 0.0; trimEnd = nil; trimIn = 0.0
    if inBucket then
        TriggerServerEvent("core_cinematics:leaveBucket"); inBucket = false
    end
    cb("ok")
end)

RegisterNUICallback("focusEntity", function(data, cb)
    local e = sceneEntities[data.entityId]
    if not e or not (e.entityHandle and DoesEntityExist(e.entityHandle)) then
        cb("ok"); return
    end
    local pos  = GetEntityCoords(e.entityHandle)
    local head = GetEntityHeading(e.entityHandle)
    local ang  = math.rad(head + 180.0)
    local dist = data.dist or 3.0
    local zOff = data.zOff or 0.8
    if focusCam and DoesCamExist(focusCam) then DestroyCam(focusCam, false) end
    focusCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(focusCam, pos.x + math.sin(ang) * dist, pos.y - math.cos(ang) * dist, pos.z + zOff)
    PointCamAtEntity(focusCam, e.entityHandle, 0, 0, 0, true)
    if editorCam and DoesCamExist(editorCam) then
        SetCamActiveWithInterp(focusCam, editorCam, 500, 1, 1)
    else
        SetCamActive(focusCam, true); RenderScriptCams(true, false, 0, true, false)
    end
    cb("ok")
end)

RegisterNUICallback("unfocusEntity", function(_, cb)
    if focusCam and DoesCamExist(focusCam) then
        if editorCam and DoesCamExist(editorCam) then
            SetCamActiveWithInterp(editorCam, focusCam, 500, 1, 1)
        end
        CreateThread(function()
            Wait(600)
            if focusCam and DoesCamExist(focusCam) then
                DestroyCam(focusCam, false); focusCam = nil
            end
        end)
    end
    cb("ok")
end)

RegisterNUICallback("sceneUpdatePos", function(data, cb)
    local e = sceneEntities[data.entityId]
    if not e or not (e.entityHandle and DoesEntityExist(e.entityHandle)) then
        cb("ok"); return
    end
    local pos         = data.pos
    local heading     = data.heading or 0.0
    local gz, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 5.0, false)
    if gz then pos.z = groundZ + (e.type == "vehicle" and 0.5 or 0.1) end
    SetEntityCoords(e.entityHandle, pos.x, pos.y, pos.z, false, false, false, false)
    SetEntityHeading(e.entityHandle, heading)
    if e.type == "vehicle" then SetVehicleOnGroundProperly(e.entityHandle) end
    e.pos = pos; e.heading = heading
    cb("ok")
end)

RegisterNUICallback("startScenePlacement", function(data, cb)
    local id = data.entityId
    local e  = sceneEntities[id]
    if not e or not (e.entityHandle and DoesEntityExist(e.entityHandle)) then
        cb("ok"); return
    end
    local isNewSpawn = data.isNewSpawn == true
    placementActive  = id
    SetNuiFocus(false, false)
    SendNUIMessage({ type = "scenePlacementActive", active = true })
    cb("ok")

    CreateThread(function()
        local handle   = e.entityHandle
        local origPos  = vector3(e.pos.x, e.pos.y, e.pos.z)
        local origHead = e.heading or 0.0
        local heading  = origHead
        local camPos   = origPos + vector3(-5.6, -5.6, 2.4)
        local rot      = vector3(math.deg(math.atan(2.4, math.sqrt(5.6 ^ 2 + 5.6 ^ 2))) * -1, 0,
            math.deg(math.atan(5.6, 5.6)) * -1)
        local camH     = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(camH, camPos.x, camPos.y, camPos.z)
        SetCamRot(camH, rot.x, rot.y, rot.z, 2)
        SetCamActive(camH, true)
        RenderScriptCams(true, false, 0, true, false)
        FreezeEntityPosition(handle, true)
        local player = PlayerPedId()
        SetEntityVisible(player, false, false); FreezeEntityPosition(player, true)
        local speed = 15.0

        while placementActive == id do
            Wait(0)
            for _, ctrl in ipairs({ 1, 2, 24, 25, 30, 31, 37, 22, 36, 44, 38 }) do DisableControlAction(0, ctrl, true) end
            local mx = GetDisabledControlNormal(0, 1) * 4.0
            local my = GetDisabledControlNormal(0, 2) * 4.0
            rot = vector3(math.max(-89, math.min(89, rot.x - my)), 0, rot.z - mx)
            SetCamRot(camH, rot.x, rot.y, rot.z, 2)
            local yaw   = math.rad(rot.z)
            local pitch = math.rad(rot.x)
            local fwd   = vector3(-math.sin(yaw) * math.abs(math.cos(pitch)), math.cos(yaw) * math.abs(math.cos(pitch)),
                math.sin(pitch))
            local rgt   = vector3(-math.sin(math.rad(rot.z - 90)), math.cos(math.rad(rot.z - 90)), 0)
            local fast  = IsDisabledControlPressed(0, 21)
            local spd   = (fast and speed * 3 or speed) * 0.016667
            if IsDisabledControlPressed(0, 32) then camPos = camPos + fwd * spd end
            if IsDisabledControlPressed(0, 33) then camPos = camPos - fwd * spd end
            if IsDisabledControlPressed(0, 34) then camPos = camPos - rgt * spd end
            if IsDisabledControlPressed(0, 35) then camPos = camPos + rgt * spd end
            if IsDisabledControlPressed(0, 22) then camPos = camPos + vector3(0, 0, spd) end
            if IsDisabledControlPressed(0, 36) then camPos = camPos - vector3(0, 0, spd) end
            if IsDisabledControlPressed(0, 44) then heading = heading + 90 * 0.016667 end
            if IsDisabledControlPressed(0, 38) then heading = heading - 90 * 0.016667 end
            SetCamCoord(camH, camPos.x, camPos.y, camPos.z)
            local entPos = camPos + fwd * speed
            local gz, gzv = GetGroundZFor_3dCoord(entPos.x, entPos.y, entPos.z + 2, false)
            if gz then entPos = vector3(entPos.x, entPos.y, gzv) end
            SetEntityCoords(handle, entPos.x, entPos.y, entPos.z, false, false, false, false)
            SetEntityHeading(handle, heading % 360)
            SendNUIMessage({
                type = "coordsUpdate",
                pos = { x = camPos.x, y = camPos.y, z = camPos.z },
                rot = { x = rot.x, y = rot.y, z = rot.z },
                fov =
                    GetCamFov(camH) or 50
            })

            local function finishPlacement(cancelled)
                placementActive = nil
                SetCamActive(camH, false); DestroyCam(camH, false)
                SetEntityVisible(player, true, false); FreezeEntityPosition(player, false)
                if editorCam and DoesCamExist(editorCam) then
                    SetCamActive(editorCam, true); RenderScriptCams(true, false, 0, true, false)
                end
                SetNuiFocus(true, true)
                if cancelled then
                    SendNUIMessage({ type = "scenePlacementActive", active = false })
                    if isNewSpawn then
                        if DoesEntityExist(handle) then DeleteEntity(handle) end
                        sceneEntities[id] = nil
                        SendNUIMessage({ type = "sceneEntityDeleted", entityId = id })
                    else
                        SetEntityCoords(handle, origPos.x, origPos.y, origPos.z, false, false, false, false)
                        SetEntityHeading(handle, origHead)
                    end
                else
                    local finalPos = GetEntityCoords(handle)
                    local gz2, gzv2 = GetGroundZFor_3dCoord(finalPos.x, finalPos.y, finalPos.z + 2, false)
                    if gz2 then SetEntityCoords(handle, finalPos.x, finalPos.y, gzv2, false, false, false, false) end
                    if e.type == "vehicle" then SetVehicleOnGroundProperly(handle) end
                    local confirmed = GetEntityCoords(handle)
                    e.pos = { x = confirmed.x, y = confirmed.y, z = confirmed.z }
                    e.heading = heading % 360
                    SendNUIMessage({ type = "scenePlacementDone", entityId = id, pos = e.pos, heading = e.heading })
                end
            end

            if IsControlJustReleased(0, 191) then
                finishPlacement(false); return
            end
            if IsDisabledControlJustReleased(0, 177) or IsDisabledControlJustReleased(0, 202) or
                IsDisabledControlJustReleased(0, 200) or IsDisabledControlJustReleased(0, 322) then
                finishPlacement(true); return
            end
        end
    end)
end)

RegisterNUICallback("resetProjectState", function(_, cb)
    if isPlaying then stopPlayback() end

    for _, veh in pairs(vehicleSpawns) do if DoesEntityExist(veh) then DeleteEntity(veh) end end
    vehicleSpawns = {}; vehicleSpawnReady = {}; vehicleFrameIdx = {}
    for _, ped in pairs(pedSpawns) do if DoesEntityExist(ped) then DeleteEntity(ped) end end
    pedSpawns = {}; pedSpawnReady = {}

    cleanupOverlaySpawns()
    for _, layer in ipairs(overlayLayers) do
        if layer.driftSmoke and DriftSmoke and DriftSmoke.stopPlayback then
            DriftSmoke.stopPlayback(layer.driftSmoke)
        end
    end
    overlayLayers = {}

    for _, ds in pairs(driftSmokeTrack or {}) do
        if DriftSmoke and DriftSmoke.stopPlayback then DriftSmoke.stopPlayback(ds) end
    end
    driftSmokeTrack = {}

    for id in pairs(sceneEntities) do deleteSceneEntity(id) end
    sceneEntities = {}; sceneFollowing = {}

    vehicleRecordings = {}; pedRecordings = {}
    trimStart = 0.0; trimEnd = nil; trimIn = 0.0
    soloRecordingLayer = nil

    if inBucket then
        TriggerServerEvent("core_cinematics:leaveBucket")
        inBucket = false
        local p = PlayerPedId()
        SetEntityVisible(p, true, false)
        ResetEntityAlpha(p)
        SetEntityCollision(p, true, true)
        SetEntityLocallyInvisible(p, false)
        SetLocalPlayerVisibleLocally(true)
    end

    if savedPlayerPos then
        local p = PlayerPedId()
        SetEntityCoordsNoOffset(p, savedPlayerPos.x, savedPlayerPos.y, savedPlayerPos.z, false, false, false)
        SetEntityHeading(p, savedPlayerHeading or 0.0)
        savedPlayerPos = nil; savedPlayerHeading = nil
    end

    cb("ok")
end)

RegisterNUICallback("clickReplayEntity", function(data, cb)
    cb("ok")
    if not (editorCam and DoesCamExist(editorCam)) then return end

    local mx      = data.mouseX or 0.5
    local my      = data.mouseY or 0.5
    local best    = 0.045
    local hitType = nil
    local hitIdx  = nil

    for idx, veh in pairs(vehicleSpawns) do
        if veh and DoesEntityExist(veh) then
            local p = GetEntityCoords(veh)
            local ok, sx, sy = GetScreenCoordFromWorldCoord(p.x, p.y, p.z)
            if ok then
                local d = math.sqrt((sx - mx) ^ 2 + (sy - my) ^ 2)
                if best > d then
                    best = d; hitType = "vehicle"; hitIdx = idx
                end
            end
        end
    end
    for idx, ped in pairs(pedSpawns) do
        if ped and DoesEntityExist(ped) then
            local p = GetEntityCoords(ped)
            local ok, sx, sy = GetScreenCoordFromWorldCoord(p.x, p.y, p.z + 0.5)
            if ok then
                local d = math.sqrt((sx - mx) ^ 2 + (sy - my) ^ 2)
                if best > d then
                    best = d; hitType = "ped"; hitIdx = idx
                end
            end
        end
    end

    if hitType and hitIdx then
        if hitType == "vehicle" then
            local rec  = vehicleRecordings[hitIdx]
            local name = rec and GetDisplayNameFromVehicleModel(rec.vehicleModel) or "UNKNOWN"
            if name == "CARNOTFOUND" then name = tostring(rec and rec.vehicleModel or hitIdx) end
            SendNUIMessage({
                type = "replayEntityClicked",
                entityType = "vehicle",
                recordingIdx = hitIdx,
                currentModel =
                    name:lower()
            })
        else
            local rec = pedRecordings[hitIdx]
            SendNUIMessage({
                type = "replayEntityClicked",
                entityType = "ped",
                recordingIdx = hitIdx,
                currentModel =
                    tostring(rec and rec.pedModel or hitIdx)
            })
        end
    end
end)

RegisterNUICallback("swapReplayModel", function(data, cb)
    local entityType  = data.entityType
    local recIdx      = data.recordingIdx
    local newModelStr = data.newModel
    local modelHash   = GetHashKey(newModelStr)
    RequestModel(modelHash)
    cb("ok")

    CreateThread(function()
        local t = 0
        while not HasModelLoaded(modelHash) and t < 100 do
            Wait(50); t = t + 1
        end
        if not HasModelLoaded(modelHash) then
            SendNUIMessage({ type = "modelSwapError", msg = _L("lua.errors.model_not_found", { model = newModelStr }) })
            return
        end

        if entityType == "vehicle" then
            local rec = vehicleRecordings[recIdx]
            if not rec then
                SendNUIMessage({ type = "modelSwapError", msg = _L("lua.errors.recording_not_found") }); return
            end

            if vehicleSpawns[recIdx] and DoesEntityExist(vehicleSpawns[recIdx]) then DeleteEntity(vehicleSpawns[recIdx]) end

            local f0 = rec.frames and rec.frames[1]
            rec.suspensionDelta = 0.0
            if f0 then
                local oldHash = rec.vehicleModel
                RequestModel(oldHash)
                local tt = 0; while not HasModelLoaded(oldHash) and tt < 60 do
                    Wait(50); tt = tt + 1
                end
                local ghost1 = CreateVehicle(oldHash, f0.px, f0.py, f0.pz + 1.0, 0, false, false)
                SetEntityVisible(ghost1, false, false); SetEntityAlpha(ghost1, 0, false)
                SetVehicleOnGroundProperly(ghost1)
                for i = 1, 40 do
                    Wait(25); if math.abs(GetEntityVelocity(ghost1).z) < 0.01 then break end
                end
                local z1 = GetEntityCoords(ghost1).z
                DeleteEntity(ghost1); SetModelAsNoLongerNeeded(oldHash)

                local ghost2 = CreateVehicle(modelHash, f0.px, f0.py, f0.pz + 1.0, 0, false, false)
                SetEntityVisible(ghost2, false, false); SetEntityAlpha(ghost2, 0, false)
                SetVehicleOnGroundProperly(ghost2)
                for i = 1, 40 do
                    Wait(25); if math.abs(GetEntityVelocity(ghost2).z) < 0.01 then break end
                end
                local z2 = GetEntityCoords(ghost2).z
                DeleteEntity(ghost2)
                rec.suspensionDelta = z2 - z1
            end

            rec.vehicleModel = modelHash
            vehicleSpawns[recIdx] = nil; vehicleSpawnReady[recIdx] = false
            spawnSingleVehicle(recIdx)

            local tt = 0
            while (not vehicleSpawns[recIdx] or not vehicleSpawnReady[recIdx]) and tt < 100 do
                Wait(50); tt = tt + 1
            end
            previewVehicleAtFrame(currentFrame)
            SendNUIMessage({
                type = "modelSwapDone",
                newModel = newModelStr,
                entityType = entityType,
                recordingIdx =
                    recIdx
            })
        elseif entityType == "ped" then
            local rec = pedRecordings[recIdx]
            if not rec then
                SendNUIMessage({ type = "modelSwapError", msg = _L("lua.errors.recording_not_found") }); return
            end

            if pedSpawns[recIdx] and DoesEntityExist(pedSpawns[recIdx]) then DeleteEntity(pedSpawns[recIdx]) end
            rec.pedModel = modelHash
            pedSpawns[recIdx] = nil; pedSpawnReady[recIdx] = false
            spawnSinglePed(recIdx)

            local tt = 0
            while (not pedSpawns[recIdx] or not pedSpawnReady[recIdx]) and tt < 100 do
                Wait(50); tt = tt + 1
            end
            previewPedAtFrame(currentFrame)
            SendNUIMessage({
                type = "modelSwapDone",
                newModel = newModelStr,
                entityType = entityType,
                recordingIdx =
                    recIdx
            })
        end

        SetModelAsNoLongerNeeded(modelHash)
    end)
end)

RegisterNUICallback("setVehicleRecTiming", function(data, cb)
    local fps = Config.DefaultFPS or 30
    trimStart = (data.startFrame or 0) / fps
    trimEnd   = data.endFrame and (data.endFrame / fps) or nil
    trimIn    = (data.trimInFrame or 0) / fps
    cb("ok")
end)

RegisterNUICallback("startSoloRecord", function(_, cb)
    local maxLayers = Config.MaxOverlayLayers or 5
    if #overlayLayers >= maxLayers then
        SendNUIMessage({ type = "toast", msg = "Max " .. maxLayers .. " overlay layers.", level = "error" })
        cb("ok"); return
    end
    closeUI()
    if inBucket then
        TriggerServerEvent("core_cinematics:leaveBucket")
        inBucket = false
        local p = PlayerPedId()
        SetEntityVisible(p, true, false); ResetEntityAlpha(p)
        SetEntityCollision(p, true, true); SetEntityLocallyInvisible(p, false)
        SetLocalPlayerVisibleLocally(true)
    end
    CreateThread(function()
        Wait(200)
        beginSoloRecording()
    end)
    cb("ok")
end)

RegisterNUICallback("soloRecordCountdownDone", function(_, cb)
    cb("ok")
end)

RegisterNUICallback("setOverlayTiming", function(data, cb)
    local fps   = Config.DefaultFPS or 30
    local layer = data.layerIdx and overlayLayers[data.layerIdx]
    if layer then
        layer.startSec  = (data.startFrame or 0) / fps
        layer.endSec    = data.endFrame and (data.endFrame / fps) or nil
        layer.trimInSec = (data.trimInFrame or 0) / fps
    end
    cb("ok")
end)

RegisterNUICallback("deleteOverlayLayer", function(data, cb)
    local idx = data.layerIdx
    if idx and overlayLayers[idx] then
        local layer = overlayLayers[idx]
        if layer.vehicleSpawn and DoesEntityExist(layer.vehicleSpawn) then
            DeleteEntity(layer.vehicleSpawn)
        end
        if layer.driftSmoke and DriftSmoke and DriftSmoke.stopPlayback then
            DriftSmoke.stopPlayback(layer.driftSmoke)
        end
        table.remove(overlayLayers, idx)
        for i, l in ipairs(overlayLayers) do l.id = i end
        sendOverlayLayersToJS()
    end
    cb("ok")
end)

local currentFilterId = "none"
local dofActive       = false

function applyEffects(fx, cam)
    if not cam then cam = editorCam end
    if not cam or not DoesCamExist(cam) then return end
    local shake  = fx.shake or {}
    local dof    = fx.dof or {}
    local filter = fx.filter or {}
    local fade   = fx.fade or {}
    
    if shake.type and shake.type ~= "none" and (shake.amplitude or 0) > 0 then
        ShakeCam(cam, shake.type, shake.amplitude)
    else
        StopCamShaking(cam, true)
    end
    
    if dof.enabled then
        dofActive = true
        SetCamUseShallowDofMode(cam, true)
        SetCamNearDof(cam, fv(dof.near or 3.0))
        SetCamFarDof(cam, fv(dof.far or 50.0))
        SetCamDofFnumberOfLens(cam, fv(dof.fNumber or 1.2))
        SetCamDofStrength(cam, fv(dof.strength or 1.0))
    else
        dofActive = false
        SetCamUseShallowDofMode(cam, false)
    end
    
    SetCamMotionBlurStrength(cam, fx.motionBlur or 0.0)
    
    local fid = (filter.id and filter.id ~= "") and filter.id or "none"
    if fid ~= currentFilterId then
        currentFilterId = fid
        if fid == "none" then
            ClearTimecycleModifier()
        else
            for _, cf in ipairs(Config.ColorFilters or {}) do
                if cf.id == fid then
                    SetTimecycleModifier(cf.timecycle)
                    break
                end
            end
        end
    end
    if fid ~= "none" and filter.strength then
        SetTimecycleModifierStrength(filter.strength)
    end
    
    local hasFx = (fade.amount or 0) > 0 or (fx.vignette or 0) > 0 or
        (fx.letterbox or 0) > 0 or (fx.grain or 0) > 0
    if hasFx then
        SendNUIMessage({
            type       = "fxUpdate",
            fadeType   = fade.type or "none",
            fadeAmount = fade.amount or 0,
            vignette   = fx.vignette or 0,
            letterbox  = fx.letterbox or 0,
            grain      = fx.grain or 0
        })
    else
        SendNUIMessage({ type = "fxClear" })
    end
end

function sendCoordsUpdate()
    if not editorCam or not DoesCamExist(editorCam) then return end
    local p = GetCamCoord(editorCam)
    local r = GetCamRot(editorCam, 2)
    local f = GetCamFov(editorCam)
    SendNUIMessage({
        type = "coordsUpdate",
        pos = { x = p.x, y = p.y, z = p.z },
        rot = { x = r.x, y = r.y, z = r.z },
        fov = f
    })
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(150)
        if uiOpen and not isFreecamMode and not isPlaying then
            sendCoordsUpdate()
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)
        if uiOpen and worldSettings.freezeTime and not isPlaying then
            local kf = interpolateKeyframes and interpolateKeyframes(currentFrame)
            if not (kf and kf.time) then
                applyGameTime(worldSettings.time)
            end
        end
    end
end)

local bucketWasActive = false
Citizen.CreateThread(function()
    while true do
        if inBucket then
            local p = PlayerPedId()
            FreezeEntityPosition(p, true)
            SetEntityVisible(p, false, false)
            SetEntityAlpha(p, 0, false)
            SetEntityCollision(p, false, false)
            SetLocalPlayerVisibleLocally(false)
            SetEntityLocallyInvisible(p, true)
            bucketWasActive = true
            Wait(0)
        else
            if bucketWasActive then
                local p = PlayerPedId()
                FreezeEntityPosition(p, false)
                bucketWasActive = false
            end
            Wait(250)
        end
    end
end)

Citizen.CreateThread(function()
    local lastLoad = nil
    while true do
        Wait(1000)
        if uiOpen and editorCam and DoesCamExist(editorCam) then
            local cp    = GetCamCoord(editorCam)
            local pp    = GetEntityCoords(PlayerPedId())
            local d2c   = #(cp - pp)
            local dLast = lastLoad and #(cp - lastLoad) or 999.0
            if d2c > 200.0 and dLast > 150.0 then
                Wait(500)
                RequestCollisionAtCoord(cp.x, cp.y, cp.z)
                NewLoadSceneStart(cp.x, cp.y, cp.z, cp.x, cp.y, cp.z, 200.0, 0)
                lastLoad = cp
            end
        end
    end
end)

local lerpAngle = lerpAngle or function(a, b, t)
    local d = (b - a) % 360
    if d > 180 then d = d - 360 end
    return a + d * t
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local dt = GetFrameTime()

        if dofActive then SetUseHiDof() end

        if isPlaying and timeScale ~= 1.0 then SetTimeScale(timeScale) end

        if uiOpen then
            if worldSettings.weatherOverride then
                SetOverrideWeather(worldSettings.weather)
            else
                ClearOverrideWeather()
            end
            SetRainLevel(worldSettings.rainEnabled and (worldSettings.rainLevel or 0) or 0)
            SetWindSpeed(worldSettings.windSpeed or 0)
            SetArtificialLightsState(worldSettings.cityLights == true)
        end

        for _, rec in pairs(cameraPropRecs or {}) do
            if rec.prop and DoesEntityExist(rec.prop) and rec.matrix then
                local m = rec.matrix
                SetEntityMatrix(rec.prop,
                    vector3(m.fx, m.fy, m.fz), vector3(m.rx, m.ry, m.rz),
                    vector3(m.ux, m.uy, m.uz), vector3(m.px, m.py, m.pz))
            end
        end

        if uiOpen and showPath and #keyframes >= 2 then
            drawKeyframePath()
        end

        if isFreecamMode and editorCam and DoesCamExist(editorCam) then
            RenderScriptCams(true, false, 0, true, true)
            DisableAllControlActions(0)
            local fast  = IsDisabledControlPressed(0, 21)
            local mv    = (fast and (Config.MoveSpeedFast or 60.0) or (Config.MoveSpeed or 12.0)) * dt
            local rv    = (fast and (Config.RotateSpeedFast or 8.0) or (Config.RotateSpeed or 3.0))
            local rot   = GetCamRot(editorCam, 2)
            local pitch = math.rad(rot.x)
            local yaw   = math.rad(rot.z)
            local fwd   = vector3(-math.sin(yaw) * math.abs(math.cos(pitch)), math.cos(yaw) * math.abs(math.cos(pitch)),
                math.sin(pitch))
            local rgt   = vector3(math.cos(yaw), math.sin(yaw), 0)
            local up    = vector3(0, 0, 1)
            local pos   = GetCamCoord(editorCam)
            local moved = false
            if IsDisabledControlPressed(0, 32) then
                pos = pos + fwd * mv; moved = true
            end
            if IsDisabledControlPressed(0, 33) then
                pos = pos - fwd * mv; moved = true
            end
            if IsDisabledControlPressed(0, 34) then
                pos = pos - rgt * mv; moved = true
            end
            if IsDisabledControlPressed(0, 35) then
                pos = pos + rgt * mv; moved = true
            end
            if IsDisabledControlPressed(0, 44) then
                pos = pos - up * mv; moved = true
            end
            if IsDisabledControlPressed(0, 38) then
                pos = pos + up * mv; moved = true
            end
            if moved then SetCamCoord(editorCam, pos.x, pos.y, pos.z) end
            local mx = GetDisabledControlNormal(0, 1)
            local my = GetDisabledControlNormal(0, 2)
            if math.abs(mx) > 0.001 or math.abs(my) > 0.001 then
                local nz = rot.z - mx * rv
                local nx = math.max(-89, math.min(89, rot.x - my * rv))
                SetCamRot(editorCam, nx, 0.0, nz, 2)
            end
            
            local fovStep = fast and 3 or 1
            if IsDisabledControlPressed(0, 241) then
                SetCamFov(editorCam, fv(math.max(Config.FovMin or 5.0, GetCamFov(editorCam) - fovStep)))
            end
            if IsDisabledControlPressed(0, 242) then
                SetCamFov(editorCam, fv(math.min(Config.FovMax or 120.0, GetCamFov(editorCam) + fovStep)))
            end
            
            if IsDisabledControlJustPressed(0, 177) or IsDisabledControlJustPressed(0, 191) then
                local cp = GetCamCoord(editorCam)
                local cr = GetCamRot(editorCam, 2)
                local cf = GetCamFov(editorCam)
                isFreecamMode = false
                SetNuiFocus(true, true)
                SendNUIMessage({
                    type = "positionSaved",
                    pos = { x = cp.x, y = cp.y, z = cp.z },
                    rot = { x = cr.x, y = cr.y, z = cr.z },
                    fov = cf
                })
            end
            
            if IsDisabledControlJustPressed(0, 200) then
                isFreecamMode = false
                SetNuiFocus(true, true)
                SendNUIMessage({ type = "positionCancelled" })
            end
            sendCoordsUpdate()

        elseif isPlaying then
            HideHudAndRadarThisFrame()
            playbackSec = playbackSec + dt
            currentFrame = math.floor(playbackSec * (Config.DefaultFPS or 30))

            local kf = (interpSettings.mode == "spline" and interpolateKeyframesSpline or interpolateKeyframes)(
                currentFrame)
            if kf then
                SetCamCoord(editorCam, kf.pos.x, kf.pos.y, kf.pos.z)
                SetCamRot(editorCam, kf.rot.x, kf.rot.y, kf.rot.z, 2)
                SetCamFov(editorCam, fv(kf.fov))
                applyEffects(kf.effects or {}, editorCam)
                if kf.time then
                    applyGameTime(kf.time)
                elseif worldSettings.freezeTime then
                    applyGameTime(worldSettings.time)
                end
                timeScale = kf.timeScale or 1.0
                sendCoordsUpdate()
                
                if savedPlayerPos and (#vehicleRecordings > 0 or #pedRecordings > 0) then
                    SetEntityCoordsNoOffset(PlayerPedId(), kf.pos.x, kf.pos.y, kf.pos.z, false, false, false)
                end
            else
                stopPlayback()
            end

            for i, rec in ipairs(vehicleRecordings) do
                local frames = rec.frames
                if #frames >= 2 then
                    local endSec = trimEnd or (trimStart + rec.duration - trimIn)
                    local t      = playbackSec - trimStart + trimIn
                    if playbackSec < trimStart or endSec < playbackSec then
                        
                        if vehicleSpawns[i] and DoesEntityExist(vehicleSpawns[i]) then
                            if driftSmokeTrack[i] and DriftSmoke then DriftSmoke.stopPlayback(driftSmokeTrack[i]) end
                            DeleteEntity(vehicleSpawns[i]); vehicleSpawns[i] = nil; vehicleSpawnReady[i] = false
                        end
                    else
                        if t < frames[1].t or t > rec.duration then
                            if vehicleSpawns[i] and DoesEntityExist(vehicleSpawns[i]) then
                                DeleteEntity(vehicleSpawns[i]); vehicleSpawns[i] = nil; vehicleSpawnReady[i] = false
                            end
                        else
                            if not (vehicleSpawns[i] and DoesEntityExist(vehicleSpawns[i])) then
                                spawnSingleVehicle(i)
                            else
                                
                                while vehicleFrameIdx[i] < #frames - 1 and frames[vehicleFrameIdx[i] + 1].t <= t do
                                    vehicleFrameIdx[i] = vehicleFrameIdx[i] + 1
                                end
                                local fi    = vehicleFrameIdx[i]
                                local f0    = frames[fi]
                                local f1    = frames[math.min(fi + 1, #frames)]
                                local df    = f1.t - f0.t
                                local alpha = df > 0.001 and math.max(0, math.min(1, (t - f0.t) / df)) or 0
                                local px    = f0.px + (f1.px - f0.px) * alpha
                                local py    = f0.py + (f1.py - f0.py) * alpha
                                local pz    = f0.pz + (f1.pz - f0.pz) * alpha + (rec.suspensionDelta or 0)
                                local vx    = f0.vx + (f1.vx - f0.vx) * alpha
                                local vy    = f0.vy + (f1.vy - f0.vy) * alpha
                                local vz    = f0.vz + (f1.vz - f0.vz) * alpha
                                local rx    = lerpAngle(f0.rx, f1.rx, alpha)
                                local ry    = lerpAngle(f0.ry, f1.ry, alpha)
                                local rz    = lerpAngle(f0.rz, f1.rz, alpha)
                                local steer = f0.steer + ((f1.steer or f0.steer) - f0.steer) * alpha
                                local rpm   = f0.rpm and (f0.rpm + ((f1.rpm or f0.rpm) - f0.rpm) * alpha) or nil
                                local veh   = vehicleSpawns[i]
                                if IsEntityOnScreen(veh) then
                                    FreezeEntityPosition(veh, false)
                                    local cur = GetEntityCoords(veh)
                                    local dp  = (vector3(px, py, pz) - cur) * 15.0
                                    SetEntityRotation(veh, rx, ry, rz, 2, true)
                                    SetVehicleSteeringAngle(veh, steer)
                                    if rpm then SetVehicleCurrentRpm(veh, rpm) end
                                    if f0.handbrake ~= nil then SetVehicleHandbrake(veh, f0.handbrake == true) end
                                    SetEntityVelocity(veh, vector3(vx, vy, vz) + dp)
                                    if DriftSmoke then
                                        if not driftSmokeTrack[i] then driftSmokeTrack[i] = { active = false } end
                                        DriftSmoke.applyToPlayback(veh, driftSmokeTrack[i], rpm)
                                    end
                                else
                                    FreezeEntityPosition(veh, true)
                                    SetEntityCoordsNoOffset(veh, px, py, pz, false, false, false)
                                    SetEntityRotation(veh, rx, ry, rz, 2, true)
                                    if driftSmokeTrack[i] and driftSmokeTrack[i].active and DriftSmoke then
                                        DriftSmoke.stopPlayback(driftSmokeTrack[i])
                                    end
                                end
                            end
                        end
                    end
                end
            end

            for i, rec in ipairs(pedRecordings) do
                local frames = rec.frames
                if #frames >= 2 then
                    local endSec = trimEnd or (trimStart + rec.duration - trimIn)
                    local t      = playbackSec - trimStart + trimIn
                    if playbackSec < trimStart or endSec < playbackSec then
                        if pedSpawns[i] and DoesEntityExist(pedSpawns[i]) then
                            DeleteEntity(pedSpawns[i]); pedSpawns[i] = nil; pedSpawnReady[i] = false
                        end
                    else
                        if t < frames[1].t or t > rec.duration then
                            if pedSpawns[i] and DoesEntityExist(pedSpawns[i]) then
                                DeleteEntity(pedSpawns[i]); pedSpawns[i] = nil; pedSpawnReady[i] = false
                            end
                        else
                            if not (pedSpawns[i] and DoesEntityExist(pedSpawns[i])) then
                                spawnSinglePed(i)
                            else
                                while pedFrameIdx[i] < #frames - 1 and frames[pedFrameIdx[i] + 1].t <= t do
                                    pedFrameIdx[i] = pedFrameIdx[i] + 1
                                end
                                local fi    = pedFrameIdx[i]
                                local f0    = frames[fi]
                                local f1    = frames[math.min(fi + 1, #frames)]
                                local df    = f1.t - f0.t
                                local alpha = df > 0.001 and math.max(0, math.min(1, (t - f0.t) / df)) or 0
                                local px    = f0.px + ((f1.inVehicle and f0.px or f1.px) - f0.px) * alpha
                                local py    = f0.py + ((f1.inVehicle and f0.py or f1.py) - f0.py) * alpha
                                local pz    = f0.pz + ((f1.inVehicle and f0.pz or f1.pz) - f0.pz) * alpha
                                local rz    = lerpAngle(f0.rz, f1.inVehicle and f0.rz or f1.rz, alpha)
                                local ped   = pedSpawns[i]
                                if not f0.isRagdoll then
                                    if f0.isJumping then
                                        FreezeEntityPosition(ped, false)
                                        if not pedJumpState[i] then
                                            pedJumpState[i] = true; TaskJump(ped, true)
                                        end
                                    elseif f0.isVaulting or f0.isClimbing then
                                        FreezeEntityPosition(ped, false)
                                        if not pedClimbState[i] then
                                            pedClimbState[i] = true; TaskClimb(ped, true)
                                        end
                                    else
                                        pedJumpState[i] = nil; pedClimbState[i] = nil
                                        FreezeEntityPosition(ped, false)
                                        SetEntityVelocity(ped, 0, 0, 0)
                                        SetEntityCoordsNoOffset(ped, px, py, pz, false, false, false)
                                        SetEntityHeading(ped, rz)
                                    end
                                    if f0.weapon and f0.weapon ~= 0 then
                                        SetCurrentPedWeapon(ped, f0.weapon, true)
                                    end
                                    if f0.moveBlend then
                                        SetPedDesiredMoveBlendRatio(ped, f0.moveBlend)
                                    end
                                else
                                    if not pedRagdollState[i] then
                                        SetPedCanRagdoll(ped, true)
                                        FreezeEntityPosition(ped, false)
                                        SetEntityCoordsNoOffset(ped, px, py, pz, false, false, false)
                                        SetEntityVelocity(ped, f0.vx or 0, f0.vy or 0, f0.vz or 0)
                                        pedRagdollState[i] = true
                                    end
                                    SetPedToRagdoll(ped, 1000, 1000, 0, 0, 0, 0)
                                end
                            end
                        end
                    end
                end
            end

            for i, layer in ipairs(overlayLayers) do
                local rec    = layer.vehicleRec
                local frames = rec and rec.frames
                if frames and #frames >= 2 then
                    local endSec = layer.endSec or (layer.startSec + rec.duration - (layer.trimInSec or 0))
                    local t      = playbackSec - layer.startSec + (layer.trimInSec or 0)
                    if playbackSec < layer.startSec or endSec < playbackSec then
                        if layer.vehicleSpawn and DoesEntityExist(layer.vehicleSpawn) then
                            if layer.driftSmoke and DriftSmoke then DriftSmoke.stopPlayback(layer.driftSmoke) end
                            DeleteEntity(layer.vehicleSpawn); layer.vehicleSpawn = nil; layer.vehicleSpawning = false
                        end
                    else
                        if t < frames[1].t or t > rec.duration then
                            if layer.vehicleSpawn and DoesEntityExist(layer.vehicleSpawn) then
                                DeleteEntity(layer.vehicleSpawn); layer.vehicleSpawn = nil; layer.vehicleSpawning = false
                            end
                        else
                            if not (layer.vehicleSpawn and DoesEntityExist(layer.vehicleSpawn)) then
                                spawnOverlayVehicle(i)
                            else
                                while layer.vehicleFrameIdx < #frames - 1 and frames[layer.vehicleFrameIdx + 1].t <= t do
                                    layer.vehicleFrameIdx = layer.vehicleFrameIdx + 1
                                end
                                local fi  = layer.vehicleFrameIdx
                                local f0  = frames[fi]
                                local f1  = frames[math.min(fi + 1, #frames)]
                                local df  = f1.t - f0.t
                                local a   = df > 0.001 and math.max(0, math.min(1, (t - f0.t) / df)) or 0
                                local px  = f0.px + (f1.px - f0.px) * a
                                local py  = f0.py + (f1.py - f0.py) * a
                                local pz  = f0.pz + (f1.pz - f0.pz) * a + (rec.suspensionDelta or 0)
                                local vx  = f0.vx + (f1.vx - f0.vx) * a
                                local vy  = f0.vy + (f1.vy - f0.vy) * a
                                local vz  = f0.vz + (f1.vz - f0.vz) * a
                                local rx  = lerpAngle(f0.rx, f1.rx, a)
                                local ry  = lerpAngle(f0.ry, f1.ry, a)
                                local rz  = lerpAngle(f0.rz, f1.rz, a)
                                local st  = f0.steer + ((f1.steer or f0.steer) - f0.steer) * a
                                local rpm = f0.rpm and (f0.rpm + ((f1.rpm or f0.rpm) - f0.rpm) * a) or nil
                                local veh = layer.vehicleSpawn
                                if IsEntityOnScreen(veh) then
                                    FreezeEntityPosition(veh, false)
                                    local cur = GetEntityCoords(veh)
                                    local dp  = (vector3(px, py, pz) - cur) * 15.0
                                    SetEntityRotation(veh, rx, ry, rz, 2, true)
                                    SetVehicleSteeringAngle(veh, st)
                                    if rpm then SetVehicleCurrentRpm(veh, rpm) end
                                    if f0.handbrake ~= nil then SetVehicleHandbrake(veh, f0.handbrake == true) end
                                    SetEntityVelocity(veh, vector3(vx, vy, vz) + dp)
                                    if DriftSmoke then
                                        if not layer.driftSmoke then layer.driftSmoke = { active = false } end
                                        DriftSmoke.applyToPlayback(veh, layer.driftSmoke, rpm)
                                    end
                                else
                                    FreezeEntityPosition(veh, true)
                                    SetEntityCoordsNoOffset(veh, px, py, pz, false, false, false)
                                    SetEntityRotation(veh, rx, ry, rz, 2, true)
                                    if layer.driftSmoke and layer.driftSmoke.active and DriftSmoke then
                                        DriftSmoke.stopPlayback(layer.driftSmoke)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end 
    end     
end)        

