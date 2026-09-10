-- ============================================================================
-- Restaurant Craft Tablet — Client
-- Opens the craft React tablet when interacting with craft point
-- ============================================================================

local isCraftTabletOpen = false

function OpenCraftTabletRestaurant()
    if isCraftTabletOpen then return end
    isCraftTabletOpen = true

    ESX.TriggerServerCallback('null:restaurant:getCraftData', function(data)
        if not data then
            isCraftTabletOpen = false
            return
        end

        SendNUIMessage({
            action = 'craftTablet:setData',
            data = data
        })
        SendNUIMessage({ action = 'craftTablet:open' })
        SetNuiFocus(true, true)
    end)
end

RegisterNUICallback('craftTablet:close', function(data, cb)
    isCraftTabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'craftTablet:close' })
    cb('ok')
end)

RegisterNUICallback('craftTablet:refreshData', function(data, cb)
    ESX.TriggerServerCallback('null:restaurant:getCraftData', function(craftData)
        if craftData then
            SendNUIMessage({
                action = 'craftTablet:updateData',
                data = craftData
            })
        end
    end)
    cb('ok')
end)

local isCraftAnimPlaying = false

local function StopCraftAnimation()
    if not isCraftAnimPlaying then return end
    isCraftAnimPlaying = false
    local ped = PlayerPedId()
    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    RemoveAnimDict('amb@prop_human_bbq@male@base')
end

RegisterNUICallback('craftTablet:craft', function(data, cb)
    ESX.TriggerServerCallback('null:restaurant:startCraft', function(result)
        if result and result.started then
            cb({ started = true })

            -- Close the tablet UI
            isCraftTabletOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'craftTablet:close' })

            -- Play cooking animation
            local ped = PlayerPedId()
            local dict = 'amb@prop_human_bbq@male@base'
            local anim = 'base'

            RequestAnimDict(dict)
            while not HasAnimDictLoaded(dict) do Wait(10) end

            isCraftAnimPlaying = true
            FreezeEntityPosition(ped, true)
            TaskPlayAnim(ped, dict, anim, 8.0, 8.0, -1, 1, 0, false, false, false)

            -- Show the null-core progressbar
            local craftTime = (result.time or 5) * 1000
            ShowProgressBar(craftTime, result.label or "Préparation en cours...")
        else
            cb({ started = false, message = result and result.message or "Erreur" })
        end
    end, data.recipeId)
end)

-- Handle craft completion from server — stop animation + notify
RegisterNetEvent('null:restaurant:craftDone', function(success, message)
    StopCraftAnimation()
    HideProgressBar()

    if success then
        ESX.ShowNotification("~g~" .. (message or "Craft réussi !"))
    else
        ESX.ShowNotification("~r~" .. (message or "Craft échoué"))
    end
end)

RegisterNUICallback('craftTablet:inputFocus', function(data, cb)
    cb('ok')
end)

RegisterNUICallback('craftTablet:inputBlur', function(data, cb)
    cb('ok')
end)

-- ── Orders NUI callbacks ─────────────────────────────────────────────
local function refreshCraftTabletData()
    ESX.TriggerServerCallback('null:restaurant:getCraftData', function(craftData)
        if craftData then
            SendNUIMessage({ action = 'craftTablet:updateData', data = craftData })
        end
    end)
end

RegisterNUICallback('craftTablet:getOrders', function(_, cb)
    ESX.TriggerServerCallback('null:restaurant:getOrders', function(orders)
        SendNUIMessage({ action = 'craftTablet:ordersUpdate', data = orders or {} })
        cb('ok')
    end)
end)

RegisterNUICallback('craftTablet:claimOrder', function(data, cb)
    ESX.TriggerServerCallback('null:restaurant:claimOrder', function(ok, msg)
        if not ok then
            ESX.ShowNotification('~r~' .. (msg or 'Impossible de réclamer'))
        end
        refreshCraftTabletData()
        cb({ success = ok })
    end, data.orderId)
end)

RegisterNUICallback('craftTablet:markReady', function(data, cb)
    ESX.TriggerServerCallback('null:restaurant:markReady', function(ok, msg)
        if ok then
            ESX.ShowNotification('~g~Commande marquée comme prête — le client est prévenu')
        else
            ESX.ShowNotification('~r~' .. (msg or 'Impossible'))
        end
        refreshCraftTabletData()
        cb({ success = ok })
    end, data.orderId)
end)

RegisterNUICallback('craftTablet:handOverOrder', function(data, cb)
    ESX.TriggerServerCallback('null:restaurant:handOverOrder', function(ok, msg)
        if ok then
            ESX.ShowNotification('~g~Commande remise au client')
        else
            ESX.ShowNotification('~r~' .. (msg or 'Impossible'))
        end
        refreshCraftTabletData()
        cb({ success = ok })
    end, data.orderId)
end)

RegisterNUICallback('craftTablet:cancelOrder', function(data, cb)
    ESX.TriggerServerCallback('null:restaurant:cancelOrder', function(ok)
        refreshCraftTabletData()
        cb({ success = ok })
    end, data.orderId)
end)

-- Auto-refresh whenever a new order is received while the tablet is open
RegisterNetEvent('null:restaurant:orderReceived', function()
    if isCraftTabletOpen then refreshCraftTabletData() end
end)

-- Listen for server NUI messages
RegisterNetEvent('null:nui:send', function(msg)
    SendNUIMessage(msg)
end)

-- Make function globally available so the marker Action can call it
_G.OpenCraftTabletRestaurant = OpenCraftTabletRestaurant
