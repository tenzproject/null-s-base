local isGenerating = false
local currentCamera = nil
local currentPed = nil
local originalCoords = nil
local hudWasVisible = true

local function DisableControls()
    Citizen.CreateThread(function()
        while isGenerating do
            DisableAllControlActions(0)
            Citizen.Wait(0)
        end
    end)
end

local function CreateCamera(offset, rotation, fov)
    if currentCamera then
        DestroyCam(currentCamera, false)
    end
    
    local pedCoords = GetEntityCoords(currentPed)
    local pedHeading = GetEntityHeading(currentPed)
    
    local radians = math.rad(pedHeading)
    local camX = pedCoords.x + (offset.y * math.sin(radians)) + (offset.x * math.cos(radians))
    local camY = pedCoords.y + (offset.y * math.cos(radians)) - (offset.x * math.sin(radians))
    local camZ = pedCoords.z + offset.z
    
    currentCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(currentCamera, camX, camY, camZ)
    SetCamRot(currentCamera, rotation.x, rotation.y, rotation.z + pedHeading, 2)
    SetCamFov(currentCamera, fov)
    SetCamActive(currentCamera, true)
    RenderScriptCams(true, false, 0, true, true)
    
    return currentCamera
end

local function DestroyCamera()
    if currentCamera then
        RenderScriptCams(false, false, 0, true, true)
        DestroyCam(currentCamera, false)
        currentCamera = nil
    end
end

local function ApplyComponent(category, index, gender)
    local mapping = Config.ComponentMapping[category.componentType]
    
    if not mapping then
        print("^1[ImageMaker] Mapping non trouvé pour: " .. category.componentType .. "^0")
        return
    end
    
    if category.componentType == "hair" then
        SetPedComponentVariation(currentPed, mapping.component, index, mapping.texture, 0)
        SetPedHairColor(currentPed, 0, 0)
    elseif category.componentType == "beard" then
        SetPedHeadOverlay(currentPed, mapping.overlay, index, mapping.opacity)
        SetPedHeadOverlayColor(currentPed, mapping.overlay, 1, mapping.color, mapping.color)
    elseif category.componentType == "eyebrows" then
        SetPedHeadOverlay(currentPed, mapping.overlay, index, mapping.opacity)
        SetPedHeadOverlayColor(currentPed, mapping.overlay, 1, mapping.color, mapping.color)
    elseif category.componentType == "chest" then
        SetPedHeadOverlay(currentPed, mapping.overlay, index, mapping.opacity)
        SetPedHeadOverlayColor(currentPed, mapping.overlay, 1, mapping.color, mapping.color)
    elseif category.componentType == "lipstick" then
        SetPedHeadOverlay(currentPed, mapping.overlay, index, mapping.opacity)
        SetPedHeadOverlayColor(currentPed, mapping.overlay, 2, mapping.color, mapping.color)
    elseif category.componentType == "tattoos" then
        ClearPedDecorations(currentPed)
        if index > 0 then
            AddPedDecorationFromHashes(currentPed, GetHashKey(mapping.collection), GetHashKey("FM_Tat_M_" .. string.format("%03d", index)))
        end
    end
    
    Citizen.Wait(100)
end

local function ResetPedAppearance()
    if not currentPed then return end
    
    SetPedDefaultComponentVariation(currentPed)
    ClearPedDecorations(currentPed)
    
    for i = 0, 12 do
        SetPedHeadOverlay(currentPed, i, 0, 0.0)
    end
end

local function TakeScreenshot(category, index, gender)
    local filename = category.name .. "_" .. (category.genderSpecific and gender .. "_" or "") .. index .. ".png"
    
    TriggerServerEvent('null-imagemaker:saveScreenshot', {
        category = category.name,
        index = index,
        gender = gender,
        filename = filename,
        genderSpecific = category.genderSpecific
    })
    
    Citizen.Wait(Config.ScreenshotDelay)
end

local function ProcessCategory(category, gender)
    print("^2[ImageMaker] Traitement: " .. category.label .. " (" .. gender .. ")^0")
    
    CreateCamera(category.camera.offset, category.camera.rotation, category.camera.fov)
    Citizen.Wait(500)
    
    local range = category.ranges[gender]
    local totalItems = (range.max - range.min) + 1
    local processed = 0
    
    for i = range.min, range.max do
        if not isGenerating then
            print("^3[ImageMaker] Génération annulée^0")
            return false
        end
        
        ResetPedAppearance()
        ApplyComponent(category, i, gender)
        
        Citizen.Wait(200)
        
        TakeScreenshot(category, i, gender)
        
        processed = processed + 1
        
        if processed % 10 == 0 then
            print(string.format("^2[ImageMaker] Progression: %d/%d (%.1f%%)^0", processed, totalItems, (processed/totalItems)*100))
        end
    end
    
    return true
end

