-- Créateur de personnage
local isRotating = false
local tempSkinTable = {}
local lastMouseX = 0
local characterData = {
    firstName = "",
    lastName = "",
    birthdate = "",
    gender = "m",
    features = {},
    heritage = {
        mother = 0,
        father = 0,
        resemblance = 50, -- Pourcentage de ressemblance avec le père (0-100)
        skinTone = 50     -- Teint de peau (0-100)
    },
    appearance = {
        hairstyle = 0,
        hairColor = 0,
        eyeColor = 0,
        eyebrows = 0,
        eyebrowColor = 0,
        beard = 0,
        beardColor = 0,
        skinBlemishes = 0,
        skinAgeing = 0,
        skinComplexion = 0,
        skinSunDamage = 0,
        skinMoles = 0,
        skinFreckles = 0,
        lipstick_1 = 0,
        lipstick_2 = 0,
        lipstick_3 = 0,
        lipstick_4 = 0,
    },
    bodyFeatures = {
        noseWidth = 50,
        noseHeight = 50,
        noseLength = 50,
        noseBridge = 50,
        noseTip = 50,
        noseBridgeShift = 50,
        browHeight = 50,
        browWidth = 50,
        cheekboneHeight = 50,
        cheekboneWidth = 50,
        cheeksWidth = 50,
        eyes = 50,
        lips = 50,
        jawWidth = 50,
        jawHeight = 50,
        chinLength = 50,
        chinPosition = 50,
        chinWidth = 50,
        chinShape = 50,
        neckWidth = 50
    },
    clothing = {
        top = 0,
        bottom = 0,
        shoes = 0
    },
    outfit = nil -- Pour stocker l'ID de la tenue prédéfinie
}

-- Définition des tenues prédéfinies
local predefinedOutfits = Config.Creator.OutFits
local startHasNewPlayer = false

