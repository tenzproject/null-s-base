Config.AllPedModel = {"a_m_m_farmer_01", "a_m_m_eastsa_02", "a_m_m_og_boss_01", "a_m_m_soucent_01"}

Config.Territories = {
    ChanceToPedReply = 55,
    timeToWait = {
        min = 2000,
        max = 12000
    },
    weaponToReply = {
        "weapon_autoshotgun",
        "weapon_pistol"
    },
    moneyToDrop = {
        min = 10,
        max = 200
    },
    removeInstedOfMarket = 35, -- Combien de pourcentage il enleves quand c'est le prix du marché (E.G si la weed est a 20$ il la vend a 14$ sur les territoires car c'est plus simple que par DealWP)

    -- Bonus de niveau pour les territoires (basé sur le niveau du groupe tablette)
    -- Les territoires restent toujours plus rentables que DealWP grâce au prix marché + ces bonus
    levelBonuses = {
        { -- Petit groupe (niveau 1-20) : pas de bonus
            minLevel = 1,
            maxLevel = 20,
            maxCountSellBonus = 0,     -- Pas de bonus sur la quantité max vendue
            priceBonus = 1.0,          -- Prix normal
            waitMultiplier = 1.0,      -- Temps d'attente normal
        },
        { -- Groupe moyen (niveau 21-50) : léger bonus
            minLevel = 21,
            maxLevel = 50,
            maxCountSellBonus = 3,     -- +3 unités max par vente
            priceBonus = 1.10,         -- +10% sur le prix
            waitMultiplier = 0.90,     -- -10% temps d'attente
        },
        { -- Gros groupe (niveau 51-100) : bon bonus
            minLevel = 51,
            maxLevel = 100,
            maxCountSellBonus = 6,     -- +6 unités max par vente
            priceBonus = 1.20,         -- +20% sur le prix
            waitMultiplier = 0.80,     -- -20% temps d'attente
        },
    },
}