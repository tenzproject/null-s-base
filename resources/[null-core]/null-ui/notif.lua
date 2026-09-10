Config = Config or {}

notificationsEnabled = true

Config.Timeout          = 8000          -- Overridden by the `timeout` param
Config.Position         = "bottomleft"  -- Overridden by the `position` param
Config.Progress         = true         -- Overridden by the `progress` param
Config.Theme            = "default"     -- Overridden by the `theme` param
Config.Queue            = 5             -- No. of notifications to show before queueing
Config.Stacking         = true
Config.ShowStackedCount = true
Config.AnimationOut     = "fadeOut";    -- Exit animation - 'fadeOut', 'fadeOutLeft', 'flipOutX', 'flipOutY', 'bounceOutLeft', 'backOutLeft', 'slideOutLeft', 'zoomOut', 'zoomOutLeft'
Config.AnimationTime    = 800           -- Entry / exit animation interval
Config.FlashCount       = 5            -- No. of times to flash the notification
Config.FlashType       = "flash"        -- No. of times to flash the notification
Config.SoundFile        = false         -- Sound file stored in ui/audio used for notification sound. Leave as false to disable.
Config.SoundVolume      = 0.4           -- 0.0 - 1.0
Config.Pictures = {
    call = "call.png",
    CHAR_ANO = "Char_anonyme.png",
    CHAR_MORT = "Char_lester_deathwish.jpg",
    CHAR_PUTE = "Char_stripper_peach.jpg",
    CHAR_TAXI = "Char_taxi.jpg",
    CHAR_TWT = "Char_twitter.png",
    CHAR_JEROME = "Dia_jerome.jpg",
    CHAR_REZU = "CHAR_REZU.png",
    CHAR_BAHAMAS = "CHAR_BAHAMAS.png",
    CHAR_LOGO = "CHAR_LOGO.png",

    CHAR_BURGERSHOT = "CHAR_BURGERSHOT.png",
    CHAR_EMS = "CHAR_EMS.png",
    CHAR_LSCUSTOM = "CHAR_LSCUSTOM.png",
    CHAR_AUTOEXOTIC = "CHAR_AUTOEXOTIC.png",
    CHAR_TABAC = "tabacJob.png",
    CHAR_GOUV = "gouvJob.png",
    CHAR_BENNYS = "CHAR_BENNYS.jpg",
    CHAR_MOTORCYCLE = "Char_bikesite.jpg",
    CHAR_LSPD = "lspd.png",
    CHAR_MP_MORS_MUTUAL = "CHAR_VIGNERON.png",
    CHAR_CONCESSAUTO = "CHAR_CONCESSAUTO.png",
    CHAR_CALL911 = "CHAR_CALL911.png",
    CHAR_MARTIN = "dynasty.jpg",
    CHAR_STRIPPER_PEACH = "CHAR_UNICORN.png",
    CHAR_BANK_FLEECA = "CHAR_BANK_FLEECA.png"
}


math.randomseed(GetGameTimer())

local notifications = {}

function Send(message, couleurProgress, timeout, position, progress, theme, exitAnim, pin_id)
    if notificationsEnabled == false then
        return
    end
    if type(message) == 'table' then
        SendCustom(message)
        return
    end

    if message == nil then
        return PrintError("^1BULLETIN ERROR: ^7Notification message is nil")
    end

    message = tostring(message)

    if not tonumber(timeout) then
        timeout = Config.Timeout
    end
    
    if position == nil then
        position = Config.Position
    end
    
    if progress == nil then
        progress = Config.Progress
    end

    local id = nil
    local duplicateID = DuplicateCheck(message)
    if duplicateID then
        id = duplicateID
    else
        id = uuid(message)
        notifications[id] = message
    end
    

    AddNotification({
        duplicate   = duplicateID ~= false,
        --duplicate   = false,
        id          = id,
        type        = "standard",
        message     = message,
        couleurProgress = couleurProgress or ESX.Config("hexcolor"),
        timeout     = timeout,
        position    = position,
        progress    = progress,
        theme       = theme,
        exitAnim    = exitAnim,
        pin_id      = pin_id,
    })        
end

