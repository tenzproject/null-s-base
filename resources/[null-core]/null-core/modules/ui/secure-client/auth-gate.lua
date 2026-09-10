local function pushAuth(data)
    if type(data) ~= 'table' then return end
    SendNUIMessage({
        action = 'null:ui:auth',
        license = data.license,
        uiToken = data.uiToken,
        -- devmode = not LPH_OBFUSCATED (true en dev, false en prod Luraph).
        -- Sert à désactiver l'anti-devtools côté NUI hors production.
        devMode = devmode == true
    })
end

AddStateBagChangeHandler('NullUiAuth', 'global', function(_, _, value)
    pushAuth(value)
end)

RegisterNUICallback('null:ui:requestAuth', function(_, cb)
    local auth = GlobalState.NullUiAuth
    if auth then
        pushAuth(auth)
    end
    cb({})
end)

Citizen.CreateThread(function()
    while GlobalState.NullUiAuth == nil do
        Citizen.Wait(500)
    end
    local auth = GlobalState.NullUiAuth
    for _ = 1, 6 do
        Citizen.Wait(2000)
        pushAuth(auth)
    end
end)
