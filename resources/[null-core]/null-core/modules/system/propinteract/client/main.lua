--[[
    PropInteract — Client
    Realistic 3D prop interaction system with camera, cursor, drag & drop.
    
    Players interact with spawned props via NUI overlay:
    - Click zones on props
    - Hold-click for timed actions
    - Drag items onto zones
    - Camera orbit around the scene
    
    API (Exports):
        OpenPropScene(sceneConfig)   — Open an interaction scene
        ClosePropScene()             — Close current scene
        IsSceneOpen()                — Check if a scene is active
        UpdateZoneState(id, state, pulse)
        AddSceneItem(item)
        RemoveSceneItem(id, count)
        AddResult(result)
        SendSceneNotification(text, type)
        UpdateZoneItems(id, heldItems)
    
    NUI Actions (Lua → React):
        propInteract:open
        propInteract:close
        propInteract:updatePositions
        propInteract:updateZoneState
        propInteract:updateItems
        propInteract:holdProgress
        propInteract:holdComplete
        propInteract:holdCancel
        propInteract:addResult
        propInteract:removeItem
        propInteract:notification
        propInteract:updateZoneItems
    
    NUI Callbacks (React → Lua):
        propInteract:close
        propInteract:selectTool
        propInteract:zoneClick
        propInteract:zoneHoldStart
        propInteract:zoneHoldEnd
        propInteract:zoneDrop
        propInteract:orbitStart
        propInteract:orbitMove
        propInteract:orbitEnd
]]

-- ============================================================
-- STATE
-- ============================================================

local activeScene = nil       -- Current scene config
local sceneProps = {}          -- Spawned prop handles { [propId] = entityHandle }
local sceneCam = nil           -- Camera handle
local isOpen = false
local activeTool = nil
local holdingZone = nil
local holdStartTime = 0
local holdDuration = 0
local orbitAngle = 0.0         -- Horizontal orbit angle (radians)
local orbitPitch = 0.0         -- Vertical pitch offset
local orbitDistance = 0.0      -- Camera distance from center
local orbitCenter = nil        -- vec3 center of the scene
local baseOrbitAngle = 0.0
local baseOrbitPitch = 0.0

-- 3D prop drag state
local isDraggingProp = false
local dragPropHandle = nil
local dragOrigPos = nil
local dragScreenX = 0.5
local dragScreenY = 0.5
local dragSourceZoneId = nil
local dragSnapZoneId = nil       -- When hovering a target zone, snap prop to its world pos

-- ============================================================
-- HELPERS
-- ============================================================

local function SendPropNUI(action, data)
    SendNUIMessage({ action = action, data = data or {} })
end

local function LoadModel(model)
    local hash = type(model) == "string" and GetHashKey(model) or model
    if not IsModelValid(hash) then return nil end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 5000 do
        Citizen.Wait(1)
        timeout = timeout + 1
    end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

local function LoadAnimDict(dict)
    if not dict or dict == "" then return false end
    RequestAnimDict(dict)
    local timeout = 0
    while not HasAnimDictLoaded(dict) and timeout < 5000 do
        Citizen.Wait(1)
        timeout = timeout + 1
    end
    return HasAnimDictLoaded(dict)
end

local function GetGroundZ(x, y, z)
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 2.0, false)
    if found then return groundZ end
    found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
    if found then return groundZ end
    return z - 1.0
end

-- ============================================================
-- CAMERA SYSTEM
-- ============================================================

-- Convert screen coords (0-1) to a world ray (origin + direction)
local function ScreenToWorldRay(sx, sy)
    local camPos = GetCamCoord(sceneCam)
    local camRot = GetCamRot(sceneCam, 2)
    local fov = GetCamFov(sceneCam)

    local rx = camRot.x * math.pi / 180.0
    local rz = camRot.z * math.pi / 180.0
    local absX = math.abs(math.cos(rx))
    local fwd = vector3(-math.sin(rz) * absX, math.cos(rz) * absX, math.sin(rx))

    local right = vector3(fwd.y, -fwd.x, 0.0)
    local rLen = #right
    if rLen > 0.001 then right = right / rLen end

    local up = vector3(
        right.y * fwd.z - right.z * fwd.y,
        right.z * fwd.x - right.x * fwd.z,
        right.x * fwd.y - right.y * fwd.x
    )

    local fovRad = fov * math.pi / 180.0
    local ar = GetAspectRatio(false)
    local vS = math.tan(fovRad / 2.0)
    local hS = vS * ar

    local offX = (sx - 0.5) * 2.0 * hS
    local offY = (0.5 - sy) * 2.0 * vS

    local dir = fwd + right * offX + up * offY
    local dLen = #dir
    if dLen > 0.001 then dir = dir / dLen end

    return camPos, dir
end

local function CreateSceneCamera(config)
    local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
     
    if config.camera then
        local c = config.camera
        if c.position then
            SetCamCoord(cam, c.position.x, c.position.y, c.position.z)
        end 
        if c.lookAt then
            PointCamAtCoord(cam, c.lookAt.x, c.lookAt.y, c.lookAt.z)
        end
        SetCamFov(cam, c.fov or 50.0)
        
        -- Store orbit params
        orbitCenter = c.lookAt or c.position
        orbitDistance = c.distance or 1.5
        baseOrbitAngle = c.angle or 0.0
        baseOrbitPitch = c.pitch or 0.15
        orbitAngle = baseOrbitAngle
        orbitPitch = baseOrbitPitch
        
        if orbitCenter and not c.position then
            -- Auto-compute camera position from orbit params
            local cx = orbitCenter.x + orbitDistance * math.cos(orbitAngle) * math.cos(orbitPitch)
            local cy = orbitCenter.y + orbitDistance * math.sin(orbitAngle) * math.cos(orbitPitch)
            local cz = orbitCenter.z + orbitDistance * math.sin(orbitPitch) + (c.heightOffset or 0.3)
            SetCamCoord(cam, cx, cy, cz)
            PointCamAtCoord(cam, orbitCenter.x, orbitCenter.y, orbitCenter.z + (c.lookAtHeightOffset or 0.0))
        end
    end
    
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 800, true, true)
    
    return cam
end

