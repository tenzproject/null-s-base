Config.Drugs = { -- Ancien systeme
    Price = 12,
    maxSells = 6800,
    maxCountSell = 9,
    Wait = 2000,  -- Pas toucher
    Drugs = {},
    Items = {},
    RandomZone = {}, -- Pas toucher
    x = {}, -- Pas toucher
    y = {}, -- Pas toucher
    z = {}, -- Pas toucher
    objSpawn = {}, -- Pas toucher
}
 
Config.DrugsMarket = {
    market = {
        ["default"] = {
            price = {8, 12},
            label = "",
            hide = true,
            maxsell = {80000, 100000},
        },
        ["weed"] = {
            -- prix par pochon de weed
            -- un pochon fait 2 grammes (1 tête de canabis)
            price = {8, 12}, 
            label = "Weed",
            maxsell = {80000, 100000}, 
        },
        ["coke"] = {
            price = {80, 100},
            label = "Coke",
            maxsell = {15000, 35000},
        },
        ["meth"] = {
            price = {40, 80},
            label = "Meth",
            maxsell = {10000, 30000}, 
        },
    },
}

Config.CustomDrugsPrice = { -- Prix pour les drogues non incluse ci dessous = 1000$ (Config.Drugs.Price)
    ["mdmatraitement"] = 13,
    ["ketaminetraitement"] = 15,
    ["champignontraitement"] = 18,
    ["codeinetraitement"] = 10,
}

Config.DrugSellers = {
    type = {
        ["weed"] = {
            item = "weed_pooch",
            quantity = function() -- Quantité que chaque dealer peut vendre par reboot
                return math.random(50, 5000) -- Nombre aléatoire entre 50 et 5000
            end,
            price = function(marketprice)
                --return marketprice * 0.90 -- OLD: -10% que le prix qu'il va revendre en territoire etc
                return marketprice * (math.random(80, 95)/100) -- 5-20% du prix en moins que le prix qu'il va revendre en territoire etc
            end,
        },
        ["meth"] = {
            item = "meth_pooch",
            quantity = function() -- Quantité que chaque dealer peut vendre par reboot
                return math.random(50, 1000) -- Nombre aléatoire entre 50 et 5000
            end,
            price = function(marketprice)
                --return marketprice * 0.90 -- OLD: -10% que le prix qu'il va revendre en territoire etc
                return marketprice * (math.random(80, 95)/100) -- 5-20% du prix en moins que le prix qu'il va revendre en territoire etc
            end,
        },
        ["coke"] = {
            item = "coke_pooch",
            quantity = function() -- Quantité que chaque dealer peut vendre par reboot
                return math.random(50, 3500) -- Nombre aléatoire entre 50 et 5000
            end,
            price = function(marketprice)
                --return marketprice * 0.90 -- OLD: -10% que le prix qu'il va revendre en territoire etc
                return marketprice * (math.random(80, 95)/100) -- 5-20% du prix en moins que le prix qu'il va revendre en territoire etc
            end,
        },
    },

    Positions = {
        -- Paleto
        vector4(9.5010271072388, 6506.2426757812, 31.524356842041, 222.59539794922),
        vector4(-119.47380065918, 6328.0205078125, 35.500988006592, 224.70225524902),
        vector4(-272.17639160156, 6353.5981445312, 32.489646911621, 318.3727722168),
        vector4(84.611671447754, 3717.9365234375, 40.326412200928, 55.991424560547),
        vector4(330.69311523438, 3389.0244140625, 36.403305053711, 203.30554199219),

        -- Sandy
        vector4(1369.5954589844, 3648.82421875, 33.84886932373, 106.52254486084),
        vector4(1865.4173583984, 3759.9599609375, 32.997802734375, 294.85159301758),

        -- YouTool 
        vector4(2710.1342773438, 3455.0798339844, 56.3173828125, 162.51023864746),

        -- Los Santos:Parking
        vector4(-521.28942871094, 165.34225463867, 71.084693908691, 180.3473815918), -- Parking

        -- Los Santos:Ruelle
        vector4(588.32684326172, 143.38174438477, 104.25132751465, 158.99504089355), 
        vector4(326.51843261719, -148.30894470215, 64.44278717041, 162.92489624023),
        vector4(-1488.2335205078, -325.88586425781, 46.941822052002, 133.0580291748), 
        vector4(-1652.8919677734, -371.98794555664, 45.329696655273, 143.18501281738),
        vector4(-1322.7037353516, -1227.0882568359, 7.1489791870117, 286.93014526367),
        vector4(-1142.7974853516, -1521.0522460938, 4.3565630912781, 33.376396179199),
        vector4(-1117.4246826172, -1627.1512451172, 4.4764981269836, 308.44345092773),
        vector4(206.56632995605, -1851.4404296875, 27.481349945068, 141.09773254395),
        vector4(420.40399169922, -2064.3369140625, 22.143321990967, 51.291168212891),
        vector4(341.39059448242, -1270.6727294922, 32.093475341797, 88.323516845703),
        
        -- Los Santos:Maison
        vector4(171.61248779297, -1871.353515625, 24.400224685669, 64.701499938965),
        vector4(165.13357543945, -1944.9976806641, 20.235422134399, 226.37701416016),
        vector4(197.65808105469, -1725.7822265625, 29.663673400879, 292.16302490234),
        vector4(495.42855834961, -1823.3054199219, 28.870121002197, 320.39465332031),
    },
}

Config.WeedPlant = {
    WeedProps = {
        [0] = `bkr_prop_weed_plantpot_stack_01b`,
        [1] = `bkr_prop_weed_01_small_01a`,
        [2] = `bkr_prop_weed_med_01a`,
        [3] = `bkr_prop_weed_med_01b`,
        [4] = `bkr_prop_weed_lrg_01a`,
        [5] = `bkr_prop_weed_lrg_01b`
    },
    PackageProp = `prop_mp_drug_package`,
    GrowTime = 420, -- Time in minutes for a plant to grow from 0 to 100
    GrowTimeWithUV = 300, -- Time in minutes for a plant to grow from 0 to 100
    LoopUpdate = 15, -- Time in minutes to perform a loop update for water, nutrition, health, growth, etc.
    WaterDecay = 0.4, -- Percent of water that decays every minute
    FertilizerDecay = 0.4, -- Percent of fertilizers that decays every minute
    FertilizerThreshold = 40,
    WaterThreshold = 40,
    HealthBaseDecay = {7, 10}, -- Min/Max Amount of health decay when the plant is below the above thresholds for water and nutrition
}