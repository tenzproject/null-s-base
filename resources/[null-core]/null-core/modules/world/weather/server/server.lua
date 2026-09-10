-- Set this to false if you don't want the weather to change automatically every 10 minutes.
DynamicWeather = true

--------------------------------------------------
debugprint = false -- don't touch this unless you know what you're doing or you're being asked by Vespura to turn this on.
-------------------- DON'T CHANGE THIS --------------------
AvailableWeatherTypes = {
    'EXTRASUNNY', 
    'CLEAR', 
    'NEUTRAL', 
    'SMOG', 
    'FOGGY', 
    'OVERCAST', 
    'CLOUDS', 
    'CLEARING', 
    'RAIN', 
    'THUNDER', 
    'SNOW', 
    'BLIZZARD', 
    'SNOWLIGHT', 
    'XMAS', 
    'HALLOWEEN',
}
CurrentWeather = "EXTRASUNNY"
nextWeather = nil
saveWeather = "EXTRASUNNY"
local baseTime = 0
local timeOffset = 0
local freezeTime = false
local freezeWeather = false
local blackoutAnim = true
local blackout = false
local DefautNextWeahterTime = 30
local newWeatherTimer = DefautNextWeahterTime


localTime = {
    hours = 12,
    minutes = 0,
}

RegisterServerEvent('vSync:requestSync')
AddEventHandler('vSync:requestSync', function()
    TriggerClientEvent('vSync:updateWeather', -1, CurrentWeather, freezeWeather, nextWeather, newWeatherTimer)
    TriggerClientEvent('vSync:updateTime', -1, baseTime, timeOffset, freezeTime, localTime.hours, localTime.minutes, blackout, blackoutAnim)
end)

RegisterServerEvent('null:weather:changeFreeze')
AddEventHandler('null:weather:changeFreeze', function(freezeTime2, freezeWeather2, bool)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    if bool and freezeWeather2 then
        saveWeather = CurrentWeather
    elseif bool then
        CurrentWeather = saveWeather
    end
    freezeTime, freezeWeather = freezeTime2, freezeWeather2

    SaveData.json["vsync"]["freeze"] = {
        ["weather"] = freezeWeather,
        ["time"] = freezeTime,
    }

    TriggerClientEvent('vSync:updateWeather', -1, CurrentWeather, freezeWeather, nextWeather, newWeatherTimer)
    TriggerClientEvent('vSync:updateTime', -1, baseTime, timeOffset, freezeTime, localTime.hours, localTime.minutes, blackout, blackoutAnim)
end)

RegisterServerEvent('null:weather:changeTime')
AddEventHandler('null:weather:changeTime', function(newHours, newMinutes)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    if not freezeTime and Config.Weather.UseRealTime then 
        return 
    end
    localTime.hours, localTime.minutes = newHours, newMinutes
    SaveData.json["vsync"]["time"] = {
        h = localTime.hours,
        m = localTime.minutes
    }
    TriggerClientEvent('vSync:updateTime', -1, baseTime, timeOffset, freezeTime, localTime.hours, localTime.minutes, blackout, blackoutAnim)
end)

RegisterServerEvent('null:weather:requestWeatherTimer')
AddEventHandler('null:weather:requestWeatherTimer', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer.getGroup() == "user" then return end
    TriggerClientEvent('vSync:updateWeatherTimer', src, newWeatherTimer)
end)

RegisterServerEvent('null:weather:changeBlackOutAnim')
AddEventHandler('null:weather:changeBlackOutAnim', function(newblackoutAnim)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    blackoutAnim = newblackoutAnim
    TriggerClientEvent('vSync:updateTime', -1, baseTime, timeOffset, freezeTime, localTime.hours, localTime.minutes, blackout, blackoutAnim)
end)

RegisterServerEvent('null:weather:changeBlackout')
AddEventHandler('null:weather:changeBlackout', function(value)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" and xPlayer.getJob().name ~= "gouvernement" then return end
    blackout = value
    if xPlayer.getJob().name == "gouvernement" then
        TriggerClientEvent('vSync:updateTime', -1, baseTime, timeOffset, freezeTime, localTime.hours, localTime.minutes, blackout, true)
    else
        TriggerClientEvent('vSync:updateTime', -1, baseTime, timeOffset, freezeTime, localTime.hours, localTime.minutes, blackout, blackoutAnim)
    end
end)

RegisterServerEvent('null:weather:changeWeather')
AddEventHandler('null:weather:changeWeather', function(newWeather, bool)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    if bool then
        if freezeWeather then return end
        nextWeather = newWeather
        TriggerClientEvent('vSync:updateWeather', -1, CurrentWeather, freezeWeather, nextWeather, newWeatherTimer)
    else
        if not freezeWeather then return end
        CurrentWeather = newWeather
        TriggerClientEvent('vSync:updateWeather', -1, CurrentWeather, freezeWeather, nextWeather, newWeatherTimer)
    end
    SaveData.json["vsync"]["weather"] = CurrentWeather
end)

