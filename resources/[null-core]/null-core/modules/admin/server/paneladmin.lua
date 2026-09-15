-- Panel Admin - dashboard and live server configuration.
-- All permissions are checked server-side; the NUI is never trusted.

local PANEL_ADMIN_EVENTS = {
    open = 'null:paneladmin:open',
    configUpdated = 'null:paneladmin:configUpdated',
}

local PERSISTENCE_FILE = 'cache/paneladmin-config.json'

local EDITABLE_CONVARS = {
    serverName = true,
    serverColor = true,
    jsColor = true,
    serverCHAR = true,
    discordAPI = true,
    boutiqueLink = true,
    serverDiscord = true,
    serverDiscord2 = true,
    r = true,
    g = true,
    b = true,
    hexcolor = true,
    backgroundBanner = true,
    bannerUrl = true,
}

local function convar(name, fallback)
    local value = GetConvar(name, fallback or '')
    return value ~= nil and value or (fallback or '')
end

local function getServerConfig()
    local banner = convar('backgroundBanner', '')
    if banner == '' then banner = convar('bannerUrl', '') end
    return {
        serverName = convar('serverName', 'Null\'s Base'),
        serverColor = convar('serverColor', '~g~'),
        jsColor = convar('jsColor', '^2'),
        serverCHAR = convar('serverCHAR', ''),
        discordAPI = convar('discordAPI', ''),
        boutiqueLink = convar('boutiqueLink', ''),
        serverDiscord = convar('serverDiscord', ''),
        serverDiscord2 = convar('serverDiscord2', ''),
        r = convar('r', '190'),
        g = convar('g', '238'),
        b = convar('b', '17'),
        hexcolor = convar('hexcolor', '#BEEE11'),
        backgroundBanner = banner,
        bannerUrl = convar('bannerUrl', banner),
    }
end

local function sanitizeConfigValue(key, value)
    if value == nil then return nil end
    value = tostring(value)
    if #value > 500 then return nil end
    if value:find('[\r\n]') or value:find(';') or value:find('"') then return nil end

    if key == 'hexcolor' and not value:match('^#%x%x%x%x%x%x$') then return nil end
    if key == 'r' or key == 'g' or key == 'b' then
        local channel = tonumber(value)
        if not channel or channel < 0 or channel > 255 or value:match('%D') then return nil end
    end

    return value
end

local function applyConvar(key, value)
    -- Quoting keeps URLs, names and banner paths intact while the validation
    -- above prevents command injection through ExecuteCommand.
    local escaped = value:gsub('\\', '\\\\'):gsub('"', '\\"')
    ExecuteCommand(('setr %s "%s"'):format(key, escaped))
end

local function persistConfig(config)
    local persisted = {}
    for key in pairs(EDITABLE_CONVARS) do
        if config[key] ~= nil then persisted[key] = config[key] end
    end
    SaveResourceFile(GetCurrentResourceName(), PERSISTENCE_FILE, json.encode(persisted), -1)
end

local function loadPersistedConfig()
    local raw = LoadResourceFile(GetCurrentResourceName(), PERSISTENCE_FILE)
    if not raw or raw == '' then return end

    local ok, persisted = pcall(json.decode, raw)
    if not ok or type(persisted) ~= 'table' then
        print('[Panel Admin] Configuration persistée invalide, valeurs du server.cfg conservées.')
        return
    end

    local loaded = 0
    for key in pairs(EDITABLE_CONVARS) do
        local value = sanitizeConfigValue(key, persisted[key])
        if value ~= nil then
            applyConvar(key, value)
            loaded = loaded + 1
        end
    end

    -- Supporte les anciennes installations qui n’avaient que bannerUrl.
    if persisted.backgroundBanner and not persisted.bannerUrl then
        applyConvar('bannerUrl', persisted.backgroundBanner)
    end

    if loaded > 0 then
        print(('[Panel Admin] %s variable(s) restaurée(s) depuis %s.'):format(loaded, PERSISTENCE_FILE))
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    -- Restaurer avant l'arrivée des clients pour que le loading screen et la
    -- lib reçoivent directement la bannière sauvegardée après un reboot.
    loadPersistedConfig()
end)

local function getOnlineStats()
    local connected = 0
    local police = 0
    local ems = 0

    for _, playerId in ipairs(ESX.GetPlayers()) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            connected = connected + 1
            local job = xPlayer.getJob and xPlayer.getJob() or xPlayer.job or {}
            local jobName = string.lower(tostring(job.name or ''))
            if jobName == 'police' or jobName == 'sheriff' or jobName == 'fib' or jobName == 'lspd' then
                police = police + 1
            elseif jobName == 'ambulance' or jobName == 'ems' then
                ems = ems + 1
            end
        end
    end

    return connected, police, ems
