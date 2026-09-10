local gangbuildercounter = 0

local DefaultStats = {
	["criminalité"] = 0.0,
	["confiance"] = 75.0,
	["honneur"] = 50.0,
	["morale"] = 50.0,
}

function ChangeGroupeStat(name, key, val, type)
	if SaveData.json["groupes-stats"][name] == nil then 
		SaveData.json["groupes-stats"][name] = DefaultStats
	end
	if type == nil then type = "add" end
	if type == "add" and SaveData.json["groupes-stats"][name][key] + val <= 100.0 then
		SaveData.json["groupes-stats"][name][key] = SaveData.json["groupes-stats"][name][key] + val
	elseif type == "add" then
		SaveData.json["groupes-stats"][name][key] = 100.0
	elseif type == "remove" and SaveData.json["groupes-stats"][name][key] - val >= 0.0 then
		SaveData.json["groupes-stats"][name][key] = SaveData.json["groupes-stats"][name][key] - val
	elseif type == "remove" then
		SaveData.json["groupes-stats"][name][key] = 0.0
	end
end

function getGroupeStat(name)
	if SaveData.json["groupes-stats"][name] == nil then 
		SaveData.json["groupes-stats"][name] = DefaultStats
	end
	return SaveData.json["groupes-stats"][name]
end

ESX.RegisterServerCallback("null:groupe:getStats", function(source, cb, name)
	cb(getGroupeStat(name))
end)

-- ============================================================================
-- Convert weapon craft config to inventory crafting format
-- ============================================================================

local function convertWeaponCraftsToRecipes()
	local recipes = {}
	if not Config.IllegalGroups or not Config.IllegalGroups.Craft or not Config.IllegalGroups.Craft.Weapons then
		return recipes
	end
	for weaponName, craft in pairs(Config.IllegalGroups.Craft.Weapons) do
		local reqs = craft.requirements or {}
		table.insert(recipes, {
			id = string.lower(weaponName),
			label = craft.label or weaponName,
			item = craft.name or weaponName,
			type = "weapon",
			time = craft.time or 10,
			category = "armes",
			description = "Fabriquer: " .. (craft.label or weaponName),
			requirements = reqs,
		})
	end
	return recipes
end

local function syncGangCraftTables()
	while not Config.Crafting do Wait(0) end
	Config.Crafting.Tables = Config.Crafting.Tables or {}

	-- Remove existing gang craft tables
	local cleaned = {}
	for _, t in ipairs(Config.Crafting.Tables) do
		if not t._isGangCraft then
			table.insert(cleaned, t)
		end
	end
	Config.Crafting.Tables = cleaned

	local weaponRecipes = convertWeaponCraftsToRecipes()

	-- Add craft tables for gangs that have FabArme enabled and a posFabrication
	for gangname, gang in pairs(SaveData.gangs) do
		if (gang.FabArme == 1 or gang.FabArme == true) and gang.posFabrication then
			local coords = vector3(gang.posFabrication.x, gang.posFabrication.y, gang.posFabrication.z)
			table.insert(Config.Crafting.Tables, {
				id = "gang_craft_" .. gangname,
				label = "Fabrication d'armes",
				coords = coords,
				conditions = { job2 = gangname },
				recipes = weaponRecipes,
				_isGangCraft = true,
			})
		end
	end
end

