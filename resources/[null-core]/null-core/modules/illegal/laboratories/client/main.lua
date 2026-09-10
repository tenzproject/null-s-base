Citizen.CreateThread(function()
    Wait(1000)
    GetAllLabo()

    Add3DInteraction({
        id = "labo_inside_exit",
        coords = Config.laboratoire.coords,
        text = "Sortir du laboratoire",
        Action = function()
            TriggerServerEvent("null:labo:leave")
        end,
        maxDistance = 0.6,
        maxDistance2 = 1.5,
        key = "E"
    })
end)

LaboTutorial = {
    numberOfWeedPlanted = 0 
}

function HasLaboPermissions(id, perm) 
    if id == nil then return false end
    local data = null.data.illegals.laboratories.list[id]
    if data == nil then return false end 
    if data.owner == ESX.PlayerData.idunique then return true end
    if data.owner == ESX.PlayerData.job.name and Config.laboratoire.Permissions[perm].groupeAccess then return true end
    if data.owner == ESX.PlayerData.job2.name and Config.laboratoire.Permissions[perm].groupeAccess then return true end
    if data.members == nil then return false end
    if data.members[ESX.PlayerData.idunique] == nil then return false end
    local perms = data.members[ESX.PlayerData.idunique].permissions
    if perms == nil then return false end
    -- Support both array-style {"access_lab"} and dict-style {access_lab = true}
    if perms[perm] ~= nil then return true end
    for _, v in ipairs(perms) do
        if v == perm then return true end
    end
    return false
end

local function CreateAntiBugWhile(id)
    Wait(5000)
    Citizen.CreateThread(function()
        local coords = null.fct.JsonCoordsToVect3(Config.laboratoire.coords)
        while true do
            if PlayerState.Illegals.laboratories.inLabo == false then break end
            local distance = #(coords - GetEntityCoords(PlayerPedId()))
            if distance > 50.0 then
                TriggerServerEvent("null:labo:forceLeaveByTp", id)
                break
            end
            DisplayRadar(false)
            Wait(2000)
        end
        DestoryLaboDry()
    end)
    Citizen.CreateThread(function()
        while true do
            if PlayerState.Illegals.laboratories.inLabo == false then break end
            HideMinimapInteriorMapThisFrame()
            Wait(0)
        end
    end)
end

function GetAllLabo() 
    null.data.illegals.laboratories.loaded = false
    TriggerServerEvent("null:labo:get")
end 

function GetLaboInfo(name)
    return null.data.illegals.laboratories.list[name]
end
exports("GetLaboInfo", GetLaboInfo)

local function SetupLabo(id)
    Citizen.CreateThread(function()
        local data = null.data.illegals.laboratories.list[id]
        if not data then
            while null.data.illegals.laboratories.list[id] == nil do 
                Wait(100) 
            end
            data = null.data.illegals.laboratories.list[id]
        end 

        if devmode then
            RegisterCommand("testComputer_"..id, function()
                ESX.TriggerServerCallback("null:labo:getMarket", function(market) 
                    local labodata = exports["null-core"]:GetLaboInfo(id)
                    exports["cuchi_computer"]:openLaptop("laboratory", {
                        laboratory = labodata, 
                        market = market,
                    })
                end, id)
            end)
        end

        if data.ownerType == "ind" then
            if ESX.PlayerData.idunique == data.owner then
                ESX.addBlips({
                    name = 'labo_'..data.id,
                    label = 'Votre laboratoire de '..Config.laboratoire.type[data.type].label,
                    category = nil,
                    position = null.fct.JsonCoordsToVect3(data.coords),
                    sprite = 499,
                    display = 4,
                    scale = 0.60,
                    color = 13
                })
            elseif HasLaboPermissions(data.id, "access_lab") then
                ESX.addBlips({
                    name = 'labo_'..data.id,
                    label = 'Laboratoire de '..Config.laboratoire.type[data.type].label,
                    category = nil,
                    position = null.fct.JsonCoordsToVect3(data.coords),
                    sprite = 499,
                    display = 4,
                    scale = 0.60,
                    color = 3
                })
            end
        elseif data.ownerType == "group" then
            while ESX.PlayerData == nil or ESX.PlayerData.job2 == nil or ESX.PlayerData.job == nil do
                Wait(100)
            end
            if ESX.PlayerData ~= nil and ESX.PlayerData.job2 ~= nil and ESX.PlayerData.job2.name == data.owner then
                ESX.addBlips({ 
                    name = 'labo_'..data.id,
                    label = 'Laboratoire de '..Config.laboratoire.type[data.type].label.." de votre groupe",
                    category = nil,
                    position = null.fct.JsonCoordsToVect3(data.coords),
                    sprite = 499,
                    display = 4,
                    scale = 0.60, 
                    color = 1
                })
            elseif ESX.PlayerData ~= nil and ESX.PlayerData.job ~= nil and ESX.PlayerData.job.name == data.owner then
                ESX.addBlips({
                    name = 'labo_'..data.id,
                    label = 'Laboratoire de '..Config.laboratoire.type[data.type].label.." de votre groupe",
                    category = nil,
                    position = null.fct.JsonCoordsToVect3(data.coords),
                    sprite = 499,
                    display = 4,
                    scale = 0.60,
                    color = 1
                })
            end
        end
        
        if Exist3DInteraction("labo_"..data.id) then
            Remove3DInteraction("labo_"..data.id)
        end

        Add3DInteraction({
            id = "labo_"..data.id,
            type = "multi",
            coords = vector3(data.coords.x,data.coords.y,data.coords.z+0.4),
            maxDistance = 5.0,
            maxDistance2 = 0.8,
            canSee = function(cb)
                if HasLaboPermissions(data.id, "access_lab") then
                    cb(true)
                    return
                elseif null.data.jobs.polices.list[ESX.PlayerData.job] ~= nil then
                    cb(true)
                    return
                else
                    cb(false)
                    return
                end
            end,
            text = {
                title = "Laboratoire",
                lines = {
                    -- {
                    --     left = "Propriétaire", 
                    --     rightAreFunction = true,
                    --     right = function(cb)
                    --         local labodata = exports["null-core"]:GetLaboInfo(data.id)
                    --         if type(labodata.owner) == "number" then
                    --             cb("U"..tostring(labodata.owner))
                    --         else 
                    --             cb(labodata.owner)
                    --         end
                    --     end,
                    --     canSee = function(cb) 
                    --         if HasLaboPermissions(data.id, "access_lab") then
                    --             cb(true)
                    --             return
                    --         else
                    --             cb(false)
                    --             return
                    --         end
                    --     end
                    -- },
                    {
                        left = "Type de Labo", 
                        rightAreFunction = true,
                        right = function(cb)
                            local labodata = exports["null-core"]:GetLaboInfo(data.id)
                            cb(Config.laboratoire.type[labodata.type].label)
                        end,
                        canSee = function(cb) 
                            local labodata = exports["null-core"]:GetLaboInfo(data.id)
                            if HasLaboPermissions(data.id, "access_lab") then
                                cb(true)
                                return
                            else
                                cb(false)
                                return
                            end
                        end
                    },
                    {
                        left = "Entrer", 
                        key = "E", 
                        action = function() 
                            local labodata = exports["null-core"]:GetLaboInfo(data.id)
                            if (labodata.hasBuy and labodata.owner ~= nil) or labodata.dooropen then
                                TriggerServerEvent("null:labo:enter", labodata.id)
                                null.DebugPrint("Entrance triggered")
                            end
                        end,
                        canSee = function(cb) 
                            local labodata = exports["null-core"]:GetLaboInfo(data.id)
                            if HasLaboPermissions(data.id, "access_lab") or labodata.dooropen == true then
                                cb(true)
                                return
                            else
                                cb(false)
                                return
                            end
                        end
                    },
                    {
                        left = "Status de la porte", 
                        rightAreFunction = true,
                        right = function(cb)
                            local labodata = GetLaboInfo(data.id)
                            cb(labodata.dooropen and "Crocheter" or "Fermer")
                        end
                    },
                    {
                        left = "Crocheter la serrure", 
                        key = "F", 
                        action = function() 
                            local timewait = math.random(5000, 12000)
                            TriggerServerEvent("null:labo:forceenter", data.id, timewait)
                            FreezeEntityPosition(PlayerPedId(), true)
                            local dict = "missheistfbisetup1"
                            local anim = "hassle_intro_loop_f"
                            RequestAnimDict(dict)
                            while not HasAnimDictLoaded(dict) do
                                Wait(0)
                            end
                            TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, -8.0, -1, 51, 0, false, false, false)
                            Wait(timewait+5000)
                            ClearPedTasks(PlayerPedId())
                            FreezeEntityPosition(PlayerPedId(), false)
                        end,
                        canSee = function(cb) 
                            if null.data.jobs.polices.list[ESX.PlayerData.job.name] ~= nil then
                                cb(true)
                            else
                                cb(false)
                            end
                            cb(false)
                        end
                    },
                }
            },
        })

        if data.dropbox then 
            if Exist3DInteraction("labo_dropbox_"..data.id) then
                Remove3DInteraction("labo_dropbox_"..data.id)
            end

            Add3DInteraction({
                id = "labo_dropbox_"..data.id,
                coords = vector3(data.dropbox.coords.x, data.dropbox.coords.y, data.dropbox.coords.z+1.2),
                text = "Ouvrir la DropBox",
                Action = function()
                    ESX.TriggerServerCallback('null:getCoffre', function(coffredata, coffreid)
                        if coffredata then
                            local inventory = {
                                items = coffredata.items or {},
                                loadout = coffredata.loadout or {},
                                cash = coffredata.cash or 0,
                                dirtycash = coffredata.dirtycash or 0,
                                weight = 0,
                                id = coffreid,
                                maxWeight = 100,
                                type = "BRIEFCASE",
                                cacheKey = coffredata.cacheKey,
                                savename = coffredata.savename,
                            }
                            TriggerEvent("inventory:openTarget", inventory)

                            local hasObjective = GetCurrentObjectives()
                            if hasObjective and hasObjective.id == "labo_weed_production" then
                                SetTimeout(5000, function()
                                    SetObjectiveStep("go_production")
                                end)
                            end
                        end
                    end, "labo_dropbox_"..data.id, "BRIEFCASE", 100)
                end,
                canSee = function(cb)
                    if HasLaboPermissions(data.id, "access_lab") then
                        cb(true)
                        return
                    else
                        cb(false)
                        return
                    end
                end,
                maxDistance = 3.0,
                maxDistance2 = 0.8,
                key = "E"
            })
        end
    end)
