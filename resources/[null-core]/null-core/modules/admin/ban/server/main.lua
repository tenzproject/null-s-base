BanList            = {}
BanListLoad        = false
BanListHistory     = {}
BanListHistoryLoad = false

Text = {
	start         = "La BanList et l'historique a ete charger avec succes",
	starterror    = "ERREUR : La BanList ou l'historique n'a pas ete charger nouvelle tentative.",
	banlistloaded = "La BanList a ete charger avec succes.",
	historyloaded = "La BanListHistory a ete charger avec succes.",
	loaderror     = "ERREUR : La BanList n a pas été charger.",
	cmdban        = "/sqlban (ID) (Durée en jours) (Raison)",
	cmdbanoff     = "/sqlbanoffline (Permid) (Durée en jours) (Raison)",
	cmdhistory    = "/sqlbanhistory (Steam name) ou /sqlbanhistory 1,2,2,4......",
	noreason      = "Raison Inconnue",
	during        = " pendant : ",
	noresult      = "Il n'y a pas autant de résultats !",
	isban         = " a été ban",
	isunban       = " a été déban",
	invalidsteam  =  "Vous devriez ouvrir steam",
	invalidid     = "ID du joueur incorrect",
	invalidbanid  = "ID du ban incorrect",
	invalidname   = "L'ID Unique n'est pas valide",
	invalidtime   = "Duree du ban incorrecte",
	alreadyban    = " étais déja bannie pour : ",
	yourban       = "Vous avez ete ban pour : ",
	yourpermban   = "Vous avez ete ban permanent pour : ",
	youban        = "Vous avez banni : ",
	forr          = " jours. Pour : ",
	permban       = " de facon permanente pour : ",
	timeleft      = ". Il reste : ",
	toomanyresult = "Trop de résultats, veillez être plus précis.",
	day           = " Jours ",
	hour          = " Heures ",
	minute        = " Minutes ",
	by            = "par",
	invalididentifier = "Impossible de vous identifier, merci de réouvrir FiveM.",
	ban           = "Bannir un joueurs qui est en ligne",
	banoff        = "Bannir un joueurs qui est hors ligne",
	bansearch     = "Trouver l'id permanent d'un joueur qui est hors ligne",
	dayhelp       = "Nombre de jours",
	reason        = "Raison du ban",
	permid        = "Trouver l'id permanent avec la commande (sqlsearch)",
	history       = "Affiche tout les bans d'un joueur",
	reload        = "Recharge la BanList et la BanListHistory",
	unban         = "Retirez un ban de la liste",
	steamname     = "(Nom Steam)",
}

