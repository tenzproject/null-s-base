-- Variables pour l'annonce UI
local displayAnnouncement = true

function ShowAnnouncement(message, announcementType, duration, subtitle)
    if not displayAnnouncement then return end

    if duration > 999 then
        duration = duration / 1000
    end

    -- Préparer les données
    local data = {
        type = 'SHOW_ANNOUNCEMENT',
        message = message,
        announcementType = announcementType or 'global', -- 'global', 'staff', 'warning'
        duration = duration or 5, -- Durée en secondes
        subtitle = subtitle
    }
    
    SendNUIMessage(data)
end

function HideAnnouncement()
    SendNUIMessage({
        type = 'HIDE_ANNOUNCEMENT'
    })
end

RegisterCommand('hideannounce', function(source, args)
    HideAnnouncement()
end, false)

-- Événements réseau ESX
RegisterNetEvent('esx:showAnnouncement')
AddEventHandler('esx:showAnnouncement', function(message, announcementType, duration, subtitle)
    ShowAnnouncement(message, announcementType, duration, subtitle)
end)

RegisterNetEvent('esx:hideAnnouncement')
AddEventHandler('esx:hideAnnouncement', function()
    HideAnnouncement()
end)


-- @TODO: Supprimer les commandes de test

-- -- Commandes de test
-- RegisterCommand('testannounce', function(source, args)
--     ShowAnnouncement(
--         "Ceci est une annonce globale de test. Le serveur redémarrera dans 10 minutes.",
--         'global',
--         8
--     )
-- end, false)

-- RegisterCommand('testannouncestaff', function(source, args)
--     ShowAnnouncement(
--         "Un nouveau rapport a été créé. Veuillez vérifier le menu administration.",
--         'staff',
--         6,
--         "Notification Staff"
--     )
-- end, false)

-- RegisterCommand('testannouncewarning', function(source, args)
--     ShowAnnouncement(
--         "Vous avez reçu un avertissement pour non-respect des règles du serveur. Prochain avertissement = sanction.",
--         'warning',
--         10,
--         "Avertissement Officiel"
--     )
-- end, false)
