
Citizen.CreateThread(function()
    Wait(2500)
    TriggerServerEvent("Fleeca:getFleeca")
end)

RegisterNetEvent("Fleeca:getFleeca", function(data)
    Fleeca.posFleeca = data
end)

Citizen.CreateThread(function()
    Wait(3000)
    while true do
        for k,v in pairs(Fleeca.posFleeca) do
            if v.otherDoors and #v.otherDoors > 0 then
                for k2, v2 in pairs(v.otherDoors) do 
                    if v2.doorprops and v2.doorprops.finalSelect and not Fleeca.doorOpen then
                        local doorpos = null.fct.JsonCoordsToVect3(v2.doorprops.pos)
                        local getObjdoor = ESX.Game.GetClosestObject(v2.doorprops.finalSelect, doorpos)
                        if getObjdoor and DoesEntityExist(getObjdoor) and not Fleeca.doorOpen then
                            FreezeEntityPosition(getObjdoor, true)
                        end
                    end
                end
            end
        end
        Wait(10000)
    end
end)

local ValidDrills = {}
local MyFleecaId = nil

function Fleeca:SetScaleformParams(scaleform, data)
	data = data or {}
	for k,v in pairs(data) do
		PushScaleformMovieFunction(scaleform, v.name)
		if v.param then
			for _,par in pairs(v.param) do
				if math.type(par) == "integer" then
					PushScaleformMovieFunctionParameterInt(par)
				elseif type(par) == "boolean" then
					PushScaleformMovieFunctionParameterBool(par)
				elseif math.type(par) == "float" then
					PushScaleformMovieFunctionParameterFloat(par)
				elseif type(par) == "string" then
					PushScaleformMovieFunctionParameterString(par)
				end
			end
		end
		if v.func then v.func() end
		PopScaleformMovieFunctionVoid()
	end
end

function Fleeca:DrawTopNotification(txt, beep)
	SetTextComponentFormat("jamyfafi")
	AddTextComponentString(txt)
	if string.len(txt) > 99 and AddLongString then
		AddLongString(txt)
	end
	DisplayHelpTextFromStringLabel(0, 0, beep, -1)
end

function Fleeca:TaskSynchronizedTasks(ped, animData, clearTasks)
	for _,v in pairs(animData) do
		if not HasAnimDictLoaded(v.anim[1]) then
			RequestAnimDict(v.anim[1])
			while not HasAnimDictLoaded(v.anim[1]) do Citizen.Wait(0) end
		end
	end

	local _, sequence = OpenSequenceTask(0)
	for _,v in pairs(animData) do
		TaskPlayAnim(0, v.anim[1], v.anim[2], 2.0, -2.0, math.floor(v.time or -1), v.flag or 48, 0, 0, 0, 0)
	end

	CloseSequenceTask(sequence)
	if clearTasks then ClearPedTasks(ped) end
	TaskPerformSequence(ped, sequence)
	ClearSequenceTask(sequence)

	for _,v in pairs(animData) do
		RemoveAnimDict(v.anim[1])
	end

	return sequence
end

function Fleeca:CreateScaleform(name, data)
	if not name or string.len(name) <= 0 then return end
	local scaleform = RequestScaleformMovie(name)

	while not HasScaleformMovieLoaded(scaleform) do
		Citizen.Wait(0)
	end

	Fleeca:SetScaleformParams(scaleform, data)
	return scaleform
end

function Fleeca:RequestAndWaitDict(dictName)
	if dictName and DoesAnimDictExist(dictName) and not HasAnimDictLoaded(dictName) then
		RequestAnimDict(dictName)
		while not HasAnimDictLoaded(dictName) do 
            Citizen.Wait(100) 
        end
	end
end

function Fleeca:RequestAndWaitModel(modelName)
	if modelName and IsModelInCdimage(modelName) and not HasModelLoaded(modelName) then
		RequestModel(modelName)
		while not HasModelLoaded(modelName) do
            Citizen.Wait(100) 
        end
	end
end

function Fleeca:PlayerHasBag()
    return GetPedDrawableVariation(PlayerPedId(), 5) ~= 0 
end


