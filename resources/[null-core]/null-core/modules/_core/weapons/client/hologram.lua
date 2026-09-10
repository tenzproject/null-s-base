-- ============================================================================
-- NullCore — Ammo Hologram (3D DUI hologram_box_model attached to the ped)
--
-- Hold the registered keymap (E by default) to show a 3D holographic ammo
-- display next to the equipped weapon. Releases the key → hides the hologram.
-- ============================================================================

local RESOURCE_NAME        = GetCurrentResourceName()
local HOLOGRAM_URI         = ("nui://%s/modules/_core/weapons/html/hologram.html"):format(RESOURCE_NAME)
local HOLOGRAM_MODEL       = `hologram_box_model`
local HOLOGRAM_TXD         = "hologram_box_model"
local HOLOGRAM_TXN         = "p_hologram_box"

-- ─────────────────────────────────────────────────────────
-- Config tunable (modify to adjust hologram placement/size)
-- ─────────────────────────────────────────────────────────
-- Attached to the weapon prop entity when drawn, falls back to the ped's right hand bone.
-- Offsets are in the attached entity's local space (X=right, Y=forward, Z=up).
local ATTACH_OFFSET        = vec3(0.05, -0.2, 0.07)    -- above + slightly forward from weapon
local ATTACH_ROTATION      = vec3(0.0, 0.0, -90.0)      -- degrees (pitch, roll, yaw)

-- Fallback when weapon entity is not available (uses SKEL_R_Hand bone)
local HAND_OFFSET          = vec3(0.05, 0.02, 0.10)
local HAND_ROTATION        = vec3(0.0, 0.0, 0.0)

-- Initial DUI size; updated from Null3DUI config on ready.
local DUI_WIDTH            = 1024
local DUI_HEIGHT           = 1024
local CURRENT_PACK_MODE    = "basic"
local CURRENT_VARIANT      = "hologram" -- "hologram" | "2d"

-- State
local duiObject            = false
local duiReady             = false
local hologramEntity       = 0
local textureReplaced      = false
local displayEnabled       = false
local lastSentState        = { clip = -1, mag = -1, mags = -1, label = "" }

-- ---------------------------------------------------------------------------
-- DUI helpers
-- ---------------------------------------------------------------------------

local function DuiSend(tbl)
    if duiObject and duiReady then
        SendDuiMessage(duiObject, json.encode(tbl))
        return true
    end
    return false
end

local function InitDui()
    if duiObject then return end
    duiObject = CreateDui(HOLOGRAM_URI, DUI_WIDTH, DUI_HEIGHT)

    -- Wait for JS to signal ready (timeout after 3s)
    local waited = 0
    while not duiReady and waited < 3000 do
        Wait(50)
        waited = waited + 50
    end

    -- Register runtime texture
    local txd = CreateRuntimeTxd("NullAmmoHologramTxd")
    local handle = GetDuiHandle(duiObject)
    CreateRuntimeTextureFromDuiHandle(txd, "NullAmmoHologramTex", handle)

    -- Initial state: hidden
    DuiSend({ display = false, clip = 0, mag = 0, mags = 0, label = "AMMO" })
end

RegisterNUICallback('ammoHologramReady', function(_, cb)
    duiReady = true
    cb({ ok = true })
end)

-- ---------------------------------------------------------------------------
-- Entity handling
-- ---------------------------------------------------------------------------

local function EnsureModelLoaded()
    if not IsModelInCdimage(HOLOGRAM_MODEL) or not IsModelAVehicle(HOLOGRAM_MODEL) then
        return false
    end
    if not HasModelLoaded(HOLOGRAM_MODEL) then
        RequestModel(HOLOGRAM_MODEL)
        local timeout = 0
        while not HasModelLoaded(HOLOGRAM_MODEL) and timeout < 100 do
            Wait(50)
            timeout = timeout + 1
        end
    end
    return HasModelLoaded(HOLOGRAM_MODEL)
end

local function ApplyTextureReplacement()
    -- Always re-apply: the replacement is global for hologram_box_model, so
    -- another 3D UI module may have claimed it. We always re-claim when shown.
    AddReplaceTexture(HOLOGRAM_TXD, HOLOGRAM_TXN, "NullAmmoHologramTxd", "NullAmmoHologramTex")
    textureReplaced = true
end

local function RemoveTextureReplacementAmmo()
    if not textureReplaced then return end
    RemoveReplaceTexture(HOLOGRAM_TXD, HOLOGRAM_TXN)
    textureReplaced = false
end

