Config.CarRental = {
    duration = 1 * 60, -- 30 minutes en secondes
    cooldown = 60000, -- 1 minute entre chaque location

    pedModel = "s_m_m_highsec_01",

    locations = {
        {
            Label = "Location de Véhicules",
            Position = vector4(240.2527, -818.7949, 30.1016, 72.1152),
            SpawnOffset = vec4(237.2303, -812.8513, 30.2727, 245.8041),
            Blip = {
                sprite = 77,
                color = 4,
                scale = 0.5,
                display = 4,
            },
            enableStarterPack = false,
            enableKeybinds = false,
        },
        {
            Label = "Location de Véhicules",
            Position = vector4(-1186.0244, -1509.0149, 4.3797, 33.0404),
            SpawnOffset = vec4(-1191.1573, -1504.2988, 4.3693, 297.1494),
            Blip = {
                sprite = 77,
                color = 4,
                scale = 0.5,
                display = 4,
            },
            enableStarterPack = false,
            enableKeybinds = false,
        },
        {
            Label = "Location de Véhicules",
            Position = vector4(-2002.2288, -503.4103, 11.5218, 81.3425),
            SpawnOffset = vec4(-2012.9332, -496.7325, 11.6858, 322.3295),
            Blip = {
                sprite = 77,
                color = 4,
                scale = 0.5,
                display = 4,
            },
            enableStarterPack = false,
            enableKeybinds = false,
        },
        {
            Label = "Location de Véhicules",
            Position = vector4(637.4926, 204.2517, 97.6043, 158.5671),
            SpawnOffset = vec4(627.7617, 196.5084, 97.2734, 248.7152),
            Blip = {
                sprite = 77,
                color = 4,
                scale = 0.5,
                display = 4,
            },
            enableStarterPack = false,
            enableKeybinds = false,
        },
        {
            Label = "Location de Véhicules",
            Position = vector4(-832.7659, -2351.0825, 14.5706, 266.1816),
            SpawnOffset = vec4(-830.2236, -2356.6848, 14.5707, 332.4962),
            Blip = {
                sprite = 77,
                color = 4,
                scale = 0.5,
                display = 4,
            },
            enableStarterPack = false,
            enableKeybinds = false,
        },
        {
            Label = "Location de Véhicules",
            Position = vector4(1209.8241, -1537.4045, 39.4027, 177.8938),
            SpawnOffset = vec4(1211.1298, -1546.6379, 39.4535, 51.9934),
            Blip = {
                sprite = 77,
                color = 4,
                scale = 0.5,
                display = 4,
            },
            enableStarterPack = false,
            enableKeybinds = false,
        },
        {
            Label = "Location de Véhicules",
            Position = vector4(1846.1820, 2587.3250, 45.6721, 268.2628),
            SpawnOffset = vec4(1855.1903, 2578.9229, 45.6721, 265.2610),
            Blip = {
                sprite = 77,
                color = 4,
                scale = 0.5,
                display = 4,
            },
            enableStarterPack = false,
            enableKeybinds = false,
        },
        {
            Label = "Location de Véhicules",
            Position = vector4(1523.8584, 3773.7632, 34.5114, 225.5890),
            SpawnOffset = vec4(1523.4023, 3767.4309, 34.0499, 229.6159),
            Blip = {
                sprite = 77,
                color = 4,
                scale = 0.5,
                display = 4,
            },
            enableStarterPack = false,
            enableKeybinds = false,
        },
        {
            Label = "Location de Véhicules",
            Position = vector4(-103.8325, 6343.4966, 31.5759, 229.2016),
            SpawnOffset = vec4(-101.2421, 6339.6919, 31.4904, 222.0782),
            Blip = {
                sprite = 77,
                color = 4,
                scale = 0.5,
                display = 4,
            },
            enableStarterPack = false,
            enableKeybinds = false,
        }, 
        {
            Label = "Location de Véhicules",
            Position = vector4(42.9555, 2794.1465, 57.8782, 61.9274),
            SpawnOffset = vec4(39.2392, 2798.1362, 57.8782, 140.9232),
            Blip = {
                sprite = 77,
                color = 4,
                scale = 0.5,
                display = 4,
            },
            enableStarterPack = false,
            enableKeybinds = false,
        }, 
        {
            Label = "Location de Véhicules",
            Position = vector4(-2200.5122, 4245.2607, 47.9243, 325.4948),
            SpawnOffset = vec4(-2194.3206, 4245.1436, 47.9129, 45.1720),
            Blip = {
                sprite = 77,
                color = 4,
                scale = 0.5,
                display = 4,
            },
            enableStarterPack = false,
            enableKeybinds = false,
        }, 
    },

    categories = {
        cars = {
            label = "Location de voitures",
            icon = "",
            vehicles = {
                { label = "Sultan", model = "sultan", price = 500 },
                { label = "Panto", model = "panto", price = 300 },
                { label = "Dilettante", model = "dilettante", price = 350 },
                { label = "Brioso", model = "brioso", price = 400 },
                { label = "Blista", model = "blista", price = 250 },
            },
        },
        bikes = {
            label = "Location de motos",
            icon = "",
            vehicles = {
                { label = "Sanchez", model = "sanchez", price = 400 },
                { label = "Faggio", model = "faggio", price = 200 },
                { label = "PCJ 600", model = "pcj", price = 450 },
                { label = "Vader", model = "vader", price = 500 },
                { label = "Enduro", model = "enduro", price = 350 },
            },
        },
        bicycles = {
            label = "Location de vélos",
            icon = "",
            vehicles = {
                { label = "BMX", model = "bmx", price = 50 },
                { label = "Cruiser", model = "cruiser", price = 75 },
                { label = "Fixter", model = "fixter", price = 100 },
                { label = "Scorcher", model = "scorcher", price = 80 },
                { label = "Tribike", model = "tribike", price = 60 },
            },
        },
    },
}

