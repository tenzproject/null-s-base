while not Config.Inventory do
    Wait(0)
end

-- Helper function to add item descriptions from config
local function AddItemDescription(item)
    if item and item.name and Config.Items and Config.Items.GetDescription then
        local desc = Config.Items.GetDescription(item.name)
        if desc then
            item.description = desc
        end
    end
    return item
end

NullInventory = {
    isOpen = false,
    canOpen = true,
    currentChest = nil,      -- { cacheKey, type, maxWeight, weight }
    clothesCache = nil,
    clothesCacheTime = 0,
    equippedClothes = {},
    _weaponBinds = {
        numbers = { [0] = 'one', [1] = 'two', [2] = 'three', [3] = 'four', [4] = 'five' },
        string = { ['one'] = 1, ["two"] = 2, ["three"] = 3, ["four"] = 4, ["five"] = 5 },
    },
}

_G.newInventoryOpen = false

local CLOTHES_CACHE_DURATION = 30000 -- 30 secondes

NullInventory.Open = LPH_JIT(function(secondInventory)
    if NullInventory.isOpen then
        if secondInventory then
            NullInventory.currentChest = {
                cacheKey = secondInventory.cacheKey,
                type = secondInventory.type,
                maxWeight = secondInventory.maxWeight,
                weight = secondInventory.weight,
                data = secondInventory.data,
                literal = secondInventory.literal,
            }
            -- Update right panel if already open
            -- Add descriptions to right inventory items
            local rightData = secondInventory.inventory or {}
            for i, item in ipairs(rightData) do
                rightData[i] = AddItemDescription(item)
            end
            
            SendNUIMessage({ action = "newInventory:setRightTitle", data = { title = secondInventory.title or "Coffre" } })
            SendNUIMessage({ action = "newInventory:setMaxRightWeight", data = { weight = secondInventory.maxWeight or 1000 } })
            SendNUIMessage({ action = "newInventory:setRightWeight", data = { weight = secondInventory.weight or 0 } })
            SendNUIMessage({ action = "newInventory:setRight", data = { inventory = rightData } })
            TriggerEvent("esx:enableSecondInventory", false)
        end
        return
    end
    if not NullInventory.canOpen then return end
    
    NullInventory.isOpen = true
    _G.newInventoryOpen = true
    exports["null-core"]:setChatCanOpen(false)
    SetNuiFocus(true, true)
    DisplayRadar(false)
    null.ActiveFrontend(false)

    Citizen.CreateThread(function()
        local targetPitch = 0.0
        local currentPitch = GetGameplayCamRelativePitch() 
        if math.abs(currentPitch) < 4.5 then return end
        
        while math.abs(currentPitch - targetPitch) > 0.5 do
            Citizen.Wait(0)
            
            currentPitch = currentPitch + (targetPitch - currentPitch) * 0.1
            
            SetGameplayCamRelativePitch(currentPitch, 1.0)
        end
    end)

    local secondInv = secondInventory
    
    -- Build bag info for UI
    local playerSex = NullInventory.IsMale() and "male" or "female"
    local bagInfo = Config.ListBags and Config.ListBags[playerSex] or {}
    local equipped = NullInventory.equippedClothes or {}
    local equippedBag = equipped["bag"]
    local equippedBagId = equippedBag and (equippedBag.id or equippedBag.name) or nil
    
    -- Check admin permissions for hub tabs
    local isFounder = ESX.HasPermissions("liste_items_armes") or false
    local isStaff = ESX.HasPermissions("coffre_staff") or false
    
    -- Open the React NUI
    SendNUIMessage({
        action = 'newInventory:open',
        data = {
            playerSex = playerSex,
            bagInfo = bagInfo,
            equippedBagId = equippedBagId,
            isFounder = isFounder,
            isStaff = isStaff,
        }
    })
    
    null.DisplayHud(false)
    
    SendNUIMessage({
        action = 'newInventory:setMaxLeftWeight',
        data = { weight = ESX.GetMaxWeight() or 24 }
    })
    
    local leftData = NullInventory.GetPlayerInventory()
    
    -- Add descriptions to items
    for i, item in ipairs(leftData) do
        leftData[i] = AddItemDescription(item)
    end
    
    NullInventory.GetClothes(function(clothes)
        -- Add non-bag accessories from vclothes
        for _, clothe in pairs(clothes) do
            if clothe.type ~= "bag" then
                table.insert(leftData, {
                    type = "accessory",
                    type2 = clothe.type,
                    count = 1,
                    name = clothe.id,
                    label = clothe.label,
                    weight = Config.ClothesDefaultWeight or 0.5,
                    canMove = false,
                    data = clothe.clothe,
                    slot = clothe.slot,
                })
            end
        end
        
        -- Load all bags from vbackpacks table
        ESX.TriggerServerCallback('null:backpack:getAllBags', function(bags)
            for _, bag in ipairs(bags) do
                local bagLabel = bag.label
                -- if bag.maxWeight then
                --     bagLabel = bagLabel .. " (" .. bag.maxWeight .. "kg"
                --     if bag.canHoldWeapons then
                --         bagLabel = bagLabel .. ", 🔫"
                --     end
                --     bagLabel = bagLabel .. ")"
                -- end
                
                table.insert(leftData, {
                    type = "accessory",
                    type2 = "bag",
                    count = 1,
                    name = bag.clotheId,
                    label = bagLabel,
                    canMove = true,
                    data = {
                        bags_1 = bag.bagValue,
                        bags_2 = bag.bagTexture
                    },
                    slot = bag.slot,
                })
            end
            
            SendNUIMessage({
                action = 'newInventory:setLeft',
                data = { inventory = leftData }
            })
            SendNUIMessage({
                action = 'newInventory:setMaxLeftWeight',
                data = { weight = ESX.GetMaxWeight() or 24 }
            })
            SendNUIMessage({
                action = 'newInventory:setLeftWeight',
                data = { weight = ESX.GetCurrentWeight() or 0 }
            })
        end)
    end)
    
    SendNUIMessage({
        action = 'newInventory:setLeftTitle',
        data = { title = "Inventaire" }
    })
    
    -- Send weapon shortcuts
    pcall(function()
        local keybinds = exports["null-core"]:getWeaponKeybinds()
        if keybinds then
            for i = 0, 4 do
                local key = NullInventory._weaponBinds.numbers[i]
                if keybinds[key] and keybinds[key] ~= "WEAPON_UNARMED" then
                    SendNUIMessage({
                        action = "newInventory:setShortcut",
                        data = {
                            index = i + 1,
                            shortcut = {
                                name = keybinds[key],
                                label = ESX.GetWeaponLabel(keybinds[key]) or keybinds[key],
                                count = 1,
                                type = "weapon"
                            }
                        }
                    })
                end
            end
        end
    end)
    
    -- Send player info for hub panel
    pcall(function()
        local playerData = ESX.GetPlayerData()
        local cash = 0
        local dirtycash = 0
        local bank = 0
        if playerData.accounts then
            for _, acc in ipairs(playerData.accounts) do
                if acc.name == 'money' then cash = acc.money end
                if acc.name == 'bank' then bank = acc.money end
                if acc.name == 'dirtycash' then dirtycash = acc.money end
            end
        end
        SendNUIMessage({
            action = 'newInventory:setPlayerInfo',
            data = { 
                name = playerData.firstname and playerData.lastname
                    and (playerData.firstname .. ' ' .. playerData.lastname)
                    or (GetPlayerName(PlayerId()) or 'Joueur'),
                id = tostring(GetPlayerServerId(PlayerId())),
                uniqueId = tostring(playerData.idunique or ''),
                job = playerData.job and playerData.job.label or 'Sans emploi',
                money = cash,
                dirtycash = dirtycash,
                bank = bank,

            }
        })
    end)

    -- Send options data for Options tab
    pcall(function()
        SendOptionsDataToUI()
    end)

    -- Send societies list for the home "Status des entreprises" section
    pcall(function()
        ESX.TriggerServerCallback("Core:GetSociety", function(societies)
            if type(societies) ~= "table" then return end
            local list = {}
            for _, v in pairs(societies) do
                if v and v.name then
                    table.insert(list, {
                        name = v.name,
                        label = v.label or v.name,
                        type = v.type or "",
                        state = v.state == true,
                        logo = v.logo or "",
                        description = v.description or "",
                        brandColor = v.brandColor or "#3498db",
                        hasPosition = v.position ~= nil,
                    })
                end
            end
            -- Sort by open first, then label
            table.sort(list, function(a, b)
                if a.state ~= b.state then return a.state end
                return (a.label or "") < (b.label or "")
            end)
            SendNUIMessage({ action = "newInventory:setSocieties", data = { societies = list } })
        end)
    end)

    -- Send craft recipes for Craft tab (weapon craft for illegal orgs + advanced craft)
    pcall(function()
        SendAdvancedCraftDataToUI(nil)
    end)

    -- Send outfit data for Tenues tab
    pcall(function()
        SendOutfitDataToUI()
    end)

    -- Send backpack data for Sac tab
    pcall(function()
        SendBackpackDataToUI()
    end)

    if secondInv then
        NullInventory.currentChest = {
            cacheKey = secondInv.cacheKey,
            type = secondInv.type,
            maxWeight = secondInv.maxWeight,
            weight = secondInv.weight,
            data = secondInv.data,
            literal = secondInv.literal,
        }
        -- Add descriptions to right inventory items
        local rightData = secondInv.inventory or {}
        for i, item in ipairs(rightData) do
            rightData[i] = AddItemDescription(item)
        end
        
        SendNUIMessage({ action = "newInventory:setRightTitle", data = { title = secondInv.title or "Coffre" } })
        SendNUIMessage({ action = "newInventory:setMaxRightWeight", data = { weight = secondInv.maxWeight or 1000 } })
        SendNUIMessage({ action = "newInventory:setRightWeight", data = { weight = secondInv.weight or 0 } })
        SendNUIMessage({ action = "newInventory:setRight", data = { inventory = rightData } })
        TriggerEvent("esx:enableSecondInventory", false)
    else
        NullInventory.currentChest = nil
        TriggerEvent("esx:enableSecondInventory", true)
        SendNUIMessage({ action = "newInventory:disableRight", data = { disable = true } })
    end
    
    -- Clone ped
    if exports["null-core"]:getPreference("cloneped") then
        TriggerEvent("null:inventory:createClonePed")
    else
        SendNUIMessage({
            action = 'newInventory:pedVisibility',
            data = {
                visible = false,
            }
        })
    end
    
    NullInventory.StartControlThread()
end)

