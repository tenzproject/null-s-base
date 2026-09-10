Config = Config or {}

Config.Admin = {}

--[[
    Config.GroupeGrade est défini dans configs/framework/shared/groups.lua
    Grades disponibles par défaut :
    - user = 0
    - helper = 1
    - mod = 2
    - admin = 3
    - superadmin = 4
    - assistant* = 5
    - gerant* = 6
    - responsable = 7
    - fondateur = 8
]]

Config.Admin.PermissionsGrade = { -- Grade minimum requis (voir groups.lua pour la liste)
    -- Helper (grade 1)
    ["noclip"] = 1,
    ["REPORT"] = 1,
    ["REVIVE"] = 1,
    ["JAIL"] = 1,
    ["KICK"] = 1,
    ["WARN"] = 1,
    ["BLIPS"] = 1,
    ["VEH_GESTION"] = 1,
    ["EVALUATION_STAFF"] = 1,
    ["pmms.interact"] = 1,
    ["pmms.anyEntity"] = 1,
    ["pmms.customUrl"] = 1,

    -- Mod (grade 2)
    ["FORCEEXITPROPERTY"] = 2,
    ["SCREEN"] = 2,
    ["HEAL"] = 2,
    ["BAN"] = 2,

    -- Admin (grade 3)
    ["REVIVE_ALL"] = 3,
    ["STAFFGUN"] = 3,
    ["TELEPORT_ALL"] = 3,
    ["WIPE"] = 3,
    ["INVINCIBLE"] = 3,
    ["OBJETS"] = 3,
    ["NAMEADVANCED"] = 3,
    ["GARAGEBLIPS"] = 3,
    ["GANGBLIPS"] = 3,
    ["ATA"] = 3,
    ["freecam"] = 3,
    ["pmms.anyUrl"] = 3,
    ["GESTION_SERVER"] = 3,
    ["GESTION_EVENT"] = 3,

    -- Superadmin (grade 4)
    ["CHANGE_TENU"] = 4,
    ["SUPERJUMP"] = 4,
    ["SUPERSPRINT"] = 4,
    ["DELGUN"] = 4,
    ["GIVE_ITEM"] = 4,
    ["GIVE_VEH"] = 4,
    ["GIVE_MONEY"] = 4,
    ["GIVE_WEAPON_LICENSE"] = 4,
    ["GIVE_DRIVE_LICENSE"] = 4,
    ["GIVE_GARAGE_VEH"] = 4,
    ["GIVE_WEAPON"] = 4,
    ["DELETE_GLOBAL"] = 4,
    ["DELETE_WEAPON"] = 4,
    ["DELETE_MONEY"] = 4,
    ["DELETE_ITEM"] = 4,
    ["OPEN_INV"] = 4,
    ["OPEN_GARAGE"] = 4,
    ["CUSTOM_VEHICLE"] = 4,
    ["SETJOB"] = 4,
    ["PED"] = 4,
    ["pmms.manage"] = 4,
    ["command.doorlock"] = 4,
    ["GESTION_BUILDER"] = 4,
    ["create-properties"] = 4,

    -- Gérant (grade 6)
    ["GESTIONSTAFF"] = 6,
    ["ANNONCE"] = 6,

    -- Responsable (grade 7)
    ["INSTANCE"] = 7,
    ["GESTION_AFK_POINT"] = 7,
    ["VEHICLEMONDE"] = 7,
    ["BLACKOUT"] = 7,
    ["ZONEGF_GESTION"] = 7,
    ["VIDEO"] = 7,
    ["HISTOBOUTIQUE"] = 7,
    ["COFFRE_STAFF"] = 7,

    -- Fondateur (grade 8)
    ["GIVE_GLOBAL"] = 8,
    ["GIVE_ITEM_BOUTIQUE"] = 8,
    ["GIVE_WEAPON_BOUTIQUE"] = 8,
    ["LISTE_ITEMS_ARMES"] = 8,
    ["GESTION_BOUTIQUE"] = 8,
    ["GESTION_AC"] = 8,
    ["givecoins"] = 8,
    ["INFINITE_MAX_WEIGHT"] = 8,
    ["DEV"] = 8,
}

                                              
Config.Admin.AutoClothes = true -- Si vous mettez true, changer la permissions ["CHANGE_TENU"]

