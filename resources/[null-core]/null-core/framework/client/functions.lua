ESX = {}
ESX.Items = {}
ESX.PlayerData = {}
ESX.PlayerLoaded = false
ESX.CurrentRequestId = 0
ESX.ServerCallbacks = {}
ESX.TimeoutCallbacks = {}

ESX.UI = {}
ESX.UI.HUD = {}
ESX.UI.HUD.RegisteredElements = {}
ESX.UI.Menu = {}
ESX.UI.Menu.RegisteredTypes = {}
ESX.UI.Menu.Opened = {}

ESX.Game = {}
ESX.Game.Utils = {}

ESX.Scaleform = {}
ESX.Scaleform.Utils = {}

ESX.Streaming = {}

ESX.PositionBeforeEnterCam = nil

--[[function ESX.SetTimeout(msec, cb)
	table.insert(ESX.TimeoutCallbacks, {
		time = GetGameTimer() + msec,
		cb = cb
	})

	return #ESX.TimeoutCallbacks
end]]

--[[function ESX.ClearTimeout(i)
	ESX.TimeoutCallbacks[i] = nil
end]]

function ESX.GetAmmoType(weaponName)
	for k,v in pairs(Config.Weapons) do
		if v.name == weaponName then
			return v.ammoType
		end
	end
	-- Weapon not found in config, use default ammo type if configured
	if Config.AmmoType and Config.AmmoType['default'] then
		return Config.AmmoType['default']
	end
	return "rifle"
end

function ESX.SetStaffMod(bool)
	ESX.PlayerData.staffmode = bool
end

function ESX.GetStaffMod()
	return ESX.PlayerData.staffmode
end

function ESX.IsPlayerLoaded()
	return ESX.PlayerLoaded
end

function ESX.GetPlayerData()
	return ESX.PlayerData
end

function ESX.SetPlayerData(key, val)
	ESX.PlayerData[key] = val
end

function ESX.GetTextInput (title)
	local input = lib.inputDialog(
		title,
		{
			{ type = "input", label = title }
		},
		{ allowCancel = true }
	)

	if input == nil or input[1] == nil or #input[1] == 0 or input[1] == "" then
		return nil
	end

	return input[1]
end

function ESX.GetTextareaInput (title)
	local input = lib.inputDialog(
		title,
		{
			{ type = "textarea", label = title, autosize = true }
		},
		{ allowCancel = true }
	)

	if input == nil or input[1] == nil or #input[1] == 0 or input[1] == "" then
		return nil
	end

	return input[1]
end

function ESX.GetNumberInput (title, min, max, default)
	min = min ~= nil and min or 0
	max = max ~= nil and max or 100000000000

	local input = lib.inputDialog(
        title,
        {
            { type = "number", label = title, min = min, max = max, default = default }
        },
        { allowCancel = true }
    )

	if input == nil then
		return nil
	end

	local value = tonumber(input[1])

	if (value == nil) or type(value) ~= "number" then
		return nil
	end

	if input == nil or input[1] == nil or input[1] == "" then
		return nil
	end

    return input[1]
end

function ESX.GetColorPickerInput (title, default)
	default = default ~= nil and default or "#eb4034"

	local input = lib.inputDialog(title, {
		{ type = 'color', label = title, format = "hex", default = '#eb4034' }
	})

	if input == nil or input[1] == nil or input[1] == "" then
		return { r = 0, g = 0, b = 0, a = 255 }
	end

	local value = input[1]

	if value == nil or type(value) ~= "string" then
		return { r = 0, g = 0, b = 0, a = 255 }
	end

	value = value:gsub("#", "")

    local r = tonumber(value:sub(1, 2), 16)
    local g = tonumber(value:sub(3, 4), 16)
    local b = tonumber(value:sub(5, 6), 16)

	return { r = r, g = g, b = b, a = 255 }
end

function ESX.ChatMessage(msg, author, color)
	TriggerEvent('chat:addMessage', {color = color or {255, 255, 255}, args = {author or 'SYSTEME', msg or ''}})
end

function ESX.GetDateInput (title)
	local input = lib.inputDialog(
		title,
		{
			{ type = "date", label = title, default = true, format = "DD/MM/YYYY" }
		},
        { allowCancel = true }
	)

	if input == nil or input[1] == nil or input[1] == "" then
		return nil
	end

	return input[1]
end

function ESX.ConfirmDialog (title, content)
	local input = lib.alertDialog({
		header = title,
		content = content,
		centered = true,
		cancel = true
	})

	if input == "confirm" then
		return true
	end

	return false
end

function ESX.HasPermissions(perm)
	if ESX.PlayerData.group == "user" then return false end
	if perm == nil then return false end
	perm = string.lower(perm)
	if Config.Admin.RolePermissions and Config.Admin.RolePermissions[ESX.PlayerData.group] then
		return Config.Admin.RolePermissions[ESX.PlayerData.group][perm] == true
	end

	local tempConfigPerm = {}
	for k,v in pairs(Config.Admin.PermissionsGrade) do tempConfigPerm[string.lower(k)] = v end

	if tempConfigPerm[perm] == nil then return false end
	if Config.GroupeGrade[ESX.PlayerData.group] == nil then return false end

	if Config.GroupeGrade[ESX.PlayerData.group].grade >= tempConfigPerm[perm] then
		return true
	else
		return false
	end
end

--function ESX.ShowNotification(msg, title, subtitle, color, icon, time)

function ESX.ShowNotification(msg, title, subtitle)
	-- local NullUIStart = false
	-- if GetResourceState("null-ui") == "started" then
	-- 	NullUIStart = true
	-- end
	-- if NullUIStart then
	-- 	local success, result, result2 = pcall(function()
	-- 		if NullInventory.isOpen then
	-- 			return true, false
	-- 		elseif exports["null-ui"]:isInInterface() ~= false then
	-- 			return false, true
	-- 		else
	-- 			return false, false
	-- 		end
	-- 	end)
	-- 	if success and result then
	-- 		TriggerEvent("inventory:sendMessage", msg, icon)
	-- 	elseif success and result2 then
	-- 		exports["null-ui"]:NotificationNUI(msg)
	-- 	else
	-- 		TriggerEvent("notifY:sendAdvanced", msg, title or "Annonce", subtitle or "Notification", color or nil, icon or nil, time or 8000, "bottomleft", true) 
	-- 	end
	-- else
	-- 	-- Use Local Notification Systeme
	-- 	ShowNotification(msg, "info", 8000)
	-- end

	local success, error = pcall(function()
		local NulluiStart = false
		if GetResourceState("null-ui") == "started" then
			NulluiStart = true
		end
		if NullInventory.isOpen then
			TriggerEvent("inventory:sendMessage", msg, icon)
		elseif NulluiStart and exports["null-ui"]:isInInterface() ~= false then
			exports["null-ui"]:NotificationNUI(msg)
		elseif null.modules.notifications.initialized then
			SendAdvancedNotification(msg, title or "Annonce", subtitle or nil, nil, nil, 8000, true, "default")
		else 
			ShowNotification(msg, "info", 8000)
		end
	end)
	if success then
		return
	end
	print(error)
	ShowNotification(msg, "info", 8000)
