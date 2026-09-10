local enterPositions = {}
local blurKickPending = {}

RegisterNetEvent("null:loading:playerInEnter", function(lastpos)
    enterPositions[source] = lastpos or true
end)

RegisterNetEvent("null:loading:playerLoaded", function()
    enterPositions[source] = nil
end)

RegisterNetEvent('null:loading:blurInstallKick', function()
    local src = source
    if blurKickPending[src] then return end
    blurKickPending[src] = true
    DropPlayer(src, 'Addon blur installé. Redémarrez FiveM pour activer le flou.')
end)

AddEventHandler("playerDropped", function()
    enterPositions[source] = nil
    blurKickPending[source] = nil
end)

loadingEvent = {}
loadingEvent.onLogout = function(xPlayer)
    if xPlayer == nil then return end
    local pos = enterPositions[xPlayer.source]
    if pos == nil or pos == true then return end
    xPlayer.setLastPosition(pos)
end