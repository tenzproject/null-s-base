-- ============================================================================
-- Null 3D Speedometer (minimal) — hologram_box_model attached to the vehicle
-- Shows speed / gear / rpm on a holographic display above the dashboard.
--
-- Pack mode + quality come from Null3DUI shared config (HUD Editor).
-- Shares the hologram_box_model with the ammo hologram; since speed is only
-- shown while driving and ammo only on foot, they don't overlap in practice.
-- ============================================================================

local RESOURCE_NAME        = GetCurrentResourceName()
local DUI_URI              = ("nui://%s/modules/_core/ui/html/3dui-speed/index.html"):format(RESOURCE_NAME)
local HOLOGRAM_MODEL       = `hologram_box_model`
local HOLOGRAM_TXD         = "hologram_box_model"
local HOLOGRAM_TXN         = "p_hologram_box"

-- Attachment relative to vehicle chassis bone (hologramspeed defaults)
-- X = right of chassis center, Y = forward, Z = up
-- Per-class overrides: GetVehicleClass returns 0..22
--   0 Compacts, 1 Sedans, 2 SUVs, 3 Coupes, 4 Muscle, 5 SportsClassics, 6 Sports,
--   7 Super, 8 Motorcycles, 9 OffRoad, 10 Industrial, 11 Utility, 12 Vans,
--   13 Cycles, 14 Boats, 15 Helicopters, 16 Planes, 17 Service, 18 Emergency,
--   19 Military, 20 Commercial, 21 Trains, 22 OpenWheel
local DEFAULT_OFFSET       = vec3(1.3, -1.0, 0.85)
local DEFAULT_ROTATION     = vec3(0.0, 0.0, -15.0)

local CLASS_OFFSETS = {
    -- Two-wheelers: very narrow, keep close to handlebar
    [8]  = { offset = vec3(0.5, 0.25, 0.85), rotation = vec3(0.0, 0.0, -10.0) }, -- Motorcycles
    [13] = { offset = vec3(0.5, 0.20, 0.85), rotation = vec3(0.0, 0.0, -10.0) }, -- Cycles
    -- Tall/wide vehicles: push out a bit so hologram clears the dashboard
    [10] = { offset = vec3(1.3, -0.6, 1.10), rotation = vec3(0.0, 0.0, -15.0) }, -- Industrial
    [11] = { offset = vec3(1.2, -0.8, 1.00), rotation = vec3(0.0, 0.0, -15.0) }, -- Utility
    [12] = { offset = vec3(1.2, -0.6, 1.05), rotation = vec3(0.0, 0.0, -15.0) }, -- Vans
    [20] = { offset = vec3(1.3, -0.6, 1.10), rotation = vec3(0.0, 0.0, -15.0) }, -- Commercial
    -- Boats: driver usually at rear, lift hologram higher
    [14] = { offset = vec3(0.9, -0.4, 0.95), rotation = vec3(0.0, 0.0, -15.0) }, -- Boats
    -- Air: mount close to collective / yoke
    [15] = { offset = vec3(0.8, -0.6, 0.60), rotation = vec3(0.0, 0.0, -10.0) }, -- Helicopters
    [16] = { offset = vec3(0.8, -0.8, 0.55), rotation = vec3(0.0, 0.0, -10.0) }, -- Planes
    -- Open-wheel: compact cockpit
    [22] = { offset = vec3(0.7, -0.6, 0.70), rotation = vec3(0.0, 0.0, -12.0) }, -- OpenWheel
}

local function GetAttachForVehicle(vehicle)
    local class = GetVehicleClass(vehicle)
    local entry = CLASS_OFFSETS[class]
    if entry then return entry.offset, entry.rotation end
    return DEFAULT_OFFSET, DEFAULT_ROTATION
end

-- State
local DUI_WIDTH            = 1024
local DUI_HEIGHT           = 1024
local CURRENT_PACK_MODE    = "basic"
local CURRENT_VARIANT      = "hologram" -- "hologram" | "2d"
local duiObject            = false
local duiReady             = false
local hologramEntity       = 0
local textureReplaced      = false
local running              = false
local currentVehicle       = 0

-- ---------------------------------------------------------------------------
-- DUI
-- ---------------------------------------------------------------------------

local function SendScAction(action, data)
    SendDuiMessage(duiObject, json.encode({
        action = action,
        data = data
    }))
end

local function DuiSend(tbl)
    if duiObject and duiReady then
        if type(tbl.display) == "boolean" then
            SendScAction("setVisible", tbl.display)
        end

        if type(tbl.speed) == "number" then
            SendScAction("setSpeed", math.floor(tbl.speed))
        end

        if type(tbl.fuel) == "number" then
            SendScAction("setFuel", tbl.fuel)
        end

        if type(tbl.engine) == "boolean" or type(tbl.headlight) == "boolean" then
            SendScAction("setIcons", {
                engine = tbl.engine == true,
                headlight = tbl.headlight == true
            })
        end

        return true
    end
    return false
