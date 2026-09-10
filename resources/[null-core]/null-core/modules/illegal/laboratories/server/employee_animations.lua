-- Système d'animations des employés 100% server-side
-- Gère les déplacements, animations et retours à la position de base

local EmployeeAnimThreads = {}

-- Système d'allocation dynamique des spots de base
local EmployeeBaseSpots = {} -- [labId] = { [employeeId] = { coords, heading, type, spotIndex } }
local OccupiedSpots = {} -- [labId] = { couch = {}, entrance = {} }

function AssignBaseSpot(labId, employeeId)
    if not EmployeeBaseSpots[labId] then EmployeeBaseSpots[labId] = {} end
    if not OccupiedSpots[labId] then OccupiedSpots[labId] = { couch = {}, entrance = {} } end
    
    -- Déjà assigné ?
    if EmployeeBaseSpots[labId][employeeId] then
        return EmployeeBaseSpots[labId][employeeId]
    end
    
    local spots = Config.laboratoire.baseSpots
    if not spots then
        -- Fallback sur l'ancien système si pas de baseSpots config
        local employeeConfig = Config.laboratoire.employees[employeeId]
        if employeeConfig then
            EmployeeBaseSpots[labId][employeeId] = {
                coords = employeeConfig.baseCoords,
                heading = employeeConfig.baseHeading,
                type = "couch",
                spotIndex = 0
            }
            return EmployeeBaseSpots[labId][employeeId]
        end
        return nil
    end
    
    -- Essayer un spot canapé d'abord
    if spots.couch then
        for i, spot in ipairs(spots.couch) do
            if not OccupiedSpots[labId].couch[i] then
                OccupiedSpots[labId].couch[i] = employeeId
                EmployeeBaseSpots[labId][employeeId] = {
                    coords = spot.coords,
                    heading = spot.heading,
                    type = "couch",
                    spotIndex = i
                }
                return EmployeeBaseSpots[labId][employeeId]
            end
        end
    end
    
    -- Fallback sur les spots d'entrée
    if spots.entrance then
        for i, spot in ipairs(spots.entrance) do
            if not OccupiedSpots[labId].entrance[i] then
                OccupiedSpots[labId].entrance[i] = employeeId
                EmployeeBaseSpots[labId][employeeId] = {
                    coords = vec3(spot.x, spot.y, spot.z),
                    heading = spot.w,
                    type = "entrance",
                    spotIndex = i
                }
                return EmployeeBaseSpots[labId][employeeId]
            end
        end
    end
    
    -- Aucun spot disponible, fallback sur config employé
    local employeeConfig = Config.laboratoire.employees[employeeId]
    if employeeConfig then
        EmployeeBaseSpots[labId][employeeId] = {
            coords = employeeConfig.baseCoords,
            heading = employeeConfig.baseHeading,
            type = "couch",
            spotIndex = 0
        }
        return EmployeeBaseSpots[labId][employeeId]
    end
    
    return nil
end

function ReleaseBaseSpot(labId, employeeId)
    if not EmployeeBaseSpots[labId] or not EmployeeBaseSpots[labId][employeeId] then return end
    local spot = EmployeeBaseSpots[labId][employeeId]
    if OccupiedSpots[labId] then
        if spot.type == "couch" and OccupiedSpots[labId].couch then
            OccupiedSpots[labId].couch[spot.spotIndex] = nil
        elseif spot.type == "entrance" and OccupiedSpots[labId].entrance then
            OccupiedSpots[labId].entrance[spot.spotIndex] = nil
        end
    end
    EmployeeBaseSpots[labId][employeeId] = nil
end

function ClearAllBaseSpots(labId)
    EmployeeBaseSpots[labId] = nil
    OccupiedSpots[labId] = nil
end

-- Fonction helper pour faire marcher un ped vers une position
-- Utilise le système de pathfinding intelligent avec waypoints
local function WalkToCoords(ped, targetCoords, timeout)
    if not DoesEntityExist(ped) then return false end
    
    FreezeEntityPosition(ped, false)

    local success = NavigatePedToPosition(ped, vector3(targetCoords.x, targetCoords.y, targetCoords.z), timeout)
    
    if not success then
        null.DebugPrint("[EMPLOYEE] Failed to reach destination")
    end
    
    return success
