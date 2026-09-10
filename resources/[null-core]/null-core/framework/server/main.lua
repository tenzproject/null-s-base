if not MACROS_INIT then return end

RegisterNetEvent("null:esx:loadname", function(name)
	local src = source
	Citizen.CreateThread(LPH_JIT_MAX(function()
		local attempts = 0
		while ESX.Players[tonumber(src)] == nil do 
			Wait(100)
			attempts = attempts + 1
			if attempts > 100 then return end  -- Timeout après 10 secondes
		end
		if ESX.Players[tonumber(src)].name ~= nil then return end
		ESX.Players[tonumber(src)].name = name
	end))
end)

local lastTimeUpdated = {}
RegisterNetEvent("null:esx:updateplaytime", function()
	local xPlayer = ESX.Players[tonumber(source)]
	if not xPlayer then return end
	local time = os.time()
	if lastTimeUpdated[xPlayer.idunique] ~= nil and (tonumber(time) - tonumber(lastTimeUpdated[xPlayer.idunique])) < (5*50) then return end
	local playtime = xPlayer.getPlayTime() or 0
	xPlayer.setPlayTime(playtime + (5*60))
	lastTimeUpdated[xPlayer.idunique] = os.time()
end)

LoadUser = LPH_JIT_MAX(function(source, identifier, isNew)
	local tasks = {}

	local userData = {
		ip = GetPlayerEndpoint(source),
		guild = GetPlayerGuid(source),
		name = GetPlayerName(source),
		accounts = {},
		job = {},
		job2 = {},
		inventory = {},
		loadout = {},
		license = "",
		steam = "",
		xbl = "",
		discord = "",
		live = "",
		fivem = "",
	}

	for k, v in pairs(GetPlayerIdentifiers(source)) do
		if string.sub(v, 1, string.len('license:')) == 'license:' then
			userData.license = string.gsub(v, "license:", "")
		elseif string.sub(v, 1, string.len('steam:')) == 'steam:' then
			userData.steam = string.gsub(v, "steam:", "")
		elseif string.sub(v, 1, string.len('xbl:')) == 'xbl:' then
			userData.xbl = string.gsub(v, "xbl:", "")
		elseif string.sub(v, 1, string.len('discord:')) == 'discord:' then
			userData.discord = string.gsub(v, "discord:", "")
		elseif string.sub(v, 1, string.len('live:')) == 'live:' then
			userData.live = string.gsub(v, "live:", "")
		elseif string.sub(v, 1, string.len('fivem:')) == 'fivem:' then
			userData.fivem = string.gsub(v, "fivem:", "")
		end
	end

	table.insert(tasks, function(cb)
		MySQL.Async.fetchAll('SELECT discord, fivem, smells, playtime, idunique, streamer, eval_staff, afk_time, afk_point, firstname, lastname, sex, dateofbirth, clothes, ata, permission_group, permission_level, accounts, job, job_grade, job2, job2_grade, inventory, loadout, position FROM users WHERE identifier = @identifier', {
			['@identifier'] = identifier
		}, function(result)
			local selectResult = result[1]
			--[[MySQL.Async.fetchAll('SELECT * FROM vjails WHERE identifier = @identifier',{
				['@identifier'] = identifier,
			}, function(result2)
				if result2[1] ~= nil then
					if result2[1].time <= 0 then
						userData.inJail = false
					else
						userData.inJail = true
					end
				else
					userData.inJail = false
				end]]
				local job, grade = selectResult.job, tostring(selectResult.job_grade)
				local job2, grade2 = selectResult.job2, tostring(selectResult.job2_grade)
				
				if (selectResult.discord == nil and userData.discord == "") or (selectResult.discord == -1 and userData.discord == "") then
					userData.discord = -1
				elseif userData.discord == "" then
					userData.discord = selectResult.discord
				end
				if (selectResult.fivem == nil and userData.fivem == "") or (selectResult.fivem == -1 and userData.fivem == "") then
					userData.fivem = -1
				elseif userData.discord == "" then
					userData.fivem = selectResult.fivem
				end

				if selectResult.smells == nil then
					userData.smells = {}
				else
					userData.smells = json.decode(selectResult.smells)
				end

				if selectResult.playtime == nil then
					userData.playtime = 0
				else
					userData.playtime = selectResult.playtime
				end

				if selectResult.eval_staff == nil then
					userData.eval_staff = -1
				else
					userData.eval_staff = selectResult.eval_staff
				end

				if selectResult.streamer ~= nil then
					if selectResult.streamer == 1 then
						userData.streamer = true
					else
						userData.streamer = false
					end
				else
					userData.streamer = false
				end

				if selectResult.idunique then
					userData.idunique = selectResult.idunique
				else
					userData.idunique = 0
				end

				if selectResult.afk_point then
					userData.afk_point = selectResult.afk_point
				else
					userData.afk_point = 0.00
				end
				if selectResult.afk_time then
					userData.afk_time = selectResult.afk_time
				else
					userData.afk_time = 0
				end

				if selectResult.firstname then
					userData.firstname = selectResult.firstname
				else
					userData.firstname = ""
				end
				if selectResult.lastname then
					userData.lastname = selectResult.lastname
				else
					userData.lastname = ""
				end
				if selectResult.dateofbirth then
					userData.dateofbirth = selectResult.dateofbirth
				else
					userData.dateofbirth = ""
				end
				if selectResult.sex then
					userData.sex = selectResult.sex
				else
					userData.sex = 0
				end
	
				userData.staffmode = false
	
				if selectResult.permission_group then
					userData.permission_group = selectResult.permission_group
				else
					userData.permission_group = Config.DefaultGroup
				end
	
				if selectResult.permission_level ~= nil then
					userData.permission_level = selectResult.permission_level
				else
					userData.permission_level = Config.DefaultLevel
				end
	
				if selectResult.accounts and selectResult.accounts ~= '' then
					local formattedAccounts = json.decode(selectResult.accounts) or {}
	
					for i = 1, #formattedAccounts, 1 do
						if Config.Accounts[formattedAccounts[i].name] == nil then
							print(('[^3WARNING^7] Ignoring invalid account "%s" for "%s"'):format(formattedAccounts[i].name, identifier))
							table.remove(formattedAccounts, i)
						else
							formattedAccounts[i] = {
								name = formattedAccounts[i].name,
								money = formattedAccounts[i].money or 0,
								slot = formattedAccounts[i].slot
							}
						end
					end
	
					userData.accounts = formattedAccounts
				else
					userData.accounts = {}
				end
	
				for name, account in pairs(Config.Accounts) do
					local found = false
	
					for i = 1, #userData.accounts, 1 do
						if userData.accounts[i].name == name then
							found = true
						end
					end
	
					if not found then
						table.insert(userData.accounts, {
							name = name,
							money = account.starting or 0
						})
					end
				end
	
				table.sort(userData.accounts, function(a, b)
					return Config.Accounts[a.name].priority < Config.Accounts[b.name].priority
				end)
	
				if not ESX.DoesJobExist(job, grade) then
					print(('[^3WARNING^7] Le joueur : %s a un job qui n\'existe plus. [job: %s, grade: %s]'):format(identifier, job, grade))
					job, grade = 'unemployed', '0'
				end
	
				if not ESX.DoesJobExist(job2, grade2) then
					print(('[^3WARNING^7] Le joueur : %s a un job2 qui n\'existe plus. [job: %s, grade: %s]'):format(identifier, job2, grade2))
					job2, grade2 = 'unemployed2', '0'
				end
	
				local jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]
				local job2Object, grade2Object = ESX.Jobs[job2], ESX.Jobs[job2].grades[grade2]
	
				userData.job.id = jobObject.id
				userData.job.name = jobObject.name
				userData.job.label = jobObject.label
	
				userData.job.grade = tonumber(grade)
				userData.job.grade_name = gradeObject.name
				userData.job.grade_label = gradeObject.label
				userData.job.grade_salary = gradeObject.salary

				userData.job.skin_male = {}
				userData.job.skin_female = {}
	
				if gradeObject.skin_male then
					userData.job.skin_male = type(gradeObject.skin_male) == 'table' and gradeObject.skin_male or json.decode(gradeObject.skin_male)
				end
	
				if gradeObject.skin_female then
					userData.job.skin_female = type(gradeObject.skin_female) == 'table' and gradeObject.skin_female or json.decode(gradeObject.skin_female)
				end
	
				userData.job2.id = job2Object.id
				userData.job2.name = job2Object.name
				userData.job2.label = job2Object.label
	
				userData.job2.grade = tonumber(grade2)
				userData.job2.grade_name = grade2Object.name
				userData.job2.grade_label = grade2Object.label
				userData.job2.grade_salary = grade2Object.salary
	
				userData.job2.skin_male = {}
				userData.job2.skin_female = {}
	
				if grade2Object.skin_male then
					userData.job2.skin_male = type(grade2Object.skin_male) == 'table' and grade2Object.skin_male or json.decode(grade2Object.skin_male)
				end
	
				if grade2Object.skin_female then
					userData.job2.skin_female = type(grade2Object.skin_female) == 'table' and grade2Object.skin_female or json.decode(grade2Object.skin_female)
				end

				if selectResult.inventory and selectResult.inventory ~= '' then
					local formattedInventory = json.decode(selectResult.inventory) or {}
	
					for i = #formattedInventory, 1, -1 do
						if formattedInventory[i] == nil or formattedInventory[i].name == nil then 
							table.remove(formattedInventory, i)
						elseif ESX.Items[formattedInventory[i].name] == nil then
							print(('[^3WARNING^7] Le joueur : "%s", a un item qui n\'existe plus : "%s"'):format(identifier, formattedInventory[i].name))
							table.remove(formattedInventory, i)
						else
							formattedInventory[i] = {
								name = formattedInventory[i].name,
								count = formattedInventory[i].count,
								label = ESX.Items[formattedInventory[i].name].label or 'Undefined',
								weight = ESX.Items[formattedInventory[i].name].weight or 1.0,
								canRemove = ESX.Items[formattedInventory[i].name].canRemove or false,
								metadata = formattedInventory[i].metadata or {},
								unique = formattedInventory[i].unique or false,
								extra = formattedInventory[i].extra or nil,
								slot = formattedInventory[i].slot,
							}
						end
					end
	
					userData.inventory = formattedInventory
				else
					userData.inventory = {}
				end
	
				table.sort(userData.inventory, function(a, b)
					return ESX.Items[a.name].label <  ESX.Items[b.name].label
				end)
	
				if selectResult.loadout and selectResult.loadout ~= '' then
					local formattedLoadout = json.decode(selectResult.loadout) or {}
	
					for i = 1, #formattedLoadout, 1 do
						local w = formattedLoadout[i]
						if w.components == nil then w.components = {} end
						if w.metadata == nil then w.metadata = {} end
						if w.durability == nil then w.durability = 0 end
						if w.permanent == nil then w.permanent = false end
						w.label = ESX.GetWeaponLabel(w.name)
					end

					userData.loadout = formattedLoadout
				else
					userData.loadout = {}
				end
	
				if selectResult.ata ~= nil and selectResult.ata ~= 0 then
					userData.ata = selectResult.ata
				else
					userData.ata = 0
				end
	
				if selectResult.position and selectResult.position ~= '' then
					local formattedPosition = json.decode(selectResult.position)
					userData.lastPosition = ESX.Vector(formattedPosition)
				else
					userData.lastPosition = Config.DefaultPosition
				end
	
				userData.clothes_equiped = json.decode(selectResult.clothes)
				cb()
			--end)
		end)
	end)

	-- Run Tasks
	Async.parallel(tasks, function(results)
		local xPlayer = CreatePlayer(source, identifier, userData)
		LoadVipFromDatabase(xPlayer.identifier, function(vipData, expired)
			if expired then
				xPlayer.showNotification('~r~Information~s~\nVotre VIP a expiré.')
			end

			xPlayer.vip = vipData

			SyncVipToClient(xPlayer.source, xPlayer.identifier)

			ESX.Players[source] = xPlayer
			xPlayer.set('clothes_equiped', userData.clothes_equiped)

			-- Citizen.CreateThread(LPH_JIT_MAX(function()
			-- 	while ESX.Players[source].name == nil do
			-- 		Wait(100)  -- 10 checks/sec
			-- 	end
			-- 	TriggerEvent('esx:playerLoaded', source, xPlayer)
			-- end))

			--if xPlayer.getAta() < 0 then
			--	xPlayer.setAta(xPlayer.getAta())
			--end

			--MySQL.Async.insert("INSERT INTO `vhistorycodeco` (`idu`, `name`, `type`, `date`) VALUES (@idu, @name, @type, @date)", {['@idu'] = xPlayer.getIdunique(),['@name'] = xPlayer.getName(), ["@type"] = "co", ["date"]=os.date("%Y/%m/%d %X")})
			Cache.Append("deco-reco", {idunique = xPlayer.getIdunique(),name = xPlayer.getName(),type = "co",date = os.date("%Y/%m/%d %X"),})
			--if xPlayer.isStreamer() then
				--if Config.DebugMode then print("1======================================id:setStreamerConnected======================================") end
				--exports["null-core"]:setStreamerConnected(xPlayer.source, true)
				--if Config.DebugMode then print("2======================================id:setStreamerConnected======================================") end
			--end
			xPlayer.triggerEvent('esx:playerLoaded', {
				idunique = xPlayer.idunique,
				identifier = xPlayer.identifier,
				fivem = xPlayer.fivem,
				discord = xPlayer.discord,
				firstname = xPlayer.firstname,
				lastname = xPlayer.lastname,
				dateofbirth = xPlayer.dateofbirth,
				sex = xPlayer.sex,
				group = xPlayer.getGroup(),
				staffmode = false,
				accounts = xPlayer.getAccounts(),
				playtime = xPlayer.getPlayTime(),
				level = xPlayer.getLevel(),
				streamer = xPlayer.isStreamer(),
				inJail = xPlayer.getJail(),
				vip = xPlayer.vip,
				smells = xPlayer.smells,
				clothes_equiped = xPlayer.get('clothes_equiped') or xPlayer.getClothes(),
				--ata = xPlayer.getAta(),
				job = xPlayer.getJob(),
				job2 = xPlayer.getJob2(),
				inventory = xPlayer.getInventory(),
				loadout = xPlayer.getLoadout(),
				lastPosition = xPlayer.getLastPosition(),
				maxWeight = xPlayer.maxWeight
			})

			--xPlayer.triggerEvent('esx:createMissingPickups', ESX.Pickups)
			xPlayer.triggerEvent('esx:initItems', ESX.Items)
			xPlayer.triggerEvent('chat:addSuggestions', ESX.CommandsSuggestions)
		end)
	end)
