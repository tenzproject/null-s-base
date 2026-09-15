--[[
    Null player lifecycle orchestrator (v2)
    -----------------------------------------
    Loading screen -> enter phase (caméra cinématique sur la ville) -> spawn.

    Garanties :
      * La phase Enter reste ouverte INDÉFINIMENT (aucun timeout). Le joueur peut
        laisser l'écran ouvert 10 min puis cliquer "Entrer".
      * Le reveal ne laisse JAMAIS le joueur bloqué dans les airs : la collision et
        le sol sont entièrement chargés AVANT de défreezer le ped.
      * Aucun thread concurrent ne re-téléporte le ped pendant le reveal.

    Events émis (client) :
      null:player:lifecycle (state)
      null:player:loading
      null:player:noCharacter
      null:player:loadCharacter (skin)
      null:player:enterPhase
      null:player:spawned (isFirstSpawn)
      null:player:respawned

    États : boot -> loading -> (creator) -> enter -> spawned
]]

LoadingConfig = {
    -- Spawn direct après le chargement : aucune phase d'entrée/cinématique.
    enterPhase   = false,
    fallbackModel = `mp_m_freemode_01`,
    fallbackSpawn = vector3(-269.4, -955.66, 31.22),
    spawnWatchdog = 20000,  -- watchdog AVANT la phase enter uniquement
    streamTimeout = 20000,  -- temps max de chargement du monde au reveal

    -- Caméra cinématique de la phase Enter : survol lent des gratte-ciels de
    -- Los Santos (Pillbox Hill / Maze Bank Tower).
    scenic = {
        center      = vector3(-120.0, -800.0, 75.0), -- point regardé (cœur des tours)
        pedPark     = vector3(-120.0, -800.0, 30.0), -- où parquer le ped (invisible)
        orbitRadius = 500.0,                          -- distance horizontale cam<->centre
        orbitHeight = 285.0,                          -- hauteur de la cam au-dessus du centre
        orbitSpeed  = 0.0028,                         -- deg/ms (~2.8 deg/s => tour en ~128s)
        orbitStart  = 210.0,                          -- angle de départ (vue sud-ouest)
        fov         = 58.0,
        streamRadius = 700.0,
    },
}

local function logDbg(msg) print(('^5[null-loading]^7 %s'):format(msg)) end

local STATE = { BOOT = 'boot', LOADING = 'loading', CREATOR = 'creator', ENTER = 'enter', SPAWNED = 'spawned' }

local currentState   = STATE.BOOT
local firstSpawn     = true
local enterCam       = nil
local currentXPlayer = nil
local enterThreadId  = 0        -- identifiant du thread enter courant (anti-concurrence)
local revealing      = false    -- true pendant DoEnterReveal (bloque le thread enter)
local hadLoadscreenAtStart = GetIsLoadingScreenActive()
local blurAddonActive = false

local function setState(s)
    if currentState == s then return end
    currentState = s
    TriggerEvent('null:player:lifecycle', s)
end

exports('getLifecycleState', function() return currentState end)
exports('isFirstSpawn', function() return firstSpawn end)

local function PushStatus(progress, message)
    SendLoadingScreenMessage(json.encode({ type = 'UPDATE_PROGRESS', progress = progress, message = message }))
end

local function PushNui(payload)
    SendLoadingScreenMessage(json.encode(payload))
end

-- Position de spawn fiable (lastPosition si valide, sinon fallback).
local function ResolveSpawnCoords()
    local lp = ESX and ESX.PlayerData and ESX.PlayerData.lastPosition
    if lp and lp.x and lp.y and lp.z and (math.abs(lp.x) > 50.0 or math.abs(lp.y) > 50.0) then
        return vector3(lp.x + 0.0, lp.y + 0.0, lp.z + 0.0)
    end
    return LoadingConfig.fallbackSpawn
end

