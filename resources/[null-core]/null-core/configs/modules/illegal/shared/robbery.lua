Config.Robbery = {
    Jewelry = {
        rewardPerBijou = 25,
    },
    RequiredPolice = 0,
    TempsAttenteBraquage = {600, 1800}, -- Temps aléatoire pour les demandes de braquage (secondes)
    HackerPos = vector2(1272.414307, -1711.938843),
    HackerPos2 = vec3(1272.552979, -1712.064697, 54.771458),
    HackerInfo = {
        ["Brinks"] = 1750,
        ["ROGER"] = 650,
    },
    BrinksRecompense = {2000, 9250} -- entre ... et ....
}

Fleeca = {}

Fleeca.RemoveItem = true -- Remove Item when using
Fleeca.RequiredCops = 0
Fleeca.CopsJobName = "police"
Fleeca.CoolDown = 600

Fleeca.NeedBag = false -- If you need to have a bag to start Fleeca Heist

Fleeca.DefaultReward = {
    [1] = 5000,-- Min
    [2] = 15000, -- Max
}

Fleeca.posFleeca = {}

Fleeca.Locale = {
    NotInFleeca = "You are not at a ~r~Fleeca Bank~s~.",
    NeedBag = "You ~r~must~s~ have a ~r~bag~s~.",
    UseDrill = "Press ~INPUT_CONTEXT~ to use your ~b~drill~s~.",
    BankCoolDown = "This bank has already been robbed.",
    NoCops = "The Brinks has just passed, there is no more money.",
    GiveMoney = "You got ~r~ $"
}

Config.ContainerRobbery = {
    Spawn_zones = {
        ["1"] = {
            id = 1,
            pos = vector4(957.8347, -3090.764, 5.900766,270.552),
            last = 0,
        },
        ["2"] = {
            id = 2,
            pos = vector4(957.6513, -3095.999, 5.900763,270.795),
            last = 0,
        },
        ['3'] = {
            id = 3,
            pos = vector4(984.75, -2876.18, 19.01, 270.43),
            last = 0,
        },
        ['4'] = {
            id = 4,
            pos = vector4(1085.60, -3257.44, 5.29, 268.98),
            last = 0,
        },
        ['5'] = {
            id = 5,
            pos = vector4(1147.98, -3245.13, 5.89, 0.82),
            last = 0,
        },
        ['6'] = {
            id = 6,
            pos = vector4(1274.62, -3240.41, 5.86, 268.20),
            last = 0,
        },
        ['7'] = {
            id = 7,
            pos = vector4(1274.84, -3099.74, 5.86, 265.55),
            last = 0,
        },
        ['8'] = {
            id = 8,
            pos = vector4(1215.75, -3013.96, 5.86, 270.60),
            last = 0,
        },
        ['9'] = {
            id = 9,
            pos = vector4(835.26, -2920.67, 5.88, 87.93),
            last = 0,
        },
        ['10'] = {
            id = 10,
            pos = vector4(997.52, -3036.84, 5.90, 268.07),
            last = 0,
        },
        ['11'] = {
            id = 11,
            pos = vector4(798.46, -3201.12, 5.90, 333.94),
            last = 0,
        },
        ['12'] = {
            id = 12,
            pos = vector4(1242.07, -3019.62, 13.73, 271.18),
            last = 0,
        },
        ['13'] = {
            id = 13,
            pos = vector4(1233.94, -2964.34, 12.15, 180.42),
            last = 0,
        },
        ['14'] = {
            id = 14,
            pos = vector4(1044.83, -2916.83, 5.89, 2.51),
            last = 0,
        },
        ['15'] = {
            id = 15,
            pos = vector4(1044.37, -2878.64, 19.00, 90.0),
            last = 0,
        },
        ['16'] = {
            id = 16,
            pos = vector4(998.33, -2978.94, 14.32, 89.99),
            last = 0,
        },
        ['17'] = {
            id = 17,
            pos = vector4(1040.52, -3031.46, 5.89, 90.22),
            last = 0,
        },
        ['18'] = {
            id = 18,
            pos = vector4(930.90, -3077.46, 11.50, 89.99),
            last = 0,
        },
        ['19'] = {
            id = 19,
            pos = vector4(851.15, -3265.99, 5.89, 272.32),
            last = 0,
        },
        ['20'] = {
            id = 20,
            pos = vector4(1244.13, -3329.40, 6.02, 359.77),
            last = 0,
        },
    }
}