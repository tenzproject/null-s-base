if IsDuplicityVersion() then return end

ESX = exports["null-core"]:getSharedObject()

local driveSchoolOpen = false
local practiceActive = false
local practiceStep = 0
local practiceErrors = 0
local practiceMaxSpeed = nil
local practiceLicenseId = nil
local practiceVehicle = nil
local practiceBlip = nil

function OpenDriveSchool()
    if driveSchoolOpen then return end
    driveSchoolOpen = true

    ESX.TriggerServerCallback('null:driveschool:getData', function(licenses, cash, bank)
        SendNUIMessage({
            action = 'driveSchool:open',
            data = {
                licenses = licenses,
                questions = Config.DriveSchool.Questions,
                minScore = Config.DriveSchool.MinTheoryScore,
                maxErrors = Config.DriveSchool.MaxErrors,
                cash = cash,
                bank = bank,
                brand = Config.DriveSchool.Brand,
            }
        })
        SetNuiFocus(true, true)
    end)
end

function CloseDriveSchool()
    if not driveSchoolOpen then return end
    driveSchoolOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'driveSchool:close', data = {} })
end

RegisterNUICallback('driveSchool:close', function(_, cb)
    cb({})
    CloseDriveSchool()
end)

RegisterNUICallback('driveSchool:removeMoney', function(data, cb)
    cb({})
    if not data or not data.account or not data.amount then return end
    TriggerServerEvent('null:driveschool:removeMoney', data.account, data.amount)
end)

RegisterNUICallback('driveSchool:theoryComplete', function(data, cb)
    cb({})
    if not data or not data.license then return end
    TriggerServerEvent('null:driveschool:giveLicense', data.license)
end)

RegisterNUICallback('driveSchool:practiceComplete', function(data, cb)
    cb({})
    if not data or not data.license then return end
    TriggerServerEvent('null:driveschool:giveLicense', data.license)
end)

RegisterNUICallback('driveSchool:startPractice', function(data, cb)
    cb({})
    if not data or not data.licenseId then return end

    driveSchoolOpen = false
    SetNuiFocus(false, false)

    local licConfig = nil
    for _, lic in ipairs(Config.DriveSchool.License) do
        if lic.id == data.licenseId then
            licConfig = lic
            break
        end
    end
    if not licConfig or not licConfig.vehicle then return end

    practiceLicenseId = data.licenseId
    practiceStep = 0
    practiceErrors = 0
    practiceActive = true

    local veh = licConfig.vehicle
    ESX.Game.SpawnVehicle(veh.model, veh.coords, veh.heading, function(vehicle)
        practiceVehicle = vehicle
        SetVehicleNumberPlateText(vehicle, veh.plate)
        SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
        AdvancePracticeStep()
    end)
end)

function AdvancePracticeStep()
    practiceStep = practiceStep + 1

    local routeIndex = math.random(1, #Config.DriveSchool.PracticeCoords)
    local route = Config.DriveSchool.PracticeCoords[routeIndex]
    local checkpoint = route[practiceStep]

    if not checkpoint then
        EndPractice()
        return
    end

    practiceMaxSpeed = checkpoint.speedLimit or nil
    local coords = checkpoint.coordinate
    
    if practiceBlip then
        RemoveBlip(practiceBlip)
        practiceBlip = nil
    end
    
    SetNewWaypoint(coords.x, coords.y)
    
    practiceBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(practiceBlip, 1)
    SetBlipColour(practiceBlip, 5)
    SetBlipRoute(practiceBlip, true)
    SetBlipRouteColour(practiceBlip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Checkpoint " .. practiceStep .. "/" .. #route)
    EndTextCommandSetBlipName(practiceBlip)

    SendNUIMessage({
        action = 'driveSchool:practiceUpdate',
        data = {
            step = practiceStep,
            totalSteps = #route,
            errors = practiceErrors,
            maxErrors = Config.DriveSchool.MaxErrors,
            speedLimit = practiceMaxSpeed,
        }
    })

    Citizen.CreateThread(function()
        while practiceActive do
            Citizen.Wait(0)

            DrawMarker(2, coords.x, coords.y, coords.z, 0, 0, 0, 0, 0, 0,
                1.0, 1.0, 1.0, 255, 255, 255, 100, false, true, 2, false, false, false, false)

            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if vehicle and vehicle ~= 0 then
                local speed = GetEntitySpeed(vehicle) * Config.DriveSchool.SpeedMultiplier
                if practiceMaxSpeed and speed > practiceMaxSpeed then
                    practiceErrors = practiceErrors + 1
                    ESX.ShowNotification("~r~Vous allez trop vite, ralentissez!")

                    SendNUIMessage({
                        action = 'driveSchool:practiceUpdate',
                        data = {
                            step = practiceStep,
                            totalSteps = #route,
                            errors = practiceErrors,
                            maxErrors = Config.DriveSchool.MaxErrors,
                            speedLimit = practiceMaxSpeed,
                        }
                    })

                    Wait(1000)
                end
            end

            local dist = #(coords - GetEntityCoords(PlayerPedId()))
            if dist < 2.0 then
                AdvancePracticeStep()
                return
            end
        end
    end)
end

function EndPractice()
    practiceActive = false

    if practiceVehicle and DoesEntityExist(practiceVehicle) then
        ESX.Game.DeleteVehicle(practiceVehicle)
    end
    practiceVehicle = nil
    
    if practiceBlip then
        RemoveBlip(practiceBlip)
        practiceBlip = nil
    end
    ClearGpsPlayerWaypoint()

    driveSchoolOpen = true
    SetNuiFocus(true, true)

    local passed = practiceErrors < Config.DriveSchool.MaxErrors

    SendNUIMessage({
        action = 'driveSchool:practiceResult',
        data = {
            passed = passed,
            errors = practiceErrors,
            maxErrors = Config.DriveSchool.MaxErrors,
            licenseId = practiceLicenseId,
        }
    })

    if passed then
        TriggerServerEvent('null:driveschool:giveLicense', practiceLicenseId)
    end

    practiceLicenseId = nil
    practiceStep = 0
    practiceErrors = 0
end


RegisterNetEvent('null:driveschool:updateData', function(licenses)
    SendNUIMessage({
        action = 'driveSchool:updateLicenses',
        data = { licenses = licenses }
    })
end)
