-- ============================================================================
-- ILLEGAL TABLET DEVICE - Crew bridge (reuses existing null:tablet:* backend)
-- ============================================================================

local function refresh(cb)
    ESX.TriggerServerCallback('null:tablet:getData', function(result)
        cb(result or {})
    end)
end

RegisterNUICallback('illegalDevice:crew:getData', function(_, cb)
    refresh(cb)
end)

RegisterNUICallback('illegalDevice:crew:validateGroup', function(data, cb)
    ESX.TriggerServerCallback('null:tablet:validateGroup', function(result)
        cb(result or {})
    end, data.groupName or '', data.groupLabel or '')
end)

local createdFromDevice = false
RegisterNUICallback('illegalDevice:crew:createGroup', function(data, cb)
    createdFromDevice = true
    TriggerServerEvent('null:tablet:createGroup', data.groupName, data.groupLabel)
    cb({ ok = true })
end)

RegisterNUICallback('illegalDevice:crew:addGrade', function(data, cb)
    TriggerServerEvent('null:tablet:addGrade', data.label)
    Wait(400)
    refresh(cb)
end)

RegisterNUICallback('illegalDevice:crew:removeGrade', function(data, cb)
    TriggerServerEvent('null:tablet:removeGrade', data.gradeName, data.gradePos)
    Wait(400)
    refresh(cb)
end)

RegisterNUICallback('illegalDevice:crew:changeMemberGrade', function(data, cb)
    TriggerServerEvent('null:tablet:changeMemberGrade', data.idunique, data.newGrade)
    Wait(400)
    refresh(cb)
end)

RegisterNUICallback('illegalDevice:crew:kickMember', function(data, cb)
    TriggerServerEvent('null:tablet:kickMember', data.idunique)
    Wait(400)
    refresh(cb)
end)

RegisterNUICallback('illegalDevice:crew:changePerms', function(data, cb)
    TriggerServerEvent('null:tablet:changePerms', data.permType, data.gradeKey, data.value)
    Wait(200)
    cb({ ok = true })
end)

-- Recruit / fire / promote / demote nearest player (closes the device for ped interaction)
local function nearestActionAndClose(eventName, useJob)
    if _G.CloseIllegalDevice then _G.CloseIllegalDevice() end
    Wait(150)
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    if closestDistance ~= -1 and closestDistance <= 3 then
        if useJob then
            TriggerServerEvent(eventName, GetPlayerServerId(closestPlayer), ESX.PlayerData.job2.name)
        else
            TriggerServerEvent(eventName, GetPlayerServerId(closestPlayer))
        end
    else
        ESX.ShowNotification('Aucun joueur à proximité', 'error')
    end
end

RegisterNUICallback('illegalDevice:crew:recruitNearest', function(_, cb)
    nearestActionAndClose('Null:personalmenu:Boss_recruterplayer2', true)
    cb({ ok = true })
end)

RegisterNUICallback('illegalDevice:crew:fireNearest', function(_, cb)
    nearestActionAndClose('Null:personalmenu:Boss_virerplayer2', false)
    cb({ ok = true })
end)

RegisterNUICallback('illegalDevice:crew:promoteNearest', function(_, cb)
    nearestActionAndClose('Null:personalmenu:Boss_promouvoirplayer2', false)
    cb({ ok = true })
end)

RegisterNUICallback('illegalDevice:crew:demoteNearest', function(_, cb)
    nearestActionAndClose('Null:personalmenu:Boss_destituerplayer2', false)
    cb({ ok = true })
end)

RegisterNUICallback('illegalDevice:crew:startMission', function(_, cb)
    TriggerServerEvent('null:missions:fourgon:start')
    cb({ ok = true })
end)

RegisterNetEvent('null:tablet:groupCreated')
AddEventHandler('null:tablet:groupCreated', function()
    SendNUIMessage({ action = 'illegalDevice:crew:groupCreated' })
    if createdFromDevice then
        createdFromDevice = false
        -- Suppress the legacy F7 tablet auto-open after creation
        SetTimeout(700, function()
            if _G.CloseIllegalTablet then _G.CloseIllegalTablet() end
        end)
    end
end)