end

function openSellerMenu()
    if null.data.jobs.polices.list[ESX.PlayerData.job.name] ~= nil then
        ESX.ShowNotification("Tu veux quoi ?")
        return
    end

    if #null.data.illegals.laboratories.list == 0 then
        ESX.ShowNotification("Il n'y a pas de laboratoire pour l'instant.")
        return
    end

    local catalogItems = {}
    for k, v in pairs(null.data.illegals.laboratories.list) do
        if v.hasBuy == false and v.owner == "aucun" and v.ownerType == nil then
            local laboType = Config.laboratoire.type[v.type]
            table.insert(catalogItems, {
                id = v.id,
                label = "Laboratoire " .. laboType.label,
                description = "Un laboratoire de production de " .. laboType.label,
                price = v.price,
                image = "nui://null-cache/images/laboratories/" .. v.type .. ".png",
                options = {
                    { value = "ind", label = "Pour vous" },
                    { value = "group", label = "Pour votre groupe illégal" },
                },
                metadata = {
                    laboId = v.id,
                    laboType = v.type,
                }
            })
        end
    end

    if #catalogItems == 0 then
        ESX.ShowNotification("Aucun laboratoire disponible à l'achat.")
        return
    end

    exports["null-core"]:OpenCatalog({
        title = "Mark - Vendeur de laboratoire",
        subtitle = "Laboratoires disponibles",
        description = "Sélectionnez un laboratoire pour voir les détails et l'acheter.",
        items = catalogItems,
        imagePath = "nui://null-cache/images/laboratories/",
        currency = "$",
        callbackEvent = "null:labo:buy",
    })
end

local areCuting = false
exports("GetAreCuting", function()
    return areCuting
end)
exports("SetAreCuting", function(bool)
    areCuting = bool
end)

local LaboPed = nil
local LaboPedProps = nil
local CoffreEntity = nil
local LadderEntity = nil
ChairsEntity = {}

CreatedTreatementInteract = {}
local inDeposeMethFour = false

