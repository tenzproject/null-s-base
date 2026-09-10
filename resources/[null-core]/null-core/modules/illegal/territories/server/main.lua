territories = {}
territoriesShop = {}
local drugsss = nil
local drugs = {}
local playerProcessing = {}

function getConfianceMultiplier(gangname)
	if gangname == nil or gangname == "unemployed" then return 1.0 end
	local stats = getGroupeStat(gangname)
	if stats == nil then return 1.0 end
	local confiance = stats["confiance"] or 75.0
	return 1.0 + (2.0 * (1.0 - (confiance / 100.0)))
end

function getTerritoryLevelBonus(gangname)
	if gangname == nil or gangname == "unemployed" or gangname == "unemployed2" then
		return { maxCountSellBonus = 0, priceBonus = 1.0, waitMultiplier = 1.0 }
	end
	local level = 1
	local ok, result = pcall(function() return exports["null-core"]:GetGangLevel(gangname) end)
	if ok and result then level = result end
	if Config.Territories.levelBonuses then
		for _, bonus in ipairs(Config.Territories.levelBonuses) do
			if level >= bonus.minLevel and level <= bonus.maxLevel then
				return bonus
			end
		end
	end
	return { maxCountSellBonus = 0, priceBonus = 1.0, waitMultiplier = 1.0 }
end

Citizen.CreateThread(function()
	Wait(1000)
	drugsss = exports["null-core"]:getDrugs()
	while drugsss == nil do 
		Wait(10)
	end

	for k,v in pairs(exports["null-core"]:getDrugs()) do
		local tempPrice = Config.Drugs.Price
		if Config.CustomDrugsPrice[v["data"]["traitement"].name] ~= nil then 
			tempPrice = Config.CustomDrugsPrice[v["data"]["traitement"].name] 
		end
		drugs[v["data"]["traitement"].name] = {
			name = v["data"]["traitement"].name, 
			price = tempPrice
		}
	end

	for k,v in pairs(drugsss) do
		drugs[v["data"]["traitement"].name] = {
			name=v["data"]["traitement"].name
		}
	end
	drugs["weed_pooch"] = {
		name = "weed_pooch"
	}
	drugs["meth_pooch"] = {
		name = "meth_pooch"
	}
end)

if Config.CustomDrugsPrice == nil then Config.CustomDrugsPrice = {} end

Citizen.CreateThread(function()
	Wait(2000)
	initTerritories()
	initTerritoriesShop()
end)


function updateTerritoiresOwner(id, ownerLabel, ownerCount, owner)
	SaveData.json["territories"][id].ownerCount = ownerCount
	SaveData.json["territories"][id].ownerLabel = ownerLabel
	SaveData.json["territories"][id].owner = owner
    TriggerClientEvent('Null:RecevieTerritories', -1, SaveData.json["territories"])

	exports["null-core"]:ProgressGangMission(owner, "daily_territory_capture", 1)
	exports["null-core"]:ProgressGangMission(owner, "weekly_territory_captures", 1)
	exports["null-core"]:IncrementGangTerritoriesWon(owner)
	exports["null-core"]:AddGangXP(owner, 50)
end

function resetTerritoiresData(id)
	SaveData.json["territories"][id].data = {}
	SaveData.json["territories"][id].ownerCount = 0
	SaveData.json["territories"][id].ownerLabel = nil
	SaveData.json["territories"][id].owner = nil
    TriggerClientEvent('Null:RecevieTerritories', -1, SaveData.json["territories"])
	--MySQL.Async.execute("UPDATE `territories` SET `data` = '"..json.encode({}).."' WHERE `id` = '"..id.."'", {}, function()  end)
	--MySQL.Async.execute("UPDATE `territories` SET `ownerCount` = '0' WHERE `id` = '"..id.."'", {}, function()  end)
	--MySQL.Async.execute("UPDATE `territories` SET `ownerLabel` = NULL WHERE `id` = '"..id.."'", {}, function()  end)
	--MySQL.Async.execute("UPDATE `territories` SET `owner` = NULL WHERE `id` = '"..id.."'", {}, function()  end)
end

function getPointsInTerritories(id, ownername)
	return SaveData.json["territories"][id].data[ownername].count
end

