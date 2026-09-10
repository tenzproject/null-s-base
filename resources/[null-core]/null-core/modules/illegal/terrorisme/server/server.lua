local inExplose = {}

ESX.RegisterUsableItem("ceinture_explosive", function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    inExplose[xPlayer.getIdunique()] = os.time()
    TriggerClientEvent("null:terro:useCeinture", source)    
end)

RegisterNetEvent("null:removeCeintureExplosive", function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if inExplose[xPlayer.getIdunique()] == nil then return end

    xPlayer.removeInventoryItem("ceinture_explosive", 1)
end)