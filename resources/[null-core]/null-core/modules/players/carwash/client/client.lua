-- ============================================================
--  Carwash — Client
--  Menu RageUI + animation tunnel (rouleaux/jets) ou lavage
--  rapide (progress bar + jets).
--  La fonction `openWarcash()` reste exposée globalement, elle
--  est déclenchée par `modules/_core/markers/client/setup.lua`.
-- ============================================================

local CFG = Config.CarWash

local PROPS = {
    rollerH    = "prop_carwash_roller_horz",
    rollerV    = "prop_carwash_roller_vert",
    raycastRef = "prop_ld_test_01",
    waypoint   = "carwash2_r",
    ptfx       = "scr_carwash",
    ptfxJet    = "ent_amb_car_wash_jet",
}

local State = {
    busy  = false,
    spray = {},
}

-- ============================================================
-- Helpers
-- ============================================================
local function notify(msg)
    if ESX and ESX.ShowNotification then
        ESX.ShowNotification(msg)
    end
end

local function requestModel(name)
    if not IsModelInCdimage(name) then return false end
    if HasModelLoaded(name) then return true end
    RequestModel(name)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(name) and GetGameTimer() < timeout do Wait(50) end
    return HasModelLoaded(name)
end

local function getNearestStation()
    local me = GetEntityCoords(PlayerPedId())
    local best, bestDist
    for _, st in ipairs(CFG.List or {}) do
        if st.Position then
            local d = #(me - vector3(st.Position.x, st.Position.y, st.Position.z))
            if not bestDist or d < bestDist then
                best, bestDist = st, d
            end
        end
    end
    return best, bestDist or 9999
end

local function getDriverVehicle()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if not veh or veh == 0 then return nil end
    if GetPedInVehicleSeat(veh, -1) ~= ped then return nil end
    return veh
end

-- ============================================================
-- Animation "Tunnel" (style usine Vinewood)
-- ============================================================
local function jet(carEnt, sprayProp)
    local hl  = 4.85 / 2.0
    local fl  = -3.6 / 2.0
    local fxs = {}

    for i = 1, 4 do
        local mirror = (i % 2) == 0
        UseParticleFxAssetNextCall(PROPS.ptfx)
        fxs[i] = StartParticleFxLoopedOnEntity(
            PROPS.ptfxJet, sprayProp,
            mirror and -hl or hl, 0.0,
            (-fl * (i > 2 and 0.75 or 0.0)) - 2,
            mirror and vec3(90, 90, 0) or -vec3(90, 90, 0),
            1.0
        )
    end

    local snd = GetSoundId()
    PlaySoundFromEntity(snd, "SPRAY", carEnt, "CARWASH_SOUNDS", false, 0)
    Wait(5000)
    StopSound(snd)

    for _, f in pairs(fxs) do
        StopParticleFxLooped(f, 0)
        RemoveParticleFx(f, 0)
    end
end

local function moveSideRoller(rollerProp, fromRight, targetX)
    local pos    = GetEntityCoords(rollerProp)
    local startX = pos.x

    local moveSnd = GetSoundId()
    PlaySoundFromEntity(moveSnd, "BRUSHES_MOVE", rollerProp, "CARWASH_SOUNDS", 0, 0)
    while (fromRight and pos.x > targetX) or (not fromRight and pos.x < targetX) do
        Wait(10)
        SetEntityCoords(rollerProp, pos.x - (fromRight and 0.01 or -0.01), pos.y, pos.z)
        pos = GetEntityCoords(rollerProp)
    end
    StopSound(moveSnd)

    local spinSnd = GetSoundId()
    PlaySoundFromEntity(spinSnd, "BRUSHES_SPINNING", rollerProp, "CARWASH_SOUNDS", 0, 0)
    local spinUntil = GetGameTimer() + 4000
    while GetGameTimer() < spinUntil do
        Wait(0)
        local r = GetEntityRotation(rollerProp, 2)
        SetEntityRotation(rollerProp, r.x, r.y, (r.z + 0.4) % 180.0, 2, 1)
    end
    StopSound(spinSnd)

    Citizen.CreateThread(function()
        while (fromRight and pos.x < startX) or (not fromRight and pos.x > startX) do
            Wait(10)
            SetEntityCoords(rollerProp, pos.x + (fromRight and 0.01 or -0.01), pos.y, pos.z)
            pos = GetEntityCoords(rollerProp)
        end
    end)
end

