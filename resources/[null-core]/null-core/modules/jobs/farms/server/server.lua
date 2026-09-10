EntrepriseFarmList = {}
local ListeItemRecolt = {}
local ListeItemTraitement = {}
EntrepriseCounter = 0

RegisterNetEvent('Null:CreateFarmEntreprise', function(namejob, labeljob, namerecolteitem, labelrecolteitem, PositionRecolte, nametraitementitem, labeltraitementitem, PositionTraitement, PositionVente, PositionCoffreEntreprise, PositionVestiaire)
    local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        if SaveData.json["entreprises"]["Farm"][namejob] ~= nil then 
            return ESX.ShowNotification("Cette Entreprise Farm Existe déjà")
        end
        null.fct.sql.CheckJobAndCreate(namejob, labeljob)
        null.fct.sql.CheckSocietyAndCreate(namejob, labeljob)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "PDG", "boss", 2)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Responsable", "responsable", 1)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Employer", "employer", 0)
        SaveData.json["entreprises"]["Farm"][namejob] = {}
        SaveData.json["entreprises"]["Farm"][namejob].type = 'Farm'
        SaveData.json["entreprises"]["Farm"][namejob].name = namejob
        SaveData.json["entreprises"]["Farm"][namejob].label = labeljob
        SaveData.json["entreprises"]["Farm"][namejob].namerecolteitem = namerecolteitem
        SaveData.json["entreprises"]["Farm"][namejob].nametraitementitem = nametraitementitem
        SaveData.json["entreprises"]["Farm"][namejob].PosBoss = PositionCoffreEntreprise
        SaveData.json["entreprises"]["Farm"][namejob].RecolteItem = namerecolteitem
        SaveData.json["entreprises"]["Farm"][namejob].PosRecolte = PositionRecolte
        SaveData.json["entreprises"]["Farm"][namejob].TraitementItem = nametraitementitem
        SaveData.json["entreprises"]["Farm"][namejob].PosTraitement = PositionTraitement
        SaveData.json["entreprises"]["Farm"][namejob].PosVente = PositionVente
        SaveData.json["entreprises"]["Farm"][namejob].PosVestiaire = PositionVestiaire
        ListeItemRecolt[namerecolteitem] = {}
        ListeItemRecolt[namerecolteitem].name = namerecolteitem
        ListeItemTraitement[nametraitementitem] = {}
        ListeItemTraitement[nametraitementitem].name = nametraitementitem
        SocietyCache[namejob] = {}
        SocietyCache[namejob].name = namejob
        SocietyCache[namejob].data = {
            ['weapons'] = {},
            ['items'] = {},
            ['accounts'] = {
                cash = 0,
                dirtycash = 0,
            },
        }
        TriggerEvent('Null:CreateNewItem', {src = source, name = namerecolteitem, label = labelrecolteitem})
        TriggerEvent('Null:CreateNewItem', {src = source, name = nametraitementitem, label = labeltraitementitem})
        Cache.SaveOne('entreprises')
        TriggerClientEvent('esx:showNotification', source, 'Le Job à été crée avec succès')
        Wait(1000)
        ExecuteCommand('refreshGlobalsInformations')
        TriggerClientEvent('Null:SendEntrepriseFarmList', -1, SaveData.json["entreprises"]["Farm"])
    end
end)

Citizen.CreateThread(function()
    local EntrepriseCounter = 0
    while SaveData.json["entreprises"] == nil do Wait(10) end

    for k,v in pairs(SaveData.json["entreprises"]["Farm"]) do
        if v.namerecolteitem ~= nil and v.nametraitementitem ~= nil then 
            ListeItemRecolt[v.namerecolteitem] = {}
            ListeItemRecolt[v.namerecolteitem].name = v.namerecolteitem
            ListeItemTraitement[v.nametraitementitem] = {}
            ListeItemTraitement[v.nametraitementitem].name = v.nametraitementitem
        end
    end
end)

function addRestaurantToFarm(data)
    EntrepriseCounter = EntrepriseCounter +1
    SaveData.json["entreprises"]["Farm"][data.name] = {}
    SaveData.json["entreprises"]["Farm"][data.name].type = data.type 
    SaveData.json["entreprises"]["Farm"][data.name].name = data.name
    SaveData.json["entreprises"]["Farm"][data.name].label = data.label
    SaveData.json["entreprises"]["Farm"][data.name].RecolteItem = {}
    for k,v in pairs(data.crafts) do for _,x in pairs(v.Requirements) do table.insert(SaveData.json["entreprises"]["Farm"][data.name].RecolteItem, {name = x.ItemName, label = x.Label}) end end
    SaveData.json["entreprises"]["Farm"][data.name].PosTraitement = data.PosTraitement
    TriggerClientEvent('Null:SendEntrepriseFarmList', -1, SaveData.json["entreprises"]["Farm"])
end

RegisterNetEvent('Null:initFarmSociety', function()
    local src = source
    TriggerClientEvent('Null:SendEntrepriseFarmList', src, SaveData.json["entreprises"]["Farm"])
end)

