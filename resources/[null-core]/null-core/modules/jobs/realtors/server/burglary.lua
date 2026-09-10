-- ================================================================
-- Null REALTORS — Burglary (server)
-- ----------------------------------------------------------------
-- Cambriolage des propriétés de Config.Realtors.SpawnPool :
--   • lockpick / advanced_lockpick utilisable près d'une porte
--   • minigame côté NUI (lockpick à plusieurs pins)
--   • succès → alerte police + session loot timée
--   • échec  → alarme + alerte police différée 10s
-- ================================================================

local CFG = Config and Config.Realtors
if not CFG or not CFG.Burglary or not CFG.Burglary.Enabled then
    print("^3[REALTOR][BURGLARY] Module désactivé (Config.Realtors.Burglary.Enabled = false)^0")
    return
end
local BCFG = CFG.Burglary

-- ----------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------
local function findSpawn(propKey)
    for _, sp in ipairs(CFG.SpawnPool or {}) do
        if sp.key == propKey then return sp end
    end
    return nil
end

local function neighborhoodLabel(key)
    local n = CFG.Neighborhoods and CFG.Neighborhoods[key]
    return n and n.label or (key or "?")
end

local function bannedSet()
    local s = {}
    for _, n in ipairs(BCFG.Banned or {}) do s[n] = true end
    return s
end

-- Per-property and per-player cooldown tracking (in-memory)
local propCooldown   = {}    -- [propKey]   = epochSeconds (attempt-lock or long cooldown)
local playerCooldown = {}    -- [identifier] = epochSeconds
-- Pending burglary notifications for offline property owners
-- [ownerIdentifier] = { { propName, time }, ... }
local pendingBurglaryNotifs = {}

local function nowSec() return os.time() end

local function isPropOnCooldown(key)
    local until_ = propCooldown[key]
    return until_ and until_ > nowSec()
end
local function isPlayerOnCooldown(identifier)
    local until_ = playerCooldown[identifier]
    return until_ and until_ > nowSec()
end

local function setPropCooldown(key)      propCooldown[key] = nowSec() + (BCFG.Cooldown or 0) end
local function setPropCooldownLong(key)  propCooldown[key] = nowSec() + (BCFG.PropCooldown or 21600) end
local function setPlayerCooldown(id)     playerCooldown[id] = nowSec() + (BCFG.GlobalCD or 600) end

-- ----------------------------------------------------------------
-- Time-window check
-- ----------------------------------------------------------------
local function isTimeWindowAllowed()
    local tw = BCFG.TimeWindow
    if not tw then return true end
    local h = tonumber(os.date("%H"))
    local from, to = tw.from or 0, tw.to or 23
    if from <= to then
        return h >= from and h < to
    else
        -- crosses midnight (e.g. 20 → 6)
        return h >= from or h < to
    end
end

-- ----------------------------------------------------------------
-- Forward declarations (defined later in the file)
-- ----------------------------------------------------------------
local countOnlineCops
local getOnlinePlayerByIdentifier
local findPropertyDataForSpawn

local function notifyOwnerOfBurglary(propKey, propName)
    if not BCFG.OwnerNotify then return end
    local prop = findPropertyDataForSpawn and findPropertyDataForSpawn(propKey)
    if not prop then return end
    local ownerIdentifier = prop.owner
    if not ownerIdentifier or ownerIdentifier == (CFG.SocietyName or "") then return end

    local label = prop.label or propName or propKey
    local _, src = getOnlinePlayerByIdentifier(ownerIdentifier)
    if src then
        TriggerClientEvent('esx:showAdvancedNotification', src,
            "~r~CAMBRIOLAGE", "Votre propriété",
            "Votre propriété ~y~" .. label .. "~s~ est en train d'être cambriolée !",
            "CHAR_BLOCKED")
    else
        -- Owner is offline → queue notification
        if not pendingBurglaryNotifs[ownerIdentifier] then
            pendingBurglaryNotifs[ownerIdentifier] = {}
        end
        table.insert(pendingBurglaryNotifs[ownerIdentifier], {
            label = label,
            time  = os.date("%H:%M"),
        })
    end
end

