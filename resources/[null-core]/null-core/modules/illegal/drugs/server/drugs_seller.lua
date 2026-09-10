local DrugsSellerLoad = false
Citizen.CreateThread(function()
    while not LastMarketLoaded do Wait(100) end
    local typeList = {"meth", "weed", "coke"}
    local listName = {"Trey","Darnell","Jay","Malik","DeShawn","Tyrell","Lamar","CJ","Duke","Marquis","Rico","Andre","Kareem","Rayvon","Travon","Jamal","Darius","Snoop","Reggie","Antwan"}
    local AcTime = os.time()
    Config.DrugSellers.Sellers = {}
    for k,v in pairs(Config.DrugSellers.Positions) do 
        local drugName = typeList[math.random(1, #typeList)]
        Config.DrugSellers.Sellers[k] = {
            quantity = Config.DrugSellers.type[drugName].quantity(),
            price = Config.DrugSellers.type[drugName].price(LastMarket[drugName].DrugsRequestPrice),
            drug = drugName,
            name = listName[math.random(1, #listName)],
            here = true,
            lastSync = AcTime,
            pedModel = Config.AllPedModel[math.random(1, #Config.AllPedModel)],
        }
    end
    DrugsSellerLoad = true
end)

Citizen.CreateThread(function()
    while not DrugsSellerLoad do Wait(100) end
    while true do 
        for k,v in pairs(Config.DrugSellers.Sellers) do 
            if v.here then
                if (os.time() - v.lastSync) > 60 then
                    local needToGo = math.random(0, 100)
                    if needToGo < 50 then
                        v.here = false
                        v.lastSync = os.time()
                        --null.DebugPrint("[^1DrugsDealer^7] "..v.name.." vient de sortir de chez lui.")
                    end
                end
            else
                if (os.time() - v.lastSync) > 60 then
                    local needToEnter = math.random(0, 100)
                    if needToEnter < 50 then
                        v.here = true
                        v.lastSync = os.time()
                        --null.DebugPrint("[^1DrugsDealer^7] "..v.name.." vient de rentrer chez lui.")
                    end
                end
            end
        end
        Wait(30*1000)
    end
end)

ESX.RegisterServerCallback("null:drugsseller:arehere?", function(source, cb, id)
    if Config.DrugSellers.Sellers[id] then
        if Config.DrugSellers.Sellers[id].here then
            cb(true, Config.DrugSellers.Sellers[id].quantity, Config.DrugSellers.Sellers[id].price, Config.DrugSellers.Sellers[id].drug, Config.DrugSellers.Sellers[id].name, Config.DrugSellers.Sellers[id].pedModel)
        else
            cb(false)
        end
    else
        cb(false)
    end
end)

RegisterNetEvent("null:drugsseller:buy", function(id, count)
    local xPlayer = ESX.GetPlayerFromId(source)
    local Seller = Config.DrugSellers.Sellers[id]
    if Seller == nil then return end
    if Seller.quantity < count then return end
    if not Seller.here then return end
    local price = Seller.price * count
    if xPlayer.getAccount('dirtycash').money < price then return end
    xPlayer.removeAccountMoney("dirtycash", price)
    xPlayer.addInventoryItem(Config.DrugSellers.type[Seller.drug].item, count)
    Seller.quantity = Seller.quantity - count
end)