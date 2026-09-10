-- ============================================================
--  Config.CarWash
--  Système de stations de lavage automatique pour véhicules.
--  Chaque station peut être :
--   - simple (progress bar + particules)
--   - "Tunnel" (animation rouleaux + jets, style usine GTA Vinewood)
-- ============================================================
Config.CarWash = {
    -- Réglages globaux
    Settings = {
        Cooldown        = 30,        -- secondes entre deux lavages par joueur
        DirtThreshold   = 1.0,       -- saleté minimale (0..15) pour autoriser le lavage
        WashAccount     = "bank",    -- "bank" ou "money" (espèces)
        AllowPremium    = true,      -- activer la formule Premium
    },

    -- Formules disponibles (les clés sont utilisées par le serveur)
    Tiers = {
        basic = {
            Label       = "Lavage Standard",
            Description = "Nettoyage rapide à la brosse — élimine la saleté.",
            Price       = 50,
            Duration    = 8000,      -- durée en ms (uniquement hors Tunnel)
            FinalDirt   = 0.5,
            CleanDecals = false,
        },
        premium = {
            Label       = "Lavage Premium",
            Description = "Haute pression + rouleaux + lustrage. Efface graffitis et tags.",
            Price       = 150,
            Duration    = 14000,
            FinalDirt   = 0.0,
            CleanDecals = true,
        },
    },

    -- Liste des stations
    List = {
        -- Vinewood — station "tunnel" (animation rouleaux complète)
        {
            Label    = "Hands On Car Wash",
            Position = vector3(-699.78, -929.94, 18.21),
            Tunnel = {
                EntryPos     = vec3(-699.9, -922.75, 17.84),
                Heading      = 180.0,
                IplDefault   = "kt_carwash",
                IplActive    = "kt_carwash_nobrush",
                Waypoint     = "carwash2_r",
                Speed        = 1.5,
                Center       = vec3(-699.97, -935.0,  17.9),
                FirstSpray   = vec3(-699.97, -927.7,  20.8279),
                LastSpray    = vec3(-699.97, -938.8,  20.8279),
                Roller       = vec3(-699.97, -931.7,  21.3),
                RollerWidth  = 3.6,
            },
        },

        -- Strawberry — station classique self-service (sans tunnel)
        {
            Label    = "Five Star Car Wash",
            Position = vector3(20.7689, -1391.8958, 29.3265),
        },

        -- La Mesa — station classique self-service
        {
            Label    = "La Mesa Auto Wash",
            Position = vector3(167.06, -1718.64, 29.29),
        },
    },
}