-- Fonction pour mettre à jour la position de la caméra du créateur
function UpdateCreatorCameraPosition(cameraType)
    local coords = GetEntityCoords(PlayerPedId())
    -- Créer une caméra de transition si elle n'existe pas
    if not DoesCamExist(transitionCam) then
        transitionCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    end
    
    -- Copier la position et rotation actuelles de la caméra principale vers la caméra de transition
    local currentCamCoord = GetCamCoord(cam)
    local currentCamRot = GetCamRot(cam, 2)
    SetCamCoord(transitionCam, currentCamCoord.x, currentCamCoord.y, currentCamCoord.z)
    SetCamRot(transitionCam, currentCamRot.x, currentCamRot.y, currentCamRot.z, 2)
    
    -- Définir la nouvelle position de la caméra selon le type
    if cameraType == "head" then
        -- Vue tête (pour cheveux, visage, yeux)
        SetCamCoord(cam, coords.x + 0.3, coords.y + 1.0, coords.z + 0.65)
        SetCamRot(cam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(cam, coords.x, coords.y, coords.z + 0.65)
    elseif cameraType == "body" then
        -- Vue corps (torse, bras)
        SetCamCoord(cam, coords.x + 0.5, coords.y + 2.0, coords.z + 0.4)
        SetCamRot(cam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(cam, coords.x, coords.y, coords.z + 0.2)
    elseif cameraType == "legs" then
        -- Vue jambes (pantalons, chaussures)
        SetCamCoord(cam, coords.x + 0.5, coords.y + 2.2, coords.z - 0.2)
        SetCamRot(cam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(cam, coords.x, coords.y, coords.z - 0.4)
    else
        -- Vue par défaut (corps entier)
        SetCamCoord(cam, coords.x + 0.5, coords.y + 2.2, coords.z + 0.3)
        SetCamRot(cam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(cam, coords.x, coords.y, coords.z + 0.2)
    end
    
    -- Activer la transition entre les caméras avec interpolation douce
    SetCamActiveWithInterp(cam, transitionCam, 800, 3, 3) -- 800ms de transition avec easing cubique
end

-- Fonction pour ouvrir le créateur de personnage
function OpenCharacterCreator(first)
    if isInInterface() ~= false then return end
    if first then
        startHasNewPlayer = true
        SetEntityCoords(PlayerPedId(), Config.DefaultPosition.x, Config.DefaultPosition.y, Config.DefaultPosition.z)
        SetEntityHeading(PlayerPedId(), Config.DefaultPosition.w)
    end
    setInInterface("creator")
    FreezeEntityPosition(PlayerPedId(), true)
    -- Désactiver l'interface du jeu
    null.DisplayHud(false)
    
    local data = {}
    local hasSkin = false
    local components, maxVals = getMaxValues()
    for i = 1, #components, 1 do
        data[components[i].name] = {
            value = components[i].value,
            min = components[i].min,
        }
        for k, v in pairs(maxVals) do
            if k == components[i].name then
                data[k].max = v
                break
            end
        end
    end

    -- Récupérer les options disponibles pour le créateur
    local outfits = GetAvailableOutfits()
    -- Envoyer les options au NUI
    SendNUIMessage({
        action = 'updateCreatorData',
        outfits = outfits,
        gender = characterData.gender,
        maxValues = {
            father = maxVals.dad,
            mother = maxVals.mom,
            hairstyle = maxVals.hair_1,
            hairColor = maxVals.hair_color_1,
            eyebrows = maxVals.eyebrows_1,
            beard = maxVals.beard_1,
            eyeColor = math.min(tonumber(maxVals.eye_color) or 29, 29),
            beardColor = maxVals.beard_3,
            eyebrowColor = maxVals.eyebrows_3,
            lipstickStyle = maxVals.lipstick_1,
            lipstickColor = maxVals.lipstick_3,
            chestHair = maxVals.chest_1,
            blemishes = maxVals.blemishes_1
        }
    })

    tempSkinTable = Character_ESX
    TriggerEvent('Null:skinchanger:getData', function(comp, max)
        for k, v in pairs(comp) do
            data[v.name].value = tonumber(v.value)
            tempSkinTable[v.name] = tonumber(v.value)
        end
        hasSkin = true
    end)

    -- Créer la caméra
    CreateSkinCam()
    
    SetPlayerControl(PlayerId(), false, 12)
    
    -- Afficher l'interface NUI
    SetNuiFocus(true, true)
    SendNUIMessage({
        type = "open",
        category = "creator"
    })
    
    -- Envoyer les données initiales
    SendCreatorData()
end

-- Fonction pour envoyer les données au créateur
function SendCreatorData()
    -- Envoyer les données des parents disponibles, coiffures, etc.
    SendNUIMessage({
        action = "updateCreatorData",
        parents = {
            fathers = GetAvailableFathers(),
            mothers = GetAvailableMothers()
        },
        hairstyles = GetAvailableHairstyles(),
        beards = GetAvailableBeards(),
        eyebrows = GetAvailableEyebrows(),
        clothes = {
            tops = GetAvailableTops(),
            bottoms = GetAvailableBottoms(),
            shoes = GetAvailableShoes()
        },
        gender = characterData.gender,
        outfits = GetAvailableOutfits()
    })
end

-- Empêcher la fermeture NUI depuis l'UI si le joueur est dans le créateur
RegisterNUICallback('close', function(data, cb)
    if isInInterface() == "creator" then
        cb('ok')
        return
    end
    cb('ok')
end)

-- Fonctions pour obtenir les options disponibles
function GetAvailableFathers()
    local fathers = {}
    for i = 0, 45 do -- Ajustez selon les IDs disponibles dans GTA
        table.insert(fathers, i)
    end
    return fathers
end

function GetAvailableMothers()
    local mothers = {}
    for i = 0, 45 do -- Ajustez selon les IDs disponibles dans GTA
        table.insert(mothers, i)
    end
    return mothers
end

function GetAvailableHairstyles()
    local hairstyles = {}
    local maxHairstyles = characterData.gender == "m" and 73 or 77 -- Différentes limites selon le genre
    for i = 0, maxHairstyles do
        table.insert(hairstyles, i)
    end
    return hairstyles
end

function GetAvailableBeards()
    local beards = {}
    if characterData.gender == "m" then
        for i = 0, 28 do -- Seulement pour les hommes
            table.insert(beards, i)
        end
    end
    return beards
end

function GetAvailableEyebrows()
    local eyebrows = {}
    for i = 0, 33 do
        table.insert(eyebrows, i)
    end
    return eyebrows
end

function GetAvailableTops()
    local tops = {}
    local maxTops = characterData.gender == "m" and 196 or 233 -- Différentes limites selon le genre
    for i = 0, maxTops do
        -- Filtrer les tops blacklistés si nécessaire
        if not IsClothingBlacklisted("torso_1", i) then
            table.insert(tops, i)
        end
    end
    return tops
end

function GetAvailableBottoms()
    local bottoms = {}
    local maxBottoms = characterData.gender == "m" and 121 or 135 -- Différentes limites selon le genre
    for i = 0, maxBottoms do
        -- Filtrer les bottoms blacklistés si nécessaire
        if not IsClothingBlacklisted("pants_1", i) then
            table.insert(bottoms, i)
        end
    end
    return bottoms
end

function GetAvailableShoes()
    local shoes = {}
    local maxShoes = characterData.gender == "m" and 97 or 104 -- Différentes limites selon le genre
    for i = 0, maxShoes do
        -- Filtrer les chaussures blacklistées si nécessaire
        if not IsClothingBlacklisted("shoes_1", i) then
            table.insert(shoes, i)
        end
    end
    return shoes
end

function GetAvailableOutfits()
    local outfits = {}
    for k,v in pairs(predefinedOutfits) do
        local tempGender = characterData.gender
        if v[tempGender] then
            outfits[k] = v[tempGender]
        end
    end
    return outfits
end

-- Fonction pour vérifier si un vêtement est blacklisté
function IsClothingBlacklisted(component, id)
    if Config and Config.ClothingShop and Config.ClothingShop.blackListed then
        local blacklist = Config.ClothingShop.blackListed[component]
        if blacklist then
            for _, blacklistedId in ipairs(blacklist) do
                if blacklistedId == id then
                    return true
                end
            end
        end
    end
    return false
end

function ChangeCharacterData(component, value)
    tempSkinTable[component] = value
    TriggerEvent('Null:skinchanger:change', component, value)
    updateValue(tempSkinTable)
end


-- Callbacks NUI pour le créateur de personnage

-- Callback principal charInfo (Style Nykz-characterCreator)
RegisterNUICallback('charInfo', function(data, cb)
    local ped = PlayerPedId()
    
    -- Changement de sexe
    if data.sex ~= nil then
        characterData.gender = data.sex == 0 and "m" or "f"
        local model = data.sex == 0 and GetHashKey('mp_m_freemode_01') or GetHashKey('mp_f_freemode_01')
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
        SetPlayerModel(PlayerId(), model)
        SetPedDefaultComponentVariation(PlayerPedId())
        ped = PlayerPedId()
        -- Initialiser le head blend
        SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.0, false)
        while not HasPedHeadBlendFinished(ped) do
            Wait(0)
        end
        tempSkinTable['sex'] = data.sex
    end
    
    -- Heritage (parents)
    if data.heritage then
        local h = data.heritage
        if h.faceFather ~= nil then
            characterData.heritage.father = h.faceFather
            tempSkinTable['dad'] = h.faceFather
        end
        if h.faceMother ~= nil then
            characterData.heritage.mother = h.faceMother
            tempSkinTable['mom'] = h.faceMother
        end
        if h.skinFather ~= nil then
            tempSkinTable['skin_father'] = h.skinFather
        end
        if h.skinMother ~= nil then
            tempSkinTable['skin_mother'] = h.skinMother
        end
        if h.faceMix ~= nil then
            characterData.heritage.resemblance = h.faceMix * 100
            tempSkinTable['face_md_weight'] = math.floor(h.faceMix * 100)
        end
        if h.skinMix ~= nil then
            characterData.heritage.skinTone = h.skinMix * 100
            tempSkinTable['skin_md_weight'] = math.floor(h.skinMix * 100)
        end
        
        local faceMix = (tempSkinTable['face_md_weight'] or 50) / 100
        local skinMix = (tempSkinTable['skin_md_weight'] or 50) / 100
        SetPedHeadBlendData(ped, tempSkinTable['mom'] or 21, tempSkinTable['dad'] or 0, 0, 
                           tempSkinTable['mom'] or 21, tempSkinTable['dad'] or 0, 0, 
                           faceMix, skinMix, 0.0, false)
    end
    
    -- Face features
    if data.face then
        local f = data.face
        if f.noseWidth ~= nil then
            tempSkinTable['nose_1'] = math.floor(f.noseWidth * 10)
            SetPedFaceFeature(ped, 0, f.noseWidth)
        end
        if f.noseHeight ~= nil then
            tempSkinTable['nose_2'] = math.floor(f.noseHeight * 10)
            SetPedFaceFeature(ped, 1, f.noseHeight)
        end
        if f.noseLength ~= nil then
            tempSkinTable['nose_3'] = math.floor(f.noseLength * 10)
            SetPedFaceFeature(ped, 2, f.noseLength)
        end
        if f.noseBase ~= nil then
            tempSkinTable['nose_4'] = math.floor(f.noseBase * 10)
            SetPedFaceFeature(ped, 3, f.noseBase)
        end
        if f.noseRotation ~= nil then
            tempSkinTable['nose_5'] = math.floor(f.noseRotation * 10)
            SetPedFaceFeature(ped, 4, f.noseRotation)
        end
        if f.cheekBones ~= nil then
            tempSkinTable['cheeks_1'] = math.floor(f.cheekBones * 10)
            SetPedFaceFeature(ped, 8, f.cheekBones)
        end
        if f.eyeOpenness ~= nil then
            tempSkinTable['eye_squint'] = math.floor(f.eyeOpenness * 10)
            SetPedFaceFeature(ped, 11, f.eyeOpenness)
        end
        if f.lipThickness ~= nil then
            tempSkinTable['lip_thickness'] = math.floor(f.lipThickness * 10)
            SetPedFaceFeature(ped, 12, f.lipThickness)
        end
        if f.chinHeight ~= nil then
            tempSkinTable['chin_1'] = math.floor(f.chinHeight * 10)
            SetPedFaceFeature(ped, 15, f.chinHeight)
        end
        if f.chinLength ~= nil then
            tempSkinTable['chin_2'] = math.floor(f.chinLength * 10)
            SetPedFaceFeature(ped, 16, f.chinLength)
        end
        if f.chinWidth ~= nil then
            tempSkinTable['chin_3'] = math.floor(f.chinWidth * 10)
            SetPedFaceFeature(ped, 17, f.chinWidth)
        end
        if f.neckThickness ~= nil then
            tempSkinTable['neck_thickness'] = math.floor(f.neckThickness * 10)
            SetPedFaceFeature(ped, 19, f.neckThickness)
        end
    end
    
    -- Hair
    if data.hair then
        local h = data.hair
        if h.style ~= nil then
            characterData.appearance.hairstyle = h.style
            tempSkinTable['hair_1'] = h.style
            SetPedComponentVariation(ped, 2, h.style, 0, 2)
        end
        if h.color ~= nil then
            characterData.appearance.hairColor = h.color
            tempSkinTable['hair_color_1'] = h.color
        end
        if h.highlight ~= nil then
            tempSkinTable['hair_color_2'] = h.highlight
        end
        SetPedHairColor(ped, tempSkinTable['hair_color_1'] or 0, tempSkinTable['hair_color_2'] or 0)
    end
    
    -- Beard
    if data.beard then
        local b = data.beard
        if b.style ~= nil then
            characterData.appearance.beard = b.style
            tempSkinTable['beard_1'] = b.style
        end
        if b.color ~= nil then
            characterData.appearance.beardColor = b.color
            tempSkinTable['beard_3'] = b.color
        end
        if b.opacity ~= nil then
            tempSkinTable['beard_2'] = math.floor(b.opacity * 10)
        end
        SetPedHeadOverlay(ped, 1, tempSkinTable['beard_1'] or 0, (tempSkinTable['beard_2'] or 0) / 10)
        SetPedHeadOverlayColor(ped, 1, 1, tempSkinTable['beard_3'] or 0, 0)
    end
    
    -- Eyebrows
    if data.eyebrows then
        local e = data.eyebrows
        if e.style ~= nil then
            characterData.appearance.eyebrows = e.style
            tempSkinTable['eyebrows_1'] = e.style
        end
        if e.color ~= nil then
            characterData.appearance.eyebrowColor = e.color
            tempSkinTable['eyebrows_5'] = e.color
        end
        if e.opacity ~= nil then
            tempSkinTable['eyebrows_2'] = math.floor(e.opacity * 10)
        end
        SetPedHeadOverlay(ped, 2, tempSkinTable['eyebrows_1'] or 0, (tempSkinTable['eyebrows_2'] or 0) / 10)
        SetPedHeadOverlayColor(ped, 2, 1, tempSkinTable['eyebrows_5'] or 0, 0)
    end
    
    -- Appearance
    if data.appearance then
        local a = data.appearance
        if a.eyeColor ~= nil then
            local eyeColor = tonumber(a.eyeColor) or 0
            if eyeColor < 0 then eyeColor = 0 end
            if eyeColor > 29 then eyeColor = 29 end
            characterData.appearance.eyeColor = eyeColor
            tempSkinTable['eye_color'] = eyeColor
            SetPedEyeColor(ped, eyeColor)
        end
        if a.blemishes ~= nil then
            tempSkinTable['blemishes_1'] = a.blemishes
        end
        if a.blemishesOpacity ~= nil then
            tempSkinTable['blemishes_2'] = math.floor(a.blemishesOpacity * 10)
        end
        SetPedHeadOverlay(ped, 0, tempSkinTable['blemishes_1'] or 0, (tempSkinTable['blemishes_2'] or 0) / 10)
        
        if a.chestHair ~= nil then
            tempSkinTable['chest_1'] = a.chestHair
        end
        if a.chestHairOpacity ~= nil then
            tempSkinTable['chest_2'] = math.floor(a.chestHairOpacity * 10)
        end
        if a.chestHairColor ~= nil then
            tempSkinTable['chest_3'] = a.chestHairColor
        end
        SetPedHeadOverlay(ped, 10, tempSkinTable['chest_1'] or 0, (tempSkinTable['chest_2'] or 0) / 10)
        SetPedHeadOverlayColor(ped, 10, 1, tempSkinTable['chest_3'] or 0, 0)
        
        if a.lipstick ~= nil then
            tempSkinTable['lipstick_1'] = a.lipstick
        end
        if a.lipstickOpacity ~= nil then
            tempSkinTable['lipstick_2'] = math.floor(a.lipstickOpacity * 10)
        end
        if a.lipstickColor ~= nil then
            tempSkinTable['lipstick_3'] = a.lipstickColor
        end
        SetPedHeadOverlay(ped, 8, tempSkinTable['lipstick_1'] or 0, (tempSkinTable['lipstick_2'] or 0) / 10)
        SetPedHeadOverlayColor(ped, 8, 2, tempSkinTable['lipstick_3'] or 0, 0)
    end
    
    if cb then cb('ok') end
end)

-- Callback rotation (Style Nykz-characterCreator)
RegisterNUICallback('rotate', function(data, cb)
    if data.delta then
        local heading = GetEntityHeading(PlayerPedId())
        heading = heading + data.delta
        if heading > 360 then heading = heading - 360 end
        if heading < 0 then heading = heading + 360 end
        SetEntityHeading(PlayerPedId(), heading)
    end
    if cb then cb('ok') end
end)

-- Callback sauvegarde personnage (Style Nykz-characterCreator)
RegisterNUICallback('saveCharacter', function(data, cb)
    local identity = data.identity or {}
    local skin = data.skin or {}
    
    -- Mettre à jour characterData
    characterData.firstName = identity.firstName or ""
    characterData.lastName = identity.lastName or ""
    
    -- Convertir le format de date DD/MM/YYYY vers YYYY-MM-DD
    local dateOfBirth = identity.dateOfBirth or ""
    if dateOfBirth ~= "" and dateOfBirth:match("^%d%d/%d%d/%d%d%d%d$") then
        local day, month, year = dateOfBirth:match("^(%d%d)/(%d%d)/(%d%d%d%d)$")
        dateOfBirth = year .. "-" .. month .. "-" .. day
    end
    characterData.birthdate = dateOfBirth
    characterData.gender = identity.sex == 0 and "m" or "f"
    
    -- Fusionner le skin avec tempSkinTable
    for k, v in pairs(skin) do
        tempSkinTable[k] = v
    end
    
    -- Appeler la fonction de sauvegarde existante
    SaveCharacter(function()
        -- Fermer l'interface
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = "close"
        })
        
        SetPlayerControl(PlayerId(), true, 12)
        null.DisplayHud(true)
        
        if DoesCamExist(cam) then
            DestroyCam(cam, true)
        end
        clearInterface()
        DeleteSkinCam()
        AffichePreviewPed = false
    end)
    
    
    if cb then cb('ok') end
end)

-- Héritage - Père
RegisterNUICallback('faceFather', function(data, cb)
    local value = tonumber(data) or 0
    characterData.heritage.father = value
    ChangeCharacterData("dad", value)
    if cb then cb('ok') end
end)

-- Héritage - Mère
RegisterNUICallback('faceMother', function(data, cb)
    local value = tonumber(data) or 21
    characterData.heritage.mother = value
    ChangeCharacterData("mom", value)
    if cb then cb('ok') end
end)

-- Héritage - Teint de peau
RegisterNUICallback('skinTone', function(data, cb)
    local value = tonumber(data) or 0
    characterData.heritage.skinTone = value
    ChangeCharacterData("skin_md_weight", value * 10)
    if cb then cb('ok') end
end)

-- Héritage - Mix facial
RegisterNUICallback('faceMix', function(data, cb)
    local value = tonumber(data) or 0.5
    characterData.heritage.resemblance = value * 100
    ChangeCharacterData("face_md_weight", math.floor(value * 100))
    if cb then cb('ok') end
end)

-- Cheveux - Style
RegisterNUICallback('hairstyle', function(data, cb)
    local value = tonumber(data) or 0
    characterData.appearance.hairstyle = value
    ChangeCharacterData("hair_1", value)
    if cb then cb('ok') end
end)

-- Cheveux - Couleur
RegisterNUICallback('hairColor', function(data, cb)
    local value = tonumber(data) or 0
    characterData.appearance.hairColor = value
    ChangeCharacterData("hair_color_1", value)
    if cb then cb('ok') end
end)

-- Cheveux - Reflets
RegisterNUICallback('hairHighlight', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("hair_color_2", value)
    if cb then cb('ok') end
end)

-- Barbe - Style
RegisterNUICallback('beardStyle', function(data, cb)
    local value = tonumber(data) or 0
    characterData.appearance.beard = value
    ChangeCharacterData("beard_1", value)
    if cb then cb('ok') end
end)

-- Barbe - Opacité
RegisterNUICallback('beard-opacity', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("beard_2", math.floor(value * 10))
    if cb then cb('ok') end
end)

-- Barbe - Couleur
RegisterNUICallback('beardColor', function(data, cb)
    local value = tonumber(data) or 0
    characterData.appearance.beardColor = value
    ChangeCharacterData("beard_3", value)
    if cb then cb('ok') end
end)

-- Sourcils - Style
RegisterNUICallback('eyebrowStyle', function(data, cb)
    local value = tonumber(data) or 0
    characterData.appearance.eyebrows = value
    ChangeCharacterData("eyebrows_1", value)
    if cb then cb('ok') end
end)

-- Sourcils - Opacité
RegisterNUICallback('eyebrows-opacity', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("eyebrows_2", math.floor(value * 10))
    if cb then cb('ok') end
end)

-- Sourcils - Couleur
RegisterNUICallback('eyebrowColor', function(data, cb)
    local value = tonumber(data) or 0
    characterData.appearance.eyebrowColor = value
    ChangeCharacterData("eyebrows_3", value)
    if cb then cb('ok') end
end)

-- Yeux - Couleur
RegisterNUICallback('eyeColor', function(data, cb)
    local value = tonumber(data) or 0
    if value < 0 then value = 0 end
    if value > 29 then value = 29 end
    characterData.appearance.eyeColor = value
    ChangeCharacterData("eye_color", value)
    if cb then cb('ok') end
end)

-- Rouge à lèvres - Style
RegisterNUICallback('lipstickStyle', function(data, cb)
    local value = tonumber(data) or 0
    characterData.appearance.lipstick_1 = value
    ChangeCharacterData("lipstick_1", value)
    if cb then cb('ok') end
end)

-- Rouge à lèvres - Opacité
RegisterNUICallback('lipstick-opacity', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("lipstick_2", math.floor(value * 10))
    if cb then cb('ok') end
end)

-- Rouge à lèvres - Couleur
RegisterNUICallback('lipstickColor', function(data, cb)
    local value = tonumber(data) or 0
    characterData.appearance.lipstick_3 = value
    ChangeCharacterData("lipstick_3", value)
    if cb then cb('ok') end
end)

-- Pilosité corporelle - Style
RegisterNUICallback('chestHair', function(data, cb)
    local value = tonumber(data) or 0
    characterData.appearance.chestHair = value
    ChangeCharacterData("chest_1", value)
    if cb then cb('ok') end
end)

-- Pilosité corporelle - Opacité
RegisterNUICallback('chest-hair-opacity', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("chest_2", math.floor(value * 10))
    if cb then cb('ok') end
end)

-- Pilosité corporelle - Couleur
RegisterNUICallback('chestHairColor', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("chest_3", value)
    if cb then cb('ok') end
end)

-- Imperfections - Style
RegisterNUICallback('blemishesStyle', function(data, cb)
    local value = tonumber(data) or 0
    characterData.appearance.blemishes = value
    ChangeCharacterData("blemishes_1", value)
    if cb then cb('ok') end
end)

-- Imperfections - Opacité
RegisterNUICallback('blemishes-opacity', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("blemishes_2", math.floor(value * 10))
    if cb then cb('ok') end
end)

-- Traits du visage
RegisterNUICallback('eyeOpenness', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("eye_squint", math.floor(value * 10))
    if cb then cb('ok') end
end)

RegisterNUICallback('noseWidth', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("nose_1", math.floor(value * 10))
    if cb then cb('ok') end
end)

RegisterNUICallback('noseLength', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("nose_2", math.floor(value * 10))
    if cb then cb('ok') end
end)

RegisterNUICallback('noseHeight', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("nose_3", math.floor(value * 10))
    if cb then cb('ok') end
end)

RegisterNUICallback('noseRotation', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("nose_4", math.floor(value * 10))
    if cb then cb('ok') end
end)

RegisterNUICallback('noseBase', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("nose_5", math.floor(value * 10))
    if cb then cb('ok') end
end)

RegisterNUICallback('cheekBones', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("cheeks_1", math.floor(value * 10))
    if cb then cb('ok') end
end)

RegisterNUICallback('lipThickness', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("lip_thickness", math.floor(value * 10))
    if cb then cb('ok') end
end)

RegisterNUICallback('chinLength', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("chin_1", math.floor(value * 10))
    if cb then cb('ok') end
end)

RegisterNUICallback('chinWidth', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("chin_3", math.floor(value * 10))
    if cb then cb('ok') end
end)

RegisterNUICallback('chinHeight', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("chin_2", math.floor(value * 10))
    if cb then cb('ok') end
end)

RegisterNUICallback('neckThickness', function(data, cb)
    local value = tonumber(data) or 0
    ChangeCharacterData("neck_thickness", math.floor(value * 10))
    if cb then cb('ok') end
end)

-- Tenues prédéfinies
RegisterNUICallback('outfit', function(data, cb)
    local value = data
    characterData.outfit = value
    
    local outfits = GetAvailableOutfits()
    for name, outfit in pairs(outfits) do
        if name == value then
            characterData.outfit = outfit
            TriggerEvent('Null:skinchanger:loadClothes', tempSkinTable, outfit)
            for k, v in pairs(outfit) do
                tempSkinTable[k] = v
            end
            updateValue(tempSkinTable)
            break
        end
    end
    
    if cb then cb('ok') end
end)

-- Taille
RegisterNUICallback('height', function(data, cb)
    local value = tonumber(data) or 175
    characterData.height = value
    if cb then cb('ok') end
end)

-- Callback générique pour compatibilité
RegisterNUICallback('updateFeature', function(data, cb)
    local feature = data.feature
    local value = data.value
    
    if feature and value then
        if feature == "sex" then
            characterData.gender = value
            local sexValue = value == "m" and 0 or 1
            ChangeCharacterData("sex", sexValue)
        elseif feature == "outfits-grid" then
            characterData.outfit = value
            local outfits = GetAvailableOutfits()
            for name, outfit in pairs(outfits) do
                if name == value then
                    characterData.outfit = outfit
                    TriggerEvent('Null:skinchanger:loadClothes', tempSkinTable, outfit)
                    for k, v in pairs(outfit) do
                        tempSkinTable[k] = v
                    end
                    updateValue(tempSkinTable)
                    break
                end
            end
        end
    end
    
    if cb then cb('ok') end
end)

RegisterNUICallback('updateInfo', function(data, cb)
    local field = data.field
    local value = data.value
    
    -- Mettre à jour les informations du personnage
    if field == "firstname" then
        characterData.firstName = value
    elseif field == "lastname" then
        characterData.lastName = value
    elseif field == "birthdate" then
        characterData.birthdate = value
    elseif field == "gender" then
        characterData.gender = value
        -- Réinitialiser certaines caractéristiques spécifiques au genre
        if value == "f" then
            characterData.appearance.beard = 0
            tempSkinTable["sex"] = 1
            tempSkinTable["glasses_1"] = -1
            tempSkinTable["glasses_2"] = 0
            TriggerEvent("Null:skinchanger:change", "sex", 1)
            TriggerEvent("Null:skinchanger:change", "glasses_1", -1)
            TriggerEvent("Null:skinchanger:change", "glasses_2", 0)
        elseif value == "m" then
            tempSkinTable["sex"] = 0
            TriggerEvent("Null:skinchanger:change", "sex", 0)
        end
        -- Recharger les options disponibles
        SendCreatorData()
    end
    
    if cb then cb('ok') end
end)

-- Callback pour changer la position de la caméra
RegisterNUICallback('creatorCameraChange', function(data, cb)
    if data.camera then
        UpdateCreatorCameraPosition(data.camera)
    end
    if cb then cb('ok') end
end)

-- Callback pour réinitialiser le créateur
RegisterNUICallback('resetCreator', function(data, cb)
    -- Réinitialiser toutes les valeurs du personnage aux valeurs par défaut
    local ped = PlayerPedId()
    
    -- Réinitialiser l'héritage
    ChangeCharacterData("dad", 0)
    ChangeCharacterData("mom", 21)
    ChangeCharacterData("face_md_weight", 50)
    ChangeCharacterData("skin_md_weight", 50)
    
    -- Réinitialiser les cheveux
    ChangeCharacterData("hair_1", 0)
    ChangeCharacterData("hair_color_1", 0)
    ChangeCharacterData("hair_color_2", 0)
    
    -- Réinitialiser la barbe
    ChangeCharacterData("beard_1", 0)
    ChangeCharacterData("beard_2", 0)
    ChangeCharacterData("beard_3", 0)
    
    -- Réinitialiser les sourcils
    ChangeCharacterData("eyebrows_1", 0)
    ChangeCharacterData("eyebrows_2", 0)
    ChangeCharacterData("eyebrows_3", 0)
    
    -- Réinitialiser les yeux
    ChangeCharacterData("eye_color", 0)
    
    -- Réinitialiser les traits du visage
    ChangeCharacterData("eye_squint", 0)
    ChangeCharacterData("nose_1", 0)
    ChangeCharacterData("nose_2", 0)
    ChangeCharacterData("nose_3", 0)
    ChangeCharacterData("nose_4", 0)
    ChangeCharacterData("nose_5", 0)
    ChangeCharacterData("cheeks_1", 0)
    ChangeCharacterData("lip_thickness", 0)
    ChangeCharacterData("chin_1", 0)
    ChangeCharacterData("chin_3", 0)
    ChangeCharacterData("chin_4", 0)
    ChangeCharacterData("neck_thickness", 0)
    
    -- Réinitialiser le maquillage
    ChangeCharacterData("lipstick_1", 0)
    ChangeCharacterData("lipstick_2", 0)
    ChangeCharacterData("lipstick_3", 0)
    
    -- Réinitialiser la pilosité corporelle
    ChangeCharacterData("chest_1", 0)
    ChangeCharacterData("chest_2", 0)
    ChangeCharacterData("chest_3", 0)
    
    -- Réinitialiser les imperfections
    ChangeCharacterData("blemishes_1", 0)
    ChangeCharacterData("blemishes_2", 0)
    
    -- Réinitialiser les données du personnage
    characterData.heritage = {
        mother = 21,
        father = 0,
        resemblance = 50,
        skinTone = 50
    }
    characterData.appearance = {
        hairstyle = 0,
        hairColor = 0,
        eyeColor = 0,
        eyebrows = 0,
        eyebrowColor = 0,
        beard = 0,
        beardColor = 0
    }
    
    if cb then cb('ok') end
end)

RegisterNUICallback('finishCreator', function(data, cb)
    -- Mettre à jour les informations du personnage depuis le formulaire
    if data.firstname then
        characterData.firstName = data.firstname
    end
    if data.lastname then
        characterData.lastName = data.lastname
    end
    if data.birthdate then
        local birthdate = data.birthdate
        -- Convertir le format de date si nécessaire (DD/MM/YYYY -> YYYY-MM-DD)
        if birthdate:match("^%d%d/%d%d/%d%d%d%d$") then
            local day, month, year = birthdate:match("^(%d%d)/(%d%d)/(%d%d%d%d)$")
            birthdate = year .. "-" .. month .. "-" .. day
        elseif birthdate:match("^%d%d%d%d%-%d%d%-%d%d$") then
            -- Déjà au bon format
        else
            -- Format invalide, essayer de parser quand même
            print("Format de date non reconnu: " .. birthdate)
        end
        characterData.birthdate = birthdate
    end
    
    -- Sauvegarder les données du personnage
    SaveCharacter(function()
        -- Fermer l'interface
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = "close"
        })
        
        SetPlayerControl(PlayerId(), true, 12)
        -- Restaurer l'interface du jeu
        null.DisplayHud(true)
        
        -- Détruire la caméra
        if DoesCamExist(cam) then
            DestroyCam(cam, true)
        end
        clearInterface()
        DeleteSkinCam()
        AffichePreviewPed = false

        if startHasNewPlayer then
            
        end
    end)

    
    if cb then cb('ok') end
