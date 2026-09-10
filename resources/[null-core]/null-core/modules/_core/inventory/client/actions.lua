while not _G.NullInventoryUILoaded do
    Wait(0)
end

local actionCooldown = false
local COOLDOWN_DURATION = 500 -- ms

local function SetCooldown()
    actionCooldown = true
    SetTimeout(COOLDOWN_DURATION, function()
        actionCooldown = false
    end)
end

local function IsCooldown()
    return actionCooldown
end


function UseItem(itemName, count)
    if IsCooldown() then return end
    SetCooldown()
    
    TriggerServerEvent('esx:useItem', itemName)
    
    Wait(300)
    TriggerEvent("null:inventory:update")
end

function GiveItem(targetId, itemName, count)
    if IsCooldown() then return end
    SetCooldown()
    
    TriggerServerEvent('esx:giveInventoryItem', targetId, 'item_standard', itemName, count)
    
    Wait(300)
    TriggerEvent("null:inventory:update")
end

function DropItem(itemName, count)
    if IsCooldown() then return end
    
    
    SetCooldown()
    TriggerServerEvent('esx:dropInventoryItem', 'item_standard', itemName, count)
    
    
    Wait(300)
    TriggerEvent("null:inventory:update")
end

function FindNearestTrashBin(position, maxDistance)
    for _, binName in ipairs(Config.Inventory.TrashBins) do
        local binHash = GetHashKey(binName)
        local bin = GetClosestObjectOfType(position.x, position.y, position.z, maxDistance, binHash, false, false, false)
        
        if bin and bin ~= 0 then
            return true
        end
    end
    return false
end

function GiveWeapon(targetId, weaponName)
    if IsCooldown() then return end
    SetCooldown()
    
    TriggerServerEvent('esx:giveInventoryItem', targetId, 'item_weapon', weaponName, 1)
    
    Wait(300)
    TriggerEvent("null:inventory:update")
end

function DropWeapon(weaponName)
    if IsCooldown() then return end
    
    
    SetCooldown()
    TriggerServerEvent('esx:dropInventoryItem', 'item_weapon', weaponName, 1)
    
    
    Wait(300)
    TriggerEvent("null:inventory:update")
end

function EquipAccessory(accessoryType, accessoryData, doLoading)
    if doLoading == nil then doLoading = true end
    if IsCooldown() and doLoading then 
        return 
    end 
    if doLoading then 
        SetCooldown()
        SendNUIMessage({ action = "newInventory:setLoading", data = { loading = true } })
    end
    
    
    if accessoryData.data and type(accessoryData.data) == "table" then
        for propName, propValue in pairs(accessoryData.data) do
            if type(propName) == "string" and type(propValue) == "number" then
                TriggerEvent("Null:skinchanger:change", propName, propValue)
            end
        end
    end
    
    NullInventory.equippedClothes[accessoryType] = {
        id = accessoryData.name,
        name = accessoryData.name,
        data = accessoryData.data,
        label = accessoryData.label,
    }

    TriggerServerEvent("ZgegFramework:equipedClothes", NullInventory.equippedClothes)

    TriggerEvent("Null:skinchanger:getSkin", function(skin)
        TriggerServerEvent("Null:esx_skin:save", skin)
    end)
    
    TriggerEvent("null:inventory:nui:setAccessory", accessoryType, accessoryData)
    
    -- Refresh backpack tab if equipping a bag
    if accessoryType == "bag" and _G.SendBackpackDataToUI then
        _G.SendBackpackDataToUI()
    end

    if doLoading then 
        Wait(100)
        RefreshInventoryPed()
        SendNUIMessage({ action = "newInventory:setLoading", data = { loading = false } })
    end
end

