local Boutique = {
    isOpen = false
}

-- Preview state
local inPreview = false
local previewVehicle = nil
local previewCam = nil
local beforePreviewCoords = nil
local previewItemData = nil

-- Weapon customization state
local weaponPreviewName = nil
local previewingComponentHash = nil

-- Showroom position 
local SHOWROOM_POS = vec3(-290.816345, 1648.461304, -159.7)
local SHOWROOM_HEADING = 47.98029708862305
local CAM_POS = vec3(-294.54629516602, 1651.7911376953, -159.02914428711)
local CAM_ROT = vec3(-5.62162017822265, 0.0, -133.0)

function Boutique.Open()
    if Boutique.isOpen then 
        return 
    end
    Boutique.isOpen = true
    boutiqueOpenTime = GetGameTimer()

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = 'boutique:open',
        type = 'boutique:open',
        userInfo = { coins = 0, fidelity = 0, fidelityTotal = 0 },
        items = {
            vehicles = {},
            weapons = {},
            packs = {},
            boosts = {},
            crates = {},
        },
        dailyItems = {},
        boutiqueLink = "",
        nightMarket = { active = false },
        serverBackground = (ESX.Config and ESX.Config('backgroundBanner')) or GetConvar('backgroundBanner', '') or ''
    })

    -- Request items and daily shop from server
    ESX.TriggerServerCallback('null:boutique:getData', function(data)
        data = data or {}
        SendNUIMessage({
            action = 'boutique:open',
            type = 'boutique:open',
            userInfo = data.userInfo,
            items = data.items,
            dailyItems = data.dailyItems,
            boutiqueLink = data.boutiqueLink,
            nightMarket = data.nightMarket,
            serverBackground = (ESX.Config and ESX.Config('backgroundBanner')) or GetConvar('backgroundBanner', '') or ''
        })
    end)
end

local boutiqueOpenTime = 0

function Boutique.Close()
    if not Boutique.isOpen then 
        return 
    end
    
    -- Empêcher la fermeture immédiate (moins de 500ms après ouverture)
    local timeSinceOpen = GetGameTimer() - boutiqueOpenTime
    if timeSinceOpen < 500 then
        return
    end
    
    Boutique.isOpen = false

    SendNUIMessage({
        action = 'boutique:close'
    })

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    
    Citizen.CreateThread(function()
        Wait(100)
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
    end)
end

-- ============================================================================
-- VEHICLE PREVIEW SYSTEM
-- ============================================================================
function Boutique.StartPreview(model, itemData)
    if inPreview then return end

    null.DisplayHud(false)
    inPreview = true
    previewItemData = itemData
    beforePreviewCoords = GetEntityCoords(PlayerPedId())

    local playerPed = PlayerPedId()

    SetEntityVisible(playerPed, false, 0)
    FreezeEntityPosition(playerPed, true)
    SetEntityCollision(playerPed, false, false)
    SetEntityInvincible(playerPed, true)

    SetEntityCoords(playerPed, SHOWROOM_POS.x, SHOWROOM_POS.y, SHOWROOM_POS.z)
    Wait(500)

    previewCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(previewCam, CAM_POS.x, CAM_POS.y, CAM_POS.z)
    SetCamRot(previewCam, CAM_ROT.x, CAM_ROT.y, CAM_ROT.z, 2)
    SetCamActive(previewCam, true)
    RenderScriptCams(true, true, 1000, true, true)
    Wait(200)

    ESX.Game.SpawnVehicle(model, SHOWROOM_POS, SHOWROOM_HEADING, function(vehicle)
        SetEntityCoords(vehicle, SHOWROOM_POS.x, SHOWROOM_POS.y, SHOWROOM_POS.z)
        SetVehicleOnGroundProperly(vehicle)
        FreezeEntityPosition(vehicle, true)
        SetVehicleDoorsLocked(vehicle, 2)

        previewVehicle = vehicle

        -- Show the small ingame key-hint overlay (dealership pattern)
        SendNUIMessage({ action = 'boutique:showPreviewHint' })
    end)
end

