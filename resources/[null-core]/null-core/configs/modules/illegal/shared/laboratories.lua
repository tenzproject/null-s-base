Config.laboratoire = {
    debug = false,    
    price = {9000, 17000},
    timeDealer = 45, -- minutes
    timeDeliveryService = {5, 30}, -- minutes
    Seller = {
        coords = vector3(452.832031, -1305.661865, 30.520872), -- Coords du points pas du ped (pedslist pour changer le ped)
    },  
    items = {
        pooch = "empty_pooch", 
    },
    type = { 
        ["empty"] = {
            id = "empty",
            label = "Vide",
            price = 0,
        },
        ["weed"] = {
            id = "weed",
            label = "Weed",
            price = 355,
            items = {
                plant = "weed_plant",
                plantdry = "weed_plant_dry",
                head_raw = "weed_bud_raw", -- tête de weed non traitée (avant séparation des feuilles)
                bud = "weed_bud", -- tête traitée (intermédiaire avant pochon)
                traitement = "weed_pooch", -- 1g
                pooch = "empty_pooch", 
            }, 
            treatmentequipment = {
                cuts = { 
                    {
                        coords = vec3(-309.129974, -1346.997534, 24.309658), 
                        rotation = vec3(0.0, 0.0, 98.707),
                        heading = 1.06572651863098,
                        chairProps = { 
                            coords = vector3(-309.129974, -1346.9940185547, 23.834796905518-0.55),
                            rotation = vector3(0.0, -0.0, -177.56925964355)
                        },
                        tableOrigin = vector3(-309.11, -1346.21, 24.155),
                        props = {
                            [1] = {
                                coords = vec3(-309.393494, -1346.363159, 24.139072),
                                rotation = vec3(90.0, 0.0, 26.0)
                            },
                            [2] = {
                                coords = vec3(-309.393494, -1346.363159, 24.139072),
                                rotation = vec3(90.0, 84.0, 126.0)
                            },
                            [3] = {
                                coords = vec3(-308.962799, -1345.847778, 24.153587),
                                rotation = vec3(156.0, 43.0, 267.0)
                            },
                            [4] = {
                                coords = vec3(-309.068970, -1346.398560, 24.157291),
                            },
                        }
                    }, 
                    {
                        coords = vec3(-307.129974, -1346.997534, 24.309658), 
                        rotation = vec3(0.0, 0.0, 98.707),
                        heading = 1.06572651863098,
                        chairProps = { 
                            coords = vector3(-307.05383300781, -1346.9940185547, 23.834796905518-0.55),
                            rotation = vector3(0.0, -0.0, -177.56925964355)
                        },
                        tableOrigin = vector3(-307.14, -1346.15, 24.155),
                        props = {
                            [1] = {
                                coords = vec3(-307.393494, -1346.363159, 24.139072),
                                rotation = vec3(90.0, 0.0, 26.0)
                            },
                            [2] = {
                                coords = vec3(-307.393494, -1346.363159, 24.139072),
                                rotation = vec3(90.0, 84.0, 126.0)
                            },
                            [3] = {
                                coords = vec3(-307.962799, -1345.847778, 24.153587),
                                rotation = vec3(156.0, 43.0, 267.0)
                            },
                            [4] = {
                                coords = vec3(-307.068970, -1346.398560, 24.157291),
                            },
                        }
                    }, 
                },
                packaging = {
                    budsPerBag = 1, -- 1 bud = 1 pochon
                    maxBags = 5, -- nombre de pochons par session
                },
                dryTimeToWait = 120, -- Minutes
                dry = vec3(-314.972961, -1360.637085, 24.245499),
                DryStair = {
                    pos = vector3(-314.77777099609, -1361.0977783203, 23.32950592041),
                    rotation = vector3(0.0, 0.0, 15.122999191284),
                },
                DryPlantsCoords = {
                    {coords = vector3(-300.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    {coords = vector3(-301.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    {coords = vector3(-302.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    {coords = vector3(-303.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    {coords = vector3(-304.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    {coords = vector3(-305.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    --{coords = vector3(-306.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    {coords = vector3(-307.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    {coords = vector3(-308.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    {coords = vector3(-309.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    {coords = vector3(-310.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    {coords = vector3(-311.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    {coords = vector3(-312.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    {coords = vector3(-313.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    {coords = vector3(-314.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)}, 
                    {coords = vector3(-315.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)},
                    {coords = vector3(-316.0, -1361.24, 26.36), rotation = vector3(0.0, 0.0, 87.39)}, 
        
                    {coords = vector3(-300.63, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    {coords = vector3(-301.63, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    {coords = vector3(-302.63, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    {coords = vector3(-303.2, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    {coords = vector3(-304.63, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    {coords = vector3(-304.7, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    {coords = vector3(-306.0, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    {coords = vector3(-307.63, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    --{coords = vector3(-308.63, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    {coords = vector3(-309.63, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    {coords = vector3(-310.63, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    --{coords = vector3(-311.63, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    --{coords = vector3(-312.63, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    {coords = vector3(-313.63, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    --{coords = vector3(-314.63, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
                    {coords = vector3(-315.63, -1361.81, 26.428), rotation = vector3(0.0, 0.0, 73.37)},
        
                    
                    {coords = vector3(-315.64, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-314.34, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-313.64, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-312.34, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-311.34, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-310.34, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-309.34, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-308.34, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-307.34, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-306.34, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-305.34, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-304.34, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-303.34, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-302.34, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-301.60, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-301.1, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-300.34, -1346.786, 26.48), rotation = vector3(0.0, -0.0, -95.38)},
        
        
        
                    {coords = vector3(-315.57, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-314.57, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    --{coords = vector3(-313.57, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-312.97, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-311.57, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-309.95, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-309.57, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-308.57, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-307.57, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-306.57, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-305.57, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-304.57, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-303.57, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-302.57, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-301.57, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                    {coords = vector3(-300.07, -1346.26, 26.40), rotation = vector3(0.0, -0.0, -95.38)},
                }
            },
            PlantCoords = {
                -- 1
                {coords = vector3(-311.54125976562, -1359.6826171875, 23.331493377686), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-311.52951049805, -1358.2145996094, 23.33028793335), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-313.84790039062, -1358.2193603516, 23.329517364502), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-313.79177856445, -1359.6577148438, 23.340475082397), rotation = vector3(0.0, -0.0, 0.0)},
        
                {coords = vector3(-313.82009887695, -1354.0260009766, 23.330205917358), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-313.80352783203, -1355.4738769531, 23.329378128052), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-311.52108764648, -1354.0246582031, 23.330373764038), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-311.52981567383, -1355.4730224609, 23.333866119385), rotation = vector3(0.0, -0.0, 0.0)},
                
                {coords = vector3(-313.77444458008, -1351.5457763672, 23.331340789795), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-313.81326293945, -1350.087890625, 23.327005386353), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-311.52474975586, -1351.5289306641, 23.337017059326), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-311.53015136719, -1350.0875244141, 23.332061767578), rotation = vector3(0.0, -0.0, 0.0)},
                
        
        
                {coords = vector3(-308.78863525391, -1351.5434570312, 23.337131500244), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-306.3844909668, -1351.5494384766, 23.330615997314), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-306.39071655273, -1350.0699462891, 23.331537246704), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-308.79632568359, -1350.0869140625, 23.334350585938), rotation = vector3(0.0, -0.0, 0.0)},
                
                {coords = vector3(-308.79632568359, -1350.0869140625, 23.334350585938), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-308.78863525391, -1351.5434570312, 23.337131500244), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-306.39071655273, -1350.0699462891, 23.331537246704), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-306.3844909668, -1351.5494384766, 23.330615997314), rotation = vector3(0.0, -0.0, 0.0)},
        
                {coords = vector3(-308.80584716797, -1354.0034179688, 23.330533981323), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-308.78060913086, -1355.4880371094, 23.332511901855), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-306.37524414062, -1354.0026855469, 23.331390380859), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-306.37420654297, -1355.4769287109, 23.330480575562), rotation = vector3(0.0, -0.0, 0.0)},
                
                {coords = vector3(-303.79788208008, -1358.1873779297, 23.33221244812), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-303.76776123047, -1359.6705322266, 23.330759048462), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-301.11236572266, -1359.6673583984, 23.327796936035), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-301.09323120117, -1358.1820068359, 23.31418800354), rotation = vector3(0.0, -0.0, 0.0)},
                
                {coords = vector3(-303.80694580078, -1355.5352783203, 23.333086013794), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-303.79315185547, -1354.0080566406, 23.331720352173), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-301.09307861328, -1353.990234375, 23.330717086792), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-301.10845947266, -1355.5596923828, 23.331005096436), rotation = vector3(0.0, -0.0, 0.0)},
                
                {coords = vector3(-306.40533447266, -1359.6898193359, 23.308080673218), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-306.38958740234, -1358.1970214844, 23.330280303955), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-308.80651855469, -1359.6656494141, 23.328756332397), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-308.78091430664, -1358.1862792969, 23.333889007568), rotation = vector3(0.0, -0.0, 0.0)},
                
                {coords = vector3(-301.10687255859, -1351.5183105469, 23.332406997681), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-301.08798217773, -1350.0755615234, 23.320556640625), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-303.79141235352, -1351.5245361328, 23.325710296631), rotation = vector3(0.0, -0.0, 0.0)},
                {coords = vector3(-303.75704956055, -1350.0620117188, 23.332206726074), rotation = vector3(0.0, -0.0, 0.0)},
                                
            },
        },
        ["coke"] = {
            id = "coke",
            label = "Coke",
            price = 12000,
        },
        ["meth"] = {
            id = "meth",
            label = "Meth",
            price = 45000,
            items = {
                pseudo = "pseudoephedrine",
                acide = "acid-meth",
                phosphorus = "phosphorus-meth",
                solvant = "solvant-meth",
                mixture = "meth_mixture", 
                meth_tray = "meth_tray", -- meth en plateaux (deja chauffer)
                traitement = "meth_pooch",
            },
            cuves = {
                [1] = {
                    coords = vec3(-310.874908, -1357.528076, 24.805449),
                    coords2 = vec3(-310.874908, -1357.528076, 24.805449),
                    heading = 179.182861328125,
                    anim = "idle_a",
                    dict = "amb@prop_human_bbq@male@idle_a",
                },
                [2] = {
                    coords = vec3(-304.134613, -1350.884644, 24.817736),
                    coords2 = vec3(-304.134613, -1350.884644, 24.817736),
                    heading = 0.26557886600494,
                    anim = "idle_a",
                    dict = "amb@prop_human_bbq@male@idle_a",
                },
            },
            cuveConfig = {
                ingredients = { "pseudo", "acide", "phosphorus" },
                mixTime = 3,        -- Minutes pour le premier mélange
                solvantMixTime = 3, -- Minutes pour le mélange après solvant
                traysProduced = 5, -- Plateaux produits par cuve
                traysProducedUpgrade = 10, -- Plateaux produits par cuve
            },
            timetoWaitFour = 2, -- Minutes
            fours = {
                [1] = {
                    coords = vec3(-311.655151, -1361.341919, 24.701584),
                    heading = 177.62351989746097,
                    numberMax = 10,
                },
                [2] = {
                    coords = vec3(-313.333893, -1361.404541, 24.662355),
                    heading = 177.62351989746097,
                    numberMax = 10,
                },
                [3] = {
                    coords = vec3(-314.980591, -1361.397705, 24.678726),
                    heading = 177.62351989746097,
                    numberMax = 10,
                },
            },
            breakpoints = {
                [1] = {
                    coords = vec3(-307.226959, -1346.851562, 24.309658),
                    heading = 0.0,
                    tableOrigin = vec3(-306.988617, -1346.046997, 24.237429),
                },
                [2] = {
                    coords = vec3(-308.708466, -1346.947510, 24.309658),
                    heading = 0.0,
                    tableOrigin = vec3(-308.683746, -1346.076904, 24.237429),
                },
            },
            breakConfig = {
                crystalPiles = 8,  -- Nombre de piles de cristaux par plateau
            },
        },
        ["weapon"] = {
            id = "weapon",
            label = "Armes",
            price = 95000,
        },
        ["money"] = {
            id = "money",
            label = "Blanchissement",
            price = 115000,
        },
    },
    coords = vec3(-323.196777, -1356.276245, 31.416668),
    heading = 272.2542724609375,
    management = vec3(-321.008820, -1350.149048, 24.832870),
    CameraManage = vec3(-320.842102, -1348.260132, 24.840492), 
    productionPos = vector3(-315.530670, -1355.189331, 24.304113),
    chest = vec3(-320.027710, -1346.368652, 24.747395),
    chest2 = vec3(-321.173950, -1360.005859, 24.355867),
    DealerPed = vector4(-320.180206, -1356.881226, 31.416637-0.98, 85.87882232666016),
    baseSpots = {
        couch = {
            { coords = vec3(-318.349457, -1348.195557, 24.904240 - 0.98), heading = 86.65885162353516 },
            { coords = vec3(-318.349915, -1347.221069, 24.904245 - 0.98), heading = 93.80354 },
            { coords = vec3(-318.760153, -1347.072632, 24.904242 - 0.98), heading = 173.947998046875 },
        },
        couchAnims = {
            { dict = "timetable@ron@ig_3_couch", anim = "base" },
            { dict = "timetable@ron@ig_3_couch", anim = "base" },
            { dict = "timetable@maid@couch@", anim = "base" },
        },
        entrance = {
            vector4(-318.18026733398, -1357.0070800781, 24.904272079468 - 0.98, 355.36276245117),
            vector4(-318.77429199219, -1357.025390625, 24.904272079468 - 0.98, 4.136625289917),
            vector4(-319.38296508789, -1357.0343017578, 24.904272079468 - 0.98, 0.903255879879),
            vector4(-320.21856689453, -1357.1671142578, 24.904272079468 - 0.98, 2.8923583030701),
            vector4(-321.03964233398, -1356.9276123047, 24.904272079468 - 0.98, 1.1970765590668),
        },
        entranceAnims = {
            { dict = "anim@amb@business@bgen@bgen_no_work@", anim = "sit_phone_phoneputdown_idle_nowork" },
            { dict = "anim@heists@fleeca_bank@ig_7_jetski_owner", anim = "owner_idle" },
            { scenario = "WORLD_HUMAN_LEANING" },
            { dict = "amb@world_human_leaning@female@wall@back@holding_elbow@idle_a", anim = "idle_a" },
            { dict = "amb@world_human_leaning@male@wall@back@foot_up@idle_a", anim = "idle_a" },
            { dict = "amb@world_human_leaning@male@wall@back@hands_together@idle_b", anim = "idle_e" },
        },
    },
    employees = {
        ["production_1"] = {
            model = "a_m_m_rurmeth_01",
            name = "Mario Smith",
            specialization = "production",
            labType = "weed",
            description = "Expert en culture de plantes",
            allowedTasks = {"water", "fertilize", "seed", "harvest", "deposit_fresh"},
            baseCoords = vec3(-318.349457, -1348.195557, 24.904240-0.98),
            baseHeading = 86.65885162353516,
            sitChair = true,
            anim = {"timetable@ron@ig_3_couch", "base"},
            idleAnim = {"amb@world_human_hang_out_street@male_c@idle_a", "idle_b"},
            fatigueMultiplier = 1.5,
            prices = {
                onetime = 2500,
                daily = 150
            }
        },
        ["production_2"] = {
            model = "a_m_m_farmer_01",
            name = "Carlos Rodriguez",
            specialization = "production",
            labType = "weed",
            description = "Spécialiste en agriculture",
            allowedTasks = {"water", "fertilize", "seed", "harvest", "deposit_fresh"},
            baseCoords = vec3(-318.349915, -1347.221069, 24.904245-0.98),
            baseHeading = 93.80354309082033,
            sitChair = true,
            anim = {"timetable@ron@ig_3_couch", "base"},
            idleAnim = {"amb@world_human_hang_out_street@male_c@idle_a", "idle_b"},
            fatigueMultiplier = 1.5,
            prices = {
                onetime = 3500,
                daily = 200
            }
        },
        ["production_3"] = {
            model = "a_m_m_hillbilly_02",
            name = "Jake Wilson",
            specialization = "production",
            labType = "weed",
            description = "Expert en horticulture",
            allowedTasks = {"water", "fertilize", "seed", "harvest", "deposit_fresh"},
            baseCoords = vec3(-318.707153, -1347.072632, 24.904242-0.98),
            baseHeading = 173.947998046875,
            sitChair = true,
            anim = {"timetable@maid@couch@", "base"},
            idleAnim = {"anim@amb@nightclub@peds@", "rcmme_amanda1_stand_loop_cop"},
            fatigueMultiplier = 1.5,
            prices = {
                onetime = 5000,
                daily = 280
            }
        },
        ["drying_1"] = {
            model = "a_m_m_eastsa_01",
            name = "Edwin Newman",
            specialization = "drying",
            labType = "weed",
            description = "Spécialiste du séchage",
            allowedTasks = {"dry_weed", "collect_dry", "deposit_dry"},
            baseCoords = vec3(-319.349457, -1348.195557, 24.904240-0.98),
            baseHeading = 86.65885162353516,
            sitChair = true,
            anim = {"timetable@ron@ig_3_couch", "base"},
            idleAnim = {"amb@world_human_hang_out_street@female_arms_crossed@idle_a", "idle_a"},
            fatigueMultiplier = 1.0,
            prices = {
                onetime = 1500,
                daily = 100
            }
        },
        ["drying_2"] = {
            model = "a_m_y_stbla_02",
            name = "Marcus Johnson",
            specialization = "drying",
            labType = "weed",
            description = "Expert en logistique",
            allowedTasks = {"dry_weed", "collect_dry", "deposit_dry"},
            baseCoords = vec3(-319.349915, -1347.221069, 24.904245-0.98),
            baseHeading = 93.80354309082033,
            sitChair = true,
            anim = {"timetable@ron@ig_3_couch", "base"},
            idleAnim = {"amb@world_human_hang_out_street@male_c@idle_a", "idle_b"},
            fatigueMultiplier = 1.0,
            prices = {
                onetime = 2100,
                daily = 140
            }
        },
        ["treatment_1"] = {
            model = "a_m_m_mexlabor_01",
            name = "Paul Ward",
            specialization = "treatment",
            labType = "weed",
            description = "Expert en traitement",
            allowedTasks = {"treat_weed"},
            baseCoords = vec3(-319.707153, -1347.072632, 24.904242-0.98),
            baseHeading = 173.947998046875,
            sitChair = true,
            anim = {"timetable@maid@couch@", "base"},
            idleAnim = {"anim@amb@nightclub@peds@", "rcmme_amanda1_stand_loop_cop"},
            fatigueMultiplier = 1.3,
            prices = {
                onetime = 2000,
                daily = 120
            }
        },
        ["treatment_2"] = {
            model = "a_m_m_business_01",
            name = "David Chen",
            specialization = "treatment",
            labType = "weed",
            description = "Spécialiste en conditionnement",
            allowedTasks = {"treat_weed"},
            baseCoords = vec3(-320.707153, -1347.072632, 24.904242-0.98),
            baseHeading = 173.947998046875,
            sitChair = true,
            anim = {"timetable@maid@couch@", "base"},
            idleAnim = {"anim@amb@nightclub@peds@", "rcmme_amanda1_stand_loop_cop"},
            fatigueMultiplier = 1.3,
            prices = {
                onetime = 2800,
                daily = 170
            }
        },
        ["chimiste_1"] = {
            model = "mp_f_meth_01",
            name = "Camila Rojas",
            specialization = "chimie",
            labType = "meth",
            description = "Chimiste expérimenté en synthèse de méthamphétamine",
            allowedTasks = {"meth_fill_cuve", "meth_add_solvant", "meth_collect_tray", "meth_load_four", "meth_unload_four", "meth_deposit_storage", "meth_break_tray", "meth_pack_pooch"},
            baseCoords = vec3(-318.349457, -1348.195557, 24.904240-0.98),
            baseHeading = 86.65885162353516,
            sitChair = true,
            anim = {"timetable@ron@ig_3_couch", "base"},
            idleAnim = {"amb@world_human_hang_out_street@male_c@idle_a", "idle_b"},
            fatigueMultiplier = 1.2,
            prices = {
                onetime = 5000,
                daily = 350
            }
        },
        ["chimiste_2"] = {
            model = "mp_m_meth_01",
            name = "Hector Salamanca",
            specialization = "chimie",
            labType = "meth",
            description = "Maître chimiste, spécialiste en cristallisation haute pureté",
            allowedTasks = {"meth_fill_cuve", "meth_add_solvant", "meth_collect_tray", "meth_load_four", "meth_unload_four", "meth_deposit_storage", "meth_break_tray", "meth_pack_pooch"},
            baseCoords = vec3(-318.349915, -1347.221069, 24.904245-0.98),
            baseHeading = 93.80354309082033,
            sitChair = true,
            anim = {"timetable@ron@ig_3_couch", "base"},
            idleAnim = {"amb@world_human_hang_out_street@male_c@idle_a", "idle_b"},
            fatigueMultiplier = 1.0,
            prices = {
                onetime = 8000,
                daily = 500
            }
        },
    },
    upgrades = {
        ["uv-light"] = {
            index = 1,
            label = "Lampes UV",
            description = "Les lampes UV permettent de faire pousser les plantes plus rapidement et donner plus de grammes.",
            type = "weed",
            prices = {
                oneTime = 7510,
                consommation = {
                    ["Electricite"] = 550
                }
            }
        },
        ["coffre"] = {
            index = 2,
            label = "Coffre",
            description = "Un coffre permettant de stocker les drogues.",
            type = "all",
            prices = {
                oneTime = 500
            }
        },
        ["ventilateurs"] = {
            index = 3,
            label = "Ventilateurs",
            description = "Des ventilateurs permettant d'aérer les plantations.",
            type = "weed",
            prices = {
                oneTime = 200,
                consommation = {
                    ["Electricite"] = 35,
                }
            }
        },
        ["security"] = {
            index = 4,
            label = "Sécurité",
            description = "Une meilleur porte et de nouvelles cameras.",
            type = "all",
            prices = {
                oneTime = 4500
            }
        },
        ["treatment-equipment"] = {
            index = 5,
            label = "Equipement de Traitement",
            description = "Un equipement permettant de traiter les drogues.",
            type = "weed",
            prices = {
                oneTime = 500,
            }
        },
        ["dealer"] = {
            index = 6,
            label = "Acheteur",
            description = "Une personne qui vous achete la drogues et la revend.",
            type = "all",
            prices = {
                oneTime = 2500,
                consommation = {
                    ["Salaire"] = 1200,
                }
            }
        },
        ["market-study"] = {
            index = 7,
            label = "Etude de Marché",
            description = "Outils qui vous permettent de faire des recherches sur les marchés.",
            type = "all",
            prices = {
                oneTime = 3500,
                consommation = {
                    ["Abonement"] = 600,
                }
            }
        },
        ["meth-upgrade"] = {
            index = 8,
            label = "Amélioration des machines",
            description = "Améliorer les machines pour produire en plus grande quantité et de meilleure qualité.",
            type = "meth",
            prices = {
                oneTime = 18500
            }
        },
    },  
    Permissions = {
        ["access_lab"] = {
            type = "global", 
            label = "Accéder au labo",
            groupeAccess = true,
        },
        ["access_safe"] = {
            type = "global", 
            label = "Accéder au coffre privé",
            groupeAccess = false,
        },
        ["access_storage"] = {
            type = "global", 
            label = "Accéder au stockage",
            groupeAccess = true,
        },
        ["access_camera"] = {
            type = "global", 
            label = "Accéder aux caméras",
            groupeAccess = true,
        },
        ["access_dealer"] = {
            type = "weed", 
            label = "Accéder au Dealer",
            groupeAccess = true,
        },
        ["harvest_weed"] = {
            type = "weed", 
            label = "Récolter la weed",
            groupeAccess = true,
        },
        ["process_weed"] = {
            type = "weed", 
            label = "Traiter la weed",
            groupeAccess = true,
        },
        ["mix_meth"] = {
            type = "meth", 
            label = "Mixer la Meth",
            groupeAccess = true,
        },
        ["break_meth"] = {
            type = "meth", 
            label = "Casser la Meth",
            groupeAccess = true,
        },
        ["process_meth"] = {
            type = "meth", 
            label = "Mettre au fourneaux la Meth",
            groupeAccess = true,
        },
    }
}