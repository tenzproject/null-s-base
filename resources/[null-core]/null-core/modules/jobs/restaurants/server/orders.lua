-- ============================================================================
-- Restaurant Orders — Server
-- Clients place orders at "borne de commande"; kitchen employees prepare them
-- and deliver to the customer's inventory.
-- Orders are kept in-memory (runtime) — they are volatile on restart.
-- ============================================================================

RestaurantOrders = RestaurantOrders or {}  -- { [jobname] = { {id, items, customerSrc, customerIdentifier, customerName, total, status, createdAt, claimedBy} ... } }

local function genOrderId()
    return ("ord_%d_%d"):format(os.time(), math.random(10000, 99999))
end

local function getRestaurantData(jobname)
    if not SaveData or not SaveData.json or not SaveData.json["entreprises"] or not SaveData.json["entreprises"]["Restaurant"] then
        return nil
    end
    return SaveData.json["entreprises"]["Restaurant"][jobname]
end

-- A craft is orderable by default; admins can mark it `Orderable = false`
local function isCraftOrderable(craft)
    return craft.Orderable ~= false
end

local function findOrderableCraft(jobname, itemName)
    local data = getRestaurantData(jobname)
    if not data or not data.crafts then return nil end
    for _, craft in pairs(data.crafts) do
        if string.lower(craft.Item or "") == string.lower(itemName) and isCraftOrderable(craft) then
            return craft
        end
    end
    return nil
end

local function getRestaurantCraftPrice(jobname, itemName)
    local craft = findOrderableCraft(jobname, itemName)
    if not craft then return nil end
    if craft.SellPrice then return tonumber(craft.SellPrice) end
    local base = 15
    if craft.Requirements then
        for _, r in pairs(craft.Requirements) do
            base = base + (r.Amount or 1) * 5
        end
    end
    return base
end

-- Build the shop items list for a given restaurant (orderable only)
local function BuildRestaurantShopItems(jobname)
    local data = getRestaurantData(jobname)
    if not data or not data.crafts then return {}, {} end
    local items = {}
    local categorySet = {}
    for key, craft in pairs(data.crafts) do
        if isCraftOrderable(craft) then
            local itemName = string.lower(craft.Item or key)
            local price = getRestaurantCraftPrice(jobname, itemName) or 20
            local category = craft.Category or "Menu"
            categorySet[category] = true
            table.insert(items, {
                name = itemName,
                label = craft.Label or key,
                price = price,
                category = category,
                image = "items/" .. itemName .. ".webp",
            })
        end
    end
    -- Build ShopUI-compatible categories list (with "all" prepended)
    local categories = { { name = "Tout", type = "all", icon = "LayoutGrid" } }
    local sorted = {}
    for cat in pairs(categorySet) do table.insert(sorted, cat) end
    table.sort(sorted)
    for _, cat in ipairs(sorted) do
        table.insert(categories, { name = cat, type = cat, icon = "UtensilsCrossed" })
    end
    return items, categories
end

ESX.RegisterServerCallback('null:restaurant:getShopItems', function(source, cb, jobname)
    if not jobname then return cb(nil) end
    local data = getRestaurantData(jobname)
    if not data then return cb(nil) end
    local items, categories = BuildRestaurantShopItems(jobname)
    if #items == 0 then return cb(nil) end
    cb({
        label = data.label or jobname,
        tag = "Commandez votre repas",
        description = data.description or "",
        brand = {
            id = "restaurant_" .. jobname,
            name = data.label or jobname,
            logo = (data.logo ~= "" and data.logo) or nil,
            bgColor = data.brandColor or "#e74c3c",
            accentColor = data.brandColor or "#e74c3c",
            tagline = data.description or "",
        },
        items = items,
        categories = categories,
    })
end)

