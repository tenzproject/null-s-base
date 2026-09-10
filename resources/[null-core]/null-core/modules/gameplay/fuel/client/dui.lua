local url = "nui://null-core/modules/_core/ui/html/3dui-fuel/index.html"
local sfName = 'generic_texture_renderer'
local width = 1900
local height = 1000

DUI_SCALE         = 0.035   -- un peu plus petit
DUI_OFFSET_UP     = 1.28    -- descend le panneau
DUI_OFFSET_SIDE   = 0.75    -- distance vers le joueur (devant la pompe)
DUI_OFFSET_LATERAL = 0.2   -- décalage gauche/droite (negatif = gauche)
DUI_YAW_OFFSET    = 0       -- oriente correctement la face

local sfHandle = nil
local txdHasBeenSet = false
local duiObj = nil
local displayPos = nil
local drawPos = nil
local drawYaw = 0.0
local isDisplayed = false
local isFueling = false
local price = 0
local fuel = 0

local function loadScaleform(scaleform)
    local h = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(h) do Citizen.Wait(0) end
    return h
end

local function cleanupDUI()
    if duiObj then DestroyDui(duiObj); duiObj = nil end
    if sfHandle then
        local h = sfHandle
        SetScaleformMovieAsNoLongerNeeded(h)
        sfHandle = nil
    end
    txdHasBeenSet = false
    displayPos = nil
    drawPos = nil
    drawYaw = 0.0
    isDisplayed = false
end

CreateThread(function()
    Wait(500)
    cleanupDUI()
    while true do
        if isDisplayed and sfHandle and drawPos then
            if not txdHasBeenSet then
                PushScaleformMovieFunction(sfHandle, 'SET_TEXTURE')
                PushScaleformMovieMethodParameterString('NullfuelTxd')
                PushScaleformMovieMethodParameterString('NullfuelTex')
                PushScaleformMovieFunctionParameterInt(0)
                PushScaleformMovieFunctionParameterInt(0)
                PushScaleformMovieFunctionParameterInt(width)
                PushScaleformMovieFunctionParameterInt(height)
                PopScaleformMovieFunctionVoid()
                txdHasBeenSet = true
            end

            DrawScaleformMovie_3dNonAdditive(
                sfHandle,
                drawPos.x, drawPos.y, drawPos.z,
                0.0, 0.0, drawYaw,
                0.0, 0.0, 0.0,
                DUI_SCALE, DUI_SCALE * (height / width),
                1, 2
            )
            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        if isDisplayed and duiObj and isFueling then
            SendDuiMessage(duiObj, json.encode({
                type = "updateFuelStation",
                price = price or 0,
                fuel = fuel or 0
            }))
            Wait(100)
        else
            Wait(500)
        end
    end
end)

RegisterNetEvent('null:fuel:start3DStation', function(entity, newPrice, newFuel)
    print(("[FUEL DUI] start3DStation entity=%s exists=%s price=%s fuel=%s"):format(tostring(entity), tostring(DoesEntityExist(entity)), tostring(newPrice), tostring(newFuel)))
    cleanupDUI()
    if not entity or not DoesEntityExist(entity) then
        print("[FUEL DUI] aborting: invalid entity")
        return
    end
    price = newPrice or 0
    fuel = newFuel or 0

    print("[FUEL DUI] step1: requesting scaleform")
    sfHandle = loadScaleform(sfName)
    print(("[FUEL DUI] step2: scaleform loaded sfHandle=%s"):format(tostring(sfHandle)))
    local txd = CreateRuntimeTxd("NullfuelTxd")
    print(("[FUEL DUI] step3: txd=%s"):format(tostring(txd)))
    local fullUrl = url .. ("?price=%s&fuel=%s"):format(price, fuel)
    duiObj = CreateDui(fullUrl, width, height)
    print(("[FUEL DUI] step4: duiObj=%s url=%s"):format(tostring(duiObj), fullUrl))
    local dui = GetDuiHandle(duiObj)
    print(("[FUEL DUI] step5: duiHandle=%s"):format(tostring(dui)))
    CreateRuntimeTextureFromDuiHandle(txd, "NullfuelTex", dui)
    print("[FUEL DUI] step6: texture created OK")

    local coords = GetEntityCoords(entity)
    displayPos = vector3(coords.x, coords.y, coords.z + 1.0)

    local pc = GetEntityCoords(PlayerPedId())
    local dx, dy = pc.x - displayPos.x, pc.y - displayPos.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 0.01 then len = 0.01 end
    local nx, ny = dx / len, dy / len

    local lx, ly = ny, -nx
    drawPos = vector3(
        displayPos.x + nx * DUI_OFFSET_SIDE + lx * DUI_OFFSET_LATERAL,
        displayPos.y + ny * DUI_OFFSET_SIDE + ly * DUI_OFFSET_LATERAL,
        displayPos.z + DUI_OFFSET_UP
    )
    drawYaw = (math.deg(math.atan2(-dx, dy)) + DUI_YAW_OFFSET) % 360
    isDisplayed = true

    Wait(200)
    SendDuiMessage(duiObj, json.encode({
        type = "updateFuelStation",
        price = price,
        fuel = fuel
    }))
end)

RegisterNetEvent('null:fuel:stop3DStation', function()
    isFueling = false
    if duiObj then
        SendDuiMessage(duiObj, json.encode({ type = "hideFuelStation" }))
        Citizen.SetTimeout(500, cleanupDUI)
    else
        cleanupDUI()
    end
end)

RegisterNetEvent('null:fuel:update3DStation', function(newPrice, newFuel, obj)
    price = newPrice or price
    fuel = newFuel or fuel
    if obj then isFueling = true end
    if duiObj then
        SendDuiMessage(duiObj, json.encode({
            type = "updateFuelStation",
            price = price,
            fuel = fuel
        }))
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then cleanupDUI() end
end)