local function UpdateCameraOrbit()
    if not sceneCam or not orbitCenter or not activeScene then return end
    local c = activeScene.camera or {}
    local cx = orbitCenter.x + orbitDistance * math.cos(orbitAngle) * math.cos(orbitPitch)
    local cy = orbitCenter.y + orbitDistance * math.sin(orbitAngle) * math.cos(orbitPitch)
    local cz = orbitCenter.z + orbitDistance * math.sin(orbitPitch) + (c.heightOffset or 0.3)
    local lookAtZ = orbitCenter.z + (c.lookAtHeightOffset or 0.0)

    -- Camera collision: raycast from lookAt to desired cam position
    local from = vector3(orbitCenter.x, orbitCenter.y, lookAtZ)
    local to = vector3(cx, cy, cz)
    local ray = StartShapeTestRay(from.x, from.y, from.z, to.x, to.y, to.z, 1 + 16, PlayerPedId(), 0)
    local _, hit, hitPos, _, _ = GetShapeTestResult(ray)
    if hit == 1 or hit == true then
        local dir = to - from
        local dLen = #dir
        if dLen > 0.001 then dir = dir / dLen end
        cx = hitPos.x - dir.x * 0.15
        cy = hitPos.y - dir.y * 0.15
        cz = hitPos.z - dir.z * 0.15
    end

    SetCamCoord(sceneCam, cx, cy, cz)
    PointCamAtCoord(sceneCam, orbitCenter.x, orbitCenter.y, lookAtZ)

    -- Ped alpha: fade player as camera approaches
    local ped = PlayerPedId()
    local camPos = vector3(cx, cy, cz)
    local pedPos = GetEntityCoords(ped)
    local dist = #(camPos - pedPos)
    local minD, maxD = 0.4, 2.0
    local alpha = math.floor(math.min(255, math.max(0, ((dist - minD) / (maxD - minD)) * 255)))
    SetEntityAlpha(ped, alpha, false)
end

local function DestroySceneCamera()
    if sceneCam then
        SetCamActive(sceneCam, false)
        DestroyCam(sceneCam, false)
        RenderScriptCams(false, true, 500, true, true)
        sceneCam = nil
    end
end

-- ============================================================
-- PROP MANAGEMENT
-- ============================================================

local function SpawnSceneProps(config)
    local ped = PlayerPedId()
    local pedPos = GetEntityCoords(ped)
    local pedHeading = GetEntityHeading(ped)
    
    -- Scene origin: either config.origin or in front of player
    local origin = config.origin
    if not origin then
        local fwd = pedHeading * math.pi / 180.0
        local ox = pedPos.x - math.sin(fwd) * 1.0
        local oy = pedPos.y + math.cos(fwd) * 1.0
        local gz = GetGroundZ(ox, oy, pedPos.z)
        origin = vector3(ox, oy, gz)
    end
    
    for _, propDef in ipairs(config.props or {}) do
        local hash = LoadModel(propDef.model)
        if hash then
            local pos = vector3(
                origin.x + (propDef.offset and propDef.offset.x or 0.0),
                origin.y + (propDef.offset and propDef.offset.y or 0.0),
                origin.z + (propDef.offset and propDef.offset.z or 0.0)
            )
            local rot = propDef.rotation or vector3(0.0, 0.0, 0.0)
            
            local obj = CreateObject(hash, pos.x, pos.y, pos.z, false, false, false)
            SetEntityRotation(obj, rot.x, rot.y, rot.z, 2, true)
            
            if propDef.placeOnGround then
                PlaceObjectOnGroundProperly(obj)
            end
            
            FreezeEntityPosition(obj, true)
            SetEntityCollision(obj, false, false)
            
            if propDef.invisible then
                SetEntityAlpha(obj, 0, false)
            end
            
            sceneProps[propDef.id] = {
                handle = obj,
                model = propDef.model,
                position = GetEntityCoords(obj),
                rotation = rot,
                zones = {}
            }
            
            SetModelAsNoLongerNeeded(hash)
        end
    end
    
    return origin
end

local function DeleteSceneProps()
    for id, propData in pairs(sceneProps) do
        if DoesEntityExist(propData.handle) then
            DeleteEntity(propData.handle)
        end
    end
    sceneProps = {}
end

-- ============================================================
-- ZONE SCREEN COORDINATE PROJECTION
-- ============================================================

local function GetZoneWorldPosition(zone)
    local propData = sceneProps[zone.propId]
    if not propData then
        -- Zone with absolute position
        if zone.worldPos then
            return zone.worldPos
        end
        return nil
    end
    
    local propPos = GetEntityCoords(propData.handle)
    local offset = zone.offset or vector3(0.0, 0.0, 0.0)
    
    -- Apply prop rotation to offset
    local rot = GetEntityRotation(propData.handle, 2)
    local heading = rot.z * math.pi / 180.0
    local ox = offset.x * math.cos(heading) - offset.y * math.sin(heading)
    local oy = offset.x * math.sin(heading) + offset.y * math.cos(heading)
    
    return vector3(propPos.x + ox, propPos.y + oy, propPos.z + offset.z)
end

local function ProjectZonesToScreen()
    if not activeScene or not isOpen then return nil end
    
    local positions = {}
    for _, zone in ipairs(activeScene.zones or {}) do
        local worldPos = GetZoneWorldPosition(zone)
        if worldPos then
            local onScreen, sx, sy = GetScreenCoordFromWorldCoord(worldPos.x, worldPos.y, worldPos.z)
            local camPos = GetCamCoord(sceneCam)
            local dist = #(camPos - worldPos)
            
            table.insert(positions, {
                id = zone.id,
                screenX = sx,
                screenY = sy,
                visible = onScreen,
                distance = dist
            })
        else
            -- Prop was deleted or position unavailable — hide the zone in NUI
            table.insert(positions, {
                id = zone.id,
                screenX = 0,
                screenY = 0,
                visible = false,
                distance = 999
            })
        end
    end
    
    return positions
end

-- ============================================================
-- ANIMATION SYSTEM
-- ============================================================

local function PlaySceneAnim(anim, cb)
    if not anim or not anim.dict or not anim.name then
        if cb then cb() end
        return
    end
    
    local ped = PlayerPedId()
    LoadAnimDict(anim.dict)
    
    local flags = anim.flags or 49 -- Upper body + loop by default
    local duration = anim.duration or -1
    
    TaskPlayAnim(ped, anim.dict, anim.name, 8.0, -8.0, duration, flags, 0, false, false, false)
    
    if cb and anim.duration and anim.duration > 0 then
        Citizen.SetTimeout(anim.duration, function()
            StopAnimTask(ped, anim.dict, anim.name, 1.0)
            cb()
        end)
    elseif cb then
        cb()
    end
