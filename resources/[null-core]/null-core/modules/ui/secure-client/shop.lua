-- Unified Shop - React UI Bridge (null-core)
-- Replaces clothing-store and accessories-store modules
-- Commands: /shop clothes | /shop accessories

local isShopOpen = false
local shopCam = nil
local shopTransitionCam = nil
local shopHeading = 0
local shopSkins = {}
local shopInitialSkins = {}
local shopPreviewSkins = {}
local shopChangedSkins = {}
local shopIsDragging = false
local shopLastMouseX = 0
local shopLastMouseY = 0
local shopCamYaw = 0.0
local shopCamPitch = 0.0
local shopCamDistance = 2.2
local shopCamTargetZ = 0.2
local shopCurrentCategory = "torso_1"
local shopMode = "clothes" -- "clothes" or "accessories"
local shopPreviewPedsActive = false
local shopAllPreviewPeds = {}
local shopSelectedItem = nil
local shopSelectedVariation = 0

local shopVariation = {
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
    ["ears_1"] = "ears_2",
    ["glasses_1"] = "glasses_2",
    ["watches_1"] = "watches_2",
    ["bracelets_1"] = "bracelets_2",
    ["bags_1"] = "bags_2",
}

local shopSkinsToComponents = {
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

local shopPropsToComponents = {
    ["helmet_1"] = 0,
    ["glasses_1"] = 1,
    ["ears_1"] = 2,
    ["watches_1"] = 6,
    ["bracelets_1"] = 7,
}

local function IsMale()
    return GetEntityModel(PlayerPedId()) == GetHashKey("mp_m_freemode_01")
end

-- Camera
local function IsUtilsShopModeActive()
    return shopMode == "barber" or shopMode == "makeup" or shopMode == "tattoo"
end

local function UpdateUtilsShopCam()
    if not DoesCamExist(shopCam) then return end

    local coords = GetEntityCoords(PlayerPedId())
    local targetZ = coords.z + shopCamTargetZ
    local yaw = math.rad(shopCamYaw)
    local pitch = math.rad(shopCamPitch)
    local horizontalDistance = math.cos(pitch) * shopCamDistance

    SetCamCoord(
        shopCam,
        coords.x + math.sin(yaw) * horizontalDistance,
        coords.y + math.cos(yaw) * horizontalDistance,
        targetZ + math.sin(pitch) * shopCamDistance
    )
    PointCamAtCoord(shopCam, coords.x, coords.y, targetZ)
end

local function CreateShopCam()
    if DoesCamExist(shopCam) then DestroyCam(shopCam, true) end
    if DoesCamExist(shopTransitionCam) then DestroyCam(shopTransitionCam, true) end

    shopCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local coords = GetEntityCoords(PlayerPedId())
    SetEntityVisible(PlayerPedId(), true, 0)
    shopCamYaw = 0.0
    shopCamPitch = 0.0
    if IsUtilsShopModeActive() then
        shopCamDistance = 1.65
        shopCamTargetZ = 0.82
        SetCamCoord(shopCam, coords.x, coords.y + shopCamDistance, coords.z + shopCamTargetZ)
        SetCamFov(shopCam, 42.0)
    else
        shopCamDistance = 2.2
        shopCamTargetZ = 0.2
        SetCamCoord(shopCam, coords.x + 0.5, coords.y + 2.2, coords.z + 0.6)
        SetCamRot(shopCam, 0.0, 0.0, 270.0, true)
    end
    SetCamActive(shopCam, true)
    RenderScriptCams(true, true, 1000, true, true)
    if IsUtilsShopModeActive() then
        UpdateUtilsShopCam()
    else
        PointCamAtCoord(shopCam, coords.x, coords.y, coords.z + 0.2)
    end
end

local function UpdateShopCamPosition()
    local coords = GetEntityCoords(PlayerPedId())

    if not DoesCamExist(shopTransitionCam) then
        shopTransitionCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    end

    local currentCamCoord = GetCamCoord(shopCam)
    local currentCamRot = GetCamRot(shopCam, 2)
    SetCamCoord(shopTransitionCam, currentCamCoord.x, currentCamCoord.y, currentCamCoord.z)
    SetCamRot(shopTransitionCam, currentCamRot.x, currentCamRot.y, currentCamRot.z, 2)

    if shopCurrentCategory == "shoes_1" then
        SetCamCoord(shopCam, coords.x + 0.5, coords.y + 1.8, coords.z + 0.0)
        SetCamRot(shopCam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(shopCam, coords.x, coords.y, coords.z - 0.6)
    elseif shopCurrentCategory == "pants_1" then
        SetCamCoord(shopCam, coords.x + 0.5, coords.y + 1.8, coords.z + 0.2)
        SetCamRot(shopCam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(shopCam, coords.x, coords.y, coords.z - 0.2)
    elseif shopCurrentCategory == "ears_1" or shopCurrentCategory == "mask_1" then
        SetCamCoord(shopCam, coords.x + 0.3, coords.y + 1.6, coords.z + 0.8)
        SetCamRot(shopCam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(shopCam, coords.x, coords.y, coords.z + 0.5)
    else
        SetCamCoord(shopCam, coords.x + 0.5, coords.y + 2.2, coords.z + 0.6)
        SetCamRot(shopCam, 0.0, 0.0, 270.0, true)
        PointCamAtCoord(shopCam, coords.x, coords.y, coords.z + 0.2)
    end

    SetCamActiveWithInterp(shopCam, shopTransitionCam, 1000, 3, 3)
end

local function DeleteShopCam()
    SetCamActive(shopCam, false)
    if DoesCamExist(shopTransitionCam) then
        SetCamActive(shopTransitionCam, false)
        DestroyCam(shopTransitionCam, true)
    end
    RenderScriptCams(false, true, 1500, true, true)
    if DoesCamExist(shopCam) then
        DestroyCam(shopCam, true)
    end
    shopCam = nil
    shopTransitionCam = nil
    shopIsDragging = false
    shopCamYaw = 0.0
    shopCamPitch = 0.0
    shopCamDistance = 2.2
    shopCamTargetZ = 0.2
end

-- Preview Peds System
local function CreatePreviewPeds()
    if shopPreviewPedsActive then return end
    
    Citizen.CreateThread(function()
        Wait(1300)
        local nbrPed = 3
        for i = 1, nbrPed do
            shopPreviewPedsActive = true
            local playerModel = GetEntityModel(PlayerPedId())
            shopAllPreviewPeds[i] = CreatePed(26, playerModel, 0.0, 0.0, 0.0, 0.0, false, false)
            ClonePedToTarget(PlayerPedId(), shopAllPreviewPeds[i])
            SetEntityVisible(shopAllPreviewPeds[i], false, 0)
            
            SetEntityCollision(shopAllPreviewPeds[i], false, false)
            SetEntityInvincible(shopAllPreviewPeds[i], true)
            SetEntityLocallyVisible(shopAllPreviewPeds[i])
            NetworkSetEntityInvisibleToNetwork(shopAllPreviewPeds[i], true)
            SetEntityCanBeDamaged(shopAllPreviewPeds[i], false)
            SetBlockingOfNonTemporaryEvents(shopAllPreviewPeds[i], true)
            SetEntityAlpha(shopAllPreviewPeds[i], 254)
            
            ESX.Streaming.RequestAnimDict("amb@world_human_hang_out_street@female_arms_crossed@idle_a", function()
                TaskPlayAnim(shopAllPreviewPeds[i], "amb@world_human_hang_out_street@female_arms_crossed@idle_a", "idle_a", 8.0, -8.0, -1, 49, 0, false, false, false)
            end)
            
            local positionBuffer = {}
            local bufferSize = 5
            
            CreateThread(function()
                local world, normal = GetWorldCoordFromScreenCoord(0.41, 0.83)
                local depth = 2.8
                if i == 2 then
                    world, normal = GetWorldCoordFromScreenCoord(0.59, 0.83)
                    depth = 2.8
                elseif i == 3 then
                    world, normal = GetWorldCoordFromScreenCoord(0.68, 0.82)
                    depth = 3.0
                end
                
                while shopPreviewPedsActive do
                    local target = world + normal * depth
                    
                    table.insert(positionBuffer, target)
                    if #positionBuffer > bufferSize then
                        table.remove(positionBuffer, 1)
                    end
                    
                    local averagedTarget = vector3(0, 0, 0)
                    for _, position in ipairs(positionBuffer) do
                        averagedTarget = averagedTarget + position
                    end
                    averagedTarget = averagedTarget / #positionBuffer
                    
                    SetEntityCoords(shopAllPreviewPeds[i], averagedTarget.x, averagedTarget.y, averagedTarget.z, false, false, false, true)
                    SetEntityHeading(shopAllPreviewPeds[i], shopHeading)
                    
                    -- Apply clothing based on selected item
                    if shopSelectedItem and shopCurrentCategory ~= "cart" then
                        local displaySkins = {}
                        for k, v in pairs(shopSkins) do
                            displaySkins[k] = v
                        end
                        for k, v in pairs(shopPreviewSkins) do
                            displaySkins[k] = v
                        end
                        
                        for category, value in pairs(displaySkins) do
                            if string.match(category, "_1$") then
                                local variation = category:gsub("_1$", "_2")
                                if category == shopCurrentCategory then
                                    if shopSkinsToComponents[category] then
                                        local maxVariation = GetNumberOfPedTextureVariations(shopAllPreviewPeds[i], shopSkinsToComponents[category], shopSelectedItem)
                                        local variationValue = shopSelectedVariation or 0
                                        
                                        if maxVariation > 0 and variationValue + i <= maxVariation then
                                            if i == 1 and (variationValue - 1) ~= -1 then
                                                SetEntityVisible(shopAllPreviewPeds[i], true, 0)
                                                SetPedComponentVariation(shopAllPreviewPeds[i], shopSkinsToComponents[category], shopSelectedItem, variationValue + i - 2, 0)
                                            elseif i ~= 1 then
                                                SetEntityVisible(shopAllPreviewPeds[i], true, 0)
                                                SetPedComponentVariation(shopAllPreviewPeds[i], shopSkinsToComponents[category], shopSelectedItem, variationValue + i - 1, 0)
                                            else 
                                                SetEntityVisible(shopAllPreviewPeds[i], false, 0)
                                                SetPedComponentVariation(shopAllPreviewPeds[i], shopSkinsToComponents[category], shopSelectedItem, variationValue, 0)
                                            end
                                        else
                                            SetEntityVisible(shopAllPreviewPeds[i], false, 0)
                                            SetPedComponentVariation(shopAllPreviewPeds[i], shopSkinsToComponents[category], shopSelectedItem, variationValue, 0)
                                        end
                                    elseif shopPropsToComponents[category] then
                                        local maxVariation = GetNumberOfPedPropTextureVariations(shopAllPreviewPeds[i], shopPropsToComponents[category], shopSelectedItem)
                                        local variationValue = shopSelectedVariation or 0
                                        
                                        if maxVariation > 0 and variationValue + i <= maxVariation then
                                            if i == 1 and (variationValue - 1) ~= -1 then
                                                SetPedPropIndex(shopAllPreviewPeds[i], shopPropsToComponents[category], shopSelectedItem, variationValue + i - 2, 0)
                                                SetEntityVisible(shopAllPreviewPeds[i], true, 0)
                                            elseif i ~= 1 then
                                                SetPedPropIndex(shopAllPreviewPeds[i], shopPropsToComponents[category], shopSelectedItem, variationValue + i - 1, 0)
                                                SetEntityVisible(shopAllPreviewPeds[i], true, 0)
                                            else 
                                                SetEntityVisible(shopAllPreviewPeds[i], false, 0)
                                                SetPedComponentVariation(shopAllPreviewPeds[i], shopSkinsToComponents[category], shopSelectedItem, variationValue, 0)
                                            end
                                        else
                                            SetEntityVisible(shopAllPreviewPeds[i], false, 0)
                                            SetPedPropIndex(shopAllPreviewPeds[i], shopPropsToComponents[category], shopSelectedItem, variationValue, 0)
                                        end
                                    end
                                else
                                    local variationValue = displaySkins[variation] or 0
                                    if shopSkinsToComponents[category] then
                                        SetPedComponentVariation(shopAllPreviewPeds[i], shopSkinsToComponents[category], value, variationValue, 0)
                                    elseif shopPropsToComponents[category] then
                                        SetPedPropIndex(shopAllPreviewPeds[i], shopPropsToComponents[category], value, variationValue, 0)
                                    end
                                end
                            elseif category == "arms" then
                                if category == shopCurrentCategory then
                                    SetEntityVisible(shopAllPreviewPeds[i], false, 0)
                                    SetPedComponentVariation(shopAllPreviewPeds[i], shopSkinsToComponents[category], value, 0, 0)
                                end
                            end
                        end
                    else
                        SetEntityVisible(shopAllPreviewPeds[i], false, 0)
                    end
                    
                    if not IsEntityPlayingAnim(shopAllPreviewPeds[i], "amb@world_human_hang_out_street@female_arms_crossed@idle_a", "idle_a", 3) then
                        ESX.Streaming.RequestAnimDict("amb@world_human_hang_out_street@female_arms_crossed@idle_a", function()
                            TaskPlayAnim(shopAllPreviewPeds[i], "amb@world_human_hang_out_street@female_arms_crossed@idle_a", "idle_a", 8.0, -8.0, -1, 49, 0, false, false, false)
                        end)
                    end
                    
                    Wait(4)
                end
                
                DeletePed(shopAllPreviewPeds[i])
            end)
        end
    end)
end

local function DeletePreviewPeds()
    shopPreviewPedsActive = false
    Wait(100)
    for k, v in pairs(shopAllPreviewPeds) do
        if DoesEntityExist(v) then
            DeletePed(v)
        end
    end
    shopAllPreviewPeds = {}
end

-- ============================================================================
-- Résolution de la brand active pour un shop donné.
--   `cfg`      : `Config.ClothingShop` ou `Config.AccessoriesShop`
--   `brandId`  : id explicite passé par le caller (depuis `Type` du shop)
-- Retourne la table de brand ou nil.
--
-- Ordre de résolution :
--   1. `cfg.Brands[brandId]` si brandId fourni
--   2. `cfg.Brands[cfg.DefaultBrand]`
--   3. `cfg.Brand`  (compat ancienne config — Brand singulier)
-- ============================================================================
local function ResolveShopBrand(cfg, brandId)
    if not cfg then return nil end
    if cfg.Brands then
        if brandId and cfg.Brands[brandId] then
            return cfg.Brands[brandId]
        end
        if cfg.DefaultBrand and cfg.Brands[cfg.DefaultBrand] then
            return cfg.Brands[cfg.DefaultBrand]
        end
    end
    return cfg.Brand
end

-- ============================================================================
-- UTILS SHOP STATE (barber / makeup / tattoo)
--   shopUtilsCart  : pour barber/makeup → { hair=id, beard=id, ... }
--                    pour tattoo       → liste { collection, nameHash }
--   shopUtilsInitial : snapshot du skin / decorations à l'ouverture, pour
--                      restaurer si l'utilisateur ferme sans payer.
-- ============================================================================
local shopUtilsCart = {}
local shopUtilsInitial = {}
local shopUtilsInitialDecorations = {} -- liste tattoos posés à l'ouverture

local UTILS_MODES = {
    barber = true,
    makeup = true,
    tattoo = true,
}

local function isUtilsMode(mode)
    return UTILS_MODES[mode] == true
end

-- Catégories envoyées au front pour chaque mode utils.
local SHOP_UTILS_CATEGORIES = {
    barber = {
        { id = "hair",     label = "Cheveux"  },
        { id = "beard",    label = "Barbe"    },
        { id = "eyebrows", label = "Sourcils" },
    },
    makeup = {
        { id = "makeup",   label = "Maquillage"     },
        { id = "lipstick", label = "Rouge à lèvres" },
        { id = "blush",    label = "Blush"          },
    },
    tattoo = {
        -- Pour les tattoos on regroupe par zone du corps. Les items
        -- sont filtrés côté front en fonction du `zone` détecté par
        -- imagemaker (cf. detectTattooZone).
        { id = "neck",    label = "Tête / Cou" },
        { id = "chest",   label = "Poitrine"   },
        { id = "stomach", label = "Ventre"     },
        { id = "back",    label = "Dos"        },
        { id = "larm",    label = "Bras gauche" },
        { id = "rarm",    label = "Bras droit"  },
        { id = "lleg",    label = "Jambe gauche" },
        { id = "rleg",    label = "Jambe droite" },
    },
}

-- Résout la config (barber/makeup/tattoo) et la liste tattoos par genre.
local function GetUtilsCfg(mode)
    if mode == "barber" then return Config.Barber
    elseif mode == "makeup" then return Config.MakeupShop
    elseif mode == "tattoo" then return Config.Tattoo
    end
    return nil
end

-- Aplatit Config.Tattoo.TattooList pour le front (mêmes critères que
-- imagemaker : détection genre + zone par parsing du nameHash).
local function buildTattooListsForFront()
    local lists = { male = {}, female = {} }
    if not (Config.Tattoo and Config.Tattoo.TattooList) then return lists end
    for collection, items in pairs(Config.Tattoo.TattooList) do
        for _, it in ipairs(items) do
            local n = it.nameHash or ""
            local g = "both"
            if n:match("_M_") or n:match("_M$") then g = "male"
            elseif n:match("_F_") or n:match("_F$") then g = "female" end
            local lower = n:lower()
            local zone = "torso"
            if     lower:find("hair")  then zone = "neck"
            elseif lower:find("neck")  then zone = "neck"
            elseif lower:find("back")  then zone = "back"
            elseif lower:find("chest") or lower:find("bust") then zone = "chest"
            elseif lower:find("stom")  then zone = "stomach"
            elseif lower:find("larm") or lower:find("leftarm") or lower:find("l_arm") then zone = "larm"
            elseif lower:find("rarm") or lower:find("rightarm") or lower:find("r_arm") then zone = "rarm"
            elseif lower:find("lleg") or lower:find("leftleg")  or lower:find("l_leg") then zone = "lleg"
            elseif lower:find("rleg") or lower:find("rightleg") or lower:find("r_leg") then zone = "rleg"
            end
            local entry = { collection = collection, nameHash = n, zone = zone, price = it.price or 100 }
            if g == "male"   or g == "both" then table.insert(lists.male, entry)   end
            if g == "female" or g == "both" then table.insert(lists.female, entry) end
        end
    end
    return lists
end

-- Open shop
--   `mode`    : "clothes" | "accessories" | "barber" | "makeup" | "tattoo"
--   `brandId` : id de la marque (clé de `Brands`) — typiquement le `Type`
--               du marker depuis lequel le shop est ouvert.
function OpenShop(mode, brandId)
    if isShopOpen then return end
    if exports["null-core"]:playerIsDead() then return end

    isShopOpen = true
    shopMode = mode or "clothes"
    null.DisplayHud("always-display", false)
    null.DisplayHud("additional-display", false)
    null.DisplayHud("3dinteractions", false)
    DisplayRadar(false)
    FreezeEntityPosition(PlayerPedId(), true)
    SetPlayerControl(PlayerId(), false, 12)

    CreateShopCam()
    shopHeading = GetEntityHeading(PlayerPedId())

    local pedtype = IsMale() and "male" or "female"

    -- ====================================================================
    -- Branche modes utils (barber / makeup / tattoo) — pas de peds preview,
    -- pas de cart vêtements, juste sidebar + grille + brand.
    -- ====================================================================
    if isUtilsMode(shopMode) then
        local utilsCfg = GetUtilsCfg(shopMode)
        local brand = ResolveShopBrand(utilsCfg, brandId)
        shopUtilsCart = {}
        shopUtilsInitial = {}
        shopUtilsInitialDecorations = {}

        -- Snapshot du skin actuel (pour restaurer au close sans pay)
        ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
            for k, v in pairs(skin) do shopUtilsInitial[k] = v end

            local payload = {
                mode = shopMode,
                playerSex = pedtype,
                brand = brand,
                categories = SHOP_UTILS_CATEGORIES[shopMode] or {},
                price = utilsCfg and utilsCfg.Price or 100,
                skin = skin,
                maxValues = {
                    hair = GetNumberOfPedDrawableVariations(PlayerPedId(), 2),
                    beard = GetNumHeadOverlayValues(1),
                    eyebrows = GetNumHeadOverlayValues(2),
                    colors = GetNumHairColors(),
                    opacity = 10,
                },
            }
            if shopMode == "tattoo" then
                payload.tattoosList = buildTattooListsForFront()[pedtype] or {}
            end

            SetNuiFocus(true, true)
            SendNUIMessage({ action = "shop:open", data = payload })
        end)
        return
    end

    -- ====================================================================
    -- Modes vêtement / accessoires (existant)
    -- ====================================================================
    shopCurrentCategory = mode == "accessories" and "helmet_1" or "torso_1"
    shopPreviewSkins = {}
    shopInitialSkins = {}
    shopChangedSkins = {}

    ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
        shopSkins = skin
        for k, v in pairs(skin) do
            shopInitialSkins[k] = v
        end

        local bagInfo = {}
        if Config.ListBags then
            bagInfo = Config.ListBags
        end

        local shopCfg = (shopMode == "accessories") and Config.AccessoriesShop or Config.ClothingShop
        local brand = ResolveShopBrand(shopCfg, brandId)

        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "shop:open",
            data = {
                mode = shopMode,
                playerSex = pedtype,
                skins = json.encode(skin),
                prices = {
                    MainPrice = Config.ClothingShop.MainPrice,
                    CategoryMainPrice = Config.ClothingShop.CategoryMainPrice,
                    CustomPrice = Config.ClothingShop.CustomPrice,
                },
                blackList = Config.ClothingShop.blackListed or {},
                bagInfo = bagInfo,
                brand = brand,
            }
        })

        CreatePreviewPeds()
    end)
