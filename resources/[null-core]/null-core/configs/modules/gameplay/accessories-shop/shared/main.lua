Config.AccessoriesShop = {
    -- Mêmes conventions que `Config.ClothingShop` : un dict `Brands` (clé =
    -- id de marque) et chaque shop référence sa marque via `Type`.
    DefaultBrand = "binco-acc",

    Brands = {
        ["binco-acc"] = {
            id = "binco-acc",
            name = "Binco Accessoires",
            banner = "shopui/banners/binco.webp",
            tagline = "Détails. Style. Personnalité.",
        },
        ["suburban-acc"] = {
            id = "suburban-acc",
            name = "Suburban Accessoires",
            banner = "shopui/banners/surban.webp",
            tagline = "Le détail qui fait la rue.",
        },
        ["ponsonbys-acc"] = {
            id = "ponsonbys-acc",
            name = "Ponsonbys Accessoires",
            banner = "shopui/banners/ponsboy.webp",
            tagline = "L'art du détail.",
        },
    },

    List = {
        {
            Type = "binco-acc",
            Label = "Magasin d'accessoires",
            Position = vec3(-1337.210571, -1277.965942, 4.872885),
        },
    },
}