-- ----------------------------------------------------------------
-- Property ownership lookup (a burglar should NOT pick his own house)
-- We rely on the existing realtor module's exposed helpers if any.
-- Fallback : query the SaveData / module state used by main.lua.
-- ----------------------------------------------------------------
local function propertyIsOwnedByJob(propKey)
    -- The realtors module stores owned properties in SaveData under a key.
    -- We attempt the most common patterns; if none found, returns false (assume free).
    if SaveData and SaveData.json then
        local rj = SaveData.json["realtors"] or SaveData.json["Realtors"]
        if rj and rj.owned then
            return rj.owned[propKey] ~= nil
        end
    end
    return false
end

-- ----------------------------------------------------------------
-- Police alert (mirrors gofast / police alerte pattern)
-- ----------------------------------------------------------------
local function isPoliceJob(jobName)
    if not SaveData or not SaveData.json then return false end
    local ent = SaveData.json["entreprises"]
    return ent and ent["Police"] and ent["Police"][jobName] ~= nil
end

countOnlineCops = function()
    local count = 0
    for _, src in ipairs(ESX.GetPlayers()) do
        local p = ESX.GetPlayerFromId(src)
        if p and isPoliceJob(p.job.name) then
            count = count + 1
        end
    end
    return count
end

getOnlinePlayerByIdentifier = function(identifier)
    for _, src in ipairs(ESX.GetPlayers()) do
        local p = ESX.GetPlayerFromId(src)
        if p and p.identifier == identifier then return p, src end
    end
    return nil, nil
end

local function alertPolice(spawn, profile)
    local door = spawn.door
    local nbh  = neighborhoodLabel(spawn.neighborhood)
    local msg  = string.format(profile.message or "Cambriolage", nbh)
    local id   = "burglary_" .. spawn.key
    local blip = profile.blip or {}

    local xPlayers = ESX.GetPlayers()
    for _, src in ipairs(xPlayers) do
        local p = ESX.GetPlayerFromId(src)
        if p and isPoliceJob(p.job.name) then
            TriggerClientEvent('esx:showAdvancedNotification', src,
                profile.title or "DISPATCH 911",
                profile.subtitle or "Alerte",
                msg,
                profile.icon or "CHAR_CALL911")
            TriggerClientEvent('null:police:blips', src,
                id, profile.subtitle or "Cambriolage",
                vector3(door.x, door.y, door.z),
                blip.sprite or 161, blip.color or 1, "burglary")
        end
    end

    -- Auto-cleanup blip after configured duration
    local dur = (blip.duration or 120) * 1000
    SetTimeout(dur, function()
        local xs = ESX.GetPlayers()
        for _, src in ipairs(xs) do
            local p = ESX.GetPlayerFromId(src)
            if p and isPoliceJob(p.job.name) then
                TriggerClientEvent('null:police:removeblips', src, id)
            end
        end
    end)
end

-- ----------------------------------------------------------------
-- Loot generation (server-authoritative)
--   Returns { sessionId, items = [{ key, item, count, label }, ...] }
--   The client sees these "stacks" and can click up to maxItems
-- ----------------------------------------------------------------
local activeSessions = {}    -- [sessionId] = { src, propKey, interior, taken=0, max, items={...}, expiresAt }

local function rollInt(min, max)
    if max <= min then return min end
    return math.random(min, max)
end

