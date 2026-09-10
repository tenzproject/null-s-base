Config.IllegalDevice = {}

Config.IllegalDevice.Item = {
    name = 'tablet_illegal',
    label = 'Tablette Illégale',
    weight = 0.5,
}

Config.IllegalDevice.GoFast = {
    Cooldown = 600,
    PedModels = { 'a_m_m_business_01', 'a_m_m_hillbilly_01', 'g_m_m_chigoon_01', 'g_m_m_armgoon_02' },
    ReturnVehicle = 'issi2',

    Difficulties = {
        easy = {
            id = 'easy',
            label = 'Facile',
            description = 'Course courte, faible récompense. Idéal pour débuter.',
            targetDistance = 3000.0,
            payment = { 4000, 6500 },
            cargoItem = 'weed_pooch',
            cargoLabel = 'Pochon de Weed',
            cargoMin = 5,
            cargoMax = 10,
            vehicles = { 'sultan', 'kuruma', 'schafter2', 'fugitive' },
        },
        medium = {
            id = 'medium',
            label = 'Moyen',
            description = 'Distance moyenne, risque accru, meilleur paiement.',
            targetDistance = 6000.0,
            payment = { 9000, 13000 },
            cargoItem = 'coke_pooch',
            cargoLabel = 'Pochon de Coke',
            cargoMin = 8,
            cargoMax = 15,
            vehicles = { 'elegy2', 'jester', 'massacro', 'comet2' },
        },
        expert = {
            id = 'expert',
            label = 'Expert',
            description = 'Longue distance, forte récompense, gros risques.',
            targetDistance = 10000.0,
            payment = { 18000, 26000 },
            cargoItem = 'meth_pooch',
            cargoLabel = 'Pochon de Meth',
            cargoMin = 12,
            cargoMax = 22,
            vehicles = { 'pariah', 'italigtb', 'zentorno', 't20' },
        },
    },

    -- Spawn points spread across the map (vector4 = x,y,z,heading)
    Pickups = {
        vector4(-247.0,  6293.0,   31.4,  220.0),
        vector4(1733.0,  3318.0,   41.2,  110.0),
        vector4(2452.0,  4744.0,   35.0,  220.0),
        vector4(-2912.0, 2351.0,   21.0,  180.0),
        vector4(115.0,   3700.0,   39.7,   80.0),
        vector4(-1064.0, 4923.0,  208.0,   60.0),
        vector4(1402.0,  6336.0,   23.7,  255.0),
        vector4(2675.0,  1487.0,   24.5,  180.0),
    },

    Deliveries = {
        vector4(-1196.0, -1496.0,   4.4,  130.0),
        vector4( 412.0, -1623.0,   29.3,  320.0),
        vector4(-1037.0, -2735.0,  13.7,  240.0),
        vector4(  78.0,   580.0,  184.0,  250.0),
        vector4( 815.0, -1900.0,   29.3,    0.0),
        vector4(-1601.0, -1118.0,  13.0,   30.0),
        vector4(1170.0,  -360.0,   67.0,  180.0),
        vector4( 740.0, -2230.0,   28.7,   90.0),
        vector4(-340.0,  -1450.0,  29.6,  180.0),
        vector4(2570.0,   470.0,  108.0,   90.0),
    },
}