RegisterNetEvent('null:createGang', function(namegang, labelgang, positonCoffre, KitArme, FabArme, zone, haveStarterpack, type, gangTier, posFabrication)
	local posCoffre = json.encode(positonCoffre)
    local xPlayer = ESX.GetPlayerFromId(source)
	if KitArme then
		KitArme = 1 
	else 
		KitArme = 0
	end
	if FabArme then
		FabArme = 1 
	else 
		FabArme = 0
	end
	if zone == nil then
		zone = {}
	end
    if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil and Config.GroupeHighPerm[xPlayer.getGroup()] == true then
		if SaveData.gangs[namegang] ~= nil then
			return 
			ESX.ShowNotification("Ce gang existe déjà")
		end
		local webhook = 'https://discord.com/api/webhooks/1187151378603315341/XQdWA3bu2JpnOp9LovrAGT6DHM6RRB21tBpoeE76BVCy13yYxCG5DuX1GOaJfCURcWsE'
		OthersLogsDetails("Logs Admin",xPlayer.getName().." ("..xPlayer.getIdunique()..") a créer un nouveau groupe illégal. Nom du groupe : "..namegang.. ". Label du groupe : "..labelgang..". Position :".. positonCoffre,"create-illegal-group")
		CreateStorage(namegang)
		local tier = math.max(1, math.min(4, tonumber(gangTier) or 2))
		MySQL.Async.execute("INSERT INTO `vgangs` (`gangname`,`ganglabel`, `posCoffre`, `KitArme`, `FabArme`, `zone`, `tier`, `posFabrication`) VALUES (@gangname,@ganglabel, @posCoffre, @KitArme, @FabArme, @zone, @tier, @posFabrication) ", {
            ['@gangname'] = namegang,
            ['@ganglabel'] = labelgang,
            ['@posCoffre'] = posCoffre,
			['@KitArme'] = KitArme,
			['@FabArme'] = FabArme,
			['@zone'] = json.encode(zone),
			['@tier'] = tier,
			['@posFabrication'] = posFabrication and json.encode(posFabrication) or nil,
        })
		MySQL.Async.fetchAll('SELECT * FROM `jobs` WHERE `name` = @name', {
			['@name'] = namegang
		}, function(result)
			if result[1] == nil then
				MySQL.Async.execute("INSERT INTO `jobs` (`name`, `label`, `whitelisted`, `illegal`) VALUES (@name, @label, @whitelisted, @illegal) ", {
					['@name'] = namegang,
					['@label'] = labelgang,
					['@whitelisted'] = 1,
					['@illegal'] = 1
				})	
			else
				print("Attemp to insert a existing jobs ("..namegang..")")
			end
		end)
		MySQL.Async.fetchAll('SELECT * FROM `job_grades` WHERE `job_name` = @job_name AND `name` = @name', {
			['@job_name'] = namegang,
			['@name'] = "boss"
		}, function(result)
			if result[1] == nil then
				MySQL.Async.execute("INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES (@job_name, @grade, @name, @label, @salary, @skin_male, @skin_female)", {
					['@job_name'] = namegang,
					['@grade'] = 3,
					['@name'] = "boss",
					['@label'] = "Boss",
					['@salary'] = 0,
					['@skin_male'] = "{}",
					['@skin_female'] = "{}"
				})
			else
				print("Attemp to insert a existing jobs grade ("..namegang..") (boss)")
			end
		end)
		MySQL.Async.fetchAll('SELECT * FROM `job_grades` WHERE `job_name` = @job_name AND `name` = @name', {
			['@job_name'] = namegang,
			['@name'] = "gerant"
		}, function(result)
			if result[1] == nil then
				MySQL.Async.execute("INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES (@job_name, @grade, @name, @label, @salary, @skin_male, @skin_female)", {
					['@job_name'] = namegang,
					['@grade'] = 2,
					['@name'] = "gerant",
					['@label'] = "Gérant",
					['@salary'] = 0,
					['@skin_male'] = "{}",
					['@skin_female'] = "{}"
				})
			else
				print("Attemp to insert a existing jobs grade ("..namegang..") (gerant)")
			end
		end)
		MySQL.Async.fetchAll('SELECT * FROM `job_grades` WHERE `job_name` = @job_name AND `name` = @name', {
			['@job_name'] = namegang,
			['@name'] = "membre"
		}, function(result)
			if result[1] == nil then
				MySQL.Async.execute("INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES (@job_name, @grade, @name, @label, @salary, @skin_male, @skin_female)", {
					['@job_name'] = namegang,
					['@grade'] = 1,
					['@name'] = "membre",
					['@label'] = "Membre",
					['@salary'] = 0,
					['@skin_male'] = "{}",
					['@skin_female'] = "{}"
				})
			else
				print("Attemp to insert a existing jobs grade ("..namegang..") (membre)")
			end
		end)
		MySQL.Async.fetchAll('SELECT * FROM `job_grades` WHERE `job_name` = @job_name AND `name` = @name', {
			['@job_name'] = namegang,
			['@name'] = "recrue"
		}, function(result)
			if result[1] == nil then
				MySQL.Async.execute("INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES (@job_name, @grade, @name, @label, @salary, @skin_male, @skin_female)", {
					['@job_name'] = namegang,
					['@grade'] = 0,
					['@name'] = "recrue",
					['@label'] = "Recrue",
					['@salary'] = 0,
					['@skin_male'] = "{}",
					['@skin_female'] = "{}"
				})
			else
				print("Attemp to insert a existing jobs grade ("..namegang..") (recrue)")
			end
		end)
        MySQL.Async.execute("INSERT INTO `addon_account` (`name`, `label`, `shared`) VALUES (@name, @label, @shared) ", {
            ['@name'] = 'society_'..namegang,
            ['@label'] = labelgang,
            ['@shared'] = 1
        })
        MySQL.Async.execute("INSERT INTO `addon_inventory` (`name`, `label`, `shared`) VALUES (@name, @label, @shared) ", {
            ['@name'] = 'society_'..namegang,
            ['@label'] = labelgang,
            ['@shared'] = 1
        })
		MySQL.Async.fetchAll('SELECT * FROM `society` WHERE `name` = @name', {
			['@name'] = namegang
		}, function(result)
            if result[1] == nil then 
				MySQL.Async.execute("INSERT INTO `society` (`name`, `label`, `legal`) VALUES (@name, @label, @legal) ", {
					['@name'] = namegang,
					['@label'] = labelgang,
					['@legal'] = 0
				})
            end
        end)
		Wait(500)
		ExecuteCommand("refreshGlobalsInformations")
		Wait(100)
		SaveData.gangs[namegang] = {}
		SaveData.gangs[namegang].name = namegang
		SaveData.gangs[namegang].label = labelgang
		SaveData.gangs[namegang].posCoffre = positonCoffre
		SaveData.gangs[namegang].Point = 0
		SaveData.gangs[namegang].zone = zone
		SaveData.gangs[namegang].KitArme = KitArme
		SaveData.gangs[namegang].FabArme = FabArme
		SaveData.gangs[namegang].posFabrication = posFabrication or nil
		if ESX.Jobs[namegang] == nil then
			SaveData.gangs[namegang].GradeList = {}
		else
			SaveData.gangs[namegang].GradeList = ESX.Jobs[namegang].grades
		end
		SaveData.gangs[namegang].State = false
		SaveData.gangs[namegang].StatePly = {}
		SaveData.gangs[namegang].PlyList = {}

		SaveData.gangs[namegang].perms_coffre = {
			["0"] = false,
			["1"] = false,
			["2"] = false,
			["3"] = true,
		}
		SaveData.gangs[namegang].perms_recruter = {
			["0"] = false,
			["1"] = false,
			["2"] = false,
			["3"] = true,
		}
		SaveData.gangs[namegang].perms_promouvoir = {
			["0"] = false,
			["1"] = false,
			["2"] = false,
			["3"] = true,
		}
		SaveData.gangs[namegang].perms_gestionmembre = {
			["0"] = false,
			["1"] = false,
			["2"] = false,
			["3"] = true,
		}
		SaveData.gangs[namegang].perms_vente = {
			["0"] = false,
			["1"] = false,
			["2"] = false,
			["3"] = true,
		}
		SaveData.gangs[namegang].perms_fabrication = {
			["0"] = false,
			["1"] = false,
			["2"] = false,
			["3"] = true,
		}
		ExecuteCommand("refreshGlobalsInformations")
		syncGangCraftTables()
		TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
		Citizen.CreateThread(function()
			if haveStarterpack then
				xPlayer.showNotification("Importation du StarterPack, veuillez patientez 15 secondes")
				Citizen.Wait(2000)
				for k, v in pairs(Config.StarterPack["Illégal"][type]) do
					Wait(500)
					print(v.type, v.name, v.quantity)
					if v.type == "weapon" then
						for i = 1, v.quantity do
							AddWeaponToStorage(namegang, v.name, "Ceci est une arme du groupe : "..labelgang)
							Wait(500)
						end
					elseif v.type == "vehicle" then
						for i = 1, v.quantity do
							LiteMySQL:Insert('owned_vehicles', {
								owner = namegang,
								plate = CreateRandomPlate(),
								vehicle = json.encode({ model = v.name, plate = plate }),
								type = "car",
								state = 1,
								boutique = 0,
							})
							print("Added vehicle "..v.name.." to storage : "..namegang)
						end
					elseif v.type == "money" then
						AddMoneyToStorage(namegang, v.name, v.quantity)
					elseif v.type == "item" then
						AddItemToStorage(namegang, v.name, v.quantity)
					end
				end
			else
				xPlayer.showNotification("✅ "..type.." créer avec succées")
			end
		end)
    end
end)

