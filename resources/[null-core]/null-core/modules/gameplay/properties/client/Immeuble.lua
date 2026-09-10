function OpenImmeuble(number, typee, label)
    if typee == nil then
        typee = "Middle"
    end
    if label == nil then
        label = number
    end
    local menu = RageUI.CreateMenu('Immeuble', "Que voulez-vous faire ?")
    
    RageUI.Visible(menu, not RageUI.Visible(menu))

    while menu do
        Wait(0)
        RageUI.IsVisible(menu, function()
            RageUI.Line()
            RageUI.Separator(("Intérieur de l'immeuble : %s"):format(label))
            if Config.Properties.List[typee].prices.lifetime then
                RageUI.Button(("Acheter un appartement"), nil, {RightLabel = ("%s$"):format(ESX.Math.GroupDigits(Config.Properties.List[typee].prices.lifetime) or 0)}, true, {
                    onSelected = function()
                        TriggerServerEvent("null:properties:buy", Config.Properties.List[typee], typee, number, "lifetime")
                    end
                })
            end
            if Config.Properties.List[typee].prices.permount then
                RageUI.Button(("Louer un appartement (en rénovation)"), nil, {RightLabel = ("%s$"):format(ESX.Math.GroupDigits(Config.Properties.List[typee].prices.permount) or 0)}, false, {
                    onSelected = function()
                        TriggerServerEvent("null:properties:buy", Config.Properties.List[typee], typee, number, "permount")
                    end
                })
            end
            
            if searchProperty ~= nil then
                RageUI.Button(("Annuler la recherche"), nil, {}, true, {
                    onSelected = function()
                        searchProperty = nil
                    end
                })
            else
                RageUI.Button(("Rechercher"), nil, {RightLabel = searchProperty == nil and '' or searchProperty}, true, {
                    onSelected = function()
                        local input = null.fct.input("Indiquer votre recherche")
                        if input == nil then
                            return ESX.ShowNotification("~r~La recherche ne peut pas être nulle")
                        end
    
                        searchProperty = input
                    end
                })
            end
            RageUI.Checkbox("Uniquement mes propriété", nil, showMyProperties, {}, {
                onChecked = function()
                    showMyProperties = true
                end,
                onUnChecked = function()
                    showMyProperties = false
                end
            })
            --[[RageUI.Checkbox("Visiter", nil, visitBuilding, {}, {
                onChecked = function()
                    local interiorData = Config.properties.interior[interior]
                    visitBuilding = true
                    lastPosition = PlayerStatecoords
                    SetEntityCoords(PlayerStateplayerPed, interiorData.interior)

                    if interiorData.shell then 
                        teleportToShell(interior, 'preview')
                    else
                        SetEntityCoords(PlayerStateplayerPed, interiorData.interior)
                    end
                end,
                onUnChecked = function()
                    visitBuilding = false
                    SetEntityCoords(PlayerStateplayerPed, lastPosition)
                    leaveShell('preview')
                    lastPosition = nil
                end
            })]]
            RageUI.Line()
            if showMyProperties then
                if Properties ~= nil then 
                    for k,v in pairs(Properties) do 
                        if tostring(v.immeuble) == tostring(number) then
                            if v.owner == MyLicense or v.owner == ESX.PlayerData.job.name or v.owner == ESX.PlayerData.job2.name then 
                                if v.id ~= nil then 
                                    if searchProperty ~= nil then
                                        if string.find(tostring(v.id), searchProperty) then
                                            RageUI.Button('Appartement N*'..v.id, nil, {}, true, {
                                                onSelected = function() 
                                                    ActionProperties(k, false)
                                                end
                                            })
                                        end
                                    else
                                        RageUI.Button('Appartement N*'..v.id, nil, {}, true, {
                                            onSelected = function() 
                                                ActionProperties(k, false)
                                            end
                                        })
                                    end
                                end
                            end
                        end
                    end
                end
            else
                if Properties ~= nil then 
                    for k,v in pairs(Properties) do 
                        if tostring(number) == v.immeuble then
                            if searchProperty ~= nil then
                                if string.find(tostring(v.id), searchProperty) then
                                    RageUI.Button('Appartement N*'..v.id, nil, {}, true, {
                                        onSelected = function() 
                                            ActionProperties(k, false)
                                        end
                                    })
                                end
                            else
                                RageUI.Button('Appartement N*'..v.id, nil, {}, true, {
                                    onSelected = function() 
                                        ActionProperties(k, false)
                                    end
                                })
                            end
                        end
                    end
                end
            end
        end, function()
        end)

        if not RageUI.Visible(menu) then
            menu = RMenu:DeleteType('menu', true)
        end
    end
end