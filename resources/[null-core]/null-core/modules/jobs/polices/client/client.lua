local BlipsPolice = {}
ServicePoliceArme = false

exports("GetPolice", function()
    return null.data.jobs.polices.list
end)

RegisterNetEvent("null:job:police:armeservice")
AddEventHandler("null:job:police:armeservice", function(bool)
    ServicePoliceArme = bool
end)

PoliceMenu = {
    AgentInService = 0,
    Matricule = "~r~Indéfini",
    NamePrename = "~r~Indéfini",
    ReasonArrestation = "~r~Indéfini",
    TimePrison = "~r~Indéfini",
    MatriculeKey = false,
    NamePrenameKey = false,
    ReasonArrestationKey = false,
    TimePrisonKey = false
}

CasierPolice = {}
local DragStatus = {}
DragStatus.isDragged = false
DragStatus.dragger = tonumber(draggerId)
ServicePoliceCheck = false
local IndexTig = 1
local ListTimeTig = { "5", "10", "15", "20", "30", "45"}
local Isintig = false
local Tiged = {}
local cansellfruit = false

local IndexDispo = 1
local status = false

function PlayerMarker(player)
    local ped = GetPlayerPed(player)
    local coords = GetEntityCoords(ped)
    DrawMarker(1, coords.x, coords.y, coords.z + 2.0, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 255, 0, 0, 170, false, true, nil, true)
end

function PlayerMarker2(player)
    local ped = GetPlayerPed(player)
    local coords = GetEntityCoords(ped)
    DrawMarker(1, coords.x, coords.y, coords.z + 2.0, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 0, 255, 0, 170, false, true, nil, true)
end

