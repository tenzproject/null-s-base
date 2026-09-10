local rob = false
local robbers = {}
PlayersCrafting    = {}
local CopsConnected  = 0
Configvangelico = {}
Configvangelico.Locale = 'fr'

Configvangelico.RequiredCopsRob = 6--3
Configvangelico.RequiredCopsSell = 0 --1

Stores = {
	["jewelry"] = {
		position = { ['x'] = -629.99, ['y'] = -236.542, ['z'] = 38.05 },       
		nameofstore = "jewelry",
		labelofstore = "Bijouterie",
	}
}

function get3DDistance(x1, y1, z1, x2, y2, z2)
	return math.sqrt(math.pow(x1 - x2, 2) + math.pow(y1 - y2, 2) + math.pow(z1 - z2, 2))
end

RegisterNetEvent('esx_vangelico_robbery:toofar', function(robb)
	local source = source
	local xPlayers = ESX.GetPlayers()
	rob = false
	for i=1, #xPlayers, 1 do
 		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		 if (SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil) then
			TriggerClientEvent('esx:showNotification', xPlayers[i], '~r~ Braquage annulé à: ~g~' .. Stores[robb].labelofstore)
			TriggerClientEvent('esx_vangelico_robbery:killblip', xPlayers[i])
		end
	end
	if(robbers[source])then
		TriggerClientEvent('esx_vangelico_robbery:toofarlocal', source)
		robbers[source] = nil
		TriggerClientEvent('esx:showNotification', source, '~r~ Le braquage à été annulé: ~g~' .. Stores[robb].labelofstore)
	end
end)

RegisterNetEvent('esx_vangelico_robbery:endrob', function(robb)
	local source = source
	local xPlayers = ESX.GetPlayers()
	rob = false
	for i=1, #xPlayers, 1 do
 		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		 if (SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil) then
			TriggerClientEvent('esx:showNotification', xPlayers[i], 'Les Bijoux ont été volés !')
			TriggerClientEvent('esx_vangelico_robbery:killblip', xPlayers[i])
		end
	end
	if(robbers[source])then
		local webhook = 'https://discord.com/api/webhooks/1007255131634540665/wu5ecBitrNi9txr9o9RiEmmXmqz1mdGs0XVDWAUotH2gDANwThZ71DoAJ1aQs4QG1sDo'
		TriggerClientEvent('esx_vangelico_robbery:robberycomplete', source)
		robbers[source] = nil
		TriggerClientEvent('esx:showNotification', source, 'Braquage fini')
	end
end)

local CoulDownBijouterie = 120*60*1000
local BijouterieHasBraqued = false

RegisterNetEvent('esx_vangelico_robbery:rob', function(robb, token)
    VerifyToken(source, token, 'esx_vangelico_robbery:rob', function()
		local source = source
		local xPlayer = ESX.GetPlayerFromId(source)
		local xPlayers = ESX.GetPlayers()
		
		if Stores[robb] then
	
			local store = Stores[robb]
	
			if BijouterieHasBraqued then
				TriggerClientEvent('esx_vangelico_robbery:togliblip', source)
				TriggerClientEvent('esx:showNotification', source, 'Les bijoux ont déjà été volés. Revenez plus tard')
				return
			end

			CountCops()
	
			if rob == false then
	
				if(CopsConnected >= 6)then
					BijouterieHasBraqued = true
					Citizen.SetTimeout(CoulDownBijouterie, function()
						BijouterieHasBraqued = false
					end)
					rob = true
					for i=1, #xPlayers, 1 do
						local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
						if (SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil) then
							TriggerClientEvent('esx:showNotification', xPlayers[i], 'URGENCE !\nLa ~g~Bijouterie~s~ se fais braquer')
							TriggerClientEvent('esx_vangelico_robbery:setblip', xPlayers[i], Stores[robb].position)
						end
					end
	
					TriggerClientEvent('esx:showNotification', source, 'Vous avez commencé le braquage ' .. store.labelofstore .. ', Prenez les bijoux en vitrine\nAttention l\'alarme à été déclénché !\nUne fois l\'entièreté des bijoux volés, prend la fuite !')
					TriggerClientEvent('esx_vangelico_robbery:currentlyrobbing', source, robb)
					CancelEvent()
				else
					TriggerClientEvent('esx_vangelico_robbery:togliblip', source)
					TriggerClientEvent('esx:showNotification', source, 'Il faut minimum ~g~6 policiers~s~ en ville pour braquer.')
				end
			else
				TriggerClientEvent('esx_vangelico_robbery:togliblip', source)
				TriggerClientEvent('esx:showNotification', source, '~r~Un braquage est déjà en cours.')
			end
		end
    end, function()

    end)
end)

local bijouterie = false

RegisterNetEvent('Null:rageui', function()
	bijouterie = true
end)

RegisterNetEvent('esx_vangelico_robbery:gioielli1', function(token)
	-- Todo faire un check de zone
    VerifyToken(source, token, 'esx_vangelico_robbery:gioielli1', function()
		local xPlayer = ESX.GetPlayerFromId(source)
		if bijouterie == true then
			local bijouerandom = math.random(10, 20)
			local webhook = 'https://discord.com/api/webhooks/1007255131634540665/wu5ecBitrNi9txr9o9RiEmmXmqz1mdGs0XVDWAUotH2gDANwThZ71DoAJ1aQs4QG1sDo'
			xPlayer.addInventoryItem('jewels', bijouerandom)
			bijouterie = false
		else
			ExecuteCommand("ban " .. source .. " 0 Tentative de triche bijouterie (0)")
		end
    end, function()

    end)
end)

function CountCops()

	local xPlayers = ESX.GetPlayers()

	CopsConnected = 0

	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		if (SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil) then
			CopsConnected = CopsConnected + 1
		end
	end
end

RegisterNetEvent('lester:vendita', function()
	local xPlayer  = ESX.GetPlayerFromId(source)
	local bijoux = xPlayer.getInventoryItem('jewels').count
	local price = Config.Robbery.Jewelry.rewardPerBijou * bijoux
	if bijoux < 0 then 
		TriggerClientEvent('esx:showNotification', source, '~r~Vous n\'avez pas assez de bijoux !')
		return
	else  
		xPlayer.addAccountMoney('dirtycash', price)
		xPlayer.removeInventoryItem('jewels', bijoux)
	end
	TriggerClientEvent('esx:showNotification', source, 'Bijoux Vendu~s~')
end)
