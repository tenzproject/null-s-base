RegisterNetEvent('FidelCoins:BuyVIP')
AddEventHandler('FidelCoins:BuyVIP', function()
    local xPlayer = ESX.GetPlayerFromId(source)

    if (xPlayer) then 
        if xPlayer.getAccount('fidelcoins').money >= 2500 then 
            xPlayer.removeAccountMoney('fidelcoins', 2500)
            ExecuteCommand('addVIP '..xPlayer.source.." Basic 31")
        else
            xPlayer.showNotification("Vous n'avez pas assez de points de fidélité")
        end
    end
end)