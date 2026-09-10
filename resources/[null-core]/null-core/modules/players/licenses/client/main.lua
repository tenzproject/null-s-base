PlayerState.myLicense = {}

Citizen.CreateThread(function()
	Wait(4000)
	TriggerServerEvent("Null:licenses:askmylicenses")
end)

RegisterNetEvent("Null:licenses:recevie", function(result)
	PlayerState.myLicense = result
end)


function CheckLicense(licenseType)
	if PlayerState.myLicense[licenseType] then
		return true
	else
		return false
	end
end

local isCardOpen = false

RegisterNetEvent("null:idcard:show", function(cardData)
	if isCardOpen then return end
	if not cardData then return end
	isCardOpen = true
	SendNUIMessage({ action = 'idcard:show', data = cardData })
	-- SetTimeout(8000, function()
	-- 	if isCardOpen then
	-- 		isCardOpen = false
	-- 		SendNUIMessage({ action = 'idcard:hide' })
	-- 	end
	-- end)

	Citizen.CreateThread(function()
		while true do 
			if IsControlJustPressed(0, 322) then
				isCardOpen = false
				SendNUIMessage({ action = 'idcard:hide' })
				break
			end
			Wait(1)
		end
	end)
end)

RegisterNUICallback("idcard:close", function(_, cb)
	isCardOpen = false
	cb("ok")
end)