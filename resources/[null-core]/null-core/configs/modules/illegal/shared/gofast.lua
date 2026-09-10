-- ============================================================================
-- GOFAST SYSTEM V2 - Configuration Complète
-- Système de transport illégal basé sur la réputation
-- ============================================================================

Config.GoFast = {}

-- ============================================================================
-- RÉPUTATION & PROGRESSION
-- ============================================================================
Config.GoFast.Reputation = {
    -- XP gagnée par mission réussie (base, modifiée par difficulté)
    xpPerMission = 50,
    -- XP perdue en cas d'échec (abandon, véhicule détruit)
    xpLostOnFail = 25,
    -- XP perdue en cas de trahison (avant blacklist)
    xpLostOnBetray = 9999,
    -- Cooldown entre missions solo (secondes)
    soloCooldown = 600,
    -- Cooldown entre missions crew (secondes)
    crewCooldown = 900,
    -- Nombre minimum de membres connectés pour un gofast crew
    crewMinPlayers = 5,
}

-- Paliers de réputation solo
Config.GoFast.Tiers = {
    [1] = {
        name = "PROSPECT",
        minXP = 0,
        maxXP = 199,
        label = "Prospect",
        description = "Nouveau dans le circuit. Petites courses, petites récompenses.",
        payMultiplier = 1.0,
        difficulty = 20,
        vehicles = { "sultan", "kuruma", "schafter2" },
        cargo = {
            { item = "weed_pooch",  label = "Pochon de Weed",  min = 5,  max = 15 },
            { item = "coke_pooch",  label = "Pochon de Coke",  min = 2,  max = 8 },
        },
    },
    [2] = {
        name = "RUNNER",
        minXP = 200,
        maxXP = 599,
        label = "Runner",
        description = "Tu commences à faire tes preuves. Les courses deviennent sérieuses.",
        payMultiplier = 1.5,
        difficulty = 40,
        vehicles = { "elegy2", "jester", "massacro" },
        cargo = {
            { item = "weed_pooch",  label = "Pochon de Weed",  min = 10, max = 30 },
            { item = "coke_pooch",  label = "Pochon de Coke",  min = 5,  max = 20 },
            { item = "meth_pooch",  label = "Pochon de Meth",  min = 3,  max = 10 },
        },
    },
    [3] = {
        name = "GHOST",
        minXP = 600,
        maxXP = 1499,
        label = "Ghost",
        description = "Invisible sur la route. Les flics te connaissent pas encore.",
        payMultiplier = 2.0,
        difficulty = 60,
        vehicles = { "pariah", "italigtb", "zentorno" },
        cargo = {
            { item = "weed_brick",  label = "Brique de Weed",  min = 2,  max = 5 },
            { item = "coke_brick",  label = "Brique de Coke",  min = 1,  max = 3 },
            { item = "meth_pooch",  label = "Pochon de Meth",  min = 10, max = 25 },
        },
    },
    [4] = {
        name = "KINGPIN",
        minXP = 1500,
        maxXP = 99999,
        label = "Kingpin",
        description = "Le réseau te fait confiance aveuglément. Cargaisons massives.",
        payMultiplier = 3.0,
        difficulty = 85,
        vehicles = { "t20", "entityxf", "osiris", "nero2" },
        cargo = {
            { item = "weed_brick",  label = "Brique de Weed",  min = 5,  max = 12 },
            { item = "coke_brick",  label = "Brique de Coke",  min = 3,  max = 8 },
            { item = "meth_barrel", label = "Baril de Meth",   min = 1,  max = 3 },
        },
    },
}

-- Paliers de réputation crew (basé sur le niveau du groupe illégal)
Config.GoFast.CrewTiers = {
    [1] = {
        name = "CREW_LOW",
        minLevel = 1,
        maxLevel = 9,
        label = "Équipe Débutante",
        payMultiplier = 2.0,
        difficulty = 35,
        vehicles = { "mule", "burrito3", "youga2" },
        cargo = {
            { item = "weed_brick",  label = "Brique de Weed",  min = 10, max = 20 },
            { item = "coke_brick",  label = "Brique de Coke",  min = 5,  max = 10 },
        },
    },
    [2] = {
        name = "CREW_MID",
        minLevel = 10,
        maxLevel = 49,
        label = "Équipe Confirmée",
        payMultiplier = 3.5,
        difficulty = 55,
        vehicles = { "benson", "pounder", "mule3" },
        cargo = {
            { item = "weed_brick",  label = "Brique de Weed",  min = 15, max = 35 },
            { item = "coke_brick",  label = "Brique de Coke",  min = 10, max = 20 },
            { item = "meth_barrel", label = "Baril de Meth",   min = 2,  max = 6 },
        },
    },
    [3] = {
        name = "CREW_HIGH",
        minLevel = 50,
        maxLevel = 99,
        label = "Cartel",
        payMultiplier = 5.0,
        difficulty = 80,
        vehicles = { "hauler", "phantom", "packer" },
        cargo = {
            { item = "weed_brick",  label = "Brique de Weed",  min = 30, max = 60 },
            { item = "coke_brick",  label = "Brique de Coke",  min = 15, max = 35 },
            { item = "meth_barrel", label = "Baril de Meth",   min = 5,  max = 15 },
        },
    },
}

