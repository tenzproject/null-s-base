
Config.LogsSys = {
    --[[
        Types disponibles:
        - "discord"  : Envoie les logs vers Discord via webhooks
        - "both"     : Envoie vers Discord ET la base de données
    ]]
    type = "discord",
}

Config.Logs = { -- Si logstype: discord alors veuillez configurer ceci
    ["all"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["resources"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",

    ["connexion"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["deconnexion"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["mort"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["kill"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    
    ["kick"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["warn"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["ban"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["unban"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["prise-service"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["quitte-service"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["jail"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["unjail"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    
    ["boutique_caisse"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["boutique_vehicle"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["boutique_weapon"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["boutique_weaponcustom"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    
    ["use-item"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q", 
    ["transaction-item"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["transaction-weapon"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["transaction-account"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["drop-item"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["drop-weapon"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["drop-account"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["give-item"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["give-weapon"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["give-vehicle"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["give-account"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["remove-item"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["remove-weapon"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["remove-vehicle"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["remove-account"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    
    ["screenshot"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["society"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["mecano"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["concess"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",

    ["create-illegal-group"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["edit-illegal-group"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["gestion-illegal-group"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    

    ["create-report"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["close-report"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["take-report"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",

    ["setjob"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["setjob2"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["give-weapon-component"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["clear-chat"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["clear-inventory"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["clear-loadout"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["car"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["dv"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["weather"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["time"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["register"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["wipe"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["tppc"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["goto"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["bring"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["heal"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["revive"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["freeze"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["msgstaff"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["rs-staff"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["annonce"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["annoncestaff"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",

    -- Admin Menu
    ["addstaff"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["rankstaff"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["demotestaff"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",

    ["GIVE_LICENCE"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["WARN"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["CLEAR_INV"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["CLEAR_WEAPON"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["CLEAR_VEHICULE"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["WIPE"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["SET_RANK"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["SKIN_MENU"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",

    ["twitchRequest"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
    ["superette-changename"] = "https://canary.discord.com/api/webhooks/1443624505963712512/eO3A5Kiku7ZKMZchYIzfIyS2yieLtNpcI2FupxCPzNwunQ2UZfFgkRQCLl2u3f-il13q",
}