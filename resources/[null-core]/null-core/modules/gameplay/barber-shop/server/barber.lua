-- RegisterNetEvent('barbershop:checkmoney', function()
--     local xPlayer = ESX.GetPlayerFromId(source)
--     if xPlayer.getAccount('money').money >= 100 then
--         TriggerClientEvent("barber:change")
--         xPlayer.removeAccountMoney('money', 100)
--     else
--         TriggerClientEvent("AdvancedNotifiacation", source, "Fantasia Information", "Barber Shop", "Vous ne disposez pas des fonds nécéssaire: \nManquant: ~r~"..xPlayer.getAccount('money').money - 100.."", "CHAR_FANTASIA", 8)
--     end
-- end)

ESX.RegisterServerCallback("barber:getmoney", function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getAccount('cash').money >= 100 then 
        cb(true)
    else
        cb(false)
    end
end)

-- ============================================================================
-- Null:barber:purchase
--   Vérifie ET déduit le cash. Utilisé par le nouveau ped-shop barber/makeup
--   en remplacement de l'ancien `barber:getmoney` (qui ne faisait que checker).
--
--   Lit le prix depuis Config.Barber.Price ou Config.MakeupShop.Price selon
--   `mode` (param). Fallback à 100 si pas de config.
-- ============================================================================
ESX.RegisterServerCallback("Null:barber:purchase", function(source, cb, mode)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false); return end

    local price = 100
    if mode == "barber" and Config.Barber and Config.Barber.Price then
        price = Config.Barber.Price
    elseif mode == "makeup" and Config.MakeupShop and Config.MakeupShop.Price then
        price = Config.MakeupShop.Price
    end

    if xPlayer.getAccount('cash').money >= price then
        xPlayer.removeAccountMoney('cash', price)
        xPlayer.showNotification("Merci pour votre achat !")
        cb(true)
    else
        cb(false)
    end
end)