function removePointsInTerritoires(id, ownername, nbr)
	SaveData.json["territories"][id].data[ownername].count = SaveData.json["territories"][id].data[ownername].count - nbr
end

function initTerritories()
	--[[territories = {}
    MySQL.Async.fetchAll("SELECT * FROM territories", {}, function(result)
		for k,v in pairs(result) do 
			local pos1 = json.decode(v.position)
			local pos2 = json.decode(v.pospnj)
			territories[v.id] = {
				id=v.id,
				name=v.name,
				owner=v.owner,
				ownerLabel=v.ownerLabel,
				ownerCount=v.ownerCount,
				maxSells=v.maxvente,
				minCops=v.minpolicer,
				points=json.decode(v.points),
				active=true,
				maxSell = 0,
				data=json.decode(v.data) or {},
				position=vector3(pos1.x,pos1.y,pos1.z),
				PNJ = {
					model = "a_m_m_og_boss_01",
					pos = vector3(pos2.x,pos2.y,pos2.z),
					heading = v.headpnj+0.01,
					voice = "GENERIC_HI",
					scenario = {
						active = false,
						name = "WORLD_HUMAN_CLIPBOARD",
						count = 0,
					},
					weapon = {
						active = true,
						weaponName = 'weapon_combatmg_mk2',
					},
					floatingText = {
						active = false,
						text = 'Vendeur d\'arme',
						color = 4,
					},
				}
			}
		end
    end)]]
end

function initTerritoriesShop()
	territoriesShop = {}
    MySQL.Async.fetchAll("SELECT * FROM territoriesshop", {}, function(result)
		for k,v in pairs(result) do 
			territoriesShop[v.name] = {
				id=v.id,
				name=v.name,
				label=v.label,
				type=v.type,
				price=v.price,
				points=v.points,
				territories_id=v.territories_id
			}
		end
    end)
end

Citizen.CreateThread(function()
	ESX.RegisterServerCallback('territories:getTerritoriesData', function(source, cb)
		local xPlayer = ESX.GetPlayerFromId(source)
		cb(SaveData.json["territories"])
	end)
	ESX.RegisterServerCallback('territories:getTerritoriesShop', function(source, cb, id)
		local xPlayer = ESX.GetPlayerFromId(source)
		local table = territoriesShop
		if id then
			table = {}
			for k,v in pairs(territoriesShop) do
				if v.territories_id and (v.territories_id == id or v.territories_id == 0) then
					table[k] = v
				end
			end
		end
		cb(table)
	end)
end)


RegisterNetEvent('Null:initTerritories', function()
    TriggerClientEvent('Null:RecevieTerritories', source, SaveData.json["territories"])
end)
RegisterNetEvent('Null:resetTerritoires', function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() ~= "user" then
		if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil and Config.GroupeHighPerm[xPlayer.getGroup()] == true then
			resetTerritoiresData(id)
		end
	end
end)
RegisterNetEvent('Null:resetAllTerritoires', function()
    local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() ~= "user" then
		if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil and Config.GroupeHighPerm[xPlayer.getGroup()] == true then
			for k,v in pairs(SaveData.json["territories"]) do
				resetTerritoiresData(v.id)
			end
		end
	end
end)

RegisterNetEvent('null:territories:addShop', function(data)
    if data ~= nil then
		if data.name == nil then return end
		if data.label == nil then return end
		if data.price == nil then return end
		if data.points == nil then return end
		if data.type == nil then return end

		MySQL.update("INSERT INTO `territoriesshop` (`name`, `label`, `type`, `price`, `points`, `territories_id`) VALUES (@name, @label, @type, @price, @points, @territories_id) ", {
            ['@name'] = data.name,
            ['@label'] = data.label,
			['@type'] = data.type,
			['@price'] = data.price,
			['@points'] = data.points,
			['@territories_id'] = data.territories_id,
        })

		Wait(100)
		initTerritoriesShop()
	end
end)

