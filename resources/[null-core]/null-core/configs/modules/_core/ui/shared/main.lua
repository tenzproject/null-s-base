Config = Config or {}

Config.UI = {
    -- Activer le système UI
    Enabled = true,
    
    -- Intervalle de mise à jour de la position joueur (pour sons 3D)
    PositionUpdateInterval = 100,
    
    -- Notifications
    Notifications = {
        -- Durée par défaut des notifications (ms)
        DefaultDuration = 5000,
        
        -- Nombre max de notifications affichées
        MaxNotifications = 5,
        
        -- Activer le son de notification
        SoundEnabled = true,
        
        -- Volume du son (0-1)
        SoundVolume = 0.1,
    },
    
    -- HUD
    HUD = {
        -- Opacité par défaut
        DefaultOpacity = 1.0,
        
        -- Masquer le HUD en véhicule
        HideInVehicle = false,
        
        -- Masquer le HUD en menu pause
        HideInPauseMenu = true,
    },
    
    -- Sons
    Sound = {
        -- Volume par défaut
        DefaultVolume = 1.0,
        
        -- Distance par défaut pour les sons 3D
        DefaultDistance = 50,
    },
}
