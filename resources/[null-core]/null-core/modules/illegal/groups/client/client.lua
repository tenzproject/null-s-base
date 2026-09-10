local PermSelected = "perms_coffre"
local PermsList = {
    [1] = {name = "perms_coffre", label = "Grade ayant accés au coffre"},
    [2] = {name = "perms_recruter", label = "Grade pouvant recruter"},
    [3] = {name = "perms_promouvoir", label = "Grade pouvant promouvoir"},
    [4] = {name = "perms_gestionmembre", label = "Grade ayant accés a la gestion des membres"},
}
 
local KitArme = false
local KitArmeFab = false
local Point = 0
local namegang = 'Aucun'
local labelgang = 'Aucun'
local posCoffre = 'Aucune'

Citizen.CreateThread(function()
    Wait(2000)
    TriggerServerEvent('null:initGangs')
end)

local zones = {}
InGangZone = false
GangZoneName = nil
GangZoneLabel = nil

RegisterNetEvent('null:SendGangListToClient', function(table)
    null.data.illegals.groups.list = table
    null.data.illegals.groups.loaded = true
end) 

exports("getGroupIllegalInfo", function()
    return null.data.illegals.groups.list, null.data.illegals.groups.loaded
end)

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    null.fct.waitPlayerLoaded()
    while not null.data.illegals.groups.loaded do 
        Wait(1)
    end

    for k,v in pairs(null.data.illegals.groups.list) do
        if v.zone ~= nil and #v.zone >= 3 then
            local polyzone = PolyZone:Create(v.zone, {
                name = ("gang_%s"):format(v.name),
                data = {
                    pos = v.posCoffre,
                    name = v.name,
                    label = v.label,
                    notified = false,
                }
            })
            table.insert(zones, polyzone)

            polyzone:onPlayerInOut(function(isPointInside, point)
                if isPointInside then
                    PlayerStateInGangZone = true
                    PlayerStateGangZoneName = v.name
                    PlayerStateGangZoneLabel = v.label
                elseif not isPointInside and PlayerStateGangZoneName == v.name then
                    PlayerStateInGangZone = false
                end
            end)
        end
    end

    while true do
        if PlayerStateInGangZone and ESX.PlayerData.job2.name ~= PlayerStateGangZoneName then
            DrawMissionText("Vous êtes dans une zone dangereuse", 5000)
        end
        
        Wait(5000)
    end
end))

Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    while not null.data.illegals.groups.loaded do 
        Wait(1)
    end

    for k,v in pairs(null.data.illegals.groups.list) do
        -- Coffre marker: directly opens society inventory
        -- (posCoffre peut être vide '{}' tant qu'aucun point n'a été posé)
        if v.posCoffre and v.posCoffre.x and v.posCoffre.y and v.posCoffre.z
            and not null.data.markers.isRegister("gang_coffre_"..v.name) then
            null.data.markers.register("gang_coffre_"..v.name, {
                Position = vector3(v.posCoffre.x, v.posCoffre.y, v.posCoffre.z),
                Public = false,
                Job = nil,
                Job2 = v.name,
                Action = function()
                    local gangData = null.data.illegals.groups.list[ESX.PlayerData.job2.name]
                    if gangData and gangData.perms_coffre and gangData.perms_coffre[tostring(ESX.PlayerData.job2.grade)] then
                        ESX.TriggerServerCallback('null:getCoffre', function(data, id)
                            if data then
                                local inventory = data
                                inventory.weight = 0
                                inventory.id = id
                                inventory.maxWeight = 1000
                                inventory.type = "SOCIETY"
                                TriggerEvent("inventory:openTarget", inventory)
                            end
                        end, ESX.PlayerData.job2.name, "SOCIETY", 1000)
                    else
                        ESX.ShowNotification("~r~Vous n'avez pas accès au coffre")
                    end
                end
            })
        end

        -- Fabrication marker: opens inventory craft table (if FabArme and posFabrication exist)
        if (v.FabArme == 1 or v.FabArme == true) and v.posFabrication then
            if not null.data.markers.isRegister("gang_fabrication_"..v.name) then
                local craftTableId = "gang_craft_" .. v.name
                null.data.markers.register("gang_fabrication_"..v.name, {
                    Position = vector3(v.posFabrication.x, v.posFabrication.y, v.posFabrication.z),
                    Public = false,
                    Job = nil,
                    Job2 = v.name,
                    Action = function()
                        local gangData = null.data.illegals.groups.list[ESX.PlayerData.job2.name]
                        if gangData and gangData.perms_fabrication and gangData.perms_fabrication[tostring(ESX.PlayerData.job2.grade)] then
                            if _G.OpenCraftTable then
                                _G.OpenCraftTable(craftTableId)
                            else
                                ESX.ShowNotification("~r~Système de craft non disponible")
                            end
                        else
                            ESX.ShowNotification("~r~Vous n'avez pas accès à la fabrication")
                        end
                    end
                })
            end
        end
    end
end)

local blipsinitialise = false
local gangblip = nil
Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    while not null.data.illegals.groups.loaded do 
        Wait(1)
    end

    while not blipsinitialise do
        local isProche = false
        for k,v in pairs(null.data.illegals.groups.list) do
            if ESX.PlayerData.job2.name == v.name then
                -- RequestStreamedTextureDict("world_blips", 1)
                -- while not HasStreamedTextureDictLoaded("world_blips") do
                --     Wait(0)
                -- end
                
                if v.posCoffre and v.posCoffre.x and v.posCoffre.y and v.posCoffre.z then
                    gangblip = AddBlipForCoord(vector3(v.posCoffre.x, v.posCoffre.y, v.posCoffre.z))
                    SetBlipSprite (gangblip, 408)
                    SetBlipDisplay(gangblip, 6)
                    SetBlipScale  (gangblip, 0.7)
                    SetBlipColour (gangblip, 6)
                    SetBlipAsShortRange(gangblip, true)
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentString("QG groupe illégal")
                    EndTextCommandSetBlipName(gangblip)
                end
                blipsinitialise = true
            end
        end
        
        if isProche then
            Wait(0)
        else
            Wait(750)
        end
    end
end)

RegisterNetEvent('esx:setJob2')
AddEventHandler('esx:setJob2', function(job2)
	ESX.PlayerData.job2 = job2
    RemoveBlip(gangblip)
    Wait(100)
    initBlipsGang()
end)

