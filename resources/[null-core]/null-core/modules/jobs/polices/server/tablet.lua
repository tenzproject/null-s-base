-- ============================================================================
-- POLICE TABLET - Server
-- ============================================================================
local DispatchState = {}   -- DispatchState[jobName] = { cards = {[identifier]={...}}, groups = {[gid]={...}} }
local PenalCodeCache = {}  -- PenalCodeCache[jobName] = { ["Cat"] = { {id,label,price,jail} } }
local RadioCodesCache = {} -- RadioCodesCache[jobName] = { {id,code,label,priority} }

local DEFAULT_RADIO_CODES = {
    { code = "10-1",  label = "Mauvaise réception radio",                                          priority = 0 },
    { code = "10-2",  label = "Signal clair, bonne réception",                                     priority = 0 },
    { code = "10-3",  label = "Fin de transmission / silence radio",                               priority = 0 },
    { code = "10-4",  label = "Bien reçu / OK",                                                    priority = 1 },
    { code = "10-5",  label = "Négatif",                                                           priority = 1 },
    { code = "10-6",  label = "Occupé / attendre avant de poursuivre sauf urgence",                priority = 0 },
    { code = "10-7",  label = "Hors service temporaire / indisponible pour appel",                priority = 0 },
    { code = "10-8",  label = "En service / disponible pour appel",                               priority = 0 },
    { code = "10-9",  label = "Répéter le dernier message",                                       priority = 0 },
    { code = "10-10", label = "Fin de service",                                                    priority = 0 },
    { code = "10-12", label = "Présence de visiteurs, peuvent entendre la radio",                  priority = 0 },
    { code = "10-13", label = "Météo ou conditions routières",                                    priority = 0 },
    { code = "10-14", label = "Escorte ou convoi",                                                 priority = 0 },
    { code = "10-15", label = "Suspect détenu / transport du prisonnier",                         priority = 1 },
    { code = "10-17", label = "Ajout de carburant",                                                priority = 0 },
    { code = "10-19", label = "En route vers… (préciser la localisation)",                        priority = 1 },
    { code = "10-20", label = "Votre localisation",                                                priority = 0 },
    { code = "10-22", label = "Annuler ou ignorer la transmission radio / appel",                 priority = 0 },
    { code = "10-23", label = "Standby / attente",                                                 priority = 0 },
    { code = "10-28", label = "Vérification immatriculation",                                     priority = 0 },
    { code = "10-29", label = "Vérification mandats / dossier criminel",                          priority = 0 },
    { code = "10-31", label = "Tirs d'armes à feu",                                                priority = 1 },
    { code = "10-35", label = "Demande de renfort sur position de l'officier",                    priority = 1 },
    { code = "10-37", label = "Cambriolage en cours",                                              priority = 1 },
    { code = "10-38", label = "Contrôle routier / Traffic Stop",                                  priority = 0 },
    { code = "10-40", label = "Braquage de supérette",                                             priority = 1 },
    { code = "10-41", label = "Prise de patrouille",                                               priority = 0 },
    { code = "10-50", label = "Accident (préciser si blessure corporelle)",                       priority = 0 },
    { code = "10-51", label = "Demande dépanneuse / Tow Truck",                                   priority = 0 },
    { code = "10-52", label = "Demande ambulance / Paramedics",                                   priority = 0 },
    { code = "10-56", label = "Refus d'obtempérer",                                                priority = 1 },
    { code = "10-57", label = "Délit de fuite",                                                    priority = 0 },
    { code = "10-58", label = "Braquage d'ATM",                                                    priority = 1 },
    { code = "10-59", label = "Vol de véhicule",                                                   priority = 0 },
    { code = "10-60", label = "Vente de drogue",                                                   priority = 0 },
    { code = "10-91", label = "Braquage de banque",                                                priority = 1 },
    { code = "10-97", label = "Arrivé sur scène",                                                  priority = 0 },
    { code = "10-99", label = "Officier en danger",                                                priority = 1 },
}

local function getJobName(src)
    local x = ESX.GetPlayerFromId(src)
    if not x then return nil end
    return x.getJob().name
end

local function isPoliceJob(jobName)
    if not jobName then return false end
    if SaveData and SaveData.json and SaveData.json["entreprises"] and SaveData.json["entreprises"]["Police"] then
        return SaveData.json["entreprises"]["Police"][jobName] ~= nil
    end
    return false
end

local function isBoss(src)
    local x = ESX.GetPlayerFromId(src)
    if not x then return false end
    local g = x.getJob().grade_name
    return g == "boss" or g == "patron"
end

