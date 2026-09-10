InService = 0 
PlayerPolice = {}
Cellule = {}

RegisterNetEvent("Null:servicepolice")
AddEventHandler("Null:servicepolice", function(value, policename)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerEvent("ratelimit", xPlayer.source, "Null:servicepolice") 

    if SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil then 
        local jobName = xPlayer.job.name
        local logo, color, label
        if SocietyList[jobName] then
            logo = SocietyList[jobName].logo ~= "" and SocietyList[jobName].logo or nil
            color = SocietyList[jobName].brandColor
            label = SocietyList[jobName].label or "Police"
        else
            label = "Central Police"
        end
        if value then 
            PlayerPolice[source] = source
            InService = InService+1
            for k, v in pairs(PlayerPolice) do 
                TriggerClientEvent("null:notificationAdvanced", k, "L'agent "..ESX.Config("serverColor")..xPlayer.getName().." ~s~viens de prendre son service", label, "Prise de Service", color, logo)
                TriggerClientEvent("Null:recieveagentpolice", k, InService)
            end
        else
            PlayerPolice[source] = nil
            InService = InService-1
            for k, v in pairs(PlayerPolice) do 
                TriggerClientEvent("null:notificationAdvanced", k, "L'agent "..ESX.Config("serverColor")..xPlayer.getName().." ~s~viens de finir son service", label, "Fin de Service", color, logo)
                TriggerClientEvent("Null:recieveagentpolice", k, InService)
            end
        end
    else
        DropPlayer(source, 'Désynchonisation avec le serveur ou detection de Cheat')
    end
end)

RegisterNetEvent("Null:confiscateitem")
AddEventHandler("Null:confiscateitem", function(count, item, player, action, label)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerEvent("ratelimit", xPlayer.source, "Null:confiscateitem") 
    local tPlayer = ESX.GetPlayerFromId(player)
    if SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil then 
        if PlayerPolice[source] then 
            if tPlayer then 
                if action == "item" then 
                    InfoItem = tPlayer.getInventoryItem(item)
                    if InfoItem.count >= tonumber(count) then 
                        tPlayer.removeInventoryItem(item, count)
                        xPlayer.addInventoryItem(item, count)
                    end
                    tPlayer.showNotification("Vous venez de vous faire confisquer "..ESX.Config("serverColor")..count.."~s~ de "..InfoItem.label)
                    xPlayer.showNotification("Vous venez de confisquer "..ESX.Config("serverColor")..count.."~s~ de "..InfoItem.label)
                elseif action == "weapon" then
                    InfoWeapon = tPlayer.getWeapon(item)
                    if InfoWeapon > 0 then 
                        tPlayer.removeWeapon(item)
                        xPlayer.addWeapon(item, 20)
                        tPlayer.showNotification("Vous venez de vous faire confisquer un/une "..label)
                        tPlayer.showNotification("Vous venez de confisquer un/une "..label)
                    else
                        DropPlayer(source, 'Désynchonisation avec le serveur ou detection de Cheat')
                    end
                else
                    DropPlayer(source, 'Désynchonisation avec le serveur ou detection de Cheat')
                end
            end
        else
            DropPlayer(source, 'Désynchonisation avec le serveur ou detection de Cheat')
        end
    else
        DropPlayer(source, 'Désynchonisation avec le serveur ou detection de Cheat')
    end
end)

RegisterNetEvent("Null:demandederenfort")
AddEventHandler("Null:demandederenfort", function(type)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerEvent("ratelimit", xPlayer.source, "Null:demandederenfort") 
    if SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil then 
        if PlayerPolice[source] then 
            local jobName = xPlayer.job.name
            local logo, color, label
            if SocietyList[jobName] then
                logo = SocietyList[jobName].logo ~= "" and SocietyList[jobName].logo or nil
                color = SocietyList[jobName].brandColor
                label = SocietyList[jobName].label or "Police"
            else
                label = "Central Police"
            end
            for k, v in pairs(PlayerPolice) do 
                if type == "pause" then 
                    TriggerClientEvent("null:notificationAdvanced", k, "L'agent "..ESX.Config("serverColor")..xPlayer.getName().."~s~ viens de se mettre en pause !", label, "Radio", color, logo)
                elseif type == 'control' then
                    TriggerClientEvent("null:notificationAdvanced", k, "L'agent "..ESX.Config("serverColor")..xPlayer.getName().."~s~ est actuellement en control !", label, "Radio", color, logo)
                elseif type == "retrourpdp" then 
                    TriggerClientEvent("null:notificationAdvanced", k, "L'agent "..ESX.Config("serverColor")..xPlayer.getName().."~s~ est en route vers le commisariat", label, "Radio", color, logo)
                else
                    TriggerClientEvent("null:notificationAdvanced", k, "L'agent "..ESX.Config("serverColor")..xPlayer.getName().."~s~ à besoin de renfort, je t'ai mis les coordonnées sur ton GPS !", label, "Renfort", color, logo)
                    TriggerClientEvent("Null:demandederenfort", k, type, GetEntityCoords(GetPlayerPed(source)))
                end
            end
        else
            DropPlayer(source, 'Désynchonisation avec le serveur ou detection de Cheat')
        end
    end
end)

