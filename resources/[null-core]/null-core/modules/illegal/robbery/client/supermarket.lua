Config.SupermarketRobbery.IsRobbing = false
Config.SupermarketRobbery.BarUpdate = nil
Config.SupermarketRobbery.Peds = {}
Config.SupermarketRobbery.Props = {}


function loadDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(10)
    end
end

RegisterNetEvent('null:supermarket-robbery:OnPedDeathRobbery')
AddEventHandler('null:supermarket-robbery:OnPedDeathRobbery', function(store)
    SetEntityHealth(Config.SupermarketRobbery.Peds[store], 0)
end)

RegisterNetEvent('null:supermarket-robbery:RemovePickupRobbery')
AddEventHandler('null:supermarket-robbery:RemovePickupRobbery', function(bank)
    for i = 1, #Config.SupermarketRobbery.Props  do 
        if Config.SupermarketRobbery.Props[i].bank == bank and DoesEntityExist(Config.SupermarketRobbery.Props[i].object) then 
            DeleteObject(Config.SupermarketRobbery.Props[i].object) 
        end 
    end
end)

RegisterNetEvent('null:supermarket-robbery:RobberyStartOver')
AddEventHandler('null:supermarket-robbery:RobberyStartOver', function()
    Config.SupermarketRobbery.IsRobbing = false
end)

