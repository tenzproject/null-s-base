function MainAFKMenu()
	TriggerServerEvent("null:afk:gettimer")
	local main = RageUI.CreateMenu("", "")
	RageUI.Visible(main, not RageUI.Visible(main))

	while main do
		Citizen.Wait(0)
			RageUI.IsVisible(main, function()
                RageUI.Separator('Vous avez '..PlayerState.afkPoint.. ' points AFK')
                RageUI.Separator('Vous avez '..PlayerState.afkTimer.. ' minutes d\'afk')
				for k,v in pairs(Config.Afk.Invest.Lot) do
					RageUI.Button(v.label, nil, {RightLabel = v.price, RightBadge = RageUI.BadgeStyle.Coins}, true, {
						onActive = function()
							RageUI.Info(
								v.info1, v.info2, {'','','','','','','','','','',''})
						end,
						onSelected = function()
							TriggerServerEvent('null:afk:shopbuy', k)
						end
					})
				end
			end)
		if not RageUI.Visible(main) then
			main = RMenu:DeleteType('main', true)
		end
	end
end

local time = 60*1000
local nonekeypressNbr = 0
local timepassed = 0
Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
	local controltocheck = {
		21, 22, 30, 31, 32, 33, 34, 35
	}
	if not Config.Afk.autoAfk then return end
	while true do
		Wait(time)
		local pressed = false
		for k,v in pairs(controltocheck) do
			if IsControlPressed(0, v) ~= false then
				pressed = true
				break
			end
		end
		if PlayerState.AfkSleep then
			if pressed then
				nonekeypressNbr = 0
				PlayerState.AfkSleep = false
			end
		else
			if not pressed then
				if nonekeypressNbr >= 15 and not nTable.staffMode then
					IAmAfk()
				elseif not nTable.staffMode then
					nonekeypressNbr = nonekeypressNbr + 1
				end
			end
		end
	end
end))

Citizen.CreateThread(LPH_NO_VIRTUALIZE(function()
    null.fct.waitPlayerLoaded()
	if not Config.Afk.autoAfk then return end
    while true do
        loopFrames = 2500
        if #null.data.afk >= 1 then
            for k,v in pairs(null.data.afk) do 
                local playerPos = v.coords
                local distance = #(GetEntityCoords(PlayerPedId())-v.coords)
                if distance < 20 then
                    if distance < 10 then
                        loopFrames = 0
                        local text = ('*Dort depuis %s Minutes*'):format(math.round(v.time))
                        ESX.Game.Utils.DrawText3D(v.coords, text, 0.75, 4)
                    end
                end
            end
        end

        Wait(loopFrames)
    end
end))

function IAmAfk()
	PlayerState.AfkSleep = true
	time = 1000
	timepassed = 15*60
	TriggerServerEvent("null:afk:iamafk:sleep", PlayerState.coords)
	Citizen.CreateThread(function()
		while PlayerState.AfkSleep do
			null.DisplayHud(false)
			ExecuteCommand("e bumsleep")
			FreezeEntityPosition(PlayerPedId(), true)
			timepassed = timepassed + 1
			TriggerServerEvent("null:afk:iamafk:sleep:udapte", timepassed)
			Wait(1000)
		end
		time = 60*1000
		timepassed = 0
		TriggerServerEvent("null:afk:iamnotafk:sleep")
		ExecuteCommand("emotecancel")
		FreezeEntityPosition(PlayerPedId(), false)
		null.DisplayHud(true)
	end)
	Citizen.CreateThread(function()
		while PlayerState.AfkSleep do
			local text = "Appuyer sur Z pendant 5 secondes pour vous réveillez"
			ESX.Game.Utils.DrawText(text, 0.4, 4, vector2(0.50, 0.96))
			Wait(0)
		end
	end)
end

RegisterNetEvent('null:afk:sleep:recevieplayers', function(data)
	null.data.afk = data
end)

RegisterCommand('afk', function(source,args)
    if GetSafeZone() then
        TriggerServerEvent('null:afk:join')
    else
        ESX.ShowNotification('Vous n\'êtes pas en Zone Safe')
    end
end)

RegisterNetEvent('null:afk:refresh', function(newtimer, point)
	if not PlayerState.inAfk then return end
	PlayerState.afkTimer = newtimer
	PlayerState.afkPoint = point
end)

RegisterNetEvent('null:afk:init', function()
	PlayerState.inAfk = true
	if null.data.markers.isRegister("afk_exit") then return end
	if null.data.markers.isRegister("afk_shop") then return end
	null.data.markers.register("afk_exit", {
		Position = vec3(490.118896, 4808.295898, -58.382812),
		Public = true,
		Job = nil,
		Job2 = nil,
		Action = function()
			TriggerServerEvent("null:afk:exit")
		end
	})
	null.data.markers.register("afk_shop", {
		Position = vec3(477.941956, 4804.981934, -58.382851),
		Public = true,
		Job = nil,
		Job2 = nil,
		Action = function()
			MainAFKMenu()
		end
	})
end)