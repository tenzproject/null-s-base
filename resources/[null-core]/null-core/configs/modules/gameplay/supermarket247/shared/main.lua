-- 24/7 Supermarket — classic GTA V convenience store
Config.Supermarket247 = {
    StoreConfig = {
        Brand = {
            id = "247",
            name = "24/7",
            logo = "shopui/brands/247-supermarket.webp",
            bgColor = "#006a55",
            accentColor = "#00d89d",
            tagline = "Open day. Open night. Open always.",
        },
         Categories = {
            { name = "Tous", type = "all", icon = "ic:round-clear-all" }, --! Required for all shops
            { name = "Nourritures", type = "food", icon = "mdi:food-drumstick" },
            { name = "Boissons", type = "drinks", icon = "ion:water-sharp" },
            { name = "Autres", type = "others", icon = "mdi:dots-horizontal" },
        },
        Items = {
            -- Food
            { name = "donuts1", label = "Donut Choco Deluxe", category = "food", price = 40 },
            { name = "donuts2", label = "Donut Fraise Sweet", category = "food", price = 10 },
            { name = "donuts3", label = "Donut Pistache Crunch", category = "food", price = 10 },
            { name = "donuts4", label = "Donut Bubble Sky", category = "food", price = 10 },
            { name = "donuts5", label = "Donut Myrtille Royale", category = "food", price = 10 },
            { name = "barreprot1", label = "Barre Chocolat Intense", category = "food", price = 10 },
            { name = "barreprot2", label = "Barre Jungle Bite", category = "food", price = 10 },
            { name = "barreprot3", label = "Barre Sismo Choco", category = "food", price = 10 },
            { name = "noodle1", label = "Chicken Bite Cup", category = "food", price = 10 },
            { name = "noodle2", label = "Ocean Bite Cup", category = "food", price = 10 },
            { name = "noodle3", label = "Reeves Spicy Bowl", category = "food", price = 10 },
            { name = "chips1", label = "Chips BBQ Smoke", category = "food", price = 10 },
            { name = "chips2", label = "Chips Choco Milk", category = "food", price = 10 },
            { name = "chips3", label = "Green Onion Chips", category = "food", price = 10 },
            { name = "chips4", label = "Chips Classic", category = "food", price = 10 },
            { name = "chips5", label = "Red Spice Chips", category = "food", price = 10 },
            { name = "chips6", label = "Salsa Party Chips", category = "food", price = 10 },

            -- Drinks
            { name = "water", label = "Eau", category = "drinks", price = 25 },
            { name = "cola", label = "Classic Cola", category = "drinks", price = 35 },
            { name = "orange", label = "Orange Pop", category = "drinks", price = 35 },
            { name = "spunk", label = "Green Fizz", category = "drinks", price = 35 },
            { name = "bbt1", label = "Matcha Émeraude", category = "drinks", price = 35 },
            { name = "bbt2", label = "Blue Lagoon", category = "drinks", price = 35 },
            { name = "bbt3", label = "Brown Sugar Deluxe", category = "drinks", price = 35 },
            { name = "bbt4", label = "Purple Dream", category = "drinks", price = 35 },
            { name = "juice1", label = "Apple Juice Éclat", category = "drinks", price = 35 },
            { name = "juice2", label = "Grape Juice Royale", category = "drinks", price = 35 },
            { name = "juice3", label = "Lemon Juice Boost", category = "drinks", price = 35 },
            { name = "juice4", label = "Orange Juice Énergie", category = "drinks", price = 35 },
            { name = "juice5", label = "Berry Juice Fusion", category = "drinks", price = 35 },
            { name = "eng1", label = "Fuego Boost", category = "drinks", price = 35 },
            { name = "eng2", label = "Holla Energy", category = "drinks", price = 35 },
            { name = "eng3", label = "Junk Xtreme", category = "drinks", price = 35 },

            -- autres
            { name = "bandage", label = "Bandage", category = "others", price = 210 },
            { name = "deo", label = "Déodorant", category = "others", price = 110 },
        },
        Locales = {
            mainTitle = "24/7",
            mainTag = "Supermarket",
            mainDescription = "Votre supermarché 24h/24, 7j/7.\nTout ce qu'il vous faut, quand il vous le faut.",
        },
    },
    List = {
        ["247-1"]  = { Position = vector3(-3038.939, 585.954, 7.908) },       -- Great Ocean Hwy
        ["247-2"]  = { Position = vector3(1728.66, 6414.07, 35.037) },        -- Paleto Bay
        ["247-3"]  = { Position = vector3(2557.458, 382.282, 108.622) },      -- Tataviam Mountains
        ["247-4"]  = { Position = vector3(547.823, 2670.906, 42.156) },       -- Harmony
        ["247-5"]  = { Position = vec3(25.918663, -1346.950195, 29.497021) }, -- Strawberry (Families)
        ["247-6"]  = { Position = vector3(1961.464, 3740.672, 32.343) },      -- Grapeseed
        ["247-7"]  = { Position = vector3(-3244.08, 1001.32, 12.83) },        -- Chumash
        ["247-7"]  = { Position = vector3(-3041.06, 585.103, 7.90) },         -- Banham Canyon
        ["247-8"]  = { Position = vector3(374.17, 327.80, 103.56) },          -- Centre de Vinewood
        ["247-9"]  = { Position = vector3(2678.367, 3280.68, 55.2411) },      -- Grand Señora Desert
    },
}
