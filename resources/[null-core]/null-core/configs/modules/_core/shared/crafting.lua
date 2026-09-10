Config.Crafting = Config.Crafting or {}

-- Recettes de craft basiques (disponibles dans l'inventaire sans table)
Config.Crafting.BasicRecipes = {
    {
        id = "bandage",
        label = "Bandage",
        item = "bandage",
        type = "item",
        time = 5,
        category = "médical",
        description = "Fabriquer un bandage de fortune",
        requirements = {
            { itemName = "tissu", label = "Tissu", amount = 2 },
            { itemName = "ruban_adhesif", label = "Ruban Adhésif", amount = 1 },
        },
    },
    {
        id = "cagoule",
        label = "Cagoule",
        item = "cagoule",
        type = "item",
        time = 6,
        category = "équipement",
        description = "Fabriquer une cagoule improvisée",
        requirements = {
            { itemName = "tissu", label = "Tissu", amount = 3 },
            { itemName = "ruban_adhesif", label = "Ruban Adhésif", amount = 1 },
        },
    },
    {
        id = "medikit",
        label = "Medikit",
        item = "medikit",
        type = "item",
        time = 10,
        category = "médical",
        description = "Assembler un kit de premiers soins",
        requirements = {
            { itemName = "tissu", label = "Tissu", amount = 3 },
            { itemName = "plastique", label = "Plastique", amount = 1 },
            { itemName = "bandage", label = "Bandage", amount = 2 },
        },
    },
    {
        id = "armor",
        label = "Kevlar",
        item = "armor",
        type = "item",
        time = 15,
        category = "équipement",
        description = "Fabriquer un gilet pare-balles artisanal",
        requirements = {
            { itemName = "metal_brut", label = "Métal Brut", amount = 5 },
            { itemName = "tissu", label = "Tissu", amount = 4 },
            { itemName = "plastique", label = "Plastique", amount = 2 },
        },
    },
}

-- Tables de craft (positions dans le monde avec 3D interaction)
Config.Crafting.Tables = {
    -- Exemple de table de craft pour armes:
    -- {
    --     id = "weapon_table_1",
    --     label = "Atelier d'armement",
    --     coords = vector3(0.0, 0.0, 0.0),
    --     blip = {
    --         enabled = false,
    --         name = "Atelier",
    --         sprite = 566,
    --         color = 1,
    --         scale = 0.7,
    --     },
    --     conditions = {
    --         -- job = "mechanic",      -- Requiert ce job
    --         -- job2 = nil,            -- Requiert ce job2
    --         -- group = "admin",       -- Requiert ce groupe (staff)
    --     },
    --     recipes = {
    --         {
    --             id = "pistol_craft",
    --             label = "Pistolet artisanal",
    --             item = "WEAPON_PISTOL",
    --             type = "weapon",
    --             time = 15,
    --             category = "armes",
    --             requirements = {
    --                 { itemName = "metalscrap", label = "Ferraille", amount = 5 },
    --                 { itemName = "rubber", label = "Caoutchouc", amount = 2 },
    --             },
    --         },
    --     },
    -- },

    -- Exemple de table de craft cuisine (restaurant):
    -- {
    --     id = "kitchen_burgershot",
    --     label = "Cuisine - Burger Shot",
    --     coords = vector3(0.0, 0.0, 0.0),
    --     conditions = {
    --         job = "burgershot",
    --     },
    --     recipes = {
    --         {
    --             id = "burger",
    --             label = "Burger",
    --             item = "burger",
    --             type = "item",
    --             time = 8,
    --             category = "nourriture",
    --             requirements = {
    --                 { itemName = "bread", label = "Pain", amount = 1 },
    --                 { itemName = "meat", label = "Viande", amount = 1 },
    --             },
    --         },
    --     },
    -- },
}

-- Distance max pour interagir avec une table de craft
Config.Crafting.MaxDistance = 3.0

-- Animation pendant le craft
Config.Crafting.Animation = {
    dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
    anim = "machinic_loop_mechandplayer",
    flag = 1,
}
