local currentShop  = nil
local previewVehicle = nil
local previewCam   = nil
local inPreview    = false
local savedPos     = nil
local tabletOpen   = false
local SHOWROOM_POS     = vec3(-290.816345, 1648.461304, -159.7)
local SHOWROOM_HEADING = 47.98029708862305
local CAM_POS          = vec3(-294.54629516602, 1651.7911376953, -159.02914428711)
local CAM_ROT          = vec3(-5.62162017822265, 0.0, -133.0)

local _cachedColors = nil
local function GetColors()
    if not _cachedColors then
        _cachedColors = {}
        for _, c in ipairs(Config.Dealerships.Colors) do
            _cachedColors[#_cachedColors + 1] = { id = c.id, label = c.label, name = c.name }
        end
    end
    return _cachedColors
end

local _colorLabelCache = {}
local function GetColorLabel(colorId)
    if _colorLabelCache[colorId] then return _colorLabelCache[colorId] end
    for _, color in ipairs(Config.Dealerships.Colors) do
        if color.id == colorId then
            _colorLabelCache[colorId] = color.label
            return color.label
        end
    end
    return "Inconnu"
end

local function GetVehicleLabel(model)
    local displayName = GetDisplayNameFromVehicleModel(model)
    if displayName == "CARNOTFOUND" then return model end
    local label = GetLabelText(displayName)
    return (label == "NULL" or label == "") and model or label
end

local function LoadShowroomInterior()
    local interior = GetInteriorAtCoords(SHOWROOM_POS.x, SHOWROOM_POS.y, SHOWROOM_POS.z)
    if interior == 0 then return end
    LoadInterior(interior)
    local timeout = 0
    while not IsInteriorReady(interior) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
end

local function SpawnPreviewVehicle(model, colorId, plate)
    if inPreview then return end
    if previewVehicle then
        ESX.Game.DeleteVehicle(previewVehicle)
        previewVehicle = nil
    end

    local playerPed = PlayerPedId()
    if not savedPos then savedPos = GetEntityCoords(playerPed) end

    inPreview = true

    TriggerServerEvent('dealership:enterPreviewInstance')

    LoadShowroomInterior()

    SetEntityVisible(playerPed, false, 0)
    FreezeEntityPosition(playerPed, true)
    SetEntityCollision(playerPed, false, false)
    SetEntityInvincible(playerPed, true)
    SetEntityCoords(playerPed, SHOWROOM_POS.x, SHOWROOM_POS.y, SHOWROOM_POS.z)
    Wait(400)

    previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(previewCam, CAM_POS.x, CAM_POS.y, CAM_POS.z)
    SetCamRot(previewCam, CAM_ROT.x, CAM_ROT.y, CAM_ROT.z, 2)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 1000, true, true)
    Wait(150)

    ESX.Game.SpawnVehicle(model, SHOWROOM_POS, SHOWROOM_HEADING, function(vehicle)
        if not vehicle or vehicle == 0 then return end
        SetEntityCoords(vehicle, SHOWROOM_POS.x, SHOWROOM_POS.y, SHOWROOM_POS.z)
        SetVehicleOnGroundProperly(vehicle)
        FreezeEntityPosition(vehicle, true)
        SetVehicleDoorsLocked(vehicle, 2)
        SetVehicleNumberPlateText(vehicle, plate or "PREVIEW")
        SetVehicleColours(vehicle, colorId, colorId)
        previewVehicle = vehicle
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerServerEvent('dealership:setVehicleInstance', netId)
    end)
end

local function DeletePreviewVehicle(returnToPos)
    if not inPreview then return end

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    local playerPed = PlayerPedId()

    if returnToPos and savedPos then
        SetEntityCoords(playerPed, savedPos.x, savedPos.y, savedPos.z)
        savedPos = nil
    end

    if previewVehicle then
        ESX.Game.DeleteVehicle(previewVehicle)
        previewVehicle = nil
    end

    if previewCam then
        SetCamActive(previewCam, false)
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(previewCam, true)
        previewCam = nil
    end

    SetEntityVisible(playerPed, true, 0)
    FreezeEntityPosition(playerPed, false)
    SetEntityCollision(playerPed, true, false)
    SetEntityInvincible(playerPed, false)

    inPreview = false

    TriggerServerEvent('dealership:exitPreviewInstance')

    DoScreenFadeIn(500)
end

local function CloseTablet()
    if not tabletOpen then return end
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'dealership:close' })
end