function initBlipsGang()
    for k,v in pairs(null.data.illegals.groups.list) do
        if ESX.PlayerData.job2.name == v.name then
            -- RequestStreamedTextureDict("world_blips", 1)
            -- while not HasStreamedTextureDictLoaded("world_blips") do
            --     Wait(0)
            -- end
            
            if v.posCoffre and v.posCoffre.x and v.posCoffre.y and v.posCoffre.z then
                gangblip = AddBlipForCoord(vector3(v.posCoffre.x, v.posCoffre.y, v.posCoffre.z))
                SetBlipSprite (gangblip, 408)
                SetBlipDisplay(gangblip, 6)
                SetBlipScale  (gangblip, 0.7)
                SetBlipColour (gangblip, 6)
                SetBlipAsShortRange(gangblip, true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString("QG Gang/Organisation")
                EndTextCommandSetBlipName(gangblip)
            end
            blipsinitialise = true
        end
    end
end


local dirtycash = 0
function OpenCoffreGang(pos)
    FreezeEntityPosition(PlayerPedId(), true)
	local menu = RageUI.CreateMenu("", "Actions Disponibles")
    local OpenBuyWeaponMenu = RageUI.CreateSubMenu(menu, '', 'Armes disponible')
    local OpenFabWeaponMenu = RageUI.CreateSubMenu(menu, '', 'Fabrications disponible')
    local GestionGrade1 = RageUI.CreateSubMenu(menu, '', 'Gestion Grades')
    local GestionGrade = RageUI.CreateSubMenu(menu, '', 'Gestion Permissions')
    local GestionGradePerm = RageUI.CreateSubMenu(GestionGrade, '', 'Grade ayant acces au coffre')
    local GestionGradePermCoffre = RageUI.CreateSubMenu(GestionGrade, '', 'Grade ayant acces au coffre')
    local GestionGradePermGestionMembre = RageUI.CreateSubMenu(GestionGrade, '', 'Grade ayant acces a la liste des membres')
    local GestionGradePermVenteArme = RageUI.CreateSubMenu(GestionGrade, '', 'Grade ayant acces a la vente d\'arme')
    local GestionGradePermFabriationArme = RageUI.CreateSubMenu(GestionGrade, '', 'Grade ayant acces a la fabrication d\'arme')
    local GestionGradePermRecruter = RageUI.CreateSubMenu(GestionGrade, '', 'Grade pouvant recruter/virer')
    local GestionGradePermPromouvoir = RageUI.CreateSubMenu(GestionGrade, '', 'Grade pouvant promouvoir/retrograder')
    local MembreList = RageUI.CreateSubMenu(menu, '', 'Liste des Membres')
    local GestionMembre = RageUI.CreateSubMenu(MembreList, '', 'Gestions Membres')
    local GestionRecrutement = RageUI.CreateSubMenu(menu, '', 'Gestions Recrutement')
    local GestionMembreGrade = RageUI.CreateSubMenu(GestionMembre, '', 'Changer le grade')
    RageUI.Visible(menu, not RageUI.Visible(menu))

    TriggerServerEvent("null:initGangs")

    ESX.TriggerServerCallback('GangsBuilder:getDirtyCash', function(result)
        dirtycash = result
    end)
    --print("society_"..ESX.PlayerData.job2.name)

	while menu do
        if NullInventory.isOpen then  
            return
        end
		Citizen.Wait(0)
        RageUI.IsVisible(menu, function()
            -- RageUI.Line()
            -- if ESX.PlayerData.job2.grade_name == 'boss' then
            --     RageUI.Button("Permissions", nil, {RightLabel = ""}, true, {
            --         onSelected = function()
                        
            --         end
            --     }, GestionGrade)
            -- end
            -- if null.data.illegals.groups.list[ESX.PlayerData.job2.name].perms_promouvoir[tostring(ESX.PlayerData.job2.grade)] or null.data.illegals.groups.list[ESX.PlayerData.job2.name].perms_recruter[tostring(ESX.PlayerData.job2.grade)] then
            --     RageUI.Button("Recrutement", nil, {RightLabel = ""}, true, {
            --         onSelected = function()
                        
            --         end
            --     }, GestionRecrutement)
            -- end
            --[[RageUI.Button('Facture', nil, {}, true, {
                onSelected = function() 
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

                    if closestPlayer == -1 or closestDistance > 3.0 then
                        ESX.ShowNotification('Il n\'y a aucun joueurs au alentours')
                    else
                        local string = null.fct.input('Montant', false, 9000000, "number")
                        if string ~= "" then
                            Montant = tonumber(string)
                        end
                        TriggerServerEvent("Core:AddBilling", GetPlayerServerId(closestPlayer), tonumber(Montant), ESX.PlayerData.job2.name)
                    end
                end
            })]]
        
            if null.data.illegals.groups.list[ESX.PlayerData.job2.name].perms_vente[tostring(ESX.PlayerData.job2.grade)] then
                if null.data.illegals.groups.list[ESX.PlayerData.job2.name].KitArme == 1 or null.data.illegals.groups.list[ESX.PlayerData.job2.name].KitArme == true then 
                    RageUI.Button('BlackMarket', nil, {RightLabel = ""}, true, {
                        onSelected = function() 
                      
                        end
                    }, OpenBuyWeaponMenu);
                end
            end
            if null.data.illegals.groups.list[ESX.PlayerData.job2.name].perms_coffre[tostring(ESX.PlayerData.job2.grade)] then
                RageUI.Button('Inventaire', nil, {}, true, {
                    onSelected = function()
                        --openPutWeaponGang()
                        RageUI.CloseAll()
                        local data2 = 'data'
                        ESX.TriggerServerCallback('null:getCoffre', function(data, id)
                            if data then
                                local inventory = data
                                inventory.weight = 0
                                inventory.id = id
                                inventory.maxWeight = 1000
                                inventory.type = "SOCIETY"
                                TriggerEvent("inventory:openTarget",inventory)
                            end
                        end, ESX.PlayerData.job2.name, "SOCIETY", 1000)
                    end
                })
            end
            if null.data.illegals.groups.list[ESX.PlayerData.job2.name].perms_fabrication[tostring(ESX.PlayerData.job2.grade)] then
                if null.data.illegals.groups.list[ESX.PlayerData.job2.name].FabArme == 1 or null.data.illegals.groups.list[ESX.PlayerData.job2.name].FabArme == true then 
                    RageUI.Button('Fabrications Armes', nil, {RightLabel = ""}, true, {
                        onSelected = function() 
                      
                        end
                    }, OpenFabWeaponMenu);
                end
            end
            -- if null.data.illegals.groups.list[ESX.PlayerData.job2.name].perms_gestionmembre[tostring(ESX.PlayerData.job2.grade)] then
            --     RageUI.Button("Liste des employés", nil, {Null = {id = "boss-plylistgang", LoadingOnSelect = 400, description = "Chargement de la liste des membres."}}, true, {
            --         onSelected = function()
            --             ESX.TriggerServerCallback("Null:GetMemberOfGangs", function(result) 
            --                 null.data.illegals.groups.list[ESX.PlayerData.job2.name].PlyList = result
            --             end, "boss", ESX.PlayerData.job2.name)
            --         end
            --     }, MembreList)
            -- end
            -- if ESX.PlayerData.job2.grade_name == 'boss' then
            --     RageUI.Button("Gerer les grades", nil, {RightLabel = ""}, true, {
            --         onSelected = function()
                        
            --         end
            --     }, GestionGrade1)
            -- end
            -- RageUI.Line()
        end)
        RageUI.IsVisible(GestionGrade1, function()
            RageUI.Button("Ajouter un grade", nil, {Color = { BackgroundColor = {255,244,79, 150} }}, true, {
                onSelected = function()
                    LabelGrade = null.fct.input("Nom du Grade")
                    if LabelGrade == nil then return end
                    TriggerServerEvent("null:illegal:gangsbuilder:addgrade", ESX.PlayerData.job2.name, LabelGrade)
                end
            })
            RageUI.Line()
            for k,v in pairs(null.data.illegals.groups.list[ESX.PlayerData.job2.name].GradeList) do
                if v.name == "boss" then
                    RageUI.Button(v.label.."", nil, {}, false, {
                        onSelected = function() 
                            
                        end
                    })
                else
                    RageUI.Button(v.label.."", "Appuyez sur [ENTRER] pour supprimer le grade", {}, true, {
                        onSelected = function() 
                            TriggerServerEvent("null:illegal:gangsbuilder:removegrade", ESX.PlayerData.job2.name, v.name, k)
                        end
                    })
                end
            end
        end)

        RageUI.IsVisible(OpenBuyWeaponMenu, function()
            if null.data.illegals.groups.list[ESX.PlayerData.job2.name].KitArme then
                for k,v in pairs(Config.IllegalGroups.Sell.Weapons) do 
                    RageUI.Button("Arme: "..v.label.." (x999)", "L'arme sera distribuer dans votre coffre", {RightLabel = v.price..'$'}, true, {
                        onSelected = function() 
                            local quantity = tonumber(null.fct.input("Combien en voulez-vous ? (stock: 999)"))
                            if quantity == nil then return end
                            if null.data.illegals.groups.list[ESX.PlayerData.job2.name].KitArme then
                                TriggerServerEvent('Gangsbuilder:BuyWeapon', v.name, v.label, quantity)
                            end
                        end
                    })
                end
                for k,v in pairs(Config.IllegalGroups.Sell.Items) do 
                    RageUI.Button("Objet: "..v.label.." (x999)", nil, {RightLabel = v.price..'$'}, true, {
                        onSelected = function() 
                            local quantity = tonumber(null.fct.input("Combien en voulez-vous ? (stock: 999)"))
                            if quantity == nil then return end
                            if null.data.illegals.groups.list[ESX.PlayerData.job2.name].KitArme then
                                TriggerServerEvent('Gangsbuilder:BuyItem', v.name, v.label, quantity)
                            end
                        end
                    })
                end
            end
        end)

        RageUI.IsVisible(OpenFabWeaponMenu, function()
            if null.data.illegals.groups.list[ESX.PlayerData.job2.name].FabArme then
                RageUI.Separator("Armes")
                for k,v in pairs(Config.IllegalGroups.Craft.Weapons) do 
                    if v.fabacier == 0 and v.fabplanche ~= 0 and v.fablevier ~= 0 then
                        RageUI.Button(v.label, 'Ingrédient : \n \n - '..v.fabplanche..' → Planches~s~ \n - '..v.fablevier..' → Levier', {}, true, {
                            onSelected = function() 
                                if null.data.illegals.groups.list[ESX.PlayerData.job2.name].FabArme then
                                    TriggerServerEvent('Gangsbuilder:FabWeapon', v.name, v.label)
                                end
                            end,
                        })
                    elseif v.fabplanche == 0 and v.fabacier ~= 0 and v.fablevier ~= 0 then
                        RageUI.Button(v.label, 'Ingrédient : \n \n - '..v.fabacier..' → Acier~s~ \n - '..v.fablevier..' → Levier', {}, true, {
                            onSelected = function() 
                                if null.data.illegals.groups.list[ESX.PlayerData.job2.name].FabArme then
                                    TriggerServerEvent('Gangsbuilder:FabWeapon', v.name, v.label)
                                end
                            end,
                        })
                    elseif v.fablevier == 0 and v.fabplanche ~= 0 and v.fabacier ~= 0 then
                        RageUI.Button(v.label, 'Ingrédient : \n \n - '..v.fabacier..' → Acier~s~ \n - '..v.fabplanche..' → Planches~s~', {}, true, {
                            onSelected = function() 
                                if null.data.illegals.groups.list[ESX.PlayerData.job2.name].FabArme then
                                    TriggerServerEvent('Gangsbuilder:FabWeapon', v.name, v.label)
                                end
                            end,
                        })
                    else
                        RageUI.Button(v.label, 'Ingrédient : \n \n - '..v.fabacier..' → Acier~s~ \n - '..v.fabplanche..' → Planches~s~ \n - '..v.fablevier..' → Levier', {}, true, {
                            onSelected = function() 
                                if null.data.illegals.groups.list[ESX.PlayerData.job2.name].FabArme then
                                    TriggerServerEvent('Gangsbuilder:FabWeapon', v.name, v.label)
                                end
                            end,
                        })
                    end
                end
            end
        end)


        RageUI.IsVisible(GestionGrade, function()
            for k,v in pairs(PermsList) do
                RageUI.Button(v.label, nil, {}, true, {
                    onSelected = function() 
                        PermSelected = v.name
                    end
                }, GestionGradePerm)
            end

            if null.data.illegals.groups.list[ESX.PlayerData.job2.name].KitArme == 1 or null.data.illegals.groups.list[ESX.PlayerData.job2.name].KitArme == true then 
                RageUI.Button("Grade ayant accés a la vente d'arme", nil, {}, true, {
                    onSelected = function() 
                        PermSelected = "perms_vente"
                    end
                }, GestionGradePerm)
            end

            if null.data.illegals.groups.list[ESX.PlayerData.job2.name].FabArme == 1 or null.data.illegals.groups.list[ESX.PlayerData.job2.name].FabArme == true then 
                RageUI.Button("Grade ayant accés a la fabrication d'arme", nil, {}, true, {
                    onSelected = function() 
                        PermSelected = "perms_fabrication"
                    end
                }, GestionGradePerm)
            end
        end)

        RageUI.IsVisible(GestionGradePerm, function()
            for k,v in pairs(null.data.illegals.groups.list[ESX.PlayerData.job2.name].GradeList) do
                if v.name == "boss" then
                    RageUI.Button(v.label, nil, {}, false, {
                        onSelected = function() 
                            
                        end
                    })
                else
                    if null.data.illegals.groups.list[ESX.PlayerData.job2.name][PermSelected][k] ~= nil then
                        RageUI.Checkbox(v.label, nil, null.data.illegals.groups.list[ESX.PlayerData.job2.name][PermSelected][k], {}, {
                            onSelected = function(Index)
                                null.data.illegals.groups.list[ESX.PlayerData.job2.name][PermSelected][k] = Index
                            end
                        })
                    else
                        null.data.illegals.groups.list[ESX.PlayerData.job2.name][PermSelected][k] = false
                    end
                end
            end
            RageUI.Button("Confirmer les modifications", nil, { Color = { BackgroundColor = {255,244,79, 200} } }, true, {
                onSelected = function() 
                    TriggerServerEvent("null:changeperms", PermSelected, null.data.illegals.groups.list[ESX.PlayerData.job2.name][PermSelected], ESX.PlayerData.job2.name)
                    RageUI.GoBack()
                end
            })
        end)

        RageUI.IsVisible(GestionRecrutement, function()
            if null.data.illegals.groups.list[ESX.PlayerData.job2.name].perms_recruter[tostring(ESX.PlayerData.job2.grade)] then
                RageUI.Button("Recruté le plus proche", nil, {RightLabel = ""}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_recruterplayer2", GetPlayerServerId(closestPlayer), ESX.PlayerData.job2.name)
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })
                RageUI.Button("Virer le plus proche", nil, {RightLabel = ""}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_virerplayer2", GetPlayerServerId(closestPlayer))
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })
            end
            if null.data.illegals.groups.list[ESX.PlayerData.job2.name].perms_promouvoir[tostring(ESX.PlayerData.job2.grade)] then
                RageUI.Button("Promouvoir le plus proche", nil, {RightLabel = ""}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_promouvoirplayer2", GetPlayerServerId(closestPlayer))
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })
                RageUI.Button("Rétrograder le plus proche", nil, {RightLabel = ""}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            TriggerServerEvent("Null:personalmenu:Boss_destituerplayer2", GetPlayerServerId(closestPlayer))
                        else
                            ESX.ShowNotification('Aucun joueur à proximité',"error")
                        end
                    end
                })
            end
        end)

        RageUI.IsVisible(MembreList, function()
            for k,v in pairs(null.data.illegals.groups.list[ESX.PlayerData.job2.name].PlyList) do 
                if null.data.illegals.groups.list[ESX.PlayerData.job2.name].GradeList[tostring(v.job2_grade)] ~= nil then
                    RageUI.Button(v.firstname..' '..v.lastname.." ("..v.idunique..")", nil, {RightLabel = null.data.illegals.groups.list[ESX.PlayerData.job2.name].GradeList[tostring(v.job2_grade)].label}, ESX.PlayerData.idunique ~= v.idunique and true or false, {
                        onSelected = function() 
                            SelectIdUnique = v
                        end
                    }, GestionMembre)
                end
            end
        end)
        RageUI.IsVisible(GestionMembre, function()
            RageUI.Button("Exclure", nil, {}, true, {
                onSelected = function()
                    TriggerServerEvent("null:changerank", null.data.illegals.groups.list[ESX.PlayerData.job2.name], SelectIdUnique.idunique, "unemployed", 0, true)
                    null.data.illegals.groups.list[ESX.PlayerData.job2.name].PlyList[SelectIdUnique.idunique] = nil
                    ESX.ShowNotification("Vous avez exclu "..SelectIdUnique.firstname.." "..SelectIdUnique.lastname)
                    RageUI.GoBack()
                end
            })
            RageUI.Button("Changer le grade", nil, {}, true, {
                onSelected = function()
                    
                end
            }, GestionMembreGrade)
        end)

        RageUI.IsVisible(GestionMembreGrade, function()
            for k,v in pairs(null.data.illegals.groups.list[ESX.PlayerData.job2.name].GradeList) do 
                RageUI.Button(v.label, nil, {RightLabel = v.grade}, v.name ~= "boss" and true or false, {
                    onSelected = function() 
                        if v.name == "boss" then
                            ESX.ShowNotification("Vous ne pouvez pas faire ça !")
                        else
                            null.data.illegals.groups.list[ESX.PlayerData.job2.name].PlyList[SelectIdUnique.idunique].job2_grade = v.grade
                            TriggerServerEvent("null:changerank", null.data.illegals.groups.list[ESX.PlayerData.job2.name],  SelectIdUnique.idunique ,ESX.PlayerData.job2.name, v.grade, false)
                            ESX.ShowNotification("Vous avez changer le grade de "..SelectIdUnique.firstname.." "..SelectIdUnique.lastname)
                            RageUI.GoBack()
                        end
                    end
                })
            end
        end)

        if not RageUI.Visible(menu) and not RageUI.Visible(OpenBuyWeaponMenu) and not RageUI.Visible(GestionGrade1) and not RageUI.Visible(GestionGradePermCoffre) and not RageUI.Visible(GestionGradePermFabriationArme) and not RageUI.Visible(GestionGradePermVenteArme) and not RageUI.Visible(GestionGradePerm) and not RageUI.Visible(GestionGradePermRecruter) and not RageUI.Visible(GestionGradePermPromouvoir) and not RageUI.Visible(OpenFabWeaponMenu) and not RageUI.Visible(MembreList) and not RageUI.Visible(GestionRecrutement) and not RageUI.Visible(GestionMembre) and not RageUI.Visible(GestionMembreGrade) and not RageUI.Visible(GestionGrade) then
            FreezeEntityPosition(PlayerPedId(), false)
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