RegisterNetEvent("Null:newcasierpolice")
AddEventHandler("Null:newcasierpolice", function(casier)
    local xPlayer = ESX.GetPlayerFromId(source)
    TriggerEvent("ratelimit", xPlayer.source, "Null:newcasierpolice") 
    if SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil then 
        if PlayerPolice[source] then 
            --LogsDiscord(3447003, "Nouveau Casier Judiciaire", "Information sur l'agent: \nNom: **"..xPlayer.getName().."**\nLicense: **"..xPlayer.identifier.."**\nMatricule: **"..casier.matricule.."**\nInformation sur l\'individu: Nom: **"..casier.nameprename.."**\nRaison de l'arrestation: **"..casier.reason.."**\nTemps mis en cellule: **"..casier.timecellule.."**", ConfigPoliceJob.Logs.MenuPolice)
        else
            DropPlayer(source, 'Désynchonisation avec le serveur ou detection de Cheat')
        end
    end
end)



RegisterNetEvent("Null:miseencelule")
AddEventHandler("Null:miseencelule", function(player, timer, cellule)
    if player == nil then return end  
    if timer == nil then return end
    if cellule == nil then return end
    local xPlayer = ESX.GetPlayerFromId(source)
    local tPlayer = ESX.GetPlayerFromId(player)
    if tPlayer == nil then xPlayer.showNotification("⚠️ La personne souhaitez n'est pas encore en ville.") return end
    xPlayer.job.name = xPlayer.getJob().name
    if SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil then 
        local PosCommico = nil
        for k,v in pairs(SaveData.json["entreprises"]["Police"][xPlayer.job.name].cellule) do
            if tostring(k) == tostring(cellule) then
                PosCommico = vector3(SaveData.json["entreprises"]["Police"][xPlayer.job.name].cellule[k].x, SaveData.json["entreprises"]["Police"][xPlayer.job.name].cellule[k].y,SaveData.json["entreprises"]["Police"][xPlayer.job.name].cellule[k].z)
                break
            end
        end
        if PosCommico == nil then xPlayer.showNotification("⚠️ Votre commissariat n'a pas de cellule.") return end
        local distance = #(GetEntityCoords(GetPlayerPed(source)) - PosCommico)
        if distance < 50.00 then 
            SetEntityCoords(GetPlayerPed(player), PosCommico)
            if not Cellule[tPlayer.identifier] then 
                Cellule[tPlayer.identifier] = {}
                Cellule[tPlayer.identifier].identifier = tPlayer.identifier
                Cellule[tPlayer.identifier].timecellule = tonumber(timer)
                Cellule[tPlayer.identifier].cellulenbr = cellule
                Cellule[tPlayer.identifier].code = math.random(00000, 99999)
                Cellule[tPlayer.identifier].police = SaveData.json["entreprises"]["Police"][xPlayer.job.name]
                Cellule[tPlayer.identifier].policepos = PosCommico
                TriggerClientEvent("Null:setTimerPrison", player, timer, Cellule[tPlayer.identifier].code, PosCommico)
            end
        else
            xPlayer.showNotification("Vous devez être au commisariat pour faire cela")
        end
    end
end)

RegisterNetEvent("Null:updatetimerprison")
AddEventHandler("Null:updatetimerprison", function(timer, code)
    local xPlayer = ESX.GetPlayerFromId(source)
    if Cellule[xPlayer.identifier] == nil then
    else
        Cellule[xPlayer.identifier].timecellule = timer
        if tonumber(Cellule[xPlayer.identifier].code) == tonumber(code) then 
            if tonumber(Cellule[xPlayer.identifier].timecellule) == 0 or tonumber(Cellule[xPlayer.identifier].timecellule) == 1 then 
                xPlayer.showNotification("✅ Votre temps en cellule est fini, un agent de la police va vous liberez.")
                TriggerClientEvent("null:police:notif", -1, "✅ Le temps de la cellule "..Cellule[xPlayer.identifier].cellulenbr.." est terminer.\nVeuillez venir le liberer le plus vite possible.\nId Unique : "..xPlayer.getIdunique(), true)
                Cellule[xPlayer.identifier] = nil 
            end
        else
            DropPlayer(source, 'Désynchonisation avec le serveur ou detection de Cheat')
        end
    end
end)