local function OpenTablet(shopName, mode)
    currentShop = shopName
    local shop = Config.Dealerships.Shops[shopName]
    if not shop then return end

    local saleMargin = Config.Dealerships.PublicSaleMargin or 1.25
    local vehicleList = {}
    for _, cat in ipairs(shop.categories) do
        local vehicles = Config.Dealerships.Vehicles[cat]
        if vehicles then
            for _, veh in ipairs(vehicles) do
                vehicleList[#vehicleList + 1] = {
                    model     = veh.model,
                    label     = GetVehicleLabel(veh.model),
                    price     = veh.price,
                    salePrice = math.floor(veh.price * saleMargin),
                    category  = cat,
                    inStock   = false,
                    stockCount = 0,
                }
            end
        end
    end

    local serverData = nil
    ESX.TriggerServerCallback('dealership:getTabletData', function(result)
        serverData = result or {}
    end, shopName, mode)
    while serverData == nil do Wait(10) end

    local stock        = serverData.stock        or {}
    local salesHistory = serverData.salesHistory or {}
    local societyMoney = serverData.societyMoney or 0
    local employees    = serverData.employees    or {}
    local restockPct   = serverData.restockPercent or Config.Dealerships.RestockCostPercent or 0.6
    local taxRates     = serverData.taxRates      or { salaire = 10, retrait = 10 }

    local stockList = {}
    for i, s in ipairs(stock) do
        stockList[#stockList + 1] = {
            model        = s.model,
            label        = GetVehicleLabel(s.model),
            plate        = s.plate,
            color        = s.color,
            colorLabel   = GetColorLabel(s.color),
            price        = s.price,
            purchaseDate = s.purchaseDate or "",
            available    = s.available ~= false,
            index        = i,
        }
    end

    local historyList = {}
    for _, h in ipairs(salesHistory) do
        local vData = json.decode(h.vehicle_data or '{}')
        historyList[#historyList + 1] = {
            seller = h.seller or "?",
            buyer  = h.buyer  or "?",
            model  = GetVehicleLabel(vData.model or "?"),
            plate  = vData.plate or "?",
            price  = vData.salePrice or h.sale_price or 0,  -- salePrice = final price paid by buyer
            date   = vData.saleDate or vData.purchaseDate or "",
        }
    end

    -- Build showroom config slots
    local showroomSlots = {}
    local showroomTitle = ""
    if shop.showroom then
        showroomTitle = shop.showroom.title or "Showroom"
        for _, slot in ipairs(shop.showroom.slots or {}) do
            showroomSlots[#showroomSlots + 1] = { key = slot.key, label = slot.label }
        end
    end

    -- Fetch showroom assignment data (boss only)
    local showroomData = {}
    if mode == 'boss' and #showroomSlots > 0 then
        local srData = nil
        ESX.TriggerServerCallback('dealership:getShowroom', function(r) srData = r or {} end, shopName)
        while srData == nil do Wait(10) end
        showroomData = srData
    end

    tabletOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'dealership:open',
        data = {
            mode          = mode,
            shopName      = shopName,
            shopLabel     = shop.label,
            shopType      = shop.type,
            categories    = shop.categories,
            vehicles      = vehicleList,
            stock         = stockList,
            colors        = GetColors(),
            autoSale      = false,
            salesHistory  = historyList,
            societyMoney  = societyMoney,
            playerJob     = ESX.PlayerData.job and ESX.PlayerData.job.label or "",
            playerGrade   = ESX.PlayerData.job and ESX.PlayerData.job.grade or 0,
            employees     = employees,
            restockPercent  = restockPct,
            taxRates        = taxRates,
            showroomSlots   = showroomSlots,
            showroomTitle   = showroomTitle,
            showroomData    = showroomData,
        }
    })
end

RegisterNUICallback('dealership:close', function(_, cb)
    CloseTablet()
    if inPreview then DeletePreviewVehicle(true) end
    cb('ok')
end)

RegisterNUICallback('dealership:preview', function(data, cb)
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'dealership:hideForPreview' })
    SpawnPreviewVehicle(data.model, data.colorId, "PREVIEW")
    cb('ok')
end)

RegisterNUICallback('dealership:rotate', function(data, cb)
    if previewVehicle then
        local h = GetEntityHeading(previewVehicle)
        SetEntityHeading(previewVehicle, h + (data.direction == 'left' and -7 or 7))
    end
    cb('ok')
end)

RegisterNUICallback('dealership:buyForStock', function(data, cb)
    CloseTablet()
    if inPreview then DeletePreviewVehicle(true) end
    TriggerServerEvent('dealership:purchaseForStock', currentShop, data.model, data.colorId, data.price)
    cb('ok')
end)

