Config = Config or {}

Config.Realtors = {
    -- ============================================================
    -- Identité métier
    -- ============================================================
    JobName    = "realestateagent",
    SocietyName = "realestateagent",   -- même nom (cohérent avec markers.lua existant)
    BossGrade  = 3,                     -- grade minimum considéré "boss" (PC)

    -- ============================================================
    -- Points d'interaction (markers)
    -- ============================================================
    Positions = {
        -- PC du boss (interaction E pour ouvrir le dashboard)
        BossPC  = vector4(-712.8500, 264.7500, 84.137810, 175.0),
        -- Vestiaire / showroom etc déjà gérés ailleurs
    },

    -- Commande pour les employés (ouvre la tablette)
    EmployeeCommand = "realtorTablet",

    -- Touche pour ouvrir la tablette employé directement (0 = désactivé)
    -- 73 = F6 dans FiveM (control index)
    EmployeeKey = 73,

    -- ============================================================
    -- Génération automatique des biens à vendre
    -- ============================================================
    Generation = {
        RefreshInterval = 3 * 60 * 60 * 1000, -- 3h en ms
        MaxListings     = 12,                  -- nombre simultané max sur le marché
        MinListings     = 8,                   -- regen jusqu'à atteindre au moins ce nombre
        PriceJitter     = { 0.85, 1.20 },      -- mul aléatoire sur prix de base
    },

    -- ============================================================
    -- Marges
    -- ============================================================
    -- Prix d'achat société (le boss paye ce % du prix listing pour acquérir)
    BuyMargin       = 1.00,
    -- Marge de revente conseillée au public (info UI)
    PublicSaleMargin = 1.40,
    -- Loyer max en jours (1 ou 2 semaines)
    MaxRentalDays    = 14,
    MinRentalDays    = 7,

    -- ============================================================
    -- Quartiers (zones) avec multiplicateur de prix
    -- ============================================================
    Neighborhoods = {
        ["vinewood_hills"]   = { label = "Vinewood Hills",     priceMul = 2.50 },
        ["rockford_hills"]   = { label = "Rockford Hills",     priceMul = 2.20 },
        ["west_vinewood"]    = { label = "West Vinewood",      priceMul = 1.80 },
        ["downtown_vinewood"]= { label = "Downtown Vinewood",  priceMul = 1.50 },
        ["mirror_park"]      = { label = "Mirror Park",        priceMul = 1.30 },
        ["la_mesa"]          = { label = "La Mesa",            priceMul = 1.10 },
        ["vespucci"]         = { label = "Vespucci",           priceMul = 1.40 },
        ["del_perro"]        = { label = "Del Perro",          priceMul = 1.70 },
        ["little_seoul"]     = { label = "Little Seoul",       priceMul = 1.20 },
        ["paleto_bay"]       = { label = "Paleto Bay",         priceMul = 0.85 },
        ["sandy_shores"]     = { label = "Sandy Shores",       priceMul = 0.70 },
        ["grapeseed"]        = { label = "Grapeseed",          priceMul = 0.75 },
        ["lsia"]             = { label = "LS International",   priceMul = 1.00 },
        ["el_burro"]         = { label = "El Burro Heights",   priceMul = 0.95 },
        ["cypress_flats"]    = { label = "Cypress Flats",      priceMul = 1.00 },
        ["venice_beach"]     = { label = "Venice Beach",        priceMul = 1.35 },
        ["venice_canals"]    = { label = "Venice Canals",       priceMul = 1.25 },
        ["koreatown"]        = { label = "Koreatown",           priceMul = 1.15 },
        ["beverly_hills"]    = { label = "Beverly Hills",       priceMul = 2.00 },
        ["santa_monica"]     = { label = "Santa Monica",        priceMul = 1.60 },
        ["wilmington"]       = { label = "Wilmington",          priceMul = 0.90 },
    },

    -- ============================================================
    -- CONSTRUCTION
    -- ============================================================
    -- Un employé positionné sur le terrain peut lancer une construction
    -- sur sa position courante. Le joueur LE PLUS PROCHE est facturé.
    -- La propriété est créée immédiatement mais verrouillée (underConstruction = true)
    -- pendant BuildTime secondes (defaut 24h = 86400).
    -- Le propriétaire reçoit une notification à la connexion/fin.
    -- La construction ne peut pas être louée.
    Construction = {
        Enabled    = true,
        BuildTime  = 60 ,  -- s (24h par défaut)
            --86400
        -- Prix de construction par type (payé directement par le client)
        -- Séparé de basePrice pour être plus élevé
        Prices = {
            ["Low"]    = 220000,
            ["Middle"] = 500000,
            ["High"]   = 1400000,
        },

        -- Commission employé (% du prix reversé à la société)
        CommissionPct = 0.10,  -- 10% va à la caisse de la société

        -- Notification blip couleur pendant construction
        BlipColor = 1,   -- rouge
        BlipSprite = 40,
    },

    -- ============================================================
    -- Types d'intérieurs (réutilise les intérieurs de Config.Properties.List)
    -- ============================================================
    -- basePrice : prix de référence (avant multiplier quartier + jitter aléatoire)
    -- baseRent  : loyer / jour de référence
    -- photos    : webp dans modules/jobs/realtors/images/interiors/{key}_{n}.webp
    -- maxWeight : reprend la valeur de Config.Properties.List
    InteriorTypes = {
        ["Low"] = {
            label     = "Petit appartement",
            basePrice = 150000,
            baseRent  = 600,
            photos    = 3,
        },
        ["Middle"] = {
            label     = "Appartement moyen standing",
            basePrice = 320000,
            baseRent  = 950,
            photos    = 3,
        },
        ["High"] = {
            label     = "Penthouse haut standing",
            basePrice = 850000,
            baseRent  = 1800,
            photos    = 4,
        },
        ["Entrepot1"] = {
            label     = "Grand entrepôt",
            basePrice = 600000,
            baseRent  = 0,        -- pas de location pour entrepôts par défaut
            photos    = 2,
            warehouse = true,
        },
        ["Entrepot2"] = {
            label     = "Entrepôt moyen",
            basePrice = 380000,
            baseRent  = 0,
            photos    = 2,
            warehouse = true,
        },
        ["Entrepot3"] = {
            label     = "Petit entrepôt",
            basePrice = 220000,
            baseRent  = 0,
            photos    = 2,
            warehouse = true,
        },
    },

    -- ============================================================
    -- Pool de spawns (positions où une maison peut apparaître à vendre)
    -- ============================================================
    -- Chaque entrée = un point potentiel. Chaque "key" doit être unique.
    -- 'door' = porte d'entrée (où le blip apparaît)
    -- 'interior' = clé InteriorTypes (impose le type, sinon random parmi types compat.)
    -- 'neighborhood' = clé Neighborhoods
    SpawnPool = {
        { key = "vh_001", door = vector4(-174.295, 502.379, 137.665, 161.0),  interior = "High",   neighborhood = "vinewood_hills" },
        { key = "vh_002", door = vector4(-1288.40, 440.700, 97.580, 207.0),   interior = "High",   neighborhood = "vinewood_hills" },
        { key = "vh_003", door = vector4(120.270, 549.810, 184.097, 247.0),   interior = "High",   neighborhood = "vinewood_hills" },
        { key = "rh_001", door = vector4(-678.500, 213.700, 82.430, 207.0),   interior = "High",   neighborhood = "rockford_hills" },
        { key = "rh_002", door = vector4(-852.400, 705.900, 152.300, 175.0),  interior = "Middle", neighborhood = "rockford_hills" },
        { key = "wv_001", door = vector4(-1153.27, 369.07, 72.74, 91.0),      interior = "Middle", neighborhood = "west_vinewood" },
        { key = "wv_002", door = vector4(-1118.30, 437.20, 76.60, 280.0),     interior = "Low",    neighborhood = "west_vinewood" },
        { key = "dv_001", door = vector4(287.900, -1118.10, 29.540, 87.0),    interior = "Low",    neighborhood = "downtown_vinewood" },
        { key = "dv_002", door = vector4(-820.500, -1078.20, 11.140, 30.0),   interior = "Middle", neighborhood = "downtown_vinewood" },
        { key = "mp_001", door = vector4(1136.07, -726.58, 57.910, 97.0),     interior = "Low",    neighborhood = "mirror_park" },
        { key = "mp_002", door = vector4(1239.67, -729.69, 60.95, 270.0),     interior = "Middle", neighborhood = "mirror_park" },
        { key = "lm_001", door = vector4(284.7,   -1107.0, 29.4,   87.0),     interior = "Low",    neighborhood = "la_mesa" },
        { key = "vp_001", door = vector4(-1156.40, -1518.80, 10.640, 109.0),  interior = "Middle", neighborhood = "vespucci" },
        { key = "vp_002", door = vector4(-1284.70, -1116.30, 6.830, 100.0),   interior = "Low",    neighborhood = "vespucci" },
        { key = "dp_001", door = vector4(-1465.40, -537.20, 33.740, 26.0),    interior = "High",   neighborhood = "del_perro" },
        { key = "dp_002", door = vector4(-1392.30, -480.90, 71.530, 124.0),   interior = "High",   neighborhood = "del_perro" },
        { key = "ls_001", door = vector4(-580.300, -894.400, 24.140, 90.0),   interior = "Middle", neighborhood = "little_seoul" },
        { key = "pb_001", door = vector4(101.500, 6624.270, 31.780, 136.0),   interior = "Low",    neighborhood = "paleto_bay" },
        { key = "pb_002", door = vector4(-280.900, 6228.900, 31.500, 222.0),  interior = "Low",    neighborhood = "paleto_bay" },
        { key = "ss_001", door = vector4(1685.200, 4823.500, 42.000, 85.0),   interior = "Low",    neighborhood = "sandy_shores" },
        { key = "ss_002", door = vector4(1393.500, 3603.700, 38.940, 200.0),  interior = "Low",    neighborhood = "sandy_shores" },
        { key = "gs_001", door = vector4(1664.500, 4828.300, 42.000, 90.0),   interior = "Low",    neighborhood = "grapeseed" },
        { key = "eb_001", door = vector4(1199.300, -1456.500, 34.880, 200.0), interior = "Low",    neighborhood = "el_burro" },
        { key = "cf_001", door = vector4(884.500, -1772.300, 30.000, 269.0),  interior = "Middle", neighborhood = "cypress_flats" },

        -- Venice Beach - Low
        { key = "vb_001", door = vector4(-1109.441650, -1481.940674, 4.916659, 0.0),  interior = "Low", neighborhood = "venice_beach" },
        { key = "vb_002", door = vector4(-1117.929932, -1488.137939, 4.727129, 0.0),  interior = "Low", neighborhood = "venice_beach" },
        { key = "vb_003", door = vector4(-1077.175659, -1553.607544, 4.629957, 0.0),  interior = "Low", neighborhood = "venice_beach" },
        { key = "vb_004", door = vector4(-1066.017334, -1545.500977, 4.902433, 0.0),  interior = "Low", neighborhood = "venice_beach" },
        { key = "vb_005", door = vector4(-1057.805542, -1540.489380, 5.049111, 0.0),  interior = "Low", neighborhood = "venice_beach" },
        { key = "vb_006", door = vector4(-1150.937500, -1519.246094, 4.357889, 0.0),  interior = "Low", neighborhood = "venice_beach" },
        { key = "vb_007", door = vector4(-1269.716919, -1296.390869, 3.993125, 0.0),  interior = "Low", neighborhood = "venice_beach" },
        { key = "vb_008", door = vector4(-1337.403931, -1161.574585, 4.507684, 0.0),  interior = "Low", neighborhood = "venice_beach" },
        { key = "vb_009", door = vector4(-1308.155151, -1227.961670, 4.901936, 0.0),  interior = "Low", neighborhood = "venice_beach" },

        -- Venice Beach - Medium
        { key = "vb_m01", door = vector4(-1349.688599, -1161.620361, 4.508315, 0.0),  interior = "Middle", neighborhood = "venice_beach" },
        { key = "vb_m02", door = vector4(-1347.329468, -1146.313599, 4.336268, 0.0),  interior = "Middle", neighborhood = "venice_beach" },
        { key = "vb_m03", door = vector4(-1339.696289, -1127.002686, 4.333908, 0.0),  interior = "Middle", neighborhood = "venice_beach" },
        { key = "vb_m04", door = vector4(-1327.231934, -1017.461609, 7.217155, 0.0),  interior = "Middle", neighborhood = "venice_beach" },

        -- Venice Canals - Low
        { key = "vc_001", door = vector4(-1114.441040, -1069.126587, 2.150176, 0.0),  interior = "Low", neighborhood = "venice_canals" },
        { key = "vc_002", door = vector4(-1104.236694, -1059.548584, 2.528001, 0.0),  interior = "Low", neighborhood = "venice_canals" },
        { key = "vc_003", door = vector4(-1040.331299, -1136.469971, 2.158601, 0.0),  interior = "Low", neighborhood = "venice_canals" },
        { key = "vc_004", door = vector4(-1068.250366, -1163.314087, 2.747398, 0.0),  interior = "Low", neighborhood = "venice_canals" },
        { key = "vc_005", door = vector4(-1063.380981, -1160.236694, 2.756971, 0.0),  interior = "Low", neighborhood = "venice_canals" },
        { key = "vc_006", door = vector4(-1113.897827, -1193.396729, 2.357591, 0.0),  interior = "Low", neighborhood = "venice_canals" },
        { key = "vc_007", door = vector4(-884.521057,  -1072.344604, 2.344743, 0.0),  interior = "Low", neighborhood = "venice_canals" },

        -- Koreatown - Medium
        { key = "kt_001", door = vector4(-603.793274, -782.658936, 25.017269, 0.0),   interior = "Middle", neighborhood = "koreatown" },
        { key = "kt_002", door = vector4(-588.975586, -783.264404, 25.017233, 0.0),   interior = "Middle", neighborhood = "koreatown" },
        { key = "kt_003", door = vector4(-580.187317, -778.768921, 25.017231, 0.0),   interior = "Middle", neighborhood = "koreatown" },
        { key = "kt_004", door = vector4(-603.793457, -774.100769, 25.403748, 0.0),   interior = "Middle", neighborhood = "koreatown" },
        { key = "kt_005", door = vector4(-805.507690, -959.521179, 18.263424, 0.0),   interior = "Middle", neighborhood = "koreatown" },
        { key = "kt_006", door = vector4(-812.594360, -980.866455, 14.161669, 0.0),   interior = "Middle", neighborhood = "koreatown" },

        -- Beverly Hills - Medium
        { key = "bh_001", door = vector4(-769.124268, -355.759857, 37.329815, 0.0),   interior = "Middle", neighborhood = "beverly_hills" },
        { key = "bh_002", door = vector4(-874.688660, -309.068512, 39.532722, 0.0),   interior = "Middle", neighborhood = "beverly_hills" },
        { key = "bh_003", door = vector4(-931.098755, -212.992111, 38.542278, 0.0),   interior = "Middle", neighborhood = "beverly_hills" },
        { key = "bh_004", door = vector4(-931.687134, -215.866516, 38.543652, 0.0),   interior = "Middle", neighborhood = "beverly_hills" },

        -- Santa Monica - Medium
        { key = "sm_001", door = vector4(-1778.032959, -427.453186, 41.447895, 0.0),  interior = "Middle", neighborhood = "santa_monica" },
        { key = "sm_002", door = vector4(-1697.238770, -422.168854, 46.024132, 0.0),  interior = "Middle", neighborhood = "santa_monica" },
        { key = "sm_003", door = vector4(-1652.749756, -372.586212, 45.330692, 0.0),  interior = "Middle", neighborhood = "santa_monica" },
        { key = "sm_004", door = vector4(-1597.004028, -352.349304, 45.985588, 0.0),  interior = "Middle", neighborhood = "santa_monica" },
        { key = "sm_005", door = vector4(-1533.842407, -326.342163, 47.908356, 0.0),  interior = "Middle", neighborhood = "santa_monica" },

        -- Vinewood Hills - High
        { key = "vwh_001", door = vector4(-1308.269653, 449.455078,  100.971214, 0.0), interior = "High", neighborhood = "vinewood_hills" },
        { key = "vwh_002", door = vector4(-1217.894043, 505.900146,  95.667610,  0.0), interior = "High", neighborhood = "vinewood_hills" },
        { key = "vwh_003", door = vector4(-1125.360107, 548.671997,  102.561951, 0.0), interior = "High", neighborhood = "vinewood_hills" },
        { key = "vwh_004", door = vector4(107.046219,   467.604919,  147.373810, 0.0), interior = "High", neighborhood = "vinewood_hills" },
        { key = "vwh_005", door = vector4(57.631641,    449.643402,  147.032104, 0.0), interior = "High", neighborhood = "vinewood_hills" },
        { key = "vwh_006", door = vector4(-174.760208,  502.480438,  137.420074, 0.0), interior = "High", neighborhood = "vinewood_hills" },
        { key = "vwh_007", door = vector4(-386.426941,  504.702332,  120.407494, 0.0), interior = "High", neighborhood = "vinewood_hills" },
        { key = "vwh_008", door = vector4(-406.600189,  567.107239,  124.604286, 0.0), interior = "High", neighborhood = "vinewood_hills" },
        { key = "vwh_009", door = vector4(-533.304321,  709.639404,  153.152283, 0.0), interior = "High", neighborhood = "vinewood_hills" },

        -- Wilmington - Low
        { key = "wil_001", door = vector4(191.948059,  -1883.591797, 25.087244, 0.0),  interior = "Low", neighborhood = "wilmington" },
        { key = "wil_002", door = vector4(171.466400,  -1871.365234, 24.400637, 0.0),  interior = "Low", neighborhood = "wilmington" },
        { key = "wil_003", door = vector4(149.981522,  -1864.893921, 24.591356, 0.0),  interior = "Low", neighborhood = "wilmington" },
        { key = "wil_004", door = vector4(152.704224,  -1823.613525, 27.864647, 0.0),  interior = "Low", neighborhood = "wilmington" },
        { key = "wil_005", door = vector4(216.674118,  -1717.276001, 29.667950, 0.0),  interior = "Low", neighborhood = "wilmington" },
        { key = "wil_006", door = vector4(249.905029,  -1730.562134, 29.673401, 0.0),  interior = "Low", neighborhood = "wilmington" },

        -- Entrepôts
        { key = "wh_lsia_1",  door = vector4(-1064.10, -2769.90, 13.760, 333.0), interior = "Entrepot1", neighborhood = "lsia" },
        { key = "wh_lsia_2",  door = vector4(-1145.60, -2812.00, 13.940, 60.0),  interior = "Entrepot2", neighborhood = "lsia" },
        { key = "wh_cf_1",    door = vector4(802.300, -2982.300, 5.040, 0.0),    interior = "Entrepot1", neighborhood = "cypress_flats" },
        { key = "wh_cf_2",    door = vector4(740.000, -3000.000, 5.900, 0.0),    interior = "Entrepot2", neighborhood = "cypress_flats" },
        { key = "wh_cf_3",    door = vector4(905.000, -3015.000, 5.900, 0.0),    interior = "Entrepot3", neighborhood = "cypress_flats" },
    },

    -- ============================================================
    -- Blip agence (déjà géré via ESX.addBlips dans le client legacy)
    -- ============================================================
    Blip = {
        position = vector3(-709.1039, 268.1188, 83.14735),
        sprite   = 476,
        color    = 26,
        scale    = 0.8,
        label    = "Agence Immobilière",
    },

    -- ============================================================
    -- BURGLARY (cambriolage illégal)
    -- ------------------------------------------------------------
    -- Logique : le joueur utilise un lockpick à proximité de la porte
    -- d'une propriété (≤ 2.5m). Un mini-jeu se lance avec une difficulté
    -- variable selon le type d'intérieur.
    --   • Réussite → alerte police IMMÉDIATE + ouverture de la session de
    --     loot (timer + nb d'items max).
    --   • Échec    → alarme + alerte police 10s plus tard.
    -- ============================================================
    Burglary = {
        Enabled    = true,
        DoorRange  = 2.5,    -- distance max à la porte pour déclencher
        Cooldown   = 0,      -- s, cooldown court après tentative ÉCHOUÉE (remplacé par PropCooldown en cas de succès)
        PropCooldown = 21600, -- s, cooldown long par propriété après succès (6h = 21600)
        GlobalCD   = 600,    -- s, anti-spam global par joueur

        -- Plage horaire autorisée (heure serveur, 0-23). nil = toujours autorisé.
        TimeWindow = { from = 6, to = 23 },  -- de 20h à 6h (passe minuit)

        -- Nombre minimum de policiers en service pour autoriser un cambriolage.
        MinPolice = 0,

        -- Notification au propriétaire (Discord identifier ou juste notification in-game)
        OwnerNotify = true,   -- notifier le propriétaire quand sa maison est cambriolée

        -- Item requis selon le type d'intérieur. Si nil → impossible.
        RequireItems = {
            Low       = "lockpick",
            Middle    = "lockpick",
            High      = "advanced_lockpick",
            Entrepot1 = "advanced_lockpick",
            Entrepot2 = "advanced_lockpick",
            Entrepot3 = "advanced_lockpick",
        },
        -- Probabilité de casse de l'item (0..1) sur tentative ratée
        BreakChance = {
            lockpick          = 0.35,
            advanced_lockpick = 0.18,
        },

        -- Difficulté du minigame :
        --   pins      = nombre de "tumblers" à crocheter dans l'ordre
        --   window    = largeur de la zone verte (en degrés, sur 360°)
        --   rotation  = ms par tour de l'aiguille
        --   tries     = nb max d'erreurs autorisées avant échec
        --   lootTime  = secondes de la phase loot
        --   maxItems  = nb max d'items volables dans une session
        -- ⚠ Plus une maison est "petite" plus c'est dur (cf. demande user).
        --   Entrepôts = niveau le plus dur.
        Difficulty = {
            High      = { pins = 3, window = 32, rotation = 2200, tries = 3, lootTime = 75, maxItems = 7 },
            Middle    = { pins = 4, window = 26, rotation = 2000, tries = 3, lootTime = 65, maxItems = 5 },
            Low       = { pins = 5, window = 22, rotation = 1700, tries = 2, lootTime = 50, maxItems = 4 },
            Entrepot1 = { pins = 6, window = 18, rotation = 1500, tries = 2, lootTime = 90, maxItems = 8 },
            Entrepot2 = { pins = 6, window = 16, rotation = 1400, tries = 1, lootTime = 80, maxItems = 7 },
            Entrepot3 = { pins = 7, window = 14, rotation = 1300, tries = 1, lootTime = 70, maxItems = 6 },
        },

        -- Loot drop tables. Chaque entrée : { item, weight, count = {min,max} }
        -- Le client reçoit une "vue" pré-générée par le serveur (les items
        -- réellement disponibles dans cette session); le joueur clique pour
        -- en prendre jusqu'à `maxItems`. Les items sont AJOUTÉS au moment
        -- du clic (sécurité : vérification serveur).
        LootTables = {
            Low = {
                { item = "cash",     weight = 30, count = { 50, 250 } },
                { item = "phone",    weight = 18, count = { 1, 1 } },
                { item = "wallet",   weight = 22, count = { 1, 1 } },
                { item = "watch",    weight = 12, count = { 1, 1 } },
                { item = "laptop",   weight = 6,  count = { 1, 1 } },
                { item = "tablet",   weight = 6,  count = { 1, 1 } },
                { item = "jewelry",  weight = 6,  count = { 1, 1 } },
            },
            Middle = {
                { item = "cash",     weight = 25, count = { 200, 700 } },
                { item = "phone",    weight = 14, count = { 1, 1 } },
                { item = "watch",    weight = 14, count = { 1, 1 } },
                { item = "laptop",   weight = 14, count = { 1, 1 } },
                { item = "tablet",   weight = 10, count = { 1, 1 } },
                { item = "jewelry",  weight = 16, count = { 1, 2 } },
                { item = "rolex",    weight = 7,  count = { 1, 1 } },
            },
            High = {
                { item = "cash",     weight = 22, count = { 600, 2200 } },
                { item = "rolex",    weight = 18, count = { 1, 1 } },
                { item = "jewelry",  weight = 22, count = { 1, 3 } },
                { item = "laptop",   weight = 12, count = { 1, 1 } },
                { item = "gold",     weight = 12, count = { 1, 2 } },
                { item = "diamond",  weight = 8,  count = { 1, 1 } },
                { item = "painting", weight = 6,  count = { 1, 1 } },
            },
            Entrepot1 = {
                { item = "cash",     weight = 15, count = { 1500, 4500 } },
                { item = "gold",     weight = 22, count = { 2, 5 } },
                { item = "diamond",  weight = 12, count = { 1, 2 } },
                { item = "weed_pooch",   weight = 18, count = { 1, 4 } },
                { item = "coke_pooch",   weight = 12, count = { 1, 3 } },
                { item = "meth_pooch",   weight = 10, count = { 1, 2 } },
                { item = "electronic_components", weight = 11, count = { 2, 6 } },
            },
            Entrepot2 = {
                { item = "cash",     weight = 18, count = { 800, 2200 } },
                { item = "gold",     weight = 18, count = { 1, 3 } },
                { item = "weed_pooch",   weight = 18, count = { 1, 3 } },
                { item = "coke_pooch",   weight = 14, count = { 1, 2 } },
                { item = "electronic_components", weight = 18, count = { 2, 5 } },
                { item = "laptop",   weight = 14, count = { 1, 1 } },
            },
            Entrepot3 = {
                { item = "cash",     weight = 22, count = { 400, 1100 } },
                { item = "weed_pooch",   weight = 22, count = { 1, 2 } },
                { item = "electronic_components", weight = 24, count = { 1, 4 } },
                { item = "laptop",   weight = 16, count = { 1, 1 } },
                { item = "phone",    weight = 16, count = { 1, 2 } },
            },
        },

        -- Items strictement interdits au loot (filet de sécurité serveur).
        -- Si un item du LootTables apparait ici, il est silencieusement
        -- ignoré côté serveur (utile si tu rebrasses LootTables sans relire la liste).
        Banned = {
            "weapon_pistol", "weapon_combatpistol", "weapon_smg", "weapon_assaultrifle",
            "weapon_carbinerifle", "weapon_pumpshotgun", "weapon_sniperrifle",
            "weapon_microsmg", "weapon_advancedrifle", "weapon_specialcarbine",
            -- (les armes ne devraient pas être dans LootTables ; ce filet
            --  bloque toute injection accidentelle)
        },

        -- Alerte police (réutilise le pattern existant : ESX.ShowAdvancedNotif + null:police:blips)
        PoliceAlert = {
            immediate = {
                title    = "DISPATCH 911",
                subtitle = "Effraction signalée",
                message  = "Cambriolage en cours à %s",
                icon     = "CHAR_CALL911",
                blip     = { sprite = 161, color = 1, scale = 1.4, duration = 180 },
            },
            onAlarm = {
                title    = "DISPATCH 911",
                subtitle = "Alarme déclenchée",
                message  = "Une alarme s'est déclenchée à %s",
                icon     = "CHAR_CALL911",
                delay    = 10,           -- secondes après l'échec du minigame
                blip     = { sprite = 161, color = 5, scale = 1.4, duration = 120 },
            },
        },

        -- =========================================================================
        -- VOL DU COFFRE RÉEL (nouveau système immersif)
        -- Après réussite du crochetage, le joueur entre dans la propriété et peut
        -- voler les vrais items du coffre du propriétaire.
        -- =========================================================================
        RealChestLoot = {
            Enabled = true,  -- true = vrai coffre, false = loot table aléatoire

            -- Limites de vol (par session de burglary)
            MaxDifferentItems = 5,    -- max d'items DIFFÉRENTS qu'on peut voler
            MaxQuantityPerItem = 10,  -- max quantité par item (ex: max 10 water)

            -- Nombre de mini-jeux successifs à réussir pour voler UN item
            AttemptsPerItem = 3,     -- ex: 3 mini-jeux à la suite pour chaque objet

            -- Cooldown (ms) entre deux vols d'objets (après chaque succès de vol)
            ItemStealCooldown = 4000,  -- 4 secondes de pause entre chaque item volé

            -- Mini-jeu rapide pour chaque objet volé (barre de timing)
            Minigame = {
                enabled = true,
                duration = 3.0,       -- secondes de base pour compléter le mini-jeu
                sweetSpotSize = 0.25, -- taille de zone verte de base (0.0 à 1.0)
                maxAttempts = 3,      -- nb d'essais avant échec d'UN mini-jeu (dans la série)

                -- Scaling de difficulté selon la quantité demandée :
                -- Pour chaque tranche de `step` items, la zone verte réduit de `spotReduce`
                -- et la durée réduit de `durationReduce` (jusqu'aux minima définis).
                DifficultyScaling = {
                    step          = 3,     -- tous les N items, ça durcit
                    spotReduce    = 0.04,  -- réduction de sweetSpotSize par tranche
                    durationReduce = 0.4,  -- réduction de durée (s) par tranche
                    minSpot       = 0.08,  -- zone verte minimum
                    minDuration   = 1.2,   -- durée minimum (s)
                    attemptsReduce = 1,    -- réduction maxAttempts par 2 tranches
                    minAttempts   = 1,     -- essais minimum
                },
            },

            -- Durée de la phase de loot dans la propriété (secondes)
            LootTime = 120,

            -- Position du "coffre à voler" à l'intérieur (relatif à l'entrée)
            -- Si nil, utilise la position COFFRE définie dans l'intérieur
            ChestOffset = { x = 0.0, y = -2.0, z = 0.0 },
        },

        -- Anim pendant le minigame
        Anim = {
            dict = "anim@heists@keycard@",
            name = "exit",
            flag = 49,
        },
    },
}