end

local function StopSceneAnim()
    local ped = PlayerPedId()
    ClearPedTasks(ped)
end

-- ============================================================
-- OPEN / CLOSE SCENE
-- ============================================================

function OpenPropScene(config)
    if isOpen then
        ClosePropScene()
        Citizen.Wait(600)
    end
    
    if not config or not config.id then
        print("[PropInteract] Error: config.id required")
        return
    end
    
    activeScene = config
    isOpen = true
    activeTool = config.tools and config.tools[1] and config.tools[1].id or nil
    
    -- Freeze player
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    
    -- Spawn props
    local origin = SpawnSceneProps(config)
    
    -- Setup camera
    if not config.camera then
        config.camera = {}
    end
    if not config.camera.lookAt and origin then
        config.camera.lookAt = vector3(origin.x, origin.y, origin.z + 0.5)
    end
    sceneCam = CreateSceneCamera(config)
    UpdateCameraOrbit() -- Apply collision + ped alpha on initial setup

    -- Enable NUI
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    
    -- Build zone data for NUI (without Lua-only fields)
    local nuiZones = {}
    for _, z in ipairs(config.zones or {}) do
        table.insert(nuiZones, {
            id = z.id,
            label = z.label,
            icon = z.icon,
            image = z.image,
            screenX = 0.5,
            screenY = 0.5,
            visible = false,
            distance = 2.0,
            state = z.state or "idle",
            actions = z.actions or {},
            heldItems = z.heldItems or {},
            maxItems = z.maxItems,
            tooltip = z.tooltip,
            pulse = z.pulse ~= false,
            draggable = z.draggable or false,
            dragItemId = z.dragItemId,
        })
    end
    
    -- Send open to NUI
    SendPropNUI("propInteract:open", {
        id = config.id,
        title = config.title or "Interaction",
        subtitle = config.subtitle,
        color = config.color,
        tools = config.tools or {},
        zones = nuiZones,
        items = config.items or {},
        allowOrbit = config.allowOrbit ~= false,
        allowZoom = config.allowZoom ~= false,
        showResults = config.showResults ~= false,
    })
    
    -- Start position update loop
    Citizen.CreateThread(function()
        while isOpen do
            local positions = ProjectZonesToScreen()
            if positions then
                SendPropNUI("propInteract:updatePositions", { positions = positions })
            end
            Citizen.Wait(33) -- ~30fps
        end
    end)
    
    -- Play idle animation if specified
    if config.idleAnim then
        PlaySceneAnim(config.idleAnim)
    end
end

function ClosePropScene()
    if not isOpen then return end
    isOpen = false
    
    -- Cancel any hold
    holdingZone = nil
    
    -- Stop animation
    StopSceneAnim()
    
    -- NUI close
    SendPropNUI("propInteract:close", {})
    SetNuiFocus(false, false)
    
    -- Destroy camera
    DestroySceneCamera()
    
    -- Delete props
    DeleteSceneProps()
    
    -- Reset ped alpha & unfreeze player
    local ped = PlayerPedId()
    ResetEntityAlpha(ped)
    FreezeEntityPosition(ped, false)

    -- Reset drag state
    isDraggingProp = false
    dragPropHandle = nil
    dragOrigPos = nil
    
    -- Fire callbacks
    if activeScene and activeScene.onClose then
        activeScene.onClose()
    end
    
    activeScene = nil
    activeTool = nil
end

function IsSceneOpen()
    return isOpen
end

-- ============================================================
-- SCENE STATE API
-- ============================================================

function UpdateZoneState(zoneId, state, pulse)
    if not isOpen or not activeScene then return end
    -- Update local state
    for i, z in ipairs(activeScene.zones) do
        if z.id == zoneId then
            z.state = state or z.state
            if pulse ~= nil then z.pulse = pulse end
            break
        end
    end
    SendPropNUI("propInteract:updateZoneState", { id = zoneId, state = state, pulse = pulse })
end

function AddSceneItem(item)
    if not isOpen or not activeScene then return end
    activeScene.items = activeScene.items or {}
    -- Check if item already exists
    for i, it in ipairs(activeScene.items) do
        if it.id == item.id then
            activeScene.items[i].count = (activeScene.items[i].count or 0) + (item.count or 1)
            SendPropNUI("propInteract:updateItems", { items = activeScene.items })
            return
        end
    end
    table.insert(activeScene.items, item)
    SendPropNUI("propInteract:updateItems", { items = activeScene.items })
end

function RemoveSceneItem(itemId, count)
    if not isOpen or not activeScene then return end
    count = count or 1
    for i, it in ipairs(activeScene.items or {}) do
        if it.id == itemId then
            it.count = it.count - count
            if it.count <= 0 then
                table.remove(activeScene.items, i)
            end
            break
        end
    end
    SendPropNUI("propInteract:removeItem", { id = itemId, count = count })
end

function AddResult(result)
    if not isOpen then return end
    SendPropNUI("propInteract:addResult", result)
end

function SendSceneNotification(text, notifType)
    if not isOpen then return end
    SendPropNUI("propInteract:notification", { text = text, type = notifType or "info" })
end

function UpdateZoneItems(zoneId, heldItems)
    if not isOpen then return end
    SendPropNUI("propInteract:updateZoneItems", { id = zoneId, heldItems = heldItems })
end

-- Remove a zone from the scene (NUI + config)
function RemoveSceneZone(zoneId)
    if not isOpen or not activeScene then return end
    -- Remove from config zones
    if activeScene.zones then
        for i, z in ipairs(activeScene.zones) do
            if z.id == zoneId then
                table.remove(activeScene.zones, i)
                break
            end
        end
    end
    -- Remove from NUI
    SendPropNUI("propInteract:removeZone", { id = zoneId })
end

-- Delete a specific prop from the scene
function DeleteSceneProp(propId)
    if not isOpen then return end
    local propData = sceneProps[propId]
    if propData and DoesEntityExist(propData.handle) then
        DeleteEntity(propData.handle)
    end
    sceneProps[propId] = nil
end

