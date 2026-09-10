-- ============================================================================
-- ILLEGAL TABLET DEVICE - Actions tab bridge
-- ============================================================================

local function closeDevice()
    if _G.CloseIllegalDevice then _G.CloseIllegalDevice() end
end

RegisterNUICallback('illegalDevice:actions:fouiller', function(_, cb)
    closeDevice()
    Wait(200)
    local player, distance = ESX.Game.GetClosestPlayer()
    if distance ~= -1 and distance <= 3.0 then
        local targetPed = GetPlayerPed(player)
        if ESX.isHandsUp(targetPed) then
            ESX.TriggerServerCallback('null:fouiller', function(result, id)
                if result then
                    local inventory = result
                    inventory.weight = 0
                    inventory.id = GetPlayerServerId(player)
                    inventory.maxWeight = 1000
                    inventory.type = "PLAYER"
                    TriggerEvent("inventory:openSearch", inventory, false, result.cash or 0, result.dirtycash or 0)
                end
            end, GetPlayerServerId(player))
        else
            ESX.ShowNotification('🙌 Le joueur cible ne lève pas les mains')
        end
    else
        ESX.ShowNotification('Aucun joueur à proximité')
    end
    cb('ok')
end)

RegisterNUICallback('illegalDevice:actions:facture', function(_, cb)
    closeDevice()
    Wait(200)
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestPlayer == -1 or closestDistance > 3.0 then
        ESX.ShowNotification('Il n\'y a aucun joueur aux alentours')
        cb('ok')
        return
    end
    local input = null.fct.input('Montant', false, 9000000, "number")
    if input ~= "" and input ~= nil then
        local montant = tonumber(input)
        if montant and montant > 0 then
            TriggerServerEvent("Core:AddBilling", GetPlayerServerId(closestPlayer), montant, ESX.PlayerData.job2.name)
        end
    end
    cb('ok')
end)

RegisterNUICallback('illegalDevice:actions:putInVehicle', function(_, cb)
    closeDevice()
    Wait(200)
    local player, distance = ESX.Game.GetClosestPlayer()
    if distance ~= -1 and distance <= 3.0 then
        local targetPed = GetPlayerPed(player)
        if ESX.isHandsUp(targetPed) then
            TriggerServerEvent('GangsBuilder:putInVehicle', GetPlayerServerId(player))
        else
            ESX.ShowNotification('🙌 Le joueur cible ne lève pas les mains')
        end
    else
        ESX.ShowNotification('Aucun joueur à proximité')
    end
    cb('ok')
end)

RegisterNUICallback('illegalDevice:actions:outVehicle', function(_, cb)
    closeDevice()
    Wait(200)
    local player, distance = ESX.Game.GetClosestPlayer()
    if distance ~= -1 and distance <= 3.0 then
        TriggerServerEvent('GangsBuilder:OutVehicle', GetPlayerServerId(player))
    else
        ESX.ShowNotification('Aucun joueur à proximité')
    end
    cb('ok')
end)