PoliceJobs = {
    openPolice = function()
        local mainmenupolice = RageUI.CreateMenu("", "Voici les actions disponibles")
        local interactioncitoyenspolice = RageUI.CreateSubMenu(mainmenupolice, "", "Voici les actions disponibles")
        local interactionvehiculepolice = RageUI.CreateSubMenu(mainmenupolice, "", "Voici les actions disponibles")
        local casierjudiciairepolice = RageUI.CreateSubMenu(mainmenupolice, "", "Voici les actions disponibles")
        local miseenprisonpolice = RageUI.CreateSubMenu(interactioncitoyenspolice, "", "Voici les actions disponibles")
        local tigmok = RageUI.CreateSubMenu(interactioncitoyenspolice, "", "Voici les actions disponibles")
        RageUI.Visible(mainmenupolice, not RageUI.Visible(mainmenupolice))
        while mainmenupolice do 
            Citizen.Wait(0)
            RageUI.IsVisible(mainmenupolice, function()
                --RageUI.Separator("Agent en service: "..ESX.Config("serverColor")..PoliceMenu.AgentInService.."")
                if ServicePoliceCheck then 
                    RageUI.Checkbox("Status de l'entreprise", nil, status, {}, {
                        onChecked = function()
                            status = true 
                            TriggerServerEvent("vsociety:updateSocietyStatus", ESX.PlayerData.job.name, true)
                        end,
                        onUnChecked = function()
                            status = false 
                            TriggerServerEvent("vsociety:updateSocietyStatus", ESX.PlayerData.job.name, false)
                        end
                    })
                    RageUI.Separator("")
                    RageUI.Button("Intéractions mdt", "Vous permet d'ouvrir la tablette de police", {}, true, {
                        onSelected = function()
                            ExecuteCommand("policetablet")
                        end
                    })
                    RageUI.Button("Intéractions citoyens", "Vous permet d'intéragir avec les citoyens", {}, true, {}, interactioncitoyenspolice)
                    RageUI.Button("Intéractions véhicule", "Vous permet d'intéragir avec les véhicules", {}, true, {}, interactionvehiculepolice)
                    RageUI.Button("Montrer son badge", nil, {}, true, {
                        onSelected = function()
                            ShowJobBadge(ESX.PlayerData.job.name)
                        end
                    })
                end
            end)
            RageUI.IsVisible(interactioncitoyenspolice, function()
                RageUI.Button("Fouiller un individu", "Vous permet de fouiller un citoyen", {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestPlayer ~= -1 and closestDistance <= 3.0 then
                            PlayerMarker(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestPlayer ~= -1 and closestDistance <= 3.0 then
                            RageUI.CloseAll()
                            ESX.TriggerServerCallback('null:fouiller', function(data, id)
                                if data then
                                    local inventory = data
                                    inventory.weight = 0
                                    inventory.id = GetPlayerServerId(closestPlayer)
                                    inventory.maxWeight = 1000
                                    inventory.type = "PLAYER"
                                    TriggerEvent("inventory:openSearch", inventory, false, data.cash or 0,data.dirtycash or 0)
                                end
                            end, GetPlayerServerId(closestPlayer))
                        end
                    end
                })
    
                RageUI.Button("Mettre dans un véhicule", "Vous permet de mettre l'individu dans un véhicule", {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestPlayer ~= -1 and closestDistance <= 3.0 then
                            PlayerMarker(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local player, distance = ESX.Game.GetClosestPlayer()
                        if distance ~= -1 and distance <= 3.0 then
                            TriggerServerEvent('police:putInVehicle', GetPlayerServerId(player))
                        else
                            ESX.ShowNotification('~r~Aucun joueur~s~ à proximité')
                        end
                    end
                })
    
                RageUI.Button("Sortir du véhicule", "Vous permet de sortir un individu du véhicule véhicule", {}, true, {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestPlayer ~= -1 and closestDistance <= 3.0 then
                            PlayerMarker(closestPlayer)
                        end
                    end, 
                    onSelected = function()
                        local player, distance = ESX.Game.GetClosestPlayer()
                        if distance ~= -1 and distance <= 3.0 then
                            TriggerServerEvent('police:OutVehicle', GetPlayerServerId(player))
                        else
                            ESX.ShowNotification('~r~Aucun joueur~s~ à proximité')
                        end
                    end
                })
    
                RageUI.Button("Escorter", "Vous permet d'escorter le joueur", {}, true, {
                    onSelected = function() 
                        local player, distance = ESX.Game.GetClosestPlayer()
                        if distance ~= -1 and distance <= 3.0 then
                            TriggerServerEvent('esx_policejob:drag', GetPlayerServerId(player))
                        else
                            ESX.ShowNotification('~r~Aucun joueur~s~ à proximité')
                        end
                    end,
                })
    
                RageUI.Button("Mettre une amende", "Vous permet de mettre une facture", {}, true, {
                    onSelected = function() 
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestPlayer ~= -1 and closestDistance <= 3.0 then
                            local string = null.fct.input('Montant :')
                            if string ~= "" then
                                Montant = tonumber(string)
                            end
                            local string2 = null.fct.input('Raison :')
                            if string2 == "" or string2 == nil then
                                ESX.ShowNotification("Veuillez preciser une raison !")
                                return
                            end
	                        TriggerServerEvent('Null:esx_billing:sendBill', GetPlayerServerId(closestPlayer), "null", string2, tonumber(Montant))
                        else
                            ESX.ShowNotification('Il n\'y a aucun joueurs au alentours', "~r~Erreur")
                        end
                    end,
                })

                RageUI.Button("Mise en cellule", nil, {}, true, {}, miseenprisonpolice)
                    if ESX.PlayerData.job.grade_name ~= "recruit" then
                        RageUI.Button('TIG', false, {}, true, {}, tigmok)
                    end
            
            end, function()
            end)
    
            RageUI.IsVisible(interactionvehiculepolice, function()
                RageUI.Button('Crocheter Véhicule', nil, {}, true, {
                    onActive = function()
                        local vehicle   = ESX.Game.GetClosestVehicle(GetEntityCoords(PlayerPedId(), false), false)
                        local VehiclePos = 	GetEntityCoords(vehicle)
                        DrawMarker(2, VehiclePos.x, VehiclePos.y, VehiclePos.z+1.8, 0, 0, 0, 180.0,nil,nil, 0.5, 0.5, 0.5, 255, 143, 0, 170, false, true, nil, true)
                    end,
                    onSelected = function() 
                        local vehicle = ESX.Game.GetVehicleInDirection()
                        if DoesEntityExist(vehicle) then
                            local plyPed = PlayerPedId()
        
                            TaskStartScenarioInPlace(plyPed, 'WORLD_HUMAN_WELDING', 0, true)
                            Citizen.Wait(20000)
                            ClearPedTasksImmediately(plyPed)
        
                            SetVehicleDoorsLocked(vehicle, 1)
                            SetVehicleDoorsLockedForAllPlayers(vehicle, false)
                            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..'~r~Police~s~', 'Information véhicule~s~', 'Véhicule ~g~dévérouillé~s~', 'CHAR_CARSITE', 1)
                        else
                            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..'~r~Police~s~', 'Information véhicule~s~', '~r~Aucun véhicule~s~ à proximité~s~', 'CHAR_CARSITE', 1)
                        end
                    end,
                })
    
                RageUI.Button('Mettre en fourrière', nil, {}, true, {
                    onActive = function()
                        local vehicle   = ESX.Game.GetClosestVehicle(GetEntityCoords(PlayerPedId(), false), false)
                        local VehiclePos = 	GetEntityCoords(vehicle)
                        DrawMarker(2, VehiclePos.x, VehiclePos.y, VehiclePos.z+1.8, 0, 0, 0, 180.0,nil,nil, 0.5, 0.5, 0.5, 255, 143, 0, 170, false, true, nil, true)
                    end,
    
                    onSelected = function() 
                        local vehicle = ESX.Game.GetVehicleInDirection()
                        local plyPed = PlayerPedId()
    
                        TaskStartScenarioInPlace(plyPed, 'CODE_HUMAN_MEDIC_TEND_TO_DEAD', 0, true)
                        
                        ClearPedTasks(plyPed)
                        Citizen.Wait(4000)
                        ESX.Game.DeleteVehicle(vehicle)
                        ClearPedTasks(plyPed) 
                        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..'~r~Police~s~', 'Information véhicule~s~', 'Le véhicule à été mis en fourrière', 'CHAR_CARSITE', 1)
                    end
                })
            
            end, function()
            end)
    
            RageUI.IsVisible(casierjudiciairepolice, function()
                
                RageUI.Button("Votre Matricule", nil, {RightLabel = PoliceMenu.Matricule}, true, {
                    onSelected = function()
                        local matricule = null.fct.input('Votre Matricule (EX : 113) :', false, 9000000, "text")
                        if matricule then 
                            PoliceMenu.Matricule = matricule
                            CasierPolice.matricule = matricule
                            PoliceMenu.MatriculeKey = true 
                        end
                    end
                })
    
                RageUI.Button("Nom/Prénom de l'individu", nil, {RightLabel = PoliceMenu.NamePrename}, PoliceMenu.MatriculeKey, {
                    onSelected = function()
                        local nameprename = null.fct.input('Entrez un maximum d\'Information de la Personne :', false, 9000000, "text")
                        if nameprename then 
                            PoliceMenu.NamePrename = "~g~Définie"
                            CasierPolice.nameprename = nameprename
                            PoliceMenu.NamePrenameKey = true 
                        end
                    end
                })
    
                RageUI.Button("Raison de l'arrestation", nil, {RightLabel = PoliceMenu.ReasonArrestation}, PoliceMenu.NamePrenameKey, {
                    onSelected = function()
                        local reason = null.fct.input('Raison :', false, 9000000, "text")
                        if reason then 
                            PoliceMenu.ReasonArrestation = "~g~Définie"
                            CasierPolice.reason = reason
                            PoliceMenu.ReasonArrestationKey = true 
                        end
                    end
                })
    
                RageUI.Button("Temps mis en cellule", nil, {RightLabel = PoliceMenu.TimePrison}, PoliceMenu.ReasonArrestationKey, {
                    onSelected = function()
                        local timecellule = null.fct.input('Temps :', false, 9000000, "number")
                        if timecellule then 
                            PoliceMenu.TimePrison = "~g~Définie"
                            CasierPolice.timecellule = timecellule
                            PoliceMenu.TimePrisonKey = true 
                        end
                    end
                })
    
                RageUI.Button("Valider le casier", nil, {}, PoliceMenu.TimePrisonKey, {
                    onSelected = function()
                        TriggerServerEvent("Null:newcasierpolice", CasierPolice)
                    end
                })
            
            end)
    
            RageUI.IsVisible(miseenprisonpolice, function()
                for k,v in pairs(null.data.jobs.polices.list[ESX.PlayerData.job.name].cellule) do
                    RageUI.Button("Cellule "..k, "Mettre en prison dans la cellule "..k, {}, true, {
                        onActive = function()
                            local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                            if closestPlayer ~= -1 and closestDistance <= 3.0 then
                                PlayerMarker(closestPlayer)
                            end
                        end,
                        onSelected = function()
                            local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                            if closestPlayer ~= -1 and closestDistance <= 3.0 then
                                if verif then 
                                    if closestDistance ~= -1 and closestDistance <= 3.0 then
                                        local timer = tonumber(null.fct.input('Temps : (secondes)'))
                                        if timer == nil then return end
                                        if timer > 1800 then ESX.ShowNotification("⚠️  Le temps ne doit pas dépasser 30 minutes") return end
                                        TriggerServerEvent('Null:miseencelule', GetPlayerServerId(closestPlayer), timer, tostring(k))
                                    else
                                        ESX.ShowNotification('~r~Aucun joueur~s~ à proximité')
                                    end
                                end 
                            else
                                ESX.ShowNotification("⚠️  Aucun joueur à proximité")
                            end
                        end
                    })
                end
            end, function()
            end)
    
            RageUI.IsVisible(tigmok, function()
                RageUI.List("Temps", ListTimeTig, IndexTig, "Merci de choisir un temps pour les T.I.G", {}, true, {
                    onListChange = function(Index)
                        IndexTig = Index
                    end,
                    onSelected = function(Index)
                        timetig = ListTimeTig[IndexTig]
                        ESX.ShowNotification("~g~Temps choisis " .. ListTimeTig[IndexTig] .. " minutes.")
                    end
                })
                RageUI.Button("Mettre en T.I.G", "Permet de mettre la personne la plus proche en T.I.G et il va devoir ramasser les fruits sur la place des cubes !", {}, true , {
                    onActive = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance ~= -1 and closestDistance <= 3 then
                            PlayerMarker2(closestPlayer)
                        end
                    end,
                    onSelected = function()
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        if closestDistance  ~= -1 and closestDistance  <= 3.0 then
                            if timetig ~= nil then
                                TriggerServerEvent('Police:SendInfoTigs',  GetPlayerServerId(closestPlayer), tonumber(timetig))
                            else
                                ESX.ShowNotification("Vous devez indiquer une durée !")
                            end
                        else
                            ESX.ShowNotification("Personne à proximité.")
                        end
                    end
                })
            end)
    
            if not RageUI.Visible(mainmenupolice) and
            not RageUI.Visible(interactioncitoyenspolice) and 
            not RageUI.Visible(interactionvehiculepolice) and
            not RageUI.Visible(tigmok) and
            not RageUI.Visible(casierjudiciairepolice) and
            not RageUI.Visible(miseenprisonpolice) then 
                mainmenupolice = RMenu:DeleteType('mainmenupolice')
            end
        end
    end,
    openVestiaire = function()
        local menu = RageUI.CreateMenu(ESX.PlayerData.job.label, "Menu ".. ESX.PlayerData.job.label)
        RageUI.Visible(menu, not RageUI.Visible(menu))
    
        while menu do
            Citizen.Wait(0)
            RageUI.IsVisible(menu, function()
                RageUI.Separator("Votre Grade: "..ESX.Config("serverColor")..ESX.PlayerData.job.grade_label)

                RageUI.Checkbox("Prendre votre service", "Vous permet de commencer/arréter votre service", ServicePoliceCheck, {}, {
                    onChecked = function()
                        TriggerServerEvent("Null:servicepolice", true, ESX.PlayerData.job.name)
                        ServicePoliceCheck = true 
                    end,
                    onUnChecked = function()
                        TriggerServerEvent("Null:servicepolice", false, ESX.PlayerData.job.name)
                        ServicePoliceCheck = false 
                    end
                })
    
                RageUI.Line()
                RageUI.Button("Accéder au vestiaire", nil, {}, true, {
                    onSelected = function()
                        RageUI.CloseAll()
                        Wait(1000)
                        OpenVestiaire(ESX.PlayerData.job.name)
                    end
                })
            end)
    
            if not RageUI.Visible(menu) then
                menu = RMenu:DeleteType('menu', true)
            end
        end
    end,
    OpenAmmuNation = function()
        local mainammunationpolice = RageUI.CreateMenu("", "Voici les armes disponibles")
        RageUI.Visible(mainammunationpolice, not RageUI.Visible(mainammunationpolice))
    
        while mainammunationpolice do 
            if NullInventory.isOpen then 
                return
            end
            Wait(0)
    
            RageUI.IsVisible(mainammunationpolice, function()

                if ServicePoliceArme then
                    RageUI.Button("Rendre vos arme de service", nil, {}, true , {
                        onSelected = function() 
                            TriggerServerEvent("null:police:removeservice");
                            ServicePoliceArme = false
                        end
                    })
                else
                    RageUI.Button("Prendre arme de service", nil, {}, true , {
                        onSelected = function() 
                            ServicePoliceArme = true
                            TriggerServerEvent("null:policebuilder:takearmory")
                        end
                    })
                end
            end, function()
            end)
    
            if not RageUI.Visible(mainammunationpolice) then
                mainammunationpolice = RMenu:DeleteType("mainammunationpolice")
            end 
    
        end
    end,
}