end

-- Close shop
local function CloseShop(changeSkin)
    if not isShopOpen then return end
    isShopOpen = false

    SetNuiFocus(false, false)
    SendNUIMessage({ action = "shop:close" })
    null.DisplayHud("always-display", true)
    null.DisplayHud("additional-display", true)
    null.DisplayHud("3dinteractions", true)
    DisplayRadar(true)
    SetPlayerControl(PlayerId(), true, 12)
    FreezeEntityPosition(PlayerPedId(), false)
    DeleteShopCam()
    DeletePreviewPeds()

    -- Branche modes utils (barber/makeup/tattoo)
    if isUtilsMode(shopMode) then
        local initialSkin = shopUtilsInitial
        local hadInitialSkin = next(initialSkin) ~= nil
        shopUtilsCart = {}
        shopUtilsInitial = {}
        shopUtilsInitialDecorations = {}
        if not changeSkin then
            -- Restore the exact opening snapshot, including hair/beard/
            -- eyebrow colors and opacities changed during the preview.
            if hadInitialSkin then
                TriggerEvent('Null:skinchanger:loadSkin', initialSkin)
            else
                ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
                    TriggerEvent('Null:skinchanger:loadSkin', skin)
                end)
            end
            -- Recharge les tattoos depuis le serveur
            TriggerServerEvent("null:tattoo:player:request:tattoo")
        end
        shopMode = "clothes"
        return
    end

    if not changeSkin then
        -- Restore initial skins
        if next(shopInitialSkins) then
            for k, v in pairs(shopInitialSkins) do
                shopSkins[k] = v
            end
            TriggerEvent('Null:skinchanger:loadClothes', shopInitialSkins, shopInitialSkins)
        end
        shopChangedSkins = {}
        shopPreviewSkins = {}
        shopInitialSkins = {}
        -- Reload from DB
        ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
            TriggerEvent('Null:skinchanger:loadClothes', skin, skin)
            for k, v in pairs(skin) do
                shopSkins[k] = v
            end
        end)
    else
        -- DO NOT apply skin automatically - player must equip manually from inventory
        shopPreviewSkins = {}
        shopInitialSkins = {}
        shopChangedSkins = {}
        
        -- Restore initial skin (before preview)
        ESX.TriggerServerCallback('Null:esx_skin:getPlayerSkin', function(skin)
            TriggerEvent('Null:skinchanger:loadClothes', skin, skin)
            for k, v in pairs(skin) do
                shopSkins[k] = v
            end
        end)
    end
