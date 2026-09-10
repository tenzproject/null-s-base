-- ============================================================
--  CarRental — Client
--  Menu RageUI avec preview caméra au survol
--  Timer 30min avec UI ShowInfo (comme le jail)
-- ============================================================

local rentalCooldown = false
local previewVehicle = nil
local previewCam = nil
local previewModel = nil
local isRentalMenuOpen = false
local currentLocation = nil
local spawnedPeds = {}

local RENTAL_DURATION = Config.CarRental.duration
local rentalTimer = 0
local rentalActive = false
local rentalVehicle = nil

-- ============================================================
-- Helpers
-- ============================================================

local function requestModel(model)
    if HasModelLoaded(model) then return true end
    RequestModel(model)
    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(50)
    end
    return HasModelLoaded(model)
end

local function clearPreview()
    if previewVehicle and DoesEntityExist(previewVehicle) then
        DeleteEntity(previewVehicle)
    end
    previewVehicle = nil
    previewModel = nil
end

local function destroyPreviewCam()
    if previewCam and DoesCamExist(previewCam) then
        DestroyCam(previewCam, false)
        previewCam = nil
    end
    RenderScriptCams(false, false, 0, true, true)
end

local function startPreviewCam()
    if previewCam and DoesCamExist(previewCam) then return end
    if not currentLocation then return end

    local spawnCoords = currentLocation.SpawnOffset
    local x, y, z = spawnCoords.x, spawnCoords.y, spawnCoords.z
    local camX = x + 3.5
    local camY = y + 3.5
    local camZ = z + 1.5

    previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(previewCam, camX, camY, camZ)
    SetCamRot(previewCam, 0.0, 0.0, 225.0, 2)
    SetCamFov(previewCam, 45.0)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 500, true, true)
end

local function createPreviewVehicle(model)
    if previewModel == model and previewVehicle and DoesEntityExist(previewVehicle) then
        return
    end
    if not currentLocation then return end

    clearPreview()

    if not requestModel(model) then return end

    local spawnCoords = currentLocation.SpawnOffset
    local x, y, z, heading = spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w

    previewVehicle = CreateVehicle(GetHashKey(model), x, y, z, heading, false, false)
    SetEntityAsMissionEntity(previewVehicle, true, true)
    SetVehicleOnGroundProperly(previewVehicle)
    SetEntityInvincible(previewVehicle, true)
    SetVehicleDoorsLocked(previewVehicle, 2)
    SetEntityCollision(previewVehicle, false, false)
    FreezeEntityPosition(previewVehicle, true)
    SetModelAsNoLongerNeeded(GetHashKey(model))
    previewModel = model

    -- Pointer la caméra sur le nouveau véhicule
    if previewCam and DoesCamExist(previewCam) then
        PointCamAtEntity(previewCam, previewVehicle, 0.0, 0.0, 0.5, true)
    end
end

-- ============================================================
-- Menu RageUI
-- ============================================================

