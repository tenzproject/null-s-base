-- Wait for inventory system to load
while not _G.InventoryClothesLoaded do
    Wait(100)
end

local Clothes = _G.InventoryClothes

-- Wait for outfits system to load
while not _G.InventoryOutfits do
    Wait(100)
end

local Outfits = _G.InventoryOutfits

ESX.RegisterServerCallback('Null:clothes:pay', function(source, cb, items, paymentMethod, affichename)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end
    
    local playerSex = xPlayer.sex == 0 and "male" or "female"
    
    -- Calculate total price
    local totalPrice = 0
    for k,v in pairs(items) do
        if Config.ClothingShop.CustomPrice[playerSex] and Config.ClothingShop.CustomPrice[playerSex][k] and Config.ClothingShop.CustomPrice[playerSex][k][v.item] then
            totalPrice = totalPrice + Config.ClothingShop.CustomPrice[playerSex][k][v.item]
        elseif Config.ClothingShop.CategoryMainPrice[playerSex] and Config.ClothingShop.CategoryMainPrice[playerSex][k] then
            totalPrice = totalPrice + Config.ClothingShop.CategoryMainPrice[playerSex][k]
        else
            totalPrice = totalPrice + Config.ClothingShop.MainPrice
        end
    end

    -- Check payment
    if paymentMethod == 'bank' then
        if xPlayer.getAccount('bank').money < totalPrice then
            cb(false)
            return
        end
        xPlayer.removeAccountMoney('bank', totalPrice, {title = 'Magasin de vêtements', description = 'Achat de vêtements', category = 'purchase'})
    else
        if xPlayer.getAccount('cash').money < totalPrice then
            cb(false)
            return
        end
        xPlayer.removeAccountMoney('cash', totalPrice)
    end

    -- Categorize items by clothing group
    local topKeys = {"torso_1", "torso_2", "arms", "tshirt_1", "tshirt_2", "decals_1"}
    local pantsKeys = {"pants_1", "pants_2"}
    local shoesKeys = {"shoes_1", "shoes_2"}
    
    local clothingGroups = {}
    
    for k,v in pairs(items) do
        local groupName = nil
        local clotheData = {}
        
        -- Check if it's a top item
        for _, topKey in ipairs(topKeys) do
            if k == topKey then
                groupName = "top"
                if k ~= "arms" then
                    local name = string.gsub(k, "_1", "")
                    clotheData[name.."_1"] = v.item or v.id
                    clotheData[name.."_2"] = v.variation or 0
                else
                    clotheData[k] = v.item or v.id
                end
                break
            end
        end
        
        -- Check if it's pants
        if not groupName then
            for _, pantsKey in ipairs(pantsKeys) do
                if k == pantsKey then
                    groupName = "pants"
                    local name = string.gsub(k, "_1", "")
                    clotheData[name.."_1"] = v.item or v.id
                    clotheData[name.."_2"] = v.variation or 0
                    break
                end
            end
        end
        
        -- Check if it's shoes
        if not groupName then
            for _, shoesKey in ipairs(shoesKeys) do
                if k == shoesKey then
                    groupName = "shoes"
                    local name = string.gsub(k, "_1", "")
                    clotheData[name.."_1"] = v.item or v.id
                    clotheData[name.."_2"] = v.variation or 0
                    break
                end
            end
        end
        
        -- Add to clothing groups
        if groupName then
            if not clothingGroups[groupName] then
                clothingGroups[groupName] = {}
            end
            for dataKey, dataValue in pairs(clotheData) do
                clothingGroups[groupName][dataKey] = dataValue
            end
        end
    end
    
    -- Create individual pieces first, then assemble into outfit
    local completed = 0
    local total = 0
    for _ in pairs(clothingGroups) do
        total = total + 1
    end
    
    print("[SHOP] Total clothing groups to create:", total)
    print("[SHOP] Clothing groups:", json.encode(clothingGroups))
    
    if total == 0 then
        print("[SHOP] ERROR: No clothing groups to create!")
        return cb(false)
    end
    
    local createdPieces = {}
    
    local function checkComplete()
        completed = completed + 1
        print("[SHOP] Piece created, completed:", completed, "/", total)
        print("[SHOP] Created pieces so far:", json.encode(createdPieces))
        
        if completed >= total then
            print("[SHOP] All pieces created, waiting before creating outfit...")
            -- Wait a bit to ensure all DB inserts are complete
            Wait(500)
            print("[SHOP] Creating outfit with pieces:", json.encode(createdPieces))
            -- All pieces created, now create outfit
            Outfits.Create(source, createdPieces, affichename, function(success, message)
                print("[SHOP] Outfit creation result:", success, message)
                if success then
                    -- Find the created outfit ID
                    MySQL.Async.fetchAll('SELECT id FROM vclothes WHERE identifier = @identifier AND type = @type AND name = @name ORDER BY id DESC LIMIT 1', {
                        ['@identifier'] = xPlayer.identifier,
                        ['@type'] = "outfit",
                        ['@name'] = affichename,
                    }, function(result)
                        if result and result[1] then
                            local outfitId = result[1].id
                            print("[SHOP] Outfit created with ID:", outfitId, "- Equipping...")
                            -- Equip the outfit
                            Outfits.Equip(source, outfitId, function(equipSuccess, equipMessage)
                                print("[SHOP] Outfit equip result:", equipSuccess, equipMessage)
                                cb(true, totalPrice)
                            end)
                        else
                            print("[SHOP] ERROR: Outfit not found after creation")
                            cb(true, totalPrice)
                        end
                    end)
                else
                    print("[SHOP] ERROR: Outfit creation failed:", message)
                    cb(false)
                end
            end)
        end
    end
    
    -- Add each clothing group to inventory
    for groupName, clotheData in pairs(clothingGroups) do
        print("[SHOP] Creating piece:", groupName, json.encode(clotheData))
        Clothes.Add(source, groupName, affichename, affichename, clotheData, function(success, id)
            print("[SHOP] Piece creation result:", groupName, success, id)
            if success and id then
                createdPieces[groupName] = id
            end
            checkComplete()
        end)
    end
end)

