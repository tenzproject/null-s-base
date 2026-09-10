-- ============================================================================
-- Null Help Notification feeder
--
-- Overrides the native ESX.ShowHelpNotification so that the contextual hint
-- (normally rendered by the GTA native BeginTextCommandDisplayHelp chain) is
-- routed through the React <HelpNotification /> component.
--
-- NUI message shape:
--   { type = "helpNotification", visible, message, key }
--
-- The original ESX implementation stays available as ESX.ShowNativeHelp for
-- legacy scripts that really want the vanilla popup.
-- ============================================================================

-- Minimum time between two identical payloads being flushed to the NUI layer.
local HIDE_GRACE_MS = 600

-- Keeps the banner visible while callers keep calling ShowHelpNotification in
-- a tight loop (typical ESX pattern). When no call arrives for HIDE_GRACE_MS,
-- the banner auto-hides.
local lastCallAt   = 0
local lastPayload  = { message = nil, key = nil }
local currentlyShown = false

-- GTA input token → human-readable key mapping. Covers the inputs that are
-- commonly embedded inside ShowHelpNotification strings.
local INPUT_KEY_MAP = {
    INPUT_CONTEXT                         = "E",
    INPUT_CONTEXT_SECONDARY               = "Q",
    INPUT_PICKUP                          = "F",
    INPUT_TALK                            = "N",
    INPUT_DETONATE                        = "G",
    INPUT_RELOAD                          = "R",
    INPUT_JUMP                             = "Space",
    INPUT_SPRINT                          = "Shift",
    INPUT_DUCK                            = "Ctrl",
    INPUT_COVER                           = "Q",
    INPUT_ENTER                           = "F",
    INPUT_MOVE_UP_ONLY                    = "Z",
    INPUT_MOVE_DOWN_ONLY                  = "S",
    INPUT_MOVE_LEFT_ONLY                  = "Q",
    INPUT_MOVE_RIGHT_ONLY                 = "D",
    INPUT_FRONTEND_ACCEPT                 = "Entrée",
    INPUT_FRONTEND_CANCEL                 = "Échap",
    INPUT_FRONTEND_PAUSE                  = "P",
    INPUT_FRONTEND_PAUSE_ALTERNATE        = "Échap",
    INPUT_VEH_HORN                        = "L",
    INPUT_VEH_HEADLIGHT                   = "H",
    INPUT_VEH_DUCK                        = "X",
    INPUT_VEH_HANDBRAKE                   = "Espace",
    INPUT_VEH_ROOF                        = "H",
    INPUT_VEH_EXIT                        = "F",
    INPUT_VEH_FLY_YAW_LEFT                = "Q",
    INPUT_VEH_FLY_YAW_RIGHT               = "E",
    INPUT_VEH_CIN_CAM                     = "R",
    INPUT_NEXT_CAMERA                     = "V",
    INPUT_SELECT_NEXT_WEAPON              = "Mol. ↑",
    INPUT_SELECT_PREV_WEAPON              = "Mol. ↓",
    INPUT_AIM                             = "Clic D.",
    INPUT_ATTACK                          = "Clic G.",
    INPUT_MELEE_ATTACK1                   = "R",
    INPUT_PARACHUTE_DEPLOY                = "F",
    INPUT_OPEN_INTERACTION_MENU           = "M",
    INPUT_MP_TEXT_CHAT_ALL                = "T",
}

--- Extract the first ~INPUT_*~ token found in the message, if any.
---@param msg string
---@return string|nil key, string cleaned
local function ExtractKey(msg)
    local token = msg:match("~INPUT_([A-Z0-9_]+)~")
    if not token then return nil, msg end
    return INPUT_KEY_MAP["INPUT_" .. token], msg
end

--- Strip unused formatting tokens. Color tokens (~r~, ~g~, …) are preserved so
--- the React side can render them as colored spans.
local function CleanForReact(msg)
    -- Remove ~INPUT_*~ (already resolved into a key badge).
    msg = msg:gsub("~INPUT_[A-Z0-9_]+~", "")
    -- Trim leading/trailing whitespace.
    msg = msg:gsub("^%s+", ""):gsub("%s+$", "")
    return msg
end

local function Flush(payload)
    if currentlyShown
       and payload.message == lastPayload.message
       and payload.key     == lastPayload.key then
        return
    end
    lastPayload.message = payload.message
    lastPayload.key     = payload.key
    currentlyShown      = true
    SendNUIMessage({
        type    = "helpNotification",
        visible = true,
        message = payload.message,
        key     = payload.key,
    })
end

local function Hide()
    if not currentlyShown then return end
    currentlyShown      = false
    lastPayload.message = nil
    lastPayload.key     = nil
    SendNUIMessage({
        type    = "helpNotification",
        visible = false,
    })
end

-- ──────────────────────────────────────────────────────────────────────────
-- Public overrides
-- ──────────────────────────────────────────────────────────────────────────

-- Preserve the original implementation for callers that want it.
if ESX and ESX.ShowHelpNotification and not ESX.ShowNativeHelp then
    ESX.ShowNativeHelp = ESX.ShowHelpNotification
end

--- Replacement for ESX.ShowHelpNotification.
--- @param msg string    Message to show. May contain ~INPUT_*~ and ~color~ tokens.
--- @param key string?   (Optional) Explicit key label to show in the badge.
local function ShowHelp(msg, key)
    if type(msg) ~= "string" or msg == "" then return end

    local extractedKey
    if not key then
        extractedKey = ExtractKey(msg)
    end

    local payload = {
        message = CleanForReact(msg),
        key     = key or extractedKey,
    }

    lastCallAt = GetGameTimer()
    Flush(payload)
end

if ESX then
    ESX.ShowHelpNotification = ShowHelp
end

-- Expose a null helper and a native export so other resources can use the
-- new UI without depending on ESX.
null = null or {}
null.ShowHelpNotification = ShowHelp
null.HideHelpNotification = Hide
exports("ShowHelpNotification", ShowHelp)
exports("HideHelpNotification", Hide)

-- ──────────────────────────────────────────────────────────────────────────
-- Auto-hide watchdog
-- ──────────────────────────────────────────────────────────────────────────
CreateThread(function()
    while true do
        if currentlyShown and (GetGameTimer() - lastCallAt) > HIDE_GRACE_MS then
            Hide()
        end
        Wait(150)
    end
end)

if null and null.InitPrint then
    null.InitPrint("Help Notification HUD Loaded successfully")
end
