-- ============================================================================
-- Null Doorlock — Client
-- Enregistre les portes dans le door system GTA, applique les états réseau,
-- affiche le prompt UI (cadenas) et gère l'interaction (touche E).
-- ============================================================================

local Doors = {}          -- [id] = clientDoorData
local doorByHash = {}     -- [doorHash] = id (lookup rapide)
local nearestDoorId = nil -- porte actuellement affichée
local promptVisible = false
local codePadOpen = false -- pad de code ouvert (bloque l'interaction E/G)

local doorPromptLastPayload = nil

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function notify(msg)
    exports['null-core']:SendNotification(msg)
end

local function hideDoorPrompt()
    SendNUIMessage({ type = 'doorPrompt:hide' })
    promptVisible = false
    doorPromptLastPayload = nil
end

local function updateDoorPrompt(payload, center)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(center.x, center.y, center.z + 0.35)
    if not onScreen then
        hideDoorPrompt()
        return
    end

    payload.type = 'doorPrompt:update'
    payload.screenX = math.floor(screenX * 1920)
    payload.screenY = math.floor(screenY * 1080)

    local encoded = json.encode(payload)
    if encoded ~= doorPromptLastPayload then
        doorPromptLastPayload = encoded
        SendNUIMessage(payload)
    end

    promptVisible = true
end

-- Hash unique et stable d'une porte physique (model + position arrondie).
local function makeDoorHash(d)
    return GetHashKey(('%s_%.1f_%.1f_%.1f'):format(d.model, d.x, d.y, d.z))
end

local function playDoorSound(coords, locked)
    if not DoorlockConfig.Sounds.enabled then return end
    local url = locked and DoorlockConfig.Sounds.lock or DoorlockConfig.Sounds.unlock
    if not url then return end
    local soundId = ('doorlock_%d'):format(math.random(1, 100000))
    pcall(function()
        exports['null-deps']:PlayUrlPos(soundId, url, DoorlockConfig.Sounds.volume, coords, false)
        exports['null-deps']:Distance(soundId, DoorlockConfig.Sounds.maxDistance)
        exports['null-deps']:setVolumeMax(soundId, DoorlockConfig.Sounds.volume)
    end)
end

-- ---------------------------------------------------------------------------
-- Enregistrement dans le door system GTA
-- ---------------------------------------------------------------------------

-- d.model peut être un hash (number, depuis GetEntityModel) ou un nom (string).
local function resolveModelHash(model)
    if type(model) == 'number' then return model end
    return GetHashKey(model)
end

local function shortestHeadingDelta(from, to)
    return ((to - from + 540.0) % 360.0) - 180.0
end

local function closeDoorEntitySmooth(entity, targetHeading, instant, cb)
    local startHeading = GetEntityHeading(entity)
    local delta = shortestHeadingDelta(startHeading, targetHeading)

    if instant then
        SetEntityHeading(entity, targetHeading + 0.0)
        if cb then cb() end
        return
    end

    local duration = 650
    local startTime = GetGameTimer()

    CreateThread(function()
        while DoesEntityExist(entity) do
            local elapsed = GetGameTimer() - startTime
            local t = math.min(elapsed / duration, 1.0)
            local eased = 1.0 - ((1.0 - t) * (1.0 - t))

            SetEntityHeading(entity, (startHeading + delta * eased) % 360.0)

            if t >= 1.0 then
                SetEntityHeading(entity, targetHeading + 0.0)
                if cb then cb() end
                break
            end

            Wait(0)
        end
    end)
end

local function applyDoorState(door, locked, instant)
    for _, d in ipairs(door.doors) do
        local hash = d._hash
        local modelHash = resolveModelHash(d.model)

        if hash then
            if not IsDoorRegisteredWithSystem(hash) then
                AddDoorToSystem(hash, modelHash, d.x + 0.0, d.y + 0.0, d.z + 0.0, false, false, false)
            end
            DoorSystemSetAutomaticRate(hash, 1.8, false, true)
            DoorSystemSetHoldOpen(hash, false)
        end

        local entity = GetClosestObjectOfType(d.x + 0.0, d.y + 0.0, d.z + 0.0, 1.0, modelHash, false, false, false)
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            FreezeEntityPosition(entity, false)

            if locked then
                if hash then
                    DoorSystemSetDoorState(hash, 0, false, true)
                end

                if d.heading then
                    closeDoorEntitySmooth(entity, d.heading, instant == true, function()
                        if hash then
                            DoorSystemSetDoorState(hash, 1, false, true)
                            DoorSystemSetOpenRatio(hash, 0.0, false, true)
                        end
                        if DoesEntityExist(entity) then
                            FreezeEntityPosition(entity, true)
                        end
                    end)
                else
                    if hash then
                        DoorSystemSetDoorState(hash, 1, false, true)
                    end
                    FreezeEntityPosition(entity, true)
                end
            else
                if hash then
                    DoorSystemSetDoorState(hash, 0, false, true)
                end
            end
        elseif hash then
            DoorSystemSetDoorState(hash, locked and 1 or 0, false, true)
            if locked then
                DoorSystemSetOpenRatio(hash, 0.0, false, true)
            end
        end
    end
end

local function registerDoor(door)
    -- Pré-calcule les hashes physiques.
    for _, d in ipairs(door.doors) do
        d._hash = makeDoorHash(d)
        doorByHash[d._hash] = door.id
    end
    Doors[door.id] = door
    applyDoorState(door, door.locked, true)
end

local function unregisterDoor(id)
    local door = Doors[id]
    if not door then return end
    for _, d in ipairs(door.doors) do
        if d._hash then
            if IsDoorRegisteredWithSystem(d._hash) then
                DoorSystemSetDoorState(d._hash, 0, false, false) -- déverrouille avant retrait
                RemoveDoorFromSystem(d._hash)
            end
            doorByHash[d._hash] = nil
        end
    end
    Doors[id] = nil
    if nearestDoorId == id then
        nearestDoorId = nil
        hideDoorPrompt()
    end
end

-- ---------------------------------------------------------------------------
-- Sync réseau
-- ---------------------------------------------------------------------------

RegisterNetEvent('Null_doorlock:syncAll', function(payload)
    -- Retire les anciennes.
    for id in pairs(Doors) do unregisterDoor(id) end
    Doors, doorByHash = {}, {}
    for id, door in pairs(payload) do
        registerDoor(door)
    end
end)

RegisterNetEvent('Null_doorlock:addOne', function(door)
    if Doors[door.id] then unregisterDoor(door.id) end
    registerDoor(door)
end)

RegisterNetEvent('Null_doorlock:removeOne', function(id)
    unregisterDoor(id)
end)

RegisterNetEvent('Null_doorlock:setState', function(id, locked, silent)
    local door = Doors[id]
    if not door then return end
    door.locked = locked
    applyDoorState(door, locked)
    if not silent then
        local center = door.doors[1]
        if center then
            playDoorSound(vector3(center.x, center.y, center.z), locked)
        end
    end
    -- Met à jour le prompt si c'est la porte affichée.
    if nearestDoorId == id and promptVisible then
        doorPromptLastPayload = nil
    end
end)

-- Le serveur a fini de charger : on demande la sync (utile aux resmon/restart).
AddEventHandler('null:player:spawned', function()
    TriggerServerEvent('Null_doorlock:requestSync')
end)
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('Null_doorlock:requestSync')
end)

