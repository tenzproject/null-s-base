-- ============================================================================
-- PAWN SHOP - Client Side
-- NUI bridge for React PawnShop UI
-- ============================================================================

local isPawnShopOpen = false

-- ============================================================================
-- Open PawnShop UI
-- ============================================================================
function OpenPawnShop()
    if isPawnShopOpen then return end

    ESX.TriggerServerCallback('null:pawnshop:getData', function(data)
        if not data then
            ESX.ShowNotification("Erreur lors de l'ouverture du marche")
            return
        end

        isPawnShopOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'pawnshop:open', data = data })
    end)
end

local function ClosePawnShop()
    if not isPawnShopOpen then return end
    isPawnShopOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'pawnshop:close' })
end

-- ============================================================================
-- Server refresh event
-- ============================================================================
RegisterNetEvent("null:pawnshop:update")
AddEventHandler("null:pawnshop:update", function(data)
    if isPawnShopOpen and data then
        SendNUIMessage({ action = 'pawnshop:update', data = data })
    end
end)

-- Server result events -> forward to NUI
for _, eventName in ipairs({ "buyResult", "sellResult", "cancelResult", "collectResult" }) do
    RegisterNetEvent("null:pawnshop:" .. eventName)
    AddEventHandler("null:pawnshop:" .. eventName, function(result)
        SendNUIMessage({ action = "pawnshop:" .. eventName, data = result })
    end)
end

-- ============================================================================
-- NUI Callbacks
-- ============================================================================
RegisterNUICallback("pawnshop:close", function(_, cb)
    ClosePawnShop()
    cb("ok")
end)

RegisterNUICallback("pawnshop:buy", function(data, cb)
    TriggerServerEvent("null:pawnshop:buy", data.listingId, data.quantity, data.paymentType, data.isNpc)
    cb("ok")
end)

RegisterNUICallback("pawnshop:sell", function(data, cb)
    TriggerServerEvent("null:pawnshop:sell", data.itemName, data.itemLabel, data.count, data.pricePerUnit)
    cb("ok")
end)

RegisterNUICallback("pawnshop:cancel", function(data, cb)
    TriggerServerEvent("null:pawnshop:cancel", data.listingId)
    cb("ok")
end)

RegisterNUICallback("pawnshop:collectAll", function(_, cb)
    TriggerServerEvent("null:pawnshop:collectAll")
    cb("ok")
end)