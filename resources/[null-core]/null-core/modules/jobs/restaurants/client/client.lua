local CreatedBlips = {}
local ActiveOrderPoints = {}
RegisterNetEvent("null:restaurant:recevieData", function(result)
    null.fct.waitPlayerLoaded()
    for _, v in pairs(result or {}) do
        null.data.markers.unregister("job_restaurant_vestiaire_"..v.name)
        null.data.markers.unregister("job_restaurant_boss_"..v.name)
        null.data.markers.unregister("job_restaurant_craft_"..v.name)
    end
    null.data.jobs.restaurants.list = result
    null.data.jobs.restaurants.loaded = true
    Wait(1000)
    for k,v in pairs(CreatedBlips) do
        ESX.removeBlip(v)
    end
    ActiveOrderPoints = {}

    for k,v in pairs(null.data.jobs.restaurants.list) do
        table.insert(CreatedBlips, 'restaurant_'..v.name)
        ESX.addBlips({
            name = 'restaurant_'..v.name,
            label = v.label,
            category = 10,
            position = vector3(v.PosBoss.x,v.PosBoss.y,v.PosBoss.z),
            sprite = v.sprite,
            display = 4,
            scale = 0.75,
            color = v.color
        })
        if not null.data.markers.isRegister("job_restaurant_vestiaire_"..v.name) then
            null.data.markers.register("job_restaurant_vestiaire_"..v.name, {
                Position = vector3(v.PosVestiaire.x, v.PosVestiaire.y, v.PosVestiaire.z),
                Public = false,
                Job = v.name,
                Job2 = nil,
                Action = function()
                    OpenVestiaire(ESX.PlayerData.job.name)
                end
            })
        end
        if not null.data.markers.isRegister("job_restaurant_boss_"..v.name) then
            null.data.markers.register("job_restaurant_boss_"..v.name, {
                Position = vector3(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z),
                Public = false,
                Job = v.name,
                Job2 = nil,
                Action = function()
                    OpenSocietyMenu({label = ESX.PlayerData.job.label, name = ESX.PlayerData.job.name }, vector3(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z))
                end
            })
        end
        if not null.data.markers.isRegister("job_restaurant_craft_"..v.name) then
            local craftTableId = "restaurant_" .. v.name
            null.data.markers.register("job_restaurant_craft_"..v.name, {
                Position = vector3(v.PosRecolte.x, v.PosRecolte.y, v.PosRecolte.z),
                Public = false,
                Job = v.name,
                Job2 = nil,
                Action = function()
                    if _G.OpenCraftTabletRestaurant then
                        _G.OpenCraftTabletRestaurant()
                    elseif _G.OpenCraftTable then
                        _G.OpenCraftTable(craftTableId)
                    else
                        ESX.ShowNotification("~r~ Système de craft non disponible")
                    end
                end
            })
        end

        -- Public order points (borne de commande) — E-key interaction, no markers
        if v.orderPoints then
            for i, pos in pairs(v.orderPoints) do
                local px, py, pz = pos.x or pos[1], pos.y or pos[2], pos.z or pos[3]
                table.insert(ActiveOrderPoints, {
                    jobName = v.name,
                    x = px, y = py, z = pz
                })
            end
        end
    end
end)

-- Thread: public order points E-key interaction
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for _, point in ipairs(ActiveOrderPoints) do
            local dist = #(playerCoords - vector3(point.x, point.y, point.z))
            if dist < 2.0 then
                sleep = 0
                ESX.ShowHelpNotification("Appuyez sur ~INPUT_CONTEXT~ pour commander", false, false, 1)
                if IsControlJustPressed(0, 38) then
                    OpenRestaurantOrderShop(point.jobName)
                end
                break
            end
        end

        Citizen.Wait(sleep)
    end
end)

-- ============================================================================
-- Open order shop (public side) — fetches the restaurant shop items and
-- forwards to the ShopUI with an "orderContext" so the buy callback routes
-- to the order placement instead of a normal shop purchase.
-- ============================================================================
function OpenRestaurantOrderShop(jobname)
    ESX.TriggerServerCallback('null:restaurant:getShopItems', function(data)
        if not data then
            ESX.ShowNotification("~r~Ce restaurant n'a aucun article disponible.")
            return
        end
        local storeConfig = {
            Items = data.items,
            Categories = data.categories or {},
            Brand = data.brand,
            Locales = {
                mainTitle = data.label,
                mainTag = data.tag or "Commandez votre repas",
                mainDescription = data.description or "",
            },
            _orderContext = { restaurantName = jobname },
        }
        if exports['null-core'] and exports['null-core'].OpenShopUI then
            exports['null-core']:OpenShopUI(storeConfig, { orderMode = true, orderContext = { restaurantName = jobname } })
        else
            ESX.ShowNotification("~r~ShopUI indisponible")
        end
    end, jobname)
end
_G.OpenRestaurantOrderShop = OpenRestaurantOrderShop

-- Kitchen notification when a new order arrives
RegisterNetEvent('null:restaurant:orderReceived', function(info)
    local msg = ("🛎 Nouvelle commande (%s) — $%s"):format(info.customerName or "Client", info.total or "?")
    if info.logo or info.color then
        TriggerEvent("null:notificationAdvanced", msg, info.restaurantLabel or info.restaurantName, "Commande", info.color, info.logo)
    else
        ESX.ShowNotification(msg)
    end
end)

-- Customer notification when their order is ready at the counter
RegisterNetEvent('null:restaurant:orderReady', function(info)
    local msg = ("~g~🛎 Votre commande chez %s est prête !~s~\nRendez-vous au ~b~comptoir~s~ pour la récupérer."):format(info.restaurantLabel or info.restaurantName or "le restaurant")
    if info.logo or info.color then
        TriggerEvent("null:notificationAdvanced", msg, info.restaurantLabel or info.restaurantName, "Commande Prête", info.color, info.logo)
    else
        ESX.ShowNotification(msg)
    end
end)

Citizen.CreateThread(function()
    Wait(1000)
    TriggerServerEvent("null:restaurant:getData")
end)

RestaurantJobs = {}
RestaurantJobs.OpenRestaurantMenu = function(jobname)
    local menu = RageUI.CreateMenu('Emergency System', "Voici les appeles disponibles")
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while menu do
        Citizen.Wait(0)
        RageUI.IsVisible(menu, function()
            RageUI.Checkbox("Status de l'entreprise", nil, status, {}, {
                onChecked = function()
                    status = true 
                    TriggerServerEvent("vsociety:updateSocietyStatus", jobname, true)
                end,
                onUnChecked = function()
                    status = false 
                    TriggerServerEvent("vsociety:updateSocietyStatus", jobname, false)
                end
            })
            RageUI.Line()
            RageUI.Button('Emettre une facture', nil, {}, true, {
                onSelected = function() 
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    if closestPlayer == -1 or closestDistance > 3.0 then
                        ESX.ShowNotification('Il n\'y a aucun joueur au alentours')
                    else
                        local string = null.fct.input('Montant de la facture')
                        if string ~= "" then
                            Montant = tonumber(string)
                        end
                        TriggerServerEvent("Core:AddBilling", GetPlayerServerId(closestPlayer), tonumber(Montant), jobname)
                    end
                end
            })
            RageUI.Button("Montrer son badge", nil, {}, true, {
                onSelected = function()
                    ShowJobBadge(ESX.PlayerData.job.name)
                end
            })
        end, function()
        end)

        if not RageUI.Visible(menu) then
            menu = RMenu:DeleteType('menu', true)
        end
    end
end
