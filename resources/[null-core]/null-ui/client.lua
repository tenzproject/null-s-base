InPauseMenu = false
isInInterfaceValue = false
local hiddenKeys = {}
serverColor = ""
serverName = ""
Prices = {}
local variation = {
    ["tshirt_1"] = "tshirt_2",
    ["torso_1"] = "torso_2",
    ["arms"] = "arms",
    ["pants_1"] = "pants_2",
    ["shoes_1"] = "shoes_2",
    ["decals_1"] = "decals_2",

    ["mask_1"] = "mask_2",
    ["bproof_1"] = "bproof_2",
    ["chain_1"] = "chain_2",
    ["helmet_1"] = "helmet_2",
    ["glasses_1"] = "glasses_2",
    ["watches_1"] = "watches_2",
    ["bracelets_1"] = "bracelets_2",
    ["bags_1"] = "bags_2"
}
local AffichePreviewPed = false
local heading = 0
local NumberInteractions = 0
local Skins = {
    ["tshirt_1"] = 0,
    ["tshirt_2"] = 0,
    ["torso_1"] = 0,
    ["torso_2"] = 0,
    ["arms"] = 0,
    ["pants_1"] = 0,
    ["pants_2"] = 0,
    ["shoes_1"] = 0,
    ["shoes_2"] = 0,
    ["decals_1"] = 0,
    ["decals_2"] = 0,

    ["mask_1"] = 0,
    ["mask_2"] = 0,
    ["bproof_1"] = 0,
    ["bproof_2"] = 0,
    ["chain_1"] = 0,
    ["chain_2"] = 0,
    ["helmet_1"] = 0,
    ["helmet_2"] = 0,
    ["ears_1"] = -1,
    ["ears_2"] = 0,
    ["glasses_1"] = 0,
    ["glasses_2"] = 0,
    ["watches_1"] = 0,
    ["watches_2"] = 0,
    ["bracelets_1"] = 0,
    ["bracelets_2"] = 0,
    ["bags_1"] = 0,
    ["bags_2"] = 0
}

 local previewSkins = {} -- Table temporaire pour les previews d'accessoires
local initialAccessorySkins = {} -- Sauvegarde des valeurs initiales des accessoires à l'ouverture
local SkinsToComponents = {
    ["tshirt_1"] = 8,
    ["torso_1"] = 11,
    ["arms"] = 3,
    ["pants_1"] = 4,
    ["shoes_1"] = 6,
    ["decals_1"] = 10,

    ["bproof_1"] = 9,
    ["mask_1"] = 1,
    ["bags_1"] = 5,
    ["chain_1"] = 7,
}

local PropsToComponents = {
    ["helmet_1"] = 0,
    ["glasses_1"] = 1,
    ["ears_1"] = 2,
    ["watches_1"] = 6,
    ["bracelets_1"] = 7
}

-- Helper local
local function IsMale()
    return GetEntityModel(PlayerPedId()) == GetHashKey("mp_m_freemode_01")
end

function isInInterface()
    return isInInterfaceValue
end

exports('isInInterface', function()
    return isInInterfaceValue
end)

function setInInterface(interfaceName)
    isInInterfaceValue = interfaceName

    Citizen.CreateThread(function()
        while isInInterfaceValue do 
            Wait(0)
            SetPauseMenuActive(false) 
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(1, 263)
        end
    end)
end

function clearInterface()
    Citizen.CreateThread(function()
        local timer = GetGameTimer()
        while (GetGameTimer() - timer) < 300 do
            Wait(0)
            SetPauseMenuActive(false)
            DisableControlAction(0, 200, true)
        end
    end)
    isInInterfaceValue = false
end

-- Commande de debug pour forcer la réinitialisation de l'interface
RegisterCommand('resetui', function()
    isInInterfaceValue = false
    SetNuiFocus(false, false)
    SendNUIMessage({type = "close"})
    SetPlayerControl(PlayerId(), true, 12)
    FreezeEntityPosition(PlayerPedId(), false)
    null.DisplayHud(true)
    DisplayRadar(true)
    print("^2[null-UI] Interface réinitialisée^0")
end, false)

RegisterCommand('setfocus_Nullui', function()
    SetNuiFocus(true, true)
end, false)