end

function ESX.ShowMessage(msg)
	if null.modules.notifications.initialized then
		SendNotification(msg, nil, 8000, true, "default")
	else
		ShowNotification(msg, "info", 8000)
	end
end

function ESX.ShowAdvancedNotification(title, subtitle, msg, color, icon, time)
	-- local NullUIStart = false
	-- if GetResourceState("null-ui") == "started" then
	-- 	NullUIStart = true
	-- end
	-- if NullUIStart then
	-- 	local success, result, result2 = pcall(function()
	-- 		if NullInventory.isOpen then
	-- 			return true, false
	-- 		elseif exports["null-ui"]:isInInterface() ~= false then
	-- 			return false, true
	-- 		else
	-- 			return false, false
	-- 		end
	-- 	end)

	-- 	if success and result then
	-- 		TriggerEvent("inventory:sendMessage", msg)
	-- 	elseif success and result2 then
	-- 		exports["null-ui"]:NotificationNUI(msg)
	-- 	else
	-- 		TriggerEvent("notifY:sendAdvanced", msg, title or "Annonce", subtitle or "Notification", color or nil, icon or nil, time or 8000, "bottomleft", true) 
	-- 	end
	-- else
	-- 	-- Use Local Notification Systeme
	-- 	ShowNotification(msg, "info", 8000)
	-- end

	local success, error = pcall(function()
		local NulluiStart = false
		if GetResourceState("null-ui") == "started" then
			NulluiStart = true
		end
		if NullInventory.isOpen then
			TriggerEvent("inventory:sendMessage", msg, icon)
		elseif NulluiStart and exports["null-ui"]:isInInterface() ~= false then
			exports["null-ui"]:NotificationNUI(msg)
		elseif null.modules.notifications.initialized then
			SendAdvancedNotification(msg, title or "Annonce", subtitle or nil, color or nil, icon or nil, time or 8000, true, "default") 
		else 
			ShowNotification(msg, "info", 8000)
		end
	end)
	if success then
		return
	end 
	print(error)
	ShowNotification(msg, "info", 8000)
end
	
function ESX.ShowAccept(msg, result)
	-- TriggerEvent("notifY:sendAccept", msg, title or "Annonce", subtitle or "Notification", color or nil, icon or nil, time or 8000, "bottomleft", true) 

	--print("null.modules.notifications.initialized: " .. tostring(null.modules.notifications.initialized))
	--print("ESX.ShowAccept(" .. msg .. ", result)")

	if null.modules.notifications.initialized then
		SendAcceptNotification(msg, nil, "Demande en attente", nil, nil, 10000, false, "info")
	else 
		ShowNotification(msg.."\n[~g~Y~s~] Accepter [~r~N~s~] Refuser", "info", 8000)
	end 

	if result then
		Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
            local time = 0
			local accept = false
            while true do
                time = time + 1
                if IsControlJustPressed(0, 38) then -- Accept
					accept = true
                    break
                end
                if IsControlJustPressed(0, 246) then -- Decline
					accept = false
                    break
                end
                if time > 15000 then
                    break
                end
                Wait(1)
            end
            if result then
				result(accept)
			end
        end))
	end


	--TriggerEvent('SHOW_NOTIF', msg, "rgba("..ESX.Config("r")..","..ESX.Config("g")..","..ESX.Config("b")..",1)", ESX.Config("serverCHAR"), "Informations", "Informations", true, announcement)
end


function ESX.ShowHelpNotification(msg)
	AddTextEntry('esxHelpNotification', msg)
	BeginTextCommandDisplayHelp('esxHelpNotification')
	EndTextCommandDisplayHelp(0, false, true, -1)
end


--[[function ESX.ShowNotification(msg, couleurProgress)
    exports.bulletin:Send(msg, couleurProgress)
end


function ESX.ShowAdvancedNotification(title, subject, msg, couleurProgress, banner, timeout, icon)
    exports.bulletin:SendAdvanced(msg, subject, title, couleurProgress, banner, nil, nil, true, nil, icon)
end

function ESX.ShowHelpNotification(msg)
	AddTextEntry('esxHelpNotification', msg)
	BeginTextCommandDisplayHelp('esxHelpNotification')
	EndTextCommandDisplayHelp(0, false, true, -1)
end]]

ESX.ShowDrawNotification = function(msg, time)
	ClearPrints()
	BeginTextCommandPrint("STRING")
	AddTextComponentSubstringPlayerName(msg)
	EndTextCommandPrint(time and math.ceil(time) or 0, true)
end

function ESX.TriggerServerCallback(name, cb, ...)
	ESX.ServerCallbacks[ESX.CurrentRequestId] = cb
	TriggerServerEvent('esx:triggerServerCallback', name, ESX.CurrentRequestId, ...)

	if ESX.CurrentRequestId < 65535 then
		ESX.CurrentRequestId = ESX.CurrentRequestId + 1
	else
		ESX.CurrentRequestId = 0
	end
end

function ESX.UI.HUD.SetDisplay(opacity)
	SendNUIMessage({
		action = 'setHUDDisplay',
		opacity = opacity
	})
end

function ESX.UI.HUD.RegisterElement(name, index, priority, html, data)
	local found = false

	for i = 1, #ESX.UI.HUD.RegisteredElements, 1 do
		if ESX.UI.HUD.RegisteredElements[i] == name then
			found = true
			break
		end
	end

	if found then
		return
	end

	table.insert(ESX.UI.HUD.RegisteredElements, name)

	SendNUIMessage({
		action = 'insertHUDElement',
		name = name,
		index = index,
		priority = priority,
		html = html,
		data = data
	})

	ESX.UI.HUD.UpdateElement(name, data)
end

function ESX.UI.HUD.RemoveElement(name)
	for i = 1, #ESX.UI.HUD.RegisteredElements, 1 do
		if ESX.UI.HUD.RegisteredElements[i] == name then
			table.remove(ESX.UI.HUD.RegisteredElements, i)
			break
		end
	end

	SendNUIMessage({
		action = 'deleteHUDElement',
		name = name
	})
end

function ESX.UI.HUD.UpdateElement(name, data)
	SendNUIMessage({
		action = 'updateHUDElement',
		name = name,
		data = data
	})
end

function ESX.UI.Menu.RegisterType(type, open, close, closeall, update)
	ESX.UI.Menu.RegisteredTypes[type] = {
		open = open,
		close = close,
		closeall = closeall,
		update = update
	}
end

