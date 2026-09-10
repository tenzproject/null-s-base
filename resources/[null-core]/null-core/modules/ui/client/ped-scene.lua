-- ─────────────────────────────────────────────────────────
-- PedScene — Shared module for clone-ped + background poly
-- ─────────────────────────────────────────────────────────
--
-- Usage:
--   local handle = PedScene.Create(config)
--   PedScene.Destroy(handle)
--   PedScene.Refresh(handle)
--
-- Config keys:
--   screenX          (float)   Screen X anchor  (0-1)
--   screenY          (float)   Screen Y anchor  (0-1)
--   depth            (float)   Distance from camera
--   bgWidth          (float)   Background poly width
--   bgHeight         (float)   Background poly height
--   zOffset          (float)   Vertical offset for polys
--   rotationOffset   (float)   Heading offset from camera
--   polyOffsetY      (float)   Poly Y offset behind ped
--   lightRange       (float)   Light range
--   lightIntensity   (float)   Light intensity
--   lightOffset      (vector3) Light position offset from ped
--   fadeDuration     (float)   Fade in/out duration (ms)
--   bgColor          (table)   { r, g, b }
--   targetAlpha      (int)     Max alpha for poly
--   lightColor       (table)   { r, g, b }
--   animDict         (string)  Animation dictionary
--   animName         (string)  Animation name
--   cameraTilt       (bool)    Adjust position for camera tilt
--   cameraTiltConfig (table)   { downThreshold, downScreenYDelta, downDepth, upThreshold, upDepth }
--   isOpenFn         (func)    Returns true while the UI is open
--   nuiAction        (string)  NUI action for ped visibility messages
--   timeoutPolyFn    (func)    Optional: returns true to skip drawing polys when ped is gone
-- ─────────────────────────────────────────────────────────

PedScene = {}

local activeScenes = {}

-- ─────────────────────────────────────────────────────────
-- Visibility check via engine natives
-- ─────────────────────────────────────────────────────────

local function CheckPedVisibility(ped)
    if not ped or not DoesEntityExist(ped) then return false end
    -- IsEntityOnScreen  → is the entity within the camera frustum
    -- IsEntityOccluded  → is the entity hidden behind world geometry
    return IsEntityOnScreen(ped) and not IsEntityOccluded(ped) and IsEntityVisible(ped)
end

-- ─────────────────────────────────────────────────────────
-- Draw 4 polys (front + back faces) for a quad
-- ─────────────────────────────────────────────────────────

local function DrawQuad(bl, tl, tr, br, r, g, b, a)
    DrawPoly(tr.x, tr.y, tr.z, tl.x, tl.y, tl.z, bl.x, bl.y, bl.z, r, g, b, a)
    DrawPoly(tr.x, tr.y, tr.z, bl.x, bl.y, bl.z, br.x, br.y, br.z, r, g, b, a)
    DrawPoly(tl.x, tl.y, tl.z, tr.x, tr.y, tr.z, br.x, br.y, br.z, r, g, b, a)
    DrawPoly(tl.x, tl.y, tl.z, br.x, br.y, br.z, bl.x, bl.y, bl.z, r, g, b, a)
end

-- ─────────────────────────────────────────────────────────
-- Create
-- ─────────────────────────────────────────────────────────

