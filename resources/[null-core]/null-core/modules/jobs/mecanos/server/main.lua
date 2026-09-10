local MecanoCounter = 0
MecanoList = {}

RegisterNetEvent('Null:createmecano', function(namejob, labeljob, PosVestiaire, Custom1, Custom2, Custom3, PosBoss)
    local xPlayer = ESX.GetPlayerFromId(source)

    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        if SaveData.json["entreprises"]["Mécano"][namejob] ~= nil then 
            xPlayer.showNotification('Ce mécano existe déjà.')
            return
        end
        null.fct.sql.CheckJobAndCreate(namejob, labeljob)
        null.fct.sql.CheckSocietyAndCreate(namejob, labeljob)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "PDG", "boss", 2)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Responsable", "responsable", 1)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Employer", "employer", 0)
        MecanoCounter = MecanoCounter +1
        SaveData.json["entreprises"]["Mécano"][namejob] = {}
        SaveData.json["entreprises"]["Mécano"][namejob].type =  "Mécano"
        SaveData.json["entreprises"]["Mécano"][namejob].name = namejob
        SaveData.json["entreprises"]["Mécano"][namejob].label = labeljob
        SaveData.json["entreprises"]["Mécano"][namejob].PosVestiaire = PosVestiaire
        SaveData.json["entreprises"]["Mécano"][namejob].PosCustom = Custom1
        SaveData.json["entreprises"]["Mécano"][namejob].PosCustom2 = Custom2
        SaveData.json["entreprises"]["Mécano"][namejob].PosCustom3 = Custom3
        SaveData.json["entreprises"]["Mécano"][namejob].PosBoss = PosBoss
        SaveData.json["entreprises"]["Mécano"][namejob].politique = {
            ["forceVerif"] = false,
        }
        Cache.SaveOne('entreprises')
        TriggerClientEvent('esx:showNotification', source, 'Le Job à été crée avec succès.')
        Wait(1000)
        ExecuteCommand('refreshGlobalsInformations')
        InitSociety2()
        TriggerClientEvent('Null:receiveMecano', -1, SaveData.json["entreprises"]["Mécano"])
    else
        ExecuteCommand("ban " .. source .. " Tentative de triche creation mécano (0)")
    end
end)

RegisterNetEvent('Null:mecano:refreshSetJob', function(namejob)
    local xPlayer = ESX.GetPlayerFromId(source)

    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        if SaveData.json["entreprises"]["Mécano"][namejob] == nil then 
            xPlayer.showNotification('Ce mécano n\'existe pas.')
            return
        end
        null.fct.sql.CheckJobAndCreate(namejob, labeljob)
        null.fct.sql.CheckSocietyAndCreate(namejob, labeljob)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "PDG", "boss", 2)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Responsable", "responsable", 1)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Employer", "employer", 0)
        Wait(5000)
        ExecuteCommand('refreshGlobalsInformations')
        InitSociety2()
    else
        ExecuteCommand("ban " .. source .. " Tentative de triche creation mécano (0)")
    end
end)


RegisterNetEvent('Null:initMecano', function()
	TriggerClientEvent('Null:receiveMecano', source, SaveData.json["entreprises"]["Mécano"])
end)

RegisterCommand('createmecano', function(source,args)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		TriggerClientEvent('Null:createmecanomenu', source)
	end
end)


ESX.RegisterServerCallback('Null:Mechanic:getVehicleInfos', function(source, cb, plate, name)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.job.name == name then
        if SaveData.json["owned_vehicles"][string.upper(plate)] then
            local infos = {
                plate = plate
            }
            MySQL.Async.fetchAll('SELECT firstname, lastname FROM users WHERE identifier = @identifier', {
                ['@identifier'] = SaveData.json["owned_vehicles"][string.upper(plate)].owner
            }, function(result2)
                infos.owner = (SaveData.json["owned_vehicles"][string.upper(plate)].owner or 'Inconnu')
                cb(infos)
            end)
        else
           cb({plate = plate})
        end
    else
        ExecuteCommand("ban " .. source .. " 0 Tentative de triche mécano (0)")
    end
end)

