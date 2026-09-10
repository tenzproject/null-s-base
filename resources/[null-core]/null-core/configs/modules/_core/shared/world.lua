Config._core = Config._core or {}

Config._core.World = {
    -- Désactiver les PNJ du jeu
    DisableNPC = true,
    
    -- Désactiver la police GTA (étoiles, dispatch)
    DisablePolice = true,
    
    -- Intervalle de nettoyage mémoire (ms)
    CleanupInterval = 300000, -- 5 minutes
    
    -- Intervalle de clear police (ms)
    ClearPoliceInterval = 5000,
    
    -- Nettoyage auto des épaves (serveur)
    AutoCleanupWrecks = true,
    AutoCleanupInterval = 600000, -- 10 minutes
    CleanupWarningDelay = 30 * 1000 -- 30 secondes
}