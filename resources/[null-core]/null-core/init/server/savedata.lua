SaveData = {}

--[[
    ============================================
    DONNÉES MONDES
    ============================================
]]

SaveData.World = {
    Vehicles = {},
    Props = {},
}

--[[
    ============================================
    DONNÉES SAFEZONE
    ============================================
]]

SaveData.SafeZone = {
    List = {},
    Load = false,
}


--[[
    ============================================
    DONNÉES JOBS & ENTREPRISES
    ============================================
]]

SaveData.jobs = {
    ltds = {},
    polices = {},
    farms = {},
    ambulances = {},
    mecanos = {},
    bars = {},
    restaurant = {},
}

SaveData.societyMembreList = {}

--[[
    ============================================
    DONNÉES ÉVÉNEMENTS
    ============================================
]]

SaveData.Events = {
    CamionBlinder = {},
}

--[[
    ============================================
    DONNÉES ILLÉGALES
    ============================================
]]

SaveData.Illegal = {
    WeedPlants = {},
    Laboratory = {},
}

SaveData.PlayersInLab = {}

--[[
    ============================================
    DONNÉES ENTITÉS
    ============================================
]]

SaveData.Entity = {
    Objects = {},
}

--[[
    ============================================
    DONNÉES JOUEURS
    ============================================
]]

SaveData.Players = {
    Online = {},
    Offline = {
        Load = false,
        List = {},
        Number = 0,
    },
}

--[[
    ============================================
    DONNÉES ADMIN
    ============================================
]]

SaveData.Admin = {
    Staffs = {
        List = {},
        Load = false,
    },
    PlayersBlips = {},
    StaffWithBlips = {},
    Devmode = false,

    -- Debug
    Players = {
        List = {},
        Load = false,
    },
    NbrDbPlayers = 0,
}

--[[
    ============================================
    DONNÉES PROPRIÉTÉS
    ============================================
]]

SaveData.PropertiesList = {}
SaveData.proprieties = {
    buildings = {},
    houses = {},
}

--[[
    ============================================
    DONNÉES STREAMING
    ============================================
]]

SaveData.connectedStreamerList = {}
SaveData.streamerList = {}
SaveData.inStreamList = {}

--[[
    ============================================
    DONNÉES ARMES & FARM
    ============================================
]]

SaveData.BlWeapons = {}
SaveData.FarmPlayers = {}
SaveData.FarmsActivityTotalPerPlayers = {
    recolte = {},
    traitement = {},
    vente = {}
}
SaveData.FarmsJobTotalPerPlayers = {
    recolte = {},
    traitement = {},
    vente = {}
}

--[[
    ============================================
    DONNÉES GANGS
    ============================================
]]

SaveData.gangs = {}
SaveData.gangsMembreList = {}
SaveData.chestOpenByOnePlayer = {}

--[[
    ============================================
    DONNÉES AMBULANCE
    ============================================
]]

SaveData.ambulanceList = {}
SaveData.ambulanceLoad = false

--[[
    ============================================
    DONNÉES SQL
    ============================================
]]

SaveData.structuresSql = {
    users = {},
}

--[[
    ============================================
    DONNÉES VÉHICULES
    ============================================
]]

SaveData.owned_vehicles = {}
SaveData.tempo_vehicles = {}

SaveData.garages = {
    boats = {},
    cars = {},
    aircrafts = {},
    impounds = {},
}

SaveData.coffreTable = {}

--[[
    ============================================
    DONNÉES SERVEUR
    ============================================
]]

SaveData.ServerConfig = {}
SaveData.ServerConfigLoad = false

SaveData.activity = {}

function SaveData.Get(name)
    return SaveData[name]
end

function SaveData.Set(name, value)
    SaveData[name] = value
end

function SaveData.IsServerConfigLoaded()
    return SaveData.ServerConfigLoad
end

exports('GetSaveData', function() return SaveData end)
exports('GetData', SaveData.Get)
exports('SetData', SaveData.Set)

null.InitPrint('^2SaveData initialized^7')
