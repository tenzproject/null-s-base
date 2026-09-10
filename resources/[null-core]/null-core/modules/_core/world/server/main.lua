Config = Config or {}

-- CreateThread(LPH_NO_VIRTUALIZE(function()
--     if not Config._core.World.AutoCleanupWrecks then return end
--     while true do
--         Wait(Config._core.World.AutoCleanupInterval)
        
--         TriggerClientEvent('esx:showAdvancedNotification', -1, 
--             'CASSE AUTOMOBILE', 
--             'Informations', 
--             "La casse est de passage et va récupérer toutes les épaves dans 30 secondes !",
--             "CHAR_REDSIDE"
--         )
        
--         Wait(Config._core.World.CleanupWarningDelay)
        
--         TriggerClientEvent('null:world:clearBrokenVehicles', -1)
--     end
-- end))

ESX.RegisterCommand('clearwrecks', 'admin', function(xPlayer, args, showError)
    TriggerClientEvent('null:world:clearBrokenVehicles', -1)
    print('[null-core] ^3' .. xPlayer.getName() .. ' a déclenché un nettoyage des épaves^7')
end, false, {help = 'Nettoyer toutes les épaves de véhicules'})

null.InitPrint('^2World server module loaded^7')
