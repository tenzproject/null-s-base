while not _G.InventoryClothesLoaded do
    Wait(0)
end

local Backpacks = {}
local BackpackCache = {} -- [identifier_clotheId] = { items = {}, loadout = {}, cash = 0, dirtycash = 0 }
local BackpackDirty = {} -- [cacheKey] = true si modifié depuis dernier save
local BackpackExists = {} -- [cacheKey] = true si la row existe en DB

-- SQL Migration: create vbackpacks table
MySQL.ready(function()
    MySQL.Async.execute([[
        CREATE TABLE IF NOT EXISTS `vbackpacks` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `identifier` VARCHAR(60) NOT NULL,
            `clothe_id` INT NOT NULL,
            `bag_value` INT NOT NULL DEFAULT 0,
            `bag_texture` INT NOT NULL DEFAULT 0,
            `custom_name` VARCHAR(255) DEFAULT NULL,
            `contents` LONGTEXT,
            `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `unique_bag` (`identifier`, `clothe_id`),
            INDEX `idx_identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]], {}, function()
        -- Older MySQL/MariaDB versions do not support ADD COLUMN IF NOT EXISTS.
        local function ensureColumn(columnName, definition, afterColumn, cb)
            MySQL.Async.fetchScalar([[
                SELECT COUNT(*)
                FROM information_schema.columns
                WHERE table_schema = DATABASE()
                  AND table_name = 'vbackpacks'
                  AND column_name = @columnName
            ]], { ['@columnName'] = columnName }, function(columnExists)
                if tonumber(columnExists) == 0 then
                    MySQL.Async.execute(
                        'ALTER TABLE `vbackpacks` ADD COLUMN `' .. columnName .. '` ' .. definition .. ' AFTER `' .. afterColumn .. '`',
                        {},
                        cb
                    )
                else
                    cb()
                end
            end)
        end

        ensureColumn('bag_value', 'INT NOT NULL DEFAULT 0', 'clothe_id', function()
            ensureColumn('bag_texture', 'INT NOT NULL DEFAULT 0', 'bag_value', function()
                ensureColumn('custom_name', 'VARCHAR(255) DEFAULT NULL', 'bag_texture', function()
                    ensureColumn('slot', 'INT DEFAULT NULL', 'custom_name', function()
                        --null.DebugPrint("[Backpacks] SQL migration complete")
                    end)
                end)
            end)
        end)
    end)
end)

local function normalizeBagSlots(bags)
    local used = {}
    local nextSlot = 1

    for _, bag in ipairs(bags or {}) do
        local slot = tonumber(bag.slot)
        if slot and slot > 0 and not used[slot] then
            bag.slot = slot
            used[slot] = true
        else
            while used[nextSlot] do
                nextSlot = nextSlot + 1
            end
            bag.slot = nextSlot
            used[nextSlot] = true
        end
    end
end

local function GetCacheKey(identifier, clotheId)
    return identifier .. "_" .. tostring(clotheId)
end

local function GetBagMaxWeight(playerSex, bagValue)
    if Config.ListBags then
        if Config.ListBags[playerSex] then
            local bagConfig = Config.ListBags[playerSex][bagValue]
            if bagConfig then
                if bagConfig.weight then
                    return bagConfig.weight
                end
            end
        end
    end
    
    local defaultWeight = Config.Backpacks.DefaultWeight or 15
    return defaultWeight
end

local function CalculateBackpackWeight(contents)
    local weight = 0
    if contents.items then
        for _, item in pairs(contents.items) do
            local itemWeight = item.weight or 1
            if ESX.Items[item.name] then
                itemWeight = ESX.Items[item.name].weight or 1
            end
            weight = weight + (itemWeight * (item.count or 1))
        end
    end
    if contents.loadout then
        for _, weapon in pairs(contents.loadout) do
            if not ESX.ContribWeapon(weapon.name) then
                weight = weight + (ESX.GetWeaponWeight(weapon.name) or Config.WeaponDefaultWeight)
            end
        end
    end
    return weight
end

local function EnrichItems(items)
    local enriched = {}
    for k, v in pairs(items) do
        local itemData = ESX.Items[v.name]
        enriched[k] = {
            name = v.name,
            count = v.count or 1,
            weight = itemData and itemData.weight or 1,
            label = ESX.GetItemLabel(v.name) or v.label or v.name,
            unique = itemData and itemData.unique or v.unique or false,
            metadata = v.metadata or {},
            extra = v.extra,
        }
    end
    return enriched
end

local function EnrichLoadout(loadout)
    local enriched = {}
    for k, v in pairs(loadout) do
        enriched[k] = {
            name = v.name,
            label = ESX.GetWeaponLabel(v.name) or v.label or v.name,
            metadata = v.metadata or {},
            permanent = v.permanent or false,
            serialnumber = v.serialnumber,
            durability = Config.AmmunationShop.repairSysteme and v.durability or 0,
            components = v.components or {},
        }
    end
    return enriched
end

-- Load backpack contents
function Backpacks.Load(playerId, clotheId, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, "Joueur introuvable") end
    
    local identifier = xPlayer.identifier
    local cacheKey = GetCacheKey(identifier, clotheId)
    
    -- Check cache first
    if BackpackCache[cacheKey] then
        return cb(true, BackpackCache[cacheKey])
    end
    
    MySQL.Async.fetchAll('SELECT contents FROM vbackpacks WHERE identifier = @identifier AND clothe_id = @clotheId', {
        ['@identifier'] = identifier,
        ['@clotheId'] = clotheId,
    }, function(result)
        local contents = { items = {}, loadout = {}, cash = 0, dirtycash = 0 }
        
        if result and result[1] then
            local parsed = json.decode(result[1].contents)
            if parsed then
                contents.items = EnrichItems(parsed.items or {})
                contents.loadout = EnrichLoadout(parsed.loadout or {})
                contents.cash = parsed.cash or 0
                contents.dirtycash = parsed.dirtycash or 0
            end
            BackpackExists[cacheKey] = true
        else
            -- Create entry if it doesn't exist
            MySQL.Async.execute('INSERT IGNORE INTO vbackpacks (identifier, clothe_id, contents) VALUES (@identifier, @clotheId, @contents)', {
                ['@identifier'] = identifier,
                ['@clotheId'] = clotheId,
                ['@contents'] = '{}',
            })
            BackpackExists[cacheKey] = true
        end
        
        BackpackCache[cacheKey] = contents
        BackpackDirty[cacheKey] = false
        cb(true, contents)
    end)
