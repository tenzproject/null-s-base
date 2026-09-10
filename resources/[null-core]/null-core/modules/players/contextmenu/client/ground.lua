while nTable == nil do Wait(10) end

checkboxStates = checkboxStates or {}
function _Ground()
    if IsAllowed() then
        local loaded = {
            [1] = false,
        }
        ESX.TriggerServerCallback('null:getOwnedCars', function(ownedCars, ownedCarsJobs, OwnedCarsOrg)
            localCarsOwned = ownedCars
            localCarsJobsOwned = ownedCarsJobs
            localCarsOrgOwned = OwnedCarsOrg
            loaded[1] = true
        end)
        while loaded[1] == false do Wait(10) end
    end
    local Stash = nil

    for k, v in pairs(Config.Stash) do
        if #(LastCoordsHit - v.pos) < 3.0 then
            Stash = k
            break
        end
    end

    Action_Config = {
        Ground = {
            {
                Type = "buttom",
                Blocked = (function()
                    if Stash ~= nil then 
                        return false 
                    else
                        return true 
                    end
                end)(),
                CloseOnClick = true,
                Label = "Ouvrir le carton",
                OnClick = function()
                    if Config.Stash[Stash].password ~= nil then 
                        local password = ESX.GetNumberInput("Code", 1, "Le code contient 4 chiffres.")
                        if password ~= nil then
                            ESX.TriggerServerCallback('null:getCoffre', function(data, id)
                                if data then
                                    local inventory = data
                                    inventory.weight = 0
                                    inventory.id = id
                                    inventory.maxWeight = Config.Stash[Stash].maxweight
                                    inventory.type = "STASH"
                                    TriggerEvent("inventory:openTarget",inventory)
                                end
                            end, "stash_"..Stash, "STASH", Config.Stash[Stash].maxweight)
                        else
                            return ESX.ShowNotification("~r~Le montant ne peut pas être nul")
                        end
                    else
                        ESX.TriggerServerCallback('null:getCoffre', function(data, id)
                            if data then
                                local inventory = data
                                inventory.weight = 0
                                inventory.id = id
                                inventory.maxWeight = Config.Stash[Stash].maxweight
                                inventory.type = "STASH"
                                TriggerEvent("inventory:openTarget",inventory)
                            end
                        end, "stash_"..Stash, "STASH", Config.Stash[Stash].maxweight)
                    end
                end,
            },
            {
                --IsRestricted = true,
                Type = "checkbox",  -- Ajout de la checkbox
                Label = "Mode Staff",  -- Texte affiché
                IsChecked = nTable.staffMode,  -- Valeur initiale de la checkbox
                --CloseOnClick = true,
                Blocked = (function()
                    if ESX.PlayerData.group ~= "user" then 
                        return false else 
                        return true 
                    end
                end)(),
                OnRelease = function(isChecked)  -- Action lors du changement d'état
                    ServiceStaff(isChecked)
                end,
            },
            {
                Type = "checkbox",  -- Ajout de la checkbox
                Label = "Eteindre le gps",  -- Texte affiché
                IsChecked = (function()
                    return IsRadarHidden()
                end)(),
                OnRelease = function(isChecked)  -- Action lors du changement d'état
                    if isChecked then
                        DisplayRadar(false)
                    else
                        DisplayRadar(true)
                    end
                end,
            },
            {
                IsRestricted = true,
                Type = "buttom",
                IsAllowed = true,
                Blocked = false,
                IsRestricted = true,
                CloseOnClick = true,
                KeepNuiFocus = true,
                Label = "Poser un PNJ",
                OnClick = function() 
                    ped_model = null.fct.input("Modele du PNJ")
                    if IsModelValid(ped_model) then
                        RequestModel(ped_model)
                        while not HasModelLoaded(ped_model) do
                            Wait(0)
                        end
                        ped = CreatePed(4, ped_model, LastCoordsHit, GetEntityHeading(PlayerPedId()), true, true)
                        SetEntityAsMissionEntity(ped, true, true)
                        SetModelAsNoLongerNeeded(ped_model)
                    end
                end,
            },
            {
                IsRestricted = true,
                Type = "buttom",
                IsAllowed = true,
                IsRestricted = true,
                Blocked = false,
                CloseOnClick = true,
                KeepNuiFocus = true,
                Label = "Poser un props",
                OnClick = function()
                    obj_model = null.fct.input("Modele du props")
                    if IsModelValid(obj_model) then
                        RequestModel(obj_model)
                        while not HasModelLoaded(obj_model) do
                            Wait(0)
                        end
                        obj = CreateObject(obj_model, LastCoordsHit, true, true, true)
                        SetEntityAsMissionEntity(obj, true, true)
                        SetModelAsNoLongerNeeded(obj_model)
                    end
                end,
            },
            {
                IsRestricted = true,
                Type = "buttom",
                IsAllowed = true,
                IsRestricted = true,
                Blocked = false,
                CloseOnClick = true,
                KeepNuiFocus = true,
                Label = "Poser une voiture",
                OnClick = function()
                    veh_model = null.fct.input("Modele de la voiture")
                    if IsModelValid(veh_model) then
                        RequestModel(veh_model)
                        while not HasModelLoaded(veh_model) do
                            Wait(0)
                        end
                        veh = CreateVehicle(veh_model, LastCoordsHit, GetEntityHeading(PlayerPedId()), true, true)
                        SetEntityAsMissionEntity(veh, true, true)
                        SetVehicleOnGroundProperly(veh)
                        SetModelAsNoLongerNeeded(veh_model)
                    end
                end,
            },  
            {
                IsRestricted = true,
                Type = "buttom-submenu",
                CloseOnClick = true,
                IsRestricted = true,
                Blocked = false,
                Label = "Poser une voiture du garage",
                Action = (function()
                    local actions = {}
                    for k,v in pairs(localCarsOwned) do
                        table.insert(actions, {
                            string.format("[%s] %s (Vous)", GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)),v.label or ""),
                            function()
                                SpawnVehicle(v.vehicle, v.plate, LastCoordsHit)
                            end
                        })
                    end
                    for k,v in pairs(localCarsJobsOwned) do
                        table.insert(actions, {
                            string.format("[%s] %s (Entreprise)", GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)),v.label or ""),
                            function()
                                SpawnVehicle(v.vehicle, v.plate, LastCoordsHit)
                            end
                        })
                    end
                    for k,v in pairs(localCarsOrgOwned) do
                        table.insert(actions, {
                            string.format("[%s] %s (Groupe Illégal)", GetLabelText(GetDisplayNameFromVehicleModel(v.vehicle.model)),v.label or ""),
                            function()
                                SpawnVehicle(v.vehicle, v.plate, LastCoordsHit)
                            end
                        })
                    end
            
                    return actions
                end)(),
            },
            -- {
            --     Type = "checkbox",  -- Ajout de la checkbox
            --     Label = "Activer la roue des armes",  -- Texte affiché
            --     IsChecked = (function()
            --         return not isUsingInterface()
            --     end)(),  -- Valeur initiale de la checkbox
            --     OnRelease = function(isChecked)  -- Action lors du changement d'état
            --         Config.Prefer.Enabled["interfaces"] = not isChecked
            --     end,
            -- },
            {
                IsRestricted = true,
                Type = "buttom-submenu",
                Label = "Outils de debug",
                Action = {
                    {
                        "Nettoyer la rue",
                        function()
                            ClearAllBrokenGlass()
                            ClearAllHelpMessages()
                            LeaderboardsReadClearAll()
                            ClearBrief()
                            ClearGpsFlags()
                            ClearPrints()
                            ClearSmallPrints()
                            ClearReplayStats()
                            LeaderboardsClearCacheData()
                            ClearFocus()
                            ClearHdArea()
                        end,
                    }                   
                },
            },
            {
                IsRestricted = true,
                Type = "buttom-submenu",
                Label = "Administration",
                Action = {
                    {
                        "Vous téléporter ici",
                        function()
                            SetEntityCoords(PlayerPedId(), LastCoordsHit)
                        end,
                    },
                    {
                        Type = "checkbox",
                        Label = "Gamertag",
                        IsChecked = nTable.gamerTag,
                        OnRelease = function(isChecked)
                            nTable.gamerTag = isChecked
                            showNames(isChecked)
                        end,
                    },                                 
                    {
                        Type = "checkbox",  -- Ajout de la checkbox
                        Label = "Blips Joueurs",  -- Texte affiché
                        IsChecked = nTable.blipActive,  -- Vérifie si la valeur existe
                        OnRelease = function(isChecked)  -- Action lors du changement d'état
                            nTable.blipActive = isChecked
                            TriggerServerEvent("null:staff:activeBlips", isChecked)
                        end,
                    }, 
                    {
                        Type = "checkbox",
                        Label = "StaffGun",
                        IsChecked = delGunStaffActive or false,
                        OnRelease = function(isChecked)
                            delGunStaffActive = isChecked
                            boolStaffGun()
                        end,
                    },    
                    {
                        Type = "checkbox",
                        Label = "Informations Staff",
                        IsChecked = nTable.adminHud,
                        OnRelease = function(isChecked)
                            toggleShowReport(nTable.TypeInfo)
                        end,
                    },  
                    
                },
            }
        },
    }
end