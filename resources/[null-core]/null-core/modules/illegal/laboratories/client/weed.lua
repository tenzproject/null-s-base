
DryProps = {}
local DryingWeedList = {"bkr_prop_weed_drying_01a", "bkr_prop_weed_drying_02a"}
function SetupLaboDry(id, destory)
    if destory then
        for k,v in pairs(DryProps) do DeleteEntity(v) end
        DryProps = {}
    end

    if id == nil then return end
    if PlayerState.Illegals.laboratories.inLabo ~= id then return end
    local data = null.data.illegals.laboratories.list[id]
    if data == nil then return end
    if data.type ~= "weed" then return end
    if data.treatmentequipment.indrying == nil then return end

    local nbrToSpawn = ESX.Table.SizeOf(data.treatmentequipment.indrying)
    local nbrSpawn = 0
    for k,v in pairs(DryProps) do
        if k > nbrToSpawn then
            DryProps[k] = nil
            DeleteEntity(v)
        else
            nbrSpawn += 1
        end
    end

    if nbrSpawn < nbrToSpawn then
        local newSpawnNbr = nbrToSpawn - nbrSpawn
        for i = 1, newSpawnNbr do
            local positondata = Config.laboratoire.type["weed"].treatmentequipment.DryPlantsCoords[nbrSpawn+i]
            local entityid = nbrSpawn+i
            local entitymodel = DryingWeedList[math.random(1,2)]
            if positondata then
                DryProps[entityid] = CreateObjectNoOffset(entitymodel, positondata.coords.x, positondata.coords.y, positondata.coords.z, true, true, false)
                FreezeEntityPosition(DryProps[entityid], true)
                SetEntityRotation(DryProps[entityid], vec3(positondata.rotation.x, positondata.rotation.y, positondata.rotation.z))
            end
        end
    end
end

function DestoryLaboDry()
    for k,v in pairs(DryProps) do 
        if DoesEntityExist(v) then
            DeleteEntity(v) 
        end
    end
    DryProps = {}
end

