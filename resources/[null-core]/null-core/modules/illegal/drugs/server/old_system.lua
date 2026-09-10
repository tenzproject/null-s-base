local TotalPerPly = {
    ["recolte"] = {},
    ["traitement"] = {},
    ["vente"] = {},
}

RegisterNetEvent('null:drugs:stop', function(type)
    local src = source
    TotalPerPly["recolte"][src] = 0
    TotalPerPly["traitement"][src] = 0
end)

RegisterNetEvent('zmain:drugs:drugs', function(item, type)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if (not xPlayer) then return end
    local count = 0

    if item == "weed" or item == "meth" or item == "coke" then

    else
        if drugs_circuits[item] == nil then return end
        if drugs_circuits[item]["position"][type] == nil then return end
        local pos = drugs_circuits[item]["position"][type][1]
        local distance = #(GetEntityCoords(GetPlayerPed(xPlayer.source)) - vector3(pos.x, pos.y, pos.z))
        if distance > 30 then
            TotalPerPly["recolte"][xPlayer.source] = 0
            TotalPerPly["traitement"][xPlayer.source] = 0
            return
        end
    end

    if type == 'recolte' then
        if (xPlayer) then
            count = 3
            xPlayer.addInventoryItem(Config.Drugs.Items[item][type].name, count)
            if TotalPerPly["recolte"][xPlayer.source] == nil then TotalPerPly["recolte"][xPlayer.source] = 0 end
            TotalPerPly["recolte"][xPlayer.source] = TotalPerPly["recolte"][xPlayer.source] + count
            TriggerClientEvent("inventory:sendMessage", xPlayer.source, ('🌿 Vous avez récolté ~y~+%s~s~ %s'):format(TotalPerPly["recolte"][xPlayer.source], Config.Drugs.Items[item][type].label))
            --TriggerClientEvent('esx:showNotification', source, ('🌿 Vous avez récolté ~y~+%s~s~ %s'):format(count, Config.Drugs.Items[item][type].label))
        end
    elseif type == 'traitement' then
        if (xPlayer) then
            if xPlayer.getInventoryItem(Config.Drugs.Items[item]['recolte'].name).count < 4 then return TriggerClientEvent('esx:showNotification', source, ('⚠️ Vous ne possédez pas assez de ~y~%s~s~ pour traiter'):format(item)) end

            if TotalPerPly["traitement"][xPlayer.source] == nil then TotalPerPly["traitement"][xPlayer.source] = 0 end
            TotalPerPly["traitement"][xPlayer.source] = TotalPerPly["traitement"][xPlayer.source] + 4
            xPlayer.removeInventoryItem(Config.Drugs.Items[item]['recolte'].name, 4)
            xPlayer.addInventoryItem(Config.Drugs.Items[item][type].name, 4)

            --TriggerClientEvent('esx:showNotification', source, ('🌿 ~y~x%s~s~ %s'):format(TotalPerPly["traitement"][xPlayer.source], Config.Drugs.Items[item][type].label))
            TriggerClientEvent("inventory:sendMessage", xPlayer.source, ('🌿 Vous avez traiter ~y~+%s~s~ %s'):format(TotalPerPly["traitement"][xPlayer.source], Config.Drugs.Items[item][type].label))
        end
    end
end)

RegisterNetEvent('zmain:drugs:addTable', function(table)
    Config.Drugs.Items = table
end)

drugs_circuits = {}
drugs_laboratories = {}

exports('getDrugs', function()
    return drugs_circuits
end)


local drugs_sell = {}

local drugs_sellid = {}