local function runSideRollers(carVeh)
    local L = State.spray.leftRoller
    local R = State.spray.rightRoller
    local minDim, maxDim = GetModelDimensions(GetEntityModel(carVeh))
    local pos     = GetEntityCoords(carVeh)
    local halfLen = (math.abs(minDim.x) + math.abs(maxDim.x)) / 2

    Citizen.CreateThread(function()
        moveSideRoller(L, true, pos.x + halfLen + 0.3)
    end)
    moveSideRoller(R, false, pos.x - halfLen - 0.3)
end

local function runTopRoller(carVeh, tunnel)
    local roller = State.spray.rollerUp
    local _, groundZ = GetGroundZFor_3dCoord(tunnel.Roller.x, tunnel.Roller.y, tunnel.Roller.z, 0)
    local minDim, maxDim = GetModelDimensions(GetEntityModel(carVeh))
    local targetZ = groundZ + math.abs(minDim.z) + math.abs(maxDim.z) + 0.3
    local pos     = GetEntityCoords(roller)
    local startZ  = pos.z

    local snd = GetSoundId()
    PlaySoundFromEntity(snd, "BRUSHES_MOVE", roller, "CARWASH_SOUNDS", 0, 0)
    while pos.z > targetZ do
        Wait(10)
        SetEntityCoords(roller, pos.x, pos.y, pos.z - 0.02)
        pos = GetEntityCoords(roller)
    end
    StopSound(snd)

    snd = GetSoundId()
    PlaySoundFromEntity(snd, "BRUSHES_SPINNING", roller, "CARWASH_SOUNDS", 0, 0)
    local spinUntil = GetGameTimer() + 4000
    while GetGameTimer() < spinUntil do
        Wait(0)
        local r = GetEntityRotation(roller, 2)
        SetEntityRotation(roller, (r.x + 0.4) % 90, r.y, r.z, 2, 1)
    end
    StopSound(snd)

    Citizen.CreateThread(function()
        while pos.z < startZ do
            Wait(10)
            SetEntityCoords(roller, pos.x, pos.y, pos.z + 0.02)
            pos = GetEntityCoords(roller)
        end
    end)
end

local function spawnTunnelProps(tunnel)
    -- Rouleau supérieur
    local up = CreateObject(GetHashKey(PROPS.rollerH),
        tunnel.Roller.x, tunnel.Roller.y, tunnel.Roller.z, false, true, false)
    FreezeEntityPosition(up, true)
    SetEntityInvincible(up, true)
    SetEntityCollision(up, false, false)
    State.spray.rollerUp = up

    -- Repère central invisible
    local ref = CreateObject(GetHashKey(PROPS.raycastRef),
        tunnel.Center.x, tunnel.Center.y, tunnel.Center.z, false, true, false)
    SetEntityHeading(ref, 180.0)
    FreezeEntityPosition(ref, true)
    SetEntityCollision(ref, false, false)
    SetEntityCoordsNoOffset(ref, tunnel.Center.x, tunnel.Center.y, tunnel.Center.z, false, false, true)
    State.spray._ref = ref

    -- Sortie de jet finale
    local last = CreateObject(GetHashKey(PROPS.raycastRef),
        tunnel.LastSpray.x, tunnel.LastSpray.y, tunnel.LastSpray.z, false, true, false)
    SetEntityHeading(last, 180.0)
    FreezeEntityPosition(last, true)
    State.spray.lastSpray = last

    -- Sortie de jet d'entrée
    local first = CreateObject(GetHashKey(PROPS.raycastRef),
        tunnel.FirstSpray.x, tunnel.FirstSpray.y, tunnel.FirstSpray.z, false, true, false)
    SetEntityHeading(first, 0.0)
    FreezeEntityPosition(first, true)
    State.spray.firstSpray = first

    -- Rouleaux latéraux gauche / droite
    local lp = GetOffsetFromEntityInWorldCoords(ref, -tunnel.RollerWidth / 2.0, 0.0, 1.5)
    local lr = CreateObject(GetHashKey(PROPS.rollerV), lp, false, true, false)
    FreezeEntityPosition(lr, true)
    SetEntityCollision(lr, false, false)
    SetEntityInvincible(lr, true)
    SetEntityHasGravity(lr, false)
    SetEntityCoords(lr, lp, true, false, false, true)
    State.spray.leftRoller = lr

    local rp = GetOffsetFromEntityInWorldCoords(ref, tunnel.RollerWidth / 2.0, 0.0, 1.5)
    local rr = CreateObject(GetHashKey(PROPS.rollerV), rp, false, true, false)
    FreezeEntityPosition(rr, true)
    SetEntityCollision(rr, false, false)
    SetEntityInvincible(rr, true)
    SetEntityHasGravity(rr, false)
    SetEntityCoords(rr, rp, true, false, false, true)
    State.spray.rightRoller = rr
