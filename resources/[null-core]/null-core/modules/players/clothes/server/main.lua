local vBlWords = {
    "LOAD"
}


Citizen.CreateThread(function()
    MySQL.Async.fetchAll("SELECT * FROM vclothes ", {}, function(result)
        for k, v in pairs(result) do
            if not null.players.clothes[v.identifier] then 
                null.players.clothes[v.identifier] = {}
            end
            if not null.players.clothes[v.identifier][v.id] then
                null.players.clothes[v.identifier][v.id] = {}
            end 
            null.players.clothes[v.identifier][v.id].identifier = v.identifier
            null.players.clothes[v.identifier][v.id].label = v.name 
            null.players.clothes[v.identifier][v.id].skin = v.data
            null.players.clothes[v.identifier][v.id].type = v.type
            null.players.clothes[v.identifier][v.id].equip = false
            null.players.clothes[v.identifier][v.id].id = v.id
        end
        TriggerEvent("null:core:recevieload:ClothesCount", #result)
        --Wait(10000)
        --print('[^4LOAD^0] [^4'..#result..'^0] Tenues ont été load avec succès')
    end)
end)


RegisterNetEvent("Null:addtenueitem", function(label, skin)
    --[[local NumberCount = 0
    local xPlayer = ESX.GetPlayerFromId(source)
    local NumberTenueAutorized = GetVIP(xPlayer.source) == true and 9999 or GetVIP(xPlayer.source) == 1 and 9999 or 9999
    if not null.players.clothes[xPlayer.identifier] then
        NumberCount = 0
    else
        NumberCount = 0
    end

    if NumberCount+1 > NumberTenueAutorized then 
        xPlayer.showNotification('Vous avez déjà trop de tenue.')
    else
        local Account = xPlayer.getAccount('cash').money >= 750 and 'money' or xPlayer.getAccount('bank').money >= 750 and 'bank' or 'nomoney'
        if Account == 'nomoney' then
            xPlayer.showNotification('Vous n\'avez pas assez d\'argent sur vous')
        else
            xPlayer.removeAccountMoney(Account, 750)
            local IdTenue = math.random(11111,99999)
            local IdTenue2 = math.random(11111,99999)
            local ValidateID = IdTenue+IdTenue2

            if not null.players.clothes[xPlayer.identifier][ValidateID] then
                null.players.clothes[xPlayer.identifier][ValidateID] = {}
                null.players.clothes[xPlayer.identifier][ValidateID].identifier = xPlayer.identifier
                null.players.clothes[xPlayer.identifier][ValidateID].label = label
                null.players.clothes[xPlayer.identifier][ValidateID].type = "vetement"
                null.players.clothes[xPlayer.identifier][ValidateID].equip = "n"
                null.players.clothes[xPlayer.identifier][ValidateID].skin = json.encode(skin)
                null.players.clothes[xPlayer.identifier][ValidateID].id = ValidateID
            end
            MySQL.Async.execute("INSERT INTO vclothes (label, skin, type, identifier) VALUES (@label, @skin, @type, @identifier)", {
                ["@label"] = tostring(label),
                ["@skin"] = json.encode(skin),
                ["@type"] = "vetement",
                ["@identifier"] = xPlayer.identifier 
            })
            xPlayer.showNotification('Vous avez crée une tenue (~g~'..label..'~s~)')
            TriggerClientEvent("Null:recieveclientsidevetement", xPlayer.source, null.players.clothes[xPlayer.identifier])
        end
    end]]
end)

RegisterNetEvent("Null:paidaccesoires", function(type, name, skin)
    --[[local xPlayer = ESX.GetPlayerFromId(source)
    local IdTenue = math.random(11111,99999)
    local IdTenue2 = math.random(11111,99999)
    local ValidateID = IdTenue+IdTenue2

    if xPlayer.getAccount('cash').money >= 300 then 
        xPlayer.removeAccountMoney('cash', 300)
        if not null.players.clothes[xPlayer.identifier][ValidateID] then
            null.players.clothes[xPlayer.identifier][ValidateID] = {}
            null.players.clothes[xPlayer.identifier][ValidateID].identifier = xPlayer.identifier
            null.players.clothes[xPlayer.identifier][ValidateID].label = name
            null.players.clothes[xPlayer.identifier][ValidateID].type = type
            null.players.clothes[xPlayer.identifier][ValidateID].skin = json.encode(skin)
            null.players.clothes[xPlayer.identifier][ValidateID].id = ValidateID
        end
        MySQL.Async.execute("INSERT INTO vclothes (label, skin, type, identifier) VALUES (@label, @skin, @type, @identifier)", {
            ["@label"] = tostring(name),
            ["@skin"] = json.encode(skin),
            ["@type"] = type,
            ["@identifier"] = xPlayer.identifier 
        })
        
        TriggerClientEvent("Null:recieveclientsidevetement", xPlayer.source, null.players.clothes[xPlayer.identifier])
        xPlayer.showNotification("Vous venez d'acheter un "..type.."")
    else
        xPlayer.showNotification("Vous n'avez pas les fonds nécéssaires")
    end]]
end)

RegisterNetEvent('Null:donnertenue', function(player, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    local tPlayer = ESX.GetPlayerFromId(player)

    if tPlayer ~= nil then
        if null.players.clothes[xPlayer.identifier][id] then
            null.players.clothes[tPlayer.identifier][id] = {}
            null.players.clothes[tPlayer.identifier][id] = null.players.clothes[xPlayer.identifier][id]
            null.players.clothes[xPlayer.identifier][id] = nil
            TriggerClientEvent("Null:recieveclientsidevetement", xPlayer.source, null.players.clothes[xPlayer.identifier])
            TriggerClientEvent("Null:recieveclientsidevetement", tPlayer.source, null.players.clothes[tPlayer.identifier])
            xPlayer.showNotification(" Vous avez donné votre tenue ")
            tPlayer.showNotification(" Vous avez reçu une tenue ")
            MySQL.Async.execute("UPDATE vclothes set identifier = @identifier WHERE id = @id", {
                ["@identifier"] = tPlayer.identifier,
                ["@id"] = id
            })
            MySQL.Async.execute("DELETE FROM vclothes WHERE id = @id and identifier = @identifier", {
                ["@identifier"] = xPlayer.identifier,
                ["@id"] = id
            })
        end
    end
end)

RegisterNetEvent('Null:RenameTenue', function(id, NewLabel)
    local xPlayer = ESX.GetPlayerFromId(source)
    if null.players.clothes[xPlayer.identifier][id] then
        if null.players.clothes[xPlayer.identifier][id].identifier == xPlayer.identifier then
            xPlayer.showNotification('Vous avez renommer votre tenue (~g~'..null.players.clothes[xPlayer.identifier][id].label..'~s~)')
            null.players.clothes[xPlayer.identifier][id].label = NewLabel
            TriggerClientEvent("Null:recieveclientsidevetement", xPlayer.source, null.players.clothes[xPlayer.identifier])
            MySQL.Async.execute("UPDATE vclothes set name = @name WHERE id = @id", {
                ["@name"] = tostring(NewLabel),
                ["@id"] = id
            })
        else
            --ExecuteCommand("ban " .. source .. " 0 Tentative de triche vêtement (0)")
            return
        end
    end
end)

RegisterNetEvent('Null:deletetenue', function(id, NewLabel)
    local xPlayer = ESX.GetPlayerFromId(source)
    if null.players.clothes[xPlayer.identifier][id] then
        if null.players.clothes[xPlayer.identifier][id].identifier == xPlayer.identifier then
            xPlayer.showNotification('Vous avez supprimer votre tenue (~g~'..null.players.clothes[xPlayer.identifier][id].label..'~s~)')
            null.players.clothes[xPlayer.identifier][id] = nil
            TriggerClientEvent("Null:recieveclientsidevetement", xPlayer.source, null.players.clothes[xPlayer.identifier])
            MySQL.Async.execute("DELETE FROM vclothes WHERE id = @id", {
                ["@id"] = id
            })
        else
            --ExecuteCommand("ban " .. source .. " 0 Tentative de triche vêtement (1)")
            return
        end
    end
end)

RegisterNetEvent("Null:tenuegarderobe", function(typee, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if null.players.clothes[xPlayer.identifier][id] then
        if null.players.clothes[xPlayer.identifier][id].identifier == xPlayer.identifier then
            if typee == "equip" then 
                null.players.clothes[xPlayer.identifier][id].equip = "y"
                xPlayer.showNotification('Vous avez équiper votre tenue (~g~'..null.players.clothes[xPlayer.identifier][id].label..'~s~)')
                TriggerClientEvent("Null:recieveclientsidevetement", xPlayer.source, null.players.clothes[xPlayer.identifier])
                MySQL.Async.execute("UPDATE vclothes set equip = @equip WHERE id = @id", {
                    ["@id"] = id,
                    ["@equip"] = tostring("y")
                })
            elseif typee == "deposit" then 
                null.players.clothes[xPlayer.identifier][id].equip = "n"
                MySQL.Async.execute("UPDATE vclothes set equip = @equip WHERE id = @id", {
                    ["@id"] = id,
                    ["@equip"] = "n"
                })
                xPlayer.showNotification('Vous avez déposer votre tenue (~g~'..null.players.clothes[xPlayer.identifier][id].label..'~s~)')
                TriggerClientEvent("Null:recieveclientsidevetement", xPlayer.source, null.players.clothes[xPlayer.identifier])
            end
        else
            -- ExecuteCommand("ban " .. source .. " 0 Tentative de triche vêtement (2)")
        end
    end
end)

RegisterNetEvent("RecieveVetement", function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if (not xPlayer) then return end
    if not null.players.clothes[xPlayer.identifier] then 
        null.players.clothes[xPlayer.identifier] = {}
        TriggerClientEvent("Null:recieveclientsidevetement", xPlayer.source, nil)
    else
        TriggerClientEvent("Null:recieveclientsidevetement", xPlayer.source, null.players.clothes[xPlayer.identifier])
    end
end)

RegisterNetEvent('Null:charCreator:finish')
AddEventHandler('Null:charCreator:finish', function(data)   
    local src = source

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then 
        null.DebugPrint('[CharCreator Server] ERROR: xPlayer is nil for source', src)
        return 
    end
    
    local firstname = data.firstName
    local lastname = data.lastName
    local dateofbirth = data.birthdate
    local sex = data.gender == "m" and 0 or 1
    local Taille = data.height or 180
    
    MySQL.Async.execute("UPDATE users SET firstname = @firstname, lastname = @lastname, dateofbirth = @dateofbirth, sex = @sex, height = @height WHERE identifier = @identifier", {
        ['@firstname'] = firstname,
        ['@lastname'] = lastname,
        ['@dateofbirth'] = dateofbirth,
        ['@sex'] = sex,
        ['@identifier'] = xPlayer.identifier,
        ["@height"] = Taille
        
    }, function(affected) 
        if affected then
            xPlayer.firstname = firstname
            xPlayer.lastname = lastname
            xPlayer.dateofbirth = dateofbirth
            xPlayer.sex = sex
            xPlayer.name = firstname .. " " .. lastname

            ESX.ScheduleAdminRefresh(src)

            TriggerClientEvent("esx:charCreator:finish", src)
            
            if Config.Tutorial and Config.Tutorial.enabled then
                Citizen.SetTimeout(2000, function()
                    MySQL.Async.fetchScalar('SELECT tutorial_completed FROM users WHERE identifier = @identifier', {
                        ['@identifier'] = xPlayer.identifier
                    }, function(result)
                        local needsTutorial = (result == false or result == 0 or result == nil)
                        if needsTutorial then
                            local jobCenterCoords = Config.Tutorial.jobCenter.coords
                            if not jobCenterCoords and Config.FreeJobs and Config.FreeJobs.Agence and Config.FreeJobs.Agence.InteractionCoords then
                                local ic = Config.FreeJobs.Agence.InteractionCoords
                                jobCenterCoords = vector3(ic.x, ic.y, ic.z)
                            end
                            
                            TriggerClientEvent('null:tutorial:started', src, {
                                jobCenterCoords = jobCenterCoords,
                            })
                        else
                            --null.DebugPrint('[CharCreator Server] Player does not need tutorial (already completed)')
                        end
                    end)
                end)
            else
                --null.DebugPrint('[CharCreator Server] Tutorial is disabled in config')
            end
        else
            null.DebugPrint('[CharCreator Server] ERROR: DB update failed, affected =', affected)
        end
    end)
end)