-- Callback pour le paiement d'un seul item
ESX.RegisterServerCallback('Null:clothes:payone', function(source, cb, items, paymentMethod, group, affichename)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(false) end
    
    local playerSex = xPlayer.sex == 0 and "male" or "female"
    
    local totalPrice = 0
    for k,v in pairs(items) do
        if Config.ClothingShop.CustomPrice[playerSex] and Config.ClothingShop.CustomPrice[playerSex][k] and Config.ClothingShop.CustomPrice[playerSex][k][v.item] then
            totalPrice = totalPrice + Config.ClothingShop.CustomPrice[playerSex][k][v.item]
        elseif Config.ClothingShop.CategoryMainPrice[playerSex] and Config.ClothingShop.CategoryMainPrice[playerSex][k] then
            totalPrice = totalPrice + Config.ClothingShop.CategoryMainPrice[playerSex][k]
        else
            totalPrice = totalPrice + Config.ClothingShop.MainPrice
        end
    end

    if paymentMethod == 'bank' then
        if xPlayer.getAccount('bank').money < totalPrice then
            cb(false)
            return
        end
        xPlayer.removeAccountMoney('bank', totalPrice, {title = 'Magasin d\'accessoires', description = 'Achat d\'accessoires', category = 'purchase'})
    else
        if xPlayer.getAccount('cash').money < totalPrice then
            cb(false)
            return
        end
        xPlayer.removeAccountMoney('cash', totalPrice)
    end

    -- Add clothes to inventory using the inventory system
    if not xPlayer.clothes_equiped then
        xPlayer.clothes_equiped = {}
    end
    
    Clothes.Add(source, group, affichename, affichename, items, function(success, id)
        if success then
            xPlayer.clothes_equiped[group] = {
                id = id,
                name = affichename,
                label = affichename,
                clothe = items,
            }
            TriggerClientEvent("null:inventory:equipClothesSlot", source, group, xPlayer.clothes_equiped[group])
            Clothes.SaveEquipped(source, xPlayer.clothes_equiped)
            cb(true, totalPrice)
        else
            cb(false)
        end
    end)
end)