local cfgE = Config.FreeJobs.Entrepot
local entrepotZone = vector3(cfgE.PedCoords.x, cfgE.PedCoords.y, cfgE.PedCoords.z + 1.0)
local entrepotPed = nil
local IsWorkingCariste = false
local entrepotBonus = 0
local entrepotCount = 0
local needSellingPalette = false
local palette_type = nil
local PaletteBlip = nil
local PaletteSpawned = {}
local deliveryBlip = nil
local currentForklift = nil
local infoPanelOpen = false
local infoPanelDistLimit = 15.0

local function entrepotLoadAnimDict(dict)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
end

local function SpawnMarchandise()
    local random = math.random(1, #cfgE.SpawnPalettes)
    local v = cfgE.SpawnPalettes[random]
    
    if DoesObjectOfTypeExistAtCoords(v.pos, 1.0, GetHashKey(v.props), true) then
        for _, sp in pairs(cfgE.SpawnPalettes) do
            if not DoesObjectOfTypeExistAtCoords(sp.pos, 1.0, GetHashKey(sp.props), true) then
                v = sp
                break
            end
        end
    end

    RequestModel(GetHashKey(v.props))
    while not HasModelLoaded(GetHashKey(v.props)) do Wait(1) end

    palette_type = CreateObject(GetHashKey(v.props), v.pos.x, v.pos.y, v.pos.z, false, true, true)
    SetEntityHeading(palette_type, v.pos.w)
    SetEntityAsMissionEntity(palette_type, true, true)
    ObjToNet(palette_type)

    if PaletteBlip then RemoveBlip(PaletteBlip) end
    PaletteBlip = AddBlipForEntity(palette_type)
    SetBlipSprite(PaletteBlip, cfgE.PaletteBlip.Sprite)
    SetBlipColour(PaletteBlip, cfgE.PaletteBlip.Color)
    SetBlipScale(PaletteBlip, cfgE.PaletteBlip.Scale)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(cfgE.PaletteBlip.Label)
    EndTextCommandSetBlipName(PaletteBlip)

    local markerId = 'palette_' .. palette_type
    SendNUIMessage({ action = 'freejobMarker:add', data = { id = markerId, x = v.pos.x, y = v.pos.y, z = v.pos.z + cfgE.MarkerOffset, label = 'Palette' } })

    table.insert(PaletteSpawned, { id = palette_type, x = v.pos.x, y = v.pos.y, z = v.pos.z, h = v.pos.w, markerId = markerId, pickedUp = false })
end

local function WorkingCariste()
    local waitboucle = 0
    while IsWorkingCariste do
        Wait(waitboucle)
        for index, value in pairs(PaletteSpawned) do
            if DoesEntityExist(value.id) then
                local coordsply = GetEntityCoords(PlayerPedId())
                local palettecoords = GetEntityCoords(value.id)
                local dstToMarker = #(coordsply - palettecoords)

                if dstToMarker < 50 and IsWorkingCariste then
                    waitboucle = 1
                    -- Update React marker screen position
                    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(palettecoords.x, palettecoords.y, palettecoords.z + cfgE.MarkerOffset)
                    SendNUIMessage({ action = 'freejobMarker:screenPos', data = { [value.markerId] = { x = sx, y = sy, visible = onScreen } } })

                    -- Auto-detect when palette is picked up (lifted by forklift)
                    if not value.pickedUp and IsWorkingCariste then
                        local playerVeh = GetVehiclePedIsIn(PlayerPedId(), false)
                        if playerVeh ~= 0 and playerVeh == currentForklift then
                            local isAttached = IsEntityAttachedToEntity(value.id, playerVeh) or GetEntityHeightAboveGround(value.id) > value.z + 0.5
                            if isAttached or palettecoords.z > value.z + 0.3 then
                                value.pickedUp = true
                                SendNUIMessage({ action = 'freejobMarker:remove', data = { id = value.markerId } })
                                if PaletteBlip then RemoveBlip(PaletteBlip) PaletteBlip = nil end
                                needSellingPalette = true
                                break
                            end
                        end
                    end
                else
                    waitboucle = 300
                end
            else
                -- Entity disappeared
                local lastdriven = GetLastDrivenVehicle(PlayerPedId())
                if DoesEntityExist(lastdriven) then DeleteEntity(lastdriven) end
                SendNUIMessage({ action = 'freejobMarker:remove', data = { id = value.markerId } })
                table.remove(PaletteSpawned, index)
                if palette_type and DoesEntityExist(palette_type) then DeleteEntity(palette_type) end
                needSellingPalette = false
                ESX.ShowNotification("~r~Vous vous êtes éloigné de l'entrepôt !")
                if deliveryBlip then RemoveBlip(deliveryBlip) deliveryBlip = nil end
                IsWorkingCariste = false
                break
            end

            -- Delivery phase with marker UI
            if needSellingPalette and value.pickedUp then
                local random2 = math.random(1, #cfgE.DeliveryQuai)
                local deliveryPos = cfgE.DeliveryQuai[random2].pos
                local deliveryMarkerId = 'delivery_quai'

                -- Create delivery blip
                deliveryBlip = AddBlipForCoord(deliveryPos)
                SetBlipSprite(deliveryBlip, cfgE.DeliveryBlip.Sprite)
                SetBlipColour(deliveryBlip, cfgE.DeliveryBlip.Color)
                SetBlipScale(deliveryBlip, cfgE.DeliveryBlip.Scale)
                BeginTextCommandSetBlipName("STRING")
                AddTextComponentString(cfgE.DeliveryBlip.Label)
                EndTextCommandSetBlipName(deliveryBlip)

                SendNUIMessage({ action = 'freejobMarker:add', data = { id = deliveryMarkerId, x = deliveryPos.x, y = deliveryPos.y, z = deliveryPos.z + cfgE.MarkerOffset, label = 'Quai de livraison' } })

                while needSellingPalette and IsWorkingCariste do
                    local propsCoords2 = GetEntityCoords(value.id)
                    local dstToQuai = #(deliveryPos - propsCoords2)
                    local dstPlayerToQuai = #(GetEntityCoords(PlayerPedId()) - deliveryPos)
                    
                    local onScreen, sx, sy = GetScreenCoordFromWorldCoord(deliveryPos.x, deliveryPos.y, deliveryPos.z + cfgE.MarkerOffset)
                    SendNUIMessage({ action = 'freejobMarker:screenPos', data = { [deliveryMarkerId] = { x = sx, y = sy, visible = onScreen and dstPlayerToQuai < 50 } } })
                    
                    if dstToQuai < 3.0 and dstPlayerToQuai < 5.0 then
                        if IsControlJustPressed(0, 51) then 
                            if deliveryBlip then RemoveBlip(deliveryBlip) deliveryBlip = nil end
                            SendNUIMessage({ action = 'freejobMarker:remove', data = { id = deliveryMarkerId } })
                            
                            entrepotCount = entrepotCount + 1
                            if entrepotBonus < 100 then entrepotBonus = entrepotBonus + 1 end

                            local currentReward = math.floor(entrepotCount * (entrepotBonus / 10) * Config.FreeJobs.Rewards.Entrepot)
                            SendNUIMessage({ action = 'freejobHUD:update', data = { tasks = entrepotCount, bonus = entrepotBonus, reward = currentReward } })

                            SendNUIMessage({ action = 'freejobMarker:remove', data = { id = value.markerId } })

                            table.remove(PaletteSpawned, index)
                            DeleteEntity(value.id)
                            needSellingPalette = false

                            SpawnMarchandise()
                            break
                        end
                    end
                    
                    Citizen.Wait(0)
                end

                -- Cleanup
                if deliveryBlip then RemoveBlip(deliveryBlip) deliveryBlip = nil end
                SendNUIMessage({ action = 'freejobMarker:remove', data = { id = deliveryMarkerId } })
                
                -- Break out of the for loop since this palette is delivered
                break
            end
        end
    end
end

local function StartEntrepotJob()
    -- Find parking spot
    local getcoordsveh = nil
    local getheadingveh = nil
    for _, v in pairs(cfgE.PosesParking) do
        if ESX.Game.IsSpawnPointClear(vector3(v.pos.x, v.pos.y, v.pos.z), 3.0) then
            getcoordsveh = vector3(v.pos.x, v.pos.y, v.pos.z)
            getheadingveh = v.pos.w
        end
    end

    if not getcoordsveh then
        ESX.ShowNotification("~r~Toutes les places de parking sont prises !")
        return
    end

    IsWorkingCariste = true
    entrepotCount = 0
    entrepotBonus = 0
    needSellingPalette = false

    -- Spawn forklift
    RequestModel(cfgE.ForkliftModel)
    while not HasModelLoaded(cfgE.ForkliftModel) do Wait(0) end
    local veh = CreateVehicle(cfgE.ForkliftModel, getcoordsveh, getheadingveh, false, true)
    SetVehicleNumberPlateText(veh, cfgE.ForkliftPlate)
    SetModelAsNoLongerNeeded(cfgE.ForkliftModel)

    local PersoCarblip = AddBlipForEntity(veh)
    SetBlipSprite(PersoCarblip, cfgE.ForkliftBlip.Sprite)
    SetBlipColour(PersoCarblip, cfgE.ForkliftBlip.Color)
    ShowHeadingIndicatorOnBlip(PersoCarblip, true)
    SetBlipRotation(PersoCarblip, math.ceil(GetEntityHeading(veh)))
    SetBlipScale(PersoCarblip, cfgE.ForkliftBlip.Scale)
    SetBlipShrink(PersoCarblip, true)
    ShowFriendIndicatorOnBlip(PersoCarblip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(cfgE.ForkliftBlip.Label)
    EndTextCommandSetBlipName(PersoCarblip)

    currentForklift = veh

    -- Apply outfit
    TriggerEvent('Null:skinchanger:getSkin', function(skin)
        TriggerEvent('Null:skinchanger:loadClothes', skin, cfgE.Tenue)
    end)

    -- Open HUD
    SendNUIMessage({ action = 'freejobHUD:open', data = {
        jobName = 'Cariste', jobIcon = 'forklift',
        tasks = 0, bonus = 0, reward = 0,
        rewardPerTask = Config.FreeJobs.Rewards.Entrepot,
    }})

    SpawnMarchandise()
    TriggerServerEvent("Null:jobs:startActivity")
    WorkingCariste()
end

local function CollectEntrepotPay()
    if entrepotCount <= 0 then return end
    entrepotLoadAnimDict('mp_common')
    TaskPlayAnim(entrepotPed, "mp_common", "givetake1_a", 2.0, 2.0, -1, 0, 0, false, false, false)
    local trizomik = math.floor(entrepotCount * (entrepotBonus / 10) * Config.FreeJobs.Rewards.Entrepot)
    TriggerServerEvent("Null:jobs:verifyJob", 2, trizomik)
    CleanupEntrepot()
end

function CleanupEntrepot()
    IsWorkingCariste = false
    entrepotCount = 0
    entrepotBonus = 0
    needSellingPalette = false

    -- Delete forklift using tracked vehicle
    if currentForklift and DoesEntityExist(currentForklift) then
        DeleteEntity(currentForklift)
        currentForklift = nil
    end

    -- Delete palettes + markers
    for _, s in pairs(PaletteSpawned) do
        SendNUIMessage({ action = 'freejobMarker:remove', data = { id = s.markerId } })
        if DoesEntityExist(s.id) then DeleteEntity(s.id) end
    end
    PaletteSpawned = {}
    SendNUIMessage({ action = 'freejobMarker:remove', data = { id = 'delivery_quai' } })

    if palette_type and DoesEntityExist(palette_type) then DeleteEntity(palette_type) end
    palette_type = nil
    if PaletteBlip then RemoveBlip(PaletteBlip) PaletteBlip = nil end
    if deliveryBlip then RemoveBlip(deliveryBlip) deliveryBlip = nil end

    -- Close HUDs and Info Panel
    SendNUIMessage({ action = 'freejobHUD:close' })
    SendNUIMessage({ action = 'freejobInfo:close' })
    SetNuiFocus(false, false)
    infoPanelOpen = false
    ClearPedTasks(PlayerPedId())

    -- Restore skin
    ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin, jobSkin)
        local isMale = skin.sex == 0
        TriggerEvent('Null:skinchanger:loadDefaultModel', isMale, function()
            ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin2)
                TriggerEvent('Null:skinchanger:loadSkin', skin2)
                TriggerEvent('esx:restoreLoadout')
            end)
        end)
    end)