RegisterServerEvent('Null:esx_lscustom:buyMod')
AddEventHandler('Null:esx_lscustom:buyMod', function(price, token, vehname, owner, plaque)
    VerifyToken(source, token, 'Null:esx_lscustom:buyMod', function()
        local xPlayer = ESX.GetPlayerFromId(source)
        price = tonumber(price)
        if tonumber(SocietyCache[xPlayer.job.name].data["accounts"].cash) >= price then
            SocietyCache[xPlayer.job.name].data["accounts"].cash = SocietyCache[xPlayer.job.name].data["accounts"].cash-price
            TriggerClientEvent('Null:esx_lscustom:installMod', xPlayer.source)
            TriggerClientEvent('esx:showNotification', xPlayer.source, 'Vous avez acheter une Customisation sur le véhicule')
             entreprisename = xPlayer.job.name
            --TriggerEvent("esx:SendLogsBuyModification", GetPlayerName(source), price, vehname, xPlayer.identifier, plaque,entreprisename)
            --TriggerEvent("esx:SendLogsProprio", vehname, owner, plaque)

            exports["null-core"]:SendLogs("Logs","Le joueur : "..xPlayer.getName().." (T"..source.." U"..xPlayer.getIdunique()..") a custom le véhicule : "..vehname.." (Plaque : "..plaque..", Owner : "..owner..") pour un total de : "..price.."$","society")
        else
            TriggerClientEvent('Null:esx_lscustom:cancelInstallMod', xPlayer.source)
            TriggerClientEvent('esx:showNotification', xPlayer.source, 'Votre entreprise n\'as pas assez d\'argents')
        end

    end, function()

    end)
end)


RegisterNetEvent('Null:DeleteMecano', function(value)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		if SaveData.json["entreprises"]["Mécano"][value] then
			SaveData.json["entreprises"]["Mécano"][value] = nil
            MecanoCounter = MecanoCounter - 1
            Cache.SaveOne('entreprises')
            TriggerClientEvent('Null:receiveMecano', -1, SaveData.json["entreprises"]["Mécano"])
            TriggerClientEvent('Null:deletemecanoblips', -1, value)
        else
            print("Tentative de suppression d'une entreprise inexistante ("..value..")")
		end
	end
end)


RegisterServerEvent('mecano:callMechanic')
AddEventHandler('mecano:callMechanic', function(vehicle)
    local pos = GetEntityCoords(vehicle)
    TriggerClientEvent("null:mecano:addchoicenotif",-1, math.random(1,9999),"callMechanic",pos,317,59,"towrequest","⚠️  Un citoyen a besoin d'un mécano !")
end)

RegisterServerEvent("null:mecano:verifOwner", function(target, plate)
    local xPlayer = ESX.GetPlayerFromId(source)
	if SocietyCache[xPlayer.job.name] == nil then return end
    local xTarget = ESX.GetPlayerFromId(target)


        if SaveData.json["owned_vehicles"][string.upper(plate)] ~= nil then
            if SaveData.json["owned_vehicles"][string.upper(plate)].owner == xTarget.identifier then
                TriggerClientEvent("inventory:sendMessage", xPlayer.source, "Résultat :\nPropriétaire du véhicule = ✅", 6000)
                TriggerClientEvent("null:VerifOwnerReceive", xPlayer.source, plate)
            else
                TriggerClientEvent("inventory:sendMessage", xPlayer.source, "Résultat :\nPropriétaire du véhicule = ❌\n\n(Un avertissement a étais envoyer a la police la plus proche)", 6000)
                TriggerClientEvent('null:police:addchoicenotif', -1, math.random(0,9999), "Appel vol véhicule", xPlayer.getCoords(), 225, 1,"volvehi-mecano", "Un mécano vous a signalé un véhicule volé.")
            end
        else
            TriggerClientEvent("inventory:sendMessage", xPlayer.source, "Résultat :\nPropriétaire du véhicule = ❌\n\n(Un avertissement a étais envoyer a la police la plus proche)", 6000)
            TriggerClientEvent('null:police:addchoicenotif', -1, math.random(0,9999), "Appel vol véhicule", xPlayer.getCoords(), 225, 1,"volvehi-mecano", "Un mécano vous a signalé un véhicule volé.")
        end
end)