-- ============================================================================
-- ROUTES & POINTS (pickup → delivery, générés dynamiquement)
-- ============================================================================
Config.GoFast.PickupPoints = {
    { coords = vector4(1391.73, -2080.96, 52.08, 224.78),  label = "Port de LS - Dock 7",      zone = "port" },
    { coords = vector4(137.42, -3092.81, 5.90, 270.34),    label = "Terminal Maritime Sud",    zone = "port" },
    { coords = vector4(2669.89, 1469.55, 24.50, 180.0),    label = "Desert - Route 68",        zone = "desert" },
    { coords = vector4(1536.40, 6340.15, 24.13, 310.0),    label = "Paleto - Entrepôt Nord",   zone = "paleto" },
    { coords = vector4(-1150.28, -2012.59, 13.18, 330.0),  label = "Aéroport LS - Hangar 4",   zone = "airport" },
    { coords = vector4(2540.84, -378.31, 92.99, 351.33),   label = "Collines de Vinewood",     zone = "hills" },
    { coords = vector4(481.24, -3348.25, 6.07, 85.0),      label = "Port industriel Est",      zone = "port" },
    { coords = vector4(-66.80, 6336.62, 31.50, 225.0),     label = "Paleto - Ferme isolée",    zone = "paleto" },
}

Config.GoFast.DeliveryPoints = {
    { coords = vector4(-865.88, -1654.63, -0.47, 140.0),   label = "La Puerta - Quai",         zone = "south" },
    { coords = vector4(-2176.12, 4269.10, 48.98, 45.0),    label = "North Yankton Bypass",     zone = "north" },
    { coords = vector4(-127.01, 2792.03, 53.10, 270.0),    label = "Harmony - Parking",        zone = "desert" },
    { coords = vector4(2530.91, 2587.09, 37.95, 2.0),      label = "Sandy Shores - Garage",    zone = "desert" },
    { coords = vector4(-1049.75, -850.86, 4.93, 205.0),    label = "Vespucci - Arrière-cour",  zone = "south" },
    { coords = vector4(724.02, -1082.91, 22.17, 94.0),     label = "La Mesa - Entrepôt",       zone = "south" },
    { coords = vector4(975.40, -1806.53, 31.29, 358.0),    label = "El Rancho - Casse auto",   zone = "south" },
    { coords = vector4(-589.07, 5316.44, 70.25, 310.0),    label = "Grapeseed - Grange",       zone = "north" },
}

