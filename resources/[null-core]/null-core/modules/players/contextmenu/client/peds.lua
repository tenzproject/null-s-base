local pedModels = {
    -- Modèles de Freemode (joueurs personnalisés)
    { name = "mp_m_freemode_01", hash = GetHashKey("mp_m_freemode_01") },
    { name = "mp_f_freemode_01", hash = GetHashKey("mp_f_freemode_01") },
    
    -- Modèles de PNJ masculins
    { name = "a_m_m_beach_01", hash = GetHashKey("a_m_m_beach_01") },
    { name = "a_m_m_beach_02", hash = GetHashKey("a_m_m_beach_02") },
    { name = "a_m_m_cyclist_01", hash = GetHashKey("a_m_m_cyclist_01") },
    { name = "a_m_m_fatlatin_01", hash = GetHashKey("a_m_m_fatlatin_01") },
    { name = "a_m_m_genfat_01", hash = GetHashKey("a_m_m_genfat_01") },
    { name = "a_m_m_ktown_01", hash = GetHashKey("a_m_m_ktown_01") },
    { name = "a_m_m_prolhost_01", hash = GetHashKey("a_m_m_prolhost_01") },
    { name = "a_m_m_salton_01", hash = GetHashKey("a_m_m_salton_01") },
    { name = "a_m_m_soucent_01", hash = GetHashKey("a_m_m_soucent_01") },
    { name = "a_m_m_soucent_02", hash = GetHashKey("a_m_m_soucent_02") },
    { name = "a_m_m_tourist_01", hash = GetHashKey("a_m_m_tourist_01") },
    
    -- Modèles de PNJ féminins
    { name = "a_f_m_beach_01", hash = GetHashKey("a_f_m_beach_01") },
    { name = "a_f_m_beach_02", hash = GetHashKey("a_f_m_beach_02") },
    { name = "a_f_m_downtown_01", hash = GetHashKey("a_f_m_downtown_01") },
    { name = "a_f_m_fatlatin_01", hash = GetHashKey("a_f_m_fatlatin_01") },
    { name = "a_f_m_genfat_01", hash = GetHashKey("a_f_m_genfat_01") },
    { name = "a_f_m_ktown_01", hash = GetHashKey("a_f_m_ktown_01") },
    { name = "a_f_m_prolhost_01", hash = GetHashKey("a_f_m_prolhost_01") },
    { name = "a_f_m_salton_01", hash = GetHashKey("a_f_m_salton_01") },
    { name = "a_f_m_soucent_01", hash = GetHashKey("a_f_m_soucent_01") },
    { name = "a_f_m_soucent_02", hash = GetHashKey("a_f_m_soucent_02") },
    { name = "a_f_m_tourist_01", hash = GetHashKey("a_f_m_tourist_01") },
    
    -- Modèles spécifiques (en fonction des missions ou événements)
    { name = "u_m_y_abner", hash = GetHashKey("u_m_y_abner") },
    { name = "u_m_y_antonb", hash = GetHashKey("u_m_y_antonb") },
    { name = "u_m_y_babyd", hash = GetHashKey("u_m_y_babyd") },
    { name = "u_m_y_banhammer", hash = GetHashKey("u_m_y_banhammer") },
    { name = "u_m_y_baygor", hash = GetHashKey("u_m_y_baygor") },
    { name = "u_m_y_burgerdrug", hash = GetHashKey("u_m_y_burgerdrug") },
    
    -- Modèles d'animaux
    { name = "a_c_chop", hash = GetHashKey("a_c_chop") },
    { name = "a_c_cat_01", hash = GetHashKey("a_c_cat_01") },
    { name = "a_c_dolphin", hash = GetHashKey("a_c_dolphin") },
    { name = "a_c_husky", hash = GetHashKey("a_c_husky") },
    { name = "a_c_pig", hash = GetHashKey("a_c_pig") },
    
    -- Modèles divers
    { name = "csb_ambientwhitelong", hash = GetHashKey("csb_ambientwhitelong") },
    { name = "csb_ballasog", hash = GetHashKey("csb_ballasog") },
    { name = "csb_cletus", hash = GetHashKey("csb_cletus") },
    { name = "csb_debra", hash = GetHashKey("csb_debra") },
    { name = "csb_doreen", hash = GetHashKey("csb_doreen") },
    { name = "csb_hugh", hash = GetHashKey("csb_hugh") },
    -- Vous pouvez en rajouter d'autre
}