end

-- Save backpack contents
function Backpacks.Save(identifier, clotheId)
    local cacheKey = GetCacheKey(identifier, clotheId)
    local cached = BackpackCache[cacheKey]
    if not cached then return end
    if not BackpackDirty[cacheKey] then return end
    
    local saveData = {}
    
    if (cached.cash or 0) > 0 then saveData.cash = cached.cash end
    if (cached.dirtycash or 0) > 0 then saveData.dirtycash = cached.dirtycash end
    
    local minItems = {}
    for _, item in pairs(cached.items or {}) do
        local entry = { name = item.name, count = item.count }
        local meta = item.metadata
        if meta and type(meta) == 'table' and next(meta) then entry.metadata = meta end
        if item.unique then entry.unique = true end
        if item.unique and item.extra then entry.extra = item.extra end
        minItems[#minItems + 1] = entry
    end
    if #minItems > 0 then saveData.items = minItems end
    
    local minLoadout = {}
    for _, weapon in pairs(cached.loadout or {}) do
        local entry = { name = weapon.name }
        local meta = weapon.metadata
        if meta and type(meta) == 'table' and next(meta) then entry.metadata = meta end
        if weapon.serialnumber then entry.serialnumber = weapon.serialnumber end
        if weapon.permanent then entry.permanent = true end
        if weapon.durability and weapon.durability ~= 0 then entry.durability = weapon.durability end
        if weapon.components and #weapon.components > 0 then entry.components = weapon.components end
        minLoadout[#minLoadout + 1] = entry
    end
    if #minLoadout > 0 then saveData.loadout = minLoadout end
    
    local encoded = json.encode(saveData)
    
    if BackpackExists[cacheKey] then
        MySQL.Async.execute('UPDATE vbackpacks SET contents = @contents WHERE identifier = @identifier AND clothe_id = @clotheId', {
            ['@identifier'] = identifier,
            ['@clotheId'] = clotheId,
            ['@contents'] = encoded,
        })
    else
        MySQL.Async.execute('INSERT INTO vbackpacks (identifier, clothe_id, contents) VALUES (@identifier, @clotheId, @contents) ON DUPLICATE KEY UPDATE contents = @contents', {
            ['@identifier'] = identifier,
            ['@clotheId'] = clotheId,
            ['@contents'] = encoded,
        })
        BackpackExists[cacheKey] = true
    end
    
    BackpackDirty[cacheKey] = false
end

-- Check if an item can go in a backpack
function Backpacks.CanAddItem(itemName, itemType)
    -- No bags in bags
    if itemType == "bag" or itemType == "accessory" then
        -- Check if it's a bag accessory
        local slot = nil
        for _, s in ipairs(Config.Outfits.ClothesTypes or {}) do
            if s == "bag" and itemType == "accessory" then
                return false
            end
        end
    end
    
    if Config.Backpacks.ForbiddenItems and Config.Backpacks.ForbiddenItems[itemName] then
        return false
    end
    
    return true
end

-- Transfer item from player to backpack
function Backpacks.AddItem(playerId, clotheId, itemName, count, itemExtra, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, "Joueur introuvable") end
    
    local identifier = xPlayer.identifier
    local cacheKey = GetCacheKey(identifier, clotheId)
    
    Backpacks.Load(playerId, clotheId, function(success, contents)
        if not success then return cb(false, "Impossible de charger le sac") end
        
        -- Get bag_value from vbackpacks table
        MySQL.Async.fetchScalar('SELECT bag_value FROM vbackpacks WHERE clothe_id = @clotheId AND identifier = @identifier', {
            ['@clotheId'] = clotheId,
            ['@identifier'] = identifier
        }, function(bagValue)
            bagValue = bagValue or 0
            
            -- Check max weight
            local sex = tonumber(xPlayer.sex) or 0
            local playerSex = sex == 0 and "male" or "female"
            local maxWeight = GetBagMaxWeight(playerSex, bagValue)
        
        local itemWeight = ESX.Items[itemName] and ESX.Items[itemName].weight or 1
        local currentWeight = CalculateBackpackWeight(contents)
        
        if currentWeight + (itemWeight * count) > maxWeight then
            return cb(false, "Le sac est trop lourd")
        end
        
        -- Check player has item
        local itemId = itemExtra and itemExtra.identifier or nil
        local playerItem, itemIndex = xPlayer.getInventoryItem(itemName, itemId)
        
        if not playerItem or playerItem.count < count then
            return cb(false, "Vous n'avez pas assez de cet item")
        end
        
        -- Add to backpack
        local found = false
        if not playerItem.unique then
            for k, v in pairs(contents.items) do
                if v.name == itemName then
                    contents.items[k].count = v.count + count
                    found = true
                    break
                end
            end
        end
        
        if not found then
            table.insert(contents.items, {
                name = itemName,
                count = count,
                weight = itemWeight,
                label = ESX.GetItemLabel(itemName),
                metadata = playerItem.metadata or {},
                extra = playerItem.extra,
                unique = playerItem.unique,
            })
        end
        
            -- Remove from player
            if playerItem.unique then
                xPlayer.removeInventoryItem(itemName, count, itemId)
            else
                xPlayer.removeInventoryItem(itemName, count)
            end
            
            BackpackCache[cacheKey] = contents
            BackpackDirty[cacheKey] = true
            Backpacks.Save(identifier, clotheId)
            
            cb(true, contents, CalculateBackpackWeight(contents), maxWeight)
        end)
    end)
end

-- Transfer item from backpack to player
function Backpacks.RemoveItem(playerId, clotheId, itemName, count, itemExtra, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, "Joueur introuvable") end
    
    local identifier = xPlayer.identifier
    local cacheKey = GetCacheKey(identifier, clotheId)
    
    Backpacks.Load(playerId, clotheId, function(success, contents)
        if not success then return cb(false, "Impossible de charger le sac") end
        
        -- Find item in backpack
        local bagItem = nil
        local bagItemIndex = nil
        for k, v in pairs(contents.items) do
            if v.name == itemName then
                bagItem = v
                bagItemIndex = k
                break
            end
        end
        
        if not bagItem or bagItem.count < count then
            return cb(false, "Item introuvable dans le sac")
        end
        
        -- Check player can carry
        if not xPlayer.canCarryItem(itemName, count) then
            return cb(false, "Inventaire trop lourd")
        end
        
        -- Remove from backpack
        if bagItem.count <= count then
            contents.items[bagItemIndex] = nil
            -- Reindex table
            local newItems = {}
            for _, v in pairs(contents.items) do
                if v then table.insert(newItems, v) end
            end
            contents.items = newItems
        else
            contents.items[bagItemIndex].count = bagItem.count - count
        end
        
        -- Add to player
        xPlayer.addInventoryItem(itemName, count, bagItem.metadata)
        
        BackpackCache[cacheKey] = contents
        BackpackDirty[cacheKey] = true
        Backpacks.Save(identifier, clotheId)
        
        -- Get bag_value from vbackpacks table
        MySQL.Async.fetchScalar('SELECT bag_value FROM vbackpacks WHERE clothe_id = @clotheId AND identifier = @identifier', {
            ['@clotheId'] = clotheId,
            ['@identifier'] = identifier
        }, function(bagValue)
            bagValue = bagValue or 0
            local sex = tonumber(xPlayer.sex) or 0
            local playerSex = sex == 0 and "male" or "female"
            local maxWeight = GetBagMaxWeight(playerSex, bagValue)
            
            cb(true, contents, CalculateBackpackWeight(contents), maxWeight)
        end)
    end)
end

-- Transfer weapon from player to backpack
function Backpacks.AddWeapon(playerId, clotheId, weaponName, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, "Joueur introuvable") end
    
    local identifier = xPlayer.identifier
    local cacheKey = GetCacheKey(identifier, clotheId)
    
    Backpacks.Load(playerId, clotheId, function(success, contents)
        if not success then return cb(false, "Impossible de charger le sac") end
        
        -- Get bag_value from vbackpacks table
        MySQL.Async.fetchScalar('SELECT bag_value FROM vbackpacks WHERE clothe_id = @clotheId AND identifier = @identifier', {
            ['@clotheId'] = clotheId,
            ['@identifier'] = identifier
        }, function(bagValue)
            bagValue = bagValue or 0
            local sex = tonumber(xPlayer.sex) or 0
            local playerSex = sex == 0 and "male" or "female"
            
            -- Check if bag allows weapons
            if Config.ListBags and Config.ListBags[playerSex] and Config.ListBags[playerSex][bagValue] then
                if not Config.ListBags[playerSex][bagValue].weapon then
                    return cb(false, "Ce sac ne peut pas contenir d'armes")
                end
            end
            
            local maxWeight = GetBagMaxWeight(playerSex, bagValue)
        local weaponWeight = ESX.GetWeaponWeight(weaponName) or Config.WeaponDefaultWeight
        local currentWeight = CalculateBackpackWeight(contents)
        
        if currentWeight + weaponWeight > maxWeight then
            return cb(false, "Le sac est trop lourd")
        end
        
        -- Find weapon in player loadout
        local weaponData = nil
        for _, w in pairs(xPlayer.getLoadout()) do
            if w.name == weaponName then
                weaponData = w
                break
            end
        end
        
        if not weaponData then
            return cb(false, "Arme introuvable")
        end
        
        -- Add to backpack
        table.insert(contents.loadout, {
            name = weaponData.name,
            label = ESX.GetWeaponLabel(weaponData.name) or weaponData.name,
            metadata = weaponData.metadata or {},
            serialnumber = weaponData.serialnumber,
            durability = weaponData.durability,
            components = weaponData.components or {},
        })
        
            -- Remove from player
            xPlayer.removeWeapon(weaponName)
            
            BackpackCache[cacheKey] = contents
            BackpackDirty[cacheKey] = true
            Backpacks.Save(identifier, clotheId)
            
            cb(true, contents, CalculateBackpackWeight(contents), maxWeight)
        end)
    end)
end

-- Transfer weapon from backpack to player
function Backpacks.RemoveWeapon(playerId, clotheId, weaponName, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, "Joueur introuvable") end
    
    local identifier = xPlayer.identifier
    local cacheKey = GetCacheKey(identifier, clotheId)
    
    Backpacks.Load(playerId, clotheId, function(success, contents)
        if not success then return cb(false, "Impossible de charger le sac") end
        
        -- Find weapon in backpack
        local weaponData = nil
        local weaponIndex = nil
        for k, v in pairs(contents.loadout) do
            if v.name == weaponName then
                weaponData = v
                weaponIndex = k
                break
            end
        end
        
        if not weaponData then
            return cb(false, "Arme introuvable dans le sac")
        end
        
        -- Remove from backpack
        table.remove(contents.loadout, weaponIndex)
        
        -- Add to player with preserved metadata
        -- xPlayer.addWeapon(weaponName, ammo, metadata, permanent, serialNumber, durability, components)
        local ammo = weaponData.metadata and weaponData.metadata.ammo or 0
        local metadata = weaponData.metadata or {}
        local serialNumber = weaponData.serialnumber or nil
        local durability = weaponData.durability or 0.0
        local components = weaponData.components or {}
        
        xPlayer.addWeapon(weaponName, ammo, metadata, false, serialNumber, durability, components)
        
        BackpackCache[cacheKey] = contents
        BackpackDirty[cacheKey] = true
        Backpacks.Save(identifier, clotheId)
        
        -- Get bag_value from vbackpacks table
        MySQL.Async.fetchScalar('SELECT bag_value FROM vbackpacks WHERE clothe_id = @clotheId AND identifier = @identifier', {
            ['@clotheId'] = clotheId,
            ['@identifier'] = identifier
        }, function(bagValue)
            bagValue = bagValue or 0
            local sex = tonumber(xPlayer.sex) or 0
            local playerSex = sex == 0 and "male" or "female"
            local maxWeight = GetBagMaxWeight(playerSex, bagValue)
            
            cb(true, contents, CalculateBackpackWeight(contents), maxWeight)
        end)
    end)
end

-- Transfer money to/from backpack
function Backpacks.TransferMoney(playerId, clotheId, moneyType, amount, toBackpack, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, "Joueur introuvable") end
    
    local identifier = xPlayer.identifier
    local cacheKey = GetCacheKey(identifier, clotheId)
    
    if moneyType ~= "cash" and moneyType ~= "dirtycash" then
        return cb(false, "Type d'argent invalide")
    end
    
    if amount <= 0 then return cb(false, "Montant invalide") end
    
    Backpacks.Load(playerId, clotheId, function(success, contents)
        if not success then return cb(false, "Impossible de charger le sac") end
        
        if toBackpack then
            local accountName = moneyType == "cash" and "cash" or "dirtycash"
            if xPlayer.getAccount(accountName).money < amount then
                return cb(false, "Vous n'avez pas assez d'argent")
            end
            xPlayer.removeAccountMoney(accountName, amount)
            contents[moneyType] = (contents[moneyType] or 0) + amount
        else
            if (contents[moneyType] or 0) < amount then
                return cb(false, "Pas assez d'argent dans le sac")
            end
            contents[moneyType] = contents[moneyType] - amount
            local accountName = moneyType == "cash" and "cash" or "dirtycash"
            xPlayer.addAccountMoney(accountName, amount)
        end
        
        BackpackCache[cacheKey] = contents
        BackpackDirty[cacheKey] = true
        Backpacks.Save(identifier, clotheId)
        
        cb(true, contents)
    end)
end

-- Get backpack preview (contents summary without full load)
function Backpacks.GetPreview(playerId, clotheId, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false) end
    
    local identifier = xPlayer.identifier
    local cacheKey = GetCacheKey(identifier, clotheId)
    
    if BackpackCache[cacheKey] then
        local contents = BackpackCache[cacheKey]
        local weight = CalculateBackpackWeight(contents)
        local sex = tonumber(xPlayer.sex) or 0
        local playerSex = sex == 0 and "male" or "female"
        local equipped = xPlayer.clothes_equiped or {}
        local bagData = equipped["bag"]
        local bagValue = 0
        if bagData and bagData.data and bagData.data["bags_1"] then
            bagValue = bagData.data["bags_1"]
        end
        local maxWeight = GetBagMaxWeight(playerSex, bagValue)
        
        return cb(true, {
            itemCount = #(contents.items or {}),
            weaponCount = #(contents.loadout or {}),
            cash = contents.cash or 0,
            dirtycash = contents.dirtycash or 0,
            weight = weight,
            maxWeight = maxWeight,
        })
    end
    
    MySQL.Async.fetchAll('SELECT contents FROM vbackpacks WHERE identifier = @identifier AND clothe_id = @clotheId', {
        ['@identifier'] = xPlayer.identifier,
        ['@clotheId'] = clotheId,
    }, function(result)
        if result and result[1] then
            local contents = json.decode(result[1].contents) or {}
            local weight = CalculateBackpackWeight(contents)
            local sex = tonumber(xPlayer.sex) or 0
            local playerSex = sex == 0 and "male" or "female"
            local equipped = xPlayer.clothes_equiped or {}
            local bagData = equipped["bag"]
            local bagValue = 0
            if bagData and bagData.data and bagData.data["bags_1"] then
                bagValue = bagData.data["bags_1"]
            end
            local maxWeight = GetBagMaxWeight(playerSex, bagValue)
            
            cb(true, {
                itemCount = #(contents.items or {}),
                weaponCount = #(contents.loadout or {}),
                cash = contents.cash or 0,
                dirtycash = contents.dirtycash or 0,
                weight = weight,
                maxWeight = maxWeight,
            })
        else
            cb(true, { itemCount = 0, weaponCount = 0, cash = 0, dirtycash = 0, weight = 0, maxWeight = 15 })
        end
    end)
end

-- Count how many backpacks a player has
function Backpacks.CountPlayerBackpacks(identifier, cb)
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM vbackpacks WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(count)
        cb(count or 0)
    end)
end

-- Get all player backpacks
function Backpacks.GetPlayerBackpacks(identifier, cb)
    MySQL.Async.fetchAll('SELECT clothe_id, bag_value, bag_texture FROM vbackpacks WHERE identifier = @identifier', {
        ['@identifier'] = identifier
    }, function(results)
        cb(results or {})
    end)
end

-- Transfer bag ownership from one player to another
function Backpacks.TransferOwnership(fromIdentifier, toIdentifier, clotheId, cb)
    -- Check if target player can receive more bags
    Backpacks.CountPlayerBackpacks(toIdentifier, function(count)
        if count >= 3 then
            return cb(false, "Le joueur cible a déjà 3 sacs")
        end
        
        -- Update ownership in database
        MySQL.Async.execute('UPDATE vbackpacks SET identifier = @newIdentifier WHERE identifier = @oldIdentifier AND clothe_id = @clotheId', {
            ['@newIdentifier'] = toIdentifier,
            ['@oldIdentifier'] = fromIdentifier,
            ['@clotheId'] = clotheId
        }, function(affectedRows)
            if affectedRows > 0 then
                -- Clear cache for old owner
                local oldCacheKey = GetCacheKey(fromIdentifier, clotheId)
                BackpackCache[oldCacheKey] = nil
                
                cb(true)
            else
                cb(false, "Sac introuvable")
            end
        end)
    end)
end

-- Get bag weight for inventory display (contents weight / divisor)
function Backpacks.GetBagInventoryWeight(identifier, clotheId, cb)
    local cacheKey = GetCacheKey(identifier, clotheId)
    
    if BackpackCache[cacheKey] then
        local weight = CalculateBackpackWeight(BackpackCache[cacheKey])
        local divisor = Config.Backpacks.WeightDivisor or 2
        cb(weight / divisor)
        return
    end
    
    MySQL.Async.fetchScalar('SELECT contents FROM vbackpacks WHERE identifier = @identifier AND clothe_id = @clotheId', {
        ['@identifier'] = identifier,
        ['@clotheId'] = clotheId
    }, function(contentsJson)
        if contentsJson then
            local contents = json.decode(contentsJson) or {}
            local weight = CalculateBackpackWeight(contents)
            local divisor = Config.Backpacks.WeightDivisor or 2
            cb(weight / divisor)
        else
            cb(0)
        end
    end)
end

-- Check if a bag belongs to a player
function Backpacks.BelongsToPlayer(identifier, clotheId, cb)
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM vbackpacks WHERE identifier = @identifier AND clothe_id = @clotheId', {
        ['@identifier'] = identifier,
        ['@clotheId'] = clotheId
    }, function(count)
        cb(count and count > 0)
    end)