end)

RegisterNUICallback('finishCreation', function(data, cb)
    -- Sauvegarder les données du personnage
    SaveCharacter(function()
        -- Fermer l'interface
        SetNuiFocus(false, false)
        SendNUIMessage({
            type = "close"
        })
        
        SetPlayerControl(PlayerId(), true, 12)
        -- Restaurer l'interface du jeu
        null.DisplayHud(true)
        
        -- Détruire la caméra
        if DoesCamExist(cam) then
            DestroyCam(cam, true)
        end
        clearInterface()
        DeleteSkinCam()
        AffichePreviewPed = false

        if startHasNewPlayer then
            
        end
    end)

    
    if cb then cb('ok') end
end)


-- Fonction pour appliquer les changements au personnage
function ApplyCharacterChanges()
    local playerPed = PlayerPedId()
    
end

-- Fonction pour sauvegarder le personnage
function SaveCharacter(cb)
    -- Vérifier que les informations essentielles sont présentes
    if characterData.firstName == "" or characterData.lastName == "" or characterData.birthdate == "" then
        -- Afficher une notification d'erreur
        TriggerEvent('esx:showNotification', "Veuillez remplir toutes les ~r~informations~s~ personnelles.")
        return
    end

    if characterData.birthdate then
        --2000-09-09
        local years = tonumber(characterData.birthdate:sub(1, 4))
        local mount = tonumber(characterData.birthdate:sub(6, 7))
        local day = tonumber(characterData.birthdate:sub(9, 10))
        if years > 2020 or years < 1940 then
            TriggerEvent('esx:showNotification', "Votre ~r~année de naissance~s~ n'est pas correcte.")
            return 
        end
        if mount <= 0 or mount >= 13 then
            TriggerEvent('esx:showNotification', "Votre ~r~mois de naissance~s~ n'est pas correcte.")
            return 
        end
        if day <= 0 or day >= 32 then
            TriggerEvent('esx:showNotification', "Votre ~r~jour de naissance~s~ n'est pas correcte.")
            return 
        end

    end

    local clotheSave = {
        ['tshirt_1'] = "top",
        ['tshirt_2'] = "top",
        ['torso_1'] = "top",
        ['torso_2'] = "top",
        ['decals_1'] = "top",
        ['arms'] = "top",
        ['pants_1'] = "pants",
        ['pants_2'] = "pants",
        ['shoes_1'] = "shoes",
        ['shoes_2'] = "shoes",
    }
    FreezeEntityPosition(PlayerPedId(), false)

    TriggerEvent('Null:skinchanger:getSkin', function(skin)
        TriggerServerEvent('Null:esx_skin:save', skin)
        local top = {}
        local pant = {}
        local shoes = {}
        for k,v in pairs(skin) do         
            if clotheSave[k] then    
                if k == "tshirt_1" then
                    top[k] = v
                elseif k == "tshirt_2" then
                    top[k] = v
                elseif k == "torso_1" then
                    top[k] = v
                elseif k == "torso_2" then
                    top[k] = v
                elseif k == "decals_1" then
                    top[k] = v
                elseif k == "arms" then
                    top[k] = v
                elseif k == "pants_1" then
                    pant[k] = v
                elseif k == "pants_2" then
                    pant[k] = v
                elseif k == "shoes_1" then
                    shoes[k] = v
                elseif k == "shoes_2" then
                    shoes[k] = v
                end
            end
        end
        local topid = tonumber(math.random(0,9)..""..math.random(0,9)..""..math.random(0,9)..""..math.random(0,9)..""..math.random(0,9)..""..math.random(0,9))
        local pantsid = tonumber(math.random(0,9)..""..math.random(0,9)..""..math.random(0,9)..""..math.random(0,9)..""..math.random(0,9)..""..math.random(0,9))
        local shoesid = tonumber(math.random(0,9)..""..math.random(0,9)..""..math.random(0,9)..""..math.random(0,9)..""..math.random(0,9)..""..math.random(0,9))

        TriggerServerEvent('null:clothe:addClothinInvWithID', "top", "Tenue d'arriver", top, topid)
        TriggerServerEvent('null:clothe:addClothinInvWithID', "pants", "Tenue d'arriver", pant, pantsid)
        TriggerServerEvent('null:clothe:addClothinInvWithID', "shoes", "Tenue d'arriver", shoes, shoesid)

        if cb then cb() end

        TriggerServerEvent("Null:charCreator:finish", characterData)
        TriggerServerEvent("null:esx:enter", false)
    end)