function ESX.UI.Menu.Open(type, namespace, name, data, submit, cancel, change, close)
	local menu = {}

	data.align = nil
	data.css = 'california'

	menu.type = type
	menu.namespace = namespace
	menu.name = name
	menu.data = data
	menu.submit = submit
	menu.cancel = cancel
	menu.change = change

	function menu.close()
		if menu.type == 'default' then
			ESX.UI.Menu.RegisteredTypes[menu.type].close(menu.namespace, menu.name)
		else
			ESX.UI.Menu.RegisteredTypes[menu.type].close(menu.namespace, menu.name)

			for i = 1, #ESX.UI.Menu.Opened, 1 do
				if ESX.UI.Menu.Opened[i] then
					if ESX.UI.Menu.Opened[i].type == menu.type and ESX.UI.Menu.Opened[i].namespace == menu.namespace and ESX.UI.Menu.Opened[i].name == menu.name then
						ESX.UI.Menu.Opened[i] = nil
					end
				end
			end

			if close then
				close()
			end
		end
	end

	function menu.destruct()
		for i = 1, #ESX.UI.Menu.Opened, 1 do
			if ESX.UI.Menu.Opened[i] then
				if ESX.UI.Menu.Opened[i].type == menu.type and ESX.UI.Menu.Opened[i].namespace == menu.namespace and ESX.UI.Menu.Opened[i].name == menu.name then
					ESX.UI.Menu.Opened[i] = nil
				end
			end
		end
	end

	function menu.update(query, newData)
		if menu.type == 'default' then
			ESX.UI.Menu.RegisteredTypes[menu.type].update(menu.namespace, menu.name, query, newData)
		else
			for i = 1, #menu.data.elements, 1 do
				local match = true

				for k, v in pairs(query) do
					if menu.data.elements[i][k] ~= v then
						match = false
					end
				end

				if match then
					for k, v in pairs(newData) do
						menu.data.elements[i][k] = v
					end
				end
			end
		end
	end

	function menu.refresh()
		ESX.UI.Menu.RegisteredTypes[menu.type].open(menu.namespace, menu.name, menu.data, menu.submit, menu.cancel, menu.change)
	end

	function menu.setElement(i, key, val)
		menu.data.elements[i][key] = val
	end

	function menu.setTitle(val)
		menu.data.title = val
	end

	function menu.removeElement(query)
		for i = 1, #menu.data.elements, 1 do
			for k, v in pairs(query) do
				if menu.data.elements[i] then
					if menu.data.elements[i][k] == v then
						table.remove(menu.data.elements, i)
						break
					end
				end
			end
		end
	end

	table.insert(ESX.UI.Menu.Opened, menu)
	ESX.UI.Menu.RegisteredTypes[menu.type].open(menu.namespace, menu.name, menu.data, menu.submit, menu.cancel, menu.change)
	return menu
end

function ESX.UI.Menu.Close(type, namespace, name)
	for i = 1, #ESX.UI.Menu.Opened, 1 do
		if ESX.UI.Menu.Opened[i] then
			if ESX.UI.Menu.Opened[i].type == type and ESX.UI.Menu.Opened[i].namespace == namespace and ESX.UI.Menu.Opened[i].name == name then
				ESX.UI.Menu.Opened[i].close()
				ESX.UI.Menu.Opened[i] = nil
			end
		end
	end
end

function ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.RegisteredTypes['default'].closeall()

	for i = 1, #ESX.UI.Menu.Opened, 1 do
		if ESX.UI.Menu.Opened[i] then
			if ESX.UI.Menu.Opened[i].type ~= 'default' then
				ESX.UI.Menu.Opened[i].close()
				ESX.UI.Menu.Opened[i] = nil
			end
		end
	end
end

function ESX.UI.Menu.GetOpened(type, namespace, name)
	for i = 1, #ESX.UI.Menu.Opened, 1 do
		if ESX.UI.Menu.Opened[i] then
			if ESX.UI.Menu.Opened[i].type == type and ESX.UI.Menu.Opened[i].namespace == namespace and ESX.UI.Menu.Opened[i].name == name then
				return ESX.UI.Menu.Opened[i]
			end
		end
	end
end

function ESX.UI.Menu.GetOpenedMenus()
	return ESX.UI.Menu.Opened
end

function ESX.UI.Menu.IsOpen(type, namespace, name)
	return ESX.UI.Menu.GetOpened(type, namespace, name) ~= nil
end

function ESX.UI.ShowInventoryItemNotification(add, label, count, name)
	if type(count) == "boolean" then
		count = 1
	elseif type(count) ~= "number" then
		local success = pcall(function()
			count = tonumber(count)
		end)
		if not success then
			count = 1
		end
	end
	SendNUIMessage({
		action = 'inventoryNotification',
		add = add,
		label = label,
		name = name,
		count = count
	})
end

function ESX.Game.GetPedMugshot(ped)
	if DoesEntityExist(ped) then
		local mugshot = RegisterPedheadshot(ped)

		while not IsPedheadshotReady(mugshot) do
			Citizen.Wait(100)
		end

		return mugshot, GetPedheadshotTxdString(mugshot)
	end
end

function ESX.Game.Teleport(entity, coords, cb)
	if entity ~= nil and entity == 'source' then
		RequestCollisionAtCoord(coords)

		while not HasCollisionLoadedAroundEntity(PlayerPedId()) do
			RequestCollisionAtCoord(coords)
			Citizen.Wait(100)
		end

		SetEntityCoords(PlayerPedId(), coords)
	else
		if DoesEntityExist(entity) then
			RequestCollisionAtCoord(coords)

			while not HasCollisionLoadedAroundEntity(entity) do
				RequestCollisionAtCoord(coords)
				Citizen.Wait(100)
			end

			SetEntityCoords(entity, coords)
		end
	end

	if cb then
		cb()
	end
end

function ESX.Game.DeleteVehicle(vehicle)
	SetEntityAsMissionEntity(vehicle, false, false)
	DeleteVehicle(vehicle)
end

function ESX.Game.DeleteObject(object)
	SetEntityAsMissionEntity(object, false, false)
	DeleteObject(object)
end


function ESX.Game.GetObjects()
	local objects = {}

	for object in EnumerateObjects() do
		table.insert(objects, object)
	end

	return objects
end

