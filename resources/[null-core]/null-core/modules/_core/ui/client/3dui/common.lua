-- ============================================================================
-- Null 3D UI — Shared Config & Event Bus
--
-- Centralizes configuration for 3D holographic UIs (ammo, speedometer, …).
-- Exposes `Null3DUI` global for submodules to register themselves and react
-- to config changes pushed by the HUD Editor.
--
-- Config shape:
--   {
--     packMode = "basic" | "realistic",
--     quality  = "low" | "medium" | "high",
--   }
--
-- Quality → DUI pixel dimensions:
--   low    → 512
--   medium → 1024 (default)
--   high   → 2048
-- ============================================================================

Null3DUI = Null3DUI or {}

local KVP_KEY = "Null_3dui_config"

local DEFAULT_CONFIG = {
    packMode      = "basic",
    quality       = "medium",
    speedVariant  = "hologram", -- "hologram" | "2d"
    ammoVariant   = "hologram", -- "hologram" | "2d"
}

local VALID_VARIANTS = { hologram = true, ["2d"] = true }

local QUALITY_SIZES = {
    low    = 512,
    medium = 1024,
    high   = 2048,
}

local currentConfig = {
    packMode     = DEFAULT_CONFIG.packMode,
    quality      = DEFAULT_CONFIG.quality,
    speedVariant = DEFAULT_CONFIG.speedVariant,
    ammoVariant  = DEFAULT_CONFIG.ammoVariant,
}

-- Subscribers: { [id] = function(config) end }
local subscribers = {}

local function LoadConfig()
    local raw = GetResourceKvpString(KVP_KEY)
    if not raw or raw == "" then return end
    local ok, data = pcall(json.decode, raw)
    if ok and type(data) == "table" then
        if data.packMode == "basic" or data.packMode == "realistic" then
            currentConfig.packMode = data.packMode
        end
        if QUALITY_SIZES[data.quality] then
            currentConfig.quality = data.quality
        end
        if VALID_VARIANTS[data.speedVariant] then
            currentConfig.speedVariant = data.speedVariant
        end
        if VALID_VARIANTS[data.ammoVariant] then
            currentConfig.ammoVariant = data.ammoVariant
        end
    end
end

local function SaveConfig()
    SetResourceKvp(KVP_KEY, json.encode(currentConfig))
end

local function NotifyAll()
    for _, cb in pairs(subscribers) do
        local ok, err = pcall(cb, currentConfig)
        if not ok then
            print("^1[Null3DUI] Subscriber error:", err, "^7")
        end
    end
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

function Null3DUI.GetConfig()
    return {
        packMode     = currentConfig.packMode,
        quality      = currentConfig.quality,
        size         = QUALITY_SIZES[currentConfig.quality] or 1024,
        speedVariant = currentConfig.speedVariant,
        ammoVariant  = currentConfig.ammoVariant,
    }
end

function Null3DUI.GetSpeedVariant() return currentConfig.speedVariant end
function Null3DUI.GetAmmoVariant()  return currentConfig.ammoVariant  end

function Null3DUI.GetQualitySize(quality)
    return QUALITY_SIZES[quality or currentConfig.quality] or 1024
end

function Null3DUI.SetConfig(newConfig)
    if type(newConfig) ~= "table" then return end
    local changed = false
    if newConfig.packMode and newConfig.packMode ~= currentConfig.packMode then
        if newConfig.packMode == "basic" or newConfig.packMode == "realistic" then
            currentConfig.packMode = newConfig.packMode
            changed = true
        end
    end
    if newConfig.quality and newConfig.quality ~= currentConfig.quality then
        if QUALITY_SIZES[newConfig.quality] then
            currentConfig.quality = newConfig.quality
            changed = true
        end
    end
    if newConfig.speedVariant and newConfig.speedVariant ~= currentConfig.speedVariant then
        if VALID_VARIANTS[newConfig.speedVariant] then
            currentConfig.speedVariant = newConfig.speedVariant
            changed = true
        end
    end
    if newConfig.ammoVariant and newConfig.ammoVariant ~= currentConfig.ammoVariant then
        if VALID_VARIANTS[newConfig.ammoVariant] then
            currentConfig.ammoVariant = newConfig.ammoVariant
            changed = true
        end
    end
    if changed then
        SaveConfig()
        NotifyAll()
    end
end

-- Subscribe with a unique id; callback is called immediately with current config.
function Null3DUI.Subscribe(id, callback)
    if type(id) ~= "string" or type(callback) ~= "function" then return end
    subscribers[id] = callback
    callback(currentConfig)
end

function Null3DUI.Unsubscribe(id)
    subscribers[id] = nil
end

-- ---------------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------------

LoadConfig()

-- NUI callback from HUD Editor (ModuleConfigModal → HUDEditor → here)
RegisterNUICallback("set3dUIConfig", function(data, cb)
    if data and data.config then
        Null3DUI.SetConfig(data.config)
    end
    cb("ok")
end)

-- Network event for server-triggered updates (optional)
RegisterNetEvent("null:3dui:setConfig")
AddEventHandler("null:3dui:setConfig", function(config)
    Null3DUI.SetConfig(config)
end)
