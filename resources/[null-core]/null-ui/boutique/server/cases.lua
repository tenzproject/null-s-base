local labeltype = nil

local function caserandom(x, y)
    local u = 0;
    u = u + 1
    if x ~= nil and y ~= nil then
        return math.floor(x + (math.random(math.randomseed(os.time() + u)) * 999999 % y))
    else
        return math.floor((math.random(math.randomseed(os.time() + u)) * 100))
    end
end

sBoutiqueBoutique = sBoutiqueBoutique or {};
sBoutiqueBoutique.Cache = sBoutiqueBoutique.Cache or {}
sBoutiqueBoutique.Cache.Case = sBoutiqueBoutique.Cache.Case or {}

function GenerateLootbox(source, box, list)
    local chance = math.random(1, 100)
    local gift = { category = 1, item = 1 }
    local Nullamount = 0
    local minimalChance = Config.Boutique.Crates.Chances.Ultime

    local identifier = GetIdentifiers(source);
    if (sBoutiqueBoutique.Cache.Case[source] == nil) then
        sBoutiqueBoutique.Cache.Case[source] = {};
        if (sBoutiqueBoutique.Cache.Case[source][box] == nil) then
            sBoutiqueBoutique.Cache.Case[source][box] = {};
        end
    end
    if chance <= minimalChance then
        local rand = math.random(1, #list[4])
        sBoutiqueBoutique.Cache.Case[source][box][4] = list[4][rand]
        gift.category = 4
        Nullamount = list[4][rand].amount
        gift.item = list[4][rand].model
    elseif (chance > minimalChance and chance <= Config.Boutique.Crates.Chances.Legendary) then
        local rand = math.random(1, #list[3])
        sBoutiqueBoutique.Cache.Case[source][box][3] = list[3][rand]
        gift.category = 3
        Nullamount = list[3][rand].amount
        gift.item = list[3][rand].model
    elseif (chance > minimalChance and chance <= Config.Boutique.Crates.Chances.Rare) then
        local rand = math.random(1, #list[2])
        sBoutiqueBoutique.Cache.Case[source][box][2] = list[2][rand]
        gift.category = 2
        Nullamount = list[2][rand].amount
        gift.item = list[2][rand].model
    else
        local rand = math.random(1, #list[1])
        sBoutiqueBoutique.Cache.Case[source][box][1] = list[1][rand]
        gift.category = 1
        Nullamount = list[1][rand].amount
        gift.item = list[1][rand].model
    end
    local finalList = {}
    for _, category in pairs(list) do
        for _, item in pairs(category) do
            local result = { customUrl = item.customUrl, url = item.url,name = item.model, time = 150 }
            table.insert(finalList, result)
        end
    end

    
    table.insert(finalList, { name = gift.item, time = 5000 })
    return finalList, gift.item, Nullamount
end



function OpenCaisse(source, type)
    local identifier = GetIdentifiers(source);
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer == nil then return end
    if Config.Boutique.Crates.List[type] == nil then return end
    if xPlayer.getInventoryItem(type) == nil then return end
    if xPlayer.getInventoryItem(type).count <= 0 then return end
    if identifier['fivem'] == nil then return end
    local before, after = identifier['fivem']:match("([^:]+):([^:]+)")

    local boxId = 1;
    local box = {}
    box[1],box[2],box[3],box[4] = {},{},{},{}
    for k,v in pairs(Config.Boutique.Crates.List[type].Inside) do
        if v.rarity == 1 then
            table.insert(box[1],v) 
        elseif v.rarity == 2 then
            table.insert(box[2],v) 
        elseif v.rarity == 3 then
            table.insert(box[3],v) 
        elseif v.rarity == 4 then
            table.insert(box[4],v) 
        end
    end
    local lists, result, null = GenerateLootbox(source, boxId, box)
    local giveReward = {
        ["vehicle"] = function(_s, license, player)
            local HashVeh = GetHashKey(result)
            local Target = ESX.GetPlayerFromId(source)
            local identifier = GetIdentifiers(source)
            if (identifier['fivem']) then
                local found = false
                local PlateExist = true
                local newplate = nil
                local oldCacheData = exports["null-core"]:GetCacheData("owned_vehicles")
                while PlateExist do
                    newplate = null.fct.format.randomPlateText()
                    if oldCacheData[string.upper(newplate)] == nil then
                        PlateExist = false
                    end
                    Wait(100)
                end
                for k,v in pairs(oldCacheData) do 
                    if v.owner == xPlayer.identifier then
                        if v.model == result then
                            xPlayer.showNotification('Vous avez déjà le véhicule\nLa caisses a était rembourser')
                            xPlayer.addInventoryItem(type, 1)
                            found = true
                            break
                        end
                    end
                end
                if not found then
                    oldCacheData[string.upper(newplate)] = {
                        owner = xPlayer.identifier,
                        plate = string.upper(newplate),
                        model = result,
                        label = result,
                        vehicle = { model = GetHashKey(result), plate = newplate },
                        coffre = {},
                        type = "car",
                        state = true,
                        boutique = true,
                        garage = true,
                    }
                    exports["null-core"]:EditCacheData("owned_vehicles", oldCacheData)
                end
            end
        end,
        ["helico"] = function(_s, license, player)
            local HashVeh = GetHashKey(result)
            local Target = ESX.GetPlayerFromId(source)
            local identifier = GetIdentifiers(source)
            if (identifier['fivem']) then
                local found = false
                local PlateExist = true
                local newplate = nil
                local oldCacheData = exports["null-core"]:GetCacheData("owned_vehicles")
                while PlateExist do
                    newplate = null.fct.format.randomPlateText()
                    if oldCacheData[string.upper(newplate)] == nil then
                        PlateExist = false
                    end
                    Wait(100)
                end
                for k,v in pairs(oldCacheData) do 
                    if v.owner == xPlayer.identifier then
                        if v.model == result then
                            xPlayer.showNotification('Vous avez déjà le véhicule\nLa caisses a était rembourser')
                            xPlayer.addInventoryItem(type, 1)
                            found = true
                            break
                        end
                    end
                end
                if not found then
                    oldCacheData[string.upper(newplate)] = {
                        owner = xPlayer.identifier,
                        plate = string.upper(newplate),
                        model = result,
                        label = result,
                        vehicle = { model = GetHashKey(result), plate = newplate },
                        coffre = {},
                        type = "aircraft",
                        state = true,
                        boutique = true,
                        garage = true,
                    }
                    exports["null-core"]:EditCacheData("owned_vehicles", oldCacheData)
                end
            end
        end,
        ["boat"] = function(_s, license, player)
            local HashVeh = GetHashKey(result)
            local Target = ESX.GetPlayerFromId(source)
            local identifier = GetIdentifiers(source)
            if (identifier['fivem']) then
                local found = false
                local PlateExist = true
                local newplate = nil
                local oldCacheData = exports["null-core"]:GetCacheData("owned_vehicles")
                while PlateExist do
                    newplate = null.fct.format.randomPlateText()
                    if oldCacheData[string.upper(newplate)] == nil then
                        PlateExist = false
                    end
                    Wait(100)
                end
                for k,v in pairs(oldCacheData) do 
                    if v.owner == xPlayer.identifier then
                        if v.model == result then
                            xPlayer.showNotification('Vous avez déjà le véhicule\nLa caisses a était rembourser')
                            xPlayer.addInventoryItem(type, 1)
                            found = true
                            break
                        end
                    end
                end
                if not found then
                    oldCacheData[string.upper(newplate)] = {
                        owner = xPlayer.identifier,
                        plate = string.upper(newplate),
                        model = result,
                        label = result,
                        vehicle = { model = GetHashKey(result), plate = newplate },
                        coffre = {},
                        type = "boat",
                        state = true,
                        boutique = true,
                        garage = true,
                    }
                    exports["null-core"]:EditCacheData("owned_vehicles", oldCacheData)
                end
            end
        end,
        ["weapon"] = function(_s, license, player)
            local identifier = GetIdentifiers(source);
            if (identifier['fivem']) then
                local find = false
                for k,v in pairs(xPlayer.getLoadout()) do
                    if v.name == result then
                        find = true 
                        break
                    end
                end
                if find then
                    xPlayer.showNotification('Vous avez déjà l\'arme\nLa caisses a était rembourser')
                    xPlayer.addInventoryItem(type, 1)
                else
                    xPlayer.addWeapon(result, 250)
                end 
            end
        end,
        ["money"] = function(_s, license, player)
            local quantity = tonumber(after)
            for k,v in pairs(Config.Boutique.Crates.List[type].Inside) do
                if v.typeLot == "money" then
                    if v.model == result then
                        xPlayer.addAccountMoney('bank', v.amount)
                    end
                end
            end
        end,
        ["Coins"] = function(_s, license, player)
            local quantity = tonumber(after)
            LiteMySQL:Insert('tebex_players_wallet', {
                identifiers = after,
                idunique = xPlayer.getIdunique(),
                transaction = 'Gain de coins caisse',
                price = 0,
                currency = 'Points',
                points = null,
            });
        end,
    }

    local r = nil
    for k,v in pairs(Config.Boutique.Crates.List[type].Inside) do
        if v.model == result then
            r = v
            r.message = "Vous avez gagner un(e) "..v.label
            break
        end
    end
    if giveReward[r.typeLot] ~= nil then
        giveReward[r.typeLot](source, identifier['license'], xPlayer);
    end

    LiteMySQL:Insert('tebex_players_wallet', {
        identifiers = after,
        idunique = xPlayer.getIdunique(),
        transaction = "Ouverture de "..Config.Boutique.Crates.List[type].label.." : "..r.message,
        price = '0',
        currency = 'Box',
        points = 0,
    }); 
    TriggerClientEvent('sBoutique:sCaisseOpenC', source, lists, result, r.message, type)
    sendToCaisses('SBoutique - LOGS', '[PACK-Boutique] \n' ..GetPlayerName(source).. ' viens d\'ouvrir la Caisse Mystère : ' ..type.. '\nGagné : ' ..result.. '', 3124441)

end

function sendToCaisses (name,message,color)
	date_local1 = os.date('%H:%M:%S', os.time())
	local date_local = date_local1
	local DiscordWebHook = Config.Logs["boutique_caisse"]
    local embeds = {  
        {

            ["title"] = message,
            ["type"] = "rich",
            ["color"] = color,
            ["footer"] =  {
            ["text"] = "Heure: " ..date_local.. "",
		},
	}
}

	if message == nil or message == '' then return FALSE end
	PerformHttpRequest(DiscordWebHook, function(err, text, headers) end, 'POST', json.encode({ username = name,embeds = embeds}), { ['Content-Type'] = 'application/json' })
end 


for k,v in pairs(Config.Boutique.Crates.List) do
    ESX.RegisterUsableItem(k, function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        TriggerClientEvent("null:inventory:closeinv", source)
        OpenCaisse(source, k)
        xPlayer.removeInventoryItem(k, 1)
    end)
end



RegisterServerEvent('sBoutique:process_checkout_case')
AddEventHandler('sBoutique:process_checkout_case', function(type, nbr)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = GetIdentifiers(source);
    if identifier['fivem'] == nil then return end
    if Config.Boutique.Crates.List[type] == nil then return end
    local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
    if Config.Boutique.Crates.List[type].buyable == false then return end
    if Config.Boutique.Crates.List[type].price == -1 then return end
    local fprice = Config.Boutique.Crates.List[type].price
    if nbr == 5 then
        fprice = Config.Boutique.Crates.List[type].five
    elseif nbr == 10 then
        fprice = Config.Boutique.Crates.List[type].teen
    end

    OnProcessCheckout(source, fprice, "Achat d'une caisse ("..Config.Boutique.Crates.List[type].label..")", function()
        if (identifier['fivem']) then
            xPlayer.addInventoryItem(type, nbr)
        end
        --sendToCaisses('LOGS', '[PACK-Boutique] \n' ..GetPlayerName(source).. ' viens d\'acheter la Caisse Mystère : ' ..type.. '\n', 3124441)
        end, function()
        xPlayer.showNotification("Vous ne posséder pas les points nécessaires")
    end)
end)

-- Nouvel événement pour ouvrir une caisse directement depuis la boutique avec animation
RegisterServerEvent('sBoutique:openCaseWithAnimation')
AddEventHandler('sBoutique:openCaseWithAnimation', function(caseId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = GetIdentifiers(source)
    
    if not xPlayer then return end
    if not identifier['fivem'] then return end
    if not Config.Boutique.Crates.List[caseId] then return end
    
    local caseData = Config.Boutique.Crates.List[caseId]
    local fprice = caseData.price
    
    -- Vérifier et débiter les coins
    OnProcessCheckout(source, fprice, "Ouverture de caisse ("..caseData.label..")", function()
        -- Générer le loot
        local boxId = 1
        local box = {[1]={}, [2]={}, [3]={}, [4]={}}
        
        -- Organiser les items par rareté
        for k, v in pairs(caseData.Inside) do
            if v.rarity == 1 then
                table.insert(box[1], v)
            elseif v.rarity == 2 then
                table.insert(box[2], v)
            elseif v.rarity == 3 then
                table.insert(box[3], v)
            elseif v.rarity == 4 then
                table.insert(box[4], v)
            end
        end
        
        -- Générer le résultat
        local lists, wonItemName, null = GenerateLootbox(source, boxId, box)
        
        -- Trouver les données complètes de l'item gagné
        local wonItemData = nil
        local wonRarity = 1
        for itemName, itemData in pairs(caseData.Inside) do
            if itemData.model == wonItemName then
                wonItemData = itemData
                wonRarity = itemData.rarity or 1
                break
            end
        end
        
        -- Préparer la liste de tous les items possibles pour l'animation
        local allItems = {}
        for itemName, itemData in pairs(caseData.Inside) do
            table.insert(allItems, {
                id = itemData.model,
                label = itemData.label or itemData.model,
                image = "images/items/"..itemData.model..".webp",
                rarity = itemData.rarity or 1
            })
        end
        
        -- Préparer l'item gagné pour l'UI
        local wonItem = {
            id = wonItemName,
            label = wonItemData and wonItemData.label or wonItemName,
            image = "images/items/"..wonItemName..".webp",
            rarity = wonRarity
        }
        
        -- Donner la récompense au joueur (utilise la logique existante)
        if wonItemData then
            local giveReward = {
                ["vehicle"] = function()
                    -- Logique véhicule existante
                    local HashVeh = GetHashKey(wonItemName)
                    local found = false
                    local PlateExist = true
                    local newplate = nil
                    local oldCacheData = exports["null-core"]:GetCacheData("owned_vehicles")
                    while PlateExist do
                        newplate = null.fct.format.randomPlateText()
                        if oldCacheData[string.upper(newplate)] == nil then
                            PlateExist = false
                        end
                        Wait(100)
                    end
                    for k,v in pairs(oldCacheData) do 
                        if v.owner == xPlayer.identifier then
                            if v.model == wonItemName then
                                xPlayer.showNotification('Vous avez déjà le véhicule')
                                found = true
                                break
                            end
                        end
                    end
                    if not found then
                        oldCacheData[string.upper(newplate)] = {
                            owner = xPlayer.identifier,
                            plate = string.upper(newplate),
                            model = wonItemName,
                            label = wonItemName,
                            vehicle = { model = HashVeh, plate = newplate },
                            coffre = {},
                            type = "car",
                            state = true,
                            boutique = true,
                            garage = true,
                        }
                        exports["null-core"]:EditCacheData("owned_vehicles", oldCacheData)
                    end
                end,
                ["item"] = function()
                    xPlayer.addInventoryItem(wonItemName, null or 1)
                end,
                ["weapon"] = function()
                    xPlayer.addWeapon(wonItemName, 250)
                end,
                ["money"] = function()
                    xPlayer.addAccountMoney('cash', null or 0)
                end
            }
            
            local rewardType = wonItemData.typeLot or "item"
            if giveReward[rewardType] then
                giveReward[rewardType]()
            end
        end
        
        -- Envoyer l'animation au client
        TriggerClientEvent('boutique:startCaseSpin', source, {
            wonItem = wonItem,
            allItems = allItems
        })
        
        -- Mettre à jour les coins affichés
        TriggerClientEvent("null:boutique:newCoinsAmount", source)
        
    end, function()
        xPlayer.showNotification("~r~Vous n'avez pas assez de coins!")
        TriggerClientEvent('boutique:notification', source, {
            message = "~r~Vous n'avez pas assez de coins!"
        })
    end)
end)