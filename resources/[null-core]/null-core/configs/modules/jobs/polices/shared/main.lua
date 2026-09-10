Config.Police = {
    Pourcent = {
        withsupp = { -- Avec
            randommax = 25,
            thenbr = 2,
        }, -- pourcentage de change avec un silencieux
        withoutsupp = { -- Sans
            randommax = 12, 
            thenbr = 2,
        }, -- pourcentage de change sans silencieux
    },

}

ArmesPolice = {
    ["police"] = {
        ["foreveryone"] = { -- Pour Tous (Si le grade n'est pas inscrit alors il donnera d'office ceci) :
            {type = "weapon", name = "WEAPON_STUNGUN", label = "Tazer"},
            {type = "weapon", name = "WEAPON_NIGHTSTICK", label = "Matraque"},
            {type = "weapon", name = "WEAPON_COMBATPISTOL", label = "Pistolet de combat"},

            {type = "item", name = "kevlar", label = "Kevlar", count = 3},
            {type = "item", name = "police_cuff", label = "Menotte"},
            {type = "item", name = "police_key", label = "Clés de Menotte"},
        },
        -- Chaque grades :
        ["officer"] = {

        },
        ["caporal"] = {
            {type = "weapon", name = "WEAPON_SMG", label = "SMG"},
        },
        ["sergeant"] = {
            {type = "weapon", name = "WEAPON_SMG", label = "SMG"},
            {type = "weapon", name = "WEAPON_ASSAULTSMG", label = "SMG d'assaut"},
        },
        ["lieutenant"] = {
            {type = "weapon", name = "WEAPON_SMG", label = "SMG"},
            {type = "weapon", name = "WEAPON_ASSAULTSMG", label = "SMG d'assaut"},
            {type = "weapon", name = "WEAPON_PUMPSHOTGUN", label = "Fusil à pompe"},
        },
        ["intendent"] = {
            {type = "weapon", name = "WEAPON_SMG", label = "SMG"},
            {type = "weapon", name = "WEAPON_ASSAULTSMG", label = "SMG d'assaut"},
            {type = "weapon", name = "WEAPON_PUMPSHOTGUN", label = "Fusil à pompe"},
            {type = "weapon", name = "WEAPON_CARBINERIFLE", label = "M4 d'assaut"},
        },
        ["boss"] = {
            {type = "weapon", name = "WEAPON_SMG", label = "SMG"},
            {type = "weapon", name = "WEAPON_ASSAULTSMG", label = "SMG d'assaut"},
            {type = "weapon", name = "WEAPON_PUMPSHOTGUN", label = "Fusil à pompe"},
            {type = "weapon", name = "WEAPON_CARBINERIFLE", label = "M4 d'assaut"},
        }
    },
}

extrasCFG = {
    ['ambulance'] = {
        vec3(-1867.228760, -352.504517, 58.098557),
        vec3(-1893.777, -305.1973, 49.22018)
    },
    ['ambulancenord'] = {
        vec3(-241.2324, 6336.245, 32.35968),
        vec3(-245.898636, 6323.292969, 37.616058)
    },
    ['ambulancepillbox'] = {
        vec3(295.703186, -608.190002, 43.331772),
        vec3(328.151794, -577.759277, 28.736961),
        vec3(346.695923, -583.381226, 93.058151),
    },
    ["ambulancesandy"] = {
        vec3(1671.612671, 3679.856689, 35.336208),
        vec3(1637.461792, 3653.911133, 35.336182)
    },
    ["ambulance_eclipse"] = {
        vec3(-697.847107, 341.807404, 77.722839)
    },
    ['police'] = {
        vector3(-1051.541, -854.8378, 4.868269),
        vec3(-1106.619751, -837.880249, 38.874607),
        vec3(446.2144, -1018.027, 28.60279),
        vec3(449.4751, -981.5012, 43.69101),
        vec3(442.441254, -983.994873, 25.099049)
    },
    ['gouvls'] = {
        vec3(-408.714996, 1200.229370, 325.641571)
    },
    ['bcso'] = vec3(-457.0155, 6024.778, 31.34039),
    ['policecayo'] = vec3(4951.955078, -5287.307617, 5.203465),
    ['ambulancecayo'] = vec3(4984.906738, -5104.874023, 2.632449),
    ["taxi"] = vec3(913.558167, -179.428513, 74.192436)
}
