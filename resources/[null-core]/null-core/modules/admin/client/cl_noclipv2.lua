ConfigNoClip = {

    vitessenormalnoclip = "0.4", -- Vitesse du Noclip quand tu marche
    vitessespeednoclip = "8", -- Vitesse du Noclip quand tu cours 
    touchewnoclip = "F3",


}

RegisterCommand("adminNoclip", function()
    if ESX.GetPlayerData()['group'] ~= 'user' and nTable.staffMode then
        if nTable.noclip == true then
            ToggleNoClipMode()
            nTable.noclip = false
        else
            ToggleNoClipMode()
            nTable.noclip = true
        end
    end
end, false)
RegisterKeyMapping('adminNoclip', 'Raccourci Noclip', 'keyboard', 'F2')

local breakSpeed = 10.0;

function ToggleNoClipMode()
    return NoClip(not nTable.noclip)
end

local NoClipSpeedMax = ConfigNoClip.vitessespeednoclip
local normalSpeed = ConfigNoClip.vitessenormalnoclip

function NoClip(bool)
    if (nTable.noclip == false) then
        
        noClippingEntity = PlayerPedId();
        
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            local veh = GetVehiclePedIsIn(PlayerPedId(), false);
            if IsPedDrivingVehicle(PlayerPedId(), veh) then
                noClippingEntity = veh;
            end
        end
        
        local isVeh = IsEntityAVehicle(noClippingEntity);
        
        nTable.noclip = bool;
        SetUserRadioControlEnabled(not nTable.noclip);
        
        if (nTable.noclip) then
            SetEntityAlpha(noClippingEntity, 51, 0)
            CreateThread(function()
                    
                    local clipped = noClippingEntity
                    local pPed = PlayerPedId();
                    local isClippedVeh = isVeh;
                    
                    SetInvincible(true, clipped);
                    
                    if not isClippedVeh then
                        ClearPedTasksImmediately(pPed)
                    end
                    
                    while nTable.noclip do
                        Wait(0);
                        
                        FreezeEntityPosition(clipped, true);
                        SetEntityCollision(clipped, false, false);
                        
                        SetEntityVisible(clipped, false, false);
                        SetLocalPlayerVisibleLocally(true);
                        SetEntityAlpha(clipped, 51, false)
                        
                        SetEveryoneIgnorePlayer(pPed, true);
                        SetPoliceIgnorePlayer(pPed, true);
                        
                        input = vector3(GetControlNormal(0, 30), GetControlNormal(0, 31), (IsControlAlwaysPressed(1, 38) and 1) or ((IsControlAlwaysPressed(1, 44) and -1) or 0))
                        speed = ((IsControlAlwaysPressed(1, 21) and NoClipSpeedMax) or normalSpeed) * ((isClippedVeh and 2.75) or 1)
                        
                        SetEntityRotation(noClippingEntity, GetGameplayCamRot(0), 0, false)
                        local forward, right, up, c = GetEntityMatrix(noClippingEntity);
                        previousVelocity = Lerp(previousVelocity, (((right * input.x * speed) + (up * -input.z * speed) + (forward * -input.y * speed))), Timestep() * breakSpeed);
                        c = c + previousVelocity
                        SetEntityCoords(noClippingEntity, c - offset, true, true, true, false)
                    
                    end
                    Wait(0);
                    
                    FreezeEntityPosition(clipped, false);
                    SetEntityCollision(clipped, true, true);
                    
                    SetEntityVisible(clipped, true, false);
                    SetLocalPlayerVisibleLocally(true);
                    ResetEntityAlpha(clipped);
                    
                    SetEveryoneIgnorePlayer(pPed, false);
                    SetPoliceIgnorePlayer(pPed, false);
                    ResetEntityAlpha(clipped);
                    
                    Wait(500);
                    
                    if isClippedVeh then
                        while (not IsVehicleOnAllWheels(clipped)) and not nTable.noclip do
                            Wait(0);
                        end
                        while not nTable.noclip do
                            Wait(0);
                            if IsVehicleOnAllWheels(clipped) then
                                return SetInvincible(false, clipped);
                            end
                        end
                    else
                        if (IsPedFalling(clipped) and math.abs(1 - GetEntityHeightAboveGround(clipped)) > eps) then
                            while (IsPedStopped(clipped) or not IsPedFalling(clipped)) and not nTable.noclip do
                                Wait(0);
                            end
                        end
                        while not nTable.noclip do
                            Wait(0);
                            if (not IsPedFalling(clipped)) and (not IsPedRagdoll(clipped)) then
                                return SetInvincible(false, clipped);
                            end
                        end
                    end
            end)
        else
            ResetEntityAlpha(noClippingEntity)
        end
    end
end

function getCamDirection()
    local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(PlayerPedId())
    local pitch = GetGameplayCamRelativePitch()
    local coords = vector3(-math.sin(heading * math.pi / 180.0), math.cos(heading * math.pi / 180.0), math.sin(pitch * math.pi / 180.0))
    local len = math.sqrt((coords.x * coords.x) + (coords.y * coords.y) + (coords.z * coords.z))
    
    if len ~= 0 then
        coords = coords / len
    end
    
    return coords
end

local eps = 0.01
local speed = 0.5
local input = vector3(0, 0, 0)
local previousVelocity = vector3(0, 0, 0)
local breakSpeed = 10.0;
local offset = vector3(0, 0, 1);
local noClippingEntity = PlayerPedId();
function ToggleNoClipMode()
    return NoClip(not nTable.noclip)
