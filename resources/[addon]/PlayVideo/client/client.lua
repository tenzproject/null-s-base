local smallPlayer = nil
local largePlayer = nil

-- Fonction pour extraire l'ID YouTube de l'URL
local function GetYoutubeID(url)
    if not url then return nil end
    local videoId = url:match("v=([%w-_]+)")
    if not videoId then
        videoId = url:match("youtu.be/([%w-_]+)")
    end
    return videoId
end

RegisterNetEvent('youtube:playVideo')
AddEventHandler('youtube:playVideo', function(url, mode)
    local videoId = GetYoutubeID(url)
    if mode ~= "stop" and not videoId then return end

    if mode == 'small' then
        if smallPlayer then
            SetNuiFocus(false, false)
            SendNUIMessage({
                type = "destroySmall"
            })
        end
        SendNUIMessage({
            type = "playSmall",
            videoId = videoId
        })
        smallPlayer = true

    elseif mode == 'large' then
        if largePlayer then
            SetNuiFocus(false, false)
            SendNUIMessage({
                type = "destroyLarge"
            })
        end
        SetNuiFocus(true, true)
        SendNUIMessage({
            type = "playLarge",
            videoId = videoId
        })
        largePlayer = true

    elseif mode == 'stop' then
        if smallPlayer or largePlayer then
            print("stop all")
            SetNuiFocus(false, false)
            SendNUIMessage({
                type = "destroyAll"
            })
            smallPlayer = nil
            largePlayer = nil
            TriggerEvent("chat:addMessage", {
                color = {0, 255, 0},
                args = {"Système", "Vidéo arrêtée avec succès"}
            })
        end
    end
end)