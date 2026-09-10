local TemplateLabo = {
    type = "weed",
    upgrades = {
        ["uv-light"] = false,
        ["sprinklers"] = false,
        ["coffre"] = false,
        ["ventilateurs"] = false,
        ["better-light"] = false,
        ["security"] = false,
        ["treatment-equipment"] = false,
        ["dealer"] = false,
        ["market-study"] = false,
    },
    createdAt = os.time(),
    temperature = 21.5,
    hasBuy = false,
    ownerType = nil,
    owner = "aucun",
    isOwner = false,
    patern = {},
    autorisedGroups = {},
    employees = {},
    members = {},
    History = {
        ["sells"] = {},
        ["enter"] = {},
        ["exit"] = {},
        ["treatment"] = {},
    },
    marketstudy = {
        estimate = 0,
    },
    treatementmeth = {
        fours = {},
        cuves = {},
    },
    treatmentequipment = {
        indrying = {},
        drying = {}
    },
    dealer = {
        lastRequest = nil,
    },
    billing = {
        lastBillDate = nil,
        nextBillDate = nil,
        currentBill = nil,
        billDeadline = nil,
        unpaidBills = 0
    }
}

--[[LastMarket = {
    DrugsRequestPrice = 0,
    DrugsRequestCount = 0,
}]]

LastMarket = {}
LastMarketLoaded = false