function ESX.Game.GetClosestObject(filter, coords)
	local objects = ESX.Game.GetObjects()
	local closestDistance, closestObject = -1, -1

	if type(filter) == 'string' then
		if filter ~= '' then
			filter = {filter}
		end
	end

	if coords == nil then
		coords = GetEntityCoords(PlayerPedId(), false)
	end

	for i = 1, #objects, 1 do
		local foundObject = false

		if filter == nil or (type(filter) == 'table' and #filter == 0) then
			foundObject = true
		else
			local objectModel = GetEntityModel(objects[i])

			for j = 1, #filter, 1 do
				if objectModel == GetHashKey(filter[j]) then
					foundObject = true
					break
				end
			end
		end

		if foundObject then
			local objectCoords = GetEntityCoords(objects[i], false)
			local distance = #(objectCoords - coords)

			if closestDistance == -1 or closestDistance > distance then
				closestObject = objects[i]
				closestDistance = distance
			end
		end
	end

	return closestObject, closestDistance
end

function ESX.Game.GetClosestObjectHash(filter, coords)
	local objects = ESX.Game.GetObjects()
	local closestDistance, closestObject = -1, -1

	if type(filter) == 'string' then
		if filter ~= '' then
			filter = {filter}
		end
	end

	if coords == nil then
		coords = GetEntityCoords(PlayerPedId(), false)
	end

	for i = 1, #objects, 1 do
		local foundObject = false

		if filter == nil or (type(filter) == 'table' and #filter == 0) then
			foundObject = true
		else
			local objectModel = GetEntityModel(objects[i])

			for j = 1, #filter, 1 do
				if objectModel == filter[j] then
					foundObject = true
					break
				end
			end
		end

		if foundObject then
			local objectCoords = GetEntityCoords(objects[i], false)
			local distance = #(objectCoords - coords)

			if closestDistance == -1 or closestDistance > distance then
				closestObject = objects[i]
				closestDistance = distance
			end
		end
	end

	return closestObject, closestDistance
end

function ESX.Game.DeleteEntity(entity)
	SetEntityAsMissionEntity(entity, false, false)
	DeleteEntity(entity)
end

function ESX.Game.Utils.DrawText3D(coords, text, size, font)
	local camCoords = GetGameplayCamCoords()
	local distance = #(coords - camCoords)

	if not size then
		size = 1
	end

	if not font then
		font = 0
	end

	local scale = (size / distance) * 2
	local fov = (1 / GetGameplayCamFov()) * 100
	scale = scale * fov

	SetTextScale(0.0 * scale, 0.55 * scale)
	SetTextFont(font)
	SetTextColour(255, 255, 255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)

	SetDrawOrigin(coords, 0)
	BeginTextCommandDisplayText('STRING')
	AddTextComponentSubstringPlayerName(text)
	EndTextCommandDisplayText(0.0, 0.0)
	ClearDrawOrigin()
end


function ESX.Game.Utils.DrawText2D(message, vector2, scale, fontType, color, outline, dropShadow, align)
	if outline == nil then
		outline = true
	end

	if dropShadow == nil then
		dropShadow = true
	end

	if align == nil then
		align = false
	end

	BeginTextCommandDisplayText("STRING")
	AddTextComponentSubstringPlayerName(message)
	SetTextFont(fontType)
	SetTextScale(1, scale)
	SetTextWrap(0.0, 1.0)
	SetTextCentre(true)
	SetTextColour(color.r, color.g, color.b, color.a)
	SetTextJustification(align)

	if outline then
		SetTextOutline()
	end

	if dropShadow then
		SetTextDropShadow()
	end

	EndTextCommandDisplayText(vector2.x, vector2.y)
end

function ESX.Game.Utils.DrawText(text, size, font, pos)
	if not size then
		size = 1
	end

	if not font then
		font = 0
	end

	SetTextFont(font) -- Font for the text we are drawing
	SetTextScale(size,size)
	SetTextColour(255,255,255, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	SetTextCentre(true)
	SetTextEntry("STRING") -- Initiates a new string for our text
	AddTextComponentString(text) -- Sets the text
	DrawText(pos.x, pos.y) -- Draws the text (x, y on your screen)
end

function ESX.Game.SpawnObject(ObjectModel, coords, cb)
	local model = (type(ObjectModel) == 'number' and ObjectModel or GetHashKey(ObjectModel))

	Citizen.CreateThread(function()
		ESX.Streaming.RequestModel(model)
		local object = CreateObject(model, coords, false, false, true)

		SetEntityAsMissionEntity(object, false, false)
		SetModelAsNoLongerNeeded(model)

		RequestCollisionAtCoord(coords)

		while not HasCollisionLoadedAroundEntity(object) do
			Citizen.Wait(100)
		end

		if cb then
			cb(object)
		end
	end)
end

function ESX.Game.SpawnLocalObject(model, coords, cb)
	local model = (type(model) == 'number' and model or GetHashKey(model))

	Citizen.CreateThread(function()
		ESX.Streaming.RequestModel(model)
		local object = CreateObject(model, coords, false, false, true)

		SetEntityAsMissionEntity(object, false, false)
		SetModelAsNoLongerNeeded(model)

		RequestCollisionAtCoord(coords)

		while not HasCollisionLoadedAroundEntity(object) do
			Citizen.Wait(100)
		end

		if cb then
			cb(object)
		end
	end)
end

function ESX.Game.SpawnVehicle(modelName, coords, heading, cb)
	local model = (type(modelName) == 'number' and modelName or GetHashKey(modelName))
	coords = ESX.Vector(coords)

	Citizen.CreateThread(function()
		ESX.Streaming.RequestModel(model)
		local vehicle = CreateVehicle(model, coords, heading, true, false)
		
		local id = NetworkGetNetworkIdFromEntity(vehicle)

		SetNetworkIdCanMigrate(id, true)
		SetEntityAsMissionEntity(vehicle, true, true)
		SetModelAsNoLongerNeeded(model)

		SetVehicleHasBeenOwnedByPlayer(vehicle, true)
		SetVehicleOnGroundProperly(vehicle)
		SetVehicleNeedsToBeHotwired(vehicle, false)
		SetVehRadioStation(vehicle, 'OFF')
		DecorSetInt(vehicle, 'indicatorLights', 0)

		RequestCollisionAtCoord(coords)

		while not HasCollisionLoadedAroundEntity(vehicle) do
			Citizen.Wait(100)
		end

		if cb then
			cb(vehicle)
		end
	end)
end

function ESX.Game.SpawnLocalVehicle(modelName, coords, heading, cb)
	local model = (type(modelName) == 'number' and modelName or GetHashKey(modelName))
	coords = ESX.Vector(coords)

	Citizen.CreateThread(function()
		ESX.Streaming.RequestModel(model)
		local vehicle = CreateVehicle(model, coords, heading, false, false)

		SetEntityAsMissionEntity(vehicle, true, true)
		SetModelAsNoLongerNeeded(model)

		SetVehicleHasBeenOwnedByPlayer(vehicle, true)
		SetVehicleOnGroundProperly(vehicle)
		SetVehicleNeedsToBeHotwired(vehicle, false)
		SetVehRadioStation(vehicle, 'OFF')

		RequestCollisionAtCoord(coords)

		while not HasCollisionLoadedAroundEntity(vehicle) do
			Citizen.Wait(100)
		end

		if cb then
			cb(vehicle)
		end
	end)
end

function ESX.Game.IsVehicleEmpty(vehicle)
	local passengers = GetVehicleNumberOfPassengers(vehicle)
	local driverSeatFree = IsVehicleSeatFree(vehicle, -1)
	return passengers == 0 and driverSeatFree
end

function ESX.Game.GetAllPlayers()
	local clientPlayers = false

	ESX.TriggerServerCallback('esx:getActivePlayers', function(players)
		clientPlayers = players
	end)

	while not clientPlayers do
		Citizen.Wait(100)
	end

	return clientPlayers
end

function ESX.Game.GetPlayers()
	local activePlayers = GetActivePlayers()
	local players = {}

	for i = 1, #activePlayers, 1 do
		local ped = GetPlayerPed(activePlayers[i])

		if DoesEntityExist(ped) then
			table.insert(players, activePlayers[i])
		end
	end

	return players
end

function ESX.Game.GetClosestPlayer(coords)
	local players = ESX.Game.GetPlayers()
	local closestDistance, closestPlayer = -1, -1
	local usePlayerPed, playerId = false, 0

	if coords == nil then
		usePlayerPed = true
		playerId = PlayerId()
		coords = GetEntityCoords(PlayerPedId(), false)
	end

	for i = 1, #players, 1 do
		if not usePlayerPed or (usePlayerPed and players[i] ~= playerId) then
			local targetPed = GetPlayerPed(players[i])
			local targetCoords = GetEntityCoords(targetPed, false)
			local distance = #(targetCoords - coords)

			if closestDistance == -1 or closestDistance > distance then
				closestPlayer = players[i]
				closestDistance = distance
			end
		end
	end

	return closestPlayer, closestDistance
end

function ESX.Game.GetClosestPlayerInRadius(coords,radius)
	local players = ESX.Game.GetPlayers()
	local MyPlayersTable = {}

	if not (coords) then return end
	if not (radius) then return end

	for i =1, #players do 
		local targetPed = GetPlayerPed(players[i])
		local targetCoords = GetEntityCoords(targetPed, false)
		local distance = #(targetCoords - coords)

		if distance <= radius then 
			table.insert(MyPlayersTable, {id = GetPlayerServerId(players[i])})
		end
	end
	return MyPlayersTable
end

function ESX.Game.GetPlayersServerIdsInArea(coords, maxDistance, includePlayer)
	local players = {}
    for _, player in pairs(ESX.Game.GetPlayersInArea(coords, maxDistance, includePlayer)) do
        table.insert(players, GetPlayerServerId(player))
    end
    return players
end

function ESX.Game.GetPlayersInArea(coords, area)
	local players = ESX.Game.GetPlayers()
	local playersInArea = {}

	if coords == nil then
		coords = GetEntityCoords(PlayerPedId(), false)
	end

	for i = 1, #players, 1 do
		local target = GetPlayerPed(players[i])
		local targetCoords = GetEntityCoords(target, false)
		local distance = #(targetCoords - coords)

		if distance <= area then
			table.insert(playersInArea, players[i])
		end
	end

	return playersInArea
end

function ESX.Game.GetVehicles()
	local vehicles = {}

	for vehicle in EnumerateVehicles() do
		table.insert(vehicles, vehicle)
	end

	return vehicles
end


function ESX.GetWeaponHash(weaponName)
	weaponName = tonumber(weaponName)
	
	local weapons = ESX.GetWeaponList()
	
	for i = 1, #weapons, 1 do
		if weapons[i].hash == weaponName then
			return weapons[i], i
		end
	end
end

function ESX.GetWeaponByHashAntiCheat(weaponHash)
	weaponHash = tonumber(weaponHash)
	
	local weaponName = Config.WeaponsHash[weaponHash]

	if weaponName == nil then return end

	local weaponIndex, weaponData = ESX.GetWeapon(weaponName)

	return weaponData 
end

function ESX.GetWeaponWeight(weaponName)
	weaponName = string.upper(weaponName)
	local weapons = ESX.GetWeaponList()

	for i = 1, #weapons, 1 do
		if weapons[i].name == weaponName then
			return weapons[i].weight or Config.WeaponDefaultWeight
		end
	end

	return Config.WeaponDefaultWeight
end

function ESX.GetWeaponComponent(weaponName, weaponComponent)
	weaponName = string.upper(weaponName)
	weaponComponent = string.lower(weaponComponent)
	local weapons = ESX.GetWeaponList()

	for i = 1, #weapons, 1 do
		if weapons[i].name == weaponName then
			if weapons[i].components then 
				for j = 1, #weapons[i].components, 1 do
					if weapons[i].components[j].name == weaponComponent then
						return weapons[i].components[j]
					end
				end
			end
		end
	end
end

function ESX.HasComponentWithList(weaponName, weaponComponent, list)
	weaponName = string.upper(weaponName)
	weaponComponent = string.lower(weaponComponent)
	local weapons = ESX.GetWeaponList()

	for i = 1, #weapons, 1 do
		if weapons[i].name == weaponName then
			if weapons[i].components then 
				for j = 1, #weapons[i].components, 1 do
					if weapons[i].components[j].name == weaponComponent then
						return true
					end
				end
			end
		end
	end

	return false
end

function ESX.GetWeaponComponents(weaponName)
	weaponName = string.upper(weaponName)

	local weapons = ESX.GetWeaponList()

	for i = 1, #weapons, 1 do
		if weapons[i].name == weaponName then
			if weapons[i].components then 
				return weapons[i].components
			else
				return {}
			end
		end
	end
end

function ESX.Game.GetClosestVehicle(coords)
	local vehicles = ESX.Game.GetVehicles()
	local closestDistance, closestVehicle = -1, -1

	if coords == nil then
		coords = GetEntityCoords(PlayerPedId(), false)
	end

	for i = 1, #vehicles, 1 do
		local vehicleCoords = GetEntityCoords(vehicles[i], false)
		local distance = #(vehicleCoords - coords)

		if closestDistance == -1 or closestDistance > distance then
			closestVehicle, closestDistance = vehicles[i], distance
		end
	end

	return closestVehicle, closestDistance
end

function ESX.Game.GetVehiclesInArea(coords, area)
	local vehicles = ESX.Game.GetVehicles()
	local vehiclesInArea = {}

	if coords == nil then
		coords = GetEntityCoords(PlayerPedId(), false)
	end

	for i = 1, #vehicles, 1 do
		local vehicleCoords = GetEntityCoords(vehicles[i], false)
		local distance = #(vehicleCoords - coords)

		if distance <= area then
			table.insert(vehiclesInArea, vehicles[i])
		end
	end

	return vehiclesInArea
end

function ESX.Game.GetVehicleInDirection()
	local playerPed = PlayerPedId()
	local playerCoords = GetEntityCoords(playerPed, false)
	local inDirection = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
	local rayHandle = StartShapeTestRay(playerCoords, inDirection, 10, playerPed, 0)
	local numRayHandle, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)

	if hit == 1 and GetEntityType(entityHit) == 2 then
		return entityHit
	end

	return nil
end

function ESX.Game.IsSpawnPointClear(coords, radius)
	local vehicles = ESX.Game.GetVehiclesInArea(coords, radius)
	return #vehicles == 0
end

function ESX.Game.GetPeds(ignoreList)
	local ignoreList = ignoreList or {}
	local peds = {}

	for ped in EnumeratePeds() do
		local found = false

		for j = 1, #ignoreList, 1 do
			if ignoreList[j] == ped then
				found = true
			end
		end

		if not found then
			table.insert(peds, ped)
		end
	end

	return peds
end

function ESX.Game.GetClosestPed(coords, ignoreList)
	ignoreList = ignoreList or {}
	local peds = ESX.Game.GetPeds(ignoreList)
	local closestDistance, closestPed = -1, -1

	if coords == nil then
		coords = GetEntityCoords(PlayerPedId(), false)
	end

	for i = 1, #peds, 1 do
		local pedCoords = GetEntityCoords(peds[i], false)
		local distance = #(pedCoords - coords)

		if closestDistance == -1 or closestDistance > distance then
			closestPed = peds[i]
			closestDistance = distance
		end
	end

	return closestPed, closestDistance
end

function ESX.Game.GetPedsInArea(coords, area)
	local peds = ESX.Game.GetPeds()
	local pedsInArea = {}

	if coords == nil then
		coords = GetEntityCoords(PlayerPedId(), false)
	end

	for i = 1, #peds, 1 do
		local pedCoords = GetEntityCoords(peds[i], false)
		local distance = #(pedCoords - coords)

		if distance <= area then
			table.insert(pedsInArea, peds[i])
		end
	end

	return pedsInArea
end

function ESX.Game.SpawnPed(pedType, modelName, coords, heading, cb)
	local model = (type(modelName) == 'number' and modelName or GetHashKey(modelName))

	Citizen.CreateThread(function()
		ESX.Streaming.RequestModel(model)
		local ped = CreatePed(pedType, model, coords, heading, false, false)
		local id = NetworkGetNetworkIdFromEntity(ped)

		SetNetworkIdCanMigrate(id, true)
		SetEntityAsMissionEntity(ped, false, false)
		SetModelAsNoLongerNeeded(model)

		RequestCollisionAtCoord(coords)

		--while not HasCollisionLoadedAroundEntity(ped) do
		--	Citizen.Wait(100)
		--end

		if cb then
			cb(ped)
		end
	end)
end


Citizen.CreateThread(function()
	Wait(1000)
	null.fct.waitPlayerLoaded()
	TriggerServerEvent('player:GetMyIdentifier')
end)

local MyIdentifier = nil
RegisterNetEvent('player:GetMyIdentifier', function(identifier)
	MyIdentifier = identifier
end)

function ESX.GetMyIdentifier()
	return MyIdentifier
end

function ESX.Game.SpawnLocalPed(pedType, modelName, coords, heading, cb)
	local model = (type(modelName) == 'number' and modelName or GetHashKey(modelName))

	Citizen.CreateThread(function()
		ESX.Streaming.RequestModel(model)
		local ped = CreatePed(pedType, model, coords, heading, false, false)

		SetEntityAsMissionEntity(ped, false, false)
		SetModelAsNoLongerNeeded(model)

		RequestCollisionAtCoord(coords)

		--while not HasCollisionLoadedAroundEntity(ped) do
		--	Citizen.Wait(100)
		--end

		if cb then
			cb(ped)
		end
	end)
end

function ESX.Game.GetVehicleProperties(vehicle)
	if DoesEntityExist(vehicle) then
		local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
		local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
		local extras = {}

		for id = 0, 12 do
			if DoesExtraExist(vehicle, id) then
				extras[tostring(id)] = IsVehicleExtraTurnedOn(vehicle, id) == 1
			end
		end

        local modLiveryCount = GetVehicleLiveryCount(vehicle)
        local modLivery = GetVehicleLivery(vehicle)

        if modLiveryCount == -1 or modLivery == -1 then
            modLivery = GetVehicleMod(vehicle, 48)
        end

		return {
			model = GetEntityModel(vehicle),
			displayname = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),

			plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)),
			plateIndex = GetVehicleNumberPlateTextIndex(vehicle),

			bodyHealth = ESX.Math.Round(GetVehicleBodyHealth(vehicle), 1),
			engineHealth = ESX.Math.Round(GetVehicleEngineHealth(vehicle), 1),

			fuelLevel = ESX.Math.Round(GetVehicleFuelLevel(vehicle), 1),
			dirtLevel = ESX.Math.Round(GetVehicleDirtLevel(vehicle), 1),
			color1 = colorPrimary,
			color2 = colorSecondary,

			pearlescentColor = pearlescentColor,
			wheelColor = wheelColor,

			wheels = GetVehicleWheelType(vehicle),
			windowTint = GetVehicleWindowTint(vehicle),
			xenonColor = GetVehicleXenonLightsColour(vehicle),

			neonEnabled = {
				IsVehicleNeonLightEnabled(vehicle, 0),
				IsVehicleNeonLightEnabled(vehicle, 1),
				IsVehicleNeonLightEnabled(vehicle, 2),
				IsVehicleNeonLightEnabled(vehicle, 3)
			},

			neonColor = table.pack(GetVehicleNeonLightsColour(vehicle)),
			extras = extras,
			tyreSmokeColor = table.pack(GetVehicleTyreSmokeColor(vehicle)),

			modSpoilers = GetVehicleMod(vehicle, 0),
			modFrontBumper = GetVehicleMod(vehicle, 1),
			modRearBumper = GetVehicleMod(vehicle, 2),
			modSideSkirt = GetVehicleMod(vehicle, 3),
			modExhaust = GetVehicleMod(vehicle, 4),
			modFrame = GetVehicleMod(vehicle, 5),
			modGrille = GetVehicleMod(vehicle, 6),
			modHood = GetVehicleMod(vehicle, 7),
			modFender = GetVehicleMod(vehicle, 8),
			modRightFender = GetVehicleMod(vehicle, 9),
			modRoof = GetVehicleMod(vehicle, 10),

			modEngine = GetVehicleMod(vehicle, 11),
			modBrakes = GetVehicleMod(vehicle, 12),
			modTransmission = GetVehicleMod(vehicle, 13),
			modHorns = GetVehicleMod(vehicle, 14),
			modSuspension = GetVehicleMod(vehicle, 15),
			modArmor = GetVehicleMod(vehicle, 16),

			modTurbo = IsToggleModOn(vehicle, 18),
			modSmokeEnabled = IsToggleModOn(vehicle, 20),
			modXenon = IsToggleModOn(vehicle, 22),

			modFrontWheels = GetVehicleMod(vehicle, 23),
			modBackWheels = GetVehicleMod(vehicle, 24),

			modPlateHolder = GetVehicleMod(vehicle, 25),
			modVanityPlate = GetVehicleMod(vehicle, 26),
			modTrimA = GetVehicleMod(vehicle, 27),
			modOrnaments = GetVehicleMod(vehicle, 28),
			modDashboard = GetVehicleMod(vehicle, 29),
			modDial = GetVehicleMod(vehicle, 30),
			modDoorSpeaker = GetVehicleMod(vehicle, 31),
			modSeats = GetVehicleMod(vehicle, 32),
			modSteeringWheel = GetVehicleMod(vehicle, 33),
			modShifterLeavers = GetVehicleMod(vehicle, 34),
			modAPlate = GetVehicleMod(vehicle, 35),
			modSpeakers = GetVehicleMod(vehicle, 36),
			modTrunk = GetVehicleMod(vehicle, 37),
			modHydrolic = GetVehicleMod(vehicle, 38),
			modEngineBlock = GetVehicleMod(vehicle, 39),
			modAirFilter = GetVehicleMod(vehicle, 40),
			modStruts = GetVehicleMod(vehicle, 41),
			modArchCover = GetVehicleMod(vehicle, 42),
			modAerials = GetVehicleMod(vehicle, 43),
			modTrimB = GetVehicleMod(vehicle, 44),
			modTank = GetVehicleMod(vehicle, 45),
			modWindows = GetVehicleMod(vehicle, 46),
			modLivery = modLivery
		}
	else
		return
	end