RegisterNetEvent('null:territories:create', function(data)
    if data ~= nil then
		if data.name == nil then return end
		if data.pos == nil then return end
		if data.points == nil then return end
		if data.pnj.pos == nil then return end
		if data.pnj.heading == nil then return end
		if data.minCops == nil then return end
		if data.maxSellsCops == nil then return end
		SaveData.json["territories"][#SaveData.json["territories"]+1] = {
			id = #SaveData.json["territories"]+1,
			name = data.name,
			owner = "",
			ownerLabel = "",
			ownerCount = 0,
			maxSells = data.maxSellsCops,
			minCops = data.minCops,
			points = data.points,
			territoryPoints = data.territoryPoints or {},
			active = true,
			maxSell = 0,
			data = {},
			position=data.pos,
			PNJ = {
				model = "a_m_m_og_boss_01",
				pos = data.pnj.pos,
				heading = data.pnj.heading+0.01,
				voice = "GENERIC_HI",
				scenario = {
					active = false,
					name = "WORLD_HUMAN_CLIPBOARD",
					count = 0,
				},
				weapon = {
					active = true,
					weaponName = 'weapon_combatmg_mk2',
				},
				floatingText = {
					active = false,
					text = 'Vendeur d\'arme',
					color = 4,
				},
			}
		}
		TriggerClientEvent('Null:RecevieTerritories', -1, SaveData.json["territories"])
	end
end)

RegisterNetEvent('null:territories:delete', function(id)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getGroup() == "user" then return end
	SaveData.json["territories"][id] = nil
	TriggerClientEvent('Null:RecevieTerritories', -1, SaveData.json["territories"])
end)

RegisterNetEvent('null:territories:buyShop', function(territoriesid, itemid, type)
	local xPlayer = ESX.GetPlayerFromId(source)
    if territoriesid ~= nil and itemid ~= nil then
		for k,v in pairs(territoriesShop) do
			if v.id == tonumber(itemid) then
				if type == "dirtycash" then
					if xPlayer.getAccount("cash").money >= v.price then
						xPlayer.removeAccountMoney("cash", v.price)
						if v.type == "weapon" then
							xPlayer.addWeapon(v.name, 0)
						elseif v.type == "item" then
							xPlayer.addInventoryItem(v.name, 1)
						end	
					else
						xPlayer.showNotification("Vous n'avez pas l'argent sur vous.")
					end
					break
				elseif type == "points" then
					local points = getPointsInTerritories(territoriesid,xPlayer.getJob2().name)
					if points ~= nil then
						if v.points <= points then
							removePointsInTerritoires(territoriesid,xPlayer.getJob2().name, v.points)
							if v.type == "weapon" then
								xPlayer.addWeapon(v.name, 0)
							elseif v.type == "item" then
								xPlayer.addInventoryItem(v.name, 1)
							end	
						else
							xPlayer.showNotification("❌ Vous n'avez pas asser de points.")
						end
					end
				end
			end
		end
	end
end)

RegisterNetEvent('null:territories:deleteShopItem', function(id)
	MySQL.Async.execute("DELETE FROM territoriesshop WHERE id = '"..id.."'")
	Wait(100)
	initTerritoriesShop()
end)

function isPointInPolygon(points, point, plyCoords)
    local intersectCount = 0
    local n = #points
    for i = 1, n do
        local j = i % n + 1
        local v1 = points[i]
        local v2 = points[j]
        if ((v1.y > point.y) ~= (v2.y > point.y)) and
           (point.x < (v2.x - v1.x) * (point.y - v1.y) / (v2.y - v1.y) + v1.x) then
            intersectCount = intersectCount + 1
        end
    end
    return intersectCount % 2 == 1
end

function getBoundingBox(points)
    local minX, minY = points[1].x, points[1].y
    local maxX, maxY = points[1].x, points[1].y

    for i = 2, #points do
        minX = math.min(minX, points[i].x)
        minY = math.min(minY, points[i].y)
        maxX = math.max(maxX, points[i].x)
        maxY = math.max(maxY, points[i].y)
    end

    return vector2(minX, minY), vector2(maxX, maxY)
end

local function generateRandomPositionInZone(points, source)
	local xPlayer = ESX.GetPlayerFromId(source)
    local minVec, maxVec = getBoundingBox(points)

    local randomPoint
    repeat
        local x = math.random() * (maxVec.x - minVec.x) + minVec.x
        local y = math.random() * (maxVec.y - minVec.y) + minVec.y
        randomPoint = vector2(x, y)
    until isPointInPolygon(points, randomPoint, xPlayer.getCoords())

    return randomPoint
end

