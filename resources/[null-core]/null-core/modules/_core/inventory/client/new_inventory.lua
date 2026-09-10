-- ============================================================================
-- NEW INVENTORY - NUI Callbacks & Event Bridges
-- Routes React NUI callbacks to existing null inventory events
-- Open/Close/Update are handled by NullInventory in main.lua
-- ============================================================================

while not _G.NullInventoryClientLoaded do
    Wait(0)
end

-- ============================================================================
-- NUI CALLBACKS — React → Lua
-- ============================================================================

RegisterNUICallback('newInventory:close', function(_, cb)
    NullInventory.Close()
    cb({})
end)

RegisterNUICallback('newInventory:searchFocus', function(_, cb)
    pcall(function() exports["null-core"]:setChatCanOpen(false) end)
    exports["null-core"]:ActiveFrontend(true)
    cb({})
end)

RegisterNUICallback('newInventory:searchBlur', function(_, cb)
    exports["null-core"]:ActiveFrontend(false)
    pcall(function() exports["null-core"]:setChatCanOpen(true) end)
    cb({})
end)

RegisterNUICallback('newInventory:useItem', function(data, cb)
    TriggerEvent("null:inventory:nui:useItem", data)
    cb({})
end)

RegisterNUICallback('newInventory:giveItem', function(data, cb)
    TriggerEvent("null:inventory:nui:giveItem", data)
    cb({})
end)

RegisterNUICallback('newInventory:dropItem', function(data, cb)
    TriggerEvent("null:inventory:nui:dropItem", data)
    cb({})
end)

RegisterNUICallback('newInventory:renameItem', function(data, cb)
    cb({})
    -- New rename system: React sends { item, newName } directly
    if data.newName and data.newName ~= "" then
        RenameItem(data.item, data.newName)
    end
end)

RegisterNUICallback('newInventory:changeSlot', function(data, cb)
    TriggerEvent("null:inventory:nui:changeSlot", data)
    cb({})
end)

RegisterNUICallback('newInventory:moveSlot', function(data, cb)
    TriggerServerEvent("null:inventory:moveSlot", data)
    cb({})
end)

RegisterNUICallback('newInventory:shortcutSet', function(data, cb)
    exports["null-core"]:setWeaponKeybind(NullInventory._weaponBinds.numbers[data.slot-1], data.item.name, data.item.label)
    cb({})
end)

RegisterNUICallback('newInventory:shortcutRemove', function(data, cb)
    exports["null-core"]:setWeaponKeybind(NullInventory._weaponBinds.numbers[data.slot-1], "WEAPON_UNARMED", "Aucun")
    cb({})
end)

RegisterNUICallback('newInventory:equipAccessory', function(data, cb)
    TriggerEvent("null:inventory:nui:equipAccessory", data)
    cb('ok')
end)

RegisterNUICallback('newInventory:removeAccessory', function(data, cb)
    TriggerEvent("null:inventory:nui:removeAccessory", data)
    cb({})
end)

RegisterNUICallback('newInventory:kevlarUnequip', function(_, cb)
    TriggerEvent("null:kevlar:removeItem")
    cb('ok')
end)

-- ============================================================================
-- HUB PANEL CALLBACKS — Quick Actions, Hub Links, Craft, Settings
-- ============================================================================

RegisterNUICallback('newInventory:removeAllClothes', function(_, cb)
    cb({})
    if not NullInventory.isOpen then return end
    
    NullInventory._lastOutfit = {}
    if NullInventory.equippedClothes then
        for k, v in pairs(NullInventory.equippedClothes) do
            NullInventory._lastOutfit[k] = v
        end
    end
    
    local clothesToRemove = {
        helmet_1 = "hat",
        mask_1 = "mask",
        glasses_1 = "glasses",
        ears_1 = "ear",
        watches_1 = "watch",
        bracelets_1 = "bracelet",
        chain_1 = "neck",
        bproof_1 = "gillet",
        bags_1 = "bag",
        torso_1 = "top",
        pants_1 = "pants",
        shoes_1 = "shoes"
    }
    
    SendNUIMessage({ action = "newInventory:setLoading", data = { loading = true } })

    for k, v in pairs(clothesToRemove) do
        RemoveAccessory(k, false) 
    end

    Wait(100)
    RefreshInventoryPed()
    --TriggerEvent("null:inventory:update")
    SendNUIMessage({ action = "newInventory:setLoading", data = { loading = false } })
end)


RegisterNUICallback('newInventory:restoreLastOutfit', function(_, cb)
    cb({})
    if not NullInventory.isOpen then return end
    if not NullInventory._lastOutfit or next(NullInventory._lastOutfit) == nil then 
        TriggerEvent("inventory:sendMessage", "~r~Aucune tenue à remettre")
        return 
    end
    
    SendNUIMessage({ action = "newInventory:setLoading", data = { loading = true } })

    for clotheType, clotheData in pairs(NullInventory._lastOutfit) do
        if clotheData and clotheData.data then
            EquipAccessory(clotheType, {
                type = "accessory",
                type2 = clotheType,
                name = clotheData.name or clotheData.id,
                label = clotheData.label,
                data = clotheData.data,
                count = 1,
            }, false)
        end
    end

    Wait(100)
    RefreshInventoryPed()
    SendNUIMessage({ action = "newInventory:setLoading", data = { loading = false } })
    --TriggerEvent("null:inventory:update")
end)