RegisterCommand('setunfocus_Nullui', function()
    SetNuiFocus(false, false)
end, false)

Citizen.CreateThread(function()
    --while nuiReady() == false do Wait(10) end
    Wait(1000)
    serverColor = ESX.Config("hexcolor")
    serverName = ESX.Config("serverName")
    playerSex = IsMale() and "male" or "female"
    SendNUIMessage({
        type = "setprices", 
        logo = ESX.Config("serverCHAR"),
        playerSex = playerSex,
        prices = {
            MainPrice = Config.ClothingShop.MainPrice,
            CategoryMainPrice = Config.ClothingShop.CategoryMainPrice,
            CustomPrice = Config.ClothingShop.CustomPrice,
        },
        blackListVetement = Config.ClothingShop.blackListed or {},
        color = serverColor
    });
end)

RegisterNetEvent("null:esx:pausemenu", function(bool)
    InPauseMenu = bool
end)

local allPreviewPed = {}

local changeSkin = false
local SaveSkin = nil

local isCameraActive = false
local zoomOffset = 0.0
local heading = 288.49032592773
local angle2 = 200
local zoomOffset = 0.6
local camOffset = 0.65

cam = nil 
transitionCam = nil

local isDragging = false
local lastMouseX = 0

local currentCategory = "torso_1"
local currentShowCategory = nil

local actionsCooldown = {}

function actionCooldown(name, interval)
    local action = actionsCooldown[name]
   
    if action == nil then 
        actionsCooldown[name] = { cooldown = 0, interval = interval }

        return true
    end

    local now = GetGameTimer()

    if now - action.cooldown < action.interval then 
        return false 
    end 

    action.cooldown = now
    return true
end

