-- Debounce system pour les events admin refresh
ESX.PendingAdminRefresh = {}
function ESX.ScheduleAdminRefresh(source)
    if ESX.PendingAdminRefresh[source] then return end
    ESX.PendingAdminRefresh[source] = true
    SetTimeout(1000, function()
        ESX.PendingAdminRefresh[source] = nil
        TriggerEvent("null:admin:refresh:server", source, "forAllStaff")
    end)
end

SetMapName('Los Santos')
SetGameType('GTA RP')

AddEventHandler('esx:getSharedObject', function(cb)
	cb(ESX)
end)

function getSharedObject()
	return ESX
end

exports("getSharedObject", function()
    return ESX
end)

MySQL.ready(function()
	MySQL.Async.execute('DELETE FROM addon_account_data WHERE `money` = 0', {})
	MySQL.Async.execute('DELETE FROM addon_inventory_items WHERE `count` = 0', {})
	MySQL.Async.execute('DELETE FROM datastore_data WHERE `data` = \'{}\'', {})

	MySQL.Async.fetchAll('SELECT * FROM items', {}, function(result)
		for i = 1, #result, 1 do
			ESX.Items[result[i].name] = {
				name = result[i].name,
				label = result[i].label,
				weight = result[i].weight,
				canRemove = toboolean(result[i].can_remove),
				unique = toboolean(result[i].unique)
			}
		end
	end)

	MySQL.Async.fetchAll('SELECT * FROM jobs', {}, function(result)
		for i = 1, #result do
			ESX.Jobs[result[i].name] = result[i]
			ESX.Jobs[result[i].name].grades = {}
			TriggerEvent('Null:esx_phone:registerNumber', result[i].name, result[i].label, true, true)
			TriggerEvent('Null:esx_society:registerSociety', result[i].name, result[i].label, 'society_'..result[i].name, 'society_'..result[i].name, 'society_'..result[i].name, {type = 'private'})
		end
	
		MySQL.Async.fetchAll('SELECT * FROM job_grades', {}, function(result2)
			for i = 1, #result2 do
				if result2[i].mensuelpay == nil then
					result2[i].mensuelpay = 0
				end
				-- Pré-décoder skin_male/skin_female une seule fois au boot
				if result2[i].skin_male and type(result2[i].skin_male) == 'string' then
					result2[i].skin_male = json.decode(result2[i].skin_male) or {}
				end
				if result2[i].skin_female and type(result2[i].skin_female) == 'string' then
					result2[i].skin_female = json.decode(result2[i].skin_female) or {}
				end
				if ESX.Jobs[result2[i].job_name] then
					ESX.Jobs[result2[i].job_name].grades[tostring(result2[i].grade)] = result2[i]
				else
					print(('[^1Null^7] Le job : "%s", inscrit dans : job_grades, n\'est pas inscrit dans : job.'):format(result2[i].job_name))
					MySQL.Async.execute('DELETE FROM job_grades WHERE `job_name` = "'..result2[i].job_name..'"', {})
				end
			end
		
			for k, v in pairs(ESX.Jobs) do
				if ESX.Table.SizeOf(v.grades) == 0 then
					ESX.Jobs[v.name] = nil
					print(('[^1Null^7] Le job : "%s", inscrit dans : job, n\'est pas inscrit dans : job_grades.'):format(v.name))
					MySQL.Async.execute('DELETE FROM job_grades WHERE `job_name` = "'..v.name..'"', {})
				end
			end
			TriggerEvent("Core:InitAllJob", ESX.Jobs)
		end)
	end)
end)

RegisterServerEvent('esx:triggerServerCallback')
AddEventHandler('esx:triggerServerCallback', function(name, requestId, ...)
	local _source = source
	ESX.TriggerServerCallback(name, requestId, _source, function(...)
		TriggerClientEvent('esx:serverCallback', _source, requestId, ...)
	end, ...)
end)

