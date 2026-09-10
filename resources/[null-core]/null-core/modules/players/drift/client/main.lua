local kmh = 3.6
local mph = 2.23693629
local carspeed = 0
driftmode = false -- on/off speed
local speed = kmh -- or mph

-- Thread
Citizen.CreateThread(function()
	while true do
		if (IsPedInAnyVehicle(GetPed(), false) and driftmode) or (IsPedInAnyVehicle(GetPed(), false) and TrackCanDrift) then
			Citizen.Wait(1)
		else
			Wait(1500)
		end

		if driftmode or TrackCanDrift then
			if IsPedInAnyVehicle(GetPed(), false) then
				CarSpeed = GetEntitySpeed(GetCar()) * speed
				if GetPedInVehicleSeat(GetCar(), -1) == GetPed() then
					if CarSpeed <= Config.drift.speed_limit then  
						if IsControlPressed(1, Config.drift.toggle_key) then
							SetVehicleReduceGrip(GetCar(), true)
						else
							SetVehicleReduceGrip(GetCar(), false)
						end
					else
						SetVehicleReduceGrip(GetCar(), false)
					end
				end
			end
		end
	end
end)

exports("setDriftMode", function(bool)
	if bool and type(bool) == "boolean" then
		driftmode = bool
	end
end)

-- Function
function GetPed() return PlayerPedId() end
function GetCar() return GetVehiclePedIsIn(PlayerPedId(),false) end