local function UpdateCameraPosition()
    local coords = GetEntityCoords(PlayerPedId())

    -- Créer une nouvelle caméra pour la transition
    if not DoesCamExist(transitionCam) then
        transitionCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    end

    -- Copier la position et rotation actuelles de la caméra principale vers la caméra de transition
    local currentCamCoord = GetCamCoord(cam)
    local currentCamRot = GetCamRot(cam, 2)
    SetCamCoord(transitionCam, currentCamCoord.x, currentCamCoord.y, currentCamCoord.z)
    SetCamRot(transitionCam, currentCamRot.x, currentCamRot.y, currentCamRot.z, 2)

    -- Définir la nouvelle position de la caméra principale
    if currentCategory == "shoes_1" then
        -- Vue chaussures (bas du corps)
        SetCamCoord(cam, coords.x + 0.5, coords.y + 1.8, coords.z + 0.0)
        SetCamRot(cam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(cam, coords.x, coords.y, coords.z - 0.6)
    elseif currentCategory == "pants_1" then
        -- Vue pantalons (milieu du corps)
        SetCamCoord(cam, coords.x + 0.5, coords.y + 1.8, coords.z + 0.2)
        SetCamRot(cam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(cam, coords.x, coords.y, coords.z - 0.2)
    elseif currentCategory == "ears_1" or currentCategory == "mask_1" then
        -- Vue tête (accessoires)
        SetCamCoord(cam, coords.x + 0.3, coords.y + 1.6, coords.z + 0.8)
        SetCamRot(cam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(cam, coords.x, coords.y, coords.z + 0.5)
    else
        -- Vue normale (corps entier)
        SetCamCoord(cam, coords.x + 0.5, coords.y + 2.2, coords.z + 0.6)
        SetCamRot(cam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(cam, coords.x, coords.y, coords.z + 0.2)
    end

    -- Activer la transition entre les caméras
    SetCamActiveWithInterp(cam, transitionCam, 1000, 3, 3) -- 1000ms de transition avec un easing cubique
end

function CreatePreviewPed()
    if AffichePreviewPed then
        return
    end
    Citizen.CreateThread(function()
        Wait(1300)
        local nbrPed = 3
        for i=1, nbrPed do
            AffichePreviewPed = true
            local playerModel = GetEntityModel(PlayerPedId())
            local PlayerCoords = GetEntityCoords(PlayerPedId())
            allPreviewPed[i] = CreatePed(26, playerModel, 0.0, 0.0, 0.0, 0.0, false, false)
            ClonePedToTarget(PlayerPedId(), allPreviewPed[i])
            SetEntityVisible(allPreviewPed[i], false, 0)
            
            SetEntityCollision(allPreviewPed[i], false, false)
            SetEntityInvincible(allPreviewPed[i], true)
            SetEntityLocallyVisible(allPreviewPed[i])
            NetworkSetEntityInvisibleToNetwork(allPreviewPed[i], true)
            SetEntityCanBeDamaged(allPreviewPed[i], false)
            SetBlockingOfNonTemporaryEvents(allPreviewPed[i], true)
            SetEntityAlpha(allPreviewPed[i], 254)
        
            ESX.Streaming.RequestAnimDict("amb@world_human_hang_out_street@female_arms_crossed@idle_a", function()
                TaskPlayAnim(allPreviewPed[i], "amb@world_human_hang_out_street@female_arms_crossed@idle_a", "idle_a", 8.0, -8.0, -1, 49, 0, false, false, false)
            end)
        
            local positionBuffer = {}
            local bufferSize = 5
        
            CreateThread(function()
                local world, normal = GetWorldCoordFromScreenCoord(0.58, 0.83)
                local depth = 2.8
                if i == 2 then
                    world, normal = GetWorldCoordFromScreenCoord(0.68, 0.82)
                    depth = 3.0
                elseif i == 3 then
                    world, normal = GetWorldCoordFromScreenCoord(0.78, 0.81)
                    depth = 3.2
                end
                while AffichePreviewPed do
                    local target = world + normal * depth
                    local camRot = GetGameplayCamRot(2)
        
                    table.insert(positionBuffer, target)
                    if #positionBuffer > bufferSize then
                        table.remove(positionBuffer, 1)
                    end
        
                    local averagedTarget = vector3(0, 0, 0)
                    for _, position in ipairs(positionBuffer) do
                        averagedTarget = averagedTarget + position
                    end
                    averagedTarget = averagedTarget / #positionBuffer
        
                    SetEntityCoords(allPreviewPed[i], averagedTarget.x, averagedTarget.y, averagedTarget.z, false, false, false, true)
                    SetEntityHeading(allPreviewPed[i], heading)
    
                    -- Appliquer les vêtements de base
                    if currentCategory ~= "cart" then
                        -- Fusionner Skins avec previewSkins pour les accessoires
                        local displaySkins = {}
                        for k, v in pairs(Skins) do
                            displaySkins[k] = v
                        end
                        -- Écraser avec les previews d'accessoires si présents
                        for k, v in pairs(previewSkins) do
                            displaySkins[k] = v
                        end
                        
                        for category, value in pairs(displaySkins) do
                            if string.match(category, "_1$") then  -- Si c'est une catégorie principale (se termine par _1)
                                local variation = category:gsub("_1$", "_2")  -- Obtenir le nom de la variation (_2)
                                if category == currentCategory then
                                    -- Vérifier si la variation existe
                                    if SkinsToComponents[category] then
                                        local currentVariation = GetPedDrawableVariation(allPreviewPed[i], SkinsToComponents[category])
                                        local maxVariation = GetNumberOfPedTextureVariations(allPreviewPed[i], SkinsToComponents[category], value)
                                        local variationValue = displaySkins[variation] or 0
                                        -- Appliquer le vêtement principal et sa variation +1 seulement si elle existe
                                        if maxVariation > 0 and variationValue + i < maxVariation then
                                            SetEntityVisible(allPreviewPed[i], true, 0)
                                            SetPedComponentVariation(allPreviewPed[i], SkinsToComponents[category], value, variationValue + i, 0)
                                        else
                                            SetEntityVisible(allPreviewPed[i], false, 0)
                                            SetPedComponentVariation(allPreviewPed[i], SkinsToComponents[category], value, variationValue, 0)
                                        end
                                    elseif PropsToComponents[category] then
                                        local currentVariation = GetNumberOfPedPropDrawableVariations(allPreviewPed[i], PropsToComponents[category])
                                        local maxVariation = GetNumberOfPedPropTextureVariations(allPreviewPed[i], PropsToComponents[category], value)
                                        local variationValue = displaySkins[variation] or 0
                                        -- Appliquer le vêtement principal et sa variation +1 seulement si elle existe
                                        if maxVariation > 0 and variationValue + i < maxVariation then
                                            SetPedPropIndex(allPreviewPed[i], PropsToComponents[category], value, variationValue + i, 0)
                                            SetEntityVisible(allPreviewPed[i], true, 0)
                                        else
                                            SetEntityVisible(allPreviewPed[i], false, 0)
                                            SetPedPropIndex(allPreviewPed[i], PropsToComponents[category], value, variationValue, 0)
                                        end
                                    end
                                else
                                    local variationValue = displaySkins[variation] or 0
                                    if SkinsToComponents[category] then
                                        SetPedComponentVariation(allPreviewPed[i], SkinsToComponents[category], value, variationValue, 0)
                                    elseif PropsToComponents[category] then
                                        SetPedPropIndex(allPreviewPed[i], PropsToComponents[category], value, variationValue, 0)
                                    end
                                end
                            elseif category == "arms" then
                                if category == currentCategory then
                                    local variationValue = displaySkins[variation] or 0
                                    SetEntityVisible(allPreviewPed[i], false, 0)
                                    SetPedComponentVariation(allPreviewPed[i], SkinsToComponents[category], value, variationValue, 0)
                                end
                            end
                        end
                    else
                        SetEntityVisible(allPreviewPed[i], false, 0)
                    end

                    if not IsEntityPlayingAnim(allPreviewPed[i], "amb@world_human_hang_out_street@female_arms_crossed@idle_a", "idle_a", 3) then
                        ESX.Streaming.RequestAnimDict("amb@world_human_hang_out_street@female_arms_crossed@idle_a", function()
                            TaskPlayAnim(allPreviewPed[i], "amb@world_human_hang_out_street@female_arms_crossed@idle_a", "idle_a", 8.0, -8.0, -1, 49, 0, false, false, false)
                        end)
                    end
        
                    Wait(4)
                end
                for k,v in pairs(allPreviewPed) do
                    DeletePed(v)
                end
            end)
        end
        for k,v in pairs(allPreviewPed) do
            SetEntityVisible(allPreviewPed[i], true, 0)
        end
    end)
end

function CreateSkinCam()
    if DoesCamExist(cam) then
        DestroyCam(cam, true)
    end
    if DoesCamExist(transitionCam) then
        DestroyCam(transitionCam, true)
    end

    cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local coords = GetEntityCoords(PlayerPedId())
    SetEntityVisible(PlayerPedId(), true, 0)
    -- Position initiale de la caméra (légèrement zoomée)
    SetCamCoord(cam, coords.x + 0.5, coords.y + 2.2, coords.z + 0.6)
    SetCamRot(cam, 0.0, 0.0, 270.0, true)
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 1000, true, true)
    isCameraActive = true
    
    -- Pointer la caméra vers le centre des peds
    PointCamAtCoord(cam, coords.x, coords.y, coords.z + 0.2)
end

function DeleteSkinCam()
    isCameraActive = false
    SetCamActive(cam, false)
    if DoesCamExist(transitionCam) then
        SetCamActive(transitionCam, false)
        DestroyCam(transitionCam, true)
    end
    RenderScriptCams(false, true, 1500, true, true)
    if DoesCamExist(cam) then
        DestroyCam(cam, true)
    end
    cam = nil
    transitionCam = nil
end


function openMenu(type)
    if isInInterfaceValue ~= false then return end
    null.DisplayHud(false)
    DisplayRadar(false)
    local pedtype = "male"
    if not IsMale() then pedtype = "female" end
    if type == "clothes" then
        setInInterface("clothes")
        currentCategory = "torso_1"
        FreezeEntityPosition(PlayerPedId(), true)
        SetPlayerControl(PlayerId(), false, 12)

        CreateSkinCam()
        heading = GetEntityHeading(PlayerPedId())
        CreatePreviewPed()
        
        SetNuiFocus(true,true)
        ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
            for k,v in pairs(skin) do
                Skins[k] = v
            end
            SendNUIMessage({
                type = "open", 
                category = "clothes", 
                color = serverColor,
                playerSex = pedtype,
                Skins = json.encode(Skins), 
                prices = {
                    MainPrice = Config.ClothingShop.MainPrice,
                    CategoryMainPrice = Config.ClothingShop.CategoryMainPrice,
                    CustomPrice = Config.ClothingShop.CustomPrice,
                },
            });
        end)
    elseif type == "accesories" then
        setInInterface("accesories")
        currentCategory = "bproof_1"
        FreezeEntityPosition(PlayerPedId(), true)
        SetPlayerControl(PlayerId(), false, 12)

        CreateSkinCam()
        heading = GetEntityHeading(PlayerPedId())
        CreatePreviewPed()

        SetNuiFocus(true, true)
        previewSkins = {}
        initialAccessorySkins = {}
        changedSkins = {}
        ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
            Skins = skin
            -- Sauvegarder l'état initial de tous les accessoires pour restauration
            for k, v in pairs(skin) do
                initialAccessorySkins[k] = v
            end
            local pedtype = "male"
            if GetEntityModel(PlayerPedId()) == GetHashKey('mp_f_freemode_01') then
                pedtype = "female"
            end
            SendNUIMessage({
                type = "open", 
                category = "accesories", 
                color = serverColor,
                playerSex = pedtype,
                Skins = json.encode(Skins), 
                prices = {
                    MainPrice = Config.ClothingShop.MainPrice,
                    CategoryMainPrice = Config.ClothingShop.CategoryMainPrice,
                    CustomPrice = Config.ClothingShop.CustomPrice,
                },
            });
        end)
    elseif type == "creator" then
        
    end
end

function Close(data)
    if isInInterfaceValue == false then return end
    
    local menuType = data.type or isInInterfaceValue
    local shouldSave = data.changeSkin or false
    
    clearInterface()
    SetNuiFocus(false,false);
    SendNUIMessage({type="close"});
    null.DisplayHud(true)
    SetPlayerControl(PlayerId(), true, 12)
    FreezeEntityPosition(PlayerPedId(), false)
    DisplayRadar(true)
    if menuType == "clothes" then
        DeleteSkinCam()
        AffichePreviewPed = false
        if not shouldSave then
            ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
                TriggerEvent('Null:skinchanger:loadClothes', skin, skin)
            end)
        else
            TriggerEvent('Null:skinchanger:getSkin', function(skina)
                TriggerEvent('Null:skinchanger:loadClothes', skina, Skins)
                TriggerEvent('Null:skinchanger:getSkin', function(skin)
                    TriggerServerEvent('Null:esx_skin:save', skin)
                end)
            end)
        end
    elseif menuType == "accesories" then
        DeleteSkinCam()
        AffichePreviewPed = false
        if not shouldSave then
            -- Restaurer immédiatement le skin complet initial (couvre tous les accessoires + changedSkins)
            if next(initialAccessorySkins) then
                for k, v in pairs(initialAccessorySkins) do
                    Skins[k] = v
                end
                TriggerEvent('Null:skinchanger:loadClothes', initialAccessorySkins, initialAccessorySkins)
            end
            changedSkins = {}
            previewSkins = {}
            initialAccessorySkins = {}
            -- Puis recharger depuis la DB pour être sûr
            ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
                TriggerEvent('Null:skinchanger:loadClothes', skin, skin)
                for k, v in pairs(skin) do
                    Skins[k] = v
                end
            end)
        else
            previewSkins = {}
            initialAccessorySkins = {}
            changedSkins = {}
            TriggerEvent('Null:skinchanger:getSkin', function(skina)
                TriggerEvent('Null:skinchanger:loadClothes', skina, Skins)
                TriggerEvent('Null:skinchanger:getSkin', function(skin)
                    TriggerServerEvent('Null:esx_skin:save', skin)
                end)
            end)
        end
    elseif menuType == "creator" then
        DeleteSkinCam()
        AffichePreviewPed = false
        ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
            TriggerEvent('Null:skinchanger:loadClothes', skin, skin)
        end)
    end
