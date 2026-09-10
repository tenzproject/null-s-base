Config._core = Config._core or {}

Config._core.PlayerState = {
    -- Intervalle de mise à jour rapide (en véhicule)
    UpdateIntervalFast = 0,
    
    -- Intervalle de mise à jour normal
    UpdateIntervalNormal = 200,  -- Était 100, maintenant 200ms
    
    -- Intervalle de mise à jour lent
    UpdateIntervalSlow = 1000,
}