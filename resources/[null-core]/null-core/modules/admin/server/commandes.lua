local SaveLastTpCoords = {}
local SaveSendMessageToPlayers = {}
RegisterCommand("register", function(source, args, rawCommand)
	local source = source
	if Showcase and Showcase.IsEnabled() and source ~= 0 then
		-- En showcase, /register ne peut viser que soi-même.
		TriggerClientEvent('null:newCreator:open', source, true)
		return
	end
	local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end

    local xTarget = nil
    if args[1] ~= nil then
        local targetData = ReturnPlayerId(args[1])
        if targetData and targetData ~= false then
            xTarget = ESX.GetPlayerFromId(targetData.source)
        end
    end

	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then 
        if xTarget == nil then
            TriggerClientEvent('null:newCreator:open', source, true)
			null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /register", "register", {idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName()})
        else
            TriggerClientEvent('null:newCreator:open', xTarget.source, true)
			null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /register le joueur "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "register", {idunique_auteur = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
        end
	end
end)

RegisterCommand("wipe", function(source, args, rawCommand)
	if Showcase and Showcase.IsEnabled() and source ~= 0 then
		-- En showcase, /wipe ne peut viser que soi-même.
		local xPlayer = ESX.GetPlayerFromId(source)
		if xPlayer then
			if WipeTable then WipeTable(xPlayer.identifier) end
			DropPlayer(source, "Showcase : votre personnage a été wipe. Reconnectez-vous.")
		end
		return
	end
	local source = source
	if source == 0 then
		local xTarget
		if ReturnPlayerId(args[1]) ~= false then
			xTarget = ESX.GetPlayerFromId(ReturnPlayerId(args[1]).source)
		else
			xTarget = nil
		end
		if xTarget == nil then 
			WipeTable(args[1])
		else
			WipeTable(xTarget.identifier)
			DropPlayer(xTarget.source, "Vous avez été Wipe...")
		end
	else
		local xPlayer = ESX.GetPlayerFromId(source)
		local xTarget
		if ReturnPlayerId(args[1]) ~= false then
			xTarget = ESX.GetPlayerFromId(ReturnPlayerId(args[1]).source)
		else
			xTarget = nil
		end
		if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then 
			if xTarget == nil then 
				WipeTable(args[1])
				TriggerClientEvent('chat:addMessage',source, { args = { '^1SYSTEM', 'Vous avez wipe : '..args[1] } })
				null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /wipe le joueur "..args[1], "wipe", {idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName()})
			else
				WipeTable(xTarget.identifier)
				null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /wipe le joueur "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "wipe", {idunique_auteur = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
				DropPlayer(xTarget.source, "Vous avez été Wipe...")
				TriggerClientEvent('chat:addMessage',source, { args = { '^1SYSTEM', 'Vous avez wipe : '..xTarget.getName().." ("..args[1]..")" } })
			end
		end
	end
end)

RegisterCommand("pos", function(source, args, rawCommand)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() == 'user' then return end
	if args[1] and args[2] and args[3] then 
    	xPlayer.setCoords(vec3(tonumber(args[1]), tonumber(args[2]), tonumber(args[3])))
	else
		TriggerClientEvent('chat:addMessage',source, { args = { '^1SYSTEM', "Il manque un vecteur." } })
	end
end)

RegisterCommand("giveata", function(source, args, rawCommand)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(args[1]).source)
	if xPlayer.getGroup() ~= 'user' then 
        if xTarget == nil then return end 
		if args[2] == nil then return end
		if tonumber(args[2]) == 0 then 
			if Ata[xTarget.getIdunique()] ~= nil then 
				Ata[xTarget.getIdunique()] = nil 
				TriggerClientEvent("ata:client:update", xTarget.source, { time = 0, type = 0 })
			end
			return
		end
		Ata[xTarget.getIdunique()] = tonumber(args[2])
		TriggerClientEvent("ata:client:update", xTarget.source, { time = tonumber(args[2]), type = 0 })
	end
end)