end

function ESX.Game.SetVehicleProperties(vehicle, props)
	if DoesEntityExist(vehicle) then
		local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
		local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
		SetVehicleModKit(vehicle, 0)

		if props.plate then SetVehicleNumberPlateText(vehicle, props.plate) end
		if props.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex) end
		if props.bodyHealth then SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0) end
		if props.engineHealth then SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0) end
		if props.fuelLevel then SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0) end
		if props.dirtLevel then SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0) end
		if props.color1 then SetVehicleColours(vehicle, props.color1, props.color2 or colorSecondary) end
		if props.color2 then SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2) end
		if props.pearlescentColor then SetVehicleExtraColours(vehicle, props.pearlescentColor, props.wheelColor or wheelColor) end
		if props.wheelColor then SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor) end
		if props.wheels then SetVehicleWheelType(vehicle, props.wheels) end
		if props.windowTint then SetVehicleWindowTint(vehicle, props.windowTint) end
		if props.xenonColor then SetVehicleXenonLightsColour(vehicle, props.xenonColor) end

		if props.neonEnabled then
			SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
			SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
			SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
			SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
		end

		if props.neonColor then SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3]) end

		if props.extras then
			for id, enabled in pairs(props.extras) do
				if enabled then
					SetVehicleExtra(vehicle, tonumber(id), 0)
				else
					SetVehicleExtra(vehicle, tonumber(id), 1)
				end
			end
		end

		if props.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3]) end
		if props.modSpoilers then SetVehicleMod(vehicle, 0, props.modSpoilers, false) end
		if props.modFrontBumper then SetVehicleMod(vehicle, 1, props.modFrontBumper, false) end
		if props.modRearBumper then SetVehicleMod(vehicle, 2, props.modRearBumper, false) end
		if props.modSideSkirt then SetVehicleMod(vehicle, 3, props.modSideSkirt, false) end
		if props.modExhaust then SetVehicleMod(vehicle, 4, props.modExhaust, false) end
		if props.modFrame then SetVehicleMod(vehicle, 5, props.modFrame, false) end
		if props.modGrille then SetVehicleMod(vehicle, 6, props.modGrille, false) end
		if props.modHood then SetVehicleMod(vehicle, 7, props.modHood, false) end
		if props.modFender then SetVehicleMod(vehicle, 8, props.modFender, false) end
		if props.modRightFender then SetVehicleMod(vehicle, 9, props.modRightFender, false) end
		if props.modRoof then SetVehicleMod(vehicle, 10, props.modRoof, false) end
		if props.modEngine then SetVehicleMod(vehicle, 11, props.modEngine, false) end
		if props.modBrakes then SetVehicleMod(vehicle, 12, props.modBrakes, false) end
		if props.modTransmission then SetVehicleMod(vehicle, 13, props.modTransmission, false) end
		if props.modHorns then SetVehicleMod(vehicle, 14, props.modHorns, false) end
		if props.modSuspension then SetVehicleMod(vehicle, 15, props.modSuspension, false) end
		if props.modArmor then SetVehicleMod(vehicle, 16, props.modArmor, false) end
		if props.modTurbo then ToggleVehicleMod(vehicle, 18, props.modTurbo) end
		if props.modSmokeEnabled then ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled) end
		if props.modXenon then ToggleVehicleMod(vehicle, 22, props.modXenon) end
		if props.modFrontWheels then SetVehicleMod(vehicle, 23, props.modFrontWheels, false) end
		if props.modBackWheels then SetVehicleMod(vehicle, 24, props.modBackWheels, false) end
		if props.modPlateHolder then SetVehicleMod(vehicle, 25, props.modPlateHolder, false) end
		if props.modVanityPlate then SetVehicleMod(vehicle, 26, props.modVanityPlate, false) end
		if props.modTrimA then SetVehicleMod(vehicle, 27, props.modTrimA, false) end
		if props.modOrnaments then SetVehicleMod(vehicle, 28, props.modOrnaments, false) end
		if props.modDashboard then SetVehicleMod(vehicle, 29, props.modDashboard, false) end
		if props.modDial then SetVehicleMod(vehicle, 30, props.modDial, false) end
		if props.modDoorSpeaker then SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false) end
		if props.modSeats then SetVehicleMod(vehicle, 32, props.modSeats, false) end
		if props.modSteeringWheel then SetVehicleMod(vehicle, 33, props.modSteeringWheel, false) end
		if props.modShifterLeavers then SetVehicleMod(vehicle, 34, props.modShifterLeavers, false) end
		if props.modAPlate then SetVehicleMod(vehicle, 35, props.modAPlate, false) end
		if props.modSpeakers then SetVehicleMod(vehicle, 36, props.modSpeakers, false) end
		if props.modTrunk then SetVehicleMod(vehicle, 37, props.modTrunk, false) end
		if props.modHydrolic then SetVehicleMod(vehicle, 38, props.modHydrolic, false) end
		if props.modEngineBlock then SetVehicleMod(vehicle, 39, props.modEngineBlock, false) end
		if props.modAirFilter then SetVehicleMod(vehicle, 40, props.modAirFilter, false) end
		if props.modStruts then SetVehicleMod(vehicle, 41, props.modStruts, false) end
		if props.modArchCover then SetVehicleMod(vehicle, 42, props.modArchCover, false) end
		if props.modAerials then SetVehicleMod(vehicle, 43, props.modAerials, false) end
		if props.modTrimB then SetVehicleMod(vehicle, 44, props.modTrimB, false) end
		if props.modTank then SetVehicleMod(vehicle, 45, props.modTank, false) end
		if props.modWindows then SetVehicleMod(vehicle, 46, props.modWindows, false) end

		if props.modLivery then
			SetVehicleMod(vehicle, 48, props.modLivery, false)
			SetVehicleLivery(vehicle, props.modLivery)
		end
	end
