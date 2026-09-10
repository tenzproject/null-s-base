RegisterNetEvent('Null:openFarmBuilder', function()
    openFarmBuilders()
end)

local postion = {
    "~b~Récolte~s~",
    "~b~Traitement~s~",
    "~b~Vente~s~"
}
local PosIndex = 1
local illegalmenu = false

local PosRecolte = ""
local ItemRecolte = ""
local ItemRecolteLabel = ""

local PosTraitement = ""
local ItemTraitement = ""
local ItemTraitementLabel = ""

local PosVente = ""
local PrixVente = ""

local illegal = 0

function openFarmBuilders()
    local ActivityName = ""
    local main = RageUI.CreateMenu("", "Actions Disponibles")
    local submenuCreate = RageUI.CreateSubMenu(main,"", "Actions Disponibles")
    local OpenDeleteListFarming = RageUI.CreateSubMenu(main,"", "Actions Disponibles")
    local OpenListFarming = RageUI.CreateSubMenu(main,"", "Actions Disponibles")
    local OpenListFarming2 = RageUI.CreateSubMenu(OpenListFarming,"", "Actions Disponibles")

    RageUI.Visible(main, not RageUI.Visible(main))

    while main do
        Citizen.Wait(0)
        RageUI.IsVisible(main, function()
            RageUI.Button('Créer un farming', nil, {RightLabel = ""}, true, {
                onSelected = function() 
					
                end
            }, submenuCreate);
            RageUI.Button('Gestion des farmings', nil, {RightLabel = ""}, true, {
                onSelected = function() 
                    
                end
            }, OpenListFarming);
            RageUI.Button('Supprimer un farming', nil, {RightLabel = ""}, true, {
                onSelected = function() 
                    
                end
            }, OpenDeleteListFarming);
        end)
        RageUI.IsVisible(submenuCreate, function()
            RageUI.Button('Nom de l\'activité', nil, {RightLabel = ActivityName or "~r~Indéfini~s~"}, true, {
                onSelected = function() 
                    local input = null.fct.input("Nom de l'activité")
                    if input and input ~= "" then
                        ActivityName = input 
                    end
                end
            })
            RageUI.Button('Nom de l\'item récolte', nil, {RightLabel = ItemRecolte or "~r~Indéfini~s~"}, true, {
                onSelected = function()
                    local input = null.fct.input("Nom de l'item récolte")
                    if input and input ~= "" then
                        ItemRecolte = input 
                    end
                end
            })
            RageUI.Button('Label de l\'item récolte', nil, {RightLabel = ItemRecolteLabel or "~r~Indéfini~s~"}, true, {
                onSelected = function()
                    local input = null.fct.input("Label de l'item récolte")
                    if input and input ~= "" then
                        ItemRecolteLabel = input 
                    end
                end
            })
            RageUI.Button('Nom de l\'item traitement', nil, {RightLabel = ItemTraitement or "~r~Indéfini~s~"}, true, {
                onSelected = function()
                    local input = null.fct.input("Nom de l'item traitement")
                    if input and input ~= "" then
                        ItemTraitement = input 
                    end
                end
            })
            RageUI.Button('Label de l\'item traitement', nil, {RightLabel = ItemTraitementLabel or "~r~Indéfini~s~"}, true, {
                onSelected = function()
                    local input = null.fct.input("Label de l'item traitement")
                    if input and input ~= "" then
                        ItemTraitementLabel = input 
                    end
                end
            })
            RageUI.Button('Prix de Vente', nil, {RightLabel = PrixVente or "~r~Indéfini~s~"}, true, {
                onSelected = function()
                    local input = null.fct.input("Prix de la vente")
                    if input and input ~= "" then
                        PrixVente = tonumber(input) -- Assure que le prix est bien un nombre
                    end
                end
            })            
            RageUI.List("Position :", postion, PosIndex , nil, {}, true, {
                onListChange = function(Index)
                    PosIndex = Index
                end,
                onSelected = function(Index)
                    if Index == 1 then
                        PosRecolte = GetEntityCoords(PlayerPedId(), true)  
                        ESX.ShowNotification("Nouvelle position Récolte: ~b~"..PosRecolte)
                    elseif Index == 2 then
                        PosTraitement = GetEntityCoords(PlayerPedId(), true)
                        ESX.ShowNotification("Nouvelle position Traitement : ~b~"..PosTraitement)
                    elseif Index == 3 then
                        PosVente = GetEntityCoords(PlayerPedId(), true)
                        ESX.ShowNotification("Nouvelle position Vente : ~b~"..PosVente)
                    end
                end
            });
            RageUI.Checkbox('Illégal', description, show1, {}, {
                onChecked = function()
                    illegal = 1
                end,
                onUnChecked = function()
                    illegal = 0
                end,
                onSelected = function(Index)
                    show1 = Index
                end
            })
            RageUI.Button('~g~Confirmer', nil, {}, true, {
                onSelected = function()
                    --TriggerServerEvent('framework:createactivitylegal', ActivityName, PosRecolte, ItemRecolte, ItemRecolteLabel, PosTraitement, ItemTraitement, ItemTraitementLabel, PosVente, tonumber(PrixVente), illegal)
                    TriggerServerEvent('framework:createactivitylegal', ActivityName, PosRecolte, ItemRecolte, ItemRecolteLabel, PosTraitement, ItemTraitement, ItemTraitementLabel, PosVente, tonumber(PrixVente), illegal)
                    RageUI.CloseAll()
                    ActivityName = ""
                    PosRecolte = ""
                    ItemRecolte = ""
                    ItemRecolteLabel = ""
                    PosTraitement = ""
                    ItemTraitement = ""
                    ItemTraitementLabel = ""
                    PosVente = ""
                    PrixVente = ""
                    illegal = 0
                end
            });
            --RageUI.Separator("↓ ~r~Evenements Légal ~s~ ↓")
        end)
        RageUI.IsVisible(OpenDeleteListFarming, function()
            for k, v in pairs(ListActivity) do
                RageUI.Button(v.name, nil, {RightLabel = '#' .. v.id}, true, {
                    onSelected = function()
                        local confirm = null.fct.confirm("Êtes-vous sûr de vouloir supprimer cette activité ?")
                        if confirm then
                            TriggerServerEvent("framework:deleteactivity", v.id)
                        end
                    end
                })
            end
        end)        
        RageUI.IsVisible(OpenListFarming, function()
            for k,v in pairs(ListActivity) do
                RageUI.Button(v.name, nil, {RightLabel = '#'..v.id}, true, {
                    onSelected = function()
                        SavePosRecolte = v.recolte
                        SavePosTraitement = v.traitement
                        SavePosvente = v.vente
                        saveid = v.id
                        if v.illegal == 0 then
                            illegalmenu = false
                        else
                            illegalmenu = true
                        end
                    end
                }, OpenListFarming2)
            end
        end)
        RageUI.IsVisible(OpenListFarming2, function()
            if not illegalmenu then
                RageUI.Button("Change le blips", "Changer l'id du blips (icons)", {RightLabel = ''}, true, {
                    onSelected = function()
                        if UpdateOnscreenKeyboard() == 0 then return end
                        local string = null.fct.input('Nouveau blips (id)')
                        if string ~= nil then
                            TriggerServerEvent("framework:changeactivityblips", saveid, string)
                        end
                    end
                })
                RageUI.Line()
            end
            RageUI.Button("Postion de la récolte", nil, {RightLabel = 'Se téléporter'}, true, {
                onSelected = function()
                    SetEntityCoords(PlayerPedId(), SavePosRecolte.x, SavePosRecolte.y, SavePosRecolte.z)
                end
            })
            RageUI.Button("Postion du traitement", nil, {RightLabel = 'Se téléporter'}, true, {
                onSelected = function()
                    SetEntityCoords(PlayerPedId(), SavePosTraitement.x, SavePosTraitement.y, SavePosTraitement.z)
                end
            })
            RageUI.Button("Postion de la vente", nil, {RightLabel = 'Se téléporter'}, true, {
                onSelected = function()
                    SetEntityCoords(PlayerPedId(), SavePosvente.x, SavePosvente.y, SavePosvente.z)
                end
            })
        end)
        if not RageUI.Visible(main) and not RageUI.Visible(submenuCreate) and not OpenDeleteListFarming then
            main = RMenu:DeleteType('main', true)
        end
    end
