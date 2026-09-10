
DriftSmoke                = {}

local rawCfg              = (Config and Config.DriftSmoke) or {}

local cfg                 = {
    Particles    = {},
    ParticleName = "scr_recartheft",
    ParticleBase = "core",
    Enabled      = (rawCfg.Enabled ~= false),
    SmokeON      = (rawCfg.PlayerThreadOn == true),
    Density      = rawCfg.Density or 7,
    Scale        = rawCfg.Scale or 0.12,
    BackOnly     = (rawCfg.BackOnly ~= false),
}

local wheelBones          = cfg.BackOnly
    and { "wheel_lr", "wheel_rr" }
    or { "wheel_lr", "wheel_rr", "wheel_lf", "wheel_rf" }

local PLAYBACK_MIN_SPEED  = rawCfg.PlaybackMinSpeed or 3.0
local PLAYBACK_COS_LIMIT  = rawCfg.PlaybackCosLimit or 0.94
local BURNOUT_RPM_HI      = rawCfg.BurnoutRpmHi or 0.85
local BURNOUT_SPEED_LIMIT = rawCfg.BurnoutSpeed or 12.0
local REDLINE_RPM         = rawCfg.RedlineRpm or 0.97

local isReady             = false

DriftSmoke.config         = cfg

local function loadParticleFx(assetName)
    RequestNamedPtfxAsset(assetName)
    while not HasNamedPtfxAssetLoaded(assetName) do
        Wait(0)
    end
end

local function calculateDriftParams(vehicle)
    if not vehicle or vehicle == 0 then
        return 0, 0
    end

    local velX, velY = table.unpack(GetEntityVelocity(vehicle))
    local horizSpeed = math.sqrt(velX * velX + velY * velY)

    local _, _, rotZ = table.unpack(GetEntityRotation(vehicle, 0))
    local headingX   = -math.sin(math.rad(rotZ))
    local headingY   = math.cos(math.rad(rotZ))

    local kphSpeed   = GetEntitySpeed(vehicle) * 3.6

    if kphSpeed < 5 or GetVehicleCurrentGear(vehicle) == 0 then
        return 0, horizSpeed
    end

    local forwardDot = (headingX * velX + headingY * velY) / horizSpeed

    if forwardDot > 0.966 or forwardDot < 0 then
        return 0, horizSpeed
    end

    local driftAngle = math.deg(math.acos(forwardDot)) * 0.5
    return driftAngle, horizSpeed
end

DriftSmoke.calculateDriftParams = calculateDriftParams

local function spawnSmokeOnVehicle(particleName, effectName, vehicle, density, scale)
    local spawnedHandles = cfg.Particles

    for _ = 1, density do
        for _, bone in ipairs(wheelBones) do
            UseParticleFxAssetNextCall(particleName)
            local handle = StartParticleFxLoopedOnEntityBone(
                effectName,
                vehicle,
                0, 0, 0,
                0, 0, 0,
                GetEntityBoneIndexByName(vehicle, bone),
                scale,
                false, false, false
            )
            spawnedHandles[#spawnedHandles + 1] = handle
        end
    end

    Wait(1000)

    for _, handle in ipairs(spawnedHandles) do
        StopParticleFxLooped(handle, true)
    end

    cfg.Particles = {}
end

local function isSmoking(vehicle, engineRpm)
    local velX, velY   = table.unpack(GetEntityVelocity(vehicle))
    local horizSpeed   = math.sqrt(velX * velX + velY * velY)

    local _, _, rotZ   = table.unpack(GetEntityRotation(vehicle, 0))
    local headingX     = -math.sin(math.rad(rotZ))
    local headingY     = math.cos(math.rad(rotZ))

    local forwardSpeed = headingX * velX + headingY * velY

    if horizSpeed >= PLAYBACK_MIN_SPEED and forwardSpeed > 0 then
        if (forwardSpeed / horizSpeed) < PLAYBACK_COS_LIMIT then
            return true
        end
    end

    if engineRpm then
        if engineRpm > REDLINE_RPM then
            return true
        end

        if engineRpm > BURNOUT_RPM_HI then
            if math.abs(forwardSpeed) < BURNOUT_SPEED_LIMIT then
                return true
            end
        end
    end

    return false
end

function DriftSmoke.applyToPlayback(vehicle, state, rpm)
    if not cfg.Enabled then return end
    if not isReady then return end

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return
    end

    if isSmoking(vehicle, rpm) then
        local now     = GetGameTimer()
        local elapsed = now - (state.lastSpawn or 0)

        if elapsed >= 1000 then
            
            if state.particles then
                for _, handle in ipairs(state.particles) do
                    StopParticleFxLooped(handle, true)
                end
            end

            state.particles = {}

            for _ = 1, cfg.Density do
                for _, bone in ipairs(wheelBones) do
                    UseParticleFxAssetNextCall(cfg.ParticleName)
                    local handle = StartParticleFxLoopedOnEntityBone(
                        "scr_wheel_burnout",
                        vehicle,
                        0, 0, 0,
                        0, 0, 0,
                        GetEntityBoneIndexByName(vehicle, bone),
                        cfg.Scale,
                        false, false, false
                    )
                    state.particles[#state.particles + 1] = handle
                end
            end

            state.lastSpawn = now
            state.active    = true
        end
    else
        if state.active then
            if state.particles then
                for _, handle in ipairs(state.particles) do
                    StopParticleFxLooped(handle, true)
                end
            end

            state.particles = {}
            state.active    = false
        end
    end
end

function DriftSmoke.stopPlayback(state)
    if not state then return end

    if state.particles then
        for _, handle in ipairs(state.particles) do
            StopParticleFxLooped(handle, true)
        end
    end

    state.particles = {}
    state.active    = false
    state.lastSpawn = nil
end

CreateThread(function()
    if not cfg.Enabled then return end

    loadParticleFx(cfg.ParticleName)
    loadParticleFx(cfg.ParticleBase)

    isReady = true

    while true do
        Wait(0)

        if cfg.SmokeON then
            local ped                    = PlayerPedId()
            local vehicle                = GetVehiclePedIsUsing(ped)

            local driftAngle, horizSpeed = calculateDriftParams(vehicle)

            if horizSpeed >= 3.0 and driftAngle ~= 0 then
                spawnSmokeOnVehicle(cfg.ParticleName, "scr_wheel_burnout", vehicle, cfg.Density, cfg.Scale)
            elseif driftAngle < 2.0 and driftAngle > 1.0 then
                spawnSmokeOnVehicle(cfg.ParticleName, "scr_wheel_burnout", vehicle, cfg.Density, cfg.Scale)
            end
        end
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for _, handle in ipairs(cfg.Particles) do
        StopParticleFxLooped(handle, true)
    end

    cfg.Particles = {}
end)