RegisterNetEvent("Null:demandederenfort", function(type, coords)
    if type == "petite" then
        PlaySoundFrontend(-1,"Lose_1st", "GTAO_Magnate_Boss_Modes_Soundset", false); 
        local blipId = AddBlipForCoord(coords)
        SetBlipSprite(blipId, 161)
        SetBlipScale(blipId, 0.7)
        SetBlipColour(blipId, 2)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('~g~Demande renfort')
        EndTextCommandSetBlipName(blipId)
        Wait(80 * 1000)
        RemoveBlip(blipId)
    elseif type == 'important' then 
        local blipId = AddBlipForCoord(coords)
        SetBlipSprite(blipId, 161)
        SetBlipScale(blipId, 0.7)
        SetBlipColour(blipId, 47)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('~p~Demande renfort')
        EndTextCommandSetBlipName(blipId)
        Wait(80 * 1000)
        RemoveBlip(blipId)
    elseif type == 'rouge' then 
        PlaySoundFrontend(-1, "police_notification", "DLC_AS_VNT_Sounds", true);
        local blipId = AddBlipForCoord(coords)
        SetBlipSprite(blipId, 161)
        SetBlipScale(blipId, 0.7)
        SetBlipColour(blipId, 1)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString('~r~Demande renfort')
        EndTextCommandSetBlipName(blipId)
        Wait(80 * 1000)
        RemoveBlip(blipId)
    end
end)
    