end

-- Register a new backpack when player receives/buys one
function Backpacks.RegisterBackpack(identifier, clotheId, bagValue, bagTexture, cb)
    -- Check if player already has 3 backpacks
    Backpacks.CountPlayerBackpacks(identifier, function(count)
        if count >= 3 then
            return cb(false, "Vous avez déjà 3 sacs, vous ne pouvez pas en avoir plus")
        end
        
        -- Create backpack entry
        MySQL.Async.execute('INSERT IGNORE INTO vbackpacks (identifier, clothe_id, bag_value, bag_texture, contents) VALUES (@identifier, @clotheId, @bagValue, @bagTexture, @contents)', {
            ['@identifier'] = identifier,
            ['@clotheId'] = clotheId,
            ['@bagValue'] = bagValue or 0,
            ['@bagTexture'] = bagTexture or 0,
            ['@contents'] = '{}'
        }, function(affectedRows)
            local cacheKey = GetCacheKey(identifier, clotheId)
            BackpackExists[cacheKey] = true
            cb(true)
        end)
    end)
end

-- Delete a backpack
function Backpacks.DeleteBackpack(identifier, clotheId)
    local cacheKey = GetCacheKey(identifier, clotheId)
    BackpackCache[cacheKey] = nil
    BackpackDirty[cacheKey] = nil
    BackpackExists[cacheKey] = nil
    
    MySQL.Async.execute('DELETE FROM vbackpacks WHERE identifier = @identifier AND clothe_id = @clotheId', {
        ['@identifier'] = identifier,
        ['@clotheId'] = clotheId
    })
