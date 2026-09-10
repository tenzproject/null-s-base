function GetIdentifiers(source)
    if (source ~= nil) then
        local identifiers = {}
        local playerIdentifiers = GetPlayerIdentifiers(source)
        for _, v in pairs(playerIdentifiers) do
            local before, after = playerIdentifiers[_]:match("([^:]+):([^:]+)")
            identifiers[before] = playerIdentifiers[_]
        end
        return identifiers
    else
        error("source is nil")
    end
end


function getFidPoints(identifier)
    MySQL.Async.fetchAll("SELECT * FROM tebex_Null_fidelite WHERE license = @license", {
        ['@license'] = identifier
    }, function(result)
        local total = 0
        local havebuy = 0
        if result[1] ~= nil then
            total = result[1].totalbuy
            havebuy = result[1].havebuy
        end
        return {total, havebuy}
    end)
end

local function giveCaseFid(identifier, xPlayer)
    xPlayer.addInventoryItem("caisse_fidelite", 1)
    xPlayer.showNotification("✅ Vous avez reçu une caisse fidéliter.")
    LiteMySQL:Insert('tebex_players_wallet', {
        identifiers = identifier,
        idunique = xPlayer.getIdunique(),
        transaction = "Récompense fideliter",
        price = 0,
        currency = 'Points',
        points = 0,
    });
end

local function addFidPoints(identifier, nbr, xPlayer)
    MySQL.Async.fetchAll("SELECT * FROM tebex_Null_fidelite WHERE license = @license", {
        ['@license'] = identifier
    }, function(result)
        if result[1] ~= nil then
            local newtotal = result[1].totalbuy + nbr
            local newhavebuy = result[1].havebuy + nbr
            if newhavebuy >= 5000 then
                newhavebuy = newhavebuy - 5000
                giveCaseFid(identifier, xPlayer)
            end
            MySQL.Sync.execute("UPDATE tebex_Null_fidelite SET havebuy=@havebuy, totalbuy=@totalbuy WHERE license=@license", {
                ["@license"] = identifier,
                ["@havebuy"] = newhavebuy,
                ["@totalbuy"] = newtotal 
            })
        else
            local total = nbr
            local havebuy = nbr
            if nbr >= 5000 then
                havebuy = havebuy - 5000
                giveCaseFid(identifier, xPlayer)
            end
            LiteMySQL:Insert('tebex_Null_fidelite', {
                license = identifier,
                havebuy = havebuy,
                totalbuy = total
            }); 
        end
    end)
end

function getPoints(source)
    local identifier = GetIdentifiers(source);
    if (identifier['fivem']) then
        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
        local fidPoints = getFidPoints(after)
        MySQL.Async.fetchAll("SELECT * FROM tebex_Null_fidelite WHERE license = @license", {
            ['@license'] = after
        }, function(result)
            local havebuy = 0
            if result[1] ~= nil then
                havebuy = result[1].havebuy
            end
            MySQL.Async.fetchAll("SELECT SUM(points) FROM tebex_players_wallet WHERE identifiers = @identifiers", {
                ['@identifiers'] = after
            }, function(result)
                if (result[1]["SUM(points)"] ~= nil) then
                    return result[1]["SUM(points)"]
                else
                    return 0
                end
            end);
        end)
    else
        return 0
    end
end

ESX.RegisterServerCallback('sBoutique:getPoints', function(source, cb)
    if not cb then return end
    local identifier = GetIdentifiers(source);
    if (identifier['fivem']) then
        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
        local fidPoints = getFidPoints(after)
        MySQL.Async.fetchAll("SELECT * FROM tebex_Null_fidelite WHERE license = @license", {
            ['@license'] = after
        }, function(fidResult)
            local havebuy = 0
            if fidResult[1] ~= nil then
                havebuy = fidResult[1].havebuy
            end
            MySQL.Async.fetchAll("SELECT SUM(points) FROM tebex_players_wallet WHERE identifiers = @identifiers", {
                ['@identifiers'] = after
            }, function(pointsResult)
                if cb then
                    if (pointsResult[1] and pointsResult[1]["SUM(points)"] ~= nil) then
                        cb(pointsResult[1]["SUM(points)"], havebuy)
                    else
                        cb(0, 0)
                    end
                end
            end);
        end)
    else
        if cb then cb(0, 0) end
    end
end)

