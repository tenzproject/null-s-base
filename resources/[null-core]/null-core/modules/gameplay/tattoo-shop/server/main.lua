RegisterNetEvent("null:tattoo:pay")
AddEventHandler("null:tattoo:pay", function(price,playerTatoos)
    local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
    local xMoney = xPlayer.getAccount('cash').money
    
    if xMoney >= price then
        xPlayer.removeAccountMoney('cash', price)
        xPlayer.showNotification("Merci pour votre achat !")
        TriggerClientEvent("null:tattoo:callback:pay", _src, true)
        performDbUpdate(playerTatoos,_src)
    else
        TriggerClientEvent("null:tattoo:callback:pay", _src, false)
    end
end)

-- ============================================================================
-- Null:tattoo:purchase
--   Variante de `null:tattoo:pay` qui MERGE les nouveaux tattoos avec les
--   tattoos existants en DB (évite l'écrasement). Utilisé par le nouveau
--   ped-shop mode tattoo où le cart contient seulement les nouveaux items.
--
--   `newTattoos` = liste { { cat=hash, name=hash }, ... }
-- ============================================================================
RegisterNetEvent("Null:tattoo:purchase")
AddEventHandler("Null:tattoo:purchase", function(price, newTattoos)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    if not xPlayer then return end

    local xMoney = xPlayer.getAccount('cash').money
    if xMoney < (price or 0) then
        TriggerClientEvent("null:tattoo:callback:pay", _src, false)
        return
    end

    local license = getPlayerLicense(_src)

    -- Charge les tattoos existants, merge, sauve.
    MySQL.Async.fetchAll("SELECT * FROM `playerstattoos` WHERE identifier = @identifier",
        { ['@identifier'] = license },
        function(rslt)
            local existing = {}
            if rslt[1] and rslt[1].tattoos then
                local ok, decoded = pcall(json.decode, rslt[1].tattoos)
                if ok and type(decoded) == "table" then existing = decoded end
            end

            -- Index existant par (cat:name) pour éviter les doublons
            local seen = {}
            for _, t in ipairs(existing) do
                if t.cat and t.name then seen[tostring(t.cat).."@"..tostring(t.name)] = true end
            end
            for _, t in ipairs(newTattoos or {}) do
                local key = tostring(t.cat).."@"..tostring(t.name)
                if not seen[key] then
                    table.insert(existing, { cat = t.cat, name = t.name })
                    seen[key] = true
                end
            end

            xPlayer.removeAccountMoney('cash', price)
            xPlayer.showNotification("Merci pour votre achat !")
            performDbUpdate(existing, _src)
            TriggerClientEvent("null:tattoo:callback:pay", _src, true)
            -- Refresh le ped client avec la nouvelle liste
            TriggerClientEvent("null:tattoo:player:callback", _src, json.encode(existing))
        end)
end)

function getAllLicense(source)
    for k,v in pairs(GetPlayerIdentifiers(source))do
    end
end

function getPlayerLicense(source)
    getAllLicense(source)
    for k,v in pairs(GetPlayerIdentifiers(source))do
        if string.sub(v, 1, string.len("license:")) == "license:" then
            return v
        end
    end
end


RegisterNetEvent("null:tattoo:pay:clean")
AddEventHandler("null:tattoo:pay:clean", function()
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
    local xMoney = xPlayer.getAccount('cash').money
    if xMoney >= 50000 then
        xPlayer.removeAccountMoney('cash', 50000)
        xPlayer.showNotification("Merci pour votre achat !")
        performDbClear(_src)

        TriggerClientEvent("null:tattoo:clean", _src, 1)

    else
        TriggerClientEvent("null:tattoo:clean", _src, 0)
    end
end)

RegisterNetEvent("null:tattoo:player:request:tattoo")
AddEventHandler("null:tattoo:player:request:tattoo", function()
    local _src = source
    local license = getPlayerLicense(_src)
    local result = nil
    MySQL.Async.fetchAll("SELECT * FROM `playerstattoos` WHERE identifier = @identifier", {['@identifier'] = license}, function(rslt)
        if rslt[1] ~= nil then
            result = rslt[1].tattoos
        else
            result = nil
        end
    end)
    Citizen.Wait(150)
    TriggerClientEvent("null:tattoo:player:callback", _src, result)
end)

function performDbUpdate(playerTatoos,_src)
    local license = getPlayerLicense(_src)
    local tattoos = json.encode(playerTatoos)
    MySQL.Async.fetchAll("SELECT * FROM `playerstattoos` WHERE identifier = @identifier", {['@identifier'] = license}, function(rslt)
        if rslt[1] ~= nil then
            MySQL.Async.execute("UPDATE `playerstattoos` SET tattoos = @tat WHERE identifier = @identifier",
            {['@identifier'] = license,['@tat'] = tattoos},
            function(insertId)
            end
        )
        else
            MySQL.Async.insert("INSERT INTO `playerstattoos` (`identifier`, `tattoos`) VALUES (@license, @tat)",
                {['@license'] = license,['@tat'] = tattoos},
                function(insertId)
                end
            )
        end
    end)
end

function performDbClear(_src)
    local license = getPlayerLicense(_src)
    MySQL.Async.fetchAll("SELECT * FROM `playerstattoos` WHERE identifier = @identifier", {['@identifier'] = license}, function(rslt)
        if rslt[1] ~= nil then
            MySQL.Async.execute("DELETE FROM `playerstattoos` WHERE identifier = @identifier",
            {['@identifier'] = license},
            function(insertId)
                
            end
        )
        end
    end)
end