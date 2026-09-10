while not Config.Crafting do
    Wait(0)
end

local Crafting = {}

-- Validate that a player meets the conditions for a craft table
function Crafting.MeetsConditions(playerId, conditions)
    if not conditions then return true end
    
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    if conditions.job and xPlayer.job and xPlayer.job.name ~= conditions.job then
        return false
    end
    
    if conditions.job2 and xPlayer.job2 and xPlayer.job2.name ~= conditions.job2 then
        return false
    end
    
    if conditions.group then
        local group = xPlayer.getGroup and xPlayer.getGroup() or nil
        if group ~= conditions.group then
            return false
        end
    end
    
    return true
end

-- Get recipes with player's current item counts
function Crafting.GetRecipesForPlayer(playerId, recipes)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return {} end
    
    local result = {}
    for _, recipe in ipairs(recipes) do
        local r = {
            id = recipe.id,
            label = recipe.label,
            item = recipe.item,
            type = recipe.type or "item",
            time = recipe.time or 10,
            category = recipe.category,
            description = recipe.description,
            icon = recipe.icon or ("nui://null-cache/images/items/" .. recipe.item .. ".webp"),
            requirements = {},
        }
        
        for _, req in ipairs(recipe.requirements or {}) do
            local playerItem = xPlayer.getInventoryItem(req.itemName)
            table.insert(r.requirements, {
                itemName = req.itemName,
                label = req.label,
                amount = req.amount,
                have = playerItem and playerItem.count or 0,
                icon = req.icon or ("nui://null-cache/images/items/" .. req.itemName .. ".webp"),
            })
        end
        
        table.insert(result, r)
    end
    
    return result
end

-- Perform a craft action
function Crafting.DoCraft(playerId, recipeId, tableId, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, "Joueur introuvable") end
    
    -- Find the recipe
    local recipe = nil
    local conditions = nil
    
    if tableId then
        -- Table-based craft
        for _, craftTable in ipairs(Config.Crafting.Tables or {}) do
            if craftTable.id == tableId then
                if not Crafting.MeetsConditions(playerId, craftTable.conditions) then
                    return cb(false, "Vous n'avez pas accès à cette table")
                end
                for _, r in ipairs(craftTable.recipes or {}) do
                    if r.id == recipeId then
                        recipe = r
                        break
                    end
                end
                break
            end
        end
    else
        -- Basic craft (from inventory)
        for _, r in ipairs(Config.Crafting.BasicRecipes or {}) do
            if r.id == recipeId then
                recipe = r
                break
            end
        end
    end
    
    if not recipe then
        return cb(false, "Recette introuvable")
    end
    
    -- Check requirements
    for _, req in ipairs(recipe.requirements or {}) do
        local playerItem = xPlayer.getInventoryItem(req.itemName)
        if not playerItem or playerItem.count < req.amount then
            return cb(false, "Il vous manque: " .. req.label)
        end
    end
    
    -- Check weight for result item
    if recipe.type == "item" then
        if not xPlayer.canCarryItem(recipe.item, 1) then
            return cb(false, "Inventaire trop lourd")
        end
    end
    
    -- Remove requirements
    for _, req in ipairs(recipe.requirements or {}) do
        xPlayer.removeInventoryItem(req.itemName, req.amount)
    end
    
    -- Give result
    if recipe.type == "weapon" then
        xPlayer.addWeapon(recipe.item, 0)
    else
        xPlayer.addInventoryItem(recipe.item, recipe.count or 1)
    end
    
    cb(true, recipe.label)
end

-- Server callbacks
ESX.RegisterServerCallback('null:crafting:getRecipes', function(source, cb, tableId)
    local recipes = {}
    
    if tableId then
        for _, craftTable in ipairs(Config.Crafting.Tables or {}) do
            if craftTable.id == tableId then
                if Crafting.MeetsConditions(source, craftTable.conditions) then
                    recipes = Crafting.GetRecipesForPlayer(source, craftTable.recipes or {})
                end
                break
            end
        end
    else
        recipes = Crafting.GetRecipesForPlayer(source, Config.Crafting.BasicRecipes or {})
    end
    
    cb(recipes)
end)

ESX.RegisterServerCallback('null:crafting:craft', function(source, cb, recipeId, tableId)
    Crafting.DoCraft(source, recipeId, tableId, function(success, msg)
        if success then
            TriggerClientEvent("inventory:sendMessage", source, "~g~Fabrication réussie: " .. msg)
        else
            TriggerClientEvent("inventory:sendMessage", source, "~r~" .. msg)
        end
        cb(success)
    end)
end)

_G.InventoryCrafting = Crafting
_G.InventoryCraftingLoaded = true
null.InitPrint("Inventory Crafting module loaded")
