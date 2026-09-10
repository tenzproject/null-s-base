Config.WeazelNews = {
    Coffre = {
        {pos = vec3(-568.408142, -200.148972, 38.219070)},
    },
    Vestiaire = {
        {pos = vec3(-566.670349, -191.584595, 38.218128)},
    },
    Vestiaire = {
        grades = {
                [0] = {
                    label = "S'équiper de la tenue : ~r~Journaliste ",
                    minimum_grade = 0,
                    variations = {
                    male = {
                       ['tshirt_1'] = 12,  ['tshirt_2'] = 0,
                       ['torso_1'] = 460,   ['torso_2'] = 0,
                       ['decals_1'] = 0,   ['decals_2'] = 0,
                       ['arms'] = 28,
                       ['pants_1'] = 48,   ['pants_2'] = 0,
                       ['shoes_1'] = 28,   ['shoes_2'] = 3,
                       ['helmet_1'] = 208,  ['helmet_2'] = 0,
                       ['chain_1'] = 8,    ['chain_2'] = 0,
                       ['mask_1'] = -1,  ['mask_2'] = 0,
                       ['bproof_1'] = 203,  ['bproof_2'] = 0,
                       ['ears_1'] = 0,     ['ears_2'] = 0,
                    },
                    female = {
                       ['tshirt_1'] = 53,  ['tshirt_2'] = 0,
                       ['torso_1'] = 102,   ['torso_2'] = 0,
                       ['decals_1'] = 0,   ['decals_2'] = 0,
                       ['arms'] = 0,
                       ['pants_1'] = 59,   ['pants_2'] = 0,
                       ['shoes_1'] = 25,   ['shoes_2'] = 0,
                       ['helmet_1'] = -1,  ['helmet_2'] = 0,
                       ['chain_1'] = 0,    ['chain_2'] = 0,
                       ['mask_1'] = -1,  ['mask_2'] = 0,
                       ['bproof_1'] = 7,  ['bproof_2'] = 4,
                       ['ears_1'] = 2,     ['ears_2'] = 0,
                    }
                },
                onEquip = function()
                end
                },

        },
    },
}