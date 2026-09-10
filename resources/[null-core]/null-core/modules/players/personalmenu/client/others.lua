local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local handsup = false

function getSurrenderStatus()
	return handsup
end

RegisterCommand('+handsup', function()
    if DoesEntityExist(PlayerPedId()) and not IsEntityDead(PlayerPedId()) then
        if not IsPedInAnyVehicle(PlayerPedId(), false) and not IsPedSwimming(PlayerPedId()) and not IsPedClimbing(PlayerPedId()) and not IsPedCuffed(plyPed) and not IsPedDiving(PlayerPedId()) and not IsPedFalling(PlayerPedId()) and not IsPedJumpingOutOfVehicle(PlayerPedId()) and not IsPedUsingAnyScenario(PlayerPedId()) and not IsPedInParachuteFreeFall(PlayerPedId()) then
            RequestAnimDict("random@mugging3")

            while not HasAnimDictLoaded("random@mugging3") do
                Citizen.Wait(100)
            end

            if not handsup then
                handsup = true
                TaskPlayAnim(PlayerPedId(), "random@mugging3", "handsup_standing_base", 8.0, -8, -1, 49, 0, 0, 0, 0)
                TriggerServerEvent("Null:handsup", true)
                while handsup do
                    if not handsup then break end
                    if PlayerState.isInVehicle then 
                        handsup = false
                        ClearPedSecondaryTask(PlayerPedId())
                        TriggerServerEvent("Null:handsup", false)
                        break 
                    end
                    Wait(1000)
                end
            elseif handsup then
                handsup = false
                ClearPedSecondaryTask(PlayerPedId())
                TriggerServerEvent("Null:handsup", false)
            end
        end
    end
end, false)
RegisterKeyMapping('+handsup', 'Lever les mains', 'keyboard', 'X')

local mp_pointing = false
local keyPressed = false

local function startPointing()
    local ped = PlayerPedId()
    RequestAnimDict("anim@mp_point")
    while not HasAnimDictLoaded("anim@mp_point") do
        Citizen.Wait(0)
    end
    SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
    SetPedConfigFlag(ped, 36, 1)
    Citizen.InvokeNative(0x2D537BA194896636, ped, "task_mp_pointing", 0.5, 0, "anim@mp_point", 24)
    RemoveAnimDict("anim@mp_point")

    Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
        while true do 
            if not mp_pointing then break end
            if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) then
                if not IsPedOnFoot(PlayerPedId()) then
                    stopPointing()
                else
                    local ped = PlayerPedId()
                    local camPitch = GetGameplayCamRelativePitch()
                    if camPitch < -70.0 then
                        camPitch = -70.0
                    elseif camPitch > 42.0 then
                        camPitch = 42.0
                    end
                    camPitch = (camPitch + 70.0) / 112.0
    
                    local camHeading = GetGameplayCamRelativeHeading()
                    local cosCamHeading = Cos(camHeading)
                    local sinCamHeading = Sin(camHeading)
                    if camHeading < -180.0 then
                        camHeading = -180.0
                    elseif camHeading > 180.0 then
                        camHeading = 180.0
                    end
                    camHeading = (camHeading + 180.0) / 360.0
    
                    local blocked = 0
                    local nn = 0
    
                    local coords = GetOffsetFromEntityInWorldCoords(ped, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
                    local ray = Cast_3dRayPointToPoint(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, ped, 7);
                    nn,blocked,coords,coords = GetRaycastResult(ray)
    
                    Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Pitch", camPitch)
                    Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Heading", camHeading * -1.0 + 1.0)
                    Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isBlocked", blocked)
                    Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isFirstPerson", Citizen.InvokeNative(0xEE778F8C7E1142E2, Citizen.InvokeNative(0x19CAFA3C87F7C2FF)) == 4)
                end
            end
            Wait(0)
        end
    end))
end

local function stopPointing()
    local ped = PlayerPedId()
    Citizen.InvokeNative(0xD01015C7316AE176, ped, "Stop")
    if not IsPedInjured(ped) then
        ClearPedSecondaryTask(ped)
    end
    if not IsPedInAnyVehicle(ped, 1) then
        SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
    end
    SetPedConfigFlag(ped, 36, 0)
    ClearPedSecondaryTask(PlayerPedId())
end

local once = true
local oldval = false
local oldvalped = false


RegisterCommand('+point', function()
    if not IsPedOnFoot(PlayerPedId()) then return end
    if mp_pointing then
        mp_pointing = false
        stopPointing()
    else
        mp_pointing = true
        startPointing()
    end
end, false)
RegisterKeyMapping('+point', 'Pointer du doigt', 'keyboard', 'B')

