while not _G.NullInventoryClientLoaded do
    Wait(0)
end
 
local pedSceneHandle = nil

local timeoutPedPoly = false

function TimeoutPoly()
    timeoutPedPoly = true
    SetTimeout(1000, function()
        timeoutPedPoly = false
    end)
end

local InventoryPedConfig = {
    screenX = 0.50,
    screenY = 0.70,
    depth = 4.0,
    bgWidth = 1.4,
    bgHeight = 2.5,
    zOffset = -0.05,
    rotationOffset = 180.0,
    polyOffsetY = -0.4,
    lightRange = 4.0,
    lightIntensity = 2.0,
    lightOffset = vector3(0.0, 1.0, 1.5),
    fadeDuration = 150.0,
    bgColor = { r = 12, g = 12, b = 14 },
    targetAlpha = 235,
    lightColor = { r = 195, g = 255, b = 209 },
    cameraTilt = true,
    cameraTiltConfig = {
        downThreshold = -30,
        downScreenYDelta = -0.05,
        downDepth = 5.0,
        upThreshold = 30,
        upScreenYDelta = 0,
        upDepth = 4.0,
    },
    isOpenFn = function() return NullInventory.isOpen end,
    nuiAction = 'newInventory',
    timeoutPolyFn = function() return timeoutPedPoly end,
}

function CreateInventoryPed()
    -- Always clean up old handle to prevent stale state
    if pedSceneHandle then
        if not pedSceneHandle.destroyed then
            PedScene.Destroy(pedSceneHandle)
        end
        pedSceneHandle = nil
    end
    pedSceneHandle = PedScene.Create(InventoryPedConfig)
end

function DestroyInventoryPed()
    if pedSceneHandle then
        PedScene.Destroy(pedSceneHandle)
        pedSceneHandle = nil
    end
end

function RefreshInventoryPed()
    if not NullInventory.isOpen then return end
    
    local useClonePed = exports["null-core"]:getPreference("cloneped")
    if not useClonePed then return end
    
    if pedSceneHandle then
        pedSceneHandle = PedScene.Refresh(pedSceneHandle)
    end
end

FormatInventoryForUI = LPH_JIT(function(inventoryData)
    local formatted = {}
    
    if inventoryData.cash and inventoryData.cash > 0 then
        table.insert(formatted, {
            type = "cash",
            count = inventoryData.cash,
            name = "cash",
            label = "Argent",
        })
    end
    
    if inventoryData.dirtycash and inventoryData.dirtycash > 0 then
        table.insert(formatted, {
            type = "dirtycash",
            count = inventoryData.dirtycash,
            name = "dirtycash",
            label = "Argent Sale",
        })
    end
    
    local itemList = (ESX.GetItemList and ESX.GetItemList()) or {}
    
    for i, item in ipairs(inventoryData.items or {}) do
        local canMove = not ESX.ContribItem(item.name)
        local itemWeight = item.weight
        if not itemWeight then
            local cfg = itemList[item.name]
            itemWeight = (cfg and cfg.weight) or 1
        end
        
        table.insert(formatted, {
            type = "item",
            id = i,
            count = item.count,
            name = item.name,
            label = item.label,
            weight = itemWeight,
            canMove = canMove,
            metadata = item.metadata,
            extra = item.extra,
            unique = item.unique,
            slot = item.slot,
        })
    end
    
    for i, weapon in ipairs(inventoryData.loadout or {}) do
        local canMove = not ESX.ContribWeapon(weapon.name) and not weapon.permanent
        local label = weapon.label
        
        if weapon.metadata and weapon.metadata.label then
            label = weapon.metadata.label
        end
        
        local weaponWeight = weapon.weight
            or (ESX.GetWeaponWeight and ESX.GetWeaponWeight(weapon.name))
            or Config.WeaponDefaultWeight
            or 5
        
        table.insert(formatted, {
            type = "weapon",
            id = i,
            count = 1,
            name = weapon.name,
            label = label,
            weight = weaponWeight,
            canMove = canMove,
            metadata = weapon.metadata,
            isHovered = true,
            hoveredData = {},
            durability = Config.AmmunationShop.repairSysteme and weapon.durability or 0,
            permanent = weapon.permanent,
            serialnumber = weapon.serialnumber,
            slot = weapon.slot,
        })
    end
    
    return formatted
end)

_G.formatInventory = FormatInventoryForUI

