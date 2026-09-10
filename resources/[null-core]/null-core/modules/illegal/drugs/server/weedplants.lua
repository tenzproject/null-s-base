local AuthorizedPlant = {}
local PlantLoaded = false
ESX.RegisterUsableItem('plantpot', function(source)
	local xPlayer = ESX.GetPlayerFromId(source)
	local rdn = math.random(1,99)
	AuthorizedPlant[rdn] = true
	TriggerClientEvent('null:weed:client:UseWeedSeed', source, rdn)
end)

RegisterNetEvent('null:weed:server:load', function()
	local src = source
	while PlantLoaded == false do Wait(100) end
	TriggerClientEvent("null:weed:client:recevie", src, SaveData.Illegal.WeedPlants)
end)

local function deletePlant(id)
	--DeleteEntity(SaveData.Illegal.WeedPlants[id].entity)
	SaveData.Illegal.WeedPlants[id] = nil
	MySQL.Async.execute("DELETE FROM `weedplants` WHERE id = @id", {
		["@id"] = id
	})
	TriggerClientEvent("null:weed:client:recevie", -1, SaveData.Illegal.WeedPlants)
end 
local calcGrowth = function(k)
    if not SaveData.Illegal.WeedPlants[k] then return false end
    local current_time = os.time()
    local growTime = (devmode == false and Config.WeedPlant.GrowTime or 10) * 60
	if SaveData.Illegal.WeedPlants[k].inLabo ~= 0 and SaveData.json["illegals"]["laboratorys"][SaveData.Illegal.WeedPlants[k].inLabo] then
		if SaveData.json["illegals"]["laboratorys"][SaveData.Illegal.WeedPlants[k].inLabo].upgrades["uv-light"] then
			growTime = (devmode == false and Config.WeedPlant.GrowTimeWithUV or 5) * 60
		end
	end
    local progress = os.difftime(current_time, SaveData.Illegal.WeedPlants[k].time)
    local growth = ESX.Math.Round(progress * 100 / growTime, 2)
    local retval = math.min(growth, 100.00)
    return retval
end
local calcStage = function(growth)
    local stage = math.floor(growth / 20)
    if stage <= 0 then stage = 1 end
    return stage
