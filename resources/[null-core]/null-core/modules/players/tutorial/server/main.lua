-- ============================================================================
-- TUTORIAL SYSTEM - Server Side (v2)
-- Manages tutorial state, BMX item, vehicle garage give, completion tracking
-- ============================================================================

local tutorialPlayers = {} -- [source] = { instanceId, step, path }
local tutorialSchemaReady = false

local function ensureTutorialSchema(cb)
    MySQL.Async.fetchScalar([[
        SELECT COUNT(*)
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'users'
          AND COLUMN_NAME = 'tutorial_completed'
    ]], {}, function(count)
        if tonumber(count) == 0 then
            MySQL.Async.execute('ALTER TABLE `users` ADD COLUMN `tutorial_completed` TINYINT(1) NOT NULL DEFAULT 0', {}, function()
                tutorialSchemaReady = true
                if cb then cb() end
            end)
        else
            tutorialSchemaReady = true
            if cb then cb() end
        end
    end)
end

-- ============================================================================
-- CHECK IF PLAYER NEEDS TUTORIAL
-- ============================================================================

ESX.RegisterServerCallback('null:tutorial:needsTutorial', function(source, cb)
    if not Config.Tutorial or not Config.Tutorial.enabled then
        cb(false)
        return
    end

    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        cb(false)
        return
    end

    ensureTutorialSchema(function()
        MySQL.Async.fetchScalar('SELECT tutorial_completed FROM users WHERE identifier = @identifier', {
            ['@identifier'] = xPlayer.identifier
        }, function(result)
            cb(result == 0 or result == nil)
        end)
    end)
end)

-- ============================================================================
-- START TUTORIAL
-- ============================================================================

RegisterNetEvent('null:tutorial:start', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local cfg = Config.Tutorial

    tutorialPlayers[src] = {
        step = 'welcome',
        path = nil,
        startTime = os.time()
    }

    -- Resolve job center coords from Config
    local jobCenterCoords = cfg.jobCenter.coords
    if not jobCenterCoords and Config.FreeJobs and Config.FreeJobs.Agence and Config.FreeJobs.Agence.InteractionCoords then
        local ic = Config.FreeJobs.Agence.InteractionCoords
        jobCenterCoords = vector3(ic.x, ic.y, ic.z)
    end

    TriggerClientEvent('null:tutorial:started', src, {
        jobCenterCoords = jobCenterCoords,
    })
end)

-- ============================================================================
-- UPDATE STEP
-- ============================================================================

RegisterNetEvent('null:tutorial:updateStep', function(step, path)
    local src = source
    if tutorialPlayers[src] then
        tutorialPlayers[src].step = step
        if path then
            tutorialPlayers[src].path = path
        end
    end
end)

-- ============================================================================
-- SKIP TUTORIAL
-- ============================================================================

RegisterNetEvent('null:tutorial:skip', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if tutorialPlayers[src] then
        tutorialPlayers[src] = nil
    end

    MySQL.Async.execute('UPDATE users SET tutorial_completed = 1 WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    })

    TriggerClientEvent('null:tutorial:ended', src)
end)

-- ============================================================================
-- COMPLETE TUTORIAL
-- ============================================================================

RegisterNetEvent('null:tutorial:complete', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    if tutorialPlayers[src] then
        tutorialPlayers[src] = nil
    end

    MySQL.Async.execute('UPDATE users SET tutorial_completed = 1 WHERE identifier = @identifier', {
        ['@identifier'] = xPlayer.identifier
    })

    TriggerClientEvent('null:tutorial:ended', src)
end)

-- ============================================================================
-- GIVE BMX ITEM
-- ============================================================================

RegisterNetEvent('null:tutorial:giveBmx', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local bmx = Config.Tutorial.bmx.itemName
    xPlayer.addInventoryItem(bmx, 1)
    xPlayer.showNotification(Config.Tutorial.messages.bmxGiven)
end)

-- ============================================================================
-- BMX USABLE ITEM (register as usable → spawn BMX vehicle client-side)
-- ============================================================================

Citizen.CreateThread(function()
    Wait(2000)
    local bmx = Config.Tutorial.bmx.itemName
    
    ESX.RegisterUsableItem(bmx, function(source)
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return end
        
        -- Remove item from inventory
        xPlayer.removeInventoryItem(bmx, 1)
        
        -- Trigger client to spawn BMX
        TriggerClientEvent('null:tutorial:spawnBmx', src)
    end)
end)

-- ============================================================================
-- GIVE VEHICLE TO GARAGE (like admin giveGarageVeh)
-- ============================================================================

RegisterNetEvent('null:tutorial:giveGarageVehicle', function(vehicleProps, vehicleModel)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- Check if player already owns a tutorial vehicle
    local alreadyHas = false
    for plate, vData in pairs(SaveData.json["owned_vehicles"] or {}) do
        if vData.owner == xPlayer.identifier and vData.model == vehicleModel then
            alreadyHas = true
            break
        end
    end

    if alreadyHas then
        return
    end

    -- Register the vehicle in the garage (same format as AdminMenu:giveGarageVeh)
    SaveData.json["owned_vehicles"][string.upper(vehicleProps.plate)] = {
        owner = xPlayer.identifier,
        model = vehicleModel,
        plate = string.upper(vehicleProps.plate),
        vehicle = vehicleProps,
        datetoremove = nil,
        label = vehicleModel,
        coffre = {},
        type = "car",
        state = true,
        boutique = false,
        garage = true,
    }
end)

-- ============================================================================
-- PICKUP BMX (from context menu ALT)
-- ============================================================================

RegisterNetEvent('null:tutorial:pickupBmx', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    
    local bmx = Config.Tutorial.bmx.itemName
    xPlayer.addInventoryItem(bmx, 1)
end)

-- ============================================================================
-- CLEANUP ON DISCONNECT
-- ============================================================================

AddEventHandler('playerDropped', function()
    local src = source
    if tutorialPlayers[src] then
        tutorialPlayers[src] = nil
    end
end)

-- ============================================================================
-- SQL MIGRATION
-- ============================================================================

Citizen.CreateThread(function()
    Wait(5000)
    ensureTutorialSchema()
    
    -- Add tutorial_bmx item if it doesn't exist
    local bmx = Config.Tutorial.bmx.itemName
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM items WHERE name = @name', {
        ['@name'] = bmx
    }, function(count)
        if count == 0 then
            MySQL.Async.execute('INSERT INTO items (name, label, weight) VALUES (@name, @label, @weight)', {
                ['@name'] = bmx,
                ['@label'] = 'BMX',
                ['@weight'] = 1,
            })
        end
    end)
end)

null.InitPrint('Tutorial system (server) loaded')