function StartFleecaThread()
    if MyFleecaId == nil then return end
    RequestScriptAudioBank([[DLC_MPHEIST\HEIST_FLEECA_DRILL]], false)
    RequestScriptAudioBank([[DLC_MPHEIST\HEIST_FLEECA_DRILL_2]], false)
    RequestScriptAudioBank("Vault_Door", false)
    StartClientBankHeist(Fleeca.nFleeca)
    Fleeca.moove = 1
    Fleeca.doorOpen = false
    Fleeca.vaultOpen = false
    Citizen.CreateThread(function()
        local Scal1 = 0.0
        local Scal2 = 0.0
        local Scal3 = 0.0
        local Scal4 = 0.0
        local RaterScal = false
        local SoundScal = false
        local SoundId = 1.0
        local currentDrillId = nil
        while Fleeca.nFleeca ~= 0 do
            Citizen.Wait(0)
            local TempId = Fleeca.nFleeca.id
            local FleecaIds = Fleeca.posFleeca[TempId]
            local pedPDpos = GetEntityCoords(PlayerPedId())
            if IsEntityDead(PlayerPedId()) or not FleecaIds or GetDistanceBetweenCoords(pedPDpos, null.fct.JsonCoordsToVect3(FleecaIds.hackPos.pos)) > 30 then
                Fleeca:AnimStartFin(2)
                return
            end
            print("type : "..Fleeca.nFleeca.fleecatype)
            if Fleeca.nFleeca.fleecatype == 1 then
                if Fleeca.moove == 1 then
                    local nbrDrill = 0
                    for k,v in pairs(FleecaIds.drills) do
                        if ValidDrills[TempId] == nil or ValidDrills[TempId][k] == nil or ValidDrills[TempId][k] ~= false then
                            nbrDrill = nbrDrill + 1
                            local coords = null.fct.JsonCoordsToVect3(v.pos)
                            DrawMarker(25, coords.x, coords.y, coords.z-0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 255, false, false, 2, false, false, false, false)
                            local disTance = GetDistanceBetweenCoords(pedPDpos, coords)
                            if disTance < 0.9 then
                                Fleeca:DrawTopNotification("Appuyez sur "..ESX.Config("serverColor").."E~s~ pour percer ce casier.")
                                
                                if IsControlJustReleased(0, 51) then
                                    SetEntityHeading(PlayerPedId(), v.heading)
                                    local newcoords = GetOffsetFromCoordAndHeadingInWorldCoords(coords.x, coords.y, coords.z-0.98, v.heading, 0.08, -0.47, 0.0)  
                                    SetEntityCoords(PlayerPedId(), newcoords)
                                    currentDrillId = k
                                    Fleeca:StartScalform(k, TempId)
                                end
                            end
                        end
                    end
                    if nbrDrill == 0 and ValidDrills[TempId] ~= nil then
                        Fleeca.moove = 3
                        Fleeca:AnimStartFin()
                        break
                    end
                    if drillSoundID then
                        SetVariableOnSound(drillSoundID, "DrillState", 0.0)
                    end
                elseif Fleeca.moove == 2 and Fleeca.ScalformMoov and HasScaleformMovieLoaded(Fleeca.ScalformMoov) then
                    DrawScaleformMovieFullscreen(Fleeca.ScalformMoov, 255, 255, 255, 255)
                    DrawScaleformMovieFullscreen(helpScaleform, 255, 255, 255, 255)
                    HideHudAndRadarThisFrame()
                    DisableControlAction(0, 24, true)
                    DisableControlAction(0, 25, true)
                    local Press237, Press238 = IsControlPressed(0, 237), IsControlPressed(0, 238)
                    local StartSca = false
                    if Press237 and ((Scal4 >= 0.225 and Scal4 <= 0.325 and Scal1 <= 0.325) or (Scal4 >= 0.35 and Scal4 <= 0.45 and Scal1 <= 0.45) or (Scal4 >= 0.5 and Scal4 <= 0.6 and Scal1 <= 0.6) or (Scal4 >= 0.625 and Scal4 <= 0.725 and Scal1 <= 0.725)) then
                        StartSca = true;
                        if SoundId ~= 0.5 then
                            SoundId = 0.5
                            SetVariableOnSound(drillSoundID, "DrillState", 0.5)
                        end
                    end
                    if not StartSca and SoundId == 0.5 then
                        SoundId = 0.0
                        SetVariableOnSound(drillSoundID, "DrillState", 0.0)
                    end
                    if IsControlJustPressed(0, 51) and not RaterScal then
                        SoundScal = not SoundScal;
                        Fleeca:stopsoundandparticle(SoundScal)
                    end
                    if SoundScal and Scal2 < 0.5 then
                        Scal2 = math.max(0, math.min(0.5, Scal2 + 0.005))
                    elseif not SoundScal and Scal2 > 0.0 then
                        Scal2 = math.max(0, math.min(0.5, Scal2 - 0.005))
                    end
                    if not RaterScal and Press237 and SoundScal then
                        Scal4 = math.max(0, math.min(1.0, Scal4 + 0.001 * (StartSca and 0.5 or 1.0)))
                        if Scal4 > Scal1 then
                            Scal1 = math.max(0, math.min(1.0, Scal1 + 0.001))
                        end
                        if Scal1 > 0.1 and Scal1 - Scal4 <= 0.01 then
                            Scal3 = math.max(0, math.min(1.0, Scal3 + (StartSca and 0.005 or 0.002)))
                        end
                    end
                    if not RaterScal and Press238 and SoundScal then
                        Scal4 = math.max(0, math.min(1.0, Scal4 - 0.0025))
                    end
                    if not Press238 and not Press237 and Scal3 > 0.0 then
                        Scal3 = math.max(0, math.min(1.0, Scal3 - 0.0015))
                    end
                    if Scal3 > 0.7 and not RaterScal then
                        RaterScal = true
                        PlaySoundFrontend(-1, "Drill_Pin_Break", "DLC_HEIST_FLEECA_SOUNDSET", true)
                        SoundScal = false
                        Fleeca:stopsoundandparticle(false)
                    elseif RaterScal then
                        if Scal3 < 0.1 then
                            RaterScal = false
                        end
                        Scal2 = 0.0
                        Scal4 = math.max(0, math.min(1.0, Scal4 - 0.0075))
                    end
                    if Scal1 >= 0.96 then
                        PlaySoundFromEntity(-1, "Drill_Jam", PlayerPedId(), "DLC_HEIST_FLEECA_SOUNDSET", 1, 20)
                        SetScaleformMovieAsNoLongerNeeded(Fleeca.ScalformMoov)
                        Fleeca.ScalformMoov = nil
                        DeleteEntity(Fleeca.ObjectDrill)
                        Fleeca.ObjectDrill = nil
                        FreezeEntityPosition(PlayerPedId(), false)
                        ClearPedTasks(PlayerPedId())
                        Scal1 = 0.0
                        Scal2 = 0.0
                        Scal3 = 0.0
                        Scal4 = 0.0
                        RaterScal = false
                        SoundScal = false
                        SoundId = 1.0
                        Fleeca:stopsoundandparticle(false)
                        TriggerServerEvent("null:fleeca:heistDrill", TempId, currentDrillId)
                        Fleeca.moove = 1
                    end
                    CallScaleformMovieFunctionFloatParams(Fleeca.ScalformMoov, "SET_SPEED", Scal2 * (StartSca and 0.5 or 1.0), -1082130432,-1082130432, -1082130432, -1082130432)
                    CallScaleformMovieFunctionFloatParams(Fleeca.ScalformMoov, "SET_HOLE_DEPTH", Scal1, -1082130432, -1082130432,-1082130432, -1082130432)
                    CallScaleformMovieFunctionFloatParams(Fleeca.ScalformMoov, "SET_DRILL_POSITION", Scal4, -1082130432, -1082130432,-1082130432, -1082130432)
                    CallScaleformMovieFunctionFloatParams(Fleeca.ScalformMoov, "SET_TEMPERATURE", Scal3, -1082130432, -1082130432,-1082130432, -1082130432)
                end
            else
                print("move: "..Fleeca.moove, Fleeca.ScalformMoov ~= nil, HasScaleformMovieLoaded(Fleeca.ScalformMoov), currentDrillId)
                if Fleeca.moove == 1 and Fleeca.vaultOpen == true and Fleeca.doorOpen then
                    local nbrDrill = 0
                    for k,v in pairs(FleecaIds.drills) do
                        if ValidDrills[TempId] == nil or ValidDrills[TempId][k] == nil or ValidDrills[TempId][k] ~= false then
                            nbrDrill = nbrDrill + 1
                            local coords = null.fct.JsonCoordsToVect3(v.pos)
                            DrawMarker(25, coords.x, coords.y, coords.z-0.98, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.55, 0.55, 0.55, tonumber(ESX.Config("r")), tonumber(ESX.Config("g")), tonumber(ESX.Config("b")), 255, false, false, 2, false, false, false, false)
                            local disTance = GetDistanceBetweenCoords(pedPDpos, coords)
                            if disTance < 0.9 then
                                Fleeca:DrawTopNotification("Appuyez sur "..ESX.Config("serverColor").."E~s~ pour percer ce casier.")
                                
                                if IsControlJustReleased(0, 51) then
                                    SetEntityHeading(PlayerPedId(), v.heading)
                                    local newcoords = GetOffsetFromCoordAndHeadingInWorldCoords(coords.x, coords.y, coords.z-0.98, v.heading, 0.08, -0.47, 0.0)  
                                    SetEntityCoords(PlayerPedId(), newcoords)
                                    currentDrillId = k
                                    Fleeca:StartScalform(k, TempId)
                                end
                            end
                        end
                    end
                    if nbrDrill == 0 and ValidDrills[TempId] ~= nil then
                        Fleeca.moove = 3
                        Fleeca:AnimStartFin()
                        break
                    end
                elseif Fleeca.moove == 2 and Fleeca.ScalformMoov and HasScaleformMovieLoaded(Fleeca.ScalformMoov) then
                    DrawScaleformMovieFullscreen(Fleeca.ScalformMoov, 255, 255, 255, 255)
                    DrawScaleformMovieFullscreen(helpScaleform, 255, 255, 255, 255)
                    HideHudAndRadarThisFrame()
                    DisableControlAction(0, 24, true)
                    DisableControlAction(0, 25, true)
                    local Press237, Press238 = IsControlPressed(0, 237), IsControlPressed(0, 238)
                    local StartSca = false
                    if Press237 and ((Scal4 >= 0.225 and Scal4 <= 0.325 and Scal1 <= 0.325) or (Scal4 >= 0.35 and Scal4 <= 0.45 and Scal1 <= 0.45) or (Scal4 >= 0.5 and Scal4 <= 0.6 and Scal1 <= 0.6) or (Scal4 >= 0.625 and Scal4 <= 0.725 and Scal1 <= 0.725)) then
                        StartSca = true;
                        if SoundId ~= 0.5 then
                            SoundId = 0.5
                            SetVariableOnSound(drillSoundID, "DrillState", 0.5)
                        end
                    end
                    if not StartSca and SoundId == 0.5 then
                        SoundId = 0.0
                        SetVariableOnSound(drillSoundID, "DrillState", 0.0)
                    end
                    if IsControlJustPressed(0, 51) and not RaterScal then
                        SoundScal = not SoundScal;
                        Fleeca:stopsoundandparticle(SoundScal)
                    end
                    if SoundScal and Scal2 < 0.5 then
                        Scal2 = math.max(0, math.min(0.5, Scal2 + 0.005))
                    elseif not SoundScal and Scal2 > 0.0 then
                        Scal2 = math.max(0, math.min(0.5, Scal2 - 0.005))
                    end
                    if not RaterScal and Press237 and SoundScal then
                        Scal4 = math.max(0, math.min(1.0, Scal4 + 0.001 * (StartSca and 0.5 or 1.0)))
                        if Scal4 > Scal1 then
                            Scal1 = math.max(0, math.min(1.0, Scal1 + 0.001))
                        end
                        if Scal1 > 0.1 and Scal1 - Scal4 <= 0.01 then
                            Scal3 = math.max(0, math.min(1.0, Scal3 + (StartSca and 0.005 or 0.002)))
                        end
                    end
                    if not RaterScal and Press238 and SoundScal then
                        Scal4 = math.max(0, math.min(1.0, Scal4 - 0.0025))
                    end
                    if not Press238 and not Press237 and Scal3 > 0.0 then
                        Scal3 = math.max(0, math.min(1.0, Scal3 - 0.0015))
                    end
                    if Scal3 > 0.7 and not RaterScal then
                        RaterScal = true
                        PlaySoundFrontend(-1, "Drill_Pin_Break", "DLC_HEIST_FLEECA_SOUNDSET", true)
                        SoundScal = false
                        Fleeca:stopsoundandparticle(SoundScal)
                    elseif RaterScal then
                        if Scal3 < 0.1 then
                            RaterScal = false
                        end
                        Scal2 = 0.0
                        Scal4 = math.max(0, math.min(1.0, Scal4 - 0.0075))
                    end
                    print(StartSca, RaterScal, Scal1, Scal1 >= 0.96, Scal3)
                    if Scal1 >= 0.96 then
                        PlaySoundFromEntity(-1, "Drill_Jam", PlayerPedId(), "DLC_HEIST_FLEECA_SOUNDSET", 1, 20)
                        SetScaleformMovieAsNoLongerNeeded(Fleeca.ScalformMoov)
                        Fleeca.ScalformMoov = nil
                        DeleteEntity(Fleeca.ObjectDrill)
                        Fleeca.ObjectDrill = nil
                        FreezeEntityPosition(PlayerPedId(), false)
                        ClearPedTasks(PlayerPedId())
                        Scal1 = 0.0
                        Scal2 = 0.0
                        Scal3 = 0.0
                        Scal4 = 0.0
                        RaterScal = false
                        SoundScal = false
                        SoundId = 1.0
                        Fleeca:stopsoundandparticle(false)
                        TriggerServerEvent("null:fleeca:heistDrill", TempId, currentDrillId)
                        Fleeca.moove = 1
                    end
                    CallScaleformMovieFunctionFloatParams(Fleeca.ScalformMoov, "SET_SPEED", Scal2 * (StartSca and 0.5 or 1.0), -1082130432,-1082130432, -1082130432, -1082130432)
                    CallScaleformMovieFunctionFloatParams(Fleeca.ScalformMoov, "SET_HOLE_DEPTH", Scal1, -1082130432, -1082130432,-1082130432, -1082130432)
                    CallScaleformMovieFunctionFloatParams(Fleeca.ScalformMoov, "SET_DRILL_POSITION", Scal4, -1082130432, -1082130432,-1082130432, -1082130432)
                    CallScaleformMovieFunctionFloatParams(Fleeca.ScalformMoov, "SET_TEMPERATURE", Scal3, -1082130432, -1082130432,-1082130432, -1082130432)
                end

            end
        end
    end)
