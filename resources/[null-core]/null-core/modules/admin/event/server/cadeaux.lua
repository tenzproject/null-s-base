local AllCadeaux = {}

sleighCoordsPossible = {
    vec3(-1406.481567, -5220.888672, 100.0),
    vec3(-4246.402832, 1774.787231, 100.0),
    vec3(4195.237793, 8088.704590, 100.0),
}

function CreateGift(coords)
    if coords == nil then coords = Config.Event.CadeauNoel.Spawn[math.random(1, #Config.Event.CadeauNoel.Spawn)] end

    print("CreateGift Here : "..coords)

    local id = #AllCadeaux+1
    AllCadeaux[id] = {
        id = id,
        coords = coords,
        reward = Config.Event.CadeauNoel.Reward[math.random(1,#Config.Event.CadeauNoel.Reward)],
        dropped = false,
        get = false,
    }


    TriggerClientEvent("null:noel:dropgift", -1, coords, id, sleighCoordsPossible[math.random(1,#sleighCoordsPossible)])
end

Citizen.CreateThread(function()
    while true do
        Wait(30*60000) -- 30 minutes
        if GetNumPlayerIndices() >= Config.Event.CadeauNoel.MinPlayers then
            CreateGift()
        end
    end
end)

RegisterServerEvent("null:noel:giftdropped")
AddEventHandler("null:noel:giftdropped", function(id)
    if AllCadeaux[id] == nil then return end

    AllCadeaux[id].dropped = true
end)

function RewardGift(reward, xPlayer)
    print("[^1Noel^7] Cadeau tomber du traineau récuperer par "..xPlayer.getIdunique().." (Gain: "..reward.name..")")
    xPlayer.showNotification("🎁 Vous avez réussi a récuperer le Cadeau\nVous avez récuperer "..reward.label)
    if reward.type == "car" then
        plate1 = ""
        for i = 1, 6 do 
            plate1 = plate1..''..math.random(0, 9)
        end

        SaveData.json["owned_vehicles"][string.upper(plate1)] = {
            owner = xPlayer.identifier,
            plate = string.upper(plate1),
            model = reward.name,
            label = reward.name,
            vehicle = { model = GetHashKey(reward.name), plate = plate1 },
            coffre = {},
            type = "car",
            state = true,
            boutique = true,
            garage = true,
        }
    elseif reward.type == "item" then
        xPlayer.addInventoryItem(reward.name, reward.count or 1)
    elseif reward.type == "cash" then
        xPlayer.addAccountMoney(reward.name, reward.count or 1)
    elseif reward.type == "dirtycash" then
        xPlayer.addAccountMoney(reward.name, reward.count or 1)
    elseif reward.type == "bank" then
        xPlayer.addAccountMoney(reward.name, reward.count or 1)
    elseif reward.type == "coins" then
        local identifier = null.fct.getIdentifiers(xPlayer.source)
        if identifier['fivem'] == nil then 
            TriggerClientEvent('chatMessage', xPlayer.source, "Noel", {255, 0, 0}, "Vous n'avez pas lier de compte Fivem, Veuillez faire un ticket sur le discord pour réclamer votre gain sous 1 heure.")
            print("[^1Noel^7] Un joueur a voulus récuperer des coins sans avoir de Compte Fivem, IDUnique: "..xPlayer.getIdunique())
            return 
        end
        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
        LiteMySQL:Insert('tebex_players_wallet', {
            identifiers = after,
            idunique = xPlayer.getIdunique(),
            transaction = "Cadeau Noel",
            price = 0,
            currency = 'Points',
            points = reward.count,
        });
    end
end

RegisterServerEvent("null:noel:get")
AddEventHandler("null:noel:get", function(id)
    if AllCadeaux[id] == nil then return end
    if AllCadeaux[id].dropped == false then return end
    if AllCadeaux[id].get == true then return end
    local xPlayer = ESX.GetPlayerFromId(source)

    TriggerClientEvent("null:noel:deletegift", -1)
    AllCadeaux[id].get = true
    RewardGift(AllCadeaux[id].reward, xPlayer)
    AllCadeaux[id] = nil
end)



RegisterServerEvent("null:staff:noel:start")
AddEventHandler("null:staff:noel:start", function(coords)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    CreateGift(coords)
end)