end

function Backpacks.MoveSlot(playerId, clotheId, fromSlot, toSlot, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false) end

    clotheId = tonumber(clotheId)
    fromSlot = tonumber(fromSlot)
    toSlot = tonumber(toSlot)

    if not clotheId or not fromSlot or not toSlot or fromSlot < 1 or toSlot < 1 or toSlot > 200 then
        return cb(false)
    end

    local identifier = xPlayer.identifier

    MySQL.Async.fetchAll('SELECT clothe_id, slot FROM vbackpacks WHERE identifier = @identifier', {
        ['@identifier'] = identifier,
    }, function(results)
        local bags = {}
        local fromBag = nil
        local targetBag = nil

        for _, row in ipairs(results or {}) do
            bags[#bags + 1] = {
                clotheId = tonumber(row.clothe_id),
                slot = tonumber(row.slot),
            }
        end

        normalizeBagSlots(bags)

        for _, bag in ipairs(bags) do
            if bag.clotheId == clotheId then
                fromBag = bag
            end

            if tonumber(bag.slot) == toSlot then
                targetBag = bag
            end
        end

        if not fromBag or fromBag == targetBag then
            return cb(false)
        end

        local oldSlot = tonumber(fromBag.slot) or fromSlot
        fromBag.slot = toSlot
        if targetBag then
            targetBag.slot = oldSlot
        end

        local pending = 0
        local failed = false

        local function updateSlot(bag)
            pending = pending + 1
            MySQL.Async.execute('UPDATE vbackpacks SET slot = @slot WHERE clothe_id = @clotheId AND identifier = @identifier', {
                ['@slot'] = bag.slot,
                ['@clotheId'] = bag.clotheId,
                ['@identifier'] = identifier,
            }, function(rowsChanged)
                if not rowsChanged or rowsChanged < 1 then
                    failed = true
                end

                pending = pending - 1
                if pending == 0 then
                    cb(not failed)
                end
            end)
        end

        for _, bag in ipairs(bags) do
            updateSlot(bag)
        end
    end)
