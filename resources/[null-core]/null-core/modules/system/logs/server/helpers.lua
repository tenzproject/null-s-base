--[[
    Null Logs System - Helpers
    Fonctions utilitaires pour faciliter l'envoi de logs
]]
    
-- Namespace
null.logs = null.logs or {}

local Colors = {
    green = 5763719,
    red = 15548997,
    orange = 16744192,
    blue = 3447003,
    purple = 10181046,
    grey = 9807270
}

--[[
    Crée les metadata de base pour un joueur
    @param xPlayer table - Objet ESX Player
    @return table - Metadata formatées
]]
function null.logs.playerMeta(xPlayer)
    if not xPlayer then return {} end
    return {
        idunique = xPlayer.getIdunique(),
        name = xPlayer.getName()
    }
end

--[[
    Crée les metadata pour une transaction entre joueurs
    @param xPlayer table - Joueur source
    @param xTarget table - Joueur cible
    @return table - Metadata formatées
]]
function null.logs.transactionMeta(xPlayer, xTarget)
    local meta = null.logs.playerMeta(xPlayer)
    if xTarget then
        meta.idunique_cible = xTarget.getIdunique()
        meta.name_cible = xTarget.getName()
    end
    return meta
end

--[[
    Log rapide pour les items
    @param action string - Action (give, remove, use, drop)
    @param xPlayer table - Joueur
    @param itemName string - Nom de l'item
    @param count number - Quantité
    @param xTarget table - Cible (optionnel)
]]
function null.logs.item(action, xPlayer, itemName, count, xTarget)
    if not xPlayer or not itemName then return end
    
    local logType = action .. "-item"
    local title = action:gsub("^%l", string.upper) .. " Item"
    local message = ""
    local meta = null.logs.playerMeta(xPlayer)
    
    if action == "give" and xTarget then
        message = ("**%s** a donné **%dx %s** à **%s**"):format(
            xPlayer.getName(), count or 1, itemName, xTarget.getName()
        )
        meta = null.logs.transactionMeta(xPlayer, xTarget)
    elseif action == "remove" then
        message = ("**%dx %s** retiré de **%s**"):format(count or 1, itemName, xPlayer.getName())
    elseif action == "use" then
        message = ("**%s** a utilisé **%s**"):format(xPlayer.getName(), itemName)
        logType = "use-item"
    elseif action == "drop" then
        message = ("**%s** a jeté **%dx %s**"):format(xPlayer.getName(), count or 1, itemName)
    else
        message = ("**%s** - **%dx %s**"):format(xPlayer.getName(), count or 1, itemName)
    end
    
    null.logs.send(title, message, logType, meta)
end

--[[
    Log rapide pour les armes
    @param action string - Action (give, remove, drop)
    @param xPlayer table - Joueur
    @param weaponName string - Nom de l'arme
    @param xTarget table - Cible (optionnel)
]]
function null.logs.weapon(action, xPlayer, weaponName, xTarget)
    if not xPlayer or not weaponName then return end
    
    local logType = action .. "-weapon"
    local title = action:gsub("^%l", string.upper) .. " Arme"
    local message = ""
    local meta = null.logs.playerMeta(xPlayer)
    
    if action == "give" and xTarget then
        message = ("**%s** a donné **%s** à **%s**"):format(
            xPlayer.getName(), weaponName, xTarget.getName()
        )
        meta = null.logs.transactionMeta(xPlayer, xTarget)
    elseif action == "remove" then
        message = ("**%s** retiré de **%s**"):format(weaponName, xPlayer.getName())
    elseif action == "drop" then
        message = ("**%s** a jeté **%s**"):format(xPlayer.getName(), weaponName)
    else
        message = ("**%s** - **%s**"):format(xPlayer.getName(), weaponName)
    end
    
    null.logs.send(title, message, logType, meta)
end

--[[
    Log rapide pour l'argent
    @param action string - Action (give, remove, drop, transaction)
    @param xPlayer table - Joueur
    @param accountType string - Type de compte (money, bank, black_money)
    @param amount number - Montant
    @param xTarget table - Cible (optionnel)
]]
function null.logs.money(action, xPlayer, accountType, amount, xTarget)
    if not xPlayer or not amount then return end
    
    local logType = action .. "-account"
    local title = action:gsub("^%l", string.upper) .. " Argent"
    local message = ""
    local meta = null.logs.playerMeta(xPlayer)
    
    local accountLabel = accountType
    if accountType == "money" then accountLabel = "Espèces"
    elseif accountType == "bank" then accountLabel = "Banque"
    elseif accountType == "black_money" then accountLabel = "Argent sale"
    end
    
    if action == "give" and xTarget then
        message = ("**%s** a donné **$%s** (%s) à **%s**"):format(
            xPlayer.getName(), amount, accountLabel, xTarget.getName()
        )
        meta = null.logs.transactionMeta(xPlayer, xTarget)
        logType = "transaction-account"
    elseif action == "remove" then
        message = ("**$%s** (%s) retiré de **%s**"):format(amount, accountLabel, xPlayer.getName())
    elseif action == "add" then
        message = ("**$%s** (%s) ajouté à **%s**"):format(amount, accountLabel, xPlayer.getName())
        logType = "give-account"
    elseif action == "drop" then
        message = ("**%s** a jeté **$%s** (%s)"):format(xPlayer.getName(), amount, accountLabel)
    else
        message = ("**%s** - **$%s** (%s)"):format(xPlayer.getName(), amount, accountLabel)
    end
    
    null.logs.send(title, message, logType, meta)
