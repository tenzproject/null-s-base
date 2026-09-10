Config = Config or {}

-- Configuration de base du menu personnel
Config.PersonalMenu = {
    ConfigHub = function()
        if Config and Config.Hud then
            if Config.Hud["0r-hud"] then
                ExecuteCommand("hudsettings")
            elseif Config.Hud["null-hud"] then
                ExecuteCommand("hud")
            elseif Config.Hud["null-core"] then
                ExecuteCommand("hudedit")
            end
        end
    end,

    Radio = {
        Active = false,
        Frequence = 0,
        Sound = 1,
        Tick = true,
    },
}

Config.Radio = {
    [1] = {
        ['police'] = true,
    },
    [2] = {
        ['police'] = true,
    },
    [3] = {
        ['police'] = true,
    },
    [4] = {
        ['police'] = true,
    },
    [5] = {
        ['police'] = true,
    },
    [6] = {
        ['bcso'] = true,
    },
    [7] = {
        ['bcso'] = true,
    },
    [8] = {
        ['bcso'] = true,
    },
    [9] = {
        ['bcso'] = true,
    },
    [10] = {
        ['bcso'] = true,
    },
    [11] = {
        ['ambulance'] = true,
    },
    [12] = {
        ['ambulance'] = true,
    },
    [13] = {
        ['ambulance'] = true,
    },
    [14] = {
        ['ambulance'] = true,
    },
    [15] = {
        ['ambulance'] = true,
    },
    [16] = {
        ['ambulance'] = true,
        ['police'] = true,
        ['bcso'] = true,
    },
    [17] = {
        ['ambulance'] = true,
        ['police'] = true,
        ['bcso'] = true,
    },
    [18] = {
        ['ambulance'] = true,
        ['police'] = true,
        ['bcso'] = true,
    },
    [19] = {
        ['ambulance'] = true,
        ['police'] = true,
        ['bcso'] = true,
    },
    [20] = {
        ['ambulance'] = true,
        ['police'] = true,
        ['bcso'] = true,
    },
     
    [911] = {
        ['police'] = true,
        ['policecayo'] = true,
        ['bcso'] = true,
    }
}

-- Configuration des raccourcis d'armes
Config.WeaponsBinds = {
    {id = 'one', weapon = `WEAPON_UNARMED`, weaponLabel = 'Aucun', label = 'Raccourci arme 1', bind = '1'},
    {id = 'two', weapon = `WEAPON_UNARMED`, weaponLabel = 'Aucun', label = 'Raccourci arme 2', bind = '2'},
    {id = 'three', weapon = `WEAPON_UNARMED`, weaponLabel = 'Aucun', label = 'Raccourci arme 3', bind = '3'},
    {id = 'four', weapon = `WEAPON_UNARMED`, weaponLabel = 'Aucun', label = 'Raccourci arme 4', bind = '4'},
    {id = 'five', weapon = `WEAPON_UNARMED`, weaponLabel = 'Aucun', label = 'Raccourci arme 5', bind = '5'},
}

-- Configuration du guide
Config.Guide = {
    {"Inventaire/Portefeuille/Préférences", " F5"},
    {"Menu Entreprise", " F6"},
    {"Menu Illégal", " F7"},
    {"Distance de vocal", " F3"},
    {"S'endormir/Trébuchet", " J "},
    {"Sortir/Ranger le téléphone", " G "},
    {"Ouvrir le coffre véhicule", " L ou ALT", "Maintenir et cliquer sur le véhicule."},
    {"Allumer les phares véhicules", "H"},
    {"Ouvrir/Fermer Véhicule", " U ou ALT", "Maintenir et cliquer sur le véhicule."},
    {"Lever les mains", " X"},
    {"Arreter une animation", " X"},
    {"Ceinture (Véhicules)", "K"},
    {"Changer HUD", " ,"},
    {"Changer de place en voiture", '& : 1 / é : 2 / " : 3 / '.."': 4"},
}

-- Configuration des démarches par défaut
Config.BasicDefault = {male = 'Defaultmale', girl = 'Defaultfemale'}

