-- Cache optimisé : joueurs par routing bucket (O(1) lookup)
null.players.byRoutingBucket = {}

null.fct.instance.Set = function(src, number, label)
	if src == nil then return end
	if number == nil then return end
	if type(number) ~= "number" then return end
	local xPlayer = ESX.GetPlayerFromId(src)
	if xPlayer == nil then return end

	-- Retirer le joueur de son ancien bucket
	local oldInstance = null.players.instances[xPlayer.source]
	if oldInstance and oldInstance.number ~= 0 then
		if null.players.byRoutingBucket[oldInstance.number] then
			null.players.byRoutingBucket[oldInstance.number][xPlayer.source] = nil
			-- Nettoyer le bucket s'il est vide
			if next(null.players.byRoutingBucket[oldInstance.number]) == nil then
				null.players.byRoutingBucket[oldInstance.number] = nil
			end
		end
	end

	if number == 0 then
		null.players.instances[xPlayer.source] = nil
		SetPlayerRoutingBucket(xPlayer.source, 0)
        TriggerClientEvent("Null:esx:changeBucket", xPlayer.source, 0)
	else
		null.players.instances[xPlayer.source] = {
			number = number,
			label = label or "Inconnu"
		}
		SetPlayerRoutingBucket(xPlayer.source, number)
        TriggerClientEvent("Null:esx:changeBucket", xPlayer.source, number)
		
		-- Ajouter le joueur au cache du nouveau bucket
		if not null.players.byRoutingBucket[number] then
			null.players.byRoutingBucket[number] = {}
		end
		null.players.byRoutingBucket[number][xPlayer.source] = true
	end
end

null.fct.instance.Get = function(src)
	if src == nil then return end
	local xPlayer = ESX.GetPlayerFromId(src)
	local PlayerBucket = GetPlayerRoutingBucket(src)
	if PlayerBucket ~= 0 and PlayerBucket ~= null.players.instances[xPlayer.source] then
		--print("SetPlayerRoutingBucket n'a pas était changer en SetInInstance()")
		null.players.instances[xPlayer.source] = {
			number = PlayerBucket,
			label = "Inconnu"
		}
		return null.players.instances[xPlayer.source]
	end

	if null.players.instances[xPlayer.source] == nil then 
		return {number = 0, label = "Monde RolePlay"}
	else
		return null.players.instances[xPlayer.source]
	end
end

-- Obtenir tous les joueurs dans un routing bucket spécifique (O(1))
null.fct.instance.GetPlayersInBucket = function(bucketNumber)
	if bucketNumber == nil or bucketNumber == 0 then
		return {}
	end
	
	local players = {}
	if null.players.byRoutingBucket[bucketNumber] then
		for playerId, _ in pairs(null.players.byRoutingBucket[bucketNumber]) do
			table.insert(players, playerId)
		end
	end
	
	-- Fallback: si le cache est vide, vérifier manuellement (pour compatibilité)
	if #players == 0 then
		for _, playerId in ipairs(GetPlayers()) do
			if GetPlayerRoutingBucket(playerId) == bucketNumber then
				table.insert(players, playerId)
			end
		end
	end
	
	return players
end

exports("SetInInstance", null.fct.instance.Set)
exports("GetInstance", null.fct.instance.Get)
exports("GetPlayersInBucket", null.fct.instance.GetPlayersInBucket)