local function StartGeneration(gender, specificCategory)
    if isGenerating then
        print("^3[ImageMaker] Une génération est déjà en cours^0")
        return
    end
    
    isGenerating = true
    originalCoords = GetEntityCoords(PlayerPedId())
    
    local categoriesToProcess = {}
    
    if specificCategory then
        local found = false
        for _, category in ipairs(Config.Categories) do
            if category.name == specificCategory then
                table.insert(categoriesToProcess, category)
                found = true
                break
            end
        end
        
        if not found then
            print("^1[ImageMaker] Catégorie invalide: " .. specificCategory .. "^0")
            print("^3[ImageMaker] Catégories disponibles: hair, beard, eyebrows, chest_hair, lipstick, tattoos^0")
            isGenerating = false
            return
        end
        
        print("^2[ImageMaker] Démarrage de la génération pour: " .. specificCategory .. " (" .. gender .. ")^0")
    else
        for _, category in ipairs(Config.Categories) do
            table.insert(categoriesToProcess, category)
        end
        print("^2[ImageMaker] Démarrage de la génération complète pour: " .. gender .. "^0")
    end
    
    print("^2[ImageMaker] Désactivation du HUD...^0")
    
    if exports["null-core"] and exports["null-core"].DisplayHud then
        hudWasVisible = true
        exports["null-core"]:DisplayHud(false)
    end
    
    DisableControls()
    
    local modelHash = GetHashKey(Config.PedModels[gender])
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Citizen.Wait(100)
    end
    
    local coords = Config.SpawnCoords
    currentPed = CreatePed(4, modelHash, coords.x, coords.y, coords.z, coords.w, false, true)
    SetEntityAsMissionEntity(currentPed, true, true)
    FreezeEntityPosition(currentPed, true)
    SetEntityInvincible(currentPed, true)
    SetBlockingOfNonTemporaryEvents(currentPed, true)
    
    SetPedCanRagdoll(currentPed, false)
    SetPedCanPlayAmbientAnims(currentPed, false)
    SetPedCanPlayGestureAnims(currentPed, false)
    SetPedCanPlayVisemeAnims(currentPed, false, false)
    SetPedConfigFlag(currentPed, 208, true)
    SetPedConfigFlag(currentPed, 241, true)
    SetPedConfigFlag(currentPed, 149, true)
    
    SetFacialIdleAnimOverride(currentPed, "mood_normal_1", 0)
    
    SetPedDefaultComponentVariation(currentPed)
    ClearPedDecorations(currentPed)
    
    for i = 0, 12 do
        SetPedHeadOverlay(currentPed, i, 0, 0.0)
    end
    
    SetPedHairColor(currentPed, 0, 0)
    SetPedEyeColor(currentPed, 0)
    
    Citizen.Wait(500)
    
    local totalCategories = #categoriesToProcess
    local processedCategories = 0
    
    for _, category in ipairs(categoriesToProcess) do
        if not isGenerating then break end
        
        if category.genderSpecific and gender == "male" or category.genderSpecific and gender == "female" or not category.genderSpecific then
            local success = ProcessCategory(category, gender)
            if not success then break end
            
            processedCategories = processedCategories + 1
            print(string.format("^2[ImageMaker] Catégories: %d/%d terminées^0", processedCategories, totalCategories))
        end
    end
    
    DestroyCamera()
    
    if currentPed then
        DeleteEntity(currentPed)
        currentPed = nil
    end
    
    if hudWasVisible and exports["null-core"] and exports["null-core"].DisplayHud then
        exports["null-core"]:DisplayHud(true)
    end
    
    if originalCoords then
        SetEntityCoords(PlayerPedId(), originalCoords.x, originalCoords.y, originalCoords.z)
    end
    
    isGenerating = false
    
    if processedCategories == totalCategories then
        print("^2[ImageMaker] ✓ Génération terminée avec succès !^0")
        TriggerEvent('chat:addMessage', {
            color = {0, 255, 0},
            multiline = true,
            args = {"ImageMaker", "Génération terminée ! Vérifiez le dossier raw_images"}
        })
    else
        print("^3[ImageMaker] Génération interrompue^0")
    end
end

RegisterCommand('generateicons', function(source, args)
    if #args == 0 then
        print("^3[ImageMaker] Usage:^0")
        print("^3  /generateicons [male|female] - Génère toutes les catégories^0")
        print("^3  /generateicons [category] [male|female] - Génère une catégorie spécifique^0")
        print("^3  Catégories: hair, beard, eyebrows, chest_hair, lipstick, tattoos^0")
        return
    end
    
    local category = nil
    local gender = "male"
    
    if #args == 1 then
        if args[1] == "male" or args[1] == "female" then
            gender = args[1]
        else
            category = args[1]
            gender = "male"
        end
    elseif #args >= 2 then
        category = args[1]
        gender = args[2]
    end
    
    if gender ~= "male" and gender ~= "female" then
        print("^1[ImageMaker] Genre invalide. Utilisez: male ou female^0")
        return
    end
    
    StartGeneration(gender, category)
end, false)

RegisterCommand('stopgeneration', function()
    if isGenerating then
        print("^3[ImageMaker] Arrêt de la génération...^0")
        isGenerating = false
    else
        print("^3[ImageMaker] Aucune génération en cours^0")
    end
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    DestroyCamera()
    
    if currentPed then
        DeleteEntity(currentPed)
    end
    
    if hudWasVisible and exports["null-core"] and exports["null-core"].DisplayHud then
        exports["null-core"]:DisplayHud(true)
    end
end)

print("^2[ImageMaker] Client chargé. Commandes: /generateicons [male|female], /stopgeneration^0")