end)

function RegisterUser(source, identifier)
	ESX.DB.DoesUserExist(identifier, function(exists)
		if exists then
			LoadUser(source, identifier, true)
		else
			ESX.DB.CreateUser(identifier, function()
				LoadUser(source, identifier, false)
			end)
		end
	end)
end

local GameTimer = {}

AddEventHandler('playerConnecting', function(playerName, setKickReason, deferrals)
	local _source = source
	local identifier = ESX.GetIdentifierFromId(_source)
	if identifier then
		if ESX.Config("type") == "WL" then
			if ESX.Config("WL_MDP") == "AUCUN" then
				deferrals.done(_source, "Vous n'êtes pas inscrit sur la whitelist de "..ESX.Config("serverName"))
			else
				
			end
		else
			if ESX.Whitelist.status == true then
				if ESX.Whitelist.GetPlayer(identifier) ~= nil then
					deferrals.done()
				else
					deferrals.done(_source, ESX.Whitelist.reason)
				end
			else
				if ESX.GetPlayerFromIdentifier(identifier) and LPH_OBFUSCATED == true then
					deferrals.done(_source, "Impossible de vous identifier, une personne joue déjà avec votre compte Rockstar sur le Serveur.")
					--deferrals.done()
				else
					deferrals.done()
				end
			end
		end
	else
		deferrals.done(_source, "Impossible de vous identifier, merci de réouvrir FiveM.")
	end
end)

