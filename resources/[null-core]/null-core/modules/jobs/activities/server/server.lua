RegisterNetEvent('framework:createactivitylegal', function(ActivityName, PosRecolte, ItemRecolte, ItemRecolteLabel, PosTraitement, ItemTraitement, ItemTraitementLabel, PosVente, PrixVente, illegal)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		MySQL.Async.execute("INSERT INTO `activity` (`name`, `recolte`, `itemrecolte`, `traitement`, `itemtraitement`, `vente`, `PrixVente`, `illegal`) VALUES (@name, @recolte, @itemrecolte, @traitement, @itemtraitement, @vente, @PrixVente, @illegal) ", {
			['@name'] = ActivityName,
			['@recolte'] = json.encode(PosRecolte),
			['@itemrecolte'] = ItemRecolte,
			['@traitement'] = json.encode(PosTraitement),
			['@itemtraitement'] = ItemTraitement,
			['@vente'] = json.encode(PosVente),
			['@PrixVente'] = PrixVente,
			['@illegal'] = illegal,
		})
		MySQL.Async.execute("INSERT INTO `items` (`name`, `label`, `weight`) VALUES (@name, @label, @weight) ", {
			['@name'] = ItemRecolte,
			['@label'] = ItemRecolteLabel,
			['@weight'] = 1
		})
		MySQL.Async.execute("INSERT INTO `items` (`name`, `label`, `weight`) VALUES (@name, @label, @weight) ", {
			['@name'] = ItemTraitement,
			['@label'] = ItemTraitementLabel,
			['@weight'] = 1
		})
		xPlayer.showNotification('Vous avez crée une nouvelle activité de Farm.')
	else
		ExecuteCommand("ban " .. source .. " 0 Tentative de triche farming (0)")
	end
end)

