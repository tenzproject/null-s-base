-- ESX Server-side Announcement Functions

-- Envoyer une annonce à un joueur spécifique
function ESX.ShowAnnouncement(playerId, message, announcementType, duration, subtitle)
    TriggerClientEvent('esx:showAnnouncement', playerId, message, announcementType, duration, subtitle)
end 

-- Envoyer une annonce à tous les joueurs
function ESX.ShowAnnouncementToAll(message, duration, subtitle)
    TriggerClientEvent('esx:showAnnouncement', -1, message, 'global', duration, subtitle)
end

-- Envoyer une annonce à tous les staffs
function ESX.ShowAnnouncementToStaff(message, duration, subtitle)
    local xPlayers = ESX.Players
    for _, xPlayer in pairs(xPlayers) do
        if xPlayer.getGroup() ~= 'user' then
            TriggerClientEvent('esx:showAnnouncement', xPlayer.source, message, 'staff', duration, subtitle)
        end
    end
end

-- Envoyer un avertissement à un joueur
function ESX.ShowWarningToPlayer(playerId, message, duration, subtitle)
    TriggerClientEvent('esx:showAnnouncement', playerId, message, 'warning', duration, subtitle)
end

-- Masquer l'annonce pour un joueur
function ESX.HideAnnouncement(playerId)
    TriggerClientEvent('esx:hideAnnouncement', playerId)
end

-- Exports pour d'autres ressources
exports('ShowAnnouncement', ESX.ShowAnnouncement)
exports('ShowAnnouncementToAll', ESX.ShowAnnouncementToAll)
exports('ShowAnnouncementToStaff', ESX.ShowAnnouncementToStaff)
exports('ShowWarningToPlayer', ESX.ShowWarningToPlayer)
exports('HideAnnouncement', ESX.HideAnnouncement)

-- Événements réseau
RegisterNetEvent('esx:showAnnouncement')
AddEventHandler('esx:showAnnouncement', function(message, announcementType, duration, subtitle)
    -- Cet événement est déclenché côté client
end)

RegisterNetEvent('esx:hideAnnouncement')
AddEventHandler('esx:hideAnnouncement', function()
    -- Cet événement est déclenché côté client
end)