Config = Config or {}

-- ============================================================================
-- VIP TIERS CONFIGURATION
-- ============================================================================
Config.VIP = {
    Tiers = {
        ["Basic"] = {
            level = 1,
            label = "VIP Basic",
            color = "#f59e0b",       -- amber
            icon = "⭐",
            price = 1000,            -- coins for 1 month
            durationDays = 31,

            -- Advantages
            advantages = {
                driftMode           = true,   -- Access to drift mode
                repairTimeMinutes   = 20,     -- Weapon repair time (normal: 60)
                deathTimerMinutes   = 5,      -- Respawn timer (normal: 10)
                maxWeight           = 35,     -- Inventory max weight (normal: 24)
                sellBoostPct        = 10,     -- +10% on drug territory sells
                farmSellBoostPct    = 10,     -- +10% on farm job sells
                farmHarvestBoostPct = 10,     -- +10% on farm harvest quantity
                activitySellBoostPct = 10,    -- +10% on interim activity sells
                animationAdjust     = true,   -- Fine-tune animation position
                changePed           = true,   -- Change roleplay ped model
                battlePassIncluded  = false,  -- Does NOT include battle pass
            },
        },
        ["Premium"] = {
            level = 2,
            label = "VIP Premium",
            color = "#a855f7",       -- purple
            icon = "💎",
            price = 2500,            -- coins for 1 month
            durationDays = 31,

            -- Advantages (all Basic + extras)
            advantages = {
                driftMode           = true,
                repairTimeMinutes   = 10,     -- Even faster repair
                deathTimerMinutes   = 3,      -- Even faster respawn
                maxWeight           = 40,     -- Even more weight
                sellBoostPct        = 20,     -- +20% on drug territory sells
                farmSellBoostPct    = 20,     -- +20% on farm job sells
                farmHarvestBoostPct = 15,     -- +15% on farm harvest quantity
                activitySellBoostPct = 20,    -- +20% on interim activity sells
                animationAdjust     = true,
                changePed           = true,
                battlePassIncluded  = true,   -- Includes premium battle pass
                exclusiveEmotes     = true,   -- Access to exclusive emotes
                priorityQueue       = true,   -- Priority in server queue
            },
        },
    },

    -- Default values (no VIP)
    Defaults = {
        repairTimeMinutes    = 60,
        deathTimerMinutes    = 10,
        maxWeight            = 24,     -- Config.MaxWeight
        sellBoostPct         = 0,
        farmSellBoostPct     = 0,
        farmHarvestBoostPct  = 0,
        activitySellBoostPct = 0,
    },

    -- UI display: list of all advantages with descriptions (for the VIP tab)
    AdvantagesList = {
        { key = "driftMode",           label = "Mode Drift",                    desc = "Active le mode drift sur vos véhicules",               icon = "zap",       basic = true,  premium = true  },
        { key = "repairTime",          label = "Réparation rapide",             desc = "Réparation d'armes accélérée",                         icon = "wrench",    basic = "20 min", premium = "10 min", default = "60 min" },
        { key = "deathTimer",          label = "Réapparition rapide",           desc = "Temps de réapparition à l'hôpital réduit",             icon = "heart",     basic = "5 min",  premium = "3 min",  default = "10 min" },
        { key = "maxWeight",           label = "Inventaire étendu",             desc = "Capacité de l'inventaire augmentée",                   icon = "package",   basic = "35 kg",  premium = "40 kg",  default = "24 kg" },
        { key = "sellBoost",           label = "Boost ventes drogues",          desc = "Bonus sur les ventes de drogues en territoire",        icon = "trending",  basic = "+10%",   premium = "+20%" },
        { key = "farmSellBoost",       label = "Boost ventes farms",            desc = "Bonus sur les ventes des jobs farms",                  icon = "sprout",    basic = "+10%",   premium = "+20%" },
        { key = "farmHarvestBoost",    label = "Boost récolte",                 desc = "Bonus sur la quantité récoltée",                       icon = "wheat",     basic = "+10%",   premium = "+15%" },
        { key = "activitySellBoost",   label = "Boost intérim",                desc = "Bonus sur les ventes des activités intérim",            icon = "briefcase", basic = "+10%",   premium = "+20%" },
        { key = "animationAdjust",     label = "Ajustement animations",         desc = "Ajustez précisément la position de vos animations",   icon = "move",      basic = true,  premium = true  },
        { key = "changePed",           label = "Changement de PED",             desc = "Changez votre modèle de personnage",                  icon = "user",      basic = true,  premium = true  },
        { key = "battlePass",          label = "Passe de Combat Premium",       desc = "Accès au passe premium avec récompenses exclusives",  icon = "shield",    basic = false, premium = true  },
        { key = "exclusiveEmotes",     label = "Emotes exclusives",             desc = "Accès à des animations exclusives VIP",               icon = "sparkles",  basic = false, premium = true  },
        { key = "priorityQueue",       label = "File prioritaire",              desc = "Priorité dans la file d'attente du serveur",          icon = "crown",     basic = false, premium = true  },
    },
}

