Config.PoliceTablet = {
    Enabled = true,
    OpenCommand = "policetablet",
    AgentColors = {
        "#3b82f6", "#10b981", "#f59e0b", "#ef4444", "#a855f7",
        "#06b6d4", "#ec4899", "#84cc16", "#f97316", "#6366f1"
    },
    GroupColors = {
        "#1e3a8a", "#065f46", "#92400e", "#7f1d1d", "#581c87",
        "#0e7490", "#9d174d", "#3f6212"
    },
    DefaultPenalCode = {
        ["Routier"] = {
            { label = "Excès de vitesse < 20 km/h",          price = 150,  jail = 0 },
            { label = "Excès de vitesse 20-50 km/h",         price = 450,  jail = 0 },
            { label = "Excès de vitesse > 50 km/h",          price = 900,  jail = 5 },
            { label = "Conduite sans permis",                price = 1200, jail = 10 },
            { label = "Délit de fuite",                      price = 1800, jail = 15 },
            { label = "Refus d'obtempérer",                  price = 2500, jail = 25 },
            { label = "Conduite en état d'ivresse",          price = 1500, jail = 15 },
        },
        ["Atteinte aux biens"] = {
            { label = "Vol simple",                          price = 800,  jail = 10 },
            { label = "Vol avec effraction",                 price = 2200, jail = 30 },
            { label = "Vol à main armée",                    price = 5000, jail = 60 },
            { label = "Dégradation de bien public",          price = 600,  jail = 5 },
            { label = "Recel d'objet volé",                  price = 1200, jail = 15 },
        },
        ["Atteinte aux personnes"] = {
            { label = "Violences légères",                   price = 1000, jail = 15 },
            { label = "Violences aggravées",                 price = 3500, jail = 45 },
            { label = "Tentative d'homicide",                price = 8000, jail = 90 },
            { label = "Homicide volontaire",                 price = 15000, jail = 120 },
            { label = "Menace de mort",                      price = 1500, jail = 20 },
            { label = "Prise d'otage",                       price = 10000, jail = 90 },
        },
        ["Stupéfiants"] = {
            { label = "Détention de stupéfiants",            price = 1500, jail = 20 },
            { label = "Trafic de stupéfiants",               price = 6000, jail = 75 },
            { label = "Consommation sur voie publique",      price = 400,  jail = 0 },
        },
        ["Armes"] = {
            { label = "Port d'arme blanche illégal",         price = 1000, jail = 15 },
            { label = "Port d'arme à feu illégal",           price = 4000, jail = 60 },
            { label = "Trafic d'arme à feu",                 price = 12000, jail = 100 },
            { label = "Tir en zone urbaine",                 price = 3500, jail = 40 },
        },
        ["Outrage et rébellion"] = {
            { label = "Outrage à agent",                     price = 800,  jail = 5 },
            { label = "Rébellion",                           price = 1500, jail = 20 },
            { label = "Violences sur agent",                 price = 5000, jail = 70 },
            { label = "Évasion",                             price = 4000, jail = 50 },
        },
    },
}