AddEventHandler('esx:playerLoaded', function(source)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if Cellule[xPlayer.identifier] ~= nil then
        TriggerClientEvent("Null:setTimerPrison", src, Cellule[xPlayer.identifier].timecellule, Cellule[xPlayer.identifier].code, Cellule[xPlayer.identifier].policepos)
    end
end)

ESX.RegisterServerCallback("ronfex:fouillepolicecb", function(source, cb, player)
    local tPlayer = ESX.GetPlayerFromId(player)
    if tPlayer then 
        infosplayer = {
            inventory = tPlayer.getInventory(),
            weapon = tPlayer.getLoadout(),
            black_money = tPlayer.accounts.dirtycash
        }
    end
    cb(infosplayer)
end)


RegisterServerEvent('police:putInVehicle')
AddEventHandler('police:putInVehicle', function(target)
    if target == -1 then
        TriggerEvent("BanSql:ICheatServer", source, "Tu crois chui con mek dort :(")
    end
	local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil then 
        local xPlayerTarget = ESX.GetPlayerFromId(target)
        TriggerClientEvent('police:putInVehicle', target)
    else
        DropPlayer(source, 'Désynchonisation avec le serveur ou detection de Cheat')
    end
end)


RegisterServerEvent('police:OutVehicle')
AddEventHandler('police:OutVehicle', function(target)
    if target == -1 then
        TriggerEvent("BanSql:ICheatServer", source, "Tu crois chui con mek dort :(")
    end
	local xPlayer = ESX.GetPlayerFromId(source)
	if SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil then 
		local xPlayerTarget = ESX.GetPlayerFromId(target)
		TriggerClientEvent('police:OutVehicle', target)
	else
		DropPlayer(source, 'Désynchonisation avec le serveur ou detection de Cheat')
	end
end)


RegisterServerEvent('esx_policejob:drag')
AddEventHandler('esx_policejob:drag', function(target)
    if target == -1 then
        TriggerEvent("BanSql:ICheatServer", source, "Tu crois chui con mek dort :(")
    end
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil then 
        local xPlayerTarget = ESX.GetPlayerFromId(target)
        TriggerClientEvent('esx_policejob:drag', target, xPlayer.source)
    else
        print(('esx_policejob: %s attempted to put in vehicle (not cop)!'):format(xPlayer.identifier))
    end
end)


RegisterServerEvent('esx_policejob:handcuff')
AddEventHandler('esx_policejob:handcuff', function(target)
    if target == nil then target = source end
    if target == -1 then
        TriggerEvent("BanSql:ICheatServer", source, "Tu crois chui con mek dort :(")
    end
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["entreprises"]["Police"][xPlayer.job.name] == nil then 
        DropPlayer(source, 'Désynchonisation avec le serveur ou detection de Cheat')
    end
    if SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil then 
	    TriggerClientEvent('esx_policejob:handcuff', target)
    end
end)


RegisterServerEvent('esx_policejob:unhandcuff')
AddEventHandler('esx_policejob:unhandcuff', function(target)
    if target == nil then target = source end
    if target == -1 then
        TriggerEvent("BanSql:ICheatServer", source, "Tu crois chui con mek dort :(")
    end
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil then 
	TriggerClientEvent('esx_policejob:unrestrain', target)
    else
        DropPlayer(source, 'Désynchonisation avec le serveur ou detection de Cheat')
end
end)

ESX.RegisterServerCallback('esx_policejob:getFineList', function(source, cb, category)
	MySQL.Async.fetchAll('SELECT * FROM fine_types WHERE category = @category', {
		['@category'] = category
	}, function(fines)
		cb(fines)
	end)
end)

local alreadyshot = false

RegisterServerEvent('TireEntenduServeur')
AddEventHandler('TireEntenduServeur', function(gx, gy, gz)
    if alreadyshot then return end
	local _source = source
    TriggerClientEvent('TireEntendu', -1, gx, gy, gz)
    alreadyshot = true
    if alreadyshot then
        Wait(20000)
        alreadyshot = false
    end
end)

RegisterServerEvent('PriseAppelServeur')
AddEventHandler('PriseAppelServeur', function(gx, gy, gz)
	local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
	local name = xPlayer.getName(_source)
	TriggerClientEvent('PriseAppel', -1, name)
end)