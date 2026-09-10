-- ============================================================================
-- SHOWCASE — client : écran de bienvenue, tablette showcaser, watermark,
-- protection anti-kill entre joueurs. Gardé par Showcase.IsEnabled().
-- ============================================================================

if not Showcase.IsEnabled() then return end

local cfg = Config.Showcase or {}
local uiFocus = false
 
local function setFocus(state)
    uiFocus = state
    SetNuiFocus(state, state)
end

-- Watermark permanent (rendu côté React).
CreateThread(function()
    Wait(2000)
    SendNUIMessage({
        action = 'showcase:init',
        data = { version = GetResourceMetadata("null-core", 'version', 0), lastUpdate = cfg.lastUpdate or '?' },
    })
end)

-- Écran de bienvenue à chaque connexion (au spawn).
local function openWelcome()
    ESX.TriggerServerCallback('null:showcase:getData', function(data)
        setFocus(true)
        SendNUIMessage({ action = 'showcase:welcome:open', data = data })
    end)
end

AddEventHandler('null:player:spawned', function()
    if not Showcase.IsEnabled() then return end
    Wait(1500)
    openWelcome()
end)

-- Tablette showcaser.
RegisterCommand(cfg.command or 'showcase', function()
    ESX.TriggerServerCallback('null:showcase:getData', function(data)
        setFocus(true)
        SendNUIMessage({ action = 'showcase:tablet:open', data = data })
    end)
end, false)

-- NUI callbacks
RegisterNUICallback('showcase:close', function(_, cb)
    setFocus(false)
    cb('ok')
end)

RegisterNUICallback('showcase:setGroup', function(data, cb)
    if data and data.group then
        TriggerServerEvent('null:showcase:setGroup', data.group)
    end
    cb('ok')
end)

RegisterNUICallback('showcase:wipe', function(_, cb)
    setFocus(false)
    TriggerServerEvent('null:showcase:wipe')
    cb('ok')
end)

RegisterNUICallback('showcase:register', function(_, cb)
    setFocus(false)
    TriggerServerEvent('null:showcase:register')
    cb('ok')
end)

-- Anti-kill : rend les autres joueurs invincibles côté local → personne ne
-- peut blesser/tuer un autre joueur (les PNJ restent normaux).
if cfg.blockPlayerKill then
    CreateThread(function()
        local myPlayer = PlayerId()
        while Showcase.IsEnabled() do
            local me = PlayerPedId()
            for _, pl in ipairs(GetActivePlayers()) do
                if pl ~= myPlayer then
                    local ped = GetPlayerPed(pl)
                    if ped and ped ~= 0 then
                        SetEntityInvincible(ped, true)
                    end
                end
            end
            -- On peut blesser/être blessé par les PNJ mais pas les joueurs.
            SetEntityInvincible(me, false)
            Wait(2000)
        end
    end)
end
