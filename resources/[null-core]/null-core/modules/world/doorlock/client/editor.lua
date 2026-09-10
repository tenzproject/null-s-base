-- ============================================================================
-- Null Doorlock — Éditeur in-game (/doorlock)
-- Ouvre un menu de gestion (React) : liste des portes, création avec sélection
-- visuelle façon ox_doorlock, édition (job/job2/rank admin/code), suppression.
-- ============================================================================

local managerOpen = false
local selectionMode = false
local selectedDoors = {}   -- portes physiques en cours de sélection

local function notify(msg)
    exports['null-core']:SendNotification(msg)
end

-- ---------------------------------------------------------------------------
-- Raycast : objet (porte) visé par la caméra.
-- ---------------------------------------------------------------------------

local function rotationToDirection(rotation)
    local ax = (math.pi / 180) * rotation.x
    local az = (math.pi / 180) * rotation.z
    return {
        x = -math.sin(az) * math.abs(math.cos(ax)),
        y =  math.cos(az) * math.abs(math.cos(ax)),
        z =  math.sin(ax),
    }
end

local function raycastDoorEntity()
    local camRot   = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()
    local dir      = rotationToDirection(camRot)
    local dist     = 7.0
    local dest = vector3(camCoord.x + dir.x * dist, camCoord.y + dir.y * dist, camCoord.z + dir.z * dist)
    local ray = StartShapeTestRay(camCoord.x, camCoord.y, camCoord.z, dest.x, dest.y, dest.z, 16, PlayerPedId(), 0)
    local _, hit, _, _, entity = GetShapeTestResult(ray)
    if hit == 1 and entity and entity > 0 and IsEntityAnObject(entity) then
        return entity
    end
    return nil
end

local function buildDoorDef(entity)
    local model   = GetEntityModel(entity)
    local coords  = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    return {
        model   = model,
        x       = math.floor(coords.x * 100) / 100,
        y       = math.floor(coords.y * 100) / 100,
        z       = math.floor(coords.z * 100) / 100,
        heading = math.floor(heading * 100) / 100,
        modelName = ('%s'):format(model), -- pour affichage dans l'UI
    }
end

-- Deux portes physiques sont "les mêmes" si même model + position arrondie.
local function sameDoorDef(a, b)
    return a.model == b.model
        and math.abs(a.x - b.x) < 0.05
        and math.abs(a.y - b.y) < 0.05
        and math.abs(a.z - b.z) < 0.05
end

local function indexOfDoor(list, def)
    for i, d in ipairs(list) do
        if sameDoorDef(d, def) then return i end
    end
    return nil
end

-- ---------------------------------------------------------------------------
-- Menu (React)
-- ---------------------------------------------------------------------------

local function pushSelectionUpdate(hoveredDef)
    local doorsOut = {}
    for i, d in ipairs(selectedDoors) do
        doorsOut[i] = { model = d.model, x = d.x, y = d.y, z = d.z }
    end
    SendNUIMessage({
        type    = 'doorlock:selectionUpdate',
        count   = #selectedDoors,
        doors   = doorsOut,
        hovered = hoveredDef and { model = hoveredDef.model, x = hoveredDef.x, y = hoveredDef.y, z = hoveredDef.z } or nil,
    })
end

local function openManager()
    if managerOpen then return end
    ESX.TriggerServerCallback('Null_doorlock:getEditorList', function(list)
        if not list then
            notify('~r~[Doorlock] Accès refusé.')
            return
        end
        managerOpen = true
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        SendNUIMessage({
            type  = 'doorlock:open',
            doors = list,
            editorGroups = nil,
        })
    end)
end

local function closeManager()
    managerOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'doorlock:close' })
end

-- ---------------------------------------------------------------------------
-- Mode sélection visuelle (façon ox_doorlock)
-- Le menu se ferme (focus off), le joueur vise les portes et les ajoute,
-- puis ENTRÉE renvoie au menu avec la sélection.
-- ---------------------------------------------------------------------------