RegisterCommand('refreshGlobalsInformations', function(source,args)
	if source == 0 then 
		ESX.Items = {}
		ESX.Jobs = {}
		MySQL.Async.fetchAll('SELECT * FROM items', {}, function(result)
			for i = 1, #result, 1 do
				ESX.Items[result[i].name] = {
					name = result[i].name,
					label = result[i].label,
					weight = result[i].weight,
					canRemove = toboolean(result[i].can_remove),
					unique = toboolean(result[i].unique)
				}
			end
		end)
	
		MySQL.Async.fetchAll('SELECT * FROM jobs', {}, function(result)
			for i = 1, #result do
				ESX.Jobs[result[i].name] = result[i]
				ESX.Jobs[result[i].name].grades = {}
			end
		
			MySQL.Async.fetchAll('SELECT * FROM job_grades', {}, function(result2)
				for i = 1, #result2 do
					-- Pré-décoder skin_male/skin_female
					if result2[i].skin_male and type(result2[i].skin_male) == 'string' then
						result2[i].skin_male = json.decode(result2[i].skin_male) or {}
					end
					if result2[i].skin_female and type(result2[i].skin_female) == 'string' then
						result2[i].skin_female = json.decode(result2[i].skin_female) or {}
					end
					if ESX.Jobs[result2[i].job_name] then
						ESX.Jobs[result2[i].job_name].grades[tostring(result2[i].grade)] = result2[i]
					else
						print(('[^1Null^7] Le job : "%s", inscrit dans : job_grades, n\'est pas inscrit dans : job.'):format(result2[i].job_name))
						MySQL.Async.execute('DELETE FROM job_grades WHERE `job_name` = "'..result2[i].job_name..'"', {})
					end
				end
			
				for k, v in pairs(ESX.Jobs) do
					if ESX.Table.SizeOf(v.grades) == 0 then
						ESX.Jobs[v.name] = nil
						print(('[^1Null^7] Le job : "%s", inscrit dans : job, n\'est pas inscrit dans : job_grades.'):format(v.name))
						MySQL.Async.execute('DELETE FROM job_grades WHERE `job_name` = "'..v.name..'"', {})
					end
				end
				TriggerEvent("Core:InitAllJob", ESX.Jobs)
			end)
		end)
	end
end)

RegisterNetEvent('Null:CreateNewItem')
AddEventHandler('Null:CreateNewItem', function(value)
	local xPlayer = ESX.GetPlayerFromId(value.src)
	if xPlayer.getGroup() ~= "user" then
		if ESX.Items[value.name] then
			xPlayer.showNotification('L\'item existe déjà')
		else
			MySQL.Async.execute("INSERT INTO `items` (`name`, `label`, `weight`) VALUES (@name, @label, @weight) ", {
				['@name'] = value.name,
				['@label'] = value.label,
				['@weight'] = 0.25,
			})
		end
	end
end)

function ESX.DeletGrade(job, index) 
	if ESX.Jobs[job].grades[tostring(index)] then 
		ESX.Jobs[job].grades[tostring(index)] = nil
		MySQL.Async.execute('DELETE FROM job_grades WHERE job_name = @job_name and grade = @grade', {
			['@job_name'] = job,
			['@grade'] = tostring(index),
		})
		return ESX.Jobs[job].grades
	end
end

