
local isCreatorOpen = false
local creatorCam = nil
local creatorTransitionCam = nil
local creatorTempSkin = {}
local creatorCharData = {
    firstName = "",
    lastName = "",
    birthdate = "",
    gender = "m",
}
local creatorStartAsNew = false

function GetAvailableOutfits()
    if not Config or not Config.Creator or not Config.Creator.OutFits then
        return {}
    end
    local outfits = {}
    for name, data in pairs(Config.Creator.OutFits) do
        outfits[name] = data
    end
    return outfits
end

local SitAnimStarted = false

local function StartSitAnimation()
    if SitAnimStarted then return end

    FreezeEntityPosition(PlayerPedId(), true)

    RequestAnimDict(Config.Creator.Animations[1])
    local timeout = 0
    while not HasAnimDictLoaded(Config.Creator.Animations[1]) and timeout < 50 do
        Wait(100)
        timeout = timeout + 1
    end
                
    if not HasAnimDictLoaded(Config.Creator.Animations[1]) then
        null.DebugPrint("[IDLE ANIM CLIENT] Failed to load anim dict:", Config.Creator.Animations[1])
        return
    end
                
    SitAnimStarted = true

    TaskPlayAnim(PlayerPedId(), Config.Creator.Animations[1], Config.Creator.Animations[2], 8.0, -8.0, -1, 51, 0, false, false, false)

    Wait(1000)

    FreezeEntityPosition(PlayerPedId(), false)
end

local function StopSitAnimation()
    if not SitAnimStarted then return end

    ClearPedTasks(PlayerPedId())

    SitAnimStarted = false
end

-- (Re)place le ped à la position exacte de l'animation puis rejoue l'assise.
-- À appeler UNIQUEMENT après que le modèle soit finalisé (post SetPlayerModel)
-- car un changement de modèle recrée le ped et supprime l'animation.
local function SeatPedForCreator()
    if not (Config and Config.Creator and Config.Creator.Coords) then return end
    local ped = PlayerPedId()
    local c = Config.Creator.Coords
    SetEntityCoords(ped, c.x, c.y, c.z, false, false, false, false)
    SetEntityHeading(ped, c.w)
    SitAnimStarted = false
    if Config.Creator.Animations then
        StartSitAnimation()
    end
end

local function CreateCreatorCam()
    if DoesCamExist(creatorCam) then DestroyCam(creatorCam, true) end
    if DoesCamExist(creatorTransitionCam) then DestroyCam(creatorTransitionCam, true) end

    creatorCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local coords = GetEntityCoords(PlayerPedId())
    SetCamCoord(creatorCam, coords.x + 0.5, coords.y + 2.2, coords.z + 0.3)
    SetCamRot(creatorCam, 0.0, 0.0, 270.0, true)
    SetCamActive(creatorCam, true)
    RenderScriptCams(true, true, 1000, true, true)
    PointCamAtCoord(creatorCam, coords.x, coords.y, coords.z + 0.2)
end

local function DestroyCreatorCam()
    if DoesCamExist(creatorCam) then
        DestroyCam(creatorCam, true)
        creatorCam = nil
    end
    if DoesCamExist(creatorTransitionCam) then
        DestroyCam(creatorTransitionCam, true)
        creatorTransitionCam = nil
    end
    RenderScriptCams(false, true, 500, true, true)
end

