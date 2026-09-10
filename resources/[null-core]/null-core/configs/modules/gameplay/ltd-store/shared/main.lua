Config.LTD = {
    StoreConfig = {
        Brand = {
            id = "ltd",
            name = "LTD Gasoline",
            logo = "shopui/brands/limited-ltd-gasoline.png",
            bgColor = "#232959",
            accentColor = "#aa3128",
            tagline = "Always open. Always fueling.",
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
            mainTitle = "LTD",
            mainTag = "24/7",
            mainDescription = "Bienvenue dans votre boutique locale, où nous sommes toujours là pour vous, de jour comme de nuit !\nDécouvrez une sélection soigneusement choisie de produits haut de gamme, adaptés à tous vos besoins.",
        }, 
    }, 
    List = {
        ["LTD-1"] = {Position = vector3(-707.40, -914.74, 19.21)},   -- Little Seoul
        ["LTD-2"] = {Position = vector3(-48.199, -1757.80, 29.42)},  -- Davis
        ["LTD-3"] = {Position = vector3(-1821.41, 793.88, 138.11)},  -- Richman Glen
        ["LTD-4"] = {Position = vector3(1698.26, 4924.35, 42.06)},   -- Grapeseed
        ["LTD-5"] = {Position = vector3(1163.56, -323.66, 69.20)},   -- Mirror Park
    }
} 