-- ============================================================================
-- Chargement robuste du monde autour d'un point (anti "bloqué dans les airs").
-- Garde le ped EN PLACE et FROZEN, charge collision + scène, puis cale au sol.
-- ============================================================================
local function RobustGroundLoad(ped, coords)
    local x, y, z = coords.x + 0.0, coords.y + 0.0, coords.z + 0.0

    -- Le ped doit rester figé et positionné pendant tout le chargement.
    FreezeEntityPosition(ped, true)
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)

    SetFocusPosAndVel(x, y, z, 0.0, 0.0, 0.0)
    NewLoadSceneStartSphere(x, y, z, 150.0, 0)

    local deadline = GetGameTimer() + LoadingConfig.streamTimeout
    while GetGameTimer() < deadline do
        RequestCollisionAtCoord(x, y, z)
        -- Réaffirme la position à chaque frame (rien d'autre ne doit le bouger).
        SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)

        local colReady   = HasCollisionLoadedAroundEntity(ped)
        local sceneReady = (not IsNewLoadSceneActive()) or IsNewLoadSceneLoaded()
        if colReady and sceneReady then break end
        Wait(0)
    end

    NewLoadSceneStop()

    -- Cale le ped exactement sur le sol si on le trouve à proximité (±8 m).
    -- Évite la chute (sol pas encore là) ET le spawn sous la map.
    local foundZ = false
    for _, dz in ipairs({ 0.5, 2.0, 5.0, 10.0 }) do
        local ok, groundZ = GetGroundZFor_3dCoord(x, y, z + dz, false)
        if ok and groundZ and math.abs(groundZ - z) < 8.0 then
            SetEntityCoordsNoOffset(ped, x, y, groundZ + 0.05, false, false, false)
            foundZ = true
            break
        end
    end

    ClearFocus()
    return foundZ
end

-- Durées des animations CSS de l'enter phase (cf. style.css).
local SHUTTERS_CLOSE_MS = 1300
local SHUTTERS_OPEN_MS  = 1200

-- ============================================================================
-- REVEAL : le joueur a cliqué "Entrer".
-- ============================================================================
local function DoEnterReveal()
    if currentState ~= STATE.ENTER or revealing then return end
    revealing = true
    enterThreadId = enterThreadId + 1 -- invalide le thread enter (il s'arrête)
    logDbg('enter confirmed -> revealing world')

    -- 1) Ferme les shutters (écran couvert). On attend la fin de l'animation
    --    AVANT de bouger le ped : tout se passe caché.
    PushNui({ type = 'TRIGGER_ENTER' })
    Wait(SHUTTERS_CLOSE_MS)

    -- 2) Coupe la caméra scenic (l'écran est couvert, invisible pour le joueur).
    RenderScriptCams(false, false, 0, true, true)
    if enterCam and DoesCamExist(enterCam) then
        DestroyCam(enterCam, false)
        enterCam = nil
    end

    -- 3) Place le ped au spawn et charge le monde COMPLÈTEMENT (ped frozen).
    local spawn = ESX.PositionBeforeEnterCam or ResolveSpawnCoords()
    local ped = PlayerPedId()
    RobustGroundLoad(ped, spawn)

    -- 4) Active le ped. Le défreeze est fait EN DERNIER, une fois la collision OK.
    SetEntityVisible(ped, true)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
    SetPlayerControl(PlayerId(), true, 0)
    DoScreenFadeIn(0)
    ClearFocus()
    FreezeEntityPosition(ped, false) -- <-- défreeze seulement maintenant

    -- 5) Notifs + HUD + minimap.
    TriggerServerEvent("null:loading:playerLoaded", spawn)
    DisplayRadar(true)
    null.DisplayHud(true, 999)
    loadMapType(mapConfig and mapConfig.mapType or "square")

    setState(STATE.SPAWNED)
    TriggerEvent('null:player:spawned', true)

    -- 6) Filet de sécurité : si le ped tombe (collision pas finie), on le recale.
    CreateThread(function()
        local check = GetGameTimer() + 4000
        while GetGameTimer() < check do
            local p = PlayerPedId()
            if IsPedFalling(p) or GetEntityHeightAboveGround(p) > 3.0 then
                RequestCollisionAtCoord(spawn.x, spawn.y, spawn.z)
                local ok, gz = GetGroundZFor_3dCoord(spawn.x, spawn.y, spawn.z + 5.0, false)
                if ok and gz then
                    SetEntityCoordsNoOffset(p, spawn.x, spawn.y, gz + 0.05, false, false, false)
                end
            end
            Wait(200)
        end
    end)

    -- 7) Ouvre les shutters puis ferme le loadscreen.
    PushNui({ type = 'FADE_OUT' })
    Wait(SHUTTERS_OPEN_MS)

    ShutdownLoadingScreenNui()
    ShutdownLoadingScreen()
    revealing = false
