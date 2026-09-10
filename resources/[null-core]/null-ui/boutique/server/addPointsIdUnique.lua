RegisterCommand('addPointsIdUnique', function(source, args)
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
    
    if args[1] == nil or args[2] == nil then
        if source ~= 0 then
            xPlayer.showNotification("~r~Usage: /addPointsIdUnique [ID Unique] [Nombre de coins]")
        else
            print("Usage: addPointsIdUnique [ID Unique] [Nombre de coins]")
        end
        return
    end
    
    local targetIdUnique = tonumber(args[1])
    local pointsToAdd = tonumber(args[2])
    
    if not targetIdUnique or not pointsToAdd then
        if source ~= 0 then
            xPlayer.showNotification("~r~ID Unique et nombre de coins doivent être des nombres")
        else
            print("ID Unique et nombre de coins doivent être des nombres")
        end
        return
    end
    
    local xTarget = ESX.GetPlayerFromIdUnique(targetIdUnique)
    
    if xTarget then
        local identifier = GetIdentifiers(xTarget.source)
        
        if not identifier['fivem'] then
            if source ~= 0 then
                xPlayer.showNotification("~r~Le joueur n'a aucun compte FiveM lié")
            else
                print("Le joueur (U"..targetIdUnique..") n'a aucun compte FiveM lié")
            end
            return
        end
        
        local before, after = identifier['fivem']:match("([^:]+):([^:]+)")
        
        LiteMySQL:Insert('tebex_players_wallet', {
            identifiers = after,
            idunique = xTarget.getIdunique(),
            transaction = 'Ajout de Coins par '..name,
            price = 0,
            currency = 'Points',
            points = pointsToAdd,
        })
        
        TriggerClientEvent("null:boutique:newCoinsAmount", xTarget.source, getPoints(xTarget.source))
        
        xTarget.showNotification('Vous avez reçu ~b~'..pointsToAdd.. ' ~s~Coins')
        
        if source ~= 0 then
            xPlayer.showNotification("~g~"..pointsToAdd.." coins donnés à "..xTarget.getName().." (U"..targetIdUnique..") [EN LIGNE]")
        else
            print("["..os.date("%X").."] "..pointsToAdd.." coins donnés à "..xTarget.getName().." (U"..targetIdUnique..") [EN LIGNE]")
        end
        
        print("^2[BOUTIQUE]^7 "..name.." a donné "..pointsToAdd.." coins à "..xTarget.getName().." (U"..targetIdUnique..") [EN LIGNE]")
    else
        MySQL.Async.fetchAll("SELECT firstname, lastname, fivem FROM users WHERE idunique = @idunique", {
            ['@idunique'] = targetIdUnique
        }, function(result)
            if not result or not result[1] then
                if source ~= 0 then
                    xPlayer.showNotification("~r~Aucun joueur trouvé avec l'ID Unique: "..targetIdUnique)
                else
                    print("Aucun joueur trouvé avec l'ID Unique: "..targetIdUnique)
                end
                return
            end
            
            local targetData = result[1]
            local targetName = targetData.firstname.." "..targetData.lastname
            local fivemId = targetData.fivem
            
            if not fivemId or fivemId == "" or fivemId == "-1" then
                if source ~= 0 then
                    xPlayer.showNotification("~r~Le joueur n'a aucun compte FiveM lié")
                else
                    print("Le joueur (U"..targetIdUnique..") n'a aucun compte FiveM lié")
                end
                return
            end
            
            LiteMySQL:Insert('tebex_players_wallet', {
                identifiers = fivemId,
                idunique = targetIdUnique,
                transaction = 'Ajout de Coins par '..name,
                price = 0,
                currency = 'Points',
                points = pointsToAdd,
            })
            
            if source ~= 0 then
                xPlayer.showNotification("~g~"..pointsToAdd.." coins donnés à "..targetName.." (U"..targetIdUnique..") [HORS LIGNE]")
            else
                print("["..os.date("%X").."] "..pointsToAdd.." coins donnés à "..targetName.." (U"..targetIdUnique..") [HORS LIGNE]")
            end
            
            print("^2[BOUTIQUE]^7 "..name.." a donné "..pointsToAdd.." coins à "..targetName.." (U"..targetIdUnique..") [HORS LIGNE]")
        end)
    end
end)