Citizen.CreateThread(function()
    local actualTime = os.time()
    if SaveData.json["illegals"]["market"] == nil then SaveData.json["illegals"]["market"] = {} end
    
    
    if #SaveData.json["illegals"]["market"] > 0 then
        local last = SaveData.json["illegals"]["market"][#SaveData.json["illegals"]["market"]]
        local difference = actualTime - last.time 
        local hours = difference / 3600
        if hours >= 24 then
            local id = #SaveData.json["illegals"]["market"]+1
            SaveData.json["illegals"]["market"][id] = {
                time = os.time(),
                drugs = {}
            }
            
            for k,v in pairs(Config.DrugsMarket.market) do 
                local price = math.random(v.price[1], v.price[2])
                local request = math.random(v.maxsell[1], v.maxsell[2])
                SaveData.json["illegals"]["market"][id].drugs[k] = {
                    price = price,
                    request = request,
                    totalSell = 0,
                }
                LastMarket[k] = {}
                LastMarket[k].DrugsRequestPrice = price
                LastMarket[k].DrugsRequestCount = request
            end
        else
            for k,v in pairs(last.drugs) do 
                LastMarket[k] = {}
                LastMarket[k].DrugsRequestPrice = v.price
                LastMarket[k].DrugsRequestCount = v.request
            end
        end
    else
        local id = 1
        SaveData.json["illegals"]["market"][id] = {
            time = os.time(),
            drugs = {}
        }
        
        for k,v in pairs(Config.DrugsMarket.market) do 
            local price = math.random(v.price[1], v.price[2])
            local request = math.random(v.maxsell[1], v.maxsell[2])
            SaveData.json["illegals"]["market"][id].drugs[k] = {
                price = price,
                request = request,
                totalSell = 0,
            }
            LastMarket[k] = {}
            LastMarket[k].DrugsRequestPrice = price
            LastMarket[k].DrugsRequestCount = request
        end
    end
    LastMarketLoaded = true
    Wait(13000)
    null.DebugPrint("[^1Drugs^7] Génération du marché effecuter :")
    for k,v in pairs(Config.DrugsMarket.market) do 
        if LastMarket[k] and not v.hide then
            null.DebugPrint("[^1Drugs^7:^2"..k.."^7] Prix: ^3"..LastMarket[k].DrugsRequestPrice.."$^7")
            null.DebugPrint("[^1Drugs^7:^2"..k.."^7] Nombre de Demande: "..LastMarket[k].DrugsRequestCount.."")
        end
    end
end)

exports("getMarket", function()
    return LastMarket
end)

PeopleInLabo = {}
RegisterNetEvent("null:labo:get", function()
    local src = source
    TriggerClientEvent("null:labo:recevie", src, SaveData.json["illegals"]["laboratorys"])
end)
 
Citizen.CreateThread(function()
	Wait(3500)
    for k,v in pairs(SaveData.json["illegals"]["laboratorys"]) do
        if v.price == nil or v.price == 0 then
            SaveData.json["illegals"]["laboratorys"][k].price = math.random(Config.laboratoire.type[v.type].price[1], Config.laboratoire.type[v.type].price[2])
        end
        if v.owner == nil then v.owner = "aucun" end
        if v.hasBuy == nil then v.hasBuy = false end
        if v.cameraProps ~= nil then v.cameraProps = nil end
        if v.instance == nil then 
            v.instance = math.random(50, 200)
        end
        if v.propsDry then
            v.propsDry = {}
        end
        if v.upgrades == nil then 
            v.upgrades = TemplateLabo.upgrades
        end
        if v.patern == nil then
            v.patern = {}
        end
        if v.dealer.lastRequest ~= nil then
            RewardDealer(v.id)
        end
        if v.upgrades["treatment-equipment"] and v.treatmentequipment.indrying then
            SetupLaboWeedDry(v.id)
        end
        if v.upgrades["security"] then
            SetupSecurityCamera(v.id)
        end
        if v.treatementmeth.fours == nil or #v.treatementmeth.fours == 0 then
            v.treatementmeth.fours = Config.laboratoire.type["meth"].fours
        end
        if v.treatementmeth.cuves == nil then
            v.treatementmeth.cuves = {}
        end
        if Config.laboratoire.type["meth"].cuves then
            for cuveId, _ in pairs(Config.laboratoire.type["meth"].cuves) do
                if v.treatementmeth.cuves[cuveId] == nil then
                    v.treatementmeth.cuves[cuveId] = { state = "idle", ingredients = {}, traysRemaining = 0 }
                end
            end
        end
        SetupDropBox(v.id)
        SetupLaboEmployees(v.id, false)
        for k2,v2 in pairs(TemplateLabo) do
            if SaveData.json["illegals"]["laboratorys"][k][k2] == nil then 
                SaveData.json["illegals"]["laboratorys"][k][k2] = v2
            end
        end
    end
end)

Citizen.CreateThread(function()
    Wait(5000)
	while true do
        for k,v in pairs(SaveData.json["illegals"]["laboratorys"]) do
            local changed = false
            local changedEmployees = false
            local changedMethFours = false
            local changedMethCuves = false
            if v.treatmentequipment.indrying ~= nil then
                for key, value in pairs(v.treatmentequipment.indrying) do
                    if (os.time() - value.timestart) > (devmode and 5 or (Config.laboratoire.type[v.type].treatmentequipment.dryTimeToWait)*60) then
                        v.treatmentequipment.indrying[key].finish = true
                        changed = true
                    end
                end
            end
            if v.treatementmeth.fours ~= nil then
                for fourid, fourdata in pairs(v.treatementmeth.fours) do
                    if fourdata and fourdata.inFour then
                        for key, value in pairs(fourdata.inFour) do 
                            if (os.time() - value.timestart) > (devmode and 5 or (Config.laboratoire.type["meth"].timetoWaitFour)*60) then
                                v.treatementmeth.fours[fourid].inFour[key].finish = true
                                changedMethFours = true
                            end
                        end
                    end
                end
            end
            if v.treatementmeth.cuves ~= nil then
                local cuveConf = Config.laboratoire.type["meth"].cuveConfig
                for cuveId, cuveData in pairs(v.treatementmeth.cuves) do
                    if cuveData.state == "mixing" and cuveData.mixStartTime then
                        local elapsed = os.time() - cuveData.mixStartTime
                        if elapsed >= (devmode and 10 or cuveConf.mixTime * 60) then
                            cuveData.state = "waiting_solvant"
                            cuveData.mixStartTime = nil
                            changedMethCuves = true
                        end
                    elseif cuveData.state == "mixing_solvant" and cuveData.solvantMixStartTime then
                        local elapsed = os.time() - cuveData.solvantMixStartTime
                        if elapsed >= (devmode and 10 or cuveConf.solvantMixTime * 60) then
                            cuveData.state = "ready"
                            cuveData.solvantMixStartTime = nil
                            -- Check if lab has meth-upgrade for increased production
                            if v.upgrades and v.upgrades["meth-upgrade"] then
                                cuveData.traysRemaining = cuveConf.traysProducedUpgrade
                            else
                                cuveData.traysRemaining = cuveConf.traysProduced
                            end
                            changedMethCuves = true
                        end
                    end
                end
            end
            if v.employees then
                for k2, v2 in pairs(v.employees) do
                    if (os.time() - v2.lastPay) >= (60*60*24) then
                        v2.getPayed = false
                        changedEmployees = true
                    end
                end
            end
            if changed or changedEmployees or changedMethFours or changedMethCuves then
                for k2,v2 in pairs(PeopleInLabo) do
                    if v2 == v.id then
                        local xPlayer = ESX.GetPlayerFromIdUnique(k)
                        if xPlayer then
                            if changedEmployees then
                                TriggerClientEvent("null:labo:updateEmployeesData", xPlayer.source, v.id, v.employees)
                            end
                            if changed then
                                TriggerClientEvent("null:labo:updateindrying", xPlayer.source, v.id, v.treatmentequipment.indrying)
                            end
                            if changedMethFours then
                                TriggerClientEvent("null:labo:updatefour", xPlayer.source, v.id, v.treatementmeth.fours)
                            end
                            if changedMethCuves then
                                SyncCuveToClients(v.id)
                            end
                        end
                    end
                end
            end
            if v.dealer.lastRequest ~= nil then
                RewardDealer(v.id)
            end
        end
		Wait(1*60*1000)
	end
end)

function DebugOneInstance(instance)
    SetRoutingBucketEntityLockdownMode(instance, "inactive")
    SetRoutingBucketPopulationEnabled(instance, false)
end

function SetupLaboWeedDry(id)
    --[[Citizen.CreateThread(function()
        local data = SaveData.json["illegals"]["laboratorys"][id]
        local instance = SaveData.json["illegals"]["laboratorys"][id].instance
        if data.treatmentequipment.indrying then
            local nbr = 0
            for k,v in pairs(data.treatmentequipment.indrying) do nbr += 1 end
    
            local DryingWeedList = {"bkr_prop_weed_drying_01a", "bkr_prop_weed_drying_02a"}
    
            if SaveData.json["illegals"]["laboratorys"][id].propsDry == nil then
                SaveData.json["illegals"]["laboratorys"][id].propsDry = {}
            else
                -- delete older
                for k,v in pairs(SaveData.json["illegals"]["laboratorys"][id].propsDry) do
                    --DeleteEntity(v)
                end
                --SaveData.json["illegals"]["laboratorys"][id].propsDry = {}
            end
            
            local nbrSpawn = 0
            for k,v in pairs(SaveData.json["illegals"]["laboratorys"][id].propsDry) do
                if k > nbr then
                    SaveData.json["illegals"]["laboratorys"][id].propsDry[k] = nil
                    DeleteEntity(v)
                else
                    nbrSpawn += 1
                end
            end


            if nbrSpawn < nbr then
                local newSpawnNbr = nbr - nbrSpawn
                for i = 1, newSpawnNbr do
                    local positondata = Config.laboratoire.type["weed"].treatmentequipment.DryPlantsCoords[nbrSpawn+i]
                    local entityid = #SaveData.json["illegals"]["laboratorys"][id].propsDry+1
                    local entitymodel = DryingWeedList[math.random(1,2)]
                    SaveData.json["illegals"]["laboratorys"][id].propsDry[entityid] = CreateObjectNoOffset(entitymodel, positondata.coords.x, positondata.coords.y, positondata.coords.z, true, true, false)
                    --SetEntityOrphanMode(SaveData.json["illegals"]["laboratorys"][id].propsDry[entityid], 2)
                    SetEntityRoutingBucket(SaveData.json["illegals"]["laboratorys"][id].propsDry[entityid], instance)
                end
            end
        end
    end)]]
end

function GetLabPlants(labId)
    local plants = {}
    local totalPlants = 0
    local labPlants = 0
    for plantId, plantData in pairs(SaveData.Illegal.WeedPlants) do
        totalPlants = totalPlants + 1
        if plantData.inLabo == labId then
            labPlants = labPlants + 1
            table.insert(plants, {id = plantId, data = plantData})
        end
    end
    return plants
end

function CalculatePlantStats(plantId)
    if not SaveData.Illegal.WeedPlants[plantId] then return nil end
    
    local current_time = os.time()
    local water = 0
    local fertilizer = 0
    
    if #SaveData.Illegal.WeedPlants[plantId].water > 0 then
        local last_water = SaveData.Illegal.WeedPlants[plantId].water[#SaveData.Illegal.WeedPlants[plantId].water]
        local time_elapsed = os.difftime(current_time, last_water)
        water = math.max(100 - (time_elapsed / 60 * Config.WeedPlant.WaterDecay), 0)
    end
    
    if #SaveData.Illegal.WeedPlants[plantId].fertilizer > 0 then
        local last_fertilizer = SaveData.Illegal.WeedPlants[plantId].fertilizer[#SaveData.Illegal.WeedPlants[plantId].fertilizer]
        local time_elapsed = os.difftime(current_time, last_fertilizer)
        fertilizer = math.max(100 - (time_elapsed / 60 * Config.WeedPlant.FertilizerDecay), 0)
    end
    
    local growTime = (devmode == false and Config.WeedPlant.GrowTime or 10) * 60
    if SaveData.json["illegals"]["laboratorys"][SaveData.Illegal.WeedPlants[plantId].inLabo] then
        if SaveData.json["illegals"]["laboratorys"][SaveData.Illegal.WeedPlants[plantId].inLabo].upgrades["uv-light"] then
            growTime = (devmode == false and Config.WeedPlant.GrowTimeWithUV or 5) * 60
        end
    end
    
    local progress = os.difftime(current_time, SaveData.Illegal.WeedPlants[plantId].time)
    local growth = math.min(ESX.Math.Round(progress * 100 / growTime, 2), 100)
    local stage = 0
    if growth >= 0 and growth < 20 then stage = 1
    elseif growth >= 20 and growth < 40 then stage = 2
    elseif growth >= 40 and growth < 60 then stage = 3
    elseif growth >= 60 and growth < 80 then stage = 4
    elseif growth >= 80 then stage = 5 end
    
    return {
        water = water,
        fertilizer = fertilizer,
        growth = growth,
        stage = stage,
        health = SaveData.Illegal.WeedPlants[plantId].health or 100
    }
end

function SetupSecurityCamera(id)
    local data = SaveData.json["illegals"]["laboratorys"][id]
    if not data then return end
    if data.upgrades["security"] ~= true then return end
    if data.camera == nil then return end
    if DoesEntityExist(data.cameraProps) then 
        DeleteEntity(data.cameraProps)
        data.cameraProps = nil
    end
    data.cameraProps = CreateObjectNoOffset("prop_cctv_cam_01a", data.camera.coords.x, data.camera.coords.y, data.camera.coords.z, true, true, false)
    data.networkIdCamera = NetworkGetNetworkIdFromEntity(data.cameraProps)
    FreezeEntityPosition(data.cameraProps, true)
    SetEntityRotation(data.cameraProps, data.camera.rotation.x, data.camera.rotation.y, data.camera.rotation.z)
    SetEntityRoutingBucket(data.cameraProps, 0)       
end

function SetupDropBox(id)
    local data = SaveData.json["illegals"]["laboratorys"][id]
    if not data then return end
    if data.dropbox == nil then return end
    if DoesEntityExist(data.dropboxProps) then 
        DeleteEntity(data.dropboxProps)
        data.dropboxProps = nil
    end
    data.dropboxProps = CreateObjectNoOffset("prop_elecbox_02a", data.dropbox.coords.x, data.dropbox.coords.y, data.dropbox.coords.z, true, true, false)
    FreezeEntityPosition(data.dropboxProps, true)
    data.networkIdDropbox = NetworkGetNetworkIdFromEntity(data.dropboxProps)
    SetEntityRotation(data.dropboxProps, data.dropbox.rotation.x, data.dropbox.rotation.y, data.dropbox.rotation.z)
    SetEntityRoutingBucket(data.dropboxProps, 0)
    
    CreateStorage("labo_dropbox_"..id)
end

function RewardDealer(id)
    local data = SaveData.json["illegals"]["laboratorys"][id]
    if not data then return end
    if (os.time() - data.dealer.lastRequest.time) >= (Config.laboratoire.timeDealer*60) and not data.dealer.lastRequest.finish and data.dealer.lastRequest.item ~= nil then
        local last = SaveData.json["illegals"]["market"][#SaveData.json["illegals"]["market"]].drugs[data.dealer.lastRequest.item]
        local marketData = LastMarket[data.dealer.lastRequest.item]

        local maxServ = marketData.DrugsRequestCount
        local max = data.dealer.lastRequest.count
        if last.totalSell == nil then last.totalSell = 0 end
        if (maxServ - last.totalSell) < data.dealer.lastRequest.count then
            max = (maxServ - last.totalSell)
        end
        local ProposedPrice = data.dealer.lastRequest.price
        local selled = 0
        local unselled = 0
        local pourcentage = 100
        if ProposedPrice == marketData.DrugsRequestPrice then
            pourcentage = math.random(90, 100)
            selled = (max / 100) * pourcentage
            unselled = max - selled
        elseif ProposedPrice < marketData.DrugsRequestPrice then
            pourcentage = 100
            selled = max
            unselled = 0
        else
            local surevaluation = ProposedPrice - marketData.DrugsRequestPrice
            local max_surval = marketData.DrugsRequestPrice * 0.3 -- Exemple : 30% au-dessus du prix du marché est considéré comme extrême
            pourcentage = math.max(0, math.floor(90 * (1 - (surevaluation / max_surval))))
            selled = (max / 100) * pourcentage
            unselled = max - selled
        end
    
        print("[^1Drugs^7] Résultat Vente Dealer Laboratoire : ")
        print("[^1Drugs^7] Max Vente: "..max.."/"..data.dealer.lastRequest.count.." (^4"..maxServ.."^7)")
        print("[^1Drugs^7] Pourcentage Vendu: ^2"..pourcentage.."%^7")
        print("[^1Drugs^7] Nombre vendu: "..selled.."/"..max)
        print("[^1Drugs^7] Nombre invendu: ^1"..unselled.."/"..max.."^7")
        print("[^1Drugs^7] Total gagné: ^3"..selled*ProposedPrice.."$^7")

        SaveData.json["illegals"]["laboratorys"][id].dealer.lastRequest.finish = true
        SaveData.json["illegals"]["laboratorys"][id].dealer.lastRequest.reward = {
            unselled = unselled,
            selled = selled,
            total = selled*ProposedPrice,
            max = data.dealer.lastRequest.count,
            pourcentage = pourcentage,
        }
        marketData.DrugsRequestCount = marketData.DrugsRequestCount - selled
        last.totalSell = last.totalSell + selled

        null.logs.send("Logs", "Le labo: "..id.." a reçu les résultat vente dealer : Total gagné: "..selled*ProposedPrice.."$, Max Vente: "..max.."/"..data.dealer.lastRequest.count.." ("..maxServ..")", "laboratoires", {})

        TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id])
    else
        return
    end
end
 
RegisterNetEvent("null:labo:setincamera", function(bool, id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    local data = SaveData.json["illegals"]["laboratorys"][id]
    if data.upgrades["security"] ~= true then return end
    if data.camera == nil then return end
    if bool then
        null.fct.instance.Set(src, 0)
    else
        null.fct.instance.Set(src, SaveData.json["illegals"]["laboratorys"][id].instance, "In Camera")
    end
end)

RegisterNetEvent("null:labo:enter", function(id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    local coords1 = SaveData.json["illegals"]["laboratorys"][id].coords
    local coords = vec3(coords1.x, coords1.y, coords1.z)
    local distance = #(xPlayer.getCoords()-coords)
    if distance > 10.0 then return end
    if PeopleInLabo[xPlayer.getIdunique()] ~= nil then return end
    PeopleInLabo[xPlayer.getIdunique()] = id
    if SaveData.json["illegals"]["laboratorys"][id].upgrades["security"] then
        table.insert(SaveData.json["illegals"]["laboratorys"][id].History["enter"], {
            idunique = xPlayer.getIdunique(),
            name = xPlayer.getName(),
            firstname = xPlayer.firstname,
            lastname = xPlayer.lastname,
            time = os.date("%Y-%m-%d %H:%M:%S"),
            ostime = os.time()  
        })
        TriggerClientEvent("null:labo:history", -1, id, SaveData.json["illegals"]["laboratorys"][id].History)
    end

    null.logs.send("Logs","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique().." T"..xPlayer.source..") est entrer dans le labo : "..id, "laboratoires", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})

    null.fct.instance.Set(src, SaveData.json["illegals"]["laboratorys"][id].instance, "Laboratoire")
    TriggerClientEvent("null:labo:enter", src, id, true)
end)

RegisterNetEvent("null:labo:forceenter", function(id, time)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    local coords1 = SaveData.json["illegals"]["laboratorys"][id].coords
    local coords = vec3(coords1.x, coords1.y, coords1.z)
    local distance = #(xPlayer.getCoords()-coords)
    if distance > 10.0 then return end
    if PeopleInLabo[xPlayer.getIdunique()] ~= nil then return end
    if xPlayer.getJob() == nil then return end
    if SaveData.json["entreprises"]["Police"][xPlayer.getJob().name] == nil then return end
    
    if SaveData.json["illegals"]["laboratorys"][id].upgrades["security"] then
        TriggerClientEvent("null:labo:someoneenter", -1, id)
    end

    null.logs.send("Logs","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique().." T"..xPlayer.source..") crocheté la porte du labo : "..id, "laboratoires", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})

    xPlayer.showNotification("⏳ Crochetage de la porte en cours..")
    Wait(time)
    xPlayer.showNotification("⌚ Fin dans 5 secondes")
    Wait(2000)
    xPlayer.showNotification("⌚ Fin dans 3 secondes")
    Wait(1000)
    xPlayer.showNotification("⌚ Fin dans 2 secondes")
    Wait(1000)
    xPlayer.showNotification("⌚ Fin dans 1 secondes")
    Wait(1000)
    
    local forcetime = os.time()
    SaveData.json["illegals"]["laboratorys"][id].dooropen = true
    SaveData.json["illegals"]["laboratorys"][id].lastdooropened = forcetime
    TriggerClientEvent("null:labo:forcedoor", -1, id, true)
    Citizen.CreateThread(function()
        Wait(60000)
        if SaveData.json["illegals"]["laboratorys"][id].lastdooropened == forcetime then
            SaveData.json["illegals"]["laboratorys"][id].dooropen = false
            TriggerClientEvent("null:labo:forcedoor", -1, id, false)
        end
    end)

    --[[PeopleInLabo[xPlayer.getIdunique()] = id
    if SaveData.json["illegals"]["laboratorys"][id].upgrades["security"] then
        table.insert(SaveData.json["illegals"]["laboratorys"][id].History["enter"], {
            idunique = xPlayer.getIdunique(),
            name = xPlayer.getName(),
            firstname = xPlayer.firstname,
            lastname = xPlayer.lastname,
            time = os.date("%Y-%m-%d %H:%M:%S"),
            ostime = os.time()  
        })
        TriggerClientEvent("null:labo:history", -1, id, SaveData.json["illegals"]["laboratorys"][id].History)
    end
    null.fct.instance.Set(src, SaveData.json["illegals"]["laboratorys"][id].instance, "Laboratoire")
    TriggerClientEvent("null:labo:enter", src, id, true)]]
end)


AddEventHandler('esx:playerLoaded', function(source)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end
    
    null.fct.instance.Set(src, SaveData.json["illegals"]["laboratorys"][PeopleInLabo[xPlayer.getIdunique()]].instance, "Laboratoire")
    TriggerClientEvent("null:labo:enter", src, id, false)
end)


RegisterNetEvent("null:labo:leave", function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    local distance = #(xPlayer.getCoords()-Config.laboratoire.coords)
    if distance > 10.0 then return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then
        null.fct.instance.Set(src, 0)
        xPlayer.setCoords(vec3(237.050034, -815.026306, 30.243328))
        PeopleInLabo[xPlayer.getIdunique()] = nil
    else
        null.fct.instance.Set(src, 0)
        TriggerClientEvent("null:labo:exit", src, PeopleInLabo[xPlayer.getIdunique()])
        local id = PeopleInLabo[xPlayer.getIdunique()]
        if SaveData.json["illegals"]["laboratorys"][id].upgrades["security"] then
            table.insert(SaveData.json["illegals"]["laboratorys"][id].History["exit"], {
                idunique = xPlayer.getIdunique(),
                name = xPlayer.getName(),
                firstname = xPlayer.firstname,
                lastname = xPlayer.lastname,
                time = os.date("%Y-%m-%d %H:%M:%S"),
                ostime = os.time()  
            })
            TriggerClientEvent("null:labo:history", -1, id, SaveData.json["illegals"]["laboratorys"][id].History)
        end
        null.logs.send("Logs","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique().." T"..xPlayer.source..") sort du labo : "..id, "laboratoires", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})

        PeopleInLabo[xPlayer.getIdunique()] = nil
    end
end)

RegisterNetEvent("null:labo:forceLeaveByTp", function(id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if id == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end
    null.fct.instance.Set(src, 0)
    if SaveData.json["illegals"]["laboratorys"][id].upgrades["security"] then
        table.insert(SaveData.json["illegals"]["laboratorys"][id].History["exit"], {
            idunique = xPlayer.getIdunique(),
            name = xPlayer.getName(),
            firstname = xPlayer.firstname,
            lastname = xPlayer.lastname,
            time = os.date("%Y-%m-%d %H:%M:%S"),
            ostime = os.time()  
        })
        TriggerClientEvent("null:labo:history", -1, id, SaveData.json["illegals"]["laboratorys"][id].History)
    end
    TriggerClientEvent("null:labo:exitTp", src, PeopleInLabo[xPlayer.getIdunique()])
    null.logs.send("Logs","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique().." T"..xPlayer.source..") sort du labo : "..id, "laboratoires", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})

    PeopleInLabo[xPlayer.getIdunique()] = nil
end)

RegisterCommand("restartlabotutorial", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer == nil or xPlayer.getGroup() ~= "fondateur" then return end
    if args[1] == nil then xPlayer.ChatMessage("Merci de spécifier une ID") return end
    if SaveData.json["illegals"]["laboratorys"][tonumber(args[1])] == nil then xPlayer.ChatMessage("Aucun labo avec cette ID") return end 

    TriggerClientEvent("null:labo:start-tutorial", source, tonumber(args[1]), "player", SaveData.json["illegals"]["laboratorys"][tonumber(args[1])].coords)
end)

RegisterCommand("restartlaboweedtutorial", function(source, args)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer == nil or xPlayer.getGroup() ~= "fondateur" then return end
    if args[1] == nil then xPlayer.ChatMessage("Merci de spécifier une ID") return end
    if SaveData.json["illegals"]["laboratorys"][tonumber(args[1])] == nil then xPlayer.ChatMessage("Aucun labo avec cette ID") return end 

    TriggerClientEvent("null:labo:start-weed-tutorial", source, tonumber(args[1]))
end)

ESX.RegisterServerCallback("null:labo:buy", function(source, cb, itemId, option, metadata)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not itemId or not SaveData.json["illegals"]["laboratorys"][itemId] then
        cb({ success = false, message = "Laboratoire introuvable" })
        return
    end

    local laboData = SaveData.json["illegals"]["laboratorys"][itemId]
    local price = laboData.price

    if xPlayer.getAccount("cash").money < price then
        cb({ success = false, message = "Vous n'avez pas assez d'argent ($" .. ESX.Math.GroupDigits(price) .. " requis)" })
        return
    end

    if option == "ind" then
        xPlayer.removeAccountMoney("cash", price)
        SaveData.json["illegals"]["laboratorys"][itemId].hasBuy = true
        SaveData.json["illegals"]["laboratorys"][itemId].ownerType = "ind"
        SaveData.json["illegals"]["laboratorys"][itemId].owner = xPlayer.getIdunique()

        null.logs.send("Logs", "Le joueur : " .. xPlayer.getName() .. " (U" .. xPlayer.getIdunique() .. " T" .. xPlayer.source .. ") a acheter le labo : " .. itemId, "laboratoires", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})
        
        TriggerClientEvent("null:labo:start-tutorial", xPlayer.source, itemId, "player", SaveData.json["illegals"]["laboratorys"][itemId].coords)
        TriggerClientEvent("null:labo:edit", -1, itemId, SaveData.json["illegals"]["laboratorys"][itemId], true)

        cb({ success = true, message = "Laboratoire acheté avec succès !", close = true })
    elseif option == "group" then
        if xPlayer.getJob2() ~= nil and xPlayer.getJob2().name ~= nil and xPlayer.getJob2().name ~= "unemployed2" then
            xPlayer.removeAccountMoney("cash", price)
            SaveData.json["illegals"]["laboratorys"][itemId].hasBuy = true
            SaveData.json["illegals"]["laboratorys"][itemId].ownerType = "group"
            SaveData.json["illegals"]["laboratorys"][itemId].owner = xPlayer.getJob2().name
    
            null.logs.send("Logs", "Le joueur : " .. xPlayer.getName() .. " (U" .. xPlayer.getIdunique() .. " T" .. xPlayer.source .. ") a acheter le labo : " .. itemId .. " (pour le groupe : " .. xPlayer.getJob2().name .. ")", "laboratoires", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})

            TriggerClientEvent("null:labo:start-tutorial", xPlayer.source, itemId, "group", SaveData.json["illegals"]["laboratorys"][itemId].coords)
            TriggerClientEvent("null:labo:edit", -1, itemId, SaveData.json["illegals"]["laboratorys"][itemId], true)

            cb({ success = true, message = "Laboratoire acheté pour votre groupe !", close = true })
        else
            cb({ success = false, message = "Vous n'avez pas de groupe illégal" })
        end
    else
        cb({ success = false, message = "Option invalide" })
    end
end)

RegisterNetEvent("null:labo:staff:create", function(id, data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer.getGroup() == "user" then return end

    for k,v in pairs(TemplateLabo) do
        if data[k] == nil then 
            data[k] = v
        end
    end
    data.treatementmeth.fours = Config.laboratoire.type["meth"].fours
    data.treatementmeth.cuves = {}
    if Config.laboratoire.type["meth"].cuves then
        for cuveId, _ in pairs(Config.laboratoire.type["meth"].cuves) do
            data.treatementmeth.cuves[cuveId] = { state = "idle", ingredients = {}, traysRemaining = 0 }
        end
    end

    data.price = math.random(Config.laboratoire.price[1], Config.laboratoire.price[2])
    data.instance = math.random(50, 200)
    data.createdAt = os.time()
    SaveData.json["illegals"]["laboratorys"][id] = data

    SetupLaboWeedDry(id)
    SetupLaboEmployees(id, false)
    SetupDropBox(id)

    null.logs.send("Logs","Le staff : "..xPlayer.getName().." (U"..xPlayer.getIdunique().." T"..xPlayer.source..") a créer le labo : "..id, "staffs", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})


    TriggerClientEvent("null:labo:add", -1, id, SaveData.json["illegals"]["laboratorys"][id])
end) 

RegisterNetEvent("null:labo:staff:editPos", function(id, new)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer.getGroup() == "user" then return end
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end

    SaveData.json["illegals"]["laboratorys"][id].coords = new

    null.logs.send("Logs","Le staff : "..xPlayer.getName().." (U"..xPlayer.getIdunique().." T"..xPlayer.source..") a modifier la position du labo : "..id, "staffs", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})


    TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id], false, true)
end)

