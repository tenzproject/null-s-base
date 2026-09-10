Config.Markers = {
    ["kart"] = {
        Position = vec3(-168.675369, -2144.346924, 17.051874),
        Public = true,
        Job = nil,
        Job2 = nil,
        Blip = {
            Name = null.getConvarKey("serverColor").."Activité~s~ | Karing",
            Sprite = 147,
            Display = 4,
            Scale = 0.8,
            Color = 5
        },
        Action = function()
            OpenMenuPlayerKarting()
        end
    },
    --[[["ikea"] = {
        Position = vec3(1088.819092, -776.571655, 58.339363),
        Public = true,
        Job = nil,
        Job2 = nil,
        Blip = {
            Name = "Ikea",
            Sprite = 52,
            Display = 4,
            Scale = 0.75,
            Color = 11
        },
        Action = function()
            TriggerEvent('NullopenNuiShop', "Ikea")
        end
    },]]
    ["lester"] = {
        Position = vec3(706.267822, -966.012939, 30.412878),
        Public = true,
        Job = nil,
        Job2 = nil,
        Blip = nil,
        Action = function()
            MenuVente()
        end
    },
    --[[["AppleStore"] = {
        Position = vec3(-1524.332886, -409.787903, 35.592243),
        Public = true,
        Job = nil,
        Job2 = nil,
        Blip = {
            Name = "Apple Store",
            Sprite = 52,
            Display = 4,
            Scale = 0.75,
            Color = 37
        },
        Action = function()
            TriggerEvent('NullopenNuiShop', "AppleStore")
        end
    },
    ["pharmacy"] = {
        Position = vec3(-486.946991, -1012.486023, 24.289181),
        Public = true,
        Job = nil,
        Job2 = nil,
        Blip = nil,
        Action = function()
            TriggerEvent('NullopenNuiShop', "pharmacy")
        end
    },]]
    ["agentimmo_patron"] = {
        Position = vec3(-714.855408, 261.080414, 84.137810),
        Public = false,
        Job = 'realestateagent',
        Job2 = nil,
        Action = function()
            OpenSocietyMenu({label = 'Agent Immobilier', name = 'realestateagent' }, vec3(-714.855408, 261.080414, 84.137810))
        end
    },
    ["taxi_patron"] = {
        Position = vec3(898.245422, -166.016251, 74.222275),
        Public = false,
        Job = 'taxi',
        Job2 = nil,
        Blip = {
            Name = null.getConvarKey("serverColor").."Entreprise ~s~| Taxi",
            Sprite = 198,
            Display = 4,
            Scale = 0.75,
            Color = 5
        },
        Action = function()
            OpenSocietyMenu({label = 'Taxi', name = 'taxi' }, vec3(898.245422, -166.016251, 74.222275))
        end
    },
    ["ambulance_garage_helico"] = {
        Position = vector3(352.24475097656,-588.6513671875,74.161750793457),
        Public = false,
        Job = 'ambulance',
        Job2 = nil,
        Action = function()
            AmbulanceOpenGarageMenu2()
        end
    },
    ["ambulance_deletehelico"] = {
        Position = vector3(352.24475097656,-588.6513671875,74.161750793457),
        Public = false,
        Job = 'ambulance',
        Job2 = nil,
        Action = function()
            AmbulanceDeleteVeh2()
        end
    },
    
}

if not IsDuplicityVersion() then
    Citizen.CreateThread(function()
        while Config.Gouvernement == nil do Wait(100) end
        while ESX == nil do Wait(100) end
        while null.data.markers == nil do Wait(100) end
        null.data.markers.register("gouvernement_citoyen", {
            Position = Config.Gouvernement.positions.acceuil,
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = nil,
            Action = function()
                MenuCitoyenGouvernement()
            end
        })

        null.data.markers.register("zonegf", {
            Position = Config.GunFightZone.enter,
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = {
                Name = "Paintball",
                Sprite = 630,
                Display = 4,
                Scale = 0.75,
                Color = 5
            },
            Action = function()
                enterZoneGF()
            end
        })
    end)
end