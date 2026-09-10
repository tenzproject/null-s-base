local SupplierOrders = {} 
local OrderCounter = 0
local ActivePalettes = {} 

local function GenerateOrderId()
    OrderCounter = OrderCounter + 1
    return string.format("%04d", OrderCounter)
end

local function GetOrdersForJob(jobName)
    local orders = {}
    local now = os.time()
    for id, order in pairs(SupplierOrders) do
        if order.jobName == jobName then
            local remaining = math.max(0, order.deliveryTime - (now - order.orderTime))
            table.insert(orders, {
                orderId = id,
                items = order.items,
                totalPrice = order.totalPrice,
                status = order.status,
                orderTime = order.orderTime,
                deliveryTime = order.deliveryTime,
                remainingSeconds = remaining,
            })
        end
    end
    table.sort(orders, function(a, b) return a.orderId > b.orderId end)
    return orders
end

function ProcessOrder(src, xPlayer, jobName, orderItems)
    if not orderItems or #orderItems == 0 then
        TriggerClientEvent('null:restaurant:orderResult', src, { success = false, message = "Commande vide" })
        return
    end
    
    local rawMaterials = _G.GetRawMaterialsForJob(jobName)
    if not rawMaterials then
        TriggerClientEvent('null:restaurant:orderResult', src, { success = false, message = "Aucun matériau disponible" })
        return
    end
    
    local matLookup = {}
    for _, mat in ipairs(rawMaterials) do
        matLookup[mat.name] = mat
    end
    
    local validItems = {}
    local totalPrice = 0
    
    for _, item in ipairs(orderItems) do
        local mat = matLookup[item.name]
        if mat and item.count and item.count > 0 then
            local itemTotal = mat.price * item.count
            table.insert(validItems, {
                name = mat.name,
                label = mat.label,
                count = item.count,
                price = itemTotal,
            })
            totalPrice = totalPrice + itemTotal
        end
    end
    
    if #validItems == 0 then
        TriggerClientEvent('null:restaurant:orderResult', src, { success = false, message = "Aucun article valide" })
        return
    end
    
    local societyMoney = 0
    if SocietyCache and SocietyCache[jobName] and SocietyCache[jobName].data and SocietyCache[jobName].data["accounts"] then
        societyMoney = SocietyCache[jobName].data["accounts"].cash or 0
    end
    
    if societyMoney < totalPrice then
        TriggerClientEvent('null:restaurant:orderResult', src, { success = false, message = "Fonds insuffisants dans la caisse" })
        return
    end
    
    SocietyCache[jobName].data["accounts"].cash = societyMoney - totalPrice
    
    local orderId = GenerateOrderId()
    local deliveryTime = Restaurant.Supplier.DeliveryTime or 120
    
    SupplierOrders[orderId] = {
        jobName = jobName,
        items = validItems,
        totalPrice = totalPrice,
        status = 'pending',
        orderTime = os.time(),
        deliveryTime = deliveryTime,
        source = src,
    }
    
    TriggerClientEvent('null:restaurant:orderResult', src, { success = true, message = "Commande #" .. orderId .. " passée ! Livraison dans " .. math.floor(deliveryTime / 60) .. " min" })
    
    NotifyJobPlayers(jobName, "Nouvelle commande #" .. orderId .. " passée (" .. #validItems .. " articles). Livraison dans ~o~" .. math.floor(deliveryTime / 60) .. " min~s~.")
    
    SendOrdersUpdate(src, jobName)
    
    StartDeliveryTimer(orderId)
end

function NotifyJobPlayers(jobName, message)
    local xPlayers = ESX.GetPlayers()
    for _, playerId in ipairs(xPlayers) do
        local xP = ESX.GetPlayerFromId(playerId)
        if xP and xP.job.name == jobName then
            TriggerClientEvent('esx:showNotification', playerId, message)
        end
    end
end

function SendOrdersUpdate(src, jobName)
    local orders = GetOrdersForJob(jobName)
    TriggerClientEvent('null:restaurant:ordersUpdate', src, orders)
end

function StartDeliveryTimer(orderId)
    local order = SupplierOrders[orderId]
    if not order then return end
    
    Citizen.CreateThread(function()
        Wait(math.floor(order.deliveryTime * 0.25) * 1000)
        if not SupplierOrders[orderId] then return end
        SupplierOrders[orderId].status = 'preparing'
        NotifyJobPlayers(order.jobName, "~b~Commande #" .. orderId .. " en préparation...")
        BroadcastOrdersToJob(order.jobName)
        
        Wait(math.floor(order.deliveryTime * 0.25) * 1000)
        if not SupplierOrders[orderId] then return end
        SupplierOrders[orderId].status = 'delivering'
        NotifyJobPlayers(order.jobName, "~p~Commande #" .. orderId .. " en cours de livraison...")
        BroadcastOrdersToJob(order.jobName)
        
        Wait(math.floor(order.deliveryTime * 0.50) * 1000)
        if not SupplierOrders[orderId] then return end
        SupplierOrders[orderId].status = 'ready'
        NotifyJobPlayers(order.jobName, "~g~Commande #" .. orderId .. " livrée ! La palette est disponible.")
        BroadcastOrdersToJob(order.jobName)
        
        TriggerClientEvent('null:restaurant:spawnPalette', -1, orderId, order.jobName, order.items)
        
        ActivePalettes[orderId] = {
            items = {},
            jobName = order.jobName,
        }
        for _, item in ipairs(order.items) do
            table.insert(ActivePalettes[orderId].items, {
                name = item.name,
                label = item.label,
                count = item.count,
            })
        end
    end)
end

function BroadcastOrdersToJob(jobName)
    local xPlayers = ESX.GetPlayers()
    for _, playerId in ipairs(xPlayers) do
        local xP = ESX.GetPlayerFromId(playerId)
        if xP and xP.job.name == jobName then
            SendOrdersUpdate(playerId, jobName)
        end
    end
end

ESX.RegisterServerCallback('null:restaurant:getPaletteInventory', function(source, cb, orderId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end
    
    local palette = ActivePalettes[orderId]
    if not palette then return cb(nil) end
    
    if xPlayer.job.name ~= palette.jobName then return cb(nil) end
    
    local invItems = {}
    for _, item in ipairs(palette.items) do
        table.insert(invItems, {
            name = item.name,
            label = item.label,
            count = item.count,
            weight = 0,
        })
    end
    
    local inventory = {
        items = invItems,
        loadout = {},
        cash = 0,
        dirtycash = 0,
        weight = 0,
        id = 'palette_' .. orderId,
        maxWeight = 999999,
        type = "BRIEFCASE",
        cacheKey = 'restaurant_palette_' .. orderId,
        savename = 'restaurant_palette_' .. orderId,
    }
    
    cb(inventory, 'restaurant_palette_' .. orderId)
end)

ESX.RegisterServerCallback('null:restaurant:getPaletteItems', function(source, cb, orderId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end
    
    local palette = ActivePalettes[orderId]
    if not palette then return cb(nil) end
    
    if xPlayer.job.name ~= palette.jobName then return cb(nil) end
    
    cb(palette.items)
end)


ESX.RegisterServerCallback('null:restaurant:withdrawPaletteItem', function(source, cb, orderId, itemName, count)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false, "Joueur introuvable") end
    
    local palette = ActivePalettes[orderId]
    if not palette then return cb(false, "Palette introuvable") end
    
    if xPlayer.job.name ~= palette.jobName then return cb(false, "Accès refusé") end
    
    local found = false
    for i, item in ipairs(palette.items) do
        if item.name == itemName then
            local take = math.min(count or item.count, item.count)
            
            if not xPlayer.canCarryItem(itemName, take) then
                return cb(false, "Inventaire plein")
            end
            
            xPlayer.addInventoryItem(itemName, take)
            item.count = item.count - take
            
            if item.count <= 0 then
                table.remove(palette.items, i)
            end
            
            found = true
            break
        end
    end
    
    if not found then return cb(false, "Article introuvable") end
    
    if #palette.items == 0 then
        if SupplierOrders[orderId] then
            SupplierOrders[orderId].status = 'collected'
        end
        ActivePalettes[orderId] = nil
        
        TriggerClientEvent('null:restaurant:despawnPalette', -1, orderId)
        
        NotifyJobPlayers(palette.jobName, "~g~Commande #" .. orderId .. " entièrement récupérée. Merci pour votre commande !")
        BroadcastOrdersToJob(palette.jobName)
        
        cb(true, "Dernier article récupéré. Palette vidée !")
    else
        cb(true, "Article récupéré")
    end
end)

local function GetRestaurantData(jobName)
    if not SaveData.json or not SaveData.json["entreprises"] or not SaveData.json["entreprises"]["Restaurant"] then
        return nil
    end
    for name, data in pairs(SaveData.json["entreprises"]["Restaurant"]) do
        if name == jobName or data.name == jobName then
            return name, data
        end
    end
    return nil
end

RegisterNetEvent('null:restaurant:requestSupplierData')
AddEventHandler('null:restaurant:requestSupplierData', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        TriggerClientEvent('null:restaurant:receiveSupplierData', src, nil)
        return
    end

    local jobName = xPlayer.job.name

    if not SaveData or not SaveData.json
    or not SaveData.json["entreprises"]
    or not SaveData.json["entreprises"]["Restaurant"] then
        TriggerClientEvent('null:restaurant:receiveSupplierData', src, nil)
        return
    end

    local restKey, restData = GetRestaurantData(jobName)
    if not restKey then
        TriggerClientEvent('null:restaurant:receiveSupplierData', src, nil)
        return
    end

    local rawMaterials = _G.GetRawMaterialsForJob and _G.GetRawMaterialsForJob(jobName) or {}
    local orders = GetOrdersForJob(jobName)
    local restLabel = (restData and restData.label) or restKey
    local playerMoney = xPlayer.getMoney()

    local societyMoney = 0
    if SocietyCache and SocietyCache[jobName] and SocietyCache[jobName].data and SocietyCache[jobName].data["accounts"] then
        societyMoney = SocietyCache[jobName].data["accounts"].cash or 0
    end

    TriggerClientEvent('null:restaurant:receiveSupplierData', src, {
        restaurantName = jobName,
        restaurantLabel = restLabel,
        items = rawMaterials,
        orders = orders,
        playerMoney = playerMoney,
        societyMoney = societyMoney,
    })
end)


ESX.RegisterServerCallback('null:restaurant:getSupplierData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return cb(nil)
    end

    local jobName = xPlayer.job.name

    if not SaveData or not SaveData.json then
    elseif not SaveData.json["entreprises"] then
    elseif not SaveData.json["entreprises"]["Restaurant"] then
    else
        for k, v in pairs(SaveData.json["entreprises"]["Restaurant"]) do
        end
    end

    local restKey, restData = GetRestaurantData(jobName)

    if not restKey then
        return cb(nil)
    end

    local rawMaterials = {}
    if _G.GetRawMaterialsForJob then
        rawMaterials = _G.GetRawMaterialsForJob(jobName) or {}
    else
    end

    local orders = GetOrdersForJob(jobName)
    local restLabel = (restData and restData.label) or restKey
    local callbackDone = false
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. jobName, function(account)
        if callbackDone then return end
        callbackDone = true
        local societyMoney = account and account.money or 0
        cb({
            restaurantName = jobName,
            restaurantLabel = restLabel,
            items = rawMaterials,
            orders = orders,
            playerMoney = xPlayer.getMoney(),
            societyMoney = societyMoney,
        })
    end)
    Citizen.CreateThread(function()
        Wait(3000)
        if not callbackDone then
            callbackDone = true
            cb({
                restaurantName = jobName,
                restaurantLabel = restLabel,
                items = rawMaterials,
                orders = orders,
                playerMoney = xPlayer.getMoney(),
                societyMoney = 0,
            })
        end
    end)
end)

RegisterNetEvent('null:restaurant:placeOrder')
AddEventHandler('null:restaurant:placeOrder', function(orderItems)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local jobName = xPlayer.job.name
    local restKey, _ = GetRestaurantData(jobName)

    if not restKey then
        TriggerClientEvent('null:restaurant:orderResult', src, { success = false, message = "Vous ne travaillez pas dans un restaurant" })
        return
    end

    if Restaurant.Supplier.BossOnly then
        MySQL.Async.fetchAll('SELECT MAX(grade) as maxGrade FROM job_grades WHERE job_name = @job', {
            ['@job'] = jobName
        }, function(result)
            local isBoss = result and result[1] and (xPlayer.job.grade == result[1].maxGrade)
            if not isBoss then
                TriggerClientEvent('null:restaurant:orderResult', src, { success = false, message = "Seul le patron peut passer des commandes" })
                return
            end
            ProcessOrder(src, xPlayer, jobName, orderItems)
        end)
    else
        ProcessOrder(src, xPlayer, jobName, orderItems)
    end
end)

AddEventHandler('playerDropped', function()
end)
