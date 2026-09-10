Config = {}

Config.ScreenshotDelay = 500

Config.Categories = {
    {
        name = "hair",
        label = "Cheveux",
        componentType = "hair",
        genderSpecific = true,
        camera = {
            offset = vector3(0.6, 0.0, 0.70),
            rotation = vector3(0.0, 0.0, 90.0),
            fov = 35.0
        },
        ranges = {
            male = {min = 0, max = 73},
            female = {min = 0, max = 76}
        }
    },
    {
        name = "beard",
        label = "Barbes",
        componentType = "beard",
        genderSpecific = false,
        camera = {
            offset = vector3(0.5, 0.0, 0.68),
            rotation = vector3(0.0, 0.0, 90.0),
            fov = 30.0
        },
        ranges = {
            male = {min = 0, max = 28},
            female = {min = 0, max = 28}
        }
    },
    {
        name = "eyebrows",
        label = "Sourcils",
        componentType = "eyebrows",
        genderSpecific = false,
        camera = {
            offset = vector3(0.5, 0.0, 0.70),
            rotation = vector3(0.0, 0.0, 90.0),
            fov = 28.0
        },
        ranges = {
            male = {min = 0, max = 33},
            female = {min = 0, max = 33}
        }
    },
    {
        name = "chest_hair",
        label = "Poils du torse",
        componentType = "chest",
        genderSpecific = false,
        camera = {
            offset = vector3(0.0, 0.6, 0.3),
            rotation = vector3(0.0, 0.0, 180.0),
            fov = 45.0
        },
        ranges = {
            male = {min = 0, max = 16},
            female = {min = 0, max = 16}
        }
    },
    {
        name = "lipstick",
        label = "Rouge à lèvres",
        componentType = "lipstick",
        genderSpecific = false,
        camera = {
            offset = vector3(0.0, 0.35, 0.63),
            rotation = vector3(0.0, 0.0, 180.0),
            fov = 30.0
        },
        ranges = {
            male = {min = 0, max = 9},
            female = {min = 0, max = 9}
        }
    },
    {
        name = "tattoos",
        label = "Tatouages",
        componentType = "tattoos",
        genderSpecific = false,
        camera = {
            offset = vector3(0.0, 1.2, 0.4),
            rotation = vector3(0.0, 0.0, 180.0),
            fov = 50.0
        },
        ranges = {
            male = {min = 0, max = 100},
            female = {min = 0, max = 100}
        }
    }
}

Config.PedModels = {
    male = "mp_m_freemode_01",
    female = "mp_f_freemode_01"
}

Config.SpawnCoords = vector4(402.8664, -996.4108, -99.0, 180.0)

Config.ComponentMapping = {
    hair = {component = 2, texture = 0},
    beard = {overlay = 1, opacity = 1.0, color = 0},
    eyebrows = {overlay = 2, opacity = 1.0, color = 0},
    chest = {overlay = 10, opacity = 1.0, color = 0},
    lipstick = {overlay = 8, opacity = 1.0, color = 0},
    tattoos = {overlay = "tattoo", collection = "mpbeach_overlays"}
}