end

-- Clear cache on player disconnect
function Backpacks.ClearPlayerCache(identifier)
    local toRemove = {}
    for key, _ in pairs(BackpackCache) do
        if key:find("^" .. identifier) then
            table.insert(toRemove, key)
        end
    end
    for _, key in ipairs(toRemove) do
        BackpackCache[key] = nil
        BackpackDirty[key] = nil
        BackpackExists[key] = nil
    end
end

-- Server callbacks
ESX.RegisterServerCallback('null:backpack:load', function(source, cb, clotheId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return cb(false)
    end
    
    MySQL.Async.fetchScalar('SELECT bag_value FROM vbackpacks WHERE clothe_id = @clotheId AND identifier = @identifier', {
        ['@clotheId'] = clotheId,
        ['@identifier'] = xPlayer.identifier
    }, function(bagValue)
        bagValue = bagValue or 0
        local sex = tonumber(xPlayer.sex) or 0
        local playerSex = sex == 0 and "male" or "female"
        local maxWeight = GetBagMaxWeight(playerSex, bagValue)
        
        Backpacks.Load(source, clotheId, function(success, contents)
        if success then
            local weight = CalculateBackpackWeight(contents)
            -- Convert items for UI
            local uiItems = {}
            for _, item in pairs(contents.items or {}) do
                table.insert(uiItems, {
                    type = "item",
                    name = item.name,
                    label = item.label,
                    count = item.count,
                    weight = item.weight,
                    metadata = item.metadata,
                    extra = item.extra,
                    unique = item.unique,
                })
            end
            for _, weapon in pairs(contents.loadout or {}) do
                table.insert(uiItems, {
                    type = "weapon",
                    name = weapon.name,
                    label = weapon.label,
                    count = 1,
                    metadata = weapon.metadata,
                    serialnumber = weapon.serialnumber,
                    durability = weapon.durability,
                })
            end
            if (contents.cash or 0) > 0 then
                table.insert(uiItems, { type = "cash", name = "cash", label = "Argent", count = contents.cash })
            end
            if (contents.dirtycash or 0) > 0 then
                table.insert(uiItems, { type = "dirtycash", name = "dirtycash", label = "Argent Sale", count = contents.dirtycash })
            end
            cb(true, uiItems, weight, maxWeight)
        else
            cb(false)
        end
    end)
    end)
end)

ESX.RegisterServerCallback('null:backpack:addItem', function(source, cb, clotheId, itemName, count, itemExtra)
    Backpacks.AddItem(source, clotheId, itemName, count, itemExtra, function(success, contents, weight, maxWeight)
        cb(success, weight, maxWeight)
    end)
end)

ESX.RegisterServerCallback('null:backpack:removeItem', function(source, cb, clotheId, itemName, count, itemExtra)
    Backpacks.RemoveItem(source, clotheId, itemName, count, itemExtra, function(success, contents, weight, maxWeight)
        cb(success, weight, maxWeight)
    end)
end)

ESX.RegisterServerCallback('null:backpack:addWeapon', function(source, cb, clotheId, weaponName)
    Backpacks.AddWeapon(source, clotheId, weaponName, function(success, contents, weight, maxWeight)
        cb(success, weight, maxWeight)
    end)
end)

ESX.RegisterServerCallback('null:backpack:removeWeapon', function(source, cb, clotheId, weaponName)
    Backpacks.RemoveWeapon(source, clotheId, weaponName, function(success, contents, weight, maxWeight)
        cb(success, weight, maxWeight)
    end)
end)

ESX.RegisterServerCallback('null:backpack:transferMoney', function(source, cb, clotheId, moneyType, amount, toBackpack)
    Backpacks.TransferMoney(source, clotheId, moneyType, amount, toBackpack, function(success, contents)
        cb(success)
    end)
end)

ESX.RegisterServerCallback('null:backpack:preview', function(source, cb, clotheId)
    Backpacks.GetPreview(source, clotheId, function(success, preview)
        cb(success, preview)
    end)
end)

ESX.RegisterServerCallback('null:backpack:canReceive', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end
    
    Backpacks.CountPlayerBackpacks(xPlayer.identifier, function(count)
        cb(count < 3, count)
    end)
end)

ESX.RegisterServerCallback('null:backpack:register', function(source, cb, clotheId, bagValue, bagTexture)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false, "Joueur introuvable") end
    
    Backpacks.RegisterBackpack(xPlayer.identifier, clotheId, bagValue, bagTexture, function(success, message)
        cb(success, message)
    end)
end)

