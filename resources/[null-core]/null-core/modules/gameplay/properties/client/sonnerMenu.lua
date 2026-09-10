local hasSonned = {}

function OpenMenuSonnerProperties(info)
    local label = info.label
    local menu = RageUI.CreateMenu('Maison', "Tu es chez quelqu'un !")
    
    RageUI.Visible(menu, not RageUI.Visible(menu))

    while menu do
        Wait(0)
        RageUI.IsVisible(menu, function()
            RageUI.Button("Sonner à la porte", nil, {}, not hasSonned[info.name], {
                onSelected = function()
                    TriggerServerEvent("null:properties:PlayerSonnedToPropreties", info)
                    PlaySoundFrontend(l_6C6, "DOOR_BUZZ", "MP_PLAYER_APARTMENT", 1)
                    hasSonned[info.name] = true
                    Citizen.SetTimeout(60000, function()
                        hasSonned[info.name] = false
                    end)
                end
            })

        end, function()
        end)

        if not RageUI.Visible(menu) then
            menu = RMenu:DeleteType('menu', true)
        end
    end
end