RegisterNetEvent("inventory:openTarget", function(target)
    if not target then return end
    
    --print("[DEBUG] inventory:openTarget - target.cacheKey:", target.cacheKey)
    --print("[DEBUG] inventory:openTarget - target.type:", target.type)
    --print("[DEBUG] inventory:openTarget - target.id:", target.id)
    
    local weight = 0
    for _, item in pairs(target.items or {}) do
        weight = weight + ((item.weight or 1) * (item.count or 1))
    end
    for _, weapon in pairs(target.loadout or {}) do
        if not ESX.ContribWeapon(weapon.name) and not weapon.permanent then
            weight = weight + 5
        end
    end
    
    local rightInventory = FormatInventoryForUI(target)
    
    local secondInventory = {
        name = target.type,
        title = target.title or Config.Inventory.TypeNames[target.type] or "Inventaire",
        weight = weight,
        maxWeight = target.maxWeight or 1000,
        inventory = rightInventory,
        data = { id = target.id, type = target.type },
        literal = target,
        cacheKey = target.cacheKey,
    }
    
    --print("[DEBUG] inventory:openTarget - secondInventory.cacheKey:", secondInventory.cacheKey)
    
    NullInventory.Open(secondInventory)
end)

RegisterNetEvent("inventory:openSearch", function(target, canMove, cash, dirtycash)
    if not target then return end
    
    target.cash = cash
    target.dirtycash = dirtycash
    
    local weight = 0
    for _, item in pairs(target.items or {}) do
        weight = weight + ((item.weight or 1) * (item.count or 1))
    end
    for _, weapon in pairs(target.loadout or {}) do
        weight = weight + 5
    end
    
    local rightInventory = FormatInventoryForUI(target)
    
    local secondInventory = {
        name = target.type,
        title = Config.Inventory.TypeNames[target.type] or "Fouille",
        weight = weight,
        maxWeight = target.maxWeight or 999999,
        inventory = rightInventory,
        data = {
            id = target.id,
            identifier = target.identifier,
            type = target.type,
            canMove = canMove,
            isSearch = true,
        },
        literal = target,
    }
    
    NullInventory.Open(secondInventory)
end)

RegisterNetEvent("inventory:update", function(data, inventory)
    TriggerEvent("inventory:left:changeWeight", ESX.GetCurrentWeight())
    
    if not NullInventory.currentChest then return end
    
    if inventory.id == NullInventory.currentChest.data.id then
        NullInventory.currentChest.data = data
        NullInventory.currentChest.weight = inventory.weight
        
        TriggerEvent("inventory:right:changeWeight", inventory.weight)
        
        local rightInventory = FormatInventoryForUI(data)
        TriggerEvent("esx:refreshRightInventory", rightInventory)
    end
end)

UpdateInventoryStats = LPH_JIT(function()
    if not NullInventory.isOpen then return end
    
    local ped = PlayerPedId()
    local health = math.max(0, (GetEntityHealth(ped) - 100))
    local stamina = GetPlayerStamina(PlayerId())
    local oxygen = GetPlayerUnderwaterTimeRemaining(PlayerId()) * 10
    
    local stats = {
        health = health,
        stamina = stamina,
        oxygen = oxygen,
    }
    
    pcall(function()
        stats.hunger = exports["null-core"]:getStatus("hunger") / 10000
        stats.thirst = exports["null-core"]:getStatus("thirst") / 10000
        stats.alcohol = exports["null-core"]:getStatus("drunk") / 10000
        stats.drug = exports["null-core"]:getStatus("drug") / 10000
    end)
    
    SendNUIMessage({
        type = "inventory:updateStats",
        data = stats
    })
end)

RegisterNUICallback("inventory:searchFocus", function(data, cb)
    pcall(function()
        exports["null-core"]:setChatCanOpen(false)
    end)
    exports["null-core"]:ActiveFrontend(true)
    cb({})
end)

RegisterNUICallback("inventory:searchBlur", function(data, cb)
    exports["null-core"]:ActiveFrontend(false)
    pcall(function()
        exports["null-core"]:setChatCanOpen(true)
    end)
    cb({})
end)

RegisterNUICallback("inventory:destroyPreviewPed", function(data, cb)
    DestroyInventoryPed()
    TimeoutPoly()
    cb({})
end)

AddEventHandler("null:inventory:createClonePed", function()
    SetTimeout(120, CreateInventoryPed)
end)

AddEventHandler("null:inventory:destroyClonePed", function()
    DestroyInventoryPed()
end)

AddEventHandler("null:inventory:refreshClonePed", function()
    RefreshInventoryPed()
end)

exports('CreateInventoryPed', CreateInventoryPed)
exports('DestroyInventoryPed', DestroyInventoryPed)
exports('RefreshInventoryPed', RefreshInventoryPed)
exports('FormatInventoryForUI', FormatInventoryForUI)

_G.NullInventoryUILoaded = true