end

-- Exports
exports("OpenShop", OpenShop)

-- Commands
RegisterCommand("shop", function(source, args)
    local mode = args[1] or "clothes"
    if mode ~= "clothes" and mode ~= "accessories" then mode = "clothes" end
    OpenShop(mode)
end, false)

-- ==================
-- NUI Callbacks - Clothes mode
-- ==================
RegisterNUICallback("shop:clothes:exit", function(data, cb)
    CloseShop(data.changeSkin or false)
    cb('ok')
end)

RegisterNUICallback("shop:clothes:updateSkin", function(data, cb)
    shopSkins[data.type] = data.number
    shopSelectedItem = data.number
    shopSelectedVariation = 0
    TriggerEvent("Null:skinchanger:change", data.type, data.number)
    if data.type ~= "arms" then
        local variationType = shopVariation[data.type]
        if variationType then
            shopSkins[variationType] = 0
            TriggerEvent("Null:skinchanger:change", variationType, 0)
        end
    end
    SetPlayerControl(PlayerId(), false, 12)
    cb('ok')
end)

RegisterNUICallback("shop:clothes:updateVariation", function(data, cb)
    local varType = data.type
    shopSkins[varType] = data.number
    shopSelectedVariation = data.number
    TriggerEvent("Null:skinchanger:change", varType, data.number)
    SetPlayerControl(PlayerId(), false, 12)
    cb('ok')
end)