function ESX.AddGrade(job, gradeInfo) 
	if ESX.Jobs[job] then 
		local NumberGrade = "0"
		for i = 0, 7 do
			if not ESX.Jobs[job].grades[tostring(i)] then
				NumberGrade = tostring(i)
				break
			end
		end
		ESX.Jobs[job].grades[NumberGrade] = {}
		ESX.Jobs[job].grades[NumberGrade].job_name = gradeInfo.job_name
		ESX.Jobs[job].grades[NumberGrade].grade = NumberGrade
		ESX.Jobs[job].grades[NumberGrade].name = gradeInfo.name
		ESX.Jobs[job].grades[NumberGrade].label = gradeInfo.label
		ESX.Jobs[job].grades[NumberGrade].salary = gradeInfo.salary
		ESX.Jobs[job].grades[NumberGrade].mensuelpay = gradeInfo.mensuelpay or 0
		ESX.Jobs[job].grades[NumberGrade].skin_mal = gradeInfo.skin_mal
		ESX.Jobs[job].grades[NumberGrade].skin_female = gradeInfo.skin_female
		MySQL.Async.execute('INSERT INTO job_grades (job_name, grade, name, label, salary, mensuelpay, skin_male, skin_female) VALUES (@job_name, @grade, @name, @label, @salary, @mensuelpay, @skin_male, @skin_female)', {
			['@job_name'] = gradeInfo.job_name,
			['@grade'] = NumberGrade,
			['@name'] = gradeInfo.name,
			['@label'] = gradeInfo.label,
			['@salary'] = gradeInfo.salary,
			['@mensuelpay'] = gradeInfo.mensuelpay,
			['@skin_male'] = json.encode(gradeInfo.skin_mal),
			['@skin_female'] = json.encode(gradeInfo.skin_female)
		})
		return ESX.Jobs[job].grades
	end
end

function ESX.EditGrade(editType, job, args) 
	if ESX.Jobs[job] then 
		if editType == "salary" then 
			if ESX.Jobs[job].grades[tostring(args.grade)] then
				ESX.Jobs[job].grades[tostring(args.grade)].salary = args.amount
				MySQL.Async.execute("UPDATE job_grades SET salary=@salary WHERE name=@name and job_name=@job_name", {
					["@salary"] = args.amount,
					["@job_name"] = ESX.Jobs[job].name,
					["@name"] = ESX.Jobs[job].grades[tostring(args.grade)].name
				})
				TriggerEvent("Core:InitAllJob", ESX.Jobs)
				return ESX.Jobs[job].grades
			end
		elseif editType == "mensuelpay" then 
			if ESX.Jobs[job].grades[tostring(args.grade)] then
				ESX.Jobs[job].grades[tostring(args.grade)].mensuelpay = args.amount
				MySQL.Async.execute("UPDATE job_grades SET mensuelpay=@mensuelpay WHERE name=@name and job_name=@job_name", {
					["@mensuelpay"] = args.amount,
					["@job_name"] = ESX.Jobs[job].name,
					["@name"] = ESX.Jobs[job].grades[tostring(args.grade)].name
				})
				TriggerEvent("Core:InitAllJob", ESX.Jobs)
				return ESX.Jobs[job].grades
			end
		end
	end
end
ESX.AddJob = function(jobInfo)
	if not ESX.Jobs[jobInfo.name] then 
		ESX.Jobs[jobInfo.name] = {}
		ESX.Jobs[jobInfo.name].name = jobInfo.name
		ESX.Jobs[jobInfo.name].label = jobInfo.label 
		ESX.Jobs[jobInfo.name].grades = jobInfo.grades
		ESX.Jobs[jobInfo.name].whitelisted = jobInfo.whitelisted
		for k,v in pairs(jobInfo.grades) do
			MySQL.Async.execute('INSERT INTO job_grades (job_name, grade, name, label, salary, skin_male, skin_female) VALUES (@job_name, @grade, @name, @label, @salary, @skin_male, @skin_female)', {
				['@job_name'] = v.job_name,
				['@grade'] = tonumber(k),
				['@name'] = v.name,
				['@label'] = v.label,
				['@salary'] = v.salary,
				['@skin_male'] = v.skin_male,
				['@skin_female'] = v.skin_female
			})
		end
		MySQL.Async.execute('INSERT INTO jobs (name, label, whitelisted) VALUES (@name, @label, @whitelisted)', {
			['@name'] = jobInfo.name,
			['@label'] = jobInfo.label,
			['@whitelisted'] = jobInfo.whitelisted
		})
		print("Ajout d'un job dans ESX, nom : "..jobInfo.label)
	end
end