end

RegisterNetEvent('esx:serverCallback')
AddEventHandler('esx:serverCallback', function(requestId, ...)
	if requestId == nil then return end
	if ESX.ServerCallbacks[requestId] then
		ESX.ServerCallbacks[requestId](...)
		ESX.ServerCallbacks[requestId] = nil
	end
end)

RegisterNetEvent('esx:initItems')
AddEventHandler('esx:initItems', function(items)
	ESX.Items = items
end)

function ESX.GetItemLabel(item)
	if ESX.Items[item] then
		return ESX.Items[item].label
	end
end

RegisterNetEvent('esx:showNotification')
AddEventHandler('esx:showNotification', ESX.ShowNotification)

RegisterNetEvent('esx:showMessage')
AddEventHandler('esx:showMessage', ESX.ShowMessage)

RegisterNetEvent('esx:showAdvancedNotification')
AddEventHandler('esx:showAdvancedNotification', ESX.ShowAdvancedNotification)

RegisterNetEvent('esx:showHelpNotification')
AddEventHandler('esx:showHelpNotification', ESX.ShowHelpNotification)

-- SetTimeout
--[[Citizen.CreateThread(function()
	while true do
		Citizen.Wait(100)
		local currTime = GetGameTimer()

		for i = 1, #ESX.TimeoutCallbacks, 1 do
			if ESX.TimeoutCallbacks[i] then
				if currTime >= ESX.TimeoutCallbacks[i].time then
					ESX.TimeoutCallbacks[i].cb()
					ESX.TimeoutCallbacks[i] = nil
				end
			end
		end
	end
end)]]

