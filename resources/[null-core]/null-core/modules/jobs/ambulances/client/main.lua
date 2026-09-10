EntrepriseAmbulanceBlips = {}
EntrepriseAmbulanceZone = {}

Citizen.CreateThread(function()
    Wait(3000)
    TriggerServerEvent("null:initAmbulance")
end)

RegisterNetEvent("null:ambulance:recevie", function(table)
    while null.data.markers.loaded ~= true do Wait(1000) end
    null.data.jobs.ambulances.list = table
    null.data.jobs.ambulances.loaded = true
    Wait(1000)
    for k,v in pairs(EntrepriseAmbulanceBlips) do
        ESX.removeBlip(v)
    end
    EntrepriseAmbulanceBlips = {}
    for k,v in pairs(EntrepriseAmbulanceZone) do
        null.data.markers.unregister(k)
    end
    EntrepriseAmbulanceZone = {}

    for k,v in pairs(table) do
        if v.type == 'Ambulance' then 
            ESX.addBlips({
                name = 'ambulance_'..v.name,
                label = v.label,
                category = 10,
                position = vector3(v.PosBoss.x,v.PosBoss.y,v.PosBoss.z),
                sprite = 61,
                display = 4,
                scale = 0.75,
                color = 3
            })
            EntrepriseAmbulanceBlips['ambulance_'..v.name] = 'ambulance_'..v.name
            
            if not null.data.markers.isRegister("job_ambulance_vestiaire_"..v.name) then
                EntrepriseAmbulanceZone["job_ambulance_vestiaire_"..v.name] = true
                null.data.markers.register("job_ambulance_vestiaire_"..v.name, {
                    Position = vector3(v.PosVestiaire.x, v.PosVestiaire.y, v.PosVestiaire.z),
                    Public = false,
                    Job = v.name,
                    Job2 = nil,
                    Action = function()
                        AmbulanceJobs.OpenVestiaire()
                    end
                })
            end
            
            --[[if not null.data.markers.isRegister("job_ambulance_helico_"..v.name) then
                EntrepriseAmbulanceZone["job_ambulance_helico_"..v.name] = true
                null.data.markers.register("job_ambulance_helico_"..v.name, {
                    Position = vector3(v.PosHelico.x, v.PosHelico.y, v.PosHelico.z),
                    Public = false,
                    Job = v.name,
                    Job2 = nil,
                    Action = function()
                        AmbulanceOpenGarageMenu2(vector3(v.PosHelico.x, v.PosHelico.y, v.PosHelico.z))
                    end
                })
            end]]
            
            if not null.data.markers.isRegister("job_ambulance_boss_"..v.name) then
                EntrepriseAmbulanceZone["job_ambulance_boss_"..v.name] = true
                null.data.markers.register("job_ambulance_boss_"..v.name, {
                    Position = vector3(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z),
                    Public = false,
                    Job = v.name,
                    Job2 = nil,
                    Action = function()
                        OpenSocietyMenu({label = ESX.PlayerData.job.label, name = ESX.PlayerData.job.name }, vector3(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z))
                    end
                })
            end
        end
    end
end)



