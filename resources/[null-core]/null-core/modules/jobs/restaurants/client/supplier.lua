
local SupplierPed = nil
local SpawnedPalettes = {} 
local isSupplierTabletOpen = false

local SupplierBlip = nil

local function SpawnSupplierPed()
    if SupplierPed and DoesEntityExist(SupplierPed) then return end
    local cfg = Restaurant.Supplier
    if not cfg or not cfg.PedCoords then return end
    local model = GetHashKey(cfg.PedModel or 'a_m_m_hillbilly_01')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    SupplierPed = CreatePed(4, model, cfg.PedCoords.x, cfg.PedCoords.y, cfg.PedCoords.z - 1.0, cfg.PedCoords.w, false, true)
    SetEntityAsMissionEntity(SupplierPed, true, true)
    SetBlockingOfNonTemporaryEvents(SupplierPed, true)
    SetEntityInvincible(SupplierPed, true)
    FreezeEntityPosition(SupplierPed, true)
    TaskStartScenarioInPlace(SupplierPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
    SetModelAsNoLongerNeeded(model)

    if not SupplierBlip then
        SupplierBlip = AddBlipForCoord(cfg.PedCoords.x, cfg.PedCoords.y, cfg.PedCoords.z)
        SetBlipSprite(SupplierBlip, 478)
        SetBlipDisplay(SupplierBlip, 4)
        SetBlipScale(SupplierBlip, 0.3)
        SetBlipColour(SupplierBlip, 5)
        SetBlipAsShortRange(SupplierBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Fournisseur de matières premières")
        EndTextCommandSetBlipName(SupplierBlip)
    end
end

local function IsRestaurantWorker()
    local jobName = ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name
    
    if not jobName then 
        return false 
    end
    
    if null.data.jobs then
        if null.data.jobs.restaurants then
            if null.data.jobs.restaurants.list then
                for _, v in pairs(null.data.jobs.restaurants.list) do
                    if v.name == jobName then
                        return true
                    end
                end
            end
        end
    end

    if Restaurant and Restaurant.List then
        for _, data in pairs(Restaurant.List) do
            if data.JobName == jobName then
                return true
            end
        end
    end
    return false
end

local function OpenSupplierTablet()
    if isSupplierTabletOpen then return end
    TriggerServerEvent('null:restaurant:requestSupplierData')
end

RegisterNetEvent('null:restaurant:receiveSupplierData')
AddEventHandler('null:restaurant:receiveSupplierData', function(data)
    if not data then
        ESX.ShowNotification('~r~ Vous ne travaillez pas dans un restaurant.')
        return
    end
    isSupplierTabletOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'supplierTablet:open', data = data })
end)

local function RegisterSupplierInteraction()
    local cfg = Restaurant.Supplier
    if not cfg or not cfg.PedCoords then 
        return 
    end
    local pedCoords = vector3(cfg.PedCoords.x, cfg.PedCoords.y, cfg.PedCoords.z)

    if Exist3DInteraction('restaurant_supplier') then
        Remove3DInteraction('restaurant_supplier')
    end

    Add3DInteraction({
        id = 'restaurant_supplier',
        coords = pedCoords,
        maxDistance = 20.0,
        maxDistance2 = 1.5,
        key = 'E',
        text = 'Commander des matières premières',
        Action = function()
            OpenSupplierTablet()
        end,
    })
end

local function UnregisterSupplierInteraction()
    if Exist3DInteraction('restaurant_supplier') then
        Remove3DInteraction('restaurant_supplier')
    end
end

Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    local attempts = 0
    while (not null.data.jobs.restaurants.loaded or #null.data.jobs.restaurants.list == 0) and attempts < 50 do
        Wait(100)
        attempts = attempts + 1
    end
    if IsRestaurantWorker() then
        RegisterSupplierInteraction()
    else
    end
end)

AddEventHandler('esx:setJob', function(job)
   if IsRestaurantWorker() then
        RegisterSupplierInteraction()
    else
        UnregisterSupplierInteraction()
    end
end)

RegisterNetEvent('null:restaurant:recevieData')
AddEventHandler('null:restaurant:recevieData', function(result)
    if IsRestaurantWorker() and not Exist3DInteraction('restaurant_supplier') then
        RegisterSupplierInteraction()
    end
end)

RegisterNetEvent('null:restaurant:ordersUpdate')
AddEventHandler('null:restaurant:ordersUpdate', function(orders)
    if isSupplierTabletOpen then
        SendNUIMessage({ action = 'supplierTablet:updateOrders', data = orders })
    end
end)