end

exports("openMenu", openMenu)

RegisterCommand("openClothes", function(source, args)
    openMenu("clothes")
end)
RegisterCommand("openAccesories", function(source, args)
    openMenu("accesories")
end)

-- Intercepter les requêtes de fermeture NUI. Quand le joueur est dans le créateur,
-- on ignore les demandes de fermeture pour empêcher la sortie accidentelle.
RegisterNUICallback("exit", function(data, cb)
    if isInInterfaceValue == "creator" then
        -- Ignorer la fermeture tant que le créateur est actif
        cb('ok')
        return
    end

    -- Comportement de fermeture par défaut pour les autres interfaces
    SetNuiFocus(false, false)
    SendNUIMessage({type = "close"})
    SetPlayerControl(PlayerId(), true, 12)
    FreezeEntityPosition(PlayerPedId(), false)
    null.DisplayHud(true)
    DisplayRadar(true)
    clearInterface()

    cb('ok')
end)

local changedSkins = {}
RegisterNUICallback("updateSkin", function(data)
    local newClothe = true
    if isInInterfaceValue == "clothes" then
        if Skins[data.type] == data.number then newClothe = false end
        Skins[data.type] = data.number
        TriggerEvent("Null:skinchanger:change", data.type, data.number)
        if newClothe and data.type ~= "arms" then
            local variationType = variation[data.type]
            if variationType then
                Skins[variationType] = 0
                TriggerEvent("Null:skinchanger:change", variationType, 0)
            end
        end
        SetPlayerControl(PlayerId(), false, 12)
    elseif isInInterfaceValue == "accesories" then
        previewSkins[data.type] = data.number
        TriggerEvent("Null:skinchanger:change", data.type, data.number)
        local variationType = variation[data.type]
        if variationType then
            previewSkins[variationType] = 0
            TriggerEvent("Null:skinchanger:change", variationType, 0)
        end
        SetPlayerControl(PlayerId(), false, 12)
    end
end)