function getCops()
    local xPlayers = ESX.GetPlayers()
    local copsConnected = 0

    for i = 1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		
		if (SaveData.json["entreprises"]["Police"][xPlayer.job.name] ~= nil) then
            copsConnected = copsConnected + 1
        end
    end
    return copsConnected
end

local function alertLSPDDrugSale(src, coords)
	local id = ("drugsale_%s_%s"):format(src, os.time())
	local msg = "Un civil signale une vente de stupéfiants."
	for _, playerId in ipairs(ESX.GetPlayers()) do
		local xTarget = ESX.GetPlayerFromId(playerId)
		if xTarget and xTarget.job and string.lower(xTarget.job.name or "") == "lspd" then
			TriggerClientEvent('esx:showAdvancedNotification', playerId, "DISPATCH 911", "Alerte stupéfiants", msg, "CHAR_CALL911")
			TriggerClientEvent('null:police:blips', playerId, id, "Vente de drogue", vector3(coords.x, coords.y, coords.z), 51, 1, "drugsale")
		end
	end

	SetTimeout(120000, function()
		for _, playerId in ipairs(ESX.GetPlayers()) do
			local xTarget = ESX.GetPlayerFromId(playerId)
			if xTarget and xTarget.job and string.lower(xTarget.job.name or "") == "lspd" then
				TriggerClientEvent('null:police:removeallblipswithtag', playerId, "drugsale")
			end
		end
	end)
end

local function getTerritoryById(id)
	if id == nil then return nil end
	for _, territory in pairs(SaveData.json["territories"]) do
		if territory.id == id then
			return territory
		end
	end
	return nil
end

local function getTerritoryByCoords(coords)
	if coords == nil then return nil end
	local point = vector2(coords.x, coords.y)
	for _, territory in pairs(SaveData.json["territories"]) do
		if territory.points and isPointInPolygon(territory.points, point, coords) then
			return territory
		end
	end
	return nil
end

local function getSellableDrug(xPlayer)
	local availableDrugs = {}
	for _, drugData in pairs(exports["null-core"]:getDrugs()) do
		local itemName = drugData["data"]["traitement"].name
		local tempPrice = Config.Drugs.Price
		if Config.CustomDrugsPrice[itemName] ~= nil then
			tempPrice = Config.CustomDrugsPrice[itemName]
		end
		availableDrugs[itemName] = {
			name = itemName,
			price = tempPrice
		}
	end

	for _, drug in pairs(availableDrugs) do
		local item = xPlayer.getInventoryItem(drug.name)
		if item ~= nil and item.count > 3 then
			return item, drug.price
		end
	end

	local weed = xPlayer.getInventoryItem("weed_pooch")
	if weed ~= nil and weed.count > 3 then
		return weed, LastMarket["weed"].DrugsRequestPrice * (1.0 - Config.Territories.removeInstedOfMarket / 100)
	end

	local meth = xPlayer.getInventoryItem("meth_pooch")
	if meth ~= nil and meth.count > 3 then
		return meth, LastMarket["meth"].DrugsRequestPrice * (1.0 - Config.Territories.removeInstedOfMarket / 100)
	end

	local coke = xPlayer.getInventoryItem("coke_pooch")
	if coke ~= nil and coke.count > 3 then
		return coke, LastMarket["coke"].DrugsRequestPrice * (1.0 - Config.Territories.removeInstedOfMarket / 100)
	end

	return nil, Config.Drugs.Price
end

local function updateMarketDemand(itemName, count, src)
	if itemName == "weed_pooch" then
		if (LastMarket["weed"].DrugsRequestCount - count) <= 0 then
			TriggerClientEvent('esx:showNotification', src, "Il n'y a plus de demande de Weed aujourd'hui.")
			return false, LastMarket["weed"].DrugsRequestPrice
		end
		LastMarket["weed"].DrugsRequestCount = LastMarket["weed"].DrugsRequestCount - count
		return true, LastMarket["weed"].DrugsRequestPrice
	elseif itemName == "meth_pooch" then
		if (LastMarket["meth"].DrugsRequestCount - count) <= 0 then
			TriggerClientEvent('esx:showNotification', src, "Il n'y a plus de demande de Meth aujourd'hui.")
			return false, LastMarket["meth"].DrugsRequestPrice
		end
		LastMarket["meth"].DrugsRequestCount = LastMarket["meth"].DrugsRequestCount - count
		return true, LastMarket["meth"].DrugsRequestPrice
	elseif itemName == "coke_pooch" then
		if (LastMarket["coke"].DrugsRequestCount - count) <= 0 then
			TriggerClientEvent('esx:showNotification', src, "Il n'y a plus de demande de Coke aujourd'hui.")
			return false, LastMarket["coke"].DrugsRequestPrice
		end
		LastMarket["coke"].DrugsRequestCount = LastMarket["coke"].DrugsRequestCount - count
		return true, LastMarket["coke"].DrugsRequestPrice
	end

	return true, nil