-- Spawn additional prop into the scene
function AddSceneProp(propDef)
    if not isOpen or not activeScene then return end
    local origin = activeScene.origin or vector3(0,0,0)
    local hash = LoadModel(propDef.model)
    if hash then
        local pos = vector3(
            origin.x + (propDef.offset and propDef.offset.x or 0.0),
            origin.y + (propDef.offset and propDef.offset.y or 0.0),
            origin.z + (propDef.offset and propDef.offset.z or 0.0)
        )
        local rot = propDef.rotation or vector3(0.0, 0.0, 0.0)
        local obj = CreateObject(hash, pos.x, pos.y, pos.z, false, false, false)
        SetEntityRotation(obj, rot.x, rot.y, rot.z, 2, true)
        if propDef.placeOnGround then
            PlaceObjectOnGroundProperly(obj)
        end
        FreezeEntityPosition(obj, true)
        SetEntityCollision(obj, false, false)
        sceneProps[propDef.id] = {
            handle = obj,
            model = propDef.model,
            position = GetEntityCoords(obj),
            rotation = rot,
        }
        SetModelAsNoLongerNeeded(hash)
    end
end

-- Add a new zone to an existing scene
function AddSceneZone(zoneDef)
    if not isOpen or not activeScene then return end
    
    -- Add to config
    table.insert(activeScene.zones, zoneDef)
    
    -- Send to NUI
    SendPropNUI("propInteract:addZone", {
        id = zoneDef.id,
        label = zoneDef.label,
        icon = zoneDef.icon,
        image = zoneDef.image,
        screenX = 0.5,
        screenY = 0.5,
        visible = false,
        distance = 2.0,
        state = zoneDef.state or "idle",
        actions = zoneDef.actions or {},
        heldItems = zoneDef.heldItems or {},
        maxItems = zoneDef.maxItems,
        tooltip = zoneDef.tooltip,
        pulse = zoneDef.pulse ~= false,
        draggable = zoneDef.draggable or false,
        dragItemId = zoneDef.dragItemId,
    })
end

-- Check if a scene prop exists
function GetSceneProp(propId)
    if not isOpen then return nil end
    return sceneProps[propId]
end

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

RegisterNUICallback("propInteract:close", function(data, cb)
    ClosePropScene()
    cb("ok")
end)

RegisterNUICallback("propInteract:selectTool", function(data, cb)
    activeTool = data.toolId
    cb("ok")
end)

RegisterNUICallback("propInteract:zoneClick", function(data, cb)
    if not isOpen or not activeScene then cb("ok") return end
    
    local zoneId = data.zoneId
    local actionId = data.actionId
    
    -- Find zone and action in config
    local zone, action = nil, nil
    for _, z in ipairs(activeScene.zones) do
        if z.id == zoneId then
            zone = z
            for _, a in ipairs(z.actions or {}) do
                if a.id == actionId then
                    action = a
                    break
                end
            end
            break
        end
    end
    
    if not zone or not action then cb("ok") return end
    
    -- Play animation
    if action.animation then
        PlaySceneAnim(action.animation)
    end
    
    -- Fire callback
    if action.onAction then
        action.onAction(zoneId, actionId, activeTool)
    end
    
    -- Fire event
    if activeScene.onZoneAction then
        activeScene.onZoneAction(zoneId, actionId, "click", activeTool)
    end
    
    cb("ok")
end)

RegisterNUICallback("propInteract:zoneHoldStart", function(data, cb)
    if not isOpen or not activeScene then cb("ok") return end
    
    local zoneId = data.zoneId
    local actionId = data.actionId
    
    holdingZone = zoneId
    
    local zone, action = nil, nil
    for _, z in ipairs(activeScene.zones) do
        if z.id == zoneId then
            zone = z
            for _, a in ipairs(z.actions or {}) do
                if a.id == actionId then
                    action = a
                    break
                end
            end
            break
        end
    end
    
    if not zone or not action then cb("ok") return end
    
    holdDuration = action.duration or 2000
    holdStartTime = GetGameTimer()
    
    -- Play animation
    if action.animation then
        PlaySceneAnim(action.animation)
    end
    
    -- Start hold progress loop
    Citizen.CreateThread(function()
        while holdingZone == zoneId and isOpen do
            local elapsed = GetGameTimer() - holdStartTime
            local progress = math.min(100.0, (elapsed / holdDuration) * 100.0)
            
            if progress >= 100.0 then
                holdingZone = nil
                SendPropNUI("propInteract:holdComplete", {})
                
                -- Stop animation
                if action.animation then
                    StopSceneAnim()
                    if activeScene and activeScene.idleAnim then
                        PlaySceneAnim(activeScene.idleAnim)
                    end
                end
                
                -- Fire callback
                if action.onAction then
                    action.onAction(zoneId, actionId, activeTool)
                end
                
                if activeScene and activeScene.onZoneAction then
                    activeScene.onZoneAction(zoneId, actionId, "hold_complete", activeTool)
                end
                
                break
            end
            
            Citizen.Wait(16)
        end
    end)
    
    cb("ok")
end)

RegisterNUICallback("propInteract:zoneHoldEnd", function(data, cb)
    if holdingZone then
        holdingZone = nil
        StopSceneAnim()
        if activeScene and activeScene.idleAnim then
            PlaySceneAnim(activeScene.idleAnim)
        end
        SendPropNUI("propInteract:holdCancel", {})
        
        if activeScene and activeScene.onZoneAction then
            activeScene.onZoneAction(data.zoneId, data.actionId, "hold_cancel", activeTool)
        end
    end
    cb("ok")
end)

RegisterNUICallback("propInteract:zoneDrop", function(data, cb)
    if not isOpen or not activeScene then cb("ok") return end
    
    local zoneId = data.zoneId
    local itemId = data.itemId
    
    -- Find zone
    local zone = nil
    for _, z in ipairs(activeScene.zones) do
        if z.id == zoneId then
            zone = z
            break
        end
    end
    
    if not zone then cb("ok") return end
    
    -- Find drag_receive action
    local action = nil
    for _, a in ipairs(zone.actions or {}) do
        if a.type == "drag_receive" then
            if not a.acceptItems or #a.acceptItems == 0 then
                action = a
                break
            end
            for _, acceptId in ipairs(a.acceptItems) do
                if acceptId == itemId then
                    action = a
                    break
                end
            end
            if action then break end
        end
    end
    
    if not action then
        SendPropNUI("propInteract:notification", { text = "Cet objet ne va pas ici", type = "error" })
        cb("ok")
        return
    end
    
    -- Play animation
    if action.animation then
        PlaySceneAnim(action.animation)
    end
    
    -- Fire callback
    if action.onAction then
        action.onAction(zoneId, action.id, activeTool, itemId)
    end
    
    if activeScene and activeScene.onZoneDrop then
        activeScene.onZoneDrop(zoneId, action.id, itemId, activeTool, data.sourceType, data.sourceId)
    end
    
    cb("ok")
end)

