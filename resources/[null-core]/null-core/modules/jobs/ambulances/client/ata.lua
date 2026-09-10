local ataTime = 0
local ataThreadActive = false
local ataCooldown = 0
local ataTimeRemoving = 0
local ataType = 0
local ataProps = {}
local caneModel = 'prop_cs_walking_stick'
local CaneObjet = nil

local disabledAtaKeys = {
    {group = 2, key = 37, message = '~r~Vous ne pouvez pas sortir d\'arme en SafeZone'},
    {group = 0, key = 24, message = '~r~Vous ne pouvez pas faire ceci en SafeZone'},
    {group = 0, key = 69, message = '~r~Vous ne pouvez pas faire ceci en SafeZone'},
    {group = 0, key = 92, message = '~r~Vous ne pouvez pas faire ceci en SafeZone'},
    {group = 0, key = 106, message = '~r~Vous ne pouvez pas faire ceci en SafeZone'},
    {group = 0, key = 168, message = '~r~Vous ne pouvez pas faire ceci en SafeZone'},
    {group = 0, key = 160, message = '~r~Vous ne pouvez pas faire ceci en SafeZone'},
    {group = 0, key = 160, message = '~r~Vous ne pouvez pas faire ceci en SafeZone'},
}

local function CreateCane()
	if not HasModelLoaded(-1035084591) then
		RequestModel(-1035084591)
		while not HasModelLoaded(-1035084591) do
			Citizen.Wait(10)
		end
	end
    CaneObjet = CreateObject(-1035084591, GetEntityCoords(PlayerPedId()), true, false, false)
	AttachEntityToEntity(CaneObjet, PlayerPedId(), 70, 1.18, -0.36, -0.20, -20.0, -87.0, -20.0, true, true, false, true, 1, true)
end

function inAta()
    return ataThreadActive
end

function getAtaTime()
    return ataTime
end

function getAtaType()
    return ataType
end

function inCane()
    return ataTime > 0 and ataType == 1
end

local function MinutesToSeconds(minutes)
    return minutes * 60
end

local function SecondsToClock(seconds)
    seconds = tonumber(seconds)

    if seconds <= 0 then
        return "00:00"
    else
        local mins = string.format("%02.f", math.floor(seconds / 60))
        local secs = string.format("%02.f", math.floor(seconds - mins * 60))
        return string.format("%s:%s", mins, secs)
    end
end

local function SecondsToClock2(seconds)
    seconds = tonumber(seconds)

    if seconds <= 0 then
        return "00:00"
    else
        local mins = string.format("%02.f", math.floor(seconds / 60))
        local secs = string.format("%02.f", math.floor(seconds - mins * 60))
        return string.format("%s.%s", mins, secs)
    end
end

local function SecondsToClock3(seconds)
    seconds = tonumber(seconds)

    if seconds <= 0 then
        return "00:00"
    else
        local mins = string.format("%02.f", math.floor(seconds / 60))
        local secs = string.format("%02.f", math.floor(seconds - mins * 60))
        return string.format("%s", secs)
    end
end

local TimeSave = {
    [1.0] = true,
    [2.0] = true,
    [3.0] = true,
    [4.0] = true,
    [5.0] = true,
    [6.0] = true,
    [7.0] = true,
    [8.0] = true,
    [9.0] = true,
    [10.0] = true,
    [11.0] = true,
    [12.0] = true,
    [13.0] = true,
    [14.0] = true,
    [15.0] = true,
    [16.0] = true,
    [17.0] = true,
    [18.0] = true,
    [19.0] = true,
    [20.0] = true,
    [21.0] = true,
    [22.0] = true,
    [23.0] = true,
    [24.0] = true,
    [25.0] = true,
    [26.0] = true,
    [27.0] = true,
    [28.0] = true,
    [29.0] = true,
    [30.0] = true,
}

local function ataThread()
    if ataTime <= 0 then 
        return 
    end
    if AtaType == 1 then
        if DoesEntityExist(CaneObjet) then
            DeleteEntity(CaneObjet)
        end
        CreateCane()
    end
    ataThreadActive = true
    ataTimeRemoving = GetGameTimer()

    Citizen.CreateThread(function()
        while ataThreadActive and ataTime > 0 do 
			local lPed = PlayerPedId()
            DisablePlayerFiring(lPed, true)
            SetCurrentPedWeapon(lPed, `WEAPON_UNARMED`, true)
            null.DebugPrint("ata, set unarmed")
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 140, true)
            RageUI.disableKeyFrame(21)
            RageUI.disableKeyFrame(22)
            RageUI.disableKeyFrame(25)
            RageUI.disableKeyFrame(140)


            for i = 1, #disabledAtaKeys, 1 do
                DisableControlAction(disabledAtaKeys[i].group, disabledAtaKeys[i].key, true)

                if IsDisabledControlJustPressed(disabledAtaKeys[i].group, disabledAtaKeys[i].key) or IsDisabledControlJustReleased(disabledAtaKeys[i].group, disabledAtaKeys[i].key) then
                    SetCurrentPedWeapon(lPed, `WEAPON_UNARMED`, true)
                    null.DebugPrint("ata, set unarmed")
                end
            end

            local removeTime = (GetGameTimer() - ataTimeRemoving) / 1000
            local timeRemaining = SecondsToClock(ataTime - removeTime)
            local ataMessage = ("Vous êtes limité physiquement pendant %s."):format(timeRemaining)

                DrawMissionText(ataMessage, 0)

            if ataTime - removeTime <= 0.0 then 
                ataThreadActive = false 
                ataType = 0
                ataTime = 0
                break
            end

            Citizen.Wait(0)
        end
        
        if AtaType == 1 then
            if DoesEntityExist(CaneObjet) then
               DeleteEntity(CaneObjet)
            end
        end

        ataThreadActive = false 
        ataType = 0
        ataTime = 0
    end)

    --[[Citizen.CreateThread(function()
        local AlreadyTrigger = {}
        while ataThreadActive and ataTime > 0 do 
            local removeTime = (GetGameTimer() - ataTimeRemoving) / 1000
            local tempsrestant = ataTime - removeTime

            if SecondsToClock3(tempsrestant) == "00" and AlreadyTrigger[SecondsToClock3(tempsrestant)] == nil then
                TriggerServerEvent("ata:server:updateAta", nil, tempsrestant)
                TriggerServerEvent("ata:server:recevieatatime", nil, tempsrestant)
                AlreadyTrigger[SecondsToClock3(tempsrestant)] = true
            end
            Citizen.Wait(0)
        end
    end)]]
    Citizen.CreateThread(function()
        local AlreadyTrigger = {}
        while ataThreadActive and ataTime > 0 do 
            Citizen.Wait(60000)
            local removeTime = (GetGameTimer() - ataTimeRemoving) / 1000
            local tempsrestant = ataTime - removeTime
            TriggerServerEvent("ata:server:recevieatatime", math.round(tempsrestant/60))
        end
        TriggerServerEvent("ata:server:recevieatatime", 0)
    end)
end

RegisterNetEvent('ata:client:update', function(ata)
    if ata == nil then
        return
    end

    ataTime = ata.time == nil and 0 or MinutesToSeconds(ata.time)
    ataType = ata.type == nil and 0 or ata.type
    ataTimeRemoving = GetGameTimer()

    if ataTime > 0 and not ataThreadActive then
        ataThread()
    end
end)