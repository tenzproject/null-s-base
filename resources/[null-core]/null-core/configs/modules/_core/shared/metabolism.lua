--[[
    Metabolism — Système simplifié
    ------------------------------
    Deux stats persistantes (0-100) :
        hydration  : remplie par les boissons, décroît naturellement.
        fitness    : remplie par la qualité des repas, décroît naturellement.

    Score global = moyenne pondérée (hydration × 0.4 + fitness × 0.6).
    Affiché au joueur comme une seule barre "Forme".

    Poids corporel (hidden) : varie lentement selon la fitness (pur cosmétique
    interne, influence légèrement le sprint, jamais affiché dans l'UI).

    Création d'item : un seul champ "quality" suffit.
        quality = "junk"    → nourriture de supérette, peu de fitness
        quality = "meal"    → plat de restaurant, bon bonus fitness
        quality = "gourmet" → gastronomie, gros bonus fitness
        quality = "drink"   → boisson non-alcoolisée, hydratation
        quality = "soda"    → soda, hydratation faible
        quality = "alcohol" → alcool, déshydrate légèrement
    Les valeurs exactes (fitness/hydration +) sont calculées automatiquement
    via QualityPresets ci-dessous. Pas besoin de calories/protéines/vitamines.
]]

Config = Config or {}
Config.Metabolism = {}

-- ============================================================
-- General
-- ============================================================
Config.Metabolism.Enabled = false

-- Tick de décroissance (ms)
Config.Metabolism.TickInterval = 60 * 1000      -- 60 s

-- Auto-save (ms)
Config.Metabolism.SaveInterval = 5 * 60 * 1000  -- 5 min

-- ============================================================
-- Décroissance par tick (par minute)
-- ============================================================
Config.Metabolism.Decay = {
    hydration = 0.50,   -- boisson toutes les ~33 min pour rester au max
    fitness   = 0.30,   -- repas solide toutes les ~55 min pour rester au max
}

-- ============================================================
-- Effets gameplay (basés uniquement sur le score 0-100)
-- ============================================================
Config.Metabolism.Effects = {
    sprint  = { min = 0.90, max = 1.10 },   -- ± 10% de la vitesse de course
    stamina = { min = 60.0, max = 100.0 },  -- endurance GTA (MP0_STAMINA)
    regen   = { min = 0.0,  max = 1.0  },   -- PV/s de régénération passive
}

-- Poids caché (50-130 kg, neutre = 75)
-- Varie très lentement selon la fitness : fitness haute → poids stable,
-- fitness basse → léger amaigrissement. Influence marginale sur le sprint.
Config.Metabolism.Bodyweight = {
    neutral = 75.0,
    min     = 50.0,
    max     = 130.0,
    -- Gain de poids si fitness > 70 (bien nourri) : +0.01 kg/tick
    -- Perte de poids si fitness < 30 (sous-alimenté) : -0.02 kg/tick
    gainPerTick = 0.01,
    lossPerTick = 0.02,
}

-- ============================================================
-- Qualités — presets automatiques
-- Un item ne nécessite qu'un seul champ : quality = "..."
-- ============================================================
Config.Metabolism.QualityPresets = {
    --          fitness  hydration
    junk    = { fitness =  3.0, hydration =  0.0 },  -- bouffe de rue / supérette
    meal    = { fitness = 12.0, hydration =  2.0 },  -- plat de restaurant
    gourmet = { fitness = 22.0, hydration =  3.0 },  -- gastronomie
    drink   = { fitness =  0.0, hydration = 12.0 },  -- eau / jus / thé
    soda    = { fitness =  0.0, hydration =  5.0 },  -- soda (hydratation réduite)
    alcohol = { fitness = -2.0, hydration = -4.0 },  -- alcool (déshydrate)
}

-- Qualité par défaut si l'item n'a ni "quality" ni entrée dans Foods.
Config.Metabolism.Defaults = {
    hunger = "junk",
    thirst = "drink",
    drunk  = "alcohol",
}

-- ============================================================
-- Foods — surcharge par nom d'item (optionnel, héritage)
-- Deux formats acceptés :
--   court  : { quality = "meal" }
--   détaillé (legacy) : { fitness = 12, hydration = 2 }
-- ============================================================
Config.Metabolism.Foods = {
    -- Supérette / junk
    bread       = { quality = "junk" },
    chocolate   = { quality = "junk" },
    chips       = { quality = "junk" },
    burger      = { quality = "junk" },
    hotdog      = { quality = "junk" },
    sandwich    = { quality = "junk" },
    donut       = { quality = "junk" },

    -- Boissons supérette
    water       = { quality = "drink" },
    waterbottle = { quality = "drink" },
    coffee      = { quality = "drink" },
    cocacola    = { quality = "soda"  },
    energy      = { quality = "soda"  },
    icetea      = { quality = "soda"  },

    -- Plats restaurant
    pasta       = { quality = "meal" },
    salad       = { quality = "meal" },
    steak       = { quality = "meal" },
    fish        = { quality = "meal" },
    soup        = { quality = "meal" },
    omelette    = { quality = "meal" },
    rice        = { quality = "meal" },
    vegetables  = { quality = "meal" },
    fruit       = { quality = "meal" },

    -- Gastronomie
    gourmet_burger = { quality = "gourmet" },
    gourmet_steak  = { quality = "gourmet" },
    gourmet_pasta  = { quality = "gourmet" },
    gourmet_fish   = { quality = "gourmet" },
    gourmet_salad  = { quality = "gourmet" },

    -- Boissons restaurant
    juice    = { quality = "drink" },
    smoothie = { quality = "drink" },
    tea      = { quality = "drink" },

    -- Alcool
    vin    = { quality = "alcohol" },
    beer   = { quality = "alcohol" },
    whisky = { quality = "alcohol" },
}
