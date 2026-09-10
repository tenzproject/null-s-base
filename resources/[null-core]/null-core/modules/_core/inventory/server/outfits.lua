while not _G.InventoryClothesLoaded do
    Wait(0)
end

local Clothes = _G.InventoryClothes
local Outfits = {}

-- Create an outfit from multiple clothing pieces
-- pieces = { top = clotheId, pants = clotheId, shoes = clotheId, ... }
function Outfits.Create(playerId, pieces, outfitName, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, "Joueur introuvable") end
    
    local identifier = xPlayer.identifier
    
    if not outfitName or outfitName == "" then
        outfitName = Config.Outfits.DefaultName or "Tenue"
    end
    
    -- Validate minimum pieces
    local pieceCount = 0
    for _, _ in pairs(pieces) do
        pieceCount = pieceCount + 1
    end
    
    if pieceCount < (Config.Outfits.MinPieces or 2) then
        return cb(false, "Il faut au moins " .. (Config.Outfits.MinPieces or 2) .. " pièces pour créer une tenue")
    end
    
    -- Clear cache to ensure we load fresh data (important for newly created pieces)
    Clothes.ClearCache(identifier)
    
    -- Load all player clothes to validate ownership
    Clothes.Load(playerId, function(allClothes)
        -- Build a lookup of clotheId -> clotheData
        local clothesById = {}
        for _, c in ipairs(allClothes) do
            clothesById[c.id] = c
        end
        
        -- Validate all pieces exist and belong to player
        local outfitData = {}
        local clotheIds = {}
        
        for clotheType, clotheId in pairs(pieces) do
            local clothe = clothesById[clotheId]
            if not clothe then
                return cb(false, "Vêtement introuvable: " .. tostring(clotheType))
            end
            if clothe.type ~= clotheType then
                return cb(false, "Type de vêtement incorrect pour " .. tostring(clotheType))
            end
            
            outfitData[clotheType] = {
                id = clothe.id,
                name = clothe.name,
                label = clothe.label,
                clothe = clothe.clothe,
            }
            table.insert(clotheIds, clothe.id)
        end
        
        -- Check that none of these clothes are currently equipped
        local equipped = xPlayer.clothes_equiped or {}
        for clotheType, clotheId in pairs(pieces) do
            if equipped[clotheType] and equipped[clotheType].id == clotheId then
                return cb(false, "Retirez d'abord le vêtement équipé: " .. clotheType)
            end
        end
        
        -- Create the outfit entry in vclothes with type = "outfit"
        local outfitJson = json.encode(outfitData)
        
        MySQL.Async.execute('INSERT INTO vclothes (identifier, type, name, data) VALUES (@identifier, @type, @name, @data)', {
            ['@identifier'] = identifier,
            ['@type'] = "outfit",
            ['@name'] = outfitName,
            ['@data'] = outfitJson,
        }, function(rowsChanged)
            if rowsChanged > 0 then
                -- Delete the individual pieces
                local deleteQuery = 'DELETE FROM vclothes WHERE id IN ('
                local params = {}
                for i, id in ipairs(clotheIds) do
                    deleteQuery = deleteQuery .. '@id' .. i
                    if i < #clotheIds then deleteQuery = deleteQuery .. ', ' end
                    params['@id' .. i] = id
                end
                deleteQuery = deleteQuery .. ') AND identifier = @identifier'
                params['@identifier'] = identifier
                
                MySQL.Async.execute(deleteQuery, params, function()
                    Clothes.ClearCache(identifier)
                    cb(true, "Tenue créée: " .. outfitName)
                end)
            else
                cb(false, "Erreur lors de la création de la tenue")
            end
        end)
    end)
end