local vcounnt01 = 0
IllegalGroupsLoaded = false
Citizen.CreateThread(function()
	SaveData.gangs = {}
	IllegalGroupsLoaded = false
    MySQL.Async.fetchAll('SELECT * FROM vgangs', {}, function(Gangs)
		gangbuildercounter = 0
        for i=1, #Gangs, 1 do
			gangbuildercounter = gangbuildercounter + 1
            SaveData.gangs[Gangs[i].gangname] = {}
            SaveData.gangs[Gangs[i].gangname].name = Gangs[i].gangname 
            SaveData.gangs[Gangs[i].gangname].posCoffre = json.decode(Gangs[i].posCoffre)
			if Gangs[i].zone == nil then
				SaveData.gangs[Gangs[i].gangname].zone = {}
			else
				SaveData.gangs[Gangs[i].gangname].zone = json.decode(Gangs[i].zone)
			end
            SaveData.gangs[Gangs[i].gangname].Point = Gangs[i].point
			SaveData.gangs[Gangs[i].gangname].KitArme = Gangs[i].KitArme
			SaveData.gangs[Gangs[i].gangname].FabArme = Gangs[i].FabArme
			if Gangs[i].posFabrication and Gangs[i].posFabrication ~= "" then
				SaveData.gangs[Gangs[i].gangname].posFabrication = json.decode(Gangs[i].posFabrication)
			else
				SaveData.gangs[Gangs[i].gangname].posFabrication = nil
			end
			SaveData.gangs[Gangs[i].gangname].State = false
			SaveData.gangs[Gangs[i].gangname].StatePly = {}
			SaveData.gangs[Gangs[i].gangname].PlyList = {}

			if ESX.Jobs[Gangs[i].gangname] ~= nil then
				if Gangs[i].ganglabel == nil then
					Gangs[i].ganglabel = ESX.Jobs[Gangs[i].gangname].label
					MySQL.Async.execute("UPDATE `vgangs` SET `ganglabel` = '"..Gangs[i].ganglabel.."' WHERE `gangname` = '"..Gangs[i].gangname.."'", {}, function()  end)
				end

				if ESX.Jobs[Gangs[i].gangname].grades ~= nil then
					SaveData.gangs[Gangs[i].gangname].GradeList = ESX.Jobs[Gangs[i].gangname].grades
				else
					SaveData.gangs[Gangs[i].gangname].GradeList = {}
					MySQL.Async.fetchAll('SELECT * FROM job_grades WHERE job_name = @jobname ORDER BY `grade` DESC ;', {
						['@jobname'] = Gangs[i].gangname
					}, function(result)
						if result[1] ~= nil and result ~= nil then
							for k,v in pairs(result) do
								SaveData.gangs[Gangs[i].gangname].GradeList[v.grade] = {grade = v.grade, label = v.label}
							end
						end
					end)
				end
			else
				if Gangs[i].ganglabel == nil then
					Gangs[i].ganglabel = "Inconnu"
				end
				SaveData.gangs[Gangs[i].gangname].GradeList = {}
				MySQL.Async.fetchAll('SELECT * FROM job_grades WHERE job_name = @jobname ORDER BY `grade` DESC ;', {
					['@jobname'] = Gangs[i].gangname
				}, function(result)
					if result[1] ~= nil and result ~= nil then
						for k,v in pairs(result) do
							SaveData.gangs[Gangs[i].gangname].GradeList[v.grade] = {grade = v.grade, label = v.label}
						end
					end
				end)
			end
			
            SaveData.gangs[Gangs[i].gangname].label = Gangs[i].ganglabel 
			local DefaultPerm = {}
			for k,v in pairs(SaveData.gangs[Gangs[i].gangname].GradeList) do
				if v.name == "boss" then
					DefaultPerm[tonumber(k)] = true
				else
					DefaultPerm[tonumber(k)] = false
				end
			end

			Gangs[i].perms_coffre = json.decode(Gangs[i].perms_coffre)
			if Gangs[i].perms_coffre == nil then
				Gangs[i].perms_coffre = {}
			end
			SaveData.gangs[Gangs[i].gangname].perms_coffre = Gangs[i].perms_coffre

			
			Gangs[i].perms_recruter = json.decode(Gangs[i].perms_recruter)
			if Gangs[i].perms_recruter == nil then
				Gangs[i].perms_recruter = {}
			end
			SaveData.gangs[Gangs[i].gangname].perms_recruter = Gangs[i].perms_recruter

			Gangs[i].perms_promouvoir = json.decode(Gangs[i].perms_promouvoir)
			if Gangs[i].perms_promouvoir == nil then
				Gangs[i].perms_promouvoir = {}
			end
			SaveData.gangs[Gangs[i].gangname].perms_promouvoir = Gangs[i].perms_promouvoir
			
			Gangs[i].perms_gestionmembre = json.decode(Gangs[i].perms_gestionmembre)
			if Gangs[i].perms_gestionmembre == nil then
				Gangs[i].perms_gestionmembre = {}
			end
			SaveData.gangs[Gangs[i].gangname].perms_gestionmembre = Gangs[i].perms_gestionmembre
			
			Gangs[i].perms_vente = json.decode(Gangs[i].perms_vente)
			if Gangs[i].perms_vente == nil then
				Gangs[i].perms_vente = {}
			end
			SaveData.gangs[Gangs[i].gangname].perms_vente = Gangs[i].perms_vente
			
			Gangs[i].perms_fabrication = json.decode(Gangs[i].perms_fabrication)
			if Gangs[i].perms_fabrication == nil then
				Gangs[i].perms_fabrication = {}
			end
			SaveData.gangs[Gangs[i].gangname].perms_fabrication = Gangs[i].perms_fabrication

			MySQL.Async.fetchAll('SELECT * FROM users WHERE job2 = @job2', {
				['@job2'] = Gangs[i].gangname 
			}, function (result)
				if result[1] ~= nil then
					for k,v in pairs(result) do
						SaveData.gangs[Gangs[i].gangname].PlyList[v.idunique] = {name=v.name,firstname=v.firstname,lastname=v.lastname,idunique=v.idunique,job2=v.job2,job=v.job,job2_grade=v.job2_grade,job_grade=v.job_grade,identifier=v.identifier}
					end
				else
					SaveData.gangs[Gangs[i].gangname].PlyList = {}
				end
			end)
        end
		IllegalGroupsLoaded = true
		syncGangCraftTables()
		TriggerEvent("null:core:recevieload:GangCount", gangbuildercounter)
		--Wait(10000)
		--print('[^4LOAD^0] [^4'..gangbuildercounter..'^0] Gang ont été load avec succès')
    end)
end)

