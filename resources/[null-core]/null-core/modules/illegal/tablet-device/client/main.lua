-- ============================================================================
-- ILLEGAL TABLET DEVICE - NUI Bridge (client)
-- ============================================================================

local IDevice = {}
IDevice.open = false

local function sendCfg()
    local diffs = {}
    for _, d in pairs(Config.IllegalDevice.GoFast.Difficulties) do
        diffs[#diffs + 1] = {
            id = d.id,
            label = d.label,
            description = d.description,
            distance = d.targetDistance,
            payment = d.payment,
        }
    end
    table.sort(diffs, function(a, b) return a.distance < b.distance end)
    SendNUIMessage({ action = 'illegalDevice:setConfig', data = { difficulties = diffs } })
end

function IDevice.Open()
    if IDevice.open then return end
    IDevice.open = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'illegalDevice:open' })
    sendCfg()
    ESX.TriggerServerCallback('null:illegalDevice:gofast:status', function(status)
        SendNUIMessage({ action = 'illegalDevice:gofast:status', data = status })
    end)
end

function IDevice.Close()
    if not IDevice.open then return end
    IDevice.open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'illegalDevice:close' })
end

RegisterNetEvent('null:illegalDevice:open')
AddEventHandler('null:illegalDevice:open', IDevice.Open)

RegisterNUICallback('illegalDevice:close', function(_, cb)
    IDevice.Close()
    cb({ ok = true })
end)

RegisterNUICallback('illegalDevice:gofast:request', function(data, cb)
    IDevice.Close()
    TriggerServerEvent('null:illegalDevice:gofast:request', data.difficulty)
    cb({ ok = true })
end)

RegisterNUICallback('illegalDevice:gofast:status', function(_, cb)
    ESX.TriggerServerCallback('null:illegalDevice:gofast:status', function(status)
        cb(status or {})
    end)
end)

-- Debug
RegisterCommand('illegaldevice', function()
    IDevice.Open()
end, false)

_G.OpenIllegalDevice = IDevice.Open
_G.CloseIllegalDevice = IDevice.Close
