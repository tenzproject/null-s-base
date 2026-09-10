-- ============================================================================
-- Null Doorlock — Crochetage (lockpick)
-- Mini-jeu ox_lib skillCheck pour forcer une porte verrouillée.
-- Déclenché sur la porte visée la plus proche via la commande/keybind +lockpick.
-- ============================================================================

local lastAttempt = 0

local function notify(msg)
    exports['null-core']:SendNotification(msg)
end

local function hasLockpickItem()
    if not DoorlockConfig.LockpickItem then return true end
    -- ESX.PlayerData.inventory contient les items côté client.
    if ESX and ESX.PlayerData and ESX.PlayerData.inventory then
        for _, item in ipairs(ESX.PlayerData.inventory) do
            if item.name == DoorlockConfig.LockpickItem and (item.count or 0) > 0 then
                return true
            end
        end
        return false
    end
    return true -- fallback : laisse le serveur trancher
end

local function attemptLockpick()
    if not DoorlockConfig.Lockpick.enabled then return end

    local now = GetGameTimer()
    if now - lastAttempt < DoorlockConfig.Lockpick.cooldown then
        notify("Vous devez attendre avant de réessayer.")
        return
    end

    local id = exports['null-core']:GetNearestDoorId()
    if not id then return end

    local doors = exports['null-core']:GetClientDoors()
    local door = doors and doors[id]
    if not door then return end

    if not door.locked then
        notify("Cette porte est déjà déverrouillée.")
        return
    end
    if not door.lockpick then
        notify("Cette serrure ne peut pas être crochetée.")
        return
    end
    if not hasLockpickItem() then
        notify("Vous n'avez pas de crochet.")
        return
    end

    lastAttempt = now

    -- Mini-jeu ox_lib (lib est dispo via @null-deps/modules/ox_lib/init.lua).
    local success = lib.skillCheck(DoorlockConfig.Lockpick.difficulty, DoorlockConfig.Lockpick.inputs)

    -- Informe le serveur (consomme l'item si échec, anti-cheat).
    TriggerServerEvent('Null_doorlock:lockpickResult', id, success)

    if success then
        notify("Serrure crochetée.")
        -- Déverrouille via le serveur (flag viaLockpick = bypass permission).
        TriggerServerEvent('Null_doorlock:toggle', id, true)
    else
        notify("Échec du crochetage.")
    end
end

-- Commande + keybind par défaut (touche par défaut : aucune, l'utilisateur la lie).
RegisterCommand('+Null_lockpick', attemptLockpick, false)
RegisterCommand('-Null_lockpick', function() end, false)
RegisterKeyMapping('+Null_lockpick', 'Crocheter la porte ciblée', 'keyboard', '')

-- Commande texte alternative.
RegisterCommand('lockpick', attemptLockpick, false)

-- Export pour déclencher depuis l'inventaire (usage item lockpick).
exports('UseLockpick', attemptLockpick)