local function UpdateCreatorCam(cameraType)
    local coords = GetEntityCoords(PlayerPedId())

    if not DoesCamExist(creatorTransitionCam) then
        creatorTransitionCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    end

    local curCoord = GetCamCoord(creatorCam)
    local curRot = GetCamRot(creatorCam, 2)
    SetCamCoord(creatorTransitionCam, curCoord.x, curCoord.y, curCoord.z)
    SetCamRot(creatorTransitionCam, curRot.x, curRot.y, curRot.z, 2)

    StopSitAnimation()

    if cameraType == "head" then
        SetCamCoord(creatorCam, coords.x + 0.3, coords.y + 1.0, coords.z + 0.65)
        SetCamRot(creatorCam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(creatorCam, coords.x, coords.y, coords.z + 0.65)
    elseif cameraType == "body" then
        SetCamCoord(creatorCam, coords.x + 0.5, coords.y + 2.0, coords.z + 0.4)
        SetCamRot(creatorCam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(creatorCam, coords.x, coords.y, coords.z + 0.2)
    elseif cameraType == "legs" then
        SetCamCoord(creatorCam, coords.x + 0.5, coords.y + 2.2, coords.z - 0.2)
        SetCamRot(creatorCam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(creatorCam, coords.x, coords.y, coords.z - 0.4)
    else
        SetCamCoord(creatorCam, coords.x + 0.5, coords.y + 2.2, coords.z + 0.3)
        SetCamRot(creatorCam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(creatorCam, coords.x, coords.y, coords.z + 0.2)
    end

    SetCamActiveWithInterp(creatorCam, creatorTransitionCam, 800, 3, 3)
end


local function ApplySkinToPlayer(skin)
    local myPed = PlayerPedId()

    for k, v in pairs(skin) do
        creatorTempSkin[k] = v
    end

    local s = creatorTempSkin

    local compMap = { pants_1 = 4, shoes_1 = 6, tshirt_1 = 8, torso_1 = 11, arms = 3, decals_1 = 10, mask_1 = 1, bproof_1 = 9, chain_1 = 7, bags_1 = 5 }
    for name, comp in pairs(compMap) do
        local maxDraw = GetNumberOfPedDrawableVariations(myPed, comp) - 1
        if s[name] and s[name] > maxDraw then s[name] = 0 end
    end

    local faceW = ((s['face_md_weight'] or 50) / 100) + 0.0
    local skinW = ((s['skin_md_weight'] or 50) / 100) + 0.0
    SetPedHeadBlendData(myPed, s['mom'] or 0, s['dad'] or 0, 0, s['mom'] or 0, s['dad'] or 0, 0, faceW, skinW, 0.0, false)

    local faceFeatures = {
        [0] = 'nose_1', [1] = 'nose_2', [2] = 'nose_3', [3] = 'nose_4', [4] = 'nose_5',
        [8] = 'cheeks_1', [12] = 'lip_thickness',
        [13] = 'chin_1', [14] = 'chin_2', [15] = 'chin_3',
        [19] = 'neck_thickness',
        [6] = 'eye_squint',
    }
    for idx, name in pairs(faceFeatures) do
        if s[name] then
            SetPedFaceFeature(myPed, idx, (s[name] / 10) + 0.0)
        end
    end

    if s['hair_1'] then
        SetPedComponentVariation(myPed, 2, s['hair_1'], 0, 2)
    end
    if s['hair_color_1'] then
        SetPedHairColor(myPed, s['hair_color_1'], s['hair_color_2'] or 0)
    end

    local overlays = {
        { idx = 2,  style = 'eyebrows_1',  opacity = 'eyebrows_2', color = 'eyebrows_3', colorType = 1 },
        { idx = 1,  style = 'beard_1',     opacity = 'beard_2',    color = 'beard_3',    colorType = 1 },
        { idx = 0,  style = 'blemishes_1', opacity = 'blemishes_2' },
        { idx = 8,  style = 'lipstick_1',  opacity = 'lipstick_2', color = 'lipstick_3', colorType = 2 },
        { idx = 10, style = 'chest_1',     opacity = 'chest_2',    color = 'chest_3',    colorType = 1 },
    }
    for _, ov in ipairs(overlays) do
        local styleVal = s[ov.style] or 0
        local opacityVal = ((s[ov.opacity] or 0) / 10) + 0.0
        if opacityVal > 1.0 then opacityVal = 1.0 end
        SetPedHeadOverlay(myPed, ov.idx, styleVal, opacityVal)
        if ov.color and s[ov.color] then
            SetPedHeadOverlayColor(myPed, ov.idx, ov.colorType, s[ov.color], s[ov.color])
        end
    end

    if s['eye_color'] then
        local eyeColor = tonumber(s['eye_color']) or 0
        if eyeColor < 0 then eyeColor = 0 end
        if eyeColor > 29 then eyeColor = 29 end
        SetPedEyeColor(myPed, eyeColor)
    end

    local clothesMap = {
        { name = 'tshirt_1',  tex = 'tshirt_2',  comp = 8 },
        { name = 'torso_1',   tex = 'torso_2',   comp = 11 },
        { name = 'arms',      tex = 'arms_2',    comp = 3 },
        { name = 'decals_1',  tex = 'decals_2',  comp = 10 },
        { name = 'pants_1',   tex = 'pants_2',   comp = 4 },
        { name = 'shoes_1',   tex = 'shoes_2',   comp = 6 },
        { name = 'mask_1',    tex = 'mask_2',    comp = 1 },
        { name = 'bproof_1',  tex = 'bproof_2',  comp = 9 },
        { name = 'chain_1',   tex = 'chain_2',   comp = 7 },
        { name = 'bags_1',    tex = 'bags_2',    comp = 5 },
    }
    for _, c in ipairs(clothesMap) do
        local drawable = s[c.name]
        if drawable and drawable >= 0 then
            local texture = s[c.tex] or 0
            SetPedComponentVariation(myPed, c.comp, drawable, texture, 0)
        end
    end
end

local function ChangeSkinData(component, value)
    creatorTempSkin[component] = value
    TriggerEvent('Null:skinchanger:change', component, value)
    ApplySkinToPlayer(creatorTempSkin)
end


function OpenNewCreator(first)
    if isCreatorOpen then return end
    if isInInterface and isInInterface() ~= false then return end

    if first then
        creatorStartAsNew = true

        -- Connexion : on garde l'écran noir pendant la mise en place
        -- (modèle/cam/ped) pour éviter le flash du monde entre la fin du
        -- loading screen et l'apparition du créateur.
        DoScreenFadeOut(0)

        if Config and Config.Creator and Config.Creator.Coords then
            SetEntityCoords(PlayerPedId(), Config.Creator.Coords.x, Config.Creator.Coords.y, Config.Creator.Coords.z)
            SetEntityHeading(PlayerPedId(), Config.Creator.Coords.w)
            Wait(500)
            -- L'anim assise est jouée APRÈS la finalisation du modèle (cf.
            -- SeatPedForCreator plus bas) : sinon un éventuel SetPlayerModel
            -- recrée le ped et détruit l'animation.
        end

    end

    isCreatorOpen = true
    if setInInterface then setInInterface("newcreator") end
    FreezeEntityPosition(PlayerPedId(), true)
    if null and null.DisplayHud then null.DisplayHud(false, 978) end

    local ped = PlayerPedId()
    local model = GetEntityModel(ped)
    local maleModel = GetHashKey('mp_m_freemode_01')
    local femaleModel = GetHashKey('mp_f_freemode_01')
    
    if model ~= maleModel and model ~= femaleModel then
        RequestModel(maleModel)
        while not HasModelLoaded(maleModel) do Wait(0) end
        SetPlayerModel(PlayerId(), maleModel)
        SetPedDefaultComponentVariation(PlayerPedId())
        ped = PlayerPedId()
        creatorCharData.gender = "m"
        creatorTempSkin['sex'] = 0
        SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.0, false)
        while not HasPedHeadBlendFinished(ped) do Wait(0) end
        Wait(100)
    else
        if model == femaleModel then
            creatorCharData.gender = "f"
            creatorTempSkin['sex'] = 1
        else
            creatorCharData.gender = "m"
            creatorTempSkin['sex'] = 0
        end
    end

    -- Le ped peut arriver invisible/transparent depuis le spawn de connexion
    -- (inline spawn caché). On le rend pleinement visible pour le créateur.
    do
        local p = PlayerPedId()
        SetEntityVisible(p, true, false)
        SetEntityAlpha(p, 255, false)
        ResetEntityAlpha(p)
        FreezeEntityPosition(p, true)
        SetEntityInvincible(p, true)
        SetPlayerInvincible(PlayerId(), true)
    end

    -- Modèle finalisé → on assoit le ped (position exacte + animation).
    if first then
        SeatPedForCreator()
    end

    local maxVals = GetMaxVals()

    if not creatorTempSkin or not creatorTempSkin['sex'] then
        creatorTempSkin = Character_ESX or {}
    end
    TriggerEvent('Null:skinchanger:getData', function(comp, max)
        for k, v in pairs(comp) do
            creatorTempSkin[v.name] = tonumber(v.value)
        end
    end)

    local outfits = GetAvailableOutfits()

    CreateCreatorCam()
    SetPlayerControl(PlayerId(), false, 12)
    SetNuiFocus(true, true)

    SendNUIMessage({
        action = 'newCreator:open'
    })

    SendNUIMessage({
        action = 'newCreator:setData',
        data = {
            gender = creatorCharData.gender,
            outfits = outfits,
            maxValues = {
                father = maxVals.dad or 44,
                mother = maxVals.mom or 45,
                hairstyle = maxVals.hair_1 or 73,
                hairColor = maxVals.hair_color_1 or 63,
                eyebrows = maxVals.eyebrows_1 or 33,
                beard = maxVals.beard_1 or 28,
                eyeColor = math.min(tonumber(maxVals.eye_color) or 29, 29),
                beardColor = maxVals.beard_3 or 63,
                eyebrowColor = maxVals.eyebrows_3 or 63,
                lipstickStyle = maxVals.lipstick_1 or 9,
                lipstickColor = maxVals.lipstick_3 or 63,
                chestHair = maxVals.chest_1 or 16,
                blemishes = maxVals.blemishes_1 or 23,
            }
        }
    })

    -- Cam + ped + NUI prêts : on révèle en fondu (transition fluide depuis
    -- le loading screen / depuis le monde pour une ouverture manuelle).
    CreateThread(function()
        Wait(350)
        if IsScreenFadedOut() or IsScreenFadingOut() then
            DoScreenFadeIn(700)
        end
    end)
end

local function CloseNewCreator()
    if not isCreatorOpen then return end
    isCreatorOpen = false

    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'newCreator:close' })

    SetPlayerControl(PlayerId(), true, 12)
    FreezeEntityPosition(PlayerPedId(), false)
    if null and null.DisplayHud then null.DisplayHud(true, 978) end
    DestroyCreatorCam()
    if clearInterface then clearInterface() end
    if DeleteSkinCam then DeleteSkinCam() end
