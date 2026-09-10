-- ============================================================================
-- ILLEGAL TABLET DEVICE - Solo GoFast (server)
-- ============================================================================

local SoloGF = {}
local activeMissions = {}   -- [src] = mission
local cooldowns = {}        -- [identifier] = expiresAtEpoch

local function rand(min, max) return min + math.random() * (max - min) end

local function pickPickup()
    local list = Config.IllegalDevice.GoFast.Pickups
    return list[math.random(1, #list)]
end

local function pickDelivery(pickup, target)
    local best, bestDiff = nil, math.huge
    for _, d in ipairs(Config.IllegalDevice.GoFast.Deliveries) do
        local dist = #(vector3(pickup.x, pickup.y, pickup.z) - vector3(d.x, d.y, d.z))
        local diff = math.abs(dist - target)
        if diff < bestDiff then
            bestDiff = diff
            best = d
        end
    end
    return best
end

local function newPlate(prefix)
    return string.format('%s%03d%s', prefix or 'GF', math.random(0, 999), string.char(math.random(65, 90), math.random(65, 90)))
end

RegisterNetEvent('null:illegalDevice:gofast:request')
AddEventHandler('null:illegalDevice:gofast:request', function(difficultyId)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local cfg = Config.IllegalDevice.GoFast
    local diff = cfg.Difficulties[difficultyId]
    if not diff then
        TriggerClientEvent('null:illegalDevice:gofast:response', src, { error = 'INVALID' })
        return
    end

    if activeMissions[src] then
        TriggerClientEvent('null:illegalDevice:gofast:response', src, { error = 'ALREADY_ACTIVE' })
        return
    end

    local ident = xPlayer.identifier
    local now = os.time()
    if cooldowns[ident] and cooldowns[ident] > now then
        TriggerClientEvent('null:illegalDevice:gofast:response', src, {
            error = 'COOLDOWN',
            remaining = cooldowns[ident] - now,
        })
        return
    end

    local pickup = pickPickup()
    local delivery = pickDelivery(pickup, diff.targetDistance)
    if not delivery then
        TriggerClientEvent('null:illegalDevice:gofast:response', src, { error = 'NO_ROUTE' })
        return
    end

    local mission = {
        id = ('SOLO_%d_%d'):format(src, now),
        difficulty = diff.id,
        difficultyLabel = diff.label,
        vehicle = diff.vehicles[math.random(1, #diff.vehicles)],
        plate = newPlate('GO'),
        pickup = { x = pickup.x, y = pickup.y, z = pickup.z, w = pickup.w },
        delivery = { x = delivery.x, y = delivery.y, z = delivery.z, w = delivery.w },
        cargo = { item = diff.cargoItem, label = diff.cargoLabel, count = math.random(diff.cargoMin, diff.cargoMax) },
        payment = math.floor(rand(diff.payment[1], diff.payment[2])),
        pedModel = cfg.PedModels[math.random(1, #cfg.PedModels)],
        returnVehicle = cfg.ReturnVehicle,
        startedAt = now,
    }
    activeMissions[src] = mission
    TriggerClientEvent('null:illegalDevice:gofast:response', src, { success = true, mission = mission })
end)

RegisterNetEvent('null:illegalDevice:gofast:complete')
AddEventHandler('null:illegalDevice:gofast:complete', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local mission = activeMissions[src]
    if not mission then return end

    xPlayer.addAccountMoney('dirtycash', mission.payment)
    cooldowns[xPlayer.identifier] = os.time() + (Config.IllegalDevice.GoFast.Cooldown or 600)
    activeMissions[src] = nil

    TriggerClientEvent('null:illegalDevice:gofast:result', src, {
        success = true,
        payment = mission.payment,
    })
end)

RegisterNetEvent('null:illegalDevice:gofast:fail')
AddEventHandler('null:illegalDevice:gofast:fail', function(reason)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if not activeMissions[src] then return end
    cooldowns[xPlayer.identifier] = os.time() + math.floor((Config.IllegalDevice.GoFast.Cooldown or 600) / 2)
    activeMissions[src] = nil
    TriggerClientEvent('null:illegalDevice:gofast:result', src, { success = false, reason = reason })
end)

ESX.RegisterServerCallback('null:illegalDevice:gofast:status', function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then cb({}) return end
    local now = os.time()
    local remaining = 0
    local cd = cooldowns[xPlayer.identifier]
    if cd and cd > now then remaining = cd - now end
    cb({
        active = activeMissions[src] ~= nil,
        cooldown = remaining,
        mission = activeMissions[src],
    })
end)

AddEventHandler('playerDropped', function()
    local src = source
    if activeMissions[src] then activeMissions[src] = nil end
end)