--[[Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        if once then
            once = false
        end

        if not keyPressed then
            if IsControlPressed(1, Keys["B"]) and not mp_pointing and IsPedOnFoot(PlayerPedId()) then
                Citizen.Wait(200)
                if not IsControlPressed(1, Keys["B"]) then
                    keyPressed = true
                    startPointing()
                    mp_pointing = true
                else
                    keyPressed = true
                    while IsControlPressed(1, Keys["B"]) do
                        Citizen.Wait(50)
                    end
                end
            elseif (IsControlPressed(1, Keys["B"]) and mp_pointing) or (not IsPedOnFoot(PlayerPedId()) and mp_pointing) then
                keyPressed = true
                mp_pointing = false
                stopPointing()
            end
        end

        if keyPressed then
            if not IsControlPressed(1, Keys["B"]) then
                keyPressed = false
            end
        end
        if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) and not mp_pointing then
            stopPointing()
        end
        if Citizen.InvokeNative(0x921CE12C489C4C41, PlayerPedId()) then
            if not IsPedOnFoot(PlayerPedId()) then
                stopPointing()
            else
                local ped = PlayerPedId()
                local camPitch = GetGameplayCamRelativePitch()
                if camPitch < -70.0 then
                    camPitch = -70.0
                elseif camPitch > 42.0 then
                    camPitch = 42.0
                end
                camPitch = (camPitch + 70.0) / 112.0

                local camHeading = GetGameplayCamRelativeHeading()
                local cosCamHeading = Cos(camHeading)
                local sinCamHeading = Sin(camHeading)
                if camHeading < -180.0 then
                    camHeading = -180.0
                elseif camHeading > 180.0 then
                    camHeading = 180.0
                end
                camHeading = (camHeading + 180.0) / 360.0

                local blocked = 0
                local nn = 0

                local coords = GetOffsetFromEntityInWorldCoords(ped, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
                local ray = Cast_3dRayPointToPoint(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, ped, 7);
                nn,blocked,coords,coords = GetRaycastResult(ray)

                Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Pitch", camPitch)
                Citizen.InvokeNative(0xD5BB4025AE449A4E, ped, "Heading", camHeading * -1.0 + 1.0)
                Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isBlocked", blocked)
                Citizen.InvokeNative(0xB0A6CFD2C69C1088, ped, "isFirstPerson", Citizen.InvokeNative(0xEE778F8C7E1142E2, Citizen.InvokeNative(0x19CAFA3C87F7C2FF)) == 4)
            end
        end
    end
end)]]

local crouched = false
local GUI = {}
GUI.Time = 0

--[[RegisterCommand('+accroupire', function() 
    RequestAnimSet("move_ped_crouched")

    while not HasAnimSetLoaded("move_ped_crouched") do 
        Citizen.Wait(100)
    end 

    if crouched == true then 
        ResetPedMovementClipset(PlayerPedId(), 0)
        crouched = false 
    elseif crouched == false then
        SetPedMovementClipset(PlayerPedId(), "move_ped_crouched", 0.25)
        crouched = true 
    end 
    
    GUI.Time = GetGameTimer()
end, false)]]
RegisterKeyMapping('+accroupire', 'S\'accroupir', 'keyboard', 'N')

--Fonctions des accesoires 
function setAccessory(accessory)
    ESX.TriggerServerCallback("Null:esx_accessories:get", function(hasAccessory, accessorySkin)
        local _accessory = (accessory):lower()
            TriggerEvent("Null:skinchanger:getSkin", function(skin)
                local mAccessory = -1
                local mColor = 0

                if _accessory == "ears" then
                    Wait(250)
                    ClearPedTasks(plyPed)
                elseif _accessory == "glasses" then
                    mAccessory = 0
                    Wait(1000)
                    ClearPedTasks(plyPed)
                elseif _accessory == "helmet" then
                    Wait(1000)
                    PlayerState.handsup, PlayerState.pointing = false, false
                    ClearPedTasks(plyPed)
                elseif _accessory == "mask" then
                    mAccessory = 0
                    Wait(850)
                    ClearPedTasks(plyPed)
                end

                if skin[_accessory .. "_1"] == mAccessory then
                    mAccessory = accessorySkin[_accessory .. "_1"]
                    mColor = accessorySkin[_accessory .. "_2"]
                end

                local accessorySkin = {}
                accessorySkin[_accessory .. "_1"] = mAccessory
                accessorySkin[_accessory .. "_2"] = mColor
                TriggerEvent("Null:skinchanger:loadClothes", skin, accessorySkin)
            end)

    end, accessory)
end

--Check Quantity 
function CheckQuantity(number)
    number = tonumber(number)

    if type(number) == "number" then
        number = ESX.Math.Round(number)

        if number > 0 then
            return true, number
        end
    end

    return false, number
end


--Player Marker
function PlayerMakrer(player)
    local ped = GetPlayerPed(player)
    local pos = GetEntityCoords(ped)
    DrawMarker(2, pos.x, pos.y, pos.z+1.0, 0.0, 0.0, 0.0, 179.0, 0.0, 0.0, 0.25, 0.25, 0.25, 81, 203, 231, 200, 0, 1, 2, 1, nil, nil, 0)
end
local noir = false
RegisterCommand('noir', function()
    noir = not noir
    if noir then 
        DisplayRadar(false) 
        null.DisplayHud(false)
    end
    while noir do
        if not HasStreamedTextureDictLoaded('revolutionbag') then
            RequestStreamedTextureDict('revolutionbag')
            while not HasStreamedTextureDictLoaded('revolutionbag') do
                Citizen.Wait(50)
            end
        end

        DrawSprite('revolutionbag', 'cinema', 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
        Citizen.Wait(0)
    end
    DisplayRadar(true)
    null.DisplayHud(true)
    SetStreamedTextureDictAsNoLongerNeeded('revolutionbag')
end)