local function pickWeighted(table_)
    local total = 0
    for _, e in ipairs(table_) do total = total + (e.weight or 1) end
    local r = math.random() * total
    local acc = 0
    for _, e in ipairs(table_) do
        acc = acc + (e.weight or 1)
        if r <= acc then return e end
    end
    return table_[#table_]
end

local function generateLoot(interior, count)
    local table_ = BCFG.LootTables[interior]
    if not table_ then return {} end
    local banned = bannedSet()
    local out, idx = {}, 0
    for i = 1, count do
        local entry = pickWeighted(table_)
        if entry and not banned[entry.item] then
            local qty = rollInt(entry.count[1], entry.count[2])
            idx = idx + 1
            local label = (ESX.Items[entry.item] and ESX.Items[entry.item].label) or entry.item
            out[#out+1] = {
                key   = "loot_" .. idx,
                item  = entry.item,
                count = qty,
                label = label,
            }
        end
    end
    return out
end

local function newSessionId() return string.format("burg_%d_%d", nowSec(), math.random(1000, 9999)) end

-- ----------------------------------------------------------------
-- ESX.RegisterUsableItem callbacks
-- ----------------------------------------------------------------
local function onUseLockpick(playerId, itemName)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return end

    if isPlayerOnCooldown(xPlayer.identifier) then
        TriggerClientEvent('esx:showNotification', playerId, "~r~Vous avez tenté un cambriolage récemment.")
        return
    end

    -- Tell client to find a nearby door and validate distance + send back propKey
    TriggerClientEvent("realtor:burglary:tryUse", playerId, itemName)
end

ESX.RegisterUsableItem("lockpick",          function(src) onUseLockpick(src, "lockpick") end)
ESX.RegisterUsableItem("advanced_lockpick", function(src) onUseLockpick(src, "advanced_lockpick") end)

-- ----------------------------------------------------------------
-- Server callbacks
-- ----------------------------------------------------------------
-- Client validated proximity; ask server for difficulty + start session
ESX.RegisterServerCallback("realtor:burglary:start", function(source, cb, propKey, itemName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ ok = false, reason = "no_player" }) end

    if isPlayerOnCooldown(xPlayer.identifier) then
        return cb({ ok = false, reason = "global_cd" })
    end

    local spawn = findSpawn(propKey)
    if not spawn then return cb({ ok = false, reason = "unknown_prop" }) end
    if isPropOnCooldown(propKey) then return cb({ ok = false, reason = "prop_cd" }) end

    -- Time window check
    if not isTimeWindowAllowed() then
        return cb({ ok = false, reason = "time_window" })
    end

    -- Minimum police check
    local minPol = BCFG.MinPolice or 0
    if minPol > 0 and countOnlineCops() < minPol then
        return cb({ ok = false, reason = "not_enough_police", required = minPol })
    end

    local interior = spawn.interior
    local required = BCFG.RequireItems[interior]
    if not required then return cb({ ok = false, reason = "not_breakable" }) end

    local item = xPlayer.getInventoryItem(required)
    if not item or item.count < 1 then
        return cb({ ok = false, reason = "missing_tool", required = required })
    end
    if itemName ~= required and not (itemName == "advanced_lockpick" and required == "lockpick") then
        return cb({ ok = false, reason = "wrong_tool", required = required })
    end

    local diff = BCFG.Difficulty[interior]
    if not diff then return cb({ ok = false, reason = "no_difficulty" }) end

    -- Lock the property immediately to prevent concurrent attempts
    propCooldown[propKey] = nowSec() + 60

    -- ⚡ Alerte police dès le lockpick (tentative)
    alertPolice(spawn, BCFG.PoliceAlert.immediate)

    -- 🔔 Notifier le propriétaire (en ligne ou queue hors-ligne)
    notifyOwnerOfBurglary(propKey, propKey)

    cb({
        ok         = true,
        propKey    = propKey,
        interior   = interior,
        toolUsed   = itemName,
        difficulty = diff,
    })
end)

-- Helper: find the SaveData property entry for a spawn key
-- Three strategies in order:
--   1. p.originSpawn == propKey  (set at creation by realtor module)
--   2. p.parms.realtor.originSpawn == propKey  (persisted after restart)
--   3. Distance fallback: p.positions.EXIT close to the SpawnPool door (<= 5 units)
--      For older properties not created via realtor module (e.g. "Low26647919")
findPropertyDataForSpawn = function(propKey)
    if not SaveData or not SaveData.PropertiesList then return nil end

    -- Strategy 1 & 2
    for _, p in pairs(SaveData.PropertiesList) do
        if p.originSpawn == propKey then return p end
        if p.parms and p.parms.realtor and p.parms.realtor.originSpawn == propKey then
            p.originSpawn = p.parms.realtor.originSpawn
            return p
        end
    end

    -- Strategy 3: match by door position
    local spawn = findSpawn(propKey)
    if not spawn then return nil end
    local dx, dy, dz = spawn.door.x, spawn.door.y, spawn.door.z
    local best, bestDist
    for _, p in pairs(SaveData.PropertiesList) do
        local pos = p.positions and (p.positions.EXIT or p.positions["EXIT"])
        if pos then
            local dist = math.sqrt((pos.x-dx)^2 + (pos.y-dy)^2 + (pos.z-dz)^2)
            if dist <= 10.0 and (not bestDist or dist < bestDist) then
                best, bestDist = p, dist
            end
        end
    end
    if best then
        -- Cache the link for next calls
        best.originSpawn = propKey
        print("^3[BURGLARY] findPropertyDataForSpawn: lié '"..propKey.."' → '"..tostring(best.name).."' par distance ("..string.format("%.2f", bestDist).."u)^0")
    end
    return best
