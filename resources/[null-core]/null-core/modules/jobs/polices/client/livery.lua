Citizen.CreateThread(function()
    while ESX.PlayerLoaded == nil do end

    while not ESX.PlayerData.job do 
        Citizen.Wait(10)
    end

    while not null.data.markers.loaded do Wait(100) end

    local playerJob = ESX.PlayerData.job.name

    for k, v in pairs(extrasCFG) do
        if type(v) == 'table' then
            for k2, v2 in pairs(v) do
                null.data.markers.register(("extras_menu-%s-%s"):format(k, k2), {
                    Position = v2,
                    Public = false,
                    Job = k,
                    Blip = false,
                    Action = function()
                        local ped = PlayerPedId()
                        if GetVehiclePedIsIn(ped, false) == 0 then
                            return ESX.ShowNotification("~r~Vous ne pouvez pas ouvrir le menu d'extra en étant à pied")
                        end
                        openExtrasMenu()
                    end
                })
            end
        else
            null.data.markers.register("extras_menu-"..k, {
                Position = v,
                Public = false,
                Job = k,
                Blip = false,
                Action = function()
                    openExtrasMenu()
                end
            })
        end
    end
end)

function openExtrasMenu()
    -- local playerJob = ESX.PlayerData.job.name
    -- if not extrasCFG[playerJob] or ESX.PlayerData.group ~= "user" then
    --     return
    -- end

    local menu = RageUI.CreateMenu('', 'Menu extras')
    menu.extrasmenu = RageUI.CreateSubMenu(menu, '', 'Liste des extras')
    menu.liveriesmenu = RageUI.CreateSubMenu(menu, '', 'Liste des liveries')

    menu.coords = GetEntityCoords(PlayerPedId())
    menu.indexList = 1
    menu.vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    RageUI.Visible(menu, not RageUI.Visible(menu))

    while menu do
        Citizen.Wait(0)

        RageUI.IsVisible(menu, function()
            RageUI.Button('Extras', false, {}, true, {}, menu.extrasmenu)

            RageUI.Button('Liveries', false, {}, true, {}, menu.liveriesmenu)
        end)

        RageUI.IsVisible(menu.extrasmenu, function()
            menu.vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

            if menu.vehicle then
                if GetVehicleEngineHealth(menu.vehicle) >= 998.0 then
                    for id = 0, 20 do
                        if DoesExtraExist(menu.vehicle, id) then
                            RageUI.Checkbox(("Extra N°%s"):format(id), nil, IsVehicleExtraTurnedOn(menu.vehicle, id), {}, {
                                onChecked = function ()
                                    SetVehicleExtra(menu.vehicle, id, 0)
                                end,
                                onUnChecked = function ()
                                    SetVehicleExtra(menu.vehicle, id, 1)
                                end
                            })
                        end
                    end
                else
                    RageUI.Separator('Votre véhicule est endommagé.')
                end
            end
        end)

        RageUI.IsVisible(menu.liveriesmenu, function()
            menu.vehicle = GetVehiclePedIsIn(PlayerPedId(), false)

            if #(menu.coords - GetEntityCoords(PlayerPedId())) > 5 then
                RageUI.Visible(menu, false)
            end

            if menu.vehicle then
                if GetVehicleEngineHealth(menu.vehicle) >= 998.0 then
                    if GetVehicleLiveryCount(menu.vehicle) == -1 then 
                        RageUI.Separator('Aucune liveries pour ce véhicule.')
                    else
                        for i = 0, GetVehicleLiveryCount(menu.vehicle) do
                            RageUI.Checkbox(("Liverie N°%s"):format(i), nil, GetVehicleLivery(menu.vehicle) == i, {}, {
                                onChecked = function()
                                    SetVehicleLivery(menu.vehicle, i)
                                end,
                            })
                        end
                    end
                else
                    RageUI.Separator('Votre véhicule est endommagé.')
                end
            end
        end)

        if not RageUI.Visible(menu) and not RageUI.Visible(menu.liveriesmenu) and not RageUI.Visible(menu.extrasmenu) or #(menu.coords - GetEntityCoords(PlayerPedId())) > 5 then
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

RegisterNetEvent("null:client:openExtrasMenu")
AddEventHandler("null:client:openExtrasMenu", openExtrasMenu)