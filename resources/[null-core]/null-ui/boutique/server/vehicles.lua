RegisterServerEvent('sBoutique:BuyVehicle')
AddEventHandler('sBoutique:BuyVehicle', function(model, price, label)
    local _src = source
    local identifier = GetIdentifiers(_src)
    local xPlayer = ESX.GetPlayerFromId(_src)
    if (identifier['fivem']) then
        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
        MySQL.Async.fetchAll("SELECT * FROM tebex_players_wallet WHERE (`transaction` LIKE @transaction AND `identifiers` = @identifiers) ", {
            ['@identifiers'] = after,
            ['@transaction'] = "%"..label.."%"
        }, function(resultVeh)
            if resultVeh[1] then
                return xPlayer.showNotification('Vous avez déjà le véhicule')
            else
                local BoutiqueVehicle = nil
                local found = false
                for k,v in pairs(Config.Boutique.Vehicles) do 
                    if v.model == model then
                        BoutiqueVehicle = v
                        found = true
                    end
                end
                if not found then return end
                OnProcessCheckout(_src, BoutiqueVehicle.price, string.format("Achat de : %s", label), function()
                    local newplate = nil

                    local oldCacheData = exports["null-core"]:GetCacheData("owned_vehicles")
                    local PlateExist = true
                    while PlateExist do
                        newplate = CreateRandomPlateText()
                        if oldCacheData[string.upper(newplate)] == nil then
                            PlateExist = false
                        end
                        Wait(100)
                    end

                    oldCacheData[string.upper(newplate)] = {
                        owner = xPlayer.identifier,
                        plate = string.upper(newplate),
                        model = model,
                        label = model,
                        vehicle = { model = GetHashKey(model), plate = newplate },
                        coffre = {},
                        type = "car",
                        state = true,
                        boutique = true,
                        garage = true,
                    }
                    exports["null-core"]:EditCacheData("owned_vehicles", oldCacheData)

                    xPlayer.showNotification("Vous avez acheter : " .. label .. " sur la boutique !")
                    sendtoVehicule('Coins - LOGS', GetPlayerName(_src).. '\nViens d\'acheter un véhicule\nVéhicule : ' ..BoutiqueVehicle.model..'\nPrix : ' ..BoutiqueVehicle.price.. '', 3124441)
                end, function()
                    --xPlayer.showNotification("Vous ne posséder pas les points nécessaires")
                    return
                end)
            end
        end)  
    end
end)

RegisterCommand('givevehicule', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local Player = ESX.GetPlayerFromId(args[1])


    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        local oldCacheData = exports["null-core"]:GetCacheData("owned_vehicles")
        local PlateExist = true
        while PlateExist do
            newplate = CreateRandomPlateText()
            if oldCacheData[string.upper(newplate)] == nil then
                PlateExist = false
            end
            Wait(100)
        end

        oldCacheData[string.upper(newplate)] = {
            owner = Player.identifier,
            plate = string.upper(newplate),
            model = args[2],
            label = args[2],
            vehicle = { model = GetHashKey(args[2]), plate = newplate },
            coffre = {},
            type = args[3],
            state = true,
            boutique = true,
            garage = true,
        }
        exports["null-core"]:EditCacheData("owned_vehicles", oldCacheData)
        xPlayer.showNotification("~g~Give avec succés")
    end
end)

--[[Citizen.CreateThread(function()
    while true do
        Wait(30000)
        local allPlayers = GetPlayers()

        for i=1, #allPlayers, 1 do
            ESX.ChatMessage(allPlayers[i], '💝 N\'hésitez pas a faire un tour sur notre magnifique boutique ( F1 ) 💝.', ESX.Config("serverName"), { ESX.Config("r"), ESX.Config("g"), ESX.Config("b") })
        end
        Wait(30*60*1000)
    end
end)]]

function sendtoVehicule (name,message,color)
	date_local1 = os.date('%H:%M:%S', os.time())
	local date_local = date_local1
	local DiscordWebHook = Config.Logs["boutique_vehicle"]
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