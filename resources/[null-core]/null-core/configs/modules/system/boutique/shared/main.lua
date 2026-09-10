Config = Config or {}

Config.Boutique = {
    ActivePacks = true,
    ActiveWeapons = true,
    ActiveVehicles = true,
    ActiveBoosts = true,
    ActiveCrates = false,
    ActiveHistoBoutique = true,

    Packs = {
        ["entreprise"] = {
            index = 1,
            label = "Création d'entreprise",
            description = "Disponible pour les entreprises : Restaurants, Farmers, Bars, Mécanos.",
            info = {'Ce pack contient', {'Points :'}, {'Coffre,Recolte,Traitement,Vente'}},
            info2 = {
                ["Pour les Bars : "] = "Vestiaire, Bar, Patron",
                ["Pour les Farmers : "] = "Vestiaire, Récolte, Traitement, Vente, Patron",
                ["Pour les Mécanos : "] = "Vestiaire, 3 Points de customisation, Patron",
                ["Pour les Restaurants : "] = "Vestiaire, Cusine, Stockage, Patron",
            },
            price = 7500,
        },
        ["gang"] = {
            index = 2,
            label="Création d'un gang/organisation",
            description=nil,
            info={'Ce pack contient', {'Points :', 'Emplacement :'}, {'Coffre', 'QG/Villa ou quartier'}},
            info2 = {
                ["Emplacement : "] = "QG/Villa ou Quartier",
                ["Points : "] = "Coffre",
            },
            price = 5000,
        },
        --[[["deplacement"] = {
            index = 3,
            label="Déplacement Gang/Organisation",
            description="Déplacement de votre QG de gang/organisation",
            info=nil,
            price = 3000,
        },]]
        --[[["bunker"] = {
            index = 4,
            label="Bunker Gang/Organisation",
            description="Accès a un Bunker pour votre Gang/Organisation",
            info=nil,
            price = 1500,
        },]]
        ["veh-unique"] = {
            index = 3,
            label="Véhicule au Choix",
            description="Choisis un véhicule au choix\nFaites un ticket après achat",
            info=nil,
            price = 20000,
        },
        -- ["Basic"] = {
        --     index = 4,
        --     label="VIP Basic ( 1 mois)",
        --     description="Voir les informations sur la boutique",
        --     info=nil,
        --     price = 1000,
        -- },
        -- ["Premium"] = {
        --     index = 5,
        --     label="VIP Premium ( 1 mois)",
        --     description="Voir les informations sur la boutique",
        --     info=nil,
        --     price = 2500,
        -- },
    },
    
    Weapons = {
        {
            label = 'AK-47', 
            stats = {
                ["Cadence de tire"] = 6,
                ["Dégats"] = 7,
                ["Distance"] = 7,
                ["Nombre de balles"] = 7,
                ["Durabilité"] = 7,
            },
            name = 'WEAPON_ASSAULTRIFLE', 
            description = "Le fusil d'assaut le plus célèbre au monde. Précis, puissant et redoutablement fiable.", 
            price = 5000,
            cells = 8,
            size = "featured"
        },
        {
            label = 'Gusenberg', 
            name = 'WEAPON_GUSENBERG', 
            stats = {
                ["Cadence de tire"] = 8,
                ["Dégats"] = 6,
                ["Distance"] = 6,
                ["Nombre de balles"] = 8,
                ["Durabilité"] = 6,
            },
            description = "Puissant et avec un grand chargeur", 
            price = 3500,
            cells = 4,
            size = "large"
        },
        --{
        --    label = 'Arme de défense Personnel', 
        --    name = 'WEAPON_COMBATPDW', 
        --    description = nil, 
        --    price = 2500
        --},
        -- {
        --     label = 'Glock-17', 
        --     name = 'WEAPON_GLOCK', 
        --     stats = {
        --         ["Cadence de tire"] = 1,
        --         ["Dégats"] = 5,
        --         ["Distance"] = 4,
        --         ["Nombre de balles"] = 3,
        --         ["Durabilité"] = 7,
        --     },
        --     description = "Pistolet avec une grande durabilitée", 
        --     price = 1200
        -- },
        --{
        --    label = 'Katana', 
        --    name = 'WEAPON_KATANA', 
        --    description = nil, 
        --    price = 450
        --},
    },
    
    -- elegyxa19/elegyxa19ven dubmono
    
    Vehicles = {
        -- {
        --     label = '', 
        --     model = '', 
        --     stats = {
        --         ["Vitesse"] = 0,
        --         ["Freinage"] = 0,
        --         ["Maniabiliter"] = 0,
        --         ["Tout terrains"] = 0,
        --         ["0-100 km/h"] = 0,
        --     },
        --     description = "", 
        --     price = 2000
        -- },
        -- {
        --     label = 'V250', 
        --     model = 'v250', 
        --     stats = {
        --         ["Vitesse"] = 5,
        --         ["Freinage"] = 4,
        --         ["Maniabiliter"] = 5,
        --         ["Tout terrains"] = 2,
        --         ["0-100 km/h"] = 4,
        --     },
        --     description = "Van spacieux et confortable", 
        --     price = 900
        -- },
        -- {
        --     label = 'MT125', 
        --     model = 'mt125', 
        --     stats = {
        --         ["Vitesse"] = 5,
        --         ["Freinage"] = 4,
        --         ["Maniabiliter"] = 5,
        --         ["Tout terrains"] = 2,
        --         ["0-100 km/h"] = 4,
        --     },
        --     description = "Moto légère et agile", 
        --     price = 800
        -- },
        {
            label = 'Sent Wide', 
            model = 'sent5wide', 
            stats = {
                ["Vitesse"] = 10,
                ["Freinage"] = 3,
                ["Maniabiliter"] = 3,
                ["Tout terrains"] = 3,
                ["0-100 km/h"] = 10,
            },
            description = "MaxV: 220 Force: 0.55 Frein: 1.20", 
            price = 10000,
            cells = 8,
            size = "featured"
        },
        {
            label = 'Kuruma X', 
            model = 'kurxa19', 
            stats = {
                ["Vitesse"] = 9,
                ["Freinage"] = 8,
                ["Maniabiliter"] = 8,
                ["Tout terrains"] = 3,
                ["0-100 km/h"] = 8,
            },
            description = "MaxV: 183 Force: 0.45 Frein: 1.00", 
            price = 6000,
            cells = 4,
            size = "large"
        },
        {
            label = 'Turismo Gt3', 
            model = 'turisgt3', 
            stats = {
                ["Vitesse"] = 8,
                ["Freinage"] = 7,
                ["Maniabiliter"] = 7,
                ["Tout terrains"] = 3,
                ["0-100 km/h"] = 7,
            },
            description = "MaxV: 153 Force: 0.37 Frein: 1.19", 
            price = 3500,
            cells = 4,
            size = "large"
        },
        {
            label = 'Sr8', 
            model = 'sr8', 
            stats = {
                ["Vitesse"] = 8,
                ["Freinage"] = 7,
                ["Maniabiliter"] = 7,
                ["Tout terrains"] = 3,
                ["0-100 km/h"] = 7,
            },
            description = "MaxV: 170 Force: 0.40 Frein: 1.20", 
            price = 3500
        },
        {
            label = 'Sr Hatch', 
            model = 'srspback', 
            stats = {
                ["Vitesse"] = 8,
                ["Freinage"] = 7,
                ["Maniabiliter"] = 7,
                ["Tout terrains"] = 3,
                ["0-100 km/h"] = 7,
            },
            description = "MaxV: 180 Force: 0.35 Frein: 1.20", 
            price = 3500
        },
        {
            label = 'Jubilee Offroad', 
            model = 'kcjub', 
            stats = {
                ["Vitesse"] = 8,
                ["Freinage"] = 7,
                ["Maniabiliter"] = 7,
                ["Tout terrains"] = 6,
                ["0-100 km/h"] = 7,
            },
            description = "MaxV: 150 Force: 0.40 Frein: 1.00", 
            price = 3500
        },
        {
            label = 'Comet Noire', 
            model = 'cometnor', 
            stats = {
                ["Vitesse"] = 6,
                ["Freinage"] = 6,
                ["Maniabiliter"] = 6,
                ["Tout terrains"] = 3,
                ["0-100 km/h"] = 5,
            },
            description = "MaxV: 156 Force: 0.35 Frein: 0.88", 
            price = 2000
        },
        {
            label = 'Bf Club R', 
            model = 'clubr', 
            stats = {
                ["Vitesse"] = 6,
                ["Freinage"] = 6,
                ["Maniabiliter"] = 6,
                ["Tout terrains"] = 3,
                ["0-100 km/h"] = 5,
            },
            description = "MaxV: 180 Force: 0.35 Frein: 0.88", 
            price = 2000
        },
        {
            label = 'R300 Hycade', 
            model = 'hycr300', 
            stats = {
                ["Vitesse"] = 6,
                ["Freinage"] = 6,
                ["Maniabiliter"] = 6,
                ["Tout terrains"] = 3,
                ["0-100 km/h"] = 5,
            },
            description = "MaxV: 151 Force: 0.33 Frein: 0.78", 
            price = 2000
        },
        {
            label = 'Entity Mt Hycade', 
            model = 'hycenty', 
            stats = {
                ["Vitesse"] = 6,
                ["Freinage"] = 6,
                ["Maniabiliter"] = 6,
                ["Tout terrains"] = 3,
                ["0-100 km/h"] = 5,
            },
            description = "MaxV: 172 Force: 0.35 Frein: 1.00", 
            price = 2000
        },
        {
            label = 'Carbon Club', 
            model = 'clubc', 
            stats = {
                ["Vitesse"] = 5,
                ["Freinage"] = 4,
                ["Maniabiliter"] = 5,
                ["Tout terrains"] = 2,
                ["0-100 km/h"] = 4,
            },
            description = "MaxV: 140 Force: 0.24 Frein: 0.72", 
            price = 1000
        },
    },
    Boosts = {
        [1] = {
            label = "Boost Global x2 ( 1 jour )", 
            price = 1500, 
            time = 24, 
            activeBoost = {
                harvest = 2, 
                processing = 2, 
                sell = 2, 
                hunting = 2, 
                drugs = 2, 
                worksite = 2
            }
        },
        [2] = {
            label = "Boost Global x2 ( 2 jours )", 
            price = 3000, 
            time = 48, 
            activeBoost = {
                harvest = 2, 
                processing = 2, 
                sell = 2, 
                hunting = 2, 
                drugs = 2, 
                worksite = 2
            }
        },
        [3] = {
            label = "Boost Global x2 ( 4 jours )", 
            price = 6000, 
            time = 96, 
            activeBoost = {
                harvest = 2, 
                processing = 2, 
                sell = 2, 
                hunting = 2, 
                drugs = 2, 
                worksite = 2
            }
        },
        [4] = {
            label = "Boost Global x2 ( 7 jours )", 
            price = 10000, 
            time = 168, 
            activeBoost = {
                harvest = 2, 
                processing = 2, 
                sell = 2, 
                hunting = 2, 
                drugs = 2, 
                worksite = 2
            }
        },
        [5] = {
            label = "Boost Global x2 ( 14 jours )", 
            price = 18000, 
            time = 336, 
            activeBoost = {
                harvest = 2, 
                processing = 2, 
                sell = 2, 
                hunting = 2, 
                drugs = 2, 
                worksite = 2
            }
        },
        [6] = {
            label = "Boost Global x2 ( 30 jours )", 
            price = 24000, 
            time = 720, 
            activeBoost = {
                harvest = 2, 
                processing = 2, 
                sell = 2, 
                hunting = 2, 
                drugs = 2, 
                worksite = 2
            }
        },
    },

    Crates = {
        Chances = {
            Ultime = 5,
            Legendary = 15,
            Rare = 30,
            
        },
        List = {
            -- ['caisse_gold'] = {
            --     position = 1,
            --     price = 500,
            --     five = 2250,
            --     teen = 4500,
            --     model = "caisse_gold",
            --     label = 'Caisse Gold',

            --     Inside = {
            --         { model = "mt125", typeLot = "vehicle", label = "MT125", rarity = 1},
            --         { model = "v250", typeLot = "vehicle", label = "V250", rarity = 1},
            --         { model = "smc690", typeLot = "vehicle", label = "Smc690", rarity = 1},
            --         { model = "ren_clio_5", typeLot = "vehicle", label = "Renault Clio 5", rarity = 1},
            --         { model = "mxrb", typeLot = "vehicle", label = "Mxrb", rarity = 1},
            --         { model = "cayenne", typeLot = "vehicle", label = "Cayenne", rarity = 1},
            --         { model = "money_250000", typeLot = "money", amount = 250000, label = "250 000$", rarity = 1},
            --         --
            --         { model = "passat", typeLot = "vehicle", label = "Passat", rarity = 2},
            --         { model = "rs3", typeLot = "vehicle", label = "Audi Rs3", rarity = 2},
            --         { model = "twingo", typeLot = "vehicle", label = "Twingo", rarity = 2},
            --         { model = "gle450", typeLot = "vehicle", label = "Gle 450", rarity = 2},
            --         { model = "190e", typeLot = "vehicle", label = "190e", rarity = 2},
            --         { model = "cla45sb2", typeLot = "vehicle", label = "Cla45s", rarity = 2},
            --         --
            --         { model = "money_750000", typeLot = "money", amount = 750000, label = "750 000$", rarity = 3},
            --         { model = "sciroccobyv", typeLot = "vehicle", label = "Scirocco", rarity = 3},
            --         { model = "demonhawk", typeLot = "vehicle", label = "Demonhawk", rarity = 3},
            --         { model = "a45", typeLot = "vehicle", label = "A45", rarity = 3},
            --         { model = "bmci", typeLot = "vehicle", label = "Bmci", rarity = 3},
            --         { model = "ghis2", typeLot = "vehicle", label = "Ghis", rarity = 3},
            --         --
            --         { model = "coins_500", typeLot = "Coins", amount = 500, label = "500 Coins", rarity = 4},
            --         { model = "serv_electricscooter", typeLot = "vehicle", label = "Electric Scooter", rarity = 4},
            --         { model = "WEAPON_PISTOL_MK2", typeLot = "weapon", label = "Pistol MK2", rarity = 4},
            --     }
            -- },
            -- ['caisse_diamond'] = {
            --     position = 2,
            --     price = 1000,
            --     five = 4750,
            --     teen = 9500,
            --     model = "caisse_diamond",
            --     label = 'Caisse Légendaire',

            --     Inside = {
            --         { model = "xp210", typeLot = "vehicle", label = "Toyota Yaris", rarity = 1},
            --         { model = "tw_b330i22", typeLot = "vehicle", label = "BMW 330i", rarity = 1},
            --         { model = "rx7tunable", typeLot = "vehicle", label = "RX7Tunable", rarity = 1},
            --         { model = "rmodi8mlb", typeLot = "vehicle", label = "BMW i8", rarity = 1},
            --         { model = "gle", typeLot = "vehicle", label = "Mercedes GLE", rarity = 1},
            --         { model = "money_250000", typeLot = "money", amount = 250000, label = "250 000$", rarity = 1},
            --         --
            --         { model = "p206gti", typeLot = "vehicle", label = "206 GTI", rarity = 2},
            --         { model = "lp700", typeLot = "vehicle", label = "LP 700", rarity = 2},
            --         { model = "bmwm8c", typeLot = "vehicle", label = "BMW M8C", rarity = 2},
            --         { model = "raptor150", typeLot = "vehicle", label = "Raptor 150", rarity = 2},
            --         { model = "rmodpanamera2", typeLot = "vehicle", label = "Panamera", rarity = 2},
            --         { model = "velarbyv", typeLot = "vehicle", label = "Velar", rarity = 2},
            --         { model = "rmodrs5", typeLot = "vehicle", label = "Audi Rs5", rarity = 2},
            --         { model = "rs3s20", typeLot = "vehicle", label = "Rs3s 2020", rarity = 2},
            --         { model = "a_c_chop", typeLot = "animal", label = "Chop", rarity = 2},
            --         --
            --         { model = "money_750000", typeLot = "money", amount = 750000, label = "750 000$", rarity = 3},
            --         { model = "gls63_de_dmz", typeLot = "vehicle", label = "Gls63", rarity = 3},
            --         { model = "brabus500", typeLot = "vehicle", label = "Brabus500", rarity = 3},
            --         { model = "m3touring22", typeLot = "vehicle", label = "M3 Touring", rarity = 3},
            --         { model = "zx10r", typeLot = "vehicle", label = "Zxr", rarity = 3},
            --         { model = "roma22", typeLot = "vehicle", label = "Ferrari Roma", rarity = 3},
            --         { model = "coins_500", typeLot = "Coins", amount = 500, label = "500 Coins", rarity = 3},
            --         --
            --         --{ model = "WEAPON_AKS74U", typeLot = "weapon", label = "Aks74u", rarity = 4},
            --         { model = "WEAPON_SCAR17FM", typeLot = "weapon", label = "Scar-17", rarity = 4},
            --         { model = "WEAPON_REDL", typeLot = "weapon", label = "Ak RedLight", rarity = 4},
            --         { model = "WEAPON_BLASTAK", typeLot = "weapon", label = "AK Blastak", rarity = 4},
            --         { model = "WEAPON_BLACKSNIPER", typeLot = "weapon", label = "Sniper Dragon", rarity = 4},
            --         { model = "WEAPON_DOUBLEBARRELFM", typeLot = "weapon", label = "Double Barrel", rarity = 4},
            --         { model = "savage", typeLot = "helico", label = "Savage", rarity = 4},
            --         { model = "buzzard2", typeLot = "helico", label = "Buzzard2", rarity = 4},
            --         { model = "luxor2", typeLot = "helico", label = "Luxor Gold", rarity = 4},
            --         { model = "cargobob2", typeLot = "helico", label = "Cargobob", rarity = 4},
            --     }
            -- },
            -- ['caisse_ruby'] = {
            --     position = 3,
            --     price = 2000,
            --     five = 9000,
            --     teen = 18000,
            --     model = "caisse_ruby",
            --     label = 'Caisse Ultime',

            --     Inside = {
            --         { model = "f812", typeLot = "vehicle", label = "Ferrari F812", rarity = 1},
            --         { model = "money_5000000", typeLot = "money", amount = 5000000, label = "5 000 000$", rarity = 1},
            --         { model = "nismo20", typeLot = "vehicle", label = "Nissan GTR Nismo", rarity = 1},
            --         { model = "rmodmustang", typeLot = "vehicle", label = "Ford Mustang Custom", rarity = 1},
            --         { model = "rmodm8c", typeLot = "vehicle", label = "BMW M8 Cabriolet", rarity = 1},
            --         { model = "rs7c8wb", typeLot = "vehicle", label = "RS7 Satan", rarity = 1},
            --         --
            --         { model = "coins_1000", typeLot = "Coins", amount = 1000, label = "1000 Coins", rarity = 2},
            --         { model = "mansm8", typeLot = "vehicle", label = "M8 Mansory", rarity = 2},
            --         { model = "aventador", typeLot = "vehicle", label = "Lamborgini Aventador", rarity = 2},
            --         { model = "svr14", typeLot = "vehicle", label = "Rover SVR Mansory", rarity = 2},
            --         { model = "rmodlp670", typeLot = "vehicle", label = "LP 670 Liberty Walk", rarity = 2},
            --         { model = "rmodr8c", typeLot = "vehicle", label = "Audi R8 Cabriolet", rarity = 2},
            --         --
            --         { model = "money_9500000", typeLot = "money", amount = 9500000, label = "9 500 000$", rarity = 3},
            --         { model = "gt2rsmr", typeLot = "vehicle", label = "Porsches GT2RS", rarity = 3},
            --         { model = "trx", typeLot = "vehicle", label = "Dodge Ram TRX", rarity = 3},
            --         { model = "m3g80", typeLot = "vehicle", label = "BMW M3 G80", rarity = 3},
            --         { model = "sf90", typeLot = "vehicle", label = "Ferrari SF90", rarity = 3},
            --         { model = "venatusc", typeLot = "vehicle", label = "Urus Mansory", rarity = 3},
            --         { model = "amggtsmansory", typeLot = "vehicle", label = "AMG GTS Mansory", rarity = 3},
            --         { model = "highmare", typeLot = "vehicle", label = "Mystery Machine", rarity = 3},
            --         --
            --         { model = "coins_1500", typeLot = "Coins", amount = 1500, label = "1500 Coins", rarity = 4},
            --         { model = "fxxk", typeLot = "vehicle", label = "Ferrari FXX K", rarity = 4},
            --         { model = "WEAPON_PREDATOR", typeLot = "weapon", label = "M4 Predator", rarity = 4},
            --         { model = "WEAPON_HEAVYSNIPER_MK2", typeLot = "weapon", label = "Sniper Lourd", rarity = 4},
            --         { model = "WEAPON_HKUMP", typeLot = "weapon", label = "HKUMP", rarity = 4},
            --         { model = "WEAPON_COMBATMG", typeLot = "weapon", label = "Combat MG", rarity = 4},
            --         { model = "WEAPON_BLACKSNIPER", typeLot = "weapon", label = "HK417", rarity = 4},
            --         { model = "WEAPON_SCAR17FM", typeLot = "weapon", label = "SCAR-17", rarity = 4},
            --         { model = "savage", typeLot = "helico", label = "Savage", rarity = 4},
            --         { model = "velociraptor", typeLot = "vehicle", label = "Velociraptor", rarity = 4},
            --         { model = "buzzard2", typeLot = "helico", label = "Buzzard", rarity = 4},
            --         { model = "cargobob2", typeLot = "helico", label = "Cargobob", rarity = 4},
            --         { model = "luxor2", typeLot = "helico", label = "Luxor", rarity = 4},
            --     }
            -- },
            -- ['caisse_fidelite'] = {
            --     position = 4,
            --     price = -1,
            --     buyable = false,
            --     five = -1,
            --     teen = -1,
            --     model = "caisse_fidelite",
            --     label = 'Caisse Fidelité',

            --     Inside = {
            --         { model = "money_250000", typeLot = "money", label = "250 000$", amount = 250000, rarity = 1},
            --         { model = "money_750000", typeLot = "money", label = "750 000$", amount = 750000, rarity = 1},
            --         { model = "money_150000", typeLot = "money", label = "250 000$", amount = 150000, rarity = 1},
            --         { model = "money_500000", typeLot = "money", label = "500 000$", amount = 500000, rarity = 1},
            --         { model = "velarbyv", typeLot = "vehicle", label = "Velar", rarity = 1},
            --         --
            --         { model = "p206gti", typeLot = "vehicle", label = "206 GTI", rarity = 2},
            --         { model = "multipla", typeLot = "vehicle", label = "Multipla", rarity = 2},
            --         { model = "twingo", typeLot = "vehicle", label = "Multipla", rarity = 2},
            --         { model = "coins_500", typeLot = "Coins", amount = 500, label = "500 Coins", rarity = 2},
            --         --
            --         { model = "4rune", typeLot = "vehicle", label = "TRD PRO", rarity = 3},
            --         { model = "kangoo", typeLot = "vehicle", label = "Kangoo", rarity = 3},
            --         { model = "rmodi8mlb", typeLot = "vehicle", label = "BMW i8", rarity = 3},
            --         --
            --         { model = "WEAPON_SCAR17FM", typeLot = "weapon", label = "Scar17", rarity = 4},
            --         { model = "coins_1000", typeLot = "Coins", amount = 1000, label = "1000 Coins", rarity = 4},
            --         { model = "savage", typeLot = "helico", label = "Savage", rarity = 4},
            --         { model = "buzzard2", typeLot = "helico", label = "Buzzard2", rarity = 4},
            --         { model = "luxor2", typeLot = "helico", label = "Luxor Gold", rarity = 4},
            --         { model = "cargobob2", typeLot = "helico", label = "Cargobob", rarity = 4},
            --     }
            -- },
            -- ['caisse_afk_gold'] = {
            --     position = 5,
            --     price = -1,
            --     buyable = false,
            --     preview = false,
            --     five = -1,
            --     teen = -1,
            --     model = "caisse_afk_gold",
            --     label = 'Caisse Afk Gold',

            --     Inside = {
            --         { model = "bread", typeLot = "item", label = "50 pains", amount = 50, rarity = 1},
            --         { model = "water", typeLot = "item", label = "50 bouteilles d'eau", amount = 50, rarity = 1},
            
            --         { model = "money_25000", typeLot = "money", label = "25 000$", amount = 25000, rarity = 2},
            --         { model = "money_50000", typeLot = "money", label = "50 000$", amount = 50000, rarity = 2},
            --         --
            --         { model = "money_100000", typeLot = "money", label = "100 000$", amount = 100000, rarity = 3},
            --         { model = "money_250000", typeLot = "money", label = "250 000$", amount = 250000, rarity = 3},
            --         { model = "money_500000", typeLot = "money", label = "500 000$", amount = 500000, rarity = 3},
            --         { model = "WEAPON_PISTOL", typeLot = "weapon", label = "Pistolet", rarity = 3},
            --         --
            --         { model = "money_1000000", typeLot = "money", label = "1 000 000$", amount = 1000000, rarity = 4},
            --         { model = "WEAPON_MICROSMG", typeLot = "weapon", label = "Micro Uzi", rarity = 4},
            --         { model = "caisse_gold", typeLot = "item", label = "Caisse Gold", amount = 1, rarity = 4},
            --     }
            -- },
            -- ['caisse_afk_legendaire'] = {
            --     position = 6,
            --     price = -1,
            --     buyable = false,
            --     preview = false,
            --     five = -1,
            --     teen = -1,
            --     model = "caisse_afk_legendaire",
            --     label = 'Caisse Afk Légendaire',

            --     Inside = {
            --         { model = "bread", typeLot = "item", label = "100 pains", amount = 100, rarity = 1},
            --         { model = "water", typeLot = "item", label = "100 bouteilles d'eau", amount = 100, rarity = 1},
            
            --         { model = "money_100000", typeLot = "money", label = "100 000$", amount = 100000, rarity = 2},
            --         { model = "money_250000", typeLot = "money", label = "250 000$", amount = 250000, rarity = 2},
            --         --
            --         { model = "money_750000", typeLot = "money", label = "750 000$", amount = 750000, rarity = 3},
            --         { model = "money_1000000", typeLot = "money", label = "1 000 000$", amount = 1000000, rarity = 3},
            --         { model = "WEAPON_MICROSMG", typeLot = "weapon", label = "Micro Uzi", rarity = 3},
            --         --
            --         { model = "money_3000000", typeLot = "money", label = "3 000 000$", amount = 3000000, rarity = 4},
            --         { model = "WEAPON_COMPACTRIFLE", typeLot = "weapon", label = "AK Compact", rarity = 4},
            --         { model = "velociraptor", typeLot = "vehicle", label = "Velociraptor", rarity = 4},
            --         { model = "a45", typeLot = "vehicle", label = "A45", rarity = 4},
            --         { model = "caisse_gold", typeLot = "item", label = "Caisse Gold", amount = 1, rarity = 4},
            --         { model = "caisse_diamond", typeLot = "item", label = "Caisse Légendaire", amount = 1, rarity = 4},
            --     }
            -- },
        },
    },

    DailyShopPool = {
        vehicles = {
            -- { model = "mt125", label = "MT125", description = "Moto légère et agile", rarity = "common", basePrice = 800 },
            -- { model = "v250", label = "V250", description = "Van spacieux et confortable", rarity = "common", basePrice = 900 },
            -- { model = "smc690", label = "SMC 690", description = "Supermotard puissant", rarity = "common", basePrice = 1000 },
            -- { model = "passat", label = "Passat", description = "Berline familiale", rarity = "rare", basePrice = 1500 },
            -- { model = "rs3", label = "Audi RS3", description = "Compacte sportive", rarity = "rare", basePrice = 2000 },
            -- { model = "gle450", label = "GLE 450", description = "SUV premium", rarity = "rare", basePrice = 2200 },
            -- { model = "cla45sb2", label = "CLA 45S", description = "Berline sportive AMG", rarity = "rare", basePrice = 2500 },
            -- { model = "sciroccobyv", label = "Scirocco", description = "Coupé sportif", rarity = "epic", basePrice = 3000 },
            -- { model = "demonhawk", label = "Demonhawk", description = "Muscle car démoniaque", rarity = "epic", basePrice = 3500 },
            -- { model = "bmci", label = "BMCi", description = "Coupé électrique", rarity = "epic", basePrice = 3200 },
            -- { model = "a45", label = "A45 AMG", description = "Compacte surpuissante", rarity = "epic", basePrice = 3800 },
            -- { model = "brabus500", label = "Brabus 500", description = "SUV tuné par Brabus", rarity = "legendary", basePrice = 5000 },
            -- { model = "m3touring22", label = "M3 Touring", description = "Break sportif ultime", rarity = "legendary", basePrice = 5500 },
            -- { model = "roma22", label = "Ferrari Roma", description = "GT italienne élégante", rarity = "legendary", basePrice = 6000 },
            -- { model = "gt2rsmr", label = "Porsche GT2RS", description = "Supercar allemande", rarity = "legendary", basePrice = 7000 },
            -- { model = "sf90", label = "Ferrari SF90", description = "Hypercar hybride", rarity = "ultimate", basePrice = 10000 },
            -- { model = "fxxk", label = "Ferrari FXX K", description = "Hypercar de circuit", rarity = "ultimate", basePrice = 12000 },
            -- { model = "velociraptor", label = "Velociraptor", description = "Pick-up extrême", rarity = "ultimate", basePrice = 9000 },


            { model = "abfbuff", label = "Buffalo Wide", description = "MaxV: 170 Force: 0.36 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "ballvenm", label = "Baller Venuum", description = "MaxV: 170 Force: 0.40 Frein: 2.00", rarity = "legendary", basePrice = 6000 },
            { model = "briosoav", label = "Brioso X", description = "MaxV: 175 Force: 0.35 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "cazador", label = "Cazador", description = "MaxV: 176 Force: 0.31 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "cazadortcr", label = "Cazador Tcr", description = "MaxV: 176 Force: 0.31 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "clubc", label = "Carbon Club", description = "MaxV: 140 Force: 0.24 Frein: 0.72", rarity = "common", basePrice = 1000 },
            { model = "clubp", label = "Club Painted", description = "MaxV: 140 Force: 0.24 Frein: 0.72", rarity = "common", basePrice = 1000 },
            { model = "clubr", label = "Bf Club R", description = "MaxV: 180 Force: 0.35 Frein: 0.88", rarity = "rare", basePrice = 2000 },
            { model = "clubrhyc", label = "Clubrhyc", description = "MaxV: 180 Force: 0.35 Frein: 0.88", rarity = "rare", basePrice = 2000 },
            { model = "cometnor", label = "Comet Noire", description = "MaxV: 156 Force: 0.35 Frein: 0.88", rarity = "rare", basePrice = 2000 },
            { model = "cometven", label = "Comet Venuum", description = "MaxV: 156 Force: 0.35 Frein: 0.88", rarity = "rare", basePrice = 2000 },
            { model = "coquettepiston", label = "Coquette X", description = "MaxV: 167 Force: 0.33 Frein: 0.70", rarity = "rare", basePrice = 2000 },
            { model = "coqvenm", label = "Coquette Venuum", description = "MaxV: 160 Force: 0.32 Frein: 0.60", rarity = "rare", basePrice = 2000 },
            { model = "dawn", label = "Dawn", description = "MaxV: 185 Force: 0.40 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "drafthyc", label = "Drafter Hycade", description = "MaxV: 150 Force: 0.34 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "draftven", label = "Drafter Venuum", description = "MaxV: 170 Force: 0.45 Frein: 1.20", rarity = "legendary", basePrice = 6000 },
            { model = "dubmono", label = "Dubmono", description = "MaxV: 170 Force: 0.45 Frein: 1.20", rarity = "legendary", basePrice = 6000 },
            { model = "elegyxa19", label = "Elegy X", description = "MaxV: 182 Force: 0.35 Frein: 1.00", rarity = "epic", basePrice = 3500 },
            { model = "elegyxa19ven", label = "Elegy X Venuum", description = "MaxV: 182 Force: 0.35 Frein: 1.00", rarity = "epic", basePrice = 3500 },
            { model = "flashgrs", label = "Flash Grs", description = "MaxV: 183 Force: 0.45 Frein: 1.00", rarity = "legendary", basePrice = 6000 },
            { model = "flattruckm", label = "Flat Truck", description = "MaxV: 130 Force: 0.22 Frein: 0.85", rarity = "common", basePrice = 1000 },
            { model = "gaterback", label = "Tailgater Sportback", description = "MaxV: 160 Force: 0.35 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "gazatar", label = "Gazer Wide", description = "MaxV: 156 Force: 0.31 Frein: 0.85", rarity = "rare", basePrice = 2000 },
            { model = "hweevil", label = "Weevil Halloween", description = "MaxV: 185 Force: 0.45 Frein: 1.20", rarity = "legendary", basePrice = 6000 },
            { model = "hycadetail", label = "Tailgater Hycade", description = "MaxV: 160 Force: 0.35 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "hycbansh", label = "Banshee Hycade", description = "MaxV: 182 Force: 0.39 Frein: 0.72", rarity = "epic", basePrice = 3500 },
            { model = "hycbuff", label = "Buffalo Hycade", description = "MaxV: 170 Force: 0.36 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "hycdeity", label = "Deity Hycade", description = "MaxV: 185 Force: 0.45 Frein: 1.20", rarity = "legendary", basePrice = 6000 },
            { model = "hycenty", label = "Entity Mt Hycade", description = "MaxV: 172 Force: 0.35 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "hycgaunt", label = "Gauntlet Hycade", description = "MaxV: 175 Force: 0.40 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "hycignus", label = "Ignus Hycade", description = "MaxV: 160 Force: 0.38 Frein: 1.00", rarity = "epic", basePrice = 3500 },
            { model = "hycpargn", label = "Paragon Hycade", description = "MaxV: 175 Force: 0.43 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "hycr300", label = "R300 Hycade", description = "MaxV: 151 Force: 0.33 Frein: 0.78", rarity = "rare", basePrice = 2000 },
            { model = "hycsedan", label = "Rhine Sedan Hycade", description = "MaxV: 170 Force: 0.45 Frein: 1.20", rarity = "legendary", basePrice = 6000 },
            { model = "hycwagen", label = "Wagen Hycade", description = "MaxV: 150 Force: 0.40 Frein: 1.00", rarity = "epic", basePrice = 3500 },
            { model = "hyczr350", label = "Zr350 Hycade", description = "MaxV: 149 Force: 0.33 Frein: 0.85", rarity = "rare", basePrice = 2000 },
            { model = "issiwider", label = "Issi Wider", description = "MaxV: 148 Force: 0.30 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "jestvenm", label = "Jester Venuum", description = "MaxV: 190 Force: 0.45 Frein: 1.00", rarity = "legendary", basePrice = 6000 },
            { model = "jubven", label = "Jubilee Venuum", description = "MaxV: 170 Force: 0.40 Frein: 2.00", rarity = "legendary", basePrice = 6000 },
            { model = "kcjub", label = "Jubilee Offroad", description = "MaxV: 150 Force: 0.40 Frein: 1.00", rarity = "epic", basePrice = 3500 },
            { model = "kurxa19", label = "Kuruma X", description = "MaxV: 183 Force: 0.45 Frein: 1.00", rarity = "legendary", basePrice = 6000 },
            { model = "neonvenm", label = "Neon Venuum", description = "MaxV: 156 Force: 0.25 Frein: 1.30", rarity = "rare", basePrice = 2000 },
            { model = "paragonven", label = "Paragon Venuum", description = "MaxV: 159 Force: 0.33 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "parawide", label = "Paragon X", description = "MaxV: 159 Force: 0.33 Frein: 1.10", rarity = "rare", basePrice = 2000 },
            { model = "remusx", label = "Remus X", description = "MaxV: 146 Force: 0.33 Frein: 0.90", rarity = "rare", basePrice = 2000 },
            { model = "rhinea19x", label = "Rhinehart X", description = "MaxV: 180 Force: 0.45 Frein: 1.20", rarity = "legendary", basePrice = 6000 },
            { model = "rsxven", label = "Rsx Venuum", description = "MaxV: 163 Force: 0.40 Frein: 1.35", rarity = "epic", basePrice = 3500 },
            { model = "rt3000varis", label = "Rt3000Varis", description = "MaxV: 149 Force: 0.31 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "rt3kavan", label = "Rt3K X", description = "MaxV: 149 Force: 0.31 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "rwagvenm", label = "Wagen Venuum", description = "MaxV: 123 Force: 0.40 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "schlag", label = "Schlagen Gtr", description = "MaxV: 159 Force: 0.37 Frein: 0.80", rarity = "rare", basePrice = 2000 },
            { model = "sedanwid", label = "Rhine Sed Wider", description = "MaxV: 170 Force: 0.45 Frein: 1.20", rarity = "legendary", basePrice = 6000 },
            { model = "shenron", label = "Shenron", description = "MaxV: 170 Force: 0.40 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "sitavenm", label = "Corsita Venuum", description = "MaxV: 162 Force: 0.40 Frein: 1.30", rarity = "epic", basePrice = 3500 },
            { model = "sr8", label = "Sr8", description = "MaxV: 170 Force: 0.40 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "sr8elem", label = "Sr8 Elem", description = "MaxV: 170 Force: 0.40 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "srspback", label = "Sr Hatch", description = "MaxV: 180 Force: 0.35 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "str", label = "Schneider Str", description = "MaxV: 156 Force: 0.37 Frein: 0.95", rarity = "rare", basePrice = 2000 },
            { model = "strcoupe", label = "Strcoupe", description = "MaxV: 159 Force: 0.33 Frein: 1.10", rarity = "rare", basePrice = 2000 },
            { model = "strman", label = "Strman", description = "MaxV: 156 Force: 0.37 Frein: 0.95", rarity = "rare", basePrice = 2000 },
            { model = "strwag", label = "Schneider Str Wagon", description = "MaxV: 156 Force: 0.37 Frein: 0.95", rarity = "rare", basePrice = 2000 },
            { model = "sugoix", label = "Sugoi X", description = "MaxV: 160 Force: 0.32 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "sultlong", label = "Sultlong", description = "MaxV: 145 Force: 0.33 Frein: 0.50", rarity = "rare", basePrice = 2000 },
            { model = "tailgatersr", label = "24 Tails Sr", description = "MaxV: 160 Force: 0.35 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "tailsr66", label = "Tails Sr66", description = "MaxV: 160 Force: 0.35 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "temphyc", label = "Tempesta Hycade", description = "MaxV: 157 Force: 0.36 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "temptwins", label = "Tempesta Twins", description = "MaxV: 157 Force: 0.36 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "tenfhyc", label = "Tenf Hycade", description = "MaxV: 150 Force: 0.45 Frein: 1.00", rarity = "epic", basePrice = 3500 },
            { model = "tenfvenm", label = "10F Venuum", description = "MaxV: 150 Force: 0.45 Frein: 1.00", rarity = "epic", basePrice = 3500 },
            { model = "thraxven", label = "Thrax Venuum", description = "MaxV: 158 Force: 0.34 Frein: 1.20", rarity = "rare", basePrice = 2000 },
            { model = "toroslbwk", label = "Toros Wide", description = "MaxV: 170 Force: 0.35 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "torosven", label = "Toros Venuum", description = "MaxV: 170 Force: 0.40 Frein: 2.00", rarity = "legendary", basePrice = 6000 },
          --  { model = "tragambo", label = "Tragambo", description = "MaxV: 140 Force: 0.25 Frein: 1.00", rarity = "common", basePrice = 1000 },
            { model = "trager", label = "Trager", description = "MaxV: 140 Force: 0.25 Frein: 1.00", rarity = "common", basePrice = 1000 },
            { model = "tragmech", label = "Tragmech", description = "MaxV: 140 Force: 0.25 Frein: 1.00", rarity = "common", basePrice = 1000 },
            { model = "turisgt3", label = "Turismo Gt3", description = "MaxV: 153 Force: 0.37 Frein: 1.19", rarity = "epic", basePrice = 3500 },
            { model = "verusreg", label = "Verus Regen", description = "MaxV: 105 Force: 0.35 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "xlsstr", label = "Xlsstr", description = "MaxV: 160 Force: 0.55 Frein: 1.50", rarity = "ultimate", basePrice = 10000 },
            { model = "zentven", label = "Zentorno Venuum", description = "MaxV: 159 Force: 0.35 Frein: 1.00", rarity = "rare", basePrice = 2000 },
            { model = "zr350piston", label = "Zr350 X", description = "MaxV: 149 Force: 0.33 Frein: 0.85", rarity = "rare", basePrice = 2000 },
            { model = "carrion", label = "Carrion", description = "MaxV: 156 Force: 0.31 Frein: 0.85", rarity = "rare", basePrice = 2000 },
            { model = "carrionmech", label = "Carrion Mech", description = "MaxV: 156 Force: 0.31 Frein: 0.85", rarity = "rare", basePrice = 2000 },
            { model = "cyphx", label = "Cyph X", description = "MaxV: 147 Force: 0.33 Frein: 0.70", rarity = "rare", basePrice = 2000 },
            { model = "kanjoep4", label = "Kanjo Ep4", description = "MaxV: 140 Force: 0.32 Frein: 0.50", rarity = "rare", basePrice = 2000 },
            { model = "kanjox", label = "Kanjo X", description = "MaxV: 183 Force: 0.45 Frein: 1.00", rarity = "legendary", basePrice = 6000 },
            { model = "reblax", label = "Rebla X", description = "MaxV: 180 Force: 0.45 Frein: 1.20", rarity = "legendary", basePrice = 6000 },
            { model = "sen5tour", label = "Sen5Tour", description = "MaxV: 220 Force: 0.55 Frein: 1.20", rarity = "ultimate", basePrice = 10000 },
            { model = "sen5tourhyc", label = "Sen5Tourhyc", description = "MaxV: 220 Force: 0.55 Frein: 1.20", rarity = "ultimate", basePrice = 10000 },
            { model = "sent5bxane", label = "Sent5Bxane", description = "MaxV: 220 Force: 0.55 Frein: 1.20", rarity = "ultimate", basePrice = 10000 },
            { model = "sent5hyc", label = "Sent5Hyc", description = "MaxV: 220 Force: 0.55 Frein: 1.20", rarity = "ultimate", basePrice = 10000 },
            { model = "sent5wide", label = "Sent5Wide", description = "MaxV: 220 Force: 0.55 Frein: 1.20", rarity = "ultimate", basePrice = 10000 },
            { model = "taurion", label = "Taurion", description = "MaxV: 170 Force: 0.40 Frein: 1.20", rarity = "epic", basePrice = 3500 },
            { model = "uranusx", label = "Uranus X", description = "MaxV: 155 Force: 0.32 Frein: 0.48", rarity = "rare", basePrice = 2000 },
            { model = "varx", label = "Varx", description = "MaxV: 100 Force: 0.50 Frein: 1.05", rarity = "epic", basePrice = 3500 },
        },
        weapons = {
            { name = "WEAPON_PISTOL_MK2", label = "Pistol MK2", description = "Pistolet amélioré", rarity = "common", basePrice = 600 },
            { name = "WEAPON_MICROSMG", label = "Micro SMG", description = "SMG compact", rarity = "common", basePrice = 800 },
            { name = "WEAPON_COMBATPDW", label = "Combat PDW", description = "Arme de défense", rarity = "rare", basePrice = 1500 },
            { name = "WEAPON_COMPACTRIFLE", label = "AK Compact", description = "Fusil d'assaut compact", rarity = "rare", basePrice = 2000 },
            { name = "WEAPON_GUSENBERG", label = "Gusenberg", description = "Mitraillette classique", rarity = "epic", basePrice = 3000 },
            { name = "WEAPON_COMBATMG", label = "Combat MG", description = "Mitrailleuse lourde", rarity = "epic", basePrice = 3500 },
            --{ name = "WEAPON_SCAR17FM", label = "SCAR-17", description = "Fusil d'assaut précis", rarity = "legendary", basePrice = 5000 },
            --{ name = "WEAPON_REDL", label = "AK RedLight", description = "AK customisée", rarity = "legendary", basePrice = 5500 },
            --{ name = "WEAPON_HKUMP", label = "HK UMP", description = "SMG tactique", rarity = "legendary", basePrice = 4500 },
            --{ name = "WEAPON_PREDATOR", label = "M4 Predator", description = "Fusil d'assaut premium", rarity = "ultimate", basePrice = 8000 },
            { name = "WEAPON_HEAVYSNIPER_MK2", label = "Sniper Lourd MK2", description = "Sniper dévastateur", rarity = "ultimate", basePrice = 10000 },
            --{ name = "WEAPON_BLACKSNIPER", label = "HK417", description = "Sniper de précision", rarity = "ultimate", basePrice = 9000 },
        }
    }
}