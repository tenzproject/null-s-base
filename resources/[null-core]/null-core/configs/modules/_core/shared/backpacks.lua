Config.Backpacks = Config.Backpacks or {}

-- Poids par défaut d'un sac (si pas dans Config.ListBags)
Config.Backpacks.DefaultWeight = 15

-- Diviseur de poids pour les sacs dans l'inventaire (poids du contenu / diviseur)
Config.Backpacks.WeightDivisor = 2

-- Types d'items interdits dans les sacs
Config.Backpacks.ForbiddenTypes = {
    -- "bag" est interdit automatiquement (pas de sac dans un sac)
}

-- Items spécifiques interdits dans les sacs
Config.Backpacks.ForbiddenItems = {
    -- ["item_name"] = true,
}