RegisterNetEvent("null:labo:staff:delete", function(id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer.getGroup() == "user" then return end
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    local data = SaveData.json["illegals"]["laboratorys"][id]
    if DoesEntityExist(data.cameraProps) then 
        DeleteEntity(data.cameraProps)
    end
    SaveData.json["illegals"]["laboratorys"][id] = nil

    null.logs.send("Logs","Le staff : "..xPlayer.getName().." (U"..xPlayer.getIdunique().." T"..xPlayer.source..") a supprimer le labo : "..id, "staffs", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})


    TriggerClientEvent("null:labo:edit", -1, id, nil, false, true)
end)

RegisterNetEvent("null:labo:staff:updateUpgrade", function(id, data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer.getGroup() == "user" then return end
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    local oldUpgrades = SaveData.json["illegals"]["laboratorys"][id].upgrades

    SaveData.json["illegals"]["laboratorys"][id].upgrades = data

    for k,v in pairs(oldUpgrades) do 
        if v == "security" then
            if DoesEntityExist(SaveData.json["illegals"]["laboratorys"][id].cameraProps) then 
                DeleteEntity(SaveData.json["illegals"]["laboratorys"][id].cameraProps)
            end
        end
    end

    for k,v in pairs(data) do
        if v == "security" then        
            SetupSecurityCamera(id)
            break
        end
    end

    null.logs.send("Logs","Le staff : "..xPlayer.getName().." (U"..xPlayer.getIdunique().." T"..xPlayer.source..") a modifier les upgrades du labo : "..id, "staffs", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})


    TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id])