local drugSellPedCooldown = {}
local drugSellInProgress = false
local pendingDrugSellPed = nil

local function canSellDrugsToPed(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return false end
    if ped == PlayerPedId() or IsPedAPlayer(ped) then return false end
    if not IsPedHuman(ped) or IsPedDeadOrDying(ped, true) then return false end
    if IsPedInAnyVehicle(ped, false) or IsPedFleeing(ped) then return false end
    if GetGameTimer() < (drugSellPedCooldown[ped] or 0) then return false end
    return true
end

local function playDrugSellAttempt(ped)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local pedCoords = GetEntityCoords(ped)

    ClearPedTasks(ped)
    TaskTurnPedToFaceCoord(playerPed, pedCoords.x, pedCoords.y, pedCoords.z, 1000)
    TaskTurnPedToFaceCoord(ped, playerCoords.x, playerCoords.y, playerCoords.z, 1000)
    Wait(1000)

    FreezeEntityPosition(playerPed, true)
    FreezeEntityPosition(ped, true)

    local dict, anim = "mp_common", "givetake1_a"
    ESX.Streaming.RequestAnimDict(dict)
    TaskPlayAnim(playerPed, dict, anim, -1.0, -1.0, 1800, 0, 0, true, true, true)
    TaskPlayAnim(ped, dict, anim, -1.0, -1.0, 1800, 0, 0, true, true, true)
    Wait(1600)

    FreezeEntityPosition(playerPed, false)
    FreezeEntityPosition(ped, false)
end

local function sellDrugsToContextPed()
    local ped = LastEntityHit
    if drugSellInProgress then return end
    if not canSellDrugsToPed(ped) then
        ESX.ShowNotification("Vous ne pouvez pas vendre à cette personne.")
        return
    end
    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ped)) > 3.0 then
        ESX.ShowNotification("Vous êtes trop loin.")
        return
    end
    if GetSelectedPedWeapon(PlayerPedId()) ~= GetHashKey('WEAPON_UNARMED') then
        ESX.ShowNotification("❌ Vous devez ranger votre arme.")
        return
    end

    drugSellInProgress = true
    playDrugSellAttempt(ped)

    local pedNetId = NetworkGetNetworkIdFromEntity(ped)
    local coords = GetEntityCoords(PlayerPedId())
    pendingDrugSellPed = ped
    TriggerServerEvent("territories:sellDrugsToPed", pedNetId, { x = coords.x, y = coords.y, z = coords.z })
    Citizen.SetTimeout(2500, function()
        drugSellInProgress = false
    end)
end

RegisterNetEvent("null:territories:npcSellResult", function(pedNetId, result)
    if not pedNetId then return end
    local ped = NetworkGetEntityFromNetworkId(pedNetId)
    if (not ped or ped == 0 or not DoesEntityExist(ped)) and pendingDrugSellPed and DoesEntityExist(pendingDrugSellPed) then
        ped = pendingDrugSellPed
    end
    pendingDrugSellPed = nil
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end

    if result == "success" then
        drugSellPedCooldown[ped] = GetGameTimer() + (10 * 60 * 1000)
        ClearPedTasks(ped)
        TaskWanderStandard(ped, 10.0, 10)
    elseif result == "refused" then
        drugSellPedCooldown[ped] = GetGameTimer() + (2 * 60 * 1000)
        ClearPedTasks(ped)
        TaskSmartFleePed(ped, PlayerPedId(), 60.0, 20000, false, false)
    elseif result == "nodrugs" or result == "blocked" or result == "cooldown" then
        ClearPedTasks(ped)
    end
end)