function SetupLaboInside(id)
    if DoesEntityExist(CoffreEntity) then DeleteEntity(CoffreEntity) end
    if DoesEntityExist(LadderEntity) then DeleteEntity(LadderEntity) end
    if DoesEntityExist(LaboPed) then DeleteEntity(LaboPed) end
    if DoesEntityExist(LaboPedProps) then DeleteEntity(LaboPedProps) end
    for k,v in pairs(ChairsEntity) do if DoesEntityExist(v) then DeleteEntity(v) end end

    local data = null.data.illegals.laboratories.list[id]
    if data == nil then return end
    if PlayerState.Illegals.laboratories.inLabo ~= id then return end
    if Exist3DInteraction("labo_"..id.."_inside_pc") then
        Remove3DInteraction("labo_"..id.."_inside_pc")
    end
    if Exist3DInteraction("labo_"..id.."_inside_dealer") then
        Remove3DInteraction("labo_"..id.."_inside_dealer")
    end
    if Exist3DInteraction("labo_"..id.."_inside_coffre") then
        Remove3DInteraction("labo_"..id.."_inside_coffre")
    end
    if Exist3DInteraction("labo_"..id.."_inside_coffre_big") then
        Remove3DInteraction("labo_"..id.."_inside_coffre_big")
    end
    if Exist3DInteraction("labo_"..id.."_inside_treatment_dry") then
        Remove3DInteraction("labo_"..id.."_inside_treatment_dry")
    end
    if Exist3DInteraction("labo_"..id.."_inside_camera") then
        Remove3DInteraction("labo_"..id.."_inside_camera")
    end
    for k,v in pairs(CreatedTreatementInteract) do
        if Exist3DInteraction(v) then
            Remove3DInteraction(v)
        end
    end
    for k,v in pairs(Config.laboratoire.type["meth"].cuves) do 
        local idInteraction = "labo_"..id.."_inside_mix_"..k
        if Exist3DInteraction(idInteraction) then
            Remove3DInteraction(idInteraction)
        end
    end
    
    for k,v in pairs(Config.laboratoire.type["meth"].fours) do
        local idInteraction = "labo_"..id.."_inside_four_"..k
        if Exist3DInteraction(idInteraction) then
            Remove3DInteraction(idInteraction)
        end
    end
    
    for k,v in pairs(Config.laboratoire.type["meth"].breakpoints) do
        local idInteraction = "labo_"..id.."_inside_break_"..k
        if Exist3DInteraction(idInteraction) then
            Remove3DInteraction(idInteraction)
        end
    end

    Add3DInteraction({
        id = "labo_"..id.."_inside_pc",
        coords = Config.laboratoire.management,
        bucket = data.instance,
        text = "Ouvrir l'ordinateur",
        Action = function()
            ESX.TriggerServerCallback("null:labo:getMarket", function(market) 
                local result = exports["null-core"]:GetLaboInfo(id)
                exports["cuchi_computer"]:openLaptop("laboratory", {
                    laboratory = result, 
                    market = market,
                })

                local hasObjective = GetCurrentObjectives()
                if hasObjective and hasObjective.id == "discover_lab" then
                    SetTimeout(5000, function()
                        SetObjectiveStep("go_stockage")
                    end)
                end
            end, id)
        end,
        canSee = function(cb)
            local labodata = exports["null-core"]:GetLaboInfo(id)
            if labodata.owner == ESX.PlayerData.idunique or labodata.owner == ESX.PlayerData.job.name or labodata.owner == ESX.PlayerData.job2.name then
                cb(true)
                return
            end
            cb(false)
        end,
        maxDistance = 3.0,
        maxDistance2 = 1.0,
        key = "E"
    })
    if data.upgrades["security"] then
        Add3DInteraction({
            id = "labo_"..id.."_inside_camera",
            coords = Config.laboratoire.CameraManage,
            bucket = data.instance,
            type = "multi",
            text = {
                title = "Caméra's Live",
                lines = {
                    {
                        left = "Camera 1",
                        key = "E",
                        action = function()
							CameraUtils.RequestCamera("Weed Laboratoire", 1)
                        end,
                        canSee = function(cb)
                            local result = exports["null-core"]:GetLaboInfo(id)
                            if result.upgrades["security"] ~= true then
                                cb(false)
                                return
                            end
                            cb(true)
                        end
                    },
                    {
                        left = "Camera 2",
                        key = "F",
                        action = function()
							CameraUtils.RequestCamera("Weed Laboratoire", 2)
                        end,
                        canSee = function(cb)
                            local result = exports["null-core"]:GetLaboInfo(id)
                            if result.upgrades["security"] ~= true then
                                cb(false)
                                return
                            end
                            cb(true)
                        end
                    },
                    {
                        left = "Camera 3",
                        key = "H",
                        action = function()
							CameraUtils.RequestCamera("Weed Laboratoire", 3)
                        end,
                        canSee = function(cb)
                            local result = exports["null-core"]:GetLaboInfo(id)
                            if result.upgrades["security"] ~= true then
                                cb(false)
                                return
                            end
                            cb(true)
                        end
                    },
                    {
                        left = "Camera 4",
                        key = "K",
                        action = function()
							CameraUtils.RequestCamera("Weed Laboratoire", 4)
                        end,
                        canSee = function(cb)
                            local result = exports["null-core"]:GetLaboInfo(id)
                            if result.upgrades["security"] ~= true then
                                cb(false)
                                return
                            end
                            cb(true)
                        end
                    },
                    {
                        left = "Camera Exterieur",
                        key = "G",
                        action = function()
                            local result = exports["null-core"]:GetLaboInfo(id)
                            TriggerServerEvent("null:labo:setincamera", true, id)
                            
                            local TempPropsCamera = CreateObject(GetHashKey("prop_cctv_cam_01a"), result.camera.coords.x, result.camera.coords.y, result.camera.coords.z, true, true, true)
                            FreezeEntityPosition(TempPropsCamera, true)
                            SetEntityRotation(TempPropsCamera, vec3(result.camera.rotation.x, result.camera.rotation.y, result.camera.rotation.z))
                            local CameraCoords = GetOffsetFromEntityInWorldCoords(TempPropsCamera, 0.0, -0.5, -1.5)
                            local headingCamera = (GetEntityHeading(TempPropsCamera) + 180) % 360
                            DeleteEntity(TempPropsCamera)
                            --local propsCoordsOffSet = GetOffsetFromEntityInWorldCoords(NetworkGetEntityFromNetworkId(result.networkIdCamera), 0.0, 1.0, -1.0)
							CameraUtils.RequestCamera("Weed Laboratoire", vector4(CameraCoords.x, CameraCoords.y, CameraCoords.z, headingCamera or 175.0)
                        )
                        end,
                        canSee = function(cb)
                            local result = exports["null-core"]:GetLaboInfo(id)
                            if result.upgrades["security"] ~= true then
                                cb(false)
                                return
                            end
                            if result.camera == nil then
                                cb(false)
                                return
                            end
                            cb(true)
                        end
                    },
                }
            },
            canSee = function(cb)
                if not HasLaboPermissions(id, "access_camera") then
                    cb(false)
                    return
                end
                cb(true)
            end,
            maxDistance = 4.0,
            maxDistance2 = 1.0,
            key = "E"
        })
    end
    if data.upgrades["dealer"] then
        local function CreateDealer(hasReward)
            if DoesEntityExist(LaboPed) then
                DeleteEntity(LaboPed)
            end
            if DoesEntityExist(LaboPedProps) then
                DeleteEntity(LaboPedProps)
            end
            Citizen.CreateThread(function()
                local ped = "a_m_m_eastsa_01" 
                RequestModel(ped)    
                while not HasModelLoaded(ped) do
                    Citizen.Wait(100)
                end    
                LaboPed = CreatePed(0, ped, Config.laboratoire.DealerPed.x, Config.laboratoire.DealerPed.y, Config.laboratoire.DealerPed.z, Config.laboratoire.DealerPed.w, false, false) 
                if hasReward then
                    local dict = "anim@heists@box_carry@"
                    local anim = "idle"
                    
                    RequestAnimDict(dict)
                    while not HasAnimDictLoaded(dict) do
                        Wait(0)
                    end
                    
                    local model = "prop_cs_cardbox_01"
                    RequestModel(GetHashKey(model))
                    while not HasModelLoaded(GetHashKey(model)) do
                        Wait(0)
                    end
                    local coords = GetEntityCoords(LaboPed)
                    LaboPedProps = CreateObject(GetHashKey(model), coords.x, coords.y, coords.z, true, true, true)
                    AttachEntityToEntity(LaboPedProps, LaboPed, GetPedBoneIndex(LaboPed, 60309), 0.025, 0.08, 0.255, -145.0, 290.0, 0.0, true, true, false, true, 1, true)
                    
                    TaskPlayAnim(LaboPed, dict, anim, 8.0, -8.0, -1, 51, 0, false, false, false)
                end
                SetBlockingOfNonTemporaryEvents(LaboPed, true)
                SetEntityInvincible(LaboPed, true)
                FreezeEntityPosition(LaboPed, true)
            end) 
            Add3DInteraction({
                id = "labo_"..id.."_inside_dealer",
                coords = vec3(Config.laboratoire.DealerPed.x, Config.laboratoire.DealerPed.y, Config.laboratoire.DealerPed.z+0.98),
                bucket = data.instance,
                type = "multi",
                text = {
                    title = "Joe",
                    lines = {
                        {
                            left = "Vendre des pochons de Weed",
                            key = "E",
                            action = function()
                                local inventory = exports["null-core"]:GetPlayerInventaire()
                                local count = null.fct.input("Tu veux vendre combien de pochon ?")
                                if count == nil then return end
                                if type(count) ~= "number" then return end
                                local found = false
                                for k,v in pairs(inventory) do 
                                    if v.name == Config.laboratoire.type["weed"].items["traitement"] and v.count >= count then 
                                        found = true 
                                    end 
                                end
                                if not count then return end
                                local price = null.fct.input("Tu veux vendre combien de $ le pochon ?")
                                if price == nil then return end
                                if type(price) ~= "number" then return end
                                TriggerServerEvent("null:labo:selltoDealer", id, count, price, "weed")
                            end,
                            canSee = function(cb)
                                local inventory = exports["null-core"]:GetPlayerInventaire()
                                local result = exports["null-core"]:GetLaboInfo(id)
                                local found = false
                                for k,v in pairs(inventory) do 
                                    if v.name == Config.laboratoire.type["weed"].items["traitement"] and v.count >= 1 then 
                                        found = true 
                                    end 
                                end
                                if not found then 
                                    cb(false)
                                    return 
                                end
                                
                                if result.type ~= "weed" then
                                    cb(false)
                                    return  
                                end
                                
                                if result.dealer.lastRequest ~= nil then 
                                    cb(false)
                                    return  
                                end
            
                                cb(true)
                            end
                        },
                        {
                            left = "Vendre des pochons de Meth",
                            key = "F",
                            action = function()
                                local inventory = exports["null-core"]:GetPlayerInventaire()
                                local count = null.fct.input("Tu veux vendre combien de pochon ?")
                                if count == nil then return end
                                if type(count) ~= "number" then return end
                                local found = false
                                for k,v in pairs(inventory) do 
                                    if v.name == Config.laboratoire.type["meth"].items["traitement"] and v.count >= count then 
                                        found = true 
                                    end 
                                end
                                if not count then return end
                                local price = null.fct.input("Tu veux vendre combien de $ le pochon ?")
                                if price == nil then return end
                                if type(price) ~= "number" then return end
                                TriggerServerEvent("null:labo:selltoDealer", id, count, price, "meth")
                            end,
                            canSee = function(cb)
                                local inventory = exports["null-core"]:GetPlayerInventaire()
                                local result = exports["null-core"]:GetLaboInfo(id)
                                local found = false
                                for k,v in pairs(inventory) do 
                                    if v.name == Config.laboratoire.type["meth"].items["traitement"] and v.count >= 1 then 
                                        found = true 
                                    end 
                                end
                                if not found then 
                                    cb(false)
                                    return 
                                end
                                
                                if result.type ~= "meth" then
                                    cb(false)
                                    return  
                                end
                                
                                if result.dealer.lastRequest ~= nil then 
                                    cb(false)
                                    return  
                                end
            
                                cb(true)
                            end
                        },
                        {
                            left = "Gains: ",
                            rightAreFunction = true,
                            right = function(cb)
                                local result = exports["null-core"]:GetLaboInfo(id)
                                if result.dealer.lastRequest == nil then 
                                    cb(false)
                                    return
                                end
                                if result.dealer.lastRequest.finish ~= true then 
                                    cb(false)
                                    return
                                end
                                cb(result.dealer.lastRequest.reward.total.."$")
                            end,
                            canSee = function(cb)
                                local result = exports["null-core"]:GetLaboInfo(id)
                                if result.dealer.lastRequest == nil then 
                                    cb(false) 
                                    return 
                                end
                                if result.dealer.lastRequest.finish ~= true then 
                                    cb(false)
                                    return 
                                end
                                cb(true)
                            end
                        },
                        {
                            left = "Total Vendu: ",
                            rightAreFunction = true,
                            right = function(cb)
                                local result = exports["null-core"]:GetLaboInfo(id)
                                if result.dealer.lastRequest == nil then 
                                    cb(false)
                                    return
                                end
                                if result.dealer.lastRequest.finish ~= true then 
                                    cb(false)
                                    return
                                end
                                cb(result.dealer.lastRequest.reward.selled.."/"..result.dealer.lastRequest.reward.max)
                            end,
                            canSee = function(cb)
                                local result = exports["null-core"]:GetLaboInfo(id)
                                if result.dealer.lastRequest == nil then 
                                    cb(false)
                                    return
                                end
                                if result.dealer.lastRequest.finish ~= true then 
                                    cb(false)
                                    return
                                end
                                cb(true)
                            end
                        },
                        {
                            left = "Total Invendu: ",
                            rightAreFunction = true,
                            right = function(cb)
                                local result = exports["null-core"]:GetLaboInfo(id)
                                if result.dealer.lastRequest == nil then 
                                    cb(false)
                                    return
                                end
                                if result.dealer.lastRequest.finish ~= true then 
                                    cb(false)
                                    return
                                end
                                cb(result.dealer.lastRequest.reward.unselled.."/"..result.dealer.lastRequest.reward.max)
                            end,
                            canSee = function(cb)
                                local result = exports["null-core"]:GetLaboInfo(id)
                                if result.dealer.lastRequest == nil then 
                                    cb(false) 
                                    return 
                                end
                                if result.dealer.lastRequest.finish ~= true then 
                                    cb(false) 
                                    return
                                end
                                cb(true)
                            end
                        },
                        {
                            left = "Pourcentage Vendu: ",
                            rightAreFunction = true,
                            right = function(cb)
                                local result = exports["null-core"]:GetLaboInfo(id)
                                if result.dealer.lastRequest == nil then 
                                    cb(false)
                                    return
                                end
                                if result.dealer.lastRequest.finish ~= true then 
                                    cb(false)
                                    return
                                end
                                cb(result.dealer.lastRequest.reward.pourcentage.."%")
                            end,
                            canSee = function(cb)
                                local result = exports["null-core"]:GetLaboInfo(id)
                                if result.dealer.lastRequest == nil then return cb(false) end
                                if result.dealer.lastRequest.finish ~= true then return cb(false) end
                                cb(true)
                            end
                        },
                        {
                            left = "Récupérer les gains",
                            key = "E",
                            action = function()
                                TriggerServerEvent("null:labo:takeReward", id)
                            end,
                            canSee = function(cb)
                                local result = exports["null-core"]:GetLaboInfo(id)
                                local inventory = exports["null-core"]:GetPlayerInventaire()

                                if result.dealer.lastRequest == nil then return cb(false) end
                                if result.dealer.lastRequest.finish ~= true then return cb(false) end
                                
                                cb(true)
                            end
                        },
                    }
                },
                canSee = function(cb)
                    if not HasLaboPermissions(id, "access_dealer") then
                        cb(false)
                        return
                    end
                    cb(true)
                end,
                maxDistance = 3.5,
                key = "E"
            })
        end
        if data.dealer.lastRequest ~= nil and not data.dealer.lastRequest.finish then
            if DoesEntityExist(LaboPed) then
                DeleteEntity(LaboPed)
            end
            Add3DInteraction({
                id = "labo_"..id.."_inside_dealer",
                coords = vec3(Config.laboratoire.DealerPed.x, Config.laboratoire.DealerPed.y, Config.laboratoire.DealerPed.z+0.98),
                bucket = data.instance,
                text = "Le dealer est partie.",
                canSee = function(cb)
                    if not HasLaboPermissions(id, "access_dealer") then
                        cb(false)
                        return
                    end
                    cb(true)
                end,
                maxDistance = 3.5,
            })
        elseif data.dealer.lastRequest ~= nil and data.dealer.lastRequest.finish == true then
            CreateDealer(true)
        else
            CreateDealer(false)
        end
    end
    if data.upgrades["coffre"] then
        --CoffreEntity = CreateObject(GetHashKey('p_v_43_safe_s'), 1043.3186035156, -3192.4436035156, -38.41109085083-0.98, true)
        --FreezeEntityPosition(CoffreEntity, true)
        --SetEntityCollision(CoffreEntity, false)
        Add3DInteraction({
            id = "labo_"..id.."_inside_coffre",
            coords = Config.laboratoire.chest,
            bucket = data.instance,
            text = "Ouvrir le coffre",
            Action = function()
                ESX.TriggerServerCallback('null:getCoffre', function(coffredata, coffreid)
                    if coffredata then
                        local inventory = {
                            items = coffredata.items or {},
                            loadout = coffredata.loadout or {},
                            cash = coffredata.cash or 0,
                            dirtycash = coffredata.dirtycash or 0,
                            weight = 0,
                            id = coffreid,
                            maxWeight = 100,
                            type = "STASH",
                            cacheKey = coffredata.cacheKey,
                            savename = coffredata.savename,
                        } 
                        TriggerEvent("inventory:openTarget",inventory)
                    end
                end, "labo_coffre_"..id, "STASH", 100)
            end,
            canSee = function(cb)
                if not HasLaboPermissions(id, "access_safe") then
                    cb(false)
                    return
                end
                cb(true)
            end,
            maxDistance = 3.5,
            maxDistance2 = 1.0,
            key = "E"
        })
    end
    Add3DInteraction({
        id = "labo_"..id.."_inside_coffre_big",
        coords = Config.laboratoire.chest2,
        bucket = data.instance,
        text = "Ouvrir la salle de stockage",
        Action = function()
            ESX.TriggerServerCallback('null:getCoffre', function(coffredata, coffreid)
                if coffredata then
                    local inventory = {
                        items = coffredata.items or {},
                        loadout = coffredata.loadout or {},
                        cash = coffredata.cash or 0,
                        dirtycash = coffredata.dirtycash or 0,
                        weight = 0,
                        id = coffreid,
                        maxWeight = 15000,
                        type = "DRUGLABS",
                        cacheKey = coffredata.cacheKey,
                        savename = coffredata.savename,
                    }
                    TriggerEvent("inventory:openTarget",inventory)
                end
            end, "labo_coffre_big_"..id, "DRUGLABS", 15000)
        end,
        canSee = function(cb)
            if not HasLaboPermissions(id, "access_storage") then
                cb(false)
                return
            end
            cb(true)
        end,
        maxDistance = 3.5,
        maxDistance2 = 1.0,
        key = "E"
    })

    if data.type == "weed" then
        SetupWeedLabo(id)
    elseif data.type == "meth" then
        SetupMethLabo(id)
    end
