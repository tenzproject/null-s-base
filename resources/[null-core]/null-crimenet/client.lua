-- ============================================================================
-- CRIMENET v2 - Client (lb-phone app + game bridge)
-- Social network, contacts, messaging, network visualization + GoFast missions
-- ============================================================================

local appOpen = false
local crimeNetData = nil
local isIllegalMember = false
local activeContract = nil

-- ============================================================================
-- SEND MESSAGE TO APP (via lb-phone iframe routing)
-- ============================================================================
local function SendAppMessage(action, data)
    exports["lb-phone"]:SendCustomAppMessage(CrimeNet.App.identifier, {
        action = action,
        data = data
    })
end

-- ============================================================================
-- ILLEGAL GROUP CHECK
-- ============================================================================
local function checkIllegalStatus()
    if ESX and ESX.PlayerData and ESX.PlayerData.job2 then
        local gangName = ESX.PlayerData.job2.name
        local illegals = exports["null-core"]:getData("illegals") 
        if illegals and illegals.groups and illegals.groups.list and illegals.groups.list[gangName] ~= nil then
            isIllegalMember = true
            return true
        end
    end
    isIllegalMember = false
    return false
end

-- ============================================================================
-- APP REGISTRATION
-- ============================================================================
local function registerApp()
    local added, err = exports["lb-phone"]:AddCustomApp({
        identifier = CrimeNet.App.identifier,
        name = CrimeNet.App.name,
        description = CrimeNet.App.description,
        developer = CrimeNet.App.developer,
        defaultApp = CrimeNet.App.defaultApp,
        size = CrimeNet.App.size,
        icon = CrimeNet.App.icon,
        ui = GetCurrentResourceName() .. "/ui/index.html",
        fixBlur = true,
    })

    if not added then
        print("[CrimeNet] Erreur enregistrement app: " .. tostring(err))
    end
end

if GetResourceState("lb-phone") == "started" then
    registerApp()
end

AddEventHandler("onResourceStart", function(resource)
    if resource == "lb-phone" then
        registerApp()
    end
end)

-- ============================================================================
-- APP OPEN → determine mode + load CrimeNet data
-- ============================================================================
RegisterNUICallback("crimenet:appOpened", function(data, cb)
    appOpen = true
    checkIllegalStatus()

    if isIllegalMember then
        SendAppMessage("crimenet:setMode", { mode = "real" })

        -- Load full CrimeNet data (profile, contacts, conversations, network, groups)
        ESX.TriggerServerCallback("CrimeNet:getData", function(cnData)
            crimeNetData = cnData
            SendAppMessage("crimenet:fullData", cnData)
        end)

        -- Also load GoFast mission data
        ESX.TriggerServerCallback("Null:gofast:getProfileData", function(result)
            SendAppMessage("crimenet:goFastData", result)
            updateCooldownTracking(result)
        end)
    else
        SendAppMessage("crimenet:setMode", { mode = "fake" })
    end

    cb("ok")
end)

RegisterNUICallback("crimenet:appClosed", function(data, cb)
    appOpen = false
    crimeNetData = nil
    cb("ok")
end)

-- ============================================================================
-- REFRESH DATA
-- ============================================================================
RegisterNUICallback("crimenet:refreshData", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:getData", function(cnData)
        crimeNetData = cnData
        cb(cnData)
    end)
end)

RegisterNUICallback("crimenet:refreshGoFast", function(data, cb)
    ESX.TriggerServerCallback("Null:gofast:getProfileData", function(result)
        cb(result)
        updateCooldownTracking(result)
    end)
end)

-- ============================================================================
-- CONTACT MANAGEMENT (NUI callbacks from React)
-- ============================================================================
RegisterNUICallback("crimenet:addContact", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:addContact", function(success, err)
        cb({ success = success, error = err })
    end, data.identifier, data.nickname)
end)

RegisterNUICallback("crimenet:removeContact", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:removeContact", function(success)
        cb({ success = success })
    end, data.identifier)
end)

RegisterNUICallback("crimenet:shareContact", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:shareContact", function(success, err)
        cb({ success = success, error = err })
    end, data.contactIdentifier, data.targetServerId)
end)

RegisterNUICallback("crimenet:searchPlayers", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:searchPlayers", function(results)
        cb(results)
    end, data.query)
end)

RegisterNUICallback("crimenet:findByCrimenetId", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:findByCrimenetId", function(result, err)
        if result then
            cb({ success = true, player = result })
        else
            cb({ success = false, error = err })
        end
    end, data.crimenetId)
end)

-- ============================================================================
-- MESSAGING (NUI callbacks from React)
-- ============================================================================
RegisterNUICallback("crimenet:sendMessage", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:sendMessage", function(success, msgId)
        cb({ success = success, id = msgId })
    end, data.toIdentifier, data.content)
end)

RegisterNUICallback("crimenet:getConversation", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:getConversation", function(messages)
        cb(messages)
    end, data.otherIdentifier, data.page or 1)
