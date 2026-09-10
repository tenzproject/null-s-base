-- ============================================================================
-- Null 2D Ammo HUD feeder
--
-- Pushes ammo status to the React <AmmoHud /> component via NUI messages when
-- the player selected the "2d" ammo variant in the HUD Editor.
-- NUI message shape:
--   { type = "ammoStatus", visible, clip, mag, mags, label }
-- ============================================================================

local POLL_MS_ACTIVE   = 150
local POLL_MS_IDLE     = 500

local currentVariant   = "hologram"
local lastSent         = { visible = nil, clip = -1, mag = -1, mags = -1, label = "" }

local function SendStatus(payload)
    -- Only re-send when something actually changed (cuts NUI chatter).
    if payload.visible == lastSent.visible
       and payload.clip    == lastSent.clip
       and payload.mag     == lastSent.mag
       and payload.mags    == lastSent.mags
       and payload.label   == lastSent.label then
        return
    end
    lastSent.visible = payload.visible
    lastSent.clip    = payload.clip
    lastSent.mag     = payload.mag
    lastSent.mags    = payload.mags
    lastSent.label   = payload.label
    SendNUIMessage({
        type = "ammoStatus",
        visible = payload.visible,
        clip    = payload.clip,
        mag     = payload.mag,
        mags    = payload.mags,
        label   = payload.label,
    })
end

local function ReadAmmoInfo()
    if not ESX or not ESX.PlayerLoaded then return nil end
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    if weapon == `WEAPON_UNARMED` then return nil end

    if PlayerState.isInVehicle then return nil end

    local weaponData = ESX.GetWeaponHash and ESX.GetWeaponHash(weapon) or nil
    if not weaponData then return nil end

    local ammoType = ESX.GetAmmoType(weaponData.name)
    if not ammoType or ammoType == 'infinite' then return nil end

    local magSize = (Config and Config.MagazineSize
                     and (Config.MagazineSize[ammoType] or Config.MagazineSize['default'])) or 30
    local _, clip = GetAmmoInClip(ped, weapon)

    local magsItem  = (Config and Config.AmmoType and Config.AmmoType[ammoType]) or nil
    local magsCount = 0
    if magsItem and ESX.GetInventoryItem then
        local item = ESX.GetInventoryItem(magsItem)
        magsCount = (item and item.count) or 0
    end

    return {
        clip  = clip or 0,
        mag   = magSize,
        mags  = magsCount,
        label = weaponData.label or "AMMO",
    }
end

CreateThread(function()
    while not (null and null.fct and null.fct.waitPlayerLoaded) do Wait(250) end
    null.fct.waitPlayerLoaded()
    Wait(2000)

    if Null3DUI then
        currentVariant = Null3DUI.GetAmmoVariant() or "hologram"
        Null3DUI.Subscribe("ammo_hud_2d", function(cfg)
            currentVariant = (cfg and cfg.ammoVariant) or "hologram"
            if currentVariant ~= "2d" then
                -- Ensure the React component hides immediately.
                SendStatus({ visible = false, clip = 0, mag = 0, mags = 0, label = "" })
            end
        end)
    end

    while true do
        if currentVariant == "2d" then
            local info = ReadAmmoInfo()
            if info then
                SendStatus({
                    visible = true,
                    clip    = info.clip,
                    mag     = info.mag,
                    mags    = info.mags,
                    label   = info.label,
                })
                Wait(POLL_MS_ACTIVE)
            else
                SendStatus({ visible = false, clip = 0, mag = 0, mags = 0, label = "" })
                Wait(POLL_MS_IDLE)
            end
        else
            Wait(1000)
        end
    end
end)