end

function Fleeca:FindNearDoor(id)
    local idFleeca = Fleeca.posFleeca[id]
    local plyPos = GetEntityCoords(PlayerPedId())
    if not idFleeca.otherDoors then return nil end
    if #idFleeca.otherDoors <= 0 then return nil end
    local nearest, distance = nil, nil
    for k,v in pairs(idFleeca.otherDoors) do 
        local distance2 = Vdist(plyPos, null.fct.JsonCoordsToVect3(v.doorprops.pos))
        if nearest then
            if distance > distance then
                nearest = k
                distance = distance2
            end
        else
            nearest = k
            distance = distance2
        end
    end

    return nearest
end

function Fleeca:OpenDoorFl(id, type, fleecatype)
    local idFleeca = Fleeca.posFleeca[id]
    if fleecatype == 2 and type == "door" then
        local doorid = Fleeca:FindNearDoor(id)
        local doorpos = null.fct.JsonCoordsToVect3(idFleeca.otherDoors[doorid].doorprops.pos)
        local getObjdoor = ESX.Game.GetClosestObject(idFleeca.otherDoors[doorid].doorprops.finalSelect, doorpos)
        if getObjdoor and DoesEntityExist(getObjdoor) then
            Fleeca.ObjectDoor2id = getObjdoor
            Fleeca.ObjectDoor2idPos = doorpos
            TriggerServerEvent("Fleeca:OpenDoor", getObjdoor, doorpos, id, type)
            Fleeca.doorOpen = true
        end
    elseif fleecatype == 2 and type == "vault" then
        local doorpos = null.fct.JsonCoordsToVect3(idFleeca.vault.pos)
        local getObjdoor = ESX.Game.GetClosestObject(idFleeca.vaultprops, doorpos)
        if getObjdoor and DoesEntityExist(getObjdoor) then
            local dict = "anim@heists@fleeca_bank@bank_vault_door"
            Fleeca:RequestAndWaitDict(dict)
            PlayEntityAnim(getObjdoor, "bank_vault_door_opens", dict, 4.0, false, true, false, 0.0, 8)
            Fleeca.ObjectDoorid = getObjdoor
            Fleeca.ObjectDooridPos = doorpos
            TriggerServerEvent("Fleeca:OpenDoor", getObjdoor, doorpos, id, type)
            Fleeca.vaultOpen = true
        end
    elseif fleecatype == 1 then
        local doorpos = null.fct.JsonCoordsToVect3(idFleeca.vault.pos)
        local getObjdoor = ESX.Game.GetClosestObject(idFleeca.vaultprops, doorpos)
        if getObjdoor and DoesEntityExist(getObjdoor) then
            local dict = "anim@heists@fleeca_bank@bank_vault_door"
            Fleeca:RequestAndWaitDict(dict)
            PlayEntityAnim(getObjdoor, "bank_vault_door_opens", dict, 4.0, false, true, false, 0.0, 8)
            Fleeca.ObjectDoorid = getObjdoor
            Fleeca.ObjectDooridPos = doorpos
            TriggerServerEvent("Fleeca:OpenDoor", getObjdoor, doorpos, id, type)
            Fleeca.vaultOpen = true
        end
    end
