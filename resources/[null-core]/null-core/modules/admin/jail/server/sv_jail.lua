Helper = {}

IN_JAIL = {};

local ALL_PLAYERS_IN_JAIL = {}; 
 
RegisterCommand("jail", function(source, args, rawCommand)
    if Showcase and Showcase.IsEnabled() and source ~= 0 then
        local xt = ESX.GetPlayerFromIdUnique(args[1])
        local tsrc = xt and xt.source or nil
        if Showcase.BlocksTarget(source, tsrc) then
            TriggerClientEvent('esx:showNotification', source, "~r~/jail indisponible sur un autre joueur (mode showcase).")
            return
        end
    end
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromIdUnique(args[1])
    if source ~= 0 then
        if xPlayer.getGroup() == "user" then
            return
        end
    end
    if xPlayer == nil then
        xPlayer = {}
        xPlayer.getName = function()
            return "Console"
        end
        xPlayer.showNotification = function(msg) print(msg) return end
    end
    if args[1] ~= nil and args[2] ~= nil and args[3] ~= nil then
        local reasn = table.concat(args, " ",3)
        if args[2] ~= "-1" then
            args[2] = args[2] * 60 -- Transformation Minutes en Secondes
        end
        if xTarget == nil then
            local pName
            if source == 0 then
                pName = "Console"
            else
                pName = GetPlayerName(source)
            end
            local tSource = "Inconnu"
            MySQL.Async.fetchAll('SELECT * FROM users WHERE idunique = @idunique',{
                ['@idunique'] = tonumber(args[1]),
            }, function(result)
                local identifier = result[1].identifier
                local TargetTable = result[1]
                MySQL.Async.fetchAll('SELECT * FROM account_info WHERE license = @license',{
                    ['@license'] = identifier,
                }, function(result2)
                    tSource = result2[1].name
                    if IN_JAIL[identifier] ~= nil then 
                        if source == 0 then
                            print("Ce joueur est déjà en prison pour ~g~"..IN_JAIL[identifier].raison.."~s~ pendant ~g~"..IN_JAIL[identifier].time.."~s~ sec !")
                        else
                            xPlayer.showNotification("Ce joueur est déjà en prison pour ~g~"..IN_JAIL[identifier].raison.."~s~ pendant ~g~"..IN_JAIL[identifier].time.."~s~ sec !") 
                        end
                        return
                    end
                    MySQL.Async.fetchAll('SELECT * FROM vjails WHERE identifier = @identifier',{
                        ['@identifier'] = identifier,
                    }, function(result3)
                        if result3[1] then
                            if source == 0 then
                                print("Ce joueur est déjà en prison pour ~g~"..result3[1].raison.."~s~ pendant ~g~"..result3[1].time.."~s~ secondes.")
                            else
                                xPlayer.showNotification("Ce joueur est déjà en prison pour ~g~"..result3[1].raison.."~s~ pendant ~g~"..result3[1].time.."~s~ secondes.") 
                            end
                            return
                        else
                            MySQL.Async.execute("INSERT INTO sanction_list (target_id, staff_name, target_name, type, raison, date) VALUES (@target_id, @staff_name, @target_name, @type, @raison, @date)",{
                                ["@target_id"] = identifier,
                                ["@staff_name"] = pName,
                                ["@target_name"] = tSource,
                                ["@type"] = "JAIL",
                                ["@raison"] = reasn.."  ("..args[2].." min)",
                                ["@date"] = os.date("%d/%m/%Y | %X"),
                            }, function()
                            end)
                            null.logs.send("Logs Staff",""..pName.." a jail "..tSource.." ("..args[1]..") pendant : "..args[2].." secondes","jail")
                            MySQL.update('INSERT INTO vjails (jailname,staffname,identifier, time, raison) VALUES (@e,@d,@a, @b, @c)', {
                                ["@e"] = tSource,
                                ["@d"] = pName,
                                ["@a"] = identifier,
                                ["@b"] = tonumber(args[2]),
                                ["@c"] = tostring(reasn)
                            })
                            IN_JAIL[identifier] = {
                                jailname = tSource,
                                identifier = identifier,
                                time = tonumber(args[2]),
                                raison = tostring(reasn),
                                staffname = pName
                            }
                        end
                    end)
                end)
            end)
        else
            if IN_JAIL[xTarget.identifier] ~= nil then 
                return xPlayer.showNotification("Ce joueur est déjà en prison pour ~g~"..IN_JAIL[xTarget.identifier].raison.."~s~ pendant ~g~"..IN_JAIL[xTarget.identifier].time.."~s~ sec !") 
            end
            TriggerClientEvent("Null:JailPutIn", args[1], tonumber(args[2]), tostring(reasn), xPlayer.getName())
            null.logs.send("Logs Staff",xPlayer.getName().." a jail "..xTarget.getName().." ("..args[1]..") pendant : "..args[2].." secondes","jail")
            MySQL.Async.execute("INSERT INTO sanction_list (target_id, staff_name, target_name, type, raison, date) VALUES (@target_id, @staff_name, @target_name, @type, @raison, @date)",{
                ["@target_id"] = xTarget.identifier,
                ["@staff_name"] = xPlayer.getName(),
                ["@target_name"] = xTarget.getName(),
                ["@type"] = "JAIL",
                ["@raison"] = reasn.."  ("..args[2].." min)",
                ["@date"] = os.date("%d/%m/%Y | %X"),
            }, function()
            end)

            MySQL.update('INSERT INTO vjails (jailname,staffname,identifier,idunique, time, raison) VALUES (@e,@d,@a,@uid, @b, @c)', {
                ["@e"] = xTarget.getName(),
                ["@d"] = xPlayer.getName(),
                ["@a"] = xTarget.identifier,
                ["@uid"] = xTarget.getIdunique(),
                ["@b"] = tonumber(args[2]),
                ["@c"] = tostring(reasn)
            })
            IN_JAIL[xTarget.identifier] = {
                jailname = xTarget.getName(),
                identifier = xTarget.identifier,
                time = tonumber(args[2]),
                raison = tostring(reasn),
                staffname = xPlayer.getName()
            }
            TriggerClientEvent("Null:JailPutIn", xTarget.source, tonumber(args[2]), tostring(reasn), xPlayer.getName())  
            null.fct.instance.Set(xTarget.source, 9201, "Jail")
        end
    else
        xPlayer.chatMessage("Formulation incorrect !")
    end 
end, false)