end

-- Fonction pour obtenir l'index d'une caractéristique faciale
function GetPedFaceFeatureIndex(feature)
    local featureIndices = {
        noseWidth = 0,
        noseHeight = 1,
        noseLength = 2,
        noseBridge = 3,
        noseTip = 4,
        noseBridgeShift = 5,
        browHeight = 6,
        browWidth = 7,
        cheekboneHeight = 8,
        cheekboneWidth = 9,
        cheeksWidth = 10,
        eyes = 11,
        lips = 12,
        jawWidth = 13,
        jawHeight = 14,
        chinLength = 15,
        chinPosition = 16,
        chinWidth = 17,
        chinShape = 18,
        neckWidth = 19
    }
    
    return featureIndices[feature] or -1
end

-- Commande pour tester le créateur de personnage
RegisterCommand('openCreator', function()
    OpenCharacterCreator()
end, false)

-- Exporter la fonction pour qu'elle puisse être appelée depuis d'autres ressources
exports('OpenCharacterCreator', OpenCharacterCreator)


RegisterNetEvent("NullUI:openCreator", OpenCharacterCreator)


Character_ESX = {}

local Components = {
	{name = 'sex',				value = 0,		min = 0},
	{name = 'mom',				value = 21,		min = 21},
	{name = 'dad',				value = 0,		min = 0},
	{name = 'face_md_weight',	value = 100,		min = 0},
	{name = 'skin_md_weight',	value = 0,    min = 0},
	{name = 'nose_1',			value = 0,		min = -10},
	{name = 'nose_2',			value = 0,		min = -10},
	{name = 'nose_3',			value = 0,		min = -10},
	{name = 'nose_4',			value = 0,		min = -10},
	{name = 'nose_5',			value = 0,		min = -10},
	{name = 'nose_6',			value = 0,		min = -10},
	{name = 'cheeks_1',			value = 0,		min = -10},
	{name = 'cheeks_2',			value = 0,		min = -10},
	{name = 'cheeks_3',			value = 0,		min = -10},
	{name = 'lip_thickness',	value = 0,		min = -10},
	{name = 'jaw_1',			value = 0,		min = -10},
	{name = 'jaw_2',			value = 0,		min = -10},
	{name = 'chin_1',			value = 0,		min = -10},
	{name = 'chin_2',			value = 0,		min = -10},
	{name = 'chin_3',			value = 0,		min = -10},
	{name = 'chin_4',			value = 0,		min = -10},
	{name = 'neck_thickness',	value = 0,		min = -10},
	{name = 'hair_1',			value = 0,		min = 0},
	{name = 'hair_2',			value = 0,		min = 0},
	{name = 'hair_color_1',		value = 0,		min = 0},
	{name = 'hair_color_2',		value = 0,		min = 0},
	{name = 'tshirt_1',			value = 0,		min = 0,    componentId	= 8},
	{name = 'tshirt_2',			value = 0,		min = 0,    textureof	= 'tshirt_1'},
	{name = 'torso_1',			value = 0,		min = 0,    componentId	= 11},
	{name = 'torso_2',			value = 0,		min = 0,	textureof	= 'torso_1'},
	{name = 'decals_1',			value = 0,		min = 0,	componentId	= 10},
	{name = 'decals_2',			value = 0,		min = 0,	textureof	= 'decals_1'},
	{name = 'arms',				value = 0,		min = 0},
	{name = 'arms_2',			value = 0,		min = 0},
	{name = 'pants_1',			value = 0,		min = 0,	componentId	= 4},
	{name = 'pants_2',			value = 0,		min = 0,	textureof	= 'pants_1'},
	{name = 'shoes_1',			value = 0,		min = 0,	componentId	= 6},
	{name = 'shoes_2',			value = 0,		min = 0,	textureof	= 'shoes_1'},
	{name = 'mask_1',			value = 0,		min = 0,	componentId	= 1},
	{name = 'mask_2',			value = 0,		min = 0,	textureof	= 'mask_1'},
	{name = 'bproof_1',			value = 0,		min = 0,	componentId	= 9},
	{name = 'bproof_2',			value = 0,		min = 0,	textureof	= 'bproof_1'},
	{name = 'chain_1',			value = 0,		min = 0,	componentId	= 7},
	{name = 'chain_2',			value = 0,		min = 0,	textureof	= 'chain_1'},
	{name = 'helmet_1',			value = -1,		min = -1,	componentId	= 0 },
	{name = 'helmet_2',			value = 0,		min = 0,	textureof	= 'helmet_1'},
	{name = 'glasses_1',		value = 0,		min = 0,	componentId	= 1},
	{name = 'glasses_2',		value = 0,		min = 0,	textureof	= 'glasses_1'},
	{name = 'watches_1',		value = -1,		min = -1,	componentId	= 6},
	{name = 'watches_2',		value = 0,		min = 0,	textureof	= 'watches_1'},
	{name = 'bracelets_1',		value = -1,		min = -1,	componentId	= 7},
	{name = 'bracelets_2',		value = 0,		min = 0,	textureof	= 'bracelets_1'},
	{name = 'bags_1',			value = 0,		min = 0,	componentId	= 5},
	{name = 'bags_2',			value = 0,		min = 0,	textureof	= 'bags_1'},
	{name = 'eye_color',		value = 0,		min = 0},
	{name = 'eye_squint',		value = 0,		min = -10},
	{name = 'eyebrows_1',		value = 0,		min = Config.SkinManager == "qb-clothing" and -1 or 0},
	{name = 'eyebrows_2',		value = 0,		min = 0},
	{name = 'eyebrows_3',		value = 0,		min = 0},
	{name = 'eyebrows_4',		value = 0,		min = 0},
	{name = 'eyebrows_5',		value = 0,		min = -10},
	{name = 'eyebrows_6',		value = 0,		min = -10},
	{name = 'makeup_1',			value = 0,		min = Config.SkinManager == "qb-clothing" and -1 or 0},
	{name = 'makeup_2',			value = 0,		min = 0},
	{name = 'makeup_3',			value = 0,		min = 0},
	{name = 'makeup_4',			value = 0,		min = 0},
	{name = 'lipstick_1',		value = 0,		min = Config.SkinManager == "qb-clothing" and -1 or 0},
	{name = 'lipstick_2',		value = 0,		min = 0},
	{name = 'lipstick_3',		value = 0,		min = 0},
	{name = 'lipstick_4',		value = 0,		min = 0},
	{name = 'ears_1',			value = -1,		min = -1,	componentId	= 2},
	{name = 'ears_2',			value = 0,		min = 0,	textureof	= 'ears_1'},
	{name = 'chest_1',			value = 0,		min = 0},
	{name = 'chest_2',			value = 0,		min = 0},
	{name = 'chest_3',			value = 0,		min = 0},
	{name = 'bodyb_1',			value = -1,		min = -1},
	{name = 'bodyb_2',			value = 0,		min = 0},
	{name = 'bodyb_3',			value = -1,		min = -1},
	{name = 'bodyb_4',			value = 0,		min = 0},
	{name = 'age_1',			value = 0,		min = Config.SkinManager == "qb-clothing" and -1 or 0},
	{name = 'age_2',			value = 0,		min = 0},
	{name = 'blemishes_1',		value = 0,		min = 0},
	{name = 'blemishes_2',		value = 0,		min = 0},
	{name = 'blush_1',			value = 0,		min = Config.SkinManager == "qb-clothing" and -1 or 0},
	{name = 'blush_2',			value = 0,		min = 0},
	{name = 'blush_3',			value = 0,		min = 0},
	{name = 'complexion_1',		value = 0,		min = 0},
	{name = 'complexion_2',		value = 0,		min = 0},
	{name = 'sun_1',		    value = 0,		min = 0},
	{name = 'sun_2',		    value = 0,		min = 0},
	{name = 'moles_1',			value = 0,		min = 0},
	{name = 'moles_2',			value = 0,		min = 0},
	{name = 'beard_1',			value = 0,		min = Config.SkinManager == "qb-clothing" and -1 or 0},
	{name = 'beard_2',			value = 0,		min = 0},
	{name = 'beard_3',			value = 0,		min = 0},
	{name = 'beard_4',			value = 0,		min = 0}
}

