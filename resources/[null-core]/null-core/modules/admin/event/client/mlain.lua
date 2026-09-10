--[[local ScreenCoords = { baseX = 0.918, baseY = 0.984, titleOffsetX = 0.035, titleOffsetY = -0.018, valueOffsetX = 0.0785, valueOffsetY = -0.0165, pbarOffsetX = 0.047, pbarOffsetY = 0.0015 }
local Sizes = {	timerBarWidth = 0.165, timerBarHeight = 0.035 , timerBarMargin = 0.038, pbarWidth = 0.0616, pbarHeight = 0.0105 } 
activeBars = {}

function AddTimerBar(title, itemData)
	if not itemData then return end
	RequestStreamedTextureDict("timerbars", true)
	local barIndex = #activeBars + 1
	activeBars[barIndex] = {
		title = title,
		text = itemData.text,
		textColor = itemData.color or { 255, 255, 255, 255 },
		percentage = itemData.percentage,
		endTime = itemData.endTime,
		pbarBgColor = itemData.bg or { 155, 155, 155, 255 },
		pbarFgColor = itemData.fg or { 255, 255, 255, 255 }
	}
	return barIndex
end

function null.fct.draw.RemoveTimerBar()
	activeBars = {}
	SetStreamedTextureDictAsNoLongerNeeded("timerbars")
end

function SecondsToClock(seconds)
	seconds = tonumber(seconds)
	if seconds <= 0 then
		return "00:00"
	else
		local mins = string.format("%02.f", math.floor(seconds / 60))
		local secs = string.format("%02.f", math.floor(seconds - mins * 60))
		return string.format("%s:%s", mins, secs)
	end
end

function DrawText2(intFont, stirngText, floatScale, intPosX, intPosY, color, boolShadow, intAlign, addWarp)
	SetTextFont(intFont)
	SetTextScale(floatScale, floatScale)
	if boolShadow then
		SetTextDropShadow(0, 0, 0, 0, 0)
		SetTextEdge(0, 0, 0, 0, 0)
	end
	SetTextColour(color[1], color[2], color[3], 255)
	if intAlign == 0 then
		SetTextCentre(true)
	else
		SetTextJustification(intAlign or 1)
		if intAlign == 2 then
			SetTextWrap(.0, addWarp or intPosX)
		end
	end
	SetTextEntry("STRING")
	AddTextComponentString(stirngText)
	DrawText(intPosX, intPosY)
end	


local HideHudComponentThisFrame = HideHudComponentThisFrame
local GetSafeZoneSize = GetSafeZoneSize
local DrawSprite = DrawSprite
local DrawText2 = DrawText2
local DrawRect = DrawRect
local SecondsToClock = SecondsToClock
local GetGameTimer = GetGameTimer
local textColor = { 200, 100, 100 }
local math = math

--[[Citizen.CreateThread(function()
	WaitActiveBars = 350
	while true do
		local safeZone = GetSafeZoneSize()
		local safeZoneX = (1.0 - GetSafeZoneSize()) * 0.5
		local safeZoneY = (1.0 - safeZone) * 0.5
		if #activeBars > 0 then
            WaitActiveBars = 0
			for i,v in pairs(activeBars) do
				local drawY = (ScreenCoords.baseY - safeZoneY) - (i * Sizes.timerBarMargin);
				DrawSprite("timerbars", "all_black_bg", ScreenCoords.baseX - safeZoneX, drawY, Sizes.timerBarWidth, Sizes.timerBarHeight, 0.0, 255, 255, 255, 160)
				DrawText2(0, v.title, 0.425, (ScreenCoords.baseX - safeZoneX) + ScreenCoords.titleOffsetX, drawY + ScreenCoords.titleOffsetY, v.textColor, false, 2)
				if v.percentage then
					local pbarX = (ScreenCoords.baseX - safeZoneX) + ScreenCoords.pbarOffsetX;
					local pbarY = drawY + ScreenCoords.pbarOffsetY;
					local width = Sizes.pbarWidth * v.percentage;
					DrawRect(pbarX, pbarY, Sizes.pbarWidth, Sizes.pbarHeight, v.pbarBgColor[1], v.pbarBgColor[2], v.pbarBgColor[3], v.pbarBgColor[4])
					DrawRect((pbarX - Sizes.pbarWidth / 2) + width / 2, pbarY, width, Sizes.pbarHeight, v.pbarFgColor[1], v.pbarFgColor[2], v.pbarFgColor[3], v.pbarFgColor[4])
				elseif v.text then
					DrawText2(0, v.text, 0.425, (ScreenCoords.baseX - safeZoneX) + ScreenCoords.valueOffsetX, drawY + ScreenCoords.valueOffsetY, v.textColor, false, 2)
				elseif v.endTime then
					local remainingTime = math.floor(v.endTime - GetGameTimer())
					DrawText2(0, SecondsToClock(remainingTime / 1000), 0.425, (ScreenCoords.baseX - safeZoneX) + ScreenCoords.valueOffsetX, drawY + ScreenCoords.valueOffsetY, remainingTime <= 0 and textColor or v.textColor, false, 2)
				end
			end
        else
            WaitActiveBars = 1500
		end
        Wait(WaitActiveBars)
	end
end)

local ObjTable = {}
local sended = false
local sound = GetSoundId()
local ObjNetId = 0
EventStop = false

function BrinksEvents(sEventsInfos, zone, time)
    sended = false
    Citizen.CreateThread(function()
        blip = AddBlipForCoord(zone)
        SetBlipSprite(blip, 616)
        SetBlipColour(blip, 1)
		SetBlipScale(blip, 0.6)
		BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Événement | Brinks")
        EndTextCommandSetBlipName(blip)
		ESX.ShowNotification(sEventsInfos.message)
		AddTimerBar("Temps restant(s)", {endTime=GetGameTimer()+time*60*1000})
		local dst = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), zone, true)
		while dst > 150 do
			Wait(100)
			dst = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), zone, true)
			if EventStop then return end
			if EventStop then break end
		end
		if not EventStop then
			local blinder = GetHashKey("Stockade")
			RequestModel(blinder)
			while not HasModelLoaded(blinder) do Wait(10) end
			local veh = CreateVehicle(blinder, zone, math.random(0.0,180.0), 0, 0)
			SetVehicleUndriveable(veh, 1)
			FreezeEntityPosition(veh, 1)
			SetVehicleAlarm(veh, 1)
			SetVehicleAlarmTimeLeft(veh, 999999.0*9999)
			for i = 1,9 do
				SetVehicleDoorOpen(veh, i, 0, 1)
			end
			table.insert(ObjTable, veh)
			local ArgentRecup = 0
			while ArgentRecup < 10 do
				Wait(1)
				local randomProp = sEventsInfos.prop[math.random(1, #sEventsInfos.prop)]
				RequestModel(GetHashKey(randomProp))
				while not HasModelLoaded(GetHashKey(randomProp)) do Wait(10) end
				local randomZone = vector3(zone.x+math.random(-6.0,6.0), zone.y+math.random(-6.0,6.0), zone.z)
				local obj = CreateObject(GetHashKey(randomProp), randomZone, 0, 0, 0)
				table.insert(ObjTable, obj)
				PlaceObjectOnGroundProperly(obj)
				FreezeEntityPosition(obj, 1)
				local ObjCoords = GetEntityCoords(obj)
				local dst = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), ObjCoords, 0)
				while dst > 2.0 do
					Wait(1)
					ObjCoords = GetEntityCoords(obj)
					dst = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), ObjCoords, 0)
					DrawMarker(21, ObjCoords+0.8, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255,143,0, 255, 55555, false, true, 2, false, false, false, false)
					if EventStop then return end
					if EventStop then break end
				end
				if not EventStop then
					PlaySoundFrontend(-1, "Bus_Schedule_Pickup", "DLC_PRISON_BREAK_HEIST_SOUNDS", 1)
					ArgentRecup = ArgentRecup + 1
					local nombre = math.random(120, 200)
					ESX.ShowNotification("Vous avez ramasser: ~g~+"..nombre.."$")
					TriggerServerEvent("AKService:GetMoneyInsEvents", nombre)
					RemoveEventsObj(obj)
					if EventStop then return end
					if EventStop then break end
				end
				if ArgentRecup >= 10 then
					TriggerServerEvent("AKService:TakeRecInsEvents")
					StopSound(sound)
					sended = true
					for k,v in pairs(ObjTable) do
						RemoveEventsObj(v)
					end
					break
				end
				if EventStop then 
					ArgentRecup = 99 break 
				end
			end
			if not sended then
				StopSound(sound)
				TriggerServerEvent("AKService:TakeRecInsEvents")
				sended = true
			end
			StopSound(sound)
			ESX.ShowNotification("Cargaison récupérée !")
			PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
		end
		for k,v in pairs(ObjTable) do
			RemoveEventsObj(v)
		end
		ObjTable = {}
		RemoveBlip(blip)
		null.fct.draw.RemoveTimerBar()
    end)
