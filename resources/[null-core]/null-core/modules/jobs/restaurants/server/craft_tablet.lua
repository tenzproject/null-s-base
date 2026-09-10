local CraftingSessions = {}
local function GetRestaurantRecipes(jobName)
    local recipes = {}
    if not SaveData or not SaveData.json or not SaveData.json["entreprises"] or not SaveData.json["entreprises"]["Restaurant"] then
        return recipes
    end
    
    local restData = nil
    for name, data in pairs(SaveData.json["entreprises"]["Restaurant"]) do
        if data.name == jobName or name == jobName then
            restData = data
            break
        end
    end
    
    if not restData or not restData.crafts then return recipes end
    
    for key, craft in pairs(restData.crafts) do
        local reqs = {}
        if craft.Requirements then
            for _, req in pairs(craft.Requirements) do
                table.insert(reqs, {
                    itemName = req.ItemName,
                    label = req.Label or req.ItemName,
                    amount = req.Amount or 1,
                })
            end
        end
        table.insert(recipes, {
            id = string.lower(key),
            label = craft.Label or key,
            item = string.lower(craft.Item or key),
            count = craft.Count or 1,
            time = craft.Time or 5,
            category = craft.Category or "nourriture",
            description = craft.Description or "",
            requirements = reqs,
        })
    end
    return recipes
end

local function GetRawMaterials(jobName)
    local recipes = GetRestaurantRecipes(jobName)
    local materials = {}
    local seen = {}
    
    for _, recipe in ipairs(recipes) do
        for _, req in ipairs(recipe.requirements) do
            if not seen[req.itemName] then
                seen[req.itemName] = true
                local price = 50 
                table.insert(materials, {
                    name = req.itemName,
                    label = req.label,
                    price = price,
                })
            end
        end
    end
    return materials
end
local function EnrichRecipesWithPlayerData(source, recipes)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return recipes end
    
    for _, recipe in ipairs(recipes) do
        for _, req in ipairs(recipe.requirements) do
            local item = xPlayer.getInventoryItem(req.itemName)
            req.playerHas = item and item.count or 0
        end
    end
    return recipes
end


ESX.RegisterServerCallback('null:restaurant:getCraftData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb(nil) end
    
    local jobName = xPlayer.job.name
    local recipes = GetRestaurantRecipes(jobName)
    recipes = EnrichRecipesWithPlayerData(source, recipes)
    
    local restLabel = jobName
    local brand = nil
    if SaveData.json["entreprises"]["Restaurant"] then
        for name, d in pairs(SaveData.json["entreprises"]["Restaurant"]) do
            if d.name == jobName or name == jobName then
                restLabel = d.label or name
                brand = {
                    color = d.brandColor or "#e74c3c",
                    logo = d.logo or "",
                    description = d.description or "",
                }
                break
            end
        end
    end

    -- Current orders for this restaurant
    local orders = {}
    if RestaurantOrders and RestaurantOrders[jobName] then
        for _, o in ipairs(RestaurantOrders[jobName]) do
            table.insert(orders, {
                id = o.id,
                items = o.items,
                customerName = o.customerName,
                total = o.total,
                status = o.status,
                createdAt = o.createdAt,
                claimedBy = o.claimedBy,
            })
        end
    end

    cb({
        restaurantName = jobName,
        restaurantLabel = restLabel,
        recipes = recipes,
        categories = {},
        brand = brand,
        orders = orders,
    })
end)

ESX.RegisterServerCallback('null:restaurant:startCraft', function(source, cb, recipeId)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return cb({ started = false, message = "Joueur introuvable" }) end
    
    if CraftingSessions[source] then
        return cb({ started = false, message = "Un craft est déjà en cours" })
    end
    
    local jobName = xPlayer.job.name
    local recipes = GetRestaurantRecipes(jobName)
    local recipe = nil
    
    for _, r in ipairs(recipes) do
        if r.id == recipeId then
            recipe = r
            break
        end
    end
    
    if not recipe then
        return cb({ started = false, message = "Recette introuvable" })
    end
    
    for _, req in ipairs(recipe.requirements) do
        local item = xPlayer.getInventoryItem(req.itemName)
        if not item or item.count < req.amount then
            return cb({ started = false, message = "Il vous manque: " .. req.label })
        end
    end
    
    if not xPlayer.canCarryItem(recipe.item, recipe.count) then
        return cb({ started = false, message = "Inventaire plein" })
    end
    
    local src = source
    CraftingSessions[src] = {
        recipeId = recipe.id,
        startTime = GetGameTimer(),
        duration = recipe.time * 1000,
    }
    
    cb({ started = true, time = recipe.time, label = recipe.label })
    
    local totalMs = recipe.time * 1000
    local startMs = GetGameTimer()
    
    Citizen.CreateThread(function()
        while CraftingSessions[src] do
            Wait(500)
            local elapsed = GetGameTimer() - startMs
            
            if elapsed >= totalMs then
                CraftingSessions[src] = nil
                
                local canCraft = true
                for _, req in ipairs(recipe.requirements) do
                    local item = xPlayer.getInventoryItem(req.itemName)
                    if not item or item.count < req.amount then
                        canCraft = false
                        break
                    end
                end
                
                if canCraft and xPlayer.canCarryItem(recipe.item, recipe.count) then
                    for _, req in ipairs(recipe.requirements) do
                        xPlayer.removeInventoryItem(req.itemName, req.amount)
                    end
                    xPlayer.addInventoryItem(recipe.item, recipe.count)
                    
                    TriggerClientEvent('null:restaurant:craftDone', src, true, recipe.count .. "x " .. recipe.label .. " crafté !")
                else
                    TriggerClientEvent('null:restaurant:craftDone', src, false, "Craft échoué - vérifiez votre inventaire")
                end
                break
            end
        end
    end)
end)

_G.GetRestaurantRecipesForPlayer = function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return nil end
    
    local jobName = xPlayer.job.name
    local recipes = GetRestaurantRecipes(jobName)
    recipes = EnrichRecipesWithPlayerData(source, recipes)
    
    local restLabel = jobName
    if SaveData.json["entreprises"]["Restaurant"] then
        for name, d in pairs(SaveData.json["entreprises"]["Restaurant"]) do
            if d.name == jobName or name == jobName then
                restLabel = d.label or name
                break
            end
        end
    end
    
    return {
        restaurantName = jobName,
        restaurantLabel = restLabel,
        recipes = recipes,
        categories = {},
    }
end

_G.GetRawMaterialsForJob = GetRawMaterials

AddEventHandler('playerDropped', function()
    CraftingSessions[source] = nil
end)