for i=1, #Components, 1 do
	Character_ESX[Components[i].name] = Components[i].value
end

function refreshValues()
	Character_ESX = {}
	for i=1, #Components, 1 do
		Character_ESX[Components[i].name] = Components[i].value
	end
end

function getMaxValues()
    local components = json.decode(json.encode(Components))
	for k,v in pairs(Character_ESX) do
		for i=1, #components, 1 do
			if k == components[i].name then
				components[i].value = v
			end
		end
	end
	return components, GetMaxVals()
end

function GetMaxVal(item)
	local myPed = PlayerPedId()
	local maxVals = GetMaxVals()
	if item == 'tshirt_1' then
		return 'tshirt_2', maxVals['tshirt_2']
	elseif item == 'torso_1' then
		return 'torso_2', maxVals['torso_2']
	elseif item == 'helmet_1' then
		return 'helmet_2', maxVals['helmet_2']
	elseif item == 'pants_1' then
		return 'pants_2', maxVals['pants_2']
	elseif item == 'shoes_1' then
		return 'shoes_2', maxVals['shoes_2']
	elseif item == 'mask_1' then
		return 'mask_2', maxVals['mask_2']
	elseif item == 'decals_1' then
		return 'decals_2', maxVals['decals_2']
	elseif item == 'chain_1' then
		return 'chain_2', maxVals['chain_2']
	elseif item == 'glasses_1' then
		return 'glasses_2', maxVals['glasses_2']
	elseif item == 'watches_1' then
		return 'watches_2', maxVals['watches_2']
	elseif item == 'bracelets_1' then
		return 'bracelets_2', maxVals['bracelets_2']
	elseif item == 'bags_1' then
		return 'bags_2', maxVals['bags_2']
	elseif item == 'ears_1' then
		return 'ears_2', maxVals['ears_2']
	elseif item == 'bproof_1' then
		return 'bproof_2', maxVals['bproof_2']
	elseif item == 'hair_1' then
		return 'hair_2', maxVals['hair_2']
	end