-- ---------------------------------------------------------------------------
-- Détection de la porte la plus proche + prompt UI
-- ---------------------------------------------------------------------------

-- Renvoie la porte (et son point central) la plus proche dans DrawDistance.
local function findNearestDoor(pcoords)
    local bestId, bestDist, bestCenter = nil, DoorlockConfig.DrawDistance, nil
    for id, door in pairs(Doors) do
        -- Centre = moyenne des portes physiques (gère les double-portes).
        local cx, cy, cz, n = 0.0, 0.0, 0.0, 0
        for _, d in ipairs(door.doors) do
            cx, cy, cz, n = cx + d.x, cy + d.y, cz + d.z, n + 1
        end
        if n > 0 then
            local center = vector3(cx / n, cy / n, cz / n)
            local dist = #(pcoords - center)
            if dist < bestDist then
                bestId, bestDist, bestCenter = id, dist, center
            end
        end
    end
    return bestId, bestCenter, bestDist
end

CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)
        local id, center, dist = findNearestDoor(pcoords)

        if id and center then
            sleep = 0
            local door = Doors[id]
            if nearestDoorId ~= id then
                nearestDoorId = id
                doorPromptLastPayload = nil
            end

            updateDoorPrompt({
                id          = id,
                distance    = dist,
                locked      = door.locked,
                label       = door.label,
                interactKey = DoorlockConfig.InteractKey,
                canInteract = dist <= DoorlockConfig.InteractDistance,
                hasCode     = door.hasCode == true,
                show        = true,
            }, center)

            if dist <= DoorlockConfig.InteractDistance and not codePadOpen then
                -- Touche E : (dé)verrouillage par permission.
                if IsControlJustReleased(0, ConfigAllKeys[DoorlockConfig.InteractKey] or 51) then
                    TriggerServerEvent('Null_doorlock:toggle', id, false)
                end
                -- Touche G : pad de code (si la porte a un code).
                if door.hasCode and IsControlJustReleased(0, ConfigAllKeys["G"] or 47) then
                    openCodePad(id, door.label)
                end
            end
        else
            if promptVisible then
                hideDoorPrompt()
                nearestDoorId = nil
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        hideDoorPrompt()
    end
end)

-- ---------------------------------------------------------------------------
-- Pad de code (déverrouillage par code)
-- ---------------------------------------------------------------------------

function openCodePad(doorId, label)
    codePadOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ type = 'doorCode:open', id = doorId, label = label })
end

local function closeCodePad()
    codePadOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'doorCode:close' })
end

RegisterNUICallback('doorlock:submitCode', function(data, cb)
    if data and data.id and data.code then
        TriggerServerEvent('Null_doorlock:tryCode', data.id, tostring(data.code))
    end
    closeCodePad()
    cb({ ok = true })
end)

RegisterNUICallback('doorlock:closeCode', function(_, cb)
    closeCodePad()
    cb({ ok = true })
end)

-- Expose un lookup pour le module lockpick (porte visée).
exports('GetDoorByHash', function(hash) return doorByHash[hash] and Doors[doorByHash[hash]] or nil end)
exports('GetNearestDoorId', function() return nearestDoorId end)
exports('GetClientDoors', function() return Doors end)
