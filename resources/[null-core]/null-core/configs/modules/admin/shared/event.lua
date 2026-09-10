Config.Event = {
    CamionBlinder = {
        PricePerPalette = 2000,
        AutoEventInterval = 60, -- En minute
        AutoEventNbrPlayer = 10, -- Nombre de joueur minimal pour lancer l'event automatique
        AutoEvent = {
            {
                pos = vector3(-182.5941, -891.2957, 29.33857),
                reward = {
                    { pos = vector3(-181.9299, -880.7997, 29.35008)},
                    { pos = vector3(-176.771, -893.2791, 29.33994)},
                    { pos = vector3(-187.6028, -900.0408, 29.34871)},
                }
            },
            {
                pos = vector3(27.88299, -1722.806, 29.30294),
                reward = {
                    { pos = vector3(17.25285, -1722.961, 29.30293)},
                    { pos = vector3(19.33466, -1712.337, 29.29928)},
                    { pos = vector3(25.21941, -1706.947, 29.2952)},
                }
            },
            {
                pos = vector3(-119.0014, -488.2652, 30.06849),
                reward = {
                    { pos = vector3(-109.5207, -488.1952, 30.38207)},
                    { pos = vector3(-114.0339, -494.2086, 30.32321)},
                    { pos = vector3(-123.3315, -496.1223, 29.98015)},
                }
            },
            {
                pos = vector3(-608.4604, 337.8598, 85.11673),
                reward = {
                    { pos = vector3(-610.401, 343.8043, 85.11674)},
                    { pos = vector3(-620.5007, 334.7534, 85.11674)},
                    { pos = vector3(-613.9526, 331.3243, 85.11738)},
                }
            }
        }
    },
    Track = {
        VehiculePacks = {
            ["allEcuries"] = {"sultan"},
            ["mercedes"] = {"brabus800", "amgone", "gle900rocket"},
            ["audi"] = {"mansoryrsq3", "asixbyv", "audis1"},
            ["ferrari"] = {"ferrari812", "911venom"},
            ["lamborghini"] = {"aventadorS", "Royal_Aventador_Anim"},
        }
    },
    CadeauNoel = {
        MinPlayers = 30, -- 30
        Spawn = {
            vec3(143.283478, -1266.500000, 29.261179),
            vec3(419.908020, -1333.043457, 46.053783),
            vec3(806.433594, -1612.153809, 31.453817),
            vec3(892.120422, -1872.117798, 30.627081),
            vec3(470.777557, -935.930481, 36.341198),
            vec3(520.245056, -978.892212, 30.587124),
            vec3(335.503937, -910.228149, 53.402355),
            vec3(33.531849, -771.297119, 44.232590),
            vec3(-638.215881, -220.358841, 53.544586),
            vec3(115.711571, 263.604736, 125.357307),
            vec3(621.221741, 1003.719299, 260.967865),
            vec3(-813.149170, 1107.536377, 277.652435),
            vec3(-1676.852783, 491.822449, 128.876297),
            vec3(-2322.508057, 293.426422, 169.467133),
            vec3(-1374.461670, -452.513092, 34.478069),
        },
        Reward = {
            --{label = "10X Pains", name = "bread", type = "item", count = 10},
            --{label = "10X Eaux", name = "water", type = "item", count = 10},
            {label = "50 Coins", name = "coins", type = "coins", count = 50},
            {label = "150 Coins", name = "coins", type = "coins", count = 150},
            {label = "5000$", name = "cash", type = "cash", count = 5000},
            --{label = "Sultan", name = "sultan", type = "vehicles", count = 5000},
        }
    }
}
SaveVehiculeEcurie = {}

for k,v in pairs(Config.Event.Track.VehiculePacks) do 
    if k ~= "allEcuries" then
        SaveVehiculeEcurie[k] = v
    end
 end


for k,v in pairs(Config.Event.Track.VehiculePacks) do 
    if k ~= "allEcuries" then
        for k2, v2 in pairs(v) do
            table.insert(Config.Event.Track.VehiculePacks["allEcuries"], v2)
        end
    end
 end
