
function SetupMarkerInteraction()
    Citizen.CreateThread(function()
        --while GetResourceState("null-ui") ~= "started" do Wait(200) end
        --while Add3DInteraction == nil do Wait(200) end
        Wait(500)

        local success, error = pcall(function()
            for k,v in pairs(Config.ClothingShop.List) do
                local brandId = v.Type
                Add3DInteraction({
                    id = "clothes_shop_"..k,
                    coords = v.Position,
                    text = "Ouvrir le Magasin de vêtement",
                    Action = function()
                        -- exports["null-ui"]:openMenu("clothes")
                        OpenShop("clothes", brandId)
                    end, 
                    maxDistance = 7.0,
                    key = "E",
                    blip = {
                        name = "Magasin de vêtement",
                        sprite = 73,
                        color = 17,
                        scale = 0.75,
                        display = 4,
                    }
                })
            end

            Add3DInteraction({
                id = "laboseller",
                coords = Config.laboratoire.Seller.coords,
                text = "Parler à Mark",
                Action = function()
                    openSellerMenu()
                end,
                maxDistance = 3.0,
                key = "E"
            })
            
            for k,v in pairs(Config.AccessoriesShop.List) do
                local brandId = v.Type
                Add3DInteraction({
                    id = "accesories_shop_"..k,
                    coords = v.Position,
                    text = "Ouvrir le Magasin d'accessoires",
                    Action = function()
                        --exports["null-ui"]:openMenu("accesories")
                        OpenShop("accessories", brandId)
                    end,
                    maxDistance = 7.0,
                    key = "E",
                    blip = {
                        name = v.Label,
                        sprite = 102,
                        color = 16,
                        scale = 0.75,
                        display = 4,
                    }
                })
            end

            for k,v in pairs(Config.LTD.List) do
                Add3DInteraction({
                    id = "ltd_"..k,
                    coords = v.Position,
                    text = "Ouvrir LTD Gasoline",
                    Action = function()
                        OpenShopUI(Config.LTD.StoreConfig)
                    end,
                    maxDistance = 7.0,
                    key = "E",
                    blip = {
                        name = "LTD Gasoline",
                        sprite = 52,
                        color = 69,
                        scale = 0.75,
                        display = 4,
                    }
                })
            end

            if Config.Supermarket247 and Config.Supermarket247.List then
                for k,v in pairs(Config.Supermarket247.List) do
                    Add3DInteraction({
                        id = "s247_"..k,
                        coords = v.Position,
                        text = "Ouvrir le 24/7",
                        Action = function()
                            OpenShopUI(Config.Supermarket247.StoreConfig)
                        end,
                        maxDistance = 7.0,
                        key = "E",
                        blip = {
                            name = "24/7",
                            sprite = 52,
                            color = 25,
                            scale = 0.75,
                            display = 4,
                        }
                    })
                end
            end

            if Config.RobsLiquor and Config.RobsLiquor.List then
                for k,v in pairs(Config.RobsLiquor.List) do
                    Add3DInteraction({
                        id = "robsliquor_"..k,
                        coords = v.Position,
                        text = "Ouvrir Rob's Liquor",
                        Action = function()
                            OpenShopUI(Config.RobsLiquor.StoreConfig)
                        end,
                        maxDistance = 7.0,
                        key = "E",
                        blip = {
                            name = "Rob's Liquor",
                            sprite = 52,
                            color = 1,
                            scale = 0.75,
                            display = 4,
                        }
                    })
                end
            end

            for k,v in pairs(Config.AmmunationShop.shops) do
                if v.Shop then
                    Add3DInteraction({
                        id = "ammunation_shop_"..k,
                        coords = v.Shop,
                        text = "Ouvrir l'Ammu-nation",
                        Action = function()
                            OpenShopUI(Config.AmmunationShop.storeConfig, { hasRepair = true })
                        end,
                        maxDistance = 7.0,
                        key = "E",
                        blip = {
                            name = "Ammunation",
                            sprite = 313,
                            color = 75,
                            scale = 0.55,
                            display = 4,
                        }
                    }) 
                end
            end

            for k,v in pairs(Config.Banks.List) do
                Add3DInteraction({
                    id = "bank_"..k,
                    coords = v.Position,
                    text = "Accédez à votre banque",
                    Action = function()
                        OpenBank()
                    end,
                    maxDistance = 7.0,
                    key = "E",
                    blip = {
                        name = v.Label,
                        sprite = 207,
                        color = 25,
                        scale = 0.75,
                        display = 4,
                    }
                })
            end
            
            if Config.DriveSchool and Config.DriveSchool.Locations and Config.DriveSchool.Locations[1] then
                Add3DInteraction({
                    id = "driveschool",
                    coords = Config.DriveSchool.Locations[1],
                    text = "Ouvrir l'auto-école",
                    Action = function()
                            OpenDriveSchool()
                    end,
                    maxDistance = 5.0,
                    key = "E",
                    blip = {
                        name = "Auto-École",
                        sprite = 225,
                        color = 46,
                        scale = 0.65,
                        display = 4,
                    }
                })
            end

            -- Tattoo shops : on itère sur Stores (avec Type) si disponible,
            -- sinon fallback sur l'ancien Position simple pour backward-compat.
            local tattooStores = Config.Tattoo.Stores
            if not tattooStores then
                tattooStores = {}
                for _, pos in ipairs(Config.Tattoo.Position or {}) do
                    table.insert(tattooStores, { Type = Config.Tattoo.DefaultBrand, Position = pos })
                end
            end
            for k, store in pairs(tattooStores) do
                Add3DInteraction({
                    id = "tatto_shop_"..k,
                    coords = store.Position,
                    text = "Ouvrir le Magasin de Tattoo",
                    Action = function()
                        -- Met le ped en tenue minimale pour bien voir les tattoos
                        if GetEntityModel(GetPlayerPed(-1)) == GetHashKey("mp_m_freemode_01") then
                            SetPedComponentVariation(GetPlayerPed(-1), 8,  15, 0, 2)
                            SetPedComponentVariation(GetPlayerPed(-1), 4,  21, 0, 2)
                            SetPedComponentVariation(GetPlayerPed(-1), 6,  34, 0, 2)
                            SetPedComponentVariation(GetPlayerPed(-1), 11, 15, 0, 2)
                            SetPedComponentVariation(GetPlayerPed(-1), 3,  15, 0, 2)
                            SetPedComponentVariation(GetPlayerPed(-1), 7,  0,  0, 2)
                        else
                            SetPedComponentVariation(GetPlayerPed(-1), 8,  2,  0, 2)
                            SetPedComponentVariation(GetPlayerPed(-1), 4,  15, 0, 2)
                            SetPedComponentVariation(GetPlayerPed(-1), 6,  35, 0, 2)
                            SetPedComponentVariation(GetPlayerPed(-1), 11, 15, 0, 2)
                            SetPedComponentVariation(GetPlayerPed(-1), 7,  0,  0, 2)
                        end
                        exports["null-core"]:OpenShop("tattoo", store.Type)
                    end,
                    maxDistance = 5.0,
                    key = "E",
                    blip = {
                        name = "Magasin de Tattoo",
                        sprite = 75,
                        color = 1,
                        scale = 0.75,
                        display = 4,
                    }
                })
            end
        end)

        if not success then
            null.DebugPrint("^1[ERROR] in markers-ui.lua: " .. error)
        end
    end)

end 

SetupMarkerInteraction()

RegisterCommand("reloadInteraction", function()
    SetupMarkerInteraction()
end)