local function CreateHologramEntity()
    if hologramEntity ~= 0 and DoesEntityExist(hologramEntity) then
        return hologramEntity
    end

    if not EnsureModelLoaded() then
        return 0
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    hologramEntity = CreateVehicle(HOLOGRAM_MODEL, coords.x, coords.y, coords.z, 0.0, false, false)

    SetEntityCollision(hologramEntity, false, false)
    SetVehicleIsConsideredByPlayer(hologramEntity, false)
    SetEntityInvincible(hologramEntity, true)
    SetEntityCompletelyDisableCollision(hologramEntity, false, false)
    SetEntityCanBeDamaged(hologramEntity, false)
    SetEntityAlpha(hologramEntity, 200, false)
    FreezeEntityPosition(hologramEntity, true)
    SetVehicleEngineOn(hologramEntity, true, true, false)
    SetModelAsNoLongerNeeded(HOLOGRAM_MODEL)

    ApplyTextureReplacement()
    return hologramEntity
end

local currentAttachTarget = 0

local function AttachToWeaponOrHand()
    if hologramEntity == 0 or not DoesEntityExist(hologramEntity) then return end
    local ped = PlayerPedId()
    local weaponEntity = GetCurrentPedWeaponEntityIndex(ped)

    -- Prefer attaching directly to the weapon prop (follows it perfectly)
    if weaponEntity and weaponEntity ~= 0 and DoesEntityExist(weaponEntity) then
        if currentAttachTarget == weaponEntity and IsEntityAttachedToEntity(hologramEntity, weaponEntity) then
            return -- already attached to this weapon entity
        end
        DetachEntity(hologramEntity, false, false)
        AttachEntityToEntity(
            hologramEntity, weaponEntity, 0,
            ATTACH_OFFSET.x, ATTACH_OFFSET.y, ATTACH_OFFSET.z,
            ATTACH_ROTATION.x, ATTACH_ROTATION.y, ATTACH_ROTATION.z,
            false, false, false, false, 2, true
        )
        currentAttachTarget = weaponEntity
        return
    end

    -- Fallback: attach to right hand bone
    if currentAttachTarget == ped and IsEntityAttachedToEntity(hologramEntity, ped) then
        return
    end
    DetachEntity(hologramEntity, false, false)
    local bone = GetPedBoneIndex(ped, 28422) -- SKEL_R_Hand
    AttachEntityToEntity(
        hologramEntity, ped, bone,
        HAND_OFFSET.x, HAND_OFFSET.y, HAND_OFFSET.z,
        HAND_ROTATION.x, HAND_ROTATION.y, HAND_ROTATION.z,
        false, false, false, false, 2, true
    )
    currentAttachTarget = ped
end

local function DestroyHologram()
    if hologramEntity ~= 0 and DoesEntityExist(hologramEntity) then
        DetachEntity(hologramEntity, false, false)
        DeleteVehicle(hologramEntity)
    end
    hologramEntity = 0
    currentAttachTarget = 0
    RemoveTextureReplacementAmmo()
end

-- ---------------------------------------------------------------------------
-- Ammo reading
-- ---------------------------------------------------------------------------

local function GetCurrentAmmoInfo()
    local ped = PlayerPedId()
    local weapon = GetSelectedPedWeapon(ped)
    if weapon == `WEAPON_UNARMED` then return nil end

    local weaponData = ESX.GetWeaponHash and ESX.GetWeaponHash(weapon) or nil
    if not weaponData then return nil end

    local ammoType = ESX.GetAmmoType(weaponData.name)
    if not ammoType or ammoType == 'infinite' then return nil end

    local magSize = (Config.MagazineSize and (Config.MagazineSize[ammoType] or Config.MagazineSize['default'])) or 30
    local _, clip = GetAmmoInClip(ped, weapon)

    local magsItem = (Config.AmmoType and Config.AmmoType[ammoType]) or nil
    local magsCount = 0
    if magsItem then
        local item = ESX.GetInventoryItem and ESX.GetInventoryItem(magsItem) or nil
        magsCount = (item and item.count) or 0
    end

    return {
        clip = clip or 0,
        mag = magSize,
        mags = magsCount,
        label = weaponData.label or "AMMO",
    }
end

local function UpdateHologramDisplay(force)
    local info = GetCurrentAmmoInfo()
    if not info then
        if displayEnabled then
            DuiSend({ display = false })
            displayEnabled = false
        end
        return
    end

    if not displayEnabled then
        DuiSend({ display = true })
        displayEnabled = true
    end

    if force
        or info.clip ~= lastSentState.clip
        or info.mag ~= lastSentState.mag
        or info.mags ~= lastSentState.mags
        or info.label ~= lastSentState.label
    then
        DuiSend({
            display = true,
            clip = info.clip,
            mag = info.mag,
            mags = info.mags,
            label = info.label,
        })
        lastSentState.clip = info.clip
        lastSentState.mag = info.mag
        lastSentState.mags = info.mags
        lastSentState.label = info.label
    end
end

