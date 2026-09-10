-- ============================================================================
-- SHOP UI - Client Side
-- Receives storeConfig objects from markers-ui.lua via export
-- ============================================================================

local shopOpen = false
local activeOrderContext = nil  -- { restaurantName = "..." } when ShopUI is opened in order mode

local defaultLocales = {
    cartTitle = "Panier",
    cartDescription = "Vérifiez les articles choisis et procédez au paiement.",
    addCart = "Ajouter au Panier",
    paymentTitle = "PAIEMENT",
    payBank = "Banque",
    payCash = "Espèces",
    emptyCart = "Votre panier est vide",
    total = "Total",
    quantity = "Quantité",
    removeItem = "Retirer",
}

-- ============================================================================
-- OPEN / CLOSE
-- ============================================================================

function OpenShopUI(storeConfig, options)
    if shopOpen then return end
    if not storeConfig or not storeConfig.Items then return end

    options = options or {}
    shopOpen = true
    activeOrderContext = options.orderContext or nil

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    local locales = storeConfig.Locales or {}

    SendNUIMessage({
        action = 'shopui:open',
        data = {
            label = locales.mainTitle or "Boutique",
            tag = locales.mainTag or "",
            description = locales.mainDescription or "",
            categories = storeConfig.Categories or {},
            items = storeConfig.Items or {},
            locales = defaultLocales,
            hasRepair = options.hasRepair or false,
            brand = storeConfig.Brand or nil,
            orderMode = options.orderMode or false,
        }
    })

    -- Fetch player money
    ESX.TriggerServerCallback('null:shopui:getMoney', function(money)
        SendNUIMessage({
            action = 'shopui:setMoney',
            data = money
        })
    end)
end

function CloseShopUI()
    if not shopOpen then return end
    shopOpen = false
    activeOrderContext = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'shopui:close' })
end

exports('OpenShopUI', OpenShopUI)
exports('CloseShopUI', CloseShopUI)
exports('IsShopOpen', function() return shopOpen end)

-- ============================================================================
-- NUI CALLBACKS
-- ============================================================================

RegisterNUICallback('shopui:close', function(data, cb)
    CloseShopUI()
    cb('ok')
end)

-- ============================================================================
-- REPAIR NUI CALLBACKS
-- ============================================================================

RegisterNUICallback('shopui:getRepairData', function(data, cb)
    if not shopOpen then return cb('ok') end

    -- Get player loadout weapons with durability and repair prices
    local weapons = {}
    if ESX.PlayerData.loadout then
        for _, weapon in pairs(ESX.PlayerData.loadout) do
            local ammoType = ESX.GetAmmoType(weapon.name)
            local rawDurability = weapon.durability or 0
            local displayDurability = 100 - rawDurability
            local repairPrice = 0
            if Config.Repair and Config.Repair.Prices and ammoType then
                local maxPrice = Config.Repair.Prices[ammoType] or Config.Repair.defaultPrice or 120
                repairPrice = math.floor(maxPrice * (rawDurability / 100))
            end
            table.insert(weapons, {
                name = weapon.name,
                label = weapon.label or ESX.GetWeaponLabel(weapon.name) or weapon.name,
                durability = displayDurability,
                ammoType = ammoType or "pistol",
                repairPrice = repairPrice,
            })
        end
    end

    -- Get existing repairs from server
    ESX.TriggerServerCallback("Null:repairshop:get", function(repairs)
        local repairList = {}
        for weaponName, repairData in pairs(repairs) do
            table.insert(repairList, {
                name = weaponName,
                label = ESX.GetWeaponLabel(weaponName) or weaponName,
                pourcent = repairData.pourcent or 0,
                finish = repairData.finish or false,
            })
        end

        local isVip = false
        if GetVIP then isVip = GetVIP() or false end

        SendNUIMessage({
            action = 'shopui:repairData',
            data = {
                weapons = weapons,
                repairs = repairList,
                prices = Config.Repair and Config.Repair.Prices or {},
                timeToRepair = Config.Repair and Config.Repair.TimeToRepair or 120,
                timeToRepairVIP = Config.Repair and Config.Repair.TimeToRepairVIP or 40,
                isVip = isVip,
            }
        })
    end)

    cb('ok')
end)

RegisterNUICallback('shopui:repairWeapon', function(data, cb)
    if not shopOpen then return cb('ok') end
    if not data.weaponName then return cb('ok') end

    TriggerServerEvent("null:repair:weapon", data.weaponName, data.ammoType)

    -- Wait a bit then refresh repair data
    Citizen.SetTimeout(500, function()
        if shopOpen then
            -- Re-trigger getRepairData to refresh the UI
            SendNUIMessage({
                action = 'shopui:repairResult',
                data = { success = true, message = "Arme envoyée en réparation !" }
            })
        end
    end)

    cb('ok')
end)

RegisterNUICallback('shopui:repairPickup', function(data, cb)
    if not shopOpen then return cb('ok') end
    if not data.weaponName then return cb('ok') end

    TriggerServerEvent("null:repair:get", data.weaponName)

    Citizen.SetTimeout(500, function()
        if shopOpen then
            SendNUIMessage({
                action = 'shopui:repairPickupResult',
                data = { success = true, message = "Arme récupérée !" }
            })
        end
    end)

    cb('ok')
end)

RegisterNUICallback('shopui:buy', function(data, cb)
    if not shopOpen then return cb({ success = false }) end

    -- If opened in order mode → route to restaurant order placement instead
    if activeOrderContext and activeOrderContext.restaurantName then
        ESX.TriggerServerCallback('null:restaurant:placeOrder', function(success, result)
            if success then
                -- Refresh money
                ESX.TriggerServerCallback('null:shopui:getMoney', function(money)
                    SendNUIMessage({ action = 'shopui:setMoney', data = money })
                end)
                SendNUIMessage({ action = 'shopui:purchaseResult', data = { success = true, message = "Commande envoyée à la cuisine !" } })
            else
                SendNUIMessage({ action = 'shopui:purchaseResult', data = { success = false, message = result or "Erreur" } })
            end
            cb({ success = success })
        end, data.paymentType, data.cart, activeOrderContext.restaurantName)
        return
    end

    ESX.TriggerServerCallback('null:shopui:processTransaction', function(success, result)
        if success then
            SendNUIMessage({
                action = 'shopui:setMoney',
                data = result
            })
            SendNUIMessage({
                action = 'shopui:purchaseResult',
                data = { success = true }
            })
        else
            SendNUIMessage({
                action = 'shopui:purchaseResult',
                data = { success = false }
            })
        end
        cb({ success = success })
    end, data.paymentType, data.cart)
end)

-- ============================================================================
-- CLEANUP
-- ============================================================================

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if shopOpen then CloseShopUI() end
end)

AddEventHandler("gameEventTriggered", function(event, data)
    if event ~= "CEventNetworkEntityDamage" then return end
    local player, playerDead = data[1], data[4]
    if not IsPedAPlayer(player) then return end
    if playerDead and NetworkGetPlayerIndexFromPed(player) == PlayerId() and (IsPedDeadOrDying(player, true) or IsPedFatallyInjured(player)) then
        if shopOpen then CloseShopUI() end
    end
end)

null.InitPrint("ShopUI Client Module loaded")
