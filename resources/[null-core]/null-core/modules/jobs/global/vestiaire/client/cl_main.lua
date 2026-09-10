
local index = {
    vestiaire = 1,
}

local VestiaireJobMenu = {}
function GetAllClothJob()
    VestiaireJobMenu = {}
    ESX.TriggerServerCallback('null:jobclothes:getVetements', function(VestiaireJob)
        VestiaireJobMenu = VestiaireJob
    end)  
end

function OpenVestiaire(job)
    local main = RageUI.CreateMenu("", "Actions disponibles")
    local vesitaire = RageUI.CreateSubMenu(main, "", "Actions disponibles")
    local menuGestion = RageUI.CreateSubMenu(main, "", "Actions disponibles")
    local menuAdd = RageUI.CreateSubMenu(menuGestion, "", "Actions disponibles")

    RageUI.Visible(main, not RageUI.Visible(main))
    FreezeEntityPosition(PlayerPedId(), true)
    while true do
        if not main then break end 
        Wait(0)
        RageUI.IsVisible(main, function()
            RageUI.Button("Tenue civil", nil, {}, true, {
                onSelected = function()                    
                    ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
                        TriggerEvent('Null:skinchanger:loadSkin', skin)
                    end)
                end
            })
            RageUI.Button("Vestiaire", nil, {}, true, {
                onSelected = function()               
                    GetAllClothJob()
                
                end
            },vesitaire )
            if ESX.PlayerData.job.grade_name == 'boss' then
                RageUI.Button("Gestion des tenues", nil, {}, true, {
                    onSelected = function()                    
                        GetAllClothJob()  
                    end
                }, menuGestion)
            end
        end)
        RageUI.IsVisible(vesitaire, function()
            
            for k,v in pairs(VestiaireJobMenu) do 
                RageUI.Button(('Tenue %s'):format(v.label), nil, {RightLabel = 'Equiper'}, true, {
                    onSelected = function()
                        apllyTenueVestiaire(v.value)
                        ESX.ShowNotification(('Vous avez équipé la tenue %s'):format(v.label))
                    end
                })
            end
        
        end)
        RageUI.IsVisible(menuGestion, function()
            RageUI.Button("Ajouter une tenue", nil, {}, true, {
                onSelected = function()                    

                end
            }, menuAdd)
            RageUI.Line()
            for k,v in pairs(VestiaireJobMenu) do 
                RageUI.List(('Tenue %s'):format(v.label), {"Modifier le nom","~r~Supprimer~s~"}, index.vestiaire, nil, {}, true, {
                    onListChange = function(Index)
                        index.vestiaire = Index
                    end,

                    onSelected = function(Index)
                        if Index == 1 then
                            local newLabel = null.fct.input(('Entrez un nouveau nom  (Nom actuel : %s)'):format(v.label))
                            if newLabel then 
                                TriggerServerEvent('null:jobclothes:editname', v.id, newLabel)
                                Wait(150)
                                GetAllClothJob()

                            end

                        elseif Index == 2 then
                            local result = null.fct.confirm(('Êtes-vous sûr de vouloir supprimer : %s ?'):format(v.label))
                            if result then
                                TriggerServerEvent('null:jobclothes:deleteJobTenue', v.id)
                                Wait(150)
                                GetAllClothJob()
                            else
                                ESX.ShowNotification("⚠️ Tu n'as pas confirmé la suppression.")
                            end
                        end                        
                    end
                })
            end
        
        end)

        RageUI.IsVisible(menuAdd, function()
            
            RageUI.Button('Ajouter votre tenue actuelle au vestiaire', nil, {}, true, {
                onSelected = function()
                    local name = null.fct.input('Indiquer le nom de la tenue')
                    if name then 
                        local TempoSkin = {}
                        local ListVet = {
                            ["mask_1"] = true,
                            ["mask_2"] = true,
                            ["tshirt_1"] = true,
                            ["tshirt_2"] = true,
                            ["torso_1"] = true,
                            ["torso_2"] = true,
                            ["arms"] = true,
                            ["arms_2"] = true,
                            ["decals_1"] = true,
                            ["decals_2"] = true,
                            ["pants_1"] = true,
                            ["pants_2"] = true,
                            ["shoes_1"] = true,
                            ["shoes_2"] = true,
                            ["bproof_1"] = true,
                            ["bproof_2"] = true,
                            ["chain_1"] = true,
                            ["chain_2"] = true,
                            ["bags_1"] = true,
                            ["bags_2"] = true,
                            ["helmet_1"] = true,
                            ["helmet_2"] = true,
                            ["glasses_1"] = true,
                            ["glasses_2"] = true,
                        }
                        TriggerEvent("Null:skinchanger:getSkin", function(skin)
                            TriggerServerEvent("Null:esx_skin:save", skin)
                            for k,v in pairs(skin) do 
                                if ListVet[k] ~= nil then
                                    TempoSkin[k] = v
                                end
                            end
                            TriggerServerEvent("null:jobclothes:addtenuvestiaire", name, TempoSkin)
                        end)
                        -- ESX.ShowNotification(('Vous avez ajouter la tenue %s'):format(name))

                    end
                end
            })
        
        end)

        if not RageUI.Visible(main) and 
        not RageUI.Visible(vesitaire) and
        not RageUI.Visible(menuAdd) and
        not RageUI.Visible(menuGestion) then
            main = RMenu:DeleteType("main")
            FreezeEntityPosition(PlayerPedId(), false)
        end 
    end
end


function apllyTenueVestiaire(tenue)
    local clothes = tenue 
    null.fct.game.startAnimAction('clothingtie', 'try_tie_neutral_a')
    Wait(1000)
    ClearPedTasks(PlayerPedId())  

    TriggerEvent('Null:skinchanger:getSkin', function(skin)
        TriggerEvent('Null:skinchanger:loadClothes', skin, json.decode(clothes))
    end)
    -- -- save la tenue 
    -- TriggerEvent('skinchanger:getSkin', function(skin)
    --     TriggerServerEvent('esx_skin:save', skin)
    -- end)
end