-- Place an order (triggered by shopui callback when orderContext = restaurantName)
ESX.RegisterServerCallback('null:restaurant:placeOrder', function(source, cb, paymentType, cartArray, jobname)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false, "Joueur introuvable") end
    if not jobname or not getRestaurantData(jobname) then return cb(false, "Restaurant introuvable") end
    if not cartArray or #cartArray == 0 then return cb(false, "Panier vide") end

    -- Compute server-side price (don't trust client)
    local total = 0
    local orderItems = {}
    for _, ci in ipairs(cartArray) do
        local price = getRestaurantCraftPrice(jobname, ci.name)
        if not price then return cb(false, "Article invalide: " .. (ci.label or ci.name)) end
        local qty = math.max(1, math.floor(ci.quantity or 1))
        total = total + price * qty
        table.insert(orderItems, {
            name = string.lower(ci.name),
            label = ci.label or ci.name,
            quantity = qty,
            price = price,
        })
    end

    local account = (paymentType == "bank") and "bank" or "cash"
    local money = xPlayer.getAccount(account).money
    if money < total then return cb(false, "Fonds insuffisants") end

    xPlayer.removeAccountMoney(account, total)

    -- Credit the restaurant's society account
    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. jobname, function(societyAccount)
        if societyAccount then
            societyAccount.addMoney(total)
        end
    end)

    RestaurantOrders[jobname] = RestaurantOrders[jobname] or {}
    local order = {
        id = genOrderId(),
        items = orderItems,
        customerSrc = source,
        customerIdentifier = xPlayer.identifier,
        customerName = (xPlayer.getName and xPlayer.getName()) or xPlayer.name or ("Client #" .. source),
        total = total,
        status = "pending",  -- pending -> preparing -> delivered
        createdAt = os.time(),
        claimedBy = nil,
    }
    table.insert(RestaurantOrders[jobname], order)

    -- Notify kitchen staff with a refresh signal
    local players = ESX.GetPlayers()
    for _, pid in ipairs(players) do
        local p = ESX.GetPlayerFromId(pid)
        if p and p.job and p.job.name == jobname then
            TriggerClientEvent('null:restaurant:orderReceived', pid, {
                restaurantName = jobname,
                restaurantLabel = (GetRestaurantBrand(jobname) and GetRestaurantBrand(jobname).label) or jobname,
                customerName = order.customerName,
                total = total,
                logo = GetRestaurantBrand(jobname) and GetRestaurantBrand(jobname).logo,
                color = GetRestaurantBrand(jobname) and GetRestaurantBrand(jobname).brandColor,
            })
        end
    end

    xPlayer.showNotification(("Commande envoyée à la cuisine ! Total: $%d"):format(total))
    cb(true, { orderId = order.id, total = total })
end)

local function findOrder(jobname, orderId)
    local list = RestaurantOrders[jobname] or {}
    for i, o in ipairs(list) do
        if o.id == orderId then return o, i end
    end
    return nil, nil
end

ESX.RegisterServerCallback('null:restaurant:getOrders', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({}) end
    local jobname = xPlayer.job.name
    local list = RestaurantOrders[jobname] or {}
    local out = {}
    for _, o in ipairs(list) do
        table.insert(out, {
            id = o.id,
            items = o.items,
            customerName = o.customerName,
            total = o.total,
            status = o.status,
            createdAt = o.createdAt,
            claimedBy = o.claimedBy,
        })
    end
    cb(out)
end)

