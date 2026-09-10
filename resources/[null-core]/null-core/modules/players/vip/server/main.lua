local VipCache = {}

local function CalculateTimeRemaining(expiration)
    local remaining = ((expiration - os.time()) / 60) 
    local days = math.floor(remaining / 60 / 24)
    local hours = math.floor((remaining / 60) % 24)
    local minutes = math.ceil(remaining % 60)
    
    return {
        days = days,
        hours = hours,
        minutes = minutes,
        remaining = remaining
    }
end

local function FormatVipData(identifier)
    local cache = VipCache[identifier]
    if not cache or not cache.isVip then
        return nil
    end
    
    return {
        isVip = cache.isVip,
        type = cache.type,
        time = cache.time
    }
end

function SyncVipToClient(source, identifier)
    local data = FormatVipData(identifier)
    TriggerClientEvent('null:vip:sync', source, data)
    
    if data then
        TriggerClientEvent('null:updateVIP', source, data.isVip, data.type, {
            d = data.time.days,
            h = data.time.hours,
            m = data.time.minutes,
            tempsrestant = data.time.remaining
        })
        -- Apply VIP max weight
        pcall(function()
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                local vipWeight = exports["null-core"]:GetVIPMaxWeight(identifier)
                if vipWeight and vipWeight > Config.MaxWeight then
                    xPlayer.setMaxWeight(vipWeight)
                end
            end
        end)
    else
        TriggerClientEvent('null:updateVIP', source, false)
        -- Reset to default weight when VIP expires
        pcall(function()
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer and xPlayer.getMaxWeight() > Config.MaxWeight then
                xPlayer.setMaxWeight(Config.MaxWeight)
            end
        end)
    end
end

function LoadVipFromDatabase(identifier, callback)
    MySQL.Async.fetchAll("SELECT * FROM vips WHERE identifier = @identifier", {
        ['@identifier'] = identifier
    }, function(result)
        if result[1] and result[1].vip == 1 then
            local expiration = tonumber(result[1].expiration)
            if expiration <= os.time() then
                MySQL.Async.execute('UPDATE vips SET vip = 0 WHERE identifier = @identifier', {
                    ['@identifier'] = identifier
                })
                VipCache[identifier] = nil
                callback(nil, true) -- expired = true
            else
                local timeData = CalculateTimeRemaining(expiration)
                VipCache[identifier] = {
                    isVip = true,
                    type = result[1].type or "Basic",
                    time = timeData,
                    expiration = expiration
                }
                callback(VipCache[identifier], false)
            end
        else
            VipCache[identifier] = nil
            callback(nil, false)
        end
    end)
end

-- AddEventHandler('esx:playerLoaded', function(source, xPlayer)
--     LoadVipFromDatabase(xPlayer.identifier, function(vipData, expired)
--         if expired then
--             xPlayer.showNotification('~r~Information~s~\nVotre VIP a expiré.')
--         end

--         ESX.Players[xPlayer.source].vip = vipData

--         SyncVipToClient(source, xPlayer.identifier)
--     end)
-- end)

RegisterNetEvent('null:vip:request', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    if not VipCache[xPlayer.identifier] then
        LoadVipFromDatabase(xPlayer.identifier, function()
            SyncVipToClient(source, xPlayer.identifier)
        end)
    else
        SyncVipToClient(source, xPlayer.identifier)
    end
end)

RegisterNetEvent('mercuryRP:GetVIP', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    if not VipCache[xPlayer.identifier] then
        LoadVipFromDatabase(xPlayer.identifier, function()
            SyncVipToClient(source, xPlayer.identifier)
        end)
    else
        SyncVipToClient(source, xPlayer.identifier)
    end
end)