end

local function getAccountTotals(rows)
    local totals = { cash = 0, bank = 0, illegal = 0 }
    for _, row in ipairs(rows or {}) do
        local accounts = row.accounts
        if type(accounts) == 'string' and accounts ~= '' then
            local ok, decoded = pcall(json.decode, accounts)
            if ok and type(decoded) == 'table' then accounts = decoded end
        end
        if type(accounts) == 'table' then
            for _, account in pairs(accounts) do
                local name = string.lower(tostring(account.name or ''))
                local money = tonumber(account.money or account.amount or 0) or 0
                if name == 'cash' or name == 'money' then
                    totals.cash = totals.cash + money
                elseif name == 'bank' then
                    totals.bank = totals.bank + money
                elseif name == 'dirtycash' or name == 'black_money' or name == 'illegal' then
                    totals.illegal = totals.illegal + money
                end
            end
        end
    end
    return totals
end

local function fetchDashboard(source, callback)
    local connected, police, ems = getOnlineStats()
    local pendingReports = tonumber(reportsNoTraiter or 0) or 0
    local activeReports = tonumber(reportsCount or 0) or 0
    local memoryReportTotal = tonumber(reportsTotal or 0) or 0

    MySQL.Async.fetchAll('SELECT COUNT(DISTINCT identifier) AS total FROM users', {}, function(uniqueRows)
        MySQL.Async.fetchAll('SELECT COUNT(DISTINCT identifier) AS total FROM users WHERE lastConnection >= (NOW() - INTERVAL 24 HOUR)', {}, function(last24Rows)
            MySQL.Async.fetchAll("SELECT COUNT(*) AS total FROM vlogs WHERE type = 'create-report'", {}, function(reportRows)
                MySQL.Async.fetchAll('SELECT accounts FROM users', {}, function(accountRows)
                    local money = getAccountTotals(accountRows)
                    local uniquePlayers = tonumber(uniqueRows and uniqueRows[1] and uniqueRows[1].total or 0) or 0
                    local last24 = tonumber(last24Rows and last24Rows[1] and last24Rows[1].total or 0) or 0
                    local persistedReports = tonumber(reportRows and reportRows[1] and reportRows[1].total or 0) or 0

                    callback({
                        ok = true,
                        metrics = {
                            uniquePlayers = uniquePlayers,
                            connectedPlayers = connected,
                            policeOnline = police,
                            emsOnline = ems,
                            pendingReports = pendingReports,
                            activeReports = activeReports,
                            totalReports = math.max(memoryReportTotal, persistedReports),
                            playersLast24h = last24,
                            money = money,
                            updatedAt = os.time(),
                        },
                        config = getServerConfig(),
                        -- Le Panel Admin est volontairement ouvert sans permission.
                        permissions = { canEditConfig = true },
                    })
                end)
            end)
        end)
    end)
end

ESX.RegisterServerCallback('null:paneladmin:getData', function(source, callback)
    fetchDashboard(source, callback)
end)

RegisterNetEvent('null:paneladmin:requestOpen')
AddEventHandler('null:paneladmin:requestOpen', function()
    local source = source
    TriggerClientEvent(PANEL_ADMIN_EVENTS.open, source)
end)

RegisterNetEvent('null:paneladmin:updateConfig')
AddEventHandler('null:paneladmin:updateConfig', function(payload)
    local source = source
    if type(payload) ~= 'table' then return end

    local changed = {}
    for key in pairs(EDITABLE_CONVARS) do
        local value = sanitizeConfigValue(key, payload[key])
        if value ~= nil then
            applyConvar(key, value)
            changed[key] = value
            if key == 'backgroundBanner' then
                -- Older server.cfg files call this variable bannerUrl; keep
                -- both names synchronized so the existing core can consume it.
                applyConvar('bannerUrl', value)
            elseif key == 'bannerUrl' then
                applyConvar('backgroundBanner', value)
            end
        end
    end

    if next(changed) == nil then return end

    local config = getServerConfig()
    persistConfig(config)
    TriggerClientEvent(PANEL_ADMIN_EVENTS.configUpdated, -1, config)
    TriggerClientEvent('esx:showNotification', source, 'Configuration serveur appliquée en direct.')
end)