-- ============================================================================
-- BATTLE PASS CONFIGURATION
-- ============================================================================
Config.BattlePass = {
    Enabled = true,

    -- Season duration in days (3 months ≈ 90 days)
    SeasonDurationDays = 90,

    -- Max level per season
    MaxLevel = 50,

    -- XP system
    XP = {
        -- XP required per level (linear + slight curve)
        BaseXP = 100,           -- XP for level 1
        XPPerLevel = 50,        -- Additional XP per level
        -- Formula: RequiredXP(level) = BaseXP + (level - 1) * XPPerLevel
        -- Level 1: 100 XP, Level 2: 150 XP, Level 10: 550 XP, Level 50: 2550 XP

        -- XP sources
        PlaytimeXPPerMinute = 1,        -- 1 XP per minute of playtime (60 XP/hour)
        PlaytimeTickMinutes = 5,         -- Award XP every 5 minutes (5 XP per tick)
    },

    -- Rewards per level: { level, free = reward|nil, premium = reward|nil }
    -- Reward types: "money", "item", "weapon", "vehicle", "coins", "crate"
    -- Current season rewards (Season 1 example)
    CurrentSeason = {
        id = "season_1",
        name = "Saison 1 : Origines",
        description = "La première saison du passe de combat",
        startDate = "2026-03-01",    -- Will be set by server on first boot
        color = "#f59e0b",

        Rewards = {
            -- Level 1-10
            { level = 1,  free = { type = "money",   amount = 10000,  label = "10 000$" },
                          premium = { type = "money",   amount = 25000,  label = "25 000$" } },
            { level = 2,  free = nil,
                          premium = { type = "item",    name = "bread",  amount = 20, label = "20 Pains" } },
            { level = 3,  free = { type = "item",    name = "water",  amount = 10, label = "10 Eaux" },
                          premium = { type = "item",    name = "water",  amount = 20, label = "20 Eaux" } },
            { level = 4,  free = nil,
                          premium = { type = "money",   amount = 30000,  label = "30 000$" } },
            { level = 5,  free = { type = "money",   amount = 15000,  label = "15 000$" },
                          premium = { type = "coins",   amount = 100,    label = "100 Coins" } },
            { level = 6,  free = nil,
                          premium = { type = "item",    name = "kevlar_light", amount = 1, label = "1 Kevlar léger" } },
            { level = 7,  free = nil,
                          premium = { type = "money",   amount = 40000,  label = "40 000$" } },
            { level = 8,  free = { type = "item",    name = "bread",  amount = 15, label = "15 Pains" },
                          premium = { type = "money",   amount = 50000,  label = "50 000$" } },
            { level = 9,  free = nil,
                          premium = { type = "item",    name = "water",  amount = 30, label = "30 Eaux" } },
            { level = 10, free = { type = "money",   amount = 25000,  label = "25 000$" },
                          premium = { type = "weapon",  name = "WEAPON_PISTOL", ammo = 100, label = "Pistolet", permanent = false } },

            -- Level 11-20
            { level = 11, free = nil,
                          premium = { type = "money",   amount = 60000,  label = "60 000$" } },
            { level = 12, free = nil,
                          premium = { type = "item",    name = "bread",  amount = 40, label = "40 Pains" } },
            { level = 13, free = { type = "money",   amount = 30000,  label = "30 000$" },
                          premium = { type = "money",   amount = 70000,  label = "70 000$" } },
            { level = 14, free = nil,
                          premium = { type = "item",    name = "kevlar_medium", amount = 1, label = "1 Kevlar moyen" } },
            { level = 15, free = { type = "item",    name = "water",  amount = 25, label = "25 Eaux" },
                          premium = { type = "crate",   name = "caisse_gold", amount = 1, label = "Caisse Gold" } },
            { level = 16, free = nil,
                          premium = { type = "money",   amount = 80000,  label = "80 000$" } },
            { level = 17, free = nil,
                          premium = { type = "item",    name = "water",  amount = 50, label = "50 Eaux" } },
            { level = 18, free = { type = "item",    name = "kevlar_light", amount = 1, label = "1 Kevlar léger" },
                          premium = { type = "money",   amount = 90000,  label = "90 000$" } },
            { level = 19, free = nil,
                          premium = { type = "item",    name = "bread",  amount = 60, label = "60 Pains" } },
            { level = 20, free = { type = "money",   amount = 50000,  label = "50 000$" },
                          premium = { type = "vehicle", model = "passat", label = "VW Passat" } },

            -- Level 21-30
            { level = 21, free = nil,
                          premium = { type = "money",   amount = 100000, label = "100 000$" } },
            { level = 22, free = nil,
                          premium = { type = "item",    name = "water",  amount = 60, label = "60 Eaux" } },
            { level = 23, free = { type = "money",   amount = 40000,  label = "40 000$" },
                          premium = { type = "money",   amount = 120000, label = "120 000$" } },
            { level = 24, free = nil,
                          premium = { type = "item",    name = "kevlar_heavy", amount = 1, label = "1 Kevlar lourd" } },
            { level = 25, free = { type = "money",   amount = 50000,  label = "50 000$" },
                          premium = { type = "coins",   amount = 200,    label = "200 Coins" } },
            { level = 26, free = nil,
                          premium = { type = "money",   amount = 140000, label = "140 000$" } },
            { level = 27, free = nil,
                          premium = { type = "item",    name = "bread",  amount = 80, label = "80 Pains" } },
            { level = 28, free = { type = "item",    name = "kevlar_medium", amount = 1, label = "1 Kevlar moyen" },
                          premium = { type = "money",   amount = 160000, label = "160 000$" } },
            { level = 29, free = nil,
                          premium = { type = "item",    name = "water",  amount = 80, label = "80 Eaux" } },
            { level = 30, free = { type = "money",   amount = 75000,  label = "75 000$" },
                          premium = { type = "weapon",  name = "WEAPON_MICROSMG", ammo = 250, label = "Micro SMG", permanent = false } },

            -- Level 31-40
            { level = 31, free = nil,
                          premium = { type = "money",   amount = 180000, label = "180 000$" } },
            { level = 32, free = nil,
                          premium = { type = "item",    name = "kevlar_medium", amount = 2, label = "2 Kevlars moyens" } },
            { level = 33, free = { type = "money",   amount = 60000,  label = "60 000$" },
                          premium = { type = "money",   amount = 200000, label = "200 000$" } },
            { level = 34, free = nil,
                          premium = { type = "item",    name = "bread",  amount = 100, label = "100 Pains" } },
            { level = 35, free = { type = "item",    name = "water",  amount = 50, label = "50 Eaux" },
                          premium = { type = "crate",   name = "caisse_diamond", amount = 1, label = "Caisse Légendaire" } },
            { level = 36, free = nil,
                          premium = { type = "money",   amount = 225000, label = "225 000$" } },
            { level = 37, free = nil,
                          premium = { type = "item",    name = "water",  amount = 100, label = "100 Eaux" } },
            { level = 38, free = { type = "item",    name = "kevlar_heavy", amount = 1, label = "1 Kevlar lourd" },
                          premium = { type = "money",   amount = 250000, label = "250 000$" } },
            { level = 39, free = nil,
                          premium = { type = "item",    name = "kevlar_heavy", amount = 2, label = "2 Kevlars lourds" } },
            { level = 40, free = { type = "money",   amount = 100000, label = "100 000$" },
                          premium = { type = "vehicle", model = "rs3", label = "Audi RS3" } },

            -- Level 41-50
            { level = 41, free = nil,
                          premium = { type = "money",   amount = 300000, label = "300 000$" } },
            { level = 42, free = nil,
                          premium = { type = "item",    name = "bread",  amount = 150, label = "150 Pains" } },
            { level = 43, free = { type = "money",   amount = 150000, label = "150 000$" },
                          premium = { type = "money",   amount = 350000, label = "350 000$" } },
            { level = 44, free = nil,
                          premium = { type = "item",    name = "kevlar_heavy", amount = 3, label = "3 Kevlars lourds" } },
            { level = 45, free = { type = "money",   amount = 200000, label = "200 000$" },
                          premium = { type = "coins",   amount = 300,    label = "300 Coins" } },
            { level = 46, free = nil,
                          premium = { type = "money",   amount = 400000, label = "400 000$" } },
            { level = 47, free = nil,
                          premium = { type = "item",    name = "water",  amount = 150, label = "150 Eaux" } },
            { level = 48, free = { type = "crate",   name = "caisse_gold", amount = 1, label = "Caisse Gold" },
                          premium = { type = "crate",   name = "caisse_ruby", amount = 1, label = "Caisse Ultime" } },
            { level = 49, free = nil,
                          premium = { type = "weapon",  name = "WEAPON_ASSAULTRIFLE", ammo = 250, label = "AK-47", permanent = false } },
            { level = 50, free = { type = "money",   amount = 500000, label = "500 000$" },
                          premium = { type = "vehicle", model = "brabus500", label = "Brabus 500" } },
        },
    },
}
