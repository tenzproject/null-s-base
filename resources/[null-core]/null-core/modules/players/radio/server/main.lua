-- ============================================================================
-- RADIO UI — Server-side
-- Registers radio as a usable item (item is NOT consumed on use)
-- ============================================================================

ESX.RegisterUsableItem('radio', function(source)
    TriggerClientEvent('null:radio:open', source)
end)
