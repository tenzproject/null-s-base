local UIReady = false

RegisterNUICallback('ui_ready', function(data, cb)
    UIReady = true
    null.InitPrint('^2UI ready (v' .. (data.version or '?') .. ')^7')
    
    SendNUIMessage({ 
        action = 'setConfig',
        data = {
            serverName = ESX.Config and ESX.Config('serverName') or 'Null', 
            serverColor = ESX.Config and ESX.Config('hexcolor') or '#9b59b6',
            serverLuaColor = ESX.Config and ESX.Config('serverColor') or '~b~',
            serverIcon = ESX.Config and ESX.Config('serverCHAR') or '',
            serverDiscord = ESX.Config and ESX.Config('serverDiscord') or '',
            serverBackground = ESX.Config and ESX.Config('backgroundBanner') or ''
        },
        serverName = ESX.Config and ESX.Config('serverName') or 'Null', 
        serverColor = ESX.Config and ESX.Config('hexcolor') or '#9b59b6',
        serverLuaColor = ESX.Config and ESX.Config('serverColor') or '~b~',
        serverIcon = ESX.Config and ESX.Config('serverCHAR') or '',
        serverDiscord = ESX.Config and ESX.Config('serverDiscord') or '',
        serverBackground = ESX.Config and ESX.Config('backgroundBanner') or ''
    })
    
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(data, cb)
    if null and null.modules and null.modules.ui and null.modules.ui.interactions then
        local HUDEditor = null.modules.ui.interactions.HUDEditor
        if HUDEditor and HUDEditor.isOpen then
            HUDEditor.Close(true)
            cb('ok')
            return
        end
    end
    
    SetNuiFocus(false, false)
    cb('ok')
end)

function SetHUDDisplay(opacity)
    SendNUIMessage({
        action = 'setHUDDisplay',
        opacity = opacity
    })
end

function InsertHUDElement(name, index, priority, html, data)
    SendNUIMessage({
        action = 'insertHUDElement',
        name = name,
        index = index,
        priority = priority,
        html = html,
        data = data or {}
    })
end

function UpdateHUDElement(name, data)
    SendNUIMessage({
        action = 'updateHUDElement',
        name = name,
        data = data
    })
end

function DeleteHUDElement(name)
    SendNUIMessage({
        action = 'deleteHUDElement',
        name = name
    })
end

function HideUI(hide)
    SendNUIMessage({
        action = 'hideUi',
        value = hide
    })
end

function FadeUI(hide)
    SendNUIMessage({
        action = 'fadeUi',
        value = hide
    })
end

exports('SetHUDDisplay', SetHUDDisplay)
exports('InsertHUDElement', InsertHUDElement)
exports('UpdateHUDElement', UpdateHUDElement)
exports('DeleteHUDElement', DeleteHUDElement)
exports('HideUI', HideUI)
exports('FadeUI', FadeUI)

function ShowNotification(text, type, duration)
    SendNUIMessage({
        action = 'notify',
        text = text,
        type = type or 'info',
        duration = duration
    })
end

function InventoryNotification(add, label, count, name)
    SendNUIMessage({
        action = 'inventoryNotification',
        add = add,
        label = label,
        name = name,
        count = count or 1
    })
end

exports('ShowNotification', ShowNotification)
exports('InventoryNotification', InventoryNotification)

null.InitPrint('^2UI module loaded^7')
