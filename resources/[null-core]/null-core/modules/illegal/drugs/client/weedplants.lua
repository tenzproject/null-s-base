local seedUsed = false
PlantList = {}
local gender = "femelle"
local RotationToDirection = function(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end
  
local RayCastCamera = function(dist)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = camPos + (dir * dist)
    local ray = StartShapeTestRay(camPos, dest, 17, -1, 0)
    local _, hit, endPos, surfaceNormal, entityHit = GetShapeTestResult(ray)
    if hit == 0 then endPos = dest end
    return hit, endPos, entityHit, surfaceNormal
end

local function IsLocationTooCloseToOtherPlants(coords, minDistance)
    for k,v in pairs(PlantList) do
        local dist = #(vector3(coords.x, coords.y, coords.z) - vector3(v.coords.x, v.coords.y, v.coords.z))
        if dist < minDistance then
            return true
        end
    end
    return false
end

local function FindClosestPlantSpot(coords, plantSpots)
    local closestDist = 1.0
    local closestSpot = nil

    for _, spot in pairs(plantSpots) do
        local dist = #(coords - spot.coords)
        if dist < closestDist then
            local spotTaken = false
            for _, plant in pairs(PlantList) do
                if PlayerState.bucket == plant.bucket then
                    if #(plant.coords - spot.coords) < 0.5 then
                        spotTaken = true
                        break
                    end
                end
            end
            
            if not spotTaken then
                closestDist = dist
                closestSpot = spot
            end
        end
    end
    
    return closestSpot
end

 
local tempPlantProps = {}

local function AddWeedProps(id, model, coords, rotation)
    if PlantList[id] == nil then return end
    if PlantList[id].bucket then
        if PlantList[id].bucket ~= PlayerState.bucket then
            return
        end
    end

    if coords == nil then return end
    if tempPlantProps[id] ~= nil then
        if DoesEntityExist(tempPlantProps[id]) then
            DeleteEntity(tempPlantProps[id])
        end
        tempPlantProps[id] = nil
    end
    tempPlantProps[id] = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, true, true, false)
    if rotation then
        SetEntityRotation(tempPlantProps[id], vec3(rotation.x, rotation.y, rotation.z))
    end
    FreezeEntityPosition(tempPlantProps[id], true)
end

local function DestroyAllWeedProps()
    for k,v in pairs(tempPlantProps) do
        if DoesEntityExist(v) then
            DeleteEntity(v)
        end
    end
end

function InitWeedProps()
    DestroyAllWeedProps()
    for id,data in pairs(PlantList) do
        local ModelHash = Config.WeedPlant.WeedProps[data.stage]
        if data.hasBase == 0 then 
            ModelHash = "bzzz_growing_freepot_a" 
        end
        if data.hasBase == 2 then 
            ModelHash = "bzzz_growing_freepot_b" 
        end
        AddWeedProps(id, ModelHash, data.coords, data.rotation or nil)
    end
end