RegisterNetEvent('esx_policejob:handcuff')
AddEventHandler('esx_policejob:handcuff', function()
	IsHandcuffed    = not IsHandcuffed
	local playerPed = PlayerPedId()

	Citizen.CreateThread(function()
		if IsHandcuffed then
            RageUI.setKeyState(21, true)
            RageUI.setKeyState(22, true)
            TriggerEvent("Null:krz_handcuff:startThread")
			RequestAnimDict('mp_arresting')
			while not HasAnimDictLoaded('mp_arresting') do
				Citizen.Wait(500)
			end
			TaskPlayAnim(playerPed, 'mp_arresting', 'idle', 8.0, -8, -1, 49, 0, 0, 0, 0)
			SetEnableHandcuffs(playerPed, true)
			DisablePlayerFiring(playerPed, true)
			SetPedCanPlayGestureAnims(playerPed, false)
			FreezeEntityPosition(playerPed, false)
			DisplayRadar(false)
		else
			ClearPedSecondaryTask(playerPed)
            ClearPedTasks(playerPed)
			SetEnableHandcuffs(playerPed, false)
			DisablePlayerFiring(playerPed, false)
			SetPedCanPlayGestureAnims(playerPed, true)
			FreezeEntityPosition(playerPed, false)
			DisplayRadar(true)
            RageUI.setKeyState(21, false)
            RageUI.setKeyState(22, false)
            cuffedN = false
		end
	end)
end)

