--[[
    Metabolism — Client (simplifié)
    --------------------------------
    Reçoit : score (0-100), hydration, fitness, bodyweight (caché), effects.
    Applique sprint, stamina, regen PV basés uniquement sur le score.
    Pousse score vers le NUI (inventaire) pour afficher la barre "Forme".
]]

if not Config.Metabolism or not Config.Metabolism.Enabled then return end


local MetaState = nil

-- ============================================================
-- Effets gameplay basés sur le score
-- ============================================================
local SPRINT_CAP   = 1.49
local HP_MAX       = 200
local HP_REGEN_MIN = 180

local function applyEffects()
    if not MetaState then return end
    local score = MetaState.score or 0
    local t     = score / 100
    local fx    = MetaState.effects or Config.Metabolism.Effects

    -- Sprint ± 10%
    local spFx  = fx.sprint  or { min = 0.90, max = 1.10 }
    local stFx  = fx.stamina or { min = 60.0, max = 100.0 }
    local rgFx  = fx.regen   or { min = 0.0,  max = 1.0  }

    -- Influence discrète du poids caché sur le sprint (-0.003/kg au-dessus du neutre)
    local bw      = MetaState.bodyweight or (MetaState.neutralBW or 75)
    local neutral = MetaState.neutralBW  or 75
    local bwPenalty = math.max(0, (bw - neutral) * 0.003)

    local sprintMul = math.min(SPRINT_CAP, math.max(0.5,
        spFx.min + t * (spFx.max - spFx.min) - bwPenalty
    ))
    local stamina   = stFx.min + t * (stFx.max - stFx.min)
    local regen     = rgFx.min + t * (rgFx.max - rgFx.min)

    SetPlayerSprintSpeedMultiplier(PlayerId(), sprintMul)
    StatSetInt(GetHashKey("MP0_STAMINA"), math.floor(stamina), true)

    if regen > 0.05 then
        local ped = PlayerPedId()
        local hp  = GetEntityHealth(ped)
        if hp > HP_REGEN_MIN and hp < HP_MAX then
            SetEntityHealth(ped, math.min(HP_MAX, math.floor(hp + regen)))
        end
    end
end

-- Thread unique d'effets (1/s)
CreateThread(function()
    while true do
        Wait(1000)
        if MetaState then applyEffects() end
    end
end)

-- ============================================================
-- Sync depuis le serveur
-- ============================================================
RegisterNetEvent('null:metabolism:sync')
AddEventHandler('null:metabolism:sync', function(payload)
    MetaState = payload
    SendNUIMessage({ type = "newInventory:setMetabolism", data = payload })
end)

AddEventHandler('esx:playerLoaded', function()
    TriggerServerEvent('null:metabolism:request')
end)

RegisterNUICallback('metabolism:request', function(_, cb)
    TriggerServerEvent('null:metabolism:request')
    cb('ok')
end)

RegisterNUICallback('metabolism:requestSync', function(_, cb)
    TriggerServerEvent('null:metabolism:request')
    cb('ok')
end)

-- ============================================================
-- Export
-- ============================================================
exports('GetMetabolism', function() return MetaState end)