function openCarRental(loc)
    if isRentalMenuOpen then return end
    isRentalMenuOpen = true
    currentLocation = loc

    local mainMenu = RageUI.CreateMenu("", "Location de Véhicules")
    local carsMenu = RageUI.CreateSubMenu(mainMenu, "", "Voitures")
    local bikesMenu = RageUI.CreateSubMenu(mainMenu, "", "Motos")
    local bicyclesMenu = RageUI.CreateSubMenu(mainMenu, "", "Vélos")
    local starterpackMenu = RageUI.CreateSubMenu(mainMenu, "", "Packs de début")
    local keybindsMenu = RageUI.CreateSubMenu(mainMenu, "", "Liste des touches")

    RageUI.Visible(mainMenu, not RageUI.Visible(mainMenu))

    local wasOnMainMenu = false

    while isRentalMenuOpen do
        Citizen.Wait(0)

        if not RageUI.Visible(mainMenu) and not RageUI.Visible(carsMenu) and not RageUI.Visible(bikesMenu) and not RageUI.Visible(bicyclesMenu) and not RageUI.Visible(starterpackMenu) and not RageUI.Visible(keybindsMenu) then
            clearPreview()
            destroyPreviewCam()
            isRentalMenuOpen = false
        end

        -- Quand on revient au menu principal, détruire le preview véhicule mais garder/relancer la caméra
        if RageUI.Visible(mainMenu) and not wasOnMainMenu then
            wasOnMainMenu = true
            clearPreview()
            destroyPreviewCam()
        elseif not RageUI.Visible(mainMenu) then
            wasOnMainMenu = false
        end

        RageUI.IsVisible(mainMenu, function()
            if rentalCooldown then
                RageUI.Separator("~r~Vous devez attendre avant une nouvelle location")
            else
                RageUI.Separator("Locations disponibles")
                for catKey, catData in pairs(Config.CarRental.categories) do
                    RageUI.Button(catData.icon .. " " .. catData.label, nil, {RightLabel = "→"}, true, {
                        onSelected = function()
                            startPreviewCam()
                            local firstVeh = catData.vehicles[1]
                            if firstVeh then
                                createPreviewVehicle(firstVeh.model)
                            end
                        end
                    }, catKey == "cars" and carsMenu or catKey == "bikes" and bikesMenu or bicyclesMenu)
                end
            end

            if currentLocation.enableStarterPack or currentLocation.enableKeybinds then
                RageUI.Separator("Autres options")
            end

            if currentLocation.enableStarterPack then
                RageUI.Button("Les packs de début", nil, {RightLabel = "→"}, true, {
                    onSelected = function()
                    end
                }, starterpackMenu)
            end

            if currentLocation.enableKeybinds then
                RageUI.Button("Liste des touches", nil, {RightLabel = "→"}, true, {
                    onSelected = function()
                    end
                }, keybindsMenu)
            end
        end)

        local function renderCategory(menu, catKey)
            RageUI.IsVisible(menu, function()
                local catData = Config.CarRental.categories[catKey]
                if not catData then return end

                for _, v in ipairs(catData.vehicles) do
                    RageUI.Button(v.label, nil, {RightLabel = "~g~" .. v.price .. "$"}, true, {
                        onActive = function()
                            createPreviewVehicle(v.model)
                        end,
                        onSelected = function()
                            if rentalCooldown then
                                ESX.ShowNotification("~r~Vous devez attendre avant une nouvelle location")
                                return
                            end

                            if rentalActive or rentalVehicle then
                                ESX.ShowNotification("~r~Vous avez déjà un véhicule de location en cours")
                                return
                            end

                            -- Dialog de paiement
                            local paymentResult = NullInput({
                                title = "Paiement de la location",
                                fields = {
                                    {
                                        type = "select",
                                        label = "Méthode de paiement",
                                        options = {
                                            {value = "bank", label = "Carte bancaire"},
                                            {value = "cash", label = "Cash"},
                                        },
                                        required = true,
                                        icon = "fa-solid fa-credit-card"
                                    }
                                }
                            })

                            if not paymentResult or not paymentResult[1] then return end

                            local paymentType = paymentResult[1]

                            clearPreview()
                            destroyPreviewCam()

                            local playerPed = PlayerPedId()
                            local spawnCoords = currentLocation.SpawnOffset
                            local spawnPos = vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z)

                            -- Vérifier que le point de spawn est libre
                            local blockingVeh = GetClosestVehicle(spawnPos.x, spawnPos.y, spawnPos.z, 3.0, 0, 71)
                            if blockingVeh and blockingVeh ~= 0 then
                                ESX.ShowNotification("~r~Le point de spawn est occupé, veuillez patienter...")
                                local waitAttempts = 0
                                while blockingVeh and blockingVeh ~= 0 and waitAttempts < 20 do
                                    Wait(500)
                                    blockingVeh = GetClosestVehicle(spawnPos.x, spawnPos.y, spawnPos.z, 3.0, 0, 71)
                                    waitAttempts = waitAttempts + 1
                                end
                                if blockingVeh and blockingVeh ~= 0 then
                                    ESX.ShowNotification("~r~Le point de spawn est toujours occupé. Location annulée.")
                                    return
                                end
                            end

                            local plate = "RENT" .. math.random(1000, 9999)

                            ESX.Game.SpawnVehicle(v.model, spawnPos, spawnCoords.w, function(vehicle)
                                SetVehicleNumberPlateText(vehicle, plate)
                                SetVehRadioStation(vehicle, "OFF")
                                TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
                                SetEntityAsMissionEntity(vehicle, true, true)

                                rentalVehicle = vehicle
                                rentalActive = true
                                rentalTimer = RENTAL_DURATION

                                TriggerServerEvent('null:carrental:rent', v.model, v.price, plate, VehToNet(vehicle), paymentType)
                                TriggerServerEvent('Null:garage:addTempKey', plate)
                            end)

                            TriggerEvent('null:carrental:cooldown')
                            RageUI.CloseAll()
                        end
                    })
                end
            end)
        end

        renderCategory(carsMenu, "cars")
        renderCategory(bikesMenu, "bikes")
        renderCategory(bicyclesMenu, "bicycles")

        if currentLocation.enableStarterPack then
            RageUI.IsVisible(starterpackMenu, function()
                if Config.StarterPack and Config.StarterPack.Pack then
                    for k, v in pairs(Config.StarterPack.Pack) do
                        RageUI.Button("" .. (v.Type or k), v.Description, {}, true, {
                            onSelected = function()
                                TriggerServerEvent("Null:starterpack", k)
                            end
                        })
                    end
                else
                    RageUI.Separator("~r~StarterPack non configuré")
                end
            end)
        end

        -- Menu Keybinds
        if currentLocation.enableKeybinds then
            RageUI.IsVisible(keybindsMenu, function()
                if Config.StarterPack and Config.StarterPack.Touche then
                    for k, v in pairs(Config.StarterPack.Touche) do
                        RageUI.Button("" .. (v.Label or k), v.Description, {RightLabel = v.RightLabel}, true, {
                            onSelected = function()
                            end
                        })
                    end
                else
                    RageUI.Separator("~r~Aucune touche configurée")
                end
            end)
        end

        local anySubVisible = RageUI.Visible(carsMenu) or RageUI.Visible(bikesMenu) or RageUI.Visible(bicyclesMenu)
        if currentLocation.enableStarterPack then anySubVisible = anySubVisible or RageUI.Visible(starterpackMenu) end
        if currentLocation.enableKeybinds then anySubVisible = anySubVisible or RageUI.Visible(keybindsMenu) end
        if not RageUI.Visible(mainMenu) and not anySubVisible then
            isRentalMenuOpen = false
            clearPreview()
            destroyPreviewCam()
        end
    end

    clearPreview()
    destroyPreviewCam()
