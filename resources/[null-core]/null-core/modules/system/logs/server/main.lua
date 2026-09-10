--[[
    Null Logs System
    Module de gestion des logs (Discord / Database)
]]

-- Namespace
null.logs = null.logs or {}

-- Cache pour éviter les logs dupliqués
local logCache = {}
local CACHE_DURATION = 1000 -- 1 seconde

-- Caractères à nettoyer des messages
local CLEAN_PATTERNS = {
    ["~s~"] = "", ["~r~"] = "", ["~g~"] = "", ["~b~"] = "",
    ["~y~"] = "", ["~p~"] = "", ["~n~"] = " ", ["\\n"] = " ",
    ["**"] = "", ["__"] = "", ["@"] = ""
}

--[[
    Nettoie un message des caractères spéciaux
    @param message string - Message à nettoyer
    @return string - Message nettoyé
]]
local function cleanMessage(message)
    if not message then return "" end
    for pattern, replacement in pairs(CLEAN_PATTERNS) do
        message = message:gsub(pattern, replacement)
    end
    return message
end

--[[
    Vérifie si un log est dupliqué (anti-spam)
    @param key string - Clé unique du log
    @return boolean - true si dupliqué
]]
local function isDuplicate(key)
    local now = GetGameTimer()
    if logCache[key] and (now - logCache[key]) < CACHE_DURATION then
        return true
    end
    logCache[key] = now
    return false
end

--[[
    Récupère le webhook pour un type de log
    @param logType string - Type de log
    @return string - URL du webhook
]]
local function getWebhook(logType)
    if Config.Logs[logType] and Config.Logs[logType] ~= "" then
        return Config.Logs[logType]
    end
    return Config.Logs["all"] or ""
end

--[[
    Envoie un log vers Discord
    @param title string - Titre du log
    @param message string - Message
    @param logType string - Type de log
    @param metadata table - Données supplémentaires (optionnel)
]]
local function sendToDiscord(title, message, logType, metadata)
    local webhook = getWebhook(logType)
    if webhook == "" then return end
    
    local serverName = ESX.Config("serverName") or "Null"
    local serverIcon = ESX.Config("serverCHAR") or ""
    
    local embed = {
        ["author"] = {
            ["name"] = "Logs",
            ["icon_url"] = serverIcon
        },
        ["title"] = title,
        ["description"] = cleanMessage(message),
        ["color"] = metadata and metadata.color or 3447003, -- Bleu par défaut
        ["footer"] = {
            ["text"] = "Logs • " .. os.date("%d/%m/%Y %H:%M:%S"),
            ["icon_url"] = serverIcon
        }
    }
    
    -- Ajouter des champs si metadata contient des infos joueur
    if metadata then
        local fields = {}
        if metadata.idunique then
            table.insert(fields, { name = "ID Unique", value = tostring(metadata.idunique), inline = true })
        end
        if metadata.name then
            table.insert(fields, { name = "Joueur", value = metadata.name, inline = true })
        end
        if metadata.idunique_cible then
            table.insert(fields, { name = "Cible ID", value = tostring(metadata.idunique_cible), inline = true })
        end
        if metadata.name_cible then
            table.insert(fields, { name = "Cible", value = metadata.name_cible, inline = true })
        end
        if #fields > 0 then
            embed["fields"] = fields
        end
    end
    
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({
        username = serverName,
        embeds = { embed },
        avatar_url = serverIcon
    }), {
        ['Content-Type'] = 'application/json'
    })
end

--[[
    Envoie un log vers la base de données
    @param title string - Titre du log
    @param message string - Message
    @param logType string - Type de log
    @param metadata table - Données supplémentaires (optionnel)
]]
local function sendToDatabase(title, message, logType, metadata)
    local data = {
        logs_title = title,
        logs_message = cleanMessage(message)
    }
    
    -- Fusionner les metadata
    if metadata then
        for k, v in pairs(metadata) do
            if k ~= "color" then -- Ignorer la couleur pour la DB
                data[k] = v
            end
        end
    end
    
    MySQL.Async.execute(
        "INSERT INTO `vlogs` (`type`, `data`) VALUES (@type, @data)",
        {
            ['@type'] = logType,
            ['@data'] = json.encode(data)
        }
    )
end

function OthersLogsDetails(title, message, logType, metadata) 
    null.logs.send(title, message, logType, metadata)
end

--[[
    Fonction principale d'envoi de logs
    @param title string - Titre du log
    @param message string - Message
    @param logType string - Type de log (connexion, mort, kill, etc.)
    @param metadata table - Données supplémentaires (optionnel)
        - idunique: ID unique du joueur
        - name: Nom du joueur
        - idunique_cible: ID unique de la cible
        - name_cible: Nom de la cible
        - color: Couleur Discord (nombre)
        - ... autres données custom
]]
function null.logs.send(title, message, logType, metadata)
    if not title or not message or not logType then
        return null.DebugPrint("[Logs] Paramètres manquants pour l'envoi du log")
    end
    
    -- Anti-spam: vérifier les doublons
    local cacheKey = logType .. "_" .. message
    if isDuplicate(cacheKey) then
        return
    end
    
    -- Debug
    null.DebugPrint(("[Logs] %s: %s"):format(logType, title))
    
    -- Envoyer selon le type configuré
    if Config.LogsSys.type == "discord" then
        sendToDiscord(title, message, logType, metadata)
    elseif Config.LogsSys.type == "php" or Config.LogsSys.type == "database" then
        sendToDatabase(title, message, logType, metadata)
    elseif Config.LogsSys.type == "both" then
        sendToDiscord(title, message, logType, metadata)
        sendToDatabase(title, message, logType, metadata)
    end
end

-- Alias court
null.fct.logs = null.logs

-- Export pour les autres ressources
exports("SendLogs", function(title, message, logType, metadata)
    null.logs.send(title, message, logType, metadata)
end)