RegisterNetEvent("null:illegal:gangsbuilder:addgrade")
AddEventHandler("null:illegal:gangsbuilder:addgrade", function(job, label)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getJob2().name ~= job then return end
	if xPlayer.getJob2().grade_name ~= "boss" then return end

	pos = math.random(111,999)
	name = "playergrade_"..tostring(pos)

	MySQL.Async.execute("INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`) VALUES (@job_name, @grade, @name, @label) ", {
		['@job_name'] = job,
		['@grade'] = pos,
		['@name'] = name,
		['@label'] = label
	})
	Wait(500)
	ExecuteCommand("refreshGlobalsInformations")
	Wait(500)
	SaveData.gangs[job].GradeList[tostring(pos)] = {name=name,label=label}
	OthersLogsDetails("Logs Groupe Illégal","Le joueur "..xPlayer.getName().." ("..xPlayer.getIdunique()..") a ajouter un grade : "..label.." ("..name..") ("..job..")","gestion-illegal-group", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})
		
	TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
end)

RegisterNetEvent("null:illegal:gangsbuilder:removegrade")
AddEventHandler("null:illegal:gangsbuilder:removegrade", function(job, name, pos)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.getJob2().name ~= job then return end
	if xPlayer.getJob2().grade_name ~= "boss" then return end

	MySQL.update('DELETE FROM job_grades WHERE name = @name AND job_name = @job_name', {
		['@name'] = name,
		['@job_name'] = job
	}, function()
	Wait(500)
	ExecuteCommand("refreshGlobalsInformations")
	Wait(500)
	OthersLogsDetails("Logs Groupe Illégal","Le joueur "..xPlayer.getName().." ("..xPlayer.getIdunique()..") a supprimer un grade : "..name.." ("..job..")","gestion-illegal-group", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})
		
	SaveData.gangs[job].GradeList[tostring(pos)] = nil 
	TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
	end)