end

function ResetIPL(interiorHash)
    DeactivateInteriorEntitySet(interiorHash, "light_stock")
    DeactivateInteriorEntitySet(interiorHash, "meth_app")
    DeactivateInteriorEntitySet(interiorHash, "meth_staff_01")
    DeactivateInteriorEntitySet(interiorHash, "meth_staff_02")

    DeactivateInteriorEntitySet(interiorHash, "meth_basic_lab_01")
    DeactivateInteriorEntitySet(interiorHash, "meth_basic_lab_02")
    DeactivateInteriorEntitySet(interiorHash, "meth_basic_lab_01_2")
    DeactivateInteriorEntitySet(interiorHash, "meth_basic_lab_02_2")

    DeactivateInteriorEntitySet(interiorHash, "meth_update_lab_01")
    DeactivateInteriorEntitySet(interiorHash, "meth_update_lab_02")
    DeactivateInteriorEntitySet(interiorHash, "meth_update_lab_01_2")
    DeactivateInteriorEntitySet(interiorHash, "meth_update_lab_02_2")

    DeactivateInteriorEntitySet(interiorHash, "meth_stock")

    DeactivateInteriorEntitySet(interiorHash, "weed_app")
    DeactivateInteriorEntitySet(interiorHash, "weed_staff_01")
    DeactivateInteriorEntitySet(interiorHash, "weed_staff_02")

    DeactivateInteriorEntitySet(interiorHash, "weed_basic_lamp")
    DeactivateInteriorEntitySet(interiorHash, "weed_update_lamp")

    DeactivateInteriorEntitySet(interiorHash, "weed_fan_basick")
    DeactivateInteriorEntitySet(interiorHash, "weed_fan_update")

    DeactivateInteriorEntitySet(interiorHash, "weed_plant_v1")
    DeactivateInteriorEntitySet(interiorHash, "weed_plant_v2")
    DeactivateInteriorEntitySet(interiorHash, "weed_plant_v3")
    DeactivateInteriorEntitySet(interiorHash, "weed_plant_v4")
    DeactivateInteriorEntitySet(interiorHash, "weed_plant_v5")
    DeactivateInteriorEntitySet(interiorHash, "weed_plant_v6")
    DeactivateInteriorEntitySet(interiorHash, "weed_plant_v7")
    DeactivateInteriorEntitySet(interiorHash, "weed_plant_v8")
    DeactivateInteriorEntitySet(interiorHash, "weed_plant_v9")

    DeactivateInteriorEntitySet(interiorHash, "weed_stock")

    DeactivateInteriorEntitySet(interiorHash, "coke_app")
    DeactivateInteriorEntitySet(interiorHash, "coke_staff_01")
    DeactivateInteriorEntitySet(interiorHash, "coke_staff_02")
    DeactivateInteriorEntitySet(interiorHash, "coke_stock")

    DeactivateInteriorEntitySet(interiorHash, "money_app")
    DeactivateInteriorEntitySet(interiorHash, "money_staff_01")
    DeactivateInteriorEntitySet(interiorHash, "money_staff_02")
    DeactivateInteriorEntitySet(interiorHash, "money_stock")

    DeactivateInteriorEntitySet(interiorHash, "weapon_app")
    DeactivateInteriorEntitySet(interiorHash, "weapon_staff_01")
    DeactivateInteriorEntitySet(interiorHash, "weapon_stock")