end)

-- ============================================================================
-- GROUP CHAT (NUI callbacks from React)
-- ============================================================================
RegisterNUICallback("crimenet:createGroup", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:createGroup", function(success, groupIdOrErr)
        cb({ success = success, groupId = success and groupIdOrErr or nil, error = not success and groupIdOrErr or nil })
    end, data.name, data.memberIdentifiers)
end)

RegisterNUICallback("crimenet:sendGroupMessage", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:sendGroupMessage", function(success, msgId)
        cb({ success = success, id = msgId })
    end, data.groupId, data.content)
end)

RegisterNUICallback("crimenet:getGroupMessages", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:getGroupMessages", function(messages)
        cb(messages)
    end, data.groupId, data.page or 1)
end)

RegisterNUICallback("crimenet:getGroupMembers", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:getGroupMembers", function(members)
        cb(members)
    end, data.groupId)
end)

RegisterNUICallback("crimenet:addGroupMember", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:addGroupMember", function(success, err)
        cb({ success = success, error = err })
    end, data.groupId, data.memberIdentifier)
end)

RegisterNUICallback("crimenet:leaveGroup", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:leaveGroup", function(success)
        cb({ success = success })
    end, data.groupId)
end)

-- ============================================================================
-- PROFILE UPDATE (NUI callbacks from React)
-- ============================================================================
RegisterNUICallback("crimenet:updateProfile", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:updateProfile", function(success, err)
        cb({ success = success, error = err })
    end, data.fields or {})
end)

-- Pick photo from lb-phone gallery
RegisterNUICallback("crimenet:pickPhoto", function(data, cb)
    exports["lb-phone"]:ShowComponent({
        component = "gallery",
    }, function(image)
        if image then
            cb({ success = true, url = image })
        else
            cb({ success = false })
        end
    end)
end)

-- ============================================================================
-- GOFAST MISSION CALLBACKS (kept from v1)
-- ============================================================================
RegisterNUICallback("crimenet:requestMission", function(data, cb)
    TriggerServerEvent("Null:gofast:requestMission", "solo")
    cb("ok")
end)

RegisterNUICallback("crimenet:requestCrewMission", function(data, cb)
    if data and data.members and type(data.members) == "table" then
        -- New flow: crew mission with selected member server IDs
        TriggerServerEvent("Null:gofast:requestCrewMission", data.members)
    else
        -- Legacy fallback
        TriggerServerEvent("Null:gofast:requestMission", "crew")
    end
    cb("ok")
end)

RegisterNUICallback("crimenet:getCrewMembers", function(data, cb)
    ESX.TriggerServerCallback("Null:gofast:getCrewMembers", function(members)
        cb(members or {})
    end)
end)

-- ============================================================================
-- MARKETPLACE NUI CALLBACKS
-- ============================================================================
RegisterNUICallback("crimenet:market:create", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:market:create", function(success, err)
        cb({ success = success, error = err })
    end, data)
end)

RegisterNUICallback("crimenet:market:markSold", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:market:markSold", function(success)
        cb({ success = success })
    end, data.listingId)
end)

RegisterNUICallback("crimenet:market:delete", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:market:delete", function(success)
        cb({ success = success })
    end, data.listingId)
end)

RegisterNUICallback("crimenet:market:contact", function(data, cb)
    -- Open or create a DM conversation with the seller
    ESX.TriggerServerCallback("CrimeNet:sendMessage", function(success)
        cb({ success = success })
    end, data.sellerId, "Bonjour, je suis intéressé par votre annonce sur le Marché Noir.")
end)

-- ============================================================================
-- CONTRACT SYSTEM CALLBACKS
-- ============================================================================
RegisterNUICallback("crimenet:getContracts", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:getContracts", function(contracts)
        cb(contracts or {})
    end)
end)

RegisterNUICallback("crimenet:getActiveContract", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:getActiveContract", function(contract)
        cb(contract)
    end)
end)

RegisterNUICallback("crimenet:acceptContract", function(data, cb)
    ESX.TriggerServerCallback("CrimeNet:acceptContract", function(success, result)
        if success then
            -- Start the GoFast mission for this contract
            if result.type == 'crew' then
                TriggerServerEvent("Null:gofast:requestCrewMission", data.crewMembers)
            else
                TriggerServerEvent("Null:gofast:requestMission", 'solo')
            end
            TriggerServerEvent("Null:crimenet:missionStarted")
        end
        cb({ success = success, result = result })
    end, { contractId = data.contractId, crewMembers = data.crewMembers })
end)

-- Contract mission events
RegisterNetEvent("crimenet:contractMission")
AddEventHandler("crimenet:contractMission", function(data)
    if appOpen then
        SendAppMessage("crimenet:activeContract", data)
    end
    -- Store active contract for mission result handling
    activeContract = data
end)