end

RegisterNetEvent("Fleeca:startHackVault", function(id)
    StartClientBankHeist({
        type = "vault",
        fleecatype = 2,
        id = id
    })
end)

function Fleeca:StartScalform(drillid, fleecaid)
    print("StartScalform")
    local numFleeca = Fleeca.posFleeca[fleecaid]
    Fleeca:RequestAndWaitDict(Fleeca.dict)
    RequestNamedPtfxAsset(Fleeca.prEffect)
    while not HasNamedPtfxAssetLoaded(Fleeca.prEffect) do
        Citizen.Wait(0)
    end
    Fleeca.moove = 2
    local posRewarvec = null.fct.JsonCoordsToVect3(numFleeca.drills[drillid].pos)
    Fleeca:RequestAndWaitModel("hei_prop_heist_drill")
    Fleeca:RequestAndWaitModel("hei_p_m_bag_var22_arm_s")
    Fleeca.ObjectDrill = CreateObject(GetHashKey("hei_prop_heist_drill"), GetEntityCoords(PlayerPedId()), true)
    AttachEntityToEntity(Fleeca.ObjectDrill, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false,false, 2, true)
    TaskMoveNetworkAdvanced(PlayerPedId(), "minigame_drilling", posRewarvec, 0.0, 0.0, numFleeca.drills[drillid].heading, 2, 0.5, 0, Fleeca.dict, 4)
    FreezeEntityPosition(PlayerPedId(), true)
    ForcePedAiAndAnimationUpdate(PlayerPedId(), false, true)
    ClearPedTasks(PlayerPedId())
    TaskPlayAnim(PlayerPedId(), Fleeca.dict, "drill_straight_idle", 1000.0, -1.5, -1, 1)
    Fleeca.ScalformMoov = nil
    helpScaleform = nil
    Fleeca.ScalformMoov = Fleeca:CreateScaleform("drilling", {{name = "SET_SPEED",param = {0.1}},{name = "SET_HOLE_DEPTH",param = {0.6}},{name = "SET_DRILL_POSITION",param = {0.3}},{name = "SET_TEMPERATURE",param={0.0}}})
    helpScaleform = Fleeca:CreateScaleform("INSTRUCTIONAL_BUTTONS", 
    {
        {name = "CLEAR_ALL", param = {}},
        {name = "TOGGLE_MOUSE_BUTTONS", param = {0}},
        {name = "CREATE_CONTAINER", param = {}},
        {name = "SET_DATA_SLOT", param = {0, GetControlInstructionalButton(2, 51, 0), "Turn on/off"}}, 
        {name = "SET_DATA_SLOT", param = {1, GetControlInstructionalButton(2, 237, 0), "Push"}},
        {name = "SET_DATA_SLOT", param = {2, GetControlInstructionalButton(2, 238, 0), "Pull"}}, 
        {name = "DRAW_INSTRUCTIONAL_BUTTONS", param = {-1}}
    })
    Fleeca.moove = 2
