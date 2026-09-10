Config.Barber = {
    -- =====================================================================
    -- MARQUES — Salons de coiffure cohérents GTA V
    --   bob_mulet      : luxe (Rockford Hills, Burton)  — accent doré
    --   herr_kutz      : classique américain (centre, banlieue)
    --   beach_combover : surf style (Vespucci, Cayo)    — accent bleu océan
    -- =====================================================================
    DefaultBrand = "herr_kutz",

    Brands = {
        bob_mulet = {
            id = "bob_mulet",
            name = "Bob Mulét",
            logo = "shopui/brands/bob_mulet.png",
            bgColor = "#0d0a08",
            accentColor = "#c9a45c",
            tagline = "Coiffure de luxe à la française.",
        },
        herr_kutz = {
            id = "herr_kutz",
            name = "Herr Kutz Barber",
            logo = "shopui/brands/herr_kutz.png",
            bgColor = "#1c1a16",
            accentColor = "#d4b16a",
            tagline = "Le classique américain.",
        },
        beach_combover = {
            id = "beach_combover",
            name = "Beach Combover",
            logo = "shopui/brands/beach_combover.png",
            bgColor = "#0a3050",
            accentColor = "#4ad7e8",
            tagline = "Le style surf, sans sable dans les ciseaux.",
        },
    },

    List = { -- Coiffeur
        -- Burton (West Vinewood) — Bob Mulét (luxe)
        { Label = "Bob Mulét",        Type = "bob_mulet",      Position = vector3(-814.3, -183.8, 36.6) },
        -- Davis (centre-ville sud) — Herr Kutz
        { Label = "Herr Kutz Barber", Type = "herr_kutz",      Position = vector3(136.675278, -1708.381836, 29.291611) },
        -- Vespucci Beach — Beach Combover
        { Label = "Beach Combover",   Type = "beach_combover", Position = vec3(-1281.956543, -1117.293579, 6.990351) },
        -- Sandy Shores — Herr Kutz
        { Label = "Herr Kutz Barber", Type = "herr_kutz",      Position = vector3(1931.5, 3729.7, 31.8) },
        -- Vinewood Hills (Mirror Park) — Bob Mulét
        { Label = "Bob Mulét",        Type = "bob_mulet",      Position = vector3(1212.8, -472.9, 65.2) },
        -- Hawick (Vinewood) — Bob Mulét
        { Label = "Bob Mulét",        Type = "bob_mulet",      Position = vector3(-32.9, -152.3, 56.1) },
        -- Paleto Bay — Herr Kutz
        { Label = "Herr Kutz Barber", Type = "herr_kutz",      Position = vector3(-278.1, 6228.5, 30.7) },
        -- Cayo Perico (plage) — Beach Combover
        { Label = "Beach Combover",   Type = "beach_combover", Position = vec3(4353.432617, -4572.542969, 4.247622) },
    },

    -- Tarifs (utilisé côté serveur). Une seule transaction par session, donc
    -- prix global plutôt que par item.
    Price = 100,
}