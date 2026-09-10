null.fct.sql.CheckSocietyAndCreate = function(name, label)
	MySQL.Async.fetchAll('SELECT * FROM `society` WHERE `name` = @name', {
		['@name'] = name
	}, function(result)
		if result[1] == nil then 
			MySQL.Async.execute("INSERT INTO `society` (`name`, `label`) VALUES (@name, @label) ", {
				['@name'] = name,
				['@label'] = label
			})
            if SocietyCache then
                SocietyCache[name] = {}
                SocietyCache[name].name = name
                SocietyCache[name].data = {
                    ['weapons'] = {},
                    ['items'] = {},
                    ['accounts'] = {
                        cash = 0,
                        dirtycash = 0,
                    },
                }
            end
		end            
	end)
end

null.fct.sql.CheckItemAndCreate = function(name, label)
	MySQL.Async.fetchAll('SELECT * FROM `items` WHERE `name` = @name', {
		['@name'] = name,
	}, function(result)
		if result[1] == nil then 
			MySQL.Async.execute("INSERT INTO `items` (`name`, `label`, `weight`) VALUES (@name, @label, @weight) ", {
				['@name'] = name,
				['@label'] = label,
				['@weight'] = 1
			})
		end
	end)
end

null.fct.sql.CheckJobAndCreate = function(name, label)
	MySQL.Async.fetchAll('SELECT * FROM `jobs` WHERE `name` = @name', {
		['@name'] = name
	}, function(result)
		if result[1] == nil then 
			MySQL.Async.execute("INSERT INTO `jobs` (`name`, `label`, `whitelisted`) VALUES (@name, @label, @whitelisted) ", {
				['@name'] = name,
				['@label'] = label,
				['@whitelisted'] = 1
			})    
		end
	end)
end

null.fct.sql.CheckJobGradeAndCreate = function(name, label, rank, grade)
	MySQL.Async.fetchAll('SELECT * FROM `job_grades` WHERE `job_name` = @job_name AND `name` = @name', {
		['@job_name'] = name,
		['@name'] = rank
	}, function(result)
		if result[1] == nil then 
			MySQL.Async.execute("INSERT INTO `job_grades` (`job_name`, `grade`, `name`, `label`, `salary`, `skin_male`, `skin_female`) VALUES (@job_name, @grade, @name, @label, @salary, @skin_male, @skin_female)", {
				['@job_name'] = name,
				['@grade'] = grade,
				['@name'] = rank,
				['@label'] = label,
				['@salary'] = 0,
				['@skin_male'] = "{}",
				['@skin_female'] = "{}"
			})
		end
	end)
end