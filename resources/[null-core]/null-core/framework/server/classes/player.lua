if StopBase == nil then return end

function CreatePlayer(source, identifier, userData)
	local self = {}

	self.source = source
	self.identifier = identifier
	self.idunique = userData.idunique
	self.discord = userData.discord
	self.fivem = userData.fivem
 
	self.name = userData.name
	self.firstname = userData.firstname
	self.lastname = userData.lastname
	self.dateofbirth = userData.dateofbirth
	self.sex = userData.sex
	self.permission_group = userData.permission_group
	self.permission_level = userData.permission_level
	self.accounts = userData.accounts
	self.job = userData.job
	self.job2 = userData.job2
	self.inventory = userData.inventory
	self.loadout = userData.loadout
	self.clothes_equiped = userData.clothes_equiped or {}
	self.lastPosition = userData.lastPosition
	self.maxWeight = Config.MaxWeight
	self.ata = userData.ata
	self.playtime = userData.playtime
	self.afk_time = userData.afk_time
	self.afk_point = userData.afk_point
	self.streamer = userData.streamer
	self.smells = userData.smells
	
	self.inJail = userData.inJail
	self.staffmode = false
	self.gamertag = false
	self.vip = nil
	self.instance = 0
	self.freeze = false
	self.enter = true
	self.positionSaveReady = false
	self.suit = nil

	-- Cache JSON pour éviter les json.encode répétés dans SavePlayer
	-- Seuls les champs dirty sont ré-encodés, les autres réutilisent le cache
	local _jsonCache = {
		accounts = nil,
		inventory = nil,
		loadout = nil,
		clothes = nil,
		smells = nil,
		position = nil,
	}
	local _dirty = {
		accounts = true,
		inventory = true,
		loadout = true,
		clothes = true,
		smells = true,
		position = true,
	}

	-- Dirty tracking pour les colonnes scalaires (évite d'UPDATE les 21 colonnes à chaque save)
	local _dirtyScalar = {}

	local function markDirty(field)
		_dirty[field] = true
	end

	-- Helper: nettoie les metadata vides pour réduire la taille JSON
	local function cleanMetadata(meta)
		if meta == nil then return nil end
		if type(meta) ~= 'table' then return nil end
		if next(meta) == nil then return nil end
		return meta
	end

	-- Helper: nettoie les metadata armes (retire le label redondant avec ESX.GetWeaponLabel)
	local function cleanWeaponMetadata(meta)
		if meta == nil then return nil end
		if type(meta) ~= 'table' then return nil end
		if next(meta) == nil then return nil end
		-- Désactiver, car si l'arme a un metadata label, c'est qu'il a était définit par l'user et donc custom
		-- if meta.label then
		-- 	local cleaned = {}
		-- 	for k, v in pairs(meta) do
		-- 		if k ~= 'label' then cleaned[k] = v end
		-- 	end
		-- 	if next(cleaned) == nil then return nil end
		-- 	return cleaned
		-- end
		return meta
	end

	self.getJsonCache = function(field)
		if _dirty[field] then
			if field == 'accounts' then
				_jsonCache.accounts = json.encode(self.getAccounts(true))
			elseif field == 'inventory' then
				-- Minimal: only name, count, metadata (non-empty), unique, extra
				local inv = self.inventory
				local minimal = {}
				for i = 1, #inv do
					local it = inv[i]
					local meta = cleanMetadata(it.metadata)
					local entry = {
						name = it.name,
						count = it.count,
					}
					if meta then entry.metadata = meta end
					if it.unique then entry.unique = true end
					if it.unique and it.extra then entry.extra = it.extra end
					if it.slot then entry.slot = it.slot end
					minimal[i] = entry
				end
				_jsonCache.inventory = json.encode(minimal)
			elseif field == 'loadout' then
				-- Minimal: sans label, sans metadata vide/label-only
				local loadout = self.getLoadout()
				local minimalLoadout = {}
				for k, v in ipairs(loadout) do
					local meta = cleanWeaponMetadata(v.metadata)
					local entry = {
						name = v.name,
						ammo = v.ammo,
					}
					if v.components and #v.components > 0 then entry.components = v.components end
					if v.serialnumber then entry.serialnumber = v.serialnumber end
					if v.permanent then entry.permanent = true end
					if v.durability and v.durability ~= 0 then entry.durability = v.durability end
					if meta then entry.metadata = meta end
					if v.slot then entry.slot = v.slot end
					minimalLoadout[k] = entry
				end
				_jsonCache.loadout = json.encode(minimalLoadout)
			elseif field == 'clothes' then
				_jsonCache.clothes = json.encode(self.get('clothes_equiped'))
			elseif field == 'smells' then
				_jsonCache.smells = json.encode(self.getSmells())
			elseif field == 'position' then
				local lastCoords = ESX.RoundVector(self.getLastPosition())
				_jsonCache.position = json.encode({x = lastCoords.x, y = lastCoords.y, z = lastCoords.z})
			end
			_dirty[field] = false
		end
		return _jsonCache[field]
	end

	self.getDirtyScalar = function()
		return _dirtyScalar
	end

	self.clearDirtyScalar = function()
		_dirtyScalar = {}
	end

	self.isDirtyJson = function(field)
		return _dirty[field] == true
	end

	self.markDirty = markDirty

	-- Cache O(1) pour les accounts
	local accountsCache = {}
	for i, acc in ipairs(self.accounts) do
		accountsCache[acc.name] = acc
	end

	-- Raccourcis directs pour les comptes (références vers accountsCache)
	self.cash = accountsCache["cash"].money
	self.bank = accountsCache["bank"].money
	self.black = accountsCache["dirtycash"].money

	local function syncAccountShortcuts()
		self.cash = accountsCache["cash"].money
		self.bank = accountsCache["bank"].money
		self.black = accountsCache["dirtycash"].money
	end

	-- Cache O(1) pour l'inventaire
	-- local inventoryCache = {}
	-- for i, item in ipairs(self.inventory) do
	-- 	if not ESX.Items[item.name] or not ESX.Items[item.name].unique then
	-- 		inventoryCache[item.name] = { item = item, index = i }
	-- 	end
	-- end

	-- Indexer le joueur dans les tables globales
	ESX.PlayersByIdentifier[identifier] = self
	ESX.PlayersByIdUnique[userData.idunique] = self

	--ExecuteCommand(('add_principal identifier.%s group.%s'):format(self.identifier, self.permission_group))

	self.triggerEvent = function(eventName, ...)
		TriggerClientEvent(eventName, self.source, ...)
	end

	self.chatMessage = function(msg, author, color)
		self.triggerEvent('chat:addMessage', {color = color or {255, 255, 255}, args = {author or 'SYSTEME', msg or ''}})
	end

	self.kick = function(reason)
		DropPlayer(self.source, reason)
	end

	self.set = function(key, value)
		self[key] = value
		if key == "clothes_equiped" then
			self.clothes_equiped = value
			markDirty('clothes')
		end
		ESX.ScheduleAdminRefresh(self.source)
	end

	self.get = function(key)
		return self[key]
	end

	self.isStreamer = function()
		return self.streamer
	end

	self.setStreamer = function(bool)
		self.streamer = bool
		_dirtyScalar['streamer'] = true
	end

	self.setEnter = function(bool)
		self.enter = bool
	end

	self.getEnter = function()
		return self.enter
	end

	
	self.getIdentifier = function()
		return self.identifier
	end

	self.getAfk = function()
		return {
			afk_time = self.afk_time or 0,
			afk_point = self.afk_point or 0,
			time = self.afk_time or 0,
			point = self.afk_point or 0
		}
	end

	self.setAfk = function(time, point)
		self.afk_time = time or 0
		self.afk_point = point or 0
		
		-- Forcer une sauvegarde immédiate
		MySQL.Async.execute('UPDATE users SET afk_time = @afk_time, afk_point = @afk_point WHERE identifier = @identifier', {
			['@afk_time'] = self.afk_time,
			['@afk_point'] = self.afk_point,
			['@identifier'] = self.identifier
		})
	end

	self.getLevel = function()
		return self.permission_level
	end

	self.setPlayTime = function(value)
		self.playtime = value
		_dirtyScalar['playtime'] = true
	end

	self.getPlayTime = function()
		if self.playtime == nil then self.playtime = 0 end
		return self.playtime
	end

	self.setLevel = function(level)
		local lastLevel = permission_level

		if type(level) == "number" then
			self.permission_level = level
			_dirtyScalar['permission_level'] = true

			TriggerEvent('esx:setLevel', self.source, self.permission_level, lastLevel)
			self.triggerEvent('esx:setLevel', self.permission_level, lastLevel)
		end
	end

	self.getGroup = function()
		return self.permission_group
	end

	self.getPermission = function(perm)
		if self.permission_group == "user" then return false end
		if perm == nil then return false end
		perm = string.lower(perm)
		if Config.Admin.RolePermissions and Config.Admin.RolePermissions[self.permission_group] then
			return Config.Admin.RolePermissions[self.permission_group][perm] == true
		end

		local tempConfigPerm = {}
		for k,v in pairs(Config.Admin.PermissionsGrade) do tempConfigPerm[string.lower(k)] = v end

		if tempConfigPerm[perm] == nil then return false end
		if Config.GroupeGrade[self.permission_group] == nil then return false end

		if Config.GroupeGrade[self.permission_group].grade >= tempConfigPerm[perm] then
			return true
		else
			return false
		end
	end

	self.getSmells = function()
		return self.smells
	end
	self.getSmell = function(key)
		return self.smells[key]
	end
	self.setSmell = function(key, value)
		self.smells[key] = value
		markDirty('smells')
		self.triggerEvent("null:esx:smellupdated", key, value)
	end
	self.getSuit = function()
		return self.suit
	end
	self.setSuit = function(value)
		self.suit = value
		self.triggerEvent("null:esx:setSuit", value)
	end

	self.getJail = function()
		return self.inJail
	end

	--[[self.getAta = function()
		return self.ata
	end

	self.setAta = function(time)
		self.ata = time
		TriggerEvent("ata:server:updateCaneByExtended", self.source, time)
	end

	self.setAta2 = function(time)
		self.ata = time
	end]]

	self.getClothes = function()
		return self.clothes_equiped
	end

	self.setGroup = function(group)
		local lastGroup = permission_group

		if ESX.Groups[group] then
			self.permission_group = group
			_dirtyScalar['permission_group'] = true

			for k, v in pairs(ESX.Groups) do
				ExecuteCommand(('remove_principal identifier.%s group.%s'):format(self.identifier, k))
			end

			--ExecuteCommand(('add_principal identifier.%s group.%s'):format(self.identifier, group))

			TriggerEvent('esx:setGroup', self.source, self.permission_group, lastGroup)
			self.triggerEvent('esx:setGroup', self.permission_group, lastGroup)
			ESX.ScheduleAdminRefresh(self.source)
			TriggerEvent("null:staff:requestGroupVerif", tonumber(self.source))
		else
			print(('[^3WARNING^7] Ignoring invalid .setGroup() usage for "%s"'):format(self.identifier))
		end
	end



	-- Optimisé: O(1) au lieu de O(n)
	self.getAccount = function(accountName)
		return accountsCache[accountName]
	end

	-- Optimisé: O(1) au lieu de O(n)
	self.getMoney = function()
		return accountsCache["cash"]
	end
	
	self.updateCoords = function(coords)
		self.coords = {x = ESX.Round(coords.x, 1), y = ESX.Round(coords.y, 1), z = ESX.Round(coords.z, 1), heading = ESX.Round(coords.heading or 0.0, 1)}
	end


	self.setCoords = function(coords)
		self.updateCoords(coords)
		self.triggerEvent('esx:teleport', coords)
	end

	self.setHeading = function(heading)
		self.triggerEvent('esx:head', heading)
	end

	self.setFreeze = function(bool)
		if type(bool) ~= "boolean" then return end
		self.freeze = bool
		self.triggerEvent('esx:freeze', bool)
	end

	self.getAccounts = function(minimal)
		if minimal then
			local minimalAccounts = {}

			for i = 1, #self.accounts, 1 do
				table.insert(minimalAccounts, {
					name = self.accounts[i].name,
					money = self.accounts[i].money,
					slot = self.accounts[i].slot
				})
			end

			return minimalAccounts
		else
			return self.accounts
		end
	end

	self.getInventory = function(minimal)
		if minimal then
			local minimalInventory = {}

			for i = 1, #self.inventory, 1 do
				table.insert(minimalInventory, {
					name = self.inventory[i].name,
					count = self.inventory[i].count,
					metadata = self.inventory[i].metadata,
					unique = self.inventory[i].unique or false,
					extra = ESX.Items[self.inventory[i].name].unique and self.inventory[i].extra or nil,
					slot = self.inventory[i].slot
				})
			end

			return minimalInventory
		else
			return self.inventory
		end
	end

	
    self.syncInventory = function(weight, maxWeight, items, money)
		self.weight, self.maxWeight = weight, maxWeight
		self.inventory = items
		markDirty('inventory')

		if not money then return end
		for accountName, amount in pairs(money) do
			local account = self.getAccount(accountName)

			if account and ESX.Math.Round(account.money) ~= amount then
				account.money = amount
				self.triggerEvent("esx:setAccountMoney", account)
				TriggerEvent("esx:setAccountMoney", self.source, accountName, amount, "Sync account with item")
			end
		end
    end

	self.getLoadout = function()
		return self.loadout
	end

	self.getJob = function()
		return self.job
	end

	self.getJob2 = function()
		return self.job2
	end

	self.getName = function()
		return self.name
	end

	self.getIdunique = function()
		return self.idunique
	end

	self.setName = function(name)
		self.name = name
		_dirtyScalar['name'] = true
	end

	self.getCoords = function()
		local coords = GetEntityCoords(GetPlayerPed(self.source))

		if type(coords) ~= 'vector3' or ((coords.x >= -1.0 and coords.x <= 1.0) and (coords.y >= -1.0 and coords.y <= 1.0) and (coords.z >= -1.0 and coords.z <= 1.0)) then
			coords = self.getLastPosition()
		end

		return coords
	end

	self.getLastPosition = function()
		return self.lastPosition
	end

	self.setLastPosition = function(coords)
		self.lastPosition = coords
		markDirty('position')
	end

	self.setAccountMoney = function(accountName, money)
		money = ESX.Math.Check(ESX.Math.Round(money))
	
		if money >= 0 then
			local account = self.getAccount(accountName)

			if account then
				account.money = money
				markDirty('accounts')
				self.triggerEvent('esx:setAccountMoney', account)
				ESX.ScheduleAdminRefresh(self.source)
				TriggerClientEvent("null:inventory:update", self.source)
			end
		end
	end

	self.setMoney = function(money)
		money = ESX.Math.Check(ESX.Math.Round(money))
	
		accountName = "cash"

		if money >= 0 then
			local account = self.getAccount(accountName)

			if account then
				account.money = money
				markDirty('accounts')
				self.triggerEvent('esx:setAccountMoney', account)
				ESX.ScheduleAdminRefresh(self.source)
				TriggerClientEvent("null:inventory:update", self.source)
			end
		end
	end

	self.addAccountMoney = function(accountName, money)
		money = ESX.Math.Check(ESX.Math.Round(money))
	
		if money > 0 then
			local account = self.getAccount(accountName)

			if account then
				local newMoney = ESX.Math.Check(account.money + money)
				account.money = newMoney
				syncAccountShortcuts()
				markDirty('accounts')
				self.triggerEvent('esx:setAccountMoney', account)
				ESX.ScheduleAdminRefresh(self.source)
				TriggerClientEvent("null:inventory:update", self.source)

				-- Auto-record bank transaction if metadata provided
				if accountName == 'bank' and metadata and Bank and Bank.AddTransaction then
					Bank.AddTransaction(self.source, {
						amount = money,
						title = metadata.title or 'Crédit',
						description = metadata.description or '',
						category = metadata.category or 'other',
					})
				end
			end
		end
	end

	self.addMoney = function(money)
		money = ESX.Math.Check(ESX.Math.Round(money))
		
		accountName = "cash"

		if money > 0 then
			local account = self.getAccount(accountName)

			if account then
				local newMoney = ESX.Math.Check(account.money + money)
				account.money = newMoney
				syncAccountShortcuts()
				markDirty('accounts')
				self.triggerEvent('esx:setAccountMoney', account)
				ESX.ScheduleAdminRefresh(self.source)
				TriggerClientEvent("null:inventory:update", self.source)
			end
		end
	end

	self.removeAccountMoney = function(accountName, money, metadata)
		money = ESX.Math.Check(ESX.Math.Round(money))
	
		if money > 0 then
			local account = self.getAccount(accountName)

			if account then
				local newMoney = ESX.Math.Check(account.money - money)
				account.money = newMoney
				syncAccountShortcuts()
				markDirty('accounts')
				self.triggerEvent('esx:setAccountMoney', account)
				ESX.ScheduleAdminRefresh(self.source)
				TriggerClientEvent("null:inventory:update", self.source)

				-- Auto-record bank transaction if metadata provided
				if accountName == 'bank' and metadata and Bank and Bank.AddTransaction then
					Bank.AddTransaction(self.source, {
						amount = -money,
						title = metadata.title or 'Débit',
						description = metadata.description or '',
						category = metadata.category or 'other',
					})
				end
			end
		end
	end

	self.removeMoney = function(money)
		money = ESX.Math.Check(ESX.Math.Round(money))
		accountName = "cash"
		if money > 0 then
			local account = self.getAccount(accountName)

			if account then
				local newMoney = ESX.Math.Check(account.money - money)
				account.money = newMoney
				syncAccountShortcuts()
				markDirty('accounts')
				self.triggerEvent('esx:setAccountMoney', account)
				ESX.ScheduleAdminRefresh(self.source)
				TriggerClientEvent("null:inventory:update", self.source)
			end
		end
	end

	self.hasInventoryItem = function(name)
		for i = 1, #self.inventory, 1 do
			if self.inventory[i].name == name then
				return true
			end
		end

		return false
	end

	self.getInventoryItem = function(name, identifier)
		for i = 1, #self.inventory, 1 do
			if self.inventory[i].name == name and (not identifier or (ESX.Items[name].unique and self.inventory[i].extra.identifier == identifier)) then
				return self.inventory[i], i
			end
		end

		if ESX.Items[name] == nil then return nil end

		return {
			name = name,
			count = 0,
			label = ESX.Items[name].label or 'Undefined',
			weight = ESX.Items[name].weight or 1.0,
			canRemove = ESX.Items[name].canRemove or false,
			unique = ESX.Items[name].unique or false,
			metadata = ESX.Items[name].metadata or {},
			extra = ESX.Items[name].unique and {} or nil
		}, false
	end

	self.addInventoryItem = function(name, count, metadata)
		if type(name) ~= 'string' then return end
		if type(count) ~= 'number' then return end
		if ESX.Items[name] == nil then return end
		count = ESX.Math.Round(count)
		if count < 1 then return end

		-- Auto-apply DefaultMetadata when no metadata is provided
		if (metadata == nil or (type(metadata) == 'table' and next(metadata) == nil)) and ESX.DefaultMetadata and ESX.DefaultMetadata[name] then
			metadata = ESX.DefaultMetadata[name](self.identifier)
		end

		local item, itemIndex = self.getInventoryItem(name, false)

		if ESX.Items[name].unique then
			local item = {
				name = name,
				count = 1,
				label = ESX.Items[name].label or 'Undefined',
				weight = ESX.Items[name].weight or 1.0,
				canRemove = ESX.Items[name].canRemove or false,
				unique = ESX.Items[name].unique or false,
				metadata = metadata or {},
				extra = {
					identifier = math.random(0,9999)
				}
			}
			print("extra (add) : "..json.encode(item.extra))

			table.insert(self.inventory, item)
			TriggerEvent('esx:onAddInventoryItem', self.source, item)
			self.triggerEvent('esx:addInventoryItem', item)
		else
			if item and itemIndex then
				local newCount = item.count + count

				if newCount > 0 then
					item.count = newCount
					TriggerEvent('esx:onUpdateItemCount', self.source, true, item.name, newCount)
					self.triggerEvent('esx:updateItemCount', true, item.name, newCount)
				end
			else
				local item = {
					name = name,
					count = count,
					label = ESX.Items[name].label or 'Undefined',
					weight = ESX.Items[name].weight or 1.0,
					canRemove = ESX.Items[name].canRemove or false,
					unique = false,
					metadata = metadata or {}
				}

				table.insert(self.inventory, item)
				TriggerEvent('esx:onAddInventoryItem', self.source, item)
				self.triggerEvent('esx:addInventoryItem', item)
			end
		end
		markDirty('inventory')
		TriggerClientEvent("null:inventory:update", self.source)
		ESX.ScheduleAdminRefresh(self.source)
	end

	-- self.addInventoryItem = function(name, count, metadata, slot)
	-- 	exports["inventory"]:AddItem(self.source, name, count, metadata)
	-- end

	self.removeInventoryItem = function(name, count, identifier)
		if type(name) ~= 'string' then return end
		if type(count) ~= 'number' then return end
		if ESX.Items[name] == nil then return end
		count = ESX.Math.Round(count)
		if count < 1 then return end

		if identifier then
			print("(remove) "..identifier)
		end
		
		local item, itemIndex = self.getInventoryItem(name, identifier)

		if item and itemIndex then
			if ESX.Items[name].unique then
				table.remove(self.inventory, itemIndex)
				TriggerEvent('esx:onRemoveInventoryItem', self.source, item)
				self.triggerEvent('esx:removeInventoryItem', item)
			else
				local newCount = item.count - count

				if newCount > 0 then
					item.count = newCount
					TriggerEvent('esx:onUpdateItemCount', self.source, false, item.name, newCount)
					self.triggerEvent('esx:updateItemCount', false, item.name, newCount)
				else
					table.remove(self.inventory, itemIndex)
					TriggerEvent('esx:onRemoveInventoryItem', self.source, item)
					self.triggerEvent('esx:removeInventoryItem', item)
				end
			end
		end
		markDirty('inventory')
		TriggerClientEvent("null:inventory:update", self.source)
		ESX.ScheduleAdminRefresh(self.source)
	end

	-- self.removeInventoryItem = function(name, count, metadata, slot)
	-- 	exports["inventory"]:RemoveItem(self.source, name, count)
	-- end

	self.setInventoryItem = function(name, count, identifier)
		local item = self.getInventoryItem(name, identifier)

		if item and count >= 0 then
			count = ESX.Math.Round(count)

			if count > item.count then
				self.addInventoryItem(item.name, count - item.count)
			else
				self.removeInventoryItem(item.name, item.count - count)
			end
		end
		ESX.ScheduleAdminRefresh(self.source)
		TriggerClientEvent("null:inventory:update", self.source)
	end

	self.getWeight = function()
		local inventoryWeight = 0

		for i = 1, #self.inventory, 1 do
			inventoryWeight = inventoryWeight + (self.inventory[i].count * self.inventory[i].weight)
		end

		return inventoryWeight
	end

	self.getMaxWeight = function()
		return self.maxWeight
	end

	self.canCarryItem = function(name, count)
		if (ESX.Items[name] == nil) then
			-- Todo send log to discord item missing 
			return true
		end

		local currentWeight, itemWeight = self.getWeight(), ESX.Items[name].weight or 1
		local newWeight = currentWeight + (itemWeight * count)

		return newWeight <= self.maxWeight
	end

	self.canSwapItem = function(firstItem, firstItemCount, testItem, testItemCount)
		local firstItemObject = self.getInventoryItem(firstItem)

		if firstItemObject.count >= firstItemCount then
			local weightWithoutFirstItem = ESX.Math.Round(self.getWeight() - (ESX.Items[firstItem].weight * firstItemCount))
			local weightWithTestItem = ESX.Math.Round(weightWithoutFirstItem + (ESX.Items[testItem].weight * testItemCount))

			return weightWithTestItem <= self.maxWeight
		end

		return false
	end

	self.addWeapon = function(weaponName, ammo, metadata, permanent, hasSerieNumber, durability)
		if type(weaponName) ~= 'string' then return end
		weaponName = string.upper(weaponName)

		if not self.hasWeapon(weaponName) then
			local weaponLabel = ESX.GetWeaponLabel(weaponName)
			if metadata == nil then metadata = {} end
			local serialNumber = nil
			if hasSerieNumber then
				serialNumber = ESX.GenerateSerialNumber()
			end
			null.DebugPrint("addWeapon", hasSerieNumber, serialNumber, json.encode(metadata))
			table.insert(self.loadout, {
				name = weaponName,
				ammo = ammo,
				label = weaponLabel,
				components = {},
				serialnumber = serialNumber,
				permanent = permanent or false,
				durability = durability or 0,
				metadata = metadata,
			})
			self.triggerEvent('esx:addWeapon', weaponName, ammo, metadata, serialNumber, permanent, durability)
			markDirty('loadout')
			ESX.ScheduleAdminRefresh(self.source)
			TriggerClientEvent("null:inventory:update", self.source)
		end
	end

	self.editWeapon = function(weaponName, toedit)
		if type(weaponName) ~= 'string' then return end
		weaponName = string.upper(weaponName)
		if type(toedit) ~= "table" then return end

		if self.hasWeapon(weaponName) then
			local weaponLabel = ESX.GetWeaponLabel(weaponName)
			for k,v in pairs(self.loadout) do
				if v.name == weaponName then
					for edittype, value in pairs(toedit) do
						self.loadout[k][edittype] = value
					end
				end
			end
			self.triggerEvent('esx:editWeapon', weaponName, toedit)
			markDirty('loadout')
			ESX.ScheduleAdminRefresh(self.source)
			TriggerClientEvent("null:inventory:update", self.source)
		end
	end

	self.editWeaponMetaData = function(weaponName, newmetadata)
		if type(weaponName) ~= 'string' then return end
		weaponName = string.upper(weaponName)

		if self.hasWeapon(weaponName) then
			local weaponLabel = ESX.GetWeaponLabel(weaponName)
			if newmetadata == nil then return end
			
			for k,v in pairs(self.loadout) do
				if v.name == weaponName then
					v.metadata = newmetadata
				end
			end
			self.triggerEvent('esx:editWeaponMetadata', weaponName, newmetadata)
			markDirty('loadout')
			ESX.ScheduleAdminRefresh(self.source)
			TriggerClientEvent("null:inventory:update", self.source)
		end
	end

	self.getWeaponMetaData = function(weaponName)
		if self.hasWeapon(weaponName) then
			for k,v in pairs(self.loadout) do
				if v.name == weaponName then
					return v
				end
			end
			return {}
		else
			return {}
		end
	end

	self.addWeaponComponent = function(weaponName, weaponComponent)
		if type(weaponName) ~= 'string' then return end
		if type(weaponComponent) ~= 'string' then return end
		weaponName = string.upper(weaponName)

		weaponComponent = string.lower(weaponComponent)

		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			local component = ESX.GetWeaponComponent(weaponName, weaponComponent)
			if component then
				if not self.hasWeaponComponent(weaponName, weaponComponent) then
					table.insert(self.loadout[loadoutNum].components, weaponComponent)
					self.triggerEvent('esx:addWeaponComponent', weaponName, weaponComponent)
					markDirty('loadout')
					ESX.ScheduleAdminRefresh(self.source)
					TriggerClientEvent("null:inventory:update", self.source)
				end
			end
		end
	end

	self.addWeaponAmmo = function(weaponName, ammoCount)
		if type(weaponName) ~= 'string' then return end
		weaponName = string.upper(weaponName)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			weapon.ammo = weapon.ammo + ammoCount
			markDirty('loadout')
			self.triggerEvent('esx:setWeaponAmmo', weaponName, weapon.ammo)
		end
	end

	self.removeWeapon = function(weaponName, ammo)
		if type(weaponName) ~= 'string' then return end
		weaponName = string.upper(weaponName)

		for i = 1, #self.loadout, 1 do
			if self.loadout[i].name == weaponName then
				weaponLabel = self.loadout[i].label

				for j = 1, #self.loadout[i].components, 1 do
					self.removeWeaponComponent(weaponName, self.loadout[i].components[j])
				end

				table.remove(self.loadout, i)
				self.triggerEvent('esx:removeWeapon', weaponName, ammo)
				markDirty('loadout')
				ESX.ScheduleAdminRefresh(self.source)
				TriggerClientEvent("null:inventory:update", self.source)
				break
			end
		end
	end

	self.removeWeaponComponent = function(weaponName, weaponComponent)
		if type(weaponName) ~= 'string' then return end
		if type(weaponComponent) ~= 'string' then return end
		weaponName = string.upper(weaponName)
		weaponComponent = string.lower(weaponComponent)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			local component = ESX.GetWeaponComponent(weaponName, weaponComponent)

			if component then
				if self.hasWeaponComponent(weaponName, weaponComponent) then
					for i = 1, #self.loadout[loadoutNum].components, 1 do
						if self.loadout[loadoutNum].components[i] == weaponComponent then
							table.remove(self.loadout[loadoutNum].components, i)
							break
						end
					end

					self.triggerEvent('esx:removeWeaponComponent', weaponName, weaponComponent)
					markDirty('loadout')
					ESX.ScheduleAdminRefresh(self.source)
					TriggerClientEvent("null:inventory:update", self.source)
				end
			end
		end
	end

	self.removeWeaponAmmo = function(weaponName, ammoCount)
		if type(weaponName) ~= 'string' then return end
		weaponName = string.upper(weaponName)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			weapon.ammo = weapon.ammo - ammoCount
			markDirty('loadout')
			self.triggerEvent('esx:setWeaponAmmo', weaponName, weapon.ammo)
		end
	end

	self.hasWeaponComponent = function(weaponName, weaponComponent)
		if type(weaponName) ~= 'string' then return end
		if type(weaponComponent) ~= 'string' then return end
		weaponName = string.upper(weaponName)
		weaponComponent = string.lower(weaponComponent)
		local loadoutNum, weapon = self.getWeapon(weaponName)

		if weapon then
			for i = 1, #weapon.components, 1 do
				if weapon.components[i] == weaponComponent then
					return true
				end
			end

			return false
		else
			return false
		end
	end

	self.hasWeapon = function(weaponName)
		if type(weaponName) ~= 'string' then return end
		weaponName = string.upper(weaponName)

		for i = 1, #self.loadout, 1 do
			if self.loadout[i].name == weaponName then
				return true
			end
		end

		return false
	end

	self.getWeapon = function(weaponName)
		if type(weaponName) ~= 'string' then return end
		weaponName = string.upper(weaponName)

		for i = 1, #self.loadout, 1 do
			if self.loadout[i].name == weaponName then
				return i, self.loadout[i]
			end
		end

		return
	end

	self.setJob = function(job, grade)
		grade = tostring(grade)
		-- Shallow copy au lieu de json.decode(json.encode()) - beaucoup plus rapide
		local lastJob = {}
		for k, v in pairs(self.job) do lastJob[k] = v end

		if ESX.DoesJobExist(job, grade) then
			local jobObject, gradeObject = ESX.Jobs[job], ESX.Jobs[job].grades[grade]

			self.job.id = jobObject.id
			self.job.name = jobObject.name
			self.job.label = jobObject.label

			self.job.grade = tonumber(grade)
			self.job.grade_name = gradeObject.name
			self.job.grade_label = gradeObject.label
			self.job.grade_salary = gradeObject.salary

			if gradeObject.skin_male then
				self.job.skin_male = type(gradeObject.skin_male) == 'table' and gradeObject.skin_male or json.decode(gradeObject.skin_male)
			else
				self.job.skin_male = {}
			end

			if gradeObject.skin_female then
				self.job.skin_female = type(gradeObject.skin_female) == 'table' and gradeObject.skin_female or json.decode(gradeObject.skin_female)
			else
				self.job.skin_female = {}
			end
			_dirtyScalar['job'] = true
			_dirtyScalar['job_grade'] = true
			TriggerEvent('esx:setJob', self.source, self.job, lastJob)
			self.triggerEvent('esx:setJob', self.job)
			ESX.ScheduleAdminRefresh(self.source)
		else
			print(('[^3WARNING^7] Ignoring invalid .setJob() usage for "%s"'):format(self.identifier))
		end
	end

	self.setJob2 = function(job2, grade2)
		grade2 = tostring(grade2)
		-- Shallow copy au lieu de json.decode(json.encode()) - beaucoup plus rapide
		local lastJob2 = {}
		for k, v in pairs(self.job2) do lastJob2[k] = v end

		if ESX.DoesJobExist(job2, grade2) then
			local job2Object, grade2Object = ESX.Jobs[job2], ESX.Jobs[job2].grades[grade2]

			self.job2.id = job2Object.id
			self.job2.name = job2Object.name
			self.job2.label = job2Object.label

			self.job2.grade = tonumber(grade2)
			self.job2.grade_name = grade2Object.name
			self.job2.grade_label = grade2Object.label
			self.job2.grade_salary = grade2Object.salary

			if grade2Object.skin_male ~= nil then
				self.job2.skin_male = type(grade2Object.skin_male) == 'table' and grade2Object.skin_male or json.decode(grade2Object.skin_male)
			else
				self.job2.skin_male = {}
			end

			if grade2Object.skin_female ~= nil then
				self.job2.skin_female = type(grade2Object.skin_female) == 'table' and grade2Object.skin_female or json.decode(grade2Object.skin_female)
			else
				self.job2.skin_female = {}
			end

			_dirtyScalar['job2'] = true
			_dirtyScalar['job2_grade'] = true
			TriggerEvent('esx:setJob2', self.source, self.job2, lastJob2)
			self.triggerEvent('esx:setJob2', self.job2)
			ESX.ScheduleAdminRefresh(self.source)
		else
			print(('[^3WARNING^7] Ignoring invalid .setJob() usage for "%s"'):format(self.identifier))
		end
	end

	self.setMaxWeight = function(newWeight)
		newWeight = ESX.Math.Round(newWeight)

		if newWeight > 0 then
			self.maxWeight = newWeight
			self.triggerEvent('esx:setMaxWeight', self.maxWeight)
		end
	end

	self.showNotification = function(msg, hudColorIndex)
		self.triggerEvent('esx:showNotification', msg, hudColorIndex)
	end

	self.showAdvancedNotification = function(title, subject, msg, icon, iconType, hudColorIndex)
		self.triggerEvent('esx:showAdvancedNotification', title, subject, msg, icon, iconType, hudColorIndex)
	end

	self.showHelpNotification = function(msg)
		self.triggerEvent('esx:showHelpNotification', msg)
	end

	self.getStaffMode = function()
		return self.staffmode
	end

	self.setStaffMode = function(bool)
		self.staffmode = bool
		self.triggerEvent('esx:setStaffMode', bool)
	end

	self.getGamertag = function()
		return self.gamertag
	end

	self.setGamertag = function(bool)
		self.gamertag = bool
	end

	self.getInstance = function()
		return self.instance
	end

	self.setInstance = function(bool)
		self.instance = bool
	end

	-- Get accessory data by type and ID
	self.getAccessory = function(accessoryType, itemName)
		if type(accessoryType) ~= 'string' or not itemName then return nil end
		
		-- Check if the accessory is equipped
		if self.clothes_equiped and self.clothes_equiped[accessoryType] then
			local equipped = self.clothes_equiped[accessoryType]
			-- Match by ID (itemName is the clothe ID from vclothes)
			if equipped.id and tostring(equipped.id) == tostring(itemName) then
				return {
					id = equipped.id,
					type = accessoryType,
					label = equipped.label or accessoryType,
					skin = equipped.skin or {},
				}
			end
		end
		
		return nil
	end

	-- Remove accessory from player's equipped clothes
	self.removeAccessory = function(accessoryType, itemName)
		if type(accessoryType) ~= 'string' or not itemName then return false end
		
		-- Check if the accessory is equipped
		if self.clothes_equiped and self.clothes_equiped[accessoryType] then
			local equipped = self.clothes_equiped[accessoryType]
			-- Match by ID
			if equipped.id and tostring(equipped.id) == tostring(itemName) then
				-- Remove from equipped clothes
				self.clothes_equiped[accessoryType] = nil
				markDirty('clothes')
				
				-- Trigger client event to remove the accessory visually
				self.triggerEvent('esx:removeAccessory', accessoryType)
				
				-- Update admin panel and inventory
				ESX.ScheduleAdminRefresh(self.source)
				TriggerClientEvent("null:inventory:update", self.source)
				
				return true
			end
		end
		
		return false
	end

	return self
end
