local notificationsEnabled = true
local notifications = {}
null.modules.notifications = {
    initialized = false,
}

-- Generate UUID
local function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

-- Check for duplicate notifications
local function DuplicateCheck(message)
    for id, msg in pairs(notifications) do
        if msg == message then
            return id
        end
    end
    return false
end

-- Send standard notification
function SendNotification(message, couleurProgress, timeout, progress, theme, exitAnim, pin_id)
    if not notificationsEnabled then
        return
    end

    if type(message) == 'table' then
        SendCustomNotification(message)
        return
    end

    if message == nil then
        null.DebugPrint("^1NOTIFICATION ERROR: ^7Notification message is nil")
        return
    end

    message = tostring(message)

    if not tonumber(timeout) then
        timeout = 8000
    end
    
    if progress == nil then
        progress = true
    end

    local id = nil
    local duplicateID = DuplicateCheck(message)
    if duplicateID then
        id = duplicateID
    else
        id = uuid()
        notifications[id] = message
    end

    SendNUIMessage({
        duplicate   = duplicateID ~= false,
        id          = id,
        type        = "standard",
        message     = message,
        couleurProgress = couleurProgress or ESX.Config("hexcolor"),
        timeout     = timeout,
        progress    = progress,
        theme       = theme,
        exitAnim    = exitAnim,
        pin_id      = pin_id,
    })
end

-- Send advanced notification (with title, subject, icon)
function SendAdvancedNotification(message, title, subject, couleurProgress, icon, timeout, progress, theme, exitAnim, pin_id)
    if not notificationsEnabled then
        return
    end

    if type(message) == 'table' then
        SendCustomNotification(message, true)
        return
    end

    if message == nil then
        null.DebugPrint("^1NOTIFICATION ERROR: ^7Notification message is nil")
        return
    end

    message = tostring(message)

    if title == nil then
        null.DebugPrint("^1NOTIFICATION ERROR: ^7Notification title is nil")
        return
    end

    if not tonumber(timeout) or timeout == 0 then
        timeout = 8000
    end
    
    if progress == nil then
        progress = true
    end

    local id = nil
    local duplicateID = DuplicateCheck(message)

    if duplicateID then
        id = duplicateID
    else
        id = uuid()
        notifications[id] = message
    end

    SendNUIMessage({
        duplicate   = duplicateID ~= false,
        id          = id,
        type        = "advanced",
        message     = message,
        title       = title,
        subject     = subject,
        couleurProgress = couleurProgress or ESX.Config("hexcolor"),
        icon        = icon or ESX.Config("serverCHAR"),
        timeout     = timeout,
        progress    = progress,
        theme       = theme,
        exitAnim    = exitAnim,
        pin_id      = pin_id,
    })
end

-- Send accept notification (with accept/refuse buttons)
function SendAcceptNotification(message, title, subject, couleurProgress, icon, timeout, progress, theme, exitAnim, pin_id)
    if not notificationsEnabled then
        return
    end

    if type(message) == 'table' then
        SendCustomNotification(message, true)
        return
    end

    if message == nil then
        null.DebugPrint("^1NOTIFICATION ERROR: ^7Notification message is nil")
        return
    end

    message = tostring(message)

    if title == nil then
        title = "DEMANDE"
    end

    if not tonumber(timeout) then
        timeout = 30000
    end
    
    if progress == nil then
        progress = false
    end

    local id = nil
    local duplicateID = DuplicateCheck(message)

    if duplicateID then
        id = duplicateID
    else
        id = uuid()
        notifications[id] = message
    end

    SendNUIMessage({
        duplicate   = duplicateID ~= false,
        id          = id,
        type        = "accept",
        message     = message,
        title       = title,
        subject     = subject,
        couleurProgress = couleurProgress or ESX.Config("hexcolor"),
        icon        = icon or ESX.Config("serverCHAR"),
        timeout     = timeout,
        progress    = progress,
        theme       = theme,
        exitAnim    = exitAnim,
        pin_id      = pin_id,
    })
end

-- Send pinned notification
function SendPinnedNotification(options)
    local pin_id = uuid()
    options.pin_id = pin_id

    SendCustomNotification(options)

    return pin_id
end

-- Unpin notification
function UnpinNotification(pinned)
    SendNUIMessage({
        type = 'unpin',
        pin_id = pinned
    })
end

-- Update pinned notification
function UpdatePinnedNotification(pinned, options)
    SendNUIMessage({
        type = 'update_pinned',
        pin_id = pinned,
        options = options
    })
end