ESX.RegisterServerCallback('null:restaurant:claimOrder', function(source, cb, orderId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end
    local jobname = xPlayer.job.name
    local order = findOrder(jobname, orderId)
    if not order then return cb(false, "Commande introuvable") end
    if order.status ~= "pending" then return cb(false, "Commande déjà prise") end
    order.status = "preparing"
    order.claimedBy = source
    cb(true)
end)

-- Helper: resolve an order's customer xPlayer (by identifier, fallback)
local function resolveCustomer(order)
    local customer = ESX.GetPlayerFromId(order.customerSrc)
    if customer and customer.identifier == order.customerIdentifier then
        return customer
    end
    local players = ESX.GetPlayers()
    for _, pid in ipairs(players) do
        local p = ESX.GetPlayerFromId(pid)
        if p and p.identifier == order.customerIdentifier then
            return p
        end
    end
    return nil
end

-- Kitchen marks an order as ready → customer is notified to come to the counter
ESX.RegisterServerCallback('null:restaurant:markReady', function(source, cb, orderId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false, "Joueur introuvable") end
    local jobname = xPlayer.job.name
    local order = findOrder(jobname, orderId)
    if not order then return cb(false, "Commande introuvable") end
    if order.status == "ready" or order.status == "delivered" then
        return cb(false, "La commande est déjà prête")
    end

    order.status = "ready"
    order.readyAt = os.time()

    local customer = resolveCustomer(order)
    if customer then
        --customer.showNotification("~g~🛎 Votre commande est prête !~s~\nVenez la récupérer au ~b~comptoir du restaurant~s~.")
        TriggerClientEvent('null:restaurant:orderReady', customer.source, {
            restaurantName = jobname,
            restaurantLabel = (GetRestaurantBrand(jobname) and GetRestaurantBrand(jobname).label) or jobname,
            orderId = orderId,
            logo = GetRestaurantBrand(jobname) and GetRestaurantBrand(jobname).logo,
            color = GetRestaurantBrand(jobname) and GetRestaurantBrand(jobname).brandColor,
        })
    end

    cb(true)
end)

-- Employee at the counter hands over the order to the customer in person
-- Requires proximity (server-side distance check) between employee and customer
ESX.RegisterServerCallback('null:restaurant:handOverOrder', function(source, cb, orderId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false, "Joueur introuvable") end
    local jobname = xPlayer.job.name
    local order, idx = findOrder(jobname, orderId)
    if not order then return cb(false, "Commande introuvable") end
    if order.status == "delivered" then return cb(false, "Commande déjà remise") end
    if order.status ~= "ready" then return cb(false, "La commande n'est pas encore prête") end

    local customer = resolveCustomer(order)
    if not customer then
        return cb(false, "Le client n'est plus en ligne")
    end

    -- Proximity check: customer must be next to the employee (comptoir)
    local empPed = GetPlayerPed(source)
    local custPed = GetPlayerPed(customer.source)
    if empPed == 0 or custPed == 0 then
        return cb(false, "Impossible de localiser le client")
    end
    local empCoords = GetEntityCoords(empPed)
    local custCoords = GetEntityCoords(custPed)
    local dist = #(empCoords - custCoords)
    if dist > 5.0 then
        return cb(false, ("Le client n'est pas au comptoir (%.1fm)"):format(dist))
    end

    -- Deliver items (respects inventory capacity)
    local deliveredAny = false
    for _, it in ipairs(order.items) do
        if customer.canCarryItem(it.name, it.quantity) then
            customer.addInventoryItem(it.name, it.quantity)
            deliveredAny = true
        else
            customer.showNotification(("~r~Vous ne pouvez pas porter %s x%d"):format(it.label, it.quantity))
        end
    end

    if not deliveredAny then
        return cb(false, "Le client ne peut rien porter")
    end

    order.status = "delivered"
    customer.showNotification(("~g~Commande remise par %s"):format(xPlayer.getName and xPlayer.getName() or "un employé"))

    -- Remove from list after short delay so UI shows "delivered" briefly
    Citizen.SetTimeout(2000, function()
        local _, i = findOrder(jobname, orderId)
        if i then table.remove(RestaurantOrders[jobname], i) end
    end)

    cb(true)
end)

ESX.RegisterServerCallback('null:restaurant:cancelOrder', function(source, cb, orderId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end
    local jobname = xPlayer.job.name
    local order, idx = findOrder(jobname, orderId)
    if not order or not idx then return cb(false) end

    -- Refund the customer
    local customer = ESX.GetPlayerFromId(order.customerSrc)
    if not customer or customer.identifier ~= order.customerIdentifier then
        customer = nil
        local players = ESX.GetPlayers()
        for _, pid in ipairs(players) do
            local p = ESX.GetPlayerFromId(pid)
            if p and p.identifier == order.customerIdentifier then
                customer = p
                break
            end
        end
    end
    if customer then
        customer.addAccountMoney("bank", order.total)
        customer.showNotification(("~r~Votre commande a été annulée. Remboursement: $%d"):format(order.total))
    end

    TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. jobname, function(societyAccount)
        if societyAccount then societyAccount.removeMoney(order.total) end
    end)

    table.remove(RestaurantOrders[jobname], idx)
    cb(true)
end)

AddEventHandler('playerDropped', function()
    -- Keep orders alive; another employee can still deliver. Customer identifier is preserved.
end)

_G.BuildRestaurantShopItems = BuildRestaurantShopItems
_G.GetRestaurantBrand = function(jobname)
    local data = getRestaurantData(jobname)
    if not data then return nil end
    return {
        label = data.label or jobname,
        brandColor = data.brandColor or "#e74c3c",
        logo = data.logo or "",
        description = data.description or "",
    }
end
