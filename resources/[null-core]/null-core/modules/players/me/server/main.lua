local LastMe = {}
local MeActiveSeconds = 7

local function sanitizeMeMessage(message)
    message = tostring(message or "")
    message = message:gsub("[%z\1-\31\127]", " ")
    message = message:gsub("<[^>]->", "")
    message = message:gsub("~.-~", "")
    message = message:gsub("%s+", " ")
    message = message:gsub("^%s+", ""):gsub("%s+$", "")

    if message == "" then
        return nil
    end

    return message:sub(1, 96)
end

RegisterCommand('me', function(source, args, rawCommand)
    if source == 0 then
        return
    end
    if PlayerIsDead[source] ~= nil then
        if PlayerIsDead[source].isDead == 1 then
            return
        end
    end
    local message = sanitizeMeMessage((rawCommand or ""):sub(4))
    if message == nil then
        return
    end

    if string.match(message:lower(), "img%s+src") then 
        ExecuteCommand("ban " .. source .. " 0 Tentative de triche me (0)") 
        return 
    end
    local now = os.time()
    if LastMe[source] ~= nil and now < LastMe[source] then return end
    LastMe[source] = now + MeActiveSeconds
    TriggerClientEvent('Null:3dme:trigger', -1, source, 'La personne ' .. message)
end)

AddEventHandler('playerDropped', function()
    LastMe[source] = nil
end)
