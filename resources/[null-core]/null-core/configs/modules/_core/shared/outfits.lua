Config.Outfits = Config.Outfits or {}

-- Types de vêtements qui composent une tenue
Config.Outfits.ClothesTypes = {
    "top",      -- Haut (torso_1, torso_2, tshirt_1, tshirt_2, arms, decals_1)
    "pants",    -- Pantalon (pants_1, pants_2)
    "shoes",    -- Chaussures (shoes_1, shoes_2)
    "mask",     -- Masque (mask_1, mask_2)
    "glasses",  -- Lunettes (glasses_1, glasses_2)
    "hat",      -- Chapeau (helmet_1, helmet_2)
    "bag",      -- Sac (bags_1, bags_2)
    "gillet",   -- Gilet (bproof_1, bproof_2)
    "bracelet", -- Bracelet (bracelets_1, bracelets_2)
    "ear",      -- Boucles d'oreilles (ears_1, ears_2)
    "watch",    -- Montre (watches_1, watches_2)
    "neck",     -- Collier (chain_1, chain_2)
}

-- Nombre minimum de pièces pour créer une tenue
Config.Outfits.MinPieces = 2

-- Nom par défaut d'une nouvelle tenue
Config.Outfits.DefaultName = "Tenue"
