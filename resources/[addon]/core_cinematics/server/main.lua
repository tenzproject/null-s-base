local function hasPermission(playerId)
    if not playerId or playerId == 0 then
        return false
    end

    local aceNode = (Config and Config.AcePerm) or "core_cinematics.use"

    if IsPlayerAceAllowed(playerId, aceNode) then
        return true
    end

    if IsPlayerAceAllowed(playerId, "command") then
        return true
    end

    return false
end

RegisterNetEvent("core_cinematics:checkPerm")
AddEventHandler("core_cinematics:checkPerm", function()
    local playerId = source
    if hasPermission(playerId) then
        TriggerClientEvent("core_cinematics:permOk", playerId)
    else
        TriggerClientEvent("core_cinematics:permDenied", playerId)
    end
end)

local resourceName = GetCurrentResourceName()
local projectsDir  = "projects/"

local function validateSlug(slug)
    if type(slug) ~= "string" then return nil end
    if #slug == 0 or #slug > 64 then return nil end

    if not slug:match("^[%w%-_]+$") then return nil end

    return slug
end

local function projectFilePath(slug)
    return projectsDir .. slug .. ".json"
end

local function loadIndex()
    local raw = LoadResourceFile(resourceName, projectsDir .. "index.json")
    if raw and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok and decoded then
            return decoded
        end
        
        print("[core_cinematics] WARNING: projects/index.json corrupted: " .. tostring(decoded))
    end
    return {}
end

local function saveIndex(indexTable)
    SaveResourceFile(resourceName, projectsDir .. "index.json", json.encode(indexTable), -1)
end

RegisterNetEvent("core_cinematics:listProjects")
AddEventHandler("core_cinematics:listProjects", function()
    local playerId = source
    if not hasPermission(playerId) then return end

    TriggerClientEvent("core_cinematics:projectList", playerId, loadIndex())
end)

RegisterNetEvent("core_cinematics:saveProject")
AddEventHandler("core_cinematics:saveProject", function(projectData)
    local playerId = source
    if not hasPermission(playerId) then return end

    if type(projectData) ~= "table" then return end

    local slug = validateSlug(projectData.slug)
    if not slug then return end

    SaveResourceFile(
        resourceName,
        projectFilePath(slug),
        json.encode(projectData),
        -1
    )

    local index = loadIndex()
    local found = false

    for i, entry in ipairs(index) do
        if entry.slug == slug then
            
            index[i].name      = projectData.name
            index[i].updatedAt = projectData.updatedAt or os.time()
            found              = true
            break
        end
    end

    if not found then
        
        table.insert(index, {
            slug      = slug,
            name      = projectData.name,
            createdAt = projectData.createdAt or os.time(),
            updatedAt = projectData.updatedAt or os.time(),
        })
    end

    saveIndex(index)

    TriggerClientEvent("core_cinematics:projectSaved", playerId, slug)
end)

RegisterNetEvent("core_cinematics:saveRecording")
AddEventHandler("core_cinematics:saveRecording", function(slug, recordingJson)
    local playerId = source
    if not hasPermission(playerId) then return end

    slug = validateSlug(slug)
    if not slug then return end

    if type(recordingJson) ~= "string" or #recordingJson == 0 then return end

    SaveResourceFile(
        resourceName,
        projectsDir .. slug .. "_rec.json",
        recordingJson,
        -1
    )
end)

RegisterNetEvent("core_cinematics:loadProject")
AddEventHandler("core_cinematics:loadProject", function(slug)
    local playerId = source
    if not hasPermission(playerId) then return end

    slug = validateSlug(slug)
    if not slug then return end

    local projectJson = LoadResourceFile(resourceName, projectFilePath(slug))

    if projectJson and projectJson ~= "" then
        
        TriggerClientEvent("core_cinematics:projectLoaded", playerId, projectJson)

        local recordingJson = LoadResourceFile(
            resourceName,
            projectsDir .. slug .. "_rec.json"
        )

        if recordingJson and recordingJson ~= "" then
            TriggerLatentClientEvent(
                "core_cinematics:loadRecording",
                playerId,
                500000, 
                recordingJson
            )
        end
    else
        
        local errorKey, errorMsg, errorExtra = _L("lua.server.project_not_found")
        TriggerClientEvent("core_cinematics:projectLoadError", playerId, errorKey, errorMsg, errorExtra)
    end
end)

RegisterNetEvent("core_cinematics:deleteProject")
AddEventHandler("core_cinematics:deleteProject", function(slug)
    local playerId = source
    if not hasPermission(playerId) then return end

    slug = validateSlug(slug)
    if not slug then return end

    SaveResourceFile(resourceName, projectFilePath(slug), "", -1)

    SaveResourceFile(resourceName, projectsDir .. slug .. "_rec.json", "", -1)

    local index = loadIndex()
    for i = #index, 1, -1 do
        if index[i].slug == slug then
            table.remove(index, i)
        end
    end
    saveIndex(index)

    TriggerClientEvent("core_cinematics:projectDeleted", playerId, slug)
end)

RegisterNetEvent("core_cinematics:syncCameraPath")
AddEventHandler("core_cinematics:syncCameraPath", function(cameraPathData)
    local playerId = source
    if not hasPermission(playerId) then return end

    TriggerClientEvent("core_cinematics:cameraPathUpdated", -1, playerId, cameraPathData)
end)

RegisterNetEvent("core_cinematics:syncCameraPropPos")
AddEventHandler("core_cinematics:syncCameraPropPos", function(propPosData)
    local playerId = source
    if not hasPermission(playerId) then return end

    TriggerClientEvent("core_cinematics:cameraPropMoved", -1, playerId, propPosData)
end)

RegisterNetEvent("core_cinematics:clearCameraPath")
AddEventHandler("core_cinematics:clearCameraPath", function()
    local playerId = source
    if not hasPermission(playerId) then return end

    TriggerClientEvent("core_cinematics:cameraPathCleared", -1, playerId)
end)

local cinematicBucket = (Config and Config.CinematicBucket) or 69

SetRoutingBucketEntityLockdownMode(cinematicBucket, "relaxed")
SetRoutingBucketPopulationEnabled(cinematicBucket, false)

local playersInBucket = {}

RegisterNetEvent("core_cinematics:enterBucket")
AddEventHandler("core_cinematics:enterBucket", function()
    local playerId = source
    if not hasPermission(playerId) then return end

    SetPlayerRoutingBucket(playerId, cinematicBucket)
    playersInBucket[playerId] = true
end)

RegisterNetEvent("core_cinematics:leaveBucket")
AddEventHandler("core_cinematics:leaveBucket", function()
    local playerId = source
    if not hasPermission(playerId) then return end

    SetPlayerRoutingBucket(playerId, 0) 
    playersInBucket[playerId] = nil
end)

AddEventHandler("playerDropped", function()
    local playerId = source
    playersInBucket[playerId] = nil
end)

AddEventHandler("onResourceStop", function(stoppedResource)
    if stoppedResource ~= resourceName then return end

    for playerId, _ in pairs(playersInBucket) do
        
        if GetPlayerEndpoint(tostring(playerId)) then
            SetPlayerRoutingBucket(playerId, 0)
        end
    end

    playersInBucket = {}
end)