end

function GetMaxVals()
	local myPed = PlayerPedId()
	local data = {
		sex				= 1,
		mom				= 45,
		dad				= 44,
		face_md_weight	= 100,
		skin_md_weight	= 100,
		nose_1			= 10,
		nose_2			= 10,
		nose_3			= 10,
		nose_4			= 10,
		nose_5			= 10,
		nose_6			= 10,
		cheeks_1		= 10,
		cheeks_2		= 10,
		cheeks_3		= 10,
		lip_thickness	= 10,
		jaw_1			= 10,
		jaw_2			= 10,
		chin_1			= 10,
		chin_2			= 10,
		chin_3			= 10,
		chin_4			= 10,
		neck_thickness	= 10,
		age_1			= GetPedHeadOverlayNum(3)-1,
		age_2			= 10,
		beard_1			= GetPedHeadOverlayNum(1)-1,
		beard_2			= 10,
		beard_3			= GetNumHairColors()-1,
		beard_4			= GetNumHairColors()-1,
		hair_1			= GetNumberOfPedDrawableVariations(myPed, 2) - 1,
		hair_2			= GetNumberOfPedTextureVariations(myPed, 2, Character_ESX['hair_1']) - 1,
		hair_color_1	= GetNumHairColors()-1,
		hair_color_2	= GetNumHairColors()-1,
		eye_color		= 29,
		eye_squint		= 10,
		eyebrows_1		= GetPedHeadOverlayNum(2)-1,
		eyebrows_2		= 10,
		eyebrows_3		= GetNumHairColors()-1,
		eyebrows_4		= GetNumHairColors()-1,
		eyebrows_5		= 10,
		eyebrows_6		= 10,
		makeup_1		= GetPedHeadOverlayNum(4)-1,
		makeup_2		= 10,
		makeup_3		= GetNumHairColors()-1,
		makeup_4		= GetNumHairColors()-1,
		lipstick_1		= GetPedHeadOverlayNum(8)-1,
		lipstick_2		= 10,
		lipstick_3		= GetNumHairColors()-1,
		lipstick_4		= GetNumHairColors()-1,
		blemishes_1		= GetPedHeadOverlayNum(0)-1,
		blemishes_2		= 10,
		blush_1			= GetPedHeadOverlayNum(5)-1,
		blush_2			= 10,
		blush_3			= GetNumHairColors()-1,
		complexion_1	= GetPedHeadOverlayNum(6)-1,
		complexion_2	= 10,
		sun_1			= GetPedHeadOverlayNum(7)-1,
		sun_2			= 10,
		moles_1			= GetPedHeadOverlayNum(9)-1,
		moles_2			= 10,
		chest_1			= GetPedHeadOverlayNum(10)-1,
		chest_2			= 10,
		chest_3			= GetNumHairColors()-1,
		bodyb_1			= GetPedHeadOverlayNum(11)-1,
		bodyb_2			= 10,
		bodyb_3			= GetPedHeadOverlayNum(12)-1,
		bodyb_4			= 10,
		ears_1			= GetNumberOfPedPropDrawableVariations(myPed, 2) - 1,
		ears_2			= GetNumberOfPedPropTextureVariations(myPed, 2, Character_ESX['ears_1'] - 1),
		tshirt_1		= GetNumberOfPedDrawableVariations(myPed, 8) - 1,
		tshirt_2		= GetNumberOfPedTextureVariations(myPed, 8, Character_ESX['tshirt_1']) - 1,
		torso_1			= GetNumberOfPedDrawableVariations(myPed, 11) - 1,
		torso_2			= GetNumberOfPedTextureVariations(myPed, 11, Character_ESX['torso_1']) - 1,
		decals_1		= GetNumberOfPedDrawableVariations(myPed, 10) - 1,
		decals_2		= GetNumberOfPedTextureVariations(myPed, 10, Character_ESX['decals_1']) - 1,
		arms			= GetNumberOfPedDrawableVariations(myPed, 3) - 1,
		arms_2			= 10,
		pants_1			= GetNumberOfPedDrawableVariations(myPed, 4) - 1,
		pants_2			= GetNumberOfPedTextureVariations(myPed, 4, Character_ESX['pants_1']) - 1,
		shoes_1			= GetNumberOfPedDrawableVariations(myPed, 6) - 1,
		shoes_2			= GetNumberOfPedTextureVariations(myPed, 6, Character_ESX['shoes_1']) - 1,
		mask_1			= GetNumberOfPedDrawableVariations(myPed, 1) - 1,
		mask_2			= GetNumberOfPedTextureVariations(myPed, 1, Character_ESX['mask_1']) - 1,
		bproof_1		= GetNumberOfPedDrawableVariations(myPed, 9) - 1,
		bproof_2		= GetNumberOfPedTextureVariations(myPed, 9, Character_ESX['bproof_1']) - 1,
		chain_1			= GetNumberOfPedDrawableVariations(myPed, 7) - 1,
		chain_2			= GetNumberOfPedTextureVariations(myPed, 7, Character_ESX['chain_1']) - 1,
		bags_1			= GetNumberOfPedDrawableVariations(myPed, 5) - 1,
		bags_2			= GetNumberOfPedTextureVariations(myPed, 5, Character_ESX['bags_1']) - 1,
		helmet_1		= GetNumberOfPedPropDrawableVariations(myPed, 0) - 1,
		helmet_2		= GetNumberOfPedPropTextureVariations(myPed, 0, Character_ESX['helmet_1']) - 1,
		glasses_1		= GetNumberOfPedPropDrawableVariations(myPed, 1) - 1,
		glasses_2		= GetNumberOfPedPropTextureVariations(myPed, 1, Character_ESX['glasses_1'] - 1),
		watches_1		= GetNumberOfPedPropDrawableVariations(myPed, 6) - 1,
		watches_2		= GetNumberOfPedPropTextureVariations(myPed, 6, Character_ESX['watches_1']) - 1,
		bracelets_1		= GetNumberOfPedPropDrawableVariations(myPed, 7) - 1,
		bracelets_2		= GetNumberOfPedPropTextureVariations(myPed, 7, Character_ESX['bracelets_1'] - 1)
	}
	return data