end)  

RegisterNetEvent("null:labo:staff:updateType", function(id, new)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer.getGroup() == "user" then return end
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end

    SaveData.json["illegals"]["laboratorys"][id].type = new

    TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id])
end)  

RegisterNetEvent("null:labo:staff:edit", function(id, data)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if xPlayer.getGroup() == "user" then return end

    SaveData.json["illegals"]["laboratorys"][id] = data

    SetupLaboWeedDry(id)
    SetupLaboEmployees(id, false)

    null.logs.send("Logs","Le staff : "..xPlayer.getName().." (U"..xPlayer.getIdunique().." T"..xPlayer.source..") a modifier le type du labo : "..id, "staffs", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})


    TriggerClientEvent("null:labo:edit", -1, id, data)
end)


local lastPlyRequest = {}
RegisterNetEvent("null:labo:cutDriedHead", function(id, isFirst)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].upgrades["treatment-equipment"] == nil then return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end

    if isFirst then
        local item = xPlayer.getInventoryItem(Config.laboratoire.type["weed"].items["plantdry"])
        if item == nil or item.count <= 0 then return end
        xPlayer.removeInventoryItem(Config.laboratoire.type["weed"].items["plantdry"], 1)

        if SaveData.json["illegals"]["laboratorys"][id].upgrades["security"] then
            table.insert(SaveData.json["illegals"]["laboratorys"][id].History["treatment"], {
                idunique = xPlayer.getIdunique(),
                name = xPlayer.getName(),
                firstname = xPlayer.firstname,
                lastname = xPlayer.lastname,
                time = os.date("%Y-%m-%d %H:%M:%S"),
                ostime = os.time()  
            })
            TriggerClientEvent("null:labo:history", -1, id, SaveData.json["illegals"]["laboratorys"][id].History)
        end
    end

    xPlayer.addInventoryItem(Config.laboratoire.type["weed"].items["head_raw"], 1)

    local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed"
    if gangname ~= "unemployed" then
        exports["null-core"]:AddGangXP(gangname, 2)
    end
end)

RegisterNetEvent("null:labo:cutWeed", function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if lastPlyRequest[xPlayer.source] ~= nil then
        if (os.time() - lastPlyRequest[xPlayer.source]) < 25 then return end
    end
    lastPlyRequest[xPlayer.source] = os.time()
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].upgrades["treatment-equipment"] == nil then return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end

    local number = 0

    if SaveData.json["illegals"]["laboratorys"][id].upgrades["uv-light"] then
        number = math.random(5, 14)
    else
        number = math.random(3, 6)
    end

    local item = xPlayer.getInventoryItem(Config.laboratoire.type["weed"].items["head_raw"])
    if item == nil or item.count <= 0 then return end

    xPlayer.removeInventoryItem(Config.laboratoire.type["weed"].items["head_raw"], 1)

    xPlayer.addInventoryItem(Config.laboratoire.type["weed"].items["bud"], number)

    local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed"
    if gangname ~= "unemployed" then
        exports["null-core"]:AddGangXP(gangname, 2 * number)
    end
end)

RegisterNetEvent("null:labo:packageWeedBud", function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].upgrades["treatment-equipment"] == nil then return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end

    local budItem = xPlayer.getInventoryItem(Config.laboratoire.type["weed"].items["bud"])
    if budItem == nil or budItem.count <= 0 then
        TriggerClientEvent("null:labo:packageResult", xPlayer.source, false, "Vous n'avez plus de buds de weed.")
        return
    end
    local poochItem = xPlayer.getInventoryItem(Config.laboratoire.items["pooch"])
    if poochItem == nil or poochItem.count <= 0 then
        TriggerClientEvent("null:labo:packageResult", xPlayer.source, false, "Vous n'avez plus de pochon vide.")
        return
    end

    xPlayer.removeInventoryItem(Config.laboratoire.type["weed"].items["bud"], 1)
    xPlayer.removeInventoryItem(Config.laboratoire.items["pooch"], 1)
    xPlayer.addInventoryItem(Config.laboratoire.type["weed"].items["traitement"], 1)

    local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed"
    if gangname ~= "unemployed" then
        exports["null-core"]:ProgressGangMission(gangname, "daily_lab_produce", 1)
        exports["null-core"]:ProgressGangMission(gangname, "daily_lab_produce_large", 1)
        exports["null-core"]:ProgressGangMission(gangname, "weekly_lab_mass", 1)
        exports["null-core"]:AddGangXP(gangname, 5)
    end

    TriggerClientEvent("null:labo:packageResult", xPlayer.source, true)
end)

