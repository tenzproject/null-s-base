Config.DealWP = {
    PedList = {
        "a_m_m_farmer_01", 
        "a_m_m_eastsa_01",
        "a_m_m_eastsa_02", 
        "a_m_m_og_boss_01", 
        "a_m_m_soucent_01"
    },
    MessageList = {
        "Je suis intéressé par ton offre, retrouve-moi ici.",
        "J’ai l’argent, viens me voir.",
        "Je veux acheter ce que tu proposes. Viens.",
        "Je t’attends à cette position pour conclure le deal.",
        "Pas le temps de discuter, rejoins-moi ici pour la transaction.",
        "Apporte la marchandise, je suis ici.",
        "Je suis prêt à acheter, mais pas pour longtemps.",
        "On peut faire affaire… si tu viens rapidement.",
        "J’ai besoin de ce que tu vends, retrouve-moi ici.",
        "Viens vite, je paye bien.",
        "C’est maintenant ou jamais, je suis ici.",
        "Ne fais pas attendre un bon client.",
    },
    PedAnim = {
        {
            dict = "amb@world_human_hang_out_street@female_arms_crossed@idle_a",
            anim = "idle_a"
        },
        {
            dict = "amb@world_human_hang_out_street@male_c@idle_a",
            anim = "idle_b"
        },
        {
            dict = "anim@heists@heist_corona@single_team",
            anim = "single_team_loop_boss"
        },
        {
            dict = "anim@amb@nightclub@peds@",
            anim = "rcmme_amanda1_stand_loop_cop"
        },
        {
            dict = "anim@heists@heist_corona@team_idles@male_a",
            anim = "idle"
        },
        {
            dict = "anim@heists@humane_labs@finale@strip_club",
            anim = "ped_b_celebrate_loop"
        },
        {
            dict = "friends@fra@ig_1",
            anim = "base_idle"
        },
        {
            dict = "anim@amb@business@bgen@bgen_no_work@",
            anim = "sit_phone_phoneputdown_idle_nowork"
        },
        {
            dict = "rcm_barry3",
            anim = "barry_3_sit_loop"
        },
        {
            dict = "anim@heists@fleeca_bank@ig_7_jetski_owner",
            anim = "owner_idle"
        },
    },
    Position = {
        vector4(-823.70208740234, -2103.6196289062, 8.9574432373047, 312.34652709961),
        vector4(-785.86206054688, -2067.4365234375, 9.0178880691528, 133.63059997559),
        vector4(-421.70236206055, -2171.5537109375, 11.33854675293, 0.83261501789093),
        vector4(-306.81170654297, -2192.0979003906, 10.839423179626, 323.45785522461),
        vector4(-157.59721374512, -2206.3369140625, 8.7142276763916, 266.96524047852),
        vector4(-58.234668731689, -2244.8322753906, 8.9559593200684, 90.475234985352),
        vector4(121.16474914551, -2468.8859863281, 6.0958733558655, 58.190887451172),
        vector4(-106.48026275635, -2497.6157226562, 6.0957016944885, 328.50888061523),
        vector4(67.606559753418, -2569.7419433594, 6.004590511322, 91.386825561523),
        vector4(72.921577453613, -2681.6652832031, 6.0046472549438, 88.312362670898),
        vector4(961.82025146484, -2503.484375, 28.452276229858, 2.0941648483276),
        vector4(1080.4887695312, -2412.9084472656, 30.167612075806, 267.30682373047),
        vector4(1108.9825439453, -2336.1982421875, 31.297939300537, 177.58921813965),
        vector4(1054.0573730469, -1952.7642822266, 32.094928741455, 269.85958862305),
        vector4(1073.6059570312, -1808.4370117188, 37.445838928223, 292.39080810547),
        vector4(915.33605957031, -1514.5668945312, 31.204191207886, 184.1690826416),
        vector4(734.20275878906, -1270.2895507812, 27.036851882935, 91.530570983887),
        vector4(359.96444702148, -1265.2655029297, 32.708988189697, 144.13609313965),
        vector4(338.00881958008, -1101.6361083984, 29.406408309937, 358.8635559082),
        vector4(343.39437866211, -1082.08203125, 29.451263427734, 91.630447387695),
        vector4(328.51138305664, -994.38555908203, 29.322044372559, 182.34292602539),
        vector4(296.40524291992, -994.02758789062, 29.310552597046, 181.05401611328),
        vector4(315.28277587891, -684.66375732422, 30.037916183472, 251.83312988281),
        vector4(486.35003662109, -630.14263916016, 25.11326789856, 172.40083312988),
        vector4(474.17044067383, -635.76171875, 25.648365020752, 357.79107666016),
        vector4(724.12469482422, -697.15191650391, 28.537059783936, 89.99584197998),
    },

    -- Probabilité qu'un NPC accepte une négociation (0.0 - 1.0)
    negotiationAcceptChance = 0.65,

    -- Système de paliers basé sur le niveau du groupe (tablette illégale)
    -- Petits groupes : petites quantités, offres rapides, prix légèrement réduit
    -- Gros groupes : grosses quantités, offres lentes, prix légèrement meilleur mais plus risqué
    tiers = {
        { -- Tier 1 : Petit groupe (niveau 1-20)
            minLevel = 1,
            maxLevel = 20,
            quantities = {min = 1, max = 5},
            offerInterval = {min = 30, max = 90},       -- Offres rapides
            priceMultiplier = 0.85,                       -- Prix réduit (-15%)
        },
        { -- Tier 2 : Groupe moyen (niveau 21-50)
            minLevel = 21,
            maxLevel = 50,
            quantities = {min = 3, max = 15},
            offerInterval = {min = 60, max = 180},       -- Offres normales
            priceMultiplier = 1.0,                        -- Prix normal
        },
        { -- Tier 3 : Gros groupe (niveau 51-100)
            minLevel = 51,
            maxLevel = 100,
            quantities = {min = 8, max = 30},
            offerInterval = {min = 120, max = 300},      -- Offres lentes
            priceMultiplier = 1.05,                       -- Prix légèrement meilleur (+5%)
        },
    },

    -- Fallback si le joueur n'a pas de groupe ou niveau introuvable
    defaultTier = {
        quantities = {min = 1, max = 5},
        offerInterval = {min = 30, max = 90},
        priceMultiplier = 0.85,
    },
}