-- ============================================================================
-- CONTACTS / RÉSEAU (NPC contacts dans l'app CrimeNet)
-- ============================================================================
Config.GoFast.Contacts = {
    {
        id = "el_conectado",
        name = "El Conectado",
        alias = "???",
        avatar = "contact_shadow",
        description = "Premier contact du réseau. Méfiant mais régulier.",
        unlockXP = 0,
        trustLevel = 1,
        maxTrust = 3,
        messages = {
            intro = "T'es nouveau. Prouve que t'es fiable. Petite course, petit paquet.",
            mission = "J'ai un colis. Pickup confirmé. Bouge.",
            success = "Clean. T'es peut-être pas si mauvais.",
            fail = "Tu me fais perdre du fric. Dernière chance.",
        },
    },
    {
        id = "la_sombra",
        name = "La Sombra",
        alias = "Fantôme",
        avatar = "contact_ghost",
        description = "Opère dans l'ombre. Personne ne l'a jamais vu.",
        unlockXP = 200,
        trustLevel = 1,
        maxTrust = 5,
        messages = {
            intro = "On m'a parlé de toi. Voyons si tu vaux le détour.",
            mission = "Route tracée. Marchandise prête. Zéro erreur autorisée.",
            success = "Impeccable. Tu commences à comprendre.",
            fail = "Décevant. Ne reviens pas avant d'avoir retrouvé tes couilles.",
        },
    },
    {
        id = "don_rafa",
        name = "Don Rafa",
        alias = "Le Patriarche",
        avatar = "contact_boss",
        description = "Ancien du milieu. Connecté avec le cartel. Ne tolère aucune erreur.",
        unlockXP = 600,
        trustLevel = 1,
        maxTrust = 5,
        messages = {
            intro = "Mon réseau n'accepte que les meilleurs. Tu vas me prouver que tu en fais partie.",
            mission = "Cargaison prioritaire. Livraison express. Ne me déçois pas.",
            success = "Tu as du potentiel, gamin. Continue comme ça.",
            fail = "Un échec de plus et tu seras enterré dans le désert.",
        },
    },
    {
        id = "the_architect",
        name = "The Architect",
        alias = "Architecte",
        avatar = "contact_elite",
        description = "Cerveau du réseau. Gère les opérations les plus massives.",
        unlockXP = 1500,
        trustLevel = 1,
        maxTrust = 5,
        messages = {
            intro = "Bienvenue au sommet. Ici, chaque erreur se paie cash. En vie.",
            mission = "Opération en cours. Véhicule armé, cargaison pleine. Tu connais la musique.",
            success = "Parfait. Le cartel est satisfait.",
            fail = "Tu viens de signer ton arrêt de mort.",
        },
    },
}

-- ============================================================================
-- ANTI-TRAHISON (Système de sanctions)
-- ============================================================================
Config.GoFast.Betrayal = {
    -- Si le joueur ne livre pas la marchandise dans ce délai (secondes), c'est une trahison
    deliveryTimeout = 900,  -- 15 minutes
    -- Temps avant que le warning "WANTED" apparaisse dans l'app (secondes après trahison)
    wantedDelay = 120,
    -- Zone Sud de LS pour les drive-by aléatoires (centre + rayon)
    dangerZone = {
        center = vector3(200.0, -1600.0, 30.0),
        radius = 1500.0,
    },
    -- Probabilité de drive-by par check (toutes les 60 secondes en zone)
    driveByChance = 0.35,  -- 35% par check
    -- Délai min entre deux drive-by (secondes)
    driveByCooldown = 300,
    -- Véhicules utilisés pour les drive-by hostiles
    driveByVehicles = { "baller2", "cavalcade2", "granger" },
    -- Modèles PNJ pour le guet-apens / drive-by
    hostilePeds = {
        "g_m_y_mexgoon_01", "g_m_y_mexgoon_02", "g_m_y_mexgoon_03",
        "g_m_m_armboss_01", "g_m_m_armgoon_01", "g_m_y_armgoon_02",
    },
    -- Armes des PNJ hostiles
    hostileWeapons = {
        `WEAPON_MICROSMG`, `WEAPON_PISTOL50`, `WEAPON_ASSAULTRIFLE`,
    },
    -- Nombre de PNJ au guet-apens
    ambushPedCount = 12,
    -- Messages d'alerte dans l'app
    wantedMessages = {
        "[SYSTÈME] Ta trahison a été enregistrée.",
        "[SYSTÈME] Le réseau te cherche. Chaque rue est un piège.",
        "[SYSTÈME] Services CrimeNet suspendus. BLACKLISTÉ.",
    },
}

-- ============================================================================
-- PAIEMENTS
-- ============================================================================
Config.GoFast.Pay = {
    -- Prix de base par item de cargo livré
    basePricePerItem = {
        weed_pooch  = 150,
        coke_pooch  = 300,
        meth_pooch  = 250,
        weed_brick  = 1500,
        coke_brick  = 3500,
        meth_barrel = 8000,
    },
    -- Bonus pour véhicule en bon état (multiplié par engineHealth / 1000)
    vehicleConditionBonus = true,
    -- Bonus de rapidité (si livré en moins de X secondes)
    speedBonus = {
        threshold = 300,  -- 5 minutes
        multiplier = 1.25,
    },
    -- XP du groupe illégal gagnée par gofast réussi
    gangXP = 75,
    -- Missions gang à progresser
    gangMissions = {
        "daily_gofast_complete",
        "daily_gofast_multiple",
        "weekly_gofast_master",
    },
}

-- ============================================================================
-- PNJ MODÈLES (pour les spawns de contacts au pickup)
-- ============================================================================
Config.GoFast.PedModels = {
    "g_m_m_armgoon_01", "g_m_m_armboss_01", "g_m_y_mexgoon_02",
    "g_m_y_mexgoon_01", "g_m_y_armgoon_02", "a_m_m_og_boss_01",
}

-- ============================================================================
-- POLICE ALERT
-- ============================================================================
Config.GoFast.PoliceAlert = {
    enabled = true,
    -- Délai avant alerte aux flics (secondes après le départ)
    delay = 10,
    -- Message envoyé aux policiers
    message = "D'après mes infos, un transport illégal est en cours. Restez attentifs !",
}