function Boutique.StopPreview()
    if not inPreview then return end
    local playerPed = PlayerPedId()

    if beforePreviewCoords then
        SetEntityCoords(playerPed, beforePreviewCoords.x, beforePreviewCoords.y, beforePreviewCoords.z)
        beforePreviewCoords = nil
    end

    if previewVehicle then
        ESX.Game.DeleteVehicle(previewVehicle)
        previewVehicle = nil
    end

    if previewCam then
        SetCamActive(previewCam, false)
        RenderScriptCams(false, true, 1000, true, true)
        DestroyCam(previewCam, true)
        previewCam = nil
    end

    SetEntityVisible(playerPed, true, 0)
    FreezeEntityPosition(playerPed, false)
    SetEntityCollision(playerPed, true, false)
    SetEntityInvincible(playerPed, false)

    null.DisplayHud(true)
    inPreview = false
    previewItemData = nil

    SendNUIMessage({ action = 'boutique:hidePreviewHint' })
end

-- Ingame control thread for the preview (matches dealership exactly):
-- * disables camera / movement controls
-- * LEFT (174) / RIGHT (175) arrows rotate the vehicle
-- * DELETE (178) exits the preview and reopens the boutique
CreateThread(LPH_NO_VIRTUALIZE(function()
    while true do
        if inPreview then
            Wait(0)

            DisableControlAction(0, 200, true)
            DisableControlAction(0, 199, true)
            DisableControlAction(1, 23,  true)
            DisableControlAction(1, 75,  true)
            DisableControlAction(0, 24,  true)
            DisableControlAction(0, 25,  true)
            DisableControlAction(0, 1,   true)
            DisableControlAction(0, 2,   true)

            if previewVehicle and DoesEntityExist(previewVehicle) then
                if IsDisabledControlPressed(0, 174) or IsControlPressed(0, 174) then
                    SetEntityHeading(previewVehicle, GetEntityHeading(previewVehicle) - 1.5)
                end
                if IsDisabledControlPressed(0, 175) or IsControlPressed(0, 175) then
                    SetEntityHeading(previewVehicle, GetEntityHeading(previewVehicle) + 1.5)
                end
            end

            if IsDisabledControlJustPressed(0, 177) or IsControlJustPressed(0, 177)
            or IsDisabledControlJustPressed(0, 178) or IsControlJustPressed(0, 178) then
                Boutique.StopPreview()
                Wait(300)
                Boutique.Open()
            end
        else
            Wait(500)
        end
    end
end))

-- NUI Callbacks
RegisterNUICallback('boutique:close', function(data, cb)
    cb('ok')
    -- Désactiver immédiatement le focus avant de fermer
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    Boutique.Close()
end)

RegisterNUICallback('boutique:getItems', function(data, cb)
    if not data.category then cb('error') return end

    ESX.TriggerServerCallback('null:boutique:getItems', function(items)
        SendNUIMessage({
            action = 'boutique:items',
            category = data.category,
            items = items
        })
    end, data.category)

    cb('ok')
end)

RegisterNUICallback('boutique:purchase', function(data, cb)
    ESX.TriggerServerCallback('null:boutique:purchase', function(result)
        SendNUIMessage({
            action = 'boutique:purchaseResult',
            success = result.success,
            message = result.message,
            coins = result.coins
        })

        -- If vehicle purchased, spawn it
        if result.success and result.vehicleModel then
            --Boutique.SpawnVehicle(result.vehicleModel)
        end
    end, data.id, data.category, data.quantity or 1, data.price)

    cb('ok')
end)

RegisterNUICallback('boutique:openCrate', function(data, cb)
    ESX.TriggerServerCallback('null:boutique:openCrate', function(result)
        SendNUIMessage({
            action = 'boutique:crateResult',
            reward = result.reward,
            coins = result.coins
        })

        -- If vehicle won, spawn it
        if result.reward and result.reward.typeLot == 'vehicle' then
            Boutique.SpawnVehicle(result.reward.model)
        end
    end, data.crateId, data.quantity or 1)

    cb('ok')
end)

RegisterNUICallback('boutique:openTebex', function(data, cb)
    if data.url and data.url ~= "" then
        SendNUIMessage({
            type = "openUrl",
            link = tostring(data.url)
        })
    end
    cb('ok')
end)