end

RegisterNetEvent('Null:territories:enterZone', function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
	if playerProcessing[source] then
		return
	end
	playerProcessing[source] = true
	local find = false
	for k,v in pairs(drugs) do
		if xPlayer.getInventoryItem(v.name) ~= nil then
			find = true
			break
		end
	end
	if not find then 
		null.DebugPrint("not drugs find")
		playerProcessing[source] = nil
		return 
	end

	local vv = nil
	for k,v in pairs(SaveData.json["territories"]) do
		if v.id == id then
			vv = v
			break
		end
	end

	if vv == nil then
		null.DebugPrint("territories not found")
		playerProcessing[source] = nil
		return 
	end
	if vv.minCops > getCops() then
		null.DebugPrint("not enough cops")
		playerProcessing[source] = nil
		return
	end
	if vv.maxSell >= Config.Drugs.maxSells then
		null.DebugPrint("max sell")
		playerProcessing[source] = nil
		return
	end

	local minX = vv.points[1].x
	local minY = vv.points[1].y
	local maxX = vv.points[1].x
	local maxY = vv.points[1].y
	
	for k,v in pairs(vv.points) do
		if v.x < minX then
			minX = v.x
		elseif v.x > maxX then
			maxX = v.x
		end
		if v.y < minY then
			minY = v.y
		elseif v.y > maxY then
			maxY = v.y
		end
	end
	local xPlayerEnter = ESX.GetPlayerFromId(source)
	local gangEnter = xPlayerEnter and xPlayerEnter.getJob2() and xPlayerEnter.getJob2().name or "unemployed"
	local confianceMult = getConfianceMultiplier(gangEnter)
	TriggerClientEvent("null:territories:addPoint", source,generateRandomPositionInZone(vv.points, source),vv.PNJ.pos.z-1,vv.id, confianceMult)
end)

RegisterNetEvent('Null:territories:retryPoint', function(id)
	local src = source
	if not playerProcessing[src] then
		null.DebugPrint("retryPoint for player "..src.." but not processing, ignoring")
		return
	end
	local xPlayer = ESX.GetPlayerFromId(src)
	local find = false
	for k,v in pairs(drugs) do
		if xPlayer.getInventoryItem(v.name) ~= nil then
			find = true
			break
		end
	end
	if not find then playerProcessing[src] = nil return end

	local vv = {}
	for k,v in pairs(SaveData.json["territories"]) do
		if v.id == id then
			vv = v
			break
		end
	end
	if vv == nil then playerProcessing[src] = nil return end
	if vv.minCops > getCops() then playerProcessing[src] = nil return end
	if vv.maxSell >= Config.Drugs.maxSells then playerProcessing[src] = nil return end

	local xPlayerRetry = ESX.GetPlayerFromId(src)
	local gangRetry = xPlayerRetry and xPlayerRetry.getJob2() and xPlayerRetry.getJob2().name or "unemployed"
	local confianceMultRetry = getConfianceMultiplier(gangRetry)
	TriggerClientEvent("null:territories:addPoint", src, generateRandomPositionInZone(vv.points, src), vv.PNJ.pos.z-1, vv.id, confianceMultRetry)
end)

RegisterNetEvent('Null:territories:exitZone', function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
	local vv = {}
	for k,v in pairs(SaveData.json["territories"]) do
		if v.id == id then
			vv = v
		end
	end

	playerProcessing[source] = nil
	TriggerClientEvent("null:territories:clearPoint", source)
end)


local npcSellCooldown = {}