function OpenGetItemsGang()
    local loaded = false
    local data = nil
    ESX.TriggerServerCallback('GangsBuilder:getStockItems', function(items)
        data = items
        loaded = true
    end)
    while not loaded do 
        Wait(1)
    end
    local inventaireplayer = RageUI.CreateMenu("", "Inventaire")
    RageUI.Visible(inventaireplayer, not RageUI.Visible(inventaireplayer))
	while inventaireplayer do
		Citizen.Wait(0)
        RageUI.IsVisible(inventaireplayer, function()
            if data == "rien" then
                RageUI.Separator("Vous n'avez rien dans votre coffre (n'existe pas)")
            else
                for k,v in pairs(data) do
                    if v.count ~= 0 then
                        RageUI.Button(v.label, nil, {RightLabel = ESX.Config("serverColor")..'Quantités : '..v.count}, true, {
                            onSelected = function()
                                quantity = null.fct.input('Combien voulez vous déposer ?')
                                TriggerServerEvent('GangsBuilder:getStockItem', v.name, tonumber(quantity))
                                RageUI.CloseAll()
                                Wait(150)
                                OpenGetItemsGang()
                            end
                        })
                    end
                end
            end
        end)
        if not RageUI.Visible(inventaireplayer) then
        
            inventaireplayer = RMenu:DeleteType('inventaireplayer', true)
        end
    end
