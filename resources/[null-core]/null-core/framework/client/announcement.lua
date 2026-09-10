-- ESX Client-side Announcement Functions

function ESX.ShowAnnouncement(message, announcementType, duration, subtitle)
    ShowAnnouncement(message, announcementType, duration, subtitle)
end

function ESX.HideAnnouncement()
    HideAnnouncement()
end

-- Exports pour d'autres ressources
exports('ShowAnnouncement', ESX.ShowAnnouncement)
exports('HideAnnouncement', ESX.HideAnnouncement)
 