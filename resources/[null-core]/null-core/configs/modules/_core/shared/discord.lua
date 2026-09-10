Config._core = Config._core or {}

Config._core.Discord = {
    -- Activer Discord Rich Presence
    Enabled = true,
    
    -- Activer la personnalisation du menu pause
    CustomPauseMenu = true,

    -- Textes du menu pause
    PauseMenuTexts = {
        ['FE_THDR_GTAO'] = nil, -- Header (sera généré dynamiquement)
        ['PM_PANE_KEYS'] = 'Configurer vos Touches',
        ['PM_PANE_AUD'] = 'Audio & Son',
        ['PM_PANE_GTAO'] = 'Touches Basique',
        ['PM_PANE_CFX'] = nil, -- Nom du serveur
        ['PM_PANE_LEAVE'] = 'Retourner sur la liste des serveurs.',
        ['PM_PANE_QUIT'] = 'Quitter la ville',
        ['PM_SCR_MAP'] = 'Carte de Los Santos',
        ['PM_SCR_GAM'] = 'Prendre l\'avion',
        ['PM_SCR_INF'] = 'Logs',
        ['PM_SCR_SET'] = 'Configuration',
        ['PM_SCR_STA'] = 'Statistiques',
        ['PM_SCR_RPL'] = '',
    }
}