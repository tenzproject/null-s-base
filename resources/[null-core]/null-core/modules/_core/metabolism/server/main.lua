--[[
    Metabolism — Server (simplifié)
    --------------------------------
    Deux stats persistantes (0-100) : hydration + fitness.
    Score = hydration*0.4 + fitness*0.6 → synced au client.
    Poids corporel caché, varie selon la fitness (jamais affiché).
    Un item alimentaire n'a besoin que d'un champ : quality = "junk"|"meal"|"gourmet"|"drink"|"soda"|"alcohol"
]]

if not Config.Metabolism or not Config.Metabolism.Enabled then return end

-- ============================================================
-- SQL migration
-- ============================================================
CreateThread(function()
    Wait(2000)
    MySQL.Async.fetchScalar([[
        SELECT COUNT(*)
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'users'
          AND COLUMN_NAME = 'metabolism'
    ]], {}, function(count)
        if tonumber(count) == 0 then
            MySQL.Async.execute('ALTER TABLE `users` ADD COLUMN `metabolism` LONGTEXT NULL DEFAULT NULL', {})
        end
    end)
end)

-- ============================================================
-- Runtime registry  [name] = { quality, fitness, hydration }
-- ============================================================
local RuntimeFoods = {}

local function resolveImpact(t)
    if type(t) ~= "table" then return nil end
    -- Format court : { quality = "meal" }
    if t.quality then
        local preset = Config.Metabolism.QualityPresets[t.quality]
        if preset then return { fitness = preset.fitness, hydration = preset.hydration } end
    end
    -- Format détaillé direct (legacy ou surcharge) : { fitness=N, hydration=N }
    if t.fitness ~= nil or t.hydration ~= nil then
        return { fitness = tonumber(t.fitness) or 0, hydration = tonumber(t.hydration) or 0 }
    end
    return nil
end

function RegisterRuntimeFood(name, impact)
    if not name or name == "" then return end
    local clean = resolveImpact(impact)
    if not clean then return end
    RuntimeFoods[string.lower(name)] = clean
end

function ClearRuntimeFood(name)
    if name then RuntimeFoods[string.lower(name)] = nil end
end

-- ============================================================
-- State
-- ============================================================
local PlayerData = {}

local BW = Config.Metabolism.Bodyweight or { neutral=75, min=50, max=130, gainPerTick=0.01, lossPerTick=0.02 }

local function clamp(v, mn, mx) if v < mn then return mn elseif v > mx then return mx else return v end end

local function defaultState()
    return { hydration = 70.0, fitness = 70.0, bodyweight = BW.neutral }
end

local function sanitize(s)
    s = s or {}
    s.hydration  = clamp(tonumber(s.hydration)  or 70.0, 0, 100)
    s.fitness    = clamp(tonumber(s.fitness)    or 70.0, 0, 100)
    s.bodyweight = clamp(tonumber(s.bodyweight) or BW.neutral, BW.min, BW.max)
    return s
end

-- Score 0-100 : pondération hydration 40%, fitness 60%
local function computeScore(s)
    return clamp(s.hydration * 0.4 + s.fitness * 0.6, 0, 100)
end

-- ============================================================
-- Persistance
-- ============================================================
local function loadFor(src, identifier, cb)
    MySQL.scalar('SELECT metabolism FROM users WHERE identifier = ?', { identifier }, function(raw)
        local state = defaultState()
        if raw and raw ~= "" then
            local ok, decoded = pcall(json.decode, raw)
            if ok and type(decoded) == "table" then
                for k, v in pairs(decoded) do state[k] = v end
            end
        end
        PlayerData[src] = sanitize(state)
        if cb then cb(PlayerData[src]) end
    end)
end

local function saveFor(src)
    local xPlayer = ESX.GetPlayerFromId(src)
    local s = PlayerData[src]
    if not xPlayer or not s then return end
    MySQL.update('UPDATE users SET metabolism = ? WHERE identifier = ?', {
        json.encode(s), xPlayer.identifier
    })
end