end)

RegisterNetEvent("null:changeperms")
AddEventHandler("null:changeperms", function(type, new, job)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
	local gangname = xPlayer.getJob2().name
	local encodedNew = json.encode(new)

	if type == "perms_coffre" then
		SaveData.gangs[gangname].perms_coffre = new
		MySQL.Async.execute("UPDATE `vgangs` SET `perms_coffre` = @new WHERE `gangname` = @gangname", {['@new'] = encodedNew, ['@gangname'] = gangname}, function() end)
	elseif type == "perms_recruter" then
		SaveData.gangs[gangname].perms_recruter = new
		MySQL.Async.execute("UPDATE `vgangs` SET `perms_recruter` = @new WHERE `gangname` = @gangname", {['@new'] = encodedNew, ['@gangname'] = gangname}, function() end)
	elseif type == "perms_promouvoir" then
		SaveData.gangs[gangname].perms_promouvoir = new
		MySQL.Async.execute("UPDATE `vgangs` SET `perms_promouvoir` = @new WHERE `gangname` = @gangname", {['@new'] = encodedNew, ['@gangname'] = gangname}, function() end)
	elseif type == "perms_gestionmembre" then
		SaveData.gangs[gangname].perms_gestionmembre = new
		MySQL.Async.execute("UPDATE `vgangs` SET `perms_gestionmembre` = @new WHERE `gangname` = @gangname", {['@new'] = encodedNew, ['@gangname'] = gangname}, function() end)
	elseif type == "perms_vente" then
		SaveData.gangs[gangname].perms_vente = new
		MySQL.Async.execute("UPDATE `vgangs` SET `perms_vente` = @new WHERE `gangname` = @gangname", {['@new'] = encodedNew, ['@gangname'] = gangname}, function() end)
	elseif type == "perms_fabrication" then
		SaveData.gangs[gangname].perms_fabrication = new
		MySQL.Async.execute("UPDATE `vgangs` SET `perms_fabrication` = @new WHERE `gangname` = @gangname", {['@new'] = encodedNew, ['@gangname'] = gangname}, function() end)
	end

	OthersLogsDetails("Logs Groupe Illégal","Le joueur "..xPlayer.getName().." ("..xPlayer.getIdunique()..") a modifier les permissions : "..type.." ("..gangname..")","gestion-illegal-group", {idunique = xPlayer.getIdunique(), name = xPlayer.getName()})
end)

RegisterNetEvent('null:initGangs', function()
    TriggerClientEvent('null:SendGangListToClient', source, SaveData.gangs)
end)


--[[
	["test"] = {
		name = "Sandy shore",
		ownerLabel = "Bloods", 
		ownerCount = 0,
		active = false,
		data = {
			["blood"] = {
				count = 0
			},
			["vagos"] = {
				count = 0
			},
		}
	}]]


RegisterNetEvent("null:changerank")
AddEventHandler("null:changerank", function(gangs,idunique, job, grade, bool)
    local _src = source
    local xPlayer = ESX.GetPlayerFromId(_src)
	local player = exports["null-core"]:getPlayerWithUniqueID(idunique) or {id = 0}
	if gangs.name ~= xPlayer.getJob2().name then return end
    xTarget = ESX.GetPlayerFromId(player.id)

    if xTarget ~= nil then
        xTarget.setJob2(job, grade)
		OthersLogsDetails("Logs Groupe Illégal","Le joueur "..xPlayer.getName().." ("..xPlayer.getIdunique()..") a modifier le grade de "..xTarget.getName().." ("..xTarget.getIdunique()..") en "..grade.." ("..job..")","gestion-illegal-group", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = xTarget.getIdunique(), name_cible = xTarget.getName()})
    else
		if bool then
			MySQL.Async.execute("UPDATE `users` SET `job2` = @job, `job2_grade` = @grade WHERE `idunique` = @idunique", {['@job'] = job, ['@grade'] = grade, ['@idunique'] = idunique}, function() end)
			OthersLogsDetails("Logs Groupe Illégal","Le joueur "..xPlayer.getName().." ("..xPlayer.getIdunique()..") a exclu "..idunique.." de sont groupe illégal ("..job..")","gestion-illegal-group", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = idunique})
		else
			MySQL.Async.execute("UPDATE `users` SET `job2_grade` = @grade WHERE `idunique` = @idunique", {['@grade'] = grade, ['@idunique'] = idunique}, function() end)
			OthersLogsDetails("Logs Groupe Illégal","Le joueur "..xPlayer.getName().." ("..xPlayer.getIdunique()..") a modifier le grade de "..idunique.." en "..grade.." ("..job..")","gestion-illegal-group", {idunique = xPlayer.getIdunique(), name = xPlayer.getName(), idunique_cible = idunique})
		end
	end
