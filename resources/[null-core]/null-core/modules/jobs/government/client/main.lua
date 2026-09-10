if Config.Gouvernement == nil then Config.Gouvernement = {} print("[^1Null^7] Vous n'avez pas mit a jour le gouv shared") end


CreateThread(function()
    while not null.data.markers.loaded do Wait(1000) end
    while Config.Gouvernement == nil do Wait(1000) end
    null.data.markers.register("job_gouv_boss", {
        Position = vector3(Config.Gouvernement.positions.boss.x, Config.Gouvernement.positions.boss.y, Config.Gouvernement.positions.boss.z),
        Public = false,
        Job = "gouvernement",
        Job2 = nil,
        Action = function()
            OpenSocietyMenu({label = ESX.PlayerData.job.label, name = ESX.PlayerData.job.name }, vector3(Config.Gouvernement.positions.boss.x, Config.Gouvernement.positions.boss.y, Config.Gouvernement.positions.boss.z))
        end
    })
    null.data.markers.register("job_gouv_vestiaire", {
        Position = vector3(Config.Gouvernement.positions.vestiaire.x, Config.Gouvernement.positions.vestiaire.y, Config.Gouvernement.positions.vestiaire.z),
        Public = false,
        Job = "gouvernement",
        Job2 = nil,
        Action = function()
            OpenVestiaireGouv()
        end
    })
    null.data.markers.register("job_gouv_garage", {
        Position = vector3(Config.Gouvernement.positions.garage.x, Config.Gouvernement.positions.garage.y, Config.Gouvernement.positions.garage.z),
        Public = false,
        Job = "gouvernement",
        Job2 = nil,
        Action = function()
            OpenGarageGouv()
        end
    })
    null.data.markers.register("job_gouv_garage_ranger", {
        Position = vector3(Config.Gouvernement.positions.garage_ranger.x, Config.Gouvernement.positions.garage_ranger.y, Config.Gouvernement.positions.garage_ranger.z),
        Public = false,
        Job = "gouvernement",
        Job2 = nil,
        Action = function()
            if PlayerState.isInVehicle then
                DoScreenFadeOut(1500)
                Wait(1500)
                DeleteEntity(PlayerState.vehicle)
                DoScreenFadeIn(1500)
                Wait(1500)
            end  
        end
    })
end)


function OpenVestiaireGouv()
    local menu = RageUI.CreateMenu(nil, "")
    RageUI.Visible(menu, true)
    local pedArmour = GetPedArmour(PlayerState.ped)
    local hasEquipement = false
    if ESX.PlayerData.loadout then 
        for k,v in pairs(ESX.PlayerData.loadout) do
            if v.metadata and v.metadata.gouvernement then
                hasEquipement = true
            end
        end
    end

    Citizen.CreateThread(function()
        while menu do
            RageUI.IsVisible(menu, function()
                RageUI.Checkbox("Prendre son service", nil, servicegouv, {}, {
                    onChecked = function(index, items)
                        servicegouv = true
                        ESX.ShowNotification("Vous avez ~g~pris~s~ votre service !")
                    end,
                    onUnChecked = function(index, items)
                        servicegouv = false
                        ESX.ShowNotification("Vous avez ~r~quitter~s~ votre service !")
                    end
                })
                if servicegouv then
                    if Config.Gouvernement.Kevlar.enable then
                        if pedArmour > 0 then
                            RageUI.Button("Enlevez votre kevlar", nil,{RightLabel = ""}, true,{
                                onSelected = function()
                                    TriggerEvent('Null:skinchanger:getSkin', function(skin)
                                        TriggerEvent('Null:skinchanger:loadClothes', skin, {
                                            ['bproof_1'] = 0, ['bproof_2'] = 0,
                                        })
                                        SetPedArmour(PlayerPedId(), 0)
                                        pedArmour = 0
                                    end)
                                end
                            })
                        else
                            RageUI.Button("Mettre un kevlar", nil,{RightLabel = ""}, true,{
                                onSelected = function()
                                    TriggerEvent('Null:skinchanger:getSkin', function(skin)
                                        if skin.sex == 0 then
                                            TriggerEvent('Null:skinchanger:loadClothes', skin, Config.Gouvernement.Kevlar.clothes["male"])
                                            SetPedArmour(PlayerPedId(), 100)
                                            pedArmour = 100
                                        else
                                            TriggerEvent('Null:skinchanger:loadClothes', skin, Config.Gouvernement.Kevlar.clothes["female"])
                                            SetPedArmour(PlayerPedId(), 100)
                                            pedArmour = 100
                                        end
                                    end)
                                end
                            })
                        end
                    end
                    if hasEquipement then
                        RageUI.Button("Déposer son équipement", nil,{}, true,{
                            onSelected = function()
                                TriggerServerEvent("Null:gouv:vestaiaire:déposer")
                                hasEquipement = false
                            end
                        })
                    else
                        RageUI.Button("Equiper votre équipement", nil,{}, true,{
                            onSelected = function()
                                TriggerServerEvent("Null:gouv:vestaiaire:equipement")
                                hasEquipement = true
                            end
                        })
                    end
                    RageUI.Button("Vestiaire", nil, {}, true,{
                        onSelected = function()
                            RageUI.CloseAll()
                            Wait(1000)
                            OpenVestiaire(ESX.PlayerData.job.name)
                        end
                    })
                end
            end)
            if not RageUI.Visible(menu) then
                menu = RMenu:DeleteType("menu", true)
            end
            Citizen.Wait(0)
        end
    end)
end


function OpenGarageGouv()
    local menu = RageUI.CreateMenu(nil, "")
    RageUI.Visible(menu, true)
    menu.Closable = false
    Citizen.CreateThread(function()
        while menu do
            RageUI.IsVisible(menu, function()
                for k,v in pairs(Config.Gouvernement.Garage.vehicles) do
                    RageUI.Button(v.label, nil, {}, true, {
                        onSelected = function()
                            if not ESX.Game.IsSpawnPointClear(vector3(v.spawnPoint.x, v.spawnPoint.y, v.spawnPoint.z), 10.0) then
                                ESX.ShowNotification("~g~Gouvernement\n~r~Point de spawn bloquée")
                            else
                                DoScreenFadeOut(1500)
                                Wait(1500)
                                local model = GetHashKey(k)
                                RequestModel(model)
                                while not HasModelLoaded(model) do Wait(10) end
                                local gouviveh = CreateVehicle(model, v.spawnPoint.x, v.spawnPoint.y, v.spawnPoint.z, v.heading, true, false)
                                local newPlate = GenerateSocietyPlate('GOUV')
                                SetVehicleNumberPlateText(gouviveh, newPlate)
                                TriggerServerEvent('Null:garage:addTempKey', newPlate)
                                SetVehicleFixed(gouviveh)
                                TaskWarpPedIntoVehicle(PlayerPedId(),  gouviveh,  -1)
                                SetVehRadioStation(gouviveh, 0)
                                DoScreenFadeIn(1500)
                                Wait(1500)
                            end
                        end
                    })
                end
            end)
            if not RageUI.Visible(menu) then
                menu = RMenu:DeleteType("menu", true)
            end
            Citizen.Wait(0)
        end
    end)
end