end

-- Fonction helper pour jouer une animation côté client
local function PlayAnimation(ped, animType, duration, extraParam)
    if not DoesEntityExist(ped) then return false end
    
    local pedNetId = NetworkGetNetworkIdFromEntity(ped)
    
    if animType == "water" then
        TriggerClientEvent("null:labo:playEmployeeWaterAnim", -1, pedNetId, duration)
    elseif animType == "fertilizer" then
        TriggerClientEvent("null:labo:playEmployeeFertilizerAnim", -1, pedNetId, duration)
    elseif animType == "seed" then
        TriggerClientEvent("null:labo:playEmployeeSeedAnim", -1, pedNetId, duration)
    elseif animType == "harvest" then
        TriggerClientEvent("null:labo:playEmployeeHarvestAnim", -1, pedNetId, duration)
    elseif animType == "dry_area" then
        TriggerClientEvent("null:labo:playEmployeeDryAreaAnim", -1, pedNetId, duration)
    elseif animType == "treat" then
        TriggerClientEvent("null:labo:playEmployeeTreatAnim", -1, pedNetId, extraParam or 5)
    elseif animType == "storage" then
        TriggerClientEvent("null:labo:playEmployeeStorageAnim", -1, pedNetId, duration)
    elseif animType == "meth_cuve" then
        TriggerClientEvent("null:labo:playEmployeeMethCuveAnim", -1, pedNetId, duration)
    elseif animType == "meth_four" then
        TriggerClientEvent("null:labo:playEmployeeMethFourAnim", -1, pedNetId, duration)
    elseif animType == "meth_break" then
        TriggerClientEvent("null:labo:playEmployeeMethBreakAnim", -1, pedNetId, duration)
    end
    
    Wait(duration)
    
    return true
end

