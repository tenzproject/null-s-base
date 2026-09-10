Config.Kevlar = {
    Items = {
        ["kevlar_light"] = {
            label = "Kevlar Léger",
            description = "Gilet pare-balles léger, protection basique.",
            maxArmor = 30,
            maxDurability = 30,
            price = 800,
            weight = 1.5,
            bproof = { male = { bproof_1 = 16, bproof_2 = 0 }, female = { bproof_1 = 16, bproof_2 = 0 } },
        },
        ["kevlar_medium"] = {
            label = "Kevlar Standard",
            description = "Gilet pare-balles standard, bonne protection.",
            maxArmor = 60,
            maxDurability = 60,
            price = 2500,
            weight = 2.5,
            bproof = { male = { bproof_1 = 1, bproof_2 = 1 }, female = { bproof_1 = 1, bproof_2 = 1 } },
        },
        ["kevlar_heavy"] = {
            label = "Kevlar Lourd",
            description = "Gilet pare-balles lourd, protection maximale.",
            maxArmor = 100,
            maxDurability = 100,
            price = 5000,
            weight = 4.0,
            bproof = { male = { bproof_1 = 16, bproof_2 = 2 }, female = { bproof_1 = 18, bproof_2 = 2 } },
        },
    },
}

function Config.Kevlar.IsKevlarItem(itemName)
    return Config.Kevlar.Items[itemName] ~= nil
end

function Config.Kevlar.GetKevlarConfig(itemName)
    return Config.Kevlar.Items[itemName]
end
