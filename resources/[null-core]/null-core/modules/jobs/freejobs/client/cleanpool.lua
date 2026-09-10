local cfgP = Config.FreeJobs.Pool
local poolZone = vector3(cfgP.PedCoords.x, cfgP.PedCoords.y, cfgP.PedCoords.z)
local poolPed = nil
local IsWorkingPool = false
local poolBroom = nil
local hasBroom = false
local poolBonus = 0
local poolCount = 0
local poolCurrentEntity = nil
local poolBlip = nil
local PoolSpawned = {}

local function poolLoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

local function GivePoolBroom()
    hasBroom = true
    local ped = PlayerPedId()
    local cSCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, -5.0)
    poolBroom = CreateObject(GetHashKey(cfgP.BroomModel), cSCoords.x, cSCoords.y, cSCoords.z, true, true, true)
    AttachEntityToEntity(poolBroom, ped, GetPedBoneIndex(ped, 28422), -0.005, 0.0, 0.0, 360.0, 360.0, 0.0, true, true, false, true, 0, true)
end

local function SpawnPoolTrash()
    local random = math.random(1, #cfgP.PoolShit)
    local v = cfgP.PoolShit[random]

    RequestModel(GetHashKey(v.props))
    while not HasModelLoaded(GetHashKey(v.props)) do Wait(1) end

    poolCurrentEntity = CreateObject(GetHashKey(v.props), v.pos, false, true, true)
    SetEntityAsMissionEntity(poolCurrentEntity, true, true)

    if poolBlip then RemoveBlip(poolBlip) end
    poolBlip = AddBlipForEntity(poolCurrentEntity)
    SetBlipSprite(poolBlip, cfgP.TrashBlip.Sprite)
    SetBlipColour(poolBlip, cfgP.TrashBlip.Color)
    SetBlipScale(poolBlip, cfgP.TrashBlip.Scale)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(cfgP.TrashBlip.Label)
    EndTextCommandSetBlipName(poolBlip)

    local markerId = 'pool_' .. poolCurrentEntity
    SendNUIMessage({ action = 'freejobMarker:add', data = { id = markerId, x = v.pos.x, y = v.pos.y, z = v.pos.z + cfgP.MarkerOffset, label = v.label } })

    table.insert(PoolSpawned, { id = poolCurrentEntity, pos = v.pos, anim = v.anim, lib = v.lib, markerId = markerId })

    -- Interaction loop
    Citizen.CreateThread(function()
        local entity = poolCurrentEntity
        local data = PoolSpawned[#PoolSpawned]
        while IsWorkingPool and DoesEntityExist(entity) do
            Wait(0)
            local ply = PlayerPedId()
            local coordsply = GetEntityCoords(ply)
            local ecoords = GetEntityCoords(entity)
            local dist = #(coordsply - ecoords)

            if dist < 50.0 then
                local onScreen, sx, sy = GetScreenCoordFromWorldCoord(ecoords.x, ecoords.y, ecoords.z + cfgP.MarkerOffset)
                SendNUIMessage({ action = 'freejobMarker:screenPos', data = { [data.markerId] = { x = sx, y = sy, visible = onScreen } } })
            end

            if dist <= 1.5 and IsWorkingPool and hasBroom then
                if IsControlJustPressed(1, 38) then
                    poolLoadAnimDict(data.anim)
                    TaskPlayAnim(ply, data.anim, data.lib, 8.0, -8.0, -1, 0, 0, false, false, false)
                    SendNUIMessage({ action = 'freejobHUD:progress', data = { duration = cfgP.CleanDuration } })
                    Wait(cfgP.CleanDuration)
                    ClearPedTasksImmediately(ply)

                    if not IsWorkingPool then break end

                    poolCount = poolCount + 1
                    if poolBonus < 100 then poolBonus = poolBonus + 1 end

                    local currentReward = math.floor(poolCount * (poolBonus / 10) * Config.FreeJobs.Rewards.CleanPool)
                    SendNUIMessage({ action = 'freejobHUD:update', data = { tasks = poolCount, bonus = poolBonus, reward = currentReward } })
                    SendNUIMessage({ action = 'freejobMarker:remove', data = { id = data.markerId } })

                    DeleteEntity(entity)
                    for i, s in ipairs(PoolSpawned) do
                        if s.id == entity then table.remove(PoolSpawned, i) break end
                    end

                    if IsWorkingPool then SpawnPoolTrash() end
                    break
                end
            end
        end
    end)
end

local function StartPoolJob()
    IsWorkingPool = true
    poolCount = 0
    poolBonus = 0

    -- Apply outfit
    TriggerEvent('Null:skinchanger:getSkin', function(skin)
        TriggerEvent('Null:skinchanger:loadClothes', skin, cfgP.Tenue)
    end)

    GivePoolBroom()
    SpawnPoolTrash()

    SendNUIMessage({ action = 'freejobHUD:open', data = {
        jobName = 'Nettoyage Piscine', jobIcon = 'pool',
        tasks = 0, bonus = 0, reward = 0,
        rewardPerTask = Config.FreeJobs.Rewards.CleanPool,
    }})
    TriggerServerEvent("Null:jobs:startActivity")

    -- Distance check
    Citizen.CreateThread(function()
        while IsWorkingPool do
            Wait(5000)
            local dist = #(GetEntityCoords(PlayerPedId()) - poolZone)
            if dist > cfgP.MaxDistance then
                CleanupPool()
                ESX.ShowNotification("~r~Vous vous êtes trop éloigné, mission abandonnée !")
            end
        end
    end)
end

local function CollectPoolPay()
    if poolCount <= 0 then return end
    poolLoadAnimDict('mp_common')
    TaskPlayAnim(poolPed, "mp_common", "givetake1_a", 2.0, 2.0, -1, 0, 0, false, false, false)
    local trizomik = math.floor(poolCount * (poolBonus / 10) * Config.FreeJobs.Rewards.CleanPool)
    TriggerServerEvent("Null:jobs:verifyJob", 4, trizomik)
    CleanupPool()
end

function CleanupPool()
    IsWorkingPool = false
    poolCount = 0
    poolBonus = 0

    if poolBroom and DoesEntityExist(poolBroom) then DeleteEntity(poolBroom) end
    poolBroom = nil
    hasBroom = false

    for _, s in pairs(PoolSpawned) do
        SendNUIMessage({ action = 'freejobMarker:remove', data = { id = s.markerId } })
        if DoesEntityExist(s.id) then DeleteEntity(s.id) end
    end
    PoolSpawned = {}

    if poolCurrentEntity and DoesEntityExist(poolCurrentEntity) then DeleteEntity(poolCurrentEntity) end
    poolCurrentEntity = nil
    if poolBlip then RemoveBlip(poolBlip) poolBlip = nil end

    SendNUIMessage({ action = 'freejobHUD:close' })
    ClearPedTasks(PlayerPedId())

    -- Restore skin
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

-- Spawn PED
Citizen.CreateThread(function()
    local ped = cfgP.PedModel
    RequestModel(ped)
    while not HasModelLoaded(ped) do Wait(100) end
    poolPed = CreatePed(0, ped, cfgP.PedCoords.x, cfgP.PedCoords.y, cfgP.PedCoords.z, cfgP.PedCoords.w, false, false)
    SetBlockingOfNonTemporaryEvents(poolPed, true)
    SetEntityInvincible(poolPed, true)
    FreezeEntityPosition(poolPed, true)

    -- 3D Interaction
    Add3DInteraction({
        id = 'freejob_pool',
        coords = vector3(cfgP.Ped3DInteractionCoords.x, cfgP.Ped3DInteractionCoords.y, cfgP.Ped3DInteractionCoords.z),
        maxDistance = 8.0,
        maxDistance2 = 2.5,
        type = 'multi',
        text = {
            title = 'Gérant de la piscine',
            lines = {
                {
                    id = 'start',
                    left = 'Commencer le travail',
                    key = 'E',
                    action = function()
                        if IsWorkingPool then return end
                        StartPoolJob()
                    end,
                    canSee = function(cb) cb(not IsWorkingPool) end,
                },
                {
                    id = 'paye',
                    left = 'Prendre sa paye',
                    key = 'E',
                    action = function()
                        if not IsWorkingPool then return end
                        CollectPoolPay()
                    end,
                    canSee = function(cb) cb(IsWorkingPool and poolCount > 0) end,
                },
                {
                    id = 'quit',
                    left = 'Quitter le travail',
                    key = 'G',
                    action = function()
                        if not IsWorkingPool then return end
                        CleanupPool()
                    end,
                    canSee = function(cb) cb(IsWorkingPool) end,
                },
            },
        },
    })
end)