RegisterNetEvent('null:supermarket-robbery:RobberyStart')
AddEventHandler('null:supermarket-robbery:RobberyStart', function(i)
    if not IsPedDeadOrDying(Config.SupermarketRobbery.Peds[i]) then
        SetEntityCoords(Config.SupermarketRobbery.Peds[i], Config.SupermarketRobbery.List[i].coords)
        loadDict('mp_am_hold_up')
        TaskPlayAnim(Config.SupermarketRobbery.Peds[i], "mp_am_hold_up", "holdup_victim_20s", 8.0, -8.0, -1, 2, 0, false, false, false)
        PlayAmbientSpeechWithVoice(Config.SupermarketRobbery.Peds[i], "SHOP_HURRYING", "MP_M_SHOPKEEP_01_PAKISTANI_MINI_01", "SPEECH_PARAMS_FORCE", 1)
        while not IsEntityPlayingAnim(Config.SupermarketRobbery.Peds[i], "mp_am_hold_up", "holdup_victim_20s", 3) do 
            Wait(0) 
        end
        local timer = GetGameTimer() + 10800
        while timer >= GetGameTimer() do
            if IsPedDeadOrDying(Config.SupermarketRobbery.Peds[i]) then
                break
            end
            if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(Config.SupermarketRobbery.Peds[i]), true) >= 7.5 then
                ClearPedTasks(Config.SupermarketRobbery.Peds[i])
                Wait(0)
                ReleaseScriptAudioBank("Alarms")
                StopSound(Config.SupermarketRobbery.IsRobbing)
                null.fct.draw.RemoveTimerBar()
                SetFakeWantedLevel(0)
                Config.SupermarketRobbery.IsRobbing = false
            end
            Wait(0)
        end

        if not IsPedDeadOrDying(Config.SupermarketRobbery.Peds[i]) then
            local cashRegister = GetClosestObjectOfType(GetEntityCoords(Config.SupermarketRobbery.Peds[i]), 5.0, GetHashKey('prop_till_01'))
            if DoesEntityExist(cashRegister) then
                CreateModelSwap(GetEntityCoords(cashRegister), 0.5, GetHashKey('prop_till_01'), GetHashKey('prop_till_01_dam'), false)
                PlayAmbientSpeechWithVoice(Config.SupermarketRobbery.Peds[i],"BUMP","A_F_M_BEACH_01_WHITE_FULL_01","SPEECH_PARAMS_FORCE",1)
            end

            timer = GetGameTimer() + 200 
            while timer >= GetGameTimer() do
                if IsPedDeadOrDying(Config.SupermarketRobbery.Peds[i]) then
                    break
                end
                if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(Config.SupermarketRobbery.Peds[i]), true) >= 7.5 then
                    ClearPedTasks(Config.SupermarketRobbery.Peds[i])
                    Wait(0)
                    ReleaseScriptAudioBank("Alarms")
                    StopSound(Config.SupermarketRobbery.IsRobbing)
                    null.fct.draw.RemoveTimerBar()
                    SetFakeWantedLevel(0)
                    Config.SupermarketRobbery.IsRobbing = false
                end
                Wait(0)
            end
            local model = GetHashKey('prop_poly_bag_01')
            RequestAndWaitModel(model)
            local bag = CreateObject(model, GetEntityCoords(Config.SupermarketRobbery.Peds[i]), false, false)
                        
            AttachEntityToEntity(bag, Config.SupermarketRobbery.Peds[i], GetPedBoneIndex(Config.SupermarketRobbery.Peds[i], 60309), 0.1, -0.11, 0.08, 0.0, -75.0, -75.0, 1, 1, 0, 0, 2, 1)
            timer = GetGameTimer() + 10000
            while timer >= GetGameTimer() do
                if IsPedDeadOrDying(Config.SupermarketRobbery.Peds[i]) then
                    break
                end
                Wait(0)
            end
            if not IsPedDeadOrDying(Config.SupermarketRobbery.Peds[i]) then
                DetachEntity(bag, true, false)
                timer = GetGameTimer() + 75
                while timer >= GetGameTimer() do
                    if IsPedDeadOrDying(Config.SupermarketRobbery.Peds[i]) then
                        break
                    end
                    if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(Config.SupermarketRobbery.Peds[i]), true) >= 7.5 then
                        ClearPedTasks(Config.SupermarketRobbery.Peds[i])
                        Wait(0)
                        ReleaseScriptAudioBank("Alarms")
                        StopSound(Config.SupermarketRobbery.IsRobbing)
                        null.fct.draw.RemoveTimerBar()
                        SetFakeWantedLevel(0)
                        Config.SupermarketRobbery.IsRobbing = false
                    end
                    Wait(0)
                end
                SetEntityHeading(bag, Config.SupermarketRobbery.List[i].heading)
                ApplyForceToEntity(bag, 3, vector3(0.0, 50.0, 0.0), 0.0, 0.0, 0.0, 0, true, true, false, false, true)
                table.insert(Config.SupermarketRobbery.Props , {bank = i, object = bag})
                Citizen.CreateThread(function()
                    while true do
                        local wait = 500
                        if DoesEntityExist(bag) then
                            if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(bag), true) <= 1.5 then
                                wait = 1
                                --DrawText3D(GetEntityCoords(bag).x, GetEntityCoords(bag).y, GetEntityCoords(bag).z, "Appuyez sur ~g~E~s~ pour ~g~ramasser le sac~s~.", 12)
                                null.fct.draw.Text3DBar(GetEntityCoords(bag).x, GetEntityCoords(bag).y, GetEntityCoords(bag).z, "Appuyez sur ~g~E~s~ pour ~g~ramasser le sac~s~.")
                                if IsControlJustPressed(0, 38) then 
                                    local dict, anim = 'random@domestic', 'pickup_low'
                                    loadDict(dict)
                                    TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, 8.0, -1, 0, 1, 0, 0, 0)
                                    Wait(1000)
                                    PlaySoundFrontend(-1, 'Bus_Schedule_Pickup', 'DLC_PRISON_BREAK_HEIST_SOUNDS', false)
                                    null.fct.draw.UpdateTimerBar(Config.SupermarketRobbery.BarUpdate, {percentage = 0})
                                    null.fct.draw.RemoveTimerBar()
                                    StopSound(Config.SupermarketRobbery.IsRobbing)
                                    ReleaseScriptAudioBank("Alarms")
                                    TriggerServerEvent('null:supermarket-robbery:PickupRobbery', Config.SupermarketRobbery.List[i], i)
                                    SetFakeWantedLevel(0)
                                    break
                                end
                            end
                        else
                            break
                        end
                        Wait(wait)
                    end
                end)
            else
                DeleteObject(bag)
            end
        end
        loadDict('mp_am_hold_up')
        TaskPlayAnim(Config.SupermarketRobbery.Peds[i], "mp_am_hold_up", "cower_intro", 8.0, -8.0, -1, 0, 0, false, false, false)
        Wait(10000)
        ClearPedTasks(Config.SupermarketRobbery.Peds[i])
    end
end)