RegisterNUICallback("updateVariation", function(data)
    -- Utiliser data.type directement (envoyé par le JS) au lieu de variation[currentCategory]
    -- pour éviter les problèmes de désynchronisation quand le joueur change vite de catégorie
    local varType = data.type
    if not varType then
        varType = variation[currentCategory]
    end
    
    if isInInterfaceValue == "clothes" then
        Skins[varType] = data.number
    elseif isInInterfaceValue == "accesories" then
        previewSkins[varType] = data.number
    end
    TriggerEvent("Null:skinchanger:change", varType, data.number)
    SetPlayerControl(PlayerId(), false, 12)
end)

RegisterNUICallback('startRotation', function(data, cb)
    isDragging = true
    lastMouseX = data.mouseX
    cb({})
end)

RegisterNUICallback('stopRotation', function(data, cb)
    isDragging = false
    cb({})
end)

RegisterNUICallback('updateRotation', function(data, cb)
    if isDragging then
        local currentHeading = GetEntityHeading(PlayerPedId())
        local mouseDelta = data.mouseX - lastMouseX
        SetEntityHeading(PlayerPedId(), currentHeading - (mouseDelta * 0.5))
        heading = currentHeading - (mouseDelta * 0.5)
        lastMouseX = data.mouseX
    end
    cb({})
end)