end

local function InitDui()
    if duiObject then return end
    --print(("^3[Null3DSpeed] InitDui — size=%d uri=%s^7"):format(DUI_WIDTH, DUI_URI))
    duiObject = CreateDui(DUI_URI, DUI_WIDTH, DUI_HEIGHT)
    duiReady = true
    --print(("^3[Null3DSpeed] DUI ready after %dms (duiReady=%s)^7"):format(waited, tostring(duiReady)))
    local txd = CreateRuntimeTxd("NullSpeedHologramTxd")
    local handle = GetDuiHandle(duiObject)
    CreateRuntimeTextureFromDuiHandle(txd, "NullSpeedHologramTex", handle)
    DuiSend({ display = false, speed = 0, rpm = 0, gear = 1, unit = "KMH", packMode = CURRENT_PACK_MODE })
end

RegisterNUICallback("speedHologramReady", function(_, cb)
    duiReady = true
    --print("^2[Null3DSpeed] JS signalled ready (speedHologramReady)^7")
    cb({ ok = true })
end)

-- ---------------------------------------------------------------------------
-- Entity
-- ---------------------------------------------------------------------------

local function EnsureModelLoaded()
    if not IsModelInCdimage(HOLOGRAM_MODEL) or not IsModelAVehicle(HOLOGRAM_MODEL) then return false end
    if not HasModelLoaded(HOLOGRAM_MODEL) then
        RequestModel(HOLOGRAM_MODEL)
        local timeout = 0
        while not HasModelLoaded(HOLOGRAM_MODEL) and timeout < 100 do
            Wait(50); timeout = timeout + 1
        end
    end
    return HasModelLoaded(HOLOGRAM_MODEL)
end

local function ApplyTextureReplacement()
    -- Global resource: re-claim each call so ammo/other 3D UIs don't steal us.
    AddReplaceTexture(HOLOGRAM_TXD, HOLOGRAM_TXN, "NullSpeedHologramTxd", "NullSpeedHologramTex")
    textureReplaced = true
end

local function RemoveTextureReplacement()
    if not textureReplaced then return end
    RemoveReplaceTexture(HOLOGRAM_TXD, HOLOGRAM_TXN)
    textureReplaced = false
end

local function CreateHologramEntity(vehicle)
    if hologramEntity ~= 0 and DoesEntityExist(hologramEntity) then return hologramEntity end
    if not EnsureModelLoaded() then return 0 end
    local coords = GetEntityCoords(vehicle)
    hologramEntity = CreateVehicle(HOLOGRAM_MODEL, coords.x, coords.y, coords.z, 0.0, false, false)
    SetEntityCollision(hologramEntity, false, false)
    SetVehicleIsConsideredByPlayer(hologramEntity, false)
    SetEntityInvincible(hologramEntity, true)
    SetEntityAlpha(hologramEntity, 200, false)
    FreezeEntityPosition(hologramEntity, true)
    SetVehicleEngineOn(hologramEntity, true, true, false)
    SetModelAsNoLongerNeeded(HOLOGRAM_MODEL)
    ApplyTextureReplacement()
    return hologramEntity
end

local function AttachToVehicle(vehicle)
    if hologramEntity == 0 or not DoesEntityExist(hologramEntity) then return end
    local bone = GetEntityBoneIndexByName(vehicle, "chassis")
    local off, rot = GetAttachForVehicle(vehicle)
    AttachEntityToEntity(
        hologramEntity, vehicle, bone,
        off.x, off.y, off.z,
        rot.x, rot.y, rot.z,
        false, false, false, false, 2, true
    )
end

local function DestroyHologram()
    if hologramEntity ~= 0 and DoesEntityExist(hologramEntity) then
        DetachEntity(hologramEntity, false, false)
        DeleteVehicle(hologramEntity)
    end
    hologramEntity = 0
    RemoveTextureReplacement()
end

-- ---------------------------------------------------------------------------
-- Config updates
-- ---------------------------------------------------------------------------

local function RebuildDui()
    RemoveTextureReplacement()
    if duiObject then
        DestroyDui(duiObject)
        duiObject = false
    end
    duiReady = false
    InitDui()
    if running and hologramEntity ~= 0 and DoesEntityExist(hologramEntity) then
        ApplyTextureReplacement()
    end
end

local function ApplyConfig(cfg)
    if not cfg then return end
    local newSize = (Null3DUI and Null3DUI.GetQualitySize(cfg.quality)) or 1024
    local newMode = cfg.packMode or "basic"
    local newVariant = cfg.speedVariant or "hologram"
    local sizeChanged = (newSize ~= DUI_WIDTH)
    local variantChanged = (newVariant ~= CURRENT_VARIANT)
    DUI_WIDTH, DUI_HEIGHT = newSize, newSize
    CURRENT_PACK_MODE = newMode
    CURRENT_VARIANT = newVariant

    -- If switching to 2D while currently shown, tear down the hologram immediately.
    if variantChanged and newVariant == "2d" and running then
        DuiSend({ display = false })
        DestroyHologram()
        running = false
        currentVehicle = 0
    end

    if duiObject and sizeChanged then
        RebuildDui()
    else
        DuiSend({ packMode = CURRENT_PACK_MODE })
    end