-- 3D prop drag callbacks
RegisterNUICallback("propInteract:zoneDragStart", function(data, cb)
    if not isOpen or not activeScene then cb("ok") return end
    local zoneId = data.zoneId
    -- Find zone and its prop
    for _, z in ipairs(activeScene.zones or {}) do
        if z.id == zoneId and z.propId then
            local pd = sceneProps[z.propId]
            if pd and DoesEntityExist(pd.handle) then
                isDraggingProp = true
                dragPropHandle = pd.handle
                dragOrigPos = GetEntityCoords(pd.handle)
                dragSourceZoneId = zoneId
                dragScreenX = 0.5
                dragScreenY = 0.5
                FreezeEntityPosition(pd.handle, false)
                -- Enable collision on other scene props so raycast hits surfaces (table etc.)
                for pid, ppd in pairs(sceneProps) do
                    if ppd.handle ~= dragPropHandle and DoesEntityExist(ppd.handle) then
                        SetEntityCollision(ppd.handle, true, false)
                    end
                end
                -- Drag loop: move prop every frame
                Citizen.CreateThread(function()
                    while isDraggingProp and isOpen do
                        if sceneCam and dragPropHandle and DoesEntityExist(dragPropHandle) then
                            -- If hovering a target zone, snap prop to that zone's world position
                            if dragSnapZoneId then
                                for _, sz in ipairs(activeScene.zones or {}) do
                                    if sz.id == dragSnapZoneId then
                                        local snapPos = GetZoneWorldPosition(sz)
                                        if snapPos then
                                            SetEntityCoords(dragPropHandle, snapPos.x, snapPos.y, snapPos.z, false, false, false, false)
                                        end
                                        break
                                    end
                                end
                            else
                                local camPos, dir = ScreenToWorldRay(dragScreenX, dragScreenY)
                                local endP = camPos + dir * 10.0
                                local ray = StartShapeTestRay(camPos.x, camPos.y, camPos.z, endP.x, endP.y, endP.z, 1 + 16, dragPropHandle, 0)
                                local _, rHit, rPos, rNorm, _ = GetShapeTestResult(ray)
                                if rHit == 1 or rHit == true then
                                    SetEntityCoords(dragPropHandle, rPos.x + rNorm.x * 0.02, rPos.y + rNorm.y * 0.02, rPos.z + rNorm.z * 0.02, false, false, false, false)
                                else
                                    local pos = camPos + dir * 1.2
                                    SetEntityCoords(dragPropHandle, pos.x, pos.y, pos.z, false, false, false, false)
                                end
                            end
                        end
                        Citizen.Wait(0)
                    end
                end)
            end
            break
        end
    end
    cb("ok")
end)

RegisterNUICallback("propInteract:zoneDragMove", function(data, cb)
    dragScreenX = data.screenX or 0.5
    dragScreenY = data.screenY or 0.5
    cb("ok")
end)

RegisterNUICallback("propInteract:zoneDragSnap", function(data, cb)
    dragSnapZoneId = data.targetZoneId -- nil clears snap
    cb("ok")
end)

RegisterNUICallback("propInteract:zoneDragEnd", function(data, cb)
    if isDraggingProp and dragPropHandle and DoesEntityExist(dragPropHandle) then
        if not data.dropped then
            -- Snap back to original position
            SetEntityCoords(dragPropHandle, dragOrigPos.x, dragOrigPos.y, dragOrigPos.z, false, false, false, false)
        end
        FreezeEntityPosition(dragPropHandle, true)
    end
    -- Disable collision on all scene props again
    for pid, ppd in pairs(sceneProps) do
        if DoesEntityExist(ppd.handle) then
            SetEntityCollision(ppd.handle, false, false)
        end
    end
    isDraggingProp = false
    dragPropHandle = nil
    dragOrigPos = nil
    dragSourceZoneId = nil
    dragSnapZoneId = nil
    cb("ok")
end)

RegisterNUICallback("propInteract:orbitStart", function(data, cb)
    cb("ok")
end)

RegisterNUICallback("propInteract:orbitMove", function(data, cb)
    if not isOpen or not sceneCam then cb("ok") return end
    local c = activeScene and activeScene.camera or {}
    local sensitivity = 0.003
    orbitAngle = orbitAngle - (data.dx or 0) * sensitivity
    orbitPitch = math.max(-0.3, math.min(0.8, orbitPitch + (data.dy or 0) * sensitivity))
    UpdateCameraOrbit()
    cb("ok")
end)

RegisterNUICallback("propInteract:orbitEnd", function(data, cb)
    cb("ok")
end)

RegisterNUICallback("propInteract:zoom", function(data, cb)
    if not isOpen or not sceneCam then cb("ok") return end
    local c = activeScene and activeScene.camera or {}
    local minDist = c.minDistance or 0.5
    local maxDist = c.maxDistance or 5.0
    local step = c.zoomStep or 0.15
    local delta = data.delta or 0
    orbitDistance = math.max(minDist, math.min(maxDist, orbitDistance + delta * step))
    UpdateCameraOrbit()
    cb("ok")
end)

-- ============================================================
-- EXPORTS
-- ============================================================

exports('OpenPropScene', OpenPropScene)
exports('ClosePropScene', ClosePropScene)
exports('IsSceneOpen', IsSceneOpen)
exports('UpdateZoneState', UpdateZoneState)
exports('AddSceneItem', AddSceneItem)
exports('RemoveSceneItem', RemoveSceneItem)
exports('AddResult', AddResult)
exports('SendSceneNotification', SendSceneNotification)
exports('UpdateZoneItems', UpdateZoneItems)
exports('DeleteSceneProp', DeleteSceneProp)
exports('AddSceneProp', AddSceneProp)
exports('RemoveSceneZone', RemoveSceneZone)
exports('AddSceneZone', AddSceneZone)
exports('GetSceneProp', GetSceneProp)