end


RegisterCommand('newcreator', function()
    if isCreatorOpen then
        CloseNewCreator()
    else
        OpenNewCreator()
    end
end, false)


RegisterNUICallback('newCreator:close', function(_, cb)
    CloseNewCreator()
    cb({})
end)

RegisterNUICallback('newCreator:cameraChange', function(data, cb)
    if data.camera then
        UpdateCreatorCam(data.camera)
    end
    cb('ok')
end)

RegisterNUICallback('newCreator:rotate', function(data, cb)
    if data.delta then
        local heading = GetEntityHeading(PlayerPedId())
        heading = heading + data.delta
        if heading > 360 then heading = heading - 360 end
        if heading < 0 then heading = heading + 360 end
        SetEntityHeading(PlayerPedId(), heading)
    end
    cb('ok')
end)

RegisterNUICallback('newCreator:charInfo', function(data, cb)
    local ped = PlayerPedId()
    if data.sex ~= nil then
        creatorCharData.gender = data.sex == 0 and "m" or "f"
        local model = data.sex == 0 and GetHashKey('mp_m_freemode_01') or GetHashKey('mp_f_freemode_01')

        -- Écran noir pendant le swap de modèle : éviter que la caméra
        -- scriptée rende un ped en cours de recréation (crash gta-core-five).
        DoScreenFadeOut(200)
        Wait(250)

        -- CRUCIAL : stopper l'animation/tâche et défiger AVANT SetPlayerModel.
        -- Changer de modèle sur un ped figé + en cours d'animation crashe le
        -- moteur (gta-core-five.dll).
        StopSitAnimation()
        ClearPedTasksImmediately(ped)
        FreezeEntityPosition(ped, false)
        Wait(0)

        RequestModel(model)
        local mt = GetGameTimer() + 5000
        while not HasModelLoaded(model) and GetGameTimer() < mt do Wait(10) end
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
        ped = PlayerPedId()
        SetPedDefaultComponentVariation(ped)
        SetPedHeadBlendData(ped, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.0, false)
        local bt = GetGameTimer() + 3000
        while not HasPedHeadBlendFinished(ped) and GetGameTimer() < bt do Wait(10) end
        creatorTempSkin['sex'] = data.sex

        -- Réétat visuel + ré-assise (position exacte + anim) + recadrage cam.
        SetEntityVisible(ped, true, false)
        SetEntityAlpha(ped, 255, false)
        ResetEntityAlpha(ped)
        SetEntityInvincible(ped, true)
        SetPlayerControl(PlayerId(), false, 12)
        SeatPedForCreator()
        UpdateCreatorCam('default')
        Wait(150)
        DoScreenFadeIn(350)

        local maxVals = GetMaxVals()
        local outfits = GetAvailableOutfits and GetAvailableOutfits() or {}
        SendNUIMessage({
            action = 'newCreator:setData',
            data = {
                gender = creatorCharData.gender,
                outfits = outfits,
                maxValues = {
                    father = maxVals.dad or 44,
                    mother = maxVals.mom or 45,
                    hairstyle = maxVals.hair_1 or 73,
                    hairColor = maxVals.hair_color_1 or 63,
                    eyebrows = maxVals.eyebrows_1 or 33,
                    beard = maxVals.beard_1 or 28,
                    eyeColor = math.min(tonumber(maxVals.eye_color) or 29, 29),
                    beardColor = maxVals.beard_3 or 63,
                    eyebrowColor = maxVals.eyebrows_3 or 63,
                    lipstickStyle = maxVals.lipstick_1 or 9,
                    lipstickColor = maxVals.lipstick_3 or 63,
                    chestHair = maxVals.chest_1 or 16,
                    blemishes = maxVals.blemishes_1 or 23,
                }
            }
        })
    end
    cb('ok')
end)