RegisterNetEvent('esx_policejob:unrestrain')
AddEventHandler('esx_policejob:unrestrain', function()
	if IsHandcuffed then
		local playerPed = PlayerPedId()
		IsHandcuffed = false

		ClearPedSecondaryTask(playerPed)
		SetEnableHandcuffs(playerPed, false)
		DisablePlayerFiring(playerPed, false)
		SetPedCanPlayGestureAnims(playerPed, true)
		FreezeEntityPosition(playerPed, false)
		DisplayRadar(true)

        RageUI.setKeyState(21, false)
        RageUI.setKeyState(22, false)
        cuffedN = false
	end
end)



RegisterNetEvent('Null:receivePolice', function(Table)
    for _, v in pairs(Table or {}) do
        null.data.markers.unregister("job_police_vestiaire_"..v.name)
        null.data.markers.unregister("job_police_ammunation_"..v.name)
        null.data.markers.unregister("job_police_boss_"..v.name)
    end
    null.data.jobs.polices.list = Table
    EntrepriseLoad = true
    Wait(1000)
    for k,v in pairs(BlipsPolice) do
        RemoveBlip(v)
    end
    BlipsPolice = {}

    for k,v in pairs(Table) do
        if v.type == 'Police' then
            if BlipsPolice[v.name] == nil then
                BlipsPolice[v.name] = AddBlipForCoord(v.PosBoss.x, v.PosBoss.y, v.PosBoss.z)
                SetBlipSprite(BlipsPolice[v.name], v.sprite)
                SetBlipDisplay(BlipsPolice[v.name], 4)
                SetBlipScale(BlipsPolice[v.name], 0.8)
                SetBlipColour(BlipsPolice[v.name], v.color or 18)
                SetBlipAsShortRange(BlipsPolice[v.name], true)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(v.label)
                EndTextCommandSetBlipName(BlipsPolice[v.name])
                SetBlipCategory(BlipsPolice[v.name], 10)
            end
            
            if not null.data.markers.isRegister("job_police_vestiaire_"..v.name) then
                null.data.markers.register("job_police_vestiaire_"..v.name, {
                    Position = vector3(v.PosVestiaire.x, v.PosVestiaire.y, v.PosVestiaire.z),
                    Public = false,
                    Job = v.name,
                    Job2 = nil,
                    Action = function()
                        PoliceJobs.openVestiaire()
                    end
                })
                null.data.markers.register("job_police_ammunation_"..v.name, {
                    Position = vector3(v.PosArmory.x, v.PosArmory.y, v.PosArmory.z),
                    Public = false,
                    Job = v.name,
                    Job2 = nil,
                    Action = function()
                        PoliceJobs.OpenAmmuNation()
                    end
                })
                null.data.markers.register("job_police_boss_"..v.name, {
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

RegisterNetEvent('Null:deletepoliceblips', function(value)
    for k,v in pairs(BlipsPolice) do
        if k == value then
            RemoveBlip(v)
            break
        end
    end
end)


Citizen.CreateThread(function()
    Wait(2000)
    TriggerServerEvent('Null:initPolice')
end)


RMenu.Add('tig', 'main', RageUI.CreateMenu("", "Actions disponibles", nil, nil, "onestlagrrr", "interaction_bgd"))
RMenu:Get('tig', 'main').Closable = false
local TableFruitS = {}

TableFruit = {
    {
        props = "v_res_tre_banana", -- Banane
        coords = vector3(-337.9838, -1556.324, 25.22934),
        text = "Appuyez sur ~INPUT_PICKUP~ pour ramasser la banane",
        
    },
    {
        props = "v_res_tre_pineapple", -- ananas
        coords = vector3(-339.5727, -1565.624, 25.23189),
        text = "Appuyez sur ~INPUT_PICKUP~ pour ramasser l'ananas",
        
    },
    {
        props = "v_res_tre_pineapple", -- ananas
        coords = vector3(-350.3534, -1566.709, 25.22748),
        text = "Appuyez sur ~INPUT_PICKUP~ pour ramasser l'ananas",
        
    },
    {
        props = "v_res_tre_banana", -- ananas
        coords = vector3(-355.769, -1556.805, 25.16569),
        text = "Appuyez sur ~INPUT_PICKUP~ pour ramasser l'ananas",
        
    },
    {
        props = "v_res_tre_pineapple", -- ananas
        coords = vector3(-347.2171, -1558.114, 25.23049),
        text = "Appuyez sur ~INPUT_PICKUP~ pour ramasser l'ananas",
        
    },
    {
        props = "v_res_tre_banana", -- ananas
        coords = vector3(-342.3019, -1581.248, 25.25584),
        text = "Appuyez sur ~INPUT_PICKUP~ pour ramasser l'ananas",
        
    },
}
RegisterNetEvent("Police:SendSomeoneInTig")
AddEventHandler("Police:SendSomeoneInTig", function(time, author)
	Tiged.time = tonumber(time)
	Tiged.author = author
	RageUI.Visible(RMenu:Get('tig', 'main'), not RageUI.Visible(RMenu:Get('tig', 'main')))
    SetEntityCoords(PlayerPedId(), -345.675, -1562.505, 25.23028, false, false, false, true)
	--[[TriggerEvent('Null:skinchanger:getSkin', function(skin)
		if skin.sex == 0 then
			TriggerEvent('Null:skinchanger:loadClothes', skin, {
				['tshirt_1'] = 15, ['tshirt_2'] = 0,
				['torso_1'] = 179, ['torso_2'] = 0,
				['decals_1'] = 0, ['decals_2'] = 0,
				['arms'] = 0, ['pants_1'] = 248,
				['pants_2'] = 5, ['shoes_1'] = 1,
				['shoes_2'] = 0, ['chain_1'] = 0,
				['chain_2'] = 0
			})
		else
			TriggerEvent('Null:skinchanger:loadClothes', skin, {
				['tshirt_1'] = 15, ['tshirt_2'] = 0,
				['torso_1'] = 179, ['torso_2'] = 0,
				['decals_1'] = 0, ['decals_2'] = 0,
				['arms'] = 0, ['pants_1'] = 248,
				['pants_2'] = 5, ['shoes_1'] = 1,
				['shoes_2'] = 0, ['chain_1'] = 0,
				['chain_2'] = 0
			})
		end
	end)]]
	Citizen.CreateThread(function()
		while true do
			if Tiged.time > 0 then
				Tiged.time = Tiged.time - 1
				TriggerServerEvent("Police:SendTigTime")
            else
				break
			end
			Wait(1000)
		end
	end)
	Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
		while true do
			if tonumber(Tiged.time) > 0 then
                time = TimerBar(Tiged.time)
                ShowInfo(
                    "Informations TIG",  
                    {
                        {left = "Auteur", right = Tiged.author, color = "rgb(255, 255, 255)"},
                        {left = "Temps restant", right = ("%s heures"):format(time[1]..':'..time[2]..':'..time[3]), color = "rgb(255, 255, 255)"},
                    }
                )
				RageUI.IsVisible(RMenu:Get('tig', 'main'), function()
					RageUI.Separator("Vous avez été mis en tig par " .. Tiged.author)
					RageUI.Button('Temps restant', nil, {RightLabel = Tiged.time .. "s"}, true, {})
                    RageUI.Button('Temps déduis / fruit ramené', nil, {RightLabel = "- 30 secondes"}, true, {})
                    RageUI.Separator("")
                    RageUI.Separator("Ramasser les fruits par terre pour la marchande !")
                    RageUI.Separator("Cela vous permettra une libération plus rapide !")
                    RageUI.Separator("")
                    RageUI.Button('Astuces :', nil, {RightLabel = "~s~(~g~E~s~) pour effectuer une action"}, true, {})
				end)
			else
                TriggerEvent("Police:OutofTig", Tiged.time, Tiged.author)
                HideInfo()
                SetEntityCoords(PlayerPedId(),-280.13934326172,-1064.6807861328,25.810646057129)
				break
			end
			if Vdist2(PlayerState.coords, -345.675, -1562.505, 25.23028) > 1090 then
				SetEntityCoords(PlayerPedId(), -345.675, -1562.505, 25.23028, false, false, false, true)
			else
				if IsControlJustPressed(0,245) then
					ESX.ShowNotification("~r~Pas de report en TIG !")
				end
				DisableControlAction(0,245,true)
			end
			Wait(0)
		end
        HideInfo()
	end))
    Isintig = true
    SpawnFruitForTige()
    WorkingLessTimeTig()
end)




function SpawnFruitForTige()
    local random = math.random(1,#TableFruit)
    local countfruit = 0
    for k,v in pairs(TableFruit) do
        countfruit = countfruit + 1
        if countfruit == random and Isintig then
            RequestModel(GetHashKey(v.props))
            while not HasModelLoaded(GetHashKey(v.props)) do
                Wait(1)
            end
            local pos = vector3(v.coords.x,v.coords.y,v.coords.z-0.98)
            fruit_type = CreateObject(GetHashKey(v.props), pos, false, true, true)
            SetEntityAsMissionEntity(fruit_type, true, true)
            ESX.addBlips({
                name = 'tigblip_fruit',
                label = 'Fruit à ramasser',
                entity = fruit_type,
                category = nil,
                position = v.coords,
                sprite = 11,
                display = 4,
                scale = 0.60,
                color = 25
            })
            table.insert(TableFruitS, {id = fruit_type, x = v.coords.x, y = v.coords.y, z = v.coords.z})
        end
    end
end





function WorkingLessTimeTig()
    while Isintig do
        Wait(1)
        for index, value in pairs(TableFruitS)do
            if DoesEntityExist(value.id) then
                local ply = PlayerPedId()
                local coordsply = GetEntityCoords(PlayerPedId())
                local fruitcoords = GetEntityCoords(value.id)
                local dstToMarker = GetDistanceBetweenCoords(coordsply, fruitcoords, true)
                DrawMarker(0, fruitcoords.x, fruitcoords.y, fruitcoords.z+1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.3, 0.3, 0, 255, 0, 170, 0, 0, 2, 1, nil, nil, 0)
                if dstToMarker <= 1.5 and Isintig then
                    ESX.ShowHelpNotification("Appuyez sur ~INPUT_PICKUP~ pour prendre le fruit")
                    if IsControlJustPressed(1, 51) and dstToMarker <= 1.5 then
                        ESX.Streaming.RequestAnimDict('weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', function()
                            TaskPlayAnim(ply, 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor', 8.0, 1.0, 1000, 16, 0.0, false, false, false)
                        end)
                        PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
                        AttachEntityToEntity(value.id,GetPlayerPed(PlayerId()),GetPedBoneIndex(GetPlayerPed(PlayerId()), 28422),-0.005,0.0,0.0,360.0,360.0,0.0,1,1,0,1,0,1)
                        ESX.ShowNotification("~p~T.I.G ~s~: Vous avez ramassé un fruit , veuillez le donner a la marchande !")
                        cansellfruit = true
                        break
                    end
                end
            end
            if cansellfruit then
                local ply2 = PlayerPedId()
                local coords2 = GetEntityCoords(value.id)
                local dstToMarker2 = GetDistanceBetweenCoords(-341.661, -1551.046, 25.22656, coords2, true)
                blip2 = AddBlipForCoord(-341.661, -1551.046, 25.22656)
                SetBlipSprite(blip2, 365)
                SetBlipColour(blip2, 83)
                SetBlipScale(blip2, 0.60)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString('Marchande')
                EndTextCommandSetBlipName(blip2)
                while Isintig and cansellfruit do
                    Wait(1)
                    dstToMarker2 = GetDistanceBetweenCoords(-341.661, -1551.046, 25.22656, propsCoords2, true)
                    propsCoords2 = GetEntityCoords(value.id)
                    DrawMarker(0, propsCoords2.x, propsCoords2.y, propsCoords2.z+2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.2, 0, 255, 0, 170, 0, 0, 2, 1, nil, nil, 0)
                    if dstToMarker2 <= 1.5 and Isintig and cansellfruit then
                        ESX.ShowHelpNotification("Appuyer sur ~INPUT_PICKUP~ pour donner le fruit à la marchande")
                        if IsControlJustPressed(1, 51) and dstToMarker2 <= 1.5 then
                            ESX.Streaming.RequestAnimDict('mp_common', function()
                                TaskPlayAnim(PlayerPedId(), 'mp_common', 'givetake1_a' ,8.0, -8.0, -1, 0, 0, false, false, false )
                            end)
                            PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
                            ESX.removeBlip("tigblip_fruit")
                            table.remove(TableFruitS, index)
                            DeleteEntity(value.id)
                            yamokda = value.id
                            cansellfruit = false
                            Tiged.time = Tiged.time - 30
                            TriggerServerEvent("Police:SendTigTime2", 30)
                            ESX.ShowNotification("Le temps de votre peine a été diminué de 30 secondes , veuillez continuez ainsi pour sortir plus vite")
                            SpawnFruitForTige()
                            break
                        end
                    end
                end
            end
        end
    end
end



RegisterNetEvent("Police:OutofTig")
AddEventHandler("Police:OutofTig", function(time, author)
    Isintig = false
	RageUI.CloseAll()
    cansellfruit = false
    ESX.removeBlip("tigblip_fruit")
    table.remove(TableFruitS, index)
    DeleteEntity(yamokda)
	SetEntityCoords(PlayerPedId(), 236.1626, -864.2734, 29.81388, false, false, false, true)
	ESX.ShowNotification("Vous avez terminé votre peine, faites attention la prochaine fois!")
	Tiged.time = 0
	Tiged.author = nil
end)


Citizen.CreateThread(function()
    local hash = GetHashKey("a_f_y_eastsa_03")   -- Marchande TIG
    while not HasModelLoaded(hash) do
        RequestModel(hash)
        Wait(20)
    end
    while not HasAnimDictLoaded("mini@strip_club@idles@bouncer@base") do
        RequestAnimDict("mini@strip_club@idles@bouncer@base")
        Wait(20)
    end
	ped = CreatePed(4, "a_f_y_eastsa_03", -341.7946, -1550.563, 24.22602, 179.10879516601565, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    TaskPlayAnim(ped,"mini@strip_club@idles@bouncer@base","base", 8.0, 0.0, -1, 1, 0, 0, 0, 0)
end)


RegisterNetEvent('police:OutVehicle')
AddEventHandler('police:OutVehicle', function()
	local plyPed = PlayerPedId()

	if not IsPedSittingInAnyVehicle(plyPed) then
		return
	end

	DetachEntity(plyPed, true, false)
	local vehicle = GetVehiclePedIsIn(plyPed, false)
	TaskLeaveVehicle(plyPed, vehicle, 16)
end)


RegisterNetEvent('police:putInVehicle')
AddEventHandler('police:putInVehicle', function()
	local plyPed = PlayerPedId()
	local coords = GetEntityCoords(plyPed, false)

    if IsAnyVehicleNearPoint(coords, 5.0) then
		local vehicle = GetClosestVehicle(coords, 5.0, 0, 71)

		if DoesEntityExist(vehicle) then
			local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
			local freeSeat = nil

			for i = maxSeats - 1, 0, -1 do
				if IsVehicleSeatFree(vehicle, i) then
					freeSeat = i
					break
				end
			end

			if freeSeat ~= nil then
				DetachEntity(plyPed, true, false)
				TaskWarpPedIntoVehicle(plyPed, vehicle, freeSeat)
			end
		end
	end
end)



RegisterNetEvent('esx_policejob:drag')
AddEventHandler('esx_policejob:drag', function(draggerId)
    DragStatus.isDragged = not DragStatus.isDragged
    DragStatus.dragger = tonumber(draggerId)

    if not DragStatus.isDragged then
        DetachEntity(PlayerPedId(), true, false)
    end
    CreateThreadPoliceDrag()
end)


function CreateThreadPoliceDrag()
    CreateThread(function()
        while DragStatus ~= nil and DragStatus.isDragged do
            Wait(0)
            if DragStatus.isDragged then
                local target = GetPlayerFromServerId(DragStatus.dragger)
                if target ~= PlayerId() and target > 0 then
                    local targetPed = GetPlayerPed(target)
                    if not IsPedSittingInAnyVehicle(targetPed) then
                        AttachEntityToEntity(PlayerState.ped, targetPed, 11816, 0.54, 0.54, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                    else
                        DragStatus.isDragged = false
                        DetachEntity(PlayerState.ped, true, false)
                    end
                else
                    Wait(500)
                end
            else
                Wait(500)
            end
        end
    end)
end