end

--[[
    Log rapide pour les véhicules
    @param action string - Action (give, remove, spawn, delete)
    @param xPlayer table - Joueur
    @param vehicleName string - Nom du véhicule
    @param plate string - Plaque (optionnel)
]]
function null.logs.vehicle(action, xPlayer, vehicleName, plate)
    if not xPlayer or not vehicleName then return end
    
    local logType = action .. "-vehicle"
    local title = action:gsub("^%l", string.upper) .. " Véhicule"
    local plateText = plate and (" [" .. plate .. "]") or ""
    local message = ""
    local meta = null.logs.playerMeta(xPlayer)
    
    if action == "give" then
        message = ("**%s** a reçu le véhicule **%s**%s"):format(xPlayer.getName(), vehicleName, plateText)
    elseif action == "remove" then
        message = ("Véhicule **%s**%s retiré de **%s**"):format(vehicleName, plateText, xPlayer.getName())
    elseif action == "spawn" then
        message = ("**%s** a spawn **%s**%s"):format(xPlayer.getName(), vehicleName, plateText)
        logType = "car"
    elseif action == "delete" then
        message = ("**%s** a supprimé **%s**%s"):format(xPlayer.getName(), vehicleName, plateText)
        logType = "dv"
    else
        message = ("**%s** - **%s**%s"):format(xPlayer.getName(), vehicleName, plateText)
    end
    
    null.logs.send(title, message, logType, meta)
end

--[[
    Log rapide pour les commandes admin
    @param commandName string - Nom de la commande
    @param xStaff table - Staff qui exécute
    @param xTarget table - Cible (optionnel)
    @param details string - Détails supplémentaires (optionnel)
]]
function null.logs.adminCommand(commandName, xStaff, xTarget, details)
    if not xStaff or not commandName then return end
    
    local message = ("**%s** a utilisé la commande **/%s**"):format(xStaff.getName(), commandName)
    local meta = null.logs.playerMeta(xStaff)
    
    if xTarget then
        message = message .. (" sur **%s**"):format(xTarget.getName())
        meta = null.logs.transactionMeta(xStaff, xTarget)
    end
    
    if details then
        message = message .. ("\n\n**Détails:** %s"):format(details)
    end
    
    null.logs.send("Commande Admin", message, commandName, meta)
end

--[[
    Log rapide pour les jobs
    @param action string - Action (setjob, service-on, service-off)
    @param xPlayer table - Joueur
    @param jobName string - Nom du job
    @param gradeName string - Grade (optionnel)
    @param xStaff table - Staff qui a fait l'action (optionnel)
]]
function null.logs.job(action, xPlayer, jobName, gradeName, xStaff)
    if not xPlayer or not jobName then return end
    
    local logType = action
    local title = ""
    local message = ""
    local meta = null.logs.playerMeta(xPlayer)
    
    if action == "setjob" or action == "setjob2" then
        title = action == "setjob2" and "SetJob2" or "SetJob"
        if xStaff then
            message = ("**%s** a défini le job de **%s** sur **%s** (grade %s)"):format(
                xStaff.getName(), xPlayer.getName(), jobName, gradeName or "N/A"
            )
            meta = null.logs.transactionMeta(xStaff, xPlayer)
        else
            message = ("**%s** a maintenant le job **%s** (grade %s)"):format(
                xPlayer.getName(), jobName, gradeName or "N/A"
            )
        end
    elseif action == "prise-service" then
        title = "Prise de Service"
        message = ("**%s** a pris son service (**%s**)"):format(xPlayer.getName(), jobName)
        logType = "prise-service"
    elseif action == "quitte-service" then
        title = "Fin de Service"
        message = ("**%s** a quitté son service (**%s**)"):format(xPlayer.getName(), jobName)
        logType = "quitte-service"
    end
    
    null.logs.send(title, message, logType, meta)
end
