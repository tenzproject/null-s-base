RegisterNetEvent("christmasGift:open", function (id)
    local canAction = ActionCooldown('inventory_christmas_gift', 2000)
                
    if canAction == true then 
        TriggerServerEvent("inventory:openTarget", id, ESX.InventoryType.CHRISTMAS_GIFT)
    end
end)
