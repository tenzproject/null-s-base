-- Dashboard Bridge: expose des actions live sur l'API HTTP du serveur (port 30147)
-- Auth: déjà gérée par common.lua (Bearer + IP whitelist api.null.fr)

local function ok(data)
    local r = data or {}
    r.success = true
    return r
end

local function err(message, status)
    return { success = false, error = message, _status = status or 400 }
end

local function getXPlayer(id)
    if not id or not ESX then return nil end
    return ESX.GetPlayerFromId(tonumber(id))
end

local function safeRun(fn)
    Citizen.CreateThread(fn)
end

-- ============================================
-- GET /live/players — liste détaillée
-- ============================================
null.api.registerRoute("GET", "/live/players", function()
    local players = {}
    if not ESX or not ESX.Players then return ok({ players = players }) end

    for _, xPlayer in pairs(ESX.Players) do
        if xPlayer then
            local accounts = {}
            for _, acc in pairs(xPlayer.getAccounts() or {}) do
                accounts[acc.name] = acc.money
            end
            local ped = GetPlayerPed(xPlayer.source)
            local coords = ped and GetEntityCoords(ped) or vector3(0,0,0)
            table.insert(players, {
                source = xPlayer.source,
                name = xPlayer.getName(),
                identifier = xPlayer.identifier,
                idunique = xPlayer.getIdunique and xPlayer.getIdunique() or nil,
                group = xPlayer.getGroup(),
                job = xPlayer.job and { name = xPlayer.job.name, label = xPlayer.job.label, grade = xPlayer.job.grade, grade_label = xPlayer.job.grade_label } or nil,
                accounts = accounts,
                ping = GetPlayerPing(xPlayer.source),
                coords = { x = coords.x, y = coords.y, z = coords.z },
                playtime = xPlayer.getPlaytime and xPlayer.getPlaytime() or nil,
            })
        end
    end
    return ok({ players = players, count = #players })
end)

-- ============================================
-- POST /live/broadcast — annonce globale
-- ============================================
null.api.registerRoute("POST", "/live/broadcast", function(body)
    local message = body.message
    if not message or message == "" then return err("Message requis") end

    local subtitle = body.subtitle or "Dashboard"
    local duration = tonumber(body.duration) or 8000

    if ESX and ESX.ShowAnnouncementToAll then
        ESX.ShowAnnouncementToAll(message, duration, subtitle)
    else
        TriggerClientEvent('esx:showAnnouncement', -1, message, 'global', duration, subtitle)
    end
    return ok({ message = "Broadcast envoyé" })
end)

-- ============================================
-- POST /live/kick — éjecter un joueur
-- ============================================
null.api.registerRoute("POST", "/live/kick", function(body)
    local playerId = tonumber(body.playerId)
    if not playerId then return err("playerId requis") end
    local xPlayer = getXPlayer(playerId)
    if not xPlayer then return err("Joueur introuvable", 404) end

    local reason = body.reason or "Vous avez été kick depuis le dashboard"
    DropPlayer(playerId, reason)
    if null and null.logs and null.logs.send then
        null.logs.send("Dashboard", ("Dashboard a kick %s — Raison: %s"):format(xPlayer.getName(), reason), "kick")
    end
    return ok({ message = "Joueur kick" })
end)

-- ============================================
-- POST /live/ban — bannir un joueur
-- ============================================
null.api.registerRoute("POST", "/live/ban", function(body)
    local playerId = tonumber(body.playerId)
    if not playerId then return err("playerId requis") end
    local xPlayer = getXPlayer(playerId)
    if not xPlayer then return err("Joueur introuvable", 404) end

    local duration = tonumber(body.duration) or 0 -- 0 = permanent
    local reason = body.reason or "Banni depuis le dashboard"
    ExecuteCommand(("ban %d %d %s"):format(playerId, duration, reason))
    if null and null.logs and null.logs.send then
        null.logs.send("Dashboard", ("Dashboard a ban %s (%dh) — Raison: %s"):format(xPlayer.getName(), duration, reason), "ban")
    end
    return ok({ message = "Joueur banni" })
end)

-- ============================================
-- POST /live/revive — réanimer un joueur
-- ============================================
null.api.registerRoute("POST", "/live/revive", function(body)
    local playerId = tonumber(body.playerId)
    if not playerId then return err("playerId requis") end
    local xPlayer = getXPlayer(playerId)
    if not xPlayer then return err("Joueur introuvable", 404) end

    TriggerClientEvent("esx:restoreHealth", playerId)
    TriggerClientEvent("null:revive", playerId)
    TriggerClientEvent("EMS:ReviveClientPlayer", playerId)
    ExecuteCommand("heal " .. playerId)
    return ok({ message = "Joueur réanimé" })
end)

-- ============================================
-- POST /live/giveItem — donner un item
-- ============================================
null.api.registerRoute("POST", "/live/giveItem", function(body)
    local playerId = tonumber(body.playerId)
    local itemName = body.itemName
    local count = tonumber(body.count) or 1
    if not playerId or not itemName then return err("playerId et itemName requis") end
    local xPlayer = getXPlayer(playerId)
    if not xPlayer then return err("Joueur introuvable", 404) end

    if not ESX.Items or not ESX.Items[itemName] then return err("Item inexistant", 404) end
    if not xPlayer.canCarryItem(itemName, count) then return err("Inventaire plein") end

    xPlayer.addInventoryItem(itemName, count)
    if null and null.logs and null.logs.send then
        null.logs.send("Dashboard", ("Dashboard a donné %dx %s à %s"):format(count, itemName, xPlayer.getName()), "item")
    end
    return ok({ message = "Item donné" })
end)

-- ============================================
-- POST /live/giveMoney — donner argent
-- ============================================
null.api.registerRoute("POST", "/live/giveMoney", function(body)
    local playerId = tonumber(body.playerId)
    local account = body.account or "money" -- money | bank | black_money
    local amount = tonumber(body.amount)
    if not playerId or not amount then return err("playerId et amount requis") end
    local xPlayer = getXPlayer(playerId)
    if not xPlayer then return err("Joueur introuvable", 404) end

    if account == "money" or account == "cash" then
        xPlayer.addMoney(amount)
    else
        xPlayer.addAccountMoney(account, amount)
    end
    if null and null.logs and null.logs.send then
        null.logs.send("Dashboard", ("Dashboard a donné $%d (%s) à %s"):format(amount, account, xPlayer.getName()), "money")
    end
    return ok({ message = "Argent donné" })
end)

-- ============================================
-- POST /live/restartResource — redémarrer une ressource
-- ============================================
null.api.registerRoute("POST", "/live/restartResource", function(body)
    local resource = body.resource
    if not resource or resource == "" then return err("Ressource requise") end
    -- Blacklist: ne pas autoriser à redémarrer null-core lui-même via dashboard
    if resource == GetCurrentResourceName() then return err("Impossible de redémarrer null-core via le dashboard") end

    local state = GetResourceState(resource)
    if state == "missing" or state == "unknown" then return err("Ressource introuvable", 404) end

    safeRun(function()
        ExecuteCommand("restart " .. resource)
    end)
    return ok({ message = "Redémarrage demandé pour " .. resource })
end)

-- ============================================
-- GET /live/economy — snapshot économie
-- ============================================
null.api.registerRoute("GET", "/live/economy", function()
    local totalCash, totalBank, totalBlack = 0, 0, 0
    local playerCount = 0
    if ESX and ESX.Players then
        for _, xPlayer in pairs(ESX.Players) do
            if xPlayer then
                playerCount = playerCount + 1
                totalCash = totalCash + (xPlayer.getMoney() or 0)
                for _, acc in pairs(xPlayer.getAccounts() or {}) do
                    if acc.name == "bank" then totalBank = totalBank + (acc.money or 0)
                    elseif acc.name == "black_money" then totalBlack = totalBlack + (acc.money or 0) end
                end
            end
        end
    end
    return ok({
        online = playerCount,
        cash = totalCash,
        bank = totalBank,
        blackMoney = totalBlack,
        total = totalCash + totalBank + totalBlack,
    })
end)
