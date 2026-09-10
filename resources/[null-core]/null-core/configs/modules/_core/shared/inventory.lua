Config.Inventory = Config.Inventory or {}

-- Paramètres généraux
Config.Inventory.MaxWeight = 24                    -- Poids max par défaut joueur
Config.Inventory.CacheTimeout = 300                -- Timeout cache coffres (5 min)
Config.Inventory.SaveInterval = 30                 -- Intervalle sauvegarde coffres ouverts (30 sec)

-- Poids des coffres par type de véhicule
Config.Inventory.VehicleWeight = {
    [0] = 50,    -- Compacts
    [1] = 50,    -- Sedans
    [2] = 75,    -- SUVs
    [3] = 40,    -- Coupes
    [4] = 40,    -- Muscle
    [5] = 30,    -- Sports Classics
    [6] = 30,    -- Sports
    [7] = 20,    -- Super
    [8] = 15,    -- Motorcycles
    [9] = 100,   -- Off-road
    [10] = 150,  -- Industrial
    [11] = 200,  -- Utility
    [12] = 200,  -- Vans
    [13] = 0,    -- Cycles
    [14] = 50,   -- Boats
    [15] = 50,   -- Helicopters
    [16] = 50,   -- Planes
    [17] = 50,   -- Service
    [18] = 100,  -- Emergency
    [19] = 100,  -- Military
    [20] = 200,  -- Commercial
    [21] = 0,    -- Trains
}

-- Poids personnalisés par modèle de véhicule (coffre)
Config.Inventory.CustomVehicleWeight = {
    -- [`adder`] = 15,
}

-- Poids des boîtes à gants par type de véhicule
Config.Inventory.GloveBoxWeight = {
    [0] = 5,     -- Compacts
    [1] = 5,     -- Sedans
    [2] = 7,     -- SUVs
    [3] = 5,     -- Coupes
    [4] = 5,     -- Muscle
    [5] = 5,     -- Sports Classics
    [6] = 5,     -- Sports
    [7] = 5,     -- Super
    [8] = 3,     -- Motorcycles
    [9] = 7,     -- Off-road
    [10] = 10,   -- Industrial
    [11] = 10,   -- Utility
    [12] = 10,   -- Vans
    [13] = 0,    -- Cycles
    [14] = 5,    -- Boats
    [15] = 5,    -- Helicopters
    [16] = 5,    -- Planes
    [17] = 7,    -- Service
    [18] = 7,    -- Emergency
    [19] = 7,    -- Military
    [20] = 10,   -- Commercial
    [21] = 0,    -- Trains
}

-- Poids personnalisés par modèle de véhicule (boîte à gants)
Config.Inventory.CustomGloveBoxWeight = {
    -- [`adder`] = 3,
}

-- Types d'inventaires
Config.Inventory.Types = {
    PLAYER = "PLAYER",
    VEHICLE = "VEHICLE",
    VEHICLE_GLOVE_BOX = "VEHICLE_GLOVE_BOX",
    PROPERTY = "PROPERTY",
    SOCIETY = "SOCIETY",
    STASH = "STASH",
    FRIDGE = "FRIDGE",
    DRUGLABS = "DRUGLABS",
    BRIEFCASE = "BRIEFCASE",
    DEBUG = "DEBUG",
}

-- Noms affichés des types
Config.Inventory.TypeNames = {
    PLAYER = "Joueur",
    VEHICLE = "Coffre de véhicule",
    VEHICLE_GLOVE_BOX = "Boîte à gants",
    PROPERTY = "Propriété",
    SOCIETY = "Entreprise",
    STASH = "Stockage",
    FRIDGE = "Frigo",
    DRUGLABS = "Laboratoire",
    BRIEFCASE = "Mallette",
    DEBUG = "Debug (Staff)",
}

-- Poids par défaut des types d'inventaires
Config.Inventory.DefaultWeights = {
    PLAYER = 24,
    VEHICLE = 100,
    VEHICLE_GLOVE_BOX = 5,
    PROPERTY = 500,
    SOCIETY = 1000,
    STASH = 100,
    FRIDGE = 200,
    DRUGLABS = 15000,
    BRIEFCASE = 15,
    DEBUG = -1,  -- Illimité
}