local function sellDrugsToNpc(src, territoryId, pedNetId, coords, shouldContinueTerritoryLoop)
	local xPlayer = ESX.GetPlayerFromId(src)
	if not xPlayer then return end

	coords = coords or xPlayer.getCoords()
	local playerCoords = xPlayer.getCoords()
	if pedNetId and #(vector3(coords.x, coords.y, coords.z) - vector3(playerCoords.x, playerCoords.y, playerCoords.z)) > 5.0 then
		return
	end
	local selectDrugs, selectedDrugsPrice = getSellableDrug(xPlayer)
	if not selectDrugs then
		playerProcessing[src] = nil
		xPlayer.showNotification("Vous n'avez pas de drogue sur vous !")
		TriggerClientEvent("null:territories:clearPoint", src)
		if pedNetId then
			TriggerClientEvent("null:territories:npcSellResult", src, pedNetId, "nodrugs")
		end
		return
	end

	if pedNetId and npcSellCooldown[src] and npcSellCooldown[src] > os.time() then
		xPlayer.showNotification("Attendez un peu avant de reproposer à quelqu'un.")
		TriggerClientEvent("null:territories:npcSellResult", src, pedNetId, "cooldown")
		return
	end

	if pedNetId and math.random(1, 20) == 1 then
		alertLSPDDrugSale(src, coords)
	end

	if pedNetId and math.random(1, 3) == 1 then
		npcSellCooldown[src] = os.time() + 5
		xPlayer.showNotification("La personne refuse votre proposition.")
		TriggerClientEvent("null:territories:npcSellResult", src, pedNetId, "refused")
		return
	end

	local vv = territoryId and getTerritoryById(territoryId) or getTerritoryByCoords(coords)
	local inTerritory = vv ~= nil
	local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed"
	local levelBonus = inTerritory and getTerritoryLevelBonus(gangname) or { maxCountSellBonus = 0, priceBonus = 1.0, waitMultiplier = 1.0 }
	local maxCount = Config.Drugs.maxCountSell + levelBonus.maxCountSellBonus
	local count = math.min(maxCount, selectDrugs.count)

	if inTerritory then
		local nbrCops = getCops()
		if vv.minCops > nbrCops then
			playerProcessing[src] = nil
			TriggerClientEvent("null:territories:clearPoint", src)
			xPlayer.showNotification("Il n'y a pas asser de policier en ville")
			if pedNetId then
				TriggerClientEvent("null:territories:npcSellResult", src, pedNetId, "blocked")
			end
			return
		end
		if vv.maxSell >= Config.Drugs.maxSells or vv.maxSell + count >= Config.Drugs.maxSells then
			playerProcessing[src] = nil
			TriggerClientEvent("null:territories:clearPoint", src)
			xPlayer.showNotification("Vous ne pouvez plus vendre ici pour aujourd'hui !")
			if pedNetId then
				TriggerClientEvent("null:territories:npcSellResult", src, pedNetId, "blocked")
			end
			return
		end
	end

	local soldCount = math.random(1, count)
	local marketOk, marketPrice = updateMarketDemand(selectDrugs.name, soldCount, src)
	if not marketOk then
		playerProcessing[src] = nil
		TriggerClientEvent("null:territories:clearPoint", src)
		if pedNetId then
			TriggerClientEvent("null:territories:npcSellResult", src, pedNetId, "blocked")
		end
		return
	end
	if marketPrice then
		selectedDrugsPrice = marketPrice
	end

	if inTerritory and gangname ~= "unemployed" and SaveData.gangs[gangname] ~= nil then
		local ganglabel = xPlayer.getJob2().label
		local territoryData = SaveData.json["territories"][vv.id]
		local isDefending = territoryData.owner == gangname

		if territoryData.data[gangname] ~= nil then
			territoryData.data[gangname].count = territoryData.data[gangname].count + soldCount
			if territoryData.ownerCount < territoryData.data[gangname].count then
				updateTerritoiresOwner(vv.id, ganglabel, territoryData.data[gangname].count, gangname)
			end
		else
			territoryData.data[gangname] = { count = soldCount }
		end

		if isDefending then
			exports["null-core"]:ProgressGangMission(gangname, "daily_territory_defend", 1)
		end
	end

	if inTerritory then
		SaveData.json["territories"][vv.id].maxSell = SaveData.json["territories"][vv.id].maxSell + soldCount
	end

	xPlayer.removeInventoryItem(selectDrugs.name, soldCount)
	local finalPrice = math.floor(selectedDrugsPrice * levelBonus.priceBonus)
	local payment = soldCount * finalPrice
	local BoostOrVip, BoostId, BoostTime, BoostBonus = null.fct.BoostAndVip(xPlayer.identifier, xPlayer.source)
	if BoostOrVip and BoostOrVip == 2 then
		payment = payment + (payment * BoostBonus.sell)
	elseif BoostOrVip and BoostOrVip == 1 then
		payment = payment * BoostBonus.sell
	end
	payment = math.floor(payment)

	xPlayer.addAccountMoney("dirtycash", payment)
	if pedNetId then
		npcSellCooldown[src] = os.time() + 5
	end
	TriggerClientEvent("inventory:sendMessage", xPlayer.source, ('💵 Vous avez récuperer ~y~+%s~s~$'):format(payment), 10000)
	if pedNetId then
		TriggerClientEvent("null:territories:npcSellResult", src, pedNetId, "success")
	end

	if gangname ~= "unemployed" then
		ChangeGroupeStat(gangname, "confiance", 1.0, "add")
		ChangeGroupeStat(gangname, "criminalité", 0.25, "add")
		if inTerritory then
			exports["null-core"]:ProgressGangMission(gangname, "daily_territory_points", soldCount)
		end
		exports["null-core"]:ProgressGangMission(gangname, "daily_sell_drugs", soldCount)
		exports["null-core"]:ProgressGangMission(gangname, "weekly_sell_drugs_mass", soldCount)
		exports["null-core"]:ProgressGangMission(gangname, "daily_dirty_money", payment)
		exports["null-core"]:ProgressGangMission(gangname, "weekly_dirty_money_mass", payment)
		exports["null-core"]:AddGangXP(gangname, 10 * soldCount)
	end

	if shouldContinueTerritoryLoop and inTerritory then
		local confianceMultSell = getConfianceMultiplier(gangname) * levelBonus.waitMultiplier
		TriggerClientEvent("null:territories:addPoint", src, generateRandomPositionInZone(vv.points, src), vv.PNJ.pos.z - 1, vv.id, confianceMultSell)
	else
		playerProcessing[src] = nil
	end