end
function IsControlAlwaysPressed(inputGroup, control) return IsControlPressed(inputGroup, control) or IsDisabledControlPressed(inputGroup, control) end
function IsControlAlwaysJustPressed(inputGroup, control) return IsControlJustPressed(inputGroup, control) or IsDisabledControlJustPressed(inputGroup, control) end
function Lerp(a, b, t) return a + (b - a) * t end
function IsPedDrivingVehicle(ped, veh)
    return ped == GetPedInVehicleSeat(veh, -1);
end
function SetInvincible(val, id)
    SetEntityInvincible(id, val)
    return SetPlayerInvincible(id, val)
end

function NoClip(bool)
    if (nTable.noclip == false) then
        
        noClippingEntity = PlayerPedId();
        
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            local veh = GetVehiclePedIsIn(PlayerPedId(), false);
            if IsPedDrivingVehicle(PlayerPedId(), veh) then
                noClippingEntity = veh;
            end
        end
        
        local isVeh = IsEntityAVehicle(noClippingEntity);
        
        nTable.noclip = bool;
        SetUserRadioControlEnabled(not nTable.noclip);
        
        if (nTable.noclip) then
            SetEntityAlpha(noClippingEntity, 51, 0)
            CreateThread(function()
                    
                    local clipped = noClippingEntity
                    local pPed = PlayerPedId();
                    local isClippedVeh = isVeh;

                    
                    SetInvincible(true, clipped);

                    if not isClippedVeh then
                        ClearPedTasksImmediately(pPed)
                    end
                    
                    while nTable.noclip do
                        Wait(0);
                        
                        FreezeEntityPosition(clipped, true);
                        
                        SetEntityCollision(clipped, false, false);
                        SetEntityAlpha(entity, 255, false)
                        SetEntityVisible(clipped, false, false);
                        SetLocalPlayerVisibleLocally(true);
                        SetEntityAlpha(clipped, 51, false)
                        
                        SetEveryoneIgnorePlayer(pPed, true);
                        SetPoliceIgnorePlayer(pPed, true);

                        SetPoliceIgnorePlayer(playerPed, false)
                        FreezeEntityPosition(entity, false)
                        SetEntityCollision(entity, true, true)
                        SetEntityVisible(entity, true, false)

                        
                        input = vector3(GetControlNormal(0, 30), GetControlNormal(0, 31), (IsControlAlwaysPressed(1, 38) and 1) or ((IsControlAlwaysPressed(1, 44) and -1) or 0))
                        speed = ((IsControlAlwaysPressed(1, 21) and NoClipSpeedMax) or normalSpeed) * ((isClippedVeh and 2.75) or 1)
                        
                        SetEntityRotation(noClippingEntity, GetGameplayCamRot(0), 0, false)
                        local forward, right, up, c = GetEntityMatrix(noClippingEntity);
                        previousVelocity = Lerp(previousVelocity, (((right * input.x * speed) + (up * -input.z * speed) + (forward * -input.y * speed))), Timestep() * breakSpeed);
                        c = c + previousVelocity
                        SetEntityCoords(noClippingEntity, c - offset, true, true, true, false)
                    
                    end
                    Wait(0);
                    
                    FreezeEntityPosition(clipped, false);
                    SetEntityCollision(clipped, true, true);

                    SetEntityVisible(clipped, true, false);
                    SetLocalPlayerVisibleLocally(true);
                    ResetEntityAlpha(clipped);
                    
                    SetEveryoneIgnorePlayer(pPed, false);
                    SetPoliceIgnorePlayer(pPed, false);
                    ResetEntityAlpha(clipped);

                    
                    Wait(500);
                    
                    if isClippedVeh then
                        while (not IsVehicleOnAllWheels(clipped)) and not nTable.noclip do
                            Wait(0);
                        end
                        while not nTable.noclip do
                            Wait(0);
                            if IsVehicleOnAllWheels(clipped) then
                                return SetInvincible(false, clipped);
                            end
                        end
                    else
                        if (IsPedFalling(clipped) and math.abs(1 - GetEntityHeightAboveGround(clipped)) > eps) then
                            while (IsPedStopped(clipped) or not IsPedFalling(clipped)) and not nTable.noclip do
                                Wait(0);
                            end
                        end
                        while not nTable.noclip do
                            Wait(0);
                            if (not IsPedFalling(clipped)) and (not IsPedRagdoll(clipped)) then
                                return SetInvincible(false, clipped);
                            end
                        end
                    end
            end)
        else
            ResetEntityAlpha(noClippingEntity)
        end
    end
end

function ResetNoClipState(entity, playerPed)
    SetEntityAlpha(entity, 255, false)
    SetEntityInvincible(entity, false)
    SetEveryoneIgnorePlayer(playerPed, false)
    SetPoliceIgnorePlayer(playerPed, false)
    FreezeEntityPosition(entity, false)
    SetEntityCollision(entity, true, true)
    SetEntityVisible(entity, true, false)
end

function IsControlAlwaysPressed(inputGroup, control)
    return IsControlPressed(inputGroup, control) or IsDisabledControlPressed(inputGroup, control)
end

function IsPedDrivingVehicle(ped, veh)
    return ped == GetPedInVehicleSeat(veh, -1)
end