--[[local ActifsEvents = {}
RegisterNetEvent('AKService:StartEventsStaff')
AddEventHandler('AKService:StartEventsStaff', function(type, time)
	table.insert(ActifsEvents, {name = GetPlayerName(source), down = true, type = type, time = time*60*1000})
end)

ESX.RegisterServerCallback('AKService:GetEventStarted', function(source, cb)
	if ActifsEvents ~= nil then
		cb(ActifsEvents)
	end
end)

RegisterServerEvent('AKService:RemoveEvents')
AddEventHandler('AKService:RemoveEvents', function(k)
	table.remove(ActifsEvents, k)
end)

ESX.RegisterServerCallback('AKService:getPlayerCoords', function(source, cb, plyid)
	cb(GetEntityCoords(GetPlayerPed(plyid)))
end)

-- Events

local eventStarted = true
RegisterNetEvent("AKService:StartsEvents")
AddEventHandler("AKService:StartsEvents", function(type, time, number)
	local randomEvent = ConfigEvents.Events[type]
	local i = math.random(1, #randomEvent.possibleZone)
	local zone = randomEvent.possibleZone[i]
	TriggerClientEvent("AKService:SendsEvents", -1, randomEvent, zone, time)
	Citizen.Wait(time*60*1000)
	TriggerClientEvent("AKService:DeleteEvent", -1)
	if eventStarted then
		TriggerClientEvent("AKService:StopsEvents", -1)
	end
end)

RegisterNetEvent("AKService:TakeRecInsEvents")
AddEventHandler("AKService:TakeRecInsEvents", function()
	TriggerClientEvent("AKService:StopsEvents", -1)
	eventStarted = false
end)

RegisterNetEvent("AKService:GetItemInsEvents")
AddEventHandler("AKService:GetItemInsEvents", function(item, nombre)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.addInventoryItem(item, nombre)
end)

RegisterNetEvent("AKService:GetMoneyInsEvents")
AddEventHandler("AKService:GetMoneyInsEvents", function(nombre)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.addAccountMoney('money',nombre)
end)]]