NullInventory.Close = LPH_JIT(function()
    if not NullInventory.isOpen then NullInventory.isOpen = false return end
    
    if NullInventory.currentChest then
        if NullInventory.currentChest.literal and NullInventory.currentChest.literal.savename then
            TriggerServerEvent("null:closeCoffre", NullInventory.currentChest.literal.savename)
        end
    end
    
    NullInventory.isOpen = false
    _G.newInventoryOpen = false
    NullInventory.currentChest = nil
     
    SendNUIMessage({ action = 'newInventory:close' })
    
    SetNuiFocus(false, false)
    DisplayRadar(true)
    null.DisplayHud(true)
    null.ActiveFrontend(false)
    TriggerEvent("null:inventory:destroyClonePed")
    
    pcall(function() exports["null-core"]:setChatCanOpen(true) end)
end)

NullInventory.Update = LPH_JIT(function()
    if not NullInventory.isOpen then return end

    local leftData = NullInventory.GetPlayerInventory()
    
    -- Add descriptions to items
    for i, item in ipairs(leftData) do
        leftData[i] = AddItemDescription(item)
    end
    
    NullInventory.GetClothes(function(clothes)
        -- Add non-bag accessories from vclothes
        for _, clothe in pairs(clothes) do
            if clothe.type ~= "bag" then
                table.insert(leftData, {
                    type = "accessory",
                    type2 = clothe.type,
                    count = 1,
                    name = clothe.id,
                    label = clothe.label,
                    weight = Config.ClothesDefaultWeight or 0.5,
                    canMove = false,
                    data = clothe.clothe,
                    slot = clothe.slot,
                })
            end
        end
        
        -- Load all bags from vbackpacks table
        ESX.TriggerServerCallback('null:backpack:getAllBags', function(bags)
            for _, bag in ipairs(bags) do
                local bagLabel = bag.label
                -- if bag.maxWeight then
                --     bagLabel = bagLabel .. " (" .. bag.maxWeight .. "kg"
                --     if bag.canHoldWeapons then
                --         bagLabel = bagLabel .. ", 🔫"
                --     end
                --     bagLabel = bagLabel .. ")"
                -- end
                
                table.insert(leftData, {
                    type = "accessory",
                    type2 = "bag",
                    count = 1,
                    name = bag.clotheId,
                    label = bagLabel,
                    canMove = true,
                    data = {
                        bags_1 = bag.bagValue,
                        bags_2 = bag.bagTexture
                    },
                    slot = bag.slot,
                })
            end
            
            SendNUIMessage({ action = "newInventory:setLeft", data = { inventory = leftData } })
            SendNUIMessage({ action = "newInventory:setMaxLeftWeight", data = { weight = ESX.GetMaxWeight() or 24 } })
            SendNUIMessage({ action = "newInventory:setLeftWeight", data = { weight = ESX.GetCurrentWeight() or 0 } })
        end)

        -- Clear all accessory slots first
        local allSlotTypes = {"top", "pants", "shoes", "mask", "glasses", "hat", "gillet", "bag", "bracelet", "ears", "chain"}
        for _, slotType in ipairs(allSlotTypes) do
            SendNUIMessage({
                action = "newInventory:setAccessory",
                data = {
                    type = slotType,
                    item = { name = "none" }
                }
            })
        end
        
        -- Send equipped clothes to equip slots
        if NullInventory.equippedClothes then
            for clotheType, clotheData in pairs(NullInventory.equippedClothes) do
                if clotheData and clotheData.data and (clotheData.name or clotheData.id) then
                    local slotKey = clotheType:gsub("_1$", "") -- Convert mask_1 to mask for UI slot
                    SendNUIMessage({
                        action = "newInventory:setAccessory",
                        data = {
                            type = slotKey,
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
        end
    end)
end)

NullInventory.GetPlayerInventory = LPH_JIT(function()
    local data = {}
    local playerData = ESX.GetPlayerData()
    local accountSlots = {}

    for _, account in ipairs(playerData.accounts or {}) do
        accountSlots[account.name] = account.slot
    end
    
    if ESX.getAccountMoney("cash") >= 1 then
        table.insert(data, {
            type = "cash",
            count = ESX.getAccountMoney("cash"),
            name = "cash",
            label = "Argent",
            slot = accountSlots.cash or accountSlots.money,
        })
    end
    
    if ESX.getAccountMoney("dirtycash") >= 1 then
        table.insert(data, {
            type = "dirtycash",
            count = ESX.getAccountMoney("dirtycash"),
            name = "dirtycash",
            label = "Argent Sale",
            slot = accountSlots.dirtycash,
        })
    end
    
    for i, item in ipairs(playerData.inventory or {}) do
        if item.count > 0 then
            local label = item.label
            if item.metadata and item.metadata.label then
                label = item.metadata.label
            end
            
            local canMove = not ESX.ContribItem(item.name)
            
            local itemData = {
                type = "item",
                id = i,
                count = item.count,
                name = item.name,
                label = label,
                weight = item.weight or (ESX.Items[item.name] and ESX.Items[item.name].weight) or 0,
                canMove = canMove,
                metadata = item.metadata,
                extra = item.extra,
                unique = item.unique,
                slot = item.slot,
            }
            
            if ESX.InventoryHover and ESX.InventoryHover[item.name] then
                itemData.isHovered = true
                itemData.hoveredData = ESX.InventoryHover[item.name](item)
            end
            
            if ESX.InventoryProgress and ESX.InventoryProgress[item.name] then
                itemData.progressBar = true
                itemData.progressData = ESX.InventoryProgress[item.name](item)
            end
            
            table.insert(data, itemData)
        end
    end
    
    for i, weapon in ipairs(playerData.loadout or {}) do
        local label = weapon.label
        if weapon.metadata and weapon.metadata.label then
            label = weapon.metadata.label
        end
        
        if weapon.name == 'WEAPON_PETROLCAN' and weapon.metadata then
            local liters = math.floor(((weapon.metadata.fuel or 1) / 4500) * 100)
            label = ("%s (%sL)"):format(label, liters)
        end
        
        local canMove = not ESX.ContribWeapon(weapon.name) and not weapon.permanent
        
        local weaponData = {
            type = "weapon",
            id = i,
            count = 1,
            name = weapon.name,
            label = label,
            weight = ESX.GetWeaponWeight and ESX.GetWeaponWeight(weapon.name) or Config.WeaponDefaultWeight or 0,
            canMove = canMove,
            metadata = weapon.metadata,
            hoveredData = {},
            isHovered = true,
            durability = Config.AmmunationShop.repairSysteme and weapon.durability or 0,
            permanent = weapon.permanent,
            serialnumber = weapon.serialnumber,
            slot = weapon.slot,
        }
        
        if ESX.InventoryProgressWeapon and ESX.InventoryProgressWeapon[weapon.name] then
            weaponData.progressBar = true
            weaponData.progressData = ESX.InventoryProgressWeapon[weapon.name](weapon)
        end
        
        table.insert(data, weaponData)
    end
    
    return data
end)

NullInventory.GetClothes = LPH_JIT(function(cb)
    local now = GetGameTimer()
    
    if NullInventory.clothesCache and (now - NullInventory.clothesCacheTime) < CLOTHES_CACHE_DURATION then
        return cb(NullInventory.clothesCache)
    end
    
    ESX.TriggerServerCallback('null:inv:getClothe', function(clothes)
        NullInventory.clothesCache = clothes
        NullInventory.clothesCacheTime = now
        cb(clothes)
    end)
end)

function NullInventory.IsMale()
    return GetEntityModel(PlayerPedId()) == GetHashKey("mp_m_freemode_01")
end

NullInventory.StartControlThread = LPH_NO_VIRTUALIZE(function()
    CreateThread(function()
        while NullInventory.isOpen do
            Wait(0)
            DisableControlAction(0, 1, true)   -- LookLeftRight
            DisableControlAction(0, 2, true)   -- LookUpDown
            DisableControlAction(0, 142, true) -- MeleeAttackAlternate
            DisableControlAction(0, 135, true) -- VehicleSubDescend
            DisableControlAction(0, 223, true) -- VehicleExit
            DisableControlAction(0, 257, true) -- AttackAlternate
            DisableControlAction(0, 18, true)  -- Enter
            DisableControlAction(0, 322, true) -- ESC
            DisableControlAction(0, 106, true) -- VehicleMouseControlOverride
            DisableControlAction(0, 24, true)  -- Attack
            DisableControlAction(0, 25, true)  -- Aim
            
            -- Disable movement
            DisableControlAction(0, 30, true)  -- MoveLeftRight
            DisableControlAction(0, 31, true)  -- MoveUpDown
            DisableControlAction(0, 21, true)  -- Sprint
            DisableControlAction(0, 22, true)  -- Jump
            DisableControlAction(0, 36, true)  -- Duck

            if IsDisabledControlJustPressed(0, 322) then
                NullInventory.Close()
            end
        end
    end)
end)

local timeout = nil
RegisterKeyMapping("vopenInventory", "Ouvrir l'inventaire", "keyboard", "tab")
RegisterCommand("vopenInventory", function()
    if timeout and (GetGameTimer() - timeout) < 200 then
        return
    end
    timeout = GetGameTimer()
    if NullInventory.isOpen then
        NullInventory.Close()
    else
        NullInventory.Open()
    end
end, false)

RegisterNetEvent("null:inventory:closeinv", function()
    NullInventory.Close()
end)

AddEventHandler("inventory:onClose", function()
    NullInventory.Close()
end)

RegisterNetEvent("null:inventory:update", function()
    NullInventory.Update()
end)

RegisterNetEvent("null:inventory:syncSlots", function(slots)
    if type(slots) ~= "table" or not ESX or not ESX.PlayerData then return end

    for _, accountSlot in ipairs(slots.accounts or {}) do
        for _, account in ipairs(ESX.PlayerData.accounts or {}) do
            if account.name == accountSlot.name then
                account.slot = tonumber(accountSlot.slot)
                break
            end
        end
    end

    for _, itemSlot in ipairs(slots.inventory or {}) do
        local item = ESX.PlayerData.inventory and ESX.PlayerData.inventory[tonumber(itemSlot.index)]
        if item and item.name == itemSlot.name then
            item.slot = tonumber(itemSlot.slot)
        end
    end

    for _, weaponSlot in ipairs(slots.loadout or {}) do
        local weapon = ESX.PlayerData.loadout and ESX.PlayerData.loadout[tonumber(weaponSlot.index)]
        if weapon and weapon.name == weaponSlot.name then
            weapon.slot = tonumber(weaponSlot.slot)
        end
    end

    if ESX.RebuildInventoryCache then ESX.RebuildInventoryCache() end
    if ESX.RebuildLoadoutCache then ESX.RebuildLoadoutCache() end
end)

RegisterNetEvent("null:inventory:clearClothesCache", function()
    NullInventory.clothesCache = nil
    NullInventory.clothesCacheTime = 0
end)

-- Handle item rename from server
RegisterNetEvent("inventory:itemRenamed", function(itemName, itemIndex, newName)
    print("[INVENTORY DEBUG CLIENT] Received inventory:itemRenamed event")
    print("[INVENTORY DEBUG CLIENT] Item name:", itemName, "Index:", itemIndex, "New name:", newName)
    
    local playerData = ESX.GetPlayerData()
    if playerData and playerData.inventory then
        -- Find and update the item in ESX.PlayerData
        for i, item in ipairs(playerData.inventory) do
            if item.name == itemName and i == itemIndex then
                if not item.metadata then
                    item.metadata = {}
                end
                item.metadata.title = newName
                print("[INVENTORY DEBUG CLIENT] Updated item metadata locally:", json.encode(item.metadata))
                
                -- Update ESX PlayerData
                ESX.SetPlayerData("inventory", playerData.inventory)
                
                -- Force UI refresh
                NullInventory.Update()
                break
            end
        end
    end
end)

-- Handle weapon rename from server
RegisterNetEvent("inventory:weaponRenamed", function(weaponName, weaponIndex, newName)
    print("[INVENTORY DEBUG CLIENT] Received inventory:weaponRenamed event")
    print("[INVENTORY DEBUG CLIENT] Weapon name:", weaponName, "Index:", weaponIndex, "New name:", newName)
    
    local playerData = ESX.GetPlayerData()
    if playerData and playerData.loadout then
        -- Find and update the weapon in ESX.PlayerData
        for i, weapon in ipairs(playerData.loadout) do
            if weapon.name == weaponName and i == weaponIndex then
                if not weapon.metadata then
                    weapon.metadata = {}
                end
                weapon.metadata.title = newName
                print("[INVENTORY DEBUG CLIENT] Updated weapon metadata locally:", json.encode(weapon.metadata))
                
                -- Update ESX PlayerData
                ESX.SetPlayerData("loadout", playerData.loadout)
                
                -- Force UI refresh
                NullInventory.Update()
                break
            end
        end
    end
end)

-- Handle clothe rename from server
RegisterNetEvent("inventory:clotheRenamed", function(clotheId, newName)
    print("[INVENTORY DEBUG CLIENT] Received inventory:clotheRenamed event")
    print("[INVENTORY DEBUG CLIENT] Clothe ID:", clotheId, "New name:", newName)
    
    -- Invalidate clothes cache to force reload from database
    TriggerEvent("null:inventory:invalidateClothesCache")
    
    -- Force UI refresh
    NullInventory.Update()
end)

AddEventHandler("null:inventory:invalidateClothesCache", function()
    NullInventory.clothesCache = nil
    NullInventory.clothesCacheTime = 0
end)

AddEventHandler('esx:playerLoaded', function(xPlayer)
    Wait(1000) 

    if xPlayer.clothes_equiped then
        NullInventory.equippedClothes = xPlayer.clothes_equiped

        local defaultSkin = NullInventory.IsMale() 
            and Config.Inventory.DefaultSkin.male 
            or Config.Inventory.DefaultSkin.female
        
        for clotheType, defaultValues in pairs(defaultSkin) do
            if xPlayer.clothes_equiped[clotheType] then
                local equipped = xPlayer.clothes_equiped[clotheType]
                
                TriggerEvent("null:inventory:nui:setAccessory", clotheType, {
                    type2 = clotheType,
                    count = 1,
                    name = equipped.name,
                    data = equipped.data,
                    label = equipped.label,
                })
                
                if type(equipped.data) == "table" then
                    for propName, propValue in pairs(equipped.data) do
                        if type(propName) == "string" and type(propValue) == "number" then
                            TriggerEvent("Null:skinchanger:change", propName, propValue)
                        end
                    end
                end
            else
                for propName, propValue in pairs(defaultValues) do
                    TriggerEvent("Null:skinchanger:change", propName, propValue)
                end
            end
        end
    end
    
    TriggerEvent("null:inventory:nui:setTitle", "Inventaire")
end)

exports('openInventory', function(secondInventory)
    NullInventory.Open(secondInventory)
end)

exports('closeInventory', function()
    NullInventory.Close()
end)

exports('isInventoryOpen', function()
    return NullInventory.isOpen
end)

exports('IsInInventory', function()
    return NullInventory.isOpen
end)

exports('CanOpenInventory', function(value)
    if value ~= nil then
        NullInventory.canOpen = value
    end
    return NullInventory.canOpen
end)

function isUsingInterface()
    return Config.Prefer and Config.Prefer.Enabled and Config.Prefer.Enabled["interfaces"] or false
end

exports('isUsingInterface', isUsingInterface)

exports('setUsingInterface', function(value)
    if Config.Prefer and Config.Prefer.Enabled then
        Config.Prefer.Enabled["interfaces"] = value
    end
end)

-- Vehicle Trunk Keybind (L key)
RegisterKeyMapping("openCoffre", "Ouvrir un coffre de véhicule", "keyboard", "L")
RegisterCommand("openCoffre", function()
    if NullInventory.isOpen then return end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicle = GetVehiclePedIsIn(playerPed) ~= 0 and GetVehiclePedIsIn(playerPed) or GetClosestVehicle(playerCoords, 7.0, 0, 71)
    
    if not DoesEntityExist(vehicle) then
        return ESX.ShowNotification("Il n'y a pas de véhicule proche", "Erreur")
    end
    
    local vehiclePos = GetEntityCoords(vehicle)
    local dist = #(playerCoords - vehiclePos)
    local locked = GetVehicleDoorLockStatus(vehicle)
    
    if dist > 3.5 then
        return ESX.ShowNotification("Il n'y a pas de véhicule proche.", "Erreur")
    end
    
    if locked ~= 1 then
        return ESX.ShowNotification("Ce coffre est verrouillé", "Erreur")
    end
    
    local vPlate = GetVehicleNumberPlateText(vehicle)
    
    -- If player is sitting in vehicle, open glove box instead
    if IsPedSittingInAnyVehicle(playerPed) then
        local vehClass = GetVehicleClass(vehicle)
        local vehModel = GetEntityModel(vehicle)
        local vehMaxWeight = Config.Inventory.GloveBoxWeight[vehClass] or Config.Inventory.DefaultWeights.VEHICLE_GLOVE_BOX or 5
        
        if Config.Inventory.CustomGloveBoxWeight[vehModel] then
            vehMaxWeight = Config.Inventory.CustomGloveBoxWeight[vehModel]
        end
        
        ESX.TriggerServerCallback('null:getCoffre', function(data, id, weight)
            if data then
                data.weight = weight or 0
                data.id = id
                data.maxWeight = vehMaxWeight
                data.type = "VEHICLE_GLOVE_BOX"
                TriggerEvent("inventory:openTarget", data)
            end
        end, vPlate, "glovebox", vehMaxWeight)
        return
    end
    
    -- Open trunk
    local vehClass = GetVehicleClass(vehicle)
    local vehModel = GetEntityModel(vehicle)
    local vehMaxWeight = Config.Inventory.VehicleWeight[vehClass] or Config.Inventory.DefaultWeights.VEHICLE
    
    if Config.Inventory.CustomVehicleWeight[vehModel] then
        vehMaxWeight = Config.Inventory.CustomVehicleWeight[vehModel]
    end
    
    ESX.TriggerServerCallback('null:getCoffre', function(data, id, weight)
        if data then
            data.weight = weight or 0
            data.id = id
            data.maxWeight = vehMaxWeight
            data.type = "VEHICLE"
            TriggerEvent("inventory:openTarget", data)
        end
    end, vPlate, "trunk", vehMaxWeight)
end, false)

-- Export for opening chests/storage
exports("openChest", function(name, maxWeight)
    ESX.TriggerServerCallback('null:getCoffre', function(data, id, weight)
        if data then
            data.weight = weight or 0
            data.id = id
            data.maxWeight = maxWeight or 1000
            data.type = "SOCIETY"
            TriggerEvent("inventory:openTarget", data)
        end
    end, name, "storage", maxWeight)
end)

_G.NullInventoryClientLoaded = true
null.InitPrint("Inventory Client Module loaded")