RegisterNetEvent('null:supermarket-robbery:ResetPedDeath')
AddEventHandler('null:supermarket-robbery:ResetPedDeath', function(i)
    if DoesEntityExist(Config.SupermarketRobbery.Peds[i]) then
        DeletePed(Config.SupermarketRobbery.Peds[i])
    end
    Wait(250)
    Config.SupermarketRobbery.Peds[i] = _CreatePed(Config.SupermarketRobbery.List[i].shopkeeper, Config.SupermarketRobbery.List[i].coords, Config.SupermarketRobbery.List[i].heading)
    SetEntityInvincible(Config.SupermarketRobbery.Peds[i], true)
    local brokenCashRegister = GetClosestObjectOfType(GetEntityCoords(Config.SupermarketRobbery.Peds[i]), 5.0, GetHashKey('prop_till_01_dam'))
    if DoesEntityExist(brokenCashRegister) then
        CreateModelSwap(GetEntityCoords(brokenCashRegister), 0.5, GetHashKey('prop_till_01_dam'), GetHashKey('prop_till_01'), false)
    end
end)

function _CreatePed(hash, coords, heading)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Wait(5)
    end

    local ped = CreatePed(4, hash, coords, false, false)
    SetEntityHeading(ped, heading)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedHearingRange(ped, 0.0)
    SetPedSeeingRange(ped, 0.0)
    SetPedAlertness(ped, 0.0)
    SetPedFleeAttributes(ped, 0, 0)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedCombatAttributes(ped, 46, true)
    SetPedFleeAttributes(ped, 0, 0)
    return ped
end

local function MenaceApuMore(apu)
    ShowNotification("~r~Vous devez menacer APU.")
    local pPed = PlayerPedId()
    PlayAmbientSpeechWithVoice(apu, "SHOP_SCARED_START", "MP_M_SHOPKEEP_01_PAKISTANI_MINI_01", "SPEECH_PARAMS_FORCE", 1)
    GiveWeaponToPed(apu, GetHashKey("weapon_sawnoffshotgun"), 0, 1, 1)
    TaskAimGunAtEntity(apu, pPed, 2500, false)
    --TaskAnimForce({"random@mugging3","handsup_standing_base"},48)
    Citizen.Wait(5000)
    RemoveAllPedWeapons(apu, 1)
    ClearPedTasks(pPed)
    null.fct.draw.RemoveTimerBar()
    StopSound(Config.SupermarketRobbery.IsRobbing)
    SetFakeWantedLevel(0)
    ReleaseScriptAudioBank("Alarms")
    null.fct.draw.UpdateTimerBar(Config.SupermarketRobbery.BarUpdate, {percentage = 0})
end

local function ApuShootPlayer(peds)
    local pPed = PlayerPedId()
    PlayAmbientSpeechWithVoice(peds, "SHOP_SCARED_START","MP_M_SHOPKEEP_01_PAKISTANI_MINI_01", "SPEECH_PARAMS_FORCE", 1)
    GiveWeaponToPed(peds, GetHashKey("weapon_autoshotgun"), 0, 1, 1)
    TaskAimGunAtEntity(peds, pPed, 2000, false)
    Wait(2000)
    TaskShootAtEntity(peds, pPed, 6000, -957453492)
    Citizen.Wait(6500)
    RemoveAllPedWeapons(peds, 1)
    ClearPedTasks(peds)
end

