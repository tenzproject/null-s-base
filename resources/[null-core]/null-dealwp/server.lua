--[[
Comment récuperer les donnes du marcher : 
exports["Null"]:getMarket()


ca return une liste qui ressemble a ca : 
{
    ["meth"] = {
        DrugsRequestPrice = 100,
        DrugsRequestCount = 100,
    },
    ["weed"] = {
        DrugsRequestPrice = 100,
        DrugsRequestCount = 100,
    },
    ...
}
]]

ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function Debugprint(text)
    print("^2[DealWP] ^7" .. text)
end

-- Liste des joueurs en attente d'acheteurs
local dealingPlayers = {}

-- Récupère le palier DealWP en fonction du niveau du groupe
local function getTierForLevel(gangname)
    local level = 1
    if gangname and gangname ~= "unemployed" and gangname ~= "unemployed2" then
        local ok, result = pcall(function() return exports["null-core"]:GetGangLevel(gangname) end)
        if ok and result then level = result end
    end
    for _, tier in ipairs(Config.DealWP.tiers) do
        if level >= tier.minLevel and level <= tier.maxLevel then
            return tier
        end
    end
    return Config.DealWP.defaultTier
end

-- Fonction pour générer un nombre aléatoire entre min et max
local function randomNumber(min, max)
    return math.floor(math.random() * (max - min + 1)) + min
end

-- Fonction pour obtenir un joueur par son identifiant source
local function getPlayerBySource(source)
    for i, player in ipairs(dealingPlayers) do
        if player.source == source then
            return player, i
        end
    end
    return nil, nil
end

-- Fonction pour générer une offre d'achat (utilise le palier du groupe)
local function generateOffer(drugId, tier)
    tier = tier or Config.DealWP.defaultTier

    local market = exports["null-core"]:getMarket()
    if market[drugId] == nil then return 0, 0, false end
    if market[drugId].DrugsRequestCount < 1 then return 0, 0, false end
    
    local quantity = randomNumber(tier.quantities.min, tier.quantities.max)

    if market[drugId].DrugsRequestCount < quantity then
        quantity = market[drugId].DrugsRequestCount
    end
    
    local price = market[drugId].DrugsRequestPrice

    -- Ajustement du prix : base * quantité * variation aléatoire * multiplicateur du palier
    price = math.floor(price * quantity * (0.9 + math.random() * 0.2) * tier.priceMultiplier)
    
    return price, quantity, true
end

-- Événement pour commencer à chercher des acheteurs
RegisterServerEvent("dealwp:startDealing")
AddEventHandler("dealwp:startDealing", function(drugs)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    
    -- Vérifier si le joueur n'est pas déjà en train de chercher des acheteurs
    local player, playerIndex = getPlayerBySource(source)
    if player then return end
    
    -- Récupérer le nom du groupe et le palier
    local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed2"
    local tier = getTierForLevel(gangname)

    -- Ajouter le joueur à la liste des vendeurs
    table.insert(dealingPlayers, {
        source = source,
        identifier = xPlayer.identifier,
        drugs = drugs,
        lastOfferTime = 0,
        gangname = gangname,
        tier = tier
    })
    
    Debugprint("" .. GetPlayerName(source) .. " a commencé à chercher des acheteurs")
end)

