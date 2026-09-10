Config = Config or {}

Config.Licenses = {
    Listes = {
        ["identity_card"] = {
            indexmenu = 1,
            label = "Carte d'identité",
            description = "Acheter une nouvelle carte d'identité",
            type = "identity_card",
            card = true,
            price = 100,
        },
        ["dmv"] = {
            label = "Code de la route",
            type = "driver",
            card = false,
        },
        ["drive"] = {
            indexmenu = 2,
            label = "Permis de conduire",
            description = "Acheter un nouveau permis de conduire",
            type = "driver",
            card = true,
            price = 100,
        },
        ["drive_bike"] = {
            label = "Permis moto",
            type = "driver",
            card = false,
        },
        ["drive_truck"] = {
            label = "Permis camion",
            type = "driver",
            card = false,
        },
        ["weapon"] = {
            indexmenu = 3,
            label = "PPA Léger",
            description = "Acheter un nouveau PPA",
            type = "weapon",
            card = true,
            price = 100,
        },
        ["weapon2"] = {
            label = "PPA Lourd",
            type = "weapon",
            card = false,
        },
    },
}