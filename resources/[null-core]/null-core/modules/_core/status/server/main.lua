

AlreadyDoUsableItem = {}
UsableItemDBLoad = false
UsableItemList = Config.UsableItems

function loadUsableItem()
	MySQL.Async.fetchAll('SELECT * FROM vusableitem', {}, function(result)
        for k,v in pairs(result) do
			UsableItemList[v.name] = {type=v.type, label=v.label,number=v.number}
		end
		UsableItemDBLoad = true
    end)
end

-- Renvoie la valeur actuelle d'un status pour un xPlayer, ou nil si introuvable
local function getPlayerStatusVal(xPlayer, statusName)
	local status = xPlayer.get('status')
	if type(status) ~= "table" then return nil end
	for _, s in ipairs(status) do
		if s.name == statusName then return tonumber(s.val) or 0 end
	end
	return nil
end

local STATUS_MAX = 1000000 -- aligné sur Config_Status.StatusMax (côté client)

function initUsableItem()
	for k,v in pairs(UsableItemList) do
		if AlreadyDoUsableItem[k] == nil then
			AlreadyDoUsableItem[k] = true
			ESX.RegisterUsableItem(k, function(source)
				local xPlayer = ESX.GetPlayerFromId(source)
				if v.type == "hunger" then
					-- Bloque la consommation si la jauge est déjà à 100%
					local cur = getPlayerStatusVal(xPlayer, "hunger") or 0
					if cur >= STATUS_MAX then
						TriggerClientEvent('esx:showNotification', source, "~o~Vous n'avez pas faim.")
						return
					end
					TriggerClientEvent('esx_status:add', source, "hunger", v.number*10000)
					TriggerClientEvent('esx_status:onEat', source, 'prop_cs_burger_01')
					TriggerClientEvent('esx:showNotification', source, "Vous avez manger "..v.label)
					if v.notRemove then return end
				elseif v.type == "thirst" then
					local cur = getPlayerStatusVal(xPlayer, "thirst") or 0
					if cur >= STATUS_MAX then
						TriggerClientEvent('esx:showNotification', source, "~o~Vous n'avez pas soif.")
						return
					end
					TriggerClientEvent('esx_status:add', source, "thirst", v.number*10000)
					TriggerClientEvent('esx_status:onEat', source, 'prop_ld_flow_bottle')
					TriggerClientEvent('esx:showNotification', source, "Vous avez bu "..v.label)
					if v.notRemove then return end
				elseif v.type == "drunk" then
					TriggerClientEvent('esx_status:add', source, 'drunk', v.number*10000)
					TriggerClientEvent('esx_status:onDrinkAlcohol', source)
					TriggerClientEvent('esx:showNotification', source, "Vous avez bu "..v.label)
					if v.notRemove then return end
				elseif v.type == "drug" then
					TriggerClientEvent('esx_status:add', source, 'drug', v.number*10000)
					TriggerClientEvent('esx_status:onWeed', source)
					TriggerClientEvent('esx:showNotification', source, "Vous avez consomer "..v.label)
					if v.notRemove then return end
				elseif v.type == "heal" then
					if GetEntityHealth(GetPlayerPed(source)) >= 200 then
						return
					end
					TriggerClientEvent("Null:UseItemsEMS", source, k, v.number, v.time*1000)
					if v.notRemove then return end
				elseif v.type == "armor" then
					if GetPedArmour(GetPlayerPed(source)) >= 100 then
						return
					end
					TriggerClientEvent("Null:UseItemsEMS", source, k, 0, v.time*1000)
					SetPedArmour(GetPlayerPed(source), v.number)
					if v.notRemove then return end
				elseif v.type == "command" then
					ExecuteCommand(v.command)
					if v.notRemove then return end
				elseif v.type == "clientevent" then
					TriggerClientEvent(v.event, source)
					if v.notRemove then return end
				elseif v.type == "function" then
					v.functions()
					if v.notRemove then return end
				end
				xPlayer.removeInventoryItem(k, 1)
			end)
		end
	end