RegisterCommand("removeata", function(source, args, rawCommand)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(args[1]).source)
	if xPlayer.getGroup() ~= 'user' then 
        if xTarget == nil then return end 
		if Ata[xTarget.getIdunique()] ~= nil then 
			Ata[xTarget.getIdunique()] = nil 
			TriggerClientEvent("ata:client:update", xTarget.source, { time = 0, type = 0 })
		end
	end
end)


RegisterCommand("tpcoords", function(source, args, rawCommand)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() ~= 'user' then 
		local posx = tonumber(args[1])
		local posy = tonumber(args[2])
		local posz = tonumber(args[3])
		SetEntityCoords(GetPlayerPed(source), posx, posy, posz)
	end
end)

RegisterCommand("tppc", function(source, args, rawCommand)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	local xTarget = nil
	if xPlayer.getGroup() == 'user' then return end
	if null.fct.format.isNumber(args[1]) then 
		local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(args[1]).source)
		if xTarget == nil then return end 
		SaveLastTpCoords[xTarget.getIdunique()] = GetEntityCoords(GetPlayerPed(xTarget.source))
		SetEntityCoords(GetPlayerPed(xTarget.source), vec3(217.236328, -809.206055, 30.718781))
		null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /tppc le joueur "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "tppc", {idunique_auteur = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
	else
		if SaveData.gangs[args[1]] ~= nil then
			SaveLastTpCoords[args[1]] = {}
			for k,v in pairs(SaveData.gangs[args[1]].PlyList) do
				local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(v.idunique).source)
				if xTarget ~= nil then 	
					SaveLastTpCoords[xTarget.getIdunique()] = GetEntityCoords(GetPlayerPed(xTarget.source))
					table.insert(SaveLastTpCoords[args[1]], {source = xTarget.getIdunique(), coords = GetEntityCoords(GetPlayerPed(xTarget.source))})
					SetEntityCoords(GetPlayerPed(xTarget.source), vec3(217.236328, -809.206055, 30.718781))
					TriggerClientEvent('chat:addMessage',source, { args = { '^3STAFF', "Vous avez tppc le joueur: "..xTarget.getName().." (U"..xTarget.getIdunique()..") du groupe: "..args[1] } })
				end
			end
			null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /tppc le groupe "..args[1], "tppc", {idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName()})
		end
	end
end)

RegisterCommand("tpa", function(source, args, rawCommand)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	local xTarget = nil
	if xPlayer.getGroup() == 'user' then return end
	if null.fct.format.isNumber(args[1]) then 
		xTarget = ESX.GetPlayerFromId(ReturnPlayerId(args[1]).source)
		if xTarget == nil then return end
		local posx = tonumber(xTarget.getCoords().x)
		local posy = tonumber(xTarget.getCoords().y)
		local posz = tonumber(xTarget.getCoords().z)
		SaveLastTpCoords[xPlayer.getIdunique()] = GetEntityCoords(GetPlayerPed(xPlayer.source))
		SetEntityCoords(GetPlayerPed(source), posx, posy, posz)
		null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /tpa le joueur "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "goto", {idunique_auteur = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
	end
end)

RegisterCommand("goto", function(source, args, rawCommand)
	local source = source
	local playerPed = GetPlayerPed(source)
	local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(args[1]).source)
	if xPlayer.getGroup() ~= 'user' then 
        if xTarget == nil then return end
		local posx = tonumber(xTarget.getCoords().x)
		local posy = tonumber(xTarget.getCoords().y)
		local posz = tonumber(xTarget.getCoords().z)

		if null.players.instances[xTarget.source] ~= nil and null.players.instances[xTarget.source].number ~= 0 and ((null.players.instances[xPlayer.source] ~= nil and null.players.instances[xPlayer.source].number ~= null.players.instances[xTarget.source].number) or null.players.instances[xPlayer.source] == nil) then
			TriggerClientEvent('chat:addMessage',source, { args = { '^3STAFF', "Ce joueur est dans une instance : "..null.players.instances[xTarget.source].label.. ", vous avez été déplacer dedans."} })
			null.fct.instance.Set(xPlayer.source, null.players.instances[xTarget.source].number, null.players.instances[xTarget.source].label.." (TPA)")
		end

		SaveLastTpCoords[xPlayer.getIdunique()] = GetEntityCoords(playerPed)
		SetEntityCoords(playerPed, posx, posy, posz)
		null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /goto le joueur "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "goto", {idunique_auteur = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
	end
