-- ============================================================================
-- ILLEGAL TABLET DEVICE - Territories (map polygons + owner color)
-- ============================================================================

local function readNum(t, k1, k2)
    if t == nil then return 0 end
    local v = t[k1]
    if v ~= nil then return v end
    if k2 ~= nil then v = t[k2]; if v ~= nil then return v end end
    return 0
end

ESX.RegisterServerCallback('null:illegalDevice:territories:get', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local gangname = xPlayer.getJob2().name
    local out = {}

    local territoriesData = (SaveData and SaveData.json and SaveData.json["territories"]) or {}
    for _, t in pairs(territoriesData) do
        if t and t.active ~= false then
            local owner = t.owner
            local color
            if owner and SaveData.gangs and SaveData.gangs[owner] then
                color = SaveData.gangs[owner].gangcolor
            end

            local pts = {}
            if t.points then
                for _, p in ipairs(t.points) do
                    pts[#pts + 1] = { x = readNum(p, 'x', 1), y = readNum(p, 'y', 2) }
                end
            end

            local terrPts = {}
            if t.territoryPoints then
                for _, p in ipairs(t.territoryPoints) do
                    terrPts[#terrPts + 1] = { x = readNum(p, 'x', 1), y = readNum(p, 'y', 2) }
                end
            end

            local pos = t.position
            local posOut = nil
            if pos then
                posOut = { x = readNum(pos, 'x', 1), y = readNum(pos, 'y', 2) }
            end

            local myPoints = 0
            if t.data and t.data[gangname] and t.data[gangname].count then
                myPoints = t.data[gangname].count
            end

            out[#out + 1] = {
                id = t.id,
                name = t.name,
                points = pts,
                territoryPoints = terrPts,
                position = posOut,
                owner = owner,
                ownerLabel = t.ownerLabel,
                ownerCount = t.ownerCount or 0,
                color = color or '#9aa0a6',
                isOwned = (owner == gangname),
                myPoints = myPoints,
            }
        end
    end

    cb({ territories = out, gangname = gangname })
end)
