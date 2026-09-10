-- @dashboardLabel: Protection serveur
-- @dashboardDescription: Protège le serveur contre les spams d'événements et attaques réseau.
-- @dashboardGroup: Protection
Config.Protection = {
    Events = {
        -- @dashboardLabel: Anti-spam d'events
        -- @dashboardDescription: Limite le nombre d'events réseau qu'un joueur peut envoyer par seconde. Au-delà, les events sont ignorés et le joueur peut être kick.
        -- @dashboardGroup: Protection
        AntiSpam = {
            -- @dashboardLabel: Activer l'anti-spam d'events
            -- @dashboardGroup: Protection
            -- @dashboardWidget: boolean
            Enable = true,
            -- @dashboardLabel: Max events par seconde
            -- @dashboardDescription: Seuil d'events par seconde par joueur avant déclenchement de l'anti-spam. 50 est raisonnable, augmentez si de faux positifs apparaissent.
            -- @dashboardGroup: Protection
            -- @dashboardWidget: number
            -- @dashboardMin: 10
            -- @dashboardMax: 500
            MaxEventsPerSecond = 50
        }
    }
}