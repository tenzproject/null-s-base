RegisterNetEvent("null:esx:smellupdated", function(key, value)
    if ESX.PlayerData.smells == nil then ESX.PlayerData.smells = {} end
    ESX.PlayerData.smells[key] = value
end)