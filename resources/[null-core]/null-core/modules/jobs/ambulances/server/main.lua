-- Tu gobes bien ptit pute a unlock (t'en a plein la bouche et tes fan aussi)
RegisterNetEvent('null:createambulancesociety', function(namejob, labeljob, PosVestiaire, PosBoss, color)
    local xPlayer = ESX.GetPlayerFromId(source)
    local src = source
    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        if SaveData.json["entreprises"]["Ambulance"][namejob] ~= nil then  
            xPlayer.showNotification('Ce ambulance job existe déjà.')
            return
        end
        null.fct.sql.CheckJobAndCreate(namejob, labeljob)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Directeur", "boss", 3)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Médecin-Chef", "chief", 2)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Médecin", "doctor", 1)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Ambulancier", "ambulance", 0)
        null.fct.sql.CheckSocietyAndCreate(namejob, labeljob)
        SaveData.json["entreprises"]["Ambulance"][namejob] = {}
        SaveData.json["entreprises"]["Ambulance"][namejob].type =  "Ambulance"
        SaveData.json["entreprises"]["Ambulance"][namejob].name = namejob
        SaveData.json["entreprises"]["Ambulance"][namejob].label = labeljob
        SaveData.json["entreprises"]["Ambulance"][namejob].PosVestiaire = PosVestiaire
        SaveData.json["entreprises"]["Ambulance"][namejob].PosBoss = PosBoss
        SaveData.json["entreprises"]["Ambulance"][namejob].color = color
        Cache.SaveOne('entreprises')
        TriggerClientEvent('esx:showNotification', src, 'Le Job à été crée avec succès.')
        Wait(1000)
        ExecuteCommand('refreshGlobalsInformations')
        InitSociety2()
        TriggerClientEvent('null:ambulance:recevie', -1, SaveData.json["entreprises"]["Ambulance"])
    else
        ExecuteCommand("ban " .. src .. " Tentative de triche creation mécano (0)")
    end
end)

RegisterNetEvent('Null:DeleteAmbulance', function(value)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		if SaveData.json["entreprises"]["Ambulance"][value] then
			SaveData.json["entreprises"]["Ambulance"][value] = nil
            Cache.SaveOne('entreprises')
            TriggerClientEvent('null:ambulance:recevie', -1, SaveData.json["entreprises"]["Ambulance"])
        else
            print("Tentative de suppression d'une entreprise inexistante ("..value..")")
		end
	end
end)


RegisterNetEvent('null:initAmbulance', function()
    local src = source
    Wait(2000)
	TriggerClientEvent('null:ambulance:recevie', src, SaveData.json["entreprises"]["Ambulance"])
end)

function GetDiscordInformations(src)
	local ids = ExtractIdentifiers(src)
	local license = nil
	local discord = nil

	if ids.discord ~= "" then 
		discord = ids.discord:gsub("discord:", "")
	else 
		discord = "0"
	end 

	if ids.license ~= "" then 
		license = ids.license 
	else 
		license = ""
	end 

	return discord, license
end

function ExtractIdentifiers(src)
    local identifiers = {
        steam = "",
        ip = "",
        discord = "",
        license = "",
        xbl = "",
        live = ""
    }

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)

        if string.find(id, "steam") then
            identifiers.steam = id
        elseif string.find(id, "ip") then
            identifiers.ip = id
        elseif string.find(id, "discord") then
            identifiers.discord = id
        elseif string.find(id, "license") then
            identifiers.license = id
        elseif string.find(id, "xbl") then
            identifiers.xbl = id
        elseif string.find(id, "live") then
            identifiers.live = id
        end
    end
    return identifiers
end