Citizen.CreateThread(function()
    for i = 1, #Config.SupermarketRobbery.List do 
        Config.SupermarketRobbery.Peds[i] = _CreatePed(Config.SupermarketRobbery.List[i].shopkeeper, Config.SupermarketRobbery.List[i].coords, Config.SupermarketRobbery.List[i].heading)
        SetEntityInvincible(Config.SupermarketRobbery.Peds[i], true)
        local brokenCashRegister = GetClosestObjectOfType(GetEntityCoords(Config.SupermarketRobbery.Peds[i]), 5.0, GetHashKey('prop_till_01_dam'))
        if DoesEntityExist(brokenCashRegister) then
            CreateModelSwap(GetEntityCoords(brokenCashRegister), 0.5, GetHashKey('prop_till_01_dam'), GetHashKey('prop_till_01'), false)
        end
    end

  --Citizen.CreateThread(function()
  --    while true do
  --        for i = 1, #Config.SupermarketRobbery.Peds do
  --            if IsPedDeadOrDying(Config.SupermarketRobbery.Peds[i]) then
  --                TriggerServerEvent('null:supermarket-robbery:PedDeadRobbery', i)
  --            end
  --        end
  --        Wait(30000)
  --    end
  --end)
   
	local timerBraquage = false
    local wait = 1000
    while true do
        Wait(wait)
        local player = PlayerPedId()
        if IsPedArmed(player, 5) then
            wait = 500
            if IsPlayerFreeAiming(PlayerId()) or IsPedInMeleeCombat(player) then
                if Config.SupermarketRobbery.IsRobbing then
                    StopSound(Config.SupermarketRobbery.IsRobbing)
                    Config.SupermarketRobbery.IsRobbing = false
                end
                for i = 1, #Config.SupermarketRobbery.Peds do
                    if HasEntityClearLosToEntityInFront(player, Config.SupermarketRobbery.Peds[i], 19) and not IsPedDeadOrDying(Config.SupermarketRobbery.Peds[i]) and GetDistanceBetweenCoords(GetEntityCoords(player), GetEntityCoords(Config.SupermarketRobbery.Peds[i]), true) <= 5.0 then
                        wait = 1
                        if not Config.SupermarketRobbery.IsRobbing then
                            local canRob = nil
							if not timerBraquage then
								timerBraquage = true
								ESX.TriggerServerCallback('null:supermarket-robbery:CanRobbery', function(cb)
									canRob = cb
                                    ESX.ShowNotification("~g~Vous ne pouvez pas braquer se supermarché (pas assez de policier)")
									Citizen.SetTimeout(10000, function()
										timerBraquage = false
									end)
								end, i)
								while canRob == nil do
									Wait(0)
								end
							end
                                if canRob == true then
                                    local chance = math.random(0, 99)
                                    if chance >= 0 and chance <= 25 then
                                        ApuShootPlayer(Config.SupermarketRobbery.Peds[i])
                                    else
                                        Config.SupermarketRobbery.IsRobbing = true
                                        RequestScriptAudioBank("Alarms")
                                        PlaySoundFromCoord(Config.SupermarketRobbery.IsRobbing, "Burglar_Bell", Config.SupermarketRobbery.List[i].coords, "Generic_Alarms", 0, 0, 0)
                                        PlaySoundFrontend(-1, "Object_Dropped_Remote", "GTAO_FM_Events_Soundset", 0)
                                        ActivatePhysics(Config.SupermarketRobbery.Peds[i])
                                        Config.SupermarketRobbery.BarUpdate = null.fct.draw.AddTimerBar("Menace :",{percentage = 0.0, bg = {100,0,0,255}, fg = {200,0,0,255}})
                                        PlayAmbientSpeechWithVoice(Config.SupermarketRobbery.Peds[i], "SHOP_HURRYING", "MP_M_SHOPKEEP_01_PAKISTANI_MINI_01", "SPEECH_PARAMS_FORCE", 1)
                                        SetFakeWantedLevel(2)
                                        Citizen.CreateThread(function()
                                            while Config.SupermarketRobbery.IsRobbing do 
                                                Wait(0) 
                                                if IsPedDeadOrDying(Config.SupermarketRobbery.Peds[i]) then 
                                                    Config.SupermarketRobbery.IsRobbing = false 
                                                end 
                                                if not IsPedArmed(player, 5) and GetDistanceBetweenCoords(GetEntityCoords(player), GetEntityCoords(Config.SupermarketRobbery.Peds[i]), true) <= 5.0 then
                                                    ClearPedTasksImmediately(Config.SupermarketRobbery.Peds[i])
                                                    MenaceApuMore(Config.SupermarketRobbery.Peds[i])
                                                    Config.SupermarketRobbery.IsRobbing = false 
                                                end
                                            end
                                        end)
                                        loadDict('missheist_agency2ahands_up')
                                        TriggerServerEvent('null:supermarket-robbery::CallPolice', Config.SupermarketRobbery.List[i], i)
                                        TaskPlayAnim(Config.SupermarketRobbery.Peds[i], "missheist_agency2ahands_up", "handsup_anxious", 8.0, -8.0, -1, 1, 0, false, false, false)
                                        local scared = 0
                                        while scared < 50 and not IsPedDeadOrDying(Config.SupermarketRobbery.Peds[i]) and GetDistanceBetweenCoords(GetEntityCoords(player), GetEntityCoords(Config.SupermarketRobbery.Peds[i]), true) <= 7.5 do
                                            local sleep = Config.SupermarketRobbery.List[i].timrob
                                            SetEntityAnimSpeed(Config.SupermarketRobbery.Peds[i], "missheist_agency2ahands_up", "handsup_anxious", 1.0)
                                            if IsPedArmed(player, 5) then
                                                sleep = Config.SupermarketRobbery.List[i].timrob
                                                SetEntityAnimSpeed(Config.SupermarketRobbery.Peds[i], "missheist_agency2ahands_up", "handsup_anxious", 1.3)
                                            end
                                            sleep = GetGameTimer() + sleep
                                            while sleep >= GetGameTimer() and not IsPedDeadOrDying(Config.SupermarketRobbery.Peds[i]) do
                                                Wait(0)
                                                local draw = scared/500
                                            end
                                            null.fct.draw.UpdateTimerBar(Config.SupermarketRobbery.BarUpdate, {percentage = scared / 50})
                                            scared = scared + 1
                                        end
                                        if GetDistanceBetweenCoords(GetEntityCoords(player), GetEntityCoords(Config.SupermarketRobbery.Peds[i]), true) <= 7.5 then
                                            if not IsPedDeadOrDying(Config.SupermarketRobbery.Peds[i]) then
                                                TriggerServerEvent('null:supermarket-robbery:RobberyStart', i)
                                                while Config.SupermarketRobbery.IsRobbing do
                                                    Wait(0) 
                                                    if IsPedDeadOrDying(Config.SupermarketRobbery.Peds[i]) then 
                                                        Config.SupermarketRobbery.IsRobbing = false 
                                                        null.fct.draw.UpdateTimerBar(Config.SupermarketRobbery.BarUpdate, {percentage = 0})
                                                        null.fct.draw.RemoveTimerBar()
                                                    end 
                                                end
                                            end
                                        else
                                            ClearPedTasks(Config.SupermarketRobbery.Peds[i])
                                            local wait = GetGameTimer()+5000
                                            while wait >= GetGameTimer() do
                                                Wait(0)
                                                ReleaseScriptAudioBank("Alarms")
                                                StopSound(Config.SupermarketRobbery.IsRobbing)
                                                null.fct.draw.UpdateTimerBar(Config.SupermarketRobbery.BarUpdate, {percentage = 0})
                                                null.fct.draw.RemoveTimerBar()
                                                SetFakeWantedLevel(0)
                                            end
                                            Config.SupermarketRobbery.IsRobbing = false
                                        end
                                    end
                                elseif canRob == 'no_cops' then
                                    local wait = GetGameTimer() + 5000
                                    while wait >= GetGameTimer() do
                                        Wait(0)
                                        local pedcoord = GetEntityCoords(Config.SupermarketRobbery.Peds[i], true)
                                        --ESX.ShowNotification('~r~Pas assez de Policier en ville.')
                                        null.fct.draw.Text3DBar(pedcoord.x, pedcoord.y, pedcoord.z, '~r~Pas assez de Policier en ville.')
                                        StopSound(Config.SupermarketRobbery.IsRobbing)
                                        SetFakeWantedLevel(0)
                                    end
                                else
                                    local wait = GetGameTimer() + 5000
                                    while wait >= GetGameTimer() do
                                        Wait(0)
                                        local pedcoord = GetEntityCoords(Config.SupermarketRobbery.Peds[i], true)
                                        null.fct.draw.Text3DBar(pedcoord.x, pedcoord.y, pedcoord.z, '~r~Cette superette a déjà été braqué, le vendeur n\'a plus rien.')
                                        StopSound(Config.SupermarketRobbery.IsRobbing)
                                        SetFakeWantedLevel(0)
                                    end
                                end
                                break
                        else
                            wait = 150
                        end
                    end
                end
            end
        end
    end
end)

local BlipSuperette = {}
RegisterNetEvent('null:supermarket-robbery::MsgPolice')
AddEventHandler('null:supermarket-robbery::MsgPolice', function(store, i)
	local lieu = GetStreetNameFromHashKey(GetStreetNameAtCoord(store.coords.x, store.coords.y, store.coords.z))
    ESX.ShowAdvancedNotification("Informations", ESX.Config("serverColor").."Supérette", "Braquage de superette ! \nEmplacement sur la Carte\nLieu : "..lieu)

    if BlipSuperette[i] == nil then
        BlipSuperette[i] = AddBlipForCoord(store.coords)

        SetBlipSprite(BlipSuperette[i], 161)
        SetBlipScale(BlipSuperette[i], 2.0)
        SetBlipColour(BlipSuperette[i], 3)

        PulseBlip(BlipSuperette[i])

        Citizen.Wait(60000)
        if BlipSuperette[i] then
            RemoveBlip(BlipSuperette[i])
            BlipSuperette[i] = nil
        end
    else
        if BlipSuperette[i] then
            RemoveBlip(BlipSuperette[i])
            BlipSuperette[i] = nil
        end
    end
end)