RegisterNetEvent('null:weed:client:UseWeedSeed', function(rdn)
	TriggerEvent("null:inventory:closeinv")
    if GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 then return end
    if seedUsed then return end
    seedUsed = true 
    local inLabo = PlayerState.Illegals.laboratories.inLabo
    local Labo = nil
    local LaboType = nil
    if inLabo then
        LaboType = null.data.illegals.laboratories.list[inLabo].type
        Labo = Config.laboratoire.type[LaboType]
    end
    local ModelHash = "bzzz_growing_freepot_a"
    RequestModel(ModelHash)
    while not HasModelLoaded(ModelHash) do Wait(0) end
    local hit, dest, _, _ = RayCastCamera(7.0)
    local plant = CreateObject(ModelHash, dest.x, dest.y, dest.z, false, false, false)
    SetEntityCollision(plant, false, false)
    SetEntityAlpha(plant, 150, true)
    local planted = false
    
    while not planted do
        local toClose = false
        hit, dest, _, _ = RayCastCamera(7.0)
        if inLabo and LaboType == "weed" then
            for k,v in pairs(Labo.PlantCoords) do
                DrawMarker(2, v.coords.x, v.coords.y, v.coords.z+1.7, 0.0, 0.0, 0.0, 179.0, 0.0, 0.0, 0.25, 0.25, 0.25, 0, 255, 0, 100, 0, 1, 2, 1, nil, nil, 0)
            end
        end
    
        if hit == 1 then
            if inLabo and LaboType == "weed" then
                -- Dans un labo, on cherche le spot le plus proche
                local closestSpot = FindClosestPlantSpot(vector3(dest.x, dest.y, dest.z), Labo.PlantCoords, null.data.illegals.laboratories.list[inLabo].bucket)
                if closestSpot then
                    SetEntityCoords(plant, closestSpot.coords)
                    SetEntityRotation(plant, closestSpot.rotation)
                    dest = closestSpot.coords
                    toClose = false
                else
                    toClose = true
                end
            elseif inLabo then
                toClose = true
            else
                SetEntityCoords(plant, dest.x, dest.y, dest.z)
                if IsLocationTooCloseToOtherPlants(dest, 1.2) then
                    toClose = true
                else
                    toClose = false
                end
            end

            if IsControlJustPressed(0, 38) then
                if toClose then
                    if inLabo and LaboType == "weed" then
                        ESX.ShowNotification("~r~Vous devez placer la plante sur un emplacement disponible")
                    elseif inLabo then
                        ESX.ShowNotification("~r~Vous devez avoir le meublement pour la Weed.")
                    else
                        ESX.ShowNotification("~r~Trop proche d'une autre plante")
                    end
                else
                    planted = true
                    DeleteObject(plant)
                    local ped = PlayerPedId()
                    RequestAnimDict('amb@medic@standing@kneel@base')
                    RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
                    while not HasAnimDictLoaded('amb@medic@standing@kneel@base') or not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@') do Wait(0) end
                    TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
                    TriggerEvent("progressbar:start", 5500, "Placement du pot")
                    Wait(5500)
                    FreezeEntityPosition(ped, false)
                    if inLabo then
                        if LaboType == "weed" then
                            local closestSpot = FindClosestPlantSpot(vector3(dest.x, dest.y, dest.z), Labo.PlantCoords, null.data.illegals.laboratories.list[inLabo].bucket)
                            if closestSpot then
                                TriggerServerEvent("null:weed:server:CreateNewPlant", closestSpot.coords, rdn, inLabo, closestSpot.rotation)
                                
                                local hasObjective = GetCurrentObjectives()
                                if hasObjective and hasObjective.id == "labo_weed_production" then
                                    LaboTutorial.numberOfWeedPlanted += 1

                                    if LaboTutorial.numberOfWeedPlanted == 2 then
                                        SetObjectiveStep("wait_harvest")
                                    else 
                                        SetObjectiveStep("add_soil")
                                    end
                                end
                            end
                        end
                    else
                        TriggerServerEvent("null:weed:server:CreateNewPlant", dest, rdn)
                    end
                    planted = false
                    seedUsed = false
                    ClearPedTasks(ped)
                    RemoveAnimDict('amb@medic@standing@kneel@base')
                    break
                end
            end
            
            if IsControlJustPressed(0, 47) then
                planted = false
                seedUsed = false
                DeleteObject(plant)
                return
            end
        end
        
        if toClose then
            if inLabo and LaboType == "weed" then
                ESX.ShowHelpNotification("~r~Placez la plante sur un emplacement disponible\n~w~Appuyez sur ~INPUT_PICKUP~ pour planter\nAppuyez sur ~INPUT_DETONATE~ pour annuler")
            elseif inLabo then
                ESX.ShowHelpNotification("~r~Vous devez avoir le meublement pour la Weed.\nAppuyez sur ~INPUT_DETONATE~ pour annuler")
            else
                ESX.ShowHelpNotification("~r~Trop proche d'une autre plante\n~w~Appuyez sur ~INPUT_PICKUP~ pour planter\nAppuyez sur ~INPUT_DETONATE~ pour annuler")
            end
        else
            ESX.ShowHelpNotification("Appuyez sur ~INPUT_PICKUP~ pour planter\nAppuyez sur ~INPUT_DETONATE~ pour annuler")
        end
        Wait(0)
    end
end)
 
RegisterNetEvent('null:weed:client:recevieDataPlant', function(id, data)
    
    -- Vérifier que la plante existe dans PlantList
    if not PlantList[id] then
        null.DebugPrint("[WEED CLIENT] Plant", id, "not found in PlantList, ignoring update")
        return
    end
    
    PlantList[id].displayfertilizer = data.displayfertilizer
	PlantList[id].fertilizer = data.fertilizer
	PlantList[id].displaywater = data.displaywater
	PlantList[id].water = data.water
	PlantList[id].bucket = data.bucket
    if PlantList[id].stage ~= data.stage then
        local ModelHash = Config.WeedPlant.WeedProps[data.stage]
        if data.hasBase == 0 then 
            ModelHash = "bzzz_growing_freepot_a" 
        end
        if data.hasBase == 2 then 
            ModelHash = "bzzz_growing_freepot_b" 
        end
        AddWeedProps(id, ModelHash, data.coords, data.rotation or nil)
    end
    if PlantList[id].hasBase ~= data.hasBase then
        local ModelHash = Config.WeedPlant.WeedProps[data.stage]
        if data.hasBase == 0 then 
            ModelHash = "bzzz_growing_freepot_a" 
        end
        if data.hasBase == 2 then 
            ModelHash = "bzzz_growing_freepot_b" 
        end
        AddWeedProps(id, ModelHash, data.coords, data.rotation or nil)
    end
	PlantList[id].stage = data.stage
	PlantList[id].health = data.health
	PlantList[id].growth = data.growth
	PlantList[id].gender = data.gender
	PlantList[id].hasBase = data.hasBase
end)
 