RegisterNUICallback('dealership:sellToPlayer', function(data, cb)
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestPlayer == -1 or closestDistance > 5.0 then
        SendNUIMessage({ action = 'dealership:feedback', data = { message = 'Aucun joueur à proximité' } })
        cb('ok')
        return
    end

    local targetId = GetPlayerServerId(closestPlayer)
    CloseTablet()
    if inPreview then DeletePreviewVehicle(true) end

    -- Use server callback so we can wait for buyer acceptance (up to 30s)
    ESX.TriggerServerCallback('dealership:sellToPlayer', function(success, reason)
        if not success then
            local msgs = {
                nomoney     = 'Ce joueur n\'a pas assez d\'argent',
                refused     = 'Le joueur a refusé l\'achat',
                timeout     = 'Le joueur n\'a pas répondu à temps',
                disconnected = 'Le joueur s\'est déconnecté',
                unavailable = 'Véhicule non disponible',
                error       = 'Erreur lors de la vente',
            }
            ESX.ShowNotification('~r~' .. (msgs[reason] or reason or 'Erreur'))
        end
    end, currentShop, data.stockIndex, targetId)
    cb('ok')
end)

RegisterNUICallback('dealership:stockPreview', function(data, cb)
    local shop = Config.Dealerships.Shops[currentShop]
    if not shop then cb('ok') return end

    local stockData = nil
    ESX.TriggerServerCallback('dealership:getStock', function(s) stockData = s or {} end, currentShop)
    while stockData == nil do Wait(10) end

    local veh = stockData[data.stockIndex]
    if veh then
        tabletOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'dealership:hideForPreview' })
        SpawnPreviewVehicle(veh.model, veh.color, veh.plate)
    end
    cb('ok')
end)

RegisterNUICallback('dealership:payEmployee', function(data, cb)
    TriggerServerEvent('dealership:payEmployee', currentShop, data.identifier)
    cb('ok')
end)

RegisterNUICallback('dealership:societyMenu', function(_, cb)
    CloseTablet()
    local shop = Config.Dealerships.Shops[currentShop]
    if shop then
        OpenSocietyMenu({ label = shop.label, name = currentShop }, shop.positions.vendor)
    end
    cb('ok')
end)

RegisterNUICallback('dealership:setShowroomVehicle', function(data, cb)
    -- data: { slotKey, stockIndex (nil to clear) }
    TriggerServerEvent('dealership:setShowroomVehicle', currentShop, data.slotKey, data.stockIndex)
    cb('ok')
end)

CreateThread(function()
    local hintShown = false
    while true do
        if inPreview then
            Wait(0)

            DisableControlAction(0, 200, true)  
            DisableControlAction(0, 199, true)  
            DisableControlAction(1, 23,  true)  
            DisableControlAction(1, 75,  true)  
            DisableControlAction(0, 24,  true)  
            DisableControlAction(0, 25,  true)  
            DisableControlAction(0, 1,   true) 
            DisableControlAction(0, 2,   true) 

            if not hintShown then
                hintShown = true
                SendNUIMessage({ action = 'dealership:showPreviewHint' })
            end

            if previewVehicle and DoesEntityExist(previewVehicle) then
                if IsDisabledControlPressed(0, 174) or IsControlPressed(0, 174) then
                    SetEntityHeading(previewVehicle, GetEntityHeading(previewVehicle) - 1.5)
                end
                if IsDisabledControlPressed(0, 175) or IsControlPressed(0, 175) then
                    SetEntityHeading(previewVehicle, GetEntityHeading(previewVehicle) + 1.5)
                end
            end

            if IsDisabledControlJustPressed(0, 177) or IsControlJustPressed(0, 177)
            or IsDisabledControlJustPressed(0, 178) or IsControlJustPressed(0, 178) then
                hintShown = false
                SendNUIMessage({ action = 'dealership:hidePreviewHint' })
                local shopName = currentShop
                DeletePreviewVehicle(true)
                Wait(300)
                if shopName then OpenTablet(shopName, 'public') end
            end
        else
            if hintShown then
                hintShown = false
                SendNUIMessage({ action = 'dealership:hidePreviewHint' })
            end
            Wait(500)
        end
    end
end)

