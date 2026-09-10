local kvpData = nil


Citizen.CreateThread(function()
    null.fct.waitPlayerLoaded()
    
    kvpData = "Null"

    for k, v in pairs(Config.Prefer.Preferences) do
        local value = GetResourceKvpString(("%s:preferences:%s"):format(kvpData, k))

        if value == nil then
            setPreferData(k, v.basicV)
        else
            setPreferData(k, value == 'true' and true or false)
        end
    end
end)

function setPreferData(name, force)
    while kvpData == nil do Wait(1) end

    local value = GetResourceKvpString(("%s:preferences:%s"):format(kvpData, name))
    local newValue = (not value or value == 'false') and 'true' or 'false'
    if force ~= nil then
        newValue = force and 'true' or 'false'
    end

    if Config.Prefer.Preferences[name] == nil then
        return
    end

    if newValue == 'true' then
        Config.Prefer.Enabled[name] = true
        if Config.Prefer.Preferences[name].enable then
            Config.Prefer.Preferences[name].enable()
        end
    else
        Config.Prefer.Enabled[name] = false
        if Config.Prefer.Preferences[name].disable then
            Config.Prefer.Preferences[name].disable()
        end
    end
    if name ~= nil and newValue ~= nil then
        SetResourceKvp(("%s:preferences:%s"):format(kvpData, name), newValue)
    end

    --TriggerEvent('preferences:update', name, getDataPrefer(name))

    return newValue
end

function getWeaponKeyBind(name)
    local value = GetResourceKvpString(("%s:preferences:%s"):format(kvpData, name))
    return value == 'true' and true or false
end

function getPreference(name)
    return Config.Prefer.Enabled[name]
end

exports('getPreference', function(name)
    return getPreference(name)
end)

Citizen.CreateThread(function()
    -- Attendre que Config.Prefer.Blips soit chargé
    while not Config.Prefer or not Config.Prefer.Blips do Wait(100) end
    
    for i = 1, #Config.Prefer.Blips do 
        local blip = Config.Prefer.Blips[i]
        if blip and blip.kvpName ~= nil then
            PlayerState[blip.kvpName] = GetResourceKvpString(blip.kvpName) 

            if PlayerState[blip.kvpName] == nil then 
                SetResourceKvp(blip.kvpName, "true")
                PlayerState[blip.kvpName] = "true"
            end

            if PlayerState[blip.kvpName] == "false" then
                local category = blip.category
                Citizen.SetTimeout(15000, function()
                    ESX.removeAllBlipsFromCategory(category)
                end)
            end
        end
    end
end)

Citizen.CreateThread(function()
    --[[while true do 
        Wait(5000)
        local entityHealth = GetEntityHealth(PlayerState.ped)

        if getInZoneGF() then
            ExecuteCommand(('walk %s'):format(getWalkStyle()))
        elseif entityHealth <= 130 then 
            ExecuteCommand(("walk %s"):format("Injured"))
        elseif PlayerState.cuffed then
            ExecuteCommand(("walk %s"):format("Handcuffs"))
        elseif inAta() == true then 
            ExecuteCommand(("walk %s"):format("Injured"))
        else
            ExecuteCommand(('walk %s'):format(getWalkStyle()))
        end
    end]]
end)
