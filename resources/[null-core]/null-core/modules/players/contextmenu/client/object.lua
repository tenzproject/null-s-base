-- Définir les objets et leurs hachages pour GTA V
local objectModels = {
    { name = "prop_beachball_02", hash = GetHashKey("prop_beachball_02") },
    { name = "prop_lawnmower", hash = GetHashKey("prop_lawnmower") },
    { name = "prop_tool_bench02", hash = GetHashKey("prop_tool_bench02") }, 
    { name = "prop_rub_couch01", hash = GetHashKey("prop_rub_couch01") },
    { name = "prop_cs_duffel_bag", hash = GetHashKey("prop_cs_duffel_bag") },
    { name = "prop_cs_milk_crate", hash = GetHashKey("prop_cs_milk_crate") },
    { name = "prop_cs_whisky", hash = GetHashKey("prop_cs_whisky") },
    { name = "prop_tv_02", hash = GetHashKey("prop_tv_02") },
    { name = "prop_cs_heist_cash", hash = GetHashKey("prop_cs_heist_cash") },
    { name = "prop_phone_ing", hash = GetHashKey("prop_phone_ing") },
    { name = "prop_cs_burger_01", hash = GetHashKey("prop_cs_burger_01") },
    { name = "prop_amb_phone", hash = GetHashKey("prop_amb_phone") },
    { name = "prop_drug_package", hash = GetHashKey("prop_drug_package") },
    { name = "prop_roadcone01a", hash = GetHashKey("prop_roadcone01a") },
    { name = "prop_fib_plant", hash = GetHashKey("prop_fib_plant") },
    { name = "prop_bench_01", hash = GetHashKey("prop_bench_01") },
    { name = "prop_bottle_cap_01", hash = GetHashKey("prop_bottle_cap_01") },
    { name = "prop_ammobox_01a", hash = GetHashKey("prop_ammobox_01a") },
    { name = "prop_amb_phone", hash = GetHashKey("prop_amb_phone") },
    { name = "prop_beachball_02", hash = GetHashKey("prop_beachball_02") },
    { name = "prop_box_wood01a", hash = GetHashKey("prop_box_wood01a") },
    { name = "prop_chair_01a", hash = GetHashKey("prop_chair_01a") },
    { name = "prop_cigar", hash = GetHashKey("prop_cigar") },
    { name = "prop_cs_ciggy_01", hash = GetHashKey("prop_cs_ciggy_01") },
    { name = "prop_cs_drink", hash = GetHashKey("prop_cs_drink") },
    { name = "prop_cs_espresso", hash = GetHashKey("prop_cs_espresso") },
    { name = "prop_cs_shopping_bag", hash = GetHashKey("prop_cs_shopping_bag") },
    { name = "prop_dock_crane_01", hash = GetHashKey("prop_dock_crane_01") },
    { name = "prop_dock_light_01", hash = GetHashKey("prop_dock_light_01") },
    { name = "prop_gas_mask", hash = GetHashKey("prop_gas_mask") },
    { name = "prop_roadcone01a", hash = GetHashKey("prop_roadcone01a") },
    { name = "prop_sack_01", hash = GetHashKey("prop_sack_01") },
    { name = "prop_snowball", hash = GetHashKey("prop_snowball") },
    { name = "prop_wheelchair", hash = GetHashKey("prop_wheelchair") },
    { name = "prop_wine_bottle", hash = GetHashKey("prop_wine_bottle") },
    { name = "prop_xmas_tree_int", hash = GetHashKey("prop_xmas_tree_int") },
    -- Ajoutez d'autres objets ici si nécessaire
} 