local function Activity(source, itemRecolte, type, ItemTraitement, society, type2)
	if SaveData.FarmPlayers[source] then
		local xPlayer  = ESX.GetPlayerFromId(source)
        if type2 == "Restaurant" then
            local find = false
            for k,v in pairs(SaveData.json["entreprises"]["Farm"][society].RecolteItem) do
                if v.name == itemRecolte then
                    find = true
                    break
                end
            end
            if not find then return end
            if not xPlayer.canCarryItem(itemRecolte, 1) then
                xPlayer.showNotification('Vous êtes trop lourd pour faire ceci')
            else
                if SaveData.FarmsJobTotalPerPlayers["recolte"][xPlayer.source] == nil then
                    SaveData.FarmsJobTotalPerPlayers["recolte"][xPlayer.source] = 0
                end
                TriggerClientEvent('framework:farmanimation', source, 6000)
                Citizen.Wait(6000)
                local harvestQty = 1
                pcall(function()
                    local boostPct = exports["null-core"]:GetVIPFarmHarvestBoost(xPlayer.identifier)
                    if boostPct and boostPct > 0 then harvestQty = 2 end
                end)
                xPlayer.addInventoryItem(itemRecolte, harvestQty)
                SaveData.FarmsJobTotalPerPlayers["recolte"][xPlayer.source] = SaveData.FarmsJobTotalPerPlayers["recolte"][xPlayer.source] + harvestQty
                TriggerClientEvent("inventory:sendMessage", xPlayer.source, ('🌿 Vous avez récuperer ~y~+%s~s~ %s'):format(SaveData.FarmsJobTotalPerPlayers["recolte"][xPlayer.source], ESX.GetItemLabel(itemRecolte)), 10000)
                Activity(source, itemRecolte, type, ItemTraitement, society, type2)
            end
        else
            if type == 1 then -- Recolte
                if ListeItemRecolt[itemRecolte] == nil then
                    ExecuteCommand("ban " .. source .. " 0 Tentative de triche farm (0)")
                else
                    if ListeItemRecolt[itemRecolte].name == itemRecolte then
                        local Quantity = xPlayer.getInventoryItem(itemRecolte).count
                        if not xPlayer.canCarryItem(ListeItemRecolt[itemRecolte].name, 1) then
                            xPlayer.showNotification('Vous êtes trop lourd pour faire ceci')
                        else
                            if SaveData.FarmsJobTotalPerPlayers["recolte"][xPlayer.source] == nil then
                                SaveData.FarmsJobTotalPerPlayers["recolte"][xPlayer.source] = 0
                            end
                            TriggerClientEvent('framework:farmanimation', source)
                            Citizen.Wait(Config.Farming.VitesseAnimation)
                            local harvestQty = 1
                            pcall(function()
                                local boostPct = exports["null-core"]:GetVIPFarmHarvestBoost(xPlayer.identifier)
                                if boostPct and boostPct > 0 then harvestQty = 2 end
                            end)
                            xPlayer.addInventoryItem(itemRecolte, harvestQty)
                            SaveData.FarmsJobTotalPerPlayers["recolte"][xPlayer.source] = SaveData.FarmsJobTotalPerPlayers["recolte"][xPlayer.source] + harvestQty
                            TriggerClientEvent("inventory:sendMessage", xPlayer.source, ('🌿 Vous avez récolté ~y~+%s~s~ %s'):format(SaveData.FarmsJobTotalPerPlayers["recolte"][xPlayer.source], ESX.GetItemLabel(itemRecolte)))
                            Activity(source, itemRecolte, type, ItemTraitement, society)
                        end
                    else
                        TriggerEvent('ewenlpb_fantadmin:ban', source, source, 'Tricher est interdit ( Activité Légal )', 0)
                    end
                end
            elseif type == 2 then -- Traitement
                if ListeItemRecolt[itemRecolte] == nil or ListeItemTraitement[ItemTraitement] == nil then
                    ExecuteCommand("ban " .. source .. " 0 Tentative de triche farm (1)")
                else
                    if ListeItemRecolt[itemRecolte].name == itemRecolte or ListeItemTraitement[ItemTraitement].name == ItemTraitement then
                        local Quantity = xPlayer.getInventoryItem(itemRecolte).count
                        local Quantity2 = xPlayer.getInventoryItem(ItemTraitement).count
                        if xPlayer.canSwapItem(itemRecolte, 1, ItemTraitement, 1) then
                            if SaveData.FarmsJobTotalPerPlayers["traitement"][xPlayer.source] == nil then
                                SaveData.FarmsJobTotalPerPlayers["traitement"][xPlayer.source] = 0
                            end
                            xPlayer.removeInventoryItem(itemRecolte, 1)
                            xPlayer.addInventoryItem(ItemTraitement, 1)
                            SaveData.FarmsJobTotalPerPlayers["traitement"][xPlayer.source] = SaveData.FarmsJobTotalPerPlayers["traitement"][xPlayer.source] + 1
                            TriggerClientEvent("inventory:sendMessage", xPlayer.source, ('🌿 Vous avez traiter ~y~+%s~s~ %s'):format(SaveData.FarmsJobTotalPerPlayers["traitement"][xPlayer.source], ESX.GetItemLabel(ItemTraitement)))
                            TriggerClientEvent('framework:farmanimation', source)
                            Citizen.Wait(1500)
                            Activity(source, itemRecolte, type, ItemTraitement, society)
                        else
                            xPlayer.showNotification('Vous êtes trop lourd pour faire ceci')
                        end
                    else
                        ExecuteCommand("ban " .. source .. " 0 Tentative de triche farm (2)")
                    end
                end
            elseif type == 3 then -- Vente
                null.DebugPrint(ListeItemTraitement[ItemTraitement], ListeItemTraitement, ItemTraitement)
                if ListeItemTraitement[ItemTraitement] == nil then
                    ExecuteCommand("ban " .. source .. " 0 Tentative de triche farm (3)")
                else
                    if ListeItemTraitement[ItemTraitement].name == ItemTraitement then
                        local Quantity = xPlayer.getInventoryItem(ItemTraitement).count
                        if Quantity <= 0 then
                            TriggerClientEvent("inventory:sendMessage", xPlayer.source, '❌ Vous n\'avez rien a traiter')
                        else					
                            TriggerClientEvent('framework:farmanimation', source)
                            Citizen.Wait(Config.Farming.VitesseAnimation)
                            if SaveData.FarmsJobTotalPerPlayers["vente"][xPlayer.source] == nil then
                                SaveData.FarmsJobTotalPerPlayers["vente"][xPlayer.source] = 0
                            end
                            local farmBoostPct = 0
                            pcall(function()
                                farmBoostPct = exports["null-core"]:GetVIPFarmSellBoost(xPlayer.identifier) or 0
                            end)
                            local sellPrice = math.floor(Config.Farming.PricePerSell * (1 + farmBoostPct / 100))
                            local societyReward = farmBoostPct > 0 and 2000 or 1000
                            local vipLabel = farmBoostPct > 0 and (" (VIP +"..farmBoostPct.."%%)") or ""
                            xPlayer.removeInventoryItem(ItemTraitement, 1)
                            xPlayer.addAccountMoney("cash", sellPrice)
                            SaveData.FarmsJobTotalPerPlayers["vente"][xPlayer.source] = SaveData.FarmsJobTotalPerPlayers["vente"][xPlayer.source] + sellPrice
                            SocietyCache[society].data["accounts"].cash = SocietyCache[society].data["accounts"].cash + societyReward
                            addHistorySociety(xPlayer.getJob().name, "Gains : Vente 1x "..ESX.GetItemLabel(ItemTraitement), "~n~Auteur: "..xPlayer.getName().." ("..xPlayer.idunique..")"..vipLabel.."~n~Total Gagner : "..SaveData.FarmsJobTotalPerPlayers["vente"][xPlayer.source].."$~n~", societyReward)
                            TriggerClientEvent("inventory:sendMessage", xPlayer.source, ('💵 Vous avez vendu ~y~+%s$~s~'):format(SaveData.FarmsJobTotalPerPlayers["vente"][xPlayer.source]))
                            Activity(source, itemRecolte, type, ItemTraitement, society)
                        end
                    else
                        ExecuteCommand("ban " .. source .. " 0 Tentative de triche farm (4)")
                    end
                end
            else
                ExecuteCommand("ban " .. source .. " 0 Tentative de triche farm (5)")
            end
        end
    end

    RegisterNetEvent('framework:stopActivity', function()
        local src = source
        SaveData.FarmPlayers[src] = false
        Wait(3000)
        SaveData.FarmsJobTotalPerPlayers["vente"][src] = 0
        SaveData.FarmsJobTotalPerPlayers["traitement"][src] = 0
        SaveData.FarmsJobTotalPerPlayers["recolte"][src] = 0
    end)
    
	if #(GetEntityCoords(GetPlayerPed(source)) - vector3(position.x, position.y, position.z)) < 100 then
		SaveData.FarmPlayers[source] = true
		Activity(source, itemRecolte, type, ItemTraitement, society, type2)
	else
		ExecuteCommand("ban " .. source .. " 0 Tentative de triche farm (6)")
	end
end

RegisterNetEvent('framework:stopActivity', function()
    local src = source
	SaveData.FarmPlayers[src] = false
    Wait(3000)
    SaveData.FarmsJobTotalPerPlayers["vente"][src] = 0
    SaveData.FarmsJobTotalPerPlayers["traitement"][src] = 0
    SaveData.FarmsJobTotalPerPlayers["recolte"][src] = 0
end)

RegisterNetEvent('Null:DeleteFarms', function(value)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		if SaveData.json["entreprises"]["Farm"][value] then
			SaveData.json["entreprises"]["Farm"][value] = nil
            Cache.SaveOne('entreprises')
            TriggerClientEvent('Null:SendEntrepriseFarmList', -1, SaveData.json["entreprises"]["Farm"])
        else
            print("Tentative de suppression d'une entreprise inexistante ("..value..")")
		end
	end
end)