end

function updateValue(skin)
    local myPed = PlayerPedId()

	for k,v in pairs(skin) do
		tempSkinTable[k] = v
	end

	-- Valider les variations de vêtements pour éviter les erreurs "Invalid variation"
	local maxPants = GetNumberOfPedDrawableVariations(myPed, 4) - 1
	local maxShoes = GetNumberOfPedDrawableVariations(myPed, 6) - 1
	local maxTshirt = GetNumberOfPedDrawableVariations(myPed, 8) - 1
	local maxTorso = GetNumberOfPedDrawableVariations(myPed, 11) - 1
	local maxArms = GetNumberOfPedDrawableVariations(myPed, 3) - 1
	local maxDecals = GetNumberOfPedDrawableVariations(myPed, 10) - 1
	local maxMask = GetNumberOfPedDrawableVariations(myPed, 1) - 1
	local maxBproof = GetNumberOfPedDrawableVariations(myPed, 9) - 1
	local maxChain = GetNumberOfPedDrawableVariations(myPed, 7) - 1
	local maxBags = GetNumberOfPedDrawableVariations(myPed, 5) - 1

	if tempSkinTable['pants_1'] and tempSkinTable['pants_1'] > maxPants then tempSkinTable['pants_1'] = 0 end
	if tempSkinTable['shoes_1'] and tempSkinTable['shoes_1'] > maxShoes then tempSkinTable['shoes_1'] = 0 end
	if tempSkinTable['tshirt_1'] and tempSkinTable['tshirt_1'] > maxTshirt then tempSkinTable['tshirt_1'] = 0 end
	if tempSkinTable['torso_1'] and tempSkinTable['torso_1'] > maxTorso then tempSkinTable['torso_1'] = 0 end
	if tempSkinTable['arms'] and tempSkinTable['arms'] > maxArms then tempSkinTable['arms'] = 0 end
	if tempSkinTable['decals_1'] and tempSkinTable['decals_1'] > maxDecals then tempSkinTable['decals_1'] = 0 end
	if tempSkinTable['mask_1'] and tempSkinTable['mask_1'] > maxMask then tempSkinTable['mask_1'] = 0 end
	if tempSkinTable['bproof_1'] and tempSkinTable['bproof_1'] > maxBproof then tempSkinTable['bproof_1'] = 0 end
	if tempSkinTable['chain_1'] and tempSkinTable['chain_1'] > maxChain then tempSkinTable['chain_1'] = 0 end
	if tempSkinTable['bags_1'] and tempSkinTable['bags_1'] > maxBags then tempSkinTable['bags_1'] = 0 end

	-- Valider aussi les textures
	if tempSkinTable['pants_1'] then
		local maxPantsTex = GetNumberOfPedTextureVariations(myPed, 4, tempSkinTable['pants_1']) - 1
		if tempSkinTable['pants_2'] and tempSkinTable['pants_2'] > maxPantsTex then tempSkinTable['pants_2'] = 0 end
	end
	if tempSkinTable['shoes_1'] then
		local maxShoesTex = GetNumberOfPedTextureVariations(myPed, 6, tempSkinTable['shoes_1']) - 1
		if tempSkinTable['shoes_2'] and tempSkinTable['shoes_2'] > maxShoesTex then tempSkinTable['shoes_2'] = 0 end
	end


	local face_weight =	(tempSkinTable['face_md_weight'] / 100) + 0.0
	local skin_weight =	(tempSkinTable['skin_md_weight'] / 100) + 0.0
	SetPedHeadBlendData(myPed, tempSkinTable['mom'], tempSkinTable['dad'], 0, tempSkinTable['mom'], tempSkinTable['dad'], 0, face_weight, skin_weight, 0.0, false)

	SetPedFaceFeature(myPed, 0, (tempSkinTable['nose_1'] / 10) + 0.0)
	SetPedFaceFeature(myPed, 1, (tempSkinTable['nose_2'] / 10) + 0.0)
	SetPedFaceFeature(myPed, 2, (tempSkinTable['nose_3'] / 10) + 0.0)
	SetPedFaceFeature(myPed, 3, (tempSkinTable['nose_4'] / 10) + 0.0)
	SetPedFaceFeature(myPed, 4, (tempSkinTable['nose_5'] / 10) + 0.0)
	SetPedFaceFeature(myPed, 5, (tempSkinTable['nose_6'] / 10) + 0.0)

	SetPedFaceFeature(myPed, 8, (tempSkinTable['cheeks_1'] / 10) + 0.0)
	SetPedFaceFeature(myPed, 9, (tempSkinTable['cheeks_2'] / 10) + 0.0)
	SetPedFaceFeature(myPed, 10, (tempSkinTable['cheeks_3'] / 10) + 0.0)
    
	SetPedFaceFeature(myPed, 12, (tempSkinTable['lip_thickness'] / 10) + 0.0)
    
	SetPedFaceFeature(myPed, 13, (tempSkinTable['jaw_1'] / 10) + 0.0)
	SetPedFaceFeature(myPed, 14, (tempSkinTable['jaw_2'] / 10) + 0.0)
    
	SetPedFaceFeature(myPed, 15, (tempSkinTable['chin_1'] / 10) + 0.0)
	SetPedFaceFeature(myPed, 16, (tempSkinTable['chin_2'] / 10) + 0.0)
	SetPedFaceFeature(myPed, 17, (tempSkinTable['chin_3'] / 10) + 0.0)
	SetPedFaceFeature(myPed, 18, (tempSkinTable['chin_4'] / 10) + 0.0)
    
	SetPedFaceFeature(myPed, 19, (tempSkinTable['neck_thickness'] / 10) + 0.0)
    
	SetPedHeadOverlay(myPed, 3, tempSkinTable['age_1'], (tempSkinTable['age_2'] / 10) + 0.0)

	SetPedHeadOverlay(myPed, 0, tempSkinTable['blemishes_1'], (tempSkinTable['blemishes_2'] / 10) + 0.0)

	SetPedEyeColor(myPed, math.min(math.max(tonumber(tempSkinTable['eye_color']) or 0, 0), 29))

	SetPedHeadOverlay(myPed, 2, tempSkinTable['eyebrows_1'], (tempSkinTable['eyebrows_2'] / 10) + 0.0)
	SetPedHeadOverlayColor(myPed, 2, 1,	tempSkinTable['eyebrows_3'], tempSkinTable['eyebrows_4'])
	SetPedFaceFeature(myPed, 6, (tempSkinTable['eyebrows_5'] / 10) + 0.0)
	SetPedFaceFeature(myPed, 7, (tempSkinTable['eyebrows_6'] / 10) + 0.0)
    
	SetPedHeadOverlay(myPed, 4, tempSkinTable['makeup_1'], (tempSkinTable['makeup_2'] / 10) + 0.0)
	SetPedHeadOverlayColor(myPed, 4, 2,	tempSkinTable['makeup_3'], tempSkinTable['makeup_4'])
    
	SetPedHeadOverlay(myPed, 8, tempSkinTable['lipstick_1'], (tempSkinTable['lipstick_2'] / 10) + 0.0)
	SetPedHeadOverlayColor(myPed, 8, 1,	tempSkinTable['lipstick_3'], tempSkinTable['lipstick_4'])
    
	SetPedComponentVariation(myPed, 2, tempSkinTable['hair_1'], tempSkinTable['hair_2'], 2)
	SetPedHairColor(myPed, tempSkinTable['hair_color_1'], tempSkinTable['hair_color_2'])
    
	SetPedHeadOverlay(myPed, 1, tempSkinTable['beard_1'], (tempSkinTable['beard_2'] / 10) + 0.0)
	SetPedHeadOverlayColor(myPed, 1, 1,	tempSkinTable['beard_3'], tempSkinTable['beard_4'])

	SetPedHeadOverlay(myPed, 5, tempSkinTable['blush_1'], (tempSkinTable['blush_2'] / 10) + 0.0)
	SetPedHeadOverlayColor(myPed, 5, 2,	tempSkinTable['blush_3'])

	SetPedHeadOverlay(myPed, 6, tempSkinTable['complexion_1'], (tempSkinTable['complexion_2'] / 10) + 0.0)
	SetPedHeadOverlay(myPed, 7, tempSkinTable['sun_1'], (tempSkinTable['sun_2'] / 10) + 0.0)
	SetPedHeadOverlay(myPed, 9, tempSkinTable['moles_1'], (tempSkinTable['moles_2'] / 10) + 0.0)

	SetPedHeadOverlay(myPed, 10, tempSkinTable['chest_1'], (tempSkinTable['chest_2'] / 10) + 0.0)
	SetPedHeadOverlayColor(myPed, 10, 1, tempSkinTable['chest_3'])

	if tempSkinTable['ears_1'] == -1 then
		ClearPedProp(myPed, 2)
	else
		SetPedPropIndex(myPed, 2, tempSkinTable['ears_1'], tempSkinTable['ears_2'], 2)
	end

	SetPedComponentVariation(myPed, 8, tempSkinTable['tshirt_1'], tempSkinTable['tshirt_2'], 2)
	SetPedComponentVariation(myPed, 11, tempSkinTable['torso_1'], tempSkinTable['torso_2'], 2)
	SetPedComponentVariation(myPed, 3, tempSkinTable['arms'], tempSkinTable['arms_2'], 2)
	SetPedComponentVariation(myPed, 10, tempSkinTable['decals_1'], tempSkinTable['decals_2'], 2)
	SetPedComponentVariation(myPed, 4, tempSkinTable['pants_1'], tempSkinTable['pants_2'], 2)
	SetPedComponentVariation(myPed, 6, tempSkinTable['shoes_1'], tempSkinTable['shoes_2'], 2)
	SetPedComponentVariation(myPed, 1, tempSkinTable['mask_1'], tempSkinTable['mask_2'], 2)
	SetPedComponentVariation(myPed, 9, tempSkinTable['bproof_1'], tempSkinTable['bproof_2'], 2)
	SetPedComponentVariation(myPed, 7, tempSkinTable['chain_1'], tempSkinTable['chain_2'], 2)
	SetPedComponentVariation(myPed, 5, tempSkinTable['bags_1'], tempSkinTable['bags_2'], 2)

	if tempSkinTable['helmet_1'] == -1 then
		ClearPedProp(myPed, 0)
	else
		SetPedPropIndex(myPed, 0, tempSkinTable['helmet_1'], tempSkinTable['helmet_2'], 2)
	end

	if tempSkinTable['glasses_1'] == -1 then
		ClearPedProp(myPed, 1)
	else
		SetPedPropIndex(myPed, 1, tempSkinTable['glasses_1'], tempSkinTable['glasses_2'], 2)
	end

	if tempSkinTable['watches_1'] == -1 then
		ClearPedProp(myPed, 6)
	else
		SetPedPropIndex(myPed, 6, tempSkinTable['watches_1'], tempSkinTable['watches_2'], 2)
	end

	if tempSkinTable['bracelets_1'] == -1 then
		ClearPedProp(myPed,	7)
	else
		SetPedPropIndex(myPed, 7, tempSkinTable['bracelets_1'], tempSkinTable['bracelets_2'], 2)
	end
end