-- Preview: Start (dealership-style)
-- Hides the tablet NUI first, then spawns the vehicle and shows the ingame
-- key-hint overlay. Rotation + exit are handled by the preview control thread.
RegisterNUICallback('boutique:previewVehicle', function(data, cb)
    if not data.model then cb('error') return end
    if not exports["null-core"]:GetSafeZone() then
        ESX.ShowNotification("❌ Vous devez être en safezone pour prévisualiser un véhicule.")
        SendNUIMessage({ action = 'boutique:previewDenied' })
        cb('ok')
        return
    end

    -- Close the tablet UI (focus + component) like dealership does
    Boutique.isOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'boutique:hideForPreview' })

    Boutique.StartPreview(data.model, data.itemData)
    cb('ok')
end)

-- ============================================================================
-- WEAPON CUSTOMIZATION SYSTEM (Standalone menu)
-- ============================================================================
local WeaponCustom = {
    isOpen = false
}
local weaponCustomCam = nil
local openedFromBoutique = false

function WeaponCustom.StartCamera()
    local playerPed = PlayerPedId()
    local pedCoords = GetEntityCoords(playerPed)
    local pedHeading = GetEntityHeading(playerPed)
    local headingRad = math.rad(pedHeading)

    local camDist = 1.3
    local camX = pedCoords.x + math.sin(-headingRad) * camDist
    local camY = pedCoords.y + math.cos(-headingRad) * camDist
    local camZ = pedCoords.z + 0.2

    weaponCustomCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(weaponCustomCam, camX, camY, camZ)
    PointCamAtCoord(weaponCustomCam, pedCoords.x, pedCoords.y, pedCoords.z + 0.2)
    SetCamActive(weaponCustomCam, true)
    RenderScriptCams(true, true, 500, true, true)
end

function WeaponCustom.StopCamera()
    if weaponCustomCam then
        SetCamActive(weaponCustomCam, false)
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(weaponCustomCam, true)
        weaponCustomCam = nil
    end
end

function WeaponCustom.OpenForWeapon(weaponName)
    if WeaponCustom.isOpen then return end
    WeaponCustom.isOpen = true

    -- Equip the weapon
    local playerPed = PlayerPedId()
    local hash = GetHashKey(weaponName)
    SetCurrentPedWeapon(playerPed, hash, true)
    weaponPreviewName = weaponName
    previewingComponentHash = nil

    Wait(300)

    -- Start camera zoom
    WeaponCustom.StartCamera()

    -- Fetch weapon data and coins, then open NUI
    ESX.TriggerServerCallback('null:boutique:getPlayerWeapons', function(weapons)
        -- Find the selected weapon data
        local selectedWeaponData = nil
        for _, w in ipairs(weapons) do
            if w.name:upper() == weaponName:upper() then
                selectedWeaponData = w
                break
            end
        end

        ESX.TriggerServerCallback('null:boutique:getCoins', function(coins)
            SendNUIMessage({
                action = 'weaponCustom:open',
                weapons = weapons,
                coins = coins,
                selectedWeapon = weaponName
            })
            SetNuiFocus(true, true)
        end)
    end)
end

function WeaponCustom.Open()
    if WeaponCustom.isOpen then return end
    WeaponCustom.isOpen = true
    openedFromBoutique = false

    -- Fetch player weapons and coins from server
    ESX.TriggerServerCallback('null:boutique:getPlayerWeapons', function(weapons)
        ESX.TriggerServerCallback('null:boutique:getCoins', function(coins)
            SendNUIMessage({
                action = 'weaponCustom:open',
                weapons = weapons,
                coins = coins
            })
            SetNuiFocus(true, true)
        end)
    end)
end

function WeaponCustom.Close()
    if not WeaponCustom.isOpen then return end
    WeaponCustom.isOpen = false

    -- Remove any previewed component
    if weaponPreviewName and previewingComponentHash then
        local playerPed = PlayerPedId()
        local weaponHash = GetHashKey(weaponPreviewName)
        local compHash = GetHashKey(previewingComponentHash)
        RemoveWeaponComponentFromPed(playerPed, weaponHash, compHash)
        previewingComponentHash = nil
    end

    weaponPreviewName = nil

    -- Stop camera
    WeaponCustom.StopCamera()

    SendNUIMessage({
        action = 'weaponCustom:close'
    })
    SetNuiFocus(false, false)

    -- Re-open boutique if it was opened from there
    if openedFromBoutique then
        openedFromBoutique = false
        Wait(200)
        Boutique.Open()
    end
end

-- ============================================================================
-- NIGHT MARKET - Card reveal KVP + NUI callbacks
-- ============================================================================

