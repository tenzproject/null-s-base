Config.PawnShop = {
    -- Positions des PawnShops dans le monde
    Locations = {
        { label = "Marché aux Puces", position = vec3(1705.892456, 3783.437744, 34.711018) },
    },

    -- Max d'annonces par joueur
    MaxListingsPerPlayer = 8,

    -- Taxe sur les ventes joueur (% prélevé lors d'un achat)
    SaleTax = 5,

    -- Items par défaut vendus par le NPC (matériaux de craft)
    DefaultItems = {
        { name = "metal_brut",              label = "Métal Brut",               price = 150,  stock = -1 },
        { name = "poudre_noire",            label = "Poudre Noire",             price = 250,  stock = -1 },
        { name = "composant_electronique",  label = "Composant Électronique",   price = 500,  stock = -1 },
        { name = "plastique",               label = "Plastique",                price = 100,  stock = -1 },
        { name = "ressort",                 label = "Ressort",                  price = 200,  stock = -1 },
        { name = "ruban_adhesif",           label = "Ruban Adhésif",            price = 75,   stock = -1 },
        { name = "tissu",                   label = "Tissu",                    price = 50,   stock = -1 },
        { name = "planche",                 label = "Planche",                  price = 80,   stock = -1 },
    },

    -- Items interdits de vente (drogues, items staff, etc.)
    BlackListItem = {
        ["opiumrecolte"] = true,
        ["opiumtraitement"] = true,
        ["methrecolte"] = true,
        ["methtraitement"] = true,
        ["lsd"] = true,
        ["lsdtraitement"] = true,
        ["heroinerecolte"] = true,
        ["traitementheroine"] = true,
        ["champignonavarrie"] = true,
        ["champignonmagique"] = true,
        ["cocainerecolte"] = true,
        ["cocainetraitement"] = true,
        ["ecstasy"] = true,
        ["weedrecolte"] = true,
        ["weedtraitement"] = true,
        ["codeinetraitement"] = true,
        ["police_cuff"] = true,
        ["police_key"] = true,
        ["basic_cuff"] = true,
        ["basic_key"] = true,
        ["caisse_halloween"] = true,
        ["caisse_ruby"] = true,
        ["caisse_fidelite"] = true,
        ["caisse_gold"] = true,
        ["caisse_diamond"] = true,
    },
}