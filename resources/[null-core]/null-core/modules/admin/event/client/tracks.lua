TrackList = {}
TrackLoad = false
TrackPed = {}
inTrack = false
TrackCanDrift = false
local Zone = nil
local TimerToExit = 7
local OutSideZone = false
local FreezeTrack = true
local RaceStart = false
local Solo = {
    Time = nil,
    TimeonStart = nil,
    checkpoints = {}
}
local PlayerBarIndex = nil
local CheckPointBarIndex = nil
local areFinish = false
trackOwner = false
Citizen.CreateThread(function()
    Wait(2000)
    TriggerServerEvent("null:track:request")
end)

RegisterNetEvent("null:track:load", function(data)
    TrackList = data
    TrackLoad = true
    DeleteTrackPed(function()
        Wait(1000)
        CreateTrackPed()
    end)
end)

RegisterNetEvent("null:track:lobby:setintrack", function(id, lobbyid, data)
    inTrack = true
end)

RegisterNetEvent("null:track:lobby:load", function(id, lobbyid, data)
    TrackList[id].lobby[lobbyid] = data
    if RaceStart == true then
        while TrackList[id].lobby[lobbyid].players[ESX.PlayerData.idunique] == nil do 
            Wait(100)
        end
        while TrackList[id].lobby[lobbyid].players[ESX.PlayerData.idunique].checkpoints == nil do 
            Wait(100)
        end
        while TrackList[id].checkpoint == nil do 
            Wait(100)
        end
        null.fct.draw.UpdateTimerBar(PlayerBarIndex, {text = TrackList[id].lobby[lobbyid].playerInTrack.."/"..TrackList[id].lobby[lobbyid].nbrPlayers})
        null.fct.draw.UpdateTimerBar(CheckPointBarIndex, {text = #TrackList[id].checkpoint - #TrackList[id].lobby[lobbyid].players[ESX.PlayerData.idunique].checkpoints.."/"..#TrackList[id].checkpoint})
    end
end)

RegisterNetEvent("null:track:lobby:leave", function()
   -- PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
    if inTrack then
        inTrack = false
        RaceStart = false
        areFinish = true
        if PlayerState.isInVehicle then
            DeleteEntity(PlayerState.vehicle)
        end
        --exports["Null"]:whileToDestroy("raceAmbiance", 200)
        if Zone then
            Zone:destroy()
        end
        null.fct.draw.RemoveTimerBar()   
        inTrack = false 
    end
end)

RegisterNetEvent("null:track:ply:finish", function()
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
    if PlayerState.isInVehicle then
        DeleteEntity(PlayerState.vehicle)
    end
    inTrack = false
    areFinish = true
    exports["Null"]:whileToDestroy("raceAmbiance", 200)
    Zone:destroy()
    null.fct.draw.RemoveTimerBar()    
    inTrack = false
end)

RegisterNetEvent("null:track:lobby:finish", function(id, lobbyid, data)
    TrackList[id].lobby[lobbyid] = data
    inTrack = false
end)

RegisterNetEvent("null:track:lobby:start", function(id, lobbyid, points, canDrift)
    TrackCanDrift = canDrift
    FreezeTrack = true
    RaceStart = false
    areFinish = false
    inTrack = true
    Citizen.CreateThread(function()
        RageUI.CloseAll()
        DoScreenFadeOut(100)
        Wait(5000)
        DoScreenFadeIn(5500)
    end)
    Zone = PolyZone:Create(points, {
        name = ("race_%s"):format(id),
        data = {
            id = id,
            lobbyid = lobbyid,
        },
        debugGrid = false
    })
    Citizen.CreateThread(function()
        while TrackList[id] == nil do Wait(10) end

        while TrackList[id].lobby[lobbyid].players[ESX.PlayerData.idunique] == nil do 
            Wait(100)
        end
        while TrackList[id].lobby[lobbyid].players[ESX.PlayerData.idunique].checkpoints == nil do 
            Wait(100)
        end
        while TrackList[id].checkpoint == nil do 
            Wait(100)
        end
        if TrackList[id].maxTime == nil then 
            TrackList[id].maxTime = 300000 
        end
        local time = GetGameTimer() + TrackList[id].maxTime + 5000
        PlayerBarIndex = null.fct.draw.AddTimerBar("Joueurs restant :", {text = TrackList[id].lobby[lobbyid].playerInTrack.."/"..TrackList[id].lobby[lobbyid].nbrPlayers})
        CheckPointBarIndex = null.fct.draw.AddTimerBar("Checkpoint restant :", {text = #TrackList[id].checkpoint - #TrackList[id].lobby[lobbyid].players[ESX.PlayerData.idunique].checkpoints.."/"..#TrackList[id].checkpoint})
        null.fct.draw.AddTimerBar("Temps restant :",{endTime=time+5000})
    end)
    Citizen.CreateThread(function()
        local FinishCoords = vector3(TrackList[id].finish.pos.x, TrackList[id].finish.pos.y, TrackList[id].finish.pos.z)
        local allCheckPoint = {}
        for k,v in pairs(TrackList[id].checkpoint) do
            allCheckPoint[k] = vector3(v.pos.x, v.pos.y, v.pos.z)
        end
        while true do
            if not inTrack then
                break
            end
            if TrackList[id].lobby[lobbyid].finish == true then break end
            if areFinish then return end
            if PlayerState.isInVehicle then
                if TrackList[id].onlyFirstPerson then
                    SetFollowVehicleCamViewMode(4)
                end
                local playerCoords = GetEntityCoords(PlayerState.playerPed)
                local distanceFinish = Distance3d(playerCoords, FinishCoords)
                if distanceFinish < 10.0 then
                    local canAction = ActionCooldown("triggerRaceFinish", 1500, false)
                    if canAction then 
                        TriggerServerEvent("null:track:players:race:finish", id, lobbyid)
                    end
                end
                if distanceFinish < 200.0 then
                    local dx = playerCoords.x - FinishCoords.x
                    local dy = playerCoords.y - FinishCoords.y
                    local angle = math.deg(math.atan2(dy, dx))
                    DrawMarker(4, FinishCoords.x, FinishCoords.y, FinishCoords.z+1, 0.0, 0.0, 0.0, 0.0, 0.0, angle-90.0, 5.0, 5.0, 5.0, 0, 255, 0, 255, false, false, 2, false, false, false, false)
                end
                for k,v in pairs(TrackList[id].checkpoint) do
                    local val, groundZ, normal = GetGroundZAndNormalFor_3dCoord(v.pos.x, v.pos.y, v.pos.z + 1)
                    if val then
                        local dx = playerCoords.x - v.pos.x
                        local dy = playerCoords.y - v.pos.y
                        local angle = math.deg(math.atan2(dy, dx))
                        local pitch = math.deg(math.asin(normal.x))
                        local roll = math.deg(math.asin(normal.y))
                        local colors = {255, 255, 255, 105}
                        if TrackList[id].lobby[lobbyid].players[ESX.PlayerData.idunique].checkpoints ~= nil and TrackList[id].lobby[lobbyid].players[ESX.PlayerData.idunique].checkpoints[k] == true then
                            colors = {255, 255, 0, 50}
                        end
                        DrawMarker(42, 
                        v.pos.x, v.pos.y, groundZ + 2, 
                        0.0, 0.0, 0.0, 
                        pitch, roll, angle-90.0, 
                        5.0, 5.0, 5.0, 
                        colors[1],colors[2],colors[3],colors[4] , false, false, 2, false, false, false, false)

                        local distanceCheckPoint = (Distance3d(vector2(playerCoords.x,playerCoords.y), vector2(v.pos.x, v.pos.y)))
                        if distanceCheckPoint <= 10.0 then
                            local canAction = ActionCooldown("triggerCheckPoint", 1500, false)
                            if canAction then
                                TriggerServerEvent("null:track:players:race:pastcheckpawn", id, lobbyid, k)
                            end
                        end
                    end
                end
            end
            Wait(1)
        end
    end)
    Citizen.CreateThread(function()
        while true do
            null.DisplayHud(false)
            DisplayRadar(false)

            if not inTrack then break end
            if TrackList[id].lobby[lobbyid].finish then break end
            if not Zone:isPointInside(GetEntityCoords(PlayerState.playerPed)) and RaceStart then
                OutSideZone = true
                TimerToExit = TimerToExit - 1
                if TimerToExit < 0 then
                    TriggerServerEvent("null:track:players:race:leave", id, lobbyid)
                    break
                end
				DrawMissionText("~r~Vous êtes en dehors de la zone de course ! Vous avez "..TimerToExit.." secondes pour rentrer.", 2000)
            else
                OutSideZone = false
                TimerToExit = 7
			end
            if PlayerState.isInVehicle then
                if FreezeTrack then
                    FreezeEntityPosition(PlayerState.vehicle, true)
                    SetEntityAlpha(PlayerState.vehicle, 230, false)
                else
                    SetVehicleNumberPlateText(PlayerState.vehicle, "RACE")
                    SetVehicleEngineHealth(PlayerState.vehicle, 1000.0)
                    SetVehicleFuelLevel(PlayerState.vehicle, 200.0)
                    SetVehicleEngineOn(PlayerState.vehicle, true, true, false)
                    SetEntityAlpha(PlayerState.vehicle, 255, false)
                    SetVehiclePetrolTankHealth(PlayerState.vehicle, 1000.0)
                end
            end
            Wait(1000)
        end 
        null.DisplayHud(true)
        DisplayRadar(true)
    end)
end)

RegisterNetEvent("null:track:solo:start", function(id, points, canDrift)
    Solo = {
        Time = nil,
        TimeonStart = nil,
        checkpoints = {}
    }
    TrackCanDrift = canDrift
    areFinish = false
    FreezeTrack = true
    RaceStart = false
    inTrack = true
    Citizen.CreateThread(function()
        RageUI.CloseAll()
        DoScreenFadeOut(100)
        Wait(5000)
        DoScreenFadeIn(5500)
    end)
    Zone = PolyZone:Create(points, {
        name = ("race_%s"):format(id),
        data = {
            id = id
        },
        debugGrid = false
    })
    Citizen.CreateThread(function()
        while TrackList[id] == nil do Wait(10) end
        if TrackList[id].maxTime == nil then 
            TrackList[id].maxTime = 300000 
        end
        Solo.Time = GetGameTimer() + TrackList[id].maxTime + 17000
        Solo.TimeonStart = GetGameTimer() + 17000
        CheckPointBarIndex = null.fct.draw.AddTimerBar("Checkpoint restant :", {text = #TrackList[id].checkpoint - #Solo.checkpoints.."/"..#TrackList[id].checkpoint})
        null.fct.draw.AddTimerBar("Temps restant :",{endTime=Solo.Time})
    end)
    Citizen.CreateThread(function()
        local FinishCoords = vector3(TrackList[id].finish.pos.x, TrackList[id].finish.pos.y, TrackList[id].finish.pos.z)
        local allCheckPoint = {}
        for k,v in pairs(TrackList[id].checkpoint) do
            allCheckPoint[k] = vector3(v.pos.x, v.pos.y, v.pos.z)
        end
        while true do
            if not inTrack then
                break
            end
            if areFinish then return end
            if PlayerState.isInVehicle then
                if TrackList[id].onlyFirstPerson then
                    SetFollowVehicleCamViewMode(4)
                end
                local playerCoords = GetEntityCoords(PlayerState.playerPed)
                local distanceFinish = Distance3d(playerCoords, FinishCoords)
                if distanceFinish < 10.0 then
                    local canAction = ActionCooldown("triggerRaceFinish", 2000, false)
                    if canAction then 
                        if #TrackList[id].checkpoint - #Solo.checkpoints == 0 then 
                            TriggerServerEvent("null:track:solo:finish", id, GetGameTimer(), Solo.TimeonStart)
                            break
                        end
                    end
                end
                if distanceFinish < 200.0 then
                    local dx = playerCoords.x - FinishCoords.x
                    local dy = playerCoords.y - FinishCoords.y
                    local angle = math.deg(math.atan2(dy, dx))
                    DrawMarker(4, 
                    FinishCoords.x, FinishCoords.y, FinishCoords.z+1, 
                    0.0, 0.0, 0.0, 
                    0.0, 0.0, angle-90.0, 5.0, 5.0, 5.0, 0, 255, 0, 255, false, false, 2, false, false, false, false)
                end
                for k,v in pairs(TrackList[id].checkpoint) do
                    local val, groundZ, normal = GetGroundZAndNormalFor_3dCoord(v.pos.x, v.pos.y, v.pos.z + 1)
                    if val then
                        local dx = playerCoords.x - v.pos.x
                        local dy = playerCoords.y - v.pos.y
                        local angle = math.deg(math.atan2(dy, dx))
                        local pitch = math.deg(math.asin(normal.x))
                        local roll = math.deg(math.asin(normal.y))
                        local colors = {255, 255, 255, 105}
                        if Solo.checkpoints ~= nil and Solo.checkpoints[k] == true then
                            colors = {255, 255, 0, 50}
                        end
                        DrawMarker(42, 
                        v.pos.x, v.pos.y, groundZ + 2, 
                        0.0, 0.0, 0.0, 
                        pitch, roll, angle-90.0, 
                        5.0, 5.0, 5.0, 
                        colors[1],colors[2],colors[3],colors[4] , false, false, 2, false, false, false, false)

                        local distanceCheckPoint = (Distance3d(vector2(playerCoords.x,playerCoords.y), vector2(v.pos.x, v.pos.y)))
                        if distanceCheckPoint <= 10.0 then
                            local canAction = ActionCooldown("triggerCheckPoint", 500, false)
                            if canAction and Solo.checkpoints[k] ~= true then
                                if Solo.checkpoints[k-1] == true then 
                                    Solo.checkpoints[k] = true
                                    null.fct.draw.UpdateTimerBar(CheckPointBarIndex, {text = #TrackList[id].checkpoint - #Solo.checkpoints.."/"..#TrackList[id].checkpoint})
                                elseif k == 1 then
                                    Solo.checkpoints[k] = true
                                    null.fct.draw.UpdateTimerBar(CheckPointBarIndex, {text = #TrackList[id].checkpoint - #Solo.checkpoints.."/"..#TrackList[id].checkpoint})
                                end
                            end
                        end
                    end
                end
            end
            Wait(1)
        end
    end)
    Citizen.CreateThread(function()
        while true do
            null.DisplayHud(false)
            DisplayRadar(false)

            if not inTrack then break end
            if not Zone:isPointInside(GetEntityCoords(PlayerState.playerPed)) and RaceStart then
                OutSideZone = true
                TimerToExit = TimerToExit - 1
                if TimerToExit < 0 then
                    TriggerServerEvent("null:track:solo:leave", id)
                    break
                end
				DrawMissionText("~r~Vous êtes en dehors de la zone de course ! Vous avez "..TimerToExit.." secondes pour rentrer.", 2000)
            else
                OutSideZone = false
                TimerToExit = 7
			end
            if PlayerState.isInVehicle then
                if FreezeTrack then
                    FreezeEntityPosition(PlayerState.vehicle, true)
                    SetEntityAlpha(PlayerState.vehicle, 230, false)
                else
                    SetVehicleNumberPlateText(PlayerState.vehicle, "RACE")
                    SetVehicleEngineHealth(PlayerState.vehicle, 1000.0)
                    SetVehicleFuelLevel(PlayerState.vehicle, 200.0)
                    SetVehicleEngineOn(PlayerState.vehicle, true, true, false)
                    SetEntityAlpha(PlayerState.vehicle, 255, false)
                    SetVehiclePetrolTankHealth(PlayerState.vehicle, 1000.0)
                end
            end
            Wait(1000)
        end 
        null.DisplayHud(true)
        DisplayRadar(true)
    end)
end)

RegisterNetEvent("null:race:start", function(id, lobbyid, points)
    Citizen.CreateThread(function()
        ExecuteCommand("clearchat")
        --exports["Null"]:PlayUrl("raceAmbiance", "https://www.youtube.com/watch?v=J4t4pMZBXZg", 0.2, true)

        PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 1)
        Wait(200)
        ShowCenteredAnnouncement("5", nil, 1300, {255,255,0,255})
        Wait(1300)
        PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 1)
        Wait(200)
        ShowCenteredAnnouncement("4", nil, 1300, {255,255,0,255})
        Wait(1300)
        PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 1)
        Wait(200)
        ShowCenteredAnnouncement("3", nil, 1300, {255,255,0,255})
        Wait(1300)
        PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 1)
        Wait(200)
        ShowCenteredAnnouncement("2", nil, 1300, {255,255,0,255})
        Wait(1300)
        PlaySoundFrontend(-1, "Event_Start_Text", "GTAO_FM_Events_Soundset", 1)
        Wait(200)
        ShowCenteredAnnouncement("1", nil, 1300, {255,255,0,255})
        Wait(1300)
        PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
        ShowCenteredAnnouncement("GOO", nil, 1300, {255,255,0,255})
        RaceStart = true
        FreezeTrack = false
        FreezeEntityPosition(PlayerState.vehicle, false)
    end)
end)

function DeleteTrackPed(cb)
    for k,v in pairs(TrackPed) do 
        if v and DoesEntityExist(v) then 
            DeleteEntity(v) 
        end 
    end
    if cb then cb() end
end

function CreateTrackPed()
    Wait(1000)
    while not TrackLoad do Wait(100) end
    for k,v in pairs(TrackList) do
        if v.pedPosition then
            local hash = GetHashKey("g_m_m_armgoon_01")
            while not HasModelLoaded(hash) do RequestModel(hash) Wait(20) end
            local id = #TrackPed+1
            TrackPed[id] = {
                ped = CreatePed("PED_TYPE_CIVMALE", "g_m_m_armgoon_01", v.pedPosition.pos.x, v.pedPosition.pos.y, v.pedPosition.pos.z-1, v.pedPosition.heading, false, true),
                name = "Course "..v.label
            }
            SetBlockingOfNonTemporaryEvents(TrackPed[id].ped, true)
            FreezeEntityPosition(TrackPed[id].ped, true)
            SetEntityInvincible(TrackPed[id].ped, true)
            ZonesListe["race_"..v.name] = {
                Position = vector3(v.pedPosition.pos.x, v.pedPosition.pos.y, v.pedPosition.pos.z),
                Public = true,
                Job = nil,
                Job2 = nil,
                Action = function()
                    OpenRaceMenu(v.id)
                end
            }
            ESX.addBlips({
                name = "race_"..v.name,
                label = "Course: "..v.label,
                category = nil,
                position = vector3(v.pedPosition.pos.x, v.pedPosition.pos.y, v.pedPosition.pos.z),
                sprite = 38,
                display = 4,
                scale = 0.75,
                color = 4,
            })
        end
    end
end

function OpenRaceMenu(id)
    
    local Classement = {}
	local main = RageUI.CreateMenu("", "")
    local createLobby = RageUI.CreateSubMenu(main, "", "Créer un Event Brinks")
    local Classements = RageUI.CreateSubMenu(main, "", "Créer un Event Brinks")
    local rules = RageUI.CreateSubMenu(main, "", "Créer un Event Brinks")
    local openLobby = RageUI.CreateSubMenu(main, "", "Créer un Event Brinks")
	RageUI.Visible(main, not RageUI.Visible(main))
	while main do
		Citizen.Wait(0)
			RageUI.IsVisible(main, function()
                if TrackList[id].type == "players" then
                    RageUI.Info("Information", {
                        "Nom :",
                        "Joueurs Maximum :",
                        "Joueurs Minimum :",
                        "Prix :",
                    }, {
                        ESX.Config("serverColor")..TrackList[id].label.." ("..TrackList[id].name.." - id: "..TrackList[id].id..")",
                        ESX.Config("serverColor")..TrackList[id].minPlayers,
                        ESX.Config("serverColor")..TrackList[id].maxPlayers,
                        ESX.Config("serverColor")..TrackList[id].mise.."$",
                    })
                    RageUI.Button("A savoir", nil, {}, true, {
                        onSelected = function()
                        end
                    }, rules)
                    if not inTrack then
                        RageUI.Button("Créer un salon", nil, {}, true, {
                            onSelected = function()
                            end
                        }, createLobby)
                    else
                        RageUI.Button("Créer un salon", "~r~Vous êtes déja dans un salon.", {}, false, {
                            onSelected = function()
                            end
                        })
                    end
                    RageUI.Line()
                    for k,v in pairs(TrackList[id].lobby) do 
                        local label = "Salon #"..v.id.." ("..v.nbrPlayers.." Joueurs)"
                        trackOwner = false
                        if v.players[ESX.PlayerData.idunique] ~= nil and v.players[ESX.PlayerData.idunique].owner == true then
                            label = "Null Salon #"..v.id.." ("..v.nbrPlayers.."/"..TrackList[id].maxPlayers.." Joueurs)"
                            trackOwner = true
                            inTrack = true
                        end
                        if (not v.start and v.nbrPlayers < TrackList[id].maxPlayers) or trackOwner then
                            RageUI.Button(label, nil, {RightLabel = trackOwner == false and "Rejoindre" or "Gérer"}, true, {
                                onSelected = function()
                                    if v.nbrPlayers >= TrackList[id].maxPlayers and not trackOwner then 
                                        return 
                                    end
                                    if not trackOwner then
                                        DoScreenFadeOut(1500)
                                        TriggerServerEvent("null:track:players:join", id, v.id)
                                        Wait(1500)
                                        DoScreenFadeIn(500)
                                    end
                                    
                                    selectedLobby = v
                                    selectedLobbyId = v.id
                                    
                                    RageUI.Visible(main, false)
                                    RageUI.Visible(openLobby, true)
                                end
                            })
                        else
                            RageUI.Button(label, nil, {RightLabel = trackOwner == false and "" or "Gérer"}, false, {
                                onSelected = function()
                                end
                            })
                        end
                    end
                elseif TrackList[id].type == "timer" then
                    RageUI.Button("Commencer la course", nil, {}, true, {
                        onSelected = function()
                            TriggerServerEvent("null:track:startrace", id)
                            DoScreenFadeOut(100)
                            RageUI.CloseAll()
                            Wait(5000)
                            DoScreenFadeIn(5500)
                        end
                    })
                    RageUI.Button("Classement", nil, {}, true, {
                        onSelected = function()
                            ESX.TriggerServerCallback("null:track:getClassementFromTrack", function(data) 
                                Classement = data or {}
                                table.sort(Classement, function(a, b)
                                    return a.timer < b.timer
                                end)
                            end, id)
                        end
                    }, Classements)
                end
			end)
            RageUI.IsVisible(Classements, function()
                for k,v in ipairs(Classement) do
                    if k == 1 then
                        RageUI.Button(v.name.." - "..v.timer2, nil, {RightLabel = "TOP 1"}, true, {
                            onActive = function()
                                
                            end
                        })
                    elseif k == 2 then
                        RageUI.Button(v.name.." - "..v.timer2, nil, {RightLabel = "TOP 2"}, true, {
                            onActive = function()
                                
                            end
                        })
                    elseif k == 3 then
                        RageUI.Button(v.name.." - "..v.timer2, nil, {RightLabel = "TOP 3"}, true, {
                            onActive = function()
                                
                            end
                        })
                    else
                        RageUI.Button(v.name.." - "..v.timer2, nil, {RightLabel = nil}, true, {
                            onActive = function()
                                
                            end
                        })
                    end
                end
            end)
            RageUI.IsVisible(openLobby, function()
                if trackOwner then
                    while TrackList[id].lobby[selectedLobbyId] == nil do Wait(1) end
                    local top1 = ESX.Math.GroupDigits(math.floor(TrackList[id].mise*0.6)*TrackList[id].lobby[selectedLobbyId].nbrPlayers)
                    local top2 = ESX.Math.GroupDigits(math.floor(TrackList[id].mise*0.3)*TrackList[id].lobby[selectedLobbyId].nbrPlayers)
                    local top3 = ESX.Math.GroupDigits(math.floor(TrackList[id].mise*0.1)*TrackList[id].lobby[selectedLobbyId].nbrPlayers)
                    RageUI.Button("Information", nil, {RightLabel = ESX.Config("serverColor").."Voir"}, true, {
                        onActive = function()
                            RageUI.Info("Information sur votre Course", {
                                "Nombre de joueurs minimum :",
                                "Nombre de joueurs :",
                                "Argent mis en jeu :",
                                "",
                                "Top 1 : ",
                                "Top 2 : ",
                                "Top 3 : ",
                            }, {
                                ESX.Config("serverColor")..TrackList[id].minPlayers,
                                ESX.Config("serverColor")..TrackList[id].lobby[selectedLobbyId].nbrPlayers.."/"..TrackList[id].maxPlayers,
                                "~y~"..TrackList[id].lobby[selectedLobbyId].nbrPlayers * TrackList[id].mise.."$",
                                "",
                                ESX.Config("serverColor")..top1.."$",
                                ESX.Config("serverColor")..top2.."$",
                                ESX.Config("serverColor")..top3.."$",
                            })
                        end
                    })
                    RageUI.Line()
                    for k,v in pairs(TrackList[id].lobby[selectedLobbyId].players) do
                        if v.idunique ~= ESX.PlayerData.idunique then
                            RageUI.Button(v.name.." (U"..v.idunique..")", "[ENTRER] Pour exclure le joueur", {}, true, {
                                onSelected = function()
                                    TriggerServerEvent("null:track:kick", id, TrackList[id].lobby[selectedLobbyId].id, v.idunique)
                                    TrackList[id].lobby[selectedLobbyId].players[K] = nil
                                end
                            })
                        else
                            RageUI.Button(v.name.." (U"..v.idunique..")", nil, {}, true, {}) 
                        end
                    end
                    RageUI.Line()
                    RageUI.Button("Annuler la course", nil, {Color = {BackgroundColor = {255, 0, 0, 100}}}, true, {
                        onSelected = function()
                            RageUI.CloseAll()
                            TriggerServerEvent("null:track:players:closelobby", id, TrackList[id].lobby[selectedLobbyId].id )
                        end
                    })
                    if TrackList[id].lobby[selectedLobbyId].nbrPlayers > TrackList[id].maxPlayers then
                        RageUI.Button("Lancer la course", "~r~Trop de joueur, veuillez excluse les joueurs en trop.", {}, false, {
                            onSelected = function()
                                
                            end
                        })
                    elseif TrackList[id].lobby[selectedLobbyId].nbrPlayers < TrackList[id].minPlayers then
                        RageUI.Button("Lancer la course", "~r~Nombre de joueur insuffisant.", {}, false, {
                            onSelected = function()
                                    
                            end
                        })
                    else
                        RageUI.Button("Lancer la course", "Vous et les autres joueurs seront débiter de "..TrackList[id].mise.."$.", {Color = {BackgroundColor = {0, 200, 0, 100}}}, true, {
                            onSelected = function()
                                RageUI.CloseAll()
                                TriggerServerEvent("null:track:players:start", id,TrackList[id].lobby[selectedLobbyId].id )
                            end
                        })
                    end
                else
                    RageUI.Separator("Veuillez attendre que le chef lance la course..")
                    RageUI.Button("Quitter la course", nil, {}, true, {
                        onSelected = function()
                            RageUI.CloseAll()
                            TriggerServerEvent("null:track:players:leave", id, TrackList[id].lobby[selectedLobbyId].id)
                        end
                    })
                end
            end)
            RageUI.IsVisible(createLobby, function()
                RageUI.Separator("Vous serez débiter de "..TrackList[id].mise.."$ au lancement.")
                RageUI.Button("Confirmer", nil, {}, true, {
                    onSelected = function()
                        TriggerServerEvent("null:track:startrace", id)
                        RageUI.GoBack()
                    end
                })
            end)
            RageUI.IsVisible(rules, function()
                local top1 = ESX.Math.GroupDigits(math.floor(TrackList[id].mise*0.6)*TrackList[id].minPlayers).." et "..ESX.Math.GroupDigits(math.floor(TrackList[id].mise*0.6)*TrackList[id].maxPlayers)
                local top2 = ESX.Math.GroupDigits(math.floor(TrackList[id].mise*0.3)*TrackList[id].minPlayers).." et "..ESX.Math.GroupDigits(math.floor(TrackList[id].mise*0.3)*TrackList[id].maxPlayers)
                local top3 = ESX.Math.GroupDigits(math.floor(TrackList[id].mise*0.1)*TrackList[id].minPlayers).." et "..ESX.Math.GroupDigits(math.floor(TrackList[id].mise*0.1)*TrackList[id].maxPlayers)
                RageUI.Button("Fonctionnement", nil, {RightLabel = ESX.Config("serverColor").."Voir"}, true, {
                    onActive = function()
                        RageUI.Info("Fonctionnnement", {"La course consiste à passer par des points de contrôle", "et à atteindre la ligne d'arrivée en premier."}, {"",""})
                    end
                })
                RageUI.Button("Récompenses", nil, {RightLabel = ESX.Config("serverColor").."Voir"}, true, {
                    onActive = function()
                        RageUI.Info("Récompenses", {"Le vainqueur remporte entre", "Le deuxième remporte entre", "Le troisième remporte entre"}, {"~y~"..top1.."$~s~","~g~"..top2.."$~s~", "~b~"..top3.."$~s~"})
                    end
                })
                RageUI.Button("Prix d'inscription", nil, {RightLabel = ESX.Config("serverColor")..ESX.Math.GroupDigits(TrackList[id].mise).."$"}, true, {
                    onActive = function()
                        RageUI.Info("Prix", {"Le prix d'inscription est de ~y~"..ESX.Math.GroupDigits(TrackList[id].mise).."$~s~"}, {""})
                    end
                })
                RageUI.Button("Règles", nil, {RightLabel = ESX.Config("serverColor").."Voir"}, true, {
                    onActive = function()
                        local Collision = TrackList[id].enableCollision == true and "~g~Activer" or "~r~Désactiver"
                        local Drift = TrackList[id].giveDrift == true and "~g~Activer" or "~r~Désactiver"
                        local onlyFirstPerson = TrackList[id].onlyFirstPerson == true and "~g~Activer" or "~r~Désactiver"
                        local timer = TrackList[id].maxTime/60000
                        RageUI.Info("Règles", {"Les collisions des véhicules sont", "Le mode drift est", "Premiere personne uniquement est", "Temps maximum"}, {Collision, Drift, onlyFirstPerson, timer.." Min"})
                    end
                })
            end)
		if not RageUI.Visible(main) and not RageUI.Visible(createLobby) and not RageUI.Visible(Classements) and not RageUI.Visible(rules) and not RageUI.Visible(openLobby) then
			main = RMenu:DeleteType('main', true)
		end
	end
end

local gamerTags = {}
Citizen.CreateThread(function()
    while true do
        local plyPed = PlayerPedId()
        for k,v in pairs(TrackPed) do
            if #(GetEntityCoords(plyPed, false) - GetEntityCoords(v.ped, false)) < 5.0 then
                gamerTags[v.ped] = CreateFakeMpGamerTag(v.ped, v.name, false, false, "", 0)
                SetMpGamerTagAlpha(gamerTags[v.ped], 0, 255)
                SetMpGamerTagAlpha(gamerTags[v.ped], 14, 255)
                SetMpGamerTagVisibility(gamerTags[v.ped], 0, true)
                SetMpGamerTagVisibility(gamerTags[v.ped], 14, true)
            else
                RemoveMpGamerTag(gamerTags[v.ped])
                gamerTags[v.ped] = nil
            end
        end
        Citizen.Wait(25)
    end
    for k,v in pairs(gamerTags) do
        RemoveMpGamerTag(v)
    end
    gamerTags = {}
end)