end

function Fleeca:AnimStartFin(Ped)
    local pPed = GetPlayerPed(-1)

    local cleanupEntities = {
        Fleeca.ObjectTel,
        Fleeca.ObjectDrill,
        Fleeca.ObjectBag,
        Fleeca.ScalformMoov,
        helpScaleform,
        drillSoundID,
        Fleeca.netScal,
    }

    for _, entity in pairs(cleanupEntities) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end

    local animDicts = {
        "anim@heists@humane_labs@emp@hack_door",
        "anim@heists@fleeca_bank@bank_vault_door",
        Fleeca.dict,
    }

    for _, animDict in pairs(animDicts) do
        RemoveAnimDict(animDict)
    end

    local audioBanks = {
        [[DLC_MPHEIST\HEIST_FLEECA_DRILL]],
        [[DLC_MPHEIST\HEIST_FLEECA_DRILL_2]],
        "Vault_Door",
    }

    for _, audioBank in pairs(audioBanks) do
        ReleaseScriptAudioBank(audioBank, false)
    end

    if Fleeca.getVaria ~= 0 then
        SetPedComponentVariation(pPed, 5, Fleeca.getVaria, 0, 2)
    end

    if Fleeca.netScal then
        StopParticleFxLooped(Fleeca.netScal, 0)
        Fleeca.netScal = nil
        RemoveNamedPtfxAsset(Fleeca.prEffect)
    end
    SetModelAsNoLongerNeeded("prop_v_m_phone_01")

    Fleeca.nFleeca = 0
    Fleeca.moove = 0
    Fleeca.getVaria = 0

    Wait(5 * 60 * 1000)

    if Fleeca.ObjectDoorid ~= nil and Fleeca.ObjectDooridPos ~= nil then
        TriggerServerEvent("Fleeca:CloseDoor", Fleeca.ObjectDoorid, Fleeca.ObjectDooridPos)
    end
