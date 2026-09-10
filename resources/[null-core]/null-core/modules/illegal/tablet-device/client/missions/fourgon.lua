-- ============================================================================
-- MISSION : VOL DE FOURGON
-- Un fourgon est garé, gardé par 6-8 pnj gang.
-- Premier coup de feu → les gardes ripostent.
-- Tuer les gardes, voler le fourgon, le livrer au point de dépôt.
-- ============================================================================

local M = nil

-- ─────────────────────────────────────────────
-- CONFIG
-- ─────────────────────────────────────────────

local ROUTES = {
    {
        label    = "Cypress Flats",
        spawn    = vector4(1101.1549, -2238.9700, 30.2283, 171.0807),
        delivery = vector3(2195.8696, 5607.1113, 53.5360),
    },
    {
        label    = "Elysian Island",
        spawn    = vector4(34.5315, -2669.6895, 5.9918, 3.3044),
        delivery = vector3(-1093.1001, 4945.5801, 218.3406),
    },
    {
        label    = "Rancho",
        spawn    = vector4(1909.2106, 565.9580, 175.7456, 238.6469),
        delivery = vector3(1538.9047, 6336.4648, 24.0683),
    },
}

-- Offsets des gardes autour du fourgon (relatifs à l'axe avant/droite du véhicule)
local GUARD_OFFSETS = {
    { ox =  4.0, oy =  2.0 },
    { ox = -4.0, oy =  2.0 },
    { ox =  4.0, oy = -2.0 },
    { ox = -4.0, oy = -2.0 },
    { ox =  0.0, oy =  6.0 },
    { ox =  0.0, oy = -6.0 },
    { ox =  6.0, oy =  0.0 },
    { ox = -6.0, oy =  0.0 },
}

local PED_MODELS = {
    "g_m_y_famca_01", "g_m_y_famdnf_01", "g_m_y_famfor_01",
    "g_m_y_ballasog_01", "g_m_y_ballas_01",
}

local WEAPON_PISTOL = GetHashKey("WEAPON_PISTOL")

-- ─────────────────────────────────────────────
-- HELPERS
-- ─────────────────────────────────────────────

local function LoadModel(name)
    local h = GetHashKey(name)
    if not IsModelValid(h) then return nil end
    RequestModel(h)
    local t = 0
    while not HasModelLoaded(h) and t < 4000 do Wait(10); t = t + 10 end
    return HasModelLoaded(h) and h or nil
end

local function SafeDel(e) if e and DoesEntityExist(e) then DeleteEntity(e) end end
local function Notif(msg) ESX.ShowNotification(msg) end

-- Convertit un offset local (ox=droite, oy=avant) en coordonnées monde
local function WorldOffset(origin, heading, ox, oy)
    local rad = math.rad(heading)
    local fx  = -math.sin(rad)
    local fy  =  math.cos(rad)
    return vector3(
        origin.x + fx * oy - fy * ox,
        origin.y + fy * oy + fx * ox,
        origin.z
    )
end

-- ─────────────────────────────────────────────
-- CLEANUP
-- ─────────────────────────────────────────────

local function Cleanup()
    if not M then return end
    SafeDel(M.veh)
    for _, p in ipairs(M.peds or {}) do SafeDel(p) end
    if M.vehBlip  and DoesBlipExist(M.vehBlip)  then RemoveBlip(M.vehBlip)  end
    if M.dBlip    and DoesBlipExist(M.dBlip)     then RemoveBlip(M.dBlip)    end
    M = nil
end

-- ─────────────────────────────────────────────
-- ALERTE : premier coup de feu reçu
-- ─────────────────────────────────────────────

local function OnAlert()
    if not M or M.alert then return end
    M.alert = true
    Notif("Les gardes ripostent.")

    for _, ped in ipairs(M.peds) do
        if not DoesEntityExist(ped) or IsEntityDead(ped) then goto continue end
        SetBlockingOfNonTemporaryEvents(ped, false)
        local pc = GetEntityCoords(ped)
        local nearest, nearestD = nil, 999.0
        for _, pid in ipairs(GetActivePlayers()) do
            local pp = GetPlayerPed(pid)
            if pp ~= 0 and DoesEntityExist(pp) and not IsEntityDead(pp) then
                local d = #(pc - GetEntityCoords(pp))
                if d < nearestD then nearestD = d; nearest = pp end
            end
        end
        if nearest then TaskCombatPed(ped, nearest, 0, 16) end
        ::continue::
    end
end

-- ─────────────────────────────────────────────
-- MONITORING
-- ─────────────────────────────────────────────

local PHASE_DURATION = 300000  -- 5 minutes en ms

local function Monitor()
    CreateThread(function()
        while M do
            Wait(300)
            if not M then break end

            local veh = M.veh
            if not DoesEntityExist(veh) then
                Notif("Fourgon détruit — Mission échouée.")
                Cleanup(); break
            end

            -- Timer phase 1 : 5 min pour récupérer le fourgon
            if not M.taken and GetGameTimer() - M.startTime > PHASE_DURATION then
                Notif("Temps écoulé — Mission échouée.")
                Cleanup(); break
            end

            -- Timer phase 2 : 5 min pour livrer
            if M.taken and M.takenTime and GetGameTimer() - M.takenTime > PHASE_DURATION then
                Notif("Délai de livraison dépassé — Mission échouée.")
                Cleanup(); break
            end

            -- Alerte : surveillance de la santé des gardes
            if not M.alert then
                for i, ped in ipairs(M.peds) do
                    if DoesEntityExist(ped) and GetEntityHealth(ped) < (M.pedHealth[i] or 200) then
                        OnAlert()
                        break
                    end
                end
            end

            -- Fourgon pris : joueur local au volant
            if not M.taken then
                if GetVehiclePedIsIn(PlayerPedId(), false) == veh then
                    M.taken     = true
                    M.takenTime = GetGameTimer()

                    if M.vehBlip and DoesBlipExist(M.vehBlip) then
                        RemoveBlip(M.vehBlip)
                    end

                    local dp = M.route.delivery
                    M.dBlip  = AddBlipForCoord(dp.x, dp.y, dp.z)
                    SetBlipSprite(M.dBlip, 1)
                    SetBlipColour(M.dBlip, 2)
                    SetBlipScale(M.dBlip, 1.0)
                    SetBlipRoute(M.dBlip, true)
                    SetBlipRouteColour(M.dBlip, 2)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString("Point de livraison")
                    EndTextCommandSetBlipName(M.dBlip)

                    Notif("Fourgon récupéré. Livrez-le au point indiqué.")
                end
            end

            -- Livraison
            if M.taken then
                if #(GetEntityCoords(veh) - M.route.delivery) < 12.0 then
                    TriggerServerEvent('null:missions:fourgon:complete', M.gang)
                    Notif("Livraison effectuée.")
                    Cleanup(); break
                end
            end
        end
    end)
end

local function StartTimerHUD()
    CreateThread(function()
        while M do
            Wait(0)
            if not M then break end

            local timeLeft
            if not M.taken then
                timeLeft = math.max(0, M.startTime + PHASE_DURATION - GetGameTimer())
            else
                timeLeft = math.max(0, (M.takenTime or M.startTime) + PHASE_DURATION - GetGameTimer())
            end

            local mins = math.floor(timeLeft / 60000)
            local secs = math.floor((timeLeft % 60000) / 1000)
            local r, g, b = 255, 255, 255
            if    timeLeft < 30000 then r, g, b = 220, 50,  50
            elseif timeLeft < 60000 then r, g, b = 230, 140, 0
            end

            local label = M.taken and "Livraison" or "Neutraliser"
            local text  = label .. "  " .. string.format("%02d:%02d", mins, secs)

            SetTextFont(4)
            SetTextScale(0.38, 0.38)
            SetTextColour(r, g, b, 220)
            SetTextDropShadow()
            SetTextJustification(0)
            SetTextEntry("STRING")
            AddTextComponentString(text)
            DrawText(0.5, 0.015)
        end
    end)
end

-- ─────────────────────────────────────────────
-- SPAWN
-- ─────────────────────────────────────────────

local function SpawnMission(data)
    if M then Notif("Une mission est déjà en cours."); return end

    CreateThread(function()
        local route = ROUTES[data.routeIndex]
        if not route then return end

        local sp  = route.spawn
        local hdg = sp.w

        -- Spawn du fourgon garé
        local vh = LoadModel("speedo")
        if not vh then return end
        local veh = CreateVehicle(vh, sp.x, sp.y, sp.z, hdg, true, false)
        SetEntityAsMissionEntity(veh, true, true)
        SetModelAsNoLongerNeeded(vh)
        SetVehicleEngineOn(veh, false, true, true)
        SetVehicleDirtLevel(veh, math.random(2, 6) * 1.0)

        -- Blip fourgon
        local vehBlip = AddBlipForEntity(veh)
        SetBlipSprite(vehBlip, 225)
        SetBlipColour(vehBlip, 1)
        SetBlipScale(vehBlip, 1.0)
        SetBlipAsShortRange(vehBlip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Fourgon")
        EndTextCommandSetBlipName(vehBlip)

        -- Préchargement de tous les modèles de peds en une seule passe
        local availableModels = {}
        for _, name in ipairs(PED_MODELS) do
            local h = LoadModel(name)
            if h then availableModels[#availableModels+1] = h end
        end

        if #availableModels == 0 then
            Notif("Erreur interne — Mission annulée.")
            SafeDel(veh); return
        end

        -- Mélange les offsets
        local offsets = {}
        for _, o in ipairs(GUARD_OFFSETS) do offsets[#offsets+1] = o end
        for i = #offsets, 2, -1 do
            local j = math.random(i)
            offsets[i], offsets[j] = offsets[j], offsets[i]
        end

        -- Groupe de relation : gardes alliés entre eux, ennemis des joueurs
        AddRelationshipGroup("Null_FOURGON_GUARDS")
        local guardGroup  = GetHashKey("Null_FOURGON_GUARDS")
        local playerGroup = GetHashKey("PLAYER")
        SetRelationshipBetweenGroups(0, guardGroup, guardGroup)   -- alliés
        SetRelationshipBetweenGroups(5, guardGroup, playerGroup)  -- haïssent joueurs
        SetRelationshipBetweenGroups(5, playerGroup, guardGroup)  -- joueurs haïssent gardes

        -- Spawn des gardes (6 à 8) — modèles déjà chargés, création instantanée
        local count   = math.random(6, 8)
        local allPeds = {}

        for i = 1, count do
            local off = offsets[i]
            local pos = WorldOffset(sp, hdg, off.ox, off.oy)
            local mh  = availableModels[math.random(#availableModels)]
            local ped = CreatePed(4, mh, pos.x, pos.y, pos.z, math.random(0, 360), true, false)
            SetEntityAsMissionEntity(ped, true, true)
            SetPedRelationshipGroupHash(ped, guardGroup)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedFleeAttributes(ped, 0, false)
            SetPedCombatAttributes(ped, 46, true)
            SetPedCombatAttributes(ped, 5, true)
            SetPedAccuracy(ped, 35)
            SetPedDropsWeaponsWhenDead(ped, false)
            GiveWeaponToPed(ped, WEAPON_PISTOL, 150, false, true)
            TaskGuardCurrentPosition(ped, 5.0, 10.0, true)
            allPeds[#allPeds+1] = ped
        end

        for _, h in ipairs(availableModels) do
            SetModelAsNoLongerNeeded(h)
        end

        -- Enregistre la santé initiale de chaque garde
        local pedHealth = {}
        for i, ped in ipairs(allPeds) do
            pedHealth[i] = GetEntityHealth(ped)
        end

        M = {
            gang      = data.gangName,
            route     = route,
            veh       = veh,
            peds      = allPeds,
            pedHealth = pedHealth,
            vehBlip   = vehBlip,
            dBlip     = nil,
            alert     = false,
            taken     = false,
            startTime = GetGameTimer(),
            takenTime = nil,
        }

        Notif("Fourgon localisé. Neutralisez les gardes et prenez le van.")
        Monitor()
        StartTimerHUD()
    end)
end

-- ─────────────────────────────────────────────
-- EVENTS
-- ─────────────────────────────────────────────

RegisterNetEvent('null:missions:fourgon:init')
AddEventHandler('null:missions:fourgon:init', function(data)
    SpawnMission(data)
end)