-- ---------------------------------------------------------------------------
-- Show / Hide logic
-- ---------------------------------------------------------------------------

local showing = false

local function ShowHologram()
    if showing then return end
    showing = true
    CreateThread(function()
        CreateHologramEntity()
        AttachToWeaponOrHand()
        UpdateHologramDisplay(true)

        while showing do
            -- Re-attach if entity changes (weapon drawn/holstered/swapped)
            if not DoesEntityExist(hologramEntity) then
                CreateHologramEntity()
            end
            AttachToWeaponOrHand()

            UpdateHologramDisplay(false)
            Wait(100)
        end

        -- Hide + cleanup
        if displayEnabled then
            DuiSend({ display = false })
            displayEnabled = false
        end
        DestroyHologram()
        lastSentState.clip = -1
        lastSentState.mag = -1
        lastSentState.mags = -1
        lastSentState.label = ""
    end)
end

local function HideHologram()
    showing = false
end

-- ---------------------------------------------------------------------------
-- Keybind (hold to show)
-- ---------------------------------------------------------------------------

RegisterCommand('+NullAmmoHologram', function()
    -- Block while dead / not loaded / in a vehicle (speedometer uses the same hologram model)
    if not ESX or not ESX.PlayerLoaded then return end
    if PlayerState and PlayerState.isDead then return end
    if IsPedInAnyVehicle(PlayerPedId(), false) then return end
    -- Block entirely when the player selected the 2D ammo HUD variant.
    if CURRENT_VARIANT ~= "hologram" then return end

    -- Only show if holding a weapon with finite ammo
    local info = GetCurrentAmmoInfo()
    if not info then return end

    ShowHologram()
end, false)

RegisterCommand('-NullAmmoHologram', function()
    HideHologram()
end, false)

RegisterKeyMapping('+NullAmmoHologram', 'Afficher les munitions (hologramme)', 'keyboard', 'E')

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------

local function RebuildDui()
    -- Tear down existing DUI if any
    if textureReplaced then
        RemoveReplaceTexture(HOLOGRAM_TXD, HOLOGRAM_TXN)
        textureReplaced = false
    end
    if duiObject then
        DestroyDui(duiObject)
        duiObject = false
    end
    duiReady = false
    InitDui()
    -- Re-apply pack mode
    DuiSend({ packMode = CURRENT_PACK_MODE })
    -- If currently showing, re-apply texture replacement + force resend state
    if showing then
        ApplyTextureReplacement()
        lastSentState.clip = -1
        UpdateHologramDisplay(true)
    end
end

local function ApplyConfig(cfg)
    if not cfg then return end
    local newSize = (Null3DUI and Null3DUI.GetQualitySize(cfg.quality)) or 1024
    local newMode = cfg.packMode or "basic"
    local newVariant = cfg.ammoVariant or "hologram"

    local sizeChanged = (newSize ~= DUI_WIDTH)
    local variantChanged = (newVariant ~= CURRENT_VARIANT)
    DUI_WIDTH  = newSize
    DUI_HEIGHT = newSize
    CURRENT_PACK_MODE = newMode
    CURRENT_VARIANT = newVariant

    -- Switching to 2D while the hologram is currently shown → hide immediately.
    if variantChanged and newVariant == "2d" and showing then
        HideHologram()
    end

    if duiObject and sizeChanged then
        RebuildDui()
    else
        -- Just push pack mode change
        DuiSend({ packMode = CURRENT_PACK_MODE })
    end
end

CreateThread(function()
    -- Wait for player / framework ready
    while not (null and null.fct and null.fct.waitPlayerLoaded) do Wait(250) end
    null.fct.waitPlayerLoaded()
    Wait(2000)

    -- Pull current config before initializing DUI
    if Null3DUI then
        local cfg = Null3DUI.GetConfig()
        DUI_WIDTH = cfg.size
        DUI_HEIGHT = cfg.size
        CURRENT_PACK_MODE = cfg.packMode
        CURRENT_VARIANT = cfg.ammoVariant or "hologram"
    end

    InitDui()
    DuiSend({ packMode = CURRENT_PACK_MODE })

    -- Subscribe to future config changes
    if Null3DUI then
        Null3DUI.Subscribe("ammo_hologram", ApplyConfig)
    end
end)

-- Auto hide when switching to unarmed mid-hold
CreateThread(function()
    while true do
        Wait(500)
        if showing then
            local info = GetCurrentAmmoInfo()
            if not info then
                HideHologram()
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= RESOURCE_NAME then return end
    HideHologram()
    DestroyHologram()
    if textureReplaced then
        RemoveReplaceTexture(HOLOGRAM_TXD, HOLOGRAM_TXN)
        textureReplaced = false
    end
    if duiObject then
        DestroyDui(duiObject)
        duiObject = false
    end
end)
