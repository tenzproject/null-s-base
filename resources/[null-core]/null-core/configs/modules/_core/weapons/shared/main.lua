Config.WeaponParams = Config.WeaponParams or {}

-- Table des armes avec leurs paramètres
-- anim: animation de dégainage
-- onlyBag: nécessite un sac pour sortir l'arme
-- scoped: arme avec lunette
-- shakeCam: intensité du recul caméra
-- infiniteAmmo: munitions infinies
Config.WeaponParams.List = {
    -- Unarmed / Gadgets
    [`WEAPON_UNARMED`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`GADGET_PARACHUTE`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },

    -- Melee
    [`WEAPON_KNIFE`] = { anim = true, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_NIGHTSTICK`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_HAMMER`] = { anim = true, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_BAT`] = { anim = true, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_CROWBAR`] = { anim = true, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_GOLFCLUB`] = { anim = true, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_BOTTLE`] = { anim = true, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_DAGGER`] = { anim = true, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_HATCHET`] = { anim = true, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_KNUCKLE`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_MACHETE`] = { anim = true, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_FLASHLIGHT`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_SWITCHBLADE`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_BATTLEAXE`] = { anim = true, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_POOLCUE`] = { anim = true, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_WRENCH`] = { anim = true, scoped = false, shakeCam = 0, infiniteAmmo = false },

    -- Pistols
    [`WEAPON_PISTOL`] = { anim = true, scoped = false, shakeCam = 0.025, infiniteAmmo = false },
    [`WEAPON_PISTOL_MK2`] = { anim = true, scoped = false, shakeCam = 0.03, infiniteAmmo = false },
    [`WEAPON_COMBATPISTOL`] = { anim = false, scoped = false, shakeCam = 0.03, infiniteAmmo = false },
    [`WEAPON_PISTOL50`] = { anim = true, scoped = false, shakeCam = 0.05, infiniteAmmo = false },
    [`WEAPON_SNSPISTOL`] = { anim = true, scoped = false, shakeCam = 0.02, infiniteAmmo = false },
    [`WEAPON_SNSPISTOL_MK2`] = { anim = true, scoped = false, shakeCam = 0.025, infiniteAmmo = false },
    [`WEAPON_HEAVYPISTOL`] = { anim = true, scoped = false, shakeCam = 0.03, infiniteAmmo = false },
    [`WEAPON_VINTAGEPISTOL`] = { anim = true, scoped = false, shakeCam = 0.025, infiniteAmmo = false },
    [`WEAPON_MARKSMANPISTOL`] = { anim = true, scoped = false, shakeCam = 0.03, infiniteAmmo = false },
    [`WEAPON_REVOLVER`] = { anim = true, scoped = false, shakeCam = 0.045, infiniteAmmo = false },
    [`WEAPON_REVOLVER_MK2`] = { anim = true, scoped = false, shakeCam = 0.055, infiniteAmmo = false },
    [`WEAPON_DOUBLEACTION`] = { anim = true, scoped = false, shakeCam = 0.025, infiniteAmmo = false },
    [`WEAPON_APPISTOL`] = { anim = true, scoped = false, shakeCam = 0.05, infiniteAmmo = false },
    [`WEAPON_STUNGUN`] = { anim = false, scoped = false, shakeCam = 0.01, infiniteAmmo = false },
    [`WEAPON_FLAREGUN`] = { anim = true, scoped = false, shakeCam = 0.01, infiniteAmmo = false },

    -- SMGs (onlyBag = true)
    [`WEAPON_MICROSMG`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.035, infiniteAmmo = false },
    [`WEAPON_MACHINEPISTOL`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.035, infiniteAmmo = false },
    [`WEAPON_MINISMG`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.035, infiniteAmmo = false },
    [`WEAPON_SMG`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.045, infiniteAmmo = false },
    [`WEAPON_SMG_MK2`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.055, infiniteAmmo = false },
    [`WEAPON_ASSAULTSMG`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.05, infiniteAmmo = false },
    [`WEAPON_COMBATPDW`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.045, infiniteAmmo = false },
    [`WEAPON_MG`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.07, infiniteAmmo = false },
    [`WEAPON_COMBATMG`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.08, infiniteAmmo = false },
    [`WEAPON_COMBATMG_MK2`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.085, infiniteAmmo = false },
    [`WEAPON_GUSENBERG`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.05, infiniteAmmo = false },

    -- Assault Rifles
    [`WEAPON_ASSAULTRIFLE`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.07, infiniteAmmo = false },
    [`WEAPON_ASSAULTRIFLE_MK2`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.075, infiniteAmmo = false },
    [`WEAPON_CARBINERIFLE`] = { anim = true, onlyBag = false, scoped = false, shakeCam = 0.06, infiniteAmmo = false },
    [`WEAPON_CARBINERIFLE_MK2`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.065, infiniteAmmo = false },
    [`WEAPON_ADVANCEDRIFLE`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.06, infiniteAmmo = false },
    [`WEAPON_SPECIALCARBINE`] = { anim = true, onlyBag = false, scoped = false, shakeCam = 0.06, infiniteAmmo = false },
    [`WEAPON_SPECIALCARBINE_MK2`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.075, infiniteAmmo = false },
    [`WEAPON_BULLPUPRIFLE`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.05, infiniteAmmo = false },
    [`WEAPON_BULLPUPRIFLE_MK2`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.065, infiniteAmmo = false },
    [`WEAPON_COMPACTRIFLE`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.05, infiniteAmmo = false },
    [`WEAPON_SCAR17FM`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.05, infiniteAmmo = false },
    [`WEAPON_HKUMP`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.05, infiniteAmmo = false },

    -- Shotguns
    [`WEAPON_PUMPSHOTGUN`] = { anim = true, onlyBag = false, scoped = false, shakeCam = 0.07, infiniteAmmo = false },
    [`WEAPON_PUMPSHOTGUN_MK2`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.085, infiniteAmmo = false },
    [`WEAPON_SAWNOFFSHOTGUN`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.06, infiniteAmmo = false },
    [`WEAPON_BULLPUPSHOTGUN`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.08, infiniteAmmo = false },
    [`WEAPON_ASSAULTSHOTGUN`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.12, infiniteAmmo = false },
    [`WEAPON_MUSKET`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.04, infiniteAmmo = false },
    [`WEAPON_HEAVYSHOTGUN`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.13, infiniteAmmo = false },
    [`WEAPON_DBSHOTGUN`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.05, infiniteAmmo = false },
    [`WEAPON_AUTOSHOTGUN`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.08, infiniteAmmo = false },

    -- Sniper Rifles
    [`WEAPON_SNIPERRIFLE`] = { anim = true, onlyBag = true, scoped = true, shakeCam = 0.2, infiniteAmmo = false },
    [`WEAPON_HEAVYSNIPER`] = { anim = true, onlyBag = true, scoped = true, shakeCam = 0.3, infiniteAmmo = false },
    [`WEAPON_HEAVYSNIPER_MK2`] = { anim = true, onlyBag = true, scoped = true, shakeCam = 0.35, infiniteAmmo = false },
    [`WEAPON_MARKSMANRIFLE`] = { anim = true, onlyBag = true, scoped = true, shakeCam = 0.1, infiniteAmmo = false },
    [`WEAPON_MARKSMANRIFLE_MK2`] = { anim = true, onlyBag = true, scoped = true, shakeCam = 0.1, infiniteAmmo = false },

    -- Heavy Weapons
    [`WEAPON_GRENADELAUNCHER`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.08, infiniteAmmo = false },
    [`WEAPON_RPG`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.9, infiniteAmmo = false },
    [`WEAPON_STINGER`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_MINIGUN`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.2, infiniteAmmo = false },
    [`WEAPON_FIREWORK`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.5, infiniteAmmo = false },
    [`WEAPON_RAILGUN`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 1.0, infiniteAmmo = false },
    [`WEAPON_HOMINGLAUNCHER`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.9, infiniteAmmo = false },
    [`WEAPON_COMPACTLAUNCHER`] = { anim = true, onlyBag = true, scoped = false, shakeCam = 0.08, infiniteAmmo = false },

    -- Throwables
    [`WEAPON_GRENADE`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_STICKYBOMB`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_PROXMINE`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_SMOKEGRENADE`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_BZGAS`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_MOLOTOV`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_FIREEXTINGUISHER`] = { anim = true, scoped = false, shakeCam = 0, infiniteAmmo = true },
    [`WEAPON_PETROLCAN`] = { anim = true, scoped = false, shakeCam = 0, infiniteAmmo = true },
    [`WEAPON_BALL`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_SNOWBALL`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_FLARE`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
    [`WEAPON_PIPEBOMB`] = { anim = false, scoped = false, shakeCam = 0, infiniteAmmo = false },
}

-- Helper pour récupérer les paramètres d'une arme
function Config.WeaponParams.Get(weaponHash)
    return Config.WeaponParams.List[weaponHash]
end

-- Helper pour vérifier si une arme nécessite un sac
function Config.WeaponParams.RequiresBag(weaponHash)
    local weapon = Config.WeaponParams.List[weaponHash]
    return weapon and weapon.onlyBag == true
end
