-- =============================================================================
-- Groupes & permissions
-- =============================================================================

-- @dashboardLabel: Groupe par défaut
-- @dashboardDescription: Groupe assigné automatiquement aux nouveaux joueurs à leur première connexion.
-- @dashboardGroup: Permissions
-- @dashboardWidget: text
Config.DefaultGroup = 'user'

-- @dashboardLabel: Niveau par défaut
-- @dashboardDescription: Niveau de permission assigné aux nouveaux joueurs. Conservez "0" sauf si vous avez une raison particulière.
-- @dashboardGroup: Permissions
-- @dashboardWidget: text
Config.DefaultLevel = '0'

-- @dashboardLabel: Hiérarchie des groupes
-- @dashboardDescription: Définition de tous les groupes du serveur avec leur héritage (champ "before" = groupe dont on hérite les permissions). L'ordre de la liste reflète la hiérarchie de bas en haut.
-- @dashboardGroup: Permissions
-- @dashboardWidget: object
Config.Groupes = {
    [1] = { name = 'user', before = '' },
    [2] = { name = 'helper', before = 'user' },
    [3] = { name = 'mod', before = 'helper' },
    [4] = { name = 'admin', before = 'mod' },
    [5] = { name = 'superadmin', before = 'admin' },
    
    -- Assistants (héritent de superadmin)
    [6] = { name = 'assistantillegal', before = 'superadmin' },
    [7] = { name = 'assistantlegal', before = 'superadmin' },
    [8] = { name = 'assistantstaff', before = 'superadmin' },
    
    -- Gérants (héritent de superadmin)
    [9] = { name = 'gerantillegal', before = 'superadmin' },
    [10] = { name = 'gerantlegal', before = 'superadmin' },
    [11] = { name = 'gerantstaff', before = 'superadmin' },
    
    -- Direction
    [12] = { name = 'responsable', before = 'superadmin' },
    [13] = { name = 'fondateur', before = 'superadmin' },
}

-- @dashboardLabel: Grades par groupe
-- @dashboardDescription: Niveau numérique de chaque groupe (0 = joueur, 8 = fondateur). Utilisé pour les vérifications de permissions par grade minimum.
-- @dashboardGroup: Permissions
-- @dashboardWidget: object
Config.GroupeGrade = {
    ['user'] = { grade = 0 },
    ['helper'] = { grade = 1 },
    ['mod'] = { grade = 2 },
    ['admin'] = { grade = 3 },
    ['superadmin'] = { grade = 4 },
    ['assistantillegal'] = { grade = 5 },
    ['assistantlegal'] = { grade = 5 },
    ['assistantstaff'] = { grade = 5 },
    ['gerantillegal'] = { grade = 6 },
    ['gerantlegal'] = { grade = 6 },
    ['gerantstaff'] = { grade = 6 },
    ['responsable'] = { grade = 7 },
    ['fondateur'] = { grade = 8 },
}

-- @dashboardLabel: Groupes à hautes permissions (legacy)
-- @dashboardDescription: Ancien système de permissions, largement remplacé par les grades. Conservé pour compatibilité avec certains modules.
-- @dashboardGroup: Permissions
-- @dashboardWidget: object
Config.GroupeHighPerm = {
    ["gerantlegal"] = true,
    ["gerantillegal"] = true,
    ["gerantstaff"] = true,
    ["responsable"] = true,
    ["fondateur"] = true
}

-- @dashboardLabel: Permissions ACE vérifiées
-- @dashboardDescription: Liste des permissions ACE dont le statut doit être vérifié automatiquement (pmms, commandes spéciales, etc.).
-- @dashboardGroup: Permissions
-- @dashboardWidget: object
Config.AceToVerif = {
    ['pmms.interact'] = true,
    ['pmms.anyEntity'] = true,
    ['pmms.customUrl'] = true,
    ['pmms.anyUrl'] = true,
    ['pmms.manage'] = true,
    ['command.doorlock'] = true,
}

-- @dashboardLabel: Grade minimum par permission ACE
-- @dashboardDescription: Grade minimum (voir Config.GroupeGrade) requis pour chaque permission. Par exemple, pmms.manage = 4 signifie qu'il faut être au moins superadmin.
-- @dashboardGroup: Permissions
-- @dashboardWidget: object
Config.AcePermsGrade = {
    ['pmms.interact'] = 1,      -- helper+
    ['pmms.anyEntity'] = 2,     -- mod+
    ['pmms.customUrl'] = 3,     -- admin+
    ['pmms.anyUrl'] = 4,        -- superadmin+
    ['pmms.manage'] = 4,        -- superadmin+
    ['command.doorlock'] = 3,   -- admin+
}

function Config.IsStaffGroup(group)
    local grade = Config.GroupeGrade[group]
    return grade and grade.grade >= 1
end

function Config.GetGroupGrade(group)
    local gradeData = Config.GroupeGrade[group]
    return gradeData and gradeData.grade or 0
end
