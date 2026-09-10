for k,v in pairs(Config.CarWash.List) do
    local markerKey = "carwash_"..k
    if null.data.markers.list[markerKey] == nil and v.Position ~= nil then
        null.data.markers.list[markerKey] = {
            Position = v.Position,
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = {
                Name = v.Label or "Car Wash",
                Sprite = 100,
                Display = 4,
                Scale = 0.75,
                Color = 0
            },
            Action = function()
                if IsPedInAnyVehicle(PlayerPedId(), true) ~= 1 or IsPedInAnyVehicle(PlayerPedId(), true) == false then
                    
                else
                    openWarcash()   
                end
            end,
            ConditionMarker = function()
                if IsPedInAnyVehicle(PlayerPedId(), true) ~= 1 or IsPedInAnyVehicle(PlayerPedId(), true) == false then
                    return
                else
                    DrawMarker(25, v.Position.x, v.Position.y, v.Position.z-0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 255, false, false, 2, false, false, false, false)
                end
            end,
            ConditionText = function()
                if IsPedInAnyVehicle(PlayerPedId(), true) ~= 1 or IsPedInAnyVehicle(PlayerPedId(), true) == false then
                    return
                else
                    null.fct.draw.Text3DBar(v.Position.x, v.Position.y,v.Position.z, "Appuyez sur [~y~E~s~] pour intéragir~s~.")
                end
            end
        }
    else
        print("Erreur de configuration dans ^1Config.CarWash^7 ("..markerKey..")")
    end
end

for k,v in pairs(Config.Properties.apartment) do
    local markerKey = "apartment_"..k
    if null.data.markers.list[markerKey] == nil and v.id ~= nil and v.Position ~= nil then
        null.data.markers.list[markerKey] = {
            Position = v.Position,
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = {
                Name = "Immeuble",
                Sprite = 475,
                Display = 4,
                Scale = 0.6,
                Color = 51,
                Type = "blip_building",
            },
            Action = function()
                OpenImmeuble(v.id, v.type, v.label)
            end
        }
    else
        print("Erreur de configuration dans ^1Config.Properties^7 ("..markerKey..")")
    end
end

for k,v in pairs(Config.PawnShop.Locations) do
    local markerKey = "pawnshop_"..k
    if null.data.markers.list[markerKey] == nil and v.position ~= nil then
        null.data.markers.list[markerKey] = {
            Position = v.position,
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = {
                Name = v.label or "Marche aux Puces",
                Sprite = 52,
                Display = 4,
                Scale = 0.75,
                Color = 24
            },
            Action = function()
                OpenPawnShop()
            end
        }
    else
        print("Erreur de configuration dans ^1Config.PawnShop^7 ("..markerKey..")")
    end
end

for k,v in pairs(Config.Barber.List) do
    local markerKey = "barber_"..k
    if null.data.markers.list[markerKey] == nil and v.Position ~= nil then
        null.data.markers.list[markerKey] = {
            Position = v.Position,
            Public = true,
            Job = nil,
            Job2 = nil,
            Blip = {
                Name = v.Label or "Salon de Coiffure",
                Sprite = 71,
                Display = 4,
                Scale = 0.75,
                Color = 31
            },
            Action = function()
                exports["null-core"]:OpenShop("barber", v.Type)
            end
        }
    else
        print("Erreur de configuration dans ^1Config.Barber^7 ("..markerKey..")")
    end
end

for k,v in pairs(Config.MakeupShop.List) do
    local markerKey = "makeupshop_"..k
    if null.data.markers.list[markerKey] == nil and v.Position ~= nil then
        if v.Blip then
            null.data.markers.list[markerKey] = {
                Position = v.Position,
                Public = true,
                Job = nil,
                Job2 = nil,
                Blip = {
                    Name = v.Label or "Salon de Beauté",
                    Sprite = 279,
                    Display = 4,
                    Scale = 0.75,
                    Color = 8
                },
                Action = function()
                    exports["null-core"]:OpenShop("makeup", v.Type)
                end
            }
        else
            null.data.markers.list[markerKey] = {
                Position = v.Position,
                Public = true,
                Job = nil,
                Job2 = nil,
                Action = function()
                    exports["null-core"]:OpenShop("makeup", v.Type)
                end
            } 
        end
    else
        print("Erreur de configuration dans ^1Config.MakeupShop^7 ("..markerKey..")")
    end
end