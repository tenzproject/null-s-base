-- Panel Admin client bridge.

local panelAdminOpen = false

local function sendConfigToUi(config)
    if type(config) ~= 'table' then return end

    local banner = config.backgroundBanner or config.bannerUrl or ''

    SendNUIMessage({
        action = 'setConfig',
        data = {
            serverName = config.serverName,
            serverColor = config.hexcolor,
            serverLuaColor = config.serverColor,
            serverIcon = config.serverCHAR,
            serverDiscord = config.serverDiscord,
            serverBackground = banner,
        }
    })
    SendNUIMessage({ action = 'panelAdmin:configUpdated', data = config })

    -- Met aussi à jour le loading screen s'il est encore visible. Au prochain
    -- démarrage, INIT_CORE relira la même valeur depuis les convars persistées.
    SendLoadingScreenMessage(json.encode({
        type = 'SERVER_CONFIG_UPDATED',
        serverName = config.serverName,
        serverCHAR = config.serverCHAR,
        hexcolor = config.hexcolor,
        serverBackground = banner,
        backgroundBanner = banner,
        bannerUrl = banner,
    }))
end

RegisterCommand('paneladmin', function()
    TriggerServerEvent('null:paneladmin:requestOpen')
end, false)

RegisterCommand('adminpanel', function()
    TriggerServerEvent('null:paneladmin:requestOpen')
end, false)

RegisterNetEvent('null:paneladmin:open')
AddEventHandler('null:paneladmin:open', function()
    panelAdminOpen = true
    SetCursorLocation(0.5, 0.5)
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'panelAdmin:open' })
end)

RegisterNetEvent('null:paneladmin:configUpdated')
AddEventHandler('null:paneladmin:configUpdated', function(config)
    sendConfigToUi(config)
end)

RegisterNUICallback('paneladmin:close', function(_, cb)
    panelAdminOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'panelAdmin:close' })
    cb({ ok = true })
end)

RegisterNUICallback('paneladmin:getData', function(_, cb)
    ESX.TriggerServerCallback('null:paneladmin:getData', function(data)
        cb(data or { ok = false, error = 'Aucune réponse du serveur.' })
    end)
end)

RegisterNUICallback('paneladmin:updateConfig', function(data, cb)
    TriggerServerEvent('null:paneladmin:updateConfig', data or {})
    cb({ ok = true })
end)

-- FiveM can hide the cursor when another UI released focus just before the
-- panel opened. Keep the cursor active for the complete panel lifetime.
CreateThread(function()
    while true do
        if panelAdminOpen then
            -- Ne pas réappliquer le focus à chaque frame : cela fait perdre
            -- le focus natif aux champs texte après un clic.
            if not IsNuiFocused() then
                SetNuiFocus(true, true)
                SetNuiFocusKeepInput(false)
            end
            SetMouseCursorActiveThisFrame()
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 202, true)
            DisableControlAction(0, 322, true)
            if IsControlJustPressed(0, 322) or IsDisabledControlJustPressed(0, 322) then
                panelAdminOpen = false
                SetNuiFocus(false, false)
                SetNuiFocusKeepInput(false)
                SendNUIMessage({ action = 'panelAdmin:close' })
            end
            Wait(0)
        else
            Wait(250)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        panelAdminOpen = false
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end
end)
