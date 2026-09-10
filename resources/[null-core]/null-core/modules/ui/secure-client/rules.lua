-- ============================================================================
-- REGLEMENT TABLET - Client Side
-- NUI open/close for server rules tablet
-- ============================================================================

local reglementOpen = false

function OpenReglement()
    if reglementOpen then return end
    reglementOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'reglement:open'
    })
end

function CloseReglement()
    if not reglementOpen then return end
    reglementOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'reglement:close'
    })
end

RegisterNUICallback('reglement:close', function(data, cb)
    CloseReglement()
    cb('ok')
end)

RegisterCommand('reglement', function()
    OpenReglement()
end, false)

exports('OpenReglement', OpenReglement)
exports('CloseReglement', CloseReglement)
