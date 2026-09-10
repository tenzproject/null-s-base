-- ============================================================================
-- BATTLE PASS CLIENT MODULE
-- ============================================================================

local BattlePassData = nil

-- XP gain notification from server
RegisterNetEvent('null:battlepass:xpGain', function(amount, newLevel, newXP, requiredXP)
    BattlePassData = BattlePassData or {}
    BattlePassData.level = newLevel
    BattlePassData.xp = newXP
    BattlePassData.requiredXP = requiredXP

    -- Send to NUI for live update
    SendNUIMessage({
        action = 'battlepass:xpGain',
        amount = amount,
        level = newLevel,
        xp = newXP,
        requiredXP = requiredXP,
    })
end)

-- Level up notification from server
RegisterNetEvent('null:battlepass:levelUp', function(newLevel)
    BattlePassData = BattlePassData or {}
    BattlePassData.level = newLevel

    SendNUIMessage({
        action = 'battlepass:levelUp',
        level = newLevel,
    })
end)

-- NUI Callback: get battle pass data
RegisterNUICallback('battlepass:getData', function(data, cb)
    ESX.TriggerServerCallback('null:battlepass:getData', function(result)
        if result then
            BattlePassData = result
        end
        cb(result or {})
    end)
end)

-- NUI Callback: claim reward
RegisterNUICallback('battlepass:claimReward', function(data, cb)
    ESX.TriggerServerCallback('null:battlepass:claimReward', function(success, msg, updatedClaims)
        cb({
            success = success,
            message = msg,
            claimedFree = updatedClaims and updatedClaims.claimedFree or nil,
            claimedPremium = updatedClaims and updatedClaims.claimedPremium or nil,
        })
    end, data.level, data.track)
end)

-- NUI Callback: buy a level with coins
RegisterNUICallback('battlepass:buyLevel', function(data, cb)
    ESX.TriggerServerCallback('null:battlepass:buyLevel', function(success, msg, updatedData)
        cb({
            success = success,
            message = msg,
            level = updatedData and updatedData.level or nil,
            xp = updatedData and updatedData.xp or nil,
            requiredXP = updatedData and updatedData.requiredXP or nil,
            coins = updatedData and updatedData.coins or nil,
        })
    end)
end)

-- NUI Callback: get VIP data
RegisterNUICallback('boutique:getVipData', function(data, cb)
    ESX.TriggerServerCallback('null:vip:getFullData', function(result)
        cb(result or {})
    end)
end)

-- NUI Callback: get VIP purchase info (prices, restrictions)
RegisterNUICallback('boutique:getVipPurchaseInfo', function(data, cb)
    ESX.TriggerServerCallback('null:boutique:getVipPurchaseInfo', function(result)
        cb(result or {})
    end)
end)

-- NUI Callback: buy VIP from boutique
RegisterNUICallback('boutique:buyVip', function(data, cb)
    if not data.tier then cb({ success = false }) return end
    TriggerServerEvent('null:boutique:buyVip', data.tier)
    cb({ success = true })
end)

null.InitPrint('^2Battle Pass module (client) loaded^7')