end)

RegisterCommand("gotomain", function(source, args, rawCommand)
	local source = source
	local playerPed = GetPlayerPed(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() ~= 'user' then 
		if null.players.instances[xPlayer.source] ~= nil and null.players.instances[xPlayer.source].number ~= null.players.instances[xTarget.source].number then
			null.fct.instance.Set(xPlayer.source, 0, "Main")
		end
		null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /gotomain", "gotomain", {idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName()})
	end
end)

RegisterCommand("bring", function(source, args, rawCommand)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() == 'user' then return end
	if Showcase and Showcase.IsEnabled() and source ~= 0 then
		local t = ReturnPlayerId(args[1])
		local tsrc = (t and t ~= false) and t.source or nil
		if Showcase.BlocksTarget(source, tsrc) then
			TriggerClientEvent('esx:showNotification', source, "~r~/bring indisponible sur un autre joueur (mode showcase).")
			return
		end
	end
	local posx = tonumber(xPlayer.getCoords().x)
	local posy = tonumber(xPlayer.getCoords().y)
	local posz = tonumber(xPlayer.getCoords().z)
	if null.fct.format.isNumber(args[1]) then 
		local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(args[1]).source)
		SaveLastTpCoords[xTarget.getIdunique()] = GetEntityCoords(GetPlayerPed(xTarget.source))
		SetEntityCoords(GetPlayerPed(ReturnPlayerId(args[1]).source), posx, posy, posz)
		null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /bring le joueur "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "bring", {idunique_auteur = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
	else
		if SaveData.gangs[args[1]] ~= nil then
			SaveLastTpCoords[args[1]] = {}
			for k,v in pairs(SaveData.gangs[args[1]].PlyList) do
				local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(v.idunique).source)
				if xTarget ~= nil then 	
					SaveLastTpCoords[xTarget.getIdunique()] = GetEntityCoords(GetPlayerPed(xTarget.source))
					table.insert(SaveLastTpCoords[args[1]], {source = xTarget.getIdunique(), coords = GetEntityCoords(GetPlayerPed(xTarget.source))})
					SetEntityCoords(GetPlayerPed(xTarget.source), posx, posy, posz)
					TriggerClientEvent('chat:addMessage',source, { args = { '^3STAFF', "Vous avez bring le joueur: "..xTarget.getName().." (U"..xTarget.getIdunique()..") du groupe: "..args[1] } })
				end
			end
			null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /tppc le groupe "..args[1], "tppc", {idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName()})
		end
	end
end)

RegisterCommand("back", function(source, args, rawCommand)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	if Showcase and Showcase.IsEnabled() and source ~= 0 then
		local t = ReturnPlayerId(args[1])
		local tsrc = (t and t ~= false) and t.source or nil
		if Showcase.BlocksTarget(source, tsrc) then
			TriggerClientEvent('esx:showNotification', source, "~r~/back indisponible sur un autre joueur (mode showcase).")
			return
		end
	end
	if xPlayer.getGroup() ~= 'user' then
		if null.fct.format.isNumber(args[1]) then 
			local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(args[1]).source)
			if xTarget == nil then 
				if SaveLastTpCoords[xPlayer.getIdunique()] ~= nil then
					SetEntityCoords(GetPlayerPed(xPlayer.source), SaveLastTpCoords[xPlayer.getIdunique()].x, SaveLastTpCoords[xPlayer.getIdunique()].y, SaveLastTpCoords[xPlayer.getIdunique()].z)
				end
			else
				if SaveLastTpCoords[xTarget.getIdunique()] ~= nil then
					SetEntityCoords(GetPlayerPed(xTarget.source), SaveLastTpCoords[xTarget.getIdunique()].x, SaveLastTpCoords[xTarget.getIdunique()].y, SaveLastTpCoords[xTarget.getIdunique()].z)
				end
			end
		else
			if SaveLastTpCoords[args[1]] ~= nil then
				for k,v in pairs(SaveLastTpCoords[args[1]]) do
					local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(v.source).source)
					if xTarget == nil then goto continue end
					SetEntityCoords(GetPlayerPed(xTarget.source), v.coords.x, v.coords.y, v.coords.z)
					TriggerClientEvent('chat:addMessage',source, { args = { '^3STAFF', "Vous avez back le joueur: "..xTarget.getName().." (U"..xTarget.getIdunique()..") du groupe: "..args[1] } })
					::continue::
				end
			end
		end
	end