-- Disassemble an outfit back into individual clothing pieces
function Outfits.Disassemble(playerId, outfitId, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return cb(false, "Joueur introuvable") end
    
    local identifier = xPlayer.identifier
    
    -- Load the outfit data
    MySQL.Async.fetchAll('SELECT * FROM vclothes WHERE id = @id AND identifier = @identifier AND type = @type', {
        ['@id'] = outfitId,
        ['@identifier'] = identifier,
        ['@type'] = "outfit",
    }, function(result)
        if not result or not result[1] then
            return cb(false, "Tenue introuvable")
        end
        
        local outfitRow = result[1]
        local rawData = outfitRow.data or outfitRow.clothe or outfitRow.skin
        local outfitData = type(rawData) == "string" and json.decode(rawData) or rawData
        
        if not outfitData or type(outfitData) ~= "table" then
            return cb(false, "Données de tenue corrompues")
        end
        
        -- Create individual pieces with descriptive labels
        local typeLabels = {
            top = "Haut",
            pants = "Pantalon",
            shoes = "Chaussures",
            mask = "Masque",
            hat = "Chapeau",
            glasses = "Lunettes",
            ears = "Oreilles",
            watches = "Montre",
            bracelets = "Bracelet",
            chain = "Chaîne",
            bproof = "Gilet pare-balles",
        }
        
        local piecesToCreate = {}
        for clotheType, pieceData in pairs(outfitData) do
            if type(pieceData) == "table" and pieceData.clothe then
                local label = typeLabels[clotheType] or clotheType
                if outfitRow.name and outfitRow.name ~= "" then
                    label = label .. " (" .. outfitRow.name .. ")"
                end
                
                table.insert(piecesToCreate, {
                    type = clotheType,
                    name = pieceData.name or pieceData.label or outfitRow.name,
                    label = label,
                    data = pieceData.clothe,
                })
            end
        end
        
        if #piecesToCreate == 0 then
            return cb(false, "La tenue est vide")
        end
        
        -- Insert all individual pieces and track their new IDs
        local completed = 0
        local total = #piecesToCreate
        local allSuccess = true
        local createdPieces = {}
        
        for _, piece in ipairs(piecesToCreate) do
            Clothes.Add(playerId, piece.type, piece.name, piece.label, piece.data, function(success, insertId)
                if not success or not insertId or insertId == 0 then 
                    allSuccess = false 
                end
                if success and insertId and insertId > 0 then
                    table.insert(createdPieces, {
                        id = insertId,
                        type = piece.type,
                        name = piece.name,
                        label = piece.label,
                    })
                end
                completed = completed + 1
                
                if completed >= total then
                    if allSuccess then
                        -- Delete the outfit
                        MySQL.Async.execute('DELETE FROM vclothes WHERE id = @id AND identifier = @identifier', {
                            ['@id'] = outfitId,
                            ['@identifier'] = identifier,
                        }, function()
                            Clothes.ClearCache(identifier)
                            cb(true, "Tenue désassemblée en " .. total .. " pièces", createdPieces)
                        end)
                    else
                        Clothes.ClearCache(identifier)
                        cb(false, "Erreur lors du désassemblage")
                    end
                end
            end)
        end
    end)
end

-- Equip an entire outfit (applies all pieces)
function Outfits.Equip(playerId, outfitId, cb)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then 
        return cb(false, "Joueur introuvable") 
    end
    
    local identifier = xPlayer.identifier
    
    MySQL.Async.fetchAll('SELECT * FROM vclothes WHERE id = @id AND identifier = @identifier AND type = @type', {
        ['@id'] = outfitId,
        ['@identifier'] = identifier,
        ['@type'] = "outfit",
    }, function(result)
        if not result or not result[1] then
            return cb(false, "Tenue introuvable")
        end
        
        local outfitRow = result[1]
        local rawData = outfitRow.data or outfitRow.clothe or outfitRow.skin
        local outfitData = type(rawData) == "string" and json.decode(rawData) or rawData
        
        if not outfitData or type(outfitData) ~= "table" then
            return cb(false, "Données de tenue corrompues")
        end
        
        -- Build the equipped clothes from outfit data
        local newEquipped = xPlayer.clothes_equiped or {}
        local skinChanges = {}
        
        for clotheType, pieceData in pairs(outfitData) do
            if type(pieceData) == "table" and pieceData.clothe then
                newEquipped[clotheType] = {
                    id = outfitId, -- Reference the outfit ID
                    name = pieceData.name or pieceData.label or outfitRow.name,
                    label = pieceData.label or pieceData.name or outfitRow.name,
                    data = pieceData.clothe,
                }
                
                -- Collect skin changes to send to client
                for propName, propValue in pairs(pieceData.clothe) do
                    skinChanges[propName] = propValue
                end
            end
        end
        
        -- Save equipped state
        xPlayer.set("clothes_equiped", newEquipped)
        Clothes.SaveEquipped(playerId, newEquipped)
        
        cb(true, skinChanges, newEquipped)
    end)
end

-- Server callbacks & events
ESX.RegisterServerCallback('null:outfits:create', function(source, cb, pieces, outfitName)
    Outfits.Create(source, pieces, outfitName, function(success, msg)
        if success then
            TriggerClientEvent("inventory:sendMessage", source, "~g~" .. msg)
        else
            TriggerClientEvent("inventory:sendMessage", source, "~r~" .. msg)
        end
        cb(success)
    end)
end)

ESX.RegisterServerCallback('null:outfits:disassemble', function(source, cb, outfitId)
    Outfits.Disassemble(source, outfitId, function(success, msg, createdPieces)
        if success then
            TriggerClientEvent("inventory:sendMessage", source, "~g~" .. msg)
        else
            TriggerClientEvent("inventory:sendMessage", source, "~r~" .. msg)
        end
        cb(success, createdPieces)
    end)
end)

ESX.RegisterServerCallback('null:outfits:equip', function(source, cb, outfitId)
    Outfits.Equip(source, outfitId, function(success, skinChanges, newEquipped)
        cb(success, skinChanges, newEquipped)
    end)
end)

_G.InventoryOutfits = Outfits
_G.InventoryOutfitsLoaded = true
--null.InitPrint("Inventory Outfits module loaded")