function ESX.GetContribWeapon()
	return Config.ContribWeapon
end
function ESX.GetContribItem()
	return Config.ContribItem
end

function ESX.ContribItem(item) 
	if Config.ContribItem[item] then
		return true 
	else 
		return false
	end
end

function ESX.ContribWeapon(weapon)
	if Config.ContribWeapon[weapon] then
		return true 
	else 
		return false
	end
end


function ESX.getAccountMoney(accountName)
	if not ESX.PlayerData.accounts then
		return 0
	end
	for i = 1, #ESX.PlayerData.accounts, 1 do
		if ESX.PlayerData.accounts[i].name == accountName  then
			return ESX.PlayerData.accounts[i].money
		end
	end
	return 0
end

function ESX.isHandsUp(playerPed)
	return IsEntityPlayingAnim(playerPed, 'random@mugging3', 'handsup_standing_base', 3) or IsEntityPlayingAnim(playerPed, 'missminuteman_1ig_2', 'handsup_base', 3) or IsEntityPlayingAnim(playerPed, 'missminuteman_1ig_2', 'handsup_enter', 3)
end

function ESX.GetMaxWeight ()
    if ESX.PlayerData.maxWeight == -1 then
        return 999999999.999
    end

    return ESX.PlayerData.maxWeight
end