-- Forward GoFast mission results to contract system
RegisterNetEvent("Null:gofast:result")
AddEventHandler("Null:gofast:result", function(data)
    if activeContract then
        if data.success then
            TriggerServerEvent("Null:crimenet:missionCompleted")
        else
            TriggerServerEvent("Null:crimenet:missionFailed", data.reason or "FAILED")
        end
        activeContract = nil
    end
    -- Original handling continues below...
end)

-- ============================================================================
-- GAME EVENTS → UI FORWARDING
-- ============================================================================

-- Mission response from server → forward to UI
RegisterNetEvent("Null:gofast:missionResponse")
AddEventHandler("Null:gofast:missionResponse", function(data)
    if appOpen then
        SendAppMessage("crimenet:missionResponse", data)
    end
end)

-- Mission result → forward to UI + phone notification
RegisterNetEvent("Null:gofast:result")
AddEventHandler("Null:gofast:result", function(data)
    if appOpen then
        SendAppMessage("crimenet:missionResult", data)
    end

    if data.success then
        exports["lb-phone"]:SendNotification({
            app = CrimeNet.App.identifier,
            title = "Mission terminée",
            content = "Récompense : $" .. (data.payment or 0),
        })
    else
        exports["lb-phone"]:SendNotification({
            app = CrimeNet.App.identifier,
            title = "Mission échouée",
            content = "XP perdue : -" .. (data.xpLost or 0),
        })
    end
end)

-- GoFast profile refresh → forward to UI
RegisterNetEvent("Null:gofast:profileRefresh")
AddEventHandler("Null:gofast:profileRefresh", function(data)
    if data then
        updateCooldownTracking(data)
        if appOpen then
            SendAppMessage("crimenet:goFastData", data)
        end
    end
end)

-- Betrayal notification → forward to UI + phone notification
RegisterNetEvent("Null:gofast:betrayed")
AddEventHandler("Null:gofast:betrayed", function()
    if appOpen then
        SendAppMessage("crimenet:betrayed", {})
    end
    exports["lb-phone"]:SendNotification({
        app = CrimeNet.App.identifier,
        title = "⚠ TRAHISON DÉTECTÉE",
        content = "Tu as été blacklisté du réseau. Le cartel te cherche.",
    })
end)

-- New message notification from server
RegisterNetEvent("CrimeNet:newMessage")
AddEventHandler("CrimeNet:newMessage", function(data)
    if appOpen then
        SendAppMessage("crimenet:newMessage", data)
    end
    exports["lb-phone"]:SendNotification({
        app = CrimeNet.App.identifier,
        title = data.from_name or "Message",
        content = string.sub(data.content or "", 1, 80),
    })
end)

-- New group message notification from server
RegisterNetEvent("CrimeNet:newGroupMessage")
AddEventHandler("CrimeNet:newGroupMessage", function(data)
    if appOpen then
        SendAppMessage("crimenet:newGroupMessage", data)
    end
    exports["lb-phone"]:SendNotification({
        app = CrimeNet.App.identifier,
        title = "Groupe",
        content = (data.from_name or "?") .. ": " .. string.sub(data.content or "", 1, 60),
    })
end)

-- Contact shared notification from server
RegisterNetEvent("CrimeNet:contactShared")
AddEventHandler("CrimeNet:contactShared", function(data)
    if appOpen then
        SendAppMessage("crimenet:contactShared", data)
    end
    exports["lb-phone"]:SendNotification({
        app = CrimeNet.App.identifier,
        title = "Nouveau contact",
        content = (data.from or "Quelqu'un") .. " t'a partagé un contact.",
    })
end)

-- ============================================================================
-- PHONE NOTIFICATION ON COOLDOWN END
-- ============================================================================
local cooldownEndTime = 0
local cooldownNotified = true -- start as true so we don't notify on first load

-- Track cooldown from gofast data
function updateCooldownTracking(data)
    if not data then return end
    local cd = math.max(data.soloCooldown or 0, data.crewCooldown or 0)
    if cd > 0 then
        cooldownEndTime = GetGameTimer() + (cd * 1000)
        cooldownNotified = false
    elseif cooldownEndTime > 0 and not cooldownNotified then
        -- Cooldown just ended (data says 0 but we were tracking one)
        cooldownEndTime = 0
        cooldownNotified = true
    end
end

Citizen.CreateThread(function()
    while true do
        Wait(5000)
        if cooldownEndTime > 0 and not cooldownNotified then
            if GetGameTimer() >= cooldownEndTime then
                cooldownNotified = true
                cooldownEndTime = 0
                -- Send phone notification
                exports["lb-phone"]:SendNotification({
                    app = CrimeNet.App.identifier,
                    title = "CrimeNet",
                    content = "Nouveau contrat disponible.",
                })
                -- Also refresh UI if app is open
                if appOpen then
                    ESX.TriggerServerCallback("Null:gofast:getProfileData", function(result)
                        SendAppMessage("crimenet:goFastData", result)
                    end)
                end
            end
        end
    end
end)
