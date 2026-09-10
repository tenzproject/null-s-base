local meColor = { r = tonumber(ESX.Config("r")) or 230, g = tonumber(ESX.Config("g")) or 230, b = tonumber(ESX.Config("b")) or 230, a = 255 }
local meDuration = 7000
local meEntries = {}
local activeTag = {}
local lastHadEntries = false

local function sanitizeDisplayText(message, maxLength)
    message = tostring(message or "")
    message = message:gsub("[%z\1-\31\127]", " ")
    message = message:gsub("<[^>]->", "")
    message = message:gsub("~.-~", "")
    message = message:gsub("%s+", " ")
    message = message:gsub("^%s+", ""):gsub("%s+$", "")

    if message == "" then
        return nil
    end

    return message:sub(1, maxLength or 120)
end

local function getPlayerTarget(serverId)
    local player = GetPlayerFromServerId(serverId)

    if player == -1 then
        return nil
    end

    local ped = GetPlayerPed(player)
    if ped == nil or ped == 0 or not DoesEntityExist(ped) then
        return nil
    end

    return player, ped
end

local function addScreenEntry(entries, id, ped, text, offset, color, kind, useHeadBone)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords

    if useHeadBone then
        targetCoords = GetPedBoneCoords(ped, 31086, 0.45, 0.0, 0.0)
    else
        targetCoords = GetEntityCoords(ped, false)
        targetCoords = vector3(targetCoords.x, targetCoords.y, targetCoords.z + offset)
    end

    if #(playerCoords - targetCoords) > 25.0 then
        return
    end

    if not HasEntityClearLosToEntity(playerPed, ped, 17) then
        return
    end

    local onScreen, x, y = GetScreenCoordFromWorldCoord(targetCoords.x, targetCoords.y, targetCoords.z)
    if not onScreen then
        return
    end

    entries[#entries + 1] = {
        id = id,
        text = text,
        x = x,
        y = y,
        color = color or meColor,
        kind = kind or "me"
    }
end

RegisterNetEvent('Null:3dme:trigger', function(targetId, message)
    message = sanitizeDisplayText(message, 120)
    if message == nil then return end

    local now = GetGameTimer()
    for index = #meEntries, 1, -1 do
        if meEntries[index].targetId == targetId then
            table.remove(meEntries, index)
        end
    end

    meEntries[#meEntries + 1] = {
        id = ("%s:%s:%s"):format(targetId, now, #meEntries + 1),
        targetId = targetId,
        message = message,
        expires = now + meDuration,
        offset = 1.0 + (#meEntries * 0.14)
    }
end)

RegisterNetEvent('Null:adminTag:trigger', function(sender, message)
    message = sanitizeDisplayText(message, 90)
    if message ~= nil then
        activeTag[sender] = message
    else
        activeTag[sender] = nil
    end
end)

CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        local now = GetGameTimer()
        local entries = {}

        for index = #meEntries, 1, -1 do
            local entry = meEntries[index]
            if now > entry.expires then
                table.remove(meEntries, index)
            else
                local _, ped = getPlayerTarget(entry.targetId)
                if ped then
                    addScreenEntry(entries, entry.id, ped, entry.message, entry.offset, meColor, "me", false)
                end
            end
        end

        for sender, text in pairs(activeTag) do
            local _, ped = getPlayerTarget(sender)
            if ped and not IsPedInAnyVehicle(ped, false) then
                addScreenEntry(entries, "admin:" .. tostring(sender), ped, text, 1.0, { r = 127, g = 0, b = 255, a = 255 }, "admin", true)
            end
        end

        if #entries > 0 or lastHadEntries then
            SendNUIMessage({
                action = "me:update",
                entries = entries
            })
            lastHadEntries = #entries > 0
        end

        local hasActiveEntries = #meEntries > 0 or next(activeTag) ~= nil
        Wait(hasActiveEntries and 0 or 250)
    end
end))