function PedScene.Create(config)
    local handle = {
        ped = nil,
        destroyed = false,
        config = config,
    }

    -- Prevent duplicate
    local playerPed = PlayerPedId()
    local playerModel = GetEntityModel(playerPed)

    local clone = CreatePed(26, playerModel, 0.0, 0.0, 0.0, 0.0, false, false)
    ClonePedToTarget(playerPed, clone)

    FreezeEntityPosition(clone, true)
    SetEntityCollision(clone, false, false)
    SetEntityInvincible(clone, true)
    SetEntityLocallyVisible(clone)
    NetworkSetEntityInvisibleToNetwork(clone, true)
    SetEntityCanBeDamaged(clone, false)
    SetBlockingOfNonTemporaryEvents(clone, true)
    SetEntityAlpha(clone, 0)

    handle.ped = clone

    local animDict = config.animDict or "amb@world_human_hang_out_street@female_arms_crossed@idle_a"
    local animName = config.animName or "idle_a"
    ESX.Streaming.RequestAnimDict(animDict, function()
        if handle.ped and DoesEntityExist(handle.ped) then
            TaskPlayAnim(handle.ped, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
        end
    end)

    -- Render thread
    CreateThread(function()
        local cfg = config
        local depth = cfg.depth or 4.0
        DisableIdleCamera(true)

        local bgW2 = (cfg.bgWidth or 1.4) / 2
        local bgH2 = (cfg.bgHeight or 2.5) / 2
        local r, g, b = cfg.bgColor and cfg.bgColor.r or 12, cfg.bgColor and cfg.bgColor.g or 12, cfg.bgColor and cfg.bgColor.b or 14
        local tAlpha = cfg.targetAlpha or 235
        local zOff = cfg.zOffset or -0.05
        local lR, lG, lB = cfg.lightColor and cfg.lightColor.r or 195, cfg.lightColor and cfg.lightColor.g or 255, cfg.lightColor and cfg.lightColor.b or 209
        local lRange = cfg.lightRange or 4.0
        local lIntensity = cfg.lightIntensity or 2.0
        local lOff = cfg.lightOffset or vector3(0.0, 1.0, 1.5)
        local polyYOff = cfg.polyOffsetY or -0.4
        local rotOff = cfg.rotationOffset or 180.0
        local sX = cfg.screenX or 0.50
        local sY = cfg.screenY or 0.70
        local fadeDur = cfg.fadeDuration or 150.0
        local isOpenFn = cfg.isOpenFn or function() return true end
        local nuiAction = cfg.nuiAction
        local cameraTilt = cfg.cameraTilt
        local tiltCfg = cfg.cameraTiltConfig or {}
        local timeoutPolyFn = cfg.timeoutPolyFn

        local bl, tl, tr, br, lightPos = nil, nil, nil, nil, nil

        local startTime = GetGameTimer()
        local isFadingOut = false
        local fadeOutStartTime = 0

        -- Visibility tracking
        local lastVisible = true
        local visCheckCounter = 0
        local warmupFrames = 30 -- skip checks for ~30 frames to let ped settle

        while not handle.destroyed do
            -- Detect close → start fading out
            if not isOpenFn() and not isFadingOut then
                isFadingOut = true
                fadeOutStartTime = GetGameTimer()
            end

            local currentAlpha = 0
            local currentPedAlpha = 0

            if isFadingOut then
                local elapsed = GetGameTimer() - fadeOutStartTime
                currentAlpha = math.floor(tAlpha - ((elapsed / fadeDur) * tAlpha))
                currentPedAlpha = math.floor(255 - ((elapsed / fadeDur) * 255))

                if currentAlpha <= 0 then
                    currentAlpha = 0
                    currentPedAlpha = 0
                    isFadingOut = false
                    break
                end
            else
                local elapsed = GetGameTimer() - startTime
                currentAlpha = math.floor((elapsed / fadeDur) * tAlpha)
                currentPedAlpha = math.floor((elapsed / fadeDur) * 255)

                if currentAlpha > tAlpha then currentAlpha = tAlpha end
                if currentPedAlpha > 255 then currentPedAlpha = 255 end
            end

            if handle.ped and DoesEntityExist(handle.ped) then
                SetEntityAlpha(handle.ped, currentPedAlpha)

                local camRot = GetGameplayCamRot(2)
                SetEntityRotation(handle.ped, -camRot.x, 0.0, camRot.z + rotOff, 2, false)

                local screenY = sY
                local currentDepth = depth

                if cameraTilt then
                    local downTh = tiltCfg.downThreshold or -30
                    local upTh = tiltCfg.upThreshold or 30
                    if camRot.x <= downTh then
                        screenY = sY + (tiltCfg.downScreenYDelta or -0.05)
                        currentDepth = tiltCfg.downDepth or depth
                    elseif camRot.x >= upTh then
                        screenY = sY + (tiltCfg.upScreenYDelta or 0)
                        currentDepth = tiltCfg.upDepth or depth
                    end
                end

                local world, normal = GetWorldCoordFromScreenCoord(sX, screenY)
                local target = world + normal * currentDepth
                SetEntityCoords(handle.ped, target.x, target.y, target.z, false, false, false, true)

                bl = GetOffsetFromEntityInWorldCoords(handle.ped, -bgW2, polyYOff, zOff - bgH2)
                tl = GetOffsetFromEntityInWorldCoords(handle.ped, -bgW2, polyYOff, zOff + bgH2)
                tr = GetOffsetFromEntityInWorldCoords(handle.ped,  bgW2, polyYOff, zOff + bgH2)
                br = GetOffsetFromEntityInWorldCoords(handle.ped,  bgW2, polyYOff, zOff - bgH2)
                lightPos = GetOffsetFromEntityInWorldCoords(handle.ped, lOff.x, lOff.y, lOff.z)

                DrawQuad(bl, tl, tr, br, r, g, b, currentAlpha)
                DrawLightWithRange(lightPos.x, lightPos.y, lightPos.z, lR, lG, lB, lRange, lIntensity)

                -- Visibility check (every 5 frames, after warmup)
                if nuiAction and not isFadingOut then
                    if warmupFrames > 0 then
                        warmupFrames = warmupFrames - 1
                    else
                        visCheckCounter = visCheckCounter + 1
                        if visCheckCounter >= 5 then
                            visCheckCounter = 0
                            local isVisible = CheckPedVisibility(handle.ped)
                            if isVisible ~= lastVisible then
                                lastVisible = isVisible
                                SendNUIMessage({
                                    action = nuiAction .. ':pedVisibility',
                                    data = { visible = isVisible },
                                })
                            end
                        end
                    end
                end

            elseif bl ~= nil and tl ~= nil and tr ~= nil and br ~= nil then
                local skipPoly = timeoutPolyFn and timeoutPolyFn()
                if not skipPoly then
                    DrawQuad(bl, tl, tr, br, r, g, b, currentAlpha)
                end
            end

            Wait(0)
        end

        -- Cleanup
        if handle.ped and DoesEntityExist(handle.ped) then
            DeleteEntity(handle.ped)
            handle.ped = nil
        end

        DisableIdleCamera(false)

        -- Send final visible state so NUI resets
        if nuiAction then
            SendNUIMessage({
                action = nuiAction .. ':pedVisibility',
                data = { visible = true },
            })
        end

        handle.destroyed = true
    end)

    return handle
end

-- ─────────────────────────────────────────────────────────
-- Destroy
-- ─────────────────────────────────────────────────────────

function PedScene.Destroy(handle)
    if not handle then return end
    if handle.ped and DoesEntityExist(handle.ped) then
        DeleteEntity(handle.ped)
    end
    handle.ped = nil
    handle.destroyed = true
end

-- ─────────────────────────────────────────────────────────
-- Refresh (destroy + recreate with same config)
-- ─────────────────────────────────────────────────────────

function PedScene.Refresh(handle)
    if not handle or not handle.config then return nil end
    local cfg = handle.config
    PedScene.Destroy(handle)
    Wait(250)
    if cfg.isOpenFn and cfg.isOpenFn() then
        return PedScene.Create(cfg)
    end
    return nil
end

null.InitPrint("PedScene Module Loaded")
