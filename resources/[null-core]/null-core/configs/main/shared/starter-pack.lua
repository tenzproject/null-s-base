if Config.StarterPack == nil then Config.StarterPack = {} end

-- type: @weapon = arme, @money = argent sale/propre, @item = Item, @vehicle = Véhicule 
Config.StarterPack["Illégal"] = {
    ["Gang"] = {
        -- {type = "weapon", name = "WEAPON_GLOCK17", quantity=5},
        {type = "weapon", name = "WEAPON_PISTOL", quantity=4},
        {type = "weapon", name = "WEAPON_PISTOL50", quantity=3},
        {type = "weapon", name = "WEAPON_BAT", quantity=3},
        {type = "money", name = "cash", quantity=30000},
        {type = "money", name = "dirtycash", quantity=70000},
        {type = "vehicle", name = "buffalo2", vehType="car", quantity=2},
        {type = "vehicle", name = "streiter", vehType="car", quantity=2},
        {type = "vehicle", name = "bf400", vehType="car", quantity=1},
        {type = "item", name = "radio", quantity=5},
        {type = "item", name = "mobilier", quantity=5},
    },
    ["Cartel"] = {
        {type = "weapon", name = "WEAPON_SPECIALCARBINE", quantity=4},
        -- {type = "weapon", name = "WEAPON_HKUMP", quantity=3},
        -- {type = "weapon", name = "WEAPON_PREDATOR", quantity=3},
        {type = "money", name = "cash", quantity=50000},
        {type = "money", name = "dirtycash", quantity=100000},
        -- {type = "vehicle", name = "gls63_de_dmz", quantity=4},
        -- {type = "vehicle", name = "velociraptor", quantity=1},
        {type = "vehicle", name = "bf400", quantity=1},
        {type = "item", name = "mobilier", quantity=5},
    },
    ["Organisation"] = {
        {type = "weapon", name = "WEAPON_SPECIALCARBINE", quantity=4},
        -- {type = "weapon", name = "WEAPON_HKUMP", quantity=3},
        -- {type = "weapon", name = "WEAPON_PREDATOR", quantity=3},
        {type = "money", name = "cash", quantity=50000},
        {type = "money", name = "dirtycash", quantity=100000},
        -- {type = "vehicle", name = "gls63_de_dmz", quantity=4},
        -- {type = "vehicle", name = "velociraptor", quantity=1},
        {type = "vehicle", name = "bf400", quantity=1},
        {type = "item", name = "mobilier", quantity=5},
    },
}

Config.StarterPack["Légal"] = {
    ["Entreprise Farm"] = {
        {type = "vehicle", name = "burrito", quantity=5},
        {type = "money", name = "cash", quantity=150000},
    },
    ["Entreprise Mécano"] = {
        {type = "money", name = "cash", quantity=300000},
    },
    ["Entreprise Bar"] = {
        {type = "money", name = "cash", quantity=300000},
    },
    ["Entreprise Police"] = {
        {type = "money", name = "cash", quantity=500000},
    },
}
