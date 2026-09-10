Config.Garage = {
    Time = 1, -- Durée en minutes avant que les clés temporaires expirent

    DeletePointRGB = {
        255, -- R
        0,   -- G
        0,   -- B
        255  -- A (opaciter)
    },

    Impound = {
        {
            type = 'car', 
            label = "Ancienne Fourrière ( Véhicule )",
            PointFourriere = vec3(485.778442, -1307.864868, 29.217125), 
            PointSpawn = vec3(495.125793, -1330.000732, 29.339293)
        },
        {
            type = 'car', 
            label = "Fourrière ( Véhicule )",
            PointFourriere = vec3(984.091492, -206.393417, 71.067741), 
            PointSpawn = vec3(983.060059, -219.540665, 70.226028)
        },
        {
            type = 'boat', 
            label = "Fourrière ( Bateau )",
            PointFourriere = vector3(-711.5032, -1299.366, 5.400), 
            PointSpawn = vector3(-721.596, -1347.104, -0.474)},
        {
            type = 'aircraft', 
            label = "Fourrière ( Avion )",
            PointFourriere = vector3(-1078.021, -2863.886, 13.950), 
            PointSpawn = vector3(-1201.469, -3012.973, 13.944)},
        {
            type = 'car', 
            label = "Fourrière ( Véhicule )",
            PointFourriere = vector3(1224.669, 2728.537, 38.005), 
            PointSpawn = vector3(1227.043, 2720.456, 38.005)},
        {
            type = 'aircraft', 
            label = "Fourrière ( Avion )",
            PointFourriere = vector3(4441.579, -4465.199, 4.328), 
            PointSpawn = vector3(4405.237, -4538.585, 4.184)
        },
        {
            type = 'car', 
            label = "Fourrière ( Véhicule )",
            PointFourriere = vec3(4493.702148, -4525.830078, 4.414545), 
            PointSpawn = vector3(4511.969727, -4515.945312, 4.163662)
        },
        {
            type = 'boat', 
            label = "Fourrière ( Bateau )",
            PointFourriere = vector3(4878.667480, -5170.321289, 2.458328), 
            PointSpawn = vec3(4927.902832, -5161.420898, 1.168352)
        },
        {
            type = 'car', 
            label = "Fourrière ( Véhicule )",
            PointFourriere = vec3(125.069168, 6584.083984, 32.090412), 
            PointSpawn = vec3(133.319504, 6584.999023, 31.963680)
        },
        {
            type = 'car', 
            label = "Fourrière ( Véhicule )",
            PointFourriere = vec3(-2030.463013, -465.512726, 11.603973), 
            PointSpawn = vec3(-2044.072754, -454.897461, 11.409309)
        },
        {
            type = 'car', 
            label = "Fourrière ( Véhicule )",
            PointFourriere = vec3(-454.391083, 6041.330078, 31.340387), 
            PointSpawn = vec3(-454.898315, 6040.770996, 31.340387)
        },
    },

    JobsGarages = {
        ["police"] = {
            name = "LSPD Garage",
            coords = vec3(-1064.570679, -848.568665, 5.041571),
            delete = vec3(-1042.476807, -858.482300, 4.887930),
            garage = {
                ["police"] = {
                    name = "Vapid Cruiser",
                    spawn = {
                        {pos = vector4(-1045.2036132812, -861.46252441406, 4.9237360954285, 235.79267883301), heading = 235.79},
                        {pos = vector4(-1048.6680908203, -864.41766357422, 5.0018253326416, 239.45022583008), heading = 239.45022583008},
                        {pos = vector4(-1051.6889648438, -867.06506347656, 5.1267523765564, 240.63571166992), heading = 240.63571166992},
                        {pos = vector4(-1039.7662353516, -855.52783203125, 4.8763976097107, 237.54148864746), heading = 237.54148864746},
                        {pos = vector4(-1047.8103027344, -846.80780029297, 4.8678088188171, 37.484928131104), heading = 37.484928131104},
                        {pos = vector4(-1052.2069091797, -847.11676025391, 4.8676195144653, 35.068264007568), heading = 35.068264007568},
                    }, 
                    -- peut être une table : {pos = vector3(), heading = 0.0} ou un vector4
                },
                ["police2"] = {
                    name = "Buffalo",
                    spawn = {
                        {pos = vector4(-1045.2036132812, -861.46252441406, 4.9237360954285, 235.79267883301), heading = 235.79},
                        {pos = vector4(-1048.6680908203, -864.41766357422, 5.0018253326416, 239.45022583008), heading = 239.45022583008},
                        {pos = vector4(-1051.6889648438, -867.06506347656, 5.1267523765564, 240.63571166992), heading = 240.63571166992},
                        {pos = vector4(-1039.7662353516, -855.52783203125, 4.8763976097107, 237.54148864746), heading = 237.54148864746},
                        {pos = vector4(-1047.8103027344, -846.80780029297, 4.8678088188171, 37.484928131104), heading = 37.484928131104},
                        {pos = vector4(-1052.2069091797, -847.11676025391, 4.8676195144653, 35.068264007568), heading = 35.068264007568},
                    }, 
                    -- peut être une table : {pos = vector3(), heading = 0.0}
                },
            }
        }
    }
}