-- Fonction helper pour retourner à la position de base
function ReturnToBase(ped, labId, employeeId)
    local spot = AssignBaseSpot(labId, employeeId)
    if not spot then return false end
    
    local baseCoords = spot.coords
    local baseHeading = spot.heading
    
    -- Vérifier si le ped est déjà à sa position de base
    if DoesEntityExist(ped) then
        local currentCoords = GetEntityCoords(ped)
        local currentHeading = GetEntityHeading(ped)
        local dist = #(currentCoords - baseCoords)
        local headingDiff = math.abs(currentHeading - baseHeading)
        if headingDiff > 180 then headingDiff = 360 - headingDiff end
        
        -- Si déjà à moins de 0.5m de la base et heading correct (±20°), ne pas rejouer l'animation
        if dist < 0.5 and headingDiff < 20 then
            return true
        end
    end
    
    local success = NavigatePedToPosition(ped, baseCoords, 500)
    
    if success and DoesEntityExist(ped) then
        ClearPedTasks(ped)
        Wait(100)
        
        -- Positionner le ped exactement à sa place
        SetEntityCoords(ped, baseCoords.x, baseCoords.y, baseCoords.z, false, false, false, false)
        SetEntityHeading(ped, baseHeading)
        
        Wait(200)
        
        local pedNetId = NetworkGetNetworkIdFromEntity(ped)
        
        if spot.type == "couch" then
            -- Animation assise sur le canapé
            local spots = Config.laboratoire.baseSpots
            if spots and spots.couchAnims and spots.couchAnims[spot.spotIndex] then
                local couchAnim = spots.couchAnims[spot.spotIndex]
                TriggerClientEvent("null:labo:playEmployeeIdleAnim", -1, pedNetId, couchAnim.dict, couchAnim.anim, -1)
            else
                -- Fallback sur l'ancien système
                local employeeConfig = Config.laboratoire.employees[employeeId]
                if employeeConfig and employeeConfig.anim then
                    TriggerClientEvent("null:labo:playEmployeeIdleAnim", -1, pedNetId, employeeConfig.anim[1], employeeConfig.anim[2], -1)
                end
            end
        else
            -- Spot d'entrée : animation aléatoire
            local spots = Config.laboratoire.baseSpots
            if spots and spots.entranceAnims and #spots.entranceAnims > 0 then
                local chosen = spots.entranceAnims[math.random(#spots.entranceAnims)]
                if chosen.scenario then
                    TriggerClientEvent("null:labo:playEmployeeIdleAnim", -1, pedNetId, "scenario", chosen.scenario, -1)
                else
                    TriggerClientEvent("null:labo:playEmployeeIdleAnim", -1, pedNetId, chosen.dict, chosen.anim, -1)
                end
            end
        end
        
        return true
    end
    
    return false
end


-- Animation: Water/Fertilize
function ServerEmployeeAnimWaterFertilize(labId, employeeId, plantId, animType)
    if not createdEmployees[labId] or not createdEmployees[labId][employeeId] then
        null.DebugPrint("[EMPLOYEE] Employee not found: "..employeeId)
        return
    end
    
    local ped = createdEmployees[labId][employeeId]
    
    if not DoesEntityExist(ped) then
        null.DebugPrint("[EMPLOYEE] Ped does not exist")
        return
    end
    
    if EmployeeAnimThreads[labId.."_"..employeeId] then
        return
    end
    
    EmployeeAnimThreads[labId.."_"..employeeId] = true
    
    Citizen.CreateThread(function()
        local plant = SaveData.Illegal.WeedPlants[plantId]
        if not plant then
            null.DebugPrint("[EMPLOYEE] Plant not found")
            EmployeeAnimThreads[labId.."_"..employeeId] = nil
            return
        end
        
        local taskConfig = Config.EmployeeTasks[animType]
        local itemName = taskConfig.requiredItem
        
        local storageId = "labo_coffre_big_"..labId
        local STORAGE_POSITION = vector3(-320.923187, -1359.961914, 24.309654)
        
        local storageSuccess = NavigatePedToPosition(ped, STORAGE_POSITION, taskConfig.timing.walkTimeout)
        
        if not storageSuccess then
            
            EmployeeAnimThreads[labId.."_"..employeeId] = nil
            return false
        end
        
        ClearPedTasks(ped)
        Wait(500)
        local storageAnim = taskConfig.animations.storage
        PlayAnimation(ped, "storage", storageAnim.duration)
        
        local hasItem = false
        GetItemCountFromStorage(storageId, itemName, function(itemCount)
            if itemCount > 0 then
                hasItem = true
            end
        end)
        
        Wait(500)
        
        if not hasItem then
            EmployeeAnimThreads[labId.."_"..employeeId] = nil
            return false
        end
        
        local plantCoords = plant.coords
        local arrived = WalkToCoords(ped, plantCoords, taskConfig.timing.walkTimeout)
        
        if not arrived then
            EmployeeAnimThreads[labId.."_"..employeeId] = nil
            return false
        end
        
        local workAnim = taskConfig.animations.work
        
        if animType == "water" then
            PlayAnimation(ped, "water", workAnim.duration)
            EmployeeWaterPlant(labId, employeeId, plantId)
        elseif animType == "fertilize" then
            PlayAnimation(ped, "fertilizer", workAnim.duration)
            EmployeeFertilizePlant(labId, employeeId, plantId)
        end
        
        -- Unfreeze via event après l'animation
        local pedNetId = NetworkGetNetworkIdFromEntity(ped)
        TriggerClientEvent("null:labo:client:unfreezeEmployee", -1, pedNetId)
        
        EmployeeAnimThreads[labId.."_"..employeeId] = nil
        return true
    end)
end

-- Animation: Seed
function ServerEmployeeAnimSeed(labId, employeeId, plantId)
    if not createdEmployees[labId] or not createdEmployees[labId][employeeId] then
        null.DebugPrint("[EMPLOYEE] Employee not found: "..employeeId)
        return
    end
    
    local ped = createdEmployees[labId][employeeId]
    
    if not DoesEntityExist(ped) then
        null.DebugPrint("[EMPLOYEE] Ped does not exist")
        return
    end
    
    if EmployeeAnimThreads[labId.."_"..employeeId] then
        return
    end
    
    EmployeeAnimThreads[labId.."_"..employeeId] = true
    
    Citizen.CreateThread(function()
        local plant = SaveData.Illegal.WeedPlants[plantId]
        if not plant then
            null.DebugPrint("[EMPLOYEE] Plant not found")
            EmployeeAnimThreads[labId.."_"..employeeId] = nil
            return
        end
        
        local taskConfig = Config.EmployeeTasks["seed"]
        local storageId = "labo_coffre_big_"..labId
        local STORAGE_POSITION = vector3(-320.923187, -1359.961914, 24.309654)
        
        local storageSuccess = NavigatePedToPosition(ped, STORAGE_POSITION, taskConfig.timing.walkTimeout)
        
        if not storageSuccess then
            
            EmployeeAnimThreads[labId.."_"..employeeId] = nil
            return false
        end
        
        ClearPedTasks(ped)
        Wait(500)
        local storageAnim = taskConfig.animations.storage
        PlayAnimation(ped, "storage", storageAnim.duration)
        
        local hasItem = false
        GetItemCountFromStorage(storageId, taskConfig.requiredItem, function(itemCount)
            if itemCount > 0 then
                hasItem = true
            end
        end)
        
        Wait(500)
        
        if not hasItem then
            
            EmployeeAnimThreads[labId.."_"..employeeId] = nil
            return false
        end
        
        local plantCoords = plant.coords
        local arrived = WalkToCoords(ped, plantCoords, taskConfig.timing.walkTimeout)
        
        if not arrived then
            
            EmployeeAnimThreads[labId.."_"..employeeId] = nil
            return false
        end
        
        local seedRemoved = false
        RemoveItemToStorage(storageId, taskConfig.requiredItem, 1)
        Wait(100)
        seedRemoved = true
        
        if not seedRemoved then
            EmployeeAnimThreads[labId.."_"..employeeId] = nil
            return false
        end
        
        local workAnim = taskConfig.animations.work
        PlayAnimation(ped, "seed", workAnim.duration)
        
        SaveData.Illegal.WeedPlants[plantId].hasBase = 1
        SaveData.Illegal.WeedPlants[plantId].time = os.time()
        
        MySQL.update('UPDATE weedplants SET hasBase = @hasBase, time = @time WHERE id = @id', {
            ['@hasBase'] = 1,
            ['@time'] = SaveData.Illegal.WeedPlants[plantId].time,
            ['@id'] = plantId,
        }, function(affectedRows)
            --null.DebugPrint("[SEED] MySQL UPDATE affected rows:", affectedRows, "for plant", plantId)
        end)
        
        TriggerClientEvent("null:weed:client:recevieDataPlant", -1, plantId, SaveData.Illegal.WeedPlants[plantId])
        
        -- Unfreeze via event après l'animation
        local pedNetId = NetworkGetNetworkIdFromEntity(ped)
        TriggerClientEvent("null:labo:client:unfreezeEmployee", -1, pedNetId)
        
        EmployeeAnimThreads[labId.."_"..employeeId] = nil
    end)
end

-- Animation: Harvest
ServerEmployeeAnimHarvest = function(labId, employeeId, plantId)
    local ped = createdEmployees[labId] and createdEmployees[labId][employeeId]
    if not ped or not DoesEntityExist(ped) then
        null.DebugPrint("[EMPLOYEE] Ped not found for "..employeeId)
        return false
    end
    
    if EmployeeAnimThreads[labId] and EmployeeAnimThreads[labId][employeeId] then
        return false
    end
    
    if not EmployeeAnimThreads[labId] then EmployeeAnimThreads[labId] = {} end
    EmployeeAnimThreads[labId][employeeId] = true
    
    Citizen.CreateThread(function()
        local baseCoords = GetEntityCoords(ped)
        local baseHeading = GetEntityHeading(ped)
        
        local plant = SaveData.Illegal.WeedPlants[plantId]
        if not plant then
            null.DebugPrint("[EMPLOYEE] Plant not found: "..plantId)
            EmployeeAnimThreads[labId][employeeId] = nil
            return
        end
        
        local plantCoords = plant.coords
        local walkSuccess = WalkToCoords(ped, plantCoords, 100)
        if not walkSuccess then
            
            EmployeeAnimThreads[labId][employeeId] = nil
            return
        end
        
        Wait(500)
        PlayAnimation(ped, "harvest", 12500)
        
        -- Unfreeze via event après l'animation
        local pedNetId = NetworkGetNetworkIdFromEntity(ped)
        TriggerClientEvent("null:labo:client:unfreezeEmployee", -1, pedNetId)
        
        EmployeeAnimThreads[labId][employeeId] = nil
    end)
    
    return true
end

-- Animation: Dry/Collect/Deposit (with proper positioning)
ServerEmployeeAnimDryArea = function(labId, employeeId, animType)
    local ped = createdEmployees[labId] and createdEmployees[labId][employeeId]
    if not ped or not DoesEntityExist(ped) then
        return false
    end
    
    if EmployeeAnimThreads[labId] and EmployeeAnimThreads[labId][employeeId] then
        return false
    end
    
    -- Vérifier si la zone de séchage est pleine avant de commencer l'animation
    if animType == "dry_weed" then
        local lab = SaveData.json["illegals"]["laboratorys"][labId]
        if lab and lab.treatmentequipment and lab.treatmentequipment.indrying then
            local nbr = 0
            for k,v in pairs(lab.treatmentequipment.indrying) do nbr = nbr + 1 end
            local nbrMax = 0
            for k,v in pairs(Config.laboratoire.type["weed"].treatmentequipment.DryPlantsCoords) do nbrMax = nbrMax + 1 end
            if nbr >= nbrMax then
                return false
            end
        end
    end
    
    if not EmployeeAnimThreads[labId] then EmployeeAnimThreads[labId] = {} end
    EmployeeAnimThreads[labId][employeeId] = true
    
    local baseCoords = GetEntityCoords(ped)
    local baseHeading = GetEntityHeading(ped)
    
    -- Coordonnées de la zone de séchage
    local dryCoords = Config.laboratoire.type["weed"].treatmentequipment.dry
    local dryHeading = 15.122999191284 -- Heading from DryStair config
    
    -- Aller vers la zone de séchage
    local walkSuccess = WalkToCoords(ped, dryCoords, 100)
    if not walkSuccess then
        EmployeeAnimThreads[labId][employeeId] = nil
        return false
    end
    
    -- Positionner EXACTEMENT à la zone de séchage
    if DoesEntityExist(ped) then
        ClearPedTasks(ped)
        Wait(100)
        SetEntityCoords(ped, dryCoords.x, dryCoords.y, dryCoords.z, false, false, false, false)
        SetEntityHeading(ped, dryHeading)
        FreezeEntityPosition(ped, true) -- Freeze pendant l'animation
    end
    
    Wait(500)
    
    -- Animation selon le type
    local duration = animType == "dry_weed" and 4000 or 3000
    PlayAnimation(ped, "dry_area", duration)
    
    -- Unfreeze via event après l'animation
    local pedNetId = NetworkGetNetworkIdFromEntity(ped)
    TriggerClientEvent("null:labo:client:unfreezeEmployee", -1, pedNetId)
    
    -- Retourner à la base
    if DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false) -- Unfreeze après l'animation
    end
    return true
end

-- Animation: Storage (deposit fresh weed) with proper positioning
ServerEmployeeAnimStorage = function(labId, employeeId, animType)
    local ped = createdEmployees[labId] and createdEmployees[labId][employeeId]
    if not ped or not DoesEntityExist(ped) then
        return false
    end
    
    if EmployeeAnimThreads[labId] and EmployeeAnimThreads[labId][employeeId] then
        return false
    end
    
    if not EmployeeAnimThreads[labId] then EmployeeAnimThreads[labId] = {} end
    EmployeeAnimThreads[labId][employeeId] = true
    
    local baseCoords = GetEntityCoords(ped)
    local baseHeading = GetEntityHeading(ped)
    
    -- Coordonnées du stockage (chest) - utiliser la position globale du labo
    local storageCoords = Config.laboratoire.chest
    local storageHeading = Config.laboratoire.heading
    
    -- Aller vers le stockage
    local walkSuccess = WalkToCoords(ped, storageCoords, 100)
    if not walkSuccess then
        EmployeeAnimThreads[labId][employeeId] = nil
        return false
    end
    
    -- Positionner EXACTEMENT au stockage
    if DoesEntityExist(ped) then
        ClearPedTasks(ped)
        Wait(100)
        SetEntityCoords(ped, storageCoords.x, storageCoords.y, storageCoords.z, false, false, false, false)
        SetEntityHeading(ped, storageHeading)
        FreezeEntityPosition(ped, true) -- Freeze pendant l'animation
    end
    
    Wait(500)
    
    -- Animation de dépôt
    PlayAnimation(ped, "storage", 3000)
    
    -- Unfreeze via event après l'animation
    local pedNetId = NetworkGetNetworkIdFromEntity(ped)
    TriggerClientEvent("null:labo:client:unfreezeEmployee", -1, pedNetId)
    
    -- Retourner à la base
    if DoesEntityExist(ped) then
        FreezeEntityPosition(ped, false) -- Unfreeze après l'animation
    end
    return true
end

-- Animation: Treat Weed (with specific table position)
ServerEmployeeAnimTreatWeed = function(labId, employeeId, cutId)
    local ped = createdEmployees[labId] and createdEmployees[labId][employeeId]
    if not ped or not DoesEntityExist(ped) then
        return false
    end
    
    if EmployeeAnimThreads[labId] and EmployeeAnimThreads[labId][employeeId] then
        return false
    end
    
    if not EmployeeAnimThreads[labId] then EmployeeAnimThreads[labId] = {} end
    EmployeeAnimThreads[labId][employeeId] = true
    
    local baseCoords = GetEntityCoords(ped)
    local baseHeading = GetEntityHeading(ped)
    
    -- Get specific table by cutId, or find first available
    local treatCoords = nil
    local treatHeading = nil
    local treatConfig = nil
    
    local cuts = Config.laboratoire.type["weed"].treatmentequipment.cuts
    if cutId and cuts[cutId] then
        treatCoords = cuts[cutId].coords
        treatHeading = cuts[cutId].heading
        treatConfig = cuts[cutId]
    else
        -- Fallback: find first available table
        for k, v in pairs(cuts) do
            treatCoords = v.coords
            treatHeading = v.heading
            treatConfig = v
            break
        end
    end
    
    if not treatCoords then
        EmployeeAnimThreads[labId][employeeId] = nil
        return false
    end
    
    -- Aller vers la table
    local walkSuccess = WalkToCoords(ped, treatCoords, 100)
    if not walkSuccess then
        EmployeeAnimThreads[labId][employeeId] = nil
        return false
    end
    
    -- Positionner EXACTEMENT à la table avec le bon heading
    if DoesEntityExist(ped) then
        ClearPedTasks(ped)
        Wait(100)
        SetEntityCoords(ped, treatCoords.x, treatCoords.y, treatCoords.z, false, false, false, false)
        SetEntityHeading(ped, treatHeading)
        FreezeEntityPosition(ped, true) -- Freeze pendant l'animation
    end
    
    Wait(500)
    
    -- Séquence de traitement (5 itérations de 4750ms chacune)
    PlayAnimation(ped, "treat", 4750 * 5, 5)
    
    -- Unfreeze via event après l'animation
    local pedNetId = NetworkGetNetworkIdFromEntity(ped)
    TriggerClientEvent("null:labo:client:unfreezeEmployee", -1, pedNetId)
    
    -- Retourner à la base
    if DoesEntityExist(ped) then
        ClearPedTasks(ped)
        FreezeEntityPosition(ped, false) -- Unfreeze après l'animation
    end
    
    EmployeeAnimThreads[labId][employeeId] = nil
    return true
end

-- ========== METH ANIMATION FUNCTIONS ==========

-- Animation: Meth Cuve (fill, add solvant, collect tray)
ServerEmployeeAnimMethCuve = function(labId, employeeId, cuveId)
    local ped = createdEmployees[labId] and createdEmployees[labId][employeeId]
    if not ped or not DoesEntityExist(ped) then
        return false
    end
    
    if EmployeeAnimThreads[labId] and EmployeeAnimThreads[labId][employeeId] then
        return false
    end
    
    if not EmployeeAnimThreads[labId] then EmployeeAnimThreads[labId] = {} end
    EmployeeAnimThreads[labId][employeeId] = true
    
    Citizen.CreateThread(function()
        local cuveConf = Config.laboratoire.type["meth"].cuves[cuveId]
        if not cuveConf then
            EmployeeAnimThreads[labId][employeeId] = nil
            return
        end
        
        -- Go to storage first to get items
        local storagePos = vector3(-320.923187, -1359.961914, 24.309654)
        local storageSuccess = NavigatePedToPosition(ped, storagePos, 500)
        if not storageSuccess then
            EmployeeAnimThreads[labId][employeeId] = nil
            return
        end
        
        ClearPedTasks(ped)
        Wait(500)
        PlayAnimation(ped, "storage", 4000)
        
        -- Navigate directly to cuve - pathfinding will find the route
        local cuveCoords = cuveConf.coords
        local cuveHeading = cuveConf.heading
        
        local cuveSuccess = NavigatePedToPosition(ped, cuveCoords, 500)
        if not cuveSuccess then
            EmployeeAnimThreads[labId][employeeId] = nil
            return
        end
        
        -- Position at cuve
        if DoesEntityExist(ped) then
            ClearPedTasks(ped)
            Wait(100)
            SetEntityCoords(ped, cuveCoords.x, cuveCoords.y, cuveCoords.z - 0.98, false, false, false, false)
            SetEntityHeading(ped, cuveHeading)
            FreezeEntityPosition(ped, true) -- Freeze pendant l'animation
        end
        
        Wait(500)
        PlayAnimation(ped, "meth_cuve", 6000)
        
        -- Unfreeze via event après l'animation
        local pedNetId = NetworkGetNetworkIdFromEntity(ped)
        TriggerClientEvent("null:labo:client:unfreezeEmployee", -1, pedNetId)
        
        if DoesEntityExist(ped) then
            FreezeEntityPosition(ped, false) -- Unfreeze après l'animation
        end
        
        EmployeeAnimThreads[labId][employeeId] = nil
    end)
    
    return true
end

-- Animation: Meth Four (load, unload)
ServerEmployeeAnimMethFour = function(labId, employeeId, fourId)
    local ped = createdEmployees[labId] and createdEmployees[labId][employeeId]
    if not ped or not DoesEntityExist(ped) then
        return false
    end
    
    if EmployeeAnimThreads[labId] and EmployeeAnimThreads[labId][employeeId] then
        return false
    end
    
    if not EmployeeAnimThreads[labId] then EmployeeAnimThreads[labId] = {} end
    EmployeeAnimThreads[labId][employeeId] = true
    
    Citizen.CreateThread(function()
        local fourConf = Config.laboratoire.type["meth"].fours[fourId]
        if not fourConf then
            EmployeeAnimThreads[labId][employeeId] = nil
            return
        end
        
        local fourCoords = fourConf.coords
        local fourHeading = fourConf.heading
        
        -- Navigate directly to four - pathfinding will find the route
        local fourSuccess = NavigatePedToPosition(ped, fourCoords, 500)
        if not fourSuccess then
            EmployeeAnimThreads[labId][employeeId] = nil
            return
        end
        
        -- Position at four
        if DoesEntityExist(ped) then
            ClearPedTasks(ped)
            Wait(100)
            SetEntityCoords(ped, fourCoords.x, fourCoords.y, fourCoords.z, false, false, false, false)
            SetEntityHeading(ped, fourHeading)
            FreezeEntityPosition(ped, true) -- Freeze pendant l'animation
        end
        
        Wait(500)
        PlayAnimation(ped, "meth_four", 5000)
        
        -- Unfreeze via event après l'animation
        local pedNetId = NetworkGetNetworkIdFromEntity(ped)
        TriggerClientEvent("null:labo:client:unfreezeEmployee", -1, pedNetId)
        
        if DoesEntityExist(ped) then
            FreezeEntityPosition(ped, false) -- Unfreeze après l'animation
        end
        
        EmployeeAnimThreads[labId][employeeId] = nil
    end)
    
    return true
end

-- Animation: Meth Storage (deposit meth_tray)
ServerEmployeeAnimMethStorage = function(labId, employeeId)
    local ped = createdEmployees[labId] and createdEmployees[labId][employeeId]
    if not ped or not DoesEntityExist(ped) then
        return false
    end
    
    if EmployeeAnimThreads[labId] and EmployeeAnimThreads[labId][employeeId] then
        return false
    end
    
    if not EmployeeAnimThreads[labId] then EmployeeAnimThreads[labId] = {} end
    EmployeeAnimThreads[labId][employeeId] = true
    
    Citizen.CreateThread(function()
        -- Walk to storage - pathfinding will find the route
        local storagePos = vector3(-320.923187, -1359.961914, 24.309654)
        local storageSuccess = NavigatePedToPosition(ped, storagePos, 500)
        if not storageSuccess then
            EmployeeAnimThreads[labId][employeeId] = nil
            return
        end
        
        ClearPedTasks(ped)
        Wait(500)
        PlayAnimation(ped, "storage", 3000)
        
        -- Unfreeze via event après l'animation
        local pedNetId = NetworkGetNetworkIdFromEntity(ped)
        TriggerClientEvent("null:labo:client:unfreezeEmployee", -1, pedNetId)
        
        EmployeeAnimThreads[labId][employeeId] = nil
    end)
    
    return true
end

-- Animation: Meth Break (breaking tray at breakpoint)
ServerEmployeeAnimMethBreak = function(labId, employeeId, breakId)
    local ped = createdEmployees[labId] and createdEmployees[labId][employeeId]
    if not ped or not DoesEntityExist(ped) then
        return false
    end
    
    if EmployeeAnimThreads[labId] and EmployeeAnimThreads[labId][employeeId] then
        return false
    end
    
    if not EmployeeAnimThreads[labId] then EmployeeAnimThreads[labId] = {} end
    EmployeeAnimThreads[labId][employeeId] = true
    
    Citizen.CreateThread(function()
        local breakConf = Config.laboratoire.type["meth"].breakpoints[breakId]
        if not breakConf then
            EmployeeAnimThreads[labId][employeeId] = nil
            return
        end
        
        local breakCoords = breakConf.coords
        local breakHeading = breakConf.heading
        
        -- Navigate directly to breakpoint - pathfinding will find the route
        local breakSuccess = NavigatePedToPosition(ped, breakCoords, 500)
        if not breakSuccess then
            EmployeeAnimThreads[labId][employeeId] = nil
            return
        end
        
        -- Position at breakpoint
        if DoesEntityExist(ped) then
            ClearPedTasks(ped)
            Wait(100)
            SetEntityCoords(ped, breakCoords.x, breakCoords.y, breakCoords.z, false, false, false, false)
            SetEntityHeading(ped, breakHeading)
            FreezeEntityPosition(ped, true) -- Freeze pendant l'animation
        end
        
        Wait(500)
        PlayAnimation(ped, "meth_break", 8000)
        
        -- Unfreeze via event après l'animation
        local pedNetId = NetworkGetNetworkIdFromEntity(ped)
        TriggerClientEvent("null:labo:client:unfreezeEmployee", -1, pedNetId)
        
        if DoesEntityExist(ped) then
            FreezeEntityPosition(ped, false) -- Unfreeze après l'animation
        end
        
        EmployeeAnimThreads[labId][employeeId] = nil
    end)
    
    return true
end

-- Export pour vérifier si un employé est en animation
IsEmployeeAnimating = function(labId, employeeId)
    return EmployeeAnimThreads[labId] and EmployeeAnimThreads[labId][employeeId] or false
end
