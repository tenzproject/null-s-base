local DeadPedsRobbery = {}

RegisterServerEvent('null:supermarket-robbery:PedDeadRobbery')
AddEventHandler('null:supermarket-robbery:PedDeadRobbery', function(store)
    if not DeadPedsRobbery[store] then
        DeadPedsRobbery[store] = 'dead'
        TriggerClientEvent('null:supermarket-robbery:OnPedDeathRobbery', -1, store)
        local second = 1000
        local minute = 60 * second
        local hour = 60 * minute
        local cooldown = Config.SupermarketRobbery.List[store].cooldown
        local wait = cooldown.hour * hour + cooldown.minute * minute + cooldown.second * second
        Wait(wait)
        if not Config.SupermarketRobbery.List[store].robbed then
            for k, v in pairs(DeadPedsRobbery) do 
                if k == store then 
                    table.remove(DeadPedsRobbery, k) 
                end 
            end
            TriggerClientEvent('null:supermarket-robbery:ResetPedDeath', -1, store)
        end
    end
end)

RegisterServerEvent('null:supermarket-robbery:PickupRobbery')
AddEventHandler('null:supermarket-robbery:PickupRobbery', function(store, numbers)
	if store == nil or store.coords == nil then 
		ExecuteCommand("ban " .. source .. "0 SUPERETTE-BAN")
	else
		if #(GetEntityCoords(GetPlayerPed(source))-store.coords) > 10.0 then
			ExecuteCommand("ban " .. source .. " 0 SUPERETTE-BAN")
		else
			local xPlayer = ESX.GetPlayerFromId(source)
			local randomAmount = math.random(Config.SupermarketRobbery.Rewards.Minimum, Config.SupermarketRobbery.Rewards.Maximum)
			xPlayer.addAccountMoney('dirtycash', randomAmount)
			xPlayer.showNotification("Vous avez récupéré ~g~".. randomAmount .."$~s~.")
			TriggerClientEvent('null:supermarket-robbery:RemovePickupRobbery', -1, numbers)

			local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed"
			if gangname ~= "unemployed" then
				exports["null-core"]:ProgressGangMission(gangname, "daily_robbery_store", 1)
				exports["null-core"]:ProgressGangMission(gangname, "weekly_robbery_spree", 1)
				exports["null-core"]:ProgressGangMission(gangname, "daily_dirty_money", randomAmount)
				exports["null-core"]:ProgressGangMission(gangname, "weekly_dirty_money_mass", randomAmount)
				exports["null-core"]:AddGangXP(gangname, 30)
			end
		end
	end
end)

ESX.RegisterServerCallback('null:supermarket-robbery:CanRobbery', function(source, cb, store)
    local PoliceConnected = 0
    local xPlayers = ESX.GetPlayers()
	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
        if SaveData.json["entreprises"]["Police"][xPlayer.getJob().name] ~= nil then
			PoliceConnected = PoliceConnected + 1
		end
	end
    if PoliceConnected >= Config.SupermarketRobbery.Requiredcops then
        if not Config.SupermarketRobbery.List[store].robbed and not DeadPedsRobbery[store] then
            cb(true)
        else
            cb(false)
        end
    else
        cb('no_cops')
    end
end)

RegisterServerEvent('null:supermarket-robbery:RobberyStart')
AddEventHandler('null:supermarket-robbery:RobberyStart', function(store)
    local src = source
    Config.SupermarketRobbery.List[store].robbed = true

    TriggerClientEvent('null:supermarket-robbery:RobberyStart', -1, store)
    Wait(30000)
    TriggerClientEvent('null:supermarket-robbery:RobberyStartOver', src)

    local second = 1000
    local minute = 60 * second
    local hour = 60 * minute
    local cooldown = Config.SupermarketRobbery.List[store].cooldown
    local wait = cooldown.hour * hour + cooldown.minute * minute + cooldown.second * second
    Wait(wait)
    Config.SupermarketRobbery.List[store].robbed = false
    for k, v in pairs(DeadPedsRobbery) do 
        if k == store then 
            table.remove(DeadPedsRobbery, k) 
        end 
    end
    --TriggerClientEvent('null:supermarket-robbery:ResetPedDeath', -1, store)
end)

RegisterServerEvent("null:supermarket-robbery::CallPolice")
AddEventHandler("null:supermarket-robbery::CallPolice", function(store, i)
    if store and i then
        TriggerClientEvent('null:police:addchoicenotif', -1, math.random(0,9999), "Braquage Superette", vec3(store.coords.x, store.coords.y, store.coords.z), 160, 1, nil, "Braquage de superette ! \nEmplacement sur la Carte.")
    end

    --local PlayersInJobs = ESX.GetJobsPlayers('police')
    --for k,v in pairs(PlayersInJobs) do 
    --    TriggerClientEvent("null:supermarket-robbery::MsgPolice", k, store, i)
    --    TriggerClientEvent('NPCVente:AffichageAppel', k, coords)
    --end

end)