
Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()

    local value = GetResourceKvpString('preference_walk')

    if value == "move_m@multiplayer" then
        SetResourceKvp("preference_walk", "Defaultmale")
    elseif value == "move_f@multiplayer" then
        SetResourceKvp("preference_walk", "Defaultfemale")
    end

    if value == nil then
        local default = Config.BasicDefault['male']

        if GetEntityModel(PlayerPedId()) == `mp_f_freemode_01` then
            default = Config.BasicDefault['girl']
        end
        if default ~= nil then 
            SetResourceKvp("preference_walk", default)
            setNewWalkStyle(default)
        end
    else
        setNewWalkStyle(value)
    end
end)

function setNewWalkStyle(newWalk)
    if Config.walksList[newWalk] == nil then return end
    if newWalk ~= nil then
        SetResourceKvp('preference_walk', newWalk)
        ExecuteCommand("walk "..newWalk)
    end
end

function getWalkStyle()
    if GetResourceKvpString('preference_walk') == nil then
        value = "Defaultmale"
    else
        value = GetResourceKvpString('preference_walk')
    end
    return value
end