end)

RegisterCommand("getid", function(source, args, rawCommand)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() == 'user' then return end
	local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(args[1]).source)
	if not xTarget then 
		TriggerClientEvent('chat:addMessage',source, { args = { '^3STAFF', "UID "..args[1].." n'est pas connecter." } })
		return
	end

	TriggerClientEvent("null:client:copy", source, xTarget.source)
	TriggerClientEvent('chat:addMessage',source, { args = { '^3STAFF', "L'ID Temporaire "..xTarget.source.." a était copier dans votre Presse-papiers."} })


end)

local freeze = {}
RegisterCommand("freeze", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(tonumber(args[1]))
    if xPlayer.getGroup() ~= "user" and xTarget ~= nil then
        if freeze[xTarget.source] == nil then freeze[xTarget.source] = false end
        freeze[xTarget.source] = true
        TriggerClientEvent("MP:freeze", xTarget.source, freeze[xTarget.source])
		null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /freeze le joueur "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "freeze", {idunique_auteur = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
    end
end)

RegisterCommand("unfreeze", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(tonumber(args[1]))
    if xPlayer.getGroup() ~= "user" and xTarget ~= nil then
        if freeze[xTarget.source] == nil then freeze[xTarget.source] = false end
        freeze[xTarget.source] = false
        TriggerClientEvent("MP:freeze", xTarget.source, freeze[xTarget.source])
		null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /unfreeze le joueur "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "freeze", {idunique_auteur = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
    end
end)


RegisterCommand("annonce", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xPlayers = GetPlayers()
	if args[1] == nil then
		ESX.ChatMessage(source, "Mauvais Format", "SYSTEME", { 255, 0, 0 })
	end
	local message = table.concat(args, " ",1)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then 
		for i = 1, #xPlayers, 1 do
			--ESX.ChatMessage(xPlayers[i], message, "ANNONCE", { ESX.Config("r"), ESX.Config("g"), ESX.Config("b") })
			--TriggerClientEvent("null:sendAnnouce", xPlayers[i], message, 5000, "https://i.ibb.co/1YrLkQXj/Annonces.png")
			ESX.ShowAnnouncementToAll(message, 5000)
			--TriggerClientEvent("null:annonce", xPlayer.source, "ANNONCE", message, 5000, {"Event_Start_Text", "GTAO_FM_Events_Soundset"})
		end
		null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /annonce "..message, "annonce", {idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName()})
	end
end) 