AddEventHandler('playerDropped', function(reason)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	if xPlayer then
		--MySQL.Async.insert("INSERT INTO `vhistorycodeco` (`idu`, `name`, `type`, `date`) VALUES (@idu, @name, @type, @date)", {['@idu'] = xPlayer.getIdunique(),['@name'] = xPlayer.getName(), ["@type"] = "deco", ["date"]=os.date("%Y/%m/%d %X")})
		Cache.Append("deco-reco", {idunique = xPlayer.getIdunique(),name = xPlayer.getName(),type = "deco",date = os.date("%Y/%m/%d %X"),})
		TriggerEvent('esx:playerDropped', _source, xPlayer, reason)
		--if xPlayer.isStreamer() then
			--if Config.DebugMode then print("1======================================id:setStreamerConnected======================================") end
			--exports["null-core"]:setStreamerConnected(xPlayer.source, false)
			--if Config.DebugMode then print("2======================================id:setStreamerConnected======================================") end
		--end
		
		-- Nettoyer les index de lookup AVANT la sauvegarde
		ESX.PlayersByIdentifier[xPlayer.identifier] = nil
		ESX.PlayersByIdUnique[xPlayer.idunique] = nil
		
		-- Nettoyer les tables de rate-limit pour éviter les fuites mémoire
		lastTimeUpdated[xPlayer.idunique] = nil
		GameTimer[_source] = nil
		ESX.PendingAdminRefresh[_source] = nil
		
		ESX.SavePlayer(xPlayer, function()
			ESX.Players[_source] = nil
		end)
	end
end)

RegisterServerEvent('esx:firstJoinProper')
AddEventHandler('esx:firstJoinProper', function()
	local _source = source
	--TriggerEvent("ratelimit", source, "esx:firstJoinProper")

	Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
		local identifier = ESX.GetIdentifierFromId(_source)

		if identifier then
			if ESX.GetPlayerFromIdentifier(identifier) and LPH_OBFUSCATED == true then
				DropPlayer(_source, "Impossible de vous identifier, une personne joue déjà avec votre compte Rockstar sur le Serveur.")
			else
				RegisterUser(_source, identifier)
			end
		else
			DropPlayer(_source, "Impossible de vous identifier, merci de réouvrir FiveM.")
		end
	end))
end)