-- ============================================================
-- Sync
-- ============================================================
local function sync(src)
    local s = PlayerData[src]
    if not s then return end
    TriggerClientEvent('null:metabolism:sync', src, {
        score      = computeScore(s),
        hydration  = s.hydration,
        fitness    = s.fitness,
        bodyweight = s.bodyweight,
        neutralBW  = BW.neutral,
        effects    = Config.Metabolism.Effects,
    })
end

-- ============================================================
-- Consommation d'un item
-- ============================================================
local STATUS_MAX = 1000000

local function getStatusVal(xPlayer, name)
    local status = xPlayer.get('status')
    if type(status) ~= "table" then return nil end
    for _, st in ipairs(status) do
        if st.name == name then return tonumber(st.val) or 0 end
    end
    return nil
end

local function getFoodImpact(itemName, usable)
    if not itemName then return nil end
    local key = string.lower(itemName)
    -- 1. Config.Metabolism.Foods (peut avoir quality ou direct)
    local entry = Config.Metabolism.Foods[itemName] or Config.Metabolism.Foods[key]
    if entry then return resolveImpact(entry) end
    -- 2. Runtime (items créés dynamiquement)
    if RuntimeFoods[key] then return RuntimeFoods[key] end
    -- 3. Défaut par type ESX (hunger → junk, thirst → drink, drunk → alcohol)
    if usable and usable.type then
        local defQ = Config.Metabolism.Defaults[usable.type]
        if defQ then
            local preset = Config.Metabolism.QualityPresets[defQ]
            if preset then return { fitness = preset.fitness, hydration = preset.hydration } end
        end
    end
    return nil
end

local function applyConsumption(src, itemName)
    local s = PlayerData[src]
    if not s then return end

    local usable = (UsableItemList or Config.UsableItems or {})[itemName]
    local impact = getFoodImpact(itemName, usable)
    if not impact then return end

    -- Cohérence : si ESX a bloqué la consommation (jauge pleine), on ignore aussi
    if usable and (usable.type == "hunger" or usable.type == "thirst") then
        local xp = ESX.GetPlayerFromId(src)
        if xp then
            local cur = getStatusVal(xp, usable.type)
            if cur and cur >= STATUS_MAX then return end
        end
    end

    s.fitness    = clamp(s.fitness    + (impact.fitness    or 0), 0, 100)
    s.hydration  = clamp(s.hydration  + (impact.hydration  or 0), 0, 100)
    sync(src)
end

RegisterNetEvent('esx:useItem', function(itemName)
    local src = source
    SetTimeout(50, function() applyConsumption(src, itemName) end)
end)

RegisterNetEvent('null:metabolism:consume', function(itemName)
    applyConsumption(source, itemName)
end)

-- ============================================================
-- Enregistrement d'items runtime (crafts restaurants, admin)
-- ============================================================
-- Pour les crafts restaurant : quality déduite du type ESX si absente
local QualityFromType = { hunger = "meal", thirst = "drink", drunk = "alcohol" }

local function registerCraftFood(name, quality)
    local preset = Config.Metabolism.QualityPresets[quality or "meal"]
    if not preset then return end
    RuntimeFoods[string.lower(name)] = { fitness = preset.fitness, hydration = preset.hydration }
end

AddEventHandler('null:usableitem:new', function(data)
    local src = source
    local xp = ESX.GetPlayerFromId(src)
    if not xp or xp.getGroup() == "user" then return end
    if type(data) ~= "table" or not data.name or data.name == "" then return end
    local q = (type(data.metabolism) == "table" and data.metabolism.quality)
           or (type(data.metabolism) == "string" and data.metabolism)
           or "junk"
    registerCraftFood(data.name, q)
end)

local function processCraftTable(crafts)
    if type(crafts) ~= "table" then return end
    for itemName, c in pairs(crafts) do
        if type(c) == "table" then
            local q = (type(c.Metabolism) == "table" and c.Metabolism.quality)
                   or (type(c.Metabolism) == "string" and c.Metabolism)
                   or QualityFromType[c.type or ""] or "meal"
            registerCraftFood(c.Item or itemName, q)
        end
    end
end

