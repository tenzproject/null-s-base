inCeintureExplosive = false
RegisterNetEvent("null:terro:useCeinture",function()
    
    -- @TODO: Mettre le gpb ceinture explosive
    TriggerEvent('Null:skinchanger:getSkin', function(skin)
        TriggerEvent('Null:skinchanger:loadClothes', skin, {
            ["bproof_1"] = 14, ["bproof_2"] = 0,
        })

        Citizen.CreateThread(function()
            while true do 
                if inCeintureExplosive then break end
                ESX.ShowHelpNotification("Appuyer sur ~INPUT_CONTEXT~ pour ~r~exploser~s~.\nAppuyer sur ~INPUT_CELLPHONE_CANCEL~ pour enlever la ceinture explosive.")
                if IsControlJustPressed(0, 51) then
                    inCeintureExplosive = true
                    local PlayerPos = GetEntityCoords(PlayerPedId())
                    AddExplosion(PlayerPos.x, PlayerPos.y, PlayerPos.z, 9, 3.9, 1, 0, 1065353216, 0)
                    Wait(500)
                    AddExplosion(PlayerPos.x+4, PlayerPos.y, PlayerPos.z, 9, 3.9, 1, 0, 1065353216, 0)
                    Wait(500)
                    AddExplosion(PlayerPos.x-4, PlayerPos.y, PlayerPos.z, 9, 3.9, 1, 0, 1065353216, 0)
                    TriggerServerEvent("null:removeCeintureExplosive")
                    TriggerEvent('Null:skinchanger:loadClothes', skin, {
                        ["bproof_1"] = -1, ["bproof_2"] = 0,
                    })
                end
                if IsControlJustPressed(0, 177) then
                    break
                    TriggerEvent('Null:skinchanger:loadClothes', skin, {
                        ["bproof_1"] = -1, ["bproof_2"] = 0,
                    })
                end
                Wait(0)
            end
        end)
    end)
end)