RegisterServerEvent('esx:giveInventoryItem')
AddEventHandler('esx:giveInventoryItem', function(target, type, itemName, itemCount)
	if GameTimer[source] == nil or GetGameTimer() > GameTimer[source] then
		if target == -1 then 
			ExecuteCommand("ban " .. source .. " 0 Tentative de triche framework (0)") 
			return 
		end
		local _source = source
		local distance = #(GetEntityCoords(GetPlayerPed(_source)) - GetEntityCoords(GetPlayerPed(target)))
		if distance > 50 then 
			ExecuteCommand("ban " .. source .. " 0 Tentative de triche framework (1)") 
			return 
		end 
		local sourceXPlayer = ESX.GetPlayerFromId(_source)
		local targetXPlayer = ESX.GetPlayerFromId(target)
		local author = GetPlayerName(_source)
		local cible = GetPlayerName(target)
	
		if type == 'item_standard' then
			if not ESX.ContribItem(itemName) then 
				local sourceItem = sourceXPlayer.getInventoryItem(itemName)
	
				if itemCount > 0 and sourceItem.count >= itemCount then
					if targetXPlayer.canCarryItem(itemName, itemCount) then
						sourceXPlayer.removeInventoryItem(itemName, itemCount)
						targetXPlayer.addInventoryItem(itemName, itemCount)
		
						sourceXPlayer.showAdvancedNotification("Informations", "Inventaire", _U('gave_item', itemCount, ESX.Items[itemName].label, targetXPlayer.source), 'CHAR_REDSIDE', 1, 7)
						targetXPlayer.showAdvancedNotification("Informations", "Inventaire", _U('received_item', itemCount, ESX.Items[itemName].label, sourceXPlayer.source), 'CHAR_REDSIDE', 1, 7)
						null.logs.item("give", sourceXPlayer, ESX.Items[itemName].label, itemCount, targetXPlayer)
						TriggerEvent("esx:giveitemalert",  author, cible, itemName, itemCount)
						
					else
						sourceXPlayer.showAdvancedNotification("Informations", "Inventaire", _U('ex_inv_lim', targetXPlayer.name), 'CHAR_REDSIDE', 1, 7)
					end
				else
					sourceXPlayer.showAdvancedNotification("Informations", "Inventaire", _U('imp_invalid_quantity'), 'CHAR_REDSIDE', 0, 7)
				end
			else
				sourceXPlayer.showAdvancedNotification("Informations", "Inventaire", 'Vous ne pouvez pas donner cette objet', 'CHAR_REDSIDE', 0, 7)
			end
		elseif type == 'item_account' then
			if itemCount > 0 and sourceXPlayer.getAccount(itemName).money >= itemCount then
				local accountLabel = ESX.GetAccountLabel(itemName)
				
				null.logs.money("give", sourceXPlayer, itemName, itemCount, targetXPlayer)
				sourceXPlayer.removeAccountMoney(itemName, itemCount)
				targetXPlayer.addAccountMoney(itemName, itemCount)
	
				sourceXPlayer.showAdvancedNotification("Informations", "Portefeuille", _U('gave_account_money', ESX.Math.GroupDigits(itemCount), accountLabel, targetXPlayer.source), 'ssss', 9)
				targetXPlayer.showAdvancedNotification("Informations", "Portefeuille", _U('received_account_money', ESX.Math.GroupDigits(itemCount), accountLabel, sourceXPlayer.source), 'ssss', 9)
	
				TriggerEvent("esx:giveaccountalert", author, cible, itemName, itemCount)
			else
				sourceXPlayer.showAdvancedNotification("Informations", "Portefeuille", _U('imp_invalid_amount'), 'ssss', 9)
			end
		elseif type == 'item_weapon' then
			itemName = string.upper(itemName)
	
			if not ESX.ContribWeapon(itemName) then
				if sourceXPlayer.hasWeapon(itemName) then
					local weaponLabel = ESX.GetWeaponLabel(itemName)
		
					if not targetXPlayer.hasWeapon(itemName) then
						local weaponNum, weapon = sourceXPlayer.getWeapon(itemName)
						itemCount = weapon.ammo
		
						sourceXPlayer.removeWeapon(itemName)
						targetXPlayer.addWeapon(itemName, itemCount)
						null.logs.weapon("give", sourceXPlayer, weaponLabel, targetXPlayer)
						
						if itemCount > 0 then
							sourceXPlayer.showAdvancedNotification("Informations", "Armes", _U('gave_weapon_withammo', weaponLabel, itemCount, targetXPlayer.source), 'ssss', 7)
							targetXPlayer.showAdvancedNotification("Informations", "Armes", _U('received_weapon_withammo', weaponLabel, itemCount, sourceXPlayer.source), 'ssss', 7)
							TriggerEvent("esx:giveweaponalert", author, cible, itemName)
						else
							sourceXPlayer.showAdvancedNotification("Informations", "Armes", _U('gave_weapon', weaponLabel, targetXPlayer.source), 'ssss', 7)
							targetXPlayer.showAdvancedNotification("Informations", "Armes", _U('received_weapon', weaponLabel, sourceXPlayer.source), 'ssss', 7)
							TriggerEvent("esx:giveweaponalert", author, cible, itemName)
						end
					else
						sourceXPlayer.showAdvancedNotification("Informations", "Armes", _U('gave_weapon_hasalready', targetXPlayer.name, weaponLabel), 'ssss', 7)
						targetXPlayer.showAdvancedNotification("Informations", "Armes", _U('received_weapon_hasalready', sourceXPlayer.name, weaponLabel), 'ssss', 7)
					end
				end
			else
				sourceXPlayer.showAdvancedNotification("Informations", "Inventaire", 'Vous ne pouvez pas donner cette Arme', 'CHAR_REDSIDE', 0, 7)
			end
		elseif type == 'item_ammo' then
			itemName = string.upper(itemName)
	
			if sourceXPlayer.hasWeapon(itemName) then
				local weaponNum, weapon = sourceXPlayer.getWeapon(itemName)
	
				if targetXPlayer.hasWeapon(itemName) then
					if weapon.ammo >= itemCount then
						sourceXPlayer.removeWeaponAmmo(itemName, itemCount)
						targetXPlayer.addWeaponAmmo(itemName, itemCount)
	
						sourceXPlayer.showNotification(_U('gave_weapon_ammo', itemCount, weapon.label, targetXPlayer.source))
						targetXPlayer.showNotification(_U('received_weapon_ammo', itemCount, weapon.label, sourceXPlayer.source))
					end
				else
					sourceXPlayer.showNotification(_U('gave_weapon_noweapon', targetXPlayer.name))
					targetXPlayer.showNotification(_U('received_weapon_noweapon', sourceXPlayer.source, weapon.label))
				end
			end
		end
		GameTimer[source] = GetGameTimer() + 1000
	else
		ExecuteCommand("ban " .. source .. " 0 Tentative de triche framework (2)")
	end
end)

