-- ============================================================================
-- ILLEGAL TABLET - Client Side
-- NUI open/close, NUI callbacks for tablet actions
-- ============================================================================

local tabletOpen = false

function OpenIllegalTablet()
    if tabletOpen then return end
    tabletOpen = true

    ESX.TriggerServerCallback('null:tablet:getData', function(data)
        if data == nil then
            tabletOpen = false
            ESX.ShowNotification("❌ Vous n'appartenez à aucun groupe illégal", "error")
            return
        end

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = 'illegalTablet:open',
            data = data
        })
    end)
end

function CloseIllegalTablet()
    if not tabletOpen then return end
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({
        action = 'illegalTablet:close'
    })
end

-- NUI Callback: Close tablet
RegisterNUICallback('illegalTablet:close', function(data, cb)
    CloseIllegalTablet()
    cb('ok')
end)

-- NUI Callback: Refresh data
RegisterNUICallback('illegalTablet:refresh', function(data, cb)
    ESX.TriggerServerCallback('null:tablet:getData', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('illegalTablet:acceptMission', function(data, cb)
    TriggerServerEvent('null:tablet:acceptMission', data.missionId, data.missionType)
    Wait(300)
    ESX.TriggerServerCallback('null:tablet:getData', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('illegalTablet:claimMission', function(data, cb)
    TriggerServerEvent('null:tablet:claimMission', data.missionId, data.missionType)
    Wait(300)
    ESX.TriggerServerCallback('null:tablet:getData', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('illegalTablet:addGrade', function(data, cb)
    TriggerServerEvent('null:tablet:addGrade', data.label)
    Wait(500)
    ESX.TriggerServerCallback('null:tablet:getData', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('illegalTablet:removeGrade', function(data, cb)
    TriggerServerEvent('null:tablet:removeGrade', data.gradeName, data.gradePos)
    Wait(500)
    ESX.TriggerServerCallback('null:tablet:getData', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('illegalTablet:changePerms', function(data, cb)
    TriggerServerEvent('null:tablet:changePerms', data.permType, data.gradeKey, data.value)
    Wait(300)
    cb('ok')
end)

RegisterNUICallback('illegalTablet:changeMemberGrade', function(data, cb)
    TriggerServerEvent('null:tablet:changeMemberGrade', data.idunique, data.newGrade)
    Wait(500)
    ESX.TriggerServerCallback('null:tablet:getData', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('illegalTablet:kickMember', function(data, cb)
    TriggerServerEvent('null:tablet:kickMember', data.idunique)
    Wait(500)
    ESX.TriggerServerCallback('null:tablet:getData', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('illegalTablet:changeColor', function(data, cb)
    TriggerServerEvent('null:tablet:changeColor', data.color)
    Wait(300)
    ESX.TriggerServerCallback('null:tablet:getData', function(result)
        cb(result)
    end)
end)

RegisterNUICallback('illegalTablet:recruitNearest', function(data, cb)
    CloseIllegalTablet()
    Wait(200)
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestDistance ~= -1 and closestDistance <= 3 then
        TriggerServerEvent("Null:personalmenu:Boss_recruterplayer2", GetPlayerServerId(closestPlayer), ESX.PlayerData.job2.name)
    else
        ESX.ShowNotification("Aucun joueur à proximité", "error")
    end
    cb('ok')
end)

RegisterNUICallback('illegalTablet:fireNearest', function(data, cb)
    CloseIllegalTablet()
    Wait(200)
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestDistance ~= -1 and closestDistance <= 3 then
        TriggerServerEvent("Null:personalmenu:Boss_virerplayer2", GetPlayerServerId(closestPlayer))
    else
        ESX.ShowNotification("Aucun joueur à proximité", "error")
    end
    cb('ok')
end)

RegisterNUICallback('illegalTablet:promoteNearest', function(data, cb)
    CloseIllegalTablet()
    Wait(200)
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestDistance ~= -1 and closestDistance <= 3 then
        TriggerServerEvent("Null:personalmenu:Boss_promouvoirplayer2", GetPlayerServerId(closestPlayer))
    else
        ESX.ShowNotification("Aucun joueur à proximité", "error")
    end
    cb('ok')
end)

RegisterNUICallback('illegalTablet:demoteNearest', function(data, cb)
    CloseIllegalTablet()
    Wait(200)
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestDistance ~= -1 and closestDistance <= 3 then
        TriggerServerEvent("Null:personalmenu:Boss_destituerplayer2", GetPlayerServerId(closestPlayer))
    else
        ESX.ShowNotification("Aucun joueur à proximité", "error")
    end
    cb('ok')
end)

RegisterNUICallback('illegalTablet:fouiller', function(data, cb)
    CloseIllegalTablet()
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

RegisterNUICallback('illegalTablet:facture', function(data, cb)
    CloseIllegalTablet()
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

-- Player group creation (from tablet, for unemployed2 players)
RegisterNUICallback('illegalTablet:createGroup', function(data, cb)
    -- This is handled via NUI callback on client, forwarded to server event
    cb('ok')
end)

RegisterNUICallback('illegalTablet:putInVehicle', function(data, cb)
    CloseIllegalTablet()
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

-- NUI Callback: Out of vehicle
RegisterNUICallback('illegalTablet:outVehicle', function(data, cb)
    CloseIllegalTablet()
    Wait(200)
    local player, distance = ESX.Game.GetClosestPlayer()
    if distance ~= -1 and distance <= 3.0 then
        TriggerServerEvent('GangsBuilder:OutVehicle', GetPlayerServerId(player))
    else
        ESX.ShowNotification('Aucun joueur à proximité')
    end
    cb('ok')
end)

-- NUI Callback: Force open/close vehicle
RegisterNUICallback('illegalTablet:forceOpen', function(data, cb)
    CloseIllegalTablet()
    Wait(200)
    local playerPed = PlayerPedId()
    local vehicle = ESX.Game.GetVehicleInDirection()

    if IsPedSittingInAnyVehicle(playerPed) then
        ESX.ShowNotification('Action impossible')
        cb('ok')
        return
    end

    if DoesEntityExist(vehicle) then
        TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)
        Citizen.CreateThread(function()
            Citizen.Wait(10000)
            SetVehicleDoorsLocked(vehicle, 1)
            SetVehicleDoorsLockedForAllPlayers(vehicle, false)
            ClearPedTasksImmediately(playerPed)
            ESX.ShowNotification('Véhicule déverrouillé')
        end)
    else
        ESX.ShowNotification('Pas de véhicule à proximité')
    end
    cb('ok')
end)

-- NUI Callback: BlackMarket buy weapon
RegisterNUICallback('illegalTablet:buyWeapon', function(data, cb)
    TriggerServerEvent('null:tablet:buyWeapon', data.weaponId, data.quantity or 1)
    Wait(500)
    ESX.TriggerServerCallback('null:tablet:getData', function(result)
        cb(result)
    end)
end)

-- NUI Callback: BlackMarket buy item
RegisterNUICallback('illegalTablet:buyItem', function(data, cb)
    TriggerServerEvent('null:tablet:buyItem', data.itemId, data.quantity or 1)
    Wait(500)
    ESX.TriggerServerCallback('null:tablet:getData', function(result)
        cb(result)
    end)
end)

-- NUI Callback: Validate group name/label in real-time
RegisterNUICallback('illegalTablet:validateGroup', function(data, cb)
    ESX.TriggerServerCallback('null:tablet:validateGroup', function(result)
        cb(result)
    end, data.groupName or "", data.groupLabel or "")
end)

-- NUI Callback: Create group (for unemployed2 players)
RegisterNUICallback('illegalTablet:createGroup', function(data, cb)
    TriggerServerEvent('null:tablet:createGroup', data.groupName, data.groupLabel)
    cb('ok')
end)

-- Event: Group created successfully, reopen tablet with gang data
RegisterNetEvent('null:tablet:groupCreated')
AddEventHandler('null:tablet:groupCreated', function()
    -- Close current tablet, wait, then reopen with new gang data
    CloseIllegalTablet()
    Wait(500)
    OpenIllegalTablet()
end)

-- Level up notification
RegisterNetEvent('null:tablet:levelUp')
AddEventHandler('null:tablet:levelUp', function(newLevel)
    ESX.ShowNotification("⬆️ Votre groupe est passé au niveau "..newLevel.."!", "success")
end)