RegisterCommand("unjail", function(source, args, rawCommand)
    local source = source;
    local xPlayer = ESX.GetPlayerFromId(source)
    if source ~= 0 then
        if xPlayer.getGroup() == "user" then
            return
        end
    end
    if xPlayer == nil then
        xPlayer = {}
        xPlayer.getName = function()
            return "Console"
        end
        xPlayer.showNotification = function() return end
    end

    if (args[1]) then
        local xTarget = ESX.GetPlayerFromIdUnique(args[1])
        if xTarget == nil then
            MySQL.Async.fetchAll('SELECT * FROM users WHERE idunique = @idunique',{
                ['@idunique'] = tonumber(args[1]),
            }, function(result)
                if result[1] ~= nil then
                    if not IN_JAIL[result[1].identifier] then
                        if source == 0 then
                            print("Ce joueur n'est pas en prison !")
                        else
                            xPlayer.showNotification("~r~Ce joueur n'est pas en prison !")
                        end
                        return
                    end
                    MySQL.update('DELETE FROM vjails WHERE identifier = @a', {
                        ["@a"] = result[1].identifier,
                    })
                    null.logs.send("Action staff",""..xPlayer.getName().." \nA unjail : "..result[1].identifier.." ("..args[1]..")","unjail")
                    IN_JAIL[result[1].identifier] = nil;
                end
            end)
        else
            if not IN_JAIL[xTarget.identifier] then
                return xPlayer.showNotification("~r~Ce joueur n'est pas en prison !")
            end
            MySQL.update('DELETE FROM vjails WHERE identifier = @a', {
                ["@a"] = xTarget.identifier,
            })
            null.logs.send("Action staff",""..xPlayer.getName().." a unjail : "..xTarget.getName().." ("..args[1]..")","unjail")
            IN_JAIL[xTarget.identifier] = nil
            TriggerClientEvent("Null:JailPutOut", xTarget.source)
            xTarget.showNotification("Cette fois, ne fais plus n'importe quoi, bon jeu.")
            Wait(1000)
            SetEntityCoords(GetPlayerPed(xTarget.source), vector3(1854.3568115234, 2583.4379882813, 45.671989440918))
            null.fct.instance.Set(xTarget.source, 0)
        end
    else
        xPlayer.chatMessage("Formulation incorrect !")
    end
end, false)

RegisterNetEvent('Null:leaveJail')
AddEventHandler('Null:leaveJail', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerEvent("ratelimit", xPlayer.source, "Null:leaveJail") 
    if IN_JAIL[xPlayer.identifier] ~= nil then
        DropPlayer(source, "Désynchonisation avec le serveur ou detection de Cheat")
    end
end)