end

ListActivity = {}
--[[
RegisterNetEvent('framework:sendActivity')
AddEventHandler('framework:sendActivity', function(table)
    ListActivity = table
end)--]]

local Acitivity = false
local farming = false
local WaitFarming = false

function createblip(coords, sprit, blipname, text)
    local blip = AddBlipForCoord(coords) 
    SetBlipSprite(blip, sprit)
    SetBlipDisplay(blip, 6)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 36)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING") 
    AddTextComponentString(text)
    EndTextCommandSetBlipName(blip)
end



Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    ESX.TriggerServerCallback('framework:LoadActivity', function(Activity)
        ListActivity = Activity
    end)
    Wait(500)
    Acitivity = true
    while true do
        local Open = false
        for k,v in pairs(ListActivity) do  
            if Vdist2(GetEntityCoords(PlayerPedId(), false), vector3(v.recolte.x, v.recolte.y, v.recolte.z)) < 100 then
                Open = true
                if v.illegal == false then 
                        if not farming then
                            if not WaitFarming then
                                ESX.ShowHelpNotification('Appuyez sur ~g~E ~s~pour commencer la récolte')
                                if IsControlJustPressed(1,51) then
                                    if GetVehiclePedIsIn(PlayerPedId(), false) == 0 then 
                                        farming = true
                                        WaitFarming = true
                                        TriggerServerEvent('framework:startActivityBuild', v.recolte, v.ItemRecolte, 1, '0', v.illegal, token)
                                    else 
                                        ESX.ShowNotification('Vous ne pouvez pas effectuer ceci dans un vehicule')
                                    end
                                end
                            else
                                ESX.ShowHelpNotification('Merci de ne pas allez trop vite')
                            end
                        else
                            ESX.ShowHelpNotification('Appuyez sur ~g~E ~s~pour arrêter l\'activité')
                            if IsControlJustPressed(1,51) then
                                if GetVehiclePedIsIn(PlayerPedId(), false) == 0 then 
                                    farming = false
                                    TriggerServerEvent('framework:stopActivityBuild')
                                    Wait(5000)
                                    WaitFarming = false
                                else 
                                    ESX.ShowNotification('Vous ne pouvez pas effectuer ceci dans un vehicule')
                                end
                            end
                        end
                else
                    if not farming then
                        if not WaitFarming then
                            ESX.ShowHelpNotification('Appuyez sur ~g~E ~s~pour commencer le recolte')
                            if IsControlJustPressed(1,51) then
                                if GetVehiclePedIsIn(PlayerPedId(), false) == 0 then 
                                    farming = true
                                    WaitFarming = true
                                    TriggerServerEvent('framework:startActivityBuild', v.recolte, v.ItemRecolte, 1, '0', v.illegal, token)
                                else 
                                    ESX.ShowNotification('Vous ne pouvez pas effectuer ceci dans un vehicule')
                                end
                            end
                        else
                            ESX.ShowHelpNotification('Merci de ne pas allez trop vite')
                        end
                    else
                        ESX.ShowHelpNotification('Appuyez sur ~g~E ~s~pour arrêter l\'activité')
                        if IsControlJustPressed(1,51) then
                            if GetVehiclePedIsIn(PlayerPedId(), false) == 0 then 
                                farming = false
                                TriggerServerEvent('framework:stopActivityBuild')
                                Wait(5000)
                                WaitFarming = false
                            else 
                                ESX.ShowNotification('Vous ne pouvez pas effectuer ceci dans un vehicule')
                            end
                        end
                    end
                end

            end

            if Vdist2(GetEntityCoords(PlayerPedId(), false), vector3(v.recolte.x, v.recolte.y, v.recolte.z)) > 100 and Vdist2(GetEntityCoords(PlayerPedId(), false), vector3(v.recolte.x, v.recolte.y, v.recolte.z)) < 105 then
                farming = false
                TriggerServerEvent('framework:stopActivityBuild')
                Wait(5000)
                WaitFarming = false
            end

            if Vdist2(GetEntityCoords(PlayerPedId(), false), vector3(v.traitement.x, v.traitement.y, v.traitement.z)) > 100 and Vdist2(GetEntityCoords(PlayerPedId(), false), vector3(v.traitement.x, v.traitement.y, v.traitement.z)) < 105 then
                farming = false
                TriggerServerEvent('framework:stopActivityBuild')
                Wait(5000)
                WaitFarming = false
            end

            if Vdist2(GetEntityCoords(PlayerPedId(), false), vector3(v.vente.x, v.vente.y, v.vente.z)) > 100 and Vdist2(GetEntityCoords(PlayerPedId(), false), vector3(v.vente.x, v.vente.y, v.vente.z)) < 105 then
                farming = false
                TriggerServerEvent('framework:stopActivityBuild')
                Wait(5000)
                WaitFarming = false
            end

            if Vdist2(GetEntityCoords(PlayerPedId(), false), vector3(v.traitement.x, v.traitement.y, v.traitement.z)) < 100 then
                Open = true
                if not farming then
                    if not WaitFarming then
                        ESX.ShowHelpNotification('Appuyez sur ~g~E ~s~pour commencer le traitement')
                        if IsControlJustPressed(1,51) then
                            if GetVehiclePedIsIn(PlayerPedId(), false) == 0 then 
                                farming = true
                                WaitFarming = true
                                TriggerServerEvent('framework:startActivityBuild', v.traitement, v.ItemRecolte, 2, v.ItemTraitement, v.illegal, token)
                            else 
                                ESX.ShowNotification('Vous ne pouvez pas effectuer ceci dans un vehicule')
                            end
                        end
                    else
                        ESX.ShowHelpNotification('Merci de ne pas allez trop vite')
                    end
                else
                    ESX.ShowHelpNotification('Appuyez sur ~g~E ~s~pour arrêter l\'activité')
                    if IsControlJustPressed(1,51) then
                        if GetVehiclePedIsIn(PlayerPedId(), false) == 0 then 
                            farming = false
                            TriggerServerEvent('framework:stopActivityBuild')
                            Wait(5000)
                            WaitFarming = false
                        else 
                            ESX.ShowNotification('Vous ne pouvez pas effectuer ceci dans un vehicule')
                        end
                    end
                end
            end

            if Vdist2(GetEntityCoords(PlayerPedId(), false), vector3(v.vente.x, v.vente.y, v.vente.z)) < 100 then
                Open = true
                if not farming then
                    
                    if not WaitFarming then
                        ESX.ShowHelpNotification('Appuyez sur ~g~E ~s~pour commencer la vente')
                        if IsControlJustPressed(1,51) then
                            if GetVehiclePedIsIn(PlayerPedId(), false) == 0 then 
                                farming = true
                                TriggerServerEvent('framework:startActivityBuild', v.vente, '0', 3, v.ItemTraitement, v.illegal, token)
                            else 
                                ESX.ShowNotification('Vous ne pouvez pas effectuer ceci dans un vehicule')
                            end
                        end
                    else
                        ESX.ShowHelpNotification('Merci de ne pas allez trop vite')
                    end
                else
                    ESX.ShowHelpNotification('Appuyez sur ~g~E ~s~pour arrêter l\'activité')
                    if IsControlJustPressed(1,51) then
                        farming = false
                        TriggerServerEvent('framework:stopActivityBuild')
                        Wait(5000)
                        WaitFarming = false
                    end
                end
            end

        end
                
        if Open then
          Wait(0)
      else
          Wait(750)
      end
    end