RegisterNUICallback("shop:clothes:changeCategory", function(data, cb)
    shopCurrentCategory = data.category
    shopSelectedItem = nil
    shopSelectedVariation = 0
    UpdateShopCamPosition()
    cb('ok')
end)

RegisterNUICallback("shop:clothes:getMaxVariations", function(data, cb)
    local category = data.category
    local currentValue = shopSkins[category] or 0
    if shopSkinsToComponents[category] then
        local maxVariations = GetNumberOfPedTextureVariations(PlayerPedId(), shopSkinsToComponents[category], currentValue)
        cb({ max = maxVariations })
    else
        cb({ max = 0 })
    end
end)

RegisterNUICallback("shop:clothes:startRotation", function(data, cb)
    shopIsDragging = true
    shopLastMouseX = data.mouseX
    cb({})
end)

RegisterNUICallback("shop:clothes:stopRotation", function(data, cb)
    shopIsDragging = false
    cb({})
end)

RegisterNUICallback("shop:clothes:updateRotation", function(data, cb)
    if shopIsDragging then
        local currentHeading = GetEntityHeading(PlayerPedId())
        local mouseDelta = data.mouseX - shopLastMouseX
        SetEntityHeading(PlayerPedId(), currentHeading - (mouseDelta * 0.5))
        shopHeading = currentHeading - (mouseDelta * 0.5)
        shopLastMouseX = data.mouseX
    end
    cb({})
end)

