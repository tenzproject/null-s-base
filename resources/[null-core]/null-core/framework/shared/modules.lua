--[[
    Null Core - Module System
    Permet aux modules externes de s'enregistrer et d'interagir avec le core
]]

ESX.Modules = {}
ESX.ModulesLoaded = {}

-- Enregistrer un nouveau module
function ESX.RegisterModule(name, module)
    if type(name) ~= 'string' then
        return print(('[^1ERROR^7] ESX.RegisterModule: name must be a string, got %s'):format(type(name)))
    end
    
    if ESX.Modules[name] then
        return print(('[^3WARNING^7] Module "%s" is already registered, skipping'):format(name))
    end
    
    ESX.Modules[name] = module
    ESX.ModulesLoaded[name] = true
    
    -- Appeler onLoad si défini
    if module.onLoad and type(module.onLoad) == 'function' then
        module.onLoad()
    end
    
    print(('[^2Null^7] Module "^4%s^7" registered successfully'):format(name))
    TriggerEvent('esx:moduleLoaded', name, module)
    
    return true
end

-- Récupérer un module
function ESX.GetModule(name)
    return ESX.Modules[name]
end

-- Vérifier si un module est chargé
function ESX.IsModuleLoaded(name)
    return ESX.ModulesLoaded[name] == true
end

-- Attendre qu'un module soit chargé
function ESX.AwaitModule(name, timeout)
    timeout = timeout or 10000
    local waited = 0
    
    while not ESX.IsModuleLoaded(name) and waited < timeout do
        Wait(100)
        waited = waited + 100
    end
    
    return ESX.GetModule(name)
end

-- Lister tous les modules
function ESX.GetModules()
    return ESX.Modules
end

-- Décharger un module (pour hot-reload)
function ESX.UnloadModule(name)
    if not ESX.Modules[name] then return false end
    
    local module = ESX.Modules[name]
    
    -- Appeler onUnload si défini
    if module.onUnload and type(module.onUnload) == 'function' then
        module.onUnload()
    end
    
    ESX.Modules[name] = nil
    ESX.ModulesLoaded[name] = nil
    
    TriggerEvent('esx:moduleUnloaded', name)
    print(('[^2Null^7] Module "^4%s^7" unloaded'):format(name))
    
    return true
end

--[[
    Exemple d'utilisation pour un module job:
    
    ESX.RegisterModule('jobs:police', {
        name = 'Police',
        version = '1.0.0',
        
        onLoad = function()
            -- Initialisation du module
        end,
        
        onUnload = function()
            -- Nettoyage
        end,
        
        -- API publique du module
        getOnDutyOfficers = function()
            return ESX.GetJobPlayers('police')
        end,
        
        dispatchCall = function(coords, message)
            -- Logic
        end
    })
    
    -- Utilisation depuis un autre script:
    local policeModule = ESX.GetModule('jobs:police')
    if policeModule then
        policeModule.dispatchCall(coords, "Vol en cours")
    end
]]
