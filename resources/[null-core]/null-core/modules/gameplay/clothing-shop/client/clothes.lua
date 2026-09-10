TS = true
Vetement = {

    Clothes = {},

    TshirtList = {},
    TshirtList2 = {},
    TorsoList = {},
    TorsoList2 = {},
    ArmsList = {},
    ArmsList2 = {},
    DecalsList = {},

    PantalonList = {},
    PantalonList2 = {},
    ChaussuresList = {},
    ChaussuresList2 = {},

    IndexGardeRobe = 1,
    TshirtIndex = 1,
    TshirtIndex2 = 1,
    TorsoIndex = 1,
    TorsoIndex2 = 1,
    ArmsIndex = 1,
    ArmsIndex2 = 1,
    DecalsIndex = 1,

    PantalonIndex = 1,
    PantalonIndex2 = 1,
    ChaussuresIndex = 1,
    ChaussuresIndex2 = 1
}


Citizen.CreateThread(function()
    Vetement.ArmsList2 = {}
    for i = 0, 15 do
        table.insert(Vetement.ArmsList2, i)
    end
    Vetement.DecalsList = {}
    for i = 0, 200 do
        table.insert(Vetement.DecalsList, i)
    end
end)

OpenVetementShop = function()
    local mainvet = RageUI.CreateMenu("", "Choissisez votre tenue")
    local haut = RageUI.CreateSubMenu(mainvet, "", "Voici les hauts disponibles")
    local bas = RageUI.CreateSubMenu(mainvet, "", "Voici les bas disponibles")
    local garderobe = RageUI.CreateSubMenu(mainvet, "", "Voici toutes vos tenues")
    local deposittenue = RageUI.CreateSubMenu(garderobe, "", "Voici les tenues que vous avez sur vous")

    local tshirt = RageUI.CreateSubMenu(haut, "", "Voici les T-Shirt disponibles")
    local tshirt2 = RageUI.CreateSubMenu(haut, "", "Voici les variations de T-Shirt disponibles")
    local torse = RageUI.CreateSubMenu(haut, "", "Voici les torses disponibles")
    local torse2 = RageUI.CreateSubMenu(haut, "", "Voici les variations de torses disponibles")
    local bras = RageUI.CreateSubMenu(haut, "", "Voici les bras disponibles")
    local calque = RageUI.CreateSubMenu(haut, "", "Voici les calques disponibles")

    local pantalon = RageUI.CreateSubMenu(bas, "", "Voici les pantalons disponibles")
    local pantalon2 = RageUI.CreateSubMenu(bas, "", "Voici les variations des pantalons disponibles")
    local chaussures = RageUI.CreateSubMenu(bas, "", "Voici les chaussures disponibles")
    local chaussures2 = RageUI.CreateSubMenu(bas, "", "Voici les variations des chaussures disponibles")

    mainvet.Closed = function()
        ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
            TriggerEvent('Null:skinchanger:loadSkin', skin) 
        end)
    end
    FreezeEntityPosition(PlayerPedId(), true)
    --exports["lc-inventory-v2"]:lockInventory(true)

    RageUI.Visible(mainvet, not RageUI.Visible(mainvet))
    local NoTenueDispo = false
    local OneTenueDeposit = false
    while mainvet do 
        Wait(0)

        RageUI.IsVisible(mainvet, function()

            RageUI.Button("> Hauts", "Choisisez le haut de votre tenue", {}, true, {}, haut)

            RageUI.Button("> Bas", "Choisisez le bas de votre tenue", {}, true, {}, bas)

            RageUI.Separator("")

            --RageUI.Button("> Garde Robe", "Accéder à la garde robe", {}, true, {}, garderobe)

            RageUI.Button("> Valider la tenue sans l'enregister", nil, {BackgroundColor = {R = 0, G = 255, B = 0, A = 255}, RightLabel = '~r~500 $'}, true, {
                onSelected = function()  
                    ESX.TriggerServerCallback("Null:cbmoneytenue", function(cb)
                        if cb == true then 
                            TriggerEvent("Null:skinchanger:getSkin", function(skin)
                                TriggerServerEvent("Null:esx_skin:save", skin)
                            end)
                            RageUI.CloseAll()
                        else
                            ESX.ShowNotification("Vous ne disposez pas des fonds nécéssaires")
                        end
                    end)
                end
            })

            RageUI.Button("> Valider la tenue et l'enregister", nil, {BackgroundColor = {R = 0, G = 255, B = 0, A = 255}, RightLabel = '~g~750 $'}, true, {
                onSelected = function()
                    local name = null.fct.input("Indiquer le nom de la tenue")
                    if name then 
                        local TempoSkin = {}
                        local ListVet = {
                            ["tshirt_1"] = true,
                            ["tshirt_2"] = true,
                            ["torso_1"] = true,
                            ["torso_2"] = true,
                            ["arms"] = true,
                            ["arms_2"] = true,
                            ["decals_1"] = true,
                            ["pants_1"] = true,
                            ["pants_2"] = true,
                            ["shoes_1"] = true,
                            ["shoes_2"] = true,
                        }
                        TriggerEvent("Null:skinchanger:getSkin", function(skin)
                            TriggerServerEvent("Null:esx_skin:save", skin)
                            for k,v in pairs(skin) do 
                                if ListVet[k] ~= nil then
                                    TempoSkin[k] = v
                                end
                            end
                            TriggerServerEvent("lcode:addCloth", "outfit", name, TempoSkin)
                            ESX.ShowNotification("Vous avez reçu une nouvelle tenue")
                            --TriggerServerEvent("Null:addtenueitem", name, TempoSkin)
                        end)
                       --Vetement.Clothes["tshirt_1"] =  Vetement.TshirtIndex
                       --Vetement.Clothes["tshirt_2"] =  Vetement.TshirtIndex2
                       --Vetement.Clothes["torso_1"] =  Vetement.TorsoIndex
                       --Vetement.Clothes["torso_2"] =  Vetement.TorsoIndex2
                       --Vetement.Clothes["arms"] =  Vetement.ArmsIndex
                       --Vetement.Clothes["arms_2"] =  0
                       --Vetement.Clothes["decals_1"] =  Vetement.DecalsIndex
                       --Vetement.Clothes["pants_1"] =  Vetement.PantalonIndex
                       --Vetement.Clothes["pants_2"] =  Vetement.PantalonIndex2
                       --Vetement.Clothes["shoes_1"] =  Vetement.ChaussuresIndex
                       --Vetement.Clothes["shoes_2"] =  Vetement.ChaussuresIndex2
                        --TriggerServerEvent("Null:addtenueitem", name, Vetement.Clothes)
                    end
                end
            })
            
        end, function()
        end)

        RageUI.IsVisible(haut, function()

            RageUI.Button("T-Shirt", nil, {}, true, {}, tshirt)

            RageUI.Button("Variations T-Shirt", nil, {}, true, {}, tshirt2)

            RageUI.Button("Torses", nil, {}, true, {}, torse)

            RageUI.Button("Variations Torses", nil, {}, true, {}, torse2)

            RageUI.Button("Bras", nil, {}, true, {}, bras)

            RageUI.Button("Calques", nil, {}, true, {}, calque)

        end, function()
        end)
     
        
        RageUI.IsVisible(bas, function()

            RageUI.Button("Pantalon", nil, {}, true, {}, pantalon)
            RageUI.Button("Variations Pantalon", nil, {}, true, {}, pantalon2)
            RageUI.Button("Chaussures", nil, {}, true, {}, chaussures)
            RageUI.Button("Variations Chaussures", nil, {}, true, {}, chaussures2)
            
        end, function()
        end)

        RageUI.IsVisible(garderobe, function()

            RageUI.Button("> Déposer une tenues", nil, {}, true, {}, deposittenue)
        
            if ClothesPlayer ~= nil then 
                for k, v in pairs(ClothesPlayer) do 
                    if v.equip == "n" and v.type == "vetement" then 
                        NoTenueDispo = true
                        RageUI.List("Tenue "..v.label, {"Prendre sur soi", "Equiper", "Renommer", "Supprimer"}, Vetement.IndexGardeRobe, nil, {}, true, {
                            onListChange = function(Index)
                                Vetement.IndexGardeRobe = Index
                            end,
                            onSelected = function(Index)
                                if Index == 1 then 
                                    TriggerServerEvent('lcode:addCloth', 'outfit', "Tenue "..v.label, v.id)
                                    --TriggerServerEvent("Null:tenuegarderobe", "equip", v.id)
                                elseif Index == 2 then 
                                    TriggerEvent("Null:skinchanger:getSkin", function(skin)
                                        TriggerEvent("Null:skinchanger:loadClothes", skin, json.decode(v.skin))
                                        Wait(100)
                                        TriggerServerEvent("Null:esx_skin:save", skin)
                                        RageUI.CloseAll()
                                        ESX.ShowNotification("Vous avez équiper votre tenue "..v.label.."")
                                    end)
                                elseif Index == 3 then
                                    local newname = null.fct.input("Nouveau nom")
                                    if newname then 
                                        TriggerServerEvent("Null:RenameTenue", v.id, newname)
                                    end
                                elseif Index == 4 then 
                                    TriggerServerEvent('Null:deletetenue', v.id)
                                end
                            end
                        })
                    else
                        NoTenueDispo = false
                    end
                end
                if not NoTenueDispo then 
                    RageUI.Separator("~r~Aucune tenue disponible")
                end
            else
                RageUI.Separator("~r~Vous n'avez pas de tenue")
            end
        end)

        RageUI.IsVisible(deposittenue, function()
            if ClothesPlayer ~= nil  then 
                for k, v in pairs(ClothesPlayer) do 
                    if v.equip ~= "n" then 
                        OneTenueDeposit = true
                        RageUI.Button("Tenue "..v.label, nil, {RightLabel = "Déposer"}, true, {
                            onSelected = function()
                                TriggerServerEvent("Null:tenuegarderobe", "deposit", v.id)
                            end
                        })
                    else
                        OneTenueDeposit = false
                    end
                end
                if not OneTenueDeposit then 
                    RageUI.Separator("~r~Vous n'avez pas de tenue déposer")
                end
            end
        end)

        RageUI.IsVisible(tshirt, function()
            RageUI.Button("T-Shirt 0", nil, {}, true, {
                onActive = function()
                    Vetement.TshirtList2 = {}
                    TriggerEvent('Null:skinchanger:change', 'tshirt_1', 0)
                    TriggerEvent('Null:skinchanger:change', 'tshirt_2', 0)
                    Vetement.TshirtIndex = 0
                    for i = 0, GetNumberOfPedTextureVariations(PlayerPedId(), 8, 0) -2 do
                        table.insert(Vetement.TshirtList2, i)
                    end
                end
            })
            for i = 0, GetNumberOfPedDrawableVariations(PlayerPedId(), 8) - 1, 1 do
                RageUI.Button("T-Shirt "..i, nil, {}, true, {
                    onActive = function()
                        Vetement.TshirtList2 = {}
                        Vetement.TshirtIndex = i
                        TriggerEvent('Null:skinchanger:change', 'tshirt_1', i)
                        TriggerEvent('Null:skinchanger:change', 'tshirt_2', 0)
                        for n = 0, GetNumberOfPedTextureVariations(PlayerPedId(), 8, i) -2 do
                            table.insert(Vetement.TshirtList2, n)
                        end
                    end
                })
            end
        end)

        RageUI.IsVisible(tshirt2, function()
            RageUI.Button("Variation T-Shirt 0", nil, {}, true, {
                onActive = function()
                    Vetement.TshirtIndex2 = 0
                    TriggerEvent('Null:skinchanger:change', 'tshirt_2', 0)
                end
            })
            for k, v in pairs(Vetement.TshirtList2) do
                RageUI.Button("Variation T-Shirt "..k, nil, {}, true, {
                    onActive = function()
                        Vetement.TshirtIndex2 = k
                        TriggerEvent('Null:skinchanger:change', 'tshirt_2', k)
                    end
                })
            end
        end)

        RageUI.IsVisible(torse, function()
            RageUI.Button("Torse 0", nil, {}, true, {
                onActive = function()
                    Vetement.TorsoList2 = {}
                    Vetement.TorsoIndex = 0
                    TriggerEvent('Null:skinchanger:change', 'torso_1', 0)
                    TriggerEvent('Null:skinchanger:change', 'torso_2', 0)
                    for i = 0, GetNumberOfPedTextureVariations(PlayerPedId(), 11, 0) -2 do
                        table.insert(Vetement.TorsoList2, i)
                    end
                end
            })
            -- Torses
            for i = 0, GetNumberOfPedDrawableVariations(PlayerPedId(), 11) - 1, 1 do
                RageUI.Button("Torse "..i, nil, {}, true, {
                    onActive = function()
                        Vetement.TorsoList2 = {}
                        Vetement.TorsoIndex = i
                        TriggerEvent('Null:skinchanger:change', 'torso_2', 0)
                        TriggerEvent('Null:skinchanger:change', 'torso_1', i)
                        for n = 0, GetNumberOfPedTextureVariations(PlayerPedId(), 11, i) -2 do
                            table.insert(Vetement.TorsoList2, i)
                        end
                    end
                })
            end
        end)

        RageUI.IsVisible(torse2, function()
            RageUI.Button("Variations Torse 0", nil, {}, true, {
                onActive = function()
                    Vetement.TorsoIndex2 = 0
                    TriggerEvent('Null:skinchanger:change', 'torso_2', 0)
                end
            })
            for k, v in pairs(Vetement.TorsoList2) do
                RageUI.Button("Variations Torse "..k, nil, {}, true, {
                    onActive = function()
                        Vetement.TorsoIndex2 = k
                        TriggerEvent('Null:skinchanger:change', 'torso_2', k)
                    end
                })
            end
        end)

        RageUI.IsVisible(bras, function()
            for i = 0, GetNumberOfPedDrawableVariations(PlayerPedId(), 3) - 1, 1 do
                RageUI.Button("Bras "..i, nil, {}, true, {
                    onActive = function()
                        Vetement.ArmsIndex = i
                        TriggerEvent('Null:skinchanger:change', 'arms', i)
                    end
                })
            end
        end)

        RageUI.IsVisible(calque, function()
            RageUI.Button("Calques 0", nil, {}, true, {
                onActive = function()
                    Vetement.DecalsIndex = 0
                    TriggerEvent('Null:skinchanger:change', 'decals_1', 0)
                end
            })
            for k, v in pairs(Vetement.DecalsList) do
                RageUI.Button("Calques "..k, nil, {}, true, {
                    onActive = function()
                        Vetement.DecalsIndex = k
                        TriggerEvent('Null:skinchanger:change', 'decals_1', k)
                    end
                })
            end
        end)

        RageUI.IsVisible(pantalon, function()
            RageUI.Button("Pantalon 0", nil, {}, true, {
                onActive = function()
                    TriggerEvent('Null:skinchanger:change', 'pants_1', 0)
                    TriggerEvent('Null:skinchanger:change', 'pants_2', 0)
                    Vetement.PantalonList2 = {}
                    Vetement.PantalonIndex = 0
                    for i = 0, GetNumberOfPedTextureVariations(PlayerPedId(), 4, 0) -2 do
                        table.insert(Vetement.PantalonList2, i)
                    end
                end
            })
            for i = 0, GetNumberOfPedDrawableVariations(PlayerPedId(), 4) - 1, 1 do
                RageUI.Button("Pantalon "..i, nil, {}, true, {
                    onActive = function()
                        TriggerEvent('Null:skinchanger:change', 'pants_1', i)
                        TriggerEvent('Null:skinchanger:change', 'pants_2', 0)
                        Vetement.PantalonList2 = {}
                        Vetement.PantalonIndex = i
                        for n = 0, GetNumberOfPedTextureVariations(PlayerPedId(), 4, i) -2 do
                            table.insert(Vetement.PantalonList2, n)
                        end
                    end
                })
            end
        end)

        RageUI.IsVisible(pantalon2, function()
            RageUI.Button("Variation Pantalon 0", nil, {}, true, {
                onActive = function()
                    Vetement.PantalonIndex2 = 0
                    TriggerEvent('Null:skinchanger:change', 'pants_2', 0)
                end
            })
            for k, v in pairs(Vetement.PantalonList2) do 
                RageUI.Button("Variation Pantalon "..k, nil, {}, true, {
                    onActive = function()
                        Vetement.PantalonIndex2 = k
                        TriggerEvent('Null:skinchanger:change', 'pants_2', k)
                    end
                })
            end
        end)

        RageUI.IsVisible(chaussures, function()
            for i = 0, GetNumberOfPedDrawableVariations(PlayerPedId(), 6) - 1, 1 do
                RageUI.Button("Chaussure "..i, nil, {}, true, {
                    onActive = function()
                        Vetement.ChaussuresIndex = i
                        TriggerEvent('Null:skinchanger:change', 'shoes_1', i)
                        TriggerEvent('Null:skinchanger:change', 'shoes_2', 0)
                        Vetement.ChaussuresList2 = {}
                        for n = 0, GetNumberOfPedTextureVariations(PlayerPedId(), 6, i) -2 do
                            table.insert(Vetement.ChaussuresList2, n)
                        end                    
                    end
                })
            end
        end)

        RageUI.IsVisible(chaussures2, function()
            RageUI.Button("Variation Chaussure 0", nil, {}, true, {
                onActive = function()
                    Vetement.ChaussuresIndex2 = 0
                    TriggerEvent('Null:skinchanger:change', 'shoes_2', 0)
                end
            })
            for k, v in pairs(Vetement.ChaussuresList2) do 
                RageUI.Button("Variation Chaussure "..k, nil, {}, true, {
                    onActive = function()
                        Vetement.ChaussuresIndex2 = k
                        TriggerEvent('Null:skinchanger:change', 'shoes_2', k)
                    end
                })
            end
        end)

        if not RageUI.Visible(mainvet) and 
        not RageUI.Visible(haut) and 
        not RageUI.Visible(garderobe) and

        not RageUI.Visible(deposittenue) and
        not RageUI.Visible(tshirt) and 
        not RageUI.Visible(tshirt2) and 
        not RageUI.Visible(torse) and 
        not RageUI.Visible(torse2) and 
        not RageUI.Visible(bras) and 
        not RageUI.Visible(calque) and 

        not RageUI.Visible(pantalon) and 
        not RageUI.Visible(pantalon2) and 
        not RageUI.Visible(chaussures) and 
        not RageUI.Visible(chaussures2) and 

        
        not RageUI.Visible(bas) then 
            mainvet = RMenu:DeleteType('mainvet')
            FreezeEntityPosition(PlayerPedId(), false)
            --exports["lc-inventory-v2"]:lockInventory(false)
        end
    end
end