end)

ESX.RegisterServerCallback('GangsBuilder:getDirtyCash', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	TriggerEvent('esx_society:getSocietyMoney', 'society_' .. xPlayer.job2.name, function(dirtycash)
		cb(dirtycash)
	end)
end)


RegisterNetEvent('GangsBuilder:putInVehicle', function(target)
	local xPlayerTarget = ESX.GetPlayerFromId(target)

	if xPlayerTarget ~= nil then
		local cuffState = xPlayerTarget.get('cuffState')

		if cuffState.isCuffed then
			TriggerClientEvent('GangsBuilder:putInVehicle', target)
		end
	end
end)

RegisterNetEvent('GangsBuilder:OutVehicle', function(target)
	local xPlayerTarget = ESX.GetPlayerFromId(target)

	if xPlayerTarget ~= nil then
		local cuffState = xPlayerTarget.get('cuffState')

		if cuffState.isCuffed then
			TriggerClientEvent('GangsBuilder:OutVehicle', target)
		end
	end
end)

ESX.RegisterServerCallback('GangsBuilder:getOtherPlayerData', function(source, cb, target)
	local xPlayer = ESX.GetPlayerFromId(target)

	if xPlayer then
		cb({
			foundPlayer = true,
			inventory = xPlayer.inventory,
			weapons = xPlayer.loadout,
			accounts = xPlayer.accounts
		})
	else
		cb({foundPlayer = false})
	end
end)

ESX.RegisterServerCallback('null:GetPlayerData', function(source, cb, target)
    local xPlayer = ESX.GetPlayerFromId(target)
    if xPlayer then
        local data = {
            name = xPlayer.getName(),
            job = xPlayer.job.label,
            grade = xPlayer.job.grade_label,
            inventory = xPlayer.getInventory(),
            accounts = xPlayer.getAccounts(),
			weapons = xPlayer.getLoadout(),
            money = xPlayer.getAccount('cash').money,
            blackmoney = xPlayer.getAccount('dirtycash').money
        }
        cb(data)
    end
end)

local function HaveWeaponInLoadout(xPlayer, weapon)
    for i, v in pairs(xPlayer.loadout) do
        if (GetHashKey(v.name) == weapon) then
            return true;
        end
    end
    return false;
end

RegisterNetEvent('Gangsbuilder:BuyWeapon', function(weapon, label, quantity)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.IllegalGroups.Sell.Weapons[weapon] == nil then DropPlayer(source, 'euh t srx maik') return end

	if xPlayer.getAccount('dirtycash').money >= Config.IllegalGroups.Sell.Weapons[weapon].price*quantity then
        --if not (HaveWeaponInLoadout(xPlayer, Config.IllegalGroups.Sell.Weapons[weapon].hash)) then
			xPlayer.removeAccountMoney('dirtycash', Config.IllegalGroups.Sell.Weapons[weapon].price*quantity) 

			Wait(1000)
			for i = 1, quantity do
				TriggerClientEvent("inventory:sendMessage", xPlayer.source, "📦 (~y~+"..i.."~s~) Vous avez reçu une arme ("..label..")")
				AddWeaponToStorage(xPlayer.getJob2().name, weapon)
				Wait(2500)
			end

			--xPlayer.addWeapon(Config.IllegalGroups.Sell.Weapons[weapon].hash, 250)
			--xPlayer.showNotification(ESX.Config("serverColor")..''..ESX.Config("serverName")..'~s~ Vous avez acheter '..label)
		--else
		--	xPlayer.showNotification(ESX.Config("serverColor")..''..ESX.Config("serverName")..'~s~\nVous avez déjà cette arme sur vous !')
		--end
	else
		xPlayer.showNotification('❌ Vous n\'avez pas l\'argent nécéssaire.')
	end
end)

RegisterNetEvent('Gangsbuilder:FabWeapon', function(weapon, label)
	local xPlayer = ESX.GetPlayerFromId(source)
	if not Config.IllegalGroups or not Config.IllegalGroups.Craft or not Config.IllegalGroups.Craft.Weapons then 
		return 
	end
	if Config.IllegalGroups.Craft.Weapons[weapon] == nil then 
		DropPlayer(source, 'euh t srx maik') 
		return 
	end

	local craftData = Config.IllegalGroups.Craft.Weapons[weapon]
	local leveritem = xPlayer.getInventoryItem("levier")
	local plancheitem = xPlayer.getInventoryItem("planche")
	local acieritem = xPlayer.getInventoryItem("acierpur")

	local requiredLevier = craftData.fablevier or 0
	local requiredPlanche = craftData.fabplanche or 0
	local requiredAcier = craftData.fabacier or 0

	if leveritem.count >= requiredLevier and plancheitem.count >= requiredPlanche and acieritem.count >= requiredAcier then
        if not (HaveWeaponInLoadout(xPlayer, weapon)) then
        	if requiredLevier > 0 then
        		xPlayer.removeInventoryItem("levier", requiredLevier)
        	end
        	if requiredPlanche > 0 then
        		xPlayer.removeInventoryItem("planche", requiredPlanche)
        	end
        	if requiredAcier > 0 then
        		xPlayer.removeInventoryItem("acierpur", requiredAcier)
        	end
			
			xPlayer.addWeapon(weapon, 250)
			xPlayer.showNotification(ESX.Config("serverColor")..''..ESX.Config("serverName")..'~s~ Vous avez fabriqué '..label)
			TriggerClientEvent("inventory:sendMessage", xPlayer.source, "🔨 Vous avez fabriqué: "..label)
		else
			xPlayer.showNotification(ESX.Config("serverColor")..''..ESX.Config("serverName")..'~s~\nVous avez déjà cette arme sur vous !')
		end
	else
		xPlayer.showNotification(ESX.Config("serverColor")..''..ESX.Config("serverName")..'~s~\nVous n\'avez pas les matériaux nécessaires.')
	end
end)