end

-- ---------------------------------------------------------------------------
-- Main loop: show in vehicle as driver
-- ---------------------------------------------------------------------------

local function IsMetric()
    return ShouldUseMetricMeasurements()
end

CreateThread(function()
    while not (null and null.fct and null.fct.waitPlayerLoaded) do Wait(250) end
    null.fct.waitPlayerLoaded()
    Wait(2000)

    if Null3DUI then
        local cfg = Null3DUI.GetConfig()
        DUI_WIDTH, DUI_HEIGHT = cfg.size, cfg.size
        CURRENT_PACK_MODE = cfg.packMode
        CURRENT_VARIANT   = cfg.speedVariant or "hologram"
    end

    InitDui()
    DuiSend({ packMode = CURRENT_PACK_MODE })

    if Null3DUI then
        Null3DUI.Subscribe("speed_hologram", ApplyConfig)
    end

    while true do
        -- When the player disabled the hologram variant, stay dormant (poll cheap)
        if CURRENT_VARIANT ~= "hologram" then
            if running then
                DuiSend({ display = false })
                DestroyHologram()
                running = false
                currentVehicle = 0
            end
            Wait(1000)
            goto continue_speed_loop
        end

        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then 
            local veh = GetVehiclePedIsIn(ped, false)
            if veh and veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
                -- Become driver of veh
                if currentVehicle ~= veh then
                    currentVehicle = veh
                    local e = CreateHologramEntity(veh)
                    --print(("^3[Null3DSpeed] Entered vehicle %d as driver — hologramEntity=%d^7"):format(veh, e))
                    AttachToVehicle(veh)
                end
                running = true
                ApplyTextureReplacement()

                local metric = IsMetric()
                local rawSpeed = GetEntitySpeed(veh)
                local speed = metric and (rawSpeed * 3.6) or (rawSpeed * 2.23694)
                local rpm = GetVehicleCurrentRpm(veh)
                local gear = GetVehicleCurrentGear(veh)
                local reverse = gear == 0
                local handbrake = GetVehicleHandbrake(veh) == true
                local engine = GetIsVehicleEngineRunning(veh) == true
                local _, lightsOn, highbeamsOn = GetVehicleLightsState(veh)
                local dashboardLights = GetVehicleDashboardLights(veh)
                local headlight = lightsOn == 1 or highbeamsOn == 1 or dashboardLights ~= 0
                -- ABS indicator: vehicle has ABS and player is braking
                local hasAbs = GetVehicleHasAbs and GetVehicleHasAbs(veh) == 1
                local abs = hasAbs and IsControlPressed(0, 72) and GetEntitySpeed(veh) > 1.0

                -- Fuel as % of 100 (GetVehicleFuelLevel returns 0..100 for most vehicles)
                local fuel = GetVehicleFuelLevel(veh)
                if fuel < 0 then fuel = 0 end
                if fuel > 100 then fuel = 100 end

                -- Seatbelt state bridged from modules/ui/client/hud.lua
                local seatbelt = LocalPlayer.state.Null_seatbelt == true

                local sent = DuiSend({
                    display = true,
                    speed = speed,
                    unit = metric and "KMH" or "MPH",
                    gear = gear,
                    reverse = reverse,
                    rpm = rpm,
                    rpmOverload = rpm >= 0.97,
                    handbrake = handbrake,
                    engine = engine,
                    headlight = headlight,
                    abs = abs,
                    seatbelt = seatbelt,
                    fuel = fuel,
                    packMode = CURRENT_PACK_MODE,
                })
                if not _G.__Null3dSpeedFirstSent then
                    _G.__Null3dSpeedFirstSent = true
                    --print(("^3[Null3DSpeed] First DuiSend sent=%s duiObj=%s ready=%s^7"):format(tostring(sent), tostring(duiObject ~= false), tostring(duiReady)))
                end

                Wait(50)
            else
                -- Passenger: hide
                if running then
                    DuiSend({ display = false })
                    DestroyHologram()
                    running = false
                    currentVehicle = 0
                end
                Wait(500)
            end
        else
            if running then
                DuiSend({ display = false })
                DestroyHologram()
                running = false
                currentVehicle = 0
            end
            Wait(800)
        end
        ::continue_speed_loop::
    end
end)

AddEventHandler("onResourceStop", function(resource)
    if resource ~= RESOURCE_NAME then return end
    DestroyHologram()
    if duiObject then
        DestroyDui(duiObject)
        duiObject = false
    end
end)
