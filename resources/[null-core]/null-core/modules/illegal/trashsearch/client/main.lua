-- ============================================================================
-- TRASH SEARCH - Client Side
-- Detects nearby trash props, uses progressbar UI, opens temporary inventory
-- ============================================================================

local isSearching = false
local trashModelHash = {}

Citizen.CreateThread(function()
    for _, model in ipairs(Config.TrashSearch.TrashModels) do
        trashModelHash[model] = true
    end
end)

local function GetNearestTrashBin()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local maxDist = Config.TrashSearch.MaxDistance or 2.0
    local closestObj = nil
    local closestDist = maxDist + 1

    local handle, obj = FindFirstObject()
    local found = true

    while found do
        if DoesEntityExist(obj) then
            local model = GetEntityModel(obj)
            if trashModelHash[model] then
                local objCoords = GetEntityCoords(obj)
                local dist = #(playerCoords - objCoords)
                if dist < closestDist then
                    closestDist = dist
                    closestObj = obj
                end
            end
        end
        found, obj = FindNextObject(handle)
    end
    EndFindObject(handle)

    if closestObj and closestDist <= maxDist then
        return closestObj, closestDist
    end
    return nil, nil
end

local function PlaySearchAnimation()
    local dict = "mini@repair" 
    local anim = "fixing_a_ped"
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    TaskPlayAnim(PlayerPedId(), dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
end

local function StopSearchAnimation()
    ClearPedTasks(PlayerPedId())
end

local function OpenTrashInventory(data, storageName)
    local inventory = data
    inventory.weight = 0
    inventory.id = storageName
    inventory.maxWeight = 500
    inventory.type = "SOCIETY"
    inventory.title = "Poubelle"
    inventory.savename = storageName
    inventory.cacheKey = "SOCIETY_" .. storageName
    TriggerEvent("inventory:openTarget", inventory)
end

local function DoTrashSearch(targetEntity)
    if isSearching then return end

    local trashObj, dist
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    if targetEntity and DoesEntityExist(targetEntity) then
        local model = GetEntityModel(targetEntity)
        if trashModelHash[model] then
            trashObj = targetEntity
            dist = #(playerCoords - GetEntityCoords(trashObj))
        end
    end
    
    if not trashObj then
        trashObj, dist = GetNearestTrashBin()
    end
    
    if not trashObj then
        ESX.ShowNotification("~r~Aucune poubelle à proximité")
        return
    end

    local objCoords = GetEntityCoords(trashObj)
    isSearching = true

    FreezeEntityPosition(trashObj, true)

    -- Animation + progressbar
    FreezeEntityPosition(PlayerPedId(), true)
    PlaySearchAnimation()

    local duration = (Config.TrashSearch.SearchDuration or 8) * 1000
    ShowProgressBar(duration, "Fouille de la poubelle...")

    Wait(duration)

    StopSearchAnimation()
    FreezeEntityPosition(PlayerPedId(), false)
    FreezeEntityPosition(trashObj, false)

    if not isSearching then return end

    -- Ask server to generate loot and create temp inventory
    ESX.TriggerServerCallback('null:trashsearch:open', function(success, data, storageName, cacheKey)
        isSearching = false

        if not success then
            if type(data) == "string" then
                ESX.ShowNotification(data)
            end
            return
        end

        -- Store timestamp for client-side cooldown check
        local hash = string.format("%.1f_%.1f_%.1f", objCoords.x, objCoords.y, objCoords.z)
        if not LocalPlayerState then LocalPlayerState = {} end
        if not LocalPlayerState.searchedTrash then LocalPlayerState.searchedTrash = {} end
        LocalPlayerState.searchedTrash[hash] = GetGameTimer() / 1000

        if not data or not data.items or #data.items == 0 then
            ESX.ShowNotification("~o~Vous n'avez rien trouvé d'intéressant...")
            return
        end

        OpenTrashInventory(data, storageName)
    end, objCoords.x, objCoords.y, objCoords.z)
end

exports('DoTrashSearch', DoTrashSearch)

-- ============================================================================
-- Context Menu Integration: Trash bins now use ALT menu (context-menu-menus.lua)
-- Old E key detection disabled - migrated to _Trash() function in object.lua
-- ============================================================================

null.InitPrint("Trash Search module loaded")