end

function DrugsEvents(sEventsInfos, zone, time)
    sended = false
    Citizen.CreateThread(function()
        blip = AddBlipForCoord(zone)
        SetBlipSprite(blip, 615)
        SetBlipColour(blip, 1)
		SetBlipScale(blip, 0.6)
		BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Événement | Drogue")
        EndTextCommandSetBlipName(blip)
		ESX.ShowAdvancedNotification(sEventsInfos.message)
		AddTimerBar("Temps restant(s)", {endTime=GetGameTimer()+time*60*1000})
		local dst = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), zone, true)
		while dst > 150 do
			Wait(100)
			dst = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), zone, true)
			if EventStop then return end
			if EventStop then break end
		end
		if not EventStop then
			local DrogueRecup = 0
			while DrogueRecup < 10 do
				Wait(1)
				local randomProp = sEventsInfos.prop[math.random(1, #sEventsInfos.prop)]
				RequestModel(GetHashKey(randomProp))
				while not HasModelLoaded(GetHashKey(randomProp)) do Wait(10) end
				local randomZone = vector3(zone.x+math.random(-15.0,15.0), zone.y+math.random(-15.0,15.0), zone.z)
				local obj = CreateObject(GetHashKey(randomProp), randomZone, 0, 0, 0)
				ObjNetId = obj
				PlaceObjectOnGroundProperly(obj)
				FreezeEntityPosition(obj, 1)
				local ObjCoords = GetEntityCoords(obj)
				local dst = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), ObjCoords, 0)
				while dst > 2.0 do
					Wait(1)
					ObjCoords = GetEntityCoords(obj)
					dst = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), ObjCoords, 0)
					DrawMarker(21, ObjCoords+0.8, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255,143,0, 255, 55555, false, true, 2, false, false, false, false)
					if EventStop then return end
					if EventStop then break end
				end
				if not EventStop then
					PlaySoundFrontend(-1, "Bus_Schedule_Pickup", "DLC_PRISON_BREAK_HEIST_SOUNDS", 1)
					RemoveEventsObj(ObjNetId)
					DrogueRecup = DrogueRecup + 1
					local nombre = math.random(1, 10)
					local item = sEventsInfos.item[math.random(1,#sEventsInfos.item)]
					ESX.ShowNotification("Vous avez ramassé: ~g~+"..nombre.." "..item)
					TriggerServerEvent("AKService:GetItemInsEvents", item, nombre)
					if EventStop then return end
					if EventStop then break end
				end
				if DrogueRecup >= 10 then
					TriggerServerEvent("AKService:TakeRecInsEvents")
					sended = true
					break
				end
				if EventStop then 
					DrogueRecup = 99 break 
				end
			end
			if not sended then
				TriggerServerEvent("AKService:TakeRecInsEvents")
				sended = true
			end
			ESX.ShowNotification("Cargaison récupérée !")
			PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
		end
		RemoveBlip(blip)
		null.fct.draw.RemoveTimerBar()
	end)
end

function CaisseEvents(sEventsInfos, zone, time)
    sended = false
    Citizen.CreateThread(function()
        blip = AddBlipForCoord(zone)
        SetBlipSprite(blip, 587)
        SetBlipColour(blip, 2)
		SetBlipScale(blip, 0.6)
		BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Événement | Caisse mystère")
        EndTextCommandSetBlipName(blip)
		ESX.ShowNotification(sEventsInfos.message)
		AddTimerBar("Temps restant(s)", {endTime=GetGameTimer()+time*60*1000})
		local dst = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), zone, true)
		while dst > 150 do
			Wait(100)
			dst = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), zone, true)
			if EventStop then return end
			if EventStop then break end
		end
		if not EventStop then
			local CaisseRecup = 0
			while CaisseRecup < 10 do
				Wait(1)
				local randomProp = sEventsInfos.prop[math.random(1, #sEventsInfos.prop)]
				RequestModel(GetHashKey(randomProp))
				while not HasModelLoaded(GetHashKey(randomProp)) do Wait(10) end
				local randomZone = vector3(zone.x, zone.y, zone.z)
				local obj = CreateObject(GetHashKey(randomProp), randomZone, 0, 0, 0)
				ObjNetId = obj
				PlaceObjectOnGroundProperly(obj)
				FreezeEntityPosition(obj, 1)
				local ObjCoords = GetEntityCoords(obj)
				local dst = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), ObjCoords, 0)
				while dst > 2.0 do
					Wait(1)
					ObjCoords = GetEntityCoords(obj)
					dst = GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), ObjCoords, 0)
					DrawMarker(21, ObjCoords+0.8, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255,143,0, 255, 55555, false, true, 2, false, false, false, false)
					if EventStop then return end
					if EventStop then break end
				end
				if not EventStop then
					PlaySoundFrontend(-1, "Bus_Schedule_Pickup", "DLC_PRISON_BREAK_HEIST_SOUNDS", 1)
					RemoveEventsObj(ObjNetId)
					CaisseRecup = CaisseRecup + 1
					local item = sEventsInfos.item[math.random(1,#sEventsInfos.item)]
					TriggerServerEvent("AKService:GetItemInsEvents", item, 1)
					if EventStop then return end
					if EventStop then break end
				end
				if CaisseRecup >= 1 then
					TriggerServerEvent("AKService:TakeRecInsEvents")
					sended = true
					break
				end
				if EventStop then 
					CaisseRecup = 99 break 
				end
			end
			if not sended then
				TriggerServerEvent("AKService:TakeRecInsEvents")
				sended = true
			end
			ESX.ShowNotification("Cargaison récupérée !")
			PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", 1)
		end
		RemoveBlip(blip)
		null.fct.draw.RemoveTimerBar()
	end)
end

-- Events des events xD

RegisterNetEvent("AKService:SendsEvents")
AddEventHandler("AKService:SendsEvents", function(sEventsInfos, zone, time)
    EventStop = false
	SetAudioFlag("LoadMPData", 1)
	PlaySoundFrontend(-1, "Boss_Message_Orange", "GTAO_Boss_Goons_FM_Soundset", 1)
	PlaySoundFrontend(-1, "CHARACTER_SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", 1)
	activeBars = {}
	SetStreamedTextureDictAsNoLongerNeeded("timerbars")
    if sEventsInfos.type == "drugs" then
        DrugsEvents(sEventsInfos, zone, time)
    elseif sEventsInfos.type == "brinks" then
        BrinksEvents(sEventsInfos, zone, time)
	elseif sEventsInfos.type == "caisse" then
		CaisseEvents(sEventsInfos, zone, time)
    end
end)

RegisterNetEvent("AKService:StopsEvents")
AddEventHandler("AKService:StopsEvents", function(delete)
    PlaySoundFrontend(-1, "Criminal_Damage_High_Value", "Criminal_Damage_High_Value", 1)
    PlaySoundFrontend(-1, "Criminal_Damage_High_Value", "Criminal_Damage_High_Value", 1)
    PlaySoundFrontend(-1, "Criminal_Damage_High_Value", "Criminal_Damage_High_Value", 1)
    PlaySoundFrontend(-1, "Checkpoint_Cash_Hit", "GTAO_FM_Events_Soundset", 1)
	ESX.ShowNotification("Événement Terminé ! Tu n'étais pas encore arrivé ? vient plus rapidement la prochaine fois !")
    EventStop = true
    StopSound(GetSoundId())
	null.fct.draw.RemoveTimerBar()
    RemoveBlip(blip)
    for k,v in pairs(ObjTable) do
        RemoveEventsObj(v)
    end
end)

function RemoveEventsObj(id)
    local entity = id
    SetEntityAsMissionEntity(entity, true, true)
    local timeout = 2000
    while timeout > 0 and not IsEntityAMissionEntity(entity) do
        Wait(100)
        timeout = timeout - 100
    end
    Citizen.InvokeNative(0xEA386986E786A54F, Citizen.PointerValueIntInitialized(entity))
    if (DoesEntityExist(entity)) then 
        DeleteEntity(entity)
    end 
end]]