RegisterNUICallback('changeCategory', function(data, cb)
    currentCategory = data.category

    if currentCategory == "ears_1" then
        changedSkins["mask_1"] = Skins["mask_1"]
        changedSkins["mask_2"] = Skins["mask_2"]
        TriggerEvent("Null:skinchanger:change", "mask_1", -1)
    elseif currentCategory == "bracelets_1" then
        TriggerEvent("Null:skinchanger:change", "torso_1", 0)
    else
        for k,v in pairs(changedSkins) do
            TriggerEvent("Null:skinchanger:change", k, v)
        end
        changedSkins = {}
    end

    Citizen.CreateThread(function()
        Wait(1000)
        currentShowCategory = data.category
    end)
    if isCameraActive then
        UpdateCameraPosition()
    end
    cb({})
end)

RegisterNUICallback('payItem', function(data, cb)
    name = null.fct.input("Nom du vêtement")
    ESX.TriggerServerCallback('Null:clothes:payone', function(good)
        if good then
            --Close({type = "clothes", changeSkin = true})
        else
            if data.method == 'bank' then
                ESX.ShowNotification("Vous n'avez pas assez d'argent sur votre compte bancaire")
            else
                ESX.ShowNotification("Vous n'avez pas assez d'argent en liquide")
            end
        end
    end, data.items, data.method, data.group, name)

    cb('ok')
end)

