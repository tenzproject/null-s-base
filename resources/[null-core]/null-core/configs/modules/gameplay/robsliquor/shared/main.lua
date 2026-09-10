-- Rob's Liquor — alcohol & snacks
Config.RobsLiquor = {
    StoreConfig = {
        Brand = {
            id = "robsliquor",
            name = "Rob's Liquor",
            logo = "shopui/brands/robs-liquor.png",
            bgColor = "#DC0000",
            accentColor = "#ffb300",
            tagline = "The drinks of your nights.",
        },
        Categories = {
            { name = "Tous", type = "all", icon = "ic:round-clear-all" }, --! Required for all shops
            { name = "Nourritures", type = "food", icon = "mdi:food-drumstick" },
            { name = "Boissons", type = "drinks", icon = "ion:water-sharp" },
            { name = "Alcool", type = "alcohol", icon = "mdi:glass-cocktail" },
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

            --alcool 
            { name = "beer1", label = "Bière Liberty", category = "alcohol", price = 35 },
            { name = "beer2", label = "Bière Stronzo", category = "alcohol", price = 35 },
            { name = "bourbon", label = "Bourbon Old Blood", category = "alcohol", price = 35 },
            { name = "pastis", label = "Pastis 13", category = "alcohol", price = 35 },
            { name = "sake", label = "Saké Natsuki", category = "alcohol", price = 35 },
            { name = "vodka", label = "Vodka Crystal", category = "alcohol", price = 35 },
            { name = "wisky", label = "Whisky Richard", category = "alcohol", price = 35 },

            -- autres
            { name = "bandage", label = "Bandage", category = "others", price = 210 },
            { name = "deo", label = "Déodorant", category = "others", price = 110 },
        },
        Locales = {
            mainTitle = "Rob's Liquor",
            mainTag = "Since 1992",
            mainDescription = "Le meilleur choix d'alcools de Los Santos.\nBuvez responsable.",
        },
    },
    List = {
        ["robs-1"] = { Position = vector3(-1222.915, -906.983, 12.326) },  -- Del Perro
        ["robs-2"] = { Position = vector3(1135.808,  -982.281, 46.415) },  -- Little Seoul
        ["robs-3"] = { Position = vector3(-1487.555, -379.107, 40.163) },  -- Morningwood
        ["robs-4"] = { Position = vector3(-2968.243, 390.910,  15.043) },  -- Great Ocean Hwy
        ["robs-5"] = { Position = vector3(1166.024,  2708.925, 38.157) },  -- Harmony
        ["robs-6"] = { Position = vec3(4467.30, -4465.03, 4.24) },         -- Cayo
        ["robs-7"] = { Position = vector3(1392.6, 3605.0432, 34.98093) },  -- Sandy Shores
    },
}