-- ========== CUVE SYSTEM ==========
function SyncCuveToClients(id)
    local cuves = SaveData.json["illegals"]["laboratorys"][id].treatementmeth.cuves
    local cuveConf = Config.laboratoire.type["meth"].cuveConfig
    
    -- Prepare client data with calculated remaining times
    local clientData = {}
    for cuveId, cuveData in pairs(cuves) do
        clientData[cuveId] = {
            state = cuveData.state,
            ingredients = cuveData.ingredients,
            traysRemaining = cuveData.traysRemaining,
        }
        -- Calculate remaining time for client display
        if cuveData.state == "mixing" and cuveData.mixStartTime then
            local elapsed = os.time() - cuveData.mixStartTime
            local remaining = math.max(0, (devmode and 10 or cuveConf.mixTime * 60) - elapsed)
            clientData[cuveId].mixRemaining = math.ceil(remaining / 60)
        elseif cuveData.state == "mixing_solvant" and cuveData.solvantMixStartTime then
            local elapsed = os.time() - cuveData.solvantMixStartTime
            local remaining = math.max(0, (devmode and 10 or cuveConf.solvantMixTime * 60) - elapsed)
            clientData[cuveId].solvantRemaining = math.ceil(remaining / 60)
        end
    end
    
    for k, v in pairs(PeopleInLabo) do
        if v == id then
            local xP = ESX.GetPlayerFromIdUnique(k)
            if xP then
                TriggerClientEvent("null:labo:updatecuve", xP.source, id, clientData)
            end
        end
    end
end

RegisterNetEvent("null:labo:methCuveAddIngredient", function(id, cuveId, ingredientKey)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].type ~= "meth" then return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end

    local cuve = SaveData.json["illegals"]["laboratorys"][id].treatementmeth.cuves[cuveId]
    if cuve == nil then return end
    if cuve.state ~= "idle" and cuve.state ~= "adding_ingredients" then return end

    local cuveConf = Config.laboratoire.type["meth"].cuveConfig
    local validIngredient = false
    for _, v in ipairs(cuveConf.ingredients) do
        if v == ingredientKey then validIngredient = true break end
    end
    if not validIngredient then return end

    for _, v in ipairs(cuve.ingredients or {}) do
        if v == ingredientKey then
            xPlayer.showNotification("Cet ingrédient est déjà dans la cuve.")
            return
        end
    end

    local itemName = Config.laboratoire.type["meth"].items[ingredientKey]
    local item = xPlayer.getInventoryItem(itemName)
    if item == nil or item.count <= 0 then
        xPlayer.showNotification("Vous n'avez pas cet ingrédient.")
        return
    end

    xPlayer.removeInventoryItem(itemName, 1)

    if cuve.ingredients == nil then cuve.ingredients = {} end
    table.insert(cuve.ingredients, ingredientKey)
    cuve.state = "adding_ingredients"

    if #cuve.ingredients >= #cuveConf.ingredients then
        cuve.state = "mixing"
        cuve.mixStartTime = os.time()
    end

    SyncCuveToClients(id)
end)

RegisterNetEvent("null:labo:methCuveAddSolvant", function(id, cuveId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].type ~= "meth" then return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end

    local cuve = SaveData.json["illegals"]["laboratorys"][id].treatementmeth.cuves[cuveId]
    if cuve == nil then return end
    if cuve.state ~= "waiting_solvant" then return end

    local item = xPlayer.getInventoryItem(Config.laboratoire.type["meth"].items["solvant"])
    if item == nil or item.count <= 0 then
        xPlayer.showNotification("Vous n'avez pas de solvant.")
        return
    end

    xPlayer.removeInventoryItem(Config.laboratoire.type["meth"].items["solvant"], 1)
    cuve.state = "mixing_solvant"
    cuve.solvantMixStartTime = os.time()

    SyncCuveToClients(id)
end)

RegisterNetEvent("null:labo:methCuveRetrieveTray", function(id, cuveId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].type ~= "meth" then return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end

    local cuve = SaveData.json["illegals"]["laboratorys"][id].treatementmeth.cuves[cuveId]
    if cuve == nil then return end
    if cuve.state ~= "ready" then return end
    if (cuve.traysRemaining or 0) <= 0 then return end

    xPlayer.addInventoryItem(Config.laboratoire.type["meth"].items["mixture"], 1)
    cuve.traysRemaining = cuve.traysRemaining - 1

    if cuve.traysRemaining <= 0 then
        cuve.state = "idle"
        cuve.ingredients = {}
        cuve.traysRemaining = 0
    end

    local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed"
    if gangname ~= "unemployed" then
        exports["null-core"]:AddGangXP(gangname, 3)
    end

    SyncCuveToClients(id)
end)

-- ========== BREAKING METH (PropInteract) ==========
RegisterNetEvent("null:labo:methSmashTray", function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].type ~= "meth" then return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end

    local item = xPlayer.getInventoryItem(Config.laboratoire.type["meth"].items["meth_tray"])
    if item == nil or item.count <= 0 then
        xPlayer.showNotification("Vous n'avez pas de plateau de meth.")
        return
    end

    xPlayer.removeInventoryItem(Config.laboratoire.type["meth"].items["meth_tray"], 1)
end)

RegisterNetEvent("null:labo:methPackCrystal", function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].type ~= "meth" then return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end

    local poochItem = xPlayer.getInventoryItem(Config.laboratoire.items["pooch"])
    if poochItem == nil or poochItem.count <= 0 then
        TriggerClientEvent("null:labo:packageResult", xPlayer.source, false, "Vous n'avez plus de pochon vide.")
        return
    end

    xPlayer.removeInventoryItem(Config.laboratoire.items["pooch"], 1)
    xPlayer.addInventoryItem(Config.laboratoire.type["meth"].items["traitement"], 1)

    local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed"
    if gangname ~= "unemployed" then
        exports["null-core"]:ProgressGangMission(gangname, "daily_lab_produce", 1)
        exports["null-core"]:ProgressGangMission(gangname, "daily_lab_produce_large", 1)
        exports["null-core"]:ProgressGangMission(gangname, "weekly_lab_mass", 1)
        exports["null-core"]:AddGangXP(gangname, 5)
    end
end)


RegisterNetEvent("null:labo:setmethinfour", function(id, fourid)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].type ~= "meth" then return end
    if SaveData.json["illegals"]["laboratorys"][id].treatementmeth.fours[fourid] == nil then return end
    if Config.laboratoire.type["meth"].fours[fourid] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].treatementmeth.fours[fourid].inFour == nil then
        SaveData.json["illegals"]["laboratorys"][id].treatementmeth.fours[fourid].inFour = {}
    end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end
    local item = xPlayer.getInventoryItem(Config.laboratoire.type["meth"].items["mixture"])
    if item == nil or item.count <= 0 then 
        xPlayer.showNotification("Vous n'avez pas de mixture de Meth")
        return 
    end
    local nbr = 0
    for k,v in pairs(SaveData.json["illegals"]["laboratorys"][id].treatementmeth.fours[fourid].inFour) do 
        nbr += 1 
    end
    if nbr >= Config.laboratoire.type["meth"].fours[fourid].numberMax then return end
    xPlayer.removeInventoryItem(Config.laboratoire.type["meth"].items["mixture"], 1)
    table.insert(SaveData.json["illegals"]["laboratorys"][id].treatementmeth.fours[fourid].inFour, {
        name = Config.laboratoire.type["meth"].items["mixture"],
        finish = false,
        timestart = os.time()
    })
    for k,v in pairs(PeopleInLabo) do
        if v == id then
            TriggerClientEvent("null:labo:updatefour", -1, id, SaveData.json["illegals"]["laboratorys"][id].treatementmeth.fours)
        end
    end
end)

RegisterNetEvent("null:labo:recolteMethFour", function(id, fourid)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].type ~= "meth" then return end
    if SaveData.json["illegals"]["laboratorys"][id].treatementmeth.fours[fourid] == nil then return end
    if Config.laboratoire.type["meth"].fours[fourid] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].treatementmeth.fours[fourid].inFour == nil then
        SaveData.json["illegals"]["laboratorys"][id].treatementmeth.fours[fourid].inFour = {}
        return
    end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end
    local nbr = 0
    for k,v in pairs(SaveData.json["illegals"]["laboratorys"][id].treatementmeth.fours[fourid].inFour) do 
        if v.finish then
            nbr += 1 
            SaveData.json["illegals"]["laboratorys"][id].treatementmeth.fours[fourid].inFour[k] = nil
            break
        end
    end
    if nbr <= 0 then return end
    
    xPlayer.addInventoryItem(Config.laboratoire.type["meth"].items["meth_tray"], 1)

    for k,v in pairs(PeopleInLabo) do
        if v == id then
            TriggerClientEvent("null:labo:updatefour", -1, id, SaveData.json["illegals"]["laboratorys"][id].treatementmeth.fours)
        end
    end
end)

RegisterNetEvent("null:labo:dryweed", function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].upgrades["treatment-equipment"] == nil then return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end
    local item = xPlayer.getInventoryItem(Config.laboratoire.type["weed"].items["plant"])
    if item == nil or item.count <= 0 then 
        xPlayer.showNotification("Vous n'avez pas de plante de weed")
        return 
    end
    local nbr = 0
    for k,v in pairs(SaveData.json["illegals"]["laboratorys"][id].treatmentequipment.indrying) do nbr += 1 end

    local nbrMax = 0
    for k,v in pairs(Config.laboratoire.type["weed"].treatmentequipment.DryPlantsCoords) do nbrMax += 1 end

    if nbr >= nbrMax then return end
    xPlayer.removeInventoryItem(Config.laboratoire.type["weed"].items["plant"], 1)
    table.insert(SaveData.json["illegals"]["laboratorys"][id].treatmentequipment.indrying, {
        name = Config.laboratoire.type["weed"].items["plant"],
        finish = false,
        timestart = os.time()
    })
    SetupLaboWeedDry(id)
    for k,v in pairs(PeopleInLabo) do
        if v == id then
            TriggerClientEvent("null:labo:updateindrying", -1, id, SaveData.json["illegals"]["laboratorys"][id].treatmentequipment.indrying)
        end
    end