-- Send custom notification
function SendCustomNotification(options, advanced)
    if type(options) ~= 'table' then
        null.DebugPrint("^1NOTIFICATION ERROR: ^7options passed to SendCustomNotification must be a table")
        return
    end

    if options.type == "standard" or options.type == nil and not advanced then
        SendNotification(options.message, options.couleurProgress, options.timeout, options.progress, options.theme, options.exitAnim, options.pin_id)
    elseif advanced ~= nil or options.type == "advanced" then
        SendAdvancedNotification(options.message, options.title, options.subject, options.couleurProgress, options.icon, options.timeout, options.progress, options.theme, options.exitAnim, options.pin_id)
    elseif options.type == "accept" then
        SendAcceptNotification(options.message, options.title, options.subject, options.couleurProgress, options.icon, options.timeout, options.progress, options.theme, options.exitAnim, options.pin_id)
    end
end

-- Enable/disable notifications
function SetNotificationsEnabled(bool)
    notificationsEnabled = bool
end

-- NUI Callback when notification is removed
RegisterNUICallback("nui_removed", function(data, cb)
    notifications[data.id] = nil
    cb('ok')
end)

-- NUI Callback for accept/refuse response
RegisterNUICallback("notificationResponse", function(data, cb)
    -- Trigger event with response
    TriggerEvent('null:notificationResponse', data.id, data.response)
    cb('ok')
end)

-- Events
RegisterNetEvent("null:notification")
AddEventHandler("null:notification", SendNotification)

RegisterNetEvent("null:notificationAdvanced")
AddEventHandler("null:notificationAdvanced", SendAdvancedNotification)

RegisterNetEvent("null:notificationAccept")
AddEventHandler("null:notificationAccept", SendAcceptNotification)

-- Exports
exports('SendNotification', SendNotification)
exports('SendAdvancedNotification', SendAdvancedNotification)
exports('SendAcceptNotification', SendAcceptNotification)
exports('SendPinnedNotification', SendPinnedNotification)
exports('UnpinNotification', UnpinNotification)
exports('UpdatePinnedNotification', UpdatePinnedNotification)
exports('SetNotificationsEnabled', SetNotificationsEnabled)

-- Test Commands
RegisterCommand("testnotif", function()
    SendNotification("Ceci est une notification de test standard", nil, 5000, true, "default")
end)

RegisterCommand("testnotif_success", function()
    SendNotification("Opération réussie avec succès!", nil, 5000, true, "success")
end)

RegisterCommand("testnotif_error", function()
    SendNotification("Une erreur s'est produite!", nil, 5000, true, "error")
end)

RegisterCommand("testnotif_warning", function()
    SendNotification("Attention! Ceci est un avertissement", nil, 5000, true, "warning")
end)

RegisterCommand("testnotif_info", function()
    SendNotification("Information importante", nil, 5000, true, "info")
end)


RegisterCommand("testnotif_normal", function()
    SendAdvancedNotification(
        "Prise de service d'un staff",
        "ADMINISTRATION",
        nil,
        nil,
        nil,
        8000,
        true,
        "default"
    )
end)

RegisterCommand("testnotif_advanced", function()
    SendAdvancedNotification(
        "Vous avez reçu un nouveau message de la part de l'administration",
        "ADMINISTRATION",
        "Message Important",
        nil,
        nil,
        8000,
        true,
        "default"
    )
end)

RegisterCommand("testnotif_advanced_long", function()
    SendAdvancedNotification(
        "Vous avez reçu un nouveau message de la part de l'administration",
        nil,
        "Message Important",
        nil,
        nil,
        100000,
        true,
        "default"
    )
end)

RegisterCommand("testnotif_accept", function()
    SendAcceptNotification(
        "Voulez-vous accepter cette demande de téléportation?",
        "TÉLÉPORTATION",
        "Demande en attente",
        nil,
        nil,
        30000,
        false,
        "info"
    )
end)

RegisterCommand("testnotif_pinned", function()
    local pin_id = SendPinnedNotification({
        type = "advanced",
        message = "Cette notification est épinglée et ne disparaîtra pas automatiquement",
        title = "NOTIFICATION ÉPINGLÉE",
        subject = "Permanent",
        icon = "https://i.imgur.com/placeholder.png",
        progress = false,
        theme = "warning"
    })
    
    null.DebugPrint("Notification épinglée avec ID: " .. pin_id)
    
    -- Exemple: Unpin après 10 secondes
    SetTimeout(10000, function()
        UnpinNotification(pin_id)
        null.DebugPrint("Notification dépinglée")
    end)
end)

RegisterCommand("testnotif_stack", function()
    -- Envoyer plusieurs notifications identiques pour tester le stacking
    for i = 1, 5 do
        SetTimeout(i * 500, function()
            SendNotification("Message dupliqué pour test de stack", nil, 10000, true, "default")
        end)
    end
end)

null.modules.notifications.initialized = true
null.InitPrint("Système de notifications chargé")