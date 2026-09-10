-- ============================================================================
-- SERVER : Missions tablet illégal
-- ============================================================================

-- ─────────────────────────────────────────────
-- FOURGON
-- ─────────────────────────────────────────────

local FOURGON_ROUTES  = 3
local FOURGON_MIN     = 60000
local FOURGON_MAX     = 90000
local FOURGON_XP      = 400
local FOURGON_COOLDOWN = 20 * 60  -- 20 minutes en secondes

local cooldowns = {}

RegisterNetEvent('null:missions:fourgon:start')
AddEventHandler('null:missions:fourgon:start', function()
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local job2 = xPlayer.getJob2()
    if not job2 or job2.name == 'unemployed2' or job2.name == 'unemployed' then
        TriggerClientEvent('esx:showNotification', src, "Tu dois appartenir à un crew pour lancer cette mission.")
        return
    end

    local gang = job2.name
    local now  = os.time()

    if cooldowns[gang] and now < cooldowns[gang] then
        local rem = math.ceil((cooldowns[gang] - now) / 60)
        TriggerClientEvent('esx:showNotification', src, "Mission indisponible — disponible dans " .. rem .. " min.")
        return
    end

    cooldowns[gang] = now + FOURGON_COOLDOWN

    TriggerClientEvent('null:missions:fourgon:init', src, {
        gangName   = gang,
        routeIndex = math.random(1, FOURGON_ROUTES),
    })
end)

RegisterNetEvent('null:missions:fourgon:complete')
AddEventHandler('null:missions:fourgon:complete', function(gangName)
    local src     = source
    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    local job2 = xPlayer.getJob2()
    if not job2 or job2.name ~= gangName then return end

    -- Récompense argent sale
    local reward = math.random(FOURGON_MIN, FOURGON_MAX)
    xPlayer.addAccountMoney('dirtycash', reward)
    TriggerClientEvent('esx:showNotification', src, "+" .. reward .. "$ d'argent sale.")

    -- XP crew
    if not (SaveData and SaveData.gangs and SaveData.gangs[gangName]) then return end

    local gang   = SaveData.gangs[gangName]
    local cfg    = Config.IllegalTablet
    local xp     = (gang.xp or 0) + FOURGON_XP
    local lvl    = gang.level or 1
    local needed = math.floor(cfg.XP.BaseXP * (lvl ^ cfg.XP.Exponent))

    while xp >= needed and lvl < cfg.XP.MaxLevel do
        xp     = xp - needed
        lvl    = lvl + 1
        needed = math.floor(cfg.XP.BaseXP * (lvl ^ cfg.XP.Exponent))
        TriggerClientEvent('esx:showNotification', -1,
            "Crew " .. (gang.label or gangName) .. " — Niveau " .. lvl .. " atteint.")
    end

    gang.xp    = xp
    gang.level = lvl

    MySQL.Async.execute(
        "UPDATE `vgangs` SET `xp`=@x, `level`=@l WHERE `gangname`=@n",
        { ['@x'] = xp, ['@l'] = lvl, ['@n'] = gangName }
    )

    TriggerClientEvent('esx:showNotification', src, "+" .. FOURGON_XP .. " XP pour le crew.")
end)
