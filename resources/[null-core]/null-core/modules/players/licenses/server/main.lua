function AddLicense(target, type, cb)
	local xPlayer = ESX.GetPlayerFromId(target)
	MySQL.Async.execute('INSERT INTO user_licenses (type, owner) VALUES (@type, @owner)', {
		['@type'] = type,
		['@owner'] = xPlayer.identifier
	}, function(rowsChanged)

		GetLicenses(target, function(result)
			TriggerClientEvent("Null:licenses:recevie", target, result)
		end)

		if cb then
			cb()
		end
	end)
end

function RemoveLicense(target, type, cb)
	local xPlayer = ESX.GetPlayerFromId(target)
	MySQL.Async.execute('DELETE FROM user_licenses WHERE type = @type AND owner = @owner', {
		['@type'] = type,
		['@owner'] = xPlayer.identifier
	}, function(rowsChanged)
		if cb then
			cb()
		end
	end)
end

function CheckItemIsLicense(name)
	for k,v in pairs(Config.Licenses.Listes) do 
		if k == name then 
			return true 
		end
	end
	return false
end

function GetLicenses(target, cb)
	local xPlayer = ESX.GetPlayerFromId(target)
	if (xPlayer) then
		MySQL.Async.fetchAll('SELECT * FROM user_licenses WHERE owner = @owner', {
			['@owner'] = xPlayer.identifier
		}, function(result)
			local licenses = {}
			for k,v in pairs(result) do
				licenses[v.type] = true
			end
			cb(licenses)
		end)
	end
end

exports("GetLicenses", GetLicenses)

function CheckLicense(target, type, cb)
	local xPlayer = ESX.GetPlayerFromId(target)
	MySQL.Async.fetchAll('SELECT COUNT(*) as count FROM user_licenses WHERE type = @type AND owner = @owner', {
		['@type'] = type,
		['@owner'] = xPlayer.identifier
	}, function(result)
		if tonumber(result[1].count) > 0 then
			cb(true)
		else
			cb(false)
		end
	end)
end

local lastAskLicense = Config.Licenses.Listes
for k,v in pairs(lastAskLicense) do 
	lastAskLicense[k] = {}
end

RegisterNetEvent("null:buy:newlicense", function(type)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	local hasIdentityItem = xPlayer.getInventoryItem(type)
	if hasIdentityItem and hasIdentityItem.count >= 1 then
		return xPlayer.showNotification("Vous avez déjà cette license sur vous.")
	end
	if lastAskLicense[type][xPlayer.idunique] ~= nil and (os.time() - lastAskLicense[type][xPlayer.idunique] < (60*60)) then
		return xPlayer.showNotification("⏱ Vous devez attendre "..((60*60) - (os.time() - lastAskLicense[type][xPlayer.idunique])/60).." Minute(s).")
	end
	lastAskLicense[type][xPlayer.idunique] = os.time()
	if type == "identity_card" then
		xPlayer.addInventoryItem(type, 1, {
			creation = os.time(),
			firstname = xPlayer.firstname,
			lastname = xPlayer.lastname,
			birthday = xPlayer.dateofbirth,
			sex = xPlayer.sex == "0" and "Mâle" or "Femelle", 
		})
	elseif type == "drive" then
		GetLicenses(xPlayer.source, function(licenses)
			xPlayer.addInventoryItem(type, 1, {
				creation = os.time(),
				firstname = xPlayer.firstname,
				lastname = xPlayer.lastname,
				birthday = xPlayer.dateofbirth,
				sex = xPlayer.sex == "0" and "Mâle" or "Femelle", 
				licenses = licenses or {}, 
			})
		end)
	elseif type == "weapon" then
		GetLicenses(xPlayer.source, function(licenses)
			xPlayer.addInventoryItem(type, 1, {
				creation = os.time(),
				firstname = xPlayer.firstname,
				lastname = xPlayer.lastname,
				birthday = xPlayer.dateofbirth,
				sex = xPlayer.sex == "0" and "Mâle" or "Femelle", 
				licenses = licenses or {}, 
			})
		end)
	else
		xPlayer.addInventoryItem(type, 1, {
			creation = os.time(),
			firstname = xPlayer.firstname,
			lastname = xPlayer.lastname,
			birthday = xPlayer.dateofbirth,
			sex = xPlayer.sex == "0" and "Mâle" or "Femelle", 
		})
	end
end)

RegisterNetEvent("Null:licenses:open", function(licenseType, targetId, metadata)
	local src = source
	local xPlayer = ESX.GetPlayerFromId(src)
	if not xPlayer then return end
	if not metadata or not metadata.firstname then return end

	local cardData = {
		type = licenseType,
		firstname = metadata.firstname or "",
		lastname = metadata.lastname or "",
		birthday = metadata.birthday or "",
		sex = metadata.sex or "",
		creation = metadata.creation or 0,
		licenses = metadata.licenses or {},
		nationality = "San Andreas",
	}

	TriggerClientEvent("null:idcard:show", targetId, cardData)
end)

RegisterNetEvent("Null:licenses:askmylicenses", function()
	local src = source
	GetLicenses(src, function(result)
		TriggerClientEvent("Null:licenses:recevie", src, result)
	end)
end)

AddEventHandler('Null:esx_license:getLicenses', function(target, cb)
	GetLicenses(target, cb)
end)

AddEventHandler('Null:esx_license:checkLicense', function(target, type, cb)
	CheckLicense(target, type, cb)
end)

ESX.RegisterServerCallback('Null:esx_license:getLicenses', function(source, cb, target)
	GetLicenses(target, cb)
end)

ESX.RegisterServerCallback('Null:esx_license:checkLicense', function(source, cb, target, type)
	CheckLicense(target, type, cb)
end)