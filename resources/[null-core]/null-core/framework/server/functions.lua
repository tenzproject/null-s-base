local ServerCallbacks = ESX.ServerCallbacks
local CallbacksResource = ESX.ServerCallbacksResourceName
local RequestCounter = {} 

ESX.RegisterServerCallback = LPH_JIT(function(name, cb, resourceName)
    ServerCallbacks[name] = cb
    if resourceName then
        CallbacksResource[name] = resourceName
    end
end)

ESX.TriggerServerCallback = LPH_JIT_MAX(function(name, requestId, source, cb, ...)
    local callback = ServerCallbacks[name]
    
    if callback then
        local count = (RequestCounter[source] or 0) + 1
        RequestCounter[source] = count

        if count >= 50 then
            return
        end

        callback(source, cb, ...)
    else
        print(('[^4ServerCallbacks^2] - [^3ATTENTION^7] %s n\'existe pas'):format(name))
    end
end)

exports("triggerServerCallback", ESX.TriggerServerCallback)

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        Wait(5000)
        if next(RequestCounter) then
            for k in pairs(RequestCounter) do
                RequestCounter[k] = nil
            end
        end
    end
end))

ESX.SavePlayer = LPH_JIT_MAX(function(xPlayer, cb)
	if not xPlayer then
		if cb then cb() end
		return
	end

	-- Position est toujours dirty (sync toutes les 60s)
	xPlayer.markDirty('position')

	-- Construire dynamiquement la requête avec uniquement les colonnes dirty
	local setClauses = {}
	local params = { ['@identifier'] = xPlayer.identifier }

	-- JSON fields: only include if dirty
	local jsonFields = {
		{ field = 'accounts',  col = 'accounts' },
		{ field = 'inventory', col = 'inventory' },
		{ field = 'loadout',   col = 'loadout' },
		{ field = 'clothes',   col = 'clothes' },
		{ field = 'smells',    col = 'smells' },
		{ field = 'position',  col = 'position' },
	}

	for _, jf in ipairs(jsonFields) do
		if xPlayer.isDirtyJson(jf.field) then
			setClauses[#setClauses + 1] = jf.col .. ' = @' .. jf.col
			params['@' .. jf.col] = xPlayer.getJsonCache(jf.field)
		end
	end

	-- Scalar fields: only include if dirty
	local dirtyScalar = xPlayer.getDirtyScalar()

	-- Playtime is always saved (increments every tick)
	dirtyScalar['playtime'] = true

	local scalarMap = {
		name             = function() return xPlayer.getName() end,
		playtime         = function() return xPlayer.getPlayTime() end,
		fivem            = function() return xPlayer.fivem end,
		discord          = function() return xPlayer.discord end,
		streamer         = function() return xPlayer.isStreamer() end,
		ata              = function() return xPlayer.ata == 0 and nil or xPlayer.ata end,
		permission_group = function() return xPlayer.permission_group end,
		permission_level = function() return xPlayer.permission_level end,
		job              = function() return xPlayer.job.name end,
		job2             = function() return xPlayer.job2.name end,
		job_grade        = function() return xPlayer.job.grade end,
		job2_grade       = function() return xPlayer.job2.grade end,
	}

	for col, getter in pairs(scalarMap) do
		if dirtyScalar[col] then
			setClauses[#setClauses + 1] = col .. ' = @' .. col
			params['@' .. col] = getter()
		end
	end

	-- AFK: toujours sauvegarder (géré séparément car c'est un couple)
	local afkSet = xPlayer.getAfk()
	setClauses[#setClauses + 1] = 'afk_time = @afk_time'
	setClauses[#setClauses + 1] = 'afk_point = @afk_point'
	params['@afk_time'] = afkSet.afk_time
	params['@afk_point'] = afkSet.afk_point

	xPlayer.clearDirtyScalar()

	if #setClauses == 0 then
		if cb then cb() end
		return
	end

	local query = 'UPDATE users SET ' .. table.concat(setClauses, ', ') .. ' WHERE identifier = @identifier'

	MySQL.Async.execute(query, params, function(rowsChanged)
		if cb then cb() end
	end)
end)

ESX.SavePlayers = LPH_JIT_MAX(function(cb)
	local asyncTasks = {}
	local xPlayers = ESX.GetPlayers()

	if #xPlayers > 0 then
		for i = 1, #xPlayers, 1 do
			table.insert(asyncTasks, function(cb)
				local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
				ESX.SavePlayer(xPlayer, cb)
			end)
		end

		Async.parallelLimit(asyncTasks, 8, function(results)
			--print(('[^4SAUVEGARDE^7] %s Joueur(s) ont été sauvegarder'):format(#xPlayers))

			if cb then
				cb()
			end
		end)
	end
end)

function ESX.KickPlayers(reason, cb)
	local asyncTasks = {}
	local xPlayers = ESX.GetPlayers()

	if #xPlayers > 0 then
		for i = 1, #xPlayers, 1 do
			table.insert(asyncTasks, function(cb)
				local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
				ESX.SavePlayer(xPlayer, cb)
				DropPlayer(xPlayer.source, reason or "Vous avez été déconnecté de notre serveur.")
			end)
		end

		Async.parallelLimit(asyncTasks, 8, function(results)
			
			if cb then
				cb()
			end
		end)
	end
end


ESX.SyncPosition = LPH_JIT_MAX(function()
	local xPlayers = ESX.GetPlayers()

	for i = 1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])

		if xPlayer then
			local plyPed = GetPlayerPed(xPlayer.source)
			if DoesEntityExist(plyPed) then
				local lastCoords = GetEntityCoords(plyPed)
				if lastCoords ~= nil then
					if not PlayersInPropertiesForExtendedFc(xPlayer.source) then
						xPlayer.setLastPosition(lastCoords)
					end
				end
			end
		end
	end
end)

function ESX.StartDBSync()
	-- Sauvegardes étalées: au lieu de sauvegarder tous les joueurs d'un coup (pic CPU),
	-- on sauvegarde par petits lots répartis sur l'intervalle de 5 minutes
	local SAVE_INTERVAL = 5 * 60 * 1000 -- 5 minutes
	local BATCH_SIZE = 10 -- joueurs par lot

	function saveData()
		local xPlayers = ESX.GetPlayers()
		local totalPlayers = #xPlayers

		if totalPlayers == 0 then
			SetTimeout(SAVE_INTERVAL, saveData)
			return
		end

		local totalBatches = math.ceil(totalPlayers / BATCH_SIZE)
		-- Délai entre chaque lot pour étaler la charge sur l'intervalle
		local delayBetweenBatches = math.max(500, math.floor(SAVE_INTERVAL / (totalBatches + 1)))

		for batchIndex = 1, totalBatches do
			SetTimeout(delayBetweenBatches * (batchIndex - 1), function()
				local asyncTasks = {}
				local startIdx = (batchIndex - 1) * BATCH_SIZE + 1
				local endIdx = math.min(batchIndex * BATCH_SIZE, totalPlayers)

				for i = startIdx, endIdx do
					local playerId = xPlayers[i]
					table.insert(asyncTasks, function(cb)
						local xPlayer = ESX.GetPlayerFromId(playerId)
						if xPlayer then
							ESX.SavePlayer(xPlayer, cb)
						else
							cb()
						end
					end)
				end

				if #asyncTasks > 0 then
					Async.parallelLimit(asyncTasks, 4, function() end)
				end
			end)
		end

		SetTimeout(SAVE_INTERVAL, saveData)
	end

	SetTimeout(SAVE_INTERVAL, saveData)
end

function ESX.StartPositionSync()
	function updateData()
		ESX.SyncPosition()
		SetTimeout(60 * 1000, updateData)
	end

	SetTimeout(5 * 1000, updateData)
end

function ESX.GetPlayers()
	local sources = {}

	for k, v in pairs(ESX.Players) do
		table.insert(sources, k)
	end

	return sources
end

function ESX.GetPlayerFromId(source)
    if source == nil then return nil end
	return ESX.Players[tonumber(source)]
end

-- Optimisé: O(1) au lieu de O(n)
function ESX.GetPlayerFromIdUnique(idunique)
	if idunique == nil then return nil end
	return ESX.PlayersByIdUnique[tonumber(idunique)]
end

-- Optimisé: O(1) au lieu de O(n)
function ESX.GetPlayerFromIdentifier(identifier)
	if identifier == nil then return nil end
	return ESX.PlayersByIdentifier[identifier]
end



function ESX.getIdentifiers(playerSrc)
    if (playerSrc == nil) then return end

    local playerNumIdentifiers = GetNumPlayerIdentifiers(playerSrc)
    local playerIdentifiers = {}

    for identifierIndex = 0, playerNumIdentifiers do
        if (identifierIndex ~= nil) then
            table.insert(playerIdentifiers, GetPlayerIdentifier(playerSrc, identifierIndex))
        end
    end

    return playerIdentifiers
end

function ESX.GetIdentifierFromId(playerSrc, nameToSearch)
    if (playerSrc == nil) then return end

    local playerIdentifiers = ESX.getIdentifiers(playerSrc)

    if (nameToSearch == "main" or nameToSearch == nil) then
        nameToSearch = "license"
    end

    for _, identifier in pairs(playerIdentifiers) do
        if (string.find(identifier, nameToSearch..":")) then
            return identifier
        end
    end
end

function ESX.RegisterUsableItem(item, cb)
	ESX.UsableItemsCallbacks[item] = cb
end

function ESX.UseItem(source, item)
	if ESX.UsableItemsCallbacks[item] then
		ESX.UsableItemsCallbacks[item](source)
	else
		print('[es_extended] : ' .. source .. 'tried to use item : ' .. item)
	end
end

function ESX.GetItemList()
	return ESX.Items
end

function ESX.GetItem(item)
	if ESX.Items[item] then
		return ESX.Items[item]
	end
end

function ESX.GetItemLabel(item)
	if ESX.Items[item] then
		return ESX.Items[item].label
	end
end

function ESX.CreatePickup(type, name, count, label, playerId, components)
	local xPlayer = ESX.GetPlayerFromId(playerId)
	local coords = xPlayer.getCoords()

	TriggerEvent("ratelimit", source, "ESX.CreatePickup")

	local pickupId = (ESX.PickupId == 65635 and 0 or ESX.PickupId + 1)

	ESX.Pickups[pickupId] = {
		type = type,
		name = name,
		count = count,
		label = label,
		coords = coords
	}

	if type == 'item_weapon' then
		ESX.Pickups[pickupId].components = components
	end

	TriggerClientEvent('esx:createPickup', -1, pickupId, label, coords, type, name, components)
	ESX.PickupId = pickupId
end

function ESX.DoesJobExist(job, grade)
	grade = tostring(grade)

	if job and grade then
		if ESX.Jobs[job] and ESX.Jobs[job].grades[grade] then
			return true
		end
	end

	return false
end

function ESX.ChatMessage(source, msg, author, color)
	TriggerClientEvent('chat:addMessage', source, {color = color or {255, 255, 255}, args = {author or 'SYSTEME', msg or ''}})
end

function ESX.DB.CreateUser(identifier, cb)
	local position = json.encode({x = Config.DefaultPosition.x, y = Config.DefaultPosition.y, z = Config.DefaultPosition.z})

	MySQL.Async.execute('INSERT INTO users (identifier, permission_group, permission_level, position) VALUES (@identifier, @permission_group, @permission_level, @position)', {
		identifier = identifier,
		permission_group = Config.DefaultGroup,
		permission_level = Config.DefaultLevel,
		position = position
	}, function()
		if cb then
			cb()
		end
	end)
end

ESX.DB.UpdateUser = LPH_JIT_MAX(function(identifier, new, cb)
	Citizen.CreateThread(function()
		local updateString = ''
		local length = ESX.Table.SizeOf(new)
		local cLength = 1

		for k, v in pairs(new) do
			if cLength < length then
				if (type(v) == 'number') then
					updateString = updateString .. "`" .. k .. "` = " .. v .. ","
				else
					updateString = updateString .. "`" .. k .. "` = '" .. v .. "',"
				end
			else
				if (type(v) == 'number') then
					updateString = updateString .. "`" .. k .. "` = " .. v
				else
					updateString = updateString .. "`" .. k .. "` = '" .. v .. "'"
				end
			end

			cLength = cLength + 1
		end

		MySQL.Async.execute('UPDATE users SET ' .. updateString .. ' WHERE `identifier` = @identifier', {identifier = identifier}, function()
			if cb then
				cb(true)
			end
		end)
	end)
end)


function ESX.GetNameByIdentifier(identifier, cb)
	MySQL.Async.fetchAll('SELECT name FROM users WHERE `identifier` = @identifier', {identifier = identifier}, function(result)
		if result[1] ~= nil then
			cb(result[1].name)
		else
			cb(nil)
		end
	end)
end

function ESX.GetNameByIdUnique(idunique, cb)
	MySQL.Async.fetchAll('SELECT name FROM users WHERE `idunique` = @idunique', {idunique = idunique}, function(result)
		if result[1] ~= nil then
			cb(result[1].name)
		else
			cb(nil)
		end
	end)
end

function ESX.DB.DoesUserExist(identifier, cb)
	MySQL.Async.fetchAll('SELECT * FROM users WHERE `identifier` = @identifier', {identifier = identifier}, function(result)
		if cb then
			if result[1] then
				cb(true, result[1])
			else
				cb(false)
			end
		end
	end)
end

function ESX.ContribWeapon(weapon)
	if Config.ContribWeapon[weapon] then
		return true 
	else 
		return false
	end
end

function ESX.GetContribWeapon()
	return Config.ContribWeapon
end

function ESX.GetContribItem()
	return Config.ContribItem
end


function ESX.ContribItem(item) 
	if Config.ContribItem[item] then
		return true 
	else 
		return false
	end
end

function ESX.GenerateSerialNumber()
    local serialNumber = ""
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    for i = 1, 15 do
        local randomIndex = math.random(1, #chars)
        serialNumber = serialNumber .. string.sub(chars, randomIndex, randomIndex)
    end
    return serialNumber
end

function ESX.GetJobPlayers(jobName, jobGradeName)
    local sources = {}

    for k, v in pairs(ESX.Players) do
        if ((jobName ~= nil and v.job.name == jobName) or jobName == nil) and ((jobGradeName ~= nil and v.job.grade_name == jobGradeName) or jobGradeName == nil) then
            table.insert(sources, k)
        end
    end

    return sources
end

function ESX.BypassLicense(license)
	if Config.BypassLicense[license] then 
		return true
	else 
		return false
	end
end

RegisterNetEvent('player:GetMyIdentifier', function()
	local src = source
	TriggerClientEvent("player:GetMyIdentifier", src, ESX.Players[src].identifier)
end)

function ESX.Logs(title, message, logs)
	PerformHttpRequest(logs, function(err, text, headers) end, 'POST', json.encode({
	  username = null.getConvarKey("serverName") , 
	  embeds = {{
		  ["author"] = {
			  ["name"] = "Logs",
			  ["icon_url"] = null.getConvarKey("serverCHAR")
		  },
		  ["title"] = title,
		  ["description"] = "".. message .."",
		  ["footer"] = {
			  ["text"] = "Logs • "..os.date("%x %X %p"),
			  ["icon_url"] = null.getConvarKey("serverCHAR"),
		  },
	  }}, 
	  avatar_url = null.getConvarKey("serverCHAR")
	}), { 
		['Content-Type'] = 'application/json' 
	})
end