-- Preview temporaire d'un accessoire (ne sauvegarde pas)
local previewedAccessories = {}

RegisterNUICallback('previewAccessory', function(data, cb)
    -- Sauvegarder l'état actuel si c'est la première preview
    if not previewedAccessories[data.type] then
        previewedAccessories[data.type] = {
            item = Skins[data.type],
            variation = Skins[variation[data.type]]
        }
    end
    
    -- Appliquer la preview temporaire
    TriggerEvent("Null:skinchanger:change", data.type, data.number)
    if data.variation then
        TriggerEvent("Null:skinchanger:change", variation[data.type], data.variation)
    end
    
    cb('ok')
end)

-- Restaurer les accessoires initiaux
RegisterNUICallback('restoreAccessories', function(data, cb)
    if data.skins then
        for category, value in pairs(data.skins) do
            TriggerEvent("Null:skinchanger:change", category, value)
        end
    end
    
    -- Vider la sauvegarde des previews
    previewedAccessories = {}
    
    cb('ok')
end)

-- Restaurer le skin complet (vêtements et accessoires)
RegisterNUICallback('restoreSkin', function(data, cb)
    if data.skin then
        for category, value in pairs(data.skin) do
            Skins[category] = value
            TriggerEvent("Null:skinchanger:change", category, value)
        end
    end
    cb('ok')
end)

RegisterNUICallback('buyAccessory', function(data, cb)
    name = null.fct.input('Nom de l\'accessoire')
    ESX.TriggerServerCallback('Null:clothes:payone', function(good)
        if good then
            -- Vider la sauvegarde des previews car on a acheté
            previewedAccessories = {}
            -- Sauvegarder dans les skins actuels
            Skins[data.category] = data.item
            Skins[variation[data.category]] = data.variation
            Close({type = "accesories", changeSkin = true})
        else
            ESX.ShowNotification("Vous n'avez pas assez d'argent")
        end
    end, {
        [data.category] = {
            item = data.item,
            variation = data.variation
        }
    }, 'cash', nil, name)

    cb('ok')
end)

RegisterNUICallback('buyAccessories', function(data, cb)
    name = null.fct.input('Nom de l\'accessoire')
    ESX.TriggerServerCallback('Null:clothes:payone', function(good)
        if good then
            -- Vider la sauvegarde des previews car on a acheté
            previewedAccessories = {}
            -- Sauvegarder tous les accessoires achetés dans Skins
            if data.items then
                for category, itemData in pairs(data.items) do
                    Skins[category] = itemData.item
                    if variation[category] then
                        Skins[variation[category]] = itemData.variation
                    end
                end
            end
            Close({type = "accesories", changeSkin = true})
        else
            if data.method == 'bank' then
                ESX.ShowNotification("Vous n'avez pas assez d'argent sur votre compte bancaire")
            else
                ESX.ShowNotification("Vous n'avez pas assez d'argent en liquide")
            end
        end
    end, data.items, data.method, data.group, name)

    cb('ok')
end)


RegisterNUICallback('pay', function(data, cb)
    name = null.fct.input('Nom de la tenue')
    ESX.TriggerServerCallback('Null:clothes:pay', function(good)
        if good then
            Close({type = "clothes", changeSkin = true})
        else
            if data.paymentMethod == 'bank' then
                ESX.ShowNotification("Vous n'avez pas assez d'argent sur votre compte bancaire")
            else
                ESX.ShowNotification("Vous n'avez pas assez d'argent en liquide")
            end
        end
    end, data.items, data.paymentMethod, name)

    cb('ok')
end)