end

-- ============================================================
-- Cooldown
-- ============================================================

RegisterNetEvent('null:carrental:cooldown')
AddEventHandler('null:carrental:cooldown', function()
    rentalCooldown = true
    Wait(Config.CarRental.cooldown)
    rentalCooldown = false
end)

-- ============================================================
-- Timer & UI (comme le jail)
-- ============================================================

RegisterNetEvent('null:carrental:startTimer')
AddEventHandler('null:carrental:startTimer', function(duration)
    rentalActive = true
    rentalTimer = duration
end)

RegisterNetEvent('null:carrental:stopTimer')
AddEventHandler('null:carrental:stopTimer', function()
    rentalActive = false
    rentalTimer = 0
    rentalVehicle = nil
    pcall(function()
        HideInfo()
    end)
end)

CreateThread(function()
    while true do
        Wait(0)

        if rentalActive and rentalTimer > 0 then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)

            -- Afficher l'UI seulement si le joueur est dans un véhicule
            if veh and veh ~= 0 then
                -- Vérifier que c'est un véhicule de location (plate commence par RENT)
                local plate = GetVehicleNumberPlateText(veh)
                if plate and string.find(plate, "RENT") then
                    local time = null.fct.format.SecondsToClock(rentalTimer)
                    pcall(function()
                        ShowInfo(
                            "Location de Véhicule",
                            {
                                {left = "Temps restant", right = ("%s:%s:%s"):format(time[1] or "00", time[2] or "00", time[3] or "00"), color = "rgb(255, 255, 255)"},
                                {left = "Plaque", right = plate, color = "rgb(100, 200, 255)"},
                            }
                        )
                    end)
                else
                    pcall(function()
                        HideInfo()
                    end)
                end
            else
                pcall(function()
                    HideInfo()
                end)
            end
        end
    end
