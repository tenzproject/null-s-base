RegisterNetEvent("null:setNewWayPoint", function(coords)
    ESX.ShowNotification("Un point a était poser sur votre carte.")
    SetNewWaypoint(null.fct.JsonCoordsToVect3(coords))
end)

-- @TODO: move to announcements file
RegisterNetEvent("null:annonce", function(text, Subtitle, time, sound)
    time = time or 1000
    Subtitle = Subtitle or ""
    null.fct.draw.CenteredAnnouncement(text, Subtitle, time)
    if sound ~= nil then
        PlaySoundFrontend(-1, sound[1], sound[2], true)
    end
end)