function isAllowedToChange(player)
    local allowed = false
    for x,pid in ipairs(GetPlayerIdentifiers(player)) do
        if Config.AllowedLicences[pid] == true then
            allowed = true
        end
    end
    return allowed
end

RegisterCommand('freezetime', function(source, args)
    if source ~= 0 then
        if isAllowedToChange(source) then
            freezeTime = not freezeTime
            if freezeTime then
                TriggerClientEvent('esx:showNotification', source, 'Time is now frozen~s~.')
            else
                TriggerClientEvent('esx:showNotification', source, 'Time is no longer frozen~s~.')
            end
        else
            TriggerClientEvent('chatMessage', source, '', {255,255,255}, '^8Error: ^1Vous n\'etes pas autorisé a utiliser cette commande.')
        end
    else
        freezeTime = not freezeTime
        if freezeTime then
            print("Le temps est freeze.")
        else
            print("Le temps n\'est plus freeze .")
        end
    end
end)

RegisterCommand('freezeweather', function(source, args)
    if source ~= 0 then
        if isAllowedToChange(source) then
            DynamicWeather = not DynamicWeather
            if not DynamicWeather then
                TriggerClientEvent('esx:showNotification', source, 'Changements métérologiques dynamiques desactivé~s~.')
            else
                TriggerClientEvent('esx:showNotification', source, 'Changements métérologiques dynamiques activé~s~.')
            end
        else
            TriggerClientEvent('chatMessage', source, '', {255,255,255}, '^8Error: ^1Vous n\'etes pas autorisé a utiliser cette commande.')
        end
    else
        DynamicWeather = not DynamicWeather
        if not DynamicWeather then
            print("La météo est freeze.")
        else
            print("La météo n\'est plus freeze.")
        end
    end
end)

RegisterCommand('weather', function(source, args)
    if source == 0 then
        local validWeatherType = false
        if args[1] == nil then
            print("Commande invalide, la commande est: /weather <weathertype> ")
            return
        else
            for i,wtype in ipairs(AvailableWeatherTypes) do
                if wtype == string.upper(args[1]) then
                    validWeatherType = true
                end
            end
            if validWeatherType then
                print("Le temps à été mis a jour.")
                CurrentWeather = string.upper(args[1])
                newWeatherTimer = DefautNextWeahterTime
                TriggerEvent('vSync:requestSync')
            else
                print("Météo invalide, les types de météos valides sont: \nEXTRASUNNY CLEAR NEUTRAL SMOG FOGGY OVERCAST CLOUDS CLEARING RAIN THUNDER SNOW BLIZZARD SNOWLIGHT XMAS HALLOWEEN ")
            end
        end
    else
        if isAllowedToChange(source) then
            local validWeatherType = false
            if args[1] == nil then
                TriggerClientEvent('chatMessage', source, '', {255,255,255}, '^8Error: ^1Invalid syntax, use ^0/weather <weatherType> ^1instead!')
            else
                for i,wtype in ipairs(AvailableWeatherTypes) do
                    if wtype == string.upper(args[1]) then
                        validWeatherType = true
                    end
                end
                if validWeatherType then
                    null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a /weather "..string.lower(args[1]), "weather", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})
                    TriggerClientEvent('esx:showNotification', source, 'Weather will change to: ' .. string.lower(args[1]) .. "~s~.")
                    CurrentWeather = string.upper(args[1])
                    newWeatherTimer = DefautNextWeahterTime
                    TriggerEvent('vSync:requestSync')
                else
                    TriggerClientEvent('chatMessage', source, '', {255,255,255}, '^8Error: ^1Invalid weather type, valid weather types are: ^0\nEXTRASUNNY CLEAR NEUTRAL SMOG FOGGY OVERCAST CLOUDS CLEARING RAIN THUNDER SNOW BLIZZARD SNOWLIGHT XMAS HALLOWEEN ')
                end
            end
        else
            TriggerClientEvent('chatMessage', source, '', {255,255,255}, '^8Error: ^1You do not have access to that command.')
            print('Accès pour la commande /weather refusé.')
        end
    end
end, false)