-- KVP key: "nm_revealed_<cardId>" = "1"
RegisterNUICallback('boutique:nightmarket:revealCard', function(data, cb)
    if not data.cardId then cb('error') return end
    SetResourceKvp("nm_revealed_" .. data.cardId, "1")
    cb('ok')
end)

RegisterNUICallback('boutique:nightmarket:getRevealed', function(data, cb)
    local revealed = {}
    if data.cardIds then
        for _, cardId in ipairs(data.cardIds) do
            local val = GetResourceKvpString("nm_revealed_" .. cardId)
            if val == "1" then
                revealed[cardId] = true
            end
        end
    end
    SendNUIMessage({
        action = 'boutique:nightmarket:revealedCards',
        revealed = revealed
    })
    cb('ok')
end)

RegisterNUICallback('boutique:nightmarket:purchase', function(data, cb)
    if not data.cardId then cb('error') return end

    ESX.TriggerServerCallback('null:nightmarket:purchase', function(result)
        SendNUIMessage({
            action = 'boutique:nightmarket:purchaseResult',
            success = result.success,
            message = result.message,
            coins = result.coins,
            cardId = data.cardId
        })
    end, data.cardId)

    cb('ok')
end)

-- Listen for NightMarket start/stop events from server
RegisterNetEvent('null:nightmarket:started')
AddEventHandler('null:nightmarket:started', function()
    if Boutique.isOpen then
        SendNUIMessage({
            action = 'boutique:nightmarket:started'
        })
    end
end)

RegisterNetEvent('null:nightmarket:stopped')
AddEventHandler('null:nightmarket:stopped', function()
    if Boutique.isOpen then
        SendNUIMessage({
            action = 'boutique:nightmarket:stopped'
        })
    end
end)

-- Boutique: get weapons list for the customization page
RegisterNUICallback('boutique:getWeapons', function(data, cb)
    ESX.TriggerServerCallback('null:boutique:getPlayerWeapons', function(weapons)
        SendNUIMessage({
            action = 'boutique:weaponsList',
            weapons = weapons
        })
    end)
    cb('ok')
end)

-- Boutique: open weapon customization for a specific weapon (hides boutique)
RegisterNUICallback('boutique:openWeaponCustom', function(data, cb)
    if not data.weaponName then cb('error') return end

    openedFromBoutique = true

    -- Close boutique first
    Boutique.Close()
    Wait(300)

    -- Open weapon custom menu for this weapon with camera
    WeaponCustom.OpenForWeapon(data.weaponName)

    cb('ok')
end)

-- Close callback from NUI
RegisterNUICallback('weaponCustom:close', function(data, cb)
    WeaponCustom.Close()
    cb('ok')
end)

-- Select a weapon (equip it for viewing + camera)
RegisterNUICallback('weaponCustom:selectWeapon', function(data, cb)
    if not data.weaponName then cb('error') return end

    -- Remove previous preview
    if weaponPreviewName and previewingComponentHash then
        local playerPed = PlayerPedId()
        local weaponHash = GetHashKey(weaponPreviewName)
        local compHash = GetHashKey(previewingComponentHash)
        RemoveWeaponComponentFromPed(playerPed, weaponHash, compHash)
        previewingComponentHash = nil
    end

    local playerPed = PlayerPedId()
    local hash = GetHashKey(data.weaponName)
    SetCurrentPedWeapon(playerPed, hash, true)
    weaponPreviewName = data.weaponName

    Wait(200)

    -- Refresh camera
    WeaponCustom.StopCamera()
    WeaponCustom.StartCamera()

    cb('ok')
end)

-- Preview a component (add it visually, not permanently)
RegisterNUICallback('weaponCustom:previewComponent', function(data, cb)
    if not data.weaponName or not data.componentHash then cb('error') return end

    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(data.weaponName)

    -- Remove previous preview if any
    if previewingComponentHash then
        local prevHash = GetHashKey(previewingComponentHash)
        RemoveWeaponComponentFromPed(playerPed, weaponHash, prevHash)
    end

    -- Add new component visually
    local compHash = GetHashKey(data.componentHash)
    GiveWeaponComponentToPed(playerPed, weaponHash, compHash)
    previewingComponentHash = data.componentHash

    cb('ok')
end)