function _Peds()
    local employeeInfo = nil
    
    if PlayerState and PlayerState.Illegals and PlayerState.Illegals.laboratories and PlayerState.Illegals.laboratories.inLabo then
        -- Envoyer le NetworkId du ped au lieu de l'entité directement
        local pedNetId = NetworkGetNetworkIdFromEntity(LastEntityHit)
        ESX.TriggerServerCallback("null:labo:getEmployeeInfoFromPed", function(info)
            employeeInfo = info
        end, pedNetId)
        
        Wait(100)
    end
    
    Action_Config = {
        Peds = {}
    }
    
    if employeeInfo then
        table.insert(Action_Config.Peds, {
            Type = "buttom",
            IsRestricted = false,
            Blocked = false,
            CloseOnClick = false,
            Label = "Employé: " .. employeeInfo.name,
            OnClick = function() end,
        })
        
        table.insert(Action_Config.Peds, {
            Type = "buttom",
            IsRestricted = false,
            Blocked = false,
            CloseOnClick = false,
            Label = "Fatigue: " .. employeeInfo.fatigue .. "%",
            OnClick = function() end,
        })
        
        table.insert(Action_Config.Peds, {
            Type = "buttom",
            IsRestricted = false,
            Blocked = false,
            CloseOnClick = false,
            Label = "Tâche: " .. employeeInfo.currentTask,
            OnClick = function() end,
        })
        
        if employeeInfo.inventory and #employeeInfo.inventory > 0 then
            local inventoryActions = {}
            
            for _, item in ipairs(employeeInfo.inventory) do
                table.insert(inventoryActions, {
                    item.name .. " x" .. item.count,
                    function()
                        local count = null.fct.input("Quantité à retirer (max: " .. item.count .. ")")
                        if count == nil then return end
                        count = tonumber(count)
                        if count and count > 0 and count <= item.count then
                            TriggerServerEvent("null:labo:removeEmployeeItem", employeeInfo.labId, employeeInfo.employeeId, item.name, count)
                            ESX.ShowNotification("~g~" .. count .. "x " .. item.name .. " retiré de l'inventaire")
                        else
                            ESX.ShowNotification("~r~Quantité invalide")
                        end
                    end
                })
            end
            
            table.insert(Action_Config.Peds, {
                Type = "buttom-submenu",
                Label = "Inventaire (" .. #employeeInfo.inventory .. " items)",
                Blocked = false,
                IsRestricted = false,
                CloseOnClick = false,
                Action = inventoryActions
            })
        else
            table.insert(Action_Config.Peds, {
                Type = "buttom",
                IsRestricted = false,
                Blocked = false,
                CloseOnClick = false,
                Label = "Inventaire: Vide",
                OnClick = function() end,
            })
        end
        
        table.insert(Action_Config.Peds, {
            Type = "separator",
        })
    end

    if canSellDrugsToPed(LastEntityHit) then
        table.insert(Action_Config.Peds, {
            Type = "buttom",
            IsRestricted = false,
            Blocked = false,
            CloseOnClick = true,
            Label = "Vendre de la drogue",
            OnClick = sellDrugsToContextPed,
        })
    end
    
    table.insert(Action_Config.Peds, {
        Type = "buttom-submenu",
        Label = "Animations",
        Blocked = false,
        IsRestricted = false,
        CloseOnClick = true,
        Action = {
            {
                'Donner une claque',
                function()
                    pram = {
                        ['Requester'] = {
                            ['Type'] = 'animation', ['Dict'] = 'melee@unarmed@streamed_variations', ['Anim'] = 'plyr_takedown_front_slap', ['Flags'] = 0,
                        },
                        ['Accepter'] = {
                            ['Type'] = 'animation', ['Dict'] = 'melee@unarmed@streamed_variations', ['Anim'] = 'victim_takedown_front_slap', ['Flags'] = 0, ['Attach'] = {
                                ['Bone'] = 9816,
                                ['xP'] = 0.05,
                                ['yP'] = 1.15,
                                ['zP'] = -0.05,
                            
                                ['xR'] = 0.0,
                                ['yR'] = 0.0,
                                ['zR'] = 180.0,
                            }
                        }
                    }
                    ClearPedTasksImmediately(LastEntityHit)
                    ClearPedTasksImmediately(PlayerPedId())
                    RequestAnimDict(pram['Requester']['Dict'])
                    while not HasAnimDictLoaded(pram['Requester']['Dict']) do
                        print("Chargement de l'animation en cours...")
                        Citizen.Wait(0)
                    end
                    AttachEntityToEntity(PlayerPedId(), LastEntityHit, GetPedBoneIndex(LastEntityHit, pram['Accepter']['Attach']['Bone']), pram['Accepter']['Attach']['xP'], pram['Accepter']['Attach']['yP'], pram['Accepter']['Attach']['zP'], pram['Accepter']['Attach']['xR'], pram['Accepter']['Attach']['yR'], pram['Accepter']['Attach']['zR'], true, true, false, true, 1, true)
                    TaskPlayAnim(PlayerPedId(), pram['Requester']['Dict'], pram['Requester']['Anim'], 8.0, -8.0, -1, pram['Requester']['Flags'], 0, false, false, false)
                    TaskPlayAnim(LastEntityHit, pram['Accepter']['Dict'], pram['Accepter']['Anim'], 8.0, -8.0, -1, pram['Accepter']['Flags'], 0, false, false, false)
                    Citizen.Wait(1000)
                    while IsEntityPlayingAnim(PlayerPedId(), pram['Requester']['Dict'], pram['Requester']['Anim'], 3) do
                        Citizen.Wait(0)
                    end
                    DetachEntity(PlayerPedId(), true, false)
                    ClearPedTasksImmediately(LastEntityHit)
                    ClearPedTasksImmediately(PlayerPedId())
                end,
            },
            {
                'Serrer la main',
                function()
                    pram = {
                        ['Requester'] = {
                            ['Type'] = 'animation', ['Dict'] = 'mp_common', ['Anim'] = 'givetake1_a', ['Flags'] = 0,
                        },
                        ['Accepter'] = {
                            ['Type'] = 'animation', ['Dict'] = 'mp_common', ['Anim'] = 'givetake1_b', ['Flags'] = 0, ['Attach'] = {
                                ['Bone'] = 9816,
                                ['xP'] = 0.075,
                                ['yP'] = 1.0,
                                ['zP'] = 0.0,
                                ['xR'] = 0.0,
                                ['yR'] = 0.0,
                                ['zR'] = 180.0,
                            }
                        }
                    }
                    ClearPedTasksImmediately(LastEntityHit)
                    ClearPedTasksImmediately(PlayerPedId())
                    RequestAnimDict(pram['Requester']['Dict'])
                    while not HasAnimDictLoaded(pram['Requester']['Dict']) do
                        print("Chargement de l'animation en cours...")
                        Citizen.Wait(0)
                    end
                    AttachEntityToEntity(PlayerPedId(), LastEntityHit, GetPedBoneIndex(LastEntityHit, pram['Accepter']['Attach']['Bone']), pram['Accepter']['Attach']['xP'], pram['Accepter']['Attach']['yP'], pram['Accepter']['Attach']['zP'], pram['Accepter']['Attach']['xR'], pram['Accepter']['Attach']['yR'], pram['Accepter']['Attach']['zR'], true, true, false, true, 1, true)
                    TaskPlayAnim(PlayerPedId(), pram['Requester']['Dict'], pram['Requester']['Anim'], 8.0, -8.0, -1, pram['Requester']['Flags'], 0, false, false, false)
                    TaskPlayAnim(LastEntityHit, pram['Accepter']['Dict'], pram['Accepter']['Anim'], 8.0, -8.0, -1, pram['Accepter']['Flags'], 0, false, false, false)
                    Citizen.Wait(1000)
                    while IsEntityPlayingAnim(PlayerPedId(), pram['Requester']['Dict'], pram['Requester']['Anim'], 3) do
                        Citizen.Wait(0)
                    end
                    DetachEntity(PlayerPedId(), true, false)
                    ClearPedTasksImmediately(LastEntityHit)
                    ClearPedTasksImmediately(PlayerPedId())
                end,
            },
            {
                Type = "buttom-submenu",
                Label = "Outils de debug",
                IsRestricted = false,
                CloseOnClick = false,
                Action = {
                    {
    
                    ("Modèle : %s"):format(
                         (function()
                         local model = GetEntityModel(LastEntityHit)
                         for _, pedModel in ipairs(pedModels) do
                            if model == pedModel.hash then
                                return pedModel.name
                            end
                        end
                        return "Inconnu"  
                    end)()
                    ),
                    function()
                        local model = GetEntityModel(LastEntityHit)
                        local modelName = "Inconnu"  

                        for _, pedModel in ipairs(pedModels) do
                            if model == pedModel.hash then
                                modelName = pedModel.name
                                break
                            end
                        end
                        print("Le modèle du ped : " .. modelName)
                    end,
                    },
                    {
                        ("Position : %.2f, %.2f, %.2f"):format(GetEntityCoords(LastEntityHit).x, GetEntityCoords(LastEntityHit).y, GetEntityCoords(LastEntityHit).z),
                        function()
                            local pedposition = GetEntityCoords(LastEntityHit)
                            print(("Position du ped : %s"):format(pedposition))
                        end,
                    },
                },
            },
            {
                Type = "buttom-submenu",
                Label = "Administration",
                IsRestricted = true,
                CloseOnClick = false,
                Action = {
                    
                    {
                        "Supprimer",
                        function()
                            DeleteEntity(LastEntityHit)
                        end,
                    },
                    {
                        "Déplacer",
                        function()
                            if LastEntityHit and DoesEntityExist(LastEntityHit) then
                                useGizmo(LastEntityHit)
                    
                                Citizen.SetTimeout(500, function()
                                    if DoesEntityExist(LastEntityHit) then
                                        local coords, heading = GetEntityCoords(LastEntityHit), GetEntityHeading(LastEntityHit)
                    
                                        SetEntityCoords(LastEntityHit, coords.x, coords.y, coords.z, false, false, false, true)
                                        SetEntityHeading(LastEntityHit, heading)
                                        PlaceObjectOnGroundProperly(LastEntityHit)
                                    end
                                end)
                            end
                        end,
                    },                    
                    {
                        "Prendre l'aparence",
                        function()
                            model = GetEntityModel(LastEntityHit)
                            SetPlayerModel(PlayerId(), model)
                            SetPedDefaultComponentVariation(PlayerPedId())
                        end,
                    },
                    {
                        "Téléporté sur lui",
                        function()
                            SetEntityCoords(PlayerPedId(), GetEntityCoords(LastEntityHit))
                        end,
                    },
                    {
                        "Téléporté à moi",
                        function()
                            SetEntityCoords(LastEntityHit, GetEntityCoords(PlayerPedId()))
                        end,
                    },
                    {
                        "Retirer Toute ces armes",
                        function()
                            RemoveAllPedWeapons(LastEntityHit)
                        end
                    },
                    {
                        "Apaiser",
                        function()
                            ClearPedTasksImmediately(LastEntityHit)
                        end,
                    },
                    {
                        "Changer la tenue",
                        function()
                            SetPedRandomComponentVariation(LastEntityHit, true)
                        end,
                    },
                    {
                        "Faire fuir",
                        function()
                            TaskSmartFleePed(LastEntityHit, PlayerPedId(), 100.0, -1, false, false)
                        end,
                    },
                    {
                        "Rendre invincible",
                        function()
                            toggleEntityInvincible(LastEntityHit, true)
                        end,
                    },
                    {
                        "Rendre immobile",
                        function()
                            FreezeEntityPosition(LastEntityHit, true)
                        end,
                    },
                    {
                        "Rendre mobile",
                        function()
                            FreezeEntityPosition(LastEntityHit, false)
                        end,
                    }
                }
            }
        },
    })
end