--[[ESX.RegisterServerCallback('Null:getFidPoints', function(source, callback)
    local identifier = GetIdentifiers(source);
    if (identifier['fivem']) then
        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
        MySQL.Async.fetchAll("SELECT * FROM tebex_players_wallet WHERE identifiers = @identifiers", {
            ['@identifiers'] = after
        }, function(result)
            if result[1] == nil then callback({}, 0) end
            local total, totaldeja = 0, 0
            for k,v in pairs(result) do
                if v.points > 0 then
                    total = total + v.points
                elseif v.points == 0 then 
                    if v.transaction == "Récuperation Fideliter" then 
                        total = total - 5000
                    elseif v.transaction == "Rembourssement Fideliter" then
                        total = total + 5000
                    end
                else
                    if v.transaction == "Retrait de Coins via la console" then
                        total = total + v.points
                    end
                end
            end
            local totaltemp = total 
            local inventory = {}
            while totaltemp >= 5000 do
                table.insert(inventory, {name = "caisse_fidelite",label = "Caisse fidéliter",price = 5000,})
                totaltemp = totaltemp - 5000
                Wait(100)
            end
            callback(inventory, total)
        end);
    else
        callback({}, 0)
    end
end)]]

ESX.RegisterServerCallback('sBoutique:getIdboutique', function(source, callback)
    local identifier = GetIdentifiers(source);
    if (identifier['fivem']) then
        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")

        callback(after)
    else
        callback(0)
    end
end)


function OnProcessCheckout(source, price, transaction, onAccepted, onRefused)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = GetIdentifiers(source);
    if (identifier['fivem']) then
        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
        MySQL.Async.fetchAll("SELECT SUM(points) FROM tebex_players_wallet WHERE identifiers = @identifiers", {
            ['@identifiers'] = after
        }, function(result)
            local current = tonumber(result[1]["SUM(points)"]);
            if (current ~= nil) then
                if (current >= price) then
                    addFidPoints(after, price, xPlayer)
                    LiteMySQL:Insert('tebex_players_wallet', {
                        identifiers = after,
                        idunique = xPlayer.getIdunique(),
                        transaction = transaction,
                        price = 0,
                        currency = 'Points',
                        points = -price,
                    });
                    TriggerClientEvent("null:boutique:newCoinsAmount", source, getPoints(source))
                    Wait(1000)
                    MySQL.Async.fetchAll("SELECT * FROM tebex_Null_fidelite WHERE license = @license", {
                        ['@license'] = after
                    }, function(result)
                        local havebuy = 0
                        if result[1] ~= nil then
                            havebuy = result[1].havebuy
                        end
                        xPlayer.showNotification("Votre Achat à été effectuer\nPrix : "..ESX.Config("serverColor")..price.."~s~\nCode Boutique : "..ESX.Config("serverColor")..after.."~s~\nPoints Fidélité : "..ESX.Config("serverColor")..havebuy.."~s~/"..ESX.Config("serverColor").."5000~s~")
                    end)
                    onAccepted();
                else
                    onRefused();
                    xPlayer.showNotification('Vous ne procédez pas les points nécessaires pour votre achat visité notre boutique.')
                end
            else
                onRefused();
            end
        end);
    else
        onRefused();
    end
end

exports("OnProcessCheckout", OnProcessCheckout)

local characters = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" }

