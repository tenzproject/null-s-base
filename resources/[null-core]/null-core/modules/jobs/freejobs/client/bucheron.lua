
local IsWorkingBucheron = false
local BucheronPed = nil
local BucheronBlip = nil
local currentStump = nil
local StumpSpawned = {}
local StumpBlip = nil
local bonus = 0
local finalcount = 0
local hatchetGiven = false
local currentVehicle = nil
local vehicleBlip = nil

local cfg = Config.FreeJobs.Bucheron

local function loadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(10)
    end
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        Citizen.Wait(100)
    end
    return hash
end

-- Spawn the bûcheron PED
Citizen.CreateThread(function()
    local hash = loadModel(cfg.PedModel)
    BucheronPed = CreatePed(0, hash, cfg.PedCoords.x, cfg.PedCoords.y, cfg.PedCoords.z, cfg.PedCoords.w, false, false)
    SetBlockingOfNonTemporaryEvents(BucheronPed, true)
    SetEntityInvincible(BucheronPed, true)
    FreezeEntityPosition(BucheronPed, true)
    TaskStartScenarioInPlace(BucheronPed, "WORLD_HUMAN_CLIPBOARD", 0, true)
end)

-- 3D Interaction on PED
Citizen.CreateThread(function()
    while not BucheronPed do Wait(500) end

    Add3DInteraction({
        id = 'freejob_bucheron',
        coords = vector3(cfg.Ped3DInteractionCoords.x, cfg.Ped3DInteractionCoords.y, cfg.Ped3DInteractionCoords.z),
        maxDistance = 8.0,
        maxDistance2 = 2.5,
        type = 'multi',
        text = {
            title = 'Bûcheron',
            lines = {
                {
                    id = 'start',
                    left = 'Commencer le travail',
                    key = 'E',
                    action = function()
                        if IsWorkingBucheron then return end
                        StartBucheronJob()
                    end,
                    canSee = function(cb) cb(not IsWorkingBucheron) end,
                },
                {
                    id = 'paye',
                    left = 'Prendre sa paye',
                    key = 'E',
                    action = function()
                        if not IsWorkingBucheron then return end
                        CollectBucheronPay()
                    end,
                    canSee = function(cb) cb(IsWorkingBucheron and finalcount > 0) end,
                },
                {
                    id = 'quit',
                    left = 'Quitter le travail',
                    key = 'G',
                    action = function()
                        if not IsWorkingBucheron then return end
                        QuitBucheronJob()
                    end,
                    canSee = function(cb) cb(IsWorkingBucheron) end,
                },
            },
        },
    })
end)

