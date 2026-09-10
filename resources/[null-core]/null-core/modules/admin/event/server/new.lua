if SaveData.Events.CamionBlinder == nil then SaveData.Events.CamionBlinder = {} end

-- @TODO: reactive when correctly work 
-- CreateThread(function()
--     while true do
--         Wait(Config.Event.CamionBlinder.AutoEventInterval*60*1000)
--         if GetNumPlayerIndices() > Config.Event.CamionBlinder.AutoEventNbrPlayer then
--             local autoEvent_DATA = Config.Event.CamionBlinder.AutoEvent[math.random(1, #Config.Event.CamionBlinder.AutoEvent)]
--             local data = {
--                 id = math.random(1,999999),
--                 position = autoEvent_DATA.pos,
--                 reward = autoEvent_DATA.reward
--             }
--             TriggerClientEvent('esx:showNotification', -1, '🚚 ~r~Un fourgon blindé vient de tomber en panne ! Viens vite le casser et récupérer l\'argent avant que la police le sécurise')
--             TriggerClientEvent('null:Eventstart', -1, data)
--         end
--     end
-- end) 

RegisterNetEvent('null:Eventbroke', function(data)
    if SaveData.Events.CamionBlinder[data.id] == nil then return end
    if SaveData.Events.CamionBlinder[data.id].broke == true then return end
    TriggerClientEvent('esx:showNotification', -1, '🚚 ~r~Fourgon Blindé\nLe véhicule vient d\'être détruit !')
    TriggerClientEvent('null:Eventbroke', -1, data)
    SaveData.Events.CamionBlinder[data.id].broke = true
end)

RegisterNetEvent('null:EventsecondBroke', function(data)
    local source = source
    TriggerClientEvent('null:EventsecondBroke', source, data)
end)

RegisterServerEvent('null:server:Eventtake', function(obj, k, id)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.Events.CamionBlinder[id] == nil then return end
    if SaveData.Events.CamionBlinder[id].finish == true then return end
    if SaveData.Events.CamionBlinder[id].broke == false then return end
    if SaveData.Events.CamionBlinder[id].nbrProps <= 0 then return end
    SaveData.Events.CamionBlinder[id].nbrProps = SaveData.Events.CamionBlinder[id].nbrProps - 1
    xPlayer.addAccountMoney('dirtycash', Config.Event.CamionBlinder.PricePerPalette)
    TriggerClientEvent("inventory:sendMessage", xPlayer.source, ('💲 ~y~+%s$~s~ d\'argent sale'):format(Config.Event.CamionBlinder.PricePerPalette))
    TriggerClientEvent('null:client:Eventtake', -1, obj, k)
end)

RegisterServerEvent('null:server:Eventstop', function(position, id)
    if SaveData.Events.CamionBlinder[id] == nil then return end
    if SaveData.Events.CamionBlinder[id].broke ~= true then return end
    if SaveData.Events.CamionBlinder[id].finish == true then return end
    SaveData.Events.CamionBlinder[id].finish = true
    TriggerClientEvent('null:client:Eventstop', -1, position)
    TriggerClientEvent('esx:showNotification', -1, '🚚 L\'événement ~y~casse de fourgon blindé~s~ vient de se terminer !')
    SaveData.Events.CamionBlinder[id] = nil
end)

RegisterNetEvent("null:startbrinksevent")
AddEventHandler("null:startbrinksevent", function(position, rewards)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= "user" then
        local data = {
            id = math.random(1,999999),
            position = position,
            reward = rewards
        }
        SaveData.Events.CamionBlinder[data.id] = data
        SaveData.Events.CamionBlinder[data.id].nbrProps = #data.reward
        SaveData.Events.CamionBlinder[data.id].broke = false
        SaveData.Events.CamionBlinder[data.id].finish = false
        TriggerClientEvent('esx:showNotification', -1, '🚚 Un ~r~fourgon blindé~s~ vient de tomber en panne ! Viens vite le casser et récupérer l\'argent avant que la police le sécurise')
        TriggerClientEvent('null:Eventstart', -1, data)
    end
end)

RegisterNetEvent("null:startbrinkseventauto")
AddEventHandler("null:startbrinkseventauto", function()
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.getGroup() ~= "user" then
        local autoEvent_DATA = Config.Event.CamionBlinder.AutoEvent[math.random(1, #Config.Event.CamionBlinder.AutoEvent)]
        local data = {
            id = math.random(1,999999),
            position = autoEvent_DATA.pos,
            reward = autoEvent_DATA.reward
        }
        SaveData.Events.CamionBlinder[data.id] = data
        SaveData.Events.CamionBlinder[data.id].nbrProps = #data.reward
        SaveData.Events.CamionBlinder[data.id].broke = false
        SaveData.Events.CamionBlinder[data.id].finish = false
        TriggerClientEvent('esx:showNotification', -1, '🚚 ~r~Un fourgon blindé vient de tomber en panne ! Viens vite le casser et récupérer l\'argent avant que la police le sécurise')
        TriggerClientEvent('null:Eventstart', -1, data)
    else
        
    end
end)

RegisterCommand('startautoevent', function(source, args)
    if source == 0 then
        local autoEvent_DATA = Config.Event.CamionBlinder.AutoEvent[math.random(1, #Config.Event.CamionBlinder.AutoEvent)]
        local data = {
            id = math.random(1,999999),
            position = autoEvent_DATA.pos,
            reward = autoEvent_DATA.reward
        }
        SaveData.Events.CamionBlinder[data.id] = data
        SaveData.Events.CamionBlinder[data.id].broke = false
        SaveData.Events.CamionBlinder[data.id].finish = false
        TriggerClientEvent('esx:showNotification', -1, '🚚 ~r~Un fourgon blindé vient de tomber en panne ! Viens vite le casser et récupérer l\'argent avant que la police le sécurise')
        TriggerClientEvent('null:Eventstart', -1, data)
    end
end)