end

function SetupIpl(data, type)
    local interiorHash = GetInteriorFromEntity(PlayerPedId())
    local InteriorCount = 0
    while interiorHash == 0 and InteriorCount < 100 do 
        interiorHash = GetInteriorFromEntity(PlayerPedId())
        InteriorCount += 1
        Wait(100)
    end
    RefreshInterior(interiorHash)
    ResetIPL(interiorHash)
    if type == "weed" then
        ActivateInteriorEntitySet(interiorHash, "weed_app")
        ActivateInteriorEntitySet(interiorHash, "weed_staff_01")
        ActivateInteriorEntitySet(interiorHash, "weed_staff_02")

        -- @TODO: mettre le stock en fonction de l'upgrade / ce qu'il y a dedans
        ActivateInteriorEntitySet(interiorHash, "weed_stock")

        if data.upgrades["uv-light"] then
            DeactivateInteriorEntitySet(interiorHash, "weed_basic_lamp")
            ActivateInteriorEntitySet(interiorHash, "weed_update_lamp")
        else
            DeactivateInteriorEntitySet(interiorHash, "weed_update_lamp")
            ActivateInteriorEntitySet(interiorHash, "weed_basic_lamp")
        end
        if data.upgrades["ventilateurs"] then
            DeactivateInteriorEntitySet(interiorHash, "weed_fan_basick")
            ActivateInteriorEntitySet(interiorHash, "weed_fan_update")
        else
            DeactivateInteriorEntitySet(interiorHash, "weed_fan_update")
            ActivateInteriorEntitySet(interiorHash, "weed_fan_basick")
        end
    elseif type == "coke" then
        ActivateInteriorEntitySet(interiorHash, "coke_app")
        ActivateInteriorEntitySet(interiorHash, "coke_staff_01")
        ActivateInteriorEntitySet(interiorHash, "coke_staff_02")
        ActivateInteriorEntitySet(interiorHash, "coke_stock")
    elseif type == "meth" then
        ActivateInteriorEntitySet(interiorHash, "light_stock")
        ActivateInteriorEntitySet(interiorHash, "meth_app")
        ActivateInteriorEntitySet(interiorHash, "meth_staff_01")
        ActivateInteriorEntitySet(interiorHash, "meth_staff_02")

        if data.upgrades["meth-upgrade"] then
            DeactivateInteriorEntitySet(interiorHash, "meth_basic_lab_01")
            DeactivateInteriorEntitySet(interiorHash, "meth_basic_lab_02")
            DeactivateInteriorEntitySet(interiorHash, "meth_basic_lab_01_2")
            DeactivateInteriorEntitySet(interiorHash, "meth_basic_lab_02_2")
            ActivateInteriorEntitySet(interiorHash, "meth_update_lab_01")
            ActivateInteriorEntitySet(interiorHash, "meth_update_lab_02")
            ActivateInteriorEntitySet(interiorHash, "meth_update_lab_01_2")
            ActivateInteriorEntitySet(interiorHash, "meth_update_lab_02_2")
        else
            DeactivateInteriorEntitySet(interiorHash, "meth_update_lab_01")
            DeactivateInteriorEntitySet(interiorHash, "meth_update_lab_02")
            DeactivateInteriorEntitySet(interiorHash, "meth_update_lab_01_2")
            DeactivateInteriorEntitySet(interiorHash, "meth_update_lab_02_2")
            ActivateInteriorEntitySet(interiorHash, "meth_basic_lab_01")
            ActivateInteriorEntitySet(interiorHash, "meth_basic_lab_02")
            ActivateInteriorEntitySet(interiorHash, "meth_basic_lab_01_2")
            ActivateInteriorEntitySet(interiorHash, "meth_basic_lab_02_2")
        end
        
        -- @TODO: mettre le stock en fonction de l'upgrade / ce qu'il y a dedans
        ActivateInteriorEntitySet(interiorHash, "meth_stock")
    elseif type == "money" then
        -- @TODO: Si y a de l'argent qui est entrain d'etre blanchit alors mettre le _pr 
        ActivateInteriorEntitySet(interiorHash, "light_stock")
        ActivateInteriorEntitySet(interiorHash, "money_app")
        ActivateInteriorEntitySet(interiorHash, "money_staff_01") -- money_staff_02
        ActivateInteriorEntitySet(interiorHash, "money_stock")
    elseif type == "weapon" then
        ActivateInteriorEntitySet(interiorHash, "light_stock")
        ActivateInteriorEntitySet(interiorHash, "weapon_app")
        ActivateInteriorEntitySet(interiorHash, "weapon_staff_01")
        ActivateInteriorEntitySet(interiorHash, "weapon_stock")
    end
