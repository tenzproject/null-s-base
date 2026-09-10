local contextMenuOpen = false
local contextMenuActive = false
local buttonPressed = false
local recevieClose = nil
local contextMenuControlsThread = nil

function StartContextMenuControlsThread()
    if contextMenuControlsThread then return end
    contextMenuControlsThread = CreateThread(LPH_NO_VIRTUALIZE(function()
        while contextMenuOpen do
            Wait(0)
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 135, true) -- VehicleSubDescend
            DisableControlAction(0, 223, true) -- VehicleExit
            DisableControlAction(0, 257, true) -- AttackAlternate
            DisableControlAction(0, 18, true)  -- Enter
            DisableControlAction(0, 322, true) -- ESC
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
        end
    end))
end

function DeleteContextMenuControlsThread()
    if not contextMenuControlsThread then return end
    contextMenuControlsThread = nil
end

local function TargetCoords(screenPosition, maxDistance, flags, ignoreEntity)
    local pos = GetGameplayCamCoord()
    local rot = GetGameplayCamRot(0)
    local fov = GetGameplayCamFov()
    local cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, fov, 0, 2)
    local camRight, camForward, camUp, camPos = GetCamMatrix(cam)
    DestroyCam(cam, true)
    screenPosition = vector2(screenPosition.x - 0.5, screenPosition.y - 0.5) * 2.0
    local fovRadians = (fov * 3.14) / 180.0
    local resX, resY = GetActiveScreenResolution()
    local to = camPos + camForward + (camRight * screenPosition.x * fovRadians * (resX / resY) * 0.534375) - (camUp * screenPosition.y * fovRadians * 0.534375)
    local direction = (to - camPos) * maxDistance
    local endPoint = camPos + direction
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(camPos.x, camPos.y, camPos.z, endPoint.x, endPoint.y, endPoint.z, flags or -1, ignoreEntity or 0, 0)
    local _, hit, worldPosition, normalDirection, materialHash, entity = GetShapeTestResultIncludingMaterial(rayHandle)
    if hit == 1 then
        return true, worldPosition, normalDirection, entity, materialHash
    else
        return false, vector3(0, 0, 0), vector3(0, 0, 0), nil, materialHash
    end
end

local function OpenContextMenuAtCursor(data)
    if not data or not data.items or #data.items == 0 then
        return
    end

    local cursorX, cursorY = GetNuiCursorPosition()
    local screenWidth, screenHeight = GetActiveScreenResolution()
    local posX = (cursorX / screenWidth) * 1920
    local posY = (cursorY / screenHeight) * 1080

    SendNUIMessage({
        action = 'openContextMenu',
        data = {
            title = data.title,
            items = data.items,
            position = { x = posX, y = posY },
            entityType = data.entityType
        }
    })

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    contextMenuOpen = true
    
    StartContextMenuControlsThread()
end

function CloseContextMenu(keepNuiFocus)
    if not contextMenuOpen then return end

    SendNUIMessage({
        action = 'closeContextMenu'
    })

    --if not keepNuiFocus then
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    --end

    contextMenuOpen = false
    
    DeleteContextMenuControlsThread()
end

function IsContextMenuOpen()
    return contextMenuOpen
end

AddEventHandler('contextmenu:setOpen', function(state)
    contextMenuOpen = state
end)

RegisterNUICallback('contextMenuAction', function(data, cb)
    if data.action then
        TriggerEvent('contextmenu:action', data.action, data.checked)
    end
    cb('ok')
end)

RegisterNUICallback('contextMenuClosed', function(data, cb)
    local keepNuiFocus = data.keepNuiFocus or false
    CloseContextMenu(keepNuiFocus)
    recevieClose = GetGameTimer()
    SendNUIMessage({action = "hideFocus"})
    cb('ok')
end)

RegisterKeyMapping('+contextmenu', 'Menu Contextuel', 'keyboard', 'LMENU')

RegisterCommand('+contextmenu', function()
    SetCursorLocation(0.5, 0.5)
    buttonPressed = true
end)

RegisterCommand('-contextmenu', function()
    buttonPressed = false
    -- Fermer le menu quand ALT est relâché
    if contextMenuOpen then
        CloseContextMenu()
    end
end)


CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        Wait(0)
        
        if buttonPressed and not contextMenuOpen then
            contextMenuActive = true
            SetMouseCursorActiveThisFrame()
            
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 68, true)
            DisableControlAction(0, 69, true)
            DisableControlAction(0, 70, true)
            DisableControlAction(0, 91, true)
            DisableControlAction(0, 92, true)
            
            if IsDisabledControlJustPressed(0, 24) then
                local screenPosition = vector2(GetControlNormal(0, 239), GetControlNormal(0, 240))
                local hitSomething, worldPosition, normalDirection, hitEntity, materialHash = TargetCoords(screenPosition, 10000.0)
                
                local playerPed = PlayerPedId()
            
                -- Si on est dans un véhicule et que le raycast n'a rien touché
                if IsPedInAnyVehicle(playerPed, false) and not hitSomething then
                    hitEntity = GetVehiclePedIsIn(playerPed, false)
                    hitSomething = true
                end
                
                TriggerEvent('contextmenu:openMenu', hitEntity, worldPosition, hitSomething)
            end
        elseif contextMenuActive and not buttonPressed and not contextMenuOpen then
            contextMenuActive = false
        end
    end
end))

exports('CloseContextMenu', CloseContextMenu)
exports('IsContextMenuOpen', IsContextMenuOpen)

_G.CloseContextMenu = CloseContextMenu
_G.IsContextMenuOpen = IsContextMenuOpen

-- Helper function to create menu items
function CreateContextMenuItem(itemType, label, action, options)
    options = options or {}
    
    return {
        type = itemType,
        label = label,
        action = action,
        description = options.description,
        icon = options.icon,
        checked = options.checked,
        disabled = options.disabled,
        closeOnClick = options.closeOnClick,
        keepNuiFocus = options.keepNuiFocus,
        items = options.items
    }
end

exports('CreateContextMenuItem', CreateContextMenuItem)
_G.CreateContextMenuItem = CreateContextMenuItem

CreateThread(function()
    null.InitPrint("Context Menu Module Loaded successfully")
end)