-- Liste des démarches disponibles
Config.walksList = {
    ["Defaultmale"] = {"move_m@multiplayer"},
    ["Defaultfemale"] = {"move_f@multiplayer"},
    ["Alien"] = {"move_m@alien"},
    ["Mastodonte"] = {"anim_group_move_ballistic"},
    ["Arrogant"] = {"move_f@arrogant@a"},
    ["Brave"] = {"move_m@brave"},
    ["Décontracté"] = {"move_m@casual@a"},
    ["Décontracté 2"] = {"move_m@casual@b"},
    ["Décontracté 3"] = {"move_m@casual@c"},
    ["Décontracté 4"] = {"move_m@casual@d"},
    ["Décontracté 5"] = {"move_m@casual@e"},
    ["Décontracté 6"] = {"move_m@casual@f"},
    ["Chichi"] = {"move_f@chichi"},
    ["Confident"] = {"move_m@confident"},
    ["Police"] = {"move_m@business@a"},
    ["Police 2"] = {"move_m@business@b"},
    ["Police 3"] = {"move_m@business@c"},
    ["Femme par défaut"] = {"move_f@multiplayer"},
    ["Homme par défaut"] = {"move_m@multiplayer"},
    ["Ivre"] = {"move_m@drunk@a"},
    ["Ivre léger"] = {"move_m@drunk@slightlydrunk"},
    ["Ivre 2"] = {"move_m@buzzed"},
    ["Ivre Mort"] = {"move_m@drunk@verydrunk"},
    ["Femme"] = {"move_f@femme@"},
    ["Feu"] = {"move_characters@franklin@fire"},
    ["Feu 2"] = {"move_characters@michael@fire"},
    ["Feu 3"] = {"move_m@fire"},
    ["Fuir"] = {"move_f@flee@a"},
    ["Franklin"] = {"move_p_m_one"},
    ["Gangster"] = {"move_m@gangster@generic"},
    ["Gangster 2"] = {"move_m@gangster@ng"},
    ["Gangster 3"] = {"move_m@gangster@var_e"},
    ["Gangster 4"] = {"move_m@gangster@var_f"},
    ["Gangster 5"] = {"move_m@gangster@var_i"},
    ["S'enjailler"] = {"anim@move_m@grooving@"},
    ["Garde"] = {"move_m@prison_gaurd"},
    ["Menotte par devant"] = {"move_m@prisoner_cuffed"},
    ["Talons"] = {"move_f@heels@c"},
    ["Talons 2"] = {"move_f@heels@d"},
    ["Randonnée"] = {"move_m@hiking"},
    ["Hipster"] = {"move_m@hipster@a"},
    ["Hobo"] = {"move_m@hobo@a"},
    ["Se dépêcher"] = {"move_f@hurry@a"},
    ["Concierge"] = {"move_p_m_zero_janitor"},
    ["Concierge 2"] = {"move_p_m_zero_slow"},
    ["Faire du jogging"] = {"move_m@jog@"},
    ["Lemar"] = {"anim_group_move_lemar_alley"},
    ["Lester"] = {"move_heist_lester"},
    ["Lester 2"] = {"move_lester_caneup"},
    ["Croqueuse d'homme"] = {"move_f@maneater"},
    ["Michael"] = {"move_ped_bucket"},
    ["Fricé"] = {"move_m@money"},
    ["Musclé"] = {"move_m@muscle@a"},
    ["Chic"] = {"move_m@posh@"},
    ["Chic 2"] = {"move_f@posh@"},
    ["Rapide"] = {"move_m@quick"},
    ["Coureur"] = {"female_fast_runner"},
    ["Triste"] = {"move_m@sad@a"},
    ["Impertinent"] = {"move_m@sassy"},
    ["Impertinent 2"] = {"move_f@sassy"},
    ["Effrayé"] = {"move_f@scared"},
    ["Sexy"] = {"move_f@sexy@a"},
    ["Ombreux"] = {"move_m@shadyped@a"},
    ["Lent"] = {"move_characters@jimmy@slow@"},
    ["Swagger"] = {"move_m@swagger"},
    ["Dur"] = {"move_m@tough_guy@"},
    ["Dur 2"] = {"move_f@tough_guy@"},
    ["Poubelle"] = {"clipset@move@trash_fast_turn"},
    ["Poubelle 2"] = {"missfbi4prepp1_garbageman"},
    ["Trevor"] = {"move_p_m_two"},
    ["Large"] = {"move_m@bag"},
    ["Injured"] = {"move_m@injured"},
    ["Handcuffs"] = {"move_m@prisoner_cuffed"},
}

-- Configuration des préférences
Config.Prefer = {}
Config.Prefer.Enabled = {}

Config.Prefer.Submenus = {
    ['fight'] = "Combat",
    ['vehicle'] = "Véhicules",
    ['ui'] = 'Affichage',
}

Config.Prefer.Blips = {
    {label = "Société de Farm", kvpName = "blip_society_farm", category = "farm_society"},
    {label = "Garage Voiture", kvpName = "blip_garage_car", category = "blip_garage_car"},
    {label = "Garage Aérien", kvpName = "blip_garage_flight", category = "blip_garage_flight"},
    {label = "Garage Bateau", kvpName = "blip_garage_boat", category = "blip_garage_boat"},
    {label = "Immeubles", kvpName = "blip_building", category = "blip_building"},
}