-- Buyer receives vehicle purchase request (separate event from global billing to avoid collision)
RegisterNetEvent('dealership:billingDemande')
AddEventHandler('dealership:billingDemande', function(billId, amount, shopLabel)
    ESX.ShowAccept(
        string.format('~b~Achat véhicule~s~\nConcessionnaire: ~g~%s~s~\nMontant: ~g~%s$~s~\nAcceptez-vous ?',
            shopLabel or 'Concessionnaire', ESX.Math.GroupDigits(amount)),
        function(result)
            TriggerServerEvent('dealership:billingReponse', billId, result)
        end
    )
end)

RegisterNetEvent('dealership:paySuccess', function(data)
    if tabletOpen then
        SendNUIMessage({ action = 'dealership:paySuccess', data = data })
    end
end)

RegisterNetEvent('dealership:saleCompleted', function(data)
    if tabletOpen then
        SendNUIMessage({ action = 'dealership:saleCompleted', data = data })
    end
end)

RegisterNetEvent('dealership:receiveVehicle', function(model, plate, colorId, spawnPos)
    -- spawnPos comes from server config; fallback to player position
    local pos, heading
    if spawnPos then
        pos     = vector3(spawnPos.x, spawnPos.y, spawnPos.z)
        heading = spawnPos.w or 0.0
    else
        local shop = currentShop and Config.Dealerships.Shops[currentShop]
        if shop and shop.positions and shop.positions.spawn then
            local s = shop.positions.spawn
            pos     = vector3(s.x, s.y, s.z)
            heading = s.w or 0.0
        else
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            pos     = vector3(coords.x + 5.0, coords.y, coords.z)
            heading = GetEntityHeading(ped)
        end
    end
    ESX.Game.SpawnVehicle(model, pos, heading, function(vehicle)
        SetVehicleNumberPlateText(vehicle, plate)
        SetVehicleColours(vehicle, colorId, colorId)
        SetVehicleOnGroundProperly(vehicle)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    end)
end)

RegisterNetEvent('dealership:deleteVehicle', function()
    DeletePreviewVehicle(false)
end)

-- Showroom vehicles are spawned server-side (visible to all clients automatically).
-- Only handle NUI tablet refresh when assignments change.
RegisterNetEvent('dealership:showroomUpdated')
AddEventHandler('dealership:showroomUpdated', function(shopName, showroomData)
    if tabletOpen and currentShop == shopName then
        SendNUIMessage({ action = 'dealership:showroomUpdated', data = showroomData })
    end
end)

RegisterCommand('openCarDealer', function()
    OpenTablet('carshop', 'public')
end, false)

RegisterCommand('openMotoDealer', function()
    OpenTablet('bikeshop', 'public')
end, false)

RegisterCommand('openBoatDealer', function()
    OpenTablet('boatshop', 'public')
end, false)

function OpenDealerJobTablet(shopName)
    local job = ESX.PlayerData.job
    if not job or job.name ~= shopName then
        ESX.ShowNotification('~r~Vous n\'êtes pas employé ici')
        return
    end
    OpenTablet(shopName, job.grade >= 3 and 'boss' or 'employee')
end

RegisterCommand('jobCarDealer',  function() OpenDealerJobTablet('carshop')  end, false)
RegisterCommand('jobMotoDealer', function() OpenDealerJobTablet('bikeshop') end, false)
RegisterCommand('jobBoatDealer', function() OpenDealerJobTablet('boatshop') end, false)

CreateThread(function()
    null.fct.waitPlayerLoaded()

    for shopName, shop in pairs(Config.Dealerships.Shops) do
        local blip = AddBlipForCoord(shop.positions.vendor.x, shop.positions.vendor.y, shop.positions.vendor.z)
        SetBlipSprite(blip, shop.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, shop.blip.scale)
        SetBlipColour(blip, shop.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(shop.label)
        EndTextCommandSetBlipName(blip)

        local jobMode = function()
            return ESX.PlayerData.job.grade >= 3 and 'boss' or 'employee'
        end

        null.data.markers.register("dealership_vendor_"..shopName, {
            Position = shop.positions.vendor,
            Public   = false,
            Job      = shopName,
            Action   = function() OpenTablet(shopName, jobMode()) end,
        })

        null.data.markers.register("dealership_catalogue_"..shopName, {
            Position = shop.positions.catalogue,
            Public   = true,
            Action   = function() OpenTablet(shopName, 'public') end,
        })

        null.data.markers.register("dealership_wardrobe_"..shopName, {
            Position = shop.positions.wardrobe,
            Public   = false,
            Job      = shopName,
            Action   = function() OpenVestiaire(ESX.PlayerData.job.name) end,
        })
    end
end)