end)

RegisterNetEvent("null:labo:recoltedryweed", function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].upgrades["treatment-equipment"] == nil then return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end
    local nbr = 0
    for k,v in pairs(SaveData.json["illegals"]["laboratorys"][id].treatmentequipment.indrying) do 
        if v.finish then
            nbr += 1 
            SaveData.json["illegals"]["laboratorys"][id].treatmentequipment.indrying[k] = nil
            break
        end
    end
    if nbr <= 0 then return end
    
    xPlayer.addInventoryItem(Config.laboratoire.type["weed"].items["plantdry"], 1)
    SetupLaboWeedDry(id)
    for k,v in pairs(PeopleInLabo) do
        if v == id then
            TriggerClientEvent("null:labo:updateindrying", -1, id, SaveData.json["illegals"]["laboratorys"][id].treatmentequipment.indrying)
        end
    end
end)



RegisterNetEvent("null:labo:selltoDealer", function(id, count, price, type)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].upgrades["dealer"] == nil then return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].dealer.lastRequest ~= nil then return end
    local item = xPlayer.getInventoryItem(Config.laboratoire.type[type].items["traitement"])
    if item == nil or item.count < count then 
        xPlayer.showNotification("Vous n'avez pas assez de pochon de weed")
        return 
    end
    xPlayer.removeInventoryItem(Config.laboratoire.type[type].items["traitement"], count)
    SaveData.json["illegals"]["laboratorys"][id].dealer.lastRequest = {
        time = os.time(),
        count = count,
        item = type,
        price = price,
    }

    null.logs.send("Logs","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique().." T"..xPlayer.source..") a vendu au dealer (N:"..type..", Q:"..count.."X, Price: "..price.."$) (labo : "..id..")", "laboratoires", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})


    TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id])
end)

RegisterNetEvent("null:labo:takeReward", function(id)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].upgrades["dealer"] == nil then return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].dealer.lastRequest == nil then return end
    if SaveData.json["illegals"]["laboratorys"][id].dealer.lastRequest.reward == nil then return end
    local drugtype = SaveData.json["illegals"]["laboratorys"][id].dealer.lastRequest.item
    xPlayer.addInventoryItem(Config.laboratoire.type[drugtype].items["pooch"], SaveData.json["illegals"]["laboratorys"][id].dealer.lastRequest.reward.unselled)
    local finalDirty = SaveData.json["illegals"]["laboratorys"][id].dealer.lastRequest.reward.total * 0.9 -- enleves 10%
    xPlayer.addAccountMoney("dirtycash", finalDirty)

    local gangname = xPlayer.getJob2() and xPlayer.getJob2().name or "unemployed"
    if gangname ~= "unemployed" then
        exports["null-core"]:ProgressGangMission(gangname, "daily_dirty_money", finalDirty)
        exports["null-core"]:ProgressGangMission(gangname, "weekly_dirty_money_mass", finalDirty)
        exports["null-core"]:AddGangXP(gangname, 25)
    end

    SaveData.json["illegals"]["laboratorys"][id].dealer.lastRequest = nil
    TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id])
end)

ESX.RegisterServerCallback("null:labo:purchaseUpgrade", function(source, cb, upgrade, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then 
        cb(false, "Ce laboratoire n'existe pas/plus.") 
        return
    end
    if Config.laboratoire.upgrades[upgrade] == nil  then 
        cb(false, "Cette améiloration n'existe pas/plus.") 
        return
    end
    if xPlayer.getAccount("bank").money < Config.laboratoire.upgrades[upgrade].prices.oneTime then
        cb(false, "Vous n'avez pas assez d'argent sur votre compte en banque.")
        return
    else
        if SaveData.json["illegals"]["laboratorys"][id].upgrades[upgrade] == true then 
            cb(false, "Vous avez déjà cette améiloration.")
            return
        else
            xPlayer.removeAccountMoney("bank", Config.laboratoire.upgrades[upgrade].prices.oneTime, {title = 'Amélioration Labo', description = 'Upgrade: '..upgrade, category = 'purchase'})
            SaveData.json["illegals"]["laboratorys"][id].upgrades[upgrade] = true
            cb(true, "Paiement reçu.")
            if upgrade == "security" then
                SetupSecurityCamera(id)
            end
            TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id])
            if upgrade == "treatment-equipment" then
                TriggerClientEvent("null:labo:start-weed-traitement-tutorial", source, id)
            end
            return
        end
    end
end)

ESX.RegisterServerCallback("null:labo:purchaseLabType", function(source, cb, newType, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then 
        cb(false, "Ce laboratoire n'existe pas/plus.") 
        return
    end
    local oldType = SaveData.json["illegals"]["laboratorys"][id].type
    if Config.laboratoire.type[newType] == nil then 
        cb(false, "Ce type n'existe pas/plus.") 
        return
    end
    if newType ~= "weed" and newType ~= "meth" and newType ~= "coke" then
        cb(false, "Ce meublement n'est pas disponible actuellement.") 
        return
    end
    null.DebugPrint("Change Lab Type : "..id.." - "..newType.." ("..oldType..")")
    if xPlayer.getAccount("bank").money < Config.laboratoire.type[newType].price then
        cb(false, "Vous n'avez pas assez d'argent sur votre compte en banque.")
        return
    else
        if oldType == newType then 
            cb(false, "Vous avez déjà ce type.")
            return
        else
            xPlayer.removeAccountMoney("bank", Config.laboratoire.type[newType].price, {title = 'Changement Type Labo', description = 'Nouveau type: '..newType, category = 'purchase'})

            if oldType == "weed" then
                null.DebugPrint("Delete All Weedplants from labo : "..id)
                MySQL.Async.execute('DELETE FROM weedplants WHERE `inLabo` = "'..id..'"', {})
                for k,v in pairs(SaveData.Illegal.WeedPlants) do 
                    if tostring(v.inLabo) == tostring(id) then
                        SaveData.Illegal.WeedPlants[k] = nil
                        null.DebugPrint("Delete Weed Plant From Labo : "..id.." ("..k..") (Cause: changeType)")
                    end
                end
                TriggerClientEvent("null:weed:client:recevie", -1, SaveData.Illegal.WeedPlants)
            end

            null.logs.send("Logs","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique().." T"..xPlayer.source..") a acheter le type "..newType.." (labo : "..id..")", "laboratoires", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})

            SaveData.json["illegals"]["laboratorys"][id].type = newType
            cb(true, "Paiement reçu.")
            TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id])
            if newType == "weed" then
                TriggerClientEvent("null:labo:start-weed-tutorial", xPlayer.source, id)
            end
            return
        end
    end
end)

ESX.RegisterServerCallback("null:labo:hireEmployee", function(source, cb, employee, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then 
        cb(false, "Ce laboratoire n'existe pas/plus.") 
        return
    end
    if Config.laboratoire.employees[employee] == nil then 
        cb(false, "Cette employer n'existe pas/plus.") 
        return
    end
    local employeeLabType = Config.laboratoire.employees[employee].labType
    local labType = SaveData.json["illegals"]["laboratorys"][id].type
    if employeeLabType and labType and employeeLabType ~= labType then
        cb(false, "Cet employé n'est pas compatible avec ce type de laboratoire.")
        return
    end
    if xPlayer.getAccount("bank").money < Config.laboratoire.employees[employee].prices.onetime then
        cb(false, "Vous n'avez pas assez d'argent sur votre compte en banque.")
        return
    else
        if SaveData.json["illegals"]["laboratorys"][id].employees == nil then
            SaveData.json["illegals"]["laboratorys"][id].employees = {}
        end
        if SaveData.json["illegals"]["laboratorys"][id].employees[employee] ~= nil then 
            cb(false, "Vous avez déjà cette employer.")
            return
        else
            xPlayer.removeAccountMoney("bank", Config.laboratoire.employees[employee].prices.onetime, {title = 'Embauche Employé Labo', description = 'Employé: '..employee, category = 'purchase'})
            SaveData.json["illegals"]["laboratorys"][id].employees[employee] = {
                id = employee,
                lastPay = os.time(),
                getPayed = true,
                inventory = {},
                money = 0,
            }
            cb(true, "Paiement reçu.")
            SetupLaboEmployees(id, false)
            TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id])
            return
        end
    end
end)


ESX.RegisterServerCallback("null:labo:fireEmployee", function(source, cb, employee, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then 
        cb(false, "Ce laboratoire n'existe pas/plus.") 
        return
    end
    if Config.laboratoire.employees[employee] == nil then 
        cb(false, "Cette employer n'existe pas/plus.") 
        return
    end
    -- if not devmode then
    --     cb(false, "Cette fonctionnalitée arrive plus tard.") 
    --     return
    -- end
    if SaveData.json["illegals"]["laboratorys"][id].employees[employee] == nil then 
        cb(false, "Vous n'avez pas cette employer.")
        return
    else
        ReleaseBaseSpot(id, employee)
        SaveData.json["illegals"]["laboratorys"][id].employees[employee] = nil
        cb(true, "Vous avez virer avec succés cette employer.")
        SetupLaboEmployees(id, false)
        TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id])
        return
    end
end)