RegisterNUICallback('newCreator:faceFather', function(data, cb)
    local value = tonumber(data) or 0
    creatorCharData.father = value
    ChangeSkinData("dad", value)
    cb('ok')
end)

RegisterNUICallback('newCreator:faceMother', function(data, cb)
    local value = tonumber(data) or 21
    creatorCharData.mother = value
    ChangeSkinData("mom", value)
    cb('ok')
end)

RegisterNUICallback('newCreator:faceMix', function(data, cb)
    local value = tonumber(data) or 0.5
    ChangeSkinData("face_md_weight", math.floor(value * 100))
    cb('ok')
end)

RegisterNUICallback('newCreator:skinTone', function(data, cb)
    local value = tonumber(data) or 0
    ChangeSkinData("skin_md_weight", value * 10)
    cb('ok')
end)

RegisterNUICallback('newCreator:hairstyle', function(data, cb)
    ChangeSkinData("hair_1", tonumber(data) or 0)
    cb('ok')
end)

RegisterNUICallback('newCreator:hairColor', function(data, cb)
    ChangeSkinData("hair_color_1", tonumber(data) or 0)
    cb('ok')
end)

RegisterNUICallback('newCreator:hairHighlight', function(data, cb)
    ChangeSkinData("hair_color_2", tonumber(data) or 0)
    cb('ok')
end)