AddEventHandler('null:editRestaurant',    function(_, craft) processCraftTable(craft) end)
AddEventHandler('null:createrestaurant',  function(_, _, _, _, _, _, _, craft) processCraftTable(craft) end)

-- Boot : charge les crafts des restaurants déjà créés
CreateThread(function()
    Wait(8000)
    if not (SaveData and SaveData.json and SaveData.json["entreprises"]) then return end
    local rest = SaveData.json["entreprises"]["Restaurant"]
    if type(rest) ~= "table" then return end
    for _, rd in pairs(rest) do
        if type(rd) == "table" then processCraftTable(rd.crafts) end
    end
end)

-- ============================================================
-- Tick : decay + ajustement poids
-- ============================================================
CreateThread(function()
    while true do
        Wait(Config.Metabolism.TickInterval)
        local decay = Config.Metabolism.Decay
        for src, s in pairs(PlayerData) do
            s.hydration = clamp(s.hydration - (decay.hydration or 0.5), 0, 100)
            s.fitness   = clamp(s.fitness   - (decay.fitness   or 0.3), 0, 100)

            -- Poids caché : varie lentement selon la fitness
            if s.fitness > 70 then
                s.bodyweight = clamp(s.bodyweight + BW.gainPerTick, BW.min, BW.max)
            elseif s.fitness < 30 then
                s.bodyweight = clamp(s.bodyweight - BW.lossPerTick, BW.min, BW.max)
            end

            sync(src)
        end
    end
end)

-- Auto-save
CreateThread(function()
    while true do
        Wait(Config.Metabolism.SaveInterval)
        for src, _ in pairs(PlayerData) do saveFor(src) end
    end
end)

-- ============================================================
-- Lifecycle
-- ============================================================
AddEventHandler('esx:playerLoaded', function(eventSrc, xPlayer)
    loadFor(eventSrc, xPlayer.identifier, function()
        sync(eventSrc)
    end)
end)

AddEventHandler('esx:playerDropped', function(eventSrc)
    if PlayerData[eventSrc] then
        saveFor(eventSrc)
        PlayerData[eventSrc] = nil
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= GetCurrentResourceName() then return end
    for src, _ in pairs(PlayerData) do saveFor(src) end
end)

-- ============================================================
-- Callback (NUI request initial)
-- ============================================================
RegisterNetEvent('null:metabolism:request', function()
    local src = source
    if PlayerData[src] then
        sync(src)
    else
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            loadFor(src, xPlayer.identifier, function() sync(src) end)
        end
    end
end)

-- ============================================================
-- Exports
-- ============================================================
exports('GetMetabolism',  function(src) return PlayerData[src] end)
exports('SyncMetabolism', function(src) sync(src) end)
exports('AddMetabolism',  function(src, key, value)
    local s = PlayerData[src]; if not s then return end
    if key == 'fitness' or key == 'hydration' then
        s[key] = clamp((s[key] or 0) + value, 0, 100)
        sync(src)
    end
end)
exports('ApplyFood', function(src, itemName) applyConsumption(src, itemName) end)

-- ============================================================
-- Commande console : reset du métabolisme d'un joueur
-- Usage : resetmetabolism <serverId>
-- ⚠ Uniquement exécutable depuis la console serveur (source == 0)
-- ============================================================
RegisterCommand('resetmetabolism', function(source, args)
    if source ~= 0 then
        -- Bloque toute exécution in-game (joueur ou admin)
        return
    end

    local target = tonumber(args[1])
    if not target then
        print("[metabolism] Usage : resetmetabolism <serverId>")
        return
    end

    local xPlayer = ESX.GetPlayerFromId(target)
    if not xPlayer then
        print(("[metabolism] Joueur introuvable (id=%s)"):format(tostring(target)))
        return
    end

    PlayerData[target] = sanitize(defaultState())
    saveFor(target)
    sync(target)
    TriggerClientEvent('esx:showNotification', target, "~b~Votre métabolisme a été réinitialisé.")
    print(("[metabolism] Métabolisme reset pour %s (id=%d, ident=%s)")
        :format(GetPlayerName(target) or "?", target, xPlayer.identifier))
end, true)