RegisterNetEvent('Gangsbuilder:BuyItem', function(Item, label, quantity)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.IllegalGroups.Sell.Items[Item] == nil then DropPlayer(source, 'euh t srx maik') return end

	if xPlayer.getAccount('dirtycash').money >= Config.IllegalGroups.Sell.Items[Item].price*quantity then
		xPlayer.removeAccountMoney('dirtycash', Config.IllegalGroups.Sell.Items[Item].price*quantity) 

		Wait(1000)
		for i = 1, quantity do
			TriggerClientEvent("inventory:sendMessage", xPlayer.source, "📦 Vous avez reçu un objet ("..label..")")
			AddItemToStorage(xPlayer.getJob2().name, Item, 1)
			Wait(4000)
		end

		--xPlayer.addInventoryItem(Item, 1)
		--xPlayer.showNotification(ESX.Config("serverColor")..''..ESX.Config("serverName")..'~s~ Vous avez acheter '..label)
	else
		xPlayer.showNotification(ESX.Config("serverColor")..''..ESX.Config("serverName")..'~s~\nVous n\'avez pas l\'argent nécéssaire.')
	end
end)


RegisterCommand('gangs', function(source,args)
	local xPlayer = ESX.GetPlayerFromId(source)

	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		TriggerClientEvent('Open:GangMenuAdmin', source)
	end
end)

RegisterNetEvent('vFrame:setjob2')
AddEventHandler('vFrame:setjob2', function(job2, lastJob2)
	local xPlayer = ESX.GetPlayerFromId(source)
	if SaveData.gangs[lastJob2] ~= nil then
		SaveData.gangs[lastJob2].PlyList[xPlayer.getIdunique()] = nil
	end
	if SaveData.gangs[job2] == nil then 
		return
	end
	SaveData.gangs[job2].PlyList[xPlayer.getIdunique()] = {
		source=xPlayer.source,
		name=xPlayer.getName(),
		firstname=xPlayer.firstname,
		lastname=xPlayer.lastname,
		idunique=xPlayer.idunique,
		job2=xPlayer.getJob2().name,
		job=xPlayer.getJob().name,
		identifier=xPlayer.identifier
	}
end)

ESX.RegisterServerCallback("Null:GetMemberOfGangs", function(source, cb, type, gangname)
	local xPlayer = ESX.GetPlayerFromId(source)
	if type == "staff" then
		if Config.GroupeHighPerm[xPlayer.getGroup()] ~= true then cb({}) return end
		if SaveData.gangs[gangname] == nil then cb({}) return end
		cb(SaveData.gangs[gangname].PlyList)
	elseif type == "boss" then
		if xPlayer.getJob2().name ~= gangname then cb({}) return end
		if SaveData.gangs[gangname] == nil then cb({}) return end
		cb(SaveData.gangs[gangname].PlyList)
	end
end)

RegisterNetEvent('Null:wipeallGangMember', function(gangname)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= true then return end
	
	for k,v in pairs(SaveData.gangs[gangname].PlyList) do
		if SaveData.admin.Players[v.idunique] ~= nil then DropPlayer(SaveData.admin.Players[v.idunique].source, "Vous avez été wipe (Raison : Wipe de groupe)") end
		WipeTable(v.identifier)
	end
end)