end

function OpenPutItemsGang()
    local loaded = false
    local data
    local name
    local money
    local blackmoney
   
    ESX.TriggerServerCallback('null:GetPlayerData', function(result)
        data = result
        name = result.name
        money = result.money
        blackmoney = result.blackmoney
        loaded = true
    end, GetPlayerServerId(PlayerId()))

    while not loaded do 
        Wait(1)
    end
    local inventaireplayer = RageUI.CreateMenu("", "Inventaire")
    RageUI.Visible(inventaireplayer, not RageUI.Visible(inventaireplayer))
	while inventaireplayer do
		Citizen.Wait(0)
        RageUI.IsVisible(inventaireplayer, function()
            for k,v in pairs(data.inventory) do
                RageUI.Button(v.label, nil, {RightLabel = ESX.Config("serverColor")..'Quantités : '..v.count}, true, {
                    onSelected = function()
                        quantity = null.fct.input('Combien voulez vous déposer ?')
                        TriggerServerEvent('GangsBuilder:putStockItems', v.name, tonumber(quantity))
                        RageUI.CloseAll()
                        Wait(150)
                        OpenPutItemsGang()
                    end
                })
            end
        end)
        if not RageUI.Visible(inventaireplayer) then
            inventaireplayer = RMenu:DeleteType('inventaireplayer', true)
        end
    end