-- ============================================================
-- EVENTS
-- ============================================================

RegisterNetEvent('null:propInteract:open')
AddEventHandler('null:propInteract:open', function(config)
    OpenPropScene(config)
end)

RegisterNetEvent('null:propInteract:close')
AddEventHandler('null:propInteract:close', function()
    ClosePropScene()
end)

-- ============================================================
-- EXAMPLE / TEST COMMANDS
-- ============================================================

-- Example 1: Weed Cutting (with real bud props)
RegisterCommand('proptest_weed', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local fwd = heading * math.pi / 180.0
    local ox = pos.x - math.sin(fwd) * 1.2
    local oy = pos.y + math.cos(fwd) * 1.2
    local gz = GetGroundZ(ox, oy, pos.z)
    local origin = vector3(ox, oy, gz)
    
    local cutsRemaining = 4
    
    OpenPropScene({
        id = "weed_cutting",
        title = "Couper les têtes de Weed",
        subtitle = "Utilisez les ciseaux pour couper les têtes",
        color = "#22c55e",
        origin = origin,
        
        camera = {
            lookAt = vector3(origin.x, origin.y, origin.z + 0.6),
            distance = 1.8,
            heightOffset = 0.5,
            lookAtHeightOffset = 0.1,
            fov = 45.0,
        },
        
        props = {
            { id = "plant1", model = "prop_weed_01", offset = vector3(0.0, 0.0, 0.0), placeOnGround = true },
            -- Real weed bud props on the plant
            { id = "bud_prop_1", model = "bkr_prop_weed_bud_pruned_01a", offset = vector3(0.0, 0.05, 0.55) },
            { id = "bud_prop_2", model = "bkr_prop_weed_bud_pruned_01a", offset = vector3(0.15, -0.05, 0.50) },
            { id = "bud_prop_3", model = "bkr_prop_weed_bud_pruned_01a", offset = vector3(-0.12, 0.08, 0.45) },
            { id = "bud_prop_4", model = "bkr_prop_weed_bud_pruned_01a", offset = vector3(0.05, -0.12, 0.60) },
        },
        
        tools = {
            { id = "drugs_scissors", label = "Ciseaux", icon = "scissors", description = "Couper les têtes de weed" },
            { id = "hand", label = "Main", icon = "hand", description = "Prendre et déplacer" },
        },
        
        zones = {
            {
                id = "bud_1", propId = "plant1", offset = vector3(0.0, 0.05, 0.55),
                label = "Tête #1", icon = "leaf",
                state = "highlight", pulse = true,
                actions = {
                    {
                        id = "cut", label = "Couper", type = "hold", duration = 2000,
                        requiredTool = "drugs_scissors",
                        animation = { dict = "amb@world_human_gardener_plant@male@base", name = "base", flags = 49 },
                    },
                },
            },
            {
                id = "bud_2", propId = "plant1", offset = vector3(0.15, -0.05, 0.50),
                label = "Tête #2", icon = "leaf",
                state = "highlight", pulse = true,
                actions = {
                    {
                        id = "cut", label = "Couper", type = "hold", duration = 2000,
                        requiredTool = "drugs_scissors",
                        animation = { dict = "amb@world_human_gardener_plant@male@base", name = "base", flags = 49 },
                    },
                },
            },
            {
                id = "bud_3", propId = "plant1", offset = vector3(-0.12, 0.08, 0.45),
                label = "Tête #3", icon = "leaf",
                state = "highlight", pulse = true,
                actions = {
                    {
                        id = "cut", label = "Couper", type = "hold", duration = 2000,
                        requiredTool = "drugs_scissors",
                        animation = { dict = "amb@world_human_gardener_plant@male@base", name = "base", flags = 49 },
                    },
                },
            },
            {
                id = "bud_4", propId = "plant1", offset = vector3(0.05, -0.12, 0.60),
                label = "Tête #4", icon = "leaf",
                state = "highlight", pulse = true,
                actions = {
                    {
                        id = "cut", label = "Couper", type = "hold", duration = 2000,
                        requiredTool = "drugs_scissors",
                        animation = { dict = "amb@world_human_gardener_plant@male@base", name = "base", flags = 49 },
                    },
                },
            },
        },
        
        items = {},
        
        onZoneAction = function(zoneId, actionId, actionType, toolId)
            if actionType == "hold_complete" and actionId == "cut" then
                -- Mark zone as completed
                UpdateZoneState(zoneId, "completed", false)
                
                -- Delete the matching bud prop (bud_1 → bud_prop_1, etc.)
                local budPropId = zoneId:gsub("bud_", "bud_prop_")
                DeleteSceneProp(budPropId)
                
                -- Add result
                AddResult({ id = "weed_head", label = "Tête de weed", icon = "leaf", count = 1 })
                SendSceneNotification("Tête coupée avec succès !", "success")
                
                cutsRemaining = cutsRemaining - 1
                if cutsRemaining <= 0 then
                    Citizen.SetTimeout(1500, function()
                        SendSceneNotification("Toutes les têtes ont été coupées !", "success")
                        Citizen.SetTimeout(2000, function()
                            ClosePropScene()
                        end)
                    end)
                end
            end
        end,
    })
end, false)

