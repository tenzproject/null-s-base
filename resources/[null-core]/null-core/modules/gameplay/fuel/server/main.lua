RegisterServerEvent('null:fuel:pay')
AddEventHandler('null:fuel:pay', function(price)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    local amount = ESX.Math.Round(price)
    if amount > 0 then
        xPlayer.removeMoney(amount)
    end
end)