function SendAdvanced(message, title, subject, couleurProgress, icon, timeout, position, progress, theme, exitAnim, pin_id)
    if notificationsEnabled == false then
        return
    end
    if type(message) == 'table' then
        SendCustom(message, true)
        return
    end

    if message == nil then
        return PrintError("^1BULLETIN ERROR: ^7Notification message is nil")
    end

    message = tostring(message)

    if title == nil then
        return PrintError("^1BULLETIN ERROR: ^7Notification title is nil")
    end
    
    --if subject == nil then
    --    return PrintError("^1BULLETIN ERROR: ^7Notification subject is nil")
    --end    

    if not tonumber(timeout) or timeout == 0 then
        timeout = Config.Timeout
    end
    
    if position == nil then
        position = Config.Position
    end
    
    if progress == nil then
        progress = Config.Progress
    end  

    local id = nil
    local duplicateID = DuplicateCheck(message)

    if duplicateID then
        id = duplicateID
    else
        id = uuid(message)
        notifications[id] = message
    end
    print(id, duplicateID, timeout)

    AddNotification({
        duplicate   = duplicateID ~= false,
        --duplicate   = false,
        id          = id,
        type        = "advanced",
        message     = message,
        title       = title,
        --subject     = subject,
        couleurProgress = couleurProgress or ESX.Config("hexcolor"),
        icon        = icon or ESX.Config("serverCHAR"),
        timeout     = timeout,
        position    = position,
        progress    = progress,
    })
end


function SendAccept(message, title, subject, couleurProgress, icon, timeout, position, progress, theme, exitAnim, pin_id)
    if notificationsEnabled == false then
        return
    end
    if type(message) == 'table' then
        SendCustom(message, true)
        return
    end

    if message == nil then
        return PrintError("^1BULLETIN ERROR: ^7Notification message is nil")
    end

    message = tostring(message)

    if title == nil then
        return PrintError("^1BULLETIN ERROR: ^7Notification title is nil")
    end
    
    --if subject == nil then
    --    return PrintError("^1BULLETIN ERROR: ^7Notification subject is nil")
    --end    

    if not tonumber(timeout) then
        timeout = Config.Timeout
    end
    
    if position == nil then
        position = Config.Position
    end
    
    if progress == nil then
        progress = Config.Progress
    end  

    local id = nil
    local duplicateID = DuplicateCheck(message)

    if duplicateID then
        id = duplicateID
    else
        id = uuid(message)
        notifications[id] = message
    end
    AddNotification({
        duplicate   = duplicateID ~= false,
        id          = id,
        type        = "accept",
        message     = message,
        title       = title,
        --subject     = subject,
        couleurProgress = couleurProgress or ESX.Config("hexcolor"),
        icon        = icon or ESX.Config("serverCHAR"),
        timeout     = timeout,
        position    = position,
        progress    = progress,
    })
end

function SendPinned(options)
    local pin_id = uuid()
    options.pin_id = pin_id

    SendCustom(options)

    return pin_id
end


function Unpin(pinned)
    SendNUIMessage({
        type = 'unpin',
        pin_id = pinned
    })
end

function UpdatePinned(pinned, options)
    if options.icon ~= nil then
        options.icon = Config.Pictures[options.icon]
    end

    SendNUIMessage({
        type = 'update_pinned',
        pin_id = pinned,
        options = options
    })
end

function SendCustom(options, advanced)
    if type(options) ~= 'table' then
        error("BULLETIN ERROR: options passed to `SendCustom` must be a table")
    end
    if options.type == "standard" or options.type == nil and not advanced then
        Send(options.message, options.timeout, options.position, options.progress, options.theme, options.exitAnim, options.pin_id)
    elseif advanced ~= nil or options.type == "advanced" then
        SendAdvanced(options.message, options.title, options.subject, options.icon, options.timeout, options.position, options.progress, options.theme, options.exitAnim, options.pin_id)
    end
end

function AddNotification(data)
    data.config = Config
    SendNUIMessage(data)
end

function PrintError(message)
    local s = string.rep("=", string.len(message))
end

function DuplicateCheck(message)
    for id, msg in pairs(notifications) do
        if msg == message then
            return id
        end
    end

    return false
end

function uuid()
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
end

RegisterNetEvent("notifY:send")
AddEventHandler("notifY:send", Send)

RegisterNetEvent("notifY:sendAdvanced")
AddEventHandler("notifY:sendAdvanced", SendAdvanced)

RegisterNetEvent("notifY:sendAccept")
AddEventHandler("notifY:sendAccept", SendAccept)

RegisterNUICallback("nui_removed", function(data, cb)
    notifications[data.id] = nil
    cb('ok')
end)

RegisterCommand("Pablotest", function()
    SendAdvanced("Prise de service d'un staff", "STAFF MODE", "Notification", nil, nil, 500000, "bottomleft", true)
end)

RegisterCommand("Pablotest2", function()
    Send("Pablo le goat", nil, 60000, "bottomleft")
end)

RegisterCommand("Pablotest3", function()
    SendAccept("Prise de service d'un staff", "STAFF MODE", "Notification", nil, nil, 500000, "bottomleft", true)
end)


exports("displayNotif",function(bool)
    notificationsEnabled = bool
end)