-- CORE --
local Group = setmetatable({}, Group)
Group.__index = Group
Group.__call = function() return "Group" end

function Group.New(Name, Inherits)
	local _Group = {
		Name = tostring(Name),
		Inherits = tostring(Inherits)
	}

	return setmetatable(_Group, Group)
end

function Group:canTarget(target)
	if (self.Name == Config.DefaultGroup) then
		return false
	else
		if (self.Name == target.Name) then
			return true
		elseif (self.Inherits == target.Name) then
			return true
		else
			return ESX.Groups[self.Inherits]:canTarget(target)
		end
	end
end

-- SCRIPT --

ESX.GroupeHavePermission = function(my, target)
	if (my.Name == Config.DefaultGroup) then
		return false
	else
		if (my.Name == target.Name) then
			return true
		elseif (my.Inherits == target.Name) then
			return true
		else
			return ESX.GroupeHavePermission(ESX.Groups[my.Inherits], target)
		end
	end
end

ESX.GroupeHaveStaffPerm = function(group, perm)
	perm = string.lower(perm)
	if Config.Admin.RolePermissions and Config.Admin.RolePermissions[group] then
		return Config.Admin.RolePermissions[group][perm] == true
	end

	local tempConfigPerm = {}
	for k,v in pairs(Config.Admin.PermissionsGrade) do tempConfigPerm[string.lower(k)] = v end

	if tempConfigPerm[perm] == nil then return false end
	if Config.GroupeGrade[group] == nil then return false end

	if Config.GroupeGrade[group].grade >= tempConfigPerm[perm] then
		return true
	else
		return false
	end
end

ESX.AddGroup = function(name, inherits)
	if (type(name) ~= 'string') then
		print("ES_ERROR: There seems to be an issue while creating a new group, please make sure that you entered a correct 'group' as 'string'")
	end

	if (type(inherits) ~= 'string') then
		print("ES_ERROR: There seems to be an issue while creating a new group, please make sure that you entered a correct 'inherit' as 'string'")
	end

	ExecuteCommand('add_principal group.'..name..' group.'..inherits)
	ExecuteCommand("add_ace group."..name.." VolShield.bypass allow")
	
	for k,v in pairs(Config.AceToVerif) do
		ExecuteCommand("remove_ace group."..name.." "..k.." allow")
		local hasAuth = ESX.GroupeHaveStaffPerm(name, k)
		if hasAuth then
			ExecuteCommand("add_ace group."..name.." "..k.." allow")
		end
	end

	ESX.Groups[name] = Group.New(name, inherits)
end

ESX.GroupCanTarget = function(targetGroup1, targetGroup2, cb)
	if ESX.Groups[targetGroup1] and ESX.Groups[targetGroup2] then
		if cb then
			cb(ESX.Groups[targetGroup1]:canTarget(ESX.Groups[targetGroup2]))
		else
			return ESX.Groups[targetGroup1]:canTarget(ESX.Groups[targetGroup2])
		end
	else
		if cb then
			cb(false)
		else
			return false
		end
	end
end

--[[ Default groups
ESX.AddGroup(Config.DefaultGroup, '')
ESX.AddGroup('helper', Config.DefaultGroup)
ESX.AddGroup('mod', 'helper')
ESX.AddGroup('admin', 'mod')
ESX.AddGroup('superadmin', 'admin')
ESX.AddGroup('assistantillegal', 'superadmin')
ESX.AddGroup('assistantlegal', 'superadmin')
ESX.AddGroup('assistantstaff', 'superadmin')
ESX.AddGroup('gerantillegal', 'superadmin')
ESX.AddGroup('gerantlegal', 'superadmin')
ESX.AddGroup('gerantstaff', 'superadmin')
ESX.AddGroup('responsable', 'superadmin')
ESX.AddGroup('fondateur', 'superadmin')]]

for k,v in ipairs(Config.Groupes) do
	ESX.AddGroup(v.name, v.before)
end
