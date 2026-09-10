Config.Properties = {
    apartment = {
        {
            Position = vector3(-773.5578, 311.4858, 85.6981),
            id = 1,
            type = "High",
            label = "Eclipse Towers"
        },
        {
            Position = vector3(-618.2738, 36.48872, 43.57004),
            id = 2,
            type = "High",
            label = "Tinsel Towers"
        },
        {
            Position = vector3(-882.6196, -436.1918, 39.5999),
            id = 3,
            type = "High",
            label = "Weazel Plaza"
        },
        {
            Position = vector3(-47.73304, -585.7634, 37.95544), 
            id = 4, 
            type = "High", 
            label = "4 Integrity Way"
        },
        {
            Position = vector3(-66.08768, -801.2214, 44.22728), 
            id = 5, 
            type = "High", 
            label = "Maze Bank"
        },
        {
            Position = vector3(288.377838, -1095.023804, 29.419659), 
            id = 6, 
            type = "Low", 
            label = "Petit appartement"
        },
        {
            Position = vector3(-736.7746, -2275.542, 13.43744), 
            id = 7, 
            type = "Middle", 
            label = "Opium Nights"
        },
    },
    List = {
        ["Motel"] = {
            MaxWeight = 100,
            prices = {
                --lifetime = 35000,
                permount = 320,
            },
            positions = {
                inside = vector3(151.45, -1007.57, -98.9999),
                cam_coords = vector3(151.7361, -1003.5819, -99.00-1),
            }
        },
        ["Low"] = {
            MaxWeight = 250,
            prices = {
                lifetime = 35000,
                permount = 580,
            },
            positions = {
                inside = vector3(266.0316, -1007.424, -100.8884),
                cam_coords = vector3(265.1008, -999.1278, -99.0086-1),
            }
        },
        ["Middle"] = {
            MaxWeight = 300,
            prices = {
                lifetime = 90000,
                permount = 700,
            },
            positions = {
                inside = vector3(-603.29, 59.74, 98.2),
                cam_coords = vector3(-623.0919, 54.6931, 97.5994-1),
            }
        },
        ["High"] = {
            MaxWeight = 400,
            prices = {
                lifetime = 350000,
                permount = 1200,
            },
            positions = {
                inside = vector3(-1451.35, -523.69, 56.92),
                cam_coords = vector3(-1456.8374, -531.0899, 56.9369-1),
            }
        },
        ["Entrepot1"] = {
            MaxWeight = 20000,
            prices = {
                lifetime = 80000,
                --permount = 400,
            },
            positions = {
                inside = vector3(1026.5056, -3099.8320, -38.9998),
                cam_coords = vector3(999.5825, -3096.2946, -38.9998-1),
            }
        },
        ["Entrepot2"] = {
            MaxWeight = 10000,
            prices = {
                lifetime = 50000,
                --permount = 400,
            },
            positions = {
                inside = vector3(1048.5067, -3097.0817, -38.9999),
                cam_coords = vector3(1070.8294, -3098.5852, -38.9999-1),
            }
        },
        ["Entrepot3"] = {
            MaxWeight = 7500,
            prices = {
                lifetime = 10000,
                --permount = 400,
            },
            positions = {
                inside = vector3(1088.1834, -3099.3547, -38.9999),
                cam_coords = vector3(1103.0339, -3101.6630, -38.999-1),
            }
        },
    },
}

