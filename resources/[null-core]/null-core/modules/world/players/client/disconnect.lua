local cached_players = {}


RegisterNetEvent("utils:playerDisconnect")
AddEventHandler("utils:playerDisconnect", function(player, info)
    cached_players[player] = info
    StartLoop(player)
end)


function StartLoop(player)
    Citizen.CreateThread(function()
        Wait(180*1000)
        if cached_players[player] ~= nil then
            cached_players[player] = nil
        end
    end)
end

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        local pNear = false

        for k,v in pairs(cached_players) do
            if #(v.pos - PlayerState.coords) < 10 then
                pNear = true
                local text = ('Déconnexion d\'un Joueur\nID : %s'):format(k)
                ESX.Game.Utils.DrawText3D(v.pos, text, 0.75, 4)
            end
        end

        if pNear then
            Wait(1)
        else
            Wait(500)
        end
    end
end))


null.InitPrint("Player Disconnect Module Initialized")