editing = false
deleting = false
Point1 = false
Point2 = false
ActivePosters = {}
CurrentPoster = {}
GLOBAL_COORDS = nil
TXD = nil 
PlayerData = {}

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    loadData()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        loadData()
    end
end)


local function GetPlayerData()
    return ESX.GetPlayerData()
end

function loadData()
    PlayerData = GetPlayerData()
    ESX.TriggerServerCallback("posters:getImages", function(images) 
        for k,v in pairs(images) do
            DUILoaded = false
            v.duiObj = CreateDui(string.format("https://cfx-nui-%s/web/dist/index.html", GetCurrentResourceName()), v.width, v.height)
            v.duiHandle = GetDuiHandle(v.duiObj)
            v.txd = CreateRuntimeTxd(v.textureid)
            v.texture = CreateRuntimeTextureFromDuiHandle(v.txd, v.txn, v.duiHandle)
            v.pointA = vector3(v.pointA.x, v.pointA.y, v.pointA.z)
            v.pointB = vector3(v.pointB.x, v.pointB.y, v.pointB.z)
            while not DUILoaded do Wait(0) end
            SendDuiMessage(v.duiObj, json.encode({
                action = "setDUIVariables",
                imageSrc = v.url,
                width = v.width,
                height = v.height,
            }))
            ActivePosters[#ActivePosters+1] = v
            Wait(1000)
        end 
    end)
end

RegisterNetEvent("posters:deleteClientImage", function(id)
    for k,v in pairs(ActivePosters) do
        if v.id == id then
            DestroyDui(v.duiObj)
            table.remove(ActivePosters, k)
            break
        end
    end
end)

RegisterNetEvent("posters:sendAddedImage", function(newImage)
    DUILoaded = false
    newImage.duiObj = CreateDui(string.format("https://cfx-nui-%s/web/dist/index.html", GetCurrentResourceName()), newImage.width, newImage.height)
    newImage.duiHandle = GetDuiHandle(newImage.duiObj)
    newImage.txd = CreateRuntimeTxd(newImage.textureid)
    newImage.texture = CreateRuntimeTextureFromDuiHandle(newImage.txd, newImage.txn, newImage.duiHandle)
    while not DUILoaded do Wait(0) end
    SendDuiMessage(newImage.duiObj, json.encode({
        action = "setDUIVariables",
        imageSrc = newImage.url,
        width = newImage.width,
        height = newImage.height,
    }))
    ActivePosters[#ActivePosters+1] = newImage
end)

function DrawSelectedArea(PointA, PointB, minZ, maxZ, r, g, b, a)
	DrawPoly(PointB.x, PointB.y, minZ, PointB.x, PointB.y, maxZ, PointA.x, PointA.y, maxZ, r, g, b, a)
	DrawPoly(PointB.x, PointB.y, minZ, PointA.x, PointA.y, maxZ, PointA.x, PointA.y, minZ, r, g, b, a)
end

function DrawImageOnArea(PointA, PointB, minZ, maxZ, r, g, b, a, texture, dict)
	DrawSpritePoly(PointB.x, PointB.y, minZ, PointB.x, PointB.y, maxZ, PointA.x, PointA.y, maxZ, r, g, b, a, texture, dict, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0)
	DrawSpritePoly(PointA.x, PointA.y, maxZ, PointA.x, PointA.y, minZ, PointB.x, PointB.y, minZ, r, g, b, a, texture, dict, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0)
end

function PlaceImage(admin)
    TriggerEvent("null:inventory:closeinv")
    editing = true
    Point1 = false
    local dist = 6.0
    Point2 = false
    CurrentPoster = {}
    if admin then
        lib.showTextUI(
            '[E]     - Selectionner le point de départ  \n' ..
            '[Y]     - Rapprocher le point de vous  \n' ..
            '[U]     - Eloigner le point de vous  \n'
        )
        exports["Null"]:DisplayHud(false)
    else
        lib.showTextUI("[E] Selectionner le point de départ", {
            icon = 'fas fa-hand-pointer',
            position = 'left-center', 
        })
    end
    while editing do
        DisableControlAction(0, 38, true)
        if admin then
            local start,fin = null.fct.game.GetCoordsInFrontOfCam(dist, 5000)
            if IsControlPressed(0, 246) then
                dist -= 0.1
            end
            if IsControlPressed(0, 303) then
                dist += 0.1
            end
            DrawSphere(start, 0.06, 0, 255, 0, 0.5)
            if not Point1 then
                if IsDisabledControlJustReleased(0, 38) then
                    lib.hideTextUI()
                    Point1 = start
                    Point2 = start
                    Wait(100)
                    lib.showTextUI("[E] Selectionner le point de fin", {
                        icon = 'fas fa-hand-pointer',
                        position = 'left-center',
                    })
                end
            end
            if Point2 then
                Point2 = start
                if IsDisabledControlJustReleased(0, 38) then
                    editing = false
                end
            end
            if Point1 then
                DrawSelectedArea(Point1, Point2, Point2.z, Point1.z, 0, 155, 0, 80)
            end
        else
            local start,fin = null.fct.game.GetCoordsInFrontOfCam(0, 5000)
            local ray = StartShapeTestRay(start.x, start.y, start.z, fin.x, fin.y, fin.z, 4294967295, cache.ped, 5000)
            local _ray,hit,pos,norm,ent = GetShapeTestResult(ray)
            if hit then
                DrawSphere(pos, 0.06, 0, 255, 0, 0.5)
                if not Point1 then
                    if IsDisabledControlJustReleased(0, 38) then
                        lib.hideTextUI()
                        Point1 = pos
                        Point2 = pos
                        Wait(100)
                        lib.showTextUI("[E] Selectionner le point de fin", {
                            icon = 'fas fa-hand-pointer',
                            position = 'left-center',
                        })
                    end
                end
                if Point2 then
                    Point2 = pos
                    if IsDisabledControlJustReleased(0, 38) then
                        editing = false
                    end
                end
            end
            if Point1 then
                DrawSelectedArea(Point1, Point2, Point2.z, Point1.z, 0, 155, 0, 80)
            end
        end
        Wait(0)
    end
    exports["Null"]:DisplayHud(true)
    lib.hideTextUI()
    if (#(Point1 - Point2) < 50.0) or admin then
        CurrentPoster.pointA = Point1
        CurrentPoster.pointB = Point2
        if admin then
            CurrentPoster.renderDist = 300.0 
        end
        SendNUIMessage({ action = "openEditor" })
        SetNuiFocus(true, true)
    else
        lib.notify({
            title = 'Posters',
            description = 'Le poster est trop grand !',
            type = 'error'
        })
    end
end

function DeleteImage()
    deleting = true
    lib.showTextUI("[E] Selectionner le poster", {
        icon = 'fas fa-hand-pointer',
        position = 'left-center', 
    })
    while deleting do
        DisableControlAction(0, 38, true)
        local start,fin = null.fct.game.GetCoordsInFrontOfCam(0, 5000)
        local ray = StartShapeTestRay(start.x, start.y, start.z, fin.x, fin.y, fin.z, 4294967295, cache.ped, 5000)
        local _ray,hit,pos,norm,ent = GetShapeTestResult(ray)
        if hit then
            DrawSphere(pos, 0.06, 0, 255, 0, 0.5)
            if IsDisabledControlJustReleased(0, 38) then
                deleting = false
                lib.hideTextUI()
                local closestDist, currentKey = 999.9, 1
                local currentPoster = nil
                for k,v in pairs(ActivePosters) do
                    if #(pos - v.pointA) < closestDist then
                        closestDist = #(pos - v.pointA)
                        currentKey = v.id
                        currentPoster = v
                    end
                    if #(pos - v.pointB) < closestDist then
                        closestDist = #(pos - v.pointB)
                        currentKey = v.id
                        currentPoster = v
                    end
                end
                if closestDist < 10 then
                    if lib.progressCircle({
                        label = 'Removing Poster...',
                        duration = 10000,
                        position = "bottom",
                        useWhileDead = false,
                        canCancel = true,
                        disable = {car = true, move = true, combat = true},
                        anim = { dict = 'mini@repair', clip = 'fixing_a_ped' },
                    }) then
                        TriggerServerEvent("posters:deleteImage", currentKey, PlayerData.identifier == currentPoster.cid)
                    else
                        lib.notify({
                            title = 'Posters',
                            description = "Menu deletion canceled.",
                            type = "error",
                        })
                    end
                else
                    lib.notify({
                        title = 'Posters',
                        description = "Could not find an poster close enough to delete. Please try again",
                        type = "error",
                    })
                end
            end
        end
        Wait(0)
    end
end

RegisterNUICallback("exit", function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNuiCallback('loaded', function(_, cb)
    DUILoaded = true
    cb({resName = GetCurrentResourceName()})
end)

RegisterNUICallback("savePoster", function(data, cb)
    SetNuiFocus(false, false)
    CurrentPoster.url = data.url
    CurrentPoster.width = data.width
    CurrentPoster.height = data.height
    CurrentPoster.id = math.random(999999, 999999999)
    CurrentPoster.cid = PlayerData.identifier
    CurrentPoster.textureid = "newtexture"..tostring(math.random(1, 100000))
    CurrentPoster.txn = "newtexture"..tostring(math.random(1, 100000))
    TriggerServerEvent("posters:addNewImage", CurrentPoster)
    cb('ok')
end)

CreateThread(function()
    while true do
        local sleep = 1500
        local coords = GetEntityCoords(cache.ped)
        for k,v in pairs(ActivePosters) do
            local renderdist = Config.Posters.RenderDistance
            if v.renderDist then 
                renderdist = v.renderDist 
            end
            if #(coords - v.pointA) < renderdist or #(coords - v.pointB) < renderdist then
                sleep = 0
                DrawImageOnArea(v.pointA, v.pointB, v.pointB.z, v.pointA.z, 255, 255, 255, 255, v.textureid, v.txn)
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent("posters:placeImage", function(admin)
    PlaceImage(admin)
end)

RegisterNetEvent("posters:removePoster", function()
	DeleteImage()
end)