-- Items qui ne peuvent pas être déplacés
Config.Inventory.LockedItems = {
    -- ["item_name"] = true,
}

-- Armes qui ne peuvent pas être déplacées
Config.Inventory.LockedWeapons = {
    -- ["WEAPON_NAME"] = true,
}

-- Skin par défaut quand on retire un accessoire
Config.Inventory.DefaultSkin = {
    male = {
        top = { torso_1 = 15, torso_2 = 0, tshirt_1 = 15, tshirt_2 = 0 },
        pants = { pants_1 = 21, pants_2 = 0 },
        shoes = { shoes_1 = 34, shoes_2 = 0 },
        mask = { mask_1 = 0, mask_2 = 0 },
        glasses = { glasses_1 = 0, glasses_2 = 0 },
        hat = { helmet_1 = -1, helmet_2 = 0 },
        bag = { bags_1 = 0, bags_2 = 0 },
        gillet = { bproof_1 = 0, bproof_2 = 0 },
        bracelet = { bracelets_1 = -1, bracelets_2 = 0 },
    },
    female = {
        top = { torso_1 = 15, torso_2 = 0, tshirt_1 = 15, tshirt_2 = 0 },
        pants = { pants_1 = 15, pants_2 = 0 },
        shoes = { shoes_1 = 35, shoes_2 = 0 },
        mask = { mask_1 = 0, mask_2 = 0 },
        glasses = { glasses_1 = 0, glasses_2 = 0 },
        hat = { helmet_1 = -1, helmet_2 = 0 },
        bag = { bags_1 = 0, bags_2 = 0 },
        gillet = { bproof_1 = 0, bproof_2 = 0 },
        bracelet = { bracelets_1 = -1, bracelets_2 = 0 },
    }
}

-- Liste des poubelles (pour jeter des items)
Config.Inventory.TrashBins = {
    "prop_bin_01a", "prop_bin_02a", "prop_bin_03a", "prop_bin_04a",
    "prop_bin_05a", "prop_bin_06a", "prop_bin_07a", "prop_bin_07b",
    "prop_bin_07c", "prop_bin_07d", "prop_bin_08a", "prop_bin_08open",
    "prop_bin_09a", "prop_bin_10a", "prop_bin_10b", "prop_bin_11a",
    "prop_bin_11b", "prop_bin_12a", "prop_bin_13a", "prop_bin_14a",
    "prop_bin_14b", "prop_bin_beach_01a", "prop_bin_beach_01d",
    "prop_cs_bin_01", "prop_cs_bin_03", "prop_cs_dumpster_01a",
    "prop_recyclebin_01a", "prop_recyclebin_02a", "prop_recyclebin_02b",
    "prop_recyclebin_02_c", "prop_recyclebin_02_d", "prop_recyclebin_04_a",
    "prop_recyclebin_04_b", "prop_recyclebin_05_a",
    "v_ret_gc_bin", "v_ret_csr_bin", "v_med_bin", "v_serv_waste_bin1",
    "mp_b_kit_bin_01", "hei_heist_kit_bin_01",
    "ch_prop_casino_bin_01a", "vw_prop_vw_casino_bin_01a",
}

-- Animations pour équiper/retirer des accessoires
Config.Inventory.AccessoryAnimations = {
    top = { dict = "clothingtie", anim = "try_tie_positive_a", flag = 51, duration = 2100 },
    shoes = { dict = "random@domestic", anim = "pickup_low", flag = 0, duration = 1200 },
    pants = { dict = "re@construction", anim = "out_of_breath", flag = 51, duration = 1300 },
    mask = { dict = "mp_masks@standard_car@ds@", anim = "put_on_mask", flag = 51, duration = 800 },
    glasses = { dict = "clothingspecs", anim = "take_off", flag = 51, duration = 1400 },
    hat = { dict = "missheist_agency2ahelmet", anim = "take_off_helmet_stand", flag = 51, duration = 1200 },
    gillet = { dict = "clothingtie", anim = "try_tie_positive_a", flag = 51, duration = 2100 },
    bag = { dict = "clothingtie", anim = "try_tie_negative_a", flag = 51, duration = 1200 },
    bracelet = { dict = "nmt_3_rcm-10", anim = "cs_nigel_dual-10", flag = 51, duration = 1200 },
}