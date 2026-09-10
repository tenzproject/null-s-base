-- =============================================================================
-- Framework — paramètres généraux du framework Null
-- =============================================================================

-- @dashboardLabel: Préfixe de commande
-- @dashboardDescription: Caractère utilisé pour préfixer les commandes (/ par défaut). Changez-le si vous souhaitez utiliser "!" par exemple.
-- @dashboardGroup: Framework
-- @dashboardWidget: text
Config.CommandPrefix = '/'

-- @dashboardLabel: Position de spawn par défaut
-- @dashboardDescription: Position (x,y,z,heading) où les nouveaux joueurs apparaissent lors de leur première connexion.
-- @dashboardGroup: Framework
-- @dashboardWidget: vector4
Config.DefaultPosition = vector4(-1037.8951416016, -2738.2416992188, 20.169288635254, 329.54357910156)

-- @dashboardLabel: Poids max inventaire
-- @dashboardDescription: Poids maximum (en kg) que peut porter un joueur dans son inventaire par défaut.
-- @dashboardGroup: Inventaire
-- @dashboardWidget: number
-- @dashboardMin: 1
-- @dashboardMax: 200
Config.MaxWeight = 24

-- @dashboardLabel: Message de whitelist
-- @dashboardDescription: Message affiché aux joueurs non whitelistés qui tentent de se connecter.
-- @dashboardGroup: Framework
-- @dashboardWidget: textarea
Config.whitelistMessage = "Notre serveur est en maintenance, merci de revenir plus tard."

-- @dashboardLabel: Licenses privilégiées
-- @dashboardDescription: Licenses Rockstar des joueurs exemptés de la whitelist (accès permanent). Format : 'license:XXX' = true.
-- @dashboardGroup: Framework
-- @dashboardWidget: object
-- @dashboardSensitive
Config.BypassLicense = {
    ['license:5474636beca7e2658e6f77079a1e6c47f98af4b6'] = true
}

-- @dashboardLabel: Jours de paie
-- @dashboardDescription: Jours du mois auxquels les employés reçoivent leur salaire. Les joueurs déconnectés ne touchent pas leur paie.
-- @dashboardGroup: Économie
-- @dashboardWidget: list
Config.PayAtDays = {
    3,
    10,
    17,
    24
}

-- @dashboardLabel: Poids custom par véhicule
-- @dashboardDescription: Override du poids maximum du coffre pour des véhicules spécifiques (par spawn name). Prioritaire sur Config.WeightTrunk.
-- @dashboardGroup: Inventaire
-- @dashboardWidget: object
Config.CustomVehicleWeight = {
    ["burrito2"] = 750,
    ["burrito3"] = 750,
}

-- @dashboardLabel: Poids max coffre par classe
-- @dashboardDescription: Poids maximum par défaut du coffre selon la classe du véhicule GTA (0=compacts, 10=industrial, etc.). CustomVehicleWeight prime sur ce tableau.
-- @dashboardGroup: Inventaire
-- @dashboardWidget: object
Config.WeightTrunk = {
    [0] = 75, -- Compacts
    [1] = 75, -- Sedans
    [2] = 150, -- SUVs
    [3] = 75, --Coupes
    [4] = 75, --Muscle
    [5] = 75, -- SportsClassics
    [6] = 50, -- Sports
    [7] = 50, -- Super
    [8] = 10, -- Motorcycles
    [9] = 150, -- OffRoad
    [10] = 550, --Industrial
    [11] = 550, -- Utility
    [12] = 300, -- Vans
    [13] = 1, -- Cycles
    [14] = 50, -- Boats
    [15] = 50, -- Helicopters
    [16] = 550, -- Planes
    [17] = 100, -- Service
    [18] = 100, --Emergency
    [19] = 100, -- Military
    [20] = 500, -- Commercial
}