RegisterNetEvent('null:weed:client:recevie', function(data)
    null.fct.safe.wait(function() 
        for k,v in pairs(PlantList) do
            if Exist3DInteraction("weedplant_"..v.id) then 
                Remove3DInteraction("weedplant_"..v.id)
            end
        end
    end)
    
	PlantList = data
    for k,v in pairs(data) do
        CreateWeedPlantInteraction2(v)
    end
    InitWeedProps()
end)

RegisterNetEvent('null:weed:client:recevieNew', function(id, data)
	PlantList[id] = data
    CreateWeedPlantInteraction2(data)

    local ModelHash = Config.WeedPlant.WeedProps[data.stage]
    if data.hasBase == 0 then 
        ModelHash = "bzzz_growing_freepot_a" 
    end
    if data.hasBase == 2 then 
        ModelHash = "bzzz_growing_freepot_b" 
    end
    AddWeedProps(id, ModelHash, data.coords, data.rotation or nil)
end)
 
RegisterNetEvent("null:player:bucketChanged", function(bucket)
    InitWeedProps()
end)

Citizen.CreateThread(function()
    local loopWait = 2000
    Wait(5000)
    TriggerServerEvent('null:weed:server:load')
end)

function GetPlantStats(id, data)
    if PlantList[id] == nil then return nil end
    if data == nil then return PlantList[id] end
    return PlantList[id][data]
end

exports("GetPlantStats", GetPlantStats)

exports("GetPlayerInventaire", function()
    return ESX.PlayerData.inventory
end)

