Config._core = Config._core or {}

Config._core.Vehicles = {
    -- Anti car-kill (désactive collision avec véhicules proches)
    AntiCarKill = true,
    AntiCarKillRadius = 4.0,
    
    -- Désactiver le drive-by pour le conducteur
    DisableDriveBy = true,
    
    -- Désactiver les armes de véhicules
    DisableVehicleWeapons = true,
    
    -- Désactiver le contrôle en l'air (anti-flip)
    DisableAirControl = true,
    
    -- Véhicules exemptés du disable air control (par hash)
    BypassAirControl = {
        [`deluxo`] = true,
        [`oppressor`] = true,
        [`oppressor2`] = true,
        [`hydra`] = true,
        [`lazer`] = true,
    },
    
    -- Véhicules exemptés du disable drive-by (par hash)
    BypassDriveBy = {},
    
    -- Véhicules avec armes autorisées
    WhitelistWeaponVehicles = {
        ["technical2"] = true,
        ["tula"] = true,
        ["insurgent3"] = true,
    },
}