RegisterServerEvent('esx:dropInventoryItem')
AddEventHandler('esx:dropInventoryItem', function(itemType, itemName, itemCount, accessoryType)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local playerCoords = GetEntityCoords(GetPlayerPed(_source))
	--TriggerEvent("ratelimit", source, "esx:dropInventoryItem")

	if itemType == 'item_standard' then
		if itemCount == nil or itemCount < 1 then
			xPlayer.showAdvancedNotification("Informations", "Inventaire", "Quantité invalide", 'CHAR_REDSIDE', 0, 7)
		else
			local xItem = xPlayer.getInventoryItem(itemName)

			if (itemCount > xItem.count or xItem.count < 1) then
				xPlayer.showAdvancedNotification("Informations", "Inventaire", "Quantité invalide", 'CHAR_REDSIDE', 0, 7)
			else
				null.logs.item("drop", xPlayer, ESX.Items[itemName].label, itemCount)
				xPlayer.removeInventoryItem(itemName, itemCount)

				-- Créer un carton au sol avec l'item
				if CreateGroundItem then
					local items = {{
						name = itemName,
						count = itemCount,
						label = ESX.Items[itemName].label,
						weight = ESX.Items[itemName].weight,
						metadata = xItem.metadata or {},
						unique = xItem.unique or false,
					}}
					CreateGroundItem(playerCoords, items, {}, 0, 0)
				else
				end
				
				xPlayer.showAdvancedNotification("Informations", "Inventaire", ("Vous avez jeter %sx %s."):format(itemCount, ESX.Items[itemName].label), 'CHAR_REDSIDE', 0, 7)
			end
		end
	elseif itemType == 'item_account' then
		if itemCount == nil or itemCount < 1 then
			xPlayer.showAdvancedNotification("Informations", "Portefeuille", _U('imp_invalid_amount'), 'ssss', 9)
		else
			local account = xPlayer.getAccount(itemName)
			local accountLabel = ESX.GetAccountLabel(itemName)

			if (itemCount > account.money or account.money < 1) then
				xPlayer.showAdvancedNotification("Informations", "Portefeuille", _U('imp_invalid_amount'), 'ssss', 9)
			else
				null.logs.money("drop", xPlayer, itemName, itemCount)
				xPlayer.removeAccountMoney(itemName, itemCount)

				-- Créer un carton au sol avec l'argent
				if CreateGroundItem then
					if itemName == "cash" then
						CreateGroundItem(playerCoords, {}, {}, itemCount, 0)
					elseif itemName == "dirtycash" then
						CreateGroundItem(playerCoords, {}, {}, 0, itemCount)
					end
				else
				end
				
				xPlayer.showAdvancedNotification("Informations", "Portefeuille", _U('threw_account', ESX.Math.GroupDigits(itemCount), string.lower(accountLabel)), 'ssss', 9)
			end
		end
	elseif itemType == 'item_weapon' then
		itemName = string.upper(itemName)

		if xPlayer.hasWeapon(itemName) then
			local weaponNum, weapon = xPlayer.getWeapon(itemName)
			null.logs.weapon("drop", xPlayer, weapon.label)
			xPlayer.removeWeapon(itemName)

			-- Créer un carton au sol avec l'arme
			if CreateGroundItem then
				local weapons = {{
					name = itemName,
					label = weapon.label,
					ammo = weapon.ammo,
					metadata = weapon.metadata or {},
				}}
				CreateGroundItem(playerCoords, {}, weapons, 0, 0)
			else
			end
			
			if weapon.ammo > 0 then
				xPlayer.showAdvancedNotification("Informations", "Armes", _U('threw_weapon_ammo', weapon.label, weapon.ammo), 'ssss', 7)
			else
				xPlayer.showAdvancedNotification("Informations", "Armes", _U('threw_weapon', weapon.label), 'ssss', 7)
			end
		end
	elseif itemType == 'item_accessory' then
		if not accessoryType then
			null.DebugPrint("[DROP ACCESSORY] ERREUR: accessoryType est nil, abandon")
			return
		end
		
		local identifier = xPlayer.identifier
		MySQL.Async.fetchAll('SELECT * FROM vclothes WHERE id = @id AND identifier = @identifier', {
			['@id'] = itemName,
			['@identifier'] = identifier
		}, function(result)
			if result and result[1] then
				local clotheRow = result[1]
				local rawData = clotheRow.clothe or clotheRow.data or clotheRow.skin
				local clothData
				if type(rawData) == "string" then
					clothData = json.decode(rawData) or {}
				elseif type(rawData) == "table" then
					clothData = rawData
				else
					clothData = {}
				end
				
				local accLabel = clotheRow.label or clotheRow.name or accessoryType
				
				MySQL.Async.execute('DELETE FROM vclothes WHERE id = @id AND identifier = @identifier', {
					['@id'] = itemName,
					['@identifier'] = identifier
				}, function(rowsChanged)
					if rowsChanged > 0 then
						if _G.InventoryClothes and _G.InventoryClothes.ClearCache then
							_G.InventoryClothes.ClearCache(identifier)
						end
						
						if CreateGroundItem then
							local accessories = {{
								name = itemName,
								type = accessoryType,
								label = accLabel,
								skin = clothData,
							}}
							CreateGroundItem(playerCoords, {}, {}, 0, 0, accessories)
						else
							null.DebugPrint("[DROP ACCESSORY] ERREUR: CreateGroundItem est nil!")
						end
						
						TriggerClientEvent("null:inventory:update", _source)
						xPlayer.showAdvancedNotification("Informations", "Vêtements", ("Vous avez jeté %s"):format(accLabel), 'CHAR_REDSIDE', 0, 7)
					end
				end)
			else
				null.DebugPrint("[DROP ACCESSORY] ERREUR: Vêtement introuvable dans vclothes: ID=" .. tostring(itemName) .. ", identifier=" .. tostring(identifier))
			end
		end)
	end
end)

RegisterServerEvent('esx:useItem')
AddEventHandler('esx:useItem', function(itemName)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xItem = xPlayer.getInventoryItem(itemName)

	--TriggerEvent("ratelimit", source, "esx:useItem")

	if xItem then
		if xItem.count > 0 then
			ESX.UseItem(xPlayer.source, itemName)
			null.logs.item("use", xPlayer, itemName)
		else
			xPlayer.showAdvancedNotification("Informations", "Inventaire", _U('act_imp'), 'CHAR_REDSIDE', 0, 7)
		end
	else
		--print('[es_extended] : ' .. xPlayer.source .. 'tried to use item : ' .. itemName)
	end
end)

RegisterServerEvent('esx:onPickup')
AddEventHandler('esx:onPickup', function(id)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(source)
	local pickup = ESX.Pickups[id]
	local success

	--TriggerEvent("ratelimit", source, "esx:onPickup")

	if pickup then
		if pickup.type == 'item_standard' then
			if xPlayer.canCarryItem(pickup.name, pickup.count) then
				success = true
				xPlayer.addInventoryItem(pickup.name, pickup.count)
			else
				xPlayer.showNotification(_U('threw_cannot_pickup'))
			end
		elseif pickup.type == 'item_account' then
			success = true
			xPlayer.addAccountMoney(pickup.name, pickup.count)
		elseif pickup.type == 'item_weapon' then
			if xPlayer.hasWeapon(pickup.name) then
				xPlayer.showNotification(_U('threw_weapon_already'))
			else
				success = true
				xPlayer.addWeapon(pickup.name, pickup.count)

				for i = 1, #pickup.components, 1 do
					xPlayer.addWeaponComponent(pickup.name, pickup.components[i])
				end
			end
		end

		if success then
			TriggerClientEvent('esx:removePickup', -1, id)
			ESX.Pickups[id] = nil
		end
	end
end)

RegisterServerEvent('esx:positionSaveReady')
AddEventHandler('esx:positionSaveReady', function()
	local xPlayer = ESX.GetPlayerFromId(source)
	--TriggerEvent("ratelimit", source, "esx:positionSaveReady")
	xPlayer.positionSaveReady = true
end)

ESX.RegisterServerCallback('esx:getPlayerData', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	cb({
		identifier = xPlayer.identifier,
		accounts = xPlayer.getAccounts(),
		inventory = xPlayer.getInventory(),
		job = xPlayer.getJob(),
		job2 = xPlayer.getJob2(),
		loadout = xPlayer.getLoadout(),
		lastPosition = xPlayer.getLastPosition()
	})
end)

ESX.RegisterServerCallback('esx:getOtherPlayerData', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)

	cb({
		identifier = xPlayer.identifier,
		accounts = xPlayer.getAccounts(),
		inventory = xPlayer.getInventory(),
		job = xPlayer.getJob(),
		job2 = xPlayer.getJob2(),
		loadout = xPlayer.getLoadout(),
		lastPosition = xPlayer.getLastPosition()
	})
end)

ESX.RegisterServerCallback('esx:getActivePlayers', function(source, cb)
	local players = {}

	for k, v in pairs(ESX.Players) do
		table.insert(players, {id = k, name = GetPlayerName(k)})
	end

	cb(players)
end)