function _Coffee()
    Action_Config = {
        Coffee = {
            {
                Type = "buttom-submenu",
                Label = "Acheter",
                CloseOnClick = true,
                Action = {
                    {
                        'Café (~g~10$~s~)', 
                        function() 
                            playAnim('mp_common', 'givetake2_a', 2500)
                            Citizen.Wait(2500)
                            local item = 'coffee'
                            local prix = 10
                            TriggerServerEvent('Acheter', item, prix)
                        end
                    },
                },
            },
            {
                Type = "buttom-submenu",
                CloseOnClick = true,
                Label = "Information de l'object",

                Action = {
                    {
                        ("ID de l'objet : %s"):format(LastEntityHit),
                        function()
                        end
                    },
                    {
                        ("Model de l'objet : %s"):format(GetEntityModel(LastEntityHit)),
                        function()
                            SendNUIMessage({type = "copy", text = GetEntityModel(LastEntityHit)})
                        end
                    },
                    {
                        ("Owner de l'objet : %s"):format(NetworkGetEntityOwner(LastEntityHit)),
                        function()
                        end
                    },
                    {
                        ("Position : %s"):format(GetEntityCoords(LastEntityHit)),
                        function()
                        end
                    },
                    {
                        ("Rotation : %s"):format(GetEntityRotation(LastEntityHit)),
                        function()
                        end
                    },
                    {
                        ("Type : %s"):format(GetEntityType(LastEntityHit)),
                        function()
                        end
                    },
                },    
            },
            {
                
                superadmin = "superadmin",
                Type = "buttom-submenu",
                Label = "Admin",
                Action = {
                    {
                        "Déplacé l'objet",
                        function() 
                            Target:MouveEntity(LastEntityHit)
                        end
                    },
                    {
                        "Dupliqué",
                        function() 
                            local new = Target:DuplicateEntity(LastEntityHit)
                            Target:MouveEntity(new)
                        end
                    },
                    {
                        "Suprimé",
                        function() 
                            SetEntityAsMissionEntity(LastEntityHit, false, false)
                            DeleteObject(LastEntityHit)
                        end
                    },
                },
            },
        },
    }
end

function _Atm()
    Action_Config = {
        Object = {
            {
                Type = "buttom",
                CloseOnClick = true,
                OnClick = function()
                    if not ESX.HasItem('bank_card') then
                        ESX.ShowNotification("~r~Vous n'avez pas de carte bancaire")
                        return
                    end
                    OpenAtmUI()
                end,
                Label = "Utiliser l'ATM",
            },
        },
    }
end

CurrentTrashEntity = nil

function _Trash()
    CurrentTrashEntity = LastEntityHit
    
    local coords = GetEntityCoords(CurrentTrashEntity)
    local hash = string.format("%.1f_%.1f_%.1f", coords.x, coords.y, coords.z)
    local cooldown = Config.TrashSearch and Config.TrashSearch.Cooldown or 300
    
    local searchedTrash = LocalPlayerState and LocalPlayerState.searchedTrash or {}
    local lastSearch = searchedTrash[hash]
    local now = GetGameTimer() / 1000
    local remaining = 0
    
    if lastSearch and (now - lastSearch) < cooldown then
        remaining = math.floor(cooldown - (now - lastSearch))
    end
    
    local label = remaining > 0 and ("Fouillée (" .. remaining .. "s)") or "Fouiller"
    
    Action_Config = {
        Object = {
            {
                Type = "buttom",
                CloseOnClick = remaining == 0,
                OnClick = function()
                    if remaining > 0 then
                        ESX.ShowNotification("~r~Cette poubelle a déjà été fouillée")
                        return
                    end
                    exports["null-core"].DoTrashSearch(CurrentTrashEntity)
                end,
                Label = label,
            },
        },
    }
end

function _Soda()
    Action_Config = {
        Soda = {
            {
                
                user = "user", -- SI VOUS METTEZ "user" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
                mod = "mod", -- SI VOUS METTEZ "mod" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
                admin = "admin", -- SI VOUS METTEZ "admin" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
                superadmin = "superadmin", -- SI VOUS METTEZ "superadmin" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
                _dev = "_dev", -- SI VOUS METTEZ "_dev" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
                owner = "owner", -- SI VOUS METTEZ "owner" CELA VOUDRA DIRE QUE TOUTE PERSONNE AVEC LE GRADE USER POURRA VOIR LE BOUTON !
				
                Type = "buttom-submenu",
                Label = "Acheter",
                CloseOnClick = true,
                Action = {
                    {
                        'Coca-cola (~g~10$~s~)', 
                        function() 
                            playAnim('mp_common', 'givetake2_a', 2500)
                            Citizen.Wait(2500)
                            local item = 'coca'
                            local prix = 10
                            TriggerServerEvent('Acheter', item, prix)
                        end
                    },
                    {
                        'Eau (~g~10$~s~)', 
                        function() 
                            playAnim('mp_common', 'givetake2_a', 2500)
                            Citizen.Wait(2500)
                            local item = 'water'
                            local prix = 10
                            TriggerServerEvent('Acheter', item, prix)
                        end
                    },
                    {
                        'Fanta (~g~10$~s~)', 
                        function() 
                            playAnim('mp_common', 'givetake2_a', 2500)
                            Citizen.Wait(2500)
                            local item = 'fanta'
                            local prix = 10
                            TriggerServerEvent('Acheter', item, prix)
                        end
                    },
                },
            },

        },
    }
