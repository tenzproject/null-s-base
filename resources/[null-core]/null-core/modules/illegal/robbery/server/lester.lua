LesterisSwat = false

ESX.RegisterServerCallback('null:lester:phone', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
    if Config.Phone.votre_telephone["lbphone"] then
        local phonenumber = exports["lb-phone"]:GetEquippedPhoneNumber(source)
        exports["lb-phone"]:SendMessage("056-029", phonenumber, "Rend-toi a cette position gps, tu pourras me contacter")
        exports["lb-phone"]:SendCoords("056-029", phonenumber, Config.Robbery.HackerPos)
        cb(true)
    elseif Config.Phone.votre_telephone["qs"] then
        cb(true)
    else
        cb(true)
    end
end)

ESX.RegisterServerCallback('null:lester:getnbrpolice', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
    local xPlayers    = ESX.GetPlayers()
    local nbr = 0
    for k,v in pairs(xPlayers) do
        local xPlayer = ESX.GetPlayerFromId(v)
        if SaveData.json["entreprises"]["Police"][xPlayer.getJob().name] ~= nil then
            nbr = nbr + 1
        end
    end
    cb(nbr)
end)

Citizen.CreateThread(function ()
    MySQL.Async.fetchAll('SELECT * FROM vlester', {}, function(result)
        if #result > 0 then
            if (os.time() - tonumber(result[1].time)) < 604800 then
                LesterisSwat = true
            else
                MySQL.Async.execute("DELETE FROM `vlester` WHERE id = @id", {['@id'] = result[1].id})
            end
        else
            LesterisSwat = false
        end
    end)
end)


RegisterServerEvent("null:lester:swat", function ()
	local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["entreprises"]["Police"][xPlayer.getJob().name] == nil then return end
    if LesterisSwat then return end

    print("[^5Null^7] Police Swat Lester")
    LesterisSwat = true
    TriggerClientEvent("null:swat:client", -1)
end)


RegisterServerEvent("null:lester:LesterisSwat", function ()
    TriggerClientEvent("null:LesterisSwat:client", source,LesterisSwat)
end)


RegisterNetEvent('lester:vendeur', function(nbr)
	local xPlayer  = ESX.GetPlayerFromId(source)
	local bijoux = xPlayer.getInventoryItem('jewels').count
	local price = 1200 * bijoux
	if bijoux == nil then return end

	if bijoux < nbr or bijoux == 0 then 
		TriggerClientEvent('esx:showNotification', source, '~r~Vous n\'avez pas assez de bijoux !')
		return
	elseif bijoux >= nbr then  
		xPlayer.addAccountMoney('dirtycash', price)
		xPlayer.removeInventoryItem('jewels', nbr)
		TriggerClientEvent('esx:showNotification', source, nbr..'x Bijoux Vendu~s~')

		local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed"
		if gangname ~= "unemployed" then
			exports["null-core"]:ProgressGangMission(gangname, "daily_dirty_money", price)
			exports["null-core"]:ProgressGangMission(gangname, "weekly_dirty_money_mass", price)
			exports["null-core"]:AddGangXP(gangname, 20)
		end
	end
end)