end

RegisterNUICallback('loadingEnter', function(_, cb)
    if cb then cb({ ok = true }) end
    DoEnterReveal()
end)

local function BuildPlayerData(xPlayer)
    local data = {
        firstname = xPlayer.firstname or 'John',
        lastname  = xPlayer.lastname or 'Doe',
        sex       = xPlayer.sex or '0',
        accounts  = {},
        playtime  = xPlayer.playtime or 0,
        vip       = xPlayer.vip or { isVip = false, type = nil, time = {} },
    }
    if xPlayer.accounts then
        for _, account in ipairs(xPlayer.accounts) do
            data.accounts[account.name] = account.money
        end
    end
    return data
end

RegisterNUICallback('blurProposalAction', function(data, cb)
    if cb then cb({ ok = true }) end
    if data and data.action == 'install' then
        TriggerServerEvent('null:loading:blurInstallKick')
        return
    end
    if data and data.action == 'skip' then
        SetResourceKvp('Null_blur_refused', 'true')
    end
    if currentXPlayer then
        PushNui({ type = 'BLUR_PROPOSAL_DONE', playerData = BuildPlayerData(currentXPlayer) })
    end
end)

RegisterNUICallback('blurStateUpdate', function(data, cb)
    if cb then cb({ ok = true }) end
    if data and type(data.active) == 'boolean' then
        blurAddonActive = data.active
    end
end)

RegisterNUICallback('blurOpenUrl', function(data, cb)
    if cb then cb({ ok = true }) end
    if data and data.url then
        TriggerEvent('null:client:openUrl', data.url)
    end
end)

-- ============================================================================
-- Enter phase : caméra cinématique + ped parqué invisible.
-- ============================================================================

local function SetupScenicCamera()
    local sc  = LoadingConfig.scenic
    local ped = PlayerPedId()

    null.DisplayHud(false, 999)
    DisplayRadar(false)

    -- Parque le ped (invisible, frozen, invincible) au centre-ville pour que le
    -- décor stream correctement derrière la caméra.
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, false)
    FreezeEntityPosition(ped, true)
    SetEntityCoordsNoOffset(ped, sc.pedPark.x, sc.pedPark.y, sc.pedPark.z, false, false, false)

    -- Force le streaming du décor autour du point regardé.
    SetFocusPosAndVel(sc.center.x, sc.center.y, sc.center.z, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(sc.center.x, sc.center.y, sc.center.z)

    if enterCam and DoesCamExist(enterCam) then
        DestroyCam(enterCam, false)
        enterCam = nil
    end

    -- Position initiale de la cam sur l'orbite.
    local rad = math.rad(sc.orbitStart)
    local camX = sc.center.x + math.cos(rad) * sc.orbitRadius
    local camY = sc.center.y + math.sin(rad) * sc.orbitRadius
    local camZ = sc.center.z + sc.orbitHeight

    enterCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(enterCam, camX, camY, camZ)
    PointCamAtCoord(enterCam, sc.center.x, sc.center.y, sc.center.z)
    SetCamFov(enterCam, sc.fov)
    SetCamActive(enterCam, true)
    RenderScriptCams(true, false, 0, true, true)

    DoScreenFadeIn(0)
end

local function ShowEnterScreen(xPlayer)
    setState(STATE.ENTER)
    currentXPlayer = xPlayer
    TriggerServerEvent("null:loading:playerInEnter", ESX.PositionBeforeEnterCam)

    local blurRefused = GetResourceKvpString('Null_blur_refused') == 'true'

    if not blurAddonActive and not blurRefused then
        PushNui({ type = 'SHOW_BLUR_PROPOSAL' })
    else
        PushNui({ type = 'SHOW_ENTER_SCREEN', playerData = BuildPlayerData(xPlayer) })
    end

    SetupScenicCamera()
    TriggerEvent('null:player:enterPhase')

    -- Thread cinématique : orbite la caméra + maintient le ped parqué.
    -- AUCUN timeout : tourne tant qu'on est en ENTER (le joueur peut attendre
    -- indéfiniment). S'arrête net quand DoEnterReveal incrémente enterThreadId.
    enterThreadId = enterThreadId + 1
    local myId = enterThreadId
    local sc = LoadingConfig.scenic
    local startTime = GetGameTimer()

    CreateThread(function()
        while currentState == STATE.ENTER and myId == enterThreadId and not revealing do
            local ped = PlayerPedId()
            -- Maintient le ped hors-jeu (invisible + figé).
            if IsEntityVisible(ped) then SetEntityVisible(ped, false) end
            FreezeEntityPosition(ped, true)

            -- Orbite lente de la caméra autour du centre-ville.
            if enterCam and DoesCamExist(enterCam) then
                local angle = sc.orbitStart + (GetGameTimer() - startTime) * sc.orbitSpeed
                local r = math.rad(angle)
                local camX = sc.center.x + math.cos(r) * sc.orbitRadius
                local camY = sc.center.y + math.sin(r) * sc.orbitRadius
                local camZ = sc.center.z + sc.orbitHeight
                SetCamCoord(enterCam, camX, camY, camZ)
                PointCamAtCoord(enterCam, sc.center.x, sc.center.y, sc.center.z)
            end

            -- Garde le focus de streaming sur la ville.
            SetFocusPosAndVel(sc.center.x, sc.center.y, sc.center.z, 0.0, 0.0, 0.0)

            Wait(0)
        end
    end)
