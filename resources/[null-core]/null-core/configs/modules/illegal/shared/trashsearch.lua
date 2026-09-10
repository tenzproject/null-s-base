Config.TrashSearch = Config.TrashSearch or {}

-- Cooldown entre chaque fouille (en secondes)
Config.TrashSearch.Cooldown = 5*60 -- 5 Minutes

-- Durée de l'animation de fouille (en secondes)
Config.TrashSearch.SearchDuration = 8

-- Distance max pour interagir avec une poubelle
Config.TrashSearch.MaxDistance = 3.0

-- Chance de trouver un item (en %)
Config.TrashSearch.FindChance = 85

-- Nombre max d'items trouvés par fouille
Config.TrashSearch.MaxItemsPerSearch = 6

-- Modèles de poubelles dans le monde
Config.TrashSearch.TrashModels = {
    `prop_bin_01a`,
    `prop_bin_02a`,
    `prop_bin_03a`,
    `prop_bin_04a`,
    `prop_bin_05a`,
    `prop_bin_06a`,
    `prop_bin_07a`,
    `prop_bin_07b`,
    `prop_bin_07c`,
    `prop_bin_07d`,
    `prop_bin_08a`,
    `prop_bin_08open`,
    `prop_bin_09a`,
    `prop_bin_10a`,
    `prop_bin_10b`,
    `prop_bin_11a`,
    `prop_bin_11b`,
    `prop_bin_12a`,
    `prop_bin_13a`,
    `prop_bin_14a`,
    `prop_bin_14b`,
    `prop_bin_beach_01a`,
    `prop_bin_beach_01d`,
    `prop_bin_delpiero`,
    `prop_recyclebin_01a`,
    `prop_recyclebin_02a`,
    `prop_recyclebin_02b`,
    `prop_recyclebin_02_d`,
    `prop_recyclebin_03_a`,
    `prop_recyclebin_04_a`,
    `prop_recyclebin_04_b`,
    `prop_recyclebin_05_a`,
    `prop_dumpster_01a`,
    `prop_dumpster_02a`,
    `prop_dumpster_02b`,
    `prop_dumpster_3a`,
    `prop_dumpster_4a`,
    `prop_dumpster_4b`,
    `zprop_bin_01a_old`,
}

-- Items trouvables dans les poubelles avec leurs poids de probabilité
-- Plus le poids est élevé, plus l'item est fréquent
Config.TrashSearch.Loot = {
    -- Matériaux de craft (communs)
    { name = "tissu",                   label = "Tissu",                    weight = 25, min = 1, max = 3 },
    { name = "plastique",               label = "Plastique",                weight = 22, min = 1, max = 3 },
    { name = "ruban_adhesif",           label = "Ruban Adhésif",            weight = 15, min = 1, max = 2 },
    { name = "planche",                 label = "Planche",                  weight = 12, min = 1, max = 2 },

    -- Matériaux de craft (rares)
    { name = "metal_brut",              label = "Métal",                    weight = 8,  min = 1, max = 2 },
    { name = "copper",                  label = "Cuivre",                   weight = 8,  min = 1, max = 1 },
    { name = "ressort",                 label = "Ressort",                  weight = 8,  min = 1, max = 2 },
    { name = "composant_electronique",  label = "Composant Électronique",   weight = 8,  min = 1, max = 1 },

    -- Nourriture / Utile
    { name = "trash_bread",             label = "Pain Usagée",              weight = 15, min = 1, max = 2 },
    { name = "trash_chips",             label = "Paquet de chips Usagée",   weight = 15, min = 1, max = 2 },
    { name = "trash_can",               label = "Canette Usagée",           weight = 15, min = 1, max = 2 },
    { name = "trash_burger",            label = "Burger Usagée",            weight = 15, min = 1, max = 2 },
    { name = "water",                   label = "Eau",                      weight = 8,  min = 1, max = 1 },

    -- Rare
    { name = "ring",                    label = "Bague",                    weight = 2,  min = 1, max = 1 },
 
    -- Inutile
    { name = "trash",                   label = "Crasses",                  weight = 25, min = 2, max = 8 },
}
