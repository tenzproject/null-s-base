null = {}
-- Namespaces
null.fct = {} -- Functions
null.fct.draw = {}
null.fct.game = {}
null.fct.format = {}
null.fct.math = {}
null.fct.utils = {}
null.fct.safe = {}

null.data = {}           -- Données globales des modules
null.data.server = {     -- Données liées au serveur
    days = 0,
    mounts = 0,
    years = 0,
    maxplayers = 0,
}
null.data.jobs = {       -- Données liées aux jobs/entreprises
    polices = {
        list = {},
        loaded = false,
    },
    ambulances = {
        list = {},
        loaded = false,
    },
    restaurants = {
        list = {},
        loaded = false,
    },
    farms = {
        list = {},
        loaded = false,
    },
    mecanos = {
        list = {},
        loaded = false,
    },
    bars = {
        list = {},
        loaded = false,
    },
}
null.data.illegals = {   -- Données liées à l'illégals (laboratoires, groupe illégaux)
    laboratories = {
        list = {},
        loaded = false,
    },
    groups = {
        list = {},
        loaded = false,
    },
}
null.data.world = {}     -- Données monde (météo, temps, etc.) 
null.data.markers = {}
null.data.system = {}
null.data.afk = {}

null.modules = {}

null.loader = {
    resources = {},
}

exports("getData", function(keys)
    if null.data[keys] then
        return null.data[keys]
    else
        return nil
    end
end)