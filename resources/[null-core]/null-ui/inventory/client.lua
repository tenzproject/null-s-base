local function IsMale()
    return GetEntityModel(PlayerPedId()) == GetHashKey("mp_m_freemode_01")
end

-- Disabled - null-core handles inventory NUI
-- AddEventHandler("inventory:open", function(leftData, leftWeight)
--     setInInterface("inventory")
--     SetNuiFocus(true, true)
--     SetNuiFocusKeepInput(true)
--     DisplayRadar(false)
--     null.DisplayHud(false)
--     null.ActiveFrontend(false)
--     
--     SendNUIMessage({ type = "inventory:setMaxLeftWeight", data = { weight = leftWeight } })
--     SendNUIMessage({ type = "inventory:setLeft", data = { inventory = leftData } })
--     SendNUIMessage({ type = "inventory:open", playerSex = IsMale() and "male" or "female" })
--     
--     if exports["null-core"]:getPreference("cloneped") then 
--         TriggerEvent("null:inventory:createClonePed")
--     end
-- end)

-- Disabled - null-core handles inventory NUI
-- AddEventHandler("inventory:close", function()
--     clearInterface()
--     SetNuiFocus(false, false)
--     DisplayRadar(true)
--     null.DisplayHud(true)
--     null.ActiveFrontend(false)
--     TriggerEvent("null:inventory:destroyClonePed")
--     
--     SendNUIMessage({ type = "inventory:close" })
--     
--     pcall(function() exports["null-core"]:setChatCanOpen(true) end)
-- end)

-- Disabled - null-core handles these events in new_inventory.lua
-- AddEventHandler("inventory:left:changeWeight", function(newWeight)
--     SendNUIMessage({ type = "inventory:setLeftWeight", data = { weight = newWeight } })
-- end)
-- 
-- AddEventHandler("inventory:left:changeMaxWeight", function(newWeight)
--     SendNUIMessage({ type = "inventory:setMaxLeftWeight", data = { weight = newWeight } })
-- end)
-- 
-- AddEventHandler("inventory:right:changeWeight", function(newWeight)
--     SendNUIMessage({ type = "inventory:setRightWeight", data = { weight = newWeight } })
-- end)
-- 
-- AddEventHandler("inventory:setRight", function(rightData)
--     SendNUIMessage({ type = "inventory:setRight", data = { inventory = rightData } })
-- end)
-- 
-- AddEventHandler("esx:refreshRightInventory", function(data)
--     SendNUIMessage({ type = "inventory:setRight", data = { inventory = data } })
-- end)
-- 
-- AddEventHandler("ZgegFramework:enableSecondInventory", function(data)
--     SendNUIMessage({ type = "inventory:disableRightInventory", data = { disable = data } })
-- end)

-- Disabled - null-core handles this
-- RegisterNetEvent("inventory:setRightData", function(data)
--     if data.weight then SendNUIMessage({ type = "inventory:setRightWeight", data = { weight = data.weight } }) end
--     if data.maxWeight then SendNUIMessage({ type = "inventory:setMaxRightWeight", data = { weight = data.maxWeight } }) end
--     if data.title then SendNUIMessage({ type = "inventory:setInventoryRightData", data = { title = data.title } }) end
--     SendNUIMessage({ type = "inventory:setRight", data = { inventory = data.inventory } })
-- end)

-- Disabled - null-core handles notifications
-- RegisterNetEvent("inventory:sendMessage", function(msg, time2)
--     SendNUIMessage({ type = "inventory:sendMessage", data = { message = { text = msg }, time = time2 or 3000 } })
-- end)
-- 
-- exports("InventoryNotif", function(msg, time2)
--     SendNUIMessage({ type = "inventory:sendMessage", data = { message = { text = msg }, time = time2 or 3000 } })
-- end)


-- RegisterNUICallback("inventory:startRename", function(_, cb) SetNuiFocusKeepInput(false) cb({}) end)
-- RegisterNUICallback("inventory:startGiveItem", function(_, cb) SetNuiFocusKeepInput(false) cb({}) end)
-- RegisterNUICallback("inventory:startDropItem", function(_, cb) SetNuiFocusKeepInput(false) cb({}) end)

RegisterNUICallback("inventory:close", function(_, cb)
    if NullInventory and NullInventory.Close then
        NullInventory.Close()
    else
        TriggerEvent("inventory:close")
    end
    cb({})
end)

RegisterNUICallback("inventory:searchFocus", function(_, cb)
    pcall(function() exports["null-core"]:setChatCanOpen(false) end)
    exports["null-core"]:ActiveFrontend(true)
    cb({})
end)

RegisterNUICallback("inventory:searchBlur", function(_, cb)
    exports["null-core"]:ActiveFrontend(false)
    pcall(function() exports["null-core"]:setChatCanOpen(true) end)
    cb({})
end)

