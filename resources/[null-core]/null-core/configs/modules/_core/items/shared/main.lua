Config.Items = Config.Items or {}

Config.Items.Descriptions = {
    ["water"] = "Une bouteille d'eau fraîche pour vous hydrater.",
    ["bread"] = "Un pain frais qui restaure un peu de faim.",
    ["burger"] = "Un burger savoureux qui restaure beaucoup de faim.",
    
    ["medikit"] = "Kit médical complet permettant de soigner les blessures graves.",
    ["bandage"] = "Bandage basique pour soigner les blessures légères.",
    
    ["ammo_pistol"] = "Munitions pour armes de poing (9mm).",
    ["ammo_rifle"] = "Munitions pour fusils d'assaut (5.56mm).",
    ["ammo_sniper"] = "Munitions pour fusils de précision (.308).",
    ["ammo_shotgun"] = "Cartouches pour fusils à pompe (12 gauge).",
    
    ["radio"] = "Radio portable pour communiquer avec vos alliés.",
    ["phone"] = "Téléphone portable pour appeler et envoyer des messages.",
    ["kevlar"] = "Gilet pare-balles offrant une protection contre les projectiles.",
    ["kevlar_light"] = "Gilet pare-balles léger, protection basique (30%).",
    ["kevlar_medium"] = "Gilet pare-balles standard, bonne protection (60%).",
    ["kevlar_heavy"] = "Gilet pare-balles lourd, protection maximale (100%).",
}

function Config.Items.GetDescription(itemName)
    return Config.Items.Descriptions[itemName] or nil
end
