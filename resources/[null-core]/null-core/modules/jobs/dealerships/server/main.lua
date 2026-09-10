local PreviewInstances  = {}
local SaleBillingWaiting = {} -- [billId] = true/false/nil (nil=waiting, true=accepted, false=refused)
local ShowroomEntities   = {} -- [shopName][slotKey] = vehicleEntityHandle (server-side)

local CHARSET_NUM  = {}
local CHARSET_ALPH = {}
for i = 48,  57 do CHARSET_NUM[#CHARSET_NUM+1]   = string.char(i) end
for i = 65,  90 do CHARSET_ALPH[#CHARSET_ALPH+1] = string.char(i) end
for i = 97, 122 do CHARSET_ALPH[#CHARSET_ALPH+1] = string.char(i) end

local function RandStr(charset, len)
    local t = {}
    for i = 1, len do
        t[i] = charset[math.random(1, #charset)]
    end
    return table.concat(t)
end

local function GeneratePlate()
    math.randomseed(GetGameTimer() + math.random(1, 99999))
    return string.upper(RandStr(CHARSET_ALPH, 4) .. RandStr(CHARSET_NUM, 4))
end

local function GetVehicleLabel(model)
    return model:upper()
end

local function GetDate()
    local d = os.date('*t')
    return string.format("%02d/%02d/%04d - %02d:%02d:%02d", d.day, d.month, d.year, d.hour, d.min, d.sec)
end

local function GetVehicleType(shopName)
    local shop = Config.Dealerships.Shops[shopName]
    if not shop then return "car" end
    if shop.type == "boat" then return "boat" end
    return "car"
end

local function GetTaxRates()
    local t = SaveData.json["taxes"]
    return {
        salaire = (t and t["salaire"]) or 10,
        retrait = (t and t["retrait"]) or 10,
    }
end

CreateThread(function()
    while SaveData == nil or SaveData.json == nil do Wait(100) end

    if not SaveData.json["dealerships"] then
        SaveData.json["dealerships"] = {}
    end

    for shopName in pairs(Config.Dealerships.Shops) do
        if not SaveData.json["dealerships"][shopName] then
            SaveData.json["dealerships"][shopName] = { stock = {} }
            --null.InitPrint("^3[DEALERSHIP] " .. shopName .. " initialisé (aucun stock existant)^0")
        end
        local stockCount = #SaveData.json["dealerships"][shopName].stock
        --null.InitPrint(string.format("^2[DEALERSHIP] %s chargé - %d véhicules en stock^0", shopName, stockCount))
    end
    -- Log tax rates (SaveData is loaded at this point)
    local initTaxes = GetTaxRates()
    --null.InitPrint(string.format("^2[DEALERSHIP] Taxes actives — Salaire: %d%% | Retrait (TVA): %d%%^0", initTaxes.salaire, initTaxes.retrait))

    MySQL.execute([[
        CREATE TABLE IF NOT EXISTS `dealership_purchases` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `shop` varchar(50) NOT NULL,
            `buyer` varchar(100) NOT NULL,
            `model` varchar(50) NOT NULL,
            `plate` varchar(20) NOT NULL,
            `cost` int(11) NOT NULL DEFAULT 0,
            `purchase_date` varchar(50) NOT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

for shopName, shop in pairs(Config.Dealerships.Shops) do
    TriggerEvent('esx_phone:registerNumber', shopName, shop.label, false, false)
    TriggerEvent('esx_society:registerSociety', shopName, shop.label, shop.society, shop.society, shop.society, { type = 'private' })
end

ESX.RegisterServerCallback('dealership:getTabletData', function(source, cb, shopName, mode)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end

    local result = {
        stock          = {},
        autoSale       = false,
        salesHistory   = {},
        societyMoney   = 0,
        employees      = {},
        restockPercent = Config.Dealerships.RestockCostPercent or 0.6,
        taxRates       = GetTaxRates(),
    }

    if mode == 'employee' or mode == 'boss' then
        if xPlayer.job.name == shopName then
            result.stock = SaveData.json["dealerships"][shopName].stock or {}
            local society = SocietyCache[shopName]
            if society then
                result.societyMoney = society.data.accounts.cash or 0
            end
            -- Employees and bosses both see history
            local history = MySQL.query.await(
                'SELECT * FROM dealership_sales WHERE shop = ? ORDER BY id DESC LIMIT 50', { shopName })
            result.salesHistory = history or {}
            --null.InitPrint(string.format("^3[DEALERSHIP] getTabletData: %s mode=%s stock=%d history=%d^0",
            --    xPlayer.getName(), mode, #result.stock, #result.salesHistory))
        end
    end

    if mode == 'boss' and xPlayer.job.name == shopName then

        local grades = MySQL.query.await(
            'SELECT grade, label FROM job_grades WHERE job_name = ? ORDER BY grade ASC', { shopName })
        local gradeLabels = {}
        if grades then
            for _, g in ipairs(grades) do gradeLabels[g.grade] = g.label end
        end

        local users = MySQL.query.await(
            'SELECT identifier, firstname, lastname, job_grade FROM users WHERE job = ?', { shopName })
        if not users then cb(result) return end

        local allSales = MySQL.query.await(
            'SELECT seller, buyer, sale_price, vehicle_data FROM dealership_sales WHERE shop = ? ORDER BY id DESC',
            { shopName }) or {}
        local allPurchases = MySQL.query.await(
            'SELECT buyer, model, plate, cost, purchase_date FROM dealership_purchases WHERE shop = ? ORDER BY id DESC',
            { shopName }) or {}

       local salesByName     = {}
        local purchasesByName = {}

        for _, s in ipairs(allSales) do
            local name = string.lower(s.seller or '')
            if not salesByName[name] then salesByName[name] = {} end
            salesByName[name][#salesByName[name]+1] = s
        end
        for _, p in ipairs(allPurchases) do
            local name = string.lower(p.buyer or '')
            if not purchasesByName[name] then purchasesByName[name] = {} end
            purchasesByName[name][#purchasesByName[name]+1] = p
        end

        local onlineIds = {}
        for _, pid in ipairs(ESX.GetPlayers()) do
            local p = ESX.GetPlayerFromId(pid)
            if p and p.job and p.job.name == shopName then
                onlineIds[p.identifier] = true
            end
        end

        -- Debug: log all seller names from sales to verify matching
        local sellerNames = {}
        for name in pairs(salesByName) do sellerNames[#sellerNames+1] = name end
        --null.InitPrint(string.format("^3[DEALERSHIP DEBUG] Sellers in DB: [%s]^0", table.concat(sellerNames, ", ")))

        for _, u in ipairs(users) do
            local empName = string.lower((u.firstname or '') .. ' ' .. (u.lastname or ''))
            --null.InitPrint(string.format("^3[DEALERSHIP DEBUG] Matching emp='%s' | salesFound=%d^0", empName, salesByName[empName] and #salesByName[empName] or 0))
            local totalCA  = 0
            local activity = {}

            for _, s in ipairs(salesByName[empName] or {}) do
                totalCA = totalCA + (s.sale_price or 0)
                local vData = json.decode(s.vehicle_data or '{}')
                activity[#activity+1] = {
                    type  = 'sale',
                    model = GetVehicleLabel(vData.model or '?'),
                    plate = vData.plate or '?',
                    buyer = s.buyer or vData.buyerName or '?',
                    price = s.sale_price or 0,
                    date  = vData.saleDate or vData.purchaseDate or '',
                }
            end

            for _, p in ipairs(purchasesByName[empName] or {}) do
                activity[#activity+1] = {
                    type  = 'purchase',
                    model = GetVehicleLabel(p.model or '?'),
                    plate = p.plate or '?',
                    buyer = '',
                    price = -(p.cost or 0),
                    date  = p.purchase_date or '',
                }
            end

            local salesCount = #(salesByName[empName] or {})

            result.employees[#result.employees+1] = {
                identifier = u.identifier,
                firstname  = u.firstname or '?',
                lastname   = u.lastname or '?',
                grade      = u.job_grade or 0,
                gradeLabel = gradeLabels[u.job_grade or 0] or ('Grade ' .. (u.job_grade or 0)),
                online     = onlineIds[u.identifier] or false,
                sales      = activity,
                totalCA    = totalCA,
                totalSales = salesCount,
            }
        end
    end

    cb(result)
end)

ESX.RegisterServerCallback('dealership:getStock', function(source, cb, shopName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= shopName then cb(nil) return end
    cb(SaveData.json["dealerships"][shopName].stock or {})
end)

RegisterNetEvent('dealership:purchaseForStock', function(shopName, model, colorId, catalogPrice)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or xPlayer.job.name ~= shopName then return end

    local shop = Config.Dealerships.Shops[shopName]
    if not shop then return end

    local restockCost = math.floor(catalogPrice * (Config.Dealerships.RestockCostPercent or 0.6))
    local society     = SocietyCache[shopName]

    if not society or society.data.accounts.cash < restockCost then
        TriggerClientEvent('esx:showNotification', _source, '~r~Fonds insuffisants dans la société')
        return
    end

    local plate = GeneratePlate()
    local vehicleData = {
        model        = model,
        plate        = plate,
        color        = colorId,
        price        = catalogPrice,
        purchaseDate = GetDate(),
        serial       = math.random(10000, 99999),
        available    = true,
    }

    society.data.accounts.cash = society.data.accounts.cash - restockCost
    SocietySaved[shopName]     = SocietyCache[shopName]

    addHistorySociety(shopName, "Achat véhicule stock",
        string.format("Véhicule: %s\nPlaque: %s\nPar: %s\nCoût: %s$",
            GetVehicleLabel(model), plate, xPlayer.getName(), ESX.Math.GroupDigits(restockCost)), -restockCost)

    table.insert(SaveData.json["dealerships"][shopName].stock, vehicleData)

    MySQL.insert('INSERT INTO dealership_purchases (shop, buyer, model, plate, cost, purchase_date) VALUES (?, ?, ?, ?, ?, ?)',
        { shopName, xPlayer.getName(), model, plate, restockCost, GetDate() })

    --null.InitPrint(string.format("^3[DEALERSHIP] AchatStock: %s | Modèle: %s | Plaque: %s | Coût: %d$^0",
    --    xPlayer.getName(), model, plate, restockCost))

    TriggerClientEvent('esx:showNotification', _source,
        string.format('~g~Véhicule acheté pour le stock\n~s~%s - %s$',
            GetVehicleLabel(model), ESX.Math.GroupDigits(restockCost)))
end)

ESX.RegisterServerCallback('dealership:sellToPlayer', function(source, cb, shopName, stockIndex, targetId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local xTarget = ESX.GetPlayerFromId(targetId)

    if not xPlayer or not xTarget or xPlayer.job.name ~= shopName then cb(false, 'error') return end

    local stock = SaveData.json["dealerships"][shopName].stock
    if not stock or not stock[stockIndex] or not stock[stockIndex].available then
        cb(false, 'unavailable') return
    end

    local vehicle   = stock[stockIndex]
    local salePrice = math.floor(vehicle.price * Config.Dealerships.PublicSaleMargin)
    local shop      = Config.Dealerships.Shops[shopName]

    -- Check buyer has enough money (cash or bank)
    local buyerCash = xTarget.getAccount('cash').money
    local buyerBank = xTarget.getAccount('bank').money
    if buyerCash + buyerBank < salePrice then
        cb(false, 'nomoney') return
    end

    --null.InitPrint(string.format("^3[DEALERSHIP] Demande vente: %s → %s | %s | %d$^0",
    --    xPlayer.getName(), xTarget.getName(), vehicle.model, salePrice))

    -- Send billing request to buyer using existing billing UI
    local billId = math.random(0, 99999999)
    SaleBillingWaiting[billId] = 'pending'
    TriggerClientEvent("dealership:billingDemande", targetId, billId, salePrice, shopName)

    -- Notify seller that request was sent
    TriggerClientEvent('esx:showNotification', _source,
        string.format('~b~Demande de paiement envoyée à %s (%s$)', xTarget.getName(), ESX.Math.GroupDigits(salePrice)))

    -- Wait up to 30s for buyer response
    local maxWait = 30
    local waited  = 0
    while SaleBillingWaiting[billId] == 'pending' and waited < maxWait do
        Wait(1000)
        waited = waited + 1
        if not ESX.GetPlayerFromId(targetId) then
            SaleBillingWaiting[billId] = nil
            --null.InitPrint("^1[DEALERSHIP] Acheteur déconnecté pendant la demande^0")
            cb(false, 'disconnected') return
        end
    end

    if SaleBillingWaiting[billId] == 'pending' then
        SaleBillingWaiting[billId] = nil
        TriggerClientEvent('esx:showNotification', _source, '~r~Le joueur n\'a pas répondu à temps')
        TriggerClientEvent('esx:showNotification', targetId, '~r~Demande de paiement expirée')
        cb(false, 'timeout') return
    end

    local accepted = SaleBillingWaiting[billId]
    SaleBillingWaiting[billId] = nil

    if not accepted then
        TriggerClientEvent('esx:showNotification', _source, '~r~Le joueur a refusé l\'achat')
        TriggerClientEvent('esx:showNotification', targetId, '~r~Vous avez refusé l\'achat')
        cb(false, 'refused') return
    end

    -- Buyer accepted — deduct money (cash first then bank)
    if buyerCash >= salePrice then
        xTarget.removeAccountMoney('cash', salePrice)
    else
        local fromCash = buyerCash
        local fromBank = salePrice - fromCash
        if fromCash > 0 then xTarget.removeAccountMoney('cash', fromCash) end
        xTarget.removeAccountMoney('bank', fromBank)
    end

    -- Apply TVA (retrait tax)
    local taxes        = GetTaxRates()
    local tvaTax       = math.floor(salePrice * (taxes.retrait / 100))
    local netToSociety = salePrice - tvaTax

    --null.InitPrint(string.format("^2[DEALERSHIP] Vente confirmée: %s | Prix: %d$ | TVA(%d%%): %d$ | Net: %d$^0",
    --    vehicle.model, salePrice, taxes.retrait, tvaTax, netToSociety))

    -- Credit society (net after TVA)
    local society = SocietyCache[shopName]
    society.data.accounts.cash = society.data.accounts.cash + netToSociety
    SocietySaved[shopName]     = SocietyCache[shopName]

    -- Send TVA to government
    local govSociety = SocietyCache['gouvernement']
    if govSociety and tvaTax > 0 then
        govSociety.data.accounts.cash = govSociety.data.accounts.cash + tvaTax
        SocietySaved['gouvernement']  = SocietyCache['gouvernement']
        addHistorySociety('gouvernement', 'TVA Concessionnaire',
            string.format('Concessionnaire: %s\nVéhicule: %s\nPrix vente: %s$\nTVA(%d%%): %s$',
                shopName, GetVehicleLabel(vehicle.model),
                ESX.Math.GroupDigits(salePrice), taxes.retrait, ESX.Math.GroupDigits(tvaTax)), tvaTax)
    end

    -- Register vehicle ownership
    local props = {
        model  = GetHashKey(vehicle.model),
        plate  = vehicle.plate,
        color1 = vehicle.color,
        color2 = vehicle.color,
    }
    SaveData.json["owned_vehicles"][vehicle.plate] = {
        owner    = xTarget.identifier,
        model    = vehicle.model,
        plate    = vehicle.plate,
        vehicle  = props,
        label    = GetVehicleLabel(vehicle.model),
        coffre   = {},
        type     = GetVehicleType(shopName),
        state    = true,
        boutique = false,
        garage   = true,
    }

    local saleRecord = {}
    for k, v in pairs(vehicle) do saleRecord[k] = v end
    saleRecord.saleDate   = GetDate()
    saleRecord.buyerName  = xTarget.getName()
    saleRecord.salePrice  = salePrice  -- store final sale price for history display

    MySQL.insert('INSERT INTO dealership_sales (shop, seller, buyer, vehicle_data, sale_price) VALUES (?, ?, ?, ?, ?)', {
        shopName, xPlayer.getName(), xTarget.getName(), json.encode(saleRecord), salePrice,
    })

    addHistorySociety(shopName, "Vente véhicule",
        string.format("Véhicule: %s\nPlaque: %s\nVendeur: %s\nAcheteur: %s\nPrix: %s$ | TVA(%d%%): %s$ | Net: %s$",
            GetVehicleLabel(vehicle.model), vehicle.plate, xPlayer.getName(), xTarget.getName(),
            ESX.Math.GroupDigits(salePrice), taxes.retrait, ESX.Math.GroupDigits(tvaTax), ESX.Math.GroupDigits(netToSociety)), netToSociety)

    table.remove(SaveData.json["dealerships"][shopName].stock, stockIndex)

    -- Spawn vehicle at config spawn position
    local spawnPos = shop and shop.positions and shop.positions.spawn
    TriggerClientEvent('esx:showNotification', _source,
        string.format('~g~Véhicule vendu avec succès — %s$', ESX.Math.GroupDigits(netToSociety)))
    TriggerClientEvent('esx:showNotification', targetId,
        string.format('~g~Vous avez acheté un %s pour %s$', GetVehicleLabel(vehicle.model), ESX.Math.GroupDigits(salePrice)))
    TriggerClientEvent('dealership:receiveVehicle', targetId, vehicle.model, vehicle.plate, vehicle.color,
        spawnPos and { x = spawnPos.x, y = spawnPos.y, z = spawnPos.z, w = spawnPos.w } or nil)

    -- Notify all online employees/bosses of this shop to refresh tablet
    local newSocietyMoney = society.data.accounts.cash
    for _, pid in ipairs(ESX.GetPlayers()) do
        local p = ESX.GetPlayerFromId(pid)
        if p and p.job and p.job.name == shopName then
            TriggerClientEvent('dealership:saleCompleted', pid, {
                shopName     = shopName,
                sellerName   = xPlayer.getName(),
                sellerId     = xPlayer.identifier,
                model        = vehicle.model,
                plate        = vehicle.plate,
                price        = salePrice,
                date         = saleRecord.saleDate,
                buyerName    = xTarget.getName(),
                societyMoney = newSocietyMoney,
            })
        end
    end

    cb(true, 'ok')
end)

-- Intercept billing responses for dealership sales
-- The global handler in billings/server/server.lua also fires for this event,
-- but SaleBillingWaiting only has keys for dealership bill IDs so it's safe.
RegisterNetEvent('dealership:billingReponse')
AddEventHandler('dealership:billingReponse', function(id, bool)
    if SaleBillingWaiting[id] == 'pending' then
        SaleBillingWaiting[id] = bool
    end
end)

RegisterNetEvent('dealership:takeOutVehicle', function(shopName, stockIndex)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or xPlayer.job.name ~= shopName then return end

    local stock = SaveData.json["dealerships"][shopName].stock
    if not stock or not stock[stockIndex] or not stock[stockIndex].available then
        TriggerClientEvent('esx:showNotification', _source, '~r~Véhicule non disponible')
        return
    end

    local vehicle     = stock[stockIndex]
    vehicle.available = false
    TriggerClientEvent('dealership:spawnStockVehicle', _source, vehicle.model, vehicle.plate, vehicle.color)
    TriggerClientEvent('esx:showNotification', _source, '~g~Véhicule sorti du stock')
end)

RegisterNetEvent('dealership:returnVehicle', function(shopName, plate)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or xPlayer.job.name ~= shopName then return end

    local stock = SaveData.json["dealerships"][shopName].stock
    for _, vehicle in ipairs(stock) do
        if vehicle.plate == plate then
            vehicle.available = true
            TriggerClientEvent('dealership:deleteVehicle', _source)
            TriggerClientEvent('esx:showNotification', _source, '~g~Véhicule remis dans le stock')
            return
        end
    end
    TriggerClientEvent('esx:showNotification', _source, '~r~Ce véhicule n\'appartient pas au stock')
end)

RegisterNetEvent('dealership:removeFromStock', function(shopName, stockIndex)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or xPlayer.job.name ~= shopName or xPlayer.job.grade < 2 then return end

    local stock = SaveData.json["dealerships"][shopName].stock
    if stock and stock[stockIndex] then
        local vehicle = stock[stockIndex]
        table.remove(SaveData.json["dealerships"][shopName].stock, stockIndex)
        addHistorySociety(shopName, "Véhicule retiré du stock",
            string.format("Véhicule: %s\nPlaque: %s\nPar: %s",
                GetVehicleLabel(vehicle.model), vehicle.plate, xPlayer.getName()), 0)
        TriggerClientEvent('esx:showNotification', _source, '~g~Véhicule retiré du stock')
    end
end)

RegisterNetEvent('dealership:payEmployee', function(shopName, identifier)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or xPlayer.job.name ~= shopName or xPlayer.job.grade < 3 then return end

    local userData = MySQL.query.await('SELECT firstname, lastname FROM users WHERE identifier = ?', { identifier })
    if not userData or #userData == 0 then
        TriggerClientEvent('esx:showNotification', _source, '~r~Employé introuvable')
        return
    end

    local empName = string.lower((userData[1].firstname or '') .. ' ' .. (userData[1].lastname or ''))
    local empSales = MySQL.query.await(
        'SELECT sale_price FROM dealership_sales WHERE shop = ? AND LOWER(seller) = ?', { shopName, empName })

    local totalCA = 0
    if empSales then
        for _, s in ipairs(empSales) do totalCA = totalCA + (s.sale_price or 0) end
    end

    local taxes       = GetTaxRates()
    local salaireTax  = taxes.salaire
    local retraitTax  = taxes.retrait

    local rawSalary   = math.floor(totalCA * 0.05)
    local salaryTax   = math.floor(rawSalary * (salaireTax / 100))
    local netSalary   = rawSalary - salaryTax
    local govCATax    = math.floor(totalCA * (retraitTax / 100))
    local totalDeducted = rawSalary + govCATax

    --null.InitPrint(string.format("^3[DEALERSHIP] PayEmployee: %s | CA=%d$ | Brut=%d$ | Impôts=%d$ | Net=%d$ | TaxeCA=%d$^0",
    --    empName, totalCA, rawSalary, salaryTax, netSalary, govCATax))

    if netSalary <= 0 then
        TriggerClientEvent('esx:showNotification', _source, '~r~Aucun salaire à verser')
        return
    end

    local society = SocietyCache[shopName]
    if not society or society.data.accounts.cash < totalDeducted then
        TriggerClientEvent('esx:showNotification', _source, '~r~Fonds insuffisants dans la société')
        return
    end

    society.data.accounts.cash = society.data.accounts.cash - totalDeducted
    SocietySaved[shopName]     = SocietyCache[shopName]

    local targetPlayer = ESX.GetPlayerFromIdentifier(identifier)
    if targetPlayer then
        targetPlayer.addAccountMoney('bank', netSalary)
        TriggerClientEvent('esx:showNotification', targetPlayer.source,
            string.format('~g~Vous avez reçu votre paye\n~s~%s$ (-%s$ impôts %d%%)',
                ESX.Math.GroupDigits(netSalary), ESX.Math.GroupDigits(salaryTax), salaireTax))
    else
        MySQL.update('UPDATE users SET bank = bank + ? WHERE identifier = ?', { netSalary, identifier })
    end

    local totalGov = salaryTax + govCATax
    local govSociety = SocietyCache['gouvernement']
    if govSociety then
        govSociety.data.accounts.cash = govSociety.data.accounts.cash + totalGov
        SocietySaved['gouvernement']  = SocietyCache['gouvernement']
        addHistorySociety('gouvernement', 'Taxes concessionnaire',
            string.format('Concessionnaire: %s\nEmployé: %s\nTaxe salaire (%d%%): %s$\nTaxe CA (%d%%): %s$',
                shopName, empName, salaireTax, ESX.Math.GroupDigits(salaryTax),
                retraitTax, ESX.Math.GroupDigits(govCATax)), totalGov)
    end

    addHistorySociety(shopName, 'Paye employé',
        string.format('Employé: %s\nCA: %s$\nSalaire brut: %s$\nImpôts: %s$\nTaxe CA: %s$\nNet versé: %s$',
            empName, ESX.Math.GroupDigits(totalCA), ESX.Math.GroupDigits(rawSalary),
            ESX.Math.GroupDigits(salaryTax), ESX.Math.GroupDigits(govCATax),
            ESX.Math.GroupDigits(netSalary)), -totalDeducted)

    MySQL.execute('DELETE FROM dealership_sales WHERE shop = ? AND LOWER(seller) = ?',    { shopName, empName })
    MySQL.execute('DELETE FROM dealership_purchases WHERE shop = ? AND LOWER(buyer) = ?', { shopName, empName })

    TriggerClientEvent('esx:showNotification', _source,
        string.format('~g~Paye versée à %s\n~s~Net: %s$ | Taxes État: %s$',
            empName, ESX.Math.GroupDigits(netSalary), ESX.Math.GroupDigits(totalGov)))

    TriggerClientEvent('dealership:paySuccess', _source, {
        identifier = identifier,
        name       = empName,
        net        = netSalary,
    })
end)

RegisterNetEvent('dealership:enterPreviewInstance', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    local instanceId = 50000 + _source
    PreviewInstances[_source] = instanceId
    null.fct.instance.Set(_source, instanceId, "Aperçu véhicule")
end)

RegisterNetEvent('dealership:setVehicleInstance', function(vehicleNetId)
    local _source = source
    if not PreviewInstances[_source] then return end
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
    if DoesEntityExist(vehicle) then
        SetEntityRoutingBucket(vehicle, PreviewInstances[_source])
    end
end)

RegisterNetEvent('dealership:exitPreviewInstance', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end
    PreviewInstances[_source] = nil
    null.fct.instance.Set(_source, 0, "Monde RolePlay")
end)

AddEventHandler('playerDropped', function()
    local _source = source
    PreviewInstances[_source] = nil
end)

ESX.RegisterServerCallback('dealership:getAutoSaleStatus', function(_, cb) cb(false) end)
ESX.RegisterServerCallback('dealership:getSalesHistory', function(source, cb, shopName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= shopName then cb(nil) return end
    MySQL.query('SELECT * FROM dealership_sales WHERE shop = ? ORDER BY id DESC LIMIT 50', { shopName }, function(result)
        cb(result)
    end)
end)

-- ===================== SHOWROOM =====================

ESX.RegisterServerCallback('dealership:getShowroom', function(source, cb, shopName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.job.name ~= shopName or xPlayer.job.grade < 3 then cb(nil) return end
    if not SaveData.json["dealerships"][shopName] then cb(nil) return end
    local showroom = SaveData.json["dealerships"][shopName].showroom or {}
    cb(showroom)
end)

-- Public version: any player can fetch showroom data to spawn display vehicles
ESX.RegisterServerCallback('dealership:getShowroomPublic', function(source, cb, shopName)
    if not SaveData.json["dealerships"] or not SaveData.json["dealerships"][shopName] then
        cb({}) return
    end
    cb(SaveData.json["dealerships"][shopName].showroom or {})
end)

-- ---- Server-side showroom entity management ----

local function DeleteShowroomEntity(shopName, slotKey)
    if ShowroomEntities[shopName] and ShowroomEntities[shopName][slotKey] then
        local ent = ShowroomEntities[shopName][slotKey]
        if DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
        ShowroomEntities[shopName][slotKey] = nil
    end
end

local function SpawnShowroomEntityServer(shopName, slotKey, vehicleData)
    DeleteShowroomEntity(shopName, slotKey)
    if not vehicleData or not vehicleData.model then return end

    local shop = Config.Dealerships.Shops[shopName]
    if not shop or not shop.showroom then return end

    local slotPos = nil
    for _, s in ipairs(shop.showroom.slots or {}) do
        if s.key == slotKey then slotPos = s.position break end
    end
    if not slotPos then return end

    local model = GetHashKey(vehicleData.model)
    local vehicle = CreateVehicle(model, slotPos.x, slotPos.y, slotPos.z, slotPos.w or 0.0, true, false)
    --SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleNumberPlateText(vehicle, vehicleData.plate or "SHOWROOM")
    SetVehicleColours(vehicle, vehicleData.color or 0, vehicleData.color or 0)
    SetEntityCoords(vehicle, slotPos.x, slotPos.y, slotPos.z, false, false, false, false)
    SetEntityHeading(vehicle, slotPos.w or 0.0)
    FreezeEntityPosition(vehicle, true)
    SetVehicleDoorsLocked(vehicle, 2)
    --SetEntityInvincible(vehicle, true)

    if not ShowroomEntities[shopName] then ShowroomEntities[shopName] = {} end
    ShowroomEntities[shopName][slotKey] = vehicle

    -- --null.InitPrint(string.format("^2[DEALERSHIP] Showroom server entity spawned: %s/%s → %s^0",
    --     shopName, slotKey, vehicleData.model))
end

local function RefreshAllShowroomEntities(shopName)
    local shop = Config.Dealerships.Shops[shopName]
    if not shop or not shop.showroom then return end
    if not SaveData.json["dealerships"] or not SaveData.json["dealerships"][shopName] then return end

    local showroom = SaveData.json["dealerships"][shopName].showroom or {}
    for _, slot in ipairs(shop.showroom.slots or {}) do
        if showroom[slot.key] then
            SpawnShowroomEntityServer(shopName, slot.key, showroom[slot.key])
        else
            DeleteShowroomEntity(shopName, slot.key)
        end
    end
end

-- Spawn all showroom vehicles on server start
CreateThread(function()
    while SaveData == nil or SaveData.json == nil do Wait(100) end
    Wait(1000)
    for shopName, shop in pairs(Config.Dealerships.Shops) do
        if shop.showroom and shop.showroom.slots then
            RefreshAllShowroomEntities(shopName)
        end
    end
end)

RegisterNetEvent('dealership:setShowroomVehicle')
AddEventHandler('dealership:setShowroomVehicle', function(shopName, slotKey, stockIndex)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer or xPlayer.job.name ~= shopName or xPlayer.job.grade < 3 then return end

    local shop = Config.Dealerships.Shops[shopName]
    if not shop or not shop.showroom or not shop.showroom.slots then
        TriggerClientEvent('esx:showNotification', _source, '~r~Aucun showroom configuré')
        return
    end

    if not SaveData.json["dealerships"][shopName] then
        TriggerClientEvent('esx:showNotification', _source, '~r~Données indisponibles')
        return
    end

    if not SaveData.json["dealerships"][shopName].showroom then
        SaveData.json["dealerships"][shopName].showroom = {}
    end

    local showroom = SaveData.json["dealerships"][shopName].showroom

    -- stockIndex == nil means clear the slot
    if not stockIndex then
        showroom[slotKey] = nil
        DeleteShowroomEntity(shopName, slotKey)
        TriggerClientEvent('esx:showNotification', _source, '~g~Emplacement showroom vidé')
        --null.InitPrint(string.format("^3[DEALERSHIP] Showroom %s/%s vidé par %s^0", shopName, slotKey, xPlayer.getName()))
    else
        local stock = SaveData.json["dealerships"][shopName].stock
        if not stock or not stock[stockIndex] then
            TriggerClientEvent('esx:showNotification', _source, '~r~Véhicule introuvable dans le stock')
            return
        end
        local veh = stock[stockIndex]
        showroom[slotKey] = {
            model = veh.model,
            plate = veh.plate,
            color = veh.color,
            price = veh.price,
        }
        SpawnShowroomEntityServer(shopName, slotKey, showroom[slotKey])
        --null.InitPrint(string.format("^3[DEALERSHIP] Showroom %s/%s → %s (%s) par %s^0",
        --    shopName, slotKey, veh.model, veh.plate, xPlayer.getName()))
        TriggerClientEvent('esx:showNotification', _source,
            string.format('~g~%s affiché au showroom (%s)', GetVehicleLabel(veh.model), slotKey))
    end

    -- Notify all online employees/bosses of this shop to refresh tablet UI
    for _, pid in ipairs(ESX.GetPlayers()) do
        local p = ESX.GetPlayerFromId(pid)
        if p and p.job and p.job.name == shopName then
            TriggerClientEvent('dealership:showroomUpdated', pid, shopName, showroom)
        end
    end
end)