RegisterNUICallback("shop:clothes:pay", function(data, cb)
    local name = null.fct.input('Nom de la tenue', GetCurrentResourceName()) 
    ESX.TriggerServerCallback('Null:clothes:pay', function(good)
        if good then
            CloseShop(true)
            cb({ success = true })
        else
            if data.paymentMethod == 'bank' then
                ESX.ShowNotification("Vous n'avez pas assez d'argent sur votre compte bancaire")
            else
                ESX.ShowNotification("Vous n'avez pas assez d'argent en liquide")
            end
            cb({ success = false })
        end
    end, data.items, data.paymentMethod, name)
end)

-- ==================
-- NUI Callbacks - Accessories mode
-- ==================
RegisterNUICallback("shop:acc:exit", function(data, cb)
    CloseShop(data.changeSkin or false)
    cb('ok')
end)

RegisterNUICallback("shop:acc:updateSkin", function(data, cb)
    shopPreviewSkins[data.type] = data.number
    shopSelectedItem = data.number
    shopSelectedVariation = 0
    TriggerEvent("Null:skinchanger:change", data.type, data.number)
    local variationType = shopVariation[data.type]
    if variationType then
        shopPreviewSkins[variationType] = 0
        TriggerEvent("Null:skinchanger:change", variationType, 0)
    end
    SetPlayerControl(PlayerId(), false, 12)
    cb('ok')
end)