local acceptedOffer = {}
RegisterServerEvent("dealwp:acceptOffer")
AddEventHandler("dealwp:acceptOffer", function(offerId, offer)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local idunique = xPlayer.getIdunique()
    
    if xPlayer.getInventoryItem(offer.item).count < offer.quantity then
        TriggerClientEvent('esx:showNotification', src, "Vous n'avez pas assez de " .. offer.drugLabel)
        return
    end

    if acceptedOffer[idunique] ~= nil and acceptedOffer[idunique].time + 120 < os.time() then 
        TriggerClientEvent('esx:showNotification', src, "Vous avez déjà accepté une offre")
        return
    elseif acceptedOffer[idunique] ~= nil then
        acceptedOffer[idunique] = nil
        -- Ancienne offre annulée
    end
    local npcPhoneNumber = tostring(math.random(1000000000, 9999999999))
    local myphoneNumber = exports["lb-phone"]:GetEquippedPhoneNumber(src)
    acceptedOffer[idunique] = {
        time = os.time(),
        id = offerId,
        offer = offer,
        phoneNumber = npcPhoneNumber,
        position = Config.DealWP.Position[math.random(1, #Config.DealWP.Position)],
        pedModel = Config.DealWP.PedList[math.random(1, #Config.DealWP.PedList)],
        pedAnim = Config.DealWP.PedAnim[math.random(1, #Config.DealWP.PedAnim)]
    }
    Debugprint("Phone numbers - player: " .. tostring(myphoneNumber) .. " npc: " .. tostring(npcPhoneNumber))
    if not myphoneNumber then
        Debugprint("ERROR: Player has no equipped phone number!")
        return
    end
    Citizen.CreateThread(function()
        Wait(math.random(1000, 10000))
        if not acceptedOffer[idunique] then return end
        TriggerClientEvent("dealwp:acceptedOffer", src, offerId, acceptedOffer[idunique].offer, acceptedOffer[idunique].position, acceptedOffer[idunique].pedModel, acceptedOffer[idunique].pedAnim)
        Wait(math.random(1000, 5000))
        if not acceptedOffer[idunique] then return end
        local msg = Config.DealWP.MessageList[math.random(1, #Config.DealWP.MessageList)]
        Debugprint("Sending message from " .. npcPhoneNumber .. " to " .. myphoneNumber .. ": " .. msg)
        local ok, err = pcall(function()
            exports["lb-phone"]:SendMessage(npcPhoneNumber, myphoneNumber, msg)
        end)
        if not ok then Debugprint("SendMessage error: " .. tostring(err)) end
        Wait(math.random(1000, 3000))
        if not acceptedOffer[idunique] then return end
        local pos = acceptedOffer[idunique].position
        local coords = vector2(pos.x, pos.y)
        Debugprint("Sending coords: " .. tostring(coords))
        local ok2, err2 = pcall(function()
            exports["lb-phone"]:SendCoords(npcPhoneNumber, myphoneNumber, coords)
        end)
        if not ok2 then Debugprint("SendCoords error: " .. tostring(err2)) end
    end)
end)


RegisterServerEvent("dealwp:dealCompleted")
AddEventHandler("dealwp:dealCompleted", function(offerId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local idunique = xPlayer.getIdunique()

    if acceptedOffer[idunique] == nil then return end
    if acceptedOffer[idunique].id ~= offerId then return end
    
    xPlayer.removeInventoryItem(acceptedOffer[idunique].offer.item, acceptedOffer[idunique].offer.quantity)
    xPlayer.addAccountMoney('dirtycash', acceptedOffer[idunique].offer.price)
    acceptedOffer[idunique] = nil
end)
 


RegisterServerEvent("dealwp:negotiateOffer")
AddEventHandler("dealwp:negotiateOffer", function(offerId, offer, newPrice)
    local src = source
    
    local accepted = math.random() < Config.DealWP.negotiationAcceptChance
    
    if offer.price > newPrice then
        accepted = true
    end

    if newPrice > (offer.price * 1.2) then
        accepted = false
    end
    
    TriggerClientEvent("dealwp:negotiationResult", source, offerId, accepted, newPrice)
    
    Debugprint("" .. GetPlayerName(source) .. " a négocié une offre. Résultat: " .. (accepted and "Acceptée" or "Refusée"))
end)

RegisterServerEvent("dealwp:declineOffer")
AddEventHandler("dealwp:declineOffer", function(offerId, offer)
    local source = source
    Debugprint("" .. GetPlayerName(source) .. " a refusé une offre pour " .. offer.drugLabel)
end)

RegisterServerEvent("dealwp:stopDealing")
AddEventHandler("dealwp:stopDealing", function()
    local source = source
    local player, playerIndex = getPlayerBySource(source)
    if player and playerIndex then
        table.remove(dealingPlayers, playerIndex)
        Debugprint("" .. GetPlayerName(source) .. " a arrêté de chercher des acheteurs (manuellement)")
    end
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    local player, playerIndex = getPlayerBySource(source)
    if player and playerIndex then
        table.remove(dealingPlayers, playerIndex)
        Debugprint("" .. GetPlayerName(source) .. " a arrêté de chercher des acheteurs (déconnexion)")
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        
        local currentTime = os.time()
        
        for i, player in ipairs(dealingPlayers) do
            if not GetPlayerName(player.source) then
                table.remove(dealingPlayers, i)
            else
                local tier = player.tier or Config.DealWP.defaultTier
                if currentTime - player.lastOfferTime >= randomNumber(tier.offerInterval.min, tier.offerInterval.max) then
                    if #player.drugs > 0 then
                        local randomDrugIndex = math.random(1, #player.drugs)
                        local selectedDrug = player.drugs[randomDrugIndex]
                        
                        local price, quantity, can = generateOffer(selectedDrug.id, tier)
                        if can then
                            TriggerClientEvent("dealwp:newOffer", player.source, selectedDrug.id, price, quantity)
                            player.lastOfferTime = currentTime
                        end
                    end
                end
            end
        end
    end
end)