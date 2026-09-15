local UIReady = false

local function getRuntimeConfig(name, fallback)
    local value = GetConvar(name, '')
    if value == '' and ESX and ESX.Config then
        value = ESX.Config(name) or ''
    end
    return value ~= '' and value or (fallback or '')
end

local function getRuntimeBanner()
    local banner = GetConvar('backgroundBanner', '')
    if banner == '' then banner = GetConvar('bannerUrl', '') end
    if banner == '' and ESX and ESX.Config then
        banner = ESX.Config('backgroundBanner') or ESX.Config('bannerUrl') or ''
    end
    return banner
end

RegisterNUICallback('ui_ready', function(data, cb)
    UIReady = true
    null.InitPrint('^2UI ready (v' .. (data.version or '?') .. ')^7')
    
    SendNUIMessage({ 
        action = 'setConfig',
        data = {
            serverName = getRuntimeConfig('serverName', 'Null'),
            serverColor = getRuntimeConfig('hexcolor', '#BEEE11'),
            serverLuaColor = getRuntimeConfig('serverColor', '~b~'),
            serverIcon = getRuntimeConfig('serverCHAR', ''),
            serverDiscord = getRuntimeConfig('serverDiscord', ''),
            serverBackground = getRuntimeBanner()
        },
        serverName = getRuntimeConfig('serverName', 'Null'),
        serverColor = getRuntimeConfig('hexcolor', '#BEEE11'),
        serverLuaColor = getRuntimeConfig('serverColor', '~b~'),
        serverIcon = getRuntimeConfig('serverCHAR', ''),
        serverDiscord = getRuntimeConfig('serverDiscord', ''),
        serverBackground = getRuntimeBanner()
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