AddEventHandler("Null:VerifyJail", function(id)
    local xPlayer = ESX.GetPlayerFromId(id);
    TriggerEvent("ratelimit", xPlayer.source, "Null:VerifyJail") 

    if (xPlayer) then
        if (IN_JAIL[xPlayer.identifier] ~= nil) then
            TriggerClientEvent("Null:JailPutIn", id, tonumber(IN_JAIL[xPlayer.identifier].time), tostring(IN_JAIL[xPlayer.identifier].raison),IN_JAIL[xPlayer.identifier].staffname)
            
            null.fct.instance.Set(id, 9201, "Jail")
        else
            MySQL.query('SELECT time, raison FROM vjails WHERE identifier = @a', {
                ["@a"] = xPlayer.identifier
            }, function(result)
                if result[1] then
                    TriggerClientEvent("Null:JailPutIn", id, result[1].time, result[1].raison, result[1].staffname)
                    null.fct.instance.Set(id, 9201, "Jail")
                    if result[1].jailname ~= nil then
                        IN_JAIL[xPlayer.identifier] = {
                            jailname = GetPlayerName(result[1].jailname),
                            identifier = xPlayer.identifier, 
                            time = tonumber(result[1].time),
                            raison = tostring(result[1].raison),
                            staffname = result[1].staffname
                        }
                    else
                        IN_JAIL[xPlayer.identifier] = {
                            jailname = "Nom Inconnu",
                            identifier = xPlayer.identifier, 
                            time = tonumber(result[1].time),
                            raison = tostring(result[1].raison),
                            staffname = result[1].staffname
                        }
                    end
                else
                    return
                end
            end)
        end
    end
end)

RegisterNetEvent('Null:JailPut')
AddEventHandler('Null:JailPut', function(id, seconds, desc)
    local source = source;
    local xPlayer = ESX.GetPlayerFromId(source);
    TriggerEvent("ratelimit", xPlayer.source, "Null:JailPut") 
    if xPlayer.getGroup() ~= "user" then
        local xTarget = ESX.GetPlayerFromId(id)
        if IN_JAIL[xTarget.identifier] ~= nil then 
            return xPlayer.showNotification("Ce joueur est déjà en prison pour ~g~"..IN_JAIL[xTarget.identifier].raison.."~s~ pendant ~g~"..IN_JAIL[xTarget.identifier].time.."~s~ sec !") 
        end
        TriggerClientEvent("Null:JailPutIn", id, seconds, tostring(desc),GetPlayerName(source))
        null.fct.instance.Set(id, 9201, "Jail")
        MySQL.update('INSERT INTO vjails (jailname,staffname,identifier, time, raison) VALUES (@e,@d,@a, @b, @c)', {
            ["@e"] = GetPlayerName(xTarget.source),
            ["@d"] = GetPlayerName(source),
            ["@a"] = xTarget.identifier,
            ["@b"] = tonumber(seconds),
            ["@c"] = tostring(desc)
        })
        IN_JAIL[xTarget.identifier] = {
            jailname = GetPlayerName(result[1].jailname),
            identifier = xTarget.identifier,
            time = tonumber(seconds),
            raison = tostring(desc),
            staffname = GetPlayerName(source)
        }
    end
end)

RegisterNetEvent('Null:JailSeconds')
AddEventHandler('Null:JailSeconds', function()
    local source = source;
    local xPlayer = ESX.GetPlayerFromId(source);
    if not xPlayer then return end
    TriggerEvent("ratelimit", xPlayer.source, "Null:JailSeconds") 

    if IN_JAIL[xPlayer.identifier] then
        SetTimeout(1000, function()
            if IN_JAIL[xPlayer.identifier] ~= nil and IN_JAIL[xPlayer.identifier].time == -1 then
                IN_JAIL[xPlayer.identifier].time = IN_JAIL[xPlayer.identifier].time
                null.fct.instance.Set(xPlayer.source, 9201, "Jail")
            elseif IN_JAIL[xPlayer.identifier] ~= nil and IN_JAIL[xPlayer.identifier].time <= 0 then
                xPlayer.showNotification("Cette fois, ne fais plus n'importe quoi, bon jeu.")
                Wait(1000)
                SetEntityCoords(GetPlayerPed(xPlayer.source), vector3(1854.3568115234, 2583.4379882813, 45.671989440918))
                null.fct.instance.Set(xPlayer.source, 0)
                MySQL.update('DELETE FROM vjails WHERE identifier = @a', {
                    ["@a"] = xPlayer.identifier,
                })
                IN_JAIL[xPlayer.identifier] = nil;
                TriggerClientEvent("Null:JailPutOut", source)
            elseif IN_JAIL[xPlayer.identifier] ~= nil then
                IN_JAIL[xPlayer.identifier].time = IN_JAIL[xPlayer.identifier].time - 1
                null.fct.instance.Set(xPlayer.source, 9201, "Jail")
            end
        end)
    end
end)

