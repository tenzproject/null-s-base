function OpenMenuBuyPropreties(info)
    local label, price = info.label, info.price
    local menu = RageUI.CreateMenu('Maison', "Que voulez-vous faire ?")
    
    RageUI.Visible(menu, not RageUI.Visible(menu))

    while menu do
        Wait(0)
        RageUI.IsVisible(menu, function()
            RageUI.Line()
            RageUI.Separator(("Propriété : %s"):format(info.label))
            if ESX.PlayerData.job.name == 'realestateagent' then
                local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                RageUI.Button("Attribuer la maison ( Vente )", nil, {}, closestDistance ~= -1 and true or false, {
                    onActive = function()
                        if closestPlayer ~= -1 and closestDistance < 3.0 then
                            ESX.Utils.EntityMarker(GetPlayerPed(closestPlayer))
                        end
                    end,
                    onSelected = function()
                        TriggerServerEvent("null:properties:PlayerBuyPropeties", info, GetPlayerServerId(closestPlayer))
                        RageUI.CloseAll()
                    end
                })
                RageUI.Button("Attribuer la maison a vous ( Vente )", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent("null:properties:PlayerBuyPropeties", info)
                        RageUI.CloseAll()
                    end
                })
            else
                RageUI.Button("Contacter l'agence Immobilier", "Vous êtes intéresser par cette propriété ? ", {}, true, {
                    onSelected = function()
                        SetNewWaypoint(-709.1039, 268.1188)
                        ESX.ShowNotification("Un point à était placer sur votre Map !")
                    end
                })
            end
            RageUI.Line()
            --[[RageUI.Separator("Prix : "..price.."$")
            RageUI.Button('Visitez cette propriété', nil, {}, true, {
                onSelected = function()
                    EnterProperties("visite", info)
                end
            })
            RageUI.Button('Acheter cette propriété', nil, {}, true, {
                onSelected = function()
                    TriggerServerEvent("null:properties:PlayerBuyPropeties", info)
                    RageUI.CloseAll()
                end
            })]]

        end, function()
        end)

        if not RageUI.Visible(menu) then
            menu = RMenu:DeleteType('menu', true)
        end
    end
end