RegisterNUICallback('newInventory:hubAction', function(data, cb)
    cb({})
    if not data or not data.action then return end
    local action = data.action

    -- Close inventory first, then open the target interface
    NullInventory.Close()
    Wait(400)

    if action == "hub:openReglement" then
        OpenReglement()
    elseif action == "hub:openHudEditor" then
        exports["null-core"]:OpenHUDEditor()
    elseif action == "hub:openBoutique" then
        exports["null-core"]:OpenBoutique()
    elseif action == "hub:openTablet" then
        OpenIllegalTablet()
    elseif action == "hub:openAnimations" then
        exports["null-core"]:openAnimations()
    end
end)

-- Set a GPS waypoint to the selected society (called from the home "Status
-- des entreprises" grid)
RegisterNUICallback('newInventory:societyWaypoint', function(data, cb)
    cb({})
    if not data or not data.name then return end
    ESX.TriggerServerCallback("Core:GetSociety", function(societies)
        local s = societies and societies[data.name]
        if s and s.position then
            SetNewWaypoint(s.position.x + 0.0, s.position.y + 0.0)
            ESX.ShowNotification("~g~GPS~s~ → "..(s.label or s.name))
        else
            ESX.ShowNotification("~r~Aucune position disponible pour cette entreprise")
        end
    end)
end)

RegisterNUICallback('newInventory:settingChange', function(data, cb)
    cb({})
    if not data or not data.id then return end
    TriggerEvent("null:inventory:settingChanged", data.id, data.value)
    -- Persist setting
    pcall(function()
        exports["null-core"]:setPreference(data.id, data.value)
    end)
end)

-- ============================================================================
-- OPTIONS MENU CALLBACKS — Preferences, Blips, Walk Styles
-- ============================================================================

-- Send all options data to the UI
function SendOptionsDataToUI()
    local walkStyles = {}
    if Config and Config.walksList then
        for name, clipData in pairs(Config.walksList) do
            table.insert(walkStyles, { name = name, clipSet = clipData[1] or "" })
        end
        table.sort(walkStyles, function(a, b) return a.name < b.name end)
    end

    local currentWalk = GetResourceKvpString("preference_walk") or "Defaultmale"

    local blips = {}
    if Config and Config.Prefer and Config.Prefer.Blips then
        for i = 1, #Config.Prefer.Blips do
            local b = Config.Prefer.Blips[i]
            local enabled = MyPlayerGet(b.kvpName) == "true"
            table.insert(blips, {
                label = b.label,
                kvpName = b.kvpName,
                category = b.category,
                enabled = enabled,
            })
        end
    end

    local preferences = {}
    if Config and Config.Prefer and Config.Prefer.Preferences then
        for name, pref in pairs(Config.Prefer.Preferences) do
            local cat = pref.submenu or "root"
            table.insert(preferences, {
                id = name,
                label = pref.label,
                description = pref.description or nil,
                enabled = Config.Prefer.Enabled[name] and true or false,
                category = cat,
            })
        end

        -- Add special Affichage toggles (radar, hud, cinema) as virtual preferences
        table.insert(preferences, {
            id = "_radar",
            label = "Activer le radar",
            description = "Vous permet d'activer ou de désactiver la minimap",
            enabled = personalMenu and personalMenu.Radar or false,
            category = "ui",
        })
        table.insert(preferences, {
            id = "_hud",
            label = "Activer l'HUD",
            description = "Vous permet d'activer ou de désactiver l'HUD",
            enabled = personalMenu and personalMenu.ui or false,
            category = "ui",
        })
        table.insert(preferences, {
            id = "_cinema",
            label = "Mode cinématique",
            description = nil,
            enabled = cinemamode or false,
            category = "ui",
        })

        -- Add informations objets as root
        table.insert(preferences, {
            id = "_worldpropsinfo",
            label = "Informations objets",
            description = "Afficher les informations sur les objets du monde",
            enabled = PlayerState and PlayerState.WorldPropsInfo or false,
            category = "root",
        })
    end

    SendNUIMessage({
        action = "newInventory:setOptionsData",
        data = {
            walkStyles = walkStyles,
            currentWalk = currentWalk,
            blips = blips,
            preferences = preferences,
        }
    })
end

RegisterNUICallback('newInventory:togglePreference', function(data, cb)
    cb({})
    if not data or not data.id then return end
    local id = data.id
    local newEnabled = data.enabled

    -- Handle special virtual preferences
    if id == "_radar" then
        personalMenu.Radar = newEnabled
        DisplayRadar(newEnabled)
        Citizen.CreateThread(function()
            local savedValue = personalMenu.Radar
            while true do 
                if personalMenu.Radar ~= savedValue then
                    break
                end
                DisplayRadar(savedValue)
                Wait(100)
            end
        end)

        SendNUIMessage({ action = "newInventory:updatePreference", data = { id = id, enabled = newEnabled } })
        return
    elseif id == "_hud" then
        personalMenu.ui = newEnabled
        null.DisplayHud(newEnabled, 54) 
        SendNUIMessage({ action = "newInventory:updatePreference", data = { id = id, enabled = newEnabled } })
        return
    elseif id == "_cinema" then
        ExecuteCommand('noir')
        cinemamode = newEnabled
        SendNUIMessage({ action = "newInventory:updatePreference", data = { id = id, enabled = newEnabled } })
        return
    elseif id == "_worldpropsinfo" then
        PlayerState.WorldPropsInfo = newEnabled
        SendNUIMessage({ action = "newInventory:updatePreference", data = { id = id, enabled = newEnabled } })
        return
    end

    -- Regular Config.Prefer preference
    setPreferData(id)
    SendNUIMessage({
        action = "newInventory:updatePreference",
        data = { id = id, enabled = Config.Prefer.Enabled[id] and true or false }
    })
end)

RegisterNUICallback('newInventory:toggleBlip', function(data, cb)
    cb({})
    if not data or not data.kvpName then return end

    local newEnabled = data.enabled
    local blipDef = nil
    for i = 1, #Config.Prefer.Blips do
        if Config.Prefer.Blips[i].kvpName == data.kvpName then
            blipDef = Config.Prefer.Blips[i]
            break
        end
    end
    if not blipDef then return end

    if newEnabled then
        SetResourceKvp(blipDef.kvpName, "true")
        MyPlayerSet(blipDef.kvpName, "true")
        ESX.addAllBlipsFromCategory(blipDef.category)
    else
        MyPlayerSet(blipDef.kvpName, "false")
        SetResourceKvp(blipDef.kvpName, "false")
        ESX.removeAllBlipsFromCategory(blipDef.category)
    end

    SendNUIMessage({
        action = "newInventory:updateBlip",
        data = { kvpName = data.kvpName, enabled = newEnabled }
    })
end)

RegisterNUICallback('newInventory:setWalkStyle', function(data, cb)
    cb({})
    if not data or not data.name then return end
    if Config.walksList[data.name] then
        setNewWalkStyle(data.name)
        SendNUIMessage({
            action = "newInventory:updateWalkStyle",
            data = { name = data.name }
        })
    end
end)

RegisterNUICallback('inventory:destroyPreviewPed', function(_, cb)
    TriggerEvent("null:inventory:destroyClonePed")
    cb({})
end)

-- ============================================================================
-- EVENT BRIDGES — Lua events → React NUI updates
-- ============================================================================

-- Shortcut changes from other systems
RegisterNetEvent("ZgegFramework:changeShortCut", function(name, weapon, isNumber)
    if not NullInventory.isOpen then return end
    local id = isNumber and tonumber(name) or NullInventory._weaponBinds.string[name]
    if not id then return end
    local shortcut = weapon == "WEAPON_UNARMED"
        and { name = "none", label = "", count = 1, type = "weapon" }
        or { name = weapon, label = ESX.GetWeaponLabel(weapon), count = 1, type = "weapon" }
    SendNUIMessage({ action = "newInventory:setShortcut", data = { index = id, shortcut = shortcut } })
end)

-- Accessory changes
AddEventHandler("null:inventory:nui:setAccessory", function(accessoryType, item)
    if not NullInventory.isOpen then return end
    SendNUIMessage({ action = "newInventory:setAccessory", data = { type = accessoryType, item = item } })
end)

-- Clothes equip - DISABLED: Items should be equipped manually by dragging to slots
-- RegisterNetEvent("null:inventory:equipClothesSlot", function(clotheType, clotheData)
--     This event is no longer used - players must manually equip items from inventory
-- end)

-- Stats updates
AddEventHandler("null:inventory:nui:updateStats", function(stats)
    if not NullInventory.isOpen then return end
    SendNUIMessage({ action = "newInventory:updateStats", data = stats })
end)

-- Weight changes
AddEventHandler("inventory:left:changeWeight", function(newWeight)
    if not NullInventory.isOpen then return end
    SendNUIMessage({ action = "newInventory:setLeftWeight", data = { weight = newWeight } })
end)

AddEventHandler("inventory:left:changeMaxWeight", function(newWeight)
    if not NullInventory.isOpen then return end
    SendNUIMessage({ action = "newInventory:setMaxLeftWeight", data = { weight = newWeight } })
end)

-- Right inventory weight changes
AddEventHandler("inventory:right:changeWeight", function(newWeight)
    if not NullInventory.isOpen then return end
    SendNUIMessage({ action = "newInventory:setRightWeight", data = { weight = newWeight } })
end)

-- Right inventory refresh after deposit/withdraw
AddEventHandler("esx:refreshRightInventory", function(rightInventory)
    if not NullInventory.isOpen then return end
    if rightInventory then
        SendNUIMessage({ action = "newInventory:setRight", data = { inventory = rightInventory } })
    end
end)

-- Right inventory disable/enable
AddEventHandler("ZgegFramework:enableSecondInventory", function(data)
    if not NullInventory.isOpen then return end
    SendNUIMessage({ action = "newInventory:disableRight", data = { disable = data } })
end)

-- Notifications
RegisterNetEvent("inventory:sendMessage", function(msg, time2)
    if not NullInventory.isOpen then return end
    SendNUIMessage({ action = "newInventory:sendMessage", data = { message = { text = msg }, time = time2 or 3000 } })
end)

-- ============================================================================
-- OUTFIT SYSTEM — Create/Disassemble/Equip outfits
-- ============================================================================

RegisterNUICallback('newInventory:outfitCreate', function(data, cb)
    cb({})
    if not data or not data.pieces then return end
    
    -- Ask for outfit name
    local outfitName = null.fct.input("Nom de la tenue", GetCurrentResourceName())
    if not outfitName or outfitName == "" then
        TriggerEvent("inventory:sendMessage", "~r~Nom de tenue requis")
        return
    end
    
    -- Remember piece IDs so we can find the new outfit after refresh
    local pieceIds = {}
    for _, clotheId in pairs(data.pieces) do
        pieceIds[tostring(clotheId)] = true
    end
    
    ESX.TriggerServerCallback('null:outfits:create', function(success)
        if success then
            -- Clear cache and refresh inventory to load the new outfit
            NullInventory.clothesCache = nil
            NullInventory.clothesCacheTime = 0
            Wait(300)
            NullInventory.Update()
            
            -- Wait a bit for inventory to refresh, then move outfit to result slot
            Wait(100)
            
            -- Find the newly created outfit and send it to the assembler result slot
            NullInventory.GetClothes(function(clothes)
                for _, clothe in pairs(clothes) do
                    if clothe.type == "outfit" and clothe.name == outfitName then
                        SendNUIMessage({
                            action = "newInventory:outfitAssembleResult",
                            data = {
                                item = {
                                    type = "accessory",
                                    type2 = "outfit",
                                    count = 1,
                                    name = clothe.id,
                                    label = clothe.label or clothe.name or outfitName,
                                }
                            }
                        })
                        break
                    end
                end
            end)
            
            TriggerEvent("inventory:sendMessage", "~g~Tenue créée: " .. outfitName)
        end
    end, data.pieces, outfitName)
end)

RegisterNUICallback('newInventory:outfitDisassemble', function(data, cb)
    cb({})
    if not data or not data.outfitId then return end
    
    ESX.TriggerServerCallback('null:outfits:disassemble', function(success, createdPieces)
        if success then
            -- Clear cache and refresh inventory to load the new pieces
            NullInventory.clothesCache = nil
            NullInventory.clothesCacheTime = 0
            Wait(300)
            NullInventory.Update()
            
            -- Wait a bit for inventory to refresh, then move pieces to assembler slots
            Wait(100)
            
            -- Use the exact pieces returned by the server to populate assembler slots
            if createdPieces and #createdPieces > 0 then
                local assemblerSlots = {}
                for _, piece in ipairs(createdPieces) do
                    assemblerSlots[piece.type] = {
                        type = "accessory",
                        type2 = piece.type,
                        count = 1,
                        name = piece.id,
                        label = piece.label or piece.name,
                        slot = piece.slot,
                    }
                end
                
                SendNUIMessage({
                    action = "newInventory:outfitDisassembleResult",
                    data = { slots = assemblerSlots }
                })
            end
            
            TriggerEvent("inventory:sendMessage", "~g~Tenue désassemblée")
        end
    end, data.outfitId)
end)

RegisterNUICallback('newInventory:outfitEquip', function(data, cb)
    cb({})
    if not data or not data.outfitId then return end
    
    ESX.TriggerServerCallback('null:outfits:equip', function(success, skinChanges, newEquipped)
        if success and skinChanges then
            -- Apply skin changes
            for propName, propValue in pairs(skinChanges) do
                if type(propName) == "string" and type(propValue) == "number" then
                    TriggerEvent("Null:skinchanger:change", propName, propValue)
                end
            end
            
            -- Update local equipped data
            if newEquipped then
                NullInventory.equippedClothes = newEquipped
                -- Update accessory slots in UI
                for clotheType, clotheData in pairs(newEquipped) do
                    if clotheData then
                        SendNUIMessage({
                            action = "newInventory:setAccessory",
                            data = {
                                type = clotheType,
                                item = {
                                    type = "accessory",
                                    type2 = clotheType,
                                    count = 1,
                                    name = clotheData.name or clotheData.id,
                                    data = clotheData.data,
                                    label = clotheData.label,
                                }
                            }
                        })
                    end
                end
                -- Save to server
                TriggerServerEvent("null:inventory:saveEquippedClothes", newEquipped)
            end
            
            NullInventory.Update()
        end
    end, data.outfitId)
end)

function SendOutfitDataToUI()
    NullInventory.GetClothes(function(clothes)
        local clothesByType = {}
        
        for _, clothe in pairs(clothes) do
            if clothe.type ~= "outfit" then
                if not clothesByType[clothe.type] then
                    clothesByType[clothe.type] = {}
                end
                table.insert(clothesByType[clothe.type], {
                    id = clothe.id,
                    name = clothe.name,
                    label = clothe.label or clothe.name,
                    type = clothe.type,
                    data = clothe.clothe,
                })
            end
        end
        
        SendNUIMessage({
            action = "newInventory:setOutfitData",
            data = {
                clothesByType = clothesByType,
            }
        })
    end)
end

-- ============================================================================
-- BACKPACK SYSTEM — Open/Close/Transfer items in equipped bag
-- ============================================================================

local currentBackpackId = nil
_G.BackpackWeightCache = _G.BackpackWeightCache or {}

function SendBackpackDataToUI()
    TriggerEvent("Null:skinchanger:getSkin", function(skin)
        local currentBagValue = skin.bags_1 or 0
        local currentBagTexture = skin.bags_2 or 0

        -- If no bag equipped (naked value)
        if currentBagValue == 0 then
            _G.BackpackWeightCache = {}
            currentBackpackId = nil
            SendNUIMessage({
                action = "newInventory:setBackpackData",
                data = { hasBag = false }
            })
            return
        end
        
        -- Find the bag in vbackpacks that matches current skin
        ESX.TriggerServerCallback('null:backpack:getAllBags', function(bags)
            local equippedBag = nil
            for _, bag in ipairs(bags) do
                if bag.bagValue == currentBagValue and bag.bagTexture == currentBagTexture then
                    equippedBag = bag
                    break
                end
            end
            
            if not equippedBag then
                _G.BackpackWeightCache = {}
                currentBackpackId = nil
                SendNUIMessage({
                    action = "newInventory:setBackpackData",
                    data = { hasBag = false }
                })
                return
            end
            
            ESX.TriggerServerCallback('null:backpack:load', function(success, items, weight, maxWeight)
                if success then
                    currentBackpackId = equippedBag.clotheId
                    _G.BackpackWeightCache[tostring(equippedBag.clotheId)] = weight or 0
                    SendNUIMessage({
                        action = "newInventory:setBackpackData",
                        data = {
                            hasBag = true,
                            bagId = equippedBag.clotheId,
                            bagName = equippedBag.label,
                            items = items or {},
                            weight = weight or 0,
                            maxWeight = maxWeight or 15,
                        }
                    })
                else
                    _G.BackpackWeightCache[tostring(equippedBag.clotheId)] = nil
                    currentBackpackId = nil
                    SendNUIMessage({
                        action = "newInventory:setBackpackData",
                        data = { hasBag = false }
                    })
                end
            end, equippedBag.clotheId)
        end)
    end)
end

-- Track if bag is opened as second inventory
local bagOpenedAsStorage = false

-- Function to refresh bag opened as second inventory
local function RefreshBagStorage()
    if bagOpenedAsStorage and currentBackpackId then
        ESX.TriggerServerCallback('null:backpack:load', function(success, items, weight, maxWeight)
            if success then
                SendNUIMessage({ action = "newInventory:setRightWeight", data = { weight = weight or 0 } })
                SendNUIMessage({ action = "newInventory:setRight", data = { inventory = items or {} } })
            end
        end, currentBackpackId)
    end
end

RegisterNUICallback('newInventory:backpackAddItem', function(data, cb)
    cb({})
    if not data or not data.itemName then
        return
    end
    
    if not currentBackpackId then
        return
    end
    
    ESX.TriggerServerCallback('null:backpack:addItem', function(success, weight, maxWeight)
        if success then
            NullInventory.Update()
            SendBackpackDataToUI()
            RefreshBagStorage()
        else
            SendNUIMessage({
                action = "newInventory:sendMessage",
                data = { text = "Impossible d'ajouter l'item au sac (poids max atteint ou sac plein)" }
            })
        end
    end, currentBackpackId, data.itemName, data.count or 1, data.extra)
end)

RegisterNUICallback('newInventory:backpackRemoveItem', function(data, cb)
    cb({})

    if not data or not data.itemName then
        return
    end
    
    if not currentBackpackId then
        return
    end
    
    ESX.TriggerServerCallback('null:backpack:removeItem', function(success, weight, maxWeight)
        if success then
            NullInventory.Update()
            SendBackpackDataToUI()
            RefreshBagStorage()
        else
            SendNUIMessage({
                action = "newInventory:sendMessage",
                data = { text = "Impossible de retirer l'item du sac" }
            })
        end
    end, currentBackpackId, data.itemName, data.count or 1, data.extra)
end)

RegisterNUICallback('newInventory:backpackAddWeapon', function(data, cb)
    cb({})
    if not data or not data.weaponName or not currentBackpackId then return end
    
    ESX.TriggerServerCallback('null:backpack:addWeapon', function(success)
        if success then
            NullInventory.Update()
            SendBackpackDataToUI()
            RefreshBagStorage()
        else
            SendNUIMessage({
                action = "newInventory:sendMessage",
                data = { text = "Impossible d'ajouter l'arme au sac (sac plein ou armes non autorisées)" }
            })
        end
    end, currentBackpackId, data.weaponName)
end)

RegisterNUICallback('newInventory:backpackRemoveWeapon', function(data, cb)
    cb({})
    if not data or not data.weaponName or not currentBackpackId then return end
    
    ESX.TriggerServerCallback('null:backpack:removeWeapon', function(success)
        if success then
            NullInventory.Update()
            SendBackpackDataToUI()
            RefreshBagStorage()
        else
            SendNUIMessage({
                action = "newInventory:sendMessage",
                data = { text = "Impossible de retirer l'arme du sac" }
            })
        end
    end, currentBackpackId, data.weaponName)
end)

RegisterNUICallback('newInventory:backpackTransferMoney', function(data, cb)
    cb({})
    if not data or not data.moneyType or not data.amount or not currentBackpackId then return end
    
    ESX.TriggerServerCallback('null:backpack:transferMoney', function(success)
        if success then
            NullInventory.Update()
            SendBackpackDataToUI()
        else
            SendNUIMessage({
                action = "newInventory:sendMessage",
                data = { text = "Impossible de transférer l'argent" }
            })
        end
    end, currentBackpackId, data.moneyType, data.amount, data.toBackpack)
end)

RegisterNUICallback('newInventory:backpackPreview', function(data, cb)
    if not data or not data.clotheId then return cb({}) end
    
    ESX.TriggerServerCallback('null:backpack:preview', function(success, preview)
        cb({ success = success, preview = preview })
    end, data.clotheId)
end)

-- Open a bag from inventory as second inventory
RegisterNUICallback('newInventory:openBagAsStorage', function(data, cb)
    cb({})
    if not data or not data.clotheId then return end
    
    ESX.TriggerServerCallback('null:backpack:load', function(success, items, weight, maxWeight)
        if success then
            currentBackpackId = data.clotheId
            bagOpenedAsStorage = true
            -- Open as right panel
            SendNUIMessage({ action = "newInventory:setRightTitle", data = { title = data.bagName or "Sac" } })
            SendNUIMessage({ action = "newInventory:setMaxRightWeight", data = { weight = maxWeight or 15 } })
            SendNUIMessage({ action = "newInventory:setRightWeight", data = { weight = weight or 0 } })
            SendNUIMessage({ action = "newInventory:setRight", data = { inventory = items or {} } })
            SendNUIMessage({ action = "newInventory:setBagMode", data = { enabled = true, clotheId = data.clotheId } })
        end
    end, data.clotheId)
end)

RegisterNUICallback('newInventory:closeBagStorage', function(_, cb)
    cb({})
    currentBackpackId = nil
    bagOpenedAsStorage = false
    SendNUIMessage({ action = "newInventory:setBagMode", data = { enabled = false } })
    SendNUIMessage({ action = "newInventory:disableRight", data = { disable = true } })
    NullInventory.Update()
    SendBackpackDataToUI()
end)

-- ============================================================================
-- ADVANCED CRAFTING — Table-based crafting with 3D interactions
-- ============================================================================

local currentCraftTableId = nil

function SendAdvancedCraftDataToUI(tableId)
    if tableId then
        ESX.TriggerServerCallback('null:crafting:getRecipes', function(recipes)
            SendNUIMessage({
                action = "newInventory:setCraftRecipes",
                data = {
                    recipes = recipes or {},
                    tableId = tableId,
                    tableBased = true,
                }
            })
        end, tableId)
    else
        -- Merge basic recipes with existing illegal weapon craft
        local allRecipes = {}
        
        -- Get basic recipes from server
        ESX.TriggerServerCallback('null:crafting:getRecipes', function(basicRecipes)
            for _, r in ipairs(basicRecipes or {}) do
                table.insert(allRecipes, r)
            end
            
            -- -- Also add existing illegal weapon craft recipes
            -- pcall(function()
            --     if not null or not null.data or not null.data.illegals or not null.data.illegals.groups
            --         or not null.data.illegals.groups.list then return end

            --     local job2 = ESX.PlayerData.job2
            --     if not job2 or not job2.name then return end

            --     local gangData = null.data.illegals.groups.list[job2.name]
            --     if not gangData then return end

            --     local hasFabArme = (gangData.FabArme == 1 or gangData.FabArme == true)
            --     if not hasFabArme then return end

            --     local hasPerm = gangData.perms_fabrication and gangData.perms_fabrication[tostring(job2.grade)]
            --     if not hasPerm then return end

            --     if not Config or not Config.IllegalGroups or not Config.IllegalGroups.Craft
            --         or not Config.IllegalGroups.Craft.Weapons then return end

            --     local xPlayer = ESX.GetPlayerData()
            --     local leverCount, plancheCount, acierCount = 0, 0, 0

            --     if xPlayer and xPlayer.inventory then
            --         for _, item in pairs(xPlayer.inventory) do
            --             if item.name == "levier" then leverCount = item.count or 0 end
            --             if item.name == "planche" then plancheCount = item.count or 0 end
            --             if item.name == "acierpur" then acierCount = item.count or 0 end
            --         end
            --     end

            --     for weaponName, wData in pairs(Config.IllegalGroups.Craft.Weapons) do
            --         local reqs = {}
            --         if wData.fablevier and wData.fablevier > 0 then
            --             table.insert(reqs, { label = "Levier", itemName = "levier", icon = "nui://null-core/images/items/levier.webp", amount = wData.fablevier, have = leverCount })
            --         end
            --         if wData.fabplanche and wData.fabplanche > 0 then
            --             table.insert(reqs, { label = "Planche", itemName = "planche", icon = "nui://null-core/images/items/planche.webp", amount = wData.fabplanche, have = plancheCount })
            --         end
            --         if wData.fabacier and wData.fabacier > 0 then
            --             table.insert(reqs, { label = "Acier Pur", itemName = "acierpur", icon = "nui://null-core/images/items/acierpur.webp", amount = wData.fabacier, have = acierCount })
            --         end
            --         table.insert(allRecipes, {
            --             id = weaponName, item = weaponName, label = wData.label,
            --             description = "Fabriquer " .. wData.label,
            --             icon = "nui://null-core/images/items/" .. weaponName .. ".webp",
            --             time = 10, type = "weapon", category = "armes",
            --             requirements = reqs, isLegacyWeaponCraft = true,
            --         })
            --     end
            -- end)
            
            SendNUIMessage({
                action = "newInventory:setCraftRecipes",
                data = {
                    recipes = allRecipes,
                    tableBased = false,
                }
            })
        end, nil)
    end
end

RegisterNUICallback('newInventory:advancedCraft', function(data, cb)
    cb({})
    if not data or not data.recipeId then return end
    
    -- Check if this is a legacy weapon craft
    if data.isLegacyWeaponCraft then
        -- Use existing weapon craft system
        local recipeId = data.recipeId
        if not Config or not Config.IllegalGroups or not Config.IllegalGroups.Craft
            or not Config.IllegalGroups.Craft.Weapons or not Config.IllegalGroups.Craft.Weapons[recipeId] then
            return
        end
        
        local craftData = Config.IllegalGroups.Craft.Weapons[recipeId]
        local playerPed = PlayerPedId()
        local animDict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do Wait(10) end
        TaskPlayAnim(playerPed, animDict, "machinic_loop_mechandplayer", 8.0, -8.0, -1, 1, 0, false, false, false)
        
        local craftTime = 10
        local steps = 50
        local stepTime = (craftTime * 1000) / steps
        
        SendNUIMessage({ action = "newInventory:setCraftProgress", data = { recipeId = recipeId, progress = 0, done = false } })
        
        Citizen.CreateThread(function()
            for i = 1, steps do
                Wait(math.floor(stepTime))
                SendNUIMessage({ action = "newInventory:setCraftProgress", data = { recipeId = recipeId, progress = (i / steps) * 100, done = false } })
            end
            ClearPedTasks(playerPed)
            TriggerServerEvent('Gangsbuilder:FabWeapon', recipeId, craftData.label)
            SendNUIMessage({ action = "newInventory:setCraftProgress", data = { recipeId = recipeId, progress = 100, done = true } })
            Wait(1000)
            SendAdvancedCraftDataToUI(currentCraftTableId)
        end)
        return
    end
    
    -- New crafting system
    local tableId = data.tableId or currentCraftTableId
    
    -- Play animation
    local playerPed = PlayerPedId()
    local anim = Config.Crafting and Config.Crafting.Animation or { dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", anim = "machinic_loop_mechandplayer", flag = 1 }
    RequestAnimDict(anim.dict)
    while not HasAnimDictLoaded(anim.dict) do Wait(10) end
    TaskPlayAnim(playerPed, anim.dict, anim.anim, 8.0, -8.0, -1, anim.flag or 1, 0, false, false, false)
    
    local craftTime = data.time or 10
    local steps = 50
    local stepTime = (craftTime * 1000) / steps
    
    SendNUIMessage({ action = "newInventory:setCraftProgress", data = { recipeId = data.recipeId, progress = 0, done = false } })
    
    Citizen.CreateThread(function()
        for i = 1, steps do
            Wait(math.floor(stepTime))
            SendNUIMessage({ action = "newInventory:setCraftProgress", data = { recipeId = data.recipeId, progress = (i / steps) * 100, done = false } })
        end
        ClearPedTasks(playerPed)
        
        ESX.TriggerServerCallback('null:crafting:craft', function(success)
            SendNUIMessage({ action = "newInventory:setCraftProgress", data = { recipeId = data.recipeId, progress = 100, done = true } })
            Wait(1000)
            SendAdvancedCraftDataToUI(tableId)
            NullInventory.Update()
        end, data.recipeId, tableId)
    end)
end)

-- 3D Interaction setup for craft tables
Citizen.CreateThread(function()
    while not Config.Crafting do Wait(100) end
    
    for _, craftTable in ipairs(Config.Crafting.Tables or {}) do
        local tableData = craftTable
        
        local interactionConfig = {
            id = "craft_table_" .. tableData.id,
            coords = tableData.coords,
            text = tableData.label or "Table de craft",
            Action = function()
                currentCraftTableId = tableData.id
                NullInventory.Open()
                Wait(500)
                SendAdvancedCraftDataToUI(tableData.id)
            end,
            maxDistance = Config.Crafting.MaxDistance or 3.0,
            key = "E",
        }
        
        if tableData.blip and tableData.blip.enabled then
            interactionConfig.blip = {
                name = tableData.blip.name or tableData.label,
                sprite = tableData.blip.sprite or 566,
                color = tableData.blip.color or 1,
                scale = tableData.blip.scale or 0.7,
                display = tableData.blip.display or 4,
            }
        end
        
        -- Check conditions before adding interaction
        if tableData.conditions then
            local origAction = interactionConfig.Action
            interactionConfig.Action = function()
                local xPlayer = ESX.GetPlayerData()
                if tableData.conditions.job and xPlayer.job and xPlayer.job.name ~= tableData.conditions.job then
                    ESX.ShowNotification("~r~Vous n'avez pas accès à cette table de craft")
                    return
                end
                if tableData.conditions.job2 and xPlayer.job2 and xPlayer.job2.name ~= tableData.conditions.job2 then
                    ESX.ShowNotification("~r~Vous n'avez pas accès à cette table de craft")
                    return
                end
                origAction()
            end
        end
        
        Add3DInteraction(interactionConfig)
    end
end)

-- ============================================================================
-- ADMIN TABS — All Items (founder) & Staff Chest
-- ============================================================================

-- Fetch all items list (founder only)
RegisterNUICallback('newInventory:fetchAllItems', function(_, cb)
    ESX.TriggerServerCallback('newInventory:getAllItems', function(response)
        if type(response) == "table" and response.success ~= nil then
            cb({
                success = response.success == true,
                items = response.items or {},
                reason = response.reason,
            })
        elseif type(response) == "table" then
            cb({ success = true, items = response })
        else
            cb({ success = false, items = {}, reason = "empty_response" })
        end
    end)
end)

-- Take item from all-items infinite list
RegisterNUICallback('newInventory:allItemsTake', function(data, cb)
    if not data or not data.itemName or not data.itemType then return cb({ success = false }) end
    ESX.TriggerServerCallback('newInventory:allItemsTake', function(success)
        if success then
            NullInventory.Update()
        end
        cb({ success = success })
    end, data.itemName, data.itemType, data.count or 1)
end)

-- Deposit (destroy) item via all-items
RegisterNUICallback('newInventory:allItemsDeposit', function(data, cb)
    if not data or not data.itemName or not data.itemType then return cb({ success = false }) end
    ESX.TriggerServerCallback('newInventory:allItemsDeposit', function(success)
        if success then
            NullInventory.Update()
        end
        cb({ success = success })
    end, data.itemName, data.itemType, data.count or 1)
end)

-- Fetch staff chest
RegisterNUICallback('newInventory:fetchStaffChest', function(_, cb)
    ESX.TriggerServerCallback('null:getCoffre', function(data, id, weight)
        if data then
            -- Format items for the new inventory UI
            local items = {}
            if data.items then
                for _, item in pairs(data.items) do
                    if item.count and item.count > 0 then
                        table.insert(items, {
                            type = 'item',
                            name = item.name,
                            label = item.label or ESX.GetItemLabel(item.name) or item.name,
                            count = item.count,
                            weight = item.weight or 1,
                        })
                    end
                end
            end
            if data.loadout then
                for _, w in pairs(data.loadout) do
                    table.insert(items, {
                        type = 'weapon',
                        name = w.name,
                        label = w.label or ESX.GetWeaponLabel(w.name) or w.name,
                        count = 1,
                    })
                end
            end
            -- Money
            if data.cash and data.cash > 0 then
                table.insert(items, { type = 'account', name = 'money', label = 'Argent propre', count = data.cash })
            end
            if data.dirtycash and data.dirtycash > 0 then
                table.insert(items, { type = 'account', name = 'dirtycash', label = 'Argent sale', count = data.dirtycash })
            end
            cb({ success = true, items = items, weight = weight or 0 })
        else
            cb({ success = false })
        end
    end, "staffchest")
end)

-- Transfer item to staff chest
RegisterNUICallback('newInventory:staffChestDeposit', function(data, cb)
    if not data or not data.itemName or not data.itemType then return cb({ success = false }) end
    
    if data.itemType == 'weapon' then
        ESX.TriggerServerCallback('null:inv:transfertWeaponToStorage', function(success)
            if success then NullInventory.Update() end
            cb({ success = success })
        end, "staffchest", data.itemName, "SOCIETY", data.metadata)
    elseif data.itemType == 'account' then
        ESX.TriggerServerCallback('null:inv:transfertCashToStorage', function(success)
            if success then NullInventory.Update() end
            cb({ success = success })
        end, "staffchest", data.count or 1, data.itemName, "SOCIETY")
    else
        ESX.TriggerServerCallback('null:inv:transfertItemToStorage', function(success)
            if success then NullInventory.Update() end
            cb({ success = success })
        end, "staffchest", data.itemName, data.count or 1, "SOCIETY", nil, data.extra)
    end
end)

-- Take item from staff chest
RegisterNUICallback('newInventory:staffChestWithdraw', function(data, cb)
    if not data or not data.itemName or not data.itemType then return cb({ success = false }) end
    
    if data.itemType == 'weapon' then
        ESX.TriggerServerCallback('null:inv:transferStorageToWeapon', function(success)
            if success then NullInventory.Update() end
            cb({ success = success })
        end, "staffchest", data.itemName, "SOCIETY", data.metadata)
    elseif data.itemType == 'account' then
        ESX.TriggerServerCallback('null:inv:transfertStorageToCash', function(success)
            if success then NullInventory.Update() end
            cb({ success = success })
        end, "staffchest", data.count or 1, data.itemName, "SOCIETY")
    else
        ESX.TriggerServerCallback('null:inv:transfertStorageToItem', function(success)
            if success then NullInventory.Update() end
            cb({ success = success })
        end, "staffchest", data.itemName, data.count or 1, "SOCIETY", data.extra)
    end
end)

-- ============================================================================
-- EXTERNAL API — Allow other scripts to open inventory on a craft table
-- ============================================================================

function OpenCraftTable(tableId)
    currentCraftTableId = tableId
    NullInventory.Open()
    Wait(500)
    SendAdvancedCraftDataToUI(tableId)
end

_G.OpenCraftTable = OpenCraftTable

null.InitPrint("New Inventory NUI Bridge loaded")