local function startSelection(preDoors)
    selectionMode = true
    selectedDoors = {}
    if preDoors then
        for _, d in ipairs(preDoors) do selectedDoors[#selectedDoors + 1] = d end
    end

    -- On garde le NUI affiché (bandeau) mais on rend le contrôle au joueur.
    SetNuiFocus(false, false)
    SendNUIMessage({ type = 'doorlock:selectionStart' })
    notify('~b~[Doorlock]~s~ Visez une porte → ~b~E~s~ ajouter/retirer · ~b~ENTRÉE~s~ valider · ~b~ÉCHAP~s~ annuler')

    CreateThread(function()
        local outlined = nil
        local function clearOutline()
            if outlined and DoesEntityExist(outlined) then SetEntityDrawOutline(outlined, false) end
            outlined = nil
        end

        while selectionMode do
            local entity = raycastDoorEntity()
            local hoveredDef = nil

            if entity ~= outlined then
                clearOutline()
                if entity then
                    SetEntityDrawOutline(entity, true)
                    SetEntityDrawOutlineColor(74, 144, 226, 255)
                    outlined = entity
                end
            end

            if entity then
                hoveredDef = buildDoorDef(entity)
                -- Couleur verte si déjà sélectionnée.
                if indexOfDoor(selectedDoors, hoveredDef) then
                    SetEntityDrawOutlineColor(74, 200, 130, 255)
                else
                    SetEntityDrawOutlineColor(74, 144, 226, 255)
                end

                if IsControlJustReleased(0, 51) then -- E : toggle
                    local idx = indexOfDoor(selectedDoors, hoveredDef)
                    if idx then
                        table.remove(selectedDoors, idx)
                        notify(('~o~[Doorlock]~s~ Porte retirée (%d sélectionnée(s)).'):format(#selectedDoors))
                    else
                        selectedDoors[#selectedDoors + 1] = hoveredDef
                        notify(('~g~[Doorlock]~s~ Porte ajoutée (%d sélectionnée(s)).'):format(#selectedDoors))
                    end
                    Wait(250)
                end
            end

            pushSelectionUpdate(hoveredDef)

            if IsControlJustReleased(0, 191) then -- ENTRÉE : valider
                if #selectedDoors > 0 then
                    selectionMode = false
                else
                    notify('~r~[Doorlock] Sélectionnez au moins une porte.')
                end
            elseif IsControlJustReleased(0, 322) then -- ÉCHAP : annuler
                selectionMode = false
                selectedDoors = {}
            end

            Wait(0)
        end

        clearOutline()

        -- Retour au menu avec la sélection (ou annulation).
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(false)
        local doorsOut = {}
        for i, d in ipairs(selectedDoors) do
            doorsOut[i] = { model = d.model, x = d.x, y = d.y, z = d.z, heading = d.heading }
        end
        SendNUIMessage({
            type  = 'doorlock:selectionDone',
            doors = doorsOut,
        })
    end)
end

-- ---------------------------------------------------------------------------
-- NUI Callbacks
-- ---------------------------------------------------------------------------

RegisterNUICallback('doorlock:close', function(_, cb)
    closeManager()
    cb({ ok = true })
end)

RegisterNUICallback('doorlock:startSelection', function(data, cb)
    -- L'UI passe les portes déjà sélectionnées (édition d'une porte existante).
    cb({ ok = true })
    startSelection(data and data.doors or nil)
end)

RegisterNUICallback('doorlock:create', function(data, cb)
    ESX.TriggerServerCallback('Null_doorlock:create', function(ok, res)
        if ok then
            notify(('~g~[Doorlock] Porte #%s créée.'):format(res))
        else
            notify('~r~[Doorlock] ' .. (res or 'Erreur'))
        end
        cb({ ok = ok, result = res })
    end, data)
end)

RegisterNUICallback('doorlock:update', function(data, cb)
    ESX.TriggerServerCallback('Null_doorlock:update', function(ok, err)
        notify(ok and '~g~[Doorlock] Porte mise à jour.' or ('~r~[Doorlock] ' .. (err or 'Erreur')))
        cb({ ok = ok })
    end, data.id, data)
end)

RegisterNUICallback('doorlock:delete', function(data, cb)
    ESX.TriggerServerCallback('Null_doorlock:delete', function(ok, err)
        notify(ok and '~g~[Doorlock] Porte supprimée.' or ('~r~[Doorlock] ' .. (err or 'Erreur')))
        cb({ ok = ok })
    end, data.id)
end)

-- Téléportation vers une porte (pratique depuis le menu).
RegisterNUICallback('doorlock:teleport', function(data, cb)
    if data and data.x then
        SetEntityCoords(PlayerPedId(), data.x + 0.0, data.y + 0.0, data.z + 1.0, false, false, false, true)
    end
    closeManager()
    cb({ ok = true })
end)

-- ---------------------------------------------------------------------------
-- Commandes
-- ---------------------------------------------------------------------------

RegisterCommand('doorlock', function()
    openManager()
end, false)