end

function _Object()
    Action_Config = {
        Object = {
            -- {
            --     Type = "buttom",
            --     IsRestricted = false,
            --     CloseOnClick = true,
            --     Blocked = (function()
            --         local obj = GetEntityModel(LastEntityHit) 
            --         for name,data in pairs(Config.PropsInteraction) do
            --             for i,props in pairs(data.props) do
            --                 if obj == GetHashKey(props) then
            --                     return false
            --                 end
            --             end
            --         end
            --         return true
            --     end)(),
            --     Label = ("Intéragir avec l'objet"),
            --     OnClick = function()
            --         local obj = GetEntityModel(LastEntityHit) 
            --         local typeprops = nil
            --         for name,data in pairs(Config.PropsInteraction) do
            --             for i,props in pairs(data.props) do
            --                 if obj == GetHashKey(props) then
            --                     typeprops = name
            --                 end
            --             end
            --         end
            --         if not typeprops then return end
            --         InteractWithProps(LastEntityHit, typeprops)
            --     end,
            -- },
            {
                Type = "buttom",
                IsRestricted = false,
                CloseOnClick = false,
                Blocked = true,
                Label = ("Ouvrir/Fermer la porte"),
                OnClick = function()
                    exports.ox_doorlock:useClosestDoor()
                end,
            },
            {
                Type = "buttom",
                IsRestricted = false,
                CloseOnClick = false,
                Blocked = false,
                Label = ("ID de l'objet : %s"):format(LastEntityHit),
                OnClick = function()
                    exports["null-core"]:copy(LastEntityHit)
                end,
            },
            {
                Type = "buttom",
                IsAllowed = true,
                Blocked = false,
                CloseOnClick = true,
                Label = "S'asseoir",
                OnClick = function()
                    TriggerEvent('Boost-Sit:Sit')
                end,
            },
            {
                Type = "buttom",
                IsAllowed = true,
                Blocked = false,
                CloseOnClick = true,
                Label = "Freeze Props",
                OnClick = function()
                    local playerPed = PlayerPedId()
                    local coords = GetEntityCoords(playerPed)
                    local radius = 3.0  
                    local closestObject = nil
                    local closestDistance = radius
            
                    for object in EnumerateObjects() do
                        local objCoords = GetEntityCoords(object)
                        local distance = #(coords - objCoords)
                        
                        if distance < closestDistance then
                            closestDistance = distance
                            closestObject = object
                        end
                    end
            
                    if closestObject and DoesEntityExist(closestObject) then
                        NetworkRequestControlOfEntity(closestObject)
                        local attempts = 0
                        while not NetworkHasControlOfEntity(closestObject) and attempts < 20 do
                            NetworkRequestControlOfEntity(closestObject)
                            Citizen.Wait(50)
                            attempts = attempts + 1
                        end
            
                        if NetworkHasControlOfEntity(closestObject) then
                            FreezeEntityPosition(closestObject, true)
                        end
                    end
                end,
            },         
            {
                Type = "buttom",
                Label = ("Media"),
                IsRestricted = false,
                CloseOnClick = true,
                Blocked = false,
                OnClick = function() 
                    ExecuteCommand("pmms")
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
                        local obj = GetEntityModel(LastEntityHit) 
                        for _, objectModel in ipairs(objectModels) do
                            if obj == objectModel.hash then
                                return objectModel.name
                            end
                        end
                        return "Inconnu"  
                    end)()
                    ),
                    function()
                        local obj = GetEntityModel(LastEntityHit) 
                        local objectName = "Inconnu"  
                        for _, objectModel in ipairs(objectModels) do
                            if obj == objectModel.hash then
                                objectName = objectModel.name
                                break
                            end
                        end
                        print("Le modèle du props : " .. objectName)
                        exports["null-core"]:copy(objectName)
                    end,
                    },
                    {
                        ("hash : %s "):format(GetEntityModel(LastEntityHit)),
                        function()
                            print("Le hash du props : " .. GetEntityModel(LastEntityHit))
                            exports["null-core"]:copy(GetEntityModel(LastEntityHit))
                        end,
                    },
                    {
                        ("Position : %.2f, %.2f, %.2f"):format(GetEntityCoords(LastEntityHit).x, GetEntityCoords(LastEntityHit).y, GetEntityCoords(LastEntityHit).z),
                        function()
                            local objectposition = GetEntityCoords(LastEntityHit)
                            exports["null-core"]:copy("vector3("..objectposition.x..", "..objectposition.y..", "..objectposition.z..")")
                            print(("Position de l'objet : %s"):format("vector3("..objectposition.x..", "..objectposition.y..", "..objectposition.z..")"))
                        end,
                    },
                },
            },
             {
                Type = "buttom",
                IsRestricted = false,
                CloseOnClick = true,
                Blocked = function()
                    -- Vérifier si l'objet cliqué est un ground item (carton)
                    if not LastEntityHit or not DoesEntityExist(LastEntityHit) then
                        return true
                    end
                    
                    local groundItemId = exports['null-core']:GetGroundItemIdFromEntity(LastEntityHit)
                    return groundItemId == nil
                end,
                Label = "Ramasser les items",
                OnClick = function()
                    if not LastEntityHit or not DoesEntityExist(LastEntityHit) then
                        return
                    end
                    
                    local groundItemId = exports['null-core']:GetGroundItemIdFromEntity(LastEntityHit)
                    if groundItemId then
                        exports['null-core']:PickupGroundItem(groundItemId)
                    end
                end,
            },
            {
                Type = "buttom-submenu",
                Label = "Administration",
                IsRestricted = true,
                CloseOnClick = false,
                Action = {
                    
                    {
                        ("Proprietaire de l'objet : %s"):format(NetworkGetEntityOwner(LastEntityHit)),
                        function()
                            exports["null-core"]:copy(NetworkGetEntityOwner(LastEntityHit))
                        end,
                    },
                    {
                        ("Rotation : %s"):format(GetEntityRotation(LastEntityHit)),
                        function()
                            local vec3 = GetEntityRotation(LastEntityHit)
                            exports["null-core"]:copy("vector3("..vec3.x..", "..vec3.y..", "..vec3.z..")")
                        end,
                    },
                    {
                        ("Type : %s"):format(GetEntityType(LastEntityHit)),
                        function()
                        end,
                    },
                    {
                        ("Déplacer"),
                        function()
                            if (LastEntityHit ~= nil and DoesEntityExist(LastEntityHit)) then
                                useGizmo(LastEntityHit)
                    
                                local objCoords = GetEntityCoords(LastEntityHit)
                                local objHeading = GetEntityHeading(LastEntityHit)
                    
                                Citizen.Wait(100)
                    
                                SetEntityCoords(LastEntityHit, objCoords.x, objCoords.y, objCoords.z, false, false, false, true)
                                SetEntityHeading(LastEntityHit, objHeading)
                    
                                FreezeEntityPosition(LastEntityHit, true)
                                PlaceObjectOnGroundProperly(LastEntityHit)
                            end
                        end,
                    },                    
                    {
                        ("Dupliquer"),
                        function()
                            local new = Target:DuplicateEntity(LastEntityHit)
                            Target:MouveEntity(new)
                        end,
                    },
                    {
                        ("Suprimer"),
                        function()
                            SetEntityAsMissionEntity(LastEntityHit, false, false)
                            DeleteObject(LastEntityHit)
                        end,
                    }
                    
                },
            }
        },
    }
end