end

local WeaponBlacklist = {
    ['WEAPON_GLOCK20'] = true,
    ['WEAPON_KATANA'] = true,
    ['WEAPON_SCAR17FM'] = true, 
    ['WEAPON_BLACKSNIPER'] = true,
}

function openDepositWeaponGang()
    local loaded = false
    local data
    local name
    local money
    local blackmoney
   
    ESX.TriggerServerCallback('null:GetPlayerData', function(result)
        data = result
        name = result.name
        money = result.money
        blackmoney = result.blackmoney
        loaded = true
    end, GetPlayerServerId(PlayerId()))
    while not loaded do 
        Wait(1)
    end
    local inventaireplayer = RageUI.CreateMenu("", "Inventaire")
    RageUI.Visible(inventaireplayer, not RageUI.Visible(inventaireplayer))
	while inventaireplayer do
		Citizen.Wait(0)
        RageUI.IsVisible(inventaireplayer, function()
            for k,v in pairs(data.weapons) do
                RageUI.Button(v.label, nil, {}, true, {
                    onSelected = function()
                        if WeaponBlacklist[v.name] == nil then
                            ESX.TriggerServerCallback('GangsBuilder:addArmoryWeapon', function()
                                openDepositWeaponGang()
                            end, v.name, 250)
                        else
                            ESX.ShowNotification(ESX.Config("serverColor")..''..ESX.Config("serverName")..'~s~Vous ne pouvez pas déposer les armes boutique dans les coffres')
                        end
                    end
                })
            end
        end)
        if not RageUI.Visible(inventaireplayer) then
            inventaireplayer = RMenu:DeleteType('inventaireplayer', true)
        end
    end
end

function openPutWeaponGang()
    local loaded = false
    local data = nil
    ESX.TriggerServerCallback('GangsBuilder:getArmoryWeapons', function(weapons)
        data = weapons
        loaded = true
    end)
    while not loaded do 
        Wait(1)
    end
    local inventaireplayer = RageUI.CreateMenu("", "Inventaire")
    RageUI.Visible(inventaireplayer, not RageUI.Visible(inventaireplayer))
	while inventaireplayer do
		Citizen.Wait(0)
        RageUI.IsVisible(inventaireplayer, function()
            for k,v in pairs(data) do
                RageUI.Button(ESX.GetWeaponLabel(v.name), nil, {RightLabel = v.ammo}, true, {
                    onSelected = function()
                        ESX.TriggerServerCallback('GangsBuilder:removeArmoryWeapon', function()
                            openPutWeaponGang()
                        end, v.name, v.ammo)
                    end
                })
            end
        end)
        if not RageUI.Visible(inventaireplayer) then
            inventaireplayer = RMenu:DeleteType('inventaireplayer', true)
        end
    end
end

RegisterCommand("f7", function()
    if not PlayerIsDead then
        --OpenIllegalTablet()
        OpenIllegalDevice()
    end
end, false)
RegisterKeyMapping('f7', 'Menu Gang', 'keyboard', 'F7')