ListeActivity = {}
ListeItemRecolt = {}
ListeItemTraitement = {}
function LoadActivity()
	MySQL.Async.fetchAll('SELECT * FROM activity', {}, function(Activity)
        for i=1, #Activity, 1 do
			spritblip = 682
			if Activity[i].blipid ~= nil then
				spritblip = Activity[i].blipid
			end
            table.insert(ListeActivity, {
				id = Activity[i].id,
				blipid = spritblip,
                name = Activity[i].name,
                recolte = json.decode(Activity[i].recolte), 
                ItemRecolte = Activity[i].itemrecolte,
                traitement = json.decode(Activity[i].traitement),
                ItemTraitement = Activity[i].itemtraitement,
				vente = json.decode(Activity[i].vente),
				illegal = Activity[i].illegal
			})
			-- SECURITE RECOLTE
			if not ListeItemRecolt[Activity[i].itemrecolte] then ListeItemRecolt[Activity[i].itemrecolte] = {} end
			ListeItemRecolt[Activity[i].itemrecolte].name = Activity[i].itemrecolte
			-- SECURITE TRAITEMENT
			if not ListeItemTraitement[Activity[i].itemtraitement] then ListeItemTraitement[Activity[i].itemtraitement] = {} end
			ListeItemTraitement[Activity[i].itemtraitement].name = Activity[i].itemtraitement
			ListeItemTraitement[Activity[i].itemtraitement].price = Activity[i].PrixVente
			if Activity[i].illegal == 0 then 
				--TriggerClientEvent("Null:AddClientBlipFarm", -1, vector3(json.decode(Activity[i].recolte).x, json.decode(Activity[i].recolte).y, json.decode(Activity[i].recolte).z), spritblip, ESX.Config("serverColor").."Activité Farming ~s~ | Récolte "..Activity[i].name)
				--TriggerClientEvent("Null:AddClientBlipFarm", -1, vector3(json.decode(Activity[i].traitement).x, json.decode(Activity[i].traitement).y, json.decode(Activity[i].traitement).z), spritblip, ESX.Config("serverColor").."Activité Farming ~s~ | Traitement "..Activity[i].name)
				--TriggerClientEvent("Null:AddClientBlipFarm", -1, vector3(json.decode(Activity[i].vente).x, json.decode(Activity[i].vente).y, json.decode(Activity[i].vente).z), spritblip, ESX.Config("serverColor").."Activité Farming ~s~ | Vente "..Activity[i].name)
			end
		end

		TriggerEvent("null:core:recevieload:ActivityCount", #Activity)
		--Wait(10000)
		--null.DebugPrint('[^4LOAD^0] [^4'..#Activity..'^0] Activités ont été load avec succès')
    end)
end

MySQL.ready(function()
    LoadActivity()
end)

ESX.RegisterServerCallback('framework:LoadActivity', function(source, cb)
	cb(ListeActivity)
end)

local function Activity(source, itemRecolte, type, ItemTraitement, illegal)
	if SaveData.FarmPlayers[source] then
		local xPlayer  = ESX.GetPlayerFromId(source)
		if type == 1 then -- Recolte
			if ListeItemRecolt[itemRecolte] == nil then
				ExecuteCommand("ban " .. source .. " 0 Tentative de triche farming (1)")
			else
				if ListeItemRecolt[itemRecolte].name == itemRecolte then
					if not xPlayer.canCarryItem(itemRecolte, 1) then
						xPlayer.showNotification('Vous êtes trop lourd pour faire ceci')
					else
						TriggerClientEvent('framework:farmanimation', source)
						Citizen.Wait(1500)
						if SaveData.FarmsActivityTotalPerPlayers["recolte"][source] == nil then SaveData.FarmsActivityTotalPerPlayers["recolte"][source] = 0 end
						if GetVIP(xPlayer.identifier) then 
							xPlayer.addInventoryItem(itemRecolte, 2)
							SaveData.FarmsActivityTotalPerPlayers["recolte"][source] = SaveData.FarmsActivityTotalPerPlayers["recolte"][source] + 2
						else
							xPlayer.addInventoryItem(itemRecolte, 1)
							SaveData.FarmsActivityTotalPerPlayers["recolte"][source] = SaveData.FarmsActivityTotalPerPlayers["recolte"][source] + 1
						end
                        TriggerClientEvent("inventory:sendMessage", xPlayer.source, ('🌿 Vous avez récolté ~y~+%s~s~ %s'):format(SaveData.FarmsActivityTotalPerPlayers["recolte"][source], ESX.GetItemLabel(itemRecolte)))
						

						
						Activity(source, itemRecolte, type, ItemTraitement, illegal)
					end
				else
                    ExecuteCommand("ban " .. source .. " 0 Tentative de triche farming (2)")
				end
			end
		elseif type == 2 then -- Traitement
			if ListeItemRecolt[itemRecolte] == nil or ListeItemTraitement[ItemTraitement] == nil then
                ExecuteCommand("ban " .. source .. " 0 Tentative de triche farming (3)")
			else
				if ListeItemRecolt[itemRecolte] == itemRecolte or ListeItemTraitement[itemTraitement] == itemTraitement then
					if xPlayer.getInventoryItem(itemRecolte).count <= 0 then
                        TriggerClientEvent("inventory:sendMessage", xPlayer.source, '❌ Vous n\'avez rien a traiter')
					elseif not xPlayer.canCarryItem(ItemTraitement, 1) then
						xPlayer.showNotification('Vous êtes trop lourd pour faire ceci')
					else					
						if SaveData.FarmsActivityTotalPerPlayers["traitement"][source] == nil then SaveData.FarmsActivityTotalPerPlayers["traitement"][source] = 0 end
						TriggerClientEvent('framework:farmanimation', source)
						Citizen.Wait(1500)
						xPlayer.removeInventoryItem(itemRecolte, 1)
						SaveData.FarmsActivityTotalPerPlayers["traitement"][source] = SaveData.FarmsActivityTotalPerPlayers["traitement"][source] + 1
						xPlayer.addInventoryItem(ItemTraitement, 1)
                        TriggerClientEvent("inventory:sendMessage", xPlayer.source, ('🌿 Vous avez traiter ~y~+%s~s~ %s'):format(SaveData.FarmsActivityTotalPerPlayers["traitement"][source], ESX.GetItemLabel(ItemTraitement)))
						Activity(source, itemRecolte, type, ItemTraitement, illegal)
					end
				else
                    ExecuteCommand("ban " .. source .. " 0 Tentative de triche farming (4)")
				end
			end
		elseif type == 3 then -- Vente
			if ListeItemTraitement[ItemTraitement] == nil then
                ExecuteCommand("ban " .. source .. " 0 Tentative de triche farming (5)")
			else
				if ListeItemTraitement[itemTraitement] == itemTraitement then
					if xPlayer.getInventoryItem(ItemTraitement).count <= 0 then
                        TriggerClientEvent("inventory:sendMessage", xPlayer.source, '❌ Vous n\'avez rien a traiter')
					else
						TriggerClientEvent('framework:farmanimation', source)
						Citizen.Wait(1500)
						if SaveData.FarmsActivityTotalPerPlayers["vente"][source] == nil then SaveData.FarmsActivityTotalPerPlayers["vente"][source] = 0 end
                        local BoostOrVip, BoostId, BoostTime, BoostBonus = null.fct.BoostAndVip(xPlayer.identifier, xPlayer.source)
						if BoostOrVip == 2 then
							xPlayer.removeInventoryItem(ItemTraitement, 1)
							null.DebugPrint("==============VENTE FARMING (Avec Boosts et Vip)================")
							null.DebugPrint("Prix initial : "..ListeItemTraitement[ItemTraitement].price)
							null.DebugPrint("Prix avec Boost : "..(ListeItemTraitement[ItemTraitement].price*BoostBonus.sell))
							null.DebugPrint("Prix avec Boost + VIP : "..(ListeItemTraitement[ItemTraitement].price*BoostBonus.sell) + ListeItemTraitement[ItemTraitement].price)
							null.DebugPrint("=========================================================")
							if illegal ~= 1 then
								xPlayer.addAccountMoney('cash', (ListeItemTraitement[ItemTraitement].price*BoostBonus.sell) + ListeItemTraitement[ItemTraitement].price)
							else
								xPlayer.addAccountMoney('dirtycash', (ListeItemTraitement[ItemTraitement].price*BoostBonus.sell) + ListeItemTraitement[ItemTraitement].price)
							end
							SaveData.FarmsActivityTotalPerPlayers["vente"][source] = SaveData.FarmsActivityTotalPerPlayers["vente"][source] + (ListeItemTraitement[ItemTraitement].price*BoostBonus.sell) + ListeItemTraitement[ItemTraitement].price
							TriggerClientEvent("inventory:sendMessage", xPlayer.source, ('💵 Vous avez vendu ~y~+%s$~s~'):format(SaveData.FarmsActivityTotalPerPlayers["vente"][source]))
						elseif BoostOrVip == 1 then
							null.DebugPrint("==============VENTE FARMING (Avec Boosts/Vip)================")
							null.DebugPrint("Prix initial : "..ListeItemTraitement[ItemTraitement].price)
							null.DebugPrint("Prix avec Boost/Vip : "..(ListeItemTraitement[ItemTraitement].price*BoostBonus.sell))
							null.DebugPrint("=========================================================")
							xPlayer.removeInventoryItem(ItemTraitement, 1)
							if illegal ~= 1 then
								xPlayer.addAccountMoney('cash', ListeItemTraitement[ItemTraitement].price*BoostBonus.sell)
							else
								xPlayer.addAccountMoney('dirtycash', ListeItemTraitement[ItemTraitement].price*BoostBonus.sell)
							end
							xPlayer.showNotification('Vous avez gagné : '.. ListeItemTraitement[ItemTraitement].price*BoostBonus.sell)
							SaveData.FarmsActivityTotalPerPlayers["vente"][source] = SaveData.FarmsActivityTotalPerPlayers["vente"][source] + ListeItemTraitement[ItemTraitement].price*BoostBonus.sell
							TriggerClientEvent("inventory:sendMessage", xPlayer.source, ('💵 Vous avez vendu ~y~+%s$~s~'):format(SaveData.FarmsActivityTotalPerPlayers["vente"][source]))
						elseif BoostOrVip == 0 then
							xPlayer.removeInventoryItem(ItemTraitement, 1)
							if illegal ~= 1 then
								xPlayer.addAccountMoney('cash', ListeItemTraitement[ItemTraitement].price)
							else
								xPlayer.addAccountMoney('dirtycash', ListeItemTraitement[ItemTraitement].price)
							end
							xPlayer.showNotification('Vous avez gagné : '.. ListeItemTraitement[ItemTraitement].price)
							SaveData.FarmsActivityTotalPerPlayers["vente"][source] = SaveData.FarmsActivityTotalPerPlayers["vente"][source] + ListeItemTraitement[ItemTraitement].price
							TriggerClientEvent("inventory:sendMessage", xPlayer.source, ('💵 Vous avez vendu ~y~+%s$~s~'):format(SaveData.FarmsActivityTotalPerPlayers["vente"][source]))
						end

						Activity(source, itemRecolte, type, ItemTraitement, illegal)
					end
				else
                    ExecuteCommand("ban " .. source .. " 0 Tentative de triche farming (6)")
				end
			end
		else
            ExecuteCommand("ban " .. source .. " 0 Tentative de triche farming (7)")
		end
	end
end

RegisterNetEvent('framework:startActivityBuild', function(position, itemRecolte, type, ItemTraitement, illegal, token)
	VerifyToken(source, token, 'framework:startActivityBuild', function()
		if #(GetEntityCoords(GetPlayerPed(source)) - vector3(position.x, position.y, position.z)) < 10 then
			SaveData.FarmPlayers[source] = true
			Activity(source, itemRecolte, type, ItemTraitement, illegal)
		else
			ExecuteCommand("ban " .. source .. " 0 Tentative de triche farming (8)")
		end
    end, function()

    end)
end)

RegisterNetEvent('framework:stopActivityBuild', function()
	local src = source
	SaveData.FarmPlayers[source] = false
	Wait(3000)
	SaveData.FarmsActivityTotalPerPlayers["recolte"][src] = 0
	SaveData.FarmsActivityTotalPerPlayers["traitement"][src] = 0
	SaveData.FarmsActivityTotalPerPlayers["vente"][src] = 0
end)

RegisterCommand('createfarming', function(source,args)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		TriggerClientEvent('Null:openFarmBuilder', source)
	end
end)

RegisterServerEvent('framework:deleteactivity')
AddEventHandler('framework:deleteactivity', function(id)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		ListeActivity[id] = nil
		--TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
		MySQL.Async.execute('DELETE FROM activity WHERE `id` = @id', {
			['@id'] = id
		})
		xPlayer.showNotification(ESX.Config("serverName")..'~s~\nVous avez supprimer l\'entreprise farme #'..id)
	end
end)

RegisterServerEvent('framework:changeactivityblips')
AddEventHandler('framework:changeactivityblips', function(id, newsprit)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		MySQL.Async.execute('UPDATE activity SET blipid = @blipid WHERE id = @id', {
			['@blipid'] = newsprit,
			['@id'] = id
		})
		xPlayer.showNotification('Le blips était changer avec ~g~succés.')
		--ESX.ShowNotification("Le blips était changer avec ~g~succés")
	end
end)