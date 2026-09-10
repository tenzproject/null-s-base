ESX.CanRenameItem = {
    --["kevlar_metadata"] = true,
    --["phone"] = false,
}

for k,v in pairs(Config.ContribItem) do 
    --ESX.CanRenameItem[k] = true
end

ESX.DefaultMetadata = {
    ["kevlar_metadata"] = function ()
        return {
            unique = true,
            plate = 0,
            uniqueId = ("%s-%s-%s"):format(os.time(), math.random(1,9999), math.random(1,9999)),
            label = "Kevlar",
        }
    end,
    ["leather_briefcase"] = function (identifier)
        local briefcaseID = createBriefcase(identifier)

        return {
            unique = true,
            briefcaseID = briefcaseID
        }
    end,
    ["steel_briefcase"] = function (identifier)
        local briefcaseID = createBriefcase(identifier)

        return {
            unique = true,
            briefcaseID = briefcaseID
        }
    end,
    ["cigarette_pack"] = function ()
        return {
            unique = true,
            cigarette = 10
        }
    end,

    ["fishing_road_wood"] = function ()
        return {
            unique = true,
            durability = 250
        }
    end,

    ["fishing_road_silver"] = function ()
        return {
            unique = true,
            durability = 1000
        }
    end,

    ["fishing_road_carbone"] = function ()
        return {
            unique = true,
            durability = 25000
        }
    end,
}

-- Auto-register kevlar items DefaultMetadata
if Config.Kevlar and Config.Kevlar.Items then
    for itemName, kevlarCfg in pairs(Config.Kevlar.Items) do
        ESX.DefaultMetadata[itemName] = function()
            return {
                unique = true,
                uniqueId = ("%s-%s-%s"):format(os.time(), math.random(1, 9999), math.random(1, 9999)),
                durability = kevlarCfg.maxDurability,
                maxDurability = kevlarCfg.maxDurability,
                maxArmor = kevlarCfg.maxArmor,
                kevlarType = itemName,
                label = kevlarCfg.label,
            }
        end
    end
end

ESX.InventoryType = {
    DEBUG = "DEBUG",
    PLAYER = "PLAYER",
    VEHICLE = "VEHICLE",
    VEHICLE_GLOVE_BOX = "VEHICLE_GLOVE_BOX",
    PROPERTY = "PROPERTY",
    GUNLABS = "GUNLABS",
    DRUGLABS = "DRUGLABS",
    SOCIETY = "SOCIETY",
    POLICE_SEIZURE = "POLICE_SEIZURE",
    FRIDGE = "FRIDGE",
    BRIEFCASE = "BRIEFCASE",
    CHRISTMAS_GIFT = "CHRISTMAS_GIFT",
    STASH = "STASH",
    GROUND = "GROUND",
}

ESX.InventoryTypeName = {
    [ESX.InventoryType.PLAYER] = "Joueur",
    [ESX.InventoryType.VEHICLE] = "Véhicule",
    [ESX.InventoryType.VEHICLE_GLOVE_BOX] = "Boite à gant",
    [ESX.InventoryType.PROPERTY] = "Propriété",
    [ESX.InventoryType.GUNLABS] = "Laboratoire d'arme",
    [ESX.InventoryType.DRUGLABS] = "Laboratoire de drogue",
    [ESX.InventoryType.SOCIETY] = "Entreprise/Factions",
    [ESX.InventoryType.DEBUG] = "Staff/Dev",
    [ESX.InventoryType.POLICE_SEIZURE] = "Coffre de saisie",
    [ESX.InventoryType.FRIDGE] = "Frigo",
    [ESX.InventoryType.BRIEFCASE] = "Malette",
    [ESX.InventoryType.CHRISTMAS_GIFT] = "Cadeau de Noël",
    [ESX.InventoryType.STASH] = "Carton",
    [ESX.InventoryType.GROUND] = "Carton au sol",
}