end

-- Helper: get real property chest contents from vstorage (proprieties_<propName>)
-- Returns items list and the resolved property name for later removal
local function getPropertyChestContents(propKey)
    local prop = findPropertyDataForSpawn(propKey)
    if not prop then
        print("^1[BURGLARY] Propriété '"..tostring(propKey).."' introuvable dans SaveData.PropertiesList^0")
        return {}, nil
    end

    local storageName = "proprieties_" .. prop.name
    local result = MySQL.query.await('SELECT coffre FROM vstorage WHERE name = @name', { ['@name'] = storageName })

    if not result or not result[1] or not result[1].coffre then
        print("^3[BURGLARY] vstorage '"..storageName.."' vide ou absent^0")
        return {}, prop.name
    end

    local data = json.decode(result[1].coffre)
    if not data or not data.items or #data.items == 0 then
        print("^3[BURGLARY] vstorage '"..storageName.."' ne contient aucun item^0")
        return {}, prop.name
    end

    local items = {}
    for _, itemData in ipairs(data.items) do
        if itemData.name and itemData.count and itemData.count > 0 then
            local label = (ESX.Items[itemData.name] and ESX.Items[itemData.name].label) or itemData.name
            table.insert(items, {
                key   = itemData.name,
                item  = itemData.name,
                count = itemData.count,
                label = label,
                isRealChest = true,
            })
        end
    end

    print("^2[BURGLARY] Coffre '"..storageName.."' → "..#items.." item(s)^0")
    return items, prop.name
end

-- Helper: remove items from property chest in vstorage
-- propName = resolved property name (e.g. "realtor_XXXX_XXXX"), not the spawnKey
local function removeFromPropertyChest(propName, itemName, count)
    local storageName = "proprieties_" .. propName
    local result = MySQL.query.await('SELECT coffre FROM vstorage WHERE name = @name', { ['@name'] = storageName })
    if not result or not result[1] or not result[1].coffre then return false end

    local data = json.decode(result[1].coffre)
    if not data or not data.items then return false end

    local found = false
    for i, it in ipairs(data.items) do
        if it.name == itemName then
            if it.count < count then return false end
            it.count = it.count - count
            if it.count <= 0 then
                table.remove(data.items, i)
            end
            found = true
            break
        end
    end
    if not found then return false end

    MySQL.Async.execute('UPDATE vstorage SET coffre = @coffre WHERE name = @name', {
        ['@coffre'] = json.encode(data),
        ['@name']   = storageName,
    })
    return true
end

-- Minigame finished — outcome routing
ESX.RegisterServerCallback("realtor:burglary:finish", function(source, cb, payload)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ ok = false }) end

    local propKey = payload and payload.propKey
    local success = payload and payload.success
    local toolUsed = payload and payload.toolUsed or "lockpick"
    local spawn   = findSpawn(propKey)
    if not spawn then return cb({ ok = false, reason = "unknown_prop" }) end

    -- Apply player cooldown immediately (anti-spam)
    setPlayerCooldown(xPlayer.identifier)

    if success then
        -- Long cooldown sur la propriété (6h)
        setPropCooldownLong(propKey)

        -- L'alerte police a déjà été envoyée au start (lockpick), pas besoin de répéter

        -- Build loot session (real chest or generated loot)
        local diff   = BCFG.Difficulty[spawn.interior]
        local rcl    = BCFG.RealChestLoot
        local loot   = {}
        local isRealChest = false
        local resolvedPropName = nil

        if rcl and rcl.Enabled then
            -- Use real property chest contents
            loot, resolvedPropName = getPropertyChestContents(propKey)
            isRealChest = true
        else
            -- Fallback: generated random loot
            local nItems = math.max(diff.maxItems, 5) + 3
            loot = generateLoot(spawn.interior, nItems)
        end

        local sid    = newSessionId()
        local lootTime = (rcl and rcl.LootTime) or diff.lootTime
        activeSessions[sid] = {
            src       = source,
            propKey   = propKey,
            interior  = spawn.interior,
            taken     = 0,
            max       = (rcl and rcl.MaxDifferentItems) or diff.maxItems,
            maxQty    = (rcl and rcl.MaxQuantityPerItem) or 10,
            items     = loot,
            expiresAt = nowSec() + lootTime,
            isRealChest = isRealChest,
            resolvedPropName = resolvedPropName, -- actual properties_list key for vstorage
            stolenItems = {}, -- track what was already stolen
        }

        -- Auto-cleanup when timer expires
        SetTimeout((lootTime + 5) * 1000, function()
            if activeSessions[sid] then
                TriggerClientEvent("realtor:burglary:lootEnd", source, { reason = "timeout" })
                activeSessions[sid] = nil
            end
        end)

        -- Retrieve property physical data (positions + bucketID) for client teleport
        local propData = findPropertyDataForSpawn(propKey)
        -- Build a minimal propData if not found (fallback using spawn door as EXIT)
        if not propData then
            local interiorCfg = Config.Properties and Config.Properties.List and Config.Properties.List[spawn.interior]
            propData = {
                bucketID  = math.random(210000, 219999),
                positions = {
                    EXIT   = { x = spawn.door.x, y = spawn.door.y, z = spawn.door.z },
                    ENTER  = interiorCfg and interiorCfg.positions and interiorCfg.positions.inside
                             or { x = spawn.door.x, y = spawn.door.y, z = spawn.door.z },
                    COFFRE = interiorCfg and interiorCfg.positions and interiorCfg.positions.cam_coords
                             or { x = spawn.door.x, y = spawn.door.y, z = spawn.door.z },
                },
            }
        end

        cb({
            ok        = true,
            sessionId = sid,
            items     = loot,
            timeLeft  = lootTime,
            maxItems  = (rcl and rcl.MaxDifferentItems) or diff.maxItems,
            isRealChest = isRealChest,
            interior  = spawn.interior,
            maxQtyPerItem      = (rcl and rcl.MaxQuantityPerItem) or 10,
            attemptsPerItem    = (rcl and rcl.AttemptsPerItem) or 1,
            itemStealCooldown  = (rcl and rcl.ItemStealCooldown) or 0,
            minigameConfig = (rcl and rcl.Minigame) and {
                enabled       = rcl.Minigame.enabled,
                duration      = rcl.Minigame.duration,
                sweetSpotSize = rcl.Minigame.sweetSpotSize,
                maxAttempts   = rcl.Minigame.maxAttempts,
                scaling       = rcl.Minigame.DifficultyScaling,
            } or nil,
            propData  = {
                bucketID  = propData.bucketID,
                positions = propData.positions,
            },
        })
    else
        -- Failure: maybe consume the tool, play alarm (police already alerted at start)
        local breakChance = BCFG.BreakChance[toolUsed] or 0
        if breakChance > 0 and math.random() < breakChance then
            xPlayer.removeInventoryItem(toolUsed, 1)
            TriggerClientEvent('esx:showNotification', source, "~r~Votre " .. toolUsed .. " s'est cassé !")
        end

        setPropCooldown(propKey)

        -- Tell the client to play the alarm sound
        TriggerClientEvent("realtor:burglary:alarm", source, {
            propKey = propKey,
            door    = { x = spawn.door.x, y = spawn.door.y, z = spawn.door.z },
        })

        cb({ ok = true, success = false })
    end