RegisterNUICallback("shop:acc:updateVariation", function(data, cb)
    local varType = data.type
    shopPreviewSkins[varType] = data.number
    shopSelectedVariation = data.number
    TriggerEvent("Null:skinchanger:change", varType, data.number)
    SetPlayerControl(PlayerId(), false, 12)
    cb('ok')
end)

RegisterNUICallback("shop:acc:changeCategory", function(data, cb)
    shopCurrentCategory = data.category
    shopSelectedItem = nil
    shopSelectedVariation = 0

    -- Handle special cases
    if data.category == "ears_1" then
        shopChangedSkins["mask_1"] = shopSkins["mask_1"]
        shopChangedSkins["mask_2"] = shopSkins["mask_2"]
        TriggerEvent("Null:skinchanger:change", "mask_1", -1)
    elseif data.category == "bracelets_1" then
        TriggerEvent("Null:skinchanger:change", "torso_1", 0)
    else
        for k, v in pairs(shopChangedSkins) do
            TriggerEvent("Null:skinchanger:change", k, v)
        end
        shopChangedSkins = {}
    end

    UpdateShopCamPosition()
    cb('ok')
end)

RegisterNUICallback("shop:acc:getMaxVariations", function(data, cb)
    local category = data.category
    local currentValue = shopSkins[category] or 0
    if shopPreviewSkins[category] ~= nil then
        currentValue = shopPreviewSkins[category]
    end

    if shopSkinsToComponents[category] then
        local maxVariations = GetNumberOfPedTextureVariations(PlayerPedId(), shopSkinsToComponents[category], currentValue)
        cb({ max = maxVariations })
    elseif shopPropsToComponents[category] then
        local maxVariations = GetNumberOfPedPropTextureVariations(PlayerPedId(), shopPropsToComponents[category], currentValue)
        cb({ max = maxVariations })
    else
        cb({ max = 0 })
    end
end)

