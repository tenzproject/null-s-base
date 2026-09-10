-- ProgressBar Module
-- Gère l'affichage de barres de progression pour les actions

local progressActive = false
local progressCallback = nil

-- Fonction pour afficher la barre de progression
function ShowProgressBar(time, text, callback)
    if progressActive then
        print("[ProgressBar] Une barre de progression est déjà active")
        return false
    end

    -- Convertir time en nombre si c'est une string
    time = tonumber(time) or 1000

    progressActive = true
    progressCallback = callback

    SendNUIMessage({
        action = 'showProgressBar',
        display = true,
        time = time,
        text = text,
        callback = callback and 'progressBarComplete' or nil
    })

    -- Timer pour désactiver automatiquement après le délai
    Citizen.SetTimeout(time, function()
        progressActive = false
        if progressCallback then
            local cb = progressCallback
            progressCallback = nil
            -- Le callback sera exécuté par le NUI
        end
    end)

    return true
end

-- Fonction pour masquer la barre de progression
function HideProgressBar()
    if not progressActive then
        return
    end

    progressActive = false
    progressCallback = nil

    SendNUIMessage({
        action = 'hideProgressBar'
    })
end

-- Callback NUI pour la complétion
RegisterNUICallback('progressBarComplete', function(data, cb)
    if progressCallback then
        local callback = progressCallback
        progressCallback = nil
        progressActive = false
        
        -- Exécuter le callback
        if type(callback) == 'function' then
            callback()
        elseif type(callback) == 'string' then
            TriggerEvent(callback)
        end
    end
    cb('ok')
end)

-- Event pour afficher la barre de progression
RegisterNetEvent('progressbar:start', function(time, text, callback)
    time = tonumber(time) or 1000
    null.DebugPrint(("Starting progress bar with time: %d, text: %s"):format(time, text or "nil"))
    ShowProgressBar(time, text, callback)
end)

-- Event pour masquer la barre de progression
RegisterNetEvent('progressbar:stop', function()
    HideProgressBar()
end)

-- Export pour utilisation dans d'autres scripts
exports('ShowProgressBar', ShowProgressBar)
exports('HideProgressBar', HideProgressBar)
exports('IsProgressActive', function() return progressActive end)

-- Alias pour compatibilité avec l'ancien système
exports('startProgressbar', ShowProgressBar)