ESX.InventoryWeightDefault = {
    [ESX.InventoryType.PLAYER] = 24,
    [ESX.InventoryType.VEHICLE] = 100,
    [ESX.InventoryType.VEHICLE_GLOVE_BOX] = 5,
    [ESX.InventoryType.PROPERTY] = 24,
    [ESX.InventoryType.GUNLABS] = -1,
    [ESX.InventoryType.DRUGLABS] = -1,
    [ESX.InventoryType.DEBUG] = -1,
    [ESX.InventoryType.SOCIETY] = 1000,
    [ESX.InventoryType.POLICE_SEIZURE] = -1,
    [ESX.InventoryType.FRIDGE] = -1,
    [ESX.InventoryType.BRIEFCASE] = -1,
    [ESX.InventoryType.CHRISTMAS_GIFT] = 15,
    [ESX.InventoryType.STASH] = -1,
}

ESX.InventoryTransfert = {
    [ESX.InventoryType.GUNLABS] = {
        items = {
            "rusty_weapon_part_1",
            "rusty_weapon_part_2",
            "weapon_part"
        }
    },
    [ESX.InventoryType.FRIDGE] = {
        cash = false,
        dirtycash = false,
        weapons = {},
        items = {
            "bread",
            "hotdog",
            "cupcake",
            "pizzahallal",
            "pizzaorientale",
            "pizza4fromage",
            "pizzaforestiere",
            "Spaghettibolo",
            "triplecheese",
            "doublecheese",
            "280burger",
            "baconburger",
            "nuggets",
            "oignonsrings",
            "grandefrite",
            "platjaponnais",
            "nespresso",
            "tacos",
            "natchos",
            "tacos",
            "natchos",
            "filetofish",
            "doublefilet",
            "bigmachalal",
            "macfirstpoisson",
            "cupcakecitron",
            "cupcakecerise",
            "cupcakefraise",
            "macaronfraise",
            "macaronmyrtille",
            "macaronpomme",
            "macaroncaramel",
            "nounoursalaguimauve",
            "trianglesaumon",
            "trianglepoulet",
            "triangleboeuf",
            "nuggetshalal",
            "potatoes",
            "cocacherry",
            "dragibus",
            "sucette",
            "kitkat",
            "mochi",
            "dessertfraise",
            "tomatemozza",
            "patesaumon",
            "pizzamargaritta",
            "spaghettibolo",
            "coca",
        }
    },
    [ESX.InventoryType.BRIEFCASE] = {
        items = {},
        weapons = {},
    },
    [ESX.InventoryType.CHRISTMAS_GIFT] = {
        blacklistItems = { "christmas_gift" },
    }
}

ESX.InventoryHover = {
    ["cayo_passport"] = function (item)
        return {
            ["Nom désigné au Passeport"] = "Null",
            ["Péremption dans"] = "30 jours",
        }
    end,

    --[[["fishing_road_wood"] = function (item)
        return {
            ["Durabilité"] = item.metadata["durability"]
        }
    end,

    ["fishing_road_silver"] = function (item)
        return {
            ["Durabilité"] = item.metadata["durability"]
        }
    end,

    ["fishing_road_carbone"] = function (item)
        return {
            ["Durabilité"] = item.metadata["durability"]
        }
    end]]
}


-- for k,v in pairs(Config.foodItems) do 
--     ESX.InventoryHover[k] = function(item)
--         return {
--             ["Péremption dans"] = item.metadata["expiration"]
--         }
--     end
-- end


ESX.InventoryProgress = {}

-- Auto-register kevlar items InventoryProgress (durability bar)
if Config.Kevlar and Config.Kevlar.Items then
    local kevlarColors = {
        ["kevlar_light"] = "rgb(59, 130, 246)",
        ["kevlar_medium"] = "rgb(245, 158, 11)",
        ["kevlar_heavy"] = "rgb(239, 68, 68)",
    }
    for itemName, kevlarCfg in pairs(Config.Kevlar.Items) do
        ESX.InventoryProgress[itemName] = function(item)
            local dur = item.metadata and item.metadata.durability or 0
            local maxDur = kevlarCfg.maxDurability or 100
            return {
                current = dur <= 0 and 0.1 or dur,
                maximum = maxDur,
                color = kevlarColors[itemName] or "rgb(59, 130, 246)"
            }
        end
    end
end

ESX.InventoryHoverWeapon = {}

ESX.InventoryProgressWeapon = {}