end)

-- Pick a single loot stack from the active session
-- NEW: Supports real chest loot with mini-game validation and quantity limits
ESX.RegisterServerCallback("realtor:burglary:loot", function(source, cb, payload)
    local sid = payload and payload.sessionId
    local key = payload and payload.lootKey
    local quantity = payload and payload.quantity or 1
    local minigameSuccess = payload and payload.minigameSuccess
    local sess = sid and activeSessions[sid] or nil

    if not sess or sess.src ~= source then return cb({ ok = false, reason = "no_session" }) end
    if nowSec() > sess.expiresAt              then return cb({ ok = false, reason = "expired" })   end
    if sess.taken >= sess.max                  then return cb({ ok = false, reason = "max_items" }) end

    -- Mini-game check (if enabled and required)
    local rcl = BCFG.RealChestLoot
    if rcl and rcl.Minigame and rcl.Minigame.enabled then
        if minigameSuccess ~= true then
            return cb({ ok = false, reason = "minigame_failed" })
        end
    end

    local found, idx
    for i, it in ipairs(sess.items) do
        if it.key == key then found, idx = it, i; break end
    end
    if not found then return cb({ ok = false, reason = "unknown_loot" }) end

    -- Banned check (defensive)
    local banned = bannedSet()
    if banned[found.item] then
        table.remove(sess.items, idx)
        return cb({ ok = false, reason = "banned", items = sess.items })
    end

    -- Validate quantity limits
    local maxQty = sess.maxQty or 10
    if quantity > maxQty then quantity = maxQty end
    if quantity > found.count then quantity = found.count end
    if quantity <= 0 then return cb({ ok = false, reason = "invalid_quantity" }) end

    -- Check if already stolen this item type
    local alreadyStolen = sess.stolenItems[found.item] or 0
    if alreadyStolen + quantity > maxQty then
        quantity = maxQty - alreadyStolen
        if quantity <= 0 then
            return cb({ ok = false, reason = "max_quantity_reached" })
        end
    end

    -- Add item to player
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ ok = false, reason = "no_player" }) end
    if not ESX.Items[found.item] then
        print("^3[BURGLARY] Item inconnu dans ESX.Items: " .. tostring(found.item) .. " (vérifie ta DB items)^0")
        table.remove(sess.items, idx)
        return cb({ ok = false, reason = "unknown_item", items = sess.items })
    end

    -- For real chest: remove from property first
    if sess.isRealChest then
        local removed = removeFromPropertyChest(sess.resolvedPropName or sess.propKey, found.item, quantity)
        if not removed then
            return cb({ ok = false, reason = "chest_empty" })
        end
    end

    -- Give to player
    xPlayer.addInventoryItem(found.item, quantity)
    sess.taken = sess.taken + 1
    sess.stolenItems[found.item] = alreadyStolen + quantity

    -- Update remaining count in session
    found.count = found.count - quantity
    if found.count <= 0 then
        table.remove(sess.items, idx)
    end

    cb({
        ok        = true,
        taken     = sess.taken,
        max       = sess.max,
        items     = sess.items,
        picked    = { item = found.item, count = quantity, label = found.label },
        remaining = found.count,
    })

    -- If reached max different items, auto-end
    if sess.taken >= sess.max then
        TriggerClientEvent("realtor:burglary:lootEnd", source, { reason = "max" })
        activeSessions[sid] = nil
    end
