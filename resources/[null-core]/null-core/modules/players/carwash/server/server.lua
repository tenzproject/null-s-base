-- ============================================================
--  Carwash — Server
--  Validation, débit, cooldown, notification.
-- ============================================================

local cooldowns = {} -- [identifier] = lastWashTimestamp (ms)

local function now() return GetGameTimer() end

local function notify(src, msg)
    TriggerClientEvent('esx:showNotification', src, msg)
end

-- ---- Callback principal ----------------------------------------
ESX.RegisterServerCallback('null:carwash:wash', function(source, cb, tierName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false, "no_player") end

    local CFG = Config.CarWash
    local tier = CFG.Tiers and CFG.Tiers[tierName]
    if not tier then return cb(false, "no_tier") end

    if tierName == "premium" and not CFG.Settings.AllowPremium then
        notify(source, "~y~La formule Premium est indisponible.")
        return cb(false, "premium_disabled")
    end

    -- Cooldown anti-spam
    local last = cooldowns[xPlayer.identifier]
    local cooldown = (CFG.Settings.Cooldown or 30) * 1000
    if last and (now() - last) < cooldown then
        local rem = math.ceil((cooldown - (now() - last)) / 1000)
        notify(source, ("~y~Patientez ~o~%ds~y~ avant de relaver."):format(rem))
        return cb(false, "cooldown")
    end

    -- Vérification + débit
    local account = CFG.Settings.WashAccount or "bank"
    local money   = xPlayer.getAccount(account).money or 0
    if money < tier.Price then
        notify(source, ("~r~Solde %s insuffisant — il vous faut %d$"):format(
            account == "bank" and "bancaire" or "espèces",
            tier.Price
        ))
        return cb(false, "no_money")
    end

    xPlayer.removeAccountMoney(account, tier.Price, {
        title       = 'Station de Lavage',
        description = tier.Label,
        category    = 'purchase',
    })
    cooldowns[xPlayer.identifier] = now()

    -- On renvoie au client la formule à appliquer.
    cb(true, {
        key         = tierName,
        Label       = tier.Label,
        Price       = tier.Price,
        Duration    = tier.Duration,
        FinalDirt   = tier.FinalDirt,
        CleanDecals = tier.CleanDecals,
    })
end)

-- ---- Compatibilité ascendante ----------------------------------
-- Anciens scripts qui déclenchaient directement `framework:carwash`
-- continuent de fonctionner (formule basique, débit bancaire).
RegisterNetEvent('framework:carwash', function()
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local tier    = Config.CarWash.Tiers.basic
    local account = Config.CarWash.Settings.WashAccount or "bank"

    if xPlayer.getAccount(account).money < tier.Price then
        notify(src, "~r~Solde insuffisant")
        return
    end

    xPlayer.removeAccountMoney(account, tier.Price, {
        title       = 'Station de Lavage',
        description = tier.Label,
        category    = 'purchase',
    })
    notify(src, ("~g~Véhicule lavé — -%d$"):format(tier.Price))
    TriggerClientEvent('framework:cleanvehicle', src)
end)

-- ---- Nettoyage du cooldown au déco -----------------------------
AddEventHandler('playerDropped', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer then cooldowns[xPlayer.identifier] = nil end
end)
