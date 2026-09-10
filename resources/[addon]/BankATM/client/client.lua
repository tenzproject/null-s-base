RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
	ESX.PlayerData = ESX.GetPlayerData()
	if ESX.PlayerData and ESX.PlayerData.accounts then
		for i = 1, #ESX.PlayerData.accounts, 1 do
			if ESX.PlayerData.accounts[i].name == account.name then
				ESX.PlayerData.accounts[i] = account
				break
			end
		end
	end
end)


local localCam
local localATM
local card = false

RegisterNetEvent("BankATM:client:update_nui")
AddEventHandler("BankATM:client:update_nui",function(data)
	SendNUIMessage(data)
	ESX.PlayerData = ESX.GetPlayerData()
	for i = 1, #ESX.PlayerData.accounts, 1 do
		if ESX.PlayerData.accounts[i].name == "bank" then
			SendNUIMessage({type="balance",money=ESX.PlayerData.accounts[i].money})
			break
		end
	end
end)

RegisterNUICallback("exit",function(data,cb)
	if card then
		remove_card()
	end
	card = false
	SendNUIMessage({type="visible",data=false})
	cb({status=true})
	RenderScriptCams(false, false, 0, true, true)
	DestroyCam(localCam, false)
	SetNuiFocus(false,false)
	FreezeEntityPosition(PlayerPedId(),false)
	TriggerEvent("BankATM:client:close")
end)

Citizen.CreateThread(function()
	DoScreenFadeIn(300)
	FreezeEntityPosition(PlayerPedId(),false)
end)

RegisterNetEvent("BankATM:client:notify")
AddEventHandler("BankATM:client:notify",function(msg)
	--showNotification(msg)
	ESX.ShowNotification(msg)
end)

function showNotification(msg)
	SetNotificationTextEntry('STRING')
	AddTextComponentString(msg)
	EndTextCommandThefeedPostMessagetext(config.notifyIcon, config.notifyIcon, true, 1, config.notifyName, config.notifyDesc)
	DrawNotification(true, false)
end

RegisterNUICallback("doCommand",function(data,cb)
	cb({status=true})
	if data.type == "card" then
		card = true
		insert_card()
		return
	end
	if data.type == "pickupmoney" then
		pickup_money()
		return
	end
	if data.type == "putmoney" then
		put_money()
		return
	end
	if data.type == "withdraw" then
		--pickup_money()
	end
	if data.type == "deposit" then
		put_money()
	end
	ESX.PlayerData = ESX.GetPlayerData()
	if data.type == "balance" then
		for i = 1, #ESX.PlayerData.accounts, 1 do
			if ESX.PlayerData.accounts[i].name == "bank" then
				SendNUIMessage({type="balance",money=ESX.PlayerData.accounts[i].money})
				break
			end
		end
	end
	TriggerServerEvent("BankATM:server:doCommand",data)
end)


local options =
{
	{
		label = "Ouvrir l'ATM",
		name = "openatm",
		icon = "fa-solid fa-money-bills",
		distance = 1,
		canInteract = function()
			return true
		end,
		onSelect = function(Podatci)
			return open_atm()
		end
	}
}
--exports.ox_target:addModel(config.atmModels, options)

function open_atm()
	local playerPed = PlayerPedId()
	local playerPos = GetEntityCoords(playerPed)
	for _, atmModel in ipairs(config.atmModels) do
		local atm = GetClosestObjectOfType(playerPos, 0.7, GetHashKey(atmModel), false, false, false)
		if atm ~= 0 then
			DoScreenFadeOut(300)
			ESX.PlayerData = ESX.GetPlayerData()
			for i = 1, #ESX.PlayerData.accounts, 1 do
				if ESX.PlayerData.accounts[i].name == "bank" then
					SendNUIMessage({type="balance",money=ESX.PlayerData.accounts[i].money})
					break
				end
			end
			Wait(300)
			TriggerEvent("BankATM:client:open")
			TriggerEvent("BankATM:client:update_nui",{type="visible",data=true,atm=atmModel,lang=config.atm_lang})
			SetNuiFocus(true,true)

			SetEntityHeading(playerPed, GetEntityHeading(atm))
			local cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
			localCam = cam
			local atmCoords = GetEntityCoords(atm)

			local camCoords = GetOffsetFromEntityInWorldCoords(atm, 0.0, -0.5, 1.0)
			SetCamCoord(cam, camCoords.x,camCoords.y,camCoords.z+0.35)

			if atmModel == "prop_atm_01" then
				local camCoords = GetOffsetFromEntityInWorldCoords(atm, 0.0, -0.6, 0.9)
				SetCamCoord(cam, camCoords.x,camCoords.y,camCoords.z+0.35)
			end
			
			local deltaX = atmCoords.x - camCoords.x
			local deltaY = atmCoords.y - camCoords.y
			local deltaZ = atmCoords.z - camCoords.z
			local length = math.sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)

			local pitch = math.deg(math.asin(deltaZ / length))
			local heading = math.deg(math.atan2(deltaY, deltaX))

			local camRotX = pitch + 41.0
			local camRotY = 0.0
			local camRotZ = heading - 90

			SetCamRot(cam, camRotX, camRotY, camRotZ, 2)

			local entityCoords = GetEntityCoords(atm)
    		local entityHeading = GetEntityHeading(atm)
    		local radianHeading = math.rad(entityHeading+180)
    		local offsetX = -0.6 * math.sin(radianHeading)
    		local offsetY = 0.6 * math.cos(radianHeading)
    		if atmModel == "prop_atm_01" then
				offsetX = -0.8 * math.sin(radianHeading)
    			offsetY = 0.8 * math.cos(radianHeading)
			end
    		local targetCoords = vector3(entityCoords.x + offsetX, entityCoords.y + offsetY, entityCoords.z)
    		local position = targetCoords

			local atmHeading = GetEntityHeading(atm)
			FreezeEntityPosition(playerPed,true)
			SetEntityCoords(playerPed, position)
			SetEntityHeading(playerPed, atmHeading)

			SetCamActive(cam, true)
			RenderScriptCams(true, false, 0, true, true)
			DoScreenFadeIn(300)
			Wait(300)
		end
	end