CreateThread(LPH_NO_VIRTUALIZE(function()
	while true do
		Wait(1000)
        if BanListLoad == false then
			loadBanList()
			if BanList ~= {} then
				TriggerEvent("null:core:recevieload:BanList", #BanList)
				--print(Text.banlistloaded)
				BanListLoad = true
			else
				--print(Text.starterror)
			end
		end
		if BanListHistoryLoad == false then
			loadBanListHistory()
            if BanListHistory ~= {} then
				TriggerEvent("null:core:recevieload:BanListHistory", #BanListHistory)
				--print(Text.historyloaded)
				BanListHistoryLoad = true
			else
				--print(Text.starterror)
			end
		end
	end
end))

CreateThread(function()
	--[[while Config.MultiServerSync do
		Wait(30000)
		MySQL.Async.fetchAll(
		'SELECT * FROM banlist',
		{},
		function (data)
			if #data ~= #BanList then
			  BanList = {}

			  for i=1, #data, 1 do
				table.insert(BanList, {
					license    = data[i].license,
					identifier = data[i].identifier,
					liveid     = data[i].liveid,
					xblid      = data[i].xblid,
					discord    = data[i].discord,
					playerip   = data[i].playerip,
					reason     = data[i].reason,
					added      = data[i].added,
					expiration = data[i].expiration,
					permanent  = data[i].permanent
				  })
			  end
			loadBanListHistory()
			TriggerClientEvent('BanSql:Respond', -1)
			end
		end
		)
	end]]
end)

RegisterCommand("ban", function(source, args, raw)
	if Showcase and Showcase.IsEnabled() and source ~= 0 then
		local t = ReturnPlayerId(tonumber(args[1]))
		local tsrc = (t and t ~= false) and t.source or nil
		if Showcase.BlocksTarget(source, tsrc) then
			TriggerClientEvent('esx:showNotification', source, "~r~/ban indisponible sur un autre joueur (mode showcase).")
			return
		end
	end
	if source == 0 then
		if ReturnPlayerId(tonumber(args[1])) ~= nil and ReturnPlayerId(tonumber(args[1])) ~= false then
			local target = ESX.GetPlayerFromId(ReturnPlayerId(tonumber(args[1])).source)
			args[1] = target.source
			args[2] = tonumber(args[2])
			cmdban(source, args)
		else
			args[2] = tonumber(args[2])
			args[10] = tonumber(args[1])
			cmdban(source, args)
		end
	else
		local xPlayer = ESX.GetPlayerFromId(source)
		if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
			if ReturnPlayerId(tonumber(args[1])) ~= nil and ReturnPlayerId(tonumber(args[1])) ~= false then
				local target = ESX.GetPlayerFromId(ReturnPlayerId(tonumber(args[1])).source)
				args[1] = target.source
				args[2] = tonumber(args[2])
				cmdban(source, args)
			else
				args[2] = tonumber(args[2])
				args[10] = tonumber(args[1])
				cmdban(source, args)
			end
		end
	end
end, false)

RegisterCommand("unban", function(source, args, raw)
	if source ~= 0 then
		local xPlayer = ESX.GetPlayerFromId(source)

		if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
			cmdunban(source, args)
		end
	else
		cmdunban(source, args)
	end
end, false)

RegisterCommand("search", function(source, args, raw)
	if source == 0 then
		cmdsearch(source, args)
	end
end, false)

RegisterCommand("banoffline", function(source, args, raw)
	if source == 0 then
		cmdbanoffline(source, args)
	end
end, false)

RegisterCommand("banhistory", function(source, args, raw)
	if source == 0 then
		cmdbanhistory(source, args)
	end
end, false)


RegisterCommand("sqlban", function(source, args, raw)
	if source ~= nil then
		local xPlayer = ESX.GetPlayerFromId(source)
		if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
			cmdban(source, args)
		end
	end
end, false)

RegisterCommand("sqlunban", function(source, args, raw)
	if source ~= nil then
		local xPlayer = ESX.GetPlayerFromId(source)

		if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
			cmdunban(source, args)
		end
	end
end, false)


RegisterCommand("sqlsearch", function(source, args, raw)
	if source ~= nil then
		local xPlayer = ESX.GetPlayerFromId(source)

		if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
			cmdsearch(source, args)
		end
	end
end, false)

RegisterCommand("sqlbanoffline", function(source, args, raw)
	if source ~= nil then
		local xPlayer = ESX.GetPlayerFromId(source)

		if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
			cmdbanoffline(source, args)
		end
	end
end, false)

RegisterCommand("sqlbanhistory", function(source, args, raw)
	if source ~= nil then
		local xPlayer = ESX.GetPlayerFromId(source)
		if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
			cmdbanhistory(source, args)
		end
	end
end, false)


--How to use from server side : TriggerEvent("BanSql:ICheat", "Auto-Cheat Custom Reason",TargetId)
RegisterServerEvent('BanSql:ICheat')
AddEventHandler('BanSql:ICheat', function(reason,servertarget)
	local license,identifier,liveid,xblid,discord,playerip,target
	local duree     = 0
	local reason    = reason

	if not reason then reason = "Auto Anti-Cheat" end

	if tostring(source) == "" then
		target = tonumber(servertarget)
	else
		target = source
	end

	if target and target > 0 then
		local ping = GetPlayerPing(target)
	
		if ping and ping > 0 then
			if duree and duree < 365 then
				local sourceplayername = "Anti-Cheat-System"
				local targetplayername = GetPlayerName(target)
					for k,v in ipairs(GetPlayerIdentifiers(target))do
						if string.sub(v, 1, string.len("license:")) == "license:" then
							license = v
						elseif string.sub(v, 1, string.len("steam:")) == "steam:" then
							identifier = v
						elseif string.sub(v, 1, string.len("live:")) == "live:" then
							liveid = v
						elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
							xblid  = v
						elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
							discord = v
						elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
							playerip = v
						end
					end
			
				if duree > 0 then
					ban(target,license,identifier,liveid,xblid,discord,playerip,targetplayername,sourceplayername,duree,reason,0) --Timed ban here
					DropPlayer(target, Text.yourban .. reason)
				else
					ban(target,license,identifier,liveid,xblid,discord,playerip,targetplayername,sourceplayername,duree,reason,1) --Perm ban here
					DropPlayer(target, Text.yourpermban .. reason)
				end
			
			else
				--print("BanSql Error : Auto-Cheat-Ban time invalid.")
			end	
		else
			--print("BanSql Error : Auto-Cheat-Ban target are not online.")
		end
	else
		--print("BanSql Error : Auto-Cheat-Ban have recive invalid id.")
	end
end)

RegisterServerEvent('BanSql:ICheatServer')
AddEventHandler('BanSql:ICheatServer', function(servertarget,reason)
	local license,identifier,liveid,xblid,discord,playerip,target
	local duree     = 0
	local reason    = reason

	if not reason then reason = "Auto Anti-Cheat" end

	if tostring(source) == "" then
		target = tonumber(servertarget)
	else
		target = source
	end

	if target and target > 0 then
		local ping = GetPlayerPing(target)
	
		if ping and ping > 0 then
			if duree and duree < 365 then
				local sourceplayername = "Anti-Cheat-System"
				local targetplayername = GetPlayerName(target)
					for k,v in ipairs(GetPlayerIdentifiers(target))do
						if string.sub(v, 1, string.len("license:")) == "license:" then
							license = v
						elseif string.sub(v, 1, string.len("steam:")) == "steam:" then
							identifier = v
						elseif string.sub(v, 1, string.len("live:")) == "live:" then
							liveid = v
						elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
							xblid  = v
						elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
							discord = v
						elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
							playerip = v
						end
					end
			
				if duree > 0 then
					ban(target,license,identifier,liveid,xblid,discord,playerip,targetplayername,sourceplayername,duree,reason,0) --Timed ban here
					DropPlayer(target, Text.yourban .. reason)
				else
					ban(target,license,identifier,liveid,xblid,discord,playerip,targetplayername,sourceplayername,duree,reason,1) --Perm ban here
					DropPlayer(target, Text.yourpermban .. reason)
				end
			
			else
				--print("BanSql Error : Auto-Cheat-Ban time invalid.")
			end	
		else
			--print("BanSql Error : Auto-Cheat-Ban target are not online.")
		end
	else
		--print("BanSql Error : Auto-Cheat-Ban have recive invalid id.")
	end
end)

RegisterServerEvent('BanSql:CheckMe')
AddEventHandler('BanSql:CheckMe', function()
	doublecheck(source)
end)

-- console / rcon can also utilize es:command events, but breaks since the source isn't a connected player, ending up in error messages
AddEventHandler('bansql:sendMessage', function(source, message)
	if source ~= 0 then
		TriggerClientEvent('chat:addMessage', source, { args = { '^1Banlist ', message } } )
	else
		print(message)
	end
end)                                                        

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
	local _source = source
	local licenseid, playerip = 'N/A', 'N/A'
	licenseid = ESX.GetIdentifierFromId(_source)
	--playerip = GetPlayerEndpoint(_source)

	if not licenseid then
		setKickReason(Text.invalididentifier)
		CancelEvent()
	end
	deferrals.defer()
	Citizen.Wait(0)
	deferrals.update(('Vérification de %s en cours...'):format(playerName))
	Citizen.Wait(1000)

	IsBanned(licenseid, function(isBanned, banData)
		if isBanned then
			if tonumber(banData.permanent) == 1 then
				local card = {
					type = "AdaptiveCard",
					version = "1.3",
					body = {
						{
							type = "Image",
							url = ESX.Config("serverCHAR"),
							size = "Medium",
							horizontalAlignment = "Center",
							separator = false,
						},
						{
							type = "TextBlock",
							text = "Vous êtes banni de "..ESX.Config("serverName"),
							wrap = true,
							horizontalAlignment = "Center",
							separator = false,
							fontType = "Sans",
							size = "ExtraLarge",
							weight = "Default",
							color = "Default",
						},
						{
							type = "TextBlock",
							text = "Date d'expiration : Permanent",
							wrap = true,
							horizontalAlignment = "Center",
							separator = false,
							height = "stretch",
							fontType = "Sans",
							size = "Medium",
							weight = "Default",
							color = "Default",
						},
						{
							type = "TextBlock",
							text = "Raison : "..banData.reason,
							wrap = true,
							horizontalAlignment = "Center",
							separator = false,
							height = "stretch",
							fontType = "Sans",
							size = "Medium",
							weight = "Default",
							color = "Default",
						},
						{
							type = "TextBlock",
							text = "Auteur : "..banData.sourceplayername,
							wrap = true,
							horizontalAlignment = "Center",
							separator = false,
							height = "stretch",
							fontType = "Sans",
							size = "Medium",
							weight = "Default",
							color = "Default",
						},
						{
							type = "TextBlock",
							text = "BAN ID : "..banData.banid,
							wrap = true,
							horizontalAlignment = "Center",
							separator = false,
							height = "stretch",
							fontType = "Sans",
							size = "Medium",
							weight = "Default",
							color = "Default",
						},
						{
							type = "TextBlock",
							text = "Si vous pensez que c'est une erreur faites un ticket sur notre discord : ["..ESX.Config("serverDiscord").."]("..ESX.Config("serverDiscord2")..")",
							wrap = true,
							horizontalAlignment = "Center",
							separator = true,
							spacing= "ExtraLarge",
							height = "stretch",
							fontType = "Sans",
							size = "Small",
							weight = "Default",
							color = "Default",
						},
					},
					--[[backgroundImage= {
						url= "https://media.discordapp.net/attachments/1100450604532383775/1176990919136923760/image.png?ex=66374af6&is=6635f976&hm=03f0da9b5f0bccd8cb3a69b69dd5a882fd598f58320f5e4215705451f0503944&=&format=webp&quality=lossless&width=1168&height=657"
					}]]
				}     
				deferrals.presentCard(card, function(data, rawData)
					deferrals.done()
				end)
			else
				if tonumber(banData.expiration) > os.time() then
					local timeRemaining = tonumber(banData.expiration) - os.time()
					local card = {
						type = "AdaptiveCard",
						version = "1.3",
						body = {
							{
								type = "Image",
								url = ESX.Config("serverCHAR"),
								size = "Medium",
								horizontalAlignment = "Center",
								separator = false,
							},
							{
								type = "TextBlock",
								text = "Vous êtes banni de "..ESX.Config("serverName"),
								wrap = true,
								horizontalAlignment = "Center",
								separator = false,
								fontType = "Sans",
								size = "Large",
								weight = "Default",
								color = "Default",
							},
							{
								type = "TextBlock",
								text = "Date d'expiration : "..SexyTime(timeRemaining),
								wrap = true,
								horizontalAlignment = "Center",
								separator = false,
								height = "stretch",
								fontType = "Sans",
								size = "Medium",
								weight = "Default",
								color = "Default",
							},
							{
								type = "TextBlock",
								text = "Raison : "..banData.reason,
								wrap = true,
								horizontalAlignment = "Center",
								separator = false,
								height = "stretch",
								fontType = "Sans",
								size = "Medium",
								weight = "Default",
								color = "Default",
							},
							{
								type = "TextBlock",
								text = "Auteur : "..banData.sourceplayername,
								wrap = true,
								horizontalAlignment = "Center",
								separator = false,
								height = "stretch",
								fontType = "Sans",
								size = "Medium",
								weight = "Default",
								color = "Default",
							},
							{
								type = "TextBlock",
								text = "BAN ID : "..banData.banid,
								wrap = true,
								horizontalAlignment = "Center",
								separator = false,
								height = "stretch",
								fontType = "Sans",
								size = "Medium",
								weight = "Default",
								color = "Default",
							},
							{
								type = "TextBlock",
								text = "Si vous pensez que c'est une erreur faites un ticket sur notre discord : ["..ESX.Config("serverDiscord").."]("..ESX.Config("serverDiscord2")..")",
								wrap = true,
								horizontalAlignment = "Center",
								separator = true,
								spacing= "ExtraLarge",
								height = "stretch",
								fontType = "Sans",
								size = "Small",
								weight = "Default",
								color = "Default",
							},
						},
						--[[backgroundImage= {
							url= "https://media.discordapp.net/attachments/1100450604532383775/1176990919136923760/image.png?ex=66374af6&is=6635f976&hm=03f0da9b5f0bccd8cb3a69b69dd5a882fd598f58320f5e4215705451f0503944&=&format=webp&quality=lossless&width=1168&height=657"
						}]]
					}     
					deferrals.presentCard(card, function(data, rawData)
						deferrals.done()
					end)
				else
					DeleteBan(licenseid)
				end
			end
		else
			if Config.Ban.ActiveEnterCard then
				CreateThread(function()
					local tempsRestant = 7
					local breakLoop = false
					while true do
						local card = ([==[
	{
		"type": "AdaptiveCard",
		"$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
		"version": "1.6",
		"body": [
			{
				"type": "Container",
				"items": [
					{
						"type": "Table",
						"columns": [
							{
								"width": 0.5
							},
							{
								"width": 2
							}
						],
						"rows": [
							{
								"type": "TableRow",
								"cells": [
									{
										"type": "TableCell",
										"items": [
											{
												"type": "Image",
												"url": "%s",
												"size": "Stretch",
												"width": "150px",
												"height": "150px"
											}
										],
										"verticalContentAlignment": "Center",
										"minHeight": "2px"
									},
									{
										"type": "TableCell",
										"items": [
											{
												"type": "TextBlock",
												"text": "%s",
												"horizontalAlignment": "Left",
												"fontType": "Default",
												"size": "Large",
												"weight": "Bolder",
												"color": "Accent",
												"spacing": "Large",
												"style": "default",
												"wrap": true
											},
											{
												"type": "TextBlock",
												"text": "Un serveur unique, pour une immersion inoubliable.",
												"horizontalAlignment": "Left",
												"wrap": true,
												"size": "Medium",
												"fontType": "Default",
												"weight": "Lighter",
												"isSubtle": false,
												"spacing": "None",
												"style": "default",
												"color": "Default"
											}
										],
										"spacing": "Medium",
										"height": "stretch",
										"minHeight": "100px",
										"horizontalAlignment": "Center",
										"verticalContentAlignment": "Center",
										"rtl": false
									}
								]
							}
						],
						"horizontalAlignment": "Center",
						"showGridLines": false
					},
					{
						"type": "TextBlock",
						"text": "Connexion au serveur en cours... (Temps restant: %s sec)",
						"wrap": true,
						"horizontalAlignment": "Center"
					}
				],
				"minHeight": "5px"
			},
			{
				"type": "ColumnSet",
				"columns": [
					{
						"type": "Column",
						"width": "auto",
						"selectAction": {
							"type": "Action.OpenUrl"
						},
						"items": [
							{
								"type": "ActionSet",
								"actions": [
									{
										"type": "Action.OpenUrl",
										"title": "Ouvrir la Boutique",
										"url": "%s",
										"tooltip": "t",
										"iconUrl": "https://img.icons8.com/?size=100&id=60946&format=png&color=FFFFFF"
									}
								]
							}
						],
						"backgroundImage": {
							"fillMode": "RepeatHorizontally"
						}
					},
					{
						"type": "Column",
						"width": "auto",
						"items": [
							{
								"type": "ActionSet",
								"actions": [
									{
										"type": "Action.OpenUrl",
										"title": "Rejoindre le Discord",
										"url": "%s",
										"iconUrl": "https://static.vecteezy.com/system/resources/previews/018/930/604/original/discord-logo-discord-icon-transparent-free-png.png"
									}
								]
							}
						]
					}
				],
				"bleed": true,
				"style": "default",
				"horizontalAlignment": "Center",
				"spacing": "Medium"
			},
			{
				"type": "TextBlock",
				"text": "© 2025 %s. Tous droits réservés.",
				"wrap": true,
				"isSubtle": true,
				"size": "Small",
				"horizontalAlignment": "Center"
			}
		],
		"minHeight": "70px"
	}
						]==]):format(ESX.Config("serverCHAR"), ESX.Config("serverName"), tempsRestant, ESX.Config("boutiqueLink_points2"), ESX.Config("serverDiscord2"), ESX.Config("serverName"))
						deferrals.presentCard(card)
						if tempsRestant <= 0 then
							if Config.Connection.ActiveMessage or Config.Connection.ActiveMessage == nil then
								deferrals.update(Config.Connection.Message or '✅ Connexion au serveur...')
								Wait(2000)
							end
							deferrals.done()
							breakLoop = true
						end
			
						if breakLoop then break end
						tempsRestant = tempsRestant - 1
						Wait(1000)
					end
				end)
			else
				deferrals.done()
			end
		end
	end)
end)


--[[AddEventHandler('playerConnecting', function (playerName,setKickReason)
	local license,steamID,liveid,xblid,discord,playerip  = "n/a","n/a","n/a","n/a","n/a","n/a"

	for k,v in ipairs(GetPlayerIdentifiers(source))do
		if string.sub(v, 1, string.len("license:")) == "license:" then
			license = v
		elseif string.sub(v, 1, string.len("steam:")) == "steam:" then
			steamID = v
		elseif string.sub(v, 1, string.len("live:")) == "live:" then
			liveid = v
		elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
			xblid  = v
		elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
			discord = v
		elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
			playerip = v
		end
	end

	--Si Banlist pas chargée
	if (Banlist == {}) then
		Citizen.Wait(1000)
	end

	for i = 1, #BanList, 1 do
		print(tostring(license))
		if 
			  ((tostring(BanList[i].license)) == tostring(license) 
			or (tostring(BanList[i].identifier)) == tostring(steamID) 
			or (tostring(BanList[i].liveid)) == tostring(liveid) 
			or (tostring(BanList[i].xblid)) == tostring(xblid) 
			or (tostring(BanList[i].discord)) == tostring(discord) 
			or (tostring(BanList[i].playerip)) == tostring(playerip)) 
		then

			if (tonumber(BanList[i].permanent)) == 1 then

				setKickReason(Text.yourpermban .. BanList[i].reason)
				CancelEvent()
				break

			elseif (tonumber(BanList[i].expiration)) > os.time() then

				local tempsrestant     = (((tonumber(BanList[i].expiration)) - os.time())/60)
				if tempsrestant >= 1440 then
					local day        = (tempsrestant / 60) / 24
					local hrs        = (day - math.floor(day)) * 24
					local minutes    = (hrs - math.floor(hrs)) * 60
					local txtday     = math.floor(day)
					local txthrs     = math.floor(hrs)
					local txtminutes = math.ceil(minutes)
						setKickReason(Text.yourban .. BanList[i].reason .. Text.timeleft .. txtday .. Text.day ..txthrs .. Text.hour ..txtminutes .. Text.minute)
						CancelEvent()
						break
				elseif tempsrestant >= 60 and tempsrestant < 1440 then
					local day        = (tempsrestant / 60) / 24
					local hrs        = tempsrestant / 60
					local minutes    = (hrs - math.floor(hrs)) * 60
					local txtday     = math.floor(day)
					local txthrs     = math.floor(hrs)
					local txtminutes = math.ceil(minutes)
						setKickReason(Text.yourban .. BanList[i].reason .. Text.timeleft .. txtday .. Text.day .. txthrs .. Text.hour .. txtminutes .. Text.minute)
						CancelEvent()
						break
				elseif tempsrestant < 60 then
					local txtday     = 0
					local txthrs     = 0
					local txtminutes = math.ceil(tempsrestant)
						setKickReason(Text.yourban .. BanList[i].reason .. Text.timeleft .. txtday .. Text.day .. txthrs .. Text.hour .. txtminutes .. Text.minute)
						CancelEvent()
						break
				end

			elseif (tonumber(BanList[i].expiration)) < os.time() and (tonumber(BanList[i].permanent)) == 0 then

				deletebanned(license)
				break
			end
		end
	end
end)]]

AddEventHandler('esx:playerLoaded',function(source)
	CreateThread(function()
	Wait(5000)
		local license,steamID,liveid,xblid,discord,playerip
		local playername = GetPlayerName(source)

		for k,v in ipairs(GetPlayerIdentifiers(source))do
			if string.sub(v, 1, string.len("license:")) == "license:" then
				license = v
			elseif string.sub(v, 1, string.len("steam:")) == "steam:" then
				steamID = v
			elseif string.sub(v, 1, string.len("live:")) == "live:" then
				liveid = v
			elseif string.sub(v, 1, string.len("xbl:")) == "xbl:" then
				xblid  = v
			elseif string.sub(v, 1, string.len("discord:")) == "discord:" then
				discord = v
			elseif string.sub(v, 1, string.len("ip:")) == "ip:" then
				playerip = v
			end
		end

		MySQL.Async.fetchAll('SELECT * FROM `baninfo` WHERE `license` = @license', {
			['@license'] = license
		}, function(data)
		local found = false
			for i=1, #data, 1 do
				if data[i].license == license then
					found = true
				end
			end
			if not found then
				MySQL.Async.execute('INSERT INTO baninfo (license,identifier,liveid,xblid,discord,playerip,playername) VALUES (@license,@identifier,@liveid,@xblid,@discord,@playerip,@playername)', 
					{ 
					['@license']    = license,
					['@identifier'] = steamID,
					['@liveid']     = liveid,
					['@xblid']      = xblid,
					['@discord']    = discord,
					['@playerip']   = playerip,
					['@playername'] = playername
					},
					function ()
				end)
			else
				MySQL.Async.execute('UPDATE `baninfo` SET `identifier` = @identifier, `liveid` = @liveid, `xblid` = @xblid, `discord` = @discord, `playerip` = @playerip, `playername` = @playername WHERE `license` = @license', 
					{ 
					['@license']    = license,
					['@identifier'] = steamID,
					['@liveid']     = liveid,
					['@xblid']      = xblid,
					['@discord']    = discord,
					['@playerip']   = playerip,
					['@playername'] = playername
					},
					function ()
				end)
			end
		end)
		--[[if Config.MultiServerSync then
			doublecheck(source)
		end]]
	end)
end)