AmbulanceJobs = {}
IsInServiceEMS = false
local IndexDispo = 1
local status = false
AmbulanceJobs.OpenAmbulanceMenu = function(jobname)
    local menu = RageUI.CreateMenu('Emergency System', "Voici les appeles disponibles")
    local menuAppels = RageUI.CreateSubMenu(menu, "Emergency System", 'Actions disponible')
    local OpenSelectedAppel = RageUI.CreateSubMenu(menuAppels, "Emergency System", 'Actions disponible')
    local OpenInteractAmbulanceMenu = RageUI.CreateSubMenu(menu, "Emergency System", 'Actions disponible')
    local OpenPubMenuAmbulance = RageUI.CreateSubMenu(menu, "Emergency System", 'Actions disponible')
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while menu do
        Citizen.Wait(0)
        RageUI.IsVisible(menu, function()
            RageUI.Checkbox("Status de l'entreprise", nil, status, {}, {
                onChecked = function()
                    status = true 
                    TriggerServerEvent("vsociety:updateSocietyStatus", jobname, true)
                end,
                onUnChecked = function()
                    status = false 
                    TriggerServerEvent("vsociety:updateSocietyStatus", jobname, false)
                end
            })
            RageUI.Line()
            RageUI.Button('Liste des appels', nil, {}, true, {
                onSelected = function()
                    
                end
            }, menuAppels)
            RageUI.Line()
            RageUI.Button('Réanimer une personne', nil, { }, true, {
                onSelected = function()
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    if closestPlayer == -1 or closestDistance > 3.0 then
                        ESX.ShowNotification('Aucun joueur au alentours.')
                    else
                        TaskStartScenarioInPlace(PlayerPedId(), 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
                        Citizen.Wait(10000)
                        ClearPedTasks(PlayerPedId())
                        TriggerServerEvent('EMS:RevivePlayer', GetPlayerServerId(closestPlayer))
                    end
                end
            })
            RageUI.Button('Mettre une Cane', nil, { RightBadge = nil }, true, {
                onSelected = function()
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    if closestPlayer == -1 or closestDistance > 3.0 then
                        ESX.ShowNotification('Aucun joueur au alentours.')
                    else
                        TriggerServerEvent('EMS:RevivePlayer', GetPlayerServerId(closestPlayer))
                        Time = tonumber(null.fct.input("Temps a mettre en Cane (5-30 Minutes) ?"))
                        if Time < 5 or Time > 30 then
                            ESX.ShowNotification("~r~Temps invalide !")
                            return
                        end
                        TriggerServerEvent('ata:server:updateNoCane', GetPlayerServerId(closestPlayer), Time)
                    end
                end
            })
            RageUI.Button('Emettre une facture', nil, {}, true, {
                onSelected = function() 
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    if closestPlayer == -1 or closestDistance > 3.0 then
                        ESX.ShowNotification('Il n\'y a aucun joueur au alentours')
                    else
                        local string = null.fct.input('Montant de la facture')
                        if string ~= "" then
                            Montant = tonumber(string)
                        end
                        TriggerServerEvent("Core:AddBilling", GetPlayerServerId(closestPlayer), tonumber(Montant), jobname)
                    end
                end
            })
            RageUI.Button('Faire un bandage', nil, {}, true, {
                onSelected = function()
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    if closestPlayer == -1 or closestDistance > 3.0 then
                        ESX.ShowNotification('Aucun joueur aux alentours.')
                    else
                        TaskStartScenarioInPlace(PlayerPedId(), 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
                        Citizen.Wait(10000)
                        ClearPedTasks(PlayerPedId())
                        TriggerServerEvent('EMS:HealPlayer', GetPlayerServerId(closestPlayer))
                    end
                end
            })
            RageUI.Button('Escorter/Lacher la personne', nil, {}, true, {
                onSelected = function()
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    if closestPlayer == -1 or closestDistance > 3.0 then
                        ESX.ShowNotification('Aucun joueur au alentours.')
                    else
                        -- ExecuteCommand("porter2")
                    end
                end
            })
            RageUI.Button("Montrer son badge", nil, {}, true, {
                onSelected = function()
                    ShowJobBadge(ESX.PlayerData.job.name)
                end
            })
        end, function()
        end)

        RageUI.IsVisible(menuAppels, function()
            RageUI.Separator('~s~↓ ~r~Appels en attente ~s~↓')
            for k,v in pairs(ReportListTable) do
                if v.status == 0 then
                    RageUI.Button('Appel N*'..v.numbers, 'Description : '..v.raison, {RightLabel = 'Fait à '..v.heures..'h'..v.minutes.. 'm'..v.secondes..'s'}, true, {
                        onSelected = function() 
                            SrcSelected = v.src
                            AppelsSelected = v.numbers
                        end
                    }, OpenSelectedAppel)
                end
            end
            RageUI.Separator('~s~↓ ~g~Appels en cours ~s~↓')
            for k,v in pairs(ReportListTable) do
                if v.status == 1 then
                    RageUI.Button('Appel N*'..v.numbers, 'Description : '..v.raison..'\nAppel pris par ~g~'..v.EMSName, {RightLabel = 'Fait à '..v.heures..'h'..v.minutes.. 'm'..v.secondes..'s'}, true, {
                        onSelected = function() 
                            SrcSelected = v.src
                            AppelsSelected = v.numbers
                        end
                    }, OpenSelectedAppel)
                end
            end
        end)

        RageUI.IsVisible(OpenSelectedAppel, function()
            while SrcSelected == 0 or SrcSelected == nil do Wait(1) end
            while AppelsSelected == 0 or AppelsSelected == nil do Wait(1) end
            RageUI.Separator('')
            RageUI.Separator('Appel N*~g~'..AppelsSelected)

            if ReportListTable[SrcSelected].status == 1 then
                StatusText = 'Pris par ~g~'..ReportListTable[SrcSelected].EMSName
            else 
                StatusText = '~r~En Attente'
            end

            RageUI.Separator('Status : '..StatusText)
            RageUI.Separator('')

            if ReportListTable[SrcSelected].status == 0 then
                RageUI.Button('Prendre l\'appel','Permet de prendre l\'appel, Vos collegues seront informer', {}, true, {
                    onSelected = function()
                        if not AppelEnCours then
                            AppelEnCours = true
                            blip = AddBlipForCoord(ReportListTable[SrcSelected].position)
                            SetBlipColour(blip, 60)
                            SetBlipRoute(blip, true)
                            ESX.ShowNotification('Tu as pris l\'appel N*'..AppelsSelected)
                            TriggerServerEvent('EMS:UpdateReport', SrcSelected, true) --> TRUE = PRENDRE
                        else
                            ESX.ShowNotification('Vous avez déjà un appel en cours\nCloture le pour en reprendre un.')
                        end
                    end
                })
            else
                if GetPlayerServerId(PlayerId()) == ReportListTable[SrcSelected].EMS_SRC then
                    RageUI.Button('Informer le patient de votre arriver',nil, {}, true, {
                        onSelected = function()
                            TriggerServerEvent('EMS:InformPatient', SrcSelected)
                        end
                    })
                    
                    RageUI.Button('Terminer l\'appel',nil, {}, true, {
                        onSelected = function()
                            AppelEnCours = false
                            RemoveBlip(blip)
                            ESX.ShowNotification('Vous avez terminer l\'intervention N*'..AppelsSelected)
                            TriggerServerEvent('EMS:UpdateReport', SrcSelected, false)
                        end
                    })
                end
            end
        end)

        if not RageUI.Visible(menu) and not RageUI.Visible(menuAppels) and not RageUI.Visible(OpenSelectedAppel) then
            menu = RMenu:DeleteType('menu', true)
        end
    end
end
local indexservice = 1
AmbulanceJobs.OpenVestiaire = function(jobname)
    local menu = RageUI.CreateMenu('Emergency System', "Ambulance Vestiaire")
    RageUI.Visible(menu, not RageUI.Visible(menu))
    while menu do
        Citizen.Wait(0)
        RageUI.IsVisible(menu, function()
            RageUI.Button("Accéder au vestiaire", nil, {}, true, {
                onSelected = function()
                    RageUI.CloseAll()
                    Wait(1000)
                    OpenVestiaire(ESX.PlayerData.job.name)
                end
            })
            RageUI.List("Actions", {"~g~Prendre son service~s~", "~r~Finir son service~s~"}, indexservice, nil, {}, true, {
                onListChange = function(Index)
                    indexservice = Index
                end,
                onSelected = function(Index)
                    if Index == 1 then
                        IsInServiceEMS = true
                        TriggerServerEvent('EMS:Service', true, jobname)
                        ESX.ShowNotification("Vous avez ~g~pris~s~ votre service")
                    elseif Index == 2 then
                        IsInServiceEMS = false
                        TriggerServerEvent('EMS:Service', false, jobname)
                        ESX.ShowNotification("Vous avez ~r~quitter~s~ votre service")
                    end
                end,
            })
        end, function()
        end)

        if not RageUI.Visible(menu) then
            menu = RMenu:DeleteType('menu', true)
        end
    end
end

RegisterNetEvent('EMS:HealClientPlayer', function()
    local healt = GetEntityHealth(PlayerPedId())
    if healt >= 175 then
        HealtMax = 200
    else
        HealtMax = healt + 25
    end
    SetEntityHealth(PlayerPedId(), HealtMax)
end)

RegisterNetEvent('EMS:removeBlip', function()
    if blip then
        RemoveBlip(blip)
    end
end)