RegisterNUICallback('newCreator:beardStyle', function(data, cb)
    ChangeSkinData("beard_1", tonumber(data) or 0)
    cb('ok')
end)

RegisterNUICallback('newCreator:beardColor', function(data, cb)
    ChangeSkinData("beard_3", tonumber(data) or 0)
    cb('ok')
end)

RegisterNUICallback('newCreator:beardOpacity', function(data, cb)
    local value = tonumber(data) or 0
    ChangeSkinData("beard_2", math.floor(value * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:eyebrowStyle', function(data, cb)
    ChangeSkinData("eyebrows_1", tonumber(data) or 0)
    cb('ok')
end)

RegisterNUICallback('newCreator:eyebrowColor', function(data, cb)
    ChangeSkinData("eyebrows_3", tonumber(data) or 0)
    cb('ok')
end)

RegisterNUICallback('newCreator:eyebrowOpacity', function(data, cb)
    local value = tonumber(data) or 0
    ChangeSkinData("eyebrows_2", math.floor(value * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:eyeColor', function(data, cb)
    local value = tonumber(data) or 0
    if value < 0 then value = 0 end
    if value > 29 then value = 29 end
    ChangeSkinData("eye_color", value)
    cb('ok')
end)

RegisterNUICallback('newCreator:noseWidth', function(data, cb)
    ChangeSkinData("nose_1", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:noseHeight', function(data, cb)
    ChangeSkinData("nose_2", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:noseLength', function(data, cb)
    ChangeSkinData("nose_3", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:noseBase', function(data, cb)
    ChangeSkinData("nose_4", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:noseRotation', function(data, cb)
    ChangeSkinData("nose_5", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:cheekBones', function(data, cb)
    ChangeSkinData("cheeks_1", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:eyeOpenness', function(data, cb)
    ChangeSkinData("eye_squint", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:lipThickness', function(data, cb)
    ChangeSkinData("lip_thickness", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:chinHeight', function(data, cb)
    ChangeSkinData("chin_1", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:chinLength', function(data, cb)
    ChangeSkinData("chin_2", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:chinWidth', function(data, cb)
    ChangeSkinData("chin_3", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:neckThickness', function(data, cb)
    ChangeSkinData("neck_thickness", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:lipstickStyle', function(data, cb)
    ChangeSkinData("lipstick_1", tonumber(data) or 0)
    cb('ok')
end)

RegisterNUICallback('newCreator:lipstickColor', function(data, cb)
    ChangeSkinData("lipstick_3", tonumber(data) or 0)
    cb('ok')
end)

RegisterNUICallback('newCreator:lipstickOpacity', function(data, cb)
    ChangeSkinData("lipstick_2", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:chestHair', function(data, cb)
    ChangeSkinData("chest_1", tonumber(data) or 0)
    cb('ok')
end)

RegisterNUICallback('newCreator:chestHairColor', function(data, cb)
    ChangeSkinData("chest_3", tonumber(data) or 0)
    cb('ok')
end)

RegisterNUICallback('newCreator:chestHairOpacity', function(data, cb)
    ChangeSkinData("chest_2", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:blemishesStyle', function(data, cb)
    ChangeSkinData("blemishes_1", tonumber(data) or 0)
    cb('ok')
end)

RegisterNUICallback('newCreator:blemishesOpacity', function(data, cb)
    ChangeSkinData("blemishes_2", math.floor((tonumber(data) or 0) * 10))
    cb('ok')
end)

RegisterNUICallback('newCreator:outfit', function(data, cb)
    local outfitName = data
    if type(data) == "table" then outfitName = data.outfit or data[1] end
    
    print('[Creator] Outfit selected:', outfitName, 'Gender:', creatorCharData.gender)
    
    local outfits = GetAvailableOutfits and GetAvailableOutfits() or {}
    
    for name, outfit in pairs(outfits) do
        if name == outfitName then
            local genderKey = creatorCharData.gender or 'm'
            local genderOutfit = outfit[genderKey]
            
            print('[Creator] Found outfit:', name, 'Gender key:', genderKey, 'Data:', json.encode(genderOutfit))
            
            if genderOutfit then
                local componentList = {
                    'tshirt_1', 'tshirt_2',
                    'torso_1', 'torso_2',
                    'arms', 'arms_2',
                    'decals_1', 'decals_2',
                    'pants_1', 'pants_2',
                    'shoes_1', 'shoes_2',
                    'mask_1', 'mask_2',
                    'bproof_1', 'bproof_2',
                    'chain_1', 'chain_2',
                    'bags_1', 'bags_2'
                }
                
                for _, component in ipairs(componentList) do
                    if genderOutfit[component] then
                        creatorTempSkin[component] = genderOutfit[component]
                        TriggerEvent('Null:skinchanger:change', component, genderOutfit[component])
                    end
                end
                
                print('[Creator] Outfit applied via skinchanger!')
            else
                print('[Creator] ERROR: No outfit data for gender:', genderKey)
            end
            break
        end
    end
    cb('ok')
end)

RegisterNUICallback('newCreator:resetCreator', function(_, cb)
    ChangeSkinData("dad", 0)
    ChangeSkinData("mom", 21)
    ChangeSkinData("face_md_weight", 50)
    ChangeSkinData("skin_md_weight", 50)
    ChangeSkinData("hair_1", 0)
    ChangeSkinData("hair_color_1", 0)
    ChangeSkinData("hair_color_2", 0)
    ChangeSkinData("beard_1", 0)
    ChangeSkinData("beard_2", 0)
    ChangeSkinData("beard_3", 0)
    ChangeSkinData("eyebrows_1", 0)
    ChangeSkinData("eyebrows_2", 0)
    ChangeSkinData("eyebrows_3", 0)
    ChangeSkinData("eye_color", 0)
    ChangeSkinData("eye_squint", 0)
    ChangeSkinData("nose_1", 0)
    ChangeSkinData("nose_2", 0)
    ChangeSkinData("nose_3", 0)
    ChangeSkinData("nose_4", 0)
    ChangeSkinData("nose_5", 0)
    ChangeSkinData("cheeks_1", 0)
    ChangeSkinData("lip_thickness", 0)
    ChangeSkinData("chin_1", 0)
    ChangeSkinData("chin_2", 0)
    ChangeSkinData("chin_3", 0)
    ChangeSkinData("neck_thickness", 0)
    ChangeSkinData("lipstick_1", 0)
    ChangeSkinData("lipstick_2", 0)
    ChangeSkinData("lipstick_3", 0)
    ChangeSkinData("chest_1", 0)
    ChangeSkinData("chest_2", 0)
    ChangeSkinData("chest_3", 0)
    ChangeSkinData("blemishes_1", 0)
    ChangeSkinData("blemishes_2", 0)
    cb('ok')
end)

RegisterNUICallback('newCreator:finishCreator', function(data, cb)
    
    if data.firstname then creatorCharData.firstName = data.firstname end
    if data.lastname then creatorCharData.lastName = data.lastname end
    if data.birthdate then
        local birthdate = data.birthdate
        if birthdate:match("^%d%d/%d%d/%d%d%d%d$") then
            local day, month, year = birthdate:match("^(%d%d)/(%d%d)/(%d%d%d%d)$")
            birthdate = year .. "-" .. month .. "-" .. day
        end
        creatorCharData.birthdate = birthdate
    end


    if creatorCharData.firstName == "" or creatorCharData.lastName == "" or creatorCharData.birthdate == "" then
        TriggerEvent('esx:showNotification', "Veuillez remplir toutes les ~r~informations~s~ personnelles.")
        cb('ok')
        return
    end

    if creatorCharData.birthdate then
        local years = tonumber(creatorCharData.birthdate:sub(1, 4))
        local mount = tonumber(creatorCharData.birthdate:sub(6, 7))
        local day = tonumber(creatorCharData.birthdate:sub(9, 10))
        if years and (years > 2020 or years < 1940) then
            TriggerEvent('esx:showNotification', "Votre ~r~année de naissance~s~ n'est pas correcte.")
            cb('ok')
            return
        end
        if mount and (mount <= 0 or mount >= 13) then
            TriggerEvent('esx:showNotification', "Votre ~r~mois de naissance~s~ n'est pas correcte.")
            cb('ok')
            return
        end
        if day and (day <= 0 or day >= 32) then
            TriggerEvent('esx:showNotification', "Votre ~r~jour de naissance~s~ n'est pas correcte.")
            cb('ok')
            return
        end
    end

    -- Sortie fluide : fondu au noir pendant la sauvegarde + téléportation,
    -- puis on révèle le monde en fondu (le tutoriel s'enchaîne ensuite).
    DoScreenFadeOut(450)

    FreezeEntityPosition(PlayerPedId(), false)

    StopSitAnimation()

    TriggerEvent('Null:skinchanger:getSkin', function(skin)
        TriggerServerEvent('Null:esx_skin:save', skin)
        
        local clotheSave = {
            ['tshirt_1'] = "top", ['tshirt_2'] = "top",
            ['torso_1'] = "top", ['torso_2'] = "top",
            ['decals_1'] = "top", ['arms'] = "top",
            ['pants_1'] = "pants", ['pants_2'] = "pants",
            ['shoes_1'] = "shoes", ['shoes_2'] = "shoes",
        }
        
        local top, pant, shoes = {}, {}, {}
        for k, v in pairs(skin) do
            if clotheSave[k] then
                if clotheSave[k] == "top" then top[k] = v
                elseif clotheSave[k] == "pants" then pant[k] = v
                elseif clotheSave[k] == "shoes" then shoes[k] = v
                end
            end
        end

        local function randId()
            return tonumber(math.random(0,9)..""..math.random(0,9)..""..math.random(0,9)..""..math.random(0,9)..""..math.random(0,9)..""..math.random(0,9))
        end

        TriggerServerEvent('null:clothe:addClothinInvWithID', "top", "Tenue d'arriver", top, randId())
        TriggerServerEvent('null:clothe:addClothinInvWithID', "pants", "Tenue d'arriver", pant, randId())
        TriggerServerEvent('null:clothe:addClothinInvWithID', "shoes", "Tenue d'arriver", shoes, randId())

        TriggerServerEvent("Null:charCreator:finish", creatorCharData)
        TriggerServerEvent("null:esx:enter", false)

        if Config and Config.DefaultPosition then
            SetEntityCoords(PlayerPedId(), Config.DefaultPosition.x, Config.DefaultPosition.y, Config.DefaultPosition.z)
            SetEntityHeading(PlayerPedId(), Config.DefaultPosition.w)
        end

        CloseNewCreator()

        -- Monde prêt → fondu d'entrée (le tutoriel s'ouvre ~2s après).
        CreateThread(function()
            Wait(500)
            DoScreenFadeIn(800)
            ExecuteCommand("tutorial")
        end)
    end)

    cb('ok')
end)

exports('OpenNewCreator', OpenNewCreator)
RegisterNetEvent("null:newCreator:open", OpenNewCreator)