RegisterCommand("msgstaff", function(source, args)
	local source = source
	if source == 0 then
		local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(args[1]).source)
		if xTarget == nil then
			return
		end
		local message = table.concat(args, " ", 2)
		ESX.ChatMessage(xTarget.source, message, "CONSOLE", { 255, 0, 0 })
		return
	end
	local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(args[1]).source)
	if args[1] == nil or args[2] == nil then
		ESX.ChatMessage(source, "Mauvais Format : /msgstaff [idunique] [message]", "SYSTEME", { 255, 0, 0 })
		return
	end
    if xPlayer.getGroup() ~= "user" and xTarget ~= nil then
		local message = table.concat(args, " ", 2)
		ESX.ChatMessage(xTarget.source, message, "STAFF", { 255, 0, 0 })
		TriggerClientEvent("esx:showMessage", xTarget.source, "STAFF: "..message)
		TriggerClientEvent("AdminMenu:playSound", xTarget.source)
		if SaveSendMessageToPlayers[xTarget.source] ~= nil then
			SaveSendMessageToPlayers[xTarget.source] = {
				staffidunique = xPlayer.getIdunique(),
				message = message
			}
		else
			ESX.ChatMessage(source, "Message envoyer a "..xTarget.getName(), "SYSTEME", { 0, 0, 0 })
			ESX.ChatMessage(xTarget.source, "Utilisez la commande /rs pour repondre au staff", "STAFF", { 255, 0, 0 })
			SaveSendMessageToPlayers[xTarget.source] = {
				staffidunique = xPlayer.getIdunique(),
				message = message
			}
		end
		null.logs.send("Logs Staff",""..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n /msgstaff ("..message..") le joueur "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "msgstaff", {idunique_auteur = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
	end
end)
RegisterCommand("closemsgstaff", function(source, args)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
    local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(args[1]).source)
	if args[1] == nil then
		ESX.ChatMessage(source, "Mauvais Format : /closemsgstaff [idunique]", "SYSTEME", { 255, 0, 0 })
		return
	end
    if xPlayer.getGroup() ~= "user" and xTarget ~= nil then
		if SaveSendMessageToPlayers[xTarget.source] ~= nil then
			SaveSendMessageToPlayers[xTarget.source] = nil
			ESX.ChatMessage(source, "Ce joueur ne peux maintenant plus repondre a ce message.", "SYSTEME", { 255, 0, 0 })
		else
			ESX.ChatMessage(source, "Ce joueur n'est pas reçu de message.", "SYSTEME", { 255, 0, 0 })
		end
	end
end)