end

function refreshUsableItem()
	loadUsableItem()
	while UsableItemDBLoad == false do
		Wait(1)
	end
	initUsableItem()
end

function addUsableItem(name,label,type,number)
	UsableItemList[name] = {type=type, label=label,number=number}
	initUsableItem()
end

RegisterServerEvent("null:usableitem:new", function (data)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() ~= "user" then
		MySQL.Async.fetchAll('SELECT * FROM `vusableitem` WHERE `name` = @name', {
			['@name'] = data.name,
		}, function(result)
			if result[1] == nil then 
                MySQL.Async.execute("INSERT INTO `vusableitem` (`name`, `label`, `type`, `number`) VALUES (@name, @label, @type, @number) ", {
                    ['@name'] = data.name,
                    ['@label'] = data.label,
                    ['@type'] = data.type,
                    ['@number'] = data.number
                })
				addUsableItem(data.name,data.label,data.type,data.number)
            end
        end)
	end
end)

RegisterServerEvent("null:item:new", function (data)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() ~= "user" then
		MySQL.Async.fetchAll('SELECT * FROM `items` WHERE `name` = @name', {
			['@name'] = data.name
		}, function(result)
			if result[1] == nil then 
                MySQL.Async.execute("INSERT INTO `items` (`name`, `label`, `weight`) VALUES (@name, @label, @weight) ", {
                    ['@name'] = data.name,
                    ['@label'] = data.label,
                    ['@weight'] = data.weight or 1
                })
				ExecuteCommand("refreshGlobalsInformations")
            end
        end)
	end
end)


Citizen.CreateThread(function()
	loadUsableItem()
	while UsableItemDBLoad == false do
		Wait(1)
	end
	initUsableItem()
end)

RegisterCommand("heal", function(source, args, rawCommand)
	if source == 0 then
		if args[1] ~= nil then
			local target = tonumber(args[1])
	
			if GetPlayerName(target) then
				TriggerClientEvent('esx_status:healPlayer', target)
			end
		end
	else
		local xPlayer = ESX.GetPlayerFromId(source)
		if xPlayer.getGroup() ~= 'user' then 
			if not xPlayer.getStaffMode() then return end
			if tonumber(args[1]) then
				local target = tonumber(args[1])
				local xTarget = ESX.GetPlayerFromId(target)
		
				if GetPlayerName(target) then
					TriggerClientEvent('esx_status:healPlayer', target)
					null.logs.adminCommand("heal", xPlayer, xTarget)
				else
					TriggerClientEvent('chatMessage', source, "HEAL", {255, 0, 0}, "Player not found!")
				end
			else
				null.logs.adminCommand("heal", xPlayer)
				TriggerClientEvent('esx_status:healPlayer', source)
			end
		end
	end
end)

-- ============================================================
-- Commande console : reset des status d'un joueur
-- Usage : resetstatus <serverId>
--   → faim/soif rétablies à 100%, drug/drunk remis à 0
-- ⚠ Uniquement exécutable depuis la console serveur (source == 0)
-- ============================================================
RegisterCommand('resetstatus', function(source, args)
	if source ~= 0 then
		-- Bloque toute exécution in-game (joueur ou admin)
		return
	end

	local target = tonumber(args[1])
	if not target then
		print("[status] Usage : resetstatus <serverId>")
		return
	end

	local xPlayer = ESX.GetPlayerFromId(target)
	if not xPlayer then
		print(("[status] Joueur introuvable (id=%s)"):format(tostring(target)))
		return
	end

	TriggerClientEvent('esx_status:resetStatus', target)
	TriggerClientEvent('esx:showNotification', target, "~b~Vos status (faim/soif/drogue/alcool) ont été réinitialisés.")
	print(("[status] Status reset pour %s (id=%d, ident=%s)")
		:format(GetPlayerName(target) or "?", target, xPlayer.identifier))
end, true)