-- Example 2: Packaging (drag bud props into bags)
-- Buds are draggable zones on the table; bags are drop-receive zones.
RegisterCommand('proptest_package', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local fwd = heading * math.pi / 180.0
    local ox = pos.x - math.sin(fwd) * 1.0
    local oy = pos.y + math.cos(fwd) * 1.0
    local gz = GetGroundZ(ox, oy, pos.z)
    local origin = vector3(ox, oy, gz)
    
    local bagsCompleted = 0
    local budImage = "nui://null-cache/images/props/bkr_prop_weed_bud_pruned_01a.webp"
    
    -- Bag zone offsets (relative to table, on top of it)
    local bag1Offset = vector3(-0.3, 0.0, 0.95)
    local bag2Offset = vector3(0.3, 0.0, 0.95)
    
    -- Bud offsets on the table (spread out in the center)
    local budOffsets = {
        vector3(-0.05, -0.15, 0.95),
        vector3(0.05, -0.10, 0.95),
        vector3(-0.08,  0.10, 0.95),
        vector3(0.08,  0.15, 0.95),
        vector3(0.0,   0.0,  0.95),
        vector3(-0.02,  0.05, 0.98),
    }
    
    -- Build bud props + draggable bud zones
    local budProps = {}
    local budZones = {}
    for i, off in ipairs(budOffsets) do
        budProps[#budProps + 1] = {
            id = "bud_pkg_" .. i,
            model = "bkr_prop_weed_bud_pruned_01a",
            offset = off,
            placeOnGround = false,
        }
        budZones[#budZones + 1] = {
            id = "bud_zone_" .. i,
            propId = "bud_pkg_" .. i,
            offset = vector3(0.0, 0.0, 0.05),
            label = "Tête de weed",
            icon = "leaf",
            image = budImage,
            state = "idle",
            draggable = true,
            dragItemId = "weed_head",
            actions = {},
        }
    end
    
    -- Combine all props
    local allProps = {
        { id = "table", model = "bkr_prop_weed_table_01a", offset = vector3(0.0, 0.0, 0.0), placeOnGround = true },
        { id = "bag_prop_1", model = "bkr_prop_weed_bag_01a", offset = bag1Offset, rotation = vector3(0.0, 0.0, 0.0) },
        { id = "bag_prop_2", model = "bkr_prop_weed_bag_01a", offset = bag2Offset, rotation = vector3(0.0, 0.0, 0.0) },
    }
    for _, bp in ipairs(budProps) do allProps[#allProps + 1] = bp end
    
    -- Combine all zones: bag receivers + bud draggables
    local allZones = {
        {
            id = "bag_1", propId = "table", offset = vector3(-0.3, 0.0, 1.1),
            label = "Pochon #1", icon = "package",
            state = "idle", pulse = true,
            maxItems = 3,
            actions = {
                {
                    id = "fill", label = "Remplir", type = "drag_receive",
                    acceptItems = { "weed_head" },
                    animation = { dict = "mp_common", name = "givetake1_a", flags = 49, duration = 800 },
                },
            },
        },
        {
            id = "bag_2", propId = "table", offset = vector3(0.3, 0.0, 1.1),
            label = "Pochon #2", icon = "package",
            state = "idle", pulse = true,
            maxItems = 3,
            actions = {
                {
                    id = "fill", label = "Remplir", type = "drag_receive",
                    acceptItems = { "weed_head" },
                    animation = { dict = "mp_common", name = "givetake1_a", flags = 49, duration = 800 },
                },
            },
        },
    }
    for _, bz in ipairs(budZones) do allZones[#allZones + 1] = bz end
    
    OpenPropScene({
        id = "weed_packaging",
        title = "Conditionner la Weed",
        subtitle = "Glissez les têtes dans les pochons",
        color = "#f59e0b",
        origin = origin,
        
        camera = {
            lookAt = vector3(origin.x, origin.y, origin.z + 0.85),
            distance = 1.6,
            heightOffset = 0.6,
            lookAtHeightOffset = 0.0,
            fov = 50.0,
        },
        
        props = allProps,
        tools = {},
        zones = allZones,
        items = {},
        
        onZoneDrop = function(zoneId, actionId, itemId, toolId, sourceType, sourceId)
            -- If the drag came from a bud zone, remove that zone + its prop
            if sourceType == "zone" and sourceId then
                local budPropId = sourceId:gsub("bud_zone_", "bud_pkg_")
                DeleteSceneProp(budPropId)
                RemoveSceneZone(sourceId)
            end
            
            -- Track held items in bag zone
            local zone = nil
            for _, z in ipairs(activeScene.zones) do
                if z.id == zoneId then zone = z break end
            end
            if zone then
                zone.heldItems = zone.heldItems or {}
                local found = false
                for _, h in ipairs(zone.heldItems) do
                    if h.itemId == itemId then
                        h.count = h.count + 1
                        found = true
                        break
                    end
                end
                if not found then
                    table.insert(zone.heldItems, { itemId = itemId, count = 1 })
                end
                
                UpdateZoneItems(zoneId, zone.heldItems)
                
                -- Count items in this bag
                local total = 0
                for _, h in ipairs(zone.heldItems) do total = total + h.count end
                
                -- Swap bag prop based on fill level
                local bagPropId = zoneId:gsub("bag_", "bag_prop_")
                local bagOffset = zoneId == "bag_1" and bag1Offset or bag2Offset
                
                if total >= (zone.maxItems or 3) then
                    -- Full → closed bag
                    DeleteSceneProp(bagPropId)
                    AddSceneProp({ id = bagPropId, model = "sf_prop_sf_bag_weed_01a", offset = bagOffset })
                    
                    UpdateZoneState(zoneId, "completed", false)
                    AddResult({ id = "weed_bag", label = "Pochon de weed", icon = "package", count = 1 })
                    SendSceneNotification("Pochon rempli !", "success")
                    
                    bagsCompleted = bagsCompleted + 1
                    if bagsCompleted >= 2 then
                        Citizen.SetTimeout(1500, function()
                            SendSceneNotification("Tout est conditionné !", "success")
                            Citizen.SetTimeout(2000, function()
                                ClosePropScene()
                            end)
                        end)
                    end
                elseif total >= 1 then
                    -- Partially filled → open bag with weed
                    DeleteSceneProp(bagPropId)
                    AddSceneProp({ id = bagPropId, model = "sf_prop_sf_bag_weed_open_01b", offset = bagOffset })
                    SendSceneNotification(string.format("Pochon %d/%d", total, zone.maxItems or 3), "info")
                end
            end
        end,
    })
end, false)

-- Example 3: Weapon Assembly (multi-step click)
RegisterCommand('proptest_weapon', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local fwd = heading * math.pi / 180.0
    local ox = pos.x - math.sin(fwd) * 1.0
    local oy = pos.y + math.cos(fwd) * 1.0
    local gz = GetGroundZ(ox, oy, pos.z)
    local origin = vector3(ox, oy, gz)
    
    local partsAssembled = 0
    local totalParts = 4
    
    OpenPropScene({
        id = "weapon_assembly",
        title = "Assemblage d'Arme",
        subtitle = "Assemblez les pièces sur l'établi",
        color = "#ef4444",
        origin = origin,
        
        camera = {
            lookAt = vector3(origin.x, origin.y, origin.z + 0.8),
            distance = 1.5,
            heightOffset = 0.5,
            lookAtHeightOffset = 0.0,
            fov = 48.0,
        },
        
        props = {
            { id = "bench", model = "prop_tool_bench02", offset = vector3(0.0, 0.0, 0.0), rotation = vector3(0.0, 0.0, 90.0), placeOnGround = true },
        },
        
        tools = {
            { id = "wrench", label = "Clé", icon = "wrench", description = "Pour visser les pièces" },
            { id = "hammer", label = "Marteau", icon = "hammer", description = "Pour emboîter les pièces" },
        },
        
        zones = {
            {
                id = "frame", propId = "bench", offset = vector3(0.0, 0.0, 0.95),
                label = "Cadre de l'arme", icon = "target",
                state = "highlight", pulse = true,
                actions = {
                    {
                        id = "assemble", label = "Monter le cadre", type = "hold", duration = 3000,
                        requiredTool = "wrench",
                        animation = { dict = "mini@repair", name = "fixing_a_player", flags = 49 },
                    },
                },
            },
            {
                id = "barrel", propId = "bench", offset = vector3(0.3, 0.0, 0.95),
                label = "Canon", icon = "crosshair",
                state = "disabled",
                actions = {
                    {
                        id = "assemble", label = "Fixer le canon", type = "hold", duration = 2500,
                        requiredTool = "wrench",
                        animation = { dict = "mini@repair", name = "fixing_a_player", flags = 49 },
                    },
                },
            },
            {
                id = "grip", propId = "bench", offset = vector3(-0.3, 0.0, 0.95),
                label = "Poignée", icon = "grip",
                state = "disabled",
                actions = {
                    {
                        id = "assemble", label = "Fixer la poignée", type = "hold", duration = 2000,
                        requiredTool = "hammer",
                        animation = { dict = "mini@repair", name = "fixing_a_player", flags = 49 },
                    },
                },
            },
            {
                id = "magazine", propId = "bench", offset = vector3(0.0, 0.2, 0.95),
                label = "Chargeur", icon = "box",
                state = "disabled",
                actions = {
                    {
                        id = "assemble", label = "Insérer le chargeur", type = "click",
                        requiredTool = "hand",
                        animation = { dict = "mp_common", name = "givetake1_a", flags = 49, duration = 600 },
                    },
                },
            },
        },
        
        items = {},
        
        idleAnim = { dict = "amb@world_human_welding@male@base", name = "base", flags = 49 },
        
        onZoneAction = function(zoneId, actionId, actionType, toolId)
            local isComplete = (actionType == "hold_complete") or (actionType == "click")
            if not isComplete then return end
            
            UpdateZoneState(zoneId, "completed", false)
            partsAssembled = partsAssembled + 1
            
            local partNames = { frame = "Cadre", barrel = "Canon", grip = "Poignée", magazine = "Chargeur" }
            SendSceneNotification(string.format("%s assemblé(e) ! (%d/%d)", partNames[zoneId] or zoneId, partsAssembled, totalParts), "success")
            
            -- Unlock next step
            local unlockOrder = { "barrel", "grip", "magazine" }
            if partsAssembled <= #unlockOrder then
                local nextId = unlockOrder[partsAssembled]
                UpdateZoneState(nextId, "highlight", true)
                
                -- Add required tool hint
                if nextId == "grip" then
                    SendSceneNotification("Sélectionnez le marteau pour la poignée", "info")
                elseif nextId == "magazine" then
                    -- Magazine needs "hand" tool — auto-add if not in tools
                    SendSceneNotification("Utilisez votre main pour le chargeur", "info")
                end
            end
            
            if partsAssembled >= totalParts then
                AddResult({ id = "weapon_pistol", label = "Pistolet assemblé", icon = "crosshair", count = 1 })
                Citizen.SetTimeout(1500, function()
                    SendSceneNotification("Arme assemblée avec succès !", "success")
                    Citizen.SetTimeout(2000, function()
                        ClosePropScene()
                    end)
                end)
            end
        end,
    })
    
    -- Add hand tool dynamically (it wasn't in tools list initially - to demonstrate AddSceneItem is different)
    Citizen.SetTimeout(100, function()
        -- Actually tools are static, but items can be added
    end)
end, false)

-- Simple test: minimal scene
RegisterCommand('proptest_simple', function()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local fwd = heading * math.pi / 180.0
    local ox = pos.x - math.sin(fwd) * 1.5
    local oy = pos.y + math.cos(fwd) * 1.5
    local gz = GetGroundZ(ox, oy, pos.z)
    local origin = vector3(ox, oy, gz)
    
    OpenPropScene({
        id = "simple_test",
        title = "Test Simple",
        subtitle = "Cliquez sur les zones",
        color = "#8b5cf6",
        origin = origin,
        
        camera = {
            lookAt = vector3(origin.x, origin.y, origin.z + 0.5),
            distance = 2.0,
            heightOffset = 0.5,
            fov = 50.0,
        },
        
        props = {
            { id = "barrel", model = "prop_barrel_02a", offset = vector3(0.0, 0.0, 0.0), placeOnGround = true },
        },
        
        tools = {
            { id = "hand", label = "Main", icon = "hand" },
        },
        
        zones = {
            {
                id = "top", propId = "barrel", offset = vector3(0.0, 0.0, 0.8),
                label = "Dessus du baril", icon = "circle",
                state = "highlight", pulse = true,
                actions = {
                    { id = "tap", label = "Taper", type = "click" },
                },
            },
            {
                id = "side", propId = "barrel", offset = vector3(0.3, 0.0, 0.4),
                label = "Côté du baril", icon = "target",
                state = "idle",
                actions = {
                    { id = "hold_test", label = "Maintenir", type = "hold", duration = 3000 },
                },
            },
        },
        
        items = {},
        
        onZoneAction = function(zoneId, actionId, actionType, toolId)
            if zoneId == "top" and actionType == "click" then
                SendSceneNotification("Vous avez tapé sur le baril !", "success")
                UpdateZoneState("top", "completed", false)
                UpdateZoneState("side", "highlight", true)
            elseif zoneId == "side" and actionType == "hold_complete" then
                SendSceneNotification("Action maintenue terminée !", "success")
                UpdateZoneState("side", "completed", false)
                AddResult({ id = "test_item", label = "Objet test", icon = "star", count = 1 })
                Citizen.SetTimeout(2000, function()
                    ClosePropScene()
                end)
            end
        end,
    })
end, false)