RegisterCommand('nextweather', function(source)
    if source == 0 then
        if nextWeather ~= nil then
            CurrentWeather = nextWeather
            nextWeather = NextWeatherStage()
        else
            CurrentWeather = NextWeatherStage()
            nextWeather = NextWeatherStage()
        end
        TriggerEvent("vSync:requestSync")
    else
        if nextWeather ~= nil then
            CurrentWeather = nextWeather
            nextWeather = NextWeatherStage()
        else
            CurrentWeather = NextWeatherStage()
            nextWeather = NextWeatherStage()
        end
        TriggerEvent("vSync:requestSync")
        TriggerClientEvent('esx:showNotification', source, 'Changement de méteo aléatoirement en cours...')
    end
end)


function ShiftToMinute(minute)
    timeOffset = timeOffset - ( ( (baseTime+timeOffset) % 60 ) - minute )
end

function ShiftToHour(hour)
    timeOffset = timeOffset - ( ( ((baseTime+timeOffset)/60) % 24 ) - hour ) * 60
end

RegisterCommand('time', function(source, args, rawCommand)
    if source == 0 then
        if tonumber(args[1]) ~= nil and tonumber(args[2]) ~= nil then
            local argh = tonumber(args[1])
            local argm = tonumber(args[2])
            if argh < 24 then
                ShiftToHour(argh)
            else
                ShiftToHour(0)
            end
            if argm < 60 then
                ShiftToMinute(argm)
            else
                ShiftToMinute(0)
            end
            localTime.hours, localTime.minutes = argh, argm
            print("L'heure est désormais " .. argh .. ":" .. argm .. ".")
            TriggerEvent('vSync:requestSync')
        else
            print("Syntax invalide, la syntaxe correcte est: time <hour> <minute> !")
        end
    elseif source ~= 0 then
        if isAllowedToChange(source) then
            if tonumber(args[1]) ~= nil and tonumber(args[2]) ~= nil then
                local argh = tonumber(args[1])
                local argm = tonumber(args[2])
                if argh < 24 then
                    ShiftToHour(argh)
                else
                    ShiftToHour(0)
                end
                if argm < 60 then
                    ShiftToMinute(argm)
                else
                    ShiftToMinute(0)
                end
                local newtime = math.floor(((baseTime+timeOffset)/60)%24) .. ":"
				local minute = math.floor((baseTime+timeOffset)%60)
                if minute < 10 then
                    newtime = newtime .. "0" .. minute
                else
                    newtime = newtime .. minute
                end
                localTime.hours, localTime.minutes = argh, argm
                null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a /time en "..newtime, "time", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})
                    TriggerClientEvent('esx:showNotification', source, 'Time was changed to: ' .. newtime .. "~s~!")
                TriggerEvent('vSync:requestSync')
            else
                TriggerClientEvent('chatMessage', source, '', {255,255,255}, '^8Error: ^1Invalid syntax. Use ^0/time <hour> <minute> ^1instead!')
            end
        else
            TriggerClientEvent('chatMessage', source, '', {255,255,255}, '^8Error: ^1You do not have access to that command.')
            print('Accès a la commande /time refusé.')
        end
    end
end)

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    local timetowait = 0
    while true do
        if Config.Weather.UseRealTime then
            local date = os.date("*t")
            local newBaseTime = os.time(os.date("!*t"))/2 + 360
            if not freezeTime then
                baseTime = newBaseTime
                localTime.hours, localTime.minutes = date.hour, date.min
            end
            timetowait = 0
        else
            if not freezeTime then
                if localTime.hours >= 24 then
                    localTime.hours = 0
                end
                if localTime.minutes >= 60 then
                    localTime.minutes = 0
                    if Config.Weather.Debug then
                        null.DebugPrint("Minutes Updated: 60 -> 0")
                    end
                    localTime.hours += 1
                    if Config.Weather.Debug then
                        null.DebugPrint("Hours Updated: "..tostring(localTime.hours - 1).." -> "..localTime.hours.."")
                    end
                end
                localTime.minutes += 1 
                if Config.Weather.Debug then
                    null.DebugPrint("Minutes Updated: "..tostring(localTime.minutes - 1).." -> "..localTime.minutes.."")
                end
            end
            --TriggerClientEvent('vSync:updateTime', -1, 0, 0, freezeTime, localTime.hours, localTime.minutes, blackout, blackoutAnim)
            timetowait = Config.Weather.TimeToWait
        end
        Citizen.Wait(timetowait)
    end
end))

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        Citizen.Wait(2*60*1000)
        if not freezeTime then
            SaveData.json["vsync"]["time"] = {
                h = localTime.hours,
                m = localTime.minutes
            }
        end
        TriggerClientEvent('vSync:updateTime', -1, baseTime, timeOffset, freezeTime, localTime.hours, localTime.minutes, blackout, blackoutAnim)
    end
