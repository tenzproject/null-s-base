local PropertiesLoaded = false
local PlayerInProperties = {}
local PropertiesSaved = {}
local function Init()
    -- Patch : initialise parms pour les anciennes lignes qui ont NULL
    MySQL.Async.execute(
        "UPDATE properties_list SET parms=@parms WHERE parms IS NULL OR parms='' OR parms='null'",
        { ['@parms'] = json.encode({ GradesAlloweds = {}, PeopleAlloweds = {} }) }
    )
    SaveData.PropertiesList = {}
    MySQL.Async.fetchAll('SELECT * FROM properties_list', {}, function(data)
        for k,v in pairs(data) do
            local info = json.decode(v.info)
            if not SaveData.PropertiesList[info.name] then 
                SaveData.PropertiesList[info.name] = {}
                SaveData.PropertiesList[info.name].id = v.id
                SaveData.PropertiesList[info.name].name = info.name
                SaveData.PropertiesList[info.name].label = info.label 
                SaveData.PropertiesList[info.name].poids = tonumber(info.poids)
                SaveData.PropertiesList[info.name].price = tonumber(v.price) 
                local isBuy 
                if tonumber(v.isBuy) == 1 then 
                    isBuy = true
                else 
                    isBuy = false
                end
                SaveData.PropertiesList[info.name].isBuy = isBuy
                SaveData.PropertiesList[info.name].positions = json.decode(v.coords)
                SaveData.PropertiesList[info.name].owner = v.owner
                SaveData.PropertiesList[info.name].immeuble = v.immeuble
                v.data = json.decode(v.data)
                if v.data ~= nil then
                    if v.data["weapons"] ~= nil then
                        SaveData.PropertiesList[info.name].data = v.data
                    else 
                        SaveData.PropertiesList[info.name].data = v.data
                        SaveData.PropertiesList[info.name].data["weapons"] = {}
                    end
                else
                    SaveData.PropertiesList[info.name].data = {
                        ["weapons"] = {},
                        ['item'] = {},
                        ['accounts'] = {
                            cash = 0,
                            dirtycash = 0,
                        },
                    }
                end
                SaveData.PropertiesList[info.name].bucketID = tonumber("21"..tostring(math.random(1111, 9999)))
                local rawParms = v.parms
                local parsedParms = nil
                if type(rawParms) == "string" and rawParms ~= "" then
                    parsedParms = json.decode(rawParms)
                elseif type(rawParms) == "table" then
                    parsedParms = rawParms
                end
                if parsedParms ~= nil then
                    -- Normalize PeopleAlloweds: convert object/hash format to array
                    local rawPeople = parsedParms.PeopleAlloweds or {}
                    local normalizedPeople = {}
                    local seen = {}
                    for k, entry in pairs(rawPeople) do
                        if type(entry) == "table" and entry.identifier then
                            -- Proper format: {identifier, name, perms}
                            if not seen[entry.identifier] then
                                seen[entry.identifier] = true
                                table.insert(normalizedPeople, {
                                    identifier = entry.identifier,
                                    name = entry.name or entry.identifier,
                                    perms = entry.perms or { enter = true, deposit = true, withdraw = true },
                                })
                            end
                        elseif entry == true and type(k) == "string" and k:find("license:") then
                            -- Legacy/corrupt format: ["license:xxx"] = true
                            if not seen[k] then
                                seen[k] = true
                                table.insert(normalizedPeople, {
                                    identifier = k,
                                    name = k,
                                    perms = { enter = true, deposit = true, withdraw = true },
                                })
                            end
                        end
                    end
                    SaveData.PropertiesList[info.name].parms = {
                        GradesAlloweds = parsedParms.GradesAlloweds or {},
                        PeopleAlloweds = normalizedPeople,
                    }
                    if #normalizedPeople > 0 then
                        --print(("[^3PROPERTIES^0] Loaded %s with %d PeopleAlloweds"):format(info.name, #normalizedPeople))
                    end
                    -- Re-save to DB if format was corrupted (different from original)
                    local needsResave = false
                    for k, _ in pairs(rawPeople) do
                        if type(k) ~= "number" then needsResave = true break end
                    end
                    if needsResave and #normalizedPeople > 0 then
                        --print(("[^3PROPERTIES^0] Re-saving %s with normalized parms"):format(info.name))
                        MySQL.Async.execute('UPDATE properties_list SET parms=@parms WHERE name=@name', {
                            ['@parms'] = json.encode(SaveData.PropertiesList[info.name].parms),
                            ['@name']  = info.name,
                        })
                    end
                else
                    SaveData.PropertiesList[info.name].parms = {
                        GradesAlloweds = {},
                        PeopleAlloweds = {}
                    }
                    --print(("[^1PROPERTIES^0] %s has no parms (raw: %s)"):format(info.name, tostring(rawParms)))
                end
            end
        end
        PropertiesLoaded = true
        local count = 0
        for _ in pairs(SaveData.PropertiesList) do count = count + 1 end
        Citizen.CreateThread(function()
            Wait(10000) -- Wait 10 seconds for clients to be ready
            local players = ESX.GetPlayers()
            for _, playerId in ipairs(players) do
                TriggerClientEvent("null:properties:UpdatePropertiesList", playerId, SaveData.PropertiesList)
            end
        end)
    end)
end

Citizen.CreateThread(function()
    Init()
end)

local function SizeOfTable(t)
    local count = 0

    for k,v in pairs(t) do
        count = count + 1
    end

    return count
end

local function GetPlayerProperties(id)
    local _source = id 
    local xPlayer = ESX.GetPlayerFromId(_source)
    local xIdentifier = xPlayer.identifier
    local PlayerProperties = {}

    for k,v in pairs(SaveData.PropertiesList) do 
        if v.parms then
            for i=1, #v.parms.PeopleAlloweds, 1 do 
                if v.parms.PeopleAlloweds[i].identifier == xIdentifier then 
                    table.insert(PlayerProperties, v)
                end
            end
            if v.owner == xIdentifier then 
                table.insert(PlayerProperties, v)
            end
        end
    end
    return PlayerProperties
end

local function GetJobProperties(id)
    local _source = id 
    local xPlayer = ESX.GetPlayerFromId(_source)
    local JobProperties = {}

    for k,v in pairs(SaveData.PropertiesList) do 
        if v.owner == xPlayer.job.name then 
            table.insert(JobProperties, v)
        end
    end
    return JobProperties
end

local function GetJobProperties2(id)
    local _source = id 
    local xPlayer = ESX.GetPlayerFromId(_source)
    local JobProperties = {}

    for k,v in pairs(SaveData.PropertiesList) do 
        if v.owner == xPlayer.job2.name then 
            table.insert(JobProperties, v)
        end
    end
    return JobProperties
end

local function GetProperties(propertiesName)
    if SaveData.PropertiesList[propertiesName] then 
        return true, SaveData.PropertiesList[propertiesName]
    else 
        return false
    end
end

-- Retourne les permissions effectives d'un joueur sur une propriété.
-- Owner/job => toutes permissions. PeopleAlloweds => perms stockées.
-- Retourne nil si aucun accès.
local function GetPlayerPermForProperty(xPlayer, propData)
    if not propData then return nil end
    local isOwner = propData.owner == xPlayer.identifier
        or propData.owner == xPlayer.job.name
        or propData.owner == xPlayer.job2.name
    if isOwner then
        return { enter = true, deposit = true, withdraw = true }
    end
    if propData.parms and propData.parms.PeopleAlloweds then
        for _, v in ipairs(propData.parms.PeopleAlloweds) do
            if v.identifier == xPlayer.identifier then
                local p = v.perms or { enter = true, deposit = true, withdraw = true }
                return {
                    enter    = p.enter    ~= false,
                    deposit  = p.deposit  ~= false,
                    withdraw = p.withdraw ~= false,
                }
            end
        end
    end
    return nil
end

local function GetWeightRestantProperties(propertiesName, xPlayer)
    if SaveData.PropertiesList[propertiesName] then
        local totalWeight = 0
        local items = SaveData.PropertiesList[propertiesName].data and SaveData.PropertiesList[propertiesName].data["item"]
        if items and type(items) == "table" then
            for k,v in pairs(items) do
                local itemData = ESX.Items[v.name]
                if itemData then
                    totalWeight = totalWeight + (itemData.weight * v.count)
                end
            end
        end
        local weapons = SaveData.PropertiesList[propertiesName].data and SaveData.PropertiesList[propertiesName].data["weapons"]
        if weapons and type(weapons) == "table" then
            for k,v in pairs(weapons) do
                totalWeight = totalWeight + (ESX.GetWeaponWeight(v.name) or Config.WeaponDefaultWeight or 5)
            end
        end
        return totalWeight
    else
        return nil
    end
end

function SavePropreties(name, data, parms)
    MySQL.Async.execute("UPDATE properties_list SET data=@data, parms=@parms WHERE name=@name", {
        ["@name"] = name,
        ["@data"] = json.encode(data),
        ["@parms"] = json.encode(parms)
    })
end

Citizen.CreateThread(function()
    while not PropertiesLoaded do 
        Wait(100)
    end
    local SaveCount = 0
    while true do 
        local PropertiesCounter = 0
        for k,v in pairs(PropertiesSaved) do 
            PropertiesCounter = PropertiesCounter+1
            if v.parms then
                MySQL.Async.execute("UPDATE properties_list SET data=@data, parms=@parms WHERE name=@name", {
                    ["@name"] = v.name,
                    ["@data"] = json.encode(v.data),
                    ["@parms"] = json.encode(v.parms)
                })
            end
            PropertiesSaved[k] = nil
        end
        if PropertiesCounter ~= nil then 
            if PropertiesCounter ~= 0 then 
                --print('[^4SAVE^0] [^4'..PropertiesCounter..'^0] Propriétés ont été sauvegarder avec succès')
            end
        end
        Wait(30000)
    end
end)


RegisterServerEvent("null:properties:CreatedProperties", function(data) 
    local _source = source 
    local xPlayer = ESX.GetPlayerFromId(_source)

    if (xPlayer.getPermission("create-properties")) or (xPlayer.getJob() == "realestateagent" and #(GetEntityCoords(GetPlayerPed(_source)) - data.POSITION.EXIT) < 50) then 
        local info = {
            name = data.NAME,
            label = data.LABEL,
            poids = data.MaxWeight,
        } 
        if data.immeuble == '1' then 
            data.POSITION['EXIT'] = vector3(-773.5578, 311.4858, 85.6981)
        elseif data.immeuble == '2' then 
            data.POSITION['EXIT'] = vector3(-618.2738, 36.48872, 43.57004)
        elseif data.immeuble == '3' then 
            data.POSITION['EXIT'] = vector3(-882.6196, -436.1918, 39.5999)
        elseif data.immeuble == '4' then
            data.POSITION['EXIT'] = vector3(-47.73304, -585.7634, 37.95544)
        elseif data.immeuble == '5' then 
            data.POSITION['EXIT'] = vector3(-66.08768, -801.2214, 44.22728)
        end
        local coords = data.POSITION
        if not SaveData.PropertiesList[info.name] then 
            SaveData.PropertiesList[info.name] = {}
            SaveData.PropertiesList[info.name].id = math.random(111111,999999)
            SaveData.PropertiesList[info.name].name = info.name
            SaveData.PropertiesList[info.name].label = info.label 
            SaveData.PropertiesList[info.name].poids = tonumber(info.poids)
            SaveData.PropertiesList[info.name].price = tonumber(data.PRICE) 
            SaveData.PropertiesList[info.name].isBuy = false
            SaveData.PropertiesList[info.name].positions = coords
            SaveData.PropertiesList[info.name].owner = nil
            SaveData.PropertiesList[info.name].immeuble = data.immeuble
            SaveData.PropertiesList[info.name].data = {
                ["weapons"] = {},
                ['item'] = {},
                ['accounts'] = {
                    cash = 0,
                    dirtycash = 0,
                },
            }
            SaveData.PropertiesList[info.name].bucketID = tonumber("21"..tostring(math.random(1111, 9999)))
            SaveData.PropertiesList[info.name].parms = {
                GradesAlloweds = {},
                PeopleAlloweds = {},
            }
            MySQL.Async.execute('INSERT INTO properties_list (name, info, price, coords, immeuble, parms) VALUES (@name, @info, @price, @coords, @immeuble, @parms)', {
                ['@name'] = info.name,
                ['@info'] = json.encode(info),
                ['@price'] = tonumber(data.PRICE),
                ['@coords'] = json.encode(coords),
                ['@immeuble'] = data.immeuble,
                ['@parms'] = json.encode({ GradesAlloweds = {}, PeopleAlloweds = {} })
            })
            TriggerClientEvent('esx:showNotification', _source, "~p~Création de propriété~s~\nVotre propriété "..data.LABEL.." à bien était crée avec comme prix "..data.PRICE.."$.") 
            TriggerClientEvent("null:properties:UpdatePropertiesList", -1, SaveData.PropertiesList)
        else 
            TriggerClientEvent('esx:showNotification', _source, "~p~Création de propriété~s~\nUne propriété comporte déjà ce nom.") 
        end
    end
end)
RegisterServerEvent("null:properties:deleteProperties", function(data) 
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if xPlayer.getJob().name ~= "realestateagent" then
        return
    end
    SaveData.PropertiesList[data.name] = nil
    MySQL.Async.execute('DELETE FROM properties_list WHERE `name` = @name', {
        ['@name'] = data.name
    })
    TriggerClientEvent("null:properties:UpdatePropertiesList", -1, SaveData.PropertiesList)
end)
RegisterServerEvent("null:properties:virerOwnerProperties", function(data) 
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if xPlayer.getJob().name ~= "realestateagent" then
        return
    end
    SaveData.PropertiesList[data.name].owner = nil
    SaveData.PropertiesList[data.name].isBuy = false
    SaveData.PropertiesList[data.name].data = {}
    MySQL.Async.execute('UPDATE properties_list SET isBuy=@isBuy, owner=@owner, data=@data WHERE name=@name', {
        ['@name'] = data.name,
        ["@owner"] = nil,
        ['@isBuy'] = 0,
        ["@data"] = "[]"
    })
    TriggerClientEvent("null:properties:UpdatePropertiesList", -1, SaveData.PropertiesList)
end)

RegisterServerEvent("null:properties:PlayerBuyPropeties", function(data, player) 
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if player == nil then player = _source end
    local xTarget = ESX.GetPlayerFromId(player)
    if xPlayer.getJob().name ~= "realestateagent" or xTarget == nil then
        TriggerClientEvent('esx:showNotification', _source, "Il n'y aucun joueur au alentours") 
        return
    end
    --if #(GetEntityCoords(GetPlayerPed(_source)) - vector3(data.positions.EXIT.x, data.positions.EXIT.y, data.positions.EXIT.z)) < 50 then 
        local xMoney = xTarget.getAccount('cash').money 

        if xMoney >= data.price then 
            if SaveData.PropertiesList[data.name] then
                xTarget.removeAccountMoney('cash', data.price)
                SaveData.PropertiesList[data.name].isBuy = true
                SaveData.PropertiesList[data.name].owner = xTarget.identifier
                PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
                MySQL.Async.execute('UPDATE properties_list SET isBuy=@isBuy, owner=@owner WHERE name=@name', {
                    ['@name'] = data.name,
                    ["@owner"] = xTarget.identifier,
                    ['@isBuy'] = 1,
                })
                TriggerClientEvent('esx:showNotification', player, "~g~Achat propriété~s~\nVous avez payer "..data.price.."$ pour la propriété "..data.label..".") 
                TriggerClientEvent("null:properties:UpdatePropertiesBuyed",-1, data.name, true, xTarget.identifier)
                TriggerClientEvent("h:propertySyncProperties", -1)
            else 
                TriggerClientEvent('esx:showNotification', _source, "~r~Achat propriété~s~\nUne erreur est survenue lors de votre achat.") 
            end
        else
            TriggerClientEvent('esx:showNotification', _source, "~g~Achat propriété~s~\nLe joueur n'a pas l'argent nécessaire. (manque "..data.price-xMoney.."$)") 
        end
    --end
end)

RegisterServerEvent("null:properties:PlayerHasRenderProperties", function(data, priceRender) 
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local itsMyProperties = SaveData.PropertiesList[data.name] and SaveData.PropertiesList[data.name].owner == xPlayer.identifier or SaveData.PropertiesList[data.name].owner == xPlayer.job.name or SaveData.PropertiesList[data.name].owner == xPlayer.job2.name

    if itsMyProperties then
        if #(GetEntityCoords(GetPlayerPed(_source)) - vector3(data.positions.COFFRE.x, data.positions.COFFRE.y, data.positions.COFFRE.z)) < 50 then 
            if SaveData.PropertiesList[data.name] then
                xPlayer.addAccountMoney('cash', priceRender)
                SaveData.PropertiesList[data.name].isBuy = false
                SaveData.PropertiesList[data.name].owner = nil
                PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
                MySQL.Async.execute('UPDATE properties_list SET isBuy=@isBuy, owner=@owner, data=@data WHERE name=@name', {
                    ['@name'] = data.name,
                    ["@owner"] = nil,
                    ['@isBuy'] = 0,
                    ["@data"] = "[]"
                })
                TriggerClientEvent('esx:showNotification', _source, "~g~Reprise propriété~s~\nL'agence a repris votre "..data.label..". Vous avez reçu "..priceRender.."$.") 
                TriggerClientEvent("null:properties:UpdatePropertiesBuyed",-1, data.name, false, nil)
                TriggerClientEvent("h:propertySyncProperties", -1)
                TriggerClientEvent("null:properties:ExitProperties", _source, data.name)
                TriggerClientEvent("h:propertySyncProperties", -1)
            else 
                TriggerClientEvent('esx:showNotification', _source, "~r~Achat propriété~s~\nUne erreur est survenue lors de la reprise de votre propriété.") 
            end
        end
    end
end)

RegisterServerEvent("null:properties:PlayerAttribuetPropreties", function(data, value) 
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local itsMyProperties = SaveData.PropertiesList[data.name] and SaveData.PropertiesList[data.name].owner == xPlayer.identifier or SaveData.PropertiesList[data.name].owner == xPlayer.job.name or SaveData.PropertiesList[data.name].owner == xPlayer.job2.name
    
    if itsMyProperties and #(GetEntityCoords(GetPlayerPed(_source)) - vector3(data.positions.COFFRE.x, data.positions.COFFRE.y, data.positions.COFFRE.z)) < 50 then 
        if SaveData.PropertiesList[data.name] then
            if xPlayer.job.name == "unemployed" or xPlayer.job.name == "unemployed2" then 
                TriggerClientEvent('esx:showNotification', _source, "~r~Information propriété~s~\nVous ne pouvez pas attribuer cette propriété à ce job.") 
            else 
                if value == 1 then
                    SaveData.PropertiesList[data.name].owner = xPlayer.job.name
                    MySQL.Async.execute('UPDATE properties_list SET owner=@owner WHERE name=@name', {
                        ['@name'] = data.name,
                        ["@owner"] = xPlayer.job.name
                    })
                    local GradesAllowedTable = {}
                    for k,v in pairs(ESX.Jobs[xPlayer.job.name].grades) do 
                        GradesAllowedTable[v.label] = true
                    end
                    SaveData.PropertiesList[data.name].parms = {
                        GradesAlloweds = GradesAllowedTable,
                        PeopleAlloweds = {}
                    } 
                    PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
                    TriggerClientEvent('esx:showNotification', _source, "~g~Actions propriété~s~\nL'agence a attribué votre "..data.label.." à votre job "..xPlayer.job.label..".") 
                    TriggerClientEvent("null:properties:UpdatePropertiesJob",-1, data.name, xPlayer.job.name)
                else
                    SaveData.PropertiesList[data.name].owner = xPlayer.job2.name
                    MySQL.Async.execute('UPDATE properties_list SET owner=@owner WHERE name=@name', {
                        ['@name'] = data.name,
                        ["@owner"] = xPlayer.job2.name
                    })
                    local GradesAllowedTable = {}
                    for k,v in pairs(ESX.Jobs[xPlayer.job2.name].grades) do 
                        GradesAllowedTable[v.label] = true
                    end
                    SaveData.PropertiesList[data.name].parms = {
                        GradesAlloweds = GradesAllowedTable,
                        PeopleAlloweds = {}
                    } 
                    PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
                    TriggerClientEvent('esx:showNotification', _source, "~g~Actions propriété~s~\nL'agence a attribué votre "..data.label.." à votre job "..xPlayer.job2.label..".") 
                    TriggerClientEvent("null:properties:UpdatePropertiesJob",-1, data.name, xPlayer.job2.name)
                end
                TriggerClientEvent("null:properties:ExitProperties", _source, data.name)
            end
        else 
            TriggerClientEvent('esx:showNotification', _source, "~r~Information propriété~s~\nUne erreur est survenue lors de la reprise de votre propriété.") 
        end
    end
end)

local PlayersInPropertiesForExtended = {}

RegisterServerEvent("null:properties:SetBucket", function(interact, number)
    local _source = source
    
    if interact == "solo" then
        null.fct.instance.Set(_source, number, "Propriété")
        PlayersInPropertiesForExtended[_source] = true
    elseif interact == "group" then 
        null.fct.instance.Set(source, number, "Propriété")
        PlayersInPropertiesForExtended[_source] = true
    elseif interact == "remettre" then 
        null.fct.instance.Set(source, 0)
        PlayersInPropertiesForExtended[_source] = false
    end
end)

function PlayersInPropertiesForExtendedFc(id)
    return PlayersInPropertiesForExtended[id]
end

RegisterServerEvent("null:properties:PlayerSonnedToPropreties", function(data)
    local _source = source
    local waitTime = math.random(5000, 10000)

    if not ESX.Jobs[data.owner] then 
        if PlayerInProperties[data.name] then 
            if SizeOfTable(PlayerInProperties[data.name]) > 0 then 
                for k,v in pairs(PlayerInProperties[data.name]) do 
                    TriggerClientEvent("null:properties:NotificationSonnedProperties", v, data.name, _source)
                end
            else 
                Wait(waitTime)
                TriggerClientEvent('esx:showNotification', _source, "~r~Sonnette propriété~s~\nIl y a l'air d'y avoir personne dans cette propriété.") 
            end
        else 
            Wait(waitTime)
            TriggerClientEvent('esx:showNotification', _source, "~r~Sonnette propriété~s~\nIl y a l'air d'y avoir personne dans cette propriété.") 
        end
    else 
        if PlayerInProperties[data.name] then 
            if SizeOfTable(PlayerInProperties[data.name]) > 0 then 
                for k,v in pairs(PlayerInProperties[data.name]) do 
                    TriggerClientEvent("null:properties:NotificationSonnedProperties", v, data.name, _source)
                end
            else 
                Wait(waitTime)
                TriggerClientEvent('esx:showNotification', _source, "~r~Sonnette propriété~s~\nIl y a l'air d'y avoir personne dans cette propriété.") 
            end
        else 
            Wait(waitTime)
            TriggerClientEvent('esx:showNotification', _source, "~r~Sonnette propriété~s~\nIl y a l'air d'y avoir personne dans cette propriété.") 
        end
    end
end)

RegisterServerEvent("null:properties:ReturnPlayerSonnedProperties", function(interact, id, data, isLonguer)
    local _source = source
    
    if interact == "accept" then
        TriggerClientEvent('esx:showNotification', _source, "~g~Sonnette propriété~s~\nVous avez accepté la sonnerie.") 
        TriggerClientEvent("null:properties:EnterPropertiesBySonnet", id, data, data.bucketID)
    elseif interact == "decline" then 
        if not isLonguer then
            TriggerClientEvent('esx:showNotification', _source, "~r~Sonnette propriété~s~\nVous avez déclinner la sonnerie.")
        end 
        TriggerClientEvent('esx:showNotification', id, "~r~Sonnette propriété~s~\nLa personne a déclinner votre sonnerie.") 
    end
end)

RegisterServerEvent("null:properties:PlayerEntrerOrExitThisProperties", function(data, exitOrEnter) 
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local propData = SaveData.PropertiesList[data.name]
    local hasAccess = propData and (
        propData.owner == xPlayer.identifier or
        propData.owner == xPlayer.job.name or
        propData.owner == xPlayer.job2.name or
        GetPlayerPermForProperty(xPlayer, propData) ~= nil
    )

    if hasAccess then 
        if exitOrEnter == "enter" then 
            if not PlayerInProperties[data.name] then 
                PlayerInProperties[data.name] = {}
            end
            local alreadyIn = false
            for k,v in pairs(PlayerInProperties[data.name]) do 
                if v == _source then
                    alreadyIn = true
                    break
                end
            end
            if not alreadyIn then
                table.insert(PlayerInProperties[data.name], _source)
            end
        elseif exitOrEnter == "exit" then 
            if PlayerInProperties[data.name] then
                for k,v in pairs(PlayerInProperties[data.name]) do 
                    if v == _source then
                        table.remove(PlayerInProperties[data.name], k)
                    end
                end
            end
        end
    end
end)

RegisterNetEvent("null:properties:forceExitProperty", function(id)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.getPermission("FORCEEXITPROPERTY") then
        TriggerClientEvent("null:properties:forceExitProperty", id)
    end
end)
ESX.RegisterServerCallback("null:properties:getAllInProperty", function(source, cb)
    cb(PlayerInProperties)
end)

ESX.RegisterServerCallback("null:properties:inProperty", function(source, cb, id)
    local areIN = false
    for propertyname,data in pairs(PlayerInProperties) do
        if data then
            for k,v in pairs(data) do
                if v == id then
                    areIN = true
                end
            end
        end
    end
    cb(areIN)
end)

ESX.RegisterServerCallback("null:properties:GetProperties", function(source, cb)
    local attempts = 0
    while not PropertiesLoaded and attempts < 100 do
        Wait(100)
        attempts = attempts + 1
    end
    cb(SaveData.PropertiesList)
end)

ESX.RegisterServerCallback("null:properties:GetPlayerProperties", function(source, cb)
    local _source = source 
    local xPlayer = ESX.GetPlayerFromId(_source)
    local PlayerProperties = GetPlayerProperties(_source)
    local JobProperties = GetJobProperties(_source)
    local Job2Properties = GetJobProperties2(_source)
    cb(json.encode(PlayerProperties), json.encode(JobProperties), json.encode(Job2Properties))
end)

RegisterServerEvent("null:properties:GetCoffreProperties", function(propertiesName)
    if SaveData.PropertiesList[propertiesName] then
        local _source = source
        TriggerClientEvent("null:properties:GetCoffreProperties", _source, SaveData.PropertiesList[propertiesName].data)
    end
end)

RegisterServerEvent("null:properties:AddItemToPropertiesCoffre", function(data, item, count) 
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local PropertiesExist, PropertiesData = GetProperties(data.name)
    local perm = PropertiesExist and GetPlayerPermForProperty(xPlayer, PropertiesData)

    if #(GetEntityCoords(GetPlayerPed(_source)) - vector3(data.positions.COFFRE.x, data.positions.COFFRE.y, data.positions.COFFRE.z)) < 5 then 
        if perm and perm.deposit then 
            local infoItem = xPlayer.getInventoryItem(item)
            if not ESX.ContribItem(item) then
                local weightRestant = GetWeightRestantProperties(PropertiesData.name, xPlayer)
                local weightProperties = PropertiesData.poids 
                if infoItem then
                    if CheckQuantityIsValid(count) then 
                        if (weightProperties-weightRestant) >= (infoItem.weight*count) then
                            if not PropertiesData.data["item"][infoItem.name] then 
                                PropertiesData.data["item"][infoItem.name] = {}
                                PropertiesData.data["item"][infoItem.name].name = infoItem.name
                                PropertiesData.data["item"][infoItem.name].label = infoItem.label
                                PropertiesData.data["item"][infoItem.name].count = count
                                PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
                            else 
                                PropertiesData.data["item"][infoItem.name].count = PropertiesData.data["item"][infoItem.name].count + count
                                PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
                            end
                            xPlayer.removeInventoryItem(infoItem.name, count)
                            TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nVous avez déposer "..count.." "..infoItem.label.." dans le coffre.") 
                            TriggerClientEvent("null:properties:UpdateCoffreProperties", _source, PropertiesData.data)
                        else 
                            TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nIl n'y a pas assez de place dans le coffre pour antant de "..infoItem.label..".") 
                        end
                    else
                         xPlayer.showNotification('Quantité Invalide')
                    end
                else    
                    TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nVous n'avez pas cette quantitée.") 
                end
            else 
                TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nVous ne pouvez pas déposer cet item.") 
            end
        end
    end 
end)

RegisterServerEvent("null:properties:SuppItemToPropertiesCoffre", function(data, item, count) 
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local PropertiesExist, PropertiesData = GetProperties(data.name)
    local perm = PropertiesExist and GetPlayerPermForProperty(xPlayer, PropertiesData)

    if #(GetEntityCoords(GetPlayerPed(_source)) - vector3(data.positions.COFFRE.x, data.positions.COFFRE.y, data.positions.COFFRE.z)) < 5 then 
        if perm and perm.withdraw then 
            local infoItem = xPlayer.getInventoryItem(item)
            local weightRestant = GetWeightRestantProperties(PropertiesData.name, xPlayer)
            local weightProperties = PropertiesData.poids 
            if infoItem then 
                if xPlayer.canCarryItem(item, count) then
                    if PropertiesData.data["item"][infoItem.name] then 
                        if CheckQuantityIsValid(count) then 
                            if PropertiesData.data["item"][infoItem.name].count >= count then
                                PropertiesData.data["item"][infoItem.name].count = PropertiesData.data["item"][infoItem.name].count - count
                                if PropertiesData.data["item"][infoItem.name].count == 0 then
                                    PropertiesData.data["item"][infoItem.name] = nil
                                end
                                PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
                            else
                                TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nIl n\'y a pas assez d\'item dans le coffre")
                                return
                            end
                        else
                            xPlayer.showNotification('Quantité Invalide')
                        end
                    else 
                        TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nIl n\'y a pas assez d\'item dans le coffre")
                        return
                    end
                    xPlayer.addInventoryItem(infoItem.name, count)
                    TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nVous avez pris "..count.." "..infoItem.label.." dans le coffre.") 
                    TriggerClientEvent("null:properties:UpdateCoffreProperties", _source, PropertiesData.data)
                else 
                    TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nVous ne pouvez pas prendre cette quantité.") 
                end
            else    
                TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nVous n'avez pas cette quantitée.") 
            end
        end
    end 
end)



RegisterServerEvent("null:properties:AddWeaponsToPropertiesCoffre", function(data, weaponInfo, ammo)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local PropertiesExist, PropertiesData = GetProperties(data.name)
    local perm = PropertiesExist and GetPlayerPermForProperty(xPlayer, PropertiesData)

    if #(GetEntityCoords(GetPlayerPed(_source)) - vector3(data.positions.COFFRE.x, data.positions.COFFRE.y, data.positions.COFFRE.z)) < 5 then
        if perm and perm.deposit then 
            local weightRestant = GetWeightRestantProperties(PropertiesData.name, xPlayer)
            local weightProperties = PropertiesData.poids 
            if weaponInfo then 
                if not ESX.ContribWeapon(weaponInfo.name) and not weaponInfo.permanent then
                    --if Config.Properties.PoidsWeapons[weaponInfo.name] then
                        if (weightProperties-weightRestant) >= (ESX.GetWeaponWeight(weaponInfo.name)) then
                            local random = math.random(0, 999999)
                            if not PropertiesData.data["weapons"][random] then 
                                PropertiesData.data["weapons"][random] = {}
                                PropertiesData.data["weapons"][random].name = weaponInfo.name
                                PropertiesData.data["weapons"][random].label = weaponInfo.label
                                PropertiesData.data["weapons"][random].ammo = ammo
                            else 
                                local random = math.random(0, 999999)
                                PropertiesData.data["weapons"][random] = {}
                                PropertiesData.data["weapons"][random].name = weaponInfo.name
                                PropertiesData.data["weapons"][random].label = weaponInfo.label
                                PropertiesData.data["weapons"][random].ammo = ammo
                            end
                            PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
                            xPlayer.removeWeapon(weaponInfo.name)
                            TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nVous avez déposer un(e) "..weaponInfo.label.." dans le coffre.") 
                            TriggerClientEvent("null:properties:UpdateCoffreProperties", _source, PropertiesData.data)
                        else 
                            TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nIl n'y a pas assez de place dans le coffre pour un(e) "..weaponInfo.label..".") 
                        end 
                    --end
                else
                    ESX.showNotification("~g~Propriété\n~s~Vous ne pouvez pas déposer cette armes.")
                end
            else    
                TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nUne erreur est survenu.") 
            end
        end
    end 
end)

RegisterServerEvent("null:properties:SuppWeaponsToPropertiesCoffre", function(data, weaponInfo, random, ammo)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local PropertiesExist, PropertiesData = GetProperties(data.name)
    local perm = PropertiesExist and GetPlayerPermForProperty(xPlayer, PropertiesData)

    if #(GetEntityCoords(GetPlayerPed(_source)) - vector3(data.positions.COFFRE.x, data.positions.COFFRE.y, data.positions.COFFRE.z)) < 5 then
        if perm and perm.withdraw then 
            local weightRestant = GetWeightRestantProperties(PropertiesData.name, xPlayer)
            local weightProperties = PropertiesData.poids 
            if weaponInfo then
                if not xPlayer.hasWeapon(weaponInfo.name) then
                    PropertiesData.data["weapons"][random] = nil
                    PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
                    xPlayer.addWeapon(weaponInfo.name, ammo)
                    TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nVous avez pris un(e) "..weaponInfo.label.." dans le coffre.") 
                    TriggerClientEvent("null:properties:UpdateCoffreProperties", _source, PropertiesData.data)
                else 
                    TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nVous avez déjà un(e) "..weaponInfo.label..".") 
                end 
            else    
                TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nUne erreur est survenu.") 
            end
        end
    end 
end)

RegisterServerEvent("null:properties:AddMoneyToPropertiesCoffre", function(data, moneyType, amount) 
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local PropertiesExist, PropertiesData = GetProperties(data.name)
    local perm = PropertiesExist and GetPlayerPermForProperty(xPlayer, PropertiesData)

    if #(GetEntityCoords(GetPlayerPed(_source)) - vector3(data.positions.COFFRE.x, data.positions.COFFRE.y, data.positions.COFFRE.z)) < 5 then 
        if perm and perm.deposit then 
            if xPlayer.getAccount(moneyType).money >= amount then
                PropertiesData.data["accounts"][moneyType] = PropertiesData.data["accounts"][moneyType] + amount
                PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
                xPlayer.removeAccountMoney(moneyType, amount)
                TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nVous avez déposer "..amount.." de "..moneyType.." dans le coffre.") 
                TriggerClientEvent("null:properties:UpdateCoffreProperties", _source, PropertiesData.data)
            else 
                TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nVous n'avez pas cette quantitée.") 
            end
        end
    end 
end)

RegisterServerEvent("null:properties:SuppMoneyToPropertiesCoffre", function(data, moneyType, amount) 
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local PropertiesExist, PropertiesData = GetProperties(data.name)
    local perm = PropertiesExist and GetPlayerPermForProperty(xPlayer, PropertiesData)

    if #(GetEntityCoords(GetPlayerPed(_source)) - vector3(data.positions.COFFRE.x, data.positions.COFFRE.y, data.positions.COFFRE.z)) < 5 then 
        if perm and perm.withdraw then 
            if PropertiesData.data["accounts"][moneyType] >= amount then
                PropertiesData.data["accounts"][moneyType] = PropertiesData.data["accounts"][moneyType] - amount
                PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
                xPlayer.addAccountMoney(moneyType, amount)
                TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nVous avez pris "..amount.." de "..moneyType.." dans le coffre.") 
                TriggerClientEvent("null:properties:UpdateCoffreProperties", _source, PropertiesData.data)
            else 
                TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nVous n'avez pas cette quantitée.") 
            end
        end
    end 
end)


RegisterServerEvent('loadlicense', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    if xPlayer == nil then return end
    TriggerClientEvent('InitLicense', xPlayer.source, xPlayer.identifier)
end)

local PlayerOpenedCoffre = {}

RegisterServerEvent('null:properties:playerOpenedCoffre', function(propertiesName)
    local _source = source 

	if not PlayerOpenedCoffre[propertiesName] then 
		PlayerOpenedCoffre[propertiesName] = _source
	else 
		PlayerOpenedCoffre[propertiesName] = _source
	end
end)

RegisterServerEvent('null:properties:playerClosedCoffre', function(propertiesName)
    local _source = source
    -- Security: only the player who opened can close
    if PlayerOpenedCoffre[propertiesName] == _source then
        PlayerOpenedCoffre[propertiesName] = nil
    end
end)

ESX.RegisterServerCallback('null:properties:CheckIfPlayerInCoffre', function(source, cb, propertiesName)
	local _source = source

    if PlayerOpenedCoffre[propertiesName] then 
		cb(true)
	else 
		cb(false)
	end
end)

RegisterServerEvent('null:properties:GetGradeListProperties', function(data)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local itsMyProperties = SaveData.PropertiesList[data.name] and SaveData.PropertiesList[data.name].owner == xPlayer.identifier or SaveData.PropertiesList[data.name].owner == xPlayer.job.name or SaveData.PropertiesList[data.name].owner == xPlayer.job2.name
    local PropertiesExist, PropertiesData = GetProperties(data.name)

    if #(GetEntityCoords(GetPlayerPed(_source)) - vector3(data.positions.COFFRE.x, data.positions.COFFRE.y, data.positions.COFFRE.z)) < 5 then 
        if itsMyProperties then 
            local GradeList = {}
            for k,v in pairs(ESX.Jobs[data.owner].grades) do 
                table.insert(GradeList, v.label)
            end
            TriggerClientEvent("null:properties:ResultOfGradeListProperties", _source, GradeList, PropertiesData.parms.GradesAlloweds)
        end
    end 
end)

RegisterServerEvent('null:properties:UpdateGradeListProperties', function(data, newGradesAlloweds)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local itsMyProperties = SaveData.PropertiesList[data.name] and SaveData.PropertiesList[data.name].owner == xPlayer.identifier or SaveData.PropertiesList[data.name].owner == xPlayer.job.name or SaveData.PropertiesList[data.name].owner == xPlayer.job2.name
    local PropertiesExist, PropertiesData = GetProperties(data.name)

    if #(GetEntityCoords(GetPlayerPed(_source)) - vector3(data.positions.COFFRE.x, data.positions.COFFRE.y, data.positions.COFFRE.z)) < 5 then 
        if itsMyProperties and PropertiesExist then 
            PropertiesData.parms.GradesAlloweds = newGradesAlloweds
            PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
            -- TriggerClientEventAll("null:properties:UpdatePropertiesList", SaveData.PropertiesList)
        end
    end 
end)

RegisterServerEvent('null:properties:CheckIfGradeNotExistProperties', function(data, jobType)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local itsMyProperties = SaveData.PropertiesList[data.name] and SaveData.PropertiesList[data.name].owner == xPlayer.identifier or SaveData.PropertiesList[data.name].owner == xPlayer.job.name or SaveData.PropertiesList[data.name].owner == xPlayer.job2.name
    local PropertiesExist, PropertiesData = GetProperties(data.name)

    if #(GetEntityCoords(GetPlayerPed(_source)) - vector3(data.positions.COFFRE.x, data.positions.COFFRE.y, data.positions.COFFRE.z)) < 5 then 
        if itsMyProperties and PropertiesExist then 
            if ESX.Jobs[data.owner] then
                local GradesAllowedTable = {}
                if jobType == "job" then 
                    for k,v in pairs(ESX.Jobs[xPlayer.job.name].grades) do 
                        GradesAllowedTable[v.label] = true
                    end
                else 
                    for k,v in pairs(ESX.Jobs[xPlayer.job2.name].grades) do 
                        GradesAllowedTable[v.label] = true
                    end
                end
                SaveData.PropertiesList[data.name].parms.GradesAlloweds = GradesAllowedTable
                PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
                -- TriggerClientEventAll("null:properties:UpdatePropertiesList", SaveData.PropertiesList)
            end
        end
    end 
end)

RegisterServerEvent('null:properties:PlayerDonnedKeysToPlayerProperties', function(data, targetId, perms)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local itsMyProperties = SaveData.PropertiesList[data.name] and SaveData.PropertiesList[data.name].owner == xPlayer.identifier or SaveData.PropertiesList[data.name].owner == xPlayer.job.name or SaveData.PropertiesList[data.name].owner == xPlayer.job2.name
    local PropertiesExist, PropertiesData = GetProperties(data.name)
    local safePerms = {
        enter    = perms and perms.enter    ~= false,
        deposit  = perms and perms.deposit  ~= false,
        withdraw = perms and perms.withdraw ~= false,
    }

    if #(GetEntityCoords(GetPlayerPed(_source)) - vector3(data.positions.COFFRE.x, data.positions.COFFRE.y, data.positions.COFFRE.z)) < 5 then 
        if itsMyProperties and PropertiesExist then 
            local xTarget = ESX.GetPlayerFromId(targetId)
            if xTarget then 
                table.insert(PropertiesData.parms.PeopleAlloweds, {
                    name       = xTarget.getName(),
                    identifier = xTarget.identifier,
                    perms      = safePerms,
                })
                PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
                MySQL.Async.execute('UPDATE properties_list SET parms=@parms WHERE name=@name', {
                    ['@parms'] = json.encode(PropertiesData.parms),
                    ['@name']  = data.name,
                })
                local permStr = (safePerms.enter and "Entrée " or "")..(safePerms.deposit and "Dépôt " or "")..(safePerms.withdraw and "Retrait" or "")
                TriggerClientEvent('esx:showNotification', _source, "~g~Clés données~s~\nPerms : "..permStr)
                TriggerClientEvent('esx:showNotification', targetId, "~g~Clés reçues~s~\n"..PropertiesData.label.." — Perms : "..permStr)
                TriggerClientEvent("null:properties:UpdatePropertiesList", targetId, SaveData.PropertiesList)
                TriggerClientEvent("null:properties:UpdatePropertiesList", _source, SaveData.PropertiesList)
                -- Notify recipient to refresh permissions if already inside the property
                TriggerClientEvent("null:properties:KeysUpdated", targetId, data.name, safePerms)
            else 
                TriggerClientEvent('esx:showNotification', _source, "~g~Coffre propriété~s~\nLe joueur a déconnecté.") 
            end
        end
    end 
end)

RegisterServerEvent('null:properties:RevokeKeysProperties', function(data, idx)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local itsMyProperties = SaveData.PropertiesList[data.name] and SaveData.PropertiesList[data.name].owner == xPlayer.identifier or SaveData.PropertiesList[data.name].owner == xPlayer.job.name or SaveData.PropertiesList[data.name].owner == xPlayer.job2.name
    local PropertiesExist, PropertiesData = GetProperties(data.name)

    if itsMyProperties and PropertiesExist then
        local person = PropertiesData.parms.PeopleAlloweds[idx]
        if person then
            local revokedId = person.identifier
            local revokedName = person.name
            table.remove(PropertiesData.parms.PeopleAlloweds, idx)
            PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
            MySQL.Async.execute('UPDATE properties_list SET parms=@parms WHERE name=@name', {
                ['@parms'] = json.encode(PropertiesData.parms),
                ['@name']  = data.name,
            })
            TriggerClientEvent('esx:showNotification', _source, "~r~Accès retiré~s~\n"..revokedName.." n'a plus accès.")
            TriggerClientEvent("null:properties:UpdatePropertiesList", _source, SaveData.PropertiesList)
            local xRevoked = ESX.GetPlayerFromIdentifier(revokedId)
            if xRevoked then
                TriggerClientEvent('esx:showNotification', xRevoked.source, "~r~Accès retiré~s~\nVos clés pour "..PropertiesData.label.." ont été révoquées.")
                TriggerClientEvent("null:properties:UpdatePropertiesList", xRevoked.source, SaveData.PropertiesList)
                -- Notify to refresh access (will remove coffre marker if inside)
                TriggerClientEvent("null:properties:KeysRevoked", xRevoked.source, data.name)
            end
        end
    end
end)

RegisterServerEvent('null:properties:UpdateAccessPermsProperties', function(data, idx, newPerms)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local itsMyProperties = SaveData.PropertiesList[data.name] and SaveData.PropertiesList[data.name].owner == xPlayer.identifier or SaveData.PropertiesList[data.name].owner == xPlayer.job.name or SaveData.PropertiesList[data.name].owner == xPlayer.job2.name
    local PropertiesExist, PropertiesData = GetProperties(data.name)

    if itsMyProperties and PropertiesExist then
        local person = PropertiesData.parms.PeopleAlloweds[idx]
        if person then
            person.perms = {
                enter    = newPerms.enter    ~= false,
                deposit  = newPerms.deposit  ~= false,
                withdraw = newPerms.withdraw ~= false,
            }
            PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
            MySQL.Async.execute('UPDATE properties_list SET parms=@parms WHERE name=@name', {
                ['@parms'] = json.encode(PropertiesData.parms),
                ['@name']  = data.name,
            })
            TriggerClientEvent("null:properties:UpdatePropertiesList", _source, SaveData.PropertiesList)
            local xTarget = ESX.GetPlayerFromIdentifier(person.identifier)
            if xTarget then
                TriggerClientEvent("null:properties:UpdatePropertiesList", xTarget.source, SaveData.PropertiesList)
                -- Notify about permission changes
                TriggerClientEvent("null:properties:KeysUpdated", xTarget.source, data.name, person.perms)
            end
            TriggerClientEvent('esx:showNotification', _source, "~g~Accès mis à jour~s~\nPerms de "..person.name.." modifiées.")
        end
    end
end)

function CheckQuantityIsValid(Quantity)
    if tonumber(Quantity) then 
        if tonumber(Quantity) > 0 then 
            return true
        else
            return false
        end
    end
end


RegisterNetEvent('null:properties:buy')
AddEventHandler('null:properties:buy', function(properties, type, immeuble, typebought)
    local id = math.random(11111111,99999999)
    local randomname = type..id
    local immmeuuble = nil
    for k,v in pairs(Config.Properties.apartment) do
        if v.id == immeuble then
            immmeuuble = v
            break
        end
    end

    local data = {
        price=properties.prices[typebought], 
        name=randomname, 
        immeuble=tostring(immeuble),
        label = immmeuuble.label,
        POSITION = {
            ['EXIT'] = immmeuuble.Position,
            ['COFFRE'] = Config.Properties.List[type].positions.cam_coords,
            ['ENTER'] = Config.Properties.List[type].positions.inside,
        },
    }
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    --if #(GetEntityCoords(GetPlayerPed(_source)) - vector3(data.positions.EXIT.x, data.positions.EXIT.y, data.positions.EXIT.z)) < 50 then 
        local xMoney = xPlayer.getAccount('cash').money 

        if xMoney >= properties.prices[typebought] then 
            if SaveData.PropertiesList[data.name] == nil then
                local info = {
                    name = data.name,
                    label = immmeuuble.label.."-"..id,
                    poids = properties.MaxWeight,
                } 
                local coords = data.POSITION
                SaveData.PropertiesList[info.name] = {}
                SaveData.PropertiesList[info.name].id = id
                SaveData.PropertiesList[info.name].name = info.name
                SaveData.PropertiesList[info.name].label = info.label 
                SaveData.PropertiesList[info.name].poids = info.poids
                SaveData.PropertiesList[info.name].price = properties.prices[typebought]
                SaveData.PropertiesList[info.name].isBuy = true
                SaveData.PropertiesList[info.name].positions = coords
                SaveData.PropertiesList[info.name].owner = xPlayer.identifier
                SaveData.PropertiesList[info.name].immeuble = data.immeuble
                SaveData.PropertiesList[info.name].data = {
                    ["weapons"] = {},
                    ['item'] = {},
                    ['accounts'] = {
                        cash = 0,
                        dirtycash = 0,
                    },
                }
                SaveData.PropertiesList[info.name].bucketID = tonumber("21"..tostring(math.random(1111, 9999)))
                SaveData.PropertiesList[info.name].parms = {
                    GradesAlloweds = {},
                    PeopleAlloweds = {},
                }
                MySQL.Async.execute('INSERT INTO properties_list (id,name, info, price, coords, immeuble, parms) VALUES (@id,@name, @info, @price, @coords, @immeuble, @parms)', {
                    ['@id'] = SaveData.PropertiesList[info.name].id,
                    ['@name'] = info.name,
                    ['@info'] = json.encode(info),
                    ['@price'] = tonumber(properties.prices[typebought]),
                    ['@coords'] = json.encode(coords),
                    ['@immeuble'] = data.immeuble,
                    ['@parms'] = json.encode({ GradesAlloweds = {}, PeopleAlloweds = {} })
                })
                TriggerClientEvent("null:properties:UpdatePropertiesList", -1, SaveData.PropertiesList)
                xPlayer.removeAccountMoney('cash', data.price)
                PropertiesSaved[data.name] = SaveData.PropertiesList[data.name]
                MySQL.Async.execute('UPDATE properties_list SET isBuy=@isBuy, owner=@owner WHERE name=@name', {
                    ['@name'] = data.name,
                    ["@owner"] = xPlayer.identifier,
                    ['@isBuy'] = 1,
                })
                TriggerClientEvent('esx:showNotification', _source, "~g~Achat propriété~s~\nVous avez payer "..data.price.."$.") 
                TriggerClientEvent("null:properties:UpdatePropertiesBuyed",-1, data.name, true, xPlayer.identifier)
                TriggerClientEvent("h:propertySyncProperties", -1)
            else
                TriggerClientEvent('esx:showNotification', _source, "~g~Probleme achat~s~\nUn probleme a eu lieu lors de la création de votre propriété.") 
            end
        else
            TriggerClientEvent('esx:showNotification', _source, "~g~Achat propriété~s~\nVous n'avez pas l'argent nécessaire. (manque "..data.price-xMoney.."$)") 
        end
    --end
end)

-- Send properties data to newly connected players
AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    while not PropertiesLoaded do
        Wait(100)
    end
    -- Send full properties list to the new player
    TriggerClientEvent("null:properties:UpdatePropertiesList", playerId, SaveData.PropertiesList)
end)

-- Allow client to request properties data explicitly (after resource restart)
RegisterServerEvent('null:properties:RequestData')
AddEventHandler('null:properties:RequestData', function()
    local _source = source
    local attempts = 0
    while not PropertiesLoaded and attempts < 100 do
        Wait(100)
        attempts = attempts + 1
    end
    if SaveData.PropertiesList then
        TriggerClientEvent("null:properties:UpdatePropertiesList", _source, SaveData.PropertiesList)
    end
end)