end

local soundActualPlay = false
function Fleeca:stopsoundandparticle(bool)
    if bool then
        if soundActualPlay then return end
        soundActualPlay = true
        print("createSound")
        UseParticleFxAssetNextCall(Fleeca.prEffect)
        Fleeca.netScal = StartNetworkedParticleFxLoopedOnEntity("scr_drill_debris", Fleeca.ObjectDrill, 0.0, -0.55, 0.01, -90.0, 0.0, 0.0, 0.5,1065353216, 1065353216, 0)
        SetParticleFxLoopedEvolution(Fleeca.netScal, "power", 0.3, 0)
        drillSoundID = GetSoundId()
        PlaySoundFromEntity(drillSoundID, "Drill", Fleeca.ObjectDrill, "DLC_HEIST_FLEECA_SOUNDSET", 1, 0)
    else
        if not soundActualPlay then return end
        print("stopSound")
        soundActualPlay = false
        if drillSoundID then
            StopSound(drillSoundID)
            drillSoundID = nil
            StopParticleFxLooped(Fleeca.netScal, 0)
            Fleeca.netScal = nil
        end
    end
end

function LoadModel(model)
    if type(model) == 'number' then
        model = model
    else
        model = GetHashKey(model)
    end
    while not HasModelLoaded(model) do
        RequestModel(model)
        Citizen.Wait(0)
    end