function StartBucheronJob()
    IsWorkingBucheron = true
    finalcount = 0
    bonus = 0
    hatchetGiven = true

    -- Find free vehicle spawn spot
    local spawnPos = nil
    for _, v in pairs(cfg.VehicleSpawns) do
        if ESX.Game.IsSpawnPointClear(vector3(v.pos.x, v.pos.y, v.pos.z), 3.0) then
            spawnPos = v.pos
            break
        end
    end

    if not spawnPos then
        ESX.ShowNotification("~r~Toutes les places de parking sont prises !")
        IsWorkingBucheron = false
        return
    end

    -- Spawn vehicle from config
    RequestModel(GetHashKey(cfg.VehicleModel))
    while not HasModelLoaded(GetHashKey(cfg.VehicleModel)) do Wait(0) end

    currentVehicle = CreateVehicle(GetHashKey(cfg.VehicleModel), spawnPos.x, spawnPos.y, spawnPos.z, spawnPos.w, false, true)
    SetVehicleNumberPlateText(currentVehicle, cfg.VehiclePlate .. math.random(100, 999))
    SetVehicleFuelLevel(currentVehicle, 100.0)
    SetVehicleDirtLevel(currentVehicle, 0.0)

    -- Limit speed from config
    SetVehicleMaxSpeed(currentVehicle, cfg.VehicleMaxSpeed)

    -- Vehicle blip from config
    vehicleBlip = AddBlipForEntity(currentVehicle)
    SetBlipSprite(vehicleBlip, cfg.VehicleBlip.Sprite)
    SetBlipColour(vehicleBlip, cfg.VehicleBlip.Color)
    SetBlipScale(vehicleBlip, cfg.VehicleBlip.Scale)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(cfg.VehicleBlip.Label)
    EndTextCommandSetBlipName(vehicleBlip)

    -- Give hatchet weapon (melee only, disable against players)
    GiveWeaponToPed(PlayerPedId(), GetHashKey('WEAPON_HATCHET'), 1, false, true)
    SetCurrentPedWeapon(PlayerPedId(), GetHashKey('WEAPON_HATCHET'), true)

    -- Apply outfit
    TriggerEvent('Null:skinchanger:getSkin', function(skin)
        TriggerEvent('Null:skinchanger:loadClothes', skin, cfg.Tenue)
    end)

    -- Open HUD
    SendNUIMessage({
        action = 'freejobHUD:open',
        data = {
            jobName = 'Bûcheron',
            jobIcon = 'axe',
            tasks = 0,
            bonus = 0,
            reward = 0,
            rewardPerTask = Config.FreeJobs.Rewards.Bucheron,
        }
    })

    SpawnStump()
    TriggerServerEvent("Null:jobs:startActivity")

    -- Disable attacking players with hatchet
    Citizen.CreateThread(function()
        while IsWorkingBucheron do
            Wait(0)
            DisablePlayerFiring(PlayerId(), true)
            -- Allow melee only on the prop (not on players)
            local _, targetEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())
            if targetEntity and IsEntityAPed(targetEntity) and targetEntity ~= PlayerPedId() then
                DisableControlAction(0, 140, true) -- melee attack light
                DisableControlAction(0, 141, true) -- melee attack heavy
                DisableControlAction(0, 142, true) -- melee attack alternate
                DisableControlAction(0, 24, true)  -- attack
                DisableControlAction(0, 25, true)  -- aim
            end
        end
    end)

    -- Distance check
    Citizen.CreateThread(function()
        while IsWorkingBucheron do
            Wait(5000)
            local coords = GetEntityCoords(PlayerPedId())
            local dist = #(coords - vector3(cfg.PedCoords.x, cfg.PedCoords.y, cfg.PedCoords.z))
            if dist > cfg.MaxDistance then
                QuitBucheronJob()
                ESX.ShowNotification("~r~Vous vous êtes trop éloigné, mission abandonnée !")
            end
        end
    end)
end