RegisterNetEvent('Null:RequestJail')
AddEventHandler('Null:RequestJail', function()
    local source = source;
    local xPlayer = ESX.GetPlayerFromId(source);
    TriggerEvent("ratelimit", xPlayer.source, "Null:RequestJail") 
    ALL_PLAYERS_IN_JAIL = {};

    if xPlayer.getGroup() ~= "user" then
        local playeers = ESX.GetPlayers()
        for i = 1, #playeers do
            local player = ESX.GetPlayerFromId(playeers[i])
            for k,v in pairs(IN_JAIL) do
                if player.identifier == v.identifier then
                    table.insert(ALL_PLAYERS_IN_JAIL, { id = player.source, name = player.name, job = player.job.name, raison = v.raison, time = v.time / 60})
                end
            end
        end
        TriggerClientEvent("Null:StaffUpdateJail", source, ALL_PLAYERS_IN_JAIL)
    else
        DropPlayer(source, 'Vous n\'avez pas les permissions nécessaire ['..xPlayer.getGroup()..']')
    end
end)

RegisterNetEvent("AKService:unjailServer", function(jid,jl)
    local xPlayer = ESX.GetPlayerFromId(source)

    if xPlayer.getGroup() ~= "user" then
        MySQL.Async.fetchAll("SELECT * FROM vjails WHERE identifier = @i AND jailid = @j", {
            ["@i"] = jl,
            ["@j"] = tonumber(jid)
        }, function(result)
            if result[1] then
                MySQL.Async.execute("DELETE FROM vjails WHERE jailid = @j2",{
                    ["@j2"] = tonumber(jid)
                }, function(rowsChanged)
                    if rowsChanged then
                        xPlayer.showNotification("Vous avez unjail le joueur avec succès")
                        local tPlayer = ESX.GetPlayerFromIdentifier(jl)
                        if tPlayer then
                            TriggerClientEvent("Null:skinchanger:getSkin", tPlayer.source, function(skin)
                                TriggerClientEvent("Null:skinchanger:loadSkin", tPlayer.source, skin)
                            end)
                            IN_JAIL[tPlayer.identifier] = nil;
                            null.fct.instance.Set(tPlayer.source, 0)
                            TriggerClientEvent("Null:JailPutOut", tPlayer.source)
                            tPlayer.showNotification("Cette fois, ne fais plus n'importe quoi, bon jeu.")
                            Wait(1000)
                            SetEntityCoords(GetPlayerPed(tPlayer.source), vector3(1854.3568115234, 2583.4379882813, 45.671989440918))
                        end
                    else
                        xPlayer.showNotification("Une erreur s'est produite veuillez contacter les développeurs")
                    end
                end)
            end
        end)
    end
end)

AddEventHandler("playerDropped", function()
    local source = source;
    local xPlayer = ESX.GetPlayerFromId(source);
    if xPlayer == nil then
        return
    end
    if IN_JAIL[xPlayer.identifier] then
        if IN_JAIL[xPlayer.identifier].time == -1 then
                        
        elseif IN_JAIL[xPlayer.identifier].time > 0 then
            local newJail = tonumber(IN_JAIL[xPlayer.identifier].time) + 300
            MySQL.update("UPDATE vjails SET time = @a WHERE identifier = @b", {
                ["@a"] = newJail,
                ["@b"] = xPlayer.identifier
            })
        else
            IN_JAIL[xPlayer.identifier] = nil;
            MySQL.update("DELETE FROM vjails WHERE identifier = @a", {
                ["@a"] = xPlayer.identifier
            })
        end
    end
end)

AddEventHandler('esx:playerLoaded', function(source)
	TriggerEvent("Null:VerifyJail", source)
end)

ESX.RegisterServerCallback("Null:jailList", function(source,cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    cb(IN_JAIL)
end)

ESX.RegisterServerCallback("Null:IsInJail", function(source,cb,id,identifier)
    if id == nil and identifier ~= nil then
        MySQL.Async.fetchAll("SELECT * FROM vjails WHERE identifier = @identifier", {
            ["@identifier"] = identifier
        }, function(result)
            if result[1] then
                cb(true,result[1].time, result[1].staffname)
            else
                cb(false)
            end
        end)
    else
        local xPlayer = ESX.GetPlayerFromId(id)

        MySQL.Async.fetchAll("SELECT * FROM vjails WHERE identifier = @identifier", {
            ["@identifier"] = xPlayer.identifier
        }, function(result)
            if result[1] then
                cb(true,result[1].time, result[1].staffname)
            else
                cb(false)
            end
        end)
    end
end)