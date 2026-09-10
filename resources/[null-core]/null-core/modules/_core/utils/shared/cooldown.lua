local Cooldowns = {}

function ActionCooldown(name, interval, showNotif)
    if showNotif == nil then showNotif = true end
    
    local action = Cooldowns[name]
    local now = GetGameTimer()
    
    if action == nil then
        Cooldowns[name] = {
            cooldown = now,
            interval = interval
        }
        return true
    end
    
    if now - action.cooldown < action.interval then
        if showNotif and IsDuplicityVersion() == false then
            if ESX and ESX.ShowNotification then
                local remaining = math.ceil((action.interval - (now - action.cooldown)) / 1000)
                ESX.ShowNotification('Veuillez patienter ' .. remaining .. ' seconde(s)')
            end
        end
        return false
    end
    
    action.cooldown = now
    action.interval = interval 
    return true
end

function ResetCooldown(name)
    Cooldowns[name] = nil
end

function GetCooldownRemaining(name)
    local action = Cooldowns[name]
    if not action then return nil end
    
    local now = GetGameTimer()
    local remaining = action.interval - (now - action.cooldown)
    
    return remaining > 0 and remaining or 0
end

function IsOnCooldown(name)
    local remaining = GetCooldownRemaining(name)
    return remaining ~= nil and remaining > 0
end

exports('ActionCooldown', ActionCooldown)
exports('ResetCooldown', ResetCooldown)
exports('GetCooldownRemaining', GetCooldownRemaining)
exports('IsOnCooldown', IsOnCooldown)

exports('actionCooldown', ActionCooldown)