RegisterNetEvent('null:UpdateGangs', function(value)
	local xPlayer = ESX.GetPlayerFromId(source)
	local NewCoffrePos = json.encode(value.CoffrePos)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		if SaveData.gangs[value.name] then
			SaveData.gangs[value.name].posCoffre = json.decode(NewCoffrePos)
			SaveData.gangs[value.name].KitArme = value.KitArme
			if value.FabArme then
				SaveData.gangs[value.name].FabArme = 1
			else
				SaveData.gangs[value.name].FabArme = 0
			end
			if value.KitArme then
				SaveData.gangs[value.name].KitArme = 1
			else
				SaveData.gangs[value.name].KitArme = 0
			end
			if value.FabPos then
				SaveData.gangs[value.name].posFabrication = value.FabPos
			end
			SaveData.gangs[value.name].nbrpoint = value.NBRPoint
			SaveData.gangs[value.name].Point = value.NBRPoint	
			syncGangCraftTables()
			TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
			local webhook = 'https://discord.com/api/webhooks/1187151378603315341/XQdWA3bu2JpnOp9LovrAGT6DHM6RRB21tBpoeE76BVCy13yYxCG5DuX1GOaJfCURcWsE'
			MySQL.Async.execute('UPDATE vgangs SET posCoffre = @posCoffre, point = @point, KitArme = @KitArme, FabArme = @FabArme, posFabrication = @posFabrication WHERE gangname = @gangname',{
				['@gangname'] = value.name,
				['@posCoffre'] = NewCoffrePos,
				['@point'] = value.NBRPoint,
				['@KitArme'] = SaveData.gangs[value.name].KitArme,
				['@FabArme'] = SaveData.gangs[value.name].FabArme,
				['@posFabrication'] = SaveData.gangs[value.name].posFabrication and json.encode(SaveData.gangs[value.name].posFabrication) or nil,
			})
		end
	end
end)

RegisterNetEvent('null:UpdateGangsPoint', function(value)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		if SaveData.gangs[value.name] then
			SaveData.gangs[value.name].nbrpoint = value.NBRPoint
		    SaveData.gangs[value.name].Point = value.NBRPoint	
			TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
			local webhook = 'https://discord.com/api/webhooks/1187151378603315341/XQdWA3bu2JpnOp9LovrAGT6DHM6RRB21tBpoeE76BVCy13yYxCG5DuX1GOaJfCURcWsE'
			MySQL.Async.execute('UPDATE vgangs SET point = @point WHERE gangname = @gangname',{
				['@gangname'] = value.name,
				['@point'] = value.NBRPoint,
			})

			TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)
		end
	end
end)

RegisterNetEvent('Null:GivePointGangs', function(Gang, PointNbr)
	local xPlayer = ESX.GetPlayerFromId(source)
	local job2 = xPlayer.getJob2().name
	if SaveData.gangs[Gang] then
		MySQL.Async.fetchAll('SELECT * FROM vgangs where gangname = @gangname', {
		    ['@gangname'] = Gang
		}, function(result)
		   	local newpoint = result[1].point + PointNbr
		    SaveData.gangs[Gang].nbrpoint = newpoint
		    SaveData.gangs[Gang].Point = newpoint

			MySQL.Async.execute('UPDATE vgangs SET point = @point WHERE gangname = @gangname',{
				['@gangname'] = Gang,
				['@point'] = newpoint,
			})
		end)
	end
end)


RegisterNetEvent('null:DeleteGangs', function(value)
	local xPlayer = ESX.GetPlayerFromId(source)
	if Config.GroupeHighPerm[xPlayer.getGroup()] ~= nil then
		if SaveData.gangs[value] then
			SaveData.gangs[value] = nil
			TriggerClientEvent('null:SendGangListToClient', -1, SaveData.gangs)

			MySQL.Async.fetchAll('SELECT coffre, name, id FROM vstorage WHERE name = @name', {
				['@name'] = value
			}, function (result)
				if result[1] then
					print("Suppression du coffre de gang : "..result[1].name.." ("..result[1].id..")")
					MySQL.Async.execute('DELETE FROM vstorage WHERE `id` = @id', {
						['@id'] = result[1].id
					})
				end
			end)
			MySQL.Async.execute('DELETE FROM vgangs WHERE `gangname` = @gangname', {
				['@gangname'] = value
			})
		end
	end
end)

local Nullopti = 0

AddEventHandler('playerDropped', function(reason)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer == nil then
        return
    end
	local gangname = xPlayer.getJob2().name

	if SaveData.gangs[gangname] ~= nil then
		SaveData.gangs[gangname].StatePly[source] = nil

		if #SaveData.gangs[gangname].StatePly == 0 then
			SaveData.gangs[gangname].State = false
		end

		Nullopti = Nullopti + 1
	end
end)

RegisterNetEvent('Null:GangInfoSetJob2')
AddEventHandler('Null:GangInfoSetJob2', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
	local gangname = xPlayer.getJob2().name
	if SaveData.gangs[gangname] ~= nil then
		SaveData.gangs[gangname].State = true
		SaveData.gangs[gangname].StatePly[xPlayer.source] = {name=xPlayer.getName(),id=xPlayer.source}
	end
	for k,v in pairs(SaveData.gangs) do
		if v.State then
			for i,p in pairs(StatePly) do
				if v.id == xPlayer.source then
					SaveData.gangs[v.name].StatePly[xPlayer.source] = nil
				end
			end
		end
	end
	Nullopti = Nullopti + 1
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
	local gangname = xPlayer.getJob2().name
	if SaveData.gangs[gangname] ~= nil then
		SaveData.gangs[gangname].State = true
		SaveData.gangs[gangname].StatePly[xPlayer.source] = {name=xPlayer.getName(),id=xPlayer.source}
	end

	Nullopti = Nullopti + 1
end)


Citizen.CreateThread(function()
    while true do 
        Wait(1000 * 60 * 5)

		if Nullopti >= Config.OptimisationSys then
			TriggerClientEvent("null:SendGangListToClient", -1, SaveData.gangs)

			Nullopti = 0
		end
    end
end)