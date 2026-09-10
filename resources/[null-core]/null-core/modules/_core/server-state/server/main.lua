RegisterNetEvent('null:world:getServerInfo', function()
    local src = source
    
    TriggerClientEvent('null:world:serverInfo', src, {
        day = tonumber(os.date("%d")),
        month = tonumber(os.date("%m")),
        year = tonumber(os.date("%Y")),
        maxplayers = GetConvarInt("sv_maxclients", 32),
        --hour = tonumber(os.date("%H")),
        --minute = tonumber(os.date("%M")),
        --dayName = os.date("%A"),
        --monthName = os.date("%B"),
        --timestamp = os.time()
    })
end)