RegisterNUICallback("shop:acc:startRotation", function(data, cb)
    shopIsDragging = true
    shopLastMouseX = data.mouseX
    cb({})
end)

RegisterNUICallback("shop:acc:stopRotation", function(data, cb)
    shopIsDragging = false
    cb({})
end)

RegisterNUICallback("shop:acc:updateRotation", function(data, cb)
    if shopIsDragging then
        local currentHeading = GetEntityHeading(PlayerPedId())
        local mouseDelta = data.mouseX - shopLastMouseX
        SetEntityHeading(PlayerPedId(), currentHeading - (mouseDelta * 0.5))
        shopHeading = currentHeading - (mouseDelta * 0.5)
        shopLastMouseX = data.mouseX
    end
    cb({})
end)

RegisterNUICallback("shop:acc:buyAccessories", function(data, cb)
    local name = null.fct.input("Nom de l'accessoire", GetCurrentResourceName())
    
    if not name or name == "" then
        cb({ success = false })
        return
    end
    
    ESX.TriggerServerCallback('Null:accessories:buy', function(good)
        if good then
            if data.items then
                for category, itemData in pairs(data.items) do
                    shopSkins[category] = itemData.item
                    if shopVariation[category] then
                        shopSkins[shopVariation[category]] = itemData.variation
                    end
                end
            end
            
            TriggerEvent("null:inventory:invalidateClothesCache")
            
            Wait(300)
            TriggerEvent("null:inventory:update")
            
            CloseShop(true)
            cb({ success = true })
        else
            if data.method == 'bank' then
                ESX.ShowNotification("Vous n'avez pas assez d'argent sur votre compte bancaire")
            else
                ESX.ShowNotification("Vous n'avez pas assez d'argent en liquide")
            end
            cb({ success = false })
        end
    end, data.items, data.method, name)
end)

-- ============================================================================
-- NUI Callbacks - Utils mode (barber / makeup / tattoo)
-- ============================================================================

-- Map des skinchanger keys par utilsType (overlay principal seulement, pas
-- couleur/opacité — gérés à part).
local UTILS_SKIN_KEYS = {
    hair      = "hair_1",
    beard     = "beard_1",
    eyebrows  = "eyebrows_1",
    makeup    = "makeup_1",
    lipstick  = "lipstick_1",
    blush     = "blush_1",  -- non géré par skinchanger actuel; ignoré côté load
}

-- Nombre de variations dispo pour un type utils (barber/makeup).
--   hair = composante 2 ; barbe/sourcils/maquillage = head overlays.
local UTILS_OVERLAY_ID = {
    beard = 1, eyebrows = 2, makeup = 4, blush = 5, lipstick = 8,
}
RegisterNUICallback("shop:utils:getMaxVariations", function(data, cb)
    local utilsType = data and data.utilsType
    local ped = PlayerPedId()
    local max = 0
    if utilsType == "hair" then
        max = GetNumberOfPedDrawableVariations(ped, 2)
    elseif UTILS_OVERLAY_ID[utilsType] then
        max = GetPedHeadOverlayNum(UTILS_OVERLAY_ID[utilsType])
    end
    cb({ max = max })
end)

-- Camera controls for the utils shop. The camera orbits the player's head
-- while the NUI remains focused, so the preview can be inspected without
-- changing the ped heading used by the rest of the game.
RegisterNUICallback("shop:utils:startRotation", function(data, cb)
    if not IsUtilsShopModeActive() then cb({}); return end
    shopIsDragging = true
    shopLastMouseX = tonumber(data and data.mouseX) or 0
    shopLastMouseY = tonumber(data and data.mouseY) or 0
    cb({})
end)

RegisterNUICallback("shop:utils:stopRotation", function(data, cb)
    shopIsDragging = false
    cb({})
end)

RegisterNUICallback("shop:utils:updateRotation", function(data, cb)
    if shopIsDragging and IsUtilsShopModeActive() then
        local currentX = tonumber(data and data.mouseX) or shopLastMouseX
        local currentY = tonumber(data and data.mouseY) or shopLastMouseY
        local deltaX = currentX - shopLastMouseX
        local deltaY = currentY - shopLastMouseY
        shopCamYaw = shopCamYaw + (deltaX * 0.35)
        shopCamPitch = math.max(-28.0, math.min(28.0, shopCamPitch - (deltaY * 0.25)))
        shopLastMouseX = currentX
        shopLastMouseY = currentY
        UpdateUtilsShopCam()
    end
    cb({})
end)