ESX.RegisterServerCallback("null:labo:payEmployee", function(source, cb, employee, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then 
        cb(false, "Ce laboratoire n'existe pas/plus.") 
        return
    end
    if Config.laboratoire.employees[employee] == nil then 
        cb(false, "Cette employer n'existe pas/plus.") 
        return
    end
    -- if not devmode then
    --     cb(false, "Cette fonctionnalitée arrive plus tard.") 
    --     return
    -- end
    if SaveData.json["illegals"]["laboratorys"][id].employees[employee] == nil then 
        cb(false, "Vous n'avez pas cette employer.")
        return
    else
        if xPlayer.getAccount("bank").money < Config.laboratoire.employees[employee].prices.daily then
            cb(false, "Vous n'avez pas assez d'argent sur votre compte en banque.")
            return
        end
        xPlayer.removeAccountMoney("bank", Config.laboratoire.employees[employee].prices.daily, {title = 'Salaire Employé Labo', description = 'Paiement journalier: '..employee, category = 'salary'})
        SaveData.json["illegals"]["laboratorys"][id].employees[employee].lastPay = os.time()
        SaveData.json["illegals"]["laboratorys"][id].employees[employee].getPayed = true
        SetupLaboEmployees(id, false)
        TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id])
    end
end)

RegisterNetEvent("null:labo:removeEmployeeItem", function(labId, employeeId, itemName, count)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab or not lab.employees or not lab.employees[employeeId] then
        return
    end
    
    local employee = lab.employees[employeeId]
    if not employee.inventory then
        return
    end
    
    for k, v in pairs(employee.inventory) do
        if v.name == itemName then
            v.count = v.count - count
            if v.count <= 0 then
                table.remove(employee.inventory, k)
            end
            TriggerClientEvent("null:labo:edit", -1, labId, lab)
            break
        end
    end
end)

ESX.RegisterServerCallback("null:labo:inviteMember", function(source, cb, members, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.unique == members then
        cb(false, "Vous ne pouvez pas vous invitez vous-meme.") 
        return
    end
    if members == nil then
        cb(false, "...") 
        return
    end
    members = tonumber(members)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then 
        cb(false, "Ce laboratoire n'existe pas/plus.") 
        return
    end
    if SaveData.json["illegals"]["laboratorys"][id].members[members] ~= nil then
        cb(false, "Vous avez déjà inviter cette personne.") 
        return
    end
    local xMember = ESX.GetPlayerFromIdUnique(members) 
    if not xMember then
        cb(false, "Cette personne n'est pas dans la ville.") 
        return
    end
    xMember.showNotification("Vous avez été inviter dans un laboratoire.")
    TriggerClientEvent("null:setNewWayPoint", xMember.source, SaveData.json["illegals"]["laboratorys"][id].coords)
    SaveData.json["illegals"]["laboratorys"][id].members[members] = {
        name = xMember.name,
        idunique = xMember.idunique,
        permissions = {"access_lab"}
    }
    
    TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id], true)
end)

ESX.RegisterServerCallback("null:labo:removeMember", function(source, cb, members, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if members == nil then
        cb(false, "...") 
        return
    end
    members = tonumber(members)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then 
        cb(false, "Ce laboratoire n'existe pas/plus.") 
        return
    end
    if SaveData.json["illegals"]["laboratorys"][id].members[members] == nil then
        cb(false, "Cette personne n'est pas dans la liste des membres.") 
        return
    end
    SaveData.json["illegals"]["laboratorys"][id].members[members] = nil
    TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id], true)
end)

ESX.RegisterServerCallback("null:labo:transferOwnership", function(source, cb, newOwnerId, labId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][labId] == nil then 
        cb(false, "Ce laboratoire n'existe pas/plus.") 
        return
    end
    
    -- Vérifier que le joueur est bien le propriétaire
    if SaveData.json["illegals"]["laboratorys"][labId].ownerType ~= "individual" then
        cb(false, "Seul un propriétaire individuel peut transférer la propriété.")
        return
    end
    
    if SaveData.json["illegals"]["laboratorys"][labId].owner ~= xPlayer.idunique then
        cb(false, "Vous n'êtes pas le propriétaire de ce laboratoire.")
        return
    end
    
    -- Vérifier que le nouveau propriétaire existe
    local xNewOwner = ESX.GetPlayerFromIdUnique(newOwnerId)
    if not xNewOwner then
        cb(false, "Le joueur avec cet ID n'est pas connecté.")
        return
    end
    
    -- Transférer la propriété
    SaveData.json["illegals"]["laboratorys"][labId].owner = newOwnerId
    
    -- Retirer l'ancien propriétaire des membres s'il y était
    if SaveData.json["illegals"]["laboratorys"][labId].members[xPlayer.idunique] then
        SaveData.json["illegals"]["laboratorys"][labId].members[xPlayer.idunique] = nil
    end
    
    -- Ajouter l'ancien propriétaire comme membre avec tous les accès
    SaveData.json["illegals"]["laboratorys"][labId].members[xPlayer.idunique] = {
        name = xPlayer.getName(),
        idunique = xPlayer.idunique,
        permissions = {"access_lab", "access_safe", "access_storage", "access_camera", "access_dealer", "harvest_weed", "process_weed", "mix_meth"}
    }
    
    -- Notifier les joueurs
    xPlayer.showNotification("Vous avez transféré la propriété du laboratoire à "..xNewOwner.getName())
    xNewOwner.showNotification("Vous êtes maintenant propriétaire d'un laboratoire !")
    TriggerClientEvent("null:setNewWayPoint", xNewOwner.source, SaveData.json["illegals"]["laboratorys"][labId].coords)
    
    -- Logger l'action
    null.logs.send("Logs","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique().." T"..xPlayer.source..") a transféré la propriété du labo "..labId.." à "..xNewOwner.getName().." (U"..newOwnerId..")", "laboratoires", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})
    
    TriggerClientEvent("null:labo:edit", -1, labId, SaveData.json["illegals"]["laboratorys"][labId], true)
    cb(true, "Transfert effectué avec succès.", xNewOwner.getName())
end)

ESX.RegisterServerCallback("null:labo:updateMemberPermissions", function(source, cb, members, id, newperms)
    local xPlayer = ESX.GetPlayerFromId(source)
    if members == nil then
        cb(false, "...") 
        return
    end
    members = tonumber(members)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then 
        cb(false, "Ce laboratoire n'existe pas/plus.") 
        return
    end
    if SaveData.json["illegals"]["laboratorys"][id].members[members] == nil then
        cb(false, "Cette personne n'est pas dans la liste des membres.") 
        return
    end
    SaveData.json["illegals"]["laboratorys"][id].members[members].permissions = newperms
    TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id], true)
end)

