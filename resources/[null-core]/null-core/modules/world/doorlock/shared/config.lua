-- ============================================================================
-- Null Doorlock — Configuration partagée (client + serveur)
-- Système de verrouillage de portes natif null-core.
-- ============================================================================

DoorlockConfig = {}

-- Distance max à laquelle le prompt 3D apparaît.
DoorlockConfig.DrawDistance = 2.5
-- Distance max à laquelle on peut interagir (touche E).
DoorlockConfig.InteractDistance = 1.6

-- Touche d'interaction (voir ConfigAllKeys dans 3dinteraction.lua : E/F/G/H/K/Y).
DoorlockConfig.InteractKey = "E"

-- Accès à l'éditeur in-game (/doorlock).
-- Grade minimum requis (voir Config.GroupeGrade dans configs/framework/shared/groups.lua) :
--   user=0, helper=1, mod=2, admin=3, superadmin=4, ... responsable=7, fondateur=8
-- 8 = seuls les fondateurs. Baissez (ex: 4) pour autoriser superadmin+ etc.
DoorlockConfig.EditorMinGrade = 8
-- Groupes supplémentaires autorisés hors hiérarchie de grade (ex: 'dev').
DoorlockConfig.EditorExtraGroups = { ["dev"] = true, ["fondateur"] = true }

-- Item de crochetage (consommé en cas d'échec). nil = pas d'item requis.
DoorlockConfig.LockpickItem = "lockpick"
-- Item passe-partout (déverrouille sans crochetage, non consommé).
DoorlockConfig.MasterKeyItem = "passe_partout"

-- Crochetage : difficulté ox_lib skillcheck + inputs.
DoorlockConfig.Lockpick = {
    enabled    = true,
    difficulty = { 'easy', 'easy', 'medium' }, -- 3 cercles
    inputs     = { 'w', 'a', 's', 'd' },
    cooldown   = 10000, -- ms entre deux tentatives
    breakOnFail = true, -- consomme le lockpick si échec
}

-- Sons (xsound bundlé dans null-deps). nil = pas de son.
DoorlockConfig.Sounds = {
    enabled = true,
    lock    = "https://www.soundjay.com/locks/sounds/lock-and-key-1.mp3",
    unlock  = "https://www.soundjay.com/locks/sounds/unlocking-1.mp3",
    volume  = 0.25,
    maxDistance = 5.0,
}

-- Textes du prompt 3D.
DoorlockConfig.Text = {
    locked   = "Verrouillé",
    unlocked = "Déverrouillé",
    toLock   = "Verrouiller",
    toUnlock = "Déverrouiller",
    noAccess = "Accès refusé",
}
