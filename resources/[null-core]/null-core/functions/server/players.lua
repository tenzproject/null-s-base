--[[
    Extrait les identifiants d'un joueur
    @param source number - ID du joueur
    @return table - Identifiants
]]
function null.fct.getIdentifiers(source)
    local identifiers = {
        fivem = nil,
        steam = nil,
        discord = nil,
        license = nil,
        ip = nil,
        xbl = nil,
        live = nil
    }
    
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id then
            if string.find(id, "steam:") then
                identifiers.steam = id
            elseif string.find(id, "discord:") then
                identifiers.discord = id:gsub("discord:", "")
            elseif string.find(id, "license:") then
                identifiers.license = id
            elseif string.find(id, "fivem:") then
                identifiers.fivem = id
            elseif string.find(id, "ip:") then
                identifiers.ip = id
            elseif string.find(id, "xbl:") then
                identifiers.xbl = id
            elseif string.find(id, "live:") then
                identifiers.live = id
            end
        end
    end
    
    return identifiers
end

function null.fct.BoostAndVip(identifier, source) 
    local sellBoostPct = 0
    pcall(function()
        sellBoostPct = exports["null-core"]:GetVIPSellBoost(identifier) or 0
    end)
    if sellBoostPct > 0 then
        return 1, nil, nil, { sell = 1 + (sellBoostPct / 100) }
    end
    return 0
end 

exports("HowManyBoostVip", null.fct.BoostAndVip)