local url = "nui://fb_fuel/ui/index.html"
local scale = 0.15
local sfName = 'generic_texture_renderer'

local width = 1900
local height = 1000

local displayPosX = 0
local displayPosY = 0
local displayPosZ = 0
local rota = 0

local sfHandle = nil
local txdHasBeenSet = false
local duiObj = nil
local displayPos = nil
local forwardPoint = nil 
local isDisplayed = false
local entityHeading = 0
local isFueling = false
local price = 0
local fuel = 0

local function playerPed()
    return PlayerPedId()
end

local function GetFrontOfEntity(entity, distance)
    local coords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity)
    local rad = math.rad(heading)
    local offsetX = distance * math.sin(rad)
    local offsetY = distance * math.cos(rad)
    return vector3(coords.x + offsetX, coords.y + offsetY, coords.z)
end

local function IsPlayerInFrontOfStation(playerCoords, stationCoords, stationForwardPoint) 
    if not playerCoords or not stationCoords or not stationForwardPoint then
        return "jsp"
    end

    local forwardVector = stationForwardPoint - stationCoords
    forwardVector = forwardVector / #forwardVector

    local dirToPlayer = playerCoords - stationCoords
    dirToPlayer = dirToPlayer / #dirToPlayer 

    local dot = forwardVector.x * dirToPlayer.x + forwardVector.y * dirToPlayer.y               

    if dot > 0.3 then
        return "front"
    elseif dot < -0.3 then
        return "back"
    else
        return "side"
    end
end

local function loadScaleform(scaleform)
    local scaleformHandle = RequestScaleformMovie(scaleform)
    while not HasScaleformMovieLoaded(scaleformHandle) do
        Citizen.Wait(0)
    end
    return scaleformHandle
end
 
local function cleanupDUI()
    if duiObj then 
        DestroyDui(duiObj)
        duiObj = nil
    end
    if sfHandle then 
        SetScaleformMovieAsNoLongerNeeded(sfHandle)
        sfHandle = nil
    end
    txdHasBeenSet = false
    displayPos = nil
    forwardPoint = nil
    isDisplayed = false
end

CreateThread(function() 
    Wait(500)
    cleanupDUI()
    
    while true do  
        if isDisplayed then  
            local playerPed = playerPed()
            local playerCoords = GetEntityCoords(playerPed)
             
            if sfHandle and displayPos and forwardPoint then
                if not txdHasBeenSet then
                    PushScaleformMovieFunction(sfHandle, 'SET_TEXTURE')
                    PushScaleformMovieMethodParameterString('meows')
                    PushScaleformMovieMethodParameterString('woof')
                    PushScaleformMovieFunctionParameterInt(0)
                    PushScaleformMovieFunctionParameterInt(0)
                    PushScaleformMovieFunctionParameterInt(width)
                    PushScaleformMovieFunctionParameterInt(height)
                    PopScaleformMovieFunctionVoid()
                    txdHasBeenSet = true
                end

                local positionRelative = IsPlayerInFrontOfStation(playerCoords, displayPos, forwardPoint)

                local offset = vector3(-2.7, -0.3, 2.3) 
                local rota = 360 - entityHeading

                if positionRelative == 'back' then
                    offset = vector3(2.7, 0.35, 2.3) 
                    rota = 180 - entityHeading
                end
     
                local headingRad = math.rad(entityHeading)
                local rotatedX = offset.x * math.cos(headingRad) - offset.y * math.sin(headingRad)
                local rotatedY = offset.x * math.sin(headingRad) + offset.y * math.cos(headingRad)

                displayPosX = rotatedX
                displayPosY = rotatedY
                displayPosZ = offset.z 

                DrawScaleformMovie_3dNonAdditive(
                    sfHandle,
                    (displayPos.x + tonumber(displayPosX)), 
                    (displayPos.y + tonumber(displayPosY)), 
                    (displayPos.z + tonumber(displayPosZ)),
                    0.0, 0.0, (0.0 + tonumber(rota)),
                    0.0, 0.0, 0.0,
                    scale, scale * (9 / 16),
                    1, 2
                )
            end
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
                type = "updateGasStation",
                price = price or 0,
                fuel = fuel or 0
            }))
            Wait(100)  
        else
            Wait(500)  
        end
    end
end)
 
RegisterNUICallback("closeUI", function(_, cb)
    cleanupDUI()
    cb({})
end)  

RegisterNetEvent('Start3DFuelStation', function(entity, newPrice, newFuel)
    cleanupDUI()
    
    if not entity or not DoesEntityExist(entity) then
        print("Entity invalide pour Start3DFuelStation")
        return
    end

    price = newPrice or 0
    fuel = newFuel or 0
    
    sfHandle = loadScaleform(sfName)
    local txd = CreateRuntimeTxd("meows")
    duiObj = CreateDui(url .. ("?price=%s&fuel=%s"):format(price, fuel), width, height)
    local dui = GetDuiHandle(duiObj)
    CreateRuntimeTextureFromDuiHandle(txd, "woof", dui)

    local coords = GetEntityCoords(entity)
    displayPos = vector3(coords.x, coords.y, coords.z + 1.0)
    forwardPoint = GetFrontOfEntity(entity, 2.0)
    entityHeading = GetEntityHeading(entity)
    
    isDisplayed = true
 
    Wait(200)
 
    SendDuiMessage(duiObj, json.encode({
        type = "updateGasStation",
        price = (price+3) or 0,
        fuel = fuel or 0
    }))
end) 

RegisterNetEvent("StopFuelStation", function() 
    isFueling = false
    
    if duiObj then
        SendDuiMessage(duiObj, json.encode({
            type = "hideGasStation"
        })) 
        Citizen.SetTimeout(500, function()
            cleanupDUI()
        end)
    else
        cleanupDUI()
    end
end)

RegisterNetEvent("UpdateFuelStation", function(newPrice, newFuel, obj)
    price = newPrice or price
    fuel = newFuel or fuel
    
    if obj then
        isFueling = true
    end

    if duiObj then
        SendDuiMessage(duiObj, json.encode({
            type = "updateGasStation",
            price = (price+3) or 0,
            fuel = fuel or 0
        })) 
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then
        cleanupDUI()
    end
end)