function SetupWeedLabo(id)
    local data = null.data.illegals.laboratories.list[id]
    if data.type ~= "weed" then return end

    if data.upgrades["treatment-equipment"] then
        LadderEntity = CreateObject(GetHashKey('prop_paint_stepl01'), Config.laboratoire.type[data.type].treatmentequipment.DryStair.pos, true)
        FreezeEntityPosition(LadderEntity, true)
        SetEntityRotation(LadderEntity, Config.laboratoire.type[data.type].treatmentequipment.DryStair.rotation)
        Add3DInteraction({
            id = "labo_"..id.."_inside_treatment_dry",
            coords = Config.laboratoire.type[data.type].treatmentequipment.dry,
            bucket = data.instance,
            type = "multi", 
            text = {
                title = "Séchage",
                lines = {
                    {
                        left = "Plante en séchages",
                        rightAreFunction = true,
                        right = function(cb)
                            local result = GetLaboInfo(id)
                            local nbr = 0
                            for k,v in pairs(result.treatmentequipment.indrying) do nbr += 1 end
                            local nbrMax = 0
                            for k,v in pairs(Config.laboratoire.type["weed"].treatmentequipment.DryPlantsCoords) do nbrMax += 1 end
                            cb(tostring(nbr).."/"..nbrMax)
                        end
                    },
                    {
                        left = "Sécher une plante",
                        key = "E",
                        action = function() 
                            local result = exports["null-core"]:GetLaboInfo(id)
                            local nbr = 0
                            for k,v in pairs(result.treatmentequipment.indrying) do nbr += 1 end
                            local nbrMax = 0
                            for k,v in pairs(Config.laboratoire.type["weed"].treatmentequipment.DryPlantsCoords) do nbrMax += 1 end
                            if nbr >= nbrMax then return end

                            local canAction = ActionCooldown("sendDryWeed", 1000, false)
                            if canAction then
                                TriggerServerEvent("null:labo:dryweed", id)

                                local inventory = exports["null-core"]:GetPlayerInventaire()
                                local count = 0
                                for k,v in pairs(inventory) do 
                                    if v.name == Config.laboratoire.type["weed"].items["plant"] and v.count >= 1 then 
                                        count = v.count
                                        break
                                    end 
                                end

                                local hasObjective = GetCurrentObjectives()
                                if hasObjective and hasObjective.id == "weed_processing" and (count-1 == 0) then
                                    SetObjectiveStep("wait_drying")
                                end
                            end
                        end,
                        canSee = function(cb)
                            local result = exports["null-core"]:GetLaboInfo(id)
                            local nbr = 0
                            for k,v in pairs(result.treatmentequipment.indrying) do nbr += 1 end
                            local nbrMax = 0
                            for k,v in pairs(Config.laboratoire.type["weed"].treatmentequipment.DryPlantsCoords) do nbrMax += 1 end
                            if nbr >= nbrMax then
                                cb(false)
                            else
                                local inventory = exports["null-core"]:GetPlayerInventaire()
                                local found = false
                                for k,v in pairs(inventory) do 
                                    if v.name == Config.laboratoire.type["weed"].items["plant"] and v.count >= 1 then 
                                        found = true 
                                    end 
                                end
                                if found then
                                    cb(true)
                                else
                                    cb(false)
                                end
                            end
                        end
                    },
                    {
                        left = "Récolter les plantes séches",
                        key = "F",
                        action = function() 
                            local result = exports["null-core"]:GetLaboInfo(id)
                            local nbr = 0
                            for k,v in pairs(result.treatmentequipment.indrying) do 
                                if v.finish then
                                    nbr += 1 
                                end
                            end
                            if nbr > 0 then
                                local canAction = ActionCooldown("sendRecolteDryWeed", 500, false)
                                if canAction then
                                    TriggerServerEvent("null:labo:recoltedryweed", id)

                                    local hasObjective = GetCurrentObjectives()
                                    if hasObjective and hasObjective.id == "weed_processing" then
                                        SetObjectiveStep("trim_and_pack")
                                    end
                                end 
                            end
                        end,
                        canSee = function(cb)
                            local result = exports["null-core"]:GetLaboInfo(id)
                            local nbr = 0
                            for k,v in pairs(result.treatmentequipment.indrying) do 
                                if v.finish then
                                    nbr += 1 
                                end
                            end
                            if nbr <= 0 then
                                cb(false)
                            else
                                cb(true)
                            end
                        end
                    },
                }
            },
            canSee = function(cb)
                if not HasLaboPermissions(id, "process_weed") then
                    cb(false)
                    return
                end
                cb(true)
            end, 
            maxDistance = 5.0,
            maxDistance2 = 1.2,
            key = "E"
        })
        for k,v in pairs(Config.laboratoire.type[data.type].treatmentequipment.cuts) do
            local InteractId = "labo_"..id.."_inside_treatment-equipment_"..k 
            if Exist3DInteraction(InteractId) then
                Remove3DInteraction(InteractId)
            end
            if v.chairProps then
                local tempID = #ChairsEntity+1
                ChairsEntity[tempID] = CreateObject(GetHashKey('gr_prop_gr_chair02_ped'), vector3(v.chairProps.coords.x, v.chairProps.coords.y, v.chairProps.coords.z), true)
                FreezeEntityPosition(ChairsEntity[tempID], true)
                SetEntityRotation(ChairsEntity[tempID], v.chairProps.rotation)
            end
            CreatedTreatementInteract[k] = InteractId
            Add3DInteraction({
                id = InteractId,
                type = "multi",
                coords = vec3(v.coords.x, v.coords.y, v.coords.z),
                bucket = data.instance,
                maxDistance = 3.5,
                maxDistance2 = 1.2,
                canSee = function(cb)
                    if not HasLaboPermissions(id, "process_weed") then
                        cb(false)
                        return
                    end
                    cb(true)
                end,
                text = {
                    title = "Traitement Weed",
                    lines = {
                        {
                            left = "Couper les têtes",
                            key = "E",
                            action = function()
                                if exports["null-core"]:GetAreCuting() then return end
                                if exports["null-core"]:IsSceneOpen() then return end

                                local origin = v.tableOrigin or vec3(v.coords.x, v.coords.y, v.coords.z)

                                local nbrBuds = math.random(3, 5)

                                local dryModels = { "bkr_prop_weed_drying_01a", "bkr_prop_weed_drying_02a" }
                                local dryModel = dryModels[math.random(1, #dryModels)]

                                local allProps = {
                                    {
                                        id = "dried_plant",
                                        model = dryModel,
                                        offset = vector3(0.0, 0.0, 0.02),
                                        rotation = vector3(90.0, 0.0, math.random(0, 360)),
                                    },
                                }

                                local budOffsets = {
                                    vector3(-0.15, 0.08, 0.08),
                                    vector3( 0.10, -0.05, 0.10),
                                    vector3(-0.05, -0.10, 0.07),
                                    vector3( 0.18, 0.06, 0.09),
                                    vector3(-0.20, -0.02, 0.06),
                                }

                                local allZones = {}
                                for i = 1, nbrBuds do
                                    local off = budOffsets[i] or vector3(0.0, 0.0, 0.08)
                                    allProps[#allProps + 1] = {
                                        id = "bud_prop_" .. i,
                                        model = "bkr_prop_weed_bud_pruned_01a",
                                        offset = off,
                                        placeOnGround = false,
                                    }
                                    allZones[#allZones + 1] = {
                                        id = "bud_" .. i,
                                        propId = "bud_prop_" .. i,
                                        offset = vector3(0.0, 0.0, 0.05),
                                        label = "Tête #" .. i,
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

                                local cutsRemaining = nbrBuds
                                local isFirstCut = true
                                local laboId = data.id

                                null.DisplayHud("3dinteractions", false)

                                local saveCoords = GetEntityCoords(PlayerState.ped)
                                FreezeEntityPosition(PlayerState.ped, true)
                                SetEntityCoords(PlayerPedId(), vec3(v.coords.x, v.coords.y, v.coords.z - 1.0))
                                SetEntityHeading(PlayerState.ped, v.heading)

                                exports["null-core"]:OpenPropScene({
                                    id = "weed_cut_heads_labo",
                                    title = "Couper les Têtes",
                                    subtitle = "Utilisez les ciseaux pour couper les têtes",
                                    color = "#22c55e",
                                    origin = origin,

                                    idleAnim = { dict = "timetable@ron@ig_3_couch", name = "base", flags = 51 },

                                    allowOrbit = false,
                                    allowZoom = true,

                                    camera = {
                                        lookAt = vector3(origin.x, origin.y, origin.z + 0.05),
                                        distance = 0.75,
                                        minDistance = 0.5,
                                        maxDistance = 1.5,
                                        angle = math.rad(-90),
                                        heightOffset = 0.5,
                                        lookAtHeightOffset = 0.0,
                                        fov = 50.0,
                                    },

                                    props = allProps,
                                    tools = {
                                        { id = "drugs_scissors", label = "Ciseaux de jardinage", icon = "drugs_scissors", description = "Couper les têtes de weed" },
                                    },
                                    zones = allZones,
                                    items = {},

                                    onZoneAction = function(zoneId, actionId, actionType, toolId)
                                        if actionType == "hold_complete" and actionId == "cut" then
                                            exports["null-core"]:UpdateZoneState(zoneId, "completed", false)

                                            local budPropId = zoneId:gsub("bud_", "bud_prop_")
                                            exports["null-core"]:DeleteSceneProp(budPropId)
                                            exports["null-core"]:RemoveSceneZone(zoneId)

                                            TriggerServerEvent("null:labo:cutDriedHead", laboId, isFirstCut)
                                            isFirstCut = false

                                            --exports["null-core"]:AddResult({ id = "weed_head_raw", label = "Tête de weed", icon = "leaf", count = 1 })
                                            --exports["null-core"]:SendSceneNotification("Tête coupée !", "success")

                                            cutsRemaining = cutsRemaining - 1
                                            if cutsRemaining <= 0 then
                                                Citizen.SetTimeout(1500, function()
                                                    --exports["null-core"]:SendSceneNotification("Toutes les têtes sont coupées !", "success")
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
                                local inventory = exports["null-core"]:GetPlayerInventaire()
                                local found = false
                                for _,item in pairs(inventory) do
                                    if item.name == Config.laboratoire.type["weed"].items["plantdry"] and item.count >= 1 then
                                        found = true
                                        break
                                    end
                                end
                                if found then
                                    cb(true)
                                else
                                    cb(false, "Nécessite une plante de weed séchée")
                                end
                            end
                        },
                        {
                            left = "Séparer les feuilles",
                            key = "F",
                            action = function()
                                local result = exports["null-core"]:GetAreCuting()
                                if result then return end
                                if not null.fct.confirm() then return end
                                Citizen.CreateThread(function()
                                    ESX.TriggerServerCallback("null:labo:canCut", function(can)
                                        if can then
                                            local oldCam = GetFollowPedCamViewMode()
                                            SetFollowPedCamViewMode(4)
                                            DisableIdleCamera(true)
                                            null.DisplayHud("3dinteractions", false)
                                            exports["null-core"]:SetAreCuting(true)
                                            local saveCoords = GetEntityCoords(PlayerState.ped)
                                            local coords = vec3(v.coords.x, v.coords.y, v.coords.z)
                                            SetEntityCoords(PlayerPedId(), coords)
                                            SetEntityHeading(PlayerState.ped, v.heading)

                                            RequestAnimDict("anim@amb@business@weed@weed_sorting_seated@")
                                            while not HasAnimDictLoaded('anim@amb@business@weed@weed_sorting_seated@') do
                                                Wait(100)
                                            end
                                            TriggerEvent("progressbar:start", 24750*5, "Séparation des feuilles en cours...")
                                            local PropsTable1 = CreateObject(GetHashKey('bkr_prop_weed_bud_02b'), v.props[1].coords.x, v.props[1].coords.y, v.props[1].coords.z, true)
                                            SetEntityRotation(PropsTable1, v.props[1].rotation.x, v.props[1].rotation.y, v.props[1].rotation.z)
                                            local PropsTable2 = CreateObject(GetHashKey('bkr_prop_weed_bud_02b'), v.props[2].coords.x, v.props[2].coords.y, v.props[2].coords.z, true)
                                            SetEntityRotation(PropsTable2, v.props[2].rotation.x, v.props[2].rotation.y, v.props[2].rotation.z)
                                            local PropsTable3 = CreateObject(GetHashKey('bkr_prop_weed_bud_02b'), v.props[3].coords.x, v.props[3].coords.y, v.props[3].coords.z, true)
                                            SetEntityRotation(PropsTable3, v.props[3].rotation.x, v.props[3].rotation.y, v.props[3].rotation.z)

                                            local function TreatOneWeed()
                                                TaskPlayAnimAdvanced(GetPlayerPed(-1), 'anim@amb@business@weed@weed_sorting_seated@', 'sorter_right_sort_v3_sorter02', v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, v.heading, 1.0, 1.0, -1)
                                                FreezeEntityPosition(PlayerPedId(), true)
                                                Wait(3750)
                                                local tempPropsWeedBud = CreateObject(GetHashKey('bkr_prop_weed_bud_02b'), 0.0, 0.0, 0.0, true)
                                                AttachEntityToEntity(tempPropsWeedBud, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 18905), 0.12, -0.025, 0.045, 260.0, 0.0, 0.0, true, true, false, true, 1, true)
                                                Wait(20000)
                                                AttachEntityToEntity(tempPropsWeedBud, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 57005), 0.12, -0.025, -0.005, 260.0, 0.0, 0.0, true, true, false, true, 1, true)
                                                Wait(1000)
                                                DeleteEntity(tempPropsWeedBud)
                                            end

                                            TreatOneWeed()
                                            TreatOneWeed()
                                            TreatOneWeed()
                                            TreatOneWeed()
                                            TreatOneWeed()

                                            DeleteEntity(PropsTable1)
                                            DeleteEntity(PropsTable2)
                                            DeleteEntity(PropsTable3)
                                            FreezeEntityPosition(PlayerPedId(), false)
                                            SetEntityCoords(PlayerPedId(), saveCoords)
                                            ClearPedTasks(PlayerState.ped)
                                            TriggerServerEvent("null:labo:cutWeed", data.id)
                                            local hasObjective = GetCurrentObjectives()
                                            if hasObjective and hasObjective.id == "weed_processing" then
                                                SetObjectiveStep("package_buds")
                                            end

                                            exports["null-core"]:SetAreCuting(false)
                                            null.DisplayHud("3dinteractions", true)
                                            DisableIdleCamera(false)
                                            SetFollowPedCamViewMode(oldCam)
                                        end
                                    end, data.id)
                                end)
                            end,
                            canSee = function(cb)
                                local inventory = exports["null-core"]:GetPlayerInventaire()
                                local found = false
                                for _,item in pairs(inventory) do
                                    if item.name == Config.laboratoire.type["weed"].items["head_raw"] and item.count >= 1 then
                                        found = true
                                        break
                                    end
                                end
                                if found then
                                    cb(true)
                                else
                                    cb(false, "Nécessite une tête de weed non traitée")
                                end
                            end
                        },
                        {
                            left = "Conditionner en pochon",
                            key = "G",
                            action = function()
                                local result = exports["null-core"]:GetAreCuting()
                                if result then return end
                                if exports["null-core"]:IsSceneOpen() then return end
                                
                                local inventory = exports["null-core"]:GetPlayerInventaire()
                                local budCount = 0
                                local poochCount = 0
                                for _,item in pairs(inventory) do
                                    if item.name == Config.laboratoire.type["weed"].items["bud"] then budCount = item.count end
                                    if item.name == Config.laboratoire.items["pooch"] then poochCount = item.count end
                                end

                                if budCount <= 0 then
                                    ESX.ShowNotification("Vous n'avez pas de bud de weed.")
                                    return
                                end
                                if poochCount <= 0 then
                                    ESX.ShowNotification("Vous n'avez pas de pochon vide.")
                                    return
                                end

                                local packagingCfg = Config.laboratoire.type["weed"].treatmentequipment.packaging
                                local budsPerBag = packagingCfg.budsPerBag or 1
                                local maxBags = packagingCfg.maxBags or 5

                                -- Nombre de pochons = min(buds, pochons vides, maxBags)
                                local numBags = math.min(budCount, poochCount, maxBags)
                                local budsToShow = numBags * budsPerBag

                                local budImage = "nui://null-cache/images/props/bkr_prop_weed_bud_pruned_01a.webp"
 
                                -- Origin = centre de la table réelle (pas de spawn de table)
                                local origin = v.tableOrigin or vec3(v.coords.x, v.coords.y, v.coords.z)

                                -- Pochons (rangée proche du joueur, côté sud = Y négatif)
                                local bagOffsets = {
                                    vector3(-0.45, -0.13, 0.02),
                                    vector3(-0.22, -0.13, 0.02),
                                    vector3( 0.00, -0.13, 0.02),
                                    vector3( 0.22, -0.13, 0.02),
                                    vector3( 0.45, -0.13, 0.02),
                                }

                                -- Buds (rangée éloignée du joueur, côté nord = Y positif)
                                local budTableOffsets = {
                                    vector3(-0.40,  0.10, 0.02),
                                    vector3(-0.18,  0.12, 0.02),
                                    vector3( 0.03,  0.08, 0.02),
                                    vector3( 0.20,  0.12, 0.02),
                                    vector3( 0.42,  0.10, 0.02),
                                }

                                -- Construire props et zones
                                local allProps = {}
                                local allZones = {}

                                -- Pochons (props + zones réceptrices)
                                for i = 1, numBags do
                                    allProps[#allProps + 1] = {
                                        id = "bag_prop_" .. i,
                                        model = "bkr_prop_weed_bag_01a",
                                        offset = bagOffsets[i],
                                    }
                                    allZones[#allZones + 1] = {
                                        id = "bag_" .. i,
                                        propId = "bag_prop_" .. i,
                                        offset = vector3(0.0, 0.0, 0.12),
                                        label = "Pochon #" .. i,
                                        icon = "package",
                                        state = "idle",
                                        pulse = true,
                                        maxItems = budsPerBag,
                                        actions = {
                                            {
                                                id = "fill", label = "Remplir", type = "drag_receive",
                                                acceptItems = { "weed_bud" },
                                                animation = { dict = "mp_common", name = "givetake1_a", flags = 49, duration = 800 },
                                            },
                                        },
                                    }
                                end

                                -- Buds (props + zones draggables)
                                for i = 1, budsToShow do
                                    allProps[#allProps + 1] = {
                                        id = "bud_pkg_" .. i,
                                        model = "bkr_prop_weed_bud_pruned_01a",
                                        offset = budTableOffsets[i] or vector3(0.0, 0.10, 0.02),
                                        placeOnGround = false,
                                    }
                                    allZones[#allZones + 1] = {
                                        id = "bud_zone_" .. i,
                                        propId = "bud_pkg_" .. i,
                                        offset = vector3(0.0, 0.0, 0.05),
                                        label = "Bud de weed",
                                        icon = "leaf",
                                        image = budImage,
                                        state = "idle",
                                        draggable = true,
                                        dragItemId = "weed_bud",
                                        actions = {},
                                    }
                                end 

                                local bagsCompleted = 0
                                local laboId = data.id
                                local bagFillCount = {}
                                for i = 1, numBags do bagFillCount["bag_" .. i] = 0 end

                                null.DisplayHud("3dinteractions", false)

                                local saveCoords = GetEntityCoords(PlayerState.ped)
                                FreezeEntityPosition(PlayerState.ped, true)
                                SetEntityCoords(PlayerPedId(), vec3(v.coords.x, v.coords.y, v.coords.z - 1.0))
                                SetEntityHeading(PlayerState.ped, v.heading)
 
                                exports["null-core"]:OpenPropScene({
                                    id = "weed_packaging_labo",
                                    title = "Conditionner la Weed",
                                    subtitle = "Glissez les buds dans les pochons",
                                    color = "#22c55e",
                                    origin = origin,
   
                                    idleAnim = { dict = "timetable@ron@ig_3_couch", name = "base", flags = 51 },
    
                                    allowOrbit = false,
                                    allowZoom = true,

                                    camera = { 
                                        lookAt = vector3(origin.x, origin.y, origin.z + 0.05),
                                        distance = 0.75, 
                                        minDistance = 0.5,
                                        maxDistance = 1.5,
                                        angle = math.rad(-90),
                                        heightOffset = 0.5,
                                        lookAtHeightOffset = 0.0,
                                        fov = 50.0,
                                    },

                                    props = allProps,
                                    tools = {},
                                    zones = allZones,
                                    items = {},

                                    onZoneDrop = function(zoneId, actionId, itemId, toolId, sourceType, sourceId)
                                        -- Supprimer le bud (zone + prop)
                                        if sourceType == "zone" and sourceId then
                                            local budPropId = sourceId:gsub("bud_zone_", "bud_pkg_")
                                            exports["null-core"]:DeleteSceneProp(budPropId)
                                            exports["null-core"]:RemoveSceneZone(sourceId)
                                        end

                                        -- Serveur : 1 bud + 1 pochon vide → 1 weed_pooch
                                        TriggerServerEvent("null:labo:packageWeedBud", laboId)

                                        bagFillCount[zoneId] = (bagFillCount[zoneId] or 0) + 1
                                        local total = bagFillCount[zoneId]

                                        local heldItems = { { itemId = itemId, count = total } }
                                        exports["null-core"]:UpdateZoneItems(zoneId, heldItems)

                                        -- Récupérer l'index du pochon
                                        local bagIdx = tonumber(zoneId:match("bag_(%d+)"))
                                        local bagPropId = "bag_prop_" .. bagIdx
                                        local bagOffset = bagOffsets[bagIdx]

                                        if total >= budsPerBag then
                                            -- Pochon rempli → sac fermé
                                            exports["null-core"]:DeleteSceneProp(bagPropId)
                                            exports["null-core"]:AddSceneProp({ id = bagPropId, model = "prop_custom_pooch_closed", offset = bagOffset })

                                            exports["null-core"]:UpdateZoneState(zoneId, "completed", false)
                                            --exports["null-core"]:AddResult({ id = "weed_pooch", label = "Pochon de weed", icon = "package", count = 1 })
                                            --exports["null-core"]:SendSceneNotification("Pochon rempli !", "success")

                                            bagsCompleted = bagsCompleted + 1
                                            if bagsCompleted >= numBags then
                                                Citizen.SetTimeout(1500, function()
                                                    exports["null-core"]:SendSceneNotification("Tout est conditionné !", "success")
                                                    local hasObjective = GetCurrentObjectives()
                                                    if hasObjective and hasObjective.id == "weed_processing" then
                                                        CompleteObjectives(6000)
                                                    end
                                                    Citizen.SetTimeout(2000, function()
                                                        exports["null-core"]:ClosePropScene()
                                                        null.DisplayHud("3dinteractions", true)
                                                    end)
                                                end)
                                            end
                                        elseif total >= 1 then
                                            -- Partiellement rempli → sac ouvert
                                            exports["null-core"]:DeleteSceneProp(bagPropId)
                                            exports["null-core"]:AddSceneProp({ id = bagPropId, model = "sf_prop_sf_bag_weed_open_01b", offset = bagOffset })
                                            --exports["null-core"]:SendSceneNotification(string.format("Pochon %d/%d", total, budsPerBag), "info")
                                        end
                                    end,

                                    onClose = function()
                                        null.DisplayHud("3dinteractions", true)
                                    end,
                                })
                            end,
                            canSee = function(cb)
                                local inventory = exports["null-core"]:GetPlayerInventaire()
                                local hasBud = false
                                local hasPooch = false
                                for _,item in pairs(inventory) do
                                    if item.name == Config.laboratoire.type["weed"].items["bud"] then hasBud = true end
                                    if item.name == Config.laboratoire.items["pooch"] then hasPooch = true end
                                end
                                if hasBud and hasPooch then
                                    cb(true)
                                elseif not hasBud and not hasPooch then
                                    cb(false, "Nécessite des têtes et des pochons vides")
                                elseif not hasBud then
                                    cb(false, "Nécessite des têtes de weed")
                                else
                                    cb(false, "Nécessite des pochons vides")
                                end
                            end
                        },
                    }
                },
            })
        end
    end
end

RegisterNetEvent("null:labo:updateindrying", function(id, data)
    null.data.illegals.laboratories.list[id].treatmentequipment.indrying = data
    if null.data.illegals.laboratories.list[id].type == "weed" then
        SetupLaboDry(id, false)
    else
        for k,v in pairs(DryProps) do if DoesEntityExist(v) then DeleteEntity(v) end end
        DryProps = {}
    end
end)