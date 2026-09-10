

local ZoneInfoNorth = Config.BlackMarket.NorthZones[math.random(1,5)]
local ZoneInfoSud = Config.BlackMarket.SouthZones[math.random(1,5)]

Citizen.CreateThread(function()
    while not FinishPrintCore do Wait(10) end
    Wait(3000)
    print("[^4Null^7] Position BlackMarket Nord : "..ZoneInfoNorth.x.." "..ZoneInfoNorth.y.." "..ZoneInfoNorth.z.."")
    print("[^4Null^7] Position BlackMarket Sud : "..ZoneInfoSud.x.." "..ZoneInfoSud.y.." "..ZoneInfoSud.z.."")
end)

RegisterNetEvent('illegalshop:GetPoints', function()
    TriggerClientEvent('illegalshop:ReceivePoints', source, ZoneInfoNorth, ZoneInfoSud)
end)

RegisterNetEvent('IllegalShop:buyItem', function(item)
    local Objects = nil
    for k,v in pairs(Config.BlackMarket.Objects) do
        if v.name == item then
            Objects = v
        end
    end
    if Objects == nil then return end
    local xPlayer = ESX.GetPlayerFromId(source)
    if Objects.type == 'item' then
        if xPlayer.canCarryItem(item, 1) then
            if xPlayer.getAccount('cash').money >= Objects.price then
                xPlayer.removeAccountMoney('cash', Objects.price)
                xPlayer.addInventoryItem(item, 1)
                xPlayer.showNotification('Vous avez acheté '..Objects.label.. ' pour '.. Objects.price.. '$')
            else
                xPlayer.showNotification('Vous n\'avez pas l\'argent nécéssaire')
            end
        else
            xPlayer.showNotification('Vous avez trop d\'objets sur vous.')
        end
    elseif Objects.type == 'weapon' then 
        if xPlayer.getAccount('cash').money >= Objects.price then
            xPlayer.removeAccountMoney('cash', Objects.price)
            xPlayer.addWeapon(item, 250)
            xPlayer.showNotification('Vous avez acheté '..Objects.label.. ' pour '.. Objects.price.. '$')
        else
            xPlayer.showNotification('Vous n\'avez pas l\'argent nécéssaire')
        end
    end
end)