RegisterCommand("rs", function(source, args)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	if SaveSendMessageToPlayers[xPlayer.source] ~= nil then
		local message = table.concat(args, " ", 1)
		if message == nil then
			ESX.ChatMessage(source, "Mauvais Format : /rs [message]", "SYSTEME", { 255, 0, 0 })
			return
		end
		local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(SaveSendMessageToPlayers[xPlayer.source].staffidunique).source)
		if xTarget ~= nil then
			ESX.ChatMessage(xTarget.source, message, "Réponse joueur : "..xPlayer.getName(), { 255, 0, 0 })
			TriggerClientEvent("AdminMenu:playSound", xTarget.source)
			null.logs.send("Logs Staff","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n/rs ("..message..") le Staff : "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "rs-staff", {idunique_auteur = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
		else
			ESX.ChatMessage(source, "Ce staff n'est plus en ligne.", "SYSTEME", { 255, 0, 0 })
			SaveSendMessageToPlayers[xPlayer.source] = nil
		end
	else
		ESX.ChatMessage(source, "Aucun staff ne vous a envoyer de message.", "SYSTEME", { 255, 0, 0 })
	end
end)

RegisterCommand("annoncestaff", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xPlayers = GetPlayers()
	if args[1] == nil then
		ESX.ChatMessage(source, "Mauvais Format", "SYSTEME", { 255, 0, 0 })
	end
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then 
		local message = table.concat(args, " ",1)
		ESX.ShowAnnouncementToStaff(message, 6, "Notification Staff")
		null.logs.send("Logs Staff","Le Staff : "..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n/annoncestaff ("..message..")", "annoncestaff", {idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName()})
	end
end)

RegisterCommand("warn", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    local xPlayers = GetPlayers()
	if args[1] == nil or args[2] == nil then
		ESX.ChatMessage(source, "Mauvais Format", "SYSTEME", { 255, 0, 0 })
	end
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then 
		local message = table.concat(args[2], " ",1)
		local xTarget = ESX.GetPlayerFromId(ReturnPlayerId(args[1]).source)
		ESX.ShowWarningToPlayer(xTarget.source, message, 10, "Avertissement de "..xPlayer.getName())
		null.logs.send("Logs Staff","Le Staff : "..xPlayer.getName().." (U"..xPlayer.getIdunique()..")\n/warn ("..message..") le joueur : "..xTarget.getName().." (U"..xTarget.getIdunique()..")", "warn", {idunique_auteur = xPlayer.getIdunique(), idunique_cible = xTarget.getIdunique(), name = xPlayer.getName(), name_cible = xTarget.getName()})
	end
end)


ESX.AddGroupCommand('kick', "admin", function(source, args, user)
	if args[1] then
		if GetPlayerName(tonumber(args[1])) then
			local target = tonumber(args[1])
			local reason = args
			table.remove(reason, 1)

			if #reason == 0 then
				reason = "[ 📡 Kick ]"
			else
				reason = "Kick : " .. table.concat(reason, " ")
			end

			TriggerClientEvent('chatMessage', source, "SYSTEME", {255, 0, 0}, "Player ^2" .. GetPlayerName(target) .. "^0 has been kicked (^2" .. reason .. "^0)")
			DropPlayer(target, reason)
		else
			TriggerClientEvent('chatMessage', source, "SYSTEME", {255, 0, 0}, "Incorrect player ID!")
		end
	else
		TriggerClientEvent('chatMessage', source, "SYSTEME", {255, 0, 0}, "Incorrect player ID!")
	end
end, {help = "La raison du kick", params = { {name = "userid", help = "The ID of the player"}, {name = "reason", help = "The reason as to why you kick this player"} }})

RegisterCommand('say', function(source, args)
	if source == 0 then
		local argument = table.concat(args, " ")
		TriggerClientEvent('chatMessage', -1, "ANNONCE", {255, 0, 0}, '   '..argument)
	end
end)

RegisterCommand("sc", function(source, args, rawCommand)
    if source == 0 then
        TriggerClientEvent("AdminMenu:sendAdminMessage", -1, 0, "CONSOLE", table.concat(args, " "), 0)
    else
        local xPlayer = ESX.GetPlayerFromId(source)

        if xPlayer.getGroup() ~= "user" then
            local xPlayers = GetPlayers()
            for i = 1, #xPlayers, 1 do
                if xPlayers[i] ~= source then
                    local xTarget = ESX.GetPlayerFromId(xPlayers[i])
                    if xTarget.getGroup() ~= "user" then
                        ESX.ChatMessage(xPlayers[i], table.concat(args, " "), "STAFF : "..xPlayer.getName().." ["..xPlayer.getIdunique().."]", { ESX.Config("r"), ESX.Config("g"), ESX.Config("b") })
                    end
                else
                    ESX.ChatMessage(xPlayers[i], table.concat(args, " "), "STAFF : "..xPlayer.getName().." ["..xPlayer.getIdunique().."]", { ESX.Config("r"), ESX.Config("g"), ESX.Config("b") })
                end
            end
        end
    end
end)

RegisterCommand("setgroup", function(source, args, rawCommand)
    if source == 0 then
        if args[1] == nil or args[2] == nil then return print("Usage: setgroup [id] [group]") end

        if Config.GroupeGrade[string.lower(args[2])] == nil then
            return print("group incorrect - groupes disponibles: " .. table.concat(ESX.Table.GetKeys(Config.GroupeGrade), ", "))
        end 

        local targetId = tonumber(args[1])
        print("Recherche du joueur avec ID: " .. tostring(targetId))
        
        local xTarget = ESX.GetPlayerFromId(targetId)
        
        if not xTarget then
            print("Joueur non trouvé. Joueurs connectés:")
            local xPlayers = ESX.GetPlayers()
            for i = 1, #xPlayers do
                local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
                if xPlayer then
                    print("  - ID: " .. xPlayer.source .. " | Nom: " .. xPlayer.getName())
                end
            end
            return
        end

        print("Joueur trouvé: " .. xTarget.getName() .. " (" .. xTarget.identifier .. ")")

        MySQL.Async.execute("UPDATE `users` SET `permission_group` = @group WHERE `identifier` = @identifier", {
            ['@group'] = args[2],
            ['@identifier'] = xTarget.identifier
        }, function()
            print("Groupe " .. args[2] .. " attribué à " .. xTarget.getName() .. " (" .. xTarget.identifier .. ")")
        end)
        
        xTarget.setGroup(args[2])
        TriggerClientEvent("null:staff:recevieRequestGroup", xTarget.source, {true, xTarget.getGroup()})
        TriggerClientEvent("AdminMenu:reciviestaffrole", xTarget.source, args[2])
        TriggerClientEvent("esx:showNotification", xTarget.source, "Le groupe staff : "..args[2].." vous a été attribué avec succès")
    end
end)