function ESX.GetCurrentWeight()
    local currentWeight = 0

    if ESX.PlayerData.inventory ~= nil and type(ESX.PlayerData.inventory) == "table" then
        for i = 1, #ESX.PlayerData.inventory, 1 do
            local item = ESX.PlayerData.inventory[i]

            if ESX.ContribItem(item.name) then goto continue end
            if item.count == 0 then goto continue end
			local itemWeight = item.weight
			if itemWeight == nil then itemWeight = 0 end
			
            currentWeight = currentWeight + (item.weight * item.count)

            ::continue::
        end
    end

    if ESX.PlayerData.loadout ~= nil and type(ESX.PlayerData.loadout) == "table" then
        for i = 1, #ESX.PlayerData.loadout, 1 do
            local weapon = ESX.PlayerData.loadout[i]

            if ESX.ContribWeapon(weapon.name) then goto continue end
			if weapon.permanent then goto continue end

            currentWeight = currentWeight + (ESX.GetWeaponWeight(weapon.name) or Config.WeaponDefaultWeight)

            ::continue::
        end
    end

    local count = 0
    if ESX.PlayerData.clothes_equiped ~= nil and type(ESX.PlayerData.clothes_equiped) == "table" then
        for k, _ in pairs(ESX.PlayerData.clothes_equiped) do
            count = count + ESX.Table.SizeOf(ESX.PlayerData.clothes_equiped[k])
        end
    end

    currentWeight = currentWeight + (0.25 * count)

    -- Backpack weight: bags in inventory contribute their content weight / divisor
    if _G.BackpackWeightCache and type(_G.BackpackWeightCache) == "table" then
        local divisor = (Config and Config.Backpacks and Config.Backpacks.WeightDivisor) or 2
        for _, bagWeight in pairs(_G.BackpackWeightCache) do
            currentWeight = currentWeight + (bagWeight / divisor)
        end
    end

    return currentWeight
end

ESX.PlayerData.inventoryByName = {}
ESX.PlayerData.loadoutByName = {}

function ESX.RebuildInventoryCache()
    ESX.PlayerData.inventoryByName = {}
    for i = 1, #ESX.PlayerData.inventory do
        local item = ESX.PlayerData.inventory[i]
        if item and item.name then
            ESX.PlayerData.inventoryByName[item.name] = item
        end
    end
end

function ESX.RebuildLoadoutCache()
    ESX.PlayerData.loadoutByName = {}
    for i = 1, #ESX.PlayerData.loadout do
        local weapon = ESX.PlayerData.loadout[i]
        if weapon and weapon.name then
            ESX.PlayerData.loadoutByName[weapon.name] = weapon
        end
    end
end

function ESX.GetInventoryItem(itemName)
    return ESX.PlayerData.inventoryByName[itemName]
end

function ESX.GetJerrycanMaxAmmo()
    local weapon = nil
    local maxFuel = -1
    
    for i = 1, #ESX.PlayerData.loadout do
        local v = ESX.PlayerData.loadout[i]
        
        if v.name ~= 'WEAPON_PETROLCAN' then
            goto continue
        end

        if v.metadata == nil then
            goto continue
        end

        local fuel = v.metadata.fuel

        if fuel == nil then
            fuel = 4500
        end

        if fuel > maxFuel then
            weapon = i
            maxFuel = fuel
        end

        ::continue::
    end

    return weapon
end


function ESX.HasItem(name)
    if not ESX.PlayerData.inventoryByName then return false end
    return ESX.PlayerData.inventoryByName[name] ~= nil
end

function ESX.HasWeapon(name)
    if not ESX.PlayerData.loadoutByName then return false end
    return ESX.PlayerData.loadoutByName[name] ~= nil
end

function ESX.GetMyWeapon(name)
    if not ESX.PlayerData.loadoutByName then return nil end
    return ESX.PlayerData.loadoutByName[name]
end

function ESX.HasWeaponComponent(weaponName, weaponComponent)
    if not ESX.PlayerData.loadoutByName then return false end
    local weapon = ESX.PlayerData.loadoutByName[weaponName]
    if not weapon or not weapon.metadata or not weapon.metadata.components then return false end
    return ESX.Table.Contains(weapon.metadata.components, weaponComponent)
end

function IsMale()
    return GetEntityModel(PlayerPedId()) == GetHashKey("mp_m_freemode_01")
end

--[[ESX.RegisterClientCallback("esx:getNearbyPlayer", function()
	local player, distance = ESX.Game.GetClosestPlayer()

	if player == -1 then 
		return {player = 0, distance = 0}
	end

	return {player = GetPlayerServerId(player), distance = distance}
end)

ESX.RegisterClientCallback("esx:getNearbyVehicle", function ()
	local vehicle, distance = ESX.Game.GetClosestVehicle()

	if vehicle == -1 then
		return { vehicle = 0, distance = 0 }
	end

	if not NetworkGetEntityIsNetworked(vehicle) then
		return { vehicle = 0, distance = 0 }
	end

	return {
		vehicle = NetworkGetNetworkIdFromEntity(vehicle),
		distance = distance
	}
end)]]

function ESX.SecondsToClock(seconds)
    local seconds = tonumber(seconds)
  
    if seconds <= 0 then
        return "00:00:00";
    else
        hours = string.format("%02.f", math.floor(seconds/3600));
        mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
        secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
        return hours..":"..mins..":"..secs
    end
end

ESX.Utils = {}

function ESX.Utils.EntityMarker(entity)
	local pos = GetEntityCoords(entity)
	DrawMarker(2, pos.x, pos.y, pos.z+1.0, 0.0, 0.0, 0.0, 179.0, 0.0, 0.0, 0.25, 0.25, 0.25, 81, 203, 231, 200, 0, 1, 2, 1, nil, nil, 0)
end