end

RegisterNetEvent("null:labo:updateEmployeesData", function(id, data)
    local data = null.data.illegals.laboratories.list[id]
    if data == nil then return end
    if PlayerState.Illegals.laboratories.inLabo == false then return end

    null.data.illegals.laboratories.list[id].employees = data
end)

local saveCoords = nil
local laboIplLoaded = false

RegisterNetEvent("null:labo:enter", function(id, loader)
    local data = null.data.illegals.laboratories.list[id]
    if data == nil then return end
    if PlayerState.Illegals.laboratories.inLabo ~= false then return end
    if loader then 
        DoScreenFadeOut(100)
        null.DisplayHud(false)
        if not laboIplLoaded then
            laboIplLoaded = true
            FreezeEntityPosition(PlayerPedId(), true)
            SetEntityCoords(PlayerPedId(), Config.laboratoire.coords)
            Wait(1500)
            FreezeEntityPosition(PlayerPedId(), false)
        end
        SetEntityCoords(PlayerPedId(), Config.laboratoire.coords)
        SetEntityHeading(PlayerPedId(), Config.laboratoire.heading)
    end
    SetupIpl(data, data.type)
    PlayerState.Illegals.laboratories.inLabo = id
    SetupLaboInside(id)
    if data.type == "weed" then
        SetupLaboDry(id, true)
    else
        DestoryLaboDry()
    end
    Wait(1000)
    if loader then 
        DoScreenFadeIn(1000)
        null.DisplayHud(true)
    end

    local hasObjective = GetCurrentObjectives()
    if hasObjective and hasObjective.id == "discover_lab" then
        SetObjectiveStep("explore")
    end

    CreateAntiBugWhile(id)
end)