local GANG_DATA_TERRITORIES = {}
function OpenGangMenuF7()
    local inventaireplayer = RageUI.CreateMenu("", ESX.Config("serverColor").."Faction")
    local pointlist = RageUI.CreateSubMenu(inventaireplayer,"", "Actions Disponibles")
    local openTerritoriesInformations = RageUI.CreateSubMenu(inventaireplayer,"", "Actions Disponibles")
    RageUI.Visible(inventaireplayer, not RageUI.Visible(inventaireplayer))
    TriggerServerEvent("null:initGangs")
	while inventaireplayer do
		Citizen.Wait(0)
        RageUI.IsVisible(inventaireplayer, function()
            RageUI.Button('Tablette Illégal', nil, { Color = { BackgroundColor = {100,60,180, 200} } }, true, {
                onSelected = function()
                    RageUI.CloseAll()
                    OpenIllegalTablet()
                end
            })
            -- RageUI.Button('Informations territoires', nil, {}, true, {
            --     onSelected = function() 
            --         ESX.TriggerServerCallback("territories:getTerritoriesData", function(data)
            --             if GANG_DATA_TERRITORIES ~= data then
            --                 Wait(1000)
            --                 GANG_DATA_TERRITORIES = data
            --             end
            --         end)
            --     end
            -- }, openTerritoriesInformations)

            RageUI.Button('Fouiller', nil, {}, true, {
                onSelected = function()
                    local player, distance = ESX.Game.GetClosestPlayer()
                    if distance ~= -1 and distance <= 3.0 then
                        local targetPed = GetPlayerPed(player)
                        if ESX.isHandsUp(targetPed) then  
                            RageUI.CloseAll()
                            ESX.TriggerServerCallback('null:fouiller', function(data, id)
                                if data then
                                    local inventory = data
                                    inventory.weight = 0
                                    inventory.id = GetPlayerServerId(player)
                                    inventory.maxWeight = 1000
                                    inventory.type = "PLAYER"
                                    TriggerEvent("inventory:openSearch", inventory, false, data.cash or 0,data.dirtycash or 0)
                                end
                            end, GetPlayerServerId(player))
                        else
                            ESX.ShowNotification('🙌 Le joueur cible ne leve pas les mains')
                        end
                    else
                        ESX.ShowNotification('\nAucun Joueurs au alentours')
                    end
                end
            });
            if ESX.PlayerData.job2.grade_name == "boss" then
                RageUI.Button('Facture', nil, {}, true, {
                    onSelected = function() 
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    
                        if closestPlayer == -1 or closestDistance > 3.0 then
                            ESX.ShowNotification('Il n\'y a aucun joueurs au alentours')
                        else
                            local string = null.fct.input('Montant', false, 9000000, "number")
                            if string ~= "" then
                                Montant = tonumber(string)
                            end
                            TriggerServerEvent("Core:AddBilling", GetPlayerServerId(closestPlayer), tonumber(Montant), ESX.PlayerData.job2.name)
                        end
                    end
                })
            end
            RageUI.Button('Mettre dans le véhicule', nil, {}, true, {
                onSelected = function()
                    local player, distance = ESX.Game.GetClosestPlayer()
                    if distance ~= -1 and distance <= 3.0 then
                        local targetPed = GetPlayerPed(player)
                        if ESX.isHandsUp(targetPed) then  
                            TriggerServerEvent('GangsBuilder:putInVehicle', GetPlayerServerId(player))
                        else
                            ESX.ShowNotification('🙌 Le joueur cible ne leve pas les mains')
                        end
                    else
                        ESX.ShowNotification('\nAucun Joueurs au alentours')
                    end
                end
            });
            RageUI.Button('Sortir du véhicule', nil, {}, true, {
                onSelected = function()
                    local player, distance = ESX.Game.GetClosestPlayer()
                    if distance ~= -1 and distance <= 3.0 then
                        TriggerServerEvent('GangsBuilder:OutVehicle', GetPlayerServerId(player))
                    else
                        ESX.ShowNotification('\nAucun Joueurs au alentours')
                    end
                end
            });
            RageUI.Button("Ouvrir / fermer de force", nil, {}, true , {
                onSelected = function()
                    local playerPed = PlayerPedId()
                    local vehicle = ESX.Game.GetVehicleInDirection()
                    local coords = GetEntityCoords(playerPed)
        
                    if IsPedSittingInAnyVehicle(playerPed) then
                        ESX.ShowNotification('Action impossible')
                        return
                    end
        
                    if DoesEntityExist(vehicle) then
                        isBusy = true
                        TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)
                        Citizen.CreateThread(function()
                            Citizen.Wait(10000)
        
                            SetVehicleDoorsLocked(vehicle, 1)
                            SetVehicleDoorsLockedForAllPlayers(vehicle, false)
                            ClearPedTasksImmediately(playerPed)
        
                            ESX.ShowNotification('Véhicule dévérouiller')
                            isBusy = false
                        end)
                    else
                        ESX.ShowNotification('Pas de véhicules à proximité')
                    end
                end
            });
            --[[RageUI.Button('Classement Point', nil, {}, true, {
                onSelected = function() 
                    TriggerServerEvent("null:initGangs")
                    print(#null.data.illegals.groups.list)
                    for i = 1, #null.data.illegals.groups.list do
                        table.sort(null.data.illegals.groups.list[i])
                    end
                end
            }, pointlist)]]
        end)
        RageUI.IsVisible(pointlist, function()
            if null.data.illegals.groups.list[ESX.PlayerData.job2.name].Point ~= nil then
                RageUI.Separator("Votre nombre de point : "..ESX.Config("serverColor")..null.data.illegals.groups.list[ESX.PlayerData.job2.name].Point)
            else
                RageUI.Separator("Votre nombre de point : 0")
            end
            for k,v in pairs(null.data.illegals.groups.list) do
                if v.Point ~= 0 then
                    RageUI.Button(v.name, nil, {RightLabel = v.Point.." Points"}, true, {
                        onSelected = function() 
                            
                        end,
                        onActive = function()
                            RageUI.Info('~s~Gang : '..v.name, {'~s~Nombre de points : '}, {ESX.Config("serverColor")..v.Point})
                        end
                    });
                end
            end
        end)
        RageUI.IsVisible(openTerritoriesInformations, function()
            for k,v in pairs(GANG_DATA_TERRITORIES) do
                if not v.active then goto continue end
            
                RageUI.Button(v.name,
                    ("Nom de la zone : %s\nControlé par : %s\nNombre de point : %s\n\nVotre nombre de point : %s\nPoint manquant pour controler la zone : %s"):format(
                        v.name,
                        v.ownerLabel == nil and "Aucun" or v.ownerLabel,
                        v.ownerCount,
                        GANG_DATA_TERRITORIES[k].data[ESX.PlayerData.job2.name] == nil and 0 or GANG_DATA_TERRITORIES[k].data[ESX.PlayerData.job2.name].count,
                        v.owner == ESX.PlayerData.job2.name and "Vous controlez la zone" or v.ownerCount - (GANG_DATA_TERRITORIES[k].data[ESX.PlayerData.job2.name] == nil and 0 or GANG_DATA_TERRITORIES[k].data[ESX.PlayerData.job2.name].count)
                    ), { RightLabel = v.owner == ESX.PlayerData.job2.name and '✅' or ("❌ %s"):format(
                        v.owner == v.ownerCount - (GANG_DATA_TERRITORIES[k].data[ESX.PlayerData.job2.name] == nil and 0 or GANG_DATA_TERRITORIES[k].data[ESX.PlayerData.job2.name].count)
                    ) }, true, {}
                )

                ::continue::
            end
        end)
        if not RageUI.Visible(inventaireplayer) and not RageUI.Visible(pointlist) and not RageUI.Visible(openTerritoriesInformations) then
            inventaireplayer = RMenu:DeleteType('inventaireplayer', true)
        end
    end
end

RegisterNetEvent('GangsBuilder:putInVehicle', function()
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed, false)

	if IsAnyVehicleNearPoint(coords, 5.0) then
		local vehicle = GetClosestVehicle(coords, 5.0, 0, 71)

		if DoesEntityExist(vehicle) then
			local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
			local freeSeat = nil

			for i = maxSeats - 1, 0, -1 do
				if IsVehicleSeatFree(vehicle,  i) then
					freeSeat = i
					break
				end
			end

			if freeSeat ~= nil then
				TaskWarpPedIntoVehicle(playerPed, vehicle, freeSeat)
			end
		end
	end
end)

RegisterNetEvent('GangsBuilder:OutVehicle', function()
	local ped = PlayerPedId()

	if not IsPedSittingInAnyVehicle(playerPed) then
		return
	end

	local vehicle = GetVehiclePedIsIn(playerPed, false)
	TaskLeaveVehicle(playerPed, vehicle, 16)
end)