end

RegisterNetEvent('territories:sellDrugs', function(id)
	sellDrugsToNpc(source, id, nil, nil, true)
end)

RegisterNetEvent('territories:sellDrugsToPed', function(pedNetId, coords)
	sellDrugsToNpc(source, nil, pedNetId, coords, false)
end)

local RobbedPed = {}
RegisterNetEvent("null:territories:startSelledPedReply", function(ped)
	local xPlayer = ESX.GetPlayerFromId(source)
	if RobbedPed[xPlayer.source] ~= nil then
		return
	end
	RobbedPed[xPlayer.source] = ped
end)

RegisterNetEvent("null:territories:takeMoney", function(ped, type)
	local xPlayer = ESX.GetPlayerFromId(source)
	if RobbedPed[xPlayer.source] ~= ped then
		return
	end
	RobbedPed[xPlayer.source] = nil
	playerProcessing[source] = nil
	local random = math.random(Config.Territories.moneyToDrop.min, Config.Territories.moneyToDrop.max)
	xPlayer.addAccountMoney("dirtycash", random)
	TriggerClientEvent("inventory:sendMessage", xPlayer.source, ('💵 Vous avez récuperer ~y~+%s~s~$'):format(random), 10000)

	if xPlayer.getJob2().name ~= "unemployed" then
		local gangname = xPlayer.getJob2().name
		if type == "rob" then
			ChangeGroupeStat(gangname, "confiance", 1.0, "remove")
			ChangeGroupeStat(gangname, "criminalité", 0.25, "add")
		elseif type == "kill" then		
			ChangeGroupeStat(gangname, "confiance", 1.0, "remove")
			ChangeGroupeStat(gangname, "morale", 1.0, "remove")
			ChangeGroupeStat(gangname, "criminalité", 0.75, "add")
		end
		exports["null-core"]:ProgressGangMission(gangname, "daily_dirty_money", random)
		exports["null-core"]:ProgressGangMission(gangname, "weekly_dirty_money_mass", random)
	end
end)