RegisterNetEvent("null:labo:exit", function(id)
    local data = null.data.illegals.laboratories.list[id]
    if data == nil then return end
    DoScreenFadeOut(100)
    if DoesEntityExist(CoffreEntity) then DeleteEntity(CoffreEntity) end
    if DoesEntityExist(LadderEntity) then DeleteEntity(LadderEntity) end
    if DoesEntityExist(LaboPed) then DeleteEntity(LaboPed) end
    if DoesEntityExist(LaboPedProps) then DeleteEntity(LaboPedProps) end
    for k,v in pairs(ChairsEntity) do if DoesEntityExist(v) then DeleteEntity(v) end end
    null.DisplayHud(false)
    SetEntityCoords(PlayerPedId(), null.fct.JsonCoordsToVect3(data.coords))
    SetEntityHeading(PlayerPedId(), data.heading)
    DestoryLaboDry()
    PlayerState.Illegals.laboratories.inLabo = false
    if Exist3DInteraction("labo_"..id.."_inside_pc") then
        Remove3DInteraction("labo_"..id.."_inside_pc")
    end
    Wait(1000)
    DoScreenFadeIn(1500)
    null.DisplayHud(true)
end)

RegisterNetEvent("null:labo:exitTp", function(id)
    local data = null.data.illegals.laboratories.list[id]
    if data == nil then return end
    if DoesEntityExist(CoffreEntity) then DeleteEntity(CoffreEntity) end
    if DoesEntityExist(LadderEntity) then DeleteEntity(LadderEntity) end
    if DoesEntityExist(LaboPed) then DeleteEntity(LaboPed) end
    if DoesEntityExist(LaboPedProps) then DeleteEntity(LaboPedProps) end
    for k,v in pairs(ChairsEntity) do if DoesEntityExist(v) then DeleteEntity(v) end end
    DoScreenFadeOut(100)
    null.DisplayHud(false)
    DestoryLaboDry()
    PlayerState.Illegals.laboratories.inLabo = false
    if Exist3DInteraction("labo_"..id.."_inside_pc") then
        Remove3DInteraction("labo_"..id.."_inside_pc")
    end
    Wait(1000)
    DoScreenFadeIn(1500)
    null.DisplayHud(true)
end)

RegisterNetEvent("null:labo:recevie", function(data)
    null.data.illegals.laboratories.list = data
    for k,v in pairs(null.data.illegals.laboratories.list) do
        SetupLabo(v.id)
    end
    null.data.illegals.laboratories.loaded = true
end)

RegisterNetEvent("null:labo:add", function(key, data)
    null.data.illegals.laboratories.list[key] = data
    SetupLabo(key)
end)

RegisterNetEvent("null:labo:edit", function(key, data, buy, laboExt)
    if data == nil then
        local id = key
        if Exist3DInteraction("labo_"..key) then
            Remove3DInteraction("labo_"..key)
        end
        if Exist3DInteraction("labo_"..key.."_inside_pc") then
            Remove3DInteraction("labo_"..key.."_inside_pc")
        end
        if Exist3DInteraction("labo_"..key.."_inside_dealer") then
            Remove3DInteraction("labo_"..key.."_inside_dealer")
        end
        if Exist3DInteraction("labo_"..key.."_inside_coffre") then
            Remove3DInteraction("labo_"..key.."_inside_coffre")
        end
        if Exist3DInteraction("labo_"..key.."_inside_coffre_big") then
            Remove3DInteraction("labo_"..key.."_inside_coffre_big")
        end
        if Exist3DInteraction("labo_"..key.."_inside_treatment_dry") then
            Remove3DInteraction("labo_"..key.."_inside_treatment_dry")
        end
        if Exist3DInteraction("labo_"..key.."_inside_camera") then
            Remove3DInteraction("labo_"..key.."_inside_camera")
        end
        for k,v in pairs(CreatedTreatementInteract) do
            if Exist3DInteraction(v) then
                Remove3DInteraction(v)
            end
        end
        ESX.removeBlip('labo_'..key)
        if PlayerState.Illegals.laboratories.inLabo == key then
            TriggerServerEvent("null:labo:leave")
            if DoesEntityExist(CoffreEntity) then DeleteEntity(CoffreEntity) end
            if DoesEntityExist(LadderEntity) then DeleteEntity(LadderEntity) end
            if DoesEntityExist(LaboPed) then DeleteEntity(LaboPed) end
            if DoesEntityExist(LaboPedProps) then DeleteEntity(LaboPedProps) end
            for k,v in pairs(ChairsEntity) do if DoesEntityExist(v) then DeleteEntity(v) end end
        end
        null.data.illegals.laboratories.list[key] = nil
    else
        null.data.illegals.laboratories.list[key] = data
        if PlayerState.Illegals.laboratories.inLabo == key then
            SetupIpl(null.data.illegals.laboratories.list[key], null.data.illegals.laboratories.list[key].type)
            SetupLaboInside(key)
        end
    
        if laboExt or buy then
            SetupLabo(key)
        end
    end
end)

RegisterNetEvent("null:labo:someoneenter", function(id)
    if PlayerState.Illegals.laboratories.inLabo == id then
        ESX.ShowNotification("⚠️ Attention, quelqu'un a été détecté devant la porte de votre laboratoire et essaie de rentrer.")
    end
end)

RegisterNetEvent("null:labo:forcedoor", function(id, data)
    null.data.illegals.laboratories.list[id].dooropen = data
end)

RegisterNetEvent("null:labo:start-tutorial", function(id, type, pos)
    pos = vector3(pos.x, pos.y, pos.z)
    SetNewWaypoint(pos.x, pos.y) 

    StartObjectives("discover_lab", "Laboratoire", {
        { id = "go_lab", title = "Se rendre au laboratoire", description = "Suivez le GPS pour localiser votre laboratoire." },
        { id = "enter_lab", title = "Pénétrer dans les lieux", description = "Approchez-vous de la porte et appuyez sur [E] pour entrer." },
        { id = "explore", title = "État des lieux", description = "Bienvenue dans votre laboratoire ! Il est encore vide, mais le potentiel est là. Dirigez-vous vers l'ordinateur." },
        { id = "discover_laptop", title = "Découvrir l'ordinateur", description = "Accédez au terminal pour acheter des améliorations, recruter des employés ou commander des matières premières." },
        { id = "go_stockage", title = "Rejoindre la zone de stockage", description = "Dirigez-vous vers la réserve pour inspecter votre matériel et vos stocks." },
    }, { color = "#798b0f" })
    
    Citizen.CreateThread(function()
        while true do
            local currentStep = GetCurrentStepId()
            if not currentStep then return end

            if currentStep == "go_lab" then
                if #(PlayerState.coords - pos) <= 5.0 then
                    SetObjectiveStep("enter_lab")
                end
            elseif currentStep == "enter_lab" then
                -- Gérer par l'event labo:enter
            elseif currentStep == "explore" then
                if #(PlayerState.coords - Config.laboratoire.management) <= 3.0 then
                    SetObjectiveStep("discover_laptop")
                end
            elseif currentStep == "go_stockage" then 
                if #(PlayerState.coords - Config.laboratoire.chest2) <= 4.0 then
                    CompleteObjectives(6000)
                end
            end

            Wait(1)
        end
    end)
end)

