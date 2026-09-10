--[[
    Admin Module - Client Init
    Structure des données du module admin/staff
]]

-- Namespace admin dans null.data
null.data.admin = {
    --[[
        ============================================
        STAFF
        ============================================
    ]]
    staff = {
        mode = false,           -- Mode staff activé
        identifier = nil,       -- Identifier du staff
        group = "",             -- Groupe staff
        list = {},              -- Liste des staffs en ligne
        listOffline = {},       -- Liste des staffs hors ligne
        top = {},               -- Top staff
        nbrReports = 0,         -- Nombre de reports du staff
    },

    --[[
        ============================================
        REPORTS
        ============================================
    ]]
    reports = {
        list = {},              -- Liste des reports
        countList = {},         -- Compteur par report
        count = 0,              -- Nombre total de reports
        totalCount = 0,         -- Total historique
        noTraiter = 0,          -- Non traités
        takenCount = 0,         -- Reports pris
        source = nil,           -- Source du report actuel
        takenBy = "Personne",   -- Pris par
        taken = false,          -- Est pris
        hideTaken = false,      -- Cacher les reports pris
        hideStaff = false,      -- Cacher les staffs
        sound = true,           -- Son de notification
        notif = true,           -- Notification activée
    },

    --[[
        ============================================
        PLAYERS
        ============================================
    ]]
    players = {
        list = {},              -- Liste des joueurs
        all = {},               -- Tous les joueurs
        selected = {},          -- Joueurs sélectionnés
        selectedAll = {},       -- Tous sélectionnés
        selectedIsCo = false,   -- Sélection connectée
        total = 0,              -- Nombre total
        tableUsers = {},        -- Table des utilisateurs
        byIdU = {},             -- Par ID unique
        page = {
            list = {},          -- Liste paginée
            current = 1,        -- Page actuelle
            total = 0,          -- Nombre de pages
        },
        -- Blacklist des colonnes à ignorer
        blacklistColumns = {
            status = true,
            skin = true,
            permission_level = true,
            eval_staff = true,
            tattoo = true,
            ata = true,
            apps = true,
            widget = true,
            bt = true,
            charinfo = true,
            metadata = true,
            cryptocurrency = true,
            cryptocurrencytransfers = true,
        },
    },

    --[[
        ============================================
        SEARCH
        ============================================
    ]]
    search = {
        active = false,         -- Recherche active
        playerId = {},          -- Résultats par ID
        playerIdUnique = {},    -- Résultats par ID unique
        idUnique = false,       -- Recherche ID unique
        idUniqueResult = nil,   -- Résultat ID unique
        playerSearched = "",    -- Joueur recherché
        group = nil,            -- Groupe recherché
        job = "",               -- Job recherché
        job2 = "",              -- Job2 recherché
        -- Véhicule
        vehicle = {
            plate = false,
            found = false,
            data = nil,
        },
    },

    --[[
        ============================================
        SELECTED PLAYER (joueur inspecté)
        ============================================
    ]]
    selected = {
        source = {},            -- Source du joueur
        idUnique = 0,           -- ID unique
        name = "",              -- Nom
        identifier = "",        -- Identifier
        group = "",             -- Groupe
        job = "",               -- Job 1
        job2 = "",              -- Job 2
        cash = "",              -- Argent liquide
        bank = "",              -- Banque
        black = "",             -- Argent sale
        ranks = "",             -- Rangs
        inventory = {},         -- Inventaire
        weapons = {},           -- Armes
        loadout = {},           -- Loadout
        sanction = {},          -- Sanctions
        sanction2 = {},         -- Sanctions 2
        historique = {},        -- Historique
        pack = {},              -- Pack
        isDead = false,         -- Est mort
    },

    --[[
        ============================================
        BANS
        ============================================
    ]]
    bans = {
        list = {},              -- Liste des bans
        list2 = {},             -- Liste secondaire
        current = {
            id = "",
            name = "",
            sourceName = "",
            license = "",
            reason = "",
            note = "",
        },
        timeOk = false,
        reasonOk = false,
    },

    --[[
        ============================================
        JAIL
        ============================================
    ]]
    jail = {
        list = {},              -- Liste des jails
        inJail = false,         -- En prison
        time = 0,               -- Temps restant
        current = {
            staffName = "",
            license = "",
            reason = "",
            time = 0,
        },
        timeOk = false,
        reasonOk = false,
        finish = false,
    },

    --[[
        ============================================
        VEHICLES
        ============================================
    ]]
    vehicles = {
        list = {},              -- Liste des véhicules
        sell = {},              -- Véhicules à vendre
        current = {
            owner = "",
            plate = "",
            vehicle = {},
            model = "",
            type = "",
            state = 0,
            label = "",
            boutique = 0,
        },
        hideVhBoutique = false,
        hideVhNoBoutique = false,
    },

    --[[
        ============================================
        ECONOMY
        ============================================
    ]]
    economy = {
        total = 0,
        cash = 0,
        bank = 0,
        black = 0,
        cashList = {},
        loaded = false,
    },

    --[[
        ============================================
        TENUES / SKINS
        ============================================
    ]]
    tenues = {
        list = {},
        current = {
            id = 0,
            name = "",
            skin = {},
        },
        filter = nil,
    },

    --[[
        ============================================
        ACCESSORIES
        ============================================
    ]]
    accessories = {
        list = {},
        current = {
            id = 0,
            name = "",
            type = "",
            skin = {},
        },
        filter = nil,
    },

    --[[
        ============================================
        WEAPONS
        ============================================
    ]]
    weapons = {
        all = {},               -- Toutes les armes
        list = {},              -- Liste filtrée
        current = {
            name = "",
            hash = "",
        },
        filter = nil,
        onlyAll = 1,
    },

    --[[
        ============================================
        ITEMS
        ============================================
    ]]
    items = {
        all = {},               -- Tous les items
        list = {},              -- Liste filtrée
        created = {},           -- Items créés
        filter = nil,
        onlyAll = 1,
    },

    --[[
        ============================================
        JOBS
        ============================================
    ]]
    jobs = {
        all = {},               -- Tous les jobs
        grades = {},            -- Tous les grades
        filter = 1,             -- 1 = Job1, 2 = Job2
    },

    --[[
        ============================================
        ZONES
        ============================================
    ]]
    zones = {
        show = false,           -- Afficher les zones
        safe = {
            list = {},
            selected = {},
            filter = nil,
            creating = { points = {} },
        },
        territories = {},
        territoriesShop = {},
        gang = {
            creating = {},
            index = 1,
            types = { "Gang", "Organisation", "Cartel" },
        },
    },

    --[[
        ============================================
        MARKERS / BLIPS
        ============================================
    ]]
    markers = {
        show = false,
        job = nil,
        action = nil,
        name = nil,
        nameNoSpace = nil,
        vector3 = nil,
        blip = {
            color = "",
            sprite = "",
            name = "",
        },
    },

    --[[
        ============================================
        ENTREPRISES
        ============================================
    ]]
    entreprises = {
        list = {},
        list2 = {
            ["Mécano"] = {},
            ["Bar"] = {},
            ["Ambulance"] = {},
            ["Police"] = {},
            ["Farm"] = {},
            ["Restaurant"] = {},
        },
        selected = nil,
        teleportIndex = 1,
        teleportList = {},
    },

    --[[
        ============================================
        GARAGES
        ============================================
    ]]
    garages = {
        list = {},
        selected = {},
        blipShow = false,
    },

    --[[
        ============================================
        ELEVATORS
        ============================================
    ]]
    elevators = {
        list = {},              -- AscenseurList
        selected = nil,
        creating = { positions = {} },
    },

    --[[
        ============================================
        SPECIAL EVENTS
        ============================================
    ]]
    events = {
        braquage = {
            demandes = {},
            brinks = {},
            attente = {},
        },
        camion = {
            props = {},
            posBlinder = nil,
        },
        tirAppels = false,
        blackout = true,
    },

    --[[
        ============================================
        STREAMERS
        ============================================
    ]]
    streamers = {
        connected = {},
        list = {},
        mode = false,
    },

    --[[
        ============================================
        HISTORIQUE
        ============================================
    ]]
    historique = {
        decoReco = {},
        evalStaff = {},
    },

    --[[
        ============================================
        UI STATE (états des menus/listes)
        ============================================
    ]]
    ui = {
        -- Index des listes
        indexes = {
            list1 = 1, list2 = 1, list3 = 1, list4 = 1,
            list5 = 1, list6 = 1, list7 = 1, list8 = 1,
            list9 = 1, list10 = 1, list11 = 1, list12 = 1,
            list13 = 1, list14 = 1,
            color = { 1, 1, 1 },
            typeInfo = 4,
            actionDirt = 1,
        },
        -- Filtres actifs
        filters = {
            letter = nil,
            hidePlayers = false,
            objectUniqueId = false,
        },
        -- Actions sélectionnées
        action = {
            selected = {},
            label = "",
            hasSelected = false,
            current = "",
        },
    },

    --[[
        ============================================
        PLAYER ABILITIES (pouvoirs staff)
        ============================================
    ]]
    abilities = {
        noclip = false,
        superjump = false,
        supersprint = false,
        noragdoll = false,
        invincible = false,
        invisible = false,
        freeze = false,
        vehicleFreeze = false,
        vehicleInvisible = false,
        delgun = false,
        spawncar = false,
        spectate = false,
        inSpectate = false,
        gamerTag = false,
        gamerTag2 = false,
        gamerTag3 = false,
        gamerTagAdvanced = false,
        blipActive = false,
        illegalBlips = false,
        gangBlip = false,
        garageBlip = false,
        adminHud = false,
        adminHudOk = false,
        staffTenu = false,
        isPeds = false,
        objets = false,
        fonda = false,
    },

    --[[
        ============================================
        LISTS (listes statiques pour les menus)
        ============================================
    ]]
    lists = {
        filterArray = { "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" },
        refreshPlayer = { "Recherche ID", "Refresh la liste" },
        recherche = { "ID", "ID Uniques", "Nom" },
        giveType = { "Argent liquide", "Argent en banque", "Argent sale", "PPA", "Permis de conduire" },
        histoSanction = { "Jail", "Warn", "Kick", "Ban" },
        wipe = { "Inventaire", "Armes", "Véhicules", "Général" },
        weaponType = { "Blanche", "Pistolet", "Fusil d'assault", "Mitraillette", "Arme lourde" },
        jobFilter = { "Job 1", "Job 2" },
        vehSpeed = { "Désactiver", "x16", "x32", "x64", "x128", "x256", "x1024" },
        tenue = { "Equiper", "Retirer" },
        annonce = { "Annonce", "Annonce Staff", "Reboot" },
        vehColor = { "Rouge", "Bleu", "Noir", "Orange", "Blanc" },
        actionDirt = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15" },
    },

    --[[
        ============================================
        DRUGS / LABORATORIES (création)
        ============================================
    ]]
    drugs = {
        creating = {
            laboratory = {
                active = false,
                list = {},  -- À remplir avec les templates
            },
        },
    },

    --[[
        ============================================
        CELLULES (prison)
        ============================================
    ]]
    cellules = {},

    --[[
        ============================================
        FARM
        ============================================
    ]]
    farm = {
        playersIn = {},
    },

    --[[
        ============================================
        ATA (All Ata)
        ============================================
    ]]
    ata = {},
}

-- Alias pour compatibilité (à supprimer progressivement)
-- nTable = null.data.admin

--null.InitPrint('Admin Data structure initialized')