Config.Prefer.Preferences = {
    -- ['interfaces'] = {
    --     label = "Mode Interface",
    --     description = "Permet de passer les menus inventaire en interface",
    --     basicV = true,
    --     enable = function()
    --         Citizen.CreateThread(function()
    --             while Config.Prefer.Enabled['interfaces'] do 
    --                 Wait(0)
    --                 DisableControlAction(0, 37, true) -- weapon wheel
    --             end
    --         end)
    --     end,
    --     disable = function()
    --     end,
    -- },
    ['cloneped'] = {
        label = "Activer le clone dans l'interface",
        description = "Permet de désactiver/activer le clone dans l'inventaire",
        basicV = true,
        enable = function()
        end,
        disable = function()
        end,
    },
    ['leftclickattack'] = {
        label = 'Coup de poings',
        description = 'Activer l\'attaque par coups de poings',
        basicV = true,
        disable = function()
            Citizen.CreateThread(function()
                while not Config.Prefer.Enabled['leftclickattack'] do
                    local sleepTime = 750
                    if PlayerState and PlayerState.weapon == `WEAPON_UNARMED` then
                        sleepTime = 0
                        DisableControlAction(0, 24)
                        DisableControlAction(0, 140)
                    end
                    Citizen.Wait(sleepTime)
                end
            end)
        end,
        submenu = 'fight'
    },
    ['crosshair'] = {
        label = 'Viseur',
        description = 'Afficher le viseur en mode tir',
        basicV = true,
        disable = function()
            Citizen.CreateThread(function()
                while not Config.Prefer.Enabled['crosshair'] do
                    HideHudComponentThisFrame(14)
                    Citizen.Wait(0)
                end
            end)
        end,
        submenu = 'fight'
    },
    ['bikehelmet'] = {
        label = 'Casque moto',
        description = 'Activer le fait d\'équiper un casque de moto automatiquement',
        basicV = true,
        enable = function()
            SetPedConfigFlag(PlayerPedId(), 35, true)
        end,
        disable = function()
            SetPedConfigFlag(PlayerPedId(), 35, false)
        end,
        submenu = 'vehicle'
    },
    ['bikerelaxed'] = {
        label = 'Conduite décontracté moto',
        description = 'Activer le style de conduite décontracté en moto',
        basicV = false,
        enable = function()
            SetPedConfigFlag(PlayerPedId(), 424, true)
        end,
        disable = function()
            SetPedConfigFlag(PlayerPedId(), 424, false)
        end,
        submenu = 'vehicle'
    },
    ['realistic'] = {
        label = 'Conduite réalistique',
        description = 'Rend l\'impression de conduite plus réaliste(option en dev)',
        basicV = false,
        enable = function()
            PlayerState.realisticDrive = false
        end,
        disable = function()
            PlayerState.realisticDrive = false
        end,
        submenu = 'vehicle'
    },
    ['cover'] = {
        label = 'Se mettre à couvert',
        description = 'Activer la touche pour mettre le personnage à couvert',
        basicV = true,
        disable = function()
            Citizen.CreateThread(function()
                while not Config.Prefer.Enabled['cover'] do
                    DisableControlAction(0, 44)
                    Citizen.Wait(0)
                end
            end)
        end,
        submenu = 'fight'
    },
    ['crossWeapon'] = {
        label = 'Coup de Crosse',
        description = 'Permet d\'activer, désactiver les coup de crosse',
        basicV = false,
        disable = function()
            Citizen.CreateThread(function()
                while not Config.Prefer.Enabled['crossWeapon'] do  
                    local isArmed = IsPedArmed(PlayerPedId(), 6)
                    if isArmed then
                        Wait(0)
                        DisableControlAction(1, 140, true)
                        DisableControlAction(1, 141, true)
                        DisableControlAction(1, 142, true)
                    else
                        Wait(2500)
                    end
                end
            end)
        end,
        submenu = 'fight'
    },
    ['roll'] = {
        label = 'Roulades',
        description = "Permet d'activer/désactiver les roulades",
        basicV = true,
        disable = function()
            Citizen.CreateThread(function()
                while not Config.Prefer.Enabled['roll'] do  
                    local isArmed = IsPedArmed(PlayerPedId(), 6)
                    if isArmed then
                        Wait(0)
                        DisableControlAction(0, 22, true)
                    else
                        Wait(2500)
                    end
                end
            end)
        end,
        submenu = 'fight'
    },
}
