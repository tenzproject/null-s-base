local BarBuilderCounter = 0
BarList = {}

while SaveData.json == nil do Wait(10) end
while SaveData.json["entreprises"] == nil do Wait(10) end

RegisterNetEvent('Null:createbarbuilder', function(namejob, labeljob, PosVestiaire, PosBar, PosBoss)
    local xPlayer = ESX.GetPlayerFromId(source)
    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        if SaveData.json["entreprises"]["Bar"][namejob] ~= nil then 
            return ESX.ShowNotification("Cette Entreprise Bar Existe déjà")
        end
        null.fct.sql.CheckJobAndCreate(namejob, labeljob)
        null.fct.sql.CheckSocietyAndCreate(namejob, labeljob)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "PDG", "boss", 2)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Responsable", "responsable", 1)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Employer", "employer", 0)
        MySQL.Async.fetchAll('SELECT * FROM `addon_account` WHERE `name` = @name', {
			['@name'] = 'society_'..namejob,
		}, function(result)
			if result[1] == nil then 
                MySQL.Async.execute("INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES (@name, @label, @shared) ", {
                    ['@name'] = 'society_'..namejob,
                    ['@label'] = labeljob,
                    ['@shared'] = 1
                })
            end
        end)
        MySQL.Async.fetchAll('SELECT * FROM `addon_inventory` WHERE `name` = @name', {
			['@name'] = 'society_'..namejob,
		}, function(result)
			if result[1] == nil then 
                MySQL.Async.execute("INSERT INTO `addon_inventory` (`name`, `label`, `shared`) VALUES (@name, @label, @shared) ", {
                    ['@name'] = 'society_'..namejob,
                    ['@label'] = labeljob,
                    ['@shared'] = 1
                })
            end
        end)

        BarBuilderCounter = BarBuilderCounter +1
        SaveData.json["entreprises"]["Bar"][namejob] = {}
        SaveData.json["entreprises"]["Bar"][namejob].type = "Bar"
        SaveData.json["entreprises"]["Bar"][namejob].name = namejob
        SaveData.json["entreprises"]["Bar"][namejob].label = labeljob
        SaveData.json["entreprises"]["Bar"][namejob].PosVestiaire = PosVestiaire
        SaveData.json["entreprises"]["Bar"][namejob].PosBar = PosBar
        SaveData.json["entreprises"]["Bar"][namejob].PosBoss = PosBoss
        

        Cache.SaveOne('entreprises')
        TriggerClientEvent('esx:showNotification', source, 'Le Job à été crée avec succès.')
        Wait(1000)
        ExecuteCommand('refreshGlobalsInformations')
        InitSociety2()
        TriggerClientEvent('Null:receiveBarBuilder', -1, SaveData.json["entreprises"]["Bar"])
    else
        ExecuteCommand("ban " .. source .. " Tentative de triche creation barbuilder (0)")
    end
end)

RegisterNetEvent('Null:bar:refreshSetJob', function(namejob)
    local xPlayer = ESX.GetPlayerFromId(source)
    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
        if SaveData.json["entreprises"]["Bar"][namejob] == nil then 
            return 
        end
        null.fct.sql.CheckJobAndCreate(namejob, labeljob)
        null.fct.sql.CheckSocietyAndCreate(namejob, labeljob)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "PDG", "boss", 2)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Responsable", "responsable", 1)
        null.fct.sql.CheckJobGradeAndCreate(namejob, "Employer", "employer", 0)
        
        MySQL.Async.fetchAll('SELECT * FROM `addon_account` WHERE `name` = @name', {
			['@name'] = 'society_'..namejob,
		}, function(result)
			if result[1] == nil then 
                MySQL.Async.execute("INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES (@name, @label, @shared) ", {
                    ['@name'] = 'society_'..namejob,
                    ['@label'] = labeljob,
                    ['@shared'] = 1
                })
            end
        end)
        MySQL.Async.fetchAll('SELECT * FROM `addon_inventory` WHERE `name` = @name', {
			['@name'] = 'society_'..namejob,
		}, function(result)
			if result[1] == nil then 
                MySQL.Async.execute("INSERT INTO `addon_inventory` (`name`, `label`, `shared`) VALUES (@name, @label, @shared) ", {
                    ['@name'] = 'society_'..namejob,
                    ['@label'] = labeljob,
                    ['@shared'] = 1
                })
            end
        end)

        Wait(3000)
        ExecuteCommand('refreshGlobalsInformations')
        InitSociety2()
    else
        ExecuteCommand("ban " .. source .. " Tentative de triche creation barbuilder (0)")
    end
end)

RegisterNetEvent('Null:DeleteBars', function(value)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		if SaveData.json["entreprises"]["Bar"][value] then
			SaveData.json["entreprises"]["Bar"][value] = nil
            BarBuilderCounter = BarBuilderCounter - 1
            Cache.SaveOne('entreprises')
            TriggerClientEvent('Null:receiveBarBuilder', -1, SaveData.json["entreprises"]["Bar"])
		end
	end
end)

RegisterNetEvent('Null:initBarBuilder', function()
	TriggerClientEvent('Null:receiveBarBuilder', source, SaveData.json["entreprises"]["Bar"], BarBuilderCounter)
end)

RegisterCommand('createbar', function(source,args)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		TriggerClientEvent('Null:createbarbuildermenu', source)
	end
end)

RegisterNetEvent("Null:bar:take", function(societyName, name, quantity)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.job.name == societyName then
        TriggerEvent('Null:esx_addoninventory:getSharedInventory', 'society_'..societyName, function(inventory)
            inventory.removeItem(name, quantity)
            xPlayer.addInventoryItem(name, quantity)
            xPlayer.showNotification("Vous avez pris : "..name.." "..quantity.."X")
            exports["null-core"]:SendLogs("Logs","Le joueur : "..xPlayer.getName().." (T"..source.." U"..xPlayer.getIdunique()..") a récuperer "..name.." "..quantity.."X dans le Bar ("..societyName..")","society", {idunique_auteur = xPlayer.getIdunique(), name = xPlayer.getName()})
        end)
    end
end)

ESX.RegisterServerCallback('Null:getStockItemsBar', function(source, cb, societyName)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.job.name == societyName then
        TriggerEvent('Null:esx_addoninventory:getSharedInventory', 'society_'..societyName, function(inventory)
            local finalinv = {}
            if inventory ~= nil then
                for k,v in pairs(inventory.items) do
                    if ESX.GetItem(v.name) == nil then
                        print("MERCI DE CREER L'ITEM : "..v.name.." POUR LE BAR : "..xPlayer.getJob().label)
                    else
                        table.insert(finalinv, {name=v.name,count=v.count,label=ESX.GetItemLabel(v.name)})
                    end
                end
            end
            cb(finalinv)
        end)
    else
        ExecuteCommand("ban " .. source .. " 0 Tentative de triche society (3)")
    end
end)