function RemoveAccessory(accessoryType, doLoading)
    if doLoading == nil then doLoading = true end
    if IsCooldown() and doLoading then 
        return 
    end

    if doLoading then
        SetCooldown()
        SendNUIMessage({ action = "newInventory:setLoading", data = { loading = true } })
    end

    NullInventory.equippedClothes[accessoryType] = nil

    TriggerServerEvent("ZgegFramework:equipedClothes", NullInventory.equippedClothes)

    TriggerEvent("null:inventory:nui:setAccessory", accessoryType, { name = "none" })

    local keyMapping = {
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
    
    local configKey = keyMapping[accessoryType] or accessoryType

    local defaultSkin = NullInventory.IsMale()
        and Config.Inventory.DefaultSkin.male[configKey]
        or Config.Inventory.DefaultSkin.female[configKey]
    
    if defaultSkin then
        for propName, propValue in pairs(defaultSkin) do
            TriggerEvent("Null:skinchanger:change", propName, propValue)
        end
    end
    
    TriggerEvent("Null:skinchanger:getSkin", function(skin)
        TriggerServerEvent("Null:esx_skin:save", skin)
    end)
    
    -- Refresh backpack tab if removing a bag
    if accessoryType == "bag" and _G.SendBackpackDataToUI then
        _G.SendBackpackDataToUI()
    end
    
    if doLoading then
        Wait(100)
        RefreshInventoryPed()
        SendNUIMessage({ action = "newInventory:setLoading", data = { loading = false } })
    end
end

function DeleteAccessory(accessoryType, accessoryId)
    if IsCooldown() then return end
    SetCooldown()
    
    TriggerServerEvent("esx:clothes:delete", accessoryId)
    RemoveAccessory(accessoryType)
end

function PlayAccessoryAnimation(anim)
    ESX.Streaming.RequestAnimDict(anim.dict, function()
        TaskPlayAnim(PlayerPedId(), anim.dict, anim.anim, 8.0, -8.0, anim.duration, anim.flag, 0, false, false, false)
    end)
end

function RenameItem(itemData, newName)
    if not newName or newName == "" then 
        print("[INVENTORY ERROR CLIENT] newName is empty or nil")
        return 
    end
    
    if itemData.type == "item" then
        TriggerServerEvent("inventory:renameItem", itemData, newName)
    elseif itemData.type == "weapon" then
        TriggerServerEvent("inventory:renameWeapon", itemData.name, newName)
    elseif itemData.type == "accessory" then
        TriggerServerEvent("ZgegFramework:clothes:rename", newName, itemData.name)
    end
    
    Wait(300)
    TriggerEvent("null:inventory:update")
end

local lastDepositData = nil
local lastWithdrawData = nil

AddEventHandler("esx:inventory:deposit", function(data)
    if IsCooldown() then return end
    
    if lastDepositData and lastDepositData == data then return end
    lastDepositData = data
    
    if not NullInventory.currentChest then return end
    if NullInventory.currentChest.data.isSearch then return end
    
    local itemWeight = 1
    for _, item in ipairs(ESX.PlayerData.inventory or {}) do
        if item.name == data.item.name then
            itemWeight = item.weight or 1
            break
        end
    end
    
    local chest = NullInventory.currentChest
    if chest.maxWeight > 0 and chest.weight + (itemWeight * data.count) > chest.maxWeight then
        TriggerEvent("inventory:sendMessage", "~r~Plus de place dans le coffre")
        return
    end
    
    SetCooldown()
    
    if chest.data.type == "GROUND" then
        local itemType = data.item.type == "item" and "item" or (data.item.type == "weapon" and "weapon" or data.item.type)
        TriggerServerEvent('null:groundItems:deposit', chest.data.id, itemType, data.item.name, data.count, data.item.metadata)
        Wait(500)
        RefreshChest()
        TriggerEvent("inventory:left:changeWeight", ESX.GetCurrentWeight())
        return
    end
    
    local cacheKey = chest.cacheKey
    
    if data.item.type == "item" then
        ESX.TriggerServerCallback('null:inventory:depositItem', function(success)
            if success then RefreshChest() end
        end, cacheKey, data.item.name, data.count, data.item.extra)
        
    elseif data.item.type == "accessory" then
        if data.item.type2 == "bag" then
            -- Bags use dedicated deposit handler (they live in vbackpacks, not ESX inventory)
            ESX.TriggerServerCallback('null:backpack:depositToStorage', function(success, errMsg)
                if success then
                    RefreshChest()
                else
                    TriggerEvent("inventory:sendMessage", "~r~" .. (errMsg or "Erreur"))
                end
            end, cacheKey, data.item.name)
        else
            -- Regular accessories
            local itemExtra = data.item.extra or {}
            ESX.TriggerServerCallback('null:inventory:depositItem', function(success)
                if success then RefreshChest() end
            end, cacheKey, data.item.name, 1, itemExtra)
        end
        
    elseif data.item.type == "weapon" then
        ESX.TriggerServerCallback('null:inventory:depositWeapon', function(success)
            if success then RefreshChest() end
        end, cacheKey, data.item.name, data.item.metadata)
        
    elseif data.item.type == "cash" or data.item.type == "dirtycash" then
        ESX.TriggerServerCallback('null:inventory:depositMoney', function(success)
            if success then RefreshChest() end
        end, cacheKey, data.count, data.item.type)
    end
    
    Wait(1)
    TriggerEvent("inventory:left:changeWeight", ESX.GetCurrentWeight())
end)

AddEventHandler("esx:inventory:withdraw", function(data)
    if IsCooldown() then return end
    
    if lastWithdrawData and lastWithdrawData == data then return end
    lastWithdrawData = data
    
    if not NullInventory.currentChest then return end
    
    if ESX.GetCurrentWeight() >= ESX.GetMaxWeight() then
        TriggerEvent("inventory:sendMessage", "~r~Vous n'avez plus de place sur vous")
        return
    end
    
    if NullInventory.currentChest.data.isSearch then
        if not NullInventory.currentChest.data.canMove then return end
        
        if data.item.type == "item" then
            TriggerServerEvent("police:confiscate", NullInventory.currentChest.data.identifier, "item_standard", data.item.name, data.count, data.item.id, data.item.metadata)
        elseif data.item.type == "weapon" then
            TriggerServerEvent("police:confiscate", NullInventory.currentChest.data.identifier, "item_weapon", data.item.name, 1, data.item.id)
        elseif data.item.type == "dirtycash" then
            TriggerServerEvent("police:confiscate", NullInventory.currentChest.data.identifier, "item_account", "dirtycash", data.count)
        end
        return
    end
    
    SetCooldown()
    
    -- Check if it's a ground item
    if NullInventory.currentChest.data.type == "GROUND" then
        local itemType = data.item.type == "item" and "item" or (data.item.type == "weapon" and "weapon" or data.item.type)
        TriggerServerEvent('null:groundItems:withdraw', NullInventory.currentChest.data.id, itemType, data.item.name, data.count)
        Wait(500)
        RefreshChest()
        TriggerEvent("inventory:left:changeWeight", ESX.GetCurrentWeight())
        return
    end
    
    local cacheKey = NullInventory.currentChest.cacheKey
    
    if data.item.type == "item" then
        ESX.TriggerServerCallback('null:inventory:withdrawItem', function(success)
            if success then RefreshChest() end
        end, cacheKey, data.item.name, data.count, data.item.extra)
        
    elseif data.item.type == "accessory" then
        if data.item.type2 == "bag" and data.item.metadata and data.item.metadata.clotheId then
            -- Bags use dedicated withdraw handler (re-creates vbackpacks entry)
            ESX.TriggerServerCallback('null:backpack:withdrawFromStorage', function(success, errMsg)
                if success then
                    RefreshChest()
                else
                    TriggerEvent("inventory:sendMessage", "~r~" .. (errMsg or "Erreur"))
                end
            end, cacheKey, data.item.name)
        else
            -- Regular accessories
            ESX.TriggerServerCallback('null:inventory:withdrawItem', function(success)
                if success then RefreshChest() end
            end, cacheKey, data.item.name, 1, data.item.extra)
        end
        
    elseif data.item.type == "weapon" then
        ESX.TriggerServerCallback('null:inventory:withdrawWeapon', function(success)
            if success then RefreshChest() end
        end, cacheKey, data.item.name)
        
    elseif data.item.type == "cash" or data.item.type == "dirtycash" then
        ESX.TriggerServerCallback('null:inventory:withdrawMoney', function(success)
            if success then RefreshChest() end
        end, cacheKey, data.count, data.item.type)
    end
    
    Wait(1)
    TriggerEvent("inventory:left:changeWeight", ESX.GetCurrentWeight())
end)

function RefreshChest()
    if not NullInventory.currentChest then return end
    
    local chest = NullInventory.currentChest
    
    if chest.cacheKey then
        local invType, id = chest.cacheKey:match("^(.+)_(.+)$")
        if not invType or not id then
            print("[ERROR] RefreshChest - Invalid cacheKey format:", chest.cacheKey)
            return
        end
        
        ESX.TriggerServerCallback('null:getCoffreForRefresh', function(data)
            if data then
                local rightInventory = FormatInventoryForUI(data)
                TriggerEvent("esx:refreshRightInventory", rightInventory)
                TriggerEvent("null:inventory:update")
                
                local weight = 0
                for _, item in pairs(data.items or {}) do
                    weight = weight + ((item.weight or 1) * (item.count or 1))
                end
                for _, weapon in pairs(data.loadout or {}) do
                    weight = weight + 5
                end
                
                NullInventory.currentChest.weight = weight
                TriggerEvent("inventory:right:changeWeight", weight)
                
                Wait(300)
                TriggerEvent("null:inventory:update")
            end
        end, id, invType)
    else
        ESX.TriggerServerCallback('null:getCoffreForRefresh', function(data)
            if data then
                local rightInventory = FormatInventoryForUI(data)
                TriggerEvent("esx:refreshRightInventory", rightInventory)
                TriggerEvent("null:inventory:update")
                
                local weight = 0
                for _, item in pairs(data.items or {}) do
                    weight = weight + ((item.weight or 1) * (item.count or 1))
                end
                for _, weapon in pairs(data.loadout or {}) do
                    weight = weight + 5
                end
                
                NullInventory.currentChest.weight = weight
                TriggerEvent("inventory:right:changeWeight", weight)
                
                Wait(300)
                TriggerEvent("null:inventory:update")
            end
        end, chest.data.id, chest.data.type)
    end
end

local selectedWeapon = nil
local rightinvOpen = false

AddEventHandler("null:inventory:nui:useItem", function(data)
    if not data.item or ESX.Table.SizeOf(data.item) == 0 then return end
    
    if data.item.type == 'item' then
        local isLicense = false
        if Config.Licenses and Config.Licenses.Listes then
            for k, _ in pairs(Config.Licenses.Listes) do 
                if k == data.item.name then
                    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                    TriggerEvent("null:inventory:closeinv")
                    if closestPlayer == -1 or closestDistance <= 2 then
                        TriggerServerEvent('Null:licenses:open', k, GetPlayerServerId(PlayerId()), data.item.metadata)
                    else
                        TriggerServerEvent('Null:licenses:open', k, GetPlayerServerId(closestPlayer), data.item.metadata)
                    end
                    isLicense = true
                    break
                end
            end
        end
        if not isLicense then
            if Config.Kevlar and Config.Kevlar.IsKevlarItem(data.item.name) then
                TriggerEvent("null:kevlar:useItem", data.item.name, data.item.extra)
            else
                UseItem(data.item.name, data.count or 1)
            end
        end
        
    elseif data.item.type == "weapon" then
        ToggleWeapon(data.item)
        
    elseif data.item.type == "accessory" then
        -- Check if it's an outfit (tenue)
        if data.item.type2 == "outfit" then
            -- Check if this outfit is already equipped (toggle behavior)
            local isOutfitEquipped = false
            if NullInventory.equippedClothes then
                for _, clotheData in pairs(NullInventory.equippedClothes) do
                    if clotheData and clotheData.id == data.item.name then
                        isOutfitEquipped = true
                        break
                    end
                end
            end
            
            if isOutfitEquipped then
                -- Outfit is already equipped, remove all pieces simultaneously
                SendNUIMessage({ action = "newInventory:setLoading", data = { loading = true } })
                
                local clothesToRemove = {}
                for clotheType, clotheData in pairs(NullInventory.equippedClothes or {}) do
                    if clotheData and clotheData.id == data.item.name then
                        table.insert(clothesToRemove, clotheType)
                    end
                end
                
                -- Remove all from equippedClothes at once
                for _, clotheType in ipairs(clothesToRemove) do
                    NullInventory.equippedClothes[clotheType] = nil
                end
                
                -- Save to server once
                TriggerServerEvent("ZgegFramework:equipedClothes", NullInventory.equippedClothes)
                
                -- Update UI for all slots
                for _, clotheType in ipairs(clothesToRemove) do
                    TriggerEvent("null:inventory:nui:setAccessory", clotheType, { name = "none" })
                end
                
                -- Apply default skin for all pieces simultaneously
                local defaultSkin = NullInventory.IsMale()
                    and Config.Inventory.DefaultSkin.male
                    or Config.Inventory.DefaultSkin.female
                
                local keyMapping = {
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
                
                for _, clotheType in ipairs(clothesToRemove) do
                    local configKey = keyMapping[clotheType] or clotheType
                    local defaultValues = defaultSkin[configKey]
                    if defaultValues then
                        for propName, propValue in pairs(defaultValues) do
                            TriggerEvent("Null:skinchanger:change", propName, propValue)
                        end
                    end
                end
                
                TriggerEvent("Null:skinchanger:getSkin", function(skin)
                    TriggerServerEvent("Null:esx_skin:save", skin)
                end)
                
                Wait(100)
                RefreshInventoryPed()
                
                SendNUIMessage({ action = "newInventory:setLoading", data = { loading = false } })
                TriggerEvent("inventory:sendMessage", "~o~Tenue retirée")
            else
                -- Equip the entire outfit
                SendNUIMessage({ action = "newInventory:setLoading", data = { loading = true } })
                
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
                            TriggerServerEvent("ZgegFramework:equipedClothes", newEquipped)
                            
                            -- Update all accessory slots in UI
                            for clotheType, clotheData in pairs(newEquipped) do
                                if clotheData then
                                    TriggerEvent("null:inventory:nui:setAccessory", clotheType, {
                                        type = "accessory",
                                        type2 = clotheType,
                                        count = 1,
                                        name = clotheData.name or clotheData.id,
                                        data = clotheData.data,
                                        label = clotheData.label,
                                    })
                                end
                            end
                            
                            TriggerEvent("inventory:sendMessage", "~g~Tenue équipée")
                        end
                        
                        Wait(100)
                        RefreshInventoryPed()
                    end
                    
                    SendNUIMessage({ action = "newInventory:setLoading", data = { loading = false } })
                end, data.item.name)
            end
        else
            -- Regular accessory
            SendNUIMessage({ action = "newInventory:setLoading", data = { loading = true } })
            EquipAccessory(data.item.type2, data.item)
            SendNUIMessage({ action = "newInventory:setLoading", data = { loading = false } })
        end
    end
     
    Wait(300)
    TriggerEvent("null:inventory:update")
end)

AddEventHandler("null:inventory:nui:giveItem", function(data)
    
    if exports["null-core"]:playerIsDead() then 
        return 
    end
  
    local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
    
    if closestPlayer == -1 or closestDistance > 3 then
        TriggerEvent("inventory:sendMessage", "Aucun joueurs aux alentours")
        return
    end
    
    if ESX.ContribItem(data.item.name) or ESX.ContribWeapon(data.item.name) or data.item.permanent then
        return
    end
    
    local Quantity = tonumber(null.fct.input("Quantité à donner ?", "null-core"))
  
    if not Quantity or Quantity <= 0 or Quantity > data.item.count then
        return
    end
    
    local targetId = GetPlayerServerId(closestPlayer)
    
    if data.item.type == "item" then
        GiveItem(targetId, data.item.name, Quantity)
    elseif data.item.type == "weapon" then
        GiveWeapon(targetId, data.item.name)
    elseif data.item.type == "accessory" then
        -- Check if it's a bag accessory
        if data.item.type2 == "bag" and data.item.clotheId then
            -- Special handling for bags - transfer ownership
            TriggerServerEvent("null:backpack:giveToPlayer", targetId, data.item.clotheId, data.item.name)
        else
            TriggerServerEvent("ZgegFramework:clothes:transfere", data.item.name, targetId)
        end
    elseif data.item.type == "cash" then
        TriggerServerEvent('esx:giveInventoryItem', targetId, 'item_account', "cash", Quantity)
    elseif data.item.type == "dirtycash" then
        TriggerServerEvent('esx:giveInventoryItem', targetId, 'item_account', "dirtycash", Quantity)
    end
    
    Wait(300)
    TriggerEvent("null:inventory:update")
end) 

AddEventHandler("null:inventory:nui:dropItem", function(data)
    if data.item.type == "accessory" then
        SetCooldown()
        
        -- If this accessory is currently equipped, unequip it first
        if data.item.type2 and data.item.type2 ~= "bag" and data.item.type2 ~= "outfit" then
            local equippedType = data.item.type2
            if NullInventory.equippedClothes and NullInventory.equippedClothes[equippedType] then
                local equipped = NullInventory.equippedClothes[equippedType]
                if equipped and tostring(equipped.id or equipped.name) == tostring(data.item.name) then
                    RemoveAccessory(equippedType, false)
                end
            end
        end
        
        if data.item.type2 == "bag" then
            -- Bags live in vbackpacks, not vclothes — use dedicated drop event
            TriggerServerEvent('null:backpack:dropBag', data.item.name)
        else
            TriggerServerEvent('esx:dropInventoryItem', 'item_accessory', data.item.name, 1, data.item.type2)
        end
        
        -- Clear clothes cache so next inventory open reloads from DB
        NullInventory.clothesCache = nil
        NullInventory.clothesCacheTime = 0
        
        Wait(300)
        TriggerEvent("null:inventory:update")
    elseif data.item.type == "item" then
        local Quantity = tonumber(data.count) or tonumber(data.item.count) or 1
        if Quantity <= 0 or Quantity > data.item.count then
            return
        end
        DropItem(data.item.name, Quantity)
    elseif data.item.type == "weapon" then
        DropWeapon(data.item.name)
    elseif data.item.type == "cash" or data.item.type == "dirtycash" then
        local Quantity = tonumber(data.count) or tonumber(data.item.count) or 1
        if Quantity <= 0 or Quantity > data.item.count then
            return
        end
        SetCooldown()
        TriggerServerEvent('esx:dropInventoryItem', 'item_account', data.item.type, Quantity)
    end
    
    Wait(300)
    TriggerEvent("null:inventory:update")
end) 

AddEventHandler("null:inventory:nui:changeSlot", function(data)

    if not rightinvOpen or not data.target then
        if data.item.type == "weapon" then
            ToggleWeapon(data.item)
            
        elseif data.item.type == "accessory" then
            EquipAccessory(data.item.type2, data.item)
            
        elseif data.item.type == "item" then
            if ESX.Table.SizeOf(data.item) == 0 then return end
            
            if Config.Licenses and Config.Licenses.Listes then
                for k, _ in pairs(Config.Licenses.Listes) do 
                    if k == data.item.name then
                        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                        TriggerEvent("null:inventory:closeinv")
                        if closestPlayer == -1 or closestDistance < 2 then
                            TriggerServerEvent('Null:licenses:open', k, GetPlayerServerId(PlayerId()), data.item.metadata)
                        else
                            TriggerServerEvent('Null:licenses:open', k, GetPlayerServerId(closestPlayer), data.item.metadata)
                        end
                        return
                    end
                end
            end
            
            if Config.Kevlar and Config.Kevlar.IsKevlarItem(data.item.name) then
                TriggerEvent("null:kevlar:useItem", data.item.name, data.item.extra)
            else
                UseItem(data.item.name, 1)
            end
        end
    else
        local count = 1 
        if data.item.count > 1 and not data.item.unique then
            --count = tonumber(null.fct.input("Quantité à déposer", "null-core"))
            count = data.item.count
            if not count then
                return
            end
        end
        
        if not count or count <= 0 or count > data.item.count then
            return
        end
        
        data.count = count
        
        if data.target == "inventoryRight" then
            TriggerEvent("esx:inventory:deposit", data)
        elseif data.target == "inventoryLeft" then
            TriggerEvent("esx:inventory:withdraw", data)
        end
    end
end)

AddEventHandler("null:inventory:nui:equipAccessory", function(data)
    if not data.item or not data.type then 
        return 
    end
    -- If skin data is missing or empty, re-fetch from DB before equipping
    local itemData = data.item
    local skinData = itemData.data
    local skinIsEmpty = (skinData == nil) or (type(skinData) == "table" and next(skinData) == nil)
    if skinIsEmpty and itemData.name then
        ESX.TriggerServerCallback('null:inv:getClotheSkin', function(freshSkin)
            if freshSkin and next(freshSkin) ~= nil then
                itemData.data = freshSkin
            end
            EquipAccessory(data.type, itemData)
        end, itemData.name)
    else
        EquipAccessory(data.type, itemData)
    end
end)

AddEventHandler("null:inventory:nui:removeAccessory", function(data)
    RemoveAccessory(data.type)
end)

AddEventHandler("esx:enableSecondInventory", function(bool)
    rightinvOpen = not bool
end)

function ToggleWeapon(weaponItem)
    if selectedWeapon then
        local _, weaponData = ESX.GetWeapon(selectedWeapon.name)
        if weaponData and weaponData.components then
            for _, v in pairs(weaponData.components) do
                RemoveWeaponComponentFromPed(PlayerPedId(), GetHashKey(selectedWeapon.name), v.hash)
            end
        end
    end
    
    if GetSelectedPedWeapon(PlayerPedId()) == GetHashKey(weaponItem.name) then
        selectedWeapon = nil
        SetCurrentPedWeapon(PlayerPedId(), "WEAPON_UNARMED", true)
    else
        selectedWeapon = weaponItem
        SetCurrentPedWeapon(PlayerPedId(), weaponItem.name, true)
    end
end

exports('getSelectedWeapon', function() return selectedWeapon end)
exports('UseItem', UseItem)
exports('GiveItem', GiveItem)
exports('DropItem', DropItem)
exports('GiveWeapon', GiveWeapon)
exports('DropWeapon', DropWeapon)
exports('EquipAccessory', EquipAccessory)
exports('RemoveAccessory', RemoveAccessory)