-- ============================================================================
-- SQL MIGRATIONS
-- ============================================================================
CreateThread(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS police_penal_code (
            id INT AUTO_INCREMENT PRIMARY KEY,
            job_name VARCHAR(60) NOT NULL,
            category VARCHAR(120) NOT NULL,
            label VARCHAR(255) NOT NULL,
            price INT DEFAULT 0,
            jail_time INT DEFAULT 0,
            INDEX idx_job (job_name)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS police_radio_codes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            job_name VARCHAR(60) NOT NULL,
            code VARCHAR(20) NOT NULL,
            label VARCHAR(255) NOT NULL,
            priority TINYINT DEFAULT 0,
            INDEX idx_job (job_name)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS police_casier (
            id INT AUTO_INCREMENT PRIMARY KEY,
            job_name VARCHAR(60) NOT NULL,
            target_identifier VARCHAR(100) NOT NULL,
            target_name VARCHAR(255),
            target_idunique VARCHAR(60),
            agent_identifier VARCHAR(100),
            agent_name VARCHAR(255),
            agent_matricule VARCHAR(50),
            offenses LONGTEXT,
            notes TEXT,
            total_amount INT DEFAULT 0,
            total_jail INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_target (target_identifier),
            INDEX idx_job (job_name)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {})

    Wait(2000)
    -- Seed default penal code for each police job that has none yet
    if Config.PoliceTablet and Config.PoliceTablet.DefaultPenalCode and SaveData and SaveData.json and SaveData.json["entreprises"] and SaveData.json["entreprises"]["Police"] then
        for jobName, _ in pairs(SaveData.json["entreprises"]["Police"]) do
            MySQL.Async.fetchScalar('SELECT COUNT(*) FROM police_penal_code WHERE job_name = @j', { ['@j'] = jobName }, function(count)
                if tonumber(count or 0) == 0 then
                    for cat, list in pairs(Config.PoliceTablet.DefaultPenalCode) do
                        for _, off in ipairs(list) do
                            MySQL.Async.execute('INSERT INTO police_penal_code (job_name, category, label, price, jail_time) VALUES (@j,@c,@l,@p,@t)', {
                                ['@j'] = jobName, ['@c'] = cat, ['@l'] = off.label, ['@p'] = off.price, ['@t'] = off.jail
                            })
                        end
                    end
                end
            end)
            MySQL.Async.fetchScalar('SELECT COUNT(*) FROM police_radio_codes WHERE job_name = @j', { ['@j'] = jobName }, function(count)
                if tonumber(count or 0) == 0 then
                    for _, rc in ipairs(DEFAULT_RADIO_CODES) do
                        MySQL.Async.execute('INSERT INTO police_radio_codes (job_name, code, label, priority) VALUES (@j,@c,@l,@p)', {
                            ['@j'] = jobName, ['@c'] = rc.code, ['@l'] = rc.label, ['@p'] = rc.priority,
                        })
                    end
                end
            end)
        end
    end
end)

-- ============================================================================
-- PENAL CODE HELPERS
-- ============================================================================
local function loadPenalCode(jobName, cb)
    MySQL.Async.fetchAll('SELECT id, category, label, price, jail_time FROM police_penal_code WHERE job_name = @j ORDER BY category, id', {
        ['@j'] = jobName
    }, function(rows)
        local grouped = {}
        for _, r in ipairs(rows or {}) do
            grouped[r.category] = grouped[r.category] or {}
            table.insert(grouped[r.category], { id = r.id, label = r.label, price = r.price, jail = r.jail_time })
        end
        PenalCodeCache[jobName] = grouped
        if cb then cb(grouped) end
    end)
end

local function loadRadioCodes(jobName, cb)
    MySQL.Async.fetchAll('SELECT id, code, label, priority FROM police_radio_codes WHERE job_name = @j ORDER BY code, id', {
        ['@j'] = jobName
    }, function(rows)
        local list = {}
        for _, r in ipairs(rows or {}) do
            table.insert(list, { id = r.id, code = r.code, label = r.label, priority = tonumber(r.priority) or 0 })
        end
        RadioCodesCache[jobName] = list
        if cb then cb(list) end
    end)
end

local function broadcastRadio(jobName)
    local list = RadioCodesCache[jobName] or {}
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        local xp = ESX.GetPlayerFromId(pid)
        if xp and xp.getJob().name == jobName then
            TriggerClientEvent("null:policeTablet:radioUpdate", pid, list)
        end
    end
end

-- ============================================================================
-- DISPATCH HELPERS
-- ============================================================================
local function ensureDispatch(jobName)
    if not DispatchState[jobName] then
        DispatchState[jobName] = { cards = {}, groups = {} }
    end
    return DispatchState[jobName]
end

local function broadcastDispatch(jobName)
    local state = ensureDispatch(jobName)
    for _, playerId in ipairs(GetPlayers()) do
        local pid = tonumber(playerId)
        local xp = ESX.GetPlayerFromId(pid)
        if xp and xp.getJob().name == jobName then
            TriggerClientEvent("null:policeTablet:dispatchUpdate", pid, state)
        end
    end
end

-- ============================================================================
-- MAIN CALLBACK : open tablet
-- ============================================================================
ESX.RegisterServerCallback("null:policeTablet:getData", function(source, cb)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return cb(nil) end
    local jobName = xPlayer.getJob().name
    if not isPoliceJob(jobName) then return cb(nil) end

    local brand = nil
    if SocietyList and SocietyList[jobName] then
        brand = {
            id = jobName,
            name = SocietyList[jobName].label or "Police",
            logo = SocietyList[jobName].logo ~= "" and SocietyList[jobName].logo or nil,
            accentColor = SocietyList[jobName].brandColor or "#1e40af",
            bgColor = "#0a0f1e",
        }
    else
        brand = { id = jobName, name = "Central Police", logo = nil, accentColor = "#1e40af", bgColor = "#0a0f1e" }
    end

    loadPenalCode(jobName, function(penal)
        loadRadioCodes(jobName, function(radio)
            cb({
                jobName = jobName,
                brand = brand,
                isBoss = isBoss(src),
                grade = xPlayer.getJob().grade_name,
                gradeLabel = xPlayer.getJob().grade_label,
                agent = {
                    identifier = xPlayer.identifier,
                    idunique = xPlayer.getIdunique(),
                    firstname = xPlayer.firstname or "",
                    lastname = xPlayer.lastname or "",
                    name = xPlayer.getName(),
                },
                penalCode = penal or {},
                radioCodes = radio or {},
                dispatch = ensureDispatch(jobName),
            })
        end)
    end)
end)

-- ============================================================================
-- DISPATCH : create / move / delete card and group
-- ============================================================================
RegisterNetEvent("null:policeTablet:createCard", function(payload)
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp then return end
    local jobName = xp.getJob().name
    if not isPoliceJob(jobName) then return end

    local state = ensureDispatch(jobName)
    local id = xp.identifier
    state.cards[id] = {
        identifier = id,
        idunique = xp.getIdunique(),
        firstname = xp.firstname or "",
        lastname = xp.lastname or "",
        matricule = tostring(payload and payload.matricule or ""),
        color = payload and payload.color or "#3b82f6",
        x = payload and payload.x or 100,
        y = payload and payload.y or 100,
        groupId = nil,
    }
    broadcastDispatch(jobName)
end)

RegisterNetEvent("null:policeTablet:moveCard", function(payload)
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp then return end
    local jobName = xp.getJob().name
    local state = ensureDispatch(jobName)
    if not payload or not payload.identifier then return end
    local card = state.cards[payload.identifier]
    if not card then return end
    -- only own card or boss can move
    if card.identifier ~= xp.identifier and not isBoss(src) then return end
    card.x = payload.x or card.x
    card.y = payload.y or card.y
    if payload.groupId ~= nil then
        card.groupId = payload.groupId ~= "" and payload.groupId or nil
    end
    broadcastDispatch(jobName)
end)

RegisterNetEvent("null:policeTablet:deleteCard", function(payload)
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp then return end
    local jobName = xp.getJob().name
    local state = ensureDispatch(jobName)
    if not payload or not payload.identifier then return end
    local card = state.cards[payload.identifier]
    if not card then return end
    if card.identifier ~= xp.identifier and not isBoss(src) then return end
    state.cards[payload.identifier] = nil
    broadcastDispatch(jobName)
end)

RegisterNetEvent("null:policeTablet:createGroup", function(payload)
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp then return end
    local jobName = xp.getJob().name
    if not isPoliceJob(jobName) then return end
    local state = ensureDispatch(jobName)
    local gid = "g_" .. tostring(math.random(100000, 999999))
    state.groups[gid] = {
        id = gid,
        name = (payload and payload.name) or "Patrouille",
        color = (payload and payload.color) or "#1e3a8a",
        x = (payload and payload.x) or 200,
        y = (payload and payload.y) or 200,
        createdBy = xp.identifier,
    }
    broadcastDispatch(jobName)
end)

RegisterNetEvent("null:policeTablet:moveGroup", function(payload)
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp then return end
    local jobName = xp.getJob().name
    local state = ensureDispatch(jobName)
    if not payload or not payload.id then return end
    local g = state.groups[payload.id]
    if not g then return end
    g.x = payload.x or g.x
    g.y = payload.y or g.y
    broadcastDispatch(jobName)
end)

RegisterNetEvent("null:policeTablet:deleteGroup", function(payload)
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp then return end
    local jobName = xp.getJob().name
    local state = ensureDispatch(jobName)
    if not payload or not payload.id then return end
    local g = state.groups[payload.id]
    if not g then return end
    if g.createdBy ~= xp.identifier and not isBoss(src) then return end
    state.groups[payload.id] = nil
    -- detach cards
    for _, c in pairs(state.cards) do
        if c.groupId == payload.id then c.groupId = nil end
    end
    broadcastDispatch(jobName)
end)

-- ============================================================================
-- SEARCH PLAYERS / VEHICLES / PROPERTIES
-- ============================================================================
local function buildPlayerSummary(row)
    local accounts = {}
    if row.accounts then
        local ok, acc = pcall(json.decode, row.accounts)
        if ok and type(acc) == "table" then accounts = acc end
    end
    local job = "unemployed2"
    if row.job and row.job ~= "" then job = row.job end
    return {
        identifier = row.identifier,
        idunique = row.idunique,
        firstname = row.firstname or "",
        lastname = row.lastname or "",
        bank = (accounts.bank and accounts.bank.money) or 0,
        job = job,
        jobGrade = row.job_grade or 0,
        sex = row.sex or "m",
        dateofbirth = row.dateofbirth or "",
        phone = "",
    }
end

ESX.RegisterServerCallback("null:policeTablet:searchPlayers", function(source, cb, query)
    local src = source
    if not isPoliceJob(getJobName(src)) then return cb({}) end
    local function send(rows)
        local out = {}
        for _, r in ipairs(rows or {}) do
            table.insert(out, buildPlayerSummary(r))
        end
        cb(out)
    end
    if not query or #query < 1 then
        return MySQL.Async.fetchAll([[
            SELECT identifier, idunique, firstname, lastname, accounts, job, job_grade, sex, dateofbirth
            FROM users WHERE firstname <> '' ORDER BY lastUpdate DESC LIMIT 8
        ]], {}, send)
    end
    local q = "%" .. tostring(query) .. "%"
    MySQL.Async.fetchAll([[
        SELECT identifier, idunique, firstname, lastname, accounts, job, job_grade, sex, dateofbirth
        FROM users
        WHERE firstname LIKE @q OR lastname LIKE @q OR CONCAT(firstname,' ',lastname) LIKE @q OR idunique LIKE @q
        LIMIT 20
    ]], { ['@q'] = q }, send)
end)

-- Recent casier entries (preview for the Casier page)
ESX.RegisterServerCallback("null:policeTablet:recentCasier", function(source, cb)
    local src = source
    if not isPoliceJob(getJobName(src)) then return cb({}) end
    MySQL.Async.fetchAll([[
        SELECT id, target_identifier, target_name, agent_name, agent_matricule, offenses, total_amount, total_jail, created_at, notes
        FROM police_casier WHERE job_name = @j ORDER BY created_at DESC LIMIT 8
    ]], { ['@j'] = getJobName(src) }, function(rows)
        local out = {}
        for _, r in ipairs(rows or {}) do
            local off = {}
            if r.offenses then local ok, dec = pcall(json.decode, r.offenses) if ok then off = dec end end
            table.insert(out, {
                id = r.id, targetIdentifier = r.target_identifier, targetName = r.target_name,
                agentName = r.agent_name, agentMatricule = r.agent_matricule,
                offenses = off, totalAmount = r.total_amount, totalJail = r.total_jail,
                notes = r.notes or "", createdAt = tostring(r.created_at),
            })
        end
        cb(out)
    end)
end)

ESX.RegisterServerCallback("null:policeTablet:getPlayerDetails", function(source, cb, identifier)
    local src = source
    if not isPoliceJob(getJobName(src)) then return cb(nil) end
    if not identifier then return cb(nil) end

    MySQL.Async.fetchAll([[
        SELECT identifier, idunique, firstname, lastname, accounts, job, job_grade, sex, dateofbirth
        FROM users WHERE identifier = @id LIMIT 1
    ]], { ['@id'] = identifier }, function(rows)
        if not rows or #rows == 0 then return cb(nil) end
        local summary = buildPlayerSummary(rows[1])

        -- vehicles
        local vehicles = {}
        if SaveData and SaveData.json and SaveData.json["owned_vehicles"] then
            for plate, v in pairs(SaveData.json["owned_vehicles"]) do
                if v.owner == identifier then
                    table.insert(vehicles, {
                        plate = v.plate or plate,
                        label = v.label or v.vehicle,
                        vehicle = v.vehicle,
                        type = v.type or "car",
                        state = v.state or "out",
                        garage = v.garage,
                    })
                end
            end
        end

        -- properties
        local properties = {}
        if SaveData and SaveData.PropertiesList then
            for name, p in pairs(SaveData.PropertiesList) do
                if p.owner == identifier then
                    table.insert(properties, {
                        name = p.name,
                        label = p.label or p.name,
                        price = p.price or 0,
                        coords = p.positions and p.positions["EXIT"] or nil,
                        immeuble = p.immeuble,
                    })
                end
            end
        end

        -- casier (last 5)
        MySQL.Async.fetchAll([[
            SELECT id, agent_name, agent_matricule, offenses, total_amount, total_jail, created_at, notes
            FROM police_casier WHERE target_identifier = @id ORDER BY created_at DESC LIMIT 5
        ]], { ['@id'] = identifier }, function(casierRows)
            local casier = {}
            for _, r in ipairs(casierRows or {}) do
                local off = {}
                if r.offenses then local ok, dec = pcall(json.decode, r.offenses) if ok then off = dec end end
                table.insert(casier, {
                    id = r.id, agentName = r.agent_name, agentMatricule = r.agent_matricule,
                    offenses = off, totalAmount = r.total_amount, totalJail = r.total_jail,
                    notes = r.notes or "", createdAt = tostring(r.created_at),
                })
            end
            cb({
                summary = summary,
                vehicles = vehicles,
                vehiclesCount = #vehicles,
                properties = properties,
                propertiesCount = #properties,
                casier = casier,
            })
        end)
    end)
end)

ESX.RegisterServerCallback("null:policeTablet:getCasier", function(source, cb, identifier)
    local src = source
    if not isPoliceJob(getJobName(src)) then return cb({}) end
    if not identifier then return cb({}) end
    MySQL.Async.fetchAll([[
        SELECT id, agent_name, agent_matricule, offenses, total_amount, total_jail, created_at, notes, target_name
        FROM police_casier WHERE target_identifier = @id ORDER BY created_at DESC
    ]], { ['@id'] = identifier }, function(rows)
        local out = {}
        for _, r in ipairs(rows or {}) do
            local off = {}
            if r.offenses then local ok, dec = pcall(json.decode, r.offenses) if ok then off = dec end end
            table.insert(out, {
                id = r.id, agentName = r.agent_name, agentMatricule = r.agent_matricule,
                offenses = off, totalAmount = r.total_amount, totalJail = r.total_jail,
                notes = r.notes or "", createdAt = tostring(r.created_at), targetName = r.target_name,
            })
        end
        cb(out)
    end)
end)

ESX.RegisterServerCallback("null:policeTablet:searchVehicles", function(source, cb, query)
    local src = source
    if not isPoliceJob(getJobName(src)) then return cb({}) end

    -- Preview: return a sample of owned vehicles with their owner names
    if not query or #query < 1 then
        local preview, owners = {}, {}
        if SaveData and SaveData.json and SaveData.json["owned_vehicles"] then
            for plate, v in pairs(SaveData.json["owned_vehicles"]) do
                if #preview >= 8 then break end
                table.insert(preview, {
                    plate = v.plate or plate, label = v.label or v.vehicle, vehicle = v.vehicle,
                    type = v.type or "car", state = v.state or "out", owner = v.owner, garage = v.garage,
                })
                if v.owner then owners[v.owner] = true end
            end
        end
        if #preview == 0 then return cb({}) end
        local ids = {}
        for id in pairs(owners) do ids[#ids + 1] = id end
        if #ids == 0 then return cb(preview) end
        MySQL.Async.fetchAll(('SELECT identifier, firstname, lastname FROM users WHERE identifier IN (%s)'):format(
            ("?,"):rep(#ids):sub(1, -2)), ids, function(rows)
            local byId = {}
            for _, r in ipairs(rows or {}) do byId[r.identifier] = (r.firstname or "") .. " " .. (r.lastname or "") end
            for _, r in ipairs(preview) do if r.owner and byId[r.owner] then r.ownerName = byId[r.owner] end end
            cb(preview)
        end)
        return
    end

    local q = string.lower(tostring(query))
    local results = {}
    -- owner identifier lookup cache by firstname/lastname
    local matchingIds = {}
    -- First match plates directly
    if SaveData and SaveData.json and SaveData.json["owned_vehicles"] then
        for plate, v in pairs(SaveData.json["owned_vehicles"]) do
            local plateLower = string.lower(v.plate or plate or "")
            if string.find(plateLower, q, 1, true) then
                table.insert(results, {
                    plate = v.plate or plate, label = v.label or v.vehicle, vehicle = v.vehicle,
                    type = v.type or "car", state = v.state or "out", owner = v.owner, garage = v.garage,
                })
            end
        end
    end
    -- Then look up by owner name
    MySQL.Async.fetchAll([[
        SELECT identifier, firstname, lastname FROM users
        WHERE firstname LIKE @q OR lastname LIKE @q OR CONCAT(firstname,' ',lastname) LIKE @q LIMIT 30
    ]], { ['@q'] = "%" .. tostring(query) .. "%" }, function(rows)
        local byId = {}
        for _, r in ipairs(rows or {}) do byId[r.identifier] = (r.firstname or "") .. " " .. (r.lastname or "") end
        if SaveData and SaveData.json and SaveData.json["owned_vehicles"] then
            for plate, v in pairs(SaveData.json["owned_vehicles"]) do
                if v.owner and byId[v.owner] then
                    -- avoid duplicate plate match
                    local exists = false
                    for _, r2 in ipairs(results) do if r2.plate == (v.plate or plate) then exists = true break end end
                    if not exists then
                        table.insert(results, {
                            plate = v.plate or plate, label = v.label or v.vehicle, vehicle = v.vehicle,
                            type = v.type or "car", state = v.state or "out", owner = v.owner,
                            ownerName = byId[v.owner], garage = v.garage,
                        })
                    end
                end
            end
        end
        -- enrich ownerName for plate-matched results
        for _, r in ipairs(results) do
            if r.owner and not r.ownerName and byId[r.owner] then r.ownerName = byId[r.owner] end
        end
        cb(results)
    end)
end)

ESX.RegisterServerCallback("null:policeTablet:searchProperties", function(source, cb, query)
    local src = source
    if not isPoliceJob(getJobName(src)) then return cb({}) end

    -- Preview: return a sample of properties (prioritise owned ones)
    if not query or #query < 1 then
        local preview, owners = {}, {}
        if SaveData and SaveData.PropertiesList then
            for name, p in pairs(SaveData.PropertiesList) do
                if p.owner then
                    if #preview >= 8 then break end
                    table.insert(preview, {
                        name = p.name, label = p.label or p.name, price = p.price or 0,
                        owner = p.owner, coords = p.positions and p.positions["EXIT"] or nil, immeuble = p.immeuble,
                    })
                    owners[p.owner] = true
                end
            end
            if #preview < 8 then
                for name, p in pairs(SaveData.PropertiesList) do
                    if not p.owner then
                        if #preview >= 8 then break end
                        table.insert(preview, {
                            name = p.name, label = p.label or p.name, price = p.price or 0,
                            owner = p.owner, coords = p.positions and p.positions["EXIT"] or nil, immeuble = p.immeuble,
                        })
                    end
                end
            end
        end
        if #preview == 0 then return cb({}) end
        local ids = {}
        for id in pairs(owners) do ids[#ids + 1] = id end
        if #ids == 0 then return cb(preview) end
        MySQL.Async.fetchAll(('SELECT identifier, firstname, lastname FROM users WHERE identifier IN (%s)'):format(
            ("?,"):rep(#ids):sub(1, -2)), ids, function(rows)
            local byId = {}
            for _, r in ipairs(rows or {}) do byId[r.identifier] = (r.firstname or "") .. " " .. (r.lastname or "") end
            for _, r in ipairs(preview) do if r.owner and byId[r.owner] then r.ownerName = byId[r.owner] end end
            cb(preview)
        end)
        return
    end

    local q = string.lower(tostring(query))

    local results = {}
    if SaveData and SaveData.PropertiesList then
        -- match property name/label
        for name, p in pairs(SaveData.PropertiesList) do
            local lab = string.lower(p.label or p.name or "")
            local n = string.lower(p.name or "")
            if string.find(lab, q, 1, true) or string.find(n, q, 1, true) then
                table.insert(results, {
                    name = p.name, label = p.label or p.name, price = p.price or 0,
                    owner = p.owner, coords = p.positions and p.positions["EXIT"] or nil,
                    immeuble = p.immeuble,
                })
            end
        end
    end

    -- also try by owner name
    MySQL.Async.fetchAll([[
        SELECT identifier, firstname, lastname FROM users
        WHERE firstname LIKE @q OR lastname LIKE @q OR CONCAT(firstname,' ',lastname) LIKE @q LIMIT 30
    ]], { ['@q'] = "%" .. tostring(query) .. "%" }, function(rows)
        local byId = {}
        for _, r in ipairs(rows or {}) do byId[r.identifier] = (r.firstname or "") .. " " .. (r.lastname or "") end
        if SaveData and SaveData.PropertiesList then
            for name, p in pairs(SaveData.PropertiesList) do
                if p.owner and byId[p.owner] then
                    local exists = false
                    for _, r2 in ipairs(results) do if r2.name == p.name then exists = true break end end
                    if not exists then
                        table.insert(results, {
                            name = p.name, label = p.label or p.name, price = p.price or 0,
                            owner = p.owner, ownerName = byId[p.owner],
                            coords = p.positions and p.positions["EXIT"] or nil, immeuble = p.immeuble,
                        })
                    end
                end
            end
        end
        for _, r in ipairs(results) do
            if r.owner and not r.ownerName and byId[r.owner] then r.ownerName = byId[r.owner] end
        end
        cb(results)
    end)
end)

-- ============================================================================
-- CASIER : add entry
-- ============================================================================
RegisterNetEvent("null:policeTablet:addCasier", function(payload)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end
    local jobName = xPlayer.getJob().name
    if not isPoliceJob(jobName) then return end
    if not payload or not payload.identifier or not payload.offenses or #payload.offenses == 0 then return end

    local total, jail = 0, 0
    local cleanOffenses = {}
    for _, off in ipairs(payload.offenses) do
        local p = tonumber(off.price) or 0
        local j = tonumber(off.jail) or 0
        total = total + p
        jail = jail + j
        table.insert(cleanOffenses, { label = tostring(off.label or ""), price = p, jail = j, category = tostring(off.category or "") })
    end

    MySQL.Async.execute([[
        INSERT INTO police_casier (job_name, target_identifier, target_name, target_idunique,
            agent_identifier, agent_name, agent_matricule, offenses, notes, total_amount, total_jail)
        VALUES (@job, @tid, @tname, @tidu, @aid, @aname, @amat, @off, @notes, @ta, @tj)
    ]], {
        ['@job']    = jobName,
        ['@tid']    = payload.identifier,
        ['@tname']  = payload.targetName or "",
        ['@tidu']   = payload.targetIdunique or "",
        ['@aid']    = xPlayer.identifier,
        ['@aname']  = xPlayer.getName(),
        ['@amat']   = tostring(payload.agentMatricule or ""),
        ['@off']    = json.encode(cleanOffenses),
        ['@notes']  = tostring(payload.notes or ""),
        ['@ta']     = total,
        ['@tj']     = jail,
    }, function()
        -- send bill if total > 0
        if total > 0 then
            local target = ESX.GetPlayerFromIdentifier(payload.identifier)
            if target then
                target.removeAccountMoney("bank", math.min(total, target.getAccount("bank").money))
            else
                MySQL.Async.execute('UPDATE users SET accounts = JSON_SET(accounts, "$.bank.money", GREATEST(0, JSON_EXTRACT(accounts, "$.bank.money") - @amt)) WHERE identifier = @id', {
                    ['@amt'] = total, ['@id'] = payload.identifier
                })
            end
        end
        xPlayer.showNotification("Casier ajouté ($"..total..", "..jail.."s)", "success")
        TriggerClientEvent("null:policeTablet:casierAdded", src, payload.identifier)
    end)
end)

RegisterNetEvent("null:policeTablet:deleteCasier", function(casierId)
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp then return end
    if not isPoliceJob(xp.getJob().name) then return end
    if not isBoss(src) then xp.showNotification("Seul le patron peut supprimer un casier", "error") return end
    MySQL.Async.execute('DELETE FROM police_casier WHERE id = @id AND job_name = @j', {
        ['@id'] = tonumber(casierId), ['@j'] = xp.getJob().name
    })
end)

-- ============================================================================
-- PENAL CODE CRUD (boss only)
-- ============================================================================
RegisterNetEvent("null:policeTablet:addPenal", function(payload)
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp or not isBoss(src) then return end
    local jobName = xp.getJob().name
    if not isPoliceJob(jobName) then return end
    if not payload or not payload.category or not payload.label then return end
    MySQL.Async.execute('INSERT INTO police_penal_code (job_name, category, label, price, jail_time) VALUES (@j,@c,@l,@p,@t)', {
        ['@j'] = jobName, ['@c'] = payload.category, ['@l'] = payload.label,
        ['@p'] = tonumber(payload.price) or 0, ['@t'] = tonumber(payload.jail) or 0,
    }, function()
        loadPenalCode(jobName, function(penal)
            for _, pid in ipairs(GetPlayers()) do
                local p = ESX.GetPlayerFromId(tonumber(pid))
                if p and p.getJob().name == jobName then
                    TriggerClientEvent("null:policeTablet:penalUpdate", tonumber(pid), penal)
                end
            end
        end)
    end)
end)

RegisterNetEvent("null:policeTablet:updatePenal", function(payload)
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp or not isBoss(src) then return end
    local jobName = xp.getJob().name
    if not payload or not payload.id then return end
    MySQL.Async.execute('UPDATE police_penal_code SET label=@l, price=@p, jail_time=@t, category=@c WHERE id=@id AND job_name=@j', {
        ['@id'] = tonumber(payload.id), ['@j'] = jobName,
        ['@l'] = payload.label, ['@p'] = tonumber(payload.price) or 0,
        ['@t'] = tonumber(payload.jail) or 0, ['@c'] = payload.category,
    }, function()
        loadPenalCode(jobName, function(penal)
            for _, pid in ipairs(GetPlayers()) do
                local p = ESX.GetPlayerFromId(tonumber(pid))
                if p and p.getJob().name == jobName then
                    TriggerClientEvent("null:policeTablet:penalUpdate", tonumber(pid), penal)
                end
            end
        end)
    end)
end)

RegisterNetEvent("null:policeTablet:deletePenal", function(penalId)
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp or not isBoss(src) then return end
    local jobName = xp.getJob().name
    MySQL.Async.execute('DELETE FROM police_penal_code WHERE id=@id AND job_name=@j', {
        ['@id'] = tonumber(penalId), ['@j'] = jobName
    }, function()
        loadPenalCode(jobName, function(penal)
            for _, pid in ipairs(GetPlayers()) do
                local p = ESX.GetPlayerFromId(tonumber(pid))
                if p and p.getJob().name == jobName then
                    TriggerClientEvent("null:policeTablet:penalUpdate", tonumber(pid), penal)
                end
            end
        end)
    end)
end)

-- ============================================================================
-- RADIO CODES CRUD (boss only)
-- ============================================================================
RegisterNetEvent("null:policeTablet:addRadio", function(payload)
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp or not isBoss(src) then return end
    local jobName = xp.getJob().name
    if not isPoliceJob(jobName) then return end
    if not payload or not payload.code or not payload.label then return end
    MySQL.Async.execute('INSERT INTO police_radio_codes (job_name, code, label, priority) VALUES (@j,@c,@l,@p)', {
        ['@j'] = jobName, ['@c'] = tostring(payload.code), ['@l'] = tostring(payload.label),
        ['@p'] = tonumber(payload.priority) or 0,
    }, function()
        loadRadioCodes(jobName, function() broadcastRadio(jobName) end)
    end)
end)

RegisterNetEvent("null:policeTablet:updateRadio", function(payload)
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp or not isBoss(src) then return end
    local jobName = xp.getJob().name
    if not payload or not payload.id then return end
    MySQL.Async.execute('UPDATE police_radio_codes SET code=@c, label=@l, priority=@p WHERE id=@id AND job_name=@j', {
        ['@id'] = tonumber(payload.id), ['@j'] = jobName,
        ['@c'] = tostring(payload.code or ''), ['@l'] = tostring(payload.label or ''),
        ['@p'] = tonumber(payload.priority) or 0,
    }, function()
        loadRadioCodes(jobName, function() broadcastRadio(jobName) end)
    end)
end)

RegisterNetEvent("null:policeTablet:deleteRadio", function(payload)
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp or not isBoss(src) then return end
    local jobName = xp.getJob().name
    local id = type(payload) == 'table' and payload.id or payload
    if not id then return end
    MySQL.Async.execute('DELETE FROM police_radio_codes WHERE id=@id AND job_name=@j', {
        ['@id'] = tonumber(id), ['@j'] = jobName
    }, function()
        loadRadioCodes(jobName, function() broadcastRadio(jobName) end)
    end)
end)

-- Cleanup card when player disconnects
AddEventHandler("playerDropped", function()
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp then return end
    local jobName = xp.getJob().name
    if not isPoliceJob(jobName) then return end
    local state = DispatchState[jobName]
    if state and state.cards[xp.identifier] then
        state.cards[xp.identifier] = nil
        broadcastDispatch(jobName)
    end
end)

null.InitPrint("Police Tablet Server loaded")