end

Fleeca.dict = "anim@heists@fleeca_bank@drilling"
Fleeca.getVaria = 0
Fleeca.prEffect = "FM_Mission_Controler"
Fleeca.moove = 0
Fleeca.doorOpen = false
Fleeca.vaultOpen = false
Fleeca.nFleeca = 0
Fleeca.ObjectDrill = nil
Fleeca.ObjectTel = nil
Fleeca.ScalformMoov = nil
Fleeca.netScal = nil
Fleeca.ObjectBag = nil
Fleeca.ObjectDoorid = nil 
Fleeca.ObjectDooridPos = nil
Fleeca.OpenDoor = false 

RegisterNetEvent("Fleeca:OpenDoor")
AddEventHandler("Fleeca:OpenDoor", function(prop, doorpos, id, type)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = Vdist(playerCoords, doorpos)
    if distance > 100.0 then
        return
    end
    if prop ~= nil then
        local maxDistance = 10.0
        if type == "door" then
            if distance <= maxDistance then
                PlaySoundFromCoord(-1, "vault", doorpos.x, doorpos.y, doorpos.z, "HACKING_DOOR_UNLOCK_SOUNDS", 1, 30, 0)
            end
            Fleeca.doorOpen = true
            local doorid = Fleeca:FindNearDoor(id)
            local getObjdoor = ESX.Game.GetClosestObject(Fleeca.posFleeca[id].otherDoors[doorid].doorprops.finalSelect, doorpos)
            if getObjdoor and DoesEntityExist(getObjdoor) then
                FreezeEntityPosition(getObjdoor, false)
            end
            FreezeEntityPosition(prop, false)
        else
            if Fleeca.posFleeca[MyFleecaId].vaultprops == "v_ilev_bk_vaultdoor" then
                if distance <= maxDistance then
                    local sescount = 0
                    repeat
                      PlaySoundFrontend(-1,"OPENING", "MP_PROPERTIES_ELEVATOR_DOORS" ,1)
                      Citizen.Wait(900)
                      sescount = sescount + 1
                    until sescount == 11
                end
        
                local obj = ESX.Game.GetClosestObject("v_ilev_bk_vaultdoor", playerCoords)
                local count = 0
                FreezeEntityPosition(obj, true)
                repeat
                  local rotation = GetEntityHeading(obj) - 0.05
                  SetEntityHeading(obj,rotation)
                  count = count + 1
                  Citizen.Wait(10)
                until count == 750
            else
                if distance <= maxDistance then
                    PlaySoundFromCoord(-1, "vault", doorpos.x, doorpos.y, doorpos.z, "HACKING_DOOR_UNLOCK_SOUNDS", 1, 30, 0)
                end
        
                local rotationCount = 1800
                local rotationStep = 0.05
        
                Citizen.Wait(800)
        
                for count = 1, rotationCount do
                    local newRotation = GetEntityHeading(prop) - rotationStep
                    SetEntityHeading(prop, newRotation)
                    Citizen.Wait(3)
                end
            end
            FreezeEntityPosition(prop, true)
        end

        Fleeca.OpenDoor = true
    end
end)