ESX.RegisterServerCallback("null:labo:canCutHeads", function(source, cb, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then cb(false) return end
    if SaveData.json["illegals"]["laboratorys"][id].upgrades["treatment-equipment"] == nil then cb(false) return end
    if SaveData.json["illegals"]["laboratorys"][id].type ~= "weed" then cb(false) return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then cb(false) return end
    local item = xPlayer.getInventoryItem(Config.laboratoire.type["weed"].items["plantdry"])
    if item == nil or item.count <= 0 then
        xPlayer.showNotification("Vous n'avez pas de plante de weed sèches")
        cb(false) 
        return
    end
    cb(true) 
end)

ESX.RegisterServerCallback("null:labo:canCut", function(source, cb, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then cb(false) return end
    if SaveData.json["illegals"]["laboratorys"][id].upgrades["treatment-equipment"] == nil then cb(false) return end
    if SaveData.json["illegals"]["laboratorys"][id].type ~= "weed" then cb(false) return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then cb(false) return end
    local item = xPlayer.getInventoryItem(Config.laboratoire.type["weed"].items["head_raw"])
    if item == nil or item.count <= 0 then
        xPlayer.showNotification("Vous n'avez pas de têtes de weed non traitées")
        cb(false) 
        return
    end
    cb(true) 
end)

ESX.RegisterServerCallback("null:labo:canMixMeth", function(source, cb, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then cb(false) return end
    if SaveData.json["illegals"]["laboratorys"][id].type ~= "meth" then cb(false) return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then cb(false) return end
    
    -- Check if player has at least one ingredient available
    local hasIngredient = false
    local ingredients = Config.laboratoire.type["meth"].cuveConfig.ingredients
    for _, ingKey in ipairs(ingredients) do
        local itemName = Config.laboratoire.type["meth"].items[ingKey]
        local item = xPlayer.getInventoryItem(itemName)
        if item and item.count > 0 then
            hasIngredient = true
            break
        end
    end
    
    if not hasIngredient then
        xPlayer.showNotification("Vous n'avez aucun ingrédient pour la cuve.")
        cb(false)
        return
    end
    
    cb(true) 
end)


ESX.RegisterServerCallback("null:labo:canBreakMeth", function(source, cb, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then cb(false) return end
    if SaveData.json["illegals"]["laboratorys"][id].type ~= "meth" then cb(false) return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then cb(false) return end
    local item = xPlayer.getInventoryItem(Config.laboratoire.type["meth"].items["meth_tray"])
    if item == nil or item.count <= 0 then
        xPlayer.showNotification("Vous n'avez pas de plateau de meth cristallisée.")
        cb(false)
        return
    end

    cb(true) 
end)

ESX.RegisterServerCallback("null:labo:getMarket", function(source, cb, id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if SaveData.json["illegals"]["laboratorys"][id] == nil then cb(nil) return end
    if SaveData.json["illegals"]["laboratorys"][id].upgrades["market-study"] == nil then cb(nil) return end
    if PeopleInLabo[xPlayer.getIdunique()] == nil then cb(nil) return end
    cb(SaveData.json["illegals"]["market"]) 
end)



ESX.RegisterServerCallback('null:labo:placeDeliveryOrder', function(source, cb, items, address, note, total, laboid)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(false, "Joueur non trouvé")
        return
    end
     
    local playerMoney = xPlayer.getAccount('bank').money
    if playerMoney < total then
        cb(false, "Vous n'avez pas assez d'argent pour passer cette commande")
        return
    end
    
    xPlayer.removeAccountMoney('bank', total, {title = 'Commande Labo', description = 'Livraison de matériel', category = 'purchase'})
    
    SaveData.json["LaboOrders"]["LastOrderId"] = SaveData.json["LaboOrders"]["LastOrderId"] + 1
    local orderId = string.format("%06d", SaveData.json["LaboOrders"]["LastOrderId"])
    local deliveryTime = math.random(Config.laboratoire.timeDeliveryService[1], Config.laboratoire.timeDeliveryService[2]) * 60 
    if devmode then
        deliveryTime = math.random(10, 120)
    end
    
    SaveData.json["LaboOrders"]["DeliveryOrders"][orderId] = {
        id = orderId,
        player = xPlayer.identifier,
        items = items,
        address = address,
        note = note,
        labo = laboid,
        total = total,
        status = "pending", 
        deliveryTime = deliveryTime,
        createdAt = os.time()
    }
    
    TriggerClientEvent("null:objectives:setStep", source, "labo_weed_production", "wait_delivery")
    
    null.DebugPrint(string.format("[Delivery Service] Nouvelle commande #%s de %s pour un total de $%s. Prévue pour dans "..math.ceil(deliveryTime/60) .. " minutes.", 
        orderId, GetPlayerName(source), total))
    SetTimeout(deliveryTime * 1000, function()
        DeliverOrder(orderId, source)
    end)
    
    TriggerClientEvent('esx:showNotification', source, "Votre commande #" .. orderId .. " a été passée avec succès. Livraison prévue dans environ " .. math.ceil(deliveryTime/60) .. " minutes.")
    
    cb(true, "Commande passée avec succès", orderId)
end)

function DeliverOrder(orderId, source)
    local order = SaveData.json["LaboOrders"]["DeliveryOrders"][orderId]
    if not order then return end
    local labo = SaveData.json["illegals"]["laboratorys"][order.labo]
    if not labo then return end
    if not labo.dropbox then return end

    order.status = "delivered"
    order.deliveredAt = os.time()
    

    local xPlayer = nil
    if source then
        xPlayer = ESX.GetPlayerFromId(source)
    end

    for itemId, itemData in pairs(order.items) do
        if itemData.type == nil then itemData.type = "item" end
        if itemData.type == "item" then
            AddItemToStorage("labo_dropbox_"..labo.id, itemData.name, itemData.quantity)
        elseif itemData.type == "weapon" then
            AddWeaponToStorage("labo_dropbox_"..labo.id, itemData.name, "Livrée par VS.N Delivery Service.")
        end
    end

    null.DebugPrint(string.format("[Delivery Service] Commande #%s livrée au labo %s", 
    orderId, labo.id))

    if xPlayer then
        xPlayer.showNotification("Vous avez reçu votre commande #"..orderId.." dans votre DropBox.")
    end


    TriggerClientEvent("null:objectives:setStep", source, "labo_weed_production", "collect_dropbox")

    --[[local xPlayer = nil
    if source then
        xPlayer = ESX.GetPlayerFromId(source)
    end
    
    if not xPlayer then
        for _, player in ipairs(ESX.GetPlayers()) do
            local p = ESX.GetPlayerFromId(player)
            if p and p.identifier == order.player then
                xPlayer = p
                source = player
                break
            end
        end
    end
    
    if xPlayer then
        for itemId, itemData in pairs(order.items) do
            xPlayer.addInventoryItem(itemData.name, itemData.quantity)
        end
        
        TriggerClientEvent('esx:showNotification', source, "Votre commande #" .. orderId .. " a été livrée !")
        
        null.DebugPrint(string.format("[Delivery Service] Commande #%s livrée à %s", 
            orderId, GetPlayerName(source)))
    else
        order.status = "pending"
        null.DebugPrint(string.format("[Delivery Service] Impossible de livrer la commande #%s, joueur déconnecté", orderId))
    end]]
end

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    for orderId, order in pairs(SaveData.json["LaboOrders"]["DeliveryOrders"]) do
        if order.player == xPlayer.identifier and order.status == "pending" then
            DeliverOrder(orderId, source)
        end
    end
end)

local function CalculateLabMonthlyBill(labId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab then return 0 end
    local totalBill = 0
    if lab.upgrades then
        for upgrade, active in pairs(lab.upgrades) do
            if active and Config.laboratoire.upgrades[upgrade] and Config.laboratoire.upgrades[upgrade].prices and Config.laboratoire.upgrades[upgrade].prices.consommation then
                for resource, cost in pairs(Config.laboratoire.upgrades[upgrade].prices.consommation) do
                    totalBill = totalBill + cost
                end
            end
        end
    end

    -- Coûts des employés (120$ par jour * 30 jours)
    local employeesCount = 0
    if lab.employees then
        for _ in pairs(lab.employees) do
            employeesCount = employeesCount + 1
        end
    end
    totalBill = totalBill + (employeesCount * 120 * 30)
    
    return totalBill
end

local function GenerateLabBill(labId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab then return end
    
    local billAmount = CalculateLabMonthlyBill(labId)
    
    if billAmount > 0 then
        local currentTime = os.time()
        local deadline = currentTime + (3 * 24 * 60 * 60)
        
        lab.billing.currentBill = billAmount
        lab.billing.lastBillDate = currentTime
        lab.billing.nextBillDate = currentTime + (30 * 24 * 60 * 60)
        lab.billing.billDeadline = deadline
        
        if lab.ownerType == "individual" then
            local xOwner = ESX.GetPlayerFromIdUnique(lab.owner)
            if xOwner then
                xOwner.showNotification("~y~Facture laboratoire~s~\nMontant: ~g~$"..billAmount.."~s~\nÉchéance: 3 jours")
            end
        end
        
        null.logs.send("Logs","Facture générée pour le labo "..labId.." : $"..billAmount.." (Échéance: "..os.date('%Y-%m-%d %H:%M:%S', deadline)..")", "laboratoires", {})
    end
end

ESX.RegisterServerCallback("null:labo:payBill", function(source, cb, labId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    
    if not lab then 
        cb(false, "Ce laboratoire n'existe pas/plus.") 
        return
    end
    
    if not lab.billing.currentBill or lab.billing.currentBill <= 0 then
        cb(false, "Aucune facture en attente.")
        return
    end
    
    if xPlayer.getAccount("bank").money < lab.billing.currentBill then
        cb(false, "Vous n'avez pas assez d'argent sur votre compte bancaire.")
        return
    end
    
    xPlayer.removeAccountMoney("bank", lab.billing.currentBill, {title = 'Facture Laboratoire', description = 'Paiement facture labo '..labId, category = 'fine'})
    
    null.logs.send("Logs","Le joueur : "..xPlayer.getName().." (U"..xPlayer.getIdunique().." T"..xPlayer.source..") a payé la facture du labo "..labId.." : $"..lab.billing.currentBill, "laboratoires", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})
    
    lab.billing.currentBill = nil
    lab.billing.billDeadline = nil
    
    TriggerClientEvent("null:labo:edit", -1, labId, lab)
    cb(true, "Facture payée avec succès.")
end)

ESX.RegisterServerCallback("null:labo:getBillingInfo", function(source, cb, labId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab then 
        cb(nil)
        return
    end
    
    cb({
        currentBill = lab.billing.currentBill,
        billDeadline = lab.billing.billDeadline,
        nextBillDate = lab.billing.nextBillDate,
        monthlyEstimate = CalculateLabMonthlyBill(labId)
    })
end)


Citizen.CreateThread(function()
    while true do
        Wait(60000)
        
        local currentTime = os.time()
        
        for labId, lab in pairs(SaveData.json["illegals"]["laboratorys"]) do
            if lab.billing then
                if lab.billing.nextBillDate and currentTime >= lab.billing.nextBillDate then
                    GenerateLabBill(labId)
                end
                
                if lab.billing.currentBill and lab.billing.billDeadline then
                    if currentTime >= lab.billing.billDeadline then
                        lab.billing.unpaidBills = (lab.billing.unpaidBills or 0) + 1
                        
                        if lab.ownerType == "individual" then
                            local xOwner = ESX.GetPlayerFromIdUnique(lab.owner)
                            if xOwner then
                                xOwner.showNotification("~r~FACTURE IMPAYÉE~s~\nLaboratoire: Pénalités appliquées!")
                            end
                        end
                        
                        lab.billing.currentBill = nil
                        lab.billing.billDeadline = nil
                        lab.billing.nextBillDate = currentTime + (30 * 24 * 60 * 60)
                        
                        null.logs.send("Logs","Facture impayée pour le labo "..labId.." (Total impayées: "..lab.billing.unpaidBills..")", "laboratoires", {})
                    elseif currentTime >= (lab.billing.billDeadline - (24 * 60 * 60)) then
                        if lab.ownerType == "individual" then
                            local xOwner = ESX.GetPlayerFromIdUnique(lab.owner)
                            if xOwner then
                                xOwner.showNotification("~o~RAPPEL FACTURE~s~\nMontant: ~g~$"..lab.billing.currentBill.."~s~\nÉchéance: ~r~24h")
                            end
                        end
                    end
                end
            end
        end
    end
end)

Citizen.CreateThread(function()
    Wait(10000)
    for labId, lab in pairs(SaveData.json["illegals"]["laboratorys"]) do
        if not lab.billing then
            lab.billing = {
                lastBillDate = nil,
                nextBillDate = os.time() + (30 * 24 * 60 * 60),
                currentBill = nil,
                billDeadline = nil,
                unpaidBills = 0
            }
        end
        
        if not lab.billing.nextBillDate then
            lab.billing.nextBillDate = os.time() + (30 * 24 * 60 * 60)
        end
        
        if lab.employees then
            for empId, emp in pairs(lab.employees) do
                if not emp.inventory then
                    emp.inventory = {}
                end
            end
        end
    end
end)