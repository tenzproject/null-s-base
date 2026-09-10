-- ============================================================================
-- SHOWCASE — serveur : self-service (setgroup / wipe / register) + setup.
-- Tout est gardé par Showcase.IsEnabled().
-- ============================================================================

if not Showcase.IsEnabled() then return end

local cfg = Config.Showcase or {}

local function availableGroups()
    if cfg.groups and #cfg.groups > 0 then return cfg.groups end
    local keys = {}
    if Config.GroupeGrade then
        for k in pairs(Config.GroupeGrade) do keys[#keys + 1] = k end
    end
    return keys
end

-- Données pour la tablette + l'écran de bienvenue.
ESX.RegisterServerCallback('null:showcase:getData', function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    cb({
        version = cfg.version or "?",
        lastUpdate = cfg.lastUpdate or "?",
        groups = availableGroups(),
        currentGroup = xPlayer and xPlayer.getGroup() or 'user',
        serverName = GetConvar('serverName', 'Null'),
    })
end)

-- Setgroup SOI-MÊME uniquement.
RegisterNetEvent('null:showcase:setGroup', function(group)
    if not Showcase.IsEnabled() then return end
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    group = tostring(group or '')
    if not Config.GroupeGrade or Config.GroupeGrade[string.lower(group)] == nil then
        return TriggerClientEvent('esx:showNotification', src, "~r~Groupe invalide.")
    end

    MySQL.Async.execute("UPDATE `users` SET `permission_group` = @group WHERE `identifier` = @identifier", {
        ['@group'] = group,
        ['@identifier'] = xPlayer.identifier,
    })
    xPlayer.setGroup(group)
    TriggerClientEvent("null:staff:recevieRequestGroup", src, { true, xPlayer.getGroup() })
    TriggerClientEvent("AdminMenu:reciviestaffrole", src, group)
    TriggerClientEvent("esx:showNotification", src, "~g~Groupe défini : ~s~" .. group)
end)

-- Wipe SOI-MÊME uniquement.
RegisterNetEvent('null:showcase:wipe', function()
    if not Showcase.IsEnabled() then return end
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    if WipeTable then WipeTable(xPlayer.identifier) end
    DropPlayer(src, "Showcase : votre personnage a été wipe. Reconnectez-vous.")
end)

-- Register SOI-MÊME uniquement (réouvre le créateur).
RegisterNetEvent('null:showcase:register', function()
    if not Showcase.IsEnabled() then return end
    local src = source
    TriggerClientEvent('null:newCreator:open', src, true)
end)

-- Auto-setup : à la connexion d'un showcaser, on lui donne le groupe admin par
-- défaut (zéro friction) s'il est encore 'user'.
AddEventHandler('esx:playerLoaded', function(playerId)
    if not Showcase.IsEnabled() then return end
    if not cfg.autoGroup then return end
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end
    if xPlayer.getGroup() == 'user' then
        MySQL.Async.execute("UPDATE `users` SET `permission_group` = @group WHERE `identifier` = @identifier", {
            ['@group'] = cfg.autoGroup,
            ['@identifier'] = xPlayer.identifier,
        })
        xPlayer.setGroup(cfg.autoGroup)
        TriggerClientEvent("null:staff:recevieRequestGroup", xPlayer.source, { true, xPlayer.getGroup() })
        TriggerClientEvent("AdminMenu:reciviestaffrole", xPlayer.source, cfg.autoGroup)
    end
end)
