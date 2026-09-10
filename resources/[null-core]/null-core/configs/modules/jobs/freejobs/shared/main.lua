Config.FreeJobs = {

    -- =========================================================================
    -- AGENCE FREEJOBS Configuration
    -- =========================================================================

    Agence = {
        PedModel = 'a_f_y_business_02',
        PedCoords = vector4(-1083.17, -245.78, 36.76, 207.54),
        InteractionCoords = vector3(-1082.1428, -247.5675, 37.7632),
        BlipSprite = 280,
        BlipColor = 50,
    },

    Metiers = {
        {
            id = 'entrepot',
            nom = 'Cariste',
            description = 'Récupère des palettes de marchandises en tant que cariste avec ton chariot élévateur !',
            icon = 'forklift',
            zone = vector3(-416.7652, -2763.1550, 6.0004),
            blip = 479,
            couleur = 12,
            scale = 0.55,
            rentabilite = 90,
            activityId = 2,
        },
        {
            id = 'cleanpool',
            nom = 'Nettoyage de la piscine',
            description = 'Nettoie le vomi et les déchets autour de la piscine !',
            icon = 'pool',
            zone = vector3(-1367.43, 358.90, 63.24),
            blip = 351,
            couleur = 18,
            scale = 0.55,
            rentabilite = 50,
            activityId = 4,
        },
        {
            id = 'bucheron',
            nom = 'Bûcheron',
            description = 'Abats les arbres dans la forêt avec ta hache pour récolter du bois !',
            icon = 'axe',
            zone = vector3(-553.0767, 5348.8716, 73.7432),
            blip = 478,
            couleur = 17,
            scale = 0.55,
            rentabilite = 70,
            activityId = 5,
        },
    },

    -- =========================================================================
    -- CARISTE Configuration
    -- =========================================================================

    Entrepot = {
        PedModel = 's_m_y_dockwork_01',
        PedCoords = vector4(-416.7652, -2763.1550, 5.0004, 186.2012),
        PedScenario = 'WORLD_HUMAN_CLIPBOARD',
        MaxDistance = 150.0,
        ForkliftModel = 1491375716,
        ForkliftPlate = 'FENOUIK',
        Tenue = {
            ['bags_1'] = 0, ['bags_2'] = 0,
            ['tshirt_1'] = 59, ['tshirt_2'] = 1,
            ['torso_1'] = 1, ['torso_2'] = 0,
            ['arms'] = 30,
            ['pants_1'] = 9, ['pants_2'] = 7,
            ['decals_1'] = 0, ['decals_0'] = 0,
            ['shoes_1'] = 25, ['shoes_2'] = 0,
            ['mask_1'] = 0, ['mask_2'] = 0,
            ['bproof_1'] = 0, ['bproof_2'] = 0,
            ['helmet_1'] = 0, ['helmet_2'] = 0,
        },
        MarkerOffset = -0.3,
        SpawnPalettes = {
            { pos = vector4(-525.3170, -2786.1833, 5.0004, 240.5617),    props = "prop_conc_blocks01c" },
            { pos = vector4(-562.4404, -2812.0593, 5.0004, 179.7906),    props = "prop_conc_blocks01b" },
            { pos = vector4(-549.1063, -2852.0354, 5.0004, 83.7255),    props = "p_pallet_02a_s" },
            { pos = vector4(-510.4268, -2932.9177, 5.0004, 205.3932),   props = "prop_conc_blocks01c" },
            { pos = vector4(-457.1456, -2877.9929, 5.0004, 10.8284),   props = "prop_conc_blocks01c" },
            { pos = vector4(-415.6707, -2857.4514, 5.0004, 302.5291),    props = "prop_conc_blocks01a" },
            { pos = vector4(-373.9647, -2785.6006, 5.0003, 352.7134),    props = "p_pallet_02a_s" },
            { pos = vector4(-430.2982, -2763.7622, 5.0004, 28.7004),   props = "prop_conc_blocks01b" },
            { pos = vector4(-468.0060, -2782.0146, 5.0004, 260.3228),    props = "prop_conc_blocks01c" },
        },
        DeliveryQuai = {
            { pos = vector3(-440.4554, -2795.9514, 6.2959) },
            { pos = vector3(-458.4305, -2813.4004, 6.2959) },
            { pos = vector3(-476.5259, -2831.5591, 6.2959) },
            { pos = vector3(-494.3383, -2849.8059, 6.2959) },
            { pos = vector3(-521.5408, -2876.5188, 6.2959) },
        },
        PosesParking = {
            { pos = vector4(-408.4572, -2764.3684, 6.0004, 184.1765) },
            { pos = vector4(-405.1005, -2764.4319, 6.0004, 177.6570) },
            { pos = vector4(-401.2603, -2764.7175, 6.0004, 176.2475) },
        },
        InfoCommandes = {
            { icon = 'up',       key = 'SHIFT',  text = 'Monter la fourche' },
            { icon = 'down',     key = 'CTRL',   text = 'Baisser la fourche' },
            { icon = 'hand',     key = 'E',      text = 'Valider / Livrer la palette' },
            { icon = 'info',     key = 'INFO',    text = 'Récupérez les palettes et livrez-les au quai' },
        },
        PaletteBlip = {
            Sprite = 285,
            Color = 32,
            Scale = 0.45,
            Label = 'Palette de marchandises',
        },
        DeliveryBlip = {
            Sprite = 291,
            Color = 3,
            Scale = 0.45,
            Label = 'Quai de livraison',
        },
        ForkliftBlip = {
            Sprite = 225,
            Color = 0,
            Scale = 0.55,
            Label = 'Chariot élévateur',
        },
    },

    -- =========================================================================
    -- BUCHERON Configuration
    -- =========================================================================

    Bucheron = {
        PedModel = 's_m_y_construct_02',
        PedCoords = vector4(-553.0767, 5348.8716, 73.7432, 65.5992),
        Ped3DInteractionCoords = vector3(-553.0767, 5348.8716, 74.7432),
        MaxDistance = 200.0,
        Tenue = {
            ['bags_1'] = 0, ['bags_2'] = 0,
            ['tshirt_1'] = 15, ['tshirt_2'] = 0,
            ['torso_1'] = 43, ['torso_2'] = 0,
            ['arms'] = 11,
            ['pants_1'] = 43, ['pants_2'] = 1,
            ['decals_1'] = 0, ['decals_0'] = 0,
            ['shoes_1'] = 27, ['shoes_2'] = 0,
            ['mask_1'] = 0, ['mask_2'] = 0,
            ['bproof_1'] = 0, ['bproof_2'] = 0,
            ['helmet_1'] = -1, ['helmet_2'] = 0,
        },
        MarkerOffset = -0.3,
        AnimDict = 'melee@large_wpn@streamed_core',
        AnimName = 'ground_attack_on_spot',
        ActionTime = 6000,
        VehicleModel = 'blazer',
        VehiclePlate = 'BCH',
        VehicleMaxSpeed = 8.33,
        VehicleBlip = {
            Sprite = 512,
            Color = 17,
            Scale = 0.5,
            Label = 'Blazer - Bûcheron',
        },
        Props = {
            { pos = vector3(-607.2551, 5511.0176, 48.8537), props = 'prop_log_01' },
            { pos = vector3(-525.1140, 5465.2031, 71.1673), props = 'prop_log_01' },
            { pos = vector3(-466.4580, 5515.0098, 78.9978), props = 'prop_log_01' },
            { pos = vector3(-470.5009, 5398.8115, 77.7990), props = 'prop_log_01' },
            { pos = vector3(-615.8641, 5249.2251, 71.2292), props = 'prop_log_01' },
            { pos = vector3(-653.1663, 5266.1235, 74.4689), props = 'prop_log_01' },
            { pos = vector3(-677.8374, 5325.2563, 66.3020), props = 'prop_log_01' },
            { pos = vector3(-718.1899, 5430.3281, 43.0789), props = 'prop_log_01' },
        },
        VehicleSpawns = {
            { pos = vector4(-555.6437, 5372.7485, 70.3128, 72.5080) },
            { pos = vector4(-556.9427, 5369.5845, 70.2143, 60.6227) },
            { pos = vector4(-559.1014, 5364.9585, 70.2315, 67.8827) },
        },
        StumpBlip = {
            Sprite = 285,
            Color = 32,
            Scale = 0.45,
            Label = 'Arbre à couper',
        },
    },

    -- =========================================================================
    -- NETOYEUR DE PISCINE Configuration
    -- =========================================================================

    Pool = {
        PedModel = 's_m_y_construct_02',
        PedCoords = vector4(-1367.4301, 358.9000, 64.2406-1, 225.8315),
        Ped3DInteractionCoords = vector3(-1367.4301, 358.9000, 64.2406),
        MaxDistance = 150.0,
        BroomModel = 'prop_tool_broom',
        CleanDuration = 5000,
        Tenue = {
            ['bags_1'] = 0, ['bags_2'] = 0,
            ['tshirt_1'] = 15, ['tshirt_2'] = 0,
            ['torso_1'] = 9, ['torso_2'] = 3,
            ['arms'] = 0,
            ['pants_1'] = 6, ['pants_2'] = 0,
            ['decals_1'] = 0, ['decals_0'] = 0,
            ['shoes_1'] = 16, ['shoes_2'] = 0,
            ['mask_1'] = 0, ['mask_2'] = 0,
            ['bproof_1'] = 0, ['bproof_2'] = 0,
            ['helmet_1'] = -1, ['helmet_2'] = 0,
        },
        MarkerOffset = -0.3,
        PoolShit = {
            { pos = vector3(-1363.222, 358.185, 63.08036),  props = "prop_juice_pool_01",  label = "Vomi",   anim = "amb@world_human_janitor@male@idle_a", lib = "idle_a" },
            { pos = vector3(-1357.394, 345.2082, 63.08108), props = "prop_juice_pool_01",  label = "Vomi",   anim = "amb@world_human_janitor@male@idle_a", lib = "idle_a" },
            { pos = vector3(-1358.924, 332.073, 63.07152),  props = "ng_proc_sodacup_03c", label = "Gobelet", anim = "amb@world_human_janitor@male@idle_a", lib = "idle_a" },
            { pos = vector3(-1375.228, 326.2322, 63.08116), props = "prop_juice_pool_01",  label = "Vomi",   anim = "amb@world_human_janitor@male@idle_a", lib = "idle_a" },
            { pos = vector3(-1379.776, 336.4292, 63.07612), props = "prop_juice_pool_01",  label = "Vomi",   anim = "amb@world_human_janitor@male@idle_a", lib = "idle_a" },
            { pos = vector3(-1368.028, 345.1448, 63.06462), props = "ng_proc_sodacup_03c", label = "Gobelet", anim = "amb@world_human_janitor@male@idle_a", lib = "idle_a" },
            { pos = vector3(-1357.132, 344.066, 63.08118),  props = "ng_proc_sodacup_03c", label = "Gobelet", anim = "amb@world_human_janitor@male@idle_a", lib = "idle_a" },
            { pos = vector3(-1332.024, 340.0476, 63.07882), props = "prop_juice_pool_01",  label = "Vomi",   anim = "amb@world_human_janitor@male@idle_a", lib = "idle_a" },
            { pos = vector3(-1322.51, 361.705, 63.07792),   props = "ng_proc_sodacup_03c", label = "Gobelet", anim = "amb@world_human_janitor@male@idle_a", lib = "idle_a" },
        },
        TrashBlip = {
            Sprite = 285,
            Color = 32,
            Scale = 0.45,
            Label = 'Déchet à nettoyer',
        },
    },

    -- =========================================================================
    -- GAIN FREEJOBS Configuration
    -- =========================================================================

    Rewards = {
        CleanPool = 6,
        Entrepot = 70,
        Bucheron = 45,
    },
}