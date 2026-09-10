null.players.afk = {}
ListeJoueursSleepy = {}

RegisterNetEvent("null:afk:join", function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local afk = xPlayer.getAfk()
    null.players.afk[xPlayer.getIdunique()] = {
        idunique = xPlayer.getIdunique(),
        source = source,
        point = afk.point,
        time = afk.time,
        ostime = os.time(),
    }
    SetEntityCoords(GetPlayerPed(source), 482.894348, 4811.361328, -58.382843)
    TriggerClientEvent("null:afk:init", source)
end)

RegisterNetEvent("null:afk:exit", function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if null.players.afk[xPlayer.getIdunique()] == nil then return end
    xPlayer.setAfk(null.players.afk[xPlayer.getIdunique()].time, null.players.afk[xPlayer.getIdunique()].point)
    null.players.afk[xPlayer.getIdunique()] = nil
    SetEntityCoords(GetPlayerPed(source), 218.774261, -808.359192, 30.707996)
    TriggerClientEvent("null:afk:init", source)
end) 

RegisterNetEvent("null:afk:gettimer", function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if null.players.afk[xPlayer.getIdunique()] == nil then return end
    xPlayer.setAfk(null.players.afk[xPlayer.getIdunique()].time, null.players.afk[xPlayer.getIdunique()].point)
    TriggerClientEvent("null:afk:refresh", source, null.players.afk[xPlayer.getIdunique()].time, null.players.afk[xPlayer.getIdunique()].point)
end)

RegisterNetEvent("null:afk:shopbuy")
AddEventHandler('null:afk:shopbuy', function(product)
    local xPlayer = ESX.GetPlayerFromId(source)
    if null.players.afk[xPlayer.getIdunique()] == nil then return end
    if Config.Afk.Invest.Lot[product] == nil then return end
    xPlayer.setAfk(null.players.afk[xPlayer.getIdunique()].time, null.players.afk[xPlayer.getIdunique()].point)
    local afk = xPlayer.getAfk()
    if afk.point < Config.Afk.Invest.Lot[product].price then return end

    xPlayer.setAfk(null.players.afk[xPlayer.getIdunique()].time, null.players.afk[xPlayer.getIdunique()].point-Config.Afk.Invest.Lot[product].price)
    xPlayer.addInventoryItem(Config.Afk.Invest.Lot[product].itemtogive, 1)

    local afk = xPlayer.getAfk()
    null.players.afk[xPlayer.getIdunique()].point = afk.point
    TriggerClientEvent("null:afk:refresh", source, null.players.afk[xPlayer.getIdunique()].time, null.players.afk[xPlayer.getIdunique()].point)
end)


RegisterNetEvent("null:afk:iamafk:sleep")
AddEventHandler('null:afk:iamafk:sleep', function(data)
    local src = source
    if ListeJoueursSleepy[src] ~= nil then return end
    ListeJoueursSleepy[src] = {
        time = (12*15),
        coords = vec3(data.x, data.y, data.z-0.80)
    }
    TriggerClientEvent("null:afk:sleep:recevieplayers", -1, ListeJoueursSleepy)
end)

RegisterNetEvent("null:afk:iamafk:sleep:udapte")
AddEventHandler('null:afk:iamafk:sleep:udapte', function(data)
    local src = source
    if ListeJoueursSleepy[src] == nil then return end
    null.DebugPrint(ListeJoueursSleepy[src].time, data/60)
    ListeJoueursSleepy[src].time = data/60
    TriggerClientEvent("null:afk:sleep:recevieplayers", -1, ListeJoueursSleepy)
end)

RegisterNetEvent("null:afk:iamnotafk:sleep")
AddEventHandler('null:afk:iamnotafk:sleep', function()
    local src = source
    if ListeJoueursSleepy[src] == nil then return end
    ListeJoueursSleepy[src] = nil
    TriggerClientEvent("null:afk:sleep:recevieplayers", -1, ListeJoueursSleepy)
end)

AddEventHandler('esx:playerDropped', function(eventSrc, xPlayer)
    if ListeJoueursSleepy[src] ~= nil then 
        ListeJoueursSleepy[src] = nil
    end
    
    if null.players.afk[xPlayer.getIdunique()] ~= nil then
        xPlayer.setAfk(null.players.afk[xPlayer.getIdunique()].time, null.players.afk[xPlayer.getIdunique()].point)
        null.players.afk[xPlayer.getIdunique()] = nil
    end
end)

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        for k,v in pairs(null.players.afk) do
            local xPlayer = ESX.GetPlayerFromId(v.source)
            if xPlayer == nil then
                null.players.afk[v.idunique] = nil
            else
                null.players.afk[v.idunique].time = null.players.afk[v.idunique].time + 1
                null.players.afk[v.idunique].point = null.players.afk[v.idunique].point + 0.5
                TriggerClientEvent("esx:showNotification", null.players.afk[v.idunique].source, "Vous avez gagner 0.5 point afk.")
                xPlayer.setAfk(null.players.afk[xPlayer.getIdunique()].time, null.players.afk[xPlayer.getIdunique()].point)                
            end
            TriggerClientEvent("null:afk:refresh", xPlayer.source, null.players.afk[xPlayer.getIdunique()].time, null.players.afk[xPlayer.getIdunique()].point)
        end
        Wait(60000)
    end
end))
