-- ============================================================================
-- ILLEGAL TABLET DEVICE - Marché noir bridge (reuses null:tablet:* backend)
-- ============================================================================

RegisterNUICallback('illegalDevice:market:getData', function(_, cb)
    ESX.TriggerServerCallback('null:tablet:getData', function(result)
        cb(result or {})
    end)
end)

RegisterNUICallback('illegalDevice:market:buyWeapon', function(data, cb)
    TriggerServerEvent('null:tablet:buyWeapon', data.weaponId, data.quantity or 1)
    Wait(500)
    ESX.TriggerServerCallback('null:tablet:getData', function(result)
        cb(result or {})
    end)
end)

RegisterNUICallback('illegalDevice:market:buyItem', function(data, cb)
    TriggerServerEvent('null:tablet:buyItem', data.itemId, data.quantity or 1)
    Wait(500)
    ESX.TriggerServerCallback('null:tablet:getData', function(result)
        cb(result or {})
    end)
end)