function CreateRandomPlateText()
    local plate = ""
    math.randomseed(GetGameTimer())
    for i = 1, 4 do
        plate = plate .. characters[math.random(1, #characters)]
    end
    plate = plate .. ""
    for i = 1, 3 do
        plate = plate .. math.random(1, 9)
    end
    return plate
end

RegisterServerEvent('NullBoutique:buycoins')
AddEventHandler('NullBoutique:buycoins', function(coins, cost)
    local xPlayer = ESX.GetPlayerFromId(source)

    if (xPlayer) then 
        if xPlayer.getAccount('fidelcoins').money >= cost then 
            local identifier = GetIdentifiers(source);
            if (identifier['fivem']) then
                local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
                xPlayer.removeAccountMoney('fidelcoins', cost)
                LiteMySQL:Insert('tebex_players_wallet', {
                    identifiers = after,
                    idunique = xPlayer.getIdunique(),
                    transaction = 'Ajout de coins grace a la boutique fidéliter',
                    price = 0,
                    currency = 'Points',
                    points = coins,
                });
                TriggerClientEvent("null:boutique:newCoinsAmount", source, getPoints(source))
                xPlayer.showNotification('Vous avez reçu ~b~'..coins.. ' ~s~Coins')
            else
                xPlayer.showNotification('Le joueur n\'as aucun compte FiveM lier')
            end
        else
            xPlayer.showNotification("Vous n'avez pas assez de points de fidélité")
        end
    end
end)

RegisterServerEvent('BoutiqueBucket:SetEntitySourceBucket')
AddEventHandler('BoutiqueBucket:SetEntitySourceBucket', function(valeur)
    if valeur then
        exports["null-core"]:SetInInstance(source, source+1, "Boutique")
    else
        exports["null-core"]:SetInInstance(source, 0)
    end
end)

RegisterCommand('addPointsIdBoutique', function(source, args)
    local xPlayer = nil
    local name = "Inconnu"
    if source == 0 then
        name = "Console"
    else
        xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getGroup() ~= "fondateur" then
            return
        end
        name = xPlayer.getName().." (U"..xPlayer.getIdunique()..")"
    end
    if args[1] ~= nil and args[2] ~= nil then
        MySQL.Async.fetchAll("SELECT * FROM tebex_players_wallet WHERE identifiers = @identifiers", {
            ['@identifiers'] = tonumber(args[1])
        }, function(result)
            if result[1] == nil then
                print("Tebex: id boutique incorrect ("..args[1]..")")
            else
                LiteMySQL:Insert('tebex_players_wallet', {
                    identifiers = tonumber(args[1]),
                    idunique = result[1].idunique,
                    transaction = 'Ajout de Coins par '..name,
                    price = 0,
                    currency = 'Points',
                    points = args[2],
                })
            end
        end)
    end
end)

RegisterCommand('addPoints', function(source, args)
    if source == 0 then
        local xPlayer = ESX.GetPlayerFromId(args[1])
        local identifier = GetIdentifiers(args[1]);
        if (identifier['fivem']) then
            local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
            LiteMySQL:Insert('tebex_players_wallet', {
                identifiers = after,
                idunique = xPlayer.getIdunique(),
                transaction = 'Achat de Coins',
                price = 0,
                currency = 'Points',
                points = args[2],
            });
            TriggerClientEvent("null:boutique:newCoinsAmount", args[1], getPoints(args[1]))
        else
            print('LE JOUEUR N\'A LIER AUCUN COMPTE FIVEM')
        end
    else
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getGroup() == "fondateur" then
            local Target = ESX.GetPlayerFromId(args[1])
            local identifier = GetIdentifiers(args[1]);
            if (identifier['fivem']) then
                local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
                LiteMySQL:Insert('tebex_players_wallet', {
                    identifiers = after,
                    idunique = Target.getIdunique(),
                    transaction = 'Ajout de Coins par '..GetPlayerName(source),
                    price = 0,
                    currency = 'Points',
                    points = args[2],
                });
                TriggerClientEvent("null:boutique:newCoinsAmount", args[1], getPoints(args[1]))
                Target.showNotification('Vous avez reçu ~b~'..args[2].. ' ~s~Coins')
            else
                xPlayer.showNotification('Le joueur n\'as aucun compte FiveM lier')
            end
        end
    end
end)

RegisterCommand('removePoints', function(source, args)
    if source == 0 then
        local xPlayer = ESX.GetPlayerFromId(args[1])
        local identifier = GetIdentifiers(args[1]);
        if (identifier['fivem']) then
            local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
            LiteMySQL:Insert('tebex_players_wallet', {
                identifiers = after,
                idunique = xPlayer.getIdunique(),
                transaction = 'Retrait de Coins via la console',
                price = 0,
                currency = 'Points',
                points = '-'..args[2],
            });
            TriggerClientEvent("null:boutique:newCoinsAmount", args[1], getPoints(args[1]))
        else
            print('LE JOUEUR N\'A LIER AUCUN COMPTE FIVEM')
        end
    else
        local xPlayer = ESX.GetPlayerFromId(source)

        if xPlayer.getGroup() == "fondateur" then
            local Target = ESX.GetPlayerFromId(args[1])
            local identifier = GetIdentifiers(args[1]);
            if (identifier['fivem']) then
                local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
                LiteMySQL:Insert('tebex_players_wallet', {
                    identifiers = after,
                    idunique = Target.Coins(),
                    transaction = 'Retrait de Coinss par '..GetPlayerName(source),
                    price = 0,
                    currency = 'Points',
                    points = '-'..args[2],
                });
                TriggerClientEvent("null:boutique:newCoinsAmount", args[1], getPoints(args[1]))
                Target.showNotification('Vous avez perdu ~b~'..args[2].. ' ~s~Coins')
            else
                xPlayer.showNotification('Le joueur n\'as aucun compte FiveM lier')
            end
        end
    end
end)



RegisterCommand("addPointsAll", function(source, args, user)
	local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if args[1] == nil then return end
    if tonumber(args[1]) < 0 then return end
    if xPlayer.getPermission("GESTION_BOUTIQUE") then
	    local AllPlayers = ESX.GetPlayers()
        for i = 1, #AllPlayers, 1 do
            if AllPlayers[i] then
                local xPlayersAll = ESX.GetPlayerFromId(AllPlayers[i])
                if xPlayersAll then
                    ExecuteCommand("addPoints "..AllPlayers[i].." "..tonumber(args[1]))
                    TriggerClientEvent("null:boutique:newCoinsAmount", AllPlayers[i], getPoints(AllPlayers[i]))
                    TriggerClientEvent("esx:showNotification", xPlayersAll.source, ESX.Config("serverColor").."Boutique~s~\nNous te remercions pour ta présence ! vous avez reçu "..args[1].." coins.")
                end
            end
        end
    end
    xPlayer.showNotification('Vous avez ajouté '..args[1]..' coins à tous les joueurs')
end, false)

RegisterCommand("addVIPAll", function(source, args, user)
	local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if args[1] == nil then return end
    if tonumber(args[1]) < 0 then return end
    if xPlayer.getPermission("GESTION_BOUTIQUE") then
	    local AllPlayers = ESX.GetPlayers()
        for i = 1, #AllPlayers, 1 do
            if AllPlayers[i] then
                local xPlayersAll = ESX.GetPlayerFromId(AllPlayers[i])
                if xPlayersAll then
                    ExecuteCommand("addVIP "..AllPlayers[i].." Basic "..tonumber(args[1]))
                    TriggerClientEvent("esx:showNotification", xPlayersAll.source, ESX.Config("serverColor").."Boutique~s~\n-Nous te remercions pour ta présence ! vous avez reçu un VIP de "..args[1].."J.")
                end
            end
        end
    end
    xPlayer.showNotification('Vous avez ajouté '..args[1]..'J de VIP Basic à tous les joueurs')
end, false)

RegisterServerEvent('null:server:BuyPack')
AddEventHandler('null:server:BuyPack', function(type)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = GetIdentifiers(source)
    if xPlayer ~= nil then 
        if Config.Boutique.Packs[type] ~= nil then
            if (identifier['fivem']) then
                local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
                MySQL.Async.fetchAll("SELECT SUM(points) FROM tebex_players_wallet WHERE identifiers = @identifiers", {
                    ['@identifiers'] = after
                }, function(result)
                    local current = tonumber(result[1]["SUM(points)"]);
                    if (current ~= nil) then
                        if (current >= Config.Boutique.Packs[type].price) then
                            if type == "Basic" or type == "Premium" then
                                MySQL.Async.fetchAll("SELECT * FROM vips WHERE identifier=@identifier",{
                                    ['@identifier'] = xPlayer.identifier,
                                }, function(data) 
                                    if data[1] then
                                        xPlayer.showNotification("Vous avez déjà le vip.")
                                        return
                                    else
                                        addFidPoints(after, Config.Boutique.Packs[type].price, xPlayer)
                                        LiteMySQL:Insert('tebex_players_wallet', {
                                            identifiers = after,
                                            idunique = xPlayer.getIdunique(),
                                            transaction = "Achat du pack "..type,
                                            price = 0,
                                            currency = 'Points',
                                            points = -Config.Boutique.Packs[type].price,
                                        });
                                        TriggerClientEvent("null:boutique:newCoinsAmount", xPlayer.source, getPoints(xPlayer.source))
                                        local expiration = (31 * 86400)
                                        if expiration < os.time() then
                                            expiration = os.time() + expiration
                                        end
                                        MySQL.Async.execute('INSERT INTO vips (identifier, vip, expiration, type) VALUES (@identifier, @vip, @expiration, @type)', {
                                            ['@identifier'] = xPlayer.identifier,
                                            ['@vip'] = 1,
                                            ['@expiration'] = expiration,
                                            ['@type'] = type,
                                        })
                                        xPlayer.showNotification('Information ~s~\nVous venez d\'obtenir un VIP')
                                        exports["null-core"]:GetVIP(xPlayer.identifier)
                                        TriggerClientEvent('NullupdateVIP', xPlayer.source, true)
                                    end
                                end)
                            else
                                MySQL.Async.fetchAll("SELECT * FROM tebex_players_wallet WHERE (`transaction` LIKE @transaction AND `identifiers` = @identifiers) ", {
                                    ['@identifiers'] = after,
                                    ['@transaction'] = "Achat du pack "..type
                                }, function(result)
                                    if result[1] then
                                        xPlayer.showNotification("Vous avez déjà ce pack.")
                                    else
                                        addFidPoints(after, Config.Boutique.Packs[type].price, xPlayer)
                                        LiteMySQL:Insert('tebex_players_wallet', {
                                            identifiers = after,
                                            idunique = xPlayer.getIdunique(),
                                            transaction = "Achat du pack "..type,
                                            price = 0,
                                            currency = 'Points',
                                            points = -Config.Boutique.Packs[type].price,
                                        });
                                        TriggerClientEvent("null:boutique:newCoinsAmount", xPlayer.source, getPoints(xPlayer.source))
                                        xPlayer.showNotification("Vous avez acheter le pack "..type)
                                    end
                                end)  
                            end
                        else
                            xPlayer.showNotification("Vous n'avez pas les coins nécessaire.")
                        end
                    end
                end)
            end
        end
    end
end)


ESX.RegisterServerCallback('sBoutique:getHistory', function(source, callback)
    local identifier = GetIdentifiers(source);
    if (identifier['fivem']) then
        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
        local count, result = LiteMySQL:Select('tebex_players_wallet'):Where('identifiers', '=', after):Get();
        if (result ~= nil) then
            callback(result)
        else
            print('[Exceptions] retrieve category is nil')
            callback({ })
        end
    end
end)

RegisterCommand('history', function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        if args[1] ~= nil then
            openHistory(source, args[1])
        else
            xPlayer.showNotification('Vous devez mettre une ID')
        end
    end
end)

function openHistory(source, player)
    local xPlayer = ESX.GetPlayerFromId(source)
    local identifier = GetIdentifiers(player);
    if (identifier['fivem']) then
        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
        local count, result = LiteMySQL:Select('tebex_players_wallet'):Where('identifiers', '=', after):Get();
        if (result ~= nil) then
            TriggerClientEvent('sBoutique:retrieveHistoryClient', source, result)
        else
            xPlayer.showNotification('Cette personne n\'a pas de FiveM lier')
        end
    end
end