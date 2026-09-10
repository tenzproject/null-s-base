CurrentWeather = 'EXTRASUNNY'
NextWeather = 'EXTRASUNNY'
local lastWeather = CurrentWeather
local baseTime = 0
local timeOffset = 0
local timer = 0
freezeTime = false
freezeWeather = false
local saveBlackOut = false
newWeatherTimer = 0
inBlackout = false
blackoutAnim = true
local noel = false

localTime = {
    hours = 0,
    minutes = 0,
    changed = false,
}

LabelWeather = {
    ['EXTRASUNNY'] = "Ensoleillé",
    ['CLEAR'] = "Dégagé",
    ['NEUTRAL'] = "Neutre",
    ['SMOG'] = "Brumeux",
    ['FOGGY'] = "Brume",
    ['OVERCAST'] = "Nuageux",
    ['CLOUDS'] = "Nuages",
    ['CLEARING'] = "Dégagement",
    ['RAIN'] = "Pluie",
    ['THUNDER'] = "Orage",
    ['SNOW'] = "Neige",
    ['BLIZZARD'] = "Tempête de neige",
    ['SNOWLIGHT'] = "Neige légère",
    ['XMAS'] = "Noël",
    ['HALLOWEEN'] = "Halloween"
}


RegisterNetEvent('vSync:updateWeather')
AddEventHandler('vSync:updateWeather', function(NewWeather, newfreezeWeather, newNextWeather, WeatherTimer)
    CurrentWeather = NewWeather
    freezeWeather = newfreezeWeather
    NextWeather = newNextWeather
    newWeatherTimer = WeatherTimer
end)

local EnableTimeWhile = true

exports("stopTimeWhile", function(bool)
    EnableTimeWhile = not bool
end)

-- Thread séparé pour l'heure (besoin de précision)
CreateThread(LPH_NO_VIRTUALIZE(function()
    local animatedHour = localTime.hours
    local animatedMinute = localTime.minutes

    while true do
        if not EnableTimeWhile then
            Wait(1000)
        elseif localTime.changed then
            -- Animation de transition d'heure
            local targetHour = localTime.hours
            local targetMinute = localTime.minutes
            local currentTotal = animatedHour * 60 + animatedMinute
            local targetTotal = targetHour * 60 + targetMinute

            if currentTotal ~= targetTotal then
                local diff = targetTotal - currentTotal
                local step = math.min(15, math.max(1, math.ceil(math.abs(diff) / 60)))
                
                currentTotal = currentTotal + (diff > 0 and step or -step)
                currentTotal = diff > 0 
                    and math.min(currentTotal, targetTotal) 
                    or math.max(currentTotal, targetTotal)

                animatedHour = math.floor(currentTotal / 60) % 24
                animatedMinute = currentTotal % 60
                
                if animatedHour == targetHour and animatedMinute == targetMinute then
                    localTime.changed = false
                end
            else
                localTime.changed = false
            end
            
            NetworkOverrideClockTime(animatedHour, animatedMinute, 0)
            Wait(50)
        else
            -- Sync direct si pas d'animation
            if animatedHour ~= localTime.hours or animatedMinute ~= localTime.minutes then
                animatedHour = localTime.hours
                animatedMinute = localTime.minutes
            end
            NetworkOverrideClockTime(animatedHour, animatedMinute, 0)
            Wait(1000)
        end
    end
end))

-- Thread séparé pour la météo (moins fréquent)
CreateThread(LPH_NO_VIRTUALIZE(function()
    local lastAppliedWeather = nil
    local lastXmasState = false
    
    while true do
        if EnableTimeWhile then
            -- Changement de météo
            if lastWeather ~= CurrentWeather then
                lastWeather = CurrentWeather
                SetWeatherTypeOverTime(CurrentWeather, 15.0)
                Wait(15000)
            end
            
            -- Blackout
            if inBlackout ~= saveBlackOut then
                if blackoutAnim then
                    BlackoutFunction(inBlackout)
                else
                    SetBlackout(inBlackout)
                end
                saveBlackOut = inBlackout
            end
            
            -- Appliquer météo seulement si changée
            if lastAppliedWeather ~= lastWeather then
                ClearOverrideWeather()
                ClearWeatherTypePersist()
                SetWeatherTypePersist(lastWeather)
                SetWeatherTypeNow(lastWeather)
                SetWeatherTypeNowPersist(lastWeather)
                lastAppliedWeather = lastWeather
                
                -- XMAS trails
                local isXmas = lastWeather == 'XMAS'
                if lastXmasState ~= isXmas then
                    SetForceVehicleTrails(isXmas)
                    SetForcePedFootstepsTracks(isXmas)
                    lastXmasState = isXmas
                end
            end
        end
        
        Wait(2000)
    end
end))

local inBoFunction = false
function BlackoutFunction(value)
    if inBoFunction then return end
    inBoFunction = true

    Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
        --if value then
            local lastValue = true
            local indextime = 0
            while true do 
                if indextime > 16 then break end
                indextime = indextime + 1
                SetBlackout(lastValue)
                lastValue = not lastValue
                Wait(math.random(5,100))
            end
            SetBlackout(value)
        --else
        --    SetBlackout(value)
       -- end
    end))

    inBoFunction = false
end

RegisterNetEvent('vSync:updateWeatherTimer')
AddEventHandler('vSync:updateWeatherTimer', function(timer)
    newWeatherTimer = timer
end)

RegisterNetEvent('vSync:updateTime')
AddEventHandler('vSync:updateTime', function(base, offset, freeze, recevieHour, recevieMinute, blackout, theblackoutAnim)
    freezeTime = freeze
    timeOffset = offset
    baseTime = base

    if localTime.hours ~= recevieHour or localTime.minutes ~= recevieMinute then
        localTime.changed = true
    end

    localTime.hours = recevieHour
    localTime.minutes = recevieMinute
    
    inBlackout = blackout
    blackoutAnim = theblackoutAnim
end)

AddEventHandler('null:player:spawned', function()
    TriggerServerEvent('vSync:requestSync')
end)

function ShowNotification(text, blink)
    if blink == nil then blink = false end
    SetNotificationTextEntry("STRING")
    AddTextComponentSubstringPlayerName(text)
    DrawNotification(blink, false)
end


RegisterNetEvent('vSync:notify')
AddEventHandler('vSync:notify', function(message, blink)
    ShowNotification(message, blink)
end)

function Draw3DText(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local p = GetGameplayCamCoords()
    local distance = GetDistanceBetweenCoords(p.x, p.y, p.z, x, y, z, 1)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov
    if onScreen then
        SetTextScale(0.0, 0.35)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x,_y)
    end
end

RegisterNetEvent('SeaLife_ui:showInteraction')
AddEventHandler('SeaLife_ui:showInteraction', function(touche, message)
    position = GetEntityCoords(PlayerPedId(), false)

    --DrawMarker(6, v.position.x, v.position.y, v.position.z, 0.0, 0.0, 0.0, -90.0, 0.0, 0.0, 0.7, 0.7, 0.7, 255, 0, 0, 100, false, false, 2, false, false, false, false)
    --Draw3DText(position.x, position.y, position.z, "Appuyez sur [~r~E~s~]~s~ pour intéragir")
    ESX.ShowHelpNotification("~r~Null\n~s~Appuyez sur "..touche.." pour "..message)
end)


null.InitPrint("Weather Module Initialized")