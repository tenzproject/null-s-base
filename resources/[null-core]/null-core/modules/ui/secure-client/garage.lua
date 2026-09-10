--[[
    Garage UI — Client NUI Bridge
    Replaces RageUI menus with React-based garage interface.
    
    This file ONLY handles the NUI bridge. The original garage logic
    (markers, blips, proximity, spawn, store, etc.) stays in gameplay/garage/client/main.lua.
    
    We override openMenuGarage, OpenFourriereMenu, and openRangerVehicle
    to open the React UI instead of RageUI menus.
]]

local GarageUIOpen = false
local frozenVehicleEntity = nil

-- ============================================================
-- NUI BRIDGE
-- ============================================================

local function SendGarageNUI(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local function CloseGarageUI(fromNUI)
    if not GarageUIOpen then return end
    GarageUIOpen = false
    if not fromNUI then -- Disable for trigger NUI _core bridge
        SendGarageNUI("garage:close")
    end
    SetNuiFocus(false, false)
    FreezeEntityPosition(PlayerPedId(), false)
    if frozenVehicleEntity and DoesEntityExist(frozenVehicleEntity) then
        FreezeEntityPosition(frozenVehicleEntity, false)
    end
    frozenVehicleEntity = nil
end

-- ============================================================
-- BUILD VEHICLE LIST with extra info (spawned, distance)
-- ============================================================

local function BuildVehicleList(ownedCars, ownedCarsJobs, ownedCarsOrg)
    local vehicles = {}
    local playerCoords = GetEntityCoords(PlayerPedId())

    local function addVehicle(v, category)
        local spawned = false
        local distance = nil

        -- Check if vehicle is spawned via VehicleSort
        if VehicleSort and VehicleSort[v.plate] then
            local entity = VehicleSort[v.plate].Entity
            if entity and DoesEntityExist(entity) then
                spawned = true
                local vehCoords = GetEntityCoords(entity)
                distance = #(playerCoords - vehCoords)
            end
        end

        local modelHash = v.vehicle and v.vehicle.model or 0
        local modelName = ""
        if modelHash ~= 0 then
            modelName = string.lower(GetDisplayNameFromVehicleModel(modelHash))
        end

        table.insert(vehicles, {
            plate = v.plate or (v.vehicle and v.vehicle.plate) or "UNKNOWN",
            model = modelName,
            modelLabel = modelHash ~= 0 and GetLabelText(GetDisplayNameFromVehicleModel(modelHash)) or "Inconnu",
            label = v.label,
            type = v.type or "car",
            owner = v.owner or "",
            ownerCategory = category,
            state = v.state and true or false,
            boutique = v.boutique and true or false,
            spawned = spawned,
            distance = distance,
            vehicle = v.vehicle,
        })
    end

    for _, v in pairs(ownedCars or {}) do addVehicle(v, "personal") end
    for _, v in pairs(ownedCarsJobs or {}) do addVehicle(v, "job") end
    for _, v in pairs(ownedCarsOrg or {}) do addVehicle(v, "org") end

    return vehicles
end

-- ============================================================
-- OPEN GARAGE (replaces openMenuGarage)
-- ============================================================

local currentSpawnPoint = nil
local currentGarageType = nil
local currentGarageId = nil

function openGarage(SpawnPoint, TypeGarage, garageid)
    if GarageUIOpen then return end

    -- Find the garage in GarageList to get the real SpawnPoint
    local garageData = nil
    if GarageList then
        for k, v in pairs(GarageList) do
            if v.id == garageid then
                garageData = v
                break
            end
        end
    end

    -- Use the garage's SpawnPoint if found, otherwise fallback to the provided position
    if garageData and garageData.SpawnPoint then
        currentSpawnPoint = vector3(garageData.SpawnPoint.x, garageData.SpawnPoint.y, garageData.SpawnPoint.z)
    else
        currentSpawnPoint = SpawnPoint
    end

    currentGarageType = TypeGarage
    currentGarageId = garageid

    ESX.PlayerData = ESX.GetPlayerData()

    ESX.TriggerServerCallback('null:getOwnedCars', function(ownedCars, ownedCarsJobs, ownedCarsOrg)
        local vehicles = BuildVehicleList(ownedCars, ownedCarsJobs, ownedCarsOrg)

        local hasJob = ESX.PlayerData.job and ESX.PlayerData.job.name ~= "unemployed"
        local hasOrg = ESX.PlayerData.job2 and ESX.PlayerData.job2.name ~= "unemployed2"

        local garageName = garageData and garageData.name or "Parking Public"

        SendGarageNUI("garage:open", {
            mode = "garage",
            garageType = tostring(TypeGarage),
            garageId = tostring(garageid or ""),
            garageName = garageName,
            vehicles = vehicles,
            hasJob = hasJob,
            hasOrg = hasOrg,
            jobLabel = hasJob and ESX.PlayerData.job.label or "",
            orgLabel = hasOrg and ESX.PlayerData.job2.label or "",
            impoundPrice = 0,
            repairPrice = 0,
        })

        GarageUIOpen = true
        SetNuiFocus(true, true)
        FreezeEntityPosition(PlayerPedId(), true)
    end)
end

-- ============================================================
-- OPEN IMPOUND (replaces OpenFourriereMenu)
-- ============================================================

local currentImpoundData = nil

function OpenImpound(TypeGarage, impoundTable)
    if GarageUIOpen then return end

    currentImpoundData = impoundTable

    ESX.PlayerData = ESX.GetPlayerData()

    ESX.TriggerServerCallback('null:getOwnedCars', function(ownedCars, ownedCarsJobs, ownedCarsOrg)
        local vehicles = BuildVehicleList(ownedCars, ownedCarsJobs, ownedCarsOrg)

        local hasJob = ESX.PlayerData.job and ESX.PlayerData.job.name ~= "unemployed"
        local hasOrg = ESX.PlayerData.job2 and ESX.PlayerData.job2.name ~= "unemployed2"

        SendGarageNUI("garage:open", {
            mode = "impound",
            garageType = tostring(TypeGarage),
            garageId = "",
            garageName = "Fourrière",
            vehicles = vehicles,
            hasJob = hasJob,
            hasOrg = hasOrg,
            jobLabel = hasJob and ESX.PlayerData.job.label or "",
            orgLabel = hasOrg and ESX.PlayerData.job2.label or "",
            impoundPrice = 1000,
            repairPrice = 1500,
        })

        GarageUIOpen = true
        SetNuiFocus(true, true)
        FreezeEntityPosition(PlayerPedId(), true)
    end)
end

-- ============================================================
-- OPEN STORE (replaces openRangerVehicle)
-- ============================================================

local currentStorePosition = nil
local currentStoreGarageId = nil

--[[
    DISABLED: Replaced by direct store with animation in main.lua
    The store UI is no longer used, instead we use ShowHelpNotification + E key + fade animation
]]
function openStoreVehicle(position, garageid)
    -- Function disabled - now using direct store with animation
    return
end

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

RegisterNUICallback("garage:close", function(data, cb)
    CloseGarageUI(true)
    cb("ok")
end)

RegisterNUICallback("garage:spawn", function(data, cb)
    if not currentSpawnPoint then cb("error") return end

    local plate = data.plate
    local vehicle = data.vehicle

    -- Check if already spawned
    if VehicleSort and VehicleSort[plate] then
        local entity = VehicleSort[plate].Entity
        if entity and DoesEntityExist(entity) then
            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Ce véhicule est déjà sorti")
            cb("error")
            return
        end
    end

    CloseGarageUI()
    SpawnVehicle(vehicle, plate, currentSpawnPoint)
    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez sorti votre véhicule.")
    cb("ok")
end)

RegisterNUICallback("garage:impoundSpawn", function(data, cb)
    if not currentImpoundData then cb("error") return end

    local plate = data.plate
    local vehicle = data.vehicle

    -- Check if already spawned
    if VehicleSort and VehicleSort[plate] then
        local entity = VehicleSort[plate].Entity
        if entity and DoesEntityExist(entity) then
            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Ce véhicule est déjà sorti")
            cb("error")
            return
        end
    end

    ESX.TriggerServerCallback('null:storeVehicleFourriere', function(valid)
        if valid then
            CloseGarageUI()
            SpawnVehicle(vehicle, plate, currentImpoundData.PointSpawn)
            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous avez récupéré votre véhicule à la fourrière.")
        else
            SendGarageNUI("garage:feedback", { message = "Argent insuffisant" })
        end
    end, vehicle)
    cb("ok")
end)

RegisterNUICallback("garage:store", function(data, cb)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then cb("error") return end

    local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
    if not vehicleProps then cb("error") return end

    local NewPosition = Vdist2(GetEntityCoords(PlayerPedId(), false), currentStorePosition)
    if NewPosition > 20 then
        ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Vous êtes trop loin du point")
        cb("error")
        return
    end

    ESX.TriggerServerCallback('null:storevehicle', function(valid)
        if valid then
            SetVehicleFixed(vehicle)
            SetVehicleDeformationFixed(vehicle)
            SetVehicleUndriveable(vehicle, false)
            SetVehicleEngineHealth(vehicle, 1000.0)
            CloseGarageUI()
            PutVehicleInGarage(vehicle, vehicleProps)
        else
            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Ce véhicule ne vous appartient pas")
        end
    end, vehicleProps, currentStoreGarageId, vehicleProps.displayname)
    cb("ok")
end)

RegisterNUICallback("garage:storeWithRepair", function(data, cb)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then cb("error") return end

    local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
    if not vehicleProps then cb("error") return end

    ESX.TriggerServerCallback('null:storevehiclewithmoney', function(valid)
        if valid then
            CloseGarageUI()
            PutVehicleInGarage(vehicle, vehicleProps)
        else
            ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Véhicule non reconnu ou argent insuffisant")
        end
    end, vehicleProps, currentStoreGarageId)
    cb("ok")
end)

RegisterNUICallback("garage:rename", function(data, cb)
    TriggerServerEvent('null:renameVehicle', data.owner, data.vehicle, data.label)
    cb("ok")
end)

RegisterNUICallback("garage:give", function(data, cb)
    local player, closestplayer = ESX.Game.GetClosestPlayer()
    if player == -1 or closestplayer > 3.0 then
        SendGarageNUI("garage:feedback", { message = "Aucun joueur à proximité" })
        cb("error")
        return
    end

    TriggerServerEvent('Null:changevehicleowner', GetPlayerServerId(player), {
        plate = data.plate,
        vehicle = data.vehicle,
        owner = data.owner,
    })
    CloseGarageUI()
    ESX.ShowAdvancedNotification(ESX.Config("serverColor")..ESX.Config("serverName"), "Information", "Véhicule donné avec succès")
    cb("ok")
end)

RegisterNUICallback("garage:assign", function(data, cb)
    local vehicleData = {
        plate = data.plate,
        vehicle = data.vehicle,
        owner = data.owner or "",
        boutique = false,
    }
    TriggerServerEvent('Null:AttribuerVehicule', data.type, vehicleData)
    CloseGarageUI()
    cb("ok")
end)

RegisterNUICallback("garage:locate", function(data, cb)
    local plate = data.plate
    if VehicleSort and VehicleSort[plate] then
        local entity = VehicleSort[plate].Entity
        if entity and DoesEntityExist(entity) then
            local coords = GetEntityCoords(entity)
            SetNewWaypoint(coords.x, coords.y)
        end
    end
    cb("ok")
end)

-- ============================================================
-- OVERRIDE original functions to use new UI
-- ============================================================

-- Override the original openMenuGarage
openMenuGarage = openGarage

-- Override the original OpenFourriereMenu
OpenFourriereMenu = OpenImpound

-- Override the original openRangerVehicle
-- DISABLED: Now using direct store with animation in main.lua
-- openRangerVehicle = openStoreVehicle