RegisterNetEvent("null:labo:start-weed-tutorial", function(id)
    local laptopFocusDodge = false
    --exports["cuchi_computer"]:closeLaptop()
    --SetNuiFocus(true, false) -- to be up than laptop
    --laptopFocusDodge = true
 
    StartObjectives("labo_weed_production", "Culture de Cannabis", {
        { id = "buy_supplies", title = "Première commande", description = "Votre labo est prêt !\nSur l'application Delivery-Service, commandez :\n- 2 pots.\n- 2 graines femelles.\n- 2 engrais.\n- 2 bidons d'eau.\n- 2 sacs de terre.\n- 1 paire de ciseaux." },
        { id = "wait_delivery", title = "Attente du livreur", description = "Quittez l'ordinateur et patientez (5-20 minutes) jusqu'à recevoir la notification de livraison." },
        { id = "collect_dropbox", title = "Récupérer la marchandise", description = "Sortez du laboratoire et allez à votre 'Drop-box' (indiquée sur la carte) pour récupérer la commande." },
        { id = "go_production", title = "Salle de production", description = "Retournez à l'intérieur et dirigez-vous vers la salle de production de votre laboratoire." },
        { id = "place_pot", title = "Installation du matériel", description = "Équipez le pot de plante et appuyez sur [E] pour l'installer sur un emplacement prédéfini." },
        { id = "add_soil", title = "Préparer la terre", description = "Rapprochez-vous du pot vide et appuyez sur [E] pour y verser votre sac de terre." },
        { id = "plant_seed", title = "Planter la graine", description = "Maintenant, plantez votre graine femelle en appuyant sur [E]." },
        { id = "nurture_plant", title = "Entretien de la plante", description = "Maintenez la plante à 100% d'eau ([F]) et d'engrais ([E]). \nOption : ajoutez une graine mâle pour récolter de nouvelles graines par la suite." },
        { id = "second_pot", title = "Doubler la production", description = "Pendant que votre première plante pousse, placez votre 2ème pot et répétez tout le processus." },
        { id = "wait_harvest", title = "Patience et préparation", description = "Attendez la fin de la croissance pour récolter. \nVous devrez ensuite acheter l'amélioration 'Équipement de traitement' sur l'ordinateur pour traiter vos plantes." },
    }, { color = "#1b8b0f", skipCommand = "skiplabotuto" }) 

    local plant = nil
    local dropboxWaypoint = false

    Citizen.CreateThread(function()
        while true do
            local currentStep = GetCurrentStepId()
            if not currentStep then return end

            if currentStep == "go_production" then
                if #(PlayerState.coords - Config.laboratoire.productionPos) <= 3.0 then
                    SetObjectiveStep("place_pot")
                end
            elseif currentStep == "wait_delivery" and laptopFocusDodge then
                --SetNuiFocus(false, false)
                laptopFocusDodge = false
            elseif currentStep == "collect_dropbox" and not dropboxWaypoint then
                local dropboxCoords = null.data.illegals.laboratories.list[id].dropbox.coords
                SetNewWaypoint(dropboxCoords.x, dropboxCoords.y)
                dropboxWaypoint = true
            elseif currentStep == "nurture_plant" then
                if plant == nil then
                    for k,v in pairs(PlantList) do 
                        if v.inLabo == id then
                            plant = k
                        end
                    end
                elseif PlantList[plant].displayfertilizer >= 80.0 and PlantList[plant].displaywater >= 80.0 then
                    SetObjectiveStep("second_pot")
                end
            elseif currentStep == "second_pot" or currentStep == "wait_harvest" then
                -- second_pot optionnel donc skip des que la premiere plante a 100% growth
                if PlantList[plant].growth == 100.0 then
                    CompleteObjectives(6000)
                end
            end

            Wait(1)
        end
    end)
end)

RegisterNetEvent("null:labo:start-weed-traitement-tutorial", function(id, resume)
    local laptopFocusDodge = false
    --exports["cuchi_computer"]:closeLaptop()
    --SetNuiFocus(true, false) -- to be up than laptop
    --laptopFocusDodge = true
 
    StartObjectives("weed_processing", "Traitement de la Récolte", {
        { id = "go_drying", title = "Zone de séchage", description = "Retournez dans la salle de production et dirigez-vous vers l'échelle sur votre droite.\nC'est ici que vous ferez sécher vos plantes." },
        { id = "hang_plants", title = "Suspendre la récolte", description = "Interagissez avec l'échelle pour mettre à sécher toutes les plantes de cannabis que vous avez sur vous." },
        { id = "wait_drying", title = "Temps de séchage", description = "Le séchage prend environ 2 heures.\nVous pouvez vaquer à vos occupations et reprendre ce tutoriel plus tard avec la commande : /resume-traitement-tuto" },
        { id = "collect_dried_plants", title = "Récupérer les plantes", description = "Une fois le temps écoulé, retournez à l'échelle pour décrocher vos plantes désormais sèches." },
        { id = "trim_and_pack", title = "Extraction et emballage", description = "Allez vers les chaises (à gauche) et appuyez sur [E] pour extraire les têtes.\nAttention : il vous faut au moins 100 pochons vides (achetables via Delivery-Service sur l'ordinateur)." }
    }, { color = "#1b8b0f" })

    if resume then
        SetObjectiveStep("wait_drying")
    end

    local labodata = null.data.illegals.laboratories.list[id]

    local lastLaboInfo = nil

    Citizen.CreateThread(function()
        while true do
            local currentStep = GetCurrentStepId()
            if not currentStep then return end

            if currentStep == "go_drying" then 
                if #(PlayerState.coords - Config.laboratoire.type["weed"].treatmentequipment.DryStair.pos) <= 4.0 then
                    SetObjectiveStep("hang_plants")
                end
            elseif currentStep == "wait_drying" then
                if lastLaboInfo == nil or (GetGameTimer() - lastLaboInfo > 5000) then
                    SetResourceKvp(ESX.Config("serverName").."null:labo:tutorial:treatment", tostring(id))

                    local nbr = 0
                    for k,v in pairs(labodata.treatmentequipment.indrying) do 
                        if v.finish then
                            nbr += 1 
                        end
                    end

                    if nbr > 0 then
                        SetObjectiveStep("collect_dried_plants")
                    end

                    lastLaboInfo = GetGameTimer()
                end
            end

            Wait(1)
        end
    end)
end)

RegisterCommand("resume-traitement-tuto", function()
    local kvpp = GetResourceKvpString(ESX.Config("serverName").."null:labo:tutorial:treatment")
    if kvpp and tonumber(kvpp) then
        TriggerEvent("null:labo:start-weed-traitement-tutorial", kvpp, true)
    end
end)