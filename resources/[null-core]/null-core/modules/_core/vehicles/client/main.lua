local function GetPlayerData()
    local state = exports['null-core']:GetPlayerState()
    if state then return state end
    
    return {
        ped = PlayerPedId(),
        playerId = PlayerId(),
        coords = GetEntityCoords(PlayerPedId()),
        isInVehicle = IsPedInAnyVehicle(PlayerPedId(), false),
        vehicle = GetVehiclePedIsIn(PlayerPedId(), false),
    }
end

CreateThread(LPH_NO_VIRTUALIZE(function()
    if not Config._core.Vehicles.AntiCarKill then return end
    
    local lastVehicle = 0
    
    while true do
        local sleepTime = 500
        local player = GetPlayerData()
        
        if not player.isInVehicle then
            local closestVeh = GetClosestVehicle(
                player.coords.x, 
                player.coords.y, 
                player.coords.z, 
                Config._core.Vehicles.AntiCarKillRadius, 
                0, 71
            )
            
            if closestVeh ~= 0 then
                sleepTime = 100 
                SetEntityNoCollisionEntity(closestVeh, player.ped, true)
                lastVehicle = closestVeh
            elseif lastVehicle ~= 0 and DoesEntityExist(lastVehicle) then
                SetEntityNoCollisionEntity(lastVehicle, player.ped, false)
                lastVehicle = 0
            end
        else
            sleepTime = 1000  
        end
        
        Wait(sleepTime)
    end
end))
 
CreateThread(LPH_NO_VIRTUALIZE(function()
    local sleepTime = 2000
    
    while true do
        Wait(sleepTime)
        
        local player = GetPlayerData()
        
        if player.isInVehicle and player.vehicle ~= 0 then
            sleepTime = 0
            local model = GetEntityModel(player.vehicle)
            
            DisablePlayerVehicleRewards(player.playerId)
            
            if PlayerState.realisticDrive then
                if GetFollowVehicleCamViewMode() == 1 or GetFollowVehicleCamViewMode() == 2 then
                    SetFollowVehicleCamViewMode(4)
                end
            end

            if Config._core.Vehicles.DisableDriveBy then
                local isDriver = GetPedInVehicleSeat(player.vehicle, -1) == player.ped
                local canDriveBy = not isDriver or Config._core.Vehicles.BypassDriveBy[model]
                SetPlayerCanDoDriveBy(player.playerId, canDriveBy)
            end
            
            if Config._core.Vehicles.DisableVehicleWeapons and DoesVehicleHaveWeapons(player.vehicle) then
                local vehName = GetDisplayNameFromVehicleModel(model)
                if not Config._core.Vehicles.WhitelistWeaponVehicles[vehName] then
                    local hasWeapon, weaponHash = GetCurrentPedVehicleWeapon(player.ped)
                    if hasWeapon then
                        DisableVehicleWeapon(true, weaponHash, player.vehicle, player.ped)
                        SetCurrentPedWeapon(player.ped, `WEAPON_UNARMED`)
                    end
                end
            end
            
            if Config._core.Vehicles.DisableAirControl and not Config._core.Vehicles.BypassAirControl[model] then
                if IsEntityInAir(player.vehicle) and IsVehicleOnAllWheels(player.vehicle) == false then
                    if not IsThisModelABoat(model) and 
                       not IsThisModelAHeli(model) and 
                       not IsThisModelAPlane(model) and
                       not IsThisModelABike(model) and
                       not IsThisModelABicycle(model) then
                        DisableControlAction(0, 59, true) -- Left/Right
                        DisableControlAction(0, 60, true) -- Up/Down
                    end
                end
            end
            
            if not Config._core.Vehicles.BypassAirControl[model] then
                DisableControlAction(0, 354, true) -- Special Ability Secondary
                DisableControlAction(0, 351, true) -- Vehicle Rocket Boost
                DisableControlAction(0, 350, true) -- Vehicle Fly Boost
                DisableControlAction(0, 357, true) -- Vehicle Fly Attack
            end
        else
            sleepTime = 2000
        end
    end
end))

local undriveableMenuOpen = false

local function OpenUndriveableMenu(vehicle)
    if undriveableMenuOpen then return end
    
    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    if not NetworkDoesEntityExistWithNetworkId(vehicleNetId) then return end
    if NetworkGetEntityOwner(vehicle) ~= PlayerId() then return end
    
    undriveableMenuOpen = true
    
    if lib and lib.registerContext then
        lib.registerContext({
            id = 'vehicle_broken_menu',
            title = 'Véhicule en panne',
            options = {
                {
                    title = 'Contacter un mécanicien',
                    description = 'Appeler un mécanicien pour réparer votre véhicule',
                    icon = 'wrench',
                    onSelect = function()
                        TriggerServerEvent('mecano:callMechanic', vehicleNetId, false)
                        undriveableMenuOpen = false
                    end
                }
            }
        })
        lib.showContext('vehicle_broken_menu')
    else
        ESX.ShowNotification('Votre véhicule est en panne ! Contactez un mécanicien.')
        undriveableMenuOpen = false
    end
end

CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        local sleepTime = 2000
        local player = GetPlayerData()
        
        if player.isInVehicle and player.vehicle ~= 0 then
            local engineHealth = math.floor(GetVehicleEngineHealth(player.vehicle) / 10)
            
            if engineHealth <= 10 then
                sleepTime = 500 
                SetVehicleEngineOn(player.vehicle, false, true, true)
                SetVehicleIndicatorLights(player.vehicle, 0, true)
                SetVehicleIndicatorLights(player.vehicle, 1, true)
                OpenUndriveableMenu(player.vehicle)
            else
                sleepTime = 500 
            end
        end
        
        Wait(sleepTime)
    end
end))

AddEventHandler('null:player:exitVehicle', function()
    undriveableMenuOpen = false
end)

null.InitPrint('^2Vehicles module loaded^7')