function SpawnStump()
    local props = cfg.Props
    local random = math.random(1, #props)
    local v = props[random]

    local hash = loadModel(v.props)
    currentStump = CreateObject(hash, v.pos.x, v.pos.y, v.pos.z, false, true, true)
    SetEntityAsMissionEntity(currentStump, true, true)

    if StumpBlip then RemoveBlip(StumpBlip) end
    StumpBlip = AddBlipForEntity(currentStump)
    SetBlipSprite(StumpBlip, cfg.StumpBlip.Sprite)
    SetBlipColour(StumpBlip, cfg.StumpBlip.Color)
    SetBlipScale(StumpBlip, cfg.StumpBlip.Scale)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(cfg.StumpBlip.Label)
    EndTextCommandSetBlipName(StumpBlip)

    table.insert(StumpSpawned, { id = currentStump, pos = v.pos })

    -- Send marker to NUI
    SendNUIMessage({
        action = 'freejobMarker:add',
        data = {
            id = 'stump_' .. currentStump,
            x = v.pos.x,
            y = v.pos.y,
            z = v.pos.z + cfg.MarkerOffset,
            label = 'Arbre',
        }
    })

    -- Interaction loop for this stump
    Citizen.CreateThread(function()
        local stumpEntity = currentStump
        while IsWorkingBucheron and DoesEntityExist(stumpEntity) do
            Wait(0)
            local ply = PlayerPedId()
            local coordsply = GetEntityCoords(ply)
            local stumpcoords = GetEntityCoords(stumpEntity)
            local dist = #(coordsply - stumpcoords)

            -- Update marker screen position for NUI
            if dist < 50.0 then
                local onScreen, sx, sy = GetScreenCoordFromWorldCoord(stumpcoords.x, stumpcoords.y, stumpcoords.z + cfg.MarkerOffset)
                SendNUIMessage({
                    action = 'freejobMarker:screenPos',
                    data = { ['stump_' .. stumpEntity] = { x = sx, y = sy, visible = onScreen } }
                })
            end

            if dist <= 2.0 and IsWorkingBucheron then
                -- Show 3D interaction to chop
                if IsControlJustPressed(1, 38) then -- E key
                    -- Play chopping animation looped for full duration
                    loadAnimDict(cfg.AnimDict)
                    TaskPlayAnim(ply, cfg.AnimDict, cfg.AnimName, 8.0, -8.0, -1, 1, 0, false, false, false)

                    -- Send progress to NUI
                    SendNUIMessage({
                        action = 'freejobHUD:progress',
                        data = { duration = cfg.ActionTime }
                    })

                    Wait(cfg.ActionTime)
                    ClearPedTasks(ply)

                    if not IsWorkingBucheron then break end

                    finalcount = finalcount + 1
                    if bonus < 100 then
                        bonus = bonus + 1
                    end

                    -- Update HUD
                    local currentReward = math.floor(finalcount * (bonus / 10) * Config.FreeJobs.Rewards.Bucheron)
                    SendNUIMessage({
                        action = 'freejobHUD:update',
                        data = {
                            tasks = finalcount,
                            bonus = bonus,
                            reward = currentReward,
                        }
                    })

                    -- Remove marker
                    SendNUIMessage({
                        action = 'freejobMarker:remove',
                        data = { id = 'stump_' .. stumpEntity }
                    })

                    -- Delete and spawn next
                    DeleteEntity(stumpEntity)
                    table.remove(StumpSpawned, 1)
                    currentStump = nil

                    if IsWorkingBucheron then
                        SpawnStump()
                    end
                    break
                end
            end
        end
    end)
end

function CollectBucheronPay()
    if finalcount <= 0 then return end

    loadAnimDict('mp_common')
    TaskPlayAnim(BucheronPed, "mp_common", "givetake1_a", 2.0, 2.0, -1, 0, 0, false, false, false)

    local trizomik = math.floor(finalcount * (bonus / 10) * Config.FreeJobs.Rewards.Bucheron)
    TriggerServerEvent("Null:jobs:verifyJob", 5, trizomik)

    CleanupBucheron()
end

function QuitBucheronJob()
    CleanupBucheron()
end

function CleanupBucheron()
    IsWorkingBucheron = false
    finalcount = 0
    bonus = 0

    -- Remove weapon
    if hatchetGiven then
        RemoveWeaponFromPed(PlayerPedId(), GetHashKey('WEAPON_HATCHET'))
        hatchetGiven = false
    end

    -- Delete vehicle
    if currentVehicle and DoesEntityExist(currentVehicle) then
        DeleteEntity(currentVehicle)
        currentVehicle = nil
    end
    if vehicleBlip then
        RemoveBlip(vehicleBlip)
        vehicleBlip = nil
    end

    -- Delete props
    for _, v in pairs(StumpSpawned) do
        if DoesEntityExist(v.id) then
            SendNUIMessage({
                action = 'freejobMarker:remove',
                data = { id = 'stump_' .. v.id }
            })
            DeleteEntity(v.id)
        end
    end
    StumpSpawned = {}
    currentStump = nil

    if StumpBlip then
        RemoveBlip(StumpBlip)
        StumpBlip = nil
    end

    -- Close HUD
    SendNUIMessage({ action = 'freejobHUD:close' })

    -- Restore skin
    ClearPedTasks(PlayerPedId())
    ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin, jobSkin)
        local isMale = skin.sex == 0
        TriggerEvent('Null:skinchanger:loadDefaultModel', isMale, function()
            ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin2)
                TriggerEvent('Null:skinchanger:loadSkin', skin2)
                TriggerEvent('esx:restoreLoadout')
            end)
        end)
    end)
end