end)

-- Player explicitly closes the loot panel
RegisterServerEvent("realtor:burglary:abort")
AddEventHandler("realtor:burglary:abort", function(sessionId)
    local src = source
    local sess = activeSessions[sessionId]
    if sess and sess.src == src then
        activeSessions[sessionId] = nil
    end
end)

-- ----------------------------------------------------------------
-- Notify owner on reconnect if burglarized while offline
-- ----------------------------------------------------------------
AddEventHandler("esx:playerLoaded", function(playerId, xPlayer)
    local id = xPlayer and xPlayer.identifier
    if not id then return end
    local notifs = pendingBurglaryNotifs[id]
    if not notifs or #notifs == 0 then return end

    SetTimeout(5000, function()
        for _, n in ipairs(notifs) do
            TriggerClientEvent('esx:showAdvancedNotification', playerId,
                "~r~CAMBRIOLAGE", "Votre propriété",
                "Votre propriété ~y~" .. n.label .. "~s~ a été cambriolée à ~b~" .. n.time .. "~s~ pendant votre absence.",
                "CHAR_BLOCKED")
        end
        pendingBurglaryNotifs[id] = nil
    end)
end)

-- ----------------------------------------------------------------
-- Cleanup on player drop
-- ----------------------------------------------------------------
AddEventHandler("playerDropped", function()
    local src = source
    for sid, s in pairs(activeSessions) do
        if s.src == src then activeSessions[sid] = nil end
    end
end)