-- ============================================================================
-- CRIMENET - Standalone Configuration
-- ============================================================================

CrimeNet.Config = {}

-- ============================================================================
-- NETWORK / CONTACTS
-- ============================================================================
CrimeNet.Config.Network = {
    -- Max contacts per player
    maxContacts = 50,
    -- Max groups per player
    maxGroups = 10,
    -- Max members per group chat
    maxGroupMembers = 20,
    -- Max message length
    maxMessageLength = 500,
    -- Max profile description length
    maxDescriptionLength = 200,
    -- Messages loaded per page (pagination)
    messagesPerPage = 30,
    -- How many recent conversations to show
    recentConversations = 20,
}

-- ============================================================================
-- NETWORK GRAPH
-- ============================================================================
CrimeNet.Config.Graph = {
    -- Gang boss grade (highest grade = boss). Players with this grade_name are considered bosses.
    bossGradeNames = { "boss", "chef", "patron", "leader", "king" },
    -- Minimum grade number to be considered a boss (fallback if grade_name doesn't match)
    bossMinGrade = 3,
    -- Show gang clusters in network (group contacts by gang around boss)
    showGangClusters = true,
    -- Show admin-marked important nodes with special styling
    showImportantNodes = true,
}

-- ============================================================================
-- NPC CONTACTS (default branch: L'Intermédiaire → GoFast chain)
-- Everyone gets L'Intermédiaire by default. He introduces the GoFast contacts.
-- Each contact "gives" the next one, forming a chain in the network graph.
-- ============================================================================

-- ============================================================================
-- CONTRACTS (Jobs v2 - GoFast Contract Board)
-- ============================================================================
CrimeNet.Config.Contracts = {
    -- How often to regenerate contracts (minutes)
    refreshInterval = 30,
    -- Base number of contracts available
    baseCount = { solo = 3, crew = 1 },
    -- Additional contracts per 10 players online
    perPlayerCount = { solo = 2, crew = 0.5 },
    -- Max contracts
    maxCount = { solo = 8, crew = 5 },
    -- Contract duration before expiration (minutes)
    contractLifetime = 120,
    -- Reputation penalty for missing a fixed-time contract (XP)
    fixedTimeMissPenalty = 100,
    -- Reputation penalty for failing an accepted contract (XP)
    contractFailPenalty = 50,
    -- XP reward multiplier based on difficulty
    xpMultiplier = 1.0,
    -- Revenue variance (±%)
    revenueVariance = 15,
    
    -- Contract templates by tier/XP
    Templates = {
        -- Tier 1: Beginner (0-200 XP)
        {
            minXP = 0,
            maxXP = 200,
            solo = {
                { label = "Livraison Express", vehicle = "blista", cargo = "~3kg divers", baseRevenue = 3000, difficulty = 1, deadline = 15 },
                { label = "Course Rapide", vehicle = "elegy", cargo = "~5kg herbe", baseRevenue = 5000, difficulty = 2, deadline = 20 },
                { label = "Transport Nuit", vehicle = "sultan", cargo = "~8kg cocaïne", baseRevenue = 7000, difficulty = 3, deadline = 25 },
            },
            crew = {
                { label = "Convoi Léger", vehicle = "bison", cargo = "~15kg mixte", baseRevenue = 12000, difficulty = 4, crewMin = 2, crewMax = 4, deadline = 30 },
            },
            fixedTime = {
                { label = "Drop Minuit", vehicle = "schafter", cargo = "~10kg premium", baseRevenue = 10000, difficulty = 3, deadline = 20, startTime = "00:00" },
            }
        },
        -- Tier 2: Runner (200-600 XP)
        {
            minXP = 200,
            maxXP = 600,
            solo = {
                { label = "Transport Express Nord", vehicle = "sultan", cargo = "~15kg cocaïne", baseRevenue = 8500, difficulty = 3, deadline = 20 },
                { label = "Course Paleto Bay", vehicle = "elegy", cargo = "~8kg herbe", baseRevenue = 5200, difficulty = 2, deadline = 25 },
                { label = "Livraison VIP Downtown", vehicle = "schafter", cargo = "~5kg premium", baseRevenue = 12000, difficulty = 5, deadline = 15 },
            },
            crew = {
                { label = "Convoi Armé Sandy", vehicle = "mule", cargo = "~50kg mixte", baseRevenue = 22000, difficulty = 7, crewMin = 3, crewMax = 6, deadline = 30 },
                { label = "Escorte Lourde", vehicle = "benson", cargo = "~75kg divers", baseRevenue = 30000, difficulty = 8, crewMin = 4, crewMax = 6, deadline = 35 },
            },
            fixedTime = {
                { label = "Opération Minuit", vehicle = "baller", cargo = "~35kg armes", baseRevenue = 35000, difficulty = 9, crewMin = 4, crewMax = 6, deadline = 45, startTime = "22:00" },
            }
        },
        -- Tier 3: Smuggler (600-1500 XP)
        {
            minXP = 600,
            maxXP = 1500,
            solo = {
                { label = "Run Premium", vehicle = "jugular", cargo = "~20kg pure", baseRevenue = 15000, difficulty = 6, deadline = 18 },
                { label = "Transport Discret", vehicle = "f620", cargo = "~12kg documents", baseRevenue = 10000, difficulty = 4, deadline = 22 },
            },
            crew = {
                { label = "Convoi Militaire", vehicle = "barracks2", cargo = "~100kg armes lourdes", baseRevenue = 50000, difficulty = 10, crewMin = 4, crewMax = 8, deadline = 40 },
                { label = "Opération Massive", vehicle = "pounder", cargo = "~200kg divers", baseRevenue = 75000, difficulty = 12, crewMin = 5, crewMax = 8, deadline = 50 },
            },
            fixedTime = {
                { label = "Livraison Royale", vehicle = "xls", cargo = "~50kg premium", baseRevenue = 45000, difficulty = 10, deadline = 30, startTime = "21:00" },
            }
        },
        -- Tier 4: Kingpin (1500+ XP)
        {
            minXP = 1500,
            maxXP = 999999,
            solo = {
                { label = "Mission Élite", vehicle = "toros", cargo = "~30kg royale", baseRevenue = 25000, difficulty = 8, deadline = 15 },
            },
            crew = {
                { label = "Empire Run", vehicle = "mule", cargo = "~300kg empire", baseRevenue = 100000, difficulty = 15, crewMin = 6, crewMax = 10, deadline = 60 },
            },
            fixedTime = {
                { label = "Grand Finale", vehicle = "baller", cargo = "~100kg finale", baseRevenue = 80000, difficulty = 14, crewMin = 6, crewMax = 10, deadline = 45, startTime = "23:00" },
            }
        },
    }
}

CrimeNet.Config.DefaultContact = {
    id = "intermediaire",
    name = "L'Intermédiaire",
    alias = "???",
    avatar = "contact_broker",
    description = "Contact principal du réseau souterrain. Il connaît tout le monde et personne ne le connaît.",
    label = "Courtier",
    messages = {
        intro = "Bienvenue dans le réseau. Je suis ton point d'entrée. Je te mets en contact avec les bonnes personnes.",
    },
}

CrimeNet.Config.NPCContacts = {
    {
        id = "el_conectado",
        name = "El Conectado",
        alias = "???",
        avatar = "contact_shadow",
        description = "Premier contact du réseau. Méfiant mais régulier.",
        label = "GoFast Tier 1",
        unlockXP = 0,
        trustLevel = 1,
        maxTrust = 3,
        givenBy = "intermediaire",  -- introduced by L'Intermédiaire
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
        label = "GoFast Tier 2",
        unlockXP = 200,
        trustLevel = 1,
        maxTrust = 5,
        givenBy = "el_conectado",  -- chain: El Conectado → La Sombra
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
        label = "GoFast Tier 3",
        unlockXP = 600,
        trustLevel = 1,
        maxTrust = 5,
        givenBy = "la_sombra",  -- chain: La Sombra → Don Rafa
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
        label = "GoFast Tier 4",
        unlockXP = 1500,
        trustLevel = 1,
        maxTrust = 5,
        givenBy = "don_rafa",  -- chain: Don Rafa → The Architect
        messages = {
            intro = "Bienvenue au sommet. Ici, chaque erreur se paie cash. En vie.",
            mission = "Opération en cours. Véhicule armé, cargaison pleine. Tu connais la musique.",
            success = "Parfait. Le cartel est satisfait.",
            fail = "Tu viens de signer ton arrêt de mort.",
        },
    },
}