end
local calcFertilizer = function(k)
    if not SaveData.Illegal.WeedPlants[k] then return false end
    local current_time = os.time()

    if #SaveData.Illegal.WeedPlants[k].fertilizer == 0 then
        return 0
    else
        local last_fertilizer = SaveData.Illegal.WeedPlants[k].fertilizer[#SaveData.Illegal.WeedPlants[k].fertilizer]
        local time_elapsed = os.difftime(current_time, last_fertilizer)
        local fertilizer = ESX.Math.Round(100 - (time_elapsed / 60 * Config.WeedPlant.FertilizerDecay), 2)
        local retval = math.max(fertilizer, 0.00)
        return retval
    end
end
local calcWater = function(k)
    if not SaveData.Illegal.WeedPlants[k] then return false end
    local current_time = os.time()

    if #SaveData.Illegal.WeedPlants[k].water == 0 then
        return 0
    else
        local last_water = SaveData.Illegal.WeedPlants[k].water[#SaveData.Illegal.WeedPlants[k].water]
        local time_elapsed = os.difftime(current_time, last_water)
        local water = ESX.Math.Round(100 - (time_elapsed / 60 * Config.WeedPlant.WaterDecay), 2)
        local retval = math.max(water, 0.00)
        return retval
    end
end
local calcHealth = function(k)
    if not SaveData.Illegal.WeedPlants[k] then return false end
    local health = 100
    local current_time = os.time()
    local planted_time = SaveData.Illegal.WeedPlants[k].time
    local elapsed_time = os.difftime(current_time, planted_time)
    local intervals = math.floor(elapsed_time / 60 / Config.WeedPlant.LoopUpdate)
    if intervals == 0 then return 100 end

    for i=1, intervals, 1 do
        local interval_time = planted_time + (i * Config.WeedPlant.LoopUpdate * 60)

        local fertilizer_amount
        if #SaveData.Illegal.WeedPlants[k].fertilizer == 0 then
            fertilizer_amount = 0
            health -= math.random(Config.WeedPlant.HealthBaseDecay[1], Config.WeedPlant.HealthBaseDecay[2])
        else
            local last_fertilizer = math.huge
            for i=1, #SaveData.Illegal.WeedPlants[k].fertilizer, 1 do
                last_fertilizer = last_fertilizer < SaveData.Illegal.WeedPlants[k].fertilizer[i] and last_fertilizer or SaveData.Illegal.WeedPlants[k].fertilizer[i]
            end
            local time_since_fertilizer = os.difftime(interval_time, last_fertilizer)

            fertilizer_amount = math.max(ESX.Math.Round(100 - (time_since_fertilizer / 60 * Config.WeedPlant.FertilizerDecay), 2), 0.00)
            if fertilizer_amount < Config.WeedPlant.FertilizerThreshold then
                health -= math.random(Config.WeedPlant.HealthBaseDecay[1], Config.WeedPlant.HealthBaseDecay[2])
            end
        end

        local water_amount
        if #SaveData.Illegal.WeedPlants[k].water == 0 then
            water_amount = 0
            health -= math.random(Config.WeedPlant.HealthBaseDecay[1], Config.WeedPlant.HealthBaseDecay[2])
        else
            local last_water = math.huge
            for i=1, #SaveData.Illegal.WeedPlants[k].water, 1 do
                last_water = last_water < SaveData.Illegal.WeedPlants[k].water[i] and last_water or SaveData.Illegal.WeedPlants[k].water[i]
            end
            local time_since_water = os.difftime(interval_time, last_water)

            water_amount = math.max(ESX.Math.Round(100 - (time_since_water / 60 * Config.WeedPlant.WaterDecay), 2), 0.00)
            if water_amount < Config.WeedPlant.WaterThreshold then
                health -= math.random(Config.WeedPlant.HealthBaseDecay[1], Config.WeedPlant.HealthBaseDecay[2])
            end
        end
    end

    return math.max(health, 0.0)
end

local function UpdatePlantData(plantId)
    if not SaveData.Illegal.WeedPlants[plantId] then return end
    SaveData.Illegal.WeedPlants[plantId].displayfertilizer = calcFertilizer(plantId)
    SaveData.Illegal.WeedPlants[plantId].displaywater = calcWater(plantId)
    SaveData.Illegal.WeedPlants[plantId].health = calcHealth(plantId)
    SaveData.Illegal.WeedPlants[plantId].growth = calcGrowth(plantId)
    local newStage = calcStage(SaveData.Illegal.WeedPlants[plantId].growth)
    if newStage ~= SaveData.Illegal.WeedPlants[plantId].stage then
        SaveData.Illegal.WeedPlants[plantId].stage = newStage
        
        local plantData = SaveData.Illegal.WeedPlants[plantId]
        local inLabo = plantData.inLabo
        
        if inLabo and inLabo ~= 0 then
            for idunique, playerLabId in pairs(PeopleInLabo) do
                if playerLabId == inLabo then
                    local xPlayer = ESX.PlayersByIdUnique[idunique]
                    if xPlayer then
                        TriggerClientEvent("null:weed:client:recevieDataPlant", xPlayer.source, plantId, plantData)
						--null.DebugPrint("Update Plant for player :", xPlayer.source, "Plant ID :",plantId)
                    end
                end
            end
        else
            TriggerClientEvent("null:weed:client:recevieDataPlant", -1, plantId, plantData)
        end
    end
end

function NotifyPlantDataToClients(plantId)
    if not SaveData.Illegal.WeedPlants[plantId] then return end
    local plantData = SaveData.Illegal.WeedPlants[plantId]
    local inLabo = plantData.inLabo
    
    if inLabo and inLabo ~= 0 then
        for idunique, playerLabId in pairs(PeopleInLabo) do
            if playerLabId == inLabo then
                local xPlayer = ESX.PlayersByIdUnique[idunique]
                if xPlayer then
                    TriggerClientEvent("null:weed:client:recevieDataPlant", xPlayer.source, plantId, plantData)
                end
            end
        end
    else
        TriggerClientEvent("null:weed:client:recevieDataPlant", -1, plantId, plantData)
    end
end

Citizen.CreateThread(function()
    while true do
        if devmode then
            Wait(30 * 1000)
        else
            Wait(2 * 60 * 1000)
        end
        
        for plantId, plantData in pairs(SaveData.Illegal.WeedPlants) do
            if plantData then
                UpdatePlantData(plantId)
            end
        end
    end
end)

Citizen.CreateThread(function()
	Wait(6500)
	local current_time = os.time()
    local growTime = (devmode == false and Config.WeedPlant.GrowTime or 10) * 60
	
	MySQL.Async.fetchAll('SELECT * FROM weedplants', {}, function(result)
		null.DebugPrint("[^1Drugs^7] Chargement des plantes de Weed en cours")
		for k,v in pairs(result) do
			v.coords = json.decode(v.coords)
			if v.inLabo ~= 0 and SaveData.json["illegals"]["laboratorys"][v.inLabo] then
				if SaveData.json["illegals"]["laboratorys"][v.inLabo].upgrades["uv-light"] then
					growTime = (devmode == false and Config.WeedPlant.GrowTimeWithUV or 5) * 60
				else
					growTime = (devmode == false and Config.WeedPlant.GrowTime or 10) * 60
				end
			end
			if v.hasBase ~= 1 then
				v.time = os.time()
			end
			local progress = os.difftime(current_time, v.time)
			local growth = math.min(ESX.Math.Round(progress * 100 / growTime, 2), 100.00)
			local stage = calcStage(growth)
			local ModelHash = Config.WeedPlant.WeedProps[stage]
			if v.hasBase == 0 then 
				ModelHash = "bzzz_growing_freepot_a" 
			end
			if v.hasBase == 2 then 
				ModelHash = "bzzz_growing_freepot_b" 
			end
			local PlantEntityObject = CreateObjectNoOffset(ModelHash, v.coords.x, v.coords.y, v.coords.z, true, true, false)
			SetEntityOrphanMode(PlantEntityObject, 2)
			local bucket = nil
			if v.inLabo ~= 0 and v.inLabo ~= nil then
				if SaveData.json["illegals"]["laboratorys"][v.inLabo] ~= nil then
					--print("Set Bucket ("..v.id..") "..SaveData.json["illegals"]["laboratorys"][v.inLabo].instance)
					--SetEntityRoutingBucket(PlantEntityObject, SaveData.json["illegals"]["laboratorys"][v.inLabo].instance)
					bucket = SaveData.json["illegals"]["laboratorys"][v.inLabo].instance
				end
			end
			--print("Entity Bucket : "..GetEntityRoutingBucket(PlantEntityObject).."")

			local rotation = vector3(0.0, 0.0, 0.0)
			if v.rotation ~= nil then
				v.rotation = json.decode(v.rotation)
				rotation = vector3(v.rotation.x, v.rotation.y, v.rotation.z)
			end
			--SetEntityRotation(PlantEntityObject, rotation.x, rotation.y, rotation.z, 0, 0)
			SaveData.Illegal.WeedPlants[v.id] = {
				id = v.id,
				owner = json.decode(v.owner),
                coords = vector3(v.coords.x, v.coords.y, v.coords.z),
                rotation = rotation or vector3(0.0, 0.0, 0.0),
				--entity = PlantEntityObject,
				--networkId = NetworkGetNetworkIdFromEntity(PlantEntityObject),
                time = v.time,
				date = os.date('%Y-%m-%d %H:%M:%S', v.time),
                fertilizer = json.decode(v.fertilizer),
                water = json.decode(v.water),
                gender = v.gender,
				bucket = bucket,
				inLabo = v.inLabo,
				hasBase = v.hasBase,
				growth = growth,
				stage = stage,
				health = 100,
				displayfertilizer = 0,
				displaywater = 0,
			}
			SaveData.Illegal.WeedPlants[v.id].health = calcHealth(v.id)
			--FreezeEntityPosition(PlantEntityObject, true) 
			if SaveData.Illegal.WeedPlants[v.id].health <= 0 and SaveData.Illegal.WeedPlants[v.id].hasBase ~= 2 and SaveData.Illegal.WeedPlants[v.id].hasBase ~= 0 then 
				--DeleteEntity(PlantEntityObject)
				--SaveData.Illegal.WeedPlants[v.id].entity = CreateObjectNoOffset("bzzz_growing_freepot_b", SaveData.Illegal.WeedPlants[v.id].coords.x, SaveData.Illegal.WeedPlants[v.id].coords.y, SaveData.Illegal.WeedPlants[v.id].coords.z, true, true, false)
				--SetEntityOrphanMode(SaveData.Illegal.WeedPlants[v.id].entity, 2)
				if SaveData.Illegal.WeedPlants[v.id].inLabo ~= 0 then
					local id = SaveData.Illegal.WeedPlants[v.id].inLabo
					if SaveData.json["illegals"]["laboratorys"][id] ~= nil then
						--SetEntityRoutingBucket(SaveData.Illegal.WeedPlants[v.id].entity, SaveData.json["illegals"]["laboratorys"][id].instance)
					end
				end 
				SaveData.Illegal.WeedPlants[v.id].time = os.time()
				SaveData.Illegal.WeedPlants[v.id].date = os.date('%Y-%m-%d %H:%M:%S', os.time())
				SaveData.Illegal.WeedPlants[v.id].water = {}
				SaveData.Illegal.WeedPlants[v.id].fertilizer = {}
				SaveData.Illegal.WeedPlants[v.id].displayfertilizer = 0
				SaveData.Illegal.WeedPlants[v.id].displaywater = 0
				SaveData.Illegal.WeedPlants[v.id].health = 100
				SaveData.Illegal.WeedPlants[v.id].growth = 0
				SaveData.Illegal.WeedPlants[v.id].stage = 0
				SaveData.Illegal.WeedPlants[v.id].hasBase = 2
				SaveData.Illegal.WeedPlants[v.id].gender = "female"
				MySQL.Async.execute('UPDATE weedplants SET water = @water, fertilizer = @fertilizer, hasBase = @hasBase, gender = @gender, time = @time WHERE id = @id', {
					['@id'] = v.id,
					['@water'] = json.encode({}),
					['@fertilizer'] = json.encode({}),
					['@hasBase'] = 2,
					['@gender'] = "female",
					['@time'] = SaveData.Illegal.WeedPlants[v.id].time,
				})
			end
			Wait(100)
		end
		PlantLoaded = true
		null.DebugPrint("[^1Drugs^7] Plantes de Weed charger")
	end)
end)

RegisterNetEvent('null:weed:upgrade:PlaceDirt', function(id)
	if not SaveData.Illegal.WeedPlants[id] then return end
	local xPlayer = ESX.GetPlayerFromId(source)
	local item = xPlayer.getInventoryItem("earthbag")
	if item == nil or item.count < 1 then return end
	if SaveData.Illegal.WeedPlants[id].hasBase ~= 0 then return end 
	xPlayer.removeInventoryItem("earthbag", 1)
	SaveData.Illegal.WeedPlants[id].hasBase = 2
	MySQL.update('UPDATE weedplants SET hasBase = (:hasBase) WHERE id = (:id)', {
		['hasBase'] = 2,
		['id'] = id,
	})
	--DeleteEntity(SaveData.Illegal.WeedPlants[id].entity)
	--SaveData.Illegal.WeedPlants[id].entity = CreateObjectNoOffset("bzzz_growing_freepot_b", SaveData.Illegal.WeedPlants[id].coords.x, SaveData.Illegal.WeedPlants[id].coords.y, SaveData.Illegal.WeedPlants[id].coords.z, true, true, false)
	--SetEntityOrphanMode(SaveData.Illegal.WeedPlants[id].entity, 2)
	if SaveData.Illegal.WeedPlants[id].inLabo ~= 0 and SaveData.Illegal.WeedPlants[id].inLabo ~= nil then
		if SaveData.json["illegals"]["laboratorys"][SaveData.Illegal.WeedPlants[id].inLabo] ~= nil then
			--SetEntityRoutingBucket(SaveData.Illegal.WeedPlants[id].entity, SaveData.json["illegals"]["laboratorys"][SaveData.Illegal.WeedPlants[id].inLabo].instance)
		end
	end
	NotifyPlantDataToClients(id)
end)

RegisterNetEvent('null:weed:upgrade:PlantSeed', function(id)
	if not SaveData.Illegal.WeedPlants[id] then return end
	local xPlayer = ESX.GetPlayerFromId(source)
	local item2 = xPlayer.getInventoryItem("weed-seed-female")
	if item2 == nil or item2.count < 1 then return end
	if SaveData.Illegal.WeedPlants[id].hasBase ~= 2 then return end 
	xPlayer.removeInventoryItem("weed-seed-female", 1)
	SaveData.Illegal.WeedPlants[id].hasBase = 1
	SaveData.Illegal.WeedPlants[id].time = os.time()
	MySQL.update('UPDATE weedplants SET hasBase = (:hasBase) WHERE id = (:id)', {
		['hasBase'] = 1,
		['id'] = id,
	})
	MySQL.update('UPDATE weedplants SET time = (:time) WHERE id = (:id)', {
		['time'] = SaveData.Illegal.WeedPlants[id].time,
		['id'] = id,
	})
	SaveData.Illegal.WeedPlants[id].displayfertilizer = calcFertilizer(id)
	SaveData.Illegal.WeedPlants[id].displaywater = calcWater(id)
	SaveData.Illegal.WeedPlants[id].health = calcHealth(id)
	SaveData.Illegal.WeedPlants[id].growth = calcGrowth(id)
	SaveData.Illegal.WeedPlants[id].stage = calcStage(calcGrowth(id))
	

	--DeleteEntity(SaveData.Illegal.WeedPlants[id].entity)
	--SaveData.Illegal.WeedPlants[id].entity = CreateObjectNoOffset("bkr_prop_weed_01_small_01a", SaveData.Illegal.WeedPlants[id].coords.x, SaveData.Illegal.WeedPlants[id].coords.y, SaveData.Illegal.WeedPlants[id].coords.z, true, true, false)
	--SetEntityOrphanMode(SaveData.Illegal.WeedPlants[id].entity, 2)
	if SaveData.Illegal.WeedPlants[id].inLabo ~= 0 and SaveData.Illegal.WeedPlants[id].inLabo ~= nil then
		if SaveData.json["illegals"]["laboratorys"][SaveData.Illegal.WeedPlants[id].inLabo] ~= nil then
			--SetEntityRoutingBucket(SaveData.Illegal.WeedPlants[id].entity, SaveData.json["illegals"]["laboratorys"][SaveData.Illegal.WeedPlants[id].inLabo].instance)
		end
	end
	NotifyPlantDataToClients(id)
end)

RegisterNetEvent('null:weed:destroyPlant', function(id)
	if not SaveData.Illegal.WeedPlants[id] then return end
	local xPlayer = ESX.GetPlayerFromId(source)
	--if SaveData.Illegal.WeedPlants[id].owner.idunique ~= xPlayer.idunique then return end
	deletePlant(id)
end)

RegisterNetEvent('null:weed:removePlantPot', function(id)
	if not SaveData.Illegal.WeedPlants[id] then return end
	local xPlayer = ESX.GetPlayerFromId(source)
	--if SaveData.Illegal.WeedPlants[id].owner.idunique ~= xPlayer.idunique then return end
	deletePlant(id)
	xPlayer.addInventoryItem("plantpot", 1)
end)

RegisterNetEvent('null:weed:add', function(id, type)
	if not SaveData.Illegal.WeedPlants[id] then return end
	local xPlayer = ESX.GetPlayerFromId(source)
	if SaveData.Illegal.WeedPlants[id].health == 0 then deletePlant(id) return end
	if type == "water" then
		local item = xPlayer.getInventoryItem("water-canister")
		if item == nil or item.count < 1 then return end
		xPlayer.removeInventoryItem("water-canister", 1)
		SaveData.Illegal.WeedPlants[id].water[#SaveData.Illegal.WeedPlants[id].water + 1] = os.time()
		--sqlUpdate("weedplants", "water = (:water)", "id = (:id)", {['water'] = json.encode(SaveData.Illegal.WeedPlants[id].water),['id'] = SaveData.Illegal.WeedPlants[id].id})
        MySQL.update('UPDATE weedplants SET water = (:water) WHERE id = (:id)', {
            ['water'] = json.encode(SaveData.Illegal.WeedPlants[id].water),
            ['id'] = SaveData.Illegal.WeedPlants[id].id,
        })
	elseif type == "fertilizer" then
		local item = xPlayer.getInventoryItem("fertilizer")
		if item == nil or item.count < 1 then return end
		xPlayer.removeInventoryItem("fertilizer", 1)
		SaveData.Illegal.WeedPlants[id].fertilizer[#SaveData.Illegal.WeedPlants[id].fertilizer + 1] = os.time()
		--sqlUpdate("weedplants", "fertilizer = (:fertilizer)", "id = (:id)", {['fertilizer'] = json.encode(SaveData.Illegal.WeedPlants[id].fertilizer),['id'] = SaveData.Illegal.WeedPlants[id].id})
        MySQL.update('UPDATE weedplants SET fertilizer = (:fertilizer) WHERE id = (:id)', {
            ['fertilizer'] = json.encode(SaveData.Illegal.WeedPlants[id].fertilizer),
            ['id'] = SaveData.Illegal.WeedPlants[id].id,
        })
	elseif type == "weed-seed-male" then
		local item = xPlayer.getInventoryItem("weed-seed-male")
		if item == nil or item.count < 1 then return end
		xPlayer.removeInventoryItem("weed-seed-male", 1)
		SaveData.Illegal.WeedPlants[id].gender = "male"
        MySQL.update('UPDATE weedplants SET gender = (:gender) WHERE id = (:id)', {
            ['gender'] = SaveData.Illegal.WeedPlants[id].gender,
            ['id'] = SaveData.Illegal.WeedPlants[id].id,
        })
	elseif type == "weed-seed-female" then
		SaveData.Illegal.WeedPlants[id].gender = "female"
        MySQL.update('UPDATE weedplants SET gender = (:gender) WHERE id = (:id)', {
            ['gender'] = SaveData.Illegal.WeedPlants[id].gender,
            ['id'] = SaveData.Illegal.WeedPlants[id].id,
        })
	end
	NotifyPlantDataToClients(id)
end)

RegisterNetEvent('null:weed:harvest', function(id)
	if not SaveData.Illegal.WeedPlants[id] then return end
	if SaveData.Illegal.WeedPlants[id].growth ~= 100 then return end
	if SaveData.Illegal.WeedPlants[id].health == 0 then
		--DeleteEntity(SaveData.Illegal.WeedPlants[id].entity)
		SaveData.Illegal.WeedPlants[id] = nil
		MySQL.Async.execute("DELETE FROM `weedplants` WHERE id = @id", {
			["@id"] = id
		})
		return
	end
	local xPlayer = ESX.GetPlayerFromId(source)
	
	--DeleteEntity(SaveData.Illegal.WeedPlants[id].entity)
	--SaveData.Illegal.WeedPlants[id].entity = CreateObjectNoOffset("bzzz_growing_freepot_b", SaveData.Illegal.WeedPlants[id].coords.x, SaveData.Illegal.WeedPlants[id].coords.y, SaveData.Illegal.WeedPlants[id].coords.z, true, true, false)
	--SetEntityOrphanMode(SaveData.Illegal.WeedPlants[id].entity, 2)
	if SaveData.Illegal.WeedPlants[id].inLabo ~= 0 then
		if SaveData.json["illegals"]["laboratorys"][SaveData.Illegal.WeedPlants[id].inLabo] ~= nil then
			--SetEntityRoutingBucket(SaveData.Illegal.WeedPlants[id].entity, SaveData.json["illegals"]["laboratorys"][SaveData.Illegal.WeedPlants[id].inLabo].instance)
		end
	end
	-- Récompenses : 
	if SaveData.Illegal.WeedPlants[id].gender == "male" then
		local nbrmale, nbrfemale = math.floor(SaveData.Illegal.WeedPlants[id].health / 50), math.floor(SaveData.Illegal.WeedPlants[id].health / 20)
		xPlayer.addInventoryItem("weed-seed-female", nbrfemale)
		xPlayer.addInventoryItem("weed-seed-male", nbrmale)
	elseif SaveData.Illegal.WeedPlants[id].gender == "female" then
		local nbrweed = math.floor(SaveData.Illegal.WeedPlants[id].health / 20)
		xPlayer.addInventoryItem("weed_plant", nbrweed)
	end
	------------------------
	SaveData.Illegal.WeedPlants[id].time = os.time()
	SaveData.Illegal.WeedPlants[id].date = os.date('%Y-%m-%d %H:%M:%S', os.time())
	SaveData.Illegal.WeedPlants[id].water = {}
	SaveData.Illegal.WeedPlants[id].fertilizer = {}
	SaveData.Illegal.WeedPlants[id].displayfertilizer = calcFertilizer(id)
	SaveData.Illegal.WeedPlants[id].displaywater = calcWater(id)
	SaveData.Illegal.WeedPlants[id].health = calcHealth(id)
	SaveData.Illegal.WeedPlants[id].growth = calcGrowth(id)
	SaveData.Illegal.WeedPlants[id].stage = calcStage(calcGrowth(id))
	SaveData.Illegal.WeedPlants[id].hasBase = 2
	SaveData.Illegal.WeedPlants[id].gender = "female"

	MySQL.Async.execute('UPDATE weedplants SET water = @water, fertilizer = @fertilizer, hasBase = @hasBase, gender = @gender, time = @time WHERE id = @id', {
		['@id'] = id,
		['@water'] = json.encode({}),
		['@fertilizer'] = json.encode({}),
		['@hasBase'] = 2,
		['@gender'] = "female",
		['@time'] = SaveData.Illegal.WeedPlants[id].time,
	})
	NotifyPlantDataToClients(id)
end)

RegisterNetEvent('null:weed:requestPlantData', function(id)
	if not SaveData.Illegal.WeedPlants[id] then return end
	SaveData.Illegal.WeedPlants[id].displayfertilizer = calcFertilizer(id)
	SaveData.Illegal.WeedPlants[id].displaywater = calcWater(id)
	SaveData.Illegal.WeedPlants[id].health = calcHealth(id)
	SaveData.Illegal.WeedPlants[id].growth = calcGrowth(id)
	SaveData.Illegal.WeedPlants[id].stage = calcStage(SaveData.Illegal.WeedPlants[id].growth)
	NotifyPlantDataToClients(id)
end)

RegisterNetEvent('null:weed:server:CreateNewPlant', function(coords, rdn, inLabo, rotation)
	if AuthorizedPlant[rdn] ~= true then return end
	AuthorizedPlant[rdn] = nil
    local src = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - coords) > 7.0 + 10 then return end
	local quantity = xPlayer.getInventoryItem("plantpot")
    if quantity ~= nil and quantity.count > 0 then
		xPlayer.removeInventoryItem("plantpot", 1)
        local time = os.time()
		local inLaboId = 0
		if PeopleInLabo[xPlayer.getIdunique()] then
			inLaboId = PeopleInLabo[xPlayer.getIdunique()]
		end
        MySQL.insert('INSERT into weedplants (owner, coords, time, fertilizer, water, gender, inLabo, rotation) VALUES (:owner,:coords, :time, :fertilizer, :water, :gender, :inLabo, :rotation)', {
            ['owner'] = json.encode({
				idunique = xPlayer.idunique,
				firstname = xPlayer.firstname,
				lastname = xPlayer.lastname,
				name = xPlayer.getName()
			}),
            ['coords'] = json.encode(coords),
            ['inLabo'] = inLaboId,
            ['time'] = time,
            ['fertilizer'] = json.encode({}),
            ['water'] = json.encode({}),
            ['gender'] = 'female',
            ['rotation'] = rotation and json.encode(rotation) or json.encode(vector3(0.0, 0.0, 0.0))
        }, function(data)
			--local entity = CreateObjectNoOffset("bzzz_growing_freepot_a", coords.x, coords.y, coords.z, true, true, false)
			--SetEntityOrphanMode(entity, 2)
			local bucket = nil
			if inLaboId ~= 0 and inLaboId ~= nil then
				if SaveData.json["illegals"]["laboratorys"][inLaboId] ~= nil then
					--SetEntityRoutingBucket(entity, SaveData.json["illegals"]["laboratorys"][inLaboId].instance)
					bucket = SaveData.json["illegals"]["laboratorys"][inLaboId].instance
				end
			end

            if rotation then
                --SetEntityRotation(entity, rotation.x, rotation.y, rotation.z, 2, true)
            end
            SaveData.Illegal.WeedPlants[data] = {
                id = data,
				owner = {
					idunique = xPlayer.idunique,
					firstname = xPlayer.firstname,
					lastname = xPlayer.lastname,
					name = xPlayer.getName()
				},
				--entity = entity,
				--networkId = NetworkGetNetworkIdFromEntity(entity),
                coords = coords,
                rotation = rotation or vector3(0.0, 0.0, 0.0),
                time = time,
				bucket = bucket,
				inLabo = inLaboId,
				date = os.date('%Y-%m-%d %H:%M:%S', time),
                fertilizer = {},
                water = {},
                gender = 'female',
				health = 100,
				hasBase = 0,
				growth = 0,
				stage = 0,
				displayfertilizer = 0,
				displaywater = 0
            }
			TriggerClientEvent("null:weed:client:recevieNew", -1, data, SaveData.Illegal.WeedPlants[data])
        end)
    end
end)