function OpenBodySearchMenu(player)
    local loaded = false
    local data
    local name
    local money
    local blackmoney
   
    ESX.TriggerServerCallback('null:GetPlayerData', function(result)
        data = result
        name = result.name
        money = result.money
        blackmoney = result.blackmoney
        loaded = true
    end, player)
    while not loaded do 
        Wait(1)
    end

    local InventoryMenu = RageUI.CreateMenu("", 'Menu Fouille')
    RageUI.Visible(InventoryMenu, not RageUI.Visible(promote))

	while InventoryMenu do
		Citizen.Wait(0)
        RageUI.IsVisible(InventoryMenu, function()
            RageUI.Separator('↓ Argents ↓')
            RageUI.Separator('Liquides : '.. money)
            RageUI.Separator('Argents Sale : '.. blackmoney)
            RageUI.Separator('↓ Objets ↓')
            for k,v in pairs(data.inventory) do
                RageUI.Button(v.label, nil, {RightLabel = ESX.Config("serverColor")..'Quantités : '..v.count}, true, {
                    onSelected = function()

                    end
                })
            end
            RageUI.Separator('↓ Armes ↓')
            for k,v in pairs(data.weapons) do
                RageUI.Button(v.label, nil, {RightLabel = ESX.Config("serverColor")..'Munitions : '..v.ammo}, true, {
                    onSelected = function()

                    end
                })
            end
        end)
        if not RageUI.Visible(InventoryMenu) then
            InventoryMenu = RMenu:DeleteType('InventoryMenu', true)
        end
    end
end


