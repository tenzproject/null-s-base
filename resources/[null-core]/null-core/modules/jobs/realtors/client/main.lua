-- ================================================================
-- Null REALTORS — Client (Boss PC + Employee tablet)
-- ================================================================

local CFG = Config and Config.Realtors
if not CFG then
    print("^1[REALTOR][CLIENT] Config.Realtors introuvable — vérifier configs/modules/jobs/realtors/shared/config.lua^0")
    return
end
print("^2[REALTOR][CLIENT] Module agence chargé (job="..tostring(CFG.JobName)..")^0")

local tabletOpen   = false
local lastDashboard = nil

-- ----------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------
local function isJob()
    return ESX and ESX.PlayerData and ESX.PlayerData.job and ESX.PlayerData.job.name == CFG.JobName
end

local function isBoss()
    return isJob() and ESX.PlayerData.job.grade >= CFG.BossGrade
end

-- ----------------------------------------------------------------
-- NUI bridge
-- ----------------------------------------------------------------
local function sendData(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function feedback(msg, type)
    sendData("realtor:feedback", { message = msg, type = type or "error" })
end

local function fetchDashboard(callback)
    ESX.TriggerServerCallback("realtor:getDashboard", function(data)
        lastDashboard = data
        if callback then callback(data) end
    end)
end

function openTabletRelator(mode, bypassChecks)
    if tabletOpen then return end
    if mode == nil then 
        mode = isBoss() and "boss" or "employee"
    end
    if not bypassChecks then
        if not isJob() then
            ESX.ShowNotification("~r~Vous n'êtes pas employé de l'agence")
            return
        end
        if mode == "boss" and not isBoss() then
            ESX.ShowNotification("~r~Réservé au patron")
            return
        end
    end

    fetchDashboard(function(data)
        if not data then
            ESX.ShowNotification("~r~Erreur de chargement (callback nil)")
            print("[REALTOR] fetchDashboard a retourné nil — joueur non autorisé côté server")
            return
        end
        tabletOpen = true
        SetNuiFocus(true, true)
        sendData("realtor:open", { mode = mode, dashboard = data })
        print(("[REALTOR] Tablette ouverte : mode=%s, listings=%d, owned=%d"):format(
            data.mode or '?', #(data.listings or {}), #(data.owned or {})))
    end)
end

local function closeTablet()
    if not tabletOpen then return end
    tabletOpen = false
    SetNuiFocus(false, false)
    sendData("realtor:close", {})
end

-- ----------------------------------------------------------------
-- NUI callbacks (UI React → client → server)
-- ----------------------------------------------------------------
RegisterNUICallback("realtor:close", function(_, cb)
    closeTablet()
    cb("ok")
end)

RegisterNUICallback("realtor:refresh", function(_, cb)
    fetchDashboard(function(data) sendData("realtor:dataUpdate", data) end)
    cb("ok")
end)

RegisterNUICallback("realtor:buy", function(data, cb)
    TriggerServerEvent("realtor:buyListing", data.listingId)
    cb("ok")
end)

RegisterNUICallback("realtor:updateSettings", function(data, cb)
    TriggerServerEvent("realtor:updatePropertySettings", data.propName, {
        mode      = data.mode,
        salePrice = tonumber(data.salePrice),
        rentPrice = tonumber(data.rentPrice),
    })
    cb("ok")
end)

local DEPOSIT_REASON = {
    unauth         = "Action non autorisée",
    badamount      = "Montant invalide",
    nomoney        = "Vous n'avez pas assez d'argent en liquide",
    societynomoney = "Le coffre n'a pas assez d'argent",
    error          = "Erreur",
}

RegisterNUICallback("realtor:deposit", function(data, cb)
    local amount = tonumber(data and data.amount) or 0
    ESX.TriggerServerCallback("realtor:deposit", function(success, reason)
        if success then
            ESX.ShowNotification(("~g~+%s$ déposés au coffre"):format(ESX.Math.GroupDigits(amount)))
            feedback("Dépôt effectué", "success")
            fetchDashboard(function(d) sendData("realtor:dataUpdate", d) end)
        else
            feedback(DEPOSIT_REASON[reason] or "Erreur", "error")
        end
        cb({ success = success and true or false })
    end, amount)
end)

RegisterNUICallback("realtor:withdraw", function(data, cb)
    local amount = tonumber(data and data.amount) or 0
    ESX.TriggerServerCallback("realtor:withdraw", function(success, reason)
        if success then
            ESX.ShowNotification(("~g~%s$ retirés du coffre"):format(ESX.Math.GroupDigits(amount)))
            feedback("Retrait effectué", "success")
            fetchDashboard(function(d) sendData("realtor:dataUpdate", d) end)
        else
            feedback(DEPOSIT_REASON[reason] or "Erreur", "error")
        end
        cb({ success = success and true or false })
    end, amount)
end)

RegisterNUICallback("realtor:setWaypoint", function(data, cb)
    if data and data.x and data.y then
        SetNewWaypoint(data.x + 0.0, data.y + 0.0)
        ESX.ShowNotification("~b~GPS défini")
    end
    cb("ok")
end)

-- ----------------------------------------------------------------
-- Vente / Location au joueur le plus proche
-- ----------------------------------------------------------------
local function getNearestPlayerServerId()
    local closest, dist = ESX.Game.GetClosestPlayer()
    if closest == -1 or dist > 5.0 then return nil end
    return GetPlayerServerId(closest)
end

local SELL_REASON = {
    nomoney        = "L'acheteur n'a pas assez d'argent",
    refused        = "L'acheteur a refusé",
    timeout        = "Pas de réponse de l'acheteur",
    disconnected   = "L'acheteur s'est déconnecté",
    unavailable    = "Bien indisponible",
    wrongmode      = "Ce bien n'est pas configuré pour ce mode",
    farfromdoor    = "Vous devez être proche de la porte du bien",
    baddays        = "Durée de location invalide",
    badrent        = "Loyer non défini",
    alreadyrented  = "Ce bien est déjà loué",
    warehousenorent = "Un entrepôt ne peut pas être loué",
    error          = "Erreur",
}

RegisterNUICallback("realtor:sellToPlayer", function(data, cb)
    local target = getNearestPlayerServerId()
    if not target then feedback("Aucun joueur à proximité"); cb("ok"); return end

    closeTablet()
    ESX.TriggerServerCallback("realtor:sellToPlayer", function(success, reason)
        if success then
            ESX.ShowNotification("~g~Vente conclue")
        else
            ESX.ShowNotification("~r~"..(SELL_REASON[reason] or reason or "Erreur"))
        end
    end, data.propName, target)
    cb("ok")
end)

RegisterNUICallback("realtor:rentToPlayer", function(data, cb)
    local target = getNearestPlayerServerId()
    if not target then feedback("Aucun joueur à proximité"); cb("ok"); return end

    closeTablet()
    ESX.TriggerServerCallback("realtor:rentToPlayer", function(success, reason)
        if success then
            ESX.ShowNotification("~g~Location conclue")
        else
            ESX.ShowNotification("~r~"..(SELL_REASON[reason] or reason or "Erreur"))
        end
    end, data.propName, target, tonumber(data.days) or 7)
    cb("ok")
end)

-- Demande de paiement reçue par l'acheteur
RegisterNetEvent("realtor:billingDemande", function(billId, amount, label)
    ESX.ShowAccept(
        ("~b~Agence Immobilière~s~\n%s\nMontant : ~g~%s$~s~\nAcceptez-vous ?"):format(
            label or "Bien immobilier", ESX.Math.GroupDigits(amount)),
        function(result)
            TriggerServerEvent("realtor:billingReponse", billId, result)
        end
    )
end)

-- ----------------------------------------------------------------
-- Server → client refresh
-- ----------------------------------------------------------------
RegisterNetEvent("realtor:dashboardDirty", function()
    if tabletOpen then
        fetchDashboard(function(data) sendData("realtor:dataUpdate", data) end)
    end
end)

-- ----------------------------------------------------------------
-- Commandes debug : ouvrent la tablette sans aucune permission
-- ----------------------------------------------------------------
local function debugOpen(mode)
    print(("[REALTOR] /%s — demande grant debug..."):format(
        mode == 'boss' and 'realtorDebugBoss' or 'realtorDebugEmployee'))
    ESX.TriggerServerCallback('realtor:grantDebug', function(ok)
        print(("[REALTOR] Grant reçu : %s"):format(tostring(ok)))
        if not ok then
            ESX.ShowNotification("~r~Echec du grant debug")
            return
        end
        openTablet(mode, true)
    end, mode)
end

RegisterCommand('realtorDebugBoss',     function() debugOpen('boss')     end, false)
RegisterCommand('realtorDebugEmployee', function() debugOpen('employee') end, false)
TriggerEvent('chat:addSuggestion', '/realtorDebugBoss',     'Ouvre la tablette agence en mode patron (debug)')
TriggerEvent('chat:addSuggestion', '/realtorDebugEmployee', 'Ouvre la tablette agence en mode employé (debug)')

-- ----------------------------------------------------------------
-- Markers : PC du boss
-- ----------------------------------------------------------------
CreateThread(function()
    null.fct.waitPlayerLoaded()

    -- Blip agence
    if CFG.Blip then
        ESX.addBlips({
            name     = "realtor_agency",
            label    = CFG.Blip.label,
            position = CFG.Blip.position,
            sprite   = CFG.Blip.sprite,
            color    = CFG.Blip.color,
            scale    = CFG.Blip.scale,
            display  = 4,
            type     = 11,
        })
    end

    -- Marker PC boss
    null.data.markers.register("realtor_boss_pc", {
        Position = vector3(CFG.Positions.BossPC.x, CFG.Positions.BossPC.y, CFG.Positions.BossPC.z),
        Public   = false,
        Job      = CFG.JobName,
        Action   = function() openTablet("boss") end,
    })
end)

-- ----------------------------------------------------------------
-- Commande employé pour ouvrir la tablette
-- ----------------------------------------------------------------
-- RegisterCommand(CFG.EmployeeCommand, function()
--     if not isJob() then
--         ESX.ShowNotification("~r~Vous n'êtes pas employé de l'agence")
--         return
--     end
--     openTablet(isBoss() and "boss" or "employee")
-- end, false)

-- ----------------------------------------------------------------
-- NUI callbacks construction
-- ----------------------------------------------------------------
local CONSTRUCT_REASON = {
    not_employee     = "Vous n'êtes pas employé de l'agence",
    no_target        = "Aucun client à proximité (< 5m)",
    nomoney          = "Le client n'a pas assez d'argent",
    refused          = "Le client a refusé",
    timeout          = "Pas de réponse du client",
    disconnected     = "Le client s'est déconnecté",
    unknown_type     = "Type de bien inconnu",
    disabled         = "La construction est désactivée",
    error            = "Erreur serveur",
}

RegisterNUICallback("realtor:construct", function(data, cb)
    local target = getNearestPlayerServerId()
    if not target then
        feedback("Aucun client à proximité (< 5m)")
        cb("ok")
        return
    end

    local coords = GetEntityCoords(PlayerPedId())
    closeTablet()

    ESX.TriggerServerCallback("realtor:construct", function(success, reason)
        if success then
            ESX.ShowNotification("~g~Construction lancée avec succès !")
        else
            ESX.ShowNotification("~r~" .. (CONSTRUCT_REASON[reason] or reason or "Erreur"))
        end
    end, {
        interiorType = data.interiorType,
        targetId     = target,
        x = coords.x, y = coords.y, z = coords.z,
    })
    cb("ok")
end)

-- ----------------------------------------------------------------
-- Echap → close
-- ----------------------------------------------------------------
CreateThread(function()
    while true do
        if tabletOpen then
            Wait(0)
            if IsControlJustPressed(0, 322) then  -- ESC
                closeTablet()
            end
        else
            Wait(500)
        end
    end
end)

-- ----------------------------------------------------------------
-- F6 → ouvrir la tablette employé
-- ----------------------------------------------------------------
-- if CFG.EmployeeKey and CFG.EmployeeKey ~= 0 then
--     CreateThread(function()
--         null.fct.waitPlayerLoaded()
--         while true do
--             Wait(0)
--             if not tabletOpen and IsControlJustPressed(0, CFG.EmployeeKey) then
--                 if isJob() then
--                     openTablet(isBoss() and "boss" or "employee")
--                 end
--             end
--         end
--     end)
-- end
