Config.IllegalTablet = {
    -- Gang Title / Tier System
    -- Tier 1: default for player-created groups
    -- Tier 2+: set by staff when creating groups (or promoted later)
    GangTiers = {
        [1] = {
            name = "Petite frappe",
            description = "Faites des petits braquages, créez des contacts, vendez de la drogue achetée à des grands groupes dans la rue.",
            specialization = "Indéfini",
            color = "#95a5a6",
        },
        [2] = {
            name = "Gang de Rue",
            description = "Votre gang contrôle les rues. Spécialisez-vous dans la drogue de rue et les vols pour asseoir votre domination.",
            specialization = "Drogue de rue / Vols",
            color = "#e67e22",
        },
        [3] = {
            name = "Réseau Mafieux",
            description = "Votre organisation opère dans l'ombre. Le blanchiment d'argent et le trafic d'armes sont vos spécialités.",
            specialization = "Blanchiment / Armes",
            color = "#8e44ad",
        },
        [4] = {
            name = "Empire Criminel",
            description = "Vous contrôlez tout. Drogue, armes, blanchiment, territoires — rien ne vous échappe.",
            specialization = "Tout",
            color = "#c0392b",
        },
    },

    -- Group creation settings (for players via tablet)
    GroupCreation = {
        enabled = true,
        price = 500000, -- prix en argent sale pour créer un groupe
        minNameLength = 3,
        maxNameLength = 20,
        minLabelLength = 3,
        maxLabelLength = 30,
        -- Noms internes réservés (jobs système, métiers légaux, etc.)
        reservedNames = {
            "police", "ambulance", "mechanic", "taxi", "judge", "reporter",
            "realestateagent", "banker", "cardealer", "unemployed", "unemployed2",
            "admin", "staff", "moderator", "owner", "superadmin", "god",
            "lspd", "bcso", "sasp", "ems", "samu", "pompier", "gouv",
            "government", "mairie", "doj", "fbi", "dea", "atf", "cia",
            "off_white", "off_black", "off_ballas", "off_vagos", "off_lost",
            "test", "debug", "system", "server", "console", "root",
        },
        -- Mots interdits dans le nom interne ET le label
        forbiddenWords = {
            "admin", "staff", "moder", "police", "flic", "keuf",
            "hack", "cheat", "exploit", "bug", "glitch",
            "nigger", "nigga", "negro", "nazi", "hitler", "isis",
            "pd", "fdp", "ntm", "nique", "putain", "pute", "salope",
            "bite", "couille", "enculer", "encule",
        },
    },

    -- XP & Level System (exponential curve)
    -- Formula: requiredXP = BaseXP * (Level ^ Exponent)
    XP = {
        BaseXP = 500,       -- XP needed for level 1->2
        Exponent = 1.15,    -- Exponential growth factor
        MaxLevel = 100,
    },

    -- Level unlock thresholds
    LevelUnlocks = {
        -- { level, type, description }
        { level = 1,  type = "max_members",     value = 10,  description = "10 membres maximum" },
        { level = 5,  type = "max_members",     value = 15,  description = "15 membres maximum" },
        { level = 5,  type = "max_ranks",       value = 5,   description = "5 rangs maximum" },
        { level = 10, type = "weapon_sell",      value = true, description = "Accès à la vente d'armes" },
        { level = 10, type = "max_members",     value = 20,  description = "20 membres maximum" },
        { level = 10, type = "max_ranks",       value = 7,   description = "7 rangs maximum" },
        { level = 15, type = "blackmarket_discount", value = 5, description = "5% de réduction BlackMarket" },
        { level = 20, type = "weapon_craft",     value = true, description = "Accès à la fabrication d'armes" },
        { level = 20, type = "max_members",     value = 25,  description = "25 membres maximum" },
        { level = 20, type = "max_ranks",       value = 10,  description = "10 rangs maximum" },
        { level = 21, type = "dealwp_tier",     value = 2,   description = "DealWP : quantités 3-15, offres normales" },
        { level = 21, type = "territory_tier",  value = 2,   description = "Territoires : +3 unités/vente, +10% prix, -10% attente" },
        { level = 30, type = "blackmarket_discount", value = 10, description = "10% de réduction BlackMarket" },
        { level = 30, type = "max_members",     value = 30,  description = "30 membres maximum" },
        { level = 40, type = "max_ranks",       value = 15,  description = "15 rangs maximum" },
        { level = 40, type = "max_members",     value = 35,  description = "35 membres maximum" },
        { level = 50, type = "blackmarket_discount", value = 15, description = "15% de réduction BlackMarket" },
        { level = 50, type = "max_members",     value = 40,  description = "40 membres maximum" },
        { level = 50, type = "max_ranks",       value = 20,  description = "20 rangs maximum" },
        { level = 51, type = "dealwp_tier",     value = 3,   description = "DealWP : quantités 8-30, offres lentes, +5% prix" },
        { level = 51, type = "territory_tier",  value = 3,   description = "Territoires : +6 unités/vente, +20% prix, -20% attente" },
        { level = 75, type = "max_members",     value = 50,  description = "50 membres maximum" },
        { level = 75, type = "blackmarket_discount", value = 20, description = "20% de réduction BlackMarket" },
        { level = 100, type = "max_members",    value = 60,  description = "60 membres maximum" },
        { level = 100, type = "max_ranks",      value = 25,  description = "25 rangs maximum" },
        { level = 100, type = "blackmarket_discount", value = 25, description = "25% de réduction BlackMarket" },
    },

    -- Missions definition
    -- type: "daily" or "weekly"
    -- category: links to game module (territories, gofast, laboratory, robbery, general)
    -- xp: XP reward on completion
    Missions = {
        Daily = {
            { id = "daily_territory_capture",   label = "Conquérant",           description = "Capturer un territoire",                  category = "territories",  objective = 1,  xp = 150 },
            { id = "daily_territory_defend",    label = "Défenseur",            description = "Défendre un territoire avec succès",       category = "territories",  objective = 1,  xp = 120 },
            { id = "daily_territory_points",    label = "Domination",           description = "Marquer 10 points de territoire",          category = "territories",  objective = 10, xp = 100 },
            { id = "daily_gofast_complete",     label = "Livreur Express",      description = "Compléter un Go-Fast",                    category = "gofast",       objective = 1,  xp = 200 },
            { id = "daily_gofast_multiple",     label = "Convoi",               description = "Compléter 3 Go-Fast",                     category = "gofast",       objective = 3,  xp = 500 },
            { id = "daily_lab_produce",         label = "Chimiste",             description = "Produire 10 unités en laboratoire",        category = "laboratory",   objective = 10, xp = 130 },
            { id = "daily_lab_produce_large",   label = "Production de masse",  description = "Produire 25 unités en laboratoire",        category = "laboratory",   objective = 25, xp = 300 },
            { id = "daily_robbery_store",       label = "Braqueur",             description = "Braquer un supermarché",                   category = "robbery",      objective = 1,  xp = 180 },
            { id = "daily_robbery_atm",         label = "Perceur de coffre",    description = "Braquer un ATM",                          category = "robbery",      objective = 1,  xp = 150 },
            { id = "daily_sell_drugs",          label = "Dealer",               description = "Vendre 20 drogues",                       category = "general",      objective = 20, xp = 160 },
            { id = "daily_dirty_money",         label = "Blanchisseur",         description = "Gagner $50,000 en argent sale",            category = "general",      objective = 50000, xp = 200 },
        },
        Weekly = {
            { id = "weekly_territory_hold",     label = "Seigneur de guerre",   description = "Posséder 3 territoires simultanément",     category = "territories",  objective = 3,  xp = 1000 },
            { id = "weekly_territory_captures", label = "Impérialiste",         description = "Capturer 10 territoires",                  category = "territories",  objective = 10, xp = 1500 },
            { id = "weekly_gofast_master",      label = "Roi de la route",      description = "Compléter 10 Go-Fast",                    category = "gofast",       objective = 10, xp = 2000 },
            { id = "weekly_lab_mass",           label = "Baron de la drogue",   description = "Produire 100 unités en laboratoire",       category = "laboratory",   objective = 100, xp = 1800 },
            { id = "weekly_robbery_bank",       label = "Braqueur de banque",   description = "Braquer une banque",                      category = "robbery",      objective = 1,  xp = 2500 },
            { id = "weekly_robbery_spree",      label = "Série noire",          description = "Braquer 5 commerces",                     category = "robbery",      objective = 5,  xp = 1200 },
            { id = "weekly_sell_drugs_mass",    label = "Cartel",               description = "Vendre 100 drogues",                      category = "general",      objective = 100, xp = 1500 },
            { id = "weekly_dirty_money_mass",   label = "Empire",               description = "Gagner $250,000 en argent sale",           category = "general",      objective = 250000, xp = 2000 },
            { id = "weekly_members_online",     label = "Force collective",     description = "Avoir 5 membres en ligne simultanément",   category = "general",      objective = 5,  xp = 800 },
        },
        -- How many missions each group gets per reset
        DailyCount = 3,
        WeeklyCount = 2,
    },
}
