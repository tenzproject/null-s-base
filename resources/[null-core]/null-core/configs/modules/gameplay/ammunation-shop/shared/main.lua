Config.AmmunationShop = {
    repairPrice = 120,
    repairSysteme = true,
    repair = {
        ["pistol"] = 75,
        ["rifle"] = 220,
        ["shotgun"] = 120,
        ["sniper"] = 290,
    },
    timeToRepair = 120,
    timeToRepairVIP = 40,
    shops = {
        ["ammunation_1"] = {
            Shop = vector3(-661.30889892578,-938.42425537109,21.829364776611)
        },
        ["ammunation_2"] = {
            Shop = vec3(22.145428, -1106.716187, 29.797005),
            -- Repair = vec3(18.560125, -1109.671875, 29.797005)
        },
        ["ammunation_3"] = {
            Shop = vector3(814.50402832031,-2153.0822753906,29.619209289551)
        },
        ["ammunation_4"] = {
            Shop = vector3(-328.51657104492,6080.7626953125,31.454780578613)
        },
        ["ammunation_5"] = {
            Shop = vector3(248.87251281738,-49.93448638916,69.941215515137)
        },
        ["ammunation_6"] = {
            Shop = vector3(1695.4624023438,3756.8728027344,34.705379486084)
        },
        ["ammunation_7"] = {
            Shop = vector3(2566.8271484375,297.50985717773,108.7349319458)
        },
        ["ammunation_8"] = {
            Shop = vec3(-1305.438477, -394.297546, 36.695751)
        },
    },
    storeConfig = {
        Brand = {
            id = "ammunation",
            name = "Ammu-Nation",
            logo = "shopui/brands/ammu-nation.png",
            bgColor = "#1E1E1E",
            accentColor = "#c62828",
            tagline = "Guns, ammo, attitude.",
        },
        Categories = {
            { name = "Tous les produits", type = "all", icon = "ic:round-clear-all" },
            { name = "Armes", type = "weapons", icon = "mdi:pistol" },
            { name = "Munitions", type = "ammo", icon = "mdi:ammunition" },
            --{ name = "Attachments", type = "attachments", icon = "game-icons:machine-gun-magazine" },
            { name = "Kevlar", type = "armour", icon = "game-icons:kevlar-vest" },
            { name = "Réparation", type = "repair", icon = "mdi:wrench" },
        },
        Items = {
            -- Corps à corps
            { name = "WEAPON_KNUCKLE", label = "Poing Américain", category = "weapons", price = 150 },
            { name = "WEAPON_KNIFE", label = "Couteau", category = "weapons", price = 200 },
            { name = "WEAPON_SWITCHBLADE", label = "Couteau à Cran d'Arrêt", category = "weapons", price = 250 },
            { name = "WEAPON_DAGGER", label = "Dague", category = "weapons", price = 300 },
            { name = "WEAPON_MACHETE", label = "Machette", category = "weapons", price = 350 },
            { name = "WEAPON_HATCHET", label = "Hachette", category = "weapons", price = 400 },
            { name = "WEAPON_BATTLEAXE", label = "Hache de Combat", category = "weapons", price = 450 },
            { name = "WEAPON_STONE_HATCHET", label = "Hachette en Pierre", category = "weapons", price = 500 },
            { name = "WEAPON_BOTTLE", label = "Bouteille Cassée", category = "weapons", price = 100 },
            { name = "WEAPON_BAT", label = "Batte", category = "weapons", price = 200 },
            { name = "WEAPON_CROWBAR", label = "Pied-de-Biche", category = "weapons", price = 250 },
            { name = "WEAPON_GOLFCLUB", label = "Club de Golf", category = "weapons", price = 300 },
            { name = "WEAPON_HAMMER", label = "Marteau", category = "weapons", price = 250 },
            { name = "WEAPON_POOLCUE", label = "Queue de Billard", category = "weapons", price = 150 },
            { name = "WEAPON_WRENCH", label = "Clé à Molette", category = "weapons", price = 200 },

            { name = "ammo_pistol", label = "1x Chargeur Pistolet", category = "ammo", price = 6 },
            { name = "ammo_rifle", label = "1x Chargeur Mitrailette", category = "ammo", price = 11 },
            { name = "ammo_shotgun", label = "1x Chargeur Pompe", category = "ammo", price = 15 },
            { name = "ammo_sniper", label = "1x Chargeur Sniper", category = "ammo", price = 23 },
            { name = "kevlar_light", label = "Kevlar Léger", category = "armour", price = 800 },
            { name = "kevlar_medium", label = "Kevlar Standard", category = "armour", price = 2500 },
            { name = "kevlar_heavy", label = "Kevlar Lourd", category = "armour", price = 5000 },
        },
        Locales = {
            mainTitle = "Ammunations",
            mainTag = "24/7",
            mainDescription = "Bienvenue dans votre armurerie locale, où nous sommes toujours là pour vous, jour et nuit !\nDécouvrez une sélection soignée de produits de qualité, adaptés à tous vos besoins.",
        },
    },
}