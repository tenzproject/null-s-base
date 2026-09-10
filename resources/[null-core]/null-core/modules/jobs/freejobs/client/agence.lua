local agenceCfg = Config.FreeJobs.Agence
local agencePed = nil
local isTabletOpen = false

local function loadModel(model)
    local hash = type(model) == 'number' and model or GetHashKey(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(100) end
    return hash
end

-- Open the React tablet
function OpenFreejobTablet()
    if isTabletOpen then return end
    isTabletOpen = true

    -- Build metiers data for the NUI
    local metiersData = {}
    for _, m in ipairs(Config.FreeJobs.Metiers) do
        table.insert(metiersData, {
            id = m.id,
            nom = m.nom,
            description = m.description,
            icon = m.icon,
            rentabilite = m.rentabilite,
            zone = { x = m.zone.x, y = m.zone.y, z = m.zone.z },
        })
    end

    SendNUIMessage({ action = 'freejobTablet:open' })
    SendNUIMessage({
        action = 'freejobTablet:setData',
        data = { metiers = metiersData }
    })
    SetNuiFocus(true, true)
end

-- NUI Callbacks
RegisterNUICallback('freejobTablet:close', function(_, cb)
    isTabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'freejobTablet:close' })
    cb('ok')
end)

RegisterNUICallback('freejobTablet:selectJob', function(data, cb)
    isTabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'freejobTablet:close' })

    local jobId = data.jobId
    for _, m in ipairs(Config.FreeJobs.Metiers) do
        if m.id == jobId then
            ESX.ShowNotification(ESX.Config("serverColor") .. "Vous avez trouvé un emploi !\n~s~Zone : " .. ESX.Config("serverColor") .. m.nom .. "\n~s~Position GPS : Activé")
            SetNewWaypoint(m.zone.x, m.zone.y)
            break
        end
    end
    cb('ok')
end)

-- Spawn PED + 3D Interaction
Citizen.CreateThread(function()
    local hash = loadModel(agenceCfg.PedModel)
    agencePed = CreatePed(2, hash, agenceCfg.PedCoords.x, agenceCfg.PedCoords.y, agenceCfg.PedCoords.z, agenceCfg.PedCoords.w, false, false)
    DecorSetInt(agencePed, "Yay", 5431)
    FreezeEntityPosition(agencePed, true)
    TaskStartScenarioInPlace(agencePed, "WORLD_HUMAN_CLIPBOARD", 0, true)
    SetEntityInvincible(agencePed, true)
    SetBlockingOfNonTemporaryEvents(agencePed, true)

    -- Agence blip
    local blip = AddBlipForCoord(agenceCfg.PedCoords.x, agenceCfg.PedCoords.y, agenceCfg.PedCoords.z)
    SetBlipSprite(blip, agenceCfg.BlipSprite)
    SetBlipScale(blip, 0.75)
    SetBlipColour(blip, agenceCfg.BlipColor)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString("Agence intérimaire")
    EndTextCommandSetBlipName(blip)

    -- Job zone blips
    for _, m in ipairs(Config.FreeJobs.Metiers) do
        local jblip = AddBlipForCoord(m.zone)
        SetBlipSprite(jblip, m.blip)
        SetBlipScale(jblip, m.scale)
        SetBlipColour(jblip, m.couleur)
        SetBlipAsShortRange(jblip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString(m.nom)
        EndTextCommandSetBlipName(jblip)
    end

    -- 3D Interaction on the agence PED
    Add3DInteraction({
        id = 'freejob_agence',
        coords = vector3(agenceCfg.InteractionCoords.x, agenceCfg.InteractionCoords.y, agenceCfg.InteractionCoords.z),
        maxDistance = 8.0,
        maxDistance2 = 2.5,
        text = 'Agence intérimaire',
        key = 'E',
        Action = function()
            OpenFreejobTablet()
        end,
    })
end)