RegisterNetEvent("Fleeca:CloseDoor")
AddEventHandler("Fleeca:CloseDoor", function(prop, doorpos)
    if prop ~= nil and Fleeca.OpenDoor then
        local playerCoords = GetEntityCoords(PlayerPedId())
        local maxDistance = 10.0

        if Vdist(playerCoords, doorpos) <= maxDistance then
            PlaySoundFromCoord(-1, "vault", doorpos.x, doorpos.y, doorpos.z, "HACKING_DOOR_UNLOCK_SOUNDS", 1, 30, 0)
        end

        local rotationCount = 1800
        local rotationStep = 0.05

        Citizen.Wait(800)

        for count = 1, rotationCount do
            local newRotation = GetEntityHeading(prop) + rotationStep
            SetEntityHeading(prop, newRotation)
            Citizen.Wait(3)
        end

        FreezeEntityPosition(prop, true)
        Fleeca.OpenDoor = false
    end
end)

RegisterNetEvent("Fleeca:HeistDrill")
AddEventHandler("Fleeca:HeistDrill", function(FleecaId, DrillId)
    ValidDrills[FleecaId][DrillId] = false
end)

RegisterNetEvent("Fleeca:startFleeca")
AddEventHandler("Fleeca:startFleeca", function(id, type, fleecatype)
    TriggerServerEvent("Var:NotifPoliceHeist", GetEntityCoords(PlayerPedId()))
    Fleeca.nFleeca = {id = id, type = type, fleecatype = fleecatype}
    ValidDrills[id] = {}
    MyFleecaId = id
    StartFleecaThread()
end)

function StartClientBankHeist(data)
    Citizen.CreateThread(function()
        if data then
            local pPed = PlayerPedId()
            local pCoords, pRot = GetEntityCoords(pPed), GetEntityRotation(pPed)
            local animDict = 'anim@heists@ornate_bank@hack'
        
            for k, v in pairs(LaptopAnimation['objects']) do
                LoadModel(v)
                LaptopAnimation['sceneObjects'][k] = CreateObject(GetHashKey(v), pCoords, 1, 1, 0)
            end
        
            for i =1, #LaptopAnimation['animations'] do
                LaptopAnimation['scenes'][i] = NetworkCreateSynchronisedScene(pCoords.xy, pCoords.z + 0.4, pRot, 2, true, false, 1065353216, 0, 1.3)
                NetworkAddPedToSynchronisedScene(pPed, LaptopAnimation['scenes'][i], animDict, LaptopAnimation['animations'][i][1], 1.5, -4.0, 1, 16, 1148846080, 0)
                NetworkAddEntityToSynchronisedScene(LaptopAnimation['sceneObjects'][1], LaptopAnimation['scenes'][i], animDict, LaptopAnimation['animations'][i][3], 4.0, -8.0, 1)
            end
        
            NetworkStartSynchronisedScene(LaptopAnimation['scenes'][2])
            Wait(3000)
            null.DisplayHud(false)
            StartHotwire(function(status)
                null.DisplayHud(true)
                for k, v in pairs(LaptopAnimation['objects']) do
                    if DoesEntityExist(LaptopAnimation['sceneObjects'][k]) then
                        DeleteObject(LaptopAnimation['sceneObjects'][k])
                    end
                end
                for i =1, #LaptopAnimation['animations'] do
                    NetworkStopSynchronisedScene(LaptopAnimation['scenes'][i])
                end
                if status then
                    Fleeca:OpenDoorFl(data.id, data.type, data.fleecatype)
                end
            end)
        end
    end)
end