end)

-- Thread de décrémentation du timer côté client (affichage + despawn)
CreateThread(function()
    while true do
        Wait(1000)
        if rentalActive and rentalTimer > 0 then
            rentalTimer = rentalTimer - 1
            if rentalTimer <= 0 then
                rentalTimer = 0
                rentalActive = false
                pcall(function()
                    HideInfo()
                end)

                -- Despawn du véhicule côté client
                local ped = PlayerPedId()
                local veh = GetVehiclePedIsIn(ped, false)
                if veh and veh ~= 0 then
                    local plate = GetVehicleNumberPlateText(veh)
                    if plate and string.find(plate, "RENT") then
                        -- Éjecter le joueur
                        TaskLeaveVehicle(ped, veh, 0)
                        Wait(2000)
                        -- Supprimer le véhicule
                        SetEntityAsMissionEntity(veh, true, true)
                        DeleteEntity(veh)
                    end
                else
                    -- Le joueur n'est pas dans le véhicule, chercher par plaque
                    local veh2 = GetVehiclePedIsIn(ped, true)
                    if veh2 and veh2 ~= 0 then
                        local plate = GetVehicleNumberPlateText(veh2)
                        if plate and string.find(plate, "RENT") then
                            SetEntityAsMissionEntity(veh2, true, true)
                            DeleteEntity(veh2)
                        end
                    end
                end

                ESX.ShowNotification("~r~Votre location de véhicule est terminée.")
                TriggerServerEvent('null:carrental:cleanup')
            end
        end
    end
end)

-- ============================================================
-- 3D Interactions & Peds
-- ============================================================

CreateThread(function()
    for k, loc in ipairs(Config.CarRental.locations) do
        -- Spawn du ped de location
        local pedModel = Config.CarRental.pedModel or "s_m_m_highsec_01"
        local hash = GetHashKey(pedModel)
        RequestModel(hash)
        while not HasModelLoaded(hash) do Wait(50) end

        local ped = CreatePed(4, hash, loc.Position.x, loc.Position.y, loc.Position.z - 1.0, loc.Position.w or 0.0, false, false)
        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetModelAsNoLongerNeeded(hash)
        spawnedPeds[#spawnedPeds + 1] = ped

        -- 3D Interaction
        local blipData = nil
        if loc.Blip then
            blipData = {
                name = loc.Label or "Location de Véhicules",
                sprite = loc.Blip.sprite or 409,
                color = loc.Blip.color or 9,
                scale = loc.Blip.scale or 0.9,
                display = loc.Blip.display or 4,
            }
        end

        Add3DInteraction({
            id = "carrental_" .. k,
            coords = loc.Position,
            text = loc.Label or "Location de Véhicules",
            Action = function()
                openCarRental(loc)
            end,
            maxDistance = 7.0,
            key = "E",
            blip = blipData,
        })
    end
end)

-- ============================================================
-- Export
-- ============================================================

exports('openCarRental', openCarRental)