RegisterNUICallback("getMaxVariations", function(data, cb)
    local category = data.category
    -- Pour les accessoires, utiliser previewSkins si disponible (contient l'item en cours de preview)
    local currentValue = Skins[category]
    if isInInterfaceValue == "accesories" and previewSkins[category] ~= nil then
        currentValue = previewSkins[category]
    end
    
    if SkinsToComponents[category] then
        local maxVariations = GetNumberOfPedTextureVariations(PlayerPedId(), SkinsToComponents[category], currentValue)
        cb({ max = maxVariations })
    elseif PropsToComponents[category] then
        local maxVariations = GetNumberOfPedPropTextureVariations(PlayerPedId(), PropsToComponents[category], currentValue)
        cb({ max = maxVariations })
    else
        cb({ max = 0 })
    end
end)

myBucket = 0
RegisterNetEvent("Null:esx:changeBucket", function(value)
    --print("new bucket : "..value)
    myBucket = value
end)

numberToUpdate = 0

function getNumber()
    return numberToUpdate
end

function GenerateSerialNumber()
    local serialNumber = ""
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    for i = 1, 15 do
        local randomIndex = math.random(1, #chars)
        serialNumber = serialNumber .. string.sub(chars, randomIndex, randomIndex)
    end
    return serialNumber
end

-- Export pour ouvrir la tablette
exports('OpenTablet', function(tabletType, data)
    if tabletType == nil then return end
    
    SendNUIMessage({
        action = "openTablet",
        type = tabletType,
        data = data
    })
    SetNuiFocus(true, true)
end)

-- Callback pour fermer la tablette
RegisterNUICallback('closeTablet', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Fonction pour détecter et convertir le type d'une valeur
local function AutoConvertValue(value)
    if value == nil or value == "" then return nil end
    
    -- Conversion en nombre entier
    if value:match("^%-?%d+$") then
        return tonumber(value)
    end
    
    -- Conversion en nombre décimal
    if value:match("^%-?%d*%.%d+$") then
        return tonumber(value)
    end
    
    -- Conversion en booléen
    local lower = value:lower()
    if lower == "true" then return true end
    if lower == "false" then return false end
    
    -- Si c'est une liste de nombres séparés par des virgules
    if value:match("^%-?%d+%.?%d*%s*,%s*%-?%d+%.?%d*$") then
        local numbers = {}
        for num in value:gmatch("%-?%d+%.?%d*") do
            table.insert(numbers, tonumber(num))
        end
        return numbers
    end
    
    -- Sinon retourner la chaîne telle quelle
    return value
end

-- Fonction pour afficher une image à l'écran
function ShowImage(url, x, y, width, height)
    SendNUIMessage({
        type = "SHOW_IMAGE",
        url = url,
        x = x,
        y = y,
        width = width,
        height = height
    })
end

-- Fonction pour supprimer une image ou toutes les images
function RemoveImage(id)
    SendNUIMessage({
        type = "REMOVE_IMAGE",
        id = id -- Si id est nil, toutes les images seront supprimées
    })
end

RegisterNetEvent("SHOW_IMAGE", function(show, url, left, top, width, height)
    if not show then
        RemoveImage()
    else
        ShowImage(url, left, top, width, height)
    end
end)

RegisterCommand("testImage", function()
    ShowImage("https://i.ibb.co/pWzZsCX/LOGO-PNG.png", 100, 200, "monImage")
    ShowImage("https://i.ibb.co/pWzZsCX/LOGO-PNG.png", 400, 300, "monImage2")
    Wait(5000)
    RemoveImage() -- Supprime toutes les images
end)  

-- Exemple d'export pour utiliser les fonctions depuis d'autres ressources
exports("showImage", ShowImage)
exports("removeImage", RemoveImage)

RegisterNetEvent("null-ui:setSafeZone", function(bool)
    null.DebugPrint("SafeZone event received: " .. tostring(bool))
    -- SendNUIMessage({
    --     type = "safezone",
    --     status = bool
    -- })
    TriggerEvent("null:safezone:update", { inSafezone = bool })
end)

RegisterNetEvent("null-ui:updateWarn", function(number, total)
    SendNUIMessage({
        type = "warn:update",
        number = number,
        total = total
    })
end)

RegisterNetEvent("null-ui:AnnounceImage", function(data)
    SendNUIMessage({
        action = "rolePlayAnnounce",
        data = data
    })
end)

RegisterCommand("testWeazelNews", function()
    TriggerEvent("null-ui:AnnounceImage", {
        title = "Test Weazel News",
        description = "Ceci est un test de la fonction weazelNews Ceci est un test de la fonction weazelNews Ceci est un test de la fonction weazelNews",
        time = 120000
    })
end)

--null.InitPrint("^2UI modules loaded")