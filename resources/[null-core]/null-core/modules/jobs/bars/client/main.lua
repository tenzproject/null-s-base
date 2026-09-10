local IndexDispo = 1
local status = false

openBarBuilder = function()
    local menu = RageUI.CreateMenu(ESX.PlayerData.job.label, "Menu ".. ESX.PlayerData.job.label)
    RageUI.Visible(menu, not RageUI.Visible(menu))

    while menu do
        Citizen.Wait(0)
        RageUI.IsVisible(menu, function()
            RageUI.Checkbox("Status de l'entreprise", nil, status, {}, {
                onChecked = function()
                    status = true 
                    TriggerServerEvent("vsociety:updateSocietyStatus", ESX.PlayerData.job.name, true)
                end,
                onUnChecked = function()
                    status = false 
                    TriggerServerEvent("vsociety:updateSocietyStatus", ESX.PlayerData.job.name, false)
                end
            })
            RageUI.Line()
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
                        TriggerServerEvent("Core:AddBilling", GetPlayerServerId(closestPlayer), tonumber(Montant), ESX.PlayerData.job.name)
                    end
                end,
            onActive = function()

            end})
            RageUI.Button("Montrer son badge", nil, {}, true, {
                onSelected = function()
                    ShowJobBadge(ESX.PlayerData.job.name)
                end
            })
        end)

        if not RageUI.Visible(menu) then
            menu = RMenu:DeleteType('menu', true)
        end
    end
end




local elementsObjectSaisi = {}

OpenFridge = function()
    ESX.TriggerServerCallback('Null:getStockItemsBar', function(items)
        elementsObjectSaisi = {}
        for i=1, #items, 1 do
            table.insert(elementsObjectSaisi, {
                name = items[i].label,
                count = items[i].count,
                value = items[i].name
            })
        end
    end, ESX.PlayerData.job.name)
    local fridge = RageUI.CreateMenu('', "Voici les actions disponibles")
    RageUI.Visible(fridge, not RageUI.Visible(fridge))
    while fridge do
        Citizen.Wait(0)
        RageUI.IsVisible(fridge, function()
            for e, f in pairs(elementsObjectSaisi) do
                if f.count > 0 then
                    RageUI.Button(f.name, false, { RightLabel = "~g~x"..f.count }, true , {
                        onSelected = function()
                            local input = null.fct.input('Choisir une quantité ?', false, 10., "number")
                            if tonumber(input) <= f.count then
                                TriggerServerEvent("Null:bar:take", ESX.PlayerData.job.name, f.value, tonumber(input))
                                Wait(500)
                                ESX.TriggerServerCallback('Null:getStockItemsBar', function(items)
                                    elementsObjectSaisi = {}
                                    for i=1, #items, 1 do
                                        table.insert(elementsObjectSaisi, {
                                            name = items[i].label,
                                            count = items[i].count,
                                            value = items[i].name
                                        })
                                    end
                                end, ESX.PlayerData.job.name)
                            else
                                ESX.ShowNotification("Montant invalide.")
                            end
                        end
                    })
                end
            end
        end, function()
        end)


        if not RageUI.Visible(fridge) then
            fridge = RMenu:DeleteType('fridge', true)
        end
    end
end



local BarBlips = {}

RegisterNetEvent('Null:receiveBarBuilder', function(Table)
    for _, v in pairs(Table or {}) do
        null.data.markers.unregister("job_bar_vestiaire_"..v.name)
        null.data.markers.unregister("job_bar_fridge_"..v.name)
        null.data.markers.unregister("job_bar_boss_"..v.name)
    end
    null.data.jobs.bars.list = Table
    null.data.jobs.bars.loaded = true
    for k,v in pairs(BarBlips) do
        RemoveBlip(v)
    end
    BarBlips = {}

    for k,v in pairs(null.data.jobs.bars.list) do
        if null.data.jobs.bars.list.type == 'Bar' then
            BarBlips[v.name] = AddBlipForCoord(null.data.jobs.bars.list.PosBoss.x, null.data.jobs.bars.list.PosBoss.y, null.data.jobs.bars.list.PosBoss.z)
            SetBlipSprite(BarBlips[v.name], 93)
            SetBlipDisplay(BarBlips[v.name], 4)
            SetBlipScale(BarBlips[v.name], 0.7)
            SetBlipColour(BarBlips[v.name], 58)
            SetBlipAsShortRange(BarBlips[v.name], true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(null.data.jobs.bars.list.label)
            EndTextCommandSetBlipName(BarBlips[v.name])
            SetBlipCategory(BarBlips[v.name], 10)

            if not ZoneExist("job_bar_vestiaire_"..v.name) then
                null.data.markers.register("job_bar_vestiaire_"..v.name, {
                    Position = vector3(v.PosVestiaire.x, v.PosVestiaire.y, v.PosVestiaire.z),
                    Public = false,
                    Job = v.name,
                    Job2 = nil,
                    Action = function()
                        OpenVestiaire(ESX.PlayerData.job.name)
                    end
                })
                null.data.markers.register("job_bar_fridge_"..v.name, {
                    Position = vector3(v.PosBar.x, v.PosBar.y, v.PosBar.z),
                    Public = false,
                    Job = v.name,
                    Job2 = nil,
                    Action = function()
                        OpenFridge()
                    end
                })
                null.data.markers.register("job_bar_boss_"..v.name, {
                    Position = vector3(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z),
                    Public = false,
                    Job = v.name,
                    Job2 = nil,
                    Action = function()
                        OpenSocietyMenu({label = ESX.PlayerData.job.label, name = ESX.PlayerData.job.name }, vector3(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z))
                    end
                })
            end
        end
    end

end)

Citizen.CreateThread(function()
    Wait(2000)
    TriggerServerEvent('Null:initBarBuilder')
end)