end))

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        Citizen.Wait(300000)
        SaveData.json["vsync"]["weather"] = CurrentWeather
        TriggerClientEvent('vSync:updateWeather', -1, CurrentWeather, freezeWeather, nextWeather, newWeatherTimer)
    end
end))

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    Wait(1000)
    CurrentWeather = NextWeatherStage()
    nextWeather = NextWeatherStage()
    TriggerClientEvent('vSync:updateWeather', -1, CurrentWeather, freezeWeather, nextWeather, newWeatherTimer)

    while true do
        newWeatherTimer = newWeatherTimer - 1
        Citizen.Wait(60000)
        if newWeatherTimer == 0 then
            if DynamicWeather and not freezeWeather then
                if nextWeather ~= nil then
                    CurrentWeather = nextWeather
                    nextWeather = NextWeatherStage()
                else
                    CurrentWeather = NextWeatherStage()
                    nextWeather = NextWeatherStage()
                end
                TriggerEvent("vSync:requestSync")
            end
            newWeatherTimer = DefautNextWeahterTime
        end
    end
end))



function isSnowDay()
  for i, decemberSnowDay in ipairs(Config.Weather.decemberSnowDays) do
    if decemberSnowDay == os.date("*t").day then
      return true
    end
  end
  return false
end

function NextWeatherStage()
    if freezeWeather then null.DebugPrint("[^5Null^7]  Tentative de changement de Météo alors qu'elle est Freeze.") return end
    local date = os.date("*t")
    local generatedWeather = nil
    local PossibleWeather = {
        "FOGGY",
        "OVERCAST",
        "CLEAR",
        "CLOUDS",
        "EXTRASUNNY",
        "OVERCAST",
        "THUNDER",
        "RAIN"
    }
    --generatedWeather = PossibleWeather[math.random(1, #PossibleWeather)]
    local new = math.random(1,7)
    if date.month == 12 and isSnowDay() and Config.Weather.snowEnabled then -- Si decembre et jour de neige
        generatedWeather = "XMAS"
    elseif date.hour > 4 and date.hour < 10 then -- Entre 4h et 10h
        if new < 5 then
            generatedWeather = "FOGGY"
        elseif new == 5 then
            generatedWeather = "CLOUDS"
        elseif new == 6 then
            generatedWeather = "SMOG"
        elseif new == 7 then
            generatedWeather = "BLIZZARD"
        end
    elseif (date.hour >= 20) or (date.hour <= 4) then -- Entre 20h et 4h 
        if new < 5 then
            generatedWeather = "CLEAR"
        elseif new >= 5 then
            generatedWeather = "CLOUDS"
        end
    else
        if new == 1 then
            generatedWeather = "OVERCAST"
        elseif new == 2 then
            generatedWeather = "CLEAR"
        elseif new == 3 then
            generatedWeather = "CLOUDS"
        elseif new == 4 then
            generatedWeather = "EXTRASUNNY"
        elseif new == 5 then
            generatedWeather = "OVERCAST"
        elseif new == 6 then
            generatedWeather = "SMOG"
        elseif new == 7 then
            generatedWeather = "RAIN"
        end
    end
    newWeatherTimer = DefautNextWeahterTime
    if debugprint then
        null.DebugPrint("[^5Null^7]  Un nouveau type de météo aléatoire a été généré: " .. generatedWeather .. ".")
        null.DebugPrint("[^5Null^7]  Réinitialiser la minuterie à "..DefautNextWeahterTime.." minutes.")
    end
    return generatedWeather
end


Citizen.CreateThread(function()
    while SaveData.json["vsync"] == nil do Wait(10) end
    Wait(4100)
    if SaveData.json["vsync"]["freeze"]["weather"] == true and SaveData.json["vsync"]["weather"] ~= nil then
        freezeWeather = true
        CurrentWeather = SaveData.json["vsync"]["weather"]
        nextWeather = SaveData.json["vsync"]["weather"]
        newWeatherTimer = DefautNextWeahterTime

        TriggerClientEvent('vSync:updateWeather', -1, CurrentWeather, freezeWeather, nextWeather, newWeatherTimer)
    end
    if SaveData.json["vsync"]["freeze"]["time"] == true then
        freezeTime = true
        localTime.hours = SaveData.json["vsync"]["time"]["h"]
        localTime.minutes = SaveData.json["vsync"]["time"]["m"]
        TriggerClientEvent('vSync:updateTime', -1, baseTime, timeOffset, freezeTime, localTime.hours, localTime.minutes, blackout, blackoutAnim)
    else
        if not Config.Weather.UseRealTime then
            localTime.hours = SaveData.json["vsync"]["time"]["h"]
            localTime.minutes = SaveData.json["vsync"]["time"]["m"]
        end
    end
end)

null.InitPrint("Weather Module Initialized")