end)

ListActivitySave = ListActivity
Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    ListActivitySave = {}
    ESX.TriggerServerCallback('framework:LoadActivity', function(Activity)
        ListActivitySave = Activity
    end)
    Wait(500)
    for k,v in pairs(ListActivitySave) do  
        if v.illegal == false or v.illegal == 0 then
            local blip = AddBlipForCoord(vector3(v.recolte.x, v.recolte.y, v.recolte.z)) 
            SetBlipSprite(blip, v.blipid)
            SetBlipDisplay(blip, 6)
            SetBlipScale(blip, 0.8)
            SetBlipColour(blip, 36)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING") 
            AddTextComponentString(ESX.Config("serverColor").."Activité Farming ~s~ | Récolte "..v.name)
            EndTextCommandSetBlipName(blip)

            local blip = AddBlipForCoord(vector3(v.traitement.x, v.traitement.y, v.traitement.z)) 
            SetBlipSprite(blip, v.blipid)
            SetBlipDisplay(blip, 6)
            SetBlipScale(blip, 0.8)
            SetBlipColour(blip, 36)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING") 
            AddTextComponentString(ESX.Config("serverColor").."Activité Farming ~s~ | Traitement "..v.name)
            EndTextCommandSetBlipName(blip)

            local blip = AddBlipForCoord(vector3(v.vente.x, v.vente.y, v.vente.z)) 
            SetBlipSprite(blip, v.blipid)
            SetBlipDisplay(blip, 6)
            SetBlipScale(blip, 0.8)
            SetBlipColour(blip, 36)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING") 
            AddTextComponentString(ESX.Config("serverColor").."Activité Farming ~s~ | Vente "..v.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)

RegisterNetEvent('framework:farmanimation', function()
	local dict, anim = 'random@domestic', 'pickup_low'
	local playerPed = PlayerPedId()
    ESX.Streaming.RequestAnimDict(dict)
	TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
end)