PlayerIsDead = {}
atatime = {}
local AtaList = {}
local IsInServiceEMS = {}
RegisterNetEvent('EMS:UpdateTableIsDead', function(value, id, deathreason, death)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    if value then
        PlayerIsDead[xPlayer.source] = { isDead = 1 }

        -- Détails du tueur
        local killerInfo = {
            idu = nil,
            source = nil,
            name = nil,
            firstname = nil,
            lastname = nil,
            job = nil,
            job2 = nil,
            distance = nil,
            coords = nil,
        }
        if id ~= nil and id ~= "Inconnu" and tonumber(id) and tonumber(id) ~= 0 then
            local xTueur = ESX.GetPlayerFromId(tonumber(id))
            if xTueur ~= nil then
                killerInfo.idu = xTueur.idunique
                killerInfo.source = xTueur.source
                killerInfo.name = xTueur.getName()
                killerInfo.firstname = xTueur.firstname
                killerInfo.lastname = xTueur.lastname
                killerInfo.job = xTueur.job and xTueur.job.label or (xTueur.job and xTueur.job.name) or nil
                killerInfo.job2 = xTueur.job2 and (xTueur.job2.label or xTueur.job2.name) or nil
                local kCoords = xTueur.getCoords()
                killerInfo.coords = kCoords
                local victimCoords = xPlayer.getCoords()
                if kCoords and victimCoords then
                    killerInfo.distance = math.floor(#(vector3(kCoords.x, kCoords.y, kCoords.z) - vector3(victimCoords.x, victimCoords.y, victimCoords.z)))
                end

                -- Compteur staff (utile si playerDied/dead.lua n'a pas trigger)
                if NullIncrementKillStat then
                    NullIncrementKillStat(xTueur.idunique, xPlayer.idunique)
                end
            end
        end

        TriggerClientEvent("null:playerDied", -1, {
            coords = xPlayer.getCoords(),
            playerId = xPlayer.source,
            victim = {
                idu = xPlayer.idunique,
                source = xPlayer.source,
                name = xPlayer.getName(),
                firstname = xPlayer.firstname,
                lastname = xPlayer.lastname,
                job = xPlayer.job and (xPlayer.job.label or xPlayer.job.name) or nil,
                job2 = xPlayer.job2 and (xPlayer.job2.label or xPlayer.job2.name) or nil,
            },
            killer = killerInfo,
            reason = deathreason,
            weapon = death,
            time = os.time(),
            -- Compat ancien format
            killedPlayer = "("..xPlayer.idunique..") "..xPlayer.getName(),
            playerName = killerInfo.idu and ("("..killerInfo.idu..") "..(killerInfo.name or "?")) or "Aucun",
            loadout = death,
        })
    else
        PlayerIsDead[xPlayer.source] = { isDead = 0 }
    end
end)

RegisterNetEvent('EMS:RevivePlayer', function(target)
    if target == -1 then
        ExecuteCommand("ban " .. source .. " 0 Tentative de triche ambulance (0)")
        return
    else
        local xPlayer = ESX.GetPlayerFromId(source)
        local TargetPlayer = ESX.GetPlayerFromId(target)
        if SaveData.json["entreprises"]["Ambulance"][xPlayer.job.name] ~= nil then
            if xPlayer.getInventoryItem('medikit').count >= 1 and TargetPlayer and (TargetPlayer.getAccount("cash").money >= Config.Hospital.Revive.price or TargetPlayer.getAccount("bank").money >= Config.Hospital.Revive.price) then
                xPlayer.removeInventoryItem('medikit', 1)
                if TargetPlayer.getAccount("cash").money >= Config.Hospital.Revive.price then
                    TargetPlayer.removeAccountMoney("cash", Config.Hospital.Revive.price)
                else
                    TargetPlayer.removeAccountMoney("bank", Config.Hospital.Revive.price, {title = 'Frais Médicaux', description = 'Réanimation par ambulancier', category = 'fine'})
                end
                TriggerClientEvent('EMS:ReviveClientPlayer', target)
                ExecuteCommand('heal '..target)
                if PlayerIsDead[target] then
                    PlayerIsDead[target].isDead = 0
                end
                xPlayer.showNotification('Vous avez réanimer un joueurs')
                TargetPlayer.showNotification('Vous avez été réanimer par un medecin.')
                --AddMoneyToSociety("ambulance", "cash", 3000)
                SocietyCache[xPlayer.job.name].data["accounts"].cash = SocietyCache[xPlayer.job.name].data["accounts"].cash+Config.Hospital.Revive.society_reward
                xPlayer.addAccountMoney('bank', Config.Hospital.Revive.employed_reward, {title = 'Prime Ambulancier', description = 'Réanimation effectuée', category = 'salary'})
            else
                if xPlayer.getInventoryItem('medikit').count < 1 then
                    xPlayer.showNotification('Vous n\'avez pas les outils nécéssaire.')
                else
                    xPlayer.showNotification('Cette personne n\'a pas l\'argent nécéssaire ('..Config.Hospital.Revive.price..'$).')
                end
            end
        else
            ExecuteCommand("ban " .. source .. " 0 Tentative de triche ambulance (1)")
            return
        end
    end
end)

RegisterNetEvent('EMS:HealPlayer', function(target)
    if target == -1 then
        ExecuteCommand("ban " .. source .. " 0 Tentative de triche ambulance (2)")
        return
    else
        local xPlayer = ESX.GetPlayerFromId(source)
       if SaveData.json["entreprises"]["Ambulance"][xPlayer.job.name] ~= nil then
            if xPlayer.getInventoryItem('bandage').count >= 2 then
                xPlayer.removeInventoryItem('bandage', 2)
                TriggerClientEvent('EMS:HealClientPlayer', target)
                xPlayer.showNotification('Vous avez soigner un joueurs')
                local TargetPlayer = ESX.GetPlayerFromId(target)
                TargetPlayer.showNotification('Vous avez été soigner par un medecin.')
            else
                xPlayer.showNotification('Vous n\'avez pas les outils nécéssaire.')
            end
        else
            ExecuteCommand("ban " .. source .. " 0 Tentative de triche ambulance (3)")
            return
        end
    end
end)

RegisterNetEvent('EMS:Ouvert', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local xPlayers = ESX.GetPlayers()
    if SaveData.json["entreprises"]["Ambulance"][xPlayer.job.name] ~= nil then
        for i=1, #xPlayers, 1 do
            local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
            TriggerClientEvent('esx:showAdvancedNotification', xPlayers[i], 'EMS', 'Informations', 'Un EMS est en service ! Votre santé avant tout !', 'CHAR_CALL911', 7, "ems")
        end
    else
        ExecuteCommand("ban " .. source .. " 0 Tentative de triche ambulance (4)")
    end
end)

RegisterNetEvent('EMS:Fermer', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local xPlayers    = ESX.GetPlayers()
    if SaveData.json["entreprises"]["Ambulance"][xPlayer.job.name] ~= nil then
        for i=1, #xPlayers, 1 do
            local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
            TriggerClientEvent('esx:showAdvancedNotification', xPlayers[i], 'EMS', 'Informations', 'Un EMS a quitté son service ! ', 'CHAR_CALL911', 7, "ems")
        end
    else
        ExecuteCommand("ban " .. source .. " 0 Tentative de triche ambulance (5)")
    end
end)



RegisterNetEvent('Null:RetreiveIsDead', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    MySQL.Async.fetchAll('SELECT * FROM `visdead` WHERE `license` = @license', {
        ['@license'] = xPlayer.identifier
    }, function(result)
        if result[1] then
            if not PlayerIsDead[xPlayer.source] then
                PlayerIsDead[xPlayer.source] = {}
                PlayerIsDead[xPlayer.source].isDead = 1
            end
            TriggerClientEvent('Null:PlayerIsDead', xPlayer.source)
            xPlayer.showNotification('Vous avez déconnecter en étant mort, Veuillez appelez les EMS.')
        else
            if not PlayerIsDead[xPlayer.source] then
                PlayerIsDead[xPlayer.source] = {}
                PlayerIsDead[xPlayer.source].isDead = 0
            end
        end
    end)
    if SaveData.json["entreprises"]["Ambulance"][xPlayer.job.name] ~= nil then
        IsInServiceEMS[xPlayer.source] = {}
        IsInServiceEMS[xPlayer.source].inService = false
    end
end)

local AppelsEMSList = {}
local CountAppel = 0
RegisterNetEvent('Null:CreateEmsSignal', function()
    local xPlayer = ESX.GetPlayerFromId(source)

    if AppelsEMSList[xPlayer.source] then
        return xPlayer.showNotification('Vous avez déjà un appel en cours')
    else
        AppelsEMSList[xPlayer.source] = {}
        AppelsEMSList[xPlayer.source].position = GetEntityCoords(GetPlayerPed(source))
        local date = os.date('*t')
        AppelsEMSList[xPlayer.source].status = 0
        CountAppel = CountAppel+1
        AppelsEMSList[xPlayer.source].numbers = CountAppel
        AppelsEMSList[xPlayer.source].heures = math.floor(date.hour)
        AppelsEMSList[xPlayer.source].minutes = date.min
        AppelsEMSList[xPlayer.source].secondes = date.sec
        AppelsEMSList[xPlayer.source].src = xPlayer.source
        AppelsEMSList[xPlayer.source].raison = 'Une personne est inconsciente'
        null.DebugPrint("Create EMS Signal : "..xPlayer.source)
        local PlayersInJobs = ESX.GetJobsTypePlayers('ambulance')
        for k,v in pairs(PlayersInJobs) do 
            local xPlayers = ESX.GetPlayerFromId(k)
            if (xPlayers) then
                xPlayers.showNotification('Un nouvelle appel à été reçu.')
                null.DebugPrint("Notif EMS for signal ("..k..")")
                TriggerClientEvent('Null:UpdateTableSignalEms', k, AppelsEMSList)
            end
        end
    end
end)

RegisterNetEvent('EMS:UpdateReport', function(AppelsEms, value)
    local xPlayer = ESX.GetPlayerFromId(source)
    if value then
        AppelsEMSList[AppelsEms].status = 1
        AppelsEMSList[AppelsEms].EMS = xPlayer.identifier
        AppelsEMSList[AppelsEms].EMSName = xPlayer.getName()
        AppelsEMSList[AppelsEms].EMS_SRC = xPlayer.source
        local PlayersInJobs = ESX.GetJobsTypePlayers('ambulance')
        for k,v in pairs(PlayersInJobs) do 
            TriggerClientEvent('Null:UpdateTableSignalEms', k, AppelsEMSList)
        end
    else
        AppelsEMSList[AppelsEms] = nil
        local PlayersInJobs = ESX.GetJobsTypePlayers('ambulance')
        for k,v in pairs(PlayersInJobs) do 
            TriggerClientEvent('Null:UpdateTableSignalEms', k, AppelsEMSList)
        end
    end
end)

RegisterNetEvent('EMS:InformPatient', function(target)
    if target == -1 then
        ExecuteCommand("ban " .. source .. " 0 Tentative de triche ambulance (6)")
        return
    else
        local xPlayer = ESX.GetPlayerFromId(target)
        distance = #(GetEntityCoords(GetPlayerPed(source)) - AppelsEMSList[xPlayer.source].position)
        xPlayer.showNotification('Un medecin est en route (~g~'..math.floor(distance)..'m~s~)')
    end
end)

RegisterNetEvent('Null:RespawnHopital', function(Freekill, SID, UID)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    AppelsEMSList[src] = nil
    local best = Config.Hospital.Respawn[1]
    if best == nil then best = vector4(-456.783081, -1024.475098, 33.689308, 173.3725738525391) end
    local coords = xPlayer.getCoords()
    local lastDistance = #(vector3(coords.x, coords.y, coords.z) - vector3(best.x, best.y, best.z))
    for k,v in pairs(Config.Hospital.Respawn) do
        local distance = #(vector3(coords.x, coords.y, coords.z) - vector3(v.x, v.y, v.z))
        if distance < lastDistance then
            best = v
            lastDistance = distance
        end
    end
    if best == nil then best = vector4(-456.783081, -1024.475098, 33.689308, 173.3725738525391) end
    SetEntityCoords(GetPlayerPed(src), vector3(best.x, best.y, best.z))
    SetEntityHeading(GetPlayerPed(src), best.w)
    xPlayer.showNotification('Vous avez été réanimer à l\'hôpital.')
    TriggerClientEvent("ata:client:update", src, { time = 10, type = 1 })
    if PlayerIsDead[src] then
        PlayerIsDead[src].isDead = 0
    end
    if SaveData.json["entreprises"]["Police"][xPlayer.getJob().name] == nil then
        for i = 1, #xPlayer.loadout, 1 do
            if not ESX.ContribWeapon(xPlayer.loadout[i].name) and not xPlayer.loadout[i].permanent then 
                xPlayer.removeWeapon(xPlayer.loadout[i].name)
            end
        end
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if (xPlayer) then
        if SaveData.json["entreprises"]["Ambulance"][xPlayer.job.name] ~= nil then
            for k,v in pairs(AppelsEMSList) do 
                if v.EMSName == xPlayer.getName() then 
                    AppelsEMSList[v.src] = nil
                    local PlayersInJobs = ESX.GetJobsTypePlayers('ambulance')
                    for k,v in pairs(PlayersInJobs) do 
                        TriggerClientEvent('Null:UpdateTableSignalEms', k, AppelsEMSList)
                    end
                end
            end
        end
        if PlayerIsDead[xPlayer.source] then
            if PlayerIsDead[xPlayer.source].isDead == 1 then
                MySQL.Async.fetchAll('SELECT * FROM `visdead` WHERE `license` = @license', {
                    ['@license'] = xPlayer.identifier
                }, function(result)
                    if not result[1] then
                        MySQL.Async.execute('INSERT INTO visdead (license) VALUES (@license)', {
                            ['@license'] = xPlayer.identifier,
                        }, function() end)
                    end
                end)
                local name = GetPlayerName(src)
                local ip = GetPlayerEndpoint(src)
                local ping = GetPlayerPing(src)
                local discord, license = GetDiscordInformations(src)
                local raison = reason
                if reason == 'Exiting' then
                    raison = 'Déconnexion'
                end
            else
                MySQL.Async.fetchAll('SELECT * FROM `visdead` WHERE `license` = @license', {
                    ['@license'] = xPlayer.identifier
                }, function(result)
                    if result[1] then
                        MySQL.Async.execute('DELETE FROM visdead WHERE `license` = @license', {
                            ['@license'] = xPlayer.identifier
                        })
                    end
                end)
            end
        else
            MySQL.Async.fetchAll('SELECT * FROM `visdead` WHERE `license` = @license', {
                ['@license'] = xPlayer.identifier
            }, function(result)
                if result[1] then
                    MySQL.Async.execute('DELETE FROM visdead WHERE `license` = @license', {
                        ['@license'] = xPlayer.identifier
                    })
                end
            end)
        end
        if AppelsEMSList[xPlayer.source] then
            if AppelsEMSList[xPlayer.source].status == 1 then 
                local EMSPlayer = ESX.GetPlayerFromId(AppelsEMSList[xPlayer.source].EMS_SRC)
                EMSPlayer.showNotification('Le joueur à déconnecter, l\'appel à été annuler')
                TriggerClientEvent('EMS:ForceStopAppel', EMSPlayer.source)
                AppelsEMSList[xPlayer.source] = nil
                local PlayersInJobs = ESX.GetJobsTypePlayers('ambulance')
                for k,v in pairs(PlayersInJobs) do 
                    TriggerClientEvent('Null:UpdateTableSignalEms', k, AppelsEMSList)
                end
            else
                AppelsEMSList[xPlayer.source] = nil
                local PlayersInJobs = ESX.GetJobsTypePlayers('ambulance')
                for k,v in pairs(PlayersInJobs) do 
                    TriggerClientEvent('Null:UpdateTableSignalEms', k, AppelsEMSList)
                end
            end
        end
        if atatime[xPlayer.source] ~= nil then
            if atatime[xPlayer.source] > 0 then
    
            else
                atatime[xPlayer.source] = nil
            end
        end
    end
end)

RegisterNetEvent('EMS:Service', function(value)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["entreprises"]["Ambulance"][xPlayer.job.name] ~= nil then
        if value then
            if not IsInServiceEMS[xPlayer.source] then
                IsInServiceEMS[xPlayer.source] = {}
                IsInServiceEMS[xPlayer.source].inService = true
            else
                IsInServiceEMS[xPlayer.source].inService = true
            end
        else
            if not IsInServiceEMS[xPlayer.source] then
                IsInServiceEMS[xPlayer.source] = {}
                IsInServiceEMS[xPlayer.source].inService = false
            else
                IsInServiceEMS[xPlayer.source].inService = false
            end
        end
    end
end)


RegisterNetEvent('PharmaPublique:GetinfosPly', function(bool)
    TriggerClientEvent('PharmaPublique:SendState', -1, bool)
end)

RegisterCommand('reviver', function(source,args)
    local source = source;
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= 'user' then 
        if not xPlayer.getStaffMode() then return end
        if args[1] and tonumber(args[1]) ~= nil then
            local coordsStaff = GetEntityCoords(GetPlayerPed(source))
            for k,v in pairs(GetPlayers()) do
                local xPlayers = ESX.GetPlayerFromId(v)
                local coordsSpecial = #(coordsStaff - GetEntityCoords(GetPlayerPed(v)))
                if coordsSpecial <= tonumber(args[1]) then
                    TriggerClientEvent('EMS:ReviveClientPlayer', v)
                    xPlayer.showNotification("Vous avez revive tout les joueurs dans une zone de ~r~"..args[1].."~s~ mètres !")
					null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a /revive (/reviver "..args[1].."m) le joueur "..xPlayers.getName().." (U"..xPlayers.getIdunique()..")", "revive", {idunique = xPlayer.getIdunique(), idunique_cible = xPlayers.getIdunique(), name = xPlayer.getName(), name_cible = xPlayers.getName()})
                end
            end
        end
    end
end)

RegisterCommand('healall', function(source,args)
    local source = source;
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() ~= 'user' then 
        if not xPlayer.getStaffMode() then return end
        if args[1] and tonumber(args[1]) ~= nil then
            local coordsStaff = GetEntityCoords(GetPlayerPed(source))
            for k,v in pairs(GetPlayers()) do
                local coordsSpecial = #(coordsStaff - GetEntityCoords(GetPlayerPed(v)))
                if coordsSpecial <= tonumber(args[1]) then
                    ExecuteCommand('heal '..v)
                    xPlayer.showNotification("Vous avez heal tout les joueurs dans une zone de ~r~"..args[1].."~s~ mètres !")
                end
            end
        end
    end
end)


RegisterCommand('revive', function(source,args)
    if source == 0 then 
        if args[1] then 
            local PlayerRevive = ESX.GetPlayerFromIdUnique(args[1])
            if PlayerRevive then 
                if AppelsEMSList[args[1]] then
                    if AppelsEMSList[args[1]].status == 1 then
                        local EMS_Players = ESX.GetPlayerFromId(AppelsEMSList[args[1]].EMS_SRC)
                        EMS_Players.showNotification('Le joueurs qui avait fais l\'appel que vous avez pris à été réanimer par un Staff')
                        TriggerClientEvent("EMS:removeBlip", EMS_Players.source)
                        AppelsEMSList[args[1]] = nil
                        local PlayersInJobs = ESX.GetJobsTypePlayers('ambulance')
                        for k,v in pairs(PlayersInJobs) do 
                            TriggerClientEvent('Null:UpdateTableSignalEms', k, AppelsEMSList)
                        end
                    else
                        AppelsEMSList[args[1]] = nil
                        local PlayersInJobs = ESX.GetJobsTypePlayers('ambulance')
                        for k,v in pairs(PlayersInJobs) do 
                            TriggerClientEvent('Null:UpdateTableSignalEms', k, AppelsEMSList)
                        end
                    end
                end
                TriggerClientEvent('EMS:ReviveClientPlayer', args[1])
                ExecuteCommand('heal '..args[1])
                if PlayerIsDead[args[1]] then
                    PlayerIsDead[args[1]].isDead = 0
                end
                --PlayerRevive.showNotification('Vous avez été réanimer par un staff')
            end
        end
    else
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getGroup() ~= 'user' then
            if not xPlayer.getStaffMode() then return end
            if args[1] ~= nil and args[1] ~= 0 then
                local PlayerRevive = ESX.GetPlayerFromIdUnique(args[1]) 
                if PlayerRevive then 
                    if AppelsEMSList[PlayerRevive.source] then
                        if AppelsEMSList[PlayerRevive.source].status == 1 then
                            local EMS_Players = ESX.GetPlayerFromId(AppelsEMSList[PlayerRevive.source].EMS_SRC)
    
                            EMS_Players.showNotification('Le joueurs qui avait fais l\'appel que vous avez pris à été réanimer par un Staff')
                            TriggerClientEvent("EMS:removeBlip", EMS_Players.source)
                            AppelsEMSList[PlayerRevive.source] = nil
                            local PlayersInJobs = ESX.GetJobsTypePlayers('ambulance')
                            for k,v in pairs(PlayersInJobs) do 
                                TriggerClientEvent('Null:UpdateTableSignalEms', k, AppelsEMSList)
                            end
                        else
                            AppelsEMSList[PlayerRevive.source] = nil
                            local PlayersInJobs = ESX.GetJobsTypePlayers('ambulance')
                            for k,v in pairs(PlayersInJobs) do 
                                TriggerClientEvent('Null:UpdateTableSignalEms', k, AppelsEMSList)
                            end
                        end
                    end
    
                    null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a /revive le joueur "..PlayerRevive.getName().." (U"..PlayerRevive.getIdunique()..")", "revive", {idunique = xPlayer.getIdunique(), idunique_cible = PlayerRevive.getIdunique(), name = xPlayer.getName(), name_cible = PlayerRevive.getName()})
                    TriggerClientEvent('EMS:ReviveClientPlayer', PlayerRevive.source)
                    ExecuteCommand('heal '..PlayerRevive.source)
                    if PlayerIsDead[PlayerRevive.source] then
                        PlayerIsDead[PlayerRevive.source] = 0
                    end
                    --PlayerRevive.showNotification('Vous avez été réanimer par un staff')
                else
                    xPlayer.showNotification('Aucun joueur n\'est connecté avec cette ID Unique')
                end
            else
                if AppelsEMSList[xPlayer.source] then
                    if AppelsEMSList[xPlayer.source].status == 1 then
                        local EMS_Players = ESX.GetPlayerFromId(AppelsEMSList[xPlayer.source].EMS_SRC)

                        EMS_Players.showNotification('Le joueurs qui avait fais l\'appel que vous avez pris à été réanimer par un Staff')
                        TriggerClientEvent("EMS:removeBlip", EMS_Players.source)
                        AppelsEMSList[xPlayer.source] = nil
                        local PlayersInJobs = ESX.GetJobsTypePlayers('ambulance')
                        for k,v in pairs(PlayersInJobs) do 
                            TriggerClientEvent('Null:UpdateTableSignalEms', k, AppelsEMSList)
                        end
                    else
                        AppelsEMSList[xPlayer.source] = nil
                        local PlayersInJobs = ESX.GetJobsTypePlayers('ambulance')
                        for k,v in pairs(PlayersInJobs) do 
                            TriggerClientEvent('Null:UpdateTableSignalEms', k, AppelsEMSList)
                        end
                    end
                end

                null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..") a /revive lui meme", "revive", {idunique = xPlayer.getIdunique(), idunique_cible = xPlayer.getIdunique(), name = xPlayer.getName(), name_cible = xPlayer.getName()})
                TriggerClientEvent('EMS:ReviveClientPlayer', xPlayer.source)
                ExecuteCommand('heal '..xPlayer.source)
                if PlayerIsDead[xPlayer.source] then
                    PlayerIsDead[xPlayer.source] = 0
                end
                xPlayer.showNotification('Vous vous êtes réanimer')
            end
        end
    end
end)

ShopEMS = {
    ["medikit"] = {price = 7500},
    ["bandage"] = {price = 5000}
}

RegisterNetEvent("Null:UseItemsEMS", function(name)
    local xPlayer = ESX.GetPlayerFromId(source)

    if SaveData.json["entreprises"]["Ambulance"][xPlayer.job.name] ~= nil then
        if ShopEMS[name] ~= nil then
            if xPlayer.getAccount('cash').money >= ShopEMS[name].price then
                if xPlayer.canCarryItem(name, 1) then 
                    xPlayer.removeAccountMoney('cash', ShopEMS[name].price)
                    xPlayer.addInventoryItem(name, 1)
                    xPlayer.showNotification("Vous avez acheté x1 "..name.."")
                else 
                    xPlayer.showNotification('Vous êtes trop lourd')
                end
            else
                xPlayer.showNotification("Vous ne disposez pas des fonds nécéssaires")
            end
        end
    end
end)

--[[ESX.RegisterUsableItem('medikit', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeInventoryItem('medikit', 1)

    TriggerClientEvent("Null:UseItemsEMS", source, "medikit")
    xPlayer.showNotification("Vous avez utilisé un kit de soin")
end)

ESX.RegisterUsableItem('bandage', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeInventoryItem('bandage', 1)
    TriggerClientEvent("Null:UseItemsEMS", source, "bandage")
    xPlayer.showNotification("Vous avez utilisé un bandage")
end)]]

Citizen.CreateThread(function()
    while true do 
        Wait(35000)
        for k,v in pairs(PlayerIsDead) do 
            if v.isDead == 1 or v.isDead == true then 
                ExecuteCommand('heal '..k)
            end
        end
    end
end)
