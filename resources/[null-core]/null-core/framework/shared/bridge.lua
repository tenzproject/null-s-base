--[[
    Null Core - Bridge System
    Unifie l'API null et ESX pour une meilleure cohérence
]]

-- Bridge: null namespace pointe vers ESX pour compatibilité
null.core = ESX

-- Aliases pour les fonctions les plus utilisées
null.GetPlayer = function(source)
    if IsDuplicityVersion() then
        return ESX.GetPlayerFromId(source)
    else
        return ESX.PlayerData
    end
end

null.GetPlayers = function()
    if IsDuplicityVersion() then
        return ESX.GetPlayers()
    end
end

null.GetPlayerByIdentifier = function(identifier)
    if IsDuplicityVersion() then
        return ESX.GetPlayerFromIdentifier(identifier)
    end
end

-- Utilitaires communs 
null.Notify = function(source, message, title)
    if IsDuplicityVersion() then
        TriggerClientEvent('esx:showNotification', source, message, title)
    else
        ESX.ShowNotification(message, title)
    end
end

-- Raccourcis pour les callbacks
null.RegisterCallback = function(name, cb)
    if IsDuplicityVersion() then
        ESX.RegisterServerCallback(name, cb)
    end
end

null.TriggerCallback = function(name, cb, ...)
    if not IsDuplicityVersion() then
        ESX.TriggerServerCallback(name, cb, ...)
    end
end

-- Système d'events typés
null.Events = {
    _handlers = {},
    
    On = function(self, eventName, handler)
        if not self._handlers[eventName] then
            self._handlers[eventName] = {}
        end
        table.insert(self._handlers[eventName], handler)
        
        return #self._handlers[eventName] -- Retourne l'index pour pouvoir Off()
    end,
    
    Off = function(self, eventName, index)
        if self._handlers[eventName] and self._handlers[eventName][index] then
            table.remove(self._handlers[eventName], index)
        end
    end,
    
    Emit = function(self, eventName, ...)
        if self._handlers[eventName] then
            for _, handler in ipairs(self._handlers[eventName]) do
                handler(...)
            end
        end
    end
}

-- Exports pour les autres ressources
if IsDuplicityVersion() then
    exports('GetCore', function() return ESX end)
    exports('GetNull', function() return null end)
    exports('GetPlayer', null.GetPlayer)
    exports('GetPlayers', null.GetPlayers)
    exports('Notify', null.Notify)
else
    exports('GetCore', function() return ESX end)
    exports('GetNull', function() return null end)
    exports('Notify', null.Notify)
end