end

-- ============================================================================
-- First spawn sequence
-- ============================================================================

local function StartFirstSpawnSequence()
    while not ESX.PlayerLoaded do Wait(10) end
    logDbg('ESX.PlayerLoaded ok, resolving spawn coords')

    ESX.PositionBeforeEnterCam = ResolveSpawnCoords()
    setState(STATE.LOADING)
    TriggerEvent('null:player:loading')
    logDbg(('hadLoadscreenAtStart = %s'):format(tostring(hadLoadscreenAtStart)))

    PushNui({
        type = 'INIT_CORE',
        serverName = GetConvar('serverName', 'Null V4'),
        serverCHAR = GetConvar('serverCHAR', 'img/logo.png'),
        hexcolor   = GetConvar('hexcolor', '#BEEE11'),
        serverBackground = GetConvar('backgroundBanner', GetConvar('bannerUrl', '')),
    })
    SetNuiFocus(false, false)

    local skinDone, hasCharacter, playerSkin = false, false, nil
    PushStatus(15, 'Chargement des ressources protégées...')
    ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
        playerSkin = skin
        hasCharacter = skin ~= nil
        skinDone = true
    end)

    PushStatus(45, 'Chargement du framework...')
    Wait(150)
    PushStatus(70, 'Initialisation des modules core...')
    Wait(150)
    PushStatus(90, 'Finalisation...')

    local timeout = GetGameTimer() + 8000
    while not skinDone and GetGameTimer() < timeout do Wait(25) end
    PushStatus(100, 'Prêt')

    if not hasCharacter then
        setState(STATE.CREATOR)
        -- Écran noir AVANT de couper le loading screen : évite le flash du
        -- monde. Le créateur révèle ensuite en fondu (cf. OpenNewCreator).
        DoScreenFadeOut(0)
        ShutdownLoadingScreenNui()
        ShutdownLoadingScreen()
        TriggerEvent('null:player:noCharacter')
        TriggerEvent('null:newCreator:open', true)
        return
    end

    -- Le skinchanger peut remplacer le ped lorsqu'il charge le modèle de
    -- freemode. On attend son callback avant de relâcher le joueur, sinon il
    -- apparaît avec le modèle fallback, sans tenue, ou reste figé.
    local skinApplied = false
    TriggerEvent('null:player:loadCharacter', playerSkin, function()
        skinApplied = true
    end)

    local skinDeadline = GetGameTimer() + 12000
    while not skinApplied and GetGameTimer() < skinDeadline do
        Wait(0)
    end
    if not skinApplied then
        logDbg('^3skin callback timeout, releasing spawn with the current ped^7')
    end

    if not LoadingConfig.enterPhase then
        -- Toujours relire le ped après le changement de modèle.
        local ped = PlayerPedId()
        RobustGroundLoad(ped, ESX.PositionBeforeEnterCam)
        SetPlayerControl(PlayerId(), true, false)
        SetEntityVisible(ped, true)
        SetEntityCollision(ped, true, true)
        SetEntityInvincible(ped, false)
        FreezeEntityPosition(ped, false)
        DoScreenFadeIn(0)
        ClearFocus()
        TriggerServerEvent("null:loading:playerLoaded", ESX.PositionBeforeEnterCam)
        DisplayRadar(true)
        null.DisplayHud(true, 999)
        loadMapType(mapConfig and mapConfig.mapType or "square")
        setState(STATE.SPAWNED)
        TriggerEvent('null:player:spawned', true)
        ShutdownLoadingScreenNui()
        ShutdownLoadingScreen()
        return
    end

    ShowEnterScreen(ESX.GetPlayerData())