function CreateWeedPlantInteraction2(data)
    local id = data.id
    if PlantList[id] == nil then return end
    if Exist3DInteraction("weedplant_"..data.id) then return end
    
    if data.owner.idunique == ESX.PlayerData.idunique and not data.inLabo then
        ESX.addBlips({
            name = 'plant_'..data.id,
            label = "Plante de weed",
            category = nil,
            position = null.fct.JsonCoordsToVect3(data.coords),
            sprite = 469,
            display = 4,
            scale = 0.60,
            color = 2
        })
    end
 
    null.fct.utils.CreateZoneFunction("weed_plant_"..data.id, 
        "circle", -- type
        vector3(data.coords.x,data.coords.y,data.coords.z+0.4),  -- coords
        function() 
            local hasSuit = GetPlayerKey("suit")
            local hasBase = GetPlantStats(data.id, "hasBase")
            if hasSuit ~= "hazmat" and hasBase ~= 0 and hasBase ~= 2 then
                TriggerServerEvent("null:smells:updateSmell", 3, "weed")
                TriggerServerEvent("null:smells:setInSmellZone", "weed")
            end
        end, -- function execute
        10*1000, -- time (miliseconde)
        5.0 -- radius  
    )   
    Citizen.CreateThread(function()
        --while GetResourceState("null-ui") ~= "started" do Wait(200) end
        Add3DInteraction({
            id = "weedplant_"..data.id,
            type = "multi",
            bucket = data.bucket,
            coords = vector3(data.coords.x,data.coords.y,data.coords.z+0.4),
            maxDistance = 1.2,
            maxDistance2 = 0.9,
            everytime = {
                [15000] = function()
                    local result = GetPlantStats(id)
                    if result == nil then return end
                    TriggerServerEvent("null:weed:requestPlantData", result.id)
                end,
            },
            text = {
                title = "Gestion Plante de Weed",
                lines = {
                    {
                        left = "Date", 
                        rightAreFunction = true,
                        right = function(cb)
                            local result = GetPlantStats(id, "date")
                            cb(result)
                        end
                    },
                    {
                        left = "Croissance", 
                        rightAreFunction = true,
                        right = function(cb)
                            local result = GetPlantStats(id, "growth")
                            cb(tostring(result).."%")
                        end,
                        canSee = function(cb)
                            local result = GetPlantStats(id)
                            if result == nil then cb(false) return end
                            if result.hasBase ~= 1 then 
                                cb(false)
                            else
                                cb(true)
                            end
                        end
                    },
                    {
                        left = "Stage", 
                        rightAreFunction = true,
                        right = function(cb)
                            local result = GetPlantStats(id, "stage")
                            cb(tostring(result).."/5")
                        end,
                        canSee = function(cb)
                            local result = GetPlantStats(id)
                            if result == nil then cb(false) return end
                            if result.hasBase ~= 1 then 
                                cb(false)
                            else
                                cb(true)
                            end
                        end
                    },
                    {
                        left = "Genre", 
                        rightAreFunction = true,
                        right = function(cb)
                            local result = GetPlantStats(id, "gender")
                            if result == "female" then 
                                cb("Femelle")
                            elseif result == "male" then
                                cb("Mâle")
                            end
                        end,
                        canSee = function(cb)
                            local result = GetPlantStats(id)
                            if result == nil then cb(false) return end
                            if result.hasBase ~= 1 then 
                                cb(false)
                            else
                                cb(true)
                            end
                        end
                    },
                    {
                        left = "Vie", 
                        rightAreFunction = true,
                        right = function(cb)
                            local result = GetPlantStats(id, "health")
                            cb(tostring(result).."%")
                        end,
                        canSee = function(cb)
                            local result = GetPlantStats(id)
                            if result == nil then cb(false) return end
                            if result.hasBase ~= 1 then 
                                cb(false)
                            else
                                cb(true)
                            end
                        end
                    },
                    {
                        left = "Eau", 
                        rightAreFunction = true,
                        right = function(cb)
                            local result = GetPlantStats(id, "displaywater")
                            cb(tostring(result).."%")
                        end,
                        canSee = function(cb)
                            local result = GetPlantStats(id)
                            if result == nil then cb(false) return end
                            if result.hasBase ~= 1 then 
                                cb(false)
                            else
                                cb(true)
                            end
                        end
                    },
                    {
                        left = "Engrais", 
                        rightAreFunction = true,
                        right = function(cb)
                            local result = GetPlantStats(id, "displayfertilizer")
                            cb(tostring(result).."%")
                        end,
                        canSee = function(cb)
                            local result = GetPlantStats(id)
                            if result == nil then cb(false) return end
                            if result.hasBase ~= 1 then 
                                cb(false)
                            else
                                cb(true)
                            end
                        end
                    },


                    --[[ Principales Actions :
                    Récuperer le pot           G
                    Récolter la weed           E
                    Ajouter de l'Eau           F
                    Ajouter de l'engrais       E
                    Ajouter une graine mâle    H
                    Retirer les graines mâle   H
                    Ajouter de la terre        E
                    Ajouter une graine femelle E
                    ]]


                    {
                        left = "Récuperer le pot", 
                        key = "G", 
                        action = function() 
                            if not null.fct.confirm("Voulez-vous vraiment récuperer cette plante ?") then return end

                            local oldCam = GetFollowPedCamViewMode()
                            --SetFollowPedCamViewMode(4)
                            null.DisplayHud("3dinteractions", false)
                            local ped = PlayerPedId()
                            local plantEntity = tempPlantProps[id]
                            if not plantEntity or plantEntity == 0 then 
                            else
                                TaskTurnPedToFaceEntity(ped, plantEntity, -1)
                            end
                            Wait(1000)
                            RequestAnimDict('amb@medic@standing@kneel@base')
                            RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
                            while not HasAnimDictLoaded('amb@medic@standing@kneel@base') or not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@') do Wait(0) end
                            TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
                            --TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)
                            FreezeEntityPosition(ped, true)
                            Wait(12500)
                            FreezeEntityPosition(ped, false)
                            ClearPedTasks(ped)
                            RemoveAnimDict('amb@medic@standing@kneel@base')
                            --RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                            null.DisplayHud("3dinteractions", true)
                            --SetFollowPedCamViewMode(oldCam)
                            TriggerServerEvent("null:weed:removePlantPot", id)
                            Remove3DInteraction("weedplant_"..id)
                        end,
                        canSee = function(cb)
                            local result = GetPlantStats(id)
                            if result == nil then cb(false) return end
                            if ESX.PlayerData.idunique == nil then 
                                cb(false) 
                                return
                            end
                            --if ESX.PlayerData.idunique ~= result.owner.idunique then cb(false) end
                            if result.hasBase == 1 then 
                                cb(false) 
                                return
                            end
                            cb(true)
                            return
                        end,
                    },
                    {
                        left = "Récolter la weed", 
                        key = "E", 
                        action = function() 
                            local result = GetPlantStats(id)
                            if not result then return end
                            if exports["null-core"]:IsSceneOpen() then return end
 
                            if not null.fct.confirm("Voulez-vous vraiment récuperer cette plante ?") then return end

                            null.DisplayHud("3dinteractions", false)

                            local plantCoords = result.coords
                            local origin = vector3(plantCoords.x, plantCoords.y, plantCoords.z)

                            -- Nombre de buds basé sur la santé (même formule que le serveur)
                            local nbrBuds = math.floor(result.health / 20)
                            if nbrBuds <= 0 then nbrBuds = 1 end
                            if nbrBuds > 5 then nbrBuds = 5 end

                            -- Positions des buds sur la plante (variées)
                            local budOffsets = {
                                vector3(0.0,   0.05,  1.4),
                                vector3(0.15, -0.05,  1.25),
                                vector3(-0.12, 0.08,  1.8),
                                vector3(0.05, -0.12,  1.7),
                                vector3(-0.08, -0.08, 0.6),
                            }

                            -- Construire les props et zones dynamiquement
                            local props = {}
                            local zones = {}
                            local cutsRemaining = nbrBuds

                            for i = 1, nbrBuds do
                                local off = budOffsets[i] or vector3(0.0, 0.0, 0.5)
                                zones[#zones + 1] = {
                                    id = "bud_" .. i,
                                    offset = vector3(0.0, 0.0, 0.05),
                                    label = "Branche",
                                    icon = "leaf",
                                    state = "highlight",
                                    pulse = true,
                                    actions = {
                                        {
                                            id = "cut",
                                            label = "Couper",
                                            type = "hold",
                                            duration = 2500,
                                            requiredTool = "drugs_scissors",
                                            animation = { dict = "amb@world_human_gardener_plant@male@base", name = "base", flags = 49 },
                                        },
                                    },
                                }
                            end

                            local plantId = result.id
 
                            exports["null-core"]:OpenPropScene({
                                id = "weed_harvest_" .. plantId,
                                title = "Récolter la Weed",
                                subtitle = "Utilisez les ciseaux pour couper les branches contenant beaucoup de tête.",
                                color = "#22c55e",
                                origin = origin,

                                camera = {
                                    lookAt = vector3(origin.x, origin.y, origin.z + 0.6),
                                    distance = 1.8,
                                    heightOffset = 0.5,
                                    lookAtHeightOffset = 0.1,
                                    fov = 45.0,
                                },

                                tools = {
                                    { id = "drugs_scissors", label = "Ciseaux", icon = "drugs_scissors", description = "Couper les têtes de weed" },
                                },
                                zones = zones,
                                items = {},

                                onZoneAction = function(zoneId, actionId, actionType, toolId)
                                    if actionType == "hold_complete" and actionId == "cut" then
                                        exports["null-core"]:UpdateZoneState(zoneId, "completed", false)

                                        local budPropId = zoneId:gsub("bud_", "bud_prop_")
                                        exports["null-core"]:DeleteSceneProp(budPropId)

                                        --exports["null-core"]:AddResult({ id = "weed_head", label = "Branche de weed", count = 1 })
                                        --exports["null-core"]:SendSceneNotification("Branches coupée !", "success")

                                        cutsRemaining = cutsRemaining - 1
                                        if cutsRemaining <= 0 then
                                            Citizen.SetTimeout(1500, function()
                                                --exports["null-core"]:SendSceneNotification("Récolte terminée !", "success")
                                                TriggerServerEvent("null:weed:harvest", plantId)
                                                Citizen.SetTimeout(2000, function()
                                                    exports["null-core"]:ClosePropScene()
                                                    null.DisplayHud("3dinteractions", true)
                                                end)
                                            end)
                                        end
                                    end
                                end,

                                onClose = function()
                                    null.DisplayHud("3dinteractions", true)
                                end,
                            })
                        end,
                        canSee = function(cb)
                            local result = GetPlantStats(id)
                            if result == nil then cb(false) return end
                            local inventory = exports["null-core"]:GetPlayerInventaire()
                            if result.growth ~= 100 or result.hasBase ~= 1 then 
                                cb(false)
                                return
                            else
                                local found = false
                                for k,v in pairs(inventory) do 
                                    if v.name == "drugs_scissors" and v.count >= 1 then 
                                        found = true 
                                    end 
                                end
                                if found then
                                    cb(true)
                                    return
                                else
                                    cb(false)
                                    return
                                end
                            end
                        end
                    },
                    {
                        left = "Ajouter de l'Eau", 
                        key = "F", 
                        action = function() 
                            null.DisplayHud("3dinteractions", false)
                            local oldCam = GetFollowPedCamViewMode()
                            --SetFollowPedCamViewMode(4)
                            local ped = PlayerPedId()
                            local coords = GetEntityCoords(ped)
                            local result = GetPlantStats(id)
                            local plantEntity = tempPlantProps[id]
                            if not plantEntity or plantEntity == 0 then 
                            else
                                TaskTurnPedToFaceEntity(ped, plantEntity, -1)
                            end
                            Wait(1000)
                            local model = `prop_wateringcan`
                            Wait(1500)
                            RequestModel(model)
                            RequestNamedPtfxAsset('core')
                            while not HasModelLoaded(model) or not HasNamedPtfxAssetLoaded('core') do Wait(0) end
                            SetPtfxAssetNextCall('core')
                            local created_object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
                            AttachEntityToEntity(created_object, ped, GetPedBoneIndex(ped, 28422), 0.4, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)
                            local effect = StartParticleFxLoopedOnEntity('ent_sht_water', created_object, 0.35, 0.0, 0.25, 0.0, 0.0, 0.0, 2.0, false, false, false)
                            RequestAnimDict('weapon@w_sp_jerrycan')
                            while not HasAnimDictLoaded('weapon@w_sp_jerrycan') do Wait(0) end
                            FreezeEntityPosition(ped, true)
                            TaskPlayAnim(ped, 'weapon@w_sp_jerrycan', 'fire', 8.0, 8.0, -1, 1, 0, false, false, false)
                            TriggerEvent("progressbar:start", 12500, "Ajout d'eau")
                            Wait(12500)
                            FreezeEntityPosition(ped, false)
                            TriggerServerEvent("null:weed:add", id, "water")
                            ClearPedTasks(ped)
                            DeleteEntity(created_object)
                            StopParticleFxLooped(effect, 0)
                            --SetFollowPedCamViewMode(oldCam)
                            null.DisplayHud("3dinteractions", true)
                            TriggerServerEvent("null:weed:requestPlantData", id)
                        end,
                        canSee = function(cb)
                            local result = GetPlantStats(id)
                            if result == nil then cb(false) return end
                            local inventory = exports["null-core"]:GetPlayerInventaire()
                            if ESX.PlayerData.idunique == nil then 
                                cb(false) 
                                return
                            end
                            --if ESX.PlayerData.idunique ~= result.owner.idunique then cb(false) end
                            local found = true
                            for k,v in pairs(inventory) do 
                                if v.name == "water-canister" and v.count >= 1 then 
                                    found = true 
                                    break 
                                end 
                            end 
                            if not found then 
                                cb(false, "Vous n'avez pas d'eau sur vous.") 
                                return
                            end
                            if result.hasBase ~= 1 then  
                                cb(false) 
                                return
                            end
                            if result.growth == 100 then 
                                cb(false) 
                                return
                            end
                            cb(true)
                            return
                        end
                    },
                    {
                        left = "Ajouter de l'engrais", 
                        key = "E", 
                        action = function() 
                            null.DisplayHud("3dinteractions", false)
                            local oldCam = GetFollowPedCamViewMode()
                            --SetFollowPedCamViewMode(4)
                            local ped = PlayerPedId()
                            local coords = GetEntityCoords(ped)
                            local result = GetPlantStats(id)
                            local plantEntity = tempPlantProps[id]
                            if not plantEntity or plantEntity == 0 then 
                            else
                                TaskTurnPedToFaceEntity(ped, plantEntity, -1)
                            end
                            Wait(1000)
                            local model = `w_am_jerrycan_sf`
                            Wait(1500)
                            RequestModel(model)
                            RequestNamedPtfxAsset('core')
                            while not HasModelLoaded(model) or not HasNamedPtfxAssetLoaded('core') do Wait(0) end
                            SetPtfxAssetNextCall('core')
                            local created_object = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
                            AttachEntityToEntity(created_object, ped, GetPedBoneIndex(ped, 28422), 0.3, 0.1, 0.0, 90.0, 180.0, 0.0, true, true, false, true, 1, true)
                            local effect = StartParticleFxLoopedOnEntity('ent_sht_water', created_object, 0.35, 0.0, 0.25, 0.0, 0.0, 0.0, 2.0, false, false, false)
                            RequestAnimDict('weapon@w_sp_jerrycan')
                            while not HasAnimDictLoaded('weapon@w_sp_jerrycan') do Wait(0) end
                            FreezeEntityPosition(ped, true)
                            TaskPlayAnim(ped, 'weapon@w_sp_jerrycan', 'fire', 8.0, 8.0, -1, 1, 0, false, false, false)
                            TriggerEvent("progressbar:start", 12500, "Ajout de l'engrais")
                            Wait(12500)
                            FreezeEntityPosition(ped, false)
                            TriggerServerEvent("null:weed:add", id, "fertilizer")
                            ClearPedTasks(ped)
                            DeleteEntity(created_object)
                            StopParticleFxLooped(effect, 0)
                            --SetFollowPedCamViewMode(oldCam)
                            null.DisplayHud("3dinteractions", true)
                            TriggerServerEvent("null:weed:requestPlantData", id)
                        end,
                        canSee = function(cb)
                            local result = GetPlantStats(id)
                            if result == nil then cb(false) return end
                            local inventory = exports["null-core"]:GetPlayerInventaire()
                            if ESX.PlayerData.idunique == nil then 
                                cb(false) 
                                return
                            end
                            --if ESX.PlayerData.idunique ~= result.owner.idunique then cb(false) end
                            local found = true
                            for k,v in pairs(inventory) do 
                                if v.name == "fertilizer" and v.count >= 1 then found = true break end end if not found then 
                                cb(false, "Vous n'avez pas d'engrais sur vous.") 
                                return
                            end
                            if result.hasBase ~= 1 then 
                                cb(false) 
                                return
                            end
                            if result.growth == 100 then 
                                cb(false) 
                                return
                            end
                            cb(true)
                            return
                        end
                    },
                    {
                        left = "Ajouter une graine mâle", 
                        key = "H", 
                        action = function() 
                            if not null.fct.confirm() then return end
                            local oldCam = GetFollowPedCamViewMode()
                            null.DisplayHud("3dinteractions", false)
                            --SetFollowPedCamViewMode(4)
                            local ped = PlayerPedId()
                            local result = GetPlantStats(id)
                            local plantEntity = tempPlantProps[id]
                            if not plantEntity or plantEntity == 0 then 
                            else
                                TaskTurnPedToFaceEntity(ped, plantEntity, -1)
                            end
                            Wait(1000)
                            RequestAnimDict('amb@medic@standing@kneel@base')
                            RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
                            while not HasAnimDictLoaded('amb@medic@standing@kneel@base') or not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@') do Wait(0) end
                            TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
                            --TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)
                            TriggerEvent("progressbar:start", 5500, "Ajout de la graine male")
                            FreezeEntityPosition(ped, true)
                            Wait(5500)
                            FreezeEntityPosition(ped, false)
                            TriggerServerEvent("null:weed:add", result.id, "weed-seed-male")
                            ClearPedTasks(ped)
                            RemoveAnimDict('amb@medic@standing@kneel@base')
                            --RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                            --SetFollowPedCamViewMode(oldCam)
                            null.DisplayHud("3dinteractions", true)
                            TriggerServerEvent("null:weed:requestPlantData", id)
                        end,
                        canSee = function(cb)
                            local result = GetPlantStats(id)
                            if result == nil then cb(false) return end
                            local inventory = exports["null-core"]:GetPlayerInventaire()
                            if ESX.PlayerData.idunique == nil then 
                                cb(false) 
                                return
                            end
                            
                            local found = true
                            for k,v in pairs(inventory) do 
                                if v.name == "weed-seed-male" and v.count >= 1 then 
                                    found = true 
                                    break 
                                end 
                            end 
                            if not found then 
                                cb(false, "Vous n'avez pas de graine mâle sur vous.")
                                return
                            end
                            if result.hasBase ~= 1 then 
                                cb(false)
                                return
                            end
                            if result.gender == "male" then 
                                cb(false)
                                return
                            end
                            if result.growth == 100 then 
                                cb(false)
                                return
                            end
                            cb(true)
                        end
                    },
                    {
                        left = "Retirer les graines mâle", 
                        key = "H", 
                        action = function() 
                            if not null.fct.confirm() then return end
                            local oldCam = GetFollowPedCamViewMode()
                            local result = GetPlantStats(id)
                            null.DisplayHud("3dinteractions", false)
                            --SetFollowPedCamViewMode(4)
                            local ped = PlayerPedId()
                            local result = GetPlantStats(id)
                            local plantEntity = tempPlantProps[id]
                            if not plantEntity or plantEntity == 0 then 
                            else
                                TaskTurnPedToFaceEntity(ped, plantEntity, -1)
                            end
                            Wait(1000)
                            RequestAnimDict('amb@medic@standing@kneel@base')
                            RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
                            while not HasAnimDictLoaded('amb@medic@standing@kneel@base') or not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@') do Wait(0) end
                            TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
                            --TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)
                            FreezeEntityPosition(ped, true)
                            TriggerEvent("progressbar:start", 5000, "Récuperation des graines male")
                            Wait(5000)
                            FreezeEntityPosition(ped, false)
                            TriggerServerEvent("null:weed:add", result.id, "weed-seed-female")
                            ClearPedTasks(ped)
                            RemoveAnimDict('amb@medic@standing@kneel@base')
                            --RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                            --exports.ox_target:disableTargeting(false)
                            --SetFollowPedCamViewMode(oldCam)
                            null.DisplayHud("3dinteractions", true)
                            TriggerServerEvent("null:weed:requestPlantData", id)
                        end,
                        canSee = function(cb)
                            local result = GetPlantStats(id)
                            if result == nil then cb(false) return end
                            if result == nil then cb(false) return end
                            local inventory = exports["null-core"]:GetPlayerInventaire()
                            if ESX.PlayerData.idunique == nil then 
                                cb(false) 
                                return
                            end
                            if result.hasBase == 0 then 
                                cb(false)
                                return
                            end
                            if result.gender == "female" then 
                                cb(false)
                                return
                            end
                            if result.growth == 100 then 
                                cb(false)
                                return
                            end
                            cb(true)
                        end
                    },
                    {
                        left = "Ajouter de la terre", 
                        key = "E", 
                        action = function()
                            local oldCam = GetFollowPedCamViewMode()
                            local result = GetPlantStats(id)
                            --SetFollowPedCamViewMode(4)
                            null.DisplayHud("3dinteractions", false)
                            local ped = PlayerPedId()
                            local result = GetPlantStats(id)
                            local plantEntity = tempPlantProps[id]
                            if not plantEntity or plantEntity == 0 then 
                            else
                                TaskTurnPedToFaceEntity(ped, plantEntity, -1)
                            end
                            Wait(1000)
                            RequestAnimDict('amb@medic@standing@kneel@base')
                            RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
                            while not HasAnimDictLoaded('amb@medic@standing@kneel@base') or not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@') do Wait(0) end
                            TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
                            TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)
                            TriggerEvent("progressbar:start", 12500, "Ajout de la terre")
                            FreezeEntityPosition(ped, true)
                            Wait(12500)
                            TriggerServerEvent("null:weed:upgrade:PlaceDirt", result.id)

                            local hasObjective = GetCurrentObjectives()
                            if hasObjective and hasObjective.id == "labo_weed_production" then
                                SetObjectiveStep("plant_seed")
                            end

                            FreezeEntityPosition(ped, false)
                            ClearPedTasks(ped)
                            RemoveAnimDict('amb@medic@standing@kneel@base')
                            RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                            --SetFollowPedCamViewMode(oldCam)
                            null.DisplayHud("3dinteractions", true)
                            TriggerServerEvent("null:weed:requestPlantData", id)
                        end,
                        canSee = function(cb)
                            local result = GetPlantStats(id)
                            if result == nil then cb(false) return end
                            local inventory = exports["null-core"]:GetPlayerInventaire()
                            if ESX.PlayerData.idunique == nil then 
                                cb(false) 
                                return
                            end
                            --if ESX.PlayerData.idunique ~= result.owner.idunique then cb(false) end
                            local found = 0
                            for k,v in pairs(inventory) do 
                                if v.name == "earthbag" and v.count >= 1 then 
                                    found = found + 1
                                end 
                            end 
                            if found < 1 then 
                                cb(false, "Vous n'avez pas de terre sur vous.") 
                                return
                            end
                            if result.hasBase == 1 then 
                                cb(false) 
                                return
                            end
                            if result.hasBase == 2 then 
                                cb(false) 
                                return
                            end
                            cb(true)
                            return
                        end
                    },
                    {
                        left = "Ajouter une graine femelle", 
                        key = "E", 
                        action = function() 
                            local oldCam = GetFollowPedCamViewMode()
                            --SetFollowPedCamViewMode(4)
                            null.DisplayHud("3dinteractions", false)
                            local ped = PlayerPedId()
                            local result = GetPlantStats(id)
                            local plantEntity = tempPlantProps[id]
                            if not plantEntity or plantEntity == 0 then 
                            else
                                TaskTurnPedToFaceEntity(ped, plantEntity, -1)
                            end
                            Wait(1000)
                            RequestAnimDict('amb@medic@standing@kneel@base')
                            RequestAnimDict('anim@gangops@facility@servers@bodysearch@')
                            while not HasAnimDictLoaded('amb@medic@standing@kneel@base') or not HasAnimDictLoaded('anim@gangops@facility@servers@bodysearch@') do Wait(0) end
                            TaskPlayAnim(ped, 'amb@medic@standing@kneel@base', 'base', 8.0, 8.0, -1, 1, 0, false, false, false)
                            --TaskPlayAnim(ped, 'anim@gangops@facility@servers@bodysearch@', 'player_search', 8.0, 8.0, -1, 48, 0, false, false, false)
                            TriggerEvent("progressbar:start", 12500, "Ajout des graines")
                            FreezeEntityPosition(ped, true)
                            Wait(12500)
                            TriggerServerEvent("null:weed:upgrade:PlantSeed", result.id)
                            local hasObjective = GetCurrentObjectives()
                            if hasObjective and hasObjective.id == "labo_weed_production" then
                                SetObjectiveStep("nurture_plant")
                            end
                            FreezeEntityPosition(ped, false)
                            ClearPedTasks(ped)
                            RemoveAnimDict('amb@medic@standing@kneel@base')
                            --RemoveAnimDict('anim@gangops@facility@servers@bodysearch@')
                            --SetFollowPedCamViewMode(oldCam)
                            null.DisplayHud("3dinteractions", true)
                            TriggerServerEvent("null:weed:requestPlantData", id)
                        end,
                        canSee = function(cb)
                            local result = GetPlantStats(id)
                            if result == nil then cb(false) return end
                            local inventory = exports["null-core"]:GetPlayerInventaire()
                            if ESX.PlayerData.idunique == nil then 
                                cb(false) 
                                return
                            end
                            --if ESX.PlayerData.idunique ~= result.owner.idunique then cb(false) end
                            local found = 0
                            for k,v in pairs(inventory) do 
                                if v.name == "weed-seed-female" and v.count >= 1 then 
                                    found = found + 1
                                end 
                            end 
                            if found < 1 then 
                                cb(false, "Vous n'avez pas de graine femelle sur vous.") 
                                return
                            end
                            if result.hasBase == 0 then 
                                cb(false) 
                                return
                            end
                            if result.hasBase == 1 then 
                                cb(false) 
                                return
                            end
                            cb(true)
                            return
                        end
                    },
                }
            },
            canSee = function(cb)
                if PlayerState.Illegals.laboratories.inLabo == false then
                    cb(true)
                    return
                end
                if not HasLaboPermissions(PlayerState.Illegals.laboratories.inLabo, "harvest_weed") then
                    cb(false)
                    return
                end
                cb(true)
            end,
        })
    end)
end