RegisterNUICallback("inventory:useItem", function(data, cb)
    TriggerEvent("null:inventory:nui:useItem", data)
    cb({})
end)

RegisterNUICallback("inventory:giveItem", function(data, cb)
    TriggerEvent("null:inventory:nui:giveItem", data)
    cb({})
end)

RegisterNUICallback("inventory:dropItem", function(data, cb)
    TriggerEvent("null:inventory:nui:dropItem", data)
    cb({})
end)

RegisterNUICallback("inventory:renameItem", function(data, cb)
    TriggerEvent("null:inventory:nui:renameItem", data)
    cb({})
end)

RegisterNUICallback("inventory:changeSlot", function(data, cb)
    TriggerEvent("null:inventory:nui:changeSlot", data)
    cb({})
end)

local weaponBinds = {
    numbers = { [0] = 'one', [1] = 'two', [2] = 'three', [3] = 'four', [4] = 'five' },
    string = { ['one'] = 1, ["two"] = 2, ["three"] = 3, ["four"] = 4, ["five"] = 5 }
}

-- Disabled - null-core handles shortcuts in new_inventory.lua
-- RegisterNetEvent("ZgegFramework:changeShortCut", function(name, weapon, isNumber)
--     local id = isNumber and tonumber(name) or weaponBinds.string[name]
--     if not id then return end
--     local shortcut = weapon == "WEAPON_UNARMED" 
--         and { name = "none", label = "", count = 1, type = "weapon" }
--         or { name = weapon, label = ESX.GetWeaponLabel(weapon), count = 1, type = "weapon" }
--     SendNUIMessage({ type = "shortcut:setShortcut", data = { index = id, shortcut = shortcut } })
-- end)

RegisterNUICallback("shortcut:set", function(data, cb)
    exports["null-core"]:setWeaponKeybind(weaponBinds.numbers[data.slot-1], data.item.name, data.item.label)
    cb({})
end)

RegisterNUICallback("shortcut:remove", function(data, cb)
    exports["null-core"]:setWeaponKeybind(weaponBinds.numbers[data.slot-1], "WEAPON_UNARMED", "Aucun")
    cb({})
end)

RegisterNUICallback("shortcut:equipAccessory", function(data, cb)
    TriggerEvent("null:inventory:nui:equipAccessory", data)
    cb({})
end)

RegisterNUICallback("shortcut:removeAccessory", function(data, cb)
    TriggerEvent("null:inventory:nui:removeAccessory", data)
    cb({})
end)

-- Disabled - null-core handles accessories
-- AddEventHandler("null:inventory:nui:setAccessory", function(accessoryType, item)
--     SendNUIMessage({ type = "shortcut:setAccessory", data = { type = accessoryType, item = item } })
-- end)

RegisterNetEvent("null:inventory:equipClothesSlot", function(clotheType, clotheData)
    if not clotheData then return end
    

    if NullInventory then
        NullInventory.clothesCache = nil
        NullInventory.clothesCacheTime = 0
    end
    
    if clotheData.data and type(clotheData.data) == "table" then
        for propName, propValue in pairs(clotheData.data) do
            if type(propName) == "string" and type(propValue) == "number" then
                TriggerEvent("Null:skinchanger:change", propName, propValue)
            end
        end
    end
    
    -- Disabled - null-core handles this
    -- SendNUIMessage({ 
    --     type = "shortcut:setAccessory", 
    --     data = { 
    --         type = clotheType, 
    --         item = {
    --             type2 = clotheType,
    --             count = 1,
    --             name = clotheData.id,
    --             data = clotheData.data,
    --             label = clotheData.label,
    --         }
    --     } 
    -- })
    
    if NullInventory and NullInventory.equippedClothes then
        NullInventory.equippedClothes[clotheType] = clotheData
    end

    TriggerEvent("Null:skinchanger:getSkin", function(skin)
        TriggerServerEvent("Null:esx_skin:save", skin)
    end)
end)

-- Disabled - null-core handles all these
-- AddEventHandler("null:inventory:nui:updateStats", function(stats)
--     SendNUIMessage({ type = "inventory:updateStats", data = stats })
-- end)
-- 
-- AddEventHandler("null:inventory:nui:setLeftData", function(data, leftMaxWeight)
--     SendNUIMessage({ type = "inventory:setLeft", data = { inventory = data } })
--     if leftMaxWeight then 
--         SendNUIMessage({ type = "inventory:setMaxLeftWeight", data = { weight = leftMaxWeight } })
--     end
-- end)
-- 
-- AddEventHandler("null:inventory:nui:setTitle", function(title)
--     SendNUIMessage({ type = "inventory:setInventoryLeftData", data = { title = title } })
-- end)
-- 
-- CreateThread(function()
--     Wait(5000)
--     SendNUIMessage({ type = "inventory:setInventoryLeftData", data = { title = "Inventaire" } })
-- end)

null.InitPrint("Inventory NUI Bridge loaded")
