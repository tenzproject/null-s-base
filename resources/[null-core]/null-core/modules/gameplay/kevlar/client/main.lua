-- ============================================================================
-- KEVLAR SYSTEM — Client
-- Item stays in inventory, equip/unequip toggles armor + visual
-- ============================================================================

local isKevlarEquipped = false
local kevlarData = nil -- { itemName, extraIdentifier, durability, maxDurability, maxArmor, armorValue }
local lastArmor = 0
local damageCheckActive = false

-- ============================================================================
-- EQUIP
-- ============================================================================

RegisterNetEvent("null:kevlar:equipped", function(data)
    if not data then return end
    isKevlarEquipped = true
    kevlarData = data

    local ped = PlayerPedId()

    -- Apply armor
    SetPedArmour(ped, data.armorValue)
    lastArmor = data.armorValue

    -- Apply visual (bproof vest)
    if data.bproof then
        local sex = GetEntityModel(ped) == GetHashKey("mp_m_freemode_01") and "male" or "female"
        local bproofData = data.bproof[sex]
        if bproofData then
            for propName, propValue in pairs(bproofData) do
                TriggerEvent("Null:skinchanger:change", propName, propValue)
            end
            TriggerEvent("Null:skinchanger:getSkin", function(skin)
                TriggerServerEvent("Null:esx_skin:save", skin)
            end)
        end
    end

    -- Set gillet accessory slot in UI (like other accessories)
    if data.bproof then
        local sex = GetEntityModel(ped) == GetHashKey("mp_m_freemode_01") and "male" or "female"
        local bproofData = data.bproof[sex]
        if bproofData then
            -- Track in equippedClothes so it behaves like a normal accessory
            NullInventory.equippedClothes["bproof_1"] = {
                id = data.itemName,
                name = data.itemName,
                data = bproofData,
                label = data.itemName,
            }
            TriggerServerEvent("ZgegFramework:equipedClothes", NullInventory.equippedClothes)
            -- Update NUI gillet slot
            SendNUIMessage({
                action = "newInventory:setAccessory",
                data = {
                    type = "gillet",
                    item = {
                        type = "accessory",
                        type2 = "bproof_1",
                        count = 1,
                        name = data.itemName,
                        label = data.itemName,
                        data = bproofData,
                    }
                }
            })
        end
    end

    -- Update NUI with kevlar info (includes extraIdentifier)
    SendKevlarStateToUI()

    -- Start damage monitoring
    if not damageCheckActive then
        damageCheckActive = true
        StartDamageMonitor()
    end
end)

-- ============================================================================
-- UNEQUIP
-- ============================================================================

RegisterNetEvent("null:kevlar:unequipped", function()
    isKevlarEquipped = false
    kevlarData = nil
    damageCheckActive = false

    local ped = PlayerPedId()

    -- Remove armor
    SetPedArmour(ped, 0)
    lastArmor = 0

    -- Reset bproof visual + clear gillet slot (RemoveAccessory handles skin, equippedClothes, NUI slot)
    RemoveAccessory("bproof_1", false)

    -- Update NUI kevlar state
    SendKevlarStateToUI()
end)

-- ============================================================================
-- DESTROYED
-- ============================================================================

RegisterNetEvent("null:kevlar:destroyed", function()
    isKevlarEquipped = false
    kevlarData = nil
    damageCheckActive = false
    lastArmor = 0

    -- Reset bproof visual + clear gillet slot
    RemoveAccessory("bproof_1", false)

    SendKevlarStateToUI()
end)

-- ============================================================================
-- DAMAGE MONITOR — Tracks armor changes and reports to server
-- ============================================================================

function StartDamageMonitor()
    CreateThread(function()
        while damageCheckActive and isKevlarEquipped do
            Wait(1000)
            if not isKevlarEquipped then break end

            local ped = PlayerPedId()
            local currentArmor = GetPedArmour(ped)

            if currentArmor < lastArmor then
                -- Armor decreased, report to server
                TriggerServerEvent("null:kevlar:damageTick", currentArmor)

                -- Update local data
                if kevlarData then
                    kevlarData.armorValue = currentArmor
                    local ratio = currentArmor / kevlarData.maxArmor
                    kevlarData.durability = math.max(0, math.floor(ratio * kevlarData.maxDurability))
                    SendKevlarStateToUI()
                    -- Update the item's durability in the inventory grid
                    SendNUIMessage({
                        action = "newInventory:updateKevlarDurability",
                        data = {
                            itemName = kevlarData.itemName,
                            extraIdentifier = kevlarData.extraIdentifier,
                            durability = kevlarData.durability,
                            maxDurability = kevlarData.maxDurability,
                        }
                    })
                end

                if currentArmor <= 0 then
                    break
                end
            end

            lastArmor = currentArmor
        end
        damageCheckActive = false
    end)
end

-- ============================================================================
-- NUI STATE — Send equipped state including extraIdentifier for UI matching
-- ============================================================================

function SendKevlarStateToUI()
    if isKevlarEquipped and kevlarData then
        SendNUIMessage({
            action = "newInventory:setKevlar",
            data = {
                equipped = true,
                itemName = kevlarData.itemName,
                extraIdentifier = kevlarData.extraIdentifier,
                durability = kevlarData.durability,
                maxDurability = kevlarData.maxDurability,
                maxArmor = kevlarData.maxArmor,
                armorValue = kevlarData.armorValue,
            }
        })
    else
        SendNUIMessage({
            action = "newInventory:setKevlar",
            data = { equipped = false }
        })
    end
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

exports("IsKevlarEquipped", function() return isKevlarEquipped end)
exports("GetKevlarData", function() return kevlarData end)

-- ============================================================================
-- INVENTORY INTEGRATION — Intercept kevlar item usage
-- ============================================================================

AddEventHandler("null:kevlar:useItem", function(itemName, itemExtra)
    if isKevlarEquipped then
        -- If clicking the already-equipped kevlar, unequip it
        if kevlarData and itemExtra and kevlarData.extraIdentifier
            and tostring(kevlarData.extraIdentifier) == tostring(itemExtra.identifier) then
            TriggerServerEvent("null:kevlar:unequip")
        else
            TriggerEvent("inventory:sendMessage", "~r~Vous portez déjà un gilet")
        end
        return
    end
    TriggerServerEvent("null:kevlar:equip", itemName, itemExtra)
end)

AddEventHandler("null:kevlar:removeItem", function()
    if not isKevlarEquipped then
        TriggerEvent("inventory:sendMessage", "~r~Vous ne portez pas de gilet")
        return
    end
    TriggerServerEvent("null:kevlar:unequip")
end)
