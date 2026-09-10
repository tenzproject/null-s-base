Config.ClothingShop = {
    -- =====================================================================
    -- MARQUES
    --   Chaque magasin de la `List` ci-dessous référence une marque via son
    --   champ `Type` (clé du dict `Brands`). Le client envoie alors les
    --   infos de la marque correspondante au NUI lors de l'ouverture du shop.
    --
    --   Pour ajouter une nouvelle marque :
    --     1. Ajouter une entrée dans `Brands` (id, name, tagline, banner).
    --     2. Mettre la bannière dans `null-cache/images/shopui/banners/<x>.webp`.
    --     3. Référencer son id via `Type` dans la `List` ou en créer une.
    --
    --   Le menu reprend la couleur du serveur (config Global). La marque ne
    --   sert plus qu'à afficher une bannière + un nom + une courte description.
    --   Le champ `DefaultBrand` ci-dessous est utilisé en fallback si un
    --   shop a un Type invalide / absent.
    -- =====================================================================
    DefaultBrand = "binco",

    Brands = {
        binco = {
            id = "binco",
            name = "Binco",
            banner = "shopui/brands/binco.webp",
            tagline = "Style. Confort. Attitude.",
        },
        suburban = {
            id = "suburban",
            name = "Suburban",
            banner = "shopui/brands/surban.webp",
            tagline = "Streetwear authentique.",
        },
        ponsonbys = {
            id = "ponsonbys",
            name = "Ponsonbys",
            banner = "shopui/brands/ponsboy.webp",
            tagline = "Élégance intemporelle.",
        },
    },

    List = {
        -- Davis (centre-ville sud) — Binco
        ["Magasin de Vêtement"] = {Type = "binco", Position = vec3(74.005081, -1398.247314, 29.376181)},
        -- Cayo Perico — Binco
        ["MagasindeVêtement2"] = {Type = "binco", Position = vec3(4492.142090, -4451.760254, 4.663914)},
        -- Burton (West Vinewood) — Ponsonbys
        ["MagasindeVêtement3"] = {Type = "ponsonbys", Position = vec3(-704.509277, -152.177734, 37.415146)},
        -- Hawick (Rockford / Vinewood) — Ponsonbys
        ["MagasindeVêtement4"] = {Type = "ponsonbys", Position = vec3(-167.563065, -299.559784, 39.733311)},
        -- Pillbox Hill / Mission Row — Suburban
        ["MagasindeVêtement5"] = {Type = "binco", Position = vec3(427.160278, -801.307495, 29.491165)},
        -- Vespucci Beach — Suburban
        ["MagasindeVêtement6"] = {Type = "suburban", Position = vec3(-826.576904, -1072.387085, 11.625558)},
        -- Rockford Hills — Ponsonbys
        ["MagasindeVêtement7"] = {Type = "ponsonbys", Position = vec3(-1447.260498, -242.295410, 49.821392)},
        -- Paleto Bay — Binco
        ["MagasindeVêtement8"] = {Type = "binco", Position = vec3(9.410763, 6512.699707, 32.175293)},
        -- Vinewood Boulevard — Suburban
        ["MagasindeVêtement9"] = {Type = "suburban", Position = vec3(123.646, -219.440, 54.557)},
        -- Sandy Shores — Binco
        ["MagasindeVêtement10"] = {Type = "binco", Position = vec3(1696.368652, 4826.562500, 42.360538)},
        -- Grand Senora (Harmony) — Binco
        ["MagasindeVêtement11"] = {Type = "binco", Position = vec3(618.093, 2759.629, 42.088)},
        -- Sandy Shores (E) — Binco
        ["MagasindeVêtement12"] = {Type = "binco", Position = vec3(1193.156006, 2713.183594, 38.520058)},
        -- Del Perro Plaza — Suburban
        ["MagasindeVêtement13"] = {Type = "suburban", Position = vec3(-1193.429, -772.262, 17.324)},
        -- Chumash — Binco
        ["MagasindeVêtement14"] = {Type = "binco", Position = vec3(-3172.496, 1048.133, 20.863)},
        -- Lago Zancudo — Binco
        ["MagasindeVêtement15"] = {Type = "binco", Position = vec3(-1105.885620, 2710.430176, 19.405298)},
    },

    MainPrice = 10,
    CategoryMainPrice = {
        ["male"] = {
            ["pants_1"] = 40,
            ["arms"] = 0,
            ["torso_1"] = 50,
            ["tshirt_1"] = 15,
            ["shoes_1"] = 60,
            ["decals_1"] = 100,
        },
        ["female"] = {
            ["pants_1"] = 40,
            ["arms"] = 0,
            ["torso_1"] = 50,
            ["tshirt_1"] = 15,
            ["shoes_1"] = 60,
            ["decals_1"] = 100,
        },
    },
    CustomPrice = {
        ["male"] = {
            ["pants_1"] = {
                [11] = 0,
                [21] = 0,
                [61] = 2,
                [77] = 505,
                [169] = 55,
            },
            ["arms"] = {
                [15] = 0,
            },
            ["torso_1"] = {
                [15] = 0,
                [548] = 250,
            },
            ["tshirt_1"] = {
                [15] = 0,
            },
            ["shoes_1"] = {
                [34] = 0,
                [156] = 100,
            }
        },
        ["female"] = {
            ["pants_1"] = {
                [11] = 0,
                [21] = 0,
                [61] = 2,
                [77] = 505,
                [169] = 55,
            },
            ["arms"] = {
                [15] = 0,
            },
            ["torso_1"] = {
                [15] = 0,
                [548] = 250,
            },
            ["tshirt_1"] = {
                [15] = 0,
            },
            ["shoes_1"] = {
                [34] = 0,
                [156] = 100,
            }
        }
    },
    blackListed = {
        ["male"] = {
            ["pants_1"] = {
                [145] = true,
                [190] = true,
                [127] = true,
                [108] = true,
                [77] = true, -- pantalon staff
            },
            ["arms"] = {
                [164] = true,
                [169] = true,
            },
            ["torso_1"] = {
                [397] = true,
                [372] = true,
                [333] = true,
                [287] = true,
                [289] = true,
                [277] = true,
                [275] = true,
            },
            ["tshirt_1"] = {
    
            },
            ["shoes_1"] = {
                --[13] = true,
                [33] = true,
            }
        },
        ["female"] = {
            ["pants_1"] = {
                [145] = true,
            },
            ["arms"] = {
                [246] = true,
                [210] = true,
                [205] = true,
            },
            ["torso_1"] = {
                [290] = true,
                [348] = true,
                [420] = true,
            },
            ["tshirt_1"] = {
    
            },
            ["shoes_1"] = {
                --[33] = true,
            }  
        }
    }
}