Status = {}

function GetStatus(name, cb)
	for i = 1, #Status, 1 do
		if Status[i].name == name then
			cb(Status[i])
			return
		end
	end
end

function GetStatusData(minimal)
	local status = {}

	for i = 1, #Status, 1 do
		if minimal then
			table.insert(status, {
				name = Status[i].name,
				val = Status[i].val,
				percent = (Status[i].val / Config_Status.StatusMax) * 100
			})
		else
			table.insert(status, {
				name = Status[i].name,
				val = Status[i].val,
				color = Status[i].color,
				max = Status[i].max,
				percent = (Status[i].val / Config_Status.StatusMax) * 100
			})
		end
	end

	return status
end

function RegisterStatus(name, default, color, tickCallback)
	local status = CreateStatus(name, default, color, tickCallback)
	table.insert(Status, status)
end

RegisterNetEvent('esx_status:load')
AddEventHandler('esx_status:load', function(status)
	if status ~= nil then 
		for i = 1, #Status, 1 do
			for j = 1, #status, 1 do
				if Status[i].name == status[j].name then
					Status[i].set(status[j].val)
				end
			end
		end
	end
end)

-- Boucle de décroissance — démarre indépendamment de `esx_status:load` afin
-- de continuer à tourner même si la ressource est restart en cours de session
-- (où esx:playerLoaded ne refire pas).
Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
	-- Attend que les status aient été enregistrés (RegisterStatus dans main.lua)
	while #Status == 0 do Citizen.Wait(100) end

	-- Demande au serveur l'état persistant si le load event a été manqué
	-- (ex : restart de ressource sans déconnexion). Le serveur renverra
	-- esx_status:load qui restaurera les valeurs depuis la BDD.
	TriggerServerEvent('esx_status:requestLoad')

	while true do
		for i = 1, #Status, 1 do
			Status[i].onTick()
		end

		TriggerEvent('esx_newui:updateBasics', GetStatusData(true))
		Citizen.Wait(Config_Status.TickTime)
	end
end))

RegisterNetEvent('esx_status:set')
AddEventHandler('esx_status:set', function(name, val)
	for i = 1, #Status, 1 do
		if Status[i].name == name then
			Status[i].set(val)
			break
		end
	end

	TriggerServerEvent('esx_status:update', GetStatusData(true))
	TriggerEvent('esx_newui:updateBasics', GetStatusData(true))
end)

RegisterNetEvent('esx_status:add')
AddEventHandler('esx_status:add', function(name, val)
	for i = 1, #Status, 1 do
		if Status[i].name == name then
			Status[i].add(val)
			break
		end
	end

	TriggerServerEvent('esx_status:update', GetStatusData(true))
	TriggerEvent('esx_newui:updateBasics', GetStatusData(true))
end)

AddEventHandler('esx_status:remove', function(name, val)
	for i = 1, #Status, 1 do
		if Status[i].name == name then
			Status[i].remove(val)
			break
		end
	end

	TriggerServerEvent('esx_status:update', GetStatusData(true))
	TriggerEvent('esx_newui:updateBasics', GetStatusData(true))
end)

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
	while true do
		Citizen.Wait(5*60*1000)
		TriggerServerEvent('esx_status:update', GetStatusData(true))
	end
end))