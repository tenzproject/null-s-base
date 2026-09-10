-- ============================================================
--  Config.Taxi  —  Système de Taxi complet
--  Missions multiples · Rangs · Pourboires · Humeur client
-- ============================================================
Config.Taxi = {
    DefaultBrand = "downtown",
    Brands = {
        downtown = {
            id          = "downtown",
            name        = "Downtown Cab Co.",
            logo        = "shopui/brands/taxi.png",
            bgColor     = "#f5b400",     -- fond brand (sombre, comme les shops)
            accentColor = "#f5b400",     -- couleur principale de la tablette
            tagline     = "À votre service, jour et nuit.",
        },
    },
    -- Compat ascendante (Brand singulier)
    Brand = nil,

    -- ---- Positions principales (menu garage, rangement, spawn) -------
    Positions = {
        Garage = vector3(-1254.0399, -279.8883, 38.8453),
        Ranger = vector3(-1266.3893, -277.3861, 38.7411),
        Spawn  = vector4(-1257.8385, -274.1204, 38.8373, 29.0650),
    },

    -- ---- Économie ------------------------------------------
    Economy = {
        BaseFare       = 8,        -- montant fixe au démarrage de la course
        PerKilometer   = 12,       -- $ par km parcouru avec client
        TipMultiplier  = 0.30,     -- 0..0.30 du fare en pourboire selon humeur
        SocietyShare   = 1.00,     -- part vers society_taxi (en multiple du gain joueur)
        DailyRideGoal  = 8,        -- nombre de courses pour bonus journalier
        DailyBonus     = 750,      -- bonus en $ pour avoir atteint l'objectif

        -- Multiplicateurs par type de mission
        MissionMultiplier = {
            standard  = 1.00,
            vip       = 1.65,
            tour      = 1.30,
            express   = 1.45,
            medical   = 1.55,
        },

        -- Compteur de course (quand un joueur appelle un taxi via le tel)
        -- Le prix est calculé en direct : base + distance parcourue.
        RideMeter = {
            BaseFare      = 10,      -- montant fixe au démarrage
            PerMeter      = 0.012,   -- $ ajoutés par mètre parcouru
            MinFare       = 15,      -- montant minimum facturé
            UpdateMs      = 500,     -- période de mise à jour HUD (ms)
            DriverXp      = 2,       -- XP gagnés par le chauffeur à la fin
            SocietyShare  = 1.00,    -- part de la course versée à society_taxi
        },

        -- Bonus Pénalités (humeur client)
        Mood = {
            CrashPenalty       = 18,    -- points perdus à chaque collision
            HardBrakePenalty   = 6,     -- freinage brusque
            OverspeedPenalty   = 3,     -- au-dessus de SpeedLimit (par tick)
            OffroadPenalty     = 2,     -- sortie de route prolongée
            SmoothBonus        = 1,     -- chaque seconde sans incident
            SpeedLimit         = 110,   -- km/h au-dessus → tick de pénalité
            MinPercent         = 0,
            MaxPercent         = 100,
            StartPercent       = 100,
        },
    },

    -- ---- Rangs et progression ------------------------------
    Ranks = {
        { key = "novice",   label = "Apprenti",       minXp = 0,    payMul = 1.00, vehicles = { "taxi" } },
        { key = "confirme", label = "Confirmé",       minXp = 25,   payMul = 1.10, vehicles = { "taxi", "stanier" } },
        { key = "experimente", label = "Expérimenté", minXp = 80,   payMul = 1.20, vehicles = { "taxi", "stanier", "premier" } },
        { key = "veteran",  label = "Vétéran",        minXp = 200,  payMul = 1.35, vehicles = { "taxi", "stanier", "premier", "asea" } },
        { key = "legende",  label = "Légende",        minXp = 500,  payMul = 1.55, vehicles = { "taxi", "stanier", "premier", "asea", "schafter2" } },
    },

    -- XP par mission terminée (pondérée par humeur finale)
    XpReward = {
        standard = 1,
        vip      = 2,
        tour     = 3,
        express  = 2,
        medical  = 3,
    },

    -- ---- Véhicules disponibles -----------------------------
    Vehicles = {
        { model = "taxi",      label = "Taxi Standard",     livery = nil,  rankReq = "novice" },
        { model = "stanier",   label = "Stanier Cabby",     livery = nil,  rankReq = "confirme" },
        { model = "premier",   label = "Premier Comfort",   livery = nil,  rankReq = "experimente" },
        { model = "asea",      label = "Asea Express",      livery = nil,  rankReq = "veteran" },
        { model = "schafter2", label = "Schafter Executive",livery = nil,  rankReq = "legende" },
    },

    -- ---- Types de missions ---------------------------------
    Missions = {
        standard = {
            label       = "Course Standard",
            description = "Prenez un client lambda et déposez-le à destination.",
            icon        = "user",
            duration    = 600,        -- timeout en secondes
            stops       = 1,
            tipBase     = 1.0,
        },
        vip = {
            label       = "Course VIP",
            description = "Un client exigeant (avocat, businessman, célébrité). Conduite douce exigée.",
            icon        = "crown",
            duration    = 720,
            stops       = 1,
            tipBase     = 1.4,
            moodCritical= true,       -- l'humeur impacte fortement le pourboire
            requireRank = "confirme",
        },
        tour = {
            label       = "Tour Touristique",
            description = "Promenez un touriste en visitant 3 spots emblématiques.",
            icon        = "map",
            duration    = 900,
            stops       = 3,
            tipBase     = 1.2,
            requireRank = "confirme",
        },
        express = {
            label       = "Course Express",
            description = "Un client pressé. Plus c'est rapide, plus le pourboire est gros.",
            icon        = "zap",
            duration    = 360,
            stops       = 1,
            tipBase     = 1.0,
            timeBonus   = true,       -- bonus si terminé sous timeBonusUnder
            timeBonusUnder = 240,
            requireRank = "confirme",
        },
        medical = {
            label       = "Transport Médical",
            description = "Un client blessé légèrement à conduire à l'hôpital. Conduite stable obligatoire.",
            icon        = "heart",
            duration    = 540,
            stops       = 1,
            tipBase     = 1.3,
            moodCritical= true,
            destinationPreset = vector3(307.7, -1433.4, 29.9),
            requireRank = "experimente",
        },
    },

    -- ---- Peds disponibles par catégorie --------------------
    Peds = {
        standard = {
            "a_f_y_genhot_01", "a_f_y_eastsa_03", "a_m_y_business_02",
            "a_m_m_business_01", "a_m_y_clubcust_01", "a_f_y_yoga_01",
            "a_m_m_eastsa_02", "a_m_y_beachvesp_02",
        },
        vip = {
            "a_m_y_bevhills_01", "a_m_y_bevhills_02", "a_m_m_bevhills_02",
            "a_f_y_vinewood_03", "a_f_y_vinewood_04", "a_m_m_golfer_01",
            "a_m_y_business_01", "a_m_y_busicas_01",
        },
        tour = {
            "a_f_y_tourist_01", "a_f_y_tourist_02", "a_m_y_tourist_01",
            "a_f_y_genhot_01", "a_m_m_business_01",
        },
        express = {
            "a_m_y_business_02", "a_f_y_business_02", "a_m_y_busicas_01",
            "a_m_m_business_01",
        },
        medical = {
            "a_f_o_genstreet_01", "a_m_o_acult_01", "a_m_o_genstreet_01",
            "a_f_m_skidrow_01", "a_m_m_eastsa_02",
        },
    },

    -- ---- Dialogues ad-hoc (subtitle in-game) ---------------
    Dialogues = {
        onPickup = {
            "Salut chef ! Merci d'être venu si vite.",
            "Bonjour, vous tombez bien.",
            "Aaah un taxi enfin ! Bonjour.",
            "Ah merci, je suis pressé.",
            "Bonjour, vous m'emmenez où je vais ?",
        },
        vipPickup = {
            "Bonjour. Conduite ~y~impeccable~s~ s'il vous plaît.",
            "Pas de virages brusques merci.",
            "Une conduite calme, je vous prie.",
        },
        medicalPickup = {
            "~r~Aïe~s~... allez-y doucement, je vous en supplie.",
            "Merci... évitez les bosses si possible.",
        },
        expressPickup = {
            "Vite, vite, je suis très en retard !",
            "On y va, mettez la gomme !",
            "J'ai un rendez-vous crucial, foncez.",
        },
        onDropoff = {
            "Merci beaucoup, bonne route.",
            "Voilà votre dû, à plus !",
            "Parfait, à la prochaine.",
            "Voici, gardez la monnaie.",
        },
        moodHighEnd = {
            "Excellent service, vraiment !",
            "Je vous recommanderai à mes amis.",
            "Conduite exemplaire, bravo.",
        },
        moodLowEnd = {
            "C'était un peu... mouvementé.",
            "Apprenez à conduire.",
            "Je ne reprendrai pas votre taxi.",
        },
    },

    -- ---- Spots de pickup et destinations -------------------
    -- Liste compacte de points GPS plausibles dans Los Santos.
    SpawnPoints = {
        vector3(293.5, -590.2, 42.7),   vector3(253.4, -375.9, 44.1),
        vector3(120.8, -300.4, 45.1),   vector3(-38.4, -381.6, 38.3),
        vector3(-107.4, -614.4, 35.7),  vector3(-252.3, -856.5, 30.6),
        vector3(-236.1, -988.4, 28.8),  vector3(-277.0, -1061.2, 25.7),
        vector3(-576.5, -999.0, 21.8),  vector3(-602.8, -952.6, 21.6),
        vector3(-790.7, -961.9, 14.9),  vector3(-912.6, -864.8, 15.0),
        vector3(-1069.8, -792.5, 18.8), vector3(-1306.9, -854.1, 15.1),
        vector3(-1468.5, -681.4, 26.2), vector3(-1380.9, -452.7, 34.1),
        vector3(-1326.3, -394.8, 36.1), vector3(-1383.7, -270.0, 42.5),
        vector3(-1679.6, -457.3, 39.4), vector3(-1812.5, -416.9, 43.7),
        vector3(-2043.6, -268.3, 23.0), vector3(-2186.4, -421.6, 12.7),
        vector3(-1862.1, -586.5, 11.2), vector3(-1859.5, -617.6, 10.9),
        vector3(-1635.0, -988.3, 12.6), vector3(-1284.0, -1154.2, 5.3),
        vector3(-1126.5, -1338.1, 4.6), vector3(-867.9, -1159.7, 5.0),
        vector3(-722.6, -1144.6, 10.2), vector3(-575.5, -318.4, 34.5),
        vector3(-592.3, -224.9, 36.1),  vector3(-559.6, -162.9, 37.8),
        vector3(-535.0, -65.7, 40.6),   vector3(-758.2, -36.7, 37.3),
        vector3(-1375.9, 21.0, 53.2),   vector3(-1320.3, -128.0, 48.1),
        vector3(-1285.7, 294.3, 64.5),  vector3(-1245.7, 386.5, 75.1),
        vector3(-760.4, 285.0, 85.1),   vector3(-626.8, 254.1, 81.1),
        vector3(-563.6, 268.0, 82.5),   vector3(-486.8, 272.0, 82.8),
        vector3(88.3, 250.9, 108.2),    vector3(234.1, 344.7, 105.0),
        vector3(435.0, 96.7, 99.2),     vector3(482.6, -142.5, 58.2),
        vector3(762.7, -786.5, 25.9),   vector3(809.1, -1290.8, 25.8),
        vector3(490.8, -1751.4, 28.1),  vector3(432.4, -1856.1, 27.0),
        vector3(164.3, -1734.5, 28.9),  vector3(-57.7, -1501.4, 31.1),
        vector3(52.2, -1566.7, 29.0),   vector3(310.2, -1376.8, 31.4),
        vector3(182.0, -1332.8, 28.9),  vector3(-74.6, -1100.6, 25.7),
    },

    -- Spots touristiques pour le tour
    TourPoints = {
        { label = "Vinewood Sign",      pos = vector3(708.3, 1199.0, 351.5) },
        { label = "Maze Bank Tower",    pos = vector3(-72.0, -818.0, 326.2) },
        { label = "Pier de Vespucci",   pos = vector3(-1849.7, -1230.5, 13.0) },
        { label = "Galileo Observatoire",pos = vector3(-438.2, 1083.6, 352.3) },
        { label = "Del Perro Pier",     pos = vector3(-1601.5, -1054.3, 13.1) },
        { label = "Diamond Casino",     pos = vector3(925.8, 46.5, 80.9) },
        { label = "Rockford Plaza",     pos = vector3(-130.3, -670.6, 33.1) },
        { label = "Aéroport LSIA",      pos = vector3(-1037.9, -2737.8, 20.2) },
    },
}