end
exports("open_atm", open_atm)

function insert_card()
    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) then
        RequestAnimDict('anim@mp_atm@enter')
        while not HasAnimDictLoaded('anim@mp_atm@enter') do
            Wait(0)
        end
        TaskPlayAnim(playerPed, 'anim@mp_atm@enter', 'enter', 8.0, -8.0, 3000, 0, 0, false, false, false)
        local card = CreateObject(GetHashKey('prop_cs_business_card'), 0, 0, 0, true, true, true)
        AttachEntityToEntity(card, playerPed, GetPedBoneIndex(playerPed, 57005), 0.22, 0.02, 0.0, 0.0, 0.0, 180.0, true, true, false, true, 1, true)
        SetEntityAsMissionEntity(card, true, true)
        Wait(1500)
        DeleteObject(card)
    end
end

function remove_card()
    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) then
        RequestAnimDict('anim@mp_atm@enter')
        while not HasAnimDictLoaded('anim@mp_atm@enter') do
            Wait(0)
        end
        TaskPlayAnim(playerPed, 'anim@mp_atm@enter', 'enter', 8.0, -8.0, 3000, 0, 0, false, false, false)
        Wait(1500)
        local card = CreateObject(GetHashKey('prop_cs_business_card'), 0, 0, 0, true, true, true)
        AttachEntityToEntity(card, playerPed, GetPedBoneIndex(playerPed, 57005), 0.18, 0.025, 0.0, 0.0, 0.0, 180.0, true, true, false, true, 1, true)
        SetEntityAsMissionEntity(card, true, true)
        Wait(1500)
        DeleteObject(card)
    end
end

function pickup_money()
    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) then
		RequestAnimDict("mp_common")
		while not HasAnimDictLoaded("mp_common") do
			Citizen.Wait(100)
		end
		TaskPlayAnim(PlayerPedId(), "mp_common", "givetake2_a", 8.0, -8.0, -1, 0, 0, false, false, false)
		Wait(1000)
        local money = CreateObject(GetHashKey('bkr_prop_money_sorted_01'), 0, 0, 0, true, true, true)
        AttachEntityToEntity(money, playerPed, GetPedBoneIndex(playerPed, 57005),0.1, 0.05, 0.0, 90.0, 90.0, 00.0, true, true, false, true, 1, true)
        SetEntityAsMissionEntity(money, true, true)
        Wait(1500)
        DeleteObject(money)
		ESX.PlayerData = ESX.GetPlayerData()
		for i = 1, #ESX.PlayerData.accounts, 1 do
			if ESX.PlayerData.accounts[i].name == "bank" then
				SendNUIMessage({type="balance",money=ESX.PlayerData.accounts[i].money})
				break
			end
		end
    end
end

function put_money()
    local playerPed = PlayerPedId()
    if not IsPedInAnyVehicle(playerPed, false) then
		RequestAnimDict("mp_common")
		while not HasAnimDictLoaded("mp_common") do
			Citizen.Wait(100)
		end
		TaskPlayAnim(PlayerPedId(), "mp_common", "givetake2_a", 8.0, -8.0, -1, 0, 0, false, false, false)
        local money = CreateObject(GetHashKey('bkr_prop_money_sorted_01'), 0, 0, 0, true, true, true)
        AttachEntityToEntity(money, playerPed, GetPedBoneIndex(playerPed, 57005), 0.1, 0.05, 0.0, 90.0, 90.0, 00.0, true, true, false, true, 1, true)
        SetEntityAsMissionEntity(money, true, true)
        Wait(1000)
        DeleteObject(money)
		ESX.PlayerData = ESX.GetPlayerData()
		for i = 1, #ESX.PlayerData.accounts, 1 do
			if ESX.PlayerData.accounts[i].name == "bank" then
				SendNUIMessage({type="balance",money=ESX.PlayerData.accounts[i].money})
				break
			end
		end
    end
end