ESX.RegisterServerCallback('null:backpack:getAllBags', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then
        return cb({})
    end
    
    MySQL.Async.fetchAll([[
        SELECT 
            clothe_id,
            bag_value,
            bag_texture,
            custom_name,
            slot
        FROM vbackpacks
        WHERE identifier = @identifier
    ]], {
        ['@identifier'] = xPlayer.identifier
    }, function(results)
        local bags = {}
        local sex = tonumber(xPlayer.sex) or 0
        local playerSex = sex == 0 and "male" or "female"

        for _, row in ipairs(results or {}) do
            local maxWeight = GetBagMaxWeight(playerSex, row.bag_value)
            local canHoldWeapons = false
            local bagName = row.custom_name or "Sac à dos"
            
            if Config.ListBags and Config.ListBags[playerSex] and Config.ListBags[playerSex][row.bag_value] then
                local bagConfig = Config.ListBags[playerSex][row.bag_value]
                canHoldWeapons = bagConfig.weapon or false
                -- Use custom name if available, otherwise use config label
                if not row.custom_name or row.custom_name == "" then
                    bagName = bagConfig.label or "Sac à dos"
                end
            end
            
            table.insert(bags, {
                clotheId = row.clothe_id,
                bagValue = row.bag_value,
                bagTexture = row.bag_texture,
                name = "bag_" .. row.clothe_id,
                label = bagName,
                type = "bag",
                maxWeight = maxWeight,
                canHoldWeapons = canHoldWeapons,
                slot = row.slot,
            })
        end

        normalizeBagSlots(bags)
        cb(bags)
    end)
end)