ESX.StartDBSync()
ESX.StartPositionSync()
--ESX.StartPayCheck()

RegisterNetEvent('zgeg:DeleteVehicle')
AddEventHandler('zgeg:DeleteVehicle', function(vehicle, type)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() ~= 'user' then 
		if type then
			for k,v in pairs(vehicle) do 
				local Vehicle = NetworkGetEntityFromNetworkId(v)
	
				DeleteEntity(Vehicle)
			end
		else
			local Vehicle = NetworkGetEntityFromNetworkId(vehicle)
	
			DeleteEntity(Vehicle)
		end
	else
		ExecuteCommand("ban " .. source .. " 0 Tentative de triche framework (4)")
	end
end)


RegisterNetEvent('framework:spawnVehicleLocal')
AddEventHandler('framework:spawnVehicleLocal', function(src, vehicleName)
	local playerSrc = src
	local xPlayer = ESX.GetPlayerFromId(playerSrc)

	if xPlayer.getGroup() ~= 'user' then 
		local PlayerPos = GetEntityCoords(GetPlayerPed(playerSrc))

		TriggerClientEvent('esx:spawnVehicleLocal_client', playerSrc, vehicleName, PlayerPos)
	else
		ExecuteCommand("ban " .. playerSrc .. " 0 Tentative de triche framework (5)")
	end
end)