end

-- NUI callback for closing info panel
RegisterNUICallback('freejobInfo:close', function(_, cb)
    SetNuiFocus(false, false)
    infoPanelOpen = false
    cb('ok')
end)

-- Info panel distance check - close if too far
Citizen.CreateThread(function()
    while true do
        Wait(1000)
        if infoPanelOpen then
            local dist = #(GetEntityCoords(PlayerPedId()) - entrepotZone)
            if dist > infoPanelDistLimit then
                SendNUIMessage({ action = 'freejobInfo:close' })
                SetNuiFocus(false, false)
                infoPanelOpen = false
            end
        end
    end
end)

-- Water check thread
Citizen.CreateThread(function()
    while true do
        Wait(300)
        if IsWorkingCariste and palette_type and DoesEntityExist(palette_type) then
            if IsEntityInWater(palette_type) then
                ESX.ShowNotification("~r~Mission échouée\nVous avez fait tomber la marchandise dans l'eau !")
                CleanupEntrepot()
            end
        end
    end
end)

-- Spawn PED + 3D Interaction
Citizen.CreateThread(function()
    local ped = cfgE.PedModel
    RequestModel(ped)
    while not HasModelLoaded(ped) do Wait(100) end
    entrepotPed = CreatePed(0, ped, cfgE.PedCoords.x, cfgE.PedCoords.y, cfgE.PedCoords.z, cfgE.PedCoords.w, false, false)
    SetBlockingOfNonTemporaryEvents(entrepotPed, true)
    TaskStartScenarioInPlace(entrepotPed, cfgE.PedScenario, 0, true)
    SetEntityInvincible(entrepotPed, true)
    FreezeEntityPosition(entrepotPed, true)

    -- 3D Interaction
    Add3DInteraction({
        id = 'freejob_entrepot',
        coords = entrepotZone,
        maxDistance = 8.0,
        maxDistance2 = 2.5,
        type = 'multi',
        text = {
            title = "Gérant de l'entrepôt",
            lines = {
                {
                    id = 'start',
                    left = 'Commencer le travail',
                    key = 'E',
                    action = function()
                        if IsWorkingCariste then return end
                        Citizen.CreateThread(function()
                            StartEntrepotJob()
                        end)
                    end,
                    canSee = function(cb) cb(not IsWorkingCariste) end,
                },
                {
                    id = 'paye',
                    left = 'Prendre sa paye',
                    key = 'E',
                    action = function()
                        if not IsWorkingCariste then return end
                        CollectEntrepotPay()
                    end,
                    canSee = function(cb) cb(IsWorkingCariste and entrepotCount > 0) end,
                },
                {
                    id = 'quit',
                    left = 'Quitter le travail',
                    key = 'G',
                    action = function()
                        if not IsWorkingCariste then return end
                        CleanupEntrepot()
                    end,
                    canSee = function(cb) cb(IsWorkingCariste) end,
                },
                {
                    id = 'commandes',
                    left = 'Voir les commandes',
                    key = 'E',
                    action = function()
                        if not IsWorkingCariste then return end
                        local dist = #(GetEntityCoords(PlayerPedId()) - entrepotZone)
                        if dist > infoPanelDistLimit then
                            ESX.ShowNotification("~r~Trop loin pour voir les commandes!")
                            return
                        end
                        SendNUIMessage({ action = 'freejobInfo:open', data = {
                            title = 'Entrepôt - Commandes',
                            lines = cfgE.InfoCommandes,
                        }})
                        SetNuiFocus(true, true)
                        infoPanelOpen = true
                    end,
                    canSee = function(cb) cb(IsWorkingCariste) end,
                },
            },
        },
    })
end)
