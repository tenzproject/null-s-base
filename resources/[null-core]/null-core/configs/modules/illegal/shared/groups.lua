Config.IllegalGroups = {
    Sell = {
        Weapons = {
            ["WEAPON_SNSPISTOL"] = {price = 5000, name = 'WEAPON_SNSPISTOL', label = 'Pétoire'},
            ["WEAPON_PISTOL"] = {price = 7500, name = 'WEAPON_PISTOL', label = 'Pistolet'},
            ["WEAPON_PISTOL50"] = {price = 12500, name = 'WEAPON_PISTOL50', label = 'Calibre 50'},
            ["WEAPON_HEAVYPISTOL"] = {price = 15000, name = 'WEAPON_HEAVYPISTOL', label = 'Pistolet Lourd'},
            ["WEAPON_MINISMG"] = {price = 20000, name = 'WEAPON_MINISMG', label = 'Scorpion'},
            ["WEAPON_MACHINEPISTOL"] = {price = 32500, name = 'WEAPON_MACHINEPISTOL', label = 'Tec-9'},
            ["WEAPON_MICROSMG"] = {price = 40000, name = 'WEAPON_MICROSMG', label = 'Micro Uzi'},
            ["WEAPON_SAWNOFFSHOTGUN"] = {price = 50000, name = 'WEAPON_SAWNOFFSHOTGUN', label = 'Canon Scié'},
            ["WEAPON_COMPACTRIFLE"] = {price = 125000, name = 'WEAPON_COMPACTRIFLE', label = 'AK-U'},
            ["WEAPON_ASSAULTRIFLE"] = {price = 215000, name = 'WEAPON_ASSAULTRIFLE', label = 'AK-47'},    
        },
        Items = {
            ["armor"] = {price = 55500, name = 'armor', label = 'Kevlar'},
        }
    },
    Craft = {
        Weapons = {
            -- Mêlée
            ["WEAPON_BAT"] = {
                name = 'WEAPON_BAT', label = 'Batte de Baseball', time = 8,
                requirements = {
                    { itemName = "planche", label = "Planche", amount = 3 },
                    { itemName = "ruban_adhesif", label = "Ruban Adhésif", amount = 1 },
                }
            },
            ["WEAPON_KNIFE"] = {
                name = 'WEAPON_KNIFE', label = 'Couteau', time = 10,
                requirements = {
                    { itemName = "metal_brut", label = "Métal Brut", amount = 2 },
                    { itemName = "ruban_adhesif", label = "Ruban Adhésif", amount = 1 },
                }
            },
            -- Pistolets
            ["WEAPON_SNSPISTOL"] = {
                name = 'WEAPON_SNSPISTOL', label = 'Pétoire', time = 15,
                requirements = {
                    { itemName = "metal_brut", label = "Métal Brut", amount = 5 },
                    { itemName = "ressort", label = "Ressort", amount = 2 },
                    { itemName = "poudre_noire", label = "Poudre Noire", amount = 3 },
                }
            },
            ["WEAPON_PISTOL"] = {
                name = 'WEAPON_PISTOL', label = 'Pistolet', time = 20,
                requirements = {
                    { itemName = "metal_brut", label = "Métal Brut", amount = 8 },
                    { itemName = "ressort", label = "Ressort", amount = 3 },
                    { itemName = "poudre_noire", label = "Poudre Noire", amount = 5 },
                    { itemName = "composant_electronique", label = "Composant Électronique", amount = 1 },
                }
            },
            ["WEAPON_PISTOL50"] = {
                name = 'WEAPON_PISTOL50', label = 'Calibre 50', time = 25,
                requirements = {
                    { itemName = "metal_brut", label = "Métal Brut", amount = 12 },
                    { itemName = "ressort", label = "Ressort", amount = 5 },
                    { itemName = "poudre_noire", label = "Poudre Noire", amount = 8 },
                    { itemName = "composant_electronique", label = "Composant Électronique", amount = 2 },
                }
            },
            ["WEAPON_HEAVYPISTOL"] = {
                name = 'WEAPON_HEAVYPISTOL', label = 'Pistolet Lourd', time = 25,
                requirements = {
                    { itemName = "metal_brut", label = "Métal Brut", amount = 15 },
                    { itemName = "ressort", label = "Ressort", amount = 5 },
                    { itemName = "poudre_noire", label = "Poudre Noire", amount = 10 },
                    { itemName = "composant_electronique", label = "Composant Électronique", amount = 3 },
                }
            },
            -- SMGs
            ["WEAPON_MINISMG"] = {
                name = 'WEAPON_MINISMG', label = 'Scorpion', time = 30,
                requirements = {
                    { itemName = "metal_brut", label = "Métal Brut", amount = 18 },
                    { itemName = "ressort", label = "Ressort", amount = 8 },
                    { itemName = "poudre_noire", label = "Poudre Noire", amount = 12 },
                    { itemName = "composant_electronique", label = "Composant Électronique", amount = 4 },
                    { itemName = "plastique", label = "Plastique", amount = 3 },
                }
            },
            ["WEAPON_MACHINEPISTOL"] = {
                name = 'WEAPON_MACHINEPISTOL', label = 'Tec-9', time = 35,
                requirements = {
                    { itemName = "metal_brut", label = "Métal Brut", amount = 22 },
                    { itemName = "ressort", label = "Ressort", amount = 10 },
                    { itemName = "poudre_noire", label = "Poudre Noire", amount = 15 },
                    { itemName = "composant_electronique", label = "Composant Électronique", amount = 5 },
                    { itemName = "plastique", label = "Plastique", amount = 4 },
                }
            },
            ["WEAPON_MICROSMG"] = {
                name = 'WEAPON_MICROSMG', label = 'Micro Uzi', time = 40,
                requirements = {
                    { itemName = "metal_brut", label = "Métal Brut", amount = 25 },
                    { itemName = "ressort", label = "Ressort", amount = 12 },
                    { itemName = "poudre_noire", label = "Poudre Noire", amount = 18 },
                    { itemName = "composant_electronique", label = "Composant Électronique", amount = 6 },
                    { itemName = "plastique", label = "Plastique", amount = 5 },
                }
            },
            -- Fusils à pompe
            ["WEAPON_SAWNOFFSHOTGUN"] = {
                name = 'WEAPON_SAWNOFFSHOTGUN', label = 'Canon Scié', time = 35,
                requirements = {
                    { itemName = "metal_brut", label = "Métal Brut", amount = 20 },
                    { itemName = "ressort", label = "Ressort", amount = 8 },
                    { itemName = "poudre_noire", label = "Poudre Noire", amount = 15 },
                    { itemName = "planche", label = "Planche", amount = 3 },
                }
            },
            -- Fusils d'assaut
            ["WEAPON_COMPACTRIFLE"] = {
                name = 'WEAPON_COMPACTRIFLE', label = 'AK-U', time = 50,
                requirements = {
                    { itemName = "metal_brut", label = "Métal Brut", amount = 35 },
                    { itemName = "ressort", label = "Ressort", amount = 15 },
                    { itemName = "poudre_noire", label = "Poudre Noire", amount = 25 },
                    { itemName = "composant_electronique", label = "Composant Électronique", amount = 8 },
                    { itemName = "plastique", label = "Plastique", amount = 6 },
                }
            },
            ["WEAPON_ASSAULTRIFLE"] = {
                name = 'WEAPON_ASSAULTRIFLE', label = 'AK-47', time = 60,
                requirements = {
                    { itemName = "metal_brut", label = "Métal Brut", amount = 45 },
                    { itemName = "ressort", label = "Ressort", amount = 20 },
                    { itemName = "poudre_noire", label = "Poudre Noire", amount = 30 },
                    { itemName = "composant_electronique", label = "Composant Électronique", amount = 10 },
                    { itemName = "plastique", label = "Plastique", amount = 8 },
                }
            },
        }
    },

    -- Craft materials (for SQL migration)
    CraftMaterials = {
        { name = "metal_brut", label = "Métal Brut" },
        { name = "poudre_noire", label = "Poudre Noire" },
        { name = "composant_electronique", label = "Composant Électronique" },
        { name = "plastique", label = "Plastique" },
        { name = "ressort", label = "Ressort" },
        { name = "ruban_adhesif", label = "Ruban Adhésif" },
        { name = "tissu", label = "Tissu" },
        { name = "planche", label = "Planche" },
    },
}