RegisterCommand("server", function(source, args)
    if source ~= 0 then return end
    
    if args[1] == nil then 
        print([[^4


   _____ ______ _______      ________ _____     _____ ____  __  __ __  __          _   _ _____  ______  _____ 
  / ____|  ____|  __ \ \    / /  ____|  __ \   / ____/ __ \|  \/  |  \/  |   /\   | \ | |  __ \|  ____|/ ____|
 | (___ | |__  | |__) \ \  / /| |__  | |__) | | |   | |  | | \  / | \  / |  /  \  |  \| | |  | | |__  | (___  
  \___ \|  __| |  _  / \ \/ / |  __| |  _  /  | |   | |  | | |\/| | |\/| | / /\ \ | . ` | |  | |  __|  \___ \ 
  ____) | |____| | \ \  \  /  | |____| | \ \  | |___| |__| | |  | | |  | |/ ____ \| |\  | |__| | |____ ____) |
 |_____/|______|_|  \_\  \/   |______|_|  \_\  \_____\____/|_|  |_|_|  |_/_/    \_\_| \_|_____/|______|_____/ 

 ^2Whitelist:							
     ^3server wl enable/disable/get^7 : Active/Désactive/Obtenir la whitelist
     ^3server wl reason [reason]^7 : Définir la raison de la whitelist (message de connexion)

     ^3server wl players add [identifier]^7 : Ajouter une personne a la whitelist
     ^3server wl players remove [identifier]^7 : Supprimer une personne a la whitelist
     ^3server wl players get^7 : Voir les personnes inscrite dans la whitelist
     ^3server wl players get-json^7 : Voir les personnes inscrite dans la whitelist (en json, dans Null/results/whitelist-plys.json)
 ^2Cache:
     ^3server cache autosave^7 disable/enable/get : Désactive/Active/Obtenir la sauvegarde automatique
     ^3server cache reload^7 : Recharge tous les caches
     ^3server cache save^7 : Force la sauvegarde des caches
     ^3server cache refresh^7 : Rafraîchit les caches sans sauvegarder
 ^2Staffs:
     ^3server staffs rank^7 [idunique] [discord-id] : Donne les permissions Helper a un joueur
     ^3server staffs demote^7 [idunique] : Supprime les permissions a un joueur
     ^3server staffs rankup^7 [idunique] : Augemente les permissions d'un joueur (exemple: Helper->Modérateur)
     ^3server staffs unrank^7 [idunique] : Diminue les permissions d'un joueur (exemple: Modérateur->Helper)

     ^3server staffs refresh^7 : Rechargé les staffs
     ^3server staffs switch-week^7 : Reset le classement reports de cette semainee
     ^3server staffs setrank^7 [idunique] [rank] : Défini le rank d'un joueur
     ^3server staffs demote-all^7 : Supprime les permissions de tous les staffs
 ^2Gestion:
     ^3server save players^7 : Force la sauvegarde des joueurs
     ^3server stop^7 : Arrete le serveur
	
]])
        return
    end

    if args[1] == "save" then
        if args[2] == "players" then
            ESX.SavePlayers(function()
				print("^2[Null]^7 Sauvegarde des joueurs terminer")
			end)
        else
            print("^2[Null]^7 Usage: server save players")
        end
	elseif args[1] == "staffs" then
		if args[2] == "rank" then
			if args[3] == nil or args[4] == nil then 
				print("^2[Null]^7 Usage: server staffs rank [idunique] [discord-id]")
				return
			end
			local idunique = tonumber(args[3])
			ESX.GetNameByIdUnique(idunique, function(name)
				if not name then
					print("^2[Null]^7 Usage: server staffs rank [idunique] [discord-id]")
					return
				end

				local discord = tonumber(args[4])
				local group = "helper"
				player = ReturnPlayerId(idunique) or {id = 0}
				xTarget = ESX.GetPlayerFromId(player.id)
				
				if xTarget ~= nil then
					xTarget.setGroup(group)
					TriggerClientEvent("null:staff:recevieRequestGroup", xTarget.source, {true, xTarget.getGroup()})
					AllStaffs[idunique] = {
						idunique = idunique,
						discord = discord,
						name = name,
						permission_group = group,
						date = os.date("%d/%m/%Y | %X"),
						nbrReport = 0,
						nbrReport_take_week = 0,
						nbrReport_close_week = 0,
					}
					MySQL.Async.execute("INSERT INTO staff (idunique, discord, name, permission_group, date) VALUES (@idunique, @discord, @name, @permission_group, @date)",{
						["@idunique"] = idunique,
						["@discord"] = discord,
						["@name"] = xTarget.getName(),
						["@permission_group"] = group,
						["@date"] = os.date("%d/%m/%Y | %X"),
					}, function()
					end)
				else
					MySQL.Async.execute("UPDATE `users` SET `permission_group` = '"..group.."' WHERE `idunique` = '"..idunique.."'", {}, function()  end)
					AllStaffs[idunique] = {
						idunique = idunique,
						discord = discord,
						name = name,
						permission_group = group,
						date = os.date("%d/%m/%Y | %X"),
						nbrReport = 0,
						nbrReport_take_week = 0,
						nbrReport_close_week = 0,
					}
					MySQL.Async.execute("INSERT INTO staff (idunique, discord, name, permission_group, date) VALUES (@idunique, @discord, @name, @permission_group, @date)",{
						["@idunique"] = idunique,
						["@discord"] = discord,
						["@name"] = name,
						["@permission_group"] = group,
						["@date"] = os.date("%d/%m/%Y | %X"),
					}, function()
					end)
				end
				ExecuteCommand("server staffs refresh")
				TriggerClientEvent("null:admin:refreshOnePlayer", -1, idunique, SaveData.Players.Offline[idunique], stafflist[idunique])
				null.logs.send("Add Staff", "Console a ajouté "..name.." en tant que "..group, "addstaff", {idunique = 0, idunique_cible = idunique, name = "Console", name_cible = name})
				print("^2[Null]^7 Le staff : "..name.." (U"..idunique..") a été rajouté avec ^2succès.")
			end)
		elseif args[2] == "demote" then
			if args[3] == nil then 
				print("^2[Null]^7 Usage: server staffs demote [idunique]")
				return
			end
			local idunique = tonumber(args[3])
			local xPlayers = ESX.GetPlayers();
			local isonline = false
			ESX.GetNameByIdUnique(idunique, function(name)
				if not name then
					print("^2[Null]^7 Usage: server staffs demote [idunique]")
					return
				end

				if AllStaffs[idunique] == nil then 
					print("^2[Null]^7 Usage: server staffs demote [idunique]")
					return 
				end

				MySQL.Async.execute("DELETE FROM staff WHERE idunique = @idunique", {['@idunique'] = idunique}, function()  end)
				for i = 1, #xPlayers, 1 do
					local xTarget = ESX.GetPlayerFromId(xPlayers[i]);
					if xTarget.getIdunique() == idunique then
						isonline = true
						xTarget.setGroup("user")
						refreshPlayer(xTarget.source)
						TriggerClientEvent("AdminMenu:reciviestaffrole", xPlayers[i])
						TriggerClientEvent("null:staff:recevieRequestGroup", xTarget.source, {false, xTarget.getGroup()})
					end
				end
				MySQL.Async.execute("UPDATE `users` SET `permission_group` = 'user' WHERE `idunique` = '"..idunique.."'", {}, function()  end)


				print("^2[Null]^7 Le staff : "..name.." (U"..idunique..") a été demote avec ^2succès.")
				ExecuteCommand("server staffs refresh")
			end)
		elseif args[2] == "rankup" then
			if args[3] == nil then 
				print("^2[Null]^7 Usage: server staffs rankup [idunique]")
				return
			end
			local idunique = tonumber(args[3])
			local xPlayers = ESX.GetPlayers();
			local isonline = false
			ESX.GetNameByIdUnique(idunique, function(name)
				if not name then
					print("^2[Null]^7 Usage: server staffs rankup [idunique]")
					return
				end

				if AllStaffs[idunique] == nil then 
					print("^2[Null]^7 Usage: server staffs rankup [idunique]")
					return 
				end

				local oldrank = AllStaffs[idunique].permission_group
				local actualrank = Config.GroupeGrade[AllStaffs[idunique].permission_group].grade
				local newrank = "helper"
				for k,v in pairs(Config.GroupeGrade) do
					if v.grade == actualrank+1 then
						newrank = k
					end
				end


				AllStaffs[idunique].permission_group = newrank
				for i = 1, #xPlayers, 1 do
					local xTarget = ESX.GetPlayerFromId(xPlayers[i]);
					if xTarget.getIdunique() == idunique then
						isonline = true
						xTarget.setGroup(newrank)
						refreshPlayer(xTarget.source)
						TriggerClientEvent("AdminMenu:reciviestaffrole", xPlayers[i])
						TriggerClientEvent("null:staff:recevieRequestGroup", xTarget.source, {true, xTarget.getGroup()})
					end
				end
				MySQL.Async.execute("UPDATE `staff` SET `permission_group` = '"..newrank.."' WHERE `idunique` = '"..idunique.."'", {}, function()  end)
				print("^2[Null]^7 Le staff : "..name.." (U"..idunique..") a été rankup : "..newrank.." (avant: "..oldrank..") avec ^2succès.")
			end)
		elseif args[2] == "unrank" then
			if args[3] == nil then 
				print("^2[Null]^7 Usage: server staffs unrank [idunique]")
				return
			end

			local idunique = tonumber(args[3])
			local xPlayers = ESX.GetPlayers();
			local isonline = false
			ESX.GetNameByIdUnique(idunique, function(name)
				if not name then
					print("^2[Null]^7 Usage: server staffs unrank [idunique]")
					return
				end

				if AllStaffs[idunique] == nil or AllStaffs[idunique].permission_group == "user" then 
					print("^2[Null]^7 Usage: server staffs unrank [idunique]")
					return 
				end

				local oldrank = AllStaffs[idunique].permission_group
				if oldrank == "helper" then
					ExecuteCommand("server staffs demote "..idunique)
					return
				end
				local actualrank = Config.GroupeGrade[AllStaffs[idunique].permission_group].grade
				local newrank = "helper"
				for k,v in pairs(Config.GroupeGrade) do
					if v.grade == actualrank-1 then
						newrank = k
					end
				end

				AllStaffs[idunique].permission_group = newrank
				for i = 1, #xPlayers, 1 do
					local xTarget = ESX.GetPlayerFromId(xPlayers[i]);
					if xTarget.getIdunique() == idunique then
						isonline = true
						xTarget.setGroup(newrank)
						refreshPlayer(xTarget.source)
						TriggerClientEvent("AdminMenu:reciviestaffrole", xPlayers[i])
						TriggerClientEvent("null:staff:recevieRequestGroup", xTarget.source, {true, xTarget.getGroup()})
					end
				end
				MySQL.Async.execute("UPDATE `staff` SET `permission_group` = '"..newrank.."' WHERE `idunique` = '"..idunique.."'", {}, function()  end)
				print("^2[Null]^7 Le staff : "..name.." (U"..idunique..") a été unrank : "..newrank.." (avant: "..oldrank..") avec ^2succès.")
			end)
		elseif args[2] == "switch-week" then
			for k,v in pairs(AllStaffs) do
				AllStaffs[v.idunique].nbrReport_take_week = 0
				AllStaffs[v.idunique].nbrReport_close_week = 0
				MySQL.Async.execute("UPDATE `staff` SET `nbrReport_take_week` = '0' WHERE `idunique` = '"..v.idunique.."'", {}, function()  end)
				MySQL.Async.execute("UPDATE `staff` SET `nbrReport_close_week` = '0' WHERE `idunique` = '"..v.idunique.."'", {}, function()  end)
			end
			print("^2[Null]^7 Classement de la semaine reset avec ^2succès.")
		elseif args[2] == "demote-all" then
			for k,v in pairs(AllStaffs) do
				ExecuteCommand("server staffs demote "..v.idunique)
			end
			print("^2[Null]^7 Demote-all effectuer avec ^2succès.")
		elseif args[2] == "refresh" then
			Citizen.CreateThread(function()
				Wait(1200)
				InitAllStaffs()
				print("^2[Null]^7 Rechargement des staffs terminer")
			end)
		elseif args[2] == "setrank" then
			if args[3] == nil or args[4] == nil then 
				print("^2[Null]^7 Usage: server staffs setrank [idunique] [rank]")
				return
			end
			local idunique = tonumber(args[3])
			local xPlayers = ESX.GetPlayers();
			local isonline = false
			ESX.GetNameByIdUnique(idunique, function(name)
				if not name then
					print("^2[Null]^7 Usage: server staffs setrank [idunique] [rank]")
					return
				end

				if AllStaffs[idunique] == nil then 
					print("^2[Null]^7 Usage: server staffs setrank [idunique] [rank]")
					return 
				end

				local oldrank = AllStaffs[idunique].permission_group
				local newrank = args[4]
				if Config.GroupeGrade[newrank] == nil then
					print("^2[Null]^7 Usage: server staffs setrank [idunique] [rank]")
					return
				end

				AllStaffs[idunique].permission_group = newrank
				for i = 1, #xPlayers, 1 do
					local xTarget = ESX.GetPlayerFromId(xPlayers[i]);
					if xTarget.getIdunique() == idunique then
						isonline = true
						xTarget.setGroup(newrank)
						refreshPlayer(xTarget.source)
						TriggerClientEvent("AdminMenu:reciviestaffrole", xPlayers[i])
						TriggerClientEvent("null:staff:recevieRequestGroup", xTarget.source, {true, xTarget.getGroup()})
					end
				end
				MySQL.Async.execute("UPDATE `staff` SET `permission_group` = '"..newrank.."' WHERE `idunique` = '"..idunique.."'", {}, function()  end)
				print("^2[Null]^7 Le staff : "..name.." (U"..idunique..") a été rankup : "..newrank.." (avant: "..oldrank..") avec ^2succès.")
			end)
		end
	elseif args[1] == "cache" then
		if args[2] == "autosave" then
			if args[3] == "disable" then
				disableCacheSave = false
				print("^2[Null]^7 Sauvegarde automatique ^1désactivée^7")
			elseif args[3] == "enable" then
				disableCacheSave = true
				print("^2[Null]^7 Sauvegarde automatique ^2activée^7")
			elseif args[3] == "get" then
				if disableCacheSave then
					print("^2[Null]^7 Sauvegarde automatique est ^1désactivée^7")
				else
					print("^2[Null]^7 Sauvegarde automatique est ^2activée^7")
				end
			else
				print("^2[Null]^7 Usage: cache autosave disable/enable/get")
			end
		elseif args[2] == "reload" then
			SaveData.functions.SaveAllCacheData()
			SaveData.cacheLoad = false
			for k,v in pairs(SaveData.cache) do
				SaveData.functions.InitCacheData(k, v)
			end
			SaveData.cacheLoad = true
			print("^2[Null]^7 Rechargement des caches effectué")
		elseif args[2] == "save" then
			SaveData.functions.SaveAllCacheData()
			print("^2[Null]^7 Sauvegarde forcée effectuée")
		elseif args[2] == "refresh" then
			SaveData.cacheLoad = false
			for k,v in pairs(SaveData.cache) do
				SaveData.functions.InitCacheData(k, v)
			end
			SaveData.cacheLoad = true
			print("^2[Null]^7 Rafraîchissement des caches effectué")
		end
	elseif args[1] == "wl" then
		if args[2] == "enable" then
			ESX.Whitelist.ChangeStatus(true, function()
				print("^2[Null]^7 Statut de la WhiteList changé en ^2Activé.")
			end)
		elseif args[2] == "disable" then
			ESX.Whitelist.ChangeStatus(false, function()
				print("^2[Null]^7 Statut de la WhiteList changé en ^1Désactivé.")
			end)
		elseif args[2] == "get" then
			if ESX.Whitelist.GetStatus() then
				print("^2[Null]^7 La WhiteList est ^2Activé.")
			else
				print("^2[Null]^7 La WhiteList est ^1Désactivé.")
			end
		elseif args[2] == "reason" then
			local reasn = table.concat(args, " ", 3)
			if reasn then
				ESX.Whitelist.ChangeReason(reasn)
				print("^2[Null]^7 Le message de connexion a été changé en : "..reasn..".")
			end
		elseif args[2] == "players" then
			if args[3] == "add" then
				if not args[4] then
					print("^2[Null]^7 Usage: server wl players add [identifier]")
					return
				end
				ESX.DB.DoesUserExist(args[4], function(exist, result)
					if not exist then
						print("^2[Null]^7 Usage: server wl players add [identifier]")
						return
					end
					ESX.Whitelist.AddPlayer(args[4], result.name, result.idunique)
					print("^2[Null]^7 le joueur : "..result.name.." (U"..result.idunique..") a été ajouté à la Whitelist.")
				end)

			elseif args[3] == "remove" then
				if not args[4] then
					print("^2[Null]^7 Usage: server wl players remove [identifier]")
					return
				end
				ESX.DB.DoesUserExist(args[4], function(exist, result)
					if not exist then
						print("^2[Null]^7 Usage: server wl players remove [identifier]")
						return
					end
					ESX.Whitelist.RemovePlayer(identifier)
					print("^2[Null]^7 le joueur : "..result.name.." (U"..result.idunique..") a été supprimé de la Whitelist.")
				end)
			elseif args[3] == "get" then
				print([[
					
 __          ___    _ _____ _______ ______ _      _____  _____ _______ 
 \ \        / / |  | |_   _|__   __|  ____| |    |_   _|/ ____|__   __|
  \ \  /\  / /| |__| | | |    | |  | |__  | |      | | | (___    | |   
   \ \/  \/ / |  __  | | |    | |  |  __| | |      | |  \___ \   | |   
    \  /\  /  | |  | |_| |_   | |  | |____| |____ _| |_ ____) |  | |   
     \/  \/   |_|  |_|_____|  |_|  |______|______|_____|_____/   |_|   
	
				^2Liste des joueurs :^7

	]])

				local wlplylist = ESX.Whitelist.GetPlayers()
				for k,v in pairs(wlplylist) do
					print(k.." - "..v.name.." (^4"..v.idunique.."^7)")
				end
				
			elseif args[3] == "get-json" then
				SaveResourceFile("null-core", "whitelist-plys.json", json.encode(ESX.Whitelist.GetPlayers()),-1)
				print("^2[Null]^7 La liste des joueurs Whitelist est dans null-core/whitelist-plys.json")
			else
				print("^2[Null]^7 Usage: server wl players add/remove/get/get-json")
			end
		else
			print("^2[Null]^7 Usage: server wl enable/disable/get/reason")
		end
	elseif args[1] == "stop" then
		ESX.ChatMessage(-1, "Le serveur va redémarrer dans quelques secondes.")
		print("^2[Null]^7 Arrêt du serveur en cours...")
		ESX.SyncPosition()
		ESX.SavePlayers()
		SaveAllSociety()
		null.stopServer(function()
			Wait(2000)
			ExecuteCommand("quit")
		end)
    else
        print("^2[Null]^7 Commande invalide. Utilisez ^3server^7 pour voir les commandes disponibles")
    end
end)
