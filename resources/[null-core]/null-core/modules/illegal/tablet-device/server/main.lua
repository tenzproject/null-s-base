-- ============================================================================
-- ILLEGAL TABLET DEVICE - Usable item + DB ensure
-- ============================================================================

local function ensureItem()
    local def = Config.IllegalDevice and Config.IllegalDevice.Item
    if not def then return end
    MySQL.Async.execute(
        'INSERT IGNORE INTO `items` (`name`, `label`, `weight`) VALUES (@n, @l, @w)',
        { ['@n'] = def.name, ['@l'] = def.label, ['@w'] = def.weight or 0.5 }
    )
end

MySQL.ready(function()
    ensureItem()
end)

ESX.RegisterUsableItem(Config.IllegalDevice.Item.name, function(source)
    TriggerClientEvent('null:illegalDevice:open', source)
end)
