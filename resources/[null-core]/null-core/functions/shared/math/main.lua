null.fct.math.SizeOf = function(t)
	local count = 0

	for _,v in pairs(t) do
		count = count + v
	end

	return count
end

-- Calculates Kill/Death ratio
-- player: table with kills and deaths keys
null.fct.math.CalculateKD = function(player)
    if player.deaths == 0 then
        return player.kills
    end
    return player.kills / player.deaths
end

null.fct.math.compareKD = function(player1, player2)
    return calculateKD(player1) > calculateKD(player2)
end

null.fct.math.Distance3d = function(coords, coords2)
	return #(coords - coords2)
end

null.fct.math.Round = function(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end