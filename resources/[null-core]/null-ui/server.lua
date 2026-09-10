function AddToInv(identifier, clotheType, label, data, cb)
    MySQL.Async.execute('INSERT INTO vclothes (identifier, type, name, data) VALUES (@identifier, @type, @name, @data)', {
        ['@identifier'] = identifier,
        ['@type'] = clotheType,
        ['@name'] = label,
        ['@data'] = json.encode(data)
    }, function(rowsChanged)
        pcall(function()
            exports["null-core"]:ClearClothesCache(identifier)
        end)
        
        if rowsChanged > 0 and cb then
            MySQL.Async.fetchScalar('SELECT LAST_INSERT_ID()', {}, function(id)
                cb(true, id)
            end)
        elseif cb then
            cb(false)
        end
    end)
end

function EquipClothesSlot(source, clotheType, clotheId, clotheData)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    if not xPlayer.clothes_equiped then
        xPlayer.clothes_equiped = {}
    end
    
    xPlayer.clothes_equiped[clotheType] = {
        id = clotheId,
        name = clotheData.name or clotheData.label,
        label = clotheData.label,
        data = clotheData.data,
    }
    
    xPlayer.set('clothes_equiped', xPlayer.clothes_equiped)
    
    TriggerClientEvent("null:inventory:equipClothesSlot", source, clotheType, xPlayer.clothes_equiped[clotheType])
end

exports('EquipClothesSlot', EquipClothesSlot)

ESX.RegisterServerCallback('Null:clothes:pay', function(source, cb, items, paymentMethod, affichename)
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
        xPlayer.removeAccountMoney('bank', totalPrice)
    else
        if xPlayer.getAccount('cash').money < totalPrice then
            cb(false)
            return
        end
        xPlayer.removeAccountMoney('cash', totalPrice)
    end

    local top = {
        ["torso_1"] = 0,
        ["torso_2"] = 0,
        ["arms"] = 0,
        ["tshirt_1"] = 0,
        ["tshirt_2"] = 0,
        ["decals_1"] = 0,
    }
    local pants = {
        ["pants_1"] = 0,
        ["pants_2"] = 0,
    }
    local shoes = {
        ["shoes_1"] = 0,
        ["shoes_2"] = 0,
    }

    for k,v in pairs(items) do
        if top[k] then
            if k ~= "arms" then
                name = string.gsub(k, "_1", "")
                top[name.."_1"] = v.item
                top[name.."_2"] = v.variation
            else
                top[k] = v.item
            end
        elseif pants[k] then
            name = string.gsub(k, "_1", "")
            pants[name.."_1"] = v.item
            pants[name.."_2"] = v.variation
        elseif shoes[k] then
            name = string.gsub(k, "_1", "")
            shoes[name.."_1"] = v.item
            shoes[name.."_2"] = v.variation
        end
    end

    local completed = 0
    local total = 3
    
    local function checkComplete()
        completed = completed + 1
        if completed >= total then
            null.DebugPrint("Clothes added to inventory and payed")
            cb(true, totalPrice)
        end
    end
    
    AddToInv(xPlayer.identifier, "top", affichename, top, function(success, id)
        if success then
            EquipClothesSlot(source, "top", id, { label = affichename, data = top })
        end
        checkComplete()
    end)
    
    AddToInv(xPlayer.identifier, "pants", affichename, pants, function(success, id)
        if success then
            EquipClothesSlot(source, "pants", id, { label = affichename, data = pants })
        end
        checkComplete()
    end)
    
    AddToInv(xPlayer.identifier, "shoes", affichename, shoes, function(success, id)
        if success then
            EquipClothesSlot(source, "shoes", id, { label = affichename, data = shoes })
        end
        checkComplete()
    end)
end)



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
        xPlayer.removeAccountMoney('bank', totalPrice)
    else
        if xPlayer.getAccount('cash').money < totalPrice then
            cb(false)
            return
        end
        xPlayer.removeAccountMoney('cash', totalPrice)
    end

    local function finishCallback(clotheType, data)
        AddToInv(xPlayer.identifier, clotheType, affichename, data, function(success, id)
            if success then
                EquipClothesSlot(source, clotheType, id, { label = affichename, data = data })
            end
            cb(true, totalPrice)
        end)
    end
    
    if group == "Haut" then
        local top = {}
        for k,v in pairs(items) do
            if k ~= "arms" then
                name = string.gsub(k, "_1", "")
                top[name.."_1"] = v.item
                top[name.."_2"] = v.variation
            else
                top[k] = v.item
            end
        end
        finishCallback("top", top)
    elseif group == "Pantalon" then
        local pants = {}
        for k,v in pairs(items) do
            name = string.gsub(k, "_1", "")
            pants[name.."_1"] = v.item
            pants[name.."_2"] = v.variation
        end
        finishCallback("pants", pants)
    elseif group == "Chaussures" then
        local shoes = {}
        for k,v in pairs(items) do
            name = string.gsub(k, "_1", "")
            shoes[name.."_1"] = v.item
            shoes[name.."_2"] = v.variation
        end
        finishCallback("shoes", shoes)
    else 
        local clotheType = "accessory"
        local final = {}
        for k,v in pairs(items) do
            name = string.gsub(k, "_1", "")
            final[name.."_1"] = v.item
            final[name.."_2"] = v.variation
            if k == "mask_1" then
                clotheType = "mask"
                break
            elseif k == "helmet_1" then
                clotheType = "hat"
                break
            elseif k == "bags_1" then
                clotheType = "bag"
                break
            elseif k == "bproof_1" then
                clotheType = "gillet"
                break
            elseif k == "chain_1" then
                clotheType = "neck"
                break
            elseif k == "ears_1" then
                clotheType = "ear"
                break
            elseif k == "watches_1" then
                clotheType = "watch"
                break
            elseif k == "bracelets_1" then
                clotheType = "bracelet"
                break
            elseif k == "glasses_1" then
                clotheType = "glasses"
                break
            end
        end
        
        finishCallback(clotheType, final)
    end
end)

RegisterNetEvent('null-ui:rpannounce:sendMsg-staff', function(data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getGroup() == "user" then return end
    
    TriggerClientEvent('null-ui:AnnounceImage', -1, data)
end)


RegisterNetEvent('null-ui:rpannounce:sendMsg', function(data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getJob().name ~= "journalist" then return end

    TriggerClientEvent('null-ui:AnnounceImage', -1, data)
end)


--null.InitPrint("^2UI modules loaded")