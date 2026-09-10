-- Wait for inventory system to load
while not _G.InventoryClothesLoaded do
    Wait(100)
end

while not _G.InventoryBackpacksLoaded do
    Wait(100)
end

local Clothes = _G.InventoryClothes
local Backpacks = _G.InventoryBackpacks

-- Callback pour acheter des accessoires
ESX.RegisterServerCallback('Null:accessories:buy', function(source, cb, items, paymentMethod, affichename)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then 
        return cb(false) 
    end
    
    -- Check if player is trying to buy a bag and already has 3
    if items["bags_1"] then
        Backpacks.CountPlayerBackpacks(xPlayer.identifier, function(count)
            if count >= 3 then
                xPlayer.showAdvancedNotification("Informations", "Magasin", "Vous avez déjà 3 sacs, vous ne pouvez pas en acheter plus", 'CHAR_REDSIDE', 0, 7)
                cb(false)
                return
            end
            
            -- Continue with purchase
            processPurchase(source, cb, items, paymentMethod, affichename, xPlayer)
        end)
    else
        -- No bag in purchase, continue normally
        processPurchase(source, cb, items, paymentMethod, affichename, xPlayer)
    end
end)

function processPurchase(source, cb, items, paymentMethod, affichename, xPlayer)
    local playerSex = xPlayer.sex == "0" and "male" or "female" 
    
    -- Calculate total price
    local totalPrice = 0
    for k,v in pairs(items) do
        local itemPrice = 0
        if Config.ClothingShop.CustomPrice[playerSex] and Config.ClothingShop.CustomPrice[playerSex][k] and Config.ClothingShop.CustomPrice[playerSex][k][v.item] then
            itemPrice = Config.ClothingShop.CustomPrice[playerSex][k][v.item]
        elseif Config.ClothingShop.CategoryMainPrice[playerSex] and Config.ClothingShop.CategoryMainPrice[playerSex][k] then
            itemPrice = Config.ClothingShop.CategoryMainPrice[playerSex][k]
        else
            itemPrice = Config.ClothingShop.MainPrice
        end
        totalPrice = totalPrice + itemPrice
    end

    -- Check payment
    if paymentMethod == 'bank' then
        local bankMoney = xPlayer.getAccount('bank').money
        if bankMoney < totalPrice then
            cb(false)
            return
        end
        xPlayer.removeAccountMoney('bank', totalPrice, {title = 'Magasin d\'accessoires', description = 'Achat d\'accessoires', category = 'purchase'})
    else
        local cashMoney = xPlayer.getAccount('cash').money
        if cashMoney < totalPrice then
            cb(false)
            return
        end
        xPlayer.removeAccountMoney('cash', totalPrice)
    end

    -- Add only the purchased items to inventory (NOT equipped)
    local completed = 0
    local total = 0
    
    -- Count accessories to add
    for k,v in pairs(items) do
        total = total + 1
    end
    
    local function checkComplete()
        completed = completed + 1
        if completed >= total then
            cb(true, totalPrice)
        end
    end
    
    -- Add each accessory to inventory
    for k,v in pairs(items) do
        local accessoryData = {
            [k] = v.item,
            [string.gsub(k, "_1", "_2")] = v.variation or 0
        }
  
        -- Bags: create in vclothes first to get ID, then create in vbackpacks
        if k == "bags_1" then
            Clothes.Add(source, k, affichename, affichename, accessoryData, function(success, clotheId)
                if success and clotheId then
                    MySQL.Async.insert('INSERT INTO vbackpacks (identifier, clothe_id, bag_value, bag_texture, custom_name, contents) VALUES (@identifier, @clotheId, @bagValue, @bagTexture, @customName, @contents)', {
                        ['@identifier'] = xPlayer.identifier,
                        ['@clotheId'] = clotheId,
                        ['@bagValue'] = v.item,
                        ['@bagTexture'] = v.variation or 0,
                        ['@customName'] = affichename,
                        ['@contents'] = json.encode({ items = {}, loadout = {}, cash = 0, dirtycash = 0 })
                    }, function(backpackId)
                        checkComplete()
                    end)
                else
                    checkComplete()
                end
            end)
        else
            Clothes.Add(source, k, affichename, affichename, accessoryData, function(success, id)
                checkComplete()
            end)
        end
    end
end