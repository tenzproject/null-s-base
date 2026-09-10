Config = Config or {}

-- =============================================================================
-- Général — paramètres globaux du core
-- =============================================================================

-- @dashboardLabel: Message de connexion
-- @dashboardDescription: Affiche un message à l'écran lorsque le joueur se connecte au serveur.
-- @dashboardGroup: Général
Config.Connection = {
    -- @dashboardLabel: Activer le message de connexion
    -- @dashboardGroup: Général
    -- @dashboardWidget: boolean
    ActiveMessage = true,
    -- @dashboardLabel: Texte du message de connexion
    -- @dashboardDescription: Texte affiché au joueur pendant la connexion.
    -- @dashboardGroup: Général
    -- @dashboardWidget: text
    Message = "✅ Connexion au serveur..."
}

-- @dashboardLabel: Téléphone utilisé
-- @dashboardDescription: Sélection du système de téléphone actif. Un seul doit être activé à la fois (lbphone OU qs).
-- @dashboardGroup: Intégrations
Config.Phone = {
    votre_telephone = {
        -- @dashboardLabel: Utiliser lb-phone
        -- @dashboardGroup: Intégrations
        -- @dashboardWidget: boolean
        ["lbphone"] = true,
        -- @dashboardLabel: Utiliser qs-smartphone
        -- @dashboardGroup: Intégrations
        -- @dashboardWidget: boolean
        ["qs"] = false,
    }
}

-- @dashboardLabel: Intervalle d'optimisation
-- @dashboardDescription: Nombre de requêtes avant actualisation du système d'optimisation. Augmentez cette valeur sur un serveur avec beaucoup de joueurs (recommandé : 1 pour <50 joueurs, 3-5 pour 100+).
-- @dashboardGroup: Performance
-- @dashboardWidget: number
-- @dashboardMin: 1
-- @dashboardMax: 20
Config.OptimisationSys = 1 

-- @dashboardLabel: Animations
-- @dashboardDescription: Paramètres pour les animations du menu.
-- @dashboardGroup: Général
Config.Animation = {
    ["Animations"] = {  -- menu animation par defaut
        use = true,

        IsPlayerInAnim = function()
            local success, result = pcall(function()
                return exports["Animations"]:IsPlayerInAnim()
            end)
            if success then return result end
            return false
        end,
        
        EmoteCommandStart = function(emotename)
            exports["Animations"]:EmoteCommandStart(emotename)
        end,
        
        getPlayerAnim = function()
            return exports["Animations"]:getPlayerAnim()
        end,
    },
}

--[[ 
    @props : prop_box_wood08a, prop_box_ammo03a_set, v_serv_abox_02
]]
-- @dashboardLabel: Coffres communs (stash)
-- @dashboardDescription: Liste des coffres partagés accessibles par job (police, ambulance, etc.). Chaque entrée définit sa position, son poids max et le job requis.
-- @dashboardGroup: Inventaire
-- @dashboardWidget: object
Config.Stash = {
    ["police"] = {
        id = 1,
        pos = vec3(474.240021, -990.665344, 26.273289),
        props = nil,
        maxweight = 1000,
        passwork = nil,
        requirpjob = "police",
    },
    ["ambulance"] = {
        id = 2,
        pos = vec3(-483.568420, -1015.965454, 33.689274),
        props = nil,
        maxweight = 2000,
        passwork = nil,
        requirpjob = "ambulance",
    },
}