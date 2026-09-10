
TextPlacement = {}

local state = {
    isActive         = false,
    camera           = nil,
    callback         = nil,

    previewDui       = nil,
    previewDuiHandle = nil,
    previewTxdName   = nil,
    previewTxnName   = nil,
    previewTxd       = nil,

    camPos           = vector3(0.0, 0.0, 0.0),
    camRot           = vector3(-20.0, 0.0, 0.0),

    textPos          = vector3(0.0, 0.0, 0.0),
    textHeading      = 0.0,

    entityDistance   = 7.0,
    minDistance      = 3.0,
    maxDistance      = 30.0,

    baseSpeed        = 15.0,
    fastSpeed        = 45.0,
    mouseSensitivity = 4.0,

    worldWidth       = 6.0,
    worldHeight      = 0.75,
}

local function rotationToForwardVector(rot)
    local pitchRad = math.rad(rot.x)
    local yawRad   = math.rad(rot.z)

    local x        = -math.sin(yawRad) * math.abs(math.cos(pitchRad))
    local y        = math.cos(yawRad) * math.abs(math.cos(pitchRad))
    local z        = math.sin(pitchRad)

    return vector3(x, y, z)
end

local function rotationToRightVector(rot)
    local yawRad = math.rad(rot.z - 90.0)
    return vector3(-math.sin(yawRad), math.cos(yawRad), 0.0)
end

local function drawTextQuad(textPos)
    if not state.previewTxdName then return end

    local headingRad  = math.rad(state.textHeading)
    local right       = vector3(-math.cos(headingRad), math.sin(headingRad), 0.0)

    local halfW       = state.worldWidth / 2.0
    local halfH       = state.worldHeight / 2.0
    local up          = vector3(0.0, 0.0, halfH)

    local topLeft     = (textPos + right * (-halfW)) + up
    local topRight    = (textPos + right * halfW) + up
    local bottomLeft  = (textPos + right * (-halfW)) - up
    local bottomRight = (textPos + right * halfW) - up

    DrawSpritePoly(
        bottomRight.x, bottomRight.y, bottomRight.z,
        topRight.x, topRight.y, topRight.z,
        topLeft.x, topLeft.y, topLeft.z,
        255, 255, 255, 255,
        state.previewTxdName, state.previewTxnName,
        1.0, 1.0,
        1.0, 0.0,
        0.0, 1.0,
        0.0, 0.0,
        1.0
    )

    DrawSpritePoly(
        topLeft.x, topLeft.y, topLeft.z,
        bottomLeft.x, bottomLeft.y, bottomLeft.z,
        bottomRight.x, bottomRight.y, bottomRight.z,
        255, 255, 255, 255,
        state.previewTxdName, state.previewTxnName,
        0.0, 0.0,
        1.0, 0.0,
        1.0, 1.0,
        1.0, 1.0,
        1.0
    )
end

local function setupDui(opts)
    local charCount        = #(opts.text or "Text")
    local fontSize         = opts.size or 4.0

    state.worldWidth       = math.max(0.5, (charCount * 0.22 + 1.5) * fontSize)
    state.worldHeight      = state.worldWidth * 0.125

    local duiUrl           = "https://cfx-nui-core_cinematics/html/textdui/text.html"
    state.previewDui       = CreateDui(duiUrl, 2048, 256)
    state.previewDuiHandle = GetDuiHandle(state.previewDui)
    state.previewTxdName   = "cc_tp_txd"
    state.previewTxnName   = "cc_tp_txn"
    state.previewTxd       = CreateRuntimeTxd(state.previewTxdName)
    CreateRuntimeTextureFromDuiHandle(state.previewTxd, state.previewTxnName, state.previewDuiHandle)

    Citizen.CreateThread(function()
        local attempts = 0
        while not IsDuiAvailable(state.previewDui) and attempts < 100 do
            Citizen.Wait(100)
            attempts = attempts + 1
        end

        Citizen.Wait(300)

        if not state.previewDui then return end

        local payload = {
            action           = "processText",
            text             = opts.text or "Sample Text",
            font             = opts.font or "Arial",
            fontUrl          = opts.fontUrl or "",
            color            = opts.color or "#ffffff",
            shadow           = opts.shadow or false,
            glow             = opts.glow or false,
            outline          = opts.outline or false,
            outlineColor     = opts.outlineColor or "#000000",
            outlineWidth     = opts.outlineWidth or 2,
            colorShift       = opts.colorShift or false,
            colorShiftColors = opts.colorShiftColors or "",
            colorShiftSpeed  = opts.colorShiftSpeed or 60,
            relFrame         = 20,
            totalFrames      = 60,
            animIn           = 15,
            animOut          = 15,
        }

        SendDuiMessage(state.previewDui, json.encode(payload))
    end)