ESX.RegisterServerCallback('null:backpack:transferOwnership', function(source, cb, targetPlayerId, clotheId)
    local xPlayer = ESX.GetPlayerFromId(source)
    local tPlayer = ESX.GetPlayerFromId(targetPlayerId)
    
    if not xPlayer or not tPlayer then
        return cb(false, "Joueur introuvable")
    end
    
    Backpacks.TransferOwnership(xPlayer.identifier, tPlayer.identifier, clotheId, function(success, message)
        cb(success, message)
    end)
end)

ESX.RegisterServerCallback('null:backpack:getBagWeight', function(source, cb, clotheId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(0) end
    
    Backpacks.GetBagInventoryWeight(xPlayer.identifier, clotheId, function(weight)
        cb(weight)
    end)
end)

ESX.RegisterServerCallback('null:backpack:belongsToPlayer', function(source, cb, clotheId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end
    
    Backpacks.BelongsToPlayer(xPlayer.identifier, clotheId, function(belongs)
        cb(belongs)
    end)
end)

RegisterNetEvent('null:backpack:giveToPlayer')
AddEventHandler('null:backpack:giveToPlayer', function(targetPlayerId, clotheId, itemName)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local tPlayer = ESX.GetPlayerFromId(targetPlayerId)
    
    if not xPlayer or not tPlayer then
        return TriggerClientEvent("inventory:sendMessage", _source, "~r~Joueur introuvable")
    end
    
    -- Verify bag belongs to source player
    Backpacks.BelongsToPlayer(xPlayer.identifier, clotheId, function(belongs)
        if not belongs then
            return TriggerClientEvent("inventory:sendMessage", _source, "~r~Ce sac ne vous appartient pas")
        end
        
        -- Check if target can receive more bags
        Backpacks.CountPlayerBackpacks(tPlayer.identifier, function(count)
            if count >= 3 then
                return TriggerClientEvent("inventory:sendMessage", _source, "~r~Le joueur a déjà 3 sacs")
            end
            
            -- Remove bag accessory from source player
            local itemId = clotheId
            xPlayer.removeInventoryItem(itemName, 1, itemId)
            
            -- Transfer ownership in vbackpacks
            Backpacks.TransferOwnership(xPlayer.identifier, tPlayer.identifier, clotheId, function(success, message)
                if success then
                    -- Give bag accessory to target player
                    tPlayer.addInventoryItem(itemName, 1, { type2 = "bag", clotheId = clotheId })
                    
                    TriggerClientEvent("inventory:sendMessage", _source, "~g~Sac donné")
                    TriggerClientEvent("inventory:sendMessage", targetPlayerId, "~g~Sac reçu")
                    
                    -- Update inventories
                    TriggerClientEvent("null:inventory:update", _source)
                    TriggerClientEvent("null:inventory:update", targetPlayerId)
                else
                    -- Rollback - give item back to source
                    xPlayer.addInventoryItem(itemName, 1, { type2 = "bag", clotheId = clotheId })
                    TriggerClientEvent("inventory:sendMessage", _source, "~r~" .. (message or "Erreur lors du transfert"))
                end
            end)
        end)
    end)
end)

AddEventHandler("esx:playerDropped", function(playerId, reason)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if xPlayer then
        -- Save all open backpacks then clear cache
        for key, cached in pairs(BackpackCache) do
            if key:find("^" .. xPlayer.identifier) then
                local _, clotheId = key:match("^(.+)_(%d+)$")
                if clotheId then
                    Backpacks.Save(xPlayer.identifier, tonumber(clotheId))
                end
            end
        end
        Backpacks.ClearPlayerCache(xPlayer.identifier)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    -- Save all cached backpacks
    for key, cached in pairs(BackpackCache) do
        if type(cached) == "table" then
            local identifier, clotheId = key:match("^(.+)_(%d+)$")
            if identifier and clotheId then
                Backpacks.Save(identifier, tonumber(clotheId))
            end
        end
    end
end)

-- Drop a bag on the ground (delete from vbackpacks)
RegisterNetEvent('null:backpack:dropBag')
AddEventHandler('null:backpack:dropBag', function(clotheId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if not xPlayer then return end

    local identifier = xPlayer.identifier
    clotheId = tonumber(clotheId)
    if not clotheId then return end

    Backpacks.BelongsToPlayer(identifier, clotheId, function(belongs)
        if not belongs then
            return TriggerClientEvent("inventory:sendMessage", _source, "~r~Ce sac ne vous appartient pas")
        end

        -- Get bag info before deleting
        MySQL.Async.fetchAll('SELECT bag_value, bag_texture, custom_name FROM vbackpacks WHERE identifier = @identifier AND clothe_id = @clotheId', {
            ['@identifier'] = identifier,
            ['@clotheId'] = clotheId
        }, function(result)
            local bagLabel = "Sac à dos"
            if result and result[1] and result[1].custom_name then
                bagLabel = result[1].custom_name
            end

            -- Delete backpack and its contents
            Backpacks.DeleteBackpack(identifier, clotheId)

            -- Also remove from vclothes if it exists there
            MySQL.Async.execute('DELETE FROM vclothes WHERE id = @id AND identifier = @identifier', {
                ['@id'] = clotheId,
                ['@identifier'] = identifier
            })
            if _G.InventoryClothes and _G.InventoryClothes.ClearCache then
                _G.InventoryClothes.ClearCache(identifier)
            end

            TriggerClientEvent("null:inventory:update", _source)
            xPlayer.showAdvancedNotification("Informations", "Inventaire", ("Vous avez jeté %s"):format(bagLabel), 'CHAR_REDSIDE', 0, 7)
        end)
    end)
end)

-- Deposit a bag into a storage chest
ESX.RegisterServerCallback('null:backpack:depositToStorage', function(source, cb, cacheKey, clotheId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false, "Joueur introuvable") end

    clotheId = tonumber(clotheId)
    if not clotheId then return cb(false, "ID sac invalide") end

    local identifier = xPlayer.identifier

    -- Verify bag belongs to player
    Backpacks.BelongsToPlayer(identifier, clotheId, function(belongs)
        if not belongs then
            return cb(false, "Ce sac ne vous appartient pas")
        end

        -- Get the storage cache
        if not _G.InventoryCache then return cb(false, "Système de stockage indisponible") end
        local cached = _G.InventoryCache.Get(cacheKey)
        if not cached then return cb(false, "Coffre introuvable") end

        -- Get bag data for storage
        MySQL.Async.fetchAll('SELECT bag_value, bag_texture, custom_name, contents FROM vbackpacks WHERE identifier = @identifier AND clothe_id = @clotheId', {
            ['@identifier'] = identifier,
            ['@clotheId'] = clotheId
        }, function(result)
            if not result or not result[1] then
                return cb(false, "Sac introuvable")
            end

            local row = result[1]
            local contents = json.decode(row.contents) or {}
            local bagWeight = CalculateBackpackWeight(contents)
            local divisor = Config.Backpacks.WeightDivisor or 2
            local storageWeight = bagWeight / divisor

            -- Check storage space
            local maxWeight = cached.maxWeight or 0
            if maxWeight > 0 then
                local currentWeight = cached.weight or 0
                if currentWeight + storageWeight > maxWeight then
                    return cb(false, "Plus de place dans le coffre")
                end
            end

            -- Add bag reference to storage
            table.insert(cached.data.items, {
                name = "bag_" .. clotheId,
                count = 1,
                weight = storageWeight,
                label = row.custom_name or "Sac à dos",
                type = "accessory",
                type2 = "bag",
                metadata = {
                    clotheId = clotheId,
                    bagValue = row.bag_value,
                    bagTexture = row.bag_texture,
                    contents = row.contents,
                    type2 = "bag",
                },
                unique = true,
            })

            -- Delete from vbackpacks
            Backpacks.DeleteBackpack(identifier, clotheId)

            -- Also remove from vclothes if exists
            MySQL.Async.execute('DELETE FROM vclothes WHERE id = @id AND identifier = @identifier', {
                ['@id'] = clotheId,
                ['@identifier'] = identifier
            })
            if _G.InventoryClothes and _G.InventoryClothes.ClearCache then
                _G.InventoryClothes.ClearCache(identifier)
            end

            if _G.InventoryCache.UpdateWeight then
                _G.InventoryCache.UpdateWeight(cacheKey)
            end
            if _G.InventoryCache.MarkDirty then
                _G.InventoryCache.MarkDirty(cacheKey)
            end

            TriggerClientEvent("null:inventory:update", source)
            cb(true)
        end)
    end)
end)

-- Withdraw a bag from a storage chest
ESX.RegisterServerCallback('null:backpack:withdrawFromStorage', function(source, cb, cacheKey, bagItemName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false, "Joueur introuvable") end

    local identifier = xPlayer.identifier

    -- Check player can receive more bags
    Backpacks.CountPlayerBackpacks(identifier, function(count)
        if count >= 3 then
            return cb(false, "Vous avez déjà 3 sacs")
        end

        -- Get the storage cache
        if not _G.InventoryCache then return cb(false, "Système de stockage indisponible") end
        local cached = _G.InventoryCache.Get(cacheKey)
        if not cached then return cb(false, "Coffre introuvable") end

        -- Find the bag in storage
        local bagItem = nil
        local bagIndex = nil
        for i, item in ipairs(cached.data.items or {}) do
            if item.name == bagItemName and item.metadata and item.metadata.clotheId then
                bagItem = item
                bagIndex = i
                break
            end
        end

        if not bagItem then
            return cb(false, "Sac introuvable dans le coffre")
        end

        local meta = bagItem.metadata
        local clotheId = meta.clotheId
        local bagValue = meta.bagValue or 0
        local bagTexture = meta.bagTexture or 0
        local contents = meta.contents or "{}"

        -- Re-create vbackpacks entry
        MySQL.Async.execute('INSERT INTO vbackpacks (identifier, clothe_id, bag_value, bag_texture, contents) VALUES (@identifier, @clotheId, @bagValue, @bagTexture, @contents) ON DUPLICATE KEY UPDATE contents = @contents, bag_value = @bagValue, bag_texture = @bagTexture', {
            ['@identifier'] = identifier,
            ['@clotheId'] = clotheId,
            ['@bagValue'] = bagValue,
            ['@bagTexture'] = bagTexture,
            ['@contents'] = type(contents) == "string" and contents or json.encode(contents),
        }, function()
            -- Remove from storage
            table.remove(cached.data.items, bagIndex)

            if _G.InventoryCache.UpdateWeight then
                _G.InventoryCache.UpdateWeight(cacheKey)
            end
            if _G.InventoryCache.MarkDirty then
                _G.InventoryCache.MarkDirty(cacheKey)
            end

            TriggerClientEvent("null:inventory:update", source)
            cb(true)
        end)
    end)
end)

_G.InventoryBackpacks = Backpacks
_G.InventoryBackpacksLoaded = true
--null.InitPrint("Inventory Backpacks module loaded")