RegisterNUICallback("shop:utils:zoom", function(data, cb)
    if IsUtilsShopModeActive() and DoesCamExist(shopCam) then
        local delta = tonumber(data and data.delta) or 0
        shopCamDistance = math.max(0.9, math.min(2.6, shopCamDistance + (delta > 0 and 0.12 or -0.12)))
        UpdateUtilsShopCam()
    end
    cb({})
end)

local UTILS_EDITABLE_KEYS = {
    hair_color_1 = true, hair_color_2 = true,
    beard_2 = true, beard_3 = true, beard_4 = true,
    eyebrows_2 = true, eyebrows_3 = true, eyebrows_4 = true,
}

RegisterNUICallback("shop:utils:update", function(data, cb)
    local key = data and data.key
    if not UTILS_EDITABLE_KEYS[key] then cb({ ok = false }); return end

    local value = tonumber(data.value)
    if not value then cb({ ok = false }); return end
    if key == "beard_2" or key == "eyebrows_2" then
        value = math.max(0, math.min(10, math.floor(value)))
    else
        value = math.max(0, math.min(GetNumHairColors() - 1, math.floor(value)))
    end

    TriggerEvent("Null:skinchanger:change", key, value)
    cb({ ok = true, value = value })
end)

-- Applique en preview un item utils (barber/makeup).
--   data = { utilsType, variationId }
RegisterNUICallback("shop:utils:apply", function(data, cb)
    local utilsType   = data.utilsType
    local variationId = tonumber(data.variationId) or 0
    local key = UTILS_SKIN_KEYS[utilsType]
    if key then
        shopUtilsCart[utilsType] = variationId
        TriggerEvent("Null:skinchanger:change", key, variationId)
        if utilsType == "hair" then
            -- réinitialise le sub-texture pour hair
            TriggerEvent("Null:skinchanger:change", "hair_2", 0)
        end
    end
    cb('ok')
end)

-- Ajoute un tattoo au panier + applique en preview.
--   data = { collection, nameHash }
RegisterNUICallback("shop:utils:tattoo:add", function(data, cb)
    if not (data and data.collection and data.nameHash) then cb({ ok = false }); return end
    -- Vérifie pas déjà en cart
    for _, t in ipairs(shopUtilsCart) do
        if t.nameHash == data.nameHash then cb({ ok = true, dup = true }); return end
    end
    table.insert(shopUtilsCart, {
        collection = data.collection,
        nameHash   = data.nameHash,
        zone       = data.zone,
        price      = tonumber(data.price) or 100,
    })
    AddPedDecorationFromHashes(PlayerPedId(), GetHashKey(data.collection), GetHashKey(data.nameHash))
    cb({ ok = true })
end)

-- Retire un tattoo du panier (et reset les decorations).
--   data = { nameHash }
RegisterNUICallback("shop:utils:tattoo:remove", function(data, cb)
    if not (data and data.nameHash) then cb({ ok = false }); return end
    local kept = {}
    for _, t in ipairs(shopUtilsCart) do
        if t.nameHash ~= data.nameHash then table.insert(kept, t) end
    end
    shopUtilsCart = kept
    -- Reset & réapplique les tattoos restants
    ClearPedDecorations(PlayerPedId())
    for _, t in ipairs(shopUtilsCart) do
        AddPedDecorationFromHashes(PlayerPedId(), GetHashKey(t.collection), GetHashKey(t.nameHash))
    end
    cb({ ok = true })
end)

-- Quitte sans payer → restaure
RegisterNUICallback("shop:utils:exit", function(data, cb)
    CloseShop(false)
    cb('ok')
end)

-- Paiement (barber/makeup → applique skin et le sauvegarde,
--           tattoo → ajoute les tattoos achetés à la persistence)
RegisterNUICallback("shop:utils:pay", function(data, cb)
    local mode = data.mode
    if mode == "barber" or mode == "makeup" then
        -- Vérifie + déduit le cash, puis sauve le skin courant (déjà preview).
        ESX.TriggerServerCallback("Null:barber:purchase", function(ok)
            if ok then
                TriggerEvent('Null:skinchanger:getSkin', function(skin)
                    TriggerServerEvent('Null:esx_skin:save', skin)
                end)
                CloseShop(true)
                cb({ success = true })
            else
                ESX.ShowNotification("~r~Vous n'avez pas assez d'argent")
                cb({ success = false })
            end
        end, mode)
    elseif mode == "tattoo" then
        local total = 0
        local serialized = {}
        for _, t in ipairs(shopUtilsCart) do
            total = total + (t.price or 100)
            table.insert(serialized, {
                cat  = GetHashKey(t.collection),
                name = GetHashKey(t.nameHash),
            })
        end
        if #serialized == 0 then cb({ success = false, empty = true }); return end
        -- Null:tattoo:purchase merge avec les tattoos existants en DB.
        TriggerServerEvent("Null:tattoo:purchase", total, serialized)
        CloseShop(true)
        cb({ success = true })
    else
        cb({ success = false })
    end
end)