end

local function loadTunnelAssets()
    RequestScriptAudioBank("CARWASH_SOUNDS")
    RequestNamedPtfxAsset(PROPS.ptfx)
    while not HasNamedPtfxAssetLoaded(PROPS.ptfx) do Wait(50) end
    requestModel(PROPS.raycastRef)
    requestModel(PROPS.rollerV)
    requestModel(PROPS.rollerH)
    RequestWaypointRecording(PROPS.waypoint)
    while not GetIsWaypointRecordingLoaded(PROPS.waypoint) do Wait(0) end
end

local function unloadTunnelAssets(tunnel)
    SetModelAsNoLongerNeeded(PROPS.rollerV)
    SetModelAsNoLongerNeeded(PROPS.raycastRef)
    SetModelAsNoLongerNeeded(PROPS.rollerH)
    if IsAudioSceneActive("CAR_WASH_SCENE") then StopAudioScene("CAR_WASH_SCENE") end
    if tunnel.IplActive  then RemoveIpl(tunnel.IplActive)   end
    if tunnel.IplDefault then RequestIpl(tunnel.IplDefault) end
    for _, e in pairs(State.spray) do
        if DoesEntityExist(e) then DeleteEntity(e) end
    end
    State.spray = {}
end

local function followWaypoint(veh, recording, speed)
    SetVehicleDoorsShut(veh, true)
    TaskVehicleFollowWaypointRecording(PlayerPedId(), veh, recording, 262144, 0, 546, -1, speed, false, 1.25)
    VehicleWaypointPlaybackOverrideSpeed(veh, speed)
end

local function runTunnel(tunnel, veh, tier)
    if tunnel.IplDefault then RemoveIpl(tunnel.IplDefault)  end
    if tunnel.IplActive  then RequestIpl(tunnel.IplActive) end

    loadTunnelAssets()
    spawnTunnelProps(tunnel)

    SetEntityCoords(veh, tunnel.EntryPos.x, tunnel.EntryPos.y, tunnel.EntryPos.z)
    SetEntityHeading(veh, tunnel.Heading or 180.0)
    followWaypoint(veh, tunnel.Waypoint or PROPS.waypoint, tunnel.Speed or 1.5)
    Wait(2000)

    jet(veh, State.spray.firstSpray)
    runTopRoller(veh, tunnel)
    runSideRollers(veh)

    if tier.CleanDecals then WashDecalsFromVehicle(veh, true) end
    SetVehicleDirtLevel(veh, tier.FinalDirt or 0.0)

    jet(veh, State.spray.lastSpray)
    Wait(1000)
    unloadTunnelAssets(tunnel)

    PlaySoundFrontend(-1, "Out_Of_Bounds_Timer", "DLC_HEISTS_GENERAL_FRONTEND_SOUNDS", 0)
    ClearPedTasks(PlayerPedId())
end

-- ============================================================
-- Lavage rapide (sans animation tunnel)
-- ============================================================
local function runQuickWash(veh, tier)
    RequestNamedPtfxAsset(PROPS.ptfx)
    RequestScriptAudioBank("CARWASH_SOUNDS")
    while not HasNamedPtfxAssetLoaded(PROPS.ptfx) do Wait(50) end

    FreezeEntityPosition(veh, true)
    if ShowProgressBar then
        ShowProgressBar(tier.Duration or 8000, ("Lavage en cours — %s"):format(tier.Label or ""))
    end

    -- Jets latéraux + supérieur
    local fxs = {}
    for _, off in ipairs({
        { 1.2, 0.0, 0.6, vec3(0, 90, 0) },
        { -1.2, 0.0, 0.6, vec3(0, -90, 0) },
        { 0.0, 0.0, 1.8, vec3(90, 0, 0) },
    }) do
        UseParticleFxAssetNextCall(PROPS.ptfx)
        fxs[#fxs + 1] = StartParticleFxLoopedOnEntity(
            PROPS.ptfxJet, veh, off[1], off[2], off[3], off[4], 1.0
        )
    end

    local snd = GetSoundId()
    PlaySoundFromEntity(snd, "SPRAY", veh, "CARWASH_SOUNDS", false, 0)

    -- Doucement faire baisser la saleté pendant la durée
    local steps    = 20
    local interval = math.floor((tier.Duration or 8000) / steps)
    local startDirt = GetVehicleDirtLevel(veh)
    local endDirt   = tier.FinalDirt or 0.0
    for i = 1, steps do
        Wait(interval)
        local p = i / steps
        SetVehicleDirtLevel(veh, startDirt + (endDirt - startDirt) * p)
    end

    StopSound(snd)
    for _, f in ipairs(fxs) do
        StopParticleFxLooped(f, 0)
        RemoveParticleFx(f, 0)
    end

    if tier.CleanDecals then WashDecalsFromVehicle(veh, true) end
    SetVehicleDirtLevel(veh, endDirt)
    FreezeEntityPosition(veh, false)

    PlaySoundFrontend(-1, "Object_Dropped_Remote", "GTAO_FM_Events_Soundset", 0)