-- Ne pas toucher, tous es déjà configurer
Config.GangsBuilder = true
Config.JobsBuilder = true
Config.FarmingsBuilder = true
Config.GaragesBuilder = true
Config.DoorsBuilder = false

Config.HudOnServiceStaff = true -- si vous souhaiter que l'hud staff s'enlever quand quelqu'un quitte le service staff
Config.PedOnServiceStaff = true -- si vous souhaiter que les Peds staff s'enlever quand quelqu'un quitte le service staff

Config.listwhitelist = { -- Véhicule qu'un staff (helpeur) peut faire spawn dans le menu admin !
    {model = "sanchez"},
    {model = "panto"},
    {model = "sultan"},
    {model = "sanchez2"},
    {model = "blista"},
    {model = "cliffhanger"},
}

Config.Admin.Controls = {
    openMenu = "f9", -- Touche pour ouvrir le menu
    freeCam = "f2", -- Touche pour le noclip
    tpMarker = "f4", -- Touche pour ce téléporter sur un marqueur
}

-- Ne pas toucher, tous es déjà configurer
Config.Admin.Commands = {
    heal = "heal", -- Changer si votre commande n'est pas /heal
    freeze = "freeze", -- Changer si votre commande n'est pas /freeze
    unfreeze = "unfreeze", -- Changer si votre commande n'est pas /unfreeze
    setjob = "setjob", -- Changer si votre commande n'est pas /setjob
    setjob2 = "setjob2", -- Changer si votre commande n'est pas /setjob2
}

-- Ne pas toucher, tous es déjà configurer
Config.Admin.BuilderCommand = {
    creategarage = "creategarage", 
    modifygarage = "garage:modify", 
    addvehicle = "garage:addvehicle", 
    cleargaragegarage = "garage:clearGarage", 
    deletevehiculegarage = "garage:deleteVehicle", 

    createdoor = "createdoor", 
    deletedoor = "deletedoor", 

    gangsbuilder = "gangs",
    mecanobuilder = "createmecano",
    maisonbuilder = "maison",
    jobsbuilder = "createentreprise",
    farmingsbuilder = "createfarming",
}

-- ATTENTION, une mauvaise manipulation et le serveur peut ne plus démarer, veuillez ne pas changer si vous n'etes pas dev
-- gamertag_color: Hud Color Index, sauf fondateur et reponsable c'est uniquement quand il est en service
Config.Admin.RankList = {
    {
        rank = "helper", 
        label = "Helpeur", 
        menuColor = "~b~", 
        can = true, 
        gamertag_color = 6, 
        alwayscolored = false, 
        star = false
    }, 
    {
        rank = "mod", 
        label = "Modérateur", 
        menuColor = "~p~", 
        can = true, 
        gamertag_color = 6, 
        alwayscolored = false, 
        star = false
    },
    {
        rank = "admin", 
        label = "Administrateur", 
        menuColor = "~y~", 
        can = true, 
        gamertag_color = 6, 
        alwayscolored = false, 
        star = false
    },
    {
        rank = "superadmin", 
        label = "Super-Administrateur", 
        menuColor = "~o~", 
        can = true, 
        gamertag_color = 6, 
        alwayscolored = false, 
        star = false
    },
    {
        rank = "gerantlegal", 
        label = "Gérant Légal", 
        menuColor = "~g~", 
        can = true, 
        gamertag_color = 6, 
        alwayscolored = false, 
        star = false
    },
    {
        rank = "gerantillegal", 
        label = "Gérant Illégal", 
        menuColor = "~r~", 
        can = true, 
        gamertag_color = 6, 
        alwayscolored = false,
        star = false,
    }, 
    {
        rank = "gerantstaff", 
        label = "Gérant Staff", 
        menuColor = "~b~", 
        can = true, 
        gamertag_color = 6, 
        alwayscolored = false, 
        star = false
    },
    {
        rank = "responsable", 
        label = "Responsable", 
        menuColor = "~b~", 
        can = false, 
        gamertag_color = 6, 
        alwayscolored = true, 
        star = false
    },
    {
        rank = "fondateur", 
        label = "Fondateur", 
        menuColor = "~r~", 
        can = false, 
        gamertag_color = 6, 
        alwayscolored = true, 
        star = true
    },
}