end

local function destroyDui()
    if not state.previewDui then return end

    DestroyDui(state.previewDui)
    state.previewDui       = nil
    state.previewDuiHandle = nil
    state.previewTxdName   = nil
    state.previewTxnName   = nil
    state.previewTxd       = nil
end

local function cleanup()
    state.isActive = false
    destroyDui()

    if state.camera and DoesCamExist(state.camera) then
        SetCamActive(state.camera, false)
        DestroyCam(state.camera, false)
        state.camera = nil
    end

    RenderScriptCams(false, false, 0, true, false)

    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    FreezeEntityPosition(ped, false)
    DisplayRadar(true)
    DisplayHud(true)

    SendNUIMessage({ type = "textPlacementActive", active = false })
end

function TextPlacement.Start(opts, callback)
    if state.isActive then return end

    state.isActive = true
    state.callback = callback

    local ped = PlayerPedId()

    if opts.existingCoords and opts.existingCoords.x then
        
        local ec             = opts.existingCoords
        local pos            = vector3(ec.x, ec.y, ec.z)
        local heading        = ec.heading or 0.0

        local headingRad     = math.rad(heading)
        local sinH           = math.sin(headingRad)
        local cosH           = math.cos(headingRad)
        local backDist       = 8.0

        local camPos         = vector3(
            pos.x + sinH * backDist,
            pos.y + cosH * backDist,
            pos.z + backDist * 0.25
        )
        state.camPos         = camPos

        local delta          = pos - camPos
        local horizLen       = math.sqrt(delta.x * delta.x + delta.y * delta.y)
        local fullLen        = math.sqrt(delta.x * delta.x + delta.y * delta.y + delta.z * delta.z)

        state.entityDistance = fullLen

        local pitchDeg       = math.deg(math.atan(delta.z, horizLen))
        local yawDeg         = math.deg(math.atan(delta.x, delta.y)) * -1.0

        state.camRot         = vector3(pitchDeg, 0.0, yawDeg)
        state.textPos        = pos
        state.textHeading    = heading
    elseif opts.camPos and opts.camPos.x then
        
        state.camPos      = vector3(opts.camPos.x, opts.camPos.y, opts.camPos.z)

        local rotX        = (opts.camRot and opts.camRot.x) or -20.0
        local rotZ        = (opts.camRot and opts.camRot.z) or 0.0
        state.camRot      = vector3(rotX, 0.0, rotZ)

        state.textPos     = state.camPos + rotationToForwardVector(state.camRot) * state.entityDistance
        state.textHeading = state.camRot.z
    else
        
        local pedPos      = GetEntityCoords(ped)
        local pedHeading  = GetEntityHeading(ped)

        state.camPos      = vector3(pedPos.x, pedPos.y, pedPos.z + 2.0)
        state.camRot      = vector3(-20.0, 0.0, pedHeading)
        state.textPos     = state.camPos + rotationToForwardVector(state.camRot) * state.entityDistance
        state.textHeading = 0.0
    end

    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)
    DisplayRadar(false)
    DisplayHud(false)

    state.camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(state.camera, state.camPos.x, state.camPos.y, state.camPos.z)
    SetCamRot(state.camera, state.camRot.x, state.camRot.y, state.camRot.z, 2)
    SetCamActive(state.camera, true)
    RenderScriptCams(true, false, 0, true, false)

    setupDui(opts)

    SendNUIMessage({ type = "textPlacementActive", active = true })

    Citizen.CreateThread(function()
        
        Citizen.Wait(50)

        local dx = state.camPos.x - state.textPos.x
        local dy = state.camPos.y - state.textPos.y
        state.textHeading = math.deg(math.atan(dx, dy))

        local lastTime = GetGameTimer()

        while state.isActive do
            Citizen.Wait(0)

            DisableControlAction(0, 1, true)  
            DisableControlAction(0, 2, true)  
            DisableControlAction(0, 24, true) 
            DisableControlAction(0, 25, true) 
            DisableControlAction(0, 30, true) 
            DisableControlAction(0, 31, true) 
            DisableControlAction(0, 37, true) 
            DisableControlAction(0, 22, true) 
            DisableControlAction(0, 36, true) 

            local now      = GetGameTimer()
            local dt       = (now - lastTime) / 1000.0
            lastTime       = now

            local mouseX   = GetDisabledControlNormal(0, 1) * state.mouseSensitivity
            local mouseY   = GetDisabledControlNormal(0, 2) * state.mouseSensitivity

            state.camRot   = vector3(
                math.max(-89.0, math.min(89.0, state.camRot.x - mouseY)),
                0.0,
                state.camRot.z - mouseX
            )

            local speed    = IsDisabledControlPressed(0, 21) and state.fastSpeed or state.baseSpeed
            local moveDist = speed * dt

            local fwd      = rotationToForwardVector(state.camRot)
            local right    = rotationToRightVector(state.camRot)

            if IsDisabledControlPressed(0, 32) then 
                state.camPos = state.camPos + fwd * moveDist
            end
            if IsDisabledControlPressed(0, 33) then 
                state.camPos = state.camPos - fwd * moveDist
            end
            if IsDisabledControlPressed(0, 34) then 
                state.camPos = state.camPos - right * moveDist
            end
            if IsDisabledControlPressed(0, 35) then 
                state.camPos = state.camPos + right * moveDist
            end

            if IsDisabledControlPressed(0, 22) then
                state.camPos = state.camPos + vector3(0.0, 0.0, moveDist)
            end
            if IsDisabledControlPressed(0, 36) then
                state.camPos = state.camPos - vector3(0.0, 0.0, moveDist)
            end

            if IsDisabledControlPressed(0, 241) then 
                state.entityDistance = math.min(state.entityDistance + 0.5, state.maxDistance)
            end
            if IsDisabledControlPressed(0, 242) then 
                state.entityDistance = math.max(state.entityDistance - 0.5, state.minDistance)
            end

            if IsDisabledControlPressed(0, 44) then 
                state.textHeading = state.textHeading + 90.0 * dt
            end
            if IsDisabledControlPressed(0, 38) then 
                state.textHeading = state.textHeading - 90.0 * dt
            end

            SetCamCoord(state.camera, state.camPos.x, state.camPos.y, state.camPos.z)
            SetCamRot(state.camera, state.camRot.x, state.camRot.y, state.camRot.z, 2)

            state.textPos = state.camPos + rotationToForwardVector(state.camRot) * state.entityDistance

            drawTextQuad(state.textPos)

            SendNUIMessage({
                type = "coordsUpdate",
                pos  = { x = state.camPos.x, y = state.camPos.y, z = state.camPos.z },
                rot  = { x = state.camRot.x, y = state.camRot.y, z = state.camRot.z },
                fov  = GetCamFov(state.camera) or 50.0,
            })

            if IsControlJustReleased(0, 191) then
                local normalizedHeading = state.textHeading % 360.0
                if normalizedHeading < 0 then
                    normalizedHeading = normalizedHeading + 360.0
                end

                local result = {
                    x       = state.textPos.x,
                    y       = state.textPos.y,
                    z       = state.textPos.z,
                    heading = normalizedHeading,
                    rx      = 0.0,
                    ry      = 0.0,
                }

                cleanup()

                if state.callback then
                    state.callback(result)
                end

                return
            end

            if IsControlJustReleased(0, 177) then
                cleanup()

                if state.callback then
                    state.callback(nil)
                end

                return
            end
        end
    end)
end

function TextPlacement.Stop()
    if not state.isActive then return end

    cleanup()

    if state.callback then
        state.callback(nil)
    end
end

