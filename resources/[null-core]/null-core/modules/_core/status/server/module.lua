

local function loadStatusFor(eventSrc, xPlayer)
	MySQL.Async.fetchAll('SELECT status FROM users WHERE identifier = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		local data = {}

		if result and result[1] and result[1].status ~= nil then
			data = json.decode(result[1].status)
		end

		xPlayer.set('status', data)
		TriggerClientEvent('esx_status:load', eventSrc, data)
	end)
end

AddEventHandler('esx:playerLoaded', function(eventSrc, xPlayer)
	loadStatusFor(eventSrc, xPlayer)
end)

-- Le client peut demander un (re)load à tout moment — utile après un
-- restart de la ressource où esx:playerLoaded ne refire pas.
RegisterServerEvent('esx_status:requestLoad')
AddEventHandler('esx_status:requestLoad', function()
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	if not xPlayer then return end
	-- Si l'état est déjà en mémoire (déjà chargé une fois), on le renvoie tel quel
	-- pour ne pas écraser les décréments client par la version DB.
	local cached = xPlayer.get('status')
	if type(cached) == "table" and #cached > 0 then
		TriggerClientEvent('esx_status:load', src, cached)
	else
		loadStatusFor(src, xPlayer)
	end
end)

AddEventHandler('esx:playerDropped', function(eventSrc, xPlayer)
	local status = xPlayer.get('status')

	MySQL.Async.execute('UPDATE users SET status = @status WHERE identifier = @identifier', {
		['@status'] = json.encode(status),
		['@identifier'] = xPlayer.identifier
	})
end)

RegisterServerEvent('esx_status:update')
AddEventHandler('esx_status:update', function(status)
	local xPlayer = ESX.GetPlayerFromId(source)

	if xPlayer then
		xPlayer.set('status', status)
	end
end)

local function SaveData()
	local xPlayers = ESX.GetPlayers()

	for i = 1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])

		if xPlayer then
			local status = xPlayer.get('status')

			MySQL.Async.execute('UPDATE users SET status = @status WHERE identifier = @identifier', {
				['@status'] = json.encode(status),
				['@identifier'] = xPlayer.identifier
			})
		end
	end

	SetTimeout(10 * 60 * 1000, SaveData)
end

SaveData()