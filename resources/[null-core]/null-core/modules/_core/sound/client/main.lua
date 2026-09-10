local soundInfo = {}

local AllMusicPlaying = {}

local defaultInfo = {
    volume = 1.0,
    url = "",
    id = "",
    position = nil,
    distance = 0,
    playing = false,
    paused = false,
    loop = false,
}

function PlayUrl(name, url, volume, loop)
    AllMusicPlaying[name] = {
        name = name,
        url = url,
        loop = loop,
        volume = volume,
    }
    
    SendNUIMessage({
        status = "url",
        name = name,
        url = url,
        x = 0,
        y = 0,
        z = 0,
        dynamic = false,
        volume = volume,
        loop = loop or false,
    })

    if soundInfo[name] == nil then 
        soundInfo[name] = {}
        for k, v in pairs(defaultInfo) do
            soundInfo[name][k] = v
        end
    end

    soundInfo[name].volume = volume
    soundInfo[name].url = url
    soundInfo[name].id = name
    soundInfo[name].playing = true
    soundInfo[name].paused = false
    soundInfo[name].loop = loop or false
end

function PlayUrlPos(name, url, volume, pos, loop)
    AllMusicPlaying[name] = {
        name = name,
        url = url,
        loop = loop,
        volume = volume,
    }
    
    SendNUIMessage({
        status = "url",
        name = name,
        url = url,
        x = pos.x,
        y = pos.y,
        z = pos.z,
        dynamic = true,
        volume = volume,
        loop = loop or false,
    })
    
    if soundInfo[name] == nil then 
        soundInfo[name] = {}
        for k, v in pairs(defaultInfo) do
            soundInfo[name][k] = v
        end
    end

    soundInfo[name].volume = volume
    soundInfo[name].url = url
    soundInfo[name].position = pos
    soundInfo[name].id = name
    soundInfo[name].playing = true
    soundInfo[name].paused = false
    soundInfo[name].loop = loop or false
end

function Distance(name, distance)
    SendNUIMessage({
        status = "distance",
        name = name,
        distance = distance,
    })
    
    if soundInfo[name] then
        soundInfo[name].distance = distance
    end
end

function Position(name, pos)
    SendNUIMessage({
        status = "soundPosition",
        name = name,
        x = pos.x,
        y = pos.y,
        z = pos.z,
    })
    
    if soundInfo[name] then
        soundInfo[name].position = pos
        soundInfo[name].id = name
    end
end

function Destroy(name)
    SendNUIMessage({
        status = "delete",
        name = name
    })
    
    soundInfo[name] = nil
    AllMusicPlaying[name] = nil
end

function Resume(name)
    SendNUIMessage({
        status = "resume",
        name = name
    })
    
    if soundInfo[name] then
        soundInfo[name].playing = true
        soundInfo[name].paused = false
    end
end

function Pause(name)
    SendNUIMessage({
        status = "pause",
        name = name
    })
    
    if soundInfo[name] then
        soundInfo[name].playing = false
        soundInfo[name].paused = true
    end
end

function setVolume(name, vol)
    SendNUIMessage({
        status = "volume",
        volume = vol,
        name = name,
    })
    
    if soundInfo[name] then
        soundInfo[name].volume = vol
    end
end

function setVolumeMax(name, vol)
    SendNUIMessage({
        status = "max_volume",
        volume = vol,
        name = name,
    })
    
    if soundInfo[name] then
        soundInfo[name].maxVolume = vol
    end
end

function whileToDestroy(name, time)
    CreateThread(function()
        if not AllMusicPlaying[name] then return end
        
        local tempVolume = AllMusicPlaying[name].volume or 1.0
        
        while tempVolume > 0 do
            tempVolume = tempVolume - 0.01
            if tempVolume < 0 then tempVolume = 0 end
            setVolume(name, tempVolume)
            Wait(time)
        end
        
        Destroy(name)
    end)
end

function fadeIn(name, targetVolume, time)
    CreateThread(function()
        if not soundInfo[name] then return end
        
        local currentVolume = 0
        setVolume(name, 0)
        
        while currentVolume < targetVolume do
            currentVolume = currentVolume + 0.01
            if currentVolume > targetVolume then currentVolume = targetVolume end
            setVolume(name, currentVolume)
            Wait(time)
        end
    end)
end

function getLink(name)
    if soundInfo[name] then
        return soundInfo[name].url
    end
    return nil
end

function getPosition(name)
    if soundInfo[name] then
        return soundInfo[name].position
    end
    return nil
end

function isLooped(name)
    if soundInfo[name] then
        return soundInfo[name].loop
    end
    return false
end

function getInfo(name)
    return soundInfo[name]
end

function soundExists(name)
    return soundInfo[name] ~= nil
end

function isPlaying(name)
    if soundInfo[name] == nil then return false end
    return soundInfo[name].playing
end

function isPaused(name)
    if soundInfo[name] == nil then return false end
    return soundInfo[name].paused
end

function getDistance(name)
    if soundInfo[name] then
        return soundInfo[name].distance
    end
    return 0
end

function getVolume(name)
    if soundInfo[name] then
        return soundInfo[name].volume
    end
    return 0
end

function getAllSounds()
    return soundInfo
end

RegisterNUICallback("data_status", function(data, cb)
    if data.type == "finished" then
        if soundInfo[data.id] then
            soundInfo[data.id].playing = false
        end
        TriggerEvent("xSound:songStopPlaying", data.id)
        TriggerEvent("null:sound:finished", data.id)
    end
    cb('ok')
end)

RegisterNUICallback("sound_finished", function(data, cb)
    if data.name and soundInfo[data.name] then
        soundInfo[data.name].playing = false
        TriggerEvent("xSound:songStopPlaying", data.name)
        TriggerEvent("null:sound:finished", data.name)
    end
    cb('ok')
end)

CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        local coords = GetEntityCoords(PlayerPedId())
        SendNUIMessage({
            status = "position",
            x = coords.x,
            y = coords.y,
            z = coords.z
        })
        Wait(250)
    end
end))

exports('PlayUrl', PlayUrl)
exports('PlayUrlPos', PlayUrlPos)

exports('Distance', Distance)
exports('Position', Position)
exports('Destroy', Destroy)
exports('Resume', Resume)
exports('Pause', Pause)
exports('setVolume', setVolume)
exports('setVolumeMax', setVolumeMax)
exports('whileToDestroy', whileToDestroy)
exports('fadeIn', fadeIn)

exports('getLink', getLink)
exports('getPosition', getPosition)
exports('isLooped', isLooped)
exports('getInfo', getInfo)
exports('soundExists', soundExists)
exports('isPlaying', isPlaying)
exports('isPaused', isPaused)
exports('getDistance', getDistance)
exports('getVolume', getVolume)
exports('getAllSounds', getAllSounds)

null.InitPrint('^2Sound module loaded^7')