end

-- ============================================================
-- Démarre le lavage après validation serveur
-- ============================================================
local function startWash(tierKey, station, veh)
    if State.busy then return end
    State.busy = true

    ESX.TriggerServerCallback('null:carwash:wash', function(success, payload)
        if not success then
            State.busy = false
            return
        end

        Citizen.CreateThread(function()
            local ok, err = pcall(function()
                if station.Tunnel and tierKey == "premium" then
                    runTunnel(station.Tunnel, veh, payload)
                else
                    runQuickWash(veh, payload)
                end
            end)
            if not ok then print("[carwash] " .. tostring(err)) end

            notify(("~g~%s — -%d$"):format(payload.Label or "Lavage", payload.Price or 0))
            State.busy = false
        end)
    end, tierKey)
end

-- ============================================================
-- Menu d'interaction (appelé par le marker)
-- ============================================================
function openWarcash()
    if State.busy then return end

    local veh = getDriverVehicle()
    if not veh then
        notify("~r~Vous devez être au volant d'un véhicule")
        return
    end

    local station = getNearestStation()
    if not station then
        notify("~r~Station introuvable")
        return
    end

    local dirt           = GetVehicleDirtLevel(veh) or 0
    local hasTunnel      = station.Tunnel ~= nil
    local premiumAllowed = CFG.Settings.AllowPremium

    local main = RageUI.CreateMenu(station.Label or "Station de Lavage", "Choisissez une formule")
    RageUI.Visible(main, not RageUI.Visible(main))

    while main do
        Citizen.Wait(0)
        RageUI.IsVisible(main, function()
            RageUI.Separator(("Saleté du véhicule : ~y~%.1f / 15"):format(dirt))
            if hasTunnel then
                RageUI.Separator("Station ~b~automatique~s~ — animation rouleaux")
            else
                RageUI.Separator("Station ~b~self-service~s~ — lavage rapide")
            end

            -- Formule basique
            do
                local tier = CFG.Tiers.basic
                RageUI.Button(
                    tier.Label,
                    tier.Description,
                    {
                        RightLabel = ("~s~$%d"):format(tier.Price),
                        RightBadge = RageUI.BadgeStyle.Coins,
                    },
                    true,
                    {
                        onSelected = function()
                            if dirt < (CFG.Settings.DirtThreshold or 0) then
                                notify("~y~Votre véhicule est déjà propre")
                                return
                            end
                            RageUI.CloseAll()
                            startWash("basic", station, veh)
                        end
                    }
                )
            end

            -- Formule premium
            do
                local tier    = CFG.Tiers.premium
                local enabled = premiumAllowed
                local desc    = tier.Description
                if not premiumAllowed then
                    desc = (desc or "") .. "\n~r~Indisponible pour le moment."
                elseif not hasTunnel then
                    desc = (desc or "") .. "\n~y~Disponible uniquement en station automatique."
                end
                RageUI.Button(
                    tier.Label,
                    desc,
                    {
                        RightLabel = ("~s~$%d"):format(tier.Price),
                        RightBadge = RageUI.BadgeStyle.Coins,
                    },
                    enabled and hasTunnel,
                    {
                        onSelected = function()
                            if dirt < (CFG.Settings.DirtThreshold or 0) then
                                notify("~y~Votre véhicule est déjà propre")
                                return
                            end
                            RageUI.CloseAll()
                            startWash("premium", station, veh)
                        end
                    }
                )
            end
        end)

        if not RageUI.Visible(main) then
            main = RMenu:DeleteType('main', true)
        end
    end
end

-- ============================================================
-- Compatibilité ascendante
-- ============================================================
RegisterNetEvent('framework:cleanvehicle', function()
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    if veh and veh ~= 0 then
        SetVehicleDirtLevel(veh, 0.0)
    end
end)