end

local spawningInProgress = false

AddEventHandler('playerSpawned', function()
    if spawningInProgress then return end
    if not firstSpawn then
        TriggerEvent('null:player:respawned')
        return
    end
    firstSpawn = false
    logDbg('playerSpawned (external) -> starting first spawn sequence')
    Citizen.CreateThread(StartFirstSpawnSequence)
end)

-- ============================================================================
-- Spawn inline (sans spawnmanager) — garde le ped caché jusqu'à la phase Enter.
-- ============================================================================
local function performInlineSpawn(coords, heading)
    local playerId = PlayerId()
    local model = LoadingConfig.fallbackModel

    SetPlayerControl(playerId, false, false)
    local ped = PlayerPedId()
    SetEntityVisible(ped, false)
    SetEntityCollision(ped, false, false)
    FreezeEntityPosition(ped, true)
    SetPlayerInvincible(playerId, true)

    RequestModel(model)
    local mdlDeadline = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < mdlDeadline do
        RequestModel(model)
        Wait(0)
    end
    SetPlayerModel(playerId, model)
    SetModelAsNoLongerNeeded(model)

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading or 0.0, true, false)
    ClearPedTasksImmediately(ped)
    RemoveAllPedWeapons(ped, false)

    local colDeadline = GetGameTimer() + 5000
    while not HasCollisionLoadedAroundEntity(PlayerPedId()) and GetGameTimer() < colDeadline do Wait(0) end

    SetPlayerControl(playerId, true, false)
    SetPlayerInvincible(playerId, false)
    -- Le ped reste invisible/frozen : SetupScenicCamera s'en chargera ensuite.

    ShutdownLoadingScreen()
end

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while ESX == nil or not ESX.PlayerLoaded do Wait(50) end

    local spawnCoords = ResolveSpawnCoords()
    logDbg(('inline spawn @ %.2f, %.2f, %.2f'):format(spawnCoords.x, spawnCoords.y, spawnCoords.z))

    spawningInProgress = true
    performInlineSpawn(spawnCoords, 0.0)
    firstSpawn = false

    TriggerEvent('playerSpawned', { x = spawnCoords.x, y = spawnCoords.y, z = spawnCoords.z, heading = 0.0 }, true)
    spawningInProgress = false

    Citizen.CreateThread(StartFirstSpawnSequence)

    -- Watchdog : ne se déclenche QUE si la séquence se bloque AVANT d'atteindre
    -- enter/creator/spawned. La phase Enter elle-même n'a aucun timeout.
    Wait(LoadingConfig.spawnWatchdog)
    if currentState == STATE.BOOT or currentState == STATE.LOADING then
        logDbg('^1WATCHDOG: séquence bloquée avant ENTER, libération du loadscreen^7')
        ShutdownLoadingScreenNui()
        ShutdownLoadingScreen()
    end
end))

-- Commande de secours pour débloquer manuellement un écran resté affiché.
RegisterCommand("debug", function()
    TriggerScreenblurFadeOut(1000)
    SetNuiFocus(false, false)
    pcall(function() exports["null-core"]:ActiveFrontend(false) end)
    null.DisplayHud(true, 999)
    pcall(function() exports["chat"]:setChatCanOpen(true) end)
    SetPlayerControl(PlayerId(), true, 12)
    if enterCam and DoesCamExist(enterCam) then
        DestroyCam(enterCam, false)
        enterCam = nil
    end
    RenderScriptCams(false, false, 0, true, true)
    ClearFocus()
    FreezeEntityPosition(PlayerPedId(), false)
    SetEntityVisible(PlayerPedId(), true)
    DoScreenFadeIn(0)
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
end)