-- Stop previewing a component (remove it visually)
RegisterNUICallback('weaponCustom:stopPreviewComponent', function(data, cb)
    if not data.weaponName or not data.componentHash then cb('error') return end

    local playerPed = PlayerPedId()
    local weaponHash = GetHashKey(data.weaponName)
    local compHash = GetHashKey(data.componentHash)
    RemoveWeaponComponentFromPed(playerPed, weaponHash, compHash)
    previewingComponentHash = nil

    cb('ok')
end)

-- Buy a weapon component
RegisterNUICallback('weaponCustom:buyComponent', function(data, cb)
    if not data.weaponName or not data.componentHash then cb('error') return end

    -- Remove preview before buying (server will add it permanently)
    if previewingComponentHash == data.componentHash then
        local playerPed = PlayerPedId()
        local weaponHash = GetHashKey(data.weaponName)
        local compHash = GetHashKey(data.componentHash)
        RemoveWeaponComponentFromPed(playerPed, weaponHash, compHash)
        previewingComponentHash = nil
    end

    ESX.TriggerServerCallback('null:boutique:buyWeaponComponent', function(result)
        SendNUIMessage({
            action = 'weaponCustom:componentPurchased',
            success = result.success,
            message = result.message,
            coins = result.coins,
            weaponName = data.weaponName,
            componentHash = data.componentHash
        })

        -- If successful, apply component permanently on the ped
        if result.success then
            local playerPed = PlayerPedId()
            local weaponHash = GetHashKey(data.weaponName)
            local compHash = GetHashKey(data.componentHash)
            GiveWeaponComponentToPed(playerPed, weaponHash, compHash)
        end
    end, data.weaponName, data.componentHash, data.price)

    cb('ok')
end)

-- Command to open weapon customization standalone
RegisterCommand('weaponcustom', function()
    if WeaponCustom.isOpen then
        WeaponCustom.Close()
    else
        WeaponCustom.Open()
    end
end, false)

exports('OpenWeaponCustom', function()
    WeaponCustom.Open()
end)

exports('CloseWeaponCustom', function()
    WeaponCustom.Close()
end)

-- Commands 
RegisterCommand("boutique", function()
    if inPreview then
        Boutique.StopPreview()
        return
    end
    if Boutique.isOpen then
        Boutique.Close()
    else
        Boutique.Open()
    end
end, false)
local lastBoutiqueToggle = 0
RegisterCommand("menuboutique", function()
    -- Debounce: empêcher les doubles appuis (300ms)
    local now = GetGameTimer()
    if now - lastBoutiqueToggle < 300 then
        return
    end
    lastBoutiqueToggle = now
    
    
    if inPreview then
        Boutique.StopPreview()
        return
    end
    if Boutique.isOpen then
        Boutique.Close()
    else
        Boutique.Open()
    end
end, false)
RegisterKeyMapping('menuboutique', 'Ouvrir la boutique', 'keyboard', 'F1')


RegisterCommand("closeboutique", function()
    if inPreview then
        Boutique.StopPreview()
    end
    Boutique.Close()
end, false)

TriggerEvent('chat:addSuggestion', '/boutique', 'Ouvrir la boutique')

-- Vehicle spawn helper
function Boutique.SpawnVehicle(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end

    if HasModelLoaded(hash) then
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local heading = GetEntityHeading(playerPed)

        local vehicle = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
        SetVehicleNumberPlateText(vehicle, "BOUTIQUE")
        SetEntityAsMissionEntity(vehicle, true, true)
        SetVehicleOnGroundProperly(vehicle)
        SetModelAsNoLongerNeeded(hash)

        -- Give keys via ESX
        local plate = GetVehicleNumberPlateText(vehicle)
        TriggerEvent("vehiclekeys:client:SetOwner", plate)
    end
end

-- Exports
exports('OpenBoutique', function()
    Boutique.Open()
end)

exports('CloseBoutique', function()
    Boutique.Close()
end)

if not null.modules.ui then
    null.modules.ui = {}
end
if not null.modules.ui.interactions then
    null.modules.ui.interactions = {}
end
null.modules.ui.interactions.Boutique = Boutique

-- Forward NUI messages from server to UI
RegisterNetEvent('null:boutique:nuiCallback')
AddEventHandler('null:boutique:nuiCallback', function(data)
    SendNUIMessage(data)
end)

null.InitPrint("Boutique Loaded successfully")