RegisterCommand('addVIP', function(source, args)
    if source ~= 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.getGroup() ~= 'admin' then
            return
        end
    end
    
    local targetId = tonumber(args[1])
    local vipType = args[2] or "Basic"
    local days = tonumber(args[3]) or 31
    
    if not targetId then
        print('[VIP] Usage: addVIP <id> [type] [jours]')
        return
    end
    
    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        print('[VIP] Joueur non trouvé')
        return
    end
    
    local identifier = target.identifier
    local expirationAdd = days * 86400
    
    MySQL.Async.fetchAll("SELECT * FROM vips WHERE identifier = @identifier", {
        ['@identifier'] = identifier
    }, function(result)
        local newExpiration
        
        if result[1] and result[1].vip == 1 and tonumber(result[1].expiration) > os.time() then
            newExpiration = tonumber(result[1].expiration) + expirationAdd
            MySQL.Async.execute('UPDATE vips SET expiration = @expiration, type = @type, vip = 1 WHERE identifier = @identifier', {
                ['@identifier'] = identifier,
                ['@expiration'] = newExpiration,
                ['@type'] = vipType
            })
        else
            newExpiration = os.time() + expirationAdd
            
            if result[1] then
                MySQL.Async.execute('UPDATE vips SET expiration = @expiration, type = @type, vip = 1 WHERE identifier = @identifier', {
                    ['@identifier'] = identifier,
                    ['@expiration'] = newExpiration,
                    ['@type'] = vipType
                })
            else
                MySQL.Async.execute('INSERT INTO vips (identifier, vip, expiration, type) VALUES (@identifier, 1, @expiration, @type)', {
                    ['@identifier'] = identifier,
                    ['@expiration'] = newExpiration,
                    ['@type'] = vipType
                })
            end
        end
        
        local timeData = CalculateTimeRemaining(newExpiration)
        VipCache[identifier] = {
            isVip = true,
            type = vipType,
            time = timeData,
            expiration = newExpiration
        }
        
        target.showNotification(('~g~VIP %s~s~ activé!\nExpire dans ~b~%d~s~ jours et ~b~%d~s~ heures.'):format(
            vipType, timeData.days, timeData.hours
        ))
        
        SyncVipToClient(target.source, identifier)
        
        print(('[VIP] VIP %s ajouté à %s pour %d jours'):format(vipType, target.getName(), days))
    end)
end, false)

RegisterCommand('removeVIP', function(source, args)
    if source ~= 0 then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer or xPlayer.getGroup() ~= 'admin' then
            return
        end
    end
    
    local targetId = tonumber(args[1])
    if not targetId then
        print('[VIP] Usage: removeVIP <id>')
        return
    end
    
    local target = ESX.GetPlayerFromId(targetId)
    if not target then
        print('[VIP] Joueur non trouvé')
        return
    end
    
    local identifier = target.identifier
    
    MySQL.Async.execute('UPDATE vips SET vip = 0 WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    })
    
    VipCache[identifier] = nil
    
    target.showNotification('~r~Votre VIP a été retiré.')
    SyncVipToClient(target.source, identifier)
    
    print(('[VIP] VIP retiré de %s'):format(target.getName()))
end, false)

function GetVIP(identifier)
    local cache = VipCache[identifier]
    if cache and cache.isVip then
        return true, cache.type, cache.time
    end
    return false, nil, nil
end

function HasVIPAccess(identifier, requiredType)
    local isVip, vipType = GetVIP(identifier)
    if not isVip then return false end
    
    local hierarchy = {
        ["Basic"] = 1,
        ["Premium"] = 2,
    }
    
    local playerLevel = hierarchy[vipType] or 0
    local requiredLevel = hierarchy[requiredType] or 0
    
    return playerLevel >= requiredLevel
end

exports('GetVIP', GetVIP)
exports('HasVIPAccess', HasVIPAccess)

ESX.RegisterServerCallback('null:vip:check', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end
    
    local isVip, vipType, timeData = GetVIP(xPlayer.identifier)
    cb(isVip, vipType, timeData)
end)

null.InitPrint('^2VIP module loaded^7')
