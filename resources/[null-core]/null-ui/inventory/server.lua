-- RegisterNetEvent("esx:clothes:delete")
-- AddEventHandler("esx:clothes:delete", function(id)
--     MySQL.Async.fetchAll("DELETE from vclothes WHERE id = @id", {["@id"] = id})
-- end)


-- RegisterNetEvent("Null:removeInventoryWeapon")
-- AddEventHandler("Null:removeInventoryWeapon", function(WeaponName)
--     local src = source
--     local xPlayer = ESX.GetPlayerFromId(src)
--     local loadout = xPlayer.getLoadout()

--     for k,v in pairs(loadout) do
--         if v.name == WeaponName and not v.permanent then
--             xPlayer.removeWeapon(WeaponName)
--             break
--         end
--     end
-- end)

-- RegisterNetEvent("inventory:renameWeapon", function(weaponname, newname)
--     local xPlayer = ESX.GetPlayerFromId(source)
--     local oldmeta = xPlayer.getWeaponMetaData(weaponname)
--     if oldmeta.description ~= nil then
--         xPlayer.editWeaponMetaData(weaponname, {
--             label = newname,
--             description = oldmeta.description
--         })
--     else
--         xPlayer.editWeaponMetaData(weaponname, {
--             label = newname
--         })
--     end
-- end)
-- RegisterNetEvent("ZgegFramework:clothes:rename")
-- AddEventHandler("ZgegFramework:clothes:rename", function(name, id)
--     local xPlayer = ESX.GetPlayerFromId(source)
--     MySQL.Async.execute("UPDATE vclothes SET name=@name WHERE identifier = @identifier AND id = @id", {
--         ["@id"] = id,
--         ["@identifier"] = xPlayer.identifier,
--         ["@name"] = name
--     })
    
--     xPlayer.set("clothes_equiped", clothes)
-- end)

-- RegisterNetEvent("ZgegFramework:clothes:transfere")
-- AddEventHandler("ZgegFramework:clothes:transfere", function(id, target)
--     local xTarget = ESX.GetPlayerFromId(target)

--     MySQL.Async.execute("UPDATE vclothes SET identifier=@identifier WHERE id = @id", {
--         ["@id"] = id,
--         ["@identifier"] = xTarget.identifier
--     })
-- end)

-- RegisterNetEvent("esx:playerLoaded")
-- AddEventHandler('esx:playerLoaded', function(source, xPlayer)
--     local source = source
--     TriggerClientEvent("null:inv:load", source, xPlayer)
-- end)


-- RegisterNetEvent("ZgegFramework:equipedClothes")
-- AddEventHandler("ZgegFramework:equipedClothes", function(clothes, id)
--     local xPlayer = ESX.GetPlayerFromId(source)
--     if id then
--         local cloth = clothes[id]
--         if cloth then
--             clothes[id] = nil
--         end
--     end
    
--     MySQL.Async.execute("UPDATE users SET clothes=@clothes WHERE identifier = @identifier", {
--         ["@identifier"] = xPlayer.identifier,
--         ["@clothes"] = json.encode(clothes)
--     })
    
--     xPlayer.set("clothes_equiped", clothes)
-- end)


-- ESX.RegisterServerCallback('null:inv:getClothe', function(source, cb)
--     local src = source
--     local xPlayer = ESX.GetPlayerFromId(src)
--     local clothe_v_data = {}

--     MySQL.Async.fetchAll('SELECT * FROM vclothes WHERE identifier = @identifier', {
--         ['@identifier'] = xPlayer.identifier
--     }, function(result) 
--         if result[1] then
--             for i = 1, #result, 1 do  
--                 table.insert(clothe_v_data, {      
--                     type      = result[i].type,  
--                     clothe      = json.decode(result[i].data),
--                     id      = result[i].id,
--                     label      = result[i].name,
--                 })
--             end
--         end

--         if clothe_v_data then
--             cb(clothe_v_data)
--         end
--     end)  
-- end, GetCurrentResourceName())

-- ESX.RegisterServerCallback('null:inv:getClotheByNameAndType', function(source, cb, type,name)
--     local src = source
--     local xPlayer = ESX.GetPlayerFromId(src)
--     MySQL.Async.fetchAll('SELECT * FROM vclothes WHERE identifier = @identifier AND name = @name AND type = @type', {
--         ['@identifier'] = xPlayer.identifier,
--         ['@name'] = name,
--         ['@type'] = type
--     }, function(result) 
--         if result[1] then
--             return result
--         end
--     end)  
-- end, GetCurrentResourceName())

-- ESX.RegisterServerCallback('null:inv:getClotheEquiped', function(source, cb)
--     local src = source
--     local xPlayer = ESX.GetPlayerFromId(src)
--     local clotheequipe_v_data = {}

--     MySQL.Async.fetchAll("SELECT * FROM users WHERE identifier=@identifier", {["@identifier"] = xPlayer.identifier}, function(result)
--         if result[1] then
--             if result[1].clothes then
--                 cb(json.decode(result[1].clothes))
--             end 
--         end
--     end)
-- end, GetCurrentResourceName())

-- ESX.RegisterServerCallback("null:inv:getPlayerInventory", function(source, cb, target, offline)
--     local xPlayer = ESX.GetPlayerFromId(target)
    
--     if not offline then
--         if xPlayer then
--             cb({
--                 inventory = xPlayer.inventory,
--                 uniqueid = xPlayer.getUniqueId(),
--                 money = xPlayer.getMoney(),
--                 accounts = xPlayer.accounts,
--                 weapons = xPlayer.loadout,
--                 weight = xPlayer.getWeight(),
--                 maxWeight = xPlayer.maxWeight,
--                 blackMoney = xPlayer.getAccount("black_money").money
--             })
--         else
--             cb(nil)
--         end
--     elseif xPlayer then
--         cb({
--             inventory = xPlayer.inventory
--         })
--     else
--         cb(nil)
--     end
-- end, GetCurrentResourceName())

-- ESX.RegisterServerCallback("null:inv:getPlayerInventoryOffline", function(source, cb, idunique)
--     local player = MySQL.Async.fetchAll("SELECT * FROM users WHERE idunique = @idunique", {["@idunique"] = tonumber(idunique)})
--     if player[1] then
--         local data = {
--             money = player[1].accounts.money,
--             blackMoney = player[1].accounts.black_money,
--             inventory = json.decode(player[1].inventory),
--             weapons = json.decode(player[1].loadout),
--             accounts = json.decode(player[1].accounts),
--             weight = 0,
--             maxWeight = ESX.GetConfig().MaxWeight
--         }
--         cb(data)
--     else
--         cb(nil)
--     end
-- end, GetCurrentResourceName())


-- null.InitPrint("Inventory UI loaded")