RegisterNetEvent('null:restaurant:orderResult')
AddEventHandler('null:restaurant:orderResult', function(result)
    SendNUIMessage({ action = 'supplierTablet:orderResult', data = result })
end)

RegisterNUICallback('supplierTablet:close', function(data, cb)
    isSupplierTabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'supplierTablet:close' })
    cb('ok')
end)

RegisterNUICallback('supplierTablet:order', function(data, cb)
    TriggerServerEvent('null:restaurant:placeOrder', data.items or {})
    cb('ok')
end)

RegisterNetEvent('null:restaurant:spawnPalette', function(orderId, jobName, items)
    if ESX.PlayerData.job.name ~= jobName then return end

    local cfg = Restaurant.Supplier
    if not cfg or not cfg.PaletteCoords then return end

    if SpawnedPalettes[orderId] then return end

    local propHash = GetHashKey(cfg.PaletteProp or 'prop_boxpile_03a')
    RequestModel(propHash)
    while not HasModelLoaded(propHash) do Wait(10) end
    local prop = CreateObject(propHash, cfg.PaletteCoords.x, cfg.PaletteCoords.y, cfg.PaletteCoords.z, false, false, false)
    SetEntityHeading(prop, cfg.PaletteCoords.w)
    PlaceObjectOnGroundProperly(prop)
    FreezeEntityPosition(prop, true)
    SetEntityAsMissionEntity(prop, true, true)
    SetModelAsNoLongerNeeded(propHash)
    SpawnedPalettes[orderId] = { prop = prop, jobName = jobName }
    local paletteCoords = vector3(cfg.PaletteCoords.x, cfg.PaletteCoords.y, cfg.PaletteCoords.z)
    Add3DInteraction({
        id = 'restaurant_palette_' .. orderId,
        coords = paletteCoords,
        maxDistance = 15.0,
        maxDistance2 = 2.0,
        key = 'E',
        text = 'Palette #' .. orderId .. ' · Récupérer le contenu',
        Action = function()
            OpenPaletteStash(orderId)
        end,
    })
end)

RegisterNetEvent('null:restaurant:despawnPalette', function(orderId)
    local palette = SpawnedPalettes[orderId]
    if not palette then return end
    if Exist3DInteraction('restaurant_palette_' .. orderId) then
        Remove3DInteraction('restaurant_palette_' .. orderId)
    end
    if palette.prop and DoesEntityExist(palette.prop) then
        DeleteObject(palette.prop)
    end
    SpawnedPalettes[orderId] = nil
end)

function OpenPaletteStash(orderId)
    ESX.TriggerServerCallback('null:restaurant:getPaletteInventory', function(inventory, coffreid)
        if not inventory then
            ESX.ShowNotification("Palette introuvable ou vide.")
            return
        end
        _G._currentPaletteOrderId = orderId
    TriggerEvent("inventory:openTarget", inventory)
    end, orderId)
end

AddEventHandler("esx:inventory:withdraw", function(data)
    if not data or not data.item then return end
    
    local orderId = _G._currentPaletteOrderId
    if not orderId then return end

    local itemName = data.item.name
    local count = data.count or data.item.count or 1

    if not itemName then return end

    ESX.TriggerServerCallback('null:restaurant:withdrawPaletteItem', function(success, message)
        if success then
            ESX.ShowNotification("~g~ Article récupéré")
            ESX.TriggerServerCallback('null:restaurant:getPaletteInventory', function(inventory)
                if inventory and inventory.items and #inventory.items > 0 then
                    local rightInventory = exports["null-core"]:FormatInventoryForUI(inventory)
                    TriggerEvent("esx:refreshRightInventory", rightInventory)
                else
                    _G._currentPaletteOrderId = nil
                    TriggerEvent("inventory:close")
                    ESX.ShowNotification("~g~ Palette entièrement vidée !")
                end
            end, orderId)
        else
            ESX.ShowNotification("~r~ Erreur")
        end
    end, orderId, itemName, count)
end)

AddEventHandler("inventory:onOpen", function(data)
    
end)

AddEventHandler("inventory:onClose", function()
    _G._currentPaletteOrderId = nil
end)

Citizen.CreateThread(function()
    while not ESX.PlayerData.job do Wait(100) end
    Wait(2000)
    SpawnSupplierPed()
end)