Config.Admin.RankListLabel = (function()
    local ranks = {}
    for k,v in pairs(Config.Admin.RankList) do 
        ranks[v.rank] = v.label
    end
    return ranks
end)()

Config.Admin.RankListGamerTag = { -- Nom afficher dans le gamertag (nom des joueurs) quand il sont staff
    ["user"] = "",
    ["helper"] = " - H",
    ["mod"] = " - M",
    ["admin"] = " - A",
    ["superadmin"] = " - S-A",
    ["gerantlegal"] = " - RL",
    ["gerantillegal"] = " - RI",
    ["gerantstaff"] = " - RS",
    ["responsable"] = " - R",
    ["fondateur"] = " - F",
}


Config.WeaponOnlyForOwner = {
    ["WEAPON_SCAR17FM"] = {"fondateur"},
}

Config.Admin.PlayerTeleportList = {  -- Rajouter les coordonnées des points de TP optionnels
    {label = "PC", pos = vector3(216.91, -810.93, 30.69)},
    {label = "LSPD", pos = vector3(-1124.939, -846.3799, 19.31564)},
    {label = "Hopital", pos = vector3(-1857.42, -350.7845, 49.38783)    },
    {label = "Fourriere SUD", pos = vector3(403.96, -1625.67, 29.29)},
    {label = "Fourriere NORD", pos = vector3(-479.89, 6021.62, 31.34)}
}

Config.Admin.PedList = { -- Liste des peds vous pouvez en rejouter (https://wiki.rage.mp/index.php?title=Peds)
    {label = "Singe", model = "a_c_chimp"},
    {label = "Danseuse", model = "csb_stripper_01"},
    {label = "Cosmonaute", model = "s_m_m_movspace_01"},
    {label = "Alien", model = "s_m_m_movalien_01"},
    {label = "Chat", model = "a_c_cat_01"},
    {label = "Aigle", model = "a_c_chickenhawk"},
    {label = "Coyote", model = "a_c_coyote"},
}

Config.Admin.TrollPedList = { -- Liste des peds vous pouvez en rejouter (https://wiki.rage.mp/index.php?title=Peds)
    {label = "Coyote", model = "a_c_coyote"},
}

Config.Admin.IllegalBlips = {
    {pos = vec3(516.432983, 170.614471, 99.378586), label = "Torture + Garage"},

    {pos = vec3(-1832.010010, -349.911896, 46.720741), label = "Torture"},
    {pos = vec3(595.203735, 2769.385010, 40.733189), label = "Torture"},
    {pos = vec3(516.432983, 170.614471, 99.378586), label = "Torture"},
    {pos = vec3(-572.930481, 235.010071, 74.890823), label = "Hacker"},

    {pos = vec3(808.467529, -494.421356, 30.626921), label = "Salle Illegal"},
    {pos = vec3(1397.223999, 3638.135742, 34.879028), label = "Salle Illegal"},
}

Config.Admin.StaffModeClothes = { -- Tenues staff à vous de la personnalisé | m = homme f = femme
    m = {
        ['sex'] = 0,
        ['bags_1'] = 0, ['bags_2'] = 0,
        ['tshirt_1'] = 15, ['tshirt_2'] = 0,
        ['torso_1'] = 178, ['torso_2'] = 5,
        ['arms'] = 1,
        ['pants_1'] = 77, ['pants_2'] = 5,
        ['shoes_1'] = 55, ['shoes_2'] = 5,
        ['bproof_1'] = 0,
        ['chain_1'] = 0, ['chain_2'] = 0,
    },
    f = {
        ['tshirt_1'] = 10, ['tshirt_2'] = 0,
        ['torso_1'] = 180, ['torso_2'] = 5,
        ['decals_1'] = 0, ['decals_2'] = 0,
        ['arms'] = 1,
        ['pants_1'] = 79, ['pants_2'] = 5,
        ['shoes_1'] = 58, ['shoes_2'] = 5,
        ['glasses_1'] = 12, ['glasses_2'] = 0,
        ['helmet_1'] = -1, ['helmet_2'] = 0,
        ['chain_1'] = 0, ['chain_2'] = 0,
        ['ears_1'] = -1, ['ears_2'] = 0
    }
}
