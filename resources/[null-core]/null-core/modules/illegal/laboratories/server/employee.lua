createdEmployees = {} -- Global pour être accessible par employee_animations.lua
EmployeeCurrentTask = {}
local AllWhileForEmployee = {}
local EmployeeTasks = {}
local EmployeeTaskLocks = {}
local EmployeeFailedTasks = {} -- Track failed tasks to avoid spam

-- Helper function to add items to employee inventory
function AddItemToEmployeeInventory(labId, employeeId, itemName, count)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab or not lab.employees[employeeId] then return false end
    
    local employee = lab.employees[employeeId]
    if not employee.inventory then employee.inventory = {} end
    
    local found = false
    for k, v in pairs(employee.inventory) do
        if v.name == itemName then
            v.count = v.count + count
            found = true
            break
        end
    end
    
    if not found then
        table.insert(employee.inventory, {name = itemName, count = count})
    end
    
    return true
end

function PlayEmployeeIdleAnim(labId, employeeId, duration)
    local ped = createdEmployees[labId] and createdEmployees[labId][employeeId]
    if not ped or not DoesEntityExist(ped) then
        return
    end
    
    local employeeConfig = Config.laboratoire.employees[employeeId]
    if not employeeConfig or not employeeConfig.idleAnim then
        return
    end
    
    local dict = employeeConfig.idleAnim[1]
    local anim = employeeConfig.idleAnim[2]
    local pedNetId = NetworkGetNetworkIdFromEntity(ped)
    
    TriggerClientEvent("null:labo:playEmployeeIdleAnim", -1, pedNetId, dict, anim, duration)
    
    Wait(duration)
    ClearPedTasks(ped)
end


