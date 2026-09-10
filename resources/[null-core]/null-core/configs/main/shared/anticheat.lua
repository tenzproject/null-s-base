-- =============================================================================
-- Anticheat — protection du serveur contre les tricheurs
-- =============================================================================

-- @dashboardLabel: Systèmes d'anticheat
-- @dashboardDescription: Sélection des anticheats actifs. "others" est l'anticheat intégré Null, cumulable avec un anticheat externe (WaveShield).
-- @dashboardGroup: Anticheat
Config.Anticheat = {
    votre_anticheat = { -- Tous sur false pour pas d'anticheat
        -- @dashboardLabel: WaveShield
        -- @dashboardDescription: Active l'anticheat WaveShield (externe). Mettre à false si vous n'utilisez pas ce système.
        -- @dashboardGroup: Anticheat
        -- @dashboardWidget: boolean
        ["WaveShield"] = false,
        -- @dashboardLabel: Anticheat Null (intégré)
        -- @dashboardDescription: Active l'anticheat intégré de null-core. Peut être cumulé avec WaveShield.
        -- @dashboardGroup: Anticheat
        -- @dashboardWidget: boolean
        ["others"] = true,
    },

    -- @dashboardLabel: Groupes whitelistés
    -- @dashboardDescription: Groupes exemptés de l'anticheat intégré. Utile pour les fondateurs qui utilisent des commandes admin avancées.
    -- @dashboardGroup: Anticheat
    -- @dashboardWidget: object
    withlist_group = {
        ["fondateur"] = true
    },

    -- @dashboardLabel: Durée des bans
    -- @dashboardDescription: Durée (en jours) des bans appliqués par l'anticheat. Uniquement appliqué avec WaveShield.
    -- @dashboardGroup: Anticheat
    BanTime = {
        -- @dashboardLabel: Ban blacklist (jours)
        -- @dashboardDescription: Nombre de jours de ban lorsqu'un joueur utilise un objet blacklisté (arme/véhicule/ped interdit).
        -- @dashboardGroup: Anticheat
        -- @dashboardWidget: number
        -- @dashboardMin: 0
        -- @dashboardMax: 365
        BlackList = 5
    }, 

    -- @dashboardLabel: Liste noire (objets interdits)
    -- @dashboardDescription: Objets dont l'utilisation déclenche un ban automatique : munitions, véhicules, peds et armes proscrits.
    -- @dashboardGroup: Anticheat
    BlackList = {
        -- @dashboardLabel: Munitions interdites
        -- @dashboardGroup: Anticheat
        -- @dashboardWidget: list
        Ammo = {
            "AMMO_RIFLE_TRACER",
        },
        -- @dashboardLabel: Véhicules interdits
        -- @dashboardDescription: Véhicules dont le spawn déclenche une sanction (armes militaires lourdes, chars, avions de combat, etc.).
        -- @dashboardGroup: Anticheat
        -- @dashboardWidget: list
        vehicles = {
            'stockade3',
            'hunter',
            'buzzard',
            'chernobog',
            'halftrack',
            'khanjali',
            'minitank',
            'rhino',
            'scarab',
            'trailersmall2',
            'hydra',
            'lazer',
            'rogue',
            'molotok',
            'deluxo',
            'cargoplane',
            'jet',
            'oppressor',
            'oppressor2',
        },
        peds = {
            'mp_f_stripperlite',
        },
        weapons = {
            'weapon_minigun',
        }
    }
}