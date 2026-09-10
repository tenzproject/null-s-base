CreateThread(function()
    while not ESX or not ESX.PlayerLoaded do 
        Wait(100) 
    end
    
    TriggerServerEvent('null:vip:request')
end)

RegisterNetEvent('null:vip:sync', function(data)
    if not data then
        PlayerState.vip.isVip = false
        PlayerState.vip.type = nil
        PlayerState.vip.time = { days = 0, hours = 0, minutes = 0, remaining = 0 }
        PlayerState.vip.loaded = true
        return
    end
    
    PlayerState.vip.isVip = data.isVip or false
    PlayerState.vip.type = data.type
    PlayerState.vip.time = data.time or { days = 0, hours = 0, minutes = 0, remaining = 0 }
    PlayerState.vip.loaded = true
    
    TriggerEvent('null:vip:updated', PlayerState.vip)
end)

function GetVIP()
    return PlayerState.vip.isVip, PlayerState.vip.type, PlayerState.vip.time
end

function GetVIPTable()
    return PlayerState.vip
end

function GetVIPLoad()
    return PlayerState.vip.loaded
end

function HasVIPAccess(requiredType)
    if not PlayerState.vip.isVip then return false end
    
    local hierarchy = {
        ["Basic"] = 1,
        ["Premium"] = 2,
    }
    
    local playerLevel = hierarchy[PlayerState.vip.type] or 0
    local requiredLevel = hierarchy[requiredType] or 0
    
    return playerLevel >= requiredLevel
end

exports("GetVIP", GetVIP)
exports("GetVIPTable", GetVIPTable)
exports("GetVIPLoad", GetVIPLoad)
exports("HasVIPAccess", HasVIPAccess)

RegisterNetEvent('null:updateVIP')
AddEventHandler('null:updateVIP', function(vip, viptype, viptime)
    PlayerState.vip.isVip = vip or false
    PlayerState.vip.type = viptype
    if viptime then
        PlayerState.vip.time = {
            days = viptime.d or 0,
            hours = viptime.h or 0,
            minutes = viptime.m or 0,
            remaining = viptime.tempsrestant or 0
        }
    end
    PlayerState.vip.loaded = true
    
    TriggerEvent('null:vip:updated', PlayerState.vip)
end)

null.InitPrint('^2VIP module (client) loaded^7')