CreateThread(function() 
    local function fetch()
        local drugs_circuitscount = 0
        MySQL.Async.fetchAll('SELECT * FROM drugs_circuits', {}, function(result)
            for k,v in pairs(result) do
                drugs_circuitscount = drugs_circuitscount + 1
                drugs_circuits[v.name] = {
                    ["id"] = v.id,
                    ["name"] = v.name,
                    ["label"] = v.label,
                    ['position'] = {
                        ["recolte"] = json.decode(v.recolte),
                        ["traitement"] = json.decode(v.traitement)
                    },
                    ['data'] = {
                        ["recolte"] = {
                            name = v.name,
                            label = v.label,
                            animtype = v.animtype,
                            animdict = v.animdict,
                            anim = v.anim,
                            animtime = v.animtime,
                            marker = v.marker,
                            props = v.props
                        },
                        ["traitement"] = {
                            name = v.name_pooch,
                            label = v.label_pooch,
                            animtype = v.animtype_t,
                            animdict = v.animdict_t,
                            anim = v.anim_t,
                            animtime = v.animtime_t,
                            marker = v.marker_t,
                            props = v.props_t
                        },
                    }
                }
            end
            TriggerEvent("null:core:recevieload:DrugsCircuitCount", drugs_circuitscount)
            --Wait(10000)
            --print('[^4LOAD^0] [^4'..drugs_circuitscount..'^0] Circuit de drogues ont été load avec succès')
        end)
    end
    
    fetch()

    RegisterNetEvent('zmain:drugs:load', function()
        local source = source

        TriggerClientEvent('zmain:drugs:load', source, drugs_circuits)
    end)

    RegisterNetEvent('zmain:drugs:create', function(data)
        local source = source

        if data.traitement_anim == nil then
            data.traitement_anim = 'none'
        end

        if data.recolte_anim == nil then
            data.recolte_anim = 'none'
        end

        if data.recolte_props == nil then
            data.recolte_props = 'none'
        end

        if data.traitement_props == nil then
            data.traitement_props = 'none'
        end

        if data.recolte_marker == nil then
            data.recolte_marker = false
        end

        MySQL.Async.fetchAll('SELECT * FROM `items` WHERE `name` = @name', {
			['@name'] = data.name_pooch,
		}, function(result)
			if result[1] == nil then 
                MySQL.Async.execute("INSERT INTO `items` (`name`, `label`, `weight`) VALUES (@name, @label, @weight) ", {
                    ['@name'] = data.name_pooch,
                    ['@label'] = data.label_pooch,
                    ['@weight'] = 1
                })
            end
        end)
        MySQL.Async.fetchAll('SELECT * FROM `items` WHERE `name` = @name', {
			['@name'] = data.name
		}, function(result)
			if result[1] == nil then 
                MySQL.Async.execute("INSERT INTO `items` (`name`, `label`, `weight`) VALUES (@name, @label, @weight) ", {
                    ['@name'] = data.name,
                    ['@label'] = data.label,
                    ['@weight'] = 1
                })
            end
        end)

        MySQL.Async.execute('INSERT INTO drugs_circuits (name, label, recolte, traitement, animtype, animdict, anim, animtime, marker, props, name_pooch, label_pooch, animtype_t, animdict_t, anim_t, animtime_t, marker_t, props_t) VALUES (@name, @label, @recolte, @traitement, @animtype, @animdict, @anim, @animtime, @marker, @props, @name_pooch, @label_pooch, @animtype_t, @animdict_t, @anim_t, @animtime_t, @marker_t, @props_t)', {
            ['@name'] = data.name,
            ['@label'] = data.label,
            ['@recolte'] = json.encode(data.posRecolte),
            ['@traitement'] = json.encode(data.posTraitement),
            ['@animtype'] = data.recolte_animtype,
            ['@animdict'] = data.recolte_animdict,
            ['@anim'] = data.recolte_anim,
            ['@animtime'] = data.recolte_animtime,
            ['@marker'] = data.recolte_marker,
            ['@props'] = data.recolte_props,
            ['@name_pooch'] = data.name_pooch,
            ['@label_pooch'] = data.label_pooch,
            ['@animtype_t'] = data.traitement_animtype,
            ['@animdict_t'] = data.traitement_animdict,
            ['@anim_t'] = data.traitement_anim,
            ['@animtime_t'] = data.traitement_animtime,
            ['@marker_t'] = data.traitement_marker,
            ['@props_t'] = data.traitement_props
        }, function()
            --ESX.Notifi(source, 'Drogue crée avec succès')

            Wait(1000)
            
            fetch()

            Wait(1000)

            TriggerClientEvent('zmain:drugs:load', -1, drugs_circuits)

            TriggerClientEvent('zmain:drugs:refresh', -1, data.name)
        end)
    end)

    RegisterNetEvent('zmain:admin:drugs:update', function(drugsName, data)
        if not drugsName then return end
        if not data then return end
        if type(data) ~= "table" then return end

        
    end)

    local illegal_laboratorycount = 0
    local function fetchLabo()
        MySQL.Async.fetchAll('SELECT * FROM illegal_laboratory', {}, function(result)
            for k,v in pairs(result) do
                illegal_laboratorycount = illegal_laboratorycount + 1
                drugs_laboratories[v.id] = {
                    id = v.id,
                    name = v.name,
                    type = v.type,
                    interior = json.decode(v.interior),
                    owner = v.owner,
                    pos = json.decode(v.pos),
                }

            end
            TriggerEvent("null:core:recevieload:DrugsLaboratoryCount", illegal_laboratorycount)
            --Wait(10000)
            --print('[^4LOAD^0] [^4'..illegal_laboratorycount..'^0] Laboratoires de drogues ont été load avec succès')
        end)
    end

    local drugssellcount = 0
    local function fetchSell()
        MySQL.Async.fetchAll('SELECT * FROM drugs_sell', {}, function(result)
            for k,v in pairs(result) do
                drugssellcount = drugssellcount + 1
                table.insert(drugs_sell, {
                    pos = json.decode(v.position),
                    message = v.message,
                    id = tonumber(v.id)
                })
                pos = json.decode(v.position)
                table.insert(drugs_sellid, {id=v.id, message=v.message, posx=pos.x, posy=pos.y})
            end
            TriggerEvent("null:core:recevieload:DrugsSellsCount", drugssellcount)
            --Wait(10000)
            --print('[^4LOAD^0] [^4'..drugssellcount..'^0] Vendeurs de drogues ont été load avec succès')
        end)
    end

    CreateThread(function()
        fetchLabo()
        fetchSell()
    end)

    RegisterNetEvent('zmain:labs:fetchAll', function()
        local source = source
        TriggerClientEvent('zmain:labs:recieve', source, drugs_laboratories)
        TriggerClientEvent('zmain:labs:recieve2', source, drugs_laboratories)

        TriggerClientEvent('zmain:admin:drugs:sendSell', source, drugs_sell)
    end)

    RegisterNetEvent('zmain:admin:labo:create', function(data)
        MySQL.insert("INSERT INTO illegal_laboratory (name, type, interior, owner, pos) VALUES (?,?,?,?,?)", {
            data.name,
            data.activeLaboratoryName,
            json.encode({}),
            'none',
            json.encode(data.pos)
        }, function()
            fetchLabo()

            TriggerClientEvent('zmain:labs:recieve', -1, drugs_laboratories)
            TriggerClientEvent('zmain:labs:recieve2', -1, drugs_laboratories)
        end)
    end)

    local illegal_laboratorycount = 0
    local function fetchLabo()
        MySQL.Async.fetchAll('SELECT * FROM illegal_laboratory', {}, function(result)
            for k,v in pairs(result) do
                illegal_laboratorycount = illegal_laboratorycount + 1
                drugs_laboratories[v.id] = {
                    id = v.id,
                    name = v.name,
                    type = v.type,
                    interior = json.decode(v.interior),
                    owner = v.owner,
                    pos = json.decode(v.pos),
                }

            end
            TriggerEvent("null:core:recevieload:DrugsLaboratoryCount", illegal_laboratorycount)
            --Wait(10000)
            --print('[^4LOAD^0] [^4'..illegal_laboratorycount..'^0] Laboratoires de drogues ont été load avec succès')
        end)
    end

    RegisterNetEvent('zmain:drugs:labo:delete', function(id)
        MySQL.Async.execute('DELETE FROM illegal_laboratory WHERE id = @id', {
                ['@id'] = id
        }, function()
            drugs_laboratories[id] = nil
                
            fetchLabo()

            Wait(1000)
            TriggerEvent('zmain:labs:recieve', -1, drugs_laboratories)
            TriggerEvent('zmain:labs:recieve2', -1, drugs_laboratories)
            --TriggerClientEvent('zmain:admin:drugs:sendSell', -1, drugs_sell)
        end) 
    end)

    RegisterNetEvent('zmain:drugs:circuit:delete', function(name)
        MySQL.Async.execute('DELETE FROM drugs_circuits WHERE name = @name', {
                ['@name'] = name
        }, function()
            drugs_circuits[name] = nil
        end) 
    end)
    RegisterNetEvent('zmain:drugs:circuit:update:pos', function(name, type,index, newpos)
        for k,v in pairs(drugs_circuits[name]['position'][type]) do
            if k == index then
                drugs_circuits[name]['position'][type][k] = newpos
            end
        end
        MySQL.Async.execute('UPDATE drugs_circuits SET recolte = @recolte WHERE name = @name', {
            ['@name'] = name,
            ['@recolte'] = json.encode(drugs_circuits[name]['position'][type]),
        })
    end)
end)


ESX.RegisterServerCallback("null:getDrugsItems",function(source,cb)
    cb(drugs_circuits)
end)