-- ============================================================================
-- RADIO UI — Client-side bridge to pma-voice
-- Opens via radio item use, positioned bottom-right
-- ============================================================================

local pma = exports["null-deps"]
local radioOpen = false
local radioEnabled = false
local currentFrequency = nil
local currentVolume = 1.0
local micClicks = true

-- ============================================================================
-- OPEN / CLOSE
-- ============================================================================

function OpenRadioUI()
    if radioOpen then return end
    radioOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'radio:open',
        data = {}
    })
    
    -- Send current state
    SendNUIMessage({
        action = 'radio:setState',
        data = {
            enabled = radioEnabled,
            frequency = currentFrequency,
            volume = math.floor(currentVolume * 100),
            micClicks = micClicks,
        }
    })
end

function CloseRadioUI()
    if not radioOpen then return end
    radioOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'radio:close' })
end

-- ============================================================================
-- NUI CALLBACKS
-- ============================================================================

RegisterNUICallback('radio:close', function(_, cb)
    CloseRadioUI()
    cb({})
end)

RegisterNUICallback('radio:toggle', function(data, cb)
    cb({})
    if data.enabled then
        radioEnabled = true
        pma:setVoiceProperty("radioEnabled", true)
    else
        radioEnabled = false
        if currentFrequency then
            pma:setRadioChannel(0)
            currentFrequency = nil
        end
        pma:setVoiceProperty("radioEnabled", false)
    end
end)

RegisterNUICallback('radio:connect', function(data, cb)
    cb({})
    local freq = tonumber(data.frequency)
    if not freq or freq <= 0 or freq > 999 then
        SendNUIMessage({
            action = 'radio:connectResult',
            data = { success = false, error = 'Fréquence invalide (1-999)' }
        })
        return
    end

    -- Check restricted frequencies
    if Config.Radio and Config.Radio[freq] then
        local can = false
        for jobName, _ in pairs(Config.Radio[freq]) do
            if jobName == ESX.PlayerData.job.name then
                can = true
                break
            end
        end
        if not can then
            SendNUIMessage({
                action = 'radio:connectResult',
                data = { success = false, error = 'Fréquence réservée' }
            })
            return
        end
    end

    -- Enable radio if not already
    if not radioEnabled then
        radioEnabled = true
        pma:setVoiceProperty("radioEnabled", true)
    end

    currentFrequency = freq
    pma:setRadioChannel(freq)

    SendNUIMessage({
        action = 'radio:connectResult',
        data = { success = true, frequency = freq }
    })

    ESX.ShowNotification("Fréquence définie sur " .. freq .. " MHz")
end)

RegisterNUICallback('radio:disconnect', function(_, cb)
    cb({})
    pma:setRadioChannel(0)
    currentFrequency = nil
    ESX.ShowNotification("Déconnecté de la fréquence")
end)

RegisterNUICallback('radio:setVolume', function(data, cb)
    cb({})
    local vol = tonumber(data.volume) or 1.0
    currentVolume = vol
    pma:setRadioVolume(vol)
end)

RegisterNUICallback('radio:toggleMicClicks', function(data, cb)
    cb({})
    micClicks = data.enabled and true or false
    pma:setVoiceProperty("micClicks", micClicks)
end)

-- Focus handling for input fields
RegisterNUICallback('radio:inputFocus', function(_, cb)
    pcall(function() exports["null-core"]:setChatCanOpen(false) end)
    null.ActiveFrontend(true)
    cb({})
end)

RegisterNUICallback('radio:inputBlur', function(_, cb)
    null.ActiveFrontend(false)
    pcall(function() exports["null-core"]:setChatCanOpen(true) end)
    cb({})
end)

-- ============================================================================
-- ITEM USE — Server triggers this when player uses the radio item
-- ============================================================================

RegisterNetEvent('null:radio:open', function()
    if radioOpen then
        CloseRadioUI()
    else
        OpenRadioUI()
    end
end)

-- ============================================================================
-- COMMAND (debug)
-- ============================================================================

RegisterCommand('radio', function()
    if not ESX.HasItem("radio") then
        ESX.ShowNotification("~r~Vous n'avez pas de radio")
        return
    end
    if radioOpen then
        CloseRadioUI()
    else
        OpenRadioUI()
    end
end, false)

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports('OpenRadioUI', OpenRadioUI)
exports('CloseRadioUI', CloseRadioUI)
exports('IsRadioOpen', function() return radioOpen end)
exports('GetRadioFrequency', function() return currentFrequency end)
exports('IsRadioEnabled', function() return radioEnabled end)