local gangpos = false
local BlipsGang = {}
RegisterCommand('gangpos', function()
    if Config.GroupeHighPerm[ESX.PlayerData.group] ~= nil then
        gangpos = not gangpos
        if gangpos then
            for k,v in pairs(null.data.illegals.groups.list) do
                BlipsGang[v.name] = AddBlipForCoord(v.posCoffre.x, v.posCoffre.y, v.posCoffre.z)
                SetBlipSprite(BlipsGang[v.name], 429)
                SetBlipDisplay(BlipsGang[v.name], 4)
                SetBlipScale(BlipsGang[v.name], 0.8)
                SetBlipColour(BlipsGang[v.name], 0)
                SetBlipAsShortRange(BlipsGang[v.name], true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(v.name)
                EndTextCommandSetBlipName(BlipsGang[v.name])
            end
        else
            for k,v in pairs(BlipsGang) do 
                RemoveBlip(v)
            end
        end
    end
end)

RegisterNetEvent('Open:GangMenuAdmin', function()
    while not null.data.illegals.groups.loaded do 
        Wait(1)
    end
    if Config.GroupeHighPerm[ESX.GetPlayerData()['group']] ~= nil then 
        local SelectedGang = {}
        local NewCoffrePosition = nil
        local PositionChanged = false
        local KitArmeGang = false
        local NbrPointGang = 0
        local NbrPointGangSave = 0
        local KitArmeFabGang = false
        local PositionChangedCoffre = false
        local FinishKitArmeValue = false
        local FinishKitArmeFabValue = false
        local NewFabPosition = nil
        local PositionChangedFab = false
        local posFabCreation = nil
        local GangMenu = RageUI.CreateMenu('Gang', 'Actions Disponible')
        local GangsBuilderMenu = RageUI.CreateSubMenu(GangMenu, 'Gang', 'Actions Disponible')
        local OpenListGangs = RageUI.CreateSubMenu(GangMenu, 'Gang', 'Actions Disponible')
        local OpenSelectedGang = RageUI.CreateSubMenu(OpenListGangs, 'Gang', 'Actions Disponible')
        local OpenDeleteListGang = RageUI.CreateSubMenu(GangMenu, 'Gang', 'Actions Disponible')
        local DeleteGang = RageUI.CreateSubMenu(OpenDeleteListGang, 'Gang', 'Actions Disponible')
        local OpenInfoGang = RageUI.CreateSubMenu(GangMenu, 'Gang', 'Actions Disponible')
        local OpenInfoGang2 = RageUI.CreateSubMenu(OpenInfoGang, 'Gang', 'Actions Disponible')
        
        RageUI.Visible(GangMenu, not RageUI.Visible(GangMenu))

        while GangMenu do
            Citizen.Wait(0)
            RageUI.IsVisible(GangMenu, function()
                RageUI.Button('Crée un nouveau Gang', nil, {}, true, {
                    onSelected = function()

                end},GangsBuilderMenu)
                RageUI.Button('Modifier un Gang', nil, {}, true, {
                    onSelected = function()

                end}, OpenListGangs)
                RageUI.Button('Informations Gang', nil, {}, true, {
                    onSelected = function()

                end}, OpenInfoGang)
            end)

            RageUI.IsVisible(GangsBuilderMenu, function()
                RageUI.Button('Nom du Gang (setjob2)', "Aucune majuscule ni espace !", {RightLabel = namegang}, true, {
                    onSelected = function()
                        namegang = null.fct.input('Quelle nom veux tu mettre ?')
                end})
                RageUI.Button('Label du Gang', nil, {RightLabel = labelgang}, true, {
                    onSelected = function()
                        labelgang = null.fct.input('Quelle nom veux tu mettre ?')
                end})
                RageUI.Button('Position du Coffre', posCoffre or 'Aucune', {}, true, {
                    onSelected = function()
                        posCoffre = GetEntityCoords(PlayerPedId())
                end})
                RageUI.Button('Position Fabrication', posFabCreation or 'Aucune', {}, true, {
                    onSelected = function()
                        posFabCreation = GetEntityCoords(PlayerPedId())
                end})
                RageUI.Checkbox("Kit Arme", nil, KitArme, {}, {
                    onSelected = function(Index)
                        KitArme = Index
                    end
                })
                RageUI.Checkbox("Fabrications Arme", nil, KitArmeFab, {}, {
                    onSelected = function(Index)
                        KitArmeFab = Index
                    end
                })
                RageUI.Button('Confirmer', nil, { Color = { BackgroundColor = {255,244,79, 120} } }, true, {
                    onSelected = function()
                        TriggerServerEvent('null:createGang', namegang, labelgang, posCoffre, KitArme, KitArmeFab, nil, nil, nil, nil, posFabCreation)
                        RageUI.GoBack()
                        KitArme = false
                        KitArmeFab = false
                        Point = 0
                        namegang = 'Aucun'
                        labelgang = 'Aucun'
                        posCoffre = 'Aucune'
                        posFabCreation = nil
                end})
            end)

            RageUI.IsVisible(OpenListGangs, function()
                for k,v in pairs(null.data.illegals.groups.list) do
                    RageUI.Button(v.name, nil, {}, true, {
                        onSelected = function()
                            SelectedGang = v
                            NewCoffrePosition = "~r~Indéfini~s~"
                            PositionChanged = false
                            NbrPointGang = v.Point
                            NbrPointGangSave = v.Point
                            KitArmeGang = false
                            KitArmeFabGang = false
                            PositionChangedCoffre = false
                            PositionChangedFab = false
                            NewFabPosition = "~r~Indéfini~s~"
                            FinishKitArmeValue = false
                            if SelectedGang.FabArme == 1 then
                                KitArmeFabGang = true
                            else
                                KitArmeFabGang = false
                            end
                            if SelectedGang.KitArme == 1 then
                                KitArmeGang = true
                            else
                                KitArmeGang = false
                            end
                    end}, OpenSelectedGang)
                end
            end)

            RageUI.IsVisible(OpenSelectedGang, function()
                if SelectedGang.name ~= nil then
                    RageUI.Separator('Modification de '..SelectedGang.name)
                    RageUI.Button('TP Position du Coffre', nil, {}, true, {
                        onSelected = function()
                            SetEntityCoords(PlayerPedId(), vector3(math.floor(SelectedGang.posCoffre.x), math.floor(SelectedGang.posCoffre.y), math.floor(SelectedGang.posCoffre.z)))
                        end
                    })
                    RageUI.Button('Changer la Position du Coffre', nil, {RightLabel = NewCoffrePosition}, true, {
                        onSelected = function()
                            NewCoffrePosition = GetEntityCoords(PlayerPedId())
                            PositionChangedCoffre = true
                        end
                    })
                    RageUI.Button('Ouvrir le coffre', nil, {}, true, {
                        onSelected = function()
                            RageUI.CloseAll()
                            ESX.TriggerServerCallback('null:getCoffre', function(data, id)
                                if data then
                                    local inventory = data
                                    inventory.weight = 0
                                    inventory.id = id
                                    inventory.maxWeight = 1000
                                    inventory.type = "SOCIETY"
                                    TriggerEvent("inventory:openTarget",inventory)
                                end
                            end, SelectedGang.name, "SOCIETY", 1000)
                        end
                    })
                    RageUI.Checkbox("Kit Arme", nil, KitArmeGang, {}, {
                        onSelected = function(Index)
                            KitArmeGang = Index
                        end
                    })
                    RageUI.Checkbox("Fabrications Arme", nil, KitArmeFabGang, {}, {
                        onSelected = function(Index)
                            KitArmeFabGang = Index
                        end
                    })
                    if SelectedGang.posFabrication then
                        RageUI.Button('TP Position Fabrication', nil, {}, true, {
                            onSelected = function()
                                SetEntityCoords(PlayerPedId(), vector3(math.floor(SelectedGang.posFabrication.x), math.floor(SelectedGang.posFabrication.y), math.floor(SelectedGang.posFabrication.z)))
                            end
                        })
                    end
                    RageUI.Button('Changer la Position Fabrication', nil, {RightLabel = NewFabPosition}, true, {
                        onSelected = function()
                            NewFabPosition = GetEntityCoords(PlayerPedId())
                            PositionChangedFab = true
                        end
                    })
                    RageUI.Button('Supprimer', nil, {Color = { BackgroundColor = {255, 0, 0, 90} } }, true, {
                        onSelected = function()
                            local result = null.fct.confirm("Êtes-vous sur ?")
                            if result ~= true then return end
                            TriggerServerEvent('null:DeleteGangs', SelectedGang.name)
                            RageUI.GoBack()
                        end
                    })
                    RageUI.Button('Confirmer', nil, { Color = { BackgroundColor = {255,244,79, 120} } }, true, {
                        onSelected = function()
                            if not PositionChangedCoffre then
                                NewCoffrePosition = SelectedGang.posCoffre
                            end
                            local updateData = {name = SelectedGang.name, CoffrePos = NewCoffrePosition, KitArme = KitArmeGang, FabArme = KitArmeFabGang, NBRPoint = NbrPointGang}
                            if PositionChangedFab then
                                updateData.FabPos = NewFabPosition
                            end
                            TriggerServerEvent('null:UpdateGangs', updateData)
                            --TriggerServerEvent("null:UpdateGangsPoint", {name=SelectedGang.name,NBRPoint = NbrPointGang})
                            if NbrPointGangSave == NbrPointGang then
                            else
                                null.data.illegals.groups.list[ESX.PlayerData.job2.name].Point = NbrPointGang
                                TriggerServerEvent("Null:ChangePointGangs", SelectedGang, NbrPointGang)
                            end
                            RageUI.GoBack()
                        end
                    })
                end
            end)
            RageUI.IsVisible(OpenDeleteListGang, function()
                for k,v in pairs(null.data.illegals.groups.list) do
                    RageUI.Button(v.name, nil, {}, true, {
                        onSelected = function()
                            local result = null.fct.confirm("Êtes-vous sur ?")
                            if result ~= true then return end
                            TriggerServerEvent('null:DeleteGangs', v.name)
                    end})
                end
            end)

            RageUI.IsVisible(OpenInfoGang, function()
                for k,v in pairs(null.data.illegals.groups.list) do
                    if v.State then
                        RageUI.Button(v.name, nil, {RightLabel = '~g~En-Ligne~s~ ('..#null.data.illegals.groups.list[v.name].StatePly..')'}, true, {
                            onSelected = function()
                                SelectedGang = v
                            end
                        }, OpenInfoGang2)
                    else
                        RageUI.Button(v.name, nil, {RightLabel = '~r~Hors-Ligne'}, true, {})
                    end
                end
            end)
            
            RageUI.IsVisible(OpenInfoGang2, function()
                if SelectedGang.name ~= nil then
                    RageUI.Separator("Membre en ligne "..SelectedGang.name)
                    for k,v in pairs(null.data.illegals.groups.list[SelectedGang.name].StatePly) do
                        RageUI.Button(v.name.." ("..v.id..")", nil, {}, true, {
                            onSelected = function()
                                
                            end
                        })
                    end
                else
                    RageUI.GoBack()
                end
            end)

            
            if not RageUI.Visible(GangMenu) and 
            not RageUI.Visible(GangsBuilderMenu) and 
            not RageUI.Visible(OpenListGangs) and 
            not RageUI.Visible(OpenInfoGang) and 
            not RageUI.Visible(OpenInfoGang2) and 
            not RageUI.Visible(OpenSelectedGang) and 
            not RageUI.Visible(OpenDeleteListGang) and
            not RageUI.Visible(DeleteGang) then
                GangMenu = RMenu:DeleteType('GangMenu', true)
                SelectedGang = {}
            end
        end
    end
end)