-- ============================================================
--  StarterPack Config (intégré au CarRental)
-- ============================================================

Config.StarterPack = {
    MessageBan = "Tentative de Cheat StarterPack",

    KeySystem = true,
    Money = {
        cash = "cash",
    },

    DirtyCash = {
        sale = "dirtycash",
    },

    Pack = {
        ["legal"] = {
            Type = "Pack Légal",
            Description = "Voici le pack legal dans lequel vous pourrez bénéficiez de : \n~g~5000$~s~\n~b~10 Eaux~s~\n~o~10 pains",
            Notification = "Vous venez de recevoir votre starterpack Légal !",
            ["Reward"] = {
                cash = 5000,
                weapon = {
                --    {name = "WEAPON_PISTOL"},
                --    {name = "WEAPON_PISTOL50"}
                },
                items = {
                    {count = 10, name = "bread"},
                    {count = 10, name = "water"}
                },
              --  car = "sultan",
            },
        },
        ["illegal"] = {
            Type = "Pack Illégal",
            Description = "Voici le pack illégal dans lequel vous pourrez bénéficiez de : \n~r~2500$~s~\n~y~2500$~s~\n~b~Une Batte",
            Notification = "Vous venez de recevoir votre starterpack Illégal !",
            ["Reward"] = {
                cash = 2500,
                sale = 2500,
                weapon = {
                    {name = "WEAPON_BAT"}
                },
               -- car = "bf400"
            }
        }
    },

    Touche = {
        ["phone"] = {
            Label = "Ouvrir le Téléphone",
            Description = nil,
            RightLabel = "G",
        },
        ["boutique"] = {
            Label = "Ouvrir le menu Boutique",
            Description = nil,
            RightLabel = "F1",
        },
        ["f5"] = {
            Label = "Ouvrir le menu Personnel",
            Description = nil,
            RightLabel = "F5",
        },
        ["alt"] = {
            Label = "Ouvrir le menu Intéraction",
            Description = nil,
            RightLabel = "ALT",
        },
        ["f6"] = {
            Label = "Ouvrir le menu Entreprise",
            Description = nil,
            RightLabel = "F6",
        },
        ["f7"] = {
            Label = "Ouvrir le menu Illégal",
            Description = nil,
            RightLabel = "F7",
        },
        ["s'assoir"] = {
            Label = "S'accroupir",
            Description = nil,
            RightLabel = "CRTL",
        },
        ["pointer"] = {
            Label = "Pointer du doight",
            Description = nil,
            RightLabel = "B",
        },
        ["leverlesmains"] = {
            Label = "Lever les mains",
            Description = nil,
            RightLabel = "X",
        }
    },
}

Config.StarterPack.Logs = {
    Icon = "",
    WebHook = "",
    Content = {
        ["Title"] = "Un joueur viens de récupérer le startepack %s",
        ["Description"] = "Le joueur:\n License: ** %s **\n Id: ** %s ** \nId Unique: ** %s ** \nviens de récupérer sont starter pack !",
        ["Colour"] = 1752220,
    }
}
