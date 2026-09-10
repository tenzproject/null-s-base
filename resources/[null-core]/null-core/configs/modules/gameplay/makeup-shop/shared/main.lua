Config.MakeupShop = {
    -- =====================================================================
    -- MARQUES — Salons de maquillage cohérents GTA V
    --   glamour_sundries   : Vinewood (rose / glam Hollywood)
    --   ponsonbys_cosmetics: Rockford Hills (haut de gamme noir & or)
    --   vinewood_beauty    : Burton (warm tones)
    -- =====================================================================
    DefaultBrand = "glamour_sundries",

    Brands = {
        glamour_sundries = {
            id = "glamour_sundries",
            name = "Glamour Sundries",
            logo = "shopui/brands/glamour_sundries.png",
            bgColor = "#1a0a14",
            accentColor = "#e91e63",
            tagline = "Glam à la Hollywood.",
        },
        ponsonbys_cosmetics = {
            id = "ponsonbys_cosmetics",
            name = "Ponsonbys Cosmetics",
            logo = "shopui/brands/ponsonbys_cosmetics.png",
            bgColor = "#0d0d0d",
            accentColor = "#e8c87a",
            tagline = "Beauté intemporelle.",
        },
        vinewood_beauty = {
            id = "vinewood_beauty",
            name = "Vinewood Beauty",
            logo = "shopui/brands/vinewood_beauty.png",
            bgColor = "#1a0e0a",
            accentColor = "#f5a623",
            tagline = "Sublimez votre éclat.",
        },
    },

    List = {
        -- Vespucci / Mission Row — Glamour Sundries
        { Label = "Glamour Sundries",    Type = "glamour_sundries",    Position = vector3(-570.897, -1068.122, 26.61526), Blip = false },
        -- Rockford Hills — Ponsonbys Cosmetics
        { Label = "Ponsonbys Cosmetics", Type = "ponsonbys_cosmetics", Position = vector3(-130.0, -195.0, 37.0),         Blip = false },
        -- Burton (Vinewood) — Vinewood Beauty
        { Label = "Vinewood Beauty",     Type = "vinewood_beauty",     Position = vector3(-823.0, -132.0, 37.6),          Blip = false },
    },

    Price = 100,
}