function EmployeeWaterPlant(labId, employeeId, plantId)
    if not SaveData.Illegal.WeedPlants[plantId] then
        if Config.laboratoire.debug then
            null.DebugPrint("[WATER FAIL] Plant", plantId, "does not exist")
        end
        return false
    end
    if SaveData.Illegal.WeedPlants[plantId].health == 0 then
        if Config.laboratoire.debug then
            null.DebugPrint("[WATER FAIL] Plant", plantId, "health = 0")
        end
        return false
    end
    
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    local storageId = "labo_coffre_big_"..labId
    local hasWater = false
    
    GetItemCountFromStorage(storageId, "water-canister", function(waterCount)
        if waterCount > 0 then
            hasWater = true
            RemoveItemToStorage(storageId, "water-canister", 1)
            if Config.laboratoire.debug then
                null.DebugPrint("[WATER SUCCESS] Employee", employeeId, "watered plant", plantId)
            end
            
            -- Ajouter l'eau à l'inventaire de l'employé temporairement
            if not lab.employees[employeeId].inventory then
                lab.employees[employeeId].inventory = {}
            end
            table.insert(lab.employees[employeeId].inventory, {name = "water-canister", count = 1})
            Cache.SaveOne("illegals")
            
            SaveData.Illegal.WeedPlants[plantId].water[#SaveData.Illegal.WeedPlants[plantId].water + 1] = os.time()
            MySQL.update('UPDATE weedplants SET water = (:water) WHERE id = (:id)', {
                ['water'] = json.encode(SaveData.Illegal.WeedPlants[plantId].water),
                ['id'] = plantId,
            })
            NotifyPlantDataToClients(plantId)
            
            -- Retirer l'eau de l'inventaire après utilisation
            Wait(100)
            for k, v in pairs(lab.employees[employeeId].inventory) do
                if v.name == "water-canister" then
                    table.remove(lab.employees[employeeId].inventory, k)
                    break
                end
            end
            Cache.SaveOne("illegals")
        else
            if Config.laboratoire.debug then
                null.DebugPrint("[WATER FAIL] No water-canister in storage (labo_coffre_big_"..labId..")")
            end
        end
    end)
    
    Wait(100)
    return hasWater
end

function EmployeeSeedPlant(labId, employeeId, plantId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab or not lab.employees[employeeId] then
        if Config.laboratoire.debug then
            null.DebugPrint("[SEED FAIL] Laboratory or employee does not exist")
        end
        return false
    end
    
    local plant = SaveData.Illegal.WeedPlants[plantId]
    if not plant then
        if Config.laboratoire.debug then
            null.DebugPrint("[SEED FAIL] Plant", plantId, "does not exist")
        end
        return false
    end
    
    -- Vérifier si la plante a besoin d'une graine (hasBase == 0 ou 2)
    -- hasBase: 0 = pot vide, 1 = graine DÉJÀ plantée (ne pas planter!), 2 = terre sans graine
    if plant.hasBase ~= 2 then
        if Config.laboratoire.debug then
            null.DebugPrint("[SEED FAIL] Plant", plantId, "hasBase =", plant.hasBase, "(expected 2 for seeding)")
        end
        return false
    end
    
    -- Vérifier si l'employé a une graine femelle dans le stockage
    local storageId = "labo_coffre_big_"..labId
    local hasSeed = false
    
    GetItemCountFromStorage(storageId, "weed-seed-female", function(seedCount)
        if seedCount > 0 then
            hasSeed = true
            RemoveItemToStorage(storageId, "weed-seed-female", 1)
            
            -- Planter la graine
            SaveData.Illegal.WeedPlants[plantId].hasBase = 1
            SaveData.Illegal.WeedPlants[plantId].time = os.time()
            
            MySQL.update('UPDATE weedplants SET hasBase = @hasBase, time = @time WHERE id = @id', {
                ['@hasBase'] = 1,
                ['@time'] = SaveData.Illegal.WeedPlants[plantId].time,
                ['@id'] = plantId,
            })
            
            NotifyPlantDataToClients(plantId)
        else
            if Config.laboratoire.debug then
                null.DebugPrint("[SEED FAIL] No weed-seed-female in storage (labo_coffre_big_"..labId..")")
            end
        end
    end)
    
    Wait(100)
    return hasSeed
end

function EmployeeFertilizePlant(labId, employeeId, plantId)
    if not SaveData.Illegal.WeedPlants[plantId] then
        if Config.laboratoire.debug then
            null.DebugPrint("[FERTILIZE FAIL] Plant", plantId, "does not exist")
        end
        return false
    end
    if SaveData.Illegal.WeedPlants[plantId].health == 0 then
        if Config.laboratoire.debug then
            null.DebugPrint("[FERTILIZE FAIL] Plant", plantId, "health = 0")
        end
        return false
    end
    
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    local storageId = "labo_coffre_big_"..labId
    local hasFertilizer = false
    
    GetItemCountFromStorage(storageId, "fertilizer", function(fertilizerCount)
        if fertilizerCount > 0 then
            hasFertilizer = true
            RemoveItemToStorage(storageId, "fertilizer", 1)
            
            -- Ajouter l'engrais à l'inventaire de l'employé temporairement
            if not lab.employees[employeeId].inventory then
                lab.employees[employeeId].inventory = {}
            end
            table.insert(lab.employees[employeeId].inventory, {name = "fertilizer", count = 1})
            Cache.SaveOne("illegals")
            
            SaveData.Illegal.WeedPlants[plantId].fertilizer[#SaveData.Illegal.WeedPlants[plantId].fertilizer + 1] = os.time()
            MySQL.update('UPDATE weedplants SET fertilizer = (:fertilizer) WHERE id = (:id)', {
                ['fertilizer'] = json.encode(SaveData.Illegal.WeedPlants[plantId].fertilizer),
                ['id'] = plantId,
            })
            NotifyPlantDataToClients(plantId)
            
            -- Retirer l'engrais de l'inventaire après utilisation
            Wait(100)
            for k, v in pairs(lab.employees[employeeId].inventory) do
                if v.name == "fertilizer" then
                    table.remove(lab.employees[employeeId].inventory, k)
                    break
                end
            end
            Cache.SaveOne("illegals")
        else
            if Config.laboratoire.debug then
                null.DebugPrint("[FERTILIZE FAIL] No fertilizer in storage (labo_coffre_big_"..labId..")")
            end
        end
    end)
    
    Wait(100)
    return hasFertilizer
end

function EmployeeHarvestPlant(labId, employeeId, plantId)
    if not SaveData.Illegal.WeedPlants[plantId] then
        if Config.laboratoire.debug then
            null.DebugPrint("[HARVEST FAIL] Plant", plantId, "does not exist")
        end
        return false
    end
    if SaveData.Illegal.WeedPlants[plantId].growth ~= 100 then
        if Config.laboratoire.debug then
            null.DebugPrint("[HARVEST FAIL] Plant", plantId, "growth =", SaveData.Illegal.WeedPlants[plantId].growth, "(expected 100)")
        end
        return false
    end
    if SaveData.Illegal.WeedPlants[plantId].health == 0 then
        if Config.laboratoire.debug then
            null.DebugPrint("[HARVEST FAIL] Plant", plantId, "health = 0")
        end
        return false
    end
    
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    local storageId = "labo_coffre_big_"..labId
    local hasdrugs_scissors = false
    
    -- Vérifier si l'employé a déjà des ciseaux dans son inventaire
    if not lab.employees[employeeId].inventory then
        lab.employees[employeeId].inventory = {}
    end
    
    local employeeHasdrugs_scissors = false
    for k, v in pairs(lab.employees[employeeId].inventory) do
        if v.name == "drugs_scissors" then
            employeeHasdrugs_scissors = true
            break
        end
    end
    
    -- Si l'employé n'a pas de ciseaux, en prendre dans le stockage
    if not employeeHasdrugs_scissors then
        GetItemCountFromStorage(storageId, "drugs_scissors", function(drugs_scissorsCount)
            if drugs_scissorsCount > 0 then
                hasdrugs_scissors = true
                -- Ajouter les ciseaux à l'inventaire de l'employé de façon permanente
                table.insert(lab.employees[employeeId].inventory, {name = "drugs_scissors", count = 1})
                Cache.SaveOne("illegals")
            else
                if Config.laboratoire.debug then
                    null.DebugPrint("[HARVEST FAIL] No drugs_scissors in storage (labo_coffre_big_"..labId..")")
                end
                return
            end
        end)
        Wait(100)
    else
        hasdrugs_scissors = true
    end
    
    if not hasdrugs_scissors then return false end
    
    local nbrweed = math.floor(SaveData.Illegal.WeedPlants[plantId].health / 20)
    if Config.laboratoire.debug then
        null.DebugPrint("[HARVEST] Plant", plantId, "health:", SaveData.Illegal.WeedPlants[plantId].health, "-> weed count:", nbrweed)
    end
    
    if nbrweed > 0 then
        local lab = SaveData.json["illegals"]["laboratorys"][labId]
        if not lab.employees[employeeId].inventory then
            lab.employees[employeeId].inventory = {}
        end
        
        local found = false
        for k, v in pairs(lab.employees[employeeId].inventory) do
            if v.name == "weed_plant" then
                v.count = v.count + nbrweed
                found = true
                break
            end
        end
        
        if not found then
            table.insert(lab.employees[employeeId].inventory, {
                name = "weed_plant",
                count = nbrweed
            })
        end
        
        Cache.SaveOne("illegals")
    end
    
    SaveData.Illegal.WeedPlants[plantId].time = os.time()
    SaveData.Illegal.WeedPlants[plantId].date = os.date('%Y-%m-%d %H:%M:%S', os.time())
    SaveData.Illegal.WeedPlants[plantId].water = {}
    SaveData.Illegal.WeedPlants[plantId].fertilizer = {}
    SaveData.Illegal.WeedPlants[plantId].displayfertilizer = 0
    SaveData.Illegal.WeedPlants[plantId].displaywater = 0
    SaveData.Illegal.WeedPlants[plantId].health = 100
    SaveData.Illegal.WeedPlants[plantId].growth = 0
    SaveData.Illegal.WeedPlants[plantId].stage = 0
    SaveData.Illegal.WeedPlants[plantId].hasBase = 2
    SaveData.Illegal.WeedPlants[plantId].gender = "female"
    
    MySQL.Async.execute('UPDATE weedplants SET water = @water, fertilizer = @fertilizer, hasBase = @hasBase, gender = @gender, time = @time WHERE id = @id', {
        ['@id'] = plantId,
        ['@water'] = json.encode({}),
        ['@fertilizer'] = json.encode({}),
        ['@hasBase'] = 2,
        ['@gender'] = "female",
        ['@time'] = SaveData.Illegal.WeedPlants[plantId].time,
    })
    NotifyPlantDataToClients(plantId)
    return true
end

function EmployeeDryWeed(labId, employeeId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab then return false end
    if not lab.upgrades["treatment-equipment"] then return false end
    
    local employee = lab.employees[employeeId]
    if not employee or not employee.inventory then return false end
    
    local weedCount = 0
    for k, v in pairs(employee.inventory) do
        if v.name == "weed_plant" and v.count > 0 then
            weedCount = v.count
            break
        end
    end
    
    if weedCount == 0 then 
        if Config.laboratoire.debug then
            null.DebugPrint("[DRY_WEED] No weed_plant in inventory")
        end
        return false 
    end
    
    local nbr = 0
    for k,v in pairs(lab.treatmentequipment.indrying) do nbr = nbr + 1 end
    local nbrMax = 0
    for k,v in pairs(Config.laboratoire.type["weed"].treatmentequipment.DryPlantsCoords) do nbrMax = nbrMax + 1 end
    if nbr >= nbrMax then 
        if Config.laboratoire.debug then
            null.DebugPrint("[DRY_WEED] Drying area full")
        end
        return false 
    end

    for k, v in pairs(employee.inventory) do
        if v.name == "weed_plant" and v.count > 0 then
            v.count = v.count - 1
            if v.count <= 0 then
                table.remove(employee.inventory, k)
            end
            break
        end
    end

    table.insert(lab.treatmentequipment.indrying, {
        name = "weed_plant",
        finish = false,
        timestart = os.time()
    })
    Cache.SaveOne("illegals")
    
    SetupLaboWeedDry(labId)
    for k,v in pairs(PeopleInLabo) do
        if v == labId then
            TriggerClientEvent("null:labo:updateindrying", -1, labId, lab.treatmentequipment.indrying)
        end
    end
    
    return true
end

function EmployeeCollectDryWeed(labId, employeeId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab then return false end
    if not lab.upgrades["treatment-equipment"] then return false end
    
    local collected = false
    for k,v in pairs(lab.treatmentequipment.indrying) do 
        if v.finish then
            lab.treatmentequipment.indrying[k] = nil
            
            local employee = lab.employees[employeeId]
            if not employee.inventory then
                employee.inventory = {}
            end

            local found = false
            for i, item in pairs(employee.inventory) do
                if item.name == "weed_plant_dry" then
                    item.count = item.count + 1
                    found = true
                    break
                end
            end
            
            if not found then
                table.insert(employee.inventory, {
                    name = "weed_plant_dry",
                    count = 1
                })
            end
            
            Cache.SaveOne("illegals")
            
            collected = true
            break
        end
    end
    
    if collected then
        SetupLaboWeedDry(labId)
        for k,v in pairs(PeopleInLabo) do
            if v == labId then
                TriggerClientEvent("null:labo:updateindrying", -1, labId, lab.treatmentequipment.indrying)
            end
        end
    end
    
    return collected
end

function EmployeeDepositFreshWeed(labId, employeeId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab then return false end
    
    local employee = lab.employees[employeeId]
    if not employee or not employee.inventory then return false end
    
    local freshWeedCount = 0
    local itemIndex = nil
    for k, v in pairs(employee.inventory) do
        if v.name == "weed_plant" and v.count > 0 then
            freshWeedCount = v.count
            itemIndex = k
            break
        end
    end
    
    if freshWeedCount == 0 then return false end
    
    AddItemToStorage("labo_coffre_big_"..labId, "weed_plant", freshWeedCount)
    table.remove(employee.inventory, itemIndex)
    Cache.SaveOne("illegals")

    return true
end

function EmployeeDepositDryWeed(labId, employeeId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab then return false end
    
    local employee = lab.employees[employeeId]
    if not employee or not employee.inventory then return false end
    
    local dryWeedCount = 0
    local itemIndex = nil
    for k, v in pairs(employee.inventory) do
        if v.name == "weed_plant_dry" and v.count > 0 then
            dryWeedCount = v.count
            itemIndex = k
            break
        end
    end
    
    if dryWeedCount == 0 then return false end
    
    AddItemToStorage("labo_coffre_big_"..labId, "weed_plant_dry", dryWeedCount)
    table.remove(employee.inventory, itemIndex)
    Cache.SaveOne("illegals")
    
    return true
end

-- Récupérer weed frais du stockage pour le mettre à sécher
function EmployeeGetFreshWeedForDrying(labId, employeeId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab then return false end
    
    local employee = lab.employees[employeeId]
    if not employee then return false end
    
    local storageId = "labo_coffre_big_"..labId
    
    -- Vérifier si le stockage a du weed frais
    local hasFreshWeed = false
    GetItemCountFromStorage(storageId, "weed_plant", function(freshWeedCount)
        if freshWeedCount > 0 then
            hasFreshWeed = true
        end
    end)
    Wait(100)
    
    if not hasFreshWeed then
        if Config.laboratoire.debug then
            null.DebugPrint("[GET_FRESH_FOR_DRY] No fresh weed in storage")
        end
        return false
    end
    
    -- Retirer du stockage
    RemoveItemToStorage(storageId, "weed_plant", 1)
    Wait(100)
    
    -- Ajouter à l'inventaire de l'employé
    if not employee.inventory then
        employee.inventory = {}
    end
    
    local found = false
    for k, v in pairs(employee.inventory) do
        if v.name == "weed_plant" then
            v.count = v.count + 1
            found = true
            break
        end
    end
    
    if not found then
        table.insert(employee.inventory, {
            name = "weed_plant",
            count = 1
        })
    end
    
    Cache.SaveOne("illegals")
    
    if Config.laboratoire.debug then
        null.DebugPrint("[GET_FRESH_FOR_DRY] Employee "..employeeId.." got 1 fresh weed from storage")
    end
    
    return true
end

function EmployeeTreatWeed(labId, employeeId, callback)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab then 
        if callback then callback(false) end
        return 
    end
    if not lab.upgrades["treatment-equipment"] then 
        if callback then callback(false) end
        return 
    end
    
    local storageId = "labo_coffre_big_"..labId
    
    GetItemCountFromStorage(storageId, "weed_plant_dry", function(dryWeedCount)
        if dryWeedCount < 1 then 
            if callback then callback(false) end
            return 
        end
        
        local number = 0
        if lab.upgrades["uv-light"] then
            number = math.random(25, 70)
        else
            number = math.random(15, 30)
        end
        
        GetItemCountFromStorage(storageId, Config.laboratoire.items["pooch"], function(emptyPouchCount)
            if emptyPouchCount < number then 
                if callback then callback(false) end
                return 
            end
            
            RemoveItemToStorage(storageId, "weed_plant_dry", 1)
            RemoveItemToStorage(storageId, Config.laboratoire.items["pooch"], number)
            AddItemToStorage(storageId, "weed_pooch", number)
            
            if lab.upgrades["security"] then
                table.insert(lab.History["treatment"], {
                    idunique = "EMPLOYEE_"..employeeId,
                    name = "Employé "..employeeId,
                    firstname = "Employé",
                    lastname = employeeId,
                    time = os.date("%Y-%m-%d %H:%M:%S"),
                    ostime = os.time()
                })
                TriggerClientEvent("null:labo:history", -1, labId, lab.History)
            end
            
            if callback then callback(true) end
        end)
    end)
end

-- ========== METH EMPLOYEE TASK FUNCTIONS ==========

function EmployeeMethFillCuve(labId, employeeId, cuveId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab or lab.type ~= "meth" then return false end
    
    local cuve = lab.treatementmeth.cuves[cuveId]
    if not cuve or (cuve.state ~= "idle" and cuve.state ~= "adding_ingredients") then return false end
    
    local storageId = "labo_coffre_big_"..labId
    local cuveConf = Config.laboratoire.type["meth"].cuveConfig
    local items = Config.laboratoire.type["meth"].items
    
    -- Add each missing ingredient
    for _, ingredientKey in ipairs(cuveConf.ingredients) do
        local alreadyAdded = false
        for _, v in ipairs(cuve.ingredients or {}) do
            if v == ingredientKey then alreadyAdded = true break end
        end
        
        if not alreadyAdded then
            local itemName = items[ingredientKey]
            local hasItem = false
            
            GetItemCountFromStorage(storageId, itemName, function(count)
                if count > 0 then hasItem = true end
            end)
            Wait(100)
            
            if not hasItem then
                if Config.laboratoire.debug then
                    null.DebugPrint("[METH TASK] No "..itemName.." in storage for cuve "..cuveId)
                end
                return false
            end
            
            RemoveItemToStorage(storageId, itemName, 1)
            Wait(100)
            
            if cuve.ingredients == nil then cuve.ingredients = {} end
            table.insert(cuve.ingredients, ingredientKey)
            cuve.state = "adding_ingredients"
        end
    end
    
    -- Check if all ingredients are in
    if #cuve.ingredients >= #cuveConf.ingredients then
        cuve.state = "mixing"
        cuve.mixStartTime = os.time()
    end
    
    SyncCuveToClients(labId)
    Cache.SaveOne("illegals")
    
    if Config.laboratoire.debug then
        null.DebugPrint("[METH TASK] Employee "..employeeId.." filled cuve "..cuveId.." (state: "..cuve.state..")")
    end
    return true
end

function EmployeeMethAddSolvant(labId, employeeId, cuveId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab or lab.type ~= "meth" then return false end
    
    local cuve = lab.treatementmeth.cuves[cuveId]
    if not cuve or cuve.state ~= "waiting_solvant" then return false end
    
    local storageId = "labo_coffre_big_"..labId
    local solvantItem = Config.laboratoire.type["meth"].items["solvant"]
    local hasItem = false
    
    GetItemCountFromStorage(storageId, solvantItem, function(count)
        if count > 0 then hasItem = true end
    end)
    Wait(100)
    
    if not hasItem then
        if Config.laboratoire.debug then
            null.DebugPrint("[METH TASK] No solvant in storage for cuve "..cuveId)
        end
        return false
    end
    
    RemoveItemToStorage(storageId, solvantItem, 1)
    Wait(100)
    
    cuve.state = "mixing_solvant"
    cuve.solvantMixStartTime = os.time()
    
    SyncCuveToClients(labId)
    Cache.SaveOne("illegals")
    
    if Config.laboratoire.debug then
        null.DebugPrint("[METH TASK] Employee "..employeeId.." added solvant to cuve "..cuveId)
    end
    return true
end

function EmployeeMethCollectTray(labId, employeeId, cuveId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab or lab.type ~= "meth" then return false end
    
    local cuve = lab.treatementmeth.cuves[cuveId]
    if not cuve or cuve.state ~= "ready" or (cuve.traysRemaining or 0) <= 0 then return false end
    
    local employee = lab.employees[employeeId]
    if not employee then return false end
    if not employee.inventory then employee.inventory = {} end
    
    local mixtureItem = Config.laboratoire.type["meth"].items["mixture"]
    cuve.traysRemaining = cuve.traysRemaining - 1
    
    if cuve.traysRemaining <= 0 then
        cuve.state = "idle"
        cuve.ingredients = {}
        cuve.traysRemaining = 0
    end
    
    -- Add to employee inventory
    local found = false
    for k, v in pairs(employee.inventory) do
        if v.name == mixtureItem then
            v.count = v.count + 1
            found = true
            break
        end
    end
    if not found then
        table.insert(employee.inventory, {name = mixtureItem, count = 1})
    end
    
    SyncCuveToClients(labId)
    Cache.SaveOne("illegals")
    
    if Config.laboratoire.debug then
        null.DebugPrint("[METH TASK] Employee "..employeeId.." collected tray from cuve "..cuveId.." (remaining: "..(cuve.traysRemaining or 0)..")")
    end
    return true
end

function EmployeeMethLoadFour(labId, employeeId, fourId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab or lab.type ~= "meth" then return false end
    
    local fourData = lab.treatementmeth.fours[fourId]
    if not fourData then return false end
    if fourData.inFour == nil then fourData.inFour = {} end
    
    local nbr = 0
    for k,v in pairs(fourData.inFour) do nbr = nbr + 1 end
    if nbr >= Config.laboratoire.type["meth"].fours[fourId].numberMax then return false end
    
    local employee = lab.employees[employeeId]
    if not employee or not employee.inventory then return false end
    
    local mixtureItem = Config.laboratoire.type["meth"].items["mixture"]
    local itemIndex = nil
    for k, v in pairs(employee.inventory) do
        if v.name == mixtureItem and v.count > 0 then
            itemIndex = k
            break
        end
    end
    
    if not itemIndex then return false end
    
    employee.inventory[itemIndex].count = employee.inventory[itemIndex].count - 1
    if employee.inventory[itemIndex].count <= 0 then
        table.remove(employee.inventory, itemIndex)
    end
    
    table.insert(fourData.inFour, {
        name = mixtureItem,
        finish = false,
        timestart = os.time()
    })
    
    for k,v in pairs(PeopleInLabo) do
        if v == labId then
            TriggerClientEvent("null:labo:updatefour", -1, labId, lab.treatementmeth.fours)
        end
    end
    
    Cache.SaveOne("illegals")
    
    if Config.laboratoire.debug then
        null.DebugPrint("[METH TASK] Employee "..employeeId.." loaded four "..fourId)
    end
    return true
end

function EmployeeMethUnloadFour(labId, employeeId, fourId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab or lab.type ~= "meth" then return false end
    
    local fourData = lab.treatementmeth.fours[fourId]
    if not fourData or not fourData.inFour then return false end
    
    local employee = lab.employees[employeeId]
    if not employee then return false end
    if not employee.inventory then employee.inventory = {} end
    
    local collected = false
    for k, v in pairs(fourData.inFour) do
        if v.finish then
            fourData.inFour[k] = nil
            collected = true
            break
        end
    end
    
    if not collected then return false end
    
    local methBruteItem = Config.laboratoire.type["meth"].items["meth_tray"]
    local found = false
    for k, v in pairs(employee.inventory) do
        if v.name == methBruteItem then
            v.count = v.count + 1
            found = true
            break
        end
    end
    if not found then
        table.insert(employee.inventory, {name = methBruteItem, count = 1})
    end
    
    for k,v in pairs(PeopleInLabo) do
        if v == labId then
            TriggerClientEvent("null:labo:updatefour", -1, labId, lab.treatementmeth.fours)
        end
    end
    
    Cache.SaveOne("illegals")
    
    if Config.laboratoire.debug then
        null.DebugPrint("[METH TASK] Employee "..employeeId.." unloaded four "..fourId)
    end
    return true
end

function EmployeeMethDepositStorage(labId, employeeId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab then return false end
    
    local employee = lab.employees[employeeId]
    if not employee or not employee.inventory then return false end
    
    local methBruteItem = Config.laboratoire.type["meth"].items["meth_tray"]
    local deposited = false
    
    for k, v in pairs(employee.inventory) do
        if v.name == methBruteItem and v.count > 0 then
            AddItemToStorage("labo_coffre_big_"..labId, methBruteItem, v.count)
            table.remove(employee.inventory, k)
            deposited = true
            break
        end
    end
    
    if deposited then
        Cache.SaveOne("illegals")
        if Config.laboratoire.debug then
            null.DebugPrint("[METH TASK] Employee "..employeeId.." deposited meth brute to storage")
        end
    end
    return deposited
end

-- Break meth tray AND pack into pooch in one action (like player at breakpoint table)
-- This combines: break tray (creates 8 crystals) + pack crystals into pooch = 1 meth_pooch
function EmployeeMethBreakTray(labId, employeeId, breakId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab or lab.type ~= "meth" then return false end
    
    local employee = lab.employees[employeeId]
    if not employee then return false end
    
    local methBruteItem = Config.laboratoire.type["meth"].items["meth_tray"]
    local poochItem = Config.laboratoire.items["pooch"]
    local finalProductItem = Config.laboratoire.type["meth"].items["traitement"]
    local storageId = "labo_coffre_big_"..labId
    
    -- Ensure employee has inventory table
    if not employee.inventory then employee.inventory = {} end
    
    -- Step 1: Get tray (from employee inventory OR storage)
    local hasTray = false
    local trayFromStorage = false
    
    -- Check employee inventory first
    for k, v in pairs(employee.inventory) do
        if v.name == methBruteItem and v.count > 0 then
            hasTray = true
            v.count = v.count - 1
            if v.count <= 0 then
                table.remove(employee.inventory, k)
            end
            break
        end
    end
    
    -- If no tray in inventory, try to get from storage
    if not hasTray then
        local trayCount = 0
        GetItemCountFromStorage(storageId, methBruteItem, function(count)
            trayCount = count
        end)
        Wait(100)
        
        if trayCount > 0 then
            RemoveItemToStorage(storageId, methBruteItem, 1)
            trayFromStorage = true
            hasTray = true
        end
    end
    
    if not hasTray then
        if Config.laboratoire.debug then
            null.DebugPrint("[METH TASK] Employee "..employeeId.." has no meth tray to break")
        end
        return false
    end
    
    -- Step 2: Get pooch (from employee inventory OR storage)
    local hasPooch = false
    local poochFromStorage = false
    
    -- Check employee inventory first
    for k, v in pairs(employee.inventory) do
        if v.name == poochItem and v.count > 0 then
            hasPooch = true
            v.count = v.count - 1
            if v.count <= 0 then
                table.remove(employee.inventory, k)
            end
            break
        end
    end
    
    -- If no pooch in inventory, try to get from storage
    if not hasPooch then
        local poochCount = 0
        GetItemCountFromStorage(storageId, poochItem, function(count)
            poochCount = count
        end)
        Wait(100)
        
        if poochCount > 0 then
            RemoveItemToStorage(storageId, poochItem, 1)
            poochFromStorage = true
            hasPooch = true
        end
    end
    
    -- If no pooch available, restore tray and fail
    if not hasPooch then
        -- Restore tray to storage if we took it
        if trayFromStorage then
            AddItemToStorage(storageId, methBruteItem, 1)
        else
            -- Return tray to employee inventory
            AddItemToEmployeeInventory(labId, employeeId, methBruteItem, 1)
        end
        if Config.laboratoire.debug then
            null.DebugPrint("[METH TASK] Employee "..employeeId.." no pooch available for packing")
        end
        return false
    end
    
    -- Step 3: Break tray (1 tray = 8 crystals) and immediately pack into pooch
    -- This happens in ONE action at the breakpoint table
    -- Result: 1 meth_pooch added to storage
    AddItemToStorage(storageId, finalProductItem, 1)
    
    Cache.SaveOne("illegals")
    
    if Config.laboratoire.debug then
        null.DebugPrint("[METH TASK] Employee "..employeeId.." broke tray and packed meth into pooch at breakpoint "..breakId)
    end
    
    return true
end

-- Pack meth crystals into pooches (final step)
function EmployeeMethPackPooch(labId, employeeId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab or lab.type ~= "meth" then return false end
    
    local employee = lab.employees[employeeId]
    if not employee or not employee.inventory then return false end
    
    local poochItem = Config.laboratoire.items["pooch"]
    local methCrystalItem = Config.laboratoire.type["meth"].items["crystal"] or "meth_crystal"
    local finalProductItem = Config.laboratoire.type["meth"].items["traitement"]
    
    -- Check if employee has crystals and pooch
    local hasCrystals = false
    local hasPooch = false
    
    for k, v in pairs(employee.inventory) do
        if v.name == methCrystalItem and v.count >= 8 then
            hasCrystals = true
        end
        if v.name == poochItem and v.count > 0 then
            hasPooch = true
        end
    end
    
    -- If no crystals in inventory, check storage
    local crystalsFromStorage = false
    if not hasCrystals then
        local storageId = "labo_coffre_big_"..labId
        local crystalCount = 0
        GetItemCountFromStorage(storageId, methCrystalItem, function(count)
            crystalCount = count
        end)
        Wait(100)
        
        if crystalCount >= 8 then
            -- Take crystals from storage
            RemoveItemToStorage(storageId, methCrystalItem, 8)
            crystalsFromStorage = true
            hasCrystals = true
        end
    else
        -- Remove crystals from employee inventory
        for k, v in pairs(employee.inventory) do
            if v.name == methCrystalItem and v.count >= 8 then
                v.count = v.count - 8
                if v.count <= 0 then
                    table.remove(employee.inventory, k)
                end
                break
            end
        end
    end
    
    -- If no pooch in inventory, get from storage
    local poochFromStorage = false
    if not hasPooch then
        local storageId = "labo_coffre_big_"..labId
        local poochCount = 0
        GetItemCountFromStorage(storageId, poochItem, function(count)
            poochCount = count
        end)
        Wait(100)
        
        if poochCount > 0 then
            RemoveItemToStorage(storageId, poochItem, 1)
            poochFromStorage = true
            hasPooch = true
        end
    else
        -- Remove pooch from employee inventory
        for k, v in pairs(employee.inventory) do
            if v.name == poochItem and v.count > 0 then
                v.count = v.count - 1
                if v.count <= 0 then
                    table.remove(employee.inventory, k)
                end
                break
            end
        end
    end
    
    if not hasCrystals or not hasPooch then
        -- Restore items to storage if we took them
        if crystalsFromStorage then
            AddItemToStorage("labo_coffre_big_"..labId, methCrystalItem, 8)
        end
        if poochFromStorage then
            AddItemToStorage("labo_coffre_big_"..labId, poochItem, 1)
        end
        return false
    end
    
    -- Add final product to storage
    AddItemToStorage("labo_coffre_big_"..labId, finalProductItem, 1)
    
    Cache.SaveOne("illegals")
    
    if Config.laboratoire.debug then
        null.DebugPrint("[METH TASK] Employee "..employeeId.." packed meth into pooch")
    end
    
    return true
end

-- ========== METH TASK ASSIGNMENT ==========

local function GetNextTaskMeth(labId, employeeId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab or lab.type ~= "meth" then return nil end
    
    local employee = lab.employees[employeeId]
    if employee and employee.fatigue and employee.fatigue >= 100 then
        return nil
    end
    
    local employeeConfig = Config.laboratoire.employees[employeeId]
    if not employeeConfig or not employeeConfig.allowedTasks then
        return nil
    end
    
    local function isTaskAllowed(taskType)
        for _, allowedTask in ipairs(employeeConfig.allowedTasks) do
            if allowedTask == taskType then return true end
        end
        return false
    end
    
    local methBruteItem = Config.laboratoire.type["meth"].items["meth_tray"]
    local mixtureItem = Config.laboratoire.type["meth"].items["mixture"]
    local poochItem = Config.laboratoire.items["pooch"]
    local finalProductItem = Config.laboratoire.type["meth"].items["traitement"]
    
    -- ========== HIGHEST PRIORITY: BREAK TRAY + PACK POOCH (combined action) ==========
    -- Priority 1: Break meth trays and pack into pooches in one action at breakpoint
    if isTaskAllowed("meth_break_tray") then
        -- Check if employee has trays to break (inventory or storage)
        local hasTrays = false
        local traySource = nil
        
        for k, v in pairs(employee.inventory) do
            if v.name == methBruteItem and v.count > 0 then
                hasTrays = true
                traySource = "inventory"
                break
            end
        end
        
        -- Also check storage for trays
        if not hasTrays then
            local storageId = "labo_coffre_big_"..labId
            local trayCount = 0
            GetItemCountFromStorage(storageId, methBruteItem, function(count)
                trayCount = count
            end)
            Wait(50)
            
            if trayCount > 0 then
                hasTrays = true
                traySource = "storage"
            end
        end
        
        -- Check if pooches available (inventory or storage)
        local hasPooch = false
        
        for k, v in pairs(employee.inventory) do
            if v.name == poochItem and v.count > 0 then
                hasPooch = true
                break
            end
        end
        
        if not hasPooch then
            local storageId = "labo_coffre_big_"..labId
            local poochCount = 0
            GetItemCountFromStorage(storageId, poochItem, function(count)
                poochCount = count
            end)
            Wait(50)
            
            if poochCount > 0 then
                hasPooch = true
            end
        end
        
        -- Only assign break_tray task if both tray AND pooch are available
        if hasTrays and hasPooch then
            -- Find available breakpoint
            for breakId, breakConf in pairs(Config.laboratoire.type["meth"].breakpoints) do
                local taskKey = labId.."_meth_break_tray_"..breakId
                if not EmployeeTaskLocks[taskKey] then
                    EmployeeTaskLocks[taskKey] = employeeId
                    if Config.laboratoire.debug then
                        null.DebugPrint("[METH TASK] Employee", employeeId, "assigned BREAK_TRAY (tray from "..(traySource or "unknown")..") at breakpoint", breakId)
                    end
                    return {type = "meth_break_tray", breakId = breakId, taskKey = taskKey}
                end
            end
        elseif hasTrays and not hasPooch then
            if Config.laboratoire.debug then
                null.DebugPrint("[METH TASK] Employee", employeeId, "has trays but NO POUCHES available - cannot pack")
            end
        end
    end
    
    -- Priority 2: Deposit meth_tray from inventory to storage (if no pooches to pack)
    if employee and employee.inventory and isTaskAllowed("meth_deposit_storage") then
        for k, v in pairs(employee.inventory) do
            if v.name == methBruteItem and v.count > 0 then
                return {type = "meth_deposit_storage"}
            end
        end
    end
    
    -- Priority 2: Load mixture from inventory into a four
    if employee and employee.inventory and isTaskAllowed("meth_load_four") then
        for k, v in pairs(employee.inventory) do
            if v.name == mixtureItem and v.count > 0 then
                -- Find a four with available space
                for fourId, fourConf in pairs(Config.laboratoire.type["meth"].fours) do
                    local fourData = lab.treatementmeth.fours[fourId]
                    if fourData then
                        if fourData.inFour == nil then fourData.inFour = {} end
                        local nbr = 0
                        for _ in pairs(fourData.inFour) do nbr = nbr + 1 end
                        if nbr < fourConf.numberMax then
                            local taskKey = labId.."_meth_load_four_"..fourId
                            if not EmployeeTaskLocks[taskKey] then
                                EmployeeTaskLocks[taskKey] = employeeId
                                return {type = "meth_load_four", fourId = fourId, taskKey = taskKey}
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Priority 3: Unload finished items from fours
    if isTaskAllowed("meth_unload_four") then
        for fourId, fourData in pairs(lab.treatementmeth.fours) do
            if fourData and fourData.inFour then
                for k, v in pairs(fourData.inFour) do
                    if v.finish then
                        local taskKey = labId.."_meth_unload_four_"..fourId
                        if not EmployeeTaskLocks[taskKey] then
                            EmployeeTaskLocks[taskKey] = employeeId
                            return {type = "meth_unload_four", fourId = fourId, taskKey = taskKey}
                        end
                    end
                end
            end
        end
    end
    
    -- Priority 4: Collect trays from ready cuves
    if isTaskAllowed("meth_collect_tray") then
        for cuveId, cuveData in pairs(lab.treatementmeth.cuves) do
            if cuveData.state == "ready" and (cuveData.traysRemaining or 0) > 0 then
                local taskKey = labId.."_meth_collect_tray_"..cuveId
                if not EmployeeTaskLocks[taskKey] then
                    EmployeeTaskLocks[taskKey] = employeeId
                    return {type = "meth_collect_tray", cuveId = cuveId, taskKey = taskKey}
                end
            end
        end
    end
    
    -- Priority 5: Add solvant to waiting cuves
    if isTaskAllowed("meth_add_solvant") then
        for cuveId, cuveData in pairs(lab.treatementmeth.cuves) do
            if cuveData.state == "waiting_solvant" then
                local taskKey = labId.."_meth_add_solvant_"..cuveId
                if not EmployeeTaskLocks[taskKey] then
                    EmployeeTaskLocks[taskKey] = employeeId
                    return {type = "meth_add_solvant", cuveId = cuveId, taskKey = taskKey}
                end
            end
        end
    end
    
    -- Priority 6: Fill idle cuves with ingredients
    if isTaskAllowed("meth_fill_cuve") then
        for cuveId, cuveData in pairs(lab.treatementmeth.cuves) do
            if cuveData.state == "idle" or cuveData.state == "adding_ingredients" then
                local taskKey = labId.."_meth_fill_cuve_"..cuveId
                if not EmployeeTaskLocks[taskKey] then
                    EmployeeTaskLocks[taskKey] = employeeId
                    return {type = "meth_fill_cuve", cuveId = cuveId, taskKey = taskKey}
                end
            end
        end
    end
    
    if Config.laboratoire.debug then
        null.DebugPrint("[METH TASK] Employee", employeeId, "no task found - will rest")
    end
    return nil
end

local function GetNextTask(labId, employeeId)
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab or lab.type ~= "weed" then return nil end
    
    -- Vérifier la fatigue de l'employé
    local employee = lab.employees[employeeId]
    if employee and employee.fatigue and employee.fatigue >= 100 then
        return nil
    end
    
    -- Récupérer la config de l'employé pour vérifier sa spécialisation
    local employeeConfig = Config.laboratoire.employees[employeeId]
    if not employeeConfig or not employeeConfig.allowedTasks then        
        if Config.laboratoire.debug then
            null.DebugPrint("[TASK] Employee", employeeId, "has no specialization config")
        end
        return nil
    end
    
    -- Fonction helper pour vérifier si une tâche est autorisée
    local function isTaskAllowed(taskType)
        for _, allowedTask in ipairs(employeeConfig.allowedTasks) do
            if allowedTask == taskType then
                return true
            end
        end
        return false
    end
    
    local plants = GetLabPlants(labId)
    --null.DebugPrint("[TASK] Employee", employeeId, "checking", #plants, "plants for tasks (specialization:", employeeConfig.specialization, ")")
    
    for _, plant in ipairs(plants) do
        local taskKey = labId .. "_" .. plant.id
        if not EmployeeTaskLocks[taskKey] then
            local stats = CalculatePlantStats(plant.id)
            local plantData = SaveData.Illegal.WeedPlants[plant.id]
            
            if stats then
                if stats.stage == 5 and stats.growth >= 100 and isTaskAllowed("harvest") then
                    local harvestKey = labId.."_"..employeeId.."_harvest_"..plant.id
                    if not EmployeeFailedTasks[harvestKey] or (os.time() - EmployeeFailedTasks[harvestKey]) > 60 then
                        EmployeeTaskLocks[taskKey] = employeeId
                        if Config.laboratoire.debug then
                            null.DebugPrint("[TASK] Employee", employeeId, "assigned HARVEST plant", plant.id)
                        end
                        return {type = "harvest", plantId = plant.id, taskKey = taskKey}
                    end
                elseif stats.water < 30 and isTaskAllowed("water") then
                    local waterKey = labId.."_"..employeeId.."_water_"..plant.id
                    if not EmployeeFailedTasks[waterKey] or (os.time() - EmployeeFailedTasks[waterKey]) > 60 then
                        EmployeeTaskLocks[taskKey] = employeeId
                        if Config.laboratoire.debug then
                            null.DebugPrint("[TASK] Employee", employeeId, "assigned WATER plant", plant.id)
                        end
                        return {type = "water", plantId = plant.id, taskKey = taskKey}
                    end
                elseif stats.fertilizer < 30 and isTaskAllowed("fertilize") then
                    local fertilizeKey = labId.."_"..employeeId.."_fertilize_"..plant.id
                    if not EmployeeFailedTasks[fertilizeKey] or (os.time() - EmployeeFailedTasks[fertilizeKey]) > 60 then
                        EmployeeTaskLocks[taskKey] = employeeId
                        if Config.laboratoire.debug then
                            null.DebugPrint("[TASK] Employee", employeeId, "assigned FERTILIZE plant", plant.id)
                        end
                        return {type = "fertilize", plantId = plant.id, taskKey = taskKey}
                    end
                end
                
                -- Vérifier si la plante a besoin d'une graine femelle (hasBase == 0 ou 2)
                if plantData and (plantData.hasBase == 0 or plantData.hasBase == 2) and isTaskAllowed("seed") then
                    local seedKey = labId.."_"..employeeId.."_seed_"..plant.id
                    if not EmployeeFailedTasks[seedKey] or (os.time() - EmployeeFailedTasks[seedKey]) > 60 then
                        EmployeeTaskLocks[taskKey] = employeeId
                        if Config.laboratoire.debug then
                            null.DebugPrint("[TASK] Employee", employeeId, "assigned SEED plant", plant.id, "(hasBase:", plantData.hasBase, ")")
                        end
                        return {type = "seed", plantId = plant.id, taskKey = taskKey}
                    end
                end
            end
        end
    end
    
    local employee = lab.employees[employeeId]
    if employee and employee.inventory then
        -- Priorité 1: Déposer les weed_plant fraîches si production a plus de 20
        for k, v in pairs(employee.inventory) do
            if v.name == "weed_plant" and v.count > 20 and isTaskAllowed("deposit_fresh") then
                if Config.laboratoire.debug then
                    null.DebugPrint("[TASK] Employee", employeeId, "has", v.count, "weed_plant, needs to deposit")
                end
                return {type = "deposit_fresh"}
            end
        end
        
        -- Priorité 2: Sécher les weed_plant si employé de séchage
        for k, v in pairs(employee.inventory) do
            if v.name == "weed_plant" and v.count > 0 and isTaskAllowed("dry_weed") then
                local nbr = 0
                for k2,v2 in pairs(lab.treatmentequipment.indrying) do nbr = nbr + 1 end
                local nbrMax = 0
                for k2,v2 in pairs(Config.laboratoire.type["weed"].treatmentequipment.DryPlantsCoords) do nbrMax = nbrMax + 1 end
                if nbr < nbrMax then
                    return {type = "dry_weed"}
                else
                    return nil
                end
            end
        end
        
        -- Priorité 3: Déposer les weed_plant_dry
        for k, v in pairs(employee.inventory) do
            if v.name == "weed_plant_dry" and v.count > 0 and isTaskAllowed("deposit_dry") then
                return {type = "deposit_dry"}
            end
        end
    end
    
    if lab.treatmentequipment and lab.treatmentequipment.indrying and isTaskAllowed("collect_dry") then
        for k,v in pairs(lab.treatmentequipment.indrying) do 
            if v.finish then
                return {type = "collect_dry"}
            end
        end
    end
    
    -- Priorité: Récupérer weed frais au stockage pour séchage (si zone de séchage a de la place)
    if isTaskAllowed("dry_weed") and isTaskAllowed("collect_dry") then
        -- Vérifier s'il y a de la place dans la zone de séchage
        local nbr = 0
        local nbrMax = 0
        if lab.treatmentequipment and lab.treatmentequipment.indrying then
            for k,v in pairs(lab.treatmentequipment.indrying) do nbr = nbr + 1 end
        end
        if Config.laboratoire.type["weed"].treatmentequipment.DryPlantsCoords then
            for k,v in pairs(Config.laboratoire.type["weed"].treatmentequipment.DryPlantsCoords) do nbrMax = nbrMax + 1 end
        end
        
        if nbr < nbrMax then
            -- Vérifier si le coffre a des weed_plant fraîches
            local storageId = "labo_coffre_big_"..labId
            local hasFreshWeed = false
            
            GetItemCountFromStorage(storageId, "weed_plant", function(freshWeedCount)
                if freshWeedCount > 0 then
                    hasFreshWeed = true
                end
            end)
            
            Wait(50)
            
            if hasFreshWeed then
                return {type = "get_fresh_for_dry"}
            end
        end
    end
    
    -- Vérifier s'il y a de la weed séchée à traiter (uniquement pour spécialisation treatment)
    if isTaskAllowed("treat_weed") then
        local storageId = "labo_coffre_big_"..labId
        local hasDryWeed = false
        local hasPouches = false
        
        GetItemCountFromStorage(storageId, "weed_plant_dry", function(dryWeedCount)
            if dryWeedCount > 0 then
                hasDryWeed = true
            end
        end)
        
        Wait(50)
        
        if hasDryWeed then
            GetItemCountFromStorage(storageId, Config.laboratoire.items["pooch"], function(emptyPouchCount)
                if emptyPouchCount >= 15 then
                    hasPouches = true
                else
                    null.DebugPrint("[TASK] Storage has only", emptyPouchCount, "empty pouches (< 15)")
                end
            end)
            Wait(50)
            
            if hasPouches then
                -- Find available treatment table (cut position)
                local cuts = Config.laboratoire.type["weed"].treatmentequipment.cuts
                for cutId, cutData in pairs(cuts) do
                    local taskKey = labId.."_treat_weed_"..cutId
                    if not EmployeeTaskLocks[taskKey] then
                        EmployeeTaskLocks[taskKey] = employeeId
                        if Config.laboratoire.debug then
                            null.DebugPrint("[TASK] Employee", employeeId, "assigned TREAT_WEED at table", cutId)
                        end
                        return {type = "treat_weed", cutId = cutId, taskKey = taskKey}
                    end
                end
            end
        end
    end
    
    if Config.laboratoire.debug then
        null.DebugPrint("[TASK] Employee", employeeId, "no task found - will rest")
    end
    return nil
end

local function ReleaseTaskLock(taskKey)
    if taskKey then
        EmployeeTaskLocks[taskKey] = nil
    end
end

function EmployeeAI(labId, employeeId)
    Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
        while AllWhileForEmployee[labId] and AllWhileForEmployee[labId][employeeId] do
            local lab = SaveData.json["illegals"]["laboratorys"][labId]
            if not lab or not lab.employees[employeeId] or lab.employees[employeeId].getPayed == false then
                break
            end
            
            local task = GetNextTask(labId, employeeId)
            
            if task then
                if not EmployeeCurrentTask[labId] then
                    EmployeeCurrentTask[labId] = {}
                end
                EmployeeCurrentTask[labId][employeeId] = task
                
                if not lab.employees[employeeId].fatigue then
                    lab.employees[employeeId].fatigue = 0
                end 

                local success = false
                local taskConfig = Config.EmployeeTasks[task.type] or {}
                
                -- Récupérer le multiplicateur de fatigue de l'employé
                local employeeConfig = Config.laboratoire.employees[employeeId]
                local fatigueMultiplier = (employeeConfig and employeeConfig.fatigueMultiplier) or 1.0
                
                if task.type == "water" then
                    ServerEmployeeAnimWaterFertilize(labId, employeeId, task.plantId, "water")
                    success = EmployeeWaterPlant(labId, employeeId, task.plantId)
                    if success then
                        local fatigue = math.floor((taskConfig.fatigueNeeded or 4) * fatigueMultiplier)
                        lab.employees[employeeId].fatigue = math.min(100, lab.employees[employeeId].fatigue + fatigue)
                    else
                        local failKey = labId.."_"..employeeId.."_water_"..task.plantId
                        EmployeeFailedTasks[failKey] = os.time()
                        
                        if Config.laboratoire.debug then
                            null.DebugPrint("[TASK] Employee", employeeId, "FAILED water task for plant", task.plantId, "- blocked for 60s")
                        end
                    end
                elseif task.type == "fertilize" then
                    ServerEmployeeAnimWaterFertilize(labId, employeeId, task.plantId, "fertilize")
                    success = EmployeeFertilizePlant(labId, employeeId, task.plantId)
                    if success then
                        local fatigue = math.floor((taskConfig.fatigueNeeded or 4) * fatigueMultiplier)
                        lab.employees[employeeId].fatigue = math.min(100, lab.employees[employeeId].fatigue + fatigue)
                    else
                        local failKey = labId.."_"..employeeId.."_fertilize_"..task.plantId
                        EmployeeFailedTasks[failKey] = os.time()
                        
                        if Config.laboratoire.debug then
                            null.DebugPrint("[TASK] Employee", employeeId, "FAILED fertilize task for plant", task.plantId, "- blocked for 60s")
                        end
                    end
                elseif task.type == "seed" then
                    ServerEmployeeAnimSeed(labId, employeeId, task.plantId)
                    success = EmployeeSeedPlant(labId, employeeId, task.plantId)
                    if success then
                        local fatigue = math.floor((taskConfig.fatigueNeeded or 4) * fatigueMultiplier)
                        lab.employees[employeeId].fatigue = math.min(100, lab.employees[employeeId].fatigue + fatigue)
                    else
                        local failKey = labId.."_"..employeeId.."_seed_"..task.plantId
                        EmployeeFailedTasks[failKey] = os.time()
                        
                        if Config.laboratoire.debug then
                            null.DebugPrint("[TASK] Employee", employeeId, "FAILED seed task for plant", task.plantId, "- blocked for 60s")
                        end
                    end
                elseif task.type == "harvest" then
                    ServerEmployeeAnimHarvest(labId, employeeId, task.plantId)
                    success = EmployeeHarvestPlant(labId, employeeId, task.plantId)
                    if success then
                        local fatigue = math.floor((taskConfig.fatigueNeeded or 4) * fatigueMultiplier)
                        lab.employees[employeeId].fatigue = math.min(100, lab.employees[employeeId].fatigue + fatigue)
                    else
                        local failKey = labId.."_"..employeeId.."_harvest_"..task.plantId
                        EmployeeFailedTasks[failKey] = os.time()
                        
                        if Config.laboratoire.debug then
                            null.DebugPrint("[TASK] Employee", employeeId, "FAILED harvest task for plant", task.plantId, "- blocked for 60s")
                        end
                    end
                elseif task.type == "dry_weed" then
                    ServerEmployeeAnimDryArea(labId, employeeId, "dry_weed")
                    success = EmployeeDryWeed(labId, employeeId)
                    if success then
                        local fatigue = math.floor((taskConfig.fatigueNeeded or 4) * fatigueMultiplier)
                        lab.employees[employeeId].fatigue = math.min(100, lab.employees[employeeId].fatigue + fatigue)
                    end
                elseif task.type == "collect_dry" then
                    ServerEmployeeAnimDryArea(labId, employeeId, "collect_dry")
                    success = EmployeeCollectDryWeed(labId, employeeId)
                    if success then
                        local fatigue = math.floor((taskConfig.fatigueNeeded or 4) * fatigueMultiplier)
                        lab.employees[employeeId].fatigue = math.min(100, lab.employees[employeeId].fatigue + fatigue)
                    end
                elseif task.type == "get_fresh_for_dry" then
                    -- Récupérer weed frais au stockage pour séchage
                    ServerEmployeeAnimStorage(labId, employeeId, "storage")
                    success = EmployeeGetFreshWeedForDrying(labId, employeeId)
                    if success then
                        local fatigue = math.floor((taskConfig.fatigueNeeded or 3) * fatigueMultiplier)
                        lab.employees[employeeId].fatigue = math.min(100, lab.employees[employeeId].fatigue + fatigue)
                    end
                elseif task.type == "deposit_fresh" then
                    ServerEmployeeAnimStorage(labId, employeeId, "deposit_fresh")
                    success = EmployeeDepositFreshWeed(labId, employeeId)
                    if success then
                        local fatigue = math.floor((taskConfig.fatigueNeeded or 2) * fatigueMultiplier)
                        lab.employees[employeeId].fatigue = math.min(100, lab.employees[employeeId].fatigue + fatigue)
                    end
                elseif task.type == "deposit_dry" then
                    ServerEmployeeAnimDryArea(labId, employeeId, "deposit_dry")
                    success = EmployeeDepositDryWeed(labId, employeeId)
                    if success then
                        local fatigue = math.floor((taskConfig.fatigueNeeded or 4) * fatigueMultiplier)
                        lab.employees[employeeId].fatigue = math.min(100, lab.employees[employeeId].fatigue + fatigue)
                    end
                elseif task.type == "treat_weed" then
                    ServerEmployeeAnimTreatWeed(labId, employeeId, task.cutId)
                    EmployeeTreatWeed(labId, employeeId, function(treatSuccess)
                        success = treatSuccess
                        if success then
                            lab.employees[employeeId].fatigue = math.min(100, lab.employees[employeeId].fatigue + (taskConfig.fatigueNeeded or 4))
                        end
                    end)
                end
                
                --Cache.SaveOne("illegals")
                
                ReleaseTaskLock(task.taskKey)
                
                Wait(3000)
                EmployeeCurrentTask[labId][employeeId] = nil
            else
                if not lab.employees[employeeId].fatigue then
                    lab.employees[employeeId].fatigue = 0
                end
                
                if lab.employees[employeeId].fatigue >= 100 then
                    if not EmployeeCurrentTask[labId] then
                        EmployeeCurrentTask[labId] = {}
                    end
                    EmployeeCurrentTask[labId][employeeId] = {type = "resting", reason = "exhausted"}
                    
                    --null.DebugPrint("[REST] Employee", employeeId, "exhausted (100%), returning to base for rest")
                    
                    -- Retourner à la base et attendre que ce soit terminé
                    local ped = createdEmployees[labId] and createdEmployees[labId][employeeId]
                    if ped and DoesEntityExist(ped) then
                        local returnSuccess = ReturnToBase(ped, labId, employeeId)
                        if returnSuccess then
                            --null.DebugPrint("[REST] Employee", employeeId, "at base, starting rest period")
                        end
                    end
                    
                    -- Repos prolongé avec animation idle
                    while lab.employees[employeeId].fatigue > 0 do
                        Wait(20000)
                        lab.employees[employeeId].fatigue = math.max(0, lab.employees[employeeId].fatigue - 5)
                        Cache.SaveOne("illegals")
                        --null.DebugPrint("[REST] Employee", employeeId, "fatigue:", lab.employees[employeeId].fatigue, "%")
                    end
                    
                    EmployeeCurrentTask[labId][employeeId] = nil
                    --null.DebugPrint("[REST] Employee", employeeId, "fully rested, resuming work")
                else
                    -- Pas de tâche mais pas épuisé : retour à la base pour courte pause
                    local ped = createdEmployees[labId] and createdEmployees[labId][employeeId]
                    if ped and DoesEntityExist(ped) then
                        ReturnToBase(ped, labId, employeeId)
                    end
                    Wait(5000)
                end
            end
            
            Wait(1000)
        end
    end))
end

function MethEmployeeAI(labId, employeeId)
    Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
        while AllWhileForEmployee[labId] and AllWhileForEmployee[labId][employeeId] do
            local lab = SaveData.json["illegals"]["laboratorys"][labId]
            if not lab or not lab.employees[employeeId] or lab.employees[employeeId].getPayed == false then
                break
            end
            
            local task = GetNextTaskMeth(labId, employeeId)
            
            if task then
                if not EmployeeCurrentTask[labId] then
                    EmployeeCurrentTask[labId] = {}
                end
                EmployeeCurrentTask[labId][employeeId] = task
                
                if not lab.employees[employeeId].fatigue then
                    lab.employees[employeeId].fatigue = 0
                end

                local success = false
                local taskConfig = Config.EmployeeTasks[task.type] or {}
                local employeeConfig = Config.laboratoire.employees[employeeId]
                local fatigueMultiplier = (employeeConfig and employeeConfig.fatigueMultiplier) or 1.0
                
                if task.type == "meth_fill_cuve" then
                    ServerEmployeeAnimMethCuve(labId, employeeId, task.cuveId)
                    success = EmployeeMethFillCuve(labId, employeeId, task.cuveId)
                elseif task.type == "meth_add_solvant" then
                    ServerEmployeeAnimMethCuve(labId, employeeId, task.cuveId)
                    success = EmployeeMethAddSolvant(labId, employeeId, task.cuveId)
                elseif task.type == "meth_collect_tray" then
                    ServerEmployeeAnimMethCuve(labId, employeeId, task.cuveId)
                    success = EmployeeMethCollectTray(labId, employeeId, task.cuveId)
                elseif task.type == "meth_load_four" then
                    ServerEmployeeAnimMethFour(labId, employeeId, task.fourId)
                    success = EmployeeMethLoadFour(labId, employeeId, task.fourId)
                elseif task.type == "meth_unload_four" then
                    ServerEmployeeAnimMethFour(labId, employeeId, task.fourId)
                    success = EmployeeMethUnloadFour(labId, employeeId, task.fourId)
                elseif task.type == "meth_deposit_storage" then
                    ServerEmployeeAnimMethStorage(labId, employeeId)
                    success = EmployeeMethDepositStorage(labId, employeeId)
                elseif task.type == "meth_break_tray" then
                    ServerEmployeeAnimMethBreak(labId, employeeId, task.breakId)
                    success = EmployeeMethBreakTray(labId, employeeId, task.breakId)
                end
                
                if success then
                    local fatigue = math.floor((taskConfig.fatigueNeeded or 4) * fatigueMultiplier)
                    lab.employees[employeeId].fatigue = math.min(100, lab.employees[employeeId].fatigue + fatigue)
                else
                    local failKey = labId.."_"..employeeId.."_"..task.type
                    if task.cuveId then failKey = failKey.."_"..task.cuveId end
                    if task.fourId then failKey = failKey.."_"..task.fourId end
                    if task.breakId then failKey = failKey.."_"..task.breakId end
                    if task.cutId then failKey = failKey.."_"..task.cutId end
                    EmployeeFailedTasks[failKey] = os.time()
                end
                
                ReleaseTaskLock(task.taskKey)
                
                Wait(3000)
                EmployeeCurrentTask[labId][employeeId] = nil
            else
                if not lab.employees[employeeId].fatigue then
                    lab.employees[employeeId].fatigue = 0
                end
                
                if lab.employees[employeeId].fatigue >= 100 then
                    if not EmployeeCurrentTask[labId] then
                        EmployeeCurrentTask[labId] = {}
                    end
                    EmployeeCurrentTask[labId][employeeId] = {type = "resting", reason = "exhausted"}
                    
                    null.DebugPrint("[REST] Meth Employee", employeeId, "exhausted (100%), returning to base for rest")
                    
                    local ped = createdEmployees[labId] and createdEmployees[labId][employeeId]
                    if ped and DoesEntityExist(ped) then
                        ReturnToBase(ped, labId, employeeId)
                    end
                    
                    while lab.employees[employeeId].fatigue > 0 do
                        Wait(20000)
                        lab.employees[employeeId].fatigue = math.max(0, lab.employees[employeeId].fatigue - 5)
                        Cache.SaveOne("illegals")
                    end
                    
                    EmployeeCurrentTask[labId][employeeId] = nil
                    null.DebugPrint("[REST] Meth Employee", employeeId, "fully rested, resuming work")
                else
                    local ped = createdEmployees[labId] and createdEmployees[labId][employeeId]
                    if ped and DoesEntityExist(ped) then
                        ReturnToBase(ped, labId, employeeId)
                    end
                    Wait(5000)
                end
            end
            
            Wait(1000)
        end
    end))
end

function SetupLaboEmployees(id, reload)
    Citizen.CreateThread(function()
        if createdEmployees[id] == nil then
            createdEmployees[id] = {}
        end
        if AllWhileForEmployee[id] == nil then
            AllWhileForEmployee[id] = {}
        end
        local data = SaveData.json["illegals"]["laboratorys"][id]
        if not data then return end
        if reload then
            for k,v in pairs(createdEmployees[id]) do 
                if DoesEntityExist(v) then
                    DeleteEntity(v)
                end
            end
            AllWhileForEmployee[id] = {}
            createdEmployees[id] = {}
            ClearAllBaseSpots(id)
        end
        if data.employees then
            for k,v in pairs(data.employees) do
                if v.getPayed == false then
                    if createdEmployees[id][v.id] and DoesEntityExist(createdEmployees[id][v.id]) then
                        DeleteEntity(createdEmployees[id][v.id])
                    end
                    goto pass
                end
                if not Config.laboratoire.employees[v.id] then
                    goto pass
                end
                if createdEmployees[id][v.id] ~= nil and DoesEntityExist(createdEmployees[id][v.id]) then
                    goto pass
                end
                if createdEmployees[id][v.id] ~= nil and not DoesEntityExist(createdEmployees[id][v.id]) then
                    createdEmployees[id][v.id] = nil
                end
                local employeeConfig = Config.laboratoire.employees[v.id]
                local model = GetHashKey(employeeConfig.model)
                
                -- Assigner un spot dynamique (canapé ou entrée)
                local spot = AssignBaseSpot(id, v.id)
                local spawnCoords = spot and spot.coords or employeeConfig.baseCoords
                local spawnHeading = spot and spot.heading or employeeConfig.baseHeading
                
                createdEmployees[id][v.id] = CreatePed(4, model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnHeading, true, true)
                SetEntityRoutingBucket(createdEmployees[id][v.id], data.instance)
                
                -- Configuration pour permettre au ped d'accepter les tâches server-side
                --SetBlockingOfNonTemporaryEvents(createdEmployees[id][v.id], true)
                --SetPedFleeAttributes(createdEmployees[id][v.id], 0, false)
                --SetPedCombatAttributes(createdEmployees[id][v.id], 17, true)
                SetPedCanRagdoll(createdEmployees[id][v.id], false)
                --SetEntityInvincible(createdEmployees[id][v.id], true)
                
                while not DoesEntityExist(createdEmployees[id][v.id]) and NetworkGetNetworkIdFromEntity(createdEmployees[id][v.id]) == 0 do
                    Citizen.Wait(1)
                end
                SetEntityCoords(createdEmployees[id][v.id], spawnCoords, true, false, false, false)
                SetEntityHeading(createdEmployees[id][v.id], spawnHeading)
                
                Wait(100)
                
                -- Jouer l'animation idle selon le type de spot
                if spot and spot.type == "couch" then
                    local spots = Config.laboratoire.baseSpots
                    if spots and spots.couchAnims and spots.couchAnims[spot.spotIndex] then
                        local couchAnim = spots.couchAnims[spot.spotIndex]
                        TaskPlayAnim(createdEmployees[id][v.id], couchAnim.dict, couchAnim.anim, 8.0, 8.0, -1, 1, 0, false, false, false)
                    elseif employeeConfig.sitChair and employeeConfig.anim then
                        TaskPlayAnim(createdEmployees[id][v.id], employeeConfig.anim[1], employeeConfig.anim[2], 8.0, 8.0, -1, 1, 0, false, false, false)
                    end
                elseif spot and spot.type == "entrance" then
                    -- Animation aléatoire d'entrée (sera gérée côté client via idle anim event)
                    local pedNetId = NetworkGetNetworkIdFromEntity(createdEmployees[id][v.id])
                    local spots = Config.laboratoire.baseSpots
                    if spots and spots.entranceAnims and #spots.entranceAnims > 0 then
                        local chosen = spots.entranceAnims[math.random(#spots.entranceAnims)]
                        if chosen.scenario then
                            TriggerClientEvent("null:labo:playEmployeeIdleAnim", -1, pedNetId, "scenario", chosen.scenario, -1)
                        else
                            TriggerClientEvent("null:labo:playEmployeeIdleAnim", -1, pedNetId, chosen.dict, chosen.anim, -1)
                        end
                    end
                elseif employeeConfig.sitChair and employeeConfig.anim then
                    TaskPlayAnim(createdEmployees[id][v.id], employeeConfig.anim[1], employeeConfig.anim[2], 8.0, 8.0, -1, 1, 0, false, false, false)
                end
                if AllWhileForEmployee[id][v.id] == nil then
                    AllWhileForEmployee[id][v.id] = true
                    
                    -- Thread de surveillance de la santé de l'employé
                    Citizen.CreateThread(function() 
                        while true do
                            if AllWhileForEmployee[id][v.id] == nil then break end

                            if GetEntityHealth(createdEmployees[id][v.id]) <= 0 and GetEntityMaxHealth(createdEmployees[id][v.id]) ~= 0 then
                                AllWhileForEmployee[id][v.id] = nil
                                ReleaseBaseSpot(id, v.id)
                                SaveData.json["illegals"]["laboratorys"][id].employees[k] = nil
                                TriggerClientEvent("null:labo:edit", -1, id, SaveData.json["illegals"]["laboratorys"][id])
                                Citizen.CreateThread(function()
                                    Wait(15000)
                                    if DoesEntityExist(createdEmployees[id][v.id]) then
                                        DeleteEntity(createdEmployees[id][v.id])
                                    end
                                    createdEmployees[id][v.id] = nil
                                    TriggerClientEvent("null:labo:removeEmployee", -1, id, v.id)
                                end)
                            end
                            Wait(5000)
                        end
                    end)
                    
                    if data.type == "weed" then
                        Wait(math.random(2000, 8000))
                        EmployeeAI(id, v.id)
                    elseif data.type == "meth" then
                        Wait(math.random(2000, 8000))
                        MethEmployeeAI(id, v.id)
                    end
                end
                ::pass::
            end
        end
    end)
end

ESX.RegisterServerCallback("null:labo:getEmployeeInfoFromPed", function(source, cb, pedNetId)
    local labId = nil
    local employeeId = nil
    
    -- Comparer les NetworkIds au lieu des entités directement
    for lId, employees in pairs(createdEmployees) do
        for eId, ped in pairs(employees) do
            if DoesEntityExist(ped) then
                local employeePedNetId = NetworkGetNetworkIdFromEntity(ped)
                if employeePedNetId == pedNetId then
                    labId = lId
                    employeeId = eId
                    break
                end
            end
        end
        if labId then break end
    end
    
    if not labId or not employeeId then
        cb(nil)
        return
    end
    
    local lab = SaveData.json["illegals"]["laboratorys"][labId]
    if not lab or not lab.employees or not lab.employees[employeeId] then
        cb(nil)
        return
    end
    
    local employeeData = lab.employees[employeeId]
    local employeeConfig = Config.laboratoire.employees[employeeId]
    
    if not employeeData.fatigue then
        employeeData.fatigue = 0
    end

    local currentTask = "Repos"
    if EmployeeCurrentTask and EmployeeCurrentTask[labId] and EmployeeCurrentTask[labId][employeeId] then
        local task = EmployeeCurrentTask[labId][employeeId]
        if task.type == "water" then
            currentTask = "Arrosage plante #"..task.plantId
        elseif task.type == "fertilize" then
            currentTask = "Fertilisation plante #"..task.plantId
        elseif task.type == "seed" then
            currentTask = "Plantation graine #"..task.plantId
        elseif task.type == "harvest" then
            currentTask = "Récolte plante #"..task.plantId
        elseif task.type == "dry_weed" then
            currentTask = "Séchage weed"
        elseif task.type == "collect_dry" then
            currentTask = "Collecte weed séché"
        elseif task.type == "get_fresh_for_dry" then
            currentTask = "Récupération weed frais pour séchage"
        elseif task.type == "deposit_fresh" then
            currentTask = "Dépôt weed frais au stockage"
        elseif task.type == "deposit_dry" then
            currentTask = "Dépôt weed séché"
        elseif task.type == "treat_weed" then
            currentTask = "Traitement weed table #"..(task.cutId or "?")
        elseif task.type == "meth_fill_cuve" then
            currentTask = "Remplissage cuve #"..(task.cuveId or "?")
        elseif task.type == "meth_add_solvant" then
            currentTask = "Ajout solvant cuve #"..(task.cuveId or "?")
        elseif task.type == "meth_collect_tray" then
            currentTask = "Récupération plateau cuve #"..(task.cuveId or "?")
        elseif task.type == "meth_load_four" then
            currentTask = "Chargement four #"..(task.fourId or "?")
        elseif task.type == "meth_unload_four" then
            currentTask = "Déchargement four #"..(task.fourId or "?")
        elseif task.type == "meth_deposit_storage" then
            currentTask = "Dépôt meth au stockage"
        elseif task.type == "meth_break_tray" then
            currentTask = "Cassage + packaging meth #"..(task.breakId or "?")
        elseif task.type == "meth_pack_pooch" then
            currentTask = "Mise en pochon meth"
        elseif task.type == "resting" then
            currentTask = "Repos (épuisé)"
        end
    end
    
    cb({
        labId = labId,
        employeeId = employeeId,
        name = employeeConfig.name or employeeId,
        fatigue = employeeData.fatigue or 0,
        currentTask = currentTask,
        inventory = employeeData.inventory or {},
        getPayed = employeeData.getPayed or false
    })
end)


-- Cleanup des employés lors du stop de la ressource
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- Arrêter tous les threads d'employés
    for labId, employees in pairs(AllWhileForEmployee) do
        for employeeId, _ in pairs(employees) do
            AllWhileForEmployee[labId][employeeId] = false
        end
    end
    
    -- Supprimer tous les peds d'employés
    for labId, employees in pairs(createdEmployees) do
        for employeeId, ped in pairs(employees) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
                --null.DebugPrint("[LABORATORY] Deleted employee ped: "..employeeId.." (Lab: "..labId..")")
            end
        end
    end
    
    -- Nettoyer les tables
    createdEmployees = {}
    AllWhileForEmployee = {}
    EmployeeTaskLocks = {}
    EmployeeAnimThreads = {}
end)

